--[[
 * author : liyajie
 * descpt : 音频管理器
]]
local BaseManager  = require('Frame.Manager.ManagerBase')
---@class AudioManager
local AudioManager = class('AudioManager', BaseManager)


-------------------------------------------------
-- manager method

AudioManager.DEFAULT_NAME = 'AudioManager'


function AudioManager.GetInstance(instancesKey)
	instancesKey = instancesKey or AudioManager.DEFAULT_NAME
    
	if _G[instancesKey] == nil then
		_G[instancesKey] = AudioManager.new(instancesKey)
	end
	return _G[instancesKey]
end


function AudioManager.Destroy(instancesKey)
	instancesKey = instancesKey or AudioManager.DEFAULT_NAME

	if _G[instancesKey] then
		_G[instancesKey]:release()
		_G[instancesKey] = nil
	end
end


-------------------------------------------------
-- life cycle

function AudioManager:ctor(instancesKey)
	self.super.ctor(self)
	
	if _G[instancesKey] then
		funLog(Logger.INFO, "注册相关的facade类型")
	else
		self:initial()
	end
end


function AudioManager:initial()
	-- init vars
	self.findCacheMap_ = {}
	self.loadedCueMap_ = {}
	self.lastBgmDeine_ = {}
	self.voiceRecord_  = {}
	self.audioEngine_  = CriAtom:GetInstance()

	-- init audioEngine
	if not CriAtom:IsInitialized() then
		self.audioEngine_:SetAcfFileName(AUDIOS.ACF)
		self.audioEngine_:Setup()
	end
end


function AudioManager:release()
	self:stopAndClean()
end


function AudioManager:stopAndClean()
	self:StopAllPlayers()
	self:CleanAllCueSheet()
end


-------------------------------------------------------------------------------
-- setting about
-------------------------------------------------------------------------------

--[[
	获取/设置 音乐开关
]]
function AudioManager:IsOpenMusic()
	return CommonUtils.GetControlGameProterty(CONTROL_GAME.CONRROL_MUSIC)
end
function AudioManager:SetOpenMusic(isOpen)
	CommonUtils.SetControlGameProterty(CONTROL_GAME.CONRROL_MUSIC, checkbool(isOpen))
end


--[[
	获取/设置 音效开关
]]
function AudioManager:IsOpenAudio()
	return CommonUtils.GetControlGameProterty(CONTROL_GAME.GAME_MUSIC_EFFECT)
end
function AudioManager:SetOpenAudio(isOpen)
	CommonUtils.SetControlGameProterty(CONTROL_GAME.GAME_MUSIC_EFFECT, checkbool(isOpen))
end


--[[
	获取/设置 音乐音量
]]
function AudioManager:GetMusicVolume()
	return CommonUtils.GetControlGameProterty(CONTROL_GAME_VLUE.CONTREL_MUSIC_BIGORLITTLE) or 0.8
end
function AudioManager:SetMusicVolume(volume)
	CommonUtils.SetControlGameProterty(CONTROL_GAME_VLUE.CONTREL_MUSIC_BIGORLITTLE, checknumber(volume))
end


--[[
	获取/设置 音效音量
]]
function AudioManager:GetAudioVolume()
	return CommonUtils.GetControlGameProterty(CONTROL_GAME_VLUE.CONTREL_GAME_EFFECT_BIGORLITTLE) or 0.8
end
function AudioManager:SetAudioVolume(volume)
	CommonUtils.SetControlGameProterty(CONTROL_GAME_VLUE.CONTREL_GAME_EFFECT_BIGORLITTLE, checknumber(volume))
end


--[[
	获取/设置 当前的语音类型
	@see PLAY_VOICE_TYPE
--]]
function AudioManager:GetVoiceType()
	if not self.voiceType_ then
		self.voiceType_ = cc.UserDefault:getInstance():getIntegerForKey('voiceType', PLAY_VOICE_TYPE.JAPANESE)
	end
	return self.voiceType_
end
function AudioManager:SetVoiceType(voiceType)
	self.voiceType_ = checkint(voiceType)
	cc.UserDefault:getInstance():setIntegerForKey('voiceType', self.voiceType_)
	cc.UserDefault:getInstance():flush()
end


-------------------------------------------------------------------------------
-- cueSheet about
-------------------------------------------------------------------------------

function AudioManager:AddCueSheet(cueName, acbFile, awbFile)
	if not self.loadedCueMap_[tostring(cueName)] then
		-- append cueSheet
		self.audioEngine_:AddCueSheet(cueName, acbFile, awbFile or '')
		self.loadedCueMap_[tostring(cueName)] = true
		-- append findCache
		local acbRef   = self.audioEngine_:GetAcb(cueName)
		local cueInfos = acbRef and acbRef:GetCueInfoList() or {}
		for _, cueInfo in ipairs(cueInfos) do
			self.findCacheMap_[cueInfo.name] = cueName
		end
	end
