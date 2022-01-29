local Command = require( 'Frame.Opera.Command' )

local Director = require( "Frame.Opera.Director" )

local OpacityCommand = Command:New()

OpacityCommand.NAME = "OpacityCommand"


--[[--*
* 对一个角色进行透明度的逻辑处理
* @param roleId 执行动作的角色id
* @param opacity 执行动作的角色id
--]]
function OpacityCommand:New(roleId, opacity)
    local this = {}
    setmetatable( this, {__index = OpacityCommand} )
    this.opacity = opacity
    return this
end

--[[
--执行方法的虚方法
--真实调用的方法逻辑
--执行窗口抖动
--]]
function OpacityCommand:Execute( )
    --执行方法的虚方法
    local roleInfo = Director.GetInstance( "Director" ):GetRole(self.roleId)
    if roleInfo and roleInfo.role then
    	roleInfo.role:setOpacity(checkint(self.opacity))
    end
end

return OpacityCommand