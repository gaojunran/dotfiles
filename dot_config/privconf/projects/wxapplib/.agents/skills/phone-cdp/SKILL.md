---
name: miniprogram-automator
description: 通过 miniprogram-automator-mcp 驱动微信小程序做端到端自动化与调试：注入/拉起小程序、快照定位元素、拿整页 WXML 验证渲染、点击填充、读写页面数据与调 wx API、观察 console 与网络、跑冒烟验收。工具面与语义对齐 chrome-devtools-mcp，熟悉它的 agent 可直接沿用「快照 → ref → 操作」回路。当用户需要自动化操作小程序、跑小程序测试用例、复现小程序 UI 问题或排查小程序运行时错误时使用。
---

# 小程序 Automator MCP 使用 Skill

面向 agent 的 `miniprogram_automator_mcp` 使用指南。工具面与语义对齐
**chrome-devtools-mcp**——熟悉它的 agent 可直接沿用「快照 → ref → 操作」回路。
共 **34 个工具**。

## 核心概念

### 调试回路（与 chrome-devtools-mcp 同构）

```python
init_session(shell_name="<测试号>", app_id="<appid>")
take_snapshot()                          # ① interact 模式快照（可见可交互节点），[ref=N] 即元素 id
click(element_id="42")                   # ② ref 直接可用（失效自动自愈）
fill(element_id="57", value="张三")       # ③ 填值（input/picker/slider 自动分派）
wait_for(text=["成功", "失败"])           # ④ 等任一文本出现（OR 语义）
list_console_messages(types=["error"])   # ⑤ console 日志 + 未捕获异常
list_network_requests()                  # ⑥ 网络请求记录
take_screenshot()                        # ⑦ 截图（默认内联返回图像）
```

### 关键设计

- **快照优先（交互场景）**：`take_snapshot` 的 `[ref=N]` 就是元素 id（=nodeId），
  直接传给 `click`/`fill`/`get_element_info`/`evaluate_script(args)`。
  ★ 默认（interact 模式）只含用户可见的可交互节点——开发者视角看全部节点用
  `take_snapshot(verbose=True)`（debug 模式）或 `get_page_wxml`（见「工具选择」）。
- **失效自愈**：页面重渲染后元素工具先探活（DOM.describeNode），
  失效时按缓存信息自动重查找；自愈失败才需要重新快照。
- **console/网络自动采集**：`init_session` 成功后自动开启，无前置开关。
- **失败即 MCP isError**：错误文本是 `{"success": false, "error": "..."}` envelope，
  机器可解析、人可读；成功返回 `{"success": true, "message", "data"}`。
- **evaluate_script 全能口**：页面/组件数据、wx API、Mock 惯用法全走它（见「分主题详解」）。

### 会话生命周期

**推送基础库 → 拉起小程序 → init_session** 是每次使用的必要链路，前两步都不是可选的：

- **推送基础库（必要）**：MCP 服务会修改基础库以开启调试服务，基础库才会与
  调试服务器建立连接——不推送，`init_session` 永远等不到 AppService。
- **拉起小程序（必要）**：只有拉起了小程序，基础库才会建立与调试服务器的连接。
- `init_session` 连的是已经跑起来的小程序，必须在 `launch` 之后调用；
  建连成功后自动开启 console 采集与网络跟踪，不需要额外开关。

小程序不在跑时 `init_session` 报「等待 AppService 超时」，用 `launch`（带原 `test_id`）
恢复拉起即可（设备上注入库还在，无需重新推送）。

### 页面选择

小程序任一时刻只有一个顶层页面，**没有 `select_page`**（与 chrome 最大的差异）。
切换页面只能用 `navigate_page`；历史页面用各工具的 `page_id` 参数寻址
（`pageId` 从 `list_pages` 拿）。

## 工作流

### 与页面交互前的标准回路

1. **推送基础库**（必要，见「部署与拉起链路」——不推送则后面全连不上）
2. **拉起小程序**：`launch`（必要——不拉起则基础库不会连接调试服务器）
3. **建连**：`init_session`
4. **导航 / 等待**：`navigate_page`；`wait_for` 确认目标内容已出现（知道要找什么时）
5. **快照**：`take_snapshot` 拿到元素 `ref`
6. **交互**：用快照里的 `ref` 去 `click` / `fill` / …

### 部署与拉起链路（小程序特有，chrome 无对标）

```
全链路：build_zip → upload → push → launch → init_session
快捷链：send_wxlib → launch → init_session
恢复拉起：launch(带原 test_id) → init_session（无需重新推送）
```

★ 推送与拉起都是**必要步骤**（原因见「会话生命周期」）。环境要求：
测试号必须是 **319 开头 uin** 的微信测试号（其他微信号不支持）；
微信客户端必须是**开了 dailybuild 宏**的包（线上普通微信不能自动拉起，
但可手动拉起后直接 `init_session`）。详见「常见坑」9/10。

