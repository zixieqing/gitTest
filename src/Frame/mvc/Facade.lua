---@class Facade
local Facade = class("Facade")


---@type table<string, Facade>
Facade.instances = {}


---@type Controller
local Controller = mvc.Controller
---@type ViewManager
local ViewManager = mvc.ViewManager
---@type ModelGroup
local ModelGroup = mvc.ModelGroup


---@param key string
function Facade:ctor( key )
	if Facade.instances[key] ~= nil then
		funLog(Logger.INFO, "注册相关的facade类型" )
		return
	end
	---@type string
	self.targetKey = key
	---@type ManagerBase[]
	self.managers = {} --所有的管理器
	Facade.instances[key] = self
	self:InitialFacade()
end


function Facade:InitialFacade(  )
	self:InitialModelGroup()
	self:InitialController()
	self:InitialViewManager()
end


function Facade:InitialViewManager( )
	if self.viewManager ~= nil then
		return
	end
	self.viewManager = ViewManager.GetInstance(self.targetKey)
end


function Facade:InitialController(  )
	if self.controller ~= nil then
		return
	end
	self.controller = Controller.GetInstance(self.targetKey)
end


function Facade:InitialModelGroup(  )
	if self.modelGroup ~= nil then
		return
	end
	self.modelGroup = ModelGroup.GetInstance(self.targetKey)
end


---@return Facade
function Facade.GetInstance( key )
	if nil == key then
		return nil
	end
	if Facade.instances[key] == nil then
		Facade.instances[key] = Facade.new(key)
	end
	return Facade.instances[key]
end


---@param key string
function Facade:HasInstance( key )
	return Facade.instances[key] ~= nil
end

function Facade:CanGoogleBack()
    local canBack = false
    local len = table.nums(self.viewManager.mediatorMap)
    -- for name,val in pairs(self.viewManager.mediatorStack) do
        -- print(name, val)
    -- end
    if len > 2 then
        canBack = true
    end
    return canBack
end

--[[
清除指定的facade实例
@param key 指定的key类型
]]
---@param key string
function Facade.Destroy( key )
	if Facade.instances[key] == nil then
		return
	end
    local instance = Facade.instances[tostring(key)]
	for k, manager in pairs( instance.managers ) do
		manager.Destroy()
	end
	ViewManager.Destroy(key)
	Controller.Destroy(key)
	ModelGroup.Destroy(key)
	Facade.instances[key] = nil
    _G['CommonUtils'] = nil
    _G['app'] = nil
end


-------------------------------------------------------------------------------
-- control about
-------------------------------------------------------------------------------

---@param signalName string
---@param commandClassRef SimpleCommand | QueueCommand
function Facade:RegistSignal( signalName, commandClassRef )
	self.controller:RegistSignal(signalName, commandClassRef)
end


---@param signalName string
---@return boolean
function Facade:HasSignal( signalName )
	return self.controller:HasSignal(signalName)
end


---@param signalName string
function Facade:UnRegistSignal( signalName )
	self.controller:UnRegistSignal(signalName)
end


---@param signalName string
---@param body? any
---@param type? any
function Facade:DispatchSignal( signalName, body, type )
	if self.controller then
		self.controller:ExecuteSignal(mvc.Signal.new(signalName, body, type))
	end
end


-------------------------------------------------------------------------------
-- model about
-------------------------------------------------------------------------------

---@param proxyName string
---@return boolean
function Facade:HasProxy( proxyName )
	return self.modelGroup:HasProxy(proxyName)
end


---@param proxyName string
---@return Proxy
function Facade:RetrieveProxy( proxyName )
	return self.modelGroup:RetrieveProxy(proxyName)
end


---@param proxy Proxy
function Facade:RegistProxy( proxy )
	self.modelGroup:RegistProxy(proxy)
end


---@param proxyName string
function Facade:UnRegistProxy( proxyName )
	self.modelGroup:UnRegistProxy(proxyName)
end


-------------------------------------------------------------------------------
-- view aobut
-------------------------------------------------------------------------------

