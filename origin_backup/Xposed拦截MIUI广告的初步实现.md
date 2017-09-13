基于Xposed拦截MIUI广告的实现

### 了解Xposed

xposed是什么？xposed能干什么

xposed的地址


### 如何拦截广告

首先要知道广告怎么来的。

adb shell ps | grep 'Ad'

cd data/data/包名

找到 base.apk 


adb pull

jadx-gui反编译

charles抓包

jadx-gui查找字符串

找到相应的api接口

xposed进行hook，替换掉这个字段
