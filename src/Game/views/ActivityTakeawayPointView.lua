--[[
外卖店活动view
--]]
local ActivityTakeawayPointView = class('ActivityTakeawayPointView', function ()
	local node = CLayout:create(cc.size(1035, 637))
	node:setAnchorPoint(cc.p(0, 0))
	node.name = 'home.ActivityTakeawayPointView'
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

	local timeBg = display.newImageView(_res('ui/home/activity/activity_time_bg.png'), 1030, 600, {ap = display.RIGHT_CENTER , scale9 = true , size = isKoreanSdk() and cc.size(268 ,47) or cc.size(400 ,47) })
	local timeBgSize = timeBg:getContentSize()
	view:addChild(timeBg, 5)
	local timeTitleLabel = display.newLabel(25, timeBgSize.height / 2, fontWithColor(18, {text = __('剩余时间:'), ap = display.LEFT_CENTER}))
	local timeTitleLabelSize = display.getLabelContentSize(timeTitleLabel)
	timeBg:addChild(timeTitleLabel, 10)
	local timeLabel = display.newLabel(timeTitleLabel:getPositionX() + timeTitleLabelSize.width + 5, timeTitleLabel:getPositionY(), {text = '', ap = cc.p(0, 0.5), fontSize = 22, color = '#ffe9b4', font = TTF_GAME_FONT, ttf = true, outline = '#3c1e0e', outlineSize = 1})
	timeBg:addChild(timeLabel, 10)
	-- 奖励预览
	local rewardLayerSize = cc.size(486, 202 + 35)
	local rewardLayer = display.newLayer(754, 400, {ap = display.CENTER, size = rewardLayerSize})
	rewardLayer:setVisible(false)
	view:addChild(rewardLayer, 2)
	local rewardTitle = display.newButton(rewardLayerSize.width/2, rewardLayerSize.height, {n = _res('ui/common/common_title_5.png'), enable = false, ap = display.CENTER_TOP , scale9 = true })
	display.commonLabelParams(rewardTitle, fontWithColor(4, {text = __('奖励一览') , paddingW = 30 }))
	rewardLayer:addChild(rewardTitle)
	local rewardBgImg = display.newImageView(_res('ui/home/activity/activity_bg_prop.png'), rewardLayerSize.width/2, 0, {ap = display.CENTER_BOTTOM})
	rewardLayer:addChild(rewardBgImg)
	-- 跳转按钮
	local wheelBtn = display.newButton(640, 185, {n = _res('ui/common/common_btn_orange.png')})
	view:addChild(wheelBtn, 10)
	display.commonLabelParams(wheelBtn, fontWithColor(14, {text = __('抽 奖')}))
	local exchangeBtn = display.newButton(872, 185, {n = _res('ui/common/common_btn_white_default.png')})
	view:addChild(exchangeBtn, 10)
	display.commonLabelParams(exchangeBtn, fontWithColor(14, {text = __('兑 换')}))
	-- 抽奖道具
	local wheelLabelBg = display.newImageView(_res('ui/home/activity/avtivity_take_out_bg_rumber.png'), 408 + 232, 237)
	view:addChild(wheelLabelBg, 8)
	local wheelGoodsIcon = display.newImageView(_res(''), 338 + 232, 237)
	view:addChild(wheelGoodsIcon, 10)
	wheelGoodsIcon:setScale(0.3)
	local wheelRichLabel = display.newRichLabel(413 + 232, 237)
	view:addChild(wheelRichLabel, 10)
	-- 兑换道具
	local exchangeLabelBg = display.newImageView(_res('ui/home/activity/avtivity_take_out_bg_rumber.png'), 408 + 232*2, 237)
	view:addChild(exchangeLabelBg, 8)
	local exchangeGoodsIcon = display.newImageView(_res(''), 338 + 232*2, 237)
	view:addChild(exchangeGoodsIcon, 10)
	exchangeGoodsIcon:setScale(0.3)
	local exchangeRichLabel = display.newRichLabel(413 + 232*2, 237)
	view:addChild(exchangeRichLabel, 10)
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
	local ruleLabel  = display.newLabel(0,0 ,fontWithColor('18', { fontSize = 22, ap =  display.CENTER , w = 970,hAlign = display.TAL, text = __('等级达到10级后解锁等级礼包。每个等级礼包只能购买一次，礼包首次出现时，会有12小时的打折活动，一旦超过12小时，打折活动即会消失，但等级礼包仍可购买。（购买等级礼包，也可以享受首充奖励的福利。）') } )  )
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
		bg                = bg,
		view 	          = view,
		wheelBtn          = wheelBtn,
		exchangeBtn       = exchangeBtn,
		ruleLabel         = ruleLabel,
		timeLabel         = timeLabel,
		timeBg            = timeBg ,
		timeTitleLabel    = timeTitleLabel ,
		rewardLayer       = rewardLayer,
		wheelRichLabel    = wheelRichLabel,
		exchangeRichLabel = exchangeRichLabel,
		wheelGoodsIcon    = wheelGoodsIcon,
		exchangeGoodsIcon = exchangeGoodsIcon,
		ruleLayout = ruleLayout ,
		ruleLabel = ruleLabel ,


	}
end

function ActivityTakeawayPointView:ctor( ... )
	self.viewData_ = CreateView()
	self:addChild(self.viewData_.view, 1)
	self.viewData_.view:setPosition(utils.getLocalCenter(self))
end

return ActivityTakeawayPointView
