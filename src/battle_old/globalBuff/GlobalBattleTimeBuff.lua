--[[
全局影响能力的buff
--]]
local BaseGlobalBuff = __Require('battle.globalBuff.BaseGlobalBuff')
local GlobalBattleTimeBuff = class('GlobalBattleTimeBuff', BaseGlobalBuff)

---------------------------------------------------
-- control logic begin --
---------------------------------------------------
--[[
@overdide
产生效果
--]]
function GlobalBattleTimeBuff:CauseEffect()
	-- 计算当前时间百分比
	local timePercent = math.floor(BMediator:GetBData().leftTime / BMediator:GetBData():getGameTime() * 100) * 0.01
	-- 变化
	local newGameTime = BMediator:GetBData():getGameTime() * (1 + self.value)
	-- 设置新时间
	BMediator:GetBData():setGameTime(newGameTime)
	-- 刷新剩余时间
	BMediator:GetBData().leftTime = newGameTime * timePercent
	-- 刷新时间标签
	BMediator:RefreshTimeLabel(BMediator:GetBData().leftTime)
end
--[[
@override
恢复效果
--]]
function GlobalBattleTimeBuff:RecoverEffect()
	-- 计算当前时间百分比
	local timePercent = math.floor(BMediator:GetBData().leftTime / BMediator:GetBData():getGameTime() * 100) * 0.01
	-- 变化
	local newGameTime = BMediator:GetBData():getGameTime() * (1 - self.value)
	-- 设置新时间
	BMediator:GetBData():setGameTime(newGameTime)
	-- 刷新剩余时间
	BMediator:GetBData().leftTime = newGameTime * timePercent
	-- 刷新时间标签
	BMediator:RefreshTimeLabel(BMediator:GetBData().leftTime)
end
---------------------------------------------------
-- control logic end --
---------------------------------------------------

return GlobalBattleTimeBuff
