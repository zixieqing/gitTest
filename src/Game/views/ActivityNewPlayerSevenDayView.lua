--[[
每日任务系统UI
--]]
local GameScene = require( "Frame.GameScene" )

local ActivityNewPlayerSevenDayView = class('ActivityNewPlayerSevenDayView', GameScene)
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager('CardManager')
local RES_DICT = {
	LISTBG 				= 'ui/home/task/task_bg_frame_gray_2.png',
	TASK_Icon_Task 		= "ui/home/task/task_ico_daily_story.png",
	TASK_Icon_Story 	= "ui/home/task/task_ico_mainline_task.png",
	TASK_Icon_Emergent 	= "ui/home/task/task_ico_Burst_task.png",
	Btn_Normal 			= "ui/home/activity/newPlayerSevenDay/activity_btn_novice_seven_day_unlock.png",
	Btn_Pressed 		= "ui/home/activity/newPlayerSevenDay/activity_btn_novice_seven_day_select.png",
}

function ActivityNewPlayerSevenDayView:ctor( ... )
	local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 180))
	eaterLayer:setTouchEnabled(true)
	eaterLayer:setContentSize(display.size)
	eaterLayer:setAnchorPoint(cc.p(0.5, 1.0))
	eaterLayer:setPosition(cc.p(display.cx, display.height))-- - NAV_BAR_HEIGHT
	self:addChild(eaterLayer, -1)
	eaterLayer:setOnClickScriptHandler(function()
		PlayAudioByClickClose()
	   	AppFacade.GetInstance():UnRegsitMediator("ActivityNewPlayerSevenDayMediator")
	end)

	self.viewData = nil

	local function CreateTaskView( ... )
		local cview = CLayout:create(cc.size(1160,641))
		cview:setAnchorPoint(cc.p(0.5, 0.5))
		cview:setPosition(cc.p(display.size.width*0.5, display.size.height*0.5))-- - NAV_BAR_HEIGHT
		-- cview:setBackgroundColor(cc.c4b(100,100,100,100))
		self:addChild(cview)

		local frameSize = cview:getContentSize()

		local closeLabel = display.newButton(frameSize.width*0.5,0,{
		    n = _res('ui/common/common_bg_close.png'),ap = cc.p(0.5,1)-- common_click_back
		})
		closeLabel:setEnabled(false)
		display.commonLabelParams(closeLabel,{fontSize = 18,text = __('点击空白处关闭')})
		cview:addChild(closeLabel, 10)


		--屏蔽触摸穿透
		local view = display.newLayer(0,0,{color = cc.c4b(0,0,0,0),enable = true,size = frameSize, ap = cc.p(0,0)})
		cview:addChild(view,-1)

		local messLayour = CLayout:create(cc.size(335,630))
		messLayour:setAnchorPoint(cc.p(0, 0.5))
		messLayour:setPosition(cc.p(0, frameSize.height*0.5))
		messLayour:setBackgroundColor(cc.c4b(100,100,100,100))
		cview:addChild(messLayour)


		local endRewardsBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_orange.png')})
		display.commonUIParams(endRewardsBtn, {po = cc.p(messLayour:getContentSize().width * 0.5, 74)})
	    display.commonLabelParams(endRewardsBtn,fontWithColor(14,{fontSize = 18,text = __('领取最终奖励')}))
	    messLayour:addChild(endRewardsBtn)
		endRewardsBtn:setVisible(false)


		local imgHero = display.newImageView(_res('ui/home/activity/newPlayerSevenDay/activity_btn_novice_seven_day_lihui.png'))
		imgHero:setAnchorPoint(0.5, 0.5)
		imgHero:setPosition(cc.p( messLayour:getContentSize().width*0.5, messLayour:getContentSize().height*0.5 ))
		messLayour:addChild(imgHero, -1)

		-- local lsize = cc.size(330 , 630)
		-- local roleClippingNode = cc.ClippingNode:create()
		-- roleClippingNode:setContentSize(cc.size(lsize.width , lsize.height -10))
		-- roleClippingNode:setAnchorPoint(0.5, 0.5)
		-- roleClippingNode:setPosition(cc.p( messLayour:getContentSize().width*0.5, messLayour:getContentSize().height*0.5 ))
		-- roleClippingNode:setInverted(false)
		-- messLayour:addChild(roleClippingNode, -1)
		-- -- cut layer
		-- local cutLayer = display.newLayer(
		-- 	0,
		-- 	0,
		-- 	{
		-- 		size = roleClippingNode:getContentSize(),
		-- 		ap = cc.p(0, 0),
		-- 		color = '#ffcc00'
		-- 	})

		-- local imgHero = display.newImageView()
		-- imgHero:setAnchorPoint(display.LEFT_BOTTOM)

		-- local bgHero = display.newImageView()
		-- bgHero:setAnchorPoint(cc.p(0.5,0.5))
		-- -- imgHero:setVisible(false)
		-- bgHero:setPosition(cc.p(lsize.width*0.5,lsize.height*0.5))

		-- roleClippingNode:setStencil(cutLayer)
		-- roleClippingNode:addChild(imgHero,1)
		-- roleClippingNode:addChild(bgHero)

		local desImg = display.newImageView(_res('ui/home/activity/newPlayerSevenDay/activity_title_novice_seven_day.png'),
		-20, messLayour:getContentSize().height + 30,--
		{ap = cc.p(0, 1)})
		messLayour:addChild(desImg)
		local desImgSize = desImg:getContentSize()
		if desImgSize.width > 390   then
			desImg:setScale( 390 / desImgSize.width  )
		end

		local desImg1 = display.newImageView(_res('ui/home/activity/newPlayerSevenDay/activity_bg_novice_seven_day_words.png'),
		340, messLayour:getContentSize().height * 0.4,--
		{ap = cc.p(1, 1)})
		messLayour:addChild(desImg1)



		local messBg = display.newImageView(_res('ui/home/activity/newPlayerSevenDay/activity_bg_novice_seven_day_card.png'),
		messLayour:getContentSize().width *0.5, messLayour:getContentSize().height *0.5,--
		{ap = cc.p(0.5, 0.5)})
		messLayour:addChild(messBg)


		local timeBg = display.newImageView(_res('ui/home/activity/newPlayerSevenDay/activity_bg_novice_seven_day_time.png'),
		messLayour:getContentSize().width *0.5, 8,--
		{ap = cc.p(0.5, 0)})
		messLayour:addChild(timeBg)

		local timeLabel = display.newRichLabel(messLayour:getContentSize().width * 0.5 , 8,{ap = cc.p(0.5,0),c = {
					fontWithColor(10,{text =__('活动剩余时间：'),fontSize = 22, color = 'ffffff'}),
					fontWithColor(10,{text = "00：00：00",fontSize = 22, color = 'ffc600'})
				}})
		timeLabel:reloadData()
		messLayour:addChild(timeLabel,1)

		local nameBtn = display.newButton(0, 0, {n = _res('ui/home/activity/newPlayerSevenDay/activity_novice_seven_day_card_name.png')})
		display.commonUIParams(nameBtn, {po = cc.p(messLayour:getContentSize().width * 0.5, messLayour:getContentSize().height * 0.2)})
	    display.commonLabelParams(nameBtn,fontWithColor(14,{text = '我是名字',offset = cc.p(30,0) ,reqW =110}))
	    messLayour:addChild(nameBtn)

    	local qualityImg = display.newImageView(_res('ui/common/common_img_n.png'),10 , nameBtn:getContentSize().height * 0.5  )
		qualityImg:setAnchorPoint(cc.p(0,0.5))
		nameBtn:addChild(qualityImg,2)


		--添加多个按钮功能
		local buttons = {}
		for i=1,TOTAL_DAY_NUMS do
			local tabButton = display.newCheckBox(0,0,
				{n = _res(RES_DICT.Btn_Normal),
				s = _res(RES_DICT.Btn_Pressed),})

			local buttonSize = tabButton:getContentSize()
			display.commonUIParams(
				tabButton,
				{
					ap = cc.p(1, 0.5),
					po = cc.p(frameSize.width - 8,
						frameSize.height + 25 - (i) * (buttonSize.height + 8))
				})
			cview:addChild(tabButton, cview:getLocalZOrder() - 1)
			tabButton:setTag(i)
			buttons[tostring( i )] = tabButton

			--天数 ,outline = '5b3c25'
			local tabNameLabel1 = display.newLabel(utils.getLocalCenter(tabButton).x - 5 , utils.getLocalCenter(tabButton).y,
				fontWithColor(14,{fontSize = 18,color = 'ffffff',text = string.fmt(__('第_num_天'),{_num_ = CommonUtils.GetChineseNumber(i)}),ap = cc.p(0.5, 0)}))
			tabButton:addChild(tabNameLabel1)
			tabNameLabel1:setTag(101)
			tabNameLabel1:setVisible(false)
			--进度 964006
			local tabNameLabel2 = display.newLabel(utils.getLocalCenter(tabButton).x - 5 , utils.getLocalCenter(tabButton).y - 25,
				fontWithColor(8,{fontSize = 20,color = 'ffffff',text = string.format('（%d/%d）',1,1),ap = cc.p(0.5, 0)}))
			tabButton:addChild(tabNameLabel2)
			tabNameLabel2:setTag(102)
			tabNameLabel2:setVisible(false)
			--勾
		    local arrowImg = display.newImageView(_res('ui/home/activity/newPlayerSevenDay/activity_ico_novice_seven_day_arrow.png'),buttonSize.width *0.5,buttonSize.height *0.5 ,
		            {ap = cc.p(0.5, 0.5)
		        })
		    tabButton:addChild(arrowImg,6)
		    arrowImg:setTag(103)
		    arrowImg:setVisible(false)
		    --锁
		    local lockImg = display.newImageView(_res('ui/home/activity/newPlayerSevenDay/activity_btn_novice_seven_day_ico_lock.png'),buttonSize.width *0.5,buttonSize.height *0.5 ,
		            {ap = cc.p(0.5, 0.5)
		        })
		    tabButton:addChild(lockImg,6)
		    lockImg:setTag(104)
		    lockImg:setVisible(false)

		    --小红点
		    local newImg = display.newImageView(_res('ui/common/common_ico_red_point.png'),buttonSize.width - 20,buttonSize.height  ,
		            {ap = cc.p(0, 1)
		        })
		    tabButton:addChild(newImg,6)
		    newImg:setTag(789)
		    -- newImg:setVisible(false)
		end

		--滑动层背景图
		local ListBg = display.newImageView(_res('ui/home/activity/newPlayerSevenDay/activity_bg_novice_seven_day_reward.png'), frameSize.width - 118, frameSize.height*0.5,--
		{ap = cc.p(1, 0.5)})
		cview:addChild(ListBg)
		local ListBgFrameSize = ListBg:getContentSize()
		--添加列表功能
		local taskListSize = cc.size(ListBgFrameSize.width - 22, ListBgFrameSize.height - 16)
		local taskListCellSize = cc.size(683 , 140)

		local gridView = CGridView:create(taskListSize)
		gridView:setSizeOfCell(taskListCellSize)
		gridView:setColumns(1)
		gridView:setAutoRelocate(true)
		cview:addChild(gridView)
		gridView:setAnchorPoint(cc.p(1, 0.5))
		gridView:setPosition(cc.p(ListBg:getPositionX() - 10 , ListBg:getPositionY() ))
		-- gridView:setBackgroundColor(cc.c4b(0,100,0,100))

		return {
			view 			= cview,
			buttons 		= buttons,
			gridView 		= gridView,
			messLayour		= messLayour,
			imgHero 		= imgHero,
			-- bgHero 			= bgHero,
			qualityImg 		= qualityImg,
			nameLabel 		= nameBtn:getLabel(),
			endRewardsBtn	= endRewardsBtn,
			timeLabel		= timeLabel,
		}
	end
	self.viewData = CreateTaskView()
end


return ActivityNewPlayerSevenDayView
