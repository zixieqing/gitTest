--[[
战斗管理器基类
@params _ table {
	battleConstructor BattleConstructor 战斗构造器
}
--]]
---@class BaseBattleManager
local BaseBattleManager = class('BaseBattleManager')

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

--[[
construtor
--]]
function BaseBattleManager:ctor( ... )
	local args = unpack({...})

	self.battleConstructor = args.battleConstructor

	self:Init()
end

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化逻辑
--]]
function BaseBattleManager:Init()
	-- 战斗驱动器
	self.drivers = {}
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- battle driver begin --
---------------------------------------------------
--[[
获取战斗驱动
@params battleDriverType BattleDriverType 战斗驱动类型
--]]
function BaseBattleManager:GetBattleDriver(battleDriverType)
	return self.drivers[battleDriverType]
end
--[[
设置战斗驱动
@params battleDriverType BattleDriverType 战斗驱动类型
@params battleDriver BaseBattleDriver
--]]
function BaseBattleManager:SetBattleDriver(battleDriverType, battleDriver)
	self.drivers[battleDriverType] = battleDriver
end
---------------------------------------------------
-- battle driver end --
---------------------------------------------------

---------------------------------------------------
-- battle constructor begin --
---------------------------------------------------
--[[
获取战斗构造器
--]]
function BaseBattleManager:GetBattleConstructor()
	return self.battleConstructor
end
--[[
获取战斗构造数据
--]]
function BaseBattleManager:GetBattleConstructData()
	return self:GetBattleConstructor():GetBattleConstructData()
end
--[[
获取当前关卡id
--]]
function BaseBattleManager:GetCurStageId()
	return self:GetBattleConstructData().stageId
end
--[[
获取本次战斗类型
@return _ QuestBattleType
--]]
function BaseBattleManager:GetQuestBattleType()
	return self:GetBattleConstructData().questBattleType
end
--[[
获取地图信息
@params wave int 波数
@return _ 背景图信息
--]]
function BaseBattleManager:GetBattleBgInfo(wave)
	return self:GetBattleConstructData().backgroundInfo[wave]
end
--[[
获取阵容信息
@params isEnemy bool 是否是敌人
@return _ FormationStruct
--]]
function BaseBattleManager:GetTeamData(isEnemy)
	if isEnemy then
		return self:GetBattleConstructData().enemyFormation
	else
		return self:GetBattleConstructData().friendFormation
	end
end
--[[
获取队伍编号
@params isEnemy bool 是否是敌人
@return _ int team id
--]]
function BaseBattleManager:GetTeamId(isEnemy)
	if isEnemy then
		return self:GetBattleConstructData().enemyFormation.teamId
	else
		return self:GetBattleConstructData().friendFormation.teamId
	end
end
--[[
获取阵容成员信息
@params isEnemy bool 是否是敌人
@params wave int 波数
@return _ list 阵容信息
--]]
function BaseBattleManager:GetBattleMembers(isEnemy, wave)
	if nil == wave then
		return self:GetTeamData(isEnemy).members
	else
		return self:GetTeamData(isEnemy).members[wave]	
	end
end
--[[
获取主角技
--]]
function BaseBattleManager:GetPlayerSkilInfo(isEnemy)
	return self:GetTeamData(isEnemy).playerSkillInfo
end
--[[
获取关卡天气配置
--]]
function BaseBattleManager:GetStageWeatherConfig()
	return self:GetBattleConstructData().weather
end
--[[
根据波数获取过关配置
@params wave int 波数
@return _ StageCompleteSturct 过关配置信息
--]]
function BaseBattleManager:GetStageCompleteInfoByWave(wave)
	return self:GetBattleConstructData().stageCompleteInfo[wave]
end
--[[
根据波数重新设置过关配置
@params wave int 波数
@params stageCompleteInfo StageCompleteSturct 过关配置信息
--]]
function BaseBattleManager:SetStageCompleteInfoByWave(wave, stageCompleteInfo)
	self:GetBData():GetBattleConstructData().stageCompleteInfo[wave] = stageCompleteInfo
