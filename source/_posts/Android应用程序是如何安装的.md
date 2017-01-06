---
title: Android应用程序是如何安装的
date: 2017-01-04 20:24:27
categories: Android
tags: framework

---
<Excerpt in index | 首页摘要>
### 1.前言

当我们安装应用程序的时候，会弹出安装界面，那么，在我们点击安装之后，发生了什么呢？今天就来了解下，应用程序是如何安装的。首先，我们今天介绍的是通过安装器安装应用，当然，在pms的构造函数中，也会将我们原先安装好的应用装载到内存中。

+ <!-- more -->
<The rest of contents | 余下全文>



以6.0源码为例。安装器在源码目录packages/apps/PackageInstaller中，

### 2.安装器

显示安装 取消按钮的那个界面对应着PackageInstallerActivity，而安装按钮对应的是mOk，对应部分代码。

```
        if (v == mOk) {
            if (mOkCanInstall || mScrollView == null) {
                mInstallFlowAnalytics.setInstallButtonClicked();
                if (mSessionId != -1) {
                    mInstaller.setPermissionsResult(mSessionId, true);

                    // We're only confirming permissions, so we don't really know how the
                    // story ends; assume success.
                    mInstallFlowAnalytics.setFlowFinishedWithPackageManagerResult(
                            PackageManager.INSTALL_SUCCEEDED);
                    finish();
                } else {
                    startInstall();
                }
            } else {
                mScrollView.pageScroll(View.FOCUS_DOWN);
            }
        }
```

虽然，我不知懂这里的mSessionId是什么含义，但是 根据代码能看出，安装一个应用应该是startInstall方法。在这个方法中，最终会去玩InstallAppProgress这个界面，对应我们安装中进度条显示的界面。有如下代码。

```
        if ("package".equals(mPackageURI.getScheme())) {
            try {
                pm.installExistingPackage(mAppInfo.packageName);
                observer.packageInstalled(mAppInfo.packageName,
                        PackageManager.INSTALL_SUCCEEDED);
            } catch (PackageManager.NameNotFoundException e) {
                observer.packageInstalled(mAppInfo.packageName,
                        PackageManager.INSTALL_FAILED_INVALID_APK);
            }
        } else {
            pm.installPackageWithVerificationAndEncryption(mPackageURI, observer, installFlags,
                    installerPackageName, verificationParams, null);
        }
```

* mPackageURI，安装应用的话，应该是file
* pm 为ApplicationPackageManager

因此，我们看installPackageWithVerificationAndEncryption方法。

### 3.ApplicationPackageManager#installPackageWithVerificationAndEncryption


在这个方法中，会调用installCommon方法，而installCommon方法中，会进行简单的参数校验，然后调用mPM的installPackage方法去安装。这个mPM参数实在构造的时候传入的。是通过ActivityThread.getPackageManager()获取。

```
    public static IPackageManager getPackageManager() {
        if (sPackageManager != null) {
            //Slog.v("PackageManager", "returning cur default = " + sPackageManager);
            return sPackageManager;
        }
        IBinder b = ServiceManager.getService("package");
        //Slog.v("PackageManager", "default service binder = " + b);
        sPackageManager = IPackageManager.Stub.asInterface(b);
        //Slog.v("PackageManager", "default service = " + sPackageManager);
        return sPackageManager;
    }
```

从中可以看出，其binder服务端为PackageManagerService.

### 4.PackageManagerService#installPackage

在这个方法中，回调用installPackageAsUser方法。在这个方法中，会发送一个消息，执行安装过程的第一个阶段，copy

```
        final Message msg = mHandler.obtainMessage(INIT_COPY);
        msg.obj = new InstallParams(origin, null, observer, installFlags, installerPackageName,
                null, verificationParams, user, packageAbiOverride, null);
        mHandler.sendMessage(msg);
```

这里的mHandler为PackageHandler实例对象，其消息处理部分代码在doHandleMessage中，我们看INIT_COPY，做了什么？

