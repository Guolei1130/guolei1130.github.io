### 初始化流程

* application.getBaseContext() 是一个ContextImpl对象
* 获取LoadedApk,对应ContextImpl#mPackageInfo字段
* 获取classloader、resource等对象
* 获取ActivityThread对象，对应ContextImpl#mMainThread字段
* 反射ActivityThread#mInstrumetation对象，为ZeusInstrumentation
* 创建插件相关文件夹目录
	* InsidePluginPath,data/data/包名/files/plugins
	* DexCacheParentDirectPath insidePluginPath/dalvik-cache/
* 加载已安装的插件 loadInstalledPlugins
	* 首先读取 InsidePluginPath下的plugin.installedlist文件
	* 生成classloader，并将每一个插件对应的classloader加入到这个classloader里
	* 设置当前apk的classloader
	* 重新加载资源 reloadInstalledPluginResources
* 清除旧插件 clearOldPlugin()
* 安装内置插件 installInitPlugins


### 安装插件的流程

核心流程

* ClassLoader 里添加apkPath
* 重新加载资源

### Activity的启动

