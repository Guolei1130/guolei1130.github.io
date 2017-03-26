---
title: ZeusPlugin浅析
date: 2017-03-26 16:08:51
categories: Android
tags: 插件化

---
<Excerpt in index | 首页摘要>
### 前言

从去年开始，插件化和热修复技术就一直很火，本人对这些技术也很关注。虽然说这些技术可能在今年就会退热。但是其中的技术点，我们还是需要get到的。今天就来学习下，掌阅的[ZeusPlugin](https://github.com/iReaderAndroid/ZeusPlugin) 

<!-- more -->
<The rest of contents | 余下全文>


ZeusPlugin中包含插件化和热修两部分，其中热修涉及到的原理以及gradle插件部分，这里就不说了，热修还是QQ空间的超级补丁方案。

现在，开始单独说下插件部分的原理。


### 插件的安装

插件的安装过程分为三个步骤:

* 将插件复制到指定文件夹中
* 进行dex优化
* 将dex文件添加到classloader中
* 将资源添加到AssetManager中

将插件复制到指定文件夹的过程有ZeusPlugin来完成。具体代码，这里不说了。

dex优化过程，生成DexClassLoader即可。

重点看下下面两步。其中添加dex文件的过程由PluginManager#loadPlugin方法来完成，代码如下：

```
public static boolean loadPlugin(String pluginId, int version) {
        synchronized (mLoadLock) {
            if (getLoadedPlugin() != null && getLoadedPlugin().containsKey(pluginId) && getLoadedPlugin().get(pluginId) >= version) {
                return true;
            }
            String pluginApkPath = PluginUtil.getAPKPath(pluginId);
            ZeusPlugin plugin = getPlugin(pluginId);
            if (!PluginUtil.exists(pluginApkPath)) {
                if (getDefaultPlugin().containsKey(pluginId)) {
                    if (!plugin.installAssetPlugin()) {
                        return false;
                    } else {
                        pluginApkPath = PluginUtil.getAPKPath(pluginId);
                    }
                } else {
                    return false;
                }
            }

            PluginManifest meta = plugin.getPluginMeta();
            if (meta == null || Integer.valueOf(meta.version) < version) return false;

            ClassLoader cl = mNowClassLoader;
            if (PluginUtil.isHotFix(pluginId)) {
                loadHotfixPluginClassLoader(pluginId);
            } else {
                //如果一个老版本的插件已经被加载了，则需要先移除
                if (getLoadedPlugin() != null && getLoadedPlugin().containsKey(pluginId)) {
                    if (cl instanceof ZeusClassLoader) {
                        ZeusClassLoader classLoader = (ZeusClassLoader) cl;
                        //移除老版本的插件
                        classLoader.removePlugin(pluginId);
                        clearViewConstructorCache();
                        //添加新版本的插件
                        classLoader.addAPKPath(pluginId, pluginApkPath, PluginUtil.getLibFileInside(pluginId));
                    }
                } else {
                    if (cl instanceof ZeusClassLoader) {
                        ZeusClassLoader classLoader = (ZeusClassLoader) cl;
                        classLoader.addAPKPath(pluginId, pluginApkPath, PluginUtil.getLibFileInside(pluginId));
                    } else {
                        ZeusClassLoader classLoader = new ZeusClassLoader(cl);
                        classLoader.addAPKPath(pluginId, pluginApkPath, PluginUtil.getLibFileInside(pluginId));
                        PluginUtil.setField(mPackageInfo, "mClassLoader", classLoader);
                        Thread.currentThread().setContextClassLoader(classLoader);
                        mNowClassLoader = classLoader;
                    }
                }
                putLoadedPlugin(pluginId, Integer.valueOf(meta.version));
            }
            if (!PluginUtil.isHotfixWithoutResFile(pluginId)) {
                reloadInstalledPluginResources();
            }
        }
        return true;
    }
```

代码虽然长，但是逻辑却很简单，调用ZeusClassLoader#addApkPath的方法，加入。这里的具体代码也不分析了，关于双亲委托机制，就不说了。

这些做完之后，会调用reloadInstalledPluginResources，加载资源并清除掉之前的缓存。

```
   private static void reloadInstalledPluginResources() {
        try {
            AssetManager assetManager = AssetManager.class.newInstance();
            Method addAssetPath = AssetManager.class.getMethod("addAssetPath", String.class);
            addAssetPath.invoke(assetManager, mBaseContext.getPackageResourcePath());
            if (mLoadedPluginList != null && mLoadedPluginList.size() != 0) {
                //每个插件的packageID都不能一样
                for (String id : mLoadedPluginList.keySet()) {
                    //只有带有资源的补丁才会执行添加到assetManager中
                    if (!PluginUtil.isHotfixWithoutResFile(id)) {
                        addAssetPath.invoke(assetManager, PluginUtil.getAPKPath(id));
                    }
                }
            }
            //这里提前创建一个resource是因为Resources的构造函数会对AssetManager进行一些变量的初始化
            //还不能创建系统的Resources类，否则中兴系统会出现崩溃问题
            PluginResources newResources = new PluginResources(assetManager,
                    mBaseContext.getResources().getDisplayMetrics(),
                    mBaseContext.getResources().getConfiguration());

            PluginUtil.setField(mBaseContext, "mResources", newResources);
            //这是最主要的需要替换的，如果不支持插件运行时更新，只留这一个就可以了
            PluginUtil.setField(mPackageInfo, "mResources", newResources);

            //清除一下之前的resource的数据，释放一些内存
            //因为这个resource有可能还被系统持有着，内存都没被释放
            clearResoucesDrawableCache(mNowResources);

            mNowResources = newResources;
            //需要清理mtheme对象，否则通过inflate方式加载资源会报错
            //如果是activity动态加载插件，则需要把activity的mTheme对象也设置为null
            PluginUtil.setField(mBaseContext, "mTheme", null);
        } catch (Throwable e) {
            e.printStackTrace();
        }
    }
```

同样是通过一系列反射调用。略。

### 组件启动

和其他一样，这里也是需要进行占桩，不过这里比DroidPlugin的处理要简单点，但是我们需要预先确定。这一点比较麻烦。关于如何占桩，这里不说了，感兴趣的看下weishu的文章。还有一点区别就是，我们这里调用通过Classloader根据类名去获取class信息的。所以我们不需要对Instrumentation进行特别大的修改。详情，看源码吧。

### 资源冲突

这里是通过修改aapt，通过固定资源id前几位的方式做的。关于aapt修改，github上有不少代码，感兴趣的可以看下，这里占个坑。我也没看~~~

### 总结

ZeusPlugin很轻量，但是能满足我们的需求，个人感觉是一个不错的选择。


### 最近访客
<ul class="ds-recent-visitors" data-num-items="46" data-avatar-size="40"></ul>