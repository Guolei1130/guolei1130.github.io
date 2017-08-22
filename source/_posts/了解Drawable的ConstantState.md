---
title: 了解Drawable的ConstantState
date: 2017-08-22 22:18:25
category: Android
tags: Android

---
<Excerpt in index | 首页摘要>
### 前言

在今天之前，我并不知道还有这么个机制。直到写的代码出了bug。在项目中使用了Tint对图片进行着色处理。

<!-- more -->
<The rest of contents | 余下全文>


```
Drawable drawable = ResourcesCompat.getDrawable(getResources(), R.drawable.icon, getTheme());
drawable.setBounds(0, 0, 50, 50);
drawable = DrawableCompat.wrap(drawable);
binding.img.setCompoundDrawables(drawable, null, null, null);
```

但是，所有使用icon的地方，全部被着色了。一起来探讨下。

### 从资源加载的角度入手

废话不多说，直接看代码。

```
    public Drawable getDrawable(@DrawableRes int id, @Nullable Theme theme)
            throws NotFoundException {
        final TypedValue value = obtainTempTypedValue();
        try {
            final ResourcesImpl impl = mResourcesImpl;
            impl.getValue(id, value, true);
            return impl.loadDrawable(this, value, id, theme, true);
        } finally {
            releaseTempTypedValue(value);
        }
    }
```

资源的加载详细过程这里不做过多解释，在6.0的源码中 ，通过ResurcesImpl#loadDrawable来加载图片，当第一次加载我们apk中的drawable资源的时候，因为没有对应cache的关系，会从资源文件中，解析资源，并做相应的cache操作，对应代码如下：

```
            Drawable dr;
            if (cs != null) {
                dr = cs.newDrawable(wrapper);
            } else if (isColorDrawable) {
                dr = new ColorDrawable(value.data);
            } else {
                dr = loadDrawableForCookie(wrapper, value, id, null);
            }

            // Determine if the drawable has unresolved theme attributes. If it
            // does, we'll need to apply a theme and store it in a theme-specific
            // cache.
            final boolean canApplyTheme = dr != null && dr.canApplyTheme();
            if (canApplyTheme && theme != null) {
                dr = dr.mutate();
                dr.applyTheme(theme);
                dr.clearMutated();
            }

            // If we were able to obtain a drawable, store it in the appropriate
            // cache: preload, not themed, null theme, or theme-specific. Don't
            // pollute the cache with drawables loaded from a foreign density.
            if (dr != null && useCache) {
                dr.setChangingConfigurations(value.changingConfigurations);
                cacheDrawable(value, isColorDrawable, caches, theme, canApplyTheme, key, dr);
            }
```

本文以BitmapDrawable为例，因此，加载全薪资源由loadDrawableForCookie完成，而cache操作由cacheDrawable来完成，那么，我们看下cache了哪些数据。

```
    private void cacheDrawable(TypedValue value, boolean isColorDrawable, DrawableCache caches,
            Resources.Theme theme, boolean usesTheme, long key, Drawable dr) {
        final Drawable.ConstantState cs = dr.getConstantState();
        if (cs == null) {
            return;
        }

        if (mPreloading) {
            final int changingConfigs = cs.getChangingConfigurations();
            if (isColorDrawable) {
                if (verifyPreloadConfig(changingConfigs, 0, value.resourceId, "drawable")) {
                    sPreloadedColorDrawables.put(key, cs);
                }
            } else {
                if (verifyPreloadConfig(
                        changingConfigs, LAYOUT_DIR_CONFIG, value.resourceId, "drawable")) {
                    if ((changingConfigs & LAYOUT_DIR_CONFIG) == 0) {
                        // If this resource does not vary based on layout direction,
                        // we can put it in all of the preload maps.
                        sPreloadedDrawables[0].put(key, cs);
                        sPreloadedDrawables[1].put(key, cs);
                    } else {
                        // Otherwise, only in the layout dir we loaded it for.
                        sPreloadedDrawables[mConfiguration.getLayoutDirection()].put(key, cs);
                    }
                }
            }
        } else {
            synchronized (mAccessLock) {
                caches.put(key, theme, cs, usesTheme);
            }
        }
    }
```

重点看头和尾，

* dr.getConstantState
* caches.put

这里，我们不必要去关心cache的操作，我们关系的是getConstantState,以BitmapDrawable为例，他返回他的类型为BitmapState的成员。

### 再看setTintList与getDrawable读取cache

```
    @Override
    public void setTintList(ColorStateList tint) {
        final BitmapState state = mBitmapState;
        if (state.mTint != tint) {
            state.mTint = tint;
            mTintFilter = updateTintFilter(mTintFilter, tint, mBitmapState.mTintMode);
            invalidateSelf();
        }
    }
```

BitmapDrawable的setTintList方法，将mBitmapState的mTint属性做了修改，而mBitmapState是被Resource缓存起来了的，因此，缓存中对应的部分也被修改了。

在loadDrawable的方法中，有如下代码片段。

```
final Drawable cachedDrawable = caches.getInstance(key, wrapper, theme);
```
当从cache中，获取到之后，就会直接返回。再看下getInstance。

```
    public Drawable getInstance(long key, Resources resources, Resources.Theme theme) {
        final Drawable.ConstantState entry = get(key, theme);
        if (entry != null) {
            return entry.newDrawable(resources, theme);
        }

        return null;
    }
```

还是以BitmapDrawable为例，

```
        @Override
        public Drawable newDrawable() {
            return new BitmapDrawable(this, null);
        }
```

因此，我们在先前修改了的mTint也被复制给了后续cache的Drawable，因此，他们也被着色了。

### 如何避免

想要避免这个问题，也很简单，调用Drawable#mutate方法，这个方法会返回一个新的State，我们对这个进行修改是不会作用到原先的State的.

### 总结

上述的Drawable.ConstantState，就是我们想说的ConstantState。这个的设计是为了节约内存。官方blog中也有对这个的介绍。详情见链接，需要翻墙。

[Drawable mutations](https://android-developers.googleblog.com/2009/05/drawable-mutations.html)


### 最近访客
<ul class="ds-recent-visitors" data-num-items="46" data-avatar-size="40"></ul>