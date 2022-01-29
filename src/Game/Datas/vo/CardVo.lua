local CardVo = {}
local Vo = require('Game.Datas.Vo')
function CardVo:New(params)
	local this = {}
	setmetatable(CardVo, {__index = Vo})
	setmetatable(this, {__index = CardVo})
	this:Initail(params)
	return this 
end


function CardVo:ToString( )
	return tableToString(self)
end

function CardVo:GetId()
	return self.data.id
end

return CardVo
