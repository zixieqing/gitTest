--[[
--胜利的逻辑状态逻辑
--]]
local IState = require('Frame.IState')

local WinState = class('WinState',IState )

function WinState:ctor( stateId )
    self.super.ctor(self, stateId)
end
--[[
--状态关注的事件的逻辑
--]]
function WinState:OnEvent(eventId, ...)

end

function WinState:Before(owner)
	--设置相关的参数
	owner.viewData.qAvatar:setAnimation(0, 'win', true)
end

--[[
--暂停逻辑
--]]
function WinState:Pause(owner)
end

--[[
拷贝相关的状态机
--]]
function WinState:CopySate(owner)

end

function WinState:Update(owner)
	--更新逻辑
end

function WinState:Leave(owner)
	--设置相关的参数
	owner.viewData.qAvatar:setToSetupPose()
end

return WinState
