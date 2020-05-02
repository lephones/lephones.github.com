title: OpenCV在Android NDK按需要的模块编译
date: 2020-05-02 17:04:20
category: android

tag: [opencv,android]
---

# 前言
公司要做一个和图片有关的功能，一说图片处理，大家首先想到的就是强大的OpenCV。OpenCV很强大，官方也提供了android专用的sdk，直接将so和jar放入项目中就能使用。尽管官方推荐的也是这种方式，但有一个问题是，OpenCV的库很大，有10MB，很多公司整个APK都没有10MB，如果要把真个库都放到项目中，那还是挺大的。所以，这里就需要我们自己编译。中间折腾了好久，写个文章记录一下。

# 准备
## 下载OpenCV
地址 [https://opencv.org/releases/](https://opencv.org/releases/)
选择Android平台的包

这里注意了，4.0的版本，要求api level是21以上，所以，如果你的APP是要在21以下使用，不要下载这个。

3.x的版本不清楚，但我试了OpenCV 2.x的版本是api level 8以上。2.x的版本，需要自行google，官方应该已经不提供了。

<!-- more -->

## 配置gradle
```

defaultConfig

android {
	ndkVersion "16.1.4479499"
    defaultConfig {
        ndk {
            moduleName "opencv-test"
            abiFilters 'armeabi-v7a','x86'
        }
    }
    externalNativeBuild {
        cmake {
            path "src/main/jni/CMakeLists.txt"
            version "3.10.2"
        }
    }
}
```
注意，上面的ndkVersion可以不填，我这里是为了使用OpenCV 2.X版本，应该是需要r16的版本编译，因为使用当前最新的版本编译时，有个库找不到。

abi需要哪些请根据你自己的需要来填，有很多新入门的朋友抄的时候都不看内容，否则如果你其它so库在某平台缺失，可能会闪退。

CMakeLists.txt注意对应的目录是你JNI代码的目录

## CMakeLists.txt

在网上找的一个内容折腾了好久，终于算是弄明白了
```
#你的opencv解压目录
set(OpenCV_DIR /OpenCV-android-sdk/sdk/native/jni)
#这里也可以在后面跟具体模块OpenCV REQUIRED core imgproc 注意，写上并不代表会编译到包内
FIND_PACKAGE(OpenCV REQUIRED)
if(OpenCV_FOUND)
    include_directories(${OpenCV_INCLUDE_DIRS})
    message(STATUS "OpenCV library status:")
    message(STATUS "    version: ${OpenCV_VERSION}")
    message(STATUS "    libraries: ${OpenCV_LIBS}")
    message(STATUS "    include path: ${OpenCV_INCLUDE_DIRS}")
else(OpenCV_FOUND)
    message(FATAL_ERROR "OpenCV library not found")
endif(OpenCV_FOUND)
#你的库
add_library( native_test
        SHARED
        native.cpp)

#include为头文件所在的目录hpp
include_directories(/OpenCV-android-sdk/sdk/native/jni/include)

#要链接的库
target_link_libraries( native_test
        ${OpenCV_LIBS}
        log
        jnigraphics)
```
简单说一下上面的代码
1. 首先设置OpenCV_DIR环境变量，指定所在目录
2. 找出配置的所包含的库，也就是OpenCV的模块
3. 环境的打印，不用在意
4. add_library是你的库的配置，可以参考ndk的官方文档
5. include_directories是OpenCV的头文件目录
6. target_link_libraries这里要用到jnigraphics，还有日志打印的log（常用），注意看OpenCV_LIBS就是FIND_PACKAGE的内容，在3中会打印出来。

搭建完后你就可以在代码中编写你的jni代码了，这样写出来的库，只会包含你用到的模块，比如你只用到了core和imgproc，那你的库打出来就只有1.8mb，这比OpenCV官方的要小了好多。

# 附

写代码的时候，不要使用OpenCV的imread，这会导致有需要多导入模块，增加了包的体积。ndk中，有android/bitmap.h，可以直接使用Bitmap对象来转Mat.
