--[[
 * author : kaishiqi
 * descpt : 爬塔相关 - 配表解析器
]]
local AbstractBaseParser = require('Game.Datas.Parser')
---@class CuisineConfigParser
local CuisineConfigParser  = class('CuisineConfigParser', AbstractBaseParser)

CuisineConfigParser.NAME = 'CuisineConfigParser'
CuisineConfigParser.TYPE = {
	AVATARA_ESTHETIC_EVALUATION = 'avatarAestheticEvaluation',
	FOOD_MATERIALTAG            = 'foodMaterialTag',-- 食物标签表
	FOOD_TAG                    = 'foodTag',
	GROUP                       = 'group',          -- 章节表
	GROUP_REWARDS               = 'groupRewards',   -- 章节的奖励表
	QUEST                       = 'quest',
	QUEST_GROUP                 = 'questGroup',     -- 关卡信息的分类
	RATER                       = 'rater',
	RATER_MOOD                  = 'raterMood',
	STAGE                       = 'stage',           -- 大的关卡的分类
	MENU_TAG                    = 'menuTag',         -- 食材的的分类
	TOTAL_REWARDS               = 'totalRewards',    -- 区域获取的总奖励
	RATER_BUBBLE                = 'raterBubble'      -- 玩家心情所说的话
}

function CuisineConfigParser:ctor()
	self.super.ctor(self, table.values(CuisineConfigParser.TYPE))
end



return CuisineConfigParser
