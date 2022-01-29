--[[
组队副本聊天层
--]]
local RaidChatLayer = class('RaidChatLayer', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.raid.RaidChatLayer'
	node:enableNodeEvents()
	print('RaidChatLayer', ID(node))
	return node
end)

------------ import ------------
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local audioMgr = AppFacade.GetInstance():GetManager("AudioManager")
local voiceChatMgr = AppFacade.GetInstance():GetManager("GlobalVoiceManager")
------------ import ------------

------------ define ------------
local OPEN_CHAT_DEBUG = true

local MusicDownVolume = 0.2
local SoundDownVolume = 0.2

-- 个人设置
local BUTTON_CLICK = {
    CONTREL_MUSIC_BIGORLITTLE 			= 1014, --控制音乐大小
    CONTREL_GAME_EFFECT_BIGORLITTLE 	= 1015, --控制音乐大小
    CONTREL_GAME_VOICE_BIGORLITTLE 		= 1017, --控制游戏声音大小
    FORM_TEAM_VOICE_AUTO_PLAY 			= 1021  --组队语音控制
}
------------ define ------------

--[[
constructor
--]]
function RaidChatLayer:ctor( ... )
	local args = unpack({...})

	self.isVoiceChatConnected = false
	self.isChatPanelInited = false
	self.isMicOpen = nil
	self.isSpeakerOpen = nil
	self.voiceNodeHandler = nil

	self:InitUI()
end
---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化ui
--]]
function RaidChatLayer:InitUI()

	local CreateView = function ()

		-- 聊天板
		local chatPanel = require('common.CommonChatPanel').new({channelId = CHAT_CHANNELS.CHANNEL_TEAM})
	    self:addChild(chatPanel)

	    -- 语音按钮
		local chatPanelBg = chatPanel.viewData_.bg

		local micBtn = display.newButton(0, 0, {n = _res('ui/raid/room/main_bg_common_dialogue.png')})
		display.commonUIParams(micBtn, {po = cc.p(
		    display.SAFE_L + micBtn:getContentSize().width * 0.5 + 2,
		    chatPanelBg and (chatPanelBg:getContentSize().height + micBtn:getContentSize().height * 0.5 + 5) or (micBtn:getContentSize().height * 0.5 + 5)
		), cb = handler(self, self.MicBtnClickHandler)})
		self:addChild(micBtn)

		local micEnableMark = display.newNSprite(_res('ui/raid/room/raid_room_ico_micon.png'))
		display.commonUIParams(micEnableMark, {po = utils.getLocalCenter(micBtn)})
		micBtn:addChild(micEnableMark)
		micEnableMark:setTag(3)
		micEnableMark:setVisible(false)

		local micDisableMark = display.newNSprite(_res('ui/raid/room/raid_room_ico_micoff.png'))
		display.commonUIParams(micDisableMark, {po = utils.getLocalCenter(micBtn)})
		micBtn:addChild(micDisableMark)
		micDisableMark:setTag(5)

		local speakerBtn = display.newButton(0, 0, {n = _res('ui/raid/room/main_bg_common_dialogue.png')})
		display.commonUIParams(speakerBtn, {po = cc.p(
		    micBtn:getPositionX() + micBtn:getContentSize().width * 0.5 + speakerBtn:getContentSize().width * 0.5 + 5,
		    micBtn:getPositionY()
		), cb = handler(self, self.SpeakerBtnClickHandler)})
		self:addChild(speakerBtn)

		local speakerEnableMark = display.newNSprite(_res('ui/raid/room/raid_room_ico_volon.png'))
		display.commonUIParams(speakerEnableMark, {po = utils.getLocalCenter(speakerBtn)})
		speakerBtn:addChild(speakerEnableMark)
		speakerEnableMark:setTag(3)
		speakerEnableMark:setVisible(false)

		local speakerDisableMark = display.newNSprite(_res('ui/raid/room/raid_room_ico_voloff.png'))
		display.commonUIParams(speakerDisableMark, {po = utils.getLocalCenter(speakerBtn)})
		speakerBtn:addChild(speakerDisableMark)
		speakerDisableMark:setTag(5)

		-- -- 初始化实时语音
		-- local voiceNode = nil
		-- if device.platform == 'android' or device.platform == 'ios' then
		-- 	voiceNode = VoiceNode:create(
		-- 		cc.size(5, 5),
		-- 		'1564137035',
		-- 		'3f8719414f1dedc6d1e8ba5892f4927a',
		-- 		checkint(gameMgr:GetUserInfo().userId),
		-- 		VoiceType.RealTime
		-- 	)
		-- 	voiceNode:setBackgroundColor(cc.c4b(255, 0, 0, 0))
		-- 	voiceNode:setPosition(cc.p(display.cx, display.cy))
		-- 	self:addChild(voiceNode, 9999)
		-- end

		return {
			chatPanel = chatPanel,
			micBtn = micBtn,
			speakerBtn = speakerBtn
		}

	end

	xTry(function()
		self.viewData = CreateView()
	end, __G__TRACKBACK__)

	-- 注册事件
	self:RegistVoiceNodeEventHandler()
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- logic begin --
---------------------------------------------------
--[[
初始化聊天板
--]]
function RaidChatLayer:InitChatPanel()
	if not self:GetInitedChatPanel() then
		self.viewData.chatPanel:delayInit()
		self:SetInitedChatPanel(true)
	end
