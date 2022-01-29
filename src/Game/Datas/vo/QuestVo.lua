local QuestVo = {}
local Vo = require('Game.Datas.Vo')
function QuestVo:New(params)
	local this = {}
	setmetatable(QuestVo, {__index = Vo})
	setmetatable(this, {__index = QuestVo})
	this:Initail(params)
	return this 
end


function QuestVo:ToString( )
	return tableToString(self)
end

function QuestVo:GetId()
	return self.data.id
end

return QuestVo