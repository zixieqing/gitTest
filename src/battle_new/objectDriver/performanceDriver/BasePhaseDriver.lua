--[[
阶段转换驱动器
--]]
local BaseActionDriver = __Require('battle.objectDriver.BaseActionDriver')
local BasePhaseDriver = class('BasePhaseDriver', BaseActionDriver)

--[[
@override
constructor
--]]
function BasePhaseDriver:ctor( ... )
	BaseActionDriver.ctor(self, ...)

	local args = unpack({...})

	self.phaseChangeData = args.phaseChangeData
	
	-- dump(self.phaseChangeData)

	self:Init()
end
---------------------------------------------------
-- init logic begin --
---------------------------------------------------
--[[
初始化逻辑
--]]
function BasePhaseDriver:Init()
	self:InitInnateValue()
	self:InitUnitValue()

	self:InitActionTrigger()
	self:InitPhaseConfig()
end
--[[
初始化固有数据
--]]
function BasePhaseDriver:InitInnateValue()
	-- 死亡时触发的转接段计数
	self.diePhaseChangeCounter = nil
end
--[[
初始化特有数据
--]]
function BasePhaseDriver:InitUnitValue()

end
--[[
初始化转阶段触发器
--]]
function BasePhaseDriver:InitActionTrigger()
	-- 初始化阶段转换触发器
	self.actionTrigger = {
		[ActionTriggerType.HP] = 0,
		[ActionTriggerType.CD] = 0,
		[ActionTriggerType.DIE] = false,
		[ActionTriggerType.SKILL] = {
			[ConfigCampType.FRIEND] = {},
			[ConfigCampType.ENEMY] = {}
		}
	}
end
---------------------------------------------------
-- init logic end --
---------------------------------------------------

---------------------------------------------------
-- control logic begin --
---------------------------------------------------
--[[
@override
是否能进行动作 此处的逻辑统一在update中检测
--]]
function BasePhaseDriver:CanDoAction()
	return self:GetCanDoPhase()
end
--[[
获取死亡时触发的阶段转换
@return result table 可以触发的阶段转换
--]]
function BasePhaseDriver:CanDoActionWhenDie()
	local pcinfo = nil
	local pcdata = nil
	local result = {}
	for i = #self.phases, 1, -1 do
		pcinfo = self.phases[i]
		pcdata = self:GetPCDataByIndex(pcinfo.index)
		if ConfigPhaseTriggerType.OBJ_DIE == pcdata.phaseTriggerType or
			ConfigPhaseType.BECKON_ADDITION_FORCE == pcdata.phaseType then

			------------ 死亡时会额外触发强制召唤add ------------
			table.insert(result, pcinfo.index)
			------------ 死亡时会额外触发强制召唤add ------------

		end
	end
	return result
end
--[[
@override
进入动作
@params index int 根据优先级保存的转阶段信息序号
--]]
function BasePhaseDriver:OnActionEnter(index)
	-- self:CostActionResources(index)
	self:OnPhaseChangeEnter(index)
	
	BattleUtils.PrintBattleActionLog(string.format('%s, %s, ready to do phase change !!! phaseId >>> %s',
			self:GetOwner():GetObjectName(),
			self:GetOwner():GetObjectConfigId(),
			self:GetPCDataByIndex(index).phaseId
		)
	)
end
--[[
@override
结束动作
--]]
function BasePhaseDriver:OnActionExit()

end
--[[
执行转阶段
@params index 根据优先级保存的转阶段信息序号
--]]
function BasePhaseDriver:OnPhaseChangeEnter(index)
	local phaseData = self:GetPCDataByIndex(index)

	if ConfigPhaseType.TALK_DEFORM == phaseData.phaseType then
		
		------------ 喊话+变身 ------------
		self:PhaseChangeSpeakAndDeform(phaseData)
		------------ 喊话+变身 ------------

	elseif ConfigPhaseType.TALK_ESCAPE == phaseData.phaseType then

		------------ 喊话+逃跑 ------------
		self:PhaseChangeSpeakAndEscape(phaseData)
		------------ 喊话+逃跑 ------------

	elseif ConfigPhaseType.TALK_ONLY == phaseData.phaseType then

		------------ 纯喊话 ------------
		self:Speak(phaseData.dialogueData)
		------------ 纯喊话 ------------

	elseif ConfigPhaseType.BECKON_ADDITION_FORCE == phaseData.phaseType or
		ConfigPhaseType.BECKON_ADDITION == phaseData.phaseType then

		------------ 招小怪 ------------
		self:PhaseChangeBeckonAddition(phaseData)
		------------ 招小怪 ------------

	elseif ConfigPhaseType.BECKON_CUSTOMIZE == phaseData.phaseType then

		------------ 招小怪 ------------
		self:PhaseChangeBeckonAdditionCustomize(phaseData)
		------------ 招小怪 ------------

	elseif ConfigPhaseType.EXEUNT_CUSTOMIZE == phaseData.phaseType then

		------------ 怪物退场 ------------		
		self:AdditionExeunt(phaseData)
		------------ 怪物退场 ------------

	elseif ConfigPhaseType.DEFORM_CUSTOMIZE == phaseData.phaseType then

		------------ 招小怪 ------------
		self:PhaseChangeDeformCustomize(phaseData)
		------------ 招小怪 ------------

	elseif ConfigPhaseType.PLOT == phaseData.phaseType then

		------------ 出主线对话 ------------
		self:PhaseChangeShowPlotStage(phaseData)
		------------ 出主线对话 ------------

	end

