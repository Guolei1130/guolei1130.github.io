---
title: monkey和monkeyRunner
date: 2017-09-02 19:55:55
tags: Android
categories: 自动化测试

---
<Excerpt in index | 首页摘要>
### 前言

Monkey测试还是挺好玩的。


<!-- more -->
<The rest of contents | 余下全文>


### Monkey

```
adb shell monkey 

```

便可查询一些monkey测试可使用的参数，链接手机或者模拟器

```
adb shell monkry -p 你的包名 -v 模拟点击次数
```

就可以执行一些非常简单的monkey测试。

关于更多参数，自行查看提示或者查看文档。

### MonkeyRunner

monkeyrunner提供了更多可控的操作，一般来说monkey测试太随机了。monkeyrunner可以执行一段我们预先可好的脚本，按照我们的要求去执行。

[monkeyrunner基础文档](https://developer.android.com/studio/test/monkeyrunner/index.html)


而我们只要在终端执行monkeyrunner，就能进入交互式环境。像写python一些编写，不过这里是jython。不多bb

### 从源码中找寻可用api

实话说，这里才是我想说的重点，monkery和monkeyrunner的用法，网上随处可见，但都千篇一律。似乎官方也没给出太多的文档。不过我们可以从源码中找到用法，但是是哪jython写的，不影响我们看。怎么滴一点简单的python总会吧。
以monkeydrvice为例。他的源码在这里。[点我看代码，翻墙必须的](https://android.googlesource.com/platform/tools/swt/+/d9880c7c4d4c12d94d2059453361f1c3691a901d/monkeyrunner/src/main/java/com/android/monkeyrunner/MonkeyDevice.java?autodive=0%2F%2F%2F)

找一个文档中没有给的例子

```
    @MonkeyRunnerExported(doc = "Get the HierarchyViewer object for the device.",
            returns = "A HierarchyViewer object")
    public HierarchyViewer getHierarchyViewer(PyObject[] args, String[] kws) {
        return impl.getHierarchyViewer();
    }
```

这个方法在文档中是没有给的，不过我们可以用这个，但是这个又涉及到HierarchyViewer的一些操作。没关系，我们知道如从源码中找寻可用api就行了。

在举个带参数的例子。

```
    @MonkeyRunnerExported(doc = "Given the name of a variable on the device, " +
            "returns the variable's value",
            args = {"key"},
            argDocs = {"The name of the variable. The available names are listed in " +
            "http://developer.android.com/guide/topics/testing/monkeyrunner.html."},
            returns = "The variable's value")
    public String getProperty(PyObject[] args, String[] kws) {
        ArgParser ap = JythonUtils.createArgParser(args, kws);
        Preconditions.checkNotNull(ap);
        return impl.getProperty(ap.getString(0));
    }
```

不想多说什么，清晰的不能再清晰了，虽然我们看不懂源码，但是我们却能冲MonkeyRunnerExported中找到用法。包裹参数，返回值等等信息。

并且，源码中有很多文档被没有给出但是却额能十分有用的东西，比如easy、recorder等等。

而HierarchyViewer，我们可以从[HierarchyViewer源码](https://android.googlesource.com/platform/tools/swt/+/d9880c7c4d4c12d94d2059453361f1c3691a901d/chimpchat/src/main/java/com/android/chimpchat/hierarchyviewer/HierarchyViewer.java?autodive=0%2F%2F%2F%2F%2F%2F%2F%2F)  获取到他的用法。

android/platform/tools/下面，有非常多的工具，作为Android开发者，我觉得是有必要了解的。

[地址，记得翻墙](https://android.googlesource.com/platform/tools/) 
### 最近访客
<ul class="ds-recent-visitors" data-num-items="46" data-avatar-size="40"></ul>