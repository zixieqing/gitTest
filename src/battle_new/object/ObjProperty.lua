--[[
战斗物体基础属性
@params ObjectPropertyConstructStruct 卡牌属性构造函数
--]]
local ObjProp = class('ObjProp')

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

--[[
construtor
--]]
function ObjProp:ctor( ... )
	local args = unpack({...})

	self.cardId = args.cardId
	self.level = args.level
	self.breakLevel = args.breakLevel
	self.favorLevel = args.favorLevel

	self.petAddition = nil
	if nil ~= args.petData then
		self.petAddition = args.petData:GetCardPropertyAddition()
	end

	self.artifactAddition = nil
	if nil ~= args.talentData then
		self.artifactAddition = args.talentData:GetCardPropertyAddition()
	end

	self.bookAddition = nil 
	if nil ~= args.bookData then
		self.bookAddition = args.bookData:GetCardPropertyAddition()
	end

	self.catBuffAddition = nil
	if nil ~= args.catGeneData then
		self.catBuffAddition = args.catGeneData:GetCardPropertyAddition()
	end

	self.singleAddition = args.singleAddition
	self.ultimateAddition = args.ultimateAddition

	self.location = args.oriLocation

	self:Init()
end
--[[
init logic
--]]
function ObjProp:Init()
	-- 获取配表信息
	local objConfig = CardUtils.GetCardConfig(self.cardId)
	local cellSizeW = G_BattleLogicMgr:GetBConf().cellSizeWidth
	local walkSpeed = cellSizeW * 3

	-- 原始属性
	self.op = {

		------------ property info ------------
		[ObjP.HP] 			= self:CalcFixedFinalOriginProperty(ObjP.HP),
		[ObjP.ATTACK] 		= self:CalcFixedFinalOriginProperty(ObjP.ATTACK),
		[ObjP.DEFENCE] 		= self:CalcFixedFinalOriginProperty(ObjP.DEFENCE),
		[ObjP.CRITRATE] 	= self:CalcFixedFinalOriginProperty(ObjP.CRITRATE),
		[ObjP.CRITDAMAGE] 	= self:CalcFixedFinalOriginProperty(ObjP.CRITDAMAGE),
		[ObjP.ATTACKRATE] 	= self:CalcFixedFinalOriginProperty(ObjP.ATTACKRATE),
		[ObjP.ENERGY] 		= MAX_ENERGY, -- 能量上限
		attackRange 		= checknumber(objConfig.attackRange),
		walkSpeed 			= walkSpeed,
		------------ property info ------------

		------------ battle info ------------
		location = self.location or {po = {x = 0, y = 0}, rc = {r = 0, c = 0}}
		------------ battle info ------------

	}

	-- 实时属性
	self.p = {

		------------ property info ------------
		[ObjP.HP] 			= self.op[ObjP.HP],
		[ObjP.ATTACK] 		= self.op[ObjP.ATTACK],
		[ObjP.DEFENCE] 		= self.op[ObjP.DEFENCE],
		[ObjP.CRITRATE] 	= self.op[ObjP.CRITRATE],
		[ObjP.CRITDAMAGE] 	= self.op[ObjP.CRITDAMAGE],
		[ObjP.ATTACKRATE] 	= self.op[ObjP.ATTACKRATE],
		[ObjP.ENERGY] 		= self.op[ObjP.ENERGY], -- 能量上限
		attackRange 		= self.op.attackRange,
		walkSpeed 			= self.op.walkSpeed,
		hpPercent 			= 1,
		------------ property info ------------

		------------ battle info ------------
		location = {po = {x = self.op.location.po.x, y = self.op.location.po.y}, rc = {r = self.op.location.rc.r, c = self.op.location.rc.c}},
		------------ battle info ------------

	}
	dump(self.p, 'ObjProp.p -> ' .. self.cardId)

	-- 属性参数
	self:InitObjPP()

	-- 初始化一次外部属性系数配置
	self:InitSinglePropertyAttr()
