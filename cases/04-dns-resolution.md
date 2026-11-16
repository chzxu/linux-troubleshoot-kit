# 案例 04 · DNS 解析：同一个域名，两个工具看到的不一样

> 环境：Ubuntu 22.04（WSL2）· 实测于 2026-11-16

## 1. 症状

<!-- 写现象，不写原因。这个案例是"主动构造"的，所以症状可以写你原本想查什么 -->

- 现象：我使用dig和getent解析同一个域名出不同的内容
- 发现方式：通过dig和getent指令并观察
- 影响：观察查看的内容

## 2. 环境

- 系统：Ubuntu 22.04（WSL2）
- DNS 服务器：
- nsswitch：

## 3. 排查过程

### 3.1 基线：两个工具看法一致

```bash
dig example.com +short
//dig：直接向 DNS 服务器发 DNS 查询包，不读 /etc/hosts，也不走 nsswitch.conf

getent ahostsv4 example.com
//getent：调用 getaddrinfo()，走 NSS（Name Service Switch），通常按 /etc/nsswitch.conf 里的 hosts: 顺序查，例如 files dns，即先查 /etc/hosts，再查 DNS。
```

输出：

```text
172.66.147.243
104.20.23.154//dig

172.66.147.243  STREAM example.com
172.66.147.243  DGRAM
172.66.147.243  RAW
104.20.23.154   STREAM
104.20.23.154   DGRAM
104.20.23.154   RAW//getent
```

<!-- 两条应该给同样的 IP。这是"正常"的样子 -->

### 3.2 制造分歧：改 hosts

```bash
sudo sh -c 'echo "127.0.0.1 example.com" >> /etc/hosts'
getent ahostsv4 example.com
dig example.com +short
```

输出：

```text
sudo sh -c 'echo "127.0.0.1 example.com" >> /etc/hosts'
getent ahostsv4 example.com
127.0.0.1       STREAM example.com
127.0.0.1       DGRAM
127.0.0.1       RAW
dig example.com +short
172.66.147.243
104.20.23.154
```

<!-- 核心现象：getent 变成 127.0.0.1，dig 完全不动 -->

因为 `dig` 绕过 `/etc/hosts`，直接问 DNS。

**`getent` 受 hosts 影响，`dig` 不受。**

### 3.3 第三方验证：程序到底跟谁走

```bash
curl -v --connect-timeout 3 http://example.com/ 2>&1 | head -8
```

输出：

```text
curl -v --connect-timeout 3 http://example.com/ 2>&1 | head -8
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0* Host example.com:80 was resolved.
* IPv6: 2606:4700:10::ac42:93f3, 2606:4700:10::6814:179a
* IPv4: 172.66.147.243, 104.20.23.154
*   Trying 172.66.147.243:80...
*   Trying [2606:4700:10::ac42:93f3]:80...
* Immediate connect fail for 2606:4700:10::ac42:93f3: Network is unreachable
```

<!-- 看 Trying 那行：它用的是 127.0.0.1，说明程序走 getent 那条路 -->

大多数 Linux 程序通过 `getaddrinfo()` 走 NSS，因此通常和 `getent` 一致；但 `curl` 等程序取决于编译选项和解析器实现，不能一概而论。排查时 `getent` 通常比 `dig` 更接近普通程序，但最好用实际程序验证。

### 3.4 不存在的域名长什么样

```bash
getent hosts NoSuchDomain-abc123.com
dig NoSuchDomain-abc123.com +short
dig NoSuchDomain-abc123.com | grep status
```

输出：

```text
 getent hosts NoSuchDomain-abc123.com
dig NoSuchDomain-abc123.com +short
dig NoSuchDomain-abc123.com | grep status
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 43416
```

### 3.5 意外发现：UDP 53 被劫持

<!-- 这一段是本案例的隐藏关卡，原计划是"看超时要多久"，结果根本没超时 -->

```bash
time dig @192.0.2.1 example.com +short
dig +tcp @192.0.2.1 example.com +short
```

输出：

