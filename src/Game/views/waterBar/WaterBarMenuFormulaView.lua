
--[[
 * author : kaishiqi
 * descpt : 水吧 - 信息视图
]]
---@class WaterBarMenuFormulaView
local WaterBarMenuFormulaView = class('WaterBarMenuFormulaView', function()
	return CLayout:create(display.size)
end)
local RES_DICT={
	COMMON_BG_4                        = _res("ui/common/common_bg_4.png"),
	COMMON_BG_GOODS_3                  = _res("ui/common/common_bg_goods_3.png"),
	COMMON_TIPS_LINE                   = _res("ui/common/common_tips_line.png"),
	COMMON_TITLE_5                     = _res("ui/common/common_title_5.png"),
	COMMON_BTN_ORANGE                  = _res("ui/home/activity/common_btn_orange.png"),
	MARKET_BUY_BG_INFO                 = _res("ui/home/commonShop/market_buy_bg_info.png"),
	GOODS_ICON_260016                  = _res("arts/goods/goods_icon_260016.png"),
	KITCHEN_BG_FOOD_QUAN               = _res("ui/home/kitchen/kitchen_bg_food_quan.png"),
	GOODS_ICON_880190                  = _res("arts/goods/goods_icon_880190.png"),
	BAR_SHOP_BG1                       = _res("ui/waterBar/mixedDrink/bar_shop_bg1.png"),
	BAR_SHOP_TIPS_BG                   = _res("ui/waterBar/mixedDrink/bar_shop_tips_bg.png"),
	BAR_SHOP_ICON_RANK                 = _res("ui/common/common_star_l_ico.png"),
	BAR_BARTENDING_ICON_RECONCILIATION = _res("ui/waterBar/mixedDrink/bar_bartending_icon_reconciliation.png"),
	BAR_SHOP_ICON_FREQUENTER           = _res("ui/waterBar/mixedDrink/bar_shop_icon_frequenter.png"),
	BAR_BARTENDING_BG1                 = _res("ui/waterBar/mixedDrink/bar_bartending_bg1.png"),
	BAR_SHOP_BG                        = _res("ui/waterBar/mixedDrink/bar_shop_bg.png"),
	COMMON_STAR_GREY_L_ICO             = _res("ui/common/common_star_grey_l_ico.png")
}
local KIND_OF_TABLE = {
	ALL_DRINKS  = 1001, -- 全部饮料
	FRUIT_DRINT = 1002, -- 水果饮料
	WINS_DRINT  = 1003, -- 酒
}
function WaterBarMenuFormulaView:ctor(args)
	local closeView = display.newLayer(display.cx , display.cy , {ap = display.CENTER,color = cc.c4b(0,0,0,175),   enable = true, size = display.size })
	self:addChild(closeView)
	local rightLayout = display.newLayer(display.cx + 205, display.cy + 2 ,{ap = display.CENTER,size = cc.size(756,722)})
	self:addChild(rightLayout)
	local rightSwallowLayout = display.newLayer(0,0, {color = cc.c4b(0,0,0,0) , size =cc.size(756,722) })
	rightLayout:addChild(rightSwallowLayout)
	local rightBgImage = display.newImageView( RES_DICT.BAR_SHOP_BG ,378, 361,{ap = display.CENTER})
	rightLayout:addChild(rightBgImage)
	local titleText = display.newLabel(357, 676 , {ttf = true,fontSize = 30 , font = TTF_GAME_FONT,outlineSize = 2,text = __('酒吧菜单')})
	rightLayout:addChild(titleText)
	local drinkGridView = CGridView:create(cc.size(646.3, 640))
	drinkGridView:setSizeOfCell(cc.size(323 , 214 ))
	drinkGridView:setColumns(2)
	drinkGridView:setAutoRelocate(true)
	drinkGridView:setAnchorPoint(display.CENTER)
	drinkGridView:setPosition(363 , 332)
	rightLayout:addChild(drinkGridView)
	local height = 10
	local leftLayout = display.newLayer(display.cx + -358, display.cy + -26.51999 ,{ap = display.CENTER,size = cc.size(436,656.95)})
	self:addChild(leftLayout)
	local leftSwallowLayout = display.newLayer(0,0, {color = cc.c4b(0,0,0,0) ,enable = true ,   size =cc.size(436,656.95) })
	leftLayout:addChild(leftSwallowLayout)
	local bgImage = display.newImageView( RES_DICT.COMMON_BG_4 ,218, 328.475,{ap = display.CENTER,scale9 = true,size = cc.size(436 , 659)})
	leftLayout:addChild(bgImage)
	local bgImage2 = display.newImageView( RES_DICT.BAR_BARTENDING_BG1 ,218, 390,{ap = display.CENTER})
	leftLayout:addChild(bgImage2)
	local drinkInfoLayout = display.newLayer(16.94998, 262.85+height+3 ,{ap = display.LEFT_BOTTOM,size = cc.size(395.7,262.3)})
	leftLayout:addChild(drinkInfoLayout)
	local infoBgImage = display.newImageView( RES_DICT.COMMON_BG_GOODS_3 ,200, 131.15,{ap = display.CENTER,scale9 = true,size = cc.size(395.7 , 262.3)})
	drinkInfoLayout:addChild(infoBgImage)
	local lineImage = display.newImageView( RES_DICT.COMMON_TIPS_LINE ,197.85, 133.15,{ap = display.CENTER,scaleX = 0.7 ,scaleY = 2 })
	drinkInfoLayout:addChild(lineImage)
	local attractCardTitle = display.newButton(197.85, 110.15 , {n = RES_DICT.COMMON_TITLE_5,s = RES_DICT.COMMON_TITLE_5,d = RES_DICT.COMMON_TITLE_5,ap = display.CENTER})
	drinkInfoLayout:addChild(attractCardTitle)
	display.commonLabelParams(attractCardTitle ,{fontSize = 24,
												 text = __('可吸引飨灵'),color = '#5b3c25'})
	local buttonNameTable = {
		{
			name = __('全部'),
			tag  = KIND_OF_TABLE.ALL_DRINKS
		},
		{
			name = __('酒水'),
			tag  = KIND_OF_TABLE.WINS_DRINT
		},
		{
			name = __('软饮'),
			tag  = KIND_OF_TABLE.FRUIT_DRINT
		}
	}
	local buttonTable = {}
	local buttonSize = cc.size(143,96)
	local buttonLayotSize = cc.size(buttonSize.width, buttonSize.height*#buttonNameTable)
	local swallowButtonLayout = display.newLayer(buttonLayotSize.width/2  , buttonLayotSize.height/2 ,{
		size = buttonLayotSize , enable = true , ap = display.CENTER ,
		color = cc.c4b(0,0,0,0),
	})
	local buttonLayot = CLayout:create(buttonLayotSize)
	buttonLayot:addChild(swallowButtonLayout)
	buttonLayot:setPosition(cc.p( display.cx + 520, display.cy +270))
	buttonLayot:setAnchorPoint(display.LEFT_TOP)
	self:addChild(buttonLayot)
	for i = 1, #buttonNameTable do
		local buttonAttr = buttonNameTable[i]
		local btn = display.newButton(buttonSize.width/2,buttonLayotSize.height -((i -0.5) * buttonSize.height), {
			n = _res("ui/common/common_btn_sidebar_common.png"),
			d = _res("ui/common/common_btn_sidebar_selected.png")
		})
		buttonLayot:addChild(btn)
		btn:setTag(buttonAttr.tag)
		display.commonLabelParams(btn , {text = buttonAttr.name , color = "#5b3c25" , fontSize = 22 , offset = cc.p(0, 15) })
		buttonTable[tostring(buttonAttr.tag)] = btn
	end
	local drinkDetailInfoTable = {
		{
			text  = __('饮品券'),
			img   =  CommonUtils.GetGoodsIconPathById(FOOD.GOODS.DEFINE.WATER_BAR_CURRENCY_ID),
			scale = 0.25
		},
		{
			text  = __('酒吧知名度'),
			img   = CommonUtils.GetGoodsIconPathById(FOOD.GOODS.DEFINE.WATER_BAR_POPULARITY_ID),
			scale = 0.25
		},
		{
			text  = __('熟客值'),
			img   = CommonUtils.GetGoodsIconPathById(FOOD.GOODS.DEFINE.WATER_BAR_FREQUENCY_ID),
			scale = 0.25
		}
	}
	local buyInfoTable = {}
	for i =1 , #drinkDetailInfoTable do
		local buyInfo = display.newLayer(47.5, 223-(i-1)*39 ,{ap = display.LEFT_BOTTOM,size = cc.size(309,30)})
		drinkInfoLayout:addChild(buyInfo)
		local buyBgImage = display.newImageView( RES_DICT.MARKET_BUY_BG_INFO ,154.5, 15,{ap = display.CENTER,scale9 = true,size = cc.size(309 , 30)})
		buyInfo:addChild(buyBgImage)
		local iconImage = display.newImageView( drinkDetailInfoTable[i].img ,2.5, 15,{ap = display.CENTER,scale = drinkDetailInfoTable[i].scale })
		buyInfo:addChild(iconImage)
		local priceLabel = display.newLabel(296, 15 , {ap = display.RIGHT_CENTER ,  fontSize = 24,text = "",color = '#5C5B57'})
		buyInfo:addChild(priceLabel)
		local goldName = display.newLabel(31, 15 , {ap = display.LEFT_CENTER ,  fontSize = 24,text = drinkDetailInfoTable[i].text,color = '#a74700'})
		buyInfo:addChild(goldName)
		buyInfoTable[#buyInfoTable+1] = {
			buyInfo    = buyInfo,
			iconImage  = iconImage,
			priceLabel = priceLabel,
			goldName   = goldName
		}
	end
	local needFoodLayout = display.newLayer(16.94998, 125 +height+8,{ap = display.LEFT_BOTTOM,size = cc.size(395.7,130)})
	leftLayout:addChild(needFoodLayout)

	local cardLayout = display.newLayer(200, 45 ,{ap = display.CENTER,size = cc.size(100,100)})
	drinkInfoLayout:addChild(cardLayout)

	local needBgImage = display.newImageView( RES_DICT.COMMON_BG_GOODS_3 ,200, 65,{ap = display.CENTER,scale9 = true,size = cc.size(395.7 , 130)})
	needFoodLayout:addChild(needBgImage)
	local needFoodTitle = display.newButton(197.85, 110 , {n = RES_DICT.COMMON_TITLE_5,s = RES_DICT.COMMON_TITLE_5,d = RES_DICT.COMMON_TITLE_5,ap = display.CENTER})
	needFoodLayout:addChild(needFoodTitle)
	display.commonLabelParams(needFoodTitle ,{fontSize = 24,text = __('所需食材'),color = '#5b3c25'})
	local goodsLayout = display.newLayer(200, 50 ,{ap = display.CENTER,size = cc.size(100,100)})
	needFoodLayout:addChild(goodsLayout)

	local drinkCircleImage = display.newImageView( RES_DICT.KITCHEN_BG_FOOD_QUAN ,135, 583.475+height,{ap = display.CENTER,scaleX = 0.65,scaleY = 0.65})
	leftLayout:addChild(drinkCircleImage)
	local drinkImage = display.newImageView( RES_DICT.GOODS_ICON_880190 ,135, 583.475+height,{ap = display.CENTER,scaleX = 0.65,scaleY = 0.65})
	leftLayout:addChild(drinkImage)
	local drinkName = display.newLabel(271, 600.475+height , {fontSize = 28,ttf = true,font = TTF_GAME_FONT,outlineSize = 1,text = '',color = '#ba5c5c'})
	leftLayout:addChild(drinkName)
	local drinkStarLayout = display.newLayer(271, 560 +height,{ap = display.CENTER,size = cc.size(120,40)})
	leftLayout:addChild(drinkStarLayout)
	local starTables = {}
	local width = 40
	for i = 1, 3 do
		local img = display.newImageView( RES_DICT.BAR_SHOP_ICON_RANK ,width*(i-0.5), width/2)
		drinkStarLayout:addChild(img)
		starTables[#starTables+1] = img
	end
	local reconcileBtn = display.newButton(218, 74.47498 , {n = RES_DICT.COMMON_BTN_ORANGE,s = RES_DICT.COMMON_BTN_ORANGE,d = RES_DICT.COMMON_BTN_ORANGE,ap = display.CENTER})
	leftLayout:addChild(reconcileBtn)
	display.commonLabelParams(reconcileBtn ,fontWithColor(14 , {fontSize = 24,text = __('调制'),color = '#ffffff'}))

	self.viewData = {
		leftLayout       = leftLayout,
		bgImage          = bgImage,
		cardLayout       = cardLayout,
		goodsLayout      = goodsLayout,
		drinkInfoLayout  = drinkInfoLayout,
		infoBgImage      = infoBgImage,
		lineImage        = lineImage,
		attractCardTitle = attractCardTitle,
		buyInfoTable     = buyInfoTable,
		needFoodLayout   = needFoodLayout,
		needBgImage      = needBgImage,
		needFoodTitle    = needFoodTitle,
		drinkCircleImage = drinkCircleImage,
		drinkImage       = drinkImage,
		drinkName        = drinkName,
		drinkStarLayout  = drinkStarLayout,
		rightLayout      = rightLayout,
		rightBgImage     = rightBgImage,
		titleText        = titleText,
		closeView        = closeView,
		reconcileBtn     = reconcileBtn,
		buttonTable      = buttonTable,
		starTables       = starTables,
		drinkGridView    = drinkGridView
	}
end

function WaterBarMenuFormulaView:CreateSelectFormulaSpine()
	local lightSpine =  _spnEx('ui/waterBar/mixedDrinkAnimate/light')
	local lightNode = sp.SkeletonAnimation:create(lightSpine.json, lightSpine.atlas, 1)
	lightNode:setAnimation(0, "play", false)
	lightNode:setName("lightNode")
	lightNode:setAnchorPoint(display.CENTER)
	lightNode:retain()
	self.viewData.lightNode = lightNode
	local spinecallBack = function (event)
		local eventName = event.animation
		if eventName == "play"  then
			self.viewData.lightNode:setAnimation(0, "idle", true)
		elseif  eventName == "stop" then
			self.viewData.lightNode:setAnimation(0, "play", false)
		end
	end
	self.viewData.lightNode:registerSpineEventHandler(spinecallBack, sp.EventType.ANIMATION_COMPLETE)
end
function WaterBarMenuFormulaView:UpdateSelectFormuSpine(node)
	local nodeSize = node:getContentSize()
	if not self.viewData.lightNode then
		self:CreateSelectFormulaSpine()
		node:addChild(self.viewData.lightNode)
	else
		self.viewData.lightNode:removeFromParent()
		node:addChild(self.viewData.lightNode)
	end
	self.viewData.lightNode:setVisible(true)
	self.viewData.lightNode:setPosition(nodeSize.width/2-30, -nodeSize.height/2+30)
	self.viewData.lightNode:setAnimation(0, "stop", false)
end
----=======================----
--@author : xingweihao
--@date : 2020/2/21 5:02 PM
--@Description 更新可吸引的飨灵的显示
--@params cardsData : table 传cardId
--@return
---=======================----
function WaterBarMenuFormulaView:UpdateCardLayout(cardsData)
	local cardLayout = self.viewData.cardLayout
	cardLayout:removeAllChildren()
	if #cardsData == 0 then
		local cardLayoutSize = cardLayout:getContentSize()
		cardLayout:addChild(display.newLabel(cardLayoutSize.width/2 , cardLayoutSize.height/2 , fontWithColor(14, { outline = false , fontSize = 30 ,color = "#ba5c5c",outlineSize = 2,text = __('暂无可吸引的飨灵')})))
		return
	end
	local count = #cardsData
	local width = 100
	local height = 100
	local cardSize = cc.size(count * width ,  height)
	cardLayout:setContentSize(cardSize)
	for i =1 , count do
		local cardNode = require("common.GoodNode").new({goodsId =cardsData[i]})
		cardNode:setPosition((i - 0.5) * width ,height /2)
		cardNode:setScale(0.75)
		cardLayout:addChild(cardNode)
		local likeIcon = display.newImageView(RES_DICT.BAR_SHOP_ICON_FREQUENTER ,0 , 0 , {ap = display.LEFT_BOTTOM}  )
		cardNode:addChild(likeIcon,20)
		cardNode:setTag(checkint(cardsData[i]))
	end
end
----=======================----
--@author : xingweihao
--@date : 2020/2/21 5:02 PM
--@Description 调和饮料所需要的食材
--@params goodsData : table 传所需的goodsId
--@return
---=======================----
function WaterBarMenuFormulaView:UpdateGoodsLayout(goodsData)
	local goodsLayout = self.viewData.goodsLayout
	goodsLayout:removeAllChildren()
	local count = #goodsData
	local width = 100
	local height = 100
	local goodSize = cc.size(count * width ,  height)
	goodsLayout:setContentSize(goodSize)
	for i =1 , count do
		local goodNode = require("common.GoodNode").new({goodsId = goodsData[i] })
		goodNode:setAnchorPoint(display.CENTER)
		goodNode:setPosition((i - 0.5) * width ,height /2)
		goodsLayout:addChild(goodNode)
		goodNode:setScale(0.75)
		goodNode:setTag(checkint(goodsData[i]))
		display.commonUIParams(goodNode, {animate = false , cb = function(sender)
			app.uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId =sender:getTag(), type = 1})
		end})
	end