end
--[[
初始化个体属性参数 -> 刷新初始化的属性
--]]
function ObjProp:InitSinglePropertyAttr()
	------------ 初始化单体外部属性的影响值 ------------
	if nil ~= self.singleAddition then
		for objp_, attr in pairs(self.singleAddition.pattr) do
			if nil ~= self.p[objp_] and attr >= 0 then
				self.p[objp_] = self.p[objp_] * attr
			end
		end

		for objp_, value in pairs(self.singleAddition.pvalue) do
			if nil ~= self.p[objp_] and value >= 0 then
				self.p[objp_] = value
			end
		end
	end
	------------ 初始化单体外部属性的影响值 ------------

	-- 刷新一次生命百分比
	self:UpdateCurHpPercent()
end
--[[
根据属性类型获取计算修正后的原始属性
@params objp ObjP
@return _ number 修正后的原始属性
--]]
function ObjProp:CalcFixedFinalOriginProperty(objp)
	local fixedP = CardUtils.GetCardOneFixedP(
		self.cardId, objp, self.level, self.breakLevel, self.favorLevel, self.petAddition, self.artifactAddition, self.bookAddition, self.catBuffAddition
	) * self:GetUltimatePropertyAddition(objp)
	return fixedP
end
--[[
初始化属性参数
--]]
function ObjProp:InitObjPP()
	self.pp = {}

	for k,v in pairs(ObjPP) do

		local value = 0

		-- 属性系数的外部参数
		local ppattrA = self:GetUltimatePPAddition(v)
		if nil ~= ppattrA then
			value = value + ppattrA
		end

		self.pp[v] = value
		
	end
	
end
--[[
计算初始化的能量值
@params isLeader bool 是否是队长 队长拥有初始50点能量的加成值
@return result number 能量值
--]]
function ObjProp:CalcFixedInitEnergy(isLeader)
	local result = self:GetMaxEnergy() * self.singleAddition.energyPercent + self.singleAddition.energyValue
	if true == isLeader then
		result = result + LEADER_ENERGY_ADD
	end
	result = math.max(0, math.min(self:GetMaxEnergy(), result))

	return result
end
---------------------------------------------------
-- logic begin --
---------------------------------------------------
--[[
变化属性参数
@params pp ObjPP 属性参数
@params delta number 变化量
--]]
function ObjProp:Changepp(pp, delta)
	self:Setpp(pp, self:Getpp(pp) + delta)
end
--[[
传入一个血量变化值 判断该值是否致死
@params delta number 变化值
@return _ bool 是否致死
--]]
function ObjProp:IsDamageDeadly(delta)
	return 0 < self:GetCurrentHp() and 0 >= self:GetCurrentHp() + delta
end
---------------------------------------------------
-- logic end --
---------------------------------------------------

---------------------------------------------------
-- expression begin --
---------------------------------------------------
--[[
获取修正后的攻击力
-- TODO expression --
当攻击力<=2000
攻击力为当前值
当攻击力>2000
攻击力最终值=2000+(C2-2000)^(3/2)/100)
-- TODO expression --

-- old expression --
攻击力公式ATK -> 基础攻击力*(1+(攻击力系数加成-攻击力系数减成))+(攻击力常数加成-攻击力常数减成)
-- old expression --
--]]
function ObjProp:GetATK()
	-- TODO expression --
	local threshold = 2000
	local atk = math.max(0, self:Getp(ObjP.ATTACK) * (1 + self:Getpp(ObjPP.ATTACK_A)) + self:Getpp(ObjPP.ATTACK_B))
	if threshold >= atk then
		return atk
	else
		return threshold + (atk - threshold) ^ (1.5) * 0.01
	end
	-- TODO expression --

	-- old expression --
	-- return math.max(0, self:Getp(ObjP.ATTACK) * (1 + self:Getpp(ObjPP.ATTACK_A)) + self:Getpp(ObjPP.ATTACK_B))
	-- old expression --
