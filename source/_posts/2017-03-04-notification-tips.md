title: Notification通知栏的那些事
date: 2017-03-04 18:48:50
category: android开发
---

# 前言

在安卓开发中，一定会使用Notification。而notification也随着Android版本的升级，一直在变化。这篇blog简单记录一下在Notification开发时，我所碰上的问题，以及需要注意的地方。

# 碰上的问题
## RemoteView的文字颜色
Android的ROM太多了，通知栏的颜色、样式都不尽相同。有的是白的，有的是黑的，这就让我们在自定义RemoteView的时候，不能直去设置文字的颜色，比如设置了白色，在白底的通知栏就没办法显示出文字。

怎么办？

/res/values/styles.xml
```
<style name="NotificationText">
    <item name="android:textColor">?android:attr/textColorPrimary</item>
</style>

<style name="NotificationTitle">
    <item name="android:textColor">?android:attr/textColorPrimary</item>
</style>

```

因为在安卓2.3以上的版本，系统提供了一个默认通知栏的文本颜色值，所以直接拿来用就好
/res/values-v9/styles.xml
```
<style name="NotificationText" parent="android:TextAppearance.StatusBar.EventContent" />
<style name="NotificationTitle" parent="android:TextAppearance.StatusBar.EventContent.Title" />
```

本以为这样就OK了，这块代码一直没有动，直到前几天，测试发现在华为P9上，7.0系统，别人家的通知栏是白色底的，而我家的通知栏是黑色的。。而且有一个诡异的现象就是，在7.0系统展开后一滑动，有一定几率变成白色底。

*于是查啊查，终于发现，原来是gradle里面的`targetSdkVersion`，因为之前一直都是18，改成21以后就成了白色的了。*

白色的倒是变了，但是之前黑色底的文字是白色的，现在成了白色底，却还是白色的文字。不墨迹，直接翻开Notification的源码，找到了默认的layout，终于发现，原来在5.0系统上，默认通知栏文本颜色值又重新定义了。我们需要在v21再加入以下代码

/res/values-v21/styles.xml
```
<style name="NotificationText" parent="android:TextAppearance.Material.Notification" />
<style name="NotificationTitle" parent="android:TextAppearance.Material.Notification.Title" />
```

怎么使用我就不细说了，在layout的textview使用style属性应该都会。

==在EMUI和MIUI上，测试没有通过，发现还是用的v9的值，看来还是需要在代码里判断view的颜色值==

## 点了通知栏不跳转

有一次测试，发现在4.4的手机上，明明配置了正确的PendingIntent，然而，不管怎么点，都不能跳转到Activity，非常郁闷。最后，终于找到了资料。原来，是因为在创建PendingIntent的时候，我们使用了FLAG_UPDATE_CURRENT，在4.4的系统上，用FLAG_UPDATE_CURRENT的时候，Activity必须得是exported=true的才可以。

解决办法：改为FLAG_CANCEL_CURRENT 或者，在清单文件将落地Activity改为exported=true。

## 根布局
我提一个建议就是，根布局使用LinearLayout，为什么呢？因为在有的coolpad的手机上，弹出一个通知后，会在你的通知布局上加一个View，然后让用户选择是否允许弹出，如果我们的布局是RelativeLayout或者FrameLayout，那它加上的两个按钮就会把咱们的控件覆盖掉。

# 7.0的新特性
7.0的系统上，又有了一些新功能，附上google官方的博客介绍文章。
https://android-developers.googleblog.com/2016/06/notifications-in-android-n.html
