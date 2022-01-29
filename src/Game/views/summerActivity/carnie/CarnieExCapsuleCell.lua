--[[
游乐园（夏活）特典奖池Cell
--]]
---@class CarnieExCapsuleCell
local CarnieExCapsuleCell = class('CarnieExCapsuleCell', function ()
	local CarnieExCapsuleCell = CGridViewCell:new()
	CarnieExCapsuleCell.name = 'home.CarnieExCapsuleCell'
	CarnieExCapsuleCell:enableNodeEvents()
	return CarnieExCapsuleCell
end)

local RES_DICT = {
    SUMMER_ACTIVITY_EGG_PREVIEW_LINE_1 = _res('ui/home/activity/summerActivity/carnie/summer_activity_egg_preview_line_1.png'),
    SUMMER_ACTIVITY_EGG_BG_PREVIEW     = _res('ui/home/activity/summerActivity/carnie/summer_activity_egg_bg_preview.png'),
}

function CarnieExCapsuleCell:ctor( ... )
	local arg = { ... }
	local size = arg[1]
	self:setContentSize(size)
	local eventNode = CLayout:create(size)
	eventNode:setPosition(utils.getLocalCenter(self))
	self:addChild(eventNode)
    self.eventNode = eventNode
    self.dateLabel = display.newLabel(size.width / 2, size.height - 20, {text = '', fontSize = 20, color = '#6c4a31', ap = cc.p(0.5, 0.5)}) 
    eventNode:addChild(self.dateLabel, 5)   
    self.line = display.newImageView(RES_DICT.SUMMER_ACTIVITY_EGG_PREVIEW_LINE_1, size.width/2, size.height - 40)
    eventNode:addChild(self.line, 5)
    self.rewardsLayout = CLayout:create(cc.size(size.width, 100))
    self.rewardsLayout:setPosition(size.width/2, 0)
    self.rewardsLayout:setAnchorPoint(cc.p(0.5, 0))
    self.rewardsLayout:setBackgroundColor(cc.c4b(100, 100, 100, 100))
    eventNode:addChild(self.rewardsLayout, 5)
    self.selectedBg = display.newImageView(RES_DICT.SUMMER_ACTIVITY_EGG_BG_PREVIEW, size.width / 2, size.height / 2 - 3)
    eventNode:addChild(self.selectedBg, 1)
end
return CarnieExCapsuleCell