local FSMState = class('FSMState')


--[[
--初始化一个状态机
--@owner 拥有者 
--@startState 初始的状态
--]]
function FSMState:ctor(owner, startState)
    self.owner    = owner
    self.curState = startState
    self.preState = nil --是否有存在的意义
    self.isActive = true
	self.states   = {startState}
    startState:SetFSM(self)
    startState:Before(owner) -- 手动启动下第一个效果
end

function FSMState.Clear( )
    self.states = {}
end

function FSMState:AutoPlay()
    return self.owner:AutoPlay()
end

--[[
--是否是在活跃中
--]]
function FSMState:IsActive()
    return self.isActive
end

function FSMState:DeActive()
    self.isActive = false
end

function FSMState:HasState(stateId)
    local state = nil
    for name,val in pairs(self.states) do
        if checkint(val.stateId) == checkint(stateId) then
            state = val
            break
        end
    end
    return (state ~= nil)
end

function FSMState:GetState(stateId)
    local state = nil
    for name,val in pairs(self.states) do
        if checkint(val.stateId) == checkint(stateId) then
            state = val
            break
        end
    end
    return state
end

--[[
*添加一个状态对象
@istate --一个istate的对象
--]]
function FSMState:AddState( istate )
    if not self:HasState(istate.stateId) then
        istate:SetFSM(self)
        table.insert( self.states,istate )
    end
end

--[[
--发送状态机事件逻辑
--@eventId 事件id
--]]
function FSMState:DispatchEvent(eventId, ...)
    if not self.isActive then
        funLog(Logger.DEBUG, "当前不在激活状态")
    else
        if self.curState:HasEvent(eventId) then
            self.curState:OnEvent(eventId, ...)
        end
    end
end

--[[
--是否是当前的状态
--]]
function FSMState:IsCurrentState(stateId)
    if not self.isActive then
        funLog(Logger.DEBUG, "当前处于不活跃状态")
        return false
    else
        return (self.curState.stateId == stateId)
    end
end

function FSMState:ChangeState( stateId )
    if not self:HasState(stateId) then
        funLog(Logger.ERROR, "要切换的状态不存在")
    else
        local state = self:GetState(stateId)
        if state then
            self.curState:Leave(self.owner) --当前状态移除
            self.curState = state
            state:Before(self.owner)
        end
    end
end

function FSMState:Update( dt )
    if #states > 0 and self.isActive then
        if self.curState then self.curState:Update(self.owner) end
    end
end

return FSMState
