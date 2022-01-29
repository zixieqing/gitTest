--[[
全局语音聊天管理模块
--]]
local ManagerBase = require( "Frame.Manager.ManagerBase" )
---@class GlobalVoiceManager
local GlobalVoiceManager = class('GlobalVoiceManager', ManagerBase)

GlobalVoiceManager.instances = {}

------------ define ------------

VoiceType = {
    RealTime    		= 0,
    Messages    		= 1,
}

StateType = {
    State_JoinRoom     	= 'joinRoom',
    State_RoomStatus   	= 'roomStatus',
    State_MemberVoice  	= 'memberVoice',
    State_Upload       	= 'uploadFile',
    State_Download     	= 'downloadFile',
    State_ApplyMessage 	= 'applyMessage',
    State_RecordFile   	= 'recordedFile',
}

CodeType = {
    GV_ON_JOINROOM_SUCC               = 1,
    GV_ON_JOINROOM_TIMEOUT            = 2,
    GV_ON_JOINROOM_SVR_ERR            = 3,
    GV_ON_JOINROOM_UNKNOWN            = 4,
    GV_ON_NET_ERR                     = 5,
    GV_ON_QUITROOM_SUCC               = 6,
    GV_ON_MESSAGE_KEY_APPLIED_SUCC    = 7,
    GV_ON_MESSAGE_KEY_APPLIED_TIMEOUT = 8,
    GV_ON_MESSAGE_KEY_APPLIED_SVR_ERR = 9,
    GV_ON_MESSAGE_KEY_APPLIED_UNKNOWN = 10,
    GV_ON_UPLOAD_RECORD_DONE          = 11,
    GV_ON_UPLOAD_RECORD_ERROR         = 12,
    GV_ON_DOWNLOAD_RECORD_DONE        = 13,
    GV_ON_DOWNLOAD_RECORD_ERROR       = 14,
    GV_ON_PLAYFILE_DONE               = 18,
    GV_ON_ROOM_OFFLINE                = 19,
    GV_ON_UNKNOWN                     = 20,
}
------------ define ------------

---------------------------------------------------
-- mediator extend begin --
---------------------------------------------------
function GlobalVoiceManager:ctor( key )
	ManagerBase.ctor(self, key)
	if GlobalVoiceManager.instances[key] ~= nil then
		funLog(Logger.INFO,"注册相关的facade类型" )
		return
	end

	GlobalVoiceManager.instances[key] = self
end
function GlobalVoiceManager.GetInstance(key)
	key = (key or "GlobalVoiceManager")
	if GlobalVoiceManager.instances[key] == nil then
		GlobalVoiceManager.instances[key] = GlobalVoiceManager.new(key)
	end
	return GlobalVoiceManager.instances[key]
end
function GlobalVoiceManager.Destroy( key )
	key = (key or "GlobalVoiceManager")
	if GlobalVoiceManager.instances[key] == nil then
		return
	end
	--清除配表数据
	GlobalVoiceManager.instances[key] = nil
end
---------------------------------------------------
-- mediator extend end --
---------------------------------------------------

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化一次语音管理器
--]]
function GlobalVoiceManager:Initial()
	self.voiceMode = nil

	if device.platform == 'ios' or device.platform == 'android' then
		-- 移除原先可能存在的voicenode
		if sceneWorld:getChildByTag(GameSceneTag.GlobalVoiceNodeTag) then
			sceneWorld:removeChildByTag(GameSceneTag.GlobalVoiceNodeTag)
		end

		if VoiceNode then
            local voiceId = "1564137035"
            local voiceKey = "3f8719414f1dedc6d1e8ba5892f4927a"
            if isJapanSdk() then
                voiceId = "1578107851"
                voiceKey = "65fdcfa4f5c25766b823a331e6fcd452"
            end
			local voiceNode = VoiceNode:create(
				cc.size(200, 200),
                voiceId,
                voiceKey,
				app.gameMgr:GetUserInfo().userId,
				VoiceType.Messages
			)
			voiceNode:setPosition(cc.p(0, 0))
			voiceNode:registScriptHandler(handler(self, self.VoiceNodeEventHandler))
			
			sceneWorld:addChild(voiceNode, 1, GameSceneTag.GlobalVoiceNodeTag)

			local ret = voiceNode:ApplyMessageKey()
			if ret == 0 then
				voiceNode:StartUpdate() --开始start update的逻辑
			end
		end

		self:SetMode(VoiceType.Messages)

	end
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- handler begin --
---------------------------------------------------
--[[
语音节点绑定的回调事件
--]]
function GlobalVoiceManager:VoiceNodeEventHandler(evt)
	local state = evt.state
	local code = checkint(evt.code)
	local voiceNode = self:GetVoiceNode()

	dump(evt)

	if state then
		if StateType.State_ApplyMessage == state then

			--开始录音的逻辑
			if voiceNode then
				voiceNode:StartUpdate() --开始start update的逻辑
			-- AppFacade.GetInstance():DispatchObservers('VOICE_EVENT', {name = StateType.State_ApplyMessage,code = code})
			end

		elseif StateType.State_Upload == state then

			--语音上传成功逻辑 发送消息
			AppFacade.GetInstance():DispatchObservers('VOICE_EVENT', {name = StateType.State_Upload, code = code, fileID = evt.fileID})

		elseif StateType.State_Download == state then

			AppFacade.GetInstance():DispatchObservers('VOICE_EVENT', {name = StateType.State_Download, code = code, fileID = evt.fileID})
			app.audioMgr:PauseBGMusic()
			
			if utils.isExistent(evt.filePath) and voiceNode then
                voiceNode:PlayRecordedFile(evt.filePath)
            end

        elseif StateType.State_RecordFile == state then

            --录音播放完成
            AppFacade.GetInstance():DispatchObservers('VOICE_EVENT',{name = StateType.State_RecordFile,code = code,fileID = evt.fileID})
            app.audioMgr:ResumeBGMusic()
            AppFacade.GetInstance():DispatchObservers(CHAT_AUDIO_END)

        elseif StateType.State_JoinRoom == state then

			-- 加入组队聊天成功
			AppFacade.GetInstance():DispatchObservers('VOICE_EVENT', {
				name = StateType.State_JoinRoom,
				code = code,
				event = event
			})

		end
	end

end
---------------------------------------------------
-- handler end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
获取当前语音节点
--]]
function GlobalVoiceManager:GetVoiceNode()
	return sceneWorld:getChildByTag(GameSceneTag.GlobalVoiceNodeTag)
end
--[[
获取当前模式
--]]
function GlobalVoiceManager:GetMode()
	return self.voiceMode
end
function GlobalVoiceManager:SetMode(mode)
	self.voiceMode = mode
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return GlobalVoiceManager
