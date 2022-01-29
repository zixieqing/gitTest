--[[
 * author : kaishiqi
 * descpt : 爬塔相关 - 配表解析器
]]
local AbstractBaseParser = require('Game.Datas.Parser')
local TowerConfigParser  = class('TowerConfigParser', AbstractBaseParser)

TowerConfigParser.NAME = 'TowerConfigParser'

TowerConfigParser.TYPE = {
  UNIT           = 'towerUnit',
  ENEMY          = 'towerEnemy',
  CONTRACT       = 'towerContract',
  BASE_REWARD    = 'towerBaseReward',
  REVIVE_CONSUME = 'towerBuyLiveConsume',
  LEVEL_ATTR     = 'towerLevelCoefficient',
  GLOBAL_BUFF    = 'globalBuff'
}
function TowerConfigParser:ctor()
  self.super.ctor(self, table.values(TowerConfigParser.TYPE))
end
return TowerConfigParser