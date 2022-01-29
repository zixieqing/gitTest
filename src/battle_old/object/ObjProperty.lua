--[[
战斗物体基础属性
@params ObjectPropertyConstructStruct 卡牌属性构造函数
--]]
local ObjProp = class('ObjProp')
local cardMgr = AppFacade.GetInstance():GetManager('CardManager')

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

	self.singleAddition = args.singleAddition
	self.ultimateAddition = args.ultimateAddition

	self.location = args.oriLocation

	self:init()
end
--[[
init logic
--]]
function ObjProp:init()
	-- 获取配表信息
	local objConfig = CardUtils.GetCardConfig(self.cardId)
	local cellSizeW = BMediator:GetBConf().cellSizeWidth
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

	-- 属性参数
	self:InitObjPP()

	-- 初始化一次外部属性系数配置
	self:initSinglePropertyAttr()
end
--[[
初始化个体属性参数 -> 刷新初始化的属性
--]]
function ObjProp:initSinglePropertyAttr()
	------------ 初始化单体外部属性的影响值 ------------
	if nil ~= self.singleAddition then
		for objp_, attr in pairs(self.singleAddition.pattr) do
			if nil ~= self.p[objp_] and attr >= 0 then
				self.p[objp_] = RBQN.New(self.p[objp_] * attr)
			end
		end

		for objp_, value in pairs(self.singleAddition.pvalue) do
			if nil ~= self.p[objp_] and value >= 0 then
				self.p[objp_] = RBQN.New(value)
			end
		end
	end
	------------ 初始化单体外部属性的影响值 ------------

	-- 刷新一次生命百分比
	self:updateCurHpPercent()
end
--[[
根据属性类型获取计算修正后的原始属性
@params objp ObjP
@return _ number 修正后的原始属性
--]]
function ObjProp:CalcFixedFinalOriginProperty(objp)
	local fixedP = RBQN.New(
		CardUtils.GetCardOneFixedP(self.cardId, objp, self.level, self.breakLevel, self.favorLevel, self.petAddition, self.artifactAddition) * self:GetUltimatePropertyAddition(objp)
	)
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

		self.pp[v] = RBQN.New(value)
		
	end
	
end
--[[
计算初始化的能量值
@params isLeader bool 是否是队长 队长拥有初始50点能量的加成值
@return result RBQN 能量值
--]]
function ObjProp:CalcFixedInitEnergy(isLeader)
	local result = self:GetMaxEnergy() * self.singleAddition.energyPercent + self.singleAddition.energyValue
	if true == isLeader then
		result = result + LEADER_ENERGY_ADD
	end
	result = math.max(0, math.min(self:GetMaxEnergy(), result))

	return RBQN.New(result)
end
---------------------------------------------------
-- logic begin --
---------------------------------------------------
--[[
变化属性参数
@params pp ObjPP 属性参数
@params delta number 变化量
--]]
function ObjProp:changepp(pp, delta)
	self:setpp(pp, self:getpp(pp) + delta)
end
--[[
传入一个血量变化值 判断该值是否致死
@params delta number 变化值
@return _ bool 是否致死
--]]
function ObjProp:isDamageDeadly(delta)
	return 0 < self:getCurrentHp():ObtainVal() and 0 >= self:getCurrentHp() + delta
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
function ObjProp:getATK()
	-- TODO expression --
	local threshold = rbqn_2000
	local atk = math.max(0, self:getp(ObjP.ATTACK) * (1 + self:getpp(ObjPP.ATTACK_A)) + self:getpp(ObjPP.ATTACK_B))
	if threshold:ObtainVal() >= atk then
		return atk
	else
		return threshold + (atk - threshold) ^ (rbqn_1_5) * rbqn_0_01
	end
	-- TODO expression --

	-- old expression --
	-- return math.max(0, self:getp(ObjP.ATTACK) * (1 + self:getpp(ObjPP.ATTACK_A)) + self:getpp(ObjPP.ATTACK_B))
	-- old expression --