```
                case INIT_COPY: {
                    HandlerParams params = (HandlerParams) msg.obj;
                    int idx = mPendingInstalls.size();
                    if (DEBUG_INSTALL) Slog.i(TAG, "init_copy idx=" + idx + ": " + params);
                    // If a bind was already initiated we dont really
                    // need to do anything. The pending install
                    // will be processed later on.
                    if (!mBound) {
                        // If this is the only one pending we might
                        // have to bind to the service again.
                        if (!connectToService()) {
                            Slog.e(TAG, "Failed to bind to media container service");
                            params.serviceError();
                            return;
                        } else {
                            // Once we bind to the service, the first
                            // pending request will be processed.
                            mPendingInstalls.add(idx, params);
                        }
                    } else {
                        mPendingInstalls.add(idx, params);
                        // Already bound to the service. Just make
                        // sure we trigger off processing the first request.
                        if (idx == 0) {
                            mHandler.sendEmptyMessage(MCS_BOUND);
                        }
                    }
                    break;
                }
```

如果没有绑定，就绑定，如果绑定了，将HandlerParams加入到mPendingInstalls中，并且如果以前为空，则发送MCS_BOUND这个空消息。
在接受到MCS_BOUND这个消息之后，会循环处理并且再次发送MCS_BOUND消息，

```
                    if (DEBUG_INSTALL) Slog.i(TAG, "mcs_bound");
                    if (msg.obj != null) {
                        mContainerService = (IMediaContainerService) msg.obj;
                    }
                    if (mContainerService == null) {
                        if (!mBound) {
                            // Something seriously wrong since we are not bound and we are not
                            // waiting for connection. Bail out.
                            Slog.e(TAG, "Cannot bind to media container service");
                            for (HandlerParams params : mPendingInstalls) {
                                // Indicate service bind error
                                params.serviceError();
                            }
                            mPendingInstalls.clear();
                        } else {
                            Slog.w(TAG, "Waiting to connect to media container service");
                        }
                    } else if (mPendingInstalls.size() > 0) {
                        HandlerParams params = mPendingInstalls.get(0);
                        if (params != null) {
                            if (params.startCopy()) {
                                // We are done...  look for more work or to
                                // go idle.
                                if (DEBUG_SD_INSTALL) Log.i(TAG,
                                        "Checking for more work or unbind...");
                                // Delete pending install
                                if (mPendingInstalls.size() > 0) {
                                    mPendingInstalls.remove(0);
                                }
                                if (mPendingInstalls.size() == 0) {
                                    if (mBound) {
                                        if (DEBUG_SD_INSTALL) Log.i(TAG,
                                                "Posting delayed MCS_UNBIND");
                                        removeMessages(MCS_UNBIND);
                                        Message ubmsg = obtainMessage(MCS_UNBIND);
                                        // Unbind after a little delay, to avoid
                                        // continual thrashing.
                                        sendMessageDelayed(ubmsg, 10000);
                                    }
                                } else {
                                    // There are more pending requests in queue.
                                    // Just post MCS_BOUND message to trigger processing
                                    // of next pending install.
                                    if (DEBUG_SD_INSTALL) Log.i(TAG,
                                            "Posting MCS_BOUND for next work");
                                    mHandler.sendEmptyMessage(MCS_BOUND);
                                }
                            }
                        }
                    } else {
                        // Should never happen ideally.
                        Slog.w(TAG, "Empty queue");
                    }
                    break;
```

从上诉代码中，我们就能知道，通过params.startCopy()去执行copy操作，并且如果还有未安装的，会重复发这个消息，知道所有都安装成功。

### 5.HandlerParams#startCopy

```
        final boolean startCopy() {
            boolean res;
            try {
                if (DEBUG_INSTALL) Slog.i(TAG, "startCopy " + mUser + ": " + this);

                if (++mRetries > MAX_RETRIES) {
                    Slog.w(TAG, "Failed to invoke remote methods on default container service. Giving up");
                    mHandler.sendEmptyMessage(MCS_GIVE_UP);
                    handleServiceError();
                    return false;
                } else {
                    handleStartCopy();
                    res = true;
                }
            } catch (RemoteException e) {
                if (DEBUG_INSTALL) Slog.i(TAG, "Posting install MCS_RECONNECT");
                mHandler.sendEmptyMessage(MCS_RECONNECT);
                res = false;
            }
            handleReturnCode();
            return res;
        }
```

这里有重试机制。而handleStartCopy的实现在InstallParams中。

### 6.InstallParams#handleStartCopy

这个方法比较长，分段来看。

