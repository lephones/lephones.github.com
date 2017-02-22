title: 如何使用网页调起APP
date: 2015-10-10 16:56:36
tags: 网页调用APP
category: android开发
---
## 前言
为了推广自己的APP，增加用户黏性，会在浏览器中加入调用自己APP的链接，如果用户没有安装APP，则去下载。淘宝，支付宝，百度手机助手，都有这个功能。简单介绍一下方法
<!-- more -->

## ~~拦截http链接~~
不要用该方法，兼容性差，国内浏览器都不允许跳转
```
<activity android:name=”.MyActivity”>
  <intent-filter>
    <action android:name=”android.intent.action.VIEW” />
    <category android:name=”android.intent.category.DEFAULT” />
    <category android:name=”android.intent.category.BROWSABLE” />
    <!-- 关键所在，匹配相应域名和 url 模式 -->
    <data android:scheme=”http” android:host=”www.xxx.com” 
android:pathPattern=”/xx/.*” />
  </intent-filter>
</activity>
```
其原理就是，对指定的http链接进行拦截，从而达到跳转目的。这种方式还有一点恶心的地方就是会弹出一个弹窗让你选择是用浏览器还是APP打开该连接，如果你选择浏览器并勾选不再询问，如果下次你的URL没有改变，那你就悲剧了。。。

## 使用本地http服务
http://127.0.0.1:8804/xxx

原理:我们都知道127.0.0.1访问的是本机地址，只要我们的应用在本地搭建一个简单http服务器，在网页中用ajax偷偷发一个请求，访问这个地址，APP就能收到消息并处理。目前好多手机助手，应用市场都使用该方法，貌似是一个很好的解决方案，但同样该方法也有弊端：首先，各家应用端口不能冲突，否则就乱套了；其次，你的程序必须能一直在后台启动，不能死掉，否则你的http服务就挂了，我们都知道市面上的手机助手都有守(liu)护(mang)进程，杀不死；另外，该方法因为后台服务需要一直启动，会比较耗电。

找开源项目 NanoHTTPD

## 自定义scheme
与拦截http链接类似,需要修改scheme为自己的scheme
```
<activity android:name=”.MyActivity”>
  <intent-filter>
    <action android:name=”android.intent.action.VIEW” />
    <category android:name=”android.intent.category.DEFAULT” />
    <category android:name=”android.intent.category.BROWSABLE” />
    <!-- 关键所在，匹配相应域名和 url 模式 -->
    <data android:scheme=”yourscheme” android:host=”yourhost” />
  </intent-filter>
</activity>
```
然后你的链接格式就是`yourscheme://yourhost/xxx`这样的格式。

该方法最大的问题就是，如果应用没有安装，怎么办？点击链接就会404

对于应用没有安装的问题，也有解决办法，就是在网页嵌入一个`<iframe>`标签来打开这个连接。这需要编写JS脚本，具体操作如下 :

1. 使用JS代码为网页创建一个`<iframe src="yourscheme://yourhost/xxx" style="disable:none"/>`
2. 在后面加入一句setTimeout方法，超时时间设置为1000，去打开下载地址
3. 该方法同样适合IOS

**注意:**在新的chrome浏览器(chrome 25以后)中，已经不支持用自定义scheme，但是chrome引进一种叫[Chrome Intent](https://developer.chrome.com/multidevice/android/intents "Chrome Intent")，该方式在清单文件中和自定义scheme类似
```
intent:
   //scan/
   #Intent; 
      package=com.google.zxing.client.android; 
      scheme=zxing; 
   end; 
```

```
      <intent-filter>
        <action android:name="android.intent.action.VIEW"/>
        <category android:name="android.intent.category.DEFAULT"/>
        <category android:name="android.intent.category.BROWSABLE"/>
        <data android:scheme="zxing" android:host="scan" android:path="/"/>
      </intent-filter>
```

我们可以在JS代码中判断到底应该生成哪种链接。可以参考阿里系的软件，淘宝，支付宝。在电脑的chrome中打开debug模式，可以模拟各种设备来访问[m.taobao.com](http://m.taobao.com) 和[m.alipay.com](http://m.alipay.com)

简单看了一下淘宝和支付宝网页的源码，感觉复杂点是从UserAgent中来判断系统、浏览器版本、是否支持Chrome Intent等（好像淘宝还对samsung做了特殊处理）

弊端：在第三方软件的webview中会不支持，比如 微信

## 总结
网上好多人推崇第二种方式，但我觉得第二种方式虽然适配简单，但是让你的程序一直在后台运行，也是个技术活。况且，如果在我的手机上一直在后台运行，还杀不死，总有种被强奸的感觉，还TMD耗电！所以还是推崇第三种方式。
