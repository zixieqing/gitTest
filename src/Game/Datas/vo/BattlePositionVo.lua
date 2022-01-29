local BattlePositionVo = {}
local Vo = require('Game.Datas.Vo')
function BattlePositionVo:New( params )
	local this = {}
	setmetatable(BattlePositionVo, {__index = Vo})
	setmetatable(this, {__index = BattlePositionVo})
	this:Initail(params, key)
	return this 
end

function BattlePositionVo:GetId()
	return self.data.positionId
end

function BattlePositionVo:ToString()
	return tableToString(self)
end

return BattlePositionVo