```
                    final StorageManager storage = StorageManager.from(mContext);
                    final long lowThreshold = storage.getStorageLowBytes(
                            Environment.getDataDirectory());

                    final long sizeBytes = mContainerService.calculateInstalledSize(
                            origin.resolvedPath, isForwardLocked(), packageAbiOverride);

                    if (mInstaller.freeCache(null, sizeBytes + lowThreshold) >= 0) {
                        pkgLite = mContainerService.getMinimalPackageInfo(origin.resolvedPath,
                                installFlags, packageAbiOverride);
                    }
```

首先，如果需要的空间不够大，就调用Install的freeCache去释放一部分缓存。

这里的mContainerService对应的binder服务端实现，在DefaultContainerService中。

中间经过复杂的判断处理之后，创建一个InstallArgs对象，如果前面的判断结果是能安装成功的话，进入分支。

```
if (ret == PackageManager.INSTALL_SUCCEEDED) {
                 /*
                 * ADB installs appear as UserHandle.USER_ALL, and can only be performed by
                 * UserHandle.USER_OWNER, so use the package verifier for UserHandle.USER_OWNER.
                 */
                int userIdentifier = getUser().getIdentifier();
                if (userIdentifier == UserHandle.USER_ALL
                        && ((installFlags & PackageManager.INSTALL_FROM_ADB) != 0)) {
                    userIdentifier = UserHandle.USER_OWNER;
                }

                /*
                 * Determine if we have any installed package verifiers. If we
                 * do, then we'll defer to them to verify the packages.
                 */
                final int requiredUid = mRequiredVerifierPackage == null ? -1
                        : getPackageUid(mRequiredVerifierPackage, userIdentifier);
                if (!origin.existing && requiredUid != -1
                        && isVerificationEnabled(userIdentifier, installFlags)) {
                    final Intent verification = new Intent(
                            Intent.ACTION_PACKAGE_NEEDS_VERIFICATION);
                    verification.addFlags(Intent.FLAG_RECEIVER_FOREGROUND);
                    verification.setDataAndType(Uri.fromFile(new File(origin.resolvedPath)),
                            PACKAGE_MIME_TYPE);
                    verification.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);

                    final List<ResolveInfo> receivers = queryIntentReceivers(verification,
                            PACKAGE_MIME_TYPE, PackageManager.GET_DISABLED_COMPONENTS,
                            0 /* TODO: Which userId? */);

                    if (DEBUG_VERIFY) {
                        Slog.d(TAG, "Found " + receivers.size() + " verifiers for intent "
                                + verification.toString() + " with " + pkgLite.verifiers.length
                                + " optional verifiers");
                    }

                    final int verificationId = mPendingVerificationToken++;

                    verification.putExtra(PackageManager.EXTRA_VERIFICATION_ID, verificationId);

                    verification.putExtra(PackageManager.EXTRA_VERIFICATION_INSTALLER_PACKAGE,
                            installerPackageName);

                    verification.putExtra(PackageManager.EXTRA_VERIFICATION_INSTALL_FLAGS,
                            installFlags);

                    verification.putExtra(PackageManager.EXTRA_VERIFICATION_PACKAGE_NAME,
                            pkgLite.packageName);

                    verification.putExtra(PackageManager.EXTRA_VERIFICATION_VERSION_CODE,
                            pkgLite.versionCode);

                    if (verificationParams != null) {
                        if (verificationParams.getVerificationURI() != null) {
                           verification.putExtra(PackageManager.EXTRA_VERIFICATION_URI,
                                 verificationParams.getVerificationURI());
                        }
                        if (verificationParams.getOriginatingURI() != null) {
                            verification.putExtra(Intent.EXTRA_ORIGINATING_URI,
                                  verificationParams.getOriginatingURI());
                        }
                        if (verificationParams.getReferrer() != null) {
                            verification.putExtra(Intent.EXTRA_REFERRER,
                                  verificationParams.getReferrer());
                        }
                        if (verificationParams.getOriginatingUid() >= 0) {
                            verification.putExtra(Intent.EXTRA_ORIGINATING_UID,
                                  verificationParams.getOriginatingUid());
                        }
                        if (verificationParams.getInstallerUid() >= 0) {
                            verification.putExtra(PackageManager.EXTRA_VERIFICATION_INSTALLER_UID,
                                  verificationParams.getInstallerUid());
                        }
                    }

                    final PackageVerificationState verificationState = new PackageVerificationState(
                            requiredUid, args);

                    mPendingVerification.append(verificationId, verificationState);

                    final List<ComponentName> sufficientVerifiers = matchVerifiers(pkgLite,
                            receivers, verificationState);

                    // Apps installed for "all" users use the device owner to verify the app
                    UserHandle verifierUser = getUser();
                    if (verifierUser == UserHandle.ALL) {
                        verifierUser = UserHandle.OWNER;
                    }

                    /*
                     * If any sufficient verifiers were listed in the package
                     * manifest, attempt to ask them.
                     */
                    if (sufficientVerifiers != null) {
                        final int N = sufficientVerifiers.size();
                        if (N == 0) {
                            Slog.i(TAG, "Additional verifiers required, but none installed.");
                            ret = PackageManager.INSTALL_FAILED_VERIFICATION_FAILURE;
                        } else {
                            for (int i = 0; i < N; i++) {
                                final ComponentName verifierComponent = sufficientVerifiers.get(i);

                                final Intent sufficientIntent = new Intent(verification);
                                sufficientIntent.setComponent(verifierComponent);
                                mContext.sendBroadcastAsUser(sufficientIntent, verifierUser);
                            }
                        }
                    }

                    final ComponentName requiredVerifierComponent = matchComponentForVerifier(
                            mRequiredVerifierPackage, receivers);
                    if (ret == PackageManager.INSTALL_SUCCEEDED
                            && mRequiredVerifierPackage != null) {
                        /*
                         * Send the intent to the required verification agent,
                         * but only start the verification timeout after the
                         * target BroadcastReceivers have run.
                         */
                        verification.setComponent(requiredVerifierComponent);
                        mContext.sendOrderedBroadcastAsUser(verification, verifierUser,
                                android.Manifest.permission.PACKAGE_VERIFICATION_AGENT,
                                new BroadcastReceiver() {
                                    @Override
                                    public void onReceive(Context context, Intent intent) {
                                        final Message msg = mHandler
                                                .obtainMessage(CHECK_PENDING_VERIFICATION);
                                        msg.arg1 = verificationId;
                                        mHandler.sendMessageDelayed(msg, getVerificationTimeout());
                                    }
                                }, null, 0, null, null);

                        /*
                         * We don't want the copy to proceed until verification
                         * succeeds, so null out this field.
                         */
                        mArgs = null;
                    }
                } else {
                    /*
                     * No package verification is enabled, so immediately start
                     * the remote call to initiate copy using temporary file.
                     */
                    ret = args.copyApk(mContainerService, true);
                }
            }

```

