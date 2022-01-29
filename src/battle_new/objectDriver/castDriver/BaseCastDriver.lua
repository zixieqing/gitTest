--[[
施法驱动基类
--]]
local BaseActionDriver = __Require('battle.objectDriver.BaseActionDriver')
local BaseCastDriver = class('BaseCastDriver', BaseActionDriver)

------------ import ------------
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
@override
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
	-- 释放技能的次数信息
	self.skillCastCounter = {}

	-- 技能的额外系数
	self.skillExtra = 1

	-- 是否在释放回响的技能
	self.castingEcho = false

	-- 正在释放的技能id
	self.castingSkillId = nil

	-- 技能内置cd
	self.skillInsideCountdown = {}

	-- 技能的触发条件
	self.skillTriggerInfo = {}
end
--[[
初始化独有属性
--]]
function BaseCastDriver:InitUnitValue()
	-- 点击的弱点序号缓存
	self.curClickedWeakPointId = nil

	-- 是否拥有连携技
	self.hasConnectSkill = false

	-- 读条计时
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
	BattleUtils.BattleObjectActionLog(self:GetOwner(), '准备释放技能 ->', skillId)
	---------- logic ----------
	-- 置为施法状态
	self:GetOwner():SetState(OState.CASTING)

	-- 缓存当前施法的技能id
	self:SetCastingSkillId(skillId)

	-- 缓存点击的弱点id
	self:SetCurClickedWeakPointId(nil)

	-- 消耗释放技能的资源
	self:CostActionResources(skillId)
	
	-- 触发一些事件
	self:TriggerEvent(skillId)	
	---------- logic ----------
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
	---------- 自动释放连携技时检查是否有满足释放条件的连携技 ----------
	local friendCanConnectSkill = G_BattleLogicMgr:AutoUseFriendConnectSkill() and not self:GetOwner():IsEnemy(true)
	local enemyCanConnectSkill  = G_BattleLogicMgr:AutoUseEnemyConnectSkill() and self:GetOwner():IsEnemy(true)
	if friendCanConnectSkill or enemyCanConnectSkill then
		for i, skillId in ipairs(self.skills.connect) do
			if true == self:CanCastBySkillId(skillId) then
				return skillId
			end
		end
	end
	---------- 自动释放连携技时检查是否有满足释放条件的连携技 ----------

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

	if self:CanSpell() then

		local skillConfig = CommonUtils.GetSkillConf(skillId)

		if nil ~= skillConfig then

			local skillType = checkint(skillConfig.property)

			if ConfigSkillType.SKILL_CONNECT == skillType then

				-- 连携技检测 对象是否存活
				if not self:CanUseConnectSkillByCardAlive(skillId) then
					return false
				end

				-- 普通技能检测
				if self:CanCastSkillJudgeByTriggerType(skillId) then
					result = true
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

	end

	return result
end
--[[
是否可以施法
@return _ bool 可以施法
--]]
function BaseCastDriver:CanSpell()
	return (
		self:GetOwner():CanAct() and
		not self:GetOwner():InAbnormalState(AbnormalState.SILENT) and
		not self:GetOwner():InAbnormalState(AbnormalState.ENCHANTING) and
		2 == self:IsInChanting()
	)