end
--[[
@override
刷新触发器
@params actionTriggerType ActionTriggerType 行为触发类型
@params delta number 变化量
--]]
function BasePhaseDriver:UpdateActionTrigger(actionTriggerType, delta)
	if ActionTriggerType.CD == actionTriggerType then

		-- 记录触发宿主上场后的时间
		self.actionTrigger[ActionTriggerType.CD] = math.max(0, self.actionTrigger[ActionTriggerType.CD] + delta)

	elseif ActionTriggerType.HP == actionTriggerType then

		-- 记录触发宿主损失的hp	
		self.actionTrigger[ActionTriggerType.HP] = 1 - delta

	elseif ActionTriggerType.DIE == actionTriggerType then

		-- 记录触发宿主是否死亡
		self.actionTrigger[ActionTriggerType.DIE] = delta

	elseif ActionTriggerType.SKILL == actionTriggerType then

		-- 记录物体释放技能
		local npcId = delta.npcId
		local npcCampType = delta.npcCampType
		local skillId = delta.skillId

		if nil == self.actionTrigger[ActionTriggerType.SKILL][npcCampType] then
			self.actionTrigger[ActionTriggerType.SKILL][npcCampType] = {}
		end

		if nil == self.actionTrigger[ActionTriggerType.SKILL][npcCampType][tostring(npcId)] then
			self.actionTrigger[ActionTriggerType.SKILL][npcCampType][tostring(npcId)] = {}
		end

		self.actionTrigger[ActionTriggerType.SKILL][npcCampType][tostring(npcId)][tostring(skillId)] = true

	end
end
--[[
获取当前状态可以执行的阶段转换
@return _ int 阶段转换信息的序号
--]]
function BasePhaseDriver:GetCanDoPhase()
	-- 读条时无法阶段转换
	if 1 == self:GetOwner().castDriver:IsInChanting() then return nil end

	local pcinfo = nil
	local result = false
	for i = #self.phases, 1, -1 do
		pcinfo = self.phases[i]
		result = self:CanDoPhaseChangeJudgeByIndex(pcinfo.index)
		if true == result then
			return pcinfo.index
		end
	end
	return nil
end
--[[
根据自增序号判断阶段转换是否满足触发条件
@params index int 根据优先级保存的转阶段信息序号
@return result bool 是否可以进行阶段转换
--]]
function BasePhaseDriver:CanDoPhaseChangeJudgeByIndex(index)
	local pcdata = self:GetPCDataByIndex(index)

	local judgeFunc = {
		[ConfigPhaseTriggerType.LOST_HP] = function (pcdata)

			-- 判断宿主损失血量是否大于一定值
			return pcdata.phaseTriggerValue <= self:GetActionTrigger(ActionTriggerType.HP)

		end,
		[ConfigPhaseTriggerType.APPEAR_TIME] = function (pcdata)

			-- 判断宿主是否在场到达一定时间
			return pcdata.phaseTriggerValue <= self:GetActionTrigger(ActionTriggerType.CD)

		end,
		[ConfigPhaseTriggerType.OBJ_DIE] = function (pcdata)

			-- 判断宿主是否死亡
			return self:GetActionTrigger(ActionTriggerType.DIE)

		end,
		[ConfigPhaseTriggerType.OBJ_SKILL] = function (pcdata)

			-- 判断目标是否释放过技能
			local triggerInfo = self:GetActionTrigger(ActionTriggerType.SKILL)
			local info = triggerInfo[pcdata.phaseTriggerNpcCampType][tostring(pcdata.phaseTriggerNpcId)]

			if nil ~= info then
				return info[tostring(pcdata.phaseTriggerValue)] and true == info[tostring(pcdata.phaseTriggerValue)]
			end

			return false

		end
	}

	local phaseTriggerType = pcdata.phaseTriggerType
	if nil ~= judgeFunc[phaseTriggerType] then

		local result = judgeFunc[phaseTriggerType](pcdata)
		if not result then
			return false
		end
		return true

	else

		return false

	end
