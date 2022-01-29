--[[
爱心便当活动view
--]]
local ActivityHoneyBentoView = class('ActivityHoneyBentoView', function ()
	local node = CLayout:create(cc.size(1035, 637))
	node:setAnchorPoint(cc.p(0, 0))
	node.name = 'home.ActivityHoneyBentoView'
	node:enableNodeEvents()
	return node
end)
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local function CreateView( )
	local size = cc.size(1035, 637)
	local view = CLayout:create(size)
	-- 背景
	local bg = display.newImageView(_res('ui/home/activity/activity_bg_love_lunch.png'), size.width/2, size.height/2)
	view:addChild(bg, 1)
	-- 活动规则
	--local ruleTitleBg = display.newImageView(_res('ui/home/activity/activity_exchange_bg_rule_title.png'), 10, 164, {scale9 = true, ap =display.LEFT_CENTER })
	--view:addChild(ruleTitleBg, 5)
	--local ruleTitleLabel = display.newLabel(20, 168, {text = __('活动规则') ,ap =display.LEFT_CENTER, fontSize = 26, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#3c1e0e', outlineSize = 1})
	--view:addChild(ruleTitleLabel, 10)

	--local ruleTitleLabelSize = display.getLabelContentSize(ruleTitleLabel)
	--local ruleTitleBgSize = ruleTitleBg:getContentSize()
	--if ruleTitleLabelSize.width + 40 > ruleTitleBgSize.width then
	--	ruleTitleBg:setContentSize(cc.size(ruleTitleLabelSize.width + 40, ruleTitleBgSize.height))
	--end
	local ruleTitleBg  = display.newButton(20,170, { n = _res('ui/home/activity/activity_exchange_bg_rule_title.png') ,enable = true , scale9 = true , ap = display.LEFT_CENTER  } )
	display.commonLabelParams(ruleTitleBg, fontWithColor('14',{text= __('活动规则') , offset = cc.p( -15, 0) ,paddingW = 30}) )
	view:addChild(ruleTitleBg, 9 )

	local ruleBg = display.newImageView(_res('ui/home/activity/activity_exchange_bg_rule.png'), size.width/2, 3, {ap = cc.p(0.5, 0)})
	view:addChild(ruleBg, 5)

	local ruleLabel = display.newLabel(34, 142, { ap = display.CENTER, fontSize = 24, color = '#ffffff', w = 970})
	--view:addChild(ruleLabel, 10)
	local ruleSize = display.getLabelContentSize( ruleLabel)
	local ruleLayout  = display.newLayer(34, 142,{size = ruleSize ,ap = cc.p(0, 1)})
	ruleLayout:addChild(ruleLabel,10)
	ruleLabel:setPosition(ruleSize.width/2 ,ruleSize.height/2)
	local listViewSize = cc.size(970 , 130)
	local listView = CListView:create(listViewSize)
	listView:setBounceable(true )
	listView:setDirection(eScrollViewDirectionVertical)
	listView:setAnchorPoint(display.LEFT_TOP)
	listView:setPosition(cc.p(50, 142))
	view:addChild(listView  , 10 )
	listView:insertNodeAtLast(ruleLayout)



    local gridViewSize = cc.size(672, 482)
    local gridViewCellSize = cc.size(224, 482)
    local gridView = CTableView:create(gridViewSize)
    gridView:setAnchorPoint(cc.p(1, 0.5))   
    gridView:setDirection(eScrollViewDirectionHorizontal)
    gridView:setSizeOfCell(gridViewCellSize)
    gridView:setPosition(cc.p(size.width - 8, 392))  
    gridView:setBounceable(false)
    gridView:setAutoRelocate(true)
    view:addChild(gridView, 10)

	return {
		view       = view,
		ruleLabel  = ruleLabel,
		listView   = listView,
		ruleLayout = ruleLayout,
		gridView   = gridView
	}
end

function ActivityHoneyBentoView:ctor( ... )
	self.viewData_ = CreateView()
	self:addChild(self.viewData_.view, 1)
	self.viewData_.view:setPosition(utils.getLocalCenter(self))
end

function ActivityHoneyBentoView:setRuleText(ruleText)
	local ruleLabel = self.viewData_.ruleLabel
	if ruleLabel then
		local ruleLayout = self.viewData_.ruleLayout
		local listView = self.viewData_.listView
		display.commonLabelParams(ruleLabel, {text = tostring(ruleText)})
		local ruleLabelSize = display.getLabelContentSize(ruleLabel)

		ruleLayout:setContentSize(ruleLabelSize)
		ruleLabel:setPosition(ruleLabelSize.width/2 ,ruleLabelSize.height/2)
		listView:reloadData()
	end
end

return ActivityHoneyBentoView