
--[[
 * author : xingweihao
 * descpt : 饮料调配界面
]]
---@class WaterBarDeployFormulaView
local WaterBarDeployFormulaView = class('WaterBarDeployFormulaView', function()
	return CLayout:create(display.size)
end)
local waterBarMgr = app.waterBarMgr
local RES_DICT={
	BAR_BARTENDING_BG                        = _res("ui/waterBar/mixedDrink/bar_bartending_bg.png"),
	BAR_BARTENDING_BG_CHOICE_SELECTED        = _res("ui/waterBar/mixedDrink/bar_bartending_bg_choice_selected.png"),
	BAR_BARTENDING_BG_LIST                   = _res("ui/waterBar/mixedDrink/bar_bartending_bg_list.png"),
	GOLD_TRADE_WARE_BG_LISTDI_FRONT          = _res("ui/waterBar/mixedDrink/gold_trade_ware_bg_listdi_front.png"),
	COMMON_TITLE_5                           = _res("ui/common/common_title_5.png"),
	COMMON_BTN_TIPS                          = _res('ui/common/common_btn_tips.png'),
	COMMON_TIPS_LINE                         = _res("ui/common/common_tips_line.png"),
	COMMON_BG_LIST_3                         = _res("ui/common/common_bg_list_3.png"),
	BAR_BARTENDING_BG_CHOICE                 = _res("ui/waterBar/mixedDrink/bar_bartending_bg_choice.png"),
	BAR_BARTENDING_ICON_RECONCILIATION       = _res("ui/waterBar/mixedDrink/bar_bartending_icon_reconciliation.png"),
	BAR_BARTENDING_ICON_SHAKE                = _res("ui/waterBar/mixedDrink/bar_bartending_icon_shake.png"),
	BAR_BARTENDING_ICON_STIR                 = _res("ui/waterBar/mixedDrink/bar_bartending_icon_stir.png"),
	COMMON_RECORD_BG_AVATOR                  = _res("ui/common/common_record_bg_avator.png"),
	MARKET_CHOICE_BG_PRIZCE                  = _res("ui/home/market/market_choice_bg_prizce.png"),
	MARKET_SOLD_BTN_PLUS                     = _res("avatar/ui/market_sold_btn_plus.png"),
	MARKET_SOLD_BTN_SUB                      = _res("ui/home/market/market_sold_btn_sub.png"),
	BAR_BARTENDING_BTN_LEFT                  = _res("ui/waterBar/mixedDrink/bar_bartending_btn_left.png"),
	BAR_BARTENDING_BTN_RIGHT                 = _res("ui/waterBar/mixedDrink/bar_bartending_btn_right.png"),
	BAR_BTN_SUBTRACTED                       = _res("ui/waterBar/mixedDrink/bar_btn_subtracted.png"),
	BAR_COMMON_BG_GOODS_3                    = _res("ui/waterBar/mixedDrink/bar_common_good_3.png"),
	COMMON_BG_GOODS_3                        = _res("ui/common/common_bg_goods_3.png"),
	MARKET_BUY_BG_INFO                       = _res("ui/home/commonShop/market_buy_bg_info.png"),
	GOODS_ICON_260016                        = _res("arts/goods/goods_icon_260016.png"),
	KITCHEN_BG_FOOD_QUAN                     = _res("ui/home/kitchen/kitchen_bg_food_quan.png"),
	GOODS_ICON_880190                        = _res("arts/goods/goods_icon_880190.png"),
	BAR_BARTENDING_BG2                       = _res("ui/waterBar/mixedDrink/bar_bartending_bg2.png"),
	BAR_TIPS_MSG                             = _res("ui/waterBar/mixedDrink/bar_tips_msg.png"),
	COMMON_BTN_ORANGE                        = _res("ui/home/activity/common_btn_orange.png"),
	BAR_BARTENDING_ICON_RECORDS              = _res("ui/waterBar/mixedDrink/bar_bartending_icon_records.png"),
	BAR_BARTENDING_BAR_ACTIVE_TIPS           = _res("ui/waterBar/mixedDrink/bar_bartending_bar_active_tips.png"),
	BAR_BARTENDING_BAR_ACTIVE                = _res("ui/waterBar/mixedDrink/bar_bartending_bar_active.png"),
	BAR_FRAME_BG                             = _res("ui/waterBar/mixedDrink/bar_frame_bg.png"),
	BAR_BARTENDING_CONTENT_SELECTED          = _res("ui/waterBar/mixedDrink/bar_bartending_content_selected.png"),
	BAR_BARTENDING_SELECTED_LEFT             = _res("ui/waterBar/mixedDrink/bar_bartending_selected_left.png"),
	BAR_BARTENDING_SELECTED_RIGHT            = _res("ui/waterBar/mixedDrink/bar_bartending_selected_right.png"),
	BAR_BARTENDING_BG1                       = _res("ui/waterBar/mixedDrink/bar_bartending_bg1.png"),
	BAR_BARTENDING_BAR_ACTIVE1               = _res("ui/waterBar/mixedDrink/bar_bartending_bar_active1.png"),
	BAR_BARTENDING_BTN_RESET                 = _res("ui/waterBar/mixedDrink/bar_bartending_btn_reset.png"),
	RESTAURANT_BG_BOARD                      = _res("ui/home/lobby/cooking/restaurant_bg_board.png"),
	BAR_ICON_FREQUENTER                      = _res("ui/waterBar/home/bar_icon_frequenter.png"),
	BAR_ICON_SUPPLIERS                       = _res("ui/waterBar/home/bar_icon_suppliers.png"),
	BAR_SHOP_ICON_RANK                       = _res("ui/common/common_star_l_ico.png"),
	RESTAURANT_BTN_MY_FRIENDS                = _res("avatar/ui/restaurant_btn_my_friends.png") ,
	COMMON_STAR_GREY_L_ICO                   = _res("ui/common/common_star_grey_l_ico.png"),
	TOWER_BTN_QUIT                           = _res("ui/common/tower_btn_quit.png")

}
local BAR_DEFIN_TABLE = {
	DEV = {
		FREE_DEV          = 1, -- 自由调试
		FORMULA_DEV       = 2, --配方调试
		FORMULA_BATCH_DEV = 3  --批量开发
	},

	EVENT = {
		ADD_MATERIAL_EVENT                 = "ADD_MATERIAL_EVENT",
		ADD_MATERIAL_CALLBACK_EVENT        = "ADD_MATERIAL_CALLBACK_EVENT",
		REDUCE_MATERIAL_EVENT              = "REDUCE_MATERIAL_EVENT",
		CHANGE_MATERIAL_POS_EVENT          = "CHANGE_MATERIAL_POS_EVENT",
		CHANGE_MATERIAL_POS_CALLBACK_EVENT = "CHANGE_MATERIAL_POS_CALLBACK_EVENT",
		MATERIAL_CHANGE_EVENT              = "MATERIAL_CHANGE_EVENT",
		CHANGE_BATCH_NUM_EVENT              = "CHANGE_BATCH_NUM_EVENT",
	},
	METHOD = {
		BUILD_METHOD   = 1,  -- 兑和法
		SHAKING_METHOD = 2,  -- 摇和法
		MIX_METHOD     = 3,  -- 搅合法
	},
	MAX_MATERIAL_NUM = 10  , -- 消耗材料最多
	HISHEST_STAR = 3  , -- 最高星级
}

