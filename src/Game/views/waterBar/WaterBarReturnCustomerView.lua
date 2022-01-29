
--[[
 * author : kaishiqi
 * descpt : 水吧 - 信息视图
]]
---@class WaterBarReturnCustomerView
local WaterBarReturnCustomerView = class('WaterBarReturnCustomerView', function()
	return CLayout:create(display.size)
end)
local RES_DICT = {
	COMMON_BG_FREQUENTER                        = _res("ui/common/common_bg_frequenter.png"),
	MENU_IMG_JIAZI                              = _res("ui/privateRoom/menu_img_jiazi.png"),
	COMMON_DECORATE_KNIFE                       = _res("ui/common/common_decorate_knife.png"),
	COMMON_DECORATE_DECORATIVE1                 = _res("ui/common/common_decorate_decorative1.png"),
	COMMON_DECORATE_DECORATIVE                  = _res("ui/common/common_decorate_decorative.png"),
	COMMON_BG_FRAME_GOODS_ELECTED               = _res("ui/common/common_bg_frame_goods_elected.png"),
	KITCHEN_TOOL_SPLIT_LINE                     = _res("ui/home/lobby/cooking/kitchen_tool_split_line.png"),
	COMMON_BG_GOODS_3                           = _res("ui/common/common_bg_goods_3.png"),
	COMMON_BG_FREQUENTER_GOODS                  = _res("ui/common/common_bg_frequenter_goods.png"),
	COMMON_TITLE_5                              = _res("ui/common/common_title_5.png"),
	COMMON_BTN_ORANGE                           = _res("ui/home/activity/common_btn_orange.png"),
	MARKET_BUY_BG_INFO                          = _res("ui/home/commonShop/market_buy_bg_info.png"),
	BAR_FREQUENTERBG_GOODS                      = _res("ui/waterBar/returnCustom/bar_frequenterbg_goods.png"),
	BAR_ICO_QUESTION_MARK                       = _res("ui/waterBar/returnCustom/bar_ico_question_mark.png"),
	COMMON_BG_4                                 = _res("ui/common/common_bg_4.png"),
	COMMON_BG_TITLE_3                           = _res("ui/common/common_bg_title_3.png"),
	TEAM_BTN_SELECTION_UNUSED                   = _res("ui/home/teamformation/choosehero/team_btn_selection_unused.png"),
	BAR_BG_TASK_WORKING_2                       = _res("ui/waterBar/returnCustom/bar_bg_task_working_2.png"),
	BAR_BG_TASK_WORKING_1                       = _res("ui/waterBar/returnCustom/bar_bg_task_working_1.png"),
	MAIN_SANDGLAS_BG_TIME_2                     = _res("ui/home/nmain/main_sandglas_bg_time_2.png"),
	BAR_FREQUENTER_BAR_2                        = _res("ui/waterBar/returnCustom/bar_frequenter_bar_2.png"),
	BAR_FREQUENTER_BAR_1                        = _res("ui/waterBar/returnCustom/bar_frequenter_bar_1.png"),
	COMMON_FRAME_GOODS_LOCK                     = _res("ui/common/common_frame_goods_lock.png"),
	COMMON_HINT_CIRCLE_RED_ICO                  = _res("ui/common/common_hint_circle_red_ico.png"),
	COMMON_ICO_LOCK                             = _res("ui/common/common_ico_lock.png"),
	COMMON_ARROW                                = _res("ui/common/common_arrow.png"),
	TUJIAN_SELECTION_LINE                       = _res("ui/common/tujian_selection_line.png"),
	TUJIAN_SELECTION_SELECT_BTN_FILTER_SELECTED = _res("ui/common/tujian_selection_select_btn_filter_selected.png"),
	BAR_CHOOSE_FORMULA_BG                       = _res("ui/waterBar/mixedDrink/bar_choose_formula_bg.png"),
	TASK_BAR_SPOT                               = _res('ui/home/task/task_bar_spot.png'),
	TEAM_BTN_SELECTION_CHOOSED                  = _res('ui/home/teamformation/choosehero/team_btn_selection_choosed.png')
}
local SORT_TYPE = {
	{descr = __('全部'), tag = 1},
	{descr = __('今日客人'),  tag = 2},
}
local BAR_RETURN_EVENTS = {
	SELECT_FORMULA_EVENT = "SELECT_FORMULA_EVENT",
	SELECT_SORT_TYPE_EVENT = "SELECT_SORT_TYPE_EVENT",
}
function WaterBarReturnCustomerView:ctor(param)
	self:InitUI()
