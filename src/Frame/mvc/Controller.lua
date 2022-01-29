---@class Controller
local Controller = class("Controller")


---@type table<string, Controller>
Controller.instances = {}


---@param key string
function Controller:ctor( key )
	if Controller.instances[key] ~= nil then
		funLog(Logger.INFO, "注册相关的 mvc.Controller 类型" )
		return
	end
	---@type string
	self.targetKey = key
	---@type table<string, SimpleCommand|QueueCommand>
	self.commandMap = {}
	Controller.instances[self.targetKey] = self
	self:InitialController()
end


function Controller:InitialController(  )
	---@type ViewManager
	self.viewManager = mvc.ViewManager.GetInstance(self.targetKey)
end


---@param key? string
---@return Controller
function Controller.GetInstance( key)
	if not key then return nil end
	if not Controller.instances[tostring( key )] then
		return Controller.new(key)
	else
		return Controller.instances[key]
	end
end


--[[
信号相关的逻辑
--]]
---@param signal Signal
function Controller:ExecuteSignal( signal )
	if not self:HasSignal(signal:GetName()) then
		funLog(Logger.INFO, '命令不存在' .. tostring(signal.name) )
		return
	end
	---@type SimpleCommand | QueueCommand
	local command = self.commandMap[signal:GetName()]
	-- local command = classRef.new()
	command:Initial(self.targetKey)
	command:Execute(signal)
end


---@param signalName string
---@param commandClassRef SimpleCommand | QueueCommand
function Controller:RegistSignal( signalName, commandClassRef )
	if self:HasSignal(signalName) then
		return
	end
	self.commandMap[signalName] = commandClassRef.new() --改为对象的逻辑
end


---@param signalName string
---@return boolean
function Controller:HasSignal( signalName )
	return (self.commandMap[signalName] ~= nil)
end


---@param signalName string
function Controller:UnRegistSignal( signalName )
	if self:HasSignal(signalName) then
		self.commandMap[signalName] = nil --清除已有命令
	else
		if DEBUG > 0 and signalName == nil then
			assert(false, ' Controller:UnRegistSignal > signalName : ' .. tostring(signalName))
		end
	end
end


---@param key string
function Controller.Destroy( key )
	Controller.instances[key] = nil
end


return Controller
