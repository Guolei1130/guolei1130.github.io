---
title: android应用进程是如何启动的
date: 2017-01-02 00:55:08
categories: Android
tags: framework

---
<Excerpt in index | 首页摘要>
### 1.前言

我们在了解了四大组件之后，有必要去了解下进程是如何启动的，毕竟，进程是一个很重要的感念。我们知道，我们可以在配置文件中，通过process属性指定进程。在ams中，如果组件需要运行在一个新的进程中，这时候就会去新建进程。让我们看下代码。

+ <!-- more -->
<The rest of contents | 余下全文>


```
            if (entryPoint == null) entryPoint = "android.app.ActivityThread";
            Trace.traceBegin(Trace.TRACE_TAG_ACTIVITY_MANAGER, "Start proc: " +
                    app.processName);
            checkTime(startTime, "startProcess: asking zygote to start proc");
            Process.ProcessStartResult startResult = Process.start(entryPoint,
                    app.processName, uid, uid, gids, debugFlags, mountExternal,
                    app.info.targetSdkVersion, app.info.seinfo, requiredAbi, instructionSet,
                    app.info.dataDir, entryPointArgs);
```

* 其中entryPoint是进程的运行入口


### 2.Process#start

在start方法中，会调用startViaZygote方法。

```
    private static ProcessStartResult startViaZygote(final String processClass,
                                  final String niceName,
                                  final int uid, final int gid,
                                  final int[] gids,
                                  int debugFlags, int mountExternal,
                                  int targetSdkVersion,
                                  String seInfo,
                                  String abi,
                                  String instructionSet,
                                  String appDataDir,
                                  String[] extraArgs)
                                  throws ZygoteStartFailedEx {
        synchronized(Process.class) {
            ArrayList<String> argsForZygote = new ArrayList<String>();

            // --runtime-args, --setuid=, --setgid=,
            // and --setgroups= must go first
            argsForZygote.add("--runtime-args");
            argsForZygote.add("--setuid=" + uid);
            argsForZygote.add("--setgid=" + gid);
            if ((debugFlags & Zygote.DEBUG_ENABLE_JNI_LOGGING) != 0) {
                argsForZygote.add("--enable-jni-logging");
            }
            if ((debugFlags & Zygote.DEBUG_ENABLE_SAFEMODE) != 0) {
                argsForZygote.add("--enable-safemode");
            }
            if ((debugFlags & Zygote.DEBUG_ENABLE_DEBUGGER) != 0) {
                argsForZygote.add("--enable-debugger");
            }
            if ((debugFlags & Zygote.DEBUG_ENABLE_CHECKJNI) != 0) {
                argsForZygote.add("--enable-checkjni");
            }
            if ((debugFlags & Zygote.DEBUG_ENABLE_JIT) != 0) {
                argsForZygote.add("--enable-jit");
            }
            if ((debugFlags & Zygote.DEBUG_GENERATE_DEBUG_INFO) != 0) {
                argsForZygote.add("--generate-debug-info");
            }
            if ((debugFlags & Zygote.DEBUG_ENABLE_ASSERT) != 0) {
                argsForZygote.add("--enable-assert");
            }
            if (mountExternal == Zygote.MOUNT_EXTERNAL_DEFAULT) {
                argsForZygote.add("--mount-external-default");
            } else if (mountExternal == Zygote.MOUNT_EXTERNAL_READ) {
                argsForZygote.add("--mount-external-read");
            } else if (mountExternal == Zygote.MOUNT_EXTERNAL_WRITE) {
                argsForZygote.add("--mount-external-write");
            }
            argsForZygote.add("--target-sdk-version=" + targetSdkVersion);

            //TODO optionally enable debuger
            //argsForZygote.add("--enable-debugger");

            // --setgroups is a comma-separated list
            if (gids != null && gids.length > 0) {
                StringBuilder sb = new StringBuilder();
                sb.append("--setgroups=");

                int sz = gids.length;
                for (int i = 0; i < sz; i++) {
                    if (i != 0) {
                        sb.append(',');
                    }
                    sb.append(gids[i]);
                }

                argsForZygote.add(sb.toString());
            }

            if (niceName != null) {
                argsForZygote.add("--nice-name=" + niceName);
            }

            if (seInfo != null) {
                argsForZygote.add("--seinfo=" + seInfo);
            }

            if (instructionSet != null) {
                argsForZygote.add("--instruction-set=" + instructionSet);
            }

            if (appDataDir != null) {
                argsForZygote.add("--app-data-dir=" + appDataDir);
            }

            argsForZygote.add(processClass);

            if (extraArgs != null) {
                for (String arg : extraArgs) {
                    argsForZygote.add(arg);
                }
            }

            return zygoteSendArgsAndGetResult(openZygoteSocketIfNeeded(abi), argsForZygote);
        }
    }
```
在经过一系列参数设置之后，会调用zygoteSendArgsAndGetResult方法，这里需要两个参数，一个是ZygoteState，通过openZygoteSocketIfNeeded函数返回，另一个就是启动配置。接下来就看下openZygoteSocketIfNeeded干了什么？

