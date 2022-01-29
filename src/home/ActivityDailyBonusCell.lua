--[[
活动每日签到Cell
--]]
local ActivityDailyBonusCell = class('ActivityDailyBonusCell', function ()
	local ActivityDailyBonusCell = CGridViewCell:new()
	ActivityDailyBonusCell.name = 'home.ActivityDailyBonusCell'
	ActivityDailyBonusCell:enableNodeEvents()
	return ActivityDailyBonusCell
end)

function ActivityDailyBonusCell:ctor( ... )
	local arg = { ... }
	local size = arg[1]
	self:setContentSize(size)
	local eventNode = CLayout:create(size)
	eventNode:setPosition(utils.getLocalCenter(self))
	self:addChild(eventNode)
	self.eventNode = eventNode
	-- bg
	self.bgBtn = display.newImageView(_res('ui/home/activity/activity_sign_bg_ico_reward.png'), size.width/2, size.height/2)
	self.eventNode:addChild(self.bgBtn, 5)
	self.goodsIcon = require('common.GoodNode').new({id = 900001, amount = 1, showAmount = true })
	self.goodsIcon:setScale(0.85)
	self.goodsIcon:setPosition(cc.p(size.width/2, size.height/2))
	self.eventNode:addChild(self.goodsIcon, 7)
	self.mask = display.newImageView(_res('ui/home/activity/activity_sign_bg_ico_reward_black.png'), size.width/2, size.height/2)
	self.eventNode:addChild(self.mask, 9)
	self.hookIcon = display.newImageView(_res('ui/home/activity/activity_sign_ico_hook.png'), size.width/2, size.height/2)
	self.eventNode:addChild(self.hookIcon, 10)
	self.turntable = display.newImageView(_res('ui/home/activity/activity_sign_btn_turntable.png'), size.width*0.83, size.height*0.83)
	self.eventNode:addChild(self.turntable, 10)
	self.turntable:setScale(0.45)

	self.frameSpine = sp.SkeletonAnimation:create('effects/activity/biankuang.json', 'effects/activity/biankuang.atlas', 1)
	self.frameSpine:update(0) 
	self.frameSpine:setScale(0.85)
	self.frameSpine:setAnimation(0, 'idle', true)
	self.eventNode:addChild(self.frameSpine,10)
	self.frameSpine:setPosition(utils.getLocalCenter(self))

end
return ActivityDailyBonusCell