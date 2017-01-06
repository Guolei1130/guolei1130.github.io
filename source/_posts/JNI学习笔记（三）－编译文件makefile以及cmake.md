---
title: JNI学习笔记（三）－编译文件makefile以及cmake
date: 2016-11-29 18:38:27
tags: jni

---
<Excerpt in index | 首页摘要>

### 1. 前言

在android2.2中，加入了cmake编译，而以前都是用Android.mk、Application.mk的，今天就来记录下，他们的配置选项。
+ <!-- more -->
<The rest of contents | 余下全文>

### 2. Android.mk

Android.mk在jni目录下，用于描述构建系统的源文件以及
shared libraries 。文件格式如下：

* 以LOCAL_PATH变量开始 



	```
LOCAL_PATH := $(call my-dir)
```
* 紧接着是CLEAR_VARS变量 

	```
	include $(CLEAR_VARS) 
	```
* 接下来LOCAL_MODULE变量，定义来将要输出的so文件的名，默认情况下，输出的so为 lib+LOCAL_MODULE变量值+.so，如果变量值前面有了lib，就不会加了，或者变量值后面有.xxx，也会去掉。
* 接下来是LOCAL_SRC_FILES变量，声明我们的原文件路径，如

	```
	LOCAL_SRC_FILES := hello-jni.c 
	```
* 最后一行是帮助构建系统联系在一起的。

	```
include $(BUILD_SHARED_LIBRARY) 
```

```
LOCAL_PATH := $(call my-dir)
include $(CLEAR_VARS)

LOCAL_MODULE := hello-jni

LOCAL_SRC_FILES := hello.cpp

include $(BUILD_SHARED_LIBRARY)
```

当然，上面只是一个最简单的，下面我们来介绍其他的一些变量和宏。

构建系统提供了许多变量和宏，当然 也允许我们自定义，内置的有以下三种：

* 以LOCAL_开始，如LOCAL_MODULE
* 以PRIVATE_, NDK_, or APP 
* 小写字母，如 my-di

如果要自定义的话，建议MY_开头。

#### 2.1 NDK 默认的变量

* CLEAR_VARS  用来在描述新model之前引入这个脚本，会清除之前的值 

	```
include $(CLEAR_VARS) 
```
* BUILD_SHARED_LIBRARY,告诉构建系统去收集声明的LOCAL_变量的值，然后输出成so 

	```
include $(BUILD_SHARED_LIBRARY)
```
* BUILD_STATIC_LIBRARY,和BUILD_SHARED_LIBRARY类似，不过不会复制到project/packages，但是可以提供给shared libraries用，会输出成.a 

	```
include $(BUILD_STATIC_LIBRARY) 
```
* PREBUILT_SHARED_LIBRARY 用于指定预先编译好的共享库，但是LOCAL_SRC_FILES是so文件 

	```
	include $(PREBUILT_SHARED_LIBRARY) 
	```
* PREBUILT_STATIC_LIBRARY 和PREBUILT_SHARED_LIBRARY 类似
* TARGET_ARCH 略，重点看TARGET_ARCH_ABI
* TARGET_PLATFORM 指定当前编译的android api版本 

	```
TARGET_PLATFORM := android-22
```
* TARGET_ARCH_ABI 指定cpu架构，

	```
TARGET_ARCH_ABI := arm64-v8a
```
* TARGET_ABI，指定android api版本鱼abi架构
* 
	```
	TARGET_ABI := android-22-arm64-v8a
	```

#### 2.2 Module-Description Variables 描述model的变量

*  LOCAL_PATH 指定当前文件的路径，必须在文件开始的时候指定 


	
	```
	LOCAL_PATH := $(call my-dir)
	
	```
	注意CLEAR_VARS，并不会清除这个的值
* LOCAL_MODULE 
* LOCAL_MODULE_FILENAME 可以指定生成的so文件的名字
* LOCAL_SRC_FILES 指定这个model对应的原文件
* LOCAL_CPP_EXTENSION 配置c++ 文件后缀(扩展名)，是c++、cc还是其他
* LOCAL_CPP_FEATURES 指定特定的c++特性 如支持RTTI (RunTime Type Information),

	```
	LOCAL_CPP_FEATURES := rtti
	```
* LOCAL_C_INCLUDES 指定路径列表，相对于ndk的跟路径
* LOCAL_CFLAGS、LOCAL_CPPFLAGS 可以指定额外的宏定义和编译选项
* LOCAL_STATIC_LIBRARIES、LOCAL_SHARED_LIBRARIES 指定其他的static libraries、shared libraries
* LOCAL_WHOLE_STATIC_LIBRARIES  整个。
* LOCAL_LDLIBS 指定系统-l指定系统库，如/system/lib/libz.so 

	```
	LOCAL_LDLIBS := -lz 
	```
* LOCAL_LDFLAGS 略，没看明白
* LOCAL_ALLOW_UNDEFINED_SYMBOLS 默认情况下,当构建系统遇到遇到未定义的引用在试图建立一个共享的,它会抛出未定义符号错误。这个错误可以帮助debug。
* 剩下的许多 并不常用，暂时到这里，以后有机会用的话，查文档吧。

### 3. Application.mk

用于描述app需要的native model。

#### 3.1 变量

