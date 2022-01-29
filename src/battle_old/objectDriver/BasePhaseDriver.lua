--[[
阶段转换驱动器
--]]
local BaseActionDriver = __Require('battle.objectDriver.BaseActionDriver')
local BasePhaseDriver = class('BasePhaseDriver', BaseActionDriver)
local cardMgr = AppFacade.GetInstance():GetManager('CardManager')
--[[
@override
constructor
--]]
function BasePhaseDriver:ctor( ... )
	BaseActionDriver.ctor(self, ...)

	local args = unpack({...})
	self.phaseChangeData = args.phaseChangeData
	self.diePhaseChangeCounter = nil
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
	self:InitActionTrigger()
	self:InitPhaseConfig()
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
			self:GetOwner():getOCardName(),
			self:GetOwner():getOCardId(),
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
		self:PhaseChageSpeakAndEscape(phaseData)
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
	if ConfigPhaseTriggerType.LOST_HP == pcdata.phaseTriggerType then

		-- 判断宿主损失血量是否大于一定值
		return pcdata.phaseTriggerValue <= self:GetActionTrigger(ActionTriggerType.HP)

	elseif ConfigPhaseTriggerType.APPEAR_TIME == pcdata.phaseTriggerType then

		-- 判断宿主是否在场到达一定时间
		return pcdata.phaseTriggerValue <= self:GetActionTrigger(ActionTriggerType.CD)

	elseif ConfigPhaseTriggerType.OBJ_DIE == pcdata.phaseTriggerType then

		-- 判断宿主是否死亡
		return self:GetActionTrigger(ActionTriggerType.DIE)

	elseif ConfigPhaseTriggerType.OBJ_SKILL == pcdata.phaseTriggerType then

		-- 判断目标是否释放过技能
		local triggerInfo = self:GetActionTrigger(ActionTriggerType.SKILL)
		local info = triggerInfo[pcdata.phaseTriggerNpcCampType][tostring(pcdata.phaseTriggerNpcId)]
		if nil ~= info then
			return info[tostring(pcdata.phaseTriggerValue)] and true == info[tostring(pcdata.phaseTriggerValue)]
		end
		return false

	end
