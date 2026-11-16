#!/usr/bin/env bash
source "$(dirname "$0")/../lib/common.sh"

section "磁盘使用率"
code "df -h"
df -h
ok "df 磁盘使用率检查完成"

section "大目录占用"
code "timeout 30 du -x --max-depth=1 / | sort -rh | head"
timeout 30 du -x --max-depth=1 / 2>/dev/null | sort -rh | head
ok "大目录占用检查完成"

section "已删除未释放的文件"
code "timeout 30 sudo lsof +L1 | grep deleted"
timeout 30 sudo lsof +L1 | grep deleted
ok "lsof 已删除未释放的文件检查完成"