local Command = require( 'Frame.Opera.Command' )

local Director = require( "Frame.Opera.Director" )

local MoveCommand = Command:New()

MoveCommand.NAME = "MoveCommand" --移除动作执行功能


--[[--*
* id 角色或者背景的对象
* @param id 角色或者背景的对象
* @param x 要移动到的x位置
* @param y 要移动到的y位置
* @param time 移动完成的时间
--]]
function MoveCommand:New(id, x, y, time, reverse)
	local this = {}
	setmetatable( this, {__index = MoveCommand} )
	this.id = id
	this.x = x
	this.y = y
	this.time = time
    this.reverse = (reverse or false)
    this.inAction = true
	return this
end
--[[
--直到一个人物进入完成后才能够下
--一步的操作
--]]
function MoveCommand:CanMoveNext()
    return false
end
--[[
--执行方法的虚方法
--真实调用的方法逻辑
--执行窗口抖动
--]]
function MoveCommand:Execute( )
	--执行方法的虚方法
    local director = Director.GetInstance( "Director" )
    local roleInfo = director:GetRole(self.id)
    if roleInfo and roleInfo.role then
        if self.reverse then
            local x, y = display.cx, display.cy
            roleInfo.role:runAction(cc.Sequence:create(cc.EaseOut:create(cc.MoveTo:create(self.time , cc.p(x + self.x, y + self.y)),self.time),
            cc.EaseIn:create(cc.MoveTo:create(self.time, cc.p(x - self.x, y - self.y)), self.time ), cc.EaseIn:create(cc.MoveTo:create(self.time, cc.p(x, y)), self.time)))
        else
            roleInfo.role:runAction(cc.Sequence:create(cc.EaseOut:create(cc.MoveTo:create(self.time,cc.p(self.x, self.y)), self.time), cc.CallFunc:create(function()
                if self.x > display.width or self.x < 0 then
                    director:PopRole(self.id)
                end
                local nameBg = roleInfo.role:getChildByTag(7654)
                if nameBg then
                    nameBg:setVisible(true)
                end
                self:Dispatch("DirectorStory","next")
                -- self.inAction = false
            end)))
        end
    else
        self:Dispatch("DirectorStory","next")
    end
end

return MoveCommand
