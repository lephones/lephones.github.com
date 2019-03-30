title: 使用jenkins为android工程打包，支持多包名，改资源（简单上手）
date: 2019-03-26 14:44:00
category: android打包
tag: [android,jenkins]
---

# 下载安装jenkins

官网地址：[https://jenkins.io/](https://jenkins.io/)
没什么好说的，网上教程一大堆，唯一要做的是要修改jenkins_home目录所在分区，因为将来所有的内容都要放在这里，如果分区太小，指不定哪天就满了，到时就打不了包了。

实践中，发现/home/jenkins目录也要处理一下，我就碰上了/home/jenkins目录占满了根分区，打开发现都是gradle打包时生成的一些缓存，就将/home/jenkins使用`ln`命令做了个软连接到另一个分区目录下。

<!-- more -->

# 新建jenkins项目

![创建项目](/image/20190326/create-jenkins.jpg)
![代码库](/image/20190326/source.jpg)

选择`新建任务`,填一个名字，选择自由风格的项目，点下方OK
进入配置页，源码管理里选择你们所用的源码管理工具，填入地址，用户名认证信息等。
注意，这里可能没有git和svn，那么需要你去系统管理，管理插件模块，搜索git或者svn插件并安装。后续还有其它功能需要安装插件。

构建步骤 选择 Execute shell，Command里填入`./gradlew assembleRelease`就好了。

# 改渠道号、版本号打包
我们搭建jenkins，肯定不只是简单的打个包。一般常见的需求有，打渠道包，改包名，改资源文件。

## 参数化打包，打包时修改渠道号，版本号

jenkins提供了一个功能叫`参数化构建`，打包时，可以手动配一些参数。在`配置`中勾选`参数化构建过程`，下面添加你需要的参数，支持布尔型，字符串型。这些添加的参数，在shell中可以直接使用${参数名}使用，比如我们可以填入渠道号，versionname，versioncode等，如果你想填APP的名称也可以。

参数填了，如何在打包时配到gradle文件中呢？

使用`sed`命令开修改

```
#echo get versioncode
vc=$VERSION_CODE;
sed -i 's/android:versionCode=\"\([a-zA-Z0-9.]*\)\"/android:versionCode=\"'$vc'\"/g'  AndroidManifest.xml
echo "version code : $vc"

#echo get  versionname
vn=$VERSION_NAME
sed -i 's/android:versionName=\"\([a-zA-Z0-9.]*\)\"/android:versionName=\"'$vn'\"/g'  AndroidManifest.xml
echo "version name : $vn"

./gradlew assembleRelease
```
其中，VERSION_CODE和VERSION_NAME就是在jenkins中配置的参数，我这里是改的manifest文件，我们也可以用sed命令修改gradle文件。


## 改包名

通过sed命令修改gradle文件中的`build applicationId packagename`，首先在参数化构建中，添加一个名称为PACKAGE_NAME的变量，供打包的人填写包名。然后在构建shell前面加入下列shell脚本。

```
toReplace='applicationId \"'$PACKAGE_NAME'\"'
echo $toReplace
sed -i 's/applicationId \"com.old.pkgname\"/'"$toReplace"'/g' build.gradle
```


## 修改构建后生成的名称
通常jenkins打包完成后，左侧的构建历史，是一个数字序号，时间一长可能就忘了对应关系，所以一般情况需要将名称修改成可读的格式，那么如何在构建时，自动就修改好名称？

使用插件`Version Number`，安装该插件后，去到项目配置页，在构建环境下，勾选`Create a formatted version number`，再在下面的`	Build Display Name`选项勾选`Build Display Name`

在`Environment Variable Name`中可以将生成的名称赋值给一个变量名，在后续构建时的shell中可以使用，根据自己喜好起一个就行。

在`Version Number Format String`中可以填写想要生成的名称格式，可以使用`${变量名}`引用环境变量和参数名称，同时点右侧的问号可以看到系统提供的一部分时间相关的变量名。

如：`${VERSION_CODE}_${VERSION_NAME}_${BUILD_ID}`

![构建名称](/image/20190326/formatted-version-number.jpg)

# 后续

以上讲的就是基本打包流程，但是实际应用中，还存在一些问题，比如，改了包名后，一些第三方的client key也要修改。再加上产品的对资源、功能定制需求也越来越复杂，上面的方式是绝对难满足他们定制化的要求的。下篇见。。。

下篇博客写在打包实际应用中，是如何通过jenkins改包名和改资源，以及解决一些随包名存在的问题和注意事项。