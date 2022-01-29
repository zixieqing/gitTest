local LobbyTaskCell = class('LobbyTaskCell', function ()
	local LobbyTaskCell = CLayout:create()
	LobbyTaskCell.name = 'home.LobbyTaskCell'
	LobbyTaskCell:enableNodeEvents()
	return LobbyTaskCell
end)

function LobbyTaskCell:ctor( ... )
	local arg = { ... }
	local size = arg[1]
	self.size = size
	self:setContentSize(size)
	local eventNode = CLayout:create(size)
	self.eventNode = eventNode
	eventNode:setPosition(utils.getLocalCenter(self))
	self:addChild(eventNode)
	-- 背景
	self.cardBtn = display.newButton(size.width/2, size.height/2, {n = _res('ui/home/lobby/task/restaurant_task_bg_choice.png'), useS = false})
	eventNode:addChild(self.cardBtn, 5)
	self.titleLabel = display.newLabel(size.width/2, 420, {text = '', fontSize = 30, color = '#e97a38',
        font = TTF_GAME_FONT, ttf = true, w = 300})
    self.titleLabel:setAlignment(cc.TEXT_ALIGNMENT_CENTER)
	eventNode:addChild(self.titleLabel, 10)
	self.descrLabel = display.newLabel(size.width/2, 370, fontWithColor(6, {text = '在1小时内赶走10个客人，获得100个知名度', w = 270, ap = cc.p(0.5, 1)}))
	eventNode:addChild(self.descrLabel, 10)
	self.rewardLabel = display.newButton(size.width/2, 235, {n = _res('ui/common/common_title_5.png'), enable = false})
	eventNode:addChild(self.rewardLabel, 10)
	display.commonLabelParams(self.rewardLabel, fontWithColor(5, {text = __('奖励')}))

    self.progressBar = CProgressBar:create(_res('ui/home/lobby/information/restaurant_bar_exp_1.png'))
    self.progressBar:setBackgroundImage(_res('ui/home/lobby/information/setup_bar_exp_2.png'))
    self.progressBar:setDirection(eProgressBarDirectionLeftToRight)
    self.progressBar:setAnchorPoint(cc.p(0.5, 0.5))
    self.progressBar:setScaleX(0.38)
    self.progressBar:setVisible(false)
    self.progressBar:setPosition(cc.p(size.width/2, 285))
    eventNode:addChild(self.progressBar, 10)
    self.progressLabel = display.newLabel(size.width/2, 285, fontWithColor(9, {text = ''}))
    self.progressLabel:setVisible(false)
    eventNode:addChild(self.progressLabel, 10)

end
return LobbyTaskCell