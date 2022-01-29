--[[
订单页面Mediator
--]]
local Mediator = mvc.Mediator
---@class LargeAndOrdinaryMediator :Mediator
local LargeAndOrdinaryMediator = class("LargeAndOrdinaryMediator", Mediator)
local NAME = "LargeAndOrdinaryMediator"
local WaitingShipping  = 1  -- 等待配送
local CompleteOrder = 4     -- 完成订单 领取奖励
local PublicOrder = 2
local PrivateOrder =1
---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local shareFacade = AppFacade.GetInstance()
local takeawayInstance = AppFacade.GetInstance():GetManager('TakeawayManager')

function LargeAndOrdinaryMediator:ctor(param ,viewComponent )
	self.dingCarTable = takeawayInstance:GetDatas().diningCar
	if not  param then
		param = {}
	end
	self.super:ctor(NAME, viewComponent)
	param = takeawayInstance:GetOrderInfoByOrderInfo({orderId = param.orderId ,orderType = param.orderType  })
	self.param = param
	self.diningCarId = param.diningCarId
	self.status = param.status
	self.roleId = param.roleId
	self.teamId = param.teamId
	self.deliveryTime = param.deliveryTime  or  0  -- 订单预计剩余时间
	self.totalDeliverySeconds = param.totalDeliverySeconds
	-- self.time = param.time

	self.orderType = param.orderType
	-- self.orderType = 1
	self.orderId = param.orderId
	self.takeawayId = param.takeawayId
	if self.orderType  == PublicOrder then
		if self.status > WaitingShipping then
			self.time = param.leftSeconds
		else
			self.time = param.endLeftSeconds
		end
	elseif self.orderType  == PrivateOrder then
		if self.status > WaitingShipping then
			self.time = param.leftSeconds
		end
	end
	if self.status == CompleteOrder then
		self.time =  0
	end
end

function LargeAndOrdinaryMediator:InterestSignals()
    local signals = {
        SIGNALNAMES.LargeAndOrdinary_TakeAwayReward,
		SIGNALNAMES.StartDeliveryOrder_Cancel,
		SIGNALNAMES.LargeAndOrdinary_TakeAwayOrder,
		SIGNALNAMES.StartDeliveryOrder_Refuse ,
		SIGNALNAMES.RobberyOneDetailView_Name_Callback
    }
    return signals
end

