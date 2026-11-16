# 案例 05 · 都是「连不上」，但原因相反

> 环境：Ubuntu 22.04（WSL2）· 实测于 2026-11-16

## 1. 症状

<!-- 写现象，不写原因。
     这个案例是主动构造的，所以"症状"可以照 04 的写法：
     先写我想确认什么，再写两个错误看起来有多像。
     影响要写"分不清会导致什么"，别写"观察查看的内容"。 -->

- 现象：关于网页服务连不上，需要理解是因为什么才连不上
- 发现方式：用 curl 打不同的地址，看报错文字和耗时
- 影响：让用户无法使用服务，并且运维这边不清楚为啥连不上

## 2. 环境

- 系统：Ubuntu 22.04（WSL2，网络模式 NAT）
- 内核：6.18.58.1-microsoft-standard-WSL2
- 客户端地址：172.26.65.110/20（`ip -4 addr show eth0`）
- 网关：172.26.64.1 —— 就是 Windows 侧的 `vEthernet (WSL (Hyper-V firewall))`
  <!-- 每次重启 WSL 这个网段都可能变，别写死；用 ip route 现取 -->
- 回环：127.0.0.1

## 3. 排查过程

### 3.1 基线：服务能连

```bash
python3 -m http.server 8080 &
curl -s -o /dev/null -w 'HTTP %{http_code} 用时 %{time_total}s\n' http://127.0.0.1:8080/
```

输出：

```text
Serving HTTP on 0.0.0.0 port 8080 (http://0.0.0.0:8080/) ...
127.0.0.1 - - [16/Nov/2026 18:54:59] "GET / HTTP/1.1" 200 -
HTTP 200 用时 0.029656s
```

### 3.2 refused · 本机没人监听的端口

```bash
curl -sv --connect-timeout 3 http://127.0.0.1:9/
```

输出：

```text
*   Trying 127.0.0.1:9...
* connect to 127.0.0.1 port 9 from 127.0.0.1 port 35632 failed: Connection refused
* Failed to connect to 127.0.0.1 port 9 after 0 ms: Couldn't connect to server
* Closing connection
```

<!-- 拆这四行：
     第 2 行拆三段：对方(172.26.64.1:9) / 自己(172.26.65.110:45406) / 结果(refused)
     "自己 port 45406" 是客户端临时端口 —— 案例 03 里的 58008 是同一个东西
     第 3 行的 after 0 ms 是主角：有回音，所以几乎不花时间

     注意 after N ms 只算"建立连接"这一段，不能和 3.1 的 time_total 直接比。
     要和 %{time_connect} 比。 -->

### 3.3 refused · 跨主机（网关，同样没人监听）

```bash
GW=$(ip route | awk '/^default/{print $3}')
echo "网关 = $GW"
curl -sv --connect-timeout 3 "http://$GW:9/"
```

输出：

```text
网关 = 172.26.64.1
*   Trying 172.26.64.1:9...
* connect to 172.26.64.1 port 9 from 172.26.65.110 port 45406 failed: Connection refused
* Failed to connect to 172.26.64.1 port 9 after 0 ms: Couldn't connect to server
* Closing connection
```

<!-- 这条比 3.2 值钱，原因写清楚：
     172.26.64.1 不是本机地址，包真的出去了 → 对面真的回话了
     所以它证明了：WSL 到 Windows 这条路是通的、Windows 活着、9 号端口没开
     一次 0 ms 拿到三个确定信息

     可加的旁证：
       ping -c 2 $GW     → ttl=128（Windows 默认；Linux 是 64）
       ping -c 2 127.0.0.1 → ttl=64 对比
     "一条 ping 看出回应我的是 Linux 还是 Windows"
     
     顺带记：172.26.64.1 在 Windows 侧叫 vEthernet (WSL (Hyper-V firewall))
     这一步还是"不用写脚本"的现成例子 —— 变量在同一个终端里跨行有效 -->

### 3.4 timeout · 一个永远不存在的地址

```bash
curl -sv --connect-timeout 4 http://192.0.2.1/
```

输出：

```text
*   Trying 192.0.2.1:80...
* ipv4 connect timeout after 4000ms, move on!
* Failed to connect to 192.0.2.1 port 80 after 4000 ms: Timeout was reached
* Closing connection
```

<!-- 192.0.2.0/24 是 RFC 5737 划给文档用的保留段（TEST-NET-1），
     连同 198.51.100.0/24、203.0.113.0/24，永远不分配给真实主机。
     所以没人会回 —— 用它专门制造 timeout。

     要对比的就一个数：3.2/3.3 的 0 ms vs 这里的 after ???? ms。 -->

### 3.5 决定性实验：同一个端口，只改防火墙

```bash
# 先确认 8080 上的服务还活着
curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:8080/

# 一个"吞掉"（结果应该是 timeout）
sudo iptables -I INPUT 1 -p tcp --dport 8080 -j DROP
# 一个"明确拒绝"（结果应该是 refused）
sudo iptables -I INPUT 1 -p tcp --dport 8081 -j REJECT --reject-with tcp-reset

curl -sv --connect-timeout 4 http://127.0.0.1:8080/
curl -sv --connect-timeout 3 http://127.0.0.1:8081/

# 立刻清理，别把规则留在机器里
sudo iptables -D INPUT -p tcp --dport 8080 -j DROP
sudo iptables -D INPUT -p tcp --dport 8081 -j REJECT --reject-with tcp-reset
```

