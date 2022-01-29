
local AvatarShopView = class('AvatarShopView', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.AvatarShopView'
	node:enableNodeEvents()
	return node
end)

local RES_DIR = {
    AVATAR_SHOP_BG = _res('avatar/ui/avatarShop/avator_bg_shop.png'),
    
   -----------------------  主题   -------------------------
    AVATAR_SHOP_GOOD_THEME_BG = _res('avatar/ui/avatarShop/avator_goods_bg_l.png'),
    AVATAR_SHOP_GOOD_THEME_SELECT_FRAME = _res('avatar/ui/avatarShop/avator_goods_bg_l_selected.png'),
    AVATAR_SHOP_GOOD_THEME_TITLE_NAME_BG = _res('avatar/ui/avatarShop/avator_goods_bg_title_name.png'),
    AVATAR_SHOP_GOOD_THEME_LOCK_TEXT_BG = _res('avatar/ui/avatarShop/avator_bg_lock_text.png'),
    OWN_BG = _res('avatar/ui/avatarShop/avator_ico_own_label.png'), 
    DISCOUNT_RATE_BG = _res('avatar/ui/avatarShop/shop_tag_sale_member.png'), 

    -----------------------  预览   -------------------------
    AVATAR_SHOP_GOOD_PREVIEW_BG = _res('avatar/ui/avatarShop/avator_goods_bg_preview.png'),
    AVATAR_SHOP_GOOD_PREVIEW_SALE_NUM_BG = _res('avatar/ui/avatarShop/avator_bg_sale_number.png'),
    AVATAR_SHOP_GOOD_PREVIEW_NUM_BG = _res('avatar/ui/avatarShop/avator_goods_preview_bg_num.png'),
    AVATAR_SHOP_GOOD_PREVIEW_SUB_BG = _res('avatar/ui/market_sold_btn_sub.png'),
    AVATAR_SHOP_GOOD_PREVIEW_PLUS_BG = _res('avatar/ui/market_sold_btn_plus.png'),
    AVATAR_SHOP_GOOD_PREVIEW_NUM_INFO_BG = _res('ui/home/market/market_buy_bg_info.png'),
    AVATAR_SHOP_GOOD_PREVIEW_ATTIBUTE = _res('avatar/ui/avatarShop/avator_goods_bg_attibute.png'),
    -----------------------  cell   -------------------------
    AVATAR_SHOP_GOOD_BG_M = _res('avatar/ui/avatarShop/avator_goods_bg_m.png'),
    AVATAR_SHOP_BANNER_BG_SELECT = _res('avatar/ui/avatarShop/avator_banner_btn_selected.png'),
    AVATAR_SHOP_BANNER_ICO_LINE = _res('avatar/ui/avatarShop/avator_banner_ico_line.png'),
    AVATAR_SHOP_BANNER_SELLOUT = _res('avatar/ui/avatarShop/shop_btn_goods_sellout.png'),
    AVATAR_SHOP_BANNER_SELE = _res('avatar/ui/avatarShop/shop_btn_goods_sale.png'),
    AVATAR_SHOP_GOOD_THEME_CELL_DEFAULT_BG = _res('ui/home/commonShop/shop_btn_goods_default.png'),
    -- AVATAR_SHOP_BANNER_SELE = _res('ui/home/commonShop/shop_btn_goods_sale.png'),
    AVATAR_SHOP_BTN_ORANGE = _res('ui/common/common_btn_orange.png'),
    
    -----------------------  主题购买预览   ------------------------- 
    AVATAR_SHOP_THEME_BUY_PREVIEW_BG = _res('ui/common/common_bg_3.png'),
    AVATAR_SHOP_THEME_BUY_PREVIEW_LIST_BG = _res('ui/common/common_bg_tips.png'),
    AVATAR_SHOP_THEME_BUY_PREVIEW_TITLE = _res('ui/common/common_bg_title_2.png'),
    
    -- avator_goods_bg_attibute.png

    ICON_HEART            =  _res('ui/common/common_hint_circle_red_ico.png'),

    BTN_WHITR             =  _res('ui/common/common_btn_white_default.png'),
    DISCOUNT_LINE         =  _res('ui/home/commonShop/shop_sale_line.png'),


    AVATAR_SHOP_GOOD_THEME_BUY_PREVIEW_BG = _res('ui/common/commcon_bg_text1.png'),
    AVATAR_SHOP_GOOD_THEME_BUY_PREVIEW_NAME = _res('avatar/ui/avatarShop/theme_preview_bg_name.png'),
    AVATAR_SHOP_GOOD_THEME_BUY_PREVIEW_TITLE = _res('ui/common/common_title_3.png'),
    AVATAR_SHOP_GOOD_THEME_BUY_PREVIEW_RIGHT_BG = _res('avatar/ui/avatarShop/theme_preview_bg.png'),
    AVATAR_SHOP_GOOD_THEME_BUY_PREVIEW_RIGHT_DES_BG = _res('avatar/ui/avatarShop/theme_preview_bg_detail.png'),
    AVATAR_SHOP_GOOD_THEME_BUY_PREVIEW_RIGHT_PRESENT_PRICE_BG = _res('avatar/ui/avatarShop/shop_package_putong_bg.png'),
    AVATAR_SHOP_GOOD_THEME_BUY_PREVIEW_RIGHT_DISCOUNT_PRICE_BG = _res('avatar/ui/avatarShop/shop_package_putong_bg_2.png'),
    -- 
    -- 
    
}

local DragNode = require('Game.views.restaurant.DragNode')

local CCB = cc.c3b(100,100,200)

local CreateShopTabLayer_ = nil
local CreateShopThemeDescLayer_ = nil
local CreateShopGoodPreview_ = nil
local CreateShopGoodLayer_ = nil
local CreateShopThemeInventoryPreviewLayer_ = nil

local CreateGoodIcon_ = nil

local CreateShopTabCell_ = nil
local CreateShopGoodCell_ = nil
local CreateShopThemeCellLayer_ = nil
local CreateShopThemeInventoryCell_ = nil

local CreatePriceLabel_ = nil

function AvatarShopView:ctor( ... )
    self.args = unpack({...})
    self:InitialUI()
end

