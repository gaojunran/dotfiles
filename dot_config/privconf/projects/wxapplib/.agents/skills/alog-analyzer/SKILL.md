---
name: alog-analyzer
version: 26040505
description: ALog 日志分析工具。当用户提供日志文件（含 xlog）、welog 链接，或提供 UIN/微信号要求排查或分析客户端日志或异常时触发。闪退问题优先由 crash-analyzer-skill 处理，卡顿报告优先由 ios-hang-analyzer 处理。
allowed-tools: Bash(python3:*), Bash(grep:*), Bash(cat:*)
---

# ALog 日志排查

根据用户问题描述分析日志，场景库关键词作为知识补充而非入口。

## 依赖脚本

- `alog_keyword.py`：位于 `alog-keyword-skill/scripts/` 目录，拉取场景关键词。**调用前需确认 alog-keyword 凭证已配置**（`credentials.json` 中 `alog.username` + `alog.token`）；`list` 查询免鉴权，但写操作需 token。在 AnyDev 容器中，`welog.woa.com` 必须走 HTTP（见 alog-keyword skill 的 HTTPS→HTTP 降级规则）。
- `alog_grep.py`：本 skill 的 `scripts/` 目录，三个子命令：
  - `detect-platform --log <file>`：检测日志平台
  - `grep --tag <alog_tag> --log <file>`：单条 ALog tag 正则匹配，提取捕获组值
  - `batch-grep --keywords <json> --log <file>`：批量匹配，接受 `--export` 的 JSON 一次扫描所有关键词

**Reference case studies**: `references/page-container-interception-timing.md` — page-container NavigateBackInterception 时序竞态的 ALog 分析案例，含时序证据和关键 grep 词。

## 硬性规则

1. **禁止跳过平台检测**：拿到日志后第一步必须检测平台，后续搜索和分析都依赖平台信息。
2. **禁止不搜场景库就直接 grep**：grep 前必须先用 `--search` 搜场景库读 desc 列表，了解该 grep 什么信号。
3. **禁止场景库无结果就停止分析**：搜不到匹配场景时，凭问题类型和平台自行推断 grep 词继续分析。
4. **禁止无问题描述就开始分析**：用户只给日志没描述问题时，必须先询问异常现象再继续。
5. **禁止把 grep 结果全量输出**：grep 命中超过 20 行时，只采样关键行，给出总结性结论。
6. **禁止用 `grep` 提取 ALog 捕获组值**：tag 含 `(?<$N>)` 时必须用 `alog_grep.py grep --tag`；关键词多时用 `batch-grep --keywords`。
7. **scenePrompt 按需取用**：仅在结论不确定或用户明确要求时才取 scenePrompt 补充判断。
8. **分析中发现场景库未覆盖的有效模式时，主动询问用户是否沉淀为关键词**，确认后通过 Skill 工具调用 `alog-keyword-skill` 新增。
9. **禁止 grep/perl 命令不限制输出行数**：所有 grep/perl/awk 命令必须 `| head -50`（或更小），需要更多行时分批取。禁止一次性将大段日志灌入 context。
10. **禁止 ≥3 个信号逐条 grep**：3 个及以上关键词必须用 `batch-grep --keywords` 一次扫描，减少调用次数。
11. **禁止重复执行相同查询**：compact 恢复后，已写入分析笔记的结论直接引用，禁止重新 grep 验证。
12. **视图树可视化**：禁止用 Grep 工具检测视图树，必须用 Bash 执行 `grep -c 'wc tree view begin' "$LOG_FILE"`。命中时：
    1. 先用 `--list` 输出快照摘要表展示给用户：
       ```bash
       python3 "$SKILL_DIR/scripts/view_tree.py" "$LOG_FILE" --list
       ```
    2. 询问用户是否打开浏览器查看。
    3. 用户确认后再启动 viewer：
       ```bash
       python3 "$SKILL_DIR/scripts/view_tree.py" "$LOG_FILE"
       ```
    禁止在 skill 中手动解析视图树内容。
13. **OOM/内存类问题必须回溯基线**：分析 OOM/crash 时，禁止只看 crash 时刻的内存数据。必须提取异常页面/小程序打开**之前**的内存水位时间线，对比打开前 vs 打开后跳变量，并检查打开前用户的活动路径。仅报告"crash 时内存 X MB"而不给出基线和跳变是不足够的结论。

