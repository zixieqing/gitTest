--[[
包厢配表解析器
--]]
local AbstractBaseParser = require('Game.Datas.Parser')
local PlotConfigParser  = class('PlotConfigParser', AbstractBaseParser)

PlotConfigParser.NAME = 'PlotConfigParser'

PlotConfigParser.TYPE = {
    COLLECT_COORDINATE    = 'collectCoordinate',
    QUEST_PLOT_COLLECTION = 'questPlotCollection',
    STORY_REWARD          = 'storyReward',
}

function PlotConfigParser:ctor()
	self.super.ctor(self, table.values(PlotConfigParser.TYPE))
end
return PlotConfigParser