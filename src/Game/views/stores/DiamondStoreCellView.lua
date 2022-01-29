--[[
 * author : kaishiqi
 * descpt : 新游戏商店 - 卡皮商店视图
]]
---@class DiamondStoreCellView
local DiamondStoreCellView   = class('DiamondStoreCellView', function()
    local DiamondStoreCellView = CGridViewCell:new()
    DiamondStoreCellView.name = 'Game.view.stores.DiamondStoreCellView'
    DiamondStoreCellView:enableNodeEvents()
    return DiamondStoreCellView
end)
local newImageView = display.newImageView
local newLabel = display.newLabel
local newNSprite = display.newNSprite
local newButton = display.newButton
local newLayer = display.newLayer
local RES_DICT = {
    SHOP_LINE_2                   = _res('ui/stores/diamond/shop_line_2.png'),
    SHOP_DIAMONDS_ICO_LIGHT       = _res('ui/stores/diamond/shop_diamonds_ico_light.png'),
    SHOP_BG_TEXT                  = _res('ui/stores/diamond/shop_bg_text.png'),
    SHOP_TAG_X2                   = _res('ui/stores/diamond/shop_tag_x2.png'),
    SHOP_BG_TEXT_AD               = _res('ui/stores/diamond/shop_bg_text_ad.png'),
    SHOP_TAG_DOUBLE               = _res('ui/stores/diamond/shop_tag_double.png'),
    SHOP_BG_MONEY_DIAMONDS        = _res('ui/stores/diamond/shop_bg_money_diamonds.png'),
    SHOP_BTN_DIAMONDS_AD_DEFAULT  = _res('ui/stores/diamond/shop_btn_diamonds_ad_default.png'),
    SHOP_FRAME_AD_UP              = _res('ui/stores/diamond/shop_frame_ad_up.png'),
    SHOP_ICO_TIME                 = _res('ui/stores/diamond/shop_ico_time.png'),
    SHOP_DIAMOND_BG_TIMELEFT      = _res('ui/stores/diamond/shop_diamond_bg_timeleft.png'),
    TEMP_AD_UP                    = _res('ui/stores/diamond/temp_ad_up.png'),
    SHOP_BTN_DIAMONDS_DEFAULT     = _res('ui/stores/diamond/shop_btn_diamonds_default.png'),
    SHOP_DIAMONDS_ICO_1           = _res('ui/stores/diamond/shop_diamonds_ico_1.png'),
}

function DiamondStoreCellView:ctor()
    self:InitView()
end

function DiamondStoreCellView:InitView()
    local cellSize = cc.size(523,189)
    self:setContentSize(cellSize)
    local cellLayout = newLayer(cellSize.width/2, cellSize.height/2,
                                { ap = display.CENTER, color = cc.c4b(0,0,0,0), size = cc.size(528, 187), enable = true })
    self:addChild(cellLayout)

    local bgImage = newImageView(RES_DICT.SHOP_BTN_DIAMONDS_DEFAULT, 263, 93,
                                 { ap = display.CENTER, tag = 56, enable = fals })
    cellLayout:addChild(bgImage)

    local iconLayout = newLayer(0, 0,
                                { ap = display.LEFT_BOTTOM, color = cc.r4b(0), size = cc.size(230, 186), enable = true })
    cellLayout:addChild(iconLayout)

    local lightImage = newImageView(RES_DICT.SHOP_DIAMONDS_ICO_LIGHT, 0, 0,
                                    { ap = display.LEFT_BOTTOM, tag = 72, enable = false })
    iconLayout:addChild(lightImage)

    local diamondIco = newImageView(RES_DICT.SHOP_DIAMONDS_ICO_1, 115, 93,
                                    { ap = display.CENTER, tag = 74, enable = false })
    iconLayout:addChild(diamondIco)

    local priceButton = newButton(396, 44, { ap = display.CENTER ,  n = RES_DICT.SHOP_BG_MONEY_DIAMONDS, d = RES_DICT.SHOP_BG_MONEY_DIAMONDS, s = RES_DICT.SHOP_BG_MONEY_DIAMONDS, scale9 = true, size = cc.size(268, 91), tag = 57 })
    cellLayout:addChild(priceButton)
    display.commonLabelParams(priceButton , fontWithColor(14, { fontSize = 30 ,outline = '#752d11',   text = "" , offset = cc.p(-20, 0 ) }))
    local doubleText = newButton(0, 156, { ap = display.LEFT_CENTER ,  n = RES_DICT.SHOP_TAG_DOUBLE, d = RES_DICT.SHOP_TAG_DOUBLE, s = RES_DICT.SHOP_TAG_DOUBLE, scale9 = true, size = cc.size(185,40 ), tag = 59 })
    display.commonLabelParams(doubleText, fontWithColor(14,{outline = "#5b248f", outlineSize = 2,  text = __('首充双倍！'),reqW = 160, fontSize = 22, color = '#ffffff',offset = cc.p(-10,0)  }))
    cellLayout:addChild(doubleText,20 )



    local giveLayout = newLayer(151, 80,
                                { ap = display.LEFT_BOTTOM, size = cc.size(342, 48) })
    cellLayout:addChild(giveLayout,2)

    local shopBgText = newImageView(RES_DICT.SHOP_LINE_2, 158, 5,
                                    { ap = display.CENTER, tag = 68, enable = false, scale9 = true, size = cc.size(323, 2) })
    giveLayout:addChild(shopBgText)
    local bgPriceLayoutSize = cc.size(342, 48)
    local giveTextLabel = newLabel(42, 21,
                                  { ap = display.LEFT_CENTER, color = '#963e39', text = __('额外赠送'), fontSize = 20, tag = 69 })
    giveLayout:addChild(giveTextLabel)
    local giveDiamondLabel = display.newRichLabel(bgPriceLayoutSize.width - 50 , bgPriceLayoutSize.height/2 , {
        ap = display.RIGHT_CENTER ,r = true, c = {
            fontWithColor('14', {text = 14})
        }
    })
    giveLayout:addChild(giveDiamondLabel)
    local giveDoubleTextImage = newNSprite(RES_DICT.SHOP_TAG_X2, 331, 32,
                                           { ap = display.CENTER, tag = 71 })
    giveDoubleTextImage:setScale(1, 1)
    giveLayout:addChild(giveDoubleTextImage)

    local bgPriceLayout = newLayer(151, 123,
                                   { ap = display.LEFT_BOTTOM, size = bgPriceLayoutSize })
    cellLayout:addChild(bgPriceLayout)

    local shopBgText_1 = newImageView(RES_DICT.SHOP_BG_TEXT, 171, 22,
                                      { ap = display.CENTER, tag = 62, enable = false, scale9 = true, size = cc.size(342, 48) })
    bgPriceLayout:addChild(shopBgText_1)

    local buyTextLabel = newLabel(39, 22,
                                    fontWithColor(14,{ ap = display.LEFT_CENTER, color = '#ffffff', text = __('购买'), fontSize = 22, outlineSize = 2 , outline = "#956a43" ,tag = 63 }))
    bgPriceLayout:addChild(buyTextLabel)

    local doubleTextImage = newNSprite(RES_DICT.SHOP_TAG_X2, 331, 32,
                                       { ap = display.CENTER, tag = 66 })
    doubleTextImage:setScale(1, 1)
    bgPriceLayout:addChild(doubleTextImage)

    local buyDiamondLabel = display.newRichLabel(bgPriceLayoutSize.width - 50 , bgPriceLayoutSize.height/2 , {
        ap = display.RIGHT_CENTER , r = true,  c = {
            fontWithColor('14', {text = 14}),
            { img = CommonUtils.GetGoodsIconPathById(DIAMOND_ID) , scale = 0.23}
        }
    })
    bgPriceLayout:addChild(buyDiamondLabel)
    self.viewData_ =  {
        cellLayout              = cellLayout,
        bgImage                 = bgImage,
        priceButton             = priceButton,
        doubleText              = doubleText,
        iconLayout              = iconLayout,
        lightImage              = lightImage,
        diamondIco              = diamondIco,
        giveLayout              = giveLayout,
        shopBgText              = shopBgText,
        buyTextLabel            = buyTextLabel,
        giveDoubleTextImage     = giveDoubleTextImage,
        bgPriceLayout           = bgPriceLayout,
        shopBgText_1            = shopBgText_1,
        buyDiamondLabel         = buyDiamondLabel,
        giveDiamondLabel        = giveDiamondLabel,
        giveTextLabel           = giveTextLabel,
        doubleTextImage         = doubleTextImage
    }