function AvatarShopView:InitialUI()
    local function CreateView()
        local touchView = display.newLayer(0, 0, {color = cc.c4b(0, 0, 0, 130), enable = true, size = display.size, ap = display.LEFT_BOTTOM, cb = handler(self, self.CloseHandler)})

        local bg = display.newImageView(_res(RES_DIR.AVATAR_SHOP_BG), 0, 0)
        local bgSize = bg:getContentSize()
        local view = display.newLayer(0, 0, {size = bgSize, ap = cc.p(0.5, 0.5)})
        local touchBgView = display.newLayer(0, 0, {color = cc.c4b(0, 0, 0, 0), enable = true, size = bgSize, ap = display.LEFT_BOTTOM})
        view:setPosition(display.center)
        display.commonUIParams(bg, {po = cc.p(utils.getLocalCenter(view))})
        view:addChild(touchBgView)
        view:addChild(bg)
        
        self:addChild(touchView)
        self:addChild(view)

        local shopTabViewData = CreateShopTabLayer_(bgSize)
        view:addChild(shopTabViewData.layer)
        
        local shopGoodViewData = CreateShopGoodLayer_(bgSize)
        local shopGoodLayer = shopGoodViewData.layer
        shopGoodLayer:setVisible(false)
        view:addChild(shopGoodLayer)

        local shopThemeViewData = CreateShopGoodLayer_(bgSize, RESTAURANT_AVATAR_TYPE.THEME)
        local shopThemeLayer = shopThemeViewData.layer
        shopThemeLayer:setVisible(false)
        view:addChild(shopThemeLayer)

        local goodPreviewViewData = CreateShopGoodPreview_(bgSize)
        view:addChild(goodPreviewViewData.layer)
        
        local themeDescViewData = CreateShopThemeDescLayer_(bgSize)
        local shopThemeDescLayer = themeDescViewData.layer
        shopThemeDescLayer:setVisible(false)
        view:addChild(shopThemeDescLayer)
        
        -- local themeInventoryPreviewViewData = CreateShopThemeInventoryPreviewLayer_()
        -- display.commonUIParams(spareParts.layer, {po = utils.getLocalCenter(self)})
        -- self:addChild(spareParts.layer)

        -- local gridView = spareParts.gridView
        -- gridView:setDataSourceAdapterScriptHandler(handler(self,self.OnThemeInventoryDataSource))
        -- gridView:setCountOfCell(5)
        -- gridView:setBounceable(false)
        -- gridView:reloadData()

        return {
            view = view,
            shopTabViewData = shopTabViewData,
            shopGoodViewData = shopGoodViewData,
            shopThemeViewData = shopThemeViewData,
            goodPreviewViewData = goodPreviewViewData,

            themeDescViewData = themeDescViewData,
        }
    end
    
    xTry(function ( )
        self.viewData = CreateView( )
	end, __G__TRACKBACK__)
end

CreateShopTabLayer_ = function (bgSize)
    local gridViewSize = cc.size(220, bgSize.height * 0.93)
    local gridViewCellSize = cc.size(220, 84)

    local layer = display.newLayer(190, bgSize.height * 0.99, {size = gridViewSize, ap = display.RIGHT_TOP})

    local gridView = CGridView:create(gridViewSize)
    gridView:setAnchorPoint(display.LEFT_BOTTOM)   
    gridView:setSizeOfCell(gridViewCellSize)
    gridView:setColumns(1)
    -- gridView:setBackgroundColor(cc.c3b(100,100,200))
    gridView:setPosition(cc.p(0, 0))
    layer:addChild(gridView)

    return {
        layer = layer,
        gridView = gridView,
    }
end

-- 主题详情 
CreateShopThemeDescLayer_ = function (bgSize)
    local descBgSize = cc.size(bgSize.width * 0.55, bgSize.height * 0.92)
    local layer = display.newLayer(bgSize.width * 0.444, bgSize.height * 0.96, {size = descBgSize, ap = display.CENTER_TOP})

    local themeCellViewData = CreateShopThemeCellLayer_()
    local themeCellLayer = themeCellViewData.layer
    themeCellLayer:setPosition(cc.p(0, bgSize.height * 0.935))
    layer:addChild(themeCellLayer)

    local gridViewSize = cc.size(bgSize.width * 0.55, bgSize.height * 0.63)
    local gridViewCellSize = cc.size(226, 285)
    local gridView = CGridView:create(gridViewSize)
    gridView:setAnchorPoint(display.LEFT_BOTTOM)   
    gridView:setSizeOfCell(gridViewCellSize)
    gridView:setColumns(3)
    -- gridView:setBackgroundColor(cc.c3b(100,100,200))
    gridView:setPosition(cc.p(0, 0))
    layer:addChild(gridView)

    return {
        layer = layer,
        themeCellViewData = themeCellViewData,
        gridView = gridView,
    }
end