end
--[[
是否可以施放复活技能
@params skillId int 技能id
@return _ bool 
--]]
function BaseCastDriver:CanCastRevive(skillId)
	local skillConfig = CommonUtils.GetSkillConf(skillId)
	local isEnemy = self:GetOwner():IsEnemy()
	local canReviveCards = BattleExpression.GetDeadFriendlyTargets(
		isEnemy,
		checkint(skillConfig.target[tostring(ConfigBuffType.REVIVE)].type),
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
	return G_BattleLogicMgr:CanCreateBeckonFromBuff()
end
--[[
处理技能触发类型判定
@params skillId int 技能id
@return result bool 是否满足条件释放该技能
--]]
function BaseCastDriver:CanCastSkillJudgeByTriggerType(skillId)
	local result = true

	---------- 内置cd ----------
	local insideCD = self:GetSkillInsideCD(skillId)
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
			return (triggerValue * 1000) >= (G_BattleLogicMgr:GetRandomManager():GetRandomInt(1000))

		end,
		[ConfigSkillTriggerType.ENERGY] = function (triggerValue)

			-- 能量
			return triggerValue <= self:GetOwner():GetEnergy()

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
			return triggerValue < self:GetOwner():GetMainProperty():GetCurrentHp()

		end,
		[ConfigSkillTriggerType.COST_CHP] = function (triggerValue)

			-- 当前血量百分比
			return true

		end,
		[ConfigSkillTriggerType.COST_OHP] = function (triggerValue)

			-- 最大血量百分比
			return triggerValue < self:GetOwner():GetMainProperty():GetCurHpPercent()

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
end
--[[
是否触发事件
@params skillId int 技能id
--]]
function BaseCastDriver:TriggerEvent(skillId)
	local skillConfig = CommonUtils.GetSkillConf(skillId)
	local skillType = checkint(skillConfig.property)

	if ConfigSkillType.SKILL_HALO == skillType then

		-- 光环技能 不会触发事件
		self:OnCastEnter(skillId)

	elseif ConfigSkillType.SKILL_CUTIN == skillType then

		-- ci技能 不会触发事件
		self:OnCastEnter(skillId)

	elseif ConfigSkillType.SKILL_CONNECT == skillType then

		-- 连携技 触发连携技ci场景
		self:TriggerConnectSkillEvent(skillId)

	elseif ConfigSkillType.SKILL_WEAK == skillType then

		-- 弱点技能 读条 显示弱点场景
		self:TriggerWeakEvent(skillId)

	else

		-- 其他类型不触发事件
		self:OnCastEnter(skillId)

	end

end
--[[
触发连携技事件
@params skillId int 技能id
--]]
function BaseCastDriver:TriggerConnectSkillEvent(skillId)
	local otherHeadSkinId = {}
	local connectCardIds = self:GetSkillBySkillId(skillId).connectCardId
	if nil ~= connectCardIds then
		local obj = nil
		for _, cardId in ipairs(connectCardIds) do
			obj = G_BattleLogicMgr:IsObjAliveByCardId(cardId, self:GetOwner():IsEnemy(true))
			if nil ~= obj then
				local skinId = obj:GetObjectSkinId()
				table.insert(otherHeadSkinId, skinId)
			end
		end
	end

	local sceneTag = G_BattleLogicMgr:GetBData():GetTagByTagType(BattleTags.BT_CI_SCENE)
	local cardId = self:GetOwner():GetObjectConfigId()
	local skinId = self:GetOwner():GetObjectSkinId()
	local frame  = G_BattleLogicMgr:GetBData():GetLogicFrameIndex()

	--***---------- 刷新渲染层 ----------***--
	-- 屏蔽触摸
	G_BattleLogicMgr:SetBattleTouchEnable(false)

	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'ShowConnectSkillCIScene',
		self:GetOwner():GetOTag(), sceneTag, cardId, skinId, otherHeadSkinId, skillId, self:GetOwner():IsEnemy(true), frame, ANITIME_CUTIN_SCENE
	)
	--***---------- 刷新渲染层 ----------***--

	if G_BattleLogicMgr:IsCalculator() then
		--###---------- 刷新逻辑层 ----------###--
		G_BattleLogicMgr:AddPlayerOperate2TimeLine(
			'G_BattleLogicMgr',
			nil,
			'ConnectCISceneEnter',
			self:GetOwner():GetOTag(), skillId, sceneTag
		)
		-- 此处直接插入操作
		G_BattleLogicMgr:AddPlayerOperate2TimeLine(
			'G_BattleLogicMgr',
			ANITIME_CUTIN_SCENE,
			'ConnectCISceneExit',
			self:GetOwner():GetOTag(), skillId, sceneTag
		)
		--###---------- 刷新逻辑层 ----------###--
	end
end
--[[
连携技进入施法
@params skillId int 技能id
--]]
function BaseCastDriver:OnConnectSkillCastEnter(skillId)
	self:OnCastEnter(skillId)

	-- 设置连携技物体高亮
	local skillModel = self:GetSkillModelBySkillId(skillId)
	local targets = skillModel:GetTargetPool(targets)
	self:ConnectSkillHighlightStart(skillId, targets)