end
function WaterBarReturnCustomerView:InitUI()
	local closeLayer = display.newLayer(display.cx, display.cy ,{
		ap = display.CENTER,size = display.size,color = cc.c4b(0,0,0,175) , enable = true
	})
	self:addChild(closeLayer)
	local centerLayout = display.newLayer(display.cx + 10.9, display.cy  + -21.7 ,{ap = display.CENTER,size = cc.size(1005.9,682.1)})
	self:addChild(centerLayout)
	local centerSwallowLayer = display.newLayer(502.95, 341.05 ,{color = cc.c4b(0,0,0,0), enable = true, ap = display.CENTER,size = cc.size(1005.9,682.1)})
	centerLayout:addChild(centerSwallowLayer)
	local leftLayout = display.newLayer(181.05, 341.05 ,{ap = display.CENTER,size = cc.size(362.1,682.1)})
	centerLayout:addChild(leftLayout)
	local leftBgImage = display.newImageView( RES_DICT.COMMON_BG_FREQUENTER ,181.05, 341.05,{ap = display.CENTER})
	leftLayout:addChild(leftBgImage)
	local menuImage = display.newImageView( RES_DICT.MENU_IMG_JIAZI ,181.05, 686.05,{ap = display.CENTER})
	leftLayout:addChild(menuImage)
	local rightLineImage = display.newImageView( RES_DICT.COMMON_DECORATE_KNIFE ,349.05, 343.05,{ap = display.CENTER})
	leftLayout:addChild(rightLineImage)
	local leftImage = display.newImageView( RES_DICT.COMMON_DECORATE_KNIFE ,18.05, 343.05,{ap = display.CENTER,scaleX = -1,scaleY = -1})
	leftLayout:addChild(leftImage)
	local decorativeLeft = display.newImageView( RES_DICT.COMMON_DECORATE_DECORATIVE1 ,34.05, 648.05,{ap = display.CENTER})
	leftLayout:addChild(decorativeLeft)
	local decorativeRight = display.newImageView( RES_DICT.COMMON_DECORATE_DECORATIVE1 ,330.05, 650.05,{ap = display.CENTER,scaleX = -1})
	leftLayout:addChild(decorativeRight)
	local bottomdecorativeLeft = display.newImageView( RES_DICT.COMMON_DECORATE_DECORATIVE ,35.05, 35.04999,{ap = display.CENTER})
	leftLayout:addChild(bottomdecorativeLeft)
	local bottomdecorativeRight = display.newImageView( RES_DICT.COMMON_DECORATE_DECORATIVE ,330.05, 35.04999,{ap = display.CENTER,scaleX = -1})
	leftLayout:addChild(bottomdecorativeRight)
	local lineImage = display.newImageView( RES_DICT.KITCHEN_TOOL_SPLIT_LINE ,183.65, 461.1,{ap = display.CENTER,scaleX = 0.85})
	leftLayout:addChild(lineImage)
	local drinkLayout = display.newLayer(183.65, 555.1 ,{ap = display.CENTER,size = cc.size(300.4,150.9)})
	leftLayout:addChild(drinkLayout)
	local drinkBgImage = display.newImageView( RES_DICT.COMMON_BG_GOODS_3 ,150.2, 75.45,{ap = display.CENTER,scale9 = true,size = cc.size(300.4 , 159)})
	drinkLayout:addChild(drinkBgImage)
	local drinkName = display.newLabel(150.2, 126.45 , {fontSize = 30,ttf = true,font = TTF_GAME_FONT,text = '',color = '#bc3c5c',w = 300,hAlign = display.TAC,ap = display.CENTER})

	drinkLayout:addChild(drinkName)
	local drinkKindsLayout = display.newLayer(150.2, 56.45 ,{ap = display.CENTER,size = cc.size(100,100)})
	drinkLayout:addChild(drinkKindsLayout)

	-- 常规奖励
	local commonRewardLayout = display.newLayer(183.65, 358.05 ,{ap = display.CENTER,size = cc.size(300.4,150.9)})
	leftLayout:addChild(commonRewardLayout)
	local commonBgImage = display.newImageView( RES_DICT.COMMON_BG_FREQUENTER_GOODS ,150.2, 75.45,{ap = display.CENTER})
	commonRewardLayout:addChild(commonBgImage)
	local commonTitle = display.newButton(150.2, 140.45 , {n = RES_DICT.COMMON_TITLE_5,ap = display.CENTER})
	commonRewardLayout:addChild(commonTitle)
	display.commonLabelParams(commonTitle ,{fontSize = 22,text = __('普通收益'),color = '#5b3c25'})

	local commonAttrTable = {
		{attr = "barPopularity"   ,  text = __('酒吧知名度') },
		{attr = "frequencyPoint"  ,  text = __('熟客值') },
		{attr = "barPoint"            ,  text = __('饮品券') },
	}
	local priceLabelTable = {}
	for i = 1,#commonAttrTable do
		local commonCustomer = display.newImageView( RES_DICT.MARKET_BUY_BG_INFO ,150.2, 100 -(i-1) * 38 ,{ap = display.CENTER,scale9 = true,size = cc.size(281 , 30)})
		commonRewardLayout:addChild(commonCustomer)
		local commonCustomerLabel = display.newLabel(7, 15 , {fontSize = 20,text = commonAttrTable[i].text,color = '#423B2F',ap = display.LEFT_CENTER})
		commonCustomer:addChild(commonCustomerLabel)
		local commonCustomerPrice = display.newLabel(270, 15 , {fontSize = 20,text = '1111',color = '#f14a11',ap = display.RIGHT_CENTER})
		commonCustomer:addChild(commonCustomerPrice)
		priceLabelTable[commonAttrTable[i].attr] = commonCustomerPrice
	end

	-- 专属奖励
	local exclusiveRewardLayout = display.newLayer(183.65, 182.05 ,{ap = display.CENTER,size = cc.size(300.4,150.9)})
	leftLayout:addChild(exclusiveRewardLayout)
	local exclusiveBgImage = display.newImageView( RES_DICT.BAR_FREQUENTERBG_GOODS ,150.2, 75.45,{ap = display.CENTER})
	exclusiveRewardLayout:addChild(exclusiveBgImage)
	local exclusiveTitle = display.newButton(150.2, 140.45 , {n = RES_DICT.COMMON_TITLE_5,ap = display.CENTER})
	exclusiveRewardLayout:addChild(exclusiveTitle)
	display.commonLabelParams(exclusiveTitle ,{fontSize = 22,text = __('专属收益'),color = '#B95D5E'})

	local exclusiveAttrTable = {
		{attr = "loveBarPopularity"   ,  text = __('酒吧知名度') },
		{attr = "loveFrequencyPoint"  ,  text = __('熟客值') },
		{attr = "loveBarPoint"            ,  text = __('饮品券') },
	}
	local exclusivePriceTable = {}
	for i = 1,#exclusiveAttrTable do
		local exclusivePop = display.newImageView( RES_DICT.MARKET_BUY_BG_INFO ,150.2, 100 -(i-1) * 38 ,{ap = display.CENTER,scale9 = true,size = cc.size(281 , 30)})
		exclusiveRewardLayout:addChild(exclusivePop)
		local exclusiveLabel = display.newLabel(7, 15 , {fontSize = 20,text = commonAttrTable[i].text,color = '#423B2F',ap = display.LEFT_CENTER})
		exclusivePop:addChild(exclusiveLabel)
		local exclusivePriceLabel = display.newLabel(270, 15 , {fontSize = 20,text = '1111',color = '#f14a11',ap = display.RIGHT_CENTER})
		exclusivePop:addChild(exclusivePriceLabel)
		exclusivePriceTable[exclusiveAttrTable[i].attr] = exclusivePriceLabel
	end
	local makeBtn = display.newButton(182.05, 54.04999 , {n = RES_DICT.COMMON_BTN_ORANGE,ap = display.CENTER})
	leftLayout:addChild(makeBtn)
	display.commonLabelParams(makeBtn ,fontWithColor(14 , {text = __('调制'),color = '#ffffff'}))

	local rightLayout = display.newLayer(691.35, 341.05 ,{ap = display.CENTER,size = cc.size(629.1,682.1)})
	centerLayout:addChild(rightLayout)
	local rightImage = display.newImageView( RES_DICT.COMMON_BG_4 ,317.15, 341.65,{ap = display.CENTER,scale9 = true,size = cc.size(623.9 , 670.5)})
	rightLayout:addChild(rightImage)
	local customerTitle = display.newButton(317.15, 647.4 , {n = RES_DICT.COMMON_BG_TITLE_3,ap = display.CENTER})
	rightLayout:addChild(customerTitle)
	display.commonLabelParams(customerTitle ,{text = __('客人列表'), fontSize = 24 , color = '#7E6552' , offset = cc.p(0,-3)})
	local goodsImage = display.newImageView( RES_DICT.COMMON_BG_GOODS_3 ,316.75, 320.76,{ap = display.CENTER , scale9 = true , size = cc.size(596,600 )})
	rightLayout:addChild(goodsImage)
	local selectKindsBtn = display.newCheckBox(553.15, 647.4 , {
		n = RES_DICT.TEAM_BTN_SELECTION_UNUSED ,
		s =  RES_DICT.TEAM_BTN_SELECTION_CHOOSED,
		ap = display.CENTER,
	})
	rightLayout:addChild(selectKindsBtn)

	local selectKindsBtnSize = selectKindsBtn:getContentSize()
	local selectKindsBtnLabel = display.newLabel(selectKindsBtnSize.width/2 , selectKindsBtnSize.height /2, fontWithColor(14,{
		{text = __('今日客人'),color = '#ffffff'}
	}))
	display.commonLabelParams(selectKindsBtnLabel ,fontWithColor(14 , {text = __('今日客人'),color = '#ffffff'}))
	selectKindsBtn:addChild(selectKindsBtnLabel)

	local gridView = CGridView:create(cc.size(595.29, 592.43))
	gridView:setSizeOfCell(cc.size(595 , 140 ))
	gridView:setColumns(1)
	gridView:setAutoRelocate(true)
	gridView:setAnchorPoint(display.CENTER)
	gridView:setPosition(316.505 , 320.78)
	rightLayout:addChild(gridView)
	local drinkNodeTable = {}
	self.viewData = {
		closeLayer                = closeLayer,
		centerLayout              = centerLayout,
		centerSwallowLayer        = centerSwallowLayer,
		leftLayout                = leftLayout,
		leftBgImage               = leftBgImage,
		menuImage                 = menuImage,
		rightImage                = rightImage,
		leftImage                 = leftImage,
		decorativeLeft            = decorativeLeft,
		decorativeRight           = decorativeRight,
		bottomdecorativeLeft      = bottomdecorativeLeft,
		bottomdecorativeRight     = bottomdecorativeRight,
		lineImage                 = lineImage,
		drinkLayout               = drinkLayout,
		drinkBgImage              = drinkBgImage,
		drinkName                 = drinkName,
		drinkKindsLayout          = drinkKindsLayout,
		commonRewardLayout        = commonRewardLayout,
		commonBgImage             = commonBgImage,
		commonTitle               = commonTitle,
		exclusiveRewardLayout     = exclusiveRewardLayout,
		exclusiveBgImage          = exclusiveBgImage,
		exclusiveTitle            = exclusiveTitle,
		makeBtn                   = makeBtn,
		rightLayout               = rightLayout,
		customerTitle             = customerTitle,
		goodsImage                = goodsImage,
		selectKindsBtnLabel       = selectKindsBtnLabel,
		selectKindsBtn            = selectKindsBtn,
		gridView                  = gridView,
		drinkNodeTable            = drinkNodeTable ,
		exclusivePriceTable       = exclusivePriceTable ,
		priceLabelTable           = priceLabelTable
	}
