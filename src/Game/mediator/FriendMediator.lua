local Mediator = mvc.Mediator

local FriendMediator = class("FriendMediator", Mediator)

local NAME = "FriendMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")

function FriendMediator:ctor( params, viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.args = checktable(params) or {}
	self.showLayer = {}
	self.rightClickTag = checkint(self.args.friendType or FriendTabType.FRIENDLIST)  --右边好友列表tag
	self.friendDatas = {}
	if self.args.strangerDatas then
		self.strangerDatas = self.args.strangerDatas
	end
	if not next(self.args.friendRequest or {}) then
		AppFacade.GetInstance():GetManager("DataManager"):ClearRedDotNofication(tostring(RemindTag.NEW_FRIENDS), RemindTag.NEW_FRIENDS)
	end
end
function FriendMediator:InterestSignals()
	local signals = {
		SIGNALNAMES.Friend_List_Callback,
		SIGNALNAMES.Friend_PlayerInfo_Callback,
		FRIEND_REMARK_UPDATE
	}

	return signals
end
function FriendMediator:ProcessSignal( signal )
	local name = signal:GetName()
	print(name)
	if name == SIGNALNAMES.Friend_List_Callback then
		self.friendDatas = checktable(signal:GetBody())
		gameMgr:GetUserInfo().friendList = self.friendDatas.friendList
		local contactsId = ChatUtils.GetRecentContactsId()
		if contactsId == nil then
			self.friendDatas.recentContactsList = {}
			self:ConvertFriendDatas()
			self:UpdateFriendList()
			self:RightButtonActions(self.rightClickTag)
			if self.strangerDatas then
				self:SelectStrangerChat()
			end
		else
			self:SendSignal(COMMANDS.COMMAND_Friend_PlayerInfo, {playerIdList = contactsId})
		end
		self:RefreshTabStatus()
	elseif name == SIGNALNAMES.Friend_PlayerInfo_Callback then
		local datas = signal:GetBody()
		self.friendDatas.recentContactsList = checktable(datas.playerList)
		self:ConvertFriendDatas()
		self:UpdateFriendList()
		self:RightButtonActions(self.rightClickTag)
		if self.strangerDatas then
			self:SelectStrangerChat()
		end
	elseif name == FRIEND_REMARK_UPDATE then
		self:SendSignal(COMMANDS.COMMAND_Friend_List)
	end
end
function FriendMediator:Initial( key )
	self.super.Initial(self,key)
	local scene = uiMgr:GetCurrentScene()
	local viewComponent  = require( 'Game.views.FriendView' ).new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	-- scene:AddGameLayer(viewComponent)
	scene:AddDialog(viewComponent)
	--绑定相关的事件
	local viewData = viewComponent.viewData_
	for k, v in pairs( viewData.buttons ) do
		v:setOnClickScriptHandler(handler(self,self.RightButtonActions))
	end
end
--[[
右边不同类型model按钮的事件处理逻辑
@param sender button对象
--]]
function FriendMediator:RightButtonActions( sender )
	-- PlayAudioClip(AUDIOS.UI.ui_tab_change.id)
	local tag = 0
	if type(sender) == 'number' then
		tag = sender
	else
		tag = sender:getTag()
		PlayAudioClip(AUDIOS.UI.ui_depot_tabchange.id)
		if self.rightClickTag == tag then
			return
		end
	end

	local viewData = self:GetViewComponent().viewData_
	for k, v in pairs( viewData.buttons ) do
		local curTag = v:getTag()
		if tag == curTag then
			v:setChecked(true)
			v:setEnabled(false)
			v:getChildByName('title'):setColor(cc.c3b(233, 73, 26))
		else
			v:setChecked(false)
			v:setEnabled(true)
			v:getChildByName('title'):setColor(cc.c3b(92, 92, 92))
		end
	end

	local prePanel = self.showLayer[tostring(self.rightClickTag)]
	if prePanel then
		prePanel:setVisible(false)
	end

	self.rightClickTag = tag
	local viewData = self.viewComponent.viewData_
	local modelLayout = viewData.modelLayout

	-- 特殊处理 因为好友切磋页面不能缓存，所以切换的时候要释放掉
	if self.showLayer[tostring(FriendTabType.FRIEND_BATTLE)] then
		app:UnRegsitMediator('FriendBattleMediator')
		self.showLayer[tostring(FriendTabType.FRIEND_BATTLE)] = nil
	end

	if self.showLayer[tostring(tag)] then
		self.showLayer[tostring(tag)]:setVisible(true)
	else
		if tag == 1001 then -- 好友
			local FriendListMediator = require( 'Game.mediator.FriendListMediator')
			local mediator = FriendListMediator.new({friendDatas = checktable(self.friendDatas), friendListType = self.args.friendListType})
			self:GetFacade():RegistMediator(mediator)
			modelLayout:addChild(mediator:GetViewComponent())
			self.showLayer[tostring(tag)] = mediator:GetViewComponent()
		elseif tag == 1002 then	--捐助
			local FriendDonationMediator = require( 'Game.mediator.FriendDonationMediator' )
			local mediator = FriendDonationMediator.new({
				assistanceList = checktable(self.friendDatas.assistanceList),
				assistanceDoneList = checktable(self.friendDatas.assistanceDoneList),
				assistanceLimit = checkint(self.friendDatas.assistanceLimit),
				assistanceNum = checkint(self.friendDatas.assistanceNum)
			})
			self:GetFacade():RegistMediator(mediator)
			modelLayout:addChild(mediator:GetViewComponent())
			self.showLayer[tostring(tag)] = mediator:GetViewComponent() -- mediator:GetViewComponent()
		elseif tag == 1003 then -- 切磋
			local friendBattleMediator = require( 'Game.mediator.friend.FriendBattleMediator' )
			local mediator = friendBattleMediator.new({
				
			})
			self:GetFacade():RegistMediator(mediator)
			modelLayout:addChild(mediator:GetViewComponent())
			self.showLayer[tostring(tag)] = mediator:GetViewComponent() -- mediator:GetViewComponent()
		end
	end
end
function FriendMediator:ConvertFriendDatas()
	local temp = {}
	for i, v in ipairs(checktable(self.friendDatas.friendRequest)) do
		-- 筛选别人对我的请求
		if v.type == 1 then
			-- 去重
			local isRepeat = false
			for _, friend in ipairs(gameMgr:GetUserInfo().friendList) do
				if checkint(friend.friendId) == checkint(v.friendId) then
					isRepeat = true
					break
				end
			end
			if not isRepeat then
				table.insert(temp, v)
			end
		end
	end
	self.friendDatas.friendRequest = temp
end
--[[
刷新页签状态
--]]
function FriendMediator:RefreshTabStatus( status )
	local viewData = self:GetViewComponent().viewData_
	if status == nil then
		if self.friendDatas.assistanceList and next(self.friendDatas.assistanceList) ~= nil then
			viewData.buttons['1002']:getChildByName('remindIcon'):setVisible(true)
		else
			viewData.buttons['1002']:getChildByName('remindIcon'):setVisible(false)
		end
	else
		viewData.buttons['1002']:getChildByName('remindIcon'):setVisible(status)
	end
end
--[[
添加陌生人聊天
--]]
function FriendMediator:SelectStrangerChat()
    local friendListMediator = AppFacade.GetInstance():RetrieveMediator('FriendListMediator')
    if friendListMediator then
        friendListMediator:SwitchChatView(self.strangerDatas)
    end
end
--[[

--]]
function FriendMediator:UpdateFriendList()
	local mediator    = AppFacade.GetInstance():RetrieveMediator('FriendListMediator')
	if mediator then
		mediator:UpdateFriendData(self.friendDatas)
	end

end
function FriendMediator:enterLayer()
	self:SendSignal(COMMANDS.COMMAND_Friend_List)
end

function FriendMediator:OnRegist(  )
	local FriendCommand = require('Game.command.FriendCommand')
	-- self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "allhide")
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Friend_List, FriendCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Friend_PlayerInfo, FriendCommand)
	self:enterLayer()
