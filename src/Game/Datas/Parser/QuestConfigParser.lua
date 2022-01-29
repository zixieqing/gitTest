local Parser = require( 'Game.Datas.Parser' )

local QuestConfigParser = class('QuestConfigParser', Parser)


QuestConfigParser.NAME = "QuestConfigParser"

function QuestConfigParser:ctor()
  self.super.ctor(self, {
    'enemy',
    'quest',
    'starCondition',
    'battlePosition',
    'city',
    'cityReward',
    'questPlot',
    'questPlotType',
    'questStory',
    'role',
    'starCondition',
    'branch',
    'branchStory',
    'weather',
    'weatherProperty',
    'bossAction',
    'plotFightQuest',
    'teamBoss',
    'teamBossGroup',
    'teamBossGroupReward',
    'teamType',
    'passType',
    'lensControl'
  })
end

return QuestConfigParser
