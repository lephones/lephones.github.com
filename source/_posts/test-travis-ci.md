title: 测试一下travis自动发布
date: 2015-03-31 18：41:36
tags: [travis,hexo]
category: 个人随笔
---

搭建了一个自动发布BLOG的平台  
下面是代码，做一下备份，关于详细教程，以后的BLOG更新一下

<!-- more -->

```
branches:
  only:
  - blog

language: node_js

node_js:
- '0.10'

before_install:
# 如果你要用这个，把这里换成你的，生成方法百度找
- openssl aes-256-cbc -K $encrypted_bf7ae6d2ed82_key -iv $encrypted_bf7ae6d2ed82_iv -in .travis/ssh_key.enc -out ~/.ssh/id_rsa -d
- chmod 600 ~/.ssh/id_rsa
- eval $(ssh-agent)
- ssh-add ~/.ssh/id_rsa
- cp .travis/ssh_config ~/.ssh/config
- git config --global user.name 'lephones'
- git config --global user.email 'lephones@lephones.net'

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