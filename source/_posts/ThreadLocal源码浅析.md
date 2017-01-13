---
title: ThreadLocal源码浅析
date: 2017-01-13 22:24:36
tags: 源码

---
<Excerpt in index | 首页摘要>
### 前言

ThreadLocal是用来实现本地线程存储的，就是每个线程都有自己的值。java和android sdk中的这个类实现有点小差别，这篇文章以android sdk中的ThreadLocal源码来解析，看看是如何实现的。

<!-- more -->
<The rest of contents | 余下全文>


### 设置值-set方法

```
    public void set(T value) {
        Thread currentThread = Thread.currentThread();
        Values values = values(currentThread);
        if (values == null) {
            values = initializeValues(currentThread);
        }
        values.put(this, value);
    }
```

set值的方法很简单，首先是获取当前线程对象，然后，通过values方法获取当前线程的localValues对象，这是一个Values对象，在ThreadLocal中起着很很重要的作用。如果为null的话，用initializeValues为当前线程初始化一个Values对象。最后，将值put进去。

#### Values的初始化

在initializeValues方法中，只是初始化一个Values对象

```
    Values initializeValues(Thread current) {
        return current.localValues = new Values();
    }
```

我们看下Values的无参构造函数的实现。

```
        Values() {
            initializeTable(INITIAL_SIZE);
            this.size = 0;
            this.tombstones = 0;
        }

```

* initializeTable 初始化一个容量为INITIAL_SIZE(16)*2的Object数组
* 设置存活对象数目size 为0
* 设置死亡对象数目size 为0

在看看initializeTable做了下啥

```
        private void initializeTable(int capacity) {
            this.table = new Object[capacity * 2];
            this.mask = table.length - 1;
            this.clean = 0;
            this.maximumLoad = capacity * 2 / 3; // 2/3
        }

```

* 初始化一个容量为16*2的对象数组，为什么要这样呢？因为这里没有使用map的结构来保存key，value，要是用数组保存key，value，容量当然得为value的2倍。而这里是用数组的结构，我想是因为访问和修改的速度快的原因吧。
* mark 用于散列索引,15
* clean 指向下一个将要清除的位置，这里指向最后一个元素
* maximumLoad 存活和死亡对象的最大数(用于扩容)，设置为容量的2/3

#### 存储到values中

```
        void put(ThreadLocal<?> key, Object value) {
            cleanUp();

            // Keep track of first tombstone. That's where we want to go back
            // and add an entry if necessary.
            int firstTombstone = -1;

            for (int index = key.hash & mask;; index = next(index)) {
                Object k = table[index];

                if (k == key.reference) {
                    // Replace existing entry.
                    table[index + 1] = value;
                    return;
                }

                if (k == null) {
                    if (firstTombstone == -1) {
                        // Fill in null slot.
                        table[index] = key.reference;
                        table[index + 1] = value;
                        size++;
                        return;
                    }

                    // Go back and replace first tombstone.
                    table[firstTombstone] = key.reference;
                    table[firstTombstone + 1] = value;
                    tombstones--;
                    size++;
                    return;
                }

                // Remember first tombstone.
                if (firstTombstone == -1 && k == TOMBSTONE) {
                    firstTombstone = index;
                }
            }
        }
```

* 清理垃圾回收后的线程本地变量
* firstTombstones为－1，用于追踪第一个死亡对象。
* 循环，index值为threadlocal的hash变量和mask变量的&，hash值对应为0，mask，当我们初始化的时候设置为15，也就是1111，两个&之后为0，而next操作，我们这里可以看出是index+2
* index处对应的就为key值，
	* 如果key.reference和k等，则将value存放于index+1处，替换已经存放的
	* 如果k为null，说明没放过
		* 如果firstTombstone为-1， 则index处放key.reference，index+1处放value
		* 如果不是，则将key和对应的value放在firstTombstone,firstTombstone+1处。
	* 不等于	key.reference，也不等于null，(threadlocal被gc回收了。)
		* firstTombstone 设置为index


put的操作还是有点复杂的，要考虑到gc回收的问题。

### 获取值-get方法

```
    public T get() {
        // Optimized for the fast path.
        Thread currentThread = Thread.currentThread();
        Values values = values(currentThread);
        if (values != null) {
            Object[] table = values.table;
            int index = hash & values.mask;
            if (this.reference == table[index]) {
                return (T) table[index + 1];
            }
        } else {
            values = initializeValues(currentThread);
        }

        return (T) values.getAfterMiss(this);
    }
```

在知道上面存在gc回收之后，这里就比较好理解了,gc回收之后，会吧index处的key，设置为TOMBSTONE对象。

* 如果index处的值是this.reference,也就是没被gc回收，那么就是index+1处的值
* 否则，getAfterMiss返回,这个函数后面会说到

### gc带来的影响及处理

因为key的reference变量是个WeakReference，因此，要考虑到gc的影响。

```
    private final Reference<ThreadLocal<T>> reference
            = new WeakReference<ThreadLocal<T>>(this);
```

关于java中的四种引用类型及其gc，这里不说了。

#### 清理过程

清理过程有cleanUp来完成。

