local Command = require( 'Frame.Opera.Command' )

local Director = require( "Frame.Opera.Director" )

local FadeCommand = Command:New()

FadeCommand.NAME = "FadeCommand"


--[[--*
* 等待多少秒再继续执行剧情
* @param roleId 执行动作的角色id
* @param isIn 是否需要点击才执行接下来的动作
--]]
function FadeCommand:New(roleId, time, isIn)
    local this = {}
    setmetatable( this, {__index = FadeCommand} )
    this.roleId = roleId
    this.time = time --执行的时间间隔
    this.isIn = (isIn == nil and true or isIn) --是否执行显示或者是隐藏
    return this
end


--[[
--执行方法的虚方法
--真实调用的方法逻辑
--执行窗口抖动
--]]
function FadeCommand:Execute( )
    --执行方法的虚方法
    local roleInfo = Director.GetInstance( "Director" ):GetRole(self.roleId)
    if roleInfo and roleInfo.role then
    	if self.isIn then
    		roleInfo.role:runAction(cc.FadeIn:create(self.time))
    	else
    		roleInfo.role:runAction(cc.FadeOut:create(self.time))
    	end
    end
end

return FadeCommand