end
--[[
连携技高亮处理
@params skillId int 技能id
@params targets table 连携技即将作用的目标
--]]
function BaseCastDriver:ConnectSkillHighlightStart(skillId, targets)
	G_BattleLogicMgr:ConnectSkillHighlightEventEnter(
		skillId, self:GetOwner():GetOTag(), targets
	)
end
--[[
连携技高亮结束
--]]
function BaseCastDriver:ConnectSkillHighlightOver(skillId)
	G_BattleLogicMgr:ConnectSkillHighlightEventExit(
		skillId, self:GetOwner():GetOTag()
	)
end
--[[
触发弱点场景
@params skillId int 技能id
--]]
function BaseCastDriver:TriggerWeakEvent(skillId)
	local skillConfig = CommonUtils.GetSkillConf(skillId)

	local time = checknumber(skillConfig.readingTime or 3)
	local weakPoints = clone(self:GetSkillBySkillId(skillId).weakPoints)

	---------- 开始读条 ----------
	self:OnChantEnter(skillId, time + 1)
	---------- 开始读条 ----------

	local sceneTag = G_BattleLogicMgr:GetBData():GetTagByTagType(BattleTags.BT_CI_SCENE)

	--***---------- 刷新渲染层 ----------***--
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'ShowWeakSkillScene',
		self:GetOwner():GetOTag(), self:GetOwner():GetViewModelTag(), sceneTag, skillId, weakPoints, time
	)
	--***---------- 刷新渲染层 ----------***--
end
--[[
准备施法
@params skillId int 技能id
--]]
function BaseCastDriver:OnCastEnter(skillId)
	local skillConfig = CommonUtils.GetSkillConf(skillId)
	local skillType = checkint(skillConfig.property)

	---------- 发送物体施法事件 ----------
	G_BattleLogicMgr:SendObjEvent(ObjectEvent.OBJECT_CAST_ENTER, {
		tag = self:GetOwner():GetOTag(), isEnemy = self:GetOwner():IsEnemy(true), skillId = skillId
	})
	---------- 发送物体施法事件 ----------

	---------- 触发器 ----------
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

	---------- view ----------
	local castAnimationConfig = self:GetOwner():GetActionAnimationConfigBySkillId(skillId)
	local castAnimationName = castAnimationConfig.actionName
	if not self:GetOwner():HasAnimationByName(castAnimationName) then
		-- 添加一层容错
		castAnimationName = sp.AnimationName.skill1
	end
	-- 施法时恢复原始动画速度
	local actionTimeScale = self:GetOwner():GetAvatarTimeScale(true)
	self:GetOwner():DoAnimation(
		true, actionTimeScale,
		castAnimationName, false, sp.AnimationName.idle, true
	)

	--***---------- 刷新渲染层 ----------***--
	-- 动画
	self:GetOwner():RefreshRenderAnimation(
		true, actionTimeScale,
		castAnimationName, false, sp.AnimationName.idle, true
	)
	------------ sound effect ------------
	G_BattleLogicMgr:RenderPlayBattleSoundEffect(castAnimationConfig.actionSE)
	G_BattleLogicMgr:RenderPlayBattleSoundEffect(castAnimationConfig.actionVoice)
	------------ sound effect ------------
	--***---------- 刷新渲染层 ----------***--
	---------- view ----------

	---------- 进入施法 ----------
	local params = ObjectCastParameterStruct.New(
		self:GetNextSkillExtra(skillId),
		1,
		nil,
		cc.p(0, 0),
		false,
		self:GetOwner():IsHighlight()
	)
	self:DoCastEnterLogic(skillId, params)
	---------- 进入施法 ----------
