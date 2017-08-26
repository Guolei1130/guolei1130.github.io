---
title: databinding基础知识
date: 2017-08-26 20:44:45
category: Android
tags: Android

---
<Excerpt in index | 首页摘要>
### 前言

google出的databinding库，相信很多人都已经使用了，经过这么长时间的发展，是时候放到项目里使用了。

<!-- more -->
<The rest of contents | 余下全文>


### 基本用法

#### 开启databiding

```
android {
    ....
    dataBinding {
        enabled = true
    }
}
```

注意：建议使用最新版的Android studio，我在使用的过程中发现as 2.2版本，databinding的双向绑定有点小问题。

将我们的布局文件做稍许的修改。

```
<?xml version="1.0" encoding="utf-8"?>
<layout xmlns:android="http://schemas.android.com/apk/res/android">
   <data>
       
   </data>
   
   <LinearLayout>
   
   </LinearLayout>
</layout>
```

分为两部分，data数据部分以及原先的布局两部分。


#### 绑定数据

要向绑定数据，我们要准备好bean，这里我准备一个Student，有name和age两个属性。

```
public class Student {
    private String name;
    private int age;

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public int getAge() {
        return age;
    }

    public void setAge(int age) {
        this.age = age;
    }
}
```

然后，我们在布局中，使用。

```
<?xml version="1.0" encoding="utf-8"?>
<layout>

    <data>
        <import type="String"/>
        <variable
            name="student"
            type="com.guolei.baseuse.Student"/>
    </data>

    <android.support.constraint.ConstraintLayout
        xmlns:android="http://schemas.android.com/apk/res/android"
        xmlns:app="http://schemas.android.com/apk/res-auto"
        xmlns:tools="http://schemas.android.com/tools"
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        tools:context="com.guolei.baseuse.BaseUseActivity">
        <LinearLayout
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:orientation="vertical"
            >
            <TextView
                android:layout_width="match_parent"
                android:layout_height="50dp"
                android:text="@{student.name}"
                android:gravity="center"
                />

            <TextView
                android:layout_width="match_parent"
                android:layout_height="50dp"
                android:text="@{String.valueOf(student.age)}"
                android:gravity="center"
                />
        </LinearLayout>
    </android.support.constraint.ConstraintLayout>
</layout>


```

注意 ：

* 我们在data下用variable声明了一个类型为Student的变量student，
* 我们用import将String 这个类导进来，然后我们就可以在这里使用String的一些静态方法了
* 我们用@{}语法来使用变量的属性，如name，age等

完成这些之后，我们需要make一些module，这个过程会生成我们后面需要使用的一些中间文件和类。

最后，在Activity中，生成binding并且绑定变量。如下

```
        ActivityBaseUseBinding binding = DataBindingUtil.setContentView(this,R.layout.activity_base_use);
        Student student = new Student();
        student.setName("_StriveG");
        student.setAge(22);
        binding.setStudent(student);
```

这样，数据就绑定在了布局上。

#### 生成的binding类

生成的binding类中，包含我们布局的很多信息。那么，我们如何构造一个binding对象呢。有下面几种办法

* DataBindingUtil中提供了一些方法，如setcontentview，inflate,bind,getbind等等一些办法，
* 同样，生成的具体binding类，如上面的ActivityBaseUseBinding中，也有inflate、bind等办法，不过，推荐使用DataBindingUtil的

生成的databinding类中，还顺带生成了，我们在布局文件中，指定了id的控件，我们可以通过这个类去操作view，省去了我们findviewbyid。

#### 绑定事件

绑定事件有两种方法，方法引用和监听器绑定，分别来说下。

1. 方法引用

	首先声明一个类，
	
	```
	    public static class MethodRef{
        public void onClick(View view) {
            Log.e(TAG, "onClick: " );
        }
    }
	
	```
	
	其次，我们需要在布局文件中加入这个变量，并且为onclick属性绑定这个方法。
	
	```
  <variable
            name="methodRef"
            type="com.guolei.baseuse.EventHandling.MethodRef"/>
            
      <Button
            android:layout_width="match_parent"
            android:layout_height="50dp"
            android:onClick="@{methodRef::onClick}"
            />
	```
	
	最后，给这个绑定变量，binding.setMethodRef(new MethodRef())

	但是，这里有一个缺点，就是以这种方式绑定的方法，只能有view属性，不能有其他参数，有其他参数的情况下，编译会报错。怎么办呢？监听器绑定
	
2. 监听器绑定

与方法绑定类似，不同的是在onclick属性中，我们使用的是如下表达式

```
@{(it)->listener.onClick(student)} 或者@{()->listener.onClick(it,student)}

```

上面只是OnClickListener的形式，其他的listener类似。

#### 包含include标签的情况

包含include标签的情况下我们如何给include的布局绑定呢

```
<?xml version="1.0" encoding="utf-8"?>
<layout xmlns:android="http://schemas.android.com/apk/res/android"
        xmlns:bind="http://schemas.android.com/apk/res-auto">
   <data>
       <variable name="user" type="com.example.User"/>
   </data>
   <LinearLayout
       android:orientation="vertical"
       android:layout_width="match_parent"
       android:layout_height="match_parent">
       <include layout="@layout/name"
           bind:user="@{user}"/>
       <include layout="@layout/contact"
           bind:user="@{user}"/>
   </LinearLayout>
</layout>
```

官方例子，懒得自己写了。

#### set属性

set属性的方法就很简单了，这里分为三种情况。

1. android:xxx属性，通过@{}绑定即可
2. 若为自定义控件，则app:xxx ，通过@{}绑定
3. 如对应的属性没有提供setXXX方法的话，就需要通过@BindingAdapter自定义，举个例子

```
    @android.databinding.BindingAdapter("app:progress")
    public static void setProgress(View view,int progress) {
        view.setPreogress(progress);
    }
```

* 注意，方法一定要是static的
* 这样，我们就能在不居中通过app:progress来指定属性了


### 总结

这篇只说明了一些很简单很简单的基础用法，下篇会出一些比较高级的用法。当然，这篇中很多基础用法也没介绍完，个人感觉没啥输的，官方文档中很全很详细了。

[官方文档，要翻墙！](https://developer.android.com/topic/libraries/data-binding/index.html)
### 最近访客
<ul class="ds-recent-visitors" data-num-items="46" data-avatar-size="40"></ul>