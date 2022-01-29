--[[
 * author : kaishiqi
 * descpt : 关于 市场数据 的本地模拟
]]
virtualData = virtualData or {}

local _r  = virtualData._r
local j2t = virtualData.j2t
local t2t = virtualData.t2t


-- 市场首页
virtualData['market/market'] = function(args)
    local data = {
        refreshCD = _r(99),
        market    = {},
    }
    return t2t(data)
end


-- 退出市场
virtualData['market/close'] = function(args)
    return t2t({})
end