end

function WaterBarReturnCustomerView:UpdateDrinksKindLayout(customerId)
	local customerConf = CONF.BAR.CUSTOMER:GetValue(customerId)
	local formulas = clone(checktable(customerConf.formula))
	local count = #formulas
	local goodSize = cc.size(100,100)
	local viewData = self.viewData
	viewData.drinkNodeTable = {}
	viewData.drinkKindsLayout:setVisible(false)
	viewData.drinkKindsLayout:removeAllChildren()
	viewData.drinkKindsLayout:setContentSize(cc.size(goodSize.width* count , goodSize.height))
	local formulaConf = CONF.BAR.FORMULA:GetAll()
	table.sort(formulas , function(aFormulaId, bFormulaId)
		local aFormulaData = app.waterBarMgr:getFormulaData(aFormulaId)
		local bFormulaData = app.waterBarMgr:getFormulaData(bFormulaId)
		if (aFormulaData and bFormulaData) or aFormulaData == bFormulaData then
			local aOpenBarLevel = checkint(formulaConf[tostring(aFormulaId)].openBarLevel)
			local bOpenBarLevel = checkint(formulaConf[tostring(bFormulaId)].openBarLevel)
			if aOpenBarLevel == bOpenBarLevel then
				return checkint(aFormulaId) > checkint(bFormulaId)
			else
				return aOpenBarLevel < bOpenBarLevel
			end
		else
			if aFormulaData then
				return true
			else
				return false
			end
		end
	end)

	for i =1 , count do
		local drinkNode = require("common.GoodNode").new({goodsId = formulas[i]})
		drinkNode:setAnchorPoint(display.CENTER)
		drinkNode:setPosition(goodSize.width*(i -0.5) , goodSize.height/2)
		drinkNode:setScale(0.8)
		local drinkSize = drinkNode:getContentSize()
		local selectImage = display.newImageView(RES_DICT.COMMON_BG_FRAME_GOODS_ELECTED , drinkSize.width/2 , drinkSize.height /2)
		drinkNode:addChild(selectImage , -1)
		selectImage:setName("selectImage")
		selectImage:setVisible(false)
		viewData.drinkKindsLayout:addChild(drinkNode)
		drinkNode:setTag(checkint(formulas[i]))
		viewData.drinkNodeTable[tostring(formulas[i])] = drinkNode
		local status = app.waterBarMgr:GetFormulaIdStatus(formulas[i])
		if status > FOOD.WATER_BAR.FORMULA_STATUS.UNLCOK_NOT_MAKE then
			local frameImage = display.newImageView(RES_DICT.COMMON_FRAME_GOODS_LOCK,drinkSize.width/2 , drinkSize.height/2)
			drinkNode:addChild(frameImage  , 20 )
		end
		if status == FOOD.WATER_BAR.FORMULA_STATUS.LEVEL_LOCK then
			local lockImage = display.newImageView(RES_DICT.COMMON_ICO_LOCK ,drinkSize.width/2 ,drinkSize.height/2)
			drinkNode:addChild(lockImage , 21)
		end

		if status == FOOD.WATER_BAR.FORMULA_STATUS.HIDE then
			local questionImage = display.newImageView(RES_DICT.BAR_ICO_QUESTION_MARK ,drinkSize.width/2 ,drinkSize.height/2)
			drinkNode:addChild(questionImage , 21)
		end
		drinkNode:setOnClickScriptHandler(function(sender)
			local formulaId = sender:getTag()
			local status = app.waterBarMgr:GetFormulaIdStatus(formulaId)
			if status == FOOD.WATER_BAR.FORMULA_STATUS.LEVEL_LOCK or status == FOOD.WATER_BAR.FORMULA_STATUS.HIDE then
				app.uiMgr:ShowInformationTips(__('当前饮品尚未解锁'))
				return
			end
			if status == FOOD.WATER_BAR.FORMULA_STATUS.UNLCOK_NOT_MAKE then
				app.uiMgr:ShowInformationTips(__('当前饮品尚未调制'))
			end
			app:DispatchObservers(BAR_RETURN_EVENTS.SELECT_FORMULA_EVENT , { formulaId = sender:getTag()})
		end)
	end
	viewData.drinkKindsLayout:setVisible(true)
