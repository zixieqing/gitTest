--[[
战斗物体相关的数据结构
--]]
if not BaseStruct then __Require('battle.battleStruct.BaseStruct') end

---------------------------------------------------
-- 构造obj需要的数据结构 --
---------------------------------------------------
ObjectConstructorStruct = {
	--[[
	------------ 基本信息 ------------
	@params cardId int 卡牌id
	@params oriLocation ObjectLocation 战斗物体位置信息
	@params teamPosition int 队伍中的站位
	@params objectFeature BattleObjectFeature 战斗物体特征
	@params career ConfigCardCareer 物体职业
	@params isEnemy bool 敌我性
	------------ 数值信息 ------------
	@params property ObjProp 属性表
	@params skillData table {level = 0} 技能信息表
	@params talentData ArtifactTalentConstructorStruct 天赋信息
	@params exAbilityData EXAbilityConstructorStruct 卡牌超能力信息
	@params isLeader bool 是否是队长
	@params recordDeltaHp ConfigMonsterRecordDeltaHP 是否记录血量变化
	------------ 外貌信息 ------------
	@params skinId int 皮肤id
	@params avatarScale float 人物spine缩放
	@params defaultZOrder int 人物初始的图层
	------------ 触发的事件 ------------
	@params phaseChangeData PhaseChangeSturct 转阶段数据
	--]]
	New = function (
			cardId, oriLocation, teamPosition, objectFeature, career, isEnemy,
			property, skillData, talentData, exAbilityData, isLeader, recordDeltaHp,
			skinId, avatarScale, defaultZOrder,
			phaseChangeData
		)
		local this = NewStruct(ObjectConstructorStruct, BaseStruct)

		--[[---------- 初始化数据结构 ------------
		this.cardId = 0 						-- 卡牌id
		this.oriLocation = nil 					-- 战斗物体位置信息
		this.teamPosition = 0 	 				-- 队伍中的站位
		this.objectFeature = BattleObjectFeature.BASE -- 战斗物体特征
		this.career = ConfigCardCareer.BASE		-- 物体职业
		this.isEnemy = false	 				-- 敌我性
		this.property = nil 					-- 基础属性表
		this.skillData = {} 					-- 技能信息表
		this.talentData = nil 					-- 神器天赋信息
		this.exAbilityData = nil 				-- 卡牌超能力信息
		this.isLeader = false 					-- 初始能量
		this.recordDeltaHp = ConfigMonsterRecordDeltaHP.DONT -- 记录血量变化
		this.skinId = 0 						-- 皮肤id
		this.avatarScale = 1 					-- avatar缩放
		this.phaseChangeData = nil 				-- 转阶段数据
		------------ 初始化数据结构 ----------]]--

		this:Init(
			cardId, oriLocation, teamPosition, objectFeature, career, isEnemy,
			property, skillData, talentData, exAbilityData, isLeader, recordDeltaHp,
			skinId, avatarScale, defaultZOrder,
			phaseChangeData
		)

		return this
	end,
	Init = function (self,
			cardId, oriLocation, teamPosition, objectFeature, career, isEnemy,
			property, skillData, talentData, exAbilityData, isLeader, recordDeltaHp,
			skinId, avatarScale, defaultZOrder,
			phaseChangeData
		)

		self.cardId = cardId
		self.oriLocation = oriLocation
		self.teamPosition = teamPosition
		self.objectFeature = objectFeature
		self.career = career
		self.isEnemy = isEnemy
		self.property = property
		self.skillData = skillData or {}
		self.talentData = talentData
		self.exAbilityData = exAbilityData
		self.isLeader = isLeader or false
		self.recordDeltaHp = recordDeltaHp or ConfigMonsterRecordDeltaHP.DONT
		self.skinId = skinId
		self.avatarScale = avatarScale or 1
		self.defaultZOrder = defaultZOrder or 0
		self.phaseChangeData = phaseChangeData

	end
}
---------------------------------------------------
-- 构造obj需要的数据结构 --
---------------------------------------------------

---------------------------------------------------
-- 构造卡牌obj属性需要的数据结构 --
---------------------------------------------------
CardPropertyConstructStruct = {
	--[[
	@params cardId int 卡牌id
	@params level int 卡牌等级
	@params breakLevel int 突破等级
	@params favorLevel int 好感度等级
	@params petData PetConstructorStruct 宠物信息
	@params talentData ArtifactTalentConstructorStruct 神器信息
	@params oriLocation ObjectLocation 位置信息
	@params singleAddition ObjPFixedAttrStruct 个体值加成
	@params ultimateAddition ObjectPropertyFixedAttrStruct 最终值加成 总控的值 做卡牌pvc卡牌血量翻倍的逻辑
	--]]
	New = function (
			cardId, level, breakLevel, favorLevel, petData, talentData,
			singleAddition, ultimateAddition,
			oriLocation
		)
		local this = NewStruct(CardPropertyConstructStruct, BaseStruct)

		--[[---------- 初始化数据结构 ------------
		this.cardId = 0 						-- 卡牌id
		this.level = 0 							-- 卡牌等级
		this.breakLevel = 0 					-- 卡牌突破等级
		this.favorLevel = 1 					-- 卡牌好感度等级
		this.petData = nil 						-- 宠物信息
		this.talentData = nil 					-- 天赋信息
		this.singleAddition = nil 				-- 属性个体值加成
		this.ultimateAddition = nil 			-- 属性最终值加成
		this.oriLocation = nil 					-- 卡牌位置信息
		------------ 初始化数据结构 ----------]]--

		this:Init(
			cardId, level, breakLevel, favorLevel, petData, talentData,
			singleAddition, ultimateAddition,
			oriLocation
		)

		return this
	end,
	Init = function (self,
			cardId, level, breakLevel, favorLevel, petData, talentData,
			singleAddition, ultimateAddition,
			oriLocation
		)
		self.cardId = cardId
		self.level = level
		self.breakLevel = breakLevel
		self.favorLevel = favorLevel or 1
		self.petData = petData
		self.talentData = talentData

		self.singleAddition = singleAddition
		self.ultimateAddition = ultimateAddition

		self.oriLocation = oriLocation
	end
}
---------------------------------------------------
-- 构造卡牌obj属性需要的数据结构 --
---------------------------------------------------

---------------------------------------------------
-- 构造怪物obj属性需要的数据结构 --
---------------------------------------------------
MonsterPropertyConstructStruct = {
	--[[
	@params cardId int 卡牌id
	@params level int 怪物等级
	@params attrGrow number 属性成长系数
	@params skillGrow number 技能成长系数
	@params singleAddition ObjPFixedAttrStruct 个体值加成
	@params ultimateAddition ObjectPropertyFixedAttrStruct 最终值加成
	@params oriLocation ObjectLocation 位置信息
	--]]
	New = function (
			cardId, level, attrGrow, skillGrow,
			singleAddition, ultimateAddition,
			oriLocation
		)
		local this = NewStruct(MonsterPropertyConstructStruct, BaseStruct)

		--[[---------- 初始化数据结构 ------------
		this.cardId = 0 						-- 卡牌id
		this.level = 0 							-- 卡牌等级
		this.attrGrow = 0 						-- 卡牌属性成长系数
		this.skillGrow = 1 						-- 卡牌技能成长系数
		this.singleAddition = nil 				-- 个体值加成
		this.ultimateAddition = nil 			-- 属性最终值加成
		this.oriLocation = nil 					-- 卡牌位置信息
		------------ 初始化数据结构 ----------]]--

		this:Init(
			cardId, level, attrGrow, skillGrow,
			singleAddition, ultimateAddition,
			oriLocation
		)

		return this
	end,
	Init = function (self,
			cardId, level, attrGrow, skillGrow,
			singleAddition, ultimateAddition,
			oriLocation
		)
		self.cardId = cardId
		self.level = level
		self.attrGrow = attrGrow
		self.skillGrow = skillGrow
		self.singleAddition = singleAddition
		self.ultimateAddition = ultimateAddition
		self.oriLocation = oriLocation
	end
}
---------------------------------------------------
-- 构造怪物obj属性需要的数据结构 --
---------------------------------------------------