* 如果启动了包验证的话，就会进入验证阶段。 
	* 发送有序广播， 
* 否则，直接进行复制操作

验证部分的逻辑很长，大部分代码都是对intent进行设置。

### 7.InstallArgs#copyApk

在createInstallArgs中，会根据InstallParams创建不同的InstallArgs对象。

```
    private InstallArgs createInstallArgs(InstallParams params) {
        if (params.move != null) {
            return new MoveInstallArgs(params);
        } else if (installOnExternalAsec(params.installFlags) || params.isForwardLocked()) {
            return new AsecInstallArgs(params);
        } else {
            return new FileInstallArgs(params);
        }
    }
```

以FileInstallArgs为例，我们来看看。

```

       int copyApk(IMediaContainerService imcs, boolean temp) throws RemoteException {
            if (origin.staged) {
                if (DEBUG_INSTALL) Slog.d(TAG, origin.file + " already staged; skipping copy");
                codeFile = origin.file;
                resourceFile = origin.file;
                return PackageManager.INSTALL_SUCCEEDED;
            }

            try {
                final File tempDir = mInstallerService.allocateStageDirLegacy(volumeUuid);
                codeFile = tempDir;
                resourceFile = tempDir;
            } catch (IOException e) {
                Slog.w(TAG, "Failed to create copy file: " + e);
                return PackageManager.INSTALL_FAILED_INSUFFICIENT_STORAGE;
            }

            final IParcelFileDescriptorFactory target = new IParcelFileDescriptorFactory.Stub() {
                @Override
                public ParcelFileDescriptor open(String name, int mode) throws RemoteException {
                    if (!FileUtils.isValidExtFilename(name)) {
                        throw new IllegalArgumentException("Invalid filename: " + name);
                    }
                    try {
                        final File file = new File(codeFile, name);
                        final FileDescriptor fd = Os.open(file.getAbsolutePath(),
                                O_RDWR | O_CREAT, 0644);
                        Os.chmod(file.getAbsolutePath(), 0644);
                        return new ParcelFileDescriptor(fd);
                    } catch (ErrnoException e) {
                        throw new RemoteException("Failed to open: " + e.getMessage());
                    }
                }
            };

            int ret = PackageManager.INSTALL_SUCCEEDED;
            ret = imcs.copyPackage(origin.file.getAbsolutePath(), target);
            if (ret != PackageManager.INSTALL_SUCCEEDED) {
                Slog.e(TAG, "Failed to copy package");
                return ret;
            }

            final File libraryRoot = new File(codeFile, LIB_DIR_NAME);
            NativeLibraryHelper.Handle handle = null;
            try {
                handle = NativeLibraryHelper.Handle.create(codeFile);
                ret = NativeLibraryHelper.copyNativeBinariesWithOverride(handle, libraryRoot,
                        abiOverride);
            } catch (IOException e) {
                Slog.e(TAG, "Copying native libraries failed", e);
                ret = PackageManager.INSTALL_FAILED_INTERNAL_ERROR;
            } finally {
                IoUtils.closeQuietly(handle);
            }

            return ret;
        }

```

