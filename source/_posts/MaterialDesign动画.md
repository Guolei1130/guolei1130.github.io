---
title: MaterialDesign动画
date: 2018-01-27 20:38:17
tags: 动画
categories: Android

---

<Excerpt in index | 首页摘要>
### 前言

对于现在来说，大多数用户已经在使用5.0的手机了，4.4及以下的已经非常少了，那么，我们有理由把我们的app带向Material Design。Material Design中很重要的一项就是动画。


<!-- more -->
<The rest of contents | 余下全文>


### Ripple-触摸反馈

默认的，继承了MeaterialDesign主题的都带了反馈效果。系统默认有两种实现

* ?android:attr/selectableItemBackground 指定有界的波纹
* ?android:attr/selectableItemBackgroundBorderless 指定越过视图边界的波纹


自带有界效果

![自带有界效果](https://github.com/Guolei1130/blog_resource/blob/master/art/md_anim/selectableItemBackground.gif?raw=true)

自带无界效果

![自带无界效果](https://github.com/Guolei1130/blog_resource/blob/master/art/md_anim/selectableItemBackgroundBorderless.gif?raw=true)


一个是有边界的，一个是无边界的。当然，某些情况下我们或许不满足与系统提供的，这时，我们可以选择自己是先，在drawable下定义。最简单的是这样

```
<ripple xmlns:android="http://schemas.android.com/apk/res/android"
    android:color="@color/colorAccent"
    >
</ripple>

```

自定义无界无mask效果

![自定义无界无mask效果](https://github.com/Guolei1130/blog_resource/blob/master/art/md_anim/custom_wujie.gif?raw=true)

上面的效果是无界的。那么，我们怎么定义一个有界的呢？我们只需要在ripple下加一个item，这个item就是我们的边界了。

```
<?xml version="1.0" encoding="utf-8"?>
<ripple xmlns:android="http://schemas.android.com/apk/res/android"
    android:color="@color/colorAccent"
    >
    <item android:drawable="@color/colorPrimary"/>
</ripple>
```

自定义有界无mask效果

![自定义有界无mask效果](https://github.com/Guolei1130/blog_resource/blob/master/art/md_anim/custom_youjie.gif?raw=true)

那么，既然我们的边界item是一个drawable，我们当然可以选择其他类型的drawable作为边界。如shape，image。这样，我们控件被染成了item的颜色，我们如何去掉这个颜色呢？只要给这个设置id为android:id="@android:id/mask"即可。

```
```
<?xml version="1.0" encoding="utf-8"?>
<ripple xmlns:android="http://schemas.android.com/apk/res/android"
    android:color="@color/colorAccent"
    >
    <item android:drawable="@color/colorPrimary" android:id="@android:id/mask"/>
</ripple>
```

```


当我们设置mask之后，默认就是隐藏的拉。

自定义有界有mask效果

![自定义有界有mask效果](https://github.com/Guolei1130/blog_resource/blob/master/art/md_anim/custom_youjie_mask.gif?raw=true)


关于触摸反馈就说这么多。

### Circular Reveal-揭露效果

这个效果呢，非常简单，我们只需要ViewAnimationUtils.createCircularReveal这个api去create一个Animator即可。

```
        circularRevealView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                    Animator animator = ViewAnimationUtils.createCircularReveal(circularRevealView,circularRevealView.getWidth(),
                            circularRevealView.getHeight(),0,
                            (float) Math.hypot(circularRevealView.getWidth(), circularRevealView.getHeight()));
                    animator.setDuration(3000);
                    animator.start();
                }
            }
        });
```

参数就是起始点，起始半径以及最终半径，在这个效果里，以右下角为例，最终半径为斜边长度。

效果图：

![](https://github.com/Guolei1130/blog_resource/blob/master/art/md_anim/ciecular_reveal.gif?raw=true)

### Transitions-场景过度

这个在4.4的版本加入，在5.0上又加了几个动画。那么什么是场景(Scene)呢？我们可以看成是一系列View的集合。我们对着一系列View做动画。一般由View状态发生变化时触发，比如显示隐藏。那么我们如何使用呢？我们可以选择创创建Scene或者不创建Scene两种方式，统一由TransitionManager去管理。

```
        final Slide slide = new Slide();
        final Fade fade = new Fade();
        findViewById(R.id.anim).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
//                TransitionManager.beginDelayedTransition((ViewGroup) findViewById(R.id.sssss),new Fade());
//                findViewById(R.id.anim).setVisibility(View.INVISIBLE);

                TransitionManager.go(scene,slide);
                findViewById(R.id.anim).setVisibility(View.INVISIBLE);
                circularRevealView.setVisibility(View.INVISIBLE);
            }
        });

        findViewById(R.id.reset).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                TransitionManager.go(scene,fade);
                findViewById(R.id.anim).setVisibility(View.VISIBLE);
                circularRevealView.setVisibility(View.VISIBLE);
            }
        });
```

这里只是最简单的效果，大家可以去研究更深层次的用法。

看下效果。

![](https://github.com/Guolei1130/blog_resource/blob/master/art/md_anim/Transition.gif?raw=true)

### Shared Element-共享元素

我们可以通过ActivityOptionsCompant兼容类去创建共享元素动画，有如下几种Api

![](https://github.com/Guolei1130/blog_resource/blob/master/art/md_anim/shareelement.png?raw=true)


分别创建不同类型的元素共享动画。举个简单的例子。

```
                Bundle bundle = ActivityOptionsCompat.makeSceneTransitionAnimation(MainActivity.this,
                        crView, "cr")
                        .toBundle();
                Intent intent = new Intent(MainActivity.this, ShareEleActivity.class);
                startActivity(intent, bundle);
```

其中，"cr" 是通过 android:transitionName="cr"这个属性，来告诉系统，transitionName相同的View做过度。看下效果。

![](https://github.com/Guolei1130/blog_resource/blob/master/art/md_anim/shareelement.gif?raw=true)


共享元素动画还有很多，我这里没有在详细的说下去，大家有兴趣的自己研究下。

### 参考资料

[Transitions动画](https://github.com/hehonghui/android-tech-frontier/tree/master/others/%E6%B7%B1%E5%85%A5%E6%B5%85%E5%87%BAAndroid%20%E6%96%B0%E7%89%B9%E6%80%A7-Transition-Part-1)

[Android过度动画框架](http://einverne.github.io/post/2016/10/android-transition-framework.html)




### 最近访客
<ul class="ds-recent-visitors" data-num-items="46" data-avatar-size="40"></ul>