---
--- Created by xingweihao.
--- DateTime: 23/08/2017 7:59 PM
---
---@class WoodenDummyRecordView :Node
local WoodenDummyRecordView = class('Game.views.WoodenDummyRecordView' ,function ()
	local node = display.newLayer(display.cx , display.cy , { ap = display.CENTER })
	--CLayout:create(cc.size(400,))
	node.name = 'Game.views.WoodenDummyRecordView'
	node:enableNodeEvents()
	return node
end)
local RES_DICT = {
	COMMON_BG_GOODS               = _res('ui/common/common_bg_goods.png'),
	COMMCON_BG_TEXT               = _res('ui/common/commcon_bg_text.png'),
	COMMON_BG_TITLE_2             = _res('ui/common/common_bg_title_2.png'),
	COMMON_BG_5                   = _res('ui/common/common_bg_5.png'),
	EXERCISES_RECORD_BG_TALENT    = _res('ui/home/cardslistNew/woodenDummy/exercises_record_bg_talent.png'),
	TEAM_LEAD_SKILL_FRAME_L       = _res('avatar/ui/team_lead_skill_frame_l.png'),
	EXERCISES_RECORD_BG_NUM       = _res('ui/home/cardslistNew/woodenDummy/exercises_record_bg_num.png')
}

function WoodenDummyRecordView:ctor()
	self:initUI()
end
local newImageView = display.newImageView
local newButton = display.newButton
local newLayer = display.newLayer
function WoodenDummyRecordView:initUI()
	local view = newLayer(display.cx, display.cy,{ap = display.CENTER, size = display.size})
	local colorLayer = display.newLayer(display.cx , display.cy , { ap = display.CENTER, color = cc.c4b(0,0,0,175) , size = display.size , enable = true  })
	view:addChild(colorLayer)
	local closeLayer = display.newButton(display.cx , display.cy , { ap = display.CENTER, size = display.size , enable = true  })
	view:addChild(closeLayer)

	self:addChild(view)
	local contentLayer = newLayer(display.cx , display.cy,
			{ ap = display.CENTER, size = cc.size(1131, 639) })
	view:addChild(contentLayer)

	local contentSallowLayer = display.newButton(0,0, { ap = display.LEFT_BOTTOM,  size = cc.size(1131, 639) ,enable = true   })
	contentLayer:addChild(contentSallowLayer)
	local bgImage = newImageView(RES_DICT.COMMON_BG_5, 569, 317,
			{ ap = display.CENTER, tag = 437, enable = false })
	contentLayer:addChild(bgImage)
	local titleBtn = newButton(562, 615, { enable = false ,  ap = display.CENTER ,  n = RES_DICT.COMMON_BG_TITLE_2, d = RES_DICT.COMMON_BG_TITLE_2, s = RES_DICT.COMMON_BG_TITLE_2, scale9 = true, size = cc.size(256, 36), tag = 438 })
	display.commonLabelParams(titleBtn, {text = __('对战数据'), fontSize = 20, color = '#ffffff'})
	contentLayer:addChild(titleBtn)

	local rightLayout = newLayer(672, 299,
			{ ap = display.CENTER, size = cc.size(880, 575) })
	contentLayer:addChild(rightLayout)




	local rightBgImage = newImageView(RES_DICT.COMMON_BG_GOODS, 0, 0,
			{ ap = display.LEFT_BOTTOM, tag = 441, enable = false, scale9 = true, size = cc.size(880, 575) })
	rightLayout:addChild(rightBgImage)
	-- 中间小人
	local loadingCardQ = AssetsUtils.GetCartoonNode(3, 0,0)
	loadingCardQ:setScale(0.7)
	local richLabel = display.newRichLabel(672/2+100,575 -100 , { r = true  ,c ={
		{
			node = loadingCardQ ,ap = cc.p(0.05, 0.25)
		},
		fontWithColor('14',{fontSize = 35,  text = __('暂无战报') , color = '5b3c25'   })
	}

	})
	richLabel:setVisible(false)
	rightLayout:addChild(richLabel)

	local leftLayout = newLayer(27, 30,
			{ ap = display.LEFT_BOTTOM, size = cc.size(200, 557), enable = true })
	contentLayer:addChild(leftLayout)

	local buttons = {}

	local dummyTypeConf = CommonUtils.GetConfigAllMess('dummyType' , 'player')
	local countType = table.nums(dummyTypeConf)
	local buttonHeight = 85
	for i = 1, countType do
		local button =  display.newCheckBox(100,557 - ( i - 0.5) * buttonHeight , {
			n = _res('ui/home/rank/rank_btn_tab_default.png') ,
			s = _res('ui/home/rank/rank_btn_tab_select.png')
		} )
		leftLayout:addChild(button)
		buttons[#buttons+1] = button
		local buttonContentSize = button:getContentSize()
		local name = dummyTypeConf[tostring(i)].name or ""
		local nameLabel = display.newLabel(buttonContentSize.width/2 , buttonContentSize.height/2 , fontWithColor(14,{ w = 180 , hAlign = display.TAC ,text = name }))
		button:addChild(nameLabel)
		button:setTag(i)
	end



	local taskListSize = cc.size(880, 565)
	local gridView = CGridView:create(taskListSize)
	gridView:setName('gridView')
	gridView:setSizeOfCell(cc.size(870, 169))
	gridView:setColumns(1)
	gridView:setAutoRelocate(false)
	gridView:setBounceable(true)
	gridView:setPosition(5,5)
	gridView:setAnchorPoint(display.LEFT_BOTTOM)
	rightLayout:addChild(gridView, 10)
	self.viewData = {
		contentLayer            = contentLayer,
		richLabel               = richLabel,
		closeLayer              = closeLayer,
		buttons                 = buttons,
		gridView                = gridView,
		bgImage                 = bgImage,
		titleBtn                = titleBtn,
		rightLayout             = rightLayout,
		rightBgImage            = rightBgImage,
		leftLayout              = leftLayout
	}
	closeLayer:setEnabled(false)
	display.animationIn(
			view ,
			function()
				closeLayer:setEnabled(true)
		end

	)

end



function WoodenDummyRecordView:SelectType(index)
	local buttons = self.viewData.buttons
	for i = 1, #self.viewData.buttons do
		local button = buttons[i]
		button:setChecked(false)
		button:setEnabled(true)
		button:setScale(1)
	end
	buttons[index]:setChecked(true)
	buttons[index]:setEnabled(false)
	buttons[index]:setScale(1.15)
end


return WoodenDummyRecordView
