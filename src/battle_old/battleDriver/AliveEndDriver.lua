--[[
存活模式结束驱动
--]]
local BattleEndDriver = __Require('battle.battleDriver.BattleEndDriver')
local AliveEndDriver = class('AliveEndDriver', BattleEndDriver)

---------------------------------------------------
-- init logic begin --
---------------------------------------------------
--[[
@override
初始化逻辑
--]]
function AliveEndDriver:Init()
	self.actionTrigger = {
		[ActionTriggerType.CD] = checkint(self.stageCompleteInfo.aliveTime)
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
是否能进行逻辑
@return result BattleResult 战斗结束类型
--]]
function AliveEndDriver:CanDoLogic()
	local battleMgr = self:GetOwner()
	local bdata = battleMgr:GetBData()
	local result = BattleResult.BR_CONTINUE

	local leftTime = self:GetActionTrigger(ActionTriggerType.CD)

	if 0 >= leftTime then
		-- 成功
		if bdata:getNextWave() > bdata:getStageTotalWave() then
			-- 没有下一波 胜利
			result = BattleResult.BR_SUCCESS
		else
			-- 下一波
			result = BattleResult.BR_NEXT_WAVE
		end
	elseif 0 >= bdata.leftTime then
		-- 总时间结束 视为失败
		result = BattleResult.BR_FAIL
	else
		if 0 >= #bdata.sortBattleObjs.friend then
			-- 我方团灭
			if bdata:canBuyRevival() then
				-- 可以买活
				result = BattleResult.BR_RESCUE
			else
				-- 团灭
				result = BattleResult.BR_FAIL
			end
		elseif 0 >= #bdata.sortBattleObjs.enemy then
			-- 敌方团灭
			if bdata:getNextWave() > bdata:getStageTotalWave() then
				-- 没有下一波 胜利
				result = BattleResult.BR_SUCCESS
			else
				-- 下一波
				result = BattleResult.BR_NEXT_WAVE
			end
		end
	end

	return result
end
--[[
@override
逻辑进行中
--]]
function AliveEndDriver:OnLogicUpdate(dt)
	self:UpdateActionTrigger(ActionTriggerType.CD, dt)
	-- 刷新一次目标倒计时
	local countdown = BattleUtils.GetFormattedTimeForView(self:GetActionTrigger(ActionTriggerType.CD))
	BMediator:GetViewComponent():RefreshAliveCountdown(math.ceil(countdown))
end
--[[
刷新触发器
@params actionTriggerType ActionTriggerType 触发类型
@params delta number 变化量
--]]
function AliveEndDriver:UpdateActionTrigger(actionTriggerType, delta)
	if ActionTriggerType.CD == actionTriggerType then
		self.actionTrigger[ActionTriggerType.CD] = math.max(0, self.actionTrigger[ActionTriggerType.CD] - delta)
	end
end
--[[
获取触发器
@params actionTriggerType ActionTriggerType 触发类型
@return _ int 触发器值
--]]
function AliveEndDriver:GetActionTrigger(actionTriggerType)
	return self.actionTrigger[actionTriggerType]
end
---------------------------------------------------
-- control logic end --
---------------------------------------------------

return AliveEndDriver
