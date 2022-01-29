--[[
 * descpt : pass卡 相关 - 配表解析器
]]
local AbstractBaseParser = require('Game.Datas.Parser')
local GamblingConfigParser  = class('GamblingConfigParser', AbstractBaseParser)

GamblingConfigParser.NAME = 'GamblingConfigParser'
GamblingConfigParser.TYPE = {
	RAND_BUFF_CHILD_POOL    = 'randBuffChildPool',
}

function GamblingConfigParser:ctor()
	self.super.ctor(self, table.values(GamblingConfigParser.TYPE))
end
return GamblingConfigParser
