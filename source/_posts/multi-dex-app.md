title: android中方法id超过65536官方解决办法
date: 2014-11-27 01:55:46
tags: [android,dex,dexpathlist]
category: android开发
---
##前言
	Unable to execute dex: method ID not in [0, 0xffff]: 65536
安卓项目中，如果代码太多，会碰上一个叫dex文件方法数超过65536的问题。其实，google已经提供了一个标准的解决办法。使用`MultiDexApplication`。需要在项目中导入android sdk的support中的 android-support-multidex.jar

阅读本文前，我希望你已经看过google api文档中对该类的介绍了。
<!-- more -->
##使用方法

1. 先让自己的`Application`类继承`MultiDexApplication `，或者，可以覆写方法attachBaseContext为以下的代码。
```
protected void attachBaseContext(Context base) {
 super.attachBaseContext(base);
 MultiDex.install(this);
}
```

2. 将你的程序打成多个dex，命名分别为，classes.dex，classes2.dex，classes3.dex，。。。这里的名字已经被限制必须是这样。

OK，搞定。

##eclipse中如何使用run as
我在网上找了一些资料，基本都是说如何使用gradle打包。而我们开发中，习惯用eclipse的run as怎么用呢？

我不知道ADT是不是支持通过配置来解决，我只能写写我目前想到的办法。

操作：

- 先将你的代码中，不常修改的部分打成一个jar，再用dex命令将期转换成dex文件，并命名为classes2.dex
- 将classes2.dex文件复制到你主工程的src目录下。
- 将转换dex文件的jar编译依赖到你的主工程中，注意这里是编译依赖，就像android.jar一样。只参与编译，打包不会打进去，可参考build path中的配置。
- 在运行的时候，src中的文件就会直接打包到APK中了。



##原理
原理相对比较简单些，可以参考源dexpathlist代码，apk在运行的时候，有一个dexpathlist，而Multidex的代码中，会根据你的系统版本号对dexpathlist做修改，将所有的dex都添加到dexpathlist中。
