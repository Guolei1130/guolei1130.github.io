
### 创建观察者

- create 
- from 从列表中创建
- just 从分别的数据中
- repeat 重复发射数据
- defer 延迟 知道有观察者订阅时才发射数据
- range 指定一个数字从x开始发射n个数字
- interval 需要创建一个轮训程序时非常好用
- timer 一段时间之后才发射


### 过滤observables

- filter 过滤序列中不需要的值
- take 有一个参数，表示发射数据序列中前多少个元素
- takelast 同理
- distlnct 过滤掉重复的值，只处理一次
- distlnctuntllschanged 得到可观察序列中不同于前面发射的值 温度传感器
- first 第一个元素
- last 最后一个元素
- skip ，参数n表示从可观察序列的第几个元素开始发射
- skiplast 同理
- elementat 只需要可观察序列中第n个元素
- sample  指定时间间隔内，发送最近的一个元素
- throttlefirlt 指定时间间隔内，发送第一个元素
- timeout 如果在指定时间内不发射值的话，就会发射error
- debounce 过滤掉发射的速率过快的数据，如果在一个指定的时间间隔过去了扔就没有发生一个的话，就发射最后的那个


### 转换

- map 对元素进行操作，比如大小写转换
- flatmap 对observable进行转换
- concatmap 解决flatmap的交叉问题，提供了能够吧发射的值连续在一起的铺平函数
- flatmapiterable 和flatmap很像，就是返回iterable
- switchmap 和flatmap很像，就是没发射一个新的observable项时，就取消订阅并停止之前的数据项产生的observable，并且开始监视当前发射的一个。
- sacn  可以看作是一个累积函数，发射的每一个数据项都应用于一个函数，计算出返回值并添加到可观察序列，供下一次使用。
- groupby 分组元素 可以进行排序


- buffer  将一个observable 变化成新的observable，而新的observable每次发射一组数据 buffer(3)，每次发射三个，三个参数，count，skip（步伐，每count个数据，timespan，每隔多长时间
- window window和bufffer很像，但是window发射的是observable而不是数据项
- cast 将每一个数据项都转化为新的类型


### 组合observables

- merge 将两个或者多个observable合并到一个序列中，含有一个操作符，mergedelayerror，即使合并出现异常，抛出异常，但是仍然继续发射数据
-  zip 多个observables，接受它们，并变化它们，然后组合成新的observable
-  join 基于窗口的，将两个observable合并成一个
-  combinelasted 和join一样只不过作用于最近发射的的数据项
-  and then when 
-  switch 当数据源发射一个新的observabe时，立即取消前一个的订阅并开始发射新observable的序列
-  startwith 在发射数据之前，先发射这些数据序列