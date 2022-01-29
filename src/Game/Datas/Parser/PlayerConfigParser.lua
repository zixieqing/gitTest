--[[
卡牌相关解析器
--]]
local Parser = require( 'Game.Datas.Parser' )

local PlayerConfigParser = class('PlayerConfigParser', Parser)

PlayerConfigParser.NAME = "PlayerConfigParser"

function PlayerConfigParser:ctor()
  -- WARING !!! level表和卡牌经验表公用一个vo 两个表结构不一样的时候需要重写vo
  self.super.ctor(self, {'level', 'skill','vip', 'talent', 'talentAssist', 'talentBusiness', 'talentControl', 'talentDamage', 'friendRequest', 'levelReward','teamUnlock','dummyType' , 'dummyQuest'})
end

return PlayerConfigParser
