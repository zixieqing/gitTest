--[[
 * author : kaishiqi
 * descpt : 工会派对数据模型工厂
]]
local UnionConfigParser = require('Game.Datas.Parser.UnionConfigParser')
local BaseModel         = require('Game.models.BaseModel')


-------------------------------------------------
-- UnionPartyModel

local UnionPartyModel = class('UnionPartyModel', BaseModel)

function UnionPartyModel:ctor()
    self.super.ctor(self, 'UnionPartyModel')
    
    self:initProperties_({
        {name = 'PartyLevel',        value = 0},   -- 派对等级
        {name = 'UnionLevel',        value = 0},   -- 派对开启时的工会等级
        {name = 'FoodGradeMap',      value = {}},  -- 食物等级map（key: foodId, value: grade）
        {name = 'FoodScoreMap',      value = {}},  -- 食物得分map（key: stepId, value: foodNum）
        {name = 'GoldScoreMap',      value = {}},  -- 金币得分map（key: stepId, value: goldNum）
        {name = 'BossQuestMap',      value = {}},  -- 堕神任务map（key: stepId, value: questId）
        {name = 'BossResultMap',     value = {}},  -- 堕神结果map（key: stepId, value: killNum）
        {name = 'SelfPassedMap',     value = {}},  -- 自己通关map（key: stepId, value: 0-unPassed, 1-passed）
        {name = 'FoodGradeSyncMap',  value = {}},  -- 食物得分是否同步map（key: stepId, value: isSync）
        {name = 'BossResultSyncMap', value = {}},  -- 堕神结果是否同步map（key: stepId, value: isSync）
        {name = 'TempPlayerGold',    value = 0},   -- 掉菜前临时记录的玩家金币（一开始开发时为金币，实际最后改为工会币）
    })
end


-- food score
function UnionPartyModel:getFoodScore(stepId)
    return checkint(self:getFoodScoreMap()[tostring(stepId)])
end
function UnionPartyModel:setFoodScore(stepId, score)
    self:getFoodScoreMap()[tostring(stepId)] = checkint(score)
    self:dispatchEvent_(SGL.UNION_PARTY_MODEL_FOOD_SCORE_CHANGE, {stepId = checkint(stepId), score = checkint(score)})
end
function UnionPartyModel:addFoodScore(stepId, score)
    self:setFoodScore(stepId, self:getFoodScore(stepId) + score)
end


-- gold score
function UnionPartyModel:getGoldScore(stepId)
    return checkint(self:getGoldScoreMap()[tostring(stepId)])
end
function UnionPartyModel:setGoldScore(stepId, score)
    self:getGoldScoreMap()[tostring(stepId)] = checkint(score)
    self:dispatchEvent_(SGL.UNION_PARTY_MODEL_GOLD_SCORE_CHANGE, {stepId = checkint(stepId), score = checkint(score)})
end
function UnionPartyModel:addGoldScore(stepId, score)
    self:setGoldScore(stepId, self:getGoldScore(stepId) + score)
end


-- get/set) foodGrade sync
function UnionPartyModel:isFoodGradeSync(stepId)
    local isFoodGradeSync = self:getFoodGradeSyncMap()[tostring(stepId)]
    return isFoodGradeSync == nil or isFoodGradeSync == true
end
function UnionPartyModel:setFoodGradeSync(stepId, isSync)
    self:getFoodGradeSyncMap()[tostring(stepId)] = isSync == true
    self:dispatchEvent_(SGL.UNION_PARTY_MODEL_FOOD_GRADE_SYNC_CHANGE, {stepId = checkint(stepId), isSync = isSync == true})
end


-- get) boss questId
function UnionPartyModel:getBossQuestId(stepId)
    return checkint(self:getBossQuestMap()[tostring(stepId)])
end


-- get) boss killTarget
function UnionPartyModel:getBossKillTarget()
    local unionLevelConf = CommonUtils.GetConfigNoParser('union', UnionConfigParser.TYPE.LEVEL, self:getUnionLevel()) or {}
    return checkint(unionLevelConf.killNum)
end


-- get/set) boss killNum
function UnionPartyModel:getBossKillNum(stepId)
    return checkint(self:getBossResultMap()[tostring(stepId)])
end
function UnionPartyModel:setBossKillNum(stepId, killNum)
    self:getBossResultMap()[tostring(stepId)] = checkint(killNum)
    self:dispatchEvent_(SGL.UNION_PARTY_MODEL_BOSS_KILL_CHANGE, {stepId = checkint(stepId), killNum = checkint(killNum)})
end


-- is) pass bossQuest
function UnionPartyModel:isPassBossQuest(questStepId)
    return self:getBossKillNum(questStepId) >= self:getBossKillTarget()
end


-- get/set) bossResult sync
function UnionPartyModel:isBossResultSync(stepId)
    return self:getBossResultSyncMap()[tostring(stepId)] == true
end
function UnionPartyModel:setBossResultSync(stepId, isSync)
    self:getBossResultSyncMap()[tostring(stepId)] = isSync == true
end


-- is/set) self passedBoss
function UnionPartyModel:isSelfPassedBoss(stepId)
    return checkint(self:getSelfPassedMap()[tostring(stepId)]) == 1
end
function UnionPartyModel:setSelfPassedBoss(stepId, passedStatus)
    self:getSelfPassedMap()[tostring(stepId)] = checkint(passedStatus)
    self:dispatchEvent_(SGL.UNION_PARTY_MODEL_SELF_PASSED_CHANGE, {stepId = checkint(stepId), killNum = checkint(passedStatus)})
end


-------------------------------------------------
-- model factory

local UnionPartyModelFactory = {}

UnionPartyModelFactory.typeMap_ = {
    ['UnionParty'] = UnionPartyModel,
}

UnionPartyModelFactory.getModelType = function(type)
    return UnionPartyModelFactory.typeMap_[type]
end

return UnionPartyModelFactory
