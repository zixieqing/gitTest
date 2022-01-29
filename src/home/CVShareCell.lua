--[[
市场购买列表cell
--]]
local CVShareCell = class('CVShareCell', function ()
	local CVShareCell = CGridViewCell:new()
	CVShareCell.name = 'home.CVShareCell'
	CVShareCell:enableNodeEvents()
	return CVShareCell
end)

function CVShareCell:ctor( ... )
	local arg = { ... }
	local size = arg[1]
	self:setContentSize(size)
	local eventNode = CLayout:create(size)
	eventNode:setPosition(utils.getLocalCenter(self))
	self:addChild(eventNode)
	self.eventNode = eventNode
	self.headIcon = FilteredSpriteWithOne:create()
	self.headIcon:setTexture(_res('ui/home/activity/cvShare/head/activity_cv_cvsharecards_1.png'))
	self.headIcon:setPosition(cc.p(size.width * 0.5, size.height * 0.5 - 6))
	eventNode:addChild(self.headIcon, 10)
	-- self.headIcon:setFilter(filter.newFilter('GRAY'))
	self.bgBtn = display.newButton(size.width/2, size.height/2 - 6, {n = 'empty', size = self.headIcon:getContentSize()})
	eventNode:addChild(self.bgBtn, 5)
	self.shareLabel = display.newButton(size.width * 0.5, size.height * 0.5 - 6, {n = _res('ui/home/activity/cvShare/activity_cv_card_head_black.png')})
	eventNode:addChild(self.shareLabel, 10)
	self.shareLabel:setEnabled(false)
	display.commonLabelParams(self.shareLabel, {text = __('点击分享'), fontSize = 22, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#5b3c25', outlineSize = 1})
end
return CVShareCell