CreateShopGoodPreview_ = function (bgSize)
    local size = cc.size(bgSize.width * 0.268, bgSize.height * 0.95)
    local layer = display.newLayer(bgSize.width * 0.99, bgSize.height * 0.03, {size = size, ap = display.RIGHT_BOTTOM})

    local titleLabel = display.newLabel(size.width * 0.04, size.height * 0.98, fontWithColor(4, {text = '', ap = display.LEFT_TOP}))
    layer:addChild(titleLabel)
    
    local previewBg = display.newImageView(RES_DIR.AVATAR_SHOP_GOOD_PREVIEW_BG, size.width / 2, size.height * 0.93, {ap = display.CENTER_TOP})
    local previewBgSize = previewBg:getContentSize()
    layer:addChild(previewBg)

    --------------------       主题预览       ---------------------
    local previewThemeBgLayer = display.newLayer(size.width / 2, size.height * 0.93, {size = previewBgSize, ap = display.CENTER_TOP})
    previewThemeBgLayer:setVisible(false)
    layer:addChild(previewThemeBgLayer)

    -- cc.ScrollView 描点无用
    local descrViewSize  = cc.size(previewBgSize.width * 0.9, 240)
    local descrContainer = cc.ScrollView:create()
    descrContainer:setPosition(cc.p(previewBgSize.width * 0.05, previewBgSize.height - descrViewSize.height - 15))
	descrContainer:setDirection(eScrollViewDirectionVertical)
    -- descrContainer:setAnchorPoint(display.CENTER_TOP)
    descrContainer:setViewSize(descrViewSize)
	previewThemeBgLayer:addChild(descrContainer)
   
    local descLabel = display.newLabel(0, 0, fontWithColor(6, {hAlign = display.TAL, w = descrViewSize.width}))
    descrContainer:setContainer(descLabel)
    -- previewThemeBgLayer:addChild(descLabel)

    local previewBtn = display.newButton(previewBgSize.width - 5, 5, {n = RES_DIR.BTN_WHITR, ap = display.RIGHT_BOTTOM})
    display.commonLabelParams(previewBtn,fontWithColor(14, {text = __('预览'),fontSize  = 20}))
    previewThemeBgLayer:addChild(previewBtn)
    
    --------------------       普通道具预览       ---------------------
    local previewBgLayer = display.newLayer(size.width / 2, size.height * 0.93, {size = previewBgSize, ap = display.CENTER_TOP})
    previewBgLayer:setVisible(false)
    layer:addChild(previewBgLayer)
    
    local ownNumBg = display.newImageView(RES_DIR.AVATAR_SHOP_GOOD_PREVIEW_NUM_BG, previewBgSize.width * 0.99, previewBgSize.height * 0.99, {ap = display.RIGHT_TOP , scale9 = true })
    previewBgLayer:addChild(ownNumBg)

    local ownNumLabel = display.newLabel(0, 0, fontWithColor(18, {text = ''}))
    display.commonUIParams(ownNumLabel, {po = cc.p(utils.getLocalCenter(ownNumBg))})
    ownNumBg:addChild(ownNumLabel)

    local goodIconSize = cc.size(previewBgSize.width * 0.9, previewBgSize.height * 0.69)
    local goodIconLayer = display.newLayer(previewBgSize.height * 0.05, previewBgSize.height * 0.2, {size = goodIconSize, ap = display.LEFT_BOTTOM})
    previewBgLayer:addChild(goodIconLayer)

    local previewAttibute = display.newButton(previewBgSize.width / 2, 0, {ap = display.CENTER_BOTTOM, n = RES_DIR.AVATAR_SHOP_GOOD_PREVIEW_ATTIBUTE, scale9 = true})
    previewBgLayer:addChild(previewAttibute)

    local soldSize = cc.size(size.width, 53)
    local soldLayer = display.newLayer(size.width / 2, size.height * 0.23, {size = soldSize, ap = display.CENTER_BOTTOM})
    soldLayer:setVisible(false)
    layer:addChild(soldLayer)

    --选择数量
    local btnNumSize = cc.size(180, 44)
    local btnNum = display.newButton(0, 0, {n = RES_DIR.AVATAR_SHOP_GOOD_PREVIEW_NUM_INFO_BG, scale9 = true, size = btnNumSize})
    display.commonUIParams(btnNum, {po = cc.p(soldSize.width * 0.5, soldSize.height / 2),ap = cc.p(0.5, 0.5)})
    display.commonLabelParams(btnNum, {text = '1', fontSize = 28, color = '#7c7c7c'})
    soldLayer:addChild(btnNum)

    --减号btn
    local btnSub = display.newButton(0, 0, {n = RES_DIR.AVATAR_SHOP_GOOD_PREVIEW_SUB_BG})
    display.commonUIParams(btnSub, {po = cc.p(soldSize.width * 0.5 - btnNumSize.width / 2, soldSize.height / 2),ap = cc.p(0.5, 0.5)})
    soldLayer:addChild(btnSub)

    --加号btn
    local btnPlus = display.newButton(0, 0, {n = RES_DIR.AVATAR_SHOP_GOOD_PREVIEW_PLUS_BG})
    display.commonUIParams(btnPlus, {po = cc.p(soldSize.width * 0.5 + btnNumSize.width / 2, soldSize.height / 2),ap = cc.p(0.5, 0.5)})
    soldLayer:addChild(btnPlus)
    -- local probabilityLabel = cc.Label:createWithBMFont('font/small/common_text_num_5.fnt', '3%')
    -- probabilityLabel:setHorizontalAlignment(display.TAR)
    -- probabilityLabel:setPosition(previewBgSize.width * 0.05, previewBgSize.height * 0.2)
    -- probabilityLabel:setAnchorPoint(display.LEFT_TOP)
    -- previewBgLayer:addChild(probabilityLabel)

    
    
    -------------------       已打折道具价格        --------------------------
    -- local discountPriceLayer = display.newLayer(size.width / 2, size.height * 0.22, {size = saleNumBgSize, ap = display.CENTER_TOP})
    -- discountPriceLayer:setVisible(false)
    -- layer:addChild(discountPriceLayer)
    
    -- local originalPriceNumLabel = display.newLabel(8, saleNumBgSize.height / 2, {fontSize = 22, color = '#000000', text = 300, ap = display.LEFT_CENTER})
    -- local originalPriceNumLabelSize = display.getLabelContentSize(originalPriceNumLabel)
    -- discountPriceLayer:addChild(originalPriceNumLabel)
    
    -- local discountLineSize = cc.size(originalPriceNumLabelSize.width + 6, 2)
    -- local discountLine = display.newImageView(_res('ui/home/commonShop/shop_sale_line.png'), originalPriceNumLabel:getPositionX() + originalPriceNumLabelSize.width / 2, saleNumBgSize.height / 2, {size = discountLineSize, scale9 = true, ap = display.CENTER})
    -- discountPriceLayer:addChild(discountLine, 1)
    
    -- local discountCastIcon = display.newImageView(_res(CommonUtils.GetGoodsIconPathById(GOLD_ID)), discountLineSize.width + 2, saleNumBgSize.height / 2, {ap = display.LEFT_CENTER})
    -- discountCastIcon:setScale(0.2)
    -- discountPriceLayer:addChild(discountCastIcon)
    
    -- local presentPriceNumLabel = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '200')
    -- local presentPriceNumLabelSize = presentPriceNumLabel:getContentSize()
    -- presentPriceNumLabel:setPosition(cc.p(saleNumBgSize.width * 0.5 + 8, saleNumBgSize.height / 2))
    -- presentPriceNumLabel:setAnchorPoint(display.LEFT_CENTER)
    -- discountPriceLayer:addChild(presentPriceNumLabel)

    -- local presentCastIcon = display.newImageView(_res(CommonUtils.GetGoodsIconPathById(GOLD_ID)), presentPriceNumLabel:getPositionX() +  presentPriceNumLabelSize.width + 2, saleNumBgSize.height / 2, {ap = display.LEFT_CENTER})
    -- presentCastIcon:setScale(0.2)
    -- discountPriceLayer:addChild(presentCastIcon)

    local presentPriceBgSize = cc.size(previewBgSize.width, 76) or  presentPriceBg:getContentSize()
    local presentPriceBg = display.newImageView(RES_DIR.AVATAR_SHOP_GOOD_THEME_BUY_PREVIEW_RIGHT_PRESENT_PRICE_BG, 0, 0, {size = presentPriceBgSize, scale9 = true, ap = display.LEFT_BOTTOM})
   
    local presentPriceBgLayer = display.newLayer(size.width / 2, size.height * 0.15, {color = CCB, size = presentPriceBgSize, ap = display.CENTER_BOTTOM})
    presentPriceBgLayer:setVisible(false)
    presentPriceBgLayer:addChild(presentPriceBg)
    layer:addChild(presentPriceBgLayer)
    
    local discountPriceBgSize = cc.size(presentPriceBgSize.width * 0.97, 36) or discountPriceBg:getContentSize()
    local discountPriceBg = display.newImageView(RES_DIR.AVATAR_SHOP_GOOD_THEME_BUY_PREVIEW_RIGHT_DISCOUNT_PRICE_BG, 0, 0, {size = discountPriceBgSize, scale9 = true, ap = display.LEFT_BOTTOM})
    local discountPriceBgLayer = display.newLayer(presentPriceBgSize.width / 2, presentPriceBgSize.height / 2, {size = discountPriceBgSize, ap = display.CENTER_BOTTOM})
    -- discountPriceBgLayer:setVisible(false)
    discountPriceBgLayer:addChild(discountPriceBg)
    presentPriceBgLayer:addChild(discountPriceBgLayer)

    local discountPriceLabel = display.newLabel(3, 5, fontWithColor(6, {text = __('原价'), ap = display.LEFT_BOTTOM}))
    discountPriceBgLayer:addChild(discountPriceLabel)

    local discountPriceNum, discountCastIcon, discountLine = CreatePriceLabel_(discountPriceBgLayer, cc.p(discountPriceBgSize.width * 0.5, 5))

    local presentPriceLabel = display.newLabel(8, 5, fontWithColor(5, {text = __('现价'), ap = display.LEFT_BOTTOM}))
    presentPriceBgLayer:addChild(presentPriceLabel)

    local presentPriceNum, presentCastIcon = CreatePriceLabel_(presentPriceBgLayer, cc.p(presentPriceBgSize.width * 0.5, 5), true)

    -------------------       未打折道具价格        --------------------------
    local saleNumBg = display.newImageView(RES_DIR.AVATAR_SHOP_GOOD_PREVIEW_SALE_NUM_BG, size.width / 2, size.height * 0.22, {ap = display.CENTER_TOP})
    saleNumBg:setVisible(false)
    local saleNumBgSize = saleNumBg:getContentSize()
    layer:addChild(saleNumBg)

    local originalPriceLayer = display.newLayer(size.width / 2, size.height * 0.22, {size = saleNumBgSize, ap = display.CENTER_TOP})
    originalPriceLayer:setVisible(false)
    layer:addChild(originalPriceLayer)
    
    local totalPriceLabel = display.newLabel(0, 0, fontWithColor(6, {text = __('总价:'), ap = display.RIGHT_CENTER}))
    local totalPriceNum = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '0')--
    local castIcon = display.newNSprite(_res(CommonUtils.GetGoodsIconPathById(GOLD_ID)), 0, saleNumBgSize.height / 2)
    local totalPriceNumSize = totalPriceNum:getContentSize()
    
    totalPriceNum:setAnchorPoint(display.CENTER)
    totalPriceNum:setHorizontalAlignment(display.TAR)
    castIcon:setScale(0.2)
    castIcon:setAnchorPoint(display.LEFT_CENTER)
    
    totalPriceLabel:setPosition(cc.p(saleNumBgSize.width / 2 - totalPriceNumSize.width / 2, saleNumBgSize.height / 2))
    totalPriceNum:setPosition(cc.p(saleNumBgSize.width / 2, saleNumBgSize.height / 2))
    castIcon:setPosition(cc.p(saleNumBgSize.width / 2 + totalPriceNumSize.width / 2, saleNumBgSize.height / 2))
    
    originalPriceLayer:addChild(totalPriceLabel)
    originalPriceLayer:addChild(totalPriceNum)
    originalPriceLayer:addChild(castIcon)

    local buyBtn = display.newButton(size.width / 2, size.height * 0.02, {ap = display.CENTER_BOTTOM, n = RES_DIR.AVATAR_SHOP_BTN_ORANGE})
    display.commonLabelParams(buyBtn, fontWithColor(14))
    layer:addChild(buyBtn)

    return {
        layer = layer,
        titleLabel = titleLabel,

        previewThemeBgLayer = previewThemeBgLayer,
        descrContainer = descrContainer,
        descLabel = descLabel,
        previewBtn = previewBtn,

        previewBgLayer = previewBgLayer,
        ownNumLabel = ownNumLabel,
        soldLayer = soldLayer,
        btnNum = btnNum,
        btnSub = btnSub,
        btnPlus = btnPlus,
        buyBtn = buyBtn,
        goodIconLayer = goodIconLayer,
        previewAttibute = previewAttibute,
        ownNumBg = ownNumBg ,

        -- 折扣 相关
        -- discountPriceLayer = discountPriceLayer,
        -- originalPriceNumLabel = originalPriceNumLabel,
        -- discountLine = discountLine,
        -- discountCastIcon = discountCastIcon,
        -- presentPriceNumLabel = presentPriceNumLabel,
        -- presentCastIcon = presentCastIcon,
        
        presentPriceBgLayer = presentPriceBgLayer,
        discountPriceBgLayer = discountPriceBgLayer,
        discountPriceNum = discountPriceNum,
        discountCastIcon = discountCastIcon,
        discountLine = discountLine,
        presentPriceNum = presentPriceNum,
        presentCastIcon = presentCastIcon,

        saleNumBg = saleNumBg,
        originalPriceLayer = originalPriceLayer,
        totalPriceLabel = totalPriceLabel,
        totalPriceNum = totalPriceNum,
        castIcon = castIcon,

        saleNumBgSize = saleNumBgSize,
    }