end
--[[
@override
消耗做出行为需要的资源
@params index int 根据优先级保存的转阶段信息序号
--]]
function BasePhaseDriver:CostActionResources(index)
	for i = #self.phases, 1, -1 do
		pcinfo = self.phases[i]
		if pcinfo.index == index then
			table.remove(self.phases, i)
		end
	end
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
	BMediator:PauseMainLogic()

	-- 先震屏 再喊话 再执行后续
	BMediator:GetViewComponent():ShakeWorld(function ()

		local deformNpcId = nil
		local deformSource = nil
		local dialogueData = nil
		for i,v in ipairs(phaseData.phaseData) do
			deformNpcId = v.deformFromId
			-- 变身源
			deformSource = BMediator:IsObjAliveByCardId(deformNpcId, self:GetOwner():isEnemy(true))
			dialogueData = phaseData.dialogueData[tostring(deformNpcId)]
			if nil ~= deformSource then
				deformSource:DoSpineAnimation(true, nil, sp.AnimationName.chant, true)

				if nil ~= dialogueData then
					deformSource.view.viewComponent:showDialogue(
						dialogueData.dialogueId,
						dialogueData.dialogueContent,
						0.2,
						function ()
							------------ 变身光圈 ------------
							local deformNpcCenterPos = cc.p(
								deformSource.view.viewComponent:getPositionX(),
								display.cy
							)
							local deformEffect = SpineCache(SpineCacheName.BATTLE):createWithName('phase_deform_effect')
							deformEffect:update(0)
							deformEffect:setPosition(deformNpcCenterPos)
							BMediator:GetBattleRoot():addChild(deformEffect, BATTLE_E_ZORDER.BULLET + 1)
							deformEffect:setAnimation(0, sp.AnimationName.idle, false)

							local effectAnimationsData = SpineCache(SpineCacheName.BATTLE):getAnimationsDataByName('phase_deform_effect')
							local deformTime = effectAnimationsData[sp.AnimationName.idle].duration
							local deformEffectActionSeq = cc.Sequence:create(
								cc.DelayTime:create(deformTime * 0.4),
								cc.CallFunc:create(function ()
									BMediator:GetViewComponent():ShakeWorld()
								end),
								cc.DelayTime:create(deformTime * 0.6),
								cc.RemoveSelf:create()
							)
							deformEffect:runAction(deformEffectActionSeq)

							-- local deformNpcCenterPos = cc.p(
							-- 	deformSource.view.viewComponent:getPositionX(),
							-- 	deformSource.view.viewComponent:getPositionY() + deformSource.borderBox.viewBox.height * 0.5
							-- )
							-- local deformCircle = display.newNSprite(_res('ui/battle/result_bg_2.png'), deformNpcCenterPos.x, deformNpcCenterPos.y)
							-- BMediator:GetBattleRoot():addChild(deformCircle, BATTLE_E_ZORDER.BULLET + 1)
							-- local deformTime = 1
							-- local circleActionSeq = cc.Sequence:create(
							-- 	cc.Spawn:create(
							-- 		cc.ScaleTo:create(deformTime, 3),
							-- 		cc.Sequence:create(
							-- 			cc.DelayTime:create(deformTime * 0.5),
							-- 			cc.CallFunc:create(function ()
							-- 				BMediator:GetViewComponent():ShakeWorld()
							-- 			end)
							-- 		)
							-- 	),
							-- 	cc.RemoveSelf:create()
							-- )
							-- deformCircle:runAction(circleActionSeq)
							------------ 变身光圈 ------------

							------------ 变身npc处理 ------------
							-- 变身源消失
							deformSource.view.viewComponent:deformDisappear(deformTime * 0.4,
								function ()
									-- 创建变身后形态
									-- 创建坐标信息
									local cardConf = CardUtils.GetCardConfig(v.deformToId)

									local pos = cc.p(
										deformSource.view.viewComponent:getPositionX(),
										deformSource.view.viewComponent:getPositionY()
									)
									local rcInfo = BMediator:GetRowColByPos(pos)
									local location = ObjectLocation.New(pos.x, pos.y, rcInfo.r, rcInfo.c)

									-- 创建怪物属性信息
									local objProperty = __Require('battle.object.MonsterProperty').new(MonsterPropertyConstructStruct.New(
										v.deformToId,
										deformSource:getObjectLevel(),
										v.deformToAttrGrow,
										v.deformToSkillGrow,
										ObjPFixedAttrStruct.New(),
										BMediator:GetBData():getBattleConstructData().enemyFormation.propertyAttr,
										location
									))

									local objFeature = BattleUtils.GetObjFeatureByCareer(checkint(cardConf.career))
									local skinId = CardUtils.GetCardSkinId(v.deformToId)
									local isEnemy = v.deformToCampType == ConfigCampType.ENEMY

									local objInfo = ObjectConstructorStruct.New(
										v.deformToId, location, deformSource.objInfo.teamPosition, objFeature, checkint(cardConf.career), isEnemy,
										objProperty, nil, nil, EXAbilityConstructorStruct.New(deformToId, CardUtils.GetCardEXAbilitySkillsByCardId(deformToId)), false, deformSource:GetRecordDeltaHp(),
										skinId, checknumber(cardConf.scale), checkint(cardConf.defaultLayer or 0),
										BMediator:GetPhaseChangeDataByNpcId(v.deformToId)
									)

									local tagInfo = BMediator:GetBData():getObjTagInfo(objInfo.isEnemy, true)

									local o = BMediator:GetABattleObj(objInfo, tagInfo)
									BMediator:GetBattleRoot():addChild(o.view.viewComponent)
									o:awake()

									-- 设置一次当前波数
									o:setObjectWave(deformSource:getObjectWave())

									BMediator:SendObjEvent(ObjectEvent.OBJECT_CREATED, {tag = o:getOTag()})

									-- 判断血量类型
									if ConfigDeformType.HOLD_HP == v.deformType then
										local hpPercent = deformSource:getMainProperty():getCurHpPercent()
										o:setHpPercentForce(hpPercent)
									end

									o.view.viewComponent:setVisible(false)
									o.view.viewComponent:setOpacity(0)
									o.view.viewComponent:deformAppear(0, deformTime * 0.6,
										function ()
											-- 杀死变身源
											deformSource:getSpineAvatar():clearTracks()
											deformSource:killSelf(true)
											-- 各单位眩晕解除
											local obj = nil
											for i = #BMediator:GetBData().sortBattleObjs.friend, 1, -1 do
												obj = BMediator:GetBData().sortBattleObjs.friend[i]
												obj:forceStun(false)
											end
											-- 重新开始游戏
											BMediator:ResumeMainLogic()
										end
									)
								end
							)
							------------ 变身npc处理 ------------
						end
					)
				end
			end
		end
	end)
	-- 眩晕各单位
	local obj = nil
	for i = #BMediator:GetBData().sortBattleObjs.friend, 1, -1 do
		obj = BMediator:GetBData().sortBattleObjs.friend[i]
		obj:forceStun(true)
	end
