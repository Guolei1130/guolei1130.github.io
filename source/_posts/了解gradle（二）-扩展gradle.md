---
title: 了解gradle（二）-扩展gradle
date: 2016-12-06 11:41:32
categories: Gradle
tags: gradle

---
<Excerpt in index | 首页摘要>

### 1. 如何编写一个task类

在我们的gradle文件里面，我

```Groovy
class GreetingTask extends DefaultTask {

}
```

即可定义一个task，我们可以在task中通过@注解实现一个方法。如：

```Groovy
class GettingTask extends DefaultTask{
    @TaskAction
    def greet(){
        println "hello world"
    }
}

```

那么，我们该如何调用呢？

+ <!-- more -->
<The rest of contents | 余下全文>


### 1. 如何编写一个task类

在我们的gradle文件里面，我

```Groovy
class GreetingTask extends DefaultTask {

}
```

即可定义一个task，我们可以在task中通过@注解实现一个方法。如：

```Groovy
class GettingTask extends DefaultTask{
    @TaskAction
    def greet(){
        println "hello world"
    }
}

```

那么，我们该如何调用呢？

```Groovy
task printString(type:GettingTask)
```

那么问题来了，我们如何向其中传递参数呢？

* 首先，我们在class里面加成员变量
* 然后，我们调用的时候，传入值



	```Groovy
	task testPrint(type:GettingTask){
	// 这里用＝ 或者空格
    string = "guolei"
}

class GettingTask extends DefaultTask{

    String string = "xxxx"

    @TaskAction
    def greet(){
        println string
    }
}
	```
	
	

### 2. 编写独立的插件程序

可以利用as编写插件，这里，我们可以新建 app model、android lib modle或者java lib model，都可以，并且把main下面全删掉，gradle里也全删掉。

然后，在gradle中，依赖groovy

```Groovy
apply plugin: 'groovy'

dependencies {
    compile gradleApi()
    compile localGroovy()
}
```

在main下面新建groovy目录，在里面建包，建groovy类，然后实现Plugin<Project>接口，实现apply方法。

接下来在groovy同级目录，新建resources目录，里面建META-INF目录，这个目录下面在建gradle-plugin目录，这个目录下建"plugin_id".properties目录，用来配置gradle插件，在文件中配置插件。

```Groovy
implementation-class=com.gl.HelloPlugin
```
后面对应插件实现。

最后发布，这里就不发不到jcenter了，后面会专门写一篇关于发布的。发布到本地仓库。

```Groovy
apply plugin: 'groovy'
apply plugin: 'maven'

dependencies {
    compile gradleApi()
    compile localGroovy()
}

repositories {
    mavenCentral()
}

group='com.gl.HelloPlugin'
version='1.0.0'
uploadArchives {
    repositories {
        mavenDeployer {
            repository(url: uri('../repo'))
        }
    }
}

```

在右侧图形界面或者命令执行uploadArchives，就发布成功了。

如何使用，首先我们在跟目录下配置mevan仓库。

```Groovy
maven {
            url uri('./repo')
        }
        
```

然后依赖插件

```Groovy
classpath 'com.gl.HelloPlugin:gradleplugin:1.0.0'
```

解释一下，后面分为三个部分

* 第一部分，插件实现的路径
* 你创建插件时候的model 名
* 插件版本


这三个也可以通过查看 repo下的路径得到，

最后，在我们想用的地方

```Groovy
apply plugin:'com.gl.plugin'
```

* 后面跟的是pluginid，也就是我们上面properties文件的前半部分。


可以看到，开发过程基本和apt 编译时注解流程一致。

---### 最近访客<ul class="ds-recent-visitors" data-num-items="46" data-avatar-size="40"></ul>