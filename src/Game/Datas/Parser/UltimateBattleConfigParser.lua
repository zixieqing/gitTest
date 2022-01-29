--[[
 * descpt :巅峰对决 - 配表解析器
]]
local AbstractBaseParser = require('Game.Datas.Parser')
local UltimateBattleConfigParser  = class('UltimateBattleConfigParser', AbstractBaseParser)

UltimateBattleConfigParser.NAME = 'UltimateBattleConfigParser'
UltimateBattleConfigParser.TYPE = {
    ATTR  = 'attr',
    BAN   = 'ban',
    ENEMY = 'enemy',
    ENEMY_ARTIFACT = 'enemyArtifact',
    GROUP = 'group',
    LEVEL = 'level',
    RANK_REWARD = 'rankReward',
    REWARD = 'reward',
    SCHEDULE = 'schedule'
}

function UltimateBattleConfigParser:ctor()
	self.super.ctor(self, table.values(UltimateBattleConfigParser.TYPE))
end

return UltimateBattleConfigParser
