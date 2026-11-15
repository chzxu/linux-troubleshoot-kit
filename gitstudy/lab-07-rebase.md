# Lab 07 · Rebase 整理历史

## 目标

`merge` 保留分叉，`rebase` 把分支"搬到"另一条线的末端，历史变直。

## 动手 A：普通 rebase

`bash
cd ~/gitlab/07 && git init
echo a > a.txt && git add . && git commit -m "c1"
git switch -c feature
echo b > b.txt && git add . && git commit -m "c2"
git switch main
echo c > c.txt && git add . && git commit -m "c3"
git switch feature
git rebase main
`~

`bash
git log --oneline --graph --all
`~

**对比 Lab 05 的三方合并**：这里没有分叉，feature 的提交被"重放"到 main 后面。

**注意**：commit 哈希变了 —— 因为是重新生成的。

## 动手 B：压缩提交（交互式 rebase）

`bash
cd ~/gitlab/07b && git init
for i in 1 2 3; do echo $i > f$i.txt; git add .; git commit -m "wip $i"; done
git log --oneline
`~

三个零碎提交。压成一个：

`bash
git rebase -i HEAD~3
`~

编辑器打开后，把后两行的 `pick` 改成 `squash`（或 `s`），保存退出。

再编辑合并后的提交信息，保存退出。

`bash
git log --oneline      # 只剩一个提交
`~

## 验收

1. 做一次 rebase，用 graph 看出历史变直
2. 把 3 个提交压成 1 个
3. 说清：为什么 rebase 之后 commit 哈希会变？

## 坑

**已经 push 到公共分支的提交不要 rebase** —— 别人拉过之后历史就分叉了。

**规矩：rebase 只用于本地未发布的提交。**