end
--[[
获取修正后的防御力
防御力公式DFN -> 基础防御力*(1+(防御力系数加成-防御力系数减成))+(防御力常数加成-防御力常数减成)
--]]
function ObjProp:getDFN()
	return math.max(0, self:getp(ObjP.DEFENCE) * (1 + self:getpp(ObjPP.DEFENCE_A)) + self:getpp(ObjPP.DEFENCE_B))
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
function ObjProp:getFixedDFNByLevelRolling(deltaLevel)
	deltaLevel = math.min(ConfigBattleLevelRolling.HIGHER_MAX, math.max(ConfigBattleLevelRolling.LOWER_MIN, deltaLevel))
	if 0 > deltaLevel then
		return math.floor(self:getDFN() * (rbqn_1 - math.floor(math.abs(deltaLevel) / rbqn_10_1) * rbqn_0_1) + rbqn_0_5)
	elseif 0 < deltaLevel then
		return math.floor(self:getDFN() * (rbqn_1_1 + (math.sqrt(deltaLevel) / rbqn_4_1) * rbqn_0_1) + rbqn_0_5)
	else
		return self:getDFN()
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
function ObjProp:getDamageReduce()
	-- TODO expression --
	return math.floor(((self:getDFN() / (rbqn_1_7411 * self:getDFN() + rbqn_300)) + self:getDFN() ^ rbqn_0_5 * rbqn_0_002) * rbqn_100) * rbqn_0_01
	-- TODO expression --

	-- old expression --
	-- return self:getDFN() / (self:getDFN() + 255 + self.level)
	-- old expression --
end
--[[
获取等级碾压机制修正后的减伤百分比
减伤百分比 X -> 减伤百分比=DFN/(DFN+卡牌当前等级+255)
--]]
function ObjProp:getFixedDamageReduceByLevelRolling(deltaLevel)
	local fixedDFN = self:getFixedDFNByLevelRolling(deltaLevel)
	return fixedDFN / (fixedDFN + rbqn_255 + self.level)
end
--[[
获取修正后的技能伤害
技能伤害 -> (ATK*技能系数+技能常数)*(1-技能伤害百分比减成))*(1+技能伤害百分比加成)*伤害系数
@params value number 原始值
@params target obj 目标单位
--]]
function ObjProp:getSkillDamage(value, target)
	local deltaLevel = 0
	if true == BMediator:GetBData():getBattleConstructData().levelRolling then
		deltaLevel = self.level - target:getObjectLevel()
	end

	-- 计算技能基础伤害
	local damage = (self:getATK() * checknumber(value[1]) + checknumber(value[2])) *
		(1 + self:getpp(ObjPP.SKILL_DOWN) + self:getpp(ObjPP.SKILL_UP))

	-- 计算职业修正系数
	local fix = rbqn_1
	if BattleObjectFeature.MELEE == target:getOFeature()then
		fix = rbqn_1_2
	elseif BattleObjectFeature.REMOTE == target:getOFeature() then
		fix = rbqn_0_9
	end

	damage = damage * fix

	-- 最终增伤系数 
	-- /***********************************************************************************************************************************\
	--  * 此处的增伤系数必定为正
	-- \***********************************************************************************************************************************/
	damage = damage * (rbqn_1 + math.max(0, self:getpp(ObjPP.CAUSE_DAMAGE_SKILL) + self:getpp(ObjPP.CAUSE_DAMAGE_PHYSICAL) + self:getAMPByTargetMonsterType(target:getObjectMosnterType())))

	-- 计算等级碾压之后的伤害值
	damage = self:getFixedDamageByLevelRolling(damage, deltaLevel)

	return RBQN.New(damage)
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
function ObjProp:getFixedDamageByLevelRolling(damage, deltaLevel)
	deltaLevel = math.min(ConfigBattleLevelRolling.HIGHER_MAX, math.max(ConfigBattleLevelRolling.LOWER_MIN, deltaLevel))
	if 0 > deltaLevel then
		return math.floor(damage * (rbqn_1 - math.floor(math.abs(deltaLevel) / rbqn_10_1) * rbqn_0_1) + rbqn_0_5)
	elseif 0 < deltaLevel then
		return math.floor(damage * (rbqn_1 + deltaLevel * rbqn_0_03 + (math.sqrt(deltaLevel + rbqn_1) / rbqn_5_1) * rbqn_0_1) + rbqn_0_5)
	else
		return damage
	end
end
--[[
获取修正后的dps
有效DPS -> ATK*(1+暴击率*(暴击伤害-1))/(1/每秒攻击数)
--]]
function ObjProp:getDps()
	local atk = self:getATK()
	return atk * (rbqn_1 + self:getCriticalRate() * rbqn_0_01 * (self:getCriticalDamage() - rbqn_1)) * self:getAttackRatePerSecond()
end
--[[
获取修正后的有效防御力
有效防御力 -> 生命值/(1-X)
--]]
function ObjProp:getTough()
	return self:getCurrentHp() / (rbqn_1 - self:getDamageReduce())
