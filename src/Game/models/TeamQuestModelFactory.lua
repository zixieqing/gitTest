--[[
 * author : kaishiqi
 * descpt : 组队副本数据模型工厂
]]
local BaseModel = require('Game.models.BaseModel')


-------------------------------------------------
-- TeamQuestModel

local TeamQuestModel = class('TeamQuestModel', BaseModel)

TeamQuestModel.PLAYER_MAX       = 2
TeamQuestModel.BUY_TIME_CONSUME = 30


function TeamQuestModel:ctor()
    self.super.ctor(self, 'TeamQuestModel')

    self:initProperties_({
        {name = 'TeamId',         value = 0},  -- 队伍id
        {name = 'QuestTypeId',    value = 0,}, -- 副本类型
        {name = 'Password',       value = ''}, -- 队伍密码
        {name = 'CaptainId',      value = 0},  -- 队长id
        {name = 'TeamBossId',     value = 0},  -- boss id
        {name = 'PlayerModelMap', value = {}},  -- 玩家数据map（key 位置，value PlayerModel）
        {name = 'CardModelMap',   value = {}},  -- 卡牌数据map (key 位置 value CardModel)
        {name = 'CaptainSkills',  value = {}, event = SIGNALNAMES.TEAM_BOSS_MODEL_CAPTAIN_SKILL_CHANGE},  -- 队长技能
        {name = 'RandomSeed',     value = 0},  -- 随机数种子
        {name = 'RandomConfig',   value = nil},-- 随机数配置
        {name = 'LeftBuyTimes',   value = 0},  -- 剩余购买次数
        {name = 'BossRareReward', value = {}}  -- 关卡稀有掉落获得信息
    })
end


function TeamQuestModel:isEmptyTeam()
    return #table.keys(self:getPlayerModelMap()) <= 0
end
function TeamQuestModel:isFullTeam()
    return #table.keys(self:getPlayerModelMap()) >= TeamQuestModel.PLAYER_MAX
end


---------------------------------------------------
-- player data begin --
---------------------------------------------------
function TeamQuestModel:addPlayerModel(pos, teamPlayerModel)
    self:getPlayerModelMap()[tostring(pos)] = teamPlayerModel
    self:dispatchEvent_(SIGNALNAMES.TEAM_BOSS_MODEL_PLAYER_ADD_CHANGE, {pos = checkint(pos)})
end
function TeamQuestModel:hasPlayerModel(pos)
    return self:getPlayerModel(pos) ~= nil
end
function TeamQuestModel:getPlayerModel(pos)
    return self:getPlayerModelMap()[tostring(pos)]
end
function TeamQuestModel:removePlayerModel(pos)
    self:getPlayerModelMap()[tostring(pos)] = nil
    self:dispatchEvent_(SIGNALNAMES.TEAM_BOSS_MODEL_PLAYER_REMOVE_CHANGE, {pos = checkint(pos)})
end
function TeamQuestModel:releasePlayerModel(pos)
    self:getPlayerModelMap()[tostring(pos)] = nil
    self:dispatchEvent_(SIGNALNAMES.TEAM_BOSS_MODEL_PLAYER_RELEASE_CHANGE)
end


function TeamQuestModel:getPlayerPosById(playerId)
    local playerPos = 0
    for pos, model in pairs(self:getPlayerModelMap()) do
        if model:getPlayerId() == checkint(playerId) then
            playerPos = checkint(pos)
            break
        end
    end
    return playerPos
end


function TeamQuestModel:switchCaptain(playerId)
    if self:getCaptainId() == checkint(playerId) then return end
    self:setCaptainId(checkint(playerId))
    
    if self:hasPlayerModel(1) then
        -- switch players pos
        local newCaptainPos   = self:getPlayerPosById(playerId)
        local newCaptainModel = self:getPlayerModel(newCaptainPos)
        local oldCaptainModel = self:getPlayerModel(1)
        self:getPlayerModelMap()[tostring(newCaptainPos)] = oldCaptainModel
        self:getPlayerModelMap()[tostring(1)] = newCaptainModel
        
        self:dispatchEvent_(SIGNALNAMES.TEAM_BOSS_MODEL_CAPTAIN_CHANGE, {newValue = 1, oldValue = newCaptainPos})

    else
        -- to captain pos
        local playerPos   = self:getPlayerPosById(playerId)
        local playerModel = self:getPlayerModel(playerPos)
        self:getPlayerModelMap()[tostring(1)] = playerModel
        self:getPlayerModelMap()[tostring(playerPos)] = nil

        self:dispatchEvent_(SIGNALNAMES.TEAM_BOSS_MODEL_CAPTAIN_CHANGE, {newValue = 1, oldValue = playerPos})
    end
end
---------------------------------------------------
-- player data end --
---------------------------------------------------