end
--[[
@override
消耗做出行为需要的资源
@params index int 根据优先级保存的转阶段信息序号
--]]
function BasePhaseDriver:CostActionResources(index)
	-- 根据序号移除转阶段信息
	self:RemoveAPhaseChangeInfo(index)
end
--[[
@override
重置所有触发器
--]]
function BasePhaseDriver:ResetActionTrigger()
	self.actionTrigger = {
		[ActionTriggerType.HP] = 0,
		[ActionTriggerType.CD] = 0,
		[ActionTriggerType.DIE] = false,
		[ActionTriggerType.SKILL] = {
			[ConfigCampType.FRIEND] = {},
			[ConfigCampType.ENEMY] = {}
		}
	}
end
--[[
@override
操作触发器
--]]
function BasePhaseDriver:GetActionTrigger(actionTriggerType)
	return self.actionTrigger[actionTriggerType]
end
function BasePhaseDriver:SetActionTrigger(actionTriggerType, value)
	self.actionTrigger[actionTriggerType] = value
end
--[[
根据阶段转换类型判断是否需要阻塞主逻辑
@params phaseType ConfigPhaseType 阶段转换类型
@return _ bool 是否需要暂停主逻辑
--]]
function BasePhaseDriver:NeedToPauseMainLogic(phaseType)
	if ConfigPhaseType.TALK_DEFORM == phaseType then
		return true
	else
		return false
	end
end
---------------------------------------------------
-- control logic end --
---------------------------------------------------

---------------------------------------------------
-- phase logic begin --
---------------------------------------------------
--[[
转阶段类型1 喊话+变身
@params phaseData PhaseChangeSturct 阶段转换数据
--]]
function BasePhaseDriver:PhaseChangeSpeakAndDeform(phaseData)
	-- 暂停主逻辑
	G_BattleLogicMgr:PauseMainLogic()

	-- 眩晕各单位
	local objs = nil
	local obj = nil

	objs = G_BattleLogicMgr:GetAliveBattleObjs(false)
	for i = #objs, 1, -1 do
		obj = objs[i]
		obj:ForceStun(true)
	end

	local deformNpcId = nil
	local deformToNpcId = nil
	local deformSource = nil
	local dialogueData = nil

	for _, data in ipairs(phaseData.phaseData) do

		deformNpcId = data.deformFromId
		-- 查找变身源
		deformSource = G_BattleLogicMgr:IsObjAliveByCardId(deformNpcId, self:GetOwner():IsEnemy(true))
		dialogueData = phaseData.dialogueData[tostring(deformNpcId)]

		if nil ~= deformSource then
			-- 做变身的动作
			deformSource:DoAnimation(true, nil, sp.AnimationName.chant, true)

			if nil ~= dialogueData then

				deformToNpcId = data.deformToId
				local cardConfig = CardUtils.GetCardConfig(deformToNpcId)
				local isEnemy = data.deformToCampType == ConfigCampType.ENEMY

				local pos = cc.p(
					deformSource:GetLocation().po.x,
					deformSource:GetLocation().po.y
				)
				local rcInfo = G_BattleLogicMgr:GetRowColByPos(pos)
				local location = ObjectLocation.New(pos.x, pos.y, rcInfo.r, rcInfo.c)

				-- 创建怪物属性信息
				local objProperty = __Require('battle.object.MonsterProperty').new(MonsterPropertyConstructStruct.New(
					deformToNpcId,
					deformSource:GetObjectLevel(),
					data.deformToAttrGrow,
					data.deformToSkillGrow,
					ObjPFixedAttrStruct.New(),
					G_BattleLogicMgr:GetFormationPropertyAttr(isEnemy),
					location
				))

				local objFeature = BattleUtils.GetObjFeatureByCareer(checkint(cardConfig.career))
				local skinId = CardUtils.GetCardSkinId(deformToNpcId)

				local objInfo = ObjectConstructorStruct.New(
					deformToNpcId, location, deformSource:GetTeamPosition(), objFeature, checkint(cardConfig.career), isEnemy,
					objProperty, nil, nil, EXAbilityConstructorStruct.New(deformToNpcId, CardUtils.GetCardEXAbilitySkillsByCardId(deformToNpcId)), false, deformSource:GetRecordDeltaHp(),
					skinId, checknumber(cardConfig.scale), checkint(cardConfig.defaultLayer or 0),
					G_BattleLogicMgr:GetPhaseChangeDataByNpcId(deformToNpcId)
				)

				local tag = G_BattleLogicMgr:GetBData():GetTagByTagType(isEnemy and BattleTags.BT_OTHER_ENEMY or BattleTags.BT_FRIEND)
				local o = G_BattleLogicMgr:GetABattleObj(tag, objInfo)

				-- 设置一次当前波数
				o:SetObjectWave(deformSource:GetObjectWave())
				-- 设置一次队伍序号
				o:SetObjectTeamIndex(deformSource:GetObjectTeamIndex())

				-- 判断血量类型
				if ConfigDeformType.HOLD_HP == data.deformType then
					local hpPercent = deformSource:GetMainProperty():GetCurHpPercent()
					o:HpPercentChangeForce(hpPercent)
				end

				-- 杀死变身源
				deformSource:KillSelf(true)

				--***---------- 刷新渲染层 ----------***--
				-- 创建变身后物体
				G_BattleLogicMgr:AddRenderOperate(
					'G_BattleRenderMgr',
					'CreateAObjectView',
					o:GetViewModelTag(), objInfo, false
				)
				--***---------- 刷新渲染层 ----------***--

				-- 初始化渲染层状态
				o:InitObjectRender()

				--***---------- 刷新渲染层 ----------***--
				-- 开始进行阶段转换
				G_BattleLogicMgr:AddRenderOperate(
					'G_BattleRenderMgr',
					'PhaseChangeSpeakAndDeform',
					deformSource:GetViewModelTag(), deformSource:GetOTag(), o:GetViewModelTag(), o:GetOTag(),
					dialogueData.dialogueId, dialogueData.dialogueContent
				)
				--***---------- 刷新渲染层 ----------***--
			end
		end

	end
