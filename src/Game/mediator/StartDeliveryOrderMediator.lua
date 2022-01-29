local Mediator = mvc.Mediator
---@class StartDeliveryOrderMediator :Mediator
local StartDeliveryOrderMediator = class("StartDeliveryOrderMediator", Mediator)
---@type CardManager
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
---@type TakeawayManager
local takeawayInstance = AppFacade.GetInstance():GetManager('TakeawayManager')

---@type TimerManager
local timerMgr = AppFacade.GetInstance():GetManager('TimerManager')
local NAME = "StartDeliveryOrderMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local WaitingShipping  = 1  -- 等待配送 
local CompleteOrder = 4     -- 完成订单 领取奖励
local PublicOrder = 2  -- 公有订单
local PrivateOrder =1  -- 私有订单
function StartDeliveryOrderMediator:ctor(param ,viewComponent )
	self.super:ctor(NAME,viewComponent)
	local newParam    = takeawayInstance:GetOrderInfoByOrderInfo({orderId = param.orderId ,orderType = param.orderType  })
	self.param        = checktable(newParam)
	self.orderId      = checkint(self.param.orderId)
	self.orderType    = checkint(self.param.orderType)
	self.time         = self.param.time
	self.roleId       = self.param.roleId
	self.status       = checkint(self.param.status)
	self.takeawayId   = checkint(self.param.takeawayId)
	self.deliveryTime = self.param.deliveryTime or 0
	self.areaId       = checkint(self.param.areaId)
	self.diningCar    = takeawayInstance:GetDatas().diningCar
end


function StartDeliveryOrderMediator:InterestSignals()
	local signals = {
		SIGNALNAMES.StartDeliveryOrder_Dlivery,
		SIGNALNAMES.StartDeliveryOrder_Cancel,
		SIGNALNAMES.StartDeliveryOrder_Refuse,
		"REFRESH_RECIPE_DETAIL" ,
		POST.CARD_VIGOUR_DIAMOND_RECOVER.sglName ,
		"REFRESH_SELECT_TEAM",
		"SENDER_TAKEAWAY_ORDER"
	}

	return signals
end

