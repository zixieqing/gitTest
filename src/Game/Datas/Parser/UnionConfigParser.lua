--[[
 * author : kaishiqi
 * descpt : 爬塔相关 - 配表解析器
]]
local AbstractBaseParser = require('Game.Datas.Parser')
---@class UnionConfigParser : AbstractBaseParser
local UnionConfigParser  = class('UnionConfigParser', AbstractBaseParser)

UnionConfigParser.NAME = 'UnionConfigParser'
UnionConfigParser.TYPE = {
	CONTRIBUTION        = 'contribution',
	GODBEAST            = 'godBeast',
	GODBEASTATTR        = 'godBeastAttr',
	GODBEASTLEVEL       = 'godBeastLevel',
	GODBEASTSKILL       = 'godBeastSkill',
	GODBEASTSKILLEFFECT = 'godBeastSkillEffect',
	GODBEASTSKILLLEVEL  = 'godBeastSkillLevel',
	GODBEASTFORM        = 'godBeastForm',
	GODBEASTQUEST       = 'godBeastQuest',
	GODBEASTQUESTGROUP  = 'godBeastQuestGroup',
	GLOBAL_BUFF         = 'godBeastSkillType',
	JOB                 = 'job',
	LEVEL               = 'level',
	MALL                = 'mall',
	BUILD               = 'build',
	TASK                = 'task',
	AVATAR              = 'avatar',
	ROOM                = 'room',
	ENTRANCE            = 'entrance',
	PETENERGYLEVEL      = 'petEnergyLevel',
	PETSATIETYLEVEL     = 'petSatietyLevel',
	PETFEED             = 'petFeed',
	PETVOICE            = 'petVoice',
	GODBEASTGROW        = 'godBeastGrow',
	GBBUYLIVECONSUME    = 'godBeastBuyLiveConsume',
	PARTY_TIME_LINE     = 'partyTimeLine',
	PARTY_SIZE          = 'partySize',
	PARTY_STORY         = 'partyStory',
	PARTY_QUEST         = 'partyQuest',
	PARTY_QUEST_ENEMY   = 'partyQuestEnemy',
	PARTY_QUEST_ATTR    = 'partyQuestCoefficient',
	PARTY_FOOD_GOLD     = 'partyChopFoodGold',
	WARS_TIME_LINE      = 'warsTime',
	WARS_SITE_INFO      = 'warsCoordinates',
	WARS_REWARDS        = 'warsRewards',
	WARS_DEFINES        = 'warsParam',
	WARS_BOSS_LIMIT     = 'warsLimit',
	WARS_BOSS_QUEST     = 'warsBeastQuest',
	WARS_BOSS_DIFF_ATTR = 'warsCoefficient',
}

function UnionConfigParser:ctor()
	self.super.ctor(self, table.values(UnionConfigParser.TYPE))
end


return UnionConfigParser
