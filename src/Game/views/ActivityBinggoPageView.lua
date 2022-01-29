--[[
	binggo 活动主页 页面
--]]
local ActivityBinggoPageView = class('ActivityBinggoPageView', function ()
	local node = CLayout:create(cc.size(1035, 637))
	node:setAnchorPoint(cc.p(0, 0))
	node.name = 'home.ActivityBinggoPageView'
	node:enableNodeEvents()
	return node
end)

local VIEW_SIZE = cc.size(1035, 637)

local RES_DIR = {
	DEF_BG           = _res('ui/home/activity/activity_bg_loading.jpg'),
    -- BG               = _res("ui/home/activity/puzzle/activity_puzzle_bg_2.jpg"),
    TIME_BG          = _res('ui/home/activity/activity_time_bg.png'),
    BTN_ORANGE       = _res('ui/common/common_btn_big_orange.png'),
    RED_POINT_IMG    = _res('ui/common/common_hint_circle_red_ico.png'),
    RULE_TITLE_BG    = _res('ui/home/activity/activity_exchange_bg_rule_title.png'),
    RULE_BG          = _res('ui/home/activity/activity_exchange_bg_rule.png'),
    REWARD_BG        = _res("ui/home/activity/puzzle/activity_puzzle_reward_bg.jpg"),
    PUZZLE_SHADOW    = _res("ui/home/activity/puzzle/activity_puzzle_shadow.jpg"),
    PUZZLE_SHADOW_2  = _res("ui/home/activity/puzzle/activity_puzzle_shadow_2.jpg"),
	LIST_TITLE       = _res('ui/common/common_title_5.png'),
}

local CreateListCell = nil


function ActivityBinggoPageView:ctor( ... )
	local args = unpack({...})

	self.viewData_ = CreateView(VIEW_SIZE)

	self:addChild(self:getViewData().view, 1)
	self:getViewData().view:setPosition(utils.getLocalCenter(self))

end

function ActivityBinggoPageView:updateRoleImg(isReceive, skinId)
	local roleImgLayer = self:getViewData().roleImgLayer
	roleImgLayer:setVisible(not isReceive)
end

function ActivityBinggoPageView:getViewData()
	return self.viewData_
end

