---
title: fresco图片decode的大体流程
date: 2016-12-13 16:10:51
categories: Android
tags: fresco

---
<Excerpt in index | 首页摘要>
### 1. 从DecodeProducer说fresco的解码过程

DecodeProducer负责用未解码的数据生产出解码的数据。先看produceResults方法。

+ <!-- more -->
<The rest of contents | 余下全文>


```
  @Override
  public void produceResults(
      final Consumer<CloseableReference<CloseableImage>> consumer,
      final ProducerContext producerContext) {
    final ImageRequest imageRequest = producerContext.getImageRequest();
    ProgressiveDecoder progressiveDecoder;
    if (!UriUtil.isNetworkUri(imageRequest.getSourceUri())) {
      progressiveDecoder = new LocalImagesProgressiveDecoder(consumer, producerContext);
    } else {
      ProgressiveJpegParser jpegParser = new ProgressiveJpegParser(mByteArrayPool);
      progressiveDecoder = new NetworkImagesProgressiveDecoder(
          consumer,
          producerContext,
          jpegParser,
          mProgressiveJpegConfig);
    }
    mInputProducer.produceResults(progressiveDecoder, producerContext);
  }
```

* 通过判断uri的类型 选择不同的渐近式解释器
* local和network都继承自ProgressiveDecoder

在ProgressiveDecoder的构造方法中，doDecode(encodedImage, isLast) 进行解析。而真正解析的则是ImageDecoder#decodeImage方法，这个方法将encodedImage解析成CloseableImage。

### 2. ImageDecoder

这个类是用来将未解码的EncodeImage,解码成对应的CloseableImage。解析的入口方法decodeImage。

```
  public CloseableImage decodeImage(
      final EncodedImage encodedImage,
      final int length,
      final QualityInfo qualityInfo,
      final ImageDecodeOptions options) {
    ImageFormat imageFormat = encodedImage.getImageFormat();
    if (imageFormat == null || imageFormat == ImageFormat.UNKNOWN) {
      imageFormat = ImageFormatChecker.getImageFormat_WrapIOException(
          encodedImage.getInputStream());
      encodedImage.setImageFormat(imageFormat);
    }
    if (imageFormat == DefaultImageFormats.JPEG) {
      return decodeJpeg(encodedImage, length, qualityInfo);
    } else if (imageFormat == DefaultImageFormats.GIF) {
      return decodeGif(encodedImage, options);
    } else if (imageFormat == DefaultImageFormats.WEBP_ANIMATED) {
      return decodeAnimatedWebp(encodedImage, options);
    } else if (imageFormat == ImageFormat.UNKNOWN) {
      throw new IllegalArgumentException("unknown image format");
    }
    return decodeStaticImage(encodedImage);
  }
```

* 先判断未解码的图片类型
* 根据不同的图片类型选择不同的解码方式

#### 2.1 ImageFormatChecker

这个类是根据输入流来确定图片的类型。基本原理是根据头标识去确定类型。如png的头标识为89 50 4E 47 0D 0A 1A 0A。对应的就为

```
  private static final byte[] PNG_HEADER = new byte[] {
      (byte) 0x89,
      'P', 'N', 'G',
      (byte) 0x0D, (byte) 0x0A, (byte) 0x1A, (byte) 0x0A};
```

如果不熟ascll表的话，可以去查阅'P''N''G'在ascll表中对应的16进制。


#### 2.2 解析种类

根据代码能看出，这里分为几种。

* JPEG
* GIF
* WEBP_ANIMATED
* 其他

从是否静态图上来看，为两种，

* 可动 ，用AnimatedImageFactory进行解析
* 不可动，用PlatformDecoder进行解析


### 3. AnimatedImageFactory


AnimatedImageFactory是一个接口，他的实现类是AnimatedImageFactoryImpl。

在这个类的静态方法块种，通过如下代码 来构造其他依赖包中的对象，这个小技巧我们可以get一下。

```
  private static AnimatedImageDecoder loadIfPresent(final String className) {
    try {
      Class<?> clazz = Class.forName(className);
      return (AnimatedImageDecoder) clazz.newInstance();
    } catch (Throwable e) {
      return null;
    }
  }

  static {
    sGifAnimatedImageDecoder = loadIfPresent("com.facebook.animated.gif.GifImage");
    sWebpAnimatedImageDecoder = loadIfPresent("com.facebook.animated.webp.WebPImage");
  }
```

解析分为两个步骤。

* 通过AnimatedImageDecoder解析出AnimatedImage
* 利用getCloseableImage从AnimatedImage中构造出CloseableAnimatedImage。这是CloseableImage的之类。

关于AnimatedImageDecoder解析gif和webp，我们后面的文章介绍。

getCloseableImage的逻辑如下：

* 用decodeAllFrames解析出所有帧
* 用createPreviewBitmap构造预览的bitmap
* 构造AnimatedImageResult对象
* 用AnimatedImageResult构造CloseableAnimatedImage对象。

这里就不再多说了，等到后面学习webp和gif的时候再说。

### 4.PlatformDecoder

PlatformDecoder是一个接口，代表不同平台。我们看他的实现类有哪些。

![](/images/fresco/fresco_3.png)

从图中可以看出，从虚拟机层次分为dalvik和art虚拟机，从版本来看，为2.3-4.0，5.0以上。

* 在5.0 以后，也就是ArtDecoder的实现，缓存是直接存在java堆上的
* 5.0以下，则是存在Ashmem匿名共享内存中。


5.0 以上的实现这里就不说，这里先引出Ashmem。从decodeFromEncodedImage看起，

```
  @Override
  public CloseableReference<Bitmap> decodeFromEncodedImage(
      final EncodedImage encodedImage,
      Bitmap.Config bitmapConfig) {
    BitmapFactory.Options options = getBitmapFactoryOptions(
        encodedImage.getSampleSize(),
        bitmapConfig);
    CloseableReference<PooledByteBuffer> bytesRef = encodedImage.getByteBufferRef();
    Preconditions.checkNotNull(bytesRef);
    try {
      Bitmap bitmap = decodeByteArrayAsPurgeable(bytesRef, options);
      return pinBitmap(bitmap);
    } finally {
      CloseableReference.closeSafely(bytesRef);
    }
  }
```

* getBitmapFactoryOptions 获取BitmapFactory.Options
* decodeByteArrayAsPurgeable 获取bitmap
* pinBitmap 真正的decode

我们需要注意的BitmapFactory.Options参数是options.inPurgeable = true，这样decode出来的bitmap是在Ashmem内存中，gc是无法自动回收的。

而在pinBitmap中，是通过Bitmaps调用native将bitmap pin住，这样即使在系统内存不够的时候 也不会回收，当我们不需要使用的时候，调用nativeReleaseByteBuffer这个native函数，将bitmap unpin，就可以被回收了。






---### 最近访客<ul class="ds-recent-visitors" data-num-items="46" data-avatar-size="40"></ul>




