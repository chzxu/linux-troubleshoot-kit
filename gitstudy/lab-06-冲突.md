# Lab 06 · 冲突：故意制造并解决

## 目标

冲突不可怕，它就是"git 不知道你要哪一个，让你决定"。

## 动手：制造冲突

`bash
cd ~/gitlab/06 && git init
echo "原始内容" > f.txt && git add . && git commit -m "c1"

git switch -c feature
echo "feature 的改法" > f.txt && git add . && git commit -m "c2"

git switch main
echo "main 的改法" > f.txt && git add . && git commit -m "c3"

git merge feature
`~

**合并失败**，输出 `CONFLICT (content): Merge conflict in f.txt`。

## 看冲突长什么样

`bash
cat f.txt
`~

`text
<<<<<<< HEAD
main 的改法
=======
feature 的改法
>>>>>>> feature
`~

三个标记的意思：

| 标记 | 含义 |
|---|---|
| `<<<<<<< HEAD` | 下面是**当前分支**的内容 |
| `=======` | 分隔线 |
| `>>>>>>> feature` | 下面是**要合并进来的分支**的内容 |

## 解决

**手工编辑这个文件**，删掉三个标记，留下你想要的最终内容：

`text
最终我保留的版本
`~

然后：

`bash
git add f.txt
git commit -m "解决冲突：合并 feature"
git log --oneline --graph --all
`~

## 验收

1. 亲手制造并解决一次冲突
2. 说清 `<<<<<<<` 和 `>>>>>>>` 各代表哪个分支
3. 冲突解决后 `git status` 是什么状态

## 坑

- **冲突时不要慌着 `git merge --abort`**，那会放弃合并，前面白做
- 编辑器里看不到冲突标记？确认你打开的是那个文件，不是别的
- 解决完必须 `git add`，git 才知道你处理完了