end
--[[
施法逻辑
@params skillId int 技能id
@params percent number 伤害占比 分段伤害用
--]]
function BaseCastDriver:Cast(skillId, percent)
	--[[
	new logic todo

	--]]
	local bulletOriPosition = self:GetOwner():GetLocation().po
	local boneData = self:GetOwner():FineBoneInBattleRootSpace(sp.CustomName.BULLET_BONE_NAME)
	if boneData then
		bulletOriPosition = cc.p(boneData.worldPosition.x, boneData.worldPosition.y)
	end

	local shouldShakeWorld = false
	if nil ~= self:GetCurClickedWeakPointId() and ConfigWeakPointId.NONE == self:GetCurClickedWeakPointId() then
		shouldShakeWorld = true
	end

	local skillModel = self:GetSkillModelBySkillId(skillId)

	if nil ~= skillModel then
		local params = ObjectCastParameterStruct.New(
			1,
			percent,
			nil,
			bulletOriPosition,
			shouldShakeWorld,
			self:GetOwner():IsHighlight()
		)
		skillModel:Cast(params)

		BattleUtils.BattleObjectActionLog(self:GetOwner(), 'here skill cause effect', self:GetCastingSkillId())
	end

	------------ sound effect ------------
	local animationData = self:GetOwner():GetActionAnimationConfigBySkillId(skillId)
	G_BattleLogicMgr:RenderPlayBattleSoundEffect(animationData.actionCauseSE)
	------------ sound effect ------------
end
--[[
施法结束
--]]
function BaseCastDriver:OnCastExit()
	local castingSkillId = self:GetCastingSkillId()

	if nil ~= castingSkillId then

		local skillConfig = CommonUtils.GetSkillConf(castingSkillId)
		-- 取消物体由连携技带来的高亮
		if G_BattleLogicMgr:IsCardVSCard() then

			if ConfigSkillType.SKILL_CONNECT == checkint(skillConfig.property) then
				self:ConnectSkillHighlightOver(castingSkillId)
			end

		else

			if ConfigSkillType.SKILL_CONNECT == checkint(skillConfig.property) then
				self:ConnectSkillHighlightOver(castingSkillId)
			end

		end
		
	end

	------------ 重置一些参数 ------------
	self:ClearNextSkillExtra()
	self:SetCastingEcho(false)
	self:SetCastingSkillId(nil)
	------------ 重置一些参数 ------------

	self:GetOwner():SetState(self:GetOwner():GetState(-1))
	self:GetOwner():SetState(OState.NORMAL, -1)
end
--[[
施法被打断
--]]
function BaseCastDriver:OnCastBreak()
	self:OnCastExit()

	self:GetOwner():DoAnimation(true, self:GetOwner():GetAvatarTimeScale(), sp.AnimationName.idle, true)

	--***---------- 插入刷新渲染层计时器 ----------***--
	-- 动画
	self:GetOwner():RefreshRenderAnimation(
		true, self:GetOwner():GetAvatarTimeScale(), sp.AnimationName.idle, true
	)
	--***---------- 插入刷新渲染层计时器 ----------***--
end
---------------------------------------------------
-- chant logic begin --
---------------------------------------------------
--[[
准备读条
@params skillId int 技能id
@params time number 读条时间
--]]
function BaseCastDriver:OnChantEnter(skillId, time)
	---------- logic ----------
	-- 设置读条时长
	self:SetChantCountdown(time)

	-- 设置读条时的免疫异常状态
	self:SetChantAbnormalStateImmune(true)

	-- 发送事件
	G_BattleLogicMgr:SendObjEvent(ObjectEvent.OBJECT_CHANT_ENTER, {
		tag = self:GetOwner():GetOTag(), isEnemy = self:GetOwner():IsEnemy(true), skillId = skillId
	})
	---------- logic ----------

	---------- view ----------
	self:GetOwner():DoAnimation(true, nil, sp.AnimationName.chant, true)

	--***---------- 刷新渲染层 ----------***--
	-- 动画
	self:GetOwner():RefreshRenderAnimation(
		true, nil, sp.AnimationName.chant, true
	)
	--***---------- 刷新渲染层 ----------***--

	-- 设置变色
	self:GetOwner().tintDriver:OnActionEnter(BattleObjTintPattern.BOTP_DARK)
	---------- view ----------
