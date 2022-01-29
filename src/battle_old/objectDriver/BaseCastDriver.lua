--[[
施法驱动基类
--]]
local BaseActionDriver = __Require('battle.objectDriver.BaseActionDriver')
local BaseCastDriver = class('BaseCastDriver', BaseActionDriver)

------------ import ------------
local cardMgr = AppFacade.GetInstance():GetManager('CardManager')
------------ import ------------

--[[
constructor
--]]
function BaseCastDriver:ctor( ... )
	BaseActionDriver.ctor(self, ...)

	self:Init()
end

---------------------------------------------------
-- init logic begin --
---------------------------------------------------
--[[
初始化逻辑
--]]
function BaseCastDriver:Init()
	self:InitInnateValue()
	self:InitUnitValue()
	
	self:InitSkills()
end
--[[
初始化固有属性
--]]
function BaseCastDriver:InitInnateValue()
	self.skillCastCounter = {}
	self.skillExtra = 1
	self.castingEcho = false
end
--[[
初始化独有属性
--]]
function BaseCastDriver:InitUnitValue()
	self.hasConnectSkill = false
	self.chantCountdown = nil
	-- 回响的施法列表
	self.castEchoSkillId = {}
end
---------------------------------------------------
-- init logic end --
---------------------------------------------------

---------------------------------------------------
-- control logic begin --
---------------------------------------------------
--[[
是否能进行动作
@params actionTriggerType ActionTriggerType 行为触发类型
@params skillId int 技能id
@return _ int 可释放的技能id
--]]
function BaseCastDriver:CanDoAction(actionTriggerType, skillId)
	if nil ~= self:GetNextEchoSkill() then

		-- 施法回响的技能优先判断
		print('>>>>>>>>>>>>>>>>>>> here cast echo skillId : ' .. skillId)
		self:SetCastingEcho(true)
		return self:GetNextEchoSkill()

	elseif ActionTriggerType.CD == actionTriggerType then

		-- 返回当前可以释放的cd技能id
		return self:CanCastByCD()

	elseif ActionTriggerType.ATTACK == actionTriggerType then

		-- 返回当前可以释放的攻击触发技能id
		return self:CanCastByAttack()

	elseif ActionTriggerType.CONNECT == actionTriggerType and nil ~= skillId then

		-- 返回当前可以释放连携技
		return self:CanCastBySkillId(skillId)

	else

		return nil

	end
end
--[[
进入动作
@params skillId int 技能id
--]]
function BaseCastDriver:OnActionEnter(skillId)
	print('\n**************\n', self:GetOwner():getOCardName(), ' cast skill(new logic) -> ', skillId, '\n**************\n')
	---------- logic ----------
	-- 置为施法状态
	self:GetOwner():setState(OState.CASTING)
	-- 缓存点击的弱点id
	self:GetOwner().curClickedWeakPointId = 0
	-- 消耗释放技能的资源
	self:CostActionResources(skillId)
	---------- logic ----------
	self:TriggerEvent(skillId)
end
--[[
结束动作
--]]
function BaseCastDriver:OnActionExit()
	self:OnCastExit()
end
--[[
打断动作
--]]
function BaseCastDriver:OnActionBreak()
	self:OnCastBreak()
end
--[[
动作进行中
@params dt number delta time
--]]
function BaseCastDriver:OnActionUpdate(dt)

end
--[[
是否可以释放cd触发的技能
@return _ int 可释放的技能id
--]]
function BaseCastDriver:CanCastByCD()
	for i, skillId in ipairs(self.skills.cd) do
		if true == self:CanCastBySkillId(skillId) then
			return skillId
		end
	end

	return nil
end
--[[
是否可以释放攻击触发的技能
@return _ int 可释放的技能id
--]]
function BaseCastDriver:CanCastByAttack()
	for i, skillId in ipairs(self.skills.attack) do
		if true == self:CanCastBySkillId(skillId) then
			return skillId
		end
	end

	return nil
end
--[[
是否可以释放对应id的技能
@params int skillId int 技能id
@return result bool 是否可以释放技能
--]]
function BaseCastDriver:CanCastBySkillId(skillId)
	local result = false
	-- 状态过滤 沉默 眩晕 无法释放技能
	if not self:GetOwner():isSilent() and
		self:GetOwner():canAct() and
		2 == self:IsInChanting() and
		not self:GetOwner():isEnchanting() then

		local skillConf = CommonUtils.GetSkillConf(skillId)
		if ConfigSkillType.SKILL_CONNECT == checkint(skillConf.property) then
			-- 连携技检测 首先消耗各种充能
			if -1 == self.connectSkillChargeCounter[tostring(skillId)] then

				-- 连携技不再能充能的状态 快速返回
				return false

			elseif 0 < self.connectSkillChargeCounter[tostring(skillId)] then

				-- TODO --
				-- -- 连携技特殊充能 消耗连携技特殊充能 并且将连携技特殊充能置为不可再充能状态
				-- self.connectSkillChargeCounter[tostring(skillId)] = -1
				result = true

			else

				-- 检测连携对象存活情况
				if not self:CanUseConnectSkillByCardAlive(skillId) then
					return false
				end

				-- 普通技能检测
				if self:CanCastSkillJudgeByTriggerType(skillId) then
					result = true
				end

			end
		else

			---------- 复活技能有特殊的机制 ----------
			if true == BattleUtils.IsSkillHaveBuffEffectByBuffType(skillId, ConfigBuffType.REVIVE) then
				if false == self:CanCastRevive(skillId) then
					return false
				end
			end
			---------- 复活技能有特殊的机制 ----------

			---------- qte召唤技能有特殊的机制 ----------
			if true == BattleUtils.IsSkillHaveBuffEffectByBuffType(skillId, ConfigBuffType.BECKON) then
				print('\n\n\nhere check fuck beckon skill logic>>>>>>>>>>>>>>>>>>>>>>>>>>', self:CanCastBeckon(skillId))
				if false == self:CanCastBeckon(skillId) then
					return false
				end
			end
			---------- qte召唤技能有特殊的机制 ----------

			-- 普通技能检测
			if self:CanCastSkillJudgeByTriggerType(skillId) then
				result = true
			end

		end
	end
	return result
end
--[[
是否可以施放复活技能
@params skillId int 技能id
@return _ bool 
--]]
function BaseCastDriver:CanCastRevive(skillId)
	local skillConf = CommonUtils.GetSkillConf(skillId)
	local isEnemy = self:GetOwner():isEnemy()
	local canReviveCards = BattleExpression.GetDeadFriendlyTargets(
		isEnemy,
		checkint(skillConf.target[tostring(ConfigBuffType.REVIVE)].type),
		self:GetOwner(),
		true
	)
	return #canReviveCards > 0
end
--[[
是否可以施放qte召唤技能
@params skillId int 技能id
@return _ bool 
--]]
function BaseCastDriver:CanCastBeckon(skillId)
	return BMediator:CanCreateBeckonFromBuff()
