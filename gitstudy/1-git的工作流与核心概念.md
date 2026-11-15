1、Git对象模型
Git是一个内容寻址文件系统，核心对象是：
blob    文件内容快照
tree    目录结构和文件引用
commit  一次提交，包含tree、parent、message
tag     对commit的命名引用

2、三种状态
工作区 → (git add) → 暂存区 → (git commit) → 本地仓库 → (git push) → 远程仓库

3、常用工作流
Git Flow	    master + develop + feature/release/hotfix 分支
GitHub Flow	    main + feature 分支，PR 合并
GitLab Flow	    main + pre-production + production 分支
Trunk-Based	    直接在 main 短分支，频繁合并

4、关键概念
HEAD: 指向当前分支的指针
origin: 默认远程仓库名称
upstream: 上游仓库（Fork 场景）
detached HEAD: HEAD 直接指向 commit 而非分支