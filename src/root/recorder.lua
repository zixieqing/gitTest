local Recorder = class('cc.Recorder')


local DEFAULT_PROVIDER_OBJECT_NAME = "location.Recorder"

function Recorder:ctor()
    self:addListener()
end

function Recorder.GetInstance()
    if not _G['cc.Recorder'] then
        _G['cc.Recorder'] = Recorder.new()
    end
    return _G['cc.Recorder']
end

function Recorder.Destroy()
    _G['cc.Recorder'] = nil
end

local SDK_CLASS_NAME = "SummerAudio"
if device.platform == 'android' then
    SDK_CLASS_NAME = 'com.duobaogame.summer.SummerAudio'
end

function Recorder:addListener()
    if device.platform == 'ios' then
        luaoc.callStaticMethod(SDK_CLASS_NAME, "addScriptListener", {listener = handler(self, self.callback_)})
    elseif device.platform == 'android' then
        luaj.callStaticMethod(SDK_CLASS_NAME, "addScriptListener", {handler(self, self.callback_)})
    end
end

local scheduler = require('cocos.framework.scheduler')
---[[--
--  分享回调函数
---]]
function Recorder:callback_(event)
    event = json.decode(event)
    dump(event)
    if checkint(event.code) == 200 then
        --录音完成，测试播放
        local path = event.path
        self:playAudioWithFileName({filePath = path})
    end
end

function Recorder:isAudioServicesAvailable()
    if device.platform == 'android' then
        luaj.callStaticMethod(SDK_CLASS_NAME,'isAudioServicesAvailable',{},'()V')
    elseif device.platform == 'ios' then
        luaoc.callStaticMethod(SDK_CLASS_NAME,'isAudioServicesAvailable')
    end
end

function Recorder:playAudioWithFileName(t)
    if device.platform == 'android' then
        luaj.callStaticMethod(SDK_CLASS_NAME,'playAudioWithFileName',{t.filePath})
    elseif device.platform == 'ios' then
        local desiredAccuracy = t.filePath
        luaoc.callStaticMethod(SDK_CLASS_NAME, 'playAudioWithFileName',{filePath = desiredAccuracy})
    end
end

function Recorder:startRecording()
    if device.platform == 'android' then
        luaj.callStaticMethod(SDK_CLASS_NAME,'startRecording')
    elseif device.platform == 'ios' then
        luaoc.callStaticMethod(SDK_CLASS_NAME, 'startRecording')
    end
end

function Recorder:stopRecording()
    if device.platform == 'android' then
        luaj.callStaticMethod(SDK_CLASS_NAME,'stopRecording')
    elseif device.platform == 'ios' then
        luaoc.callStaticMethod(SDK_CLASS_NAME, 'stopRecording')
    end
end

function Recorder:cancelRecording()
    if device.platform == 'ios' then
        luaoc.callStaticMethod(SDK_CLASS_NAME, 'cancelRecording')
    end
end

return Recorder
