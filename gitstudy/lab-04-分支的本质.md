# Lab 04 · 分支的本质

## 目标

分支不是一个"文件夹"，它只是**一个指向 commit 的指针**。

## 动手

`bash
cd ~/gitlab/04 && git init
echo "a" > a.txt && git add . && git commit -m "c1"
git branch feature          # 创建分支（不切换）
git branch                  # 看到 main 和 feature
`~

**两个分支现在指向同一个 commit。**

`bash
git switch feature          # 切过去
echo "b" > b.txt && git add . && git commit -m "c2"
git switch main
ls                          # 看不到 b.txt
`~

**切分支 = 把工作区换成那个 commit 的样子。**

## 看图形化历史

`bash
git log --oneline --graph --all
`~

`text
* c2 (feature)
* c1 (HEAD -> main, ...)
`~

**`*` 是一个 commit，`(feature)` 表示这个分支指向它。**

## HEAD 是什么

`bash
cat .git/HEAD
`~

输出 `ref: refs/heads/main` —— **HEAD 指向"当前分支"，分支指向"commit"。**

`bash
git switch feature
cat .git/HEAD      # 变成 refs/heads/feature
`~

## 验收

1. 创建分支后，为什么两个分支的文件内容一样？
2. 切换分支后，工作区的文件为什么变了？
3. `HEAD` 指向什么？分支指向什么？

## 坑

`git checkout` 既能切分支又能还原文件，容易搞混。新版本拆成了 `git switch`（切分支）和 `git restore`（还原文件）。
