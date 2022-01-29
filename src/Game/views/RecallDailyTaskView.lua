--[[
	被召回7天任务UI
--]]
local GameScene = require( "Frame.GameScene" )

local RecallDailyTaskView = class('RecallDailyTaskView', GameScene)

local RES_DICT = {
	Btn_Normal 			= "ui/home/activity/newPlayerSevenDay/activity_btn_novice_seven_day_default.png",
	Btn_Pressed 		= "ui/home/activity/newPlayerSevenDay/activity_btn_novice_seven_day_select.png",
}

local function GetFullPath( imgName )
	return _res('ui/home/recall/' .. imgName)
end

function RecallDailyTaskView:ctor( ... )
    local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 130))
	eaterLayer:setTouchEnabled(true)
	eaterLayer:setContentSize(display.size)
	eaterLayer:setAnchorPoint(cc.p(0.5, 1.0))
	eaterLayer:setPosition(cc.p(display.cx, display.height))-- - NAV_BAR_HEIGHT
	self:addChild(eaterLayer, -1)
	eaterLayer:setOnClickScriptHandler(function() 
		PlayAudioByClickClose()
	   	AppFacade.GetInstance():UnRegsitMediator("RecallDailyTaskMediator")
    end)
    
    local function CreateView( ... )
		local cview = CLayout:create(cc.size(1160,641))
		cview:setAnchorPoint(cc.p(0.5, 0.5))
		cview:setPosition(cc.p(display.size.width*0.5, display.size.height*0.5))-- - NAV_BAR_HEIGHT
		-- cview:setBackgroundColor(cc.c4b(100,100,100,100))
		self:addChild(cview, 2)

		local frameSize = cview:getContentSize()

        local tempLayer = CColorView:create(cc.c4b(0, 0, 0, 0))
        tempLayer:setTouchEnabled(true)
        tempLayer:setContentSize(cc.size(1040, 640))
        display.commonUIParams(tempLayer, {ap = display.LEFT_CENTER, po = cc.p(display.cx - frameSize.width / 2, display.cy)})
        self:addChild(tempLayer)

		local closeLabel = display.newButton(frameSize.width*0.5,0,{
		    n = _res('ui/common/common_bg_close.png'),ap = cc.p(0.5,1)-- common_click_back
		})
		closeLabel:setEnabled(false)
		display.commonLabelParams(closeLabel,{fontSize = 18,text = __('点击空白处关闭')})
		cview:addChild(closeLabel, 10)
            
        -- 左侧
        local messLayour = CLayout:create(cc.size(335,630))
        messLayour:setAnchorPoint(cc.p(0, 0.5))
        messLayour:setPosition(cc.p(0, frameSize.height*0.5))
        cview:addChild(messLayour)

        local endRewardsBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_orange.png')})
        display.commonUIParams(endRewardsBtn, {po = cc.p(messLayour:getContentSize().width * 0.5, messLayour:getContentSize().height * 0.5 + 40)})
        display.commonLabelParams(endRewardsBtn,fontWithColor(14,{text = __('领取奖励')}))
        messLayour:addChild(endRewardsBtn)
        endRewardsBtn:setVisible(false)

        local imgHero = display.newImageView(GetFullPath('activity_btn_novice_seven_day_6'))
        imgHero:setAnchorPoint(0.5, 0.5)
        imgHero:setPosition(cc.p( messLayour:getContentSize().width*0.5, messLayour:getContentSize().height*0.5 ))	
        messLayour:addChild(imgHero, -1)
        
        local messBg = display.newImageView(_res('ui/home/activity/newPlayerSevenDay/activity_bg_novice_seven_day_card.png'), 
        messLayour:getContentSize().width *0.5, messLayour:getContentSize().height *0.5,
        {ap = cc.p(0.5, 0.5)})	
        messLayour:addChild(messBg)
        
		local messTitleBg = display.newImageView(GetFullPath('recall_bg_title'), 1, messLayour:getContentSize().height - 18, {ap = display.LEFT_TOP})
        messLayour:addChild(messTitleBg)
        
		local messTitleLabel = display.newLabel(10, 18, fontWithColor('14', {text = __('回归福利，不负初心'), reqW = 290 ,  color = '#ffc731', outline = '#5b3c25', ap = display.LEFT_CENTER}))
        messTitleBg:addChild(messTitleLabel)

        local timeBg = display.newImageView(GetFullPath('recall_7tian_bg_choice'), 
            messLayour:getContentSize().width *0.5, 5, {ap = cc.p(0.5, 0)})	
        messLayour:addChild(timeBg)
        
        local leftLabel = display.newLabel(utils.getLocalCenter(messLayour).x+40  , 22,
            fontWithColor('16', {text = __('活动剩余时间:') , reqW = 200 , ap = display.RIGHT_CENTER  }))
        messLayour:addChild(leftLabel)

        local timeLabel = display.newLabel(utils.getLocalCenter(messLayour).x + 40, 22,
            fontWithColor('10', {fontSize = 22, text = '--', ap = display.LEFT_CENTER}))
        messLayour:addChild(timeLabel)

        local text =  string.gsub(__('完成全部任务可选择一张UR飨\n灵领取') , '\n' , " ")
        text = text or __('完成全部任务可选择一张UR飨\n灵领取')
		local desrLabel = display.newLabel(messLayour:getContentSize().width * 0.5, 284, fontWithColor('16', {text =  text   , w= 290 }))
        messLayour:addChild(desrLabel)

        --滑动层背景图
        local ListBg = display.newImageView(_res('ui/home/activity/newPlayerSevenDay/activity_bg_novice_seven_day_reward.png'), frameSize.width - 118, frameSize.height*0.5,--
        {ap = cc.p(1, 0.5)})
        cview:addChild(ListBg)
        local ListBgFrameSize = ListBg:getContentSize()
        --添加列表功能
        local taskListSize = cc.size(ListBgFrameSize.width - 22, ListBgFrameSize.height - 18)
        local taskListCellSize = cc.size(683 , 140)

        local gridView = CGridView:create(taskListSize)
        gridView:setSizeOfCell(taskListCellSize)
        gridView:setColumns(1)
        gridView:setAutoRelocate(true)
        cview:addChild(gridView)
        gridView:setAnchorPoint(cc.p(1, 0.5))
        gridView:setPosition(cc.p(ListBg:getPositionX() - 10 , ListBg:getPositionY() + 2 ))
		return {
            view            = cview,
            gridView        = gridView,
            buttons         = {},
            imgHero         = imgHero,
            endRewardsBtn   = endRewardsBtn,
            timeLabel       = timeLabel,
		}
	end
	xTry(function()
		self.viewData_ = CreateView()
	end, __G__TRACKBACK__)
