--[[
活动副本地图的界面
@params table {
}
--]]
local GameScene = require('Frame.GameScene')
local ActivityMapView = class('ActivityMapView', GameScene)
-- local ActivityMapView = class('ActivityMapView', function ()
-- 	local node = CLayout:create(display.size)
-- 	node.name = 'Game.views.activityMap.ActivityMapView'
-- 	node:enableNodeEvents()
-- 	return node
-- end)
local GoodPurchaseNode = require('common.GoodPurchaseNode')
---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
constructor
--]]
function ActivityMapView:ctor( )
	self.viewData = nil
	self:InitUI()
end
--[[
init ui
--]]
function ActivityMapView:InitUI()
	
	local function CreateView()

		local size = self:getContentSize()
		
		-- 返回按钮
		local backBtn = display.newButton(0, 0, {n = _res("ui/common/common_btn_back.png")})
		display.commonUIParams(backBtn, {po = cc.p(display.SAFE_L + backBtn:getContentSize().width * 0.5 + 30, display.height - 18 - backBtn:getContentSize().height * 0.5)})
		self:addChild(backBtn, 20)
        backBtn:setName('BACK_BTN')

		-- 标题版
		local tabNameLabel = display.newButton(display.SAFE_L + 130, display.height, {n = _res('ui/common/common_title_new.png'),enable = true,ap = cc.p(0, 1)})
		display.commonLabelParams(tabNameLabel, {ttf = true, font = TTF_GAME_FONT, text = '', fontSize = 30, color = '473227',offset = cc.p(- 10, -2)})
		self:addChild(tabNameLabel, 20)
		local tabtitleTips = display.newImageView(_res('ui/common/common_btn_tips.png'), 270, 28)
		tabNameLabel:addChild(tabtitleTips, 1)

		-- 地图page view
		local pageSize = self:getContentSize()
		local mapPageView = CPageView:create(pageSize)
		mapPageView:setAnchorPoint(cc.p(0.5, 0.5))
		mapPageView:setPosition(cc.p(pageSize.width * 0.5, pageSize.height * 0.5))
		mapPageView:setDirection(eScrollViewDirectionHorizontal)
		mapPageView:setSizeOfCell(pageSize)
        mapPageView:setName('CPAGE_VIEW')
		mapPageView:setBounceable(false)
		mapPageView:setDragable(false)
		mapPageView:setAutoRelocate(false)
		self:addChild(mapPageView, 3)

		-- 翻页按钮
		local prevBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_switch_right.png')})
		prevBtn:setScaleX(-1)
		prevBtn:setVisible(false)
		display.commonUIParams(prevBtn, {po = cc.p(display.SAFE_L + 15 + prevBtn:getContentSize().width * 0.5, size.height * 0.5)})
		self:addChild(prevBtn, 20)
		prevBtn:setTag(2001)
		local nextBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_switch_right.png')})
		nextBtn:setVisible(false)
		display.commonUIParams(nextBtn, {po = cc.p(display.SAFE_R - 15 - nextBtn:getContentSize().width * 0.5, size.height * 0.5)})
		self:addChild(nextBtn, 20)
		nextBtn:setTag(2002)
		-- 重置剧情 -- 
		local resetBg = display.newImageView(_res('ui/home/activity/activityQuest/activity_maps_bg_all_reflesh.png'), 0, 0)
		local resetLayoutSize = resetBg:getContentSize()
		local resetLayout = CLayout:create(resetLayoutSize)
		display.commonUIParams(resetLayout, {po = cc.p(display.SAFE_L, 20), ap = cc.p(0, 0)})
		self:addChild(resetLayout, 5)
		resetBg:setPosition(cc.p(resetLayoutSize.width/2, resetLayoutSize.height/2))
		resetLayout:addChild(resetBg, 1)
		local resetBtn = display.newButton(90, 70, {n = _res('ui/common/common_btn_green.png'), scale9 = true ,size =  cc.size(180, 60 ) })
		resetLayout:addChild(resetBtn, 1)
		display.commonLabelParams(resetBtn, fontWithColor(14, {text = __('重置剧情') , reqW = 160}))
		local resetTipsBtn = display.newButton(207, 70, {n = _res('ui/common/common_btn_tips.png')})
		resetLayout:addChild(resetTipsBtn, 1)
		local resetCost = display.newLabel(105, 23, {text = '240', ap = cc.p(1, 0.5), fontSize = 22, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#5e3c25', outlineSize = 1})
		resetLayout:addChild(resetCost, 1)
		local resetIcon = display.newImageView(_res(CommonUtils.GetGoodsIconPathById(DIAMOND_ID)),  110, 23, {ap = cc.p(0, 0.5), scale = 0.2})
		resetLayout:addChild(resetIcon, 1)
		resetLayout:setVisible(false)


		-- 重写顶部状态条 --
    	local topLayoutSize = cc.size(display.width, 80)
    	local moneyNode = CLayout:create(topLayoutSize)
    	moneyNode:setName('TOP_LAYOUT')
    	display.commonUIParams(moneyNode, {ap = display.CENTER_TOP, po = cc.p(display.cx, display.height)})
    	self:addChild(moneyNode,100)
    	-- top icon
	    local imageImage = display.newImageView(_res('ui/home/nmain/main_bg_money.png'),0,0,{enable = false,
		scale9 = true, size = cc.size(680 + (display.width - display.SAFE_R),54)})
    	display.commonUIParams(imageImage,{ap = cc.p(1.0,1.0), po = cc.p(display.width,80)})
    	moneyNode:addChild(imageImage)
    	local moneyNods = {}
    	local iconData = {ACTIVITY_QUEST_HP, GOLD_ID, DIAMOND_ID}
    	for i,v in ipairs(iconData) do
			local isShowHpTips = (v == HP_ID) and 1 or -1
    	    local purchaseNode = GoodPurchaseNode.new({id = v, isShowHpTips = isShowHpTips})
    	    display.commonUIParams(purchaseNode,
    	    {ap = cc.p(1, 0.5), po = cc.p(topLayoutSize.width - 20 - display.SAFE_L - ((#iconData - i) * (purchaseNode:getContentSize().width + 16)), imageImage:getPositionY()- 26)})
    	    moneyNode:addChild(purchaseNode, 5)
    	    purchaseNode:setName('purchaseNode' .. i)
    	    purchaseNode.viewData.touchBg:setTag(checkint(v))
    	    moneyNods[tostring( v )] = purchaseNode
    	end
        return {
			backBtn         = backBtn,
			tabNameLabel    = tabNameLabel,
			tabNameLabelPos = cc.p(tabNameLabel:getPosition()),
			mapPageView     = mapPageView,
			prevBtn         = prevBtn,
			nextBtn         = nextBtn,
			moneyNods	    = moneyNods,
			resetTipsBtn 	= resetTipsBtn,
			resetBtn        = resetBtn,
			resetLayout     = resetLayout,

		}
	end

	xTry(function ( )
		self.viewData_ = CreateView( )
	end, __G__TRACKBACK__)

	-- 弹出标题板
	self.viewData_.tabNameLabel:setPositionY(display.height + 100)
	local action = cc.EaseBounceOut:create(cc.MoveTo:create(1, self.viewData_.tabNameLabelPos))
	self.viewData_.tabNameLabel:runAction( action )

end
---------------------------------------------------
-- init end --
---------------------------------------------------

return ActivityMapView
