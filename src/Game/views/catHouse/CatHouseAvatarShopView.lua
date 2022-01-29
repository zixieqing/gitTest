--[[
 * author : zhipeng
 * descpt : 猫屋 - 家具商店 界面
]]
local CatHouseAvatarShopView = class('CatHouseAvatarShopView', function()
    return ui.layer({name = 'Game.views.catHouse.CatHouseAvatarShopView', enableEvent = true, ap = display.CENTER})
end)
-------------------------------------------------
-------------------- import ---------------------
local DragNode = require('Game.views.catHouse.avatar.CatHouseDragNode')
-------------------- import ---------------------
-------------------------------------------------

-------------------------------------------------
-------------------- define ---------------------
local RES_DICT = {
    SHOP_BG                    = _res('avatar/ui/avatarShop/avator_bg_shop.png'),
    REMIND_ICON                = _res('ui/common/common_hint_circle_red_ico.png'),
    TAB_SPLIT_LINE             = _res('avatar/ui/avatarShop/avator_banner_ico_line.png'),
    TAB_SELECT_BG              = _res('avatar/ui/avatarShop/avator_banner_btn_selected.png'),
    GOODS_BG_N                 = _res('ui/home/commonShop/shop_btn_goods_default.png'),
    GOODS_BG_S                 = _res('ui/home/commonShop/shop_btn_goods_selected.png'),
    GOODS_SELECT_FRAME         = _res('avatar/ui/avatarShop/avator_goods_bg_l_selected.png'),
    PREVIEW_BG                 = _res('avatar/ui/avatarShop/avator_goods_bg_preview.png'),
    OWN_NUM_BG                 = _res('avatar/ui/avatarShop/avator_goods_preview_bg_num.png'),
    PREVIEW_ATTIBUTE_BG        = _res('avatar/ui/avatarShop/avator_goods_bg_attibute.png'),
    PURCHASE_AMOUNT_BG         = _res('ui/home/market/market_buy_bg_info.png'),
    PURCHASE_AMOUNT_SUB_BTN    = _res('avatar/ui/market_sold_btn_sub.png'),
    PURCHASE_AMOUNT_ADD_BTN    = _res('avatar/ui/market_sold_btn_plus.png'),
    PREVIEW_SALE_NUM_BG        = _res('avatar/ui/avatarShop/avator_bg_sale_number.png'),
    COMMON_BTN                 = _res('ui/common/common_btn_orange.png'),
    
}
local CreateTabListCell = nil
local CreateGoodsListCell = nil

-------------------- define ---------------------
-------------------------------------------------

-------------------------------------------------
------------------ inheritance ------------------
function CatHouseAvatarShopView:ctor(args)
    self.args = args
    self:InitialUI()
end
------------------ inheritance ------------------
-------------------------------------------------