end
--[[
设置读条时的异常状态免疫
@params immune bool 免疫
--]]
function BaseCastDriver:SetChantAbnormalStateImmune(immune)
	self:GetOwner():SetObjectAbnormalStateImmune(AbnormalState.SILENT, immune)
	self:GetOwner():SetObjectAbnormalStateImmune(AbnormalState.STUN, immune)
	self:GetOwner():SetObjectAbnormalStateImmune(AbnormalState.FREEZE, immune)
	self:GetOwner():SetObjectAbnormalStateImmune(AbnormalState.ENCHANTING, immune)
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
	self:SetChantCountdown(nil)

	-- 恢复读条时免疫控制
	self:SetChantAbnormalStateImmune(false)

	local monsterType = checkint(self:GetOwner():GetObjectConfig().type)

	if CardUtils.IsMonsterCard(self:GetOwner():GetObjectConfigId()) and ConfigMonsterType.BOSS == monsterType then

		local weakPointEffectId = self:GetCurClickedWeakPointId()

		if ConfigWeakPointId.HALF_EFFECT == weakPointEffectId then

			-- 打断一半不会出boss技能ci
			self:OnCastEnter(skillId)

		else

			-- 未打断 显示boss cutin场景
			local sceneTag = G_BattleLogicMgr:GetBData():GetTagByTagType(BattleTags.BT_CI_SCENE)
			local mainSkinId = self:GetOwner():GetObjectSkinId()

			--***---------- 刷新渲染层 ----------***--
			-- 屏蔽触摸
			G_BattleLogicMgr:SetBattleTouchEnable(false)

			G_BattleLogicMgr:AddRenderOperate(
				'G_BattleRenderMgr',
				'ShowBossCIScene',
				self:GetOwner():GetOTag(), sceneTag, skillId, mainSkinId
			)
			--***---------- 刷新渲染层 ----------***--

		end

	else

		-- 非boss类型直接进入施法
		self:OnCastEnter(skillId)

	end
	---------- logic ----------
end
--[[
读条被打断
--]]
function BaseCastDriver:OnChantBreak()
	---------- logic ----------
	-- 清空读条时间
	self:SetChantCountdown(nil)

	-- 恢复读条时免疫控制
	self:SetChantAbnormalStateImmune(false)
	---------- logic ----------

	---------- view ----------
	self:GetOwner():DoAnimation(
		true, nil,
		sp.AnimationName.attacked, false, sp.AnimationName.idle, true
	)

	--***---------- 插入刷新渲染层计时器 ----------***--
	-- 动画
	self:GetOwner():RefreshRenderAnimation(
		true, nil,
		sp.AnimationName.attacked, false, sp.AnimationName.idle, true
	)
	--***---------- 插入刷新渲染层计时器 ----------***--

	-- 设置变色
	self:GetOwner().tintDriver:OnActionExit()
	---------- view ----------

	self:OnCastExit()
end
--[[
读条点击回调
@params skillId int 技能id
@params data table {
	skillId int 技能id
	result ciScene 返回结果 false 表示读条读完
	leftTime number 由于场景有动画 场景结束的时候会返回一个读条剩余事件
}
--]]
function BaseCastDriver:ChantClickHandler(skillId, data)
	if false == data.result then

		self:SetCurClickedWeakPointId(ConfigWeakPointId.NONE)

		-- 场景结束 没有任何玩家主动触发的结果
		self:OnChantExit(data.skillId)

	else

		-- 玩家做出返回
		local effectId, effectValue = self:GetOwner().randomDriver:RandomWeakEffect(
			checkint(data.skillId),
			self:GetWeakPointsConfigBySkillId(data.skillId),
			checkint(data.result)
		)

		self:SetCurClickedWeakPointId(effectId)

		-- 此处重置咏唱时间 在施法前初始化的咏唱时间算上了弱点动画的持续时间 是不准确的
		self:SetChantCountdown(data.leftTime)

		if ConfigWeakPointId.BREAK == effectId then

			-- 打断
			self:OnChantBreak()

		elseif ConfigWeakPointId.HALF_EFFECT == effectId then

			-- 效果降低
			self:SetSkillExtra(effectValue)

		elseif ConfigWeakPointId.NONE == effectId then

			-- 无效果

		end

		--***---------- 刷新渲染层 ----------***--
		-- 显示提示文字
		G_BattleLogicMgr:AddRenderOperate(
			'G_BattleRenderMgr',
			'ShowObjectWeakHint',
			self:GetOwner():GetViewModelTag(), effectId
		)
		--***---------- 刷新渲染层 ----------***--

	end
end
--[[
获取读条计时器
--]]
function BaseCastDriver:GetChantCountdown()
	return self.chantCountdown
end
function BaseCastDriver:SetChantCountdown(countdown)
	self.chantCountdown = countdown
