--[[
 * author : kaishiqi
 * descpt : 关于 打牌游戏数据 的本地模拟
]]
virtualData = virtualData or {}

local _r  = virtualData._r
local j2t = virtualData.j2t
local t2t = virtualData.t2t


-- 卡牌剧情解锁
virtualData['Collection/cardStoryUnlock'] = function(args)
    return t2t({})
end


-- 卡牌配音解锁
virtualData['Collection/cardVoiceUnlock'] = function(args)
    return t2t({})
end