end
function WaterBarReturnCustomerView:UpdateSelectDrinkNode(formulaId)
	formulaId = checkint(formulaId)
	local viewData = self.viewData
	local drinkNodeTable = viewData.drinkNodeTable
	if drinkNodeTable  then
		for k, drinkNode in pairs(drinkNodeTable) do
			local selectImage =  drinkNode:getChildByName("selectImage")
			if formulaId == checkint(k) then
				selectImage:setVisible(true)
				drinkNode:setScale(0.9)
				drinkNode:setEnabled(false)
			else
				drinkNode:setScale(0.8)
				selectImage:setVisible(false)
				drinkNode:setEnabled(true)
			end
		end
	end
	-- 更新饮品的显示
	local formulaConf = CONF.BAR.FORMULA:GetValue(formulaId)
	local name = formulaConf.name
	display.commonLabelParams(viewData.drinkName , {text = name})
	local status = app.waterBarMgr:getHomeStatus()
	if status == 1  then
		self.viewData.selectKindsBtn:setVisible(false)
	else
		self.viewData.selectKindsBtn:setVisible(true)
	end
end

function WaterBarReturnCustomerView:UpdateView(drinkId)
	local viewData = self.viewData
	if not drinkId then
		for attr, label in pairs(viewData.priceLabelTable) do
			display.commonLabelParams(label , {text = "???"})
		end
		for attr, label in pairs(viewData.exclusivePriceTable) do
			display.commonLabelParams(label , {text = "???"})
		end
	else
		local drinkConf = CONF.BAR.DRINK:GetValue(drinkId)
		for attr, label in pairs(viewData.priceLabelTable) do
			display.commonLabelParams(label , {text = string.fmt(__('_num_/份') , {_num_ = checkint(drinkConf[attr])})})
		end
		for attr, label in pairs(viewData.exclusivePriceTable) do
			display.commonLabelParams(label , {text = string.fmt(__('_num_/份') , {_num_ = checkint(drinkConf[attr])})})
		end
	end
