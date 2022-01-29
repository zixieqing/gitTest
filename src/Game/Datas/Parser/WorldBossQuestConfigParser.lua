local Parser = require( 'Game.Datas.Parser' )

local WorldBossQuestConfigParser = class('WorldBossQuestConfigParser', Parser)

WorldBossQuestConfigParser.NAME = "WorldBossQuestConfigParser"

WorldBossQuestConfigParser.TYPE = {
	QUEST 	 			= 'quest',
	LOCATION 			= 'location',
	BATTLE_BUFF 		= 'buffInfo',
	BUY_LIVE_CONSUME 	= 'buyLiveConsume',
	PERSONAL_REWARDS 	= 'personalRewards',
	UNION_REWARDS	 	= 'unionRewards',
	MANUAL              = 'manual',
}

function WorldBossQuestConfigParser:ctor()
	self.super.ctor(self, table.values(WorldBossQuestConfigParser.TYPE))
end


return WorldBossQuestConfigParser
