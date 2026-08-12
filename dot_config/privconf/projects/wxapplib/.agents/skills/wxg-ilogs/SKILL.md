---
name: ilogs
description: 查询和分析 iLogs 协议数据。当用户提到「协议」「logid」「log_id」并涉及查询、统计、分析意图时触发。用户说的「xxxxx协议」「协议xxxxx」中xxxxx即 logid。支持：字段/表结构查询、条件过滤、聚合统计、iLogs URL 解析。
metadata:
   {
    "openclaw":
      {
        "requires": { "env": ["TENCENT_WXG_ILOGS_TOKEN"] },
        "primaryEnv": "TENCENT_WXG_ILOGS_TOKEN",
        "category": "tencent",
        "tencentTokenMode": "custom",
        "tokenUrl": "https://mmac.woa.com/wego/weacllmagentweb/mcp?svr_name=ilogs&option_type=my_token",
        "emoji": "📝",
      },
  }
---

# iLogs 日志查询与分析

此技能帮助你使用 iLogs MCP 工具高效地查询和分析腾讯内部 iLogs 系统中的日志数据。根据你的需求选择合适的查询方式，遵循最佳实践获得最优结果。

## 核心概念

### 什么是 iLogs？

iLogs 是腾讯内部的日志收集与查询平台，底层基于 ClickHouse 存储引擎。数据来源主要有两种渠道：**mmdata**（微信数据上报通道）和 **HTTP 上报**（自定义协议上报）。

每个日志应用通过 **logid** 唯一标识。在用户日常用语中，**"协议"就是 logid**，例如用户说"查询 12345 协议的数据"，即 logid 为 `12345`。logid 的格式和来源对应关系如下：

| logid 格式                    | 示例                    | 数据来源          | 说明                              |
| ----------------------------- | ----------------------- | ----------------- | --------------------------------- |
| 5 位纯数字                     | `12345`                 | mmdata            | 标准 mmdata 上报协议               |
| `iLink`或`mpapp` + `_` + 5 位数字          | `iLink_12345` , `mpapp_10034`            | mmdata-app 类型    |  mmdata 应用协议          |
| 字母+数字+下划线组合（无固定规律）| `app_1_log2`     | HTTP 自定义上报    | 通过 HTTP 接口自定义的协议上报      |

> **注意：**
很多用户会在使用时，给出的logid增加了自己口语常用的前缀。例如用户说，帮我查询 ilogs12345 协议的数据 或者 帮我查询log_12345 协议的数据。 有较大概率用户指的是 logid = 12345。 如果你不能完全确定logid具体是什么，最好向用户进行二次确认。

### 表结构与通用字段

每个 logid 背后对应一张 ClickHouse 表。除非特殊情况，所有表都包含以下通用字段：

| 字段              | 类型       | 说明                                                         |
| ----------------- | ---------- | ------------------------------------------------------------ |
| `Ds`              | Date       | 日志日期分区字段，与 `TimeStamp` 对应，格式 `yyyy-MM-dd`。查询时通过 `start_date` 和 `end_date` 参数自动过滤此字段 |
| `Hour`            | UInt8      | 小时字段（0-23），与 `TimeStamp` 对应，可用于按小时粒度的分析和过滤 |
| `TimeStamp`       | DateTime   | 日志时间字段，精确到秒                                        |

> **注意：** `Ds` 是 ClickHouse 表的分区键，所有查询都应通过时间范围限定 `Ds` 的范围（即指定 `start_date` 和 `end_date`），这是保证查询性能的关键。


以下字段是常用字段，在绝大多数的mmdata类型协议中均包含， http上报类型协议中可能包含：
| 字段              | 类型       | 说明                                                         |
| ----------------- | ---------- | ------------------------------------------------------------ |
| `Uin`             | String/UInt64 | 日志用户 ID，标识产生该条日志的用户                           |
| `ClientVersion`   | String/UInt32     | 微信客户端版本号                                              |


## 配置步骤

1. 访问 https://mmac.woa.com/wego/weacllmagentweb/mcp?svr_name=ilogs&option_type=my_token 获取 Token，并配置环境变量：

```bash
export TENCENT_WXG_ILOGS_TOKEN="你的令牌"
```

2. 运行 setup.ts 完成服务注册

```bash
npx tsx ./scripts/setup.ts
```

> setup.ts 会自动将 ilogs MCP 服务注册到 mcporter，并验证配置是否成功。

3. 验证安装是否成功：

```bash
mcporter list | grep ilogs
```

