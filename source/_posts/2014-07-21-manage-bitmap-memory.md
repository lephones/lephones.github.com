title: android中图片内存管理-防止OOM
date: 2014-07-21 22:13:13
tags: [android,内存管理]
category: android开发
---
## 前言
最近，公司有个新需求，需要在地图上的每一个用户头像上，加上该用户当前所行驶的速度。先大概说一下地图上的一些事：

地图上单独加上的一些点（不属于地图本身的信息），我们通常称它们为`marker`，比如在地图上表示你当前的位置的小圆点，比如表示你搜索到的附近的一些点，都会通过`marker`来表示出来。而我们公司的产品，需要在地图上显示用户的头像。其实也是一个`marker`。

本来用户的头像形式只有固定的50来个，就像早期的QQ产品，头像也是不能自定义的。开发人员将这50个头像在程序启动时加载到内存中，等需要用的时候，根据图像类型，取到头像，再将头像创建成`marker`添加到地图上。

初期，所有的用户只有50个小图，不管怎么加，缓存也只有那么一丢丢。但是，新需求来了，现在需要我们在用户头像上面加一行字，表示当前用户正在地图上行驶的速度。创建地图所需要的`marker`,必须是一张图片，也就是一个`bitmap`对象，现在要在地图上加字,肯定得我们自己通过`cavans`来添加了，等于一个用户有一个`bitmap`对象，一但刷用户的速度太快，同一时间内创建的头像`bitmap`对象太多，就容易引发`OutOfMemory`。通过测试，事实也确实如此。

## 软引用 弱引用

在JAVA上，有一种很流行的内存缓存技术，就是用弱引用（`WeakReference`）或者软引用（`SoftReference`），而android早期，也是用这种方式实现缓存。但是，官方介绍，从`android 2.3`，也就是`API 9`开始，垃圾回收器更倾向于回收持有软引用或弱引用的对象，这让软引用和弱引用变得不再可靠。另外`android 3.0` `API 11`中，图片的数据会保存在本地的内存中，所有软引用、弱引用不再适合。

## LruCache

`LruCache`是android新的API，需要导入`android-support-v4.jar`，相信大家都知道这个jar包。此类适合用来缓存图片，它的主要算法原理是把最近使用的对象用强引用存储在 LinkedHashMap 中，并且把最近最少使用的对象在缓存值达到预设定值之前从内存中移除。

示例代码：

```
private LruCache<String, Bitmap> mMemoryCache;

@Override
protected void onCreate(Bundle savedInstanceState) {
	// 获取到可用内存的最大值，使用内存超出这个值会引起OutOfMemory异常。
	// LruCache通过构造函数传入缓存值，以KB为单位。
	int maxMemory = (int) (Runtime.getRuntime().maxMemory() / 1024);
	// 使用最大可用内存值的1/8作为缓存的大小。
	int cacheSize = maxMemory / 8;
	mMemoryCache = new LruCache<String, Bitmap>(cacheSize) {
		@Override
		protected int sizeOf(String key, Bitmap bitmap) {
			// 重写此方法来衡量每张图片的大小，默认返回图片数量。
			return bitmap.getByteCount() / 1024;
		}
	};
}

public void addBitmapToMemoryCache(String key, Bitmap bitmap) {
	if (getBitmapFromMemCache(key) == null) {
		mMemoryCache.put(key, bitmap);
	}
}

public Bitmap getBitmapFromMemCache(String key) {
	return mMemoryCache.get(key);
}

```

使用`LruCache`，需要分配一个缓存大小，这个值不能大，大了占用太多，不能小，小了增加删除操作太多。另外，`LruCache`的API大家去查文档吧，除了`sizeOf`，回调的方法还有`create`，`entryRemoved`。另外，还有一些移除，获取数量的常用方法，一看就懂，不解释。

## 优化小提示：
- SparseArray：如果你用的`HashMap`，并且，你的`key`是`Integer`，那么用它吧。
- 关于弱引用和软引用：其中，软引用的对象，内存不足时，会优先回收它。弱引用的对象，当垃圾回收器扫描到该对象，就立即回收。当然，如上所说，在`android 2.3`以上的系统除外。
