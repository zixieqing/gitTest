local LevelVo = {}
local Vo = require('Game.Datas.Vo')
function LevelVo:New(params)
	local this = {}
	setmetatable(LevelVo, {__index = Vo})
	setmetatable(this, {__index = LevelVo})
	this:Initail(params)
	return this 
end
function LevelVo:GetId()
	return self.data.level
end

function LevelVo:ToString( )
	return tableToString(self)
end

return LevelVo