end

-- avatarType == RESTAURANT_AVATAR_TYPE.THEME 主题列表 
CreateShopGoodLayer_ = function (bgSize, avatarType)
    local col = 0
    local gridViewCellSize = nil
    local gridViewSize = cc.size(bgSize.width * 0.55, bgSize.height * 0.92)

    if avatarType == RESTAURANT_AVATAR_TYPE.THEME then
        gridViewCellSize = cc.size(bgSize.width * 0.54, 190)
        col = 1
    else
        gridViewCellSize = cc.size(224, 285)
        col = 3
    end

    local layer = display.newLayer(bgSize.width * 0.442, bgSize.height * 0.98, {size = gridViewSize, ap = display.CENTER_TOP})
    
    local gridView = CGridView:create(gridViewSize)
    gridView:setAnchorPoint(display.CENTER)
    -- gridView:setBackgroundColor(cc.c3b(100,100,200))
    gridView:setSizeOfCell(gridViewCellSize)
    gridView:setColumns(col)
    gridView:setPosition(cc.p(gridViewSize.width / 2 + 10, gridViewSize.height / 2))
    layer:addChild(gridView)

    return {
        layer = layer,
        gridView = gridView,
    }
end

CreateShopThemeInventoryPreviewLayer_ = function ()
    local layer = display.newLayer(0, 0, {size = display.size, ap = display.CENTER})
    local touchView = display.newLayer(0, 0, {size = display.size, ap = display.LEFT_BOTTOM, enable = true, color = cc.c4b(0, 0, 0, 130), cb = function ( ... )
        layer:setVisible(false)
    end})
    layer:addChild(touchView)

    local bgSize = cc.size(1070, 600)
    local bgLayer = display.newLayer(0, 0, {size = bgSize, ap = display.CENTER})
    bgLayer:addChild(display.newLayer(0, 0, {size = bgSize, ap = display.LEFT_BOTTOM, enable = true, color = cc.c4b(0, 0, 0, 0)}))
    display.commonUIParams(bgLayer, {po =  utils.getLocalCenter(layer)})
    layer:addChild(bgLayer)

    local leftBgSize = cc.size(800, 600)
    local leftBg = display.newImageView(RES_DIR.AVATAR_SHOP_GOOD_THEME_BUY_PREVIEW_BG, 0, 0, {size = leftBgSize, scale9 = true, ap = display.LEFT_BOTTOM})
    local leftBgLayer = display.newLayer(0, 0, {size = leftBgSize, ap = display.LEFT_BOTTOM})
    leftBgLayer:addChild(leftBg)
    bgLayer:addChild(leftBgLayer)
    
    local themeImg = display.newImageView(CommonUtils.GetGoodsIconPathById(270004, true), 0, leftBgSize.height, {ap = display.LEFT_TOP})
    leftBgLayer:addChild(themeImg)
    
    local themeNameBg = display.newImageView(RES_DIR.AVATAR_SHOP_GOOD_THEME_BUY_PREVIEW_NAME, leftBgSize.width / 2, 0, {ap = display.CENTER_BOTTOM})
    leftBgLayer:addChild(themeNameBg)

    local themeName = display.newLabel(0, 0, fontWithColor(19, {ap = display.CENTER, text = '海色沙滩'}))
    display.commonUIParams(themeName, {po =  utils.getLocalCenter(themeNameBg)})
    themeNameBg:addChild(themeName)

    local rightBg = display.newImageView(RES_DIR.AVATAR_SHOP_GOOD_THEME_BUY_PREVIEW_RIGHT_BG, 0, 0, {ap = display.LEFT_BOTTOM})
    local rightBgSize = rightBg:getContentSize()
    local rightBgLayer = display.newLayer(bgSize.width, 0, {size = rightBgSize, ap = display.RIGHT_BOTTOM})
    rightBgLayer:addChild(rightBg)
    bgLayer:addChild(rightBgLayer)

    local titleBg = display.newImageView(RES_DIR.AVATAR_SHOP_GOOD_THEME_BUY_PREVIEW_TITLE, rightBgSize.width * 0.5, rightBgSize.height * 0.99, {ap = display.CENTER_TOP , scale9 = true })
    rightBgLayer:addChild(titleBg)
    
    local titleLabel = display.newLabel(0, 0, fontWithColor(4, {text = __('主题明细'), ap = display.CENTER , reqW  = 180}))
    local titleLabelSize = display.getLabelContentSize(titleLabel)
    local maxWith = 180
    if titleLabelSize.width < 180 then
        maxWith = titleLabelSize.width
    end
    local titleBgSize = titleBg:getContentSize()
    titleBg:setContentSize(cc.size(maxWith+ 60  , titleBgSize.height ))
    display.commonUIParams(titleLabel, {po =  utils.getLocalCenter(titleBg)})
    titleBg:addChild(titleLabel)


    
    local themeDescListBgSize = cc.size(256, 400)
    local themeDescListBg = display.newImageView(RES_DIR.AVATAR_SHOP_GOOD_THEME_BUY_PREVIEW_RIGHT_DES_BG, 0, 0, {size = themeDescListBgSize, scale9 = true, ap = display.LEFT_BOTTOM})
    local themeDescListBgLayer = display.newLayer(rightBgSize.width / 2, rightBgSize.height * 0.92, {size = themeDescListBgSize, ap = display.CENTER_TOP})
    rightBgLayer:addChild(themeDescListBgLayer)
    themeDescListBgLayer:addChild(themeDescListBg)

    -- dump(themeDescListBgSize, 'themeDescListBgSize')
    local gridViewCellSize = cc.size(themeDescListBgSize.width, 40)
    local gridView = CGridView:create(themeDescListBgSize)
    gridView:setAnchorPoint(display.LEFT_BOTTOM)   
    gridView:setSizeOfCell(gridViewCellSize)
    gridView:setColumns(1)
    -- gridView:setBackgroundColor(cc.c3b(100,100,200))
    gridView:setPosition(cc.p(0, 0))
    themeDescListBgLayer:addChild(gridView)

    local buyBtn = display.newButton(rightBgSize.width / 2, rightBgSize.height * 0.01, {ap = display.CENTER_BOTTOM, n = RES_DIR.AVATAR_SHOP_BTN_ORANGE})
    local buyBtnSize = buyBtn:getContentSize()
    display.commonLabelParams(buyBtn, fontWithColor(14, {text = __('购买')}))
    rightBgLayer:addChild(buyBtn)
    
    local presentPriceBg = display.newImageView(RES_DIR.AVATAR_SHOP_GOOD_THEME_BUY_PREVIEW_RIGHT_PRESENT_PRICE_BG, 0, 0, {ap = display.LEFT_BOTTOM})
    local presentPriceBgSize = presentPriceBg:getContentSize()
    local presentPriceBgLayer = display.newLayer(rightBgSize.width / 2, rightBgSize.height * 0.12, {color = CCB, size = presentPriceBgSize, ap = display.CENTER_BOTTOM})
    presentPriceBgLayer:addChild(presentPriceBg)
    rightBgLayer:addChild(presentPriceBgLayer)
    
    local discountPriceBg = display.newImageView(RES_DIR.AVATAR_SHOP_GOOD_THEME_BUY_PREVIEW_RIGHT_DISCOUNT_PRICE_BG, 0, 0, {ap = display.LEFT_BOTTOM})
    local discountPriceBgSize = discountPriceBg:getContentSize()
    local discountPriceBgLayer = display.newLayer(presentPriceBgSize.width / 2, presentPriceBgSize.height / 2, {size = discountPriceBgSize, ap = display.CENTER_BOTTOM})
    discountPriceBgLayer:addChild(discountPriceBg)
    presentPriceBgLayer:addChild(discountPriceBgLayer)

    local discountPriceLabel = display.newLabel(3, 5, fontWithColor(6, {text = __('原价'),reqW = 115, ap = display.LEFT_BOTTOM}))
    discountPriceBgLayer:addChild(discountPriceLabel)

    local discountPriceNum, discountCastIcon, discountLine = CreatePriceLabel_(discountPriceBgLayer, cc.p(discountPriceBgSize.width * 0.5, 5))

    local presentPriceLabel = display.newLabel(8, 5, fontWithColor(5, {text = __('现价'),reqW = 115, ap = display.LEFT_BOTTOM}))
    presentPriceBgLayer:addChild(presentPriceLabel)

    local presentPriceNum, presentCastIcon = CreatePriceLabel_(presentPriceBgLayer, cc.p(presentPriceBgSize.width * 0.5, 5), true)

    return {
        layer                = layer,
        touchView            = touchView,
        gridView             = gridView,
        buyBtn               = buyBtn,
        themeImg             = themeImg,
        themeName            = themeName,
        
        discountPriceBgLayer = discountPriceBgLayer,
        discountPriceNum     = discountPriceNum, 
        discountCastIcon     = discountCastIcon, 
        discountLine         = discountLine,

        presentPriceBgLayer  = presentPriceBgLayer,
        presentPriceNum      = presentPriceNum, 
        presentCastIcon      = presentCastIcon,

        presentPriceBgSize   = presentPriceBgSize,
        discountPriceBgSize  = discountPriceBgSize,
    }
