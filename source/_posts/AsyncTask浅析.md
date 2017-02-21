---
title: AsyncTask浅析
date: 2017-02-21 21:15:28
categories: Android
tags: 源码

---
<Excerpt in index | 首页摘要>
### 前言

AsyncTask，或许大家在平常开发中经常用，或许不用，虽然说AsyncTask有自己的一些缺点，但是，这并不阻碍我们对他的学习。

<!-- more -->
<The rest of contents | 余下全文>


### 怎么用

用法很简单，我们只需要继承AsyncTask，并实现一些方法就可以了。

```
    public class CustomAsyncTask extends AsyncTask<String,Integer,Integer>{

        @Override
        protected void onPreExecute() {
            super.onPreExecute();
        }

        @Override
        protected Integer doInBackground(String... params) {
            //注意 更新进度要用publishProgress
            publishProgress(1);
            return null;
        }

        @Override
        protected void onProgressUpdate(Integer... values) {
            super.onProgressUpdate(values);
        }

        @Override
        protected void onPostExecute(Integer integer) {
            super.onPostExecute(integer);
        }
    }
```

一般来说，我们实现这几个方法就可以了。

* 而其中三个泛型参数分别表示，参数、进度值类型、返回值类型
* onPreExecute 会在执行之前调用，运行在主线程
* doInBackground运行在后台线程，需要注意，当我们更新进度的时候，需要使用publishProgress方法。
* onProgressUpdate表示，当进度值更新的时候，回调，运行在主线程
* onPostExecute耗时任务，执行完毕的时候回调，运行在主线程

然后，我们通过如下代码执行即可。

```
        CustomAsyncTask asyncTask = new CustomAsyncTask();
        asyncTask.execute("xxx");
```

接下来，我们就来看看它内部的实现原理。

### 构造方法

```
    public AsyncTask() {
        mWorker = new WorkerRunnable<Params, Result>() {
            public Result call() throws Exception {
                mTaskInvoked.set(true);

                Process.setThreadPriority(Process.THREAD_PRIORITY_BACKGROUND);
                //noinspection unchecked
                Result result = doInBackground(mParams);
                Binder.flushPendingCommands();
                return postResult(result);
            }
        };

        mFuture = new FutureTask<Result>(mWorker) {
            @Override
            protected void done() {
                try {
                    postResultIfNotInvoked(get());
                } catch (InterruptedException e) {
                    android.util.Log.w(LOG_TAG, e);
                } catch (ExecutionException e) {
                    throw new RuntimeException("An error occurred while executing doInBackground()",
                            e.getCause());
                } catch (CancellationException e) {
                    postResultIfNotInvoked(null);
                }
            }
        };
    }
```

初始化方法也很简单，在其中初始化了两个对象，其中一个是WorkerRunnable，这个类implements了Callable接口，这个接口是个声明类型的接口。还有一个是FutureTask，这是一个带返回值的task。

### execute方法

在execute方法中，直接调用了executeOnExecutor方法。

```
    public final AsyncTask<Params, Progress, Result> execute(Params... params) {
        return executeOnExecutor(sDefaultExecutor, params);
    }
```

其中第一个参数是默认的线程池。这里是SerialExecutor，从名字上就看得出，这是串行的。

```
    public final AsyncTask<Params, Progress, Result> executeOnExecutor(Executor exec,
            Params... params) {
        if (mStatus != Status.PENDING) {
            switch (mStatus) {
                case RUNNING:
                    throw new IllegalStateException("Cannot execute task:"
                            + " the task is already running.");
                case FINISHED:
                    throw new IllegalStateException("Cannot execute task:"
                            + " the task has already been executed "
                            + "(a task can be executed only once)");
            }
        }

        mStatus = Status.RUNNING;

        onPreExecute();

        mWorker.mParams = params;
        exec.execute(mFuture);

        return this;
    }
```

在这个方法中，会判断任务的状态，从这里的能看出，一次智能执行一个。随后会调用onPreExecute在执行之前的操作。接着，便是线程池execute任务，然后，便会调用mFuture的run方法。我们接着看。

