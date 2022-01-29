local EnemyVo = {}
local Vo = require('Game.Datas.Vo')
function EnemyVo:New( params, key )
	local this = {}
	setmetatable(EnemyVo, {__index = Vo})
	setmetatable(this, {__index = EnemyVo})
	this:Initail(params, key)
	return this 
end

function EnemyVo:Initail( params, key )
	self.data = params
	self.id = checkint(key)
end

function EnemyVo:GetId()
	return self.id
end

function EnemyVo:ToString()
	return tableToString(self)
end

return EnemyVo