end
-- --[[
-- 实时语音事件回调
-- --]]
-- function RaidChatLayer:VoiceNodeEventCallback(event)
-- 	-- dump(event)

-- 	local voiceNode = self.viewData.voiceNode
-- 	local state = event.state
-- 	local code = checkint(event.code)

-- 	if state and StateType.State_JoinRoom == state then

-- 		-- 连线成功回调
-- 		self:SetConnectedVoiceChat(true)

-- 		voiceNode:setBackgroundColor(cc.c4b(0, 0, 255, 0))
-- 		uiMgr:ShowInformationTips(__('实时语音连接成功!!!'))

-- 		self:OpenMic(false)
-- 		self:OpenSpeaker(true)

-- 		-- 连线成功后降低背景音乐和音效的声音
-- 		audioMgr:SetBGVolume(MusicDownVolume)
-- 		audioMgr:SetAudioClipVolume(AUDIOS.UI.name, SoundDownVolume)
-- 		-- 战斗音效
-- 		audioMgr:SetAudioClipVolume(AUDIOS.BATTLE.name, SoundDownVolume)
-- 	end
-- end
--[[
连接实时语音
@params roomId int 语音连接id
--]]
function RaidChatLayer:ConnectRealTimeVoiceChat(roomId)
	if device.platform == 'android' or device.platform == 'ios' then
		local voiceNode = self:GetVoiceNode()
		if nil ~= voiceNode and not self:GetConnectedVoiceChat() then
			print('here check fuck connect real time chat<<<<<<<<<<<<<<<<<<<<<<<<<')
			voiceChatMgr:SetMode(VoiceType.RealTime)
			voiceNode:SetMode(VoiceType.RealTime)
			voiceNode:JoinTeamRoom(roomId)
			voiceNode:StartUpdate()
		end
	end
end
--[[
退出聊天房间
@params roomId int 退出语音聊天
--]]
function RaidChatLayer:ExitRealTimeVoiceChat(roomId)
	if device.platform == 'android' or device.platform == 'ios' then
		local voiceNode = self:GetVoiceNode()
		if nil ~= voiceNode then

			voiceNode:CloseMic()
			voiceNode:CloseSpeaker()
			voiceNode:QuitRoom(roomId)
			self:SetConnectedVoiceChat(false)

			-- 恢复背景音乐和音效的声音
			local playerMusicVolume = app.audioMgr:GetMusicVolume()
			local playerSoundVolume = app.audioMgr:GetAudioVolume()
			audioMgr:SetBGVolume(playerMusicVolume)
			audioMgr:SetAudioClipVolume(AUDIOS.UI.name, playerSoundVolume)
			audioMgr:SetAudioClipVolume(AUDIOS.BATTLE.name, playerSoundVolume)
			audioMgr:SetAudioClipVolume(AUDIOS.BATTLE2.name, playerSoundVolume)

			-- 恢复语音聊天模式
			voiceNode:SetMode(VoiceType.Messages)
			local ret = voiceNode:ApplyMessageKey()
			if 0 == ret then
				voiceChatMgr:SetMode(VoiceType.Messages)
				voiceNode:StartUpdate()
			end

		end
	end
