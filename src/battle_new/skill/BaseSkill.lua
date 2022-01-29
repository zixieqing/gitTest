--[[
技能模型基类
@params args SkillConstructorStruct 技能构造数据 
--]]
local BaseSkill = class('BaseSkill')

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

--[[
constructor
--]]
function BaseSkill:ctor( ... )
	local args = unpack({...})

	self.skillData = args
	-- dump(args)
	-- dump(self.skillData)
	-- dump(self.skillData.skillInfo)

	self:Init()
end

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化技能模型
--]]
function BaseSkill:Init()
	self:InitValue()
	self:InitBuffsInfo()
end
--[[
初始化技能数据
--]]
function BaseSkill:InitValue()
	-- 分段计数
	self.phase = 0
	-- 用于分段的对象池
	self.targetPool = {}
	-- 技能的最长持续时间
	self.durationTime = 0
	-- 正常的附加型buff
	self.buffInfos = {}
	-- 特殊的技能类型 该类型不会索敌
	self.nonbuffInfos = {}
end
--[[
初始化一次buff信息
--]]
function BaseSkill:InitBuffsInfo()
	local sk = sortByKey(self:GetBuffsConfig())
	-- 初始化buff信息
	for i,v in ipairs(sk) do
		local buffType_ = v
		local buffConfig_ = self:GetBuffsConfig()[v]

		if ConfigBuffType.BECKON == buffConfig_.buffType then

			---------- 召唤特殊技能 非buff类型 ----------
			local buffInfo = ObjectBuffConstructorStruct.New(
				self:GetSkillId(),
				tostring(buffConfig_.buffType),
				buffConfig_.buffType,
				BKIND.BASE,
				0,
				self:GetSkillCasterTag(),
				false,
				self:IsSkillHalo(),
				'battle.buff.BaseBeckonBuff',
				BuffCauseEffectTime.BASE,
				buffConfig_.value,
				buffConfig_.time,
				nil,
				1,
				buffConfig_.qteTapTimes,
				nil,
				{},
				{weatherId = self:GetSkillWeatherId()}
			)

			table.insert(self.nonbuffInfos, 1, buffInfo)
			---------- 召唤特殊技能 非buff类型 ----------

		elseif ConfigBuffType.DISPEL_BECKON == buffConfig_.buffType then

			---------- 驱散召唤特殊技能 非buff类型 ----------
			local buffInfo = ObjectBuffConstructorStruct.New(
				self:GetSkillId(),
				tostring(buffConfig_.buffType),
				buffConfig_.buffType,
				BKIND.BASE,
				0,
				self:GetSkillCasterTag(),
				false,
				self:IsSkillHalo(),
				'battle.buff.DispelBuff',
				BuffCauseEffectTime.BASE,
				buffConfig_.value,
				buffConfig_.time,
				nil,
				1,
				buffConfig_.qteTapTimes,
				nil,
				{},
				{weatherId = self:GetSkillWeatherId()}
			)

			table.insert(self.nonbuffInfos, 1, buffInfo)
			---------- 驱散召唤特殊技能 非buff类型 ----------

		else

			local buffConf = CommonUtils.GetConfig('cards', 'skillType', checkint(buffConfig_.buffType))

			local buffInfo = nil
			
			-- 检查触发行为
			if self:IsBuffHasTriggerByBuffType(buffConfig_.buffType) then
				---------- 带触发类型的的buff ----------
				-- /***********************************************************************************************************************************\
				--  * 处理触发类的buff
				--  * 将触发后索敌规则相同的buff整合到一个触发buff中
				-- \***********************************************************************************************************************************/
				local curBuffSeekRule = self:GetBuffSeekRuleConfigByBuffType(buffConfig_.buffType)

				local add2TriggerBuff = false
				for i,v in ipairs(self.buffInfos) do
					if ConfigBuffType.TRIGGER_BUFF == v.btype then
						local triggerBuffSeekRule = self:GetBuffSeekRuleConfigByBuffType(v:GetSeekRuleBuffType())
						if curBuffSeekRule == triggerBuffSeekRule then
							-- 找到索敌规则相同的buff 插入buff信息
							add2TriggerBuff = true

							v:AddTriggerBuffInfo(
								self:GetBuffConfigByBuffType(buffConfig_.buffType),
								self:GetBuffTriggerActionInfoByBuffType(buffConfig_.buffType),
								self:GetBuffTriggerConditionInfoByBuffType(buffConfig_.buffType),
								self:GetHurtEffectDataByBuffType(buffConfig_.buffType),
								self:GetAttachEffectDataByBuffType(buffConfig_.buffType)
							)

							break
						end
					end
				end

				if not add2TriggerBuff then

					-- 未找到索敌规则相同的buff 创建一个triggerbuff
					local bid = tostring(buffConfig_.buffType) .. '_' .. tostring(self:GetSkillId()) .. '_' .. tostring(ConfigBuffType.TRIGGER_BUFF)
					buffInfo = ObjectTriggerBuffConstructorStruct.New(
						self:GetSkillId(),
						bid,
						ConfigBuffType.TRIGGER_BUFF,
						BKIND.TRIGGER,
						0,
						self:GetSkillCasterTag(),
						false,
						self:IsSkillHalo(),
						'battle.buff.BaseTriggerBuff',
						BuffCauseEffectTime.ADD2OBJ,
						{},
						buffConfig_.time,
						0,
						1,
						buffConfig_.qteTapTimes,
						0,
						nil,
						{weatherId = self:GetSkillWeatherId()}
					)

					buffInfo:AddTriggerBuffInfo(
						self:GetBuffConfigByBuffType(buffConfig_.buffType),
						self:GetBuffTriggerActionInfoByBuffType(buffConfig_.buffType),
						self:GetBuffTriggerConditionInfoByBuffType(buffConfig_.buffType),
						self:GetHurtEffectDataByBuffType(buffConfig_.buffType),
						self:GetAttachEffectDataByBuffType(buffConfig_.buffType)
					)

				end
				---------- 带触发类型的的buff ----------
			else

				-- 普通触发类型
				---------- 判断是否为debuff ----------
				local isDebuff = false
				if ConfigIsDebuff.BUFF == checkint(buffConf.buffType) then
					isDebuff = false
				elseif ConfigIsDebuff.DEBUFF == checkint(buffConf.buffType) then
					isDebuff = true
				elseif ConfigIsDebuff.VALUE == checkint(buffConf.buffType) then
					if 0 > checknumber(buffConfig_.value[1]) then
						isDebuff = true
					else
						isDebuff = false
					end
				end
				---------- 判断是否为debuff ----------

				---------- 初始化buff信息 ----------
				buffInfo = ObjectBuffConstructorStruct.New(
					self:GetSkillId(),
					tostring(buffConfig_.buffType),
					buffConfig_.buffType,
					BKIND.BASE,
					0,
					self:GetSkillCasterTag(),
					isDebuff,
					self:IsSkillHalo(),
					'battle.buff.BaseBuff',
					BuffCauseEffectTime.BASE,
					buffConfig_.value,
					buffConfig_.time,
					nil,
					buffConfig_.innerPileMax,
					buffConfig_.qteTapTimes,
					checkint(buffConf.buffIcon),
					self:GetAttachEffectDataByBuffType(buffConfig_.buffType),
					{weatherId = self:GetSkillWeatherId()}
				)
				---------- 初始化buff信息 ----------

				---------- 判断buff类型 处理共存互斥逻辑 ----------
				if (ConfigBuffType.ISD == buffInfo.btype or
					ConfigBuffType.ISD_LHP == buffInfo.btype or 
					ConfigBuffType.ISD_CHP == buffInfo.btype or
					ConfigBuffType.ISD_OHP == buffInfo.btype) then

					-- 瞬时伤害型
					buffInfo.className = 'battle.buff.InstantBuff'
					buffInfo.bkind = BKIND.INSTANT
					buffInfo.causeEffectTime = BuffCauseEffectTime.INSTANT

				elseif (ConfigBuffType.HEAL == buffInfo.btype or
					ConfigBuffType.HEAL_LHP == buffInfo.btype or
					ConfigBuffType.HEAL_OHP == buffInfo.btype) then

					-- 瞬时治疗型
					buffInfo.className = 'battle.buff.InstantBuff'
					buffInfo.bkind = BKIND.INSTANT
					buffInfo.causeEffectTime = BuffCauseEffectTime.INSTANT

				elseif (ConfigBuffType.DISPEL_DEBUFF == buffInfo.btype or
					ConfigBuffType.DISPEL_BUFF == buffInfo.btype or
					ConfigBuffType.DISPEL_QTE == buffInfo.btype) then

					-- 驱散型
					buffInfo.className = 'battle.buff.DispelBuff'
					buffInfo.bkind = BKIND.DISPEL
					buffInfo.causeEffectTime = BuffCauseEffectTime.INSTANT

				elseif ConfigBuffType.IMMUNE == buffInfo.btype or 
					ConfigBuffType.IMMUNE_ATTACK_PHYSICAL == buffInfo.btype or
					ConfigBuffType.IMMUNE_SKILL_PHYSICAL == buffInfo.btype or
					ConfigBuffType.IMMUNE_ATTACK_HEAL == buffInfo.btype or
					ConfigBuffType.IMMUNE_SKILL_HEAL == buffInfo.btype or
					ConfigBuffType.IMMUNE_HEAL == buffInfo.btype then

					-- 伤害免疫
					buffInfo.className = 'battle.buff.ImmuneBuff'
					buffInfo.bkind = BKIND.IMMUNE
					buffInfo.causeEffectTime = BuffCauseEffectTime.ADD2OBJ

				elseif ConfigBuffType.STUN == buffInfo.btype then

					-- 眩晕
					buffInfo.className = 'battle.buff.StunBuff'
					buffInfo.bkind = BKIND.STUN
					buffInfo.causeEffectTime = BuffCauseEffectTime.ADD2OBJ

				elseif ConfigBuffType.FREEZE == buffInfo.btype then

					-- 眩晕
					buffInfo.className = 'battle.buff.FreezeBuff'
					buffInfo.bkind = BKIND.FREEZE
					buffInfo.causeEffectTime = BuffCauseEffectTime.ADD2OBJ

				elseif ConfigBuffType.SILENT == buffInfo.btype then

					-- 沉默
					buffInfo.className = 'battle.buff.SilentBuff'
					buffInfo.bkind = BKIND.SILENT
					buffInfo.causeEffectTime = BuffCauseEffectTime.ADD2OBJ

				elseif ConfigBuffType.SHIELD == buffInfo.btype then

					-- 护盾
					buffInfo.className = 'battle.buff.ShieldBuff'
					-- 护盾buff可以共存多个 加技能id后缀作区别
					buffInfo.bid = tostring(buffInfo.btype) .. '_' .. tostring(self:GetSkillId())
					buffInfo.bkind = BKIND.SHIELD
					buffInfo.causeEffectTime = BuffCauseEffectTime.DELAY

				elseif (ConfigBuffType.DOT == buffInfo.btype or
					ConfigBuffType.DOT_CHP == buffInfo.btype or
					ConfigBuffType.DOT_OHP == buffInfo.btype or
					ConfigBuffType.HOT == buffInfo.btype or
					ConfigBuffType.HOT_LHP == buffInfo.btype or
					ConfigBuffType.HOT_OHP == buffInfo.btype) then

					-- 延时伤害和治疗
					buffInfo.className = 'battle.buff.OverTimeBuff'
					-- 延时buff可以共存多个 加技能id后缀作区别
					buffInfo.bid = tostring(buffInfo.btype) .. '_' .. tostring(self:GetSkillId())
					buffInfo.bkind = BKIND.OVERTIME
					buffInfo.causeEffectTime = BuffCauseEffectTime.DELAY

				elseif ConfigBuffType.ENCHANTING == buffInfo.btype then

					-- 魅惑
					buffInfo.className = 'battle.buff.EnchantingBuff'
					buffInfo.bkind = BKIND.ENCHANTING
					buffInfo.causeEffectTime = BuffCauseEffectTime.ADD2OBJ

				elseif ConfigBuffType.EXECUTE == buffInfo.btype then

					-- 瞬时伤害型
					buffInfo.className = 'battle.buff.ExecuteBuff'
					buffInfo.bkind = BKIND.EXECUTE
					buffInfo.causeEffectTime = BuffCauseEffectTime.INSTANT

				elseif ConfigBuffType.ENERGY_ISTANT == buffInfo.btype then

					-- 瞬时增加能量
					buffInfo.className = 'battle.buff.EnergyInstantBuff'
					buffInfo.bkind = BKIND.INSTANT
					buffInfo.causeEffectTime = BuffCauseEffectTime.INSTANT

				elseif ConfigBuffType.ENERGY_CHARGE_RATE == buffInfo.btype then

					-- 影响能力数值类的buff
					buffInfo.className = 'battle.buff.EnergyRateBuff'
					-- 能力类可以共存多个 加技能id后缀作区别
					buffInfo.bid = tostring(buffInfo.btype) .. '_' .. tostring(self:GetSkillId())
					buffInfo.bkind = BKIND.ABILITY
					buffInfo.causeEffectTime = BuffCauseEffectTime.ADD2OBJ

				elseif ConfigBuffType.REVIVE == buffInfo.btype then

					-- 复活
					buffInfo.className = 'battle.buff.ReviveBuff'
					buffInfo.bkind = BKIND.REVIVE
					buffInfo.iconType = nil
					buffInfo.causeEffectTime = BuffCauseEffectTime.INSTANT

				elseif ConfigBuffType.ATK_CR_RATE_CHARGE == buffInfo.btype or 
					ConfigBuffType.ATK_ATTACK_B_CHARGE == buffInfo.btype or
					ConfigBuffType.ATK_ISD_CHARGE == buffInfo.btype or
					ConfigBuffType.ATK_HEAL_CHARGE == buffInfo.btype or
					ConfigBuffType.ATK_ENERGY_CHARGE == buffInfo.btype then

					-- 攻击充能
					buffInfo.bid = tostring(buffInfo.btype) .. '_' .. tostring(self:GetSkillId())
					buffInfo.className = 'battle.buff.AttackChargeBuff'
					buffInfo.bkind = BKIND.ATTACK_CHARGE
					buffInfo.causeEffectTime = BuffCauseEffectTime.ADD2OBJ

				elseif ConfigBuffType.STAGGER == buffInfo.btype then

					-- 醉拳
					buffInfo.className = 'battle.buff.StaggerBuff'
					buffInfo.bkind = BKIND.ABILITY
					buffInfo.causeEffectTime = BuffCauseEffectTime.DELAY

				elseif ConfigBuffType.SACRIFICE == buffInfo.btype then

					-- 牺牲
					buffInfo.className = 'battle.buff.SacrificeBuff'
					-- 牺牲可以共存多个 加技能id后缀作区别
					buffInfo.bid = tostring(buffInfo.btype) .. '_' .. tostring(self:GetSkillId())
					buffInfo.bkind = BKIND.ABILITY
					buffInfo.causeEffectTime = BuffCauseEffectTime.DELAY

				elseif ConfigBuffType.SPIRIT_LINK == buffInfo.btype then

					-- link
					buffInfo.className = 'battle.buff.SpiritLinkBuff'
					buffInfo.bkind = BKIND.ABILITY
					buffInfo.causeEffectTime = BuffCauseEffectTime.DELAY

				elseif ConfigBuffType.UNDEAD == buffInfo.btype then

					-- 春哥
					buffInfo.className = 'battle.buff.UndeadBuff'
					buffInfo.bkind = BKIND.ABILITY
					buffInfo.causeEffectTime = BuffCauseEffectTime.ADD2OBJ

				elseif ConfigBuffType.DOT_FINISHER == buffInfo.btype then

					-- dot终结
					buffInfo.className = 'battle.buff.DOTFinisherBuff'
					buffInfo.bkind = BKIND.BASE
					buffInfo.causeEffectTime = BuffCauseEffectTime.INSTANT

				elseif ConfigBuffType.CRITICAL_COUNTER == buffInfo.btype then

					-- 保底暴击
					buffInfo.className = 'battle.buff.CriticalCounterBuff'
					buffInfo.bkind = BKIND.ABILITY
					buffInfo.causeEffectTime = BuffCauseEffectTime.DELAY

				elseif ConfigBuffType.MULTISHOT == buffInfo.btype then

					-- 多重射击
					buffInfo.className = 'battle.buff.MultishotBuff'
					buffInfo.bkind = BKIND.ABILITY
					buffInfo.causeEffectTime = BuffCauseEffectTime.ADD2OBJ

				elseif ConfigBuffType.ATTACK_SEEK_RULE == buffInfo.btype then

					-- 改变平a索敌
					buffInfo.className = 'battle.buff.AttackSeekRuleBuff'
					buffInfo.bkind = BKIND.ABILITY
					buffInfo.causeEffectTime = BuffCauseEffectTime.ADD2OBJ

				elseif ConfigBuffType.HEAL_SEEK_RULE == buffInfo.btype then

					-- 改变治疗索敌
					buffInfo.className = 'battle.buff.HealSeekRuleBuff'
					buffInfo.bkind = BKIND.ABILITY
					buffInfo.causeEffectTime = BuffCauseEffectTime.ADD2OBJ

				elseif ConfigBuffType.CHANGE_SKILL_TRIGGER == buffInfo.btype then

					-- 改变技能触发条件
					buffInfo.className = 'battle.buff.ChangeSkillTriggerBuff'
					buffInfo.bkind = BKIND.ABILITY
					buffInfo.causeEffectTime = BuffCauseEffectTime.ADD2OBJ

				elseif ConfigBuffType.CHANGE_PP == buffInfo.btype then

					-- 改变属性系数
					buffInfo.className = 'battle.buff.PropertyParameterBuff'
					-- 能力类可以共存多个 加技能id后缀作区别
					buffInfo.bid = tostring(buffInfo.btype) .. '_' .. tostring(self:GetSkillId())
					buffInfo.bkind = BKIND.ABILITY
					buffInfo.causeEffectTime = BuffCauseEffectTime.ADD2OBJ

				elseif ConfigBuffType.DAMAGE_NO_TRIGGER == buffInfo.btype then

					-- 受到一个额外的不会触发触发器的伤害
					buffInfo.className = 'battle.buff.DamageNoTriggerBuff'
					buffInfo.bkind = BKIND.INSTANT
					buffInfo.causeEffectTime = BuffCauseEffectTime.INSTANT

				elseif ConfigBuffType.HEAL_NO_TRIGGER == buffInfo.btype then

					-- 受到一个额外的不会触发触发器的治疗
					buffInfo.className = 'battle.buff.HealNoTriggerBuff'
					buffInfo.bkind = BKIND.INSTANT
					buffInfo.causeEffectTime = BuffCauseEffectTime.INSTANT

				elseif ConfigBuffType.SLAY_DAMAGE_SPLASH == buffInfo.btype then

					-- 击杀伤害溢出
					buffInfo.className = 'battle.buff.SlayDamageSplashBuff'
					buffInfo.bkind = BKIND.ABILITY
					buffInfo.causeEffectTime = BuffCauseEffectTime.DELAY

				elseif ConfigBuffType.SLAY_BUFF_INFECT == buffInfo.btype then

					-- 击杀buff传染
					buffInfo.className = 'battle.buff.SlayBuffInfectBuff'
					buffInfo.bkind = BKIND.ABILITY
					buffInfo.causeEffectTime = BuffCauseEffectTime.DELAY

				elseif ConfigBuffType.ENHANCE_NEXT_SKILL == buffInfo.btype then

					-- 强化下一次技能
					buffInfo.className = 'battle.buff.EnhanceNextSkillBuff'
					buffInfo.bid = tostring(buffInfo.btype) .. '_' .. tostring(self:GetSkillId())
					buffInfo.bkind = BKIND.ABILITY
					buffInfo.causeEffectTime = BuffCauseEffectTime.DELAY

				elseif ConfigBuffType.OVERFLOW_HEAL_2_SHIELD == buffInfo.btype then

					-- 溢出治疗转护盾
					buffInfo.className = 'battle.buff.OverflowHealShieldBuff'
					buffInfo.bkind = BKIND.ABILITY
					buffInfo.causeEffectTime = BuffCauseEffectTime.DELAY

				elseif ConfigBuffType.OVERFLOW_HEAL_2_DAMAGE == buffInfo.btype then

					-- 溢出治疗转伤害
					buffInfo.className = 'battle.buff.OverflowHealDamageBuff'
					buffInfo.bkind = BKIND.ABILITY
					buffInfo.causeEffectTime = BuffCauseEffectTime.DELAY

				elseif ConfigBuffType.SLAY_CAST_ECHO == buffInfo.btype then

					-- 击杀技能回响
					buffInfo.className = 'battle.buff.SlayCastEchoBuff'
					buffInfo.bkind = BKIND.ABILITY
					buffInfo.causeEffectTime = BuffCauseEffectTime.DELAY

				elseif ConfigBuffType.MARKING == buffInfo.btype then

					-- 标记
					buffInfo.className = 'battle.buff.MarkingBuff'
					-- 共存多个 加技能id后缀作区别
					buffInfo.bid = tostring(buffInfo.btype) .. '_' .. tostring(self:GetSkillId())
					buffInfo.bkind = BKIND.ABILITY
					buffInfo.causeEffectTime = BuffCauseEffectTime.ADD2OBJ

				elseif ConfigBuffType.CHANGE_PP_BY_PROPERTY == buffInfo.btype then

					-- 属性变化导致属性系数变化
					buffInfo.className = 'battle.buff.PropertyParameterByPropertyBuff'
					-- 共存多个 加技能id后缀作区别
					buffInfo.bid = tostring(buffInfo.btype) .. '_' .. tostring(self:GetSkillId())
					buffInfo.bkind = BKIND.ABILITY
					buffInfo.causeEffectTime = BuffCauseEffectTime.ADD2OBJ

				elseif ConfigBuffType.ENHANCE_BUFF_TIME_CAUSE == buffInfo.btype then

					-- 自身释放技能的buff时间强化
					buffInfo.className = 'battle.buff.EnhanceBuffTimeCauseBuff'
					buffInfo.bid = tostring(buffInfo.btype) .. '_' .. tostring(self:GetSkillId())
					buffInfo.bkind = BKIND.ABILITY
					buffInfo.causeEffectTime = BuffCauseEffectTime.DELAY

				elseif ConfigBuffType.ENHANCE_BUFF_TIME_GET == buffInfo.btype then

					-- 自身受到的buff时间强化
					buffInfo.className = 'battle.buff.EnhanceBuffTimeGetBuff'
					buffInfo.bid = tostring(buffInfo.btype) .. '_' .. tostring(self:GetSkillId())
					buffInfo.bkind = BKIND.ABILITY
					buffInfo.causeEffectTime = BuffCauseEffectTime.DELAY

				elseif ConfigBuffType.ENHANCE_BUFF_VALUE_CAUSE == buffInfo.btype then

					-- 自身释放技能的buff值强化
					buffInfo.className = 'battle.buff.EnhanceBuffValueCauseBuff'
					buffInfo.bid = tostring(buffInfo.btype) .. '_' .. tostring(self:GetSkillId())
					buffInfo.bkind = BKIND.ABILITY
					buffInfo.causeEffectTime = BuffCauseEffectTime.DELAY

				elseif ConfigBuffType.ENHANCE_BUFF_VALUE_GET == buffInfo.btype then

					-- 自身受到技能的buff值强化
					buffInfo.className = 'battle.buff.EnhanceBuffValueGetBuff'
					buffInfo.bid = tostring(buffInfo.btype) .. '_' .. tostring(self:GetSkillId())
					buffInfo.bkind = BKIND.ABILITY
					buffInfo.causeEffectTime = BuffCauseEffectTime.DELAY

				elseif ConfigBuffType.CHANGE_BUFF_SUCCESS_RATE == buffInfo.btype then

					-- 改变buff释放成功率(不是技能的释放成功率)
					buffInfo.className = 'battle.buff.ChangeBuffSuccessRateBuff'
					buffInfo.bid = tostring(buffInfo.btype) .. '_' .. tostring(self:GetSkillId())
					buffInfo.bkind = BKIND.ABILITY
					buffInfo.causeEffectTime = BuffCauseEffectTime.DELAY

				elseif ConfigBuffType.PROPERTY_CONVERT == buffInfo.btype then

					-- 改变buff释放成功率(不是技能的释放成功率)
					buffInfo.className = 'battle.buff.PropertyConvertBuff'
					buffInfo.bid = tostring(buffInfo.btype) .. '_' .. tostring(self:GetSkillId())
					buffInfo.bkind = BKIND.ABILITY
					buffInfo.causeEffectTime = BuffCauseEffectTime.ADD2OBJ

				elseif ConfigBuffType.LIVE_CHEAT_FREE == buffInfo.btype then

					-- 免费买活
					buffInfo.className = 'battle.buff.LiveCheatFreeBuff'
					buffInfo.bkind = BKIND.BASE
					buffInfo.causeEffectTime = BuffCauseEffectTime.DELAY

				elseif ConfigBuffType.BATTLE_TIME == buffInfo.btype then

					-- 改变战斗时间
					buffInfo.className = 'battle.buff.BattleTimeBuff'
					buffInfo.bkind = BKIND.BASE
					buffInfo.causeEffectTime = BuffCauseEffectTime.INSTANT

				elseif ConfigBuffType.IMMUNE_BUFF_TYPE == buffInfo.btype then

					-- 免疫技能buff的buff
					buffInfo.className = 'battle.buff.ImmuneBuffTypeBuff'
					buffInfo.bid = tostring(buffInfo.btype) .. '_' .. tostring(self:GetSkillId())
					buffInfo.bkind = BKIND.ABILITY
					buffInfo.causeEffectTime = BuffCauseEffectTime.ADD2OBJ

				elseif ConfigBuffType.VIEW_TRANSFORM == buffInfo.btype then

					-- view变形的buff
					buffInfo.className = 'battle.buff.ViewTransformBuff'
					buffInfo.bkind = BKIND.ABILITY
					buffInfo.causeEffectTime = BuffCauseEffectTime.INSTANT

				else

					-- 影响能力数值类的buff
					buffInfo.className = 'battle.buff.AbilityBuff'
					-- 能力类可以共存多个 加技能id后缀作区别
					buffInfo.bid = tostring(buffInfo.btype) .. '_' .. tostring(self:GetSkillId())
					buffInfo.bkind = BKIND.ABILITY
					buffInfo.causeEffectTime = BuffCauseEffectTime.ADD2OBJ

				end
				---------- 判断buff类型 处理共存互斥逻辑 ----------

			end

			if nil ~= buffInfo then
				-- 计算技能持续时间
				if self.durationTime < buffInfo.time then
					self.durationTime = buffInfo.time
				end

				table.insert(self.buffInfos, 1, buffInfo)
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
开始释放技能 初始化一些值
@params params ObjectCastParameterStruct 外部传参
--]]
function BaseSkill:CastBegin(params)
	-- 清空分段
	self:ClearSkillPhase()
	-- 清空分段对象池
	self:ClearTargetPool()

	-- 缓存一次本次施法索敌目标
	self:SetTargetPool(self:ConvertBuffTargetData(params))

	self:Cast(params)