-------------------------------------------------
-------------------- private --------------------
function CatHouseAvatarShopView:InitialUI()
    local function CreateView()
        local size = cc.size(1200, 610)
        local view = display.newLayer(display.cx, display.cy, {size = size, ap = display.CENTER})
        -- mask
        local mask = display.newLayer(display.cx, display.cy, {size = size, ap = display.CENTER, enable = true, color = cc.c4b(0, 0, 0, 0)})
        view:addChild(mask, -1)
        -- bg 
        local bg = display.newImageView(RES_DICT.SHOP_BG, size.width / 2, size.height / 2)
        view:addChild(bg, 1)
        -- CommonMoneyBar
        local moneyBar = require("common.CommonMoneyBar").new()
		self:addChild(moneyBar, 10)
        -- 页签
        local tabGridViewSize = cc.size(158, 574)
        local tabTableView = ui.tableView({x = 110, y = size.height / 2 + 6, size = tabGridViewSize, csizeH = 80, dir = display.SDIR_V, bounce = false})
        tabTableView:setCellCreateHandler(CreateTabListCell)
        view:addChild(tabTableView, 1)
        -- 道具列表
        local goodsGridViewSize = cc.size(670, 560)
        local goodsGridView = ui.gridView({x = size.width / 2 - 60, y = size.height / 2 + 6, size = goodsGridViewSize, cols = 3, csizeH = 260, auto = true})
        goodsGridView:setCellCreateHandler(CreateGoodsListCell)
        view:addChild(goodsGridView, 1)

        -- 道具预览 --
        local previewLayoutSize = cc.size(320, 600)
        local previewLayout = CLayout:create(previewLayoutSize)
        previewLayout:setPosition(cc.p(size.width - 170, size.height / 2))
        view:addChild(previewLayout, 1)
        -- 背景
        local previewBg = display.newImageView(RES_DICT.PREVIEW_BG, previewLayoutSize.width / 2, previewLayoutSize.height - 210)
        previewLayout:addChild(previewBg, 1)
        local previewBgSize = previewBg:getContentSize()
        local previewBgLayer = display.newLayer(previewLayoutSize.width / 2, previewLayoutSize.height - 210, {size = previewBgSize, ap = display.CENTER})
        previewLayout:addChild(previewBgLayer, 1)
        -- 拥有数量
        local ownNumBg = display.newImageView(RES_DICT.OWN_NUM_BG, previewBgSize.width - 2, previewBgSize.height - 2, {ap = display.RIGHT_TOP})
        previewBgLayer:addChild(ownNumBg, 1)
        local ownNumLabel = display.newLabel(ownNumBg:getContentSize().width / 2, ownNumBg:getContentSize().height / 2, fontWithColor(18, {text = ''}))
        ownNumBg:addChild(ownNumLabel, 1)
        -- 道具图标layer
        local goodIconSize = cc.size(previewBgSize.width * 0.9, previewBgSize.height * 0.69)
        local goodIconLayer = display.newLayer(previewBgSize.height * 0.05, previewBgSize.height * 0.2, {size = goodIconSize, ap = display.LEFT_BOTTOM})
        previewBgLayer:addChild(goodIconLayer)
        -- 属性
        local previewAttibute = display.newButton(previewBgSize.width / 2, 0, {ap = display.CENTER_BOTTOM, n = RES_DICT.PREVIEW_ATTIBUTE_BG, scale9 = true})
        previewBgLayer:addChild(previewAttibute)
        -- 售卖layer
        local soldSize = cc.size(previewLayoutSize.width, 53)
        local soldLayer = display.newLayer(previewLayoutSize.width / 2, previewLayoutSize.height * 0.23, {size = soldSize, ap = display.CENTER_BOTTOM})
        previewLayout:addChild(soldLayer, 1)
        --选择数量
        local btnNumSize = cc.size(180, 44)
        local btnNum = display.newButton(0, 0, {n = RES_DICT.PURCHASE_AMOUNT_BG, scale9 = true, size = btnNumSize})
        display.commonUIParams(btnNum, {po = cc.p(soldSize.width * 0.5, soldSize.height / 2),ap = cc.p(0.5, 0.5)})
        display.commonLabelParams(btnNum, {text = '1', fontSize = 28, color = '#7c7c7c'})
        soldLayer:addChild(btnNum)
        --减号btn
        local btnSub = display.newButton(0, 0, {n = RES_DICT.PURCHASE_AMOUNT_SUB_BTN})
        display.commonUIParams(btnSub, {po = cc.p(soldSize.width * 0.5 - btnNumSize.width / 2, soldSize.height / 2),ap = cc.p(0.5, 0.5)})
        soldLayer:addChild(btnSub)
        --加号btn
        local btnAdd = display.newButton(0, 0, {n = RES_DICT.PURCHASE_AMOUNT_ADD_BTN})
        display.commonUIParams(btnAdd, {po = cc.p(soldSize.width * 0.5 + btnNumSize.width / 2, soldSize.height / 2),ap = cc.p(0.5, 0.5)})
        soldLayer:addChild(btnAdd)
        -- 价格
        local saleNumBg = display.newImageView(RES_DICT.PREVIEW_SALE_NUM_BG, previewLayoutSize.width / 2, previewLayoutSize.height * 0.22, {ap = display.CENTER_TOP})
        local saleNumBgSize = saleNumBg:getContentSize()
        previewLayout:addChild(saleNumBg, 1)
    
        local originalPriceLayer = display.newLayer(previewLayoutSize.width / 2, previewLayoutSize.height * 0.22, {size = saleNumBgSize, ap = display.CENTER_TOP})
        previewLayout:addChild(originalPriceLayer, 1)
        
        local totalPriceLabel = display.newLabel(0, 0, fontWithColor(6, {text = '总价:', ap = display.RIGHT_CENTER}))
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
    
        local buyBtn = display.newButton(previewLayoutSize.width / 2, 20, {ap = display.CENTER_BOTTOM, n = RES_DICT.COMMON_BTN})
        display.commonLabelParams(buyBtn, fontWithColor(14, {text = __('购买')}))
        previewLayout:addChild(buyBtn)
        -- 道具预览 --
        return {
            view          = view,
            moneyBar      = moneyBar,
            tabTableView  = tabTableView,
            goodsGridView = goodsGridView,

            previewBgLayer = previewBgLayer,
            previewLayout  = previewLayout,
            ownNumLabel = ownNumLabel,
            soldLayer = soldLayer,
            btnNum = btnNum,
            btnSub = btnSub,
            btnAdd = btnAdd,
            buyBtn = buyBtn,
            goodIconLayer = goodIconLayer,
            previewAttibute = previewAttibute,
            saleNumBg = saleNumBg,
            originalPriceLayer = originalPriceLayer,
            totalPriceLabel = totalPriceLabel,
            totalPriceNum = totalPriceNum,
            castIcon = castIcon,
            saleNumBgSize = saleNumBgSize,
        }
    end
    -- eaterLayer
    local eaterLayer = display.newLayer(display.cx, display.cy, {size = display.size, ap = display.CENTER, color = cc.c4b(0, 0, 0, 255 * 0.6), enable = true})
    self:addChild(eaterLayer, -1)
    self.eaterLayer = eaterLayer
    xTry(function ( )
        self.viewData = CreateView( )
        self:addChild(self.viewData.view)
	end, __G__TRACKBACK__)
