title: android 8.0 foregroud-service的坑
date: 2019-12-13 18:15:23
category: android

tag: [android]
---

# ForegroudService

都知道8.0以后，不可以在后台调用startService()来启动一个服务，要想通过startService启动，必须activity在前台时才能使用。当然onResume和onPause状态下的activity都可以。但是，也有一种情况是例外。

https://developer.android.com/about/versions/oreo/background#services

这里在官方文档也有讲，就是： 进入后台时，在一个持续数分钟的时间窗内，应用仍可以创建和使用 Service。 也就是，当你的activity刚进入后台时，是可以调用startService的。

如果不使用startService，就得使用startForegroundService，但是需要绑定一个通知，可以在调用时传入通知id，也可以在调用后，通过startForeground来绑定。

然而，除了以上，还是有一些疏忽了的，需要注意的地方。

<!-- more -->

## 使用了startForegroudService还是有错

做了8.0兼容后，已经把所有的startService都改成了startForegroundService，但是后台还是得到了很多的错误，特别是在android 8.0 和8.1的机子上。

android.app.RemoteServiceException: Context.startForegroundService() did not then call Service.startForeground()

经过排查，测试，发现还有一些需要注意的点，这里大概列一下。



## 可以不调用notify方法

首先，要想启动一个前台服务，必须使用startForegroundService，只要调用了startForegroundService，必须调用startForeground为其设置一个notification。

注意：这里的notification可以不调用notify方法，但是，在调用startForeground后，会自动调用这个notify方法将notification展示出来。



## stopSelf前要startForeground

google文档显示，如果在5s内未调用startForeground，则系统将停止此Service并声明此应用为ANR。那么，5s内如果stopSelf()呢？？亲测，这样也不行，按常理分析，如果直接调用stopSelf可行，是有违ForegroudService的设计初衷的。所以，在stopSelf前，如果想一个startForegroundService调用后直接关闭，也是需要调用startForeground()的。



## stopForeground不要乱用

stopForeground是将一个service从前台改为后台的，如果你中途调用了stopForeground，再次调用startForegroundService时，一但没有走到startForeground，（比如是在onCreate方法中，就不会走到）还是会报出Context.startForegroundService() did not then call Service.startForeground()的异常，所以，看清楚再使用它。