⚠️ 服务运行在远程 Linux：`*_path` 参数都在**服务端**解析，本机路径
（/Users/xx、C:\xx）传给 build_zip / upload 一律报「文件不存在」——
MCP 工具调用传不了二进制，`upload` 也只收服务端路径。按 zip 所在位置分三种情况：

- **zip 已在服务端**（预置目录，或之前上传过）：直接传文件名，
  `build_zip(src_zip_path="feat-13051-8391.zip")` 自动查找，无需上传
- **zip 在本机**：唯一入口是先 HTTP 上传换服务端路径，再传给 build_zip：

```bash
curl -X POST -F 'file=@/本机路径/your-lib.zip' \
  http://weapptest.oa.com/miniprogram-automator-mcp/upload-src-zip
# → 返回 {"path": "/data/src_zips/..."}，传给 build_zip(src_zip_path=...)
```

- **已有 test_id / wx_lib_id**：跳过 build_zip / upload，直接 `push` 或 `send_wxlib`

### 高效取数

- console / 网络用 `types` / `resourceTypes` 过滤 + `pageIdx` / `pageSize` 分页，别全量拉。
- `get_element_info` 的 `attributes`/`styles`/`properties` **必须传 `names`**，否则基础库挂起 30s 超时。
- 截图用 `file_path` 落盘（返回路径）而不是内联，避免大图进上下文。
- `list_console_messages(clear=True)` 做用例间基线重置。
- 交互类工具不需要更新页面状态时优先省掉快照返回。

### 工具选择

- **模拟用户操作（用户视角）**：`take_snapshot()`（interact 模式——剔除不可见节点，
  只有可交互节点带 `ref`）→ 拿 `ref` 操作。适合不了解源码、以用户视角观察或
  模拟真实操作
- **开发者视角验证渲染（已知源码）**：`take_snapshot(verbose=True)`（debug 模式——
  返回全部节点的结构树，无 ref）或 `get_page_wxml`（DOM.getOuterHTML 的原始
  WXML 文本，可逐字对照源码）
- **CSS 精确定位**：`get_element(selector=...)`（快照之外的入口，可 `index`/`multiple`）
- **按文字一步到位**：`click_by_text(inner_text=...)`（高频；支持 `fuzzy`）
- **a11y 树拿不到的数据**：`evaluate_script`（页面/组件 data、wx API、Mock）
- **工具面覆盖不到的能力**：`send_command` 逃生舱

### 并行执行

多个工具调用可以并行发出，但必须保持正确顺序：
`navigate → wait → snapshot → interact`。

## 分主题详解

### 会话管理

```python
# 建连（必须在 launch 之后；成功后自动开启 console 采集 + 网络跟踪）
init_session(shell_name="<测试号/房间名>", app_id="<appid>",
             ws_env="dev", wait_client=True, wait_client_timeout=60)

get_session_status()   # 诊断：initialized / has_app / cached_elements / 当前页面
close_session()        # 断连（小程序本身不受影响）
```

失败判读：「等待 AppService 超时」→ 小程序没在跑，先 `launch(带原 test_id)` 恢复拉起。

### evaluate_script —— 数据与 wx API 全能口

专用数据工具（get_page_data / set_page_data / call_page_method / call_wx_method /
call_app / 组件族 / mock 族）已删除，统一用 `evaluate_script`
（CDP Runtime，**awaitPromise 默认开启**，异步直接拿结果）：

```python
# 读 / 写页面数据
evaluate_script(function="() => getCurrentPages().pop().data")
evaluate_script(function="(d) => getCurrentPages().pop().setData(d)", args=[{"k": 1}])

# 调页面方法
evaluate_script(function="(...a) => getCurrentPages().pop().someMethod(...a)", args=[1, 2])

# 组件数据（selectComponent 惯用法）
evaluate_script(function="(s) => getCurrentPages().pop().selectComponent(s).data", args=["#comp"])

# App
evaluate_script(function="() => getApp().globalData")

# 异步 wx API（回调式包 Promise）
evaluate_script(function="async () => await new Promise(r => wx.getLocation({success: r, fail: r}))")

# Mock（monkey-patch + 保存/恢复原始引用）
evaluate_script(function="() => { globalThis.__orig = wx.getLocation; wx.getLocation = (o) => o.success && o.success({latitude: 39.9, errMsg: 'getLocation:ok'}) }")
evaluate_script(function="() => { wx.getLocation = globalThis.__orig }")   # ★ 用完恢复

# Hook / 观察
evaluate_script(function="() => { globalThis.__reqLog = []; const o = wx.request; wx.request = (o2) => { globalThis.__reqLog.push(o2.url); return o.call(wx, o2) } }")
evaluate_script(function="() => globalThis.__reqLog")                       # 读回
```