### 3.Process#openZygoteSocketIfNeeded

 ```
     private static ZygoteState openZygoteSocketIfNeeded(String abi) throws ZygoteStartFailedEx {
        if (primaryZygoteState == null || primaryZygoteState.isClosed()) {
            try {
                primaryZygoteState = ZygoteState.connect(ZYGOTE_SOCKET);
            } catch (IOException ioe) {
                throw new ZygoteStartFailedEx("Error connecting to primary zygote", ioe);
            }
        }

        if (primaryZygoteState.matches(abi)) {
            return primaryZygoteState;
        }

        // The primary zygote didn't match. Try the secondary.
        if (secondaryZygoteState == null || secondaryZygoteState.isClosed()) {
            try {
            secondaryZygoteState = ZygoteState.connect(SECONDARY_ZYGOTE_SOCKET);
            } catch (IOException ioe) {
                throw new ZygoteStartFailedEx("Error connecting to secondary zygote", ioe);
            }
        }

        if (secondaryZygoteState.matches(abi)) {
            return secondaryZygoteState;
        }

        throw new ZygoteStartFailedEx("Unsupported zygote ABI: " + abi);
    }
 ```
 
 这个方法会根据需要是否开启和zygote进程的socket通道，去做操作。在这里能看到两种不同的，这里是因为android5.0开始，支持64位编译，上面分别对应32和64，这里就不说多了。这里通过ZygoteState的connect方法，去链接到在zygote进程中的server端。
 
### 4. Process#zygoteSendArgsAndGetResult

```
            final BufferedWriter writer = zygoteState.writer;
            final DataInputStream inputStream = zygoteState.inputStream;

            writer.write(Integer.toString(args.size()));
            writer.newLine();

            int sz = args.size();
            for (int i = 0; i < sz; i++) {
                String arg = args.get(i);
                if (arg.indexOf('\n') >= 0) {
                    throw new ZygoteStartFailedEx(
                            "embedded newlines not allowed");
                }
                writer.write(arg);
                writer.newLine();
            }

            writer.flush();

            // Should there be a timeout on this?
            ProcessStartResult result = new ProcessStartResult();
            result.pid = inputStream.readInt();
            if (result.pid < 0) {
                throw new ZygoteStartFailedEx("fork() failed");
            }
            result.usingWrapper = inputStream.readBoolean();
            return result;
```

在这个方法中，向socke通道写入进程启动参数，等待socket server相应并返回，读取返回结果。

那么，现在我们就需要这里socket服务端的处理。因为这里没有分析zygote进程的启动，所以讲起来比较麻烦，直接告诉大家，其socket服务端实现在ZygoteInit中，在mian方法中，会调用registerZygoteSocket方法去启动socket server。在然后会调用runSelectLoop方法，去等待socket客户端的连接。

### 5. ZygoteInit#runSelectLoop

