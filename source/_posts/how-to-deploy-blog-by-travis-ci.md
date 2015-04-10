title: 如何通过travis ci自动发布blog
date: 2015-04-10 18：41:36
tags: [travis,hexo]
category: 个人随笔
---

## 背景 ##
用hexo搭建BLOG，悲催的就是每次换台电脑就得搭一次环境，之前在网上也看到过有自动发布的教程，一直没有搞。最近网上又翻了一下，发现用travis ci不需要拥有自己的主机（有提供服务的平台），相对来说比较节省折腾，整理一下发出来。

## 要求 ##
- github pages，用于搭建BLOG，不介绍。
- travis ci，自己百度一下补脑，可以理解为就是一个node.js的虚拟机环境。[https://travis-ci.org/](https://travis-ci.org/ "https://travis-ci.org/")提供了travis-ci的服务，可以指定构建github上的代码。
- 本地有hexo环境
- linux或者MAC工作环境

## 用法： ##

- 申请travis ci账户，将你的blog的repo绑定到travis-ci上。
- 在你的github pages的项目（也就是username.github.io），建一个分支，用于存放你写的文章的md文件，假设分支叫blog

将blog分支pull下来，参考下面的列表，将hexo环境下的这些文件夹，文件放到blog分支里

```
hexo
	|-scaffolds
	|-source
	|-themes
	|-CNAME
	|-_config.yml
	|-package.json

```

要使用travis，还需要一个travis的脚本配置文件，就是告诉travis当构建的时候，执行这个脚本。在分支的根目录新建一个文本文件，重命名为.travis.yml，在里面加入下面的代码，注意：将第3行的blog改成你的分支的名字。



<!-- more -->

```
branches:
  only:
  - blog

language: node_js

node_js:
- '0.10'
- 
before_install:

install:
- npm install hexo-cli -g
- npm install hexo --save
- npm install hexo-deployer-git --save
- npm install hexo-generator-archive --save
- npm install hexo-generator-category --save
- npm install hexo-generator-feed --save
- npm install hexo-generator-index --save
- npm install hexo-generator-sitemap --save
- npm install hexo-generator-tag --save
- npm install hexo-renderer-ejs --save
- npm install hexo-renderer-marked --save
- npm install hexo-renderer-stylus --save

script:
- hexo clean
- hexo g
- hexo d

```

已经完成了大半了，现在已经可以构建出html了，但是，还不能把生成的静态页面上传到github，要上传到github。

将生成的这些先push到github上

```
$ ssh-keygen -t rsa -C "your_email@example.com"

```

在linux环境下，生成github要用的SSHKey，参考[https://help.github.com/](https://help.github.com/ "https://help.github.com/")。记得要在项目的的Settings里加入你的key。

正确生成后你会得到两个文件，一个叫ssh_key，一个叫ssh_key.pub。

安装travis,需要ruby，gem环境，命令：
```
apt-get install ruby-dev
gem install travis
travis login --auto

```
使用你的github账户登录

假设刚刚生成的sshkey的名字叫 ssh_key。下面的代码自动会生成`ssh_key.enc`文件，在你的`.travis.yml`添加一段代码

```
$ travis encrypt-file ssh_key --add -r username/reponame
```

有可能添加不上，去掉`--add`参数，执行后，手动添加，代码如下：

```

before_install:
- openssl aes-256-cbc -K $encrypted_xxxxxxxx_key -iv $encrypted_xxxxxxxx_iv -in .travis/ssh_key.enc -out ~/.ssh/id_rsa -d
```

新建`.travis`文件夹，将刚刚的`ssh_key.enc`放在该文件夹下，再在该文件夹下新建文件`ssh_config`。
```
Host github.com
  User git
  StrictHostKeyChecking no
  IdentityFile ~/.ssh/id_rsa
  IdentitiesOnly yes

```

如果之前是自动添加的语句，需要将里面的文件目录修改成与上面描述的目录一致。

在`.travis.yml`的`before_install`区域里加入下面的代码

```
- chmod 600 ~/.ssh/id_rsa
- eval $(ssh-agent)
- ssh-add ~/.ssh/id_rsa
- cp .travis/ssh_config ~/.ssh/config
- git config --global user.name 'username'
- git config --global user.email 'email'

```
push到github，travis就会自动构建，并生成到master下面。
成品可参考前一篇BLOG

##注意##
- 最新版本的hexo，是3.x，如果你用的是2.x，需要从github上clone对应的版本使用，不能直接npm install。否则，你的_config.yml可能不适用。