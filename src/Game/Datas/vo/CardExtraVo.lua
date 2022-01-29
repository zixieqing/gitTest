local CardExtraVo = {}
local Vo = require('Game.Datas.Vo')
function CardExtraVo:New(params)
	local this = {}
	setmetatable(CardExtraVo, {__index = Vo})
	setmetatable(this, {__index = CardExtraVo})
	this:Initail(params)
	return this 
end
function CardExtraVo:GetId()
	return self.data.cardId
end

function CardExtraVo:ToString( )
	return tableToString(self)
end

return CardExtraVo