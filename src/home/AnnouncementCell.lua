local AnnouncementCell = class('AnnouncementCell', function ()
	local AnnouncementCell = CGridViewCell:new()
	AnnouncementCell.name = 'home.AnnouncementCell'
	AnnouncementCell:enableNodeEvents()
	return AnnouncementCell
end)

function AnnouncementCell:ctor( ... )
	local arg = { ... }
	local size = arg[1]
	self:setContentSize(size)
	local eventNode = CLayout:create(size)
	eventNode:setPosition(utils.getLocalCenter(self))
	self:addChild(eventNode)
	self.eventnode = eventNode

	local toggleView = display.newToggleView(size.width * 0.5, 0,{
		ap = cc.p(0.5, 0), scale9 = true, size = cc.size(298, 98),capInsets = cc.rect(10, 10, 447, 96),
		s = _res('ui/common/common_bg_list_active.png'),
		n = _res('ui/common/common_bg_list_unlock.png')
		})
	self.toggleView = toggleView
	self.eventnode:addChild(self.toggleView)
	-- titleLabel
	self.titleLabel = display.newLabel(size.width * 0.5, size.height * 0.5,
	{fontSize = 24, color = '#ab5c27'})
	self.titleLabel:setAnchorPoint(cc.p(0.5, 0.5))
	self:addChild(self.titleLabel)

end
return AnnouncementCell