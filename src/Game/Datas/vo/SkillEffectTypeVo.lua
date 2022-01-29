local SkillEffectTypeVo = {}
local Vo = require('Game.Datas.Vo')
function SkillEffectTypeVo:New( params, key )
	local this = {}
	setmetatable(SkillEffectTypeVo, {__index = Vo})
	setmetatable(this, {__index = SkillEffectTypeVo})
	this:Initail(params, key)
	return this 
end

function SkillEffectTypeVo:Initail( params, key )
	self.data = params
	self.id = checkint(key)
end

function SkillEffectTypeVo:GetId()
	return self.id
end

function SkillEffectTypeVo:ToString()
	return tableToString(self)
end

return SkillEffectTypeVo