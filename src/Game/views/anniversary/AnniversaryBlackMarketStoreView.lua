---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by xingweihao.
--- DateTime: 2018/10/12 3:27 PM
---
---@class AnniversaryBlackMarketStoreView
local AnniversaryBlackMarketStoreView = class('AnniversaryBlackMarketStoreView', function ()
    local node = CLayout:create(display.size)
    node.name = 'Game.views.artifact.AnniversaryBlackMarketStoreView'
    node:setName('AnniversaryBlackMarketStoreView')
    node:enableNodeEvents()
    return node
end)
local newImageView = display.newImageView
local newLabel = display.newLabel
local newNSprite = display.newNSprite
local newLayer = display.newLayer
local GoodPurchaseNode = require('common.GoodPurchaseNode')
local RES_DICT = {
    COMMON_BTN_TIPS                 = app.anniversaryMgr:GetResPath('ui/common/common_btn_tips.png'),
    ANNI_MAPS_SHOP_1_DESK           = app.anniversaryMgr:GetResPath('ui/anniversary/map/anni_maps_shop_1_desk.png'),
    COMMON_BTN_BACK                 = app.anniversaryMgr:GetResPath('ui/common/common_btn_back.png'),
    MATERIAL_CARD_LABEL_RELEASETIME = app.anniversaryMgr:GetResPath('ui/home/materialScript/material_card_label_releasetime.png'),
    ANNI_MAPS_SHOP_1_NPC            = app.anniversaryMgr:GetResPath('ui/anniversary/map/anni_maps_shop_1_npc.png'),
    SHOP_BTN_GOODS_DEFAULT          = app.anniversaryMgr:GetResPath('ui/home/commonShop/shop_btn_goods_default.png'),
    COMMON_TITLE                    = app.anniversaryMgr:GetResPath('ui/common/common_title.png'),
    MAIN_BG_MONEY                   = app.anniversaryMgr:GetResPath('ui/home/nmain/main_bg_money.png'),
}
function AnniversaryBlackMarketStoreView:ctor( ... )
    local view = newLayer(display.cx, display.cy,{ap = display.CENTER, size = display.size})
    view:setPosition(display.center)
    self:addChild(view)
    local swallowLayer = newLayer(667, 1334,
                                  { ap = display.CENTER, color = cc.c4b(0 ,0,0,175), size = cc.size(display.width, display.height), enable = true })
    swallowLayer:setPosition(display.cx + 0, display.cy )
    view:addChild(swallowLayer)

    local contentLayer = newLayer(667, 0,
                                  { ap = display.CENTER_BOTTOM, size = cc.size(1100, 600) })
    view:addChild(contentLayer)
    contentLayer:setPosition(display.cx , 0 )
    local peopleImage = newNSprite(RES_DICT.ANNI_MAPS_SHOP_1_NPC, 417, 376,
                                   { ap = display.CENTER, tag = 160 })
    peopleImage:setScale(1, 1)
    contentLayer:addChild(peopleImage)

    local deskImage = newImageView(RES_DICT.ANNI_MAPS_SHOP_1_DESK, 541, 121,
                                   { ap = display.CENTER, tag = 155, enable = false })
    contentLayer:addChild(deskImage)



    local titleImage = newNSprite(RES_DICT.MATERIAL_CARD_LABEL_RELEASETIME, 550, 56,
                                  { ap = display.CENTER, tag = 158 })
    titleImage:setScale(1, 1)
    contentLayer:addChild(titleImage)

    local requirementLabel = newLabel(550, 55,
                                      { ap = display.CENTER, color = '#ffffff', text = app.anniversaryMgr:GetPoText(__('????????????????????????')), fontSize = 22, tag = 159 })
    contentLayer:addChild(requirementLabel)

    local backBtn = display.newButton( 58, 697,
{ ap = display.CENTER, tag = 161 , n = RES_DICT.COMMON_BTN_BACK, s = RES_DICT.COMMON_BTN_BACK  })
    backBtn:setScale(1, 1)
    backBtn:setPosition(display.SAFE_L + 58, display.height + -55)
    view:addChild(backBtn)

    local tabNameLabel = display.newButton(97, 744, { ap = display.LEFT_TOP ,  n = RES_DICT.COMMON_TITLE, d = RES_DICT.COMMON_TITLE, s = RES_DICT.COMMON_TITLE, scale9 = true, size = cc.size(303, 78) })
    display.commonLabelParams(tabNameLabel, {text = "", fontSize = 14, color = '#414146'})
    tabNameLabel:setPosition(display.cx + -570, display.height + -6)
    view:addChild(tabNameLabel ,101)

    local moduleName = display.newLabel(138, 30,
                                        fontWithColor('14' , { outline = false ,  ap = display.CENTER, color = '#5b3c25', text = app.anniversaryMgr:GetPoText(__('????????????')), fontSize = 30, tag = 71 }))
    tabNameLabel:addChild(moduleName)

    local tipButton = display.newNSprite(RES_DICT.COMMON_BTN_TIPS, 237, 30,
                                         { ap = display.CENTER, tag = 72 })
    tipButton:setScale(1, 1)
    tabNameLabel:addChild(tipButton)
    local buyLayouts = {}
    local posXtable = { 250, 550, 850 }
    for i = 1 ,  3 do
        local node = self:CreateBuyLayout()
        contentLayer:addChild(node)
        node:setPosition(posXtable[i] , 220 )
        buyLayouts[#buyLayouts+1] = node
    end
    local topLayoutSize = cc.size(display.width, 80)
    local moneyNodeLayout = CLayout:create(topLayoutSize)
    moneyNodeLayout:setName('TOP_LAYOUT')
    display.commonUIParams(moneyNodeLayout, {ap = display.CENTER_TOP, po = cc.p(display.cx, display.height)})
    self:addChild(moneyNodeLayout, GameSceneTag.Dialog_GameSceneTag)

    -- top icon
    local imageImage = display.newImageView(RES_DICT.MAIN_BG_MONEY,0, 0, {enable = false,
                                                                                           scale9 = true, size = cc.size(680 + (display.width - display.SAFE_R), 54)})
    display.commonUIParams(imageImage,{ap = cc.p(1.0,1.0), po = cc.p(display.width,80)})
    moneyNodeLayout:addChild(imageImage)

    local moneyNods = {}
    local iconData = {app.anniversaryMgr:GetIncomeCurrencyID(), app.anniversaryMgr:GetAnniversaryTicketID(),DIAMOND_ID}
    for i,v in ipairs(iconData) do
        local purchaseNode = GoodPurchaseNode.new({id = v})
        purchaseNode:updataUi(checkint(v))
        display.commonUIParams(purchaseNode,
                               {ap = cc.p(1, 0.5), po = cc.p(topLayoutSize.width - 30 - (( 3 - i) * (purchaseNode:getContentSize().width + 16)), imageImage:getPositionY()- 26)})
        moneyNodeLayout:addChild(purchaseNode, 5)
        purchaseNode:setName('purchaseNode' .. i)
        purchaseNode.viewData.touchBg:setTag(checkint(v))
        moneyNods[tostring( v )] = purchaseNode
    end
    self.viewData =  {
        swallowLayer            = swallowLayer,
        contentLayer            = contentLayer,
        peopleImage             = peopleImage,
        deskImage               = deskImage,
        titleImage              = titleImage,
        requirementLabel        = requirementLabel,
        backBtn                 = backBtn,
        tabNameLabel            = tabNameLabel ,
        moneyNods               = moneyNods ,
        buyLayouts              = buyLayouts ,
    }
end
function AnniversaryBlackMarketStoreView:CreateBuyLayout()
    local shopLayout = newLayer(0, 0,
                                { ap = display.CENTER , size = cc.size(199, 248)  })

    local bgImage = newImageView(RES_DICT.SHOP_BTN_GOODS_DEFAULT, 99, 124,
                               { ap = display.CENTER, tag = 156  , enable = true })
    bgImage:setScale(1, 1)
    bgImage:setName("bgImage")
    shopLayout:addChild(bgImage)

    local goodNode = require('common.GoodNode').new({goodsId = DIAMOND_ID ,showName = true ,showAmount = true   })
    shopLayout:addChild(goodNode)
    display.commonLabelParams(goodNode.nameLabel , {w = 165 , hAlign = display.TAC })
    goodNode:setPosition(199/2 ,248 -70 )
    goodNode:setName("goodNode")
    local amoutRichLabel = display.newRichLabel(199/2 ,10 , { r= true ,  c = {
        fontWithColor('14' , {text = 200 }),
        {img = CommonUtils.GetGoodsIconPathById(DIAMOND_ID) , scale = 0.2 }
    }} )
    shopLayout:addChild(amoutRichLabel)
    amoutRichLabel:setName("amoutRichLabel")

    if isElexSdk() or isKoreanSdk() or isJapanSdk() then
        amoutRichLabel:setPositionY(8)
    end
    return shopLayout
end
--[[
    ???????????????UI
--]]
function AnniversaryBlackMarketStoreView:UpdateCountUI()
    if self.viewData and  self.viewData.moneyNods then
        for k ,v in pairs(self.viewData.moneyNods or {})do
            v:updataUi(checkint(k))
        end
    end
end
return AnniversaryBlackMarketStoreView
