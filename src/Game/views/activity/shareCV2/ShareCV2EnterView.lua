--[[
 * author : liuzhipeng
 * descpt : KFC签到活动 View
--]]
---@class ShareCV2EnterView
local ShareCV2EnterView = class('ShareCV2EnterView', function ()
	local node = CLayout:create(cc.size(1035, 637))
	node:setAnchorPoint(cc.p(0, 0))
	node.name = 'activity.ShareCV2EnterView'
	node:enableNodeEvents()
	return node
end)
local RES_DICT = {
	ACTIVITY_EXCHANGE_BG_RULE_TITLE = _res('ui/home/activity/activity_exchange_bg_rule_title.png'),
	ACTIVITY_EXCHANGE_BG_RULE       = _res('ui/home/activity/activity_exchange_bg_rule.png'),
	COMMON_BTN_ORANGE               = _res('ui/common/common_btn_orange'),
	TIME_BG                         = _res('ui/home/activity/activity_time_bg.png'),
}
local CreateView    = nil

CreateView = function ()
	local size = cc.size(1035, 637)
	local view = CLayout:create(size)
	local bg = lrequire('root.WebSprite').new({url = '', hpath = _res('ui/home/activity/activity_bg_loading.jpg'), tsize = cc.size(1028,630)})
	bg:setAnchorPoint(display.CENTER)
	bg:setPosition(cc.p(size.width/2, size.height/2))
	view:addChild(bg, 1)
	local timeBg = display.newImageView(RES_DICT.TIME_BG, 1030, 600, {ap = display.RIGHT_CENTER})
	local timeBgSize = timeBg:getContentSize()
	view:addChild(timeBg, 5)

	local timeTitleLabel = display.newLabel(135, timeBgSize.height / 2, fontWithColor(18, {text = __('剩余时间:'), ap = display.RIGHT_CENTER}))
	timeBg:addChild(timeTitleLabel, 10)
	local timeLabel = display.newLabel(timeTitleLabel:getPositionX() + 5, timeTitleLabel:getPositionY(), {text = '', ap = cc.p(0, 0.5), fontSize = 22, color = '#ffe9b4', font = TTF_GAME_FONT, ttf = true, outline = '#3c1e0e', outlineSize = 1})
	timeBg:addChild(timeLabel, 10)
	local activityNameLabel = display.newLabel(130 , 435 , fontWithColor(14, { ap = display.LEFT_BOTTOM , fontSize = 40  , outlineSize = 2}))
	view:addChild(activityNameLabel, 10)
	local compoundBtn = display.newButton(660 , 210 , {n = RES_DICT.COMMON_BTN_ORANGE ,scale9 = true , size = cc.size(170,62) })
	view:addChild(compoundBtn , 10 )
	display.commonLabelParams(compoundBtn , fontWithColor(14 , {text = __('前往拼图')  , w = 150 , hAlign = display.TAC , enable = true  }))
	local cvShareBtn = display.newButton(870 , 210 , {n = RES_DICT.COMMON_BTN_ORANGE  , enable = true ,scale9 = true , size = cc.size(170,62)})
	view:addChild(cvShareBtn , 10 )
	display.commonLabelParams(cvShareBtn , fontWithColor(14 , {text = __('情节播放'), w = 150 ,hAlign = display.TAC  }))
	local ruleTitleBg = display.newImageView(RES_DICT.ACTIVITY_EXCHANGE_BG_RULE_TITLE, 100, 164)
	view:addChild(ruleTitleBg, 5)
	local ruleTitleLabel = display.newLabel(88, 168, {text = __('活动规则'), fontSize = 26, color = '#ffffff', font = TTF_GAME_FONT , ttf = true, outline = '#3c1e0e', outlineSize = 1})
	view:addChild(ruleTitleLabel, 10)
	local ruleBg = display.newImageView(RES_DICT.ACTIVITY_EXCHANGE_BG_RULE, size.width/2, 3, {ap = cc.p(0.5, 0)})
	view:addChild(ruleBg, 5)
	local ruleLabel = display.newLabel(0, 0, {ap = display.LEFT_TOP ,fontSize = 24 , w = 900 , hAlign = display.TAL,  color = "#ffffff" , text = ""})
	local ruleSize = display.getLabelContentSize( ruleLabel)
	local ruleLabelLayout  = display.newLayer(0, 0,{size = ruleSize ,ap = cc.p(0, 1)})
	ruleLabelLayout:addChild(ruleLabel)
	local listViewSize = cc.size(970 , 130)
	local listView = CListView:create(listViewSize)
	listView:setBounceable(true )
	listView:setDirection(eScrollViewDirectionVertical)
	listView:setAnchorPoint(display.LEFT_TOP)
	listView:setPosition(34, 142)
	view:addChild(listView  , 10 )
	listView:insertNodeAtLast(ruleLabelLayout)
	listView:reloadData()
	return {
		bg                = bg,
		view              = view,
		timeLabel         = timeLabel,
		ruleLabel         = ruleLabel,
		ruleLabelLayout   = ruleLabelLayout,
		listView          = listView ,
		ruleTitleBg       = ruleTitleBg,
		compoundBtn       = compoundBtn,
		cvShareBtn        = cvShareBtn,
		activityNameLabel = activityNameLabel,
	}
end
function ShareCV2EnterView:ctor( ... )
	self.viewData_ = CreateView()
	display.commonUIParams(self.viewData_.view, {po = cc.p(0,0), ap = display.LEFT_BOTTOM})
	self:addChild(self.viewData_.view, 1)
end

function ShareCV2EnterView:setTimeLabel(seconds)
	local viewData = self.viewData_
	local timeLabel = viewData.timeLabel
	timeLabel:setString(CommonUtils.getTimeFormatByType(seconds))
end

function ShareCV2EnterView:UpdateRuleLable(detail)
	local viewData = self.viewData_
	local ruleLabel = viewData.ruleLabel
	if string.len(detail) > 0 then
		ruleLabel:setString(detail)
		local ruleSize = display.getLabelContentSize(ruleLabel)
		viewData.ruleLabelLayout:setContentSize(ruleSize)
		ruleLabel:setPositionY(ruleSize.height)
		viewData.listView:reloadData()
	end
end

function ShareCV2EnterView:UpdateActivityNameLabel(title)
	local viewData = self.viewData_
	local activityNameLabel = viewData.activityNameLabel
	if string.len(title) > 0 then
		activityNameLabel:setString(title)
	end
end
return ShareCV2EnterView