


```
git remote add branchName 远程仓库地址
git branch 本地分支
git checkout 本地分支
git branch --set-upstream-to=远程分支 本地分支
```

```
#创建本地分支 并提交到远程
git checkout -b develop
git push -u origin develop
```

```
git push origin --delete 分支name

推送一个空分支到远程分支，相当于删除git p
git push origin :分支name
```

```
git push origin --delete tag <tagname>
```


查看当前分支名:

```
git symbolic-ref --short -q HEAD
```

git branch -r

git stash

git stash pop


git remote -r 

git fetch upstream

git remote add name xxxxx