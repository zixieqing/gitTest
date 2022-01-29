--[[
战斗结束控制器 普通类型
@params table {
	wave int 波数
	stageCompleteInfo StageCompleteSturct 战斗结束条件数据
}
--]]
local BaseBattleDriver = __Require('battle.battleDriver.BaseBattleDriver')
local BattleEndDriver = class('BattleEndDriver', BaseBattleDriver)
--[[
constructor
--]]
function BattleEndDriver:ctor( ... )
	BaseBattleDriver.ctor(self, ...)
	self.driverType = BattleDriverType.END_DRIVER

	local args = unpack({...})

	self.wave = args.wave
	self.stageCompleteInfo = args.stageCompleteInfo

	self:Init()
end
---------------------------------------------------
-- init logic begin --
---------------------------------------------------
--[[
@override
初始化逻辑
--]]
function BattleEndDriver:Init()

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
function BattleEndDriver:CanDoLogic()
	local battleMgr = self:GetOwner()
	local bdata = battleMgr:GetBData()

	local result = BattleResult.BR_CONTINUE

	if 0 >= bdata:GetLeftTime() then

		-- 时间结束 视为失败
		result = BattleResult.BR_FAIL

	elseif 0 == #G_BattleLogicMgr:GetAliveBattleObjs(false) then

		-- 我方团灭
		if bdata:CanBuyRevival() then
			-- 可以买活
			result = BattleResult.BR_RESCUE
		else
			-- 团灭
			result = BattleResult.BR_FAIL
		end

	elseif 0 == #G_BattleLogicMgr:GetAliveBattleObjs(true) then

		-- 敌军团灭进行下一波
		if bdata:GetNextWave() > bdata:GetStageTotalWave() then
			-- 没有下一波 胜利
			result = BattleResult.BR_SUCCESS
		else
			-- 下一波
			result = BattleResult.BR_NEXT_WAVE
		end

	end

	return result
end
--[[
@override
逻辑开始
@params battleResult BattleResult 这一帧的战斗结果
@return needReturnMainUpdate 是否需要中断主逻辑
--]]
function BattleEndDriver:OnLogicEnter(battleResult)
	local needReturnMainUpdate = false
	local needDisableTouch = false

	if BattleResult.BR_SUCCESS == battleResult or BattleResult.BR_FAIL == battleResult then

		-- if self:GetOwner():IsBattleTouchEnable() then self:GetOwner():SetBattleTouchEnable(false) end
		print('stop here -> ', battleResult)
		self:HandleGameResult(battleResult)
		needReturnMainUpdate = true

		needDisableTouch = true

	elseif BattleResult.BR_NEXT_WAVE == battleResult then

		-- if self:GetOwner():IsBattleTouchEnable() then self:GetOwner():SetBattleTouchEnable(false) end
		self:GetOwner():SetGState(GState.TRANSITION)
		print('stop here -> ', battleResult)
		needReturnMainUpdate = true

		needDisableTouch = true

	elseif BattleResult.BR_RESCUE == battleResult then

		-- if self:GetOwner():IsBattleTouchEnable() then self:GetOwner():SetBattleTouchEnable(false) end
		self:GetOwner():SetGState(GState.BLOCK)
		print('stop here and ready to buy revival -> ', battleResult)
		needReturnMainUpdate = true

		needDisableTouch = true

	end

	--***---------- 插入刷新渲染层计时器 ----------***--
	if true == needDisableTouch then
		G_BattleLogicMgr:AddRenderOperate(
			'G_BattleRenderMgr',
			'SetBattleTouchEnable',
			false
		)
	end
	--***---------- 插入刷新渲染层计时器 ----------***--

	return needReturnMainUpdate
end
--[[
@override
逻辑进行中
--]]
function BattleEndDriver:OnLogicUpdate(dt)

end
--[[
@override
逻辑结束
--]]
function BattleEndDriver:OnLogicExit()

end
--[[
@override
逻辑被打断
--]]
function BattleEndDriver:OnLogicBreak()
	
end
--[[
处理战斗结果
@params battleResult BattleResult 这一帧的战斗结果
--]]
function BattleEndDriver:HandleGameResult(battleResult)
	if self:GetOwner():IsBattleTouchEnable() then 
		self:GetOwner():SetBattleTouchEnable(false)
	end
	self:GameOver(battleResult)
end
--[[
战斗结束
@params battleResult BattleResult 这一帧的战斗结果
--]]
function BattleEndDriver:GameOver(battleResult)
	if BattleResult.BR_SUCCESS == battleResult then
		self:GetOwner():SetGState(GState.SUCCESS)
	elseif BattleResult.BR_FAIL == battleResult then
		self:GetOwner():SetGState(GState.FAIL)
	end
end
---------------------------------------------------
-- control logic end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
获取波数
--]]
function BattleEndDriver:GetWave()
	return self.wave
end
--[[
获取类型
@return _ ConfigStageCompleteType 过关类型
--]]
function BattleEndDriver:GetCompleteType()
	return self.stageCompleteInfo.completeType
end
--[[
是否存在下一波
@params wipeOutIsEnemy bool 团灭方 是否是敌方
@return _ bool 是否存在下一波
--]]
function BattleEndDriver:HasNextWave(wipeOutIsEnemy)
	return self:GetOwner():GetBData():GetNextWave() <= self:GetOwner():GetBData():GetStageTotalWave()
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return BattleEndDriver