---------------------------------------------------
-- card data begin --
---------------------------------------------------
--[[
添加一个卡牌
@params pos int 卡牌位置
@params teamCardModel TeamCardModel 卡牌数据实例
--]]
function TeamQuestModel:addCardModel(pos, teamCardModel)
    self:getCardModelMap()[tostring(pos)] = teamCardModel
end
--[[
是否拥有卡牌实例
@params pos int 卡牌位置
--]]
function TeamQuestModel:hasCardModel(pos)
    return self:getCardModel(pos) ~= nil
end
--[[
根据卡牌位置获取卡牌model
@params pos int 卡牌位置
@return _ TeamCardModel 卡牌实例
--]]
function TeamQuestModel:getCardModel(pos)
    return self:getCardModelMap()[tostring(pos)]
end
--[[
移除一个卡牌实例
--]]
function TeamQuestModel:removeCardModel(pos)
    self:getCardModelMap()[tostring(pos)] = nil
end
--[[
释放一个卡牌实例
--]]
function TeamQuestModel:releaseCardModel(pos)
    self:getCardModelMap()[tostring(pos)] = nil
end
--[[
根据本玩家卡牌id获取卡牌位置
@params id int 卡牌id
--]]
function TeamQuestModel:getSelfCardModelByPlayerCardId(id)
    for pos, cardModel in pairs(self:getCardModelMap()) do
        if not cardModel:isCardEmpty() then
            if id == cardModel:getPlayerCardId() then
                return cardModel
            end
        end
    end
    return nil
end
--[[
根据其他玩家的玩家id 卡牌id获取卡牌位置
@params playerId int 玩家id
@params cardId int 卡牌id
--]]
function TeamQuestModel:getCardModelByPlayerIdAndCardId(playerId, cardId)
    local cardModel = nil
    if 0 == cardId then
        return cardModel
    end
    for pos, cardModel_ in pairs(self:getCardModelMap()) do
        if cardId == cardModel_:getCardId() and playerId == cardModel_:getPlayerId() then
            cardModel = cardModel_
            break
        end
    end
    return cardModel
end
--[[
根据玩家id获取该玩家在本场战斗中放置的卡牌位置集合
@params playerId int 玩家id
@return result list 卡牌位置集合
--]]
function TeamQuestModel:getCardsPosByPlayerId(id)
    local result = {}
    for pos, cardModel in pairs(self:getCardModelMap()) do
        if 0 ~= cardModel:getCardId() then
            if id == checkint(cardModel:getPlayerId()) then
                table.insert(result, pos)
            end
        end
    end
    return result
end
--[[
根据卡牌id和玩家id判断是否可以上阵对应的卡牌
@params cardId int 卡牌id
@return _ bool 是否已上阵
--]]
function TeamQuestModel:canAddCardByCardIdAndPlayerId(cardId, playerId)
    for pos, cardModel in pairs(self:getCardModelMap()) do
        if 0 ~= checkint(cardModel:getCardId()) then
            if cardId == checkint(cardModel:getCardId()) and playerId ~= checkint(cardModel:getPlayerId()) then
                return false
            end
        end
    end
    return true
end
---------------------------------------------------
-- card data end --
---------------------------------------------------

---------------------------------------------------
-- boss rare reward begin --
---------------------------------------------------
--[[
根据关卡id设置稀有掉落
@params stageId int 关卡id
@params got bool 是否获取了稀有掉落
--]]
function TeamQuestModel:setBossRareRewardByStageId(stageId, got)
    local stageConfig = CommonUtils.GetQuestConfig(stageId)
    local groupId = checkint(stageConfig.group)
    self:setBossRareRewardByGroupId(groupId, got)
end
--[[
根据关卡id获取是否得到稀有掉落
@params stageId int 关卡id
@return _ int 是否得到了稀有掉落
--]]
function TeamQuestModel:getBossRareRewardByStageId(stageId)
    local stageConfig = CommonUtils.GetQuestConfig(stageId)
    local groupId = checkint(stageConfig.group)
    return self:getBossRareRewardByGroupId(groupId)
end
--[[
根据组别id设置稀有掉落
@params groupId int 组别id
@params got bool 是否获取了稀有掉落
--]]
function TeamQuestModel:setBossRareRewardByGroupId(groupId, got)
    self:getBossRareReward()[tostring(groupId)] = got and 1 or 0
end
--[[
根据组别id获取是否得到稀有掉落
@params groupId int 组别id
@return got int 是否得到了稀有掉落
--]]
function TeamQuestModel:getBossRareRewardByGroupId(groupId)
    local got = 0
    if nil ~= self:getBossRareReward()[tostring(groupId)] then
        got = checkint(self:getBossRareReward()[tostring(groupId)])
    end
    return got
end
---------------------------------------------------
-- boss rare reward end --
---------------------------------------------------


