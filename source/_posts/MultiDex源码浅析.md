---
title: MultiDex源码浅析
date: 2017-04-29 13:13:39
categories: Android
tags: framework

---
<Excerpt in index | 首页摘要>
### 前言

MultiDex是为了解决65536的问题，虽然说现在我们使用起来很方便了，作为一个有追求的程序员，使用并不是我们的目标，我们的目标是学习其实现原理。

<!-- more -->
<The rest of contents | 余下全文>



### MultiDex#install

```
    public static void install(Context context) {
        Log.i(TAG, "install");
        if (IS_VM_MULTIDEX_CAPABLE) {
            Log.i(TAG, "VM has multidex support, MultiDex support library is disabled.");
            return;
        }

        if (Build.VERSION.SDK_INT < MIN_SDK_VERSION) {
            throw new RuntimeException("Multi dex installation failed. SDK " + Build.VERSION.SDK_INT
                    + " is unsupported. Min SDK version is " + MIN_SDK_VERSION + ".");
        }

        try {
            ApplicationInfo applicationInfo = getApplicationInfo(context);
            if (applicationInfo == null) {
                // Looks like running on a test Context, so just return without patching.
                return;
            }

            synchronized (installedApk) {
                String apkPath = applicationInfo.sourceDir;
                if (installedApk.contains(apkPath)) {
                    return;
                }
                installedApk.add(apkPath);

                if (Build.VERSION.SDK_INT > MAX_SUPPORTED_SDK_VERSION) {
                    Log.w(TAG, "MultiDex is not guaranteed to work in SDK version "
                            + Build.VERSION.SDK_INT + ": SDK version higher than "
                            + MAX_SUPPORTED_SDK_VERSION + " should be backed by "
                            + "runtime with built-in multidex capabilty but it's not the "
                            + "case here: java.vm.version=\""
                            + System.getProperty("java.vm.version") + "\"");
                }

                /* The patched class loader is expected to be a descendant of
                 * dalvik.system.BaseDexClassLoader. We modify its
                 * dalvik.system.DexPathList pathList field to append additional DEX
                 * file entries.
                 */
                ClassLoader loader;
                try {
                    loader = context.getClassLoader();
                } catch (RuntimeException e) {
                    /* Ignore those exceptions so that we don't break tests relying on Context like
                     * a android.test.mock.MockContext or a android.content.ContextWrapper with a
                     * null base Context.
                     */
                    Log.w(TAG, "Failure while trying to obtain Context class loader. " +
                            "Must be running in test mode. Skip patching.", e);
                    return;
                }
                if (loader == null) {
                    // Note, the context class loader is null when running Robolectric tests.
                    Log.e(TAG,
                            "Context class loader is null. Must be running in test mode. "
                            + "Skip patching.");
                    return;
                }

                try {
                  clearOldDexDir(context);
                } catch (Throwable t) {
                  Log.w(TAG, "Something went wrong when trying to clear old MultiDex extraction, "
                      + "continuing without cleaning.", t);
                }

                File dexDir = new File(applicationInfo.dataDir, SECONDARY_FOLDER_NAME);
                List<File> files = MultiDexExtractor.load(context, applicationInfo, dexDir, false);
                if (checkValidZipFiles(files)) {
                    installSecondaryDexes(loader, dexDir, files);
                } else {
                    Log.w(TAG, "Files were not valid zip files.  Forcing a reload.");
                    // Try again, but this time force a reload of the zip file.
                    files = MultiDexExtractor.load(context, applicationInfo, dexDir, true);

                    if (checkValidZipFiles(files)) {
                        installSecondaryDexes(loader, dexDir, files);
                    } else {
                        // Second time didn't work, give up
                        throw new RuntimeException("Zip files were not valid.");
                    }
                }
            }

        } catch (Exception e) {
            Log.e(TAG, "Multidex installation failure", e);
            throw new RuntimeException("Multi dex installation failed (" + e.getMessage() + ").");
        }
        Log.i(TAG, "install done");
    }
```

这个方法的所有代码都在上面，代码不错，逻辑如下：

