local Command = require( 'Frame.Opera.Command' )

local Director = require( "Frame.Opera.Director" )

local MusicCommand = Command:New()

MusicCommand.NAME = "MusicCommand"


--[[
音效命令
@musicPath 音乐路径文件
@isClip 是否是一个音效
--]]
function MusicCommand:New(controlmusic, musicPath, isClip)
	local this = {}
	setmetatable( this, {__index = MusicCommand} )
	this.musicPath = musicPath
	this.isClip = (isClip or false)
    this.controlmusic = controlmusic
	return this
end


--[[
* 是否可以进行下一步
* @return 初始是可以进行下一步操作
--]]
function MusicCommand:CanMoveNext( )
	return true
end
--[[
--执行方法的虚方法
--真实调用的方法逻辑
--执行窗口抖动
--]]
function MusicCommand:Execute( )
	--执行方法的虚方法
    if self.musicPath then
        PlayBGMusic(self.musicPath)
    end
    if self.controlmusic and string.find(self.controlmusic, '^%d+') then
        if checkint(self.controlmusic) == 0 then
            app.audioMgr:PauseBGMusic()
        else
            app.audioMgr:ResumeBGMusic()
        end
    end
end

return MusicCommand
