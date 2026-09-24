# miniprogram-automator-skill

面向使用者的上手指引：把 `miniprogram-automator-mcp` 配到你的 agent 里，让它用上本 skill。

本 skill 只负责**心智模型与 SOP 编排**，真正的能力全部来自 `miniprogram-automator-mcp`
（34 个工具）。配好 MCP 后，agent 会自动加载 [SKILL.md](SKILL.md) 作为使用指南。

## 目录结构

```
miniprogram_automator_skill/
├── README.md    # 本文件：配置与上手
└── SKILL.md     # 面向 agent 的使用指南（34 个工具的能力与回路）
```

## 前置：获取太湖个人令牌

MCP 走太湖（Tai）鉴权，需要一个个人令牌（PAT）。

1. 参考太湖文档 **<https://iwiki.woa.com/p/4016834150>** 创建个人令牌，
   申请地址：<https://tai.it.woa.com/user/pat>
2. 创建时「**授权应用**」至少要勾选 **`miniprogram-automator-mcp`**。
   如果你还要在同一个 agent 里用 iWiki、工蜂等其他 MCP，把它们一并勾上即可。

拿到形如 `tai_pat_xxx` 的令牌后，进入下一步。

## 环境要求

| 要求 | 说明 |
|---|---|
| 微信测试号 | 必须使用 **319 开头 uin** 的微信测试号，其他微信号不支持；推送与拉起必须用同一个测试号 |
| 微信客户端 | 必须使用**开了 dailybuild 宏**的安装包。线上普通微信**不能自动拉起**小程序，但可以**手动拉起**小程序后直接进入 `init_session` 阶段 |

## 配置 MCP

在你的 agent / IDE 的 MCP 配置中加上这一段：

```json
{
  "mcpServers": {
    "miniprogram-automator-mcp": {
      "type": "http",
      "url": "https://miniprogram-automator-mcp.mcp.woa.com",
      "headers": {
        "Authorization": "Bearer tai_pat_xxx"
      }
    }
  }
}
```

把 `tai_pat_xxx` 替换成上一步生成的个人令牌（注意保留 `Bearer ` 前缀和一个空格）。

## 安装 skill

把本目录放到 agent 的 skills 目录下，例如：

- 个人级：`~/.claude/skills/miniprogram_automator_skill/`
- 项目级：`<你的项目>/.claude/skills/miniprogram_automator_skill/`

或者随插件一起分发（部分客户端支持把 MCP + skill 打包安装）。
放置后**重启 agent**，用 `/skills` 之类的命令确认 skill 已加载。

> skill 的发现依赖 [SKILL.md](SKILL.md) 头部的 `name` / `description`，
> 请勿删改这两个字段。

## 验证连通

配好后按顺序确认：

1. **工具列表**：agent 的工具列表里应能看到 **34 个** `miniprogram-automator-mcp` 工具。
   看得到就说明 MCP 连接与鉴权都通过了。
2. **会话诊断**：调用 `get_session_status()`，看 `initialized` / `has_app` / 当前页面。
3. **冒烟验收**：调用 `run_acceptance()`，跑四点冒烟。

## 用法

配置完成后，直接用自然语言下达任务即可，例如：

> 帮我在测试号 X 上跑一遍登录流程，登录后检查有没有 console 报错。

agent 会自动加载本 skill 并按标准回路执行（①②为必要前置，原因见 SKILL.md「会话生命周期」）：

```python
# ① 推送基础库（必要——MCP 修改基础库开启调试服务）：send_wxlib / build_zip→upload→push
# ② 拉起小程序（必要——拉起后基础库才连接调试服务器）：launch
init_session(shell_name="<测试号>", app_id="<appid>")   # ③ 建连
take_snapshot()                 # ④ 拿元素 [ref=N]
click(element_id="42")          # ⑤ 用 ref 操作
wait_for(text=["成功", "失败"])  # ⑥ 等结果
list_console_messages(types=["error"])
```

完整的能力说明、部署链路与常见坑见 [SKILL.md](SKILL.md)。

## 常见问题

| 现象 | 原因与处理 |
|---|---|
| 401 / 403 | 令牌未配、填错或已过期。回 <https://tai.it.woa.com/user/pat> 重新生成，注意 `Bearer ` 前缀 |
| 工具列表为空 / 一直 loading | MCP 没连上。检查 `url` 与 `headers`，确认站点有访问权限 |
| 看不到工具但也没报错 | 授权应用漏勾了 `miniprogram-automator-mcp`，或改了配置后没重启 agent |
| launch 拉不起小程序 | ① 测试号是否 **319 开头 uin**（其他微信号不支持）；② 微信客户端是否**开了 dailybuild 宏**的包——线上普通微信不能自动拉起，只能手动拉起小程序后直接 `init_session` |
| 「等待 AppService 超时」 | 基础库没推送或小程序没拉起（两者都是必要前置）。先 `send_wxlib` / `push` 推送，再 `launch` 拉起，最后 `init_session` |
| `element_id` 报失效 | 页面重渲染了。重新 `take_snapshot` / `get_element` |
| 上传 zip 报路径不存在 | `*_path` 是**服务端**路径。本机 zip 需先走 `upload-src-zip` 换路径，见 SKILL.md「部署与拉起链路」 |

## 与 miniprogram-automator-mcp 的关系

| | 职责 |
|---|---|
| **本 skill** | 心智模型 + SOP 编排：什么时候快照、怎么定位、先等还是先点、坑在哪 |
| **miniprogram-automator-mcp** | 实际的 34 个工具：部署拉起、会话、页面、元素、求值、console/网络、CDP |

skill 本身不含任何执行能力——没配好 MCP，skill 无从下手。

## 相关

- [SKILL.md](SKILL.md) —— 面向 agent 的完整使用指南
- 太湖令牌文档：<https://iwiki.woa.com/p/4016834150>
- MCP 服务端实现与工具 docstring：`../miniprogram_automator_mcp/`