end


function AudioManager:RemoveCueSheet(cueName)
	if self.loadedCueMap_[tostring(cueName)] then
		-- remove findCache
		local acbRef   = self.audioEngine_:GetAcb(cueName)
		local cueInfos = acbRef and acbRef:GetCueInfoList() or {}
		for _, cueInfo in ipairs(cueInfos) do
			self.findCacheMap_[cueInfo.name] = nil
		end
		-- remove cueSheet
		self.audioEngine_:RemoveCueSheet(cueName)
		self.loadedCueMap_[tostring(cueName)] = nil
	end
end


function AudioManager:CleanAllCueSheet()
	for cueName, _ in pairs(self.loadedCueMap_) do
		self.audioEngine_:RemoveCueSheet(cueName)
	end
	self.findCacheMap_ = {}
	self.loadedCueMap_ = {}
end


function AudioManager:DumpAllCueSheet()
	for cueName, _ in pairs(self.loadedCueMap_) do
		local acbRef   = self.audioEngine_:GetAcb(cueName)
		local cueInfos = acbRef and acbRef:GetCueInfoList() or {}
		local infoList = {}
		for index, cueInfo in ipairs(cueInfos) do
			table.insert(infoList, string.format('%40s : %s', cueInfo.name, cueInfo.time))
		end
		print(string.fmt('%1 = {\n%2\n}', cueName, table.concat(infoList, '\n')))
	end
end


function AudioManager:findCueSheetByCueKey(cueKey)
	return self.findCacheMap_[tostring(cueKey)]
end


function AudioManager:checkCueSheetByCueKey(cueKey)
	if cueKey ~= nil and self.findCacheMap_[tostring(cueKey)] == nil then
		local matchAudioMap = {}
		local isFindedSheet = false
		for _, audioDefine in pairs(AUDIOS) do
			if type(audioDefine) == 'table' then
				-- match define
				for _, cueDefine in pairs(audioDefine) do
					if type(cueDefine) == 'table' then
						if cueDefine.id == cueKey then
							matchAudioMap[audioDefine.name] = audioDefine
							isFindedSheet = true
							break
						end
					end
				end
				-- match pattern
				if audioDefine.pattern then
					local patternList = type(audioDefine.pattern) == 'table' and audioDefine.pattern or { audioDefine.pattern }
					for _, pattern in ipairs(patternList) do
						if string.find(cueKey, pattern) ~= nil then
							matchAudioMap[audioDefine.name] = audioDefine
						end
					end
				end
			end
			if isFindedSheet then break end
		end
		-- add cueSheet
		for _, audioDefine in pairs(matchAudioMap) do
			self:AddCueSheet(audioDefine.name, audioDefine.acb, audioDefine.awb)
		end
	end
	return self:findCueSheetByCueKey(cueKey)
end


-------------------------------------------------------------------------------
-- exPlayer about
-------------------------------------------------------------------------------

function AudioManager:StopAllPlayers()
	self.audioEngine_:StopAllPlayers()
end


function AudioManager:RetrivePlayer(retriveKey)
    return self.audioEngine_:RetrivePlayer(retriveKey)
end


function AudioManager:PausePlayer(retriveKey)
	local exPlayer = self:RetrivePlayer(retriveKey)
	if exPlayer and not exPlayer:IsPaused() then
		exPlayer:Pause()
	end
end


function AudioManager:ResumePlayer(retriveKey)
	local exPlayer = self:RetrivePlayer(retriveKey)
	if exPlayer and exPlayer:IsPaused() then
		exPlayer:Resume(0)
	end
end


function AudioManager:IsPausedPlayer(retriveKey)
	local isPaused = false
	local exPlayer = self:RetrivePlayer(retriveKey)
	if exPlayer then
		isPaused = exPlayer:IsPaused()
	end
	return isPaused
end


function AudioManager:StartPlayer(retriveKey, cueKey, hasPlayback)
	local exPlayer = self:RetrivePlayer(retriveKey)
	local acbRef   = self.audioEngine_:GetAcb(retriveKey)
	if exPlayer and acbRef then
		exPlayer:SetCue(acbRef, tostring(cueKey))
		return exPlayer:Start(hasPlayback == true)
	end
end


function AudioManager:StopPlayer(retriveKey, isIgnoresReleaseTime)
	local exPlayer = self:RetrivePlayer(retriveKey)
	if exPlayer then
		exPlayer:Stop(isIgnoresReleaseTime == true)
	end
end


