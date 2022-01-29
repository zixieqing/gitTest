--[[
活动循环任务Cell
--]]
local ActivityCyclicTasksCell = class('ActivityCyclicTasksCell', function ()
	local ActivityCyclicTasksCell = CGridViewCell:new()
	ActivityCyclicTasksCell.name = 'home.ActivityCyclicTasksCell'
	ActivityCyclicTasksCell:enableNodeEvents()
	return ActivityCyclicTasksCell
end)

function ActivityCyclicTasksCell:ctor( ... )
	local arg = { ... }
	local size = arg[1]
	self:setContentSize(size)
	local eventNode = CLayout:create(size)
	eventNode:setPosition(utils.getLocalCenter(self))
	self:addChild(eventNode)
	self.eventNode = eventNode
	-- bg
	local bg = display.newImageView(_res('ui/common/common_bg_list.png'), size.width * 0.5, size.height * 0.5 - 2,{scale9 = true, size = cc.size(size.width - 8,size.height - 6)})
	eventNode:addChild(bg)
	local titleBg = display.newNSprite(_res('ui/home/task/task_bg_title.png'), 4, 0, {ap = cc.p(0, 0.5)})
	eventNode:addChild(titleBg)
	display.commonUIParams(titleBg, {po = cc.p(4, 92)})
	self.titleLabel = display.newLabel(titleBg:getPositionX() + 14, titleBg:getPositionY(),
	fontWithColor(4,{text = '', ap = cc.p(0, 0.5), hAlign = display.TAL}))
	eventNode:addChild(self.titleLabel)
	self.descLabel = display.newLabel(titleBg:getPositionX() + 20, titleBg:getPositionY() - titleBg:getContentSize().height * 0.5 - 10,
		fontWithColor(6,{text = '', ap = cc.p(0, 1), hAlign = display.TAL, w = 450,h=bg:getContentSize().height -50}))
	eventNode:addChild(self.descLabel)
	-- 奖励
	self.rewardsTable = {}
	for i = 1, 4 do
		local goodsNode = require('common.GoodNode').new({id = 160001, amount = 1, showAmount = true, callBack = function()end})
		eventNode:addChild(goodsNode, 10)
		goodsNode:setPosition(390 + (i * 90), 58)
		goodsNode:setScale(0.75)
		table.insert(self.rewardsTable, goodsNode)
	end
	-- 领取按钮
	self.drawBtn = display.newButton(size.width - 20, 65, {n = _res('ui/common/common_btn_orange.png'), ap = cc.p(1, 0.5), scale9 = true, size = cc.size(123, 60)})
	eventNode:addChild(self.drawBtn, 10)
	display.commonLabelParams(self.drawBtn, fontWithColor(14, {text = __('领取')}))
	-- 已完成
	self.completeLabel = display.newLabel(size.width - 82, 65, {text = __('已完成'), fontSize = 22, color = '#ffffff', font = TTF_GAME_FONT, ttf = true})
	eventNode:addChild(self.completeLabel, 10)
	self.completeLabel:setScale(0.9)
	local size1 = display.getLabelContentSize(self.drawBtn:getLabel())
	local size2 = display.getLabelContentSize(self.completeLabel)
	local btnWidth = math.max(size1.width, size2.width)
	self.drawBtn:setContentSize(cc.size(math.max(btnWidth + 30, 123), 60))
	self.taskProgressLabel = display.newLabel(size.width - 82, 20, {text = '3/5', fontSize = 22, color = '#6c6c6c'})
	eventNode:addChild(self.taskProgressLabel, 10)
end
return ActivityCyclicTasksCell
