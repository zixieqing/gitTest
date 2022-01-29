--[[
    通用 活动页
    @params bg 默认背景
    @params ruleBg 规则背景
--]]
local CommonBaseActivityView = class('CommonBaseActivityView', function ()
	local node = CLayout:create(cc.size(1035, 637))
	node:setAnchorPoint(cc.p(0, 0))
	node.name = 'common.CommonBaseActivityView'
	node:enableNodeEvents()
	return node
end)

local CreateView    = nil

function CommonBaseActivityView:ctor( ... )
	local args = unpack({...}) or {}
	self.tag = checktable(args).tag
	self.showFullRule = checktable(args).showFullRule or false -- 规则栏是否全屏
    self.viewData_ = CreateView(args)
    display.commonUIParams(self.viewData_.view, {po = cc.p(0,0), ap = display.LEFT_BOTTOM})
    self:addChild(self.viewData_.view, 1)
end

CreateView = function (args)
    local size = cc.size(1035, 637)
	local view = CLayout:create(size)
	
	-- 背景
	local bg = lrequire('root.WebSprite').new({url = '', hpath = args.bg or _res('ui/home/activity/activity_bg_loading.jpg'), tsize = cc.size(1028,630)})
    bg:setAnchorPoint(display.CENTER)
    bg:setPosition(cc.p(size.width/2, size.height/2))
	view:addChild(bg, 1)
    
    -- local titleBg = args.titleBg
	-- local title = display.newImageView(titleBg, 754, 524)
	-- title:setVisible(titleBg ~= nil)
	-- view:addChild(title, 5)

	local timeBg = display.newImageView(_res('ui/home/activity/activity_time_bg.png'), 1030, 600, {ap = display.RIGHT_CENTER})
	local timeBgSize = timeBg:getContentSize()
	view:addChild(timeBg, 5)
	local timeTitleLabel = display.newLabel(140, timeBgSize.height / 2, fontWithColor(18, {text = args.timeTitle, ap = display.RIGHT_CENTER}))
	local timeTitleLabelSize = display.getLabelContentSize(timeTitleLabel)
	timeBg:addChild(timeTitleLabel, 10)
	local timeLabel = display.newLabel(timeTitleLabel:getPositionX() + 5, timeTitleLabel:getPositionY(), {text = '', ap = cc.p(0, 0.5), fontSize = 22, color = '#ffe9b4', font = TTF_GAME_FONT, ttf = true, outline = '#3c1e0e', outlineSize = 1})
    timeBg:addChild(timeLabel, 10)
    
    local timeTipLabel = display.newLabel(timeBgSize.width / 2, timeBgSize.height / 2, fontWithColor(18, {ap = display.CENTER}))
    timeBg:addChild(timeTipLabel, 10)
    timeTipLabel:setVisible(false)

	-- 活动规则
	--local ruleTitleBg = display.newImageView(_res('ui/home/activity/activity_exchange_bg_rule_title.png'), 100, 164)
	--view:addChild(ruleTitleBg, 5)
	--local ruleTitleLabel = display.newLabel(88, 168, {text = __('活动规则'), fontSize = 26, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#3c1e0e', outlineSize = 1})
	--view:addChild(ruleTitleLabel, 10)
	local ruleTitleLabel = display.newButton( 20, 164 , { n = _res('ui/home/activity/activity_exchange_bg_rule_title.png'), ap = display.LEFT_CENTER , scale9 = true})
	display.commonLabelParams( ruleTitleLabel , {offset = cc.p(-10,0), text = __('活动规则'), fontSize = 26, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#3c1e0e', outlineSize = 1 ,paddingW = 30 })
	view:addChild(ruleTitleLabel, 10)
	local ruleBg = display.newImageView(args.ruleBg or _res('ui/home/activity/tagMatch/activity_3v3_bg_rule.png'), 3, 3, {ap = display.LEFT_BOTTOM})
	view:addChild(ruleBg, 5)

	local scrollViewSize  = cc.size(756, 120)
	if args.showFullRule then
		scrollViewSize.width = 1000
	end
	local scrollView = cc.ScrollView:create()
    scrollView:setPosition(cc.p(20, 15))
	scrollView:setDirection(eScrollViewDirectionVertical)
	scrollView:setAnchorPoint(display.LEFT_CENTER)
    scrollView:setViewSize(scrollViewSize)
	view:addChild(scrollView, 5)
    
    local ruleLabel = display.newLabel(0, scrollViewSize.height, {hAlign = display.TAL, fontSize = 24, color = '#ffffff', w = scrollViewSize.width})
    scrollView:setContainer(ruleLabel)
    
	return {
		bg              = bg,
		view 	        = view,
		timeLabel       = timeLabel,
        timeTitleLabel  = timeTitleLabel,
        timeTipLabel    = timeTipLabel,
        scrollView      = scrollView,
        ruleLabel       = ruleLabel,
	}
end

function CommonBaseActivityView:setBackground(backgroundImage)
	local viewData = self:getViewData()
    local bg = viewData.bg
	bg:setWebURL(backgroundImage)
end

function CommonBaseActivityView:setTimeTitleLabel(timeTitle)
    local viewData = self:getViewData()
    local timeTitleLabel = viewData.timeTitleLabel
    display.commonLabelParams(timeTitleLabel, {text = timeTitle ,reqW = 150 })
end

function CommonBaseActivityView:setTimeLabel(seconds)
    local viewData = self:getViewData()
    local timeLabel = viewData.timeLabel
    timeLabel:setString(CommonUtils.getTimeFormatByType(seconds))
	display.commonLabelParams(timeLabel , {text = CommonUtils.getTimeFormatByType(seconds) , reqW = 120})
end

function CommonBaseActivityView:setRule(rule)
    if rule == nil then return end

    local viewData = self:getViewData()
    local ruleLabel = viewData.ruleLabel
    display.commonLabelParams(ruleLabel, {text = rule})
    
    local ruleLabelSize = display.getLabelContentSize(ruleLabel)

    local scrollView  = viewData.scrollView
    local descrScrollTop = scrollView:getViewSize().height - ruleLabelSize.height
	scrollView:setContentOffset(cc.p(0, descrScrollTop))
    
end

function CommonBaseActivityView:getViewData()
    return self.viewData_
end

return CommonBaseActivityView