end
--[[
处理技能触发类型判定
@params skillId int 技能id
@return result bool 是否满足条件释放该技能
--]]
function BaseCastDriver:CanCastSkillJudgeByTriggerType(skillId)
	local result = true

	---------- 内置cd ----------
	local insideCD = self.skillInsideCountdown[tostring(skillId)]
	if nil ~= insideCD and insideCD > 0 then
		return false
	end
	---------- 内置cd ----------

	local triggerType = 0
	local triggerValue = 0

	local judgeFunc = {
		[ConfigSkillTriggerType.RESIDENT] = function (triggerValue)

			-- 常驻触发类型视为光环 光环只在特定事件初始化
			return false

		end,
		[ConfigSkillTriggerType.RANDOM] = function (triggerValue)

			-- 随机
			return (triggerValue * 1000) >= (BMediator:GetRandomManager():GetRandomInt(1000))

		end,
		[ConfigSkillTriggerType.ENERGY] = function (triggerValue)

			-- 能量
			return triggerValue <= self:GetOwner():getEnergy():ObtainVal()

		end,
		[ConfigSkillTriggerType.CD] = function (triggerValue)

			-- cd
			return 0 >= self:GetActionTrigger(ActionTriggerType.CD, skillId)

		end,
		[ConfigSkillTriggerType.LOST_HP] = function (triggerValue)

			-- 损失的血量百分比
			local r1 = triggerValue <= self:GetActionTrigger(ActionTriggerType.HP)
			local r2 = true
			local countdown = self:GetActionTrigger(ActionTriggerType.CD, skillId)
			if not (nil ~= countdown and countdown <= 0) then
				r2 = false
			end
			return r1 and r2

		end,
		[ConfigSkillTriggerType.COST_HP] = function (triggerValue)

			-- 固定的血量
			return triggerValue < self:GetOwner():getMainProperty():getCurrentHp()

		end,
		[ConfigSkillTriggerType.COST_CHP] = function (triggerValue)

			-- 当前血量百分比
			return true

		end,
		[ConfigSkillTriggerType.COST_OHP] = function (triggerValue)

			-- 最大血量百分比
			return triggerValue < self:GetOwner():getMainProperty():getCurHpPercent()

		end
	}

	---------- 判断触发条件 ----------
	local skillTriggerInfo = self:GetSkillTriggerInfoBySkillId(skillId)
	local sk = sortByKey(skillTriggerInfo)
	for _, key in ipairs(sk) do

		triggerType = key
		triggerValue = skillTriggerInfo[triggerType]

		local result = judgeFunc[triggerType](triggerValue)

		if not result then
			return false
		end

	end
	---------- 判断触发条件 ----------

	return result

	-- local skillInfo = CommonUtils.GetSkillConf(skillId)
	-- local result = true
	-- local triggerType = 0
	-- local triggerValue = 0

	-- -- 首先判断内置cd是否满足
	-- local insideCD = self.skillInsideCountdown[tostring(skillId)]
	-- if nil ~= insideCD and insideCD > 0 then
	-- 	return false
	-- end

	-- -- ### serialized ### --
	-- local sk = sortByKey(skillInfo.triggerType)
	-- for i, key in ipairs(sk) do

	-- 	triggerType = checkint(key)
	-- 	triggerValue = checknumber(skillInfo.triggerType[key])

	-- 	if ConfigSkillTriggerType.RESIDENT == triggerType then

	-- 		-- 常驻触发类型视为光环 光环只在特定事件初始化
	-- 		return false

	-- 	elseif ConfigSkillTriggerType.RANDOM == triggerType then

	-- 		-- 随机
	-- 		local randomResult = (BMediator:GetRandomManager():GetRandomInt(1000) <= (triggerValue * 1000))
	-- 		if false == randomResult then
	-- 			return false
	-- 		end

	-- 	elseif ConfigSkillTriggerType.ENERGY == triggerType then

	-- 		-- 能量
	-- 		if self:GetOwner():getEnergy() < triggerValue then
	-- 			return false
	-- 		end

	-- 	elseif ConfigSkillTriggerType.CD == triggerType then

	-- 		-- cd
	-- 		if self:GetActionTrigger(ActionTriggerType.CD, skillId) > 0 then
	-- 			return false
	-- 		end

	-- 	elseif ConfigSkillTriggerType.LOST_HP == triggerType then

	-- 		-- cd
	-- 		if triggerValue > self:GetActionTrigger(ActionTriggerType.HP) then
	-- 			-- 此处判断一下是否存在cd 特殊处理实现硬狂暴类型
	-- 			local countdown = self:GetActionTrigger(ActionTriggerType.CD, skillId)
	-- 			if not (nil ~= countdown and countdown <= 0) then
	-- 				return false
	-- 			end
	-- 		end

	-- 	else

	-- 		BattleUtils.PrintBattleWaringLog(string.format('cannot find the skill trigger type -> %s', k))

	-- 	end
	-- end

	-- return result
end
--[[
是否触发事件
@params skillId int 技能id
--]]
function BaseCastDriver:TriggerEvent(skillId)
	local skillInfo = CommonUtils.GetSkillConf(skillId)
	local skillType = checkint(skillInfo.property)
	if ConfigSkillType.SKILL_HALO == skillType then

		-- 光环技能 不触发事件
		self:OnCastEnter(skillId)

	elseif ConfigSkillType.SKILL_CUTIN == skillType then

		-- ### 隐藏二号技能的ci ### -- 
		-- -- 二号技能 显示ci
		-- local tag = BMediator:GetBData():getCISceneTag()
		-- local ciScene = BMediator:ShowCIScene({
		-- 	tag = tag,
		-- 	drawInfo = {drawId = self.view.spineId, breakLevel = self.args.cardInfo.blv},
		-- 	startCB = function ()
		-- 		BMediator:PauseTimer()
		-- 		BMediator:PauseBattleObjs()
		-- 	end,
		-- 	overCB = function ()
		-- 		BMediator:ResumeTimer()
		-- 		BMediator:ResumeBattleObjs()
		-- 		self:CastBegin(self.castingSkillId)
		-- 	end,
		-- 	dieCB = function ()
		-- 		self.ciScene = nil
		-- 		BMediator:GetBData().ciScenes.pause[tostring(tag)] = nil
		-- 	end
		-- })
		-- self.ciScene = ciScene
		-- ### 隐藏二号技能的ci ### -- 

		-- ci技能 不做处理
		self:OnCastEnter(skillId)

	elseif ConfigSkillType.SKILL_CONNECT == skillType then

		-- 连携技 出现连携技ci
		local otherHeadPaths = {}
		local connectCardIds = self.skills[tostring(skillId)].connectCardId
		if nil ~= connectCardIds then
			local o = nil
			for i, cardId in ipairs(connectCardIds) do
				o = BMediator:IsObjAliveByCardId(cardId)
				if o then
					local skinConfig = CardUtils.GetCardSkinConfig(o:getOSkinId())
					if nil ~= skinConfig then
						table.insert(otherHeadPaths, o:getDrawPathInfo().headPath)
					end
				end
			end
		end

		local tag = BMediator:GetBData():getCISceneTag()
		local ciScene = BMediator:ShowCIScene({
			tag = tag,
			mainSkinId = self:GetOwner():getOSkinId(),
			otherHeadPaths = otherHeadPaths,
			startCB = function ()
				-- 卡牌连携技 出现语音
				CommonUtils.PlayCardSoundByCardId(self:GetOwner():getOCardId(), SoundType.TYPE_SKILL2)
				-- 屏蔽触摸
				BMediator:SetBattleTouchEnable(false)

				------------ 暂停游戏进程 ------------				
				BMediator:PauseTimer()
				BMediator:PauseNormalCIScene()
				BMediator:PauseBattleObjs()
				------------ 暂停游戏进程 ------------
			end,
			overCB = function ()
				------------ 恢复游戏进程 ------------
				BMediator:ResumeTimer()
				BMediator:ResumeNormalCIScene()
				BMediator:ResumeBattleObjs()
				------------ 恢复游戏进程 ------------

				-- 恢复触摸
				BMediator:SetBattleTouchEnable(true)

				self:OnCastEnter(skillId)

				-- 显示连携技高亮
				local targets = self.skills[tostring(skillId)].skill:GetTargetPool()
				self:ConnectSkillHighlightStart(skillId, targets)
			end,
			dieCB = function ()
				self:GetOwner().ciScene = nil
				BMediator:GetBData().ciScenes.pause[tostring(tag)] = nil
			end
		})
		self:GetOwner().ciScene = ciScene

	elseif ConfigSkillType.SKILL_WEAK == skillType then

		-- 显示弱点场景
		local time = checknumber(skillInfo.readingTime or 3)
		local tag = BMediator:GetBData():getCISceneTag()
		local weakScene = BMediator:ShowBossWeak({
			skillId = skillId,
			tag = tag,
			o = self:GetOwner(),
			weakPoints = self.skills[tostring(skillId)].weakPoints,
			time = time,
			overCB = function (result)
				self:ChantClickHandler(result)
				self:GetOwner().ciScene = nil
			end,
			dieCB = function ()
				self:GetOwner().ciScene = nil
				BMediator:GetBData().ciScenes.normal[tostring(tag)] = nil
			end
		})
		-- 加上boss弱点层动画时间
		self:OnChantEnter(skillId, time + 1)
		self:GetOwner().ciScene = weakScene

	else

		-- 正常执行施法
		self:OnCastEnter(skillId)

	end
