-- See: https://github.com/Hammerspoon/hammerspoon/issues/1296
-- 需要先把系统级快捷键解绑。

-- 播放/暂停
hs.hotkey.bind({}, "F9", function()
  hs.eventtap.event.newSystemKeyEvent("PLAY", true):post()
  hs.eventtap.event.newSystemKeyEvent("PLAY", false):post()
end)

-- 下一曲
hs.hotkey.bind({}, "F10", function()
  hs.eventtap.event.newSystemKeyEvent("NEXT", true):post()
  hs.eventtap.event.newSystemKeyEvent("NEXT", false):post()
end)

-- 下调音量
hs.hotkey.bind({}, "F11", function()
  hs.eventtap.event.newSystemKeyEvent("SOUND_DOWN", true):post()
  hs.eventtap.event.newSystemKeyEvent("SOUND_DOWN", false):post()
end)

-- 上调音量
hs.hotkey.bind({}, "F12", function()
  hs.eventtap.event.newSystemKeyEvent("SOUND_UP", true):post()
  hs.eventtap.event.newSystemKeyEvent("SOUND_UP", false):post()
end)

-- 将窗口移动到左半屏
hs.hotkey.bind({"ctrl"}, "Left", function()
  local win = hs.window.focusedWindow()
  if not win then return end
  local screen = win:screen()
  local max = screen:frame()
  win:setFrame({x = max.x, y = max.y, w = max.w / 2, h = max.h})
end)

-- 将窗口移动到右半屏
hs.hotkey.bind({"ctrl"}, "Right", function()
  local win = hs.window.focusedWindow()
  if not win then return end
  local screen = win:screen()
  local max = screen:frame()
  win:setFrame({x = max.x + max.w / 2, y = max.y, w = max.w / 2, h = max.h})
end)

-- 将窗口铺满屏幕
hs.hotkey.bind({"ctrl"}, "Up", function()
  local win = hs.window.focusedWindow()
  if not win then return end
  win:maximize()
end)

-- 将窗口还原到正常大小
hs.hotkey.bind({"ctrl"}, "Down", function()
  local win = hs.window.focusedWindow()
  if not win then return end

  local screen = win:screen()
  local max = screen:frame()

  local newWidth = max.w * 0.6
  local newHeight = max.h * 0.6
  local newX = max.x + (max.w - newWidth) / 2
  local newY = max.y + (max.h - newHeight) / 2

  win:setFrame({x = newX, y = newY, w = newWidth, h = newHeight})
end)

-- IINA：将鼠标侧键映射为左右箭头
local sideButtonEventTap = hs.eventtap.new({hs.eventtap.event.types.otherMouseDown}, function(event)
    local button = event:getProperty(hs.eventtap.event.properties['mouseEventButtonNumber'])
    if button == 3 then
        hs.eventtap.keyStroke({}, "left")
        return true
    elseif button == 4 then
        hs.eventtap.keyStroke({}, "right")
        return true
    end
    return false
end)

function bindMouseSideButtonsToArrowKeysForIINA()
    local isIINAFrontmost = false

    local function updateMouseSideKeyBindings()
        if isIINAFrontmost then
            if not sideButtonEventTap:isEnabled() then
                sideButtonEventTap:start()
            end
        else
            if sideButtonEventTap:isEnabled() then
                sideButtonEventTap:stop()
            end
        end
    end

    hs.application.watcher.new(function(appName, eventType, app)
        local ok, err = pcall(function()
            if eventType == hs.application.watcher.activated then
                isIINAFrontmost = (appName == "IINA")
                updateMouseSideKeyBindings()
            end
        end)
        if not ok then
            hs.printf("Error in watcher: %s", err)
        end
    end):start()

    -- 初始化时检测前台应用
    local frontApp = hs.application.frontmostApplication()
    if frontApp and frontApp:name() == "IINA" then
        isIINAFrontmost = true
        updateMouseSideKeyBindings()
    end
end

bindMouseSideButtonsToArrowKeysForIINA()

-- 米家设备控制 HomeAssistant
-- 台灯
hs.hotkey.bind({}, "F8", function()
  hs.execute("mise exec -- nu -l -c lamp", true) 
  -- use mise to capture env vars
end)

-- 空调
hs.hotkey.bind({}, "F7", function()
  hs.execute("mise exec -- nu -l -c ac", true) 
end)

hs.hotkey.bind({}, "F5", function()
  hs.execute("mise exec -- nu -l -c 'ac dec'", true) 
end)

hs.hotkey.bind({}, "F6", function()
  hs.execute("mise exec -- nu -l -c 'ac inc'", true) 
end)

-- 连击F1三次：使显示器休眠
local f1KeyCount = 0
local f1Timer = nil
local f1ComboMaxInterval = 1.0 -- 1秒内按三次

-- 监听F1键
local f1Event = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(event)
    local keyCode = event:getKeyCode()
    local isF1 = keyCode == hs.keycodes.map["f1"]

    if isF1 then
        f1KeyCount = f1KeyCount + 1

        -- 启动或重置计时器
        if f1Timer then
            f1Timer:stop()
        end

        f1Timer = hs.timer.doAfter(f1ComboMaxInterval, function()
            f1KeyCount = 0 -- 超时重置
        end)

        if f1KeyCount == 3 then
            f1KeyCount = 0
            if f1Timer then f1Timer:stop() end

            -- 显示器进入休眠
            hs.caffeinate.lockScreen() -- 可选：先锁屏
            -- hs.execute("pmset displaysleepnow")
        end
    end

    return false -- 不阻止其他F1的默认行为
end)

f1Event:start()
