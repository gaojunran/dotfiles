
# 查询参数预审检查项详解

本文档是 SKILL.md 中「查询参数预审清单」各检查项的详细说明，包含规则表格、触发场景和优化示例。

---

## ☐ 1. 时间范围检查

| 检查点 | 规则 |
|--------|------|
| `start_date` 和 `end_date` 是否都已设置 | **必须设置**，缺少会导致全表扫描 |
| 时间跨度是否 ≤ 3 天 | 超过 3 天应拆分为多次查询 |
| 日期格式是否为 `yyyy-MM-dd` | 格式错误会导致查询失败 |

**优化示例：**
```
# ❌ 跨度过大
start_date="2024-01-01", end_date="2024-01-15"

# ✅ 缩小到 3 天
start_date="2024-01-01", end_date="2024-01-03"
```

---

## ☐ 2. Hour 字段优化

| 检查点 | 规则 |
|--------|------|
| 用户是否指定了具体时间段 | 如有，**必须**在 conditions 中增加 Hour 条件 |
| Hour 取值范围是否正确 | Hour 取值 0-23，为整数 |

**触发场景与优化示例：**
```
# 用户说："查上午的数据"
# ✅ 增加 Hour 条件
conditions="Hour >= 8 and Hour <= 12 and ..."

# 用户说："查晚上 8 点到 11 点的数据"
# ✅ 增加 Hour 条件
conditions="Hour >= 20 and Hour <= 23 and ..."

# 用户说："查凌晨的异常"
# ✅ 增加 Hour 条件
conditions="Hour >= 0 and Hour <= 5 and ..."
```

---

## ☐ 3. select_columns 优化

| 检查点 | 规则 |
|--------|------|
| 是否使用了 `*` | 应替换为具体需要的字段列表 |
| 聚合查询中非聚合字段是否都在 `group_by` 中 | 不一致会导致查询错误 |

**优化示例：**
```
# ❌ 使用通配符
select_columns="*"

# ✅ 指定具体字段
select_columns="Ds, Uin, error_code, error_msg"
```

---

## ☐ 4. conditions 值类型匹配

| 检查点 | 规则 |
|--------|------|
| String 类型字段值是否用单引号包围 | `uin = '12345678'` |
| 数值类型字段值是否**不带**引号 | `error_code > 0` |
| 不确定字段类型时 | 先用 `get_ilogs_clickhouse_columns_type` 确认 |

**优化示例：**
```
# ❌ String 类型的 uin 未加引号
conditions="uin = 12345678"

# ✅ 正确加引号
conditions="uin = '12345678'"
```

---

## ☐ 5. 聚合函数优化

| 检查点 | 规则 |
|--------|------|
| 是否使用了 `count(distinct ...)` | **必须替换为 `uniq()`**，性能远优 |

**优化示例：**
```
# ❌ 低效的去重计数
select_columns="Ds, count(distinct Uin) as uv"

# ✅ 使用 uniq() 替代
select_columns="Ds, uniq(Uin) as uv"
```

---

## ☐ 6. group_by 一致性

| 检查点 | 规则 |
|--------|------|
| `select_columns` 中的非聚合字段是否都出现在 `group_by` 中 | 必须一致，否则查询报错 |

**优化示例：**
```
# ❌ Ds 在 select 中但不在 group_by 中
select_columns="Ds, Hour, count(*)", group_by="Ds"

# ✅ 保持一致
select_columns="Ds, Hour, count(*)", group_by="Ds, Hour"
```

---

## ☐ 7. order_by 必要性

| 检查点 | 规则 |
|--------|------|
| 用户是否明确要求排序 | 未要求则**不要添加** order_by |
| 排序字段是否必要 | 排序会消耗额外资源 |

---

## ☐ 8. limit 合理性

| 检查点 | 规则 |
|--------|------|
| limit 值是否合理 | 默认 25，大部分场景足够 |
| 格式是否正确 | 必须是字符串类型，分页格式 `"pagesize, offset"` |

---

## ☐ 9. 条件顺序优化

| 检查点 | 规则 |
|--------|------|
| 高选择性条件（如 Uin、具体 ID）是否放在前面 | 高选择性条件前置有助于提前过滤数据 |
| Hour 条件是否紧跟时间相关条件 | Hour 作为辅助分区级过滤应靠前放置 |

**优化示例：**
```
# ❌ 低选择性条件在前
conditions="status > 0 and error_code != 0 and uin = '12345678'"

# ✅ 高选择性条件前置
conditions="uin = '12345678' and Hour >= 9 and Hour <= 18 and status > 0 and error_code != 0"
```