**args 三种形态**：
1. 普通 JSON 值 → 按值传给函数形参
2. **自定义组件/页面节点的 element_id**（get_element/快照返回值）→ 自动经
   DOM.resolveNode 转为对象引用，形参拿到 Component/Page 的 `this`。
   ★ 内置组件（view/input/image 等）不暴露 JS 对象——传入会得到明确报错（属预期），
   读内置组件属性请用 get_element_info
3. `{"$objectId": "..."}` → 对象句柄回传（★ 传 Page/组件实例的标准方式）：
   `evaluate_script(function="() => getCurrentPages().pop()")` 拿到句柄后回传

**返回值**：可序列化 → `{"value": ...}`；非序列化（页面/组件实例等）→
`{"handle": {"objectId", "type", "className", "description"}}` 句柄，
可经形态 3 传回后续调用（这就是获取页面/组件实例的口子）。

**执行上下文**：appservice（逻辑层）——可直接访问 wx / getApp() / getCurrentPages()；
不能访问渲染层 DOM。执行异常（exceptionDetails）会作为错误抛出。

### 页面导航

```python
# 五种导航 + home + 幂等
navigate_page(method="navigateTo", url="/pages/detail/detail", params={"id": "123"})
navigate_page(method="navigateBack", delta=1)
navigate_page(method="switchTab", url="/pages/tab/index")     # tabbar 页只能用这个
navigate_page(method="home")                                   # 回 app.json 首页（动态解析）
navigate_page(method="reLaunch", url="/pages/index/index", ensure=True)  # 已在则 no-op

# 页面列表（★ 小程序任一时刻只有一个顶层页面 → 没有 select_page）
list_pages(scope="stack")   # [{pageId, path, isCurrent}]（栈顶在末尾）
list_pages(scope="all")     # app.json 全部注册页面
```

历史页面用各工具的 `page_id` 参数寻址（从 list_pages 拿 pageId）。

### 元素交互

#### 快照与定位

```python
take_snapshot()                    # interact 模式：可见可交互节点，行如 `- button "提交" [ref=42]`
take_snapshot(diff=True)           # 增量快照（只返回变化部分，chrome 没有）
take_snapshot(verbose=True)        # debug 模式：全部节点（开发者视角，无 ref）

get_page_wxml()                    # 整页完整 WXML（DOM.getOuterHTML，含视口外节点）
get_page_wxml(element_id="42")     # 单个节点的 WXML

get_element(selector=".btn-primary")          # CSS 精确定位（快照之外的入口）
get_element(selector=".item", index=2)        # 第 3 个匹配
get_element(selector="input", multiple=True)  # 全部匹配
click_by_text(inner_text="登录")              # 按文字一步定位并点击（高频）
click_by_text(inner_text="按钮", selector="button", index=1)
click_by_text(inner_text="登录", fuzzy=True)  # 包含匹配
```

#### 操作

```python
click(element_id="42")                        # 点击（ref / element_id）
long_press(element_id="42", duration=1000)    # 长按

fill(element_id="57", value="张三")            # input/textarea：输入
fill(element_id="63", value=2)                # picker：选第 3 项（★ value 是索引，多列传数组）
fill(element_id="71", value=50)               # slider：滑到 50（区间外被钳制）

dispatch_event(element_id="42", event="longpress")                  # DOM 事件
dispatch_event(element_id="42", event="custom", mode="trigger")    # 组件绑定事件

touch(element_id="e1", phase="start",                         # 触摸序列（模拟手势）
      touches=[{"identifier": 0, "clientX": 100, "clientY": 200}],
      changed_touches=[{"identifier": 0, "clientX": 100, "clientY": 200}])
# … phase="move" … phase="end"

swipe_to(element_id="95", index=2)            # swiper 翻页（导航语义，不并入 fill）

scroll(top=800)                               # 页面滚动
scroll(selector="#submit-btn")                # 页面滚到指定元素
scroll(element_id="88", top=300, left=50)     # scroll-view 滚动
```

#### 元素信息

```python
get_element_info(element_id="42", info_type="attributes", names="class,id")  # WXML 标签属性
get_element_info(element_id="42", info_type="properties", names="value")     # 组件参数（运行时值）
get_element_info(element_id="42", info_type="styles", names="width")         # 计算样式
get_element_info(element_id="42", info_type="wxml")      # 元素 WXML 片段
get_element_info(element_id="42", info_type="offset")    # 偏移
get_element_info(element_id="42", info_type="rect")      # 矩形（不可用自动降级 offset）
get_element_info(info_type="scroll")                    # ★ 页面滚动状态（省略 element_id）
get_element_info(element_id="88", info_type="scroll")    # 元素滚动状态（scroll-view）

# attributes=标签上的字面属性（class/id/data-*）；properties=组件参数，普通节点返回 null。
# attributes/styles/properties 必须传 names，否则基础库挂起 30s 超时。
```