---------------------------------------------------
-- 构造obj view需要的数据结构 --
---------------------------------------------------
ObjectViewConstructStruct = {
	--[[
	@params cardId int 卡牌id
	@params skinId int 皮肤id
	@params avatarScale number 人物缩放
	@params avatarScale2Card number 相对于卡牌的缩放
	@params isEnemy bool 是否是敌人
	--]]
	New = function (cardId, skinId, avatarScale, avatarScale2Card, isEnemy)
		local this = NewStruct(ObjectViewConstructStruct, BaseStruct)

		--[[---------- 初始化数据结构 ------------
		this.cardId = 0 						-- 卡牌id
		this.skinId = 0 						-- 皮肤id
		this.avatarScale = 1 					-- 人物缩放
		this.avatarScale2Card = 1 				-- 相对于卡牌的缩放
		this.isEnemy = true 					-- 是否是敌方
		------------ 初始化数据结构 ----------]]--

		this:Init(cardId, skinId, avatarScale, avatarScale2Card, isEnemy)

		return this
	end,
	Init = function (self, cardId, skinId, avatarScale, avatarScale2Card, isEnemy)
		self.cardId = cardId
		self.skinId = skinId
		self.avatarScale = avatarScale
		self.avatarScale2Card = avatarScale2Card
		self.isEnemy = isEnemy
	end
}
---------------------------------------------------
-- 构造obj view需要的数据结构 --
---------------------------------------------------

---------------------------------------------------
-- 战斗物体的tag信息 --
---------------------------------------------------
ObjectTagStruct = {
	--[[
	@params tag int 战斗物体tag
	@params oname string 战斗物体名字
	--]]
	New = function (tag, oname)
		local this = NewStruct(ObjectTagStruct, BaseStruct)
		
		--[[---------- 初始化数据结构 ------------
		this.tag = 0 							-- 战斗物体tag
		this.oname = nil 						-- 战斗物体名字
		------------ 初始化数据结构 ----------]]--

		this:Init(tag, oname)

		return this
	end,
	Init = function (self, tag, oname)
		self.tag = tag
		self.oname = oname
	end
}
---------------------------------------------------
-- 战斗物体的tag信息 --
---------------------------------------------------

---------------------------------------------------
-- 位置信息数据结构 --
---------------------------------------------------
ObjectLocation = {
	--[[
	@params x number x坐标
	@params y number y坐标
	@params r int 行数
	@params c int 列数
	--]]
	New = function (x, y, r, c)
		local this = NewStruct(ObjectLocation, BaseStruct)

		------------ 初始化数据结构 ------------
		this.po = {}
		this.rc = {}
		------------ 初始化数据结构 ------------

		this:Init(x, y, r, c)

		return this
	end,
	Init = function (self, x, y, r, c)
		self.po.x = x
		self.po.y = y
		self.rc.r = r
		self.rc.c = c
	end
}
---------------------------------------------------
-- 位置信息数据结构 --
---------------------------------------------------

---------------------------------------------------
-- 从配表转换来的战斗物体技能数据结构 --
---------------------------------------------------
ObjectSkillStruct = {
	--[[
	@params skillId int 技能id
	@params skill BaseSkill 技能模型
	@params extraInfo table 附加技能信息 {
		weakPoints list 弱点信息
		connectCardId list 连携卡牌信息
	}
	--]]
	New = function (skillId, skill, extraInfo)
		local this = NewStruct(ObjectSkillStruct, BaseStruct)

		--[[---------- 初始化数据结构 ------------
		this.skillId = 0 						-- 技能id
		this.skill = nil 						-- 技能模型
		this.weakPoints = nil 					-- 弱点信息
		this.connectCardId = nil 				-- 连携卡牌信息
		------------ 初始化数据结构 ----------]]--

		this:Init(skillId, skill, extraInfo)

		return this
	end,
	Init = function (self, skillId, skill, extraInfo)
		self.skillId = skillId
		self.skill = skill
		if nil ~= extraInfo then
			if nil ~= extraInfo.weakPoints then
				self.weakPoints = extraInfo.weakPoints
			end
			if nil ~= extraInfo.connectCardId then
				self.connectCardId = extraInfo.connectCardId
			end
		end
	end
}
---------------------------------------------------
-- 从配表转换来的战斗物体技能数据结构 --
---------------------------------------------------

---------------------------------------------------
-- 物体携带的单个技能数据 --
---------------------------------------------------
ObjSkillDataStruct = {
	--[[
	@params skillId int 技能id
	@params skillLevel int 技能等级
	--]]
	New = function (skillId, skillLevel)
		local this = NewStruct(ObjSkillDataStruct, BaseStruct)

		--[[---------- 初始化数据结构 ------------
		this.skillId = 0 						-- 技能id
		this.level = skillLevel or 1 			-- 技能等级
		------------ 初始化数据结构 ----------]]--

		this:Init(skillId, skillLevel)

		return this
	end,
	Init = function (self, skillId, skillLevel)
		self.skillId = skillId
		self.level = skillLevel
	end
}
---------------------------------------------------
-- 物体携带的单个技能数据 --
---------------------------------------------------

