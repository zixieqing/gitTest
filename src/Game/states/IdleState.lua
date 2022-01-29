--[[
状态机的抽象状态类
--]]
local IState = require('Frame.IState')

local IdleState = class('IdleState',IState )

function IdleState:ctor( stateId )
    self.super.ctor(self, stateId)
end
--[[
--状态关注的事件的逻辑
--]]
function IdleState:OnEvent(eventId, ...)
    --动画播放完成是否自动进行下一步操作
    if self.fsm:AutoPlay() then
        self.fsm:ChangeState(States.ID_RUN)
    end
end

function IdleState:Before(owner)
	--设置相关的参数
    owner.viewData.qAvatar:setAnimation(0, 'idle', true)
end

--[[
--暂停逻辑
--]]
function IdleState:Pause(owner)
end

--[[
拷贝相关的状态机
--]]
function IdleState:CopySate(owner)

end

function IdleState:Update(owner)
	--更新逻辑
end

function IdleState:Leave(owner)
	--设置相关的参数
    --spine动画恢复到原始状态
    owner.viewData.qAvatar:setToSetupPose()
end

return IdleState
