--[[
 * author : kaishiqi
 * descpt : 工会战 数据模型工厂
]]
local BaseModel              = require('Game.models.BaseModel')
local UnionConfigParser      = require('Game.Datas.Parser.UnionConfigParser')
local unionWarsDefinesConfs  = CommonUtils.GetConfigAllMess(UnionConfigParser.TYPE.WARS_DEFINES, 'union') or {}
local unionWarsTimeLineConfs = CommonUtils.GetConfigAllMess(UnionConfigParser.TYPE.WARS_TIME_LINE, 'union') or {}
local unionWarsDefinesConf   = unionWarsDefinesConfs['1'] or {}


-------------------------------------------------
-- WarsTimeModel

local WarsTimeModel = class('WarsTimeModel', BaseModel)

function WarsTimeModel:ctor()
    self.super.ctor(self, 'WarsTimeModel')
    
    self:initProperties_({
        {name = 'Index',     value = 0},  -- timeLine 索引位置
        {name = 'StepId',    value = UNION_WARS_STEPS.UNOPEN},  -- 工会战步骤id 
        {name = 'Duration',  value = 0},  -- 持续时间
        {name = 'StartTime', value = 0},  -- 开始时间戳
        {name = 'EndedTime', value = 0},  -- 结束时间戳
    })
end


-------------------------------------------------
-- UnionWarsModel
---@class UnionWarsModel : BaseModel
local UnionWarsModel = class('UnionWarsModel', BaseModel)

-- 工会战 参与人数 最少/最大
UnionWarsModel.ATTEND_MIN = checkint(unionWarsDefinesConf['minPlayerNumber'])
UnionWarsModel.ATTEND_MAX = checkint(unionWarsDefinesConf['maxPlayerNumber'])

-- 工会战 最大生命值
UnionWarsModel.SITE_HP_MAX = checkint(unionWarsDefinesConf['defense'])

-- 工会战 debuff列表
UnionWarsModel.DEBUFF_LIST = checktable(unionWarsDefinesConf['debuffId'])

-- 工会战 最大debuff数
UnionWarsModel.DEBUFF_MAX = checkint(unionWarsDefinesConf['MaxDebuffLevel'])

-- 工会战 奖励展示卡牌
UnionWarsModel.SHOW_CARD_ID = checkint(unionWarsDefinesConf['cardId'])

-- 工会战 bossId R/SR
UnionWarsModel.SHOW_BOSS_ID_R  = checkint(unionWarsDefinesConf['guildPetR'])
UnionWarsModel.SHOW_BOSS_ID_SR = checkint(unionWarsDefinesConf['guildPetSR'])

-- 工会战 boss据点定义
UnionWarsModel.BOSS_SITE_DEFINES = {
    {petId = UnionWarsModel.SHOW_BOSS_ID_R,  name = __('R级神兽')},
    {petId = UnionWarsModel.SHOW_BOSS_ID_SR, name = __('SR级神兽')},
}


function UnionWarsModel:ctor()
    self.super.ctor(self, 'UnionWarsModel')
    
    self:initProperties_({
        {name = 'WarsBaseTime',      value = 0,  isReadOnly = true},  -- 工会战 开启时间戳
        {name = 'WarsCloseTime',     value = 0,  isReadOnly = true},  -- 工会战 终止时间戳
        {name = 'TimeLineIndex',     value = 0,  event = SGL.UNION_WARS_TIME_LINE_INDEX_CHANGE},  -- 时间线 当前位置
        {name = 'TimeLineModels',    value = {}, isReadOnly = true},  -- 时间线 模型列表 （类型 WarsTimeModel）
        {name = 'TimeLineLeftTime',  value = -1, isReadOnly = true},  -- 当前时间线 剩余时间

        {name = 'DeadCardsMap',      value = {}},  -- 死亡队伍 （key，value 都是卡牌uuid）
        {name = 'DefendCards',       value = ''},  -- 当前的 防御队伍
        {name = 'PastDefendCards',   value = ''},  -- 之前的 防御队伍
        {name = 'LeftAttachNum',     value = 0},   -- 剩余 挑战次数
        {name = 'TotalAttachNum',    value = 0},   -- 总共 挑战次数
        {name = 'PastWarsResult',    value = nil}, -- 之前的工会战结果
        {name = 'PassedBuildingMap', value = {}, isReadOnly = true},   -- 自己打通的建筑id map（key：buildingId，value：buildingId）
        {name = 'UnionMapModel',     value = nil, event = SGL.UNION_WARS_UNION_MAP_MODEL_CHANGE}, -- 己方 公会战地图模型 （类型 WarsMapModel）
        {name = 'EnemyMapModel',     value = nil, event = SGL.UNION_WARS_ENEMY_MAP_MODEL_CHANGE}, -- 敌方 公会战地图模型 （类型 WarsMapModel）

        {name = 'WatchEnemyMap',     value = false, event = SGL.UNION_WARS_WATCH_MAP_CAMP_CHANGE},  -- 是否 处于敌方地图
        {name = 'MapPageIndex',      value = 1,     event = SGL.UNION_WARS_WATCH_MAP_PAGE_CHANGE},  -- 所处于的地图页数
        {name = 'JoinMember',        value = false},  -- 是否为参战成员
    })
