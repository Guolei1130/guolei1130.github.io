---
title: Activity启动流程
date: 2016-12-25 15:20:05
tags: framework

---
<Excerpt in index | 首页摘要>
### 1.前言

我们每天都在使用startActivity去启动一个新的activty，可有想过这中间的流程是什么？可有想过这涉及到哪些东西？今天，就走一下流程，了解下，activity是如何启动的。


+ <!-- more -->
<The rest of contents | 余下全文>

### 2.从startActivity说起

不管我们是通过startActivity,还是通过startActivityForResult去启动一个activity，最终都会调用，startActivityForResult这个方法，这个方法的核心代码如下：

```java
Instrumentation.ActivityResult ar =
    mInstrumentation.execStartActivity(
        this, mMainThread.getApplicationThread(), mToken, this,
        intent, requestCode, options);
if (ar != null) {
    mMainThread.sendActivityResult(
        mToken, mEmbeddedID, requestCode, ar.getResultCode(),
        r.getResultData());
}
```

* 通过Instrumentation去启动activiy，

### 3.Instrumentation#execStartActivity

Instrumentation是一个很关键的类，我们知道Activity也是一个java类，但是他确有声明周期，而声明周期的方法，就是由这个类来控制的。而我们能看到一些插件话框架如DroidPlugin也是通过hook这个类，来做到替换的。

```java
            int result = ActivityManagerNative.getDefault()
                .startActivity(whoThread, who.getBasePackageName(), intent,
                        intent.resolveTypeIfNeeded(who.getContentResolver()),
                        token, target != null ? target.mEmbeddedID : null,
                        requestCode, 0, null, options);
            checkStartActivityResult(result, intent);
```

* 通过AMS启动activity
* 检查结果

ActivityManagerNative.getDefault()如下：

```java
    static public IActivityManager getDefault() {
        return gDefault.get();
    }
```

其中，gDefault是一个Singleton类，他返回的是IActivityManager类型，我们这里要注意，asInterface方法中，返回了AMS的bp客户端，也就是ActivityManagerProxy。而其对应的bn端就是ActivityManagerNative，他的具体实现是ActivityManagerService,也就是我们常说的ams。

### 4.ActivityManagerService#startActivity

而在这里通过startActivityAsUser, 将调用传递给ActivityStackSupervisor。

```java
    @Override
    public final int startActivityAsUser(IApplicationThread caller, String callingPackage,
            Intent intent, String resolvedType, IBinder resultTo, String resultWho, int requestCode,
            int startFlags, ProfilerInfo profilerInfo, Bundle options, int userId) {
        enforceNotIsolatedCaller("startActivity");
        userId = handleIncomingUser(Binder.getCallingPid(), Binder.getCallingUid(), userId,
                false, ALLOW_FULL_ONLY, "startActivity", null);
        // TODO: Switch to user app stacks here.
        return mStackSupervisor.startActivityMayWait(caller, -1, callingPackage, intent,
                resolvedType, null, null, resultTo, resultWho, requestCode, startFlags,
                profilerInfo, null, null, options, false, userId, null, null);
    }
```

这里的mStackSupervisor就是ActivityStackSupervisor对象，从名字上来看，似乎是activiy栈的管理，事实上确实如此。

### 5.ActivityStackSupervisor#startActivityMayWait

这个方法的代码比较长，但是大部分代码都是校验安全性方面的，我们不需要太多的关心，其核心代码如下：

```java
            int res = startActivityLocked(caller, intent, resolvedType, aInfo,
                    voiceSession, voiceInteractor, resultTo, resultWho,
                    requestCode, callingPid, callingUid, callingPackage,
                    realCallingPid, realCallingUid, startFlags, options, ignoreTargetSecurity,
                    componentSpecified, null, container, inTask);
```

而startActivityLocked也很长，我们不去关心其具体逻辑，其大部分代码都是错误检查、权限检查等操作，启动actviy的代码如下：

```java
        err = startActivityUncheckedLocked(r, sourceRecord, voiceSession, voiceInteractor,
                startFlags, true, options, inTask);
```

startActivityUncheckedLocked中涉及到启动模式和activiy栈，代码很复杂，不过我们今天的目的是了解启动流程，因此，直接看重点。在这个方法的最下面，我们能看到如下代码:

```java
        targetStack.mLastPausedActivity = null;
        targetStack.startActivityLocked(r, newTask, doResume, keepCurTransition, options);
```

* 其中，targetStack是ActivityStack,这样，启动流程就从ass转移到了as

### 6.ActivityStack#startActivityLocked

而这个方法的最下面有如下代码。

```java
        if (doResume) {
            mStackSupervisor.resumeTopActivitiesLocked(this, r, options);
        }
```

这样，就又从as转移到了ass，但是，这里没有过多的代码，而是又将操作给了as

```java
 result = targetStack.resumeTopActivityLocked(target, targetOptions);
```

绕半圈，回来了。我们接着跟，在as中，通过resumeTopActivityLocked->resumeTopActivityInnerLocked，在resumeTopActivityInnerLocked中，又调用

```java
mStackSupervisor.startSpecificActivityLocked(next, true, false); 
```
回到as，好吧，好绕。

而在ass的startSpecificActivityLocked方法中，通过如下代码去启动。

```java
realStartActivityLocked(r, app, andResume, checkConfig);
```

在这个方法中做了什么呢？

```java
            app.thread.scheduleLaunchActivity(new Intent(r.intent), r.appToken,
                    System.identityHashCode(r), r.info, new Configuration(mService.mConfiguration),
                    new Configuration(stack.mOverrideConfig), r.compat, r.launchedFromPackage,
                    task.voiceInteractor, app.repProcState, r.icicle, r.persistentState, results,
                    newIntents, !andResume, mService.isNextTransitionForward(), profilerInfo);
```

通过ApplicationThread的scheduleLaunchActivity，去启动一个actvity。


### 7.ApplicationThread#scheduleLaunchActivity

在这个方法中，发送一个消息，然后ActivityThread的H类去处理。

```java
sendMessage(H.LAUNCH_ACTIVITY, r);
```

接收到这个消息之后，调用handleLaunchActivity方法去处理。

```java
Activity a = performLaunchActivity(r, customIntent);
```


在performLaunchActivity方法中，先是通过Instrumentation.newActivity去生成actvity，然后调用callActivityOnCreate。

```java
            activity = mInstrumentation.newActivity(
                    cl, component.getClassName(), r.intent);
                    ...
                    mInstrumentation.callActivityOnCreate(activity, r.state, r.persistentState);
```

### 8.Instrumentation

在这里，先是通过类加载器去构造类对象，

```java
(Activity)cl.loadClass(className).newInstance()
```

然后通过callActivityOnCreate方法，

```java
    public void callActivityOnCreate(Activity activity, Bundle icicle) {
        prePerformCreate(activity);
        activity.performCreate(icicle);
        postPerformCreate(activity);
    }
```
调用activity.performCreate，在这个方法中，便会调用onCreate方法，这样，activity就启动起来了。

### 9.给张图吧。

流程图不一定画的对。😢

![](/images/framework/activity/Activity启动流程图.png)






