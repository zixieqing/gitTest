---@class Dispatch
local Dispatch = class('Dispatch')


Dispatch.MULTITON_MSG = "mvc: multitonKey for this Notifier not yet initialized!";


function Dispatch:ctor()
end


---@param key string
function Dispatch:Initial(key )
	---@type string
	self.targetKey = key
	---@type Facade
	self.facade = self:GetFacade()
end


--[[
分发消息
--]]
---@param signalName string
---@param body? any
---@param type? any
function Dispatch:SendSignal( signalName, body, type )
	if self.facade ~= nil then
		self.facade:DispatchSignal(signalName, body, type)
	end
end


---@return Facade
function Dispatch:GetFacade(  )
	if self.targetKey == nil then
        error(Dispatch.MULTITON_MSG)
	end
	---@type Facade
	return mvc.Facade.GetInstance(self.targetKey)
end


return Dispatch
