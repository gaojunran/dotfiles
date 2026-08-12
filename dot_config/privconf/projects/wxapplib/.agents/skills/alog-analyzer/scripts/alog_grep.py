#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
ALog 日志分析辅助工具

三个子命令：
    detect-platform  检测日志平台
    grep             单条 ALog tag 正则匹配日志，提取捕获组值
    batch-grep       批量匹配：接受 alog_keyword.py --export 的 JSON，一次扫描提取所有关键词

用法:
    python3 alog_grep.py detect-platform --log weapp.log
    python3 alog_grep.py grep --tag '/cost=(?<$10>\\d+)/' --log weapp.log
    python3 alog_grep.py batch-grep --keywords keywords.json --log weapp.log
"""

import argparse
import json
import re
import sys

# magicbox File: 路径前缀 → 平台
_FILE_PATH_PLATFORM = [
    ("/data/user/0/com.tencent.mm/",  "Android"),
    ("/data/data/com.tencent.mm/",    "Android"),
    ("/var/mobile/Containers/",       "iOS"),
    ("/data/storage/el2/base/",       "OHOS"),
]


def detect_log_platform(log_path, tail=200):
    """从日志末尾 magicbox 块判断平台。

    Returns:
        tuple: ('Android'|'iOS'|'OHOS'|'Unknown', detail_str)
    """
    try:
        with open(log_path, encoding="utf-8", errors="replace") as f:
            f.seek(0, 2)
            file_size = f.tell()
            seek_pos = max(0, file_size - tail * 200)
            f.seek(seek_pos)
            if seek_pos > 0:
                f.readline()
            tail_lines = f.readlines()[-tail:]
    except OSError:
        return "Unknown", ""

    for line in tail_lines:
        stripped = line.strip()
        if stripped.startswith("File:"):
            file_path = stripped[5:]
            for prefix, platform in _FILE_PATH_PLATFORM:
                if file_path.startswith(prefix):
                    return platform, f"File:{file_path}"
            return "Unknown", f"File:{file_path}（路径未识别）"

    for line in tail_lines:
        stripped = line.strip()
        if stripped.startswith("WeChat Alita: OHOS"):
            return "OHOS", stripped
        if stripped.startswith("System Platform:iOS"):
            return "iOS", stripped
        if stripped.startswith("Device:") and "android-" in stripped:
            return "Android", stripped

    return "Unknown", ""


def normalize_tag(tag):
    """ALog tag → Python re 格式。

    /.../ 去首尾，(?<$N>...) → (?P<g_N>...)
    """
    if tag.startswith("/") and tag.endswith("/"):
        tag = tag[1:-1]
    tag = re.sub(r"\(\?<\$(\w+)>", r"(?P<g_\1>", tag)
    return tag


def cmd_detect_platform(args):
    platform, detail = detect_log_platform(args.log)
    print(f"平台: {platform}")
    if detail:
        print(f"依据: {detail}")


def cmd_grep(args):
    try:
        normalized = normalize_tag(args.tag)
        pattern = re.compile(normalized)
    except re.error as e:
        print(f"正则编译失败: {e}", file=sys.stderr)
        sys.exit(1)

    max_lines = args.max_lines
    hit_count = 0

    try:
        with open(args.log, encoding="utf-8", errors="replace") as f:
            for lineno, line in enumerate(f, 1):
                m = pattern.search(line)
                if m:
                    named = {
                        f"${k[2:]}": v
                        for k, v in m.groupdict().items()
                        if k.startswith("g_") and v is not None
                    }
                    parts = [f"L{lineno}: {line.rstrip()[:200]}"]
                    if named:
                        parts.append("  捕获: " + ", ".join(
                            f"{k}={v}" for k, v in sorted(named.items())
                        ))
                    print("".join(parts))
                    hit_count += 1
                    if hit_count >= max_lines:
                        print(f"（已达 {max_lines} 行上限，停止匹配）")
                        break
    except OSError as e:
        print(f"错误：无法读取日志文件: {e}", file=sys.stderr)
        sys.exit(1)

    if hit_count == 0:
        print("未命中")
    else:
        print(f"\n共命中 {hit_count} 行")


def cmd_batch_grep(args):
    """批量匹配：一次扫描日志，匹配所有关键词并提取捕获组。"""
    try:
        with open(args.keywords, encoding="utf-8") as f:
            scenes = json.load(f)
    except (OSError, json.JSONDecodeError) as e:
        print(f"错误：关键词文件读取失败: {e}", file=sys.stderr)
        sys.exit(1)

    # 编译所有关键词正则，跳过 disabled 和无 tag 的
    compiled = []  # [(scene_name, desc, type, pattern), ...]
    for scene in scenes:
        scene_name = scene.get("name", "")
        for kw in scene.get("keywords", []):
            if kw.get("disable") or not kw.get("tag"):
                continue
            try:
                pat = re.compile(normalize_tag(kw["tag"]))
                compiled.append((scene_name, kw.get("desc", ""), kw.get("type", ""), pat))
            except re.error:
                continue

    if not compiled:
        print("无有效关键词")
        return

    max_lines = args.max_lines
    # hit_counts[i] = 该关键词已命中行数
    hit_counts = [0] * len(compiled)
    # 已达上限的关键词数
    done_count = 0

    try:
        with open(args.log, encoding="utf-8", errors="replace") as f:
            for lineno, line in enumerate(f, 1):
                if done_count >= len(compiled):
                    break
                for i, (scene_name, desc, ktype, pattern) in enumerate(compiled):
                    if hit_counts[i] >= max_lines:
                        continue
                    m = pattern.search(line)
                    if m:
                        named = {
                            f"${k[2:]}": v
                            for k, v in m.groupdict().items()
                            if k.startswith("g_") and v is not None
                        }
                        capture_str = ""
                        if named:
                            capture_str = "  捕获: " + ", ".join(
                                f"{k}={v}" for k, v in sorted(named.items())
                            )
                        print(f"[{desc}] L{lineno}: {line.rstrip()[:200]}{capture_str}")
                        hit_counts[i] += 1
                        if hit_counts[i] >= max_lines:
                            done_count += 1
    except OSError as e:
        print(f"错误：无法读取日志文件: {e}", file=sys.stderr)
        sys.exit(1)

    # 汇总
    print("\n--- 汇总 ---")
    for i, (scene_name, desc, ktype, _) in enumerate(compiled):
        count = hit_counts[i]
        status = f"命中 {count} 行" if count > 0 else "未命中"
        print(f"  [{scene_name}] {desc} ({ktype}): {status}")


def main():
    parser = argparse.ArgumentParser(description="ALog 日志分析辅助工具")
    sub = parser.add_subparsers(dest="command", required=True)

    p_detect = sub.add_parser("detect-platform", help="检测日志平台")
    p_detect.add_argument("--log", "-l", required=True, help="日志文件路径")

    p_grep = sub.add_parser("grep", help="用 ALog tag 正则匹配日志并提取捕获组")
    p_grep.add_argument("--tag", "-t", required=True, help="ALog tag 正则（支持 /.../ 格式和 (?<$N>) 捕获组）")
    p_grep.add_argument("--log", "-l", required=True, help="日志文件路径")
    p_grep.add_argument("--max-lines", type=int, default=20, help="最多输出命中行数（默认 20）")

    p_batch = sub.add_parser("batch-grep", help="批量匹配：接受 keywords JSON，一次扫描提取所有关键词")
    p_batch.add_argument("--keywords", "-k", required=True, help="alog_keyword.py --export 导出的 JSON 文件")
    p_batch.add_argument("--log", "-l", required=True, help="日志文件路径")
    p_batch.add_argument("--max-lines", type=int, default=10, help="每个关键词最多输出命中行数（默认 10）")

    args = parser.parse_args()
    if args.command == "detect-platform":
        cmd_detect_platform(args)
    elif args.command == "grep":
        cmd_grep(args)
    elif args.command == "batch-grep":
        cmd_batch_grep(args)


if __name__ == "__main__":
    main()
