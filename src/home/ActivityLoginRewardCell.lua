--[[
登录礼包活动Cell
--]]
local ActivityLoginRewardCell = class('ActivityLoginRewardCell', function ()
	local ActivityLoginRewardCell = CGridViewCell:new()
	ActivityLoginRewardCell.name = 'home.ActivityLoginRewardCell'
	ActivityLoginRewardCell:enableNodeEvents()
	return ActivityLoginRewardCell
end)

function ActivityLoginRewardCell:ctor( ... )
	local arg = { ... }
	local size = arg[1]
	self:setContentSize(size)
	local eventNode = CLayout:create(size)
	eventNode:setPosition(utils.getLocalCenter(self))
	self:addChild(eventNode)
	self.eventNode = eventNode
	-- bg
	self.bg = display.newImageView(_res('ui/home/activity/activity_15sign_bg_reward.png'), size.width/2, size.height/2)
	self.eventNode:addChild(self.bg, 3)
	self.numLabel = display.newLabel(210, 126, {text = '', fontSize = 28, color = '#fbbe55', ttf = true, font = TTF_GAME_FONT, outline = '4e2e1e', outlineSize = 1})
	self.eventNode:addChild(self.numLabel, 10)
	-- 奖励
	self.rewardBg = display.newImageView(_res('ui/home/activity/activity_15sign_bg_prop.png'), 210, 63)
	self.eventNode:addChild(self.rewardBg, 5)
	self.goodsTable = {}
	for i=1, 4 do
		local goodsIcon = require('common.GoodNode').new({highlight = 1, callBack = function()end})
		goodsIcon:setPosition(cc.p(72 + (i-1)*94, 63))
		goodsIcon:setScale(0.8)
		self.eventNode:addChild(goodsIcon, 10)
		table.insert(self.goodsTable, goodsIcon)
	end
	-- 领取按钮
	self.drawBtn = display.newButton(470, size.height/2, {n = _res('ui/common/common_btn_orange_disable.png')})
	-- display.commonLabelParams(self.drawBtn, {fontSize = 24, color = '2b2017', font = TTF_GAME_FONT, ttf = true, text = __('已领取')})
	self.eventNode:addChild(self.drawBtn, 10)
	self.drawLabel = display.newLabel(470, size.height/2, {fontSize = 24, color = '2b2017', font = TTF_GAME_FONT, ttf = true, text = __('已领取')})
	self.eventNode:addChild(self.drawLabel, 10)
	self.mask = display.newImageView(_res('ui/home/activity/activity_15sign_bg_reward_black.png'), size.width/2, size.height/2)
	self.eventNode:addChild(self.mask, 15)
end
return ActivityLoginRewardCell