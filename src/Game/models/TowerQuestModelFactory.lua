--[[
 * author : kaishiqi
 * descpt : 爬塔副本数据模型工厂
]]
local BaseModel = require('Game.models.BaseModel')


-------------------------------------------------
-- TowerQuestModel

local TowerQuestModel = class('TowerQuestModel', BaseModel)

TowerQuestModel.UNIT_PATH_NUM    = 5  -- 单元的路径点数
TowerQuestModel.LIBRARY_CARD_MIN = 5  -- 最小卡库卡牌数
TowerQuestModel.LIBRARY_CARD_MAX = 10 -- 最大卡库卡牌数
TowerQuestModel.BATTLE_CARD_MIN  = 1  -- 最小出战卡牌数
TowerQuestModel.BATTLE_CARD_MAX  = 5  -- 最大出战卡牌数
TowerQuestModel.BATTLE_SKILL_MAX = 2  -- 最大出站主角技


function TowerQuestModel:ctor()
    self.super.ctor(self, 'TowerQuestModel')

    self:initProperties_({
        {name = 'HistoryMaxFloor',   value = 0, event = SGL.TOWER_QUEST_MODEL_HISTORY_MAX_FLOOR_CHANGE},  -- 历史最高层数
        {name = 'CurrentFloor',      value = 0, event = SGL.TOWER_QUEST_MODEL_CURRENT_FLOOR_CHANGE},  -- 当前所在层数
        {name = 'CardLibrary',       value = {}, event = SGL.TOWER_QUEST_MODEL_CARD_LIBRARY_CHANGE},  -- 卡牌库（card id list）
        {name = 'EnterLeftTimes',    value = 0, event = SGL.TOWER_QUEST_MODEL_ENTER_LEFT_TIMES_CHANGE},  -- 爬塔剩余次数
        {name = 'ReviveTimes',       value = 0},  -- 已经复活次数
        {name = 'ReviveLimit',       value = 0},  -- 最大复活次数
        {name = 'TowerEntered',      value = false, event = SGL.TOWER_QUEST_MODEL_TOWER_ENTERED_CHANGE, isForced = true},  -- 是否 已进入爬塔
        {name = 'UnitReadied',       value = false, event = SGL.TOWER_QUEST_MODEL_UNIT_READIED_CHANGE},  -- 是否 已单元准备
        {name = 'UnitPassed',        value = false, event = SGL.TOWER_QUEST_MODEL_UNIT_PASSED_CHANGE},  -- 是否 已单元通关
        {name = 'UnitDefineModel',   value = nil, event = SGL.TOWER_QUEST_MODEL_UNIT_DEFINE_CHANGE},  -- 单元定义模型
        {name = 'UnitConfigModel',   value = nil, event = SGL.TOWER_QUEST_MODEL_UNIT_CONFIG_CHANGE},  -- 单元设置模型
        {name = 'UnconfirmedConfig', value = true},  -- 是否 未确认单元配置
        {name = 'SeasonId',          value = 0},  -- 赛季id
        {name = 'SweepFloor',        value = 0},  -- 扫荡层数
        {name = 'TeamCustomId',      value = 0},  -- 预设编队id
    })
end


function TowerQuestModel:cacheCardLibraryKey()
    return string.format('LOCAL_TOWER_CARD_LIBRARY_%d', checkint(app.gameMgr:GetUserInfo().playerId))
end
function TowerQuestModel:getCacheCardLibrary()
    return cc.UserDefault:getInstance():getStringForKey(self:cacheCardLibraryKey(), '')
end
function TowerQuestModel:setCacheCardLibrary(teamCards)
    cc.UserDefault:getInstance():setStringForKey(self:cacheCardLibraryKey(), checkstr(teamCards))
    cc.UserDefault:getInstance():flush()
end


-------------------------------------------------
-- UnitDefineModel

local UnitDefineModel = class('UnitDefineModel', BaseModel)

function UnitDefineModel:ctor()
    self.super.ctor(self, 'UnitDefineModel')

    self:initProperties_({
        {name = 'UnitId',          value = 0},  -- 单元id
        {name = 'ContractIdList',  value = {}}, -- 契约id列表
        {name = 'ChestRewardsMap', value = {}}, -- 宝箱奖励map信息（key:chestId, value:goodsList）
    })
end


-------------------------------------------------
-- UnitConfigModel

local UnitConfigModel = class('UnitConfigModel', BaseModel)

function UnitConfigModel:ctor()
    self.super.ctor(self, 'UnitConfigModel')

    self:initProperties_({
        {name = 'CardIdList',             value = {}}, -- 卡牌id列表
        {name = 'SkillIdList',            value = {}}, -- 主角技id列表
        {name = 'ContractSelectedIdList', value = {}}, -- 契约选择id列表
    })
end


-------------------------------------------------
-- UnitContractModel

local UnitContractModel = class('UnitContractModel', BaseModel)

UnitContractModel.TYPE_DIFF   = 1  -- 难度类型
UnitContractModel.TYPE_CARD   = 2  -- 卡牌类型
UnitContractModel.TYPE_TIME   = 3  -- 时间类型
UnitContractModel.TYPE_TALENT = 4  -- 天赋类型
UnitContractModel.TYPE_REVIVE = 5  -- 复活类型

UnitContractModel.ID_DIFF_UP_10      = 1   -- 难度系数上升10%
UnitContractModel.ID_DIFF_UP_20      = 2   -- 难度系数上升20%
UnitContractModel.ID_DIFF_UP_30      = 3   -- 难度系数上升30%
UnitContractModel.ID_CARD_DONT_DEF   = 4   -- 卡牌禁用防御类型
UnitContractModel.ID_CARD_DONT_ATK   = 5   -- 卡牌禁用力量类型
UnitContractModel.ID_CARD_DONT_MAG   = 6   -- 卡牌禁用魔法类型
UnitContractModel.ID_CARD_DONT_SUP   = 7   -- 卡牌禁用辅助类型
UnitContractModel.ID_TIME_SUB_30     = 8   -- 战斗时间缩短30%
UnitContractModel.ID_TIME_SUB_40     = 9   -- 战斗时间缩短40%
UnitContractModel.ID_TIME_SUB_50     = 10  -- 战斗时间缩短50%
UnitContractModel.ID_TALENT_DONT_DAM = 11  -- 天赋禁用伤害类型
UnitContractModel.ID_TALENT_DONT_SUP = 12  -- 天赋禁用辅助类型
UnitContractModel.ID_TALENT_DONT_CON = 13  -- 天赋禁用控制类型
UnitContractModel.ID_REVIVE_DISABLED = 14  -- 禁用战斗中复活

function UnitContractModel:ctor()
    self.super.ctor(self, 'UnitContractModel')
end


-------------------------------------------------
-- model factory

local TowerQuestModelFactory = {}

TowerQuestModelFactory.typeMap_ = {
    ['TowerQuest']   = TowerQuestModel,
    ['UnitDefine']   = UnitDefineModel,
    ['UnitConfig']   = UnitConfigModel,
    ['UnitContract'] = UnitContractModel,
}

TowerQuestModelFactory.getModelType = function(type)
    return TowerQuestModelFactory.typeMap_[type]
end

return TowerQuestModelFactory