## iOS OOM / 内存类问题分析要点

### ⚠️ 必须回溯 crash 前的内存基线

分析 OOM/crash 时，**禁止只看 crash 时刻的内存数据**。必须回溯到异常页面/小程序打开**之前**的内存水位，因为：
- 微信主进程长期运行后内存可能已占 5.5GB+（可用仅 500~600MB），此时再启动小程序（冷启动本身需 ~400MB）就直接濒临 OOM
- crash 的根因可能是"内存基线过高 + 新页面开销"的组合，而非新页面本身的泄漏

**操作步骤**：
1. 用 `check memory footprint` 提取完整内存时间线（至少覆盖 crash 前 10~30 分钟）
2. 定位异常页面/小程序的打开时间（`setScene` + `openApplet`/`EcsOpenWxaRouter` 等）
3. 对比打开前 vs 打开后 5s 的内存跳变量
4. 检查打开前用户的活动路径（`setScene` 序列），识别内存大户（朋友圈图片全屏、红包详情页、其他小程序等）

**关键 grep 词**（iOS）：
- 内存水位：`check memory footprint` → 提取 `footprint X MB, available: Y MB`
- OOM 上报：`OOMCrashReport` / `foom scene` / `app foreground out of memory`
- Scene 追踪：`setScene` / `set scene`
- 小程序启动：`EcsOpenWxaRouter` / `openApp` / `WAAppTaskMgr open`
- 内存清理：`WCMemoryCacheManager` / `callClearMemoryCache` / `footprintDiff`
- 内存告警：`memoryWarning` / `didReceiveMemoryWarning`

**常见内存跳变模式**：
| 跳变量 | 典型原因 |
|--------|---------|
| +400~500MB（5s内） | 小程序冷启动（Skyline引擎 + WebView + 代码包） |
| +100~200MB（持续） | 瀑布流无限加载图片/视频 |
| +50~100MB（单次） | 朋友圈图片全屏查看(WCImageFullScreenViewController) |

### 输出建议

OOM 分析结论必须包含：
1. **crash 时刻内存数据**（OOMCrashReport + footprint）
2. **异常页面打开前的内存基线**（具体数值 + 可用内存）
3. **内存跳变量**（打开前后差值 + 速率）
4. **crash 前用户活动路径**（哪些页面/操作累积了内存）
5. **修复建议分两层**：宿主侧（启动前水位检查/清理）+ 业务侧（资源回收/分页限制）

### 时序竞态分析技巧
分析客户端与基础库的时序竞态问题时，用以下方法重建事件时间线：
1. 搜 `AppBrandOnNavigateBackInterceptEvent` 找客户端 dispatch 时间
2. 搜 `Wxapplib.Critical` 找基础库 console 输出时间
3. 搜 `navigateBackInterceptionInfo is null` 找客户端发现拦截器被移除的时间
4. 搜 `BaseLibVersion` 或 `AbsReader version parsed` 确认真机运行的基础库版本
5. 计算客户端 dispatch → 基础库 stop 的间隔（ms 级）。如果间隔远小于 setTimeout delay，说明真机跑的不是新版代码

**关键结论**：如果基础库的 stop 在客户端 dispatch 后仅 3~5ms 就触发，不可能是 setTimeout 100ms 的结果——真机跑的仍是旧版代码。

## 分析笔记（防 compact 丢失）

分析过程中，每完成一个阶段性结论，**立即**追加写入工作目录的 `ANALYSIS.md`。格式：

```markdown
## [时间段/主题]
- 结论：{一句话}
- 关键证据：{行号 + 数值，不超过 5 行}
- 待确认：{如有}
```

规则：
- **禁止等分析完再写**：每个阶段性结论确认后立即写入。
- compact 恢复后第一步读 `ANALYSIS.md`，已有结论不重复验证。
- kickoff skill 共存时，分析笔记写入 kickoff 工作目录。

## 执行流程

### 步骤 1：确认输入

提取：**日志路径**（可选）、**问题描述**（必须）、**UIN/微信号**（可选）、**项目名**（可选）。

