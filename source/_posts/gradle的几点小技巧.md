---
title: gradle的几点小技巧
date: 2017-03-14 22:15:12
tags: gradle

---
<Excerpt in index | 首页摘要>
### 前言

最近入职新公司，也开发出来一些比较不错的小技巧，来分享给大家。

<!-- more -->
<The rest of contents | 余下全文>


### 如何在release包中去除一些debug包中的东西

我们平常肯定有遇到过这种情况，就是我们一些帮助调试的三方框架，我们并不想打包到release包中，而一次次的删出代码、删依赖总是很麻烦，有没有简单点的办法呢。必须有。思路是这样的，创建一个debughelper，我们在打包的时候，分别针对release和debug包，做依赖以及文件排除、等工作。

```
--debug
	--DebugHelper.java
--main
--release
	--DebugHelper.java

```


其中，我们在debug目录下，放debug的一些代码，如

```
    public static void initLeakCanary(Application application){
        if (LeakCanary.isInAnalyzerProcess(application)){
            return;
        }
        LeakCanary.install(application);
    }

    public static OkHttpClient.Builder createOkHttpBuilder(){
        return new OkHttpClient().newBuilder()
                .addNetworkInterceptor(new HttpLoggingInterceptor()
                        .setLevel(HttpLoggingInterceptor.Level.BODY))
                .addNetworkInterceptor(new StethoInterceptor());
    }
```

release目录下，放release的，当然，这下面是空的。

```
    public static void initStethoInterceptor(Application application){
    }

    public static void initLeakCanary(Application application){

    }
    public static OkHttpClient.Builder createOkHttpBuilder(){
        return new OkHttpClient().newBuilder();
    }
```

需要注意的是，debug目录、release目录都，文件的包名都要一样。
最后，在gradle文件中配置。

```
            dependencies {
                debugCompile "com.facebook.stetho:stetho:${libraryVersion.stetho}"
                debugCompile "com.facebook.stetho:stetho-okhttp3:${libraryVersion.stetho}"
                debugCompile "com.facebook.stetho:stetho-js-rhino:${libraryVersion.stetho}"
            }
            sourceSets{
                sourceSets{
                    main{
                        java {
                            srcDir 'src/main/java'
                            exclude '**/DebugHelper.java'
                            srcDir 'src/debug/java'
                        }
                    }
                }
            }
            
            sourceSets{
                main{
                    java.srcDirs = ['src/main/java','src/release/java']
                }
            }
```

这样就可以了。


### 三方包的统一管理

这里要说的不是在根gradle文件中，写ext的方法，而是另外一种。

我们将这些写在一个properties文件中，然后在一个gradle脚本中读取。脚本内容如下:

```
def libraryVersion = new Properties()
libraryVersion.load(new FileInputStream(rootProject.file("libversion.properties")))
project.ext.set("libraryVersion", libraryVersion)
```
然后在需要的地方。

```
apply from:'../libmanager.gradle'

compile "com.squareup.okhttp3:logging-interceptor:${libraryVersion.loggingInterceptor}"
```

### 如何在debug版本，依赖一个debug的model

首先，我们需要在module的gradle文件中，添加如下配置

```
oid {
    publishNonDefault true
```

在主App中的gradel中做如下配置：

```
    buildTypes {

        debug {
            minifyEnabled false
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
            buildConfigField "boolean", "IS_DEBUG", "true"
            dependencies {
                debugCompile project(path:':base', configuration:'debug')
            }
        }

        release {
            minifyEnabled false
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
            buildConfigField "boolean", "IS_DEBUG", "false"
            dependencies {
                releaseCompile project(path:':base', configuration:'release')
            }
        }
    }
```

如上配置之后，我们就能在debug版本中依赖debug的module，而在release版本中依赖release的module了。
### 最近访客
<ul class="ds-recent-visitors" data-num-items="46" data-avatar-size="40"></ul>