end
--[[
阶段转换类型2 喊话+逃跑
@params phaseData PhaseChangeSturct 阶段转换数据
--]]
function BasePhaseDriver:PhaseChangeSpeakAndEscape(phaseData)
	local currentWave = G_BattleLogicMgr:GetBData():GetCurrentWave()

	local escapeNpc = nil
	local dialogueData = nil

	for _, data in ipairs(phaseData.phaseData) do

		-- 查找逃跑源
		escapeNpc = G_BattleLogicMgr:IsObjAliveByCardId(data.escapeNpcId, self:GetOwner():IsEnemy(true))
		-- 判断是否能逃跑
		if nil ~= escapeNpc and escapeNpc.moveDriver:CanDoEscape(currentWave) then

			local targetPos = escapeNpc:CalcEscapeTargetPosition()

			-- 开始进入逃跑
			escapeNpc.moveDriver:OnEscapeEnter(targetPos, data)
			
			-- 喊话
			dialogueData = phaseData.dialogueData[tostring(data.escapeNpcId)]
			if nil ~= dialogueData then

				--***---------- 刷新渲染层 ----------***--
				-- 开始进行阶段转换
				G_BattleLogicMgr:AddRenderOperate(
					'G_BattleRenderMgr',
					'PhaseChangeSpeakAndEscape',
					escapeNpc:GetViewModelTag(), escapeNpc:GetOTag(),
					dialogueData.dialogueId, dialogueData.dialogueContent
				)
				--***---------- 刷新渲染层 ----------***--

			end

		end

	end
