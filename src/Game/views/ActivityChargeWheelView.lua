--[[
付费转盘活动view
--]]
local ActivityChargeWheelView = class('ActivityChargeWheelView', function ()
	local node = CLayout:create(cc.size(1035, 637))
	node:setAnchorPoint(cc.p(0, 0))
	node.name = 'home.ActivityChargeWheelView'
	node:enableNodeEvents()
	return node
end)
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local function CreateView( )
	local size = cc.size(1035, 637)
	local view = CLayout:create(size)
	-- 背景
	local bg = lrequire('root.WebSprite').new({url = '', hpath = _res('ui/home/activity/activity_bg_loading.jpg'), tsize = cc.size(1028,630)})
    bg:setVisible(false)
    bg:setAnchorPoint(display.CENTER)
    bg:setPosition(cc.p(size.width/2, size.height/2))
	view:addChild(bg, 1)
	-- 时间
	local timeBg = display.newImageView(_res('ui/home/activity/activity_time_bg.png'), 1030, 600, {ap = display.RIGHT_CENTER, size = isKoreanSdk() and cc.size(268 ,47) or cc.size(400 ,47) , scale9 = true })
	local timeBgSize = timeBg:getContentSize()
	view:addChild(timeBg, 5)
	local timeTitleLabel = display.newLabel(40, timeBgSize.height / 2, fontWithColor(18, {text = __('剩余时间:'), ap = display.LEFT_CENTER}))
	local timeTitleLabelSize = display.getLabelContentSize(timeTitleLabel)
	timeBg:addChild(timeTitleLabel, 10)
	local timeLabel = display.newLabel(timeTitleLabel:getPositionX() + timeTitleLabelSize.width + 5, timeTitleLabel:getPositionY(), {text = '', ap = cc.p(0, 0.5), fontSize = 24, color = '#ffe9b4', font = TTF_GAME_FONT, ttf = true, outline = '#3c1e0e', outlineSize = 1})
	timeBg:addChild(timeLabel, 10)
	-- 奖励预览
	local rewardLayerSize = cc.size(486, 202 + 35)
	local rewardLayer = display.newLayer(754, 356, {ap = display.CENTER, size = rewardLayerSize})
	rewardLayer:setVisible(false)
	view:addChild(rewardLayer, 2)
	local rewardTitle = display.newButton(rewardLayerSize.width/2, rewardLayerSize.height, {n = _res('ui/common/common_title_5.png'), enable = false, ap = display.CENTER_TOP , scale9 = true } )
	display.commonLabelParams(rewardTitle, fontWithColor(4, {text = __('奖励一览'), paddingW = 30 }))
	rewardLayer:addChild(rewardTitle)
	local rewardBgImg = display.newImageView(_res('ui/home/activity/activity_bg_prop_2.png'), rewardLayerSize.width/2, 0, {ap = display.CENTER_BOTTOM})
	rewardLayer:addChild(rewardBgImg)
	-- 跳转按钮
	local enterBtn = display.newButton(654, 191, {ap = display.CENTER, n = _res('ui/common/common_btn_big_orange.png')})
	view:addChild(enterBtn, 10)
	display.commonLabelParams(enterBtn, fontWithColor(14, {text = __('前 往')}))
	-- 领取次数奖励按钮
	local drawBtn = display.newButton(854, 191, {ap = display.CENTER, n = _res('ui/common/common_btn_big_orange.png')})
	view:addChild(drawBtn, 10)
	display.commonLabelParams(drawBtn, fontWithColor(14, {text = __('豪华奖励') ,w = 140 ,hAlign = display.TAC}))
	-- local redPoint = display.newImageView(_res('ui/common/common_hint_circle_red_ico.png'), enterBtn:getContentSize().width-20, enterBtn:getContentSize().height-15)
	-- redPoint:setName('BTN_RED_POINT')
	-- redPoint:setVisible(false)
	-- enterBtn:addChild(redPoint)
	-- 活动规则
	--local ruleTitleBg = display.newImageView(_res('ui/home/activity/activity_exchange_bg_rule_title.png'), 100, 164)
	--view:addChild(ruleTitleBg, 5)
	--local ruleTitleLabel = display.newLabel(88, 168, {text = __('活动规则'), fontSize = 26, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#3c1e0e', outlineSize = 1})
	--view:addChild(ruleTitleLabel, 10)
	local ruleTitleBg  = display.newButton(20,170, { n = _res('ui/home/activity/activity_exchange_bg_rule_title.png') ,enable = true , scale9 = true , ap = display.LEFT_CENTER  } )
	display.commonLabelParams(ruleTitleBg, fontWithColor('14',{text= __('活动规则') , offset = cc.p( -15, 0) ,paddingW = 30}) )
	view:addChild(ruleTitleBg, 9 )
	local ruleBg = display.newImageView(_res('ui/home/activity/activity_exchange_bg_rule.png'), size.width/2, 3, {ap = cc.p(0.5, 0)})
	view:addChild(ruleBg, 5)
	local ruleLabel  = display.newLabel(0,0 ,fontWithColor('18', { fontSize = 22, ap =  display.CENTER , w = 970,hAlign = display.TAL, text = "" } )  )
	--ruleImage:addChild(ruleLabel)

	local ruleSize = display.getLabelContentSize( ruleLabel)
	local ruleLayout  = display.newLayer(0, 0,{size = ruleSize ,ap = cc.p(0, 1)})
	ruleLayout:addChild(ruleLabel)
	ruleLabel:setPosition(ruleSize.width/2 ,ruleSize.height/2)
	local listViewSize = cc.size(970 , 130)
	local listView = CListView:create(listViewSize)
	listView:setBounceable(true )
	listView:setDirection(eScrollViewDirectionVertical)
	listView:setAnchorPoint(display.LEFT_TOP)
	listView:setPosition(34, 142)
	view:addChild(listView  , 10 )
	listView:insertNodeAtLast(ruleLayout)
	listView:reloadData()


	return {
		view           = view,
		ruleLabel      = ruleLabel,
		timeTitleLabel = timeTitleLabel,
		timeBg         = timeBg,
		rewardLayer    = rewardLayer,
		enterBtn       = enterBtn,
		drawBtn        = drawBtn,
		timeLabel      = timeLabel,
		listView       = listView,
		bg             = bg
	}
end

function ActivityChargeWheelView:ctor( ... )
	self.viewData_ = CreateView()
	self:addChild(self.viewData_.view, 1)
	self.viewData_.view:setPosition(utils.getLocalCenter(self))
end

return ActivityChargeWheelView
