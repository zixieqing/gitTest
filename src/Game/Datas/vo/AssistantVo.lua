local AssistantVo = {}
local Vo = require('Game.Datas.Vo')
function AssistantVo:New( params, key )
	local this = {}
	setmetatable(AssistantVo, {__index = Vo})
	setmetatable(this, {__index = AssistantVo})
	this:Initail(params, key)
	return this 
end
function AssistantVo:Initail( params, key )
	self.data = params
	self.id = checkint(key)
end

function AssistantVo:GetId()
	return self.id
end

function AssistantVo:ToString()
	return tableToString(self)
end
return AssistantVo