CreateView = function (size)
    local view = CLayout:create(size)

	-- 背景`
	local bg = lrequire('root.WebSprite').new({url = '', hpath = RES_DIR.DEF_BG, tsize = cc.size(1028,630)})
    bg:setVisible(false)
    bg:setAnchorPoint(display.CENTER)
    bg:setPosition(cc.p(size.width/2, size.height/2))
	view:addChild(bg)

	local timeBg = display.newImageView(RES_DIR.TIME_BG, 1030, 600, {ap = display.RIGHT_CENTER, scale9 = true, size = isKoreanSdk() and cc.size(268 ,47) or cc.size(400 ,47)})
	local timeBgSize = timeBg:getContentSize()
	view:addChild(timeBg, 5)
	local timeTitleLabel = display.newLabel(25, timeBgSize.height / 2, fontWithColor(18, {text = __('剩余时间:'), ap = display.LEFT_CENTER}))
	local timeTitleLabelSize = display.getLabelContentSize(timeTitleLabel)
	timeBg:addChild(timeTitleLabel, 10)
	local timeLabel = display.newLabel(timeTitleLabel:getPositionX() + timeTitleLabelSize.width + 5, timeTitleLabel:getPositionY(), {text = '', ap = cc.p(0, 0.5), fontSize = 22, color = '#ffe9b4', font = TTF_GAME_FONT, ttf = true, outline = '#3c1e0e', outlineSize = 1})
	timeBg:addChild(timeLabel, 10)

	-- 跳转按钮
	local enterBtn = display.newButton(size.width - 260, 191, {ap = display.CENTER, n = RES_DIR.BTN_ORANGE, scale9 = true, size = cc.size(123, 62)})
	view:addChild(enterBtn, 10)
	local enterLabel = display.newLabel(0, 0, fontWithColor(14, {text = __('前往解密')}))
	enterBtn:setContentSize(cc.size(math.max(123, display.getLabelContentSize(enterLabel).width + 20), 62))
	enterLabel:setPosition(cc.p(enterBtn:getContentSize().width / 2, enterBtn:getContentSize().height / 2))
	enterBtn:addChild(enterLabel, 1)
	-- display.commonLabelParams(enterBtn, fontWithColor(14, {text = __('前往解密')}))
	local redPoint = display.newImageView(RES_DIR.RED_POINT_IMG, enterBtn:getContentSize().width-20, enterBtn:getContentSize().height-15)
	redPoint:setName('BTN_RED_POINT')
	redPoint:setVisible(false)
	enterBtn:addChild(redPoint, 1)
	-- 活动规则
	local ruleTitleBg = display.newImageView(RES_DIR.RULE_TITLE_BG, 100, 164)
	view:addChild(ruleTitleBg, 5)
	local ruleTitleLabel = display.newLabel(88, 168, {text = __('活动规则'), fontSize = 26, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#3c1e0e', outlineSize = 1})
	view:addChild(ruleTitleLabel, 10)
	local ruleBg = display.newImageView(RES_DIR.RULE_BG, size.width/2, 3, {ap = cc.p(0.5, 0)})
	view:addChild(ruleBg, 5)
	--ruleImage:addChild(ruleLabel)
	local ruleLabel  = display.newLabel(0,0 ,fontWithColor('18', { fontSize = 22, ap =  display.CENTER , w = 970,hAlign = display.TAL, text = "" } )  )
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

	local roleImg = display.newImageView(RES_DIR.PUZZLE_SHADOW, 0, 0, {ap = display.LEFT_BOTTOM})
	roleImg:setVisible(false)
	view:addChild(roleImg)

	local roleImgSize = cc.size(552, 562)
	local roleImgLayer = display.newLayer(0, 0, {ap = display.LEFT_BOTTOM, size = roleImgSize})
	view:addChild(roleImgLayer)
	
	-- local tipLabel = display.newLabel(roleImgSize.width / 2 + 20, 245, {text = __('解锁全部拼图获得神秘奖励'), hAlign = display.TAC, fontSize = 26, color = '#ffd27c', font = TTF_GAME_FONT, ttf = true, outline = '#5b3c25', outlineSize = 1, ap = display.CENTER, w = 530})
	-- roleImgLayer:addChild(tipLabel)

	-- local listTitleBg = display.newImageView(RES_DIR.LIST_TITLE, size.width - 260, size.height - 80, {ap = display.CENTER_TOP})
	-- listTitleBg:setOpacity(255 - 75)
	-- view:addChild(listTitleBg)

	-- list
	local listTitle = display.newButton(size.width - 260, size.height - 80, {n = RES_DIR.LIST_TITLE, enable = false, ap = display.CENTER_TOP, scale9 = true, size = cc.size(186, 31)})
	local listTitleSize = listTitle:getContentSize()
	local listTitleLabel = display.newLabel(0, 0, fontWithColor(6, {text = __('解密任务奖励')}))
	listTitle:setContentSize(cc.size(math.max(186, display.getLabelContentSize(listTitleLabel).width + 60), 31))
	listTitleLabel:setPosition(cc.p(listTitle:getContentSize().width/2, listTitle:getContentSize().height/2))
	listTitle:addChild(listTitleLabel, 1)
	-- display.commonLabelParams(listTitle, fontWithColor(6, {text = __('解密任务奖励')}))
	view:addChild(listTitle)

	local listBg = display.newImageView(RES_DIR.REWARD_BG, 0, 0, {ap = display.LEFT_BOTTOM})
	local listBgSize = listBg:getContentSize()

	local listBgLayer = display.newLayer(listTitle:getPositionX(), listTitle:getPositionY() - listTitleSize.height - 5, {ap = display.CENTER_TOP, size = listBgSize})
	listBgLayer:addChild(listBg)
	view:addChild(listBgLayer)

    local gridViewCellSize = cc.size(listBgSize.width, 88)
    local gridView = CGridView:create(listBgSize)
    gridView:setSizeOfCell(gridViewCellSize)
    gridView:setColumns(1)
    -- gridView:setBackgroundColor(cc.c3b(100,100,200))
    gridView:setPosition(cc.p(listBgSize.width / 2, listBgSize.height / 2))
    gridView:setAnchorPoint(display.CENTER)
    listBgLayer:addChild(gridView)

	return {
		bg        = bg,
		view 	  = view,
		enterBtn  = enterBtn,
		timeLabel = timeLabel,
		timeTitleLabel = timeTitleLabel,
		ruleLabel = ruleLabel,
		listView = listView ,
		-- rewardLayer = rewardLayer,

		roleImgLayer = roleImgLayer,
		gridView = gridView,
	}
end


return ActivityBinggoPageView
