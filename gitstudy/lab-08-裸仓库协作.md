# Lab 08 · 裸仓库模拟远程协作

## 目标

远程仓库到底是什么？为什么它没有工作区？

## 什么是裸仓库

普通仓库 = `.git` + 工作区（你能编辑文件）
裸仓库 = 只有 `.git` 的内容，**没有工作区**，不能直接改文件

**GitHub 上的仓库就是裸仓库**——它只负责存历史，不负责给你编辑。

## 动手：搭一个"假 GitHub"

`bash
cd ~/gitlab && mkdir -p remote && cd remote
git init --bare repo.git
`~

### 第一个人：克隆、提交、推

`bash
cd ~/gitlab
git clone remote/repo.git alice
cd alice
echo "alice 写的" > a.txt && git add . && git commit -m "alice: 初始化"
git push origin main
`~

### 第二个人：克隆同一份

`bash
cd ~/gitlab
git clone remote/repo.git bob
cd bob
cat a.txt            # 看到 alice 的内容
echo "bob 写的" > b.txt && git add . && git commit -m "bob: 加文件"
git push origin main
`~

### 第一个人拉取更新

`bash
cd ~/gitlab/alice
git pull origin main
ls                   # 看到了 b.txt
`~

## push / fetch / pull 的区别

| 命令 | 做什么 |
|---|---|
| `git fetch` | 把远程的新提交**下载**到本地，但**不合并** |
| `git pull` | `fetch` + `merge`（相当于下载并合并） |
| `git push` | 把本地提交**上传**到远程 |

## 验收

1. 搭一个裸仓库，两个克隆之间成功同步
2. 说清裸仓库和普通仓库的区别
3. 说清 `fetch` 和 `pull` 的差别

## 坑

`git init --bare` 建的目录**不能 cd 进去编辑文件**，它没有工作区。这是设计，不是坏了。

两个人同时改同一个文件再 push，第二个人会被拒绝——那正是 Lab 06 的冲突场景。
