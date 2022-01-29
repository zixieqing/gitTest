--[[
触发buff基类
@params args ObjectTriggerBuffConstructorStruct
--]]
local BaseBuff = __Require('battle.buff.BaseBuff')
local BaseTriggerBuff = class('BaseTriggerBuff', BaseBuff)

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

--[[
@override
constructor
--]]
function BaseTriggerBuff:ctor( ... )
	BaseBuff.ctor(self, ...)

	-- local args = unpack({...})
end
---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化触发器
--]]
function BaseTriggerBuff:InitTrigger()
	self.triggers = {}
	self.triggerBuffsDict = {}
	self.triggerSkills = {}

	local owner = self:GetBuffOwner()

	if nil == owner then return end

	local buffInfos = self:GetTriggerBuffInfos()
	local sk = sortByKey(buffInfos)

	for i,v in ipairs(sk) do
		local buffType_ = v
		local buffInfo_ = buffInfos[buffType_]

		local triggerActionInfo = buffInfo_.triggerActionInfo
		if nil ~= triggerActionInfo then

			local sk = sortByKey(triggerActionInfo)

			local triggerActionInfo_ = nil

			for _, triggerType in ipairs(sk) do
				triggerActionInfo_ = triggerActionInfo[triggerType]
				if nil == self.triggers[triggerType] then
					-- 创建一个触发器
					local trigger = __Require('battle.trigger.BaseTrigger').new(ObjectTriggerConstructorStruct.New(
						G_BattleLogicMgr:GetBData():GetTagByTagType(BattleTags.BT_TRIGGER),
						triggerType,
						handler(self, self.TriggerHandler)
					))
					-- 加入缓存
					self.triggers[triggerType] = trigger
					owner.triggerDriver:AddATrigger(trigger)
				end

				-- 向字典中插入buff类型
				if nil == self.triggerBuffsDict[triggerType] then
					self.triggerBuffsDict[triggerType] = {}
				end
				table.insert(self.triggerBuffsDict[triggerType], checkint(buffType_))
			end

		end
	end
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- logic begin --
---------------------------------------------------
--[[
触发后的处理
@params triggerType ConfigObjectTriggerActionType 触发类型
@params params ObjectTriggerParameterStruct 触发传参
--]]
function BaseTriggerBuff:TriggerHandler(triggerType, params)
	local skill = self:GetTriggerSkillByTriggerType(triggerType)
	local owner = self:GetBuffOwner()
	if nil == owner then return end

	if nil == skill then
		-- 创建一个技能模型
		local buffsInfo = {}
		local seekRulesInfo = {}
		local triggerActionInfo = {}
		local triggerConditionInfo = {}
		local spineActionData = {
			hurtEffectData = {},
			attachEffectData = {}
		}

		local buffTypes = self:GetBuffsByTriggerType(triggerType)
		if nil == buffTypes then return end

		for _, buffType_ in ipairs(buffTypes) do
			local triggerBuff = self:GetTriggerBuffInfoByBuffType(buffType_)
			local buffTriggerActionInfo = triggerBuff.triggerActionInfo[triggerType]
			if nil ~= triggerBuff then

				------------ buff信息 ------------
				local buffInfo = ConfigBuffInfoStruct.New(
					triggerBuff.buffInfo.skillId,
					triggerBuff.buffInfo.buffType,
					triggerBuff.buffInfo.value,
					buffTriggerActionInfo.time,
					buffTriggerActionInfo.triggerInsideCD,
					triggerBuff.buffInfo.innerPileMax,
					buffTriggerActionInfo.triggerRate,
					triggerBuff.buffInfo.qteTapTimes
				)
				------------ buff信息 ------------

				------------ 索敌规则 ------------
				local seekRuleInfo = buffTriggerActionInfo.triggerSeekRule
				------------ 索敌规则 ------------

				buffsInfo[tostring(buffType_)] = buffInfo
				seekRulesInfo[tostring(buffType_)] = seekRuleInfo
				triggerConditionInfo[tostring(buffType_)] = triggerBuff.triggerConditionInfo
				spineActionData.hurtEffectData[tostring(buffType_)] = triggerBuff.hurtEffectData
				spineActionData.attachEffectData[tostring(buffType_)] = triggerBuff.attachEffectData

			end
		end

		local skillInfo = ConfigSkillInfoStruct.New(
			self:GetSkillId(),
			ConfigSkillType.SKILL_NORMAL,
			buffsInfo,
			seekRulesInfo,
			SeekRuleStruct.New(),
			0,
			triggerActionInfo,
			triggerConditionInfo
		)

		local skillBaseData = SkillConstructorStruct.New(
			self:GetSkillId(),
			1,
			skillInfo,
			self:GetBuffOwner():IsEnemy(true),
			self:GetBuffOwnerTag(),
			spineActionData
		)

		-- TODO --
		skill = __Require('battle.skill.BaseSkill').new(skillBaseData)
		-- TODO --

		self:SetTriggerSkillByTriggerType(triggerType, skill)
	end

	skill:CastBegin(ObjectCastParameterStruct.New(
		1,
		1,
		params,
		cc.p(0, 0),
		false,
		false
	))
end
---------------------------------------------------
-- logic end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
获取触发buff信息
--]]
function BaseTriggerBuff:GetTriggerBuffInfos()
	return self.buffInfo.triggerBuffInfos
end
--[[
根据类型获取触发buff的信息
@params buffType ConfigBuffType buff类型
--]]
function BaseTriggerBuff:GetTriggerBuffInfoByBuffType(buffType)
	return self.buffInfo.triggerBuffInfos[tostring(buffType)]
end
--[[
根据触发类型获取触发的buff
@params triggerType ConfigObjectTriggerActionType 触发类型
@return _ list 触发的buff type集合
--]]
function BaseTriggerBuff:GetBuffsByTriggerType(triggerType)
	return self.triggerBuffsDict[triggerType]
end
--[[
根据触发类型获取技能建模
@params triggerType ConfigObjectTriggerActionType 触发类型
@return _ BaseSkill 技能建模
--]]
function BaseTriggerBuff:GetTriggerSkillByTriggerType(triggerType)
	return self.triggerSkills[triggerType]
end
function BaseTriggerBuff:SetTriggerSkillByTriggerType(triggerType, skill)
	self.triggerSkills[triggerType] = skill
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return BaseTriggerBuff
