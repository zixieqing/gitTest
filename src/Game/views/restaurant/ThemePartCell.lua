local ThemePartCell = class('ThemePartCell', function ()
    local node = CLayout:new()
    node.name = 'Game.views.restaurant.ThemePartCell'
	node:enableNodeEvents()
    return node
end)

local RES_DICT = {
    AVATOR_GOODS_BG_L_SELECTED  = _res('avatar/ui/avatarShop/avator_goods_bg_l_selected.png'),
    SHOP_BTN_GOODS_DEFAULT      = _res('ui/home/commonShop/shop_btn_goods_default.png'),
    SHOP_BTN_GOODS_SELLOUT      = _res('ui/home/commonShop/shop_btn_goods_sellout.png'),
    COMMON_ICO_LOCK             = _res('ui/common/common_ico_lock.png'),
    SHOP_ICO_DYNAMIC             = _res('ui/common/shop_ico_dynamic.png'),
    
    CARD_PREVIEW_ICO_NEW_2      = _res('ui/card_preview_ico_new_2'),
    -- shop_ico_dynamic
}

local CreateView = nil

function ThemePartCell:ctor( ... )
    local arg = {...}
    local size = arg[1] or cc.size(200 , 300)
	self:setContentSize(size)

    self:InitUI(size)
end

function ThemePartCell:InitUI(size)
    local view = display.newLayer(0, 0, {size = size})
    display.commonUIParams(view, {ap = display.CENTER, po = utils.getLocalCenter(self)})
    self:addChild(view)
    self.view = view

    local centerPosX = size.width / 2
    local centerPosY = size.height / 2
    self.centerPosX  = centerPosX
    self.centerPosY  = centerPosY

    local touchView = display.newLayer(centerPosX, centerPosY, {size = cc.size(199, 245), ap = display.CENTER, enable = true, color = cc.c4b(0,0,0,0)})
    view:addChild(touchView, 1)
    self.touchView = touchView

    -- bg
    local bg = display.newNSprite(RES_DICT.SHOP_BTN_GOODS_DEFAULT, centerPosX, centerPosY, {ap  = display.CENTER}) --display.newButton(centerPosX, centerPosY, {n = RES_DICT.SHOP_BTN_GOODS_DEFAULT, ap  = display.CENTER})
    local bgSize = bg:getContentSize()
    view:addChild(bg)
    self.bg = bg

    local goodFrame = display.newImageView(RES_DICT.AVATOR_GOODS_BG_L_SELECTED, centerPosX, centerPosY, {scale9 = true, size = cc.size(bgSize.width * 1.025, bgSize.height * 1.025), ap = display.CENTER})
    goodFrame:setVisible(false)
    view:addChild(goodFrame, 1)
    self.goodFrame = goodFrame

    -- own good num
    local ownNumLabel = display.newLabel(centerPosX, size.height - 20, fontWithColor(16, {ap = display.CENTER_TOP}))
    ownNumLabel:setVisible(false)
    view:addChild(ownNumLabel, 1)
    self.ownNumLabel = ownNumLabel

    local goodsImg = AssetsUtils.GetRestaurantSmallAvatarNode(101034, centerPosX, centerPosY + 20, {ap = display.CENTER})
    goodsImg:setVisible(false)
    view:addChild(goodsImg)
    self.goodsImg = goodsImg

    -- local goodsImg = RestaurantUtils.CreateDragNode(101034)
    -- goodsImg:setPosition(centerPosX, centerPosY + 20)
    -- goodsImg:setAnchorPoint(display.CENTER)

    -- -- local goodsImg = RestaurantUtils.CreateDragNode(101034)
    -- view:addChild(goodsImg)
    -- goodsImg:setVisible(false)

    -- good name
    local goodsName = display.newLabel(centerPosX, 55, {fontSize = 24, color = '#6b5959', ap = display.CENTER_BOTTOM})
    view:addChild(goodsName)
    self.goodsName = goodsName
    
    local priceLayerSize = cc.size(bgSize.width, 40)
    local priceLayer = display.newLayer(bgSize.width / 2, 0, {ap = display.CENTER_BOTTOM, size = priceLayerSize})
    bg:addChild(priceLayer)
    self.priceLayer = priceLayer
    priceLayer:setVisible(false)

    -- good price
    local priceNum = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '0')--
    local priceNumSize = priceNum:getContentSize()
    priceNum:setHorizontalAlignment(display.TAR)
    display.commonUIParams(priceNum, {po = cc.p(centerPosX, priceLayerSize.height / 2), ap = display.CENTER})
    priceLayer:addChild(priceNum)
    -- priceNum:setVisible(false)
    self.priceNum = priceNum
    
    -- cast icon
    local castIcon = display.newNSprite('', centerPosX, priceNum:getPositionY())
    local castIconSize = castIcon:getContentSize()
    castIcon:setScale(0.2)
    castIcon:setAnchorPoint(display.CENTER)
    priceLayer:addChild(castIcon)
    -- castIcon:setVisible(false)
    self.castIcon = castIcon
    
    -- lock icon
    local lockIcon = display.newImageView(RES_DICT.COMMON_ICO_LOCK, centerPosX, 32)
    lockIcon:setVisible(false)
    view:addChild(lockIcon)
    self.lockIcon = lockIcon

    local alreadyOwnedLabel = display.newLabel(size.width / 2, 27, fontWithColor(14,{text = __('已拥有'),color = '#ffcb2b',outline = '#361e11',outlineSize = 1}))
    view:addChild(alreadyOwnedLabel)
    alreadyOwnedLabel:setVisible(false)
    self.alreadyOwnedLabel = alreadyOwnedLabel

    local newIcon = display.newImageView(RES_DICT.CARD_PREVIEW_ICO_NEW_2, size.width - 20, size.height - 20, {ap = display.CENTER})
    newIcon:setVisible(false)
    view:addChild(newIcon)
    self.newIcon = newIcon

    local dynamicAvatarTipIcon = display.newImageView(RES_DICT.SHOP_ICO_DYNAMIC, 30, size.height - 30, {ap = display.CENTER})
    dynamicAvatarTipIcon:setVisible(false)
    view:addChild(dynamicAvatarTipIcon)
    self.dynamicAvatarTipIcon = dynamicAvatarTipIcon
    -- 
end

return ThemePartCell