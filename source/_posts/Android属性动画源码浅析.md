---
title: Android属性动画源码浅析
date: 2017-01-19 16:32:38
categories: Android
tags: 源码

---
<Excerpt in index | 首页摘要>
### 前言

日常开发离不开动画，属性动画更为强大，我们不仅要知道如何使用，更要知道他的原理。这样，才能得心应手。那么，今天，就从最简单的来说，了解下属性动画的原理。

<!-- more -->
<The rest of contents | 余下全文>


```
        ObjectAnimator
                .ofInt(mView,"width",100,500)
                .setDuration(1000)
                .start();
```

### ObjectAnimator#ofInt

以这个为例，代码如下。

```
    public static ObjectAnimator ofInt(Object target, String propertyName, int... values) {
        ObjectAnimator anim = new ObjectAnimator(target, propertyName);
        anim.setIntValues(values);
        return anim;
    }
```

在这个方法中，首先会new一个ObjectAnimator对象，然后通过setIntValues方法将值设置进去，然后返回。在ObjectAnimator的构造方法中，会通过setTarget方法设置当前动画的对象，通过setPropertyName设置当前的属性名。我们重点说下setIntValues方法。

```
    public void setIntValues(int... values) {
        if (mValues == null || mValues.length == 0) {
            // No values yet - this animator is being constructed piecemeal. Init the values with
            // whatever the current propertyName is
            if (mProperty != null) {
                setValues(PropertyValuesHolder.ofInt(mProperty, values));
            } else {
                setValues(PropertyValuesHolder.ofInt(mPropertyName, values));
            }
        } else {
            super.setIntValues(values);
        }
    }
```

首先会判断，mValues是不是null，我们这里是null，并且mProperty也是null，所以会调用
setValues(PropertyValuesHolder.ofInt(mPropertyName, values));方法。先看PropertyValuesHolder.ofInt方法，PropertyValuesHolder这个类是holds属性和值的，在这个方法会构造一个IntPropertyValuesHolder对象并返回。

```
    public static PropertyValuesHolder ofInt(String propertyName, int... values) {
        return new IntPropertyValuesHolder(propertyName, values);
    }

```

IntPropertyValuesHolder的构造方法如下：

```
        public IntPropertyValuesHolder(String propertyName, int... values) {
            super(propertyName);
            setIntValues(values);
        }
```

在这里，首先会调用他的分类的构造方法，然后调用setIntValues方法，在他父类的构造方法中，只是设置了下propertyName。setIntValues内容如下：

```
        public void setIntValues(int... values) {
            super.setIntValues(values);
            mIntKeyframes = (Keyframes.IntKeyframes) mKeyframes;
        }
```

在父类的setIntValues方法中，初始化了mValueType为int.class，mKeyframes为KeyframeSet.ofInt(values)。其中KeyframeSet为关键帧集合。然后将mKeyframes赋值给mIntKeyframes。

#### KeyframeSet

这个类是记录关键帧的。我们看下他的ofInt方法。

```
    public static KeyframeSet ofInt(int... values) {
        int numKeyframes = values.length;
        IntKeyframe keyframes[] = new IntKeyframe[Math.max(numKeyframes,2)];
        if (numKeyframes == 1) {
            keyframes[0] = (IntKeyframe) Keyframe.ofInt(0f);
            keyframes[1] = (IntKeyframe) Keyframe.ofInt(1f, values[0]);
        } else {
            keyframes[0] = (IntKeyframe) Keyframe.ofInt(0f, values[0]);
            for (int i = 1; i < numKeyframes; ++i) {
                keyframes[i] =
                        (IntKeyframe) Keyframe.ofInt((float) i / (numKeyframes - 1), values[i]);
            }
        }
        return new IntKeyframeSet(keyframes);
    }
```

在这里呢？根据传入的values来计算关键帧，最后返回IntKeyframeSet。

回到ObjectAnimator里面，这里的setValues用的是父类ValueAnimator的

#### ValueAnimator#setValues

```
    public void setValues(PropertyValuesHolder... values) {
        int numValues = values.length;
        mValues = values;
        mValuesMap = new HashMap<String, PropertyValuesHolder>(numValues);
        for (int i = 0; i < numValues; ++i) {
            PropertyValuesHolder valuesHolder = values[i];
            mValuesMap.put(valuesHolder.getPropertyName(), valuesHolder);
        }
        // New property/values/target should cause re-initialization prior to starting
        mInitialized = false;
    }

```

