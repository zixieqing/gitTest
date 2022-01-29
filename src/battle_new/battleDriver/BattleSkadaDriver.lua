--[[
伤害统计插件
--]]
local BaseBattleDriver = __Require('battle.battleDriver.BaseBattleDriver')
local BattleSkadaDriver = class('BattleSkadaDriver', BaseBattleDriver)

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

--[[
constructor
--]]
function BattleSkadaDriver:ctor( ... )
	BaseBattleDriver.ctor(self, ...)
	self.driverType = BattleDriverType.SKADA_DRIVER

	local args = unpack({...})

	self:Init()
end


---------------------------------------------------
-- init logic begin --
---------------------------------------------------
--[[
@override
初始化逻辑
--]]
function BattleSkadaDriver:Init()
	-- 伤害统计
	self.skada = {
		[SkadaType.DAMAGE] 			= {}, -- 造成伤害
		[SkadaType.HEAl] 			= {}, -- 治疗
		[SkadaType.GOT_DAMAGE] 		= {}  -- 受到伤害
	}

	-- 实时的总值
	self.friendSkadaRealTime = {}
	self.enemySkadaRealTime  = {}

	-- 物体tag映射关系
	self.friendObjectTag       = {}
	self.friendObjectTagInvert = {}
	self.enemyObjectTag        = {}
	self.enemyObjectTagInvert  = {}
end
---------------------------------------------------
-- init logic end --
---------------------------------------------------

---------------------------------------------------
-- control logic begin --
---------------------------------------------------
--[[
@override
逻辑开始
@params skadaType SkadaType 伤害统计类型
@params objectTag int 物体tag
@params damageData ObjectDamageStruct 伤害数据
@params trueDamage number 修正的有效伤害数值
--]]
function BattleSkadaDriver:OnLogicEnter(skadaType, objectTag, damageData, trueDamage)
	if nil == self.skada[skadaType][objectTag] then
		self.skada[skadaType][objectTag] = {}
	end

	local damage = trueDamage or damageData:GetDamageValue()
	table.insert(self.skada[skadaType][objectTag], damage)

	self:Add2RealTimeSkada(skadaType, objectTag, trueDamage)
end
--[[
加入总值
@params skadaType SkadaType 伤害统计类型
@params objectTag int 物体tag
@params trueDamage number 修正的有效伤害数值
--]]
function BattleSkadaDriver:Add2RealTimeSkada(skadaType, objectTag, trueDamage)
	local teamInfo      = self:GetTeamInfoByObjectTag(objectTag)
	local isEnemy       = self.friendObjectTagInvert[objectTag] == nil
	local skadaRealTime = (isEnemy == true) and self.enemySkadaRealTime or self.friendSkadaRealTime
	if nil ~= teamInfo then

		local teamIndex = teamInfo.teamIndex
		if nil == skadaRealTime[teamIndex] then
			skadaRealTime[teamIndex] = {
				[SkadaType.DAMAGE] 			= {sum = 0, memberSkada = {}},
				[SkadaType.HEAl] 			= {sum = 0, memberSkada = {}},
				[SkadaType.GOT_DAMAGE] 		= {sum = 0, memberSkada = {}}
			}
		end

		-- 全队总值累加
		skadaRealTime[teamIndex][skadaType].sum = skadaRealTime[teamIndex][skadaType].sum + trueDamage

		-- 个人总值累加
		if nil == skadaRealTime[teamIndex][skadaType].memberSkada[objectTag] then
			skadaRealTime[teamIndex][skadaType].memberSkada[objectTag] = {sum = 0}
		end
		skadaRealTime[teamIndex][skadaType].memberSkada[objectTag].sum = skadaRealTime[teamIndex][skadaType].memberSkada[objectTag].sum + trueDamage
	end
end
--[[
记录物体tag的映射关系
@params teamIndex int 队伍序号
@params memberIndex int 在队伍中的序号
@params objectTag int 对应的物体tag
@params isEnemy bool 是否为敌人
--]]
function BattleSkadaDriver:SkadaAddObjectTag(teamIndex, memberIndex, objectTag, isEnemy)
	local curObjectTag       = (isEnemy == true) and self.enemyObjectTag or self.friendObjectTag
	local curObjectTagInvert = (isEnemy == true) and self.enemyObjectTagInvert or self.friendObjectTagInvert
	
	if nil == curObjectTag[teamIndex] then
		curObjectTag[teamIndex] = {}
	end
	curObjectTag[teamIndex][memberIndex] = objectTag

	if nil == curObjectTagInvert[objectTag] then
		curObjectTagInvert[objectTag] = {teamIndex = teamIndex, memberIndex = memberIndex}
	end