end
--[[
阶段转换类型4 5 喊话+召唤add
@params phaseData PhaseChangeSturct 阶段转换数据
--]]
function BasePhaseDriver:PhaseChangeBeckonAddition(phaseData)
	------------ 喊话 ------------
	self:Speak(phaseData.dialogueData)
	------------ 喊话 ------------

	------------ 创建add ------------
	-- 触发招小怪的原始怪物
	local beckoner = G_BattleLogicMgr:IsObjAliveByCardId(phaseData.phaseTriggerNpcId, self:GetOwner():IsEnemy(true))
	local beckonerPos = beckoner:GetLocation().po
	local beckonerRCInfo = G_BattleLogicMgr:GetRowColByPos(beckonerPos)
	local beckonerLevel = beckoner:GetObjectLevel()

	local cardId = nil
	local cardConfig = nil
	local beckonPos = nil
	local beckonRCInfo = nil

	for _, data in ipairs(phaseData.phaseData) do

		cardId = data.beckonNpcId
		cardConfig = CardUtils.GetCardConfig(cardId)
		local isEnemy = data.beckonNpcCampType == ConfigCampType.ENEMY

		-- 为召唤物随机一个行
		local r = G_BattleLogicMgr:GetRandomManager():GetRandomInt(G_BattleLogicMgr:GetBConf().ROW)
		beckonPos = G_BattleLogicMgr:GetCellPosByRC(r, beckonerRCInfo.c)

		local location = ObjectLocation.New(
			beckonPos.cx,
			beckonPos.cy,
			r,
			beckonerRCInfo.c
		)

		-- 创建怪物属性信息
		local objProperty = __Require('battle.object.MonsterProperty').new(MonsterPropertyConstructStruct.New(
			cardId,
			beckonerLevel,
			data.beckonNpcAttrGrow,
			data.beckonNpcSkillGrow,
			ObjPFixedAttrStruct.New(),
			G_BattleLogicMgr:GetFormationPropertyAttr(isEnemy),
			location
		))

		local objFeature = BattleUtils.GetObjFeatureByCareer(checkint(cardConfig.career))
		local skinId = CardUtils.GetCardSkinId(cardId)

		local objInfo = ObjectConstructorStruct.New(
			cardId, location, beckoner:GetTeamPosition() + 1, objFeature, checkint(cardConfig.career), isEnemy,
			objProperty, nil, nil, EXAbilityConstructorStruct.New(cardId, CardUtils.GetCardEXAbilitySkillsByCardId(cardId)), false, nil,
			skinId, checknumber(cardConfig.scale), checkint(cardConfig.defaultLayer or 0), nil,
			G_BattleLogicMgr:GetPhaseChangeDataByNpcId(cardId)
		)

		local tag = G_BattleLogicMgr:GetBData():GetTagByTagType(isEnemy and BattleTags.BT_OTHER_ENEMY or BattleTags.BT_FRIEND)
		local o = G_BattleLogicMgr:GetABattleObj(tag, objInfo)

		-- 设置一次当前波数
		o:SetObjectWave(beckoner:GetObjectWave())
		-- 设置一次队伍序号
		o:SetObjectTeamIndex(beckoner:GetObjectTeamIndex())

		--***---------- 刷新渲染层 ----------***--
		-- 创建变身后物体
		G_BattleLogicMgr:AddRenderOperate(
			'G_BattleRenderMgr',
			'CreateAObjectView',
			o:GetViewModelTag(), objInfo
		)
		--***---------- 刷新渲染层 ----------***--

		-- 初始化渲染层状态
		o:InitObjectRender()

		G_BattleLogicMgr:SendObjEvent(ObjectEvent.OBJECT_CREATED, {tag = tag})

		-- 吹飞 让怪走进战场
		o:BlewOff()
	end
	------------ 创建add ------------
