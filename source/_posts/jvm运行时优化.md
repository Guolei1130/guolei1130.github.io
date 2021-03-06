---
title: jvm运行时优化
date: 2017-01-20 21:48:56
categories: Java
tags: jvm

---
<Excerpt in index | 首页摘要>
### 前言

>深入理解java虚拟机

java虚拟机最开始是通过解释器进行解释执行的，当虚拟机发现某个方法或者代码块的运行特别频繁时，就会把这些代码认定为"热点代码"，为了提高热点代码的执行效率，在运行时，虚拟机会把这些代码编译成与本地平台相关的机器码，并进行各种层次的优化，完成这个任务的编译器称为即时编译器(JIT)

<!-- more -->
<The rest of contents | 余下全文>


![](http://s15.sinaimg.cn/mw690/0019kvgRgy6XClCB6OOfe)

* Clinet Compiler C1编译器
* Server Compiler C2编译器

为了在程序启动和运行效率之间达到平衡，hotspot虚拟机会逐渐启动分层编译:

* 第一层 程序解释执行
* 第二层 C1编译，将字节码编译成本地代码，进行简单、可靠的优化
* 第二层 C2编译，将字节码编译成本地代码，会进行深层次的优化

### 编译对象与触发条件

热点代码有两种:

* 被多次调用的方法体，编译器会以整个方法作为编译对象，标准的JIT编译
* 被多次执行的循环体，编译器依然会编译整个方法，发生在方法的执行过程中，被称为栈上替换。

判断热点代码的方式有两种：

* 基于采样的热点探测
* 基于计数器的热点探测

hotspot虚拟机中采用的是第二种。为每个方法提供两种计数器:方法计数器(计数方法被调用次数)和回边计数器(循环体代码执行次数)，当两个计数器的和达到阀值，就会触发JIT编译。在一定的时间内，如果没有代码执行，就会衰减。

### 编译优化技术

编译优化的技术特别多，这里记录下书中的几个。

* 方法内联，去除方法调用成本，
* 冗余访问消除
* 复写传播
* 无用代码消除
* 公共子表达式消除，没必要重复计算公共子表达式的值
* 数组边界检查消除
* 逃逸分析，分析对象的动态作用域，一个对象定以后，被外部方法调用，称为方法逃逸，被其他线程访问到，称为线程逃逸
	* 栈上分配
	* 同步消除
	* 标量替换
	

### 参考资料

来自经典好书 深入理解java虚拟机。建议入手一本，














### 最近访客
<ul class="ds-recent-visitors" data-num-items="46" data-avatar-size="40"></ul>