end
--[[
释放该技能
@params params ObjectCastParameterStruct 外部传参
--]]
function BaseSkill:Cast(params)
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

	---------- 释放buff类型 ----------
	local bulletEffectData = self:GetBulletEffectData()

	if nil == bulletEffectData or BattleUtils.IsTableEmpty(bulletEffectData) or self:IsSkillHalo() then

		-- 没有子弹信息或者是光环走基础施法逻辑
		self:BaseCast(self:GetTargetPool())

	elseif ConfigEffectCauseType.SCREEN == bulletEffectData.causeType then

		-- 全屏子弹
		self:SendScreenBullet(self:GetTargetPool(), self:GetSkillPhase(), params)

	elseif ConfigEffectCauseType.POINT == bulletEffectData.causeType then

		-- 指向性子弹
		self:SendPointBullet(self:GetTargetPool(), self:GetSkillPhase(), params)

	elseif ConfigEffectCauseType.SINGLE == bulletEffectData.causeType then

		-- 范围重点连线
		self:SendAreaEffectBullet(self:GetTargetPool(), self:GetSkillPhase(), params)

	else

		-- 基础子弹类型
		self:SendBaseBullet(self:GetTargetPool(), self:GetSkillPhase(), params)

	end
	---------- 释放buff类型 ----------