end

CreateGoodIcon_ = function (parent, goodsId)
    if parent and parent:getChildrenCount() > 0 then
        parent:removeAllChildren()
    end
    local parentSize = parent:getContentSize()
    local avatarConfig =  CommonUtils.GetConfigNoParser('restaurant', 'avatar', goodsId)
    local locationConfig =  CommonUtils.GetConfigNoParser('restaurant', 'avatarLocation', goodsId)
    local nType = checkint(avatarConfig.mainType)
   
    local goodIcon = DragNode.new({id = goodsId, avatarId = goodsId, nType = nType, configInfo = locationConfig, enable = false})
    -- goodIcon:setVisible(false)
    display.commonUIParams(goodIcon, {ap = display.CENTER, po = cc.p(parentSize.width / 2, parentSize.height * 0.5)})
    local goodIconSize = goodIcon:getContentSize()
    local scaleX = 1
    local scaleY = 1
    if goodIconSize.width > parentSize.width then
        scaleX = parentSize.width / goodIconSize.width
    end

    if goodIconSize.height > parentSize.height then
        scaleY = parentSize.height / goodIconSize.height
    end
    goodIcon:setScale(math.min(scaleX, scaleY))
    parent:addChild(goodIcon)


end

CreateShopTabCell_ = function ()
    local size = cc.size(220, 82)
    local cell = CGridViewCell:new()
    -- cell:

    local layer = display.newLayer(0, 0, {size = size})
    local touchView = display.newLayer(0, 0, {color = cc.c4b(0, 0, 0, 0), enable = true, size = size})
    layer:addChild(touchView)
    cell:addChild(layer)
    
    local normalLayer = display.newLayer(0, 0, {size = size, ap = display.LEFT_BOTTOM})
    -- normalLayer:setVisible(false)
    layer:addChild(normalLayer)
    
    -- local normalImg = display.newImageView(_res('avatar/ui/decorate_ico_ornament'), size.width * 0.06, size.height / 2, {ap = display.LEFT_CENTER})
    -- normalLayer:addChild(normalImg)
    
    local normalLabel = display.newLabel(size.width * 0.62, size.height * 0.48, fontWithColor(4, {ap = display.CENTER, text = '装修'}))
    normalLayer:addChild(normalLabel)
    
    local selectLayer = display.newLayer(0, 0, {size = size, ap = display.LEFT_BOTTOM})
    selectLayer:setVisible(false)
    layer:addChild(selectLayer)

    local selectBg = display.newImageView(RES_DIR.AVATAR_SHOP_BANNER_BG_SELECT, size.width, size.height / 2, {ap = display.RIGHT_CENTER})
    local selectBgSize = selectBg:getContentSize()
    selectLayer:addChild(selectBg)

    local selectImg = display.newImageView(_res('avatar/ui/decorate_ico_ornament'), selectBgSize.width / 2, 18, {ap = display.CENTER_BOTTOM})
    selectBg:addChild(selectImg)
    
    local selectLabel = display.newLabel(selectBgSize.width / 2, 0, fontWithColor(17, {ap = display.CENTER_BOTTOM, text = '装修'}))
    selectBg:addChild(selectLabel)

    local line = display.newImageView(RES_DIR.AVATAR_SHOP_BANNER_ICO_LINE, size.width * 0.62, 0, {ap = display.CENTER_BOTTOM})
    layer:addChild(line)

    local redPointIcon = display.newImageView(_res(RES_DIR.ICON_HEART), size.width - 15, size.height - 10)
    redPointIcon:setVisible(false)
    layer:addChild(redPointIcon)

    cell.viewData = {
        touchView = touchView,
        normalLayer = normalLayer,
        -- normalImg = normalImg,
        normalLabel = normalLabel,
        selectLayer = selectLayer,
        selectImg = selectImg,
        selectLabel = selectLabel,

        redPointIcon = redPointIcon
    }
    return cell
