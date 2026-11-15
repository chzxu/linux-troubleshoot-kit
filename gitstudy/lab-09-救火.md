# Lab 09 · 救火：reset / reflog / stash

## 目标

**reflog 是 Git 的后悔药。** 学会用它，你就不会怕"搞丢代码"。

## reflog 是什么

`bash
cd ~/gitlab/01
git reflog
`~

它记录**每一次 HEAD 的移动**：提交、切换分支、reset、merge……

**只要 commit 过，就算分支删了，reflog 里也能找回来。**

## 实验：删掉分支再救回来

`bash
cd ~/gitlab/09 && git init
echo a > a.txt && git add . && git commit -m "c1"
git switch -c feature
echo b > b.txt && git add . && git commit -m "c2 重要工作"
git switch main
git branch -D feature        # 删除分支（-D 强制删）
git branch                   # feature 没了
`~

**找回**：

`bash
git reflog
`~

找到写着 `c2 重要工作` 的那一行，记下哈希（比如 `a1b2c3d`）。

`bash
git branch feature a1b2c3d
git switch feature
ls                            # b.txt 回来了
`~

## stash：临时存一下

改到一半，突然要切分支做别的事：

`bash
echo "改了一半" > a.txt
git stash                     # 收进抽屉
git status                    # 干净了
git stash list                # 看到一条
git stash pop                 # 拿出来
`~

## 验收

1. 删掉一个有提交的分支，用 reflog 恢复它
2. 用 stash 暂存改动，切分支再切回来，pop 出来
3. 说清 `reflog` 和 `log` 的区别

## 坑

- `git branch -d` 删有未合并提交的分支会拒绝，`-D` 强制删 —— **这正是会丢东西的时候**
- reflog 默认保留 90 天，过期就真没了
- `git add` 过但没 commit 的内容，reflog 救不回来（因为没进版本库）
