local Command = require( 'Frame.Opera.Command' )

local Director = require( "Frame.Opera.Director" )

--[[
骨骼动作的功能
--]]
local SketonCommand = Command:New()

SketonCommand.NAME = "SketonCommand" --移除动作执行功能


--[[--*
* 对某个角色执行一个移动动作
* @param animateId 动作id
* @param x 要移动到的x位置
* @param y 要移动到的y位置
* @param time 移动完成的时间
--]]
function SketonCommand:New(animateId, animateName, x, y)
	local this = {}
	setmetatable( this, {__index = SketonCommand} )
	this.animateId = animateId
	this.animateName = animateName
	this.x = x
	this.y = y
	return this
end

--[[
* 是否可以进行下一步
* @return 初始是可以进行下一步操作
--]]
function SketonCommand:CanMoveNext( )
	return false 
end
--[[
--执行方法的虚方法
--真实调用的方法逻辑
--执行窗口抖动
--]]
function SketonCommand:Execute( )
	--执行方法的虚方法

end

return SketonCommand