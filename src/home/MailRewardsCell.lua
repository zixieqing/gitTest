local MailRewardsCell = class('MailRewardsCell', function ()
	local MailRewardsCell = CTableViewCell:new()
	MailRewardsCell.name = 'home.MailRewardsCell'
	MailRewardsCell:enableNodeEvents()
	return MailRewardsCell
end)
function MailRewardsCell:ctor( ... )
	local arg = { ... }
	local size = arg[1]
	self:setContentSize(size)
    self.goodsIcon = require('common.GoodNode').new({id = 900001, amount = 1, showAmount = true, callBack = function () end})
    self.goodsIcon:setScale(0.8)
    self.goodsIcon:setPosition(cc.p(size.width/2, size.height/2 - 6))
    self:addChild(self.goodsIcon, 5)
    self.drawnLabel = display.newLabel(size.width/2, size.height/2 - 6, {text = __('已领取'), hAlign = display.TAC, fontSize = 22, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#4e2e1e', outlineSize = 1})
    self:addChild(self.drawnLabel, 10)
end
return MailRewardsCell