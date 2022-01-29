local QualityVo = {}
local Vo = require('Game.Datas.Vo')
function QualityVo:New(params)
	local this = {}
	setmetatable(QualityVo, {__index = Vo})
	setmetatable(this, {__index = QualityVo})
	this:Initail(params)
	return this 
end
function QualityVo:GetId()
	return self.data.qualityId
end

function QualityVo:ToString(  )
	return tableToString(self)
end

return QualityVo