--[[
--回到某一个页面
--@mediatorName
--]]
---@param mediatorName string
function Facade:BackMediator( mediatorName )
    if not mediatorName then mediatorName = 'HomeMediator' end
    if self:HasMediator(mediatorName) then
        --已经在堆栈中
        self.viewManager:BackMediator(mediatorName)
    else
        --先清除已有的东西
        local upgradeLevelMediator = self.viewManager:ClearStack()
        local mediatorPath = require( string.format('Game.mediator.%s', mediatorName))
        local mediator = mediatorPath.new()
        self:RegistMediator(mediator)
        if upgradeLevelMediator then
			self:UnRegistMediator(upgradeLevelMediator)
        end
    end
end


---@param homeArgs table
function Facade:BackHomeMediator(homeArgs)
    local upgradeLevelMediator = self.viewManager:ClearStack()
    local mediatorPath = require( string.format('Game.mediator.%s', 'HomeMediator'))
    local mediator = mediatorPath.new(homeArgs)
    self:RegistMediator(mediator)
    if upgradeLevelMediator then
		self:UnRegistMediator(upgradeLevelMediator)
    end
end


--[[
--弹出一个页面，有可能直接回到根节点
--@isRoot
--]]
---@param isRoot? boolean
function Facade:PopMediator(isRoot)
    if not isRoot then isRoot = false end
    if self.viewManager then
        self.viewManager:PopMediator(isRoot)
    end
end


--[[
注册mediator
--]]
---@param mediator Mediator
function Facade:RegistMediator( mediator )
	if self.viewManager then
		self.viewManager:RegistMediator(mediator)
	end
end


---@param mediatorName string
---@return Mediator
function Facade:RetrieveMediator( mediatorName )
	if self.viewManager then
		return self.viewManager:RetrieveMediator(mediatorName)
	end
end


---@param mediatorName string
---@return Mediator
function Facade:UnRegistMediator( mediatorName )
	local mediator = nil
	if self.viewManager then
		mediator = self.viewManager:UnRegistMediator(mediatorName)
	end
	return mediator
end


---@param mediatorName string
---@return boolean
function Facade:HasMediator( mediatorName )
	return self.viewManager:HasMediator(mediatorName)
end


---@return integer
function Facade:GetMediatorStackNum()
	return self.viewManager and self.viewManager:GetMediatorStackNum() or 0
end


-------------------------------------------------------------------------------
-- 分发事件
-------------------------------------------------------------------------------

---@param signalName string
---@param body? any
---@param type? any
function Facade:DispatchObservers(signalName,body, type)
	if self.viewManager then
		self.viewManager:DispatchObservers(mvc.Signal.new(signalName, body, type))
	end
end


---@param signalName string
---@param notifyContext any
function Facade:UnRegistObserver( signalName, notifyContext )
	if self.viewManager then
		self.viewManager:UnRegistObserver(signalName, notifyContext)
	end
end


---@param signalName string
---@param observer Observer
function Facade:RegistObserver( signalName, observer )
	if self.viewManager then
		self.viewManager:RegistObserver(signalName, observer)
	end
end


-------------------------------------------------------------------------------
-- manager aobut
-------------------------------------------------------------------------------

--[[
添加管理器逻辑
@param filepath 管理器的路径类似 Frame.AudioManager
--]]
---@param filepath string
---@return ManagerBase
function Facade:AddManager( filepath )
	local t = string.split(filepath, ".")
	local targetName = t[#t]
	funLog(Logger.INFO, "AddManager targetName = " .. targetName )
	if self.managers[targetName] then
		return self.managers[targetName]
	else
		local manager = require(filepath).GetInstance()
		if manager then
			self.managers[targetName] = manager
		end
		return manager
	end
end


--[[
查找指定的管理器
@param managerName 管理器的名字
@return 指定的管理器
--]]
---@param managerName string
---@return ManagerBase
function Facade:GetManager( managerName )
	return self.managers[managerName]
end


--[[
移除指定的管理器
@param managerName 管理器的名字
]]
---@param managerName string
function Facade:RemoveManager(managerName)
	funLog(Logger.INFO, "RemoveManager targetName = " .. managerName)
	local manager = self:GetManager(managerName)
	if manager then
		manager.Destroy()
	end
	self.managers[managerName] = nil
end


-------------------------------------------------------------------------------
-- deprecated api
-------------------------------------------------------------------------------

function Facade:UnRegsitSignal( signalName )
	self:UnRegistSignal(signalName)
end

function Facade:UnRegsitMediator( mediatorName )
	self:UnRegistMediator( mediatorName )
end


return Facade