end
--[[
是否处于读条状态
@return _ int 是否处于读条状态 1 正在读条 0 读条结束 2 不处于读条状态
--]]
function BaseCastDriver:IsInChanting()
	local chantCountdown = self:GetChantCountdown()

	if OState.CASTING == self:GetOwner():GetState() and nil ~= chantCountdown then

		if 0 < chantCountdown then
			return 1
		else
			return 0
		end

	else

		return 2

	end
end
---------------------------------------------------
-- chant logic end --
---------------------------------------------------
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
	for i, skillId in ipairs(self.skills.halo) do
		self:DoCastEnterLogic(skillId, params)
	end
end
--[[
走实际施法逻辑
@params skillId int 技能id
@params params ObjectCastParameterStruct 外部传参
--]]
function BaseCastDriver:DoCastEnterLogic(skillId, params)
	local skillModel = self:GetSkillModelBySkillId(skillId)
	if nil ~= skillModel then
		print('\n**************\n', '	', self:GetOwner():GetOTag(), 'cast skill (BaseCastDriver:DoCastEnterLogic) -> ', skillId, '\n**************\n')
		skillModel:CastBegin(params)
	else
		BattleUtils.PrintBattleWaringLog('cast a not exist skill -> skillId : ' .. skillId)
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
		self:UpdateAllSkillsInsideCD(delta)
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
		local skillConfig = CommonUtils.GetSkillConf(skillId)

		------------ 刷新内置cd ------------
		self:SetSkillInsideCD(skillId, checknumber(skillConfig.insideCd))
		------------ 刷新内置cd ------------

		local skillTriggerInfo = self:GetSkillTriggerInfoBySkillId(skillId)

		------------ 能量消耗 ------------
		if nil ~= skillTriggerInfo[ConfigSkillTriggerType.ENERGY] then

			-- 能量
			self:GetOwner():AddEnergy(
				math.min(0, -1 * skillTriggerInfo[ConfigSkillTriggerType.ENERGY])
			)			

		end
		------------ 能量消耗 ------------

		------------ cd消耗 ------------
		if nil ~= skillTriggerInfo[ConfigSkillTriggerType.CD] then

			-- cd
			self:SetActionTrigger(
				ActionTriggerType.CD,
				skillId,
				skillTriggerInfo[ConfigSkillTriggerType.CD]
			)

		end
		------------ cd消耗 ------------

		------------ 生命值点数的消耗 ------------
		if nil ~= skillTriggerInfo[ConfigSkillTriggerType.COST_HP] then

			-- 血量
			local selfTag = self:GetOwner():GetOTag()
			local damage = skillTriggerInfo[ConfigSkillTriggerType.COST_HP]

			local damageData = ObjectDamageStruct.New(
				selfTag,
				damage,
				DamageType.ATTACK_PHYSICAL,
				false,
				{attackerTag = selfTag}
			)
			self:GetOwner():HpChange(damageData)

		end
		------------ 生命值点数的消耗 ------------

		------------ 当前生命值的消耗 ------------
		if nil ~= skillTriggerInfo[ConfigSkillTriggerType.COST_CHP] then

			-- 当前血量
			local selfTag = self:GetOwner():GetOTag()
			local damage = skillTriggerInfo[ConfigSkillTriggerType.COST_CHP] * self:GetOwner():GetMainProperty():GetCurrentHp()

			local damageData = ObjectDamageStruct.New(
				selfTag,
				damage,
				DamageType.ATTACK_PHYSICAL,
				false,
				{attackerTag = selfTag}
			)
			self:GetOwner():HpChange(damageData)

		end
		------------ 当前生命值的消耗 ------------

		------------ 最大生命值的消耗 ------------
		if nil ~= skillTriggerInfo[ConfigSkillTriggerType.COST_OHP] then

			-- 最大血量
			local selfTag = self:GetOwner():GetOTag()
			local damage = skillTriggerInfo[ConfigSkillTriggerType.COST_OHP] * self:GetOwner():GetMainProperty():GetOriginalHp()

			local damageData = ObjectDamageStruct.New(
				selfTag,
				damage,
				DamageType.ATTACK_PHYSICAL,
				false,
				{attackerTag = selfTag}
			)
			self:GetOwner():HpChange(damageData)

		end
		------------ 最大生命值的消耗 ------------
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
-- inside cd begin --
---------------------------------------------------
--[[
设置技能的内置cd
@params skillId int 技能id
@params cd number 内置cd
--]]
function BaseCastDriver:SetSkillInsideCD(skillId, cd)
	self.skillInsideCountdown[tostring(skillId)] = cd
