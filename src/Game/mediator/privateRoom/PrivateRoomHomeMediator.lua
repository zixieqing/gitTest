--[[
包厢功能 主页面 mediator
--]]
local Mediator = mvc.Mediator
local PrivateRoomHomeMediator = class("PrivateRoomHomeMediator", Mediator)
local NAME = "privateRoom.PrivateRoomHomeMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local timerMgr = AppFacade.GetInstance():GetManager("TimerManager")
local BUY_SERVE_TIMES_COST = 50
local WAIT_DIALOGUE_INTERVAL = 10 
function PrivateRoomHomeMediator:ctor( params, viewComponent )
	self.super:ctor(NAME, viewComponent)
	local data = params or {}
	self.homeData = checktable(data)
	self.themeId = data.themeId or 1 -- 主题id
	self.isFirstLookFriend = true  -- 标识 第一次查看好友
end

function PrivateRoomHomeMediator:InterestSignals()
	local signals = {
		POST.PRIVATE_ROOM_HOME.sglName,
		POST.PRIVATE_ROOM_ASSISSTANT_SWITCH.sglName,
		POST.PRIVATE_ROOM_GUEST_ARRIVAL.sglName,
		POST.PRIVATE_ROOM_SERVE_TIMES_BUY.sglName,
		PRIVATEROOM_UPDATE_WALL,
		PRIVATEROOM_ARRIVAL_ACT_END,
		PRIVATEROOM_LEAVE_ACT_END,
		PRIVATEROOM_SERVE_EVENT,
		PRIVATEROOM_SERVE_CANCEL,
		PRIVATEROOM_SERVE_EVENT_END,
		PRIVATEROOM_SWITCH_THEME, 
		PRIVATEROOM_WAIT_DIALOGUE_END,
		SGL.NEXT_TIME_DATE, 
	}
	return signals
end

function PrivateRoomHomeMediator:ProcessSignal( signal )
	local name = signal:GetName()
	print(name)
	local data = checktable(signal:GetBody())
	if name == POST.PRIVATE_ROOM_HOME.sglName then
		local params = {
			leftServeTimes = data.leftServeTimes,
			baseServeTimes = data.baseServeTimes,
			leftBuyTimes = data.leftBuyTimes,
		}
		app.privateRoomMgr:SetPrivateRoomData(params)
		self:UpdateServeTimes()
		timerMgr:RemoveTimer(NAME)
		local leftTimes = checkint(data.refreshLeftTimes) + 2
		self:GetViewComponent():UpdateTimeLabel(leftTimes)
		timerMgr:AddTimer({name = NAME, countdown = leftTimes, callback = handler(self, self.Update)})
	elseif name == POST.PRIVATE_ROOM_ASSISSTANT_SWITCH.sglName then -- 更换服务员
		app.privateRoomMgr:SetWaiter(data.requestData.playerCardId)
		self:RefreshWaiter(data.requestData.playerCardId)
	elseif name == POST.PRIVATE_ROOM_GUEST_ARRIVAL.sglName then -- 客人到达
		-- 扣除服务次数
		local leftServeTimes = app.privateRoomMgr:GetLeftServeTimes() - 1
		app.privateRoomMgr:SetPrivateRoomData({leftServeTimes = leftServeTimes})
		self:UpdateServeTimes()
		self:GuestArrived(data)
	elseif name == POST.PRIVATE_ROOM_SERVE_TIMES_BUY.sglName then -- 购买次数
		app.gameMgr:GetUserInfo().diamond = checkint(data.diamond)
		AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI)
		-- 消耗购买次数
		local leftBuyTimes = app.privateRoomMgr:GetLeftBuyTimes() - 1
		app.privateRoomMgr:SetPrivateRoomData({leftServeTimes = checkint(data.leftServeTimes), leftBuyTimes = leftBuyTimes})
		self:UpdateServeTimes()
	elseif name == PRIVATEROOM_UPDATE_WALL then -- 更新陈列墙
		local wallData = app.privateRoomMgr:GetWallData()
		self:RefreshWall(wallData)
	elseif name == PRIVATEROOM_SWITCH_THEME then -- 更换主题
		local themeId = app.privateRoomMgr:GetThemeId()
		self:RefreshTheme(themeId)
		if app.privateRoomMgr:GetWaiter() then
			self:RefreshWaiter(app.privateRoomMgr:GetWaiter())
		end
	elseif name == PRIVATEROOM_ARRIVAL_ACT_END then -- 客人到达动画执行完毕
		if app.privateRoomMgr:IsLastGuest(data.guestId) then
			self:GetViewComponent():ArrivalActionEnd()
			timerMgr:AddTimer({name = 'PRIVATEROOM_RANDOM_DIALOGUE', countdown = WAIT_DIALOGUE_INTERVAL, callback = handler(self, self.UpdateRandomDialogTime), autoDelete = true})
		end
	elseif name == PRIVATEROOM_LEAVE_ACT_END then -- 客人离开动画执行完毕
		if app.privateRoomMgr:IsLastGuest(data.guestId) then
			app.privateRoomMgr:ClearGuestData()
			self:GetViewComponent():RestoredPrivateRoom()
		end
	elseif name == PRIVATEROOM_SERVE_EVENT then -- 开始上菜
		timerMgr:RemoveTimer('PRIVATEROOM_RANDOM_DIALOGUE') -- 移除对话定时器
		self:GetViewComponent():StartServing(data)
	elseif name == PRIVATEROOM_SERVE_EVENT_END then -- 上菜结束
		self:GetViewComponent():ServingEventEnd()
	elseif name == PRIVATEROOM_SERVE_CANCEL then -- 放弃订单
		timerMgr:RemoveTimer('PRIVATEROOM_RANDOM_DIALOGUE') -- 移除对话定时器
		self:GetViewComponent():AbandonOrder()
	elseif name == PRIVATEROOM_WAIT_DIALOGUE_END then -- 等待对话播放结束
		-- 重新开启定时器
		timerMgr:AddTimer({name = 'PRIVATEROOM_RANDOM_DIALOGUE', countdown = WAIT_DIALOGUE_INTERVAL, callback = handler(self, self.UpdateRandomDialogTime), autoDelete = true})
	elseif name == SGL.NEXT_TIME_DATE then -- 12点更新数据
		self.SendSignal(POST.PRIVATE_ROOM_HOME.cmdName)
	end
