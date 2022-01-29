--[[
    抽卡主题商店 view
--]]
local VIEW_SIZE = cc.size(838, 570)
local CapsuleMallThemeView = class('CapsuleMallThemeView', function ()
    local node = CLayout:create(VIEW_SIZE)
    node.name = 'drawCards.CapsuleMallThemeView'
    node:enableNodeEvents()
    return node
end)

local gameMgr = app.gameMgr

local RES_DICT = {
    COMMON_BTN_ORANGE               = _res('ui/common/common_btn_orange.png'),
    COMMON_BTN_SWITCH_L             = _res('ui/common/common_btn_switch_l.png'),
    SUMMNON_SHOP_BG_AVATAR_BG_TEXT  = _res('ui/home/capsuleNew/skinCapsule/shop/summnon_shop_bg_avatar_bg_text.png'),
    SUMMON_SHOP_BTN_DETAIL          = _res('ui/home/capsuleNew/skinCapsule/shop/summon_shop_btn_detail.png'),
    SUMMON_SHOP_BG_HAVED            = _res('ui/home/capsuleNew/skinCapsule/shop/summon_shop_bg_haved.png'),
    CONSUNE_IMG                     = _res('ui/common/common_ico_exp.png'),
}

local BUTTON_TAG = {
    PARTS_PREVIEW  = 100,
    NEXT           = 101,
    PRE            = 102,
    BUY            = 103,
}

local AVATAR_THEME_RESTAURANT_CONF = CommonUtils.GetConfigAllMess('avatarTheme', 'restaurant') or {}
local CreateView = nil

function CapsuleMallThemeView:ctor( ... )
	local args = unpack({...}) or {}
    self.size = args.size
    self:InitUI()
end
 
function CapsuleMallThemeView:InitUI()
    xTry(function ( )
        self.viewData = CreateView(VIEW_SIZE)
        display.commonUIParams(self.viewData.view, {ap = display.CENTER, po = utils.getLocalCenter(self)})
        self:addChild(self.viewData.view, 1)
	end, __G__TRACKBACK__)
end

function CapsuleMallThemeView:RefreshUI(data, curIndex, maxIndex)
    local viewData = self:getViewData()
    self:UpdateSwiBtnShowState(viewData, curIndex, maxIndex)

    local themeId = data.goodsId
    self:UpdateThemeContent(viewData, themeId)

    self:UpdateGoodOwnState(viewData, data)
    
    self:UpdateImageView(viewData, themeId)
end

function CapsuleMallThemeView:UpdateSwiBtnShowState(viewData, curIndex, maxIndex)
    local viewData = self:getViewData()
    local actionBtns = viewData.actionBtns
    actionBtns[tostring(BUTTON_TAG.PRE)]:setVisible(checkint(curIndex) > 1)
    actionBtns[tostring(BUTTON_TAG.NEXT)]:setVisible(checkint(curIndex) < checkint(maxIndex))
end

function CapsuleMallThemeView:UpdateThemeContent(viewData, themeId)
    local themeConf = AVATAR_THEME_RESTAURANT_CONF[tostring(themeId)] or {}

    display.commonLabelParams(viewData.themeTitleLabel, {text = themeConf.name})
    display.commonLabelParams(viewData.themeDescrLabel, {text = themeConf.descr})
end

function CapsuleMallThemeView:UpdateGoodOwnState(viewData, data)
    local goodsId = data.goodsId

    local leftPurchaseNum = checkint(data.leftPurchaseNum)
    local isBuy = checkint(data.leftPurchaseNum) <= 0 and checkint(data.leftPurchaseNum) ~= -1
    local isOwn = isBuy or app.restaurantMgr:IsHaveTheme(goodsId)
    viewData.buyLayer:setVisible(not isOwn)
    viewData.ownTip:setVisible(isOwn)
    if not isOwn then
        self:UpdateGoodConsume(viewData, data)
    end
end

function CapsuleMallThemeView:UpdateGoodConsume(viewData, data)
    local buyLayerSize = viewData.buyLayerSize

    local consumeNum = viewData.consumeNum
    local price = checknumber(data.price)
    
    display.commonLabelParams(consumeNum, {text = price})

    local consumeImg = viewData.consumeImg
    consumeImg:setTexture(CommonUtils.GetGoodsIconPathById(data.currency))

    local consumeNumSize = display.getLabelContentSize(consumeNum)
    local consumeImgSize = consumeImg:getContentSize()

    consumeNum:setPositionX(buyLayerSize.width / 2 - consumeImgSize.width / 2 * consumeImg:getScale())
    consumeImg:setPositionX(buyLayerSize.width / 2 + consumeNumSize.width / 2)

end

function CapsuleMallThemeView:UpdateImageView(viewData, themeId)
    viewData.themeImg:setTexture(CommonUtils.GetGoodsIconPathById(themeId, true))
end