end
--[[
连携技高亮处理
@params skillId int 技能id
@params targets table 连携技即将作用的目标
--]]
function BaseCastDriver:ConnectSkillHighlightStart(skillId, targets)
	BMediator.connectSkillHighlightEvent:OnEventEnter(skillId, self:GetOwner():getOTag(), targets)
end
--[[
连携技高亮结束
--]]
function BaseCastDriver:ConnectSkillHighlightOver(skillId)
	BMediator.connectSkillHighlightEvent:OnEventExit(skillId, self:GetOwner():getOTag())
end
--[[
准备施法
@params skillId int 技能id
--]]
function BaseCastDriver:OnCastEnter(skillId)
	local skillConfig = CommonUtils.GetSkillConf(skillId)
	local skillType = checkint(skillConfig.property)

	---------- logic ----------
	-- 施法回调事件
	BMediator:SendObjEvent(ObjectEvent.OBJECT_CAST_ENTER, {
		tag = self:GetOwner():getOTag(), isEnemy = self:GetOwner():isEnemy(true), skillId = skillId
	})

	---------- 触发器 ----------
	-- 施法
	self:GetOwner().triggerDriver:OnActionEnter(ConfigObjectTriggerActionType.CAST)
	local castActionTriggerConfig = {
		[ConfigSkillType.SKILL_NORMAL] = ConfigObjectTriggerActionType.CAST_SKILL_NORMAL,
		[ConfigSkillType.SKILL_CUTIN] = ConfigObjectTriggerActionType.CAST_SKILL_CUTIN,
		[ConfigSkillType.SKILL_CONNECT] = ConfigObjectTriggerActionType.CAST_SKILL_CONNECT
	}
	if castActionTriggerConfig[skillType] then
		self:GetOwner().triggerDriver:OnActionEnter(castActionTriggerConfig[skillType])
	end
	---------- 触发器 ----------

	---------- logic ----------

	---------- view ----------
	-- 取动作名
	local castAnimationName = self:GetOwner().spineActionData[tostring(skillId)].actionName
	if not self:GetOwner().view.animationsData[castAnimationName] then
		castAnimationName = sp.AnimationName.skill1
	end

	self:GetOwner():DoSpineAnimation(
		true, self:GetOwner():getAvatarTimeScale(true),
		castAnimationName, false, sp.AnimationName.idle, true
	)
	---------- view ----------

	------------ sound effect ------------
	PlayBattleEffects(self:GetOwner().spineActionData[tostring(skillId)].actionSE)
	PlayBattleEffects(self:GetOwner().spineActionData[tostring(skillId)].actionVoice)
	------------ sound effect ------------

	local params = ObjectCastParameterStruct.New(
		self:GetNextSkillExtra(skillId),
		1,
		nil,
		cc.p(0, 0),
		false,
		self:GetOwner():isHighlight()
	)
	self.skills[tostring(skillId)].skill:CastBegin(params)
end
--[[
施法逻辑
@params skillId int 技能id
@params percent number 伤害占比 分段伤害用
--]]
function BaseCastDriver:Cast(skillId, percent)
	local bulletOriPosition = self:GetOwner():getLocation().po
	local boneData = self:GetOwner():findBoneInWorldSpace(sp.CustomName.BULLET_BONE_NAME)
	if boneData then
		bulletOriPosition = cc.p(boneData.worldPosition.x, boneData.worldPosition.y)
	end
	local shouldShakeWorld = false
	if nil ~= self:GetOwner().curClickedWeakPointId and ConfigWeakPointId.NONE == self:GetOwner().curClickedWeakPointId then
		shouldShakeWorld = true
	end

	local params = ObjectCastParameterStruct.New(
		1,
		percent,
		nil,
		bulletOriPosition,
		shouldShakeWorld,
		self:GetOwner():isHighlight()
	)
	self.skills[tostring(skillId)].skill:Cast(params)

	------------ sound effect ------------
	PlayBattleEffects(self:GetOwner().spineActionData[tostring(skillId)].actionCauseSE)
	------------ sound effect ------------
end
--[[
施法结束
--]]
function BaseCastDriver:OnCastExit()
	local skillConf = CommonUtils.GetSkillConf(self:GetOwner().castingSkillId)

	if BMediator:IsCardVSCard() then

		if not self:GetOwner():isEnemy(true) then
			if ConfigSkillType.SKILL_CONNECT == checkint(skillConf.property) then
				self:ConnectSkillHighlightOver(self:GetOwner().castingSkillId)
			end
		end

	else

		if ConfigSkillType.SKILL_CONNECT == checkint(skillConf.property) then
			self:ConnectSkillHighlightOver(self:GetOwner().castingSkillId)
		end

	end

	------------ 重置一些参数 ------------
	self:ClearNextSkillExtra(self:GetOwner().castingSkillId)
	self:SetCastingEcho(false)
	------------ 重置一些参数 ------------

	self:GetOwner():setState(self:GetOwner():getState(-1))
	self:GetOwner():setState(OState.NORMAL, -1)
	self:GetOwner().castingSkillId = nil
