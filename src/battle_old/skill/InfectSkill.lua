--[[
传染技能模型
@params arg InfectTransmitStruct 传染信息
--]]
local BaseSkill = __Require('battle.skill.BaseSkill')
local InfectSkill = class('InfectSkill', BaseSkill)

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

--[[
constructor
--]]
function InfectSkill:ctor( ... )
	local args = unpack({...})

	self.infectData = args
	dump(args)

	self:Init()
end
---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
@override
初始化技能模型
--]]
function InfectSkill:Init()
	self:InitValue()
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- logic begin --
---------------------------------------------------
--[[
@override
转换数据结构 传染技能并不会为每个buff索敌 而是整个技能一起索敌
@params params table {
	skillExtra number 释放最终值乘法修正
	percent number 分段百分比
	bulletOriPosition cc.p 发射子弹的起点
}
@return result table taget -> buff 映射
--]]
function InfectSkill:ConvertBuffTargetData(params)
	local result = {}
	local bufftargets = {}
	---------- 初始化一些由caster确定的参数 传染的caster不是源caster 而是传染源 ----------
	local casterPos = cc.p(0, 0)
	local caster = self:GetSkillCaster()
	if caster then
		casterPos = caster:getLocation().po
	end
	---------- 初始化一些由caster确定的参数 传染的caster不是源caster 而是传染源 ----------

	---------- 为整个技能索敌 ----------
	-- 技能索敌 只在第一段索敌
	bufftargets = self:SeekCastTargets(
		self:GetIsSkillEnemy(),
		self:GetSkillInfectSeekRule(),
		{pos = casterPos, o = caster}
	)
	---------- 为整个技能索敌 ----------

	---------- 整合数据结构 ----------
	local buffInfo_ = nil
	local buffType_ = nil
	local tmpTargetTagIdx = {}

	for i = #self.infectData.infectBuffInfo, 1, -1 do
		buffInfo_ = self.infectData.infectBuffInfo[i]
		buffType_ = buffInfo_.btype

		local tTag = nil
		for i, target in ipairs(bufftargets) do
			tTag = target:getOTag()
			local buffInfo = clone(buffInfo_)

			---------- 修正buff实际值 ----------
			buffInfo.ownerTag = tTag
			---------- 修正buff实际值 ----------

			---------- 整合数据结构 ----------
			if nil == tmpTargetTagIdx[tostring(tTag)] then
				table.insert(result, {tag = tTag, buffs = {}})
				tmpTargetTagIdx[tostring(tTag)] = #result
			end
			table.insert(result[tmpTargetTagIdx[tostring(tTag)]].buffs, buffInfo)
			---------- 整合数据结构 ----------
		end
	end
	---------- 整合数据结构 ----------

	return result
end
--[[
@override
技能索敌 传染技能会排除那些身上已经携带了传染驱动器的 obj
@params isEnemy bool 这个技能本身的敌我性
@params seekRule SeekRuleStruct 索敌规则
@params extra table 附加参数
@return _ table 所对应的目标
--]]
function InfectSkill:SeekCastTargets(isEnemy, seekRule, extra)
	return BattleExpression.GetSortedTargets(
		BattleExpression.GetFriendlyTargets(isEnemy, seekRule.ruleType, self:GetSkillId(), extra.o),
		seekRule.sortType,
		seekRule.maxValue,
		extra
	)
end
--[[
@override
释放该技能
@params params table {
	skillExtra number 释放最终值乘法修正
	percent number 分段百分比
	bulletOriPosition cc.p 发射子弹的起点
}
--]]
function InfectSkill:Cast(params)
	---------- 处理技能信息 ----------
	params = params or {}
	params.percent = params.percent or 1
	params.skillExtra = params.skillExtra or 1
	self.phase = self.phase + 1
	---------- 处理技能信息 ----------

	---------- 优先释放非buff类型 ----------
	-- if self.phase == 1 then
	-- 	-- ### serialized ### --
	-- 	local buffInfo = nil
	-- 	for i = #self.nonbuffInfos, 1, -1 do
	-- 		buffInfo = self.nonbuffInfos[i]
	-- 		local buff = __Require(buffInfo.className).new(buffInfo)
	-- 		buff:OnCauseEffectEnter()
	-- 	end
	-- end
	---------- 优先释放非buff类型 ----------

	---------- 释放buff类型 ----------
	self:BaseCast(self:GetTargetPool())
	---------- 释放buff类型 ----------

end
---------------------------------------------------
-- logic end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
@override
获取技能id
--]]
function InfectSkill:GetSkillId()
	return self.infectData.skillId
end
--[[
@override
获取技能等级
--]]
function InfectSkill:GetSkillLevel()
	return self.infectData.level
end
--[[
@override
获取技能的施法者tag
传染的caster不是源caster 而是传染源
--]]
function InfectSkill:GetSkillCasterTag()
	return self.infectData.infectSourceTag
end
--[[
@override
获取技能敌友性
--]]
function InfectSkill:GetIsSkillEnemy()
	return self.infectData.isEnemy
end
--[[
@override
获取传染的时间间隔
--]]
function InfectSkill:GetSkillInfectTime()
	return self.infectData.infectTime
end
--[[
@override
获取传染索敌规则
--]]
function InfectSkill:GetSkillInfectSeekRule()
	return self.infectData.infectSeekRule
end
--[[
@override
获取本技能buff的被击效果信息
@return _ table
--]]
function InfectSkill:GetHurtEffectData()
	return self.infectData.hurtEffectData
end
--[[
@override
获取本技能buff的附加效果展示信息
@return _ table
--]]
function InfectSkill:GetAttachEffectData()
	return self.infectData.attachEffectData
end
--[[
@override
根据buff类型获取本技能的buff被击效果信息
@params buffType ConfigBuffType buff类型
@return _ table
--]]
function InfectSkill:GetHurtEffectDataByBuffType(buffType)
	return self:GetHurtEffectData()[tostring(buffType)] or {}
end
--[[
@override
根据buff类型获取本技能的buff附加效果信息
@params buffType ConfigBuffType buff类型
@return _ table
--]]
function InfectSkill:GetAttachEffectDataByBuffType(buffType)
	return self:GetAttachEffectData()[tostring(buffType)] or {}
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return InfectSkill