end

function RecallDailyTaskView:CreateTab( index )
    local cview = self.viewData_.view
    local frameSize = cview:getContentSize()
    local tabButton = display.newCheckBox(0,0,
        {n = _res(RES_DICT.Btn_Normal),
        s = _res(RES_DICT.Btn_Pressed),})

    local buttonSize = tabButton:getContentSize()
    display.commonUIParams(
        tabButton, 
        {
            ap = cc.p(1, 0.5),
            po = cc.p(frameSize.width - 8,
                frameSize.height + 25 - (index) * (buttonSize.height + 8))
        })
    cview:addChild(tabButton, cview:getLocalZOrder() - 1)
    tabButton:setTag(index)
    self.viewData_.buttons[tostring( index )] = tabButton
    
    --天数 ,outline = '5b3c25'
    local tabNameLabel1 = display.newLabel(utils.getLocalCenter(tabButton).x - 5 , utils.getLocalCenter(tabButton).y,
        fontWithColor(14,{fontSize = 22,color = 'ffffff',text = string.format(__('第%s天'),CommonUtils.GetChineseNumber(index)),ap = cc.p(0.5, 0)}))
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
            {ap = cc.p(0, 0.5)
        })
    tabButton:addChild(newImg,6)
    newImg:setTag(789)
end

return RecallDailyTaskView