end
--[[
阶段转换类型2 喊话+逃跑
--]]
function BasePhaseDriver:PhaseChageSpeakAndEscape(phaseData)
	local escapeNpc = nil
	local dialogueData = nil
	for i,v in ipairs(phaseData.phaseData) do
		escapeNpc = BMediator:IsObjAliveByCardId(v.escapeNpcId, self:GetOwner():isEnemy(true))
		if nil ~= escapeNpc and escapeNpc.appearWaveAfterEscape ~= BMediator:GetBData():getCurrentWave() then
			escapeNpc:clearBuff()
			-- 将逃跑怪物设置全免疫
			escapeNpc:setAllImmune(true)
			-- 给对象加上1点血起死回生
			escapeNpc:getMainProperty():setp(
				ObjP.HP,
				math.max(1, self:GetOwner():getMainProperty():getCurrentHp():ObtainVal())
			)
			-- 设置逃跑状态
			escapeNpc.moveDriver.escaping = true
			-- 判断怪物去留
			if ConfigEscapeType.ESCAPE == v.escapeType then
				-- 彻底逃跑
				BMediator:GetBData():addAObjToRest(escapeNpc)
			elseif ConfigEscapeType.RETREAT == v.escapeType then
				-- 中场休息 后续波数继续
				escapeNpc.appearWaveAfterEscape = v.appearWave
				escapeNpc:setHpPercentForce(v.appearHpPercent)
				BMediator:GetBData():addAObjToRest(escapeNpc)
			end
			BMediator:GetBData():removeABattleObj(escapeNpc)

			dialogueData = phaseData.dialogueData[tostring(v.escapeNpcId)]
			if nil ~= dialogueData then
				-- 逃跑对象喊话
				escapeNpc.view.viewComponent:showDialogue(
					dialogueData.dialogueId,
					dialogueData.dialogueContent,
					0,
					function ()
						-- 回调逃跑
						escapeNpc:escape()
					end
				)
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
	local beckoner = BMediator:IsObjAliveByCardId(phaseData.phaseTriggerNpcId, self:GetOwner():isEnemy(true))
	local beckonerPos = beckoner:getLocation().po
	local beckonerRCInfo = BMediator:GetRowColByPos(beckonerPos)

	local cardConf = nil
	local beckonPos = nil
	local beckonRCInfo = nil
	for i,v in ipairs(phaseData.phaseData) do
		cardConf = CardUtils.GetCardConfig(v.beckonNpcId)

		-- 为召唤物随机一个行
		local r = BMediator:GetRandomManager():GetRandomInt(BMediator:GetBConf().ROW)
		beckonPos = BMediator:GetCellPosByRC(r, beckonerRCInfo.c)
		local location = ObjectLocation.New(
			beckonPos.cx,
			beckonPos.cy,
			r,
			beckonerRCInfo.c
		)

		-- 创建怪物属性信息
		local objProperty = __Require('battle.object.MonsterProperty').new(MonsterPropertyConstructStruct.New(
			v.beckonNpcId,
			beckoner:getObjectLevel(),
			v.beckonNpcAttrGrow,
			v.beckonNpcSkillGrow,
			ObjPFixedAttrStruct.New(),
			BMediator:GetBData():getBattleConstructData().enemyFormation.propertyAttr,
			location
		))

		local objFeature = BattleUtils.GetObjFeatureByCareer(checkint(cardConf.career))
		local skinId = CardUtils.GetCardSkinId(v.beckonNpcId)
		local isEnemy = v.beckonNpcCampType == ConfigCampType.ENEMY

		local objInfo = ObjectConstructorStruct.New(
			v.beckonNpcId, location, beckoner.objInfo.teamPosition + 1, objFeature, checkint(cardConf.career), isEnemy,
			objProperty, nil, nil, EXAbilityConstructorStruct.New(v.beckonNpcId, CardUtils.GetCardEXAbilitySkillsByCardId(v.beckonNpcId)), false, nil,
			skinId, checknumber(cardConf.scale), checkint(cardConf.defaultLayer or 0),
			BMediator:GetPhaseChangeDataByNpcId(v.beckonNpcId)
		)

		local tagInfo = BMediator:GetBData():getObjTagInfo(objInfo.isEnemy, true)

		local o = BMediator:GetABattleObj(objInfo, tagInfo)
		BMediator:GetBattleRoot():addChild(o.view.viewComponent)
		-- o:awake()

		-- 设置一次当前波数
		o:setObjectWave(beckoner:getObjectWave())

		BMediator:SendObjEvent(ObjectEvent.OBJECT_CREATED, {tag = o:getOTag()})

		-- 吹飞 让怪走进战场
		o:blewOff()
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

	------------ 创建add ------------
	local beckoner = BMediator:IsObjAliveByCardId(phaseData.phaseTriggerNpcId, self:GetOwner():isEnemy(true))

	for i,v in ipairs(phaseData.phaseData) do
		local cardConf = CardUtils.GetCardConfig(v.beckonNpcId)

		local appearPosId = v.beckonAppearPosId
		local appearPosConf = CommonUtils.GetConfig('quest', 'battlePosition', appearPosId)
		local ar, ac = checkint(appearPosConf.coordinate[2]), checkint(appearPosConf.coordinate[1])
		local appearCellInfo = BMediator:GetCellPosByRC(ar, ac)

		local targetPosId = v.beckonTargetPosId
		local targetPosConf = CommonUtils.GetConfig('quest', 'battlePosition', targetPosId)
		local tr, tc = checkint(targetPosConf.coordinate[2]), checkint(targetPosConf.coordinate[1])
		local targetCellInfo = BMediator:GetCellPosByRC(tr, tc)

		local location = ObjectLocation.New(
			appearCellInfo.cx,
			appearCellInfo.cy,
			ar,
			ac
		)

		-- 创建怪物属性信息
		local objProperty = __Require('battle.object.MonsterProperty').new(MonsterPropertyConstructStruct.New(
			v.beckonNpcId,
			beckoner:getObjectLevel(),
			v.beckonNpcAttrGrow,
			v.beckonNpcSkillGrow,
			ObjPFixedAttrStruct.New(),
			BMediator:GetBData():getBattleConstructData().enemyFormation.propertyAttr,
			location
		))
		
		local objFeature = BattleUtils.GetObjFeatureByCareer(checkint(cardConf.career))
		local skinId = CardUtils.GetCardSkinId(v.beckonNpcId)
		local isEnemy = v.beckonNpcCampType == ConfigCampType.ENEMY

		local objInfo = ObjectConstructorStruct.New(
			v.beckonNpcId, location, beckoner.objInfo.teamPosition + 1, objFeature, checkint(cardConf.career), isEnemy,
			objProperty, nil, nil, EXAbilityConstructorStruct.New(v.beckonNpcId, CardUtils.GetCardEXAbilitySkillsByCardId(v.beckonNpcId)), false, nil,
			skinId, checknumber(cardConf.scale), checkint(cardConf.defaultLayer or 0),
			BMediator:GetPhaseChangeDataByNpcId(v.beckonNpcId)
		)

		local tagInfo = BMediator:GetBData():getObjTagInfo(objInfo.isEnemy, true)

		local o = BMediator:GetABattleObj(objInfo, tagInfo)
		BMediator:GetBattleRoot():addChild(o.view.viewComponent)

		-- 设置一次当前波数
		o:setObjectWave(beckoner:getObjectWave())

		-- 设置不可被索敌
		o:setLuck(true)

		local targetPos = cc.p(
			targetCellInfo.cx,
			targetCellInfo.cy
		)
		o:forceMove(targetPos, v.beckonAppearActionName, function ()
			o:awake()
			BMediator:SendObjEvent(ObjectEvent.OBJECT_CREATED, {tag = o:getOTag()})
		end)
	end
	------------ 创建add ------------