* 如果当前虚拟机已经支持MultiDex了，直接退出
* 首先获取apk文件的路径，并加到installedApk中，防止重复install
* 获取classloader，这里的这个classloader是BaseDexClassLoader,要记住，我们后面会用到。
* 清除secondary-dexes文件夹中的dex文件
* 通过MultiDexExtractor去提取dex文件，注意这时的第四个参数是false，
* 校验有效性
	* 合法installSecondaryDexes，安装
	* 不合法，再次提取，不过这次提取就是从apk文件中提取了，进行安装。这一步是一点补救措施。

接下来便对其中一些关键步骤进行分析。

### MultiDexExtractor.load 

```
    static List<File> load(Context context, ApplicationInfo applicationInfo, File dexDir,
            boolean forceReload) throws IOException {
        Log.i(TAG, "MultiDexExtractor.load(" + applicationInfo.sourceDir + ", " + forceReload + ")");
        final File sourceApk = new File(applicationInfo.sourceDir);

        long currentCrc = getZipCrc(sourceApk);

        List<File> files;
        if (!forceReload && !isModified(context, sourceApk, currentCrc)) {
            try {
                files = loadExistingExtractions(context, sourceApk, dexDir);
            } catch (IOException ioe) {
                Log.w(TAG, "Failed to reload existing extracted secondary dex files,"
                        + " falling back to fresh extraction", ioe);
                files = performExtractions(sourceApk, dexDir);
                putStoredApkInfo(context, getTimeStamp(sourceApk), currentCrc, files.size() + 1);

            }
        } else {
            Log.i(TAG, "Detected that extraction must be performed.");
            files = performExtractions(sourceApk, dexDir);
            putStoredApkInfo(context, getTimeStamp(sourceApk), currentCrc, files.size() + 1);
        }

        Log.i(TAG, "load found " + files.size() + " secondary dex files");
        return files;
    }
```

其中dexFile 路径为code_cache/secondary-dexes

在这一步是对dex文件进行提取。其中的逻辑如下，

* 获取apk文件的crc校验码
* 如果不是强行reload(强行reload是指直接从apk文件提取)，并且apk文件没有进行修改。
	* loadExistingExtractions 提取缓存
	* 如果失败，则从apk文件中提取
* 当设置了forceReload时，直接从apk文件中提取

#### 获取apk文件crc校验码

```
    private static long getZipCrc(File archive) throws IOException {
        long computedValue = ZipUtil.getZipCrc(archive);
        if (computedValue == NO_VALUE) {
            // never return NO_VALUE
            computedValue--;
        }
        return computedValue;
    }
```

在这个方法中，通过ZipUtil去获取crc校验码。我们看下他的实现，

```
    static long getZipCrc(File apk) throws IOException {
        RandomAccessFile raf = new RandomAccessFile(apk, "r");
        try {
            CentralDirectory dir = findCentralDirectory(raf);

            return computeCrcOfCentralDir(raf, dir);
        } finally {
            raf.close();
        }
    }
```

