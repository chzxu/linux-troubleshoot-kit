#!/usr/bin/env bash
# lib/common.sh -所有检查模块共用的工具函数
# 约定: REPORT为空=输出到屏幕上；非空=写入该文件里面

_out(){
    if [ -n "$REPORT" ]; then
        printf '%s\n' "$1" >> "$REPORT"
    else
        printf '%s\n' "$1"
    fi
}

section(){
    _out "";
    _out "## $1";
    _out "";
}

code(){
    _out ""
    _out '```text'
    _out "$1"
    _out '```'
    _out ""
}

_emit() { printf '%b %s\n' "$1" "$2" >&2; }
ok() { _emit "✅" "$1"; } 
warn() { _emit "⚠️" "$1"; }
fail() { _emit "❌" "$1"; }