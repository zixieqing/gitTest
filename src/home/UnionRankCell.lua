--[[
工会排行榜Cell
--]]
local UnionRankCell = class('UnionRankCell', function ()
	local UnionRankCell = CGridViewCell:new()
	UnionRankCell.name = 'home.UnionRankCell'
	UnionRankCell:enableNodeEvents()
	return UnionRankCell
end)

function UnionRankCell:ctor( ... )
	local arg = { ... }
	local size = arg[1]
	self:setContentSize(size)
	local eventNode = CLayout:create(size)
	eventNode:setPosition(utils.getLocalCenter(self))
	self:addChild(eventNode)
	self.eventNode = eventNode
	-- bg
	self.bg = display.newImageView(_res('ui/common/common_bg_list.png'), size.width/2, size.height/2, {scale9 = true, size = cc.size(size.width - 10, 104), capInsets = cc.rect(10, 10, 482, 96)})
   	self.eventNode:addChild(self.bg) 
   	self.rankBg = display.newImageView('ui/home/rank/restaurant_info_bg_rank_num1.png', 52, size.height/2)
   	self.eventNode:addChild(self.rankBg, 5)
	self.rankNum = cc.Label:createWithBMFont('font/small/common_text_num.fnt', ' ')
	self.rankNum:setHorizontalAlignment(display.TAR)
	self.rankNum:setScale(1.4)
	self.rankNum:setPosition(52, size.height/2 - 3)
	self.eventNode:addChild(self.rankNum, 10)
    -- 头像
    self.avatarIcon = require('common.FriendHeadNode').new({
        enable = true, scale = 0.6, showLevel = true
    })
    display.commonUIParams(self.avatarIcon, {po = cc.p(156, size.height/2)})
    self.eventNode:addChild(self.avatarIcon, 10)

	self.nameLabel = display.newLabel(218, size.height/2, {ap = cc.p(0, 0.5), text = '', fontSize = 22, color = '#87543'})
	self.eventNode:addChild(self.nameLabel, 10)
	self.scoreBg = display.newImageView(_res('ui/home/rank/restaurant_info_bg_rank_awareness.png'), size.width - 16, size.height/2, {ap = cc.p(1, 0.5)})
	self.eventNode:addChild(self.scoreBg, 5)
	-- 额外得分
    self.extraLabel = display.newLabel(size.width - 368, size.height/2, fontWithColor(6, {text = ''}))
    self.eventNode:addChild(self.extraLabel, 10)
	-- 我的得分
	self.scoreNum = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '')
	self.scoreNum:setHorizontalAlignment(display.TAR)
	self.scoreNum:setPosition(size.width - 90, size.height/2)
	self.scoreNum:setAnchorPoint(cc.p(0.5, 0.5))
	self.eventNode:addChild(self.scoreNum, 10)
	-- self.scoreIcon = display.newImageView(_res('ui/common/common_ico_fame.png'), size.width - 58, size.height/2+5)
	-- self.eventNode:addChild(self.scoreIcon, 10)
	-- self.scoreIcon:setScale(0.25)

end
return UnionRankCell