end
--[[
基础施法逻辑
@params targetsWithBuffinfo table 对象buff映射
--]]
function BaseSkill:BaseCast(targetsWithBuffinfo)
	---------- 基础施法逻辑 ----------
	for i, v in ipairs(targetsWithBuffinfo) do
		local tTag = v.tag
		local buffs = v.buffs
		local target = nil

		if true == v.needRevive then
			target = G_BattleLogicMgr:GetDeadObjByTag(tTag)
		else
			target = G_BattleLogicMgr:IsObjAliveByTag(tTag)
		end
		if nil ~= target then
			self:AddBuffs2Target(target, buffs, 1, 1, 1, 1, false)
		end		
	end
	---------- 基础施法逻辑 ----------
end
--[[
转换数据结构
@params params ObjectCastParameterStruct 外部传参
@return result table target -> buff 映射
--]]
function BaseSkill:ConvertBuffTargetData(params)
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

		if true == self:CanCastBuff(buffType_) then

			---------- 判断是否满足释放触发条件 ----------
			local canCastByCondition = true
			if not self:IsBuffHasTriggerByBuffType(buffType_) then

				local triggerConditionInfo = self:GetBuffTriggerConditionInfoByBuffType(buffType_)
				if nil ~= triggerConditionInfo and ConfigObjectTriggerConditionType.BASE ~= triggerConditionInfo.objTriggerConditionType then

					-- 遍历一遍已有对象池 如果发现索敌规则完全相同的buff 则直接使用该buff索敌结果
					local sk = sortByKey(buffConditionTargets)
					for i,v in ipairs(sk) do
						local tbtype = v

						if nil ~= self:GetBuffTriggerConditionInfoByBuffType(checkint(tbtype)) then
							doneConditionSeekRule = self:GetBuffTriggerConditionInfoByBuffType(checkint(tbtype)).triggerSeekRule
							if nil ~= doneConditionSeekRule and doneConditionSeekRule == triggerConditionInfo.triggerSeekRule then
								-- 索敌规则相同 套用之前的规则
								buffConditionTargets[tostring(buffType_)] = buffConditionTargets[tbtype]
								break
							end
						end
					end

					-- 若不存在对象 进行一次索敌
					if nil == buffConditionTargets[tostring(buffType_)] then
						buffConditionTargets[tostring(buffType_)] = BattleExpression.GetTargets(
							self:GetIsSkillEnemy(),
							triggerConditionInfo.triggerSeekRule,
							self:GetSkillCaster(),
							nil,
							params.triggerData
						)
					end

					canCastByCondition = BattleExpression.MeetTriggerCondition(triggerConditionInfo, buffConditionTargets[tostring(buffType_)])

				end

			end
			---------- 判断是否满足释放触发条件 ----------

			if canCastByCondition then
				---------- 为buff索敌 ----------
				-- /***********************************************************************************************************************************\
				--  * 技能索敌只在第一段索敌
				--  * 如果存在索敌规则完全相同的buff 则只会索敌一次 后续buff会沿用之前索敌的对象
				-- \***********************************************************************************************************************************/
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
				---------- 为buff索敌 ----------

				---------- 为索敌对象添加buff信息 ----------
				local tTag = nil
				for i, target in ipairs(bufftargets[tostring(seekRuleBuffType)]) do
					tTag = target:GetOTag()
					local buffInfo = clone(buffInfo_)
					buffInfo.ownerTag = tTag

					---------- 修正buff实际值 ----------
					self:ConvertConfigValue2RealValue(caster, target, buffInfo_.value, buffInfo, params.skillExtra, 1)
					---------- 修正buff实际值 ----------

					---------- 分段机制 初始化伤害池 ----------

					-- ---------- 分段机制 初始化伤害池 ----------
					-- if BKIND.INSTANT == buffInfo.bkind then
					-- 	if nil == self.damagePool[tostring(tTag)] then
					-- 		self.damagePool[tostring(tTag)] = {}
					-- 	end
					-- 	self.damagePool[tostring(tTag)][tostring(buffType_)] = buffInfo.value
					-- end
					-- ---------- 分段机制 初始化伤害池 ----------

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
				---------- 为索敌对象添加buff信息 ----------

				---------- 消耗释放buff需要的资源 ----------
				if caster then
					caster:CostTriggerBuffResources(
						self:GetSkillId(),
						buffType_,
						nil,
						self:GetBuffTriggerInsideCDByBuffType(buffType_)
					)
				end
				---------- 消耗释放buff需要的资源 ----------

			else
				print('\n---> :( not meet trigger condition', '<---\n', self:GetSkillId(), 'buffType:', buffType_)
			end

		else
			print('\n---> :( cast failed skillId:', self:GetSkillId(), 'buffType:', buffType_, 'successRate:', self:GetBuffConfigByBuffType(buffType_).successRate, '<---\n')
		end
	end

	return result
