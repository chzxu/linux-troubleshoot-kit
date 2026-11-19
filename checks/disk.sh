#!/usr/bin/env bash
# shellcheck source=lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

section "磁盘使用率"
code "df -h"
_out "$(df -h)"
ok "df 磁盘使用率检查完成"

section "大目录占用"
code "timeout 30 du -x --max-depth=1 / | sort -rh | head"
warn "正在扫描根分区（约 26 GB），首次可能要十几秒…"
_out "$(timeout 30 du -x --max-depth=1 / 2>/dev/null | sort -rh | head)"
ok "大目录占用检查完成"

section "已删除未释放的文件"
code "lsof +L1 | grep deleted"
_out "$(timeout 15 lsof +L1 2>/dev/null | grep deleted || true)"
warn "普通用户只能看到自己的进程；要看全部请手动执行 sudo lsof +L1"
ok "lsof 已删除未释放的文件检查完成"