function AudioManager:SetPlayerVolume(retriveKey, volume)
	local exPlayer = self:RetrivePlayer(retriveKey)
	if exPlayer then
		exPlayer:SetVolume(checknumber(volume))
		if not self:IsPausedPlayer(retriveKey) then
			exPlayer:UpdateAll()
		end
	end
end


function AudioManager:GetPlayerCueTime(retriveKey, cueKey)
	local acbRef  = self.audioEngine_:GetAcb(retriveKey)
	local cueInfo = acbRef and acbRef:GetCueInfo(cueKey) or {}
	return checkint(cueInfo.time) / 1000
end


--@return exStatus : int    status code
--@see AUDIO_PLAYER_STATUS
function AudioManager:GetPlayerStatus(retriveKey)
	local exStatus = AUDIO_PLAYER_STATUS.ERROR
	local exPlayer = self:RetrivePlayer(retriveKey)
	if exPlayer then
		exStatus = exPlayer:GetStatus()
	end
	return exStatus
end


-------------------------------------------------------------------------------
-- bgMusic about
-------------------------------------------------------------------------------

function AudioManager:GetPlayingBGCueName()
	return self.lastBgmDeine_.cueName
end
function AudioManager:GetPlayingBGCueKey()
	return self.lastBgmDeine_.cueKey
end


--[[
	播放 指定背景音乐
	@param cueName : str    cue名字（可选，默认最后一次播放的name）
	@param cueKey  : str    cue关键字（可选，默认最后一次播放的key）
]]
function AudioManager:PlayBGMusic(cueName, cueKey)
	local playCueName = cueName or self:GetPlayingBGCueName()
	local playCueKey  = cueKey or self:GetPlayingBGCueKey()

	if self:IsOpenMusic() and playCueName ~= nil and playCueKey ~= nil then
        local exPlayer = self:RetrivePlayer(playCueName)
		if exPlayer then
			if self:IsPausedPlayer(playCueName) then
				self:ResumePlayer(playCueName)
			end
		else
			exPlayer = self.audioEngine_:CreatePlayer(playCueName)
			exPlayer:SetVoicePriority(1)
			-- exPlayer:SetCuePriority(1)
			-- bgm 优先级设调高。这样在快速堆积音效时，就不会被同时播放的音轨数超过 VoicePoolConfig.num_voices 而被停止掉。
        end
		-- check same last
		if self:GetPlayingBGCueName() ~= playCueName or self:GetPlayingBGCueKey() ~= playCueKey then
			-- stop oldMusic
			if self:GetPlayingBGCueName() then
				self:StopBGMusic(self:GetPlayingBGCueName())
			end
			-- init volume
			self:SetBGVolume(self:GetMusicVolume(), playCueName)
			-- play music
			self:StartPlayer(playCueName, playCueKey)
			-- update define
			self.lastBgmDeine_.cueName = playCueName
			self.lastBgmDeine_.cueKey  = playCueKey
		end
	end
end


--[[
	停止 指定背景音乐
	@param cueName : str    cue名字（可选，默认为当前播放中的cue）
]]
function AudioManager:StopBGMusic(cueName)
	self:StopPlayer(cueName or self:GetPlayingBGCueName())
	-- clean bgmDefine
	if cueName == nil or cueName == self:GetPlayingBGCueName() then
		self.lastBgmDeine_.cueName = nil
		self.lastBgmDeine_.cueKey  = nil
	end
end


--[[
	暂停 指定背景音乐
	@param cueName : str    cue名字（可选，默认为当前播放中的cue）
]]
function AudioManager:PauseBGMusic(cueName)
	if self:IsOpenMusic() then
		self:PausePlayer(cueName or self:GetPlayingBGCueName())
	end
end


--[[
	恢复 指定背景音乐
	@param cueName : str    cue名字（可选，默认为当前播放中的cue）
]]
function AudioManager:ResumeBGMusic(cueName)
	if self:IsOpenMusic() then
		self:ResumePlayer(cueName or self:GetPlayingBGCueName())
	end
end


--[[
	设置 背景音乐音量
	@param volume  : float    音量值（0-1）
	@param cueName : str      cue名字（可选，默认为当前播放中的cue）
]]
function AudioManager:SetBGVolume(volume, cueName)
	if self:IsOpenMusic() then
		self:SetPlayerVolume(cueName or self:GetPlayingBGCueName(), volume)
	end
end


-------------------------------------------------------------------------------
-- audioClip about
-------------------------------------------------------------------------------

