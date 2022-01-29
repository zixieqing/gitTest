--[[
溢出治疗转化为伤害
@params args ObjectBuffConstructorStruct
--]]
local BaseBuff = __Require('battle.buff.BaseBuff')
local OverflowHealDamageBuff = class('OverflowHealDamageBuff', BaseBuff)

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
function OverflowHealDamageBuff:Init()
	BaseBuff.Init(self)

	self:AddView()
end
--[[
@override
初始化固有属性
--]]
function OverflowHealDamageBuff:InitUnitValue()
	BaseBuff.InitUnitValue(self)
end
--[[
初始化索敌规则信息
--]]
function OverflowHealDamageBuff:InitExtraValue()
	self.convertPercent = checknumber(self.p.value[4])
	self.convertValue = checknumber(self.p.value[5])
	self.convertLimit = checknumber(self.p.value[6])
	self.seekRule = SeekRuleStruct.New(
		checkint(self.p.value[1]),
		checkint(self.p.value[3]),
		checkint(self.p.value[2])
	)
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
@params overflowHeal number 溢出的治疗值
--]]
function OverflowHealDamageBuff:CauseEffect(overflowHeal)
	local owner = self:GetBuffOwner()

	if nil ~= owner then
		
		local buffInfo = self:GetConvertBuffInfo(overflowHeal)
		local targets = BattleExpression.GetTargets(
			owner:isEnemy(true),
			self:GetSeekRule(),
			owner
		)
		for _, target in ipairs(targets) do
			-- 为目标对象附加buff
			local buffInfo_ = clone(buffInfo)
			-- 修改buff信息
			buffInfo_.ownerTag = target:getOTag()

			target:beCasted(buffInfo_)
		end

	end

	return value
end
--[[
@override
刷新buff效果
@params value number
@params time number
--]]
function OverflowHealDamageBuff:RefreshBuffEffect(value, time)
	BaseBuff.RefreshBuffEffect(self, value, time)
	-- 刷新一次索敌数据
	self:InitExtraValue()
end
---------------------------------------------------
-- logic end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
根据溢出的治疗值获取转化的buff信息
@params overflowHeal number 溢出的治疗值
@return buffInfo ObjectBuffConstructorStruct buff构造数据
--]]
function OverflowHealDamageBuff:GetConvertBuffInfo(overflowHeal)

	local buffType = ConfigBuffType.ISD
	local buffConfig = CommonUtils.GetConfig('cards', 'skillType', buffType)

	local value = math.min(
		self:GetBuffOwner():getMainProperty():getOriginalHp() * self.convertLimit,
		math.max(0, overflowHeal * convertPercent + self.convertValue)
	)

	local buffInfo = ObjectBuffConstructorStruct.New(
		self:GetSkillId(),
		tostring(self:GetSkillId()) .. buffType,
		buffType,
		BKIND.INSTANT,
		nil,
		self:GetBuffOwnerTag(),
		false,
		false,
		'battle.buff.InstantBuff',
		BuffCauseEffectTime.INSTANT,
		value,
		0,
		0,
		1,
		0,
		checkint(buffConfig.buffIcon),
		nil,
		nil
	)

	return buffInfo
end
--[[
获取护盾的索敌规则
--]]
function OverflowHealDamageBuff:GetSeekRule()
	return self.seekRule
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return OverflowHealDamageBuff
