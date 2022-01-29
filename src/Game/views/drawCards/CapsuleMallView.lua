--[[
 * descpt : 新抽卡视图
]]
local CapsuleMallView   = class('CapsuleMallView', function()
    return display.newLayer(0, 0, {name = 'Game.views.drawCards.CapsuleMallView'})
end)

local RES_DICT = {
    BTN_BACK        = _res('ui/common/common_btn_back.png'),
    TITLE_BAR       = _res('ui/common/common_title_new.png'),
    BTN_TIPS        = _res('ui/common/common_btn_tips.png'),
    MAIN_BG_03      = _res('arts/stage/bg/main_bg_03'),

    SHOP_BG_ADD     = _res('ui/home/commonShop/shop_bg_add'),
    SHOP_BG_LIEBIAO = _res('ui/home/commonShop/shop_bg_liebiao.png'),
    SHOP_IMG_DOWN   = _res('ui/home/commonShop/shop_img_down.png'),
    SHOP_BTN_TAB_SELECT  = _res('ui/home/commonShop/shop_btn_tab_select.png'),
    SHOP_BTN_TAB_DEFAULT = _res('ui/home/commonShop/shop_btn_tab_default.png'),

    SUMMON_SHOP_PREVIEW_BG_GOODS  = _res('ui/home/capsuleNew/skinCapsule/shop/summon_shop_preview_bg_goods.png'),
    SUMMON_SHOP_BG_TAB_NORMAL     = _res('ui/home/capsuleNew/skinCapsule/shop/summon_shop_bg_tab_normal.png'),
    SUMMON_SHOP_BG_TAB_SELECTED   = _res('ui/home/capsuleNew/skinCapsule/shop/summon_shop_bg_tab_selected.png'),
}

local CreateView     = nil


function CapsuleMallView:ctor(args)
    self:initUI()
end

function CapsuleMallView:initUI()
    xTry(function ( )
        self.viewData_ = CreateView()
        self:addChild(self.viewData_.view)
	end, __G__TRACKBACK__)
end

function CapsuleMallView:CreateCell(size)
    local node = CExpandableNode:new()
    node:setContentSize(size)

    local btn = display.newButton(size.width / 2, size.height / 2, {ap = display.CENTER, animate = false, n = RES_DICT.SHOP_BTN_TAB_DEFAULT})
    display.commonLabelParams(btn, fontWithColor(14))
    btn:setName('btn')
    node:addChild(btn)

    return node
end

function CapsuleMallView:updateCellSelectState(cell, isSelect)
    local btn = cell:getChildByName('btn')
    if btn then
        local img = isSelect and RES_DICT.SHOP_BTN_TAB_SELECT or RES_DICT.SHOP_BTN_TAB_DEFAULT
        btn:setNormalImage(img)
        btn:setSelectedImage(img)
    end
end

function CapsuleMallView:CreateItem(size)
    local item = CLayout:create()
    item:setContentSize(size)

    local btn = display.newButton(size.width / 2, size.height / 2, {ap = display.CENTER, animate = false, n = RES_DICT.SHOP_BTN_TAB_DEFAULT})
    display.commonLabelParams(btn, fontWithColor(14))
    btn:setName('btn')
    item:addChild(btn)

    return item
end

function CapsuleMallView:updateItemSelectState(cell, isSelect)
    local btn = cell:getChildByName('btn')
    if btn then
        local img = isSelect and RES_DICT.SUMMON_SHOP_BG_TAB_SELECTED or RES_DICT.SUMMON_SHOP_BG_TAB_NORMAL
        btn:setNormalImage(img)
        btn:setSelectedImage(img)
    end
end

function CapsuleMallView:updateMoneyBarGoodList(args)
    local viewData = self:getViewData()
    args.isEnableGain = true
    viewData.moneyBar:RefreshUI(args)
end


function CapsuleMallView:updateMoneyBarGoodNum()
    local viewData = self:getViewData()
    viewData.moneyBar:updateMoneyBar()
end

CreateView = function()
    local view = display.newLayer()
    local size = view:getContentSize()

    -- bg
    view:addChild(display.newImageView(RES_DICT.MAIN_BG_03, display.cx, display.cy, {isFull = true, enable = true}))

    ---------------------------------
    ------ top ui layer
    local topUILayer = display.newLayer()
    view:addChild(topUILayer, 1)
    
    -- back button
    local backBtn = display.newButton(display.SAFE_L + 75, size.height - 52, {n = RES_DICT.BTN_BACK})
    topUILayer:addChild(backBtn)

    -- title button
    local titleBtn = display.newButton(display.SAFE_L + 120, size.height, {n = RES_DICT.TITLE_BAR, ap = display.LEFT_TOP, enable = true, scale9 = true, capInsets = cc.rect(100, 70, 80, 1)})
    display.commonLabelParams(titleBtn, fontWithColor(1, {text = __('兑换'), offset = cc.p(0, -10), ttf = false}))
    topUILayer:addChild(titleBtn)

    -- local titleSize = titleBtn:getContentSize()
    -- local tipsIcon  = display.newImageView(_res(RES_DIR.BTN_TIPS), titleSize.width - 50, titleSize.height/2 - 10)
    -- titleBtn:addChild(tipsIcon)

    local moneyUILayer = display.newLayer()
    view:addChild(moneyUILayer, 2)
    -- CommonMoneyBar
    local moneyBar = require("common.CommonMoneyBar").new()
    moneyUILayer:addChild(moneyBar)

    ---------------------------------
    ------ content ui layer
    local contentUILayer = display.newLayer()
    view:addChild(contentUILayer)

    contentUILayer:addChild(display.newNSprite(RES_DICT.SHOP_BG_ADD, size.width / 2 - 56, size.height / 2 - 34, {ap = display.CENTER}))

    local listBg = display.newNSprite(RES_DICT.SHOP_BG_LIEBIAO, size.width / 2 - 507, size.height / 2 - 61, {ap = display.CENTER})
    contentUILayer:addChild(listBg)

    listBg:addChild(display.newNSprite(RES_DICT.SHOP_IMG_DOWN, 88, 0, {ap = display.CENTER_BOTTOM}))

    local expandableListSize = cc.size(158, 550)
    local expandableListView = CExpandableListView:create(expandableListSize)
    expandableListView:setPosition(cc.p(size.width / 2 - 515, size.height / 2 - 58))
    expandableListView:setDirection(eScrollViewDirectionVertical)
    expandableListView:setAnchorPoint(display.CENTER)
    contentUILayer:addChild(expandableListView)

    ---------------------------------
    ------ child ui layer
    local childUISize = cc.size(838, 570)
    local childUILayer = display.newLayer(size.width / 2 + 12, size.height / 2 - 60, {ap = display.CENTER, size = childUISize})
    view:addChild(childUILayer)

    childUILayer:addChild(display.newNSprite(RES_DICT.SUMMON_SHOP_PREVIEW_BG_GOODS, childUISize.width / 2, childUISize.height / 2, {ap = display.CENTER, scale9 = true, size = childUISize}))

    return {
        view               = view,
        backBtn            = backBtn,
        moneyBar           = moneyBar,
        expandableListView = expandableListView,
        childUILayer       = childUILayer,
    }
end


-------------------------------------------------
-- self view

function CapsuleMallView:getViewData()
    return self.viewData_
end

return CapsuleMallView