---------------------------------------------------
-- 伤害信息传递的数据结构 --
---------------------------------------------------
ObjectDamageStruct = {
	--[[
	@params targetTag int 目标对象tag
	@params damage number 伤害数值
	@params damageType DamageType 伤害类型
	@params isCritical bool 是否暴击
	@params fromTag table {
		attackerTag int 攻击者tag
		healerTag int 治疗者tag
	}
	@params skillInfo table 技能信息 {
		skillId int 技能id
		btype ConfigBuffType 技能类型
	}
	--]]
	New = function (targetTag, damage, damageType, isCritical, fromTag, skillInfo)
		local this = NewStruct(ObjectDamageStruct, BaseStruct)

		--[[---------- 初始化数据结构 ------------
		this.targetTag = nil 					-- 攻击目标对象tag
		this.damage = 0 						-- 伤害数值
		this.damageType = DamageType.INVALID 	-- 伤害类型
		this.isCritical = false 				-- 是否暴击
		this.attackerTag = nil 					-- 攻击者tag
		this.healerTag = nil 					-- 治疗者tag
		this.skillInfo = nil 					-- 技能信息
		------------ 初始化数据结构 ----------]]--

		this:Init(targetTag, damage, damageType, isCritical, fromTag, skillInfo)

		return this
	end,
	Init = function (self, targetTag, damage, damageType, isCritical, fromTag, skillInfo)

		self:OverloadMetaFunction()

		self.targetTag = targetTag
		self.damage = damage
		self.damageType = damageType
		self.isCritical = isCritical
		if nil ~= fromTag then
			if nil ~= fromTag.attackerTag then
				self.attackerTag = fromTag.attackerTag
			elseif nil ~= fromTag.healerTag then
				self.healerTag = fromTag.healerTag
			end
		end
		if nil ~= skillInfo then
			self.skillInfo = skillInfo
		end
	end,
	--[[
	设置伤害值
	--]]
	SetDamageValue = function (self, damage)
		if nil ~= self.damage then
			if nil == tonumber(damage) then
				self.damage:SetRBQV(damage:ObtainVal())
			else
				self.damage:SetRBQV(damage)
			end
			
		else
			self.damage = damage
		end
	end,
	--[[
	获取伤害值
	--]]
	GetDamageValue = function (self)
		if nil ~= self.damage then
			return self.damage:ObtainVal()
		else
			return nil
		end
	end,
	--[[
	重载元方法 一般用来重载运算符
	--]]
	OverloadMetaFunction = function (self)
		local metatable_ = getmetatable(self)
		if nil ~= metatable_ then
			------------ __newindex [=] ------------
			metatable_.__newindex = function (t, k, v)
				if 'damage' == k then
					if nil == v then
						rawset(t, k, v)
					else
						rawset(t, k, RBQN.New(v))
					end
				else
					rawset(t, k, v)
				end
			end
			------------ __newindex [=] ------------
		end
	end,
	--[[
	判断伤害是否是治疗
	--]]
	IsHeal = function (self)
		return nil ~= self.healerTag
	end,
	--[[
	获取伤害源的物体tag
	--]]
	GetSourceObjTag = function (self)
		return self.healerTag or self.attackerTag
	end,
	--[[
	获取造成伤害的buff类型
	--]]
	GetDamageBuffType = function (self)
		if nil ~= self.skillInfo then
			return self.skillInfo.btype
		else
			return nil
		end
	end,
	--[[
	是否是由技能造成的伤害
	--]]
	CausedBySkill = function (self)
		if nil ~= self.skillInfo then
			return true
		else
			return false
		end
	end,
	CloneStruct = function (self)
		local fromTag = {
			attackerTag = self.attackerTag,
			healerTag = self.healerTag
		}
		local skillInfo = self.skillInfo
		local this = ObjectDamageStruct.New(
			self.targetTag,
			self.damage,
			self.damageType,
			self.isCritical,
			fromTag,
			skillInfo
		)
		return this
	end
}
---------------------------------------------------
-- 伤害信息传递的数据结构 --
---------------------------------------------------

---------------------------------------------------
-- 构建技能模型时传入的数据结构 --
---------------------------------------------------
SkillConstructorStruct = {
	--[[
	@params skillId int 技能id
	@params level int 技能等级
	@params skillInfo ConfigSkillInfoStruct 技能信息
	@params isEnemy bool 技能的敌我性 索敌规则相关
	@params casterTag int 施法者tag
	@params skillEffectData SkillSpineEffectStruct 技能附带的特效信息
	@params extraInfo table 额外参数
	--]]
	New = function (
			skillId, level, skillInfo, isEnemy, casterTag, skillEffectData, extraInfo
		)
		local this = NewStruct(SkillConstructorStruct, BaseStruct)

		--[[---------- 初始化数据结构 ------------
		this.skillId = 0 						-- 技能id
		this.level = 1 							-- 技能等级
		this.isEnemy = true 					-- 技能的敌我性
		this.casterTag = 0						-- 施法者 tag
		this.bulletEffectData = {} 				-- 子弹信息
		this.hurtEffectData = {} 				-- 被击爆点信息
		this.attachEffectData = {} 				-- 附加特效信息

		this.weatherId = 0 						-- 天气id
		------------ 初始化数据结构 ----------]]--

		this:Init(skillId, level, skillInfo, isEnemy, casterTag, skillEffectData, extraInfo)
		return this
	end,
	Init = function (self,
			skillId, level, skillInfo, isEnemy, casterTag, skillEffectData, extraInfo
		)

		self.skillId = skillId
		self.level = level
		self.skillInfo = skillInfo
		self.isEnemy = isEnemy
		self.casterTag = casterTag

		------------ 发射的子弹信息 ------------
		self.bulletEffectData = {
			effectId = skillEffectData.effectId,
			effectActionName = skillEffectData.effectActionName,
			bulletType = skillEffectData.bulletType,
			causeType = skillEffectData.causeType,
			effectZOrder = skillEffectData.effectZOrder,
			effectScale = skillEffectData.effectScale,
			effectPos = skillEffectData.effectPos
		}
		------------ 发射的子弹信息 ------------

		------------ 技能释放后对受法者的被击爆点信息 ------------
		self.hurtEffectData = skillEffectData.hurtEffectData
		self.attachEffectData = skillEffectData.attachEffectData
		------------ 技能释放后对受法者的被击爆点信息 ------------

		if nil ~= extraInfo then
			if nil ~= extraInfo.weatherId then
				self.weatherId = extraInfo.weatherId
			end
		end

	end
}
---------------------------------------------------
-- 构建技能模型时传入的数据结构 --
---------------------------------------------------

---------------------------------------------------
-- 构造的技能配置数据 --
---------------------------------------------------
ConfigSkillInfoStruct = {
	--[[
	@params skillId int 技能id
	@params skillType ConfigSkillType 技能类型
	@params buffsInfo map buffs信息
	@params seekRulesInfo map 索敌规则信息
	@params infectSeekRule SeekRuleStruct 传染索敌规则
	@params infectTime number 传染时间
	@params triggerActionInfo map<ConfigBuffType, list<BuffTriggerActionStruct>> 触发行为数据
	@params triggerConditionInfo map 触发条件数据
	--]]
	New = function (
			skillId, skillType, buffsInfo, seekRulesInfo, infectSeekRule, infectTime,
			triggerActionInfo, triggerConditionInfo
		)
		local this = NewStruct(ConfigSkillInfoStruct, BaseStruct)

		--[[---------- 初始化数据结构 ------------
		this.skillId = 0 						-- 技能id
		this.skillType = 0 						-- 技能类型
		this.buffsInfo = {} 					-- buffs信息
		this.seekRulesInfo = {}					-- 索敌规则信息
		this.infectSeekRule = nil				-- 传染索敌规则
		this.infectTime = 0 					-- 传染时间
		this.triggerActionInfo = {} 			-- 触发行为信息
		this.triggerConditionInfo = {} 			-- 触发条件信息
		------------ 初始化数据结构 ----------]]--

		this:Init(
			skillId, skillType, buffsInfo, seekRulesInfo, infectSeekRule, infectTime,
			triggerActionInfo, triggerConditionInfo
		)

		return this
	end,
	Init = function (self,
			skillId, skillType, buffsInfo, seekRulesInfo, infectSeekRule, infectTime,
			triggerActionInfo, triggerConditionInfo
		)

		self.skillId = skillId
		self.skillType = skillType
		self.buffsInfo = buffsInfo
		self.seekRulesInfo = seekRulesInfo
		self.infectSeekRule = infectSeekRule
		self.infectTime = infectTime
		self.triggerActionInfo = triggerActionInfo
		self.triggerConditionInfo = triggerConditionInfo

	end
}
---------------------------------------------------
-- 构造的技能配置数据 --
---------------------------------------------------

