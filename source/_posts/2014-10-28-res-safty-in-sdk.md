title: android如何将资源打入jar并对资源进行保护
date: 2014-10-28 08:45:58
tags: [android,ant,res]
category: android打包
---

## 引言
有很多项目需要将Android工程打包成SDK，将java代码编译后打成一个jar包提供给二次开发商，但是，因为android工程会含有资源文件，那资源文件怎么提供给对方？怎么直接打到jar中？怎么保证资源的完全性？

** 后来发现了更简单的做法，做了补充，大家直接跳到最后的补充的内容看吧 **
<!-- more -->

## 走过的弯路
### 将资源直接提供给对方
之前我做的XX支付插件的项目是将资源文件做为一个`lib-project`提供给商户的，这种方法实际是可行的。但是，这时候问题来了，对于商户我们是不可控的，也就是说，二次开发中可以对我们的资源做任何手脚。XX曾经给我们的检测报告上写着，修改关键资源，修改关键LOGO后仍能使用。

### 对关键资源加密
因为XX方主要是在意其logo被篡改，于是就对包含logo的文件用公钥做了一份签名，启动插件的时候，进行签名校验。这份方案在我入职之前，代码里就有了的，刚开始用着是没问题的，但是当我入职后不久，问题就来了。有一个带关键信息的图片文件需要适配，因为对资源采用的是`getResources().openRawResource(id)`来访问取签名值的，但是在预先保存的签名，只能校验一个屏幕的，而适配的图片是有多份的。

### 和商户建立了默认的“契约”
其实商户也是相当诚信的，也没有任何必要去修改插件方的资源文件，毕竟支付是“双赢”，商户也不会乱动。

## ~~新的办法~~
### 发现
**该方法操作起来比较麻烦 对接入方也有要求 放弃 请直接看看后面的修改补充内容**

```
<resources>
    <item type="layout" name="xxx" >r/dir/xxx.xml/>
<resources>
```
~~偶然发现，在android开发时候，其实我们可以自定义资源的存放位置。怎么弄呢？只要将上面的代码放到`values`下面（类似strings文件格式，但type是layout），就会有一个`R.layout.xx`x的id指定到`r/dir/xxx.xml`,当然图片资源也可以这样用，type是drawable。~~

~~而我们可以直接在工程的`src`项目下新建`r.dir`的包名，未来打jar会自动打包成目录的。~~

~~关键是xml文件，这里我们`r.dir`不能再放源文件了，需要放用aapt编译的二进制文件。但是该方法也存在一个限制，就是你的values必须是源文件跟随调用你jar的主工程编译~~
~~
### 资源的安全防护

之前写过一篇文章，讲的是怎么把资源和jar一起做为SDK的时候，id的处理。[传送门](http://www.lephones.net/2014/02/28/android-lib-res/ "传送门")。这里我再简单说说

因为安卓资源通过R文件来读取，而R里面的id是在编译时候打入APK的。如果你编译sdk的时候写的是`R.xx.xxx`这种格式的，编译器会直接将id值写到class文件中，当sdk再在商户项目中编译时候，jar里面的id对应的其实已经不是你的资源了。

之前的文章讲的是把资源直接发给商户来编译，这就给商户提供了改动的空间。但如果是预先用aapt处理过的二进制XML文件，在就不会在商户再做编译，而是直接打入到apk中，所以只要我们验证自定义的路径中保存的二进制XML文件、图片资源文件的md5就可以了。

## 附加说明
### 如何读取APK中的资源并校验
我们都知道APK其实是一个ZIP，而我们通过context.getApplicationInfo().sourceDir就能得到这个zip的dir了。在zip工具类库中，JAVA其实提供了一个叫crc的校验值，类似md5，其实我们校验这个就OK了。

---
## 补充
上面的方法的经测试发现太渣，主要原因就是需要混淆资源，而且，还要修改打包过程，对商户打包，也有一定的操作要求，根本不可取。后来，在看别人的插件化框架的代码的时候，发现其实要做的很简单，商户也可以按标准打包流程，代码资源也可以直接写入到jar中。具体操作及原理：
1. 你的组件必须存在统一的一个基类，如BaseActivity，BaseService等，
2. 用反射创建出Assets对象，Resources对象
3. 调用resources.newTheme()创建Theme，调用setTo(super.getTheme())
4. 重写BaseActivity的3个方法：getResources() getTheme() getAssets()，return对应的对象
5. 其它组件类似

打包的时候，要打包一份jar，并打包一份apk，apk中只保留资源。jar和只有资源文件的apk提供给商户。

## 部分代码
创建资源对象的代码 注意修改path
```
AssetManager assets = AssetManager.class.newInstance();
Method addAssetPathMethod = AssetManager.class.getDeclaredMethod("addAssetPath", String.class);
addAssetPathMethod.setAccessible(true);
addAssetPathMethod.invoke(assets, "path");
Resources resources = new Resources(assets, onrignResources.getDisplayMetrics(), onrignResources.getConfiguration());
Resources.Theme theme = resources.newTheme();
theme.setTo(super.getTheme());
```

activity的代码就没必要贴了，只是简单的子类覆盖父类方法。