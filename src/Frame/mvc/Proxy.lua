---@class Proxy : Dispatch
local Proxy = class('Proxy', mvc.Dispatch)

Proxy.NAME = "Proxy"


---@param proxyName string
---@param data any
function Proxy:ctor(proxyName, data)
	mvc.Dispatch.ctor(self)
	self.proxyName = proxyName or Proxy.NAME
	if data ~= nil then
		self:setData(data)
	end
end


---@return string
function Proxy:getName()
	return self.proxyName
end


---@return any
function Proxy:getData()
    return self.data
end


---@param data any
function Proxy:setData(data)
	self.data = data
end


function Proxy:onRegist()
end


function Proxy:onUnRegist()
end


return Proxy
