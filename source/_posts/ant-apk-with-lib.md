title: 使用ant打包APK及依赖包最佳解决办法
date: 2014-10-13 17:17:06
tags: [android,ant]
category: android打包
---
## 简介
最近有小伙伴问ant打包的事，google现在又在推广它的gradle构建工具，但是，目前有许多朋友还是用的ant，而且，在SDK多次更新之后，之前写好的ant文件不适用了，典型的例子就是`apkbuilder`命令。那么，怎么办呢？？

好多人在网上搜索写好的打包脚本，并费劲心机的寻找工程依赖的打包方法，其实，android的SDK已经给我们提供了该build.xml文件了，就在`/tools/ant/`下面，这个脚本引用了`tools/lib`下的`ant-task.jar`，封装了好多target，我这里就说说怎么使用该脚本。
<!-- more -->
## 生成ant脚本
- 在sdk/tools目录下执行下面的命令，注意将命令里面的目录改成你的工程的目录
```bash
android update project -p /dir/to/ur/project 
```

- 如果你的工程没问题，就会在目录下生成2个文件，`build.xml`和`local.properties`,打开`local.properties`，可看到其实是一个环境配置
- 在工程目录新建`ant.properties`，将下面的配置信息添加到该文件中，注意将keystore的信息改成你的
```
key.store=/home/android/android/build-res/safetrip.releasekey
key.alias=android
key.store.password=password
key.alias.password=password
```
- 打包，在工程下使用命令`ant release`，或者在eclipse中用ant运行

## 项目依赖怎么办
在eclipse中配置好依赖关系，在每个工程下面都执行
```bash
	android update project -p /dir/to/ur/project
```
生成build.xml文件就可以啦，就是这么简单，因为在project.properties中已经能读取到依赖关系，build.xml会根据这个文件自动依赖并打入包中的。

## 批量打包：
可以看到生成的build.xml文件在最后是import了sdk中的`/tools/ant/build.xml`了，我这里打包用的是`ant contrib`,大家百度一下用法就清楚了。在工程下的build.xml最后加入下面的代码，注意修改清单文件中具体的属性。打包时候，就是执行`ant deploy`，在deploy的target中，会循环调用release的。
```
<condition property="has.contrib">
    <and>
        <isset property="ant.contrib"/>
    </and>
</condition>
<taskdef resource="net/sf/antcontrib/antcontrib.properties">
	<classpath>
		<pathelement location="${ant.contrib}"/>
	</classpath>
</taskdef>
<target name="deploy">
    <if condition="${has.contrib}">
        <then>
            <foreach target="modify_manifest" list="${market_channels}" param="channel" delimiter=",">
            </foreach>
        </then>
        <else>
            <echo level="info">ant contrib not found!</echo>
        </else>
    </if>
</target>
<target name="modify_manifest">
    <replaceregexp flags="g" byline="false">
       <regexp pattern='meta-data[^/>]*android:name="UMENG_CHANNEL"[^/>]*'/>
        <substitution expression='meta-data android:value="${channel}" android:name="UMENG_CHANNEL"'/> 
        <fileset dir="" includes="AndroidManifest.xml"/>
    </replaceregexp>
    <property name="build.deploy" value="true"/>
    <mkdir dir="${out.absolute.dir}/out"/>
    <property name="out.final.file" location="${out.absolute.dir}/out/${ant.project.name}_${channel}.apk"/>
    <antcall target="release"/> 
</target>
```

## 环境问题
因为新的SDK引入了`build-tools`目录，所以，要保证你的工程所配置的编译版本，所对应的build-tools也存在。
