title: Git中rebase的常规使用
date: 2020-01-09 20:21:39
category: git

tag: [git]
---

# git

公司从svn版本管理切换成了git，Android Studio（Intellij IDEA）也可以较好的支持git，相当方便。git有一个特别强大的命令，那就是rebase，这篇blog就记一下git rebase的一些使用。

## 官方文档
https://git-scm.com/docs/git-rebase
## 一个不错的操作模拟
https://learngitbranching.js.org/

<!-- more -->

# git rebase的常用操作
本文不另辟捷径，官方文档讲的很详细，就挑几个官方的例子翻译一下。

## 案例1 ：

```
          A---B---C topic
         /
    D---E---F---G master
```

```
git rebase master
git rebase master topic
```

上面两条命令，执行其中的一条就可以，执行以后。

```
                  A'--B'--C' topic
                 /
    D---E---F---G master
```

## 案例2：--onto的使用
```
git rebase [-i | --interactive] [<options>] [--exec <cmd>]
	[--onto <newbase> | --keep-base] [<upstream> [<branch>]]
```
```
    o---o---o---o---o  master
         \
          o---o---o---o---o  next
                           \
                            o---o---o  topic
```
```
git rebase --onto master next topic
```
执行的结果为
```
    o---o---o---o---o  master
        |            \
        |             o'--o'--o'  topic
         \
          o---o---o---o---o  next
```
这里--onto的后面有三个参数（其实属于--onto的就一个）
1. 参数1：要跟随在哪个commit，可以是分支名，也可以是commit的 Revision Number
2. 参数2：after-this-commit 意思是，从这个commit之后的开始算，这个commit是不算的
3. 参数3：要操作的最后一个commit，这个本身是要算进去的。

## 复制一段commits到另一个分支（as应该不支持）
```
    A---B---C---D---E  master
         \
          F---G---H---I---J---K---L---M  topic
```
比如想把K L M的提交copy到master上，那么可以使用命令
```
git checkout master
git rebase --onto E J M
git rebase HEAD master
```
结果为
```
    A---B---C---D---E---K‘---L’---M‘  master
         \
          F---G---H---I---J---K---L---M  topic
```
注意这里一定要`git rebase HEAD master`，因为执行了第二条rebase后，只是复制了一份commit过去，需要处理一下master和HEAD。


## 案例3：合并多条commit为一条
```
git rebase -i <after-this-commit>
```
执行上述命令后，会让你配置每一项的处理方式
```
pick ：不做任何修改；
reword：只修改提交注释信息；
edit：修改提交的文件，做增补提交；
squash：将该条提交合并到上一条提交，提交注释也一并合并；
fixup：将该条提交合并到上一条提交，废弃该条提交的注释；
```

# 关于Android Studio
AS内置的插件可以满足大部分功能，按command + 9可以唤出来log tab
附上操作指南：
https://www.jetbrains.com/help/idea/edit-project-history.html

我试了试，最终在as里没有找到 --onto 复制一段commits的方式，因为第三个参数必须得选branch，在stackoverflow里，找到一处资料

> The rebase dialog in IntelliJ 12.1 uses the most general version of the rebase command:
>
> ```
> git rebase [-i] [--onto newbase] [upstream] [branch]
> ```
> where IntelliJ's "Onto" field corresponds to --onto newbase, IntelliJ's "From" field corresponds to "upstream" and IntelliJ's "Branch" field corresponds to "branch".
>
> https://stackoverflow.com/questions/14608812/how-to-do-interactive-rebase-with-intellij-idea



如果是只有一条提交记录，通常用cherry-pick很方便，rebase可以用来处理多条commits的时候。当然，你也可以把commit先执行squash，再执行cherry-pick。