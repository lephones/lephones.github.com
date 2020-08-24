title: android进程保活（掌握黑心科技）
date: 2020-08-24 21:31:23
category: android

tag: [android]
---

# 进程保活

android这个生态真的是不好，从一开始，大家就想方设法在后台常驻，为了让自己app不被杀，绞尽脑汁想各种存活办法。

目前，之前用的大部分保活方案，在手机上几乎都是失效的，尤其是一些国内厂家机型，提供一键清理功能，把你正的运行的APP，杀的渣也不剩。

所以，目前还能正常使用的方法就只有一种，那就是两个进程互相监听。

# 技术原理

B发现A死了后，赶紧把A拉活，然后再把自己杀死，这样达到瞒天过海的效果。

## 启动子进程

方案一：就是fork。fork会分离出一个子进程，在fork的地方开始执行接下来的工作，可以根据fork函数返回值来判断是主进程还是子进程。这里提到的另一个概念就是二次fork，关于二次fork和进程托孤，可以自行上网了解一下。

方案二：使用app_process命令启动一个java进程。https://blog.csdn.net/u010651541/article/details/53163542

```
app_process dir --application --nice-name=nice_name
```



## 两个进程如何互相监听

这里有一个相当巧妙的方式，使用linux提供的函数。

```
int flock(int fd,LOCK_EX);
```

具体用法请自行搜索，简单讲，A进程调用该函数后，此时B进程再调用，会造成B进程阻塞。而当A进程挂了后，B进程就会立马继续执行。

## 如何拉活APP

要获取ams的IBinder，然后调用transact来启动组件。这里给大家提供源代码的路径，这里需要用反射。

```
mRemote = android.os.ServiceManager.getService("activity")
mRemote.transact(code,data,null,FLAG_ONEWAY);
```

这里有两部分需要处理，一个是code值，另一个就是data。关于code值，不同的安卓版本不一样，另外有的rom也会修改，翻看源码android.app.IActivityManager。

关于data，也会根据不同的系统版本有不同的拼装方法。我这里以service为例。具体参数，也可以参考源码，下面的写法也是根据IActivityManager不同版本中的startService写的。

```
        mServiceData = Parcel.obtain();
        mServiceData.writeInterfaceToken("android.app.IActivityManager");
        mServiceData.writeStrongBinder(null);
        if (Build.VERSION.SDK_INT >= 26) {
            mServiceData.writeInt(1);
        }
        //这个是service的intent
        serviceIntent.writeToParcel(mServiceData, 0);
        mServiceData.writeString(null);
        if (Build.VERSION.SDK_INT >= 26) {
            //fg service
            mServiceData.writeInt(1);
        }
        if (Build.VERSION.SDK_INT >= 23) {
            String packageName = serviceIntent.getComponent().getPackageName();
            mServiceData.writeString(packageName);
        }
        mServiceData.writeInt(0);
```

我声明一下，service保活在部分手机上可用。



# 说明

其实有比较完善的demo，保活效果很不错，但这个话题有点敏感，不想放，写这篇blog就是记录一下其中的一两个点关键。本文只有一些支离破碎的片段，不想搞的整个环境乌烟瘴气，手机里一个个APP成了流氓软件，也防止引发一些其它纠纷。

这个黑科技，还是有点恶心人的。





