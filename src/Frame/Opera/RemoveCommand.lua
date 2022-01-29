local Command = require( 'Frame.Opera.Command' )

local Director = require( "Frame.Opera.Director" )

local RemoveCommand = Command:New()

RemoveCommand.NAME = "RemoveCommand"


--[[--*
* 对一个角色进行高斯模糊
* @param roleId 执行动作的角色id
--]]
function RemoveCommand:New(roleId)
    local this = {}
    setmetatable( this, {__index = RemoveCommand} )
    this.roles = {}
    table.insert( self.roles,{roleId = roleId} )
    return this
end


function RemoveCommand:RemoveZorder(roleId, zorder)
	table.insert( self.roles,{roleId = roleId, zorder = zorder} )
end


--[[
--执行方法的虚方法
--真实调用的方法逻辑
--执行窗口抖动
--]]
function RemoveCommand:Execute( )
    --执行方法的虚方法
    
end

return RemoveCommand