end
--[[
获取每秒攻击次数
每秒攻击次数 -> rounddown(((攻速值^2+9900)^(1/2)-67)/100,4)
--]]
function ObjProp:getAttackRatePerSecond()
	return rbqn_1 / self:getATKCounter()
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
function ObjProp:getATKCounter()
	-- TODO expression --
	-- local threshold = 14042
	-- if threshold >= self:getATKRate() then
	-- 	return 2.903784 * (1 - (self:getATKRate() - 255) * 0.00003515)
	-- else
	-- 	return 2.903784 * (1 - (threshold - 255) * 0.00003515) - ((self:getATKRate() - threshold) ^ 0.2) ^ 3 / 1500
	-- end
	-- TODO expression --

	-- old expression --
	return rbqn_2_903784 * (rbqn_1 - (self:getATKRate() - rbqn_255) * rbqn_0_00003515)
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
--]]
function ObjProp:getCriticalRate()
	-- TODO expression --
	local threshold = rbqn_17222
	if threshold:ObtainVal() >= self:getCRRate() then
		return math.min(100, (math.round(((self:getCRRate() - rbqn_255) * rbqn_0_0233 + rbqn_4_6115) * rbqn_0_00125 * rbqn_10000) * rbqn_0_0001 + rbqn_0_1) * rbqn_100)
	else
		-- return math.min(100, (math.round(((threshold - 255) * 0.0233 + 4.6115) * 0.00125 * 10000) * 0.0001 + (self:getCRRate() - threshold) ^ (1 / 3) * 0.01 + 0.1) * 100)
		return math.min(100, (rbqn_0_4999 + (self:getCRRate() - threshold) ^ (rbqn_0_333) * rbqn_0_01 + rbqn_0_1) * rbqn_100)
	end
	-- TODO expression --

	-- old expression --
	-- return math.round(((self:getCRRate() - 255) * 0.0233 + 4.6115) / 800 * 10000) * 0.01
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
function ObjProp:getCriticalDamage()
	-- TODO expression --
	return math.round(((self:getCRDamage() - rbqn_855) * rbqn_0_0153 + rbqn_754_6965) * rbqn_0_002 * rbqn_10000) * rbqn_0_0001
	-- TODO expression --

	-- old expression --
	-- return math.round(((self:getCRDamage() - 855) * 0.0153 + 754.6965) / 500 * 10000) * 0.0001
	-- old expression --
end
--[[
获取公式后的治疗暴击伤害
暴击伤害 -> 治疗暴击=round(((暴击伤害值-246)*0.027+751.4534)/500,4)
--]]
function ObjProp:getHealCriticalDamage()
	return math.round(((self:getCRDamage() - rbqn_246) * rbqn_0_027 + rbqn_751_4534) / rbqn_500 * rbqn_10000) * rbqn_0_0001
end
--[[
获取战斗力
--]]
function ObjProp:getBattlePoint()
	return math.ceil(math.round(self:getDps() * self:getTough() / rbqn_500) * rbqn_100) + 0
end
--[[
获取暴击率
--]]
function ObjProp:getCRRate()
	return math.max(0, self:getp(ObjP.CRITRATE) * (1 + self:getpp(ObjPP.CR_RATE_A)) + self:getpp(ObjPP.CR_RATE_B))
end
--[[
获取暴击伤害
--]]
function ObjProp:getCRDamage()
	return math.max(0, self:getp(ObjP.CRITDAMAGE) * (1 + self:getpp(ObjPP.CR_DAMAGE_A)) + self:getpp(ObjPP.CR_DAMAGE_B))
end
--[[
获取攻击速度
--]]
function ObjProp:getATKRate()
	return math.max(0, math.min(rbqn_25750:ObtainVal(), self:getp(ObjP.ATTACKRATE) * (1 + self:getpp(ObjPP.ATK_RATE_A)) + self:getpp(ObjPP.ATK_RATE_B)))
end
--[[
获取当前生命值
--]]
function ObjProp:getCurrentHp()
	return self:getp(ObjP.HP)
end
--[[
获取最大生命值
--]]
function ObjProp:getOriginalHp()
	return RBQN.New(self:getp(ObjP.HP, true) * (1 + self:getpp(ObjPP.OHP_A)) + self:getpp(ObjPP.OHP_B))
end
--[[
获取能量上限
--]]
function ObjProp:GetMaxEnergy()
	return self:getp(ObjP.ENERGY, true)
