-- 锁定输入法为搜狗拼音
local targetInputSource = "com.sogou.inputmethod.sogou.pinyin"

-- 切换到搜狗输入法
local function enforceSogou()
    local current = hs.keycodes.currentSourceID()
    if current ~= targetInputSource then
        hs.keycodes.currentSourceID(targetInputSource)
        -- hs.alert.show("已切换到搜狗输入法")
    end
end

-- 注册输入法变化事件
hs.keycodes.inputSourceChanged(enforceSogou)

-- 启动时也切一次
enforceSogou()
