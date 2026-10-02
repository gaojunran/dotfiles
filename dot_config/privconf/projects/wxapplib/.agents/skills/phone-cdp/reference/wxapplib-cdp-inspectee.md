# wxapplib 真机 CDP 调试参考（inspectee 实现 internals + 实测行为）

> 2026-09-30 实测环境：iOS 真机 / 测试号 uin 3194525725（微信号 tidyzq3）/ 自建基础库 lib.zip（SDK 3.17.4，skyline 页面）/ automator MCP v1.27.0。
> 本文档是 SKILL.md 的 wxapplib 专属深化：**实现原理、真机实测行为、踩坑记录、任务配方**。
> 做具体调试任务前先扫「§0 任务决策表」，避免反复试错。

---

## 0. 任务决策表（要做什么 → 直接用什么）

| 调试任务 | 直接用 | 注意 |
|---|---|---|
| 推自建基础库到真机 | §1 部署链路 | **build_zip 注入步骤不可跳过**；launch 的 user_name 必须用微信号 |
| 读/写页面 data、调页面方法 | `send_command(type=cdp, Runtime.evaluate)` | REPL 语义见 §3；`evaluate_script` 工具在本库版本上有 bug（§1.5） |
| 拿页面/组件 JS 实例 | evaluate 不带 returnByValue → objectId → `Runtime.callFunctionOn` | 或 `DOM.resolveNode(nodeId)` 从节点反解（§5.2） |
| 看组件树 / 找元素 | `DOM.getDocument(depth:N)` | 自定义组件名即标签名；shadow-root 可见（§5.1） |
| 组件 data 读写 / 触发事件 | `WxComponent.getComponentData/setComponentData/triggerEvent` | `WxComponent.callMethod` **不支持**（实测报错） |
| 调 wx API（同步/异步） | evaluate + `awaitPromise:true` 包 Promise | release 版 wx.request 受域名白名单限制（§4.4） |
| Mock / Hook wx API | evaluate monkey-patch globalThis 保存/恢复 | var 泄漏语义见 §3.3 |
| 截图 | `send_command(type=cdp, Page.captureScreenshot)` | **不支持任何参数**（format/quality/clip 被忽略，§5.4）；automator 的 take_screenshot 走 native 通道，has_native=false 时不可用 |
| 看小程序 console 日志 | MCP `list_console_messages` | evaluate 里打的 console.***不会**出现在这里（双通道，§4.5） |
| 网络排查 | MCP `list_network_requests` 或 `Network.enable` 事件 | 只覆盖开发者主动请求（wx.request/uploadFile/downloadFile/WebSocket），不含图片/脚本资源 |
| 断点 / 单步 / 暂停 | ❌ 不支持 | inspectee 无 Debugger 域；真断点走 DevTools/vConsole（§4.1） |
| 插件内代码调试 | `Runtime.evaluate` + `executionContextName: "{provider}/0"` | 插件 ctx 能读宿主全局（§3.4） |
| 会话掉线恢复 | `launch(原 test_id)` + `init_session` | 无需重推库（§1.4） |

---

## 1. 部署链路（完整踩坑记录）

### 1.1 连接方式

- MCP endpoint：`https://miniprogram-automator-mcp.mcp.woa.com`，streamable-http，`Authorization: Bearer $TAI_TOKEN`（环境变量已有）。
- opencode 会话内**没有**注册 mcp__* 工具 → 用 curl 直连 JSON-RPC：
  - 辅助脚本：本 skill `scripts/cdp_eval.py`（Python，含会话自动建立、`call(name,args)`、`cdp(method,params)`、`ev(expr)` 三个惯用函数）
  - 用法：`python3 cdp_eval.py '<js表达式>'` 或 `from cdp_eval import call, cdp, ev` 后写探测脚本
  - 会话 SID 存在脚本同目录 `mcp-sid.txt`，丢失/过期自动重建
- curl 超时给足：`init_session` 可能 60-100s，单条 `-m 150+`。

### 1.2 推库全链路（顺序不可乱）

```
① 本机 zip → 服务端路径（唯一入口）
   curl -X POST -F 'file=@lib.zip' http://weapptest.oa.com/miniprogram-automator-mcp/upload-src-zip
   → {"path": "/root/weiqi-mcp/miniprogram_automator_mcp/src_zips/lib.zip", ...}

② build_zip(src_zip_path=①的path)     ← ★ 关键注入步骤，不可跳过
   服务端把 automator_dc.head.js 追加进 WAServiceRemoteDebug.js，
   生成注入版 zip（.cache_automator/ 下）

③ upload(zip_path=②的注入zip) → test_id

④ push(user_name="tidyzq3", test_id=...)     ← user_name 用微信号或 uin 均可

⑤ launch(user_name="tidyzq3", app_id="...", test_id=..., need_js="devup", wait_seconds=18)
   ← ★ user_name 必须用微信号！用 uin 报 -10086 Get UserName Fail / -4 not test user
   rtn=-1 也是成功；真实结果以 init_session 为准

⑥ init_session(shell_name="tidyzq3", wait_client=true, wait_client_timeout=60)
   → "AppService 端已上线，当前页面: pages/index/index"
```

