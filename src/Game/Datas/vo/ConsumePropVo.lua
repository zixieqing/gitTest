local ConsumePropVo = {}
local Vo = require('Game.Datas.Vo')
function ConsumePropVo:New( params, key )
	local this = {}
	setmetatable(ConsumePropVo, {__index = Vo})
	setmetatable(this, {__index = ConsumePropVo})
	this:Initail(params, key)
	return this 
end

return ConsumePropVo