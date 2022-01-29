--[[
 * author : liuzhipeng
 * descpt : KFC签到活动 View
--]]
local ActivityKFCView = class('ActivityKFCView', function ()
	local node = CLayout:create(cc.size(1035, 637))
	node:setAnchorPoint(cc.p(0, 0))
	node.name = 'activity.ActivityKFCView'
	node:enableNodeEvents()
	return node
end)
local RES_DICT = {
	LOADING_BG      = _res('ui/home/activity/activity_bg_loading.jpg'),
	TIME_BG 	    = _res('ui/home/activity/activity_time_bg.png'),
	BUTTON_BG 	    = _res('ui/home/activity/novice_recharge_btn_bg.png'),
	BUTTON_N 	 	= _res('ui/common/common_btn_big_orange.png'),
	RULE_TITLE  	= _res('ui/home/activity/activity_exchange_bg_rule_title.png'),
	RULE_BG	        = _res('ui/home/activity/activity_exchange_bg_rule.png'),
	REWARD_BG 	    = _res('ui/home/activity/activity_bg_prop.png'),
	REWAED_TITLE 	= _res('ui/common/common_title_5.png'),
	REWARD_LIST_BG	= _res('ui/common/common_bg_list.png'),

	CELL_GOODS_MASK = _res('ui/home/activity/common_frame_goods_lock.png'),
	CELL_GOODS_MARK = _res('ui/home/activity/common_arrow1.png'),

}
local CreateView    = nil
local CreateRewardCell = nil 
function ActivityKFCView:ctor( ... )
	local args = unpack({...}) or {}
    self.viewData_ = CreateView()
    display.commonUIParams(self.viewData_.view, {po = cc.p(0,0), ap = display.LEFT_BOTTOM})
    self:addChild(self.viewData_.view, 1)
end