* 首先mInstallerService.allocateStageDirLegacy申请足够的存储空间
* 得到申请的那部分空间的文件描述符，并且修改权限
* IMediaContainerService#copyPackage 拷贝到指定目录，实现在DefaultContainerService中，
* NativeLibraryHelper#copyNativeBinariesWithOverride 拷贝二进制文件(so库)

### 8.DefaultContainerService#copyPackage

```
        public int copyPackage(String packagePath, IParcelFileDescriptorFactory target) {
            if (packagePath == null || target == null) {
                return PackageManager.INSTALL_FAILED_INVALID_URI;
            }

            PackageLite pkg = null;
            try {
                final File packageFile = new File(packagePath);
                pkg = PackageParser.parsePackageLite(packageFile, 0);
                return copyPackageInner(pkg, target);
            } catch (PackageParserException | IOException | RemoteException e) {
                Slog.w(TAG, "Failed to copy package at " + packagePath + ": " + e);
                return PackageManager.INSTALL_FAILED_INSUFFICIENT_STORAGE;
            }
        }
```

* 解析apk文件
* 将文件拷贝到指定目录

### 9.NativeLibraryHelper#copyNativeBinariesWithOverride

在这个方法中，将不同的so库通过copyNativeBinariesForSupportedAbi方法copy到不同的目录。copy的具体流程就不说了。

到现在，copy的流程就完了。

在上面startCopy中，下面有handleReturnCode，是对copy后进行后续处理的，我们依然看，InstallParams的这个方法。

### 10.InstallParams#handleReturnCode

在这个方法中，会调用processPendingInstall去处理。

