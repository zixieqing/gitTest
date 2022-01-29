--[[
 * author : kaishiqi
 * descpt : 新游戏商店 - 卡皮商店视图
]]
---@class DiamondStoreActivityCellView
local DiamondStoreActivityCellView = class('DiamondStoreActivityCellView', function()
    local DiamondStoreActivityCellView = display.newLayer(0, 0, { ap = display.CENTER, size = cc.size(280, 122) })
    DiamondStoreActivityCellView.name  = 'Game.view.stores.DiamondStoreActivityCellView'
    DiamondStoreActivityCellView:enableNodeEvents()
    return DiamondStoreActivityCellView
end)
local newImageView                 = display.newImageView
local newLabel                     = display.newLabel
local newLayer                     = display.newLayer
local RES_DICT                     = {
    SHOP_LINE_2                  = _res('ui/stores/diamond/shop_line_2.png'),
    SHOP_DIAMONDS_ICO_LIGHT      = _res('ui/stores/diamond/shop_diamonds_ico_light.png'),
    SHOP_BG_TEXT                 = _res('ui/stores/diamond/shop_bg_text.png'),
    SHOP_TAG_X2                  = _res('ui/stores/diamond/shop_tag_x2.png'),
    SHOP_BG_TEXT_AD              = _res('ui/stores/diamond/shop_bg_text_ad.png'),
    SHOP_TAG_DOUBLE              = _res('ui/stores/diamond/shop_tag_double.png'),
    SHOP_BG_MONEY_DIAMONDS       = _res('ui/stores/diamond/shop_bg_money_diamonds.png'),
    SHOP_BTN_DIAMONDS_AD_DEFAULT = _res('ui/stores/diamond/shop_btn_diamonds_ad_default.png'),
    SHOP_FRAME_AD_UP             = _res('ui/stores/diamond/shop_frame_ad_up.png'),
    SHOP_ICO_TIME                = _res('ui/stores/diamond/shop_ico_time.png'),
    SHOP_DIAMOND_BG_TIMELEFT     = _res('ui/stores/diamond/shop_diamond_bg_timeleft.png'),
    TEMP_AD_UP                   = _res('ui/stores/diamond/temp_ad_up.png'),
    SHOP_BTN_DIAMONDS_AD_SOLDOUT = _res('ui/stores/diamond/shop_btn_diamonds_ad_soldout.png'),
    SHOP_BTN_DIAMONDS_DEFAULT    = _res('ui/stores/diamond/shop_btn_diamonds_default.png'),
    SHOP_BG_TEXT_AD_SOLDOUT      = _res('ui/stores/diamond/shop_bg_text_ad_soldout.png'),
    SHOP_DIAMONDS_ICO_1          = _res('ui/stores/diamond/shop_diamonds_ico_1.png'),
    SALE_LINE_DISABELD           = _res('ui/common/line_delete_2.png')
}

function DiamondStoreActivityCellView:ctor()
    self:InitView()
end

function DiamondStoreActivityCellView:InitView()
    local diamondActivityLayoutSize = cc.size(280, 122)
    local diamondActivityLayout     = newLayer(diamondActivityLayoutSize.width/2, diamondActivityLayoutSize.height/2,
                                               { ap = display.CENTER, color = cc.c4b(0,0,0,0), size = diamondActivityLayoutSize, enable = true })
    self:addChild(diamondActivityLayout)

    local diamondImage = newImageView(RES_DICT.SHOP_BTN_DIAMONDS_AD_DEFAULT, diamondActivityLayoutSize.width/2, diamondActivityLayoutSize.height/2,
                                      { ap = display.CENTER, tag = 83, enable = false , size = cc.size(285,122) , scale9 = true  })
    diamondActivityLayout:addChild(diamondImage)

    local limitLabel = newLabel(diamondActivityLayoutSize.width/2, 18,
                                { ap = display.CENTER, color = '#ffffff', text = "", fontSize = 20, tag = 86 })
    diamondActivityLayout:addChild(limitLabel)

    local dimondLayout = newLayer(diamondActivityLayoutSize.width/2, 89,
                                  { ap = display.CENTER, color = cc.r4b(0), size = cc.size(200, 48), enable = true })
    diamondActivityLayout:addChild(dimondLayout)

    local shopTextImage = newImageView(RES_DICT.SHOP_BG_TEXT_AD, 100, 24,
                                       { ap = display.CENTER, tag = 85, enable = false })
    dimondLayout:addChild(shopTextImage)

    local originalPrice = newLabel(diamondActivityLayoutSize.width/4, 45,
                                   fontWithColor(14, { ap = display.CENTER, color = '#c9c9c9', text = "￥111", fontSize = 20, tag = 91 }))
    diamondActivityLayout:addChild(originalPrice)

    local lineDeleteImage = display.newImageView(RES_DICT.SALE_LINE_DISABELD, 63, 45)
    diamondActivityLayout:addChild(lineDeleteImage)
    lineDeleteImage:setScaleX(0.7)

    local presentPrice = newLabel(diamondActivityLayoutSize.width/4 * 3, 45,
                                  fontWithColor(14, { ap = display.CENTER, color = '#ffffff', text = "￥11", fontSize = 24, tag = 92 }))
    diamondActivityLayout:addChild(presentPrice)
    local buyDiamondLabel = display.newRichLabel(diamondActivityLayoutSize.width / 2, diamondActivityLayoutSize.height - 30, {
        ap = display.CENTER, r = true, c = {
            fontWithColor('14', { text = 14 }),
            { img = CommonUtils.GetGoodsIconPathById(DIAMOND_ID), scale = 0.23 }
        }
    })
    diamondActivityLayout:addChild(buyDiamondLabel)

    self.viewData_ = {
        diamondActivityLayout = diamondActivityLayout,
        diamondImage          = diamondImage,
        limitLabel            = limitLabel,
        dimondLayout          = dimondLayout,
        shopTextImage         = shopTextImage,
        originalPrice         = originalPrice,
        presentPrice          = presentPrice,
        buyDiamondLabel          = buyDiamondLabel,
    }
