--[[
活动副本配表解析器
--]]
local AbstractBaseParser = require('Game.Datas.Parser')
local BarConfigParser  = class('BarConfigParser', AbstractBaseParser)

BarConfigParser.NAME = 'BarConfigParser'

BarConfigParser.TYPE = {
	CUSTOMER                 = 'customer',
	CUSTOMER_FREQUENCY_POINT = 'customerFrequencyPoint',
	CUSTOMER_STORY           = 'customerStory',
	DRINK                    = 'drink',
	FORMULA                  = 'formula',
	LEVELUP                  = 'levelUp',
	MATERIAL                 = 'material',
}
function BarConfigParser:ctor()
	self.super.ctor(self, table.values(BarConfigParser.TYPE) )
end
--[[
获取vo路径
@params name 配表名字
--]]
function BarConfigParser:GetVoPath(name)
	name = string.ucfirst(name)
	local path = nil
	if not utils.isExistent(path) and name ~= 'Quest' then
		path = 'Game.Datas.Vo'
	else
		path = 'Game.Datas.vo.' .. name .. 'Vo'
	end
	return path
end


return BarConfigParser