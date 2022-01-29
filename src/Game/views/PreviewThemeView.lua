---
--- Created by xingweihao.
--- DateTime: 16/10/2017 5:39 PM
---
--[[
限时超得活动view
--]]
---@class PreviewThemeView
local PreviewThemeView = class('PreviewThemeView', function()
    local node = CLayout:create(display.size)
    node.name  = 'home.PreviewThemeView'
    node:enableNodeEvents()
    return node
end)
local RES_DIR = {
    ICON_HEART                                                 = _res('ui/common/common_hint_circle_red_ico.png'),
    BTN_WHITR                                                  = _res('ui/common/common_btn_white_default.png'),
    DISCOUNT_LINE                                              = _res('ui/home/commonShop/shop_sale_line.png'),
    AVATAR_SHOP_GOOD_THEME_BUY_PREVIEW_BG                      = _res('ui/common/commcon_bg_text1.png'),
    AVATAR_SHOP_GOOD_THEME_BUY_PREVIEW_NAME                    = _res('avatar/ui/avatarShop/theme_preview_bg_name.png'),
    AVATAR_SHOP_GOOD_THEME_BUY_PREVIEW_TITLE                   = _res('ui/common/common_title_3.png'),
    AVATAR_SHOP_GOOD_THEME_BUY_PREVIEW_RIGHT_BG                = _res('avatar/ui/avatarShop/theme_preview_bg.png'),
    AVATAR_SHOP_GOOD_THEME_BUY_PREVIEW_RIGHT_DES_BG            = _res('avatar/ui/avatarShop/theme_preview_bg_detail.png'),
    AVATAR_SHOP_GOOD_THEME_BUY_PREVIEW_RIGHT_PRESENT_PRICE_BG  = _res('avatar/ui/avatarShop/shop_package_putong_bg.png'),
    AVATAR_SHOP_GOOD_THEME_BUY_PREVIEW_RIGHT_DISCOUNT_PRICE_BG = _res('avatar/ui/avatarShop/shop_package_putong_bg_2.png'),
    AVATAR_SHOP_BTN_ORANGE                                     = _res('ui/common/common_btn_orange.png')
}
local avatarThemeRestaurantConf = CommonUtils.GetConfigAllMess('avatarTheme', 'restaurant')
local function CreateView( )
    local layer = display.newLayer(0, 0, {size = display.size, ap = display.CENTER})
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
    local rightBg = display.newImageView(RES_DIR.AVATAR_SHOP_GOOD_THEME_BUY_PREVIEW_RIGHT_BG, 0, 0, {ap = display.LEFT_BOTTOM})
    local rightBgSize = rightBg:getContentSize()
    local rightBgLayer = display.newLayer(bgSize.width, 0, {size = rightBgSize, ap = display.RIGHT_BOTTOM})
    rightBgLayer:addChild(rightBg)
    bgLayer:addChild(rightBgLayer)

    local titleBg = display.newImageView(RES_DIR.AVATAR_SHOP_GOOD_THEME_BUY_PREVIEW_TITLE, rightBgSize.width * 0.5, rightBgSize.height * 0.99, {ap = display.CENTER_TOP})
    rightBgLayer:addChild(titleBg)

    local titleLabel = display.newLabel(0, 0, fontWithColor(4, {text = __('主题明细'), ap = display.CENTER}))
    display.commonUIParams(titleLabel, {po =  utils.getLocalCenter(titleBg)})
    titleBg:addChild(titleLabel)

    local themeDescListBgSize = cc.size(256, 450)
    local themeDescListBg = display.newImageView(RES_DIR.AVATAR_SHOP_GOOD_THEME_BUY_PREVIEW_RIGHT_DES_BG, 0, 0, {size = themeDescListBgSize, scale9 = true, ap = display.LEFT_BOTTOM})
    local themeDescListBgLayer = display.newLayer(rightBgSize.width / 2, rightBgSize.height * 0.92, {size = themeDescListBgSize, ap = display.CENTER_TOP})
    rightBgLayer:addChild(themeDescListBgLayer)
    themeDescListBgLayer:addChild(themeDescListBg)

    local themeDescListLabel = display.newLabel(themeDescListBgSize.width/2 ,themeDescListBgSize.height - 20  ,fontWithColor('6' , { ap = display.CENTER_TOP,hAlign = cc.TEXT_ALIGNMENT_LEFT , w = 220 , text ="" } ) )
    themeDescListBg:addChild(themeDescListLabel)
    local makeSureBtn = display.newButton(rightBgSize.width / 2, rightBgSize.height * 0.01, {ap = display.CENTER_BOTTOM, n = RES_DIR.AVATAR_SHOP_BTN_ORANGE })
    display.commonLabelParams(makeSureBtn, fontWithColor(14, {text = __('确定')}))
    rightBgLayer:addChild(makeSureBtn)

    return {
        layer                = layer,
        makeSureBtn               = makeSureBtn,
        themeImg             = themeImg,
        titleLabel = titleLabel ,
        themeDescListLabel= themeDescListLabel
    }
end

function PreviewThemeView:ctor( param)
    param = param or {}
    self.goodsId = param.goodsId or "270004"
    local closeLayer = display.newLayer(display.cx , display.cy , { ap = display.CENTER , size = display.size , color = cc.c4b(0,0,0,100) , enable = true , cb = function ()
        self:CloseView()
    end})
    self:addChild(closeLayer)

    self.viewData_ = CreateView()
    self:addChild(self.viewData_.layer, 1)
    self.viewData_.layer:setPosition(utils.getLocalCenter(self))
    self:UpdateView()

end

function PreviewThemeView:UpdateView()
    local data = avatarThemeRestaurantConf[tostring( self.goodsId )] or  {}
    local iconPath = CommonUtils.GetGoodsIconPathById(self.goodsId, true)
    local descr = data.descr or ""
    local name  = data.name or ""
    self.viewData_.themeImg:setTexture(iconPath)
    self.viewData_.titleLabel:setString(name)
    self.viewData_.themeDescListLabel:setString(descr)
    self.viewData_.makeSureBtn:setOnClickScriptHandler(handler(self , self.CloseView))
end
function PreviewThemeView:CloseView()
    if self and (not tolua.isnull(self)) then
        self:runAction(cc.RemoveSelf:create())
    end
end
return PreviewThemeView