local MailCell = class('MailCell', function ()
	local MailCell = CGridViewCell:new()
	MailCell.name = 'home.MailCell'
	MailCell:enableNodeEvents()
	return MailCell
end)
function MailCell:ctor( ... )
	local arg = { ... }
	local size = arg[1]
	self:setContentSize(size)
	self.viewData = nil
	-- bg
	self.bgBtn = display.newButton(size.width / 2, size.height / 2 - 3, {n = _res('ui/mail/mail_bg_list_readed.png')})
	self:addChild(self.bgBtn, - 2)
	self.frame = display.newImageView(_res('ui/mail/common_bg_list_selected.png'), size.width * 0.5,size.height * 0.5,
		{scale9 = true, size = cc.size(self.bgBtn:getContentSize().width + 12, self.bgBtn:getContentSize().height + 12), capInsets = cc.rect(30, 30, 10, 10)})
	self:addChild(self.frame, 5)
	-- nameLabel
	self.nameLabel = display.newLabel(95, 90,
	{fontSize = 22, color = '#5c5c5c', w = 200, maxL = 2, text = ''})
	self.nameLabel:setAnchorPoint(cc.p(0, 1))
	self:addChild(self.nameLabel)
	-- fromLabel
	self.fromLabel = display.newLabel(100, 6,
	fontWithColor(6,{text = '',ap = cc.p(0, 0)}))
	self:addChild(self.fromLabel)
	-- dateLabel
	self.dateLabel = display.newLabel(size.width - 8, 6, {text = '', fontSize = 18, color = '#b2b2b2', ap = cc.p(1, 0)})
	self:addChild(self.dateLabel)
	-- 图标 --
	self.iconBg = display.newImageView(_res('ui/mail/mail_bg_list_pic.png'), 50, size.height / 2 - 3)
	self:addChild(self.iconBg, 3)
	self.readIcon = display.newImageView(_res('ui/mail/mail_ico_mail_readed.png'), 50, size.height / 2 - 3)
	self:addChild(self.readIcon, 5)
	self.readLabel = display.newButton(self.readIcon:getContentSize().width/2, 25, {n = _res('ui/mail/mail_bg_mail_readed.png')})
	display.commonLabelParams(self.readLabel, {fontSize = 20, color = '#ffffff', text = __('已读')})
	self.readIcon:addChild(self.readLabel)
	self.unreadIcon = display.newImageView(_res('ui/mail/mail_ico_mail_unread.png'), 50, size.height / 2 - 3)
	self:addChild(self.unreadIcon, 5)

end
return MailCell