end
--[[
转换数据结构 配表值->真实值
@params caster obj 施法者
@params target obj 目标
@params buffValueConfig table buff value配置
@params buffInfo ObjectBuffConstructorStruct 需要转换的目标数据结构
@params skillExtra number 最终伤害乘法修正系数
@params percent number 百分比
--]]
function BaseSkill:ConvertConfigValue2RealValue(caster, target, buffValueConfig, buffInfo, skillExtra, percent)
	if ConfigBuffType.ISD == buffInfo.btype or ConfigBuffType.DOT == buffInfo.btype then

		-- 配置中存在两个值
		if caster and caster.GetMainProperty and nil ~= caster:GetMainProperty() then
			buffInfo.value = caster:GetMainProperty():GetSkillDamage(buffValueConfig, target)
		else
			buffInfo.value = 0 * checknumber(buffValueConfig[1]) + checknumber(buffValueConfig[2]) 
		end
	
		-- 最终乘法系数修正
		buffInfo.value = buffInfo.value * skillExtra

	elseif ConfigBuffType.HEAL == buffInfo.btype or ConfigBuffType.HOT == buffInfo.btype then

		-- 配置中只有一个值
		if caster and caster.GetMainProperty and nil ~= caster:GetMainProperty() then
			buffInfo.value = caster:GetMainProperty():GetSkillHeal(checknumber(buffValueConfig[1]), target)
		else
			buffInfo.value = checknumber(buffValueConfig[1])
		end
	
		-- 最终乘法系数修正
		buffInfo.value = buffInfo.value * skillExtra

	elseif ConfigBuffType.EXECUTE == buffInfo.btype then

		-- 斩杀配置三个值 伤害乘法系数 伤害加法系数 生命百分比
		buffInfo.percent = checknumber(buffValueConfig[3])

		if caster and caster.GetMainProperty and nil ~= caster:GetMainProperty() then
			buffInfo.value = caster:GetMainProperty():GetSkillDamage(buffValueConfig, target, ConfigBuffType.EXECUTE)
		else
			buffInfo.value = 0 * checknumber(buffValueConfig[1]) + checknumber(buffValueConfig[2])
		end

		-- 最终乘法系数修正
		buffInfo.value = buffInfo.value * skillExtra

	elseif ConfigBuffType.DISPEL_QTE == buffInfo.btype or
		ConfigBuffType.REVIVE == buffInfo.btype or
		ConfigBuffType.STAGGER == buffInfo.btype or
		ConfigBuffType.DOT_FINISHER == buffInfo.btype or
		ConfigBuffType.MULTISHOT == buffInfo.btype or
		ConfigBuffType.ATTACK_SEEK_RULE == buffInfo.btype or
		ConfigBuffType.HEAL_SEEK_RULE == buffInfo.btype or
		ConfigBuffType.CHANGE_SKILL_TRIGGER == buffInfo.btype or
		ConfigBuffType.CHANGE_PP == buffInfo.btype or
		ConfigBuffType.DAMAGE_NO_TRIGGER == buffInfo.btype or
		ConfigBuffType.HEAL_NO_TRIGGER == buffInfo.btype or
		ConfigBuffType.SLAY_DAMAGE_SPLASH == buffInfo.btype or
		ConfigBuffType.SLAY_BUFF_INFECT == buffInfo.btype or
		ConfigBuffType.ENHANCE_NEXT_SKILL == buffInfo.btype or
		ConfigBuffType.OVERFLOW_HEAL_2_SHIELD == buffInfo.btype or
		ConfigBuffType.OVERFLOW_HEAL_2_DAMAGE == buffInfo.btype or
		ConfigBuffType.SLAY_CAST_ECHO == buffInfo.btype or
		ConfigBuffType.MARKING == buffInfo.btype or
		ConfigBuffType.CHANGE_PP_BY_PROPERTY == buffInfo.btype or
		ConfigBuffType.ENHANCE_BUFF_TIME_CAUSE == buffInfo.btype or 
		ConfigBuffType.ENHANCE_BUFF_TIME_GET == buffInfo.btype or
		ConfigBuffType.ENHANCE_BUFF_VALUE_CAUSE == buffInfo.btype or
		ConfigBuffType.ENHANCE_BUFF_VALUE_GET == buffInfo.btype or
		ConfigBuffType.CHANGE_BUFF_SUCCESS_RATE == buffInfo.btype or
		ConfigBuffType.PROPERTY_CONVERT == buffInfo.btype or
		ConfigBuffType.IMMUNE_BUFF_TYPE == buffInfo.btype or
		ConfigBuffType.BATTLE_TIME == buffInfo.btype or
		ConfigBuffType.VIEW_TRANSFORM == buffInfo.btype then

		-- 保留配表配置的类型

	elseif ConfigBuffType.ATK_CR_RATE_CHARGE == buffInfo.btype then

		-- 攻击特效充能类型需要特殊处理
		buffInfo.value = checknumber(buffValueConfig[1] or 0)

	elseif ConfigBuffType.ATK_ATTACK_B_CHARGE == buffInfo.btype or
		ConfigBuffType.ATK_ISD_CHARGE == buffInfo.btype or 
		ConfigBuffType.ATK_HEAL_CHARGE == buffInfo.btype or 
		ConfigBuffType.ATK_ENERGY_CHARGE == buffInfo.btype then

		-- 攻击特效充能类型需要特殊处理
		buffInfo.value = checknumber(buffValueConfig[1])

	else

		-- 其他所有类型只有值1
		buffInfo.value = checknumber(buffValueConfig[1])

		-- 最终乘法系数修正
		buffInfo.value = buffInfo.value * skillExtra

	end

	local buffs = nil
	local targetBuff = nil

	------------ 修正一次外部条件变化的buff时间 ------------
	-- 光环效果不会被强化时间
	if not buffInfo.isHalo then
		if nil ~= caster then
			-- 施法者的强化
			local enhanceTimeCauseBuffType = {
				ConfigBuffType.ENHANCE_BUFF_TIME_CAUSE
			}
			for _, enhanceBuffType in ipairs(enhanceTimeCauseBuffType) do
				buffs = caster:GetBuffsByBuffType(enhanceBuffType, false)
				for i = #buffs, 1, -1 do
					targetBuff = buffs[i]
					buffInfo.time = targetBuff:CauseEffect(buffInfo.btype, buffInfo.time)
				end
			end
		end

		if nil ~= target then
			-- 受法者的强化
			local enhanceTimeGetBuffType = {
				ConfigBuffType.ENHANCE_BUFF_TIME_CAUSE
			}
			for _, enhanceBuffType in ipairs(enhanceTimeGetBuffType) do
				buffs = target:GetBuffsByBuffType(enhanceBuffType, false)
				for i = #buffs, 1, -1 do
					targetBuff = buffs[i]
					buffInfo.time = targetBuff:CauseEffect(buffInfo.btype, buffInfo.time)
				end
			end
		end
	end
	------------ 修正一次外部条件变化的buff时间 ------------

	------------ 修正一次外部条件变化的buff值 ------------
	-- 施法者
	if nil ~= caster then
		local enhanceValueCauseBuffType = {
			ConfigBuffType.ENHANCE_BUFF_VALUE_CAUSE
		}
		for _, enhanceBuffType in ipairs(enhanceValueCauseBuffType) do
			buffs = caster:GetBuffsByBuffType(enhanceBuffType, false)
			for i = #buffs, 1, -1 do
				targetBuff = buffs[i]
				buffInfo.value = targetBuff:CauseEffect(buffInfo.btype, buffInfo.value)
			end
		end
	end

	-- 受法者
	if nil ~= target then
		local enhanceValueGetBuffType = {
			ConfigBuffType.ENHANCE_BUFF_VALUE_GET
		}
		for _, enhanceBuffType in ipairs(enhanceValueGetBuffType) do
			buffs = target:GetBuffsByBuffType(enhanceBuffType, false)
			for i = #buffs, 1, -1 do
				targetBuff = buffs[i]
				buffInfo.value = targetBuff:CauseEffect(buffInfo.btype, buffInfo.value)
			end
		end
	end
	------------ 修正一次外部条件变化的buff值 ------------

