title: 是否允许创建快捷方式的权限检测
date: 2017-05-19 15:02:50
category: android开发
---

# 前言
部分手机的权限管理里，会有一个创建快捷方式权限。近期，产品妹子发现360手机助手可以检测到权限并弹出引导提示，符合的机型有，小米，VIVO，华为。于是我们也得加啊。。。

# 调研

## MIUI:

小米手机root方便，root后，直接看到了权限管理的配置的值，小米上，通过AppOpsManager的checkOpNoThrow()可以检测到是否有快捷方式权限。至于op的值是多少，我就不写了，自己查一查。

## vivo
找到了vivo的launcher的所有快捷方式所在的ContentProvider，`content://com.bbk.launcher2.settings/favorites`遍历了一圈发现了一个字段叫`shortcutPermission`，修改了权限后，这个值会有变化。

有趣的是，初始化假如是禁止的情况，它的值是1，但是只要编辑过，就会变化成16（允许），17（禁止），18（询问，部分手机有这个选项）。

<!-- more -->

## EMUI

最坑的是EMUI，用尽各种招数，都没有搞到到底是如何检测的权限。因为发现，在权限为询问的时候，创建快捷方式时，360助手会弹出两次系统询问的弹窗，而只在第一次点禁止时，APP才弹出提示。如果第一次点了允许，第二次不管点了禁止还是允许，都会记为已经创建过。

起先，怀疑是监听了快捷方式创建的广播，后来发现，如果是监听的快捷方式的广播，点禁止后，不能知道是点了禁止，需要用handler调用sendMessageDelayed()，而在receiver收到广播后，再removeMessage。这种方法导致的结果就是delay的时间不可控，另外，其实也不需要弹出两次权限询问的弹窗。

思考后，打算从sendBroadcast()方法入手，看看sendBroadcast到底做了什么操作，想到了用`traceview`，果然有如下发现。

![](/image/20170519/huawei-permission.jpg)

图片中，可以看出它调用了一个`HwSystemManager.canSendBroadcast(Context context,Intent intent)`

最终定位到
`com.huawei.hsm.permission.PermissionManager.canSendBroadcast(Context context,Intent intent)`

利用反射，发现该方法返回了boolean类型，允许就是可以true，禁止就是false。而且，如果是询问，该方法会弹出权限询问弹窗，阻塞你的APP的主线程，用户点了禁止或者允许，再接着往下执行，相当好用。


代码我就不上了，该写的点都写了，实在需要的可以走点 关于 找到我。