local BUTTON_TAG = {
	BUILD_METHOD   = 1, -- 兑和法
	SHAKING_METHOD = 2, -- 摇和法
	MIX_METHOD     = 3, -- 搅合法
	--------------------------------------
	LEFT_SWITH         = 1001,
	RIGHT_SWITH        = 1002,
	MAKE_BTN           = 1003,
	LOOK_BATCH_FORMULA = 1004, -- 查看配方
	LOOK_BACK          = 1005, -- 回头客
	SUPPLIER           = 1006, -- 供应商
	CLEAR_ALL          = 1007, -- 一键清空
}

function WaterBarDeployFormulaView:ctor(args)
	self:CreateCenterLayout()
end
function WaterBarDeployFormulaView:CreateCenterLayout()
	local colorView = display.newLayer(display.cx , display.cy , {ap = display.CENTER ,  color = cc.c4b(0,0,0,175), enable = true})
	self:addChild(colorView)
	local centerSize = cc.size(1144,623)
	local centerLayout = display.newLayer(display.cx , display.cy  + 9 ,{ap = display.CENTER,size = cc.size(1144,623)})
	self:addChild(centerLayout)
	local swallowCenterLayer = display.newLayer(centerSize.width/2 , centerSize.height/2 , {color = cc.c4b(0,0,0,0) ,  ap = display.CENTER, enable = true , size = centerSize})
	centerLayout:addChild(swallowCenterLayer)
	local centerBgImage = display.newImageView( RES_DICT.BAR_BARTENDING_BG ,572, 311.5,{ap = display.CENTER})
	centerLayout:addChild(centerBgImage)
	local centerLineImage = display.newImageView( RES_DICT.BAR_BARTENDING_BG_LIST ,471, 311.5,{ap = display.CENTER})
	centerLayout:addChild(centerLineImage)
	local rightLayout = display.newLayer(470, 0 ,{ap = display.LEFT_BOTTOM,size = cc.size(674,623)})
	centerLayout:addChild(rightLayout)
	local wareBgImage = display.newImageView( RES_DICT.GOLD_TRADE_WARE_BG_LISTDI_FRONT ,314, 381.5,{ap = display.CENTER})
	rightLayout:addChild(wareBgImage)
	local attractCardTitle = display.newButton(318, 505.5 , {n = RES_DICT.COMMON_TITLE_5,s = RES_DICT.COMMON_TITLE_5,d = RES_DICT.COMMON_TITLE_5,ap = display.CENTER})
	rightLayout:addChild(attractCardTitle)
	display.commonLabelParams(attractCardTitle ,{fontSize = 24,text = __('选择手法'),color = '#5b3c25'})
	local rightTopImage = display.newImageView( RES_DICT.COMMON_TIPS_LINE ,325, 538.5,{ap = display.CENTER})
	rightLayout:addChild(rightTopImage)
	local methodTable = {
		{ text = __('兑和法'), img = RES_DICT.BAR_BARTENDING_ICON_RECONCILIATION, tag = BUTTON_TAG.BUILD_METHOD , idle = "idle" , play = "play1"  },
		{ text = __('摇和法'), img = RES_DICT.BAR_BARTENDING_ICON_SHAKE, tag = BUTTON_TAG.SHAKING_METHOD , idle = "play1" , play = "play2" },
		{ text = __('搅和法'), img = RES_DICT.BAR_BARTENDING_ICON_STIR, tag = BUTTON_TAG.MIX_METHOD ,  idle = "idle" , play = "play" },
	}
	local methodUITable ={}
	for i = 1 , #methodTable do
		local methodLayout = display.newButton(320 + (i - 0.5 - (2-0.5)) * 190 , 362,{ enable =true ,  ap = display.CENTER,size = cc.size(172,239)})
		rightLayout:addChild(methodLayout)
		local bgImage = display.newImageView( RES_DICT.BAR_BARTENDING_BG_CHOICE ,86, 119.5,{enable = true , ap = display.CENTER})
		methodLayout:addChild(bgImage)
		methodLayout:setTag(methodTable[i].tag)
		local iconImage = display.newImageView(methodTable[i].img ,86 , 138.5 )
		methodLayout:addChild(iconImage,10)
		local selectImage = display.newImageView(RES_DICT.BAR_BARTENDING_BG_CHOICE_SELECTED , 86, 118.5, {ap = display.CENTER})
		methodLayout:addChild(selectImage)
		selectImage:setVisible(false)
		local makeMethodName = display.newLabel(86, 37.5 , {fontSize = 24,ttf = true,font = TTF_GAME_FONT,outlineSize = 1,text = methodTable[i].text,color = '#b58a79'})
		methodLayout:addChild(makeMethodName)
		methodUITable[#methodUITable+1] = {
			bgImage        = bgImage,
			iconImage      = iconImage,
			selectImage    = selectImage,
			makeMethodName = makeMethodName,
			methodLayout   = methodLayout
		}
	end
	local rightBottomlineImage = display.newImageView( RES_DICT.COMMON_TIPS_LINE ,314, 220.5,{ap = display.CENTER})
	rightLayout:addChild(rightBottomlineImage)

	local leftSwitchBtn = display.newImageView( RES_DICT.BAR_BARTENDING_BTN_LEFT ,196, 564.5,{ap = display.CENTER , enable = true })
	rightLayout:addChild(leftSwitchBtn)
	leftSwitchBtn:setTag(BUTTON_TAG.LEFT_SWITH)
	local rightSwitchBtn = display.newImageView( RES_DICT.BAR_BARTENDING_BTN_RIGHT ,434, 567.5,{ap = display.CENTER , enable = true })
	rightLayout:addChild(rightSwitchBtn)
	rightSwitchBtn:setTag(BUTTON_TAG.RIGHT_SWITH)
	local modeText = display.newLabel(320, 566.5 , {fontSize = 24,ttf = true,font = TTF_GAME_FONT,outlineSize = 1,text = __('自由模式'),color = '#323232'})
	rightLayout:addChild(modeText)
	self.viewData = {
		centerLayout              = centerLayout,
		centerBgImage             = centerBgImage,
		centerLineImage           = centerLineImage,
		rightLayout               = rightLayout,
		wareBgImage               = wareBgImage,
		attractCardTitle          = attractCardTitle,
		rightTopImage             = rightTopImage,
		methodUITable             = methodUITable ,
		rightBottomlineImage      = rightBottomlineImage,
		leftSwitchBtn             = leftSwitchBtn,
		rightSwitchBtn           = rightSwitchBtn,
		modeText                  = modeText,
		colorView                 = colorView,
	}
