---
title: Xposed简介以及小米去桌面广告的简单实现
date: 2017-11-18 19:18:02
categories: Android
tags: Xposed

---
<Excerpt in index | 首页摘要>

提起Xposed，大多数Android开发者都听过或者用过，甚至有一些开发过比较炫酷的模块。这是我前段时间在公司的分享内容，分享给大家。

<!-- more -->

#最先发表于个人博客 https://guolei1130.github.io/


### Xposed简介

Xposed框架是一款可以在不修改APK的情况下影响程序运行(修改系统)的框架服务，基于它可以制作出许多功能强大的模块，且在功能不冲突的情况下同时运作。项目地址：https://github.com/rovo89 包括以下几个部分：

1. Xposed & android_art ，Xposed framework，核心
2. XposedBridge java 部分的framework，我们开发模块要用到
3. XposedInstaller 安装器，用去安装Xposed framework以及管理Xposed 模块

那么，Xposed有什么应用场景么，就目前来说，我们耳熟能详的应用场景就是抢红包了，xposed的应用场景取决于我们的思维和想法。现在比较火的模块如抢红包之类的，消息防撤回、绿色守护、黑狱、小米去广告等等。


### 如何使用Xposed

就目前的国内情况来讲，要想用Xposed的话，我个人推荐小米手机。

1. root
2. 安装Xposed，要找对应手机RAM对应Android版本的Xposed framework，可以去小米论坛上找
3. 从酷安市场或者Xposed installer里安装自己喜欢的模块，
4. 勾选，重启生效

### 如何开发自己的Xposed模块

关于开发自己的Xposed模块，在Xposed项目的wiki中，有很详细的介绍，并且开发Xposed模块的话确实比较简单，难点在于找到你想实现功能的切入点，我们这里以去掉小米桌面的广告为例。关于如何开发Xposed模块，前往[Xposed Wiki 查看学习](https://github.com/rovo89/XposedBridge/wiki/Development-tutorial)

要想实现去广告，首先我们需要想一些办法，我最初想到的办法是从广告的Api入手，替换掉url地址，经过试验，失败了。但是发现，小米桌面文件夹(就那个好几个app放在一起的地方)有个隐藏的功能，修改名称的时候，下面有个是否推荐那个，这里可以关掉广告，所以，从这里入手。

第一步，我们需要拿到小米Home的代码，这个对于我们root了的手机，简单的很，不过，这里我们要对代码进行一些操作，因为我们能拿到的是odex文件，我们要将其转化为jar文件,转换过程odex->smail->dex->jar，这里我们借助两个开源项目可以轻松完成。https://github.com/JesusFreke/smali (https://bitbucket.org/JesusFreke/smali/downloads/)

https://github.com/pxb1988/dex2jar


第二步，找到对应点击文件夹图标的方法，我们直接在Launcher中搜索openF(older)，关于Launcher，这里不多说。我们能搜索到如下代码。

```

  public void openFolder(FolderInfo paramFolderInfo, View paramView)
  {
    this.mFolderClosingInNormalEdit = false;
    this.mWorkspace.post(new Runnable(this, paramFolderInfo)
    {
      public void run()
      {
        if (Launcher.access$1100(this.this$0).isOpened())
          return;
        Launcher.access$3702(this.this$0, false);
        ShortcutIcon.setEnableLoadingAnim(true);
        Launcher.access$1100(this.this$0).bind(this.val$folderInfo);
        Launcher.access$1100(this.this$0).open();
        this.this$0.updateStatusBarClock();
        Launcher.access$3800(this.this$0).cancel();
        if ((this.this$0.isInNormalEditing()) || (this.this$0.isSceneShowing()))
          Launcher.access$3800(this.this$0).setDuration(Folder.DEFAULT_FOLDER_BACKGROUND_SHORT_DURATION);
        while (true)
        {
          do
          {
            Launcher.access$3800(this.this$0).setFloatValues(new float[] { 0F, 1F });
            Launcher.access$3800(this.this$0).setInterpolator(new CubicEaseInOutInterpolater());
            Launcher.access$3800(this.this$0).start();
          }
          while (this.this$0.isInEditing();
          this.val$folderInfo.onLaunch();
          LauncherModel.updateItemFlagAndLaunchCount(this.this$0, this.val$folderInfo);
          return;
          Launcher.access$3800(this.this$0).setDuration(Folder.DEFAULT_FOLDER_OPEN_DURATION);
        }
      }
    });
  }
```

我们这里，能发现FolderInfo这个类作为了一个参数，很明显，这是描述Folder的信息的，那么是否推荐这个属性，一定是在这里面了。我们进去看看。

在这里搜索recommend，我们能发现这么一个变量。

```
private boolean mEnbaleRecommendAppsView = false;
```

细心的同学发现他这个变量名是不是手抖了。。。

private？那么，我们不管三七二十一，直接干掉get方法，直接返回false是不是就可以实现呢？尝试一波，写下如下代码。


```
public class XposedDemo implements IXposedHookLoadPackage {
    private static final String TAG = "myxposed";

    @Override
    public void handleLoadPackage(XC_LoadPackage.LoadPackageParam lpparam) throws Throwable {
        Log.e(TAG, "handleLoadPackage: " + lpparam.packageName + "----->" + lpparam.appInfo.sourceDir);
        if (lpparam.packageName.equals("com.miui.home")) {
            Log.e(TAG, "handleLoadPackage: " + "miui.home ");

            findAndHookMethod("com.miui.home.launcher.FolderInfo", lpparam.classLoader, "isRecommendAppsViewEnable", Context.class, new XC_MethodReplacement() {
                @Override
                protected Object replaceHookedMethod(MethodHookParam param) throws Throwable {
                    Log.e(TAG, "replaceHookedMethod: " + "被调用了");
                    return false;
                }
            });
        }
    }
}
```

安装，勾选，重启。然后点开文件夹，发现，舒服的很，确实没了，在编辑文件夹属性，把这个推荐打开，哈，还是没有。果然，我们成功了。

### 最后

有没有学到呢？我把小米Home的jar包以及当时做的简陋的ppt放在了 [blog_resource这个仓库](https://github.com/Guolei1130/blog_resource)，有需要的可以去拿。



### 最近访客
<ul class="ds-recent-visitors" data-num-items="46" data-avatar-size="40"></ul>