```
    private void processPendingInstall(final InstallArgs args, final int currentStatus) {
        // Queue up an async operation since the package installation may take a little while.
        mHandler.post(new Runnable() {
            public void run() {
                mHandler.removeCallbacks(this);
                 // Result object to be returned
                PackageInstalledInfo res = new PackageInstalledInfo();
                res.returnCode = currentStatus;
                res.uid = -1;
                res.pkg = null;
                res.removedInfo = new PackageRemovedInfo();
                if (res.returnCode == PackageManager.INSTALL_SUCCEEDED) {
                    args.doPreInstall(res.returnCode);
                    synchronized (mInstallLock) {
                        installPackageLI(args, res);
                    }
                    args.doPostInstall(res.returnCode, res.uid);
                }

                // A restore should be performed at this point if (a) the install
                // succeeded, (b) the operation is not an update, and (c) the new
                // package has not opted out of backup participation.
                final boolean update = res.removedInfo.removedPackage != null;
                final int flags = (res.pkg == null) ? 0 : res.pkg.applicationInfo.flags;
                boolean doRestore = !update
                        && ((flags & ApplicationInfo.FLAG_ALLOW_BACKUP) != 0);

                // Set up the post-install work request bookkeeping.  This will be used
                // and cleaned up by the post-install event handling regardless of whether
                // there's a restore pass performed.  Token values are >= 1.
                int token;
                if (mNextInstallToken < 0) mNextInstallToken = 1;
                token = mNextInstallToken++;

                PostInstallData data = new PostInstallData(args, res);
                mRunningInstalls.put(token, data);
                if (DEBUG_INSTALL) Log.v(TAG, "+ starting restore round-trip " + token);

                if (res.returnCode == PackageManager.INSTALL_SUCCEEDED && doRestore) {
                    // Pass responsibility to the Backup Manager.  It will perform a
                    // restore if appropriate, then pass responsibility back to the
                    // Package Manager to run the post-install observer callbacks
                    // and broadcasts.
                    IBackupManager bm = IBackupManager.Stub.asInterface(
                            ServiceManager.getService(Context.BACKUP_SERVICE));
                    if (bm != null) {
                        if (DEBUG_INSTALL) Log.v(TAG, "token " + token
                                + " to BM for possible restore");
                        try {
                            if (bm.isBackupServiceActive(UserHandle.USER_OWNER)) {
                                bm.restoreAtInstall(res.pkg.applicationInfo.packageName, token);
                            } else {
                                doRestore = false;
                            }
                        } catch (RemoteException e) {
                            // can't happen; the backup manager is local
                        } catch (Exception e) {
                            Slog.e(TAG, "Exception trying to enqueue restore", e);
                            doRestore = false;
                        }
                    } else {
                        Slog.e(TAG, "Backup Manager not found!");
                        doRestore = false;
                    }
                }

                if (!doRestore) {
                    // No restore possible, or the Backup Manager was mysteriously not
                    // available -- just fire the post-install work request directly.
                    if (DEBUG_INSTALL) Log.v(TAG, "No restore - queue post-install for " + token);
                    Message msg = mHandler.obtainMessage(POST_INSTALL, token, 0);
                    mHandler.sendMessage(msg);
                }
            }
        });
    }
```

安装过程

* installPackageLI，在这个之前，会用doPreInstall进行cleanup操作，在这之后会用doPostInstall进行clean操作。
* 恢复部分代码 没看明白。😭
* 发送POST_INSTALL消息

### 11.installPackageLI

改方法氛围几部分。

首先是解析包过程。

```
        PackageParser pp = new PackageParser();
        pp.setSeparateProcesses(mSeparateProcesses);
        pp.setDisplayMetrics(mMetrics);

        final PackageParser.Package pkg;
        try {
            pkg = pp.parsePackage(tmpPackageFile, parseFlags);
        } catch (PackageParserException e) {
            res.setError("Failed parse during installPackageLI", e);
            return;
        }
```

其次是校验签名的md5的过程

```
        try {
            pp.collectCertificates(pkg, parseFlags);
            pp.collectManifestDigest(pkg);
        } catch (PackageParserException e) {
            res.setError("Failed collect during installPackageLI", e);
            return;
        }

        /* If the installer passed in a manifest digest, compare it now. */
        if (args.manifestDigest != null) {
            if (DEBUG_INSTALL) {
                final String parsedManifest = pkg.manifestDigest == null ? "null"
                        : pkg.manifestDigest.toString();
                Slog.d(TAG, "Comparing manifests: " + args.manifestDigest.toString() + " vs. "
                        + parsedManifest);
            }

            if (!args.manifestDigest.equals(pkg.manifestDigest)) {
                res.setError(INSTALL_FAILED_PACKAGE_CHANGED, "Manifest digest changed");
                return;
            }
        } else if (DEBUG_INSTALL) {
            final String parsedManifest = pkg.manifestDigest == null
                    ? "null" : pkg.manifestDigest.toString();
            Slog.d(TAG, "manifestDigest was not present, but parser got: " + parsedManifest);
        }
```


调用installNewPackageLI安装。

### 12.installNewPackageLI

在这个方法中，调用scanPackageDirtyLI进行扫描，而在scanPackageDirtyLI中，经过复杂的操作之后就算完成了安装，诸如，创建用户数据目录，进行dex优化等等。


### 13.处理POST_INSTALL消息

略。


---### 最近访客<ul class="ds-recent-visitors" data-num-items="46" data-avatar-size="40"></ul>