---------------------------------------------------
-- 构造的buff配置数据 --
---------------------------------------------------
ConfigBuffInfoStruct = {
	--[[
	@params skillId int 技能id
	@params buffType ConfigBuffType buff类型
	@params value table buff效果值
	@params time number buff持续时间
	@params triggerInsideCD number buff触发的内置cd
	@params innerPileMax int 内置叠加上限
	@params successRate number buff释放成功率
	@params qteTapTime int qtebuff点击次数
	--]]
	New = function (
			skillId, buffType, value, time, triggerInsideCD, innerPileMax, successRate, qteTapTime
		)
		local this = NewStruct(ConfigBuffInfoStruct, BaseStruct)

		--[[---------- 初始化数据结构 ------------
		this.skillId = 0 						-- 技能id
		this.buffType = 0 						-- buff类型
		this.value = {} 						-- buff效果值
		this.time = 0 							-- buff持续时间
		this.triggerInsideCD = nil 				-- 内置cd
		this.innerPileMax = nil 				-- 内部叠加上限
		this.successRate = 0					-- buff释放成功率
		this.qteTapTime = 0 					-- qtebuff点击次数
		------------ 初始化数据结构 ----------]]--

		this:Init(
			skillId, buffType, value, time, triggerInsideCD, innerPileMax, successRate, qteTapTime
		)

		return this
	end,
	Init = function (self,
			skillId, buffType, value, time, triggerInsideCD, innerPileMax, successRate, qteTapTime
		)

		self.skillId = skillId
		self.buffType = buffType
		self.value = checktable(value)
		self.time = time
		self.triggerInsideCD = triggerInsideCD
		self.innerPileMax = innerPileMax
		self.successRate = successRate
		self.qteTapTimes = qteTapTime

	end
}
---------------------------------------------------
-- 构造的buff配置数据 --
---------------------------------------------------

---------------------------------------------------
-- 索敌规则的数据结构 --
---------------------------------------------------
SeekRuleStruct = {
	--[[
	@params ruleType ConfigSeekTargetRule 索敌类型
	@params sortType SeekSortRule 排序类型
	@params maxValue int 最大单位数
	--]]
	New = function (ruleType, sortType, maxValue)
		local this = NewStruct(SeekRuleStruct, BaseStruct)

		--[[---------- 初始化数据结构 ------------
		this.ruleType = 0 						-- 索敌类型
		this.sortType = 0 						-- 排序类型
		this.maxValue = 0 						-- 最大单位数
		------------ 初始化数据结构 ----------]]--

		this:Init(ruleType, sortType, maxValue)

		return this
	end,
	Init = function (self,
			ruleType, sortType, maxValue
		)

		self.ruleType = ruleType
		self.sortType = sortType
		self.maxValue = maxValue

		self:OverloadMetaFunction()

	end,
	--[[
	重载元方法 一般用来重载运算符
	--]]
	OverloadMetaFunction = function (self)
		local metatable_ = getmetatable(self)
		if nil ~= metatable_ then
			------------ __eq [==] ------------
			metatable_.__eq = function (a, b)
				if a.ruleType == b.ruleType and
					a.sortType == b.sortType and 
					a.maxValue == b.maxValue then
					return true
				else
					return false
				end
			end
			------------ __eq [==] ------------
		end
	end
}
---------------------------------------------------
-- 索敌规则的数据结构 --
---------------------------------------------------

---------------------------------------------------
-- buff触发行为的数据结构 --
---------------------------------------------------
BuffTriggerActionStruct = {
	--[[
	@params objTriggerActionType ConfigObjectTriggerActionType 物体行为触发类型
	@params triggerSeekRule SeekRuleStruct 触发后索敌
	@params time number 触发后的持续时间
	@params triggerRate number 触发概率
	@params triggerInsideCD number buff触发的内置cd
	--]]
	New = function (objTriggerActionType, triggerSeekRule, time, triggerRate, triggerInsideCD)
		local this = NewStruct(BuffTriggerActionStruct, BaseStruct)

		--[[---------- 初始化数据结构 ------------
		this.objTriggerActionType = ConfigObjectTriggerActionType.BASE -- 索敌类型
		this.triggerSeekRule = nil 				-- 排序类型
		this.time = 0 							-- 最大单位数
		this.triggerTime = 0 					-- 触发概率
		this.triggerInsideCD = nil 				-- buff的触发内置cd
		------------ 初始化数据结构 ----------]]--

		this:Init(objTriggerActionType, triggerSeekRule, time, triggerRate, triggerInsideCD)

		return this
	end,
	Init = function (self,
			objTriggerActionType, triggerSeekRule, time, triggerRate, triggerInsideCD
		)

		self.objTriggerActionType = objTriggerActionType or ConfigObjectTriggerActionType.BASE
		self.triggerSeekRule = triggerSeekRule
		self.time = time
		self.triggerRate = triggerRate
		self.triggerInsideCD = triggerInsideCD or 0

	end
}
---------------------------------------------------
-- buff触发行为的数据结构 --
---------------------------------------------------

---------------------------------------------------
-- buff触发条件的数据结构 --
---------------------------------------------------
BuffTriggerConditionStruct = {
	--[[
	@params objTriggerConditionType ConfigObjectTriggerConditionType 物体触发条件类型
	@params triggerSeekRule SeekRuleStruct 触发时索敌
	@params value table 触发判定值
	@params meetType ConfigMeetConditionType 满足条件的类型
	--]]
	New = function (objTriggerConditionType, triggerSeekRule, value, meetType)
		local this = NewStruct(BuffTriggerConditionStruct, BaseStruct)

		--[[---------- 初始化数据结构 ------------
		this.objTriggerConditionType = ConfigObjectTriggerConditionType.BASE -- 索敌类型
		this.triggerSeekRule = nil 				-- 排序类型
		this.value = {} 						-- 触发判定值
		this.meetType = ConfigMeetConditionType.BASE -- 满足类型
		------------ 初始化数据结构 ----------]]--

		this:Init(objTriggerConditionType, triggerSeekRule, value, meetType)

		return this
	end,
	Init = function (self,
			objTriggerConditionType, triggerSeekRule, value, meetType
		)

		self.objTriggerConditionType = objTriggerConditionType or ConfigObjectTriggerConditionType.BASE
		self.triggerSeekRule = triggerSeekRule
		self.value = value
		self.meetType = meetType

	end
}
---------------------------------------------------
-- buff触发条件的数据结构 --
---------------------------------------------------

