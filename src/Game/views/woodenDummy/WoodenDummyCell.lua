---
--- Created by xingweihao.
--- DateTime: 20/11/2017 1:32 PM
---
---@class WoodeDummyCell
local WoodeDummyCell = class('home.WoodeDummyCell',function ()
	local pageviewcell = CTableViewCell:new()
	pageviewcell.name = 'home.WoodeDummyCell'
	pageviewcell:enableNodeEvents()
	return pageviewcell
end)
local DESC_DICT = {

	CARD_BG_CHOSEN               = _res('ui/home/materialScript/material_card_bg_chosen'),
	CARD_BG_MAIN                 = _res('ui/home/cardslistNew/woodenDummy/material_card_bg_main'),
	CARD_BG_SUB                  = _res('ui/home/materialScript/material_card_bg_sub'),
	CARD_BG_TITLE                = _res('ui/home/materialScript/material_card_bg_title'),
	CARD_BTN_SELECT_DEFAULT      = _res('ui/home/materialScript/material_card_btn_selectlist_default'),
	CARD_BTN_SELECT_DOWN         = _res('ui/home/materialScript/material_card_btn_selectlist_down'),
	CARD_LINE_ONE                = _res('ui/home/materialScript/material_card_line_1'),
	CARD_LINE_TWO                = _res('ui/home/materialScript/material_card_line_2'),
	CARD_MODEICO                 = _res('ui/home/materialScript/material_card_modeico_1'),
	CARD_WARNING_TWO             = _res('ui/home/materialScript/material_label_warning_2'),
	CARD_SELECT_LIST             = _res('ui/home/materialScript/material_selectlist_bg'),
	CARD_SELECT_LIST_LABEL_CHOSE = _res('ui/home/materialScript/material_selectlist_label_chosen'),
	CARD_SELECT_LIST_LABEL_LINE  = _res('ui/home/materialScript/material_selectlist_line'),
	MATERIAL_CARD_ICON           = _res('ui/home/cardslistNew/woodenDummy/exercises_bg_attack_1'),
}
local CELL_STATUS = {
	LOCK_STATUS = 1 , -- 未解锁
	UNLOCK_UNUSE = 2 , -- 已解锁 不可用
	UNLOCK_UNSELECT = 3 , -- 解锁未选中
	UNLOCK_SELECT = 4 , -- 选中状态

}
function WoodeDummyCell:ctor(param)
	local cellSize =  cc.size(404,680)
	self:setContentSize(cellSize)
	local cellContentSzie = cc.size(400,600)
	local cellLayout = display.newLayer(cellSize.width/2, 50, { ap = display.CENTER_BOTTOM  , size = cellContentSzie})
	self:addChild(cellLayout)
	cellLayout:setName("cellLayout")
	-- 点击的layer
	local clickLayer = display.newLayer(cellContentSzie.width/2 , cellContentSzie.height/2,
			{ap = display.CENTER ,size =cellContentSzie , color = cc.c4b(0,0,0,0) , enable = true })
	cellLayout:addChild(clickLayer)
	-- 选中的光圈
	local bgImageChosen = display.newImageView(DESC_DICT.CARD_BG_CHOSEN , cellContentSzie.width/2 , cellContentSzie.height/2)
	cellLayout:addChild(bgImageChosen)
	bgImageChosen:setVisible(false)
	-- 材料的东西
	local materialCard =FilteredSpriteWithOne:create(DESC_DICT.MATERIAL_CARD_ICON)
	materialCard:setPosition(cc.p(  cellContentSzie.width/2 , cellContentSzie.height + 20))
	materialCard:setAnchorPoint(display.CENTER_TOP)
	cellLayout:addChild(materialCard)
	-- 前面的背景
	local card_bg_main = FilteredSpriteWithOne:create(DESC_DICT.CARD_BG_MAIN )
	card_bg_main:setPosition(cc.p(  cellContentSzie.width/2 , cellContentSzie.height /2))
	cellLayout:addChild(card_bg_main)

	-- 最左侧的线
	local titleImage =  FilteredSpriteWithOne:create(DESC_DICT.CARD_BG_TITLE)
	local titleSize = titleImage:getContentSize()

	local titleLayout  =   display.newLayer(cellContentSzie.width/2 , cellContentSzie.height - 350,
			{ap = display.CENTER ,size =titleSize , color = cc.c4b(0,0,0,0)})
	titleLayout:addChild(titleImage)
	titleImage:setPosition(cc.p(titleSize.width/2 ,titleSize.height/2 +10))
	cellLayout:addChild(titleLayout,2)
	-- 副本的名字
	local materialScriptLabel = display.newLabel(titleSize.width/2 , titleSize.height/2  +10,
		fontWithColor('14' , {fontSize = 26 , color = "#ffffff" ,text = " asdadada"}))
	titleLayout:addChild(materialScriptLabel)


	-- 中间区域的背景
	local card_bg_sub_Size = cc.size(295, 175)
	local card_bg_sub = display.newImageView(DESC_DICT.CARD_BG_SUB , 0,0, {scale9 = true , size = card_bg_sub_Size  })

	card_bg_sub:setPosition(cc.p(card_bg_sub_Size.width/2 , card_bg_sub_Size.height/2))
	local subcontentLayout =  display.newLayer(cellContentSzie.width/2 , cellContentSzie.height - 380 ,
			{ap = display.CENTER_TOP ,size =card_bg_sub_Size , color1 = cc.r4b() , enable = true })

	cellLayout:addChild(subcontentLayout)
	subcontentLayout:addChild(card_bg_sub)

	-- 选择难度
	local chosenDifficultyLabel = display.newLabel(15, card_bg_sub_Size.height-20 ,
			fontWithColor('8' , {fontSize = 20 ,color = "#926341",text =  __("选择难度:") ,ap = display.LEFT_CENTER}))
	subcontentLayout:addChild(chosenDifficultyLabel)
	-- 选择难度的按钮
	local chooseDifficultyBtn  =  display.newCheckBox(card_bg_sub_Size.width/2 , card_bg_sub_Size.height -35,
			{ n = DESC_DICT.CARD_BTN_SELECT_DEFAULT , s=   DESC_DICT.CARD_BTN_SELECT_DOWN})
	chooseDifficultyBtn:setName("chooseDifficultyBtn")
	local chooseDifficultyBtnSize = chooseDifficultyBtn:getContentSize()
	chooseDifficultyBtn:setPosition(cc.p(chooseDifficultyBtnSize.width/2 , chooseDifficultyBtnSize.height/2))
	local chooseDifficultyLayout = display.newLayer(card_bg_sub_Size.width/2 , card_bg_sub_Size.height -35,
{ap = display.CENTER_TOP , size = chooseDifficultyBtnSize ,color = cc.c4b(0,0,0,0),enable = true  })
	subcontentLayout:addChild( chooseDifficultyLayout)

	chooseDifficultyLayout:addChild(chooseDifficultyBtn)
	-- 选择的难度
	local difficultyLabel = display.newRichLabel(chooseDifficultyBtnSize.width/2  , chooseDifficultyBtnSize.height/2 ,
{ r = true , c ={fontWithColor('8' , {text = ""}) } })
	difficultyLabel:setName("difficultyLabel")
	chooseDifficultyLayout:addChild(difficultyLabel)

	-- 第二条线
	local lineTwo  = display.newImageView(DESC_DICT.CARD_LINE_TWO ,card_bg_sub_Size.width/2 , card_bg_sub_Size.height - 104 , { ap = display.CENTER_TOP} )
	subcontentLayout:addChild(lineTwo)


	self.viewData = {
		clickLayer             = clickLayer,
		materialCard           = materialCard,
		card_bg_main           = card_bg_main,
		titleImage             = titleImage,
		materialScriptLabel    = materialScriptLabel,
		chooseDifficultyBtn    = chooseDifficultyBtn,
		difficultyLabel        = difficultyLabel,
		subcontentLayout       = subcontentLayout,
		card_bg_sub            = card_bg_sub,
		cellLayout             = cellLayout,
		chooseDifficultyLayout = chooseDifficultyLayout,
		bgImageChosen          = bgImageChosen
	}
end

function WoodeDummyCell:UpdateCell(index)

	local dummyTypeConf = CommonUtils.GetConfigAllMess('dummyType' , 'player')
	print(string.format("%s%s"  ,"ui/home/cardslistNew/woodenDummy/" , dummyTypeConf[tostring(index)].picture) )
	self.viewData.materialCard:setTexture(_res(string.format("%s%s"  ,"ui/home/cardslistNew/woodenDummy/" , dummyTypeConf[tostring(index)].picture) ) )
	local name = dummyTypeConf[tostring(index)] and  dummyTypeConf[tostring(index)].name or ""
	display.commonLabelParams(self.viewData.materialScriptLabel , fontWithColor(14, {text = name }))
end

function WoodeDummyCell:UpdateLabel(text)
	display.reloadRichLabel(self.viewData.difficultyLabel, { width = 250 ,  c= {
		fontWithColor('14' , {text = text }) ,
		{img =  _res('ui/common/common_bg_tips_horn')  , ap = cc.p(-0.2,0 ) }

	}})
	--CommonUtils.SetNodeScale(self.viewData.difficultyLabel , {width = 250})
end

return WoodeDummyCell