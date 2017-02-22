title: 动态加载总结篇
date: 2016-03-19 11:49:14
tags: [android,动态加载,插件化]
category: android开发
---
动态加载是早几年前的神秘话题，这几年随着技术的开放，动态加载也用的越来越多，做了一些收录，把我之前写的那些渣渣文章做个弥补，再补上另一篇渣渣。

这篇文章没有实质性内容，开源可参考的框架很多，算是做了一点点收录。反正也好久没写博客了，顺带随便写点啥。

<!-- more -->

## 常用的动态加载的方法
* 代理方式，声明一个空壳activity，空壳activity中包含一个proxy activity对象，回调着proxy activity的生命周期。

* 参考google的multidex的方案，反射BaseDexClassLoader拿到dexElements，将自己的dex文件添加到这个列表里。

    此方法有个问题就是CLASS_ISPREVERIFIED，具体介绍可以看[这里](https://mp.weixin.qq.com/s?__biz=MzI1MTA1MzM2Nw==&mid=400118620&idx=1&sn=b4fdd5055731290eef12ad0d17f39d4a&scene=1&srcid=1106Imu9ZgwybID13e7y2nEi#wechat_redirect)

* 这个方法是我从支付宝中反编译中看的，反射mPackageInfo对象，这个对象是一个LoadedApk，再用反射替换掉这个对象的mClassLoader字段为自己的PathClassLoader，具体介绍请看[探究支付宝android客户端的动态加载](http://www.lephones.net/2014/09/29/alipay-dynamic_load/)

* 初始化的代码要写在Application类的attachBaseContext方法中，不要写在onCreate里，ContentProvider:onCreate()调用优先于Application:onCreate()，所以我关于支付宝的那篇文章，介绍是有点错误的。

## 部分框架介绍：

* [DynamicLoadApk](https://github.com/singwhatiwanna/dynamic-load-apk)

    采用代理的方式，在清单文件里注册了一个空壳avtivity，处理插件中，调用插件时，其实是start了空壳avtivity，插件中所有activity都需要继承proxy avtivity，插件中的activity其实就是一个普通的类。

    对安卓系统没有侵入性，各android版本均适用。

    完全实现插件化，不用在清单文件中注册各组件

    不能用this关键字，因为插件中的activity，本身不是一个系统加载过去的Context，当你要用this时，必须使用proxy avtivity的对象，也就是项目中的that。

    对项目改动有些大，所有的activity需要继承自proxy avtivity。


* [DroidPlugin](https://github.com/Qihoo360/DroidPlugin)

	奇虎360的框架，360手机助手在用。

    每个插件都是独立的，插件之间完全隔离。

    资源id不存在冲突

    四大组件不需要在清单文件中注册，等于调起一个未安装的APK，非常适合全家桶啊。

	不能使用自定义资源的通知

* [DynamicAPK](https://github.com/CtripMobile/DynamicAPK)

	携程的框架，宿主和项目是浑然一体的。

    实现资源共享，代码共用。

	资源id需要特殊处理

	四大组件必须得在宿主的清单文件中注册。

## 资源问题
* 360的插件没有这个问题，它们插件之前不能共用资源
* 插件和宿主的资源id会冲突，修改方法：不同插件用不同的资源package，即修改资源生成的id。默认都是以0x00开头，可以改为0xA1 0xA2开头，这需要修改aapt的源码，可参考携程的插件化，里面有aapt的代码。

	关于怎么搭建aapt的编译环境，可参考我前同事写的一篇BLOG [Build aapt for windows](http://blog.zanlabs.com/2015/09/04/build-aapt-for-windows/)，这货的这篇博客居然英文，十万头羊驼。。
* 也可以自已写ids，只要保证id没有一样的，不冲突就行。


附，阿里的开源动态修复框架：都针对art和dex做了特殊处理
[dexposed](https://github.com/alibaba/dexposed)(art慎用)
[AndFix](https://github.com/alibaba/AndFix)