日志来源：
1. 本地路径 → 直接使用
2. welog 链接 → python3 urllib 下载解压
3. 无日志 → 使用 xlog MCP 工具拉取（`submit_fetch_xlog` / `submit_manual_fetch_xlog` 等，见下方「XLog MCP 工具」）

### 步骤 2：检测平台

```bash
python3 alog_grep.py detect-platform --log "$LOG_FILE"
# 输出: Android | iOS | OHOS | Unknown
```

### 步骤 3：搜场景库读 desc

用平台过滤，只搜匹配平台的场景：
```bash
# iOS → python3 "$ALOG_KEYWORD_SCRIPT" list --project-name "iOS小程序" --search "<搜索词>"
# OHOS → python3 "$ALOG_KEYWORD_SCRIPT" list --project-name "鸿蒙小程序" --search "<搜索词>"
# Android/Unknown → python3 "$ALOG_KEYWORD_SCRIPT" list --search "<搜索词>"
```

有匹配 → 读 desc 列表作为 grep 知识基础，记录是否有 scenePrompt。无匹配 → 跳过，自行推断。

### 步骤 4：grep 分析

综合场景库 desc 和自身理解 grep 日志。场景库信号优先，未覆盖时自行补充。
持续追踪：确认异常 → 提取数值 → 识别模式 → 定位根因。
**每确认一个阶段性结论，立即写入 `ANALYSIS.md`。**

### 步骤 5：scenePrompt 补充（按需）

结论不确定或用户要求时，取 scenePrompt 补充判断标准。否则跳过。

### 步骤 6：输出结论

根据问题类型选择合适的输出形式（时间线、事件列表、异常诊断等），关键数据附日志行号和具体数值。

## 示例

> 帮我看看这个日志，小程序启动好慢 /tmp/weapp.log

1. 检测平台：iOS
2. `list --project-name "iOS小程序" --search "启动"` → 找到场景，读 desc 得知关注 ColdLaunch、ResourcePrepare 等；记录有 scenePrompt
3. grep 信号 → ResourcePrepare 3200ms → **写入 ANALYSIS.md**
4. 不确定是否超标 → 取 scenePrompt，正常应 <800ms → 异常
5. 输出结论

> UIN 12345678 昨天小程序启动很慢

1. 无日志 → 使用 xlog MCP 工具（`submit_fetch_xlog`）拉取
2. 检测平台 → 搜场景库 → grep → 输出结论

> 这个日志有点问题 /tmp/app.log

1. 问题描述不明确 → 询问：\"请描述异常现象，如启动慢、白屏、崩溃等？\"

## XLog MCP 工具

xlog-fetcher-skill 已删除，日志拉取现在通过 **xlog MCP server** (`welog.mcp.it.woa.com`) 完成。

> ⚠️ **必须走 `mcporter` CLI 调用，不要用 agent 内置 `mcp__xlog__*` 工具！**
> 团队版下 agent 主进程的 xlog MCP 连接常连不上（`os.environ` 缺 `IMATE_TAI_TOKEN`，`_servers` 为空，没有 `mcp__xlog__*` 工具）。但 **`mcporter call xlog.<tool>` 经 terminal 走 per-command token 注入，用的是当前对话人身份，完全可用**（`result_url` 含 `by <对话人>` 可验证）。不要仅凭 agent 内置 MCP 不可用就判定「拉不了」——先 `mcporter list` 确认。机制详见 `imate-platform-internals` skill 的「✅ 正确调用 MCP 的方式」。

### mcporter 调用范式（实测可用）

