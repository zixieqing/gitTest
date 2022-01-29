--[[
醉拳 伤害延时生效
@params args ObjectBuffConstructorStruct
--]]
local BaseBuff = __Require('battle.buff.BaseBuff')
local StaggerBuff = class('StaggerBuff', BaseBuff)

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
@override
初始化
--]]
function StaggerBuff:Init()
	BaseBuff.Init(self)
	self:AddView()
end
--[[
@override
初始化特有属性
--]]
function StaggerBuff:InitUnitValue()
	BaseBuff.InitUnitValue(self)

	-- 初始化醉拳池
	self.staggerPool = {
		totalDamage = 0,
		leftDamage = 0,
		interval = self:GetCauseEffectInterval()
	}
end
--[[
@override
初始化buff特有的数据
--]]
function StaggerBuff:InitExtraValue()
	-- 初始化醉拳数值配置
	self.staggerReduce = math.max(0, math.min(1, checknumber(self.p.value[1])))
	self.staggerTime = checknumber(self.p.value[2])
	self.interval = 1
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- logic begin --
---------------------------------------------------
--[[
@override
醉拳生效 减伤
@params damage number 伤害
@params damageData ObjectDamageStruct 伤害信息
@params reduceDamage number 抵消的伤害值
--]]
function StaggerBuff:CauseEffect(damage, damageData)
	local reduceDamage = damage * self:GetStaggerReduce()
	self:AddStaggerTotalDamage(reduceDamage)

	return reduceDamage
end
--[[
醉拳跳伤害
--]]
function StaggerBuff:CauseStaggerDamage()
	local owner = self:GetBuffOwner()
	if nil ~= owner then

		local btype = self:GetBuffType()
		local ownerTag = self:GetBuffOwnerTag()
		local staggerDamage = self:GetStaggerDamage()

		-- 刷新醉拳池剩余伤害
		self:AddStaggerLeftDamage(-1 * staggerDamage)

		local damageData = ObjectDamageStruct.New(
			ownerTag,
			staggerDamage,
			DamageType.SKILL_PHYSICAL,
			false,
			{attackerTag = ownerTag},
			{skillId = self:GetSkillId(), btype = btype}
		)

		owner:beAttacked(damageData)

	end

	if 0 >= self:GetStaggerLeftDamage() then
		-- 剩余伤害为0时清除醉拳池
		self:ResetStaggerPool()
	end
end
--[[
@override
恢复效果
@return result number 恢复效果以后的结果
--]]
function StaggerBuff:RecoverEffect()
	-- 醉拳池中剩余伤害一次返还
	local owner = self:GetBuffOwner()

	if nil ~= owner then
		local leftDamage = self:GetStaggerLeftDamage()
		if 0 < leftDamage then
			local damageData = ObjectDamageStruct.New(
				ownerTag,
				leftDamage,
				DamageType.SKILL_PHYSICAL,
				false,
				{attackerTag = ownerTag},
				{skillId = self:GetSkillId(), btype = btype}
			)
			owner:beAttacked(damageData)
		end

		BaseBuff.RecoverEffect(self)
	end

	return 0
end
--[[
主逻辑更新
--]]
function StaggerBuff:OnBuffUpdateEnter(dt)
	
	------------ 醉拳池逻辑 ------------
	if 0 < self:GetStaggerLeftDamage() and 0 < self:GetStaggerTotalDamage() then
		self.staggerPool.interval = self.staggerPool.interval - dt
		if 0 >= self.staggerPool.interval then
			self:CauseStaggerDamage()
			self.staggerPool.interval = self.staggerPool.interval + self:GetCauseEffectInterval()
		end
	end
	------------ 醉拳池逻辑 ------------

	if self:IsHaloBuff() then return end

	------------ buff逻辑 ------------
	-- 更新buff计时
	self.p.countdown = math.max(0, self.p.countdown - dt)
	if 0 >= self.p.countdown then
		self:OnRecoverEffectEnter()
	end
	------------ buff逻辑 ------------

end
--[[
@override
刷新buff效果
@params value number
@params time number
--]]
function StaggerBuff:RefreshBuffEffect(value, time)
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
获取醉拳减伤百分比
--]]
function StaggerBuff:GetStaggerReduce()
	return self.staggerReduce
end
--[[
获取醉拳返还总时间
--]]
function StaggerBuff:GetStaggerTime()
	return self.staggerTime
end
--[[
获取当前醉拳跳的伤害
--]]
function StaggerBuff:GetStaggerDamage()
	return self:GetStaggerTotalDamage() / self:GetStaggerTime() * self:GetCauseEffectInterval()
end
--[[
获取醉拳池总伤害
--]]
function StaggerBuff:GetStaggerTotalDamage()
	return self.staggerPool.totalDamage
end
function StaggerBuff:SetStaggerTotalDamage(damage)
	self.staggerPool.totalDamage = damage
end
--[[
增加醉拳池总伤害
@params damage number 伤害值
--]]
function StaggerBuff:AddStaggerTotalDamage(damage)
	self:SetStaggerTotalDamage(math.max(0, self:GetStaggerLeftDamage() + damage))
	self:SetStaggerLeftDamage(self:GetStaggerTotalDamage())
end
--[[
获取醉拳池剩余伤害
--]]
function StaggerBuff:GetStaggerLeftDamage()
	return self.staggerPool.leftDamage
end
function StaggerBuff:SetStaggerLeftDamage(damage)
	self.staggerPool.leftDamage = damage
end
--[[
增加醉拳池剩余伤害
@params damage number 伤害值
--]]
function StaggerBuff:AddStaggerLeftDamage(damage)
	self:SetStaggerLeftDamage(math.max(0, self:GetStaggerLeftDamage() + damage))
end
--[[
获取dot作用间隔
--]]
function StaggerBuff:GetCauseEffectInterval()
	return self.interval
end
function StaggerBuff:SetCauseEffectInterval(interval)
	self.interval = interval
end
--[[
清除醉拳池
@params percent number 清除比例
--]]
function StaggerBuff:ClearStaggerPool(percent)
	if nil == percent then
		self:ResetStaggerPool()
	else
		self:SetStaggerTotalDamage(self:GetStaggerTotalDamage() * checknumber(percent))
		self:SetStaggerLeftDamage(self:GetStaggerLeftDamage() * checknumber(percent))
	end
end
--[[
重置醉拳池
--]]
function StaggerBuff:ResetStaggerPool()
	self.staggerPool.totalDamage = 0
	self.staggerPool.leftDamage = 0
	self.staggerPool.interval = self:GetCauseEffectInterval()
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return StaggerBuff
