-- 通用构造函数
function NewStruct(class, super, ...)
	local this = (super and super.New(...) or {})
	setmetatable(class, {__index = super})
	setmetatable(this, {__index = class})
	return this
end

---------------------------------------------------
-- 基础数据结构 --
---------------------------------------------------
BaseStruct = {
	New = function ( ... )
		local this = NewStruct(BaseStruct)
		return this
	end,
	Init = function (self, ...)

	end,
	ToString = function (self)
		return ID(self)
	end,
	SerializeByJson = function (_json_)

	end,
	SerializeByTable = function (_table_)

	end,
	Clone = function (self)

	end
}
---------------------------------------------------
-- 基础数据结构 --
---------------------------------------------------

---------------------------------------------------
-- 技能特效配表转换后的数据结构 -- tips -1 代表攻击
---------------------------------------------------
SkillSpineEffectStruct = {
	--[[
	@params skillId int 技能id
	@params bulletType ConfigEffectBulletType 子弹类型
	@params causeType ConfigEffectCauseType 作用类型
	@params actionName string 技能做的动作名称
	@params effectId int 特效id
	@params effectActionName string 特效做的动作名称
	@params effectZOrder int 特效的修正zorder
	@params effectScale number 特效的缩放
	@params effectPos cc.p 特效的修正相对坐标
	@params hurtEffectData map<_, HurtEffectStruct> 击中后的爆点信息
	@params attachEffectData map<_, AttachEffectStruct> 击中后续的附加效果信息
	@params actionSE string 卡牌释放技能时释放的音效
	@params actionVoice string 做该动作时的语音
	@params actionCauseSE string 动作作用时的音效
	--]]
	New = function (
			skillId, bulletType, causeType, actionName,
			effectId, effectActionName, effectZOrder, effectScale, effectPos,
			hurtEffectData, attachEffectData,
			actionSE, actionVoice, actionCauseSE
		)
		local this = NewStruct(SkillSpineEffectStruct, BaseStruct)

		--[[---------- 初始化数据结构 ------------
		this.skillId = nil 									-- 技能id
		this.bulletType = ConfigEffectBulletType.BASE 		-- 该技能发射的子弹类型
		this.causeType = ConfigEffectCauseType.BASE 		-- 该技能发射子弹的效果类型
		this.actionName = '' 								-- 该技能做的spine动作
		this.effectId = nil 								-- 特效id
		this.effectActionName = nil 						-- 特效的动作名称
		this.effectZOrder = 0 								-- 该技能发射的子弹zorder
		this.effectScale = 1 								-- 该技能发射的子弹缩放比
		this.effectPos = cc.p(0.5, 0) 					-- 该技能发射特效的坐标修正
		this.hurtEffectData = {} 							-- 该技能击中后的爆点信息
		this.attachEffectData = {} 							-- 该技能击中后续的附加效果信息
		this.actionSE = nil 								-- 卡牌释放技能时释放的音效
		this.actionVoice = nil 								-- 卡牌做该动作时的语音
		this.actionCauseSE = nil 							-- 动作作用时的音效
		------------ 初始化数据结构 ----------]]--

		this:Init(
			skillId, bulletType, causeType, actionName,
			effectId, effectActionName, effectZOrder, effectScale, effectPos,
			hurtEffectData, attachEffectData,
			actionSE, actionVoice, actionCauseSE
		)
		return this
	end,
	Init = function (self,
			skillId, bulletType, causeType, actionName,
			effectId, effectActionName, effectZOrder, effectScale, effectPos,
			hurtEffectData, attachEffectData,
			actionSE, actionVoice, actionCauseSE
		)
		
		self.skillId = skillId
		self.bulletType = bulletType or ConfigEffectBulletType.BASE
		self.causeType = causeType or ConfigEffectCauseType.BASE
		self.actionName = actionName

		self.effectId = effectId
		self.effectActionName = effectActionName
		self.effectZOrder = effectZOrder
		self.effectScale = effectScale
		self.effectPos = effectPos

		self.hurtEffectData = hurtEffectData
		self.attachEffectData = attachEffectData

		self.actionSE = actionSE
		self.actionVoice = actionVoice
		self.actionCauseSE = actionCauseSE

	end
}
---------------------------------------------------
-- 技能特效配表转换后的数据结构 --
---------------------------------------------------

---------------------------------------------------
-- 播放一次被击特效需要的数据 --
---------------------------------------------------
HurtEffectStruct = {
	--[[
	@params effectId int 特效id
	@params effectPos cc.p 修正的相对坐标
	@params effectZOrder int 修正的相对zorder
	@params effectSoundEffectId string 播放特效同时播放的音效id
	--]]
	New = function (effectId, effectPos, effectZOrder, effectSoundEffectId)
		local this = NewStruct(HurtEffectStruct, BaseStruct)

		--[[---------- 初始化数据结构 ------------
		this.effectId = nil 					-- 特效id
		this.effectPos = nil 					-- 修正的相对坐标
		this.effectZOrder = 0 					-- 修正的相对zorder
		this.effectSoundEffectId = nil 			-- 播放特效同时播放的音效id
		------------ 初始化数据结构 ----------]]--

		this:Init(effectId, effectPos, effectZOrder, effectSoundEffectId)

		return this
	end,
	Init = function (self, effectId, effectPos, effectZOrder, effectSoundEffectId)

		self.effectId = effectId
		self.effectPos = effectPos
		self.effectZOrder = effectZOrder
		self.effectSoundEffectId = effectSoundEffectId

	end
}
---------------------------------------------------
-- 播放一次被击特效需要的数据 --
---------------------------------------------------

---------------------------------------------------
-- 播放一次附加特效需要的数据 --
---------------------------------------------------
AttachEffectStruct = HurtEffectStruct
---------------------------------------------------
-- 播放一次附加特效需要的数据 --
---------------------------------------------------

---------------------------------------------------
-- 传染技能时传递的数据结构 --
---------------------------------------------------
InfectTransmitStruct = {
	--[[
	@params skillId int 传染技能id
	@params level int 传染技能等级
	@params isEnemy bool 是否敌方技能
	@params infectBuffInfo table 传染的buff信息 对传染源造成的buff信息
	@params infectTime number 传染的时间间隔
	@params infectSeekRule SeekRuleStruct 传染的索敌规则
	@params casterTag int 源施法者tag
	@params infectSourceTag int 传染源objtag
	@params hurtEffectData table 爆点特效信息
	@params attachEffectData table 附加特效信息
	--]]
	New = function (
			skillId, level, isEnemy, infectBuffInfo, infectTime, infectSeekRule,
			casterTag, infectSourceTag,
			hurtEffectData, attachEffectData
		)
		local this = NewStruct(InfectTransmitStruct, BaseStruct)

		--[[---------- 初始化数据结构 ------------
		this.skillId = 0 						-- 传染技能id
		this.level = 1 							-- 技能等级
		this.isEnemy = true 					-- 是否敌方技能
		this.infectBuffInfo = {} 				-- 传染的buff信息 对传染源造成的buff信息
		this.infectTime = 0 					-- 传染的时间间隔
		this.infectSeekRule = nil 				-- 传染的索敌规则
		this.casterTag = 0						-- 源施法者 tag
		this.infectSourceTag = 0 				-- 传染者tag
		this.hurtEffectData = {} 				-- 爆点特效信息
		this.attachEffectData = {} 				-- 附加特效信息
		------------ 初始化数据结构 ----------]]--

		this:Init(
			skillId, level, isEnemy, infectBuffInfo, infectTime, infectSeekRule,
			casterTag, infectSourceTag,
			hurtEffectData, attachEffectData
		)
		return this
	end,
	Init = function (self,
			skillId, level, isEnemy, infectBuffInfo, infectTime, infectSeekRule,
			casterTag, infectSourceTag,
			hurtEffectData, attachEffectData
		)

		self.skillId = skillId
		self.level = level
		self.isEnemy = isEnemy
		self.infectBuffInfo = infectBuffInfo
		self.infectTime = infectTime
		self.infectSeekRule = infectSeekRule
		self.casterTag = casterTag
		self.infectSourceTag = infectSourceTag
		self.hurtEffectData = hurtEffectData or {}
		self.attachEffectData = attachEffectData or {}

	end,
	GetSkillId = function (self)
		return self.skillId
	end
}
---------------------------------------------------
-- 传染技能时传递的数据结构 --
---------------------------------------------------