end
--[[
阶段转换类型6 自定义的召唤add
@params phaseData PhaseChangeSturct 阶段转换数据
--]]
function BasePhaseDriver:PhaseChangeBeckonAdditionCustomize(phaseData)
	------------ 喊话 ------------
	self:Speak(phaseData.dialogueData)
	------------ 喊话 ------------

	-- 触发招小怪的原始怪物
	local beckoner = G_BattleLogicMgr:IsObjAliveByCardId(phaseData.phaseTriggerNpcId, self:GetOwner():IsEnemy(true))
	local beckonerLevel = beckoner:GetObjectLevel()

	local cardId = nil
	local cardConfig = nil

	for _, data in ipairs(phaseData.phaseData) do

		cardId = data.beckonNpcId
		cardConfig = CardUtils.GetCardConfig(cardId)
		local isEnemy = data.beckonNpcCampType == ConfigCampType.ENEMY

		-- 召唤后的初始位置
		local appearPosId = data.beckonAppearPosId
		local appearPosConfig = CommonUtils.GetConfig('quest', 'battlePosition', appearPosId)
		local ar, ac = checkint(appearPosConfig.coordinate[2]), checkint(appearPosConfig.coordinate[1])
		local appearCellInfo = G_BattleLogicMgr:GetCellPosByRC(ar, ac)

		local location = ObjectLocation.New(
			appearCellInfo.cx,
			appearCellInfo.cy,
			ar,
			ac
		)

		-- 创建怪物属性信息
		local objProperty = __Require('battle.object.MonsterProperty').new(MonsterPropertyConstructStruct.New(
			cardId,
			beckonerLevel,
			data.beckonNpcAttrGrow,
			data.beckonNpcSkillGrow,
			ObjPFixedAttrStruct.New(),
			G_BattleLogicMgr:GetFormationPropertyAttr(isEnemy),
			location
		))

		local objFeature = BattleUtils.GetObjFeatureByCareer(checkint(cardConfig.career))
		local skinId = CardUtils.GetCardSkinId(cardId)

		local objInfo = ObjectConstructorStruct.New(
			cardId, location, beckoner:GetTeamPosition() + 1, objFeature, checkint(cardConfig.career), isEnemy,
			objProperty, nil, nil, EXAbilityConstructorStruct.New(cardId, CardUtils.GetCardEXAbilitySkillsByCardId(cardId)), false, nil,
			skinId, checknumber(cardConfig.scale), checkint(cardConfig.defaultLayer or 0),
			G_BattleLogicMgr:GetPhaseChangeDataByNpcId(cardId)
		)

		local tag = G_BattleLogicMgr:GetBData():GetTagByTagType(isEnemy and BattleTags.BT_OTHER_ENEMY or BattleTags.BT_FRIEND)
		local o = G_BattleLogicMgr:GetABattleObj(tag, objInfo)

		-- 设置一次当前波数
		o:SetObjectWave(beckoner:GetObjectWave())
		-- 设置一次队伍序号
		o:SetObjectTeamIndex(beckoner:GetObjectTeamIndex())

		-- 设置不可被索敌
		o:SetCanBeSearched(false)

		--***---------- 刷新渲染层 ----------***--
		-- 创建变身后物体
		G_BattleLogicMgr:AddRenderOperate(
			'G_BattleRenderMgr',
			'CreateAObjectView',
			o:GetViewModelTag(), objInfo
		)
		--***---------- 刷新渲染层 ----------***--

		-- 初始化渲染层状态
		o:InitObjectRender()

		-- 计算入场目标点
		local targetPosId = data.beckonTargetPosId
		local targetPosConfig = CommonUtils.GetConfig('quest', 'battlePosition', targetPosId)
		local tr, tc = checkint(targetPosConfig.coordinate[2]), checkint(targetPosConfig.coordinate[1])
		local targetCellInfo = G_BattleLogicMgr:GetCellPosByRC(tr, tc)
		local targetPos = cc.p(
			targetCellInfo.cx,
			targetCellInfo.cy
		)

		-- 开始强制移动
		o:ForceMove(targetPos, data.beckonAppearActionName, function ()
			-- 唤醒物体 准备开始走正常逻辑
			o:AwakeObject()
			-- 发送物体被创建的事件
			G_BattleLogicMgr:SendObjEvent(ObjectEvent.OBJECT_CREATED, {tag = tag})
		end)
	end
