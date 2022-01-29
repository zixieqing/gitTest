--[[
爬塔契约的技能模型
-- /== TODO =================================================================================================================================\
--  = 新的爬塔效果逻辑需要改配表 [爬塔契约表中添加字段skills 这个是爬塔契约的实际效果]
-- \== TODO =================================================================================================================================/
@params {
	towerContractId int 爬塔技能id
}
--]]
local BaseSkill = __Require('battle.skill.BaseSkill')
local TowerContractSkill = class('TowerContractSkill', BaseSkill)

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

--[[
constructor
--]]
function TowerContractSkill:ctor( ... )
	local args = unpack({...})

	self.towerContractId = args.towerContractId
	self.buffSeekRule = {}
	self.castedBattleTime = false

	BaseSkill.ctor(self, ...)
end

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
@override
初始化一次buff信息
--]]
function TowerContractSkill:InitBuffsInfo()
	local towerContractConfig = CommonUtils.GetConfig('tower', 'towerContract', self:GetTowerContractId())
	if nil ~= towerContractConfig then
		local buffs = towerContractConfig.fullBuff
		local sk = sortByKey(buffs)

		for _, buffType_ in ipairs(sk) do

			local buffConfig = buffs[buffType_]
			local buffInfo, seekRuleInfo = self:ConvertData(buffConfig, towerContractConfig.fullBuffTarget[buffType_])

			table.insert(self.buffInfos, 1, buffInfo)
			self.buffSeekRule[buffInfo.btype] = seekRuleInfo

		end
	end
end
--[[
将爬塔契约的配表内容转换为技能模型兼容的数据
@params buffConfig table 爬塔契约的内容
@params buffSeekRuleConfig table 爬塔buff的索敌配置
@return buffInfo ObjectBuffConstructorStruct buff的构造信息
--]]
function TowerContractSkill:ConvertData(buffConfig, buffSeekRuleConfig)
	local buffMapping = {
		[ConfigGlobalBuffType.BATTLE_TIME_A] 	= {
			buffType = ConfigBuffType.BATTLE_TIME, buffClassName = 'battle.buff.BattleTimeBuff', causeEffectTime = BuffCauseEffectTime.INSTANT, 

		},

		[ConfigGlobalBuffType.OHP_A] = {
			buffType = ConfigBuffType.OHP_A, buffClassName = 'battle.buff.AbilityBuff', causeEffectTime = BuffCauseEffectTime.ADD2OBJ, 
		},

		[ConfigGlobalBuffType.ATTACK_A] = {
			buffType = ConfigBuffType.ATTACK_A, buffClassName = 'battle.buff.AbilityBuff', causeEffectTime = BuffCauseEffectTime.ADD2OBJ, 
		},

		[ConfigGlobalBuffType.DEFENCE_A] 	= {
			buffType = ConfigBuffType.DEFENCE_A, buffClassName = 'battle.buff.AbilityBuff', causeEffectTime = BuffCauseEffectTime.ADD2OBJ, 
		},

		[ConfigGlobalBuffType.IMMUNE_ATTACK_PHYSICAL] = {
			buffType = ConfigBuffType.IMMUNE_ATTACK_PHYSICAL, buffClassName = 'battle.buff.ImmuneBuff', causeEffectTime = BuffCauseEffectTime.ADD2OBJ, 
		},

		[ConfigGlobalBuffType.IMMUNE_SKILL_PHYSICAL] = {
			buffType = ConfigBuffType.IMMUNE_SKILL_PHYSICAL, buffClassName = 'battle.buff.ImmuneBuff', causeEffectTime = BuffCauseEffectTime.ADD2OBJ, 
		},

		[ConfigGlobalBuffType.CDAMAGE_A] = {
			buffType = ConfigBuffType.CDAMAGE_A, buffClassName = 'battle.buff.AbilityBuff', causeEffectTime = BuffCauseEffectTime.ADD2OBJ, 
		}
	}

	local towerContractType = checkint(buffConfig.type)
	local convertInfo = buffMapping[towerContractType]
	local buffConf = CommonUtils.GetConfig('cards', 'skillType', checkint(convertInfo.buffType))

	local buffInfo = ObjectBuffConstructorStruct.New(
		nil,
		tostring(convertInfo.buffType) .. self:GetTowerContractId() .. self:GetSkillCasterTag(),
		convertInfo.buffType,
		BKIND.BASE,
		0,
		self:GetSkillCasterTag(),
		false,
		true,
		convertInfo.buffClassName,
		convertInfo.causeEffectTime,
		buffConfig.effect,
		999,
		nil,
		nil,
		0,
		checkint(buffConf.buffIcon),
		{},
		{}
	)

	local seekRule = SeekRuleStruct.New(
		checkint(buffSeekRuleConfig.type),
		SeekSortRule.S_NONE,
		999
	)

	return buffInfo, seekRule
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- logic begin --
---------------------------------------------------
--[[
释放该技能
@params params ObjectCastParameterStruct 外部传参
--]]
function TowerContractSkill:Cast(params)
	---------- 处理技能信息 ----------
	params = params or {}
	params.percent = params.percent or 1
	params.skillExtra = params.skillExtra or 1
	params.shouldShakeWorld = params.shouldShakeWorld or false

	self:SetSkillPhase(self:GetSkillPhase() + 1)
	---------- 处理技能信息 ----------

	---------- 优先释放非buff类型 ----------
	if 1 == self:GetSkillPhase() then
		-- ### serialized ### --
		local buffInfo = nil
		for i = #self.nonbuffInfos, 1, -1 do
			buffInfo = self.nonbuffInfos[i]
			local buff = __Require(buffInfo.className).new(buffInfo)
			buff:OnCauseEffectEnter()
		end
	end
	---------- 优先释放非buff类型 ----------

	self:BaseCast(self:GetTargetPool())
