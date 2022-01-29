--[[
变形buff
@params args ObjectBuffConstructorStruct
--]]
local BaseBuff = __Require('battle.buff.BaseBuff')
local ViewTransformBuff = class('ViewTransformBuff', BaseBuff)

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
@override
初始化特有属性
--]]
function ViewTransformBuff:InitUnitValue()
	self.transformInfo = {}

	BaseBuff.InitUnitValue(self)
end
--[[
@override
初始化buff特有的数据
--]]
function ViewTransformBuff:InitExtraValue()
	local value = self:GetValue()

	self.transformInfo = {
		oriSkinId 				= checkint(value[1]),
		oriActionName 			= tostring(value[2]),
		targetSkinId 			= checkint(value[3]),
		targetActionName 		= tostring(value[4])
	}
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- logic begin --
---------------------------------------------------
--[[
@override
造成效果
--]]
function ViewTransformBuff:CauseEffect()
	local owner = self:GetBuffOwner()

	if nil ~= owner then

		local transformInfo = self:GetTransformInfo()
		owner:ViewTransform(
			transformInfo.oriSkinId,
			transformInfo.oriActionName,
			transformInfo.targetSkinId,
			transformInfo.targetActionName
		)

	end

	return 0
end
--[[
@override
恢复效果
@return result number 恢复效果以后的结果
--]]
function ViewTransformBuff:RecoverEffect()
	local owner = self:GetBuffOwner()

	if nil ~= owner then

	end

	return 0
end
---------------------------------------------------
-- logic end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
获取免疫的buff类型
--]]
function ViewTransformBuff:GetTransformInfo()
	return self.transformInfo
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return ViewTransformBuff