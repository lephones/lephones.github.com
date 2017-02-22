title: 编译Android源码，使用hide api和internal api
date: 2016-07-26 19:00:46
tags: [android,source]
category: android开发
---
# 前言
因为项目需要，有部分代码调用了Hide api，需要没有被阉割的android.jar。对于5.0以前的系统，这个jar可以从手机的framework.apk中提取，利用dex2jar变成jar，再覆盖SDK中的jar包中相同类名（sdk中有些类不是framework下的，framework只是一个模块，需要覆盖合并）。从5.0以上开始后，这个方法就不行了，必须自己生成jar包来使用。

# 官方说明
[https://source.android.com/source/index.html](https://source.android.com/source/index.html)
[https://mirrors.tuna.tsinghua.edu.cn/help/AOSP/](https://mirrors.tuna.tsinghua.edu.cn/help/AOSP/)
<!-- more -->

# 环境搭建
```
# fetch source
sudo yum install git
sudo yum install wget
# to compile
sudo yum install java-1.7.0-openjdk
sudo yum install java-1.7.0-openjdk-devel
sudo yum install glibc.i686
sudo yum install libstdc++.i686
sudo yum install bison
sudo yum install zip
sudo yum install unzip

```

编译时候，如果提示找不到某个.so库，可以使用yum whatprovides 这个命令来搜索缺少的软件
如我的就缺少 ld-linux.so.2(因为我没有按上面的包来安装，都是编译时候缺少什么装什么软件)
```
yum whatprovides ld-linux.so.2
```

安装某个软件提示protected multilib version    yum --setopt=protected_multilib=false

libz.so.1 zlib-1.2.7-13.el7.i686


# 过程
下载repo
```
mkdir ~/bin
PATH=~/bin:$PATH
curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod a+x ~/bin/repo
```

创建工作目录
```
mkdir WORKING_DIRECTORY
cd WORKING_DIRECTORY

```

初始化仓库，这里需要连接google，我走了代理，没有修改REPO，不清楚修改repo行不行
```
repo init -u https://aosp.tuna.tsinghua.edu.cn/platform/manifest
## 如果提示无法连接到 gerrit.googlesource.com，可以编辑 ~/bin/repo，把 REPO_URL 一行替换成下面的：
REPO_URL = 'https://gerrit-google.tuna.tsinghua.edu.cn/git-repo'
```

下载，同步源码
```
repo init -u https://aosp.tuna.tsinghua.edu.cn/platform/manifest -b android-6.0.1_r1
repo sync
```

设置代理，我没有使用清华的repo_url，因为公司的电脑默认可以翻墙（虚机不允许），就直接改了个代理搞定了
```
export HTTP_PROXY=http://your proxy ip//:8888
export HTTPS_PROXY=http://your proxy ip//:8888
#取消代理
export -n HTTP_PROXY
```


编译：
```
. build/envsetup.sh
lunch aosp_arm-eng
make -j16
```

编译SDK(编译sdk的时候用，这里不用执行，只是介绍一下，有上面的命令就够了)：
```
lunch sdk_sdk-eng
make sdk
```

# 使用hide api和internal api

之前我想一步到位直接编译出android.jar，将源码中带有@hide标记的代码进行处理，使其在`make sdk`的时候，不要删除这些代码。修改方法 ：去掉代码中的`@hide`比较不现实，太多了。经整理发现，进行hide api处理，其实是在生成api doc的时候，关键的代码在./external/doclava/目录下。我们修改`Stub`类，可以达到目的。

后来发现，在编译android.jar的时候，是有一个类的映射，有一个文件保存需要将哪些类打入到android.jar。上面的方法不能只处理了hide api，而还有`internal`的代码还是没能打入jar。

于是，只好使用`make -j32`命令，直接都编译了一圈，然后标准sdk中的jar进行合并，生成了包含`internal`的jar包.

framework目录：`out/target/common/obj/JAVA_LIBRARIES/framework_intermediate`
SDK的android.jar目录：`out/target/common/obj/JAVA_LIBRARIES/android_stubs_current_intermediates`