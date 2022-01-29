--[[
包厢主题view
--]]
local PrivateRoomThemeView = class('PrivateRoomThemeView', function ()
    local node = CLayout:create(display.size)
    node.name = 'home.PrivateRoomThemeView'
    node:enableNodeEvents()
    return node
end)
local gameMgr = AppFacade.GetInstance():GetManager('GameManager')
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
local RES_DICT = {
    COMMON_BG         = _res('ui/common/common_bg_4.png'),
    LIST_BG           = _res('ui/common/common_bg_goods.png'),
    DESCR_BG          = _res('avatar/ui/avatarShop/avator_goods_bg_preview.png'),
    BUFF_DESCR        = _res('avatar/ui/avatarShop/avator_goods_bg_attibute.png'),
    PRICE_BG          = _res('avatar/ui/avatarShop/shop_package_putong_bg.png'),
    PRICE_BG_ORIG     = _res('avatar/ui/avatarShop/shop_package_putong_bg_2.png'),
    BTN_ORANGE        = _res('ui/common/common_btn_orange.png'),
    BTN_WHITE         = _res('ui/common/common_btn_white_default.png'),
    DISCOUNT_LINE     = _res('ui/home/commonShop/shop_sale_line.png'),

}
function PrivateRoomThemeView:ctor( ... )
    self.args = unpack({...})
    self:InitUI()
end
--[[
init ui
--]]
function PrivateRoomThemeView:InitUI()
    local function CreateView()
        local bgSize = cc.size(1050, 650)
        local view = CLayout:create(bgSize)
        local bg = display.newImageView(RES_DICT.COMMON_BG, 0, 0, {scale9 = true, size = bgSize, enable = true})
        bg:setPosition(cc.p(bgSize.width/2, bgSize.height/2))
        view:addChild(bg, 1)
        -- 列表
        local listSize = cc.size(672, 610)
        local listCellSize = cc.size(listSize.width, 190)
        local listBg = display.newImageView(RES_DICT.LIST_BG, 358, bgSize.height / 2, {scale9 = true, size = listSize})
        view:addChild(listBg, 1)
        local gridView = CGridView:create(listSize)
        gridView:setSizeOfCell(listCellSize)
        gridView:setColumns(1)
        gridView:setAutoRelocate(true)
        view:addChild(gridView, 5)
        gridView:setPosition(cc.p(358, bgSize.height / 2))
        -- 详情 -- 
        local detailsLayoutSize = cc.size(355, bgSize.height)
        local detailsLayout = CLayout:create(detailsLayoutSize)
        display.commonUIParams(detailsLayout, {ap = cc.p(1, 0.5), po = cc.p(bgSize.width, bgSize.height / 2)})
        view:addChild(detailsLayout, 5)
        -- 名称
        local themeNameLabel = display.newLabel(30, detailsLayoutSize.height - 30, fontWithColor(4, {text = '地中海', ap = display.LEFT_TOP}))
        detailsLayout:addChild(themeNameLabel)
        -- 描述
        local descrBg = display.newImageView(RES_DICT.DESCR_BG, detailsLayoutSize.width / 2, detailsLayoutSize.height - 70, {ap = display.CENTER_TOP})
        detailsLayout:addChild(descrBg)
        local descrViewSize  = cc.size(280, 290)
        local descrListView = CListView:create(descrViewSize)
        descrListView:setDirection(eScrollViewDirectionVertical)
        descrListView:setPosition(cc.p(detailsLayoutSize.width/2, detailsLayoutSize.height - 75))
        descrListView:setAnchorPoint(cc.p(0.5, 1))
        detailsLayout:addChild(descrListView, 5)

        local buffDescr = display.newButton(detailsLayoutSize.width / 2, detailsLayoutSize.height - 385, { n = RES_DICT.BUFF_DESCR, enable = false})
        display.commonLabelParams(buffDescr, fontWithColor(5, {text = __('buff描述'), w = 280, hAlign = display.TAC}))
        detailsLayout:addChild(buffDescr, 5)
        -- 详情 -- 
        -- 价格 -- 
        local priceLayoutSize = cc.size(detailsLayoutSize.width, 100)
        local priceLayout = CLayout:create(priceLayoutSize)
        priceLayout:setPosition(detailsLayoutSize.width / 2, 160)
        detailsLayout:addChild(priceLayout, 5)
        local priceBg = display.newImageView(RES_DICT.PRICE_BG,priceLayoutSize.width / 2, priceLayoutSize.height / 2, {scale9 = true, size = cc.size(300, 80)})
        priceLayout:addChild(priceBg, 1)
        local origPriceBg = display.newImageView(RES_DICT.PRICE_BG_ORIG, priceLayoutSize.width / 2, 68, {scale9 = true, size = cc.size(292, 35)})
        priceLayout:addChild(origPriceBg, 3)
        local origPriceTitle = display.newLabel(40, 68, fontWithColor(6, {text = __('原价'), ap = cc.p(0, 0.5)}))
        priceLayout:addChild(origPriceTitle, 5)
        local priceTitle = display.newLabel(40, 30, fontWithColor(6, {text = __('现价'), ap = cc.p(0, 0.5)}))
        priceLayout:addChild(priceTitle, 5)
        local origPriceNum = display.newLabel(110, 68, fontWithColor(15, {text = '1999', ap = cc.p(0, 0.5)}))
        priceLayout:addChild(origPriceNum, 5)
        local priceNum = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '1999')
        priceNum:setAnchorPoint(cc.p(0, 0.5))
        priceNum:setHorizontalAlignment(display.TAR)
        priceNum:setPosition(cc.p(110, 30))
        priceLayout:addChild(priceNum, 5)
        local origCostIcon = display.newImageView(CommonUtils.GetGoodsIconPathById(DIAMOND_ID), origPriceNum:getPositionX() + display.getLabelContentSize(origPriceNum).width + 20, 68)
        origCostIcon:setScale(0.2)
        priceLayout:addChild(origCostIcon, 5)
        local costIcon = display.newImageView(CommonUtils.GetGoodsIconPathById(DIAMOND_ID), priceNum:getPositionX() + priceNum:getContentSize().width + 20, 30)
        costIcon:setScale(0.2)
        priceLayout:addChild(costIcon, 5)
        local discountLine = display.newImageView(RES_DICT.DISCOUNT_LINE, origPriceNum:getPositionX(), 68, {scale9 = true, ap = cc.p(0, 0.5), size = cc.size(display.getLabelContentSize(origPriceNum).width, 2)})
        priceLayout:addChild(discountLine, 5)
        local ownedLabel = display.newLabel(detailsLayoutSize.width / 2, 160, fontWithColor(16, {text = __('已拥有')}))
        detailsLayout:addChild(ownedLabel, 3)
        priceLayout:setVisible(false)
        ownedLabel:setVisible(false)
        -- 价格 -- 
        local previewBtn = display.newButton(90, 50, {n = RES_DICT.BTN_WHITE})
        display.commonLabelParams(previewBtn, fontWithColor(14, {text = __('预览')}))
        detailsLayout:addChild(previewBtn, 5)
        local purchaseBtn = display.newButton(detailsLayoutSize.width - 90, 50, {n = RES_DICT.BTN_ORANGE})
        display.commonLabelParams(purchaseBtn, fontWithColor(14, {text = __('购买')}))
        detailsLayout:addChild(purchaseBtn, 5)
        return {
            view             = view,
            gridView         = gridView,
            listSize         = listSize,
            listCellSize     = listCellSize,
            previewBtn       = previewBtn,
            purchaseBtn      = purchaseBtn,
            themeNameLabel   = themeNameLabel,
            descrListView    = descrListView,
            priceLayout      = priceLayout,
            ownedLabel       = ownedLabel,
            origPriceNum     = origPriceNum,
            priceNum         = priceNum,
            origCostIcon     = origCostIcon,
            costIcon         = costIcon,
            discountLine     = discountLine,
        }
    end
    -- eaterLayer
    local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 255*0.6))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    self:addChild(eaterLayer, -1)
    self.eaterLayer = eaterLayer
    xTry(function ( )
        self.viewData = CreateView( )
        self:addChild(self.viewData.view)
        self.viewData.view:setPosition(display.center)
    end, __G__TRACKBACK__)
