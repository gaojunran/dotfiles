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