end
--[[
阶段转换类型8 定制化变身
@params phaseData PhaseChangeSturct 阶段转换数据
--]]
function BasePhaseDriver:PhaseChangeDeformCustomize(phaseData)
	-- 暂停主逻辑
	G_BattleLogicMgr:PauseMainLogic()

	------------ 喊话 ------------
	self:Speak(phaseData.dialogueData)
	------------ 喊话 ------------

	local deformFromId = nil
	local deformFromIsEnemy = nil
	local deformFromObject = nil
	local deformToId = nil

	for _, data in ipairs(phaseData.phaseData) do

		-- 检查变身源是否存在
		deformFromId = data.deformFromId
		deformFromIsEnemy = ConfigCampType.ENEMY == data.deformToCampType
		deformFromObject = G_BattleLogicMgr:IsObjAliveByCardId(deformFromId, deformFromIsEnemy)


		if nil ~= deformFromObject then

			------------ 创建变身后的物体 ------------
			deformToId = data.deformToId
			local cardConfig = CardUtils.GetCardConfig(deformToId)
			local isEnemy = data.deformToCampType == ConfigCampType.ENEMY

			local deformToPosId = data.deformToOriPosId
			local deformToPosConfig = CommonUtils.GetConfig('quest', 'battlePosition', deformToPosId)
			local r, c = checkint(deformToPosConfig.coordinate[2]), checkint(deformToPosConfig.coordinate[1])
			local cellInfo = G_BattleLogicMgr:GetCellPosByRC(r, c)

			local location = ObjectLocation.New(
				cellInfo.cx,
				cellInfo.cy,
				r,
				c
			)

			-- 创建怪物属性信息
			local objProperty = __Require('battle.object.MonsterProperty').new(MonsterPropertyConstructStruct.New(
				data.deformToId,
				deformFromObject:GetObjectLevel(),
				data.deformToAttrGrow,
				data.deformToSkillGrow,
				ObjPFixedAttrStruct.New(),
				G_BattleLogicMgr:GetFormationPropertyAttr(isEnemy),
				location
			))
			
			local objFeature = BattleUtils.GetObjFeatureByCareer(checkint(cardConfig.career))
			local skinId = CardUtils.GetCardSkinId(data.deformToId)

			local objInfo = ObjectConstructorStruct.New(
				deformToId, location, deformFromObject:GetTeamPosition(), objFeature, checkint(cardConfig.career), isEnemy,
				objProperty, nil, nil, EXAbilityConstructorStruct.New(deformToId, CardUtils.GetCardEXAbilitySkillsByCardId(deformToId)), false, deformFromObject:GetRecordDeltaHp(),
				skinId, checknumber(cardConfig.scale), checkint(cardConfig.defaultLayer or 0),
				G_BattleLogicMgr:GetPhaseChangeDataByNpcId(deformToId)
			)

			local tag = G_BattleLogicMgr:GetBData():GetTagByTagType(isEnemy and BattleTags.BT_OTHER_ENEMY or BattleTags.BT_FRIEND)
			local o = G_BattleLogicMgr:GetABattleObj(tag, objInfo)

			-- 设置一次当前波数
			o:SetObjectWave(deformFromObject:GetObjectWave())
			-- 设置一次队伍序号
			o:SetObjectTeamIndex(deformFromObject:GetObjectTeamIndex())

			-- 判断血量类型
			if ConfigDeformType.HOLD_HP == data.deformType then
				local hpPercent = deformFromObject:GetMainProperty():GetCurHpPercent()
				o:HpPercentChangeForce(hpPercent)
			end

			--***---------- 刷新渲染层 ----------***--
			-- 创建变身后物体
			G_BattleLogicMgr:AddRenderOperate(
				'G_BattleRenderMgr',
				'CreateAObjectView',
				o:GetViewModelTag(), objInfo, false
			)
			--***---------- 刷新渲染层 ----------***--

			-- 初始化渲染层状态
			o:InitObjectRender()
			------------ 创建变身后的物体 ------------

			------------ 处理逻辑 ------------
			-- 杀死变身源
			deformFromObject:KillSelf(true)
			------------ 处理逻辑 ------------

			--***---------- 刷新渲染层 ----------***--
			-- 开始进行阶段转换
			G_BattleLogicMgr:AddRenderOperate(
				'G_BattleRenderMgr',
				'PhaseChangeDeformCustomize',
				deformFromObject:GetViewModelTag(), deformFromObject:GetOTag(), data.deformFromDisappearActionName,
				data.deformToDelayTime,
				o:GetViewModelTag(), o:GetOTag(), data.deformToAppearActionName
			)
			--***---------- 刷新渲染层 ----------***--

		end

	end
end
--[[
阶段转换类型7 add退场
@params phaseData PhaseChangeSturct 阶段转换数据
--]]
function BasePhaseDriver:AdditionExeunt(phaseData)
	------------ 喊话 ------------
	self:Speak(phaseData.dialogueData)
	------------ 喊话 ------------

	local cardId = nil
	local obj = nil

	for _, data in ipairs(phaseData.phaseData) do

		local isEnemy = ConfigCampType.ENEMY == data.npcCampType
		cardId = data.npcId
		obj = G_BattleLogicMgr:IsObjAliveByCardId(cardId, isEnemy)

		if nil ~= obj then

			-- 设置逻辑隐藏
			obj:SetCanBeSearched(false)

			-- 计算目标点
			local targetPosId = data.disappearPosId
			local targetPosConfig = CommonUtils.GetConfig('quest', 'battlePosition', targetPosId)

			if nil == targetPosConfig then
				-- 原地消失
			else
				local tr, tc = checkint(targetPosConfig.coordinate[2]), checkint(targetPosConfig.coordinate[1])
				local targetCellInfo = G_BattleLogicMgr:GetCellPosByRC(tr, tc)
				local targetPos = cc.p(
					targetCellInfo.cx,
					targetCellInfo.cy
				)

				-- 清除buff
				obj:ClearBuff()
				obj:ForceMove(targetPos, data.disappearActionName, function ()

					-- 清空动画
					obj:ClearAnimations()

					-- 杀死自己
					obj:KillSelf(true)

					--***---------- 刷新渲染层 ----------***--
					-- 创建变身后物体
					obj:ForceShowSelf(false)
					-- 清空渲染层的动画
					obj:ClearRenderAnimations()
					--***---------- 刷新渲染层 ----------***--
				end)

			end

		end

	end