end

function PrivateRoomHomeMediator:Initial( key )
	self.super.Initial(self, key)
    local viewComponent = uiMgr:SwitchToTargetScene('Game.views.privateRoom.PrivateRoomHomeScene', {mediator = self})
	self:SetViewComponent(viewComponent)

	viewComponent.viewData.decorationBtnData.btn:setOnClickScriptHandler(handler(self, self.DecorationBtnCallback))
	viewComponent.viewData.souvenirBtnData.btn:setOnClickScriptHandler(handler(self, self.SouvenirBtnCallback))
	viewComponent.viewData.waiterBoardBtn:setOnClickScriptHandler(handler(self, self.WaiterBoardBtnCallback))
	viewComponent.viewData.serviceBtn:setOnClickScriptHandler(handler(self, self.ServiceBtnCallback))
	viewComponent.viewData.serviceLabelBg:setOnClickScriptHandler(handler(self, self.BuyServiceTimeCallback))
	viewComponent.viewData.VIPBtn:setOnClickScriptHandler(handler(self, self.VIPBtnCallback))
	viewComponent.viewData.tabNameLabel:setOnClickScriptHandler(handler(self, self.TipsBtnCallback))
	viewComponent.viewData.wallBg:setOnClickScriptHandler(handler(self, self.WallBtnCallback))
	viewComponent.viewData.friendBtn:setOnClickScriptHandler(handler(self, self.FriendBtnCallback))
	app.privateRoomMgr:InitPrivateRoomData(self.homeData)
	-- 开启定时器
	local leftTimes = checkint(self.homeData.refreshLeftTimes) + 2
	self:GetViewComponent():UpdateTimeLabel(leftTimes)
	timerMgr:AddTimer({name = NAME, countdown = leftTimes, callback = handler(self, self.Update)})
	self:InitView()
end
--[[
初始化页面
--]]
function PrivateRoomHomeMediator:InitView()
	local wallData = app.privateRoomMgr:GetWallData()
	self:RefreshWall(wallData)
	local themeId = app.privateRoomMgr:GetThemeId()
	self:RefreshTheme(themeId)
	if app.privateRoomMgr:GetWaiter() then
		self:RefreshWaiter(app.privateRoomMgr:GetWaiter())
	end
	if app.privateRoomMgr:GetGuestId() then
		timerMgr:AddTimer({name = 'PRIVATEROOM_RANDOM_DIALOGUE', countdown = WAIT_DIALOGUE_INTERVAL, callback = handler(self, self.UpdateRandomDialogTime), autoDelete = true})
		self:GetViewComponent():ChangeToServeState()
	end 
	self:UpdateServeTimes()
	-- self:GetViewComponent():GuestsLeft()
