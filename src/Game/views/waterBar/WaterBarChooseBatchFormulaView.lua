
--[[
 * author : kaishiqi
 * descpt : 水吧 - 信息视图
]]
---@class WaterBarChooseBatchFormulaView
local WaterBarChooseBatchFormulaView = class('WaterBarChooseBatchFormulaView', function()
	return CLayout:create(display.size)
end)
local RES_DICT = {
	COMMON_BG_2                              = _res("update/common_bg_2.png"),
	COMMON_BG_TITLE_2                        = _res("ui/common/common_bg_title_2.png"),
	COMMON_BTN_ORANGE                        = _res("ui/home/activity/common_btn_orange.png"),
	COMMON_BG_GOODS_3                           = _res("ui/common/common_bg_goods_3.png"),
	BAR_CHOOSE_FORMULA_BG                    = _res("ui/waterBar/mixedDrink/bar_choose_formula_bg.png"),
	COMMON_BTN_TAB_DEFAULT                   = _res("ui/common/common_btn_tab_default.png"),
	COMMON_BTN_TAB_SELECT                    = _res("ui/common/common_btn_tab_select.png")
}
local BuTTON_CLICK_TAGS = {
	ZERO_STAR   = 1000,
	ONE_STAR    = 1001,
	TWO_STAR    = 1002,
	THREE_STAR  = 1003,
	CLOSE_LAYER = 1004,
}
function WaterBarChooseBatchFormulaView:ctor(param)
	self:InitUI() 
end
function WaterBarChooseBatchFormulaView:InitUI()
	local closeLayer = display.newLayer(display.cx, display.cy ,{ap = display.CENTER,size = display.size,color = cc.c4b(0,0,0,175),enable = true})
	self:addChild(closeLayer)
	closeLayer:setTag(BuTTON_CLICK_TAGS.CLOSE_LAYER)
	local centerLayer = display.newLayer(display.cx + 41, display.cy  + -35 ,{ap = display.CENTER,size = cc.size(742,639)})
	self:addChild(centerLayer)
	local swallowLayer = display.newLayer(371, 319.5 ,{ap = display.CENTER,size = cc.size(742,639),color = cc.c4b(0,0,0,0),enable = true})
	centerLayer:addChild(swallowLayer)
	local bgImage = display.newImageView( RES_DICT.COMMON_BG_2 ,371, 319.5,{ap = display.CENTER})
	centerLayer:addChild(bgImage)
	local titleBtn = display.newButton(369, 618.5 , {n = RES_DICT.COMMON_BG_TITLE_2,ap = display.CENTER})
	centerLayer:addChild(titleBtn)
	display.commonLabelParams(titleBtn ,{fontSize = 24,text = __('选择配方'),color = '#ffffff'})
	local scaleBgImage = display.newImageView( RES_DICT.COMMON_BG_GOODS_3 ,370, 262.9,{ap = display.CENTER,scale9 = true,size = cc.size(630 , 484.8)})
	centerLayer:addChild(scaleBgImage,2)
	local selectFormulaTable = {}
	local starDetailTable = {
		{text = __('三星') , tag = BuTTON_CLICK_TAGS.THREE_STAR },
		{text = __('二星') , tag = BuTTON_CLICK_TAGS.TWO_STAR },
		{text = __('一星') , tag = BuTTON_CLICK_TAGS.ONE_STAR },
		{text = __('零星') , tag = BuTTON_CLICK_TAGS.ZERO_STAR },
	}
	for i = 1 , #starDetailTable do
		local tag = starDetailTable[i].tag
		local text = starDetailTable[i].text
		local oneBtn = display.newButton(141+150*(i-1), 525.5 , {n = RES_DICT.COMMON_BTN_TAB_DEFAULT,ap = display.CENTER , d = RES_DICT.COMMON_BTN_TAB_SELECT})
		centerLayer:addChild(oneBtn)
		oneBtn:setTag(tag)
		display.commonLabelParams(oneBtn , {fontSize = 22,text = text,color = '#ffffff'})
		selectFormulaTable[tostring(tag)] = oneBtn
	end

	local decrLabel = display.newLabel(371, 575.5 , {fontSize = 20 , color = "#5b3c25", text = __('选择需要制作的配方'),ap = display.CENTER})
	centerLayer:addChild(decrLabel)
	local formulaGridView = CGridView:create(cc.size(620, 474))
	formulaGridView:setSizeOfCell(cc.size(620, 125 ))
	formulaGridView:setColumns(1)
	formulaGridView:setAutoRelocate(true)
	formulaGridView:setAnchorPoint(display.CENTER)
	formulaGridView:setPosition(371 , 264.5)
	centerLayer:addChild(formulaGridView,2)
	self.viewData = {
		closeLayer                = closeLayer,
		centerLayer               = centerLayer,
		swallowLayer              = swallowLayer,
		bgImage                   = bgImage,
		titleBtn                  = titleBtn,
		scaleBgImage              = scaleBgImage,
		decrLabel                 = decrLabel,
		formulaGridView           = formulaGridView,
		selectFormulaTable        = selectFormulaTable ,
	}
