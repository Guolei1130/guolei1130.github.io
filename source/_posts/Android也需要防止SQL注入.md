---
title: Android也需要防止SQL注入
date: 2018-03-25 10:59:03
tags: 安全
categories: Android

---
<Excerpt in index | 首页摘要>
### 为什么要写下这篇

最近，在移动端发现一个用户无法登陆的bug，经过排查，发现是不规范的Sql语句以及没做SQL攻击的防止导致的。

<!-- more -->
<The rest of contents | 余下全文>

### 移动端也防止关注SQL攻击

大多数情况下，我们是不需要考虑的，Android SDK给我们提供的query/insert/update/delete等API是安全的,但是**execSql这个API却不是,尽量别使用这个API**

由于我们的代码，原先的数据存储是靠C++的sqlite，而没借助Android的Sdk来做的。因此，原先一些SQL可能存在问题。

### 例子

```
String userName = "";
int age = 24;
mDBHelper.getWritableDatabase().execSQL(String.format(Locale.getDefault(),"insert into " + 		UserDBHelper.TABLE_NAME+ " (UserName,Age) values(%s,%d)",userName,age));
```

类似上面的代码，我想 大家的项目里或许也有。看上去，这个没有任何问题，但是却存在sql攻击，当我把userName这个字符串的内容换成，带特殊字符的，如 guolei' 的时候，这个拼接出来的sql语句就有问题了，回报如下错误。

```
Process: com.guolei.sqlinsert, PID: 22520
                                                                      android.database.sqlite.SQLiteException: unrecognized token: "',24)" (code 1): , while compiling: insert into user (UserName,Age) values(error',24)
                                                                          at android.database.sqlite.SQLiteConnection.nativePrepareStatement(Native Method)
```

这是因为单引号 ' 使sql语句发生了截断，在sql语句中，要用连续两个单引号去表达一个单引号字符。这仅仅是一个例子。有兴趣的，大家去了解SQL攻击相关的东西吧。


### 最近访客
<ul class="ds-recent-visitors" data-num-items="46" data-avatar-size="40"></ul>