--[[
活动副本配表解析器
--]]
local AbstractBaseParser = require('Game.Datas.Parser')
local ActivityQuestConfigParser  = class('ActivityQuestConfigParser', AbstractBaseParser)

ActivityQuestConfigParser.NAME = 'ActivityQuestConfigParser'

ActivityQuestConfigParser.TYPE = {
  QUEST           = 'quest',
  QUEST_TYPE      = 'questType',
  QUEST_PLOT      = 'questPlot',
  QUEST_EXCHANGE  = 'exchange',
  COORDINATE      = 'coordinate',
  QUEST_CHEST     = 'questChest',
}

function ActivityQuestConfigParser:ctor()
	self.super.ctor(self, table.values(ActivityQuestConfigParser.TYPE) )
end
--[[
获取vo路径
@params name 配表名字
--]]
function ActivityQuestConfigParser:GetVoPath(name)
  name = string.ucfirst(name)
	local path = nil
	if not utils.isExistent(path) and name ~= 'Quest' then
		path = 'Game.Datas.Vo'
	else
		path = 'Game.Datas.vo.' .. name .. 'Vo'
	end
	return path
end


return ActivityQuestConfigParser