```
    private static void runSelectLoop(String abiList) throws MethodAndArgsCaller {
        ArrayList<FileDescriptor> fds = new ArrayList<FileDescriptor>();
        ArrayList<ZygoteConnection> peers = new ArrayList<ZygoteConnection>();

        fds.add(sServerSocket.getFileDescriptor());
        peers.add(null);

        while (true) {
            StructPollfd[] pollFds = new StructPollfd[fds.size()];
            for (int i = 0; i < pollFds.length; ++i) {
                pollFds[i] = new StructPollfd();
                pollFds[i].fd = fds.get(i);
                pollFds[i].events = (short) POLLIN;
            }
            try {
                Os.poll(pollFds, -1);
            } catch (ErrnoException ex) {
                throw new RuntimeException("poll failed", ex);
            }
            for (int i = pollFds.length - 1; i >= 0; --i) {
                if ((pollFds[i].revents & POLLIN) == 0) {
                    continue;
                }
                if (i == 0) {
                    ZygoteConnection newPeer = acceptCommandPeer(abiList);
                    peers.add(newPeer);
                    fds.add(newPeer.getFileDesciptor());
                } else {
                    boolean done = peers.get(i).runOnce();
                    if (done) {
                        peers.remove(i);
                        fds.remove(i);
                    }
                }
            }
        }
    }
```

首先会通过Os.poll等待事件的到来，这里应该是用的poll模型，然后处理，当i=0的时候，为socket请求连接的事件，这时会调用acceptCommandPeer与客户端建立一个连接，然后加入监听数组，等待参数的到来，一旦i!=0,则为参数到来，那么，就调用runOnce去处理参数。完成之后，移除连接、移除监听。

### 6.ZygoteConnection#runOnce

```
   boolean runOnce() throws ZygoteInit.MethodAndArgsCaller {

        String args[];
        Arguments parsedArgs = null;
        FileDescriptor[] descriptors;

        try {
            args = readArgumentList();
            descriptors = mSocket.getAncillaryFileDescriptors();
        } catch (IOException ex) {
            Log.w(TAG, "IOException on command socket " + ex.getMessage());
            closeSocket();
            return true;
        }

        if (args == null) {
            // EOF reached.
            closeSocket();
            return true;
        }

        /** the stderr of the most recent request, if avail */
        PrintStream newStderr = null;

        if (descriptors != null && descriptors.length >= 3) {
            newStderr = new PrintStream(
                    new FileOutputStream(descriptors[2]));
        }

        int pid = -1;
        FileDescriptor childPipeFd = null;
        FileDescriptor serverPipeFd = null;

        try {
            parsedArgs = new Arguments(args);

            if (parsedArgs.abiListQuery) {
                return handleAbiListQuery();
            }

            if (parsedArgs.permittedCapabilities != 0 || parsedArgs.effectiveCapabilities != 0) {
                throw new ZygoteSecurityException("Client may not specify capabilities: " +
                        "permitted=0x" + Long.toHexString(parsedArgs.permittedCapabilities) +
                        ", effective=0x" + Long.toHexString(parsedArgs.effectiveCapabilities));
            }

            applyUidSecurityPolicy(parsedArgs, peer);
            applyInvokeWithSecurityPolicy(parsedArgs, peer);

            applyDebuggerSystemProperty(parsedArgs);
            applyInvokeWithSystemProperty(parsedArgs);

            int[][] rlimits = null;

            if (parsedArgs.rlimits != null) {
                rlimits = parsedArgs.rlimits.toArray(intArray2d);
            }

            if (parsedArgs.invokeWith != null) {
                FileDescriptor[] pipeFds = Os.pipe2(O_CLOEXEC);
                childPipeFd = pipeFds[1];
                serverPipeFd = pipeFds[0];
                Os.fcntlInt(childPipeFd, F_SETFD, 0);
            }

            /**
             * In order to avoid leaking descriptors to the Zygote child,
             * the native code must close the two Zygote socket descriptors
             * in the child process before it switches from Zygote-root to
             * the UID and privileges of the application being launched.
             *
             * In order to avoid "bad file descriptor" errors when the
             * two LocalSocket objects are closed, the Posix file
             * descriptors are released via a dup2() call which closes
             * the socket and substitutes an open descriptor to /dev/null.
             */

            int [] fdsToClose = { -1, -1 };

            FileDescriptor fd = mSocket.getFileDescriptor();

            if (fd != null) {
                fdsToClose[0] = fd.getInt$();
            }

            fd = ZygoteInit.getServerSocketFileDescriptor();

            if (fd != null) {
                fdsToClose[1] = fd.getInt$();
            }

            fd = null;

            pid = Zygote.forkAndSpecialize(parsedArgs.uid, parsedArgs.gid, parsedArgs.gids,
                    parsedArgs.debugFlags, rlimits, parsedArgs.mountExternal, parsedArgs.seInfo,
                    parsedArgs.niceName, fdsToClose, parsedArgs.instructionSet,
                    parsedArgs.appDataDir);
        } catch (ErrnoException ex) {
            logAndPrintError(newStderr, "Exception creating pipe", ex);
        } catch (IllegalArgumentException ex) {
            logAndPrintError(newStderr, "Invalid zygote arguments", ex);
        } catch (ZygoteSecurityException ex) {
            logAndPrintError(newStderr,
                    "Zygote security policy prevents request: ", ex);
        }

        try {
            if (pid == 0) {
                // in child
                IoUtils.closeQuietly(serverPipeFd);
                serverPipeFd = null;
                handleChildProc(parsedArgs, descriptors, childPipeFd, newStderr);

                // should never get here, the child is expected to either
                // throw ZygoteInit.MethodAndArgsCaller or exec().
                return true;
            } else {
                // in parent...pid of < 0 means failure
                IoUtils.closeQuietly(childPipeFd);
                childPipeFd = null;
                return handleParentProc(pid, descriptors, serverPipeFd, parsedArgs);
            }
        } finally {
            IoUtils.closeQuietly(childPipeFd);
            IoUtils.closeQuietly(serverPipeFd);
        }
    }
```

