local Command = require( 'Frame.Opera.Command' )

local Director = require( "Frame.Opera.Director" )

local ExitStageCommand = Command:New()

ExitStageCommand.NAME = "ExitStageCommand"

--[[--*
* 两个角色相互靠近功能操作
* @param ids 执行动作的角色id
--]]
function ExitStageCommand:New(ids, direction)
    local this = {}
    setmetatable( this, {__index = ExitStageCommand} )
    if type(ids) ~= 'table' then
        ids = {ids}
    end
    this.ids = ids or {}
    this.direction = direction or "left"
    this.inAction = true
    return this
end

--[[
--直到一个人物进入完成后才能够下
--一步的操作
--]]
function ExitStageCommand:CanMoveNext()
    return false
end
--[[
--执行方法的虚方法
--真实调用的方法逻辑
--执行窗口抖动
--]]
function ExitStageCommand:Execute( )
    --执行方法的虚方法
    local director = Director.GetInstance( )
    local stage    = director:GetStage()
    if #self.ids == 1 then
        local id = self.ids[1]
        local roleInfo = director:GetRole(id)
        if roleInfo and roleInfo.role then
            local offsetX = 150
            local spanW   = 440
            if self.direction  == 'left' then
               offsetX = -150
               spanW   = -440
            elseif self.direction == 'right' then
                offsetX = 150
                spanW = display.width + spanW
            end
            local action = cc.RepeatForever:create(
                cc.Sequence:create(cc.EaseIn:create(cc.MoveBy:create(0.7,cc.p(offsetX, 0)), 0.7),
                cc.DelayTime:create(0.4), cc.CallFunc:create(function()
                    local x = roleInfo.role:getPositionX()
                    if self.direction == 'left' then
                        if x < spanW then
                            director:PopRole(id)
                            self.inAction = false
                            self:Dispatch("DirectorStory","next")
                        end
                    elseif self.direction == 'right' then
                        if x > spanW then
                            director:PopRole(id)
                            self.inAction = false
                            self:Dispatch("DirectorStory","next")
                        end
                    end
                end)))
            roleInfo.role:runAction(action)
        end
    elseif #self.ids == 2 then
        local roleone = director:GetRole(self.ids[1])
        local roletwo = director:GetRole(self.ids[2])
        if roleone and roletwo and roleone.role and roletwo.role then
            local x1 = roleone.role:getPositionX()
            local x2 = roletwo.role:getPositionX()
            local offsetX = 150
            local spanW   = 440
            local left, right = nil
            if self.direction  == 'left' then
                spanW   = -440
                right = roleone.role
                left = roletwo.role
                if x1 < x2 then
                    right = roletwo.role
                    left = roleone.role
                end
            elseif self.direction == 'right' then
                spanW = display.width + spanW
                left = roletwo.role
                right = roleone.role
                if x1 < x2 then
                    left = roleone.role
                    right = roletwo.role
                end
            end
            if self.direction == 'left' then
                local lx, ly = left:getPosition()
                local rx, ry = right:getPosition()
                local actions = {
                    cc.TargetedAction:create(right, cc.MoveTo:create(0.5,cc.p(left:getPositionX() + left:getContentSize().width * 0.2, left:getPositionY())))
                }
                local len = math.floor((display.width + lx * 2) / offsetX)
                for i=1,len do
                    local xx = lx -  i * offsetX
                    table.insert( actions, cc.Spawn:create(cc.TargetedAction:create(left, cc.EaseIn:create(cc.MoveTo:create(0.5,cc.p(xx, ly)), 0.5)),
                        cc.TargetedAction:create(right, cc.EaseIn:create(cc.MoveTo:create(0.5,cc.p(xx + left:getContentSize().width * 0.2, ry)), 0.5)), cc.DelayTime:create(0.4)) )
                end
                table.insert( actions, cc.CallFunc:create(function()
                    director:PopRole(self.ids[1])
                    director:PopRole(self.ids[2])
                    self.inAction = false
                    self:Dispatch("DirectorStory","next")
                end) )
                stage:runAction(cc.Sequence:create(actions))
            else
                local lx, ly = left:getPosition()
                local rx, ry = right:getPosition()
                local actions = {
                    cc.TargetedAction:create(left, cc.MoveTo:create(0.5,cc.p(right:getPositionX() - right:getContentSize().width * 0.2, right:getPositionY())))
                }
                local len = math.floor((display.width + lx * 2) / offsetX)
                for i=1,len do
                    local xx = rx + i * offsetX
                    table.insert( actions, cc.Spawn:create(cc.TargetedAction:create(right, cc.EaseIn:create(cc.MoveTo:create(0.5,cc.p(xx, ry)), 0.5)),
                        cc.TargetedAction:create(left, cc.EaseIn:create(cc.MoveTo:create(0.5,cc.p(xx - right:getContentSize().width * 0.2, ly)), 0.5)), cc.DelayTime:create(0.4)) )
                end
                table.insert( actions, cc.CallFunc:create(function()
                    director:PopRole(self.ids[1])
                    director:PopRole(self.ids[2])
                    self.inAction = false
                    self:Dispatch("DirectorStory","next")
                end) )
                stage:runAction(cc.Sequence:create(actions))
            end
        end
    end
    
end

return ExitStageCommand