end
--[[
根据敌友性获取全军属性系数
@params isEnemy bool 敌友性
@return _ ObjectPropertyFixedAttrStruct 
--]]
function BaseBattleManager:GetFormationPropertyAttr(isEnemy)
	return self:GetTeamData(isEnemy).propertyAttr
end
--[[
获取全局效果
@return _ list {skill = nil, level = nil}
--]]
function BaseBattleManager:GetGlobalEffects()
	return self:GetBattleConstructData().globalEffects
end
--[[
获取战斗界面结算类型
@return _ ConfigBattleResultType 结算类型
--]]
function BaseBattleManager:GetBattleResultViewType()
	return self:GetBattleConstructData().resultType
end
--[[
是否可以复刷
@return _ bool
--]]
function BaseBattleManager:CanRechallenge()
	return self:GetBattleConstructData().canRechallenge
end
--[[
获取战斗网络命令
@return _ BattleNetworkCommandStruct 战斗网络命令
--]]
function BaseBattleManager:GetServerCommand()
	return self:GetBattleConstructor():GetServerCommand()
end
--[[
混合战斗参数
@params commonParams table 参数集合
--]]
function BaseBattleManager:AddGameOverServerCommandParameters(commonParams)
	if nil == self:GetServerCommand().exitBattleRequestData then
		self:GetServerCommand().exitBattleRequestData = {}
	end
	for k,v in pairs(commonParams) do
		self:GetServerCommand().exitBattleRequestData[k] = v
	end
end
--[[
获取进入战斗请求的参数
@return _ table
--]]
function BaseBattleManager:GetEnterBattleRequestData()
	return self:GetServerCommand().enterBattleRequestData
end
--[[
获取结算请求的参数
@return _ table
--]]
function BaseBattleManager:GetGameOverServerCommandParameters()
	return self:GetServerCommand().exitBattleRequestData
end
--[[
是否打开等级碾压
@return _ bool 是否打开等级碾压
--]]
function BaseBattleManager:IsLevelRollingOpen()
	return self:GetBattleConstructData().levelRolling
end
--[[
获取本次战斗对应的工会神兽id
@return _ int 神兽id
--]]
function BaseBattleManager:GetUnionBeastId()
	return self:GetBattleConstructor():GetUnionBeastId()
end
--[[
获取跳转信息
@return _ BattleMediatorsConnectStruct 跳转信息 
--]]
function BaseBattleManager:GetFromToData()
	return self:GetBattleConstructor():GetFromToData()
end
--[[
根据关卡id获取战斗引导配置
@return _ table 引导配置
--]]
function BaseBattleManager:GetBattleGuideConfigByStageId()
	local stageId = self:GetCurStageId()
	if nil == stageId then return nil end

	local guideInfos = CommonUtils.GetConfigAllMess('combatModule', 'guide')
	if nil == guideInfos then return nil end

	return guideInfos[tostring(stageId)]
end
--[[
获取本关卡配置的引导组id
@return guideModuleId int 引导模块id
--]]
function BaseBattleManager:GetGuideModuleId()
	local guideConfig = self:GetBattleGuideConfigByStageId()
	if nil == guideConfig then return nil end
	
	return checkint(guideConfig.id)
end
--[[
判断关卡是否是rep
@return _ bool 是否是战斗回放
--]]
function BaseBattleManager:IsReplay()
	return self:GetBattleConstructor():IsReplay()
end
--[[
判断本次战斗是否是战报生成
@return _ bool 是否是战报生成
--]]
function BaseBattleManager:IsCalculator()
	return self:GetBattleConstructor():IsCalculator()
end
---------------------------------------------------
-- battle constructor end --
---------------------------------------------------

---------------------------------------------------
-- battle common api begin --
---------------------------------------------------
--[[
判断是否是世界boss类型
@return _ bool 是否是世界boss类型
--]]
function BaseBattleManager:IsShareBoss()
	local questBattleType = self:GetQuestBattleType()

	local b = QuestBattleType.UNION_BEAST == questBattleType or
		QuestBattleType.WORLD_BOSS == questBattleType
		
	return b
