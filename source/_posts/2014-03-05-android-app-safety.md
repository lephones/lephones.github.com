title: android应用程序的一些安全技巧
date: 2014-03-05 19:29:29
tags: android
categories: android开发
---
## 介绍 ##
做android支付，少不了android的一些安全，如果不说系统，单纯对于APP本身而言，安全性可做手脚的地方很小。简单介绍一下

## 内容的安全 ##
加解密是对内容安全处理最常用的方法了，有`对称加密`和`非对称加密`。关于`对称加密`和`非对称加密`，大家去google查找资料。在开发中，我们常常把加密算法写在JNI层，更保密。

联网时内容的安全，大家一定都知道https，如果不用Https，我们就可以使用非对称加密，做一个伪https。

为了保证数据的完整，可加入签名机制。

## 内存的安全 ##
JAVA的对象的内存是不能主动释放的，而且，字符串对象一旦实例化出来就成为final驻留在内存中，可以通过内存扫描窥探这些信息。所以，我们的一些敏感信息（比如银行卡密码）是不能用`String`的。我们需要使用`char[]`，在不用的时候及时清除这里面的值，`char[]`需要将所有元素改成`\0`。

不能使用 `StringBuilder`， 如果查看 `StringBuilder` 的源码，会发现在对其内部的`char[]`进行扩容的时候，没有把旧的数组清空，做的是`Arrays.copyOf(value,  newCapacity)`，如此还有安全隐患。但，值得注意的是，`delete`方法，是对源数组进行的删除操作。

**即使我们可以通过在`new StringBuilder(capacity)`在创建StringBuilder对象时，指定`StringBuilder`的容量来保证不会使用扩容，`StringBuilder`在`append`的时候，为了安全，参数仍然不能为String，只能是`char[]`**，因此，如果不是要频繁改变，还不如直接使用`char[]`。



## 四大组件安全 ##
### activity ###
activity是最常用的组件，这个组件在用intent指定后，默认是可以被外界来访问的，那么，如何来阻挡外界的访问呢？

在activity注册的时候，加上 `android:exported＝false`属性，就能限制不能被外部程序访问，这里的外部程序指签名不同，用户ID不同的程序，签名相同，用户ID相同的程序执行时共享一个进程空间，相互是没有组件访问限制的。

如果希望activity能够被特定的程序访问，那可以使用自定义`android:permission`，自己在当前activity的该属性指定一个权限字符串，**只有在AndroidMenifest.xml里申明了这个权限的app，才能访问这个activity**。

### Broadcast Receiver###
广播分为无序广播和有序广播，sendBroadcast()是发送的无序的，sendOrderedBroadcast()是发送的有序的。

有序广播接收有优先级的说法，在android API中，说注册时候写的`android:priority`的值是**1000**的时候，是最高的优先级。其实不是，最高是int的最大值，`2147483647`，也就是2的32次方-1，飞信等程序在拦截短信是用的这个值而非1000，可以反编译查看。

	注意：广播在短信拦截的运用，在android 4.4的不适合。

另外，动态注册的广播优先级要比静态注册的高。如果要限定广播发送，可以在广播的intent中指定Class，`intent.setClass(MainActivity.this,DataReceiver.class)`;这样，广播将永远只能被此Receiver接收。

同时，如果跨进程的程序，广播也可以限定权限，方式跟activity一样，在receiver处指定权限，在发送的程序中，要指定该权限，否则不能调用该Receiver组件。

### Service ###
service的方式等同于activity，只是一个是界面，一个是后台，所以，service的防护方法也是通过权限来限制程序的访问。

另外，程序间访问，可以采用AIDL来调用，这样的方式相对安全，目前，支付宝的支付插件正是采用该方式从商户端到支付程序来传递订单数据的，具体可以参考支付宝无线上面提供的接入DEMO，公开的～。如果有做类似这种APK插件的朋友，也可以参考该方法。

### ContentProvider ###
这个组件，可以申明读写权限，会在具体的操作时候，去检查相应的权限，例子：
```
android:name="com.android.myapp.FileProvider"
android:authorities="com.android.myapp.fileprovider"
android:readPermission="myapp.permission.FILE_READ"
android:writePermission="myapp.permissionFILE_WRITE" >
```
ContentProvider我还没在实际中用过，大家应该也用的不多吧，我觉得很少要对外提供大量数据。

## 总结： ##
文章没啥技术含量，只是介绍了在android编码方面的一些小的安全运用技巧。

另外，目前市面上有一种对dex文件进行加壳，然后动态运行dex的方法，它通过反射android framework的一些私有API，将一个加密过的dex文件在运行时解密并动态载入。这种方法对防止APK的反编译，二次打包有一定的效果。但是，缺点就是使用了私有api。这套方案梆梆和爱加密已经作为服务免费对外提供，可了解一下下。