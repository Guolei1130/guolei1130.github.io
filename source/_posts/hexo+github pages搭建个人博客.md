layout: 使用hexo+githb
title: pages搭建个人博客
categories: hexo
date: 2016-11-29 11:49:42
tags: hexo

---
<Excerpt in index | 首页摘要> 
### 搭建步骤

1. 下载nodejs并安装
2. 安装hexo npm install -g hexo-cli
+ <!-- more -->
<The rest of contents | 余下全文>
3. 初始化gitpage，注意即使用户名大些 也弄小写，然后在电脑中 git clone xxx
4. 进入本地仓库，初始化hexo站点，hexo init
5. 修改配置_config.yml，public_dir 为 ./
6. 修改主题 找到好的主题包，下载zip或者git，将下面主题相关的文件复制到themes/某主题名下
7. 修改root目录下的_congig.yml文件，修改```theme: spfk``` 并且修改deploy 为 
	
	```
deploy:
  type: git
  repo: https://github.com/Guolei1130/Guolei1130.github.io.git
  branch: master 
	``` 
根据需求或者主题需要，修改其他相应的配置

8. hexo generate 重新生成静态网页
9. hexo new blogname，生成你的blog
10. push到github,进行测试



### 一些基本操作

* hexo new blogname 生成blog
* hexo generate(g)  重新生成静态页面
* hexo server(s)  启动本地服务器

### 关于博客中的图片

个人建议放在_posts同级目录，规则按image/年/月/文章/来放

### 关于删除文章

直接删除_post下的即可



### 多说

大部分主题支持pv统计和多说，pv统计，大多数我们不需要改
去http://duoshuo.com/create-site/注册，并修改theme中的配置

```
duoshuo: 
  on: true
  domain: guolei1130
  # 是否开启多说评论，http://duoshuo.com/create-site/
  # 使用上面网址登陆你的多说，然后创建站点，在 domain 中填入你设定的域名前半部分
  # http://<要填的部分>.duoshuo.com (domain只填上<>里的内容，不要填整个网址)
```

配置完push到github，就可在多说管理后台进行管理

### 关于全文模式
先在主题的配置文件中，添加
```
auto_excerpt:
enable: false
length: 150
```

然后在文章的最前面加

```
<Excerpt in index | 首页摘要> 
```

在文章最后增加 

```
+ <!-- more -->
<The rest of contents | 余下全文>

```

### 关于图片资源问题

有两种办法

* 将图片放在source/images／文件下，通过/images/xx.png 来引用，注意使用mackdown的语法
* 找根目录的配置文件中，将post_asset_folder: true 打开，每次用命令生成post的时候就会生成一个对应的文件夹

---### 最近访客<ul class="ds-recent-visitors" data-num-items="46" data-avatar-size="40"></ul>