end
--[[
转换数据结构
@params params ObjectCastParameterStruct 外部传参
@return result table target -> buff 映射
--]]
function TowerContractSkill:ConvertBuffTargetData(params)
	local result = {}

	---------- 初始化一些由caster确定的参数 ----------
	local casterPos = cc.p(0, 0)
	local caster = self:GetSkillCaster()
	if caster then
		casterPos = caster:GetLocation().po
	end
	---------- 初始化一些由caster确定的参数 ----------

	local buffType_ = nil
	local buffInfo_ = nil

	local bufftargets = {}
	local doneSeekRule = nil

	local buffConditionTargets = {}
	local doneConditionSeekRule = nil

	local tmpTargetTagIdx = {}

	for i = #self.buffInfos, 1, -1 do
		buffInfo_ = self.buffInfos[i]
		buffType_ = buffInfo_.btype

		if ConfigBuffType.BATTLE_TIME == buffType_ then
			if not self.castedBattleTime then
				-- 战斗时间buff 写死受法者 全局物体
				local tTag = G_BattleLogicMgr:GetGlobalEffectObj():GetOTag()
				local buffInfo = clone(buffInfo_)
				buffInfo.ownerTag = tTag
				if nil == tmpTargetTagIdx[tostring(tTag)] then
					-- waring !!! --
					-- may cause logic error
					-- waring !!! --
					table.insert(result, {tag = tTag, buffs = {}, needRevive = (ConfigBuffType.REVIVE == buffType_)})
					tmpTargetTagIdx[tostring(tTag)] = #result
				end
				table.insert(result[tmpTargetTagIdx[tostring(tTag)]].buffs, buffInfo)

				self.castedBattleTime = true
			end
		else

			local seekRuleBuffType = buffInfo_:GetSeekRuleBuffType()
			local searchConf = self:GetBuffSeekRuleConfigByBuffType(seekRuleBuffType)

			-- 遍历一遍已有对象池 如果发现索敌规则完全相同的buff 则直接使用该buff索敌结果
			local sk = sortByKey(bufftargets)
			for i,v in ipairs(sk) do
				local tSeekRuleBuffType = v

				doneSeekRule = self:GetBuffSeekRuleConfigByBuffType(tSeekRuleBuffType)
				if searchConf == doneSeekRule then
					bufftargets[tostring(seekRuleBuffType)] = bufftargets[tSeekRuleBuffType]
					break
				end
			end

			-- 若不存在对象 进行一次索敌
			if nil == bufftargets[tostring(seekRuleBuffType)] then
				if ConfigBuffType.REVIVE == buffType_ then
					bufftargets[tostring(seekRuleBuffType)] = self:SeekCastDeadTargets(
						self:GetIsSkillEnemy(),
						searchConf,
						{pos = casterPos, o = caster, triggerData = params.triggerData}
					)
				else
					bufftargets[tostring(seekRuleBuffType)] = self:SeekCastTargets(
						self:GetIsSkillEnemy(),
						searchConf,
						{pos = casterPos, o = caster, triggerData = params.triggerData}
					)
				end
			end

			local tTag = nil
			for i, target in ipairs(bufftargets[tostring(seekRuleBuffType)]) do
				tTag = target:GetOTag()
				local buffInfo = clone(buffInfo_)
				buffInfo.ownerTag = tTag

				---------- 修正buff实际值 ----------
				self:ConvertConfigValue2RealValue(caster, target, buffInfo_.value, buffInfo, params.skillExtra, 1)
				---------- 修正buff实际值 ----------

				---------- 分段机制 初始化伤害池 ----------

				---------- 整合数据结构 ----------
				if nil == tmpTargetTagIdx[tostring(tTag)] then
					-- waring !!! --
					-- may cause logic error
					-- waring !!! --
					table.insert(result, {tag = tTag, buffs = {}, needRevive = (ConfigBuffType.REVIVE == buffType_)})
					tmpTargetTagIdx[tostring(tTag)] = #result
				end
				table.insert(result[tmpTargetTagIdx[tostring(tTag)]].buffs, buffInfo)
				---------- 整合数据结构 ----------
			end

		end
	end

	return result
end
---------------------------------------------------
-- logic end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
获取爬塔契约id
@return _ int
--]]
function TowerContractSkill:GetTowerContractId()
	return self.towerContractId
end
--[[
获取技能的施法者tag
--]]
function TowerContractSkill:GetSkillCasterTag()
	return self:GetSkillCaster():GetOTag()
end
--[[
获取技能的施法者物体
--]]
function TowerContractSkill:GetSkillCaster()
	return G_BattleLogicMgr:GetGlobalEffectObj()
end
--[[
根据buff类型获取索敌规则
@params buffType ConfigBuffType buff类型
@return _ SeekRuleStruct 索敌类型
--]]
function TowerContractSkill:GetBuffSeekRuleConfigByBuffType(buffType)
	return self.buffSeekRule[buffType]
end
--[[
获取传染的时间间隔
--]]
function TowerContractSkill:GetSkillInfectTime()
	return 0
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return TowerContractSkill