输出：

8080（被 DROP）：

```text
*   Trying 127.0.0.1:8080...
* ipv4 connect timeout after 4000ms, move on!
* Failed to connect to 127.0.0.1 port 8080 after 4000 ms: Timeout was reached
* Closing connection
```

8081（被 REJECT）：

```text
*   Trying 127.0.0.1:8081...
* connect to 127.0.0.1 port 8081 from 127.0.0.1 port 48632 failed: Connection refused
* Failed to connect to 127.0.0.1 port 8081 after 0 ms: Couldn't connect to server
* Closing connection
```

<!-- 这是整个案例的灵魂：
     同一台机器、同样"没人能连上"，只因为防火墙策略不同，
     客户端看到的错误完全相反。
     
     DROP 让你以为"网络不通"，REJECT 让你立刻知道"端口没开"。
     
     顺便回看 3.1 埋的伏笔：8080 明明有服务在跑，
     但被 DROP 之后，服务器日志里一个字都不会有。
     和案例 02 的"du 看不到、df 看得到"是同一类"证据在哪一层"的问题。 -->

### 3.6 看见那个 RST

```bash
# 一个窗口开抓包
sudo tcpdump -i lo -n port 8081

# 另一个窗口敲
curl -s --connect-timeout 2 http://127.0.0.1:8081/
```

输出：

```text
listening on lo, link-type EN10MB (Ethernet), snapshot length 262144 bytes
21:19:11.579616 IP 127.0.0.1.33806 > 127.0.0.1.8081: Flags [S], seq 785172159, win 65495, options [mss 65495,sackOK,TS val 2492153497 ecr 0,nop,wscale 10], length 0
21:19:11.579688 IP 127.0.0.1.8081 > 127.0.0.1.33806: Flags [R.], seq 0, ack 785172160, win 0, length 0
```

<!-- 要能在抓包里看到带 RST 标志的那个包。
     背结论和看见包，是两回事。 -->

### 3.7 清理与验证

```bash
curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:8080/
```

输出：

```text
127.0.0.1 - - [16/Nov/2026 21:21:38] "GET / HTTP/1.1" 200 -
200
```

## 4. 根因

那个 `Flags [R.]` 是**目标机器的内核**发出来的：它收到我的 SYN，查了一下 8081 上没有程序在监听，
就直接回一个 RST 让我死心。这次走的是 loopback，所以那台"目标机器"就是我自己；换成跨主机，
就是对面那台机器的内核。

从 SYN（`579616`）到 RST（`579688`）只隔 **72 微秒**。这个数字说明的事情只有一件：
**有个包真的回来了**。它没走物理网络所以快，但重点不是快，是"有回音"。

所以一句话：

- **refused 是"等到了一个明确的否定"**
- **timeout 是"什么都没等到"**

排查的时候这就是分界线：前者去查服务，后者去查网络。

## 5. 预防

<!-- 三条，要能落地。提示方向：
      ① 线上怎么一眼区分这两种错误？（看日志里是哪一种，别一上来就重启）
      ② 防火墙该用 DROP 还是 REJECT？安全和可排查性怎么权衡？
      ③ 服务监听 0.0.0.0 还是 127.0.0.1，会改变客户端看到的现象吗？ -->

- 怎么避免再次发生：
- 怎么提前发现：
- 万一又发生，怎么最快恢复：

## 附 · 命令速查

| 命令 | 作用 | 关键点 |
|---|---|---|
| `curl -sv --connect-timeout N <url>` | 看连接失败的具体原因 | `-s` 关进度条，`-v` 开调试，`--connect-timeout` 限制等待 |
| `-w '%{time_connect}'` | 只算"建立连接"这一段 | 和 curl 报的 `after N ms` 同口径 |
| `ip route` | 找默认网关 | `default via` 后面那个 IP |
| `ping -c 2 <ip>` | 判断对面活没活 | 看 `ttl`：128 = Windows，64 = Linux |
| `nc -zv <ip> <端口>` | 只测端口通不通 | refused / timed out 直接打出来 |
| `ss -tulpn` | 看谁在监听 | 绑 `0.0.0.0` 和 `127.0.0.1` 是两回事 |
| `iptables -I INPUT 1 -p tcp --dport N -j DROP` | 模拟"包被吞" | 结果 = timeout |
| `iptables -I INPUT 1 -p tcp --dport N -j REJECT --reject-with tcp-reset` | 模拟"明确拒绝" | 结果 = refused |
| `tcpdump -i lo -n port N` | 抓包看 RST | 见到那个包，才算真懂 |

## 进阶问题

1. `curl 127.0.0.1:9` 是 refused，`curl 192.0.2.1:80` 是 timeout。这两次在内核里分别发生了什么？哪一个有包回来？

   **包回来了，是本机内核回的 RST**，告诉你“这个端口没人监听”

   **没有 TCP 包回来**，SYN 发出去石沉大海，只能等超时。

2. `iptables` 的 DROP 和 REJECT，线上该选哪个？（提示：一个泄露信息，一个坑死排查的人）

3. 服务监听 `0.0.0.0:8080` 和监听 `127.0.0.1:8080`，从别的机器连你，现象一样吗？分别是哪种错误？

4. K8s 里一个 Pod 连不上 Service，用今天的判据，你怎么三步定位？

   待续：W5 学完 K8s 回来补。
