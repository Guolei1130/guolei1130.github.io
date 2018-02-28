---
title: Android
date: 2018-01-18 20:29:36
tags: Android

---
<Excerpt in index | 首页摘要>

### 前言

很久没写博客了，也感觉有很长时间没学习了。正好今天遇见两个适配问题，记录一下。

<!-- more -->
<The rest of contents | 余下全文>



### Android O 应用内安装问题

在8.0版本的手机上，应用内下载安装的时候，后闪一下，然后退回到应用。这是因为，我们缺少一个权限，看一下官方文档的说明。[链接地址](https://developer.android.google.cn/reference/android/Manifest.permission.html#REQUEST_INSTALL_PACKAGES)


![](http://7xsy89.com1.z0.glb.clouddn.com/QQ20180118-202532@2x.png)

可以看到，这里说明了，大于25版本，要注册这个权限。


### Android 0通知栏适配问题

在8.0版本，我们必须要设置ChannelId，否则，显示不出来通知。demo如下。

```
        final NotificationManager manager = (NotificationManager) getSystemService(NOTIFICATION_SERVICE);
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            NotificationChannel chan = new NotificationChannel(getPackageName(),"demo", NotificationManager.IMPORTANCE_HIGH);
            manager.createNotificationChannel(chan);
        }
        findViewById(R.id.button).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                Notification notification = new NotificationCompat.Builder(MainActivity.this)
                        .setContentTitle("111")
                        .setContentText("222")
                        .setSmallIcon(R.drawable.ic_launcher_background)
                        .setChannelId(getPackageName())
                        .setLargeIcon(BitmapFactory.decodeResource(getResources(),R.drawable.ic_launcher_background))
                        .build();
                manager.notify(111,notification);
            }
        });
```
### 最近访客
<ul class="ds-recent-visitors" data-num-items="46" data-avatar-size="40"></ul>