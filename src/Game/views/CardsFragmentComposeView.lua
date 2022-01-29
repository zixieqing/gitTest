--[[
卡牌碎片融合UI
--]]

local GameScene = require( "Frame.GameScene" )

local CardsFragmentComposeView = class('CardsFragmentComposeView', GameScene)
local GoodPurchaseNode = require('common.GoodPurchaseNode')

local RES_DICT = {
	LISTBG 			= 'ui/backpack/bag_bg_frame_gray_1.png',
	DESBG 			= _res('ui/home/teamformation/concertSkillMess/biandui_lianxieskill_fazheng.png'),	
	Btn_Normal 		= "ui/common/common_btn_sidebar_common.png",
	Btn_Pressed 	= "ui/common/common_btn_sidebar_selected.png",
	Btn_Sale 		= "ui/common/common_btn_orange_disable.png",
	Img_cartoon 	= "ui/common/common_ico_cartoon_1.png",
	Bg_describe 	= "ui/backpack/bag_bg_describe_1.png",
	Fragment_empty 	= "ui/common/compose_ico_fragment_empty.png",

}


function CardsFragmentComposeView:ctor( ... )
    -- local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 100))
    -- eaterLayer:setTouchEnabled(true)
    -- eaterLayer:setContentSize(display.size)
    -- eaterLayer:setAnchorPoint(cc.p(0.5, 1.0))
    -- eaterLayer:setPosition(cc.p(display.cx, display.height))-- - NAV_BAR_HEIGHT
    -- self:addChild(eaterLayer, -1)

	--创建页面
	local view = require("common.TitlePanelBg").new({ title = __('碎片融合'), type = 11, cb = function()
        PlayAudioByClickClose()
        AppFacade.GetInstance():UnRegsitMediator("CardsFragmentComposeMediator")
    end})
	display.commonUIParams(view, {ap = display.CENTER, po = cc.p(display.cx, display.cy)})
	self:addChild(view)
	local function CreateTaskView( ... )
		local size = cc.size(1046,590)
		local cview = CLayout:create(size)


        local bgSize = cc.size(display.width, 80)
        local moneyNode = CLayout:create(bgSize)
        display.commonUIParams(moneyNode, {ap = display.CENTER_TOP, po = cc.p(display.cx, display.height)})
        self:addChild(moneyNode,100)

        -- top icon
        local imageImage = display.newImageView(_res('ui/home/nmain/main_bg_money.png'),0,0,{enable = false,
        scale9 = true, size = cc.size(680,54)})
        display.commonUIParams(imageImage,{ap = cc.p(1.0,1.0), po = cc.p(display.width,80)})
        moneyNode:addChild(imageImage)
        local moneyNods = {}
        local iconData =  {HP_ID, GOLD_ID, DIAMOND_ID}
        for i,v in ipairs(iconData) do
            local isShowHpTips = (v == HP_ID) and 1 or -1
            local purchaseNode = GoodPurchaseNode.new({id = v, animate = true, isShowHpTips = isShowHpTips})
            display.commonUIParams(purchaseNode,
            {ap = cc.p(1, 0.5), po = cc.p(bgSize.width - 20 - (( table.nums(iconData) - i) * (purchaseNode:getContentSize().width + 16)), imageImage:getPositionY()- 26)})
            moneyNode:addChild(purchaseNode, 5)
            purchaseNode:setName('purchaseNode' .. i)
            purchaseNode.viewData.touchBg:setTag(checkint(v))
            moneyNods[tostring( v )] = purchaseNode
        end




    	local kongBg = CLayout:create(cc.size(900,484))
		-- kongBg:setBackgroundColor(cc.c4b(100,100,100,100))
	    display.commonUIParams(kongBg, {ap = cc.p(0,0), po = cc.p(0,0)})
	    view.viewData.view:addChild(kongBg,9)

		local dialogue_tips = display.newButton(0, 0, {ap = display.CENTER,n = _res('ui/common/common_bg_dialogue_tips.png')})
		display.commonUIParams(dialogue_tips, {ap = cc.p(0,0.5),po = cc.p(80,size.height * 0.5)})
		display.commonLabelParams(dialogue_tips,{text = __('无飨灵碎片'), fontSize = 24, color = '#4c4c4c'})
        kongBg:addChild(dialogue_tips, 6)
	   
        -- 中间小人
	    local loadingCardQ = AssetsUtils.GetCartoonNode(3, dialogue_tips:getContentSize().width + 230, size.height * 0.5)
	    kongBg:addChild(loadingCardQ, 6)
	    loadingCardQ:setScale(0.7)



	    -- kongBg:setVisible(false)

		--添加多个按钮功能
		local buttonGroupView = CLayout:create(size)
		display.commonUIParams(buttonGroupView, {po = cc.p(size.width * 0.5, size.height * 0.5)})
		view.viewData.view:addChild(buttonGroupView, 30)

		local img_cartoon = display.newImageView(_res(RES_DICT.Img_cartoon), 0, 0)
	    display.commonUIParams(img_cartoon, {ap = cc.p(1,0), po = cc.p(70,510)})
	    buttonGroupView:addChild(img_cartoon,11)

		local checkBtn = display.newCheckBox(428 ,550  , { ap = display.LEFT_CENTER ,  n = _res('ui/common/common_btn_check_default') ,s =  _res('ui/common/common_btn_check_selected') } )
		cview:addChild(checkBtn)
		local tempLabel = display.newLabel(428, 550  ,
			fontWithColor(6,{text = __('放入稀有度相同的飨灵碎片') , w = 300 ,ap = display.LEFT_CENTER }))
		cview:addChild(tempLabel)


		local ruleBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_tips.png')})
		display.commonUIParams(ruleBtn, {ap = cc.p(0,0), po = cc.p(80,468)})
		cview:addChild(ruleBtn,4)

		local ruleLabel = display.newLabel( 135 , 485 , fontWithColor(6, {ap = display.LEFT_BOTTOM , text = __('规则说明')}))

		cview:addChild(ruleLabel,4)
		--批量融合
		local batchButton = display.newCheckBox(0,0,
			{n = _res('ui/home/teamformation/choosehero/team_btn_selection_unused.png'),
			s = _res('ui/home/teamformation/choosehero/team_btn_selection_choosed.png')})
		display.commonUIParams(
			batchButton, 
			{
				ap = cc.p(1, 0),
				po = cc.p(size.width-180,528)
			})
		cview:addChild(batchButton, 10)


		local batchLabel = display.newLabel(batchButton:getContentSize().width * 0.5, batchButton:getContentSize().height * 0.5 ,
			fontWithColor(14,{text = __('批量融合'),ap = cc.p(0.5, 0.5),fontSize = 22}))
		batchButton:addChild(batchLabel)
		batchLabel:setTag(1)


		--滑动层背景图 
		local ListBg = display.newImageView(_res(RES_DICT.LISTBG), 428, 37,--
		{scale9 = true, size = cc.size(450, 484),ap = cc.p(0, 0)})	--630, size.height - 20
		cview:addChild(ListBg)
		local ListBgFrameSize = ListBg:getContentSize()
		--添加列表功能
		local taskListSize = cc.size(ListBgFrameSize.width - 2, ListBgFrameSize.height - 4)
		local taskListCellSize = cc.size(taskListSize.width/4 , 114)

		local gridView = CGridView:create(taskListSize)
		gridView:setSizeOfCell(taskListCellSize)
		gridView:setColumns(4)
		gridView:setAutoRelocate(true)
		cview:addChild(gridView,1)
		gridView:setAnchorPoint(cc.p(0, 0))
		gridView:setPosition(cc.p(ListBg:getPositionX() + 4, ListBg:getPositionY() - 2))


		local emptyLayer  =display.newLayer(ListBg:getPositionX() + 4, ListBg:getPositionY() - 2 , {ap = display.LEFT_BOTTOM , size = taskListSize})
		cview:addChild(emptyLayer,10)
		emptyLayer:setVisible(false)
		--emptyLayer:setVisible(false)

		local emptydialog = display.newButton(0, 0, {ap = display.CENTER,n = _res('ui/common/common_bg_dialogue_tips.png')})
		display.commonUIParams(emptydialog, {ap = cc.p(0,0.5),po = cc.p(80 -58 ,size.height * 0.5 -64 )})
		display.commonLabelParams(emptydialog,{text = __('没有碎片了......'), fontSize = 28, color = '#4c4c4c'})
		emptyLayer:addChild(emptydialog, 6)
		emptydialog:setScale(0.7)

		local emptyImage = display.newImageView(RES_DICT.Fragment_empty, 290, size.height * 0.5 -44, { ap = display.LEFT_CENTER   })
		emptyLayer:addChild(emptyImage)
		-- --scrollbar的功能
		-- local scrollBarBg = ccui.Scale9Sprite:create(_res('ui/home/card/rold_bg_gliding_orange'))
		-- local scrollBarBtn = cc.Sprite:create(_res('ui/home/card/rold_gliding_orange'))
		-- local scrollBar = FTScrollBar:create(scrollBarBg, scrollBarBtn)
		-- scrollBar:attachToUIScrollView(gridView)


		--进阶融合 
		local advancedButton = display.newCheckBox(0,0,
			{n = _res('ui/common/comment_tab_unused.png'),
			s = _res('ui/common/comment_tab_selected.png')})
		display.commonUIParams(
			advancedButton, 
			{
				ap = cc.p(0, 0),
				po = cc.p(62,528)
			})
		cview:addChild(advancedButton, 10)
		advancedButton:setTag(2)
		advancedButton:setChecked(true)


		local advancedLabel = display.newLabel(advancedButton:getContentSize().width * 0.5, advancedButton:getContentSize().height * 0.5 ,
			fontWithColor(14,{text = __('进阶融合'),ap = cc.p(0.5, 0.5)}))
		advancedButton:addChild(advancedLabel)


		--同阶融合
		local equalButton = display.newCheckBox(0,0,
			{n = _res('ui/common/comment_tab_unused.png'),
			s = _res('ui/common/comment_tab_selected.png')})
		display.commonUIParams(
			equalButton, 
			{
				ap = cc.p(0, 0),
				po = cc.p(232,528)
			})
		cview:addChild(equalButton, 10)
		equalButton:setTag(1)


		local equalLabel = display.newLabel(equalButton:getContentSize().width * 0.5, equalButton:getContentSize().height * 0.5 ,
			fontWithColor(14,{text = __('同阶融合'),ap = cc.p(0.5, 0.5)}))
		equalButton:addChild(equalLabel)



		local Bg_describe = display.newImageView(_res(RES_DICT.Bg_describe),0,0)
		cview:addChild(Bg_describe,2)
		display.commonUIParams(Bg_describe, {ap = cc.p(0,0), po = cc.p(48, 57)})


		-- batchFragmentImg chooseLabel batchAllNum
		local batchFragmentImg = display.newImageView(_res('ui/common/common_ico_fragment_1.png'), Bg_describe:getContentSize().width + 2, Bg_describe:getContentSize().height + 2)
		display.commonUIParams(batchFragmentImg, {ap = cc.p(0,0)})	
		Bg_describe:addChild(batchFragmentImg)
		batchFragmentImg:setRotation(180)
		batchFragmentImg:setVisible(false)
		
		local chooseLabel = display.newLabel(Bg_describe:getContentSize().width - 22, Bg_describe:getContentSize().height - 34  ,
			fontWithColor(6,{text = __('已选：'),ap = cc.p(1, 0)}))
		Bg_describe:addChild(chooseLabel)
		chooseLabel:setVisible(false)

		local batchAllNum = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '')--
	    batchAllNum:setAnchorPoint(cc.p(1, 0))
	    batchAllNum:setHorizontalAlignment(display.TAR)
	    batchAllNum:setPosition(Bg_describe:getContentSize().width - 20,Bg_describe:getContentSize().height - 58)
	    Bg_describe:addChild(batchAllNum,4)
	    batchAllNum:setString('0')
	    batchAllNum:setVisible(false)

		local fazhenBg = display.newImageView(_res(RES_DICT.DESBG), Bg_describe:getContentSize().width*0.5, Bg_describe:getContentSize().height*0.5 + 10)
		display.commonUIParams(fazhenBg, {ap = cc.p(0.5,0.5)})	
		Bg_describe:addChild(fazhenBg)


    	local showChooseLayout = CLayout:create(fazhenBg:getContentSize())
		-- showChooseLayout:setBackgroundColor(cc.c4b(100,100,100,100))
	    display.commonUIParams(showChooseLayout, {ap = cc.p(0.5,0.5)})
	    showChooseLayout:setPosition(cc.p(fazhenBg:getPositionX()+48,fazhenBg:getPositionY()+57))
	    cview:addChild(showChooseLayout,5)

		local desBatchLabel = display.newLabel(showChooseLayout:getContentSize().width * 0.5, - 20 ,
			fontWithColor(6,{text = (' '),ap = cc.p(0.5, 0)}))
		showChooseLayout:addChild(desBatchLabel)



	    local Tcells = {}
	    local POST = {cc.p(180,308),cc.p(301,200),cc.p(252,50),cc.p(92,50),cc.p(41,200)}
	    for i=1,5 do
	    	local cell = require('home.BackpackCell').new(cc.size(108, 115))
	    	cell:setAnchorPoint(cc.p(0.5,0.5))
	    	showChooseLayout:addChild(cell)
	    	cell:setPosition(POST[i])
	    	cell:setScale(0.7)
	    	table.insert(Tcells,cell)
	    	-- celli:setTag(i)

			local addImg = display.newImageView(_res('ui/common/maps_fight_btn_pet_add.png'), cell:getContentSize().width*0.5, cell:getContentSize().height*0.5)
			display.commonUIParams(addImg, {ap = cc.p(0.5,0.5)})	
			cell:addChild(addImg)
			addImg:setTag(6)

	    end

    	local targetCell = require('home.BackpackCell').new(cc.size(108, 115))
    	targetCell:setAnchorPoint(cc.p(0.5,0.5))
    	showChooseLayout:addChild(targetCell)
    	targetCell:setPosition(cc.p(showChooseLayout:getContentSize().width* 0.5,showChooseLayout:getContentSize().height* 0.5))


		targetCell.fragmentImg:setVisible(true)
		targetCell.fragmentImg:setTexture(_res('ui/common/compose_ico_fragment_unkown.png'))
		targetCell.toggleView:setNormalImage(_res('ui/common/compose_frame_unkown.png'))
		targetCell.toggleView:setSelectedImage(_res('ui/common/compose_frame_unkown.png'))



		local tempImg = display.newImageView(_res('ui/common/compose_ico_unkown.png'), targetCell:getContentSize().width*0.5, targetCell:getContentSize().height*0.5)
		display.commonUIParams(tempImg, {ap = cc.p(0.5,0.5)})	
		targetCell:addChild(tempImg)


		local composeBtn = display.newButton(0, 0, {n = _res(RES_DICT.Btn_Sale)})
		display.commonUIParams(composeBtn, {ap = cc.p(0,0), po = cc.p(80,37)})
		display.commonLabelParams(composeBtn,fontWithColor(14,{text = __('融合')}))
		cview:addChild(composeBtn,4)


		local tempImg = display.newImageView(_res('ui/common/commcon_bg_text.png'),192,43,{ap = cc.p(0,0),scale9 = true,size = cc.size(200,50) })
		cview:addChild(tempImg,3)

		local castNum = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '')--
	    castNum:setAnchorPoint(cc.p(1, 0))
	    castNum:setHorizontalAlignment(display.TAR)
	    castNum:setPosition(324,50)
	    cview:addChild(castNum,4)
	    castNum:setString('0')

	    local goldIcon = display.newNSprite(_res(CommonUtils.GetGoodsIconPathById(GOLD_ID)), 380, 50)
		goldIcon:setScale(0.25)
		goldIcon:setAnchorPoint(cc.p(1, 0))
		cview:addChild(goldIcon, 5)


		view:AddContentView(cview)



		return {
			bgView 			= cview,
			gridView 		= gridView,
			ListBg 			= ListBg,

			composeBtn			= composeBtn,
			kongBg 			= kongBg,
			img_cartoon 	= img_cartoon,


			Tcells 			= Tcells,
			targetCell 		= targetCell,

			castNum 		= castNum,
			checkBtn        = checkBtn ,

			advancedButton  = advancedButton,
			equalButton		= equalButton,
			batchButton 	= batchButton,

			desBatchLabel 	= desBatchLabel,
			ruleBtn 		= ruleBtn,

			batchFragmentImg = batchFragmentImg,
			chooseLabel		 = chooseLabel,
			batchAllNum		 = batchAllNum,

			showChooseLayout = showChooseLayout,
			emptyLayer       = emptyLayer ,


			moneyNods = moneyNods,
		}
	end
	xTry(function()
		self.viewData_ = CreateTaskView()
	end, __G__TRACKBACK__)
	self:setName("CardsFragmentComposeView")
	local action = cc.Sequence:create(cc.DelayTime:create(0.1),cc.MoveBy:create(0.2,cc.p(0, - 500)))
	self.viewData_.img_cartoon:runAction(action) 
end


return CardsFragmentComposeView