end

--  
CreateShopThemeCellLayer_ = function ()
    local themeBg = display.newImageView(RES_DIR.AVATAR_SHOP_GOOD_THEME_BG, 0, 0, {ap = display.LEFT_BOTTOM})
    local bgSize = themeBg:getContentSize()
    -- local la = display.newLayer(bgSize.width * 0.02, bgSize.height * 0.08, {color = cc.c4f(0,0,0,100), size = cc.size(bgSize.width * 0.96, bgSize.height * 0.86), ap = display.LEFT_BOTTOM})
    local themeImg = display.newImageView('', bgSize.width * 0.02, bgSize.height * 0.08, {ap = display.LEFT_BOTTOM})
    local touchView = display.newLayer(0, 0, {color = cc.c4f(0,0,0,0), size = bgSize, ap = display.LEFT_BOTTOM, enable = true})
    local layer = display.newLayer(0, 0, {size = bgSize, ap = display.LEFT_TOP})
    local themeFrame = display.newImageView(RES_DIR.AVATAR_SHOP_GOOD_THEME_SELECT_FRAME, 0, 0, {scale9 = true, size = cc.size(bgSize.width * 0.99, bgSize.height * 0.99), ap = display.CENTER})
    themeFrame:setVisible(false)
    display.commonUIParams(themeFrame, {po = utils.getLocalCenter(layer)})
    
    local ownBg = display.newImageView(RES_DIR.OWN_BG, bgSize.width - 10, 10, {ap = display.RIGHT_BOTTOM})
    ownBg:setVisible(false)
    -- local ownLabel = display.newLabel(ownBg:getContentSize().width / 2 + 18, ownBg:getContentSize().height / 2 - 2, fontWithColor(16, {text = __('已拥有')}))
    -- ownLabel:setRotation(-38)
    -- ownBg:addChild(ownLabel)

    layer:addChild(themeBg)
    -- layer:addChild(la)
    layer:addChild(themeImg)
    layer:addChild(touchView)
    layer:addChild(ownBg, 1)
    layer:addChild(themeFrame, 1)


    local titleBg = display.newImageView(RES_DIR.AVATAR_SHOP_GOOD_THEME_TITLE_NAME_BG, bgSize.width * 0.02, bgSize.height * 0.08, {scale9 = true, size = cc.size(200,38), ap = display.LEFT_BOTTOM})
    -- titleBg:setOpacity(0.5)
    local titleBgSize = titleBg:getContentSize()
    layer:addChild(titleBg)

    local titleLabel = display.newLabel(10, titleBgSize.height / 2, fontWithColor(18, {text = '', ap = display.LEFT_CENTER}))
    titleBg:addChild(titleLabel)

    local lockBg = display.newImageView(RES_DIR.AVATAR_SHOP_GOOD_THEME_LOCK_TEXT_BG, bgSize.width / 2, bgSize.height / 2, {ap = display.CENTER})
    layer:addChild(lockBg)

    local lockLabel = display.newLabel(0, 0, fontWithColor(4, {text = ''}))
    display.commonUIParams(lockLabel, {po = cc.p(utils.getLocalCenter(lockBg))})
    lockBg:addChild(lockLabel)

    -- DISCOUNT_RATE_BG
    local discountRateBg = display.newImageView(RES_DIR.DISCOUNT_RATE_BG, bgSize.width * 0.02, bgSize.height * 0.89, {ap = display.LEFT_TOP , scale9 = true })
    local discountRateBgSize = discountRateBg:getContentSize()
    layer:addChild(discountRateBg)

    local discountRateLabel = display.newLabel(5, discountRateBgSize.height / 2, fontWithColor(14, {text = '8.8折', ap = display.LEFT_CENTER}))
    discountRateBg:addChild(discountRateLabel)

    local arrow = display.newImageView(_res('ui/home/cardslistNew/common_btn_switch.png'), bgSize.width / 2, 12, {ap = display.CENTER})
    arrow:setRotation(270)
    arrow:setVisible(false)
    layer:addChild(arrow, 2)
    return {
        layer       = layer,
        touchView   = touchView,
        themeImg    = themeImg,
        themeFrame  = themeFrame,
        titleBg     = titleBg,
        titleLabel  = titleLabel,
        lockBg      = lockBg,
        lockLabel   = lockLabel,
        ownBg       = ownBg,
        discountRateBg    = discountRateBg,
        discountRateLabel = discountRateLabel,
        arrow  = arrow,
    }
