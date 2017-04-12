---
title: tinker-loader部分
date: 2017-04-12 21:00:20
tags: tinker

---
<Excerpt in index | 首页摘要>
### 前言

tinker-loader部分负责对补丁包进行检测和加载，分为三部分

* dex
* so
* resource

<!-- more -->
<The rest of contents | 余下全文>


### TinkerLoader

这是loader的大管家，在他的tryLoad方法中，调用内部的tryLoadPatchFilesInternal方法，在这个方法中，进行各种验证。然后调用TinkerDexLoader#loadTinkerJars 加载dex，利用TinkerResourceLoader的loadTinkerResources来加载补丁resource。并将结果什么的写入到Intent中

### TinkerDexLoader

这个类负责检查dex的合法性已经加载dex。加载过程的主要代码如下

```
SystemClassLoaderAdder.installDexes(application, classLoader, optimizeDir, legalFiles);

```

在SystemClassLoaderAdder.installDexes中，根绝不同的版本，选择不同的方式去hook。

```

        if (!files.isEmpty()) {
            ClassLoader classLoader = loader;
            if (Build.VERSION.SDK_INT >= 24) {
                classLoader = AndroidNClassLoader.inject(loader, application);
            }
            //because in dalvik, if inner class is not the same classloader with it wrapper class.
            //it won't fail at dex2opt
            if (Build.VERSION.SDK_INT >= 23) {
                V23.install(classLoader, files, dexOptDir);
            } else if (Build.VERSION.SDK_INT >= 19) {
                V19.install(classLoader, files, dexOptDir);
            } else if (Build.VERSION.SDK_INT >= 14) {
                V14.install(classLoader, files, dexOptDir);
            } else {
                V4.install(classLoader, files, dexOptDir);
            }
            //install done
            sPatchDexCount = files.size();
            Log.i(TAG, "after loaded classloader: " + classLoader + ", dex size:" + sPatchDexCount);

            if (!checkDexInstall(classLoader)) {
                //reset patch dex
                SystemClassLoaderAdder.uninstallPatchDex(classLoader);
                throw new TinkerRuntimeException(ShareConstants.CHECK_DEX_INSTALL_FAIL);
            }
        }
```

其中各个版本都是hook classLoader进行插桩处理，具体的代码，我们就不看了。

### TinkerResourceLoader

在这个类的loadTinkerResources方法中，有加载补丁资源包的代码。

```
TinkerResourcePatcher.monkeyPatchExistingResources(context, resourceString);
```

加载的代码和dex的类似，都是hook一些东西，关于hook那些东西，由于需要对AssetManager比较熟悉，我这里不熟悉，就不记录了，可以去网上找点资料。




### 最近访客
<ul class="ds-recent-visitors" data-num-items="46" data-avatar-size="40"></ul>