---------------------------------------------------
-- 配表阶段转换解释结构 --
---------------------------------------------------
PhaseChangeSturct = {
	--[[
	@params phaseChangeConf table 原始阶段转换配表内容
	--]]
	New = function (phaseChangeConf)
		local this = NewStruct(PhaseChangeSturct, BaseStruct)

		--[[---------- 初始化数据结构 ------------
		this.phaseId = 0 						-- 转阶段id
		this.phaseTriggerNpcId = 0 				-- 触发转阶段的npc id
		this.phaseTriggerType = 0 				-- 转阶段的触发类型
		this.phaseTriggerValue = nil 			-- 转阶段的触发数值 
		this.phaseType = 0 						-- 转阶段内容的类型
		this.phaseData = {} 					-- 转阶段时的触发内容
		this.dialogueData = {
			{dialogueId = 0, dialogueContent = ''} -- 对话内容
		}
		------------ 初始化数据结构 ----------]]--

		this:Init(phaseChangeConf)
		
		return this
	end,
	Init = function (self, phaseChangeConf)

		self.phaseId = phaseChangeConf.id
		self.dialogueData = {}

		------------ 触发条件信息 ------------
		self.phaseTriggerType = checkint(phaseChangeConf.triggerCondition[1] or ConfigPhaseTriggerType.BASE)
		self.phaseTriggerNpcId = nil
		self.phaseTriggerValue = nil
		self.phaseTriggerDelayTime = 0
		self.phaseTriggerNpcCampType = ConfigCampType.ENEMY

		
		if ConfigPhaseTriggerType.LOST_HP == self.phaseTriggerType then

			------------ 触发类型 损失一定的生命值 ------------
			self.phaseTriggerNpcId = checkint(phaseChangeConf.triggerCondition[2])
			self.phaseTriggerValue = checknumber(phaseChangeConf.triggerCondition[3])
			self.phaseTriggerNpcCampType = checkint(phaseChangeConf.triggerCondition[4] or ConfigCampType.ENEMY)
			self.phaseTriggerDelayTime = checknumber(phaseChangeConf.triggerCondition[5])
			------------ 触发类型 损失一定的生命值 ------------

		elseif ConfigPhaseTriggerType.APPEAR_TIME == self.phaseTriggerType then

			------------ 触发类型 怪物出现某时间后 ------------
			self.phaseTriggerNpcId = checkint(phaseChangeConf.triggerCondition[2])
			self.phaseTriggerValue = checknumber(phaseChangeConf.triggerCondition[3])
			self.phaseTriggerNpcCampType = checkint(phaseChangeConf.triggerCondition[4] or ConfigCampType.ENEMY)
			self.phaseTriggerDelayTime = checknumber(phaseChangeConf.triggerCondition[5])
			------------ 触发类型 怪物出现某时间后 ------------

		elseif ConfigPhaseTriggerType.OBJ_DIE == self.phaseTriggerType then

			------------ 触发类型 怪物死亡后 ------------
			self.phaseTriggerNpcId = checkint(phaseChangeConf.triggerCondition[2])
			self.phaseTriggerNpcCampType = checkint(phaseChangeConf.triggerCondition[3] or ConfigCampType.ENEMY)
			self.phaseTriggerDelayTime = checknumber(phaseChangeConf.triggerCondition[4])
			------------ 触发类型 怪物死亡后 ------------

		elseif ConfigPhaseTriggerType.OBJ_SKILL == self.phaseTriggerType then

			------------ 触发类型 物体释放技能后 ------------
			self.phaseTriggerNpcId = checkint(phaseChangeConf.triggerCondition[2])
			self.phaseTriggerValue = checkint(phaseChangeConf.triggerCondition[3])
			self.phaseTriggerNpcCampType = checkint(phaseChangeConf.triggerCondition[4] or ConfigCampType.ENEMY)
			self.phaseTriggerDelayTime = checknumber(phaseChangeConf.triggerCondition[5])
			------------ 触发类型 物体释放技能后 ------------

		end
		------------ 触发条件信息 ------------

		------------ 转阶段内容信息 ------------
		self.phaseType = checkint(phaseChangeConf.type)
		self.phaseData = {}

		if ConfigPhaseType.TALK_DEFORM == self.phaseType then
			
			for i, actionConf in ipairs(phaseChangeConf.action) do
				local pdata = {}

				------------ 转阶段内容 喊话并变身 ------------
				pdata.deformFromId = checkint(actionConf[1])
				pdata.deformToId = checkint(actionConf[2])
				pdata.deformType = checkint(actionConf[3])
				pdata.deformValue = checknumber(actionConf[4])

				-- 检查成长 敌友性
				pdata.deformToAttrGrow = 1
				pdata.deformToSkillGrow = 1
				pdata.deformToCampType = ConfigCampType.ENEMY
				if nil ~= phaseChangeConf.npcAttrGrow then
					pdata.deformToAttrGrow = checknumber(phaseChangeConf.npcAttrGrow[i] or 1)
				end
				if nil ~= phaseChangeConf.npcSkillGrow then
					pdata.deformToSkillGrow = checknumber(phaseChangeConf.npcSkillGrow[i] or 1)
				end
				if nil ~= phaseChangeConf.campType then
					pdata.deformToCampType = checkint(phaseChangeConf.campType[i] or ConfigCampType.ENEMY)
				end
				------------ 转阶段内容 喊话并变身 ------------

				table.insert(self.phaseData, pdata)

				------------ 处理喊话内容 ------------
				self.dialogueData[tostring(pdata.deformFromId)] = {
					dialogueId = checkint(phaseChangeConf.dialog[1]),
					dialogueContent = tostring(phaseChangeConf.dialog[2])
				}
				------------ 处理喊话内容 ------------

			end

		elseif ConfigPhaseType.TALK_ESCAPE == self.phaseType then

			for i, actionConf in ipairs(phaseChangeConf.action) do
				local pdata = {}

				------------ 转阶段内容 喊话并逃跑 ------------
				pdata.escapeNpcId = checkint(actionConf[1])
				pdata.escapeType = checkint(actionConf[2])
				if ConfigEscapeType.RETREAT == pdata.escapeType then
					pdata.appearWave = checkint(actionConf[3])
					pdata.appearHpPercent = checknumber(actionConf[4])
				end
				------------ 转阶段内容 喊话并逃跑 ------------

				table.insert(self.phaseData, pdata)

				------------ 处理喊话内容 ------------
				self.dialogueData[tostring(pdata.escapeNpcId)] = {
					dialogueId = checkint(phaseChangeConf.dialog[1]),
					dialogueContent = tostring(phaseChangeConf.dialog[2])
				}
				------------ 处理喊话内容 ------------

			end

		elseif ConfigPhaseType.TALK_ONLY == self.phaseType then

			for i, actionConf in ipairs(phaseChangeConf.action) do
				local pdata = {}

				------------ 转阶段内容 只喊话 ------------
				pdata.dialougeNpcId = checkint(actionConf[1])
				------------ 转阶段内容 只喊话 ------------

				table.insert(self.phaseData, pdata)

				------------ 处理喊话内容 ------------
				self.dialogueData[tostring(pdata.dialougeNpcId)] = {
					dialogueId = checkint(phaseChangeConf.dialog[1]),
					dialogueContent = tostring(phaseChangeConf.dialog[2])
				}
				------------ 处理喊话内容 ------------

			end

		elseif ConfigPhaseType.BECKON_ADDITION_FORCE == self.phaseType or
			ConfigPhaseType.BECKON_ADDITION == self.phaseType then

			for i, actionConf in ipairs(phaseChangeConf.action) do
				local pdata = {}

				------------ 转阶段内容 召唤add ------------
				pdata.beckonNpcId = checkint(actionConf[1])

				-- 检查成长 敌友性
				pdata.beckonNpcAttrGrow = 1
				pdata.beckonNpcSkillGrow = 1
				pdata.beckonNpcCampType = ConfigCampType.ENEMY
				if nil ~= phaseChangeConf.npcAttrGrow then
					pdata.beckonNpcAttrGrow = checknumber(phaseChangeConf.npcAttrGrow[i] or 1)
				end
				if nil ~= phaseChangeConf.npcSkillGrow then
					pdata.beckonNpcSkillGrow = checknumber(phaseChangeConf.npcSkillGrow[i] or 1)
				end
				if nil ~= phaseChangeConf.campType then
					pdata.beckonNpcCampType = checkint(phaseChangeConf.campType[i] or ConfigCampType.ENEMY)
				end
				------------ 转阶段内容 召唤add ------------

				table.insert(self.phaseData, pdata)

			end

			------------ 处理喊话内容 ------------
			self.dialogueData[tostring(self.phaseTriggerNpcId)] = {
				dialogueId = checkint(phaseChangeConf.dialog[1]),
				dialogueContent = tostring(phaseChangeConf.dialog[2])
			}
			------------ 处理喊话内容 ------------

		elseif ConfigPhaseType.BECKON_CUSTOMIZE == self.phaseType then

			for i, actionConf in ipairs(phaseChangeConf.action) do
				local pdata = {
					beckonNpcId = nil,
					beckonAppearPosId = nil,
					beckonTargetPosId = nil,
					beckonAppearActionName = nil,
					beckonNpcAttrGrow = 1,
					beckonNpcSkillGrow = 1,
					beckonNpcCampType = ConfigCampType.ENEMY
				}

				------------ 转阶段内容 召唤add 自定义 ------------
				-- 召唤的小怪id
				pdata.beckonNpcId = checkint(actionConf[1])
				-- 召唤小怪出场的初始位置
				pdata.beckonAppearPosId = checkint(actionConf[2])
				-- 召唤小怪出场的目标位置
				pdata.beckonTargetPosId = checkint(actionConf[3])
				-- 召唤小怪出场的动作
				pdata.beckonAppearActionName = tostring(actionConf[4])

				-- 检查成长 敌友性
				if nil ~= phaseChangeConf.npcAttrGrow then
					pdata.beckonNpcAttrGrow = checknumber(phaseChangeConf.npcAttrGrow[i] or 1)
				end
				if nil ~= phaseChangeConf.npcSkillGrow then
					pdata.beckonNpcSkillGrow = checknumber(phaseChangeConf.npcSkillGrow[i] or 1)
				end
				if nil ~= phaseChangeConf.campType then
					pdata.beckonNpcCampType = checkint(phaseChangeConf.campType[i] or ConfigCampType.ENEMY)
				end
				------------ 转阶段内容 召唤add 自定义 ------------

				table.insert(self.phaseData, pdata)

			end

			------------ 处理喊话内容 ------------
			if 0 < #phaseChangeConf.dialog then
				self.dialogueData[tostring(self.phaseTriggerNpcId)] = {
					dialogueId = checkint(phaseChangeConf.dialog[1]),
					dialogueContent = tostring(phaseChangeConf.dialog[2])
				}
			end
			------------ 处理喊话内容 ------------

		elseif ConfigPhaseType.EXEUNT_CUSTOMIZE == self.phaseType then

			for i, actionConf in ipairs(phaseChangeConf.action) do
				local pdata = {
					npcId = nil,
					npcCampType = nil,
					disappearPosId = nil, -- -1为原地消失
					disappearActionName = nil
				}

				------------ 转阶段内容 怪物退场 ------------
				pdata.npcId = checkint(actionConf[1])
				pdata.npcCampType = checkint(actionConf[2])
				pdata.disappearPosId = checkint(actionConf[3])
				pdata.disappearActionName = tostring(actionConf[4])
				------------ 转阶段内容 怪物退场 ------------

				table.insert(self.phaseData, pdata)

			end

			------------ 处理喊话内容 ------------
			if 0 < #phaseChangeConf.dialog then
				self.dialogueData[tostring(self.phaseTriggerNpcId)] = {
					dialogueId = checkint(phaseChangeConf.dialog[1]),
					dialogueContent = tostring(phaseChangeConf.dialog[2])
				}
			end
			------------ 处理喊话内容 ------------

		elseif ConfigPhaseType.DEFORM_CUSTOMIZE == self.phaseType then

			for i, actionConf in ipairs(phaseChangeConf.action) do
				local pdata = {
					deformFromId = nil,
					deformFromCampType = nil,
					deformFromDisappearActionName = nil,
					deformToDelayTime = nil,
					deformToId = nil,
					deformToAppearActionName = nil,
					deformType = nil,
					deformToAttrGrow = 1,
					deformToSkillGrow = 1,
					deformToCampType = ConfigCampType.ENEMY
				}

				------------ 变身 自定义 ------------
				pdata.deformFromId = checkint(actionConf[1])
				pdata.deformFromCampType = checkint(actionConf[2])
				pdata.deformFromDisappearActionName = tostring(actionConf[3])
				pdata.deformToDelayTime = checknumber(actionConf[4])
				pdata.deformToId = checkint(actionConf[5])
				pdata.deformToOriPosId = checkint(actionConf[6])
				pdata.deformToAppearActionName = tostring(actionConf[7])
				pdata.deformType = checkint(actionConf[8])

				-- 检查成长 敌友性
				if nil ~= phaseChangeConf.npcAttrGrow then
					pdata.deformToAttrGrow = checknumber(phaseChangeConf.npcAttrGrow[i] or 1)
				end
				if nil ~= phaseChangeConf.npcSkillGrow then
					pdata.deformToSkillGrow = checknumber(phaseChangeConf.npcSkillGrow[i] or 1)
				end
				if nil ~= phaseChangeConf.campType then
					pdata.deformToCampType = checkint(phaseChangeConf.campType[i] or ConfigCampType.ENEMY)
				end
				------------ 变身 自定义 ------------

				table.insert(self.phaseData, pdata)

				------------ 处理喊话内容 ------------
				if 0 < #phaseChangeConf.dialog then
					self.dialogueData[tostring(pdata.deformFromId)] = {
						dialogueId = checkint(phaseChangeConf.dialog[1]),
						dialogueContent = tostring(phaseChangeConf.dialog[2])
					}
				end
				------------ 处理喊话内容 ------------

			end

		elseif ConfigPhaseType.PLOT == self.phaseType then

			for i, actionConf in ipairs(phaseChangeConf.action) do
				local pdata = {
					plotId = nil,
					forcePauseGame = true
				}

				------------ 剧情信息 ------------
				-- pdata.forcePauseGame = 1 == checkint(actionConf[1]) and true or false
				pdata.plotId = checkint(actionConf[2])
				------------ 剧情信息 ------------

				table.insert(self.phaseData, pdata)
			end

		else

			BattleUtils.PrintConfigLogicError('phase type ' .. self.phaseType .. ' did not accomplish')

		end
		------------ 转阶段内容信息 ------------

		-- dump(self)
	end
}
---------------------------------------------------
-- 配表阶段转换解释结构 --
---------------------------------------------------

