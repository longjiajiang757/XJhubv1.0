-- XJ Hub 一键启动器
local ui  = readfile("uilib.lua")
local hub = readfile("XJHub.lua")

-- 去掉 uilib.lua 里可能残留的 return index
ui = ui:gsub("return%s+index", "--")

local full = ui .. "\n\n" .. hub

local fn, err = loadstring(full)
if not fn then
    warn("[XJ Hub] 编译失败: " .. tostring(err))
    return
end

local ok, err2 = pcall(fn)
if not ok then
    warn("[XJ Hub] 执行失败: " .. tostring(err2))
else
    print("[XJ Hub] ✅ 启动成功")
end