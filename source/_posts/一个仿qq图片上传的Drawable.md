---
title: 一个仿qq图片上传的Drawable
date: 2018-01-22 22:37:17
tags: Android

---
<Excerpt in index | 首页摘要>
### 前言

感觉qq聊天里面，传图片的效果很赞，感觉可以用到自己的项目里，因此，也写了一个这个效果，实现方式非常简单。就是一个Drawable。

<!-- more -->
<The rest of contents | 余下全文>


### ProgressDrawable

```
package com.guolei.customviews;

//                    _    _   _ _
//__      _____  _ __| | _| |_(_) | ___
//\ \ /\ / / _ \| '__| |/ / __| | |/ _ \
// \ V  V / (_) | |  |   <| |_| | |  __/
//  \_/\_/ \___/|_|  |_|\_\\__|_|_|\___|


import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.ColorFilter;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.PixelFormat;
import android.graphics.PorterDuff;
import android.graphics.PorterDuffXfermode;
import android.graphics.Rect;
import android.graphics.RectF;
import android.graphics.drawable.Drawable;
import android.support.annotation.NonNull;
import android.support.annotation.Nullable;
import android.util.Log;

/**
 * Copyright © 2013-2017 Worktile. All Rights Reserved.
 * Author: guolei
 * Email: 1120832563@qq.com
 * Date: 18/1/17
 * Time: 下午2:17
 * Desc:
 */
public class ProgressDrawable extends Drawable {


    private float progress;

    private Paint mPaint;
    private Paint mTextPaint;
    private Path path = new Path();
    private RectF rectF = new RectF(0, 0, 0, 0);

    private int mBaseline = 0;

    public ProgressDrawable() {
        mPaint = new Paint();
        mPaint.setAntiAlias(true);
        mPaint.setDither(true);
        mPaint.setColor(Color.parseColor("#99000000"));

        mTextPaint = new Paint(mPaint);
        mTextPaint.setColor(Color.WHITE);
        mTextPaint.setTextSize(40);
    }

    public float getProgress() {
        return progress;
    }

    public void setProgress(float progress) {
        this.progress = progress;
        invalidateSelf();
    }

    @Override
    public void draw(@NonNull Canvas canvas) {
        path.reset();
        path.addRect(rectF, Path.Direction.CCW);
        int radius = (int) (progress * ((rectF.right) / 2 * 1.414 - 100)) + 100;
        path.addCircle(rectF.right / 2, rectF.right / 2, radius > 100 ? radius : 100 , Path.Direction.CW);
        canvas.drawPath(path, mPaint);
        canvas.drawCircle(rectF.right / 2, rectF.right / 2, 80, mPaint);
        String s = String.valueOf(progress * 100).substring(0,2) + "%";
        s = s.replace(".","");
        int width = (int) mTextPaint.measureText(s);
        canvas.drawText(s, rectF.right / 2 - (width / 2), mBaseline, mTextPaint);
    }

    @Override
    public void setAlpha(int i) {

    }

    @Override
    public void setColorFilter(@Nullable ColorFilter colorFilter) {

    }

    @Override
    public int getOpacity() {
        return PixelFormat.TRANSLUCENT;
    }

    @Override
    protected void onBoundsChange(Rect bounds) {
        rectF.set(0, 0, bounds.right, bounds.bottom);
        computeBaseline();
    }

    private void computeBaseline() {
        mBaseline = (int) (rectF.height() / 2 + (Math.abs(mTextPaint.ascent()) - mTextPaint.descent()) / 2);
    }
}

```

代码很简单，根据进度去绘制，分为3个部分。

* 外圈 由path合成
* 内圈 Circle
* 字 

### 最近访客
<ul class="ds-recent-visitors" data-num-items="46" data-avatar-size="40"></ul>