end


function UnionWarsModel:setWarsBaseTime(baseTime)
    -- update WarsBaseTime
    self.WarsBaseTime_   = checkint(baseTime)
    self.WarsCloseTime_  = checkint(baseTime)
    self.TimeLineModels_ = {}

    -- logInfo.add(5, 'self.WarsBaseTime_ >> ' .. tostring(self.WarsBaseTime_))
    if self:getWarsBaseTime() > 0 then

        -- update TimeLineModels
        local stepStartTime = self.getWarsBaseTime()
        local timeStepNums  = table.nums(unionWarsTimeLineConfs)
        for i = 1, timeStepNums do
            local timeConf  = unionWarsTimeLineConfs[tostring(i)] or {}
            local timeModel = WarsTimeModel.new()
            timeModel:setIndex(i)
            timeModel:setStepId(checkint(timeConf.type))
            timeModel:setDuration(checkint(timeConf.seconds))
            timeModel:setStartTime(stepStartTime)
            timeModel:setEndedTime(stepStartTime + timeModel:getDuration())
            stepStartTime = timeModel:getEndedTime()
            table.insert(self.TimeLineModels_, timeModel)
            -- logInfo.add(5, string.fmt('init %1 ) %2', i, stepStartTime))
        end

        -- update WarsCloseTime
        local lastTimeModel = self:getWarsTimeModel(timeStepNums)
        self.WarsCloseTime_ = lastTimeModel and lastTimeModel:getEndedTime() or stepStartTime
    end

    -- update TimeLineIndex 
    self:syncTimeLineIndex()
end


function UnionWarsModel:getWarsTimeModel(timeLineIndex)
    return self:getTimeLineModels()[timeLineIndex]
end


function UnionWarsModel:getWarsTimeLineIndex(serverTime)
    local warsTimeLineIndex  = 0
    local currentServerTime  = checkint(serverTime)
    for i, timeModel in ipairs(self:getTimeLineModels()) do
        if currentServerTime >= timeModel:getStartTime() and currentServerTime < timeModel:getEndedTime() then
            warsTimeLineIndex = timeModel:getIndex()
            break
        end
    end
    return warsTimeLineIndex
end


function UnionWarsModel:syncTimeLineIndex()
    self:setTimeLineIndex(self:getWarsTimeLineIndex(getServerTime()))
    self:syncTimeLineLeftTime()
end


function UnionWarsModel:syncTimeLineLeftTime()
    local currentTimeModel   = self:getWarsTimeModel(self:getTimeLineIndex())
    local currentServerTime  = getServerTime()
    local timeLineLeftTime   = 0
    if currentTimeModel then
        timeLineLeftTime = currentTimeModel:getEndedTime() - currentServerTime
    else
        if self:getWarsBaseTime() == 0 then
            timeLineLeftTime = -1
        elseif currentServerTime < self:getWarsBaseTime() then
            timeLineLeftTime = self:getWarsBaseTime() - currentServerTime
        elseif currentServerTime > self:getWarsCloseTime() then
            timeLineLeftTime = self:getWarsCloseTime() - currentServerTime
        end
    end
    self.TimeLineLeftTime_ = timeLineLeftTime
end


function UnionWarsModel:getWarsStepId()
    local currentTimeModel = self:getWarsTimeModel(self:getTimeLineIndex())
    return currentTimeModel and currentTimeModel:getStepId() or UNION_WARS_STEPS.UNOPEN
end


-- about defend card
function UnionWarsModel:getDefendCardList()
    return string.split2(checkstr(self:getDefendCards()), ',')
end
function UnionWarsModel:hasDefendCards()
    return #self:getDefendCardList() > 0
end


function UnionWarsModel:getPastDefendCardList()
    return string.split2(checkstr(self:getPastDefendCards()), ',')
end
function UnionWarsModel:hasPastDefendCards()
    return #self:getPastDefendCardList() > 0
end


-- about dead card
function UnionWarsModel:addDeadCard(cardUuid)
    if checkint(cardUuid) > 0 then
        self:getDeadCardsMap()[tostring(cardUuid)] = checkint(cardUuid)
    end
end
function UnionWarsModel:addDeadCards(cards)
    for i, cardUuid in ipairs(string.split2(cards, ',')) do
        self:addDeadCard(cardUuid)
    end
end
function UnionWarsModel:getDeadCardList()
    return table.values(self:getDeadCardsMap())
end
function UnionWarsModel:cleanDeadCards()
    self.DeadCardsMap_ = {}