CreateView = function ()
    local size = cc.size(1035, 637)
	local view = CLayout:create(size)
	
	-- 背景
	local bg = lrequire('root.WebSprite').new({url = '', RES_DICT.LOADING_BG, tsize = cc.size(1028,630)})
    bg:setAnchorPoint(display.CENTER)
    bg:setPosition(cc.p(size.width/2, size.height/2))
	view:addChild(bg, 1)

	local timeBg = display.newImageView(RES_DICT.TIME_BG, 1030, 600, {ap = display.RIGHT_CENTER})
	local timeBgSize = timeBg:getContentSize()
	view:addChild(timeBg, 5)
	local timeTitleLabel = display.newLabel(135, timeBgSize.height / 2, fontWithColor(18, {text = __('剩余时间:'), ap = display.RIGHT_CENTER}))
	local timeTitleLabelSize = display.getLabelContentSize(timeTitleLabel)
	timeBg:addChild(timeTitleLabel, 10)
	local timeLabel = display.newLabel(timeTitleLabel:getPositionX() + 5, timeTitleLabel:getPositionY(), {text = '', ap = cc.p(0, 0.5), fontSize = 22, color = '#ffe9b4', font = TTF_GAME_FONT, ttf = true, outline = '#3c1e0e', outlineSize = 1})
    timeBg:addChild(timeLabel, 10)

	-- 奖励预览
	local rewardLayerSize = cc.size(522, 223)
	local rewardLayer = display.newLayer(736, 374, {ap = display.CENTER, size = rewardLayerSize})
	view:addChild(rewardLayer, 2)
	local rewardTitle = display.newButton(rewardLayerSize.width/2, rewardLayerSize.height - 10, {n = RES_DICT.REWAED_TITLE, enable = false, ap = display.CENTER_TOP})
	display.commonLabelParams(rewardTitle, fontWithColor(4, {text = __('签 到')}))
	rewardLayer:addChild(rewardTitle)
	local rewardBgImg = display.newImageView(RES_DICT.REWARD_BG, rewardLayerSize.width/2, 0, {ap = display.CENTER_BOTTOM, scale9 = true, size = rewardLayerSize})
	rewardLayer:addChild(rewardBgImg)
	local rewrdListSize = cc.size(483, 149)
	local rewrdListCellSize = cc.size(rewrdListSize.width / 5, rewrdListSize.height)
	local rewardListBg = display.newImageView(RES_DICT.REWARD_LIST_BG, rewardLayerSize.width / 2, 10, {ap = display.CENTER_BOTTOM, scale9 = true, size = cc.size(rewrdListSize.width + 10, rewrdListSize.height)})
	rewardLayer:addChild(rewardListBg, 3)
    local gridView = CTableView:create(rewrdListSize)
	gridView:setSizeOfCell(rewrdListCellSize)
	gridView:setBounceable(false)
    gridView:setDirection(eScrollViewDirectionHorizontal)
    gridView:setAnchorPoint(display.CENTER_BOTTOM)
    gridView:setPosition(cc.p(rewardLayerSize.width / 2, 10))
    rewardLayer:addChild(gridView, 5)
	-- 跳转按钮
	local enterBtn = display.newButton(736, 191, {ap = display.CENTER, n = RES_DICT.BUTTON_N})
	view:addChild(enterBtn, 10)
	display.commonLabelParams(enterBtn, fontWithColor(14, {text = __('前往签到')}))
	-- local redPoint = display.newImageView(_res('ui/common/common_hint_circle_red_ico.png'), enterBtn:getContentSize().width-20, enterBtn:getContentSize().height-15)
	-- redPoint:setName('BTN_RED_POINT')
	-- redPoint:setVisible(false)
    -- enterBtn:addChild(redPoint)
    
    -- 活动规则
	ruleLayoutSize = cc.size(size.width, 192)
	local ruleLayout = CLayout:create(ruleLayoutSize)
	display.commonUIParams(ruleLayout, {po = cc.p(size.width/2, 0), ap = cc.p(0.5, 0)})
	view:addChild(ruleLayout, 10)
	local ruleTitleBg = display.newImageView(RES_DICT.RULE_TITLE, 100, 164)
	ruleLayout:addChild(ruleTitleBg, 5)
	local ruleTitleLabel = display.newLabel(88, 168, {text = __('活动规则'), fontSize = 26, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#3c1e0e', outlineSize = 1})
	ruleLayout:addChild(ruleTitleLabel, 10)
	local ruleBg = display.newImageView(RES_DICT.RULE_BG, size.width/2, 3, {ap = cc.p(0.5, 0)})
	ruleLayout:addChild(ruleBg, 5)
	local ruleLabel = display.newLabel(34, 142, {ap = cc.p(0, 1), text = __('活动规则'), fontSize = 24, color = '#ffffff', w = 970})
	ruleLayout:addChild(ruleLabel, 10)
    
	return {
		bg              = bg,
		view 	        = view,
		timeLabel       = timeLabel,
        ruleLabel       = ruleLabel,
		enterBtn        = enterBtn,
		gridView        = gridView,
		rewrdListCellSize = rewrdListCellSize,
	}
end

--[[
创建列表cell
--]]
CreateRewardCell = function(size)
    local view = CTableViewCell:new()
	view:setContentSize(size)
	local timeRichLabel = display.newRichLabel(size.width / 2, size.height - 26)
	view:addChild(timeRichLabel, 1)
	local goodsNode = require('common.GoodNode').new({id = GOLD_ID, amount = 1, showAmount = true, callBack = function() end})
	goodsNode:setScale(0.8)
	goodsNode:setPosition(cc.p(size.width / 2, 60))
	view:addChild(goodsNode, 3)
	local mask = display.newImageView(RES_DICT.CELL_GOODS_MASK, size.width / 2, 60)
	view:addChild(mask, 4)
	local mark = display.newImageView(RES_DICT.CELL_GOODS_MARK, mask:getContentSize().width / 2, mask:getContentSize().height / 2)
	mask:addChild(mark, 1)
    return {
		view          = view,
		timeRichLabel = timeRichLabel,
		goodsNode     = goodsNode,
		mask          = mask,
    }
end

function ActivityKFCView:setBackground(backgroundImage)
	local viewData = self:getViewData()
    local bg = viewData.bg
	bg:setWebURL(backgroundImage)
end

function ActivityKFCView:setTimeLabel(seconds)
    local viewData = self:getViewData()
    local timeLabel = viewData.timeLabel
    timeLabel:setString(CommonUtils.getTimeFormatByType(seconds))
end

function ActivityKFCView:setRule(rule)
    if rule == nil then return end

    local viewData = self:getViewData()
    local ruleLabel = viewData.ruleLabel
    display.commonLabelParams(ruleLabel, {text = rule})
end

function ActivityKFCView:createRewardCell(size)
    return CreateRewardCell(size)
end
function ActivityKFCView:getViewData()
    return self.viewData_
end

return ActivityKFCView