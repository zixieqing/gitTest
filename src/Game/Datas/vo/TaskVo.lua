local TaskVo = {}
local Vo = require('Game.Datas.Vo')
function TaskVo:New( params, key )
	local this = {}
	setmetatable(TaskVo, {__index = Vo})
	setmetatable(this, {__index = TaskVo})
	this:Initail(params, key)
	return this 
end

return TaskVo