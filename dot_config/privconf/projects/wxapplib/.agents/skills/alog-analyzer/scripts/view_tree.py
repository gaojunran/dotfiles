#!/usr/bin/env python3
"""用浏览器打开本地xlog_tree_viewer.html展示iOS视图树。

用法:
  python3 view_tree.py <log_file>                  # 打开 viewer
  python3 view_tree.py <log_file> --list            # 仅输出快照摘要表

原理：起单次HTTP服务serve日志文件，viewer通过fetch流式读取后服务自动退出。
"""
import argparse
import os
import re
import sys
import threading
import webbrowser
from http.server import HTTPServer, BaseHTTPRequestHandler

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
VIEWER_HTML = os.path.join(SCRIPT_DIR, "xlog_tree_viewer.html")

# 从 begin 行提取时间
_TIME_RE = re.compile(r'\[(\d{4}-\d{2}-\d{2} \+\d+\.?\d* \d{2}:\d{2}:\d{2}\.\d+)\]')
# 从首行内容提取 rootVc
_ROOT_VC_RE = re.compile(r'rootVc:<(\w+):')
# 提取顶层 ViewController 类名（树中缩进最浅的 orientations 行）
_VC_LAYER_RE = re.compile(r'layer\.name=\S+ \((\w+)\)')


def _list_snapshots(log_file: str):
    """扫描日志，输出每个视图树快照的索引、时间、根 VC。"""
    snapshots = []
    current_time = None
    current_root_vc = None
    current_top_vcs = []
    in_tree = False

    with open(log_file, 'r', errors='replace') as f:
        for line in f:
            if 'wc tree view begin' in line:
                in_tree = True
                current_top_vcs = []
                m = _TIME_RE.search(line)
                current_time = m.group(1).split(' ')[-1] if m else '?'  # 只取时分秒
                current_root_vc = None
            elif 'wc tree view end' in line:
                if in_tree:
                    snapshots.append((current_time, current_root_vc, current_top_vcs[:3]))
                in_tree = False
            elif in_tree:
                if current_root_vc is None:
                    m = _ROOT_VC_RE.search(line)
                    if m:
                        current_root_vc = m.group(1)
                m = _VC_LAYER_RE.search(line)
                if m:
                    vc = m.group(1)
                    if vc not in current_top_vcs:
                        current_top_vcs.append(vc)

    if not snapshots:
        print("未找到视图树快照")
        return

    print(f"共 {len(snapshots)} 个视图树快照：\n")
    print(f"{'#':<4} {'时间':<16} {'根VC':<30} {'关键页面'}")
    print('-' * 90)
    for i, (t, root, vcs) in enumerate(snapshots):
        root_str = root or '-'
        vcs_str = ', '.join(vcs) if vcs else '-'
        print(f"{i:<4} {t:<16} {root_str:<30} {vcs_str}")


def main():
    parser = argparse.ArgumentParser(description="iOS视图树本地可视化")
    parser.add_argument("log_file", help="日志文件路径")
    parser.add_argument("--list", action="store_true", help="仅输出快照摘要表，不打开浏览器")
    args = parser.parse_args()

    log_file = os.path.abspath(args.log_file)
    if not os.path.isfile(log_file):
        print(f"错误：文件不存在 {log_file}", file=sys.stderr)
        sys.exit(1)

    if args.list:
        _list_snapshots(log_file)
        return

    file_size = os.path.getsize(log_file)
    server_ref = [None]

    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            if self.path.startswith('/viewer'):
                with open(VIEWER_HTML, 'rb') as f:
                    data = f.read()
                self.send_response(200)
                self.send_header('Content-Type', 'text/html; charset=utf-8')
                self.send_header('Content-Length', len(data))
                self.end_headers()
                self.wfile.write(data)
            elif self.path == '/log':
                self.send_response(200)
                self.send_header('Content-Type', 'text/plain')
                self.send_header('Content-Length', file_size)
                self.end_headers()
                with open(log_file, 'rb') as f:
                    while chunk := f.read(65536):
                        self.wfile.write(chunk)
                threading.Timer(1, server_ref[0].shutdown).start()
            else:
                self.send_error(404)

        def log_message(self, *a):
            pass

    import socket
    with socket.socket() as s:
        s.bind(('127.0.0.1', 0))
        port = s.getsockname()[1]

    server_ref[0] = HTTPServer(('127.0.0.1', port), Handler)

    url = f"http://127.0.0.1:{port}/viewer?file=log"

    threading.Thread(target=server_ref[0].serve_forever, daemon=True).start()
    webbrowser.open(url)
    print(f"已打开视图树查看器（服务将在加载完成后自动退出）")
    server_ref[0].serve_forever()


if __name__ == "__main__":
    main()
