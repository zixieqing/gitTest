local Command = {}

local shareFacade = AppFacade.GetInstance()

function Command:New( )
	local this = {}
	setmetatable( this, {__index = Command} )
	this.curIndex = 0
	return this
end

--[[
得到当前命令的位置
--]]
function Command:GetIndex( )
    return self.curIndex
end
--[[
-- 分发事件到stage舞台来给director进行事件
--的相关的处理
--@name signal name
--@body signal data
--]]
function Command:Dispatch( name, body, type )
    shareFacade:DispatchObservers(name, body, type)
end

--[[
设置当前命令的位置
@param index 新的位置
--]]
function Command:SetIndex( index )
    self.curIndex = index
end

--[[
设置当前命令的zorder值
@param targetName 指定对象名
@param zorder 指定的order值
--]]
function Command:SetZorder( targetName, zorder )
	self.targetName = targetName
	self.zorder = zorder
end
--[[--*
* 设置角色的位置
*
* @param name 角色名称
* @param x x位置
* @param y y位置
--]]
function Command:SetTargetPosition( roleId, x, y )
	self.roleId = roleId
	self.pos = cc.p(x, y)
end

--[[
* 是否可以进行下一步
* @return 初始是可以进行下一步操作
--]]
function Command:CanMoveNext( )
	return true 
end

--[[
--执行方法的虚方法
--真实调用的方法逻辑
--]]
function Command:Execute( )
	--执行方法的虚方法
end


return Command 