--[[
卡牌相关解析器
--]]
local Parser = require( 'Game.Datas.Parser' )

local CardsConfigParser = class('CardsConfigParser', Parser)

-- 历史遗留问题，一定要用 Card ConfigParser，不能用 Cards ConfigParser
CardsConfigParser.NAME = "CardConfigParser"

function CardsConfigParser:ctor()
  self.super.ctor(self, {
    'card',
    'cardBreak',
    'cardExtra',
    'grow',
    'level',
    'quality',
    'skillLevel',
    'skillType',
    'taste',
    'coordinate',
    'favorabilityCareerBuff',
    'favorabilityLevel',
    'specialSkill',
    'buffDescr',
    'ruleEnemyTypeDescr',
    'ruleEnemySortDescr',
    'avatarSpine',
    'effectSpine',
    'hurtSpine',
    'show',
    'exSkill',
    'onlineResourceTrigger',
  })
end


return CardsConfigParser
