--[[
累计充值特殊奖励cell
--]]
local RechargeSpecialRewardCell = class('RechargeSpecialRewardCell', function ()
	local RechargeSpecialRewardCell = CGridViewCell:new()
	RechargeSpecialRewardCell.name = 'home.RechargeSpecialRewardCell'
	RechargeSpecialRewardCell:enableNodeEvents()
	RechargeSpecialRewardCell:setCascadeOpacityEnabled(true)
	return RechargeSpecialRewardCell
end)

function RechargeSpecialRewardCell:ctor( ... )
	local arg = { ... }
	local size = arg[1]
	self:setContentSize(size)
	self.eventNode = CLayout:create(size)
	self.eventNode:setPosition(utils.getLocalCenter(self))
	self:addChild(self.eventNode)

	self.goodsIcon = require('common.GoodNode').new({
		id = 200001,
		amount = 1,
		showAmount = true,
		callBack = function() end
	})
	self.eventNode:addChild(self.goodsIcon, 5)
	self.goodsIcon:setScale(0.8)
	self.goodsIcon:setPosition(cc.p(size.width/2, 104))
	self.goodsIcon.icon:setColor(cc.c3b(160, 160, 160))
	self.goodsIcon.bg:setColor(cc.c3b(160, 160, 160))
	self.selectFrame = display.newImageView(_res('ui/home/recharge/recharge_task_btn_select.png'), size.width/2, 104)
	self.eventNode:addChild(self.selectFrame, 1)
	self.previewBtn = display.newButton(size.width/2, 28, {n = _res("ui/home/recharge/recharge_btn_preview.png")})
	self.eventNode:addChild(self.previewBtn, 5)
	display.commonLabelParams(self.previewBtn, {fontSize = 20, color = '#5b3c25', text = __('预览') , reqW = 70})
end
return RechargeSpecialRewardCell