* readArgumentList读区启动参数
* 构造Arguments，在这个的构造函数中，会调用parseArgs去解析参数
* 随后进行参数检查和配置
* 调用Zygote.forkAndSpecialize进行fork进程，返回进程id


### 7.Zygote#forkAndSpecialize

```
    public static int forkAndSpecialize(int uid, int gid, int[] gids, int debugFlags,
          int[][] rlimits, int mountExternal, String seInfo, String niceName, int[] fdsToClose,
          String instructionSet, String appDataDir) {
        VM_HOOKS.preFork();
        int pid = nativeForkAndSpecialize(
                  uid, gid, gids, debugFlags, rlimits, mountExternal, seInfo, niceName, fdsToClose,
                  instructionSet, appDataDir);
        // Enable tracing as soon as possible for the child process.
        if (pid == 0) {
            Trace.setTracingEnabled(true);

            // Note that this event ends at the end of handleChildProc,
            Trace.traceBegin(Trace.TRACE_TAG_ACTIVITY_MANAGER, "PostFork");
        }
        VM_HOOKS.postForkCommon();
        return pid;
    }
```

* VM_HOOKS是ZygoteHooks
* 在preFork中，会中断HeapTaskDaemon、ReferenceQueueDaemon、FinalizerDaemon、FinalizerWatchdogDaemon，这四个守护线程。并调用nativePreFork在native层做一些fork之前的操作。其对应实现在daivik_system_ZygoteHocks.cc文件中，函数对应表如下

	```
static JNINativeMethod gMethods[] = {
  NATIVE_METHOD(ZygoteHooks, nativePreFork, "()J"),
  NATIVE_METHOD(ZygoteHooks, nativePostForkChild, "(JILjava/lang/String;)V"),
};
	```
* 然后调用nativeForkAndSpecialize去fork进程，对应实现在com_android_internal_os_Zygote.cpp中。
* 调用VM_HOOKS的postForkCommon，去启动先前中断的几个线程。


### 8. nativePreFork

```
static jlong ZygoteHooks_nativePreFork(JNIEnv* env, jclass) {
  Runtime* runtime = Runtime::Current();
  CHECK(runtime->IsZygote()) << "runtime instance not started with -Xzygote";

  runtime->PreZygoteFork();

  if (Trace::GetMethodTracingMode() != TracingMode::kTracingInactive) {
    // Tracing active, pause it.
    Trace::Pause();
  }

  // Grab thread before fork potentially makes Thread::pthread_key_self_ unusable.
  return reinterpret_cast<jlong>(ThreadForEnv(env));
}
```
这里会调用runtime、runtime中调用heap，最终调用heap的PreZygoteFork方法。去做一些初始化操作，本人太渣，看不太懂。略