end
--[[
获取修正后的防御力
防御力公式DFN -> 基础防御力*(1+(防御力系数加成-防御力系数减成))+(防御力常数加成-防御力常数减成)
--]]
function ObjProp:GetDFN()
	return math.max(0, self:Getp(ObjP.DEFENCE) * (1 + self:Getpp(ObjPP.DEFENCE_A)) + self:Getpp(ObjPP.DEFENCE_B))
end
--[[
获取等级碾压机制修正后的防御力
等级高的卡牌防御力 =round(防御力*(1.1+(等级差^0.5/4.1)*10/100),0)
等级差超过30级,按照30级处理
等级低的卡牌防御力 =round(防御力*(1-int(等级差/10.1)*10/100),0)
等级差超过60级,按照60级处理
@params deltaLevel int 等级差
@return _ int 修正后的防御力
--]]
function ObjProp:GetFixedDFNByLevelRolling(deltaLevel)
	deltaLevel = math.min(ConfigBattleLevelRolling.HIGHER_MAX, math.max(ConfigBattleLevelRolling.LOWER_MIN, deltaLevel))
	if 0 > deltaLevel then
		return math.floor(self:GetDFN() * (1 - math.floor(math.abs(deltaLevel) / 10.1) * 0.1) + 0.5)
	elseif 0 < deltaLevel then
		return math.floor(self:GetDFN() * (1.1 + (math.sqrt(deltaLevel) / 4.1) * 0.1) + 0.5)
	else
		return self:GetDFN()
	end
end
--[[
获取修正后的减伤百分比
-- TODO expression --
减伤百分比=rounddown(防御力/(1.7411*防御力+300)+防御力^0.5/500,2)
-- TODO expression --

-- old expression --
减伤百分比 X -> 减伤百分比=DFN/(DFN+卡牌当前等级+255)
-- old expression --
--]]
function ObjProp:GetDamageReduce()
	-- TODO expression --
	return math.floor(((self:GetDFN() / (1.7411 * self:GetDFN() + 300)) + self:GetDFN() ^ 0.5 * 0.002) * 100) * 0.01
	-- TODO expression --

	-- old expression --
	-- return self:GetDFN() / (self:GetDFN() + 255 + self.level)
	-- old expression --
end
--[[
获取等级碾压机制修正后的减伤百分比
减伤百分比 X -> 减伤百分比=DFN/(DFN+卡牌当前等级+255)
--]]
function ObjProp:GetFixedDamageReduceByLevelRolling(deltaLevel)
	local fixedDFN = self:GetFixedDFNByLevelRolling(deltaLevel)
	return fixedDFN / (fixedDFN + 255 + self.level)
end
--[[
获取修正后的技能伤害
技能伤害 -> (ATK*技能系数+技能常数)*(1-技能伤害百分比减成))*(1+技能伤害百分比加成)*伤害系数
@params value number 原始值
@params target obj 目标单位
@params buffType ConfigBuffType buff类型
--]]
function ObjProp:GetSkillDamage(value, target, buffType)
	local deltaLevel = 0
	if true == G_BattleLogicMgr:IsLevelRollingOpen() then
		deltaLevel = self.level - target:GetObjectLevel()
	end

	-- 计算技能基础伤害
	local damage = (self:GetATK() * checknumber(value[1]) + checknumber(value[2])) *
		(1 + self:Getpp(ObjPP.SKILL_DOWN) + self:Getpp(ObjPP.SKILL_UP))

	-- 计算职业修正系数
	local fix = 1
	if BattleObjectFeature.MELEE == target:GetOFeature()then
		fix = 1.2
	elseif BattleObjectFeature.REMOTE == target:GetOFeature() then
		fix = 0.9
	end

	damage = damage * fix

	-- 最终增伤系数 
	-- /***********************************************************************************************************************************\
	--  * 此处的增伤系数必定为正
	-- \***********************************************************************************************************************************/
	damage = damage * (1 + math.max(0, self:Getpp(ObjPP.CAUSE_DAMAGE_SKILL) + self:Getpp(ObjPP.CAUSE_DAMAGE_PHYSICAL) + self:GetAMPByTargetMonsterType(target:GetObjectMosnterType())))

	-- 计算等级碾压之后的伤害值
	damage = self:GetFixedDamageByLevelRolling(damage, deltaLevel)

	return damage