end
--[[
初始化货币栏
--]]
function CatHouseAvatarShopView:InitMoneyBar( moneyIdMap )
    local viewData = self:GetViewData()
    viewData.moneyBar:reloadMoneyBar(moneyIdMap, false)
    viewData.moneyBar:setEnableGainPopup(true)
end
--[[
更新道具cell选中状态
@params cell     gridCell 列表cell
@params isSelect bool     是否选中
--]]
function CatHouseAvatarShopView:UpdateGoodsCellSelectState( cell, isSelect )
    local goodsFrame = cell:getChildByName('goodsFrame')
    if goodsFrame then
        goodsFrame:setVisible(isSelect)
    end
end
--[[
刷新道具预览
@params goodsData      map 道具数据
@Params purchaseAmount int 购买数量
--]]
function CatHouseAvatarShopView:RefreshGoodsPreview( goodsData,  purchaseAmount )
    local viewData = self:GetViewData()

    viewData.previewLayout:setVisible(next(checktable(goodsData)) ~= nil)
    if next(checktable(goodsData)) == nil then
        return
    end
    self:UpdatePreviewPurchaseAmount(purchaseAmount, goodsData.price, goodsData.currency )
    local buffDesc = string.fmt(__('小屋舒适度提高_target_num_点'), {['_target_num_'] = goodsData.comfort})
    display.commonLabelParams(viewData.previewAttibute, fontWithColor(5, {text = buffDesc, w = 280, hAlign = display.TAC}))
    local buffDescSize = display.getLabelContentSize(viewData.previewAttibute:getLabel())
    viewData.previewAttibute:setContentSize(cc.size(viewData.previewAttibute:getContentSize().width, buffDescSize.height + 6))
    self:CreateGoodIcon(viewData.goodIconLayer, goodsData.id)
    display.commonLabelParams(viewData.ownNumLabel, {text = string.fmt(__('已有:_num_'),{_num_ = app.gameMgr:GetAmountByGoodId(goodsData.id)})})
