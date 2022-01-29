--[[
战斗公式
--]]
BattleExpression = {}

---------------------------------------------------
-- search logic begin --
---------------------------------------------------
--[[
根据敌友性和索敌规则获取索敌的结果
@params isEnemy bool 敌友性
@params seekRule SeekRuleStruct 索敌规则数据
@params o BaseObject 自身
@params infectSkillId int 是否是传染的技能不为空则为传染的技能
@params ruleOutTags map 排除的物体tags
@params triggerData ObjectTriggerParameterStruct 触发信息的传参
@params result table 
--]]
function BattleExpression.GetTargets(isEnemy, seekRule, o, infectSkillId, ruleOutTags, triggerData)
	local result = {}

	local extra = {
		o = nil,
		pos = nil
	}
	if nil ~= o then
		extra.o = o
		extra.pos = o:GetLocation().po
	end

	result = BattleExpression.GetSortedTargets(
		BattleExpression.GetFriendlyTargets(isEnemy, seekRule.ruleType, infectSkillId, o, ruleOutTags, triggerData),
		seekRule.sortType,
		seekRule.maxValue,
		extra
	)

	return result
end
--[[
根据敌我性获取相对的友军和敌军
@params isEnemy bool 原始目标的敌我性
@params ttype int 敌我类型
@params infectSkillId int 是否是传染的技能不为空则为传染的技能
@params o obj 自身
@params ruleOutTags map 排除的物体tags
@params triggerData ObjectTriggerParameterStruct 触发信息的传参
@params result table 
--]]
function BattleExpression.GetFriendlyTargets(isEnemy, ttype, infectSkillId, o, ruleOutTags, triggerData)
	local result = {}
	local ruleOutTags_ = ruleOutTags or {}

	if ConfigSeekTargetRule.T_OBJ_SELF == ttype then
		-- 自身
		assert(o, "obj must not be nil then can get itself")
		table.insert(result, o)
	else

		local objs = nil
		local obj = nil

		if ConfigSeekTargetRule.T_OBJ_ALL == ttype then

			-- 所有单位
			objs = G_BattleLogicMgr:GetAliveBattleObjs(false)
			for i = #objs, 1, -1 do

				obj = objs[i]

				if BattleExpression.CanBeSearchedByCommon(obj, infectSkillId) and true ~= ruleOutTags_[tostring(obj:GetOTag())] then
					table.insert(result, obj)
				end

			end

			objs = G_BattleLogicMgr:GetAliveBattleObjs(true)
			for i = #objs, 1, -1 do

				obj = objs[i]

				if BattleExpression.CanBeSearchedByCommon(obj, infectSkillId) and true ~= ruleOutTags_[tostring(obj:GetOTag())] then
					table.insert(result, obj)
				end
			end

			return result

		elseif ConfigSeekTargetRule.T_OBJ_ENEMY == ttype or ConfigSeekTargetRule.T_OBJ_FRIEND == ttype then

			-- 敌方或友方普通规则 这里的配表敌友性总是相对的
			if isEnemy then
				ttype = ConfigSeekTargetRule.T_OBJ_ENEMY + ConfigSeekTargetRule.T_OBJ_FRIEND - ttype
			end

			if ConfigSeekTargetRule.T_OBJ_ENEMY == ttype then

				objs = G_BattleLogicMgr:GetAliveBattleObjs(true)
				for i = #objs, 1, -1 do

					obj = objs[i]

					if BattleExpression.CanBeSearchedByCommon(obj, infectSkillId) and true ~= ruleOutTags_[tostring(obj:GetOTag())] then
						table.insert(result, obj)
					end

				end

			elseif ConfigSeekTargetRule.T_OBJ_FRIEND == ttype then

				objs = G_BattleLogicMgr:GetAliveBattleObjs(false)
				for i = #objs, 1, -1 do

					obj = objs[i]

					if BattleExpression.CanBeSearchedByCommon(obj, infectSkillId) and true ~= ruleOutTags_[tostring(obj:GetOTag())] then
						table.insert(result, obj)
					end

				end

			end

		elseif ConfigSeekTargetRule.T_OBJ_FRIEND_TANK <= ttype and ConfigSeekTargetRule.T_OBJ_FRIEND_HEALER >= ttype then

			local configCareer = ttype - ConfigSeekTargetRule.T_OBJ_FRIEND_TANK + 1

			if isEnemy then

				objs = G_BattleLogicMgr:GetAliveBattleObjs(true)
				for i = #objs, 1, -1 do

					obj = objs[i]

					if configCareer == obj:GetOCareer() then
						if BattleExpression.CanBeSearchedByCommon(obj, infectSkillId) and true ~= ruleOutTags_[tostring(obj:GetOTag())] then
							table.insert(result, obj)
						end
					end

				end

			else

				objs = G_BattleLogicMgr:GetAliveBattleObjs(false)
				for i = #objs, 1, -1 do

					obj = objs[i]

					if configCareer == obj:GetOCareer() then
						if BattleExpression.CanBeSearchedByCommon(obj, infectSkillId) and true ~= ruleOutTags_[tostring(obj:GetOTag())] then
							table.insert(result, obj)
						end
					end

				end

			end

		elseif ConfigSeekTargetRule.T_OBJ_ENEMY_TANK <= ttype and ConfigSeekTargetRule.T_OBJ_ENEMY_HEALER >= ttype then

			local configCareer = ttype - ConfigSeekTargetRule.T_OBJ_ENEMY_TANK + 1

			if isEnemy then

				objs = G_BattleLogicMgr:GetAliveBattleObjs(false)
				for i = #objs, 1, -1 do

					obj = objs[i]

					if configCareer == obj:GetOCareer() then
						if BattleExpression.CanBeSearchedByCommon(obj, infectSkillId) and true ~= ruleOutTags_[tostring(obj:GetOTag())] then
							table.insert(result, obj)
						end
					end

				end

			else

				objs = G_BattleLogicMgr:GetAliveBattleObjs(true)
				for i = #objs, 1, -1 do

					obj = objs[i]

					if configCareer == obj:GetOCareer() then
						if BattleExpression.CanBeSearchedByCommon(obj, infectSkillId) and true ~= ruleOutTags_[tostring(obj:GetOTag())] then
							table.insert(result, obj)
						end
					end
				
				end
			end

		elseif ConfigSeekTargetRule.T_OBJ_FRIEND_PLAYER == ttype or ConfigSeekTargetRule.T_OBJ_ENEMY_PLAYER == ttype then

			objs = G_BattleLogicMgr:GetOtherLogicObjs()
			for i = #objs, 1, -1 do

				obj = objs[i]

				if BattleElementType.BET_PLAYER == obj:GetOBattleElementType() then
					if isEnemy == obj:IsEnemy(true) and BattleExpression.CanBeSearchedByCommon(obj) and true ~= ruleOutTags_[tostring(obj:GetOTag())] then
						table.insert(result, obj)
					end
				end

			end

		elseif ConfigSeekTargetRule.T_OBJ_ATTACKER == ttype then

			-- 当前攻击者 平a对象为发起本次索敌物体的单位
			if nil ~= o then
				local otag = o:GetOTag()

				objs = G_BattleLogicMgr:GetAliveBattleObjs(not isEnemy)

				for i = #objs, 1, -1 do

					obj = objs[i]

					if obj.attackDriver:GetAttackTargetTag() and otag == obj.attackDriver:GetAttackTargetTag() and true ~= ruleOutTags_[tostring(obj:GetOTag())] then
						table.insert(result, obj)
					end

				end
			end

		elseif ConfigSeekTargetRule.T_OBJ_ATTACK_TARGET == ttype then

			-- 当前攻击对象
			if nil ~= o then
				if o:IsEnemy() == o:IsEnemy(true) then
					-- 魅惑状态的单位直接跳过
					if o.attackDriver then
						local attackTargetTag = o.attackDriver:GetAttackTargetTag()
						if nil ~= attackTargetTag then
							obj = G_BattleLogicMgr:IsObjAliveByTag(attackTargetTag)
							if nil ~= obj and true ~= ruleOutTags_[tostring(obj:GetOTag())] then
								table.insert(result, obj)
							end
						end
					end
				end
			end

		elseif ConfigSeekTargetRule.T_OBJ_TRIGGER_ATTACKER == ttype then

			-- 触发本次索敌的攻击者单位
			if nil ~= o and nil ~= triggerData and nil ~= triggerData.attackerTag then

				objs = G_BattleLogicMgr:GetAliveBattleObjs(not isEnemy)

				for i = #objs, 1, -1 do
					obj = objs[i]
					if triggerData.attackerTag == obj:GetOTag() and true ~= ruleOutTags_[tostring(obj:GetOTag())] then
						table.insert(result, obj)
					end
				end

			end

		end
		
	end
	return result