end


function UnionWarsModel:isAppliedUnionWars()
    local hasUnionMember = self:getUnionMapModel() and not self:getUnionMapModel():isEmptyMapSiteMap() or false
    local hasEnemyMember = self:getEnemyMapModel() and not self:getEnemyMapModel():isEmptyMapSiteMap() or false
    return hasUnionMember or hasEnemyMember
end


function UnionWarsModel:setPassedBuildings(buildings)
    self.PassedBuildingMap_ = {}
    for _, buildingId in ipairs(string.split2(checkstr(buildings), ',')) do
        self.PassedBuildingMap_[tostring(buildingId)] = checkint(buildingId)
    end
end
function UnionWarsModel:isPassedBuilding(siteId)
    local passedBuildingMap = self:getPassedBuildingMap() or {}
    return passedBuildingMap[tostring(siteId)] ~= nil
end


-------------------------------------------------
-- WarsMapModel

---@class WarsMapModel : BaseModel
local WarsMapModel = class('WarsMapModel', BaseModel)


function WarsMapModel:ctor()
    self.super.ctor(self, 'WarsMapModel')
    
    self:initProperties_({
        {name = 'UnionName',         value = 0}, -- 公会名字
        {name = 'UnionAvatar',       value = 0}, -- 公会头像
        {name = 'UnionLevel',        value = 0}, -- 公会等级
        {name = 'WarsBossRQuestId',  value = 0}, -- R级 boss关卡id
        {name = 'WarsBossSRQuestId', value = 0}, -- SR级别 boss关卡id
        {name = 'WarsBossRLevel', value = 0},    -- R级别 boss的等级
        {name = 'WarsBossSRLevel', value = 0},   -- SR级别 boss的等级
        {name = 'MapSiteModelMap',   value = {}}, -- 地图建筑模型map（key：siteId，value：WarsSiteModel）
    })
end


-- about siteModel
function WarsMapModel:setMapSiteModel(siteId, siteModel)
    self:getMapSiteModelMap()[tostring(siteId)] = siteModel
end
function WarsMapModel:getMapSiteModel(siteId)
    return self:getMapSiteModelMap()[tostring(siteId)]
end


function WarsMapModel:isEmptyMapSiteMap()
    return next(self:getMapSiteModelMap()) == nil
end


-------------------------------------------------
-- WarsSiteModel

---@class WarsSiteModel : BaseModel
local WarsSiteModel = class('WarsSiteModel', BaseModel)

WarsSiteModel.DEFEND_STATE_OFF = 0
WarsSiteModel.DEFEND_STATE_ON  = 1


function WarsSiteModel:ctor()
    self.super.ctor(self, 'WarsSiteModel')
    
    self:initProperties_({
        {name = 'BuildingId',        value = 0},  -- 建筑id
        {name = 'PlayerId',          value = 0},  -- 玩家id
        {name = 'PlayerLevel',       value = 0},  -- 玩家等级
        {name = 'PlayerName',        value = 0},  -- 玩家名字
        {name = 'PlayerAvatar',      value = 0},  -- 玩家头像
        {name = 'PlayerAvatarFrame', value = 0},  -- 玩家头像框
        {name = 'PlayerCards',       value = {}},  -- 玩家卡牌阵容
        {name = 'PlayerHP',          value = 0},  -- 玩家生命值
        {name = 'DefendDebuff',      value = 0},  -- 防御debuff数量
        {name = 'DefendState',       value = WarsSiteModel.DEFEND_STATE_OFF},  -- 是否被攻击（0:正常，1:被攻击）
    })
end


function WarsSiteModel:isDead()
    return checkint(self:getPlayerHP()) <= 0
end


function WarsSiteModel:isDefending()
    return checkint(self:getDefendState()) == WarsSiteModel.DEFEND_STATE_ON
end


function WarsSiteModel:getDebuffId()
    local debuffCount = checkint(self:getDefendDebuff())
    return UnionWarsModel.DEBUFF_LIST[debuffCount]
end


function WarsSiteModel:dumpPlayerData()
    return {
        playerId          = self:getPlayerId(),          --  玩家ID
        playerLevel       = self:getPlayerLevel(),       --  玩家等级
        playerName        = self:getPlayerName(),        --  玩家名称
        playerAvatar      = self:getPlayerAvatar(),      --  玩家头像
        playerAvatarFrame = self:getPlayerAvatarFrame(), --  玩家头像边框
        playerCards       = self:getPlayerCards(),       --  玩家出战卡牌
    }
end


-------------------------------------------------
-- model factory

local UnionWarsModelFactory = {
    UnionWarsModel = UnionWarsModel,
    WarsTimeModel  = WarsTimeModel,
    WarsMapModel   = WarsMapModel,
    WarsSiteModel  = WarsSiteModel,
}

return UnionWarsModelFactory
