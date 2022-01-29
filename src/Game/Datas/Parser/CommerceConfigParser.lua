--[[
活动副本配表解析器
--]]
local AbstractBaseParser      = require('Game.Datas.Parser')
---@class CommerceConfigParser  :  Parser
local CommerceConfigParser = class('CommerceConfigParser', AbstractBaseParser)

CommerceConfigParser.NAME  = 'CommerceConfigParser'

CommerceConfigParser.TYPE  = {
	FUTURES            = "futures",
	INVESTMENT         = "investment",
	LOTTERY_EMAIL      = "lotteryEmail",
	MALL               = "mall",
	MALL_PRODUCTS      = "mallProducts",
	PRECIOUS_MALL      = "preciousMall",
	SCHEDULE           = "schedule",
	TITLE              = "title",
	WAREHOUSE          = "warehouse",
	WAREHOUSE_CAPACITY = "warehouseCapacity",
}

function CommerceConfigParser:ctor()
	self.super.ctor(self, table.values(CommerceConfigParser.TYPE))
end
return CommerceConfigParser