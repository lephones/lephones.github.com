title: APP如何只获取一次root权限
date: 2014-11-21 10:55:22
tags: [android,root,su]
category: android开发
---
## 引言
最近和小伙伴们讨论到root权限，说有的App只需要请求一次root权限，便可以长期拥有root权限，可以为静默安装等一系列操作开绿灯。

通常我们的手机root后，会有一款叫superuser.apk的软件来管理root权限，所谓的获取root权限，就是让superuser允许你的app。只要了解了superuser的原理和root的原理，就不在话下了。

<!-- more -->

## 参考项目
SuperUser是开源项目，点击这里：[http://superuser.googlecode.com/svn/trunk/](http://superuser.googlecode.com/svn/trunk/)

root原理自行百度

## SuperUser简述
通常SuperUser.apk是安装到/sysytem/app/下的，拥有修改su的权限，只要你打开了superuser，就会将它的su文件替换到/system/bin/目录下，当其实APP需要请求root时，就会调用superuser替换过的su命令，superuser再根据白名单来判断是否放行。可参考superuser项目中su的源码。

## 原理
其实原理很简单，就像我们拿到root权限后，可以随便卸载app（包括superuser），也可以随便删除文件，比如删除掉su，当你没有了4775权限的su文件，又没有superuser这种可以修改su文件的APP，那就等于没有root了。

而只请求一次权限的App拥有类似superuser一样的操作，首先会请求root权限，一旦拥有root权限后，也就有了/system/bin/目录的修改权限，会将原来的su替换成自己的su，替换后，superuser的权限管理也就失效了。

至于有没有做恢复su文件的行为就不得知了，或者只是将原来的su做个备份，在自己的su中做个判断，如果是自己的程序，就直接跳过，否则，走替换前的su。

没有demo！

## 哎
个人用的手机，还是不要root的好。

