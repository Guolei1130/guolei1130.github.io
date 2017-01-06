---
title: 记不住adb命令？试试shell吧
date: 2016-12-20 23:06:36
tags: shell

---
<Excerpt in index | 首页摘要>
### 1. 前言

我们日常开发中，经常会需要使用adb工具做一些操作，比如，push文件、pull文件、安装apk、dump一些信息等等，命令太长记不住怎么办？没关系，我们可以把这些东西写成shell脚本。这里我就简单举几个例子。

+ <!-- more -->
<The rest of contents | 余下全文>

### 2. push and pull file

要写一些shell脚本其实也是很简单的，比如push文件、pull文件等等。

```shell
#!/bin/bash

basedir="pull_dir"

mkdir ${basedir}

topath="./${basedir}/"

if [ $# = 0 ]
then
	echo 'please input fromfile'
	exit
fi

frompath=$1

adb pull $1 ${topath}

```

```shell
topath="sdcard/"

if [ $# = 0 ]
then
	echo "please input file path"
	exit
fi

filepath=$1

if [ $# = 2 ]
then
	topath=$2
fi

adb push ${filepath} ${topath}

```

### 3. dumps 一些信息

有时候我们需要dump一些信息出来，比如内存，电量等等。

```shell

filepath=`./custom.sh`

result=""

filename=""

if [ $# = 0 ]
then
	filename="meminfo_all"
	result=`adb shell dumpsys meminfo`
else
	filename="memoinfo_pkg"
	result=`adb shell dumpsys meminfo $1`
fi

#echo "hello" >> "${filepath}${filename}"
echo "$result" >> "${filepath}${filename}"
```

```shell
filepath=`./custom.sh`

result=`adb shell dumpsys power`

filename="power_state"

```

### 4. 可以利用python ＋ adb命令，实现自动化一些自动化测试

[Android测试中常用到的脚本](https://github.com/gb112211/AndroidTestScripts)

### 5. 总结

总之，用shell 和 python等一些脚本，能够做出很多好玩的事。

