--[[
好友列表Mediator
--]]
local Mediator = mvc.Mediator

local FriendListMediator = class("FriendListMediator", Mediator)

local NAME = "FriendListMediator"
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
local socketMgr = AppFacade.GetInstance('AppFacade'):GetManager("ChatSocketManager")
local chatMgr = AppFacade.GetInstance('AppFacade'):GetManager('ChatSocketManager')
local labelparser = require("Game.labelparser")
local voiceChatMgr = AppFacade.GetInstance():GetManager("GlobalVoiceManager")
local voiceEngine = voiceChatMgr:GetVoiceNode()
local friendCell = require('Game.views.FriendCell')
local friendCommendCell = require('home.FriendCommendCell')
local friendAddCell = require('home.FriendAddCell')
local FriendListView = require('Game.views.FriendListView')
local isSearchOnlyUID = FriendListView.isSearchOnlyUID
local MAX_HISTORY_NUM = 10
local MyFriendsType = {
	FRIEND = 1,
	BLACKLIST = 2
}

local MyFriendsDatas = {
	{name = __('好友'), tag = MyFriendsType.FRIEND},
	{name = __('黑名单'), tag = MyFriendsType.BLACKLIST}
}
local SenderType = {
	mySelf = 0,
	otherPeople = 1
}
local messType = {
	-- ['look'] = 'look',--点击查看
	-- ['joinNow'] = 'joinNow',--点击加入
	-- ['playName'] = 'playName',--玩家详情
	-- ['guild'] = 'guild',--公会详情
	-- ['stage'] = 'stage',--副本名详情
	-- ['activity'] = 'activity',--活动详情
	['desc'] = 'desc',--正常文本描述

	['fileid'] = 'fileid',--语音消息id
	['messagetype'] = 'messagetype',--消息类型1非语音2语音
}
function FriendListMediator:ctor( params, viewComponent )
	self.super:ctor(NAME,viewComponent)
	local datas = checktable(params) or {}
	self.friendDatas = datas.friendDatas or {}
	self.blacklist = gameMgr:GetUserInfo().blacklist
	sceneWorld:setMultiTouchEnabled(true)
	-- 排序
	self:SortFriendsList(self.friendDatas.friendList)
	self:SortFriendsList(self.friendDatas.recentContactsList)
	-- 更新黑名单列表
	self:UpdateBlackList()
	self.showListLayer = {}
	self.removeFriendsList = {}
	self.selectedListType = checkint(datas.friendListType or FriendListViewType.RECENT_CONTACTS) -- 左侧页签选中
	self.selectedMyFriendsType = MyFriendsType.FRIEND -- 好友列表选中
	self.isFindFriend = false -- 是否查找好友
	self.findListDatas = {} -- 好友查找
	self.chattingFriendIndex = nil -- 当前聊天的好友
	self.chattingType = nil -- 当前聊天类型
	------------------------------
	self.sendMessData = {} -- 发送信息数据
	self.chatAllData = {}
	self.otherPlayerId = nil
	self.otherPlayerAvatar = nil
	------------------------------
	self.isMoving = false
	self.showdelCheckbox = false
end

function FriendListMediator:InterestSignals()
	local signals = {
		SIGNALNAMES.Friend_List_Callback,
		SIGNALNAMES.Friend_DelFriend_Callback,
		SIGNALNAMES.Friend_FindFriend_Callback,
		SIGNALNAMES.Friend_AddFriend_Callback,
		SIGNALNAMES.Friend_HandleAddFriend_Callback,
		SIGNALNAMES.Friend_RefreshRecmmend_Callback,
		SIGNALNAMES.Friend_EmptyRequest_Callback,
		SIGNALNAMES.Chat_GetPrivateMessage_Callback,
		SIGNALNAMES.Chat_SendPrivateMessage_Callback,
		SIGNALNAMES.Chat_NewPlayerInfo_Callback,
        POST.FRIEND_SET_TOP.sglName, 
		POST.FRIEND_SET_TOP_CANCEL.sglName, 
		FRIEND_POPUP_DEL_BLACKLIST,
		FRIEND_POPUP_ADD_BLACKLIST,
		FRIEND_REFRESH_EDITBOX,
		"VOICE_EVENT"
	}
	return signals
end

function FriendListMediator:ProcessSignal( signal )
	local name = signal:GetName() 
	if name == SIGNALNAMES.Friend_FindFriend_Callback then -- 查询好友
    	local datas = signal:GetBody()
    	self.isFindFriend = true
    	local gridView = self:GetViewComponent().viewData_.commendGridView
    	if datas.playerId then
    		self.findListDatas = datas
			gridView:setCountOfCell(1)
	    	gridView:reloadData()
    	else
    		self.findListDatas = {}
    		gridView:setCountOfCell(0)
	    	gridView:reloadData()
    	end
	elseif name == SIGNALNAMES.Friend_AddFriend_Callback then
		local datas = signal:GetBody()
		if self.isFindFriend then
			self.findListDatas.isAdd = 1
		else
			for i,v in ipairs(self.friendDatas.recommendFriendList) do
				if checkint(v.id) == checkint(datas.friendId) then
					v.isAdd = 1
					break
				end
			end
		end
	    self:GetViewComponent().viewData_.commendGridView:reloadData()
		uiMgr:ShowInformationTips(__('已发出请求'))
    elseif name == SIGNALNAMES.Friend_HandleAddFriend_Callback then
    	uiMgr:ShowInformationTips(__('添加成功'))
    	local datas = signal:GetBody()
		for i,v in ipairs(self.friendDatas.friendRequest) do
			if checkint(v.friendId) == checkint(datas.friendId) then
				table.remove(self.friendDatas.friendRequest, i)
				break
			end
		end
		if 0 == #checktable(self.friendDatas.friendRequest) then
			self.showListLayer[tostring(FriendListViewType.ADD_FRIENDS)]:getChildByName('empty'):setVisible(true)
		else
			self.showListLayer[tostring(FriendListViewType.ADD_FRIENDS)]:getChildByName('empty'):setVisible(false)
		end
		local requestGridView = self.showListLayer[tostring(FriendListViewType.ADD_FRIENDS)]:getChildByName('gridView')
		requestGridView:setCountOfCell(table.nums(self.friendDatas.friendRequest))
    	requestGridView:reloadData()
    	self:AddFriendAction(datas)
    	if table.nums(self.friendDatas.friendRequest) == 0 then
    		self:ClearNewFriendsRemind()
   		end
    elseif name == SIGNALNAMES.Friend_RefreshRecmmend_Callback then
    	local datas = signal:GetBody()
    	self.isFindFriend = false
    	self.friendDatas.recommendFriendList = checktable(datas.recommendFriendList)
    	self:GetViewComponent().viewData_.commendGridView:setCountOfCell(#self.friendDatas.recommendFriendList)
    	self:GetViewComponent().viewData_.commendGridView:reloadData()
    	self:ClearNewFriendsRemind()
    elseif name == SIGNALNAMES.Friend_EmptyRequest_Callback then
    	self.friendDatas.friendRequest = {}
    	self:ClearNewFriendsRemind()
		local requestGridView = self.showListLayer[tostring(FriendListViewType.ADD_FRIENDS)]:getChildByName('gridView')
		requestGridView:setCountOfCell(table.nums(self.friendDatas.friendRequest))
    	requestGridView:reloadData()
    	self:RefreshListTabStatus()
	elseif name == SIGNALNAMES.Chat_SendPrivateMessage_Callback then
		local chatDatas = {}
		local datas = self:GetFriendDatas()
		chatDatas.sendPlayerId = gameMgr:GetUserInfo().playerId
		chatDatas.sendPlayerName = gameMgr:GetUserInfo().playerName
		chatDatas.receivePlayerId = self.sendMessData.friendId
		chatDatas.receivePlayerName = self.sendMessData.name
		chatDatas.content = self.sendMessData.message
		chatDatas.sendTime = self.sendMessData.sendTime
		chatDatas.messagetype = CHAT_MSG_TYPE.TEXT
		chatDatas.msgType = 1
		ChatUtils.InertChatMessage(chatDatas)
		if datas.friendId == self.sendMessData.friendId then
			self:UpdateChatList(self.sendMessData)
		end
		self:AddRecentContacts(self.sendMessData.friendId)
	elseif name == SIGNALNAMES.Chat_GetPrivateMessage_Callback then
		local datas = signal:GetBody()
		if not datas.messages then
			datas = {messages = {datas}}
		end
		for i,v in ipairs(datas.messages) do
			-- 判断是否为当前会话
			if checkint(self.otherPlayerId) == checkint(v.friendId) then
				-- 更新消息读取状态
				self:ReadMessageWithPlayerId(v.friendId)
				local parsedtable = labelparser.parse(v.message)
				local tempTab = {}
				--过滤非法标签
				for i,v in ipairs(parsedtable) do
					if messType[v.labelname] then
						tempTab[v.labelname] = v.content
					end
				end
				local chatDatas = {}
				chatDatas.message = v.message or '<desc>....</desc>'
				chatDatas.sender = SenderType.otherPeople
				chatDatas.name = v.friendName
				chatDatas.sendTime = v.sendTime or os.time()
				chatDatas.messagetype = tempTab['messagetype']
				chatDatas.fileid = tempTab['fileid']
				chatDatas.playerId = v.friendId
				table.insert(self.chatAllData,chatDatas)
				self:UpdateChatList(chatDatas)
			else
				self:GetNewPrivateMessage(v)
			end
		end
	elseif name == SIGNALNAMES.Chat_NewPlayerInfo_Callback then
		local datas = signal:GetBody()
		for i, v in ipairs(checktable(datas)) do
			table.insert(self.friendDatas.recentContactsList, v)
		end
		self:UpdateRecentContactsList()
	elseif name == FRIEND_POPUP_ADD_BLACKLIST then
		local datas = signal:GetBody()
		self:AddBlacklistAction(datas)
	elseif name == FRIEND_POPUP_DEL_BLACKLIST then
		local datas = signal:GetBody()
		self:DeleteBlacklistAction(datas.blacklistId)
	elseif name == FRIEND_REFRESH_EDITBOX then -- 更新输入框状态
		local datas = signal:GetBody()
		self:RefreshEditBox(datas.isEnabled)
	elseif name == 'VOICE_EVENT' then
		local body = signal:GetBody()
		local name = body.name
		local code = checkint(body.code)
		if name == StateType.State_Upload then
			--上传
			if code == 11 or (code == 12293 and device.platform == "android") then
				local friendDatas = self:GetFriendDatas()
				self.sendMessData= {}
				local chatDatas = {}
				chatDatas.name = gameMgr:GetUserInfo().playerName
				chatDatas.message = string.format('<fileid>%s</fileid><messagetype>%d</messagetype>', body.fileID, CHAT_MSG_TYPE.SOUND)
				chatDatas.sendTime = getServerTime()
				chatDatas.sender = SenderType.mySelf
				chatDatas.messagetype = CHAT_MSG_TYPE.SOUND
				chatDatas.fileid = body.fileID
				chatDatas.playerId = gameMgr:GetUserInfo().playerId
				chatDatas.channel = self.chatChannel
				self.sendMessData = chatDatas
				chatMgr:SendPacket( NetCmd.RequestPrivateSendMessage, {friendId = friendDatas.friendId, time = chatDatas.sendTime, 
							message = chatDatas.message})
				socketMgr:InsertMessageVo(chatDatas)
				AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.Chat_GetMessage_Callback,chatDatas)
			end
		end
	elseif name == POST.FRIEND_SET_TOP.sglName then
		local datas = signal:GetBody()
		local playerId = datas.requestData.friendId
		self:RefreshSetTopList(playerId, os.time())
	elseif name == POST.FRIEND_SET_TOP_CANCEL.sglName then
		local datas = signal:GetBody()
		local playerId = datas.requestData.friendId
		self:RefreshSetTopList(playerId, nil)
	end
end

