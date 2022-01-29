--[[
活动页签Cell
--]]
local ActivityTabCell = class('ActivityTabCell', function ()
	local ActivityTabCell = CGridViewCell:new()
	ActivityTabCell.name = 'home.ActivityTabCell'
	ActivityTabCell:enableNodeEvents()
	return ActivityTabCell
end)

function ActivityTabCell:ctor( ... )
	local arg = { ... }
	local size = arg[1]
	self:setContentSize(size)
	local eventNode = CLayout:create(size)
	eventNode:setPosition(utils.getLocalCenter(self))
	self:addChild(eventNode)
	self.eventNode = eventNode
	-- bg
	self.bgBtn = display.newCheckBox(size.width/2, size.height/2, {
        n = _res("ui/home/rank/rank_btn_tab_default.png"),
        s = _res("ui/home/rank/rank_btn_tab_select.png")
    })
    self.eventNode:addChild(self.bgBtn)
    self.nameLabel = display.newLabel(size.width/2, size.height/2, {ttf = true, font = TTF_GAME_FONT, text = '', color = 'ffffff',fontSize = 24, outline = '#734441'})
    self.nameLabel:setAlignment(cc.TEXT_ALIGNMENT_CENTER)
    self.eventNode:addChild(self.nameLabel)
    self.tipsIcon = display.newImageView(_res('ui/common/common_hint_circle_red_ico.png'), size.width-20, size.height-10)
    self.eventNode:addChild(self.tipsIcon, 10)
    self.newIcon = display.newImageView(_res('ui/card_preview_ico_new_2'), 0, size.height  ,{ap = display.LEFT_TOP})
    self.newIcon:setScale(0.85)
    self.newIcon:setVisible(false)
    self.eventNode:addChild(self.newIcon, 10)
end
return ActivityTabCell
