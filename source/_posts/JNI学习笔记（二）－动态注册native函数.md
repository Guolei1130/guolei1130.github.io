layout: android
title: JNI学习笔记（二）－动态注册native函数
date: 2016-11-29 16:33:30
tags: jni

---
<Excerpt in index | 首页摘要> 

### 1.前言

在很久之前的一篇[Android 开发艺术探索的笔记](http://blog.csdn.net/qq_21430549/article/details/49535483)当中,学习了简单的jni开发流程，但是那会的步骤极其繁琐复杂，而且生成的头文件函数太长，那么，有没有方法能解决呢，让开发过程变得简单易懂。当然是有的，那就是今天的主角。JNI_OnLoad函数。顺便说一下，现在as对 jni开发的支持是越来越好了。
+ <!-- more -->
<The rest of contents | 余下全文>

### 2. 首先声明native函数

现在，我在activity里声明了一个native函数。

```
public native String getStringFromC();
```

然后我们build一下，为啥要build呢，这个马上就说的。

### 3. 创建并编写 .h头文件

创建jni目录，并且右键->new c++class，会生出相应的.h 和.cpp 文件，我们需要稍微修改下.h 文件。

```
#ifndef NDK_CORE_H
#define NDK_CORE_H

#define NELEM(x) ((int) (sizeof(x) / sizeof((x)[0])))

#include <jni.h>
#include <stdlib.h>

__BEGIN_DECLS

JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM* vm, void* reserved);
JNIEXPORT void JNICALL JNI_OnUnload(JavaVM* vm, void* reserved);


__END_DECLS

#endif //TEXT_HELLO_H

```

代码说明如下：

*  我们定义了一个宏NELEM，后面会用到
*  我们用JNIEXPORT和JNICALL关键字，告诉虚拟机，这是jni函数，

### 4. 编写cpp文件

代码如下：

```
jstring returnString(JNIEnv *env,jobject jobj){
  char* str = "I come from C＋＋";
  return env->NewStringUTF(str);
}

static JNINativeMethod gMethods[] = {
    {"getStringFromC","()Ljava/lang/String;",(void *)returnString }
};

JNIEXPORT int JNICALL JNI_OnLoad(JavaVM *vm,void *reserved) {
  JNIEnv *env;
  if (vm->GetEnv((void **) &env,JNI_VERSION_1_6) != JNI_OK){
    return JNI_ERR;
  }

  jclass javaClass = env->FindClass("com/example/hello_jni/MainActivity");
  if (javaClass == NULL){
    return JNI_ERR;
  }
  if (env->RegisterNatives(javaClass,gMethods,NELEM(gMethods)) < 0) {
    return JNI_ERR;
  }

  return JNI_VERSION_1_6;
}
```
先看JNI_OnLoad方法，这是注册native函数的地方。

*  首先判断jni版本是不是JNI_VERSION_1_6
*  FindClass方法找到我们对应生命native函数的类，返回一个jclass
*  RegisterNatives 注册native函数，我这里用这个三个参数的方法，第一个表示对应jclass，第二个表示JNINativeMethod的数组，第三个，这个就是我们先前命名的宏，

就这样，我们就注册了native函数了。接下来我们看下gMethods。

### 5. JNINativeMethod数组

这个数组里存放着这样的元素。

```
{"getStringFromC","()Ljava/lang/String;",(void *)returnString }
```

* 第一个参数对应的native方法名
* 第二个参数对应 native方法的描述，我们通过javap -s class文件路径来获取。
![这里写图片描述](http://img.blog.csdn.net/20161126110049266)
* 第三个参数对应的是我嗯c++代码里对应的实现

最后就是android.mk 和 application.mk的编写以及gradle的配置，最后编译，这里就不多说了，相关的内容下篇说明。现在给出文件内容。

android.mk

```
LOCAL_PATH := $(call my-dir)
include $(CLEAR_VARS)
LOCAL_MODULE := hello-jni

LOCAL_C_INCLUDES += $(LOCAL_PATH)
LOCAL_SRC_FILES := hello.cpp

include $(BUILD_SHARED_LIBRARY)
```

application.mk

```
APP_ABI := armeabi x86
APP_PLATFORM := android-14
APP_STL := stlport_static
APP_OPTIM := debug
```

gradle 配置

![这里写图片描述](http://img.blog.csdn.net/20161126110601745)

最后就会生出so文件了。(会自动打包进apk里)
![这里写图片描述](http://img.blog.csdn.net/20161126110719106)


