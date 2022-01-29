local Command = require( 'Frame.Opera.Command' )

local Director = require( "Frame.Opera.Director" )

local CollisionCommand = Command:New()

CollisionCommand.NAME = "CollisionCommand"


--[[--*
* 两个角色相互靠近功能操作
* @param ids 执行动作的角色id
--]]
function CollisionCommand:New(ids)
    local this = {}
    setmetatable( this, {__index = CollisionCommand} )
    this.ids = ids or {}
    this.inAction = true
    return this
end

--[[
* 是否可以进行下一步
* @return 初始是可以进行下一步操作
--]]
function CollisionCommand:CanMoveNext( )
	return false 
end
--[[
--执行方法的虚方法
--真实调用的方法逻辑
--执行窗口抖动
--]]
function CollisionCommand:Execute( )
    --执行方法的虚方法
    local director = Director.GetInstance( )
    local stage    = director:GetStage()
    local infoOne = director:GetRole(self.ids[1])
    local infoTwo = director:GetRole(self.ids[2])

    local left,right = nil, nil
    if infoOne.pos == "left" then
        left = infoOne.role
        right = infoTwo.role
    else
        left = infoTwo.role
        right = infoOne.role
    end
    local lx, ly = left:getPosition()
    local rx, ry = right:getPosition()
    offsetW = (rx - lx) / 2
    local actions = {}
    table.insert( actions, cc.Spawn:create(cc.TargetedAction:create(left, cc.Sequence:create(cc.EaseOut:create(cc.MoveTo:create(0.4,cc.p(lx + offsetW, ly)), 0.4),
        ShakeAction:create(0.4,6,2),
        cc.EaseOut:create(cc.MoveTo:create(0.2, cc.p(lx,ly)), 0.2))),
        cc.TargetedAction:create(right, cc.Sequence:create(cc.EaseOut:create(cc.MoveTo:create(0.4,cc.p(rx - offsetW, ry)),0.4),
        ShakeAction:create(0.4,6,2),
        cc.EaseOut:create(cc.MoveTo:create(0.2, cc.p(rx,ry)), 0.2)))))
    table.insert( actions, cc.CallFunc:create(function()
        self.inAction = false
        self:Dispatch("DirectorStory","next")
    end) )
    stage:runAction(cc.Sequence:create(actions))
end

return CollisionCommand