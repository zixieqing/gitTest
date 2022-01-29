local CommonShopCell = class('Game.views.CommonShopCell',function ()
    local pageviewcell = CGridViewCell:new()
    pageviewcell.name = 'Game.views.CommonShopCell'
    pageviewcell:enableNodeEvents()
    return pageviewcell
end)

function CommonShopCell:ctor(...)
    local arg = {...}
    local size = cc.size(200 , 252)
    self:setContentSize(arg.size or size)

    local eventNode = CLayout:create(cc.size(200 , 252))
    eventNode:setPosition(utils.getLocalCenter(self))
    self:addChild(eventNode)
    self.eventnode = eventNode

    local toggleView = display.newButton(size.width * 0.5,size.height * 0.5,{--
        n = _res('ui/home/commonShop/shop_btn_goods_default.png')
    })
    self.toggleView = toggleView
    self.eventnode:addChild(self.toggleView)


    local goodNode = require('common.GoodNode').new({id = GOLD_ID, amount = 0, showAmount = true,showName = true})
    goodNode:setAnchorPoint(cc.p(0.5,0))
    local  nameLabel =   goodNode.nameLabel
    display.commonLabelParams(nameLabel ,{w = 170 ,text =""})
    local posY = nameLabel:getPositionY()
    nameLabel:setPositionY(posY + 10)
    -- goodNode:setScale(0.8)
    goodNode:setPosition(cc.p(size.width * 0.5,120))
    self.eventnode:addChild(goodNode)
    self.goodNode = goodNode


    local fight_num = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '')--
    fight_num:setAnchorPoint(cc.p(0.5, 0))
    fight_num:setHorizontalAlignment(display.TAR)
    fight_num:setPosition(cc.p(size.width * 0.5 ,-6))
    self.eventnode:addChild(fight_num,1)
    self.numLabel = fight_num



    --剩余次数
    local leftTimesLabel = display.newRichLabel(size.width/2, 30,{ ap = cc.p(0.5,0), r = true ,
     c = {fontWithColor('8', { color = "ae8668" ,fontSize = 20 , text = __('今日剩余购买')}),
     fontWithColor('8', { color = "ac5a4a" ,fontSize = 20 , text = ('9')}),
     fontWithColor('8', { color = "ae8668" ,fontSize = 20 , text = __('次数')}) }})
    self.eventnode:addChild(leftTimesLabel)
    self.leftTimesLabel = leftTimesLabel

    local castIcon = display.newImageView(_res(CommonUtils.GetGoodsIconPathById(GOLD_ID)), fight_num:getPositionX()+fight_num:getBoundingBox().width + 4, fight_num:getPositionY())
    castIcon:setScale(0.2)
    castIcon:setAnchorPoint(cc.p(0,0))
    self.eventnode:addChild(castIcon, 5)
    self.castIcon = castIcon

    local sellLabel = display.newLabel(2, size.height - 24  ,
        fontWithColor(14,{color = 'd65050',text = __('售罄'),fontSize = 22,ap = cc.p(0, 1)}))
    self.eventnode:addChild(sellLabel)
    sellLabel:enableOutline(cc.c4b(255, 255, 255, 0), 1)
    self.sellLabel = sellLabel

    local discountBg = display.newImageView(_res('ui/home/commonShop/shop_tag_sale'), 2, size.height - 50)
    discountBg:setAnchorPoint(cc.p(0,1))
    self.eventnode:addChild(discountBg, 5)
    self.discountBg = discountBg
    discountBg:setVisible(false)
    local discountNum = display.newLabel(utils.getLocalCenter(discountBg).x, utils.getLocalCenter(discountBg).y, fontWithColor(14, {text = '3折', ap = cc.p(0.5, 0.5)}))
    discountBg:addChild(discountNum)
    self.discountNum = discountNum


    local refreshLabel = display.newLabel(size.width/2 - 50, size.height + 2, {ap = cc.p(0.5,1),text = __('剩余时间'), reqW = 90 ,fontSize = 20, color = '3c3c3c'})
    self.eventnode:addChild(refreshLabel)
    refreshLabel:setVisible(false)
    self.refreshLabel = refreshLabel

    local refreshTimeLabel = display.newLabel(size.width/2 + 50, size.height + 2, {ap = cc.p(0.5,1),text = '00:00:00', fontSize = 20, color = 'd23d3d'})
    self.eventnode:addChild(refreshTimeLabel)
    refreshTimeLabel:setVisible(false)
    self.refreshTimeLabel = refreshTimeLabel



    local discountPriceNum = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '')--
    discountPriceNum:setAnchorPoint(cc.p(0, 0))
    discountPriceNum:setHorizontalAlignment(display.TAR)
    discountPriceNum:setPosition(cc.p(6,4))
    self.eventnode:addChild(discountPriceNum,1)
    self.discountPriceNum = discountPriceNum

    local discountCastIcon = display.newImageView(_res(CommonUtils.GetGoodsIconPathById(GOLD_ID)), discountPriceNum:getPositionX()+discountPriceNum:getBoundingBox().width , 4)
    discountCastIcon:setScale(0.2)
    discountCastIcon:setAnchorPoint(cc.p(0,0))
    self.eventnode:addChild(discountCastIcon, 5)
    self.discountCastIcon = discountCastIcon


    local discountLine = display.newImageView(_res('ui/home/commonShop/shop_sale_line.png'),5 , 20)
    discountLine:setAnchorPoint(cc.p(0,1))
    self.eventnode:addChild(discountLine,5)
    self.discountLine = discountLine

    self.discountLine:setVisible(false)
    self.discountPriceNum:setVisible(false)
    self.discountCastIcon:setVisible(false)

    local priceHotImage = display.newImageView(_res('ui/home/commonShop/shop_tag_iconid_1'), size.width + 4, size.height - 30, {
        ap = display.RIGHT_TOP})
    local priceHotLabel = display.newLabel(size.width-2 , size.height- 33,fontWithColor('14' , {ttf = false , text = "", ap = display.RIGHT_TOP }))
    self:addChild(priceHotLabel,1235)
    priceHotLabel:setVisible(false)
    priceHotLabel:setName("HOTIMAGELABEL")
    self:addChild(priceHotImage, 1234)
    priceHotImage:setVisible(false)
    priceHotImage:setName('HOTIMAGE')

    self.lockLabel = display.newButton(size.width/2, size.height*0.6, {n = _res('ui/home/union/guild_shop_lock_wrod.png'), enable = false})
    display.commonLabelParams(self.lockLabel, fontWithColor(20, {fontSize = 24, w = size.width - 10, hAlign = display.TAC}))
    self.lockLabel:setVisible(false)
    self.eventnode:addChild(self.lockLabel,5)
end
return CommonShopCell
