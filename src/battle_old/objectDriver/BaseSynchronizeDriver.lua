--[[
同步驱动基类
--]]
local BaseSynchronizeDriver = class('BaseSynchronizeDriver')
--[[
constructor
--]]
function BaseSynchronizeDriver:ctor( ... )
	local args = unpack{(...)}
	self.owner = args.owner
	
	self:Init()
end
---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化数据结构
--]]
function BaseSynchronizeDriver:Init() 
	self.nextLogicFrameState = {}
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- logic begin --
---------------------------------------------------
--[[
获取下一个逻辑帧需要执行的状态
--]]
function BaseSynchronizeDriver:GetNextLogicFrameState()
	if not self:GetOwner():canAct() then return nil end

	local fsmStateInfo = nil

	if OState.NORMAL == self:GetOwner():getState() then
		-- 处于正常状态 需要索敌
		fsmStateInfo = ObjectFSMStruct.New(BattleObjectFSMState.SEEK_ATTACK_TARGET)
	elseif OState.BATTLE == self:GetOwner():getState() then
		-- 战斗状态 进一步判断
		local canCastSkillId = self:GetOwner().castDriver:CanDoAction(ActionTriggerType.CD)
		if nil ~= canCastSkillId then
			-- 存在cd技能
			fsmStateInfo = ObjectFSMStruct.New(BattleObjectFSMState.CAST, {castSkillId = canCastSkillId})
		else
			-- 不存在cd技能 准备普通攻击
			if nil == BMediator:IsObjAliveByTag(self:GetOwner().attackDriver:GetAttackTargetTag()) then
				-- 攻击对象死亡
				fsmStateInfo = ObjectFSMStruct.New(BattleObjectFSMState.SEEK_ATTACK_TARGET)
			else
				local canAttack = self:GetOwner().attackDriver:CanAttackByDistance(self:GetOwner().attackDriver:GetAttackTargetTag())
				if true == canAttack then
					-- 距离满足 判断攻击
					canAttack = self:GetOwner().attackDriver:CanDoAction()
					if true == canAttack then
						-- 可以攻击 判定触发的小技能
						canCastSkillId = self:GetOwner().castDriver:CanDoAction(ActionTriggerType.ATTACK)
						if nil ~= canCastSkillId then
							-- 可以施放小技能
							fsmStateInfo = ObjectFSMStruct.New(BattleObjectFSMState.CAST, {castSkillId = canCastSkillId})
						else
							-- 没有可以施放的小技能 普攻
							fsmStateInfo = ObjectFSMStruct.New(BattleObjectFSMState.ATTACK, {aTargetTag = self:GetOwner().attackDriver:GetAttackTargetTag()})
						end
					end
				else
					-- 距离不满足 移动
					fsmStateInfo = ObjectFSMStruct.New(BattleObjectFSMState.MOVE, {aTargetTag = self:GetOwner().attackDriver:GetAttackTargetTag()})
				end
			end
		end
	end

	return fsmStateInfo
end
--[[
根据逻辑帧信息做出对应的处理
@params fsmData ObjectFSMStruct
--]]
function BaseSynchronizeDriver:DoActionByLogicFrameState(fsmData)
	if nil == fsmData then
		-- 空状态
	elseif BattleObjectFSMState.SEEK_ATTACK_TARGET == fsmData.state then
		-- 索敌
		self:GetOwner():seekAttackTarget()
	elseif BattleObjectFSMState.MOVE == fsmData.state then
		print('here enter move >>>>>>>>>>>>>>', self:GetOwner():getOTag(), fsmData.aTargetTag)
		self:GetOwner().moveDriver:OnActionEnter(fsmData.aTargetTag)
	elseif BattleObjectFSMState.ATTACK == fsmData.state then
		-- 攻击
		self:GetOwner():attack(fsmData.aTargetTag)
	elseif BattleObjectFSMState.CAST == fsmData.state then
		-- 施法行为
		self:GetOwner():cast(fsmData.castSkillId)
	end	
end
---------------------------------------------------
-- logic end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
获取拥有者
--]]
function BaseSynchronizeDriver:GetOwner()
	return self.owner
end
--[[
下一个逻辑帧的状态
--]]
-- function BaseSynchronizeDriver:GetNextLogicFrameState()
-- 	return self.nextLogicFrameState
-- end
-- function BaseSynchronizeDriver:SetNextLogicFrameState(state)
-- 	self.nextLogicFrameState = state
-- end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return BaseSynchronizeDriver
