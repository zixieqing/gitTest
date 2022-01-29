---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by pengjixian.
--- DateTime: 2018/9/30 3:55 PM
---
local uiMgr = app.uiMgr
local SaiMoeShopItemCell = class('Game.views.saimoe.SaiMoeShopItemCell',function ()
    local pageviewcell = CLayout:new()
    pageviewcell.name = 'Game.views.saimoe.SaiMoeShopItemCell'
    pageviewcell:enableNodeEvents()
    return pageviewcell
end)

function SaiMoeShopItemCell:ctor(arg)
    local size = cc.size(200 , 278)
    self:setContentSize(size)

    local eventNode = CLayout:create(cc.size(200 , 278))
    eventNode:setPosition(utils.getLocalCenter(self))
    self:addChild(eventNode)
    self.eventnode = eventNode

    local toggleView = display.newButton(size.width * 0.5,size.height * 0.5,{--
        n = _res('ui/home/commonShop/shop_btn_goods_default.png'),
        scale9 = true, size = cc.size(199, 278)
    })
    self.toggleView = toggleView
    self.eventnode:addChild(self.toggleView)

    local goodNode = require('common.GoodNode').new({id = arg.rewards[1].goodsId, amount = arg.rewards[1].num, showAmount = true,showName = true})
    goodNode:setAnchorPoint(cc.p(0.5,0))
    -- goodNode:setScale(0.8)
    goodNode:setPosition(cc.p(size.width * 0.5,104))
    self.eventnode:addChild(goodNode)
    self.goodNode = goodNode

    local sellLabel = display.newLabel(size.width / 2, 64  ,
            fontWithColor(14,{color = 'ffffff',text = __('已购买'),fontSize = 22, outline = '118e00', outlineSize = 2}))
    self.eventnode:addChild(sellLabel)
    sellLabel:setVisible(false)
    self.sellLabel = sellLabel

    -- 有折扣
    if checkint(arg.originalPrice) < checkint(arg.consume[1].num) then
        local fight_num = cc.Label:createWithBMFont('font/small/common_text_num.fnt', arg.consume[1].num)--
        fight_num:setAnchorPoint(cc.p(1, 0))
        fight_num:setHorizontalAlignment(display.TAR)
        fight_num:setPosition(cc.p(size.width * 0.5 + 56,6))
        self.eventnode:addChild(fight_num,1)
        self.numLabel = fight_num


        local castIcon = display.newNSprite(_res(CommonUtils.GetGoodsIconPathById(arg.consume[1].goodsId)), fight_num:getPositionX()+ 4, 6)
        castIcon:setScale(0.2)
        castIcon:setAnchorPoint(cc.p(0,0))
        self.eventnode:addChild(castIcon, 5)
        self.castIcon = castIcon

        local discountBg = display.newNSprite(_res('ui/home/commonShop/shop_tag_iconid_2'), 198, size.height - 20)
        discountBg:setAnchorPoint(cc.p(1,1))
        self.eventnode:addChild(discountBg, 5)
        self.discountBg = discountBg
        local discountNum = display.newLabel(utils.getLocalCenter(discountBg).x, utils.getLocalCenter(discountBg).y, fontWithColor(14, {text = __('折扣'), ap = cc.p(0.5, 0.5)}))
        discountBg:addChild(discountNum)
        self.discountNum = discountNum


        local discountLine = display.newImageView(_res('ui/home/commonShop/shop_sale_line.png'),6 , 22, {scale9 = true, size = cc.size(92, 2)})
        discountLine:setAnchorPoint(cc.p(0,1))
        self.eventnode:addChild(discountLine,5)
        self.discountLine = discountLine

        local discountPriceNum = cc.Label:createWithBMFont('font/small/common_text_num.fnt', shop.originalPrice)--
        discountPriceNum:setAnchorPoint(cc.p(0, 0))
        discountPriceNum:setHorizontalAlignment(display.TAR)
        discountPriceNum:setPosition(cc.p(10,6))
        self.eventnode:addChild(discountPriceNum,1)
        self.discountPriceNum = discountPriceNum

        local discountCastIcon = display.newNSprite(_res(CommonUtils.GetGoodsIconPathById(arg.consume[1].goodsId)), discountPriceNum:getPositionX()+discountPriceNum:getBoundingBox().width + 4, 6)
        discountCastIcon:setScale(0.2)
        discountCastIcon:setAnchorPoint(cc.p(0,0))
        self.eventnode:addChild(discountCastIcon, 1)
        self.discountCastIcon = discountCastIcon
    else
        local fight_num = cc.Label:createWithBMFont('font/small/common_text_num.fnt', arg.consume[1].num)--
        fight_num:setAnchorPoint(cc.p(0, 0))
        fight_num:setHorizontalAlignment(display.TAR)
        fight_num:setPosition(cc.p(size.width * 0.5,6))
        self.eventnode:addChild(fight_num,1)
        self.numLabel = fight_num


        local castIcon = display.newNSprite(_res(CommonUtils.GetGoodsIconPathById(arg.consume[1].goodsId)), fight_num:getPositionX()+ 4, 6)
        castIcon:setScale(0.2)
        castIcon:setAnchorPoint(cc.p(0,0))
        self.eventnode:addChild(castIcon, 5)
        self.castIcon = castIcon

        display.setNodesToNodeOnCenter(self.eventnode, {fight_num, castIcon}, {y = 6, spaceW = 4})
    end
end

function SaiMoeShopItemCell:setLeftPurchaseCount(count)
    if 0 >= checkint(count) then
        self.toggleView:setNormalImage(_res('ui/home/commonShop/shop_btn_goods_sellout.png'))
        self.toggleView:setSelectedImage(_res('ui/home/commonShop/shop_btn_goods_sellout.png'))
    end
end

return SaiMoeShopItemCell