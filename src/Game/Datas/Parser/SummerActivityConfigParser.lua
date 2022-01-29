--[[
 * descpt : 夏活相关 - 配表解析器
]]
local AbstractBaseParser = require('Game.Datas.Parser')
---@class SummerActivityConfigParser
local SummerActivityConfigParser  = class('SummerActivityConfigParser', AbstractBaseParser)

SummerActivityConfigParser.NAME = 'SummerActivityConfigParser'
SummerActivityConfigParser.TYPE = {
    CHAPTER                   = 'chapter',
    DAMAGE_EXCHANGE_POINT     = 'damageExchangePoint',
    LOCATION                  = 'location',
    QUEST                     = 'quest',
	REWARD_POOL               = 'rewardPool',
	
	------------ rewards ------------
	------- 
    OVER_TIME_REWARD          = 'overTimeReward',
    DAMAGE_RANK_REWARDS       = 'damageRankRewards',
	SUMMER_POINT_RANK_REWARDS = 'summerPointRankRewards',
	QUEST_REWARDS             = 'questOverTimesRewards',
	------- 
	------------ rewards ------------

	------------ story ------------
	------- 
    MAIN_STORY_COLLECTION     = 'mainStoryCollection',
    BRANCH_STORY_COLLECTION   = 'branchStoryCollection',
    SUMMER_STORY              = 'summerStory',
	------- 
	------------ story ------------
}

function SummerActivityConfigParser:ctor()
	self.super.ctor(self, table.values(SummerActivityConfigParser.TYPE))
end




return SummerActivityConfigParser