end
--[[
技能效果作用逻辑
@params target obj 物体
@params buffs table buff集合
@params actionPhaseCounter int 动作分段计数
@params actionPercent number 动作分段百分比
@params effectPhaseCounter int 特效分段计数
@params effectPercent number 特效分段百分比
@params showHurtEffect bool 是否显示爆点特效
--]]
function BaseSkill:AddBuffs2Target(target, buffs, actionPhaseCounter, actionPercent, effectPhaseCounter, effectPercent, showHurtEffect)
	---------- tmp data ----------
	local tTag = target:GetOTag()
	local btype = nil
	-- buff作用计数器 计算是否需要附加qte和传染逻辑
	local causeEffectCounter = 0
	-- 传染信息
	local infectBuffInfo = {}
	-- qte信息
	local qteBuffsInfo = QTEAttachObjectConstructStruct.New(
		QTEAttachObjectType.BASE,
		self:GetSkillId(),
		tTag,
		self:GetSkillCasterTag()
	)
	---------- tmp data ----------

	for i, buffInfo_ in ipairs(buffs) do
		local buffInfo = clone(buffInfo_)
		btype = buffInfo.btype

		---------- 处理分段 修正buff数值 ----------
		if ConfigBuffType.ISD == buffInfo.btype or
			ConfigBuffType.ISD_LHP == buffInfo.btype or
			ConfigBuffType.ISD_CHP == buffInfo.btype or
			ConfigBuffType.ISD_OHP == buffInfo.btype or
			ConfigBuffType.HEAL == buffInfo.btype or
			ConfigBuffType.HEAL_LHP == buffInfo.btype or
			ConfigBuffType.HEAL_OHP == buffInfo.btype or
			ConfigBuffType.ENERGY_ISTANT == buffInfo.btype or
			ConfigBuffType.ISD == buffInfo.btype then

			buffInfo.value = buffInfo_.value * actionPercent * effectPercent

		end
		---------- 处理分段 修正buff数值 ----------

		---------- 处理分段 作用效果 ----------
		if 1 == actionPhaseCounter * effectPhaseCounter then

			-- 第一段 作用所有效果
			local ifCausedEffect = target:BeCasted(buffInfo)
			if true == ifCausedEffect then
				causeEffectCounter = causeEffectCounter + 1
			end

			-- 显示被击爆点
			if showHurtEffect then
				target:ShowHurtEffect(self:GetHurtEffectDataByBuffType(btype))
			end

			---------- 处理qte信息 ----------
			if ifCausedEffect and 0 < buffInfo.qteTapTime then
				-- 插入qte信息
				qteBuffsInfo:AddAQTEBuffInfo(buffInfo.qteTapTime, btype)
				-- 设置最大点击次数
				qteBuffsInfo:SetMaxTouch(buffInfo.qteTapTime)
			end
			---------- 处理qte信息 ----------

			---------- 处理传染信息 ----------
			if 0 < self:GetSkillInfectTime() then
				table.insert(infectBuffInfo, 1, clone(buffInfo))
			end
			---------- 处理传染信息 ----------

		elseif 1 < actionPhaseCounter * effectPhaseCounter and (BKIND.INSTANT == buffInfo.bkind) then

			-- 非瞬时伤害型的分段 第二段以后直接屏蔽
			target:BeCasted(buffInfo)

			-- 显示被击爆点
			if showHurtEffect then
				target:ShowHurtEffect(self:GetHurtEffectDataByBuffType(btype))
			end

		end
		---------- 处理分段 作用效果 ----------

	end

	---------- 处理传染信息 ----------
	if 1 == actionPhaseCounter * effectPhaseCounter then

		-- qte和传染逻辑只在特效的第一段作用
		-- 加上qte buff
		if 0 < #qteBuffsInfo.qteBuffs then
			target:AddQTE(qteBuffsInfo)
		end

		---------- 传染逻辑 ----------
		-- 如果target免疫了该技能的全效果 则不会加上传染驱动
		if 0 < causeEffectCounter and 0 < self:GetSkillInfectTime() then
			local infectInfo = InfectTransmitStruct.New(
				self:GetSkillId(),
				self:GetSkillLevel(),
				target:IsEnemy(true),
				infectBuffInfo,
				self:GetSkillInfectTime(),
				self:GetSkillInfectSeekRule(),
				self:GetSkillCasterTag(),
				tTag,
				self:GetHurtEffectData(),
				self:GetAttachEffectData()
			)
			target:AddInfectInfo(infectInfo)
		end
		---------- 传染逻辑 ----------
	end
	---------- 处理传染信息 ----------