end
--[[
施法被打断
--]]
function BaseCastDriver:OnCastBreak()
	self:OnCastExit()

	self:GetOwner():DoSpineAnimation(true, self:GetOwner():getAvatarTimeScale(true), sp.AnimationName.idle, true)
end
--[[
准备读条
@params skillId int 技能id
@params time number 读条时间
--]]
function BaseCastDriver:OnChantEnter(skillId, time)
	---------- logic ----------
	-- 设置读条时长
	self.chantCountdown = time
	-- 读条时免疫控制
	self:GetOwner():setImmune(BKIND.STUN, true)
	self:GetOwner():setImmune(BKIND.SILENT, true)
	self:GetOwner():setImmune(BKIND.FREEZE, true)
	self:GetOwner():setImmune(BKIND.ENCHANTING, true)
	-- 发送事件
	BMediator:SendObjEvent(ObjectEvent.OBJECT_CHANT_ENTER, {
		tag = self:GetOwner():getOTag(), isEnemy = self:GetOwner():isEnemy(), skillId = skillId
	})
	---------- logic ----------

	---------- view ----------
	self:GetOwner():DoSpineAnimation(true, nil, sp.AnimationName.chant, true)

	-- 设置变色
	self:GetOwner().tintDriver:OnActionEnter(BattleObjTintPattern.BOTP_DARK)
	---------- view ----------
end
--[[
读条进行中
@params dt number delta time
--]]
function BaseCastDriver:OnChantUpdate(dt)

end
--[[
读条结束
@params skillId int 技能id
--]]
function BaseCastDriver:OnChantExit(skillId)
	---------- view ----------
	-- 设置变色
	self:GetOwner().tintDriver:OnActionExit()
	---------- view ----------
	
	---------- logic ----------
	-- 清空读条时间
	self.chantCountdown = nil
	-- 恢复读条时免疫控制
	self:GetOwner():setImmune(BKIND.STUN, false)
	self:GetOwner():setImmune(BKIND.SILENT, false)
	self:GetOwner():setImmune(BKIND.FREEZE, false)
	self:GetOwner():setImmune(BKIND.ENCHANTING, false)
	-- 显示boss技能cutin
	if ConfigMonsterType.BOSS == checkint(self:GetOwner():getObjectConfig().type) then

		if ConfigWeakPointId.HALF_EFFECT == self:GetOwner().curClickedWeakPointId then

			-- 打断一半不会出boss技能ci
			self:OnCastEnter(skillId)

		else

			-- 显示boss cutin场景
			local tag = BMediator:GetBData():getCISceneTag()
			local ciScene = BMediator:ShowBossCIScene({
				tag = tag,
				mainSkinId = self:GetOwner():getOSkinId(),
				startCB = function ()
					-- 屏蔽触摸
					BMediator:SetBattleTouchEnable(false)

					------------ 暂停游戏进程 ------------
					BMediator:PauseTimer()
					BMediator:PauseNormalCIScene()
					BMediator:PauseBattleObjs()
					------------ 暂停游戏进程 ------------
				end,
				overCB = function ()
					------------ 恢复游戏进程 ------------
					BMediator:ResumeTimer()
					BMediator:ResumeNormalCIScene()
					BMediator:ResumeBattleObjs()
					------------ 恢复游戏进程 ------------

					-- 恢复触摸
					BMediator:SetBattleTouchEnable(true)

					self:OnCastEnter(skillId)
					self:GetOwner().ciScene = nil
				end,
				dieCB = function ()
					BMediator:GetBData().ciScenes.pause[tostring(tag)] = nil
				end
			})

		end

	else

		self:OnCastEnter(skillId)

	end
	---------- logic ----------
end
--[[
读条被打断
--]]
function BaseCastDriver:OnChantBreak()
	---------- logic ----------
	self.chantCountdown = nil
	-- 恢复读条时免疫控制
	self:GetOwner():setImmune(BKIND.STUN, false)
	self:GetOwner():setImmune(BKIND.SILENT, false)
	self:GetOwner():setImmune(BKIND.FREEZE, false)
	---------- logic ----------

	---------- view ----------
	self:GetOwner():DoSpineAnimation(
		true, nil,
		sp.AnimationName.attacked, false, sp.AnimationName.idle, true
	)

	-- 设置变色
	self:GetOwner().tintDriver:OnActionExit()
	---------- view ----------

	self:OnCastExit()
end
--[[
读条点击回调
@params table {
	skillId int 技能id
	result ciScene 返回结果 false 表示读条读完
	leftTime number 由于场景有动画 场景结束的时候会返回一个读条剩余事件
}
--]]
function BaseCastDriver:ChantClickHandler(data)
	self:GetOwner().ciScene = nil
	if false == data.result then
		self:GetOwner().curClickedWeakPointId = ConfigWeakPointId.NONE
		-- 场景结束 没有任何玩家主动触发的结果
		self:OnChantExit(data.skillId)
	else
		-- 玩家做出返回
		local effectId, effectValue = self:GetOwner().randomDriver:RandomWeakEffect(
			checkint(data.skillId),
			self:GetWeakPointsConfigBySkillId(data.skillId),
			checkint(data.result)
		)

		self:GetOwner().curClickedWeakPointId = effectId
		-- 此处重置咏唱时间 在施法前初始化的咏唱时间算上了弱点动画的持续时间 是不准确的
		self.chantCountdown = data.leftTime

		-- 显示提示文字
		self:GetOwner().view.viewComponent:showChantBreakEffect(effectId)

		if ConfigWeakPointId.BREAK == effectId then

			-- 打断
			self:OnChantBreak()
			-- self:GetOwner().view.viewComponent:showExpression(ExpressionType.EMBRARASSED)

		elseif ConfigWeakPointId.HALF_EFFECT == effectId then

			-- 效果降低
			self:SetSkillExtra(effectValue)
			-- self:GetOwner().view.viewComponent:showExpression(ExpressionType.SWEAT)

		elseif ConfigWeakPointId.NONE == effectId then

			-- 无效果
			-- self:GetOwner().view.viewComponent:showExpression(ExpressionType.PLEASED)

		end
	end
end
--[[
初始化所有光环效果
--]]
function BaseCastDriver:CastAllHalos()
	-- ### serialized ### --
	local params = ObjectCastParameterStruct.New(
		1,
		1,
		nil,
		cc.p(0, 0),
		false,
		false
	)
	for i, sid in ipairs(self.skills.halo) do
		self.skills[tostring(sid)].skill:CastBegin(params)
	end
end
--[[
刷新触发器
@params actionTriggerType ActionTriggerType 技能触发类型
@params delta number 变化量
--]]
function BaseCastDriver:UpdateActionTrigger(actionTriggerType, delta)
	if ActionTriggerType.CD == actionTriggerType then

		-- 刷新技能cd
		for k,v in pairs(self.actionTrigger[ActionTriggerType.CD]) do
			self.actionTrigger[ActionTriggerType.CD][k] = math.max(0, v - delta)
		end
		-- 刷新内置cd
		for k,v in pairs(self.skillInsideCountdown) do
			self.skillInsideCountdown[k] = math.max(0, v - delta)
		end
		-- 刷新读条时间
		if nil ~= self.chantCountdown then
			self.chantCountdown = math.max(0, self.chantCountdown - delta)
		end

	elseif ActionTriggerType.HP == actionTriggerType then

		-- 刷新损失血量触发器
		self.actionTrigger[ActionTriggerType.HP] = 1 - delta

	end