--[[
	播放 指定音效片段
	@param cueName      : str     cue名字
	@param cueKey       : str     cue关键字
	@param hasPlayback  : bool    是否要返回控制对象（可选，默认false）
	@return CriAtomExPlayback 对象
]]
function AudioManager:PlayAudioClip(cueName, cueKey, hasPlayback)
	if self:IsOpenAudio() then
		local exPlayer = self:RetrivePlayer(cueName)
		if not exPlayer then
			exPlayer = self.audioEngine_:CreatePlayer(cueName)
		end
		-- init volume
		self:SetAudioClipVolume(cueName, self:GetAudioVolume())
		-- play audio
		return self:StartPlayer(cueName, cueKey, hasPlayback)
	end
end


--[[
	停止 指定音效片段
	@param cueName               : str     cue名字
	@param isIgnoresReleaseTime  : bool    是否立刻停止，忽略ReleaseTime（可选，默认false）
	Ps: 如果设置了 ReleaseTime 属性，才会等待时间到达结束。 CriAtoExPlayer:SetEnvelopeReleaseTime(float time)
]]
function AudioManager:StopAudioClip(cueName, isIgnoresReleaseTime)
	self:StopPlayer(cueName, isIgnoresReleaseTime)
end


--[[
	设置 音效片段音量
	@param cueName : str      cue名字
	@param volume  : float    音量值（0-1）
]]
function AudioManager:SetAudioClipVolume(cueName, volume)
	if self:IsOpenAudio() then
		self:SetPlayerVolume(cueName, volume)
	end
end


-------------------------------------------------------------------------------
-- cvVoice about
-------------------------------------------------------------------------------

--[[
    获取语言文件的路径
    ---@params  name 文件名称
    ---@params  type 播放语音的种类
    ---@params  isAbsolutePath 是否是绝对路径
    ---@params  isAcb 不传就是acb
--]]
function AudioManager:GetVoicePathByName(name ,type , isAbsolutePath , isAcb)
	type = type or self:GetVoiceType()
	local path = ''
	isAcb = isAcb == nil
	if isElexSdk() then
		if type == PLAY_VOICE_TYPE.CHINESE then
			path  = string.format("sounds/%s/%s", 'jp-jp', name)
		elseif type == PLAY_VOICE_TYPE.JAPANESE then
			path  = string.format("sounds/%s",  name)
		end
	else
		if type == PLAY_VOICE_TYPE.CHINESE then
			path  = string.format("sounds/%s/%s", i18n.getLang(), name)
		elseif type == PLAY_VOICE_TYPE.JAPANESE then
			path  = string.format("sounds/%s" , name)
		end
	end
	if isAbsolutePath then
		if utils.isExistent(string.format("%s%s%s" , device.writablePath ,RES_SUB_PATH, path))	then
			path = string.format("%s%s%s" , device.writablePath ,RES_SUB_PATH, path)
		elseif utils.isExistent(string.format("%s%s%s" , device.writablePath ,RES_PATH, path)) then
			path = string.format("%s%s%s" , device.writablePath ,RES_PATH, path)
		else
			path = string.format("%s%s%s" , device.writablePath ,RES_SUB_PATH, path)
		end
	end
	if isAcb  then
		path = path .. ".acb"
	end
	return path
end


--[[
	检测中文文件是否完整
--]]
function AudioManager:CheckChineseVoiceComplete(acbFile)
	local filename = self:GetVoicePathByName(acbFile, PLAY_VOICE_TYPE.CHINESE,  true, false)
	if not utils.isExistent(filename) then
		return false
	end
	if table.nums(self.voiceRecord_) == 0   then
		self:DealWithChineseVioceData()
	end
	if self.voiceRecord_[acbFile] then
		local md5Remote  = self.voiceRecord_[acbFile].md5
		local md5Local  = crypto.md5file(filename)
		if md5Remote == md5Local then
			return true
		end
	end
	return false
end


--[[
	分析当前的语音数据
--]]
function AudioManager:DealWithChineseVioceData()
	local filename = self:GetVoicePathByName(VOICE_DATA.VOICE_ROMOTE_FILE, PLAY_VOICE_TYPE.CHINESE, true, false)
	if io.exists(filename) then
		local conetxt = io.readfile(filename)
		local data = json.decode(conetxt)
		if data then
			for k , v in pairs(data) do
				self.voiceRecord_[v.name] = v
			end
		else
			self.voiceRecord_ = {}
		end
	else
		self.voiceRecord_ = {}
	end
end


--[[
	获取当前的语音数据
--]]
function AudioManager:GetRemoteChineseData()
	return self.voiceRecord_ or {}
end


--[[
	设置中文声音的数据
--]]
function AudioManager:SetChineseVioceData(data)
	if data and checkint(data.errcode) == 0    then
		for k , v in pairs(data) do
			if self and type(self.voiceRecord_) == 'table' then
				self.voiceRecord_[v.name] = v
			end
		end
	end
end


return AudioManager