### 9. nativeForkAndSpecialize

在com_android_internal_os_Zygote_nativeForkAndSpecialize方法中，会调用ForkAndSpecializeCommon。

```
static pid_t ForkAndSpecializeCommon(JNIEnv* env, uid_t uid, gid_t gid, jintArray javaGids,
                                     jint debug_flags, jobjectArray javaRlimits,
                                     jlong permittedCapabilities, jlong effectiveCapabilities,
                                     jint mount_external,
                                     jstring java_se_info, jstring java_se_name,
                                     bool is_system_server, jintArray fdsToClose,
                                     jstring instructionSet, jstring dataDir) {
  SetSigChldHandler();

  pid_t pid = fork();

  if (pid == 0) {
    // The child process.
    gMallocLeakZygoteChild = 1;

    // Clean up any descriptors which must be closed immediately
    DetachDescriptors(env, fdsToClose);

    // Keep capabilities across UID change, unless we're staying root.
    if (uid != 0) {
      EnableKeepCapabilities(env);
    }

    DropCapabilitiesBoundingSet(env);

    bool use_native_bridge = !is_system_server && (instructionSet != NULL)
        && android::NativeBridgeAvailable();
    if (use_native_bridge) {
      ScopedUtfChars isa_string(env, instructionSet);
      use_native_bridge = android::NeedsNativeBridge(isa_string.c_str());
    }
    if (use_native_bridge && dataDir == NULL) {
      // dataDir should never be null if we need to use a native bridge.
      // In general, dataDir will never be null for normal applications. It can only happen in
      // special cases (for isolated processes which are not associated with any app). These are
      // launched by the framework and should not be emulated anyway.
      use_native_bridge = false;
      ALOGW("Native bridge will not be used because dataDir == NULL.");
    }

    if (!MountEmulatedStorage(uid, mount_external, use_native_bridge)) {
      ALOGW("Failed to mount emulated storage: %s", strerror(errno));
      if (errno == ENOTCONN || errno == EROFS) {
        // When device is actively encrypting, we get ENOTCONN here
        // since FUSE was mounted before the framework restarted.
        // When encrypted device is booting, we get EROFS since
        // FUSE hasn't been created yet by init.
        // In either case, continue without external storage.
      } else {
        ALOGE("Cannot continue without emulated storage");
        RuntimeAbort(env);
      }
    }

    if (!is_system_server) {
        int rc = createProcessGroup(uid, getpid());
        if (rc != 0) {
            if (rc == -EROFS) {
                ALOGW("createProcessGroup failed, kernel missing CONFIG_CGROUP_CPUACCT?");
            } else {
                ALOGE("createProcessGroup(%d, %d) failed: %s", uid, pid, strerror(-rc));
            }
        }
    }

    SetGids(env, javaGids);

    SetRLimits(env, javaRlimits);

    if (use_native_bridge) {
      ScopedUtfChars isa_string(env, instructionSet);
      ScopedUtfChars data_dir(env, dataDir);
      android::PreInitializeNativeBridge(data_dir.c_str(), isa_string.c_str());
    }

    int rc = setresgid(gid, gid, gid);
    if (rc == -1) {
      ALOGE("setresgid(%d) failed: %s", gid, strerror(errno));
      RuntimeAbort(env);
    }

    rc = setresuid(uid, uid, uid);
    if (rc == -1) {
      ALOGE("setresuid(%d) failed: %s", uid, strerror(errno));
      RuntimeAbort(env);
    }

    if (NeedsNoRandomizeWorkaround()) {
        // Work around ARM kernel ASLR lossage (http://b/5817320).
        int old_personality = personality(0xffffffff);
        int new_personality = personality(old_personality | ADDR_NO_RANDOMIZE);
        if (new_personality == -1) {
            ALOGW("personality(%d) failed: %s", new_personality, strerror(errno));
        }
    }

    SetCapabilities(env, permittedCapabilities, effectiveCapabilities);

    SetSchedulerPolicy(env);

    const char* se_info_c_str = NULL;
    ScopedUtfChars* se_info = NULL;
    if (java_se_info != NULL) {
        se_info = new ScopedUtfChars(env, java_se_info);
        se_info_c_str = se_info->c_str();
        if (se_info_c_str == NULL) {
          ALOGE("se_info_c_str == NULL");
          RuntimeAbort(env);
        }
    }
    const char* se_name_c_str = NULL;
    ScopedUtfChars* se_name = NULL;
    if (java_se_name != NULL) {
        se_name = new ScopedUtfChars(env, java_se_name);
        se_name_c_str = se_name->c_str();
        if (se_name_c_str == NULL) {
          ALOGE("se_name_c_str == NULL");
          RuntimeAbort(env);
        }
    }
    rc = selinux_android_setcontext(uid, is_system_server, se_info_c_str, se_name_c_str);
    if (rc == -1) {
      ALOGE("selinux_android_setcontext(%d, %d, \"%s\", \"%s\") failed", uid,
            is_system_server, se_info_c_str, se_name_c_str);
      RuntimeAbort(env);
    }

    // Make it easier to debug audit logs by setting the main thread's name to the
    // nice name rather than "app_process".
    if (se_info_c_str == NULL && is_system_server) {
      se_name_c_str = "system_server";
    }
    if (se_info_c_str != NULL) {
      SetThreadName(se_name_c_str);
    }

    delete se_info;
    delete se_name;

    UnsetSigChldHandler();

    env->CallStaticVoidMethod(gZygoteClass, gCallPostForkChildHooks, debug_flags,
                              is_system_server ? NULL : instructionSet);
    if (env->ExceptionCheck()) {
      ALOGE("Error calling post fork hooks.");
      RuntimeAbort(env);
    }
  } else if (pid > 0) {
    // the parent process
  }
  return pid;
}
```

