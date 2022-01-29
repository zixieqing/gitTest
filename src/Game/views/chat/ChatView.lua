--[[
主界面聊天UI
--]]
local labelparser = require("Game.labelparser")
local ChatView = class('ChatView', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.chat.ChatView'
	-- node:setBackgroundColor(cc.c4b(0,100,0,100))
	node:enableNodeEvents()
	return node
end)


local channelConf = {
    {tag = CHAT_CHANNELS.CHANNEL_WORLD},
	{tag = CHAT_CHANNELS.CHANNEL_UNION,   switch = MODULE_SWITCH.GUILD},
	{tag = CHAT_CHANNELS.CHANNEL_PRIVATE, switch = MODULE_SWITCH.FRIEND},
	{tag = CHAT_CHANNELS.CHANNEL_SYSTEM},
	{tag = CHAT_CHANNELS.CHANNEL_TEAM,    switch = MODULE_SWITCH.MATERIAL_SCRIPT},
    {tag = CHAT_CHANNELS.CHANNEL_HELP,    switch = MODULE_SWITCH.FRIEND},
    {tag = CHAT_CHANNELS.CHANNEL_HOUSE,   moduleState = GAME_MODULE_OPEN.CAT_HOUSE},
}

local MAX_HISTORY_NUM = 10


local function CreateView( )
	local view = display.newLayer(0,0,{size = cc.size(700, display.height), ap = cc.p(0,0.5)})
	-- view:setBackgroundColor(cc.c4b(0,100,0,100))

	--背景
	local bg = display.newImageView(_res('ui/common/common_bg_4.png'), 0, 0,
		{scale9 = true, size = cc.size(608,display.size.height), enable = true})
	bg:setAnchorPoint(cc.p(0,0))
	view:addChild(bg)
    local bgSize = bg:getContentSize()
	-- cview:setContentSize(bgSize)


	--顶部发送消息部分
	-- local topView = display.newLayer(2,bgSize.height - 5,{size = cc.size(bgSize.width - 110,0), ap = cc.p(0,1)})
	-- view:addChild(topView,2)

	-- local topBg = display.newImageView(_res('ui/home/chatSystem/dialogue_bg_send.png'), 0, 0,
	-- 	{scale9 = true, size = cc.size(bgSize.width - 110,68)})
	-- topBg:setAnchorPoint(cc.p(0,0))
	-- topView:setContentSize(topBg:getContentSize())
    -- topView:setPosition(cc.p(bgSize.width - 110, bgSize.height - 4))
	-- topView:addChild(topBg)

	-- local tipsLabel = display.newLabel(0, 0, {text = __('该频道下不能发言'), fontSize = 20, color = '#4c4c4c', ap = cc.p(0.5, 0.5)})
	-- display.commonUIParams(tipsLabel, {po = cc.p(topBg:getContentSize().width * 0.5 ,topBg:getContentSize().height * 0.5)})
	-- topBg:addChild(tipsLabel,1)
	-- tipsLabel:setVisible(false)



	--侧边btn部分
	local btnView = display.newLayer(0,0,{size = cc.size(bgSize.width,display.height), ap = cc.p(0,0)})
	-- btnView:setBackgroundColor(cc.c4b(0,100,0,100))
	view:addChild(btnView,1)

    local btnBg = ui.image({img = _res('ui/home/chatSystem/dialogue_bg_side.png'), scale9 = true, size = cc.size(110 + display.SAFE_L, display.height), ap = ui.lb})
    btnBg:setPositionX(-display.SAFE_L)
	btnView:addChild(btnBg)

    local checkBoxs = {}
    local offset = 1
    for _, v in ipairs(channelConf) do
        local isCloseModule = v.moduleState == false
        if isCloseModule then
            break
        end

        if not v.switch or CommonUtils.GetModuleAvailable(v.switch) then
            local checkBox= display.newCheckBox(0,0,{--newButton
                n = _res('ui/home/chatSystem/dialogue_btn_side_default.png')
                ,s = _res('ui/home/chatSystem/dialogue_btn_side_selected.png'),
                scale9 = true, size = cc.size(98, 60), ap = display.LEFT_CENTER,
            })
            btnView:addChild(checkBox,3)
            checkBox:setPosition(cc.p(4,btnBg:getContentSize().height - 72*offset - 54))
            checkBox:setTag(v.tag)
            local tempLabel = display.newLabel(0, 0, {font = TTF_GAME_FONT,ttf = true,text = ChatUtils.GetChannelTypeName(v.tag), w = 90 , hAlign = display.TAC,  fontSize = 22, reqH = 55, color = '#fffcd0', ap = cc.p(0.5, 0.5)})
            display.commonUIParams(tempLabel, {po = cc.p(checkBox:getContentSize().width * 0.5 ,checkBox:getContentSize().height * 0.5)})
            tempLabel:enableOutline(ccc4FromInt('7a2525'),1)
            checkBox:addChild(tempLabel,1)
            tempLabel:setTag(999)
            local remindIcon = display.newImageView(_res('ui/common/common_hint_circle_red_ico.png'), 90, 50)
            remindIcon:setName('remindIcon')
            remindIcon:setVisible(false)
            checkBox:addChild(remindIcon, 10)
            checkBoxs[tostring(v.tag)] = checkBox
            offset = offset + 1
        end
	end

	--新未读消息
    local unReadBtn = display.newButton(0, 0,
        {n = _res('ui/home/chatSystem/dialogue_bg_unread.png'),
        s = _res('ui/home/chatSystem/dialogue_bg_unread.png'),scale9 = true, size = cc.size(bgSize.width - 110,48)})--, animate = true, cb = handler(self, self.breakBtnCallback)
    display.commonUIParams(unReadBtn, {ap = cc.p(0,0),po = cc.p(108, 80)})
    display.commonLabelParams(unReadBtn, fontWithColor(5,{color = 'ba5c5c',text = __('有新消息')}))
    view:addChild(unReadBtn,4)
    -- 切换聊天室
    local switchChatRoomLayout = CLayout:create(cc.size(bgSize.width, 41))
    switchChatRoomLayout:setPosition(cc.p(bgSize.width/2, display.height - 26))
    view:addChild(switchChatRoomLayout, 10)
    local switchBg = display.newImageView(_res('ui/home/chatSystem/dialogue_channel_bg.png'), switchChatRoomLayout:getContentSize().width - 10, switchChatRoomLayout:getContentSize().height/2, {ap = cc.p(1, 0.5)})
    switchChatRoomLayout:addChild(switchBg)
    local switchBtn = display.newButton(switchChatRoomLayout:getContentSize().width - 30, switchChatRoomLayout:getContentSize().height/2, {n = _res('ui/home/chatSystem/dialogue_channel_bg_input.png'), ap = cc.p(1, 0.5)})
    switchChatRoomLayout:addChild(switchBtn)
    local switchBtnDescr = display.newRichLabel(switchBtn:getContentSize().width/2, switchBtn:getContentSize().height/2)
    switchBtn:addChild(switchBtnDescr)

    --聊天list
    local listSize = cc.size(bgSize.width - 110, btnBg:getContentSize().height - 80)
    local chatListView = CListView:create(listSize)
    chatListView:setDirection(eScrollViewDirectionVertical)
    chatListView:setBounceable(false)
    chatListView:setAnchorPoint(cc.p(0, 1))
    chatListView:setPosition(cc.p(108, display.height - 46))
    view:addChild(chatListView, 3)
    -- chatListView:setBackgroundColor(cc.c4b(0,100,0,100))

    local chatInputView = require( 'Game.views.chat.ChatInputView' ).new()
 	display.commonUIParams(chatInputView, {po = cc.p(bgSize.width * 0.5, 40)})
    view:addChild(chatInputView,6)
	return {
		view           = view,
		bg             = bg,
		bgSize         = bgSize,
        chatInputView  = chatInputView,
		chatListView   = chatListView,
		checkBoxs      = checkBoxs,
		unReadBtn      = unReadBtn,
        switchBtn      = switchBtn,
        switchBtnDescr = switchBtnDescr,
        switchChatRoomLayout = switchChatRoomLayout
	}
