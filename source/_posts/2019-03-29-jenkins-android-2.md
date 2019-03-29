title: 使用jenkins为android工程打包，支持多包名，改资源（踩坑指南）
date: 2019-03-29 13:30:00
category: [android打包,jenkins]
tag: [android,jenkins]
---

# 需求
上一篇文章主要写了打包刚开始的配置和参数化构建。这篇文章主要讲一讲在改包名、改资源的打包实践中，常会碰到的问题以及解决办法。如果看博客的人有更好的解决办法，也可以找我交流，关于页面有我联系方式。

打包的主要需求如下：

1. 改包名
2. 可以替换icon，可以修改应用名，包括应用内部显示的名称（如版权信息）
3. 可以控制部分功能是否开启

# 改包名分析
我们知道，改包名只是修改applicationId，和代码中类的package无关，所以基本上代码和AndroidManifest.xml中组件的name，都是不需要改动的。但是还是会涉及到下面的这些问题：

<!-- more -->

1. 代码中使用"包名"写死的路径，比如`/data/data/com.xx.xx/`。
2. AndroidManifest.xml中，ContentProvider会填一个`authorities`属性，换包名等于换应用`authorities`就得跟着变。部分`action`，部分activity的`taskAffinity`。
3. 第三方的client_key(支持多包名就没关系了，比如umeng push)。
4. 提供给外部调用的activity和service，偶尔会要求必须在包名路径下(刚好我碰上了这奇葩事)。

具体解决办法：

1. 使用全局查找，找出包名的字符串，统一改为context.getPackageName()，没有context对象的地方，使用`BuildConfig.APPLICATION_ID`。
2. 当我们配了applicationId以后，就可以在AndroidMenifest.xml中使用`{$applicationId}`代替写死的包名。
3. 像`applicationId`一样，在gradle文件的`defaultConfig`中，把每个key都声明成常量调用。在做打包之前，我想的是给产品运营人员提供一个构建参数让他们填写，后来意识到，其实这些clientkey和包名是绑定的，于是在工程里新建了一个名包文件夹，里面保存了key=value的格式，打包时，通过shell读取到环境变量，然后用shell修改gradle的配置。
4. actiivity可以使用`activity-alias`标签`<activity-alias android:name="{$applicationId}.XActivity" android:targetActivity=""`，至于service，就比较难搞，我这里的解决办法是，给当前包名写了个继承原包名Service的空子类，修改AndroidManifest.xml中的name使用`${applicationId}`。然后代码中，给如果有startService的地方，就使用`Class.forName(BuildConfig.APPLICATION_ID + ".XService")`反射。

# 应用场景

部分shell脚本的源码，这里只是修改build.gradle的脚本，要打包还要再加入`./gradlew assembleRelease`等其它个性化脚本
将完整的shell脚本保存成sh文件，放到工程目录下，在jenkins中执行该sh文件`sh ./jenkinsbuild.sh`
```
field_name=('BOOL_FIELD1' )
value=($BOOL_FIELD1 )
#注意 这里是用测试的值 注意value要和filed的name对应 在shell中全是字符串格式
#value=('false' 'false' 'false' 'false' 'false' 'false' 'false' 'false' 'false' 'false')

for i in "${!field_name[@]}";
do
    echo ${field_name[$i]} ${value[$i]}
    #只有当变量不为null的情况下，才去修改Build文件
    if [ -n "${value[$i]}" ];then
        toReplace='buildConfigField "boolean", \"'${field_name[$i]}'\", "'${value[$i]}'"'
        echo $toReplace
        sed -i 's/buildConfigField \"boolean\", \"'"${field_name[$i]}"'\", \"\([a-zA-Z]*\)\"/'"$toReplace"'/g' build.gradle
    fi
done

toReplace='applicationId \"'$PACKAGE_NAME'\"'
echo $toReplace
sed -i 's/applicationId \"com.lefo.oldpkg\"/'"$toReplace"'/g' build.gradle

#字符串变量  操作方式是删除掉gradle文件中旧的  添加新的
field_name=('PT_CLIENT_ID' 'PT_CLIENT_SECRET' 'PT_QQ_ID' 'PT_WX_RELEASE_ID' 'BUGLY_ID' 'APP_TYPE' 'PT_SERVER_SECRET' 'LICENSE_URL' 'POLICY_URL')
value_name=('client_id' 'client_secret' 'qq_id' 'wx_id' 'bugly_id' 'app_type' 'server_secret' 'license' 'policy')

for i in "${!field_name[@]}";
do
    echo ${field_name[$i]}
    value=${value_name[$i]}
	toReplace='buildConfigField \"String\", \"'${field_name[$i]}'\", \"\\\"'${!value}'\\\"\"'
	echo $toReplace
	sed -i '/buildConfigField \"String\", \"'${field_name[$i]}'\", /d' build.gradle
	sed -i '/defaultConfig/a buildConfigField \"String\", \"'${field_name[$i]}'\", \"\\\"'${!value}'\\\"\"' build.gradle
done

```
那么，脚本中，`client_id`这些，是如何一次性加入到环境变量中的？这里要用到另一款插件，**Environment Injector Plugin**。这款插件可以在执行时往执行环境中注入变量。关于变量的配置信息，我在工程目录下新建了一个文件夹保存的配置文件。就是key=value的格式，就是你熟悉的java properties file。这里的`PACKAGE_NAME`，在jenkins参数化构建时，给产品提供的是一个选项列表，固定好包名列表给产品选择选，毕竟涉及到client_key的修改，不能随便填。
![](/image/20190329/key-config.jpg)

# 改资源该怎么改
产品居然想要修改APP名称，图标，部分页面的图片，这里要用到gradle配置中的productFlavors。工程中新建一个文件夹`lefo`，注意要名字对应，然后我们将要替换的资源，按原资源存放位置，放到package1目录下，打包时，不能再执行assembleRelease，这个时候就应该是`./gradlew assembleLefoRelease`
```
productFlavors{
	lefo{
    	//产品说，可不可以做到应用显示的名字和内部的名字不一样  可以 给应用单独配一个名字 本来有个资源叫app_name
    	manifestPlaceholders = [label:"@string/app_label"]
    }
}
```

既然想这么定制，那就彻底交给产品，他们想放什么放什么。

修改应用名称：直接使用jenkins中参数配置，通过sed命令修改strings.xml
图标资源替换：最初想的是从某处下载一份资源，然后替换掉包中资源，产品那边和我们一样用的是svn，jenkins在构建的时候，SCM是在构建之前的，也就是说，在构建以前就要checkout代码。问题就来了，资源目录的URL可以做为一个参数传进来，但并不是每一次打包，都需要替换资源。如果URL没有传，那SCM就不能过，构建就会失败，根本走不到编译过程。这里同样要使用插件**Environment Injector Plugin**，它可以在SCM以前，使用脚本修改某个变量的值。

注意下图中我使用的是`groovy script`，如果我没有记错的话，只有`groovy script`是可以在SCM之前执行的。如果没有填，脚本就给它一个内容为空的文件夹路径，SCM配置中，支持`${RES_URL}`使用。为什么不给`RES_URL`配一个默认值呢？因为不填写更直观，产品修改的时候，也不用每次都删除旧的再复制上新的还得检查一遍。

![](/image/20190329/res-url.jpg)

# 续
产品经理用的很嗨，暂时没有续，为了不涉及隐私，整篇加上前一篇都是一些片段，想直接copy进去使用的可能要失望了。不过，拼凑一起还是可以的，实在不懂的来找我。