> ⚠️ **如果用户未配置 Token**，请引导用户访问上方链接获取 Token，否则所有工具调用将返回鉴权失败。
> ⚠️ **如果报错 403 acl.14001**⁠，说明需要给 openclaw 开通 IDC 环境访问，需要引导用户参考 https://iwiki.woa.com/p/4018873534 开通访问权限。

### MCP 工具概览

此技能依赖以下三个 iLogs MCP 工具：

| MCP 工具                                      | 功能          | 使用场景                           |
| --------------------------------------------- | ------------- | ---------------------------------- |
| `mcp__ilogs__get_ilogs_column_info`            | 字段元数据查询 | 了解表结构、获取字段中文名和描述     |
| `mcp__ilogs__get_ilogs_clickhouse_columns_type`| 字段类型查询   | 获取 ClickHouse 数据类型，指导条件构造 |
| `mcp__ilogs__openapi`                          | 日志数据查询   | 执行实际的数据查询、统计和分析, 底层是将各参数拼接成一个SQL，不支持如嵌套查询，join等复杂查询       |

> **注意：** 此外还有 `mcp__ilogs__logurl` 工具，用于直接通过 iLogs 链接（域名为 `ilogs.woa.com`）查询数据，适用于用户直接提供 iLogs URL 的场景。

---

## 应该使用哪个工具？

> **从简单开始。** 先了解数据结构，再构建查询。如果不确定字段名称或类型，先查元数据。

| 使用场景                                    | 推荐工具                          | 原因                                    |
| ------------------------------------------- | --------------------------------- | --------------------------------------- |
| 了解某个 logid 有哪些字段                    | `get_ilogs_column_info`           | 返回字段名、中文名、描述等完整元数据      |
| 确认字段的 ClickHouse 数据类型               | `get_ilogs_clickhouse_columns_type`| 用于正确构造查询条件（字符串 vs 数值等）  |
| 查询实际的日志数据                           | `openapi`                         | 支持条件过滤、聚合统计、排序分页等        |
| 用户提供了 iLogs URL                         | `logurl`                          | 直接解析 URL 并返回数据                  |

### 决策树

```
你需要做什么？

1. 不了解 logid 有哪些字段？
   └── get_ilogs_column_info — 获取字段元数据

2. 不确定字段是字符串还是数值类型？
   └── get_ilogs_clickhouse_columns_type — 获取精确数据类型

3. 需要查询实际数据（记录、统计、聚合）？
   └── openapi — 执行 ClickHouse SQL 查询
       ├── 简单查询 → 指定 logid + 时间范围
       ├── 条件查询 → 添加 conditions 参数
       ├── 聚合统计 → 使用 select_columns + group_by
       └── 分页查询 → 使用 limit 参数（格式："pagesize, offset"）

4. 用户给了一个 iLogs URL？
   └── logurl — 直接通过 URL 查询
```

### 推荐的查询流程

对于不熟悉的 logid，建议按以下步骤执行：

1. **第一步**：使用 `get_ilogs_column_info` 获取字段列表和描述
2. **第二步**：使用 `get_ilogs_clickhouse_columns_type` 确认关键字段的数据类型
3. **第三步**：构建 `openapi` 查询参数
4. **第四步（预审）**：按照「查询参数预审清单」逐项检查并优化参数，确保查询效率最优
5. **第五步**：执行优化后的 `openapi` 查询

对于已知结构的 logid，可以直接从第三步开始，但**第四步预审不可跳过**。

---

## MCP 工具参数速查

### 1. 字段元数据查询 — `get_ilogs_column_info`

获取指定 logid 的字段信息，返回字段名、注册类型、序号、中文名和描述。

| 参数     | 类型   | 必需 | 默认值 | 说明                                       |
| -------- | ------ | ---- | ------ | ------------------------------------------ |
| `logid`  | string | 是   | —      | 日志应用标识                                |

### 2. 字段类型查询 — `get_ilogs_clickhouse_columns_type`

获取指定 logid 对应列的 ClickHouse 数据类型，用于正确构造查询条件。

| 参数     | 类型   | 必需 | 默认值 | 说明                                       |
| -------- | ------ | ---- | ------ | ------------------------------------------ |
| `logid`  | string | 是   | —      | 日志应用标识                                |

> **关键点：** `log_id` 字段在不同表中类型可能不同（`String` vs `UInt64`），查询前务必确认类型。

### 3. 日志数据查询 — `openapi`

执行灵活的 ClickHouse SQL 查询，支持条件过滤、聚合统计、排序和分页。

