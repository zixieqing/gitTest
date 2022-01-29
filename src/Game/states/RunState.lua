--[[
--走动的逻辑状态逻辑
--]]
local IState = require('Frame.IState')

local RunState = class('RunState',IState )

function RunState:ctor( stateId )
    self.super.ctor(self, stateId)
end
--[[
--状态关注的事件的逻辑
--]]
function RunState:OnEvent(eventId, ...)

end

function RunState:Before(owner)
	--设置相关的参数
    owner.viewData.qAvatar:setAnimation(0, 'run', true)
end

--[[
--暂停逻辑
--]]
function RunState:Pause(owner)
end

--[[
拷贝相关的状态机
--]]
function RunState:CopySate(owner)

end

function RunState:Update(owner)
	--更新逻辑
end

function RunState:Leave(owner)
	--设置相关的参数
    owner.viewData.qAvatar:setToSetupPose()
end

return RunState