---------------------------------------------------
-- 配表阶段转换内容解释结构 --
---------------------------------------------------
PhaseDataStruct = {
	--[[
	@params phaseType ConfigPhaseType 转阶段内容类型
	@params actionConf table 转阶段内容配表
	--]]
	New = function (phaseType, actionConf)
		local this = NewStruct(PhaseDataStruct, BaseStruct)

		--[[---------- 初始化数据结构 ------------

		------------ 转阶段内容 喊话并变身 ------------
		this.deformFromId = 0 					-- 变身源npc id
		this.deformToId = 0 					-- 变身目标npc id
		this.deformType = ConfigDeformType 		-- 变身类型
		this.deformValue = nil 					-- 变身类型数值
		------------ 转阶段内容 喊话并变身 ------------

		------------ 转阶段内容 喊话并逃跑 ------------
		this.escapeNpcId = 0 					-- 逃跑npc id
		this.escapeType = ConfigEscapeType 		-- 逃跑类型
		this.appearWave = nil 					-- 逃跑后出现的波次
		this.appearHpPercent = nil 				-- 逃跑后出现的血量
		------------ 转阶段内容 喊话并逃跑 ------------

		------------ 转阶段内容 只喊话 ------------
		this.dialougeNpcId = 0 					-- 喊话npc id
		------------ 转阶段内容 只喊话 ------------

		------------ 转阶段内容 召唤add ------------
		this.beckonNpcId = 0 					-- 召唤的npc id
		------------ 转阶段内容 召唤add ------------

		------------ 初始化数据结构 ----------]]--

		this:Init(phaseType, actionConf)

		return this
	end,
	Init = function (self, phaseType, actionConf)

		if ConfigPhaseType.TALK_DEFORM == phaseType then

			------------ 转阶段内容 喊话并变身 ------------
			self.deformFromId = checkint(actionConf[1])
			self.deformToId = checkint(actionConf[2])
			self.deformType = checkint(actionConf[3])
			self.deformValue = checknumber(actionConf[4])
			------------ 转阶段内容 喊话并变身 ------------

		elseif ConfigPhaseType.TALK_ESCAPE == phaseType then

			------------ 转阶段内容 喊话并逃跑 ------------
			self.escapeNpcId = checkint(actionConf[1])
			self.escapeType = checkint(actionConf[2])
			if ConfigEscapeType.RETREAT == self.escapeType then
				self.appearWave = checkint(actionConf[3])
				self.appearHp = checknumber(actionConf[4])
			end
			------------ 转阶段内容 喊话并逃跑 ------------

		elseif ConfigPhaseType.TALK_ONLY == phaseType then

			------------ 转阶段内容 只喊话 ------------
			self.dialougeNpcId = checkint(actionConf[1])
			------------ 转阶段内容 只喊话 ------------

		elseif ConfigPhaseType.BECKON_ADDITION_FORCE == phaseType or
			ConfigPhaseType.BECKON_ADDITION == self.phaseType then

			------------ 转阶段内容 召唤add ------------
			self.beckonNpcId = checkint(actionConf[1])
			------------ 转阶段内容 召唤add ------------

		else

			BattleUtils.PrintConfigLogicError('phase type ' .. phaseType .. ' did not accomplish')

		end

	end
}
---------------------------------------------------
-- 配表阶段转换内容解释结构 --
---------------------------------------------------

---------------------------------------------------
-- 创建准备战斗的数据结构 --
---------------------------------------------------
BattleReadyConstructorStruct = {
	--[[
	@params battleType int 战斗类型 1 通用 只有队伍信息和主角技选择 2 int 主线战斗 有关卡信息和主角技选择 3 通用 主角技都不显示
	@params teamIdx int 默认的编队序号
	@params equipedMagicFoodId int 默认携带的魔法诱饵
	@params stageId int 关卡id
	@params questBattleType QuestBattleType 战斗类型
	@params star int 星级
	@params enterBattleRequestCommand string 进入战斗的命令
	@params enterBattleRequestData table 请求的参数集
	@params enterBattleResponseSignal string 进入战斗命令回调信号
	@params exitBattleRequestCommand string 战斗结束结算命令
	@params exitBattleRequestData table 请求的参数集
	@params exitBattleResponseSignal string 战斗结束命令回调信号
	@params fromMediatorName string 从哪个mediator来
	@params toMediatorName string 回哪个mediator
	--]]
	New = function (
			battleType, teamIdx, equipedMagicFoodId, stageId, questBattleType, star,
			enterBattleRequestCommand, enterBattleRequestData, enterBattleResponseSignal,
			exitBattleRequestCommand, exitBattleRequestData, exitBattleResponseSignal,
			fromMediatorName, toMediatorName
		)

		local this = NewStruct(BattleReadyConstructorStruct, BaseStruct)

		--[[---------- 初始化数据结构 ------------

		------------ ui 信息 ------------
		this.battleType = 1 					-- 战斗类型 1 通用战斗 只有主角技和队伍信息 2 地图关卡战斗 存在堕神诱饵等等
		this.teamIdx = 1 						-- 默认的编队序号
		this.equipedMagicFoodId = nil 			-- 默认携带的魔法诱饵id
		this.stageId = nil 						-- 当前关卡id
		this.questBattleType = QuestBattleType.BASE -- 战斗类型
		this.star = nil 						-- 当前关卡获得的星级
		------------ ui 信息 ------------

		------------ 服务器请求信息 ------------
		this.enterBattleRequestCommand = '' 	-- 进入战斗命令
		this.enterBattleRequestData = {}		-- 进入战斗向服务器发送的请求信息
		this.enterBattleResponseSignal = '' 	-- 进入战斗命令回调信号
		this.exitBattleRequestCommand = '' 		-- 战斗结束结算命令
		this.exitBattleRequestData = {} 		-- 战斗结束结算向服务器发送的请求信息
		this.exitBattleResponseSignal = '' 		-- 战斗结束命令回调信号
		------------ 服务器请求信息 ------------

		------------ 跳转数据 ------------
		this.fromMediatorName = '' 				-- 从哪个mediator来
		this.toMediatorName = '' 				-- 回哪个mediator
		------------ 跳转数据 ------------

		------------ 初始化数据结构 ----------]]--

		this:Init(
			battleType, teamIdx, equipedMagicFoodId, stageId, questBattleType, star,
			enterBattleRequestCommand, enterBattleRequestData, enterBattleResponseSignal,
			exitBattleRequestCommand, exitBattleRequestData, exitBattleResponseSignal,
			fromMediatorName, toMediatorName
		)

		return this
	end,
	Init = function (self,
			battleType, teamIdx, equipedMagicFoodId, stageId, questBattleType, star,
			enterBattleRequestCommand, enterBattleRequestData, enterBattleResponseSignal,
			exitBattleRequestCommand, exitBattleRequestData, exitBattleResponseSignal,
			fromMediatorName, toMediatorName
		)

		------------ ui 信息 ------------
		self.battleType = battleType
		self.teamIdx = teamIdx
		self.equipedMagicFoodId = equipedMagicFoodId
		self.stageId = stageId
		self.questBattleType = questBattleType
		self.star = star
		------------ ui 信息 ------------

		------------ 服务器请求信息 ------------
		self.enterBattleRequestCommand = enterBattleRequestCommand
		self.enterBattleRequestData = enterBattleRequestData
		self.enterBattleResponseSignal = enterBattleResponseSignal
		self.exitBattleRequestCommand = exitBattleRequestCommand
		self.exitBattleRequestData = exitBattleRequestData
		self.exitBattleResponseSignal = exitBattleResponseSignal
		------------ 服务器请求信息 ------------

		------------ 跳转数据 ------------
		self.fromMediatorName = fromMediatorName
		self.toMediatorName = toMediatorName
		------------ 跳转数据 ------------

	end
}
---------------------------------------------------
-- 创建准备战斗的数据结构 --
---------------------------------------------------

---------------------------------------------------
-- 转换战斗通用的阵容信息 --
---------------------------------------------------
FormationStruct = {
	--[[
	@params teamId int 队伍编号
	@params members table 成员
	@params playerSkillInfo table 主角技信息
	@params propertyAttr ObjectPropertyFixedAttrStruct 外部属性修正乘法系数
	--]]
	New = function (
			teamId, members, playerSkillInfo,
			propertyAttr
		)

		local this = NewStruct(FormationStruct, BaseStruct)

		--[[---------- 初始化数据结构 ------------
		this.teamId = 1 						-- 队伍编号
		this.members = {} 						-- 成员
		this.playerSkillInfo = {} 				-- 主角技信息
		this.propertyAttr = nil 				-- 外部属性修正乘法系数
		------------ 初始化数据结构 ----------]]--

		this:Init(
			teamId, members, playerSkillInfo,
			propertyAttr
		)

		return this
	end,
	Init = function (self,
			teamId, members, playerSkillInfo,
			propertyAttr
		)

		self.teamId = teamId
		self.members = members
		self.playerSkillInfo = playerSkillInfo
		self.propertyAttr = propertyAttr

	end
}
---------------------------------------------------
-- 转换战斗通用的阵容信息 --
---------------------------------------------------

