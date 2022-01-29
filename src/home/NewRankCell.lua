local NewRankCell = class('NewRankCell', function ()
    local NewRankCell = CExpandableNode:new()
    NewRankCell.name = 'home.NewRankCell'
	NewRankCell:enableNodeEvents()
    return NewRankCell
end)

function NewRankCell:ctor( ... )
	local arg = { ... }
	local size = arg[1]
	self.childNode = nil 
	self:setContentSize(size)
	local maskLayer = CColorView:create(cc.c4b(0, 0, 0, 0))
	maskLayer:setTouchEnabled(true)
	maskLayer:setContentSize(size)
	maskLayer:setPosition(utils.getLocalCenter(self))
	maskLayer:setAnchorPoint(0.5, 0.5)
	self:addChild(maskLayer, -1)
	self.buttonLayout = CLayout:create(cc.size(size.width, 78))
	self.buttonLayout:setPosition(cc.p(size.width/2, size.height - 50))
	self:addChild(self.buttonLayout, 10)
	self.button = display.newButton(size.width/2, 39, {n = _res('ui/home/rank/rank_btn_tab_default.png'), ap = cc.p(0.5, 0.5)})
	self.buttonLayout:addChild(self.button, 10)
	self.nameLabel = display.newLabel(size.width/2, 39, fontWithColor(14, {text = '', w = 180, hAlign = cc.TEXT_ALIGNMENT_CENTER}))
	self.buttonLayout:addChild(self.nameLabel, 10)
	self.arrowIcon = display.newImageView(_res('ui/home/rank/rank_ico_arrow.png'), 180, 39)
	self.arrowIcon:setRotation(270)
	self.buttonLayout:addChild(self.arrowIcon, 10)
	self.arrowIcon:setVisible(false)
end
return NewRankCell