---------------------------------------------------
-- 发射子弹传递的数据结构 --
---------------------------------------------------
ObjectSendBulletData = {
	--[[
	------------ 基本信息 ------------
	tag int 子弹唯一标识
	oname string 子弹名字
	otype ConfigEffectBulletType 特效子弹类型
	causeType ConfigEffectCauseType 特效指向类型
	ownerTag int 发射者tag
	targetTag int 目标tag 如果发射的特效为集团性效果则为空
	targetDead bool 目标是否死亡
	------------ spine动画信息 ------------
	spineId string 特效id 缓存中的id
	actionName string spine动画的动作名
	bulletZOrder int 特效层级
	oriLocation cc.p 初始位置
	targetLocation cc.p 初始目标位置
	bulletScale number 特效缩放
	fixedPos cc.p 修正位置
	towards bool 朝向 是否朝向右
	shouldShakeWorld bool 是否需要造成震屏
	needHighlight bool 是否需要高亮
	------------ 数据信息 ------------
	damageData ObjectDamageStruct 伤害信息
	durationTime number 持续时间
	causeEffectCallback function 收到自定义事件的回调函数 
	--]]
	New = function (
			tag, oname, otype, causeType, ownerTag, targetTag, targetDead,
			spineId, actionName, bulletZOrder, oriLocation, targetLocation, bulletScale, fixedPos, towards, shouldShakeWorld, needHighlight,
			damageData, durationTime, causeEffectCallback
		)
		local this = NewStruct(ObjectSendBulletData, BaseStruct)

		--[[---------- 初始化数据结构 ------------
		this.tag = 0 							-- 子弹唯一标识
		this.oname = '' 						-- 子弹名字
		this.otype = ConfigEffectBulletType.BASE 		-- 子弹类型
		this.causeType = ConfigEffectCauseType.BASE 	-- 特效指向类型
		this.ownerTag = 0 						-- 发射者tag
		this.targetTag = nil 					-- 目标tag
		this.targetDead = false 				-- 目标是否死亡
		this.spineId = ''						-- 特效缓存的id
		this.actionName = '' 					-- spine动画的动作名
		this.bulletZOrder = 1 					-- 特效层级
		this.oriLocation = cc.p(0, 0) 			-- 初始位置
		this.targetLocation = cc.p(0, 0) 		-- 目标位置
		this.bulletScale = 1 					-- 发射的子弹特效缩放
		this.fixedPos cc.p 		 				-- 发射子弹的修正位置
		this.towards = true 					-- 朝向
		this.shouldShakeWorld = false 			-- 是否需要震屏
		this.needHighlight = false 				-- 是否需要高亮
		this.damageData = nil 					-- 伤害信息
		this.durationTime = 0 					-- 持续时间
		this.causeEffectCallback = nil 			-- 自定义事件的回调函数
		------------ 初始化数据结构 ----------]]--

		this:Init(
			tag, oname, otype, causeType, ownerTag, targetTag, targetDead,
			spineId, actionName, bulletZOrder, oriLocation, targetLocation, bulletScale, fixedPos, towards, shouldShakeWorld, needHighlight,
			damageData, durationTime, causeEffectCallback
		)

		return this
	end,
	Init = function (self,
			tag, oname, otype, causeType, ownerTag, targetTag, targetDead,
			spineId, actionName, bulletZOrder, oriLocation, targetLocation, bulletScale, fixedPos, towards, shouldShakeWorld, needHighlight,
			damageData, durationTime, causeEffectCallback
		)

		------------ 基本信息 ------------
		self.tag = tag
		self.oname = oname
		self.otype = otype
		self.causeType = causeType
		self.ownerTag = ownerTag
		self.targetTag = targetTag
		self.targetDead = targetDead
		------------ 基本信息 ------------

		------------ spine动画信息 ------------
		self.spineId = spineId
		self.actionName = actionName
		self.bulletZOrder = bulletZOrder
		self.oriLocation = oriLocation
		self.targetLocation = targetLocation
		self.bulletScale = bulletScale
		self.fixedPos = fixedPos
		self.towards = towards
		self.shouldShakeWorld = shouldShakeWorld
		self.needHighlight = needHighlight
		------------ spine动画信息 ------------

		------------ 数据信息 ------------
		self.damageData = damageData
		self.durationTime = durationTime
		self.causeEffectCallback = causeEffectCallback
		------------ 数据信息 ------------

	end
}
---------------------------------------------------
-- 发射子弹传递的数据结构 --
---------------------------------------------------

