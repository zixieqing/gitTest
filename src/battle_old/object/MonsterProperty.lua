--[[
怪物属性类 算法略有区别 怪物没有等级和成长表 只有最终成长加成
@params MonsterPropertyConstructStruct 
--]]
local ObjProp = __Require('battle.object.ObjProperty')
local MonsterProp = class('MonsterProp', ObjProp)

local cardMgr = AppFacade.GetInstance():GetManager('CardManager')

------------ define ------------
------------ define ------------

--[[
construtor
--]]
function MonsterProp:ctor( ... )
	local args = unpack({...})

	self.cardId = args.cardId
	self.level = args.level
	self.attrGrow = args.attrGrow
	self.skillGrow = args.skillGrow
	self.location = args.oriLocation
	self.singleAddition = args.singleAddition
	self.ultimateAddition = args.ultimateAddition

	self:init()
end
--[[
init logic
--]]
function MonsterProp:init()
	if 0 == self.attrGrow then print('monster grow attr is invalid', self.cardId) end

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
		[ObjP.ENERGY] 		= MAX_ENERGY, -- 能量上限
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
根据属性类型获取计算修正后的原始属性
@params objp ObjP
@return _ number 修正后的原始属性
--]]
function MonsterProp:CalcFixedFinalOriginProperty(objp)
	local objConfig = CardUtils.GetCardConfig(self.cardId)
	local fixedP = RBQN.New(checknumber(objConfig[CardUtils.GetCardPCommonName(objp)]) * self.attrGrow * self:GetUltimatePropertyAddition(objp))
	return fixedP
end
--[[
计算初始化的能量值
@params isLeader bool 是否是队长 怪物没有能量奖励
@return result RBQN 能量值
--]]
function MonsterProp:CalcFixedInitEnergy(isLeader)
	local result = self:GetMaxEnergy() * self.singleAddition.energyPercent + self.singleAddition.energyValue
	result = math.max(0, math.min(self:GetMaxEnergy(), result))

	return RBQN.New(result)
end

--[[
@override
获取修正后的减伤百分比
减伤百分比 X -> 减伤百分比=DFN/(DFN+卡牌当前等级+280)
--]]
function MonsterProp:getDamageReduce()
	return self:getDFN() / (self:getDFN() + rbqn_280)
end
--[[
@override
获取等级碾压机制修正后的减伤百分比
减伤百分比 X -> 减伤百分比=DFN/(DFN+卡牌当前等级+280)
--]]
function ObjProp:getFixedDamageReduceByLevelRolling(deltaLevel)
	local fixedDFN = self:getFixedDFNByLevelRolling(deltaLevel)
	return fixedDFN / (fixedDFN + rbqn_280)
end
--[[
@override
获取修正后的技能伤害
技能伤害 -> (ATK*技能系数+技能常数)*(1-技能伤害百分比减成))*(1+技能伤害百分比加成)*伤害系数
@params value number 原始值
@params target obj 目标单位
@return damage number 修正后的伤害
--]]
function MonsterProp:getSkillDamage(value, target)
	local deltaLevel = 0
	if true == BMediator:GetBData():getBattleConstructData().levelRolling then
		deltaLevel = self.level - target:getObjectLevel()
	end
	
	-- 计算基础伤害
	local damage = (self:getATK() * checknumber(value[1]) + checknumber(value[2])) *
		(1 + self:getpp(ObjPP.SKILL_DOWN) + self:getpp(ObjPP.SKILL_UP))
	local fix = rbqn_1
	if BattleObjectFeature.MELEE == target:getOFeature()then
		fix = rbqn_1_2
	elseif BattleObjectFeature.REMOTE == target:getOFeature() then
		fix = rbqn_0_9
	end
	damage = damage * fix * self.skillGrow

	-- 最终增伤系数 
	-- /***********************************************************************************************************************************\
	--  * 此处的增伤系数必定为正
	-- \***********************************************************************************************************************************/
	damage = damage * (1 + math.max(0, self:getpp(ObjPP.CAUSE_DAMAGE_SKILL) + self:getpp(ObjPP.CAUSE_DAMAGE_PHYSICAL) + self:getAMPByTargetMonsterType(target:getObjectMosnterType())))

	-- 根据等级碾压机制计算修正伤害
	damage = self:getFixedDamageByLevelRolling(damage, deltaLevel)

	return RBQN.New(damage)
end

return MonsterProp
