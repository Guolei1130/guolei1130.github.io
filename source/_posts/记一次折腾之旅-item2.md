---
title: 记一次折腾之旅-item2
date: 2017-04-02 00:41:32
tags: 杂技

---
<Excerpt in index | 首页摘要>
### 前言

平常的开发学习当中，难免会于终端打交道，但是mac下自带的是在的弱，因此就有了这次的折腾之旅。

<!-- more -->
<The rest of contents | 余下全文>


### 开胃小菜

* item2
* oh-my-zsh


首先我们下载好item2并安装，[item2地址](https://www.iterm2.com/)。然后，我们需要安装下oh-my-zsh.[oh-my-zsh地址](https://github.com/robbyrussell/oh-my-zsh)

这两个步骤都比较简单。没什么可说的。接下来需要配置下item2的配色方案，我这里选的是[solarized](http://ethanschoonover.com/solarized),下载好之后，在item2->preference->profile->color->右下角进行导入并选择。

### powerline

接下来需要安装这个，这个是今天折腾的关键，在安装之前，我们需要确保我们的python环境在2.7版本以上。

```
python --version
```

然后，就安装powerline-status这个玩意，这里我们有几种安装的方式.

* pip install powerline-status
* pip install --user git+git://github.com/powerline/powerline
* ..其他自行查看文档https://powerline.readthedocs.io/en/latest/installation.html

安装好之后，我们就需要进行配置了，这里需要注意的是，我们这要配置zsh theme，[oh-my-zsh-powerline-theme](https://github.com/jeremyFreeAgent/oh-my-zsh-powerline-theme)。这里的配置很简单，就是配置.zshrc文件

```
cd ~
vim .zshrc

```

打开文件之后，我们进行配置。

```
 ZSH_THEME="powerline"
 #POWERLINE_RIGHT_A="data"
 #POWERLINE_RIGHT_B="none"
 POWERLINE_HIDE_USER_NAME="true"
 POWERLINE_HIDE_HOST_NAME="true"
 POWERLINE_DISABLE_RPROMPT="true"
```

首先我们设置THEME为powerline。然后在根据需要设置其他的属性，具体请查看[oh-my-zsh-powerline-theme的readme](https://github.com/jeremyFreeAgent/oh-my-zsh-powerline-theme)

然后,source .zshrc 生效

### 配置字体

在上诉配置之后，会出现乱码，我们还需要配置下字体.

[在这里](https://github.com/powerline/fonts)

然后，在item2的配置选项里，选择字体，即可。
### 最近访客
<ul class="ds-recent-visitors" data-num-items="46" data-avatar-size="40"></ul>