end
--[[
获取修正后的技能治疗量
@params value number 原始值
@params target obj 目标单位
@return _ number 修正值
--]]
function ObjProp:GetSkillHeal(value, target)
	local heal = value * (1 + self:Getpp(ObjPP.CAUSE_HEAL_SKILL) + self:Getpp(ObjPP.CAUSE_HEAL_ALL))
	return heal
end
--[[
获取等级碾压机制修正后的伤害值
等级高的卡牌技能伤害or普攻伤害 =round((技能伤害or普攻伤害)*(1+等级差*0.03+((等级差+1)^0.5/5.1)*10/100),0)
等级差超过30级,按照30级处理
等级低的卡牌技能伤害or普攻伤害 =round((技能伤害or普攻伤害)*(1-int(等级差/10.1)*10/100),0)
等级差超过60级,按照60级处理
@params damage number 伤害值
@params deltaLevel int 等级差
@return _ int 修正后的伤害值
--]]
function ObjProp:GetFixedDamageByLevelRolling(damage, deltaLevel)
	deltaLevel = math.min(ConfigBattleLevelRolling.HIGHER_MAX, math.max(ConfigBattleLevelRolling.LOWER_MIN, deltaLevel))
	if 0 > deltaLevel then
		return math.floor(damage * (1 - math.floor(math.abs(deltaLevel) / 10.1) * 0.1) + 0.5)
	elseif 0 < deltaLevel then
		return math.floor(damage * (1 + deltaLevel * 0.03 + (math.sqrt(deltaLevel + 1) / 5.1) * 0.1) + 0.5)
	else
		return damage
	end
end
--[[
获取修正后的dps
有效DPS -> ATK*(1+暴击率*(暴击伤害-1))/(1/每秒攻击数)
--]]
function ObjProp:GetDps()
	local atk = self:GetATK()
	return atk * (1 + self:GetCriticalRate() * 0.01 * (self:GetCriticalDamage() - 1)) * self:GetAttackRatePerSecond()
end
--[[
获取修正后的有效防御力
有效防御力 -> 生命值/(1-X)
--]]
function ObjProp:GetTough()
	return self:GetCurrentHp() / (1 - self:GetDamageReduce())
end
--[[
获取每秒攻击次数
每秒攻击次数 -> rounddown(((攻速值^2+9900)^(1/2)-67)/100,4)
--]]
function ObjProp:GetAttackRatePerSecond()
	return 1 / self:GetATKCounter()
end
--[[
获取攻击间隔
-- TODO expression --
当攻速值<=14042,
2.903784*(1-(攻速值-255)*0.00003515)
当攻速值>14042
2.903784*(1-(14042-255)*0.00003515)-((攻速值-14042)^0.2)^3/1500
-- TODO expression --

-- old expression --
攻击间隔 -> 攻击间隔=2.903784*(1-(攻速值-255)*0.00003515)
-- old expression --
--]]
function ObjProp:GetATKCounter()
	-- TODO expression --
	-- local threshold = 14042
	-- if threshold >= self:GetATKRate() then
	-- 	return 2.903784 * (1 - (self:GetATKRate() - 255) * 0.00003515)
	-- else
	-- 	return 2.903784 * (1 - (threshold - 255) * 0.00003515) - ((self:GetATKRate() - threshold) ^ 0.2) ^ 3 / 1500
	-- end
	-- TODO expression --

	-- old expression --
	return 2.903784 * (1 - (self:GetATKRate() - 255) * 0.00003515)
	-- old expression --
