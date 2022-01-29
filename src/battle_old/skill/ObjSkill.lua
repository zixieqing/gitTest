--[[
战斗物体技能模型基类 
--]]
local BaseSkill = __Require('battle.skill.BaseSkill')
local ObjSkill = class('ObjSkill', BaseSkill)

---------------------------------------------------
-- logic begin --
---------------------------------------------------
--[[
@override
开始释放技能 初始化一些值
@params params ObjectCastParameterStruct 外部传参
--]]
function ObjSkill:CastBegin(params)
	-- 清空分段
	self:ClearSkillPhase()
	-- 清空分段对象池
	self:ClearTargetPool()
	-- 缓存一次本次施法索敌目标
	self:SetTargetPool(self:ConvertBuffTargetData(params))
end
---------------------------------------------------
-- logic end --
---------------------------------------------------

return ObjSkill
