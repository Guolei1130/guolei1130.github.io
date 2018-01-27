---
title: ViewModel的一些思考
date: 2018-01-21 21:07:42
tags: Android

---
<Excerpt in index | 首页摘要>
### 前言

最近很长一段时间都在使用MVVM,但是遇到一点问题导致代码写不太好。今天就思考下VM层和V层的一些问题。

<!-- more -->
<The rest of contents | 余下全文>



### 几个问题

1. VM和V的通信
2. 在列表类型的视图中，Activity的ViewModel与Item的ViewModel通信问题
3. 当多个界面拥有共同控件时，是选择继承还是组合
4. 同一组件，但是在不同场景下对应的modle层Entity不同


下面根据上面的几个问题，做一些思考。

### VM和V的通信

在[Google Sample中](https://github.com/googlesamples/android-architecture)，ViewModel和View层的通信使用Navigator的形式。刚开始，我也模仿着使用Navigator，但是用了一端时间之后，感觉并不是很合适。Navigator在意思上更偏向于导航，跳转这样的场景。那么，应该怎么样使用或者命名呢？想了以下几种：

1. Navigator
2. EventBus
3. EventDelegate

事实上，1和3是同一种写法，只不过在命名上有一点差别，EventBus的方法维护起来不方便。




### 父ViewModel和子ViewModel通信的问题

这个是一个很常见的场景，比如说一个Activity的ViewModel中包含的子ViewModel，子ViewModel的变化能影响到父ViewModel，对于这样的场景，通常，我选择在父ViewModel构建子ViewModel的时候，注入一个CallBack接口，利用这个CallBack接口来做。

**补充**

上面的几种方法，不好解决viewmodel嵌套情况下，listener的传递问题，因此，可以使用IOC的思想，参考ViewModelProvider的设计，或者用dagger2去解决这个问题


### 多个界面共同组件问题

这也是一个很常见的场景，例如多个页面底部都有个评论框这种，这种业务场景下的话，我们会把评论框部分做成组件。用<include>去引用，这种情况下，我们就要考虑我们是使用组合还是继承了。更推荐继承。


### 同一组件，对应不同的Entity

这种场景应该不是特别多，但是还是会有的。那么，这种情况下，我们构建ViewModel的时候，就不能已Entity作为参数了，怎么办呢？我们可以声明一个接口，这个接口中，定义一些列我们这个组件需要的数据的get方法。对应不同的Entity，我们有不同的实现，而我们只需要传给ViewModel我们的实现即可。


### 最近访客
<ul class="ds-recent-visitors" data-num-items="46" data-avatar-size="40"></ul>