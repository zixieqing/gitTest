--[[
排行榜知名度排行Cell
--]]
local RankPopularityCell = class('RankPopularityCell', function ()
	local RankPopularityCell = CGridViewCell:new()
	RankPopularityCell.name = 'home.RankPopularityCell'
	RankPopularityCell:enableNodeEvents()
	return RankPopularityCell
end)

function RankPopularityCell:ctor( ... )
	local arg = { ... }
	local size = arg[1]
	self:setContentSize(size)
	local eventNode = CLayout:create(size)
	eventNode:setPosition(utils.getLocalCenter(self))
	self:addChild(eventNode)
	self.eventNode = eventNode
	-- bg
	self.bg = display.newImageView(_res('ui/common/common_bg_list.png'), size.width/2, size.height/2, {scale9 = true, size = cc.size(1006, 104), capInsets = cc.rect(10, 10, 482, 96)})
   	self.eventNode:addChild(self.bg) 
   	self.rankBg = display.newImageView('ui/home/rank/restaurant_info_bg_rank_num1.png', 82, size.height/2)
   	self.eventNode:addChild(self.rankBg, 5)
	self.rankNum = cc.Label:createWithBMFont('font/small/common_text_num.fnt', ' ')
	self.rankNum:setHorizontalAlignment(display.TAR)
	self.rankNum:setScale(1.4)
	self.rankNum:setPosition(79, size.height/2 - 1)
	self.eventNode:addChild(self.rankNum, 10)
    -- 头像
    self.avatarIcon = require('common.FriendHeadNode').new({
        enable = true, scale = 0.6, showLevel = true
    })
    display.commonUIParams(self.avatarIcon, {po = cc.p(182, size.height/2)})
    self.eventNode:addChild(self.avatarIcon, 10)

	self.nameLabel = display.newLabel(246, size.height/2, {ap = cc.p(0, 0.5), text = '', fontSize = 22, color = '#87543'})
	self.eventNode:addChild(self.nameLabel, 10)
	self.scoreBg = display.newImageView(_res('ui/home/rank/restaurant_info_bg_rank_awareness.png'), 880, size.height/2, {scale9 = true, size = cc.size(280, 98)})
	self.eventNode:addChild(self.scoreBg, 5)

	-- 我的得分
	self.scoreNum = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '')
	self.scoreNum:setHorizontalAlignment(display.TAR)
	self.scoreNum:setPosition(962, size.height/2)
	self.scoreNum:setAnchorPoint(cc.p(1, 0.5))
	self.eventNode:addChild(self.scoreNum, 10)
	self.scoreIcon = display.newImageView(_res('ui/common/common_ico_fame.png'), 986, size.height/2+5)
	self.eventNode:addChild(self.scoreIcon, 10)
	self.scoreIcon:setScale(0.25)

end
return RankPopularityCell