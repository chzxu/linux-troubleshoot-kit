# Lab 03 · 撤销的三种姿势

## 目标

改错了、add 错了、commit 错了，分别怎么退。

## 三种情况对应三个命令

| 你搞砸了哪一步 | 用什么 |
|---|---|
| 文件改乱了，想回到上次提交的样子 | `git restore <文件>` |
| 已经 `add` 了，想从暂存区拿回来 | `git restore --staged <文件>` |
| 已经 `commit` 了，想撤销这次提交 | `git reset` |

## 动手

`bash
cd ~/gitlab/03 && git init 2>/dev/null || (mkdir -p ~/gitlab/03 && cd ~/gitlab/03 && git init)
echo "v1" > f.txt && git add . && git commit -m "v1"
`~

### 场景 A：改乱了文件

`bash
echo "改坏了" > f.txt
git status          # modified
git restore f.txt
cat f.txt           # 回到 v1
`~

### 场景 B：add 错了

`bash
echo "v2" > f.txt
git add f.txt
git status          # 绿色，已暂存
git restore --staged f.txt
git status          # 红色，回到工作区
`~

### 场景 C：commit 错了

`bash
git add . && git commit -m "错误的提交"
git reset --soft HEAD~1     # 撤销提交，改动留在暂存区
git status                  # 改动还在，只是提交没了
`~

三种 `reset` 的区别：

| 参数 | 提交 | 暂存区 | 工作区 |
|---|---|---|---|
| `--soft` | 撤销 | 保留 | 保留 |
| `--mixed`（默认） | 撤销 | 清空 | 保留 |
| `--hard` | 撤销 | 清空 | **清空** |

**`--hard` 会丢代码，别乱用。**

## 验收

三种情况各救回来一次，能说出用哪个命令、为什么。

## 坑

`git checkout <文件>` 是老写法，新版本推荐 `git restore`，两者效果一样但后者语义更清楚。
