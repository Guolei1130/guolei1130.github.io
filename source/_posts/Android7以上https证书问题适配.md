---
title: Android
date: 2018-01-18 20:29:36
tags: Android

---
<Excerpt in index | 首页摘要>

### 问题描述

从7.0开始，https方面行为发生了变更。当我们的证书是一个默认不被系统信任的CA机构颁布的时候，就会出现问题。具体文档[security-config](https://developer.android.com/training/articles/security-config.html)

我的情况是这样的，证书是一个不被系统认证的CA机构发的，我把这个CA的证书安装到手机的时候，7.0以下，行为正常，7.0以上行为不正常。用过查阅资料发现，是系统行为发生了变更。

### 解决这个问题

7.0以上，默认只信任系统信任的证书，也就是说，即使你安装了CA的证书，还是不被信任的。怎么处理这个问题呢？很简单。

新建一个xml文件,我这里起名network_security_config。

```
<network-security-config>    
   <base-config>  
      <trust-anchors>
          <certificates src="system" />
          <certificates src="user" />
      </trust-anchors>
   </base-config>
</network-security-config>
```

并在配置文件中配置	```android:networkSecurityConfig=”@xml/network_security_config” ```

这样就可以了。详细的资料，去看上面的那个链接吧。


<!-- more -->
<The rest of contents | 余下全文>


### 最近访客
<ul class="ds-recent-visitors" data-num-items="46" data-avatar-size="40"></ul>