---------------------------------------------------
-- 施法传递buff的数据结构 --
---------------------------------------------------
ObjectBuffConstructorStruct = {
	--[[
	------------ 基本信息 ------------
	@params skillId int 技能id
	@params buffId string 区别buff叠加规则的唯一id
	@params buffType ConfigBuffType buff的配表类型 
	@params buffKind BKIND buff性质类别
	@parmas ownerTag int 受法者tag
	@params casterTag int 施法者tag
	@params isDebuff bool 是否是debuff
	@params isHalo bool 是否是光环
	@params className string 类名
	@params causeEffectTime BuffCauseEffectTime buff生效时机
	------------ 数值信息 ------------
	@params value number 技能效果数值
	@params time number 技能效果时间
	@params triggerInsideCD numebr buff内置cd
	@params innerPileMax int 内部叠加最大层数
	@params qteTapTime int qte点击次数
	------------ 展示特效信息 ------------
	@params iconType BuffIconType buff图标类型
	@params attachAniEffectData table 附加特效信息 {
		attachEffectId int 附加特效id
		attachEffectPos cc.p 附加特效坐标
	}
	------------ 附加额外信息 ------------
	@params extraInfo table {
		weatherId int 天气id
		hurtEffectData table 爆点信息
	}
	--]]
	New = function (
			skillId, buffId, buffType, buffKind, ownerTag, casterTag, isDebuff, isHalo, className, causeEffectTime,
			value, time, triggerInsideCD, innerPileMax, qteTapTime,
			iconType,
			attachAniEffectData,
			extraInfo
		)
		local this = NewStruct(ObjectBuffConstructorStruct, BaseStruct)

		--[[---------- 初始化数据结构 ------------
		this.skillId = 0 	 					-- 技能id
		this.bid = 0					 		-- buffId
		this.btype = ConfigBuffType.BASE 		-- buff类型
		this.bkind = BKIND.BASE 				-- buff性质类别
		this.ownerTag = 0 						-- 受法者tag
		this.casterTag = 0  					-- 施法者信息
		this.isDebuff = false 					-- 是否是debuff
		this.isHalo = false 					-- 是否是光环
		this.className = 'battle.buff.BaseBuff' -- 基本buff类型名
		this.value = 0 							-- buff数值
		this.time = 0 							-- buff时间
		this.triggerInsideCD = 0 				-- buff触发的内置cd
		this.innerPileMax = 0 					-- 内置叠加上限
		this.percent = 0 						-- 斩杀buff的斩杀线
		this.qteTapTime = 0 					-- qte点击次数
		this.iconType = nil 					-- buff图标类型
		this.attachAniEffectData = {} 			-- buff附加特效信息

		this.weatherId = nil 					-- 对应的天气id
		------------ 初始化数据结构 ----------]]--

		this:Init(
			skillId, buffId, buffType, buffKind, ownerTag, casterTag, isDebuff, isHalo, className, causeEffectTime,
			value, time, triggerInsideCD, innerPileMax, qteTapTime,
			iconType,
			attachAniEffectData,
			extraInfo
		)

		return this
	end,
	Init = function (self,
			skillId, buffId, buffType, buffKind, ownerTag, casterTag, isDebuff, isHalo, className, causeEffectTime,
			value, time, triggerInsideCD, innerPileMax, qteTapTime,
			iconType,
			attachAniEffectData,
			extraInfo
		)

		------------ 基本信息 ------------
		self.skillId = skillId
		self.bid = buffId
		self.btype = buffType
		self.bkind = buffKind
		self.ownerTag = ownerTag
		self.casterTag = casterTag
		self.isDebuff = isDebuff
		self.isHalo = isHalo
		self.className = className
		self.causeEffectTime = causeEffectTime
		------------ 基本信息 ------------

		------------ 数值信息 ------------
		self.value = value or {0, 0}
		self.time = time or 0
		self.triggerInsideCD = triggerInsideCD or 0
		self.innerPileMax = innerPileMax or 1
		self.qteTapTime = qteTapTime or 0
		-- 斩杀buff专用
		self.percent = 0
		------------ 数值信息 ------------

		------------ 展示特效信息 ------------
		self.iconType = iconType
		self.attachAniEffectData = attachAniEffectData or {}
		------------ 展示特效信息 ------------

		------------ 附加的额外信息 ------------
		if nil ~= extraInfo then
			if nil ~= extraInfo.weatherId then
				self.weatherId = extraInfo.weatherId
			end
			if nil ~= extraInfo.hurtEffectData then
				self.hurtEffectData = extraInfo.hurtEffectData
			end
		end
		------------ 附加的额外信息 ------------
	end,
	--[[
	获取用于查找索敌规则的buff类型
	--]]
	GetSeekRuleBuffType = function (self)
		return self.btype
	end
}
-- 触发buff --
ObjectTriggerBuffConstructorStruct = {
	New = function (
			skillId, buffId, buffType, buffKind, ownerTag, casterTag, isDebuff, isHalo, className, causeEffectTime,
			value, time, triggerInsideCD, innerPileMax, qteTapTime,
			iconType,
			attachAniEffectData,
			extraInfo
		)
		local this = NewStruct(ObjectTriggerBuffConstructorStruct, ObjectBuffConstructorStruct)

		this:Init(
			skillId, buffId, buffType, buffKind, ownerTag, casterTag, isDebuff, isHalo, className, causeEffectTime,
			value, time, triggerInsideCD, innerPileMax, qteTapTime,
			iconType,
			attachAniEffectData,
			extraInfo
		)

		return this
	end,
	Init = function (self,
			skillId, buffId, buffType, buffKind, ownerTag, casterTag, isDebuff, isHalo, className, causeEffectTime,
			value, time, triggerInsideCD, innerPileMax, qteTapTime,
			iconType,
			attachAniEffectData,
			extraInfo
		)

		ObjectBuffConstructorStruct.Init(self,
			skillId, buffId, buffType, buffKind, ownerTag, casterTag, isDebuff, isHalo, className, causeEffectTime,
			value, time, triggerInsideCD, innerPileMax, qteTapTime,
			iconType,
			attachAniEffectData,
			extraInfo
		)

		self.triggerBuffInfos = {}

	end,
	--[[
	添加一个buff配置
	@params buffInfo ConfigBuffInfoStruct 构造buff配置的数据
	@params triggerActionInfo BuffTriggerActionStruct 触发行为数据
	@params triggerConditionInfo BuffTriggerConditionStruct 触发条件数据
	@params hurtEffectData table 爆点信息数据
	@params attachEffectData table 附加效果信息数据
	--]]
	AddTriggerBuffInfo = function (self,
			buffInfo, triggerActionInfo, triggerConditionInfo, hurtEffectData, attachEffectData
		)

		self.triggerBuffInfos[tostring(buffInfo.buffType)] = {
			buffInfo = buffInfo,
			triggerActionInfo = triggerActionInfo,
			triggerConditionInfo = triggerConditionInfo,
			hurtEffectData = hurtEffectData,
			attachEffectData = attachEffectData
		}

	end,
	--[[
	获取用于查找索敌规则的buff类型
	--]]
	GetSeekRuleBuffType = function (self)
		for k,v in pairs(self.triggerBuffInfos) do
			return v.buffInfo.buffType
		end
	end
}
---------------------------------------------------
-- 施法传递buff的数据结构 --
---------------------------------------------------

---------------------------------------------------
-- 施法时的外部传入数据 --
---------------------------------------------------
ObjectCastParameterStruct = {
	--[[
	------------ 数值信息 ------------
	@params skillExtra number 施法最终乘法修正值
	@params percent number spine动画传入的分段百分比
	@params triggerData ObjectTriggerParameterStruct 触发信息传参
	------------ 展示信息 ------------
	@params bulletOriPosition cc.p 发射子弹的起点
	@params shouldShakeWorld bool 本次发射的子弹是否需要震屏
	@params needHighlight bool 是否需要高亮
	--]]
	New = function (
			skillExtra, percent, triggerData,
			bulletOriPosition, shouldShakeWorld, needHighlight
		)
		local this = NewStruct(ObjectCastParameterStruct, BaseStruct)

		--[[---------- 初始化数据结构 ------------
		this.skillExtra = 1 						-- 施法最终乘法修正值
		this.percent = 1 							-- spine动画传入的分段百分比
		this.triggerData = nil 						-- 触发传参
		this.bulletOriPosition = cc.p(0, 0) 		-- 发射子弹的起点
		this.shouldShakeWorld = false 				-- 本次发射的子弹是否需要震屏
		this.needHighlight = false 					-- 是否需要高亮
		------------ 初始化数据结构 ----------]]--

		this:Init(
			skillExtra, percent, triggerData,
			bulletOriPosition, shouldShakeWorld, needHighlight
		)

		return this
	end,
	Init = function (self,
			skillExtra, percent, triggerData,
			bulletOriPosition, shouldShakeWorld, needHighlight
		)

		------------ 数值信息 ------------
		self.skillExtra = skillExtra or 1
		self.percent = percent or 1
		self.triggerData = triggerData
		------------ 展示信息 ------------
		self.bulletOriPosition = bulletOriPosition or cc.p(0, 0)
		self.shouldShakeWorld = shouldShakeWorld or false
		self.needHighlight = needHighlight or false

	end
}
---------------------------------------------------
-- 施法时的外部传入数据 --
---------------------------------------------------

---------------------------------------------------
-- 驱动器与容器传递的转阶段数据结构 --
---------------------------------------------------
ObjectPhaseSturct = {
	--[[
	@params objTag int 战斗物体tag
	@params phaseId int 转阶段配表id 
	@params index int 驱动器结构中转阶段数据的idx
	@params isDieTrigger bool 是否是死亡触发的阶段转换
	@params delayTime number 触发延迟时间
	--]]
	New = function (
			objTag, phaseId, index, isDieTrigger, delayTime
		)
		local this = NewStruct(ObjectPhaseSturct, BaseStruct)

		--[[---------- 初始化数据结构 ------------
		this.objTag = 0 						-- 触发转阶段的战斗物体tag
		this.phaseId = 0 						-- 阶段转换id
		this.index = 0 							-- 驱动器结构中转阶段数据的idx
		this.isDieTrigger = false 				-- 是否是死亡触发的阶段转换
		------------ 初始化数据结构 ----------]]--

		this:Init(
			objTag, phaseId, index, isDieTrigger, delayTime
		)

		return this
	end,
	Init = function (self,
			objTag, phaseId, index, isDieTrigger, delayTime
		)
		self.objTag = objTag
		self.phaseId = phaseId
		self.index = index
		self.isDieTrigger = isDieTrigger
		self.delayTime = delayTime
	end
}
---------------------------------------------------
-- 驱动器与容器传递的转阶段数据结构 --
---------------------------------------------------