end
function DiamondStoreActivityCellView:getTotalPurchased(data)
    return checkint(data.lifeLeftPurchasedNum)
end
function DiamondStoreActivityCellView:getTodayPurchased(data)
    return checkint(data.todayLeftPurchasedNum)
end
-- about stock
function DiamondStoreActivityCellView:getTotalStock(data)
    return checkint(data.lifeStock)
end
function DiamondStoreActivityCellView:getTodayStock(data)
    return checkint(data.stock)
end
--==============================--
---@Description: 更新售卖的情况
---@param data table 售罄的状态 1、leftTimes 今日剩余购买次数 2、data数据信息
---@author : xingweihao
---@date : 2019/1/15 9:50 PM
--==============================--
function DiamondStoreActivityCellView:UpdateSellLeftTimes(data , index )
    local viewData_ = self.viewData_
    viewData_.diamondActivityLayout:setTag(index)
    viewData_.diamondActivityLayout:setOnClickScriptHandler(function(sender)
        local tag = sender:getTag()
        app:DispatchObservers(SHOP_BUY_ACTICITY_DIAMOND_EVENT, {tag = tag})
    end)
    local purchasedDescr = ''

    local minX = math.min(self:getTodayPurchased(data), self:getTotalPurchased(data))
    local purchasedCount = math.max(minX, -1)
    if self:getTodayStock(data) == self:getTotalStock(data) then
        if purchasedCount ~= -1 then
            purchasedDescr = string.fmt(__('限购_num_次'), {_num_ = purchasedCount})    
        end
    else
        if purchasedCount ~= -1 then
            purchasedDescr = string.fmt(__('今日可购_num_次'), {_num_ = purchasedCount})
        end
    end
    viewData_.diamondImage:setTexture(RES_DICT.SHOP_BTN_DIAMONDS_AD_DEFAULT)
    viewData_.shopTextImage:setTexture(RES_DICT.SHOP_BG_TEXT_AD)
    display.commonLabelParams(viewData_.limitLabel, { text = purchasedDescr })
    local isSoldOut = self:getTodayPurchased(data) == 0 or self:getTotalPurchased(data) == 0
    if isSoldOut then
        if self:getTodayStock(data) == self:getTotalStock(data) then
            purchasedDescr = __('已售罄')
        else
            purchasedDescr = __('今日售罄')
        end
        display.commonLabelParams(viewData_.limitLabel, { text = purchasedDescr})
        viewData_.diamondImage:setTexture(RES_DICT.SHOP_BTN_DIAMONDS_AD_DEFAULT)
        viewData_.shopTextImage:setTexture(RES_DICT.SHOP_BG_TEXT_AD)
    end
    self:UpdateBaseInfo(data)
end
function DiamondStoreActivityCellView:UpdateBaseInfo(data)

    local diamondValue = data.num
    local viewData_ = self.viewData_
    local   cuurentPrice ,originalPrice
    if isElexSdk() then
        cuurentPrice ,originalPrice = CommonUtils.GetCurrentAndOriginPriceDByPriceData(data)
    else
        cuurentPrice = string.format(__("￥ %s" ) , tostring(tonumber(data.price)))
        originalPrice = string.format(__("￥ %s" ) , tostring(tonumber(data.originalPrice)))
    end
    display.commonLabelParams(viewData_.originalPrice, {reqW = 115 ,  text = originalPrice})
    display.commonLabelParams(viewData_.presentPrice, {reqW = 115 ,  text = cuurentPrice})
    local totalScoreNum = cc.Label:createWithBMFont('font/team_ico_fight_figure_2.fnt', '')
    display.commonLabelParams(totalScoreNum, {text = diamondValue })
    local diamondPath = CommonUtils.GetGoodsIconPathById(DIAMOND_ID)
    local cData = {}
    if isElexSdk() then
        cData[#cData+1] =  fontWithColor('14' , {fontSize = 22 ,   text = string.fmt(__('_num_折') , { _num_ = CommonUtils.GetDiscountOffFromCN(data.price /data.originalPrice )})})
    end
    cData[#cData+1] = {node = totalScoreNum  , scale = 0.4}
    cData[#cData+1] =  { img = diamondPath , scale = 0.2}
    display.reloadRichLabel(viewData_.buyDiamondLabel , {
        c = cData
    })
    CommonUtils.AddRichLabelTraceEffect(viewData_.buyDiamondLabel ,  nil ,nil ,{1})
    CommonUtils.SetNodeScale(viewData_.buyDiamondLabel  , {width = 180 })
end

return DiamondStoreActivityCellView