end
--[[
刷新购买数量
@params amount   int 购买数量
@params price    int 商品单价
@params currency int 货币id
--]]
function CatHouseAvatarShopView:UpdatePreviewPurchaseAmount( amount, price, currency )
    local viewData = self:GetViewData()
    if not amount then amount = 1 end
    viewData.btnNum:getLabel():setString(amount)
    self:UpdatePreviewPurchasePrice(amount, price, currency)
end
--[[
刷新购买价格
@params amount   int 购买数量
@params price    int 商品单价
@params currency int 货币id
--]]
function CatHouseAvatarShopView:UpdatePreviewPurchasePrice( amount, price, currency )
    local viewData = self:GetViewData()
    local totalPrice = checkint(amount) * checkint(price)
    viewData.totalPriceNum:setString(totalPrice)
    local currency = checkint(currency)
    viewData.castIcon:setTexture(GoodsUtils.GetIconPathById(currency))
    local totalPriceNumSize = viewData.totalPriceNum:getContentSize()
    
    viewData.totalPriceLabel:setPosition(cc.p(viewData.saleNumBgSize.width / 2 - totalPriceNumSize.width / 2, viewData.saleNumBgSize.height / 2))
    viewData.totalPriceNum:setPosition(cc.p(viewData.saleNumBgSize.width / 2, viewData.saleNumBgSize.height / 2))
    viewData.castIcon:setPosition(cc.p(viewData.saleNumBgSize.width / 2 + totalPriceNumSize.width / 2, viewData.saleNumBgSize.height / 2))
end
--[[
创建预览道具icon
--]]
function CatHouseAvatarShopView:CreateGoodIcon( parent, goodsId )
    if parent and parent:getChildrenCount() > 0 then
        parent:removeAllChildren()
    end
    local parentSize   = parent:getContentSize()
    local locationConf = CONF.CAT_HOUSE.AVATAR_LOCATION:GetValue(goodsId)
    local avatarType   = CatHouseUtils.GetAvatarTypeByGoodsId(goodsId)

    local goodIcon = DragNode.new({id = goodsId, avatarId = goodsId, nType = avatarType, configInfo = locationConf, enable = false})
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

CreateTabListCell = function ( cellParent )
    local view = cellParent
    local size = cellParent:getContentSize()
    -- button 
    local button = display.newButton(size.width / 2, size.height / 2, {n = 'empty', size = size})
    view:addChild(button, 5)
    -- 分割线
    local line = display.newImageView(RES_DICT.TAB_SPLIT_LINE, size.width / 2, 0, {ap = display.CENTER_BOTTOM})
    view:addChild(line, 1)
    -- 标题
    local nTitle = display.newLabel(size.width / 2, size.height / 2, fontWithColor(4, {text = '主题'}))
    view:addChild(nTitle, 1)
    -- 选中背景
    local sBg = display.newImageView(RES_DICT.TAB_SELECT_BG, size.width / 2, size.height / 2)
    view:addChild(sBg, 1)
    -- 选中图片
    local sImg = display.newImageView('', sBg:getContentSize().width / 2, sBg:getContentSize().height / 2 + 20)
    sBg:addChild(sImg, 1)
    -- 选中标题
    local sTitle = display.newLabel(sBg:getContentSize().width / 2, 14, fontWithColor(17, {text = '标题'}))
    sBg:addChild(sTitle, 1)
    -- 红点
    local redPointIcon = display.newImageView(RES_DICT.REMIND_ICON, size.width - 15, size.height - 10)
    redPointIcon:setVisible(false)
    view:addChild(redPointIcon, 1)
    return {
        view         = view,
        button       = button,
        nTitle       = nTitle,
        sTitle       = sTitle,
        sBg          = sBg,
        sImg         = sImg,
        redPointIcon = redPointIcon
    }
