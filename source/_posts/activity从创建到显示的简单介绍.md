---
title: activity从创建到显示的简单介绍
date: 2017-11-29 22:38:11
tags: Android源码
categories: Android

---
<Excerpt in index | 首页摘要>
activity是我们平常开发最常用的一个组件，我们有必要了解activity的创建以及显示的过程，这些应该作为我们的储备知识。

<!-- more -->
<The rest of contents | 余下全文>


### Activity的创建

Activity的创建以及初始化的过程是在ActivityThread#performLaunchActivity方法中，在这个方法中，有以下几个关键点，

* 创建Activity
* Activity#attach
* Instrumentation#callActivityOnCreate
* Activity#performStart
* Instrumentation#callActivityOnPostCreate

这个地方能看到Activity生命周期的一小部分。我们需要对其中一些点进行学习，在这些点里面都有一些非常重要的操作。

创建Activity的过程就不说了，直接反射。我们重点说下attach方法，

#### Activity#attach

attach部分代码如下

```
        mWindow = new PhoneWindow(this, window);
        mWindow.setWindowControllerCallback(this);
        mWindow.setCallback(this);
        mWindow.setOnWindowDismissedCallback(this);
        mWindow.getLayoutInflater().setPrivateFactory(this);
```

在Activity的attach方法中，很关键的一点就是初始化Window，从这里就能看到，Window的实现类，是PhoneWindow。PhoneWindow的创建对于我们后面的操作很重要。

#### Activity#onCreate

```
    public void callActivityOnCreate(Activity activity, Bundle icicle,
            PersistableBundle persistentState) {
        prePerformCreate(activity);
        activity.performCreate(icicle, persistentState);
        postPerformCreate(activity);
    }
```

在activity.performCreate中，会调用activity的onCreate方法，这个是我们平常开发中非常熟悉的，在onCreate中，我们调用setContentView去填充布局，并进行一些初始化操作

#### setContentView

到了我们相当熟悉的setContentView,在setContentView中，会调用PhoneWindow的setContentView方法。我们简单看下PhoneWindow的setContentView

```
    public void setContentView(int layoutResID) {
        // Note: FEATURE_CONTENT_TRANSITIONS may be set in the process of installing the window
        // decor, when theme attributes and the like are crystalized. Do not check the feature
        // before this happens.
        if (mContentParent == null) {
            installDecor();
        } else if (!hasFeature(FEATURE_CONTENT_TRANSITIONS)) {
            mContentParent.removeAllViews();
        }

        if (hasFeature(FEATURE_CONTENT_TRANSITIONS)) {
            final Scene newScene = Scene.getSceneForLayout(mContentParent, layoutResID,
                    getContext());
            transitionTo(newScene);
        } else {
            mLayoutInflater.inflate(layoutResID, mContentParent);
        }
        mContentParent.requestApplyInsets();
        final Callback cb = getCallback();
        if (cb != null && !isDestroyed()) {
            cb.onContentChanged();
        }
        mContentParentExplicitlySet = true;
    }
```

在PhoneWindoe的setContentView方法中，会进行初始化DecorView，并将我们设置的布局加载到contentparent中。installDecor的具体逻辑我们这里就不多说了。


### resume过程

在ActivityThread#handleResumeActivity方法中，有两个关键点。

* performResumeActivity
* Window#addView

performResumeActivity中会调用activity的performResume，performResume中会调用onResume，然后进入onresume声明周期中

我们重点说下addView以及后续的处理。

#### addView


```
wm.addView(decor, l);
```
这里的wm是WindowManager，是在attach法法中，通过setWindowManager来实现初始化的，对应的实例为WindowManagerImpl的一个实例。那么，我们去看下WindoeManageImpl的addView方法,在这个方法中，直接调用WindowManagerGlobal的addView方法，我们关心的中点转移了。其中最关键的diam是如下几行。


```
            root = new ViewRootImpl(view.getContext(), display);

            view.setLayoutParams(wparams);

            mViews.add(view);
            mRoots.add(root);
            mParams.add(wparams);
            root.setView(view, wparams, panelParentView);
```

首先创建一个ViewRootImpl，然后setView。ViewRootImpl#setView方法代码较长，我们能发现requestLayout这个方法，进去看下。


```
    @Override
    public void requestLayout() {
        if (!mHandlingLayoutInLayoutRequest) {
            checkThread();
            mLayoutRequested = true;
            scheduleTraversals();
        }
    }
```
在这里，进行了首次线程检查。

```
    void scheduleTraversals() {
        if (!mTraversalScheduled) {
            mTraversalScheduled = true;
            mTraversalBarrier = mHandler.getLooper().getQueue().postSyncBarrier();
            mChoreographer.postCallback(
                    Choreographer.CALLBACK_TRAVERSAL, mTraversalRunnable, null);
            if (!mUnbufferedInputDispatch) {
                scheduleConsumeBatchedInput();
            }
            notifyRendererOfFramePending();
            pokeDrawLockIfNeeded();
        }
    }
```
Choreographer,post了一个Callback，这个callback是view刷新的核心所在。我们看下TraversalRunnable的run方法，

```
    final class TraversalRunnable implements Runnable {
        @Override
        public void run() {
            doTraversal();
        }
    }
```

```
    void doTraversal() {
        if (mTraversalScheduled) {
            mTraversalScheduled = false;
            mHandler.getLooper().getQueue().removeSyncBarrier(mTraversalBarrier);

            if (mProfile) {
                Debug.startMethodTracing("ViewAncestor");
            }

            performTraversals();

            if (mProfile) {
                Debug.stopMethodTracing();
                mProfile = false;
            }
        }
    }
```


在doTraversal中，又会调用performTraversals方法，我们看下performTraversals方法是干啥的。这个方法非常非常的长，但是在这个方法中，有非常关键的performMeasure，performLayout，performDraw等方法，至此，进入的View的的三大过程，，三大过程之后，就显示在我们面前了。






### 最近访客
<ul class="ds-recent-visitors" data-num-items="46" data-avatar-size="40"></ul>