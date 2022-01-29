--[[
 * author : kaishiqi
 * descpt : 关于 宠物数据 的本地模拟
]]
virtualData = virtualData or {}

local _r  = virtualData._r
local j2t = virtualData.j2t
local t2t = virtualData.t2t

local WorldBossConfigParser  = require('Game.Datas.Parser.WorldBossQuestConfigParser')
local worldBossManualConfs   = virtualData.getConf('worldBossQuest', WorldBossConfigParser.TYPE.MANUAL)
local worldBossQuestConfs    = virtualData.getConf('worldBossQuest', WorldBossConfigParser.TYPE.QUEST)
local worldBossLocationConfs = virtualData.getConf('worldBossQuest', WorldBossConfigParser.TYPE.LOCATION)


-- 世界boss列表
virtualData['worldBossQuest/bossList'] = function(args)
    local data = {
        bossList = {}
    }

    local locationList = table.keys(worldBossLocationConfs)
    for worldBossId, _ in pairs(worldBossQuestConfs) do
        local showTime = 5000--virtualData.createSecond('h_:24:?,s_:3:?,m:60:?')
        local startTime = os.time() + (_r(100) > 30 and 5 or -5)-- virtualData.createSecond('h_:24:?,s_:3:?,m:60:?')
        local endedTime = startTime + showTime
        data.bossList[tostring(worldBossId)] = {
            questId   = checkint(worldBossId),
            position  = checkint(locationList[_r(#locationList)]),
            startTime = startTime,
            endTime   = endedTime,
            leftTimes = _r(0, 2),
        }
    end
    return t2t(data) 
end


-- 世界boss历史伤害
virtualData['worldBossQuest/damageHistory'] = function(args)
    local data = {
        damage = {}
    }

    for worldBossId, _ in pairs(worldBossQuestConfs) do
        data.damage[tostring(worldBossId)] = _r(999999)
    end
    for i = 1, 10 do
        data.damage[tostring(i)] = _r(999999)
    end
    return t2t(data)
end


-- 世界boss入口
virtualData['worldBossQuest/home'] = function(args)
    local data = {
        leftTimes     = _r(9),
        leftSeconds   = _r(999),
        currentDamage = _r(9999),
        maxDamage     = _r(9999),
        remainHp      = _r(99999),
    }
    return t2t(data)
end


-- 世界boss手册
virtualData['worldBossQuest/manual'] = function(args)
    local data = {
        manual = {}
    }

    for worldBossId, manualConf in pairs(worldBossManualConfs) do
        local topRank = {}
        for i = 1, _r(1,3) do
            local playerId = _r(999999)
            table.insert(topRank, {
                playerId          = playerId,
                playerLevel       = _r(99),
                playerName        = virtualData.createName(_r(6,12)),
                playerAvatar      = virtualData.createAvatarId(),
                playerAvatarFrame = virtualData.createAvatarFrameId(),
                playerRank        = i,
                playerDamage      = _r(99999),
                playerCards       = {
                    virtualData.createCardData(nil, playerId),
                    virtualData.createCardData(nil, playerId),
                    virtualData.createCardData(nil, playerId),
                    virtualData.createCardData(nil, playerId),
                    virtualData.createCardData(nil, playerId),
                }
            })
        end

        table.insert(data.manual, {
            questId      = checkint(worldBossId), -- boss关卡id
            myMaxDamage  = _r(99999),             -- 我的最高伤害
            myRank       = _r(99),                -- 我的全服排名
            totalNumbers = _r(99999),             -- 全服参与玩家总数
            topRank      = topRank,               -- 排名前三玩家信息
            testReward   = manualConf.test,       -- 试炼奖励领取信息，key为试炼id，value为由已领取的stage组成的list
        })
    end

    return t2t(data)
end


-- 进入战斗
virtualData['worldBossQuest/questAt'] = function(args)
    local data = {
        maxSkillTimes      = 0,
        maxCritDamageTimes = 0,
    }
    return t2t(data)
end


-- 战斗结算
virtualData['worldBossQuest/questGrade'] = function(args)
    local data = {
        hp                = virtualData.playerData.hp,
        gold              = virtualData.playerData.gold,
        mainExp           = virtualData.playerData.mainExp,
        reward            = {},
        cardExp           = {},
        favorabilityCards = {},
    }
    return t2t(data)
end
