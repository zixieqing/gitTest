--[[
 * author : kaishiqi
 * descpt : 打牌游戏相关 - 配表解析器
]]
local AbstractBaseParser     = require('Game.Datas.Parser')
local BattleCardConfigParser = class('BattleCardConfigParser', AbstractBaseParser)

BattleCardConfigParser.NAME = 'BattleCardConfigParser'

BattleCardConfigParser.SUB = 'battleCard'

BattleCardConfigParser.TYPE = {
    CARD_INIT   = 'init',      -- 初始卡牌及卡组表.xlsx
    CARD_PACK   = 'cardPack',  -- 卡包概率信息表.xlsx
    CARD_CAMP   = 'camp',      -- 战牌同盟类型表.xlsx
    CARD_DEFINE = 'card',      -- 提尔拉战牌基本表.xlsx
    DECK_LIMIT  = 'teamLimit', -- 卡组等级表.xlsx
    CARD_ALBUM  = 'collect',   -- 收集手册表.xlsx
    NPC_DEFINE  = 'npc',       -- NPC关卡表.xlsx
    RULE_DEFINE = 'rule',      -- 流行规则表.xlsx
    RULE_TYPE   = 'ruleType',  -- 流行规则类型表.xlsx
    CHAT_MOOD   = 'message',   -- 定型文表.xlsx
    SCHEDULE    = 'schedule',  -- 活动排期与内容表.xlsx
    ACTIVITY    = 'summary',   -- 战牌活动总表.xlsx
    -- = 'robot', -- PVP机器人表.xlsx
    -- = 'group', -- 匹配分组表.xlsx
    -- 匹配规则系数表.xlsx
    -- 战牌商城表.xlsx
}


function BattleCardConfigParser:ctor()
	self.super.ctor(self, table.values(BattleCardConfigParser.TYPE))
end


return BattleCardConfigParser
