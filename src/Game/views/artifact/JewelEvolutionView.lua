--[[
	宝石进阶UI
--]]
local GameScene = require( "Frame.GameScene" )

local JewelEvolutionView = class('JewelEvolutionView', GameScene)

local function GetFullPath( imgName )
	return _res('ui/artifact/' .. imgName)
end

local RES_DIR = {
	PURCHASE_NUM_BG  = _res('ui/home/market/market_buy_bg_info.png'),
	SUB              = _res('ui/home/market/market_sold_btn_sub.png'),
	PLUS             = _res('ui/home/market/market_sold_btn_plus.png'),
	BTN_MAX			 = _res('ui/home/market/market_sold_btn_zuida.png'),
}

function JewelEvolutionView:ctor( ... )
	--创建页面
	local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 130))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    self:addChild(eaterLayer, -1)
    eaterLayer:setOnClickScriptHandler(function(sender)
        PlayAudioByClickClose()
        AppFacade.GetInstance():UnRegsitMediator("artifact.JewelEvolutionMediator")
    end)
	local function CreateView( ... )
		local size = cc.size(1138,561)
		local view = display.newLayer(display.cx, display.cy, {size = size, ap = display.CENTER})
		self:addChild(view)

		local tempLayer = display.newLayer(0, 0, {size = size, ap = display.LEFT_BOTTOM, color = cc.r4b(0), enable = true})
		view:addChild(tempLayer)

		local xx = size.width * 0.5
    	local yy = - 14
    	local closeLabel = display.newButton(xx,yy,{
    	    n = _res('ui/common/common_bg_close.png'),-- common_click_back
    	})
    	closeLabel:setEnabled(false)
    	display.commonLabelParams(closeLabel,{fontSize = 18,text = __('点击空白处关闭')})
    	view:addChild(closeLabel, 10)

		local jewelTypeBg = display.newImageView(GetFullPath('core_submit_bg_channel'), 0, 0, {ap = cc.p(0, 0)})
		view:addChild(jewelTypeBg)

		local jewelTypeBgSize = jewelTypeBg:getContentSize()
		local topShadowImg = display.newImageView(_res('ui/union/lobby/guild_img_up.png'), jewelTypeBgSize.width / 2 + jewelTypeBg:getPositionX(), jewelTypeBgSize.height, {ap = cc.p(0.5, 1)})
		view:addChild(topShadowImg, 5)

		local bottomShadowImg = display.newImageView(_res('ui/union/lobby/guild_img_down.png'), jewelTypeBgSize.width / 2 + jewelTypeBg:getPositionX(), 0, {ap = cc.p(0.5, 0)})
		view:addChild(bottomShadowImg, 5)

        local taskListSize = cc.size(193, jewelTypeBg:getContentSize().height - 6)
        local taskListCellSize = cc.size(191 , 83)
		local typeGridView = CGridView:create(taskListSize)
        typeGridView:setSizeOfCell(taskListCellSize)
        typeGridView:setColumns(1)
        typeGridView:setAutoRelocate(true)
        view:addChild(typeGridView)
        typeGridView:setAnchorPoint(cc.p(0.5, 0))
		typeGridView:setPosition(cc.p(jewelTypeBgSize.width / 2 + jewelTypeBg:getPositionX(), jewelTypeBg:getPositionY() + 3 ))
		
		local mainBg = display.newImageView(GetFullPath('core_gemstone_synthesis_bg'), size.width, 0, {ap = cc.p(1, 0)})
		view:addChild(mainBg)

		local evolutionBg = display.newImageView(GetFullPath('bag_biankuang'), size.width - 20, 34, {ap = cc.p(1, 0)})
		view:addChild(evolutionBg)

		local ruleBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_tips.png')})
		display.commonUIParams(ruleBtn, {po = cc.p(evolutionBg:getPositionX() - evolutionBg:getContentSize().width + 36,
			evolutionBg:getPositionY() + evolutionBg:getContentSize().height - 36)})
		view:addChild(ruleBtn)

		local matrixBg = display.newImageView(_res('ui/home/teamformation/concertSkillMess/biandui_lianxieskill_fazheng.png'),
			evolutionBg:getPositionX() - evolutionBg:getContentSize().width / 2, evolutionBg:getPositionY() + evolutionBg:getContentSize().height / 2 + 30)
		view:addChild(matrixBg)

		--特定合成 
		local specificButton = display.newCheckBox(0,0,
			{n = GetFullPath('comment_tab_unused'),
			s = GetFullPath('comment_tab_selected')})
		display.commonUIParams(
			specificButton, 
			{
				ap = cc.p(0.5, 0),
				po = cc.p(evolutionBg:getPositionX() - evolutionBg:getContentSize().width / 2 - 80,
					evolutionBg:getPositionY() + evolutionBg:getContentSize().height - 4)
			})
		view:addChild(specificButton)
		specificButton:setTag(2)
		specificButton:setChecked(true)

		local specificLabel = display.newLabel(specificButton:getContentSize().width * 0.5, specificButton:getContentSize().height * 0.5 ,
			fontWithColor(16,{text = __('特定合成'),w = 140 ,hAlign= display.TAC,  ap = cc.p(0.5, 0.5)}))
		specificButton:addChild(specificLabel)


		--随机合成
		local randomButton = display.newCheckBox(0,0,
			{n = GetFullPath('comment_tab_unused'),
			s = GetFullPath('comment_tab_selected')})
		display.commonUIParams(
			randomButton, 
			{
				ap = cc.p(0.5, 0),
				po = cc.p(evolutionBg:getPositionX() - evolutionBg:getContentSize().width / 2 + 80,
				 evolutionBg:getPositionY() + evolutionBg:getContentSize().height - 4)
			})
		view:addChild(randomButton)
		randomButton:setTag(1)

		local randomLabel = display.newLabel(randomButton:getContentSize().width * 0.5, randomButton:getContentSize().height * 0.5 ,
			{text = __('随机合成'),ap = cc.p(0.5, 0.5), w = 140 ,hAlign= display.TAC,fontSize = 22, color = '#f3d5c1'})
		randomButton:addChild(randomLabel)

		local centerPos = cc.p(matrixBg:getPositionX(), matrixBg:getPositionY())
		local targetCell = require('home.BackpackCell').new(cc.size(110, 110))
	    targetCell:setAnchorPoint(cc.p(0.5,0.5))
	    view:addChild(targetCell)
	    targetCell:setPosition(centerPos)
		targetCell.toggleView:setNormalImage(_res('ui/common/common_frame_goods_1.png'))
		targetCell.toggleView:setSelectedImage(_res('ui/common/common_frame_goods_1.png'))

	    local Tcells = {}
	    local POS = {
			cc.p(centerPos.x,centerPos.y + 138),
			cc.p(centerPos.x - 136,centerPos.y - 74),
			cc.p(centerPos.x + 136,centerPos.y - 74)
		}
	    for i=1,table.nums(POS) do
	    	local cell = require('home.BackpackCell').new(cc.size(110, 110))
	    	cell:setAnchorPoint(cc.p(0.5,0.5))
	    	view:addChild(cell)
	    	cell:setPosition(POS[i])
	    	cell:setScale(0.7)
	    	table.insert(Tcells,cell)
			cell.toggleView:setNormalImage(_res('ui/common/common_frame_goods_1.png'))
			cell.toggleView:setSelectedImage(_res('ui/common/common_frame_goods_1.png'))
		end
		local POS = {
			{x = centerPos.x, y = centerPos.y + 76, rotation = 0},
			{x = centerPos.x - 74, y = centerPos.y - 43, rotation = 240},
			{x = centerPos.x + 80, y = centerPos.y - 43, rotation = 120},
		}
	    local Tarrows = {}
		for i=1,table.nums(POS) do
			local arrowBg = FilteredSpriteWithOne:create()
			arrowBg:setTexture(GetFullPath('core_skill_ico_arrow'))
			arrowBg:setPosition(cc.p( POS[i].x, POS[i].y))
			arrowBg:setRotation(POS[i].rotation)
			view:addChild(arrowBg)

			local grayFilter = GrayFilter:create()
			arrowBg:setFilter(grayFilter)
			table.insert(Tarrows,arrowBg)
		end

		local compSpine = sp.SkeletonAnimation:create('effects/cardFragment/sprh.json', 'effects/cardFragment/sprh.atlas', 1)
		view:addChild(compSpine,10)
		compSpine:setPosition(centerPos)
		compSpine:setVisible(false)


		-- compSpine:registerSpineEventHandler(function (event)
		-- 	uiMgr:AddDialog('common.RewardPopup', {rewards = body.rewards ,addBackpack = false})
		-- 	compSpine:runAction(cc.RemoveSelf:create())
		-- end, sp.EventType.ANIMATION_END)

		-- 数量选择
		local goodLayer = display.newLayer(0, 0, {size = size})
		view:addChild(goodLayer)
	
		local purchaseNumBgSize = cc.size(120, 49)
		local purchaseNumBg = display.newButton(evolutionBg:getPositionX() - evolutionBg:getContentSize().width / 2, evolutionBg:getPositionY() + 90, {scale9 = true, n = RES_DIR.PURCHASE_NUM_BG, size = purchaseNumBgSize, ap = cc.p(0.5, 0.5)})
		goodLayer:addChild(purchaseNumBg)
	
		local purchaseNum = cc.Label:createWithBMFont('font/common_num_1.fnt', 1)
		purchaseNum:setAnchorPoint(cc.p(0.5, 0.5))
		purchaseNum:setHorizontalAlignment(display.TAR)
		purchaseNum:setPosition(purchaseNumBgSize.width / 2, purchaseNumBgSize.height / 2)
		purchaseNumBg:addChild(purchaseNum)
		
		--减号btn
		local btn_minus = display.newButton(0, 0, {n = RES_DIR.SUB})
		display.commonUIParams(btn_minus, {po = cc.p(purchaseNumBg:getPositionX() - purchaseNumBgSize.width / 2 + 5, purchaseNumBg:getPositionY()), ap = display.RIGHT_CENTER})
		goodLayer:addChild(btn_minus)
		btn_minus:setTag(1)
	
		--加号btn
		local btn_add = display.newButton(0, 0, {n = RES_DIR.PLUS})
		display.commonUIParams(btn_add, {po = cc.p(purchaseNumBg:getPositionX() + purchaseNumBgSize.width / 2 - 5, purchaseNumBg:getPositionY()), ap = display.LEFT_CENTER})
		goodLayer:addChild(btn_add)
		btn_add:setTag(2)

		--最大btn
	    local btn_max = display.newButton(0, 0, {n = RES_DIR.BTN_MAX})
		display.commonUIParams(btn_max, {po = cc.p(btn_add:getPositionX() + btn_add:getContentSize().width  + 15, btn_add:getPositionY()),ap = cc.p(0,0.5)})
		display.commonLabelParams(btn_max, fontWithColor(14,{text = __('最大')}))
		goodLayer:addChild(btn_max)
		btn_max:setTag(3)

		local evolutionBtn = display.newButton(0, 0, {n = _res("ui/common/common_btn_orange.png"), d = _res("ui/common/common_btn_orange_disable.png")})
		display.commonUIParams(evolutionBtn, {po = cc.p(evolutionBg:getPositionX() - evolutionBg:getContentSize().width / 2,44)})
		display.commonLabelParams(evolutionBtn,fontWithColor(14,{text = __('合成')}))
		view:addChild(evolutionBtn)

		local listSize = cc.size(473, 512)
		local ListBg = display.newImageView(_res('ui/common/common_bg_goods.png'), size.width - mainBg:getContentSize().width + 10, 34, {scale9 = true, size = listSize,ap = cc.p(0, 0)})
		view:addChild(ListBg)

		-- 全空状态
    	local kongBg = CLayout:create(listSize)
	    display.commonUIParams(kongBg, {ap = cc.p(0,0), po = cc.p(ListBg:getPositionX(), ListBg:getPositionY())})
		view:addChild(kongBg,9)
		kongBg:setVisible(false)
		
		local unlockTabletBg = display.newImageView(GetFullPath('core_lock_bg_tips'), listSize.width / 2 , listSize.height / 2)
		kongBg:addChild(unlockTabletBg)

		local unlockCostLabel = display.newLabel(170, listSize.height / 2 - 20, fontWithColor(5, {text = __("现在还没有塔可，快去塔可屋抓几只吧！"), w = 250}))
		kongBg:addChild(unlockCostLabel)

		local ListTitleBg = display.newImageView(GetFullPath('core_title'), 
			ListBg:getPositionX() + ListBg:getContentSize().width / 2, ListBg:getPositionY() + ListBg:getContentSize().height, 
			{scale9 = true, size = cc.size(listSize.width, 55),ap = cc.p(0.5, 1)})
		view:addChild(ListTitleBg)
		ListTitleBg:setVisible(false)

		--批量选择 
		local batchButton = display.newCheckBox(0,0,
			{n = _res('ui/home/teamformation/choosehero/team_btn_selection_unused.png'),
			s = _res('ui/home/teamformation/choosehero/team_btn_selection_choosed.png')})
		display.commonUIParams(
			batchButton, 
			{
				ap = cc.p(1, 0.5),
				po = cc.p(ListTitleBg:getPositionX() + ListTitleBg:getContentSize().width / 2-10, ListTitleBg:getPositionY() - ListTitleBg:getContentSize().height / 2)
			})
		view:addChild(batchButton)
		batchButton:setVisible(false)

		local batchLabel = display.newLabel(batchButton:getContentSize().width * 0.5, batchButton:getContentSize().height * 0.5 ,
			{text = __('批量选择'),fontSize = 22, color = '#ffffff', font = TTF_GAME_FONT, ttf = true})
		batchButton:addChild(batchLabel)
		batchLabel:setTag(1)

		local taskListSize = cc.size(listSize.width - 5, listSize.height - 5)
		local taskListCellSize = cc.size(taskListSize.width / 4 , 114)
		local gridView = CGridView:create(taskListSize)
		gridView:setSizeOfCell(taskListCellSize)
		gridView:setColumns(4)
		gridView:setAutoRelocate(true)
		view:addChild(gridView)
		gridView:setAnchorPoint(cc.p(0, 0))
		gridView:setPosition(cc.p(ListBg:getPositionX() + 2, ListBg:getPositionY() + 4))

		local desrLabel = display.newLabel(mainBg:getPositionX() - mainBg:getContentSize().width + 14, mainBg:getPositionY() + 18 ,
			fontWithColor(16, {text = __('三个同等级塔可，可合成一个高一等级的塔可'),ap = cc.p(0, 0.5)}))
		view:addChild(desrLabel)

		return {
			bgView 			= view,
			ListTitleBg		= ListTitleBg,
			batchButton		= batchButton,
			ruleBtn			= ruleBtn,
			typeGridView	= typeGridView,
			gridView		= gridView,
			Tcells			= Tcells,
			targetCell		= targetCell,
			Tarrows			= Tarrows,
			compSpine		= compSpine,
			specificButton	= specificButton,
			specificLabel	= specificLabel,
			randomButton	= randomButton,
			randomLabel		= randomLabel,
			goodLayer		= goodLayer,
			btn_minus		= btn_minus,
			btn_add			= btn_add,
			btn_max			= btn_max,
			btn_num 		= purchaseNumBg,
			purchaseNum 	= purchaseNum,
			kongBg			= kongBg,
			evolutionBtn	= evolutionBtn,
		}
	end
	xTry(function()
		self.viewData_ = CreateView()
	end, __G__TRACKBACK__)
end

return JewelEvolutionView