CreateView = function (size)
    local view = display.newLayer(0, 0, {size = size})

    local actionBtns = {}

    local themeImg = display.newNSprite('', 421, 285,
    {
        ap = display.CENTER,
    })
    themeImg:setScale(0.9975, 0.93)
    view:addChild(themeImg)

    -- local preImageView = display.newImageView(RES_DICT.THEME_PIC_270018, 421, 285, {ap = display.CENTER})
    -- preImageView:setScale(0.9975, 0.93)
    -- view:addChild(preImageView)

    -- local nextImageView = display.newImageView(RES_DICT.THEME_PIC_270018, 421, 285, {ap = display.CENTER})
    -- nextImageView:setScale(0.9975, 0.93)
    -- view:addChild(nextImageView)

    local partsPreviewBtn = display.newButton(794, 537,
    {
        ap = display.CENTER,
        n = RES_DICT.SUMMON_SHOP_BTN_DETAIL,
        scale9 = true, size = cc.size(52, 56),
        enable = true,
    })
    actionBtns[tostring(BUTTON_TAG.PARTS_PREVIEW)] = partsPreviewBtn
    view:addChild(partsPreviewBtn)

    local nextBtn = display.newButton(847, 305,
    {
        ap = display.RIGHT_CENTER,
        n = RES_DICT.COMMON_BTN_SWITCH_L,
    })
    actionBtns[tostring(BUTTON_TAG.NEXT)] = nextBtn
    view:addChild(nextBtn)
    -- nextBtn:setVisible(false)

    local preBtn = display.newButton(80, 297,
    {
        ap = display.LEFT_CENTER,
        n = RES_DICT.COMMON_BTN_SWITCH_L,
    })
    actionBtns[tostring(BUTTON_TAG.PRE)] = preBtn
    preBtn:setScaleX(-1)
    view:addChild(preBtn)
    -- preBtn:setVisible(false)

    --------------avatarDescrLayer start--------------
    local avatarDescrLayerSize = cc.size(803, 162)
    local avatarDescrLayer = display.newLayer(421, 5,
    {
        ap = display.CENTER_BOTTOM,
        size = cc.size(803, 162),
        enable = true,
    })
    view:addChild(avatarDescrLayer)

    local summnon_shop_bg_avatar_bg_text_8 = display.newNSprite(RES_DICT.SUMMNON_SHOP_BG_AVATAR_BG_TEXT, 402, 0,
    {
        ap = display.CENTER_BOTTOM,
    })
    avatarDescrLayer:addChild(summnon_shop_bg_avatar_bg_text_8)

    local themeTitleLabel = display.newLabel(11, 121,
    {
        ap = display.LEFT_CENTER,
        fontSize = 24,
        color = '#ffffff',
        font = TTF_GAME_FONT, ttf = true,
    })
    avatarDescrLayer:addChild(themeTitleLabel)

    local themeDescrLabel = display.newLabel(11, 104,
    {
        ap = display.LEFT_TOP,
        fontSize = 22,
        color = '#ffffff',
        w = 612
    })
    avatarDescrLayer:addChild(themeDescrLabel)

    local buyLayerSize = cc.size(123, avatarDescrLayerSize.height)
    local buyLayer = display.newLayer(710, 0, {ap = display.CENTER_BOTTOM, size = buyLayerSize})
    avatarDescrLayer:addChild(buyLayer)

    local buyBtn = display.newButton(buyLayerSize.width / 2, 75,
    {
        ap = display.CENTER,
        n = RES_DICT.COMMON_BTN_ORANGE,
        scale9 = true, size = cc.size(123, 62),
        enable = true,
    })
    actionBtns[tostring(BUTTON_TAG.BUY)] = buyBtn
    display.commonLabelParams(buyBtn, fontWithColor(14, {text = __('兑换'), reqW = 100}))
    buyLayer:addChild(buyBtn)

    local consumeNum = display.newLabel(buyLayerSize.width / 2, 32,
        fontWithColor(7, {ap = display.CENTER, fontSize = 22}))
    buyLayer:addChild(consumeNum)

    local consumeImg = display.newSprite(RES_DICT.CONSUNE_IMG, buyLayerSize.width / 2, 32, {ap = display.CENTER})
    consumeImg:setScale(0.18)
    buyLayer:addChild(consumeImg)

    local ownTip = display.newButton(710, 50, {ap = display.CENTER, enable = false, n = RES_DICT.SUMMON_SHOP_BG_HAVED})
    display.commonLabelParams(ownTip, fontWithColor(14, {text = __('已获得'), reqW = 120}))
    avatarDescrLayer:addChild(ownTip)

    return {
        view            = view,
        themeImg        = themeImg,
        -- preImageView    = preImageView,
        -- nextImageView   = nextImageView,
        actionBtns      = actionBtns,
        themeTitleLabel = themeTitleLabel,
        themeDescrLabel = themeDescrLabel,
        buyLayer        = buyLayer,
        consumeNum      = consumeNum,
        consumeImg      = consumeImg,
        ownTip          = ownTip,

        buyLayerSize    = buyLayerSize,
    }
end

function CapsuleMallThemeView:getViewData()
    return self.viewData
end

return CapsuleMallThemeView