-------------------------------------------------
-- TeamPlayerModel

local TeamPlayerModel = class('TeamPlayerModel', BaseModel)

TeamPlayerModel.STATUS_IDLE    = 1  -- 未准备
TeamPlayerModel.STATUS_READY   = 2  -- 已准备
TeamPlayerModel.STATUS_OFFLINE = 3  -- 离线

TeamPlayerModel.READY_EVENT_READY = 1 -- 准备
TeamPlayerModel.READY_EVENT_CANCEL = 0 -- 取消

function TeamPlayerModel:ctor()
    self.super.ctor(self, 'TeamPlayerModel')

    self:initProperties_({
        {name = 'PlayerId',          value = 0},   -- 玩家ID
        {name = 'Name',        value = ''},  -- 玩家名字
        {name = 'Level',       value = 0},   -- 玩家等级
        {name = 'Avatar',      value = ''},  -- 玩家头像
        {name = 'AvatarFrame', value = ''},  -- 玩家头像框
        {name = 'AttendTimes', value = 0},   -- 参与次数
        -- {name = 'Status',      value = 0, event = SIGNALNAMES.TEAM_BOSS_MODEL_PLAYER_STATUS_CHANGE},  -- 玩家状态 1:未准备, 2:已准备, 3:离线
        {name = 'Status',      value = 0},  -- 玩家状态 1:未准备, 2:已准备, 3:离线

    })
end

-------------------------------------------------
-- TeamCardModel

local TeamCardModel = class('TeamCardModel', BaseModel)

TeamCardModel.REMOVE_CARD_ID = 0

--[[
@override
constructor
--]]
function TeamCardModel:ctor()
    self.super.ctor(self, 'TeamCardModel')

    self:initProperties_({
        {name = 'PlayerId',         value = 0},     -- 所有者玩家id
        {name = 'PlayerCardId',     value = 0},     -- 卡牌数据库id
        {name = 'Place',            value = 0},     -- 卡牌位置
        {name = 'CardId',           value = 0},     -- 卡牌id 0表示卸下
        {name = 'CardSkinId',       value = 0},     -- 卡牌皮肤id
        {name = 'Level',            value = 0},     -- 卡牌等级
        {name = 'BreakLevel',       value = 0},     -- 卡牌星级
        {name = 'FavorLevel',       value = 0},     -- 卡牌好感度等级
        {name = 'CardNickname',     value = nil},   -- 卡牌昵称
        {name = 'CardSkill',        value = {}},    -- 卡牌技能信息
        {name = 'Pets',             value = {}},    -- 卡牌携带的堕神信息
        {name = 'ArtifactTalent',   value = {}},    -- 卡牌的神器信息
        {name = 'BookLevel',        value = 0},
        {name = 'EquippedHouseCatGene', value = nil},
    })

end
--[[
刷新卡牌数据
@params pos int 卡牌位置
@params cardData table 卡牌数据
--]]
function TeamCardModel:updateCardInfo(pos, cardData)
    local cardId = checkint(cardData.cardId)
    self:setCardId(cardId)
    if TeamCardModel.REMOVE_CARD_ID ~= cardId then
        self:setPlayerId(checkint(cardData.playerId))
        self:setPlace(checkint(pos))
        self:setCardSkinId(checkint(cardData.defaultSkinId or cardData.cardSkinId))
        self:setLevel(checkint(cardData.level or cardData.cardLevel))
        self:setBreakLevel(checkint(cardData.breakLevel))
        self:setFavorLevel(checkint(cardData.favorabilityLevel))
        self:setCardSkill(checktable(cardData.skill))
        self:setCardNickname(cardData.cardName)
        self:setPets(cardData.pets)
        self:setArtifactTalent(cardData.artifactTalent)
        self:setBookLevel(cardData.bookLevel)
        self:setEquippedHouseCatGene(cardData.equippedHouseCatGene)

        if nil ~= cardData.id then
            self:setPlayerCardId(checkint(cardData.id))
        end
    end

    self:dispatchEvent_(SIGNALNAMES.TEAM_BOSS_MODEL_PLAYER_CARD_CHANGE, {pos = self:getPlace()})
end
--[[
判断该卡位是否未空
--]]
function TeamCardModel:isCardEmpty()
    return TeamCardModel.REMOVE_CARD_ID == self:getCardId()
end


-------------------------------------------------
-- model factory

local TeamQuestModelFactory = {}

TeamQuestModelFactory.typeMap_ = {
    ['TeamQuest']  = TeamQuestModel,
    ['TeamPlayer'] = TeamPlayerModel,
    ['TeamCard']   = TeamCardModel,
}

TeamQuestModelFactory.getModelType = function(type)
    return TeamQuestModelFactory.typeMap_[type]
end

return TeamQuestModelFactory