end
--[[
消耗做出行为需要的资源
@params skillId int 技能id
--]]
function BaseCastDriver:CostActionResources(skillId)
	if self:GetCastingEcho() then
		-- 释放回响技能 不消耗常规资源 删除下一个回响技能
		self:RemoveNextEchoSkill()
	else
		-- 消耗常规资源
		local skillConf = CommonUtils.GetSkillConf(skillId)
		-- 刷新技能内置cd
		self.skillInsideCountdown[tostring(skillId)] = checknumber(skillConf.insideCd)

		local skillTriggerInfo = self:GetSkillTriggerInfoBySkillId(skillId)

		if nil ~= skillTriggerInfo[ConfigSkillTriggerType.ENERGY] then

			-- 能量
			self:GetOwner():addEnergy(math.min(0, -1 * skillTriggerInfo[ConfigSkillTriggerType.ENERGY]))

		end

		if nil ~= skillTriggerInfo[ConfigSkillTriggerType.CD] then

			-- cd
			self:SetActionTrigger(
				ActionTriggerType.CD,
				skillId,
				skillTriggerInfo[ConfigSkillTriggerType.CD]
			)

		end

		if nil ~= skillTriggerInfo[ConfigSkillTriggerType.COST_HP] then

			-- 血量
			local selfTag = self:GetOwner():getOTag()
			local damage = skillTriggerInfo[ConfigSkillTriggerType.COST_HP]

			local damageData = ObjectDamageStruct.New(
				selfTag,
				damage,
				DamageType.ATTACK_PHYSICAL,
				false,
				{attackerTag = selfTag}
			)
			self:GetOwner():hpChange(damageData)

		end

		if nil ~= skillTriggerInfo[ConfigSkillTriggerType.COST_CHP] then

			-- 当前血量
			local selfTag = self:GetOwner():getOTag()
			local damage = skillTriggerInfo[ConfigSkillTriggerType.COST_CHP] * self:GetOwner():getMainProperty():getCurrentHp()

			local damageData = ObjectDamageStruct.New(
				selfTag,
				damage,
				DamageType.ATTACK_PHYSICAL,
				false,
				{attackerTag = selfTag}
			)
			self:GetOwner():hpChange(damageData)

		end

		if nil ~= skillTriggerInfo[ConfigSkillTriggerType.COST_OHP] then

			-- 最大血量
			local selfTag = self:GetOwner():getOTag()
			local damage = skillTriggerInfo[ConfigSkillTriggerType.COST_OHP] * self:GetOwner():getMainProperty():getOriginalHp()

			local damageData = ObjectDamageStruct.New(
				selfTag,
				damage,
				DamageType.ATTACK_PHYSICAL,
				false,
				{attackerTag = selfTag}
			)
			self:GetOwner():hpChange(damageData)

		end
	end

	-- 增加一次技能施放计数
	self:AddSkillCastCounter(skillId)
end
--[[
重置所有触发器
--]]
function BaseCastDriver:ResetActionTrigger()
	self.chantCountdown = nil
end
--[[
操作触发器
--]]
function BaseCastDriver:GetActionTrigger(actionTriggerType, skillId)
	if nil ~= self.actionTrigger[actionTriggerType] and nil ~= skillId then
		return self.actionTrigger[actionTriggerType][tostring(skillId)]
	elseif nil ~= actionTriggerType then
		return self.actionTrigger[actionTriggerType]
	end
	return nil
end
function BaseCastDriver:SetActionTrigger(actionTriggerType, skillId, value)
	if nil ~= self.actionTrigger[actionTriggerType] and nil ~= skillId then
		self.actionTrigger[actionTriggerType][tostring(skillId)] = value
	end
	return nil
end
---------------------------------------------------
-- control logic begin --
---------------------------------------------------

---------------------------------------------------
-- handler logic begin --
---------------------------------------------------
--[[
spine动画事件消息处理
--]]
function BaseCastDriver:SpineAnimationEventHandler(event)

end
--[[
spine动画自定义事件消息处理
--]]
function BaseCastDriver:SpineCustomEventHandler(event)

end
---------------------------------------------------
-- handler logic end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
本场战斗是否激活了连携技
--]]
function BaseCastDriver:HasConnectSkill()
	return self.hasConnectSkill
end
--[[
获取连携技
@return _ table 连携技合集
--]]
function BaseCastDriver:GetConnectSkills()
	-- return self.skills.connect
	return self.skills.equipedConnect
end
--[[
根据id获取技能模型
@params skillId int 技能id
--]]
function BaseCastDriver:GetSkillBySkillId(skillId)
	return self.skills[tostring(skillId)]
end
--[[
是否处于读条状态
@return _ int 是否处于读条状态 1 正在读条 0 读条结束 2 不处于读条状态
--]]
function BaseCastDriver:IsInChanting()
	if OState.CASTING == self:GetOwner():getState() and nil ~= self.chantCountdown then
		if 0 < self.chantCountdown then
			return 1
		else
			return 0
		end
	else
		return 2
	end