end
--[[
根据敌我性获取相对已经死亡的友军和敌军
@params isEnemy bool 原始目标的敌我性
@params ttype int 敌我类型
@params o obj 自身
@params needSameTeam bool 是否在同一队
@params ruleOutTags map 排除的物体tags
@params result table
--]]
function BattleExpression.GetDeadFriendlyTargets(isEnemy, ttype, o, needSameTeam, ruleOutTags)
	local result = {}
	local ruleOutTags_ = ruleOutTags or {}

	if ConfigSeekTargetRule.T_OBJ_SELF == ttype then
		-- 自身
		return {}
	else

		local oTeamIndex = o and o:GetObjectTeamIndex() or 0
		local objs = nil
		local obj = nil

		if ConfigSeekTargetRule.T_OBJ_ALL == ttype then

			-- 所有单位
			objs = G_BattleLogicMgr:GetDeadBattleObjs(false)
			for i = #objs, 1, -1 do

				obj = objs[i]
				if obj:CanBeSearched() and (not needSameTeam or oTeamIndex == obj:GetObjectTeamIndex()) and true ~= ruleOutTags_[tostring(obj:GetOTag())] then
					table.insert(result, obj)
				end

			end

			objs = G_BattleLogicMgr:GetDeadBattleObjs(true)
			for i = #objs, 1, -1 do

				obj = objs[i]
				if obj:CanBeSearched() and (not needSameTeam or oTeamIndex == obj:GetObjectTeamIndex()) and true ~= ruleOutTags_[tostring(obj:GetOTag())] then
					table.insert(result, obj)
				end

			end

			return result

		else

			-- 敌方或友方 这里的配表敌友性总是相对的
			if isEnemy then
				ttype = ConfigSeekTargetRule.T_OBJ_ENEMY + ConfigSeekTargetRule.T_OBJ_FRIEND - ttype
			end

			if ConfigSeekTargetRule.T_OBJ_ENEMY == ttype then

				objs = G_BattleLogicMgr:GetDeadBattleObjs(true)
				for i = #objs, 1, -1 do

					obj = objs[i]
					if obj:CanBeSearched() and (not needSameTeam or oTeamIndex == obj:GetObjectTeamIndex()) and true ~= ruleOutTags_[tostring(obj:GetOTag())] then
						table.insert(result, obj)
					end

				end

			elseif ConfigSeekTargetRule.T_OBJ_FRIEND == ttype then

				objs = G_BattleLogicMgr:GetDeadBattleObjs(false)
				for i = #objs, 1, -1 do

					obj = objs[i]
					if obj:CanBeSearched() and (not needSameTeam or oTeamIndex == obj:GetObjectTeamIndex()) and true ~= ruleOutTags_[tostring(obj:GetOTag())] then
						table.insert(result, obj)
					end

				end

			end

		end
		
	end
	return result