---------------------------------------------------
-- 物体与物体之间激活的额外能力信息 --
---------------------------------------------------
ObjectAbilityRelationStruct = {
	--[[
	@params essentialCards map<cardId[int],_[bool]> 必要的卡牌id集合
	@params inessentialCards map<cardId[int],_[bool]> 非必要的卡牌id集合
	@params activeCards map<cardId[int],_[bool]> 激活能力的卡牌id集合
	@params activeSkills map<skillId[int],_[bool]> 激活的额外技能id集合
	--]]
	New = function (
			essentialCards, inessentialCards, activeCards,
			activeSkills
		)

		local this = NewStruct(ObjectAbilityRelationStruct, BaseStruct)

		--[[---------- 初始化数据结构 ------------
		this.essentialCards = {}				-- 必要的卡牌id集合
		this.inessentialCards = {}				-- 非必要的卡牌id集合
		this.activeCards = {} 					-- 激活能力的卡牌id集合
		this.activeSkills = {} 					-- 激活的额外技能id集合
		------------ 初始化数据结构 ----------]]--

		this:Init(
			essentialCards, inessentialCards, activeCards,
			activeSkills
		)

		return this
	end,
	Init = function (self,
			essentialCards, inessentialCards, activeCards,
			activeSkills
		)

		self.essentialCards = essentialCards or {}
		self.inessentialCards = inessentialCards or {}
		self.activeCards = activeCards or {}
		self.activeSkills = activeSkills or {}

		-- debug --
		-- self.essentialCards = {
		-- 	['200004'] = true,
		-- 	['200037'] = true
		-- }
		-- self.inessentialCards = {
		-- 	['200001'] = true,
		-- 	['200003'] = true
		-- }
		-- self.activeCards = {
		-- 	['200004'] = true,
		-- 	['200037'] = true,
		-- 	['200002'] = true
		-- }
		-- self.activeSkills = {
		-- 	['24777'] = true
		-- }
		-- debug --

	end,
	AbilityVaild = function (self)
		return not (BattleUtils.IsTableEmpty(self.activeSkills) or BattleUtils.IsTableEmpty(self.activeCards))
	end,
	SerializeByTable = function (_table_)
		if nil == _table_ then return nil end
		
		local struct = ObjectAbilityRelationStruct.New(
			_table_.essentialCards,
			_table_.inessentialCards,
			_table_.activeCards,
			_table_.activeSkills
		)
		return struct
	end
}
---------------------------------------------------
-- 物体与物体之间激活的额外能力信息 --
---------------------------------------------------

---------------------------------------------------
-- 组队副本开始战斗的数据结构 --
---------------------------------------------------
StartRaidBattleStruct = {
	--[[
	@params gameTimeScale number 游戏运行速度缩放
	@params stageId int 关卡id
	@params randomseed number 随机种子
	@params playerCards 玩家信息对应卡牌 
	@params friendFormation FormationStruct 友方队伍信息
	@params enemyFormation FormationStruct 敌方队伍信息
	@params captainId int 队长玩家id
	@params usePlayerSkillPlayerId int 可以使用主角技的玩家id
	@params fromMediatorName string 从哪个mediator来
	@params toMediatorName string 回哪个mediator
	--]]
	New = function (
			gameTimeScale, stageId, randomseed,
			playerCards, friendFormation, enemyFormation,
			captainId, usePlayerSkillPlayerId,
			fromMediatorName, toMediatorName
		)
		local this = NewStruct(StartRaidBattleStruct, BaseStruct)

		--[[---------- 初始化数据结构 ------------

		------------ 游戏基本信息 ------------
		this.gameTimeScale = 1 					-- 游戏运行速度缩放
		this.stageId = nil 						-- 关卡id
		this.randomseed = 0 					-- 随机种子
		------------ 游戏基本信息 ------------

		------------ 阵容信息 ------------
		this.playerCards = {} 					-- 玩家信息对应卡牌
		this.formationData = {
			friend = FormationStruct
			enemy = nil
		} 										-- 阵容信息
		------------ 阵容信息 ------------
	
		------------ id标识信息 ------------
		this.captainId = 0 						-- 队长玩家id
		this.usePlayerSkillPlayerId = 0 		-- 可以使用主角技的玩家id
		------------ id标识信息 ------------

		------------ 跳转数据 ------------
		this.fromMediatorName = '' 				-- 从哪个mediator来
		this.toMediatorName = '' 				-- 回哪个mediator
		------------ 跳转数据 ------------

		------------ 初始化数据结构 ----------]]--

		this:Init(
			gameTimeScale, stageId, randomseed,
			playerCards, friendFormation, enemyFormation,
			captainId, usePlayerSkillPlayerId,
			fromMediatorName, toMediatorName
		)

		return this
	end,
	Init = function (self,
			gameTimeScale, stageId, randomseed,
			playerCards, friendFormation, enemyFormation,
			captainId, usePlayerSkillPlayerId,
			fromMediatorName, toMediatorName
		)

		------------ 游戏基本信息 ------------
		self.gameTimeScale = gameTimeScale
		self.stageId = stageId
		self.randomseed = randomseed
		------------ 游戏基本信息 ------------

		------------ 阵容信息 ------------
		self.playerCards = playerCards or {}
		self.formationData = {
			friend = friendFormation,
			enemy = enemyFormation
		}
		------------ 阵容信息 ------------

		------------ id标识信息 ------------
		self.captainId = captainId
		self.usePlayerSkillPlayerId = usePlayerSkillPlayerId
		------------ id标识信息 ------------

		------------ 跳转数据 ------------
		self.fromMediatorName = fromMediatorName
		self.toMediatorName = toMediatorName
		------------ 跳转数据 ------------

	end
}
---------------------------------------------------
-- 组队副本开始战斗的数据结构 --
---------------------------------------------------

---------------------------------------------------
-- 构造一场战斗需要的数据结构 --
---------------------------------------------------
BattleConstructorStruct = {
	--[[
	------------ 战斗基本配置 ------------
	@params stageId int 关卡id
	@params questBattleType QuestBattleType 战斗类型
	@params randomConfig BattleRandomConfigStruct 战斗随机数配置
	@params gameTimeScale int 游戏运行速度缩放
	@params time int 战斗时间限制 second
	@params totalWave int 总波数
	@params resultType ConfigBattleResultType 结算类型
	@params stageCompleteInfo list(StageCompleteSturct) 过关条件
	@params isCalculator bool 是否是无画面战报生成器
	@params isReplay bool 是否是录像
	------------ 战斗数值配置 ------------
	@params levelRolling bool 是否开启等级碾压
	------------ 战斗环境配置 ------------
	@params weather table 天气
	@params phaseChangeDatas map 阶段转换信息
	@params abilityRelationInfo list<ObjectAbilityRelationStruct>
	@params globalEffects list 全局效果列表
	@params enableConnect bool 己方 连携技可用
	@params autoConnect bool 己方 自动释放连携技
	@params enemyEnableConnect bool 敌方 连携技可用
	@params enemyAutoConnect bool 敌方 自动释放连携技
	------------ 其他信息 ------------
	@params cleanCondition table 特殊条件
	@params canRechallenge bool 是否可以重复挑战
	@params rechallengeTime int 剩余挑战次数
	@params canBuyCheat bool 是否可以买活
	@params buyRevivalTime int 已买活次数
	@params buyRevivalTimeMax int 最大买活次数 
	------------ 战斗场景配置 ------------
	@params backgroundInfo list 背景图信息
	@params hideBattleFunctionModule list<ConfigBattleFunctionModuleType> 隐藏的战斗功能模块界面
	------------ 友方阵容信息 ------------
	@params friendFormation FormationStruct 友方阵容信息
	------------ 敌方阵容信息 ------------
	@params enemyFormation FormationStruct 敌方阵容信息
	------------ 头尾服务器交互命令 ------------
	@params serverCommand BattleNetworkCommandStruct 与服务器交互的命令信息
	------------ 头尾跳转信息 ------------
	@params fromtoData BattleMediatorsConnectStruct 跳转信息
	--]]
	New = function (
			------------ 战斗基本配置 ------------
			stageId, questBattleType, randomConfig, gameTimeScale, time, totalWave, resultType, stageCompleteInfo, isCalculator, isReplay,
			------------ 战斗数值配置 ------------
			levelRolling,
			------------ 战斗环境配置 ------------
			weather, phaseChangeDatas, abilityRelationInfo, globalEffects, enableConnect, autoConnect, enemyEnableConnect, enemyAutoConnect,
			------------ 其他信息 ------------
			cleanCondition, canRechallenge, rechallengeTime, canBuyCheat, buyRevivalTime, buyRevivalTimeMax,
			------------ 战斗场景配置 ------------
			backgroundInfo, hideBattleFunctionModule,
			------------ 友方阵容信息 ------------
			friendFormation,
			------------ 敌方阵容信息 ------------
			enemyFormation,
			------------ 头尾服务器交互命令 ------------
			serverCommand,
			------------ 头尾跳转信息 ------------
			fromtoData
		)

		local this = NewStruct(BattleConstructorStruct, BaseStruct)

		this:Init(
			stageId, questBattleType, randomConfig, gameTimeScale, time, totalWave, resultType, stageCompleteInfo, isCalculator, isReplay,
			levelRolling,
			weather, phaseChangeDatas, abilityRelationInfo, globalEffects, enableConnect, autoConnect, enemyEnableConnect, enemyAutoConnect,
			cleanCondition, canRechallenge, rechallengeTime, canBuyCheat, buyRevivalTime, buyRevivalTimeMax,
			backgroundInfo, hideBattleFunctionModule,
			friendFormation,
			enemyFormation,
			serverCommand,
			fromtoData
		)

		return this
	end,
	Init = function (self,
			stageId, questBattleType, randomConfig, gameTimeScale, time, totalWave, resultType, stageCompleteInfo, isCalculator, isReplay,
			levelRolling,
			weather, phaseChangeDatas, abilityRelationInfo, globalEffects, enableConnect, autoConnect, enemyEnableConnect, enemyAutoConnect,
			cleanCondition, canRechallenge, rechallengeTime, canBuyCheat, buyRevivalTime, buyRevivalTimeMax,
			backgroundInfo, hideBattleFunctionModule,
			friendFormation,
			enemyFormation,
			serverCommand,
			fromtoData
		)

		------------ 战斗基本配置 ------------
		self.stageId = stageId
		self.questBattleType = questBattleType
		self.randomConfig = randomConfig
		self.gameTimeScale = gameTimeScale
		self.time = time
		self.totalWave = totalWave
		self.resultType = resultType
		self.stageCompleteInfo = stageCompleteInfo
		self.isCalculator = (isCalculator == true)
		self.isReplay = (isReplay == true)
		------------ 战斗基本配置 ------------

		------------ 战斗数值配置 ------------
		self.levelRolling = true
		if nil ~= levelRolling then
			self.levelRolling = levelRolling
		end
		------------ 战斗数值配置 ------------

		------------ 战斗环境配置 ------------
		self.weather = weather
		self.phaseChangeDatas = phaseChangeDatas
		self.abilityRelationInfo = abilityRelationInfo
		self.globalEffects = globalEffects
		self.enableConnect = enableConnect
		self.autoConnect = autoConnect
		self.enemyEnableConnect = enemyEnableConnect
		self.enemyAutoConnect = enemyAutoConnect
		------------ 战斗环境配置 ------------

		------------ 其他信息 ------------
		self.cleanCondition = cleanCondition
		self.canRechallenge = canRechallenge
		self.rechallengeTime = rechallengeTime
		self.canBuyCheat = canBuyCheat
		self.buyRevivalTime = buyRevivalTime
		self.buyRevivalTimeMax = buyRevivalTimeMax
		------------ 其他信息 ------------

		------------ 战斗场景配置 ------------
		self.backgroundInfo = backgroundInfo
		self.hideBattleFunctionModule = hideBattleFunctionModule
		------------ 战斗场景配置 ------------

		------------ 友方阵容信息 ------------
		self.friendFormation = friendFormation
		------------ 友方阵容信息 ------------

		------------ 敌方阵容信息 ------------
		self.enemyFormation = enemyFormation
		------------ 敌方阵容信息 ------------

		------------ 头尾服务器交互命令 ------------
		self.serverCommand = serverCommand
		------------ 头尾服务器交互命令 ------------

		------------ 头尾跳转信息 ------------
		self.fromtoData = fromtoData
		------------ 头尾跳转信息 ------------
	end
}
---------------------------------------------------
-- 构造一场战斗需要的数据结构 --
---------------------------------------------------

