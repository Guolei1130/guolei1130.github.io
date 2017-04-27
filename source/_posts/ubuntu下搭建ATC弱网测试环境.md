---
title: ubuntu下搭建ATC弱网测试环境
date: 2017-04-27 14:09:35
tags: 测试

---
<Excerpt in index | 首页摘要>
### 前言

看到了Fresco的弱网测试框架，尝试一下。[github地址](https://github.com/facebook/augmented-traffic-control)


<!-- more -->
<The rest of contents | 余下全文>



1. 安装python virtualenv 

	```
sudo apt-get install python-virtualenv
```

2. 创建一个python 2.7的虚拟环境


	```
virtualenv python2.7 --python=python2.7

	```

3. 切换到虚拟环境

	```
source python2.7/bin.activate
	```

4. 安装django，版本必须1.10

	```
sudo pip install django==1.10
```

5. 安装ATC相关东西

	```
sudo pip install atc_thrift atcd django-atc-api django-atc-demo-ui django-atc-profile-storage
```

6. 初始化一个django项目

	```
django-admin startproject atcui
cd atcui
	```

	```
INSTALLED_APPS = (
    ...
    # Django ATC API
    'rest_framework',
    'atc_api',
    # Django ATC Demo UI
    'bootstrap_themes',
    'django_static_jquery',
    'atc_demo_ui',
    # Django ATC Profile Storage
    'atc_profile_storage',
)
```

	```	
	
	from django.views.generic.base import RedirectView
	from django.conf.urls import include,url

	urlpatterns = [
    	...
   	 # Django ATC API
    	url(r'^api/v1/', include('atc_api.urls')),
    	# Django ATC Demo UI
    	url(r'^atc_demo_ui/', include('atc_demo_ui.urls')),
    	# Django ATC profile storage
    	url(r'^api/v1/profiles/', include('atc_profile_storage.urls')),
    	url(r'^$', RedirectView.as_view(url='/atc_demo_ui/', permanent=False)),
    
	]
```
	
	```	
	python manage.py migrate
	
	```

7. 启动atcd

	注意，启动的时候得指定wan和lan,通过ifconfig查看，第一个为wan，最后一个为lan	

	```

	cd python2.7/bin/

	sudo ./atcd --atcd-wan wan名称 --atcd-lan lan名称
	
	``` 

8. 启动django

	```	
python manage.py runserver 0.0.0.0:8000
```

9. 测试

	本机链接localhost:8000

	手机链接IP 






### 最近访客
<ul class="ds-recent-visitors" data-num-items="46" data-avatar-size="40"></ul>