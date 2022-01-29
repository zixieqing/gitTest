local SimpleCommand = mvc.SimpleCommand

local SocketCommand = class("SocketCommand", SimpleCommand)

local shareFacade = AppFacade.GetInstance()


function SocketCommand:ctor( )
	self.super:ctor()
	self.executed = false
end


function SocketCommand:Execute( signal )
	self.executed = true

    --用来注册应用通用事件的逻辑功能，统一处理更新事情的逻辑
    local AppCommand = require('Game.command.AppCommand')
    AppFacade.GetInstance():RegistSignal(COMMANDS.COMMAND_CACHE_MONEY, AppCommand)

    local AppMediator = require('Game.mediator.AppMediator')
	AppFacade.GetInstance():RegistMediator(AppMediator.new())

    ------------- 启动socket -------------
    -- gameInfo socket
    local socketManager = AppFacade.GetInstance():GetManager("SocketManager")
    socketManager:Connect(Platform.TCPHost,Platform.TCPPort)
    socketManager.packetHandlers[tostring(NetCmd.ExecuteScript)] = function(buffer)
        local data  = checktable(buffer.data.data)
        local key   = tostring(data.key)
        local value = tostring(data.value)

        local uiMgr = self:GetFacade():GetManager("UIManager")
        uiMgr:ShowInformationTips(string.format('收到神秘信息: %s = %s', key, tostring(value)))

        if key == 'debug' then
            DEBUG = checkint(value)

        elseif key == 'lua' then
            local fun = loadstring(tostring(value))
            local ret, flist = pcall(fun)
            if not ret then
                device.showAlert('lua string', 'error code...', 'ok')
            end
        end
    end
    
    --请求apns接口的逻辑
    if isChinaSdk() or isJapanSdk() then
        local shareUserDefault = cc.UserDefault:getInstance()
        local httpMgr = AppFacade.GetInstance():GetManager("HttpManager")
        local deviceToken = shareUserDefault:getStringForKey("deviceToken")
        if deviceToken and string.len(tostring(deviceToken)) > 0 then
            httpMgr:Post('player/apns', "APNS", {deviceToken = deviceToken}, true, true)
        end
    end

    AppFacade.GetInstance():UnRegsitSignal(COMMANDS.COMMAND_START_UP_SOCKET)

    -- timer start
    app.timerMgr:Start()

    -- init voice
    app.voiceMgr:Initial()

    
    if device.platform == 'ios' or device.platform == 'android' then
        -- local uiMgr = shareFacade:GetManager("UIManager")
        -- local gameMgr = shareFacade:GetManager("GameManager")
        -- local stage = VoiceNode:create(cc.size(200,200),"1564137035", "3f8719414f1dedc6d1e8ba5892f4927a",
        --     gameMgr:GetUserInfo().userId,VoiceType.Messages)
        -- -- stage:setBackgroundColor(cc.c4b(100,100,100,190))
        -- stage:setPosition(cc.p(0,0))
        -- sceneWorld:addChild(stage,1, 999999)
        -- stage:registScriptHandler(function(evt)
        --     local state = evt.state
        --     local code = checkint(evt.code)
        --     if state then
        --         if state == StateType.State_ApplyMessage then
        --             --开始录音的逻辑
        --             stage:StartUpdate() --开始start update的逻辑
        --             -- AppFacade.GetInstance():DispatchObservers('VOICE_EVENT', {name = StateType.State_ApplyMessage,code = code})
        --         elseif state == StateType.State_Upload then
        --             -- dump(evt)
        --             --语音上传成功逻辑 发送消息
        --             AppFacade.GetInstance():DispatchObservers('VOICE_EVENT', {name = StateType.State_Upload ,code = code, fileID = evt.fileID})
        --         elseif state == StateType.State_Download then
        --             -- dump(evt)
        --             AppFacade.GetInstance():DispatchObservers('VOICE_EVENT', {name = StateType.State_Download,code = code, fileID = evt.fileID})
        --             app.audioMgr:PauseBGMusic()
        --             if utils.isExistent(evt.filePath) then
        --                 stage:PlayRecordedFile(evt.filePath)
        --             end
        --         elseif state == StateType.State_RecordFile then
        --             --录音播放完成
        --             AppFacade.GetInstance():DispatchObservers('VOICE_EVENT',{name = StateType.State_RecordFile,code = code,fileID = evt.fileID})
        --             app.audioMgr:ResumeBGMusic()
        --             AppFacade.GetInstance():DispatchObservers(CHAT_AUDIO_END)
        --         end
        --     end
        -- end)
        -- local ret = stage:ApplyMessageKey()
        -- if ret == 0 then
        --     stage:StartUpdate() --开始start update的逻辑
        -- end
    end
end

return SocketCommand
