-- 创建状态栏图标
local menubar = hs.menubar.new()

-- 获取空调温度的函数
function updateAcTemperature()
   local output, status = hs.execute("mise exec -- nu -l -c 'ac get'", true)
    if status and output then
        local temp = output:gsub("[\r\n]", "")
        menubar:setTitle("🌡" .. temp .. "°C")
    else
        menubar:setTitle("🌡")
    end
end

-- 初始化显示
updateAcTemperature()

-- 每 30 秒更新一次温度
local acTimer = hs.timer.doEvery(30, updateAcTemperature)
