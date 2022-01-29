--[[
剧情任务弹窗
--]]
-- local CommonDialog = require('common.CommonDialog')
-- local StoryMissionsView = class('StoryMissionsView', CommonDialog)

local GameScene = require( "Frame.GameScene" )

local StoryMissionsView = class('StoryMissionsView', GameScene)



local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")

--[[
--]]
function StoryMissionsView:ctor( ... )

	self.viewData = nil

	local function CloseSelf(sender)
        PlayAudioByClickClose()
        AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = "StoryMissionsMediator"},
			{name = "HomeMediator"})
            GuideUtils.DispatchStepEvent()
	end

    local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 100))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    self:addChild(eaterLayer, -1)
	eaterLayer:runAction(
			cc.Sequence:create(
			cc.DelayTime:create(0.05) ,
			cc.CallFunc:create(function()
				if not GuideUtils.IsGuiding() then
					eaterLayer:setOnClickScriptHandler(CloseSelf)
				end
			end)
		)
	)

	-- view:setBackgroundColor(cc.c4b(100, 100, 100, 255))
	-- view:setScale(0.96)

	local function CreateView()

		local cview = CLayout:create(cc.size(1046,637))
		-- cview:setBackgroundColor(cc.c4b(0, 128, 0, 255))
        cview:setName('ContentView')

		local size  = cview:getContentSize()
		local swallowLayer = display.newLayer(size.width/2 , size.height/2 , { ap = display.CENTER , color = cc.c4b(0,0,0,0) , enable =true , size = size })
		cview:addChild(swallowLayer)

	    display.commonUIParams(cview, {ap = display.CENTER, po = cc.p(display.size.width * 0.5, display.size.height * 0.5)})
	    self:addChild(cview, 10)

	    local bg = display.newImageView(_res("ui/home/story/task_bg.png"), size.width* 0.5 - 20, size.height* 0.5)
	    cview:addChild(bg)


        local closeBtn = display.newButton(size.width, size.height, {n = _res('ui/home/story/task_btn_quit.png')})
	    display.commonUIParams(closeBtn, {ap = display.RIGHT_TOP,po = cc.p(size.width + 36, size.height - 28)})
        closeBtn:setName('CloseBtn')
	    cview:addChild(closeBtn,10)


		local tabNameLabel = display.newButton( 180, 570,{n = _res('ui/home/story/task_bg_title.png'),enable = false,ap = cc.p(0, 0)})
		display.commonLabelParams(tabNameLabel, {text = __('剧情任务'), fontSize = 26, color = '662f2f',offset = cc.p(-40,0)})
		cview:addChild(tabNameLabel)

		local messLayout = CLayout:create(cc.size(444,550))
		messLayout:setAnchorPoint(cc.p(0,0))
		messLayout:setPosition(cc.p(521,40))
		cview:addChild(messLayout)
		-- messLayout:setBackgroundColor(cc.c4b(0, 128, 0, 255))


		local listLayout = CLayout:create(cc.size(420,550))
		listLayout:setAnchorPoint(cc.p(0,0))
		listLayout:setPosition(cc.p(55,30))
		cview:addChild(listLayout)
		-- listLayout:setBackgroundColor(cc.c4b(0, 100, 0, 255))
		listLayout:setName('listLayout')
		--
		local storyBtn = display.newButton(0, 0, {n = _res('ui/home/story/gut_task_btn_thread.png')})
		display.commonUIParams(storyBtn, {ap = cc.p(0,1), po = cc.p(10,520)})
		display.commonLabelParams(storyBtn,fontWithColor(16,{color = 'b80000',fontSize = 22, text = '',ap = cc.p(0, 0.5),offset = cc.p(-170,0)}))
		listLayout:addChild(storyBtn,1)
		storyBtn:setName('storyBtn')
        local sHeight = storyBtn:getContentSize().height
        local typeLabel = display.newLabel(14, sHeight - 8, fontWithColor(16, {text = '', ap = display.LEFT_TOP}))
        storyBtn:addChild(typeLabel,5)

        local labelName = display.newLabel(24, sHeight - 34,fontWithColor(15,{ color = '5c5c5c',text = '', w = 300, h = 120}))
        display.commonUIParams(labelName, {ap = cc.p(0, 1)})
        storyBtn:addChild(labelName,5)

		local storySelectImg = display.newImageView(_res('ui/home/story/gut_task_btn_select.png'),0,0,{as = false})
	    storySelectImg:setPosition(cc.p(storyBtn:getContentSize().width * 0.5,storyBtn:getContentSize().height * 0.5))
	    storyBtn:addChild(storySelectImg)

	    local redPointImg = display.newImageView(_res('ui/common/common_ico_red_point.png'),0,0,{as = false})
	    redPointImg:setPosition(cc.p(storyBtn:getContentSize().width - 5,storyBtn:getContentSize().height - 16 ))
	    storyBtn:addChild(redPointImg,10)
	    redPointImg:setScale(0.75)
	    redPointImg:setVisible(false)

		local npcImg = display.newImageView(_res(CommonUtils.GetNpcIconPathById('role_1',3)), storyBtn:getContentSize().width , storyBtn:getContentSize().height*0.5,
		{ap = cc.p(1, 0.5)})
		storyBtn:addChild(npcImg)
		npcImg:setVisible(false)

		--滑动层背景图
		local ListBg = display.newImageView(_res('ui/home/story/commcon_bg_text.png'), 0,20,
		{ap = cc.p(0, 0)})
		listLayout:addChild(ListBg)

		local ListBgFrameSize = ListBg:getContentSize()
		-- 添加列表功能
		local taskListSize = cc.size(ListBgFrameSize.width , 406)
		local taskListCellSize = cc.size(taskListSize.width, 90)

		local gridView = CGridView:create(taskListSize)
		gridView:setSizeOfCell(taskListCellSize)
		gridView:setColumns(1)
		gridView:setAutoRelocate(true)
		listLayout:addChild(gridView)
		gridView:setAnchorPoint(cc.p(0, 0))
		gridView:setPosition(cc.p(ListBg:getPositionX() + 1, ListBg:getPositionY()  + 2 + 6))
		-- gridView:setBackgroundColor(cc.c4b(0, 128, 0, 100))

		return {
			view = cview,
			gridView = gridView,
			storyBtn = storyBtn,
            typeLabel = typeLabel,
            typeName = labelName,
			storySelectImg = storySelectImg,
			messLayout = messLayout,
			redPointImg = redPointImg,
			closeBtn = closeBtn,
			npcImg = npcImg,
		}

	end

	xTry(function ( )
		self.viewData = CreateView( )
		self.viewData.closeBtn:setOnClickScriptHandler(CloseSelf)
	end, __G__TRACKBACK__)

end



return StoryMissionsView
