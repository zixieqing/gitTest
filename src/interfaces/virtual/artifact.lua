--[[
 * author : kaishiqi
 * descpt : 关于 神器数据 的本地模拟
]]
virtualData = virtualData or {}

local _r  = virtualData._r
local j2t = virtualData.j2t
local t2t = virtualData.t2t


-- 神器解锁
virtualData['Artifact/unlock'] = function(args)
    local cardData = virtualData.playerData.cards[tostring(args.playerCardId)]
    cardData.isArtifactUnlock = 1
    return t2t({})
end


-- 神器天赋升级
virtualData['Artifact/talentLevel'] = function(args)
    local cardData = virtualData.playerData.cards[tostring(args.playerCardId)]
    cardData.artifactTalent = cardData.artifactTalent or {}
    cardData.artifactTalent[tostring(args.talentId)] = cardData.artifactTalent[tostring(args.talentId)] or {}
    cardData.artifactTalent[tostring(args.talentId)].level = checkint(cardData.artifactTalent[tostring(args.talentId)].level) + 1

    local data = {
        level              = cardData.artifactTalent[tostring(args.talentId)].level, -- 天赋等级
        fragmentConsumeNum = 1, -- 消耗的卡牌的神器碎片数量
    }
    return t2t(data)
end


-- 抽宝石消耗
virtualData['Artifact/gemstoneLuckyConsume'] = function(args)
    local data = {
        consume = {}
    }
    return t2t(data)
end