end
--[[
获取公式后的暴击几率 20% -> return 20
-- TODO expression --
当暴击值<=17222
ROUND(((暴击值-255)*0.0233+4.6115)/800,4)+0.1
当暴击值>17222
ROUND(((17222-255)*0.0233+4.6115)/800,4)+(暴击值-17222)^(1/3)/100+0.1
-- TODO expression --

-- old expression --
ROUND(((暴击伤害值-855)*0.0153+754.6965)/500,4)
-- old expression --

@return _ number 百分数
--]]
function ObjProp:GetCriticalRate()
	-- TODO expression --
	local threshold = 17222
	if threshold >= self:GetCRRate() then
		return math.min(100, (math.round(((self:GetCRRate() - 255) * 0.0233 + 4.6115) * 0.00125 * 10000) * 0.0001 + 0.1) * 100)
	else
		-- return math.min(100, (math.round(((threshold - 255) * 0.0233 + 4.6115) * 0.00125 * 10000) * 0.0001 + (self:GetCRRate() - threshold) ^ (1 / 3) * 0.01 + 0.1) * 100)
		return math.min(100, (0.4999 + (self:GetCRRate() - threshold) ^ (1 / 3) * 0.01 + 0.1) * 100)
	end
	-- TODO expression --

	-- old expression --
	-- return math.round(((self:GetCRRate() - 255) * 0.0233 + 4.6115) / 800 * 10000) * 0.01
	-- old expression --
end
--[[
获取公式后的暴击伤害
-- TODO expression --
ROUND(((暴击伤害值-855)*0.0153+754.6965)/500,4)
-- TODO expression --

-- old expression --
暴击伤害 -> 暴击伤害=ROUND(((暴击伤害值-855)*0.0153+754.6965)/500,4)
-- old expression --
--]]
function ObjProp:GetCriticalDamage()
	-- TODO expression --
	return math.round(((self:GetCRDamage() - 855) * 0.0153 + 754.6965) * 0.002 * 10000) * 0.0001
	-- TODO expression --

	-- old expression --
	-- return math.round(((self:GetCRDamage() - 855) * 0.0153 + 754.6965) / 500 * 10000) * 0.0001
	-- old expression --
end
--[[
获取公式后的治疗暴击伤害
暴击伤害 -> 治疗暴击=round(((暴击伤害值-246)*0.027+751.4534)/500,4)
--]]
function ObjProp:GetHealCriticalDamage()
	return math.round(((self:GetCRDamage() - 246) * 0.027 + 751.4534) / 500 * 10000) * 0.0001
end
--[[
获取战斗力
--]]
function ObjProp:GetBattlePoint()
	return math.ceil(math.round(self:GetDps() * self:GetTough() / 500) * 100) + 0
end
--[[
获取暴击率
--]]
function ObjProp:GetCRRate()
	return math.max(0, self:Getp(ObjP.CRITRATE) * (1 + self:Getpp(ObjPP.CR_RATE_A)) + self:Getpp(ObjPP.CR_RATE_B))
end
--[[
获取暴击伤害
--]]
function ObjProp:GetCRDamage()
	return math.max(0, self:Getp(ObjP.CRITDAMAGE) * (1 + self:Getpp(ObjPP.CR_DAMAGE_A)) + self:Getpp(ObjPP.CR_DAMAGE_B))
end
--[[
获取攻击速度
--]]
function ObjProp:GetATKRate()
	return math.max(0, math.min(25750, self:Getp(ObjP.ATTACKRATE) * (1 + self:Getpp(ObjPP.ATK_RATE_A)) + self:Getpp(ObjPP.ATK_RATE_B)))
end
--[[
获取当前生命值
--]]
function ObjProp:GetCurrentHp()
	return self:Getp(ObjP.HP)
end
--[[
获取最大生命值
--]]
function ObjProp:GetOriginalHp()
	return self:Getp(ObjP.HP, true) * (1 + self:Getpp(ObjPP.OHP_A)) + self:Getpp(ObjPP.OHP_B)
end
--[[
获取能量上限
--]]
function ObjProp:GetMaxEnergy()
	return self:Getp(ObjP.ENERGY, true)
