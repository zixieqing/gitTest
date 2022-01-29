--[[
--聊天的输入框的逻辑
--]]
local ChatInputView = class('ChatInputView', function ()
	local node = CLayout:create()
	node.name = 'Game.views.chat.ChatInputView'
	-- node:setBackgroundColor(cc.c4b(0,100,0,100))
	node:enableNodeEvents()
	return node
end)

local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
local uiMgr = AppFacade.GetInstance('AppFacade'):GetManager("UIManager")

local socketMgr = AppFacade.GetInstance():GetManager('ChatSocketManager')

local voiceChatMgr = AppFacade.GetInstance():GetManager("GlobalVoiceManager")
local voiceEngine = voiceChatMgr:GetVoiceNode()

function ChatInputView:ctor( ... )
	local datas = checktable(unpack({...}))
    self.isMoving = false
    self.activeState = true
	local inputType = CHAT_CHANNELS.CHANNEL_WORLD
	if datas.inputType then
		inputType = datas.inputType
	end
	local size = cc.size(608, 80)
	local sendBoxSize = cc.size(330, 40)
	local voiceBtnSize = cc.size(400,46)
	if inputType == CHAT_CHANNELS.CHANNEL_WORLD then
		size = cc.size(608, 80)
		sendBoxSize = cc.size(330, 40)
		voiceBtnSize = cc.size(400,46)
	elseif inputType == CHAT_CHANNELS.CHANNEL_PRIVATE then
		self.playerId = datas.playerId
		self.playerName = datas.playerName
		size = cc.size(504, 80)
		sendBoxSize = cc.size(250, 40)
		voiceBtnSize = cc.size(380,46)
	end
	self:setContentSize(size)
    self.isVoiceChat = false
	self.viewData = nil
	self.channel = inputType
	local function CreateView()
		local chatBg = display.newImageView(_res('ui/home/chatSystem/dialogue_channel_bg_input'),0,0,{
			scale9 = true, size = size, ap = display.LEFT_BOTTOM
		})
		self:addChild(chatBg)
		local sendVoiceBtn = display.newButton(0, 0,
            {n = _res('ui/home/chatSystem/dialogue_btn_voice.png')})--, animate = true, cb = handler(self, self.breakBtnCallback)
	    display.commonUIParams(sendVoiceBtn, {ap = cc.p(0,0.5),po = cc.p( 20, size.height * 0.5)})--
	    self:addChild(sendVoiceBtn)
        if isElexSdk() then
            sendVoiceBtn:setVisible(false)
        end
        sendVoiceBtn:setTag(200)
        sendVoiceBtn:setOnClickScriptHandler(handler(self, self.OnButtonAction))

        -- view:addChild(sendVoiceBtn)

		local voicePressButton = display.newButton(110, size.height * 0.5,{
			n = _res('ui/home/chatSystem/common_bg_input_default'),
			s = _res('ui/common/common_bg_voice_pressed'),
			scale9 = true, size = voiceBtnSize, ap = display.LEFT_CENTER
		})
		display.commonLabelParams(voicePressButton, fontWithColor(5,{color = 'ba5c5c',text = __('按住 说话')}))
		self:addChild(voicePressButton, 4)
		voicePressButton:setVisible(false)
        voicePressButton:setOnLongClickScriptHandler(handler(self, self.LongEventAction))
        -- voicePressButton:setTag(00)
        -- voicePressButton:setOnClickScriptHandler(handler(self, self.OnButtonAction))


        local sendBox = ccui.EditBox:create(sendBoxSize, _res('ui/home/chatSystem/dialogue_bg_text.png'))
		display.commonUIParams(sendBox, {po = cc.p(100, size.height * 0.5),ap = cc.p(0,0.5)})
		self:addChild(sendBox)
		sendBox:setFontSize(26)
		sendBox:setFontColor(ccc3FromInt('#4c4c4c'))
		sendBox:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)--EDITBOX_INPUT_MODE_NUMERIC
		sendBox:setPlaceHolder(__('请输入内容'))
		sendBox:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)
		sendBox:setMaxLength(100)


        -- local sendImgBtn = display.newButton(0, 0,
        --  	{n = _res('ui/home/chatSystem/dialogue_btn_face.png')})--, animate = true, cb = handler(self, self.breakBtnCallback)
        --  display.commonUIParams(sendImgBtn, {ap = cc.p(0,0.5),po = cc.p(sendBox:getContentSize().width+ 90, topBg:getContentSize().height * 0.5)})
        --  topView:addChild(sendImgBtn)


        local sendBtn = display.newButton(0, 0,
            {n = _res('ui/common/common_btn_orange'), d = _res('ui/common/common_btn_orange_disable.png')})
	    display.commonUIParams(sendBtn, {ap = cc.p(1,0.5),po = cc.p(size.width - 20, size.height * 0.5)})
        display.commonLabelParams(sendBtn, fontWithColor(14,{text = __('发送')}))
        self:addChild(sendBtn)
        sendBtn:setTag(300)
        -- sendBtn:setEnabled(not CommonUtils.CheckIsDisableInputDay(false))
        sendBtn:setOnClickScriptHandler(handler(self, self.OnButtonAction))
        return {
            sendVoiceBtn = sendVoiceBtn,
            voicePressButton = voicePressButton,
            sendBox = sendBox,
			sendBtn = sendBtn,
        }
	end

	self.viewData = CreateView()

    AppFacade.GetInstance():RegistObserver('VOICE_EVENT', mvc.Observer.new(function(stage, signal)
        local name = signal:GetName()
        if name == 'VOICE_EVENT' and self.activeState then
            local body = signal:GetBody()
            local name = body.name
            local code = checkint(body.code)
--[[             if name == StateType.State_ApplyMessage then ]]
                -- --appkey成功的逻辑
                -- if code == 7 then
                    -- app.audioMgr:PauseBGMusic()
                    -- local recordFile = AUDIO_RECORD_PATH
                    -- if utils.isExistent(recordFile) then
                        -- FTUtils:deleteFile(recordFile)
                    -- end
                    -- voiceEngine:StartRecording(recordFile)
                -- else
                    -- local uiMgr = AppFacade.GetInstance():GetManager('UIManager')
                    -- uiMgr:ShowInformationTips(__('应用key失败'))
                --[[ end ]]
            if name == StateType.State_Upload then
                --上传
                if code == 11 or (code == 12293 and device.platform == "android") then
                    --上传成功后的逻辑
                    if self.channel == CHAT_CHANNELS.CHANNEL_WORLD or self.channel == CHAT_CHANNELS.CHANNEL_UNION or self.channel == CHAT_CHANNELS.CHANNEL_HOUSE then
                        local chatDatas = {}
                        chatDatas.name = gameMgr:GetUserInfo().playerName
                        chatDatas.avatar = gameMgr:GetUserInfo().avatar
                        chatDatas.avatarFrame = gameMgr:GetUserInfo().avatarFrame
                        chatDatas.message = string.format('<fileid>%s</fileid><messagetype>2</messagetype>', body.fileID)
                        chatDatas.sendTime = getServerTime()
                        chatDatas.sender = MSG_TYPES.MSG_TYPE_SELF
                        chatDatas.messagetype = CHAT_MSG_TYPE.SOUND
                        chatDatas.fileid = body.fileID
                        local recordFile = AUDIO_RECORD_PATH
                        chatDatas.time = voiceEngine and voiceEngine:GetVoiceLength(recordFile) or 0
                        chatDatas.playerId = gameMgr:GetUserInfo().playerId
                        chatDatas.channel = self.channel
                        socketMgr:SendPacket( NetCmd.RequestChatroomSendMessage, {time = chatDatas.time, channel = self.channel,message = chatDatas.message, avatarFrame = chatDatas.avatarFrame})
                        socketMgr:InsertMessageVo(chatDatas)
                        AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.Chat_GetMessage_Callback,chatDatas)
                    elseif self.channel == CHAT_CHANNELS.CHANNEL_PRIVATE then
                        local chatDatas = {}
                        chatDatas.message = string.format('<fileid>%s</fileid><messagetype>2</messagetype>', body.fileID)
                        chatDatas.sendTime = getServerTime()
                        chatDatas.sender = MSG_TYPES.MSG_TYPE_SELF
                        chatDatas.messagetype = CHAT_MSG_TYPE.SOUND
                        chatDatas.fileid = body.fileID
                        local recordFile = AUDIO_RECORD_PATH
                        chatDatas.time = voiceEngine and voiceEngine:GetVoiceLength(recordFile) or 0
                        chatDatas.friendId = self.playerId
                        chatDatas.channel = self.channel
                        chatDatas.friendName = self.playerName
                        socketMgr:SendPacket( NetCmd.RequestPrivateSendMessage, {friendId = self.playerId, message = chatDatas.message})
                        socketMgr:InsertMessageVo(chatDatas)
                        AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.Chat_GetMessage_Callback,chatDatas)
                    end
                end
            end
        end
    end, self))
    AppFacade.GetInstance():RegistObserver(FRIEND_REFRESH_EDITBOX, mvc.Observer.new(function ( stage, signal )
        local data = checktable(signal:GetBody())
        if data.tag == DISABLE_EDITBOX_MEDIATOR.CHAT_INPUT_TAG then
            if data.isEnabled then
                self.viewData.sendBox:setVisible(true)
            else
                self.viewData.sendBox:setVisible(false)
            end
        end
    end, self))