end
--[[
打开麦克风
@params open bool 是否打开麦克风
--]]
function RaidChatLayer:OpenMic(open)
	if nil ~= self.isMicOpen and open == self.isMicOpen then return end

	self.viewData.micBtn:getChildByTag(3):setVisible(open)
	self.viewData.micBtn:getChildByTag(5):setVisible(not open)

	local voiceNode = self:GetVoiceNode()
	if nil ~= voiceNode then
		if open then
			voiceNode:OpenMic()
		else
			voiceNode:CloseMic()
		end
	end

	self.isMicOpen = open
end
--[[
打开扬声器
@params open bool 是否打开扬声器
--]]
function RaidChatLayer:OpenSpeaker(open)
	if nil ~= self.isSpeakerOpen and open == self.isSpeakerOpen then return end

	self.viewData.speakerBtn:getChildByTag(3):setVisible(open)
	self.viewData.speakerBtn:getChildByTag(5):setVisible(not open)

	local voiceNode = self:GetVoiceNode()
	if nil ~= voiceNode then
		if open then
			voiceNode:OpenSpeaker()
		else
			voiceNode:CloseSpeaker()
		end
	end

	self.isSpeakerOpen = open
end
--[[
摧毁自己
--]]
function RaidChatLayer:DestroySelf()
	self:setVisible(false)
	self:runAction(cc.RemoveSelf:create())
end
--[[
摧毁附加节点
--]]
function RaidChatLayer:DestroyAdditional()
	local globalChatView = sceneWorld:getChildByTag(GameSceneTag.Chat_GameSceneTag)
	if nil ~= globalChatView then
        globalChatView:stopAllActions()
        globalChatView:setVisible(false)
        globalChatView:runAction(cc.RemoveSelf:create())
    end
end
--[[
注册语音事件
--]]
function RaidChatLayer:RegistVoiceNodeEventHandler()
	AppFacade.GetInstance():RegistObserver('VOICE_EVENT', mvc.Observer.new(function (_, signal)

		dump(signal)

		local signalName = signal:GetName()
		if 'VOICE_EVENT' == signalName then

			local body = signal:GetBody()
			local name = body.name
			local code = checkint(body.code)

			if StateType.State_JoinRoom == name then
				
				-- 连线成功回调
				self:SetConnectedVoiceChat(true)

				uiMgr:ShowInformationTips(__('实时语音连接成功!!!'))

				self:OpenMic(false)
				self:OpenSpeaker(true)

				-- 连线成功后降低背景音乐和音效的声音
				audioMgr:SetBGVolume(MusicDownVolume)
				audioMgr:SetAudioClipVolume(AUDIOS.UI.name, SoundDownVolume)
				-- 战斗音效
				audioMgr:SetAudioClipVolume(AUDIOS.BATTLE.name, SoundDownVolume)
				audioMgr:SetAudioClipVolume(AUDIOS.BATTLE2.name, SoundDownVolume)

			end
		end

	end, self))
end
function RaidChatLayer:UnregistVoiceNodeEventHandler()
	AppFacade.GetInstance():UnRegistObserver('VOICE_EVENT', self)
end
---------------------------------------------------
-- logic end --
---------------------------------------------------

---------------------------------------------------
-- click handler begin --
---------------------------------------------------
--[[
麦克风按钮回调
--]]
function RaidChatLayer:MicBtnClickHandler(sender)
    PlayAudioByClickNormal()
    self:OpenMic(not self.isMicOpen)
end
--[[
扬声器按钮回调
--]]
function RaidChatLayer:SpeakerBtnClickHandler(sender)
    PlayAudioByClickNormal()
    self:OpenSpeaker(not self.isSpeakerOpen)
end
---------------------------------------------------
-- click handler end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
是否连接上实时语音
--]]
function RaidChatLayer:SetConnectedVoiceChat(b)
	self.isVoiceChatConnected = b
end
function RaidChatLayer:GetConnectedVoiceChat()
	return self.isVoiceChatConnected
end
--[[
是否初始化过聊天板
--]]
function RaidChatLayer:SetInitedChatPanel(b)
	self.isChatPanelInited = b
end
function RaidChatLayer:GetInitedChatPanel()
	return self.isChatPanelInited
end
--[[
获取语音node
--]]
function RaidChatLayer:GetVoiceNode()
	return voiceChatMgr:GetVoiceNode()
end
---------------------------------------------------
-- get set end --
---------------------------------------------------
function RaidChatLayer:onCleanup()
	self:UnregistVoiceNodeEventHandler()
end

return RaidChatLayer