end
--[[
初始化技能数据结构
--]]
function BaseCastDriver:InitSkills()
	local cardConf = self:GetOwner():getObjectConfig()

	self.actionTrigger = {
		[ActionTriggerType.CD] = {},
		[ActionTriggerType.HP] = 0
	}

	-- 技能结构 分类表只保存技能id
	self.skills = {
		attack = {},
		cd = {},
		halo = {},
		connect = {},
		equipedConnect = {}
	}
	-- 技能替换规则
	self.innerSkillChangeRule = {
		connect2ci = {}
	}

	-- 技能内置cd
	self.skillInsideCountdown = {}

	-- 技能充能计数
	self.skillChargeCounter = {}

	-- 连携技额外充能计数
	self.connectSkillChargeCounter = {}

	-- 技能的触发条件
	self.skillTriggerInfo = {}

	local sid = 0
	local skillConf = nil
	local isSkillEnable = true
	local skillType = 0

	local effect = CardUtils.GetCardEffectConfigBySkinId(self:GetOwner():getOCardId(), self:GetOwner():getOSkinId())

	for i, sconf in ipairs(cardConf.skill) do
		sid = checkint(sconf)
		skillConf = CommonUtils.GetSkillConf(sid)
		isSkillEnable = true

		if nil == skillConf then
			print('skill not found>>>>>' .. sid, self:GetOwner():getOCardId())
		else
			skillType = checkint(skillConf.property)
			local skillClassPath = 'battle.skill.ObjSkill'
			local extraInfo = {}

			---------- 处理一次内部触发条件 ----------
			local triggerInfo = {}
			for triggerType, triggerValue in pairs(skillConf.triggerType) do
				triggerInfo[checkint(triggerType)] = checknumber(triggerValue)
			end
			self.skillTriggerInfo[tostring(sid)] = triggerInfo
			---------- 处理一次内部触发条件 ----------

			if nil ~= skillConf.triggerType[tostring(ConfigSkillTriggerType.CD)] then

				-- 具有cd触发类型的技能
				table.insert(self.skills.cd, sid) -- 有序队列 优先级不同
				self.actionTrigger[ActionTriggerType.CD][tostring(sid)] = checknumber(skillConf.triggerType[tostring(ConfigSkillTriggerType.CD)])

			else

				if ConfigSkillType.SKILL_NORMAL == skillType then

					-- 非cd技能 由普通攻击触发的技能
					table.insert(self.skills.attack, sid)

				elseif ConfigSkillType.SKILL_HALO == skillType then

					table.insert(self.skills.halo, sid)
					skillClassPath = 'battle.skill.HaloSkill'

				elseif ConfigSkillType.SKILL_CUTIN == skillType then

					table.insert(self.skills.attack, sid)

				elseif ConfigSkillType.SKILL_CONNECT == skillType and BMediator:CanUseFriendConnectSkill() then

					-- 连携技 判断是否满足释放连携技的条件
					local canCastConnect = true
					if BMediator:IsCardVSCard() and self:GetOwner():isEnemy(true) then
						-- 敌方卡牌不自动释放连携技
						canCastConnect = false

					else

						for i,v in ipairs(cardConf.concertSkill) do
							if false == BMediator:IsCardInTeam(v, self:GetOwner():isEnemy(true)) then
								isSkillEnable = false
								canCastConnect = false
								break
							else
								if nil == extraInfo.connectCardId then
									extraInfo.connectCardId = {}
								end
								table.insert(extraInfo.connectCardId, checkint(v))
							end
						end

					end

					if canCastConnect then
						table.insert(self.skills.connect, sid)
						table.insert(self.skills.equipedConnect, sid)
						self.connectSkillChargeCounter[tostring(sid)] = 0

						if BMediator:AutoUseFriendConnectSkill() then
							table.insert(self.skills.attack, sid)
						end
					end

				elseif ConfigSkillType.SKILL_WEAK == checkint(skillConf.property) then

					-- 弱点技能
					table.insert(self.skills.attack, sid)

				end

			end

			-- 如果技能可用 再去创建技能模型
			if isSkillEnable then

				-- 初始化内置cd 第一次初始化为0
				self.skillInsideCountdown[tostring(sid)] = 0

				if ConfigSkillType.SKILL_WEAK == skillType then

					-- 初始化弱点信息
					extraInfo.weakPoints = {}

					for i,v in ipairs(skillConf.weaknessEffect) do
						local effectId = checkint(v[1])
						local effectValue = checknumber(v[2])
						local weakPoint = {id = i, effectId = effectId, effectValue = effectValue}
						table.insert(extraInfo.weakPoints, weakPoint)
					end
				end

				-- 初始化技能动作 特效信息
				local spineActionData = SkillSpineEffectStruct.New(sid, effect)

				-- 创建skill模型
				local skillLevel = 1
				if nil ~= self:GetOwner().objInfo.skillData and nil ~= self:GetOwner().objInfo.skillData[tostring(sid)] then
					skillLevel = checkint(self:GetOwner().objInfo.skillData[tostring(sid)].level)
				end

				-- dump(self:GetOwner().objInfo.skillData)

				local skillBaseData = SkillConstructorStruct.New(
					sid,
					skillLevel,
					BattleUtils.GetSkillInfoStructBySkillId(sid, skillLevel),
					self:GetOwner():isEnemy(true),
					self:GetOwner():getOTag(),
					spineActionData
				)
				local skill = __Require(skillClassPath).new(skillBaseData)

				local skillInfo = ObjectSkillStruct.New(sid, skill, extraInfo)
				self.skills[tostring(sid)] = skillInfo
				self.skillChargeCounter[tostring(sid)] = 0
				self:GetOwner().spineActionData[tostring(sid)] = spineActionData
			end

		end
	end

	---------- new logic 连携技不会彻底替换ci 连携技失效后会释放2技能 ----------
	-- 如果激活了连携技 初始化一次技能重新装填的数据
	if 0 < #self.skills.connect then
		local connectSkillId = nil
		for i = #self.skills.connect, 1, -1 do
			connectSkillId = self.skills.connect[i]
			break
		end

		local ciSkillId = nil
		for i = #self.skills.attack, 1, -1 do
			local skillId = self.skills.attack[i]
			if ConfigSkillType.SKILL_CUTIN == checkint(CommonUtils.GetSkillConf(skillId).property) then
				ciSkillId = skillId
				table.remove(self.skills.attack, i)
				break
			end
		end

		local connect2ciData = {connectSkillId = connectSkillId, ciSkillId = ciSkillId}
		self.innerSkillChangeRule.connect2ci = connect2ciData
		-- dump(self.innerSkillChangeRule)
	end
	---------- new logic 连携技不会彻底替换ci 连携技失效后会释放2技能 ----------

	---------- old logic 连携技会彻底替换ci 连携技失效后不会再释放2技能 ----------
	-- -- 初始化结束 如果存在可以释放的连携技 则清空cutin
	-- if table.nums(self.skills.connect) > 0 then
	-- 	self.hasConnectSkill = true
	-- 	local ciSkillId = 0
	-- 	for i = #self.skills.attack, 1, -1 do
	-- 		ciSkillId = self.skills.attack[i]
	-- 		if ConfigSkillType.SKILL_CUTIN == checkint(CommonUtils.GetSkillConf(ciSkillId).property) then
	-- 			-- 移除缓存的ci技能数据
	-- 			if self.skills[tostring(ciSkillId)] then
	-- 				self.skills[tostring(ciSkillId)].skill = nil
	-- 				self.skills[tostring(ciSkillId)] = nil
	-- 			end
	-- 			table.remove(self.skills.attack, i)
	-- 		end
	-- 	end
	-- end
	---------- old logic 连携技会彻底替换ci 连携技失效后不会再释放2技能 ----------

	-- dump(self.skills)
	-- dump(self.actionTrigger)
	-- dump(self:GetOwner().spineActionData)
	-- dump(self.skillTriggerInfo)
