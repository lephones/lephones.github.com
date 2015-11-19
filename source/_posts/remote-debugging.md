title: android开发中如何调试webview中的网页
date: 2015-11-19 16:56:36
tags: webview
category: android开发
---
在浏览器中，如果我们想要看到一个网页的代码，只要按f12就可以轻松进行调试，但是在手机中，直接在手机浏览器上调试是肯定不行的。

###为什么要在手机中调试网页
普通的网页，我们在chrome中就能模拟手机环境。但是在android的webview中，有些是需要和native代码进行交互的，比如说注入的js，有时候我们还会用些模板来动态生成html，所以只有在手机上真正展示出来的效果才是最终的网页代码，必须在手机上调试。

<!-- more -- >

##解决办法
google就为我们提供了调试手机中网页代码的方法，此方法只在4.0以上的手机有效。

1. 最新的chrome浏览器
2. adb连接手机需要的usb驱动
3. 4.4系统以上的手机

首先，你的电脑能连上你手机的开发者模式，在chrome中输入[chrome://inspect](chrome://inspect "chrome://inspect")，如果你的连接没问题，就能在下面发现你的手机弄号。

在你的程序中加一句
```
if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
    WebView.setWebContentsDebuggingEnabled(true);
}
```

通常，只要在代码中加入如下代码，就可以在测试和生产环境中不用修改了
```
if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
    if (0 != (getApplicationInfo().flags &= ApplicationInfo.FLAG_DEBUGGABLE))
    { WebView.setWebContentsDebuggingEnabled(true); }
}
```

现在跑起来你的程序APP到webview，在chrome中，就会看到你的设备下面有你的网页，点击`inspect`就能在chrome中像普通网页一样debug了。


参考：[https://developers.google.com/web/tools/chrome-devtools/debug/remote-debugging/webviews](https://developers.google.com/web/tools/chrome-devtools/debug/remote-debugging/webviews)

备注：如果你只想调试网页，在手机上下载chrome for android，只要4.0以上的机子就行了。
