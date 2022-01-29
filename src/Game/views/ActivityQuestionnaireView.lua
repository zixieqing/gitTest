--[[
首冲礼包活动view
--]]
local ActivityQuestionnaireView = class('ActivityQuestionnaireView', function ()
	local node = CLayout:create(cc.size(1035, 637))
	node:setAnchorPoint(cc.p(0, 0))
	node.name = 'home.ActivityQuestionnaireView'
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
    bg:setAnchorPoint(display.CENTER)
    bg:setPosition(cc.p(size.width/2, size.height/2))
	view:addChild(bg, 1)
	-- 时间
	local timeBg = display.newImageView(_res('ui/home/activity/activity_time_bg.png'), 1030, 600, {ap = display.RIGHT_CENTER, scale9 = true, size = isKoreanSdk() and cc.size(268 ,47) or cc.size(400 ,47)})
	local timeBgSize = timeBg:getContentSize()
	view:addChild(timeBg, 5)
	local timeTitleLabel = display.newLabel(40, timeBgSize.height / 2, fontWithColor(18, {text = __('剩余时间:'), ap = display.LEFT_CENTER}))
	local timeTitleLabelSize = display.getLabelContentSize(timeTitleLabel)
	timeBg:addChild(timeTitleLabel, 10)
	local timeLabel = display.newLabel(timeTitleLabel:getPositionX() + timeTitleLabelSize.width + 5, timeTitleLabel:getPositionY(), {text = '', ap = cc.p(0, 0.5), fontSize = 24, color = '#ffe9b4', font = TTF_GAME_FONT, ttf = true, outline = '#3c1e0e', outlineSize = 1})
	timeBg:addChild(timeLabel, 10)
	-- 奖励 --
	local rewardLayoutSize = cc.size(500, 200)
	local rewardLayout = CLayout:create(rewardLayoutSize)
	view:addChild(rewardLayout, 10)
	rewardLayout:setPosition(cc.p(754, size.height/2))
	-- 提示
	local tipsLabel = display.newLabel(rewardLayoutSize.width/2, rewardLayoutSize.height/2 + 74, fontWithColor(16, {w = 550, hAlign= display.TAC,ap = display.CENTER_BOTTOM, text = __('提交问卷后可在邮箱中收取以下奖励')}))
	rewardLayout:addChild(tipsLabel, 10)
	-- 背景
	local rewardBg = display.newImageView(_res('ui/home/activity/activity_firstcharge_prop_bg.png'), rewardLayoutSize.width/2, rewardLayoutSize.height/2)
	rewardLayout:addChild(rewardBg, 5)
	-- 跳转按钮
	local enterBtn = display.newButton(754, 163, {ap = display.CENTER, n = _res('ui/common/common_btn_big_orange.png') , scale9 = true })
	view:addChild(enterBtn, 10)
	display.commonLabelParams(enterBtn, fontWithColor(14, {text = __('前往问卷') , paddingW = 20 }))

	return {
		view 			 = view,
		bg 	 	 	 	 = bg,
		timeLabel  	     = timeLabel,
		enterBtn	     = enterBtn,
		rewardLayout 	 = rewardLayout
	}
end

function ActivityQuestionnaireView:ctor( ... )
	self.viewData_ = CreateView()
	self.showSpine = false
	self:addChild(self.viewData_.view, 1)
	self.viewData_.view:setPosition(utils.getLocalCenter(self))
end

return ActivityQuestionnaireView