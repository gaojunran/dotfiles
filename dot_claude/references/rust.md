## Rust

### Coding Style

我更喜欢地道的 Rust 代码，偏好简洁，可以适当炫技：

#### 错误与可空处理

- 优先使用 `?` 操作符传播错误，而不是 `match` / `unwrap` / `expect`。仅在确实不可能失败的场景使用 `unwrap` / `expect`，并辅以清晰的 `expect` 信息说明不变式。
- 使用 `Option` / `Result` 的组合子：`map`、`and_then`、`ok_or`、`ok_or_else`、`unwrap_or`、`unwrap_or_else`、`unwrap_or_default`，避免冗长的 `match`。
- `map_or` 优于 `map(...).unwrap_or(...)`。
- 避免把 Option 和 Result 来回 map → transpose → ok → flatten 多层折返；例如 `and_then(|t| getopt(t).ok())`，就更简洁。
- 错误处理：库代码用 `thiserror` 定义具体错误类型；应用代码用 `anyhow` 简化。避免直接 `Box<dyn Error>`。
- `#[derive(Debug, thiserror::Error)]` + `#[from]` 自动生成错误转换，省掉手写 `impl From`。

#### 模式匹配与控制流

- 使用 `if let` / `let ... else` / `while let` 处理单一分支的模式匹配。`if / while let` chain 比嵌套更好。
- 用 let-else 替代 early-return 型 match。推荐这种写法：`let Some(v) = x else { return; };`。
- 熟练使用解构：函数参数、`let` 绑定、`match` 臂中的结构体与元组解构。
- 用枚举 + 穷尽 `match` 表达有限状态，让编译器帮忙检查遗漏分支。避免 `_ =>` 兜底，除非确实合理。
- 善用 `matches!` 宏替代 `if let Some(_) = ...` 或 `match` 只为判真假的场景。
- 切片模式匹配：`match slice { [] => ..., [x] => ..., [first, .., last] => ..., [head, tail @ ..] => ... }`。
- 范围模式、守卫 `if`、`|` 合并分支、`@` 绑定都可以大胆用，让 `match` 读起来像规格说明。
- 表达式优于语句：`if` / `match` / `loop` / 块表达式都可以返回值，直接 `let x = if cond { a } else { b };`，避免先声明后赋值。
- 函数末尾省略 `return` 和分号，让最后一个表达式作为返回值。


#### 迭代器与集合

- 迭代器链式调用优于手写 `for` 循环：`iter().map().filter().collect()`、`fold`、`any`、`all`、`find`、`sum`、`product` 等。需要索引时用 `enumerate`，并行遍历用 `zip`。
- `Iterator` 组合拳：`try_fold` / `try_for_each` 替代手写短路循环；`scan` 做带状态的映射；`chunks` / `windows` / `partition` 用得起来。
- `collect` 善用目标类型推导：`collect::<Result<Vec<_>, _>>()` 把 `Iterator<Item = Result<T, E>>` 一次性短路为 `Result<Vec<T>, E>`；同理 `Option<Vec<_>>`。
- 需要就引入 `itertools`：`group_by`、`tuple_windows`、`sorted_by_key`、`unique`、`dedup`、`join`、`cartesian_product` 等，简洁且语义明确。
- 集合：需要键值对时优先 `HashMap`；有序场景用 `BTreeMap`。用 `entry` API 实现 get-or-insert：`map.entry(k).or_insert_with(...)`、`or_default()`。

#### 所有权、借用与字符串

- 所有权与借用：优先借用 (`&T` / `&mut T`)，避免不必要的 `clone`。需要所有权转移时考虑 `mem::take` / `mem::replace` / `std::mem::swap`。
- 字符串：函数参数接收 `&str` 而非 `&String`，切片接收 `&[T]` 而非 `&Vec<T>`。返回时按需用 `String` / `Cow<str>`。
- 格式化使用捕获式 `format!("{name}")`，避免冗余的 `format!("{}", name)`。
- 生命周期标注尽量省略，仅在编译器无法推导时显式标注；能用 `'_` 就不要起名字。

#### 类型系统与 API 设计

- 用 `From` / `Into` / `TryFrom` 表达类型转换；实现 `From` 即可自动获得 `Into`。
- 在以下情况下（主键/ID、带单位的参数、带约束或独立逻辑的参数），用 newtype 包装原始类型以表达语义（如 `struct UserId(u64)`），避免原始类型滥用。尽量用第三方库（如 `derive_more` crate）而不是手写 newtype 模式。
- trait 约束复杂时用 `where` 子句换行书写，优于塞满尖括号；`impl Trait` 作参数/返回值，避免暴露具体类型。
- 需要抽象多种输入时用 `impl AsRef<Path>` / `impl Into<String>` / `impl IntoIterator` 做函数签名，调用端零样板。
- 用扩展 trait（extension trait）为外部类型加方法：`trait StrExt { ... } impl StrExt for str { ... }`，让调用点链式自然。
- 零成本抽象优先：泛型 + 单态化通常比 `dyn Trait` 更快更简洁；仅在需要异构容器或减少代码膨胀时用 `Box<dyn Trait>`。
- 用 `#[non_exhaustive]` 标注对外枚举与结构体，为未来演进留空间。
- 尽量使用 turbofish `::<T>` 和类型推导协作，避免多余的中间类型标注；能推导就不写。

#### 构造与派生

- 用 `derive` 自动派生 `Debug` / `Clone` / `PartialEq` / `Eq` / `Hash` / `Default` 等，而不是手写。
- 善用 `Default::default()` 与结构体更新语法 `Foo { x: 1, ..Default::default() }` 构造对象，避免写一长串字段。
- 构建者模式用 `derive_builder` 或手写 `with_xxx` 链式，让配置式构造一气呵成。

#### 宏与编译期

- 宏能显著降噪时就用：`vec!`、`format!`、`write!` / `writeln!`、`todo!` / `unimplemented!` / `unreachable!` / `dbg!`。
- 需要小型 DSL 或重复样板时考虑 `macro_rules!`；过程宏仅在确有收益时引入。
- 常量与编译期计算：能 `const fn` 就 `const fn`；用 `const` / `static` 表达不可变全局；需要懒初始化用 `std::sync::OnceLock` / `LazyLock`，而不是 `lazy_static`。

#### 异步

- 异步：用 `async` / `.await`，而不是手写 `Future` 或链式 `then`。并发组合使用 `tokio::join!` / `tokio::try_join!` / `futures::future::try_join_all`。

#### 工程化

- 测试与文档：单元测试写在同文件 `#[cfg(test)] mod tests` 中；公共 API 提供 doctest 示例。
- 遵循 `cargo fmt` 与 `cargo clippy -- -D warnings`，默认开启 `clippy::pedantic` 中合理的 lint。