end

function ChatView:ctor( ... )
    local args = unpack({...}) or {}
    self.curChannel = args.channelId or CHAT_CHANNELS.CHANNEL_WORLD
    self.isAction = true
    self.privateSelectedId = nil -- 私聊Id
    self.playerInfo = {} -- 玩家基本信息
    self.contentOffset = cc.p(0, 0)
	local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 0))
	eaterLayer:setTouchEnabled(true)
	eaterLayer:setContentSize(display.size)
	eaterLayer:setAnchorPoint(cc.p(0.5, 1.0))
	eaterLayer:setPosition(cc.p(display.cx, display.height))
	self:addChild(eaterLayer, -1)
    local touchView = CColorView:create(cc.c4b(0, 0, 0, 0))
    touchView:setTouchEnabled(true)
    touchView:setContentSize(cc.size(608 + display.SAFE_L, display.height))
    touchView:setAnchorPoint(cc.p(0, 1.0))
    touchView:setPosition(cc.p(0, display.height))
    self:addChild(touchView)
    sceneWorld:setMultiTouchEnabled(true)
	eaterLayer:setOnClickScriptHandler(function (sender)
		PlayAudioByClickClose()
        self:RemoveChatView()
        -- if self.isAction then return end
        -- self.isAction = true
        -- self:runAction(cc.Sequence:create(
            -- cc.TargetedAction:create(self.viewData.view,cc.MoveTo:create(0.2,cc.p(-800, display.cy))),
            -- cc.RemoveSelf:create()
            -- ))
	end)
	xTry(function ()
        self.viewData = CreateView()
        self:RefreshLeftBtnView() -- 更新页签按钮状态
		display.commonUIParams(self.viewData.view, {po = cc.p(display.SAFE_L - 800,display.cy)})
		self:addChild(self.viewData.view, 1)
        self.viewData.view:runAction(cc.Sequence:create(
                cc.MoveTo:create(0.2,cc.p(display.SAFE_L, display.cy)),
                cc.CallFunc:create(function()
                    self.isAction = false
            end)))
        for name,val in pairs(self.viewData.checkBoxs) do
            val:setOnClickScriptHandler(handler(self, self.TabButtonAction))
        end
        self.viewData.unReadBtn:setOnClickScriptHandler(function( sender )
			sender:setVisible(false)
			self.viewData.chatListView:setContentOffsetToBottom()
		end)
        self.viewData.switchBtn:setOnClickScriptHandler(function( sender )
            local worldChannelMaxRoom = checkint(app.gameMgr:GetUserInfo().worldChannelMaxRoom)
            local function inputCallback ( str )
                if checkint(str) >= 1 and checkint(str) <= worldChannelMaxRoom then
                    app.chatMgr:JoinChatRoom(checkint(str))
                else
                    app.uiMgr:ShowInformationTips(string.fmt(__('请输入1到_num_之间的数字'), {['_num_'] = worldChannelMaxRoom}))
                end
            end
            -- 房间号位数限制
            local nums = 1
            local limit = worldChannelMaxRoom
            while limit/10 >= 1 do
                nums = nums + 1
                limit = math.floor(limit/10)
            end
            app.uiMgr:ShowNumberKeyBoard({nums = nums, model = 2, titleText = __('请输入房间Id:'), callback = inputCallback, defaultContent = string.fmt(__('输入数字1-_num_'), {['_num_'] = worldChannelMaxRoom})})
        end)
		self.viewData.chatListView:setOnScrollingScriptHandler(function( )
            self.contentOffset = self.viewData.chatListView:getContentOffset()
			if self.viewData.chatListView:getMaxOffset().y == self.viewData.chatListView:getContentOffset().y then
				self.viewData.unReadBtn:setVisible(false)
			end
		end)
        self:RefreshChatRoomId() -- 刷新聊天室Id
        -- 根据外部传入的channelId刷新一次界面
        local targetChannelId = self.curChannel
        self.curChannel = nil
        self:RefreshUIByChannelId(targetChannelId)
        local voiceChatMgr = AppFacade.GetInstance():GetManager("GlobalVoiceManager")
        local voiceEngine = voiceChatMgr:GetVoiceNode()
        AppFacade.GetInstance():RegistObserver('VOICE_EVENT', mvc.Observer.new(function(stage, signal)
            local name = signal:GetName()
            if name == 'VOICE_EVENT' then
                local body = signal:GetBody()
                local name = body.name
                local code = checkint(body.code)
                if name == StateType.State_Download then
                    local fileID = body.fileID
                    --动画的逻辑
                elseif name == StateType.State_RecordFile then
                    --已播完的逻辑
                end
            end
    end, self))

    end, __G__TRACKBACK__)

