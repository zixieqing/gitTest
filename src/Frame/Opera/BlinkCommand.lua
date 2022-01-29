local Command = require( 'Frame.Opera.Command' )

local Director = require( "Frame.Opera.Director" )

local BlinkCommand = Command:New()

BlinkCommand.NAME = "BlinkCommand"


--[[--*
* 对某个角色执行闪烁效果
* @param roleId 执行动作的角色id
* @param times 闪的次数
* @param time 闪的时间
--]]
function BlinkCommand:New(roleId, times, time)
    local this = {}
    setmetatable( this, {__index = BlinkCommand} )
    this.roleId = roleId
    this.times = times --执行的时间间隔
    this.time  = time
    return this
end


function BlinkCommand:CanMoveNext( )
    return false
end
--[[
--执行方法的虚方法
--真实调用的方法逻辑
--执行窗口抖动
--]]
function BlinkCommand:Execute( )
    --执行方法的虚方法
    local roleInfo = Director.GetInstance( "Director" ):GetRole(self.roleId)
    if roleInfo and roleInfo.role then
    	roleInfo.role:runAction(cc.Sequence:create(cc.Blink:create(self.time,self.times),
            cc.DelayTime:create(0.1), cc.CallFunc:create(function()
                self:Dispatch("DirectorStory","next")
            end)))
    end
end

return BlinkCommand