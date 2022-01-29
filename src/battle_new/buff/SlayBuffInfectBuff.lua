--[[
击杀buff传染buff
@params args ObjectBuffConstructorStruct
--]]
local BaseBuff = __Require('battle.buff.BaseBuff')
local SlayBuffInfectBuff = class('SlayBuffInfectBuff', BaseBuff)

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
function SlayBuffInfectBuff:Init()
	BaseBuff.Init(self)

	self:AddView()
end
--[[
@override
初始化固有属性
--]]
function SlayBuffInfectBuff:InitUnitValue()
	BaseBuff.InitUnitValue(self)
end
--[[
初始化索敌规则信息
--]]
function SlayBuffInfectBuff:InitExtraValue()
	self.infectSeekRule = SeekRuleStruct.New(
		checkint(self.p.value[1]),
		checkint(self.p.value[3]),
		checkint(self.p.value[2])
	)

	self.infectBuffType = {}
	for i = 4, #self.p.value do
		table.insert(self.infectBuffType, checkint(self.p.value[i]))
	end
end
--[[
@override
获取buff内部trigger信息
--]]
function SlayBuffInfectBuff:GetTriggerTypeConfig()
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
@params slayTargetTag int 杀死的目标单位tag
--]]
function SlayBuffInfectBuff:CauseEffect(slayTargetTag)
	local owner = self:GetBuffOwner()
	local slayTarget = G_BattleLogicMgr:GetObjByTagForce(slayTargetTag)

	if nil ~= owner and slayTarget then
		local btype = self:GetBuffType()
		local ownerTag = self:GetBuffOwnerTag()

		local infectBuffTypes = self:GetInfectBuffTypes()
		for _, buffType in ipairs(infectBuffTypes) do

			local targetBuffs = slayTarget:GetBuffsByBuffType(buffType, true)
			if nil ~= next(targetBuffs) then
				-- 存在对应类型的buff 传染一次
				for i = #targetBuffs, 1, -1 do

					local buffInfo = targetBuffs[i]:GetBuffInfo()
					local skillId = buffInfo.skillId
					local targets = BattleExpression.GetTargets(slayTarget:IsEnemy(true), self:GetSplashSeekRule(), slayTarget, nil, {[tostring(slayTargetTag)] = true})

					for _, target in ipairs(targets) do
						-- 为目标对象附加buff
						local buffInfo_ = clone(buffInfo)
						-- 修改buff信息
						buffInfo_.ownerTag = target:GetOTag()

						target:BeCasted(buffInfo_)
					end

				end
			end

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
function SlayBuffInfectBuff:RefreshBuffEffect(value, time)
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
function SlayBuffInfectBuff:TriggerHandler(triggerType, slayData)
	self:OnCauseEffectEnter(slayData.targetTag)
end
---------------------------------------------------
-- logic end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
获取所有的传染buff信息
@return _ list 传染的buff类型
--]]
function SlayBuffInfectBuff:GetInfectBuffTypes()
	return self.infectBuffType
end
--[[
获取爆出伤害的索敌
@return _ SeekRuleStruct 索敌规则
--]]
function SlayBuffInfectBuff:GetSplashSeekRule()
	return self.infectSeekRule
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return SlayBuffInfectBuff