function FriendListMediator:Initial( key )
	self.super.Initial(self,key)
	local viewComponent = FriendListView.new()
	self:SetViewComponent(viewComponent)
	--绑定相关的事件
	local viewData = viewComponent.viewData_
	for k, v in pairs( viewData.tabButtons ) do
		display.commonUIParams(v, {cb = handler(self, self.ListTabButtonActions)})
	end
	viewData.expressionBtn:setOnClickScriptHandler(handler(self, self.ExpressionButtonCallback))
	viewData.sendBtn:setOnClickScriptHandler(handler(self, self.SendButtonCallback))
	viewData.addBtn:setOnClickScriptHandler(handler(self, self.AddFriendButtonCallback))
    if isElexSdk() then
        viewData.voiceBtn:setOnLongClickScriptHandler(handler(self, self.LongEventAction))
    end
	-- 推广员是够开启
	if gameMgr:GetUserInfo().isRecommendOpen then
		viewData.generalizeBtn:setVisible(true)
		viewData.generalizeBtn:setOnClickScriptHandler(handler(self, self.GeneralizeButtonCallback))
	else
		viewData.generalizeBtn:setVisible(false)
	end
	-- 添加好友页面
	viewData.commendGridView:setDataSourceAdapterScriptHandler(handler(self, self.CommendDataSourceAction))
	viewData.searchBtn:setOnClickScriptHandler(handler(self, self.SearchButtonCallback))
	viewData.emptyBtn:setOnClickScriptHandler(handler(self, self.EmptyButtonCallback))
	viewData.deleteBtn:setOnClickScriptHandler(handler(self, self.DeleteButtonCallback))
	viewData.changeBtn:setOnClickScriptHandler(handler(self, self.CommendChangeButtonCallback))
	-- 批量删除
	viewData.removeMultiFriendsBtn:setOnClickScriptHandler(handler(self, self.DeleteMultiFriendsButtonCallback))
	viewData.delConfirmBtn:setOnClickScriptHandler(handler(self, self.DeleteMultiFriendsConfirmButtonCallback))
	viewData.delCancelBtn:setOnClickScriptHandler(handler(self, self.DeleteMultiFriendsCancelButtonCallback))
	self:ListTabButtonActions(self.selectedListType)
	self:InitListView()
	-- 语音
	-- if device.platform == 'ios' or device.platform == 'android' then
		sceneWorld:setOnTouchEndedAfterLongClickScriptHandler(handler(self, self.LongClickEndHandler))
		sceneWorld:setOnTouchMovedAfterLongClickScriptHandler(function(sender, touch, duration)
			local y = touch:getLocation().y
			if y > 200 then
				self.isMoving = true
			else
				self.isMoving = false
			end
		end)
	-- end
end
--[[
根据列表信息判断初始化页面
--]]
function FriendListMediator:InitListView()
	if #self.friendDatas.recentContactsList ~= 0 then
		return
	elseif #self.friendDatas.friendList ~= 0 then
		self:ListTabButtonActions(FriendListViewType.MY_FRIENDS)
	else
		self:ListTabButtonActions(FriendListViewType.ADD_FRIENDS)
	end
end
--[[
列表页签点击回调
--]]
function FriendListMediator:ListTabButtonActions( sender )
	local tag = 0
	if type(sender) == 'number' then
		tag = sender
	else
		tag = sender:getTag()
		PlayAudioClip(AUDIOS.UI.ui_depot_tabchange.id)
		if self.selectedListType == tag then
			return
		end
	end

	local viewData = self:GetViewComponent().viewData_
	for k, v in pairs( viewData.tabButtons ) do
		local curTag = v:getTag()
		if tag == curTag then
			v:setEnabled(false)
			v:getChildByName('title'):setColor(ccc3FromInt('#5b3c25'))
		else
			v:setEnabled(true)
			v:getChildByName('title'):setColor(ccc3FromInt('#ffffff'))
		end
	end

	if self.showListLayer[tostring(self.selectedListType)] then
		self.showListLayer[tostring(self.selectedListType)]:setVisible(false)
	end

	self.selectedListType = tag

	if self.showListLayer[tostring(tag)] then
		self.showListLayer[tostring(tag)]:setVisible(true)
	else
		-- 创建
		self:CreateListLayer(tag)
	end
	if tag == FriendListViewType.RECENT_CONTACTS then
		if 0 == #checktable(self.friendDatas.recentContactsList) then
			self.showListLayer[tostring(tag)]:getChildByName('empty'):setVisible(true)
		else
			self.showListLayer[tostring(tag)]:getChildByName('empty'):setVisible(false)
		end
	elseif tag == FriendListViewType.MY_FRIENDS then
		if 0 == (table.nums(self.friendDatas.friendList) + table.nums(self.blacklist)) then
			self.showListLayer[tostring(tag)]:getChildByName('empty'):setVisible(true)
		else
			self.showListLayer[tostring(tag)]:getChildByName('empty'):setVisible(false)
		end
	elseif tag == FriendListViewType.ADD_FRIENDS then
		if 0 == #checktable(self.friendDatas.friendRequest) then
			self.showListLayer[tostring(tag)]:getChildByName('empty'):setVisible(true)
		else
			self.showListLayer[tostring(tag)]:getChildByName('empty'):setVisible(false)
		end
	end
	self:RefreshRightView(tag)
	self:RefreshListTabStatus()
