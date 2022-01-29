local SkillLevelVo = {}
local Vo = require('Game.Datas.Vo')
function SkillLevelVo:New(params, key)
	local this = {}
	setmetatable(SkillLevelVo, {__index = Vo})
	setmetatable(this, {__index = SkillLevelVo})
	this:Initail(params, key)
	return this 
end
function SkillLevelVo:Initail( params, key )
	self.data = params
	self.data.level = checkint(key)
end
function SkillLevelVo:GetId()
	return self.data.level
end

function SkillLevelVo:ToString( )
	return tableToString(self)
end


return SkillLevelVo