end
--[[
喊话
@params dialogueData table {
	dialogueId int 对话框id
	dialogueContent 对话内容
}
--]]
function BasePhaseDriver:Speak(dialogueData)
	local dialogueTarget = nil

	for k,v in pairs(dialogueData) do
		dialogueTarget = G_BattleLogicMgr:IsObjAliveByCardId(checkint(k), self:GetOwner():IsEnemy(true))
		if nil ~= dialogueTarget then

			--***---------- 刷新渲染层 ----------***--
			-- 喊话
			self:GetOwner():Speak(v.dialogueId, v.dialogueContent)
			--***---------- 刷新渲染层 ----------***--

		end
	end
end
--[[
阶段转换类型9 出现主线剧情对话
--]]
function BasePhaseDriver:PhaseChangeShowPlotStage(phaseData)
	-- TODO --
	-- /***********************************************************************************************************************************\
	--  * 暂时只处理配表中的第一段剧情
	-- \***********************************************************************************************************************************/

	local firstPlot = phaseData.phaseData[1]
	self:ShowPlotStage(firstPlot.plotId, firstPlot.forcePauseGame, nil)

	-- local plotIndex_ = 1
	-- local PlotOverCallback = function ()
	-- 	plotIndex_ = plotIndex_ + 1

	-- 	local nextPlotData = phaseData.phaseData[plotIndex_]
	-- 	if nil ~= nextPlotData then
	-- 		self:ShowPlotStage(nextPlotData.plotId, nextPlotData.forcePauseGame, PlotOverCallback)
	-- 	end
	-- end

	-- TODO --
end
--[[
显示主线对话
@params plotId int 主线对话id
@params pauseGame bool 是否暂停游戏
@params cb function 剧情结束的回调函数
--]]
function BasePhaseDriver:ShowPlotStage(plotId, pauseGame, cb)
	------------ 暂停游戏 ------------
	if true == pauseGame and not G_BattleLogicMgr:IsMainLogicPause() then
		-- 暂停游戏
		G_BattleLogicMgr:PauseGame()
	end
	------------ 暂停游戏 ------------

	--***---------- 刷新渲染层 ----------***--
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'PhaseChangeShowPlotStage',
		plotId, nil, false
	)
	--***---------- 刷新渲染层 ----------***--
end
---------------------------------------------------
-- phase logic end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
根据序号获取转阶段信息
@params index int 序号
--]]
function BasePhaseDriver:GetPCDataByIndex(index)
	return self.phaseChangeData[index]
end
--[[
添加一个转阶段信息
@params phaseInfo map {
	phaseId int 转阶段id
	index int 转阶段序号
}
--]]
function BasePhaseDriver:AddAPhaseChangeInfo(phaseInfo)
	table.insert(self.phases, 1, phaseInfo)
end
--[[
移除一个转阶段信息
@params index 转阶段序号
--]]
function BasePhaseDriver:RemoveAPhaseChangeInfo(index)
	for i = #self.phases, 1, -1 do
		pcinfo = self.phases[i]
		if pcinfo.index == index then
			table.remove(self.phases, i)
		end
	end
end
--[[
获取死亡触发的阶段转换计数
@return _ int 死亡触发的阶段转换计数
--]]
function BasePhaseDriver:GetDiePhaseChangeCounter()
	return self.diePhaseChangeCounter
end
function BasePhaseDriver:SetDiePhaseChangeCounter(counter)
	self.diePhaseChangeCounter = counter
end
---------------------------------------------------
-- get set end --
---------------------------------------------------
--[[
初始化转阶段配置数据 由于各种触发条件相互影响 此处处理优先级规则
--]]
function BasePhaseDriver:InitPhaseConfig()
	self.phases = {}

	------------ 此处不再排序是认为关卡表中的actionId字段是默认根据行为表中的自增id排序的 ------------
	for i, pcdata in ipairs(self.phaseChangeData) do

		local pinfo = {
			phaseId = pcdata.phaseId,
			index = i
		}

		-- 倒序插入 防止移除时出现问题
		table.insert(self.phases, 1, pinfo)
		-- table.insert(self.phasesByTriggerType[pcdata.phaseTriggerType], pinfo)
	end
	------------ 此处不再排序是认为关卡表中的actionId字段是默认根据行为表中的自增id排序的 ------------

end

return BasePhaseDriver
