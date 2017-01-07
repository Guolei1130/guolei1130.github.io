---
title: fresco用法
date: 2016-12-12 14:27:12
categories: Android
tags: fresco

---
<Excerpt in index | 首页摘要>
### 0.前言

在很久之前，还是学生的时候，使用过fresco，自从来了公司，还没好好学习呢，于是，开始fresco学习之路。

<!-- more -->
<The rest of contents | 余下全文>



### 1.fresco中的关键概念

* Drawees 负责图片的呈现，有三个元素组成，有点像mvc模式
	* DraweeView 继承view，负责图片的显示，一般情况下使用SimpleDraweeView即可
	* DraweeHierarchy DraweeHierarchy 用于组织和维护最终绘制和呈现的 Drawable 对象，相当于MVC中的M。
	* DraweeController DraweeController 负责和 image loader 交互（ Fresco 中默认为 image pipeline, 当然你也可以指定别的），可以创建一个这个类的实例，来实现对所要显示的图片做更多的控制。
如果你还需要对Uri加载到的图片做一些额外的处理，那么你会需要这个类的。
	* DraweeControllerBuilder 
DraweeControllers 由 DraweeControllerBuilder 采用 Builder 模式创建，创建之后，不可修改
	* Listeners 使用 ControllerListener 的一个场景就是设置一个 Listener监听图片的下载。
* The Image Pipeline，Fresco 的 Image Pipeline 负责图片的获取和管理。图片可以来自远程服务器，本地文件，或者Content Provider，本地资源。压缩后的文件缓存在本地存储中，Bitmap数据缓存在内存中。
在5.0系统以下，Image Pipeline 使用 pinned purgeables 将Bitmap数据避开Java堆内存，存在ashmem中。这要求图片不使用时，要显式地释放内存。
SimpleDraweeView自动处理了这个释放过程，所以没有特殊情况，尽量使用SimpleDraweeView，在特殊的场合，如果有需要，也可以直接控制Image Pipeline。 

### 3.支持的URI类型

* http|https
* file://
* content://
* asset://
* res://
* data:mime/type;base64 uri中指定图片数据

### 4.支持的xml属性

