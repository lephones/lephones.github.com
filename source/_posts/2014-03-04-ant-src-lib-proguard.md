title: ant打包中依赖工程的处理及混淆
date: 2014-03-04 10:42:07
tags: [android,ant]
category: android打包
---

## 概述 ##
在android开发中，ant是用的最多的打包工具。有时候，我们会经常用到一些工程来做为依赖库，也就是src library。那么加入src library project的工程，怎么使用ant的脚本打包成一个apk呢。

关于ant打包，请参考 **[使用ant打包APK及依赖包最佳解决办法](http://www.lephones.net/2014/10/13/ant-apk-with-lib/ "使用ant打包APK及依赖包最佳解决办法")**

## 原理 ##
我们都知道，src lib无非就是源码和资源。将src打包成jar，这绝对没问题，但是资源文件怎么打包呢？资源文件打包，其实主要就是R文件的运用，因为R文件中保存着资源的ID。

<!-- more -->
先来看ADT是怎么打包的，打开主工程的	`gen` 目录，我们会发现，有两个R文件，一个是在主工程的package下面，一个是在lib工程的package下面。打开两个R文件，细心的网友会发现，主工程的R文件中，会把lib工程的R文件copy一份过来，也就是，在主工程的R文件中，同时包括了主工程的资源和lib工程的资源。

我们依照这个原理来编写脚本。


## 脚本 ##
首先，在主工程的`build.xml`中，加入:
```
<property file="project.properties"/>
```
原理是将lib工程的配置引进入，我们打开`project.properties`会发现有一条配置就是`android.library.reference.1=../xxxx`

其次：在生成R文件的部分编写如下代码：
```
<!-- Generate the R.java file for this project's resources. -->  
<target name="resource-src" depends="dirs">  
  <echo>Generating R.java / Manifest.java from the resources...</echo> 
  <exec executable="${aapt}" failonerror="true">  
        <arg value="package" />  
        <arg value="-m" />  
    	<arg value="--auto-add-overlay" />
        <arg value="-J" />  
        <arg value="${outdir-r}" />  
        <arg value="-M" />  
        <arg value="AndroidManifest.xml" />  
        <arg value="-S" />  
        <arg value="${resource-dir}" />  
        <arg value="-S" />  
		<!-- 这里一定要加上，相当于将资源工程的R在主工程复制一份 -->
        <arg value="${android.library.reference.1}/res" /> 
        <arg value="-I" />  
        <arg value="${android-jar}" />  
    </exec>
		<!-- 单独生成一次lib工程的R文件 -->
	   <!-- 生成资源工程的R -->
     <exec executable="${aapt}" failonerror="true">  
         <arg value="package" />  
         <arg value="-m" /> 
     	<arg value="--auto-add-overlay" />
         <arg value="-J" />  
         <arg value="${outdir-r}" />  
         <arg value="-M" />  
         <arg value="${android.library.reference.1}/AndroidManifest.xml" />  
         <arg value="-S" />  
         <arg value="${android.library.reference.1}/res" />  
         <arg value="-I" />  
         <arg value="${android-jar}" />  
     </exec> 
</target> 
```

上述代码中，先将lib工程的资源生成R映射关系到主工程pachakge的R文件中，再将lib工程的资源生成R文件到lib工程package下面

**注意**

	必须在主工程package的R文件中生成lib工程的资源ID，这样ID才不会有所重复
	AAPT在打包的时候，会保证lib工程package下的R文件的id
	与主工程package下的R文件中的对应id一致

## 混淆 ##

只是一个知识点，通常混淆时候，我们都是在工程目录下的proguard.cfg中编写混淆配置，那么在ant中怎么直接引入这个文件呢？
```
<arg value="@${proguard-cfg-path}" />
```
这样，就不用在ant脚本里编写混淆参数了。