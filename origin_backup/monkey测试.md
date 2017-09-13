adb shell monkey -p packageName -v 次数  多少事件
adb shell monkey -p packageName -s seed 按照某次seed在此执行monkey
adb shell monkey -f 脚本


events:

* -s seed
* --throttle <milliseconds> 设置输入事件的时间间隔
* --pct-touch <percent> 设置touch event的百分比
* --pct-motion <percent>  设置收拾的百分比
* --pct-trackball <percent> 设置轨迹球的百分比
* --pct-nav <percent> 
* --pct-majornav <percent> 
* --pct-syskeys <percent>
* --pct-appswotch <percent>
* --pct-anyevent <percent>

constranints 

* -p 设置特别的package
* -c <main-category> 


Debugging 

* --dbg-no-events 不生成事件
* --hprof 在monkey前后，会输出内存信息
* --ignore-crashes 遇到crash也不会退出monkey
* --ignore-timeouts 遇到timeouts也不会退出monkey
* --ignore-security-exceptions 忽略permission error
* --kill-process-after-error 发生错误的时候，kill掉process
* --monitor-native-crashes 监控native crash
* --wait-dbg debug attach到的时候,wait


### MonkeyRunner

[啦啦啦](https://segmentfault.com/a/1190000008429796)

[源码](https://android.googlesource.com/platform/tools/swt/+/d9880c7c4d4c12d94d2059453361f1c3691a901d/monkeyrunner/src)

##### MonkeyDevice

* getHierarchyViewer()
* takeSnapShot()
* getProperty()
* getSystemProperty()
* touch() ,参数，x，y，事件类型
* drag() start,end,duration,stemps 开始，终止，时间，步数
* press（） name，type
* type(),message 输送message到键盘
* shell(),cmd,timeout
* reboot() into 
* installPackage()，path参数
* removePackag() package name
* startActivity() uri actin data mimetype categories 等等，
* broadcastIntent() 参数同上
* instrument() 参数，classname，args
* getPropertyList()
* getViewIdList()
* getViewById() 
* getViewByAccessibilityIds()
* getRootView()
* getViewsByText()