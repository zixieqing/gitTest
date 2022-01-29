--[[
召唤概率UP活动view
--]]
local ActivityCapsuleUpView = class('ActivityCapsuleUpView', function ()
	local node = CLayout:create(cc.size(1035, 637))
	node:setAnchorPoint(cc.p(0, 0))
	node.name = 'home.ActivityCapsuleUpView'
	node:enableNodeEvents()
	return node
end)
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local function CreateView( )
	local size = cc.size(1035, 637)
	local view = CLayout:create(size)
	-- 背景
	-- local bg = display.newImageView(_res('ui/home/activity/activity_bg_call_of_time.png'), size.width/2, size.height/2)
	-- view:addChild(bg, 1)

	local bg = lrequire('root.WebSprite').new({url = '', hpath = _res('ui/home/activity/activity_bg_loading.jpg'), tsize = cc.size(1028,630)})
    bg:setVisible(false)
    bg:setAnchorPoint(display.CENTER)
    bg:setPosition(cc.p(size.width/2, size.height/2))
	view:addChild(bg, 1)

	local timeBg = display.newImageView(_res('ui/home/activity/activity_time_bg.png'), 1030, 600, {ap = display.RIGHT_CENTER , scale9 = true, size = isKoreanSdk() and cc.size(268 ,47) or cc.size(400 ,47)})
	local timeBgSize = timeBg:getContentSize()
	view:addChild(timeBg, 5)
	local timeTitleLabel = display.newLabel(25, timeBgSize.height / 2, fontWithColor(18, {text = __('剩余时间:'), ap = display.LEFT_CENTER}))
	local timeTitleLabelSize = display.getLabelContentSize(timeTitleLabel)
	timeBg:addChild(timeTitleLabel, 10)
	local timeLabel = display.newLabel(timeTitleLabel:getPositionX() + timeTitleLabelSize.width + 5, timeTitleLabel:getPositionY(), {text = '', ap = cc.p(0, 0.5), fontSize = 22, color = '#ffe9b4', font = TTF_GAME_FONT, ttf = true, outline = '#3c1e0e', outlineSize = 1})
	timeBg:addChild(timeLabel, 10)
	-- local title = display.newImageView(_res('ui/home/activity/activity_title_call_of_time.png'), 722, 544)
	-- view:addChild(title, 5)
	-- 立绘
	-- local clipNode = cc.ClippingNode:create()
	-- clipNode:setPosition(cc.p(0, 0))
	-- view:addChild(clipNode, 3)
	-- local stencilNode = display.newNSprite(_res('ui/home/activity/activity_bg_sign.jpg'), size.width/2, size.height/2)
	-- clipNode:setAlphaThreshold(0.1)
	-- clipNode:setStencil(stencilNode)

	-- local cardDrawNode = require('common.CardSkinDrawNode').new({confId = 200001, coordinateType = COORDINATE_TYPE_TEAM})
	-- cardDrawNode:setPosition(cc.p(160, 420))
	-- cardDrawNode:setScale(0.9)
	-- clipNode:addChild(cardDrawNode)	
	-- 跳转按钮
	local enterBtn = display.newButton(754, 214, {n = _res('ui/common/common_btn_big_orange.png')})
	view:addChild(enterBtn, 10)
	display.commonLabelParams(enterBtn, fontWithColor(14, {text = __('前 往')}))
	-- 活动规则
	--local ruleTitleBg = display.newImageView(_res('ui/home/activity/activity_exchange_bg_rule_title.png'), 100, 164)
	--view:addChild(ruleTitleBg, 5)
	--local ruleTitleLabel = display.newLabel(88, 168, {text = __('活动规则'), fontSize = 26, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#3c1e0e', outlineSize = 1})
	--view:addChild(ruleTitleLabel, 10)

	local ruleBg = display.newImageView(_res('ui/home/activity/activity_exchange_bg_rule.png'), size.width/2, 3, {ap = cc.p(0.5, 0)})
	view:addChild(ruleBg, 5)
	local ruleLabel = display.newLabel(34, 142, {ap = cc.p(0, 1), text = __('活动规则'), fontSize = 24, color = '#ffffff', w = 970})
	view:addChild(ruleLabel, 10)

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
		bg        = bg,
		view 	  = view,
		enterBtn  = enterBtn,
		ruleLabel = ruleLabel,
		listView = listView ,
		timeLabel = timeLabel
	}
end

function ActivityCapsuleUpView:ctor( ... )
	self.viewData_ = CreateView()
	self:addChild(self.viewData_.view, 1)
	self.viewData_.view:setPosition(utils.getLocalCenter(self))
end

return ActivityCapsuleUpView