end
--[[
获取修正后的普通攻击伤害
普通攻击伤害公式 -> (ATK*(1-伤害百分比减成))*(1+伤害百分比加成)*(1-(X*(1-减伤百分比减成))*(1+减伤百分比加成))*伤害系数
@params attacker BaseObject 攻击者
@params target BaseObject 被攻击者
@params externalDamageParameter ObjectExternalDamageParameterStruct 影响伤害的外部参数
@return _ number 最终伤害值
--]]
function ObjProp:getAttackDamage(attacker, target, externalDamageParameter)
	-- 填充一次外部属性变化
	for k,v in pairs(externalDamageParameter.objppAttacker) do
		attacker:getMainProperty():changepp(k, v)
	end

	for k,v in pairs(externalDamageParameter.objppTarget) do
		target:getMainProperty():changepp(k, v)
	end

	-- 计算等级差值
	local deltaLevel = 0
	local deltaLevelReverse = 0
	-- 等级碾压存在开关
	if true == BMediator:GetBData():getBattleConstructData().levelRolling then
		deltaLevel = attacker:getObjectLevel() - target:getObjectLevel()
		deltaLevelReverse = target:getObjectLevel() - attacker:getObjectLevel()
	end
	-- print('here check delta level ?????????????????>>>>>>>>', attacker:getOCardName(), target:getOCardName(), deltaLevel, deltaLevelReverse)

	-- 计算伤害值
	local damage = (attacker:getMainProperty():getATK() * (1 + attacker:getMainProperty():getpp(ObjPP.CDAMAGE_DOWN)) * (1 + attacker:getMainProperty():getpp(ObjPP.CDAMAGE_UP))) *
		(1 - (target:getMainProperty():getFixedDamageReduceByLevelRolling(deltaLevelReverse) * (1 - target:getMainProperty():getpp(ObjPP.GDAMAGE_UP)) * (1 - target:getMainProperty():getpp(ObjPP.GDAMAGE_DOWN))))

	-- 计算职业修正系数
	local fix = rbqn_1
	if BattleObjectFeature.MELEE == attacker:getOFeature() and BattleObjectFeature.REMOTE == target:getOFeature() then
		fix = rbqn_1_05
	elseif BattleObjectFeature.REMOTE == attacker:getOFeature() and BattleObjectFeature.MELEE == target:getOFeature() then
		fix = rbqn_0_9
	end

	-- 判断是否产生暴击
	if externalDamageParameter.isCritical then
		damage = damage * attacker:getMainProperty():getCriticalDamage()
	end

	damage = damage * fix

	-- 最终增伤系数
	-- /***********************************************************************************************************************************\
	--  * 此处的增伤系数必定为正
	-- \***********************************************************************************************************************************/
	damage = damage * (rbqn_1 + math.max(0, self:getpp(ObjPP.CAUSE_DAMAGE_ATTACK) + self:getpp(ObjPP.CAUSE_DAMAGE_PHYSICAL) + self:getAMPByTargetMonsterType(target:getObjectMosnterType())))

	-- 计算等级碾压之后的伤害值
	damage = attacker:getMainProperty():getFixedDamageByLevelRolling(damage, deltaLevel)

	-- 添加外部最终伤害
	damage = damage + externalDamageParameter.ultimateDamage

	-- 恢复外部属性变化
	for k,v in pairs(externalDamageParameter.objppAttacker) do
		attacker:getMainProperty():changepp(k, -v)
	end

	for k,v in pairs(externalDamageParameter.objppTarget) do
		target:getMainProperty():changepp(k, -v)
	end

	return RBQN.New(damage)
end
--[[
根据伤害值计算最终的增减伤
@params damage number 伤害
@params damageType DamageType 伤害类型
@return result number 修正后的伤害
--]]
function ObjProp:fixFinalGetDamage(damage, damageType)
	-- /***********************************************************************************************************************************\
	--  * 此处的减伤系数必定为负
	-- \***********************************************************************************************************************************/
	local result = damage

	if DamageType.ATTACK_PHYSICAL == damageType then

		result = result * math.max(0, 1 + math.min(0, self:getpp(ObjPP.GET_DAMAGE_ATTACK):ObtainVal()))

	elseif DamageType.SKILL_PHYSICAL == damageType then

		result = result * math.max(0, 1 + math.min(0, self:getpp(ObjPP.GET_DAMAGE_SKILL):ObtainVal()))

	end

	result = result * math.max(0, 1 + math.min(0, self:getpp(ObjPP.GET_DAMAGE_PHYSICAL):ObtainVal()))

	return RBQN.New(result)
end
--[[
获取修正后的平A治疗量
治疗数值 -> INT((ATK^0.5+(ATK+36)^0.7+(45+0.23*ATK))/2.5)
--]]
function ObjProp:getHealing()
	local atk = self:getATK()
	return RBQN.New(math.floor((atk ^ rbqn_0_5 + (atk + rbqn_36) ^ rbqn_0_7 + (rbqn_45 + rbqn_0_23 * atk)) * rbqn_0_4))
