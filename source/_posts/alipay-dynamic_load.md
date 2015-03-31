title: 探究支付宝android客户端的动态加载
date: 2014-09-29 16:15:14
tags: [android,动态加载,插件化]
category: android开发
---
在早期的支付宝android客户端中，也有插件化的功能。大概的做法就是，自定义所有的UI控件，再通过XML文件，仿安卓原生XML的布局文件来搭建布局，再通过自定义的表达式解析器，利用JAVA的反射特性来给具体的控件添加不同的功能。这样也达到了插件化。

之前写过一篇文章，说的是支付宝的插件化。其实这篇文章很老了，现在的支付宝早已不是这种做法。最近几天忙里偷闲，反编译了一下支付宝的插件化。
<!-- more -->
在下资历不高，简单分享一下，大牛看到也不要喷我，在下也是在探索学习中，欢迎交流！


##工具：
工欲善其事，必先利其器。因为平时拆包少，对某些好工具也了解不多，基本用了手工的方法来处理的。大家可以用什么APK改之理之类的工具。

- `apktool`：这个大家都知道，反编译利器，我下的是apktool_2.0.0b9版本
- `dex2jar`：不是必须，但看smali代码太累，用这个工具好受一些
- `jd-gui`：不解释
- `Replace Studio`：文本搜索工具，可以搜索某文件夹下的文件是否有某文本，我一直用这个，不知道大家有没有其它好工具推荐。
- `notepad++`：如果你用记事本也可以
- `android环境`：这个必须，你看完它的代码了，你起码得自己写的试试吧

##简单拆包分析
先copy一份apk出来，改后缀名为zip，直接解压，先瞧瞧里面的内容，发现在/lib/armeabi/下的so文件相当的多，有蹊跷！

![](/image/alipay/so_list.jpg)

出于习惯，立马就拿notepad++打开了，结果发现，在文本的最前边是`PK`开头的两个字符，哈哈，这绝对的是一个zip文件，我们都知道apk其实就是一个zip，而且，真正的so文件应该是以`ELF`开头的。随便找一个打开，发现了APK的结构：

![](/image/alipay/so_is_apk.jpg)

该上工具了，一步到位。对支付宝主APK进行拆包，使用`apktool d xxx.apk`命令，直接拆成smali，再使用`dex2jar`命令拆成jar包，再保存成java文件。
打开`AndroidManifest.xml`文件，找到`application`

	com.alipay.mobile.quinox.LauncherApplication

用jd-gui打开jar包，找到该类，查看onCreate方法，找到这段代码
![](/image/alipay/application_create.jpg)

代码中反射的`mPackageInfo`其实就是有名的`LoadedApk`类。

使用`Replace Studio`在生成的java文件目录下搜索`pathClassloader`

我发现在com.alipay.mobile.quinox.classloader下有两个类继承自该类。

通过对smali代码的注入log日志的跟踪，JAVA文件和smali文件相互对照（因为不是所有的class都能反编译回来），我大概整理了一些逻辑与类的结构。

##安卓动态加载原理

支付宝把一个一个插件称为bundle，在`application`的onCreate方法中，反射`mPackageInfo`中的`mClassloader`字段，该属性是一个pathClassloade，将其替换成自己的PathClassloader（这段代码在dex2jar后的代码中看不到，我是直接读的smali代码）。

在自定义的PathClassloader中处理，如果是自身dex中的类，则用原pathClassloader加载，如果是bundle，则用bundle的`dexfile.loadClass`来加载

- `BundleClassloader`：继承自classloader，用于加载具体的某个插件，包含一个DexFile文件引用，重写了loadClass方法，通过调用dexFile.loadClass("className" , classLoader);
- `HostClasloader`：继承自PathClassloader，包含一个系统的pathClassloader，也就是加载apk本身的pathClassloader
- `BootstrapClassloader`：继承自`PathClassloader`，该类中包含一个map集合，保存着一个一个的`BundleClassloader`，同时包含一个HostClasloader，该类就是自定义的pathClassloader，通过反射将原来的mClassloader替换成该类。
- `OriginClassLoader`：继承自classloader，也就是上图中new的c，ClassLoader.class的`parent`成了该对象。重写了findClass方法，调用了对android原生的类和APK中的类加载做了分发处理，APK中的类调用`BootstrapClassloader`的`loadClass`方法返回。