function LargeAndOrdinaryMediator:ProcessSignal( signal )
	local name = signal:GetName()
	if name == SIGNALNAMES.LargeAndOrdinary_TakeAwayReward then
		AppFacade.GetInstance():DispatchObservers("DOT_LOG_EVENT_SEND" , {eventId = "45-02"})
		local data = checktable(signal:GetBody())
        local rewardData =  data.rewards
		uiMgr:AddDialog('common.RewardPopup', {rewards = checktable(rewardData), mainExp = checkint(data.mainExp),popularity = checkint(data.popularity), highestPopularity = checkint(data.highestPopularity)})
        --更新本地缓存的数据
		takeawayInstance:DeliveryOrDeleteCacheData(self.orderType, self.orderId)
		gameMgr:setMutualTakeAwayToTeam(self.teamId , CARDPLACE.PLACE_TAKEAWAY,CARDPLACE.PLACE_TEAM)
		takeawayInstance:DirectRfreshOrder() -- 外卖订单刷新刷去机制
		self:CloseView()
		app.badgeMgr:CheckOrderRed()
	elseif name ==  SIGNALNAMES.StartDeliveryOrder_Cancel then
		uiMgr:ShowInformationTips(__('订单取消成功~'))
		local data = signal:GetBody()
        local reqdata = data.rewards
		if self.orderType == PrivateOrder then -- 扣除所需订单
			str = 'privateOrder'
		elseif self.orderType == PublicOrder then
			str = 'publicOrder'
		end
		gameMgr:setMutualTakeAwayToTeam(self.teamId , CARDPLACE.PLACE_TAKEAWAY,CARDPLACE.PLACE_TEAM)
        takeawayInstance:DeliveryOrDeleteCacheData(self.orderType,self.orderId)
		CommonUtils.DrawRewards({{ goodsId = POPULARITY_ID , num = checkint(data.popularity) - gameMgr:GetUserInfo().popularity}})
        uiMgr:AddDialog('common.RewardPopup', {rewards = checktable(reqdata), mainExp = checkint(reqdata.mainExp)})
		takeawayInstance:DirectRfreshOrder()
		self:CloseView()
	elseif  name ==  SIGNALNAMES.LargeAndOrdinary_TakeAwayOrder  then
		local data = signal:GetBody()
		self.hasDeliveredNumber  = checkint(data.hasDeliveredNumber)
		self.lastDeliveredPlayers = data.lastDeliveredPlayers
		self.param.lastDeliveredPlayers = self.lastDeliveredPlayers
		self.param.hasDeliveredNumber = self.hasDeliveredNumber
		if self.orderType == PublicOrder then
			if self.status >WaitingShipping  then
				self.robberyData = data
				data.orders = data.robbery
				local layout = self:GetViewComponent():CreateRobberyedReward(data.rewards)
				self.layer:updateTestsureAndMarqueue(self.hasDeliveredNumber,self.lastDeliveredPlayers)
				local rightlayout =  self:GetViewComponent().rightlayout
				local orderSize = rightlayout:getContentSize()
				rightlayout:addChild(layout,10)
				layout:setPosition(cc.p(orderSize.width/2 , 230))
				if table.nums(data.orders) > 0 then
					if self:GetViewComponent().robberyButton then
						self:GetViewComponent().robberyButton:setVisible(true)
						local num = 3.2
						local moveHeight = 50
						self:GetViewComponent().robberyButton:runAction(
						cc.RepeatForever:create(
						cc.Sequence:create(
						cc.Spawn:create(
						cc.JumpBy:create( 0.5 *num , cc.p(0,0) , moveHeight ,1) ,
						cc.Sequence:create(
						cc.ScaleTo:create(0.28 *num, 1.2,0.6 )  ,
						cc.ScaleTo:create(0.22 *num , 1,1)
						)
						),
						cc.DelayTime:create(0.11)
						)
						)
						)

					end

				end
			else
				self.layer:updateTestsureAndMarqueue(self.hasDeliveredNumber,self.lastDeliveredPlayers)

			end
		end
	elseif name == "REFRESH_NOT_CLOSE_GOODS_EVENT" then
		if not tolua.isnull(self.layer) then
			self.layer:updateNeedGoodLayout()
		end
	elseif name == SIGNALNAMES.StartDeliveryOrder_Refuse then
		uiMgr:ShowInformationTips(__('订单已经拒单成功~'))
		local data = signal:GetBody()
		takeawayInstance:DeliveryOrDeleteCacheData(self.orderType, self.orderId)
		CommonUtils.DrawRewards({{ goodsId = POPULARITY_ID , num = checkint(data.popularity) - gameMgr:GetUserInfo().popularity}})
        CommonUtils.DrawRewards({{ goodsId = HIGHESTPOPULARITY_ID , num = checkint(data.highestPopularity)  - gameMgr:GetUserInfo().highestPopularity}})
		takeawayInstance:DirectRfreshOrder()
		self:CloseView()
	elseif name == SIGNALNAMES.RobberyOneDetailView_Name_Callback then
		local data = signal:GetBody()
		self.robberyData = data
		data.orders = data.robbery
		local layout = self:GetViewComponent():CreateRobberyedReward(data.rewards)
		local rightlayout =  self:GetViewComponent().rightlayout
		local orderSize = rightlayout:getContentSize()
		rightlayout:addChild(layout,10)
		layout:setPosition(cc.p(orderSize.width/2 , 230))

		if table.nums(data.orders) > 0 then
			self:GetViewComponent().robberyButton:setVisible(true)

		end
	end
end