end
--[[
获取修正后的平a治疗量
@params externalDamageParameter ObjectExternalDamageParameterStruct 影响伤害的外部参数
@return heal int 治疗最终值
--]]
function ObjProp:getFixedHealing(externalDamageParameter)
	---------- 填充一次外部属性变化 ----------
	for k,v in pairs(externalDamageParameter.objppAttacker) do
		self:changepp(k, v)
	end
	---------- 填充一次外部属性变化 ----------

	local heal = self:getHealing()

	---------- 判断是否产生暴击 ----------
	if externalDamageParameter.isCritical then
		heal = heal * self:getHealCriticalDamage()
	end
	---------- 判断是否产生暴击 ----------

	---------- 恢复外部属性变化 ----------
	for k,v in pairs(externalDamageParameter.objppAttacker) do
		self:changepp(k, -v)
	end
	---------- 恢复外部属性变化 ----------

	return RBQN.New(heal)
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
function ObjProp:getp(p, o)
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
function ObjProp:setp(p, v, o)
	if o then
		self.op[p] = RBQN.New(v)
	else
		self.p[p] = RBQN.New(v)
	end
end
--[[
根据属性类型获取当前加成后的属性
@params propertyType ObjP
@return _ number 加成后的属性
--]]
function ObjProp:getCurrentP(propertyType)
	if ObjP.ATTACK == propertyType then

		-- 攻击力
		return self:getATK()

	elseif ObjP.DEFENCE == propertyType then

		-- 防御力
		return self:getDFN()

	elseif ObjP.HP == propertyType then

		-- 血量
		return self:getCurrentHp()

	elseif ObjP.CRITRATE == propertyType then

		-- 暴击率
		return self:getCRRate()

	elseif ObjP.CRITDAMAGE == propertyType then

		-- 暴击伤害
		return self:getCRDamage()

	elseif ObjP.ATTACKRATE == propertyType then

		-- 攻击速度
		return self:getATKRate()

	end

	return nil
end
--[[
根据属性类型获取原始的属性
@params propertyType ObjP
@return _ number 原始的属性
--]]
function ObjProp:getOriginalP(propertyType)
	if ObjP.HP == propertyType then

		-- 血量
		return self:getOriginalHp()

	else

		return self:getp(true)

	end
end
--[[
获取属性系数
@params pp ObjPP obj属性
@return result 属性系数
--]]
function ObjProp:getpp(pp)
	return self.pp[pp]
end
--[[
获取属性系数
@params pp ObjPP obj属性
@params value number 系数值
@return result 属性系数
--]]
function ObjProp:setpp(pp, value)
	self.pp[pp] = RBQN.New(value)
end
--[[
当前生命百分比
--]]
function ObjProp:updateCurHpPercent()
	self.p.hpPercent = math.ceil(self:getCurrentHp() / self:getOriginalHp() * 100000) * 0.00001
end
function ObjProp:getCurHpPercent()
	return self.p.hpPercent
end
function ObjProp:setCurHpPercent(percent)
	self.p.hpPercent = percent
	self:setp(ObjP.HP, self:getOriginalHp() * self.p.hpPercent)
end
--[[
获取当前状态变化的血量
@return deltaHp int 变化的血量 不足1的部分向上取整
--]]
function ObjProp:getDeltaHp()
	-- 当前血量
	local curHp = self:getCurrentHp():ObtainVal()
	-- 本次战斗初始化时的血量
	local fixedTotalHp = 0
	if nil ~= self.singleAddition then
		if nil ~= self.singleAddition.pvalue and self.singleAddition.pvalue[ObjP.HP] > 0 then
			fixedTotalHp = self.singleAddition.pvalue[ObjP.HP]
		elseif nil ~= self.singleAddition.pattr and self.singleAddition.pattr[ObjP.HP] > 0 then
			fixedTotalHp = self:getp(ObjP.HP, true) * self.singleAddition.pattr[ObjP.HP]
		end
	else
		fixedTotalHp = self:getp(ObjP.HP, true):ObtainVal()
	end
	return math.ceil(math.max(0, fixedTotalHp - math.max(0, curHp)))
end
--[[
根据目标物体类型获取增伤系数
@params monsterType ConfigMonsterType 物体类型
@return _ number 增伤系数
--]]
function ObjProp:getAMPByTargetMonsterType(monsterType)
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
		return self:getpp(pp) or 0
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
