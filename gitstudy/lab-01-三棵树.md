# Lab 01 · 三棵树：工作区 / 暂存区 / 版本库

## 目标

搞清一件事：`git add` 到底把文件放到了哪里。

## 动手

在临时目录做，不要在主仓库里做。

`bash
mkdir -p ~/gitlab/01 && cd ~/gitlab/01
git init
echo "第一行" > a.txt
git status
`~

看到 `Untracked files` —— 文件在**工作区**，git 还没管。

`bash
git add a.txt
git status
`~

变成 `Changes to be committed` —— 现在在**暂存区**。

`bash
git commit -m "第一次提交"
git status
`~

`nothing to commit, working tree clean` —— 三棵树一致。

## 关键现象（本实验的核心）

`bash
echo "第二行" >> a.txt
git add a.txt
echo "第三行" >> a.txt
git status
`~

**同一个文件会出现两次**：

`text
Changes to be committed:
        modified:   a.txt      ← 你 add 进去的是"两行"的版本
Changes not staged for commit:
        modified:   a.txt      ← 磁盘上现在是"三行"的版本
`~

**`git add` 存的是你按下那一刻的快照，不是"这个文件"。**

## 验证

`bash
git diff            # 工作区 vs 暂存区
git diff --staged   # 暂存区 vs 版本库
`~

两个输出应该不一样。

## 验收

1. `git add` 之后文件在哪棵树？
2. 为什么 `git status` 会把同一个文件列两次？
3. `git diff` 和 `git diff --staged` 各比哪两棵树？

## 坑

- `git add .` 会把当前目录下所有未跟踪文件一起加进去，包括你不想提交的
- 提交前先 `git status`，别闭眼 `add .`
