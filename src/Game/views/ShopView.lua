--[[

--]]
local GameScene = require( "Frame.GameScene" )

local ShopView = class('ShopView', GameScene)
local GoodPurchaseNode = require('common.GoodPurchaseNode')


function ShopView:ctor( ... )
    -- GameScene.ctor(self,'views.ShopView')
     local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 100))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setAnchorPoint(cc.p(0.5, 1.0))
    eaterLayer:setPosition(cc.p(display.cx, display.height))-- - NAV_BAR_HEIGHT
    self:addChild(eaterLayer, -1)


	self.viewData = nil

	local function CreateView( ... )
        local view = CLayout:create(display.size)
        display.commonUIParams(view, {po = display.center})
        self:addChild(view)

        local bg = display.newImageView(_res('arts/stage/bg/main_bg_03'), display.cx, display.cy, {isFull = true})
        view:addChild(bg)

        local bg1 = display.newImageView(_res('ui/home/commonShop/shop_bg_add'), display.cx - 44, display.height - 70, {ap = display.CENTER_TOP})
        view:addChild(bg1)
        local tabNameLabel = display.newButton(display.SAFE_L + 130, display.size.height + 2 ,{n = _res('ui/common/common_title.png'),enable = false,ap = cc.p(0, 1)})
        display.commonLabelParams(tabNameLabel, {ttf = true, font = TTF_GAME_FONT, text = __('商 城'), fontSize = 30, color = '473227',offset = cc.p(0,-8)})
        view:addChild(tabNameLabel,5)

        local commonLayout = CLayout:create(cc.size(display.width,580))-- 848
        commonLayout:setAnchorPoint(cc.p(0,1))
        commonLayout:setPosition(cc.p(display.cx - 420,display.size.height - 134))
        view:addChild(commonLayout,1)

        local backBtn = display.newButton(0, 0, {n = _res("ui/common/common_btn_back.png")})
        display.commonUIParams(backBtn, {po = cc.p(display.SAFE_L + backBtn:getContentSize().width * 0.5 + 30, display.height - 18 - backBtn:getContentSize().height * 0.5)})
        self:addChild(backBtn, 5)


        local bgSize = cc.size(display.width, 80)
        local moneyNode = CLayout:create(bgSize)
        display.commonUIParams(moneyNode, {ap = display.CENTER_TOP, po = cc.p(display.cx, display.height)})
        self:addChild(moneyNode,100)

        -- top icon
        local imageImage = display.newImageView(_res('ui/home/nmain/main_bg_money.png'),0,0,{enable = false,
        scale9 = true, size = cc.size(860 + (display.width - display.SAFE_R),54)})
        display.commonUIParams(imageImage,{ap = cc.p(1.0,1.0), po = cc.p(display.width,80)})
        moneyNode:addChild(imageImage)
        local moneyNods = {}
        local moneyNodsIdx = {}
        local iconData =  {TIPPING_ID, HP_ID, GOLD_ID, DIAMOND_ID}
        for i,v in ipairs(iconData) do
            local isShowHpTips = (v == HP_ID) and 1 or -1
            local purchaseNode = GoodPurchaseNode.new({id = v, animate = true, isShowHpTips = isShowHpTips})
            display.commonUIParams(purchaseNode,
            {ap = cc.p(1, 0.5), po = cc.p(display.SAFE_R - 20 - (( 4 - i) * (purchaseNode:getContentSize().width + 16)), imageImage:getPositionY()- 26)})
            moneyNode:addChild(purchaseNode, 5)
            purchaseNode:setName('purchaseNode' .. i)
            purchaseNode.viewData.touchBg:setTag(checkint(v))
            moneyNods[tostring( v )] = purchaseNode
            moneyNodsIdx[i] = purchaseNode
        end


        local chooseShopTypeLayout = CLayout:create(cc.size(196,576))
        chooseShopTypeLayout:setAnchorPoint(cc.p(0.5,1))
        chooseShopTypeLayout:setPosition(cc.p(display.cx - 510, display.size.height - 134))
        view:addChild(chooseShopTypeLayout)
        -- chooseShopTypeLayout:setBackgroundColor(cc.c4b(200, 0, 0, 100))

        local tempbg = display.newImageView(_res('ui/home/commonShop/shop_bg_liebiao.png'),20,0)
        tempbg:setAnchorPoint(cc.p(0,0))
        chooseShopTypeLayout:addChild(tempbg)
        -- tempbg:setFlippedX(true)

        local ListBgFrameSize = tempbg:getContentSize()
        --添加列表功能
        local taskListSize = cc.size(142, ListBgFrameSize.height - 4)
        local taskListCellSize = cc.size(140 , 92)

        local gridView = CGridView:create(taskListSize)
        gridView:setSizeOfCell(taskListCellSize)
        gridView:setColumns(1)
        gridView:setAutoRelocate(true)
        chooseShopTypeLayout:addChild(gridView,1)
        gridView:setAnchorPoint(cc.p(0, 0))
        gridView:setPosition(cc.p(tempbg:getPositionX() + 18, tempbg:getPositionY() + 2 ))
        -- gridView:setBackgroundColor(cc.c4b(0, 100, 0, 100))

        local upImg = display.newImageView(_res('ui/home/commonShop/shop_img_up.png'),20,ListBgFrameSize.height - 1)
        upImg:setAnchorPoint(cc.p(0,1))
        chooseShopTypeLayout:addChild(upImg,2)

        local downImg = display.newImageView(_res('ui/home/commonShop/shop_img_down.png'),22,0)
        downImg:setAnchorPoint(cc.p(0,0))
        chooseShopTypeLayout:addChild(downImg,2)

        return {
            view = view,
            commonLayout = commonLayout,
            gridView = gridView,
            backBtn = backBtn,
            moneyNods = moneyNods,
            moneyNodsIdx = moneyNodsIdx,
            tabNameLabel = tabNameLabel,
            tabNameLabelPos = cc.p(tabNameLabel:getPosition()),
        }
	end
    self.viewData = CreateView( )

    self.viewData.tabNameLabel:setPositionY(display.height + 100)
    local action = cc.EaseBounceOut:create(cc.MoveTo:create(1, self.viewData.tabNameLabelPos))
    self.viewData.tabNameLabel:runAction( action )

    self:RefreshTopGoodsPurchaseNode()
end

--[[
刷新顶部3+1的1
@params goodsId int 道具id
--]]
function ShopView:RefreshTopGoodsPurchaseNode(goodsId)
    local purchaseNode = self.viewData.moneyNodsIdx[1]
    if nil == goodsId then
        purchaseNode:setVisible(false)
    else
        local preGoodsId = purchaseNode.viewData.touchBg:getTag()
        self.viewData.moneyNods[tostring(preGoodsId)] = nil
        self.viewData.moneyNods[tostring(goodsId)] = purchaseNode
        purchaseNode.viewData.touchBg:setTag(checkint(goodsId))
        purchaseNode.args.id = goodsId
        purchaseNode:setVisible(true)
        purchaseNode:RefershUI(goodsId)
    end
end


return ShopView
