local StoveQueueVo = {}
local Vo = require('Game.Datas.Vo')
function StoveQueueVo:New( params, key )
	local this = {}
	setmetatable(StoveQueueVo, {__index = Vo})
	setmetatable(this, {__index = StoveQueueVo})
	this:Initail(params, key)
	return this 
end
function StoveQueueVo:Initail( params, key )
	self.data = params
	self.id = checkint(key)
end

function StoveQueueVo:GetId()
	return self.id
end

function StoveQueueVo:ToString()
	return tableToString(self)
end
return StoveQueueVo