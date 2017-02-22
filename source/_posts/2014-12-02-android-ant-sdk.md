title: android使用ant打包成SDK及资源处理
date: 2014-12-02 12:54:07
tags: [ant,sdk]
category: android打包
---
# 前言
通常的android项目，都是以apk的形式对外发布的，但有一部分程序，是做为二次开发包提供给其它开发商的，例如，淘宝SDK，新浪微博SDK。笔者参与公司的一款支付插件的开发与维护，最终打包成**jar**+**res**的格式(与支付宝支付提供的支付不同。支付宝的交易功能，也是一个APK，商户接入后，通过AIDL调用支付)。以这款插件为例，讲解一下资源文件的处理。

在这里我就简单说一下打SDK的方法。

讲打SDK之前，先说一下APK打包流程。不管是用脚本打包，还是ADT自带打包，其流程都是先将java源码编译，混淆，再打成jar，再将jar转成dex，编译资源，打包，压缩，签名。

对于SDK，其实我们只需要执行到打成jar这一步就OK了。

#打包jar
## 方法一

使用eclipse导出jar包：我们知道一个java项目是可以用eclipse导出jar包的，安卓工程也一样，只要按普通的方法export就可以了。不过，export出来的包是没有混淆过的，如果你要混淆，还需要单独对你的jar包执行一次proguard程序，可参考proguard使用指南。

## 方法二
使用脚本打包：我个人比较喜欢该方法，因为android工程项目并不是只有JAVA代码，有的资源也需要提供出来，而使脚本可以更加定制化一些。

android的SDK默认提供了一个ant打包的脚本，具体使用方法，可参考之前的BLOG，[使用ant打包APK及依赖包最佳解决办法](/2014/10/13/ant-apk-with-lib/ "使用ant打包APK及依赖包最佳解决办法")

我们可以看出，打包，最终调用的其实是android sdk下的ant脚本，既然安卓已经帮我们写好了ant脚本，我们就好好利用。

使用上面的BLOG中介绍的方法，先在工程目录中生成你的build.xml，然后自己写一个target

```
<target name="sdk"
            depends="-set-release-mode, -release-obfuscation-check, -compile, -post-compile, -obfuscate">
</target>
```
这段target代码，就是只执行到了混淆的脚本。然后我们在build.xml中选择右键，run as， 第二个ant Build，然后选择要执行的target为我们加上的sdk。

等执行完成后，就会在`project/bin/proguard/obfuscated.jar`找到你所要的jar包。

## 优化
我们其实没有在target中增加任何逻辑的，现在我们可以加进去一些脚本，比如把你的jar和资源打包成一个zip包，或者做一些其它自定义的事。

## 后续
- 我没有试项目依赖，通常一个做为sdk的项目本身就很小了，很少再有lib project的依赖关系。可能需要更改脚本。
- 我发现很多朋友都在百度搜索android如何打SDK包，其实大家只要多了解一下打包原理，流程，打APK和打SDK没什么区别。

#打包资源
jar包打好了 sdk中还有资源文件
## 资源文件的处理 ##
在插件项目中，资源文件的引用不能再以`R.XX.XXXX`这样的格式来使用，因为这种代码在编译的时候， 会用具体的int值来替换掉代码，当你的项目在别人的环境下重新编译，资源对应的id就被改了。

### 解决办法：

将`R.xx.xxx`用方法替换。代码如下：
```
class ResLink{
   public static int getIdXXXXX(){
       return R.xx.xx;
   }
}
```



**方法一：**将ResLink的源码也提供给商户，这样，可以将R的常量的替换放到商户的项目编译时，保证id不紊乱。但要删除你的JAR中的该类的class文件

**方法二：** 使用资源名称。Resource类提供了一个叫`getIdentifier()`的方法，该方法可以根据资源的名称和类型来获取具体的值。 

**方法三：** 为自己的资源固定id，查看android的`R.java`文件，可以发现生成的资源id常量值都是0x7f开头。其实，这个id的组成是 package + type + value ，其中，应用的资源生成的id都是7f开头的。而android提供了一种资源类型叫`public`，用法：
```
<resources>
    <public type="id" name="xxx" id="0x7f040003" />
<resources>
```
这样，aapt在编译的时候，会自动将该资源指定固定的id。如此一来，就可以在代码中用R.xx.xxx了。

## 总结 ##

方法1中，编译时候及时报错，商户接入相对麻烦，必须指定类放入到指定包下才可以。

方法2中，资源全部以`string`的形式指定，如果资源有改动，每次新加都得手动添加其名字和类型，如果添加的多了，再删除，操作起来相当麻烦，而且都不知道哪些用到哪些没用到，即使没有这个资源也不会在编译时报错。

方法3中，完全指定了资源，可以用`R.XX.XXXX`来直接使用，在提供给二次开发商的时候，`public.xml`资源也会提供出去，这样，编译时候不会造成id冲突，相当于强制锁定了资源id。

以上3种方法中，我使用的是方法二，而且我发现很多家都是使用的该方法，尽管它对管理资源名称比较麻烦，但它是唯一的一种不以来R文件的办法。

**不想把资源直接发给商户？**请浏览这里**[android如何将资源打入jar并对资源进行保护](http://www.lephones.net/2014/10/28/res-safty-in-sdk/ "android如何将资源打入jar并对资源进行保护")**，下面补充的方法在这个里面也讲了。

## 补充 ##
### 方法四 （未试）###
该方法思想来源插件化框架，有兴趣的朋友可以尝试一下，原理就是动态创建资源对象，替换掉资源的来源
1. 首先所有的组件都得继承base类。如activity继承BaseActivity。
2. 重写3个方法getResources() getTheme() getAssets()，返回值参考下面代码块对应的变量来return（没有贴完整的实现，大家也不要光找现成的吃，多动手），注意里面的PATH，另，拆分后，部分字段需要用调用getAssets()getResources()方法替代
```
AssetManager assets = AssetManager.class.newInstance();
Method addAssetPathMethod = AssetManager.class.getDeclaredMethod("addAssetPath", String.class);
addAssetPathMethod.setAccessible(true);
addAssetPathMethod.invoke(assets, PATH);
Resources resources = new Resources(assets, onrignResources.getDisplayMetrics(), onrignResources.getConfiguration());
Resources.Theme theme = resources.newTheme();
theme.setTo(super.getTheme());
```
3. 打包成APK，删除掉dex，只保留资源；再把源码打成jar，和只有资源的APK一并提供给商户。
4. PATH，是资源APK的路径，可以选择让商户放到asset下，运行时可以复制/data/data/packagename下面，这就需要在调用SDK的组件之前，手动复制了。

