--[[
 * descpt :杀人案（19夏活） - 配表解析器
]]
local AbstractBaseParser = require('Game.Datas.Parser')
local MurderConfigParser  = class('MurderConfigParser', AbstractBaseParser)

MurderConfigParser.NAME = 'MurderConfigParser'
MurderConfigParser.TYPE = {
	BOSS_SCHEDULE           = 'bossSchedule',
	BRANCH_STORY_COLLECTION = 'branchStoryCollection',
	BUILD 					= 'build',
	BUILDING 				= 'building',
	CARD_ADDITION	        = 'cardAddition',
	CARD_SKILL 				= 'cardSkill',
	DAMAGE_ACCUMULATIVE 	= 'damageAccumulative',
	DAMAGE_RANK_REWARDS 	= 'demageRankRewards',
	DROP_ADDITION 			= 'dropAddition',
	MAIN_STORY_COLLECTION   = 'mainStoryCollection',
	MATERIAL_SCHEDULE	    = 'materialSchedule',
	MODULE_UNLOCK		    = 'moduleUnlock',
	OVER_TIME_REWARD	    = 'overTimeReward',
	QUEST 				    = 'quest',
	REWARD_BASE			    = 'rewardBase',
	REWARD_POOL			    = 'rewardPool',
	SHOP 					= 'shop',
	STORY 				    = 'story',
	STORY_DAMAGE_POINT 	    = 'storyDamagePoint',
	PARAM 	 	 	 	    = 'param',
	PUZZLE 	 	 	 	    = 'puzzle',
}

function MurderConfigParser:ctor()
	self.super.ctor(self, table.values(MurderConfigParser.TYPE))
end


return MurderConfigParser
