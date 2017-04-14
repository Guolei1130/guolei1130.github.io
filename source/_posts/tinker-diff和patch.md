---
title: tinker-diff和patch
date: 2017-04-14 15:37:27
tags: tinker

---
<Excerpt in index | 首页摘要>
### 前言

本篇轮到说客户端进行patch操作已经patch包生成的过程了。由于这里面涉及到的东西太复杂，就不讲原理了.

<!-- more -->
<The rest of contents | 余下全文>


### TinkerPatchService

这个service就是用来进行patch的，因为patch合成的过程是一个耗时操作。默认的进行合成的类

```
        try {
            if (upgradePatchProcessor == null) {
                throw new TinkerRuntimeException("upgradePatchProcessor is null.");
            }
            result = upgradePatchProcessor.tryPatch(context, path, patchResult);
        } catch (Throwable throwable) {
            e = throwable;
            result = false;
            tinker.getPatchReporter().onPatchException(patchFile, e);
        }
```

在这里，利用upgradePatchProcessor.tryPatch去进行patch操作，默认的实现为UpgradePatch这个类。在这个类中，有如下代码。

```
        if (!DexDiffPatchInternal.tryRecoverDexFiles(manager, signatureCheck, context, patchVersionDirectory, destPatchFile)) {
            TinkerLog.e(TAG, "UpgradePatch tryPatch:new patch recover, try patch dex failed");
            return false;
        }

        if (!BsDiffPatchInternal.tryRecoverLibraryFiles(manager, signatureCheck, context, patchVersionDirectory, destPatchFile)) {
            TinkerLog.e(TAG, "UpgradePatch tryPatch:new patch recover, try patch library failed");
            return false;
        }

        if (!ResDiffPatchInternal.tryRecoverResourceFiles(manager, signatureCheck, context, patchVersionDirectory, destPatchFile)) {
            TinkerLog.e(TAG, "UpgradePatch tryPatch:new patch recover, try patch resource failed");
            return false;
        }
```

上面的代码，分别针对dex，so，resource。

### bsdiff和bspatch

这个是针对二进制文件进行差分和合成的，我昨天试了下，发现即使修改一点点内容，生成的差分文件还是比较大。

[Binary diff/patch utility](http://www.daemonology.net/bsdiff/)

大家可以去上面的链接中，下载到对应的源代码，自行编译，尝试。tinker中使用的对应的java版本，代码几乎完全一致。

如果想了解原理的话，可以参考[ [差量更新系列1]BSDiff算法学习笔记](http://blog.csdn.net/add_ada/article/details/51232889),这篇文章。

不过编译之前，我们需要修改点东西，首先，将Makefile文件的倒数第一行和倒数第三行增加缩进。然后在bspatch.c文件中，添加

```
typedef unsigned char u_char;
```

从新编译，即可生成bsdiff和bspatch的可执行文件。./bsdiff ./bspatch会有提示。如何使用

### dexdiff和dexpatch

这个算法就高大上了，大家可以看这篇文章进行学习。[Tinker Dexdiff算法解析](https://www.zybuluo.com/dodola/note/554061)。


### 总结

这一部分是tinker的核心内容之一，虽然比较难懂，但是资料还是不少的。
### 最近访客
<ul class="ds-recent-visitors" data-num-items="46" data-avatar-size="40"></ul>