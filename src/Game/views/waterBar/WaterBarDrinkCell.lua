--[[
活动每日签到Cell
--]]
---@class WaterBarDrinkCell
local WaterBarDrinkCell = class('WaterBarDrinkCell', function ()
	local WaterBarDrinkCell = CGridViewCell:new()
	WaterBarDrinkCell.name = 'home.WaterBarDrinkCell'
	WaterBarDrinkCell:enableNodeEvents()
	return WaterBarDrinkCell
end)
local waterBarMgr = app.waterBarMgr
local RES_DICT={
	BAR_SHOP_BG1                       = _res("ui/waterBar/mixedDrink/bar_shop_bg1.png"),
	BAR_SHOP_TIPS_BG                   = _res("ui/waterBar/mixedDrink/bar_shop_tips_bg.png"),
	BAR_SHOP_RANK_BG                   = _res("ui/waterBar/mixedDrink/bar_shop_rank_bg.png"),
	BAR_SHOP_ICON_RANK                 = _res("ui/common/common_star_l_ico.png"),
	BAR_SHOP_ICON_HEART                = _res("ui/waterBar/mixedDrink/bar_shop_icon_heart.png"),
	BAR_SHOP_ICON_HEART_BG             = _res("ui/waterBar/mixedDrink/bar_shop_icon_heart_bg.png"),
	BAR_SHOP_TIPS_ICON_INVENTORY       = _res("ui/waterBar/mixedDrink/bar_shop_tips_icon_inventory.png"),
	BAR_BARTENDING_ICON_RECONCILIATION = _res("ui/waterBar/mixedDrink/bar_bartending_icon_reconciliation.png"),
	COMMON_STAR_GREY_L_ICO             = _res("ui/common/common_star_grey_l_ico.png")
}
function WaterBarDrinkCell:ctor( ... )
	local size = cc.size(323,214)
	self:setContentSize(cc.size(323,214))
	local drinkSize = cc.size(323,214)
	local drinkLayout = display.newLayer(size.width/2 , size.height/2 ,{  ap = display.CENTER,size = drinkSize})
	self:addChild(drinkLayout)
	local clickBtn = display.newButton(drinkSize.width/2 , drinkSize.height/2 , {size = drinkSize})
	drinkLayout:addChild(clickBtn)
	local bottomMenuBar = display.newImageView( RES_DICT.BAR_SHOP_BG1 ,323/2, 0,{ap = display.CENTER_BOTTOM})
	drinkLayout:addChild(bottomMenuBar)
	local drinkName = display.newLabel(drinkSize.width/2 , 18 , {text = ''})
	drinkLayout:addChild(drinkName)
	local stackImage = display.newImageView( RES_DICT.BAR_SHOP_TIPS_BG ,257.65, 66.3,{ap = display.CENTER})
	drinkLayout:addChild(stackImage,2)
	local stackLabel = display.newRichLabel(37.5, 20  , {ap = display.CENTER , c = {
		{text = ""}
	}})
	stackImage:addChild(stackLabel)
	local starBgImage = display.newButton(60, 214,{ap = display.CENTER_TOP , n =  RES_DICT.BAR_SHOP_RANK_BG , enable = false })
	drinkLayout:addChild(starBgImage)
	local starLayout = display.newLayer(55, 21,{ap = display.CENTER , size = cc.size(21*3,21)})
	starBgImage:addChild(starLayout)
	local width = 21
	local starNum = 3
	starLayout:setContentSize(cc.size(width*starNum , width))
	local starTables = {}
	for i =1 , 3 do
		local starImage  = display.newImageView( RES_DICT.BAR_SHOP_ICON_RANK  , width*(i-0.5), width/2,{ap = display.CENTER,scaleX = 0.6,scaleY = 0.6})
		starLayout:addChild(starImage)
		starTables[#starTables+1] = starImage
	end
	local focusOnBtn = display.newImageView( RES_DICT.BAR_SHOP_ICON_HEART ,drinkSize.width -20 , drinkSize.height -10,{ap = display.RIGHT_TOP , enable = true })
	drinkLayout:addChild(focusOnBtn)
	local drinkImage = FilteredSpriteWithOne:create(RES_DICT.BAR_BARTENDING_ICON_RECONCILIATION)
	drinkImage:setPosition(160.65, 36.50001)
	drinkImage:setAnchorPoint(display.CENTER_BOTTOM)
	drinkLayout:addChild(drinkImage)
	self.viewData = {
		clickBtn      = clickBtn,
		bottomMenuBar = bottomMenuBar,
		drinkName     = drinkName,
		stackImage    = stackImage,
		stackLabel    = stackLabel,
		starBgImage   = starBgImage,
		focusOnBtn    = focusOnBtn,
		drinkLayout   = drinkLayout,
		drinkImage    = drinkImage,
		starTables    = starTables ,
		starLayout    = starLayout
	}
end

function WaterBarDrinkCell:UpdateCell(data , index )
	local formulaId = tostring(data.formulaId)
	local formulaData = waterBarMgr:getFormulaData(formulaId)
	local viewData = self.viewData
	viewData.drinkImage:setVisible(false)
	viewData.stackImage:setVisible(false)
	viewData.starLayout:setVisible(false)
	viewData.starBgImage:setVisible(false)
	viewData.focusOnBtn:setVisible(false)
	local formulaConf = CONF.BAR.FORMULA:GetValue(formulaId)
	viewData.drinkImage:setTexture(CommonUtils.GetGoodsIconPathById(data.formulaId))
	display.commonLabelParams(viewData.starBgImage , {text  = ""})
	if formulaData then
		self:UpdateStarLayout(data.highStar)
		viewData.drinkImage:setVisible(true)
		viewData.stackImage:setVisible(true)
		viewData.focusOnBtn:setVisible(true)
		viewData.focusOnBtn:setVisible(true)
		if checkint(data.like) == 1 then
			viewData.focusOnBtn:setTexture(RES_DICT.BAR_SHOP_ICON_HEART)
		else
			viewData.focusOnBtn:setTexture(RES_DICT.BAR_SHOP_ICON_HEART_BG)
		end
		viewData.drinkImage:clearFilter()
		local drinkNums = 0
		local drinks = formulaConf.drinks or {}
		for i, drinkId in pairs(drinks) do
			drinkNums = drinkNums + waterBarMgr:getDrinkNum(drinkId)
		end
		display.reloadRichLabel(viewData.stackLabel , {c = {
			{img = RES_DICT.BAR_SHOP_TIPS_ICON_INVENTORY } ,
			{text = drinkNums , fontSize = 20 , color = "#5B3C25"}
		}})
		display.commonLabelParams(viewData.drinkName , {fontSize = 22 , text = formulaConf.name , color = "#ffffff"})
	else
		display.reloadRichLabel(viewData.stackLabel , {c = {
			{img = RES_DICT.BAR_SHOP_TIPS_ICON_INVENTORY } ,
			{text = 0 , fontSize = 20 , color = "#5B3C25"}
		}})
		viewData.focusOnBtn:setTexture(RES_DICT.BAR_SHOP_ICON_HEART_BG)
		if not data.barLevel then
			viewData.drinkImage:clearFilter()
			viewData.drinkImage:setTexture(CommonUtils.GetGoodsIconPathById(FOOD.GOODS.DEFINE.WATER_BAR_HIDE_FORMULA_ID))
			viewData.drinkImage:setVisible(true)
			display.commonLabelParams(viewData.drinkName , {fontSize = 20 ,  text = "?????"})
		else
			display.commonLabelParams(viewData.drinkName , {
				fontSize = 20 ,  text = string.fmt(__('水吧等级_level_解锁') ,{_level_ = formulaConf.openBarLevel })
			})
			local grayFilter = GrayFilter:create()
			viewData.drinkImage:setFilter(grayFilter)
			viewData.drinkImage:setVisible(true)
		end
	end
	if index%2 == 0 then
		viewData.bottomMenuBar:setScaleX(-1)
		viewData.bottomMenuBar:setPosition(164, 29.3-30)
	else
		viewData.bottomMenuBar:setScaleX(1)
		viewData.bottomMenuBar:setPosition(160.65, 29.3-30)
	end
end

function WaterBarDrinkCell:UpdateStarLayout(starNum)
	starNum = checkint(starNum)
	local viewData = self.viewData
	-- 首先删除自己的全部子节点的星星
	for i =1 , starNum do
		if  viewData.starTables[i] then
			viewData.starTables[i]:setTexture(RES_DICT.BAR_SHOP_ICON_RANK)
		end
	end
	for  i = starNum +1 , 3 do
		if  viewData.starTables[i] then
			viewData.starTables[i]:setTexture(RES_DICT.COMMON_STAR_GREY_L_ICO)
		end
	end
	if starNum < 0  then
		viewData.starBgImage:setVisible(true)
		display.commonLabelParams(viewData.starBgImage , {color = "5b3c25", fontSize = 20,  text = __('尚未调制')})
	else
		viewData.starLayout:setVisible(true)
		viewData.starBgImage:setVisible(true)
	end
end
return WaterBarDrinkCell