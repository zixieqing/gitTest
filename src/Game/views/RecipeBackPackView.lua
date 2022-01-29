--[[
背包系统UI
--]]
local GameScene = require( "Frame.GameScene" )
---@class RecipeBackPackView
local RecipeBackPackView = class('RecipeRecipeBackPackView', 
    function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.RecipeRecipeBackPackView'
	node:enableNodeEvents()
	return node
    end 
)

local RES_DICT = {
	LISTBG 			= 'ui/backpack/bag_bg_frame_gray_1.png',
	DESBG 			= 'ui/home/kitchen/kitchen_seasoning_bg_word_1.png',
	DESBG_ADD       = 'ui/home/kitchen/kitchen_seasoning_bg_word_2.png',
	Btn_Normal 		= "ui/common/common_btn_sidebar_common.png",
	Btn_Pressed 	= "ui/common/common_btn_sidebar_selected.png",
	Btn_Sale 		= "ui/common/common_btn_orange.png",
	Img_cartoon 	= "ui/common/common_ico_cartoon_1.png",
	Bg_describe 	= "ui/backpack/bag_bg_describe_1.png",
	FONT_NAME       = "ui/common/common_bg_font_name.png",
	EFFECT_DOWN     = 'ui/home/kitchen/kitchen_ico_down.png',
	EFFECT_UP       = 'ui/home/kitchen/kitchen_ico_top.png',
	Btn_UnEanble    = 'ui/common/common_btn_orange_disable.png'
	
}

local BTNCOLLECT_TAG = {
	SALE = 1,
	USER_SEASONING = 1103,
	UNCOMMON_SEASONING = 1104 ,
	COMMON_SEASONING = 1105
}

