--[[
回响 连续施法buff
@params args ObjectBuffConstructorStruct
--]]
local BaseBuff = __Require('battle.buff.BaseBuff')
local SlayCastEchoBuff = class('SlayCastEchoBuff', BaseBuff)

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化
--]]
function SlayCastEchoBuff:Init()
	BaseBuff.Init(self)
	self:AddView()
end
--[[
@override
初始化索敌规则信息
--]]
function SlayCastEchoBuff:InitExtraValue()
	self.slayTargetSkillType = checkint(self.p.value[1])
	self.castTargetSkillType = checkint(self.p.value[2])
	self.echoChance = checknumber(self.p.value[3])
end
--[[
@override
获取buff内部trigger信息
--]]
function SlayCastEchoBuff:GetTriggerTypeConfig()
	return {
		ConfigObjectTriggerActionType.SLAY_OBJECT
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
function SlayCastEchoBuff:CauseEffect()
	local owner = self:GetBuffOwner()

	if nil ~= owner then
		
		-- 判断一次成功率
		if self:CanEchoByEchoChance() then
			local skillId = self:GetEchoSkillId()
			owner.castDriver:AddAEchoSkill(skillId)
		end
		
	end

	return 0
end
--[[
@override
刷新buff效果
@params value number
@params time number
--]]
function SlayCastEchoBuff:RefreshBuffEffect(value, time)
	BaseBuff.RefreshBuffEffect(self, value, time)
	-- 刷新一次索敌数据
	self:InitExtraValue()
end
--[[
@override
触发后的处理
@params triggerType ConfigObjectTriggerActionType 触发类型
@params slayData 击杀信息
--]]
function SlayCastEchoBuff:TriggerHandler(triggerType, slayData)
	if nil ~= slayData.damageData.skillInfo then
		local slaySkillId = slayData.damageData.skillInfo.skillId
		if self:CanEchoBySkillId(slaySkillId) then
			-- 触发效果
			self:OnCauseEffectEnter()
		end
	end
end
---------------------------------------------------
-- logic end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
根据技能id判断是否满足触发回响的条件
@params skillId int 技能id
@return _ bool 是否满足
--]]
function SlayCastEchoBuff:CanEchoBySkillId(skillId)
	local skillConfig = CommonUtils.GetSkillConf(skillId)
	local skillType = checkint(skillConfig.property)
	return self:CanEchoBySkillType(skillType)
end
--[[
根据技能类型判断是否满足触发回响的条件
@params skillType ConfigSkillType 技能类型
@return _ bool 是否满足
--]]
function SlayCastEchoBuff:CanEchoBySkillType(skillType)
	return skillType == self.slayTargetSkillType
end
--[[
根据成功率判断是否满足回响条件
@return _ bool 是否可以回响
--]]
function SlayCastEchoBuff:CanEchoByEchoChance()
	local a = 1000
	return self.echoChance * a <= G_BattleLogicMgr:GetRandomManager():GetRandomInt(a)
end
--[[
获取owner对应的回响技能
@return skillId int 技能id
--]]
function SlayCastEchoBuff:GetEchoSkillId()
	local skillId = nil

	local owner = self:GetBuffOwner()
	if nil ~= owner and owner.castDriver then

		skillId = owner.castDriver:GetRandomSkillIdBySkillType(self.castTargetSkillType)

	end


	return skillId
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return SlayCastEchoBuff
