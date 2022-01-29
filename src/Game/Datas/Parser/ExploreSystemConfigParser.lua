--[[
 * descpt : 新探索相关 - 配表解析器
]]
local AbstractBaseParser = require('Game.Datas.Parser')
local ExploreSystemConfigParser  = class('ExploreSystemConfigParser', AbstractBaseParser)

ExploreSystemConfigParser.NAME = 'ExploreSystemConfigParser'

ExploreSystemConfigParser.TYPE = {
  QUEST              = 'quest',
  TEAM_UNLOCK        = 'teamUnlock',
  CONDITION          = 'condition',
  QUEST_NUM_UNLOCK   = 'questNumUnlock',
  QUEST_REFRESH_RATE = 'questRefreshRate',
}

function ExploreSystemConfigParser:ctor()
	self.super.ctor(self, table.values(ExploreSystemConfigParser.TYPE))
end

return ExploreSystemConfigParser