function LargeAndOrdinaryMediator:Initial( key )
	self.super.Initial(self, key)
    if isGuideOpened('takeout') then
        local guideNode = require('common.GuideNode').new({tmodule = 'takeout'})
        display.commonUIParams(guideNode, { po = display.center})
        sceneWorld:addChild(guideNode, GameSceneTag.Guide_GameSceneTag)
    end
	local scene = uiMgr:GetCurrentScene()
	local tag = 8000

	local layer = require( 'Game.views.LargeAndOrdinaryOrder' ).new({
		status = self.status ,
		diningCarId = self.diningCarId,
		roleId = self.roleId,
		time = self.time,
		orderType = self.orderType ,
		areaId = self.areaId ,
		orderId = self.orderId,
		takeawayId = self.takeawayId,
		totalDeliverySeconds = self.totalDeliverySeconds ,
		deliveryTime  = self.deliveryTime ,
		orderData = self.param
	})
	display.commonUIParams(layer, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
	layer:setTag(tag)
	scene:AddDialog(layer)
	self.layer = layer
	self:SetViewComponent(layer)
	if layer.robberyButton then
		layer.robberyButton:setVisible(false)
		layer.robberyButton:setOnClickScriptHandler(function (sender)
			if self.robberyData then
				local RobberyDetailMediator = require('Game.mediator.RobberyDetailMediator')
				local mediator = RobberyDetailMediator.new({ type = 2 })
				self:GetFacade():RegistMediator(mediator)
				local robberyData = mediator:SortRobberyHistory(self.robberyData)
				mediator.data = robberyData
				mediator:RefreshRobberyDetailView(mediator.data)
			end
		end)
	end
	self.layer.eaterLayer:setOnClickScriptHandler(handler(self,self.CloseView))
	self.layer.sendMessage:setOnClickScriptHandler(function (sender)
		PlayAudioByClickNormal()
		self:ButtonClickDelay(sender)
		if self.layer.status == CompleteOrder  then
			if self.diningCarId then
				self:SendSignal(COMMANDS.COMMANDS_LargeAndOrdinary_TakeAwayReward,{diningCarId = self.diningCarId})
			end
		else
			if self.status > WaitingShipping  then
				if self.layer.time <= 0 or self.status == CompleteOrder  then
					self:SendSignal(COMMANDS.COMMANDS_LargeAndOrdinary_TakeAwayReward,{diningCarId = self.diningCarId})
				else
					local Num  = checkint(self.layer.dataOrder.rejectPopularity )
					local CommonTip  = require( 'common.CommonTip' ).new({text = __(' 确定撤回外卖队伍?') ,descr =string.format( __(' 撤回后将扣除%d点知名度,并且无法再次接受该订单!'),Num) ,callback = function ()
							 local orderInfo = takeawayInstance:GetOrderInfoByOrderInfo({orderId = self.orderId, orderType = self.orderType})
							 local data = {}
							 data.diningCarId = orderInfo.diningCarId
                            self:SendSignal(COMMANDS.COMMANDS_StartDeliveryOrder_Cancel,data)
                        end})
					CommonTip:setPosition(display.center)
					local scene = uiMgr:GetCurrentScene()
					scene:AddDialog(CommonTip,10)
					return
				end
			else
				if self.orderType == PublicOrder  then
					if self.layer.time <  0 then
						uiMgr:ShowInformationTips(__('订单配送已过期~'))
						return
					end
				end
				if not self.layer.foodEnough then
					uiMgr:ShowInformationTips(__('菜品不足可取厨房制作或者请求好友帮助哦~'))
					return
				end
			end
			self:CloseView(sender)
			self.layer:setVisible(false)
			local StartDeliveryOrderMediator = require( 'Game.mediator.StartDeliveryOrderMediator' )
			local mediator = StartDeliveryOrderMediator.new({
				status = self.status,
				diningCarId = self.diningCarId,
				roleId = self.roleId,
				time = self.layer.time,
				orderType = self.orderType,
				orderId = self.orderId,
				takeawayId = self.takeawayId,
				diningCar = self.diningCar,
				hasDeliveredNumber  = self.hasDeliveredNumber,
				lastDeliveredPlayers = self.lastDeliveredPlayers ,
				deliveryTime = self.deliveryTime ,
				orderData = self.param
				})
			self:GetFacade():RegistMediator(mediator)
			AppFacade.GetInstance():UnRegsitMediator("LargeAndOrdinaryMediator")
		end
	end)
	self.layer.cancelBtn:setOnClickScriptHandler( function (sender)
		local Num  = checkint(self.layer.dataOrder.rejectPopularity )
		local CommonTip  = require( 'common.CommonTip' ).new({text = __(' 确定拒单么?') ,descr = string.format(__('拒单是要扣除%d点知名度的') ,Num) ,callback = function ()
			self:SendSignal(COMMANDS.COMMANDS_StartDeliveryOrder_Refuse,{orderId = self.orderId})
		end})
		CommonTip:setPosition(display.center)
		local scene = uiMgr:GetCurrentScene()
		scene:AddDialog(CommonTip,10)
	end)
end

function LargeAndOrdinaryMediator:CloseView(sender)
	PlayAudioByClickClose()
	local function deleteView()
		local scene = uiMgr:GetCurrentScene()
		AppFacade.GetInstance():UnRegsitMediator("LargeAndOrdinaryMediator")
	end
	local seqTable ={}
	local spawnTable = {}
	spawnTable[#spawnTable+1] = cc.FadeIn:create(0.2)
	local spawnAction = cc.Spawn:create(spawnTable)
	seqTable[#seqTable+1] = spawnAction
	seqTable[#seqTable+1] = cc.CallFunc:create(deleteView)
	local seqAction  = cc.Sequence:create(seqTable)
	self.layer:runAction(seqAction)
end
function LargeAndOrdinaryMediator:ButtonClickDelay(sender)
	PlayAudioByClickClose()
	local  setNotClick = function ()
		sender:setEnabled(false)
	end
	local  setCanClick = function ()
		sender:setEnabled(true)
	end
	local seqTable = {}
	seqTable[#seqTable+1] =  cc.CallFunc:create(setNotClick)
	seqTable[#seqTable+1] =  cc.DelayTime:create(0.1)
	seqTable[#seqTable+1] =  cc.CallFunc:create(setCanClick)
	local seqAction  = cc.Sequence:create(seqTable)
	sender:runAction(seqAction)

end
function LargeAndOrdinaryMediator:EnterLayer()
	if self.orderType == PublicOrder then
		self:SendSignal(COMMANDS.COMMANDS_LargeAndOrdinary_TakeAwayOrder , {orderId = self.orderId , orderType  = self.orderType})
	elseif self.orderType == PrivateOrder then
		--- 当大于1 的时候判断剩下的打劫的物品
		if self.status > WaitingShipping then
			self:SendSignal(COMMANDS.COMMAND_RobberyOneDetaiView_Name_Callback , {orderId = self.orderId , orderType = self.orderType })
		end
	end
end

function LargeAndOrdinaryMediator:OnRegist(  )
	local RobberyCommand  = require('Game.command.RobberyCommand')
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_RobberyOneDetaiView_Name_Callback, RobberyCommand)
	local LargeAndOrdinaryCommand = require( 'Game.command.LargeAndOrdinaryCommand' )
	self:GetFacade():RegistSignal(COMMANDS.COMMANDS_LargeAndOrdinary_TakeAwayReward,LargeAndOrdinaryCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMANDS_LargeAndOrdinary_TakeAwayOrder,LargeAndOrdinaryCommand)
	local StartDeliveryOrderCommand = require( 'Game.command.StartDeliveryOrderCommand')
	self:GetFacade():RegistSignal(COMMANDS.COMMANDS_StartDeliveryOrder_Refuse, StartDeliveryOrderCommand) -- 订单配送
	self:GetFacade():RegistSignal(COMMANDS.COMMANDS_StartDeliveryOrder_Cancel, StartDeliveryOrderCommand) -- 订单配送
	self:GetFacade():RegistObserver("REFRESH_NOT_CLOSE_GOODS_EVENT", mvc.Observer.new( self.ProcessSignal, self))
	self:EnterLayer()
end

function LargeAndOrdinaryMediator:OnUnRegist()
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_LargeAndOrdinary_TakeAwayReward)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_LargeAndOrdinary_TakeAwayOrder)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_RobberyOneDetaiView_Name_Callback)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_StartDeliveryOrder_Refuse)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_StartDeliveryOrder_Cancel)
	self:GetFacade():UnRegistObserver("REFRESH_NOT_CLOSE_GOODS_EVENT",self) --刷新goodNode 的显示
	uiMgr:GetCurrentScene():RemoveDialog(self:GetViewComponent())

	AppFacade.GetInstance():DispatchObservers(SGL.BREAK_TO_HOME_MEDIATOR)
end
return LargeAndOrdinaryMediator