[支持的xml属性](https://www.fresco-cn.org/docs/using-drawees-xml.html)

### 5.在java中使用Drawees

#### 5.1 自定义DraweeHierarchy

```
        GenericDraweeHierarchyBuilder builder = new GenericDraweeHierarchyBuilder(getResources());
        GenericDraweeHierarchy hierarchy = builder
                .setFadeDuration(300)
                //and so on
                .build();
        image.setHierarchy(hierarchy);
```

从这里，从源码中都可以看出，源码中GenericDraweeView，初始化的时候会调用如下方法。

```
  protected void inflateHierarchy(Context context, @Nullable AttributeSet attrs) {
    GenericDraweeHierarchyBuilder builder =
        GenericDraweeHierarchyInflater.inflateBuilder(context, attrs);
    setAspectRatio(builder.getDesiredAspectRatio());
    setHierarchy(builder.build());
  }
```

xml中对应的属性，由hierarchy控制。

#### 5.2 运行时修改 DraweeHierarchy

要想修改，首先我们就需要获取DraweeHierarchy，然后对属性进行一些修改。

```
        GenericDraweeHierarchy hierarchy = image.getHierarchy();
        hierarchy.setFadeDuration(400);
```

其他属性同理。

#### 5.3 配置效果

我们可以通过xml或者java代码配置各种效果，这里就不介绍了。其中点击重新加载的功能比较新颖。

在ControllerBuilder 中如下设置:

```
.setTapToRetryEnabled(true)
```

* XML 中属性值: retryImage
* Hierarchy builder中的方法: setRetryImage

#### 5.4 进度条

构建GenericDraweeHierarchy的时候


```
.setProgressBarImage(new ProgressBarDrawable())
```
，我们也可以自定义，实现Drawable.onLevelChange。


### 6 DraweeController增加对图片的控制

```
ControllerListener listener = new BaseControllerListener() {...}

DraweeController controller = Fresco.newDraweeControllerBuilder()
    .setUri(uri)
    .setTapToRetryEnabled(true)
    .setOldController(mSimpleDraweeView.getController())
    .setControllerListener(listener)
    .build();

mSimpleDraweeView.setController(controller);
```

* 使用渐进式jpeg图。

    ```
    ImageRequest imageRequest = ImageRequestBuilder.newBuilderWithSource(Uri.parse("xxx"))
                //打开渐进 渲染
                .setProgressiveRenderingEnabled(true)
                .build();
	```
	
* 动画自动播放
	
	```
	draweeController.setAutoPlayAnimations(true)
	```
* 动画手动播放，

	```
	        ControllerListener listener = new BaseControllerListener<ImageInfo>(){
            @Override
            public void onFinalImageSet(String id, ImageInfo imageInfo, Animatable animatable) {
                super.onFinalImageSet(id, imageInfo, animatable);
                if (animatable != null){
                    animatable.start();
                }
            }
        };
        
        draweeController.setControllerListener(listener)
	```
* 后处理器Postprocessor 对图片进行后期处理

```
Postprocessor redMeshPostprocessor = new BasePostprocessor() {
  @Override
  public String getName() {
    return "redMeshPostprocessor";
  }

  @Override
  public void process(Bitmap bitmap) {
    for (int x = 0; x < bitmap.getWidth(); x+=2) {
      for (int y = 0; y < bitmap.getHeight(); y+=2) {
        bitmap.setPixel(x, y, Color.RED);
      }
    }
  }
}

ImageRequest request = ImageRequestBuilder.newBuilderWithSource(uri)
    .setPostprocessor(redMeshPostprocessor)
    .build();
```

### 7.Image Requests

使用ImageRequestBuilder来做更多的事情。

```
Uri uri;

ImageDecodeOptions decodeOptions = ImageDecodeOptions.newBuilder()
    .setBackgroundColor(Color.GREEN)
    .build();

ImageRequest request = ImageRequestBuilder
    .newBuilderWithSource(uri)
    .setImageDecodeOptions(decodeOptions)
    .setAutoRotateEnabled(true)
    .setLocalThumbnailPreviewsEnabled(true)
    .setLowestPermittedRequestLevel(RequestLevel.FULL_FETCH)    
    .setProgressiveRenderingEnabled(false)
    .setResizeOptions(new ResizeOptions(width, height))
    .build();
```

### 8.Image Pipeline
Image pipeline 负责完成加载图像，变成Android设备可呈现的形式所要做的每个事情。

```
ImagePipelineConfig config = ImagePipelineConfig.newBuilder(context)
    .setBitmapMemoryCacheParamsSupplier(bitmapCacheParamsSupplier)
    .setCacheKeyFactory(cacheKeyFactory)
    .setDownsampleEnabled(true)
    .setWebpSupportEnabled(true)
    .setEncodedMemoryCacheParamsSupplier(encodedCacheParamsSupplier)
    .setExecutorSupplier(executorSupplier)
    .setImageCacheStatsTracker(imageCacheStatsTracker)
    .setMainDiskCacheConfig(mainDiskCacheConfig)
    .setMemoryTrimmableRegistry(memoryTrimmableRegistry)
    .setNetworkFetchProducer(networkFetchProducer)
    .setPoolFactory(poolFactory)
    .setProgressiveJpegConfig(progressiveJpegConfig)
    .setRequestListeners(requestListeners)
    .setSmallImageDiskCacheConfig(smallImageDiskCacheConfig)
    .build();
Fresco.initialize(context, config);
```

上面的可配置项会因为版本的不同有稍微的区别。

#### 8.1 缓存

在fresco里面，

* bitmap缓存，直接存的就是bitmap对象，5.0 一下，这些位于ashmem，5.0以上，直接位于java的heap上
* 未解码图片的内存缓存
* 磁盘缓存

我们可以通过imagepipeline判断bitmap是否被缓存，

```
        ImagePipeline imagePipeline = Fresco.getImagePipeline();
        imagePipeline.isInBitmapMemoryCache(Uri.parse(""));
        imagePipeline.isInDiskCache(Uri.parse("xxx"));
```

删除指定缓存

```
        Uri uri = Uri.parse("xxx");
        imagePipeline.evictFromCache(uri);
        imagePipeline.evictFromDiskCache(uri);
```


使用imagepipeline可以对整个工程加入一些控制。更多用法[文档](https://www.fresco-cn.org/docs/using-image-pipeline.html)

---### 最近访客<ul class="ds-recent-visitors" data-num-items="46" data-avatar-size="40"></ul>