end
--[[
判断是否是pvc模式
@return _ bool 是否是 card vs card
--]]
function BaseBattleManager:IsCardVSCard()
	local questBattleType = self:GetQuestBattleType()
	local battleTypeConfig = {
		[QuestBattleType.ROBBERY] 			     = true, -- 打劫
		[QuestBattleType.PVC] 				     = true, -- 皇家对决
		[QuestBattleType.TAG_MATCH_3V3] 	     = true, -- 3v3
		[QuestBattleType.UNION_PVC] 		     = true, -- 工会战打人
		[QuestBattleType.ULTIMATE_BATTLE] 	     = true, -- 巅峰对决
		[QuestBattleType.SKIN_CARNIVAL] 	     = true, -- 皮肤嘉年华
		[QuestBattleType.FRIEND_BATTLE] 	     = true, -- 好友切磋
		[QuestBattleType.CHAMPIONSHIP_PROMOTION] = true, -- 武道会-晋级赛
	}
	return true == battleTypeConfig[questBattleType]
end
--[[
是否可以重开本场战斗
@return _ bool 是否可以重开本场战斗
--]]
function BaseBattleManager:CanRestartGame()
	local questBattleType = self:GetQuestBattleType()
	local b = not (self:IsCardVSCard() or self:IsShareBoss() or (QuestBattleType.ACTIVITY_QUEST == questBattleType))
	return b
end
--[[
获取高亮修正的zorder
@return _ int zorder
--]]
function BaseBattleManager:GetFixedHighlightZOrder()
	return BATTLE_E_ZORDER.SPECIAL_EFFECT + 1
end
--[[
获取obj的zorder
@params pos cc.p 位置坐标
@params isEnemy bool 是否是敌人
@params isInHighlight bool 是否处于高亮状态
@return zorder int local zorder
--]]
function BaseBattleManager:GetObjZOrderInBattle(pos, isEnemy, isInHighlight)
	local zorder = self:GetZOrderInBattle(pos)

	if isEnemy then
		zorder = zorder - 1
	end

	if isInHighlight then
		zorder = zorder + self:GetFixedHighlightZOrder()
	end

	return zorder
end
--[[
根据y坐标换算zorder
@params p cc.p 坐标
@return zorder int cocos2dx zorder
--]]
function BaseBattleManager:GetZOrderInBattle(p)
	local zorderMax = self:GetBConf().BATTLE_AREA.height * 2
	local zorder = zorderMax - checkint(p.y - self:GetBConf().BATTLE_AREA.y)
	return zorder
end
--[[
是否是多队车轮战
@return _ bool 是否是多队阵容的车轮战模式
--]]
function BaseBattleManager:IsTagMatchBattle()
	if QuestBattleType.TAG_MATCH_3V3 == self:GetQuestBattleType() then
		return true
	end

	if 1 < #self:GetBattleMembers(false) then
		return true
	end

	return false
end
---------------------------------------------------
-- battle common api end --
---------------------------------------------------

---------------------------------------------------
-- buy revive begin --
---------------------------------------------------
--[[
是否能够买活
@return _ bool 是否能够买活
--]]
function BaseBattleManager:CanBuyRevival()
	return self:GetBattleConstructData().canBuyCheat and self:GetLeftBuyRevivalTime() > 0
end
--[[
获取剩余的买活次数
@return _ int 剩余买活次数
--]]
function BaseBattleManager:GetLeftBuyRevivalTime()
	return math.max(0, self:GetMaxBuyRevivalTime() - self:GetBuyRevivalTime())
end
--[[
获取最大买活次数
@return _ int 最大买活次数
--]]
function BaseBattleManager:GetMaxBuyRevivalTime()
	return self:GetBattleConstructData().buyRevivalTimeMax
end
--[[
获取已经买活的次数
@return _ int 已经买活次数
--]]
function BaseBattleManager:GetBuyRevivalTime()
	return self:GetBattleConstructData().buyRevivalTime
end
--[[
获取下一次买活次数
--]]
function BaseBattleManager:GetNextBuyRevivalTime()
	return math.min(self:GetMaxBuyRevivalTime(), self:GetBuyRevivalTime() + 1)
end
---------------------------------------------------
-- buy revive end --
---------------------------------------------------

return BaseBattleManager
