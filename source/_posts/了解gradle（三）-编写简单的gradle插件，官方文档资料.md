---
title: 了解gradle（三）-编写简单的gradle插件，官方文档资料
date: 2017-03-21 23:35:44
categories: Gradle
tags: gradle

---
<Excerpt in index | 首页摘要>
### 前言

前面也有介绍一些gradle的简单知识，但是这还不够，我们要想编写一些gradle插件，还是需要一些技巧，今天接着学习gradle。内容来自于官方文档。


<!-- more -->
<The rest of contents | 余下全文>

### 配置环境变量

这里只介绍mac下的环境变量配置。首先进入到~目录

```
cd ~
```

然后用vim打开.bash_profile文件，如果没有，vim会为我们创建。

```
vim .bash_profile
```

在里面加入如下配置。

```

GRADLE_HOME=/Applications/Android\ Studio.app/Contents/gradle/gradle-2.14.1
export GRADLE_HOME
export PATH=${PATH}:${GRADLE_HOME}/bin

```

* 注意将上面gradle的路径换成你自己的路径,保存退出

最后

```
source .bash_profile
```

同步配置,gradle -version测试一下。

### 编写简单的plugin

继承Plugin类，并实现apply方法。

```
apply plugin: GreetingPlugin

class GreetingPlugin implements Plugin<Project> {
    void apply(Project project) {
        project.task('hello') {
            doLast {
                println "Hello from the GreetingPlugin"
            }
        }
    }
}
```

调用gradle -q hello 去运行这个task

```
> gradle -q hello
Hello from the GreetingPlugin
```

### 获取build中的输入

代码如下：


```
apply plugin: GreetingPlugin

greeting {
    message = 'Hi'
    greeter = 'Gradle'
}

class GreetingPlugin implements Plugin<Project> {
    void apply(Project project) {
        project.extensions.create("greeting", GreetingPluginExtension)
        project.task('hello') {
            doLast {
                println "${project.greeting.message} from ${project.greeting.greeter}"
            }
        }
    }
}

class GreetingPluginExtension {
    String message
    String greeter
}
```

不难理解，我们能从构建脚本中获取对应块中的内容，转化成我们插件中对象的类似java bean的东西。


### 参考资料

[Writing Custom Plugins](https://docs.gradle.org/current/userguide/custom_plugins.html)


### 最近访客
<ul class="ds-recent-visitors" data-num-items="46" data-avatar-size="40"></ul>