end
--[[
创建好友列表
--]]
function FriendListMediator:CreateListLayer( tag )
	local viewData = self.viewComponent.viewData_
	local listLayout = viewData.listLayout
	local listSize = cc.size(460, 502)
	local listLayer = CLayout:create(listSize)
	self.showListLayer[tostring(tag)] = listLayer
	listLayout:addChild(listLayer, 10)
	listLayer:setPosition(cc.p(232, 268))
	if tag == FriendListViewType.RECENT_CONTACTS then -- 最近联系
		local gridView = CGridView:create(cc.size(460, 500))
		gridView:setName('gridView')
		gridView:setDirection(eScrollViewDirectionVertical)
		gridView:setPosition(cc.p(listSize.width/2, 252))
		gridView:setColumns(1)
		gridView:setSizeOfCell(cc.size(460, 106))
		gridView:setDataSourceAdapterScriptHandler(handler(self, self.RecentContactsDataSourceAction))
		gridView:setCountOfCell(#checktable(self.friendDatas.recentContactsList))
		gridView:reloadData()
		listLayer:addChild(gridView, 10)

		-- 全空状态
		local bgSize = cc.size(404, 574)
		local leftEmptyView = display.newLayer(bgSize.width * 0.5 - 8, bgSize.height * 0.5 - 40,{size = bgSize, ap = cc.p(0.5,0.5)})
		leftEmptyView:setName('empty')
		listLayer:addChild(leftEmptyView,20)
	
		local msgEmptyLabel = display.newLabel(
			bgSize.width * 0.58,
			bgSize.height * 0.5,
			fontWithColor('14', {text = __('没有最近联系人')}))
		leftEmptyView:addChild(msgEmptyLabel)
		leftEmptyView:setVisible(false)

	elseif tag == FriendListViewType.MY_FRIENDS then	-- 我的好友
		------------------列表-------------------
		local expandableListView = CExpandableListView:create(cc.size(460, 500))
		expandableListView:setDirection(eScrollViewDirectionVertical)
		expandableListView:setName('expandableListView')
		expandableListView:setPosition(cc.p(listSize.width/2, 252))
		listLayer:addChild(expandableListView, 10)
		self:UpdateExpandableListView()
		self:UpdateFriendListNumLabel()
		self:MyFriendsTabBtnCallback(MyFriendsType.FRIEND)

		-- 全空状态
		local bgSize = cc.size(404, 574)
		local leftEmptyView = display.newLayer(bgSize.width * 0.5 - 8, bgSize.height * 0.4 - 40,{size = bgSize, ap = cc.p(0.5,0.5)})
		leftEmptyView:setName('empty')
		listLayer:addChild(leftEmptyView,20)
	
		local msgEmptyLabel = display.newLabel(
			bgSize.width * 0.58,
			bgSize.height * 0.5,
			fontWithColor('14', {text = __('没有好友')}))
		leftEmptyView:addChild(msgEmptyLabel)
		leftEmptyView:setVisible(false)

		------------------列表-------------------
	elseif tag == FriendListViewType.ADD_FRIENDS then	-- 添加好友
		local gridView = CGridView:create(cc.size(460, 500))
		gridView:setDirection(eScrollViewDirectionVertical)
		gridView:setPosition(cc.p(listSize.width/2, 252))
		gridView:setName('gridView')
		gridView:setColumns(1)
		gridView:setSizeOfCell(cc.size(460, 106))
		gridView:setDataSourceAdapterScriptHandler(handler(self, self.AddFriendsDataSourceAction))
		gridView:setCountOfCell(#checktable(self.friendDatas.friendRequest))
		gridView:reloadData()
		listLayer:addChild(gridView, 10)
		viewData.commendGridView:setCountOfCell(#checktable(self.friendDatas.recommendFriendList))
		viewData.commendGridView:reloadData()

		-- 全空状态
		local bgSize = cc.size(404, 574)
		local leftEmptyView = display.newLayer(bgSize.width * 0.5 - 8, bgSize.height * 0.5 - 40,{size = bgSize, ap = cc.p(0.5,0.5)})
		leftEmptyView:setName('empty')
		listLayer:addChild(leftEmptyView,20)
	
		local msgEmptyLabel = display.newLabel(
			bgSize.width * 0.58,
			bgSize.height * 0.5,
			fontWithColor('14', {text = __('没有好友邀请')}))
		leftEmptyView:addChild(msgEmptyLabel)
		leftEmptyView:setVisible(false)
	end
end
--[[
更新好友列表
--]]
function FriendListMediator:UpdateExpandableListView()
	local expandableListView = self.showListLayer[tostring(FriendListViewType.MY_FRIENDS)]:getChildByName('expandableListView')
	if not expandableListView then return end
	expandableListView:removeAllExpandableNodes()
	-- 添加类别
	for i,v in ipairs(MyFriendsDatas) do
		local expandableNode = CExpandableNode:create()
		local size = cc.size(460, 54)
		expandableNode:setContentSize(size)
		expandableListView:insertExpandableNodeAtLast(expandableNode)
		local friendTypeTab = display.newButton(size.width/2, size.height/2, {tag = v.tag, useS = false, n = _res('ui/home/friend/friends_btn_tab.png')})
		friendTypeTab:setOnClickScriptHandler(handler(self, self.MyFriendsTabBtnCallback))
		expandableNode:addChild(friendTypeTab, 1)
		local tabName = display.newLabel(30, friendTypeTab:getContentSize().height/2, fontWithColor(16, {ap = cc.p(0, 0.5), text = v.name}))
		tabName:setName('name')
		expandableNode:addChild(tabName, 10)
		local numLabel = display.newLabel(35+display.getLabelContentSize(tabName).width, friendTypeTab:getContentSize().height/2, fontWithColor(16, {ap = cc.p(0, 0.5), text = ''}))
		numLabel:setName('numLabel')
		expandableNode:addChild(numLabel, 10)
		local arrow = display.newImageView(_res('ui/home/kitchen/cooking_level_up_ico_arrow.png'), friendTypeTab:getContentSize().width - 22, friendTypeTab:getContentSize().height/2)
		arrow:setName('arrow')
		expandableNode:addChild(arrow, 10)
		-- 添加cell
		if v.tag == MyFriendsType.FRIEND then -- 好友
			for i,v in ipairs(self.friendDatas.friendList) do
				expandableListView:runAction(
					cc.Sequence:create(
						cc.DelayTime:create(i*0.1),
						cc.CallFunc:create(function ()
							local node = friendCell.new(cc.size(460, 106))
							node.bgBtn:setUserTag(1)
							node.bgBtn:setTag(i)
							node.eventnode:setPositionY(node.eventnode:getPositionY()+ 5)
							node.bgBtn:setOnClickScriptHandler(handler(self, self.FriendListCellCallback))
							node.avatarIcon:setTag(i)
							node.avatarIcon:setOnClickScriptHandler(function ( sender )
								local tag = sender:getTag()
								if self.friendDatas.friendList[tag] then
									uiMgr:AddDialog('common.PlayerHeadPopup', {playerId = self.friendDatas.friendList[tag].friendId, type = HeadPopupType.FRIEND})
								end
							end)
							node.checkbox:setTag(i)
							node.checkbox:setOnClickScriptHandler(function ( sender )  
								self:CheckboxClickAction(sender)
							end)
							node.checkbox:setVisible(checkbool(self:getShowDelCheckbox()))
							local datas = v
							-- 判断是否存在备注
							local nameColor = '#843f11'
							if datas.noteName and datas.noteName ~= '' then
								node.nameLabel:setString(datas.noteName)
								nameColor = '#cb5600'
							else
								node.nameLabel:setString(datas.name)
							end
							if checkint(datas.isOnline) == 1 then
								node.nameLabel:setColor(ccc3FromInt(nameColor))
								node.signLabel:setColor(ccc3FromInt('#aa8b8b'))
								node.avatarIcon:RefreshSelf({level = datas.level, isGray = false, avatar = datas.avatar, avatarFrame = datas.avatarFrame})
								node.bgBtn:setNormalImage(_res('ui/home/friend/friends_list_frame_default.png'))
								node.bgBtn:setSelectedImage(_res('ui/home/friend/friends_list_frame_default.png'))
								display.fixLabelText(node.signLabel, {text = datas.sign, maxW = 320})
							elseif checkint(datas.isOnline) == 0 then
								node.nameLabel:setColor(ccc3FromInt('#5c5c5c'))
								node.signLabel:setColor(ccc3FromInt('#707070'))
								node.avatarIcon:RefreshSelf({level = datas.level, isGray = true, avatar = datas.avatar, avatarFrame = datas.avatarFrame})
								node.bgBtn:setNormalImage(_res('ui/home/friend/friends_list_frame_off_line.png'))
								node.bgBtn:setSelectedImage(_res('ui/home/friend/friends_list_frame_off_line.png'))
								node.signLabel:setString(self:GetOfflineTime(datas.lastExitTime))
							end
							if checkint(datas.topTime) ~= 0 then
								node.setTopIcon:setVisible(true)
								node.bgBtn:setNormalImage(_res('ui/home/friend/friends_bg_list_top.png'))
								node.bgBtn:setSelectedImage(_res('ui/home/friend/friends_bg_list_top.png'))
							else
								node.setTopIcon:setVisible(false)
							end
							if self:HasNewMessageWithPlayerId(datas.friendId) then
								node.remindIcon:setVisible(true)
							else
								node.remindIcon:setVisible(false)
							end
							if self:HasNewMessageWithPlayerId(datas.friendId) then
								node.remindIcon:setVisible(true)
							else
								node.remindIcon:setVisible(false)
							end
							expandableNode:insertItemNodeAtLast(node)
							expandableListView:reloadData()
						end)
					)
				)
			end
		elseif v.tag == MyFriendsType.BLACKLIST then -- 黑名单
			for i,v in ipairs(self.blacklist) do
				expandableListView:runAction(
					cc.Sequence:create(
						cc.DelayTime:create(i*0.1),
						cc.CallFunc:create(function ()
							local node = friendCell.new(cc.size(460, 106))
							node.remindIcon:setVisible(false)
							node.bgBtn:setUserTag(1)
							node.bgBtn:setTag(i)
							node.eventnode:setPositionY(node.eventnode:getPositionY()+ 5)
							node.avatarIcon:setTag(i)
							node.avatarIcon:setOnClickScriptHandler(function ( sender )
								local tag = sender:getTag()
								uiMgr:AddDialog('common.PlayerHeadPopup', {playerId = self.blacklist[tag].playerId, type = HeadPopupType.BLACKLIST})
							end)
							local datas = v
							node.nameLabel:setString(datas.name)
							node.nameLabel:setColor(ccc3FromInt('#5c5c5c'))
							node.signLabel:setColor(ccc3FromInt('#707070'))
							node.avatarIcon:RefreshSelf({level = datas.level, isGray = true, avatar = datas.avatar, avatarFrame = datas.avatarFrame})
							node.bgBtn:setNormalImage(_res('ui/home/friend/friends_list_frame_off_line.png'))
							node.bgBtn:setSelectedImage(_res('ui/home/friend/friends_list_frame_off_line.png'))
							node.signLabel:setVisible(false)
							expandableNode:insertItemNodeAtLast(node)
						end)
					)
				)
			end
		end
	end
	expandableListView:reloadData()
end
--[[
是否显示复选框
--]]
function FriendListMediator:setShowDelCheckbox(isShow)
	self.showdelCheckbox = isShow
end
function FriendListMediator:getShowDelCheckbox()
	return self.showdelCheckbox
end

--[[
更新expandableNode
@params myFriendsType int 列表类型
--]]
function FriendListMediator:UpdateExpandableNode( myFriendsType )
	if self.showListLayer[tostring(FriendListViewType.MY_FRIENDS)] then
		local expandableListView = self.showListLayer[tostring(FriendListViewType.MY_FRIENDS)]:getChildByName('expandableListView')
		if myFriendsType == MyFriendsType.FRIEND then -- 好友
			local expandableNode = expandableListView:getExpandableNodeAtIndex(0)
			expandableNode:removeAllItemNodes()
			for i,v in ipairs(self.friendDatas.friendList) do
				local node = friendCell.new(cc.size(460, 106))
				node.bgBtn:setUserTag(1)
				node.bgBtn:setTag(i)
				node.eventnode:setPositionY(node.eventnode:getPositionY()+ 5)
				node.bgBtn:setOnClickScriptHandler(handler(self, self.FriendListCellCallback))
				node.avatarIcon:setTag(i)
				node.avatarIcon:setOnClickScriptHandler(function ( sender )
					local tag = sender:getTag()
					uiMgr:AddDialog('common.PlayerHeadPopup', {playerId = self.friendDatas.friendList[tag].friendId, type = HeadPopupType.FRIEND})
				end)
				node.checkbox:setTag(i)
				node.checkbox:setOnClickScriptHandler(function ( sender )  
					self:CheckboxClickAction(sender)
				end)
				node.checkbox:setVisible(checkbool(self:getShowDelCheckbox()))
				local datas = v
				-- 判断是否存在备注
				local nameColor = '#843f11'
				if datas.noteName and datas.noteName ~= '' then
					node.nameLabel:setString(datas.noteName)
					nameColor = '#cb5600'
				else
					node.nameLabel:setString(datas.name)
				end
				if checkint(datas.isOnline) == 1 then
					node.nameLabel:setColor(ccc3FromInt(nameColor))
					node.signLabel:setColor(ccc3FromInt('#aa8b8b'))
					node.avatarIcon:RefreshSelf({level = datas.level, isGray = false, avatar = datas.avatar, avatarFrame = datas.avatarFrame})
					node.bgBtn:setNormalImage(_res('ui/home/friend/friends_list_frame_default.png'))
					node.bgBtn:setSelectedImage(_res('ui/home/friend/friends_list_frame_default.png'))
					display.fixLabelText(node.signLabel, {text = datas.sign, maxW = 320})
				elseif checkint(datas.isOnline) == 0 then
					node.nameLabel:setColor(ccc3FromInt('#5c5c5c'))
					node.signLabel:setColor(ccc3FromInt('#707070'))
					node.avatarIcon:RefreshSelf({level = datas.level, isGray = true, avatar = datas.avatar, avatarFrame = datas.avatarFrame})
					node.bgBtn:setNormalImage(_res('ui/home/friend/friends_list_frame_off_line.png'))
					node.bgBtn:setSelectedImage(_res('ui/home/friend/friends_list_frame_off_line.png'))
					node.signLabel:setString(self:GetOfflineTime(datas.lastExitTime))
				end
				if checkint(datas.topTime) ~= 0 then
					node.setTopIcon:setVisible(true)
					node.bgBtn:setNormalImage(_res('ui/home/friend/friends_bg_list_top.png'))
					node.bgBtn:setSelectedImage(_res('ui/home/friend/friends_bg_list_top.png'))
				else
					node.setTopIcon:setVisible(false)
				end
				-- 判断是否被选中
				if self.chattingType == FriendListViewType.MY_FRIENDS and self.chattingFriendIndex == i then
					node.selectedFrame:setVisible(true)
				else
					node.selectedFrame:setVisible(false)
				end
				
				node.checkbox:setVisible(checkbool(self:getShowDelCheckbox()))
		
				if self:HasNewMessageWithPlayerId(checkint(v.friendId)) then
					node.remindIcon:setVisible(true)
				else
					node.remindIcon:setVisible(false)
				end
				expandableNode:insertItemNodeAtLast(node)
			end
		elseif myFriendsType == MyFriendsType.BLACKLIST then -- 黑名单
			local expandableNode = expandableListView:getExpandableNodeAtIndex(1)
			expandableNode:removeAllItemNodes()
			for i,v in ipairs(self.blacklist) do
				local node = friendCell.new(cc.size(460, 106))
				node.remindIcon:setVisible(false)
				node.bgBtn:setUserTag(2)
				node.bgBtn:setTag(i)
				node.eventnode:setPositionY(node.eventnode:getPositionY()+ 5)
				-- node.bgBtn:setOnClickScriptHandler(handler(self, self.FriendListCellCallback))
				node.avatarIcon:setTag(i)
				node.avatarIcon:setOnClickScriptHandler(function ( sender )
					local tag = sender:getTag()
					uiMgr:AddDialog('common.PlayerHeadPopup', {playerId = self.blacklist[tag].playerId, type = HeadPopupType.BLACKLIST})
				end)
				local datas = v
				node.nameLabel:setString(datas.name)
				node.nameLabel:setColor(ccc3FromInt('#5c5c5c'))
				node.signLabel:setColor(ccc3FromInt('#707070'))
				node.avatarIcon:RefreshSelf({level = datas.level, isGray = true, avatar = datas.avatar, avatarFrame = datas.avatarFrame})
				node.bgBtn:setNormalImage(_res('ui/home/friend/friends_list_frame_off_line.png'))
				node.bgBtn:setSelectedImage(_res('ui/home/friend/friends_list_frame_off_line.png'))
				node.signLabel:setVisible(false)
				expandableNode:insertItemNodeAtLast(node)
			end
		end
		expandableListView:reloadData()
	end
end
--[[
最近联系人列表处理
--]]
function FriendListMediator:RecentContactsDataSourceAction( p_convertview, idx )
	local pCell = p_convertview
    local index = idx + 1
    local cSize = cc.size(460, 106)
    if pCell == nil then
        pCell = friendCell.new(cSize)
		pCell.bgBtn:setOnClickScriptHandler(handler(self, self.FriendListCellCallback))
		pCell.avatarIcon:setOnClickScriptHandler(function ( sender )
			local tag = sender:getTag()
			local isFriend = self:GetIsFriend(self.friendDatas.recentContactsList[tag].friendId)
			if isFriend then
				uiMgr:AddDialog('common.PlayerHeadPopup', {playerId = self.friendDatas.recentContactsList[tag].friendId, type = HeadPopupType.FRIEND})
			else
				uiMgr:AddDialog('common.PlayerHeadPopup', {playerId = self.friendDatas.recentContactsList[tag].friendId, type = HeadPopupType.STRANGER})
			end

		end)
    end
	xTry(function()
		local datas = self.friendDatas.recentContactsList[index]
		pCell.nameLabel:setString(datas.name)
		if checkint(datas.isOnline) == 1 then
			pCell.nameLabel:setColor(ccc3FromInt('#843f11'))
			pCell.signLabel:setColor(ccc3FromInt('#aa8b8b'))
			pCell.avatarIcon:RefreshSelf({level = datas.level, isGray = false, avatar = datas.avatar, avatarFrame = datas.avatarFrame})
			pCell.bgBtn:setNormalImage(_res('ui/home/friend/friends_list_frame_default.png'))
			pCell.bgBtn:setSelectedImage(_res('ui/home/friend/friends_list_frame_default.png'))
			display.fixLabelText(pCell.signLabel, {text = datas.sign, maxW = 320})
		elseif checkint(datas.isOnline) == 0 then
			pCell.nameLabel:setColor(ccc3FromInt('#5c5c5c'))
			pCell.signLabel:setColor(ccc3FromInt('#707070'))
			pCell.avatarIcon:RefreshSelf({level = datas.level, isGray = true, avatar = datas.avatar, avatarFrame = datas.avatarFrame})
			pCell.bgBtn:setNormalImage(_res('ui/home/friend/friends_list_frame_off_line.png'))
			pCell.bgBtn:setSelectedImage(_res('ui/home/friend/friends_list_frame_off_line.png'))
			pCell.signLabel:setString(self:GetOfflineTime(datas.lastExitTime))
		end
		-- 判断是否被选中
		if self.chattingType == FriendListViewType.RECENT_CONTACTS and checkint(self.chattingFriendIndex) == index then
			pCell.selectedFrame:setVisible(true)
			if checkint(datas.isOnline) == 1 then
				pCell.bgBtn:setNormalImage(_res('ui/home/friend/friends_list_frame_select.png'))
				pCell.bgBtn:setSelectedImage(_res('ui/home/friend/friends_list_frame_select.png'))
			end
		else
			pCell.selectedFrame:setVisible(false)
		end
		pCell.bgBtn:setTag(index)
		pCell.avatarIcon:setTag(index)
		-- 红点
		if self:HasNewMessageWithPlayerId(datas.friendId) then
			pCell.remindIcon:setVisible(true)
		else
			pCell.remindIcon:setVisible(false)
		end
	end,__G__TRACKBACK__)
    return pCell
end
--[[
我的好友页面页签按钮回调
--]]
function FriendListMediator:MyFriendsTabBtnCallback( sender )
	local tag = 0
	if type(sender) == 'number' then
		tag = sender
	else
		tag = sender:getTag()
		PlayAudioClip(AUDIOS.UI.ui_depot_tabchange.id)
	end

	local listLayer = self.showListLayer[tostring(FriendListViewType.MY_FRIENDS)]
	local expandableListView = listLayer:getChildByName('expandableListView')
	local expandableNode = expandableListView:getExpandableNodeAtIndex(tag-1)
	if expandableNode:isExpanded() then
		expandableNode:setExpanded(false)
		local arrow = expandableNode:getChildByName('arrow')
		arrow:setRotation(0)


	else
		expandableNode:setExpanded(true)
		local arrow = expandableNode:getChildByName('arrow')
		arrow:setRotation(90)
	end
	expandableListView:reloadData()
end
--[[
我的好友列表处理
--]]
function FriendListMediator:MyFriendsDataSourceAction( p_convertview, idx )
	local pCell = p_convertview
    local index = idx + 1
    local cSize = cc.size(460, 106)
    if pCell == nil then
        pCell = friendCell.new(cSize)
		pCell.bgBtn:setOnClickScriptHandler(handler(self, self.FriendListCellCallback))
		pCell.avatarIcon:setOnClickScriptHandler(function ( sender )
			local tag = sender:getTag()
			uiMgr:AddDialog('common.PlayerHeadPopup', {playerId = self.friendDatas.friendList[tag].friendId, type = HeadPopupType.FRIEND})
		end)
    end
	xTry(function()
		local datas = self.friendDatas.friendList[index]
		pCell.nameLabel:setString(datas.name)
		if checkint(datas.isOnline) == 1 then
			pCell.nameLabel:setColor(ccc3FromInt('#843f11'))
			pCell.signLabel:setColor(ccc3FromInt('#aa8b8b'))
			pCell.avatarIcon:RefreshSelf({level = datas.level, isGray = false, avatar = datas.avatar, avatarFrame = datas.avatarFrame})
			pCell.bgBtn:setNormalImage(_res('ui/home/friend/friends_list_frame_default.png'))
			pCell.bgBtn:setSelectedImage(_res('ui/home/friend/friends_list_frame_default.png'))
			display.fixLabelText(pCell.signLabel, {text = datas.sign, maxW = 320})
		elseif checkint(datas.isOnline) == 0 then
			pCell.nameLabel:setColor(ccc3FromInt('#5c5c5c'))
			pCell.signLabel:setColor(ccc3FromInt('#707070'))
			pCell.avatarIcon:RefreshSelf({level = datas.level, isGray = true, avatar = datas.avatar, avatarFrame = datas.avatarFrame})
			pCell.bgBtn:setNormalImage(_res('ui/home/friend/friends_list_frame_off_line.png'))
			pCell.bgBtn:setSelectedImage(_res('ui/home/friend/friends_list_frame_off_line.png'))
			pCell.signLabel:setString(self:GetOfflineTime(datas.lastExitTime))
		end
		if checkint(datas.topTime) ~= 0 then
			pCell.bgBtn:setNormalImage(_res('ui/home/friend/friends_bg_list_top.png'))
			pCell.bgBtn:setSelectedImage(_res('ui/home/friend/friends_bg_list_top.png'))
			pCell.setTopIcon:setVisible(true)
		else
			pCell.setTopIcon:setVisible(false)
		end
		
		-- 判断是否被选中
		if self.chattingType == FriendListViewType.MY_FRIENDS and checkint(self.chattingFriendIndex) == index then
			pCell.selectedFrame:setVisible(true)
			if checkint(datas.isOnline) == 1 then
				pCell.bgBtn:setNormalImage(_res('ui/home/friend/friends_list_frame_select.png'))
				pCell.bgBtn:setSelectedImage(_res('ui/home/friend/friends_list_frame_select.png'))
			end
			if checkint(datas.topTime) ~= 0 then
				pCell.bgBtn:setNormalImage(_res('ui/home/friend/friends_bg_list_top.png'))
				pCell.bgBtn:setSelectedImage(_res('ui/home/friend/friends_bg_list_top.png'))
			end
		else
			pCell.selectedFrame:setVisible(false)
		end
		pCell.avatarIcon:setTag(index)
		pCell.bgBtn:setTag(index)
	end,__G__TRACKBACK__)
    return pCell
end
--[[
推荐好友列表处理
--]]
function FriendListMediator:CommendDataSourceAction( p_convertview, idx )
	local pCell = p_convertview
    local index = idx + 1
    local cSize = cc.size(288, 106)
    if pCell == nil then
    	pCell = friendCommendCell.new(cSize)
		pCell.addBtn:setOnClickScriptHandler(handler(self, self.CellAddFreindButtonCallback))
		pCell.avatarIcon:setOnClickScriptHandler(function ( sender )
			local tag = sender:getTag()
			local playerId = nil
			if self.isFindFriend then
				playerId = self.findListDatas.playerId
			else
				playerId = self.friendDatas.recommendFriendList[tag].id
			end
			uiMgr:AddDialog('common.PlayerHeadPopup', {playerId = playerId, type = HeadPopupType.RECENT_CONTACTS})
		end)
    end
	xTry(function()
		local datas = {}
		if self.isFindFriend then
			datas = self.findListDatas
		else
			datas = self.friendDatas.recommendFriendList[index]
		end
		pCell.nameLabel:setString(isSearchOnlyUID and tostring(datas.id or datas.playerId) or tostring(datas.name))

		pCell.avatarIcon:RefreshSelf({level = datas.level, avatar = datas.avatar, avatarFrame = datas.avatarFrame})
		pCell.addBtn:setTag(index)
		pCell.avatarIcon:setTag(index)
		if checkint(datas.isAdd) == 1 then
			pCell.sendLabel:setVisible(true)
			pCell.addBtn:setVisible(false)
		else
			pCell.sendLabel:setVisible(false)
			pCell.addBtn:setVisible(true)
		end
	end,__G__TRACKBACK__)
    return pCell
end
--[[
添加好友列表处理
--]]
function FriendListMediator:AddFriendsDataSourceAction( p_convertview, idx )
	local pCell = p_convertview
    local index = idx + 1
    local cSize = cc.size(460, 106)
    if pCell == nil then
    	pCell = friendAddCell.new(cSize)
    	pCell.consentBtn:setOnClickScriptHandler(handler(self, self.FriendRequestAgreeButtonCallback))
    end
	xTry(function()
		local datas = self.friendDatas.friendRequest[index]
		pCell.nameLabel:setString(datas.name)
		pCell.avatarIcon:RefreshSelf({level = datas.level, avatar = datas.avatar, avatarFrame = datas.avatarFrame})
		pCell.consentBtn:setTag(index)
	end,__G__TRACKBACK__)
    return pCell
end
--[[
推荐列表添加好友按钮点击回调
--]]
function FriendListMediator:CellAddFreindButtonCallback( sender )
	PlayAudioByClickNormal()
	local index = sender:getTag()
	local friendId = nil
	if self.isFindFriend then
		friendId = self.findListDatas.playerId
	else
		friendId = self.friendDatas.recommendFriendList[index].id
	end
	self:SendSignal(COMMANDS.COMMAND_Friend_AddFriend, {friendId = friendId})
end
--[[
好友请求同意按钮点击回调
--]]
function FriendListMediator:FriendRequestAgreeButtonCallback( sender )
	PlayAudioByClickNormal()
	local tag = sender:getTag()
	if CommonUtils.IsInBlacklist(checkint(self.friendDatas.friendRequest[tag].friendId)) then
        local scene = uiMgr:GetCurrentScene()
        local CommonTip  = require( 'common.NewCommonTip' ).new({text = __('对方在您的黑名单中，是否要添加为好友？'),
                isOnlyOK = false, callback = function ()
  					self:DeleteBlacklistAction(self.friendDatas.friendRequest[tag].friendId)
					self:SendSignal(COMMANDS.COMMAND_Friend_HandleAddFriend, {friendId = checkint(self.friendDatas.friendRequest[tag].friendId), agree = 1})
                end})
        CommonTip:setPosition(display.center)
        scene:AddDialog(CommonTip)
    else
    	self:SendSignal(COMMANDS.COMMAND_Friend_HandleAddFriend, {friendId = checkint(self.friendDatas.friendRequest[tag].friendId), agree = 1})
	end
end
--[[
好友点击回调
--]]
function FriendListMediator:FriendListCellCallback( sender )
	PlayAudioByClickNormal()
	local tag = sender:getTag()
	local userTag = sender:getUserTag() -- 好友列表类型
	if self.chattingType == self.selectedListType then
		if self.chattingType == FriendListViewType.RECENT_CONTACTS then
			if self.chattingFriendIndex == tag then
				return
			end
		elseif self.chattingType == FriendListViewType.MY_FRIENDS then
			if self.selectedMyFriendsType == userTag and self.chattingFriendIndex == tag then
				return
			end
		end
	end
	PlayAudioByClickNormal()
	-- -- 清空列表
	local chatListView = self:GetViewComponent().viewData_.chatListView
	chatListView:removeAllNodes()
	chatListView:reloadData()
	if self.chattingType then
		local datas = nil
		local cell = nil
		if self.chattingType == FriendListViewType.RECENT_CONTACTS then
			datas = self.friendDatas.recentContactsList[checkint(self.chattingFriendIndex)]
			local gridView = self.showListLayer[tostring(FriendListViewType.RECENT_CONTACTS)]:getChildByName('gridView')
			cell = gridView:cellAtIndex(checkint(self.chattingFriendIndex)-1)
		elseif self.chattingType == FriendListViewType.MY_FRIENDS then
			datas = self.friendDatas.friendList[checkint(self.chattingFriendIndex)]
			local gridView = self.showListLayer[tostring(FriendListViewType.MY_FRIENDS)]:getChildByName('expandableListView')
			local expandableNode = gridView:getExpandableNodeAtIndex(self.selectedMyFriendsType-1)
			cell = expandableNode:getItemNodeAtIndex(checkint(self.chattingFriendIndex)-1)
		end
		if cell then
			cell.selectedFrame:setVisible(false)
			if checkint(datas.isOnline) == 1 then
				cell.bgBtn:setNormalImage(_res('ui/home/friend/friends_list_frame_default.png'))
				cell.bgBtn:setSelectedImage(_res('ui/home/friend/friends_list_frame_default.png'))
			end
			if self.selectedListType == FriendListViewType.MY_FRIENDS then
				if checkint(datas.topTime) ~= 0 then
					cell.bgBtn:setNormalImage(_res('ui/home/friend/friends_bg_list_top.png'))
					cell.bgBtn:setSelectedImage(_res('ui/home/friend/friends_bg_list_top.png'))
				end
			end
		end
	end
	-- -- 添加选中框
	local datas = nil
	local cell = nil
	if self.selectedListType == FriendListViewType.RECENT_CONTACTS then
		datas = self.friendDatas.recentContactsList[tag]
		local gridView = self.showListLayer[tostring(FriendListViewType.RECENT_CONTACTS)]:getChildByName('gridView')
		cell = gridView:cellAtIndex(tag-1)
	elseif self.selectedListType == FriendListViewType.MY_FRIENDS then
		if userTag == MyFriendsType.FRIEND then
			datas = self.friendDatas.friendList[checkint(tag)]
		elseif userTag == MyFriendsType.BLACKLIST then
		end

		local gridView = self.showListLayer[tostring(FriendListViewType.MY_FRIENDS)]:getChildByName('expandableListView')
		local expandableNode = gridView:getExpandableNodeAtIndex(userTag-1)
		cell = expandableNode:getItemNodeAtIndex(checkint(tag)-1)
	end
	if cell then
		cell.selectedFrame:setVisible(true)
		cell.remindIcon:setVisible(false)
		if checkint(datas.isOnline) == 1 then
			cell.bgBtn:setNormalImage(_res('ui/home/friend/friends_list_frame_select.png'))
			cell.bgBtn:setSelectedImage(_res('ui/home/friend/friends_list_frame_select.png'))
		end
		if self.selectedListType == FriendListViewType.MY_FRIENDS then
			if checkint(datas.topTime) ~= 0 then
				cell.bgBtn:setNormalImage(_res('ui/home/friend/friends_bg_list_top.png'))
				cell.bgBtn:setSelectedImage(_res('ui/home/friend/friends_bg_list_top.png'))
			end
		end
	end
	-- 更新本地数据
	self.chattingFriendIndex = tag
	self.selectedMyFriendsType = userTag
	self.chattingType = self.selectedListType
	self:RefreshChatView()
	self:AddChattingHistory()
	-- 处理红点相关
	self:ReadMessageWithPlayerId(datas.friendId)
	if self.selectedListType == FriendListViewType.RECENT_CONTACTS then
		local layer = self.showListLayer[tostring(FriendListViewType.MY_FRIENDS)]
		if layer then
			self:UpdateExpandableNode(MyFriendsType.FRIEND)
		end
	elseif self.selectedListType == FriendListViewType.MY_FRIENDS then
		local layer = self.showListLayer[tostring(FriendListViewType.RECENT_CONTACTS)]
		if layer then
			self:UpdateRecentContactsList()
		end
	end
	self:RefreshListTabStatus()
end
--[[
根据好友类型获取序号
--]]
function FriendListMediator:GetMyFriendsTypeIndex( MyFriendsType )
	for i,v in ipairs(MyFriendsDatas) do
		if checkint(v.tag) == checkint(MyFriendsType) then
			return i
		end
	end
end
--[[
添加好友按钮回调
--]]
function FriendListMediator:AddFriendButtonCallback( sender )
	PlayAudioByClickNormal()
	self:SendSignal(COMMANDS.COMMAND_Friend_AddFriend, {friendId = self.otherPlayerId})
end
--[[
推广员按钮回调
--]]
function FriendListMediator:GeneralizeButtonCallback( sender )
	PlayAudioByClickNormal()
	local PromotersMediator = require( 'Game.mediator.PromotersMediator' )
	local mediator = PromotersMediator.new()
	AppFacade.GetInstance():RegistMediator(mediator)
end

--[[
表情按钮回调
--]]
function FriendListMediator:ExpressionButtonCallback( sender )
	PlayAudioByClickNormal()
	uiMgr:ShowInformationTips(__('暂未开放'))
end
--[[
发送按钮回调
--]]
function FriendListMediator:SendButtonCallback( sender )
	PlayAudioByClickNormal()
	local viewData = self:GetViewComponent().viewData_
	local sendBox = viewData.sendBox
	if sendBox:getText() == '' then
		uiMgr:ShowInformationTips(__('信息不能为空'))
	else
		if not CommonUtils.CheckIsDisableInputDay() then
			local datas = self:GetFriendDatas()
			self.sendMessData = {}
			local chatDatas = {}
			chatDatas.name = datas.name
			chatDatas.message = '<desc>'..sendBox:getText()..'</desc><messagetype>1</messagetype><fileid>nil</fileid>'
			chatDatas.fileID = nil
			chatDatas.sendTime = getServerTime()
			chatDatas.sender = 0
			chatDatas.messagetype = CHAT_MSG_TYPE.TEXT
			chatDatas.friendId = datas.friendId
			self.sendMessData = chatDatas	
			chatMgr:SendPacket( NetCmd.RequestPrivateSendMessage, {friendId = datas.friendId, message = chatDatas.message})
			sendBox:setText('')
		end
	end	
end
--[[
清空请求按钮回调
--]]
function FriendListMediator:EmptyButtonCallback( sender )
	PlayAudioByClickNormal()
	self:SendSignal(COMMANDS.COMMAND_Friend_EmptyRequest)
end
--[[
搜索按钮回调
--]]
function FriendListMediator:SearchButtonCallback( sender )
	PlayAudioByClickNormal()
	local viewData = self.viewComponent.viewData_
	local searchBox = viewData.searchBox
	local str = searchBox:getText()
	if str == '' then
		uiMgr:ShowInformationTips(__('用户名不能为空'))
	else
		self:SendSignal(COMMANDS.COMMAND_Friend_FindFriend, {friend = str})
	end
end
--[[
搜索栏删除按钮回调
--]]
function FriendListMediator:DeleteButtonCallback( sender )
	PlayAudioByClickNormal()
	self.isFindFriend = false
	local viewData = self:GetViewComponent().viewData_
	viewData.commendGridView:setCountOfCell(#checktable(self.friendDatas.recommendFriendList))
	viewData.commendGridView:reloadData()
	viewData.searchBox:setText('')
end
--[[
推荐好友更换按钮回调
--]]
function FriendListMediator:CommendChangeButtonCallback( sender )
	PlayAudioByClickNormal()
	self:SendSignal(COMMANDS.COMMAND_Friend_RefreshRecmmend)
end
--[[
复选框点击事件
--]]
function FriendListMediator:CheckboxClickAction( sender )
	local index = checkint(sender:getTag())
	local friendData = self.friendDatas.friendList
	local friendId = friendData[index].friendId
	if not sender:isChecked() then 
		sender:setChecked(false)
		table.removebyvalue(self.removeFriendsList, friendId)
		return 
	end
	sender:setChecked(true)
	table.insert(self.removeFriendsList, friendId)
end
--[[
批量删除按钮点击事件
--]]
function FriendListMediator:DeleteMultiFriendsButtonCallback( sender )
	self.removeFriendsList = {}
	self:UpdateDelMultiViewIsShow(true)
end
--[[
批量删除确定按钮点击事件
--]]
function FriendListMediator:DeleteMultiFriendsConfirmButtonCallback( sender )
	local function convertFriendsDataToStr(friendsData)
		local friendsIdString = ''
		local len = #friendsData
		for i = 1, len do
			friendsIdString = friendsIdString .. (friendsData[i] or '')
			if i ~= len then
				friendsIdString = friendsIdString .. ','
			end
		end
		return friendsIdString
	end
	if next(self.removeFriendsList) == nil then
    	uiMgr:ShowInformationTips(__('您未选中要删除的好友'))
		return 
	end
	local friendsIdList = convertFriendsDataToStr(self.removeFriendsList)
	local commonTip = require('common.NewCommonTip').new({text =__('是否删除选中好友？'), callback = function ()
		AppFacade.GetInstance():DispatchSignal(COMMANDS.COMMAND_Friend_DelFriend, {friendId = friendsIdList})
	end})
	commonTip:setPosition(display.center)
	uiMgr:GetCurrentScene():AddDialog(commonTip)
end

--[[
批量删除取消按钮点击事件
--]]
function FriendListMediator:DeleteMultiFriendsCancelButtonCallback( sender )
	self:UpdateDelMultiViewIsShow(false)
end

--[[
更新 我的好友 批量删除界面显示
--]]
function FriendListMediator:UpdateDelMultiViewIsShow( isShow )
	self:setShowDelCheckbox(isShow)
	local viewData = self:GetViewComponent().viewData_
	viewData.myFriendLayout:setVisible(isShow)
	self:RefreshLeftView()
end

--[[
刷新右侧页面
--]]
function FriendListMediator:RefreshRightView( listType )
	local viewData = self:GetViewComponent().viewData_
	if listType == FriendListViewType.RECENT_CONTACTS then
		viewData.addFriendsLayout:setVisible(false)
		viewData.emptyBtn:setVisible(false)
		viewData.myFriendLayout:setVisible(false)
		viewData.removeMultiFriendsBtn:setVisible(false)
		if self.chattingType == nil or self.chattingFriendIndex == nil then
			viewData.chatLayout:setVisible(false)
			viewData.rightEmptyView:setVisible(true)
		else
			viewData.chatLayout:setVisible(true)
			viewData.rightEmptyView:setVisible(false)
		end
		--隐藏批量删除界面
		self:setShowDelCheckbox(false)
		self:RefreshLeftView()
	elseif listType == FriendListViewType.MY_FRIENDS then
		viewData.addFriendsLayout:setVisible(false)
		viewData.emptyBtn:setVisible(false)
		if self.chattingType == nil or self.chattingFriendIndex == nil then
			viewData.chatLayout:setVisible(false)
			viewData.rightEmptyView:setVisible(true)
		else
			viewData.chatLayout:setVisible(true)
			viewData.rightEmptyView:setVisible(false)
		end
		viewData.removeMultiFriendsBtn:setVisible(true)
	
	elseif listType == FriendListViewType.ADD_FRIENDS then
		viewData.addFriendsLayout:setVisible(true)
		viewData.chatLayout:setVisible(false)
		viewData.rightEmptyView:setVisible(false)
		viewData.emptyBtn:setVisible(true)
		viewData.myFriendLayout:setVisible(false)
		viewData.removeMultiFriendsBtn:setVisible(false)
		--隐藏批量删除界面
		self:setShowDelCheckbox(false)
		self:RefreshLeftView()
	end
end
--[[
刷新列表页签状态(小红点)
--]]
function FriendListMediator:RefreshListTabStatus()
	local viewData = self:GetViewComponent().viewData_
	-- 最近联系人
	local hasNewMsg_Recent = false
	for i,v in ipairs(checktable(self.friendDatas.recentContactsList)) do
		if self:HasNewMessageWithPlayerId(v.friendId) then
			hasNewMsg_Recent = true
			break
		end
	end
	if hasNewMsg_Recent then
		viewData.tabButtons[1]:getChildByName('remindIcon'):setVisible(true)
	else
		viewData.tabButtons[1]:getChildByName('remindIcon'):setVisible(false)
	end
	-- 我的好友
	local hasNewMsg_Friends = false
	for i,v in ipairs(checktable(self.friendDatas.friendList)) do
		if self:HasNewMessageWithPlayerId(v.friendId) then
			hasNewMsg_Friends = true
			break
		end
	end
	if hasNewMsg_Friends then
		viewData.tabButtons[2]:getChildByName('remindIcon'):setVisible(true)
	else
		viewData.tabButtons[2]:getChildByName('remindIcon'):setVisible(false)
	end
	-- 添加好友
	if self.friendDatas.friendRequest and next(self.friendDatas.friendRequest) ~= nil then
		viewData.tabButtons[3]:getChildByName('remindIcon'):setVisible(true)
	else
		viewData.tabButtons[3]:getChildByName('remindIcon'):setVisible(false)
	end
end
--[[
添加聊天记录
--]]
function FriendListMediator:AddChattingHistory()
	-- 更新聊天列表
	local tempTab = {}
	local chatMessages = checktable(ChatUtils.GetChatMessages(gameMgr:GetUserInfo().playerId, self.otherPlayerId))
    local startNum = 1
    if #chatMessages - MAX_HISTORY_NUM > 0 then
        startNum = #chatMessages - MAX_HISTORY_NUM + 1
    end
	for i = startNum, #chatMessages, 1 do
		local v = chatMessages[i]
		local chatDatas = {}
        local parsedtable = labelparser.parse(v.content)
        local temp = {}
        --过滤非法标签
        for _,val in ipairs(parsedtable) do
            if FILTERS[val.labelname] then
                temp[val.labelname] = val.content
            end
        end
        chatDatas.name = v.sendPlayerName
        chatDatas.message = v.content
        chatDatas.fileid = temp['fileid']
        chatDatas.sendTime = v.sendTime
        chatDatas.sender = MSG_TYPES.MSG_TYPE_SELF
        chatDatas.messagetype = temp['messagetype']

        if checkint(v.sendPlayerId) ~= gameMgr:GetUserInfo().playerId then
            chatDatas.sender = MSG_TYPES.MSG_TYPE_OTHER
        end
		table.insert(tempTab,chatDatas)
	end
	for i,v in ipairs(tempTab) do
		self:UpdateChatList(v)
	end
end
--[[
更新聊天列表
--]]
function FriendListMediator:UpdateChatList( chatDatas )
    -- local chatListView = self:GetViewComponent().viewData_.chatListView
  	-- local contentOffset  = chatListView:getContentOffset()
 --  	local layout = nil
 --  	local headImg = nil
 --  	local arrow = nil

	-- local timeLabel = nil
 --  	local messageLabel = nil
 --  	local nameLabel = nil
	-- local messageBg = nil
	-- local bgVoice = nil
	-- local icoVoice = nil
	-- local bgImg = nil
	-- local tempTab = {}
	-- local ios_x = 0
	-- local ios_y = 0
	-- if device.platform == 'ios' then
	-- 	ios_x = 20
	-- 	ios_y = 20
	-- end
 --    if chatDatas then
	-- 	if tonumber(chatDatas.sender) == SenderType.mySelf then -- 发送人为自己
	-- 		messageLabel = self:CreateListCell(chatDatas)--chatDatas.sender,2,chatDatas
	-- 		local messageSize = display.getLabelContentSize(messageLabel)
	-- 		messageSize.width = messageSize.width*2
	-- 		messageSize.height = messageSize.height*2

	-- 		local cellSize = cc.size(chatListView:getContentSize().width - 2, 55 + messageSize.height/2 + 30)
	-- 		layout = CLayout:create(cellSize)
	-- 		local offsetY = 0
	-- 		if chatDatas.sendTime - 22 >= 300 then -- 需要显示时间
	-- 			cellSize = cc.size(chatListView:getContentSize().width - 2, 55 + messageSize.height/2 + 60)
	-- 			layout:setContentSize(cellSize)
	-- 			timeLabel = display.newLabel(cellSize.width * 0.5, cellSize.height - 12, {ap = cc.p(0.5, 1), text = self:GetTimeStamp(chatDatas.sendTime + getLoginClientTime() - getLoginServerTime()), fontSize = 22, color = '#5b3c25'})
	-- 			layout:addChild(timeLabel)
	-- 			offsetY = -30
	-- 		end
	-- 		display.commonUIParams(layout,{po = cc.p(cellSize.width * 0.5, cellSize.height * 0.5)})
	-- 		headImg = require('common.FriendHeadNode').new({enable = false, scale = 0.6, showLevel = false, avatar = gameMgr:GetUserInfo().avatar, avatarFrame = gameMgr:GetUserInfo().avatarFrame})
 --            headImg:setAnchorPoint(cc.p(0.5,0.5))
 --            headImg:setPosition(cc.p(cellSize.width - 60, cellSize.height - 56 + offsetY))
 --            layout:addChild(headImg)
	-- 		headImg:setTag(table.nums(chatListView:getNodes())+1)
	-- 		-- headImg1 = headImg
	-- 		messageBg = display.newImageView(_res('ui/home/friend/friend_liaotianqipao_ziji.png'), cellSize.width - 115, cellSize.height - 35 + offsetY,
	-- 		{ap = cc.p(1, 1), scale9 = true, size = cc.size(messageSize.width/2+30, messageSize.height/2+30), capInsets = cc.rect(10, 10, 201, 28)})
	-- 		layout:addChild(messageBg)
	-- 		messageLabel:setPosition(cc.p(cellSize.width - 131, cellSize.height - 48 + offsetY))
	-- 		layout:addChild(messageLabel, 5)
	-- 		messageBg:setTouchEnabled(false)
	-- 		arrow = display.newImageView(_res('ui/home/friend/friend_liaotianqipao_haoyou_sanjiao_ziji.png'), cellSize.width - 106, cellSize.height - 50+ offsetY, {ap = cc.p(0, 1)})
	-- 		arrow:setScaleX(-1)
	-- 		layout:addChild(arrow)
	-- 		arrow1 = arrow
	-- 		local ios_x = 0
	-- 		local ios_y = 0
	-- 		if device.platform == 'ios' then
	-- 			ios_x = 20
	-- 			ios_y = 20
	-- 		end
	-- 		--显示语音消息相关ui
	-- 		if tonumber(chatDatas.messagetype) == CHAT_MSG_TYPE.SOUND then
	-- 			messageLabel:setVisible(false)
	-- 			messageBg:setContentSize(cc.size(250,50))
	-- 			bgVoice = display.newImageView(_res('ui/home/chatSystem/dialogue_bg_voice.png'),cellSize.width - 180 + ios_x, cellSize.height /2 + 5 + ios_y, {scale9 = true, size = cc.size(messageSize.width/2, 23),ap = cc.p(1, 1)})
	-- 			layout:addChild(bgVoice)
	-- 			-- bgVoice:setTag(table.nums(self.chatListView:getNodes())+1)

	-- 			icoVoice = display.newImageView(_res('ui/home/chatSystem/dialogue_ico_voice.png'), cellSize.width - 160 + ios_x, cellSize.height /2 - 8 + ios_y, {ap = cc.p(0.5, 0.5)})
	-- 			icoVoice:setScale(-1)
	-- 			layout:addChild(icoVoice,1)

	-- 			messageBg:setTag(table.nums(chatListView:getNodes())+1)
	-- 			messageBg:setTouchEnabled(true)
 --            	messageBg:setOnClickScriptHandler(function( sender )
 --                	if voiceEngine then
 --                	    local succ = voiceEngine:ApplyMessageKey() --开始key然后录音的逻辑
 --                	    -- print('----------->>>',succ)
 --                	    if succ == 0 then
 --                	        voiceEngine:StartUpdate()
 --                	        ---如果key应用成功的时候，然后开始才开始播放音频的逻辑
 --                	        local downloadFile = AUDIO_ABSOLUTE_PATH .. tostring(chatDatas.fileid)
 --                	        if not utils.isExistent(downloadFile) then
 --                	            voiceEngine:DownloadRecordedFile(chatDatas.fileid,downloadFile)
 --                	        else
 --                	            --如果已经下载完成的文件直接播放
 --                	            app.audioMgr:PauseBGMusic()
 --                	            voiceEngine:PlayRecordedFile(downloadFile)
 --                	        end
 --                	    end
 --                	end
 --            	end)
	-- 		end
	-- 	elseif tonumber(chatDatas.sender) == SenderType.otherPeople then -- 发送人为好友
	-- 		messageLabel = self:CreateListCell(chatDatas)--chatDatas.sender,3,chatDatas
	-- 		-- messageLabel:setOnTextRichClickScriptHandler(handler(self,self.messageLabelCallBack))

	-- 		local messageSize = display.getLabelContentSize(messageLabel)
	-- 		-- dump(messageSize)
	-- 		if messageSize.height then

	-- 		end
	-- 		messageSize.width = messageSize.width*2
	-- 		messageSize.height = messageSize.height*2

	-- 		local cellSize = cc.size(chatListView:getContentSize().width - 2, 55 + messageSize.height/2 + 30)
	-- 		layout = CLayout:create(cellSize)
	-- 		local offsetY = 0
	-- 		if chatDatas.sendTime - 22 >= 300 then -- 需要显示时间
	-- 			cellSize = cc.size(chatListView:getContentSize().width - 2, 55 + messageSize.height/2 + 60)
	-- 			layout:setContentSize(cellSize)
	-- 			timeLabel = display.newLabel(cellSize.width * 0.5, cellSize.height - 12, {ap = cc.p(0.5, 1), text = self:GetTimeStamp(chatDatas.sendTime + getLoginClientTime() - getLoginServerTime()), fontSize = 22, color = '#5b3c25'})
	-- 			layout:addChild(timeLabel)
	-- 			offsetY = -30
	-- 		end
	-- 		-- layout:setBackgroundColor(cc.c4b(0,100,0,100))
	-- 		display.commonUIParams(layout,{po = cc.p(cellSize.width * 0.5, cellSize.height * 0.5)})
	-- 		-- 获取头像
	-- 		headImg = require('common.FriendHeadNode').new({enable = false, scale = 0.6, showLevel = false, avatar = self.otherPlayerAvatar, avatarFrame = self.otherPlayerAvatarFrame})
 --            headImg:setAnchorPoint(cc.p(0.5,0.5))
 --            headImg:setPosition(cc.p(60, cellSize.height - 56+ offsetY))
	-- 		layout:addChild(headImg)
	-- 		headImg:setTag(table.nums(chatListView:getNodes())+1)

	-- 		messageBg = display.newImageView(_res('ui/home/friend/friend_liaotianqipao_haoyou.png'), 115, cellSize.height - 35 + offsetY,
	-- 		{ap = cc.p(0, 1), scale9 = true, size = cc.size(messageSize.width/2+30, messageSize.height/2+30), capInsets = cc.rect(10, 10, 201, 28)})
	-- 		layout:addChild(messageBg)
	-- 		messageLabel:setPosition(cc.p(131, cellSize.height - 48 + offsetY))
	-- 		layout:addChild(messageLabel, 50)
	-- 		messageBg:setTouchEnabled(false)
	-- 		arrow = display.newImageView(_res('ui/home/friend/friend_liaotianqipao_haoyou_sanjiao.png'), 119, cellSize.height - 50+ offsetY, {ap = cc.p(1, 1)})
	-- 		layout:addChild(arrow)
	-- 		--显示语音消息相关ui
	-- 		if tonumber(chatDatas.messagetype) == CHAT_MSG_TYPE.SOUND then
	-- 			messageLabel:setVisible(false)
	-- 			messageBg:setContentSize(cc.size(250,50))
	-- 			bgVoice = display.newImageView(_res('ui/home/chatSystem/dialogue_bg_voice.png'),170 - ios_x, cellSize.height /2+5 + ios_y, {scale9 = true, size = cc.size(messageSize.width/2, 25),ap = cc.p(0, 1)})
	-- 			layout:addChild(bgVoice)

	-- 			icoVoice = display.newImageView(_res('ui/home/chatSystem/dialogue_ico_voice.png'), 145 - ios_x, cellSize.height /2 - 8 + ios_y, {ap = cc.p(0.5, 0.5)})
	-- 			layout:addChild(icoVoice,1)

	-- 			messageBg:setTag(table.nums(chatListView:getNodes())+1)
	-- 			messageBg:setTouchEnabled(true)
	-- 		    messageBg:setOnClickScriptHandler(function( sender )
 --                	if voiceEngine then
 --                	    local succ = voiceEngine:ApplyMessageKey() --开始key然后录音的逻辑
 --                	    -- print('----------->>>',succ)
 --                	    if succ == 0 then
 --                	        voiceEngine:StartUpdate()
 --                	        ---如果key应用成功的时候，然后开始才开始播放音频的逻辑
 --                	        local downloadFile = AUDIO_ABSOLUTE_PATH .. tostring(chatDatas.fileid)
 --                	        if not utils.isExistent(downloadFile) then
 --                	            voiceEngine:DownloadRecordedFile(chatDatas.fileid,downloadFile)
 --                	        else
 --                	            --如果已经下载完成的文件直接播放
 --                	            app.audioMgr:PauseBGMusic()
 --                	            voiceEngine:PlayRecordedFile(downloadFile)
 --                	        end
 --                	    end
 --                	end
	-- 		    end)
	-- 		end
	-- 		-- layout1 = layout
	-- 		-- chatListView:insertNodeAtFront(layout)
	-- 	end
	-- 	tempTab = {
	-- 	    layout = layout,
	-- 	    headImg = headImg,
	-- 	    arrow = arrow,

	-- 	  	timeLabel = timeLabel,
	-- 	    messageLabel = messageLabel,
	-- 	    nameLabel = nameLabel,
	-- 		messageBg = messageBg,
	-- 		bgVoice = bgVoice,
	-- 		icoVoice = icoVoice,
	-- 		bgImg = bgImg,
	-- 	}

		-- chatListView:insertNodeAtLast(layout)
		-- chatListView:reloadData()
		-- chatListView:setContentOffsetToBottom()
		if tonumber(chatDatas.sender) == SenderType.mySelf then -- 发送人为自己
			chatDatas.avatar = gameMgr:GetUserInfo().avatar
			chatDatas.avatarFrame = gameMgr:GetUserInfo().avatarFrame
			chatDatas.playerId = gameMgr:GetUserInfo().playerId
			chatDatas.name = gameMgr:GetUserInfo().playerName
		elseif tonumber(chatDatas.sender) == SenderType.otherPeople then -- 发送人为好友
			chatDatas.avatar = self.otherPlayerAvatar
			chatDatas.avatarFrame = self.otherPlayerAvatarFrame
			chatDatas.playerId = self.otherPlayerId
		end
		self:InsertPrivateMessageItem(chatDatas)
	-- end
end
--[[
添加私聊信息cell
@params chatDatas
--]]
function FriendListMediator:InsertPrivateMessageItem(chatDatas)
    local chatListView = self:GetViewComponent().viewData_.chatListView
    local index = chatListView:getNodeCount()
    local view = require( 'Game.views.FriendMessageItemView' ).new({chatDatas = chatDatas, index = (index + 1)})
    chatListView:insertNodeAtLast(view)
    chatListView:reloadData()
    chatListView:setContentOffsetToBottom()
end
--[[
创建列表cell
--]]
function FriendListMediator:CreateListCell(chatDatas)
	local isSelf = chatDatas.sender
	local messageType = chatDatas.messagetype or CHAT_MSG_TYPE.TEXT
	local messageLabel = nil
	local anchorPoint = cc.p(1,1)
	if isSelf == 1 then
		anchorPoint = cc.p(0,1)
	else
		anchorPoint = cc.p(1,1)
	end
	local chatListView = self:GetViewComponent().viewData_.chatListView
	if messageType ~= 2 then
		local parsedtable = labelparser.parse(chatDatas.message)
		local tempTab = {}
		--过滤非法标签
		for i,v in ipairs(parsedtable) do
			if messType[v.labelname] then
				table.insert(tempTab,v)
			end
		end
		local t = {}
		for i,v in ipairs(tempTab) do
			if v.labelname ~= 'fileid' and v.labelname ~= 'messagetype' then
				local x = {text = v.content , fontSize = 22, color = '#ffffff',descr = v.labelname}
				table.insert(t,x)
			end
		end
		if table.nums(t) <= 0 then
			table.insert(t,{text = '                                 ', fontSize = 22, color = '#ffffff'})
		end
		messageLabel = display.newRichLabel(0, 0,
			{w = 25,ap = anchorPoint, c = t
		})
		messageLabel:setTag(table.nums(chatListView:getNodes())+1)
 		messageLabel:reloadData()
	else
		messageLabel = display.newRichLabel(0, 0,
			{w = 25,ap = anchorPoint, c = {
				{text = '                                 ', fontSize = 22, color = '#ffffff'},
			}
		})
		messageLabel:setTag(table.nums(chatListView:getNodes())+1)
		messageLabel:reloadData()
	end
	return messageLabel
end
--[[
更新右侧聊天页面
--]]
function FriendListMediator:RefreshChatView()
	local datas = self:GetFriendDatas() or {}
	self.otherPlayerId = checkint(datas.friendId)
	self.otherPlayerAvatar = datas.avatar
	self.otherPlayerAvatarFrame = datas.avatarFrame
	local isFriend = self:GetIsFriend(datas.friendId)
	-- 更新右侧页面
	local viewData = self:GetViewComponent().viewData_
	viewData.chatLayout:setVisible(true)
	viewData.rightEmptyView:setVisible(false)
	if isFriend then
		if datas.noteName and datas.noteName ~= nil then
			viewData.titleLabel:setString(datas.noteName)
		else
			viewData.titleLabel:setString(datas.name)
		end
		viewData.addBtn:setVisible(false)
	else
		viewData.titleLabel:setString(__('陌生人'))
		viewData.addBtn:setVisible(true)
	end
end
--[[
通过玩家id判断是否为好友
--]]
function FriendListMediator:GetIsFriend( friendId )
	local isFriend = false
	for i,v in ipairs(self.friendDatas.friendList) do
		if checkint(v.friendId) == checkint(friendId) then
			isFriend = true
			break
		end
	end
	return isFriend
end

--[[
时间格式转换
--]]
function FriendListMediator:GetTimeStamp( time )
	return os.date("%Y-%m-%d %X", time)
end
--[[
获取离线时间
--]]
function FriendListMediator:GetOfflineTime( seconds_ )
	-- local seconds = os.time() - checkint(time)
	local str = __('上次在线：')
	local seconds = checkint(seconds_)
	if seconds < 60 then
		str = str .. string.fmt(__('_num_秒前'), {['_num_'] = seconds})
	elseif seconds < 3600 then
		str = str .. string.fmt(__('_num_分钟前'), {['_num_'] = math.ceil(seconds/60)})
	elseif seconds < 86400 then
		str = str .. string.fmt(__('_num_小时前'), {['_num_'] = math.ceil(seconds/3600)})
	else
		str = str .. string.fmt(__('_num_天前'), {['_num_'] = math.ceil(seconds/86400)})
	end
	return str
end
--[[
获取好友信息
--]]
function FriendListMediator:GetFriendDatas( friendsType, index )
	local type = friendsType or self.chattingType
	local idx = index or self.chattingFriendIndex
	local datas = nil
	if type == FriendListViewType.RECENT_CONTACTS then
		datas = self.friendDatas.recentContactsList[checkint(idx)]
	elseif type == FriendListViewType.MY_FRIENDS then
		datas = self.friendDatas.friendList[checkint(idx)]
	end
	return datas
end
--[[
添加到最近联系人
--]]
function FriendListMediator:AddRecentContacts( friendId )
	if self.chattingType == FriendListViewType.RECENT_CONTACTS then return end
	for i,v in ipairs(self.friendDatas.recentContactsList) do
		if checkint(friendId) == checkint(v.friendId) then
			return
		end
	end
	for i,v in ipairs(self.friendDatas.friendList) do
		if checkint(friendId) == checkint(v.friendId) then
			table.insert(self.friendDatas.recentContactsList, v)
			self:UpdateRecentContactsList()
			return
		end
	end
end
--[[
好友列表排序
--]]
function FriendListMediator:SortFriendsList( list )
	table.sort(checktable(list), function (a, b)
		local NewMsgA = checktable(ChatUtils.GetNewMessageByPlayerId(a.friendId))
		local NewMsgB = checktable(ChatUtils.GetNewMessageByPlayerId(b.friendId))
		if checkint(NewMsgA.hasNewMessage) == checkint(NewMsgB.hasNewMessage) and checkint(NewMsgA.hasNewMessage) == 0 then
			if checkint(a.topTime) == checkint(b.topTime) then 
				if checkint(a.isOnline) == checkint(b.isOnline) then
					return checkint(a.lastExitTime) < checkint(b.lastExitTime)
				else
					return checkint(a.isOnline) > checkint(b.isOnline)
				end
			else
				return checkint(a.topTime) > checkint(b.topTime)
			end
		elseif checkint(NewMsgA.hasNewMessage) == checkint(NewMsgB.hasNewMessage) and checkint(NewMsgA.hasNewMessage) == 1 then
			return checkint(a.lastReceiveTime) > checkint(b.lastReceiveTime)
		else
			return checkint(NewMsgA.hasNewMessage) > checkint(NewMsgB.hasNewMessage)
		end
	end)
end
--[[
删除好友
@params friendId list 玩家id 列表
--]]
function FriendListMediator:DeleteFriend( friendIds )
    local friendIdList = string.split(checkstr(friendIds), ',')
	local delFriendIdMap = {}
	for _, friendId in ipairs(friendIdList) do
		delFriendIdMap[tostring(friendId)] = true
	end
	local function removeTargetFriendId(allFriendsList)
		for index = #allFriendsList, 1, -1 do
			local friendData = checktable(allFriendsList[index])
			if delFriendIdMap[tostring(friendData.friendId)] then
				table.remove(allFriendsList, index)
			end
		end
	end
	removeTargetFriendId(self.friendDatas.friendList)
	removeTargetFriendId(self.friendDatas.assistanceList)	
	-- 更新本地好友数据
	self:UpdateLocalFriendListDatas()
	self:UpdateFriendListNumLabel()
	if self.showListLayer[tostring(FriendListViewType.MY_FRIENDS)] then
		-- 判断当前聊天对象是否为此玩家
		for k, friendId in pairs(friendIdList) do
			if checkint(self.otherPlayerId) == checkint(friendId) then
				self:GetViewComponent().viewData_.chatLayout:setVisible(false)
				self.chattingType = nil
				self.chattingFriendIndex = nil
				self.otherPlayerId = nil 
				self.otherPlayerAvatar = nil
			end
		end
	
		if self.chattingType == FriendListViewType.MY_FRIENDS and self.chattingFriendIndex then
    		for i,v in ipairs(self.friendDatas.friendList) do
    			if checkint(self.otherPlayerId) == checkint(v.friendId) then
    				self.chattingFriendIndex = i
    				break
    			end
    		end
		end
    	local friendGridView = self.showListLayer[tostring(FriendListViewType.MY_FRIENDS)]:getChildByName('expandableListView')
    	if friendGridView then
    		self:UpdateExpandableNode(MyFriendsType.FRIEND)
		end
	end
	-- 更新消息状态
	for k, friendId in pairs(friendIdList) do
		self:ReadMessageWithPlayerId(friendId)
	end
	self.removeFriendsList = {}	
	-- 隐藏视图和复选框
	self:UpdateDelMultiViewIsShow(false)
	self:RefreshListTabStatus()
end
--[[
好友置顶
@params friendId int 玩家id
--]]
function FriendListMediator:RefreshSetTopList( friendId, topTime)
	for i,v in ipairs(self.friendDatas.friendList) do
		if checkint(v.friendId) == checkint(friendId) then
			self.friendDatas.friendList[i].topTime = topTime
		end
	end
	self:SortFriendsList(self.friendDatas.friendList)
    if self.showListLayer[tostring(FriendListViewType.MY_FRIENDS)] then
    	-- 判断当前是否在于好友聊天
    	if self.chattingType == FriendListViewType.MY_FRIENDS and self.chattingFriendIndex then
    		for i,v in ipairs(self.friendDatas.friendList) do
    			if checkint(self.otherPlayerId) == checkint(v.friendId) then
    				self.chattingFriendIndex = i 
    				break
    			end
    		end
		end
    	self:UpdateExpandableNode(MyFriendsType.FRIEND)
    end
    self:RefreshListTabStatus()
    self:UpdateLocalFriendListDatas()
    self:UpdateFriendListNumLabel()
	self:RefreshLeftView()
end
--[[
添加好友刷新好友列表
@params datas userData 玩家数据
--]]
function FriendListMediator:AddFriendAction( datas )
    table.insert(self.friendDatas.friendList, datas.friend)
    self.SortFriendsList(self.friendDatas.friendList)
    if self.showListLayer[tostring(FriendListViewType.MY_FRIENDS)] then
    	-- 判断当前是否在于好友聊天
    	if self.chattingType == FriendListViewType.MY_FRIENDS and self.chattingFriendIndex then
    		for i,v in ipairs(self.friendDatas.friendList) do
    			if checkint(self.otherPlayerId) == checkint(v.friendId) then
    				self.chattingFriendIndex = i
    				break
    			end
    		end
		end
    	self:UpdateExpandableNode(MyFriendsType.FRIEND)
    end
    self:RefreshListTabStatus()
    self:UpdateLocalFriendListDatas()
    self:UpdateFriendListNumLabel()
end
--[[
加入到黑名单
@params datas{
	playerId int 玩家Id
	level int 玩家等级
	restaurantLevel int 玩家餐厅等级
	name str 玩家姓名
	avatar str 玩家头像
}
--]]
function FriendListMediator:AddBlacklistAction( datas )
	-- 判断该玩家是否已经在黑名单中
	if CommonUtils.IsInBlacklist(datas.playerId) then
		uiMgr:ShowInformationTips(__('对方已经在你的黑名单中了'))
		return
	end

	table.insert(self.blacklist, datas)
	gameMgr:GetUserInfo().blacklist = self.blacklist

	-- 判断是否为好友
	for i,v in ipairs(self.friendDatas.friendList) do
		if checkint(datas.playerId) == checkint(v.friendId) then
			self:DeleteFriend(datas.playerId)
			break
		end
	end
	-- 判断是否在最近联系人列表
	for i,v in ipairs(self.friendDatas.recentContactsList) do
		if checkint(datas.playerId) == checkint(v.friendId) then
			table.remove(self.friendDatas.recentContactsList, i)
			if checkint(self.otherPlayerId) == checkint(datas.playerId) then
				self.chattingType = nil
				self.chattingFriendIndex = nil
				self.otherPlayerId = nil
				self:GetViewComponent().viewData_.chatLayout:setVisible(false)
			end
			if self.chattingType == FriendListViewType.RECENT_CONTACTS and self.chattingFriendIndex then
    			for i,v in ipairs(self.friendDatas.recentContactsList) do
    				if checkint(self.otherPlayerId) == checkint(v.friendId) then
    					self.chattingFriendIndex = i
    					break
    				end
    			end
			end
			local layer = self.showListLayer[tostring(FriendListViewType.RECENT_CONTACTS)]
			if layer then
				local gridView = layer:getChildByName('gridView')
				gridView:setCountOfCell(table.nums(self.friendDatas.recentContactsList))
				gridView:reloadData()
			end
			break
		end
	end
	self:UpdateExpandableNode(MyFriendsType.BLACKLIST)
	self:UpdateLocalFriendListDatas()
	self:ReadMessageWithPlayerId(datas.playerId)
	self:RefreshListTabStatus()
	uiMgr:ShowInformationTips(__('已添加至黑名单'))
end
--[[
从黑名单中移除
@params blacklistId int 玩家id
--]]
function FriendListMediator:DeleteBlacklistAction( blacklistId )
	for i,v in ipairs(self.blacklist) do
		if checkint(v.playerId) == checkint(blacklistId) then
			table.remove(self.blacklist, i)
			break
		end
	end
	gameMgr:GetUserInfo().blacklist = self.blacklist
	self:UpdateExpandableNode(MyFriendsType.BLACKLIST)
end
--[[
切换到最近联系人聊天页面
@params friendDatas userData 玩家数据
--]]
function FriendListMediator:SwitchChatView( friendDatas )
	-- 隐藏当前页面
	if self.showListLayer[tostring(self.selectedListType)] then
		self.showListLayer[tostring(self.selectedListType)]:setVisible(false)
	end
	self.chattingFriendIndex = nil
    self.selectedListType = FriendListViewType.RECENT_CONTACTS
    self.chattingType = FriendListViewType.RECENT_CONTACTS
    self:ListTabButtonActions(FriendListViewType.RECENT_CONTACTS)
    local isFind = false
    for i,v in ipairs(self.friendDatas.recentContactsList) do
    	if checkint(friendDatas.friendId) == checkint(v.friendId) then
    		isFind = true
    		self.chattingFriendIndex = i
    		break
    	end
    end
    if not isFind then
    	table.insert(self.friendDatas.recentContactsList, friendDatas)
    	self:SortFriendsList(self.friendDatas.recentContactsList)
    	for i,v in ipairs(self.friendDatas.recentContactsList) do
    		if checkint(friendDatas.friendId) == checkint(v.friendId) then
    			self.chattingFriendIndex = i
    			break
    		end
    	end
    end
    local gridView = self.showListLayer[tostring(FriendListViewType.RECENT_CONTACTS)]:getChildByName('gridView')
	gridView:setCountOfCell(#checktable(self.friendDatas.recentContactsList))
	gridView:reloadData()
	local chatListView = self:GetViewComponent().viewData_.chatListView
	chatListView:removeAllNodes()
	chatListView:reloadData()
	self:RefreshChatView()
	self:AddChattingHistory()
end
--[[
刷新好友数目显示
--]]
function FriendListMediator:UpdateFriendListNumLabel()
	local layer = self.showListLayer[tostring(FriendListViewType.MY_FRIENDS)]
	if layer then
		local expandableListView = layer:getChildByName('expandableListView')
		local expandableNode = expandableListView:getExpandableNodeAtIndex(0)
		local numLabel = expandableNode:getChildByName('numLabel')
		local onlineNum = 0
		local friendsNum = #self.friendDatas.friendList
		for i,v in ipairs(self.friendDatas.friendList) do
			if checkint(v.isOnline) == 1 then
				onlineNum = onlineNum + 1
			end
		end
		numLabel:setString(string.format('(%d/%d)', onlineNum, friendsNum))
	end
end
--[[
更改输入框状态
--]]
function FriendListMediator:RefreshEditBox( isEnabled )
	local viewData = self:GetViewComponent().viewData_
	if isEnabled then
		viewData.sendBox:setEnabled(true)
		viewData.searchBox:setEnabled(true)
	else
		viewData.sendBox:setEnabled(false)
		viewData.searchBox:setEnabled(false)
	end
end
--[[
更新黑名单列表
--]]
function FriendListMediator:UpdateBlackList()
	for _,friendDatas in ipairs(self.friendDatas.friendList) do
		for i, blackDatas in ipairs(self.blacklist) do
			if checkint(blackDatas.playerId) == checkint(friendDatas.friendId) then
				table.remove(self.blacklist, i)
				break
			end
		end
	end
	gameMgr:GetUserInfo().blacklist = self.blacklist
end

function FriendListMediator:LongClickEndHandler( sender, touch, duration )
    if voiceEngine and duration >= 1.0 then
        local succ = voiceEngine:StopRecording()
        -- print('------------->>>',succ)
        if succ == 0 then
            --结束成功后直接上传
            if not self.isMoving then
                local recordFile = AUDIO_RECORD_PATH
                if utils.isExistent(recordFile) then
                    voiceEngine:UploadRecordedFile(recordFile, 50000)
                end
            end
            app.audioMgr:ResumeBGMusic()
        end
    end
    local chatAnimate = sceneWorld:getChildByName('ChatAnimate')
    if chatAnimate then chatAnimate:removeFromParent() end
    self.isMoving = false
end
--[[
语音按钮长按
--]]
function FriendListMediator:LongEventAction( sender, touch )
	-- 非聊天模式直接返回
	if voiceEngine and VoiceType.Messages ~= voiceChatMgr:GetMode() then
		uiMgr:ShowInformationTips(__('您当前处于实时语音，无法使用其他语音功能。'))
		return false
	end

	if not GAME_MODULE_OPEN.GVOICE_SERVER then
		app.uiMgr:ShowInformationTips(__('该功能暂不可用'))
		return false
	end

    local chatAnimate = sceneWorld:getChildByName('ChatAnimate')
    if not chatAnimate then
        xTry(function()
            chatAnimate = require('Game.views.chat.ChatAnimate').new()
            chatAnimate:setName('ChatAnimate')
            display.commonUIParams(chatAnimate, {po = cc.p(display.cx, display.cy)})
            sceneWorld:addChild(chatAnimate, GameSceneTag.Chat_GameSceneTag + 1)
            if voiceEngine then
                --必需有返回值
                local ret = voiceEngine:ApplyMessageKey()
                if ret == 0 then --已经应用过key的逻辑
                    voiceEngine:StartUpdate()
                    app.audioMgr:PauseBGMusic()
                    local recordFile = AUDIO_RECORD_PATH
                    if utils.isExistent(recordFile) then
                        FTUtils:deleteFile(recordFile)
                    end
                    voiceEngine:StartRecording(recordFile)
                end
			else
                app.uiMgr:ShowInformationTips(__('不支持语音功能'))
            end
        end,function()
            return true
        end)
    end
	return true
end
--[[
更新本地好友数据
--]]
function FriendListMediator:UpdateLocalFriendListDatas()
	gameMgr:GetUserInfo().friendList = self.friendDatas.friendList
end
--[[
移除点击事件
--]]
function FriendListMediator:RemoveLongActionEvent()
    if voiceEngine and VoiceType.Messages == voiceChatMgr:GetMode() then
        voiceEngine:StopRecording()
    end
    sceneWorld:removeOnTouchEndedAfterLongClickScriptHandler()
    sceneWorld:removeOnTouchMovedAfterLongClickScriptHandler()
end
--[[
移除新好友红点
--]]
function FriendListMediator:ClearNewFriendsRemind()
	AppFacade.GetInstance():GetManager("DataManager"):ClearRedDotNofication(tostring(RemindTag.NEW_FRIENDS), RemindTag.NEW_FRIENDS)
end
--[[
判断是否在最近联系人列表
--]]
function FriendListMediator:IsInRecentContactsList( friendId )
	for i,v in ipairs(self.friendDatas.recentContactsList) do
		if checkint(v.friendId) == checkint(friendId) then
			return true
		end
	end
	return false
end
--[[
收到新私聊
@params datas table 聊天数据
--]]
function FriendListMediator:GetNewPrivateMessage(datas)
	if CommonUtils.GetIsFriendById(datas.friendId) and self.showListLayer[tostring(FriendListViewType.MY_FRIENDS)] then
    	local friendGridView = self.showListLayer[tostring(FriendListViewType.MY_FRIENDS)]:getChildByName('expandableListView')
    	if friendGridView then
    		self:UpdateExpandableNode(MyFriendsType.FRIEND)
		end
		if self:IsInRecentContactsList(checkint(datas.friendId)) then
			self:UpdateRecentContactsList()
		else
			for i,v in ipairs(self.friendDatas.friendList) do
				if checkint(datas.friendId) == checkint(v.friendId) then
					table.insert(self.friendDatas.recentContactsList, v)
					self:UpdateRecentContactsList()
					break
				end
			end
		end
	else
		if self:IsInRecentContactsList(checkint(datas.friendId)) then
			self:UpdateRecentContactsList()
		else
			self:SendSignal(COMMANDS.COMMAND_Friend_AddFriend, {friendId = datas.friendId})
		end
	end
end
--[[
更新最近联系人列表
--]]
function FriendListMediator:UpdateRecentContactsList()
	self:SortFriendsList(self.friendDatas.recentContactsList)
	local layer = self.showListLayer[tostring(FriendListViewType.RECENT_CONTACTS)]
	if layer then
		local gridView = layer:getChildByName('gridView')
		gridView:setCountOfCell(#checktable(self.friendDatas.recentContactsList))
		gridView:reloadData()
	end
end
--[[
将消息变为已读
@params playerId int 对方玩家Id
--]]
function FriendListMediator:ReadMessageWithPlayerId( playerId )
	if next(ChatUtils.GetNewMessageByPlayerId(checkint(playerId))) ~= nil then
		ChatUtils.ReadNewMessage(checkint(playerId))
	end
end
--[[
是否有新消息
@params playerId int 对方玩家Id
--]]
function FriendListMediator:HasNewMessageWithPlayerId( playerId )
	if checkint(ChatUtils.GetNewMessageByPlayerId(checkint(playerId)).hasNewMessage) == 1 then
		return true
	else
		return false
	end
end
--[[
更新好友数据
--]]
function FriendListMediator:UpdateFriendData( datas )
	self.friendDatas = datas or {}
	-- 排序
	self:SortFriendsList(self.friendDatas.friendList)
	self:SortFriendsList(self.friendDatas.recentContactsList)
	self:UpdateExpandableNode(MyFriendsType.FRIEND)
end
--[[
更新左侧页面
--]]
function FriendListMediator:RefreshLeftView()
	self:RefreshListTabStatus()
	if self.showListLayer[tostring(FriendListViewType.MY_FRIENDS)] then
		self:UpdateExpandableNode(MyFriendsType.FRIEND)
	end
	if self.showListLayer[tostring(FriendListViewType.RECENT_CONTACTS)] then
		self:UpdateRecentContactsList()
	end
end
function FriendListMediator:OnRegist(  )
	local FriendListCommand = require('Game.command.FriendListCommand')
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Friend_FindFriend, FriendListCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Friend_AddFriend, FriendListCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Friend_HandleAddFriend, FriendListCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Friend_RefreshRecmmend, FriendListCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Friend_EmptyRequest, FriendListCommand)
	regPost(POST.FRIEND_SET_TOP)
	regPost(POST.FRIEND_SET_TOP_CANCEL)
end

function FriendListMediator:OnUnRegist(  )
	self:RemoveLongActionEvent()
    app.audioMgr:ResumeBGMusic()
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Friend_FindFriend)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Friend_AddFriend)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Friend_HandleAddFriend)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Friend_RefreshRecmmend)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Friend_EmptyRequest)
	sceneWorld:setMultiTouchEnabled(false)
	unregPost(POST.FRIEND_SET_TOP)
	unregPost(POST.FRIEND_SET_TOP_CANCEL)
end

return FriendListMediator
