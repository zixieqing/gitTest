--[[
--死亡的逻辑状态逻辑
--]]
local IState = require('Frame.IState')

local DieState = class('DieState',IState )

function DieState:ctor( stateId )
    self.super.ctor(self, stateId)
end
--[[
--状态关注的事件的逻辑
--]]
function DieState:OnEvent(eventId, ...)

end

function DieState:Before(owner)
	--设置相关的参数
end

--[[
--暂停逻辑
--]]
function DieState:Pause(owner)
end

--[[
拷贝相关的状态机
--]]
function DieState:CopySate(owner)

end

function DieState:Update(owner)
	--更新逻辑
end

function DieState:Leave(owner)
	--设置相关的参数
end

return DieState