### FutureTask#run

```
    public void run() {
        if (state != NEW ||
            !U.compareAndSwapObject(this, RUNNER, null, Thread.currentThread()))
            return;
        try {
            Callable<V> c = callable;
            if (c != null && state == NEW) {
                V result;
                boolean ran;
                try {
                    result = c.call();
                    ran = true;
                } catch (Throwable ex) {
                    result = null;
                    ran = false;
                    setException(ex);
                }
                if (ran)
                    set(result);
            }
        } finally {
            // runner must be non-null until state is settled to
            // prevent concurrent calls to run()
            runner = null;
            // state must be re-read after nulling runner to prevent
            // leaked interrupts
            int s = state;
            if (s >= INTERRUPTING)
                handlePossibleCancellationInterrupt(s);
        }
    }
```

从上面的代码，我们能看出这里，会先执行，Callback的call方法，也就是我们传入的WorkerRunnable的call方法，接着，在执行完毕之后，调用set方法去设置结果。这个方法中，调用finishCompletion方法。在这个方法中，则会调用自身的done方法，多的不说。我们回到AsyncTask，看WorkerRunnable的call和FutureTask的done吧。

### WorkerRunnable#call和FutureTask#done

我们先看call方法，

```
                mTaskInvoked.set(true);

                Process.setThreadPriority(Process.THREAD_PRIORITY_BACKGROUND);
                //noinspection unchecked
                Result result = doInBackground(mParams);
                Binder.flushPendingCommands();
                return postResult(result);
```

* 首先设置 task已被调用
* 然后设置线程优先级为后台线程
* 调用doInBackground方法执行耗时任务
* 执行完毕之后调用postResult去发送执行结果

最后，来看下FutureTask的done方法。

```
            protected void done() {
                try {
                    postResultIfNotInvoked(get());
                } catch (InterruptedException e) {
                    android.util.Log.w(LOG_TAG, e);
                } catch (ExecutionException e) {
                    throw new RuntimeException("An error occurred while executing doInBackground()",
                            e.getCause());
                } catch (CancellationException e) {
                    postResultIfNotInvoked(null);
                }
            }
```

在这里，会调用postResultIfNotInvoked方法，如果postResult没被调用过，就是结果没发送过，就会发送结果，这里是发送一条消息，然后根据类型去判断是更新进度还是结束任务。

```
    private static class InternalHandler extends Handler {
        public InternalHandler() {
            super(Looper.getMainLooper());
        }

        @SuppressWarnings({"unchecked", "RawUseOfParameterizedType"})
        @Override
        public void handleMessage(Message msg) {
            AsyncTaskResult<?> result = (AsyncTaskResult<?>) msg.obj;
            switch (msg.what) {
                case MESSAGE_POST_RESULT:
                    // There is only one result
                    result.mTask.finish(result.mData[0]);
                    break;
                case MESSAGE_POST_PROGRESS:
                    result.mTask.onProgressUpdate(result.mData);
                    break;
            }
        }
    }
```

### SerialExecutor

```
    private static class SerialExecutor implements Executor {
        final ArrayDeque<Runnable> mTasks = new ArrayDeque<Runnable>();
        Runnable mActive;

        public synchronized void execute(final Runnable r) {
            mTasks.offer(new Runnable() {
                public void run() {
                    try {
                        r.run();
                    } finally {
                        scheduleNext();
                    }
                }
            });
            if (mActive == null) {
                scheduleNext();
            }
        }

        protected synchronized void scheduleNext() {
            if ((mActive = mTasks.poll()) != null) {
                THREAD_POOL_EXECUTOR.execute(mActive);
            }
        }
    }
```

这里我们就不细说了。

### 总结

AsyncTask的源码其实蛮简单的，但是我们能否从简单的源码中学到一个东西呢？这是个问题。


### 最近访客
<ul class="ds-recent-visitors" data-num-items="46" data-avatar-size="40"></ul>