* 设置子进程的signal信号处理函数 SetSigChldHandler函数
* fork进程，fork函数
* pid为0，进入子进程
	* DetachDescriptors 关闭清理文件描述符
	* SetGids 设置group
	* SetRLimits 设置资源限制
	* 进行其他的初始化设置
	* CallStaticVoidMethod，调用ZygotecallPostForkChildHooks方法。这里又会调用nativePostForkChild。
	* ...
* 父进程分支，啥也不做
* 返回pid	 
当这些都执行完之后，回到ZygoteConnection的runonce方法，进行后续操作

```
        try {
            if (pid == 0) {
                // in child
                IoUtils.closeQuietly(serverPipeFd);
                serverPipeFd = null;
                handleChildProc(parsedArgs, descriptors, childPipeFd, newStderr);

                // should never get here, the child is expected to either
                // throw ZygoteInit.MethodAndArgsCaller or exec().
                return true;
            } else {
                // in parent...pid of < 0 means failure
                IoUtils.closeQuietly(childPipeFd);
                childPipeFd = null;
                return handleParentProc(pid, descriptors, serverPipeFd, parsedArgs);
            }
        } finally {
            IoUtils.closeQuietly(childPipeFd);
            IoUtils.closeQuietly(serverPipeFd);
        }

```

我们重点看handleChildProc。

### 10.ZygoteConnection#handleChildProc

在这个方法中，有如下代码。

```
        if (parsedArgs.invokeWith != null) {
            WrapperInit.execApplication(parsedArgs.invokeWith,
                    parsedArgs.niceName, parsedArgs.targetSdkVersion,
                    VMRuntime.getCurrentInstructionSet(),
                    pipeFd, parsedArgs.remainingArgs);
        } else {
            RuntimeInit.zygoteInit(parsedArgs.targetSdkVersion,
                    parsedArgs.remainingArgs, null /* classLoader */);
        }
```

大部分情况下，invokeWith为null，所以我们看下面的分支。


### 11.RuntimeInit.zygoteInit

```
    public static final void zygoteInit(int targetSdkVersion, String[] argv, ClassLoader classLoader)
            throws ZygoteInit.MethodAndArgsCaller {
        if (DEBUG) Slog.d(TAG, "RuntimeInit: Starting application from zygote");

        Trace.traceBegin(Trace.TRACE_TAG_ACTIVITY_MANAGER, "RuntimeInit");
        redirectLogStreams();

        commonInit();
        nativeZygoteInit();
        applicationInit(targetSdkVersion, argv, classLoader);
    }
```

