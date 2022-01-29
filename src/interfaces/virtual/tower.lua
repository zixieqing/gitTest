--[[
 * author : kaishiqi
 * descpt : 关于 爬塔数据 的本地模拟
]]
virtualData = virtualData or {}

local _r  = virtualData._r
local j2t = virtualData.j2t
local t2t = virtualData.t2t

local TowerConfigParser = require('Game.Datas.Parser.TowerConfigParser')
local towerUnitConf     = virtualData.getConf('tower', TowerConfigParser.TYPE.UNIT)
local towerEnemyConf    = virtualData.getConf('tower', TowerConfigParser.TYPE.ENEMY)
local towerContractConf = virtualData.getConf('tower', TowerConfigParser.TYPE.CONTRACT)


local createUnitDefine = function()
    local unitIdList     = table.keys(towerUnitConf)
    local contractIdList = table.keys(towerContractConf)

    local unitContractList = {}
    for i=1,3 do
        local randomIndex = _r(#contractIdList)
        local contractId  = table.remove(contractIdList, randomIndex)
        table.insert(unitContractList, contractId)
    end

    local unitDefine   = {
        unitId        = unitIdList[_r(1, #unitIdList)],
        unitContracts = unitContractList,
        unitChest     = {},
    }

    local unitId   = checkint(unitDefine.unitId)
    local unitConf = checktable(towerUnitConf[tostring(unitId)])
    for i = 1, 4 do
        local chestId = checkint(unitConf['chestId'..i])
        local rewards = virtualData.createGoodsList(_r(1,5))
        unitDefine.unitChest[tostring(chestId)] = rewards
    end
    return unitDefine
end


-- 爬塔主页
virtualData['tower/home'] = function(args)
    if not virtualData.tower_ then
        virtualData.tower_ = {
            currentFloor = 0,  -- 爬塔所在层数
            maxFloor     = 0,  -- 爬塔历史最高层
            teamCards    = '', -- 爬塔队伍卡牌 （逗号格式分隔）
            buyLiveNum   = 3,  -- 爬塔可买活次数
            enterLeftNum = 2,  -- 爬塔剩余进入次数
            isEnter      = 0,  -- 是否进入爬塔  （0否 1 是）
            isReady      = 0,  -- 是否进入单元  （0否 1 是）
            isUnitPassed = 0,  -- 是否单元通关  （0否 1 是）
            unitDefine   = {}, -- 单元设定配置
            unitConfig   = {}, -- 单元手动设置
            seasonId     = _r(100), -- 赛季id
            sweepFloor   = _r(100), -- 扫荡层数
        }
    end
    -- to enter
    local teamCards = {}
    local haveCards = table.keys(virtualData.playerData.cards)
    for i = 1, math.min(#haveCards, 8) do
        local cardId = table.remove(haveCards, _r(#haveCards))
        table.insert(teamCards, cardId)
    end
    -- virtualData['tower/setClimbTeam']({teamCards = table.concat(teamCards, ',')})
    -- virtualData['tower/enterTower']({})
    -- virtualData['tower/setUnitConfig']({
    --     cards1 = tostring(teamCards[1]) .. ',,,,', 
    --     cards = table.concat(teamCards, ',', 1, math.min(5,#teamCards)),
    --     contract1 = table.concat(virtualData.tower_.unitDefine.unitContracts, ',')
    -- })
    -- virtualData.tower_.isReady      = 1
    -- virtualData.tower_.isUnitPassed = 1
    virtualData.tower_.currentFloor = 55
    return t2t(virtualData.tower_)
end


-- 爬塔预设队伍
virtualData['tower/setClimbTeam'] = function(args)
    virtualData.tower_.teamCards = args.teamCards
    return t2t({})
end


-- 进入爬塔
virtualData['tower/enterTower'] = function(args)
    virtualData.tower_.isEnter      = 1
    virtualData.tower_.currentFloor = 1
    virtualData.tower_.enterLeftNum = virtualData.tower_.enterLeftNum - 1
    virtualData.tower_.unitDefine   = createUnitDefine()
    
    local data = {
        unitDefine = virtualData.tower_.unitDefine
    }
    if args.isSweep == 1 then
        data.rewards = virtualData.createGoodsList(_r(10,25))
    end
    return t2t(data)
end


-- 退出爬塔
virtualData['tower/exitTower'] = function(args)
    virtualData.tower_ = nil
    return t2t({})
end


-- 单元配置设置
virtualData['tower/setUnitConfig'] = function(args)
    virtualData.tower_.unitConfig = {
        cards    = args.cards,
        skill    = args.skill,
        contract = string.split2(args.contract, ','),
    }
    return t2t({})
end


-- 爬塔战斗进入
virtualData['tower/questAt'] = function(args)
    local data = {
        maxSkillTimes      = 0,
        maxCritDamageTimes = 0,
    }
    return t2t(data)
end


-- 爬塔战斗结算
virtualData['tower/questGrade'] = function(args)
    local isPassed = checkint(args.isPassed) == 1
    if isPassed then
        local UNIT_PATH_NUM = 5
        if virtualData.tower_.currentFloor % UNIT_PATH_NUM == 0 then
            virtualData.tower_.isUnitPassed = 1
        else
            virtualData.tower_.currentFloor = virtualData.tower_.currentFloor + 1
        end
        virtualData.tower_.maxFloor = math.max(virtualData.tower_.maxFloor, virtualData.tower_.currentFloor)
    end

    local data = {
        hp                = virtualData.playerData.hp,
        gold              = virtualData.playerData.gold,
        mainExp           = virtualData.playerData.mainExp,
        reward            = {},
        cardExp           = {},
        favorabilityCards = {}
    }

    local cardTeam = string.split(virtualData.tower_.unitConfig.cards, ',')
    for i, cardGuid in ipairs(cardTeam) do
        if checkint(cardGuid) > 0 then
            local cardData = virtualData.playerData.cards[tostring(cardGuid)]
            data.cardExp[tostring(cardGuid)] = {
                exp   = cardData.exp,
                level = cardData.level,
            }
            data.favorabilityCards[tostring(cardGuid)] = {
                favorability      = cardData.favorability,
                favorabilityLevel = cardData.favorabilityLevel,
            }
        end
    end
    return t2t(data)
end


-- 爬塔单元奖励
virtualData['tower/draw'] = function(args)
    local oldUnitChest = table.values(virtualData.tower_.unitDefine.unitChest)

    virtualData.tower_.isReady             = 0
    virtualData.tower_.isUnitPassed        = 0
    virtualData.tower_.unitConfig.contract = ''
    virtualData.tower_.currentFloor        = virtualData.tower_.currentFloor + 1
    virtualData.tower_.unitDefine          = createUnitDefine()

    local data = {
        rewards       = oldUnitChest[1],
        unitId        = virtualData.tower_.unitDefine.unitId,
        unitContracts = virtualData.tower_.unitDefine.unitContracts,
        unitChest     = virtualData.tower_.unitDefine.unitChest,
    }
    return t2t(data)
end
