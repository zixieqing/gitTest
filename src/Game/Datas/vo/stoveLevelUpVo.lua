local SkillLevelUpVo = {}
local Vo = require('Game.Datas.Vo')
function SkillLevelUpVo:New(params, key)
	local this = {}
	setmetatable(SkillLevelUpVo, {__index = Vo})
	setmetatable(this, {__index = SkillLevelUpVo})
	this:Initail(params, key)
	return this 
end
function SkillLevelUpVo:Initail( params, key )
	self.data = params
	self.data.level = checkint(key)
end
function SkillLevelUpVo:GetId()
	return self.data.level
end

function SkillLevelUpVo:ToString( )
	return tableToString(self)
end


return SkillLevelUpVo