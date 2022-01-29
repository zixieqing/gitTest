--[[
 * author : kaishiqi
 * descpt : 关于 luna塔 的本地模拟
]]
virtualData = virtualData or {}

local _r  = virtualData._r
local j2t = virtualData.j2t
local t2t = virtualData.t2t

local DEBUG_DEFINES = {
    CURRENT_FLOOR = 40-1,
}


virtualData['LunaTower/home'] = function(args)
    if not virtualData.lunaTower_ then
        local defineConf = CommonUtils.GetConfigAllMess('summary', 'lunaTower') or {}
        virtualData.lunaTower_ = {
            maxFloor         = checkint(defineConf.maxFloor),       -- 最高层数
            resurrection     = checktable(defineConf.resurrection), -- 复活消耗
            currentFloor     = DEBUG_DEFINES.CURRENT_FLOOR,         -- 当前通过的最高层
            challengeFloorHp = {},                                  -- 当前正在挑战的怪物血量, key是敌人编号, value是血量
            ex               = {},                                  -- ex关（key是层，value是map）
            team             = {},                                  -- 编队（key为队伍ID, value为卡牌自增ID list）
        }
    end
    return t2t(virtualData.lunaTower_)
end


virtualData['LunaTower/resurrection'] = function(args)
    return t2t({})
end


-- 进入战斗
virtualData['LunaTower/questAt'] = function(args)
    local data = {
        maxSkillTimes      = 0,
        maxCritDamageTimes = 0,
    }
    return t2t(data)
end


-- 战斗结算
virtualData['LunaTower/questGrade'] = function(args)
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