end

function ChatInputView:SetChatChannel( channel )
	self.channel = checkint(channel)
end

function ChatInputView:OnButtonAction( sender )
	PlayAudioByClickNormal()
    local tag = sender:getTag()
    if tag == 200 then
        if self.isVoiceChat then
            self.viewData.sendVoiceBtn:setNormalImage(_res('ui/home/chatSystem/dialogue_btn_voice'))
            self.viewData.sendVoiceBtn:setSelectedImage(_res('ui/home/chatSystem/dialogue_btn_voice'))
            self.viewData.voicePressButton:setVisible(false)
            self.viewData.sendBtn:setVisible(true)
            self.viewData.sendBox:setVisible(true)
            self.isVoiceChat = false
        else
            self.viewData.sendVoiceBtn:setNormalImage(_res('ui/home/chatSystem/dialogue_btn_keyboard'))
            self.viewData.sendVoiceBtn:setSelectedImage(_res('ui/home/chatSystem/dialogue_btn_keyboard'))
            self.viewData.voicePressButton:setVisible(true)
            self.viewData.sendBtn:setVisible(false)
            self.viewData.sendBox:setVisible(false)
            self.isVoiceChat = true
        end
    elseif tag == 300 then
        --发送的逻辑
        local text = self.viewData.sendBox:getText()
        if text == 'system call, show log' then
            if showLogView then showLogView() end
            self.viewData.sendBox:setText('')
            return
        end
        if (self.channel == CHAT_CHANNELS.CHANNEL_WORLD or self.channel == CHAT_CHANNELS.CHANNEL_TEAM) then
            if not CommonUtils.UnLockModule(991, true) then
                return
            end
        end
        if CommonUtils.CheckIsDisableInputDay() then
            return
        end
        local chatDatas = {}
        if text and string.len( text ) > 0 then
            text = string.trim(text)
            chatDatas.name = gameMgr:GetUserInfo().playerName
            chatDatas.message = string.format('<desc>%s</desc><messagetype>1</messagetype><fileid>nil</fileid>', text)
            chatDatas.fileid = nil
            chatDatas.sendTime = getServerTime()
            chatDatas.sender = MSG_TYPES.MSG_TYPE_SELF
            chatDatas.messagetype = CHAT_MSG_TYPE.TEXT
            chatDatas.channel = self.channel
            chatDatas.playerId = gameMgr:GetUserInfo().playerId
            chatDatas.avatar = gameMgr:GetUserInfo().avatar
            chatDatas.avatarFrame = gameMgr:GetUserInfo().avatarFrame
            self.viewData.sendBox:setText('')
            if self.channel == CHAT_CHANNELS.CHANNEL_WORLD then
                socketMgr:SendPacket(NetCmd.RequestChatroomSendMessage, {channel = self.channel, message = chatDatas.message, avatarFrame = chatDatas.avatarFrame})
            elseif CHAT_CHANNELS.CHANNEL_TEAM == self.channel then

                -- 判断是否加入了组队
                if 0 == checkint(socketMgr:GetJoinedChannelRoomId(CHAT_CHANNELS.CHANNEL_TEAM)) then
                    -- 未加入组队 无法发言
                    uiMgr:ShowInformationTips(__('还未加入组队!!!'))
                    return
                end
                socketMgr:SendPacket(NetCmd.RequestChatroomSendMessage, {channel = self.channel, message = chatDatas.message, avatarFrame = chatDatas.avatarFrame})
            elseif CHAT_CHANNELS.CHANNEL_UNION == self.channel then
                -- 判断是否加入了工会
                if gameMgr:IsJoinUnion() then
                    socketMgr:SendPacket(NetCmd.RequestChatroomSendMessage, {channel = self.channel, message = chatDatas.message, avatarFrame = chatDatas.avatarFrame})
                else
                    -- 未加入工会无法发言
                    uiMgr:ShowInformationTips(__('还未加入工会'))
                    return
                end
            elseif CHAT_CHANNELS.CHANNEL_HOUSE == self.channel then
                if app.catHouseMgr:hasUnlockHouse() then
                    socketMgr:SendPacket(NetCmd.RequestChatroomSendMessage, {channel = self.channel, message = chatDatas.message, avatarFrame = chatDatas.avatarFrame})
                else
                    uiMgr:ShowInformationTips(__('还未解锁该功能'))
                    return
                end
            
            elseif self.channel == CHAT_CHANNELS.CHANNEL_PRIVATE then
                chatDatas.friendName = self.playerName
                chatDatas.friendId   = self.playerId
                socketMgr:SendPacket( NetCmd.RequestPrivateSendMessage, {friendId = self.playerId, message = chatDatas.message})
            end
            socketMgr:InsertMessageVo(chatDatas)
            AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.Chat_GetMessage_Callback,chatDatas)
        end
    end
