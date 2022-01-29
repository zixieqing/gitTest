--[[
活动副本配表解析器
--]]
local AbstractBaseParser = require('Game.Datas.Parser')
---@class SpringActivityConfigParser
local SpringActivityConfigParser  = class('SpringActivityConfigParser', AbstractBaseParser)

SpringActivityConfigParser.NAME = 'SpringActivityConfigParser'

SpringActivityConfigParser.TYPE = {
    EXTRA_REWARDS               = 'extraRewards',
    GOODS_BOTTOM_RIGHT_SHOW     = 'goodsBottomRightShow',
    GOODS_POINT_MAIN_SHOW       = 'goodsPointMainShow',
    GOODS_TOP_SHOW              = 'goodsTopShow',
    GUARANTEED                  = 'guaranteed',
    LUCKY                       = 'lucky',
    LUCKY_CONSUME               = 'luckyConsume',
    PLOT_POINT_REWARDS          = 'plotPointRewards',
    PLOT_REWARDS                = 'plotRewards',
    GOODS_REWARDS               = 'goodsRewards',
    QUEST_LIMIT                 = 'questLimit',
    QUEST_TYPE                  = 'questType',
    QUEST                       = 'quest',
    STORY                       = 'story',
    SPECIAL_QUEST_POINT_REWARDS = 'specialQuestPointRewards'
}

function SpringActivityConfigParser:ctor()
	self.super.ctor(self, table.values(SpringActivityConfigParser.TYPE))
end


return SpringActivityConfigParser