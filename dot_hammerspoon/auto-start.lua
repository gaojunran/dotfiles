-- ~/.hammerspoon/init.lua

local home = os.getenv("HOME")
local binDir = home .. "/.config/bin"

local scripts = {}
for file in hs.fs.dir(binDir) do
    if file:match("^auto%-start%-") then
        local fullPath = binDir .. "/" .. file
        table.insert(scripts, fullPath)
    end
end

table.sort(scripts)

-- 延迟执行函数，等 macOS 启动稳定后再执行
hs.timer.doAfter(5, function()
    local function runNext(i)
        if i > #scripts then
            -- hs.notify.new({title="Hammerspoon", informativeText="所有脚本执行完毕"}):send()
            return
        end

        local scriptPath = scripts[i]
        local success, output, status = hs.execute("/bin/bash " .. scriptPath, true)
        
        if success then
            -- hs.alert.show("执行成功: " .. scriptPath)
        else
            hs.alert.show("执行失败: " .. scriptPath .. "\n" .. output)
        end

        -- 执行下一个
        runNext(i + 1)
    end

    runNext(1) -- 从第一个脚本开始
end)