end
--[[
阶段转换类型8 定制化变身
@params phaseData PhaseChangeSturct 阶段转换数据
--]]
function BasePhaseDriver:PhaseChangeDeformCustomize(phaseData)
	------------ 喊话 ------------
	self:Speak(phaseData.dialogueData)
	------------ 喊话 ------------

	-- 暂停主逻辑
	BMediator:PauseMainLogic()

	local deformFromId = nil
	local deformFromObj = nil
	local deformToId = nil

	for i,v in ipairs(phaseData.phaseData) do

		deformFromId = v.deformFromId
		deformFromIsEnemy = ConfigCampType.ENEMY == v.deformToCampType
		deformFromObj = BMediator:IsObjAliveByCardId(deformFromId, deformFromIsEnemy)

		if nil ~= deformFromObj then
			deformFromObj:forceDisappear(
				v.deformFromDisappearActionName,
				nil,
				function ()
					-- 隐藏变身源
					deformFromObj:forceHide()

					-- 创建变身后形态
					local cardConf = CardUtils.GetCardConfig(v.deformToId)

					local deformToPosId = v.deformToOriPosId
					local deformToPosConf = CommonUtils.GetConfig('quest', 'battlePosition', deformToPosId)
					local r, c = checkint(deformToPosConf.coordinate[2]), checkint(deformToPosConf.coordinate[1])
					local cellInfo = BMediator:GetCellPosByRC(r, c)

					local location = ObjectLocation.New(
						cellInfo.cx,
						cellInfo.cy,
						r,
						c
					)

					-- 创建怪物属性信息
					local objProperty = __Require('battle.object.MonsterProperty').new(MonsterPropertyConstructStruct.New(
						v.deformToId,
						deformFromObj:getObjectLevel(),
						v.deformToAttrGrow,
						v.deformToSkillGrow,
						ObjPFixedAttrStruct.New(),
						BMediator:GetBData():getBattleConstructData().enemyFormation.propertyAttr,
						location
					))

					local objFeature = BattleUtils.GetObjFeatureByCareer(checkint(cardConf.career))
					local skinId = CardUtils.GetCardSkinId(v.deformToId)
					local isEnemy = v.deformToCampType == ConfigCampType.ENEMY

					local objInfo = ObjectConstructorStruct.New(
						v.deformToId, location, deformFromObj.objInfo.teamPosition + 1, objFeature, checkint(cardConf.career), isEnemy,
						objProperty, nil, nil, EXAbilityConstructorStruct.New(v.deformToId, CardUtils.GetCardEXAbilitySkillsByCardId(v.deformToId)), false, deformFromObj:GetRecordDeltaHp(),
						skinId, checknumber(cardConf.scale), checkint(cardConf.defaultLayer or 0),
						BMediator:GetPhaseChangeDataByNpcId(v.deformToId)
					)

					local tagInfo = BMediator:GetBData():getObjTagInfo(objInfo.isEnemy, true)

					local o = BMediator:GetABattleObj(objInfo, tagInfo)
					BMediator:GetBattleRoot():addChild(o.view.viewComponent)

					-- 设置一次当前波数
					o:setObjectWave(deformFromObj:getObjectWave())

					-- 判断血量类型
					if ConfigDeformType.HOLD_HP == v.deformType then
						local hpPercent = deformFromObj:getMainProperty():getCurHpPercent()
						o:setHpPercentForce(hpPercent)
					end

					o:forceAppear(
						v.deformToAppearActionName,
						nil,
						function ()
							-- 杀死变身源
							deformFromObj:getSpineAvatar():clearTracks()
							deformFromObj:killSelf(true)
							-- 唤醒变身后物体
							o:awake()
							BMediator:SendObjEvent(ObjectEvent.OBJECT_CREATED, {tag = o:getOTag()})
							-- 重新开始游戏
							BMediator:ResumeMainLogic()
						end,
						v.deformToDelayTime
					)
				end
			)
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

	for i,v in ipairs(phaseData.phaseData) do
		local isEnemy = ConfigCampType.ENEMY == v.npcCampType
		local obj = BMediator:IsObjAliveByCardId(v.npcId, isEnemy)

		if nil ~= obj then

			-- 设置逻辑隐藏
			obj:setLuck(true)

			local targetPosId = v.disappearPosId
			local targetPosConf = CommonUtils.GetConfig('quest', 'battlePosition', targetPosId)

			if nil == targetPosConf then
				-- 原地消失
			else
				local tr, tc = checkint(targetPosConf.coordinate[2]), checkint(targetPosConf.coordinate[1])
				local targetCellInfo = BMediator:GetCellPosByRC(tr, tc)
				local targetPos = cc.p(
					targetCellInfo.cx,
					targetCellInfo.cy
				)
				-- 先到达目的地再消失
				obj:clearBuff()
				obj:forceMove(targetPos, v.disappearActionName, function ()
					obj:forceHide()
					-- 杀掉自己
					obj:getSpineAvatar():clearTracks()
					obj:killSelf(true)
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
		dialogueTarget = BMediator:IsObjAliveByCardId(checkint(k), self:GetOwner():isEnemy(true))
		if nil ~= dialogueTarget then
			dialogueTarget.view.viewComponent:showDialogue(v.dialogueId, v.dialogueContent)
		end
	end
end
--[[
阶段转换类型9 出现主线剧情对话
--]]
function BasePhaseDriver:PhaseChangeShowPlotStage(phaseData)
	local plotIndex_ = 1
	local firstPlot = phaseData.phaseData[1]

	-- local PlotOverCallback = function ()
	-- 	plotIndex_ = plotIndex_ + 1

	-- 	local nextPlotData = phaseData.phaseData[plotIndex_]
	-- 	if nil ~= nextPlotData then
	-- 		self:ShowPlotStage(nextPlotData.plotId, nextPlotData.forcePauseGame, PlotOverCallback)
	-- 	end
	-- end

	self:ShowPlotStage(firstPlot.plotId, firstPlot.forcePauseGame, nil)
end
--[[
显示主线对话
@params plotId int 主线对话id
@params pauseGame bool 是否暂停游戏
@params cb function 剧情结束的回调函数
--]]
function BasePhaseDriver:ShowPlotStage(plotId, pauseGame, cb)
	------------ 处理游戏暂停 ------------
	if pauseGame and not BMediator:IsPause() then
		BMediator:PauseGame()
	end
	------------ 处理游戏暂停 ------------

	------------ 恢复游戏加速 ------------
	-- 屏蔽触摸
	BMediator:SetBattleTouchEnable(false)
	cc.Director:getInstance():getScheduler():setTimeScale(1)
	------------ 恢复游戏加速 ------------

	local plotStage = require('Frame.Opera.OperaStage').new({
		id = plotId,
		path = nil,
		guide = false,
		cb = function ()
			------------ 处理游戏暂停 ------------
			if pauseGame and BMediator:IsPause() then
				BMediator:ResumeGame()
			end
			------------ 处理游戏暂停 ------------

			------------ 恢复游戏加速 ------------
			-- 屏蔽触摸
			BMediator:SetBattleTouchEnable(true)
			BMediator:SetTimeScale(BMediator:GetTimeScale())
			------------ 恢复游戏加速 ------------

			-- if nil ~= cb then
			-- 	scheduler.performWithDelayGlobal(cb, 1 * cc.Director:getInstance():getAnimationInterval())
			-- end
		end
	})
	plotStage:setPosition(display.center)
	sceneWorld:addChild(plotStage, GameSceneTag.Dialog_GameSceneTag)
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
获取转阶段对象 涉及到死亡对象调自己
--]]
---------------------------------------------------
-- get set end --
---------------------------------------------------
--[[
初始化转阶段配置数据 由于各种触发条件相互影响 此处处理优先级规则
--]]
function BasePhaseDriver:InitPhaseConfig()
	-- self.phasesByTriggerType = {
	-- 	[ConfigPhaseTriggerType.LOST_HP] = {},
	-- 	[ConfigPhaseTriggerType.APPEAR_TIME] = {},
	-- 	[ConfigPhaseTriggerType.OBJ_DIE] = {}
	-- }

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

	-- dump(self.phases)
	-- dump(self.phasesByTriggerType)

end

return BasePhaseDriver
