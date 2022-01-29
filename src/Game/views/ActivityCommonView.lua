--[[
通用活动页view
--]]
local ActivityCommonView = class('ActivityCommonView', function ()
	local node = CLayout:create(cc.size(1035, 637))
	node:setAnchorPoint(cc.p(0, 0))
	node.name = 'home.ActivityCommonView'
	node:enableNodeEvents()
	return node
end)
local function CreateView( )
	local size = cc.size(1035, 637)
	local view = CLayout:create(size)
	-- 背景
	local bg = lrequire('root.WebSprite').new({url = '', hpath = _res('ui/home/activity/activity_bg_loading.jpg'), tsize = cc.size(1028,630)})
    bg:setAnchorPoint(display.CENTER)
    bg:setPosition(cc.p(size.width/2, size.height/2))
	view:addChild(bg, 1)
	-- 时间
	local timeBg = display.newImageView(_res('ui/home/activity/activity_time_bg.png'), 1030, 600, {ap = display.RIGHT_CENTER ,scale9 = true , size = isKoreanSdk() and cc.size(268 ,47) or cc.size(400 ,47)})
	local timeBgSize = timeBg:getContentSize()
	view:addChild(timeBg, 5)
	local timeTitleLabel = display.newLabel(40, timeBgSize.height / 2, fontWithColor(18, {text = __('剩余时间:'), ap = display.RIGHT_CENTER}))
	local timeTitleLabelSize = display.getLabelContentSize(timeTitleLabel)
	timeBg:addChild(timeTitleLabel, 10)
	local timeLabel = display.newLabel(0,0, {text = '', ap = cc.p(0, 0.5), fontSize = 24, color = '#ffe9b4', font = TTF_GAME_FONT, ttf = true, ap = display.RIGHT_CENTER, outline = '#3c1e0e', outlineSize = 1})
	timeBg:addChild(timeLabel, 10)
	-- 跳转按钮
	local btnBg = display.newImageView(_res('ui/home/activity/novice_recharge_btn_bg.png'), 754, 191)
	btnBg:setVisible(false)
	view:addChild(btnBg, 5)
	local enterLabel = display.newLabel(0, 0, fontWithColor(14, {text = __('前 往')}))
	local enterBtn = display.newButton(754, 191, {ap = display.CENTER, n = _res('ui/common/common_btn_big_orange.png'), size = cc.size(123, 62), scale9 = true})
	enterBtn:addChild(enterLabel)
	view:addChild(enterBtn, 10)
	local redPoint = display.newImageView(_res('ui/common/common_hint_circle_red_ico.png'), enterBtn:getContentSize().width-20, enterBtn:getContentSize().height-15)
	redPoint:setName('BTN_RED_POINT')
	redPoint:setVisible(false)
	enterBtn:addChild(redPoint)
	-- 奖励预览
	local rewardLayerSize = cc.size(486, 202 + 35)
	local rewardLayer = display.newLayer(754, 400, {ap = display.CENTER, size = rewardLayerSize})
	rewardLayer:setVisible(false)
	view:addChild(rewardLayer, 2)
	local rewardTitle = display.newButton(rewardLayerSize.width/2, rewardLayerSize.height, {n = _res('ui/common/common_title_5.png'), enable = false, ap = display.CENTER_TOP , scale9 = true })
	display.commonLabelParams(rewardTitle, fontWithColor(4, {text = __('奖励一览'), paddingW = 30 }))
	rewardLayer:addChild(rewardTitle)
	local rewardBgImg = display.newImageView(_res('ui/home/activity/activity_bg_prop.png'), rewardLayerSize.width/2, 0, {ap = display.CENTER_BOTTOM})
	rewardLayer:addChild(rewardBgImg)
	-- 活动规则
	local  ruleLayoutSize = cc.size(size.width, 192)
	local ruleLayout = CLayout:create(ruleLayoutSize)
	display.commonUIParams(ruleLayout, {po = cc.p(size.width/2, 0), ap = cc.p(0.5, 0)})
	view:addChild(ruleLayout, 10)
	local ruleTitleBg  = display.newButton(20,170, { n = _res('ui/home/activity/activity_exchange_bg_rule_title.png') ,enable = true , scale9 = true , ap = display.LEFT_CENTER  } )
	display.commonLabelParams(ruleTitleBg, fontWithColor('14',{text= __('活动规则') , offset = cc.p( -15, 0) ,paddingW = 30}) )
	ruleLayout:addChild(ruleTitleBg, 9 )

	--local ruleTitleBg = display.newB(_res('ui/home/activity/activity_exchange_bg_rule_title.png'), 100, 164)
	--ruleLayout:addChild(ruleTitleBg, 5)
	--local ruleTitleLabel = display.newLabel(88, 168, {text = __('活动规则'), fontSize = 26, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#3c1e0e', outlineSize = 1})
	--ruleLayout:addChild(ruleTitleLabel, 10)
	local ruleBg = display.newImageView(_res('ui/home/activity/activity_exchange_bg_rule.png'), size.width/2, 3, {ap = cc.p(0.5, 0)})
	ruleLayout:addChild(ruleBg, 5)
	local ruleLabel  = display.newLabel(0,0 ,fontWithColor('18', { fontSize = 22, ap =  display.CENTER , w = 970,hAlign = display.TAL, text = "" } )  )
	--ruleImage:addChild(ruleLabel)

	local ruleSize = display.getLabelContentSize( ruleLabel)
	local ruleLabelLayout  = display.newLayer(0, 0,{size = ruleSize ,ap = cc.p(0, 1)})
	ruleLabelLayout:addChild(ruleLabel)
	ruleLabel:setPosition(ruleSize.width/2 ,ruleSize.height/2)
	local listViewSize = cc.size(970 , 130)
	local listView = CListView:create(listViewSize)
	listView:setBounceable(true )
	listView:setDirection(eScrollViewDirectionVertical)
	listView:setAnchorPoint(display.LEFT_TOP)
	listView:setPosition(34, 142)
	view:addChild(listView  , 10 )
	listView:insertNodeAtLast(ruleLabelLayout)
	listView:reloadData()
	--local ruleLabel = display.newLabel(34, 142, {ap = cc.p(0, 1), text = __('活动规则'), fontSize = 24, color = '#ffffff', w = 970})
	--ruleLayout:addChild(ruleLabel, 10)
	return {
		view            = view,
		size            = size,
		timeTitleLabel  = timeTitleLabel,
		timeLabel       = timeLabel,
		bg              = bg,
		timeBg          = timeBg,
		btnBg           = btnBg,
		enterBtn        = enterBtn,
		rewardLayer     = rewardLayer,
		rewardTitle     = rewardTitle,
		rewardBgImg     = rewardBgImg,
		ruleLayout      = ruleLayout,
		ruleLabel       = ruleLabel,
		ruleLabelLayout = ruleLabelLayout,
		listView        = listView,
		enterLabel      = enterLabel,

	}
end
--[[
@params table {
	showTime bool 是否显示剩余时间（默认显示）
	showRule bool 是否显示活动规则（默认显示）
	showRewardsBg bool 是否显示奖励背景（默认隐藏）
	showDeepRewardsBg bool 是否显示深色奖励背景 
	showRewardsTitle bool 是否显示奖励背景标题
	showBtn bool 是否显示按钮
	showBtnBg bool 是否显示按钮背景（默认隐藏）
	btnText str 按钮文字
	ruleText str 规则文字
	timeText str 时间
	btnTag int 按钮tag
	btnCallback function 按钮回调

}
--]]
function ActivityCommonView:ctor( ... )
	self.args = unpack({...})
	self.showTime = self.args.showTime == nil and true or self.args.showTime
	self.showRule = self.args.showRule == nil and true or self.args.showRule
	self.showRewardsBg = self.args.showRewardsBg == true
	self.showDeepRewardsBg = self.args.showDeepRewardsBg == true
	self.showRewardsTitle = self.args.showRewardsTitle == nil and true or self.args.showRewardsTitle
	self.showBtn = self.args.showBtn == nil and true or self.args.showBtn
	self.showBtnBg = self.args.showBtnBg == true
	self.btnTag = self.args.btnTag
	self.btnText = self.args.btnText or __('前 往')
	self.ruleText = self.args.ruleText or ''
	self.timeText = self.args.timeText or ''
	self.bgImageURL = self.args.bgImageURL
	self.btnCallback = self.args.btnCallback
	self.viewData_ = CreateView()
	self:addChild(self.viewData_.view, 1)
	self.viewData_.view:setPosition(utils.getLocalCenter(self))
	self:InitialUI()
	-- 绑定点击回调
	if self.showBtn and self.btnCallback then
		self.viewData_.enterBtn:setOnClickScriptHandler(self.btnCallback)
	end
end
function ActivityCommonView:InitialUI()
	local viewData = self.viewData_
	viewData.timeLabel:setVisible(self.showTime)
	viewData.timeLabel:setString(self.timeText)
	viewData.ruleLayout:setVisible(self.showRule)
	viewData.ruleLabel:setString(self.ruleText)
	viewData.enterBtn:setVisible(self.showBtn)
	viewData.enterLabel:setString(self.btnText)
	local btnSize = cc.size(math.max(123, display.getLabelContentSize(viewData.enterLabel).width + 30), 62)
	viewData.enterBtn:setContentSize(btnSize)
	viewData.enterLabel:setPosition(btnSize.width / 2, btnSize.height / 2)

	if self.btnTag then
		viewData.enterBtn:setTag(checkint(self.btnTag))
	end
	if self.showBtnBg then
		viewData.btnBg:setVisible(true)
	end
	viewData.rewardLayer:setVisible(self.showRewardsBg)
	if self.showRewardsBg and self.showDeepRewardsBg then
		viewData.rewardBgImg:setText('ui/home/activity/activity_bg_prop_2.png')
	end
	if self.showRewardsBg then
		viewData.rewardTitle:setVisible(self.showRewardsTitle)
	end
	if self.bgImageURL then
		viewData.bg:setWebURL(self.bgImageURL)
	end
	local timeBgSize = self.viewData_.timeBg:getContentSize()
	viewData.timeLabel:setPosition(cc.p(timeBgSize.width - 10 ,timeBgSize.height/2 ))
	local timeLabelSize =  display.getLabelContentSize(viewData.timeLabel)
	viewData.timeTitleLabel:setPosition(cc.p(timeBgSize.width - 10 - timeLabelSize.width ,timeBgSize.height/2 ))
	local ruleSize = display.getLabelContentSize(viewData.ruleLabel)
	viewData.ruleLabelLayout:setContentSize(ruleSize)
	viewData.ruleLabel:setPosition(ruleSize.width /2 , ruleSize.height/2)
	viewData.listView:reloadData()
end
return ActivityCommonView