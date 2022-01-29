--[[
 * author : kaishiqi
 * descpt : 外卖相关 - 配表解析器
]]
local AbstractBaseParser   = require('Game.Datas.Parser')
local TakeawayConfigParser = class('TakeawayConfigParser', AbstractBaseParser)

TakeawayConfigParser.NAME = 'TakeawayConfigParser'

TakeawayConfigParser.TYPE = {
}

function TakeawayConfigParser:ctor()
	self.super.ctor(self, table.values(TakeawayConfigParser.TYPE))
end


return TakeawayConfigParser