### 1.3 跳过 build_zip 的症状（都实测出现过）

- push rtn=0 看似成功，但 init_session 永远等不到 AppService（60-90s 超时）
- 或 has_app=true 但所有命令报 **`dc.onCustomMessage is not a function`**——设备侧 automator 消息桥（head.js 注入的）不存在
- 结论：upload 描述里"上传注入后的基础库 zip"的"注入"由 build_zip 完成，不是 upload

### 1.4 会话生命周期

- **注入库只在冷启动生效**：推库后正在跑的小程序不会自动用新库，必须杀掉重开（或自动 launch）
- 自动 launch 失败时（如测试服务拒绝），让用户**手动拉起**小程序，然后 init_session
- 掉线症状：`get_session_status` 显示 `has_app: false`，命令报 "AppService 不在线"
- 恢复：`launch(user_name=微信号, app_id, test_id=原test_id, need_js=devup)` + `init_session`——设备上注入库还在，**无需重推**
- 小程序被杀/退后台过久都会掉线

### 1.5 evaluate_script 工具的坑

MCP 的 `evaluate_script` 工具在本基础库版本上抛 `JS 执行异常: callFunctionOn@WARemoteDebug.js...`（其内部用 callFunctionOn 的路径有兼容问题）。
**绕过**：一律用 `send_command(type=cdp, method=Runtime.evaluate, params={...})`，功能完全等价且更可控（可用 executionContextName / throwOnSideEffect 等全部参数）。

---

## 2. 架构：CDP 命令到底跑在哪（源码级）

### 2.1 三层结构

```
MCP 服务端 ──ws房间──> 设备
                        │
        ┌───────────────▼──────────────────┐
        │ ① 调试域 AppDebugContext          │  WARemoteDebug.js（含注入的 head.js）
        │    RuntimeAdapter / 全部 domain    │  独立 JSContext，secure
        └───────┬──────────────────────────┘
                │ evaluate 时：new Function + with(__scope__.scope)
                │ getGlobalThis() 跨域拿 ──┐
        ┌───────▼──────────┐               │
        │ ② 开发者域(子域)   │ <─────────────┘
        │    开发者 JS 跑这里 │  globalThis = 求值的 global 回退
        └──────────────────┘
        ┌──────────────────┐
        │ ③ 插件 context ×N │  scope=插件global，global 回退仍是②的 globalThis
        └──────────────────┘
```

- 调试域由 `__subContextEngine__.createAppDebugContext()` 创建：`src/subcontext-engine/src/libcontext/init/AppDebugContext.js`（entryLibs: ['WARemoteDebug.js']），入口在 `src/sdk/src/appservice/debug/inspectee.ts:121`
- adapter 注册表：`src/remote-debug/src/view-side/inspectee/skyline.ts:450-484`（所有 domain 在这里 bindAdapter）
- 求值核心：`src/wx-inspectee/src/inspectee/adapters/Runtime/context.ts:318`
  ```js
  const fn = new this._Function('__scope__', `with(__scope__.scope){\n${transformed}\n}`)
  const result = fn.call(global, scopeManager)   // global = appServiceEngine().__getGlobal()
  ```
- `__getGlobal`：`src/app-service-engine/src/plugin/global.ts:264` —— iOS 返回裸 globalThis；**Android 套 condom Proxy**（V8 跨域 no access 限制的绕法，typeof/相等性行为可能不同，未实测）
- REPL 变换：`transformForREPL`（acorn AST）：`src/wx-inspectee/.../Runtime/context.ts:8-120`
- ScopeManager（with-proxy）：同文件 `:218-281`——`has` 恒 true（劫持全部标识符查找）、get: rawScope→global→**ReferenceError**、set: rawScope（const 守卫）→global
- 插件 context 注册：`src/wx-inspectee/.../Runtime/contextRegistry.ts:41`（`initContextsForMiniProgram`，为 `getAllPluginConfigs()` 每个插件建 `{provider}/0`）

### 2.2 执行上下文清单（寻址方式）