end

--[[
刷新主题详情
--]]
function PrivateRoomThemeView:RefreshDetailsLayout( data )
	local viewData = self.viewData
	local themeConf = CommonUtils.GetConfig('privateRoom', 'avatarTheme', data.themeId)
	viewData.themeNameLabel:setString(themeConf.name)
	viewData.descrListView:removeAllNodes()
	local descrLabel = display.newLabel(0, 0, fontWithColor(6, {ap = cc.p(0, 0), w = 280, text = themeConf.name}))
	local cell = CLayout:create(cc.size(300, display.getLabelContentSize(descrLabel).height + 5))
	cell:addChild(descrLabel)
	viewData.descrListView:insertNodeAtLast(cell)
    viewData.descrListView:reloadData()
    local initThemeId = CommonUtils.GetConfig('privateRoom', 'avatarThemeInit', 1).themeId
    if gameMgr:GetAmountByGoodId(data.themeId) > 0 or checkint(data.themeId) == checkint(initThemeId ) then
        viewData.priceLayout:setVisible(false)
        viewData.ownedLabel:setVisible(true)
        viewData.purchaseBtn:getLabel():setString(__('使用'))
    else
        viewData.priceLayout:setVisible(true)
        viewData.ownedLabel:setVisible(false)
        viewData.purchaseBtn:getLabel():setString(__('购买'))
        viewData.origPriceNum:setString(tostring(data.price))
        viewData.origCostIcon:setTexture(CommonUtils.GetGoodsIconPathById(data.currency))
        viewData.origCostIcon:setPositionX(viewData.origPriceNum:getPositionX() + display.getLabelContentSize(viewData.origPriceNum).width + 20)
        viewData.discountLine:setContentSize(cc.size(display.getLabelContentSize(viewData.origPriceNum).width, 2))
        viewData.priceNum:setString(tostring(checkint(data.price * data.discount)))
        viewData.costIcon:setTexture(CommonUtils.GetGoodsIconPathById(data.currency))
        viewData.costIcon:setPositionX(viewData.priceNum:getPositionX() + viewData.priceNum:getContentSize().width + 20)
    end
end
--[[
刷新列表
--]]
function PrivateRoomThemeView:RefreshGridView()
    local viewData = self.viewData
    local offset = viewData.gridView:getContentOffset()
	viewData.gridView:reloadData()
	viewData.gridView:setContentOffset(offset)
end
return PrivateRoomThemeView