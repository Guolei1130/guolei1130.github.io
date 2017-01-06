---
title: broadcast流程浅析
date: 2016-12-27 15:45:50
tags: framework

---
<Excerpt in index | 首页摘要>
### 1. 前言

个人看法。

前两篇粗略的看了下四大组件里面的Activity、Service的启动流程，今天，我们来简单的看下BroadcastReceiver的流程。包括

+ <!-- more -->
<The rest of contents | 余下全文>


* 静态广播
* 动态广播
* 发送广播
* 动态注册广播接收者对广播的处理


### 2. 静态广播的注册过程

系统开机之后，会启动很多系统服务，如ams、pms等，而我们的静态广播，就是在pms中完成的，当然，pms中的工作也不只这些。

在PackageManagerService的构造函数中，会调用scanDirLI扫描特定的文件夹，来解析我们已经安装的apk。

```
        for (File file : files) {
            final boolean isPackage = (isApkFile(file) || file.isDirectory())
                    && !PackageInstallerService.isStageName(file.getName());
            if (!isPackage) {
                // Ignore entries which are not packages
                continue;
            }
            try {
                scanPackageLI(file, parseFlags | PackageParser.PARSE_MUST_BE_APK,
                        scanFlags, currentTime, null);
            } catch (PackageManagerException e) {
                                
            }
        }
```

如果是apk文件的话，就会调用scanPackageLI来扫描并解析。而在scanPackageLI中，会创建PackageParser对象，并调用他的parsePackage方法解析apk。而在这个方法中，会根据是文件还是文件夹去选择单个解析还是多个解析。我们以单个解析为例，parseMonolithicPackage。在这个方法中，又会调用parseBaseApk方法，解析生成Package对象，并返回。经过一些列调用之后，会调用

```
private Package parseBaseApk(Resources res, XmlResourceParser parser, int flags,
            String[] outError) 
```

方法，而在这个方法中，会解析各个标签，其中就有appliction标签，这个标签的解析会调用parseBaseApplication方法，其中就会解析receiver标签，并将其加入到

```
owner.receivers.add(a);
```

Package对象的receivers这个arraylist里面，这样，我们以安装app里面的静态广播就保存起来了。随后会调用

```
private PackageParser.Package scanPackageLI(PackageParser.Package pkg, int parseFlags,  
        int scanFlags, long currentTime, UserHandle user)
```

这个方法将其保存在ams里。这里就不多说了。

### 3. 动态广播注册

我们知道，动态广播通过registerReceiver来注册，按照我们以往的知识，我们知道它的实现过程在ContextImpl,最后都会调用到registerReceiverInternal方法中，

```
    private Intent registerReceiverInternal(BroadcastReceiver receiver, int userId,
            IntentFilter filter, String broadcastPermission,
            Handler scheduler, Context context) {
        IIntentReceiver rd = null;
        if (receiver != null) {
            if (mPackageInfo != null && context != null) {
                if (scheduler == null) {
                    scheduler = mMainThread.getHandler();
                }
                rd = mPackageInfo.getReceiverDispatcher(
                    receiver, context, scheduler,
                    mMainThread.getInstrumentation(), true);
            } else {
                if (scheduler == null) {
                    scheduler = mMainThread.getHandler();
                }
                rd = new LoadedApk.ReceiverDispatcher(
                        receiver, context, scheduler, null, true).getIIntentReceiver();
            }
        }
        try {
            return ActivityManagerNative.getDefault().registerReceiver(
                    mMainThread.getApplicationThread(), mBasePackageName,
                    rd, filter, broadcastPermission, userId);
        } catch (RemoteException e) {
            return null;
        }
    }
```

* 注意这里的rd，
* 看到，注册的过程和其他一样，也是交给了ams来完成。

我们直接看ams的registerReceiver方法。这个方法比较长，实际上逻辑是比较简单的。

* 收集粘性广播
* 将我们这个广播接收者加入到mRegisteredReceivers中，
* 插入我们所有的粘性广播，并用scheduleBroadcastsLocked，来分发，这个后面说。

### 4. 发送广播

不管是发送普通广播、有序广播还是粘性广播，都会调用asm的broadcastIntent方法。因此我们就从ams的broadcastIntent开始看,
在这个方法中，又会调用broadcastIntentLocked方法。这个方法代码比较长，分段看看比较很重要的几段。

```
intent.addFlags(Intent.FLAG_EXCLUDE_STOPPED_PACKAGES);
```

这个标志位，是默认不发送给未启动的app。接下来会做一些权限校验的操作。然后会根据不同的action，做不同的处理。
解析来判断是不是粘性广播，如果是粘性广播的话，加入粘性列表。随后，会通过

```
receivers = collectReceiverComponents(intent, resolvedType, callingUid, users);
```
找到所有匹配的BroadcastReceiver。再然后，如果不是有序广播，则构造BroadcastQueue，enqueueParallelBroadcastLocked插入广播记录，scheduleBroadcastsLocked，进行后续操作。

```
        if (!ordered && NR > 0) {
            // If we are not serializing this broadcast, then send the
            // registered receivers separately so they don't wait for the
            // components to be launched.
            final BroadcastQueue queue = broadcastQueueForIntent(intent);
            BroadcastRecord r = new BroadcastRecord(queue, intent, callerApp,
                    callerPackage, callingPid, callingUid, resolvedType, requiredPermissions,
                    appOp, brOptions, registeredReceivers, resultTo, resultCode, resultData,
                    resultExtras, ordered, sticky, false, userId);
            if (DEBUG_BROADCAST) Slog.v(TAG_BROADCAST, "Enqueueing parallel broadcast " + r);
            final boolean replaced = replacePending && queue.replaceParallelBroadcastLocked(r);
            if (!replaced) {
                queue.enqueueParallelBroadcastLocked(r);
                queue.scheduleBroadcastsLocked();
            }
            registeredReceivers = null;
            NR = 0;
        }
```

