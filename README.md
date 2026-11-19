# linux-troubleshoot-kit

Linux 故障排查实战记录。每篇案例都用真实命令跑出来，含症状、排查过程、根因、预防。

**不是教程，是我自己踩过的坑。**

## 案例

| # | 主题 | 一句话结论 |
|---|---|---|
| 01 | [磁盘写满基线](cases/01-disk-fill-baseline.md) | 正常删除 = 空间立刻回来，这是判断异常的标准 |
| 02 | [删除后空间不释放](cases/02-deleted-but-space-held.md) | `rm` 只删目录项，进程还开着 inode 就不释放 |
| 03 | [端口被占用](cases/03-port-already-in-use.md) | `EADDRINUSE` 是内核返回的，不是程序判定的 |
| 04 | [DNS 解析](cases/04-dns-resolution.md) | `getent` 走 nsswitch，`dig` 直接问 DNS，两条路 |
| 05 | [连接被拒绝 vs 连接超时](cases/05-refused-vs-timeout.md) | **refused 有回音，timeout 没有** |

## 脚本

```bash
bash checks/disk.sh      # 磁盘：使用率 / 大目录 / 删除未释放
```

## 进度

案例规划、脚本规划、简历项目，见 [ROADMAP.md](ROADMAP.md)。

## 环境

Ubuntu 22.04（WSL2），所有输出均为实测。
