--[[
卡牌相关解析器
--]]
local Parser = require( 'Game.Datas.Parser' )

local MonsterConfigParser = class('MonsterConfigParser', Parser)

MonsterConfigParser.NAME = "MonsterConfigParser"

function MonsterConfigParser:ctor()
  self.super.ctor(self, {'monster', 'monsterSkin'})
end

return MonsterConfigParser
