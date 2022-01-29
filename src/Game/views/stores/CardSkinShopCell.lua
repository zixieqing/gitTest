---@class CardSkinShopCell
local CardSkinShopCell = class('Game.views.CardSkinShopCell',function ()
    local pageviewcell = CGridViewCell:new()
    pageviewcell.name = 'Game.views.stores.CardSkinShopCell'
    pageviewcell:enableNodeEvents()
    return pageviewcell
end)

function CardSkinShopCell:ctor(...)

    local arg = {...}
    local size = arg[1] or cc.size(234 , 558)
    self:setContentSize(size)
    
    local eventNode = CLayout:create(cc.size(230, 558))
    eventNode:setPosition(utils.getLocalCenter(self))
    -- eventNode:setBackgroundColor(cc.c4b(200, 0, 0, 100))
    self:addChild(eventNode)
    self.eventnode = eventNode
    
    local toggleView = display.newButton(size.width * 0.5 ,size.height * 0.5,{--
        n = _res('ui/stores/cardSkin/shop_btn_skin_default.png'),
        s = _res('ui/stores/cardSkin/shop_btn_skin_default.png')
    })
    self.toggleView = toggleView
    self.eventnode:addChild(self.toggleView,10)
    

	-- local bg = display.newImageView(_res('ui/home/commonShop/shop_skin_bg_frame.png'), size.width * 0.5 + 1, size.height * 0.5 + 12)
	-- self.eventnode:addChild(bg,2)
	
	local lsize = cc.size(200 , 550)
	local roleClippingNode = cc.ClippingNode:create()
	roleClippingNode:setContentSize(cc.size(lsize.width , lsize.height -10))
	roleClippingNode:setAnchorPoint(0.5, 1)
	roleClippingNode:setPosition(cc.p(lsize.width / 2 + 10, lsize.height))
	roleClippingNode:setInverted(false)
	self.eventnode:addChild(roleClippingNode, 1)
	-- cut layer
	local cutLayer = display.newLayer(
		0,
		0,
		{
			size = roleClippingNode:getContentSize(),
			ap = cc.p(0, 0), 
			color = '#ffcc00'
		})

	local imgHero = AssetsUtils.GetCardDrawNode()
	imgHero:setAnchorPoint(display.LEFT_BOTTOM)
	-- imgHero:setVisible(false)
	self.imgHero = imgHero


	local imgBg = AssetsUtils.GetCardTeamBgNode(0, 0, 0)
	imgBg:setAnchorPoint(display.LEFT_BOTTOM)
	-- imgBg:setVisible(false)
	self.imgBg = imgBg

	roleClippingNode:setStencil(cutLayer)
	roleClippingNode:addChild(imgHero,1)
	roleClippingNode:addChild(imgBg)


	-- local bottomBg = display.newImageView(_res('ui/home/commonShop/shop_skin_bg_name.png'), size.width * 0.5 , 20)
	-- bottomBg:setAnchorPoint(cc.p(0.5,0))
	-- self.eventnode:addChild(bottomBg,2)
	-- local bottomSize = bottomBg:getContentSize()

	local topBg = display.newImageView(_res('ui/stores/cardSkin/shop_skin_bg_time.png'), size.width * 0.5 -8, size.height - 10,
{size = cc.size(200, 65) , scale9 = true })
	topBg:setAnchorPoint(cc.p(0.5,1))
	self.eventnode:addChild(topBg,2)
	topBg:setVisible(false)
	self.topBg = topBg
	
    local markerBtn = display.newButton(0 ,size.height - 75,{--
        n = _res('ui/stores/cardSkin/shop_tag_hot.png'),ap = cc.p(0,1)
    })
    display.commonLabelParams(markerBtn, fontWithColor(14,{text = __('热卖'), fontSize = 22, color = 'ffffff', outline = '8f2318', outlineSize = 2}))
    self.markerBtn = markerBtn
    self.eventnode:addChild(self.markerBtn,10)


	local refreshLabel = display.newLabel(15, 48, {ap = display.LEFT_CENTER ,  text = __('剩余时间'), fontSize = 20, color = 'ffffff'})
	topBg:addChild(refreshLabel)
	local refreshTimeLabel = display.newLabel(15, 16, {ap = display.LEFT_CENTER , text = '00:00:00', fontSize = 20, color = 'ffc61a'})
	topBg:addChild(refreshTimeLabel)
	self.refreshTimeLabel = refreshTimeLabel


	local bottomNameBg = display.newImageView(_res('ui/stores/cardSkin/shop_skin_bg_name.png'), size.width * 0.5 - 8 , 4)
	bottomNameBg:setAnchorPoint(cc.p(0.5,0))
	self.eventnode:addChild(bottomNameBg,2)
	local bbSize = bottomNameBg:getContentSize()
	local lineImg = display.newImageView(_res('ui/stores/cardSkin/shop_skin_bg_line_name.png'), bbSize.width * 0.5, bbSize.height * 0.5)
	bottomNameBg:addChild(lineImg,2)
	local skinNameLabel = display.newLabel(bbSize.width*0.5 , 54,fontWithColor(14,{fontSize = 22,text = __('皮肤名'),color = 'ffcb69',outline = '402008',outlineSize = 2}))-- {text = __('剩余时间'), fontSize = 20, color = 'ffffff'}
	bottomNameBg:addChild(skinNameLabel)
	self.skinNameLabel = skinNameLabel

	local cardNameLabel = display.newLabel(bbSize.width*0.5 , 22,fontWithColor(14,{fontSize = 20,text = __('飨灵名称'),color = 'ffffff',outline = '402008',outlineSize = 2}) )--{ap = cc.p(0,0.5),text = '00:00:00', fontSize = 20, color = 'ffc61a'}
	bottomNameBg:addChild(cardNameLabel)
	self.cardNameLabel = cardNameLabel
	


	local discountSize = cc.size(200, 92)
	local discountLayout = display.newLayer(lsize.width /2 + 8 ,78 , { ap = display.CENTER_BOTTOM , size = discountSize})
	self.eventnode:addChild(discountLayout,1)
	-- discountLayout:setBackgroundColor(cc.c4b(100,100,100,100))
	self.discountLayout = discountLayout

	local discountOneBg = display.newImageView(_res('ui/stores/cardSkin/shop_skin_bg_price.png'), discountSize.width * 0.5, 24)
	discountLayout:addChild(discountOneBg,2)
	local discountRichLabel = display.newRichLabel(10 ,30 ,{ap = display.LEFT_CENTER ,  c = {
		fontWithColor(14, {text = ""})
	} })
	local discountLine = display.newImageView(_res('ui/stores/cardSkin/shop_skin_line_delete.png'), 6, 30,{ap = display.LEFT_CENTER})
	discountLine:setName("LINE")
	discountOneBg:addChild(discountLine,20)
	discountRichLabel:setName("DISCOUNT")
	discountOneBg:addChild(discountRichLabel,4)
	discountRichLabel:setVisible(false)
	local priceRichLabel = display.newRichLabel(lsize.width - 10 , 30, {ap = display.RIGHT_CENTER,  c= {
		fontWithColor(14,{text = ""})
	}})
	priceRichLabel:setName("PRICE")
	discountOneBg:addChild(priceRichLabel,4)
	self.discountOneBg = discountOneBg

	local orImage = display.newButton(discountSize.width * 0.5, 48, {
			n = _res('ui/stores/cardSkin/shop_skin_bg_text_or.png'),
			s = _res('ui/stores/cardSkin/shop_skin_bg_text_or.png')
		})
	orImage:setEnabled(false)
	display.commonLabelParams(orImage, fontWithColor(14, {color = 'ffffff', fontSize = 20, text = __("或")}))
	discountLayout:addChild(orImage, 20)
	self.orImage = orImage

	local discountTwoBg = display.newImageView(_res('ui/stores/cardSkin/shop_skin_bg_price.png'), discountSize.width * 0.5, 70)
	discountLayout:addChild(discountTwoBg,2)
	local discountRich2Label = display.newRichLabel(10 ,30 ,{ap = display.LEFT_CENTER ,  c = {
		fontWithColor(14, {text = ""})
	} })
	discountRich2Label:setName("DISCOUNT")
	discountTwoBg:addChild(discountRich2Label,4)
	discountRich2Label:setVisible(false)
	local discountLine = display.newImageView(_res('ui/stores/cardSkin/shop_skin_line_delete.png'), 6, 30, {ap = display.LEFT_CENTER})
	discountLine:setName("LINE")
	discountTwoBg:addChild(discountLine,20)
	local priceRichLabel = display.newRichLabel(lsize.width - 10 , 30, {ap = display.RIGHT_CENTER,  c= {
		fontWithColor(14,{text = ""})
	}})
	priceRichLabel:setName("PRICE")
	discountTwoBg:addChild(priceRichLabel,4)
	self.discountTwoBg = discountTwoBg

	local isHasImg = display.newImageView(_res('ui/stores/cardSkin/shop_skin_bg_black.png'),size.width*0.5, size.height*0.5)
	isHasImg:setAnchorPoint(cc.p(0.5,0.5))
	self.eventnode:addChild(isHasImg,10)
	isHasImg:setVisible(false)
	self.isHasImg = isHasImg
	local ishaveButton = display.newButton(size.width * 0.5 - 8,252, {
			n = _res('ui/stores/cardSkin/shop_skin_bg_owned.png'),
			s = _res('ui/stores/cardSkin/shop_skin_bg_owned.png')
		})
	ishaveButton:setEnabled(false)
	self.eventnode:addChild(ishaveButton, 20)
	local isHasLabel = display.newLabel(ishaveButton:getContentSize().width*0.5 , 14,fontWithColor(14,{text = __('已拥有'),color = 'ffcb2b',outline = '361e11',outlineSize = 1}))
	isHasLabel:setAnchorPoint(cc.p(0.5, 0))
	ishaveButton:addChild(isHasLabel)
	-- isHasLabel:setVisible(false)
	self.isHasLabel = ishaveButton
end
return CardSkinShopCell