---
title: Android消息机制－native层
date: 2016-12-24 16:25:04
categories: Android
tags: framework

---
<Excerpt in index | 首页摘要>
### 1. 前言

前面的文章介绍了java层的消息机制，这篇来简要学习下native层的消息机制。

+ <!-- more -->
<The rest of contents | 余下全文>




### 2.初始化

在MessageQueue的构造函数中，调用nativeInit方法来初始化native层的messagequeue。而java层 MessageQueue中的几个native函数，如nativePollOnce，nativeWake等，其实现都在android_os_MessageQueue.cpp中。

首先，我们先看下方法表：

```
static JNINativeMethod gMessageQueueMethods[] = {
    /* name, signature, funcPtr */
    { "nativeInit", "()J", (void*)android_os_MessageQueue_nativeInit },
    { "nativeDestroy", "(J)V", (void*)android_os_MessageQueue_nativeDestroy },
    { "nativePollOnce", "(JI)V", (void*)android_os_MessageQueue_nativePollOnce },
    { "nativeWake", "(J)V", (void*)android_os_MessageQueue_nativeWake },
    { "nativeIsPolling", "(J)Z", (void*)android_os_MessageQueue_nativeIsPolling },
    { "nativeSetFileDescriptorEvents", "(JII)V",
            (void*)android_os_MessageQueue_nativeSetFileDescriptorEvents },
};
```


因为前面有介绍jni的相关知识，这里就不多说了。

从中找到，我们java层的nativeInit方法，对应的是android_os_MessageQueue_nativeInit.

```
static jlong android_os_MessageQueue_nativeInit(JNIEnv* env, jclass clazz) {
    NativeMessageQueue* nativeMessageQueue = new NativeMessageQueue();
    if (!nativeMessageQueue) {
        jniThrowRuntimeException(env, "Unable to allocate native queue");
        return 0;
    }

    nativeMessageQueue->incStrong(env);
    return reinterpret_cast<jlong>(nativeMessageQueue);
}
```


* 初始化NativeMessageQueue
* 并且返回给java层，也就是java层的mPtr

那么，我们就来看NativeMessageQueue的构造函数，其实还在这个cpp中。

```
NativeMessageQueue::NativeMessageQueue() :
        mPollEnv(NULL), mPollObj(NULL), mExceptionObj(NULL) {
    mLooper = Looper::getForThread();
    if (mLooper == NULL) {
        mLooper = new Looper(false);
        Looper::setForThread(mLooper);
    }
}
```

* 构造native层的looper，注意，这个和java层的没有任何关系
* 保存在类似ThreadLocal一样的结构里。

Looper的构造函数在Looper.cpp中。

```
Looper::Looper(bool allowNonCallbacks) :
        mAllowNonCallbacks(allowNonCallbacks), mSendingMessage(false),
        mPolling(false), mEpollFd(-1), mEpollRebuildRequired(false),
        mNextRequestSeq(0), mResponseIndex(0), mNextMessageUptime(LLONG_MAX) {
    mWakeEventFd = eventfd(0, EFD_NONBLOCK);
    LOG_ALWAYS_FATAL_IF(mWakeEventFd < 0, "Could not make wake event fd.  errno=%d", errno);

    AutoMutex _l(mLock);
    rebuildEpollLocked();
}
```

* eventfd构造欢迎时间的fd
* rebuildEpollLocked 重建epoll

epoll模型和select／poll模型一样，都是linux下的多路复用I/O模型,epoll模型的优点如下：

* 监视的描述符数量不受限制
* IO效率不会随着监视fd的数量增长而下降

关于epoll的更多内容，这里就不介绍了。

那么，在我们native的looper里面，是如何重建的呢？

```
void Looper::rebuildEpollLocked() {
    // Close old epoll instance if we have one.
    if (mEpollFd >= 0) {
#if DEBUG_CALLBACKS
        ALOGD("%p ~ rebuildEpollLocked - rebuilding epoll set", this);
#endif
        close(mEpollFd);
    }

    // Allocate the new epoll instance and register the wake pipe.
    mEpollFd = epoll_create(EPOLL_SIZE_HINT);
    LOG_ALWAYS_FATAL_IF(mEpollFd < 0, "Could not create epoll instance.  errno=%d", errno);

    struct epoll_event eventItem;
    memset(& eventItem, 0, sizeof(epoll_event)); // zero out unused members of data field union
    eventItem.events = EPOLLIN;
    eventItem.data.fd = mWakeEventFd;
    int result = epoll_ctl(mEpollFd, EPOLL_CTL_ADD, mWakeEventFd, & eventItem);
    LOG_ALWAYS_FATAL_IF(result != 0, "Could not add wake event fd to epoll instance.  errno=%d",
            errno);

    for (size_t i = 0; i < mRequests.size(); i++) {
        const Request& request = mRequests.valueAt(i);
        struct epoll_event eventItem;
        request.initEventItem(&eventItem);

        int epollResult = epoll_ctl(mEpollFd, EPOLL_CTL_ADD, request.fd, & eventItem);
        if (epollResult < 0) {
            ALOGE("Error adding epoll events for fd %d while rebuilding epoll set, errno=%d",
                    request.fd, errno);
        }
    }
}
```

