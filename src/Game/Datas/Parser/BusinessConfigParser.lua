--[[
卡牌相关解析器
--]]
local Parser = require( 'Game.Datas.Parser' )

local BusinessConfigParser = class('BusinessConfigParser', Parser)

BusinessConfigParser.NAME = "BusinessConfigParser"

function BusinessConfigParser:ctor()
  self.super.ctor(self, {'assistant', 'assistantBuffType','assistantSkill','assistantSkillEffect','assistantSkillLevel','assistantSkillType','assistantSkillUnlock','assistantSkillClientEffect'})
end

return BusinessConfigParser
