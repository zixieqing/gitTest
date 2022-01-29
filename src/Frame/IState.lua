--[[
状态机的抽象状态类
--]]
local IState = class('IState')

function IState:ctor( stateId )
	self.stateId = stateId
    self.events = {[tostring(States.EID_COMPELETE)] = States.EID_COMPELETE}
    self.fsm = nil
end

function IState:SetFSM(fsm)
    self.fsm = fsm
end

function IState:AddEvent(eventId)
    if not self.events[tostring(eventId)] then
        self.events[tostring(eventId)] = eventId
    end
end
--[[
--是否存在事件id
--]]
function IState:HasEvent(eventId)
    return (self.events[tostring(eventId)] ~= nil )
end

--[[
--状态关注的事件的逻辑
--]]
function IState:OnEvent(eventId, ...)

end

function IState:Before(owner)
	--设置相关的参数
end

function IState:ChangeState(stateId)
    if self.fsm then
        self.fsm:ChangeState(stateId)
    end
end

--[[
--暂停逻辑
--]]
function IState:Pause(owner)
    
end

--[[
拷贝相关的状态机
--]]
function IState:CopySate(owner)

end

function IState:Update(owner)
	--更新逻辑
end

function IState:Leave(owner)
	--设置相关的参数
end

return IState
