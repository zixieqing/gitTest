local StoveQueueUnlockTypeVo = {}
local Vo = require('Game.Datas.Vo')
function StoveQueueUnlockTypeVo:New( params, key )
	local this = {}
	setmetatable(StoveQueueUnlockTypeVo, {__index = Vo})
	setmetatable(this, {__index = StoveQueueUnlockTypeVo})
	this:Initail(params, key)
	return this 
end
function StoveQueueUnlockTypeVo:Initail( params, key )
	self.data = params
	self.id = checkint(key) 
end

function StoveQueueUnlockTypeVo:GetId()
	return self.id
end

function StoveQueueUnlockTypeVo:ToString()
	return tableToString(self)
end
return StoveQueueUnlockTypeVo