这里的操作就简单了，就是把PropertyValuesHolder放入到mValuesMap中。

### ObjectAnimator#start 

这个方法就是动画开始的地方。

```
    public void start() {
        // See if any of the current active/pending animators need to be canceled
        AnimationHandler handler = sAnimationHandler.get();
        if (handler != null) {
            int numAnims = handler.mAnimations.size();
            for (int i = numAnims - 1; i >= 0; i--) {
                if (handler.mAnimations.get(i) instanceof ObjectAnimator) {
                    ObjectAnimator anim = (ObjectAnimator) handler.mAnimations.get(i);
                    if (anim.mAutoCancel && hasSameTargetAndProperties(anim)) {
                        anim.cancel();
                    }
                }
            }
            numAnims = handler.mPendingAnimations.size();
            for (int i = numAnims - 1; i >= 0; i--) {
                if (handler.mPendingAnimations.get(i) instanceof ObjectAnimator) {
                    ObjectAnimator anim = (ObjectAnimator) handler.mPendingAnimations.get(i);
                    if (anim.mAutoCancel && hasSameTargetAndProperties(anim)) {
                        anim.cancel();
                    }
                }
            }
            numAnims = handler.mDelayedAnims.size();
            for (int i = numAnims - 1; i >= 0; i--) {
                if (handler.mDelayedAnims.get(i) instanceof ObjectAnimator) {
                    ObjectAnimator anim = (ObjectAnimator) handler.mDelayedAnims.get(i);
                    if (anim.mAutoCancel && hasSameTargetAndProperties(anim)) {
                        anim.cancel();
                    }
                }
            }
        }
        if (DBG) {
            Log.d(LOG_TAG, "Anim target, duration: " + getTarget() + ", " + getDuration());
            for (int i = 0; i < mValues.length; ++i) {
                PropertyValuesHolder pvh = mValues[i];
                Log.d(LOG_TAG, "   Values[" + i + "]: " +
                    pvh.getPropertyName() + ", " + pvh.mKeyframes.getValue(0) + ", " +
                    pvh.mKeyframes.getValue(1));
            }
        }
        super.start();
    }
```

首先呢，会获取AnimationHandler对象，如果不为空的话，就会判断是mAnimations、mPendingAnimations、mDelayedAnims中的动画，并且取消。最后调用父类的start方法。


### ValueAnimator#start

```
    private void start(boolean playBackwards) {
        if (Looper.myLooper() == null) {
            throw new AndroidRuntimeException("Animators may only be run on Looper threads");
        }
        mReversing = playBackwards;
        mPlayingBackwards = playBackwards;
        if (playBackwards && mSeekFraction != -1) {
            if (mSeekFraction == 0 && mCurrentIteration == 0) {
                // special case: reversing from seek-to-0 should act as if not seeked at all
                mSeekFraction = 0;
            } else if (mRepeatCount == INFINITE) {
                mSeekFraction = 1 - (mSeekFraction % 1);
            } else {
                mSeekFraction = 1 + mRepeatCount - (mCurrentIteration + mSeekFraction);
            }
            mCurrentIteration = (int) mSeekFraction;
            mSeekFraction = mSeekFraction % 1;
        }
        if (mCurrentIteration > 0 && mRepeatMode == REVERSE &&
                (mCurrentIteration < (mRepeatCount + 1) || mRepeatCount == INFINITE)) {
            // if we were seeked to some other iteration in a reversing animator,
            // figure out the correct direction to start playing based on the iteration
            if (playBackwards) {
                mPlayingBackwards = (mCurrentIteration % 2) == 0;
            } else {
                mPlayingBackwards = (mCurrentIteration % 2) != 0;
            }
        }
        int prevPlayingState = mPlayingState;
        mPlayingState = STOPPED;
        mStarted = true;
        mStartedDelay = false;
        mPaused = false;
        updateScaledDuration(); // in case the scale factor has changed since creation time
        AnimationHandler animationHandler = getOrCreateAnimationHandler();
        animationHandler.mPendingAnimations.add(this);
        if (mStartDelay == 0) {
            // This sets the initial value of the animation, prior to actually starting it running
            if (prevPlayingState != SEEKED) {
                setCurrentPlayTime(0);
            }
            mPlayingState = STOPPED;
            mRunning = true;
            notifyStartListeners();
        }
        animationHandler.start();
    }
```