```
        private void cleanUp() {
            if (rehash()) {
                // If we rehashed, we needn't clean up (clean up happens as
                // a side effect).
                return;
            }

            if (size == 0) {
                // No live entries == nothing to clean.
                return;
            }

            // Clean log(table.length) entries picking up where we left off
            // last time.
            int index = clean;
            Object[] table = this.table;
            for (int counter = table.length; counter > 0; counter >>= 1,
                    index = next(index)) {
                Object k = table[index];

                if (k == TOMBSTONE || k == null) {
                    continue; // on to next entry
                }

                // The table can only contain null, tombstones and references.
                @SuppressWarnings("unchecked")
                Reference<ThreadLocal<?>> reference
                        = (Reference<ThreadLocal<?>>) k;
                if (reference.get() == null) {
                    // This thread local was reclaimed by the garbage collector.
                    table[index] = TOMBSTONE;
                    table[index + 1] = null;
                    tombstones++;
                    size--;
                }
            }

            // Point cursor to next index.
            clean = index;
        }
```


* rehash返回true，或者live size为0，直接返回
* clean的初始值为0
* 不断从数组中取出key值，并判断是否被回收，如果被回收，则将key，设置为TOMBSTONE，value置null

这个过程就是将gc回收掉的key对应的value回收。


#### rehash过程-调整

```
        private boolean rehash() {
            if (tombstones + size < maximumLoad) {
                return false;
            }

            int capacity = table.length >> 1;

            // Default to the same capacity. This will create a table of the
            // same size and move over the live entries, analogous to a
            // garbage collection. This should only happen if you churn a
            // bunch of thread local garbage (removing and reinserting
            // the same thread locals over and over will overwrite tombstones
            // and not fill up the table).
            int newCapacity = capacity;

            if (size > (capacity >> 1)) {
                // More than 1/2 filled w/ live entries.
                // Double size.
                newCapacity = capacity * 2;
            }

            Object[] oldTable = this.table;

            // Allocate new table.
            initializeTable(newCapacity);

            // We won't have any tombstones after this.
            this.tombstones = 0;

            // If we have no live entries, we can quit here.
            if (size == 0) {
                return true;
            }

            // Move over entries.
            for (int i = oldTable.length - 2; i >= 0; i -= 2) {
                Object k = oldTable[i];
                if (k == null || k == TOMBSTONE) {
                    // Skip this entry.
                    continue;
                }

                // The table can only contain null, tombstones and references.
                @SuppressWarnings("unchecked")
                Reference<ThreadLocal<?>> reference
                        = (Reference<ThreadLocal<?>>) k;
                ThreadLocal<?> key = reference.get();
                if (key != null) {
                    // Entry is still live. Move it over.
                    add(key, oldTable[i + 1]);
                } else {
                    // The key was reclaimed.
                    size--;
                }
            }

            return true;
        }
```

* 如果死亡对象+存活对象达不到maximumLoad(阀值),不需要进行调整
* 计算出值的容量(length/2)
* 新容量仍然和旧容量一样，这是一种乐观的做法，当存活对象大于value容量/2时，才需要进行扩展
* 申请新的数组，将旧值中没被gc的活对象添加进去。



#### getAfterMiss过程

在第一个槽位(index)处没发现合适值的时候，会调用这个方法返回一个。

```
        Object getAfterMiss(ThreadLocal<?> key) {
            Object[] table = this.table;
            int index = key.hash & mask;

            // If the first slot is empty, the search is over.
            if (table[index] == null) {
                Object value = key.initialValue();

                // If the table is still the same and the slot is still empty...
                if (this.table == table && table[index] == null) {
                    table[index] = key.reference;
                    table[index + 1] = value;
                    size++;

                    cleanUp();
                    return value;
                }

                // The table changed during initialValue().
                put(key, value);
                return value;
            }

            // Keep track of first tombstone. That's where we want to go back
            // and add an entry if necessary.
            int firstTombstone = -1;

            // Continue search.
            for (index = next(index);; index = next(index)) {
                Object reference = table[index];
                if (reference == key.reference) {
                    return table[index + 1];
                }

                // If no entry was found...
                if (reference == null) {
                    Object value = key.initialValue();

                    // If the table is still the same...
                    if (this.table == table) {
                        // If we passed a tombstone and that slot still
                        // contains a tombstone...
                        if (firstTombstone > -1
                                && table[firstTombstone] == TOMBSTONE) {
                            table[firstTombstone] = key.reference;
                            table[firstTombstone + 1] = value;
                            tombstones--;
                            size++;

                            // No need to clean up here. We aren't filling
                            // in a null slot.
                            return value;
                        }

                        // If this slot is still empty...
                        if (table[index] == null) {
                            table[index] = key.reference;
                            table[index + 1] = value;
                            size++;

                            cleanUp();
                            return value;
                        }
                    }

                    // The table changed during initialValue().
                    put(key, value);
                    return value;
                }

                if (firstTombstone == -1 && reference == TOMBSTONE) {
                    // Keep track of this tombstone so we can overwrite it.
                    firstTombstone = index;
                }
            }
        }
```

方法较长，逻辑如下：

* 第一个槽位index处key为null，生成一个value，
	* 如果生成value的过程成数组没变，index处插入key，index+1处插入value，清理无用
	* 过程中，数组改变了.将value put进去 
* 循环处理
	* 数组中的key和传入的key.reference相等，返回数组index+1处的值
	* 数组中的key为null，初始化一个value 
		* 数组无变化，firstTombstone>-1,切firstTombstone为无效对象(TOMBSTONE)，修改firstTombstone为key，firstTombstone+1处为value，如果index处为null，加入到index处

		* 省略
		
### 总结

能看到，ThreadLocal的实现并不是想象中的那么简单。其中有一些问题我也没想明白，需要解析来思考下。



### 最近访客
<ul class="ds-recent-visitors" data-num-items="46" data-avatar-size="40"></ul>