```bash
# 0. 确认 xlog 健康 + 查工具 schema
mcporter list | grep xlog                 # 应显示 xlog (13 tools)
mcporter list-tools xlog                  # 查参数：begin_time/end_time (YYYY-MM-DD), uin_list(字符串数组)

# 1. 提交拉取（手工上报为例）
mcporter call xlog.submit_manual_fetch_xlog --args '{"uin_list":["942807682"],"begin_time":"2026-07-14","end_time":"2026-07-15"}' --output json
# → 返回 main_mongo_id + rtn_mongoid_list[].mongoid（sub_mongoid）

# 2. 轮询子任务状态
mcporter call xlog.get_xlog_subdata --args '{"sub_mongoid":"1784086676813942807682"}' --output json
# → State: TASK_FINISH 即就绪；含 Platform / FileInfoList

# 3. 拿下载链接（main_mongo_id 是 int，必须用冒号语法，--args 传字符串会报 unmarshal 错）
mcporter call xlog.query_xlog_subdata_by_main main_mongo_id:1784086676813 --output json
# → FileInfoList[].DownloadUrl（http://welog.woa.com/.../DownloadFileCheck?...）

# 4. 下载 + 解压（后台已解密为明文 .xlog.txt，直接可读）
curl -sSL -o file.zip "<DownloadUrl>" && unzip -o file.zip
```

**⚠️ mcporter 参数类型陷阱**：`--args '{...}'` 中整型参数（如 `main_mongo_id`）必须写数字不加引号（`"main_mongo_id": 1784087307506`），传字符串会报 `cannot unmarshal string into int64`。字符串参数（如 `uin_list` 的元素、`sub_mongoid`）仍加引号。

MCP 鉴权使用 `${IMATE_TAI_TOKEN}` 占位符。所有 xlog MCP 工具名（在 mcporter 下）为 `xlog.<tool>`。

### 拉取日志（submit + 循轮询 get_xlog_subdata）

| 场景 | MCP 工具 |
|---|---|
| wechat 下发拉取 | `submit_fetch_xlog` |
| wechat 手工上报 | `submit_manual_fetch_xlog` |
| ilink 下发拉取 | `submit_ilink_upload_xlog` |
| ilink 手工上报 | `submit_ilink_upload_self` |
| mp 下发拉取 | `submit_mp_upload_xlog` |
| mp 手工上报 | `submit_mp_upload_self` |

提交后拿到 `rtn_mongoid_list`，循环 `get_xlog_subdata` 轮询状态（`sub_mongoid` 必填，ilink/mp 需额外传 `main_mongo_id`）。完成后用 `query_xlog_subdata_by_main` 获取下载链接。

### 查询历史 & 解密

| 功能 | MCP 工具 |
|---|---|
| 按微信号/uin 查历史拉取记录 | `query_xlog_main_data` |
| 按主任务 ID 获取下载信息 | `query_xlog_subdata_by_main` |
| 上传 .xlog 文件触发解密 | `decode_xlog_file`（传 `content_b64`） |
| 查询解密状态 | `get_decode_status` |

### 手工上报关键词识别

| 用户表达 | 工具 |
|---|---|
| 「手工上报」/「已上报」/「已上传」 | `submit_manual_fetch_xlog` |
| 「ilink」/「ilink 日志」 | `submit_ilink_upload_xlog` |
| 「手工上报」+「ilink」 | `submit_ilink_upload_self` |
| 「mp」/「公众号」 | `submit_mp_upload_xlog` |
| 「手工上报」+「mp」 | `submit_mp_upload_self` |

### MCP vs 旧 Skill 的差异

- **身份隔离现状**：MCP 配置使用 `${IMATE_TAI_TOKEN}` 占位符，但团队版下 MCP 连接走 `os.environ` 解析，实际用的是**容器创建者**的 token（与旧 skill 共享 credentials.json 本质相同）。Terminal 命令层面的按用户隔离在 MCP 层面暂未实现。详见 `imate-platform-internals` skill 的「团队版 MCP 身份隔离陷阱」。
- **关键认知**：团队版下 `os.environ["IMATE_TAI_TOKEN"]` 存的是容器创建者的 token，不是当前对话人的。你无法在 `terminal()` 子进程中验证（安全过滤会移除该变量），必须用 `execute_code` 在 agent 主进程上下文中读取。如果用户提供了自己的 token 并希望用于 MCP，需硬编码替换 `${IMATE_TAI_TOKEN}`，但这会将 token 明文暴露给所有使用该容器的人。
- **新增能力**：`query_xlog_main_data`（按微信号/uin 查历史）、`submit_custom_cmd` + `test_push`（自定义命令/推送）
- **无需额外 appid/appkey**：MCP 鉴权走 TAI token，不再需要 xlog 专用凭证（但注意，团队版下所有人共用容器创建者的 TAI token）