end

function ChatView:RemoveChatView()
    if self.isAction then return end
    self.isAction = true
    local privateChatView = self:getChildByName('chatPrivateMessageView')
    if privateChatView then
        self:runAction(cc.Sequence:create(
                cc.Spawn:create(
                    cc.TargetedAction:create(privateChatView, cc.MoveTo:create(0.2, cc.p(-800, display.cy))),
                    cc.TargetedAction:create(self.viewData.view,cc.MoveTo:create(0.1,cc.p(-800, display.cy)))
                ),
                cc.RemoveSelf:create()
            )
        )
    else
        self:runAction(cc.Sequence:create(
                cc.TargetedAction:create(self.viewData.view,cc.MoveTo:create(0.2,cc.p(-800, display.cy))),
                cc.RemoveSelf:create()
            )
        )
    end
end
--[[
更新世界聊天聊天室信息
--]]
function ChatView:RefreshChatRoomId()
    local richLabel = self.viewData.switchBtnDescr
    display.reloadRichLabel(richLabel, {c = {
        {color = '#5c5c5c', fontSize = 22, text = string.fmt(__('世界频道_num_'), {_num_ = checkint(app.chatMgr:GetChatRoomId(CHAT_CHANNELS.CHANNEL_WORLD))}) },
        {color = '#7c7c7c', fontSize = 22, text = string.fmt(__('(输入数字1-_num_)'), {_num_ = checkint(app.gameMgr:GetUserInfo().worldChannelMaxRoom)}) },
    }})
end
function ChatView:InsertNewItem(chatDatas)
    --判断是否为黑名单
    if CommonUtils.IsInBlacklist(chatDatas.playerId) then
        return
    end
    -- self.viewData.topView:setVisible(false)
    self.viewData.unReadBtn:setVisible(false)
	local index = self.viewData.chatListView:getNodeCount()
    if index >= MAX_SHOW_MSG then
        self.viewData.chatListView:removeNodeAtIndex(0)
    end
	local view = require( 'Game.views.chat.MessageItemView' ).new({chatDatas = chatDatas, index = (index + 1)})
	self:ChestListInsertView(view)
    --self.viewData.chatListView:insertNodeAtLast(view)
	--self.viewData.chatListView:reloadData()
    -- self.viewData.chatListView:setContentOffsetToBottom()
end
--[[
添加私聊cell
--]]
function ChatView:InsertPrivateItem(chatDatas, isFront, idx )
    if not chatDatas or next(chatDatas) == nil then return end
    local playerDatas = nil
    for i,v in ipairs(self.playerInfo) do
        if checkint(v.friendId) == checkint(chatDatas.playerId) then
            playerDatas = v
            break
        end
    end
    local view = require( 'Game.views.chat.ChatPrivateItemView' ).new({chatDatas = chatDatas, index = idx, playerDatas = playerDatas})

    if isFront then
        self:ChestListInsertView(view , false)
    else
        self:ChestListInsertView(view )
    end
    if checkint(view.chatDatas.playerId) == checkint(self.privateSelectedId) then
        view.viewData.bg:setNormalImage(_res('ui/home/chatSystem/dialogue_bg_friends_chat_selected.png'))
        view.viewData.bg:setSelectedImage(_res('ui/home/chatSystem/dialogue_bg_friends_chat_selected.png'))
    end
    self.viewData.chatListView:setContentOffsetToBottom()
    view.viewData.bg:setOnClickScriptHandler(handler(self, self.PrivateListBgCallback))
end
--[[
私聊列表点击回调
--]]
function ChatView:PrivateListBgCallback( sender )
    local playerId = sender:getUserTag()
    local playerName = sender:getName()
    if checkint(playerId) == checkint(self.privateSelectedId) then return end
    self:RemoveChatPrivateMessageView()
    -- 刷新聊天列表
    self:RefreshPrivateCell(playerId)
    self:RefreshRemindIconStatus(CHAT_CHANNELS.CHANNEL_PRIVATE)
    local chatPrivateMessageView = require( 'Game.views.chat.ChatPrivateMessageView' ).new({playerId = playerId, playerName = playerName})
    chatPrivateMessageView:setName('chatPrivateMessageView')
    self:addChild(chatPrivateMessageView, 2)
    display.commonUIParams(chatPrivateMessageView, {po = cc.p(display.SAFE_L + 614,display.cy), ap = cc.p(0, 0.5)})
    -- 添加聊天信息
    self:AddChattingHistory(playerId)
end
--[[
移除私聊对话页面
--]]
function ChatView:RemoveChatPrivateMessageView()
    local privateChatView = self:getChildByName('chatPrivateMessageView')
    if privateChatView then
        privateChatView:removeFromParent()
    end
end
--[[
更新私聊列表
@params playerId int 被选中的玩家Id
--]]
function ChatView:RefreshPrivateCell( playerId )

    if self.privateSelectedId then
        local cell = self:GetPrivateCellByPlayerId(self.privateSelectedId)
        cell.viewData.bg:setNormalImage(_res('ui/home/chatSystem/dialogue_bg_friends_chat.png'))
        cell.viewData.bg:setSelectedImage(_res('ui/home/chatSystem/dialogue_bg_friends_chat.png'))
    end
    local cell = self:GetPrivateCellByPlayerId(playerId)
    cell.viewData.bg:setNormalImage(_res('ui/home/chatSystem/dialogue_bg_friends_chat_selected.png'))
    cell.viewData.bg:setSelectedImage(_res('ui/home/chatSystem/dialogue_bg_friends_chat_selected.png'))
    ChatUtils.ReadNewMessage(playerId)
    cell.viewData.remindIcon:setVisible(false)
    self.privateSelectedId = playerId
end
--[[
通过玩家id获取私聊cell
@params playerId int 玩家Id
--]]
function ChatView:GetPrivateCellByPlayerId( playerId )
    local cell = nil
    local chatListView = self.viewData.chatListView
    local nodes = chatListView:getNodes()
    for i,v in ipairs(nodes) do
        if checkint(v.chatDatas.playerId) == checkint(playerId) then
            cell = chatListView:getNodeAtIndex(i -1)
            break
        end
    end
    return cell
