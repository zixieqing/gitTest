local Parser = require( 'Game.Datas.Parser' )

local LunaTowerConfigParser = class('LunaTowerConfigParser', Parser)

LunaTowerConfigParser.NAME = "LunaTowerConfigParser"

LunaTowerConfigParser.TYPE = {
		BAN = 'ban',
		FLOOR = 'floor',
		QUEST = 'quest',
		SUMMARY = 'summary'
}

function LunaTowerConfigParser:ctor()
	self.super.ctor(self, table.values(LunaTowerConfigParser.TYPE))
end


return LunaTowerConfigParser