end
function WaterBarDeployFormulaView:CreateFormulaLayout(formulaId)
	local formulaLayout = display.newLayer(250, 264.5  ,{ap = display.CENTER,size = cc.size(436,656.95)})
	self.viewData.centerLayout:addChild(formulaLayout)
	local formulaLayoutSize = formulaLayout:getContentSize()
	local leftSwallowLayout = display.newLayer(0,0, {color = cc.c4b(0,0,0,0) , size =cc.size(436,656.95) })
	formulaLayout:addChild(leftSwallowLayout)
	local bgImage = display.newImageView( RES_DICT.BAR_BARTENDING_BG1 ,218, 395,{ap = display.CENTER})
	formulaLayout:addChild(bgImage)
	local tipBtn = display.newButton(45 , formulaLayoutSize.height -35 ,{n = RES_DICT.COMMON_BTN_TIPS} )
	formulaLayout:addChild(tipBtn , 20 )
	display.commonUIParams( tipBtn, {cb = function(sender)
		 app.uiMgr:ShowIntroPopup({moduleId = "-63" })
	end})
	--bgImage:setVisible(false)
	local drinkInfoLayout = display.newLayer(16.94998, 277.85 ,{ap = display.LEFT_BOTTOM,size = cc.size(395.7,262.3)})
	formulaLayout:addChild(drinkInfoLayout)
	local infoBgImage = display.newImageView( RES_DICT.COMMON_BG_GOODS_3 ,200, 131.15,{ap = display.CENTER,scale9 = true,size = cc.size(390 , 262.3)})
	drinkInfoLayout:addChild(infoBgImage)
	local lineImage = display.newImageView( RES_DICT.COMMON_TIPS_LINE ,197.85, 133.15,{ap = display.CENTER,scaleX = 0.7})
	drinkInfoLayout:addChild(lineImage)
	local attractCardTitle = display.newButton(197.85, 110.15 , {n = RES_DICT.COMMON_TITLE_5,s = RES_DICT.COMMON_TITLE_5,d = RES_DICT.COMMON_TITLE_5,ap = display.CENTER})
	drinkInfoLayout:addChild(attractCardTitle)
	display.commonLabelParams(attractCardTitle ,{fontSize = 24,
												 text = __('可吸引飨灵'),color = '#5b3c25'})
	local drinkDetailInfoTable = {
		{text = __('饮品券') , img = CommonUtils.GetGoodsIconPathById(FOOD.GOODS.DEFINE.WATER_BAR_CURRENCY_ID) , scale = 0.2 },
		{text = __('酒吧知名度') , img = CommonUtils.GetGoodsIconPathById(FOOD.GOODS.DEFINE.WATER_BAR_POPULARITY_ID) , scale = 0.2 },
		{text = __('熟客值') , img = CommonUtils.GetGoodsIconPathById(FOOD.GOODS.DEFINE.WATER_BAR_FREQUENCY_ID) , scale = 0.2 }
	}
	local buyInfoTable = {}
	for i =1 , #drinkDetailInfoTable do
		local buyInfo = display.newLayer(47.5, 223-(i-1)*39 ,{ap = display.LEFT_BOTTOM,size = cc.size(309,30)})
		drinkInfoLayout:addChild(buyInfo)
		local buyBgImage = display.newImageView( RES_DICT.MARKET_BUY_BG_INFO ,154.5, 15,{ap = display.CENTER,scale9 = true,size = cc.size(309 , 30)})
		buyInfo:addChild(buyBgImage)
		local iconImage = display.newImageView( drinkDetailInfoTable[i].img ,2.5, 15,{ap = display.CENTER,scale = 0.2 })
		buyInfo:addChild(iconImage)
		local priceLabel = display.newLabel(296, 15 , {ap = display.RIGHT_CENTER ,  fontSize = 24,text = '',color = '#5C5B57'})
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
	local needFoodLayout = display.newLayer(16.94998, 147 ,{ap = display.LEFT_BOTTOM,size = cc.size(395.7,120)})
	formulaLayout:addChild(needFoodLayout)

	local cardLayout = display.newLayer(200, 45 ,{ap = display.CENTER,size = cc.size(100,100)})
	drinkInfoLayout:addChild(cardLayout)

	local needBgImage = display.newImageView( RES_DICT.COMMON_BG_GOODS_3 ,200, 65,{ap = display.CENTER,scale9 = true,size = cc.size(390 , 120)})
	needFoodLayout:addChild(needBgImage)
	local needFoodTitle = display.newButton(197.85, 110 , {n = RES_DICT.COMMON_TITLE_5,s = RES_DICT.COMMON_TITLE_5,d = RES_DICT.COMMON_TITLE_5,ap = display.CENTER})
	needFoodLayout:addChild(needFoodTitle)
	display.commonLabelParams(needFoodTitle ,{fontSize = 24,text = __('所需食材'),color = '#5b3c25'})
	local goodsLayout = display.newLayer(200, 50 ,{ap = display.CENTER,size = cc.size(100,100)})
	needFoodLayout:addChild(goodsLayout)

	local drinkCircleImage = display.newImageView( RES_DICT.KITCHEN_BG_FOOD_QUAN ,135, 595,{ap = display.CENTER,scaleX = 0.65,scaleY = 0.65})
	formulaLayout:addChild(drinkCircleImage)
	local drinkImage = display.newImageView( RES_DICT.GOODS_ICON_880190 ,135, 595,{ap = display.CENTER,scaleX = 0.65,scaleY = 0.65})
	formulaLayout:addChild(drinkImage)
	local drinkName = display.newLabel(271, 615 , {fontSize = 28,ttf = true,font = TTF_GAME_FONT,outlineSize = 1,text = '',color = '#ba5c5c'})
	formulaLayout:addChild(drinkName)
	local drinkStarLayout = display.newLayer(271, 570 ,{ap = display.CENTER,size = cc.size(120,40)})
	formulaLayout:addChild(drinkStarLayout)
	local starTables = {}
	local width = 40
	for i = 1, 3 do
		local img = display.newImageView( RES_DICT.BAR_SHOP_ICON_RANK ,width*(i-0.5), width/2)
		drinkStarLayout:addChild(img)
		starTables[#starTables+1] = img
	end

	local formulaConf = CONF.BAR.FORMULA:GetValue(formulaId)
	local goodsData = string.split(formulaConf.showMaterialOrder , ";")
	---@type table<string,table<string , WaterBarMaterialCell>>
	local materialTable = {}
	local count = #goodsData
	local width = 100
	local height = 100
	local goodSize = cc.size(count * width ,  height)
	goodsLayout:setContentSize(goodSize)
	for i =1 , count do
		local goodNode = require("common.GoodNode").new({
			goodsId =  goodsData[i] , num = 0  , showAmount = true
		})
		goodNode:setTag(checkint(goodsData[i]))
		goodNode:setAnchorPoint(display.CENTER)
		goodNode:setPosition((i - 0.5) * width ,height /2)
		goodsLayout:addChild(goodNode)
		goodNode:setScale(0.75)
		materialTable[tostring(goodsData[i])] = {
			materialNode = goodNode  ,
			materialId =  goodsData[i]
		}
		display.commonUIParams(goodNode, { animate = false ,   cb = function(sender)
			app:DispatchObservers(BAR_DEFIN_TABLE.EVENT.ADD_MATERIAL_EVENT , { materialId = sender:getTag()})
		end})
	end

	local customerLikeTable = app.waterBarMgr:GetCustomersLikeFormulaByFormulaId(formulaId)
	local count = #customerLikeTable
	local width = 100
	local height = 100
	local cardSize = cc.size(count * width ,  height)
	cardLayout:setContentSize(cardSize)
	if count == 0 then
		cardLayout:addChild(display.newLabel(cardSize.width/2 , cardSize.height/2 , fontWithColor(14, { outline = false , fontSize = 30 ,color = "#ba5c5c",outlineSize = 2,text = __('暂无可吸引的飨灵')})))
	end

	for i =1 , count do
		local cardNode = require("common.GoodNode").new({goodsId =customerLikeTable[i]})
		cardNode:setPosition((i - 0.5) * width ,height /2)
		cardNode:setScale(0.75)
		cardLayout:addChild(cardNode)
		local likeIcon = display.newImageView(RES_DICT.BAR_SHOP_ICON_FREQUENTER ,0 , 0 , {ap = display.LEFT_BOTTOM}  )
		cardNode:addChild(likeIcon,20)
	end

	self.formulaViewData= {
		formulaLayout    = formulaLayout ,
		bgImage          = bgImage,
		cardLayout       = cardLayout,
		goodsLayout      = goodsLayout,
		drinkInfoLayout  = drinkInfoLayout,
		infoBgImage      = infoBgImage,
		lineImage        = lineImage,
		attractCardTitle = attractCardTitle,
		needFoodLayout   = needFoodLayout,
		needBgImage      = needBgImage,
		needFoodTitle    = needFoodTitle,
		drinkCircleImage = drinkCircleImage,
		drinkImage       = drinkImage,
		drinkName        = drinkName,
		drinkStarLayout  = drinkStarLayout,
		buyInfoTable     = buyInfoTable,
		materialTable    = materialTable,
		tipBtn           = tipBtn,
		starTables       = starTables
	}
end


function WaterBarDeployFormulaView:CreateBatachLayout()
	local batchLayout = display.newLayer(25.94998, 89.95499 ,{ap = display.LEFT_BOTTOM,size = cc.size(585.7,127.05)})
	self.viewData.rightLayout:addChild(batchLayout)
	local chooseNumTitle = display.newButton(292.05, 111.525 , {n = RES_DICT.COMMON_TITLE_5,s = RES_DICT.COMMON_TITLE_5,d = RES_DICT.COMMON_TITLE_5,ap = display.CENTER})
	batchLayout:addChild(chooseNumTitle)
	display.commonLabelParams(chooseNumTitle ,{fontSize = 24,text = __('选择数量'),color = '#5b3c25'})
	local bgImage = display.newImageView( RES_DICT.COMMON_BG_GOODS_3 ,292.8475, 44.325,{ap = display.CENTER,scale9 = true,size = cc.size(585.7 , 85)})
	batchLayout:addChild(bgImage)
	local makeNumBg = display.newImageView( RES_DICT.MARKET_CHOICE_BG_PRIZCE ,292.8475, 44.325,{
		ap = display.CENTER , enable = true , animate = false ,
		cb = handler(self , self.InputBatchNumClick)
	})
	makeNumBg:setScaleX(0.62)
	batchLayout:addChild(makeNumBg)
	local makeNum = display.newLabel(292.85, 44.525 , {fontSize = 24,outlineSize = 1,text = '',color = '#5b3c12'})
	batchLayout:addChild(makeNum)
	display.commonLabelParams(makeNum , {text = "1"})
	local addBtn = display.newImageView( RES_DICT.MARKET_SOLD_BTN_PLUS ,369.85, 44.325,{
		ap = display.CENTER , enable = true ,
		cb = handler(self , self.AddBatchNumClick)
	})
	batchLayout:addChild(addBtn)
	local reduceBtn = display.newImageView( RES_DICT.MARKET_SOLD_BTN_SUB ,211.85, 44.325,{
		ap = display.CENTER, enable = true,
		cb = handler(self , self.ReduceBatchNumClick)
	})
	batchLayout:addChild(reduceBtn)
	self.batchViewData = {
		batchLayout    = batchLayout,
		makeNum        = makeNum,
		makeNumBg      = makeNumBg,
		chooseNumTitle = chooseNumTitle,
		addBtn         = addBtn,
		reduceBtn      = reduceBtn
	}
end
function WaterBarDeployFormulaView:CreateMixRatioLayout(formulaId)
	local ratioLayout = display.newLayer(25.94998, 89.95499 ,{ap = display.LEFT_BOTTOM,size = cc.size(585.7,127.05)})
	self.viewData.rightLayout:addChild(ratioLayout)
	local chooseNumTitle = display.newButton(292.05, 115.525 , {n = RES_DICT.COMMON_TITLE_5,s = RES_DICT.COMMON_TITLE_5,d = RES_DICT.COMMON_TITLE_5,ap = display.CENTER})
	ratioLayout:addChild(chooseNumTitle)
	display.commonLabelParams(chooseNumTitle ,{fontSize = 24,outlineSize = 1,text = __('推荐比例'),color = '#5b3c25'})
	local bgSize =  cc.size(585.7 , 91)
	local bgImage = display.newImageView( RES_DICT.COMMON_BG_GOODS_3 ,292.8475, 63,{ap = display.CENTER,scale9 = true,size = cc.size(585.7  , 65)})
	ratioLayout:addChild(bgImage)
	local ratioLayoutSize = ratioLayout:getContentSize()
	local recommonLabel = display.newLabel(ratioLayoutSize.width/2 , 10 , {text = __("推荐比例：此处比例对应食材需自行尝试") , fontSize = 20 ,color = "#432323"})
	ratioLayout:addChild(recommonLabel)
	local formulaConf = CONF.BAR.FORMULA:GetValue(formulaId)
	local matching = formulaConf.matching or {}
	local totalWidth = 0
	local imageTable = {}
	for i =1 , #matching do
		local num = matching[i]
		totalWidth = totalWidth+10
		local imageOne = display.newImageView(_res(string.format('ui/waterBar/mixedDrink/bar_bartending_tips_%d' , checkint(num))) ,totalWidth , 30 ,{ap = display.LEFT_CENTER} )
		local imageOneSize = imageOne:getContentSize()
		imageTable[i] = imageOne
		totalWidth = totalWidth + imageOneSize.width
		totalWidth = totalWidth +10
		for index = 1, num do
			local image = display.newImageView(_res('ui/waterBar/mixedDrink/bar_bartending_bar_active_tips'  ) , imageOneSize.width/2+ ((index -0.5) - (num/2))* 50 ,  28 )
			imageOne:addChild(image)
		end
		local imageStr = display.newLabel(imageOneSize.width/2 , 10 , fontWithColor(14, {ap = display.CENTER_TOP ,fontSize = 28, text = num }))
		imageOne:addChild(imageStr)
	end
	local imageLayout = display.newLayer(bgSize.width/2,bgSize.height/2+5 , { ap = display.CENTER ,  size = cc.size(totalWidth , 40 ) })
	for i =1 , #imageTable do
		imageLayout:addChild(imageTable[i])
	end
	ratioLayout:addChild(imageLayout)
	self.ratioLayoutData = {
		ratioLayout = ratioLayout ,
	}
end
function WaterBarDeployFormulaView:CreateBottomLayout()
	local bottomLayout = display.newLayer(display.cx + -1, display.cy  + -273 ,{ ap = display.CENTER, size = cc.size(1376,203)})
	self:addChild(bottomLayout)
	local bottomSwallowLayer = display.newLayer(1376 /2 , 0 , {ap = display.CENTER_BOTTOM ,  size = cc.size(1376,160) , color = cc.c4b(0,0,0,0) , enable = true })
	bottomLayout:addChild(bottomSwallowLayer)
	local bottomImage  = display.newImageView( RES_DICT.BAR_BARTENDING_BG2 ,688, 101.5,{ap = display.CENTER})
	bottomLayout:addChild(bottomImage)

	local clearAllBtn = display.newButton(1272, 150 , {n = RES_DICT.BAR_BARTENDING_BTN_RESET,s = RES_DICT.BAR_BARTENDING_BTN_RESET,d = RES_DICT.BAR_BARTENDING_BTN_RESET,ap = display.CENTER})
	bottomLayout:addChild(clearAllBtn)
	display.commonLabelParams(clearAllBtn , {fontSize = 24,text = __('重置'),color = '#ffffff' , offset = cc.p(0,-30)})
	clearAllBtn:setTag(BUTTON_TAG.CLEAR_ALL)

	local makeBtn = display.newButton(1272, 71.5 , {n = RES_DICT.COMMON_BTN_ORANGE,s = RES_DICT.COMMON_BTN_ORANGE,d = RES_DICT.COMMON_BTN_ORANGE,ap = display.CENTER})
	bottomLayout:addChild(makeBtn)
	display.commonLabelParams(makeBtn ,fontWithColor(14 , {fontSize = 24,text = __('开始调制'),color = '#ffffff'}))
	makeBtn:setTag(BUTTON_TAG.MAKE_BTN)
	local operatorLayout = display.newLayer(688, 85.5 ,{ap = display.CENTER,size = cc.size(1050,140)})
	bottomLayout:addChild(operatorLayout)
	local prograssTable = {}
	local materFrameTable ={}
	local imageSize = cc.size(97.5 , 97.5)
	local reduceTable = {}
	for i = 1, 10 do
		local imageLayout = display.newLayer(80+ 97.5*(i -1), 53 , {ap = display.CENTER ,size = imageSize})
		operatorLayout:addChild(imageLayout)
		local imageOne = display.newImageView( RES_DICT.BAR_FRAME_BG ,imageSize.width/2, imageSize.height/2,{ap = display.CENTER})
		local clickLayer = display.newLayer( 97.5/2, 97.5/2 ,{color =cc.c4b(0,0,0,0), enable = true ,  ap = display.CENTER})
		imageLayout:addChild(clickLayer)
		imageLayout:addChild(imageOne)
		materFrameTable[#materFrameTable+1] = {
			imageLayout = imageLayout ,
			clickLayer = clickLayer ,
			imageOne = imageOne
		}
	end
	local width =  97.5
	local pos = cc.p(80+ width*(5 - 1) , 53 )
	local num = 3
	local addMaterialLayoutWidth = width * num + 80
	local addMaterialLayout = display.newLayer(pos.x , pos.y  ,{ap = display.CENTER })
	operatorLayout:addChild(addMaterialLayout,20)
	local swallowAddMaterialLayout =  display.newButton(0,0 ,{ap = display.CENTER , enable = true  })
	addMaterialLayout:addChild(swallowAddMaterialLayout)
	addMaterialLayout:setTag(0)
	local selectMaterialImage = display.newButton( addMaterialLayoutWidth/2 , 70,{n = RES_DICT.BAR_BARTENDING_CONTENT_SELECTED  ,  ap = display.CENTER,scale9 = true,size = cc.size(97.5 * num + 20, 120)})
	addMaterialLayout:addChild(selectMaterialImage)

	local leftBtn = display.newButton( 20, 70,{n = RES_DICT.BAR_BARTENDING_SELECTED_LEFT ,  ap = display.CENTER , enable = true , cb = handler( self , self.MoveLeftClick)
	})
	addMaterialLayout:addChild(leftBtn,2)
	local rightBtn = display.newButton(addMaterialLayoutWidth -22, 70,{n =  RES_DICT.BAR_BARTENDING_SELECTED_RIGHT ,  ap = display.CENTER , enable = true , cb = handler( self , self.MoveRightClick)})
	addMaterialLayout:addChild(rightBtn,2)
	addMaterialLayout:setVisible(false)
	local lookRecordBtn = display.newImageView( RES_DICT.BAR_BARTENDING_ICON_RECORDS ,100, 89.5,{ap = display.CENTER , enable =true })
	bottomLayout:addChild(lookRecordBtn)
	local lookTitle = display.newButton(66, -3 , {n = RES_DICT.TOWER_BTN_QUIT,s = RES_DICT.TOWER_BTN_QUIT,d = RES_DICT.TOWER_BTN_QUIT, enable =true ,  ap = display.CENTER})
	lookRecordBtn:addChild(lookTitle)
	display.commonLabelParams(lookTitle ,{fontSize = 24,ttf = true,font = TTF_GAME_FONT,outlineSize = 2,text = __('查看记录'),color = '#ffffff'})
	lookRecordBtn:setTag(BUTTON_TAG.LOOK_BATCH_FORMULA)
	self.bottomViewData = {
		bottomLayout         	  = bottomLayout,
		bottomImage               = bottomImage,
		makeBtn                   = makeBtn,
		operatorLayout            = operatorLayout,
		addMaterialLayout         = addMaterialLayout,
		selectMaterialImage       = selectMaterialImage,
		leftBtn                   = leftBtn,
		rightBtn                  = rightBtn,
		lookRecordBtn             = lookRecordBtn,
		materFrameTable           = materFrameTable,
		reduceTable               = reduceTable,
		swallowAddMaterialLayout  = swallowAddMaterialLayout,
		prograssTable             = prograssTable,
		clearAllBtn               = clearAllBtn ,
		lookTitle                 = lookTitle
	}
end
function WaterBarDeployFormulaView:CreateTipButton()
	local tipBgButton = display.newButton(0,0, {n = RES_DICT.BAR_TIPS_MSG , ap = display.LEFT_TOP , scale9 = true  })
	display.commonLabelParams(tipBgButton , {text = __('选择所需食材进行配比调制') ,offset = cc.p(0, -10), fontSize = 22 , color = "#ffffff", paddingW = 30 , safeW = 300 })
	local bottomLayout = self.bottomViewData.bottomLayout
	local bottomLayoutSize = bottomLayout:getContentSize()
	tipBgButton:setPosition(bottomLayoutSize.width/2 -390, bottomLayoutSize.height -70)
	bottomLayout:addChild(tipBgButton)
	tipBgButton:setName("tipBgButton")
	return tipBgButton
end
function WaterBarDeployFormulaView:CreateFreeLayout()
	local freeLayout = display.newLayer(45, 587.5 ,{ap = display.LEFT_TOP,size = cc.size(420,530)})
	self.viewData.centerLayout:addChild(freeLayout)
	local bgImage = display.newImageView( RES_DICT.BAR_BARTENDING_BG1 ,205, 275,{ap = display.CENTER})
	freeLayout:addChild(bgImage)
	local grideBgImage = display.newImageView( RES_DICT.COMMON_BG_GOODS_3 ,205, 275,{ap = display.CENTER,scale9 = true,size = cc.size(390 , 485)})
	freeLayout:addChild(grideBgImage)
	local materialGrideView = CGridView:create(cc.size(387.8, 475))
	materialGrideView:setSizeOfCell(cc.size(97 , 97 ))
	materialGrideView:setColumns(4)
	materialGrideView:setAutoRelocate(true)
	materialGrideView:setAnchorPoint(display.CENTER)
	materialGrideView:setPosition(204.4 , 274)
	freeLayout:addChild(materialGrideView)
	self.freeViewData = {
		freeLayout        = freeLayout,
		bgImage           = bgImage,
		materialGrideView = materialGrideView,
		grideBgImage      = grideBgImage,
	}
end

----=======================----
--@author : xingweihao
--@date : 2020/2/25 4:24 PM
--@Description 更新选中的材质框
--@params
--@return
---=======================----
function WaterBarDeployFormulaView:UpdateAddMaterialLayout(startIndex , num)
	local width = 97.5
	local bottomViewData = self.bottomViewData
	local startPosX = bottomViewData.materFrameTable[startIndex].imageLayout:getPositionX()
	local endPosX = bottomViewData.materFrameTable[(startIndex + num -1) ].imageLayout:getPositionX()
	local centerPosX = (startPosX +endPosX) /2
	local addMaterialLayoutWidth  = width * num + 80
	bottomViewData.addMaterialLayout:setContentSize(cc.size(addMaterialLayoutWidth , 140))
	bottomViewData.swallowAddMaterialLayout:setContentSize(cc.size(addMaterialLayoutWidth , 140))
	bottomViewData.swallowAddMaterialLayout:setPosition(addMaterialLayoutWidth , 70 )
	bottomViewData.addMaterialLayout:setPositionX(centerPosX)
	bottomViewData.leftBtn:setPositionX(20)
	bottomViewData.rightBtn:setPositionX(addMaterialLayoutWidth -22)
	bottomViewData.selectMaterialImage:setContentSize(cc.size(width * num +20 , 120) )
	bottomViewData.selectMaterialImage:setPositionX(addMaterialLayoutWidth/2)
end



function WaterBarDeployFormulaView:UpdateFormulaView(data)
	local formulaId = data.formulaId
	local formulaConf = CONF.BAR.FORMULA:GetValue(formulaId)
	local viewData = self.formulaViewData
	viewData.drinkImage:setTexture(CommonUtils.GetGoodsIconPathById(formulaId))
	display.commonLabelParams(viewData.drinkName , {text = formulaConf.name})
	local num = data.highStar
	if num > 0  then
		local drinkConf = CONF.BAR.DRINK:GetValue(formulaConf.drinks[data.highStar +1])
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
function WaterBarDeployFormulaView:UpdateTipButton(consumeMaterialTable, dev)
	local isHaveNoMaterial = true
	dev = checkint(dev)
	for index, materialData in pairs(consumeMaterialTable) do
		if checkint(materialData.materialId) > 0 and checkint(materialData.num)> 0 then
			isHaveNoMaterial = false
			break
		end
	end
	local tipBgButton = self.bottomViewData.bottomLayout:getChildByName("tipBgButton")
	if isHaveNoMaterial then
		if not tipBgButton then
			tipBgButton = self:CreateTipButton()
		end
		tipBgButton:setVisible(true)
		if dev == BAR_DEFIN_TABLE.DEV.FORMULA_BATCH_DEV then
			display.commonLabelParams(tipBgButton , {text =__('选择相应配方记录进行批量调制') , paddingW = 30 , safeW = 300,offset = cc.p(0, -10)  })
		else
			display.commonLabelParams(tipBgButton , {text =__('选择所需食材进行配比调制') , paddingW = 30 , safeW = 300 ,offset = cc.p(0, -10)})
		end
	else
		if tipBgButton then
			tipBgButton:setVisible(false)
		end
	end
end
function WaterBarDeployFormulaView:UpdateBottomMaterialView(consumeMaterialTable,formulaDev )
	local viewData = self.bottomViewData
	local count = 1
	local startEndTable = {
		{startPos = 0 , length = 0 , grepLength = 0 } ,
		{startPos = 0 , length = 0 , grepLength = 0 },
		{startPos = 0 , length = 0 , grepLength = 0 },
		{startPos = 0 , length = 0 , grepLength = 0 }
	}
	self:UpdateTipButton(consumeMaterialTable ,formulaDev )
	for index , v in pairs(consumeMaterialTable) do
		if checkint(v.num)  > 0  then
			startEndTable[index].startPos = checkint(count)
			startEndTable[index].length   = checkint(v.num)
			count = count + v.num
			local materialNum = waterBarMgr:getMaterialNum(v.materialId)
			if materialNum < count then startEndTable[index].grepLength = v.num - materialNum end
		end
	end

	for i = 1, #startEndTable do
		if startEndTable[i].length > 0  then
			local oneData =  startEndTable[i]
			local startPosOne = oneData.startPos
			local endPosOne  = oneData.startPos + oneData.length - 1
			local consumeOneData = consumeMaterialTable[i]
			local index = 0
			for startPos = startPosOne , endPosOne do
				index = index +1
				local materialTable = viewData.materFrameTable[startPos]
				if materialTable then
					local materialIcon =  materialTable.materialIcon
					if not materialIcon then
						materialIcon = FilteredSpriteWithOne:create(CommonUtils.GetGoodsIconPathById(consumeOneData.materialId))
						materialIcon:setPosition(97.5/2 , 97.5/2)
						materialIcon:setScale(0.5)
						materialTable.materialIcon = materialIcon
						materialTable.imageLayout:addChild(materialIcon)
						display.commonUIParams(materialTable.clickLayer , {cb = function(sender)
							app:DispatchObservers(BAR_DEFIN_TABLE.EVENT.CHANGE_MATERIAL_POS_EVENT , {materialId = sender:getTag()})
						end})
					end
					if index <=  oneData.grepLength  then
						local grayFilter = GrayFilter:create()
						materialIcon:setFilter(grayFilter)
					else
						materialIcon:clearFilter()
					end
					materialIcon:setTexture(CommonUtils.GetGoodsIconPathById(consumeOneData.materialId))
					materialIcon:setVisible(true)
					materialTable.clickLayer:setVisible(true)
					materialTable.clickLayer:setTag(checkint(consumeOneData.materialId))
				end
			end
		end
	end
	-- 处理去除材料的显示
	for i = 1, count - 1 do
		local reduceIcon = viewData.reduceTable[i]
		if formulaDev == BAR_DEFIN_TABLE.DEV.FORMULA_BATCH_DEV then
			if reduceIcon then
				reduceIcon:setVisible(false)
			end
		else
			if reduceIcon then
				reduceIcon:setVisible(true)
			else
				local reduceIcon = display.newImageView(RES_DICT.BAR_BTN_SUBTRACTED , 40+ 97.5*i, 120 , {ap = display.RIGHT_TOP , scale = 0.8  ,enable = true  })
				viewData.operatorLayout:addChild(reduceIcon,20)
				viewData.reduceTable[i] = reduceIcon
				reduceIcon:setTag(i)
				display.commonUIParams(reduceIcon , {animate = false ,  cb = function(sender)
					local index = sender:getTag()
					local clickLayer =  viewData.materFrameTable[index].clickLayer
					app:DispatchObservers(BAR_DEFIN_TABLE.EVENT.REDUCE_MATERIAL_EVENT , {materialId = clickLayer:getTag()})
				end})
			end
		end
	end

	for i = count ,BAR_DEFIN_TABLE.MAX_MATERIAL_NUM  do
		local materialTable = viewData.materFrameTable[i]
		local materialIcon =  materialTable.materialIcon
		if materialIcon then
			materialIcon:setVisible(false)
		end
		local clickLayer =  materialTable.clickLayer
		clickLayer:setVisible(false)
		local reduceIcon = viewData.reduceTable[i]
		if reduceIcon then
			reduceIcon:setVisible(false)
		end
	end

	-- 更新显示材料比例
	for i = 1, #startEndTable do
		local pos = (startEndTable[i].startPos + startEndTable[i].startPos + startEndTable[i].length -1)/2
		local oneData =  startEndTable[i]

		local prograss = nil
		if not  viewData.prograssTable[i] then
			prograss = display.newButton(0,0 , {n = RES_DICT.BAR_BARTENDING_BAR_ACTIVE,d = RES_DICT.BAR_BARTENDING_BAR_ACTIVE1 ,  ap = display.CENTER,scale9 = true})
			viewData.operatorLayout:addChild(prograss)
			viewData.prograssTable[#viewData.prograssTable+1] = prograss
		else
			prograss = viewData.prograssTable[i]
		end
		prograss:setPosition( 97.5*pos -17, 125)
		prograss:setContentSize(cc.size( 97.5* startEndTable[i].length , 24 ))
		if  oneData.grepLength > 0   then
			prograss:setEnabled(false)
		else
			prograss:setEnabled(true)
		end
		display.commonLabelParams(prograss ,{fontSize = 20  ,  text = startEndTable[i].length} )
		if startEndTable[i].length == 0  then
			prograss:setVisible(false)
		else
			prograss:setVisible(true)
		end
	end
	local index = 0
	local materialId =viewData.addMaterialLayout:getTag()
	if materialId > 0  then
		for i, v in pairs(consumeMaterialTable) do
			if materialId == checkint(v.materialId) then
				index = i
				break
			end
		end
	end
	if index > 0  then
		self:UpdateAddMaterialLayout(startEndTable[index].startPos ,startEndTable[index].length )
		viewData.addMaterialLayout:setVisible(true)
	else
		viewData.addMaterialLayout:setVisible(false)
	end
end

function WaterBarDeployFormulaView:UpdateGoodLayout(consumeMaterialTable , batchNum)
	local viewData = self.formulaViewData
	for materialId , materialData in pairs(viewData.materialTable) do
		materialId = checkint(materialId)
		local materialNum = waterBarMgr:getMaterialNum(materialId)
		local showMaterialNum = materialNum
		for index , consumeData in pairs(consumeMaterialTable) do
			if checkint(consumeData.materialId) == materialId then
				materialNum = materialNum - consumeData.num  * batchNum
				showMaterialNum = materialNum > 0 and materialNum or  0
				break
			end
		end
		local goodNode = checktable(viewData.materialTable[tostring(materialId)]).materialNode
		if goodNode then
			goodNode:RefreshSelf({
				goodsId = materialId , num = showMaterialNum
			})
			if materialNum >= 0  then
				display.commonLabelParams(goodNode.infoLabel , {color =  "#FFFFFF" , text = showMaterialNum})
			else
				display.commonLabelParams(goodNode.infoLabel , {color =  "#FF0000", text = showMaterialNum})
			end
		end
	end
end

function WaterBarDeployFormulaView:UpdateMethodLayout(method)
	local viewData = self.viewData
	local methodUITable = viewData.methodUITable
	for tag, methodUIData in pairs(methodUITable) do
		methodUIData.selectImage:setVisible(false)
	end
	if checkint(method) > 0 then
		methodUITable[checkint(method)].selectImage:setVisible(true)
	end
end

function WaterBarDeployFormulaView:PlayMakeMethodLayoutAnimate(method , callback)
	method = checkint(method)
	local methodTable = {
		{ text = __('兑和法'), spine = _spnEx('ui/waterBar/mixedDrinkAnimate/bar_bartending_reconciliation'), tag = BUTTON_TAG.BUILD_METHOD , idle = "idle" , play = "play1"  },
		{ text = __('摇和法'), spine = _spnEx('ui/waterBar/mixedDrinkAnimate/bar_bartending_shake'), tag = BUTTON_TAG.SHAKING_METHOD , idle = "play1" , play = "play2" },
		{ text = __('搅和法'), spine = _spnEx('ui/waterBar/mixedDrinkAnimate/bar_bartending_stir'), tag = BUTTON_TAG.MIX_METHOD ,  idle = "idle" , play = "play" },
	}
	local colorView = display.newLayer(display.cx , display.cy , {
		color = cc.c4b(0,0,0,175) ,
		enable = true ,size = display.size,ap = display.CENTER
	})
	self:addChild(colorView , 20)

	local iconImage = sp.SkeletonAnimation:create(methodTable[method].spine.json, methodTable[method].spine.atlas)
	iconImage:setName("iconImage")
	iconImage:setPosition(display.center)
	iconImage:setAnchorPoint(display.CENTER)
	colorView:addChild(iconImage)
	iconImage.play = methodTable[method].play
	iconImage:setAnimation(0, iconImage.play , false)

	colorView:runAction(cc.Sequence:create(
		cc.Spawn:create(
			cc.DelayTime:create(1),
			cc.Sequence:create(
				cc.DelayTime:create(1) ,
				cc.CallFunc:create(callback)
			)
		),
		cc.FadeOut:create(0.2),
		cc.RemoveSelf:create()
	))
end

function WaterBarDeployFormulaView:UpdateBatchNum(batchNum)
	if not self.batchViewData then return end
	local viewData = self.batchViewData
	display.commonLabelParams(viewData.makeNum , {text = batchNum })
end
function WaterBarDeployFormulaView:SetAddMaterialLayoutTag(materialId)
	self.bottomViewData.addMaterialLayout:setTag(materialId)
end

function WaterBarDeployFormulaView:MoveLeftClick()
	local viewData = self.bottomViewData
	local tag  = viewData.addMaterialLayout:getTag()
	app:DispatchObservers(BAR_DEFIN_TABLE.EVENT.CHANGE_MATERIAL_POS_CALLBACK_EVENT , {materialId = tag  , moveIndex =  - 1   })
end

function WaterBarDeployFormulaView:MoveRightClick()
	local viewData = self.bottomViewData
	local tag  = viewData.addMaterialLayout:getTag()
	app:DispatchObservers(BAR_DEFIN_TABLE.EVENT.CHANGE_MATERIAL_POS_CALLBACK_EVENT , {materialId = tag  , moveIndex =  1   })
end

function WaterBarDeployFormulaView:AddBatchNumClick(sender)
	local viewData = self.batchViewData
	local num = viewData.makeNum:getString()
	num = checkint(num) + 1
	self:NumKeyBordCallBackClick(num)
end
function WaterBarDeployFormulaView:ReduceBatchNumClick(sender)
	local viewData = self.batchViewData
	local num = viewData.makeNum:getString()
	num = checkint(num) - 1
	self:NumKeyBordCallBackClick(num)
end
function WaterBarDeployFormulaView:SwitchBtnIsVisible(isVisible)
	local viewData = self.viewData
	local leftSwitchBtn = viewData.leftSwitchBtn
	local rightSwitchBtn = viewData.rightSwitchBtn
	leftSwitchBtn:setVisible(isVisible)
	rightSwitchBtn:setVisible(isVisible)
end
function WaterBarDeployFormulaView:UpdateFomulaDevUI(formulaDev)
	if formulaDev == BAR_DEFIN_TABLE.DEV.FREE_DEV then
		local viewData = self.viewData
		viewData.leftSwitchBtn:setVisible(false)
		viewData.rightSwitchBtn:setVisible(false)
		local bottomViewData = self.bottomViewData
		bottomViewData.lookRecordBtn:setVisible(false)

		display.commonLabelParams(viewData.modeText , {text = __('自由模式')})

		if not self.batchViewData then
			self:CreateBatachLayout()
		end
		local viewData = self.batchViewData
		display.commonLabelParams(viewData.chooseNumTitle , {fontSize = 24,outlineSize = 1,text = __('制作数量'),color = '#5b3c25'})
		viewData.addBtn:setVisible(false)
		viewData.reduceBtn:setVisible(false)
		viewData.makeNumBg:setTouchEnabled(false)
		viewData.makeNumBg:setScale(1)
	elseif formulaDev == BAR_DEFIN_TABLE.DEV.FORMULA_DEV  then
		local viewData = self.viewData
		if self.batchViewData then
			self.batchViewData.batchLayout:setVisible(false)
		end
		self.ratioLayoutData.ratioLayout:setVisible(true)
		display.commonLabelParams(viewData.modeText , {text = __('研发模式')})
	elseif formulaDev == BAR_DEFIN_TABLE.DEV.FORMULA_BATCH_DEV then
		local viewData = self.viewData
		if not self.batchViewData then
			self:CreateBatachLayout()
		end
		self.batchViewData.batchLayout:setVisible(true)
		self.ratioLayoutData.ratioLayout:setVisible(false)
		display.commonLabelParams(viewData.modeText , {text = __('批量模式')})
	end
end

function WaterBarDeployFormulaView:InputBatchNumClick(sender)
	app.uiMgr:ShowNumberKeyBoard(
		{
			nums 			= 3, 				-- 最大输入位数
			model 			= NumboardModel.freeModel, 				-- 输入模式 1为n位密码模式 2为自由模式
			callback 		= handler(self , self.NumKeyBordCallBackClick), 						-- 回调函数 确定之后接收输入字符的处理回调
			titleText 		= __('请输入需要制作饮料的数量'), 					-- 标题
			defaultContent 	= '' 				-- 输入框中默认显示的文字
		}
	)
end

function WaterBarDeployFormulaView:NumKeyBordCallBackClick(num)
	app:DispatchObservers(BAR_DEFIN_TABLE.EVENT.CHANGE_BATCH_NUM_EVENT , {num = num })
end

function WaterBarDeployFormulaView:CreateRichLabel()
	local viewData = self.freeViewData
	local centerLayer = viewData.freeLayout
	local centerLayerSize = centerLayer:getContentSize()
	local richLabel = display.newRichLabel(centerLayerSize.width -40 , centerLayerSize.height/2 -20, {
		r  = true ,
		c = {
			fontWithColor(14 , { color = "#ba5c5c" , fontSize = 30 , ap = display.CENTER ,hAlign= display.TAC ,  text =__('暂无任何食材')}),
			{ img = _res('arts/cartoon/card_q_3') , ap = cc.p(0.8 ,-0.2 ) , scale = 0.7}
		}
	})
	local colorLayout = display.newLayer(centerLayerSize.width/2 , centerLayerSize.height/2 , {
		ap = display.CENTER,
		color = cc.c4b(0,0,0,0),
		size = centerLayerSize
	})
	colorLayout:addChild(richLabel,20 )
	centerLayer:addChild(colorLayout,20)
	self.viewData.colorLayout = colorLayout
end

function WaterBarDeployFormulaView:SetVisible(isVisible)
	if isVisible then
		if not self.viewData.colorLayout then
			self:CreateRichLabel()
		end
		self.viewData.colorLayout:setVisible(true)
	else
		if self.viewData.colorLayout then
			self.viewData.colorLayout:setVisible(isVisible)
		end
	end
end

return WaterBarDeployFormulaView