end
function WaterBarChooseBatchFormulaView:CreateCell()
	local cell  =  CGridViewCell:new()
	local cellSize = cc.size(620, 125 )
	cell:setContentSize(cellSize)
	local formulaCell = display.newLayer(cellSize.width/2, cellSize.height/2 ,{ap = display.CENTER,size = cc.size(620,122)})
	cell:addChild(formulaCell)
	local cellBgImage = display.newImageView( RES_DICT.BAR_CHOOSE_FORMULA_BG ,310.1, 61,{ap = display.CENTER , scale9 = true , size = cc.size(615,122) })
	formulaCell:addChild(cellBgImage)
	local useFormulaBtn = display.newButton(525, 59.05 , { n = RES_DICT.COMMON_BTN_ORANGE,ap = display.CENTER , enable = true })
	formulaCell:addChild(useFormulaBtn)
	display.commonLabelParams(useFormulaBtn ,fontWithColor(14 , {text = __('使用配方'),color = '#ffffff'}))
	---@type GoodNode[]
	local materialCellTable = {}
	for i =1 , 4 do
		local goodNode =require("common.GoodNode").new({
			goodsId = DIAMOND_ID ,
			num = 0 ,
			showAmount = true
		})
		goodNode:setPosition(70+(i-1) * 110 , 61  )
		goodNode:setAnchorPoint(display.CENTER)
		goodNode:setScale(0.85)
		formulaCell:addChild(goodNode)
		goodNode:setVisible(false)
		materialCellTable[i] = goodNode
	end
	cell.viewData = {
		materialCellTable = materialCellTable ,
		useFormulaBtn = useFormulaBtn ,
	}
	return cell
end
function WaterBarChooseBatchFormulaView:UpdateCell(cell ,  materials)
	local viewData = cell.viewData
	---@type GoodNode[]
	local materialCellTable = viewData.materialCellTable
	local count = 0
	for index, material in pairs(materials) do
		count = count + 1
		materialCellTable[count]:setVisible(true)
		materialCellTable[count]:RefreshSelf({goodsId = material.goodsId  , num = material.num})
	end
	for index = count +1 , 4  do
		materialCellTable[index]:setVisible(false)
	end
end
function WaterBarChooseBatchFormulaView:CreateRichLabel()
	local viewData = self.viewData
	local centerLayer = viewData.centerLayer
	local centerLayerSize = centerLayer:getContentSize()
	local richLabel = display.newRichLabel(centerLayerSize.width/2 , centerLayerSize.height/2 + 100 , {
		r  = true ,
		c = {
			fontWithColor(14 , { color = "#ba5c5c" , fontSize = 30 , text =__('暂无任何记录')}),
			{ img = _res('arts/cartoon/card_q_3') , ap = display.LEFT_CENTER , scale = 0.7}
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
function WaterBarChooseBatchFormulaView:SetVisible(isVisible)
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

return WaterBarChooseBatchFormulaView
