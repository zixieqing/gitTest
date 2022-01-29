--[[
活动副本配表解析器
--]]
local AbstractBaseParser = require('Game.Datas.Parser')
---@class Anniversary2ConfigParser : Parser
local Anniversary2ConfigParser  = class('Anniversary2ConfigParser', AbstractBaseParser)

Anniversary2ConfigParser.NAME = 'Anniversary2ConfigParser'

Anniversary2ConfigParser.TYPE = {
	EXPLORE             = "explore",
	BOSS                = "boss",
	QUEST               = "quest",
	CHAPTER             = "chapter",
	EXPLORE_CHEST       = "exploreChest",
	EXPLORE_BATTLE_CARD = "exploreBattleCard",
	EXPLORE_BOSS        = "exploreBoss",
	EXPLORE_MONSTER     = "exploreMonster",
	EXPLORE_ELITE_MONSTER= "exploreEliteMonster",
	EXPLORE_TIPS        = "exploreTips",
	SHOP                = "shop",
	REWARD_POOL         = "rewardPool",
	EXPLORE_OPTION      = "exploreOption",
	STORY               = "story",
	EXPLORE_STORY       = "exploreStory",
	CONSIGNATION        = "consignation",
	EXPLORE_AUGURY      = "exploreAugury",
	POINT               = "point",
	CARD_SKILL          = "cardSkill",
	CARD_ADDITION       = "cardAddition",
	PARAMETER           = "parameter",
	RANK_REWARDS        = "rankRewards",
	STORY_COLLECTION    = "storyCollection",
	REWARD_BASE         = "rewardBase",
	LOTTERY             = "lottery",
	LOTTERY_POOL        = "lotteryPool",
	LOTTERY_RATE        = "lotterryRate",
}

function Anniversary2ConfigParser:ctor()
	self.super.ctor(self, table.values(Anniversary2ConfigParser.TYPE) )
end

--[[
获取vo路径
@params name 配表名字
--]]
function Anniversary2ConfigParser:GetVoPath(name)
	local path = nil
	name = string.ucfirst(name)
	if not utils.isExistent(path) and name ~= 'Quest' then
		path = 'Game.Datas.Vo'
	else
		path = 'Game.Datas.vo.' .. name .. 'Vo'
	end
	return path
end



return Anniversary2ConfigParser