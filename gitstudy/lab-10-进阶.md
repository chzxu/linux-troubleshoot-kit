# Lab 10 · 进阶：tag / bisect / hooks

## 目标

三个"知道有这回事"的技巧，用得不多但关键时刻救命。

## ① tag：给提交打版本号

`bash
cd ~/gitlab/01
git tag v1.0
git tag                       # 列出所有 tag
git tag -a v1.1 -m "第二个版本"   # 带注释的 tag
git show v1.0                 # 看 tag 指向哪次提交
`~

**用途**：发布版本时标记，比如 `v1.2.3`。运维部署时常用 `git checkout v1.2.3` 拉指定版本。

## ② bisect：二分查找"哪次提交引入了 bug"

场景：100 个提交，某个功能坏了，不知道从哪次开始。

`bash
cd ~/gitlab/10 && git init
for i in $(seq 1 20); do echo "v$i" > f.txt; git add .; git commit -m "c$i"; done
`~

假设第 15 次提交引入了 bug：

`bash
git bisect start
git bisect bad HEAD           # 当前是坏的
git bisect good <第1次的哈希>   # 第 1 次是好的
`~

之后 git 每次自动切到中间那次，你测试后告诉它 `good` 或 `bad`：

`bash
git bisect good    # 或 git bisect bad
`~

几次之后 git 会告诉你：**第一次坏掉的提交是 XXXX**。

`bash
git bisect reset    # 结束，回到原来的分支
`~

**20 个提交只需要 5 次，1000 个只需要 10 次。** 这就是二分。

## ③ hooks：提交前自动检查

`bash
cd ~/gitlab/01
ls .git/hooks/       # 有一堆 .sample 文件
`~

写一个 `.git/hooks/pre-commit`（去掉 .sample）：

`bash
#!/usr/bin/env bash
echo "提交前检查..."
if grep -rn "TODO" ./*.txt 2>/dev/null; then
    echo "发现 TODO，禁止提交"
    exit 1
fi
`~

`bash
chmod +x .git/hooks/pre-commit
echo "正常内容" > ok.txt
git add ok.txt && git commit -m "测试 hook"    # 通过
echo "TODO 待办" > bad.txt
git add bad.txt && git commit -m "应该被拦"    # 被拦
`~

**用途**：提交前跑 lint、检查敏感词、防止提交密码。

## 验收

1. 打一个 tag 并 checkout 到那个版本
2. 用 bisect 在 20 个提交里找出"第 15 次引入问题"
3. 写一个 pre-commit hook，拦住含 TODO 的提交

## 坑

- hooks 在 `.git/` 里，**不会随仓库推送到远程**。团队共享要用 `core.hooksPath` 指向仓库内的目录
- bisect 前要保证工作区干净
