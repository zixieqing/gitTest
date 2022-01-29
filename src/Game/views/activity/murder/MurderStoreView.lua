--[[
 * author : liuzhipeng
 * descpt : 杀人案（19夏活）商店（兑换）view
--]]
local MurderStoreView = class('MurderStoreView', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.activity.murder.MurderStoreView'
	node:enableNodeEvents()
	return node
end)
local GoodPurchaseNode = require('common.GoodPurchaseNode')
local RES_DICT = {
	LIST_BG	 	 	 	 	 	    = app.murderMgr:GetResPath('ui/common/common_bg_goods.png'),
	MONEY_INFO_BAR       		    = app.murderMgr:GetResPath('ui/home/nmain/main_bg_money.png'),
	DOLL_1  	 	 	 	 	 	= app.murderMgr:GetResPath('ui/home/activity/murder/murder_shop_ico_doll_1.png'),
	DOLL_2  	 	 	 	 	 	= app.murderMgr:GetResPath('ui/home/activity/murder/murder_shop_ico_doll_2.png'),
}
local function CreateView( )

	local bg = display.newImageView(app.murderMgr:GetResPath('ui/home/union/guild_shop_bg_white.png'), 0, 0)
	local bgSize = bg:getContentSize()
	local view = CLayout:create(bgSize)
	bg:setPosition(bgSize.width/2, bgSize.height/2 - 5)
	view:addChild(bg, 2)
	local bgFrame = display.newImageView(app.murderMgr:GetResPath('ui/home/union/guild_shop_bg.png'), bgSize.width/2,  bgSize.height/2)
	view:addChild(bgFrame, 1)
	local mask = display.newLayer(bgSize.width/2, bgSize.height/2, {ap = display.CENTER, size = bgSize, enable = true, color = cc.c4b(0,0,0,0)})
	view:addChild(mask, -1)

	local titleBg = display.newButton(bgSize.width/2, bgSize.height + 16, {n = app.murderMgr:GetResPath('ui/home/union/guild_shop_title.png'), enable = false})
	view:addChild(titleBg, 10)
	display.commonLabelParams(titleBg, fontWithColor(18, {text = app.murderMgr:GetPoText(__('交换'))}))
	
	local doll1 = display.newImageView(RES_DICT.DOLL_1, - 100, 100)
	view:addChild(doll1 , 15)
	local doll2 = display.newImageView(RES_DICT.DOLL_2, bgSize.width + 100, 100)
	view:addChild(doll2 , 15)
	app.murderMgr:UpdateNodeVisible(doll2 , "doll2")
	app.murderMgr:UpdateNodeVisible(doll1 , "doll1")

	-- listView
	local listSize = cc.size(bgSize.width - 24, 560)
	local listCellSize = cc.size((listSize.width - 8)/5, listSize.height*0.525)
	local listBg = display.newImageView(RES_DICT.LIST_BG, bgSize.width/2, 10, {ap = cc.p(0.5, 0), scale9 = true, size = listSize, capInsets = cc.rect(10, 10, 487, 113)})
	view:addChild(listBg, 3)
    local gridView = CGridView:create(cc.size(listSize.width - 8, listSize.height))
	gridView:setSizeOfCell(cc.size(listCellSize.width, listCellSize.height - 10))
	gridView:setColumns(5)
	view:addChild(gridView, 10)
	gridView:setAnchorPoint(cc.p(0.5, 0))
	gridView:setPosition(cc.p(bgSize.width/2, listBg:getPositionY()))
	-- top ui layer
    local topUILayer = display.newLayer()
    topUILayer:setPositionY(190)
	-- money barBg
	local moneyBarBg = display.newImageView(app.murderMgr:GetResPath(RES_DICT.MONEY_INFO_BAR), display.width, display.height, {ap = display.RIGHT_TOP, scale9 = true, size = cc.size(1, 54)})
	topUILayer:addChild(moneyBarBg)
	-- money layer
    local moneyLayer = display.newLayer()
    topUILayer:addChild(moneyLayer)
	return {
		view             = view,
		bgSize			 = bgSize,
		listSize 	     = listSize,
		listCellSize 	 = listCellSize,
		gridView 	   	 = gridView,
		topUILayer		  = topUILayer,
		moneyBarBg        = moneyBarBg,
		moneyLayer        = moneyLayer,
	}
end
function MurderStoreView:ctor( ... )
	self.activityDatas = unpack({...}) or {}
	local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 255 * 0.60))
	eaterLayer:setTouchEnabled(true)
	eaterLayer:setContentSize(display.size)
	eaterLayer:setPosition(utils.getLocalCenter(self))
	eaterLayer:setOnClickScriptHandler(function () 
		AppFacade.GetInstance():UnRegsitMediator('MurderStoreMediator')
	end)
	self.eaterLayer = eaterLayer
	self:addChild(eaterLayer, -1)
	self.viewData = CreateView()
	self:addChild(self.viewData.view, 1)
	self.viewData.view:setPosition(cc.p(display.cx, display.cy - 25))
	self:addChild(self.viewData.topUILayer, 1)
	self.viewData.topUILayer:runAction(cc.MoveTo:create(0.4, cc.p(0, 0)))
end
--[[
重载货币栏
--]]
function MurderStoreView:ReloadMoneyBar(moneyIdMap, isDisableGain)
    if moneyIdMap then
        moneyIdMap[tostring(GOLD_ID)]         = nil
        moneyIdMap[tostring(DIAMOND_ID)]      = nil
        moneyIdMap[tostring(PAID_DIAMOND_ID)] = nil
        moneyIdMap[tostring(FREE_DIAMOND_ID)] = nil
    end
    
    -- money data
	local moneyIdList = table.keys(moneyIdMap or {})
	table.sort(moneyIdList, function (a, b) return a > b end)
    -- clean moneyLayer
    local moneyBarBg = self:GetViewData().moneyBarBg
    local moneyLayer = self:GetViewData().moneyLayer
    moneyLayer:removeAllChildren()
    
    -- update moneyLayer
    local MONEY_NODE_GAP = 16
    local moneyLayerSize = moneyLayer:getContentSize()
    local moneryBarSize  = cc.size(20, moneyBarBg:getContentSize().height)
    for i = #moneyIdList, 1, -1 do
        local moneyId = checkint(moneyIdList[i])
        local isDisable = moneyId ~= GOLD_ID and moneyId ~= DIAMOND_ID and isDisableGain
        local moneyNode = GoodPurchaseNode.new({id = moneyId, animate = true, disable = isDisable, isEnableGain = not isDisableGain})
        moneyNode.viewData.touchBg:setTag(checkint(moneyId))
        moneyNode:setPosition(display.SAFE_R - moneryBarSize.width, moneyLayerSize.height - 26)
        moneyNode:setAnchorPoint(display.RIGHT_CENTER)
        moneyNode:setName(moneyId)
        moneyLayer:addChild(moneyNode)

        moneryBarSize.width = moneryBarSize.width + moneyNode:getContentSize().width + MONEY_NODE_GAP
    end

    -- update moneyBarBg
    moneryBarSize.width = 40 + moneryBarSize.width + (display.width - display.SAFE_R)
    moneyBarBg:setContentSize(moneryBarSize)

    -- update money value
    self:UpdateMoneyBar()
end
--[[
更新货币栏
--]]
function MurderStoreView:UpdateMoneyBar()
    for _, moneyNode in ipairs(self:GetViewData().moneyLayer:getChildren()) do
        local moneyId = checkint(moneyNode:getName())
        moneyNode:updataUi(moneyId)
    end
end
function MurderStoreView:GetViewData()
    return self.viewData
end
return MurderStoreView