* 先初始化一些值
* updateScaledDuration 缩放时间，默认为1.0f
* 获取或者创建AnimationHandler，将动画加入到mPendingAnimations列表中，
* 如果没延迟，通知监听器
* animationHandler.start



在animationHandler.start中，会调用scheduleAnimation方法，在这个种，会用mChoreographerpost一个callback，最终会执行mAnimate的run方法。mChoreographerpost涉及到VSYNC，这里不多介绍。

### mAnimate#run

```
doAnimationFrame(mChoreographer.getFrameTime());
```

在这里会用过doAnimationFrame设置动画帧，我们看下这个方法的代码。

```
        void doAnimationFrame(long frameTime) {
            mLastFrameTime = frameTime;

            // mPendingAnimations holds any animations that have requested to be started
            // We're going to clear mPendingAnimations, but starting animation may
            // cause more to be added to the pending list (for example, if one animation
            // starting triggers another starting). So we loop until mPendingAnimations
            // is empty.
            while (mPendingAnimations.size() > 0) {
                ArrayList<ValueAnimator> pendingCopy =
                        (ArrayList<ValueAnimator>) mPendingAnimations.clone();
                mPendingAnimations.clear();
                int count = pendingCopy.size();
                for (int i = 0; i < count; ++i) {
                    ValueAnimator anim = pendingCopy.get(i);
                    // If the animation has a startDelay, place it on the delayed list
                    if (anim.mStartDelay == 0) {
                        anim.startAnimation(this);
                    } else {
                        mDelayedAnims.add(anim);
                    }
                }
            }

            // Next, process animations currently sitting on the delayed queue, adding
            // them to the active animations if they are ready
            int numDelayedAnims = mDelayedAnims.size();
            for (int i = 0; i < numDelayedAnims; ++i) {
                ValueAnimator anim = mDelayedAnims.get(i);
                if (anim.delayedAnimationFrame(frameTime)) {
                    mReadyAnims.add(anim);
                }
            }
            int numReadyAnims = mReadyAnims.size();
            if (numReadyAnims > 0) {
                for (int i = 0; i < numReadyAnims; ++i) {
                    ValueAnimator anim = mReadyAnims.get(i);
                    anim.startAnimation(this);
                    anim.mRunning = true;
                    mDelayedAnims.remove(anim);
                }
                mReadyAnims.clear();
            }

            // Now process all active animations. The return value from animationFrame()
            // tells the handler whether it should now be ended
            int numAnims = mAnimations.size();
            for (int i = 0; i < numAnims; ++i) {
                mTmpAnimations.add(mAnimations.get(i));
            }
            for (int i = 0; i < numAnims; ++i) {
                ValueAnimator anim = mTmpAnimations.get(i);
                if (mAnimations.contains(anim) && anim.doAnimationFrame(frameTime)) {
                    mEndingAnims.add(anim);
                }
            }
            mTmpAnimations.clear();
            if (mEndingAnims.size() > 0) {
                for (int i = 0; i < mEndingAnims.size(); ++i) {
                    mEndingAnims.get(i).endAnimation(this);
                }
                mEndingAnims.clear();
            }

            // Schedule final commit for the frame.
            mChoreographer.postCallback(Choreographer.CALLBACK_COMMIT, mCommit, null);

            // If there are still active or delayed animations, schedule a future call to
            // onAnimate to process the next frame of the animations.
            if (!mAnimations.isEmpty() || !mDelayedAnims.isEmpty()) {
                scheduleAnimation();
            }
        }
```

方法较长，逻辑如下：

* 从mPendingAnimations中取出动画，根据事先选择startAnimation还是加入到mDelayedAnims列表。
* 如果mDelayedAnims列表中的动画准备好了，就加入到mReadyAnims列表中
* 从mAnimations列表中取出要执行的动画，加入到mTmpAnimations列表
* 通过doAnimationFrame方法执行动画帧
* 继续执行scheduleAnimation

从上面我们能看出，执行动画的关键是doAnimationFrame方法。在这个方法中，会调用animationFrame方法。

### ValueAniator#animationFrame

