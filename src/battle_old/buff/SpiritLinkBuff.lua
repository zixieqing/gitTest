--[[
灵魂链接
@params args ObjectBuffConstructorStruct
--]]
local BaseBuff = __Require('battle.buff.BaseBuff')
local SpiritLinkBuff = class('SpiritLinkBuff', BaseBuff)

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
@override
初始化
--]]
function SpiritLinkBuff:Init()
	BaseBuff.Init(self)
	self:AddView()
end
--[[
@override
获取buff内部trigger信息
--]]
function SpiritLinkBuff:GetTriggerTypeConfig()
	return {
		ConfigObjectTriggerActionType.GOT_DAMAGE,
		ConfigObjectTriggerActionType.GOT_HEAL
	}
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- logic begin --
---------------------------------------------------
--[[
@params
造成效果
--]]
function SpiritLinkBuff:CauseEffect()
	local owner = self:GetBuffOwner()

	if nil ~= owner then
		local btype = self:GetBuffType()
		local ownerTag = self:GetBuffOwnerTag()
		local isEnemy = owner:isEnemy(true)
		local friendObjs = BattleExpression.GetFriendlyTargets(isEnemy, ConfigSeekTargetRule.T_OBJ_FRIEND)

		local curHpSum = 0
		local maxHpSum = 0
		local shareObjTags = {}

		for _, obj in ipairs(friendObjs) do
			if obj:HasBuffByBuffType(btype, false) then
				curHpSum = curHpSum + obj:getMainProperty():getCurrentHp()
				maxHpSum = maxHpSum + obj:getMainProperty():getOriginalHp()

				table.insert(shareObjTags, obj:getOTag())
			end
		end

		local hpPercent = curHpSum / maxHpSum
		local obj = nil
		for _, tag in ipairs(shareObjTags) do
			obj = BMediator:IsObjAliveByTag(tag)
			if nil ~= obj then

				local targetHp = obj:getMainProperty():getOriginalHp() * hpPercent
				local deltaHp = targetHp - obj:getMainProperty():getCurrentHp()

				local damageData = ObjectDamageStruct.New(
					tag,
					math.abs(deltaHp),
					DamageType.SKILL_PHYSICAL,
					false,
					nil,
					{skillId = self:GetSkillId(), btype = btype}
				)

				if deltaHp > 0 then
					damageData.healerTag = ownerTag
				else
					damageData.attackerTag = ownerTag
				end
				
				obj:hpChange(damageData)

			end
		end
	end

	return 0
end
--[[
@override
触发后的处理
@params triggerType ConfigObjectTriggerActionType 触发类型
@params ... 变长参数
--]]
function SpiritLinkBuff:TriggerHandler(triggerType, ...)
	self:OnCauseEffectEnter()
end
---------------------------------------------------
-- logic end --
---------------------------------------------------

return SpiritLinkBuff