```text
time dig @192.0.2.1 example.com +short
172.66.147.243
104.20.23.154

real    0m0.095s
user    0m0.007s
sys     0m0.021s
--------------------------------------------------------

dig +tcp @192.0.2.1 example.com +short
;; Connection to 192.0.2.1#53(192.0.2.1) for example.com failed: timed out.
;; no servers could be reached
;; Connection to 192.0.2.1#53(192.0.2.1) for example.com failed: timed out.
;; no servers could be reached
;; Connection to 192.0.2.1#53(192.0.2.1) for example.com failed: timed out.
;; no servers could be reached
```

<!-- 192.0.2.1 是 RFC 5737 的测试保留地址，现实中不存在。
     UDP 查询秒回 = 被链路中间截获并重定向；
     +tcp 超时   = 这条路才是真的发到外面去了 -->

### 3.6 清理与验证

```bash
sudo sed -i '/example.com/d' /etc/hosts
getent ahostsv4 example.com
```

输出：

```text
172.66.147.243  STREAM example.com
172.66.147.243  DGRAM
172.66.147.243  RAW
104.20.23.154   STREAM
104.20.23.154   DGRAM
104.20.23.154   RAW
```

## 4. 根因

<!-- 分两层写：

     第一层：为什么 getent 和 dig 结果不同？
       /etc/nsswitch.conf 里 hosts: files ... dns
       files 在 dns 前面 → 先查 /etc/hosts
       程序调的是 getaddrinfo()，走 nsswitch
       dig 直接构造 DNS 查询包，不走 nsswitch
    
     第二层（隐藏关卡）：为什么 @192.0.2.1 也能秒回？
       WSL2 会截获发往任意地址的 UDP 53 请求，转发给内部 DNS 代理
       TCP 53 没被截获，所以 +tcp 才真的超时
-->

## 5. 预防

<!-- 三条，要能落地。提示方向：
     线上怎么确认"解析到的是不是 hosts 里的"？
     排查时该用哪个工具才和程序一致？
     容器/CI 里 hosts 被注入过怎么办？
-->

- 怎么避免再次发生：不要随意往 `/etc/hosts` 写业务域名；需要本地覆盖时使用明确的 hosts 管理工具/配置，并在变更记录里标注；
- 怎么提前发现：排查域名解析时优先用 `getent ahostsv4 <域名>`，并与 `dig <域名> +short` 对比
- 万一又发生，怎么最快恢复：先 `grep <域名> /etc/hosts` 确认是否被覆盖；删除或注释对应行；清理缓存（`sudo resolvectl flush-caches` 或 `sudo nscd -i hosts`，视系统而定）
- 这算dns劫持吧

## 附 · 命令速查

| 命令 | 作用 | 关键点 |
|---|---|---|
| `getent hosts <域名>` | 走 nsswitch，**和程序一致** | 排查时优先用它 |
| `getent ahostsv4 <域名>` | 只要 IPv4 | 排除 AAAA 干扰//ipv6 |
| `dig <域名> +short` | 只问 DNS 服务器 | **绕过 hosts** |
| `dig +tcp @<服务器>` | 强制 TCP 查询 | 验证是否被劫持 |
| `cat /etc/resolv.conf` | 看实际用的 DNS | WSL 里通常是 10.255.255.254 |
| `grep hosts /etc/nsswitch.conf` | 看解析顺序 | files 在前 = hosts 优先 |

## 进阶问题

1. 改了 `/etc/hosts` 之后，为什么有的程序立刻生效，有的要重启？（提示：进程会缓存）**hosts 修改对下一次 `getaddrinfo()` 通常生效；但应用缓存、连接池、nscd/resolved 缓存需要清理或重启。**
2. `/etc/resolv.conf` 里可以写多个 `nameserver`，实际是怎么选的？顺序优先
3. 容器里的 `/etc/hosts` 是谁写的？为什么 K8s 里每个 Pod 的 hosts 不一样？

容器里的 `/etc/hosts` 不是 DNS 服务器写的，而是**容器运行时**在创建容器时生成并挂载进去的。
