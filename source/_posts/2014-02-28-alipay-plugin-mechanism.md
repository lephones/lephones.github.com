title: 支付宝插件机制研究
date: 2014-02-28 0:02:33
tags: [android,插件化]
category: android开发
---
## 前言 ##

**支付宝已不再采用该方法插件化了，请参考 [探究支付宝android客户端的动态加载](http://www.lephones.net/2014/09/29/alipay-dynamic_load/ "探究支付宝android客户端的动态加载")**

使用过支付宝android客户端的小伙伴们都知道，支付宝android客户端可以增量更新，不仅能够随时改变内部APP的个数，还可以改变它的布局，结构等。为本人也在做移动支付，对支付宝客户端颇感兴趣，于是找时间来简单破解研究一下。

支付宝的插件化，一共有两种方式，一种是通过html网页来实现布局。html技术相信coder们都清楚，不再介绍。这里只介绍native的插件化。

## 插件的下载 ##
通过对文件监控对比发现，支付宝的插件更新，是下载一个后缀名为.amr的文件，此文件实质是一个压缩包，修改后缀为zip可直接解压。

<!-- more -->

## 提取插件内容 ##
支付宝所有插件用到的文件都解压到了`/data/data/com.eg.android.AlipayGphone/files/apps/`目录下面，可直接提取。

提取出来后发现是一些数字文件夹和一个`config.json`文件，其中，一个数字的文件夹代表的是一个APP，而`config.json`文件包含所有app的一些配置信息，比如图标，名称等。

通过阅读`config.json`发现，**10000002**文件夹代表的是**我要收款**，好，就看你吧。

打开**10000002**文件夹，发现下列列表

- layout （文件夹）
- res	（文件夹）
- CERT	（文件）
- Manifest.xml	（文件）

## 文件说明及插件可配置化布局原理： ##
**layout**

一堆xml文件，看起来是包含有APP用到的布局文件，格式类似于android原生的layout的xml文件，但控件是支付宝的coder们自定义的。既然它用xml，肯定有解析xml的地方，用dex2jar转换apk，再用jd-gui逆向生成src，通过在反编译的源码中搜索xml的标签，找到了自定义控件的代码，在`com.alipay.android.appHall.component`包下面。该包下包含了很多自定义控件的类，均以UI开头。

定位到`com.alipay.android.appHall.component`下的**UIButton**的代码，找到了真正构成它的layout资源文件id（2130903115）。
```
Button localButton;
if (paramString.equals("main"))
localButton = (Button)LayoutInflater.from(this.a).inflate(2130903115, paramViewGroup, false);
```
用计算器将id **2130903115** 转换成16进制，可得到**0x7F03004B**。

用apktool工具反编译apk，生成资源文件，打开`/res/values/public.xml`找到 **0x7F03004B** 所对应的布局文件为button_main。在`/res/layout/`文件夹下面找到布局文件**button_main.xml**。

可通过该方法，找到其他控件的view类以及所对应的layout静态xml资源。

**res**

此文件夹中包含有三种类型的资源，`图片资源`，`interface.xml`，`res.xml`，打开res.xml，发现其中有三种类型的标签

```
<String id="10000">我要收款</String>
<Expression id="20000">(类似方法的表达式)
<Rule id="30000">(类似于json的一种配置关系)
```

- String	   字符串资源与id对应关系 id以1开头
- Expression    表达式，用于指定事件，在layout的控件中绑定id来指定触发的事件 id以2开头
- Rule		表达式，可根据不同的状态进行不同的操作 id以3开头

其中，String和Expression的id是在layout中使用的，配置到view的属性中。而Rule的id是在Expression的表达式中使用的，如：
```
<Expression id="20005">$exec($ternary(@30003,$ctrl_value_get(numbers)))</Expression>
```

**CERT**

签名文件，保存了该app下的所有的文件的签名，用于校验文件的完整性，防止篡改。

**Manifest.xml**

清单文件，算做是一个总的配置文件，说明性文档。具体功能未做细致研究。

## 总结 ##
在支付宝插件化中，布局文件采用了自定义常用控件的方案，重新编写了一组控件，通过配置文件来可配置性搭建界面。

对于控件的事件，比如按钮的点击事件，支付宝定义了一系列的表达式，通过在控件配置文件中配置表达式的id，来指定具体要执行的事件。我的一个猜想是：支付宝预先定义好了一些用到的算法，然后在具体事件中，通过表达式来组合这些算法的调用。因源码混淆，研究起来有难度，放弃验证。

另外，对于支付宝表达式的解析，朋友们可以将表达式字符串在反编译后的源码中搜索一下，就能找到痕迹。

关于表达式解析，大家可以自行在google寻找资料。如：JAVACC

附：如果不知道windows环境中，怎么在反编译后的代码中全局搜索资源，推荐一款神兵利器：**Replace Studio**，小伙伴们可google一下。