```
   boolean animationFrame(long currentTime) {
        boolean done = false;
        switch (mPlayingState) {
        case RUNNING:
        case SEEKED:
            float fraction = mDuration > 0 ? (float)(currentTime - mStartTime) / mDuration : 1f;
            if (mDuration == 0 && mRepeatCount != INFINITE) {
                // Skip to the end
                mCurrentIteration = mRepeatCount;
                if (!mReversing) {
                    mPlayingBackwards = false;
                }
            }
            if (fraction >= 1f) {
                if (mCurrentIteration < mRepeatCount || mRepeatCount == INFINITE) {
                    // Time to repeat
                    if (mListeners != null) {
                        int numListeners = mListeners.size();
                        for (int i = 0; i < numListeners; ++i) {
                            mListeners.get(i).onAnimationRepeat(this);
                        }
                    }
                    if (mRepeatMode == REVERSE) {
                        mPlayingBackwards = !mPlayingBackwards;
                    }
                    mCurrentIteration += (int) fraction;
                    fraction = fraction % 1f;
                    mStartTime += mDuration;
                    // Note: We do not need to update the value of mStartTimeCommitted here
                    // since we just added a duration offset.
                } else {
                    done = true;
                    fraction = Math.min(fraction, 1.0f);
                }
            }
            if (mPlayingBackwards) {
                fraction = 1f - fraction;
            }
            animateValue(fraction);
            break;
        }

        return done;
    }
```

* 计算fraction
* 调用animateValue方法

<span style="color:red">根据虚拟机执行引擎动态分派原则，这里会调用ObjectAnimator的animateValue方法。<span>

### ObjectAnimator#animateValue


```
    void animateValue(float fraction) {
        final Object target = getTarget();
        if (mTarget != null && target == null) {
            // We lost the target reference, cancel and clean up.
            cancel();
            return;
        }

        super.animateValue(fraction);
        int numValues = mValues.length;
        for (int i = 0; i < numValues; ++i) {
            mValues[i].setAnimatedValue(target);
        }
    }

```

这里主要干了两件事，

* 调用父类的animateValue方法
* 通过setAnimatedValue设置属性

其父类的方法如下：

```
    void animateValue(float fraction) {
        fraction = mInterpolator.getInterpolation(fraction);
        mCurrentFraction = fraction;
        int numValues = mValues.length;
        for (int i = 0; i < numValues; ++i) {
            mValues[i].calculateValue(fraction);
        }
        if (mUpdateListeners != null) {
            int numListeners = mUpdateListeners.size();
            for (int i = 0; i < numListeners; ++i) {
                mUpdateListeners.get(i).onAnimationUpdate(this);
            }
        }
    }
```

在这个方法中，会通过Interpolator得到出当前的fraction，并通过calculateValue来计算当前应该的值，这里会调用IntPropertyValuesHolder的calculateValue

```
        void calculateValue(float fraction) {
            mIntAnimatedValue = mIntKeyframes.getIntValue(fraction);
        }
```

我们知道，mIntKeyframes对应的是IntKeyframeSet。在这个类的getIntValue中，会通过TypeEvaluator来计算当前对应的值。不多说了。

最后，回到animateValue。计算了值之后，会调用setAnimatedValue来设置值。我们看看他的实现。

### IntPropertyValuesHolder#setAnimatedValue

```
        void setAnimatedValue(Object target) {
            if (mIntProperty != null) {
                mIntProperty.setValue(target, mIntAnimatedValue);
                return;
            }
            if (mProperty != null) {
                mProperty.set(target, mIntAnimatedValue);
                return;
            }
            if (mJniSetter != 0) {
                nCallIntMethod(target, mJniSetter, mIntAnimatedValue);
                return;
            }
            if (mSetter != null) {
                try {
                    mTmpValueArray[0] = mIntAnimatedValue;
                    mSetter.invoke(target, mTmpValueArray);
                } catch (InvocationTargetException e) {
                    Log.e("PropertyValuesHolder", e.toString());
                } catch (IllegalAccessException e) {
                    Log.e("PropertyValuesHolder", e.toString());
                }
            }
        }
```

恩，到这里就能看到修改属性值得痕迹了，有以下四种情况

* mIntProperty不为null
* mProperty不为null
* mJniSetter不为null
* mSetter不为null

首先，我们通过String propertyName, int... values参数构造的对象，mIntProperty为null，并且mProperty也为null。那其他两个是怎么来的呢？似乎漏了什么？

还节的，在doAnimationFrame中，直接调用startAnimation么?没错，就是这里。

### startAnimation

在这个方法中调用了initAnimation方法。还是根据动态分派规则，这里调用ObjectAnimator的initAnimation方法。在这里调用PropertyValuesHolder的setupSetterAndGetter方法，在这里对mSetter等进行了初始化，这里就不多说了，大家自己看代码吧。










### 最近访客
<ul class="ds-recent-visitors" data-num-items="46" data-avatar-size="40"></ul>