end
--[[
刷新一次连携技替换
@params enableConnectSkill bool 是否需要启用连携技
--]]
function BaseCastDriver:InnerChangeConnectSkill(enableConnectSkill)
	if enableConnectSkill then

		---------- 将连携技加入逻辑缓存 ----------
		local connectSkillId = checkint(self.innerSkillChangeRule.connect2ci.connectSkillId)
		if 0 ~= connectSkillId then
			local isSkillExist = false
			for i = #self.skills.connect, 1, -1 do
				if connectSkillId == self.skills.connect[i] then
					isSkillExist = true
					break
				end
			end

			if not isSkillExist then
				table.insert(self.skills.connect, connectSkillId)
			else
				-- BattleUtils.PrintConfigLogicError('here enable connect skill but this skill already in use -> skillId : ' .. connectSkillId)
			end
		end
		---------- 将连携技加入逻辑缓存 ----------

		---------- 将ci技移出逻辑缓存 ----------
		local ciSkillId = checkint(self.innerSkillChangeRule.connect2ci.ciSkillId)
		if 0 ~= ciSkillId then
			isSkillExist = false
			for i = #self.skills.attack, 1, -1 do
				if ciSkillId == self.skills.attack[i] then
					isSkillExist = true
					table.remove(self.skills.attack, i)
					break
				end
			end

			if not isSkillExist then
				-- BattleUtils.PrintConfigLogicError('here disable ci skill but this skill not in use -> skillId : ' .. ciSkillId)
			end
		end
		---------- 将ci技移出逻辑缓存 ----------

	else

		---------- 将连携技移出逻辑缓存 ----------
		local connectSkillId = checkint(self.innerSkillChangeRule.connect2ci.connectSkillId)
		if 0 ~= connectSkillId then
			local isSkillExist = false
			for i = #self.skills.connect, 1, -1 do
				if connectSkillId == self.skills.connect[i] then
					isSkillExist = true
					table.remove(self.skills.connect, i)
					break
				end
			end

			if not isSkillExist then
				-- BattleUtils.PrintConfigLogicError('here disable connect skill but this skill not in use -> skillId : ' .. connectSkillId)
			end
		end
		---------- 将连携技移出逻辑缓存 ----------

		---------- 将ci技加入逻辑缓存 ----------
		local ciSkillId = checkint(self.innerSkillChangeRule.connect2ci.ciSkillId)
		if 0 ~= ciSkillId then
			isSkillExist = false
			for i = #self.skills.attack, 1, -1 do
				if ciSkillId == self.skills.attack[i] then
					isSkillExist = true
					break
				end
			end

			if not isSkillExist then
				table.insert(self.skills.attack, ciSkillId)
			else
				-- BattleUtils.PrintConfigLogicError('here enable ci skill but this skill already in use -> skillId : ' .. ciSkillId)
			end
		end
		---------- 将ci技加入逻辑缓存 ----------

	end

	-- dump(self.skills.connect)
	-- dump(self.skills.attack)
end
--[[
根据技能信息增加技能数据结构
@params skillData list {
	{skillId = nil, level = nil},
	{skillId = nil, level = nil},
	{skillId = nil, level = nil}
	...
}
--]]
function BaseCastDriver:AddSkillsBySkillData(skillData)
	for _,v in ipairs(skillData) do
		self:AddASkill(checkint(v.skillId), checkint(v.level))
	end
end
--[[
向驱动中添加一个技能
@params skillId int 技能id
@params level int 技能等级
--]]
function BaseCastDriver:AddASkill(skillId, level)
	local skillConfig = CommonUtils.GetSkillConf(skillId)
	if nil == skillConfig then
		print('skill not found in castDriver >>>>>' .. skillId, self:GetOwner():getOCardId())
		return
	end

	if not self:CanInitSkillBySkillId(checkint(skillId)) then return end

	local skillClassPath = 'battle.skill.ObjSkill'
	local isSkillEnable = true
	local skillType = checkint(skillConfig.property)

	---------- 处理一次内部触发条件 ----------
	local triggerInfo = {}
	for triggerType, triggerValue in pairs(skillConfig.triggerType) do
		triggerInfo[checkint(triggerType)] = checknumber(triggerValue)
	end
	self:SetSkillTriggerInfoBySkillId(skillId, triggerInfo)

	if nil ~= triggerInfo[ConfigSkillTriggerType.CD] then
		-- 存在cd触发的技能 初始化一次cd触发器
		table.insert(self.skills.cd, skillId)
		self.actionTrigger[ActionTriggerType.CD][tostring(skillId)] = triggerInfo[ConfigSkillTriggerType.CD]
	end
	---------- 处理一次内部触发条件 ----------

	---------- 处理技能触发缓存 ----------
	if ConfigSkillType.SKILL_NORMAL == skillType then

		-- 非cd技能 由普通攻击触发的技能
		table.insert(self.skills.attack, skillId)

	elseif ConfigSkillType.SKILL_HALO == skillType then

		-- 光环技能
		table.insert(self.skills.halo, skillId)
		skillClassPath = 'battle.skill.HaloSkill'

	elseif ConfigSkillType.SKILL_CUTIN == skillType then

		-- 能量ci技能
		table.insert(self.skills.attack, skillId)

	elseif ConfigSkillType.SKILL_CONNECT == skillType and BMediator:CanUseFriendConnectSkill() then

		-- 连携技 判断是否满足释放连携技的条件
		local canCastConnect = true

		if BMediator:IsCardVSCard() and self:GetOwner():isEnemy(true) then

			-- 敌方卡牌不自动释放连携技
			canCastConnect = false
			isSkillEnable = false

		else

			local cardConfig = self:GetOwner():getObjectConfig()
			if nil ~= cardConfig then
				for _, connectCardId in ipairs(cardConfig.concertSkill) do

					if false == BMediator:IsCardInTeam(connectCardId, self:GetOwner():isEnemy(true)) then
						-- 连携对象不在队伍中
						isSkillEnable = false
						canCastConnect = false
						break
					else
						if nil == extraInfo.connectCardId then
							extraInfo.connectCardId = {}
						end
						table.insert(extraInfo.connectCardId, checkint(connectCardId))
					end

				end

				if canCastConnect then
					-- 激活连携技
					table.insert(self.skills.connect, skillId)
					table.insert(self.skills.equipedConnect, skillId)
					self.connectSkillChargeCounter[tostring(skillId)] = 0

					if BMediator:AutoUseFriendConnectSkill() then
						table.insert(self.skills.attack, skillId)
					end
				end
			end
		end

	elseif ConfigSkillType.SKILL_WEAK == skillType then

		-- 弱点技能
		table.insert(self.skills.attack, skillId)

		-- 初始化弱点信息
		extraInfo.weakPoints = {}

		for i,v in ipairs(skillConfig.weaknessEffect) do
			local effectId = checkint(v[1])
			local effectValue = checknumber(v[2])
			local weakPoint = {id = i, effectId = effectId, effectValue = effectValue}
			table.insert(extraInfo.weakPoints, weakPoint)
		end

	end
	---------- 处理技能触发缓存 ----------	

	---------- 创建技能模型 ----------	
	if isSkillEnable then

		-- 初始化内置cd 第一次初始化为0
		self.skillInsideCountdown[tostring(skillId)] = 0

		-- 初始化技能动作 特效信息
		local effect = CardUtils.GetCardEffectConfigBySkinId(self:GetOwner():getOCardId(), self:GetOwner():getOSkinId())
		local spineActionData = SkillSpineEffectStruct.New(skillId, effect)

		local skillBaseData = SkillConstructorStruct.New(
			skillId,
			level,
			BattleUtils.GetSkillInfoStructBySkillId(skillId, level),
			self:GetOwner():isEnemy(true),
			self:GetOwner():getOTag(),
			spineActionData
		)
		local skill = __Require(skillClassPath).new(skillBaseData)
		local skillInfo = ObjectSkillStruct.New(skillId, skill, extraInfo)
		self.skills[tostring(skillId)] = skillInfo
		self.skillChargeCounter[tostring(skillId)] = 0
		self:GetOwner().spineActionData[tostring(skillId)] = spineActionData

	end
	---------- 创建技能模型 ----------

end
--[[
根据技能id获取有序弱点配置
@params skillId int 技能id
@return _ array 有序弱点配置
--]]
function BaseCastDriver:GetWeakPointsConfigBySkillId(skillId)
	return self.skills[tostring(skillId)].weakPoints
