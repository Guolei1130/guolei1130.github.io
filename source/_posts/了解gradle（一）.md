---
title: 了解gradle（一）
date: 2016-12-05 21:27:31
categories: Gradle
tags: gradle

---
<Excerpt in index | 首页摘要>
想写gardle很长时间了，但是一直没写，现在，是时候写一下gradle文档中，重要的部分了。

### 1.依赖管理

```
repositories {
    mavenCentral()
}

dependencies {
    compile group: 'org.hibernate', name: 'hibernate-core', version: '3.6.7.Final'
    testCompile group: 'junit', name: 'junit', version: '4.+'
}
```

+ <!-- more -->
<The rest of contents | 余下全文>



* respositories 声明我们要使用的仓库
* dependencies 我们要依赖的一些东西
	* compile 依赖需要编译生产项目的来源
	* runtime 依赖运行时字节码
	* testCompile 依赖测试代码
	* testRuntime 
	
通常，我们声明仓库有两种方式

* 使用中央仓库 mavenCentral()
* 使用自己的仓库
	* 使用远程仓库
	
		```
	repositories {
    maven {
    	// 自己远程仓库地址
        url "http://repo.mycompany.com/maven2"
    }
}
	```
	* 使用本地仓库	 
	
		```
		repositories {
    ivy {
        // URL can refer to a local directory
        url "../local-repo"
    }
}
		```
		
		
		
再说我们的依赖包管理，同样有两种方式

```
// 1
compile 'org.hibernate:hibernate-core:3.6.7.Final'
// 2
compile group: 'org.hibernate', name: 'hibernate-core', version: '3.6.7.Final'
```

我们最常用的是第一种方法。

有的时候，可能会存在包冲突，这时候我们可以通过如下代码，排除

```
    compile("com.squareup.retrofit2:adapter-rxjava:$rootProject.retrofit2Version") {
        exclude group: 'com.squareup.retrofit2'
    }
```

关于如何上传仓库这里暂时不介绍,[可以看这里](https://github.com/JakeWharton/butterknife/blob/master/gradle/gradle-mvn-push.gradle)

### 2.编写gradle脚本

#### 2.1 Project API

```
println project.buildDir
```

我们可以通过project得到我们project的一些属性，关于可以得到哪些舒心，我这里就不说了。动手才是王道。

#### 2.2 如何定义变量



和大多数脚本语言一下，groovy也是弱类型语言，同样通过def关键字定义变量。

```
def my_name = "guolei"
println my_nme
```

#### 2.3 Extra 属性

```
ext {
    my_name = "guolei"
}

println ext.my_name;
```

#### 2.4 TASK 

gradle内置了许多现成的tasks，在org.gradle.api.tasks包下面，需要的时候我们可以查阅用法。[gradle api文档地址](https://docs.gradle.org/current/javadoc/)，关于Api的使用，这里就不介绍了，文档上使用方法很全。

#### 2.5 TASK之间的依赖关系

我们可以使用dependsOn来指明task之间的关系。

```
taskX.dependsOn taskY

```

如例子，taskX是依赖y的，也就是说，在执行x的时候，会先执行y。


#### 2.6 有序的TASKS

* shouldRunAfter
* mustRunAfter


#### 2.7 给task添加描述

```
task a {
	description "xxx"
	println "xx"
}

```

#### 2.8 跳过task不执行

* onlyIf,满足条件的情况下才执行

```
task hello {
    doLast {
        println 'hello world'
    }
}

hello.onlyIf { !project.hasProperty('skipHello') }
```

* 用异常

```
compile.doFirst {
    // Here you would put arbitrary conditions in real life.
    // But this is used in an integration test so we want defined behavior.
    if (true) { throw new StopExecutionException() }
}
```

* enabled属性

```
task.enabled = false
```

### 3.如何操作文件


我们可以利用Project.file 方法去获取文件

```
// Using a relative path
File configFile = file('src/config.xml')

// Using an absolute path
configFile = file(configFile.absolutePath)

// Using a File object with a relative path
configFile = file(new File('src/config.xml'))
```


然后利用Project.files方法去获取FileCollection（文件集合，一些列文件）

```

FileCollection collection = files('src/file1.txt',new File('src/file2.txt'),['src/file3.txt', 'src/file4.txt'])
```

可以利用Project.fileTree获取文件树。

```
// Create a file tree with a base directory
FileTree tree = fileTree(dir: 'src/main')

// Add include and exclude patterns to the tree
tree.include '**/*.java'
tree.exclude '**/Abstract*'

// Create a tree using path
tree = fileTree('src').include('**/*.java')

// Create a tree using closure
tree = fileTree('src') {
    include '**/*.java'
}

// Create a tree using a map
tree = fileTree(dir: 'src', include: '**/*.java')
tree = fileTree(dir: 'src', includes: ['**/*.java', '**/*.xml'])
tree = fileTree(dir: 'src', include: '**/*.java', exclude: '**/*test*/**')

```

我们可以操作压缩文件。

```

// Create a ZIP file tree using path
FileTree zip = zipTree('someFile.zip')

// Create a TAR file tree using path
FileTree tar = tarTree('someFile.tar')

//tar tree attempts to guess the compression based on the file extension
//however if you must specify the compression explicitly you can:
FileTree someTar = tarTree(resources.gzip('someTar.ext'))
```

文件复制，这里我们要用到gradle api里面的copy去做。关于如何使用这就不介绍了，上面有说到过api地址。

关于文件的复制、删除、重命名、过滤等都是api的使用，这里就不说了。


### 4. 如何打log

我们可以通过logger的一些方法输出log日志

```
ogger.quiet('An info log message which is always logged.')
logger.error('An error log message.')
logger.warn('A warning log message.')
logger.lifecycle('A lifecycle info log message.')
logger.info('An info log message.')
logger.debug('A debug log message.')
logger.trace('A trace log message.')
```

### 5. gradle plugins

```
apply from: 'other.gradle'
```

```
plugins {
    id «plugin id» version «plugin version» [apply «false»]
}
```

```
 apply plugin: 'org.gradle.sample.goodbye'
```

三种方式。

### 6.总结 

上面的一些用法，全部来自于文档.

[gradle 文档地址](https://docs.gradle.org/current/userguide/)