end
CreateGoodsListCell = function ( cellParent )
    local view = cellParent
    local size = cellParent:getContentSize()
    -- 背景按钮
    local bg = display.newButton(size.width / 2, size.height / 2, {n = RES_DICT.GOODS_BG_N, useS = false})
    view:addChild(bg, 1)
    local goodsFrame = display.newImageView(RES_DICT.GOODS_SELECT_FRAME, size.width / 2, size.height / 2, {scale9 = true, size = cc.resize(bg:getContentSize(), 8, 10)})
    goodsFrame:setName('goodsFrame')
    goodsFrame:setVisible(false)
    view:addChild(goodsFrame, 5)
    -- 已有数量
    local ownNumLabel = display.newLabel(size.width / 2, size.height - 15, fontWithColor(16, {ap = display.CENTER_TOP, text = ''}))
    view:addChild(ownNumLabel, 3)
    -- 道具
    local goodIcon = AssetsUtils.GetCatHouseSmallAvatarNode(101001, size.width / 2, size.height * 0.6, {ap = display.CENTER})
    goodIcon:setScale(0.7)
    view:addChild(goodIcon, 4)
    local goodName = display.newLabel(size.width / 2, 54, {text = '', fontSize = 24, color = '#6b5959', ap = display.CENTER_BOTTOM})
    view:addChild(goodName, 5)
    -- 价格
    local priceLayer = display.newLayer(size.width / 2, 0, {ap = display.CENTER_BOTTOM, size = cc.size(size.width, size.height * 0.2)})
    view:addChild(priceLayer, 5)
    local priceNum = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '')
    local priceNumSize = priceNum:getContentSize()
    priceNum:setAnchorPoint(display.CENTER)
    priceNum:setHorizontalAlignment(display.TAR)
    local castIcon = display.newNSprite(_res(CommonUtils.GetGoodsIconPathById(GOLD_ID)), 0, size.height * 0.1)
    local castIconSize = castIcon:getContentSize()
    castIcon:setScale(0.2)
    castIcon:setAnchorPoint(display.CENTER)
    priceNum:setPosition(cc.p(size.width / 2 - castIconSize.width / 2 * 0.2, size.height * 0.1))
    castIcon:setPosition(cc.p(size.width / 2 + priceNumSize.width / 2, size.height * 0.1))
    priceLayer:addChild(priceNum)
    priceLayer:addChild(castIcon)
    -- 锁定图标
    local lockIcon = display.newImageView(_res('ui/common/common_ico_lock.png'),size.width / 2, 30)
    lockIcon:setVisible(false)
    view:addChild(lockIcon, 4)
    -- new图标
    local newIcon = display.newImageView(_res('ui/card_preview_ico_new_2'), size.width - 20 ,size.height - 20,{ ap = display.CENTER})
    newIcon:setVisible(false)
    view:addChild(newIcon, 4)
    return {
        size        = size,
        view        = view,
        bg          = bg,
        goodsFrame  = goodsFrame,
        ownNumLabel = ownNumLabel,
        goodIcon    = goodIcon,
        goodName    = goodName,
        priceNum    = priceNum,
        castIcon    = castIcon,
        priceLayer  = priceLayer,
        lockIcon    = lockIcon,
        newIcon     = newIcon,
    }
end
-------------------- private --------------------
-------------------------------------------------

-------------------------------------------------
------------------- get / set -------------------
function CatHouseAvatarShopView:GetViewData()
    return self.viewData
end
------------------- get / set -------------------
-------------------------------------------------

return CatHouseAvatarShopView