| context | 寻址 | scope（rawScope） | global 回退 |
|---|---|---|---|
| 默认（appservice 主域） | `contextId` 省略 / `executionContextName: ""` | 会话级声明变量表 | 开发者域 globalThis |
| 插件 | `executionContextName: "{providerAppId}/0"` | 插件 global（`_createPluginGlobal` 造的独立对象） | 同上（开发者域 globalThis） |

错误寻址有明确报错：`Execution context with id N not found` / `Execution context for name X not found`。

`executionContextName` 是**非标准 CDP 扩展参数**（标准 CDP 只有 contextId）；App.CDPListProtocol 可列出全部支持的方法。

---

## 3. Runtime.evaluate 实测语义（REPL）

### 3.1 声明与持久化

- `var/let/const/function/class` 声明**跨调用持久**（存在会话 scope 的 rawScope）
- `{a:1}` 对象字面量正常返回（acorn LabeledStatement 特判）
- 重复 `let` 声明 → `SyntaxError: Identifier 'x' has already been declared`
- `var` 重复声明合法（覆盖）

### 3.2 求值形态

- `awaitPromise:true`：resolve/reject 路径都通；reject 走 exceptionDetails
- `throwOnSideEffect:true`：AST 静态检查——赋值/函数调用抛 `Possible side-effect in debug-evaluate`，纯表达式放行（DevTools 悬停预览用）
- `returnByValue:true` → JSON 值；省略 → `{objectId, className, description, preview}` 对象句柄
- `Runtime.callFunctionOn(functionDeclaration, objectId, returnByValue)`：对句柄对象调任意函数，`this` = 该对象
- `Runtime.getProperties(objectId)`：ownProperties + internalProperties（如 `[[Prototype]]`）；accessorPropertiesOnly 实测返回空
- 定时器/异步副作用在 evaluate 返回后**继续存活**（setTimeout 300ms 后全局标记可见）

### 3.3 作用域泄漏语义（重要）

- **`var`/`function` 声明同时写 globalThis** → 跨 context 可见（插件 ctx 里 `var x` 主 ctx 能读到）
- 隐式赋值 `x = 1`（未声明）→ 落到 globalThis（不是 rawScope）
- `let/const` 只进会话 scope，其他 context 读 → ReferenceError
- 清理手法：`delete globalThis.__varName`（var 泄漏）；let 变量断会话自动消失
- **`__scope__` 本身暴露在词法作用域**：`__scope__.rawScope/global/declared/scope` 全可摸（代码 TODO 已知），排查 REPL 状态直接用它

### 3.4 插件 context 实测

- scope 含插件专属：`__wxRoute`（`__plugin__/{appid}/...`）、独立 `wx`（368 keys vs 主域 748）、`requireMiniProgram`、`WXWebAssembly`、`Page/Component/Behavior`（插件 codespace 版）
- `globalThis` 仍是开发者域的 → **插件 ctx 可读写宿主全局**（含 `__wxConfig`、宿主 var 泄漏）——跨域隔离是单向的（scope 层），global 层共享
- 插件的 `wx` ≠ 宿主 `wx`（`globalThis.wx === wx` 为 false）

### 3.5 标识符探测的坑

with-scope proxy 的 get 对不存在的标识符**直接抛 ReferenceError**，所以 `typeof foo` 的安全惯用法**失效**（`typeof WebAssembly` 实测抛错）。
正确姿势：`typeof globalThis.foo`（globalThis 属性访问不走 scope proxy）。

---

## 4. 能力与边界（实测清单）

### 4.1 没有真调试器

无 Debugger 域：**无断点、无暂停、无单步、无调用栈采样**。这是 Function 构造器模拟的 REPL 运行时。真断点调试是另一套（`src/remote-debug/src/service-side/jscore-debugger/`，仅 iOS，vConsole/DevTools 走它）。

### 4.2 全局变量可见性（iOS 实测）

**可见**：`wx`、`getApp`、`getCurrentPages`、`App/Page/Component/Behavior`、`require/define`、`console`、`setTimeout`、`Function/eval`、`WeixinJSBridge`（invoke 可直调）、`__wxConfig`、`__wxAppCode__`、`__wxAppData`、`__wxAppCurrentFile__`、`__wxRoute`、`__debuggerMessager__`、`__appServiceSDK__`、`globalThis`（=开发者域 global）、`$0`–`$3`（`DOM.setInspectedNode` 后，实测拿到组件实例）

**不可见（ReferenceError）**：`window`、`document`（service 侧无 DOM）、`fetch`、`XMLHttpRequest`、`WebSocket`、`localStorage`、`WebAssembly`（appservice 子域没有，插件域有 WXWebAssembly）、`__subContextEngine__`、`__glassEaselAdapter__`、`__inspectee__`、`Reporter`（这些是调试域/主域专属）

