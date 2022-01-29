---@class ModelGroup
local ModelGroup = class("ModelGroup")


---@type table<string, ModelGroup>
ModelGroup.instances = {}



---@param key string
function ModelGroup:ctor( key )
    if ModelGroup.instances[key] ~= nil then
		funLog(Logger.INFO, "注册相关的 mvc.ModelGroup 类型" )
		return
	end
    ---@type string
    self.targetKey = key
    ---@type table<string, Proxy>
    self.proxyMap = {}
    ModelGroup.instances[self.targetKey] = false
    self:InitalizeModel()
end


function ModelGroup:InitalizeModel()
end


---@param key string
---@return ModelGroup
function ModelGroup.GetInstance( key)
	if not key then return nil end
	if not ModelGroup.instances[tostring( key )] then
		return ModelGroup.new(key)
	else
		return ModelGroup.instances[key]
	end
end


---@param proxyName string
---@return Proxy
function ModelGroup:RetrieveProxy(proxyName)
    return self.proxyMap[proxyName]
end


---@param proxyName string
---@return boolean
function ModelGroup:HasProxy(proxyName)
    return self:RetrieveProxy(proxyName) ~= nil
end


---@param proxy Proxy
function ModelGroup:RegistProxy(proxy)
    if not self:HasProxy(proxy:getName()) then
        self.proxyMap[proxy:getName()] = proxy
        proxy:Initial(self.targetKey)
        proxy:onRegist()
    end
end


---@param proxyName string
---@return Proxy
function ModelGroup:UnRegistProxy(proxyName)
    local proxy = self:RetrieveProxy(proxyName)
    if proxy then
        self.proxyMap[proxyName] = nil
        proxy:onUnRegist()
    end
    return proxy
end


---@param key string
function ModelGroup.Destroy(key)
    ModelGroup.instances[key] = nil
end


return ModelGroup