end

function WaterBarReturnCustomerView:CreateCell()
	local cell = CGridViewCell:new()
	cell:setContentSize(cc.size(595,139.91) )
	local cellLayout  = display.newLayer(595/2, 139.91 /2  ,{ap = display.CENTER, size = cc.size(595,139.91)})
	cell:addChild(cellLayout)
	local cardHeadNode = require('common.CardHeadNode').new({
		cardData = {
			cardId = 200001
		}
	})
	cardHeadNode:setPosition(70 , 70)
	cardHeadNode:setScale(0.6)
	cellLayout:addChild(cardHeadNode,10)
	local cellBgImage = display.newImageView( RES_DICT.BAR_BG_TASK_WORKING_2 ,297.5, 69.955,{ap = display.CENTER , enable = true})
	cellLayout:addChild(cellBgImage)
	local clickImage = display.newButton(0,0,{ ap= display.LEFT_BOTTOM ,   size = cc.size(595,139.91) , enable = true  })
	cellLayout:addChild(clickImage,10)
	local cardName = display.newLabel(149.5, 120.955 , {fontSize = 30,ttf = true,font = TTF_GAME_FONT,text = '',color = '#B16688',ap = display.LEFT_CENTER})
	cellLayout:addChild(cardName)
	local cellSelectImage = display.newImageView( RES_DICT.BAR_BG_TASK_WORKING_1 ,297.5, 69.955,{ap = display.CENTER})
	cellLayout:addChild(cellSelectImage)
	local activityTimeImage = display.newImageView( RES_DICT.MAIN_SANDGLAS_BG_TIME_2 ,442.5, 118.955,{ap = display.CENTER})
	cellLayout:addChild(activityTimeImage)
	local activityTimeLabel = display.newRichLabel(170.5, 55 ,{ap = display.RIGHT_CENTER,c = {{text = '11'}}})
	activityTimeImage:addChild(activityTimeLabel)
	local decrLabel = display.newRichLabel(143.95, 56.96501 ,{ap = display.LEFT_CENTER,c = {{text = '11'}}})
	cellLayout:addChild(decrLabel)
	local prograssLabel = display.newRichLabel(442.5, 118.955 ,{ap = display.CENTER,c = {{text = '11'}}})
	cellLayout:addChild(prograssLabel)

	local starTable = {100,  200 , 300 , 500 , 700 , 1000}
	local goodNodes = {}
	local lines = {}
	local prograssLabels = {}
	local prograssLayout = display.newLayer(347.5, 57.23 ,{ap = display.CENTER,size = cc.size(462.8,93.45)})
	cellLayout:addChild(prograssLayout)
	local prograssBar = CProgressBar:create(RES_DICT.BAR_FREQUENTER_BAR_1)
	prograssBar:setBackgroundImage(RES_DICT.BAR_FREQUENTER_BAR_2)
	prograssBar:setAnchorPoint(display.CENTER)
	prograssBar:setDirection(eProgressBarDirectionLeftToRight)
	prograssBar:setMaxValue(1000)
	prograssBar:setValue(0)
	prograssBar:setPosition(cc.p(231.4 , 28.725))
	prograssLayout:addChild(prograssBar)
	local prograssBarSize = prograssBar:getContentSize()
	local height = 18
	local width = 15
	for i =1 , #starTable do
		local goodNode = require('common.GoodNode').new({goodsId = DIAMOND_ID , showAmount = true })
		local posX = prograssBarSize.width *(starTable[i]/1000)
		goodNode:setScale(0.5)
		goodNode:setAnchorPoint(display.CENTER)
		local lockImage = display.newImageView(RES_DICT.COMMON_FRAME_GOODS_LOCK , 54, 54 )
		goodNode:addChild(lockImage,10)
		lockImage:setName("lockImage")
		local iconImage = display.newImageView(RES_DICT.COMMON_HINT_CIRCLE_RED_ICO , 95, 95)
		goodNode:addChild(iconImage,10)
		iconImage:setName("iconImage")
		local arrowImag = display.newImageView(RES_DICT.COMMON_ARROW ,54 , 54 )
		goodNode:addChild(arrowImag,10)
		arrowImag:setName("arrowImag")
		prograssLayout:addChild(goodNode)
		goodNode:setPosition(posX+width , 47+height)
		goodNodes[#goodNodes+1] = goodNode
		local lineImage = display.newImageView(RES_DICT.TASK_BAR_SPOT ,posX + width,10+height  )
		prograssLayout:addChild(lineImage)
		lines[#lines+1] = lineImage
		local label = display.newLabel(posX + width , -10 + height  , {fontSize = 20 , color = "#5b3c25", text =starTable[i] })
		prograssLayout:addChild(label)
		prograssLabels[i] = label
	end
	lines[#lines]:setVisible(false)
	cell.viewData = {
		cellLayout        = cellLayout,
		cardHeadNode      = cardHeadNode,
		cellSelectImage   = cellSelectImage,
		activityTimeLabel = activityTimeLabel,
		decrLabel         = decrLabel,
		cardName          = cardName  ,
		goodNodes         = goodNodes,
		prograssLayout    = prograssLayout,
		lines             = lines,
		prograssLabel     = prograssLabel,
		prograssLabels    = prograssLabels,
		clickImage        = clickImage,
		activityTimeImage = activityTimeImage,
		prograssBarSize = prograssBarSize,
		prograssBar       = prograssBar,
	}
	return cell
end
function WaterBarReturnCustomerView:CreateSortLayout()
	local cellSize  = cc.size(125 , 56)
	local sortBoardImg = display.newImageView(RES_DICT.BAR_CHOOSE_FORMULA_BG, 0,0
	,{scale9 = true,size = cc.size(cellSize.width ,  8+cellSize.height *(#SORT_TYPE))})
	local sortBoardSize = sortBoardImg:getContentSize()
	local viewData = self.viewData
	local selectKindsBtn = viewData.selectKindsBtn
	local pos = cc.p(selectKindsBtn:getPosition())
	local sortBoard = display.newLayer(pos.x,pos.y - 25,
			{size = sortBoardSize, ap = display.CENTER_TOP})
	sortBoardImg:setPosition(sortBoardSize.width/2 , sortBoardSize.height/2)
	sortBoard:addChild(sortBoardImg)
	viewData.rightLayout:addChild(sortBoard ,20 )
	local cellLayouts = {}
	for i = 1, #SORT_TYPE do
		local cellLayout = display.newButton(cellSize.width/2 , sortBoardSize.height - (i - 0.5 ) * cellSize.height -4  , {size = cellSize})
		sortBoard:addChild(cellLayout)
		local selectImage = display.newImageView(RES_DICT.TUJIAN_SELECTION_SELECT_BTN_FILTER_SELECTED ,cellSize.width/2 , cellSize.height/2)
		cellLayout:addChild(selectImage, -1)
		selectImage:setName("selectImage")
		selectImage:setVisible(false)
		cellLayout:setTag(SORT_TYPE[i].tag)
		display.commonUIParams(cellLayout , {cb = function(sender)
			app:DispatchObservers(BAR_RETURN_EVENTS.SELECT_SORT_TYPE_EVENT, {sortType = sender:getTag()})
		end})
		display.commonLabelParams(cellLayout ,fontWithColor(5,{text =SORT_TYPE[i].descr }) )
		cellLayouts[#cellLayouts+1] = cellLayout
		if i == #SORT_TYPE then break end
		local lineImage = display.newImageView(RES_DICT.TUJIAN_SELECTION_LINE , cellSize.width/2 , 0 )
		cellLayout:addChild(lineImage)
	end
	viewData.cellLayouts = cellLayouts
	viewData.sortBoard = sortBoard
end

function WaterBarReturnCustomerView:SortBordIsVisible(isVisible)
	local viewData = self.viewData
	viewData.sortBoard:setVisible(isVisible)
end
function WaterBarReturnCustomerView:UpdateSortLayout(selectTag)
	local viewData = self.viewData
	if not viewData.cellLayouts then
		self:CreateSortLayout()
	end
	for i = 1, #viewData.cellLayouts do
		local cellLayout = viewData.cellLayouts[i]
		local tag = cellLayout:getTag()
		local selectImage = cellLayout:getChildByName("selectImage")
		if tag == selectTag then
			selectImage:setVisible(true)
		else
			selectImage:setVisible(false)
		end
	end
end

return WaterBarReturnCustomerView
