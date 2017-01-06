---
title: fresco生产者Producer
date: 2016-12-13 11:26:58
categories: Android
tags: fresco

---
<Excerpt in index | 首页摘要>
### 1. 从ImagePipeline#submitFetchRequest说起

上篇说到，这里干了三件事，第三件事，就是我们异步获取数据的过程，这里的异步获取数据包括三个方面：

* 从未解码的memory cache中获取
* 从disk cache中获取
* 从net中获取

```
      return CloseableProducerToDataSourceAdapter.create(
          producerSequence,
          settableProducerContext,
          requestListener);
```

+ <!-- more -->
<The rest of contents | 余下全文>


在AbstractProducerToDataSourceAdapter中，创建了CloseableProducerToDataSourceAdapter，而这个继承了AbstractProducerToDataSourceAdapter，这个类的构造方法中，通过producer.produceResults(createConsumer(), settableProducerContext);来异步获取数据，并会将结果回调。


### 2. Producer 生产者

先看下相关的结构。

![](/images/fresco/fresco_2.png)

可以看到有许多不同类型的Producer，这些都是用来从不同的区域获取数据。


### 3. 从已解码的内存中获取－BitmapMemoryCacheProducer


这里的比较简单，他的produceResults方法中，通过mMemoryCache.get(cacheKey)来获取已解码的数据。

### 4. 从未解码的内存中获取－EncodedMemoryCacheProducer


在这里要说明下

* EncodedImage 未解码的载体
* PooledByteBuffer 存储的字节码
* CloseableBitmap 已解码的载体


先mMemoryCache.get(cacheKey) 获取未解码的数据，然后构造出未解码的载体EncodedImage，传给其他的生产者进行解码。

### 5. 从本地文件获取－DiskCacheProducer

文件缓存对应的是BufferedDiskCache，大致步骤和上面的区别不大。这里就不再说了。

### 6. 从网络中获取－NetworkFetchProducer

略，思路一致。


_ _ _

* [参考资料](https://github.com/desmond1121/Fresco-Source-Analysis/blob/master/Fresco%E6%BA%90%E7%A0%81%E5%88%86%E6%9E%90(5)%20-%20Producer%E6%B5%81%E6%B0%B4%E7%BA%BF.md)