end
--[[
刷新主题
@params themeId int 主题Id
--]]
function PrivateRoomHomeMediator:RefreshTheme( themeId )
	local viewComponent = self:GetViewComponent()
	viewComponent:RefreshTheme(themeId)
end
--[[
刷新墙面
@params wallData map 纪念品数据
--]]
function PrivateRoomHomeMediator:RefreshWall( wallData )
	local viewComponent = self:GetViewComponent()
	viewComponent:RefreshWall(wallData)
end
--[[
刷新服务员状态
@params PlayerCardId int 卡牌自增id
--]]
function PrivateRoomHomeMediator:RefreshWaiter( PlayerCardId )
	local viewComponent = self:GetViewComponent()
	viewComponent:RefreshWaiter(PlayerCardId)
end
--[[
客人到达
--]]
function PrivateRoomHomeMediator:GuestArrived( data )
	app.privateRoomMgr:SetPrivateRoomData(data)
	self:GetViewComponent():GuestArrivedAction()
end
--[[
定时器回调
--]]
function PrivateRoomHomeMediator:Update( remainTime )
	if checkint(remainTime) > 0 then
		self:GetViewComponent():UpdateTimeLabel(remainTime)
	else
		timerMgr:RemoveTimer(NAME) 
		self:SendSignal(POST.PRIVATE_ROOM_HOME.cmdName)
	end
end
--[[
随机对话定时器回调
--]]
function PrivateRoomHomeMediator:UpdateRandomDialogTime( countdown )
	if countdown <= 0 then
		self:GetViewComponent():CreateCommonDialogue('waitDialogueId')
	end
end
--[[
更新服务次数
--]]
function PrivateRoomHomeMediator:UpdateServeTimes()
	local leftTimes = app.privateRoomMgr:GetLeftServeTimes()
	local maxTimes = app.privateRoomMgr:GetBaseServeTimes()
	self:GetViewComponent():UpdateServeTimesLabel(leftTimes, maxTimes)
end
---------------------------------------
----------------点击回调----------------
--[[
装修按钮点击回调
--]]
function PrivateRoomHomeMediator:DecorationBtnCallback( sender )
	PlayAudioByClickNormal()
	uiMgr:ShowInformationTips(__('敬请期待！'))
	-- app.router:loadMdt('Game.mediator.privateRoom.PrivateRoomThemeMediator')
end
--[[
纪念品按钮点击回调
--]]
function PrivateRoomHomeMediator:SouvenirBtnCallback( sender )
	PlayAudioByClickNormal()
	app.router:loadMdt('Game.mediator.privateRoom.PrivateRoomSouvenirMediator')
end
--[[
服务员面板点击回调
--]]
function PrivateRoomHomeMediator:WaiterBoardBtnCallback( sender )
	PlayAudioByClickNormal()
    local ChooseLobbyPeopleMediator = require( 'Game.mediator.ChooseLobbyPeopleMediator' )
	local params = {chooseType = 5, callback = function ( cardData )
		AppFacade.GetInstance():UnRegsitMediator("ChooseLobbyPeopleMediator")
		self:SendSignal(POST.PRIVATE_ROOM_ASSISSTANT_SWITCH.cmdName, {playerCardId = checkint(cardData.id)})
    end}
    local mediator = ChooseLobbyPeopleMediator.new(params)
    AppFacade.GetInstance():RegistMediator(mediator)
end
--[[
招待按钮点击回调
--]]
function PrivateRoomHomeMediator:ServiceBtnCallback( sender )
	PlayAudioByClickNormal()
	if app.privateRoomMgr:GetWaiter() and checkint(app.privateRoomMgr:GetWaiter()) ~= 0 then
		if app.privateRoomMgr:GetLeftServeTimes() > 0 then
			self:SendSignal(POST.PRIVATE_ROOM_GUEST_ARRIVAL.cmdName)
		else
			uiMgr:ShowInformationTips(__('招待次数已用尽'))
		end
	else
		uiMgr:ShowInformationTips(__('招待前请先设置服务员'))
	end
