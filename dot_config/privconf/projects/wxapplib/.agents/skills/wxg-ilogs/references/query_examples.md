
# iLogs 查询示例与实战模板

## 目录

- [基础查询示例](#基础查询示例)
- [聚合统计示例](#聚合统计示例)
- [Hour 字段优化示例](#hour-字段优化示例)
- [类型敏感查询示例](#类型敏感查询示例)
- [实战查询模板](#实战查询模板)

---

## 基础查询示例

### 查询单个用户的详细信息

```
openapi(
    logid="12345",
    start_date="2024-01-01",
    end_date="2024-01-03",
    conditions="uin = '12345678'",
    select_columns="uin, nickname, reg_time, last_login_time"
)
```

### 条件查询（复合条件）

```
openapi(
    logid="12345",
    start_date="2024-01-01",
    end_date="2024-01-03",
    conditions="(uin = '12345678' and status > 0) or action_type like '%login%'"
)
```

### 获取错误日志并按时间倒序排列

```
openapi(
    logid="12345",
    start_date="2024-01-01",
    end_date="2024-01-03",
    conditions="error_code > 0",
    select_columns="error_code, error_msg, uin, create_time",
    order_by="create_time desc",
    limit="50"
)
```

### 分页查询（第 1 页，每页 10 条）

```
openapi(
    logid="12345",
    start_date="2024-01-01",
    end_date="2024-01-03",
    limit="10, 0"
)
```

---

## 聚合统计示例

### 统计每日活跃用户数

```
openapi(
    logid="12345",
    start_date="2024-01-01",
    end_date="2024-01-03",
    select_columns="Ds, uniq(Uin) as daily_active_users",
    conditions="action_type = 'login'",
    group_by="Ds"
)
```

### 聚合统计（日均计数 + 平均值）

```
openapi(
    logid="12345",
    start_date="2024-01-01",
    end_date="2024-01-03",
    select_columns="Ds, count(*) as daily_count, avg(duration) as avg_duration",
    group_by="Ds"
)
```

### 用户行为分析

```
openapi(
    logid="YOUR_LOGID",
    start_date="2024-01-01",
    end_date="2024-01-03",
    select_columns="action_type, count(*) as action_count, uniq(uin) as user_count",
    group_by="action_type",
    order_by="action_count desc",
    limit="20"
)
```

### 错误日志排查（按错误码分组）

```
openapi(
    logid="YOUR_LOGID",
    start_date="2024-01-01",
    end_date="2024-01-03",
    conditions="error_code > 0",
    select_columns="error_code, error_msg, count(*) as error_count",
    group_by="error_code, error_msg",
    order_by="error_count desc",
    limit="20"
)
```

### 时间趋势分析

```
openapi(
    logid="YOUR_LOGID",
    start_date="2024-01-01",
    end_date="2024-01-03",
    select_columns="Ds, count(*) as daily_total",
    group_by="Ds",
    order_by="Ds"
)
```

---

## Hour 字段优化示例

### 查询每天上午 9 点到 12 点的登录数据

```
openapi(
    logid="12345",
    start_date="2024-01-01",
    end_date="2024-01-03",
    conditions="Hour >= 9 and Hour <= 12 and action_type = 'login'",
    select_columns="Ds, Hour, Uin, action_type"
)
```

### 查询凌晨异常数据（0-5 点）

```
openapi(
    logid="12345",
    start_date="2024-01-01",
    end_date="2024-01-03",
    conditions="Hour >= 0 and Hour <= 5 and error_code > 0",
    select_columns="Ds, Hour, error_code, error_msg, Uin"
)
```

---

## 类型敏感查询示例

### 根据 log_id 字段查询（需先确认类型）

```
# 第一步：查询 log_id 字段类型
get_ilogs_clickhouse_columns_type(logid="12345")

# 第二步：根据返回类型构造条件
# 如果是 String 类型：
openapi(logid="12345", start_date="2024-01-01", end_date="2024-01-03",
        conditions="log_id = 'abc123'")

# 如果是 UInt64 等数值类型：
openapi(logid="12345", start_date="2024-01-01", end_date="2024-01-03",
        conditions="log_id = 123456")
```

### 单用户追踪

```
# 先确认 uin 字段类型
get_ilogs_clickhouse_columns_type(logid="YOUR_LOGID")

# 然后查询（假设 uin 为 String 类型）
openapi(
    logid="YOUR_LOGID",
    start_date="2024-01-01",
    end_date="2024-01-03",
    conditions="uin = '12345678'",
    order_by="TimeStamp desc",
    limit="50"
)
```

---

## 实战查询模板

### 模板 1：探索新的 logid

```
# 步骤 1：了解表结构
get_ilogs_column_info(logid="YOUR_LOGID")

# 步骤 2：确认关键字段类型
get_ilogs_clickhouse_columns_type(logid="YOUR_LOGID")

# 步骤 3：小范围试查
openapi(
    logid="YOUR_LOGID",
    start_date="2024-01-01",
    end_date="2024-01-03",
    limit="5"
)
```

### 模板 2：完整的用户行为分析流程

```
# 步骤 1：了解表结构，找到行为类型字段
get_ilogs_column_info(logid="YOUR_LOGID")

# 步骤 2：确认关键字段类型
get_ilogs_clickhouse_columns_type(logid="YOUR_LOGID")

# 步骤 3：按行为类型统计
openapi(
    logid="YOUR_LOGID",
    start_date="2024-01-01",
    end_date="2024-01-03",
    select_columns="action_type, count(*) as action_count, uniq(uin) as user_count",
    group_by="action_type",
    order_by="action_count desc",
    limit="20"
)
```

### 模板 3：错误排查完整流程

```
# 步骤 1：了解错误相关字段
get_ilogs_column_info(logid="YOUR_LOGID")

# 步骤 2：统计错误分布
openapi(
    logid="YOUR_LOGID",
    start_date="2024-01-01",
    end_date="2024-01-03",
    conditions="error_code > 0",
    select_columns="error_code, error_msg, count(*) as error_count",
    group_by="error_code, error_msg",
    order_by="error_count desc",
    limit="20"
)

# 步骤 3：查看特定错误的详细记录
openapi(
    logid="YOUR_LOGID",
    start_date="2024-01-01",
    end_date="2024-01-03",
    conditions="error_code = 100",
    select_columns="Ds, Hour, Uin, error_code, error_msg",
    limit="25"
)
```
