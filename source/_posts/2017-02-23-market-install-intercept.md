title: 应用市场的尔虞我诈（突破华为安装时来源检测）
date: 2017-02-23 18:38:50
category: android开发
---

# 前言

去年年底的时候，产品妹子拿着一部华为手机来找我们组，这部手机在安装应用的时候，会显示安装来源，同时，对包进行了扫描检测。但是有一个奇怪的现象是，同一款应用，安装过程不同。
1. 从我们市场安装，则显示出市场名字，并提示建议从官方市场安装，用户必须勾选允许才能安装，不然只能取消或去华为商店下载。
2. 从豌豆荚中安装，显示的是未知来源，没有提示从官方市场安装。
3. 从360手机助手、应用宝安装显示出市场名字，提示通过安全检测。

这个安全引导在一定程度上能将我们的流量直接导入到官方市场下载。应用市场就是靠下载、安装的流量转化来赚钱的，而在安装的时候，ROM方就设置一些门槛，将量转化到自己的市场里。而且从上面的结果猜测，360和应用宝明显是走了公关渠道，而豌豆荚则是使用了黑科技。

附上对比图：
![我们的APP](/image/20170223/our.jpg)![360手机助手](/image/20170223/360.jpg)

# 研究黑科技
初步猜测是安装的时候，豌豆荚传递了某个参数，导致不能获取到来源的包名。因为安卓可以拦截安装的action，在安装前对包进行处理。配置如下intent-filter
```
<intent-filter>
	<action android:name="android.intent.action.VIEW"/>
	<category android:name="android.intent.category.DEFAULT"/>
	<data android:scheme="file"/>
	<data android:mimeType="application/vnd.android.package-archive"/>
</intent-filter>
```

安装的时候，会提示使用系统安装器，还是用你的程序。debug后发现intent的extra传了一个叫`caller_package`的参数。发现豌豆荚是传递了`com.google.launcher`。这个包是没有在手机上安装的（其实市场上也没有这个），所以显示未知来源。

于是在我们调用安装时加入了上面的参数。后来发现上面的这套方法，貌似只对应用有用，毕竟商业化的主要靠游戏。游戏安装暂时无解，放弃了。

# 新黑科技

上周五，产品妹子又来找我说，360手机助手在安装游戏的时候，有一个允许拦截网络的弹窗提示，只要取消了这个弹窗，一样会提示未经过官方市场检测提示，并推荐从官方市场安装。而如果在弹窗中点了允许，在安装的时候，就能绕过去。

这个弹窗就是VPN权限，之前并没有了解过`VpnService`，找了找资料。
[http://blog.csdn.net/jsqfengbao/article/details/52462125](http://blog.csdn.net/jsqfengbao/article/details/52462125)

简单说一下，Android中的Vpn框架并不是能直接让你连接另一个网络，只是将手机的流量都截获过来，具体用来做什么，框架中并没有实现。不过，这里只需要的是拦截网络，在无网的状态下，来源检测默认是通过。开启VpnService以后，状态栏会有一个钥匙的标识。

360手助和应用宝都有这个功能，在调用安装的时候，先启动VpnService，断掉了华为安装器的网络，导致在检测的时候，是无网的状态。

关于VpnService怎么使用，上面附上的文章有demo，这里只说一下如何断掉指定APP的网络。不推荐去分析网络包，虽然兼容性好，但太复杂，工程量太大。在`VpnService.Builder`中，有一个方法叫`addAllowedApplication`，将包名传递过去，就会让这个包的流量走你的VpnService，其它就不用处理了，反正是只要断开它的网。特别注意的是这个方法只在API 21以上的版本有。

效果图：
![加入VPN功能](/image/20170223/our-vpn.jpg)

# 后续
昨天，给产品妹子发了个停安装器网络的demo，妹子和我说，她今天又试了一下，发现360手机助手在安装游戏的时候，弹窗点了取消，又能通过检测正常安装了。。。

猜测上周五，要么是停掉了允许通过的接口，要么就是有什么协议，某些时候可以转换转换量，哈哈，Interesting...

不管怎么样，黑科技还是好的。

# 附

关于OPPO修改安装来源，又封装一下Intent
```
Intent actIntent = new Intent("oppo.intent.action.INSTALL_PACKAGE");
Intent intent = new Intent(Intent.ACTION_VIEW);
intent.putString("oppo_extra_pkg_name",packageName);
//intent.setDataAndType
//intent.setFlag
actIntent.putExtra("android.intent.extra.INTENT", intent);
```