end

function ChatInputView:RegistWorldTouchAction()
    sceneWorld:setOnTouchEndedAfterLongClickScriptHandler(handler(self, self.LongClickEndHandler))
    sceneWorld:setOnTouchCancelledAfterLongClickScriptHandler(handler(self, self.LongClickCancelledHandler))
    sceneWorld:setOnTouchMovedAfterLongClickScriptHandler(function(sender, touch, duration)
        local y = touch:getLocation().y
        if y > 200 then
            self.isMoving = true
        else
            self.isMoving = false
        end
    end)
end
--
--[[
--输入框的长按的逻辑
---]]
function ChatInputView:LongEventAction( sender, touch )
    -- 非聊天模式直接返回
    if voiceEngine and VoiceType.Messages ~= voiceChatMgr:GetMode() then
        uiMgr:ShowInformationTips(__('您当前处于实时语音，无法使用其他语音功能。'))
        return false
    end

    if not GAME_MODULE_OPEN.GVOICE_SERVER then
		app.uiMgr:ShowInformationTips(__('该功能暂不可用'))
		return false
	end

    -- 改变按钮状态
    self.viewData.voicePressButton:setNormalImage(_res('ui/common/common_bg_voice_pressed'))
    self.viewData.voicePressButton:setSelectedImage(_res('ui/common/common_bg_voice_pressed'))

    local chatAnimate = sceneWorld:getChildByName('ChatAnimate')
    if not chatAnimate then
        xTry(function()
            chatAnimate = require('Game.views.chat.ChatAnimate').new()
            chatAnimate:setName('ChatAnimate')
            display.commonUIParams(chatAnimate, {po = cc.p(display.width * 0.61, display.cy)})
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
                    -- 改变按钮状态
                    self.viewData.voicePressButton:setNormalImage(_res('ui/common/common_bg_voice_pressed'))
                    self.viewData.voicePressButton:setSelectedImage(_res('ui/common/common_bg_voice_pressed'))
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

function ChatInputView:LongClickEndHandler( sender, touch, duration )
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
    -- 改变按钮状态
    self.viewData.voicePressButton:setNormalImage(_res('ui/home/chatSystem/common_bg_input_default'))
    self.viewData.voicePressButton:setSelectedImage(_res('ui/common/common_bg_voice_pressed'))
    self.isMoving = false
end
function ChatInputView:LongClickCancelledHandler( sender, touch, duration )
    app.audioMgr:ResumeBGMusic()
    local chatAnimate = sceneWorld:getChildByName('ChatAnimate')
    if chatAnimate then chatAnimate:removeFromParent() end
    -- 改变按钮状态
    if self.viewData then
        self.viewData.voicePressButton:setNormalImage(_res('ui/home/chatSystem/common_bg_input_default'))
        self.viewData.voicePressButton:setSelectedImage(_res('ui/common/common_bg_voice_pressed'))
    end
    self.isMoving = false
end
function ChatInputView:SetActiveState( state )
    if state ~= nil then
        self.activeState = state
    end
end

function ChatInputView:onEnter()
    self:RegistWorldTouchAction()
end

function ChatInputView:RemoveLongActionEvent()
    if voiceEngine and VoiceType.Messages == voiceChatMgr:GetMode() then
        voiceEngine:StopRecording()
    end
    sceneWorld:removeOnTouchEndedAfterLongClickScriptHandler()
    sceneWorld:removeOnTouchMovedAfterLongClickScriptHandler()
end

function ChatInputView:onCleanup()
    AppFacade.GetInstance():UnRegistObserver('VOICE_EVENT', self)
    AppFacade.GetInstance():UnRegistObserver(FRIEND_REFRESH_EDITBOX, self)
    self:RemoveLongActionEvent()
end

return ChatInputView
