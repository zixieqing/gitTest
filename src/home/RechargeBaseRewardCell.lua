--[[
累计充值基础奖励cell
--]]
local RechargeBaseRewardCell = class('RechargeBaseRewardCell', function ()
	local RechargeBaseRewardCell = CGridViewCell:new()
	RechargeBaseRewardCell.name = 'home.RechargeBaseRewardCell'
	RechargeBaseRewardCell:enableNodeEvents()
	RechargeBaseRewardCell:setCascadeOpacityEnabled(true)
	return RechargeBaseRewardCell
end)

function RechargeBaseRewardCell:ctor( ... )
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
	self.goodsIcon:setPosition(cc.p(size.width/2, size.height/2))
end
return RechargeBaseRewardCell