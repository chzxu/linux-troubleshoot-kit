# 案例 02 · 删除文件后，空间没有释放

## 1. 症状

<!-- 写现象，不写原因。三行以内。 -->

- 现象：就是我写入文件之后将他加入到进程之后删除文件，发现空间没有变回
- 发现方式：自己做的实验，主动构造
- 影响：没彻底删除，占用空间

## 2. 环境

- 系统：Ubuntu 22.04（WSL2）
- 文件系统：ext4
- 时间：2026-11-15

## 3. 排查过程

### 3.1 建立基线

<!-- 先看清删除前的状态，这是后面判断"没释放"的依据 -->

```bash
df -h / | tail -1
```

输出：

```text
Filesystem      Size  Used Avail Use% Mounted on
/dev/sdd       1007G   26G  930G   3% /
```

### 3.2 造文件并确认占用

```bash
fallocate -l 5G /tmp/held.log
df -h / | tail -1
```

输出：

```text
Filesystem      Size  Used Avail Use% Mounted on
/dev/sdd       1007G   31G  925G   4% /
```

### 3.3 让进程持有文件，然后删除

```bash
tail -f /tmp/held.log > /dev/null &#持续跟踪 /tmp/held.log 文件末尾，文件有新内容就输出。把输出丢弃，不显示到终端。放到后台运行。
jobs -l#查看当前进程
rm -f /tmp/held.log
ls -l /tmp/held.log
df -h / | tail -1
这组命令是在演示一个经典现象：文件被删除后，如果仍有进程打开它，磁盘空间可能不会立即释放。
```

输出：

```text
ls: cannot access '/tmp/hog.img': No such file or directory
Filesystem      Size  Used Avail Use% Mounted on
/dev/sdd       1007G   31G  925G   4% /
```

<!-- 注意：这一步的 df 是整篇的关键。
     如果空间释放了，说明复现失败，不要往下写。
     如果空间没释放，把数字原样贴上来。 -->

### 3.4 找出谁还持有这个文件

```bash
lsof +L1
```

输出：

```text
COMMAND  PID      USER   FD   TYPE DEVICE   SIZE/OFF NLINK  NODE NAME
tail    5072 username    3r   REG   8,48 5368709120     0 59388 /tmp/hog.img (deleted)
```

<!-- 关注三处：
     NLINK 是不是 0？
     最后一列有没有 (deleted)？
     COMMAND 是不是 tail？ -->

### 3.5 修复与验证

```bash
pkill -f "tail -f /tmp/held.log"#按名称/模式杀进程
sleep 1
df -h / | tail -1
```

输出：

```text
Filesystem      Size  Used Avail Use% Mounted on
/dev/sdd       1007G   26G  930G   3% /
```

## 4. 根因

<!-- 用自己的话写机制，不要写"因为文件被占用了"这种结论。
     提示方向：
       rm 到底删了什么？（是数据吗？）
       inode 的引用计数什么时候归零？
       为什么 du 看不到，df 却看得到？ -->

`rm` 主要删的是“目录项”和“链接计数”，数据块不一定马上释放。

```
要满足i_nlink == 0  且  没有进程打开该文件（i_count == 0）
```

`du` 沿目录树统计，看不到已删除文件；`df` 看文件系统块分配，所以仍能看到被占用的空间。

## 5. 预防

<!-- 三条，都要能落地执行 -->

- 怎么避免再次发生：删除文件之后要观察空间是否变化
- 怎么提前发现：写脚本自动化检查
- 万一又发生，怎么最快恢复：记住就行了

## 附 · 命令速查

| 命令               | 作用                         | 注意                                 |
| ------------------ | ---------------------------- | ------------------------------------ |
| `df -h`            | 文件系统层面的空间           | 统计的是块设备                       |
| `du -sh`           | 目录/文件的占用              | 遍历目录，看不到已删除但被打开的文件 |
| `lsof +L1`         | 找 link count < 1 的打开文件 | 需要安装 lsof                        |
| `> /proc/PID/fd/N` | 不杀进程直接截断文件         | 线上应急用                           |