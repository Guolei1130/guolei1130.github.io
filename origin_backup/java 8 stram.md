Stream 的api
IntStream
LongStream
DoubleStream

### 生成Stream Source的方式

* 从Collection和数组
	* Collection 接口的stream()和parallelStram()
	* Arrays.stram(T array) or Stream.of()
* 静态工厂
	* IntStream.range()
	* Files.walk()
* 自己构建	  
	* Spliterator 
* 其他
	* Random.ints() 等Random的一些方法
	* BitSet.stream()
	* Pattern.splitAsStream(java.lang.CharSequence)
	* JarFile.stream()
	
### 流的操作类型

* Intermediate 一个流可以侯敏跟随零个或多个Intermediate操作，其目的主要是打开流，做出某种程度的数据映射/过滤，然后返回一个新的流，交给下一个操作使用。这类操作都是惰性化的（lazy），就是说，仅仅调用到这类方法，并没有真正开始流的遍历。
* Terminal 一个流只能有一个 terminal 操作，当这个操作执行后，流就被使用“光”了，无法再被操作。所以这必定是流的最后一个操作。Terminal 操作的执行，才会真正开始流的遍历，并且会生成一个结果，或者一个 side effect。
* Short-cicuiting
	* 对于一个 intermediate 操作，如果它接受的是一个无限大（infinite/unbounded）的 Stream，但返回一个有限的新 Stream。
	* 对于一个 terminal 操作，如果它接受的是一个无限大的 Stream，但能在有限的时间计算出结果。

### 流的操作

* Intermediate：
	map (mapToInt, flatMap 等)、 filter、 distinct、 sorted、 peek、 limit、 skip、 parallel、 sequential、 unordered
* Terminal：
	forEach、 forEachOrdered、 toArray、 reduce、 collect、 min、 max、 count、 anyMatch、 allMatch、 noneMatch、 findFirst、 findAny、 iterator
* Short-circuiting：
	anyMatch、 allMatch、 noneMatch、 findFirst、 findAny、 limit

_ _ _

* map/flatmap 对数据进行变换
* filter 过滤
* distinct 特别的
* sorted 排序
* peek
* limit 数目限制
* skip 调过
* parallel 并行
* sequential 连续
* unordered 未排序
* foreach
* toArray
* reduce 组合，类似将元素组合成一个。
* collect to collect
* min 最小
* max 最大
* count 数目
* anyMatch 匹配

### 参考链接

[Java 8 Stream Tutorial](http://winterbe.com/posts/2014/07/31/java8-stream-tutorial-examples/)

[Java 8 中的 Streams API 详解](https://www.ibm.com/developerworks/cn/java/j-lo-java8streamapi/)

[Processing Data with Java SE 8 Streams, Part 1](http://www.oracle.com/technetwork/articles/java/ma14-java-se-8-streams-2177646.html)

[Part 2: Processing Data with Java SE 8 Streams](http://www.oracle.com/technetwork/articles/java/architect-streams-pt2-2227132.html)

[Package java.util.stream](http://docs.oracle.com/javase/8/docs/api/java/util/stream/package-summary.html)