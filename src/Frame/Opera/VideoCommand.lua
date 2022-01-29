local Command = require( 'Frame.Opera.Command' )

local Director = require( "Frame.Opera.Director" )

local VideoCommand = Command:New()

VideoCommand.NAME = "VideoCommand"


--[[--*
* @param name 视频文件名
--]]
function VideoCommand:New(name)
    local this = {}
    setmetatable( this, {__index = VideoCommand} )
    this.videoPath = name and _res(string.fmt('res/arts/stage/video/%1.usm', name)) or _res('res/eater_video.usm')
    this.inAction  = true
    return this
end


--[[
设置图象的反转
@param color 色彩值
--]]
function VideoCommand:SetColor( color )
    this.color = ccc4FromInt(color)
end


function VideoCommand:CanMoveNext()
    return false
end


--[[
--执行方法的虚方法
--真实调用的方法逻辑
--执行窗口抖动
--]]
function VideoCommand:Execute( )
    --执行方法的虚方法
	local director = Director.GetInstance( )
    local stage = director:GetStage()
    
	if stage then
        --首先移除消息层
        if stage:getChildByTag(Director.ZorderTAG.Z_ROLE_LAYER) then
            stage:removeChildByTag(Director.ZorderTAG.Z_ROLE_LAYER)
        end

		--再添加消息层
        local colorView = VideoNode:create()
        colorView:setContentSize(display.size)
        colorView:registScriptHandler(function(event)
            -- 6 is finished; 8 is can't renderer（但是8会派发2次，所以收到后立刻移除侦听比较安全）
            if checkint(event.status) == 6 or checkint(event.status) == 8 then
                colorView:setVisible(false)
                colorView:unregistScriptHandler()
                colorView:runAction(cc.RemoveSelf:create())
                self:finishCommand()
            end
        end)
        display.commonUIParams(colorView, {po = display.center})
        stage:addChild(colorView, Director.ZorderTAG.Z_VIDEO_LAYER, Director.ZorderTAG.Z_VIDEO_LAYER)
        colorView:PlayVideo(self.videoPath)
    end
end


function VideoCommand:finishCommand()
    self.inAction = false
    --自动下移命令
    self:Dispatch("DirectorStory","next")
end


return VideoCommand