end
--[[
获取修正后的普通攻击伤害
普通攻击伤害公式 -> (ATK*(1-伤害百分比减成))*(1+伤害百分比加成)*(1-(X*(1-减伤百分比减成))*(1+减伤百分比加成))*伤害系数
@params attacker BaseObject 攻击者
@params target BaseObject 被攻击者
@params externalDamageParameter ObjectExternalDamageParameterStruct 影响伤害的外部参数
@return _ number 最终伤害值
--]]
function ObjProp:GetAttackDamage(attacker, target, externalDamageParameter)
	-- 填充一次外部属性变化
	for k,v in pairs(externalDamageParameter.objppAttacker) do
		attacker:GetMainProperty():Changepp(k, v)
	end

	for k,v in pairs(externalDamageParameter.objppTarget) do
		target:GetMainProperty():Changepp(k, v)
	end

	-- 计算等级差值
	local deltaLevel = 0
	local deltaLevelReverse = 0
	-- 等级碾压存在开关
	if true == G_BattleLogicMgr:IsLevelRollingOpen() then
		deltaLevel = attacker:GetObjectLevel() - target:GetObjectLevel()
		deltaLevelReverse = target:GetObjectLevel() - attacker:GetObjectLevel()
	end
	-- print('here check delta level ?????????????????>>>>>>>>', attacker:getOCardName(), target:getOCardName(), deltaLevel, deltaLevelReverse)

	-- 计算伤害值
	local damage = (attacker:GetMainProperty():GetATK() * (1 + attacker:GetMainProperty():Getpp(ObjPP.CDAMAGE_DOWN)) * (1 + attacker:GetMainProperty():Getpp(ObjPP.CDAMAGE_UP))) *
		(1 - (target:GetMainProperty():GetFixedDamageReduceByLevelRolling(deltaLevelReverse) * (1 - target:GetMainProperty():Getpp(ObjPP.GDAMAGE_UP)) * (1 - target:GetMainProperty():Getpp(ObjPP.GDAMAGE_DOWN))))

	-- 计算职业修正系数
	local fix = 1
	if BattleObjectFeature.MELEE == attacker:GetOFeature() and BattleObjectFeature.REMOTE == target:GetOFeature() then
		fix = 1.05
	elseif BattleObjectFeature.REMOTE == attacker:GetOFeature() and BattleObjectFeature.MELEE == target:GetOFeature() then
		fix = 0.9
	end

	-- 判断是否产生暴击
	if externalDamageParameter.isCritical then
		damage = damage * attacker:GetMainProperty():GetCriticalDamage()
	end

	damage = damage * fix

	-- 最终增伤系数
	-- /***********************************************************************************************************************************\
	--  * 此处的增伤系数必定为正
	-- \***********************************************************************************************************************************/
	damage = damage * (1 + math.max(0, self:Getpp(ObjPP.CAUSE_DAMAGE_ATTACK) + self:Getpp(ObjPP.CAUSE_DAMAGE_PHYSICAL) + self:GetAMPByTargetMonsterType(target:GetObjectMosnterType())))

	-- 计算等级碾压之后的伤害值
	damage = attacker:GetMainProperty():GetFixedDamageByLevelRolling(damage, deltaLevel)

	-- 添加外部最终伤害
	damage = damage + externalDamageParameter.ultimateDamage

	-- 恢复外部属性变化
	for k,v in pairs(externalDamageParameter.objppAttacker) do
		attacker:GetMainProperty():Changepp(k, -v)
	end

	for k,v in pairs(externalDamageParameter.objppTarget) do
		target:GetMainProperty():Changepp(k, -v)
	end

	return damage
end
--[[
根据伤害值计算最终的增减伤
@params damage number 伤害
@params damageType DamageType 伤害类型
@return result number 修正后的伤害
--]]
function ObjProp:FixFinalGetDamage(damage, damageType)
	-- /***********************************************************************************************************************************\
	--  * 此处的减伤系数必定为负
	-- \***********************************************************************************************************************************/
	local result = damage

	if DamageType.ATTACK_PHYSICAL == damageType then

		result = result * math.max(0, 1 + math.min(0, self:Getpp(ObjPP.GET_DAMAGE_ATTACK)))

	elseif DamageType.SKILL_PHYSICAL == damageType then

		result = result * math.max(0, 1 + math.min(0, self:Getpp(ObjPP.GET_DAMAGE_SKILL)))

	end

	result = result * math.max(0, 1 + math.min(0, self:Getpp(ObjPP.GET_DAMAGE_PHYSICAL)))

	return result
