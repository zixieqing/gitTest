--[[
治疗模式结束驱动
--]]
local BattleEndDriver = __Require('battle.battleDriver.BattleEndDriver')
local HealEndDriver = class('HealEndDriver', BattleEndDriver)

---------------------------------------------------
-- init logic begin --
---------------------------------------------------
--[[
@override
初始化逻辑
--]]
function HealEndDriver:Init()
	-- 初始化一次目标数据
	self.targetsInfo = {
		[ConfigCampType.FRIEND] = {targets = {}, targetAmount = 0},
		[ConfigCampType.ENEMY] = {targets = {}, targetAmount = 0},
		[ConfigCampType.NEUTRAL] = {targets = {}, targetAmount = 0}
	}
	self.totalTargetAmount = 0

	local waveInfo = G_BattleLogicMgr:GetBattleMembers(true, self:GetWave())
	
	if nil ~= waveInfo then
		for _, npcInfo in ipairs(waveInfo) do
			local targetId = npcInfo.monsterId
			local configTargetInfo = self.stageCompleteInfo.targetsInfo[tostring(targetId)]
			if nil ~= configTargetInfo then
				-- 是目标物体
				if nil == self.targetsInfo[npcInfo.campType].targets[tostring(targetId)] then
					local targetInfo = {targetId = targetId, targetHpPercent = configTargetInfo.targetHpPercent}
					self.targetsInfo[npcInfo.campType].targets[tostring(targetId)] = targetInfo
				end
				self.targetsInfo[npcInfo.campType].targetAmount = self.targetsInfo[npcInfo.campType].targetAmount + 1
				self.totalTargetAmount = self.totalTargetAmount + 1
			end
		end
	end
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
function HealEndDriver:CanDoLogic()
	local battleMgr = self:GetOwner()
	local bdata = battleMgr:GetBData()

	local result = BattleResult.BR_CONTINUE

	------------ 如果没有配置目标 逻辑死循环 直接失败 ------------
	if 0 >= self:GetTotalTargetAmount() then
		return BattleResult.BR_FAIL
	end
	------------ 如果没有配置目标 逻辑死循环 直接失败 ------------

	if 0 >= bdata.leftTime then
		-- 时间结束视为失败
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
	else

		------------ 检查友方物体 ------------
		local friendMeetCounter = 0
		local objs = nil
		local obj = nil

		-- 特定物体死亡 失败
		objs = G_BattleLogicMgr:GetDeadBattleObjs(false)
		for i = #objs, 1, -1 do
			obj = objs[i]
			local cardId = obj:GetObjectConfigId()
			local targetInfo = self:GetTargetInfoByIdAndCampType(cardId, ConfigCampType.FRIEND)

			if nil ~= targetInfo and self:GetWave() == obj:GetObjectWave() then
				if bdata:CanBuyRevival() then
					-- 可以买活
					return BattleResult.BR_RESCUE
				else
					-- 团灭
					return BattleResult.BR_FAIL
				end
			end
		end

		objs = G_BattleLogicMgr:GetAliveBattleObjs(false)
		for i = #objs, 1, -1 do
			obj = objs[i]
			local cardId = obj:GetObjectConfigId()
			local targetInfo = self:GetTargetInfoByIdAndCampType(cardId, ConfigCampType.FRIEND)

			if nil ~= targetInfo and self:GetWave() == obj:GetObjectWave() then
				-- 是目标物体
				if targetInfo.targetHpPercent > obj:GetMainProperty():GetCurHpPercent() then

				else
					friendMeetCounter = friendMeetCounter + 1
				end
			end
		end
		------------ 检查友方物体 ------------

		------------ 检查敌方物体 ------------
		local enemyMeetCounter = 0

		objs = G_BattleLogicMgr:GetAliveBattleObjs(true)
		for i = #objs, 1, -1 do
			obj = objs[i]
			local cardId = obj:GetObjectConfigId()
			local targetInfo = self:GetTargetInfoByIdAndCampType(cardId, ConfigCampType.ENEMY)

			if nil ~= targetInfo and self:GetWave() == obj:GetObjectWave() then
				-- 是目标物体
				if targetInfo.targetHpPercent > obj:GetMainProperty():GetCurHpPercent() then

				else
					enemyMeetCounter = enemyMeetCounter + 1
				end
			end
		end
		------------ 检查敌方物体 ------------

		------------ 检查休息区物体 ------------
		objs = G_BattleLogicMgr:GetRestObjs()
		for i = #objs, 1, -1 do
			obj = objs[i]
			local cardId = obj:GetObjectConfigId()
			local isEnemy = obj:IsEnemy(true)
			local campType = isEnemy and ConfigCampType.FRIEND or ConfigCampType.ENEMY
			local targetInfo = self:GetTargetInfoByIdAndCampType(cardId, campType)

			if nil ~= targetInfo and self:GetWave() == obj:GetObjectWave() then
				if targetInfo.targetHpPercent > obj:GetMainProperty():GetCurHpPercent() then

				else
					if isEnemy then
						enemyMeetCounter = enemyMeetCounter + 1
					else
						friendMeetCounter = friendMeetCounter + 1
					end
				end
			end
		end
		------------ 检查休息区物体 ------------

		local friendTargetAmount = self:GetTargetAmountByCampType(ConfigCampType.FRIEND)
		local enemyTargetAmount = self:GetTargetAmountByCampType(ConfigCampType.ENEMY)

		if friendTargetAmount > 0 and friendTargetAmount <= friendMeetCounter then
			-- 友方全条件满足
			if bdata:GetNextWave() > bdata:GetStageTotalWave() then
				-- 没有下一波 胜利
				result = BattleResult.BR_SUCCESS
			else
				-- 下一波
				result = BattleResult.BR_NEXT_WAVE
			end
		elseif enemyTargetAmount > 0 and enemyTargetAmount <= enemyMeetCounter then
			-- 敌方全满足 失败
			if bdata:CanBuyRevival() then
				-- 可以买活
				result = BattleResult.BR_RESCUE
			else
				-- 团灭
				result = BattleResult.BR_FAIL
			end
		end

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
根据怪物配表id获取判定条件
@params objConfigId int 物体配表id
--]]
function HealEndDriver:GetTargetInfo(objConfigId)
	return self.stageCompleteInfo.targetsInfo[tostring(objConfigId)]
end
--[[
根据敌友性和id获取目标信息
@params targetId int 目标id
@params campType ConfigCampType 敌友性
@return _ map 目标信息
--]]
function HealEndDriver:GetTargetInfoByIdAndCampType(targetId, campType)
	if nil == campType then
		return self.targetsInfo[ConfigCampType.ENEMY].targets[tostring(targetId)]
	else
		return self.targetsInfo[campType].targets[tostring(targetId)]
	end
end
--[[
根据敌友性获取目标数量
@params campType ConfigCampType 敌友性
@params _ int 目标数量
--]]
function HealEndDriver:GetTargetAmountByCampType(campType)
	if nil == campType then
		return self.targetsInfo[ConfigCampType.ENEMY].targetAmount
	else
		return self.targetsInfo[campType].targetAmount
	end
end
--[[
根据阵营获取所有的目标信息
@params campType ConfigCampType 敌友性
@return _ table 所有的目标信息
--]]
function HealEndDriver:GetTargetsInfoByCampType(campType)
	return self.targetsInfo[campType].targets
end
--[[
获取所有目标个数
@return _ int 所有目标个数
--]]
function HealEndDriver:GetTotalTargetAmount()
	return self.totalTargetAmount
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return HealEndDriver