##关于资源
使用反射创建一个AssetManager对象， 使用`getDeclaredMethod`后调用`addAssetPath`方法，先用`getApplicationInfo().sourceDir`做参数调用该方法，再用bundle的路径调用该方法，这样就能整合到一起。
```
//先反射创建一个AssetManager对象 
//反射得到addAssetPath
//调用addAssetPath并把当前APK的路径传进去，也就是sourceDir
//调用addAssetPath并把子包的APK路径传进去
//使用下面的代码创建出Resources
//用反射替换掉 mPackageInfo 的mResources字段
Resources rs = getResources();
new Resources(assetManager , rs.getDisplayMetrics(), rs.getConfiguration())
```
使用反射替换掉 `mPackageInfo` 的`mResources`字段

##代码

我只写了一下动态加载activity的代码，具体的资源我没有加载，小伙伴们可以自己试试。

activity我没有添加，大家可以添加到主工程下，也可以添加的被加载的工程下，不过一定要记得在`AndroidManifest.xml`里注册

```
public class MyApplication extends Application {

	private Field field;

	@Override
	public void onCreate() {
		super.onCreate();

		Context context = getBaseContext();

		Field localField1;
		try {
			localField1 = context.getClass().getDeclaredField("mPackageInfo");
			localField1.setAccessible(true);
			Object mPackageInfo = localField1.get(context);
			field = mPackageInfo.getClass().getDeclaredField("mClassLoader");
			field.setAccessible(true);
			Object mClassLoader = field.get(mPackageInfo);
			ClassLoader loader = new MyPathClassLoader(this,
					this.getApplicationInfo().sourceDir,
					(PathClassLoader) mClassLoader);

			field.set(mPackageInfo, loader);

		} catch (Exception e) {
		}
	}
}


```

下面是我的Classloader 比较粗糙

```
public class MyPathClassLoader extends PathClassLoader {

	private ClassLoader mClassLoader;
	private Context context;
	public MyPathClassLoader(Context context,String dexPath, PathClassLoader mClassLoader) {
		
		super(dexPath, mClassLoader);
		this.mClassLoader = mClassLoader;
		this.context = context;
	}
	
	@Override
	protected Class<?> findClass(String name) throws ClassNotFoundException {
		File file = new File("/data/data/com.example.test/lib/libtest.so");

		Class clazz = null;
		try {
			clazz = mClassLoader.loadClass(name);
		} catch (Exception e) {

		}
		if (clazz != null) {
			return clazz;
		}
		try {
			DexFile dexFile = DexFile.loadDex(file.getAbsolutePath(), context
					.getDir("dex", 0).getAbsolutePath() + "/libtest.so", 0);
			return dexFile.loadClass(name, ClassLoader.getSystemClassLoader());
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		return super.findClass(name);
	}

	
}

```

##其它

支付宝之前的做法利用自定义表达式解析器，对JAVA程序员的学习成本相当高，后来支付宝就换成了该方法。

优点：

1. 使用同一个Context，还是同一个应用，相当灵活
2. 能解决打包时候method ID not in [0, 0xffff]: 65536的问题
3. 使用反射少

另外，该方法的缺点：

1. 用到的组件**必须在manifest.xml中声明**，我们并没有突破manifest的验证
2. 使用了反射私有API，尽管反射使用的不多。
3. 资源文件处理，如果bundle中的id和主工程下的id冲突了就悲剧了。支付宝自己修改了aapt的源码，把资源`0x7f010001`前面的7f改了。所有应用的生成id都是7f打头的，该方法不修改aapt办不到，会给你自动改回来。一般我们也可以通过public.xml下指定id

##说明：
同是阿里系的淘宝网有一套框架叫atlas，该框架是一套重量级框架，完全突破了manifest的封锁，不同的bundle使用的不同的context。
##后记
其实支付宝也突破了manifest文件，采用的是代理的模式，注册一个CommonActivity，在各生命周期的方法中调用targetActivity的方法。再利用反射将CommonActivity中的变量赋值到插件中targetActivity中（用遍历就能满足），此方法有个缺陷就是，在插件中的activity中，要慎用this关键字，必要用的时候，得用其它方法取CommonActivity对象。