end
---------------------------------------------------
-- control logic end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
获取伤害统计数据
--]]
function BattleSkadaDriver:GetSkadaData()
	return self.skada
end
function BattleSkadaDriver:GetFriendSkadaData()
	return self.friendSkadaRealTime
end
function BattleSkadaDriver:GetEnemySkadaData()
	return self.enemySkadaRealTime
end
--[[
获取物体tag映射
--]]
function BattleSkadaDriver:GetFriendTagInfo()
	return self.friendObjectTag
end
function BattleSkadaDriver:GetEnemyTagInfo()
	return self.enemyObjectTag
end
--[[
根据object tag获取队伍信息
--]]
function BattleSkadaDriver:GetTeamInfoByObjectTag(tag)
	return self.friendObjectTagInvert[tag] or self.enemyObjectTagInvert[tag]
end
--[[
获取传给服务器的伤害统计数值
@params isEnemy bool 是否为敌人
@return skada2server map {
	[SkadaType.DAMAGE] = 0,
	[SkadaType.HEAl] = 0,
	[SkadaType.GOT_DAMAGE] = 0
}
--]]
function BattleSkadaDriver:GetSkada2Server(isEnemy)
	local skadaRealTime = (isEnemy == true) and self.enemySkadaRealTime or self.friendSkadaRealTime
	local skada2server = {
		[SkadaType.DAMAGE]     = 0,
		[SkadaType.HEAl]       = 0,
		[SkadaType.GOT_DAMAGE] = 0
	}

	for teamIndex, skadaData in pairs(skadaRealTime) do
		skada2server[SkadaType.DAMAGE]     = skadaData[SkadaType.DAMAGE].sum
		skada2server[SkadaType.HEAl]       = skadaData[SkadaType.HEAl].sum
		skada2server[SkadaType.GOT_DAMAGE] = skadaData[SkadaType.GOT_DAMAGE].sum
	end

	-- 取精度 两位小数
	skada2server[SkadaType.DAMAGE]     = math.round(skada2server[SkadaType.DAMAGE]     * 100) * 0.01
	skada2server[SkadaType.HEAl]       = math.round(skada2server[SkadaType.HEAl]       * 100) * 0.01
	skada2server[SkadaType.GOT_DAMAGE] = math.round(skada2server[SkadaType.GOT_DAMAGE] * 100) * 0.01

	return skada2server
end
---------------------------------------------------
-- get set end --
---------------------------------------------------
function BattleSkadaDriver:DumpSkadaData()
	local skadaTypeName = {}
	for key, value in pairs(SkadaType) do
		skadaTypeName[tostring(value)] = key
	end

	local createSkadaDataFunc = function(skadaRealTime)
		local teamSkadaMap = {}
		for teamIndex, teamSkadaData in pairs(skadaRealTime) do
			local memberSkadaMap = {}
			local totalSkadaMap  = {}
			for dataType, skadaData in pairs(teamSkadaData) do
				local typeName = skadaTypeName[tostring(dataType)]
				totalSkadaMap[typeName] = skadaData.sum
				for memberId, memberData in pairs(skadaData.memberSkada) do
					local memberKey = tostring(memberId)
					memberSkadaMap[memberKey] = memberSkadaMap[memberKey] or {}
					memberSkadaMap[memberKey][typeName] = memberData.sum
				end
			end
			teamSkadaMap[teamIndex] = {
				cards = memberSkadaMap,
				total = totalSkadaMap,
			}
		end
		return teamSkadaMap
	end

	local friendTeamSkadaMap = createSkadaDataFunc(self.friendSkadaRealTime)
	local enemyTeamSkadaMap  = createSkadaDataFunc(self.enemySkadaRealTime)

	print('here check skada string >>>>>>>>>>>>>>>>>>>>>>>>>>>')

	local result = {
		friendSkadaData = friendTeamSkadaMap,
		enemySkadaData  = enemyTeamSkadaMap,
	}
	print(json.encode(result))

	print('here check skada string <<<<<<<<<<<<<<<<<<<<<<<<<<<')

	return result
end

return BattleSkadaDriver
