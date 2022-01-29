local Command = require( 'Frame.Opera.Command' )

local Director = require( "Frame.Opera.Director" )

local WaitCommand = Command:New()

WaitCommand.NAME = "WaitCommand" --移除动作执行功能


--[[--*
* 等待多少秒再继续执行剧情
* @param time 等待的时间
* @param click 是否需要点击才执行接下来的动作
--]]
function WaitCommand:New(time, click)
	local this = {}
	setmetatable( this, {__index = WaitCommand} )
	this.time = time
	-- this.click = (click or false) --是否需在单击才会执行接下来的动作
	return this
end

--[[
* 是否可以进行下一步
* @return 初始是可以进行下一步操作
--]]
function WaitCommand:CanMoveNext( )
	return false 
end
--[[
--执行方法的虚方法
--真实调用的方法逻辑
--执行窗口抖动
--]]
function WaitCommand:Execute( )
	--执行方法的虚方法
	local director = Director.GetInstance( "Director" )
	-- if self.click then
	-- 	--添加点击层
	-- else
	local stage = director:GetStage()
	stage:runAction(cc.Sequence:create(cc.DelayTime:create(tonumber(self.time,10)),cc.CallFunc:create(function()
		self:Dispatch("DirectorStory","next")
	end)))
	-- end
end

return WaitCommand