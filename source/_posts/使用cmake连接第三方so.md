---
title: 使用cmake连接第三方so
date: 2017-06-22 23:35:41
tags: jni

---
<Excerpt in index | 首页摘要>
### 前言

在开发当中，我们难免会遇到需要使用别人提供so的时候，假如so只提供了纯c接口，怎么办。这一篇讲记录，如何使用cmake连接第三方so。

<!-- more -->
<The rest of contents | 余下全文>



### 准备工作

* so一个，可以自己编译一个
* so对应的头文件

### 开发

在我们自己的c++中，引入so提供出来的接口头文件，并调用其中的一些方法。

### 编译

编译的过程主要是编写cmakelist文件，这个按照android studio上的cmake教程，没连接成功，下面就看下，连接成功的一种方法。

```
cmake_minimum_required(VERSION 3.4.1)
set(libs_DIR src/main/jnilib/${ANDROID_ABI})
set(libs_include_DIR src/main/cpp)
include_directories(${lib_include_DIR})
link_directories(${libs_DIR})
add_library( native-lib
             SHARED
             src/main/cpp/native-lib.cpp )
target_link_libraries(native-lib
                      demo )
find_library(log-lib
              log )
target_link_libraries(native-lib demo
                      ${log-lib} )
```

步骤如下：

* 指定版本
* 设置提供给我们的so路径(第二行)
* 设置提供给我们头文件路径(第三行)
* 导入头文件（4）
* 连接so（5）
* 指定本次生成的so
* 讲第三方so连接到本次生成的so中
* 连接log

连接log的一步可以去掉。如果没用到log的话。

做完这些，还需要在gradle里面配置abifliter，默认生成全平台，如果别人提供的不是全平台，有没设置fliter的话，编译不通过。

注意，别人提供的so，格式要对，libxxx.so的格式，别加奇怪的数字什么的。

### demo

demo上传到github上了，[Demo地址](https://github.com/Guolei1130/Demo)
### 最近访客
<ul class="ds-recent-visitors" data-num-items="46" data-avatar-size="40"></ul>