function StartDeliveryOrderMediator:ProcessSignal(signal )
	local name = signal:GetName() 
	local data = signal:GetBody()
	if name == SIGNALNAMES.StartDeliveryOrder_Dlivery then  -- 订单发车按钮
		AppFacade.GetInstance():DispatchObservers("DOT_LOG_EVENT_SEND" , {eventId ="45-01" })
		uiMgr:ShowInformationTips(__('订单发车成功~'))
		if self.orderType == PrivateOrder then -- 扣除所需订单
			str = 'privateOrder'
		elseif self.orderType == PublicOrder then
			str = 'publicOrder'
		end
		local dataOrder = {}
		dataOrder =  CommonUtils.GetConfigAllMess(str,'takeaway')
		dataOrder = dataOrder[tostring(self.takeawayId)]
		if not dataOrder then
			return
		end
		local reqdata = {} -- 加工组合数据 
		for k ,v in pairs (dataOrder.foods) do
			table.insert(reqdata,#reqdata+1,{})
			reqdata[#reqdata].goodsId = k
			reqdata[#reqdata].num =  0 - checkint(v) 
		end
		CommonUtils.DrawRewards(reqdata) 
		self.viewComponent.dingCarTable[self.viewComponent.selectIndexCar]['status'] = 2
		-- 更新队伍的新鲜度
		local teamData =  self.viewComponent.teamData[self.viewComponent:getTeamSelectTeamId()]  or {} -- 获取到选中的编队
		local count = table.nums(teamData.members)
		for k ,cardData in ipairs(teamData.members) do
			local vigour = app.restaurantMgr:GetMaxCardVigourById(cardData.id)
			local data = gameMgr:GetCardDataById(cardData.id)
			if not data.vigour then return  end   -- 数据不对直接返回
			data.vigour  = checkint(data.vigour) - checkint( tonumber(self.viewComponent.dataOrder.consumeVigour)  * vigour  / count )  -- 扣除新鲜度每次扣除六点
 			data.vigour  = 	data.vigour > 0  and data.vigour or 0  -- 不足的时候直接制空
		end
		local dataOrderInfo = {}
		dataOrderInfo.orderId = self.orderId
		dataOrderInfo.takeawayId  = self.takeawayId
		dataOrderInfo.orderType  = self.orderType
		--- 菜谱厨力点加成
		dataOrderInfo.recipeCookingPoint =  checkint( self:GetViewComponent().recipeCookingPoint)
		--- 餐厅助手加成
		dataOrderInfo.assistantCookingPoint =  checkint( self:GetViewComponent().assistantCookingPoint)
		local  diningCar   = {}
		diningCar.orderId  = self.orderId
		diningCar.orderType = self.orderType
		diningCar.diningCarId  = self.viewComponent.dingCarTable[self.viewComponent.selectIndexCar].diningCarId
		diningCar.takeawayId =  self.takeawayId
		diningCar.leftSeconds = data.leftSeconds
		diningCar.teamId  =  self.viewComponent:getTeamSelectTeamId() -- 加工diningCar 表
		diningCar.status  = 2
		dataOrderInfo.diningCar = diningCar
		dataOrderInfo.diningCarId =  self.viewComponent.dingCarTable[self.viewComponent.selectIndexCar].diningCarId
		dataOrderInfo.leftSeconds = data.leftSeconds
		dataOrderInfo.totalDeliverySeconds = data.leftSeconds
		dataOrderInfo.teamId =  self.viewComponent:getTeamSelectTeamId() 
		dataOrderInfo.status = 2

        takeawayInstance:DeliveryOrDeleteCacheData(self.orderType, self.orderId, dataOrderInfo)
		local datas  = takeawayInstance:GetOrderInfoByOrderInfo({orderId = self.orderId ,orderType = self.orderType  })
		local timerName = app.takeawayMgr:GetOrderTimerKey(self.areaId, self.orderType ,self.orderId)
		timerMgr:RemoveTimer(timerName) --移除旧的计时器，活加新计时器
		timerMgr:AddTimer({ name = timerName, countdown = checkint(data.leftSeconds), tag = RemindTag.TAKEAWAY_TIMER, datas = datas}) --移除旧的计时器，活加新计时器
		gameMgr:setMutualTakeAwayToTeam(self.viewComponent:getTeamSelectTeamId(),CARDPLACE.PLACE_TEAM ,CARDPLACE.PLACE_TAKEAWAY)
		self:GetFacade():DispatchObservers(FRESH_TAKEAWAY_POINTS)

		self:closeStartDeliveryMediator()
	elseif name == "SENDER_TAKEAWAY_ORDER"  then -- 发车的逻辑
		self.viewComponent.selectedTeamIdx =  data.selectedTeamIdx
		self:SenderTakeAwayOrder(self.viewComponent.sendMessage)
	elseif name == SIGNALNAMES.StartDeliveryTakeAway_Home  then -- 订单取消按钮


		local instance = AppFacade.GetInstance():GetManager('TakeawayManager')
		instance.orderDatas = data
		self.closeStartDeliveryMediator(self.viewComponent) --关闭界面
	elseif name == "REFRESH_SELECT_TEAM" then -- 刷新队伍
		self.viewComponent:RefreshTeamSelectedState( data.selectedTeamIdx)
	elseif  name == SIGNALNAMES.StartDeliveryOrder_Cancel  then -- 订单取消按钮
		uiMgr:ShowInformationTips(__('订单取消成功~'))
		if self.orderType == PrivateOrder then -- 扣除所需订单
			str = 'privateOrder'
		elseif self.orderType == PublicOrder then
			str = 'publicOrder'
		end
		local dataOrder = {}
		dataOrder =  CommonUtils.GetConfigAllMess(str,'takeaway')
		dataOrder = dataOrder[tostring(self.takeawayId)]
		if not dataOrder then
			return
		end
		local reqdata = {} -- 加工组合数据 
		for k ,v in pairs (dataOrder.foods) do
			table.insert(reqdata,#reqdata+1,{})
			reqdata[#reqdata].goodsId = k
			reqdata[#reqdata].num =  checkint(v) 
		end
		CommonUtils.DrawRewards(reqdata) 
		
	elseif  name == "REFRESH_NOT_CLOSE_GOODS_EVENT" then -- 订单取消按钮
		if not tolua.isnull(self.viewComponent) then
			self.viewComponent:updateNeedGoodLayout()
		end 
	elseif name == "SHOW_TEAM_FORMATION" then
		self:ShowTeamFormation(data)
	elseif "CLOSE_TEAM_FORMATION" == name then
		-- 关闭编队界面
		self:GetFacade():DispatchObservers(TeamFormationScene_ChangeCenterContainer)
	elseif HomeScene_ChangeCenterContainer_TeamFormation == name then
		-- 编队界面关闭成功 回调函数
		self:CloseTeamFormation()
		self.viewComponent:RefreshTeamFormation(gameMgr:GetUserInfo().teamFormation)
	elseif name == SIGNALNAMES.StartDeliveryOrder_Refuse then 
		uiMgr:ShowInformationTips(__('订单已经拒单成功~'))
		CommonUtils.DrawRewards({{ goodsId = POPULARITY_ID , num = checkint(data.popularity) - gameMgr:GetUserInfo().popularity}})
		takeawayInstance:DeliveryOrDeleteCacheData(self.orderType, self.orderId)
		takeawayInstance:DirectRfreshOrder()	
		self:closeStartDeliveryMediator()
	elseif name == POST.CARD_VIGOUR_DIAMOND_RECOVER.sglName then
		local data = signal:GetBody()
		local newVigourTable = data.newVigour
		for k ,v in  pairs (newVigourTable) do
			local cardData = gameMgr:GetCardDataById(k)
			cardData.vigour = checkint(v)
		end
		-- 刷新界面
		self.viewComponent:RefreshTeamInfo( self.viewComponent.teamData[checkint(self.viewComponent.selectedTeamIdx) ])
		-- 刷新新鲜度
		local diamondNum = data.diamond - CommonUtils.GetCacheProductNum(DIAMOND_ID)
		CommonUtils.DrawRewards({ rewards = { goodsId = DIAMOND_ID , num = diamondNum }})
	elseif  name == "REFRESH_RECIPE_DETAIL" then
		local data = signal:GetBody()
		-- 当菜谱升级的时候 应该刷新的界面
		if data.recipeLevelIsAdd then
			---@type StartDeliveryOrderView
			local viewComponent =  self:GetViewComponent()
			local cookingRichLabel = viewComponent.recipeUpgradeRefreshUI[tostring(COOK_ID)]
			if cookingRichLabel then
				local recipeCookingPoint  = app.cookingMgr:GetRecipeIdByRewardCookingNum(data.recipeId)
				viewComponent.recipeCookingPoint = recipeCookingPoint
				-- 获取厨力点的icon
				local iconPath = CommonUtils.GetGoodsIconPathById(COOK_ID)
				local cookingPoint =  viewComponent.assistantCookingPoint + recipeCookingPoint + viewComponent.baseCookingpoint
				display.reloadRichLabel(cookingRichLabel, { c = {
					{ img = iconPath  ,scale = 0.2} ,
					{ color = fontWithColor("10").color, fontSize = fontWithColor('10').fontSize,text = " " .. cookingPoint , ap = display.CENTER}

				} })
			end
		end
	end
end

function StartDeliveryOrderMediator:Initial( key )
	self.super.Initial(self,key)
	local  tag  = 8001
	local scene = uiMgr:GetCurrentScene()
	local layer  = require( 'Game.views.StartDeliveryOrderView' ).new(self.param )
	display.commonUIParams(layer, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
	layer:setTag(tag)
	scene:AddDialog(layer)
	self:SetViewComponent(layer)
	---@type StartDeliveryOrderView
	self.viewComponent = self:GetViewComponent()
	self.viewComponent.sendMessage:setOnClickScriptHandler(handler(self, self.SenderTakeAwayOrder))
	self.viewComponent.cancelBtn:setOnClickScriptHandler( function (sender)
		local Num  = checkint(self.viewComponent.dataOrder.rejectPopularity ) 
		local CommonTip  = require( 'common.CommonTip' ).new({text = __(' 确定拒单么?') ,descr = string.format(__('拒单是要扣除%d点知名度的') ,Num),callback = function ()
			if  takeawayInstance:GetOrderInfoByOrderInfo({orderType = self.orderType ,orderId = self.orderId }) then

				self:SendSignal(COMMANDS.COMMANDS_StartDeliveryOrder_Refuse,{orderId = self.orderId})
			else 
				self:closeStartDeliveryMediator()
				uiMgr:ShowInformationTips(__('该订单已经过期~'))
			end 
		end})
		CommonTip:setPosition(display.center)
		local scene = uiMgr:GetCurrentScene()
		scene:AddDialog(CommonTip,10)
	end)

	self.viewComponent.eaterLayer:setOnClickScriptHandler(handler(self,self.closeStartDeliveryMediator))
end
function StartDeliveryOrderMediator:SenderTakeAwayOrder(sender)
	PlayAudioClip(AUDIOS.UI.ui_moto.id)
	if self.orderType == publicOrder then
		if self.viewComponent.time <= 0  then
			uiMgr:ShowInformationTips(__('订单已经过期~'))
			return
		end
	end
	if self.status > WaitingShipping  and  self.status  < CompleteOrder then
		uiMgr:ShowInformationTips(__('外卖车已经发车了~'))
		return
	end
	if not self.viewComponent.dingCarTable then  --如果外卖车不存在直接return
		uiMgr:ShowInformationTips(__('不存在外卖车~'))
		return
	end
	local selectCarTable = self.viewComponent.dingCarTable[self.viewComponent.selectIndexCar]
	if  selectCarTable then
		if selectCarTable.status > WaitingShipping then
			uiMgr:ShowInformationTips(__('外卖车正在忙碌中~'))
			return
		end
	else
		return
	end
	local teamId   = self.viewComponent:getTeamSelectTeamId()
	if gameMgr:isInDeliveryTeam(teamId) then
		uiMgr:ShowInformationTips(__('该队伍在外卖中~'))
		return
	end

	local teamData =  self.viewComponent.teamData[teamId]
	if not  teamData then return end

	local cardData = teamData.members
	if #cardData> 0 then
		-- local places =  gameMgr:GetCardPlace({id = cardData[1].id})
		-- if places  and  (places[tostring(CARDPLACE.PLACE_EXPLORATION)] or places[tostring(CARDPLACE.PLACE_EXPLORE_SYSTEM)]) then
		-- 	uiMgr:ShowInformationTips(__('该队伍在探索中~'))
		-- 	return
		-- end
	else
		uiMgr:ShowInformationTips(__('队伍不能为空~'))
		return
	end
	local isFulllVigour = app.restaurantMgr:HasEnoughVigourToExplore(self.viewComponent.selectedTeamIdx ,tonumber(self.viewComponent.dataOrder.consumeVigour))
	if not isFulllVigour then
		if not  self:GetFacade():RetrieveMediator("VigourRecoveryMediator") then
			local VigourRecoveryMeiator = require("Game.mediator.VigourRecoveryMediator")
			local mediator = VigourRecoveryMeiator.new({type =1 , vigourCost = tonumber(self.viewComponent.dataOrder.consumeVigour) , selectedTeam = self.viewComponent.selectedTeamIdx })
			self:GetFacade():RegistMediator(mediator)
		else
			uiMgr:ShowInformationTips(__('新鲜度不足'))
		end
		return
	end
	self:setDelayClick(sender)
	local data = {}
	data.orderId = self.orderId
	data.orderType = self.orderType
	data.teamId = teamId

	data.diningCarId = selectCarTable.diningCarId
	if (not data.teamId)     or  self.viewComponent.teamBattlePoint == 0  then
		uiMgr:ShowInformationTips(__('没有选中的队伍~'))
		return
	end
	if  takeawayInstance:GetOrderInfoByOrderInfo({orderType = self.orderType ,orderId = self.orderId }) then
		self:SendSignal(COMMANDS.COMMANDS_StartDeliveryOrder_Dlivery,data)
	else
		uiMgr:ShowInformationTips(__('该订单已经过期~'))
		self:closeStartDeliveryMediator()
	end
end

function StartDeliveryOrderMediator:closeStartDeliveryMediator(sender)
	PlayAudioByClickClose()
	if sender then
		self:setDelayClick(sender)
	end
	local function deleteView()
		AppFacade.GetInstance():UnRegsitMediator("StartDeliveryOrderMediator")
		local scene = uiMgr:GetCurrentScene()
		if scene:GetDialogByTag(8001) then
			scene:RemoveDialogByTag(8001)
		end
	end
	local seqTable ={}
	local spawnTable = {}
	spawnTable[#spawnTable+1] = cc.FadeIn:create(0.2)
	local spawnAction = cc.Spawn:create(spawnTable)
	seqTable[#seqTable+1] = spawnAction
	seqTable[#seqTable+1] = cc.CallFunc:create(deleteView)
	local seqAction  = cc.Sequence:create(seqTable)
	self.viewComponent:runAction(seqAction)
end
--[[
	--防止过快点击造成错误
]]
function StartDeliveryOrderMediator:setDelayClick(sender)
	if sender.setEnabled then
		sender:setEnabled(false)
	else
		return
	end
	local seqTable = {}
	local callBack = function ( )
		sender:setEnabled(true)
	end
	seqTable[#seqTable+1] = cc.DelayTime:create(0.25)
	seqTable[#seqTable+1] = cc.CallFunc:create(callBack)
	local  seqAction = cc.Sequence:create(seqTable)
	sender:runAction(seqAction)
end
--[[
显示编队界面
--]]
function StartDeliveryOrderMediator:ShowTeamFormation(jumpTeamIndex)
	local TeamFormationMediator = require( 'Game.mediator.TeamFormationMediator')
	local mediator = TeamFormationMediator.new({isCommon = true,jumpTeamIndex = jumpTeamIndex})
	self:GetFacade():RegistMediator(mediator)
	self.teamMediator = mediator
	self:ShowStartDeliveryOrderView(false)
end
--[[
	影藏或者显示订单配送界面
]]
function StartDeliveryOrderMediator:ShowStartDeliveryOrderView(visible)
	if self.viewComponent then
		self.viewComponent:setVisible(visible)
	end
end
--[[
	关闭队伍界面
]]
function StartDeliveryOrderMediator:CloseTeamFormation()
	if self.teamMediator then
		-- 编队完成 关闭编队界面 刷新战斗准备界面阵容
		self:GetFacade():UnRegsitMediator("TeamFormationMediator")
		self:ShowStartDeliveryOrderView(true)
		self.teamMediator = nil
	else
		print('\n**************\n', 'logic error here should remove teamMediator in EnterBattleMediator but teamMediator is nil', '\n**************\n')
	end
end
function StartDeliveryOrderMediator:OnRegist(  )
	local StartDeliveryOrderCommand = require( 'Game.command.StartDeliveryOrderCommand')  
	self:GetFacade():RegistSignal(COMMANDS.COMMANDS_StartDeliveryOrder_Dlivery, StartDeliveryOrderCommand) -- 订单配送
	if not tolua.isnull(self:GetViewComponent()) then
		self:GetViewComponent():runAction(cc.Sequence:create(
		cc.DelayTime:create(0.1) ,  cc.CallFunc:create(function ()
			self:GetFacade():RegistSignal(COMMANDS.COMMANDS_StartDeliveryOrder_Refuse, StartDeliveryOrderCommand) -- 订单配送
		end)
		))
	end
	self:GetFacade():RegistSignal(COMMANDS.COMMANDS_StartDeliveryOrder_Cancel, StartDeliveryOrderCommand)  -- 订单取消
	self:GetFacade():RegistObserver("SHOW_TEAM_FORMATION", mvc.Observer.new(self.ProcessSignal, self)) 
	self:GetFacade():RegistObserver("REFRESH_SELECT_TEAM", mvc.Observer.new(self.ProcessSignal, self))
	self:GetFacade():RegistObserver("REFRESH_NOT_CLOSE_GOODS_EVENT", mvc.Observer.new(self.ProcessSignal, self))
	self:GetFacade():RegistObserver("CLOSE_TEAM_FORMATION", mvc.Observer.new(self.ProcessSignal, self))  
	self:GetFacade():RegistObserver(HomeScene_ChangeCenterContainer_TeamFormation, mvc.Observer.new(self.ProcessSignal, self))  
	regPost(POST.CARD_VIGOUR_DIAMOND_RECOVER)
	-- self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "allhide")
end

function StartDeliveryOrderMediator:OnUnRegist()
	--称出命令
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_StartDeliveryOrder_Dlivery)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_StartDeliveryOrder_Cancel)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_StartDeliveryOrder_Refuse)
	self:GetFacade():UnRegistObserver("SHOW_TEAM_FORMATION",self)  --注册团队显示界面事件
	self:GetFacade():UnRegistObserver("REFRESH_NOT_CLOSE_GOODS_EVENT",self) --刷新goodNode 的显示
	self:GetFacade():UnRegistObserver("CLOSE_TEAM_FORMATION",self) --关闭团队显示界面事件
	self:GetFacade():UnRegistObserver(HomeScene_ChangeCenterContainer_TeamFormation,self)    
	unregPost(POST.CARD_VIGOUR_DIAMOND_RECOVER)
	-- self:GetFacade():UnRegistObserver(SIGNALNAMES.QuestComment_CommentView,self)
	AppFacade.GetInstance():DispatchObservers(SGL.BREAK_TO_HOME_MEDIATOR)
end

return StartDeliveryOrderMediator
