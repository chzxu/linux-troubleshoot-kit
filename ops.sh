#!/usr/bin/env bash
set -euo pipefail

BASE="$(dirname "$0")"

# shellcheck source=lib/common.sh
source "$BASE/lib/common.sh"

CMD="${1:-}"

if [ -z "$CMD" ]; then
    echo "用法: $0 disk [-o 文件]"
    exit 1
fi

if [ "${2:-}" = "-o" ]; then
    # 由 lib/common.sh 的 _out() 使用，所以导出给被 source 的文件
    export REPORT="${3:-}"
fi

case "$CMD" in
    disk)
        # shellcheck source=checks/disk.sh
        source "$BASE/checks/disk.sh"
        ;;
    *)
        echo "未知命令: $CMD"
        echo "用法: $0 disk [-o 文件]"
        exit 1
        ;;
esac