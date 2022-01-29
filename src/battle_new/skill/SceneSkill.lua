--[[
情景技能
--]]
local BaseSkill = __Require('battle.skill.BaseSkill')
local SceneSkill = class('SceneSkill', BaseSkill)

---------------------------------------------------
-- logic begin --
---------------------------------------------------
--[[
释放该技能
@params params ObjectCastParameterStruct 外部传参
--]]
function SceneSkill:Cast(params)
	---------- 处理技能信息 ----------
	params = params or {}
	params.percent = params.percent or 1
	params.skillExtra = params.skillExtra or 1
	params.shouldShakeWorld = params.shouldShakeWorld or false

	self:SetSkillPhase(self:GetSkillPhase() + 1)
	---------- 处理技能信息 ----------

	---------- 优先释放非buff类型 ----------
	if 1 == self:GetSkillPhase() then
		-- ### serialized ### --
		local buffInfo = nil
		for i = #self.nonbuffInfos, 1, -1 do
			buffInfo = self.nonbuffInfos[i]
			local buff = __Require(buffInfo.className).new(buffInfo)
			buff:OnCauseEffectEnter()
		end
	end
	---------- 优先释放非buff类型 ----------

	self:BaseCast(self:GetTargetPool())
end
--[[
转换数据结构
@params params ObjectCastParameterStruct 外部传参
@return result table target -> buff 映射
--]]
function SceneSkill:ConvertBuffTargetData(params)
	local result = {}
	-- 情景类技能写死受法者为全局物体
	local target = G_BattleLogicMgr:GetGlobalEffectObj()
	local tTag = target:GetOTag()
	local caster = target

	local tmpTargetTagIdx = {}

	for i = #self.buffInfos, 1, -1 do
		buffInfo_ = self.buffInfos[i]
		buffType_ = buffInfo_.btype

		local buffInfo = clone(buffInfo_)

		---------- 修正buff实际值 ----------
		self:ConvertConfigValue2RealValue(caster, target, buffInfo_.value, buffInfo, 1, 1)
		---------- 修正buff实际值 ----------

		---------- 整合数据结构 ----------
		if nil == tmpTargetTagIdx[tostring(tTag)] then
			-- waring !!! --
			-- may cause logic error
			-- waring !!! --
			table.insert(result, {tag = tTag, buffs = {}, needRevive = (ConfigBuffType.REVIVE == buffType_)})
			tmpTargetTagIdx[tostring(tTag)] = #result
		end
		table.insert(result[tmpTargetTagIdx[tostring(tTag)]].buffs, buffInfo)
		---------- 整合数据结构 ----------
	end

	return result
end
---------------------------------------------------
-- logic end --
---------------------------------------------------

return SceneSkill
