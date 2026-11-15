# Lab 02 · 看懂一次提交

## 目标

commit 里到底存了什么？为什么能"回到过去"？

## 动手

`bash
cd ~/gitlab/01
git log --oneline
git show HEAD
`~

`git show` 会显示：作者、时间、提交信息、**以及这次改了什么（diff）**。

看一眼提交的完整结构：

`bash
git cat-file -p HEAD
`~

输出里有三个关键字段：

`text
tree     <一串哈希>   ← 这次提交时整个项目的目录快照
parent   <一串哈希>   ← 上一次提交（第一次提交没有这行）
author   ...
`~

## 理解

- **blob**：文件内容的快照（只看内容，不看文件名）
- **tree**：目录结构（哪个名字指向哪个 blob）
- **commit**：指向一个 tree + 一个 parent + 提交信息

**递归下去，就是整个项目历史。**

## 验收

1. 用 `git show` 找到某次提交改了哪几行
2. 用 `git cat-file -p HEAD` 找到 parent 哈希，再用 `git show <parent>` 看上一个提交
3. 说清 `blob` 和 `tree` 的区别

## 坑

`git log` 默认分页，按 `q` 退出。想一次看完用 `git log --oneline -5`。
