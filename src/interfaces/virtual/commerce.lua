--[[
 * author : kaishiqi
 * descpt : 关于 商会数据 的本地模拟
]]
virtualData = virtualData or {}

local _r  = virtualData._r
local j2t = virtualData.j2t
local t2t = virtualData.t2t


-- 商会首页
virtualData['Commerce/home'] = function(args)
    if not virtualData.commerce_ then
        virtualData.commerce_ = {
            status         = 2,         -- 1:出海中 2:靠岸中
            leftSeconds    = _r(99999), -- 当前状态结束剩余秒数
            titleGrade     = 1,         -- 商会称号等级
            warehouseGrade = 10,        -- 仓库容量级别
        }
    end
    return t2t(virtualData.commerce_)
end
