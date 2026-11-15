# Lab 05 · 合并：fast-forward 与三方合并

## 目标

搞清 `git merge` 什么时候"快进"，什么时候"生成一个合并提交"。

## 情况 A：fast-forward（快进）

主分支在分叉后**没有新提交**，合并时直接把指针往前移。

`bash
cd ~/gitlab/05 && git init
echo a > a.txt && git add . && git commit -m "c1"
git switch -c feature
echo b > b.txt && git add . && git commit -m "c2"
git switch main
git merge feature
`~

**输出里有 `Fast-forward`。** 历史是一条直线，没有额外的合并提交。

## 情况 B：三方合并

两个分支**都有新提交**，必须生成一个合并提交。

`bash
cd ~/gitlab/05b && git init
echo a > a.txt && git add . && git commit -m "c1"
git switch -c feature
echo b > b.txt && git add . && git commit -m "c2"
git switch main
echo c > c.txt && git add . && git commit -m "c3"
git merge feature
`~

**这次会生成一个新 commit**（合并提交），有两个 parent。

`bash
git log --oneline --graph --all
`~

`text
*   merge commit
|\
| * c2 (feature)
* | c3 (main)
|/
* c1
`~

## 验收

1. 各制造一次 FF 和三方合并
2. 用 `git log --graph` 看出两者历史形状的差别
3. 说清"三方"是指哪三方（共同祖先、两个分支末端）

## 坑

合并前先 `git status` 确认工作区干净，否则 git 会拒绝或者把改动搅进去。
