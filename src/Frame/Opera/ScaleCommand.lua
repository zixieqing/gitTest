local Command = require( 'Frame.Opera.Command' )

local Director = require( "Frame.Opera.Director" )

local ScaleCommand = Command:New()

ScaleCommand.NAME = "ScaleCommand"


--[[--*
* 对某个角色执行闪烁效果
* @param roleId 执行动作的角色id
* @param x
* @param y y轴上的放大倍率
* @param time 闪的时间
--]]
function ScaleCommand:New(roleId, x, y, time)
    local this = {}
    setmetatable( this, {__index = ScaleCommand} )
    this.roleId = roleId
    this.x = x --放大到多少倍率
    this.y = y -- y方向上的方大倍率
    this.time  = time
    return this
end


--[[
--执行方法的虚方法
--真实调用的方法逻辑
--执行窗口抖动
--]]
function ScaleCommand:Execute( )
    --执行方法的虚方法
    local roleInfo = Director.GetInstance( "Director" ):GetRole(self.roleId)
    if roleInfo and roleInfo.role then
    	roleInfo.role:runAction(cc.ScaleTo:create(self.time, self.x, self.y))
    end
end

return ScaleCommand