---
title: AndroidJNI学习笔记（四）－数据类型映射以及native调用java
date: 2016-11-30 00:05:36
tags: jni

---
<Excerpt in index | 首页摘要>
### 1. 前言

前几篇学习了jni开发的基本流程、动态注册native函数以及相关编译文件的编写，咱们也算是知道了jni开发，但是还不够，今天咱们来学习下，java和jni的数据类型映射（说白了就是对应关系），以及如何在jni层调用java层的一些东西。偷偷告诉你们，这些全在jni.h文件里。

+ <!-- more -->
<The rest of contents | 余下全文>


### 2. 数据类型映射 

首先是我们的基本数据类型，其关系如下表描述这样。

![这里写图片描述](http://img.blog.csdn.net/20161129225511135)

上面关系的相关代码在jni.h的44－51行，如下

```
typedef unsigned char   jboolean;       /* unsigned 8 bits */
typedef signed char     jbyte;          /* signed 8 bits */
typedef unsigned short  jchar;          /* unsigned 16 bits */
typedef short           jshort;         /* signed 16 bits */
typedef int             jint;           /* signed 32 bits */
typedef long long       jlong;          /* signed 64 bits */
typedef float           jfloat;         /* 32-bit IEEE 754 */
typedef double          jdouble;        /* 64-bit IEEE 754 */
```


而jni层的引用类型则是下面这个样子。

![这里写图片描述](http://img.blog.csdn.net/20161129225901230)

对于这些引用类型，c++和c的实现是不一样的。如果是c++的话，所有引用类型派生自 jobject，如果使用 C 语言编写的话，所有引用类型使用 jobject，其它引用类型使用 typedef 重新定义。同样代码也在jni.h中。这里只给出c++继承结构的部分。

```
class _jobject {};
class _jclass : public _jobject {};
class _jstring : public _jobject {};
class _jarray : public _jobject {};
class _jobjectArray : public _jarray {};
class _jbooleanArray : public _jarray {};
class _jbyteArray : public _jarray {};
class _jcharArray : public _jarray {};
class _jshortArray : public _jarray {};
class _jintArray : public _jarray {};
class _jlongArray : public _jarray {};
class _jfloatArray : public _jarray {};
class _jdoubleArray : public _jarray {};
class _jthrowable : public _jobject {};
```

### 3. native 如何调用c

我们这里的调用包括许多方面，如：

* 调用静态方法
* 调用实例方法
* 获取字段值
* 修改字段值
* 构造对象
* 等等

而要实现上面的一些功能，同样要依靠jni.h的JNINativeInterface这个结构体，这里有很多很多的方法，供我们使用来实现native 调用java层的功能。而调用的流程是这样的：

*  根据全限定名在jvm中找到想要的类
* 从jclass中获取到method、或者field
* 执行获取值、修改值、调用方法或者其他的操作
* 释放局部引用

举个调用静态方法的例子看看。

```
void callJavaStatic(JNIEnv *env,jobject jobj){
  char* str = "call from c++";

  jclass clazz = env->FindClass("com/example/cmake_demo/MainActivity");
  if (clazz == NULL) {
    LOGE("class is null");
    return;
  }

  jmethodID method = env->GetStaticMethodID(clazz,"javaStaticMethod","(Ljava/lang/String;)V");
  if (method == NULL) {
    LOGE("not find method");
  }

  jstring  jstr = env->NewStringUTF(str);
  env->CallStaticVoidMethod(clazz,method,jstr);
  env->DeleteLocalRef(clazz);
  env->DeleteLocalRef(jstr);
}
```


#### 3.1 如何找到类

很简单，我们可以通过FindClass方法去查找类。

```
jclass clazz = env->FindClass("com/example/cmake_demo/MainActivity");
```

#### 3.2  如何获取方法、或者字段
大致为以下四种方法

```
 env->GetxxxField()
 env->GetStaticxxxField()
 env->GetMethodID()
 env->GetxxxMethodID()
```

上面没有列出参数，但是仍然很明白，这里就不多说了。


#### 3.3 如何调用方法

这里呢。大致分为以下四种：

```
  env->CallXXXMethod();
  env->CallxxxMethodA();
  env->CallxxxMethodV();
  env->CallNonvirtualBooleanMethod()
```

同样，我这里没给出方法的参数，同学们自己看jni.h吧

* 调用方法（这里的方法可能使静态的、也可能是非静态的）
* 和上面的区别就在于对应的java层参数，在这里以数组的形式传进入
* 和1的区别就是，以v(矢量？)的形式传进去，这里我也不是很理解，希望知道的同学指点下。
* 调用构造函数初始化一个对象，这个，马上说道。

#### 3.4 如何修改字段的值

相信到这里，大家猜都能猜出来，set 么，这里我就不叨叨了。


#### 3.5 如何构造一个对象出来

有些情况下我们是需要构造出java层的对象的，那么如何构造呢，我们有两种办法。

*  NewObject方法 
*  CallNonvirtualxxMethod

先说第一种，NewObject方法，除了要求jclass参数之外，还要求jmethodid，以及java称构造方法对应的参数。其他两个还好，关键是这个jmethodID，这个在获取的时候，方法名固定是< init >（md语法的原因，注意尖括号之间没有空格），别问为什么。

在来说说第二种，第二中使用时这样的

```
  jobject  jo = env->AllocObject(clazz);
  env->CallNonvirtualVoidMethod(jo,clazz,jmethodId,arg )
```

* 第一行代码 创建未初始化的对象，并分配内存
* 第二行代码，调用init那个方法（构造方法）进行初始化,注意，只能初始化一次。


### 4. 总结

现在我们明白了jni 和 java的数据类型映射关系，以及在jni层调用java层的方法。