end
---------------------------------------------------
-- logic end --
---------------------------------------------------

---------------------------------------------------
-- send bullet logic begin --
---------------------------------------------------
--[[
发射基础类型子弹
@params targetsWithBuffinfo table 对象buff映射
@params actionPhaseCounter int 动作分段计数
@params params ObjectCastParameterStruct 外部传参
--]]
function BaseSkill:SendBaseBullet(targetsWithBuffinfo, actionPhaseCounter, params)
	local battleArea = G_BattleLogicMgr:GetBConf().BATTLE_AREA
	local battleAreaCenter = cc.p(battleArea.x + battleArea.width * 0.5, battleArea.y + battleArea.height * 0.5)
	local towards = true

	local caster = self:GetSkillCaster()
	if nil ~= caster then
		towards = caster:GetOrientation()
	end

	local bulletEffectData = self:GetBulletEffectData()

	local bulletData = ObjectSendBulletData.New(
		------------ 基本信息 ------------
		nil,
		nil,
		bulletEffectData.bulletType,
		bulletEffectData.causeType,
		self:GetSkillCasterTag(),
		self:GetSkillCasterViewModelTag(),
		nil,
		nil,
		false,
		------------ spine动画信息 ------------
		bulletEffectData.effectId,
		bulletEffectData.effectActionName,
		bulletEffectData.effectZOrder,
		battleAreaCenter,
		battleAreaCenter,
		bulletEffectData.effectScale,
		bulletEffectData.effectPos,
		towards,
		params.shouldShakeWorld,
		params.needHighlight,
		------------ 数据信息 ------------
		nil,
		self:GetSkillDurationTime(),
		function (effectPercent, effectPhaseCounter)
			for i, v in ipairs(targetsWithBuffinfo) do
				local tTag = v.tag
				local buffs = v.buffs
				local target = nil

				if true == v.needRevive then
					target = G_BattleLogicMgr:GetDeadObjByTag(tTag)
				else
					target = G_BattleLogicMgr:IsObjAliveByTag(tTag)
				end

				if nil ~= target then
					self:AddBuffs2Target(target, buffs, actionPhaseCounter, params.percent, effectPhaseCounter, effectPercent, true)
				end

			end
		end
	)
	G_BattleLogicMgr:SendBullet(bulletData)
