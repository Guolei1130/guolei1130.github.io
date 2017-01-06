---
title: fresco初始化过程
date: 2016-12-12 14:27:31
categories: Android
tags: fresco

---
<Excerpt in index | 首页摘要>

### 1.初始化相关

* ImagePipelineFactory
* PipelineDraweeControllerBuilderSupplier
* SimpleDraweeView

在ImagePipelineFactory初始化ImagePipelineConfig，用来配置一个参数。ImagePipelineConfig通过建造者模式 可以让使用者配置许多参数。包括以下：

+ <!-- more -->
<The rest of contents | 余下全文>




* AnimatedImageFactory 负责解析 动态图，gif和webp
* Bitmap.Config 图片质量
* Supplier<MemoryCacheParams> 内存cache的配置参数
* CacheKeyFactory 生成cachekey的工厂
* Context
* mDownsampleEnabled 是否允许下载相同的图片
* mDecodeMemoryFileEnabled 
* FileCacheFactory 文件缓存的工厂
* mEncodedMemoryCacheParamsSupplier 
* mExecutorSupplier 线程池集
* ImageCacheStatsTracker 图片缓存状态跟踪器
* ImageDecoder 图片解析
* mIsPrefetchEnabledSupplier
* mMainDiskCacheConfig disk磁盘缓存配置
* mMemoryTrimmableRegistry 内存检测注入
* NetworkFetcher 网络访问，用于封装网络
* PlatformBitmapFactory 配置bitmap 平台信息
* PoolFactory poolfactory
* ProgressiveJpegConfig 
* mRequestListeners 请求监听器
* mResizeAndRotateEnabledForNetwork 是否允许调整和旋转
* mSmallImageDiskCacheConfig small disk config
* ImagePipelineExperiments.Builder


其中，大部分我们并不需要配置。

#### 1.1 MemoryCacheParams

内部含有五个成员

* maxCacheSize cache 最大容量
* maxCacheEntries cache中 最多呢个存多少个item（块）
* maxEvictionQueueSize 准备回收 但是还没回收的 容量
* maxEvictionQueueEntries 每个块的最大回收数
* maxCacheEntrySize 每个块的最大的数

从这里可以看出来，内存cache中是分块（页）的。分页 或者分块的好处：查询快，

#### 1.2 CacheKeyFactory

生成cache key的规则。包括bitmap，encoded，渐进式bitmap的等。


默认的DefaultCacheKeyFactory，根据url，resizeoption等等确定。


#### 1.3 FileCacheFactory中的DiskCacheConfig

配置版本，cache路径，大小，error log等

#### 1.4 ImageCacheStatsTracker

cache跟踪回调，有一些列回调。可以自己配置，做一些命中率 统计啥的，

#### 1.5 ImageDecoder

图片解码的入口类。

#### 1.6 NetworkFetcher

网络库的上层封装。默认为HttpUrlConnectionNetworkFetcher，使用httpurlconnection进行下载，我们也可以配置成okhttp 的

#### 1.7 PlatformBitmapFactory

用于createbitmap，并且添加引用信息有三个实现类。

* GingerbreadBitmapFactory
* HoneycombBitmapFactory 对应kikat
* ArtBitmapFactory 对应arm


具体的实现这里暂时忽略。



#### 1.8 PoolFactory
根据PoolConfig，配置PoolFactory。

```
   private final PoolParams mBitmapPoolParams;
  private final PoolStatsTracker mBitmapPoolStatsTracker;
  private final PoolParams mFlexByteArrayPoolParams;
  private final MemoryTrimmableRegistry mMemoryTrimmableRegistry;
  private final PoolParams mNativeMemoryChunkPoolParams;
  private final PoolStatsTracker mNativeMemoryChunkPoolStatsTracker;
  private final PoolParams mSmallByteArrayPoolParams;
  private final PoolStatsTracker mSmallByteArrayPoolStatsTracker;
  
```

poolparams负责配置各种参数，内含三种参数类型。

* PoolParams
	* maxSizeSoftCap 最大软 size
	* maxSizeHardCap 最大硬 size，通过观察DefaultBitmapPoolParams，看得出 这个是memory cache 缓存
	* bucketSizes 每个桶及其对应的容量
	* minBucketSize 桶最小size
	* maxBucketSize 桶最大size
* PoolStatsTracker 状态监测，包括释放 申请内存等
* MemoryTrimmableRegistry


#### 1.9 ProgressiveJpegConfig

渐近式jpeg，

#### 1.10 DiskCacheConfig

磁盘配置。略

### 2. PipelineDraweeControllerBuilderSupplier


构造出PipelineDraweeControllerBuilder。

```
  public PipelineDraweeControllerBuilderSupplier(
      Context context,
      ImagePipelineFactory imagePipelineFactory,
      Set<ControllerListener> boundControllerListeners) {
    mContext = context;
    mImagePipeline = imagePipelineFactory.getImagePipeline();

    final AnimatedFactory animatedFactory = imagePipelineFactory.getAnimatedFactory();
    AnimatedDrawableFactory animatedDrawableFactory = null;
    if (animatedFactory != null) {
      animatedDrawableFactory = animatedFactory.getAnimatedDrawableFactory(context);
    }

    mPipelineDraweeControllerFactory = new PipelineDraweeControllerFactory(
        context.getResources(),
        DeferredReleaser.getInstance(),
        animatedDrawableFactory,
        UiThreadImmediateExecutorService.getInstance(),
        mImagePipeline.getBitmapMemoryCache());
    mBoundControllerListeners = boundControllerListeners;
  }
```

* imagePipelineFactory是通过ImagePipelineFactory.getInstance()返回的。而ImagePipelineFactory是通过传入imagePipelineConfig，根据我们的配置来完成初始化的。
* mPipelineDraweeControllerFactory
* mBoundControllerListeners 默认为null

#### 2.1 ImagePipelineFactory

内部提供了许多get方法去获取一些参数，和以往factory不同的一点是，构造函数中几乎不初始化我们需要的参数，只有在我们需要的时候才会去检查，没有初始化则初始化。

#### 2.2 PipelineDraweeControllerFactory

负责构造PipelineDraweeController。有几个默认的参数。

* Resources
* DeferredReleaser 延迟释放，当主线程处理完当前message之后才进行回收。
* AnimatedDrawableFactory
* Executor
* MemoryCache<CacheKey, CloseableImage>


### 3 SimpleDraweeView#initialize

只是设置了sDraweeControllerBuilderSupplier，注意这是个静态变量。