end

CreateShopGoodCell_ = function (avatarType)
    local cell = CGridViewCell:new()
    local bgImg = RES_DIR.AVATAR_SHOP_GOOD_THEME_CELL_DEFAULT_BG
    local bg = display.newButton(0, 0, {n = bgImg, animate = false, ap = display.LEFT_BOTTOM})
    local bgSize = bg:getContentSize()
    -- dump(bgSize, 'bgSizebgSize')
    local layer = display.newLayer(2, 0,{size = bgSize, ap = display.LEFT_BOTTOM})
    local goodFrame = display.newImageView(RES_DIR.AVATAR_SHOP_GOOD_THEME_SELECT_FRAME, 0, 0, {scale9 = true, size = cc.size(bgSize.width * 1.025, bgSize.height * 1.025), ap = display.CENTER})
    goodFrame:setVisible(false)
    display.commonUIParams(goodFrame, {po = utils.getLocalCenter(layer)})

    cell:setContentSize(bgSize)
    layer:addChild(bg)
    cell:addChild(layer)
    layer:addChild(goodFrame, 1)

    local ownNumLabel = display.newLabel(bgSize.width / 2, bgSize.height * 0.98, fontWithColor(16, {ap = display.CENTER_TOP, text = ''}))
    ownNumLabel:setVisible(false)
    layer:addChild(ownNumLabel, 1)
    
    local goodIcon = AssetsUtils.GetRestaurantSmallAvatarNode(101001, bgSize.width / 2, bgSize.height * 0.6, {ap = display.CENTER})
    goodIcon:setVisible(false)
    layer:addChild(goodIcon)

    -- local avatarConfig = CommonUtils.GetConfigNoParser('restaurant', 'avatar', 101001)
    local goodName = display.newLabel(bgSize.width / 2, bgSize.height * 0.16, {text = '', fontSize = 24, color = '#6b5959', ap = display.CENTER_BOTTOM })
    layer:addChild(goodName)

    local priceLayer = display.newLayer(bgSize.width / 2, 0, {ap = display.CENTER_BOTTOM, size = cc.size(bgSize.width, bgSize.height * 0.2)})
    layer:addChild(priceLayer)

    local priceNum = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '1000')--
    local priceNumSize = priceNum:getContentSize()
    priceNum:setAnchorPoint(display.CENTER)
    priceNum:setHorizontalAlignment(display.TAR)

    local castIcon = display.newNSprite(_res(CommonUtils.GetGoodsIconPathById(GOLD_ID)), 0, bgSize.height * 0.1)
    local castIconSize = castIcon:getContentSize()
    castIcon:setScale(0.2)
    castIcon:setAnchorPoint(display.CENTER)

    priceNum:setPosition(cc.p(bgSize.width / 2 - castIconSize.width / 2 * 0.2, bgSize.height * 0.1))
    castIcon:setPosition(cc.p(bgSize.width / 2 + priceNumSize.width / 2, bgSize.height * 0.1))

    priceLayer:addChild(priceNum)
    priceLayer:addChild(castIcon)

    local lockIcon = display.newImageView(_res('ui/common/common_ico_lock.png'),bgSize.width / 2, bgSize.height * 0.09)
    lockIcon:setVisible(false)
    layer:addChild(lockIcon)

    local newIcon = display.newImageView(_res('ui/card_preview_ico_new_2'), bgSize.width - 20 ,bgSize.height - 20,{ ap = display.CENTER})
    newIcon:setVisible(false)
    layer:addChild(newIcon, 1)

    cell.viewData = {
        layer       = layer,
        layerPos    = cc.p(layer:getPosition()),
        bg          = bg,
        goodFrame   = goodFrame,
        ownNumLabel = ownNumLabel,
        goodIcon    = goodIcon,
        goodName    = goodName,
        priceNum    = priceNum,
        castIcon    = castIcon,

        priceLayer  = priceLayer,
        lockIcon    = lockIcon,

        newIcon     = newIcon,

        bgSize      = bgSize,
    }

    return cell
