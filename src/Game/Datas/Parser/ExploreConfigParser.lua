local Parser = require( 'Game.Datas.Parser' )

local ExploreConfigParser = class('ExploreConfigParser', Parser)

ExploreConfigParser.NAME = "ExploreConfigParser"

function ExploreConfigParser:ctor()
	self.super.ctor(self,{'exploreAreaFixPoint', 'exploreAreaFixedPoint', 'exploreEnemy', 'exploreFloor', 'exploreFloorInfo', 'exploreFloorNumRate', 'exploreFloorRoom', 'explorePoint', 'exploreQuest', 'exploreFloorConsumeVigour', 'exploreLang'})
end

return ExploreConfigParser