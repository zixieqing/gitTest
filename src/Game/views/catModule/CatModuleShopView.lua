--[[
 * author : panmeng
 * descpt : 猫咪市场
]]
local CatModuleShopView = class('CatModuleShopView', function()
    return ui.layer({name = 'Game.views.catModule.CatModuleShopView', enableEvent = true})
end)

local RES_DICT = {
    GUILD_SHOP_BG_WHITE    = _res('ui/home/union/guild_shop_bg_white.png'),
    GUILD_SHOP_BG          = _res('ui/home/union/guild_shop_bg.png'),
    GUILD_SHOP_TITLE       = _res('ui/home/union/guild_shop_title.png'),
    SELECT_BTN             = _res("ui/common/common_btn_tab_select.png"),
    NORMAL_BTN             = _res("ui/common/common_btn_tab_default.png"),
    COMMON_BG_GOODS        = _res('ui/common/common_bg_goods.png'),
    SHOP_BTN_GOODS_DEFAULT = _res('ui/home/commonShop/shop_btn_goods_default.png'),
    SHOP_BTN_GOODS_SELLOUT = _res('ui/home/commonShop/shop_btn_goods_sellout.png'),
    CAT_HOUSE_TIME_BG      = _res('ui/catModule/shop/grow_main_shop_bg_time.png'),
    CONFIRM_BTN            = _res('ui/common/common_btn_orange.png'),
}


function CatModuleShopView:ctor(args)
    -- create view
    self.viewData_ = CatModuleShopView.CreateView()
    self:addChild(self.viewData_.view)
end


function CatModuleShopView:getViewData()
    return self.viewData_
end


-------------------------------------------------------------------------------
-- public
-------------------------------------------------------------------------------

function CatModuleShopView:setSelectedTabIndex(tag)
    local selectedBtnTag = checkint(tag)
    for _, tabBtn in pairs(self:getViewData().tabBtns) do
        local tabBtnTag = checkint(tabBtn:getTag())
        tabBtn:setChecked(tabBtnTag == selectedBtnTag)
    end
end


function CatModuleShopView:setCellUpdateHandler(cellIndex, cellViewData, goodData)
    cellViewData.goodNode:RefreshSelf({goodsId = goodData.goodsId, num = goodData.goodsNum, showAmount = true})
    cellViewData.numLabel:setString(tostring(GoodsUtils.GetGoodsNameById(goodData.goodsId)))
    display.reloadRichLabel(cellViewData.leftTimesLabel, {c = {
        fontWithColor(8, {color = '#ac5a4a', text = string.fmt(__('剩余库存：_num_'), {_num_ = goodData.leftPurchasedNum})})
    }})

    cellViewData.numLabel:setString(goodData.price)
    cellViewData.castIcon:setTexture(CommonUtils.GetGoodsIconPathById(checkint(goodData.currency)))
    cellViewData.castIcon:setPositionX(cellViewData.numLabel:getPositionX()+cellViewData.numLabel:getBoundingBox().width*0.5 + 4)

    local isSoldOut = checkint(goodData.leftPurchasedNum) == 0
    local normalImg = isSoldOut and RES_DICT.SHOP_BTN_GOODS_SELLOUT or RES_DICT.SHOP_BTN_GOODS_DEFAULT
    cellViewData.toggleView:setNormalImage(normalImg)
    cellViewData.toggleView:setSelectedImage(normalImg)
    cellViewData.toggleView:setEnabled(not isSoldOut)
    cellViewData.toggleView:setTag(cellIndex)
    cellViewData.sellLabel:setVisible(isSoldOut)
    cellViewData.leftTimesLabel:setVisible(checkint(goodData.leftPurchasedNum) > 0)
end


function CatModuleShopView:refershShopUpdateLeftTime(time)
    local timeText = CommonUtils.getTimeFormatByType(checkint(time), 2)
    self:getViewData().leftSecondsText:updateLabel({text = timeText})
end