end

CreateShopThemeInventoryCell_ = function ()
    local cell = CGridViewCell:new()

    local size = cc.size(256, 40)
    cell:setContentSize(size)

    local layer = display.newLayer(0, 0, {size = size, ap = display.CENTER})
    display.commonUIParams(layer, {po = utils.getLocalCenter(cell)})
    cell:addChild(layer)

    local goodNameLabel = display.newLabel(size.width * 0.03, 2, fontWithColor(6, {ap = display.LEFT_BOTTOM}))
    layer:addChild(goodNameLabel)

    local goodNumLabel = display.newLabel(size.width * 0.97, 2, fontWithColor(6, {ap = display.RIGHT_BOTTOM}))
    layer:addChild(goodNumLabel)

    local line = display.newImageView(RES_DIR.AVATAR_SHOP_BANNER_ICO_LINE, size.width / 2, 0, {size = cc.size(size.width * 0.98, 2), scale9 = true, ap = display.CENTER_BOTTOM})
    layer:addChild(line)

    cell.viewData = {
        goodNameLabel = goodNameLabel,
        goodNumLabel = goodNumLabel,
    }
    return cell
end

function CreatePriceLabel_(parent, pos, isBMF)

    local priceNumLabel = nil
    local discountLine  = nil
    if isBMF then
        priceNumLabel = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '0')
        priceNumLabel:setAnchorPoint(display.LEFT_BOTTOM)
        priceNumLabel:setHorizontalAlignment(display.TAR)

    else
        priceNumLabel = display.newLabel(0, 0, fontWithColor(6, {text = '', ap = display.LEFT_BOTTOM}))
        discountLine = display.newImageView(_res('ui/home/commonShop/shop_sale_line.png'), pos.x, pos.y, {scale9 = true, ap = display.CENTER_BOTTOM})
    end
    local castIcon = display.newImageView(_res(CommonUtils.GetGoodsIconPathById(GOLD_ID)), pos.x, pos.y, {ap = display.LEFT_BOTTOM})
    castIcon:setScale(0.2)

    local priceNumLabelSize = display.getLabelContentSize(priceNumLabel)
    -- local priceNumLabelSize = priceNumLabel:getContentSize()
    local castIconSize = castIcon:getContentSize()

    if discountLine then
        discountLine:setContentSize(cc.size(priceNumLabelSize.width, 2))
        parent:addChild(discountLine, 1)
    end

    priceNumLabel:setPosition(cc.p(pos.x, pos.y))

    parent:addChild(priceNumLabel)
    parent:addChild(castIcon)
    return priceNumLabel, castIcon, discountLine
end

function AvatarShopView:CreateShopThemeInventoryPreviewLayer()
    return CreateShopThemeInventoryPreviewLayer_()
end

function AvatarShopView:CreateShopThemeCell()
    local cell = CGridViewCell:new()
    local viewData = CreateShopThemeCellLayer_()
    local layer = viewData.layer
    local layerSize = layer:getContentSize()
    local layerPos = cc.p(-3, layerSize.height)

    layer:setPosition(layerPos)

    cell:addChild(layer)

    viewData.layerPos = layerPos
    cell.viewData = viewData
    return cell
end

function AvatarShopView:CreateShopTabCell()
    return CreateShopTabCell_()
end

function AvatarShopView:CreateShopGoodCell(avatarType)
    return CreateShopGoodCell_(avatarType)
end

function AvatarShopView:CreateShopThemeInventoryCell()
    return CreateShopThemeInventoryCell_()
end

function AvatarShopView:CreateGoodIcon(parent, goodsId)
    return CreateGoodIcon_(parent, goodsId)
end

function AvatarShopView:getArgs()
	return self.args
end

function AvatarShopView:CloseHandler()
	local args = self:getArgs()
	local mediatorName = args.mediatorName

	local mediator = AppFacade.GetInstance():RetrieveMediator(mediatorName)
	if mediator then
		AppFacade.GetInstance():UnRegsitMediator(mediatorName)
	end

end

return AvatarShopView