end
--[[
获取技能的内置cd
@params skillId int 技能id
--]]
function BaseCastDriver:GetSkillInsideCD(skillId)
	return self.skillInsideCountdown[tostring(skillId)]
end
--[[
刷一次所有技能的内置cd
@params delta number 差值
--]]
function BaseCastDriver:UpdateAllSkillsInsideCD(delta)
	for k,v in pairs(self.skillInsideCountdown) do
		self.skillInsideCountdown[k] = math.max(0, v - delta)
	end
end
---------------------------------------------------
-- inside cd end --
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
old function
根据id获取技能模型
@params skillId int 技能id
--]]
function BaseCastDriver:GetSkillBySkillId(skillId)
	return self.skills[tostring(skillId)]
end
function BaseCastDriver:SetSkillBySkillId(skillId, skill)
	self.skills[tostring(skillId)] = skill
end
--[[
根据技能id获取技能数据
@params skillId int 技能id
@return _ ObjectSkillStruct 技能信息数据
--]]
function BaseCastDriver:GetSkillStructBySkillId(skillId)
	return self.skills[tostring(skillId)]
end
function BaseCastDriver:SetSkillStructBySkillId(skillId, skillStruct)
	self.skills[tostring(skillId)] = skillStruct
end
--[[
根据技能id获取技能模型
@params skillId int 技能id
@return _ BaseSkill 技能模型
--]]
function BaseCastDriver:GetSkillModelBySkillId(skillId)
	if nil ~= self:GetSkillStructBySkillId(skillId) then
		return self:GetSkillStructBySkillId(skillId).skill
	else
		return nil
	end
end
--[[
初始化技能数据结构
--]]
function BaseCastDriver:InitSkills()
	local cardConfig = self:GetOwner():GetObjectConfig()

	-- 初始化触发器
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

	-- 技能充能计数
	self.skillChargeCounter = {}

	-- 连携技额外充能计数
	self.connectSkillChargeCounter = {}

	local skillId = nil
	local skillConfig = nil

	-- local effect = CardUtils.GetCardEffectConfigBySkinId(self:GetOwner():GetObjectConfigId(), self:GetOwner():GetObjectSkinId())

	for _, skillId_ in ipairs(cardConfig.skill) do

		skillId = checkint(skillId_)
		local skillLevel = 1
		if nil ~= self:GetOwner():GetObjInfo().skillData and nil ~= self:GetOwner():GetObjInfo().skillData[tostring(skillId)] then
			skillLevel = checkint(self:GetOwner():GetObjInfo().skillData[tostring(skillId)].level)
		end

		skillConfig = CommonUtils.GetSkillConf(skillId)

		if nil == skillConfig then

			BattleUtils.PrintConfigLogicError('cannot find skill config in BaseCastDriver -> InitSkills : ' .. tostring(skillId))

		else

			self:AddASkill(skillId, skillLevel)

		end

	end

	---------- 连携技不会彻底替换ci 连携技失效后会释放2技能 ----------
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
	---------- 连携技不会彻底替换ci 连携技失效后会释放2技能 ----------

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
	print('here check fuck add outer skills', self:GetOwner():GetObjectName())
	dump(skillData)
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
		BattleUtils.PrintConfigLogicError('cannot find skill config in BaseCastDriver -> InitSkills : ' .. tostring(skillId))
		return
	end

	if not self:CanInitSkillBySkillId(checkint(skillId)) then return end

	local skillClassPath = 'battle.skill.ObjSkill'
	local isSkillEnable = true
	local skillType = checkint(skillConfig.property)
	local extraInfo = {}

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

	elseif ConfigSkillType.SKILL_CONNECT == skillType then

		-- 连携技 判断是否满足释放连携技的条件
		local canCastConnect = false

		if G_BattleLogicMgr:IsCardVSCard() then
			if G_BattleLogicMgr:CanUseFriendConnectSkill() and not self:GetOwner():IsEnemy(true) then
				canCastConnect = true
			end

			if G_BattleLogicMgr:CanUseEnemyConnectSkill() and self:GetOwner():IsEnemy(true) then
				canCastConnect = true
			end

		else
			canCastConnect = true
		end

		if canCastConnect then

			local cardConfig = self:GetOwner():GetObjectConfig()
			if nil ~= cardConfig then
				for _, connectCardId in ipairs(cardConfig.concertSkill) do

					if false == G_BattleLogicMgr:IsCardInTeam(connectCardId, self:GetOwner():IsEnemy(true)) then
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

					-- if G_BattleLogicMgr:AutoUseFriendConnectSkill() then
					-- 	table.insert(self.skills.attack, skillId)
					-- end
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
		self:SetSkillInsideCD(skillId, 0)

		-- 初始化技能动作 特效信息
		local effect = CardUtils.GetCardEffectConfigBySkinId(self:GetOwner():GetObjectConfigId(), self:GetOwner():GetObjectSkinId())
		local spineActionData = BSCUtils.GetSkillSpineEffectStruct(skillId, effect, G_BattleLogicMgr:GetCurrentWave(), self:GetOwner():GetObjectSkinId())

		-- 添加一次技能的动画信息
		self:GetOwner():SetActionAnimationConfigBySkillId(skillId, spineActionData)

		local skillBaseData = SkillConstructorStruct.New(
			skillId,
			level,
			BattleUtils.GetSkillInfoStructBySkillId(skillId, level),
			self:GetOwner():IsEnemy(true),
			self:GetOwner():GetOTag(),
			spineActionData
		)
		local skill = __Require(skillClassPath).new(skillBaseData)
		local skillInfo = ObjectSkillStruct.New(skillId, skill, extraInfo)
		self:SetSkillStructBySkillId(skillId, skillInfo)
	end
	---------- 创建技能模型 ----------