end
--[[
次数购买按钮点击回调
--]]
function PrivateRoomHomeMediator:BuyServiceTimeCallback( sender )
	PlayAudioByClickNormal()
	local costInfo = {goodsId = DIAMOND_ID, num = BUY_SERVE_TIMES_COST}

	local challengeTimes = CommonUtils.getVipTotalLimitByField('pvp')
	local vipConf = CommonUtils.GetConfig('player', 'vip', 1)
	local privateRoomBuyNum = vipConf.privateRoomBuyNum
	
	local strs = string.split(string.fmt(__('确定要追加|_num_|次招待次数吗'), {['_num_'] = privateRoomBuyNum}), '|')
	local textRich = {
		{text = strs[1]},
		{text = strs[2], fontSize = 26, color = '#ff0000'},
		{text = strs[3]}
	}
	local descrRich = {
		{text = __('当前还可以购买')},
		{text = tostring(app.privateRoomMgr:GetLeftBuyTimes()), fontSize = fontWithColor('15').fontSize, color = '#ff0000'},
		{text = __('次')},
	}
	local callback = function ()
		if app.privateRoomMgr:GetLeftBuyTimes() > 0 then
			if app.gameMgr:GetAmountByGoodId(DIAMOND_ID) >= BUY_SERVE_TIMES_COST then
				self:SendSignal(POST.PRIVATE_ROOM_SERVE_TIMES_BUY.cmdName)
			else
				if GAME_MODULE_OPEN.NEW_STORE then
					uiMgr:showDiamonTips()
				else
					uiMgr:ShowInformationTips(__('幻晶石不足'))
				end
			end
		else
			uiMgr:ShowInformationTips(__('购买次数不足'))
		end
	end
	-- 显示购买弹窗
	local layer = require('common.CommonTip').new({
		textRich = textRich,
		descrRich = descrRich,
		defaultRichPattern = true,
		costInfo = costInfo,
		callback = callback
	})
	layer:setPosition(display.center)
    uiMgr:GetCurrentScene():AddDialog(layer)
end

--[[
贵宾信息按钮点击回调
--]]
function PrivateRoomHomeMediator:VIPBtnCallback( sender )
	PlayAudioByClickNormal()
	local moduleM = require("Game.mediator.privateRoom.PrivateRoomGuestInfoHomeMediator")
	local mediator = moduleM.new()
	app:RegistMediator(mediator)
end
--[[
tips按钮点击回调
--]]
function PrivateRoomHomeMediator:TipsBtnCallback( sender )
	PlayAudioByClickNormal()
	uiMgr:ShowIntroPopup({moduleId = MODULE_DATA[tostring(RemindTag.BOX_MODULE)]})
end
--[[
陈列墙点击回调
--]]
function PrivateRoomHomeMediator:WallBtnCallback( sender )
	PlayAudioByClickNormal()
	local wallData = app.privateRoomMgr:GetWallData()
	AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'privateRoom.PrivateRoomHomeMediator'}, {name = 'privateRoom.PrivateRoomWallShowMediator', params = {wallData = wallData}}) 
end
--[[
好友按钮点击回调
--]]
function PrivateRoomHomeMediator:FriendBtnCallback( sender )
	PlayAudioByClickClose()
	local mediator = self:GetFacade():RetrieveMediator('LobbyFriendMediator')
	if mediator then
		mediator:GetViewComponent():setVisible(true)
		return
	end
	local mediator = require("Game.mediator.LobbyFriendMediator").new({isFirstLookFriend = self.isFirstLookFriend ,visitType = 3 })
	self:GetFacade():RegistMediator(mediator)
	self.isFirstLookFriend = false
end
----------------点击回调----------------
---------------------------------------
function PrivateRoomHomeMediator:OnRegist(  )
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "show")
	PlayBGMusic(AUDIOS.BGM2.Food_Dining.id)
	regPost(POST.PRIVATE_ROOM_HOME)
	regPost(POST.PRIVATE_ROOM_ASSISSTANT_SWITCH)
	regPost(POST.PRIVATE_ROOM_GUEST_ARRIVAL)
	regPost(POST.PRIVATE_ROOM_GUEST_SERVE)
	regPost(POST.PRIVATE_ROOM_GUEST_CANCEL)
	regPost(POST.PRIVATE_ROOM_SERVE_TIMES_BUY)
end

function PrivateRoomHomeMediator:OnUnRegist(  )
	AppFacade.GetInstance():DispatchObservers(HomeScene_ChangeCenterContainer, "hide")
	PlayBGMusic()
	unregPost(POST.PRIVATE_ROOM_HOME)
	unregPost(POST.PRIVATE_ROOM_ASSISSTANT_SWITCH)
	unregPost(POST.PRIVATE_ROOM_GUEST_ARRIVAL)
	unregPost(POST.PRIVATE_ROOM_GUEST_SERVE)
	unregPost(POST.PRIVATE_ROOM_GUEST_CANCEL)
	unregPost(POST.PRIVATE_ROOM_SERVE_TIMES_BUY)
	timerMgr:RemoveTimer(NAME)
	timerMgr:RemoveTimer('PRIVATEROOM_RANDOM_DIALOGUE')
end
return PrivateRoomHomeMediator