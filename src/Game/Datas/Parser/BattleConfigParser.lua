local Parser = require( 'Game.Datas.Parser' )

local BattleConfigParser = class('BattleConfigParser', Parser)

BattleConfigParser.NAME = "BattleConfigParser"

BattleConfigParser.TYPE = {
	ENEMY = 'enemy',
	ENEMY_CARD = 'enemyCard',
	ENEMY_NPC = 'enemyNpc',
	CARD_LEVEL = 'cardLevel',
	CARD_ARTIFACT = 'cardArtifact',
}

function BattleConfigParser:ctor()
	self.super.ctor(self, table.values(BattleConfigParser.TYPE))
end
return BattleConfigParser