---------------------------------------------------
-- 战斗随机数配置数据结构 --
---------------------------------------------------
BattleRandomConfigStruct = {
	--[[
	@params randomseed long 随机种子
	@params randomvalues list 伪随机数序列
	@params randomvaluemin int 伪随机数序列最小值
	@params randomvaluemax int 伪随机数序列最大值
	@params randomvalueamount int 伪随机数序列数量
	--]]
	New = function (randomseed, randomvalues, randomvaluemin, randomvaluemax, randomvalueamount)

		local this = NewStruct(BattleRandomConfigStruct, BaseStruct)

		--[[---------- 初始化数据结构 ------------
		this.randomseed = string.reverse(tostring(os.time())) -- 随机种子
		this.randomvalues = {}					-- 伪随机数序列
		this.randomvaluemin = 1 				-- 随机数最小值 闭区间
		this.randomvaluemax = 1000 				-- 随机数最大值 闭区间
		this.randomvalueamount = #this.randomvalues -- 随机数数量
		------------ 初始化数据结构 ----------]]--

		if __THE_WORLD__TOKIYO_TOMARE__ then
			randomseed = '1234567890'
		end

		this:Init(randomseed, randomvalues, randomvaluemin, randomvaluemax, randomvalueamount)

		return this

	end,
	Init = function (self,
			randomseed, randomvalues, randomvaluemin, randomvaluemax, randomvalueamount
		)

		self.randomseed = randomseed or string.reverse(tostring(os.time()))
		self.randomvalues = randomvalues
		self.randomvaluemin = randomvaluemin
		self.randomvaluemax = randomvaluemax
		self.randomvalueamount = randomvalueamount

	end,
	HasRandomvalues = function (self)
		if (nil ~= self.randomvalues) and
			(checkint(self.randomvalueamount) == #self.randomvalues) and
			(0 < (checkint(self.randomvaluemax) - checkint(self.randomvaluemin))) then

			return true

		else

			return false

		end
	end,
	HasRandomseed = function (self)
		return checkint(self.randomseed) ~= 0
	end,
	SerializeByTable = function (_table_)
		if nil == _table_ then return BattleRandomConfigStruct.New() end

		local struct = BattleRandomConfigStruct.New(
			_table_.randomseed,
			_table_.randomvalues,
			_table_.randomvaluemin,
			_table_.randomvaluemax,
			_table_.randomvalueamount
		)
		return struct
	end
}
---------------------------------------------------
-- 战斗随机数配置数据结构 --
---------------------------------------------------

---------------------------------------------------
-- 构造一个 card obj 需要的外部参数 --
---------------------------------------------------
CardObjConstructorStruct = {
	--[[
	------------ 卡牌基本信息 ------------
	@params cardId int 卡牌id
	@params exp int 卡牌经验
	@params level int 卡牌等级
	@params breakLevel int 突破等级
	@params favorExp int 卡牌好感度经验
	@params favorLevel int 好感度等级
	@params vigour int 新鲜度
	------------ 属性参数 ------------
	@params objpattr ObjPFixedAttrStruct 单体外部属性参数
	------------ 战斗信息 ------------
	@params isLeader bool 是否是队长
	@params positionId int 站位id
	@params teamPosition int 在队伍中的位置序号
	@params skillData table 技能信息
	@params talentData ArtifactTalentConstructorStruct 天赋信息
	@params exAbilityData EXAbilityConstructorStruct 卡牌超能力信息
	@params petData PetConstructorStruct 堕神信息
	@params bookData BookConstructorStruct 飨灵收集册信息
	@params catGeneData CatGeneConstructorStruct 装备猫咪基因信息
	------------ 外貌信息 ------------
	@params skinId int 选择的皮肤id
	--]]
	New = function (
			cardId, exp, level, breakLevel, favorExp, favorLevel, vigour,
			objpattr,
			isLeader, positionId, teamPosition, skillData, talentData, exAbilityData, petData, bookData, catGeneData,
			skinId
		)

		local this = NewStruct(CardObjConstructorStruct, BaseStruct)

		--[[---------- 初始化数据结构 ------------
		------------ 卡牌基本信息 ------------
		this.cardId = nil 						-- 卡牌id
		this.exp = 0 							-- 卡牌经验值
		this.level = 1 			 				-- 卡牌等级
		this.breakLevel = 0 					-- 卡牌突破等级
		this.favorExp = 0 						-- 好感度经验值
		this.favorLevel = 1 	 				-- 好感度等级
		this.vigour = 0							-- 卡牌新鲜度
		------------ 属性参数 ------------
		this.objpattr = ObjPFixedAttrStruct.New() -- 单体外部属性参数
		------------ 战斗信息 ------------
		this.isLeader = false 					-- 是否是队长
		this.positionId = nil 					-- 外部的站位id
		this.teamPosition = 1 					-- 队伍中的位置序号
		this.skillData = {} 					-- 技能信息
		this.talentData = nil 					-- 天赋信息
		this.exAbilityData = nil 				-- 卡牌超能力信息
		this.petData = nil 						-- 堕神信息
		------------ 外貌信息 ------------
		this.skinId = nil 						-- 皮肤id
		------------ 初始化数据结构 ----------]]--

		this:Init(
			cardId, exp, level, breakLevel, favorExp, favorLevel, vigour,
			objpattr,
			isLeader, positionId, teamPosition, skillData, talentData, exAbilityData, petData, bookData, catGeneData,
			skinId
		)

		return this
	end,
	Init = function (self, 
			cardId, exp, level, breakLevel, favorExp, favorLevel, vigour,
			objpattr,
			isLeader, positionId, teamPosition, skillData, talentData, exAbilityData, petData, bookData, catGeneData,
			skinId
		)

		------------ 卡牌基本信息 ------------
		self.cardId = cardId
		self.exp = exp
		self.level = level
		self.breakLevel = breakLevel
		self.favorExp = favorExp
		self.favorLevel = favorLevel
		self.vigour = vigour
		------------ 卡牌基本信息 ------------

		------------ 属性参数 ------------
		self.objpattr = objpattr or ObjPFixedAttrStruct.New()
		------------ 属性参数 ------------

		------------ 战斗信息 ------------
		self.isLeader = isLeader
		self.positionId = positionId
		self.teamPosition = teamPosition
		self.skillData = skillData
		self.talentData = talentData
		self.exAbilityData = exAbilityData
		self.petData = petData
		self.bookData = bookData
		self.catGeneData = catGeneData
		------------ 战斗信息 ------------

		------------ 外貌信息 ------------
		self.skinId = skinId
		------------ 外貌信息 ------------

	end,
	GetObjectConfigId = function (self)
		return checkint(self.cardId)
	end
}
---------------------------------------------------
-- 构造一个 card obj 需要的外部参数 --
---------------------------------------------------

---------------------------------------------------
-- 构造一个 monster obj 需要的外部参数 --
---------------------------------------------------
MonsterObjConstructorStruct = {
	--[[
	------------ 怪物基本信息 ------------
	@params monsterId int 怪物id
	@params campType ConfigCampType 怪物敌友性
	@params level int 怪物等级
	@params attrGrow number 属性成长系数
	@params skillGrow number 技能成长系数
	@params recordDeltaHp ConfigMonsterRecordDeltaHP 是否记录怪物血量变化
	------------ 属性参数 ------------
	@params objpattr ObjPFixedAttrStruct 单体外部属性参数
	------------ 战斗信息 ------------
	@params isLeader bool 是否是队长
	@params positionId int 站位id
	@params teamPosition int 在队伍中的位置序号
	@params skillData table 技能信息
	@params talentData ArtifactTalentConstructorStruct 天赋信息
	@params exAbilityData EXAbilityConstructorStruct 卡牌超能力信息
	@params petData PetConstructorStruct 堕神信息
	------------ 外貌信息 ------------
	@params skinId int 选择的皮肤id
	--]]
	New = function (
			monsterId, campType, level, attrGrow, skillGrow, recordDeltaHp,
			objpattr,
			isLeader, positionId, teamPosition, skillData, talentData, exAbilityData, petData,
			skinId
		)
		local this = NewStruct(MonsterObjConstructorStruct, BaseStruct)

		--[[---------- 初始化数据结构 ------------
		------------ 卡牌基本信息 ------------
		this.monsterId = nil 					-- id
		this.campType = ConfigCampType.ENEMY 	-- 敌友性
		this.level = 1 			 				-- 等级
		this.attrGrow = 1 	 					-- 属性成长系数
		this.skillGrow = 1						-- 技能成长系数
		this.skillGrow = 1						-- 技能成长系数
		------------ 属性参数 ------------
		this.objpattr = ObjPFixedAttrStruct.New() -- 单体外部属性参数
		------------ 战斗信息 ------------
		this.isLeader = false 					-- 是否是队长
		this.teamPosition = 1 					-- 队伍中的位置序号
		this.skillData = {} 					-- 技能信息
		this.talentData = nil 					-- 天赋信息
		this.exAbilityData = nil 				-- 卡牌超能力信息
		this.petData = nil 						-- 堕神信息
		------------ 外貌信息 ------------
		this.skinId = nil 						-- 皮肤id
		------------ 初始化数据结构 ----------]]--

		this:Init(
			monsterId, campType, level, attrGrow, skillGrow, recordDeltaHp,
			objpattr,
			isLeader, positionId, teamPosition, skillData, talentData, exAbilityData, petData,
			skinId
		)

		return this
	end,
	Init = function (self, 
			monsterId, campType, level, attrGrow, skillGrow, recordDeltaHp,
			objpattr,
			isLeader, positionId, teamPosition, skillData, talentData, exAbilityData, petData,
			skinId
		)

		------------ 卡牌基本信息 ------------
		self.monsterId = monsterId
		self.campType = campType or ConfigCampType.ENEMY
		self.level = level
		self.attrGrow = attrGrow
		self.skillGrow = skillGrow
		self.recordDeltaHp = recordDeltaHp or ConfigMonsterRecordDeltaHP.DONT
		------------ 卡牌基本信息 ------------

		------------ 属性参数 ------------
		self.objpattr = objpattr or ObjPFixedAttrStruct.New()
		------------ 属性参数 ------------

		------------ 战斗信息 ------------
		self.isLeader = isLeader
		self.positionId = positionId
		self.teamPosition = teamPosition
		self.skillData = skillData
		self.talentData = talentData
		self.exAbilityData = exAbilityData
		self.petData = petData
		------------ 战斗信息 ------------

		------------ 外貌信息 ------------
		self.skinId = skinId
		------------ 外貌信息 ------------

	end,
	GetObjectConfigId = function (self)
		return checkint(self.monsterId)
	end
}
---------------------------------------------------
-- 构造一个 monster Obj 需要的外部参数 --
---------------------------------------------------

---------------------------------------------------
-- 全局外部属性乘法修正值 --
---------------------------------------------------
ObjectPropertyFixedAttrStruct = {
	--[[
	------------ 属性参数 ------------
	@params hpAttr number 生命参数
	@params attackAttr number 攻击参数
	@params defenceAttr number 防御参数
	@params critRateAttr number 暴击率参数
	@params critDamageAttr number 暴击伤害参数
	@params attackRateAttr number 攻击速度参数
	------------ 系数参数 ------------
	@params ppAttrA map<ObjP,number> 系数乘法参数
	------------ 其他参数 ------------
	@params moveSpeedAttr number 移动速度参数
	--]]
	New = function (
			hpAttr, attackAttr, defenceAttr, critRateAttr, critDamageAttr, attackRateAttr,
			ppAttr,
			moveSpeedAttr
		)
		local this = NewStruct(ObjectPropertyFixedAttrStruct, BaseStruct)

		--[[---------- 初始化数据结构 ------------
		this.pattr = {
			[ObjP.HP] 				= 1,
			[ObjP.ATTACK] 			= 1,
			[ObjP.DEFENCE] 			= 1,
			[ObjP.CRITRATE] 		= 1,
			[ObjP.CRITDAMAGE] 		= 1,
			[ObjP.ATTACKRATE] 		= 1
		}
		this.ppattrA = {}
		this.eattr = {
			moveSpeed 				= 1
		}
		------------ 初始化数据结构 ----------]]--

		this:Init(
			hpAttr, attackAttr, defenceAttr, critRateAttr, critDamageAttr, attackRateAttr,
			ppAttr,
			moveSpeedAttr
		)

		return this
	end,
	Init = function (self,
			hpAttr, attackAttr, defenceAttr, critRateAttr, critDamageAttr, attackRateAttr,
			ppattr,
			moveSpeedAttr
		)
		
		self.pattr = {
			[ObjP.HP] 				= checknumber(hpAttr or 1),
			[ObjP.ATTACK] 			= checknumber(attackAttr or 1),
			[ObjP.DEFENCE] 			= checknumber(defenceAttr or 1),
			[ObjP.CRITRATE] 		= checknumber(critRateAttr or 1),
			[ObjP.CRITDAMAGE] 		= checknumber(critDamageAttr or 1),
			[ObjP.ATTACKRATE] 		= checknumber(attackRateAttr or 1)
		}
		self.ppattrA = ppattr or {}
		self.eattr = {
			moveSpeed 				= checknumber(moveSpeedAttr or 1)
		}

	end
}
---------------------------------------------------
-- 全局外部属性修正值 --
---------------------------------------------------

---------------------------------------------------
-- 单体外部属性修正值 --
---------------------------------------------------
ObjPFixedAttrStruct = {
	--[[
	------------ 属性参数 ------------
	@params hpAttr number 生命参数
	@params hpValue number 生命值参数
	@params energyPercent number 能量百分比参数
	@params energyValue number 能量值参数
	--]]
	New = function (
			hpAttr, hpValue, energyPercent, energyValue
		)

		local this = NewStruct(ObjPFixedAttrStruct, BaseStruct)

		--[[---------- 初始化数据结构 ------------
		this.pattr = {
			[ObjP.HP] 				= 1
		}
		this.pvalue = {
			[ObjP.HP] 				= 0
		}
		this.energyPercent 			= 0
		this.energyValue 			= 0
		------------ 初始化数据结构 ----------]]--

		this:Init(
			hpAttr, hpValue, energyPercent, energyValue
		)
		
		return this
	end,
	Init = function (self,
			hpAttr, hpValue, energyPercent, energyValue
		)

		self.pattr = {
			[ObjP.HP] 				= checknumber(hpAttr or 1),
		}

		self.pvalue = {
			[ObjP.HP] 				= checknumber(hpValue or -1), -- 此处不能初始化为0 0是有特殊意义的数值
		}

		self.energyPercent = checknumber(energyPercent or 0)
		self.energyValue = checknumber(energyValue or 0)
	end
}
---------------------------------------------------
-- 单体外部属性修正值 --
---------------------------------------------------

---------------------------------------------------
-- 构造一个 pet 需要的外部参数 --
---------------------------------------------------
PetConstructorStruct = {
	--[[
	@params petId int 堕神配表id
	@params level int 堕神等级
	@params breakLevel int 堕神强化等级
	@params characterId int 堕神性格id
	@params activeExclusive bool 是否激活本命
	@params petp table 堕神属性
	--]]
	New = function (petId, level, breakLevel, characterId, activeExclusive, petp)
		local this = NewStruct(PetConstructorStruct, BaseStruct)

		--[[---------- 初始化数据结构 ------------
		petId = nil 							-- 堕神配表id
		level = 1 								-- 堕神等级
		breakLevel = 1 							-- 堕神强化等级
		characterId = nil 						-- 堕神性格id
		activeExclusive = false 				-- 是否激活本命
		petp = {} 								-- 堕神属性
		------------ 初始化数据结构 ----------]]--

		this:Init(petId, level, breakLevel, characterId, activeExclusive, petp)

		return this
	end,
	Init = function (self,
			petId, level, breakLevel, characterId, activeExclusive, petp
		)

		self.petId = petId
		self.level = level
		self.breakLevel = breakLevel
		self.characterId = characterId
		self.activeExclusive = activeExclusive
		self.petp = petp

	end,
	GetCardPropertyAddition = function (self)
		return PetUtils.GetPetPropertyAdditionByConvertedData(self.petp)
	end
}
---------------------------------------------------
-- 构造一个 pet 需要的外部参数 --
---------------------------------------------------

---------------------------------------------------
-- 构造一个神器天赋需要的外部参数 --
---------------------------------------------------
ArtifactTalentConstructorStruct = {
	--[[
	@params cardId int 卡牌id
	@params talentData map 天赋信息
	--]]
	New = function (cardId, talentData)
		local this = NewStruct(ArtifactTalentConstructorStruct, BaseStruct)

		--[[---------- 初始化数据结构 ------------
		this.cardId = nil 						-- 对应的卡牌id
		this.talentData = nil					-- 对应的天赋信息
		------------ 初始化数据结构 ----------]]--

		this:Init(cardId, talentData)

		return this
	end,
	Init = function (self,
			cardId, talentData
		)

		self.cardId = cardId
		self.talentData = talentData or {}

	end,
	GetCardPropertyAddition = function (self)
		return ArtifactUtils.GetArtifactPropertyAddition(self.cardId, self.talentData)
	end
}
---------------------------------------------------
-- 构造一个神器天赋需要的外部参数 --
---------------------------------------------------

---------------------------------------------------
-- 构造一个飨灵收集册需要的外部参数 --
---------------------------------------------------
BookConstructorStruct = {
	--[[
	@params cardId int 卡牌id
	@params bookData map 飨灵收集册的信息
	--]]
	New = function (cardId, bookData)
		local this = NewStruct(BookConstructorStruct, BaseStruct)

		--[[---------- 初始化数据结构 ------------
		this.cardId = nil 						-- 对应的卡牌id
		this.bookData = nil					-- 对应的飨灵收集册的信息
		------------ 初始化数据结构 ----------]]--

		this:Init(cardId, bookData)

		return this
	end,
	Init = function (self,
			cardId, bookData
		)

		self.cardId = cardId
		self.bookData = bookData or {}

	end,
	GetCardPropertyAddition = function (self)
		return CardUtils.GetCardBookPropertyAddition(self.bookData)
	end
}
---------------------------------------------------
-- 构造一个飨灵收集册需要的外部参数 --
---------------------------------------------------

---------------------------------------------------
-- 构造一个猫咪基因需要的外部参数 --
---------------------------------------------------
CatGeneConstructorStruct = {
	--[[
	@params equippedHouseCatGene map 猫咪基因列表
	--]]
	New = function (equippedHouseCatGene)
		local this = NewStruct(CatGeneConstructorStruct, BaseStruct)

		--[[---------- 初始化数据结构 ------------
		this.equippedHouseCatGene = nil		-- 猫咪基因列表
		------------ 初始化数据结构 ----------]]--

		this:Init(equippedHouseCatGene)

		return this
	end,
	Init = function (self,
			equippedHouseCatGene
		)
		self.equippedHouseCatGene = equippedHouseCatGene or {}

	end,
	GetCardPropertyAddition = function (self)
		return CatHouseUtils.GetCatBuff(self.equippedHouseCatGene)
	end
}
---------------------------------------------------
-- 构造一个猫咪基因需要的外部参数 --
---------------------------------------------------

---------------------------------------------------
-- 构造一个卡牌超能力需要的外部参数 --
---------------------------------------------------
EXAbilityConstructorStruct = {
	--[[
	@params cardId int 卡牌id
	@params skills list 技能集合
	--]]
	New = function (cardId, skills)
		local this = NewStruct(EXAbilityConstructorStruct, BaseStruct)

		--[[---------- 初始化数据结构 ------------
		this.cardId = nil 						-- 对应的卡牌id
		this.skills = nil						-- 对应的技能集合
		------------ 初始化数据结构 ----------]]--

		this:Init(cardId, skills)

		return this
	end,
	--[[
	@params cardId int 卡牌id
	@params skills list 技能集合
	--]]
	Init = function (self, cardId, skills)

		self.cardId = cardId
		self.skills = skills or {}

	end
}
---------------------------------------------------
-- 构造一个卡牌超能力需要的外部参数 --
---------------------------------------------------

---------------------------------------------------
-- 一场战斗会发生的网络命令 --
---------------------------------------------------
BattleNetworkCommandStruct = {
	--[[
	@params enterBattleRequestCommand COMMANDS 进入战斗的命令
	@params enterBattleRequestData table 请求的参数集
	@params enterBattleResponseSignal SIGNALNAMES 进入战斗命令回调信号
	@params exitBattleRequestCommand COMMANDS 战斗结束结算命令
	@params exitBattleRequestData table 请求的参数集
	@params exitBattleResponseSignal SIGNALNAMES 战斗结束命令回调信号
	@params buyCheatRequestCommand COMMANDS 买活的命令
	@params buyCheatRequestData table 买活的命令参数
	@params buyCheatResponseSignal SIGNALNAMES 买活的命令回调信号
	--]]
	New = function (
			enterBattleRequestCommand, enterBattleRequestData, enterBattleResponseSignal,
			exitBattleRequestCommand, exitBattleRequestData, exitBattleResponseSignal,
			buyCheatRequestCommand, buyCheatRequestData, buyCheatResponseSignal
		)

		local this = NewStruct(BattleNetworkCommandStruct, BaseStruct)

		--[[---------- 初始化数据结构 ------------
		this.enterBattleRequestCommand = nil 		-- 进入战斗的命令
		this.enterBattleRequestData = nil 			-- 请求的参数集
		this.enterBattleResponseSignal = nil 		-- 进入战斗命令回调信号
		this.exitBattleRequestCommand = nil 		-- 战斗结束结算命令
		this.exitBattleRequestData = nil 			-- 请求的参数集
		this.exitBattleResponseSignal = nil 		-- 战斗结束命令回调信号
		this.buyCheatRequestCommand = nil 			-- 买活的命令
		this.buyCheatRequestData = nil 				-- 买活的命令参数
		this.buyCheatResponseSignal = nil 			-- 买活的命令回调信号
		------------ 初始化数据结构 ----------]]--

		this:Init(
			enterBattleRequestCommand, enterBattleRequestData, enterBattleResponseSignal,
			exitBattleRequestCommand, exitBattleRequestData, exitBattleResponseSignal,
			buyCheatRequestCommand, buyCheatRequestData, buyCheatResponseSignal
		)

		return this
	end,
	Init = function (self,
			enterBattleRequestCommand, enterBattleRequestData, enterBattleResponseSignal,
			exitBattleRequestCommand, exitBattleRequestData, exitBattleResponseSignal,
			buyCheatRequestCommand, buyCheatRequestData, buyCheatResponseSignal
		)

		------------ 进入时的网络命令 ------------
		self.enterBattleRequestCommand = enterBattleRequestCommand
		self.enterBattleRequestData = enterBattleRequestData
		self.enterBattleResponseSignal = enterBattleResponseSignal
		------------ 进入时的网络命令 ------------

		------------ 结算时的网络命令 ------------
		self.exitBattleRequestCommand = exitBattleRequestCommand
		self.exitBattleRequestData = exitBattleRequestData
		self.exitBattleResponseSignal = exitBattleResponseSignal
		------------ 结算时的网络命令 ------------

		------------ 买活的命令 ------------
		self.buyCheatRequestCommand = buyCheatRequestCommand
		self.buyCheatRequestData = buyCheatRequestData
		self.buyCheatResponseSignal = buyCheatResponseSignal
		------------ 买活的命令 ------------

	end
}
---------------------------------------------------
-- 一场战斗会发生的网络命令 --
---------------------------------------------------

---------------------------------------------------
-- 战斗前后的跳转信息 --
---------------------------------------------------
BattleMediatorsConnectStruct = {
	--[[
	@params fromMediatorName string 从哪个mediator来
	@params toMediatorName string 到哪个mediator去
	@params toMediatorNameFail string 战斗失败时的跳转
	--]]
	New = function (fromMediatorName, toMediatorName, toMediatorNameFail)
		local this = NewStruct(BattleMediatorsConnectStruct, BaseStruct)

		--[[---------- 初始化数据结构 ------------
		this.fromMediatorName = nil 				-- mediator name
		this.toMediatorName = nil 					-- mediator name
		this.toMediatorNameFail = nil 				-- mediator name
		------------ 初始化数据结构 ----------]]--

		this:Init(fromMediatorName, toMediatorName, toMediatorNameFail)

		return this
	end,
	Init = function (self, fromMediatorName, toMediatorName, toMediatorNameFail)
		self.fromMediatorName = fromMediatorName
		self.toMediatorName = toMediatorName
		self.toMediatorNameFail = toMediatorNameFail or toMediatorName

	end,
	--[[
	获取from的mediator name
	--]]
	GetFromMediatorName = function (self)
		return self.fromMediatorName
	end,
	--[[
	获取to的mediator name
	@params battleResult PassedBattle 是否通过了战斗
	--]]
	GetToMediatorName = function (self, battleResult)
		if PassedBattle.SUCCESS == battleResult then
			return self.toMediatorName
		else
			return self.toMediatorNameFail
		end
	end
}
---------------------------------------------------
-- 战斗前后的跳转信息 --
---------------------------------------------------

---------------------------------------------------
-- 战斗引导单步的数据结构 --
---------------------------------------------------
BattleGuideStepStruct = {
	--[[
	------------ 触发时机 ------------
	@params guideStepId int 引导配表id
	@params guideStepType ConfigBattleGuideStepType 引导类型
	@params triggerType ConfigBattleGuideStepTriggerType 引导触发类型
	@params triggerValue number 引导触发的数值
	@params endType ConfigBattleGuideStepEndType 引导结束类型
	@params delayTime number 延迟出现时间
	------------ 引导主体 ------------
	@params guideContent string 引导提示文字
	@params guideGodType ConfigBattleGuideStepGodType 引导主体类型
	@params guideGodLocationId int 引导主体位置
	------------ 引导高亮 ------------
	@params highlightType ConfigBattleGuideStepHighlightType 高亮类型
	@params highlightId ... 高亮主体id
	@params highlightIndex list 高亮主体序号
	@params highlightSize cc.size 高亮主体大小
	@params highlightShapeType ConfigBattleGuideStepHighlightShapeType 高亮形状
	--]]
	New = function (
			guideStepId, guideStepType, triggerType, triggerValue, endType, delayTime,
			guideContent, guideGodType, guideGodLocationId,
			highlightType, highlightId, highlightIndex, highlightSize, highlightShapeType
		)
		local this = NewStruct(BattleGuideStepStruct, BaseStruct)

		--[[---------- 初始化数据结构 ------------
		------------ 触发时机 ------------
		guideStepId = 0 									-- 引导配表id
		guideStepType = ConfigBattleGuideStepType.BASE 		-- 引导类型
		triggerType = ConfigBattleGuideStepTriggerType.BASE -- 引导触发类型
		triggerValue = 0 									-- 引导触发的数值
		endType = ConfigBattleGuideStepEndType.BASE 		-- 引导结束类型
		delayTime = 0 										-- 延迟出现时间
		------------ 引导主体 ------------
		guideContent = '' 									-- 引导提示文字
		guideGodType = ConfigBattleGuideStepGodType.BASE 	-- 引导主体类型
		guideGodLocationId = 0 								-- 引导主体位置
		------------ 引导高亮 ------------
		highlightType = ConfigBattleGuideStepHighlightType.BASE -- 高亮类型
		highlightId = 0 									-- 高亮主体id
		highlightIndex = {} 								-- 高亮主体序号
		highlightSize = cc.size(0, 0) 						-- 高亮主体大小
		highlightShapeType = ConfigBattleGuideStepHighlightShapeType.BASE -- 高亮形状类型
		------------ 初始化数据结构 ----------]]--

		this:Init(
			guideStepId, guideStepType, triggerType, triggerValue, endType, delayTime,
			guideContent, guideGodType, guideGodLocationId,
			highlightType, highlightId, highlightIndex, highlightSize, highlightShapeType
		)

		return this
	end,
	Init = function (self,
			guideStepId, guideStepType, triggerType, triggerValue, endType, delayTime,
			guideContent, guideGodType, guideGodLocationId,
			highlightType, highlightId, highlightIndex, highlightSize, highlightShapeType
		)

		------------ 触发时机 ------------
		self.guideStepId = guideStepId
		self.guideStepType = guideStepType
		self.triggerType = triggerType
		self.triggerValue = triggerValue
		self.endType = endType
		self.delayTime = delayTime
		------------ 触发时机 ------------

		------------ 引导主体 ------------
		self.guideContent = guideContent
		self.guideGodType = guideGodType
		self.guideGodLocationId = guideGodLocationId
		------------ 引导主体 ------------

		------------ 引导高亮 ------------
		self.highlightType = highlightType
		self.highlightId = highlightId
		self.highlightIndex = highlightIndex
		self.highlightSize = highlightSize
		self.highlightShapeType = highlightShapeType
		------------ 引导高亮 ------------
		
	end
}
---------------------------------------------------
-- 战斗引导单步的数据结构 --
---------------------------------------------------

---------------------------------------------------
-- 卡牌资源信息数据结构 --
---------------------------------------------------
CardObjDrawInfoStruct = {
	--[[
	@params drawPath string 立绘路径
	@params headPath string 头像路径
	@params drawBgPath string 立绘背景路径
	@params drawFgPath string 立绘前景路径
	@params teamDrawBgPath string 编队立绘背景路径
	@params spinePath string spine动画路径
	@params spineSkinId string spine动画皮肤id
	--]]
	New = function (drawPath, headPath, drawBgPath, drawFgPath, teamDrawBgPath, spinePath, spineSkinId)

		local this = NewStruct(CardObjDrawInfoStruct, BaseStruct)

		this:Init(drawPath, headPath, drawBgPath, drawFgPath, teamDrawBgPath, spinePath, spineSkinId)

		return this

	end,
	Init = function (self,
			drawPath, headPath, drawBgPath, drawFgPath, teamDrawBgPath, spinePath, spineSkinId
		)

		self.drawPath = drawPath
		self.headPath = headPath
		self.drawBgPath = drawBgPath
		self.drawFgPath = drawFgPath
		self.teamDrawBgPath = teamDrawBgPath
		self.spinePath = spinePath
		self.spineSkinId = spineSkinId

	end
}
---------------------------------------------------
-- 卡牌资源信息数据结构 --
---------------------------------------------------

---------------------------------------------------
-- 参与联机战斗的玩家信息数据结构 --
---------------------------------------------------
RaidMemberStruct = {
	--[[
	------------ 基本信息 ------------
	@params playerId int 玩家id
	@params playerName string 玩家名
	@params level int 等级
	@params mainExp int 经验
	------------ 外貌信息 ------------
	@params avatar string 玩家头像
	@params avatarFrame string 玩家头像框
	------------ 数据信息 ------------
	@params raidLeftChallengeTimes int 剩余组队副本挑战次数
	--]]
	New = function (
			playerId, playerName, level, mainExp,
			avatar, avatarFrame,
			raidLeftChallengeTimes
		)

		local this = NewStruct(RaidMemberStruct, BaseStruct)

		--[[---------- 初始化数据结构 ------------
		this.playerId = 0 						-- 玩家id
		this.playerName = '' 					-- 玩家名字
		this.level = 1 							-- 玩家等级
		this.mainExp = 0 						-- 玩家经验
		this.avatar = '' 						-- 玩家头像
		this.avatarFrame = '' 					-- 玩家头像框
		this.raidLeftChallengeTimes = 0 		-- 剩余组队副本挑战次数
		------------ 初始化数据结构 ----------]]--

		this:Init(
			playerId, playerName, level, mainExp,
			avatar, avatarFrame,
			raidLeftChallengeTimes
		)

		return this

	end,
	Init = function (self,
			playerId, playerName, level, mainExp,
			avatar, avatarFrame,
			raidLeftChallengeTimes
		)

		self.playerId = playerId
		self.playerName = playerName
		self.level = level
		self.mainExp = mainExp
		self.avatar = avatar
		self.avatarFrame = avatarFrame
		self.raidLeftChallengeTimes = raidLeftChallengeTimes

	end
}
---------------------------------------------------
-- 参与联机战斗的玩家信息数据结构 --
---------------------------------------------------

---------------------------------------------------
-- 战斗结束条件配置数据结构 --
---------------------------------------------------
StageCompleteSturct = {
	--[[
	@params completeConf table 战斗结束配置结构
	--]]
	New = function (completeConf)

		local this = NewStruct(StageCompleteSturct, BaseStruct)

		--[[---------- 初始化数据结构 ------------
		this.completeType = ConfigStageCompleteType.NORMAL 	-- 过关类型
		this.targetsInfo = {} 								-- 目标信息
		this.aliveTime = 0 									-- 存活时间
		------------ 初始化数据结构 ----------]]--

		this:Init(completeConf)

		return this

	end,
	Init = function (self,
			completeConf
		)
	
		if nil == completeConf or nil == completeConf.type or 0 == checkint(completeConf.type) then
			self.completeType = ConfigStageCompleteType.NORMAL
			self.targetsInfo = {}
			--[[
			{
				['targetId'] = {targetId int 目标配表id target, targetHpPercent number 目标血量百分比}
			}
			--]]
			self.aliveTime = 0
		else
			self.completeType = checkint(completeConf.type)
			self.targetsInfo = {}
			--[[
			{
				{targetId int 目标配表id target, targetHpPercent number 目标血量百分比}
			}
			--]]
			self.aliveTime = 0

			if ConfigStageCompleteType.ALIVE == self.completeType then
				-- 存活模式
				self.aliveTime = checkint(completeConf.value[1])
			elseif ConfigStageCompleteType.HEAL_FRIEND == self.completeType then
				-- 刷血模式
				for i,v in ipairs(completeConf.value) do
					self.targetsInfo[tostring(v)] = {targetId = checkint(v), targetHpPercent = 1}
				end
			elseif ConfigStageCompleteType.SLAY_ENEMY == self.completeType then
				-- 杀戮模式
				for i,v in ipairs(completeConf.value) do
					self.targetsInfo[tostring(v)] = {targetId = checkint(v)}
				end
			end
		end

		-- debug --
		-- self.completeType = ConfigStageCompleteType.SLAY_ENEMY
		-- -- self.completeType = ConfigStageCompleteType.HEAL_FRIEND
		-- -- self.completeType = ConfigStageCompleteType.ALIVE
		-- self.targetsInfo = {
		-- 	['301002'] = {targetId = 301002, targetHpPercent = 1},
		-- 	-- ['301078'] = {targetId = 301078, targetHpPercent = 0.75}
		-- }
		-- self.aliveTime = 20
		-- debug --
	end
}
---------------------------------------------------
-- 战斗结束条件配置数据结构 --
---------------------------------------------------

---------------------------------------------------
-- 每一波的背景图配置 --
---------------------------------------------------
BattleBackgroundStruct = {
	--[[
	@params bgId int 背景图id
	@params defaultBgScale number 默认背景图缩放
	--]]
	New = function (bgId, defaultBgScale)
		local this = NewStruct(BattleBackgroundStruct, BaseStruct)

		--[[---------- 初始化数据结构 ------------
		this.bgId = nil 						-- 背景图id
		this.defaultBgScale = nil 				-- 默认背景图缩放
		------------ 初始化数据结构 ----------]]--

		this:Init(bgId, defaultBgScale)

		return this
	end,
	Init = function (self,
			bgId, defaultBgScale
		)

		self.bgId = checkint(bgId or 1)
		self.defaultBgScale = checknumber(defaultBgScale or 1)

	end
}
---------------------------------------------------
-- 每一波的背景图配置 --
---------------------------------------------------

---------------------------------------------------
-- 全局效果数据结构 --
---------------------------------------------------
GlobalEffectConstructStruct = {
	--[[
	@params gbuffId int 全局buffid
	@params skillId int 技能id
	@params level int 等级
	--]]
	New = function (gbuffId, skillId, level)
		local this = NewStruct(GlobalEffectConstructStruct, BaseStruct)

		--[[---------- 初始化数据结构 ------------
		this.gbuffId = nil 						-- 全局buffid
		this.skillId = nil 						-- 对应的技能id
		this.level = nil 						-- 技能对应的等级
		------------ 初始化数据结构 ----------]]--

		this:Init(gbuffId, skillId, level)
		return this
	end,
	Init = function (self,
			gbuffId, skillId, level
		)
		self.gbuffId = gbuffId
		self.skillId = skillId
		self.level = level or 1
	end
}
---------------------------------------------------
-- 全局效果数据结构 --
---------------------------------------------------

---------------------------------------------------
-- 镜头特效数据结构 --
---------------------------------------------------
CameraActionStruct = {
	--[[
	@params id int 镜头特效id
	@params cameraActionType ConfigCameraActionType 镜头类型
	@params cameraActionValue table 镜头变化的值
	@params triggerType ConfigCameraTriggerType 触发条件
	@params triggerValue table 触发值
	@params delayTime number 延迟时间
	@params accelerate bool 是否保留当前游戏加速
	--]]
	New = function (
			id, cameraActionType, cameraActionValue, triggerType, triggerValue, delayTime, accelerate
		)
		local this = NewStruct(CameraActionStruct, BaseStruct)

		--[[---------- 初始化数据结构 ------------
		this.id = 0 										-- 镜头特效id
		this.cameraActionType = ConfigCameraActionType.BASE -- 镜头类型
		this.triggerType = ConfigCameraTriggerType.BASE 	-- 触发类型
		this.delayTime = delayTime 							-- 延迟
		this.accelerate = ValueConstants.V_NORMAL 			-- 是否保留游戏加速
		------------ 初始化数据结构 ----------]]--

		this:Init(
			id, cameraActionType, cameraActionValue, triggerType, triggerValue, delayTime, accelerate
		)

		return this
	end,
	Init = function (self,
			id, cameraActionType, cameraActionValue, triggerType, triggerValue, delayTime, accelerate
		)
		self.id = id
		self.cameraActionType = cameraActionType
		self.triggerType = triggerType
		self.delayTime = delayTime
		self.accelerate = ValueConstants.V_NORMAL == checkint(accelerate)

		self.cameraActionValue = nil
		self.triggerTarget = nil
		self.triggerTargetCampType = nil
		self.triggerValue = nil

		-- 镜头变化的值
		if ConfigCameraActionType.SHAKE_ZOOM == self.cameraActionType then
			self.cameraActionValue = checknumber(checktable(cameraActionValue)[1])
		end

		-- 镜头触发的值
		if ConfigCameraTriggerType.PHASE_CHANGE == self.triggerType then
			self.triggerValue = checknumber(checktable(triggerValue)[1])
		elseif ConfigCameraTriggerType.OBJ_SKILL == self.triggerType then
			self.triggerTarget = checkint(checktable(triggerValue)[1])
			self.triggerTargetCampType = checkint(checktable(triggerValue)[2])
			self.triggerValue = checknumber(checktable(triggerValue)[3])
		end
	end
}
---------------------------------------------------
-- 镜头特效数据结构 --
---------------------------------------------------

---------------------------------------------------
-- 渲染层操作数据结构 --
---------------------------------------------------
RenderOperateStruct = {
	--[[
	@params managerName string 管理器名字
	@params functionName string 方法名
	@params ... 参数集
	--]]
	New = function (managerName, functionName, ...)
		local this = NewStruct(RenderOperateStruct, BaseStruct)

		--[[---------- 初始化数据结构 ------------
		this.managerName = nil 					-- 管理器名字
		this.functionName = nil 				-- 方法名
		this.variableParams 					-- 变长参数
		------------ 初始化数据结构 ----------]]--

		this:Init(managerName, functionName, ...)

		return this
	end,
	Init = function (self, managerName, functionName, ...)
		self.managerName = managerName
		self.functionName = functionName
		self.variableParams = { ... }
		self.maxParams = select('#', ...)
	end
}
---------------------------------------------------
-- 渲染层操作数据结构 --
---------------------------------------------------

---------------------------------------------------
-- 逻辑层操作数据结构 --
---------------------------------------------------
LogicOperateStruct = {
	--[[
	@params managerName string 管理器名字
	@params functionName string 方法名
	@params ... 参数集
	--]]
	New = function (managerName, functionName, ...)
		local this = NewStruct(LogicOperateStruct, BaseStruct)

		--[[---------- 初始化数据结构 ------------
		this.managerName = nil 					-- 管理器名字
		this.functionName = nil 				-- 方法名
		this.variableParams 					-- 变长参数
		------------ 初始化数据结构 ----------]]--

		this:Init(managerName, functionName, ...)

		return this
	end,
	Init = function (self, managerName, functionName, ...)
		self.managerName = managerName
		self.functionName = functionName
		self.variableParams = { ... }
		self.maxParams = select('#', ...)
	end
}
---------------------------------------------------
-- 逻辑层操作数据结构 --
---------------------------------------------------

---------------------------------------------------
-- spine资源加载的数据结构 --
---------------------------------------------------
SpineAnimationCacheInfoStruct = {
	--[[
	@params cacheName string 缓存的唯一名称
	@params path string spine的路径
	@params scale number spine创建时的缩放比
	@parmas skinId int 皮肤id
	--]]
	New = function (cacheName, path, scale, skinId)
		local this = NewStruct(SpineAnimationCacheInfoStruct, BaseStruct)

		--[[---------- 初始化数据结构 ------------
		this.cacheName = nil 					-- 缓存的唯一名称
		this.path = nil 						-- spine的路径
		this.scale = 1 							-- spine创建时的缩放比
		this.skinId = nil 						-- 皮肤id
		------------ 初始化数据结构 ----------]]--

		this:Init(cacheName, path, scale, skinId)

		return this
	end,
	Init = function (self,
			cacheName, path, scale, skinId			
		)

		self.cacheName = cacheName
		self.path = path
		self.scale = scale
		self.skinId = skinId

	end
}
---------------------------------------------------
-- spine资源加载的数据结构 --
---------------------------------------------------

---------------------------------------------------
-- 怪物强度系数数据结构 --
---------------------------------------------------
MonsterIntensityAttrStruct = {
	--[[
	@params attrConfig table 强度系数配表内容
	--]]
	New = function (attrConfig)
		local this = NewStruct(MonsterIntensityAttrStruct, BaseStruct)

		--[[---------- 初始化数据结构 ------------
		this.attrGrow = 1 						-- 属性系数
		this.skillGrow = 1 						-- 技能系数
		this.level = 1 							-- 等级
		------------ 初始化数据结构 ----------]]--

		this:Init(attrConfig)

		return this
	end,
	Init = function (self, attrConfig)

		if nil == attrConfig then

			self.attrGrow = nil
			self.skillGrow = nil
			self.level = nil

		else

			self.attrGrow = checknumber(attrConfig.npcAttrGrow or 1)
			self.skillGrow = checknumber(attrConfig.npcSkillGrow or 1)
			self.level = checknumber(attrConfig.monsterLevel or 1)

		end

	end
}
---------------------------------------------------
-- 怪物强度系数数据结构 --
---------------------------------------------------
