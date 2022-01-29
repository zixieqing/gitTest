--[[
车轮战模式结束驱动
--]]
local BattleEndDriver = __Require('battle.battleDriver.BattleEndDriver')
local TagMatchEndDriver = class('TagMatchEndDriver', BattleEndDriver)

---------------------------------------------------
-- init logic begin --
---------------------------------------------------
--[[
@override
初始化逻辑
--]]
function TagMatchEndDriver:Init()
	--[[
		ValueConstants = {
			V_INFINITE 				= -1, 	-- 负
			V_NONE 					= 0, 	-- 未分出胜负
			V_NORMAL 				= 1 	-- 胜
		}
	--]]
	self.friendWin = ValueConstants.V_NONE
end
---------------------------------------------------
-- init logic begin --
---------------------------------------------------

---------------------------------------------------
-- control logic begin --
---------------------------------------------------
--[[
@override
是否能进行逻辑
@return result BattleResult 战斗结束类型
--]]
function TagMatchEndDriver:CanDoLogic()
	local battleMgr = self:GetOwner()
	local bdata = battleMgr:GetBData()

	local result = BattleResult.BR_CONTINUE

	if 0 >= bdata.leftTime then

		-- 时间结束 视为失败
		result = BattleResult.BR_FAIL
		self:SetFriendWin(ValueConstants.V_INFINITE)


	elseif 0 == #bdata.sortBattleObjs.friend then

		-- 我方团灭
		if bdata:canBuyRevival() then
			-- 可以买活
			result = BattleResult.BR_RESCUE
		else
			-- 检查是否存在下一队
			if self:GetOwner():HasNextTeam(false) then
				-- 存在下一队
				result = BattleResult.BR_NEXT_WAVE
			else
				-- 彻底团灭
				result = BattleResult.BR_FAIL	
			end

			-- 设置当前波敌方胜
			self:SetFriendWin(ValueConstants.V_INFINITE)
		end

	elseif 0 == #bdata.sortBattleObjs.enemy then

		-- 检查是否存在下一队
		if self:GetOwner():HasNextTeam(true) then
			-- 存在下一队
			result = BattleResult.BR_NEXT_WAVE
		else
			-- 彻底团灭
			result = BattleResult.BR_SUCCESS	
		end

		-- 设置当前波友方胜
		self:SetFriendWin(ValueConstants.V_NORMAL)

	end

	return result
end
---------------------------------------------------
-- control logic end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
输赢记录
--]]
function TagMatchEndDriver:IsFriendWin()
	return self.friendWin
end
function TagMatchEndDriver:SetFriendWin(v)
	self.friendWin = v
end
--[[
是否存在下一波
@params wipeOutIsEnemy bool 团灭方 是否是敌方
@return _ bool 是否存在下一波
--]]
function TagMatchEndDriver:HasNextWave(wipeOutIsEnemy)
	return BattleEndDriver.HasNextWave(self, wipeOutIsEnemy)
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return TagMatchEndDriver
