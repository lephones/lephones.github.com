title: 用camera类拍照指定图片大小
date: 2014-08-22 14:01:34
tags: [android,相机]
category: android开发
---
## 拍照
在安卓上拍照主要有两种方案:

1.  直接调起系统的照相机拍照片，拍完后，图片会在相册中保存一份，对于程序来说，可以拿到保存照片的路径，从而获取图片。
2.  自己写`SurfaceView`调用相机来实现拍照，用该方法会触发一个回调，回调的参数中包含一个字节数组，里面就是图片信息。

这在网上已经有了好多的资料。


## 问题
按照需求我们采用的是第2种方案，基本的流程就是：拍照--压缩--保存--上传

本来一切挺顺利，但当我遇上小米。。


小米手机在用第2种方式拍照后，默认返回一个`176x144`分辨率的照片。经查资料发现，原来`camera`有一个参数叫`picture-size`，于是给`Camera`对象加了该参数，代码：

```
// 获得相机参数
Camera.Parameters parameters = camera.getParameters();
parameters.setPictureSize(960, 720);
```
当我把这段代码运行到红米上时候，崩了。debug了一下`parameters`参数，发现是硬件限制了，只支持它支持的尺寸。

    picture-size-values=2560x1920,2048x1536,1600x1200,1280x960,640x480,
## 解决方法
又找资料，找到`Camera.Parameters`类下的方法`getSupportedPictureSizes()`，该方法返回一个`List`，包含所有支持的尺寸。
由于太大的也用不上，而且经测试太大会影响拍照速度，太小的尺寸也不可以，所以就直接取了`size()`的一半为索引的值了。浏览我的文章的小伙伴可以根据取到的值,自己算出最适合自己的尺寸，不要使用我的这个糟方法。

```
	List<Size> list = parameters.getSupportedPictureSizes();
	
	if(list.size() >2){
		
		Camera.Size size = list.get(list.size()/2);
		parameters.setPictureSize(size.width, size.height);
	}else{
		Camera.Size size = list.get(0);
		parameters.setPictureSize(size.width, size.height);
	}
	// 设置相机参数
	camera.setParameters(parameters);
```

##说明

`getSupportedPictureSizes()`返回的集合是排好序的，但升序还是降序，也是根据手机来返回的，所以在处理的时候，不能盲目取第一个元素。

另外，小米手机返回的分辨率太小，就是因为它把最小的那个分辨率给了默认值。176x144，尼玛这么小的图片拿来干嘛？
