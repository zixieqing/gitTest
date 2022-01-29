--[[
--攻击的逻辑状态逻辑
--]]
local IState = require('Frame.IState')

local AttackState = class('AttackState',IState )

function AttackState:ctor( stateId )
    self.super.ctor(self, stateId)
end
--[[
--状态关注的事件的逻辑
--]]
function AttackState:OnEvent(eventId, ...)

end

function AttackState:Before(owner)
	--设置相关的参数
end

--[[
--暂停逻辑
--]]
function AttackState:Pause(owner)
end

--[[
拷贝相关的状态机
--]]
function AttackState:CopySate(owner)

end

function AttackState:Update(owner)
	--更新逻辑
end

function AttackState:Leave(owner)
	--设置相关的参数
end

return AttackState