end
--[[
获取主角技的索敌对象 主角技
@params isEnemy bool 原始目标的敌我性
@params ttype int 敌我类型
@params infectSkillId int 是否是传染的技能不为空则为传染的技能
@params o obj 自身
@params ruleOutTags map 排除的物体tags
@params result table 
--]]
function BattleExpression.GetFriendlyTargetsForPlayerSkill(isEnemy, ttype, infectSkillId, o, ruleOutTags)
	local result = {}
	local ruleOutTags_ = ruleOutTags or {}

	if ConfigSeekTargetRule.T_OBJ_SELF == ttype then
		-- 自身
		assert(o, "obj must not be nil then can get itself")
		table.insert(result, o)
	else
		local objs = nil
		local obj = nil

		if ConfigSeekTargetRule.T_OBJ_ALL == ttype then

			-- 所有单位
			objs = G_BattleLogicMgr:GetAliveBattleObjs(false)
			for i = #objs, 1, -1 do

				obj = objs[i]

				-- 排除木桩
				if BattleExpression.CanBeSearchedByPlayer(obj, infectSkillId) and true ~= ruleOutTags_[tostring(obj:GetOTag())] then
					table.insert(result, obj)
				end

			end

			objs = G_BattleLogicMgr:GetAliveBattleObjs(true)
			for i = #objs, 1, -1 do

				obj = objs[i]

				-- 排除木桩
				if BattleExpression.CanBeSearchedByPlayer(obj, infectSkillId) and true ~= ruleOutTags_[tostring(obj:GetOTag())] then
					table.insert(result, obj)
				end

			end

			return result

		elseif ConfigSeekTargetRule.T_OBJ_ENEMY == ttype or ConfigSeekTargetRule.T_OBJ_FRIEND == ttype then

			-- 敌方或友方普通规则 这里的配表敌友性总是相对的
			if isEnemy then
				ttype = ConfigSeekTargetRule.T_OBJ_ENEMY + ConfigSeekTargetRule.T_OBJ_FRIEND - ttype
			end

			if ConfigSeekTargetRule.T_OBJ_ENEMY == ttype then

				objs = G_BattleLogicMgr:GetAliveBattleObjs(true)
				for i = #objs, 1, -1 do

					obj = objs[i]

					-- 排除木桩
					if BattleExpression.CanBeSearchedByPlayer(obj, infectSkillId) and true ~= ruleOutTags_[tostring(obj:GetOTag())] then
						table.insert(result, obj)
					end

				end

			elseif ConfigSeekTargetRule.T_OBJ_FRIEND == ttype then

				objs = G_BattleLogicMgr:GetAliveBattleObjs(false)
				for i = #objs, 1, -1 do

					obj = objs[i]

					-- 排除木桩
					if BattleExpression.CanBeSearchedByPlayer(obj, infectSkillId) and true ~= ruleOutTags_[tostring(obj:GetOTag())] then
						table.insert(result, obj)
					end
				end

			end

		elseif ConfigSeekTargetRule.T_OBJ_FRIEND_TANK <= ttype and ConfigSeekTargetRule.T_OBJ_FRIEND_HEALER >= ttype then

			local configCareer = ttype - ConfigSeekTargetRule.T_OBJ_FRIEND_TANK + 1

			if isEnemy then

				objs = G_BattleLogicMgr:GetAliveBattleObjs(true)
				for i = #objs, 1, -1 do

					obj = objs[i]

					-- 排除木桩
					if configCareer == obj:GetOCareer() then
						if BattleExpression.CanBeSearchedByPlayer(obj, infectSkillId) and true ~= ruleOutTags_[tostring(obj:GetOTag())] then
							table.insert(result, obj)
						end
					end

				end

			else

				objs = G_BattleLogicMgr:GetAliveBattleObjs(false)
				for i = #objs, 1, -1 do

					obj = objs[i]

					-- 排除木桩
					if configCareer == obj:GetOCareer() then
						if BattleExpression.CanBeSearchedByPlayer(obj, infectSkillId) and true ~= ruleOutTags_[tostring(obj:GetOTag())] then
							table.insert(result, obj)
						end
					end

				end

			end

		elseif ConfigSeekTargetRule.T_OBJ_ENEMY_TANK <= ttype and ConfigSeekTargetRule.T_OBJ_ENEMY_HEALER >= ttype then

			local configCareer = ttype - ConfigSeekTargetRule.T_OBJ_ENEMY_TANK + 1

			if isEnemy then

				objs = G_BattleLogicMgr:GetAliveBattleObjs(false)
				for i = #objs, 1, -1 do

					obj = objs[i]

					-- 排除木桩
					if configCareer == obj:GetOCareer() then
						if BattleExpression.CanBeSearchedByPlayer(obj, infectSkillId) and true ~= ruleOutTags_[tostring(obj:GetOTag())] then
							table.insert(result, obj)
						end
					end

				end
			else
				
				objs = G_BattleLogicMgr:GetAliveBattleObjs(true)
				for i = #objs, 1, -1 do

					obj = objs[i]

					-- 排除木桩
					if configCareer == obj:GetOCareer() then
						if BattleExpression.CanBeSearchedByPlayer(obj, infectSkillId) and true ~= ruleOutTags_[tostring(obj:GetOTag())] then
							table.insert(result, obj)
						end
					end
					
				end

			end

		elseif ConfigSeekTargetRule.T_OBJ_FRIEND_PLAYER == ttype or ConfigSeekTargetRule.T_OBJ_ENEMY_PLAYER == ttype then

			objs = G_BattleLogicMgr:GetOtherLogicObjs()
			for i = #objs, 1, -1 do

				obj = objs[i]

				if BattleElementType.BET_PLAYER == obj:GetOBattleElementType() then
					if isEnemy == obj:IsEnemy(true) and BattleExpression.CanBeSearchedByPlayer(obj) and true ~= ruleOutTags_[tostring(obj:GetOTag())] then
						table.insert(result, obj)
					end
				end

			end

		end
	end
	
	return result	
