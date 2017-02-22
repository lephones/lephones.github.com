title: android使用ant打包成SDK
date: 2014-12-02 12:54:07
tags: [ant,sdk]
category: android打包
---
## 前言
最近看到好多朋友搜索android打包sdk进到我的BLOG，可能是因为我前些BLOG的关键字吧。但是，其实是没有一篇BLOG来讲如何打SDK的。

在这里我就简单说一下打SDK的方法。


讲打SDK之前，先说一下APK打包流程。不管是用脚本打包，还是ADT自带打包，其流程都是先将java源码编译，混淆，再打成jar，再将jar转成dex，编译资源，打包，压缩，签名。

对于SDK，其实我们只需要执行到打成jar这一步就OK了。

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