解析来，会根据接收者的优先级进行排序，得到一个优先级的list，并将通过enqueueOrderedBroadcastLocked加入到优先级广播这个list里，scheduleBroadcastsLocked进行后续操作。

这样，广播的处理就转移到了BroadcastQueue的scheduleBroadcastsLocked中。

```
    public void scheduleBroadcastsLocked() {
        if (DEBUG_BROADCAST) Slog.v(TAG_BROADCAST, "Schedule broadcasts ["
                + mQueueName + "]: current="
                + mBroadcastsScheduled);

        if (mBroadcastsScheduled) {
            return;
        }
        mHandler.sendMessage(mHandler.obtainMessage(BROADCAST_INTENT_MSG, this));
        mBroadcastsScheduled = true;
    }
```

这里会发一个消息，当handler收到这个消息之后，会调用processNextBroadcast来处广播列表。

在这个方法中，首先会处理普通广播代码如下。

```
            while (mParallelBroadcasts.size() > 0) {
                r = mParallelBroadcasts.remove(0);
                r.dispatchTime = SystemClock.uptimeMillis();
                r.dispatchClockTime = System.currentTimeMillis();
                final int N = r.receivers.size();
                if (DEBUG_BROADCAST_LIGHT) Slog.v(TAG_BROADCAST, "Processing parallel broadcast ["
                        + mQueueName + "] " + r);
                for (int i=0; i<N; i++) {
                    Object target = r.receivers.get(i);
                    if (DEBUG_BROADCAST)  Slog.v(TAG_BROADCAST,
                            "Delivering non-ordered on [" + mQueueName + "] to registered "
                            + target + ": " + r);
                    deliverToRegisteredReceiverLocked(r, (BroadcastFilter)target, false);
                }
                addBroadcastToHistoryLocked(r);
                if (DEBUG_BROADCAST_LIGHT) Slog.v(TAG_BROADCAST, "Done with parallel broadcast ["
                        + mQueueName + "] " + r);
            }
```

可以看到，普通广播由deliverToRegisteredReceiverLocked来完成。值得说明的是，这里处理的是我们动态注册的广播接收者。那么，静态注册的怎么处理呢？是通过processCurBroadcastLocked去处理的。

### 5. 动态注册广播接收者对广播的处理

deliverToRegisteredReceiverLocked方法经过一些复杂的判断之后，会调用performReceiveLocked

```
    private static void performReceiveLocked(ProcessRecord app, IIntentReceiver receiver,
            Intent intent, int resultCode, String data, Bundle extras,
            boolean ordered, boolean sticky, int sendingUser) throws RemoteException {
        // Send the intent to the receiver asynchronously using one-way binder calls.
        if (app != null) {
            if (app.thread != null) {
                // If we have an app thread, do the call through that so it is
                // correctly ordered with other one-way calls.
                app.thread.scheduleRegisteredReceiver(receiver, intent, resultCode,
                        data, extras, ordered, sticky, sendingUser, app.repProcState);
            } else {
                // Application has died. Receiver doesn't exist.
                throw new RemoteException("app.thread must not be null");
            }
        } else {
            receiver.performReceive(intent, resultCode, data, extras, ordered,
                    sticky, sendingUser);
        }
    }
```

* 如果进程存在并且，ApplicationThread不为null，就调用ApplicationThread的scheduleRegisteredReceiver方法，
* 否则调用receiver的performReceive，这里的这个receiver，是我们在注册的时候得到的，是一个binder对象。

```
        if (receiver != null) {
            if (mPackageInfo != null && context != null) {
                if (scheduler == null) {
                    scheduler = mMainThread.getHandler();
                }
                rd = mPackageInfo.getReceiverDispatcher(
                    receiver, context, scheduler,
                    mMainThread.getInstrumentation(), true);
            } else {
                if (scheduler == null) {
                    scheduler = mMainThread.getHandler();
                }
                rd = new LoadedApk.ReceiverDispatcher(
                        receiver, context, scheduler, null, true).getIIntentReceiver();
            }
        }
```

其实现是LoadedApk的内部类ReceiverDispatcher的内部类InnerReceiver。

而scheduleRegisteredReceiver方法，也是调用receiver的performReceive。

```
        public void scheduleRegisteredReceiver(IIntentReceiver receiver, Intent intent,
                int resultCode, String dataStr, Bundle extras, boolean ordered,
                boolean sticky, int sendingUser, int processState) throws RemoteException {
            updateProcessState(processState, false);
            receiver.performReceive(intent, resultCode, dataStr, extras, ordered,
                    sticky, sendingUser);
        }

```
receiver的performReceive方法中，调用ReceiverDispatcher的performReceive。

```
                if (rd != null) {
                    rd.performReceive(intent, resultCode, data, extras,
                            ordered, sticky, sendingUser);
                }
```

ReceiverDispatcher的performReceive中，通过handler，post一个runable消息。

```

mActivityThread.post(args)

```
在这个方法中，有如下代码

```
ClassLoader cl =  mReceiver.getClass().getClassLoader();
intent.setExtrasClassLoader(cl);
setExtrasClassLoader(cl);
receiver.setPendingResult(this);
receiver.onReceive(mContext, intent);
```

这样，BroadcastReceiver就创建并调用了onReceive方法。


### 6. 上图

![](/images/framework/broadcast/broadcast流程.png)