end
--[[
获取修正后的平A治疗量
治疗数值 -> INT((ATK^0.5+(ATK+36)^0.7+(45+0.23*ATK))/2.5)
--]]
function ObjProp:GetHealing()
	local atk = self:GetATK()
	return math.floor((atk ^ 0.5 + (atk + 36) ^ 0.7 + (45 + 0.23 * atk)) * 0.4)
end
--[[
获取修正后的平a治疗量
@params externalDamageParameter ObjectExternalDamageParameterStruct 影响伤害的外部参数
@return heal int 治疗最终值
--]]
function ObjProp:GetFixedHealing(externalDamageParameter)
	---------- 填充一次外部属性变化 ----------
	for k,v in pairs(externalDamageParameter.objppAttacker) do
		self:Changepp(k, v)
	end
	---------- 填充一次外部属性变化 ----------

	-- 计算基础的治疗量
	local heal = self:GetHealing()

	-- 系数加成
	heal = heal * (1 + self:Getpp(ObjPP.CAUSE_HEAL_ATTACK) + self:Getpp(ObjPP.CAUSE_HEAL_ALL))

	---------- 判断是否产生暴击 ----------
	if externalDamageParameter.isCritical then
		heal = heal * self:GetHealCriticalDamage()
	end
	---------- 判断是否产生暴击 ----------

	---------- 恢复外部属性变化 ----------
	for k,v in pairs(externalDamageParameter.objppAttacker) do
		self:Changepp(k, -v)
	end
	---------- 恢复外部属性变化 ----------

	return heal
end
--[[
根据治疗量计算最终的受到治疗
@params heal number 治疗
@params damageType DamageType 治疗类型
@return result number 修正后的伤害
--]]
function ObjProp:FixFinalGetHeal(heal, damageType)
	local result = heal
	local pp = 0

	if DamageType.ATTACK_HEAL == damageType then

		pp = self:Getpp(ObjPP.GET_HEAL_ATTACK)

	elseif DamageType.SKILL_HEAL == damageType then

		pp = self:Getpp(ObjPP.GET_HEAL_SKILL)

	end

	result = result * math.max(0, 1 + pp + self:Getpp(ObjPP.GET_HEAL_ALL))

	return result
end
---------------------------------------------------
-- expression end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
获取属性
@params p ObjP 属性字段
@params o bool 是否获取原始属性
--]]
function ObjProp:Getp(p, o)
	if o then
		return self.op[p]
	else
		return self.p[p]
	end
end
--[[
设置属性
@params p ObjP 属性字段
@params v number 数值
@params o bool 是否获取原始属性
--]]
function ObjProp:Setp(p, v, o)
	if o then
		self.op[p] = v
	else
		self.p[p] = v
	end
end
--[[
根据属性类型获取当前加成后的属性
@params propertyType ObjP
@return _ number 加成后的属性
--]]
function ObjProp:GetCurrentP(propertyType)
	if ObjP.ATTACK == propertyType then

		-- 攻击力
		return self:GetATK()

	elseif ObjP.DEFENCE == propertyType then

		-- 防御力
		return self:GetDFN()

	elseif ObjP.HP == propertyType then

		-- 血量
		return self:GetCurrentHp()

	elseif ObjP.CRITRATE == propertyType then

		-- 暴击率
		return self:GetCRRate()

	elseif ObjP.CRITDAMAGE == propertyType then

		-- 暴击伤害
		return self:GetCRDamage()

	elseif ObjP.ATTACKRATE == propertyType then

		-- 攻击速度
		return self:GetATKRate()

	end

	return nil
