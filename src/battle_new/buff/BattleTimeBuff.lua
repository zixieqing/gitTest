--[[
免费买活buff
@params args ObjectBuffConstructorStruct
--]]
--]]
local BaseBuff = __Require('battle.buff.BaseBuff')
local BattleTimeBuff = class('BattleTimeBuff', BaseBuff)

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
@override
初始化buff特有的数据
--]]
function BattleTimeBuff:InitExtraValue()
	self.deltaTime = 0
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- logic begin --
---------------------------------------------------
--[[
@override
造成效果
@return result number 造成效果以后的结果
--]]
function BattleTimeBuff:CauseEffect()
	-- 计算当前时间百分比
	local timePercent = math.floor(G_BattleLogicMgr:GetBData():GetLeftTime() / G_BattleLogicMgr:GetBData():GetGameTime() * 100) * 0.01
	-- 变化
	local newGameTime, deltaTime = self:CalcFixedGameTime(G_BattleLogicMgr:GetBData():GetGameTime())
	-- 缓存一次差值
	self:SetDeltaTime(deltaTime)
	-- 设置新时间
	G_BattleLogicMgr:GetBData():SetGameTime(newGameTime)
	-- 刷新剩余时间
	local fixedLeftTime = newGameTime * timePercent
	G_BattleLogicMgr:GetBData():SetLeftTime(fixedLeftTime)

	--***---------- 刷新渲染层 ----------***--
	-- 刷新时间标签
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'RefreshTimeLabel',
		fixedLeftTime
	)
	--***---------- 刷新渲染层 ----------***--

	return 0
end
--[[
@override
恢复效果
--]]
function BattleTimeBuff:RecoverEffect()
	-- 计算当前时间百分比
	local timePercent = math.floor(G_BattleLogicMgr:GetBData():GetLeftTime() / G_BattleLogicMgr:GetBData():GetGameTime() * 100) * 0.01
	-- 变化
	local deltaTime = self:GetDeltaTime()
	local newGameTime = G_BattleLogicMgr:GetBData():GetGameTime() - deltaTime
	-- 设置新时间
	G_BattleLogicMgr:GetBData():SetGameTime(newGameTime)
	-- 刷新剩余时间
	local fixedLeftTime = newGameTime * timePercent
	G_BattleLogicMgr:GetBData():SetLeftTime(fixedLeftTime)

	-- 缓存一次差值
	self:SetDeltaTime(0)

	--***---------- 刷新渲染层 ----------***--
	-- 刷新时间标签
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'RefreshTimeLabel',
		fixedLeftTime
	)
	--***---------- 刷新渲染层 ----------***--

	return 0
end
---------------------------------------------------
-- logic end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
修正战斗时间
@params time number 原始时间
@return fixedTime, deltaTime number, number 修正后的时间, 修正掉的时间
--]]
function BattleTimeBuff:CalcFixedGameTime(time)
	local fixedTime = time * (1 + checknumber(self:GetValue()[1]))
	local deltaTime = fixedTime - time
	return fixedTime, deltaTime
end
--[[
缓存一次差值
@params time number 差值
--]]
function BattleTimeBuff:SetDeltaTime(time)
	self.deltaTime = time
end
function BattleTimeBuff:GetDeltaTime()
	return self.deltaTime
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return BattleTimeBuff