end
--[[
发射全屏类型的子弹
@params targetsWithBuffinfo table 对象buff映射
@params actionPhaseCounter int 动作分段计数
@params params ObjectCastParameterStruct 外部传参
--]]
function BaseSkill:SendScreenBullet(targetsWithBuffinfo, actionPhaseCounter, params)
	local battleArea = G_BattleLogicMgr:GetBConf().BATTLE_AREA
	local battleAreaCenter = cc.p(battleArea.x + battleArea.width * 0.5, battleArea.y + battleArea.height * 0.5)
	local towards = true

	local caster = self:GetSkillCaster()
	if nil ~= caster then
		towards = caster:GetOrientation()
	end

	local bulletEffectData = self:GetBulletEffectData()

	local bulletData = ObjectSendBulletData.New(
		------------ 基本信息 ------------
		nil,
		nil,
		bulletEffectData.bulletType,
		bulletEffectData.causeType,
		self:GetSkillCasterTag(),
		self:GetSkillCasterViewModelTag(),
		nil,
		nil,
		false,
		------------ spine动画信息 ------------
		bulletEffectData.effectId,
		bulletEffectData.effectActionName,
		bulletEffectData.effectZOrder,
		battleAreaCenter,
		battleAreaCenter,
		bulletEffectData.effectScale,
		bulletEffectData.effectPos,
		towards,
		params.shouldShakeWorld,
		params.needHighlight,
		------------ 数据信息 ------------
		nil,
		self:GetSkillDurationTime(),
		function (effectPercent, effectPhaseCounter)
			for i, v in ipairs(targetsWithBuffinfo) do
				local tTag = v.tag
				local buffs = v.buffs
				local target = nil

				if true == v.needRevive then
					target = G_BattleLogicMgr:GetDeadObjByTag(tTag)
				else
					target = G_BattleLogicMgr:IsObjAliveByTag(tTag)
				end

				if nil ~= target then
					self:AddBuffs2Target(target, buffs, actionPhaseCounter, params.percent, effectPhaseCounter, effectPercent, true)
				end

			end
		end
	)
	G_BattleLogicMgr:SendBullet(bulletData)
end
--[[
发射单体指向子弹 每个人身上各发射一个
@params targetsWithBuffinfo table 对象buff映射
@params actionPhaseCounter int 动作分段计数
@params params ObjectCastParameterStruct 外部传参
--]]
function BaseSkill:SendPointBullet(targetsWithBuffinfo, actionPhaseCounter, params)
	local towards = true
	local caster = self:GetSkillCaster()
	if nil ~= caster then
		towards = caster:GetOrientation()
	end

	local bulletEffectData = self:GetBulletEffectData()
	local casterTag = self:GetSkillCasterTag()
	local casterViewModelTag = self:GetSkillCasterViewModelTag()

	for i, v in ipairs(targetsWithBuffinfo) do
		local tTag = v.tag
		local buffs = v.buffs
		local target = nil

		if true == v.needRevive then
			target = G_BattleLogicMgr:GetDeadObjByTag(tTag)
		else
			target = G_BattleLogicMgr:IsObjAliveByTag(tTag)
		end

		if nil ~= target then
			local bulletData = ObjectSendBulletData.New(
				------------ 基本信息 ------------
				nil,
				nil,
				bulletEffectData.bulletType,
				bulletEffectData.causeType,
				casterTag,
				casterViewModelTag,
				tTag,
				target:GetViewModelTag(),
				v.needRevive,
				------------ spine动画信息 ------------
				bulletEffectData.effectId,
				bulletEffectData.effectActionName,
				bulletEffectData.effectZOrder,
				params.bulletOriPosition,
				target:GetLocation().po,
				bulletEffectData.effectScale,
				bulletEffectData.effectPos,
				towards,
				params.shouldShakeWorld,
				params.needHighlight,
				------------ 数据信息 ------------
				nil,
				self:GetSkillDurationTime(),
				function (effectPercent, effectPhaseCounter)
					local target_ = nil
					if true == v.needRevive then
						target_ = G_BattleLogicMgr:GetDeadObjByTag(v.tag)
					else
						target_ = G_BattleLogicMgr:IsObjAliveByTag(v.tag)
					end

					if nil ~= target_ then
						self:AddBuffs2Target(target_, v.buffs, actionPhaseCounter, params.percent, effectPhaseCounter, effectPercent, true)
					end
				end
			)
			G_BattleLogicMgr:SendBullet(bulletData)
		end
	end
end
--[[
发射群体指向子弹 取对象群对角线交点
@params targetsWithBuffinfo table 对象buff映射
@params actionPhaseCounter int 动作分段计数
@params params ObjectCastParameterStruct 外部传参
--]]
function BaseSkill:SendAreaEffectBullet(targetsWithBuffinfo, actionPhaseCounter, params)
	------------ 计算目标点 ------------
	local maxp = cc.p(0, 0)
	local minp = cc.p(G_BattleLogicMgr:GetBConf().BATTLE_AREA_MAX_DIS, G_BattleLogicMgr:GetBConf().BATTLE_AREA_MAX_DIS)
	local tag = nil
	local target = nil
	local targetP = nil

	for i,v in ipairs(targetsWithBuffinfo) do
		tag = v.tag
		if true == v.needRevive then
			target = G_BattleLogicMgr:GetDeadObjByTag(tag)
		else
			target = G_BattleLogicMgr:IsObjAliveByTag(tag)
		end
		
		if target then
			targetp = target:GetLocation().po
			maxp = cc.p(math.max(maxp.x, targetp.x), math.max(maxp.y, targetp.y))
			minp = cc.p(math.min(minp.x, targetp.x), math.min(minp.y, targetp.y))
		end
	end
	------------ 计算目标点 ------------

	local towards = true
	local caster = self:GetSkillCaster()
	if nil ~= caster then
		towards = caster:GetOrientation()
	end

	local bulletEffectData = self:GetBulletEffectData()

	local bulletData = ObjectSendBulletData.New(
		------------ 基本信息 ------------
		nil,
		nil,
		bulletEffectData.bulletType,
		bulletEffectData.causeType,
		self:GetSkillCasterTag(),
		self:GetSkillCasterViewModelTag(),
		nil,
		nil,
		false,
		------------ spine动画信息 ------------
		bulletEffectData.effectId,
		bulletEffectData.effectActionName,
		bulletEffectData.effectZOrder,
		params.bulletOriPosition or cc.p(0, 0),
		cc.p((maxp.x + minp.x) * 0.5, (maxp.y + minp.y) * 0.5),
		bulletEffectData.effectScale,
		bulletEffectData.effectPos,
		towards,
		params.shouldShakeWorld,
		params.needHighlight,
		------------ 数据信息 ------------
		nil,
		self:GetSkillDurationTime(),
		function (effectPercent, effectPhaseCounter)
			for i, v in ipairs(targetsWithBuffinfo) do
				local tTag = v.tag
				local buffs = v.buffs
				local target = nil

				if true == v.needRevive then
					target = G_BattleLogicMgr:GetDeadObjByTag(tTag)
				else
					target = G_BattleLogicMgr:IsObjAliveByTag(tTag)
				end

				if nil ~= target then
					self:AddBuffs2Target(target, buffs, actionPhaseCounter, params.percent, effectPhaseCounter, effectPercent, true)
				end
			end
		end
	)
	G_BattleLogicMgr:SendBullet(bulletData)
end
---------------------------------------------------
-- send bullet logic end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
获取技能id
--]]
function BaseSkill:GetSkillId()
	return self.skillData.skillId
end
--[[
获取技能等级
--]]
function BaseSkill:GetSkillLevel()
	return self.skillData.level
end
--[[
获取技能敌友性
--]]
function BaseSkill:GetIsSkillEnemy()
	return self.skillData.isEnemy
end
--[[
获取技能的施法者tag
--]]
function BaseSkill:GetSkillCasterTag()
	return self.skillData.casterTag
end
--[[
获取技能的施法者物体
--]]
function BaseSkill:GetSkillCaster()
	return G_BattleLogicMgr:IsObjAliveByTag(self:GetSkillCasterTag())
end
--[[
获取施法者的view model tag
--]]
function BaseSkill:GetSkillCasterViewModelTag()
	local caster = self:GetSkillCaster()
	if caster then
		return caster:GetViewModelTag()
	end
	return nil
end
--[[
获取本技能的天气id
--]]
function BaseSkill:GetSkillWeatherId()
	return self.skillData.weatherId
end
--[[
获取所有的buff配置信息
--]]
function BaseSkill:GetBuffsConfig()
	return self.skillData.skillInfo.buffsInfo
end
--[[
根据buff类型获取buff配置信息
@params buffType ConfigBuffType buff类型
--]]
function BaseSkill:GetBuffConfigByBuffType(buffType)
	return self:GetBuffsConfig()[tostring(buffType)]