end
--[[
根据属性类型获取原始的属性
@params propertyType ObjP
@return _ number 原始的属性
--]]
function ObjProp:GetOriginalP(propertyType)
	if ObjP.HP == propertyType then

		-- 血量
		return self:GetOriginalHp()

	else

		return self:Getp(true)

	end
end
--[[
获取当前的攻击距离
@return _ int 单位列
--]]
function ObjProp:GetCurrentAttackRange()
	return self.p.attackRange
end
--[[
获取当前的移动速度
@return _ number 单位像素
--]]
function ObjProp:GetCurrentMoveSpeed()
	return self.p.walkSpeed
end
--[[
获取属性系数
@params pp ObjPP obj属性
@return result 属性系数
--]]
function ObjProp:Getpp(pp)
	return self.pp[pp]
end
--[[
获取属性系数
@params pp ObjPP obj属性
@params value number 系数值
@return result 属性系数
--]]
function ObjProp:Setpp(pp, value)
	self.pp[pp] = value
end
--[[
当前生命百分比
--]]
function ObjProp:UpdateCurHpPercent()
	self.p.hpPercent = math.ceil(self:GetCurrentHp() / self:GetOriginalHp() * 100000) * 0.00001
end
function ObjProp:GetCurHpPercent()
	return self.p.hpPercent
end
function ObjProp:SetCurHpPercent(percent)
	self.p.hpPercent = percent
	self:Setp(ObjP.HP, self:GetOriginalHp() * self.p.hpPercent)
end
--[[
获取当前状态变化的血量
@return deltaHp int 变化的血量 不足1的部分向上取整
--]]
function ObjProp:GetDeltaHp()
	-- 当前血量
	local curHp = self:GetCurrentHp()
	-- 本次战斗初始化时的血量
	local fixedTotalHp = 0
	if nil ~= self.singleAddition then
		if nil ~= self.singleAddition.pvalue and self.singleAddition.pvalue[ObjP.HP] > 0 then
			fixedTotalHp = self.singleAddition.pvalue[ObjP.HP]
		elseif nil ~= self.singleAddition.pattr and self.singleAddition.pattr[ObjP.HP] > 0 then
			fixedTotalHp = self:Getp(ObjP.HP, true) * self.singleAddition.pattr[ObjP.HP]
		end
	else
		fixedTotalHp = self:Getp(ObjP.HP, true)
	end
	return math.ceil(fixedTotalHp - math.max(0, curHp))
end
--[[
根据目标物体类型获取增伤系数
@params monsterType ConfigMonsterType 物体类型
@return _ number 增伤系数
--]]
function ObjProp:GetAMPByTargetMonsterType(monsterType)
	------------ 根据物体单位计算增伤 ------------
	local ppConfig = {
		[ConfigMonsterType.CARD] 			= ObjPP.CDP_2_CARD,
		[ConfigMonsterType.NORMAL] 			= ObjPP.CDP_2_MONSER,
		[ConfigMonsterType.ELITE] 			= ObjPP.CDP_2_ELITE,
		[ConfigMonsterType.BOSS] 			= ObjPP.CDP_2_BOSS,
		[ConfigMonsterType.CHEST] 			= ObjPP.CDP_2_CHEST
	}
	------------ 根据物体单位计算增伤 ------------
	local pp = ppConfig[monsterType]
	if nil ~= pp then
		return self:Getpp(pp) or 0
	else
		return 0
	end
end
--[[
根据属性类型获取属性的最终加成
@params objp ObjP 属性类型
@return _ number 最终值的乘法系数
--]]
function ObjProp:GetUltimatePropertyAddition(objp)
	return self.ultimateAddition.pattr[objp] or 1
end
--[[
根据属性系数类型获取属性系数的最终加成
@params objpp ObjPP 属性系数类型
@return _ number 属性系数的乘法系数
--]]
function ObjProp:GetUltimatePPAddition(objpp)
	return self.ultimateAddition.ppattrA[objpp]
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return ObjProp
