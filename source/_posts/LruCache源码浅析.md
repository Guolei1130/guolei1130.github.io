---
title: LruCache源码浅析
date: 2017-01-13 00:00:14
categories: Android
tags: 源码

---
<Excerpt in index | 首页摘要>
### 前言

(LRU)Least Recently Used,最近最少使用算法，其中LruCache便是其在的实现，也是今天的主角，它被用在各种各样的图片库中，我们当然有必要去了解他是如何实现的。源码非常简单，但是能看到许多非常有意思的地方。

<!-- more -->
<The rest of contents | 余下全文>


### 如何使用

```
   int cacheSize = 4 * 1024 * 1024; // 4MiB
   LruCache<String, Bitmap> bitmapCache = new LruCache<String, Bitmap>(cacheSize) {
        protected int sizeOf(String key, Bitmap value) {
            return value.getByteCount();
        }
    }}
```

初始化之后，便可放心的put、get了。很简单，不多说。

### 初始化过程

```
    public LruCache(int maxSize) {
        if (maxSize <= 0) {
            throw new IllegalArgumentException("maxSize <= 0");
        }
        this.maxSize = maxSize;
        this.map = new LinkedHashMap<K, V>(0, 0.75f, true);
    }
```

短短的几行代码，却有一个地方需要注意，LinkedHashMap传入的第三个参数，true。这是由含义的，这个参数表示，我们在访问的时候，会根据时间进行排序，厉害吧。

### get过程

```
    public final V get(K key) {
        if (key == null) {
            throw new NullPointerException("key == null");
        }

        V mapValue;
        synchronized (this) {
            mapValue = map.get(key);
            if (mapValue != null) {
                hitCount++;
                return mapValue;
            }
            missCount++;
        }

        /*
         * Attempt to create a value. This may take a long time, and the map
         * may be different when create() returns. If a conflicting value was
         * added to the map while create() was working, we leave that value in
         * the map and release the created value.
         */

        V createdValue = create(key);
        if (createdValue == null) {
            return null;
        }

        synchronized (this) {
            createCount++;
            mapValue = map.put(key, createdValue);

            if (mapValue != null) {
                // There was a conflict so undo that last put
                map.put(key, mapValue);
            } else {
                size += safeSizeOf(key, createdValue);
            }
        }

        if (mapValue != null) {
            entryRemoved(false, key, createdValue, mapValue);
            return mapValue;
        } else {
            trimToSize(maxSize);
            return createdValue;
        }
    }
```

* 首先，根据key获取value，根据结果修改对应的命中还是未命中
* 如果没有找到，就会调用create方法去创建一个value，当然，如果我们没有实现这个方法的话，默认返回null
* 如果实现了的话，会用put方法，把这个值丢进去，这个方法的返回结果，如果存在hash冲突(也就是已经有了同一hash值对应的value)，返回原有的value，并且撤销操作(通过将原值重新put进去)，不存在hash冲突，则调整我们当前已用size
* 存在hash冲突的情况下，entryRemoved去做一些操作，需要我们实现，不存在hash冲突，就调整size

### put过程

```
    public final V put(K key, V value) {
        if (key == null || value == null) {
            throw new NullPointerException("key == null || value == null");
        }

        V previous;
        synchronized (this) {
            putCount++;
            size += safeSizeOf(key, value);
            previous = map.put(key, value);
            if (previous != null) {
                size -= safeSizeOf(key, previous);
            }
        }

        if (previous != null) {
            entryRemoved(false, key, previous, value);
        }

        trimToSize(maxSize);
        return previous;
    }
```

这个过程就简单点了

* 调整size
* put值进去，如果存在hash冲突，返回原有的值
* 如果previous，即原来有值，调整size
* 如果原来有值，则调用entryRemoved去做一些释放操作，需要我们实现
* 最后，调整size大小

### 调整size过程

```
    public void trimToSize(int maxSize) {
        while (true) {
            K key;
            V value;
            synchronized (this) {
                if (size < 0 || (map.isEmpty() && size != 0)) {
                    throw new IllegalStateException(getClass().getName()
                            + ".sizeOf() is reporting inconsistent results!");
                }

                if (size <= maxSize) {
                    break;
                }

                Map.Entry<K, V> toEvict = map.eldest();
                if (toEvict == null) {
                    break;
                }

                key = toEvict.getKey();
                value = toEvict.getValue();
                map.remove(key);
                size -= safeSizeOf(key, value);
                evictionCount++;
            }

            entryRemoved(true, key, value, null);
        }
    }
```

调整size的过程呢，就是不断重map中取出头，进行销毁释放(entryRemoved),直到容量小于我们的初始化时给定的值。

### remove操作

```
    public final V remove(K key) {
        if (key == null) {
            throw new NullPointerException("key == null");
        }

        V previous;
        synchronized (this) {
            previous = map.remove(key);
            if (previous != null) {
                size -= safeSizeOf(key, previous);
            }
        }

        if (previous != null) {
            entryRemoved(false, key, previous, null);
        }

        return previous;
    }
```

* map中移除
* 销毁

### 总结

代码补偿，实现也简单清晰，但是却非常巧妙，有许多值得我们学习的地方。而那么多count，就是用来统计命中率啥的。






### 最近访客
<ul class="ds-recent-visitors" data-num-items="46" data-avatar-size="40"></ul>