end
--[[
检查是否满足连携技使用条件
@params skillId int 技能id
@return _ bool 是否可以使用
--]]
function BaseCastDriver:CanUseConnectSkillByCardAlive(skillId)
	for i,v in ipairs(self.skills[tostring(skillId)].connectCardId) do
		if nil == BMediator:IsObjAliveByCardId(v, self:GetOwner():isEnemy(true)) then
			return false
		end
	end
	return true
end
--[[
获取技能触发信息
@params skillId int 技能id
@return _ map {triggerType ConfigSkillTriggerType = triggerValue number}
--]]
function BaseCastDriver:GetSkillTriggerInfoBySkillId(skillId)
	return self.skillTriggerInfo[tostring(skillId)]
end
--[[
设置技能的触发信息
@params skillId int 技能id
@params triggerInfo map {triggerType ConfigSkillTriggerType = triggerValue number}
--]]
function BaseCastDriver:SetSkillTriggerInfoBySkillId(skillId, triggerInfo)
	if nil == self:GetSkillTriggerInfoBySkillId(skillId) then
		 self.skillTriggerInfo[tostring(skillId)] = triggerInfo
	end
end
--[[
添加技能触发信息
@params skillId int 技能id
@params triggerInfoList list {
	{triggerType = nil, triggerValue = nil},
	{triggerType = nil, triggerValue = nil},
	{triggerType = nil, triggerValue = nil},
	...
}
--]]
function BaseCastDriver:AddSkillTriggerInfo(skillId, triggerInfoList)
	local skillTriggerInfo = self:GetSkillTriggerInfoBySkillId(skillId)
	if nil ~= skillTriggerInfo then
		for i,v in ipairs(triggerInfoList) do
			if nil == skillTriggerInfo[v.triggerType] then
				-- 没有该触发类型 新建一次
				skillTriggerInfo[v.triggerType] = 0
			end
			skillTriggerInfo[v.triggerType] = skillTriggerInfo[v.triggerType] + v.triggerValue
		end
	end
end
--[[
移除技能触发信息
@params skillId int 技能id
@params triggerInfoList list {
	{triggerType = nil, triggerValue = nil},
	{triggerType = nil, triggerValue = nil},
	{triggerType = nil, triggerValue = nil},
	...
}
--]]
function BaseCastDriver:RemoveSkillTriggerInfo(skillId, triggerInfoList)
	local skillTriggerInfo = self:GetSkillTriggerInfoBySkillId(skillId)
	if nil ~= skillTriggerInfo then
		for i,v in ipairs(triggerInfoList) do
			if nil ~= skillTriggerInfo[v.triggerType] then
				skillTriggerInfo[v.triggerType] = skillTriggerInfo[v.triggerType] - v.triggerValue
			end
		end
	end
end
--[[
获取施法的技能次数
@params skillId int 施法的技能次数
@return _ int 次数
--]]
function BaseCastDriver:GetSkillCastCounter(skillId)
	if nil == skillId then
		return self.skillCastCounter
	else
		return self.skillCastCounter[tostring(skillId)] or 0
	end
end
--[[
增加施法的技能次数
@params skillId int 技能id
@params delta int 次数
--]]
function BaseCastDriver:AddSkillCastCounter(skillId, delta)
	if nil == self.skillCastCounter[tostring(skillId)] then
		self.skillCastCounter[tostring(skillId)] = 0
	end
	self.skillCastCounter[tostring(skillId)] = self.skillCastCounter[tostring(skillId)] + (delta or 1)
end
--[[
获取技能最终伤害加成系数
@params skillId int 技能id
@return _ number 技能最终伤害加成
--]]
function BaseCastDriver:GetNextSkillExtra(skillId)
	local skillConfig = CommonUtils.GetSkillConf(skillId)
	local skillType = checkint(skillConfig.property)

	------------ 计算buff带来的增伤效果 ------------
	local value = 0
	local buffTypes = {
		ConfigBuffType.ENHANCE_NEXT_SKILL
	}
	for i, buffType in ipairs(buffTypes) do
		local targetBuffs = self:GetOwner():GetBuffsByBuffType(buffType, false)
		for i = #targetBuffs, 1, -1 do
			value = value + targetBuffs[i]:OnCauseEffectEnter(skillType)
		end
	end
	------------ 计算buff带来的增伤效果 ------------

	return math.max(0, self:GetSkillExtra() + value)
end
--[[
重置技能最终伤害加成系数
--]]
function BaseCastDriver:ClearNextSkillExtra()
	self:SetSkillExtra(1)
end
--[[
获取技能加成系数
--]]
function BaseCastDriver:GetSkillExtra()
	return self.skillExtra
end
function BaseCastDriver:SetSkillExtra(value)
	self.skillExtra = value
end
--[[
添加一个下一次回响施法的技能
@params skillId int 回响施法的技能
--]]
function BaseCastDriver:AddAEchoSkill(skillId)
	table.insert(self.castEchoSkillId, 1, skillId)
end
--[[
获取下一个施法回响的技能id
@return _ int 技能id
--]]
function BaseCastDriver:GetNextEchoSkill()
	return self.castEchoSkillId[#self.castEchoSkillId]
end
--[[
移除下一次施法回响的技能
--]]
function BaseCastDriver:RemoveNextEchoSkill()
	if next(self.castEchoSkillId) then
		table.remove(self.castEchoSkillId, #self.castEchoSkillId)
	end
end
--[[
根据技能类型获取一个随机的技能id
@params skillType ConfigSkillType 技能类型
@return _ int 技能id 
--]]
function BaseCastDriver:GetRandomSkillIdBySkillType(skillType)
	local skillConfig = nil

	local cardConf = self:GetOwner():getObjectConfig()
	for _, skillId in ipairs(cardConf.skill) do
		skillConfig = CommonUtils.GetSkillConf(checkint(skillId))
		if nil ~= skillConfig and
			skillType == checkint(skillConfig.property) and
			nil ~= self.skills[tostring(skillId)] then

			return checkint(skillId)

		end
	end
	return nil
end
--[[
当前释放的技能是否有消耗
--]]
function BaseCastDriver:GetCastingEcho()
	return self.castingEcho
end
function BaseCastDriver:SetCastingEcho(b)
	self.castingEcho = b
end
--[[
根据技能id判断是否已经初始化过技能
@params skillId int 技能id
@return _ bool 是否初始化过技能
--]]
function BaseCastDriver:HasSkillBySkillId(skillId)
	return nil ~= self:GetSkillBySkillId(skillId)
end
--[[
根据技能id判断本场战斗该技能是否可以生效
@params skillId int 技能id
@return result bool 是否可以生效
--]]
function BaseCastDriver:CanInitSkillBySkillId(skillId)
	local result = false

	local skillConfig = CommonUtils.GetSkillConf(skillId)
	if nil ~= skillConfig and  nil ~= skillConfig.battleType then
		for _, battleType in ipairs(skillConfig.battleType) do

			if QuestBattleType.ALL == checkint(battleType) then
				result = true
				break
			elseif BMediator:GetBData():getBattleConstructData().questBattleType == checkint(battleType) then
				result = true
				break
			end

		end
	else
		return true
	end

	return result
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return BaseCastDriver