| 参数             | 类型   | 必需 | 默认值 | 说明                                                    |
| ---------------- | ------ | ---- | ------ | ------------------------------------------------------- |
| `logid`          | string | 是   | —      | 日志应用标识                                             |
| `select_columns` | string | 否   | `"*"`  | 查询字段，符合 ClickHouse SQL 语法，用英文逗号拼接        |
| `conditions`     | string | 否   | `""`   | 查询条件，符合 ClickHouse SQL 语法                       |
| `start_date`     | string | 否   | `""`   | Ds 字段的开始日期，格式：`yyyy-MM-dd`                     |
| `end_date`       | string | 否   | `""`   | Ds 字段的结束日期，格式：`yyyy-MM-dd`                     |
| `group_by`       | string | 否   | `""`   | 分组字段，符合 ClickHouse SQL 语法                       |
| `order_by`       | string | 否   | `""`   | 排序字段，符合 ClickHouse SQL 语法                       |
| `limit`          | string | 否   | `"5"`  | 结果数量限制；分页格式：`"pagesize, offset"`              |

### 4. URL 查询 — `logurl`

通过 iLogs 链接直接查询数据，适用于用户提供 `ilogs.woa.com` 域名 URL 的场景。

| 参数    | 类型    | 必需 | 默认值 | 说明                           |
| ------- | ------- | ---- | ------ | ------------------------------ |
| `url`   | string  | 是   | —      | 域名为 `ilogs.woa.com` 的 URL   |
| `limit` | integer | 否   | `25`   | 返回的记录数量                  |

---

## 查询行为约定

除非用户另有要求：

- **时间范围**：所有数据查询必须包含 `start_date` 和 `end_date`，默认查询最近 1 天
- **结果数量**：用户未指定时，`openapi` 的 `limit` 参数传入 `"25"`（注意：工具本身默认值为 `"5"`，需主动设置）
- **字段选择**：优先指定具体字段，避免使用 `*` 查询全部字段
- **排序规则**：仅在用户明确要求时才使用 `order_by`，避免不必要的排序开销
- **查询语法**：所有条件、聚合、排序需符合 ClickHouse SQL 语法

---

## 查询参数预审清单

> **重要：** 每次执行 `openapi` 查询前，必须对构建好的参数进行预审优化。按以下清单逐项检查，将参数调整为最优状态后再执行。

| #  | 检查项               | 要求                                                         | 快速判断                                               |
| -- | -------------------- | ------------------------------------------------------------ | ------------------------------------------------------ |
| 1  | 时间范围             | `start_date` 到 `end_date` 跨度不超过 7 天                    | 跨度是否合理？过大会导致扫描过多分区                       |
| 2  | Hour 过滤            | 用户指定了具体时间段时，在 `conditions` 中加上 `Hour` 过滤      | 用户是否提到了时间段？加上 `Hour >= X AND Hour <= Y`      |
| 3  | 字段选择             | `select_columns` 指定具体字段，避免使用 `*`                    | 是否用了 `*`？改为只查需要的字段                          |
| 4  | 值类型匹配           | `conditions` 中字符串加单引号，数值不加引号                     | `String` 类型 → `'value'`，数值类型 → `123`              |
| 5  | 去重计数             | 使用 `uniq()` 替代 `count(distinct ...)`                      | 是否用了 `count(distinct ...)`？改为 `uniq()`            |
| 6  | 聚合字段一致性       | `select_columns` 中的非聚合字段必须出现在 `group_by` 中        | `select` 中的非聚合字段是否都在 `group_by` 中？           |
| 7  | 排序必要性           | 仅在用户明确要求排序时才添加 `order_by`                        | 用户明确要求排序了吗？否则不加 `order_by`                  |
| 8  | limit 合理性         | 确认数量合适，分页格式为 `"pagesize, offset"`（offset 从 0 开始）| 默认 `"25"`，是否需要分页？                               |
| 9  | 条件前置优化         | 将过滤性强的条件放在 `conditions` 前面                         | 高选择性条件是否前置？提升查询效率                         |
| 10 | logid 拼写           | logid 区分大小写，拼写错误会导致查询失败                        | 不确定时先向用户确认                                      |

各检查项的详细规则和优化示例，参见 `references/precheck_details.md`。


---

## 阅读指南

需要更详细的参考时，阅读以下文件：

1. **`references/api_reference.md`** — 完整的 MCP 工具 API 参考文档，包括详细参数说明、返回格式、ClickHouse 数据类型表和 SQL 语法指南
2. **`references/query_examples.md`** — 丰富的查询示例与实战模板，涵盖基础查询、聚合统计、Hour 优化、类型敏感查询等场景
3. **`references/precheck_details.md`** — 查询参数预审清单各检查项的详细规则说明和优化示例
