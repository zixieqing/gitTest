--[[
 * descpt : 夏活相关 - 配表解析器
]]
local AbstractBaseParser = require('Game.Datas.Parser')
local PtConfigParser  = class('PtConfigParser', AbstractBaseParser)

PtConfigParser.NAME = 'PtConfigParser'
PtConfigParser.TYPE = {
    BUY_LIVE                 = 'buyLive',
    CARD_ADDITION            = 'cardAddition',
    CARD_SKILL               = 'cardSkill',
    DAMAGE_RANK_REWARDS      = 'damageRankRewards',
    POINT_RANK_REWARDS       = 'pointRankRewards',
    QUEST                    = 'quest',
    REWARDS                  = 'rewards',
    STORY                    = 'story',
}

function PtConfigParser:ctor()
	self.super.ctor(self, table.values(PtConfigParser.TYPE))
end


return PtConfigParser
