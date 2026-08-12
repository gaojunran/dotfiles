
# iLogs MCP 工具 API 参考

## 目录

- [iLogs MCP 工具 API 参考](#ilogs-mcp-工具-api-参考)
  - [目录](#目录)
  - [工具概览](#工具概览)
  - [1. openapi — 日志数据查询](#1-openapi--日志数据查询)
    - [参数详解](#参数详解)
    - [返回数据格式](#返回数据格式)
    - [注意事项](#注意事项)
  - [2. get\_ilogs\_column\_info — 字段元数据查询](#2-get_ilogs_column_info--字段元数据查询)
    - [参数详解](#参数详解-1)
    - [返回数据格式](#返回数据格式-1)
  - [3. get\_ilogs\_clickhouse\_columns\_type — 字段类型查询](#3-get_ilogs_clickhouse_columns_type--字段类型查询)
    - [参数详解](#参数详解-2)
    - [返回数据格式](#返回数据格式-2)
    - [使用建议](#使用建议)
  - [4. logurl — URL 查询](#4-logurl--url-查询)
    - [参数详解](#参数详解-3)
    - [使用场景](#使用场景)
  - [ClickHouse 数据类型参考](#clickhouse-数据类型参考)
    - [数值类型](#数值类型)
    - [字符串与日期类型](#字符串与日期类型)
    - [复合类型](#复合类型)
  - [ClickHouse SQL 语法指南](#clickhouse-sql-语法指南)
    - [条件运算符](#条件运算符)
    - [聚合函数](#聚合函数)
  - [错误处理](#错误处理)
    - [错误码说明](#错误码说明)
    - [调用openapi tools时的返回码说明](#调用openapi-tools时的返回码说明)
    - [常见错误及解决方案](#常见错误及解决方案)
    - [调试流程](#调试流程)

---

## 工具概览

iLogs 技能通过 5 个 MCP 工具提供完整的日志查询能力：

| 工具名称                                       | 功能         | 调用频率 |
| ---------------------------------------------- | ------------ | -------- |
| `mcp__ilogs__openapi`                           | 日志数据查询  | 高       |
| `mcp__ilogs__get_ilogs_column_info`             | 字段元数据查询 | 中       |
| `mcp__ilogs__get_ilogs_clickhouse_columns_type` | 字段类型查询  | 中       |
| `mcp__ilogs__logurl`                            | URL 查询     | 低       |

---

## 1. openapi — 日志数据查询

**功能**：执行 ClickHouse SQL 查询，获取 iLogs 日志数据。

### 参数详解

| 参数             | 类型   | 必需 | 默认值 | 说明                                                                     |
| ---------------- | ------ | ---- | ------ | ------------------------------------------------------------------------ |
| `logid`          | string | 是   | —      | 日志应用标识（5位纯数字或字母+数字+下划线组合，如 `25996`、`ilogs_cgi_records`） |
| `select_columns` | string | 否   | `"*"`  | 查询字段，需符合 ClickHouse SQL 语法，多个字段用英文逗号拼接                |
| `conditions`     | string | 否   | `""`   | 查询条件，需符合 ClickHouse SQL 语法                                      |
| `start_date`     | string | 否   | `""`   | Ds 字段的开始日期，格式：`yyyy-MM-dd`                                     |
| `end_date`       | string | 否   | `""`   | Ds 字段的结束日期，格式：`yyyy-MM-dd`                                     |
| `group_by`       | string | 否   | `""`   | 分组字段，需符合 ClickHouse SQL 语法                                      |
| `order_by`       | string | 否   | `""`   | 排序字段，需符合 ClickHouse SQL 语法                                      |
| `limit`          | string | 否   | `"25"` | 结果数量限制，字符串类型；分页格式：`"pagesize, offset"`                    |

### 返回数据格式

```json
{
    "code": 0,
    "message": "success",
    "data": [
      {
        "Ds": "2026-03-23",
        "Hour": 1,
        "TimeStamp": "2026-03-23 01:19:27",
        "name": "9.218.226.50"
      },
      ...
      {
        "Ds": "2026-03-23",
        "Hour": 1,
        "TimeStamp": "2026-03-23 01:19:27",
        "name": "9.134.119.204"
      }
    ]
}
```

### 注意事项

- `limit` 参数是 **字符串类型**，不是数字
- `start_date` 和 `end_date` 是 Ds 字段（每个协议必有的日期字段）的时间范围
- `conditions` 中字符串值必须用 **单引号** 包围
- 聚合查询中非聚合字段必须出现在 `group_by` 中

---

## 2. get_ilogs_column_info — 字段元数据查询

**功能**：获取指定 logid 的字段元数据信息。

### 参数详解

| 参数      | 类型   | 必需 | 默认值 | 说明                                                     |
| --------- | ------ | ---- | ------ | -------------------------------------------------------- |
| `logid`   | string | 是   | —      | 日志应用标识                                              |
| `columns` | string | 否   | `""`   | 指定要查询的列名，多个用英文逗号分隔，如 `Hour,OsName,Uin` |

### 返回数据格式

返回一个 JSON, 其中data为 json list，data字段每个元素包含以下字段：
| 字段          | 说明         |
| ------------- | ------------ |
| `field_name`  | 字段名       |
| `field_type`  | 字段注册类型  |
| `field_index` | 字段序号      |
| `field_zh`    | 字段中文名    |
| `field_desc`  | 字段描述      |

```json
{
  "code": 200,
  "msg": "",
  "data": [
    {
        "field_name": "uin",
        "field_type": "string",
        "field_index": 1,
        "field_zh": "用户账号",
        "field_desc": "用户的唯一标识符"
    },
    {
        "field_name": "create_time",
        "field_type": "datetime",
        "field_index": 2,
        "field_zh": "创建时间",
        "field_desc": "记录创建的时间戳"
    }
  ]
}
```

---

## 3. get_ilogs_clickhouse_columns_type — 字段类型查询

**功能**：获取指定 logid 对应列的 ClickHouse 表字段类型及信息，包括字段类型、注释、是否在分区键/主键中、压缩后大小等。

### 参数详解

| 参数      | 类型   | 必需 | 默认值 | 说明                                                     |
| --------- | ------ | ---- | ------ | -------------------------------------------------------- |
| `logid`   | string | 是   | —      | 日志应用标识                                              |
| `columns` | string | 否   | `""`   | 指定要查询的列名，多个用英文逗号分隔，如 `Uin,Ds,Hour`     |

### 返回数据格式

返回一个 JSON, 其中data为 json list，每个元素包含以下字段：

| 字段                    | 类型   | 说明                                                                 |
| ----------------------- | ------ | -------------------------------------------------------------------- |
| `name`                  | string | 字段名                                                               |
| `type`                  | string | ClickHouse 中的字段类型（如 `String`, `UInt32`, `DateTime` 等）        |
| `comment`               | string | ClickHouse 表中的字段注释                                             |
| `is_in_partition_key`   | int    | 是否在分区键中（`1`=是，`0`=否）。**查询时必须附带分区键相关条件**       |
| `is_in_primary_key`     | int    | 是否在主键/索引中（`1`=是，`0`=否）。查询时附带索引条件可加速查询       |
| `data_compressed_bytes` | int    | 该字段在 ClickHouse 表中的压缩后字节数，可用于判断字段数据量大小        |


```json
{
  "code": 200,
  "msg": "",
  "data": [
    {
      "name": "Hour",
      "type": "UInt8",
      "comment": "",
      "is_in_partition_key": 0,
      "is_in_primary_key": 0,
      "data_compressed_bytes": "0"
    },
    {
      "name": "OsName",
      "type": "String",
      "comment": "OS名称",
      "is_in_partition_key": 0,
      "is_in_primary_key": 0,
      "data_compressed_bytes": "0"
    }
  ]
}
```

### 使用建议

- 对于 `log_id` 等关键字段，查询前务必确认类型
- 返回的类型用于指导 `conditions` 中值的格式（是否加引号等）
- `is_in_partition_key = 1` 的字段在查询时**必须**作为过滤条件，否则查询可能非常慢或超时
- `is_in_primary_key = 1` 的字段作为过滤条件可以**加速查询**
- `data_compressed_bytes` 可用于评估某个字段的数据量，辅助判断查询开销
- `columns` 为空时返回该 logid 对应 ClickHouse 表的全部字段信息

---

## 4. logurl — URL 查询

**功能**：通过 iLogs 链接直接查询数据。

### 参数详解

| 参数    | 类型    | 必需 | 默认值 | 说明                           |
| ------- | ------- | ---- | ------ | ------------------------------ |
| `url`   | string  | 是   | —      | 域名为 `ilogs.woa.com` 的 URL   |
| `limit` | integer | 否   | `25`   | 返回的记录数量                  |

### 使用场景

当用户直接提供 iLogs 的页面链接时，使用此工具可以免去解析 URL 参数手动构造查询的步骤。


---

## ClickHouse 数据类型参考

### 数值类型

| 类型       | 范围                    | 说明                |
| ---------- | ----------------------- | ------------------- |
| `UInt8`    | 0 ~ 255                | 无符号 8 位整数      |
| `UInt16`   | 0 ~ 65,535             | 无符号 16 位整数     |
| `UInt32`   | 0 ~ 4,294,967,295      | 无符号 32 位整数     |
| `UInt64`   | 0 ~ 2^64-1             | 无符号 64 位整数     |
| `Int8`     | -128 ~ 127             | 有符号 8 位整数      |
| `Int16`    | -32,768 ~ 32,767       | 有符号 16 位整数     |
| `Int32`    | -2^31 ~ 2^31-1         | 有符号 32 位整数     |
| `Int64`    | -2^63 ~ 2^63-1         | 有符号 64 位整数     |
| `Float32`  | IEEE 754 单精度         | 浮点数              |
| `Float64`  | IEEE 754 双精度         | 浮点数              |

### 字符串与日期类型

| 类型       | 格式                    | 条件示例                         |
| ---------- | ----------------------- | -------------------------------- |
| `String`   | 任意字符串               | `field = 'value'`                |
| `DateTime` | `YYYY-MM-DD HH:MM:SS`  | `field > '2024-01-01 12:00:00'`  |
| `Date`     | `YYYY-MM-DD`           | `field = '2024-01-01'`           |

### 复合类型

| 类型           | 说明       | 条件示例                    |
| -------------- | ---------- | --------------------------- |
| `Array(T)`     | 数组       | `has(field, 'value')`       |
| `Map(K, V)`    | 键值对     | `field['key'] = 'value'`    |
| `Nullable(T)`  | 可空类型   | `field IS NOT NULL`         |

---

## ClickHouse SQL 语法指南

### 条件运算符

| 运算符                | 说明       | 示例                                |
| --------------------- | ---------- | ----------------------------------- |
| `=`, `!=`             | 等于/不等于 | `status = 1`                        |
| `>`, `>=`, `<`, `<=`  | 比较运算    | `duration > 100`                    |
| `LIKE`                | 模糊匹配   | `name like '%test%'`                |
| `IN`                  | 集合包含   | `status IN (1, 2, 3)`              |
| `BETWEEN`             | 范围       | `age BETWEEN 18 AND 30`            |
| `IS NULL` / `IS NOT NULL` | 空值判断 | `email IS NOT NULL`              |
| `AND`, `OR`           | 逻辑运算   | `a = 1 AND (b = 2 OR c = 3)`       |

### 聚合函数

| 函数                    | 说明             | 示例                           |
| ----------------------- | ---------------- | ------------------------------ |
| `count()`               | 计数             | `count(*)`                     |
| `count(distinct ...)`   | 去重计数（不推荐，用 `uniq()` 代替） | `count(distinct uin)`  |
| `sum(...)`              | 求和             | `sum(duration)`                |
| `avg(...)`              | 平均值            | `avg(response_time)`           |
| `max(...)`              | 最大值            | `max(create_time)`             |
| `min(...)`              | 最小值            | `min(create_time)`             |
| `uniq(...)`             | 近似去重计数      | `uniq(uin)`                    |
| `quantile(0.95)(...)`   | 分位数            | `quantile(0.95)(response_time)`|

---

## 错误处理

### 错误码说明

| 错误码 | 含义 |
|---|---|
| `0` | 成功 |
| `-1` | 通用失败 |
| `200` | 查询数据接口成功 |
| `40001` | 参数异常
| `40002` | 无权查询 |
| `40003` | 请求openapi内部异常 |
| `40016` | 查询错误 |
| `40017` | 语法错误 |
| `40018` | 查询结果格式异常 |
| 其他 | 请参考具体返回的 `msg` 字段 |


---

### 调用openapi tools时的返回码说明
除上述公共错误码之外，由于openapi tools在执行时会二次调用后端的RESTful API进行数据查询，此API有自己的错误码。
成功触发查询时，将直接返回查询结果，错误码，msg等信息给用户

| 返回码 | 名称 | 说明 |
|--------|------|------|
| 200 | SUCCESS | 成功 |
| 400 | INVALID_PARAMS | 参数异常 |
| 401 | AUTH_ERROR | 鉴权失败或者是超频  |
| 402 | TIME_EXPIRED_ERROR | 请求超过指定时间窗口 |
| 403 | BLOCKED_OR_NO_PERMISSION | 由于查询量太大或集群负载较高导致多次查询超时被暂时拦截请求 / ac票据验证不符 / 请求无权限协议 |
| 404 | CGI_RUN_ERROR | 服务内部错误 |
| 405 | GENERATE_SQL_ERROR | 生成sql时异常 |
| 406 | NO_PERMIT_SQL_ERROR | sql不满足默认限制条件的异常，例如必须要附带分区键，禁止join等 |
| 407 | CLUSTER_NOT_SUPPORT_ERROR | 集群不支持接口查询，可能是集群不存在/新集群未配置/或集群信息缓存异常等 |
| 416 | QUERY_ERROR | 查询/执行异常 |
| 417 | SYNTAX_ERROR | 查询语法错误 |
| 418 | RESULT_ERROR | 查询结果格式异常 |


### 常见错误及解决方案

| 错误场景             | 可能原因                        | 解决方案                                    |
| -------------------- | ------------------------------- | ------------------------------------------- |
| logid 不存在          | 拼写错误或无权限                 | 确认 logid 拼写；检查访问权限                 |
| 字段不存在            | 字段名拼写错误或大小写不匹配     | 用 `get_ilogs_column_info` 确认字段名        |
| 类型不匹配            | 字符串字段未加引号或数值字段加了引号 | 用 `get_ilogs_clickhouse_columns_type` 确认类型 |
| SQL 语法错误          | 条件格式不正确                   | 检查括号匹配、引号使用、运算符语法            |
| 查询超时              | 时间范围过大或数据量太多，或此时集群负载较高，资源紧张          | 缩小时间范围至 3 天以内；添加过滤条件；等待一段时间，集群负载降低后再重试        |
| 结果为空              | 条件过于严格或数据不存在          | 放宽条件重试；确认时间范围内有数据             |

### 调试流程

1. **分步执行**：先查字段信息 → 确认类型 → 构建查询
2. **小范围测试**：使用短时间范围和小 limit 先验证查询逻辑
3. **简化条件**：从最简单的条件开始，逐步增加复杂度
4. **检查返回**：关注返回的 `code` 和 `message` 字段定位问题


