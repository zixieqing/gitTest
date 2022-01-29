local Command = require( 'Frame.Opera.Command' )

local Director = require( "Frame.Opera.Director" )

local FlipCommand = Command:New()

FlipCommand.NAME = "FlipCommand"


--[[--*
* 对一个角色进行透明度的逻辑处理
* @param id 执行动作的角色id
* @param x x flip
* @param y y flip
--]]
function FlipCommand:New(id, x, y)
    local this = {}
    setmetatable( this, {__index = FlipCommand} )
    this.id = id 
    this.flipx = (x or 1)
    this.flipx = (x or 1)
    return this
end
--[[
--执行方法的虚方法
--真实调用的方法逻辑
--执行窗口抖动
--]]
function FlipCommand:Execute( )
    --执行方法的虚方法
    local roleInfo = Director.GetInstance( ):GetRole(self.id)
    if roleInfo and roleInfo.role then
        roleInfo.role:setScaleX(-1)
        roleInfo.role:setScaleY(-1)
    end
end

return FlipCommand