### 4.3 异常与栈

- exceptionDetails 有 exceptionId/text/exception（objectId）
- **无源码定位**：lineNumber 恒 0，栈只有 WARemoteDebug.js 内部帧（调试域 realm 编译，无 sourcemap）

### 4.4 release 版限制

- `__wxAppCode__` 只有 .json/.wxml，**无 js 源码**
- `wx.request` 受域名白名单约束（release 版实测 `url not in domain list`）

### 4.5 console 双通道（不互通）

| 通道 | 来源 | 读取方式 |
|---|---|---|
| automator 采集 | 小程序代码（WAAutoService 通道） | MCP `list_console_messages` |
| LogManager 环形缓冲（8K） | evaluate 里的 console.*（Runtime.consoleAPICalled 事件） | CDP 客户端事件 / DevTools |

实测：evaluate 里 `console.error` **不会**出现在 list_console_messages；小程序自身日志两者都有（deprecated warning 等）。

### 4.6 其他边界

- objectId **per-MCP-connection**：换 curl 会话后旧句柄失效
- `Page.captureScreenshot` 无参数（§5.4）
- `WxComponent.callMethod` 不支持（报 method not supported）
- Android 的 condom Proxy（`__getGlobal` 包装）未实测，typeof/=== 行为可能不同

---

## 5. CDP domain 完整目录（App.CDPListProtocol 实测，共 14 个 domain）

| Domain | 命令 | 实测要点 |
|---|---|---|
| **Runtime** (10) | evaluate, callFunctionOn, awaitPromise, getProperties, releaseObject, releaseObjectGroup, addBinding, removeBinding, enable, disable | 全文 §3；事件: bindingCalled / executionContextCreated / consoleAPICalled |
| **DOM** (23) | getDocument, describeNode, getOuterHTML, performSearch, getAttributes, setAttributeValue, setAttributesAsText, removeAttribute, removeNode, setInspectedNode, discardSearchResults, getSearchResults, pushNodesByBackendIdsToFrontend, enable, disable… | 树是 glass-easel 组件树（非浏览器 DOM）；shadow-root 有独立 nodeId；事件: childNodeInserted/Removed, attributeModified 等 |
| **WxComponent** (18) | getComponentData, setComponentData, resolveContext, resolveComponentCaller, getInnerText, getProperties, getScrollOffset, setScrollOffset, getByXPath, getShadowRootId, triggerEvent, enable, disable… | 事件: eventTriggered / componentDataUpdated / componentDataChanged；**无 callMethod** |
| **CSS** (6) | getComputedStyleForNode, getInlineStylesForNode, getMatchedStylesForNode, setStyleTexts, enable, disable | 按 nodeId 查计算样式 |
| **Overlay** (5) | highlightNode, hideHighlight, setInspectMode, enable, disable | 节点高亮（需要对应渲染端支持） |
| **Snapshot** (4) | enable, getTree, getStructuredTree | 结构化快照（automator take_snapshot 底层） |
| **MPPage** (10) | getStack, getCurrent, navigateTo, redirectTo, switchTab, reLaunch, navigateBack, waitForReady, enable, disable | 页面栈/导航；事件: pageStackChanged |
| **MDPElement** (10) | tap, longpress, getText, getLayout, scroll, swiperNext, swiperPrev, swiperTo, enable, disable | 元素交互 |
| **MDPForm** (10) | input, switchToggle, radioSelect, checkboxToggle, sliderChange, pickerSelect, pickerViewChange, batchFill, enable, disable | 表单批填 |
| **Input** (5) | dispatchKeyEvent, insertText, dispatchTouchEvent, enable, disable | 输入事件派发 |
| **Log** (2) | enable, disable | 事件: entryAdded（console/error 进 LogManager） |
| **Page** (3) | captureScreenshot, enable, disable | 截图无参数；必须 Service 线程 |
| **Network** (3) | enable, disable, getResponseBody | 只覆盖开发者主动请求 + WebSocket 帧；事件: requestWillBeSent/responseReceived/dataReceived/loadingFinished/Failed、webSocketCreated/FrameSent/FrameReceived 等 |
| **Exparser** (3) | setTreeMode, enable, disable | 树模式切换 |

automator 协议方法（`send_command(type="auto")`）：`App.CDPListProtocol`（列协议）、`App.CDPEnable(domain)`（开事件推送）、`App.getPageStack`、`Page.getData(pageId)` 等。

### 5.1 组件树遍历配方