---------------------------------------------------
-- 影响伤害的外部参数 --
---------------------------------------------------
ObjectExternalDamageParameterStruct = {
	--[[
	@params isCritical bool 是否暴击
	@params ultimateDamage number 最终伤害
	@params objppAttacker table 攻击者属性系数集 key -> ObjPP
	@params objppTarget table 被攻击者属性系数集 key -> ObjPP
	--]]
	New = function (isCritical, ultimateDamage, objppAttacker, objppTarget)
		local this = NewStruct(ObjectExternalDamageParameterStruct, BaseStruct)

		--[[---------- 初始化数据结构 ------------
		this.isCritical = false 				-- 是否暴击
		this.ultimateDamage = 0 				-- 最终伤害
		this.objppAttacker = {} 				-- 攻击者属性系数集
		this.objppTarget = {} 					-- 被攻击者属性系数集
		------------ 初始化数据结构 ----------]]--

		this:Init(isCritical, ultimateDamage, objppAttacker, objppTarget)

		return this
	end,
	Init = function (self, isCritical, ultimateDamage, objppAttacker, objppTarget)
		self.isCritical = isCritical or false
		self.ultimateDamage = ultimateDamage or 0
		self.objppAttacker = objppAttacker or {}
		self.objppTarget = objppTarget or {}
	end
}
---------------------------------------------------
-- 影响伤害的外部参数 --
---------------------------------------------------

---------------------------------------------------
-- 构造一个全局buff需要的数据结构 --
---------------------------------------------------
GlobalBuffConstructStruct = {
	--[[
	@params skillId int 技能id
	@params value list 效果信息
	@params time number 效果时间
	@params btype ConfigGlobalBuffType buff类型
	@params casterTag int 施法者tag
	--]]
	New = function (skillId, value, time, btype, casterTag)
		local this = NewStruct(GlobalBuffConstructStruct, BaseStruct)

		--[[---------- 初始化数据结构 ------------
		this.skillId = 0 						-- 技能id
		this.value = {} 		 				-- 技能效果值
		this.time = 0 							-- 效果时间
		this.btype = ConfigGlobalBuffType.BASE 	-- buff类型
		this.casterTag = nil 					-- 施法者tag
		------------ 初始化数据结构 ----------]]--

		this:Init(skillId, value, time, btype, casterTag)

		return this
	end,
	Init = function (self,
			skillId, value, time, btype, casterTag
		)

		self.skillId = skillId
		self.value = value
		self.time = time
		self.btype = btype
		self.casterTag = casterTag
		
	end
}
---------------------------------------------------
-- 构造一个全局buff需要的数据结构 --
---------------------------------------------------

---------------------------------------------------
-- 触发器构造数据 --
---------------------------------------------------
ObjectTriggerConstructorStruct = {
	--[[
	@params tag int 触发器tag
	@params triggerType ConfigObjectTriggerActionType 触发器类型
	@params triggerCallback function 触发后调用的函数
	--]]
	New = function (tag, triggerType, triggerCallback)
		local this = NewStruct(ObjectTriggerConstructorStruct, BaseStruct)

		--[[---------- 初始化数据结构 ------------
		this.tag = 0 							-- 触发器tag
		this.triggerType = ConfigObjectTriggerActionType.BASE -- 触发器类型
		this.triggerCallback = nil 				-- 触发后调用的函数
		------------ 初始化数据结构 ----------]]--

		this:Init(tag, triggerType, triggerCallback)

		return this
	end,
	Init = function (self,
			tag, triggerType, triggerCallback
		)

		self.tag = tag
		self.triggerType = triggerType
		self.triggerCallback = triggerCallback

	end
}
---------------------------------------------------
-- 触发器构造数据 --
---------------------------------------------------

---------------------------------------------------
-- 触发器传参数据 --
---------------------------------------------------
ObjectTriggerParameterStruct = {
	--[[
	@params attackerTag int 发起本次触发的攻击者tag
	--]]
	New = function (attackerTag)
		local this = NewStruct(ObjectTriggerParameterStruct, BaseStruct)

		--[[---------- 初始化数据结构 ------------
		this.attackerTag = nil 					-- 触发器tag
		------------ 初始化数据结构 ----------]]--

		this:Init(attackerTag)

		return this
	end,
	Init = function (self,
			attackerTag
		)

		self.attackerTag = attackerTag

	end
}
---------------------------------------------------
-- 触发器传参数据 --
---------------------------------------------------

---------------------------------------------------
-- 击杀单位传递的数据结构 --
---------------------------------------------------
SlayObjectStruct = {
	--[[
	@params targetTag int 被杀死的物体tag
	@params damageData ObjectDamageStruct 致死的伤害信息
	@params overflowDamage number 击杀溢出的伤害
	--]]
	New = function (targetTag, damageData, overflowDamage)
		local this = NewStruct(SlayObjectStruct, BaseStruct)

		--[[---------- 初始化数据结构 ------------
		this.targetTag = nil 					-- 被击杀的单位tag
		this.damageData = nil 					-- 击杀时受到的伤害信息
		this.overflowDamage = nil 				-- 击杀溢出的伤害
		------------ 初始化数据结构 ----------]]--

		this:Init(targetTag, damageData, overflowDamage)

		return this
	end,
	Init = function (self,
			targetTag, damageData, overflowDamage
		)

		self.targetTag = targetTag
		self.damageData = damageData
		self.overflowDamage = overflowDamage

	end
}
---------------------------------------------------
-- 击杀单位传递的数据结构 --
---------------------------------------------------

---------------------------------------------------
-- 单条伤害记录数据结构 --
---------------------------------------------------
ObjectBattleSturct = {
	--[[
	@params attackerTag int 攻击者tag
	@params attackerDeltaHp number 攻击者变化的hp
	@params actionType BDDamageType 伤害类型
	@params skillId int 技能id
	@params defenderInfo table{
		defenderTag int 受攻击者tag
		defenderDeltaHp number 受攻击者变化的hp
	}
	--]]
	New = function (
			attackerTag, attackerDeltaHp,
			actionType, skillId,
			defenderInfo
		)
		local this = NewStruct(ObjectBattleSturct, BaseStruct)

		--[[---------- 初始化数据结构 ------------
		this.attackerTag = 0 					-- 攻击者tag
		this.attackerDeltaHp = 0 				-- 攻击者变化的hp
		this.actionType = BDDamageType.N_ATTACK -- 伤害类型
		this.skillId = 0 						-- 技能id
		this.defenderInfo = {} 					-- 被攻击者信息
		------------ 初始化数据结构 ----------]]--

		this:Init(
			attackerTag, attackerDeltaHp,
			actionType, skillId,
			defenderInfo
		)

		return this
	end,
	Init = function (self,
			attackerTag, attackerDeltaHp,
			actionType, skillId,
			defenderInfo
		)

		self.attackerTag = attackerTag
		self.attackerDeltaHp = attackerDeltaHp
		self.actionType = actionType
		self.skillId = skillId
		self.defenderInfo = defenderInfo
	end
}
---------------------------------------------------
-- 单条伤害记录数据结构 --
---------------------------------------------------