end

function WaterBarMenuFormulaView:UpdateView(data)
	local formulaId = data.formulaId
	local formulaConf = CONF.BAR.FORMULA:GetValue(formulaId)
	local showMaterialOrder = string.split(formulaConf.showMaterialOrder , ";")
	self:UpdateGoodsLayout(showMaterialOrder)
	local customerLikeTable = app.waterBarMgr:GetCustomersLikeFormulaByFormulaId(formulaId)
	self:UpdateCardLayout(customerLikeTable)
	local viewData = self.viewData
	viewData.drinkImage:setTexture(CommonUtils.GetGoodsIconPathById(formulaId))
	display.commonLabelParams(viewData.drinkName , {text = formulaConf.name})
	local highStar = app.waterBarMgr:getFormulaMaxStar(data.formulaId)
	local num = checkint(highStar)
	if num >= 0  then
		local drinks = formulaConf.drinks or {}
		local drinkConf = CONF.BAR.DRINK:GetValue(tostring(drinks[num +1]) )
		local priceTable = {
			drinkConf.barPoint ,
			drinkConf.barPopularity ,
			drinkConf.frequencyPoint ,
		}
		-- 更新食材的价格显示
		for i, buyInfo in pairs(viewData.buyInfoTable) do
			display.commonLabelParams(buyInfo.priceLabel , {text = string.fmt(__("_num_/份") ,{_num_ = priceTable[i]}) })
		end
	else
		for i, buyInfo in pairs(viewData.buyInfoTable) do
			display.commonLabelParams(buyInfo.priceLabel , {text = string.fmt(__("_num_/份") ,{_num_ = "????"}) })
		end
	end
	for i =1 , num do
		if  viewData.starTables[i] then
			viewData.starTables[i]:setTexture(RES_DICT.BAR_SHOP_ICON_RANK)
		end
	end
	for  i = num +1 , 3 do
		if  viewData.starTables[i] then
			viewData.starTables[i]:setTexture(RES_DICT.COMMON_STAR_GREY_L_ICO)
		end
	end
end

return WaterBarMenuFormulaView
