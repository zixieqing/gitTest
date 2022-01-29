--[[
 * descpt : pass卡 相关 - 配表解析器
]]
local AbstractBaseParser = require('Game.Datas.Parser')
local PassTicketConfigParser  = class('PassTicketConfigParser', AbstractBaseParser)

PassTicketConfigParser.NAME = 'PassTicketConfigParser'
PassTicketConfigParser.TYPE = {
	LEVEL                  = 'level',
	POINT_ACTIVITY_QUEST   = 'pointActivityQuest',
	POINT_ARTIFACT_QUEST   = 'pointArtifactQuest',
	POINT_CIRCLE_TASK      = 'pointCircleTask',
	POINT_QUEST            = 'pointQuest',
	POINT_DAILY_TASK       = 'pointDailyTask',
}

function PassTicketConfigParser:ctor()
	self.super.ctor(self, table.values(PassTicketConfigParser.TYPE))
end


return PassTicketConfigParser