### Console / 网络 / 等待 / 截图

```python
# Console（采集自 init 自动开启；console 日志与未捕获异常统一缓冲）
list_console_messages()                                # 全部
list_console_messages(types=["error"])                 # 错误 + 未捕获异常（is_exception + stack）
list_console_messages(clear=True)                      # 基线重置（用例间隔离）
list_console_messages(pageIdx=1, pageSize=50, includeStackTraces=True)
get_console_message(msgid=3)                           # 单条完整内容（含堆栈）

# 网络（★ 只覆盖开发者主动发起的请求：wx.request/uploadFile/downloadFile/WebSocket）
list_network_requests()
list_network_requests(resourceTypes=["XHR"])
get_network_request(reqid="30001.23")                  # 单条详情 + body（10MB FIFO 缓冲）

# 等待
wait_for(text=["提交成功", "失败"])          # 任一文本出现（DOM.performSearch 轮询）
wait_for(page_path="pages/detail/index")     # 等指定页面成为当前页
wait_for(condition="network", cnt=0)         # 等网络空闲

# 截图
take_screenshot()                            # 内联返回图像（多模态直接看图）
take_screenshot(file_path="/tmp/step1.png")  # 落盘返回路径
```

### 弹窗与逃生舱

```python
# 弹窗（★ 真机为模拟执行：modal 走 showToast，授权/支付/分享返回占位结果）
handle_dialog(dialog="modal", action="accept")      # modal/authorize/share: accept|dismiss
handle_dialog(dialog="payment", action="dismiss")   # 支付弹窗仅支持关闭

# 万能逃生舱（工具面覆盖不到的能力从这里走）
send_command(method="App.CDPListProtocol")                    # 列出基础库支持的 CDP 方法
send_command(method="App.CDPEnable", params={"domain": "Network"})
send_command(type="cdp", method="Runtime.evaluate",
             params={"expression": "getApp()", "returnByValue": True})
send_command(type="cdp", method="DOM.getDocument", params={"depth": 2})
send_command(method="Page.getData", params={"pageId": 5})     # 原生 automator 命令（自动注入 pageId）
# type 只接受 auto / cdp（旧值 dc/websocket/ws 已移除，会明确报错）

exit_app()          # 退出小程序（后续操作报「AppService 不在线」属正常；launch 带原 test_id 恢复）
run_acceptance()    # 四点冒烟验收
```

## 常见坑

1. **element_id 失效自愈**：click/fill 等自动探活+重查找；自愈失败报错时重新
   `take_snapshot` / `get_element`。
2. **别用 `selector="view"` 做点击**：匹配最外层容器，坐标可能在屏幕外；
   优先快照（ref 按可交互性过滤）。
3. **navigateTo/redirectTo 不能跳 tabbar 页**：用 `switchTab`；回首页用 `home`。
4. **picker 的 fill value 是索引**（单列 int / 多列 list），不是选项文字。
5. **没有 select_page**：小程序单一顶层页面，切页必须 navigate_page；
   历史页面用 page_id 参数。
6. **网络 list 不含浏览器级资源**（图片/脚本），只有开发者主动发起的请求。
7. **原生弹窗不可真实操控**：handle_dialog 真机为模拟执行。
8. **Mock 惯用法用完要恢复**（见「evaluate_script」），避免影响后续用例。
9. **微信号必须是 319 开头 uin 的微信测试号**：其他微信号不支持；
   推送与拉起必须用同一个测试号。
10. **微信客户端必须是开了 dailybuild 宏的包**：线上普通微信不能自动拉起
    小程序；但可以**手动拉起**小程序后直接进入 `init_session` 阶段。

## 工具速查（34）

| 分类 | 工具 |
|---|---|
| 部署/拉起 | build_zip · upload · push · launch · send_wxlib |
| 会话 | init_session · close_session · get_session_status |
| 页面 | navigate_page · list_pages · take_snapshot · get_page_wxml |
| 元素 | get_element · click_by_text · click · long_press · fill · get_element_info · dispatch_event · touch · swipe_to · scroll · clear_element_cache |
| 求值 | evaluate_script · handle_dialog |
| Console/网络 | list_console_messages · get_console_message · list_network_requests · get_network_request · wait_for · take_screenshot |
| CDP/杂项 | send_command · exit_app · run_acceptance |

> 每个工具的完整参数与「Chrome 对标与差异」见其 docstring（tools/list 可见）。