end
--[[
添加私聊记录
@params playerId int 聊天对象id
--]]
function ChatView:AddChattingHistory( playerId )
    -- 更新聊天列表
    local tempTab = {}
    local chatMessages = checktable(ChatUtils.GetChatMessages(app.gameMgr:GetPlayerId(), playerId))
    local startNum = 1
    if #chatMessages - MAX_HISTORY_NUM > 0 then
        startNum = #chatMessages - MAX_HISTORY_NUM + 1
    end
    for i = startNum, #chatMessages, 1 do
        local v = chatMessages[i]
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
        chatDatas.playerId = v.sendPlayerId

        if checkint(v.sendPlayerId) ~= checkint(app.gameMgr:GetPlayerId()) then
            chatDatas.sender = MSG_TYPES.MSG_TYPE_OTHER
        end
        if checkint(v.sendPlayerId) == checkint(app.gameMgr:GetPlayerId()) then
            chatDatas.avatar = app.gameMgr:GetUserInfo().avatar
            chatDatas.avatarFrame = app.gameMgr:GetUserInfo().avatarFrame
        else
            for i, datas in ipairs(self.playerInfo) do
                if checkint(datas.friendId) == checkint(v.sendPlayerId) then
                    chatDatas.avatar = datas.avatar
                    chatDatas.avatarFrame = datas.avatarFrame
                    break
                end
            end
        end
        table.insert(tempTab,chatDatas)
    end
    -- for i,v in ipairs(ChatUtils.GetChatMessages(app.gameMgr:GetPlayerId(), playerId)) do
    --     local chatDatas = {}
    --     chatDatas.name = v.sendPlayerName
    --     chatDatas.message = v.content
    --     chatDatas.fileid = v.voiceId
    --     chatDatas.sendTime = v.sendTime
    --     chatDatas.sender = MSG_TYPES.MSG_TYPE_SELF
    --     chatDatas.messagetype = CHAT_MSG_TYPE.TEXT
    --     if v.voiceId ~= '' then
    --         chatDatas.messagetype = CHAT_MSG_TYPE.SOUND
    --     end
    --     if checkint(v.sendPlayerId) ~= app.gameMgr:GetPlayerId() then
    --         chatDatas.sender = MSG_TYPES.MSG_TYPE_OTHER
    --     end
    --     table.insert(tempTab,chatDatas)
    -- end
    for i,v in ipairs(tempTab) do
        self:InsertPrivateMessageItem(v)
    end
end
--[[
添加私聊信息cell
@params chatDatas
--]]
function ChatView:InsertPrivateMessageItem(chatDatas)
    local chatPrivateMessageView = self:getChildByName('chatPrivateMessageView')
    if chatPrivateMessageView then
        local chatListView = chatPrivateMessageView.viewData_.chatListView
        local index = chatListView:getNodeCount()
        local view = require( 'Game.views.chat.MessageItemView' ).new({chatDatas = chatDatas, index = (index + 1)})
        self:ChestListInsertView(view )
        chatListView:setContentOffsetToBottom()
    end
end

--[[
查找该玩家基本信息是否存在
--]]
function ChatView:HasPlayerInfo( playerId )
    local hasDatas = false
    for i,v in ipairs(self.playerInfo) do
        if checkint(playerId) == checkint(v.friendId) then
            hasDatas = true
            break
        end
    end
    return hasDatas
