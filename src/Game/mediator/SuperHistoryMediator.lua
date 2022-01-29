local Mediator = mvc.Mediator

local SuperHistoryMediator = class("SuperHistoryMediator", Mediator)


local NAME = "SuperHistoryMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
function SuperHistoryMediator:ctor( params, viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.currentpage = 0
	self.historyData = {}
	self.btn = nil
	self.index = 0
end

function SuperHistoryMediator:InterestSignals()
	local signals = {
		SIGNALNAMES.TakeAway_History_Super_Callback,
		SIGNALNAMES.TakeAway_History_Rewards_Super_Callback,
	}

	return signals
end

function SuperHistoryMediator:ProcessSignal(signal )
	local name = signal:GetName() 
	print(signal:GetBody())
	dump(signal:GetBody().historyHuge)
	if name == SIGNALNAMES.TakeAway_History_Super_Callback then	--超大订单领奖
		if table.nums(signal:GetBody().historyHuge) == 0 then
			self.viewComponent.viewData.showLabel:setVisible(true)
			self.viewComponent.viewData.rightBtn:setVisible(false)
		else
			self.historyData = signal:GetBody().historyHuge
			self.viewComponent.viewData.showLabel:setVisible(false)
			if table.nums(signal:GetBody().historyHuge) == 1 then
				self.viewComponent.viewData.rightBtn:setVisible(false)
			end
		    self.pageview:setCountOfCell(table.nums(self.historyData))
	    	self.pageview:reloadData()
		end
	elseif name == SIGNALNAMES.TakeAway_History_Rewards_Super_Callback then	
		print('-----------------领取',self.index)
		self.historyData[self.index].hasDrawn = 1
		if self.btn then
			self.btn:setVisible(false)
		end

		-- CommonUtils.DrawRewards(checktable(checktable(signal:GetBody()).rewards))
		uiMgr:AddDialog('common.RewardPopup', {rewards = checktable(checktable(signal:GetBody()).rewards)})
	end
end

function SuperHistoryMediator:Initial( key )
	self.super.Initial(self,key)
	local scene = uiMgr:GetCurrentScene()
	local viewComponent  = require( 'Game.views.SuperOrderHistoryView' ).new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	scene:AddGameLayer(viewComponent)

	viewComponent.viewData.pageview:setOnPageChangedScriptHandler(handler(self,self.on_page_changed))
    viewComponent.viewData.pageview:setDataSourceAdapterScriptHandler(handler(self,self.data_source))
    self.pageview = viewComponent.viewData.pageview
    self.pageSize = viewComponent.viewData.pageSize


 	viewComponent.viewData.rightBtn:setOnClickScriptHandler(handler(self,self.buttonAction))
    viewComponent.viewData.leftBtn:setOnClickScriptHandler(handler(self,self.buttonAction))
    viewComponent.viewData.rightBtn:setVisible(true)
	viewComponent.viewData.leftBtn:setVisible(false)
end

function SuperHistoryMediator:on_page_changed(pSender,idx)
	self.currentpage = idx
	-- print(self.currentpage)
	self.viewComponent.viewData.rightBtn:setVisible(true)
	self.viewComponent.viewData.leftBtn:setVisible(true)
	if self.currentpage == 0 then
		self.viewComponent.viewData.leftBtn:setVisible(false)
	elseif self.currentpage == table.nums(self.historyData) - 1 then
		self.viewComponent.viewData.rightBtn:setVisible(false)
	end
   -- local sId = idx+1
   -- if self.selectPoints then
   --    for i=1,table.nums(self.selectPoints) do
   --       if i == sId then
   --          self.selectPoints[i]:setVisible(true)
   --       else
   --          self.selectPoints[i]:setVisible(false)
   --       end
   --    end
   -- end
end
function SuperHistoryMediator:data_source( p_convertview,idx )
    local pCell = p_convertview
    local index = idx + 1
    if not pCell then
        pCell = CPageViewCell:new()
        pCell:setContentSize(self.pageSize)
    end
    local layout = pCell:getChildByTag(773)
    if layout then
        layout:removeFromParent()
    end
    local layout = self:getCell(index)
    layout:setTag(773)
    display.commonUIParams(layout,{po = cc.p(0,0)})
    pCell:addChild(layout)
    return pCell
end

function SuperHistoryMediator:getCell(index)
	local dates = self.historyData[index]
	local size = self.pageSize
    local view = display.newLayer()
    view:setContentSize(size)
    view:setAnchorPoint(cc.p(0,0))
    if dates then
    	local superOrderConfig = CommonUtils.GetConfig('takeAway', 'huge', dates.takeawayId)
    	dump(superOrderConfig)
		local titleLabel = display.newLabel( size.width*0.5,size.height - 60,
			{ttf = true, font = TTF_GAME_FONT, text = __('超大订单完成'), fontSize = 26, color = '#ff481d', ap = cc.p(0.5, 1)})
		view:addChild(titleLabel)

		local Data = {
			{name = __('冠军：')},
			{name = __('冠军捐献：')},
			{name = __('我的捐献：')},
		}

		-- local orderMessTab = {}
		for i,v in ipairs(Data) do
			local Deslabel = display.newRichLabel(60, ((titleLabel:getPositionY() - 100) - 29*(i-1)),{ap = cc.p(0, 0.5), w = 53,r = true,sp = 5})
			view:addChild(Deslabel)

			local line = display.newImageView(_res('ui/common/takeout_ico_big_line.png'),50, Deslabel:getPositionY() - 14,{ap = cc.p(0, 0.5)})
			view:addChild(line)

			if i == 1 then
				display.reloadRichLabel(Deslabel, {c = {--datas.champion
					fontWithColor(6,{text = v.name}),
					{text = dates.championName , fontSize = 22, color = '#5c5c5c'}
				}})
			elseif i == 2 then
				display.reloadRichLabel(Deslabel, {c = {--datas.championSubmitNum
					fontWithColor(6,{text = v.name}),
					fontWithColor(10,{text = dates.championDonate})
				}})
			elseif i == 3 then
				display.reloadRichLabel(Deslabel, {c = {--datas.mySubmitNum
					fontWithColor(6,{text = v.name}),
					fontWithColor(10,{text = dates.donateNum})
				}})
			end	
		end

		local Deslabel2 = display.newLabel(60 , size.height * 0.5 - 30,
			fontWithColor(4,{text = __('获得奖励'),ap = cc.p(0, 0.5)}))
		view:addChild(Deslabel2)

		for i=1,table.nums(superOrderConfig.ownerRewards) do
			local RewardsDates =  CommonUtils.GetConfig('goods', 'goods',superOrderConfig.ownerRewards[i].goodsId)
			dump(RewardsDates)
			local tempButton = display.newButton(0, 0, {n = _res(string.format('ui/common/common_frame_goods_'.. RewardsDates.quality .. '.png'))})
			tempButton:setScale(0.7)
		 	display.commonUIParams(tempButton, {po = cc.p(60 + (tempButton:getContentSize().width*0.7 + 4) * (i-1),Deslabel2:getPositionY()- 20 ),ap = cc.p(0,1)})
		 	view:addChild(tempButton)

		 	local iconPath = CommonUtils.GetGoodsIconPathById(superOrderConfig.ownerRewards[i].goodsId)
	 		local rewardImg = display.newImageView(_res(iconPath), tempButton:getContentSize().width * 0.5, tempButton:getContentSize().height * 0.5)
			tempButton:addChild(rewardImg)
			rewardImg:setTag(1)
			rewardImg:setScale(0.45)
		end
		if checkint(dates.hasDrawn) == 0 then
			local getButton = display.newButton(0, 0, {n = _res('ui/common/common_btn_orange.png')})
		 	display.commonUIParams(getButton, {po = cc.p(size.width * 0.5,35),ap = cc.p(0.5,0.5)})
		 	display.commonLabelParams(getButton, fontWithColor(14,{text = __('领取')}))
		 	view:addChild(getButton)
		 	getButton:setTag(index)
 	     	getButton:setOnClickScriptHandler(function (sender)
            	self:SendSignal(COMMANDS.COMMAND_TakeAway_History_Rewards_Super,{orderId = dates.takeawayOrderId})
            	self.btn = getButton
            	self.index = index
        	end)

		 end
	end
    return view
end

function SuperHistoryMediator:buttonAction(sender)
    local tag = sender:getTag()
    if tag == 2 then
        --self.pageview:setContentOffset({x = -self.pageSize.width*(self.currentpage+1),y = 0})
        self.pageview:getContainer():stopAllActions()
        self.pageview:setContentOffsetInDuration({x = -self.pageSize.width*(self.currentpage+1),y = 0},0.2)
    elseif tag == 1 then
        self.pageview:getContainer():stopAllActions()
        --self.pageview:setContentOffset({x = -self.pageSize.width*(self.currentpage-1),y = 0})
        self.pageview:setContentOffsetInDuration({x = -self.pageSize.width*(self.currentpage-1),y = 0},0.2)
    end
end

function SuperHistoryMediator:OnRegist(  )
	local TakeAwayCommand = require( 'Game.command.TakeAwayCommand')
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_TakeAway_History_Super, TakeAwayCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_TakeAway_History_Rewards_Super, TakeAwayCommand)

	self:SendSignal(COMMANDS.COMMAND_TakeAway_History_Super)
end
function SuperHistoryMediator:OnUnRegist(  )
	-- 称出命令
	local scene = uiMgr:GetCurrentScene()
	scene:RemoveGameLayer(self.viewComponent)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_TakeAway_History_Super, TakeAwayCommand)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_TakeAway_History_Rewards_Super, TakeAwayCommand)
end

return SuperHistoryMediator






