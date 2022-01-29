--[[
大堂知名度排行Cell
--]]
local LobbyPopularityRankingCell = class('LobbyPopularityRankingCell', function ()
	local LobbyPopularityRankingCell = CGridViewCell:new()
	LobbyPopularityRankingCell.name = 'home.LobbyPopularityRankingCell'
	LobbyPopularityRankingCell:enableNodeEvents()
	return LobbyPopularityRankingCell
end)

function LobbyPopularityRankingCell:ctor( ... )
	local arg = { ... }
	local size = arg[1]
	self:setContentSize(size)
	local eventNode = CLayout:create(size)
	eventNode:setPosition(utils.getLocalCenter(self))
	self:addChild(eventNode)
	self.eventNode = eventNode
	-- bg
	self.bg = display.newImageView(_res('ui/common/common_bg_list.png'), size.width/2, size.height/2, {scale9 = true, size = cc.size(745, 46), capInsets = cc.rect(10, 10, 482, 96)})
   	self.eventNode:addChild(self.bg) 
   	self.rankBg = display.newImageView('ui/home/lobby/information/restaurant_info_bg_rank_num1.png', 50, size.height/2)
   	self.eventNode:addChild(self.rankBg, 5)
	self.rankNum = cc.Label:createWithBMFont('font/small/common_text_num.fnt', ' ')
	self.rankNum:setHorizontalAlignment(display.TAR)
	self.rankNum:setPosition(50, size.height/2 - 3)
	self.eventNode:addChild(self.rankNum, 10)
	self.nameLabel = display.newLabel(100, size.height/2, {ap = cc.p(0, 0.5), text = '', fontSize = 22, color = '#87543'})
	self.eventNode:addChild(self.nameLabel, 10)
	self.scoreBg = display.newImageView(_res('ui/home/lobby/information/restaurant_info_bg_rank_awareness.png'), 650, size.height/2)
	self.eventNode:addChild(self.scoreBg, 5)
	self.scoreNum = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '')
	self.scoreNum:setHorizontalAlignment(display.TAR)
	self.scoreNum:setPosition(680, size.height/2 - 3)
	self.scoreNum:setAnchorPoint(cc.p(1, 0.5))
	self.eventNode:addChild(self.scoreNum, 10)
	self.scoreIcon = display.newImageView(_res('ui/home/lobby/information/restaurant_ico_info.png'), 700, size.height/2)
	self.eventNode:addChild(self.scoreIcon, 10)
	self.scoreIcon:setScale(0.5)

end
return LobbyPopularityRankingCell