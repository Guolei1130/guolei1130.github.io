---
title: fresco加载数据
date: 2016-12-12 23:51:23
categories: Android
tags: fresco

---
<Excerpt in index | 首页摘要>

### 1. 前言

一般我们通过SimpleDraweeView#setImageURI 去使用，我们现在就来看看它的实现。先来看看继承结构。

+ <!-- more -->
<The rest of contents | 余下全文>



![](/images/fresco/fresco_1.png)


### 2.SimpleDraweeView#setImageURI

在这个方法当中，最终都会调用setController方法。这个方法的实现在DraweeView中，在此之前，我们需要看下GenericDraweeView的初始化，在这个的初始化的时候，会调用其inflateHierarchy方法去设置Hierarchy。

```
  protected void inflateHierarchy(Context context, @Nullable AttributeSet attrs) {
    GenericDraweeHierarchyBuilder builder =
        GenericDraweeHierarchyInflater.inflateBuilder(context, attrs);
    setAspectRatio(builder.getDesiredAspectRatio());
    setHierarchy(builder.build());
  }
```

* 根据attrs更新GenericDraweeHierarchyBuilder
* 更新图像的宽高比
* 设置Hierarchy

在DraweeView的setHierarchy方法中，更新mDraweeHolder，然后设置image为mDraweeHolder.getTopLevelDrawable()。

继续看DraweeView#setImageURI

```
  public void setImageURI(Uri uri, @Nullable Object callerContext) {
    DraweeController controller = mSimpleDraweeControllerBuilder
        .setCallerContext(callerContext)
        .setUri(uri)
        .setOldController(getController())
        .build();
    setController(controller);
  }er.setImageURI(uri);
  }
```

先构造出一个新的DraweeController，然后setController，这个的实现在DraweeView中，就是调用DraweeHolder.setController方法，setController的代码如下：

```
  public void setController(@Nullable DraweeController draweeController) {
    boolean wasAttached = mIsControllerAttached;
    if (wasAttached) {
      detachController();
    }

    // Clear the old controller
    if (mController != null) {
      mEventTracker.recordEvent(Event.ON_CLEAR_OLD_CONTROLLER);
      mController.setHierarchy(null);
    }
    mController = draweeController;
    if (mController != null) {
      mEventTracker.recordEvent(Event.ON_SET_CONTROLLER);
      mController.setHierarchy(mHierarchy);
    } else {
      mEventTracker.recordEvent(Event.ON_CLEAR_CONTROLLER);
    }

    if (wasAttached) {
      attachController();
    }
  }

```

* 如果已经关联过controller，则取消与拿来的关联
* 如果mcontroller不为null，则纪录ON_CLEAR_OLD_CONTROLLER事件，并将mController的Hierarchy设为null，
* 如果传入了参数不为null，则纪录ON_SET_CONTROLLER事件并设置Hierarchy，否则只纪录事件
* 关联controller

在attachController方法中，会调用，onattcah方法。根据上下文，我们知道这个是通过PipelineDraweeControllerBuilder#build方法构建出来的。中间过程的代码这里就不说了，我们只要知道，这里的controller，默认是PipelineDraweeController的一个实例即可。我们看下他的父类的onAttach方法在干什么。

### 3.AbstractDraweeController#onAttach

```
  public void onAttach() {
    if (FLog.isLoggable(FLog.VERBOSE)) {
      FLog.v(
          TAG,
          "controller %x %s: onAttach: %s",
          System.identityHashCode(this),
          mId,
          mIsRequestSubmitted ? "request already submitted" : "request needs submit");
    }
    mEventTracker.recordEvent(Event.ON_ATTACH_CONTROLLER);
    Preconditions.checkNotNull(mSettableDraweeHierarchy);
    mDeferredReleaser.cancelDeferredRelease(this);
    mIsAttached = true;
    if (!mIsRequestSubmitted) {
      submitRequest();
    }
  }
```


* 打印日志
* 纪录事件
* 发送请求

### 4. submitRequest

这个方法分为俩个部分。

* 读取memory cache 同步
* 读取除了memorycache 的其他部分


#### 4.1 读取缓存部分

```
    final T closeableImage = getCachedImage();
    if (closeableImage != null) {
      mDataSource = null;
      mIsRequestSubmitted = true;
      mHasFetchFailed = false;
      mEventTracker.recordEvent(Event.ON_SUBMIT_CACHE_HIT);
      getControllerListener().onSubmit(mId, mCallerContext);
      onNewResultInternal(mId, mDataSource, closeableImage, 1.0f, true, true);
      return;
    }
```

* 通过getCachedImage 获取缓存数据
* 纪录缓存命中事件
* 回调，后面再将

我们重点看下如果获取缓存。获取缓存的实现在PipelineDraweeController的getCachedImage方法中

