local RecipeVo = {}
local Vo = require('Game.Datas.Vo')
function RecipeVo:New( params, key )
	local this = {}
	setmetatable(RecipeVo, {__index = Vo})
	setmetatable(this, {__index = RecipeVo})
	this:Initail(params, key)
	return this 
end

-- function RecipeVo:GetId()
-- 	return self.data.foodId
-- end

return RecipeVo