end
function DiamondStoreCellView:UpdateCell( data ,index  )
    local viewData_ = self.viewData_
    local extraNum = checkint(data.extraNum)
    local countNum = checkint(data.num )
    local price = tonumber(data.price)
    local shouldNum = countNum - extraNum
    viewData_.doubleText:setVisible(false)
    viewData_.giveLayout:setVisible(false)
    viewData_.doubleTextImage:setVisible(false)
    viewData_.giveDoubleTextImage:setVisible(false)
    if checkint(data.isFirst) == 1 then
        viewData_.doubleText:setVisible(true)
        viewData_.doubleTextImage:setVisible(true)
        viewData_.giveDoubleTextImage:setVisible(true)
    end
    if extraNum > 0 then
        viewData_.giveLayout:setVisible(true)
        local totalScoreNumOne = cc.Label:createWithBMFont('font/shop_ico_special_num.fnt', '')
        totalScoreNumOne:setString(checkint(extraNum))
        --display.commonLabelParams(, {text = extraNum })
        local diamondPath = CommonUtils.GetGoodsIconPathById(DIAMOND_ID)
        display.reloadRichLabel(viewData_.giveDiamondLabel , {
            c= {
                {node = totalScoreNumOne  , scale = 0.5} ,
                { img = diamondPath , scale = 0.2}
            }
        })
    end
    local totalScoreNum = cc.Label:createWithBMFont('font/team_ico_fight_figure_2.fnt', '')
    display.commonLabelParams(totalScoreNum, {text = shouldNum })
    local diamondPath = CommonUtils.GetGoodsIconPathById(DIAMOND_ID)
    display.reloadRichLabel(viewData_.buyDiamondLabel , {
        c= {
            {node = totalScoreNum  , scale = 0.57} ,
            { img = diamondPath , scale = 0.23}
        }
    })
    viewData_.cellLayout:setTag(index)
    viewData_.cellLayout:setOnClickScriptHandler(function(sender)
        local tag = sender:getTag()
        app:DispatchObservers(SHOP_BUY_DIAMOND_EVENT ,{tag =  tag})
    end)
    local  diamondPath =  _res(string.format('ui/stores/diamond/shop_diamonds_ico_%d.png' , checkint(index)) )
    if utils.isExistent(diamondPath) then
        viewData_.diamondIco:setTexture(diamondPath)
    end

    if isElexSdk() then
        price =  CommonUtils.GetCurrentAndOriginPriceDByPriceData(data)
    else
        price =  string.format(__("￥%s") ,price )
    end
    display.commonLabelParams(viewData_.priceButton , fontWithColor(14, {outlineSize = 2 , fontSize = 30 ,outline = '#752d11', text = price}))
end
return DiamondStoreCellView
