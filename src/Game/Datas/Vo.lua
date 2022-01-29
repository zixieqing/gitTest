local Vo = {}

function Vo:New(params, key)
	local this = {}
	setmetatable( this, {__index = Vo} )
	this:Initail(params, key)
	return this 
end

function Vo:Initail( params , key )
	self.data = params
	self.id = tostring(key)
end

function Vo:GetId()
	return self.id
end

function Vo:GetData()
	return self.data
end

function Vo:ToString( )
	return tableToString(self)
end

return Vo