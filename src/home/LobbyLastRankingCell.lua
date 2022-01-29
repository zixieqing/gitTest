--[[
上周排行榜页面Cell
--]]
local LobbyLastRankingCell = class('LobbyLastRankingCell', function ()
	local LobbyLastRankingCell = CGridViewCell:new()
	LobbyLastRankingCell.name = 'home.LobbyLastRankingCell'
	LobbyLastRankingCell:enableNodeEvents()
	return LobbyLastRankingCell
end)

function LobbyLastRankingCell:ctor( ... )
	local arg = { ... }
	local size = arg[1]
	self:setContentSize(size)
	local eventNode = CLayout:create(size)
	eventNode:setPosition(utils.getLocalCenter(self))
	self:addChild(eventNode)
	self.eventNode = eventNode

	self.bg = display.newImageView(_res('ui/common/common_bg_list.png'), size.width/2, size.height/2, {scale9 = true, size = cc.size(440, 46), capInsets = cc.rect(10, 10, 482, 96)})
   	self.eventNode:addChild(self.bg)
   	self.rankBg = display.newImageView('ui/home/lobby/information/restaurant_info_bg_rank_num1.png', 50, size.height/2)
   	self.eventNode:addChild(self.rankBg, 5)
	self.rankNum = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '')
	self.rankNum:setHorizontalAlignment(display.TAR)
	self.rankNum:setPosition(50, size.height/2 - 3)
	self.eventNode:addChild(self.rankNum, 10)
	self.nameLabel = display.newLabel(100, size.height/2, {ap = cc.p(0, 0.5), text = '', fontSize = 22, color = '#87543'})
	self.eventNode:addChild(self.nameLabel, 10)
	self.scoreBg = display.newImageView(_res('ui/home/lobby/information/restaurant_info_bg_rank_awareness.png'), 440, size.height/2,{scale9 = true , ap = display.RIGHT_CENTER ,  size = cc.size(180,30)})
	self.eventNode:addChild(self.scoreBg, 5)
	-- self.scoreNum = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '')
	-- self.scoreNum:setHorizontalAlignment(display.TAR)
	-- self.scoreNum:setPosition(400, size.height/2 - 3)
	-- self.scoreNum:setAnchorPoint(cc.p(1, 0.5))
	self.scoreNum = display.newLabel(375, size.height/2, {ap = display.RIGHT_CENTER ,  text = '', fontSize = 22, color = 'ffffff', ap = cc.p(1, 0.5)})

	self.eventNode:addChild(self.scoreNum, 10)
	self.scoreIcon = display.newImageView(_res('ui/home/lobby/information/restaurant_ico_info.png'), 420, size.height/2)
	self.eventNode:addChild(self.scoreIcon, 10)
	self.scoreIcon:setScale(0.2)
	self.iconLabel = display.newLabel(375, size.height/2, fontWithColor(14, {ap = display.LEFT_CENTER,  text = ''}))
	self.eventNode:addChild(self.iconLabel, 10)

end
return LobbyLastRankingCell
