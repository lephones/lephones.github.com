title: jenkins中实用的插件
date: 2020-02-15 02:27:04
category: jenkins

tag: [jenkins]
---

# 记录

最近疫情闹的有点凶，大家都是在家办公，刚好群里的一个妹子一边卖萌，一边问jenkins的搭建及使用，就用腾讯会议给辅导了一下。给她讲完后，翻了翻之前给公司搭建的环境，想记录一下之前使用过的Jenkins插件，供以后使用。

暂时就这些，有好用的插件会不定时更新。

## 自带插件
安装的时候，会提示你要选哪些插件，建议默认，像git svn以及gradle，这些插件会在默认插件列表里就存在。
## Git Parameter
可用于把git的tag branch当作构建参数传进来，方便使用branch构建。
## SVN Parameter
同Git Parameter 一样是可以将tag branch当作构建参数传进来。

<!-- more -->

## Multiple SCMs plugin
可以加多个源码的插件，比如我们项目就是资源单独有一个SVN，所以要把代码checkout以后，再checkout资源。

## Environment Injector Plugin
可以在构建时注入一些环境变量，这款插件有一个好处就是，它支持`Prepare an environment for the run`，可以在SCM以前注入变量，比如我们有个资源的svn地址，需要在构建时传进来然后checkout。为了更直观，参数默认值就留了空。有了这个插件，写了groovy脚本，手动将空值改成了默认资源地址，SCM那里直接使用参数名就OK了。

## Version Number Plug-In
用于自定义构建记录的名字的插件，使构建记录更直观，不再是#1 #2这种格式。

## Build Keeper Plugin
可以按天数保留几天内的构建，没什么大用，如果硬盘紧张，推荐使用自带的Discard old builds

## Role-based Authorization Strategy
按项目分权限，比如某个project不想让某人访问到，可以用这个插件。

## Copy Artifact
可以将上游JOB构建后生成的Artifact，复制到下游的JOB来使用，比如上游的JOB生成的apk。

## Validating String Parameter Plugin
用于参数校验的插件，像产品打包的时候versionCode总是喜欢空着，说多少次都不长心，还让开发看一下为什么打包失败，最后就使用了这个插件，输入时校验。