end
--[[
获取该玩家最后一条信息
@params playerId int 玩家id
--]]
function ChatView:GetLastMessage( playerId )
    local allChatDatas = ChatUtils.GetChatMessages(playerId, app.gameMgr:GetPlayerId())
    local lastChatDatas = allChatDatas[#allChatDatas] or {}
    -- 防止allChatDatas为空表
    if next(lastChatDatas) == nil then return end
    local chatDatas = {}
    chatDatas.message = string.format('<desc>%s</desc><fileid>%s</fileid><messagetype>1</messagetype>',lastChatDatas.content, lastChatDatas.voiceId)
    chatDatas.sendTime = lastChatDatas.sendTime or os.time()
    chatDatas.sender = MSG_TYPES.MSG_TYPE_OTHER
    chatDatas.messagetype = CHAT_MSG_TYPE.TEXT
    chatDatas.fileid = nil
    chatDatas.channel = 5
    chatDatas.receivePlayerId = lastChatDatas.receivePlayerId
    chatDatas.receivePlayerName = lastChatDatas.receivePlayerName
    chatDatas.sendPlayerId = lastChatDatas.sendPlayerId
    chatDatas.sendPlayerName = lastChatDatas.sendPlayerName
    if lastChatDatas.voiceId ~= '' then
        chatDatas.messagetype = CHAT_MSG_TYPE.SOUND
        chatDatas.fileid = lastChatDatas.voiceId
        chatDatas.time = lastChatDatas.time
    end
    if checkint(lastChatDatas.sendPlayerId) == checkint(app.gameMgr:GetPlayerId()) then
        chatDatas.name = lastChatDatas.receivePlayerName
        chatDatas.playerId = lastChatDatas.receivePlayerId
    else
        chatDatas.name = lastChatDatas.sendPlayerName
        chatDatas.playerId = lastChatDatas.sendPlayerId
    end
    self:InsertPrivateItem(chatDatas, false, i)
    self.viewData.chatListView:setContentOffsetToBottom()
    self:RefreshRemindIconStatus(CHAT_CHANNELS.CHANNEL_PRIVATE)
end
--[[
收到消息
--]]
function ChatView:ReceiveMessage( chatDatas )
    if not chatDatas.channel then
        chatDatas.channel = CHAT_CHANNELS.CHANNEL_PRIVATE
    end
    if checkint(self.curChannel) == checkint(chatDatas.channel) then
        if checkint(chatDatas.channel) == CHAT_CHANNELS.CHANNEL_WORLD or
            checkint(chatDatas.channel) == CHAT_CHANNELS.CHANNEL_UNION or
            checkint(chatDatas.channel) == CHAT_CHANNELS.CHANNEL_HOUSE or
            checkint(chatDatas.channel) == CHAT_CHANNELS.CHANNEL_TEAM then
            if checkint(chatDatas.sender) == MSG_TYPES.MSG_TYPE_SELF then
                --如果是自己发的消息
                self:InsertNewItem(chatDatas)
                self.viewData.unReadBtn:setVisible(false)
                self.viewData.chatListView:setContentOffsetToBottom()
            else
                --如果不是自己发的消息
                local offset = self.viewData.chatListView:getContentOffset()
                if offset.y < 0 then
                    self:InsertNewItem(chatDatas)
                    self.viewData.chatListView:setContentOffset(self.contentOffset)
                    self.viewData.unReadBtn:setVisible(true)
                else
                    self:InsertNewItem(chatDatas)
                    self.viewData.unReadBtn:setVisible(false)
                    self.viewData.chatListView:setContentOffsetToBottom()
                end
            end
        elseif checkint(chatDatas.channel) == CHAT_CHANNELS.CHANNEL_PRIVATE then
            local chatListView = self.viewData.chatListView
            local nodes = chatListView:getNodes()
            if not chatDatas.messages then
                chatDatas = {messages = {chatDatas}}
            end
            for i,v in ipairs(chatDatas.messages) do
                if checkint(v.friendId) == checkint(self.privateSelectedId) then
                    ChatUtils.ReadNewMessage( v.friendId )
                end
                if self:HasPlayerInfo(v.friendId) then
                    -- 移除已有cell
                    for idx, node in ipairs(nodes) do
                        if checkint(node.chatDatas.playerId) == checkint(v.friendId) then
                            chatListView:removeNodeAtIndex(idx -1)
                            break
                        end
                    end
                    -- 添加新的cell
                    local temp = {}
                    temp.message = string.format('<desc>%s</desc><fileid>%s</fileid><messagetype>1</messagetype>',v.message, v.voiceId or '')
                    temp.sendTime = v.sendTime or os.time()
                    temp.sender = MSG_TYPES.MSG_TYPE_OTHER
                    temp.messagetype = CHAT_MSG_TYPE.TEXT
                    temp.fileid = nil
                    temp.channel = 5
                    temp.receivePlayerId = app.gameMgr:GetPlayerId()
                    temp.receivePlayerName = app.gameMgr:GetUserInfo().playerName
                    temp.sendPlayerId = v.friendId
                    temp.sendPlayerName = v.friendName

                    if v.voiceId and v.voiceId ~= '' then
                        temp.messagetype = CHAT_MSG_TYPE.SOUND
                        temp.fileid = v.voiceId
                        temp.time = v.time
                    end
                    if checkint(v.friendId) == checkint(app.gameMgr:GetPlayerId()) then
                        temp.name = temp.receivePlayerName
                        temp.playerId = temp.receivePlayerId
                    else
                        temp.name = temp.sendPlayerName
                        temp.playerId = temp.sendPlayerId
                    end
                    self:InsertPrivateItem(temp, true)
                    if checkint(self.privateSelectedId) == checkint(v.friendId) then
                        local parsedtable = labelparser.parse(v.message)
                        local tempTab = {}
                        --过滤非法标签
                        for i,v in ipairs(parsedtable) do
                            if FILTERS[v.labelname] then
                                tempTab[v.labelname] = v.content
                            end
                        end
                        local messageDatas = {
                            message = v.message or '<desc>....</desc>' ,
                            sender = v.sender or MSG_TYPES.MSG_TYPE_OTHER,
                            name = v.friendName ,
                            sendTime = v.sendTime or os.time() ,
                            messagetype = tempTab['messagetype'],
                            fileid = tempTab['fileid'],
                            playerId = v.playerId
                        }
                        -- 添加头像
                        if checkint(messageDatas.sender) == MSG_TYPES.MSG_TYPE_SELF then
                            messageDatas.avatar = app.gameMgr:GetUserInfo().avatar
                            messageDatas.avatarFrame = app.gameMgr:GetUserInfo().avatarFrame
                        elseif checkint(messageDatas.sender) == MSG_TYPES.MSG_TYPE_OTHER then
                            for i, datas in ipairs(self.playerInfo) do
                                if checkint(datas.friendId) == checkint(v.friendId) then
                                    messageDatas.avatar = datas.avatar
                                    messageDatas.avatarFrame = datas.avatarFrame
                                    break
                                end
                            end
                        end
                        self:InsertPrivateMessageItem(messageDatas)
                    end
                else
                    local mediator = AppFacade.GetInstance():RetrieveMediator("AppMediator")
                    mediator:SendSignal(COMMANDS.COMMAND_Chat_GetPlayInfo, {playerIdList = tostring(v.friendId), type = PlayerInfoType.CHAT_ONE})
                end
            end
        end
    end
    self:RefreshRemindIconStatus(CHAT_CHANNELS.CHANNEL_PRIVATE)
end
--[[
--更新列表视图
--]]
function ChatView:UpdateListView()
    local viewData = self.viewData
    if viewData.checkBoxs[tostring(self.curChannel)] then
        viewData.checkBoxs[tostring(self.curChannel)]:setChecked(true)
    end
    local chatListView = viewData.chatListView
    chatListView:removeAllNodes()
    chatListView:reloadData()
    -- self.viewData.topView:setVisible(false)
    -- self.viewData.tipsLabel:setVisible(false)
    -- self.viewData.unReadBtn:setVisible(false)
    self.privateSelectedId = nil
    -- if tag == CHATCHANNEL.WORLD then--世界聊天频道

    -- elseif tag == CHATCHANNEL.GUILD then--公会聊天频道
    --     if app.gameMgr:IsJoinUnion() then

    --     else
    --         self.viewData.topView:setVisible(true)
    --         self.viewData.tipsLabel:setVisible(true)
    --         self.viewData.tipsLabel:setString(__('还未加入公会'))
    --     end
    -- elseif tag == CHATCHANNEL.PRIVATE then--私聊聊天频道
    --     self.viewData.topView:setVisible(true)
    --     self.viewData.tipsLabel:setVisible(true)
    --     self.viewData.tipsLabel:setString(__('以下是其他玩家给你的信息，选中对应信息，可即时回复'))
    -- elseif tag == CHATCHANNEL.SYSTEM then--系统聊天频道
    --     self.viewData.topView:setVisible(true)
    --     self.viewData.tipsLabel:setVisible(true)
    --     self.viewData.tipsLabel:setString(__('该频道下不能发言'))
    -- elseif tag == CHATCHANNEL.TEAM then--组队聊天频道
    --     self.viewData.topView:setVisible(true)
    --     self.viewData.tipsLabel:setVisible(true)
    --     self.viewData.tipsLabel:setString(__('还未加入队伍'))
    -- end
    --更新数据列表
    --[[
    local testDatas = {
        {channel = 1, message = '<desc>这个是虽顶起是顶起国夺是顶起</desc><messagetype>1</messagetype><fileid>nil</fileid>', messagetype = 1,name = '红光光', playerId = 84972, sendTime = 1510639173, sender = 1},
        {channel = 1, message = '<desc>这个是虽顶起是顶起国夺是顶起</desc><messagetype>1</messagetype><fileid>nil</fileid>', messagetype = 1,name = '天下才子', playerId = 84972, sendTime = 1510639176, sender = 0},
        {channel = 1, message = '<desc>这个是虽顶起是顶起国夺是顶起</desc><messagetype>1</messagetype><fileid>nil</fileid>', messagetype = 1,name = '红光光', playerId = 84972, sendTime = 1510639173, sender = 1},
        {channel = 1, message = '<desc>这个是虽顶起是顶起国夺是顶起</desc><messagetype>1</messagetype><fileid>nil</fileid>', messagetype = 1,name = '天下才子', playerId = 84972, sendTime = 1510639176, sender = 0},
        {channel = 1, message = '<desc></desc><messagetype>2</messagetype><fileid>323298</fileid>', messagetype = 2,name = '天下才子', playerId = 84972, sendTime = 1510639276, sender = 0},
        {channel = 1, message = '<desc></desc><messagetype>2</messagetype><fileid>323298</fileid>', messagetype = 2,name = '天下才子', playerId = 84972, sendTime = 1510639276, sender = 1},
        {channel = 1, message = '<guild id=12 32 >【hello,world】</guild><desc>发布了招募信息，寻找志同道合的御侍，共同守护世界，抗击堕神！</desc><look>【点击查看】</look>',messagetype = 1,name = '天下才子', playerId = 84972, sendTime = 1510639276, sender = 1},
    }
    --]]
    local bgSize = viewData.bgSize
    if self.curChannel == CHAT_CHANNELS.CHANNEL_WORLD then
        self.viewData.chatListView:setContentSize(cc.size(self.viewData.bgSize.width - 110, display.height - 128))
        local datas = app.chatMgr:GetWorldMessage()
        for name,val in pairs(datas) do
            self:InsertNewItem(val)
        end
        chatListView:setContentOffsetToBottom()
    elseif self.curChannel == CHAT_CHANNELS.CHANNEL_UNION then -- 工会
        self.viewData.chatListView:setContentSize(cc.size(self.viewData.bgSize.width - 110, display.height - 92))
        local datas = app.chatMgr:GetMessageByChannel(CHAT_CHANNELS.CHANNEL_UNION)
        if nil ~= datas then
            for name, val in pairs(datas) do
                self:InsertNewItem(val)
            end
        end
        self.viewData.chatListView:setContentOffsetToBottom()
    elseif self.curChannel == CHAT_CHANNELS.CHANNEL_HOUSE then -- 猫屋
        self.viewData.chatListView:setContentSize(cc.size(self.viewData.bgSize.width - 110, display.height - 92))
        local datas = app.chatMgr:GetMessageByChannel(CHAT_CHANNELS.CHANNEL_HOUSE)
        if nil ~= datas then
            for name, val in pairs(datas) do
                self:InsertNewItem(val)
            end
        end
        chatListView:setContentOffsetToBottom()
    elseif self.curChannel == CHAT_CHANNELS.CHANNEL_TEAM then -- 组队
        self.viewData.chatListView:setContentSize(cc.size(self.viewData.bgSize.width - 110, display.height - 92))
        local datas = app.chatMgr:GetMessageByChannel(CHAT_CHANNELS.CHANNEL_TEAM)
        if nil ~= datas then
            for name, val in pairs(datas) do
                self:InsertNewItem(val)
            end
        end
        chatListView:setContentOffsetToBottom()
    elseif self.curChannel == CHAT_CHANNELS.CHANNEL_PRIVATE then -- 私聊
        chatListView:setContentSize(cc.size(bgSize.width - 110, display.height - 12))
        -- 获取玩家基本信息
        local mediator = AppFacade.GetInstance():RetrieveMediator("AppMediator")
        local str = self:GetPrivateEmptyPlayerId()
        if str and str ~= "" then -- 需要获取玩家信息
            mediator:SendSignal(COMMANDS.COMMAND_Chat_GetPlayInfo, {playerIdList = str, type = PlayerInfoType.CHAT_ALL})
        elseif str == '' then -- 不需要获取玩家信息
            self:AddAllPrivateItem()
        end
    elseif self.curChannel == CHAT_CHANNELS.CHANNEL_SYSTEM then -- 系统
        chatListView:setContentSize(cc.size(bgSize.width - 110, display.height - 12))
        -- local t = {channel = 1, message = '<activity id=2 >【hello,world】</activity><desc>发布了招募信息，寻找志同道合的御侍，共同守护世界，抗击堕神！</desc><look>【点击查看】</look>',messagetype = 1,name = '天下才子', playerId = 84972, sendTime = 1510639276, sender = 1}
        -- self:InsertNewItem(t)
        -- self.viewData.chatListView:setContentOffsetToBottom()
    elseif self.curChannel == CHAT_CHANNELS.CHANNEL_HELP then -- 帮助
        chatListView:setContentSize(cc.size(bgSize.width - 110, display.height - 12))
        local mediator = AppFacade.GetInstance():RetrieveMediator("AppMediator")
        local str = self:GetHelpEmptyPlayerId()
        if str and str ~= "" then
            mediator:SendSignal(COMMANDS.COMMAND_Chat_GetPlayInfo, {playerIdList = str, type = PlayerInfoType.HELP_ALL})
        elseif str == '' then
            self:InitHelpDatas()
        end
    end
end

--[[
--tab切换的逻辑处理
--]]
function ChatView:TabButtonAction(sender)
    PlayAudioByClickNormal()

    local channelId = sender:getTag()
    self:RefreshUIByChannelId(checkint(channelId))
end
--[[
根据channelId刷新聊天界面
@params channelId int 频道id
--]]
function ChatView:RefreshUIByChannelId(channelId, force)
    if self.viewData.checkBoxs[tostring(self.curChannel)] then
        self.viewData.checkBoxs[tostring(self.curChannel)]:setChecked(false)
    end

    if nil ~= self.viewData.checkBoxs[tostring(channelId)] then
        self.viewData.checkBoxs[tostring(channelId)]:setChecked(true)
    end

    self:RemoveChatPrivateMessageView()
    self.privateSelectedId = nil

    if checkint(channelId) == checkint(self.curChannel) then
        return
    else
        self.curChannel = channelId
    end

    if channelId == CHAT_CHANNELS.CHANNEL_WORLD then
        self.viewData.switchChatRoomLayout:setVisible(true)
        self.viewData.unReadBtn:setVisible(false)
        self.viewData.chatInputView:setVisible(true)
        self.viewData.chatInputView:SetActiveState(true)
        self.viewData.chatInputView:SetChatChannel(channelId)
        self.viewData.chatInputView:RegistWorldTouchAction()
        self.viewData.chatListView:setPosition(cc.p(108, display.height - 46))
    elseif channelId == CHAT_CHANNELS.CHANNEL_TEAM then
        self.viewData.switchChatRoomLayout:setVisible(false)
        self.viewData.unReadBtn:setVisible(false)
        self.viewData.chatInputView:setVisible(true)
        self.viewData.chatInputView:SetActiveState(true)
        self.viewData.chatInputView:SetChatChannel(channelId)
        self.viewData.chatInputView:RegistWorldTouchAction()
        self.viewData.chatListView:setPosition(cc.p(108, display.height - 5))
    elseif channelId == CHAT_CHANNELS.CHANNEL_UNION then
        self.viewData.switchChatRoomLayout:setVisible(false)
        self.viewData.chatInputView:setVisible(true)
        self.viewData.chatInputView:SetActiveState(true)
        self.viewData.chatInputView:SetChatChannel(channelId)
        self.viewData.chatListView:setPosition(cc.p(108, display.height - 5))
    elseif channelId == CHAT_CHANNELS.CHANNEL_HOUSE then
        self.viewData.switchChatRoomLayout:setVisible(false)
        self.viewData.chatInputView:setVisible(true)
        self.viewData.chatInputView:SetActiveState(true)
        self.viewData.chatInputView:SetChatChannel(channelId)
        self.viewData.chatListView:setPosition(cc.p(108, display.height - 5))
    else
        self.viewData.switchChatRoomLayout:setVisible(false)
        self.viewData.chatInputView:setVisible(false)
        self.viewData.chatInputView:SetActiveState(false)
        self.viewData.chatListView:setPosition(cc.p(108, display.height - 5))
    end

    self:UpdateListView()
end
--[[
初始化帮助数据
--]]
function ChatView:InitHelpDatas()
    -- 帮助
    local helpDatas = ChatUtils.GetChatHelpDatas()
    table.sort(helpDatas, function (a, b)
        return checkint(a.helpTime) < checkint(b.helpTime)
    end)
    for i,v in ipairs(helpDatas) do
        self:InsertHelpItem(v)
    end
end
--[[
插入帮助item
@params datas {
    playerId int 玩家Id,
    helpType int 帮助类型,
    helpTime int 帮助时间,
    goodsId int 道具Id
}
--]]
function ChatView:InsertHelpItem( helpDatas )
    if checkint(helpDatas.playerId) == checkint(app.gameMgr:GetPlayerId()) then return end
    if helpDatas.helpType == HELP_TYPES.FRIEND_DONATION and checkint(helpDatas.expirationTime) <= os.time() then return end
    -- 移除已有的同类型帮助信息
    local chatListView = self.viewData.chatListView
    local nodes = chatListView:getNodes()
    for i,v in ipairs(nodes) do
        if checkint(v.helpDatas.playerId) == checkint(helpDatas.playerId) and checkint(v.helpDatas.helpType) == checkint(helpDatas.helpType) then
            chatListView:removeNodeAtIndex(i - 1)
            break
        end
    end
    local playerDatas = nil
    for i,v in ipairs(self.playerInfo) do
        if checkint(v.friendId) == checkint(helpDatas.playerId) then
            playerDatas = v
            break
        end
    end

    local index = self.viewData.chatListView:getNodeCount()
    if index >= MAX_SHOW_MSG then
        self.viewData.chatListView:removeNodeAtIndex(0)
    end
    if playerDatas then
        --防止playerDatas不为空
        local view = require( 'Game.views.chat.ChatHelpMessageView' ).new({helpDatas = helpDatas, playerDatas = playerDatas})
        self:ChestListInsertView(view)
        chatListView:setContentOffsetToBottom()
    end
end

function ChatView:ChestListInsertView(view , isLast)
    isLast = isLast == nil and true or false
    local chatListView = self.viewData.chatListView
    if isLast then
        chatListView:insertNodeAtLast(view)
    else
        chatListView:insertNodeAtFront(view)
    end
    chatListView:reloadData()
end
--[[
收到新的帮助请求
--]]
function ChatView:ReceiveHelpRequest( helpDatas )
    if checkint(self.curChannel) == CHAT_CHANNELS.CHANNEL_HELP then
        if self:HasPlayerInfo(helpDatas.playerId) then
            self:InsertHelpItem(helpDatas)
        else
            local mediator = AppFacade.GetInstance():RetrieveMediator("AppMediator")
            mediator:SendSignal(COMMANDS.COMMAND_Chat_GetPlayInfo, {playerIdList = tostring(helpDatas.playerId), type = PlayerInfoType.HELP_ONE})
        end
    end
end
--[[
帮助清除回调
@params datas{
    playerId int 玩家id，
    helpType int 帮助类型
}
--]]
--
function ChatView:HelpClearCallback( datas )
    if self.curChannel == CHAT_CHANNELS.CHANNEL_HELP then
        local chatListView = self.viewData.chatListView
        local nodes = chatListView:getNodes()
        for i,v in ipairs(nodes) do
            -- print(v.helpDatas.playerId, datas.playerId, v.helpDatas.helpType, datas.helpType)
            if checkint(v.helpDatas.playerId) == checkint(datas.playerId) and checkint(v.helpDatas.helpType) == checkint(datas.helpType) then
                chatListView:removeNodeAtIndex(i -1)
                chatListView:reloadData()
                break
            end
        end
    end
end
--[[
获取最近联系人中没有玩家信息的id
--]]
function ChatView:GetPrivateEmptyPlayerId()
    local recentContactsId = ChatUtils.GetRecentContactsId()
    if next(self.playerInfo) ~= nil then
        local idLabel = string.split(recentContactsId, ',')
        local emptyLabel = {}
        for _, id in ipairs(idLabel) do
            for i,v in ipairs(self.playerInfo) do
                if checkint(id) == checkint(v.friendId) then
                    break
                end
                if i == #self.playerInfo then
                    table.insert(emptyLabel, id)
                end
            end
        end
        local idStr = nil
        for i,v in ipairs(emptyLabel) do
            if idStr == nil then
                idStr = tostring(v)
            else
                idStr = idStr .. ',' .. tostring(v)
            end
        end
        if idStr then
            return idStr
        else
            return ''
        end
    else
        return recentContactsId
    end
end
--[[
获取帮助列表中没有玩家信息的id
--]]
function ChatView:GetHelpEmptyPlayerId()
    local helpListPlayerId = ChatUtils.GetHelpListPlayerId()
    if next(self.playerInfo) ~= nil then
        local idLabel = string.split(helpListPlayerId, ',')
        local emptyLabel = {}
        for _, id in ipairs(idLabel) do
            for i,v in ipairs(self.playerInfo) do
                if checkint(id) == checkint(v.friendId) then
                    break
                end
                if i == #self.playerInfo then
                    table.insert(emptyLabel, id)
                end
            end
        end
        local idStr = nil
        for i,v in ipairs(emptyLabel) do
            if idStr == nil then
                idStr = tostring(v)
            else
                idStr = idStr .. ',' .. tostring(v)
            end
        end
        if idStr then
            return idStr
        else
            return ''
        end
    else
        return helpListPlayerId
    end
end
--[[
添加全部的私聊联系人
--]]
function ChatView:AddAllPrivateItem()
    local recentContactsId = ChatUtils.GetRecentContactsId()
    if recentContactsId then
        local idLabel = string.split(recentContactsId, ',')
        for i, v in ipairs(idLabel) do
            self:GetLastMessage(v)
        end
    end
end
--[[
获取玩家信息回调
--]]
function ChatView:GetPlayerInfoCallback( datas )
    for i,v in ipairs(datas.playerList) do
        table.insert(self.playerInfo, v)
    end
    if checkint(datas.requestData.type) == PlayerInfoType.CHAT_ALL then
        self:AddAllPrivateItem()
    elseif checkint(datas.requestData.type) == PlayerInfoType.CHAT_ONE then
        self:GetLastMessage(checktable(checktable(datas.playerList)[1]).friendId)
    elseif checkint(datas.requestData.type) == PlayerInfoType.HELP_ALL then
        self:InitHelpDatas()
    elseif checkint(datas.requestData.type) == PlayerInfoType.HELP_ONE then
        local allHelpDatas = ChatUtils.GetChatHelpDatas()
        local temp = nil
        for i = #allHelpDatas, 1, -1 do
            if checkint(allHelpDatas[i].playerId) == checkint(datas.playerList[1].friendId) then
                temp = allHelpDatas[i]
                break
            end
        end
        if temp then
            self:InsertHelpItem(temp)
        end
    end
end
--[[
更新帮助列表
--]]
function ChatView:UpdateHelpList()
    if checkint(self.curChannel) == CHAT_CHANNELS.CHANNEL_HELP then
        local chatListView = self.viewData.chatListView
        local nodes = chatListView:getNodes()
        for i,v in ipairs(nodes) do
            if v.helpDatas.helpType == HELP_TYPES.FRIEND_DONATION then
                v:RefreshSelf()
            end
        end
    end
end
--[[
清空列表
--]]
function ChatView:CleanChatListView()
    self.viewData.chatListView:removeAllNodes()
    self.viewData.chatListView:reloadData()
end
--[[
更新左侧页签按钮状态(小红点)
--]]
function ChatView:RefreshLeftBtnView()
    for i, v in ipairs(channelConf) do
        self:RefreshRemindIconStatus(v.tag)
    end
end
--[[
更新按钮红点状态
@params tag int 频道
--]]
function ChatView:RefreshRemindIconStatus( tag )
    if checkint(tag) == CHAT_CHANNELS.CHANNEL_PRIVATE then
        local recentContactsId = ChatUtils.GetRecentContactsId()
        local idLabel = string.split(recentContactsId, ',')
        local hasNewMsg = false
        for i,v in ipairs(checktable(idLabel)) do
            if checkint(ChatUtils.GetNewMessageByPlayerId(checkint(v)).hasNewMessage) == 1 then
                hasNewMsg = true
                break
            end
        end
        if self.viewData.checkBoxs[tostring(tag)] then
            if hasNewMsg then
                self.viewData.checkBoxs[tostring(tag)]:getChildByName('remindIcon'):setVisible(true)
            else
                self.viewData.checkBoxs[tostring(tag)]:getChildByName('remindIcon'):setVisible(false)
            end
        end
        self:RefreshFriendRemindIcon()

    elseif checkint(tag) == CHAT_CHANNELS.CHANNEL_HELP then
        -- TODO 其他红点？  
    end
end
function ChatView:GoogleBack()
    local  NumKeyboardMediator = app:RetrieveMediator("NumKeyboardMediator")
    if NumKeyboardMediator then
        NumKeyboardMediator:GoogleBack()
        return false
    end
    local PlayerHeadPopup = app.uiMgr:GetCurrentScene():GetDialogByName('common.PlayerHeadPopup')
    if PlayerHeadPopup then
        PlayerHeadPopup:GoogleBack()
        return false
    end
    local mediator = app:RetrieveMediator("PersonInformationMediator")
    if mediator then
        mediator:GoogleBack()
        return false
    end
    return true
end
--[[
刷新好友系统红点
--]]
function ChatView:RefreshFriendRemindIcon()
    if ChatUtils.HasUnreadMessage() or checkint(app.dataMgr:GetRedDotNofication(tostring(RemindTag.NEW_FRIENDS), RemindTag.NEW_FRIENDS)) ~= 0 then
        app.dataMgr:AddRedDotNofication(tostring(RemindTag.FRIENDS), RemindTag.FRIENDS, "[好友]ChatView:RefreshFriendRemindIcon")
    else
        app.dataMgr:ClearRedDotNofication(tostring(RemindTag.FRIENDS), RemindTag.FRIENDS, "[好友]ChatView:RefreshFriendRemindIcon")
    end
    AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.FRIENDS})
end
function ChatView:onCleanup()
    sceneWorld:setMultiTouchEnabled(false)
    AppFacade.GetInstance():UnRegistObserver('VOICE_EVENT', self)
    app.audioMgr:ResumeBGMusic()
end

return ChatView