* APP_PROJECT_PATH 这个变量存储应用程序的项目根目录的绝对路径。
* APP_OPTIM 配置release和debug
* APP_CFLAGS 这个变量存储一组构建系统的C编译器标志传递给编译器编译任何C或c++源代码的任何模块，可以修改应用需要的构建模块而不用修改Android.mk文件
* APP_CPPFLAGS 和 APP_CFLAGS类似
* APP_LDFLAGS A set of linker flags that the build system passes when linking the application，只对 shared libraries 和 executables有效
* APP_BUILD_SCRIPT 指定Android.mk文件
* APP_ABI 指定abi
* APP_PLATFORM 指定android api版本
* APP_STL 链接其他的c＋＋支持
* NDK_TOOLCHAIN_VERSION  gcc编译版本
* APP_PIE 
* APP_THIN_ARCHIVE


### 4.在Android Studio中使用 

要求 Android Studio 2.2 以上。

在gradle中，

```
android {
  defaultConfig {  
    externalNativeBuild {
      cmake {
        // 设置cmake参数 "-DVAR_NAME=VALUE"
        arguments "-DANDROID_ARM_NEON=TRUE", "-DANDROID_TOOLCHAIN=clang"
      }
    }
    // 设置 abi
    ndk {
            abiFilters "armeabi","x86","armeabi-v7a"
        }
  }
  buildTypes {...}
  
  externalNativeBuild {
    cmake {
    	// CMakeLists.txt 文件路径
    	path 'src/main/jni/CMakeLists.txt' 
    }
  }
}
```

我们需要编写的就是上面三处有注释的地方。

* cmake参数 格式为 -D + Variable name ＝ Arguments 的形势
	* ANDROID_TOOLCHAIN cmake编译链，gcc 和clang（默认）两种
	* ANDROID_PLATFORM target Android platform
	* ANDROID_STL  cmake编译时用哪个stl，有以下种类[Helper Runtimes](https://developer.android.com/ndk/guides/cpp-support.html#hr)
	* ANDROID_PIE 指定是否使用位置独立的可执行(饼)。Android的动态链接器支持派在Android 4.1(API级16)和更高。
	* ANDROID_CPP_FEATURES 指定特定的c++特性CMake编译时需要使用本地库,比如c++ RTTI(运行时类型信息)和异常,rtti,exceptions
	* ANDROID_ALLOW_UNDEFINED_SYMBOLS 指定是否抛出未定义符号错误如果CMake遇到一个未定义的引用而建立你的本地库。禁用这些类型的错误,将这个变量设置为TRUE。
	* ANDROID_ARM_MODE 设置生成的二进制文件arm 还是 thumb模式，thumb模式下，每个指令都是16bits，arm模式下为32位，默认是 thumb
	* NDROID_ARM_NEON build native lib 是否NONE支持
	* ANDROID_DISABLE_NO_EXECUTE 是否允许ne bit，或者执行、或者安全特训过
	* ANDROID_DISABLE_RELRO 是否只读
	* ANDROID_DISABLE_FORMAT_STRING_CHECKS 指定与格式字符串是否编译源代码的保护。当启用时,编译器将抛出一个错误如果不恒定格式字符串中使用printf-style函数。
* ndk abifilters
* cmake path

关于cmake 参数，[官方文档](https://developer.android.com/ndk/guides/cmake.html)

### 5. CMakeLists.txt 编写


* cmake 最小版本 ```
	cmake_minimum_required(VERSION 3.4.1)	
	``` 
		
* 
	```
add_library(native lib name,SHARED(SHARED还是STATIC),c++或c文件路径)
```
* 指定头文件路径 

	```
include_directories(src/main/cpp/include/)
``` 

#### 5.1 添加native api

```
find_library( # Defines the name of the path variable that stores the
              # location of the NDK library.
              log-lib

              # Specifies the name of the NDK library that
              # CMake needs to locate.
              log )
```

按照我个人的理解，

* 第一个就是lib库的别名，就是我们在这个文件中其他地方要使用的。
* 第二个参数是对应的native lib库的名字，第二个参数在ndk-bundle/platforms/android版本／下面能找到。根据我们上面说到的生成so文件规则，能够很清楚的提出lib name

然后使用target_link_libraries(native-lib,${log-lib}) 去链接咱们的本地库和ndk中带的本地库，

_ _ _

也可以将源代码添加进来，

```
add_library( app-glue
             STATIC
             ${ANDROID_NDK}/sources/android/native_app_glue/android_native_app_glue.c )
```
* lib name
* 类型
* 文件路径


#### 5.2 添加其他预先构建的libraries

因为这些已经有的，需要用 IMPORTED 去告诉cmkae，只需要将这个lib导入到咱们的project

```
add_library( imported-lib
             SHARED
             IMPORTED )
```

然后需要用set_target_properties去指定路径。

```
set_target_properties( # Specifies the target library.
                       imported-lib

                       # Specifies the parameter you want to define.
                       PROPERTIES IMPORTED_LOCATION

                       # Provides the path to the library you want to import.
                       imported-lib/src/${ANDROID_ABI}/libimported-lib.so )
```

* lib name
* 指定参数
* 指定so的路径

这时候需要include_directories来指定so对应的头文件路径，上面也说到过了。


### 6. 总结
有理解的不对的，大家指出，共同学习共同进步。












_ _ _

参考资料：

* [Android.mk、文档](https://developer.android.com/ndk/guides/android_mk.html)
* [Application.mk 文档](https://developer.android.com/ndk/guides/application_mk.html)
* [Android 文档cmake 文档](https://developer.android.com/ndk/guides/cmake.html)
* [Android studio 中介绍](https://developer.android.com/studio/projects/add-native-code.html#existing-project)