通过findCentralDirectory去返回一个CentralDirectory对象，这存储了内容的偏移量和size两个字段。关于如何计算，详细看代码和zip文件格式。[ZIP文件格式](https://pkware.cachefly.net/webdocs/APPNOTE/APPNOTE-6.2.0.txt)

CRC计算就略过了。

#### isModified

```
    private static boolean isModified(Context context, File archive, long currentCrc) {
        SharedPreferences prefs = getMultiDexPreferences(context);
        return (prefs.getLong(KEY_TIME_STAMP, NO_VALUE) != getTimeStamp(archive))
                || (prefs.getLong(KEY_CRC, NO_VALUE) != currentCrc);
    }
```

这里通过比较文件更改时间以及 crc校验码来判断apk文件是够进行过修改。如升级。

#### loadExistingExtractions 

直接加载缓存好的dex文件。

```
    private static List<File> loadExistingExtractions(Context context, File sourceApk, File dexDir)
            throws IOException {
        Log.i(TAG, "loading existing secondary dex files");

        final String extractedFilePrefix = sourceApk.getName() + EXTRACTED_NAME_EXT;
        int totalDexNumber = getMultiDexPreferences(context).getInt(KEY_DEX_NUMBER, 1);
        final List<File> files = new ArrayList<File>(totalDexNumber);

        for (int secondaryNumber = 2; secondaryNumber <= totalDexNumber; secondaryNumber++) {
            String fileName = extractedFilePrefix + secondaryNumber + EXTRACTED_SUFFIX;
            File extractedFile = new File(dexDir, fileName);
            if (extractedFile.isFile()) {
                files.add(extractedFile);
                if (!verifyZipFile(extractedFile)) {
                    Log.i(TAG, "Invalid zip file: " + extractedFile);
                    throw new IOException("Invalid ZIP file.");
                }
            } else {
                throw new IOException("Missing extracted secondary dex file '" +
                        extractedFile.getPath() + "'");
            }
        }

        return files;
    }
```

上面的代码，直接查找code_cache/secondary-dexes 目录下的dex文件。

#### performExtractions

这个方法是干嘛的呢？当我们load缓存出异常的时候，就会用apk文件中做提取，我们看下逻辑。

```
    private static List<File> performExtractions(File sourceApk, File dexDir)
            throws IOException {

        final String extractedFilePrefix = sourceApk.getName() + EXTRACTED_NAME_EXT;

        // Ensure that whatever deletions happen in prepareDexDir only happen if the zip that
        // contains a secondary dex file in there is not consistent with the latest apk.  Otherwise,
        // multi-process race conditions can cause a crash loop where one process deletes the zip
        // while another had created it.
        prepareDexDir(dexDir, extractedFilePrefix);

        List<File> files = new ArrayList<File>();

        final ZipFile apk = new ZipFile(sourceApk);
        try {

            int secondaryNumber = 2;

            ZipEntry dexFile = apk.getEntry(DEX_PREFIX + secondaryNumber + DEX_SUFFIX);
            while (dexFile != null) {
                String fileName = extractedFilePrefix + secondaryNumber + EXTRACTED_SUFFIX;
                File extractedFile = new File(dexDir, fileName);
                files.add(extractedFile);

                Log.i(TAG, "Extraction is needed for file " + extractedFile);
                int numAttempts = 0;
                boolean isExtractionSuccessful = false;
                while (numAttempts < MAX_EXTRACT_ATTEMPTS && !isExtractionSuccessful) {
                    numAttempts++;

                    // Create a zip file (extractedFile) containing only the secondary dex file
                    // (dexFile) from the apk.
                    extract(apk, dexFile, extractedFile, extractedFilePrefix);

                    // Verify that the extracted file is indeed a zip file.
                    isExtractionSuccessful = verifyZipFile(extractedFile);

                    // Log the sha1 of the extracted zip file
                    Log.i(TAG, "Extraction " + (isExtractionSuccessful ? "success" : "failed") +
                            " - length " + extractedFile.getAbsolutePath() + ": " +
                            extractedFile.length());
                    if (!isExtractionSuccessful) {
                        // Delete the extracted file
                        extractedFile.delete();
                        if (extractedFile.exists()) {
                            Log.w(TAG, "Failed to delete corrupted secondary dex '" +
                                    extractedFile.getPath() + "'");
                        }
                    }
                }
                if (!isExtractionSuccessful) {
                    throw new IOException("Could not create zip file " +
                            extractedFile.getAbsolutePath() + " for secondary dex (" +
                            secondaryNumber + ")");
                }
                secondaryNumber++;
                dexFile = apk.getEntry(DEX_PREFIX + secondaryNumber + DEX_SUFFIX);
            }
        } finally {
            try {
                apk.close();
            } catch (IOException e) {
                Log.w(TAG, "Failed to close resource", e);
            }
        }

        return files;
    }
```

代码也比较简单，提取文件嘛，相信大家都会的，这里就不啰嗦了，哈哈。


#### putStoredApkInfo

从apk文件提取完之后呢，就会将apk最后一次修改时间，crc校验码，dex文件数目等信息，存放到SharedPreferences中，以便以后调用。

### MultiDex#installSecondaryDexes

```
    private static void installSecondaryDexes(ClassLoader loader, File dexDir, List<File> files)
            throws IllegalArgumentException, IllegalAccessException, NoSuchFieldException,
            InvocationTargetException, NoSuchMethodException, IOException {
        if (!files.isEmpty()) {
            if (Build.VERSION.SDK_INT >= 19) {
                V19.install(loader, files, dexDir);
            } else if (Build.VERSION.SDK_INT >= 14) {
                V14.install(loader, files, dexDir);
            } else {
                V4.install(loader, files);
            }
        }
    }
```


 安装这里呢，我想大家都比较熟悉了，看了太多这样的代码。一V19为例。
 
 在看代码之前，我们需要了解一点小知识。在BaseDexClassLoader中，有个DexPathList类型的字段，而DexPathList中，有个Element[]，dexElements，这个就是我们的dex文件对应的，当findclass的时候，会依次去里面每个元素进行查找。多的不说了，具体去了解下类加载。
 
 
 ```
        private static void install(ClassLoader loader, List<File> additionalClassPathEntries,
                File optimizedDirectory)
                        throws IllegalArgumentException, IllegalAccessException,
                        NoSuchFieldException, InvocationTargetException, NoSuchMethodException {
            /* The patched class loader is expected to be a descendant of
             * dalvik.system.BaseDexClassLoader. We modify its
             * dalvik.system.DexPathList pathList field to append additional DEX
             * file entries.
             */
            Field pathListField = findField(loader, "pathList");
            Object dexPathList = pathListField.get(loader);
            ArrayList<IOException> suppressedExceptions = new ArrayList<IOException>();
            expandFieldArray(dexPathList, "dexElements", makeDexElements(dexPathList,
                    new ArrayList<File>(additionalClassPathEntries), optimizedDirectory,
                    suppressedExceptions));
            if (suppressedExceptions.size() > 0) {
                for (IOException e : suppressedExceptions) {
                    Log.w(TAG, "Exception in makeDexElement", e);
                }
                Field suppressedExceptionsField =
                        findField(loader, "dexElementsSuppressedExceptions");
                IOException[] dexElementsSuppressedExceptions =
                        (IOException[]) suppressedExceptionsField.get(loader);

                if (dexElementsSuppressedExceptions == null) {
                    dexElementsSuppressedExceptions =
                            suppressedExceptions.toArray(
                                    new IOException[suppressedExceptions.size()]);
                } else {
                    IOException[] combined =
                            new IOException[suppressedExceptions.size() +
                                            dexElementsSuppressedExceptions.length];
                    suppressedExceptions.toArray(combined);
                    System.arraycopy(dexElementsSuppressedExceptions, 0, combined,
                            suppressedExceptions.size(), dexElementsSuppressedExceptions.length);
                    dexElementsSuppressedExceptions = combined;
                }

                suppressedExceptionsField.set(loader, dexElementsSuppressedExceptions);
            }
        }
 ```
 
* 首先通过classloader获取到pathList，再通过DexPathList的makeDexElements方法构造一个Element[]数组，注意，不同版本的方法名和字段名可能不一样，这里以5.0位例的。
* 通过expandFieldArray方法，去扩展原先的Element数组，将除了第一个dex文件外的其他dex文件添加到里面。
* 略过。。。

大体的流程就是这样的。

### 总结

看了简单的源码之后，还有几个问题需要我们思考：

1. clearOldDexDir 目的是什么？节省空间么？
2. 其中，做了哪些异常处理，比如异常重试，这个有必要学习下，是一种保护措施
3. 都说在首次加载会出现耗时的情况，没看到相关的Dex优化的代码啊。
4. odex和dex，odex是优化过后的dex，其后缀也可以是dex，code_cache/secondary-dexes中，就是优化过后的dex存放路径。

关于第三点，是在DexFile的构造函数中，会调用native的方法，做一些优化，比如opt，或者是oat


如果错误或者理解片面的地方，请各位同学赐教。
 

 

### 最近访客
<ul class="ds-recent-visitors" data-num-items="46" data-avatar-size="40"></ul>