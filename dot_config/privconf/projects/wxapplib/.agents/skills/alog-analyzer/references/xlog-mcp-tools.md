# XLog MCP Server 工具参考

## 连接信息

- **URL**: `https://welog.mcp.it.woa.com/cgi-bin/eplogsmgr/mcp_server/`
- **协议**: JSON-RPC 2.0 over HTTP (MCP)
- **鉴权**: `Authorization: Bearer ${IMATE_TAI_TOKEN}`（运行时由 `_interpolate_env_vars()` 解析）
- **服务名**: `eplogsmgr-mcp-server` v1.0.0
- **MCP 工具调用方式**: 走 `mcporter call xlog.<tool>`（terminal 路径，per-command 注入对话人身份）。**不要用 agent 内置 `mcp__xlog__*` 工具**——团队版下常连不上。详见 SKILL.md 的「mcporter 调用范式」。

### 身份隔离现状（⚠️ 重要）

xlog MCP 有**两条独立连接路径**，隔离与可用性完全不同：

| 路径 | 触发方式 | 身份归属 | 可用性 |
|---|---|---|---|
| **agent 主进程内 MCP** | agent 直接调 `mcp__xlog__*` 工具 | `${IMATE_TAI_TOKEN}` 解析为 `os.environ` 中**容器创建者**的 token | ⚠️ 团队版下 `os.environ` 常缺 token → `_servers` 为空 → **根本连不上** |
| **`mcporter` CLI（走 terminal）** | `mcporter call xlog.<tool>` | terminal 子进程注入的**当前对话人** token | ✅ 真隔离，`mcporter list` 显示 xlog healthy(13 tools) |

> **⭐ 关键：当 agent 内直接调 `mcp__xlog__*` 不可用时（连不上/身份不对），改走 `mcporter call xlog.<tool>` 即可用当前对话人身份正常拉取。** 排查方法与完整说明见 `imate-platform-internals` skill 的 `references/service-identity-isolation-matrix.md`「MCP 有两条独立连接路径」章节。

### 通过 mcporter 调用 xlog（推荐，隔离可靠）

```bash
mcporter list                                    # 确认 xlog 为 healthy
mcporter call xlog.submit_manual_fetch_xlog uin_list='["942807682"]' begin_time="2026-07-10" end_time="2026-07-15"
mcporter call xlog.query_xlog_main_data name="微信号或uin"
mcporter call xlog.get_xlog_subdata sub_mongoid="..."
mcporter call xlog.query_xlog_subdata_by_main main_mongo_id="..."
```

## 工具清单（13 个）

### 拉取类（6 个）

| 工具名 | 描述 | 必填参数 |
|---|---|---|
| `submit_fetch_xlog` | wechat 下发拉取（等价 ilogs2 xlogapi/fetch_xlog） | `uin_list`, `begin_time`, `end_time` |
| `submit_manual_fetch_xlog` | wechat 手工上报（等价 ilogs2 xlogapi/manual_fetch_xlog） | `uin_list`, `begin_time`, `end_time` |
| `submit_ilink_upload_xlog` | ilink 下发拉取（等价 welog reqdata/IlinkUploadXlog） | `uin_list`, `begin_time`, `reason` |
| `submit_ilink_upload_self` | ilink 手工上报（等价 welog reqdata/IlinkUploadSelf） | `uin_list`, `choosetime`, `reason` |
| `submit_mp_upload_xlog` | mp 公众号下发拉取（等价 welog reqdata/MpUploadXlog） | `uin_list`, `begin_time`, `end_time` |
| `submit_mp_upload_self` | mp 公众号手工上报（等价 welog reqdata/MpUploadSelf） | `uin_list`, `choosetime`, `reason` |

### 查询类（3 个）

| 工具名 | 描述 | 必填参数 |
|---|---|---|
| `get_xlog_subdata` | 查询子任务状态（统一替代 ilogs2 get_mongo_subdata 和 welog GetMongoSubData） | `sub_mongoid` |
| `query_xlog_main_data` | 按微信号/uin 查历史拉取记录（新能力，旧 skill 无此功能） | `name` |
| `query_xlog_subdata_by_main` | 按主任务 ID 获取所有文件下载信息，含 welog 链接和 DownloadUrl | `main_mongo_id` |

### 解密类（2 个）

| 工具名 | 描述 | 必填参数 |
|---|---|---|
| `decode_xlog_file` | 上传 .xlog 文件触发异步解密（等价 openapi/DecodeXlogCheck），传 base64 编码内容 | `filename`, `content_b64` |
| `get_decode_status` | 查询解密状态（DECODE_RUNNING / DECODE_FAIL / DECODE_SUCCESS），成功时同步返回 zip 内容 | `server_filename` |

### 推送类（2 个）

| 工具名 | 描述 | 必填参数 |
|---|---|---|
| `submit_custom_cmd` | 下发自定义命令（推送热补丁等），支持 prconfig/ipxxversion/hprof/magicpkg 四种推送命令 | `params_json` |
| `test_push` | 对指定 uin 列表发起测试推送（不建单） | `params_json`, `uin_list` |

## 关键参数说明

- `uin_list`: uin 数组，每个元素为字符串；**也可填入微信号**
- `begin_time` / `end_time`: 日期格式 `YYYY-MM-DD`
- `loginname`: 操作人；**不传则用 RIO 票据里的 staffname**（MCP 自动从 token 提取）
- `xlogtype` (in get_xlog_subdata): `wechat` / `ilink` / `mp`，ilink/mp 必须传 `main_mongo_id`

## 工作流

1. `submit_*` → 拿到 `rtn_mongoid_list`
2. 循环 `get_xlog_subdata` 轮询状态（wechat 直接按 sub_mongoid 查；ilink/mp 需传 main_mongo_id）
3. 完成后 `query_xlog_subdata_by_main` 获取下载链接，下载日志到本地
4. 后续交给 `alog-analyzer` 分析

## vs 旧 xlog-fetcher-skill 的变化

| 维度 | Skill（已删除） | MCP |
|---|---|---|
| 鉴权 | 写死 credentials.json（appid/appkey/username） | `${IMATE_TAI_TOKEN}` 动态解析 |
| 身份隔离 | 无——所有人共用同一身份 | 团队版下**仍然共用**容器创建者身份（MCP 层面未实现按用户隔离），详见上方说明 |
| 查询历史 | 不支持 | `query_xlog_main_data` |
| 推送命令 | 不支持 | `submit_custom_cmd` / `test_push` |
| HTTPS 降级 | 需手动 patch（welog.woa.com SSL 版本问题） | MCP URL 是 `welog.mcp.it.woa.com`，无 SSL 问题 |
| 无需 appid/appkey | 需要 xlog 专用凭证 | 不需要，鉴权走 TAI token（但团队版下所有人共用容器创建者的 TAI token） |
