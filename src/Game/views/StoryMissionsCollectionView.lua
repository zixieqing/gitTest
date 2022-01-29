--[[
剧情任务弹窗
--]]
-- local CommonDialog = require('common.CommonDialog')
-- local StoryMissionsCollectionView = class('StoryMissionsCollectionView', CommonDialog)

local GameScene = require( "Frame.GameScene" )

local StoryMissionsCollectionView = class('StoryMissionsCollectionView', GameScene)



local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")

--[[
--]]
function StoryMissionsCollectionView:ctor( ... )

	self.viewData = nil

    local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 100))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    self:addChild(eaterLayer, -1)


	-- view:setBackgroundColor(cc.c4b(100, 100, 100, 255))
	-- view:setScale(0.96)

	local function CreateView()
		local cview = CLayout:create(cc.size(1046,637))
		-- cview:setBackgroundColor(cc.c4b(0, 128, 0, 255))
		local size  = cview:getContentSize()


	    display.commonUIParams(cview, {ap = display.CENTER, po = cc.p(display.size.width * 0.5, display.size.height * 0.5)})
	    self:addChild(cview, 10)

	    local bg = display.newImageView(_res("ui/home/story/task_bg.png"), size.width* 0.5 - 20, size.height* 0.5)
	    cview:addChild(bg)


        local closeBtn = display.newButton(size.width, size.height, {n = _res('ui/home/story/task_btn_quit.png')})
	    display.commonUIParams(closeBtn, {ap = display.RIGHT_TOP,po = cc.p(size.width + 36, size.height - 28)})
	    cview:addChild(closeBtn,10)


		-- local tabNameLabel = display.newButton( 180, 570,{n = _res('ui/home/story/task_bg_title.png'),enable = false,ap = cc.p(0, 0)})
		-- display.commonLabelParams(tabNameLabel, {text = __('剧情任务'), fontSize = 26, color = '662f2f',offset = cc.p(-40,0)})
		-- cview:addChild(tabNameLabel)


		--主线剧情
		local storyButton = display.newCheckBox(0,0,
			{n = _res('ui/common/comment_tab_unused.png'),
			s = _res('ui/common/comment_tab_selected.png')})
		display.commonUIParams(
			storyButton, 
			{
				ap = cc.p(0, 0),
				po = cc.p(62,558)
			})
		cview:addChild(storyButton, 10)
		storyButton:setTag(1)
		storyButton:setChecked(true)


		local advancedLabel = display.newLabel(storyButton:getContentSize().width * 0.5, storyButton:getContentSize().height * 0.5 ,
			fontWithColor(16,{text = GAME_MODULE_OPEN.NEW_PLOT and __('剧情') or __('主线剧情'),ap = cc.p(0.5, 0.5)}))
		storyButton:addChild(advancedLabel)
		advancedLabel:setTag(1)

		--支线剧情  
		local branchButton = display.newCheckBox(0,0,
			{n = _res('ui/common/comment_tab_unused.png'),
			s = _res('ui/common/comment_tab_selected.png')})
		display.commonUIParams(
			branchButton, 
			{
				ap = cc.p(0, 0),
				po = cc.p(232,558)
			})
		cview:addChild(branchButton, 10)
		branchButton:setTag(2)
		branchButton:setVisible(not GAME_MODULE_OPEN.NEW_PLOT)


		local equalLabel = display.newLabel(branchButton:getContentSize().width * 0.5, branchButton:getContentSize().height * 0.5 ,
			fontWithColor(18,{fontSize = 20, text = __('支线剧情'),w= 150  , hAlign = display.TAC ,ap = cc.p(0.5, 0.5)}))
		branchButton:addChild(equalLabel)
		equalLabel:setTag(1)



		local messLayout = CLayout:create(cc.size(444,460))
		messLayout:setAnchorPoint(cc.p(0,0))
		messLayout:setPosition(cc.p(510,130))
		cview:addChild(messLayout)
		-- messLayout:setBackgroundColor(cc.c4b(0, 128, 0, 100))


		local desbg = display.newImageView(_res('ui/home/story/gut_task_bg_task_details.png'),0, 0,
		{ap = cc.p(0, 0),scale9 = true,size = messLayout:getContentSize()})
		messLayout:addChild(desbg)

		local tempLabel = display.newButton( desbg:getContentSize().width * 0.5 + 40,desbg:getContentSize().height - 40,{n = _res('ui/home/story/task_bg_title.png'),enable = false,ap = cc.p(0.5, 0)})
		display.commonLabelParams(tempLabel,fontWithColor(4,{text = GAME_MODULE_OPEN.NEW_PLOT and __('剧情描述') or __('任务描述'),offset = cc.p(-40,0)}))--{text = __('任务描述'), fontSize = 26, color = '662f2f',offset = cc.p(-40,0)}
		desbg:addChild(tempLabel)


		local desLabel = display.newLabel(desbg:getContentSize().width * 0.5,desbg:getContentSize().height - 60,
			fontWithColor(6,{text = ' ', ap = cc.p(0.5, 1),w = desbg:getContentSize().width - 100,h = desbg:getContentSize().height - 80}))
		desbg:addChild(desLabel, 6)

		local reReadBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_orange.png')})
		display.commonLabelParams(reReadBtn,fontWithColor(14,{text = __('回看')}))
		display.commonUIParams(reReadBtn, {ap = cc.p(0.5,0), po = cc.p(732 ,50)})
		cview:addChild(reReadBtn)


		local listLayout = CLayout:create(cc.size(420,550))
		listLayout:setAnchorPoint(cc.p(0,0))
		listLayout:setPosition(cc.p(55,50))
		cview:addChild(listLayout)
		-- listLayout:setBackgroundColor(cc.c4b(0, 100, 0, 255))


		--滑动层背景图 
		local ListBg = display.newImageView(_res('ui/home/story/commcon_bg_text.png'), 0,0,
		{ap = cc.p(0, 0)})	
		listLayout:addChild(ListBg)

		local ListBgFrameSize = ListBg:getContentSize()
		listLayout:setContentSize(ListBgFrameSize)
		-- 添加列表功能
		local taskListSize = cc.size(ListBgFrameSize.width , ListBgFrameSize.height - 10)
		local taskListCellSize = cc.size(taskListSize.width, 90)

		local gridView = CGridView:create(taskListSize)
		gridView:setSizeOfCell(taskListCellSize)
		gridView:setColumns(1)
		gridView:setAutoRelocate(true)
		listLayout:addChild(gridView)
		gridView:setAnchorPoint(cc.p(0, 0))
		gridView:setPosition(cc.p(ListBg:getPositionX() + 1, ListBg:getPositionY()  + 2 ))
		local ListBgSize = ListBg:getContentSize()

		local richLayout = display.newLayer(ListBgSize.width/2 , ListBgSize.height/2 , {
			ap = display.CENTER , size = ListBgSize
		})
		listLayout:addChild(richLayout , 20 )
		local qImage = display.newImageView(_res('arts/cartoon/card_q_3') , ListBgSize.width/2 , ListBgSize.height/2 + 50 , {scale = 0.7 })
		richLayout:addChild(qImage)
		local noBranchLabel = display.newLabel(ListBgSize.width/2 , 110 , fontWithColor(14 , {
			color = "#ba5c5c" ,
			fontSize = 30 ,
			ap = display.CENTER,
			hAlign= display.TAC ,
			text = __('暂无完成任务')
		}))
		richLayout:setVisible(false)
		richLayout:addChild(noBranchLabel)
		return {
			view = cview,
			gridView = gridView,
			messLayout = messLayout,
			closeBtn = closeBtn,
			reReadBtn = reReadBtn,
			desLabel = desLabel,
			branchButton = branchButton,
			storyButton = storyButton,
			richLayout = richLayout,
		}

	end

	xTry(function ( )
		self.viewData = CreateView( )
	end, __G__TRACKBACK__)

end



return StoryMissionsCollectionView
