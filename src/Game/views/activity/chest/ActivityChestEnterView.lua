--[[
 * author : liuzhipeng
 * descpt : KFC签到活动 View
--]]
---@class ActivityChestEnterView
local ActivityChestEnterView = class('ActivityChestEnterView', function ()
	local node = CLayout:create(cc.size(1035, 637))
	node:setAnchorPoint(cc.p(0, 0))
	node.name = 'activity.ActivityChestEnterView'
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
	--local activityNameLabel = display.newLabel(130 , 435 , fontWithColor(14, { ap = display.LEFT_BOTTOM , fontSize = 40  , outlineSize = 2}))
	--view:addChild(activityNameLabel, 10)
	local gotoBtn = display.newButton(660 , 210 , {n = RES_DICT.COMMON_BTN_ORANGE })
	view:addChild(gotoBtn , 10 )
	display.commonLabelParams(gotoBtn , fontWithColor(14 , {text = __('前往')  , enable = true }))
	--local ruleTitleBg = display.newImageView(RES_DICT.ACTIVITY_EXCHANGE_BG_RULE_TITLE, 100, 164)
	--view:addChild(ruleTitleBg, 5)
	--local ruleTitleLabel = display.newLabel(88, 168, {text = __('活动规则'), fontSize = 26, color = '#ffffff', font = TTF_GAME_FONT , ttf = true, outline = '#3c1e0e', outlineSize = 1})
	--view:addChild(ruleTitleLabel, 10)
	--local ruleBg = display.newImageView(RES_DICT.ACTIVITY_EXCHANGE_BG_RULE, size.width/2, 3, {ap = cc.p(0.5, 0)})
	--view:addChild(ruleBg, 5)
	--local ruleLabel = display.newLabel(30, 134, {ap = display.LEFT_TOP ,fontSize = 24 , w = 970 , hAlign = display.TAL,  color = "#ffffff" , text = ""})
	--view:addChild(ruleLabel, 10)
	local ruleTitleBg  = display.newButton(20,170, { n = _res('ui/home/activity/activity_exchange_bg_rule_title.png') ,enable = true , scale9 = true , ap = display.LEFT_CENTER  } )
	display.commonLabelParams(ruleTitleBg, fontWithColor('14',{text= __('活动规则') , offset = cc.p( -15, 0) ,paddingW = 30}) )
	view:addChild(ruleTitleBg, 9 )
	local ruleBg = display.newImageView(_res('ui/home/activity/activity_exchange_bg_rule.png'), size.width/2, 3, {ap = cc.p(0.5, 0)})
	view:addChild(ruleBg, 5)
	local ruleSize = cc.resize(ruleBg:getContentSize(), 0, -10)
	local ruleScrollView = ui.scrollView({size =  ruleSize, dir = display.SDIR_V, drag = true})
	view:addList(ruleScrollView, 10):alignTo(ruleBg, ui.cc)
	local ruleLabel = display.newLabel(30, 10, {ap = display.LEFT_BOTTOM ,fontSize = 24 , w = 970 , hAlign = display.TAL,  color = "#ffffff" , text = ""})
	ruleScrollView:getContainer():addChild(ruleLabel, 5)
	return {
		bg                = bg,
		view              = view,
		timeLabel         = timeLabel,
		ruleLabel         = ruleLabel,
		ruleTitleBg       = ruleTitleBg,
		gotoBtn           = gotoBtn,
		ruleScrollView    = ruleScrollView,
		ruleSize          = ruleSize,
		--activityNameLabel = activityNameLabel,
	}
end
function ActivityChestEnterView:ctor( ... )
	self.viewData_ = CreateView()
	display.commonUIParams(self.viewData_.view, {po = cc.p(0,0), ap = display.LEFT_BOTTOM})
	self:addChild(self.viewData_.view, 1)
end

function ActivityChestEnterView:SetTimeLabel(seconds)
	local viewData = self.viewData_
	local timeLabel = viewData.timeLabel
	timeLabel:setString(CommonUtils.getTimeFormatByType(seconds))
end

function ActivityChestEnterView:UpdateRuleLable(detail)
	local viewData = self.viewData_
	local ruleLabel = viewData.ruleLabel
	if string.len(detail) > 0 then
		ruleLabel:setString(detail)
		local ruleLabelSize = display.getLabelContentSize(ruleLabel)
		local containerH    = math.max(viewData.ruleSize.height, ruleLabelSize.height + 10)
		viewData.ruleScrollView:setContainerSize(cc.size(viewData.ruleSize.width, containerH))
		viewData.ruleScrollView:setContentOffsetToTop()
		ruleLabel:setPositionY(math.max(viewData.ruleSize.height - ruleLabelSize.height - 5, 5))
	end
end

function ActivityChestEnterView:UpdateActivityNameLabel(title)
	--local viewData = self.viewData_
	--local activityNameLabel = viewData.activityNameLabel
	--if string.len(title) > 0 then
	--	activityNameLabel:setString(title)
	--end
end
return ActivityChestEnterView