end
--[[
根据敌我性获取相对已经死亡的友军和敌军 主角技
@params isEnemy bool 原始目标的敌我性
@params ttype int 敌我类型
@params o obj 自身
@params needSameTeam bool 是否在同一队
@params ruleOutTags map 排除的物体tags
@params result table
--]]
function BattleExpression.GetDeadFriendlyTargetsForPlayerSkill(isEnemy, ttype, o, needSameTeam, ruleOutTags)
	local result = {}
	local ruleOutTags_ = ruleOutTags or {}
	
	if ConfigSeekTargetRule.T_OBJ_SELF == ttype then
		-- 自身
		return {}
	else

		local objs = nil
		local obj = nil

		if ConfigSeekTargetRule.T_OBJ_ALL == ttype then

			-- 所有单位
			objs = G_BattleLogicMgr:GetDeadBattleObjs(false)
			for i = #objs, 1, -1 do

				obj = objs[i]

				-- 排除木桩
				if BattleExpression.CanBeSearchedByPlayer(obj) and true ~= ruleOutTags_[tostring(obj:GetOTag())] then
					table.insert(result, obj)
				end

			end

			objs = G_BattleLogicMgr:GetDeadBattleObjs(true)
			for i = #objs, 1, -1 do

				obj = objs[i]

				-- 排除木桩
				if BattleExpression.CanBeSearchedByPlayer(obj) and true ~= ruleOutTags_[tostring(obj:GetOTag())] then
					table.insert(result, obj)
				end

			end

			return result

		else

			-- 敌方或友方 这里的配表敌友性总是相对的
			if isEnemy then
				ttype = ConfigSeekTargetRule.T_OBJ_ENEMY + ConfigSeekTargetRule.T_OBJ_FRIEND - ttype
			end

			if ConfigSeekTargetRule.T_OBJ_ENEMY == ttype then

				objs = G_BattleLogicMgr:GetDeadBattleObjs(true)
				for i = #objs, 1, -1 do

					obj = objs[i]

					-- 排除木桩
					if BattleExpression.CanBeSearchedByPlayer(obj) and true ~= ruleOutTags_[tostring(obj:GetOTag())] then
						table.insert(result, obj)
					end

				end

			elseif ConfigSeekTargetRule.T_OBJ_FRIEND == ttype then

				objs = G_BattleLogicMgr:GetDeadBattleObjs(false)
				for i = #objs, 1, -1 do

					obj = objs[i]

					-- 排除木桩
					if BattleExpression.CanBeSearchedByPlayer(obj) and true ~= ruleOutTags_[tostring(obj:GetOTag())] then
						table.insert(result, obj)
					end

				end

			end

		end
		
	end
	return result