end
--[[
根据技能id获取有序弱点配置
@params skillId int 技能id
@return _ array 有序弱点配置
--]]
function BaseCastDriver:GetWeakPointsConfigBySkillId(skillId)
	return self:GetSkillStructBySkillId(skillId).weakPoints
end
--[[
检查是否满足连携技使用条件
@params skillId int 技能id
@return _ bool 是否可以使用
--]]
function BaseCastDriver:CanUseConnectSkillByCardAlive(skillId)
	for i,v in ipairs(self:GetSkillStructBySkillId(skillId).connectCardId) do
		if nil == G_BattleLogicMgr:IsObjAliveByCardId(v, self:GetOwner():IsEnemy(true)) then
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
			nil ~= self:GetSkillStructBySkillId(skillId) then

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
设置正在释放的技能id
@params skillId int 技能id
--]]
function BaseCastDriver:SetCastingSkillId(skillId)
	self.castingSkillId = skillId
end
--[[
获取正在释放的技能id
@return _ int 正在释放的技能id
--]]
function BaseCastDriver:GetCastingSkillId()
	return self.castingSkillId
end
--[[
设置点击的弱点id
@params id int id
--]]
function BaseCastDriver:SetCurClickedWeakPointId(id)
	self.curClickedWeakPointId = id
end
function BaseCastDriver:GetCurClickedWeakPointId()
	return self.curClickedWeakPointId
end
--[[
根据技能id判断是否已经初始化过技能
@params skillId int 技能id
@return _ bool 是否初始化过技能
--]]
function BaseCastDriver:HasSkillBySkillId(skillId)
	return nil ~= self:GetSkillStructBySkillId(skillId)
end
--[[
根据技能id判断本场战斗该技能是否可以生效
@params skillId int 技能id
@return result bool 是否可以生效
--]]
function BaseCastDriver:CanInitSkillBySkillId(skillId)
	local result = false

	local skillConfig = CommonUtils.GetSkillConf(skillId)
	if nil ~= skillConfig and nil ~= skillConfig.battleType then
		for _, battleType in ipairs(skillConfig.battleType) do

			if QuestBattleType.ALL == checkint(battleType) then
				result = true
				break
			elseif G_BattleLogicMgr:GetQuestBattleType() == checkint(battleType) then
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
