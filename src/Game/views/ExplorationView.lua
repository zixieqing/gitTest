--[[
探索系统UI
--]]
local GameScene = require( "Frame.GameScene" )

local ExplorationView = class('ExplorationView', GameScene)
local GoodPurchaseNode = require('common.GoodPurchaseNode')

function ExplorationView:ctor( ... )
	self.viewData_ = nil
	local function CreateView()
		local view = CLayout:create(display.size)
    	view:setAnchorPoint(display.CENTER)

		-- 重写顶部状态条
    	local bgSize = cc.size(display.width, 80)
    	local moneyNode = CLayout:create(bgSize)
    	moneyNode:setName('TOP_LAYOUT')
    	display.commonUIParams(moneyNode, {ap = display.CENTER_TOP, po = cc.p(display.cx, display.height)})
    	view:addChild(moneyNode,100)

    	local backBtn = display.newButton(0, 0, {n = _res("ui/common/common_btn_back")})
    	display.commonUIParams(backBtn, {po = cc.p(backBtn:getContentSize().width * 0.5 + 30 + display.SAFE_L, bgSize.height - 18 - backBtn:getContentSize().height * 0.5)})
    	backBtn:setName('btn_backButton')
    	moneyNode:addChild(backBtn, 5)
    	-- top icon
    	local imageImage = display.newImageView(_res('ui/home/nmain/main_bg_money.png'),0,0,{enable = false,
    	scale9 = true, size = cc.size(680,54)})
    	display.commonUIParams(imageImage,{ap = cc.p(1.0,1.0), po = cc.p(display.width,80)})
    	moneyNode:addChild(imageImage)
    	local moneyNods = {}
    	local iconData = {HP_ID, GOLD_ID, DIAMOND_ID}
    	local len = #iconData
    	for i,v in ipairs(iconData) do
			local isShowHpTips = (v == HP_ID) and 1 or -1
    	    local purchaseNode = GoodPurchaseNode.new({id = v, isShowHpTips = isShowHpTips})
    	    display.commonUIParams(purchaseNode,
    	    {ap = cc.p(1, 0.5), po = cc.p(bgSize.width - 20 - (( len - i) * (purchaseNode:getContentSize().width + 16)), imageImage:getPositionY()- 26)})
    	    moneyNode:addChild(purchaseNode, 5)
    	    purchaseNode:setName('purchaseNode' .. i)
    	    purchaseNode.viewData.touchBg:setTag(checkint(v))
    	    moneyNods[tostring( v )] = purchaseNode
    	end
		return {
			view 			= view,
			backBtn         = backBtn,
			moneyNods       = moneyNods
		}
	end

	local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 100))
	eaterLayer:setTouchEnabled(true)
	eaterLayer:setContentSize(display.size)
	eaterLayer:setAnchorPoint(cc.p(0.5, 1.0))
	eaterLayer:setPosition(cc.p(display.cx, display.height))
	self:addChild(eaterLayer, -10)
	self.viewData_ = CreateView()
	display.commonUIParams(self.viewData_.view, {po = display.center})
	self:addChild(self.viewData_.view, 1)
end

function ExplorationView:onCleanup()
    display.removeUnusedSpriteFrames()
end

return ExplorationView
