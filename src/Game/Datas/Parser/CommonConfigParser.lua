--[[
基本表解析器
--]]
local Parser = require('Game.Datas.Parser')
local CommonConfigParser = class('CommonConfigParser', Parser)
CommonConfigParser.NAME = 'CommonConfigParser'

function CommonConfigParser:ctor()
	self.super.ctor(self, {
		'area',
		'areaFixedPoint',
		'soundEffect',
		'payBuff',
		'specialBattle'
	})
end
return CommonConfigParser