end
--[[
根据条件筛选符合条件的obj
@params targets table(obj) 备选对象集
@params stype int 排序类型
@params max int 最大目标数
@params extra table 附加参数{
	pos cc.p 施法者坐标
	o obj 施法者自身
}
@return result table 结果对象tag集
--]]
function BattleExpression.GetSortedTargets(targets, stype, max, extra)
	extra = extra or {}
	local result = {}
	if #targets <= max then
		-- 如果备选对象数小于最大目标数 快速返回 不做排序
		result = targets
		return result
	end	
	local tmpResult = {} -- 中间值 有序集合只保存对象tag
	-- 索敌规则 排序
	if SeekSortRule.S_NONE == stype then
		-- 随机排序
		tmpResult = BattleExpression.SortTByRandom(targets)
	elseif SeekSortRule.S_DISTANCE_MIN == stype then
		-- 距离最近的目标
		tmpResult = BattleExpression.SortTByDistanceMin(targets, extra.pos)
	elseif SeekSortRule.S_DISTANCE_MAX == stype then
		-- 距离最远的目标
		tmpResult = BattleExpression.SortTByDistanceMax(targets, extra.pos)
	elseif SeekSortRule.S_HP_PERCENT_MAX == stype then
		-- 当前生命值百分比最高的目标
		tmpResult = BattleExpression.SortTByHpPercentMax(targets)
	elseif SeekSortRule.S_HP_PERCENT_MIN == stype then
		-- 当前生命值百分比最低的目标
		tmpResult = BattleExpression.SortTByHpPercentMin(targets)
	elseif SeekSortRule.S_ATTACK_MAX == stype then
		-- 当前攻击力最高的目标
		tmpResult = BattleExpression.SortTByPropMax(targets, ObjP.ATTACK)
	elseif SeekSortRule.S_ATTACK_MIN == stype then
		-- 当前攻击力最低的目标
		tmpResult = BattleExpression.SortTByPropMin(targets, ObjP.ATTACK)
	elseif SeekSortRule.S_DEFENCE_MAX == stype then
		-- 当前防御力最高的目标
		tmpResult = BattleExpression.SortTByPropMax(targets, ObjP.DEFENCE)
	elseif SeekSortRule.S_DEFENCE_MIN == stype then
		-- 当前防御力最低的目标
		tmpResult = BattleExpression.SortTByPropMin(targets, ObjP.DEFENCE)
	elseif SeekSortRule.S_CHP_MAX == stype then
		-- 当前生命值最高的目标
		tmpResult = BattleExpression.SortTByPropMax(targets, ObjP.HP)
	elseif SeekSortRule.S_CHP_MIN == stype then
		-- 当前生命值最低的目标
		tmpResult = BattleExpression.SortTByPropMin(targets, ObjP.HP)
	elseif SeekSortRule.S_OHP_MAX == stype then
		-- 生命总值最高的目标
		tmpResult = BattleExpression.SortTByOPropMax(targets, ObjP.HP)
	elseif SeekSortRule.S_OHP_MIN == stype then
		-- 生命总值最低的目标
		tmpResult = BattleExpression.SortTByOPropMin(targets, ObjP.HP)
	elseif SeekSortRule.S_BATTLE_POINT_MAX == stype then
		-- TODO 战斗力最高的目标-- 
		tmpResult = BattleExpression.SortTByOPropMax(targets, ObjP.HP)
	elseif SeekSortRule.S_BATTLE_POINT_MIN == stype then
		-- TODO 战斗力最低的目标-- 
		tmpResult = BattleExpression.SortTByOPropMax(targets, ObjP.HP)
	elseif SeekSortRule.S_ATTACK_RATE_MAX == stype then
		-- 当前攻击速度最高的目标
		tmpResult = BattleExpression.SortTByPropMax(targets, ObjP.ATTACKRATE)
	elseif SeekSortRule.S_ATTACK_RATE_MIN == stype then
		-- 当前攻击速度最低的目标
		tmpResult = BattleExpression.SortTByPropMin(targets, ObjP.ATTACKRATE)
	elseif SeekSortRule.S_HATE_MAX == stype then
		-- 当前仇恨值最高的目标
		tmpResult = BattleExpression.SortTByHateMax(targets)
	elseif SeekSortRule.S_HATE_MIN == stype then
		-- 当前仇恨值最低的目标
		tmpResult = BattleExpression.SortTByHateMin(targets)
	elseif SeekSortRule.S_FOR_HEAL == stype then
		-- 治疗的目标
		tmpResult = BattleExpression.SortForHealAttack(targets)
	end
	local itor = math.min(max, #tmpResult)
	local oriTarget = nil
	for i, target in ipairs(tmpResult) do
		if 0 == itor then
			break
		else
			if SeekSortRule.S_FOR_HEAL ~= stype and extra.o and extra.o:GetOTag() == target:GetOTag() then
				-- 将自己置为最后
				oriTarget = target
			else
				itor = itor - 1
				table.insert(result, target)
			end
		end
	end
	if oriTarget and itor > 0 then
		-- 将自己置为最后
		table.insert(result, oriTarget)
	end
	return result
end
--[[
随机索敌
@params targets table(obj) 备选对象
--]]
function BattleExpression.SortTByRandom(targets)
	local result = {}
	local amount = #targets
	local randomMark = G_BattleLogicMgr:GetRandomManager():GetRandomInt(amount) - 1
	local index = 0
	for i = 1, amount do
		index = randomMark + i
		if index > amount then
			index = index - amount
		end
		table.insert(result, targets[index])
	end
	return result
end
--[[
当前仇恨值最高的目标 仇恨值相同时按照编队位置排序 怪物按照配表顺序排序
@params targets table(obj) 备选对象
@return result table(obj) 排序后结果
--]]
function BattleExpression.SortTByHateMax(targets)
	table.sort(targets, function (a, b)
		local hateA = a:GetHate()
		local hateB = b:GetHate()
		if hateA > hateB then
			return true
		elseif hateA == hateB then
			return a:GetTeamPosition() < b:GetTeamPosition()
		else
			return false
		end
	end)
	return targets
end
--[[
当前仇恨值最低的目标 仇恨值相同时按照编队位置排序 怪物按照配表顺序排序
@params targets table(obj) 备选对象
@return result table(obj) 排序后结果
--]]
function BattleExpression.SortTByHateMin(targets)
	table.sort(targets, function (a, b)
		local hateA = a:GetHate()
		local hateB = b:GetHate()
		if hateA < hateB then
			return true
		elseif hateA == hateB then
			return a:GetTeamPosition() > b:GetTeamPosition()
		else
			return false
		end
	end)
	return targets
end
--[[
最近的目标
@params targets table(obj) 备选对象
@params pos cc.p 对比的坐标
@return result table(obj) 排序后结果
--]]
function BattleExpression.SortTByDistanceMin(targets, pos)
	table.sort(targets, function (a, b)
		local posA = a:GetLocation().po
		local posB = b:GetLocation().po
		local d = (posA.x - pos.x) * (posA.x - pos.x) + (posA.y - pos.y) * (posA.y - pos.y)
		local d_ = (posB.x - pos.x) * (posB.x - pos.x) + (posB.y - pos.y) * (posB.y - pos.y)
		return d < d_
	end)
	return targets
end
--[[
最远的目标
@params targets table(obj) 备选对象
@params pos cc.p 对比的坐标
@return result table(obj) 排序后结果
--]]
function BattleExpression.SortTByDistanceMax(targets, pos)
	table.sort(targets, function (a, b)
		local posA = a:GetLocation().po
		local posB = b:GetLocation().po
		local d = (posA.x - pos.x) * (posA.x - pos.x) + (posA.y - pos.y) * (posA.y - pos.y)
		local d_ = (posB.x - pos.x) * (posB.x - pos.x) + (posB.y - pos.y) * (posB.y - pos.y)
		return d > d_
	end)
	return targets
end
--[[
生命百分比最高的目标
@params targets table(obj) 备选对象
@return result table(obj) 排序后结果
--]]
function BattleExpression.SortTByHpPercentMax(targets)
	table.sort(targets, function (a, b)
		local d = a:GetMainProperty():GetCurHpPercent()
		local d_ = b:GetMainProperty():GetCurHpPercent()
		return d > d_
	end)
	return targets
end
--[[
生命百分比最低的目标
@params targets table(obj) 备选对象
@return result table(obj) 排序后结果
--]]
function BattleExpression.SortTByHpPercentMin(targets)
	table.sort(targets, function (a, b)
		local d = a:GetMainProperty():GetCurHpPercent()
		local d_ = b:GetMainProperty():GetCurHpPercent()
		return d < d_
	end)
	return targets
end
--[[
当前指定属性最高的目标
@params targets table(obj) 备选对象
@params prop ObjP 物体属性
@return result table(obj) 排序后结果
--]]
function BattleExpression.SortTByPropMax(targets, prop)
	table.sort(targets, function (a, b)
		local d = a:GetMainProperty():Getp(prop)
		local d_ = b:GetMainProperty():Getp(prop)
		if d == d_ then
			return a:GetTeamPosition() > b:GetTeamPosition()
		end
		return d > d_
	end)
	return targets
end
--[[
当前指定属性最低的目标
@params targets table(obj) 备选对象
@params prop ObjP 物体属性
@return result table(obj) 排序后结果
--]]
function BattleExpression.SortTByPropMin(targets, prop)
	table.sort(targets, function (a, b)
		local d = a:GetMainProperty():Getp(prop)
		local d_ = b:GetMainProperty():Getp(prop)
		if d == d_ then
			return a:GetTeamPosition() < b:GetTeamPosition()
		end
		return d < d_
	end)
	return targets
end
--[[
当前原始属性最高的目标
@params targets table(obj) 备选对象
@params prop ObjP 物体属性
@return result table(obj) 排序后结果
--]]
function BattleExpression.SortTByOPropMax(targets, prop)
	table.sort(targets, function (a, b)
		local d = a:GetMainProperty():Getp(prop, true)
		local d_ = b:GetMainProperty():Getp(prop, true)
		if d == d_ then
			return a:GetTeamPosition() > b:GetTeamPosition()
		end
		return d > d_
	end)
	return targets
end
--[[
当前原始属性最低的目标
@params targets table(obj) 备选对象
@params prop ObjP 物体属性
@return result table(obj) 排序后结果
--]]
function BattleExpression.SortTByOPropMin(targets, prop)
	table.sort(targets, function (a, b)
		local d = a:GetMainProperty():Getp(prop, true)
		local d_ = b:GetMainProperty():Getp(prop, true)
		if d == d_ then
			return a:GetTeamPosition() < b:GetTeamPosition()
		end
		return d < d_
	end)
	return targets
end
--[[
治疗的索敌规则 1 生命值最低的对象 2 仇恨值最高的对象
@params targets table(obj) 备选对象
--]]
function BattleExpression.SortForHealAttack(targets)
	table.sort(targets, function (a, b)
		local d = a:GetMainProperty():GetCurHpPercent()
		local d_ = b:GetMainProperty():GetCurHpPercent()
		if d == d_ then
			local hateA = a:GetHate()
			local hateB = b:GetHate()
			if hateA == hateB then
				return a:GetTeamPosition() < b:GetTeamPosition()
			else
				return hateA > hateB
			end
		else
			return d < d_
		end
	end)
	return targets
end
---------------------------------------------------
-- search logic end --
---------------------------------------------------

---------------------------------------------------
-- search get begin --
---------------------------------------------------
--[[
通用规则 是否可以被索敌
@params obj BaseLogicModel
@params infectSkillId int 传染的技能id
@return _ bool
--]]
function BattleExpression.CanBeSearchedByCommon(obj, infectSkillId)
	if obj:CanBeSearched() and false == obj:IsInfectBySkillId(infectSkillId) then
		return true
	else
		return false
	end
end
--[[
通用规则 是否可以被主角技索敌
@params obj BaseLogicModel
@params infectSkillId int 传染的技能id
@return _ bool
--]]
function BattleExpression.CanBeSearchedByPlayer(obj, infectSkillId)
	if obj:CanBeSearched() and not obj:IsScarecrow() and false == obj:IsInfectBySkillId(infectSkillId) then
		return true
	else
		return false
	end
end
---------------------------------------------------
-- search get end --
---------------------------------------------------

---------------------------------------------------
-- trigger condition begin --
---------------------------------------------------
--[[
根据对象集合和触发条件判断是否满足触发条件
@params triggerConditionInfo BuffTriggerConditionStruct buff触发条件
@return result bool 是否满足触发条件
--]]
function BattleExpression.MeetTriggerCondition(triggerConditionInfo, targets)
	local result = nil
	local targetBreak = nil
	local meet = nil

	if ConfigMeetConditionType.ONE == triggerConditionInfo.meetType then

		result = false
		targetBreak = true

	elseif ConfigMeetConditionType.ALL == triggerConditionInfo.meetType then

		result = true
		targetBreak = false

	end

	for _, object in ipairs(targets) do
		meet = BattleExpression.MeetTriggerConditionSingleObject(triggerConditionInfo, object)
		if targetBreak == meet then
			result = meet
			break
		end
	end

	return result
end
--[[
判断单个物体是否满足触发条件
@params triggerConditionInfo BuffTriggerConditionStruct buff触发条件
@params object BaseObject
@return _ bool 是否满足触发条件
--]]
function BattleExpression.MeetTriggerConditionSingleObject(triggerConditionInfo, object)
	if ConfigObjectTriggerConditionType.HP_MORE_THAN == triggerConditionInfo.objTriggerConditionType then

		-- 当前血量百分比大于等于目标值
		return checknumber(triggerConditionInfo.value[1]) <= object:GetMainProperty():GetCurHpPercent()

	elseif ConfigObjectTriggerConditionType.HP_LESS_THAN == triggerConditionInfo.objTriggerConditionType then

		-- 当前血量百分比小于等于目标值
		return checknumber(triggerConditionInfo.value[1]) >= object:GetMainProperty():GetCurHpPercent()

	elseif ConfigObjectTriggerConditionType.HAS_BUFF == triggerConditionInfo.objTriggerConditionType then

		-- 物体拥有某种类型的buff
		local has = true
		for _, buffType in ipairs(triggerConditionInfo.value) do
			local has = obj:HasBuffByBuffType(checkint(buffType), false)
			if not has then
				has = false
				break
			end
		end
		return has

	end
end
---------------------------------------------------
-- trigger condition end --
---------------------------------------------------