```python
r = cdp('DOM.getDocument', {'depth': 6})
# 递归 walk：nodeName 即标签名（自定义组件=完整路径名如 components/rank-list/rank-list，
# 内置组件=view/image/scroll-view；#shadow-root 是 shadow 边界）
```

### 5.2 节点 → JS 对象 → 调方法

```python
r = cdp('DOM.resolveNode', {'nodeId': 87})            # 自定义组件节点
oid = r['data']['result']['object']['objectId']       # 实测 className 通常是压缩后的（如 'c'）
r2 = cdp('Runtime.callFunctionOn', {
  'functionDeclaration': 'function(){ return {is: this.is, data: this.data} }',
  'objectId': oid, 'returnByValue': True})
# 内置组件（view/input 等）不暴露 JS 对象 → 用 get_element_info
```

### 5.3 页面/组件实例直接拿

```python
cdp('Runtime.evaluate', {'expression': 'getCurrentPages()[0]'})          # → ComponentCaller 句柄
cdp('Runtime.evaluate', {'expression': 'getCurrentPages()[0].selectComponent("#nav")'})
# 纯 evaluate 惯用法（无需 DOM）：
ev("getCurrentPages().pop().data")
ev("(d) => getCurrentPages().pop().setData(d)", ...)  # MCP evaluate_script 形态；raw CDP 用 §3 语义拼表达式
```

### 5.4 截图

```python
r = cdp('Page.captureScreenshot')   # 无参数；实测 jpeg ~330-470KB，1206×2622
import base64; open('s.jpg','wb').write(base64.b64decode(r['data']['result']['data']))
```
实现链路：`PageAdapter`（`src/wx-inspectee/.../Page/index.ts:52`）编排 4 个 jsapi：
`private_captureScreen`（native 截屏，spec.js 私有 API）→ `saveFile` → `readFile(encoding:base64)` → `removeSavedFile`。
jsApiInvoke 真身 = `jsBridge().invoke`（`skyline.ts:471`）。**必须 Service 线程**；webview 侧命令自动转发。

### 5.5 addBinding（页面→调试器反向通道）

```python
cdp('Runtime.addBinding', {'name': 'onEvent'})      # 装到所有 context 的 globalThis
ev("onEvent('payload')")                            # 页面代码/evaluate 里调用
# → 事件流 bindingCalled（CDP 客户端收；MCP 侧不转发，需自己挂 CDP 事件监听）
cdp('Runtime.removeBinding', {'name': 'onEvent'})   # globalThis 上的函数可能残留 → delete globalThis.onEvent
```

---

## 6. 环境资产

| 项 | 值 |
|---|---|
| 测试号 uin | 3194525725 |
| 测试号微信号（launch/init_session 用） | tidyzq3 |
| 已验证可拉起的 appid | wx8fa80c7f0ab64cb2（小说阅读，含插件 novel-plugin wx293c4b6097a8a4d0，skyline 页面） |
| push/upload 的 user_name | 微信号或 uin 均可 |
| 临时工作目录（含全部探测脚本样例） | `/private/var/folders/dy/jwsw_x11563ffsmz28wlf_gw0000gp/T/opencode/wxa-cdp/`（重启会丢，脚本已存本 skill `scripts/`） |
| 上传中转 | `http://weapptest.oa.com/miniprogram-automator-mcp/upload-src-zip` |

## 7. 源码索引（改 inspectee 时从这里进）

| 功能 | 文件 |
|---|---|
| Runtime 求值/REPL/ScopeManager | `src/wx-inspectee/src/inspectee/adapters/Runtime/context.ts` |
| context 注册（主域+插件） | `src/wx-inspectee/src/inspectee/adapters/Runtime/contextRegistry.ts` |
| evaluate CDP 入口 | `src/wx-inspectee/src/inspectee/adapters/Runtime/index.ts:193` |
| Page 域（截图） | `src/wx-inspectee/src/inspectee/adapters/Page/index.ts` |
| domain 注册表 | `src/remote-debug/src/view-side/inspectee/skyline.ts:450` |
| DebugContext 创建 | `src/subcontext-engine/src/libcontext/init/AppDebugContext.js` + `src/sdk/src/appservice/debug/inspectee.ts:121` |
| `__getGlobal`（Android condom） | `src/app-service-engine/src/plugin/global.ts:264` |
| 插件 global 构造 | `src/app-service-engine/src/plugin/global.ts:107` |
| automator appservice 入口（CDP ws 桥） | `src/auto/src/appservice/index.ts:130-196`（`ws://localhost:9242/cdp`） |
| debuggerMessager（dc 桥） | `src/subcontext-engine/src/libcontext/init/Debugger.js` |
