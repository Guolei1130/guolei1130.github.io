---
title: ContentProvider凑数文
date: 2016-12-29 18:33:56
categories: Android
tags: framework

---
<Excerpt in index | 首页摘要>
这一篇，没营养，凑数用的。

### 1. ActivityThread的main方法

* 我们知道android应用程序的入口是ActivityThread的main方法。
* ContentProvid是何时、何流程，调用的onCreate方法呢？

ActivityThread的main方法说起。

+ <!-- more -->
<The rest of contents | 余下全文>



```
        ActivityThread thread = new ActivityThread();
        thread.attach(false);
```

在main方法中，我们能发现如上代码，attach什么？我们跟进去看。

```
            RuntimeInit.setApplicationObject(mAppThread.asBinder());
            final IActivityManager mgr = ActivityManagerNative.getDefault();
            try {
                mgr.attachApplication(mAppThread);
            } catch (RemoteException ex) {
                // Ignore
            }
```

我们的应用程序，会走这个if分支，从方法名我们能看出来，原来是将ApplicationThread和Applicatin关联起来，我们继续看，在ams的attachApplication方法中，会调用attachApplicationLocked，去做关联。继续看这个方法，会发现

```
List<ProviderInfo> providers = normalMode ? generateApplicationProvidersLocked(app) : null;
```

* app ProcessRecord, 进程相关信息
* ProviderInfo contentprovider信息

再然后，我们会发现，调用ApplicationThread#bindApplication方法，在这个方法中发送消息，我们的H类，调用handleBindApplication去处理。在这个方法中有如下代码：

```
            if (!data.restrictedBackupMode) {
                List<ProviderInfo> providers = data.providers;
                if (providers != null) {
                    installContentProviders(app, providers);
                    // For process that contains content providers, we want to
                    // ensure that the JIT is enabled "at some point".
                    mH.sendEmptyMessageDelayed(H.ENABLE_JIT, 10*1000);
                }
            }
```

找了半天，总算看到了相关的内容。这个installContentProviders就是用来装载ContentProvider的。

```
    private void installContentProviders(
            Context context, List<ProviderInfo> providers) {
        final ArrayList<IActivityManager.ContentProviderHolder> results =
            new ArrayList<IActivityManager.ContentProviderHolder>();

        for (ProviderInfo cpi : providers) {
            if (DEBUG_PROVIDER) {
                StringBuilder buf = new StringBuilder(128);
                buf.append("Pub ");
                buf.append(cpi.authority);
                buf.append(": ");
                buf.append(cpi.name);
                Log.i(TAG, buf.toString());
            }
            IActivityManager.ContentProviderHolder cph = installProvider(context, null, cpi,
                    false /*noisy*/, true /*noReleaseNeeded*/, true /*stable*/);
            if (cph != null) {
                cph.noReleaseNeeded = true;
                results.add(cph);
            }
        }

        try {
            ActivityManagerNative.getDefault().publishContentProviders(
                getApplicationThread(), results);
        } catch (RemoteException ex) {
        }
    }
```

总体分为两步，

* installProvider 生成ContentProviderHolder对象
* publishContentProviders 发布出去

### 2.installProvider


```
                final java.lang.ClassLoader cl = c.getClassLoader();
                localProvider = (ContentProvider)cl.
                    loadClass(info.name).newInstance();
                provider = localProvider.getIContentProvider();
                if (provider == null) {
                    Slog.e(TAG, "Failed to instantiate class " +
                          info.name + " from sourceDir " +
                          info.applicationInfo.sourceDir);
                    return null;
                }
                if (DEBUG_PROVIDER) Slog.v(
                    TAG, "Instantiating local provider " + info.name);
                // XXX Need to create the correct context for this provider.
                localProvider.attachInfo(c, info);
```

在这块的代码中，会生成ContentProvider对象，并且调用attachInfo方法。在attachInfo方法中，我们就能发现

```
ContentProvider.this.onCreate();
```

### 3.query操作

Context的实现类是ContextImpl,通过观察代码，我们能够发现，mContentResolver的类型是ApplicationContentResolver，这个类实现类ContentResolver的一些抽象方法。

query方法也比较复杂，涉及到应用计数的问题，我看不太懂。建议看这个[理解ContentProvider原理](http://gityuan.com/2016/07/30/content-provider/) 

* 获取IContentProvider对象
* IContentProvider的query方法


IContentProvider在这里的实现是什么呢？这个在ActivityThread的installProvider方法里能找到。

```
                localProvider = (ContentProvider)cl.
                    loadClass(info.name).newInstance();
                provider = localProvider.getIContentProvider();
```
cp的getIContentProvider返回mTransport，是一个Transport的实例，在它的query方法中，调用了cp的query。

