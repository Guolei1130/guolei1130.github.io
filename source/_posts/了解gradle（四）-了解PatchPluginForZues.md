---
title: 了解gradle（四）-了解PatchPluginForZues
date: 2017-03-25 22:11:48

categories: Gradle
tags: gradle

---

### 前言

前面也有介绍一些gradle的简单知识，但是这还不够，我们要想编写一些gradle插件，还是需要一些技巧，今天接着学习gradle。内容来自于官方文档。
<Excerpt in index | 首页摘要>



<!-- more -->
<The rest of contents | 余下全文>
### 前言

我们平时工作中会用到各种各样的gradle插件，但是你是否想过，这些插件是如何编写出来的。那么，今天，就来解析其中一个插件。叫做PatchPluginForZeus。这个是用来像class文件中注入一些代码，来解决qq空间的补丁方案中CLASS_ISPREVERIFIED的问题，关于qq空间的热补丁方案，大家自行google。下面就来学习下这个插件是如何编写的。

### 代码分析

首先看下apply方法

```
    public static final String EXTENSION_NAME = "patchPlugin";

    @Override
    public void apply(Project project) {
        DefaultDomainObjectSet<ApplicationVariant> variants
        if (project.getPlugins().hasPlugin(AppPlugin)) {
            variants = project.android.applicationVariants;

            project.extensions.create(EXTENSION_NAME, PatchExtension);

            applyTask(project, variants);
        }
    }
```

上面的代码很简单，逻辑如下：

* 检查project的插件中是否包含本插件
* 创建extension扩展
* apptask应用插件

下面代码就比较长了，分开来看。

```
            PatchExtension patchConfig = PatchExtension.getConfig(project);
            def includePackage = patchConfig.includePackage
            def excludeClass = patchConfig.excludeClass
            def excludePackage = patchConfig.excludePackage
            def excludeJar = patchConfig.excludeJar
```

首先，从扩展中获取本插件相关的配置，就是在build.gradle中的配置节点。

```
if (patchConfig.enable) {

                variants.all { variant ->
                    def dexTask = project.tasks.findByName(PatchUtils.getDexTaskName(project, variant))
                    def processManifestTask = project.tasks.findByName(PatchUtils.getProcessManifestTaskName(project, variant))

                    def manifestFile = processManifestTask.outputs.files.files[0]
                    Closure prepareClosure = {
                        patchConfig.excludePackage.add("android" + File.separator + "support")
                        def applicationClassName = PatchUtils.getApplication(manifestFile);
                        if (applicationClassName != null) {
                            applicationClassName = applicationClassName.replace(".", File.separator) + SdkConstants.DOT_CLASS
                            //过滤Application类
                            patchConfig.excludeClass.add(applicationClassName)
                        }
                    }
                    DebugUtils.debug("-------------------dexTask:" + dexTask)
                    if (dexTask != null) {
                        def patchJarBeforeDex = "patchJarBeforeDex${variant.name.capitalize()}"
                        project.task(patchJarBeforeDex) << {
                            Set<File> inputFiles = PatchUtils.getDexTaskInputFiles(project, variant, dexTask)

                            inputFiles.each { inputFile ->

                                def path = inputFile.absolutePath
                                DebugUtils.debug("patchJarBefore----->" + path)
                                if (path.endsWith(SdkConstants.DOT_JAR) && !PatchSetUtils.isExcludedJar(path, excludeJar)) {
                                    PatchProcessor.processJar(inputFile, includePackage, excludePackage, excludeClass)
                                } else if (inputFile.isDirectory()) {
                                    //intermediates/classes/debug
                                    def extensions = [SdkConstants.EXT_CLASS] as String[]

                                    def inputClasses = FileUtils.listFiles(inputFile, extensions, true);
                                    DebugUtils.debug("inputFile.isDirectory()----" + inputClasses)
                                    inputClasses.each {
                                        inputClassFile ->
                                            def classPath = inputClassFile.absolutePath
                                            if (classPath.endsWith(".class") && !classPath.contains(File.separator + "R\$") && !classPath.endsWith(File.separator + "R.class") && !classPath.endsWith(File.separator + "BuildConfig.class")) {
                                                PatchProcessor.processClass(inputClassFile)
                                            }
                                    }
                                }
                            }
                        }
                        def patchJarBeforeDexTask = project.tasks[patchJarBeforeDex]
                        DebugUtils.debug("-------------------patchJarBeforeDexTask:" + patchJarBeforeDexTask)

                        patchJarBeforeDexTask.dependsOn dexTask.taskDependencies.getDependencies(dexTask)
                        dexTask.dependsOn patchJarBeforeDexTask
                        patchJarBeforeDexTask.doFirst(prepareClosure)
                    }
                }
            }
```

判断是够允许开启插件的asm注入功能。如果开启的话，就会进行接下来的处理。

* 首先获取到processManifestTask这个task，并从这个task的输出文件中拿到AndroidManifest.xml文件，并通过解析xml文件，拿到我们应用的Application，这个class是不需要注入代码的。
* 接着，创建一个task，这个task就是来执行我们的asm代码注入任务的。到这里，我们就需要寻找合适的切入点。想一下，我们什么时候作为写入点合适呢，当然是在生成dex文件之前，这个时候作为切入点，即不会class的编译过程，也不会破坏dex的生成过程，我们做的，就是拿到生成dex文件这个task的输入文件即可。这里需要判断是不是用了transformapi。具体的不说了，大家有兴趣的看下代码。
* 然后，拿到文件之后，我们对其进行asm注入代码的操作，这个过程要区分单个的class文件还是jar包。显然，他俩的注入过程是不一样的。
* 做下依赖，让我们诸如代码的task在dex生成的这个task之前

### ASM代码注入？

这是一项高端的技术，这里暂且不细说,我也没研究明白，不过在技术栈规划当中了。

留个坑位，待补。

### 总结

有没有发现，java写多了，写gradle插件的时候，会不自觉的加;呢？看看你是不是中枪了。要是中枪，赶紧写两行python压压惊吧，毕竟听说python都冲到语言榜第三了呢。





### 最近访客
<ul class="ds-recent-visitors" data-num-items="46" data-avatar-size="40"></ul>



