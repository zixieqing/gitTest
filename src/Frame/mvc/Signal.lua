---@class Signal
local Signal = class("Signal")


---@param name string
---@param body? any
---@param type? any
function Signal:ctor( name,body,type )
	self.name = name
	self.body = body
	self.type = type
end


---@return string
function Signal:GetName( )
	return self.name
end


---@param body any
function Signal:SetBody( body )
	self.body = body
end


---@return any
function Signal:GetBody(  )
	return self.body
end


---@param type any
function Signal:SetType( type )
	self.type = type
end


---@return any
function Signal:GetType(  )
	return self.type
end


function Signal:ToString(  )
	local msg = "Signal Name: " .. self:GetName()
	msg = msg .. "\nBody: " .. tostring(self:GetBody())
	msg = msg .. "\nType: " .. tostring(self:GetType())
	return msg
end


return Signal