function RecipeBackPackView:ctor( ... )
	local view = require("common.TitlePanelBg").new({ title = __('仓 库'), type = 11})
	local function CreateTaskView( ... )
		local size = cc.size(1046,590)
		local cview = CLayout:create(size)
		local swallowLayer = display.newLayer(size.width/2,size.height/2 , { ap = display.CENTER,size = size,enable = true ,color = cc.c4b(0,0,0,0)})
		cview:addChild(swallowLayer)
		view.viewData.view:setContentSize(size)
    	local kongBg = CLayout:create(cc.size(900,590))
	    display.commonUIParams(kongBg, {ap = cc.p(0,0), po = cc.p(0,0)})
	    view.viewData.view:addChild(kongBg,9)

		local dialogue_tips = display.newButton(0, 0, {ap = display.CENTER,n = _res('ui/common/common_bg_dialogue_tips.png')})
		display.commonUIParams(dialogue_tips, {ap = cc.p(0,0.5),po = cc.p(80,size.height * 0.5)})
		display.commonLabelParams(dialogue_tips,{text = __('当前页面暂时为空'), fontSize = 24, color = '#4c4c4c'})
        kongBg:addChild(dialogue_tips, 6)
	   
        -- 中间小人
	    local loadingCardQ = AssetsUtils.GetCartoonNode(3, dialogue_tips:getContentSize().width + 230, size.height * 0.5)
	    kongBg:addChild(loadingCardQ, 6)
	    loadingCardQ:setScale(0.7)
	    kongBg:setVisible(false)

		--添加多个按钮功能
		local buttonGroupView = CLayout:create(size)
		display.commonUIParams(buttonGroupView, {po = cc.p(size.width * 0.5, size.height * 0.5)})
		view.viewData.view:addChild(buttonGroupView, 30)

		local img_cartoon = display.newImageView(_res(RES_DICT.Img_cartoon), 0, 0)
	    display.commonUIParams(img_cartoon, {ap = cc.p(1,0), po = cc.p(70,510)})
	    buttonGroupView:addChild(img_cartoon,11)

		local taskCData = {
			{name = __('普通'), 	 tag = BTNCOLLECT_TAG.COMMON_SEASONING  },
			{name = __('精致'),  tag =  BTNCOLLECT_TAG.UNCOMMON_SEASONING},
		}
		local buttons = {}
		for i,v in ipairs(taskCData) do
			local tabButton = display.newCheckBox(0,0,
				{n = _res(RES_DICT.Btn_Normal),
				s = _res(RES_DICT.Btn_Pressed),})
			local buttonSize = tabButton:getContentSize()		
			display.commonUIParams(
				tabButton, 
				{
					ap = cc.p(1, 0.5),
					po = cc.p(size.width + 4,
						size.height + 20 - (i) * (buttonSize.height - 30)) 
				})
			buttonGroupView:addChild(tabButton,-1)
			tabButton:setTag(v.tag)
			buttons[tostring( v.tag )] = tabButton


			local tabNameLabel1 = display.newLabel(utils.getLocalCenter(tabButton).x - 5 ,utils.getLocalCenter(tabButton).y,
				{ttf = true, font = TTF_GAME_FONT, text = v.name, fontSize = 22, color = '3c3c3c', ap = cc.p(0.5, 0)})--2b2017
			tabButton:addChild(tabNameLabel1)
			tabNameLabel1:setTag(3)
		end
		--滑动层背景图 
		local ListBg = display.newImageView(_res(RES_DICT.LISTBG), 428, size.height - 10,--
		{scale9 = true, size = cc.size(450, 550),ap = cc.p(0, 1)})	--630, size.height - 20
		cview:addChild(ListBg)
		local ListBgFrameSize = ListBg:getContentSize()
		--添加列表功能
		local taskListSize = cc.size(ListBgFrameSize.width - 2, ListBgFrameSize.height - 4)
		local taskListCellSize = cc.size(taskListSize.width/4 , 114)

		local gridView = CGridView:create(taskListSize)
		gridView:setSizeOfCell(taskListCellSize)
		gridView:setColumns(4)
		gridView:setAutoRelocate(true)
		cview:addChild(gridView)
		gridView:setAnchorPoint(cc.p(0, 1.0))
		gridView:setPosition(cc.p(ListBg:getPositionX() + 4, ListBg:getPositionY() - 2))
		local moveHight = 30

		local Bg_describe = display.newImageView(_res(RES_DICT.Bg_describe),0,0)
		cview:addChild(Bg_describe,2)
		display.commonUIParams(Bg_describe, {ap = cc.p(0,0), po = cc.p(48, 104)})

		local reward_rank = display.newImageView(_res('ui/common/common_frame_goods_1.png'),0,1.0,{as = false})
		cview:addChild(reward_rank,1)
		reward_rank:setScale(0.85)
		display.commonUIParams(reward_rank, {ap = cc.p(0,0), po = cc.p(70, 435+moveHight)})

		local reward_img = display.newImageView(('ui/home/task/task_ico_active.png'),0,0)
		reward_rank:addChild(reward_img,1)
		reward_img:setPosition(cc.p(reward_rank:getContentSize().width / 2  ,reward_rank:getContentSize().height / 2 ))
		reward_img:setVisible(false)
		local pox = reward_rank:getPositionX() + reward_rank:getContentSize().width  + 25
		local poy = reward_rank:getPositionY() + reward_rank:getContentSize().height - 8
 

		local fragmentPath = _res('ui/common/common_ico_fragment_1.png')
	    local fragmentImg = display.newImageView(_res(fragmentPath), reward_rank:getContentSize().width / 2  ,reward_rank:getContentSize().height / 2,{as = false})
	    reward_rank:addChild(fragmentImg,6)
	    fragmentImg:setVisible(false)
	   
		local bgName = display.newImageView(('ui/backpack/bag_bg_font_name.png'),0,0)
		bgName:setAnchorPoint(cc.p(0,1))
		cview:addChild(bgName)
		bgName:setPosition(cc.p(pox - 10, poy -10))


		-- local DesNameLabel = display.newLabel(0 , 0,
		-- 	{text = ' ', fontSize = 24, color = 'be462a', ap = cc.p(0, 1)})
		-- cview:addChild(DesNameLabel)
		-- DesNameLabel:setPosition(cc.p(pox, poy))

		local DesNamebtn =  display.newButton(pox -10, poy -10,{n = RES_DICT.FONT_NAME ,s =  RES_DICT.FONT_NAME , d =  RES_DICT.FONT_NAME ,ap = display.LEFT_TOP})
		display.commonLabelParams(DesNamebtn,fontWithColor('10',{text = ''}) )
		cview:addChild(DesNamebtn)

		local DesNumLabel = display.newLabel(0, 0,
			{text = 'fdsfsdfdsfsdf ', fontSize = 22, color = '#7c7c7c', ap = cc.p(0, 0.5)})
		cview:addChild(DesNumLabel)
		DesNumLabel:setPosition(cc.p(pox -10, poy - 60))
		--物品描述文字背景图 
		--local desBg = display.newImageView(_res(RES_DICT.DESBG), 73, 120,{scale9 = true, size = cc.size(325, 303)})

		local desBg = display.newLayer(73, 120 ,{size = cc.size(325, 303) , ap = display.CENTER })

		display.commonUIParams(desBg, {ap = display.LEFT_BOTTOM})	

		local offWidth = desBg:getContentSize().width * 0.5 + 5
		local offHeight = desBg:getContentSize().height - 30
		local effectImage = display.newImageView(_res(RES_DICT.DESBG), offWidth /2+150 + 3 , offWidth +180+10+5)
		cview:addChild(effectImage)
		cview:addChild(desBg)
		local recipeeffectName = display.newRichLabel(offWidth - 150,offHeight + 30,{hAlign = display.TAL,ap = display.LEFT_CENTER ,r = true, c =
		{
			fontWithColor('11',{text = ""}) , 
			fontWithColor('16',{text = ""}) 
		}})
		desBg:addChild(recipeeffectName)
		local effectTables =
		{
			{name = __('味道') ,value = "" }	,
			{name = __('口感') ,value = "" }	,
			{name = __('香味') ,value = "" }	,
			{name = __('外观') ,value = "" }	,
		}
		local effectUITables = {
			{effectUI ={ } ,valueLabel = nil },
			{effectUI = { } ,valueLabel = nil },
			{effectUI ={ } ,valueLabel = nil },
			{effectUI = { } ,valueLabel = nil },
		}
		local offWidth = offWidth - 150
		local distance = 30
		for i  =1 , 4 do
			local label = display.newLabel(offWidth , offHeight - (i-1) * distance,fontWithColor('8',{ ap = display.LEFT_CENTER, text = effectTables[i].name}) )
			desBg:addChild(label)
			for j =1 , 4 do 
				local effectImage = display.newImageView(RES_DICT.EFFECT_DOWN,offWidth + 50+ j* 22  , offHeight -(i-1 ) * distance )
				desBg:addChild(effectImage)
				effectImage:setVisible(false)
				table.insert( effectUITables[i].effectUI ,#effectUITables[i].effectUI+1, effectImage) 
			end
			local labelValue = display.newLabel(offWidth+170, offHeight - (i -1) * distance ,fontWithColor('8', {ap = display.LEFT_CENTER,text  = effectTables[i].value }  ))
			 effectUITables[i].valueLabel = labelValue
			 desBg:addChild(labelValue)
		end
		local desBg2 = display.newImageView(_res(RES_DICT.DESBG_ADD),offWidth -21,  offHeight - 5 *distance +10 +5, { ap = display.LEFT_TOP} )
		desBg:addChild(desBg2)

		local desBgTwoSize = desBg2:getContentSize()
		local desBgTwoLayout  = display.newLayer(desBgTwoSize.width/2, desBgTwoSize.height/2,{ ap = display.CENTER  ,size = desBgTwoSize} )
		desBg:addChild(desBgTwoLayout)
		local listView = CListView:create(cc.size(270, desBgTwoSize.height -10 ))
		listView:setDirection(eScrollViewDirectionVertical)
		listView:setAnchorPoint(display.CENTER)
		listView:setPosition(cc.p(desBgTwoSize.width/2, desBgTwoSize.height/2))
		desBgTwoLayout:addChild(listView)
		--local recipeTips = display.newLabel(offWidth, offHeight - 5 *distance, fontWithColor('8', {ap = display.LEFT_TOP ,text = "" , w = 240  }) )
		local recipeTips = display.newRichLabel(offWidth,  offHeight - 5 *distance , { ap =  display.CENTER_TOP , w =26 , sp = 5,r = true , c = { fontWithColor(8, { text = "sdfds"})}})
		--listView:insertNodeAtLast(recipeTips)
		local contentLayout = display.newLayer(desBgTwoSize.width/2, desBgTwoSize.height/2, { ap = display.CENTER,size = desBgTwoSize })
		listView:insertNodeAtLast(contentLayout)
		contentLayout:addChild(recipeTips)
		local obtainWayBtn = display.newButton(0, 0, {n = _res(RES_DICT.Btn_Sale)})
		display.commonUIParams(obtainWayBtn, {ap = cc.p(0,0), po = cc.p(73,32)})
		display.commonLabelParams(obtainWayBtn,fontWithColor(14,{text = __('获取途径')}))
		obtainWayBtn:setTag(BTNCOLLECT_TAG.SALE)
		cview:addChild(obtainWayBtn)

		local getBtn = display.newButton(0, 0, {n = _res(RES_DICT.Btn_Sale), s = _res(RES_DICT.Btn_UnEanble) , d = _res(RES_DICT.Btn_UnEanble) })
		display.commonUIParams(getBtn, {ap = cc.p(0,0), po = cc.p(258,32)})
		display.commonLabelParams(getBtn,fontWithColor(14,{text = __('使用')}))
		getBtn:setTag(BTNCOLLECT_TAG.USER_SEASONING)
		cview:addChild(getBtn)

		view:AddContentView(cview)

		return {
			bgView 			= cview,
			-- tabNameLabel 	= tabNameLabel,
			buttons 		= buttons,
			gridView 		= gridView,
			ListBg 			= ListBg,
			reward_rank		= reward_rank,
			reward_img 		= reward_img,
			DesNamebtn     = DesNamebtn ,
			DesNumLabel 	= DesNumLabel,
			obtainWayBtn	= obtainWayBtn,
			getBtn			= getBtn,
			kongBg 			= kongBg,
			img_cartoon 	= img_cartoon,
			recipeeffectName = recipeeffectName,
			fragmentImg 	= fragmentImg,
			effectUITables = effectUITables ,
			closeView      =  view.viewData.eaterLayer ,
			bgLayout       =   view ,
			recipeTips = recipeTips ,
			listView = listView ,
			contentLayout = contentLayout
		}
	end
	xTry(function()
		self.viewData_ = CreateTaskView()
	end, __G__TRACKBACK__)
	display.commonUIParams(view, {ap = display.CENTER, po = cc.p(display.cx, display.cy)})
	self:addChild(view)
	local action = cc.Sequence:create(cc.DelayTime:create(0.1),cc.MoveBy:create(0.2,cc.p(0, - 500)))
	self.viewData_.img_cartoon:runAction(action)
end


return RecipeBackPackView