* 重定向log输出
* commonInit,进行通用的一些设置如时区。
* zygote初始化
* 应用初始化

### 12.nativeZygoteInit

该函数的实现在AndroidRuntime.cpp中，

```
static void com_android_internal_os_RuntimeInit_nativeZygoteInit(JNIEnv* env, jobject clazz)
{
    gCurRuntime->onZygoteInit();
}
```

这里onZygoteInit在app_main.cpp中，这里就不多说了。

### 13.RuntimeInit.applicationInit

```
    private static void applicationInit(int targetSdkVersion, String[] argv, ClassLoader classLoader)
            throws ZygoteInit.MethodAndArgsCaller {
        // If the application calls System.exit(), terminate the process
        // immediately without running any shutdown hooks.  It is not possible to
        // shutdown an Android application gracefully.  Among other things, the
        // Android runtime shutdown hooks close the Binder driver, which can cause
        // leftover running threads to crash before the process actually exits.
        nativeSetExitWithoutCleanup(true);

        // We want to be fairly aggressive about heap utilization, to avoid
        // holding on to a lot of memory that isn't needed.
        VMRuntime.getRuntime().setTargetHeapUtilization(0.75f);
        VMRuntime.getRuntime().setTargetSdkVersion(targetSdkVersion);

        final Arguments args;
        try {
            args = new Arguments(argv);
        } catch (IllegalArgumentException ex) {
            Slog.e(TAG, ex.getMessage());
            // let the process exit
            return;
        }

        // The end of of the RuntimeInit event (see #zygoteInit).
        Trace.traceEnd(Trace.TRACE_TAG_ACTIVITY_MANAGER);

        // Remaining arguments are passed to the start class's static main
        invokeStaticMain(args.startClass, args.startArgs, classLoader);
    }
```

这里设置一些参数，并且调用invokeStaticMain，从名字上来看，就知道是调用静态main方法，也就是我们指定的进程入口ActivityThread的main方法。

```
    private static void invokeStaticMain(String className, String[] argv, ClassLoader classLoader)
            throws ZygoteInit.MethodAndArgsCaller {
        Class<?> cl;

        try {
            cl = Class.forName(className, true, classLoader);
        } catch (ClassNotFoundException ex) {
            throw new RuntimeException(
                    "Missing class when invoking static main " + className,
                    ex);
        }

        Method m;
        try {
            m = cl.getMethod("main", new Class[] { String[].class });
        } catch (NoSuchMethodException ex) {
            throw new RuntimeException(
                    "Missing static main on " + className, ex);
        } catch (SecurityException ex) {
            throw new RuntimeException(
                    "Problem getting static main on " + className, ex);
        }

        int modifiers = m.getModifiers();
        if (! (Modifier.isStatic(modifiers) && Modifier.isPublic(modifiers))) {
            throw new RuntimeException(
                    "Main method is not public and static on " + className);
        }

        /*
         * This throw gets caught in ZygoteInit.main(), which responds
         * by invoking the exception's run() method. This arrangement
         * clears up all the stack frames that were required in setting
         * up the process.
         */
        throw new ZygoteInit.MethodAndArgsCaller(m, argv);
    }
```

注意看最后一行代码的注释，因为我们之前经过了复杂的调用，堆栈信息比较多了，这里通过抛异常处理来清理调用栈。最后调用如下代码。

```
        public void run() {
            try {
                mMethod.invoke(null, new Object[] { mArgs });
            } catch (IllegalAccessException ex) {
                throw new RuntimeException(ex);
            } catch (InvocationTargetException ex) {
                Throwable cause = ex.getCause();
                if (cause instanceof RuntimeException) {
                    throw (RuntimeException) cause;
                } else if (cause instanceof Error) {
                    throw (Error) cause;
                }
                throw new RuntimeException(ex);
            }
        }
```

就这样我们的应用进程就启动起来了。当然，启动应用程序也是这个流程，简单说下吧：

在点击luncher上的图标，会通过startactivity启动我们的程序，但是，这时候没有进程，通过上面这些繁琐的流程启动之后，在启动activity，这样，应用程序也启动起来了。


---### 最近访客<ul class="ds-recent-visitors" data-num-items="46" data-avatar-size="40"></ul>