```
  @Override
  protected CloseableReference<CloseableImage> getCachedImage() {
    if (mMemoryCache == null || mCacheKey == null) {
      return null;
    }
    // We get the CacheKey
    CloseableReference<CloseableImage> closeableImage = mMemoryCache.get(mCacheKey);
    if (closeableImage != null && !closeableImage.get().getQualityInfo().isOfFullQuality()) {
      closeableImage.close();
      return null;
    }
    return closeableImage;
  }
```

可以看到，从MemoryCache中根据key获取，这里的key是怎么来的呢？是在我们生成PipelineDraweeController的时候，生成的。具体的实现在PipelineDraweeControllerBuilder中，这个中不仅生成cachekey，也根据uri生成ImageRequest。

现在我们需要知道MemoryCache是如何初始化的。一切源于PipelineDraweeControllerBuilderSupplier，就是最初的初始化过程，而在其的get方法中，new了PipelineDraweeControllerBuilder。在PipelineDraweeControllerBuilderSupplier的构造函数中，构造了PipelineDraweeControllerFactory对象，其中就有MemoryCache部分，这里 的过程比较绕。

从哪些非常绕的过程中知道，PipelineDraweeControllerFactory的初始化在PipelineDraweeControllerBuilderSupplier的初始化方法中，而cache是 mImagePipeline.getBitmapMemoryCache()得到的。不说了，这部分东西比较绕，所有的初始化过程基本就在上篇。


到这里就知道MemoryCache是mBitmapMemoryCache。而他的默认实现是InstrumentedMemoryCache。这里涉及到三个地方

* ImagePipelineFactory#getBitmapMemoryCache
* BitmapMemoryCacheFactory
* InstrumentedMemoryCache

```
  @Override
  public CloseableReference<V> get(K key) {
    CloseableReference<V> result = mDelegate.get(key);
    if (result == null) {
      mTracker.onCacheMiss();
    } else {
      mTracker.onCacheHit(key);
    }
    return result;
  }
```

我们需要搞懂mDelegate，mTracker，才能知道接下来的流程。mDelegate的类型为CountingMemoryCache，对应的获取过程在ImagePipelineFactory#getBitmapCountingMemoryCache方法。这里不追踪代码了，他是CountingMemoryCache类的实力。最终就是从lru中，取出。mTracker是用来统计的，这里不说了。在追下去就出不来了。

#### 4.2 其他部分

首先看DataSource是怎么来的，相关的代码在AbstractDraweeControllerBuilder#obtainDataSourceSupplier方法中，如果是请求uri那种的，是有mImageRequest的。那么就是getDataSourceSupplierForRequest，通过追代码能够发现，最后是在PipelineDraweeControllerBuilder的getDataSourceForRequest方法中，ImagePipeline#fetchDecodedImage获取的。在追踪发现，实现为SimpleDataSource。

而从其他部分获取的关键就在于fetchDecodedImage中的如下代码

```
      Producer<CloseableReference<CloseableImage>> producerSequence =
          mProducerSequenceFactory.getDecodedImageProducerSequence(imageRequest);
      return submitFetchRequest(
          producerSequence,
          imageRequest,
          lowestPermittedRequestLevelOnSubmit,
          callerContext);
```
我们看看getDecodedImageProducerSequence的具体实现。

```
  public Producer<CloseableReference<CloseableImage>> getDecodedImageProducerSequence(
      ImageRequest imageRequest) {
    Producer<CloseableReference<CloseableImage>> pipelineSequence =
        getBasicDecodedImageSequence(imageRequest);
    if (imageRequest.getPostprocessor() != null) {
      return getPostprocessorSequence(pipelineSequence);
    } else {
      return pipelineSequence;
    }
  }
```

我们先看getBasicDecodedImageSequence，在这个方法中，判断是不是uri是不是网络类型，如果是网络类型，getNetworkFetchSequence，其他类型则选取对应的实现。

> swallow result if prefetch -> bitmap cache get ->
  background thread hand-off -> multiplex -> bitmap cache -> decode -> multiplex ->
  encoded cache -> disk cache -> (webp transcode) -> network fetch.


这里的具体细节我们不管，继续看submitFetchRequest，
在submitFetchRequest函数中做了三件事：

* 取ImageRequest的LowestPermittedRequestLevel和传入的RequestLevel中最高的一级作为此次数据获取的最高缓存获取层；
* 将ImageRequest、本次请求的唯一标识、ImageRequestListener（提供ImageRqeuest事件的回调）、是否需要渐进式加载图片等信息封装进SettableProducerContext。
* 创建AbstractproducerToDataSourceAdapter，它实际上是一种DataSource，在这个过程中会让producer通过SettableProducerContext获取数据。

至此我们就获取了所需要的DataSource，并将它设置给DraweeController。最后便是获取结果并显示了。













