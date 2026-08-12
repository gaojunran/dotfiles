# page-container NavigateBackInterception 时序竞态

## Bug 描述
page-container 的 `leave()` 中直接调用 `stopNavigateBackInterception()`，导致拦截器在客户端处理 `onNavigateBackIntercept` 回调期间被同步移除。客户端后续发现 `navigateBackInterceptionInfo is null`，直接执行页面退出，page-container 没有完成正常关闭流程。

## 事件链（同步路径）
```
onNavigateBackIntercept dispatch → callback: setData({show:false})
→ observerShow(show=false) → leave() → stopNavigateBackInterception()
→ 客户端 remove SILENT (size=0)
→ 客户端后续处理发现 interceptionInfo=null → 直接退出页面
```

## 时序证据（ALog 实测）
| 时间 | 事件 |
|------|------|
| 14:23:06.774 | 客户端 dispatch onNavigateBackIntercept (swipe_back) |
| 14:23:06.779 | stopNavigateBackInterception（仅 5ms 后！） |
| 14:23:06.784 | 客户端 remove SILENT, size=0 |
| 14:23:08.468 | 第二次 swipe_back dispatch |
| 14:23:08.471 | 又 stop（仅 3ms 后） |
| 14:23:08.549 | 客户端 navigateBackInterceptionInfo is null → 直接执行页面退出 |

## 修复方案
`leave()` 中改用 `setTimeout(() => this.stopNavigateBackInterception(), 100)` 延迟移除拦截器，兼容客户端时序。注释说明原因。

## 关键 grep 词（ALog）
- `AppBrandOnNavigateBackInterceptEvent` — 客户端 dispatch
- `Wxapplib.Critical.*stopNavigateBackInterception` — 基础库 stop
- `navigateBackInterceptionInfo is null` — 客户端发现拦截器被移除
- `BaseLibVersion` — 确认真机基础库版本
- `registerNavigateBackInterceptionInfo.*remove.*SILENT` — 客户端移除注册

## 验证注意事项
amend commit 后必须重新构建并 push 到真机，否则真机仍跑旧版代码。用 ALog 中的版本戳确认。