end

function FriendMediator:OnUnRegist(  )
	local scene = uiMgr:GetCurrentScene()
	scene:RemoveGameLayer(self.viewComponent)
	-- self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "hide")
	self:GetFacade():DispatchObservers(FRIEND_UPDATE_LOBBY_FRIEND_BTN_STATE)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Friend_List)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Friend_PlayerInfo)
	AppFacade.GetInstance():UnRegsitMediator('FriendListMediator')
	AppFacade.GetInstance():UnRegsitMediator('FriendDonationMediator')
	AppFacade.GetInstance():UnRegsitMediator('FriendBattleMediator')
	-- 红点相关
	if ChatUtils.HasUnreadMessage() or checkint(app.dataMgr:GetRedDotNofication(tostring(RemindTag.NEW_FRIENDS), RemindTag.NEW_FRIENDS)) ~= 0 then
		app.dataMgr:AddRedDotNofication(tostring(RemindTag.FRIENDS), RemindTag.FRIENDS, "[好友]-FriendMediator:OnUnRegist")
		AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.FRIENDS})
	else
		app.dataMgr:ClearRedDotNofication(tostring(RemindTag.FRIENDS), RemindTag.FRIENDS, "[好友]-FriendMediator:OnUnRegist")
		AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.FRIENDS})
	end
end

return FriendMediator