---------------------------------------------------
-- 状态通信数据结构 --
---------------------------------------------------
ObjectFSMStruct = {
	--[[
	@params state BattleObjectFSMState 状态
	@params params 附加参数
	--]]
	New = function (state, params)
		local this = NewStruct(ObjectFSMStruct, BaseStruct)

		--[[---------- 初始化数据结构 ------------
		this.state = state 						-- 状态
		this.aTargetTag = nil 					-- 攻击对象tag
		this.castSkillId = nil 					-- 施法技能id
		------------ 初始化数据结构 ----------]]--

		this:Init(state, params)

		return this
	end,
	Init = function (self, state, params)
		self.state = state

		if nil ~= params then
			self.aTargetTag = params.aTargetTag
			self.castSkillId = params.castSkillId
		end
	end,
	GetState = function (self)
		return self.state
	end
}
---------------------------------------------------
-- 状态通信数据结构 --
---------------------------------------------------

---------------------------------------------------
-- 构造一个战斗物体展示层模型需要的数据结构 --
---------------------------------------------------
ObjectViewModelConstructorStruct = {
	--[[
	@params tag int 逻辑层tag
	@params avatarScale number 缩放
	@params spineData ObjectSpineDataStruct spine信息
	--]]
	New = function (tag, avatarScale, spineData)
		local this = NewStruct(ObjectViewModelConstructorStruct, BaseStruct)

		--[[---------- 初始化数据结构 ------------
		this.tag = nil 							-- 逻辑层的tag
		this.avatarScale = nil 					-- 卡牌avatar缩放比
		this.spineData = nil 					-- spine信息
		------------ 初始化数据结构 ----------]]--

		this:Init(tag, avatarScale, spineData)

		return this
	end,
	--[[
	@params tag int 逻辑层tag
	@params avatarScale number 缩放
	@params spineData ObjectSpineDataStruct spine信息
	--]]
	Init = function (self,
			tag, avatarScale, spineData
		)

		self.tag = tag
		self.avatarScale = avatarScale
		self.spineData = spineData

	end
}
---------------------------------------------------
-- 构造一个战斗物体展示层模型需要的数据结构 --
---------------------------------------------------

---------------------------------------------------
-- 保存spine动画信息的数据结构 --
---------------------------------------------------
ObjectSpineDataStruct = {
	--[[
	@params spineId string spineid
	@params spineName string spine的名字
	@params spineCreateScale number spine创建时的缩放
	@params spineExportScale number spine导出时的缩放
	@params staticViewBox cc.rect 静态的ui框
	@params staticCollisionBox cc.rect 静态的碰撞框
	@params animationsData map<animationName string, animationData ObjectSpineAnimationDataStruct> 动画的信息
	--]]
	New = function (
			spineId, spineName,
			spineCreateScale, spineExportScale,
			staticViewBox, staticCollisionBox,
			animationsData
		)
		local this = NewStruct(ObjectSpineDataStruct, BaseStruct)

		--[[---------- 初始化数据结构 ------------
		this.spineId = nil 						-- spineid
		this.spineName = nil 					-- spine的名字
		this.spineCreateScale = nil 			-- spine创建时的缩放
		this.spineExportScale = nil 			-- spine导出时的缩放
		this.staticViewBox = nil 				-- 静态的ui框
		this.staticCollisionBox = nil 			-- 静态的碰撞框
		this.animationsData = nil 				-- 动画的信息
		------------ 初始化数据结构 ----------]]--

		this:Init(
			spineId, spineName,
			spineCreateScale, spineExportScale,
			staticViewBox, staticCollisionBox,
			animationsData
		)

		return this
	end,
	Init = function (self,
			spineId, spineName,
			spineCreateScale, spineExportScale,
			staticViewBox, staticCollisionBox,
			animationsData
		)

		-- /***********************************************************************************************************************************\
		--  * 1 borderBox 例如 viewBox borderBox 等 spine文件中导出的信息是spine编辑器中1:1的数据 实际获取时需要计算创建或加载时传入的缩放比和cocos2dx的
		--	*   缩放比
		-- \***********************************************************************************************************************************/

		self.spineId = spineId
		self.spineName = spineName
		self.spineCreateScale = spineCreateScale
		self.spineExportScale = spineExportScale
		self.staticViewBox = staticViewBox
		self.staticCollisionBox = staticCollisionBox
		self.animationsData = animationsData
		-- self.animationsData = {
		-- 	-- [animationName] = ObjectSpineAnimationDataStruct.New(),
		-- 	-- [animationName] = ObjectSpineAnimationDataStruct.New(),
		-- 	-- [animationName] = ObjectSpineAnimationDataStruct.New()
		-- }

	end
}
---------------------------------------------------
-- 保存spine动画信息的数据结构 --
---------------------------------------------------

---------------------------------------------------
-- 保存spine动画中动作信息的数据结构 --
---------------------------------------------------
ObjectSpineAnimationDataStruct = {
	--[[
	@params animationName string spine动画名字
	@params animationDuration number spine动画的时间
	@params animationEvents list spine动画的事件
	--]]
	New = function (animationName, animationDuration, animationEvents)
		local this = NewStruct(ObjectSpineAnimationDataStruct, BaseStruct)

		--[[---------- 初始化数据结构 ------------
		this.animationName = nil 				-- 动画名字
		this.animationDuration = nil 			-- 动画时间
		this.animationEvents = nil 				-- 动画事件
		------------ 初始化数据结构 ----------]]--

		this:Init(animationName, animationDuration, animationEvents)

		return this
	end,
	Init = function (self,
			animationName, animationDuration, animationEvents
		)
		self.animationName = animationName
		self.animationDuration = animationDuration
		self.animationEvents = animationEvents
		-- TODO --
		-- 兼容
		self.duration = self.animationDuration
		-- TODO --
		-- self.animtionEvents = {
		-- 	-- [eventName] = {
		-- 	-- 	{time = 0, intValue = 20, floatValue = 20, stringValue = nil},
		-- 	-- 	{time = 0, intValue = 20, floatValue = 20, stringValue = nil},
		-- 	-- 	{time = 0, intValue = 20, floatValue = 20, stringValue = nil},
		-- 	-- 	{time = 0, intValue = 20, floatValue = 20, stringValue = nil}
		-- 	-- }
		-- }
	end
}
---------------------------------------------------
-- 保存spine动画中动作信息的数据结构 --
---------------------------------------------------

---------------------------------------------------
-- 创建spine动作需要的数据结构 --
---------------------------------------------------
RunSpineAnimationStruct = {
	--[[
	@params animationName string spine动画名称
	@params loop bool 是否循环该动画
	@params trackIndex int 动画轨道序号
	--]]
	New = function (animationName, loop, trackIndex)
		local this = NewStruct(RunSpineAnimationStruct, BaseStruct)

		--[[---------- 初始化数据结构 ------------
		this.animationName = nil 			-- 卡牌id
		this.loop = nil 						-- 卡牌皮肤id
		this.trackIndex = nil 					-- 逻辑层的tag
		------------ 初始化数据结构 ----------]]--

		this:Init(animationName, loop, trackIndex)

		return this
	end,
	Init = function (self,
			animationName, loop, trackIndex
		)

		self.animationName = animationName
		self.loop = loop
		self.trackIndex = trackIndex or 1

	end
}
---------------------------------------------------
-- 创建spine动作需要的数据结构 --
---------------------------------------------------
