---
title: 脚本打怪-shell篇
date: 2016-12-03 01:05:38
categories: shell
tags: shell

---
<Excerpt in index | 首页摘要>
### 1.什么是shell

什么是shell呢？我们这里说的shell是指shell脚本，和window下的bat批命令处理类似，shell用于linux／unix系统，用来方便我们的操作，试想一下，原来需要一堆的命令，我们将其写成一个shell脚本，轻松搞定，是不是很带感。

+ <!-- more -->
<The rest of contents | 余下全文>



### 2.shell能干什么

shell能干什么？shell能干的就是简化我们的操作，将我们从繁琐、单一的操作中解放出来。

### 3.shell基础语法

#### 3.1 变量
```shell
#变量名＝变量值
myname="guolei"
echo ${myname}
```
shell的变量很有意识，和我们其他语言不通的一点，等号两边不能有空格，奇怪吧。如果我们想要使用这个变量，我们可以在变量名前＋$，大括号是用来区分界限的。

如果我们想要定义一个数组怎么办？

```shell
arr=(1 2 3 4)
echo $arr[0]
```

注意，元素之间没有逗号。

#### 3.2 传递参数

作为一个脚本，当然需要接受接受我们终端输入参数，我们通过 $i的形式去获取参数，i＝0... ，需要注意的是，i为1时才是我们输入的第一个参数，因为$0代表的是我们当前的执行脚本文件


#### 3.3 输出

shell中有两种输出方式，

* echo 
* printf

echo是一种普通的输出，而printf是一种格式化的输出，这里就不在多说了，这里和其他的语言并没有太大的区别。



### 4.shell运算符

这里和我们平常见到的语言是不一样的，原声的bash（一种shell解释器）是不支持简单的数学运算的。我们通常通过awk 和 expr，expr等来实现，我们将表达式放在 ` `之内，如

```shell
`expr 2 + 2`
```

要注意，*，我们需要用\来进行转移，因为他和某个东西冲突，我们后面会提到。

而关系运算符这就大不相同了，因为和命令或者是其他什么冲突的原因，shell脚本中采用下面这种方式来实现关系运算

* -eq 是否相等,
* -ne 是否不等
* -gt 左边是否大于右边
* -ge 左边是否大于等于右边
* -lt 左边是否小于右边
* -le 左边是否小于等于右边


老司机们一定发现规律么，没错，就是-+英文缩写,这里就不多叨叨了。

布尔运算也是同理。

* ! 非
* -o 或
* -a 与

shell中还有字符串运算符,文件测试运算符什么的，这里就不多说了。



### 5.shell流程控制

shell脚本的流程控制和其他如python、php还是有一点区别滴，最明显的区别就是 要有结束标志，对，结束表示，这是啥类，看语法。

```shell
if
then
	commend...
else
	commend...
elif
	commend...
fi

for var in 1 2 3 4
do
	commend...
done

while xxx
do
	commend...
done

//until循环，
until xxx
do
	commend
done

//case 比较恶心，我很不喜欢，需要用我再去学，嘿

break，continue 什么也是有的
```



### 6.函数

```shell
say(){
	echo $i
}

say 1
```
没错，上面就是函数的简单用法。

* 我们不需要手动指定参数
* 同样用$i 去获取参数
* 像命令一样say 1 2 3，传递参数

但是，从${10}开始，我们需要用大括号，扩起来。。

### 7. 输入输出重定向

略过略过，> < 将输入输出定向到其他位置（文件）

### 8. 总结

shell脚本学起来 编写起来都挺简单的。

* \* @，这些都表示全部，比如 $* $@,
* \# 哈，可以表示长度，如字符串长度，数组容量
* 变量赋值 key=value 注意 中间不能有空格
* 大小比较 -ge那些
* 函数，通过$? 能获取到返回值，而不能通过赋值来获取
* 如果参数大于10个，要用$(n)去获取

不过，shell最好的一点是批命令处理。

### 9. 举个小例子？

```shell
git pull

git add ./

git commit -m "xxx"

git push
```

很常见吧，加入我们把上面的写成shell脚本，是不是会简单很多？

```shell
cms="update"

hexo g

git add ./

if [ $# -ge 1 ]
then
	cms=$1
fi

git commit -m $cms

git push

```

这不，我们通过shell 脚本，每次./update.sh ,多方便啊。

### 10. 想法

想什么呢？还不赶紧去get shell脚本这个技巧。

不写脚本释放双手的程序员，不是好程序员。


### 11. 入门链接

[入门教程，看了还不会就可以转行了](http://www.runoob.com/linux/linux-shell.html)


---### 最近访客<ul class="ds-recent-visitors" data-num-items="46" data-avatar-size="40"></ul>