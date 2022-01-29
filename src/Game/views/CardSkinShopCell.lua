local CardSkinShopCell = class('Game.views.CardSkinShopCell',function ()
    local pageviewcell = CGridViewCell:new()
    pageviewcell.name = 'Game.views.CardSkinShopCell'
    pageviewcell:enableNodeEvents()
    return pageviewcell
end)

function CardSkinShopCell:ctor(...)

    local arg = {...}
    local size = arg[1] or cc.size(200 , 390)
    self:setContentSize(size)
    
    local eventNode = CLayout:create(cc.size(200 , 390))
    eventNode:setPosition(utils.getLocalCenter(self))
    self:addChild(eventNode)
    self.eventnode = eventNode
    
    local toggleView = display.newButton(size.width * 0.5 ,size.height * 0.5,{--
        n = _res('ui/home/commonShop/shop_skin_bg_frame.png')
    })
    self.toggleView = toggleView
    self.eventnode:addChild(self.toggleView,10)
    

	-- local bg = display.newImageView(_res('ui/home/commonShop/shop_skin_bg_frame.png'), size.width * 0.5 + 1, size.height * 0.5 + 12)
	-- self.eventnode:addChild(bg,2)
	
	local lsize = cc.size(193 , 390)
	local roleClippingNode = cc.ClippingNode:create()
	roleClippingNode:setContentSize(cc.size(lsize.width , lsize.height -10))
	roleClippingNode:setAnchorPoint(0.5, 1)
	roleClippingNode:setPosition(cc.p(size.width / 2, lsize.height +10  ))
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


	local bottomBg = display.newImageView(_res('ui/home/commonShop/shop_skin_bg_name.png'), size.width * 0.5 , 20)
	bottomBg:setAnchorPoint(cc.p(0.5,0))
	self.eventnode:addChild(bottomBg,2)
	local bottomSize = bottomBg:getContentSize()

	local topBg = display.newImageView(_res('ui/home/commonShop/shop_skin_bg_time.png'), size.width * 0.5 , size.height - 20)
	topBg:setAnchorPoint(cc.p(0.5,1))
	self.eventnode:addChild(topBg,2)
	topBg:setVisible(false)
	self.topBg = topBg
	
    local markerBtn = display.newButton(0 ,145,{--
        n = _res('ui/home/commonShop/shop_tag_hot.png'),ap = cc.p(0,0) ,scale9 = true
    })
    display.commonLabelParams(markerBtn, fontWithColor(14,{text = __('热卖') , paddingW =  10 }))
    self.markerBtn = markerBtn
    self.eventnode:addChild(self.markerBtn,10)


	local refreshLabel = display.newLabel(50, 15, {text = __('剩余时间'), fontSize = 20, color = 'ffffff'})
	topBg:addChild(refreshLabel)
	local refreshTimeLabel = display.newLabel(96, 15, {ap = cc.p(0,0.5),text = '00:00:00', fontSize = 20, color = 'ffc61a'})
	topBg:addChild(refreshTimeLabel)
	self.refreshTimeLabel = refreshTimeLabel


	local skinNameLabel = display.newLabel(bottomSize.width*0.5 , 108,fontWithColor(14,{fontSize = 22,text = __('皮肤名'),color = 'ffe155',outline = '4f2212',outlineSize = 1}))-- {text = __('剩余时间'), fontSize = 20, color = 'ffffff'}
	bottomBg:addChild(skinNameLabel)
	self.skinNameLabel = skinNameLabel

	local cardNameLabel = display.newLabel(bottomSize.width*0.5 , 83,fontWithColor(14,{fontSize = 20,text = __('飨灵名称'),color = 'ffffff'}) )--{ap = cc.p(0,0.5),text = '00:00:00', fontSize = 20, color = 'ffc61a'}
	bottomBg:addChild(cardNameLabel)
	self.cardNameLabel = cardNameLabel
	self.bottomSize = bottomSize


	local discountSize = cc.size(200, 36)
	local discountLayout = display.newLayer(bottomSize.width /2 ,35 , { ap = display.CENTER , size = discountSize})
	bottomBg:addChild(discountLayout,20)
	self.discountLayout = discountLayout


	local discountRichLabel = display.newRichLabel(discountSize.width /2 , discountSize.height/2 ,{ap = display.CENTER ,  c = {
		fontWithColor(14, {text = "1111"})
	} })
	discountLayout:addChild(discountRichLabel)
	self.discountRichLabel = discountRichLabel

	local discountLine = display.newImageView(_res('ui/home/commonShop/shop_sale_line.png'),discountSize.width /2 , discountSize.height/2)
	discountLayout:addChild(discountLine,5)
	self.discountLine = discountLine
	discountLine:setScaleX(2.2)


	local isHasLabel = display.newLabel(size.width*0.5 , 40,fontWithColor(14,{text = __('已拥有'),color = 'ffcb2b',outline = '361e11',outlineSize = 1}))
	isHasLabel:setAnchorPoint(cc.p(0.5, 0))
	self:addChild(isHasLabel)
	isHasLabel:setVisible(false)
	self.isHasLabel = isHasLabel

	local isHasImg = display.newImageView(_res('ui/home/commonShop/shop_skin_bg_black.png'),size.width*0.5  , size.height*0.5)
	isHasImg:setAnchorPoint(cc.p(0.5,0.5))
	self.eventnode:addChild(isHasImg,10)
	isHasImg:setVisible(false)
	self.isHasImg = isHasImg


	local priceRichLabel = display.newRichLabel(bottomSize.width /2 , 5, {ap = display.CENTER,  c= {
		fontWithColor(14,{text = "111"})
	}})
	bottomBg:addChild(priceRichLabel)
	self.priceRichLabel = priceRichLabel
end
return CardSkinShopCell
