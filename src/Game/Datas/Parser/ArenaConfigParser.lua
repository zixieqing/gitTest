local Parser = require( 'Game.Datas.Parser' )

local ArenaConfigParser = class('ArenaConfigParser', Parser)

ArenaConfigParser.NAME = "ArenaConfigParser"
function ArenaConfigParser:ctor()
	self.super.ctor(self,{
		'activityPointReward',
		'firstWinReward',
		'robotAttr'
	})
end
return ArenaConfigParser