* epoll_create，创建epoll句柄
* memset 将数据区域至0
* eventItem.events = EPOLLIN;
    eventItem.data.fd = mWakeEventFd;，指定事件类型和唤醒的fd。
* epoll_ctl添加唤醒事件
* 循环将mRequests中的事件都添加进去。

### 3. nativePollOnce

在java层MessageQueue#next方法中，首先会通过nativePollOnce去提取native层消息队列的消息。

android_os_MessageQueue_nativePollOnce->pollOnce->Looper的pollOnce(这个pollOnce是个内连函数，会调用到4个参数的pollOnce方法)



```
int Looper::pollOnce(int timeoutMillis, int* outFd, int* outEvents, void** outData) {
    int result = 0;
    for (;;) {
        while (mResponseIndex < mResponses.size()) {
            const Response& response = mResponses.itemAt(mResponseIndex++);
            int ident = response.request.ident;
            if (ident >= 0) {
                int fd = response.request.fd;
                int events = response.events;
                void* data = response.request.data;
#if DEBUG_POLL_AND_WAKE
                ALOGD("%p ~ pollOnce - returning signalled identifier %d: "
                        "fd=%d, events=0x%x, data=%p",
                        this, ident, fd, events, data);
#endif
                if (outFd != NULL) *outFd = fd;
                if (outEvents != NULL) *outEvents = events;
                if (outData != NULL) *outData = data;
                return ident;
            }
        }

        if (result != 0) {
#if DEBUG_POLL_AND_WAKE
            ALOGD("%p ~ pollOnce - returning result %d", this, result);
#endif
            if (outFd != NULL) *outFd = 0;
            if (outEvents != NULL) *outEvents = 0;
            if (outData != NULL) *outData = NULL;
            return result;
        }

        result = pollInner(timeoutMillis);
    }
}
```

这个方法的参数含义：

* timeoutMillis 超时等待时间，-1无限等待，0立即返回
* outFd 发生事件的文件描述符
* outEvents 发生了哪些事件，目前支持可读、可写、错误、中断,
* outData 存储上下文数据

返回值的含义如下：

* ALOOPER_POLL_WAKE 表示由wake触发
* ALOOPER_POLL_TIMEOUT 等待超时
* ALOOPER_POLL_ERROR 等待过程中发生错误
* ALOOPER_POLL_CALLBACK 被监听的句柄因某种原因被触发

这个方法的处理逻辑如下：

* 先处理没有Callback方法的 Response事件,(Response/Request的结构体在Looper.h中)
* pollInner 处理内部轮询


pollInner方法很长，

* toMillisecondTimeoutDelay 重新计算超时时间
* epoll_wait 等待
* 如果需要，重建epoll
* epoll_wait函数返回，三种情况
	* eventCount<0 发生错误，goto Done
	* eventCount=0 连接超时 goto Done
	* 监听到有事件发生，
* 如果有事件发生，则循环处理
	* 如果是mWakeEventFd，则进行awoken唤醒
	* pushResponse，根据request构建response，并添加到response数组中
* Done 标志，事件处理
	* handleMessage 先处理native的message
	* handleEvent 处理有回调的message，并且response.request.callback.clear();清除引用。 	
	

### 4.nativeWake

同学上周去美团面试的时候，被问到，当消息队列阻塞的时候，我们插入message，会发生什么呢？根据enqueueMessage方法，可以知道，当消息队列没有消息，也就是p=null的时候，会调用nativeWake进行唤醒操作。

在native层通过层层调用，会调用到looper的wake方法中。

```
void Looper::wake() {
#if DEBUG_POLL_AND_WAKE
    ALOGD("%p ~ wake", this);
#endif

    uint64_t inc = 1;
    ssize_t nWrite = TEMP_FAILURE_RETRY(write(mWakeEventFd, &inc, sizeof(uint64_t)));
    if (nWrite != sizeof(uint64_t)) {
        if (errno != EAGAIN) {
            ALOGW("Could not write wake signal, errno=%d", errno);
        }
    }
}
``` 

* 向管道mWakeEventFd写入字符,因为有输入，所以读的一端就会被唤醒,r然后nativepollonce函数就会返回。这些继续处理消息了。

### 补充

当消息队列里没有消息的时候，会调用nativePollOnce方法 进入阻塞状态，当消息来的时候，会用nativeWake进行唤醒操作。并且，在主线程空闲状态时，会处理注册的mPendingIdleHandlers的任务。