-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function CatModuleShopView.CreateView()
    local view = ui.layer()
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    -- black / block layer
    local viewFrame = ui.layer({bg = RES_DICT.GUILD_SHOP_BG})
    local viewSize  = cc.resize(viewFrame:getContentSize(), -100, -20)
    local backGroundGroup = view:addList({
        ui.layer({color = cc.c4b(0,0,0,150), enable = true}),
        ui.layer({color = cc.r4b(0), enable = true, size = viewSize}),
        viewFrame,
        ui.layer({size = viewSize}),
    })
    ui.flowLayout(cpos, backGroundGroup, {type = ui.flowC, ap = ui.cc})

    -- centerLayer
    local centerLayer = backGroundGroup[4]
    local bgFrame = ui.image({img = RES_DICT.GUILD_SHOP_BG_WHITE})
    centerLayer:addList(bgFrame):alignTo(nil, ui.cc, {offsetY = -20})

    -- frameGroup
    local gridBgSize = cc.resize(viewSize, -70, -145)
    local frameGroup = centerLayer:addList({
        ui.title({n = RES_DICT.GUILD_SHOP_TITLE}):updateLabel({fnt = FONT.D18, text = __("猫猫商店"), reqW = 240}),
        ui.layer({size = cc.size(gridBgSize.width, 80)}),
        ui.layer({bg = RES_DICT.COMMON_BG_GOODS, scale9 = true, size = gridBgSize})
    })
    ui.flowLayout(cc.sizep(centerLayer, ui.cc), frameGroup, {type = ui.flowV, ap = ui.cc})

    local batchBuyBtn = ui.button({n = RES_DICT.CONFIRM_BTN, scale9 = true, ap = ui.lc}):updateLabel({fnt = FONT.D14, text = __('快速购买'), paddingW = 20, safeW = 100})
    centerLayer:addList(batchBuyBtn):alignTo(nil, ui.lt, {offsetX = 40, offsetY = -60})

    -- tabBtns
    -- local tabBtns = {}
    -- local tabLayer = frameGroup[2]
    -- for _, tabBtnInfo in pairs(TAB_BTN_INFO) do
    --     local tabBtn = CatModuleShopView.CreateTabBtn(tabBtnInfo)
    --     tabBtn:setTag(tabBtnInfo.tag)
    --     tabLayer:add(tabBtn)
    --     table.insert(tabBtns, tabBtn)
    -- end
    -- ui.flowLayout(cc.rep(cc.sizep(tabLayer, ui.lb), 7, -2), tabBtns, {type = ui.flowH, gapW = 10, ap = ui.lb})

    local timeGroup = frameGroup[2]:addList({
        ui.label({fnt = FONT.D3, color = "#A27055", text = __('系统刷新倒计时')}),
        ui.title({img = RES_DICT.CAT_HOUSE_TIME_BG}):updateLabel({fnt = FONT.D3, color = "#793615", ap = ui.rc, offset = cc.p(80, 0), text = "--"})
    })
    ui.flowLayout(cc.sizep(frameGroup[2], ui.rc), timeGroup, {type = ui.flowV, ap = ui.rc})
    
    -- gridView
    local gridLayer = frameGroup[3]
    local gridSize  = gridLayer:getContentSize()
    local GRID_COL  = 5
    local goodsGridView = ui.gridView({cols = GRID_COL, dir = display.SDIR_V, csizeH = 260, size = gridSize})
    gridLayer:addList(goodsGridView):alignTo(nil, ui.cc)
    goodsGridView:setCellCreateClass(require('Game.views.CommonShopCell'))

    -- moneyBar
    local moneyBar = require('common.CommonMoneyBar').new()
    moneyBar:reloadMoneyBar({CAT_COPPER_COIN_ID}, false)
    moneyBar:setEnableGainPopup(true)
    view:add(moneyBar)

    return {
        view            = view,
        blockLayer      = backGroundGroup[1],
        --              = center
        -- tabBtns         = tabBtns,
        goodsGridView   = goodsGridView,
        moneyBar        = moneyBar,
        leftSecondsText = timeGroup[2],
        batchBuyBtn     = batchBuyBtn,
    }
end

-- function CatModuleShopView.CreateTabBtn(btnInfo)
--     local btnNode = ui.tButton({n = RES_DICT.NORMAL_BTN, s = RES_DICT.SELECT_BTN})

--     -- add title text
--     local nLabel  = ui.label({text = tostring(btnInfo.title), fnt = FONT.D20, fontSize = 22, outline = "#6c351a"})
--     btnNode:getNormalImage():addList(nLabel):alignTo(nil, ui.cc)

--     local sLabel  = ui.label({text = tostring(btnInfo.title), fnt = FONT.D20, fontSize = 22, outline = "#6c351a", color = "#ecd8cd"})
--     btnNode:getSelectedImage():addList(sLabel):alignTo(nil, ui.cc)

--     return btnNode
-- end

return CatModuleShopView