end
--[[
根据buff类型获取buff触发的内置cd信息
@params buffType ConfigBuffType buff类型
--]]
function BaseSkill:GetBuffTriggerInsideCDByBuffType(buffType)
	local buffInfo = self:GetBuffConfigByBuffType(buffType)
	if nil ~= buffInfo then
		return buffInfo.triggerInsideCD
	else
		return nil
	end
end
--[[
获取buff的索敌规则配置信息
--]]
function BaseSkill:GetBuffsSeekRuleConfig()
	return self.skillData.skillInfo.seekRulesInfo
end
--[[
根据buff类型获取buff的索敌规则配置信息
@params buffType ConfigBuffType buff类型
--]]
function BaseSkill:GetBuffSeekRuleConfigByBuffType(buffType)
	return self:GetBuffsSeekRuleConfig()[tostring(buffType)]
end
--[[
获取本技能是否是被动技能
--]]
function BaseSkill:IsSkillHalo()
	return ConfigSkillType.SKILL_HALO == self.skillData.skillInfo.skillType
end
--[[
获取本技能buff的子弹展示信息
@return _ table
--]]
function BaseSkill:GetBulletEffectData()
	return self.skillData.bulletEffectData
end
--[[
获取本技能buff的被击效果信息
@return _ table
--]]
function BaseSkill:GetHurtEffectData()
	return self.skillData.hurtEffectData
end
--[[
获取本技能buff的附加效果展示信息
@return _ table
--]]
function BaseSkill:GetAttachEffectData()
	return self.skillData.attachEffectData
end
--[[
根据buff类型获取本技能的buff被击效果信息
@params buffType ConfigBuffType buff类型
@return _ table
--]]
function BaseSkill:GetHurtEffectDataByBuffType(buffType)
	return self:GetHurtEffectData()[tostring(buffType)] or {}
end
--[[
根据buff类型获取本技能的buff附加效果信息
@params buffType ConfigBuffType buff类型
@return _ table
--]]
function BaseSkill:GetAttachEffectDataByBuffType(buffType)
	return self:GetAttachEffectData()[tostring(buffType)] or {}
end
--[[
获取传染的时间间隔
--]]
function BaseSkill:GetSkillInfectTime()
	return self.skillData.skillInfo.infectTime
end
--[[
获取传染索敌规则
--]]
function BaseSkill:GetSkillInfectSeekRule()
	return self.skillData.skillInfo.infectSeekRule
end
--[[
获取技能的最长持续时间
--]]
function BaseSkill:GetSkillDurationTime()
	return self.durationTime
end
--[[
获取当前施法对象集合
--]]
function BaseSkill:SetTargetPool(targets)
	self.targetPool = targets
end
function BaseSkill:GetTargetPool()
	return self.targetPool
end
function BaseSkill:ClearTargetPool()
	self.targetPool = {}
end
--[[
获取当前分段
--]]
function BaseSkill:SetSkillPhase(phase)
	self.phase = phase
end
function BaseSkill:GetSkillPhase()
	return self.phase
end
function BaseSkill:ClearSkillPhase()
	self.phase = 0
end
--[[
根据buff类型获取触发行为信息
@params buffType ConfigBuffType buff类型
@return _ BuffTriggerActionStruct buff触发行为
--]]
function BaseSkill:GetBuffTriggerActionInfoByBuffType(buffType)
	return self.skillData.skillInfo.triggerActionInfo[tostring(buffType)]
end
--[[
根据buff类型获取触发条件信息
@params buffType ConfigBuffType buff类型
@return _ BuffTriggerConditionStruct buff触发条件
--]]
function BaseSkill:GetBuffTriggerConditionInfoByBuffType(buffType)
	return self.skillData.skillInfo.triggerConditionInfo[tostring(buffType)]
end
--[[
获取buff施放成功率
@params buffType ConfigBuffType
@return _ bool 是否能释放buff
--]]
function BaseSkill:CanCastBuff(buffType)
	if ConfigBuffType.TRIGGER_BUFF == buffType then return true end

	local judge = self:CanCastBuffByTriggerActionType(buffType, nil) and self:CanCastBuffBySuccessRate(buffType)

	return judge
end
--[[
根据buff内置的触发cd判断是否可以触发buff
@params buffType ConfigBuffType
@params triggerActionType ConfigObjectTriggerActionType 触发类型
@return _ bool 是否能触发buff
--]]
function BaseSkill:CanCastBuffByTriggerActionType(buffType, triggerActionType)
	local result = false
	local caster = self:GetSkillCaster()
	if nil ~= caster then
		result = caster:CanTriggerBuff(self:GetSkillId(), buffType, triggerActionType)
		-- debug --
		if not result then
			print(' - - can not trigger buff >>>>>>>>.', caster:GetObjectName(), self:GetSkillId(), buffType)
		end
		-- debug --
	end
	return result
end
--[[
根据概率判断是否可以释放buff
@params buffType ConfigBuffType
@return _ bool 是否能释放buff
--]]
function BaseSkill:CanCastBuffBySuccessRate(buffType)
	local buffSuccessRate = self:GetBuffCastSuccessRate(buffType)
	return G_BattleLogicMgr:GetRandomManager():GetRandomInt(1000) <= buffSuccessRate * 1000
end
--[[
获取buff释放成功率
@params buffType ConfigBuffType buff类型
@return successRate number 释放成功率
--]]
function BaseSkill:GetBuffCastSuccessRate(buffType)
	local successRate = self:GetBuffConfigByBuffType(buffType).successRate

	---------- 计算buff成功率增益 ----------
	local changeBuffTypes = {
		ConfigBuffType.CHANGE_BUFF_SUCCESS_RATE
	}

	local buffs = nil
	local targetBuff = nil

	local caster = self:GetSkillCaster()

	if nil ~= caster then
		for _, changeBuffType in ipairs(changeBuffTypes) do
			buffs = self:GetSkillCaster():GetBuffsByBuffType(changeBuffType, false)
			for i = #buffs, 1, -1 do
				targetBuff = buffs[i]
				successRate = targetBuff:CauseEffect(self:GetSkillId(), buffType, successRate)
			end
		end
	end
	---------- 计算buff成功率增益 ----------

	return successRate
end
--[[
技能索敌
@params isEnemy bool 这个技能本身的敌我性
@params seekRule SeekRuleStruct 索敌规则
@params extra table 附加参数
@return _ table 所对应的目标
--]]
function BaseSkill:SeekCastTargets(isEnemy, seekRule, extra)
	if 0 < self:GetSkillInfectTime() then

		return BattleExpression.GetSortedTargets(
			BattleExpression.GetFriendlyTargets(isEnemy, seekRule.ruleType, self:GetSkillId(), extra.o, nil, extra.triggerData),
			seekRule.sortType,
			seekRule.maxValue,
			extra
		)

	else

		return BattleExpression.GetSortedTargets(
			BattleExpression.GetFriendlyTargets(isEnemy, seekRule.ruleType, nil, extra.o, nil, extra.triggerData),
			seekRule.sortType,
			seekRule.maxValue,
			extra
		)

	end
end
--[[
墓地系技能索敌
@params isEnemy bool 这个技能本身的敌我性
@params seekRule SeekRuleStruct 索敌规则
@params extra table 附加参数
@return _ table 所对应的目标
--]]
function BaseSkill:SeekCastDeadTargets(isEnemy, seekRule, extra)
	return BattleExpression.GetSortedTargets(
		BattleExpression.GetDeadFriendlyTargets(isEnemy, seekRule.ruleType, extra.o, true),
		seekRule.sortType,
		seekRule.maxValue,
		extra
	)
end
--[[
根据buff类型判断该buff是否带有触发机制
@params buffType ConfigBuffType
@return _ bool 是否带有触发机制
--]]
function BaseSkill:IsBuffHasTriggerByBuffType(buffType)
	if ConfigBuffType.TRIGGER_BUFF == buffType then return true end

	local triggerActionInfo = self:GetBuffTriggerActionInfoByBuffType(buffType)
	return nil ~= triggerActionInfo and nil ~= next(triggerActionInfo)
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return BaseSkill
