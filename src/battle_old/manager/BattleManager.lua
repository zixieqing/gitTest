--[[
战斗总控制器
@params _ table {
	battleConstructor BattleConstructor 战斗构造器
}
--]]
local BattleManager = class('BattleManager')

------------ import ------------
__Require('battle.controller.BattleConstants') 
__Require('battle.controller.BattleExpression')
__Require('battle.util.BattleUtils')
__Require('battle.util.BattleConfigUtils')
__Require('battle.battleStruct.BaseStruct')
__Require('battle.battleStruct.ObjStruct')
__Require('battle.object.ObjProperty')
__Require('battle.object.MonsterProperty')

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local cardMgr = AppFacade.GetInstance():GetManager('CardManager')
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local scheduler = require('cocos.framework.scheduler')
------------ import ------------

------------ define ------------
local RENDER_FPS = 1 / 60
local UI_FPS = 1 / 45

local BUY_REVIVAL_LAYER_TAG = 2301
local FORCE_QUIT_LAYER_TAG = 2311
local GAME_RESULT_LAYER_TAG = 2321
local BATTLE_SUCCESS_VIEW_TAG = 3302

local PAUSE_SCENE_TAG = 1001
local NAME = 'BattleMediator'
------------ define ------------
--[[
construtor
--]]
function BattleManager:ctor( ... )
	BMediator = self
	local args = unpack({...})

	------------ 初始化外部传参 ------------
	self.battleConstructor = args.battleConstructor
	------------ 初始化外部传参 ------------

	------------ battle temp data ------------
	self.bconf = {}
	self.bdata = nil
	self.updateHandler = nil
	self.mainUpdateOn = false
	self.objEvents = {}
	self.globalEvents = {}
	self.battleSceneLoadingOver = false
	self.drivers = {}
	------------ battle temp data ------------

	------------ ui data ------------
	self.connectButtonsIndex = {}
	------------ ui data ------------

	self.BNetworkMediator = AppFacade.GetInstance():RetrieveMediator('BattleNetworkMediator')
	if not self.BNetworkMediator then
		local BattleNetworkMediator = require('battleEntry.network.BattleNetworkMediator')
		self.BNetworkMediator = BattleNetworkMediator.new()
		AppFacade.GetInstance():RegistMediator(self.BNetworkMediator)
	end
end
---------------------------------------------------
-- logic init begin --
---------------------------------------------------
--[[
初始化战斗逻辑
--]]
function BattleManager:InitBattleLogic()
	------------ 初始化一些界面配置 ------------
	-- 初始化导演物体
	self:InitDirector()
	-- 初始化一些额外ui
	self:InitBattleUIInfo()
	------------ 初始化一些界面配置 ------------	

	------------ 初始化随机数配置 ------------
	-- 初始化随机数管理器
	self.randomManager = __Require('battle.controller.RandomManager').new()
	local randomConfig = self:GetOriBattleConstructor():GetBattleRandomConfig()
	self.randomManager:RefreshRandomConfig(randomConfig)
	------------ 初始化随机数配置 ------------

	-- 初始化战场信息 战场配置
	self:InitBattleConfig()
	self:RefreshTimeLabel(checkint(self:GetBData().leftTime))

	------------ 初始化战斗逻辑驱动器 ------------
	self:InitBattleLogicDriver()
	------------ 初始化战斗逻辑驱动器 ------------

	-- 初始化全局buff物体
	self:InitGlobalEffect()
	
	-- 初始化战斗物体信息
	self:CreateNextWave()
	-- 初始化天气
	self:InitWeather()
	-- 初始化主角模型
	self:InitPlayer()
	-- 战斗物体初始化完成后 初始化光环 被动
	self:InitHalosEffect()
	-- 初始化事件控制器
	self:InitEventController()
	print(Logger.INFO, '!!!hey here start battle!!!'.. tostring(os.clock()))

	-- 初始化加速记录
	self:SetTimeScale(self:GetBData():getBattleConstructData().gameTimeScale)

	-- 初始化功能模块
	self:InitFunctionModule()

	-- 初始化引导
	self:InitGuide()

	-- 初始化语音驱动
	self:InitVoice()

	-- 初始化全局ob物体
	self:InitOBOjbect()

	-- self:ShowDebugInfo()
	-- self:ShowAllCollisionBox()
	-- self:ShowGuideDebug()

	-- 记录一次所有物体的属性
	self:GetBData().startAliveFriendObjPStr = self:GetBData():convertAllFriendObjPStr()
end
--[[
初始化战场信息
--]]
function BattleManager:InitBattleConfig()
	-- 战斗区域是大小定死的矩形
	local designScreenSize = cc.size(1334, 750)
	local designBgImgSize = cc.size(1334, 1002)

	-- 基础配置
	local oriL, oriR, oriB, oriT = 0, 1334, 200, 530
	local oriW = oriR - oriL
	local oriH = oriT - oriB

	local battleRootSize = cc.size(
		self:GetBattleRoot():getContentSize().width,
		self:GetBattleRoot():getContentSize().height
	)

	local battleFieldImg = self:GetViewComponent().viewData.mainField
	local battleFieldImgScaleY = battleFieldImg:getScaleY()
	local battleFieldImgSize = cc.size(
		battleFieldImg:getContentSize().width,
		battleFieldImg:getContentSize().height
	)

	-- 计算修正起点
	local x = battleRootSize.width * 0.5 - oriW * 0.5
	-- y坐标是相对背景图的
	local y = oriB + battleRootSize.height * 0.5 - designBgImgSize.height * 0.5

	self.bconf.BATTLE_AREA = cc.rect(x, y, oriW, oriH)
	self.bconf.BATTLE_AREA_MAX_DIS = self.bconf.BATTLE_AREA.width * self.bconf.BATTLE_AREA.width + self.bconf.BATTLE_AREA.height * self.bconf.BATTLE_AREA.height
	self.bconf.ROW = 5
	self.bconf.COL = 30

	------------ 特殊处理一次cellSize ------------
	local cellSizeW = self.bconf.BATTLE_AREA.width / self.bconf.COL
	local cellSizeH = self.bconf.BATTLE_AREA.height / self.bconf.ROW
	self.bconf.cellSizeWidth = cellSizeW
	self.bconf.cellSizeHeight = cellSizeH
	self.bconf.cellSize = cc.size(cellSizeW, cellSizeH)
	------------ 特殊处理一次cellSize ------------

	self:InitCellsCoordinate()

end
--[[
初始化战斗格子坐标
--]]
function BattleManager:InitCellsCoordinate()
	self.bconf.cellsCoordinate = {}
	for r = 1, self.bconf.ROW do
		if nil == self.bconf.cellsCoordinate[r] then
			self.bconf.cellsCoordinate[r] = {}
		end
		for c = 1, self.bconf.COL do
			self.bconf.cellsCoordinate[r][c] = {
				cx = self.bconf.BATTLE_AREA.x + self.bconf.cellSize.width * 0.5 + ((c - 1) * self.bconf.cellSize.width),
				cy = self.bconf.BATTLE_AREA.y + self.bconf.cellSize.height * 0.5 + ((r - 1) * self.bconf.cellSize.height),
				box = cc.rect(
					self.bconf.BATTLE_AREA.x + ((c - 1) * self.bconf.cellSize.width),
					self.bconf.BATTLE_AREA.y + ((r - 1) * self.bconf.cellSize.height),
					self.bconf.cellSize.width,
					self.bconf.cellSize.height
				)
			}
		end
	end
end
--[[
初始化battleData
--]]
function BattleManager:InitBattleData()
	self.bdata = __Require('battle.controller.BattleData').new({
		battleConstructor = self.battleConstructor
	})
end
--[[
初始化战斗逻辑驱动器
--]]
function BattleManager:InitBattleLogicDriver()
	-- 切波驱动
	local isTagMatch = self:IsTagMatchBattle()
	local shiftDriverClassName = 'battle.battleDriver.BattleShiftDriver'
	if isTagMatch then
		shiftDriverClassName = 'battle.battleDriver.TagMatchShiftDriver'
	end
	local shiftDriver = __Require(shiftDriverClassName).new({
		owner = self
	})
	self:SetBattleDriver(BattleDriverType.SHIFT_DRIVER, shiftDriver)

	-- 战斗结束驱动
	for wave, v in ipairs(self:GetBData():getBattleConstructData().stageCompleteInfo) do
		local endDriverClassName = 'battle.battleDriver.BattleEndDriver'

		if ConfigStageCompleteType.SLAY_ENEMY == v.completeType then

			endDriverClassName = 'battle.battleDriver.SlayEndDriver'

		elseif ConfigStageCompleteType.HEAL_FRIEND == v.completeType then

			endDriverClassName = 'battle.battleDriver.HealEndDriver'

		elseif ConfigStageCompleteType.ALIVE == v.completeType then

			endDriverClassName = 'battle.battleDriver.AliveEndDriver'

		elseif ConfigStageCompleteType.TAG_MATCH == v.completeType or isTagMatch then

			endDriverClassName = 'battle.battleDriver.TagMatchEndDriver'

		end
		local endDriver = __Require(endDriverClassName).new({
			owner = self,
			wave = wave,
			stageCompleteInfo = v
		})
		self:SetEndDriver(wave, endDriver)
	end
end
--[[
初始化光环
--]]
function BattleManager:InitHalosEffect()
	local obj = nil

	for i = #self:GetBData().sortWeather, 1, -1 do
		obj = self:GetBData().sortWeather[i]
		obj:castAllHalos()
	end

	for i = #self:GetBData().sortBattleObjs.friend, 1, -1 do
		obj = self:GetBData().sortBattleObjs.friend[i]
		obj:castAllHalos()
	end

	for i = #self:GetBData().sortBattleObjs.enemy, 1, -1 do
		obj = self:GetBData().sortBattleObjs.enemy[i]
		obj:castAllHalos()
	end

	for i = #self:GetBData().sortPlayerObj.friend, 1, -1 do
		obj = self:GetBData().sortPlayerObj.friend[i]
		obj:castAllHalos()
	end

	for i = #self:GetBData().sortPlayerObj.enemy, 1, -1 do
		obj = self:GetBData().sortPlayerObj.enemy[i]
		obj:castAllHalos()
	end

	self:GetBData():GetGlobalEffectObj():castAllHalos()
end
--[[
初始化天气
--]]
function BattleManager:InitWeather()
	local weatherInfo = self:GetBData():getStageWeatherConf()
	if nil ~= weatherInfo then
		local weatherConf = nil

		local isEnemy = false
		local location = ObjectLocation.New(0, 0, 0, 0)

		for i,v in ipairs(weatherInfo) do
			local weatherId = checkint(v)
			weatherConf = CommonUtils.GetConfig('quest', 'weather', weatherId)
			if nil ~= weatherConf then
				------------ new ------------
				local objInfo = ObjectConstructorStruct.New(
					weatherId, location, 1, BattleObjectFeature.BASE, ConfigCardCareer.BASE, isEnemy,
					nil, nil, nil, nil, false, nil,
					nil, nil, nil,
					nil
				)
				local tagInfo = self:GetBData():getWeatherTag()
				local weatherObject = __Require('battle.object.WeatherObject').new({
					tag = tagInfo.tag,
					oname = tagInfo.oname,
					battleElementType = BattleElementType.BET_WEATHER,
					objInfo = objInfo
				})
				self:GetBData():addAWeather(weatherObject)
				------------ new ------------
			end
		end
	end
end
--[[
初始化主角模型
--]]
function BattleManager:InitPlayer()
	------------ new ------------
	-- 友方主角
	local friendPlayerSkills = self:GetBData():getPlayerSkilInfo(false)
	local location = ObjectLocation.New(0, 0, 0, 0)
	local objInfo = ObjectConstructorStruct.New(
		ConfigSpecialCardId.PLAYER, location, 1, BattleObjectFeature.BASE, ConfigCardCareer.BASE, false,
		nil, friendPlayerSkills, nil, nil, false, nil,
		nil, nil, nil,
		nil
	)
	local tagInfo = self:GetBData():getPlayerTag(false)
	local friendPlayerObject = __Require('battle.object.PlayerObject').new({
		tag = tagInfo.tag,
		oname = tagInfo.oname,
		battleElementType = BattleElementType.BET_PLAYER,
		objInfo = objInfo
	})
	self:GetBData():addAPlayerObj(friendPlayerObject)

	-- 敌方主角
	local enemyPlayerSkills = self:GetBData():getPlayerSkilInfo(true)
	if nil ~= enemyPlayerSkills then
		local location = ObjectLocation.New(0, 0, 0, 0)
		local objInfo = ObjectConstructorStruct.New(
			ConfigSpecialCardId.PLAYER, location, 1, BattleObjectFeature.BASE, ConfigCardCareer.BASE, true,
			nil, enemyPlayerSkills, nil, nil, false, nil,
			nil, nil, nil,
			nil
		)
		local tagInfo = self:GetBData():getPlayerTag(true)
		local enemyPlayerObject = __Require('battle.object.EnemyPlayerObject').new({
			tag = tagInfo.tag,
			oname = tagInfo.oname,
			battleElementType = BattleElementType.BET_PLAYER,
			objInfo = objInfo
		})
		self:GetBData():addAPlayerObj(enemyPlayerObject)
	end
	------------ new ------------
end
--[[
对战斗单位阵容排序
@params t table 战斗单位阵容信息
@return k table 返回按阵容站位排序的key
--]]
function BattleManager:SortObjFormation(t)
	local k = table.keys(t)
	table.sort(k, function (a, b)
		local aconf = CardUtils.GetCardConfig(t[a]:GetObjectConfigId())
		local bconf = CardUtils.GetCardConfig(t[b]:GetObjectConfigId())
		if checkint(aconf.career) == checkint(bconf.career) then
			return a < b
		else
			return checkint(aconf.career) < checkint(bconf.career)
		end
	end)
	if 1 < table.nums(k) then
		-- 对卡牌第一张卡做一次过滤 如果是坦克 插到二号位
		local no = k[1]
		local cardConf = CardUtils.GetCardConfig(t[no]:GetObjectConfigId())
		if ConfigCardCareer.TANK == checkint(cardConf.career) then
			table.remove(k, 1)
			table.insert(k, 2, no)
		end
	end
	return k
end
--[[
初始化事件控制器
--]]
function BattleManager:InitEventController()
	self.connectSkillHighlightEvent = __Require('battle.event.ConnectSkillHighlightEvent').new({
		owner = self,
		effectLayer = self:GetViewComponent().viewData.effectLayer
	})
end
--[[
初始化引导
--]]
function BattleManager:InitGuide()
	local stageId = self:GetBData():getBattleConstructData().stageId
	if nil ~= stageId then

		local guideInfos = CommonUtils.GetConfigAllMess('combatModule', 'guide')
		local guideConfig = guideInfos[tostring(stageId)]

		if nil ~= guideConfig then
			-- 创建一个ob物体 引导精灵
			local isEnemy = false
			local location = ObjectLocation.New(0, 0, 0, 0)
			local objInfo = ObjectConstructorStruct.New(
				nil, location, 1, BattleObjectFeature.BASE, ConfigCardCareer.BASE, isEnemy,
				nil, nil, nil, nil, false, nil,
				nil, nil, nil,
				nil
			)
			local tagInfo = self:GetBData():getObserverTag()

			local obObject = __Require('battle.object.BaseOBObject').new({
				tag = tagInfo.tag,
				oname = tagInfo.name,
				battleElementType = BattleElementType.BET_OB,
				objInfo = objInfo
			})
			obObject:setGuideModule(checkint(guideConfig.id))
			self:GetBData():addAObserver(obObject)

			-- 隐藏功能模块
			for i,v in ipairs(guideConfig.hiddenFunction) do
				self:GetViewComponent():ShowBattleFunctionModule(checkint(v), false)
			end
		end
	end
end
--[[
初始化语音驱动
--]]
function BattleManager:InitVoice()
	if QuestBattleType.PERFORMANCE ~= self:GetBData():getBattleConstructData().questBattleType then return end

	local stageId = self:GetBData():getBattleConstructData().stageId
	if nil ~= stageId then

		if true then
			-- 创建一个ob物体 语音精灵
			local isEnemy = false
			local location = ObjectLocation.New(0, 0, 0, 0)
			local objInfo = ObjectConstructorStruct.New(
				nil, location, 1, BattleObjectFeature.BASE, ConfigCardCareer.BASE, isEnemy,
				nil, nil, nil, nil, false, nil,
				nil, nil, nil,
				nil
			)
			local tagInfo = self:GetBData():getObserverTag()
			local obObject = __Require('battle.object.VoiceOBObject').new({
				tag = tagInfo.tag,
				oname = tagInfo.name,
				battleElementType = BattleElementType.BET_OB,
				objInfo = objInfo
			})
			obObject:setVoiceModule(stageId)
			self:GetBData():addAObserver(obObject)
		end
	end
end
--[[
初始化全局效果
--]]
function BattleManager:InitGlobalEffect()
	local isEnemy = false
	local location = ObjectLocation.New(0, 0, 0, 0)
	local objInfo = ObjectConstructorStruct.New(
		nil, location, 1, BattleObjectFeature.BASE, ConfigCardCareer.BASE, isEnemy,
		nil, nil, nil, nil, false, nil,
		nil, nil, nil,
		nil
	)
	local otag = GLOBAL_EFFECT_TAG + 1
	local geObj = __Require('battle.object.GlobalEffectObject').new({
		tag = otag,
		oname = tostring(otag),
		battleElementType = BattleElementType.BET_OB,
		objInfo = objInfo
	})
	if QuestBattleType.TOWER == self:GetBData():getBattleConstructData().questBattleType then
		-- TODO --
		-- 爬塔的契约暂时特殊处理
		geObj.castDriver:InitEffects(self:GetBData():getBattleConstructData().globalEffects)
	else
		geObj.castDriver:InitSkills(self:GetBData():getBattleConstructData().globalEffects)
	end
	geObj.castDriver:InitUnionPetSkills(gameMgr:GetUnionPetsData())
	self:GetBData():SetGlobalEffectObj(geObj)

	-- 初始化一次其他类型效果
	geObj.castDriver:OnActionEnter()
end
--[[
初始化导演物体
--]]
function BattleManager:InitDirector()
	local isEnemy = false
	local location = ObjectLocation.New(0, 0, 0, 0)
	local objInfo = ObjectConstructorStruct.New(
		nil, location, 1, BattleObjectFeature.BASE, ConfigCardCareer.BASE, isEnemy,
		nil, nil, nil, nil, false, nil,
		nil, nil, nil,
		nil
	)
	local otag = DIRECTOR_TAG + 1
	local directorObj = __Require('battle.object.DirectorObject').new({
		tag = otag,
		oname = tostring(otag),
		battleElementType = BattleElementType.BET_OB,
		objInfo = objInfo
	})
	self:GetBData():SetDirectorObj(directorObj)
	self:GetBData():addAObserver(directorObj)

	-- 初始化一次初始场景
	self:GetBData():GetDirectorObj():OnGameStart()
end
--[[
初始化功能模块
--]]
function BattleManager:InitFunctionModule()
	if self:IsCardVSCard() then
		-- 隐藏主角技 波数
		self:GetViewComponent():ShowBattleFunctionModule(ConfigBattleFunctionModuleType.PLAYER_SKILL, false)
		self:GetViewComponent():ShowBattleFunctionModule(ConfigBattleFunctionModuleType.WAVE, false)
	elseif QuestBattleType.PERFORMANCE == self:GetBData():getBattleConstructData().questBattleType then
		-- 隐藏所有模块
		self:GetViewComponent():HideAllBattleFunctionModule()
	elseif QuestBattleType.RAID == self:GetBData():getBattleConstructData().questBattleType then
		-- 隐藏所有功能模块
		self:GetViewComponent():ShowBattleFunctionModule(ConfigBattleFunctionModuleType.WAVE, false)
		self:GetViewComponent():ShowBattleFunctionModule(ConfigBattleFunctionModuleType.PLAYER_SKILL, false)
		self:GetViewComponent():ShowBattleFunctionModule(ConfigBattleFunctionModuleType.ACCELERATE_GAME, false)
		self:GetViewComponent():ShowBattleFunctionModule(ConfigBattleFunctionModuleType.PAUSE_GAME, false)
	elseif self:IsShareBoss() then
		-- 世界boss模式隐藏主角技和过关目标
		self:GetViewComponent():ShowBattleFunctionModule(ConfigBattleFunctionModuleType.PLAYER_SKILL, false)
		self:GetViewComponent():ShowBattleFunctionModule(ConfigBattleFunctionModuleType.STAGE_CLEAR_TARGET, false)
	end

	-- 根据配表信息隐藏功能模块信息
	local hideBattleFunctionModule = self:GetBData():getBattleConstructData().hideBattleFunctionModule
	if nil ~= hideBattleFunctionModule then
		for _, moduleType in ipairs(hideBattleFunctionModule) do
			self:GetViewComponent():ShowBattleFunctionModule(checkint(moduleType), false)
		end
	end 
end
--[[
初始化一些界面配置
--]]
function BattleManager:InitBattleUIInfo()
	------------ 车轮战ui ------------
	if self:IsTagMatchBattle() then
		self:GetViewComponent():InitTagMatchView(
			self:GetBData():getFriendMembers(),
			self:GetBData():getEnemyMembers()
		)
	end
	------------ 车轮战ui ------------
end
--[[
注册销毁定时器
--]]
function BattleManager:RegisterMainUpdate()
	if nil == self.updateHandler then
		self.updateHandler = scheduler.scheduleUpdateGlobal(handler(self, self.MainUpdate))
		self.mainUpdateOn = true
	else
		print(BattleUtils.PrintBattleWaringLog('logic error here register mainupdate twice'))
	end
end
function BattleManager:UnregisterMainUpdate()
	if nil ~= self.updateHandler then
		self.mainUpdateOn = false
		scheduler.unscheduleGlobal(self.updateHandler)
		self.updateHandler = nil
	else
		print(BattleUtils.PrintBattleWaringLog('logic error here unregister mainupdate twice'))
	end
end
--[[
update是否有效
--]]
function BattleManager:IsMainUpdateValid()
	return self.mainUpdateOn
end
--[[
初始化全局ob物体
--]]
function BattleManager:InitOBOjbect()
	local isEnemy = false
	local location = ObjectLocation.New(0, 0, 0, 0)
	local objInfo = ObjectConstructorStruct.New(
		nil, location, 1, BattleObjectFeature.BASE, ConfigCardCareer.BASE, isEnemy,
		nil, nil, nil, nil, false, nil,
		nil, nil, nil,
		nil
	)
	local tagInfo = self:GetBData():getObserverTag()
	local obObject = __Require('battle.object.OBObject').new({
		tag = tagInfo.tag,
		oname = tagInfo.name,
		battleElementType = BattleElementType.BET_OB,
		objInfo = objInfo
	})
	self:GetBData():addAObserver(obObject)
end
---------------------------------------------------
-- logic init end --
---------------------------------------------------

------------------------------------------------------------------------------------------------------
-- battle control begin --
------------------------------------------------------------------------------------------------------
function BattleManager:StartGameAndLoadingResources()
	-- 设置标识位 开始加载
	self:SetBattleSceneLoadingOver(false)

	self:InitBattleData()
	
	local stageId = self:GetBData():getCurStageId()
	uiMgr:SwitchToWelcomScene({
		stageId = stageId,
		loadTasks = handler(self, self.LoadResources),
		done = function ()
			local bgInfo = self:GetBData():getBattleBgInfo(self:GetBData():getNextWave())
			uiMgr:SwitchToTargetScene(_GBC('battle.view.BattleScene'), {
				backgroundId = bgInfo.bgId,
				weatherId = self:GetBData():getStageWeatherConf(),
				questBattleType = self:GetQuestBattleType(),
				friendTeams = self:GetBData():getFriendMembers(),
				enemyTeams = self:GetBData():getEnemyMembers()
			})
		end})
end
--[[
加载完毕 开始初始化战斗逻辑
@params data table {
	battleScene  cc.Node 战斗场景实例
}
--]]
function BattleManager:LoadingOverAndInitBattleLogic(data)
	local battleScene = data.battleScene

	self:SetBattleSceneLoadingOver(true)

	-- 设置战斗场景
	self:SetViewComponent(battleScene)
	-- 初始化逻辑
	self:InitialActions()
	self:InitBattleLogic()
	-- 开始战斗
	self:GameStart()
end
--[[
主循环
--]]
function BattleManager:MainUpdate(dt)

	if not self:IsMainUpdateValid() then return end

	local dt_ = dt

	------------ 规则外物体逻辑 ------------
	for i = #self:GetBData().sortObserverObj, 1, -1 do
		self:GetBData().sortObserverObj[i]:update(dt_)
	end
	------------ 规则外物体逻辑 ------------

	if self:IsPause() then return end

	------------ object view ------------
	self:UpdateViewModel(dt_)
	------------ object view ------------

	if GState.START == self:GetGState() then
		
		------------ 转阶段信息最优先判断 ------------
		-- 非阻塞型
		local phaseChangeingNeedReturn = false
		local triggerPhaseNpc = nil
		local pd = nil
		for i = #self:GetBData().nextPhaseChange.nonpauseLogic, 1, -1 do

			pd = self:GetBData().nextPhaseChange.nonpauseLogic[i]
			triggerPhaseNpc = self:IsObjAliveByTag(pd.objTag)

			if 0 >= pd.delayTime then
				if nil ~= triggerPhaseNpc then
					triggerPhaseNpc.phaseDriver:OnActionEnter(pd.index)
					-- 如果是死亡触发 计数器-1
					if true == pd.isDieTrigger then
						triggerPhaseNpc.phaseDriver.diePhaseChangeCounter = triggerPhaseNpc.phaseDriver.diePhaseChangeCounter - 1
						phaseChangeingNeedReturn = true
					end

					-- 发出一次触发转阶段的事件
					self:SendObjEvent(ObjectEvent.OBJECT_PHASE_CHANGE, {
						triggerPhaseNpcTag = pd.objTag,
						phaseId = pd.phaseId
					})
				end
				-- 移除该转阶段信息
				self:GetBData():removeAPhaseChange(false, i)
			else
				-- 延迟时间
				pd.delayTime = math.max(0, pd.delayTime - dt_)
			end

		end
		-- 阻塞型
		for i = #self:GetBData().nextPhaseChange.pauseLogic, 1, -1 do

			pd = self:GetBData().nextPhaseChange.pauseLogic[i]
			triggerPhaseNpc = self:IsObjAliveByTag(pd.objTag)

			if 0 >= pd.delayTime then
				if nil ~= triggerPhaseNpc then
					triggerPhaseNpc.phaseDriver:OnActionEnter(pd.index)
					if true == pd.isDieTrigger then
						triggerPhaseNpc.phaseDriver.diePhaseChangeCounter = triggerPhaseNpc.phaseDriver.diePhaseChangeCounter - 1
						phaseChangeingNeedReturn = true
					end

					-- 发出一次触发转阶段的事件
					self:SendObjEvent(ObjectEvent.OBJECT_PHASE_CHANGE, {
						triggerPhaseNpcTag = pd.objTag,
						phaseId = pd.phaseId
					})
				end
				-- 移除该转阶段信息
				self:GetBData():removeAPhaseChange(true, i)
				return
			else
				-- 延迟时间
				pd.delayTime = math.max(0, pd.delayTime - dt_)
			end
			
		end

		if true == phaseChangeingNeedReturn then
			return
		end
		------------ 转阶段信息最优先判断 ------------

		-- 判断游戏是否应该结束或者下一波
		local r = self:isGameOver()
		local needReturn = self:GetEndDriver():OnLogicEnter(r)
		if true == needReturn then
			return
		end

		------------ time logic ------------
		if not self:GetBData().isPauseTimer then
			self:GetBData().leftTime = math.max(self:GetBData().leftTime - dt_, 0)
			self:RefreshTimeLabel(self:GetBData().leftTime)

			self:GetEndDriver():OnLogicUpdate(dt_)
		end
		------------ time logic ------------

		------------ object logic ------------
		self:UpdateLogicModel(dt_)
		------------ object logic ------------

	elseif GState.TRANSITION == self:GetGState() then
		self:EnterNextWave(dt)
	elseif GState.SUCCESS == self:GetGState() then
		self:GameSuccess(dt)
	elseif GState.FAIL == self:GetGState() then
		self:GameFail(dt)
	elseif GState.BLOCK == self:GetGState() then
		self:GameRescue(dt)
	end

	if self.debugCollisionBox then
		for k,v in pairs(self.debugCollisionBox) do
			local o = self:IsObjAliveByTag(k)
			if o then
				local pos = o:getCollisionBoxInWorldSpace()
				v:setPosition(v:getParent():convertToNodeSpace(cc.p(pos.x, pos.y)))
			end
		end
	end
end
--[[
刷新展示层模型
--]]
function BattleManager:UpdateViewModel(dt)
	local viewModel = nil

	for i = #self:GetBData().sortObjViewModels, 1, -1 do
		viewModel = self:GetBData().sortObjViewModels[i]
		viewModel:Update(dt)
	end
end
--[[
刷新逻辑层模型
--]]
function BattleManager:UpdateLogicModel(dt)
	for _,pauseCIScene in pairs(self:GetBData().ciScenes.pause) do
		pauseCIScene:update(dt)
	end
	for _,normalCIScene in pairs(self:GetBData().ciScenes.normal) do
		normalCIScene:update(dt)
	end

	local obj = nil

	-- 友方主角
	for i = #self:GetBData().sortPlayerObj.friend, 1, -1 do
		obj = self:GetBData().sortPlayerObj.friend[i]
		obj:update(dt)
	end

	-- 所有子弹
	for i = #self:GetBData().sortBattleObjs.bullet, 1, -1 do
		obj = self:GetBData().sortBattleObjs.bullet[i]
		obj:update(dt)
	end

	-- 天气
	for i = #self:GetBData().sortWeather, 1, -1 do
		obj = self:GetBData().sortWeather[i]
		obj:update(dt)
	end

	-- 存活的战斗物体
	for i = #self:GetBData().sortBattleObjs.friend, 1, -1 do
		obj = self:GetBData().sortBattleObjs.friend[i]
		obj:update(dt)
	end
	for i = #self:GetBData().sortBattleObjs.enemy, 1, -1 do
		obj = self:GetBData().sortBattleObjs.enemy[i]
		obj:update(dt)
	end
	for i = #self:GetBData().sortBattleObjs.beckonObj, 1, -1 do
		obj = self:GetBData().sortBattleObjs.beckonObj[i]
		obj:update(dt)
	end
end
--[[
game start switch
--]]
function BattleManager:GameStart()
	self:SetBattleTouchEnable(false)
	self:ShowNextWave({wave = self:GetBData():getCurrentWave(),
		callback = handler(self, self.StartNextWave)})

	self:RegisterMainUpdate()

	if DEBUG_MEM then
		funLog(Logger.DEBUG, "----------------------------------------")
        funLog(Logger.DEBUG,string.format("LUA VM MEMORY USED: %0.2f KB", collectgarbage("count")))
        -- cc.Director:getInstance():getTextureCache():getCachedTextureInfo()
        funLog(Logger.DEBUG,"----------------------------------------")
    end
end
--[[
开始下一波
--]]
function BattleManager:StartNextWave()
	for k,o in orderedPairs(self:GetBData().battleObjs) do
		o:awake()
	end
	self:SetGState(GState.START)
	if not self:IsBattleTouchEnable() then self:SetBattleTouchEnable(true) end
end
--[[
游戏结束
@params gameResult BattleResult 3 成功 4 失败 
--]]
function BattleManager:GameOver(gameResult)
	self:GetEndDriver():GameOver(gameResult)
end
--[[
判断是否能进入下一波 判断动画是否播完
@params dt number
@return result bool 是否能进入下一波
--]]
function BattleManager:CanEnterNextWave(dt)
	return self:GetBattleDriver(BattleDriverType.SHIFT_DRIVER):CanEnterNextWave(dt)
end
--[[
进入下一波
@params dt number 
--]]
function BattleManager:EnterNextWave(dt)
	self:GetBattleDriver(BattleDriverType.SHIFT_DRIVER):OnLogicEnter(dt)
end
--[[
创建下一波敌人 在此处将波数+1
--]]
function BattleManager:CreateNextWave()
	self:GetBattleDriver(BattleDriverType.SHIFT_DRIVER):OnCreateNextWaveEnter(dt)
end
--[[
游戏胜利
--]]
function BattleManager:GameSuccess(dt)
	if not self:CanEnterNextWave(dt) then return end
	self:SetGState(GState.OVER)

	if nil == self:GetOriBattleConstructor():GetServerCommand() then
		self:BackToPrevious()
		return
	end

	----- network command -----
	local function callback(responseData)
		local bdata = self:GetBData()
		local obj = nil
		for i = #bdata.sortBattleObjs.friend, 1, -1 do
			obj = bdata.sortBattleObjs.friend[i]
			obj:win()
		end

		-- 刷新一些数据
		self:RefreshDataAfterGameSuccess()

		self:ShowGameSuccess(responseData)
	end

	local commonParameters = self:GetExitRequestCommonParameters(1)
	for k,v in pairs(commonParameters) do
		self:GetBData():getBattleConstructor():GetServerCommand().exitBattleRequestData[k] = v
	end

	self.BNetworkMediator:ReadyToExitBattle(self:GetBData():getBattleConstructor(), callback)
	----- network command -----
end
--[[
游戏失败
--]]
function BattleManager:GameFail(dt)
	if not self:CanEnterNextWave(dt) then return end
	self:SetGState(GState.OVER)

	if nil == self:GetOriBattleConstructor():GetServerCommand() then
		self:BackToPrevious()
		return
	end

	----- network command -----
	local function callback(responseData)
		self:ShowGameFail(responseData)
	end
	local passTime = math.round((self:GetBData():getGameTime() - self:GetBData().leftTime) * 100) / 100

	local commonParameters = self:GetExitRequestCommonParameters(0)
	for k,v in pairs(commonParameters) do
		self:GetBData():getBattleConstructor():GetServerCommand().exitBattleRequestData[k] = v
	end

	self.BNetworkMediator:ReadyToExitBattle(self:GetBData():getBattleConstructor(), callback)
	----- network command -----
end
--[[
游戏胜利之后刷新一些数据
--]]
function BattleManager:RefreshDataAfterGameSuccess()
	local stageId = self:GetBData():getCurStageId()

	if nil ~= stageId then
		-- 刷新一次怪物图鉴
		CommonUtils.CheckEncounterMonster(stageId)

		-- 刷新一次pass卡的数据
		if nil ~= app.passTicketMgr and nil ~= app.passTicketMgr.UpdateExpByQuestId then
			app.passTicketMgr:UpdateExpByQuestId(stageId, true)
		end
	end	
end
--[[
抢救游戏结果
--]]
function BattleManager:GameRescue(dt)
	if not self:CanEnterNextWave(dt) then return end
	self:SetGState(GState.OVER)
	self:ShowBuyRevival()
end
--[[
游戏是否结束
@return _ BattleResult 判断结果
--]]
function BattleManager:isGameOver()
	return self:GetEndDriver():CanDoLogic()
end
--[[
暂停游戏
--]]
function BattleManager:PauseGame()
	self:SetBattleTouchEnable(false)
	self:PauseMainLogic()
	self:PauseMainScene()
	self:PauseCIScene()
	self:PauseNormalCIScene()
	self:PauseBattleObjs()
	
	local scene = __Require('battle.miniGame.PauseScene').new()
	self:GetViewComponent():addChild(scene, BATTLE_E_ZORDER.PAUSE)
	scene:setTag(PAUSE_SCENE_TAG)
	for i, btn in ipairs(scene.viewData.actionButtons) do
		display.commonUIParams(btn, {cb = handler(self, self.ButtonActions)})
	end
end
--[[
恢复游戏
--]]
function BattleManager:ResumeGame()
	self:SetBattleTouchEnable(true)
	self:ResumeMainLogic()
	self:ResumeMainScene()

	local pauseScene = self:GetViewComponent():getChildByTag(PAUSE_SCENE_TAG)
	if nil ~= pauseScene then
		pauseScene:setVisible(false)
		pauseScene:runAction(cc.CallFunc:create(function ()
			pauseScene:die()
		end))
	end

	if table.nums(self:GetBData().pauseActions.ciScene) > 0 then
		-- 如果存在会暂停物体的场景 则只恢复这些场景
		self:ResumeCIScene()
	else
		-- 如果不存在会暂停物体的场景 则恢复所有的物体
		self:ResumeNormalCIScene()
		self:ResumeBattleObjs()
	end
end
--[[
暂停主逻辑
--]]
function BattleManager:PauseMainLogic()
	self:GetBData().isPause = true
end
--[[
暂停倒计时
--]]
function BattleManager:PauseTimer()
	self:GetBData().isPauseTimer = true
end
--[[
恢复倒计时
--]]
function BattleManager:ResumeTimer()
	self:GetBData().isPauseTimer = false
end
--[[
暂停ciScene
--]]
function BattleManager:PauseCIScene()
	------------ 暂停所有会暂停一切的场景 ------------
	for _, p in pairs(self:GetBData().ciScenes.pause) do
		-- 暂停逻辑
		p:pauseObj()
		-- 暂停action
		cc.Director:getInstance():getActionManager():pauseTarget(p)
		table.insert(self:GetBData().pauseActions.ciScene, p)
	end
	------------ 暂停所有会暂停一切的场景 ------------
end
--[[
恢复暂停ciScene
--]]
function BattleManager:ResumeCIScene()
	------------ 恢复所有会暂停一切的场景 ------------
	for _, p in pairs(self:GetBData().ciScenes.pause) do
		-- 暂停逻辑
		p:resumeObj()
		-- 恢复action
		cc.Director:getInstance():getActionManager():resumeTarget(p)
	end
	self:GetBData().pauseActions.ciScene = {}
	------------ 恢复所有会暂停一切的场景 ------------
end
--[[
暂停所有非中断性场景
--]]
function BattleManager:PauseNormalCIScene()
	------------ 暂停所有不会暂停一切的场景 ------------
	for _, p in pairs(self:GetBData().ciScenes.normal) do
		-- 暂停逻辑
		p:pauseObj()
		-- 暂停action
		cc.Director:getInstance():getActionManager():pauseTarget(p)
		table.insert(self:GetBData().pauseActions.normalCIScene, p)
	end
	------------ 暂停所有不会暂停一切的场景 ------------
end
--[[
恢复所有非中断性场景
--]]
function BattleManager:ResumeNormalCIScene()
	------------ 恢复所有不会暂停一切的场景 ------------
	for _, p in pairs(self:GetBData().ciScenes.normal) do
		-- 暂停逻辑
		p:resumeObj()
		-- 恢复action
		cc.Director:getInstance():getActionManager():resumeTarget(p)
	end
	self:GetBData().pauseActions.normalCIScene = {}
	------------ 恢复所有不会暂停一切的场景 ------------
end
--[[
暂停obj
@params ex table(objs)
--]]
function BattleManager:PauseBattleObjs(ex)
	------------ 暂停所有战斗物体 ------------
	ex = ex or {}
	for tag, o in orderedPairs(self:GetBData().battleObjs) do
		if nil == ex[tag] then
			o:pauseObj()
		end
	end

	for tag, o in orderedPairs(self:GetBData().restObjs) do
		if nil == ex[tag] then
			o:pauseObj()
		end
	end

	for tag, o in orderedPairs(self:GetBData().dustObjs) do
		if nil == ex[tag] and sp.AnimationName.die == o:getSpineAvatar():getCurrent() then
			o:pauseObj()
		end
	end

	for tag, w in orderedPairs(self:GetBData().weather) do
		w:pauseObj()
	end

	for tag, p in orderedPairs(self:GetBData().playerObj) do
		p:pauseObj()
	end
	------------ 暂停所有战斗物体 ------------

	------------ 暂停所有cocos2dx action ------------
	table.insert(self:GetBData().pauseActions.battle, cc.Director:getInstance():getActionManager():pauseAllRunningActions())
	------------ 暂停所有cocos2dx action ------------

	-- 恢复cocos场景的action
	cc.Director:getInstance():getActionManager():resumeTarget(cc.CSceneManager:getInstance():getRunningScene())
end
--[[
恢复暂停 主逻辑
--]]
function BattleManager:ResumeMainLogic()
	self:GetBData().isPause = false
end
--[[
恢复暂停
@params ex table(objs)
--]]
function BattleManager:ResumeBattleObjs(ex)
	------------ 恢复所有战斗物体 ------------
	ex = ex or {}
	for tag, o in orderedPairs(self:GetBData().battleObjs) do
		if nil == ex[tag] then
			o:resumeObj()
		end
	end

	for tag, o in orderedPairs(self:GetBData().restObjs) do
		if nil == ex[tag] then
			o:resumeObj()
		end
	end

	for tag, o in orderedPairs(self:GetBData().dustObjs) do
		if nil == ex[tag] and sp.AnimationName.die == o:getSpineAvatar():getCurrent() then
			o:resumeObj()
		end
	end

	for tag, w in orderedPairs(self:GetBData().weather) do
		w:resumeObj()
	end

	for tag, p in orderedPairs(self:GetBData().playerObj) do
		p:resumeObj()
	end
	------------ 恢复所有战斗物体 ------------

	------------ 恢复所有cocos2dx action ------------
	for i,v in ipairs(self:GetBData().pauseActions.battle) do
		cc.Director:getInstance():getActionManager():resumeTargets(v)
	end
	self:GetBData().pauseActions.battle = {}
	------------ 恢复所有cocos2dx action ------------
end
--[[
暂停主场景
--]]
function BattleManager:PauseMainScene()
	self:GetViewComponent():PauseScene()
end
--[[
恢复主场景
--]]
function BattleManager:ResumeMainScene()
	self:GetViewComponent():ResumeScene()
end
--[[
创建一个battleObj 在这里创建id信息
@params objInfo ObjectConstructorStruct 战斗物体构造参数
@params tagInfo ObjectTagStruct 战斗物体tag信息
@return obj BaseObj
--]]
function BattleManager:GetABattleObj(objInfo, tagInfo)
	local objClassName = 'battle.object.CardObject'
	local obj = __Require(objClassName).new({
		tag = tagInfo.tag,
		oname = tagInfo.oname,
		battleElementType = BattleElementType.BET_CARD,
		objInfo = objInfo
	})
	self:GetBData():addABattleObj(obj)

	return obj
end
--[[
创建一个召唤物
@params objInfo ObjectConstructorStruct 战斗物体构造参数
@params tagInfo ObjectTagStruct 战斗物体tag信息
@params beckonerTag int 召唤者tag
@params qteTapTime int qte点击次数
@return obj BaseObj
--]]
function BattleManager:GetABeckonObj(objInfo, tagInfo, beckonerTag, qteTapTime)
	local objClassName = ''
	if BattleObjectFeature.MELEE == objInfo.objectFeature then
		objClassName = 'battle.object.HealerBeckonObj'
	elseif BattleObjectFeature.REMOTE == objInfo.objectFeature then
		objClassName = 'battle.object.HealerBeckonObj'
	elseif BattleObjectFeature.HEALER == objInfo.objectFeature then
		objClassName = 'battle.object.HealerBeckonObj'
	else
		objClassName = 'battle.object.BaseBeckonObj'
	end
	local obj = __Require(objClassName).new({
		tag = tagInfo.tag,
		oname = tagInfo.oname,
		objInfo = objInfo,
		battleElementType = BattleElementType.BET_CARD,
		beckonerTag = beckonerTag,
		qteTapTime = qteTapTime
	})
	self:GetBData():addABeckonObj(obj)
	return obj
end
--[[
创建一发子弹
@params params table {
	otype int obj type
	ownerTag int 发射者tag
	targetTag int 目标tag
	oriLocation cc.p origin pos
	targetLocation cc.p origin pos
	damageData table 伤害信息
}
@return obj BaseBullet
--]]
function BattleManager:GetABullet(params)
	local obj = nil
	local tagInfo = self:GetBData():getBulletTagInfo(params)
	params.tag = tagInfo.tag
	params.oname = tagInfo.oname
	local className = 'battle.bullet.BaseBullet'

	if ConfigEffectBulletType.BASE == params.otype then

		className = 'battle.bullet.BaseBullet'

	elseif ConfigEffectBulletType.SPINE_EFFECT == params.otype then

		className = 'battle.bullet.SpineBaseBullet'

	elseif ConfigEffectBulletType.SPINE_PERSISTANCE == params.otype then

		className = 'battle.bullet.SpinePersistenceBullet'

	elseif ConfigEffectBulletType.SPINE_UFO_STRAIGHT == params.otype then

		className = 'battle.bullet.SpineUFOBullet'

	elseif ConfigEffectBulletType.SPINE_UFO_CURVE == params.otype then

		className = 'battle.bullet.SpineUFOCurveBullet'

	elseif ConfigEffectBulletType.SPINE_WINDSTICK == params.otype then

		className = 'battle.bullet.SpineWindStickBullet'

	elseif ConfigEffectBulletType.SPINE_LASER == params.otype then

		className = 'battle.bullet.SpineLaserBullet'
		
	else

	end
	-- print('$$$ bullet tag --> ', tagInfo.tag, params.otype, params.ownerTag, params.targetTag)
	obj = __Require(className).new(params)
	if obj then
		self:GetBData():addABullet(obj)
	end
	return obj
end
--[[
注册事件
@params name string 事件名称
@params obj obj 注册物体
@params callback function 回调
--]]
function BattleManager:AddObjEvent(ename, o, callback)
	if nil == self.objEvents[ename] then
		self.objEvents[ename] = {}
	end
	table.insert(self.objEvents[ename], {tag = o:getOTag(), callback = callback})
end
--[[
注销事件
@params name string 事件名称
@params obj obj 注册物体
--]]
function BattleManager:RemoveObjEvent(ename, o)
	if nil == self.objEvents[ename] then
		funLog(Logger.INFO,'can not find obj event -> ' .. ename)
	else
		local targetTag = o:getOTag()
		local callbackInfo = nil
		for i = #self.objEvents[ename], 1, -1 do
			callbackInfo = self.objEvents[ename][i]
			if targetTag == callbackInfo.tag then
				table.remove(self.objEvents[ename], i)
			end
		end
	end
end
--[[
发送事件
@params ename string
@params ... 
--]]
function BattleManager:SendObjEvent(ename, ...)
	if nil ~= self.objEvents[ename] then
		local args = unpack({...})
		local callbackInfo = nil
		for i = #self.objEvents[ename], 1, -1 do
			callbackInfo = self.objEvents[ename][i]
			xTry(function()
				callbackInfo.callback(args)
			end,__G__TRACKBACK__)
		end
	end
end
--[[
退出游戏
--]]
function BattleManager:ExitGame()
	if nil == self.bdata then return end
	self:SetGState(GState.OVER)
	-- 停掉定时器
	self:UnregisterMainUpdate()
	-- 移除所有obj 因为obj的view是在转场时释放的 可能会存在缓存的view
	local bdata = self:GetBData()
	bdata:destroy()
	self.bdata = nil

	self.objEvents = {}
	self.globalEvents = {}

	-- SpineCache(SpineCacheName.BATTLE):clearCache()

	cc.Director:getInstance():getScheduler():setTimeScale(1)

	------------ 停掉录像 ------------
	BattleUtils.StopScreenRecord()
	------------ 停掉录像 ------------
end
--[[
强制退出战斗
--]]
function BattleManager:QuitBattleForce()
	self:BackToPrevious()
end
--[[
杀死战斗
--]]
function BattleManager:KillBattle()
	if true == self:IsBattleSceneLoadingOver() then
		-- 加载结束以后 直接杀掉自己 讲界面跳转交给外部逻辑
		self:ExitGame()
	else
		-- TODO 加载未结束
		self:ExitGame()
	end
end
--[[
重开特定的一关
阵容是不变的
@params stageId int 关卡id
@params enemyInfo table 敌方阵容
--]]
function BattleManager:RestartGame(stageId)
	-- 初始化新数据
	self:GetOriBattleConstructData().stageId = stageId
	----- network command -----
	local function callback(responseData)
		self:ExitGame()
		self:StartGameAndLoadingResources()
	end

	self.BNetworkMediator:ReadyToEnterBattle(self:GetBData():getBattleConstructor(), callback)
	----- network command -----
end
--[[
obj状态改变回调
@params o obj 战斗物体
@params ostate OState 变化的目标状态
--]]
function BattleManager:ObjStateChangedHandler(o, ostate)
	
end
--[[
放弃买活
--]]
function BattleManager:CancelRescue()
	self:GameOver(BattleResult.BR_FAIL)
end
--[[
确定买活 全体复活
--]]
function BattleManager:RescueAllFriend()
	-- 买活判断
	local costConsumeConfig = CommonUtils.GetBattleBuyReviveCostConfig(
		self:GetBData():getCurStageId(),
		self:GetBData():getQuestBattleType(),
		self:GetBData():getNextBuyRevivalTime()
	)
	local costGoodsId = checkint(costConsumeConfig.consume)
	local costGoodsAmount = checkint(costConsumeConfig.consumeNum)

	local canBuyRevivalFree = self:GetBData():canBuyRevivalFree()
	if canBuyRevivalFree then
		costGoodsAmount = 0
	end

	local goodsAmount = gameMgr:GetAmountByIdForce(costGoodsId)
	if (0 ~= costGoodsAmount) and (costGoodsAmount > goodsAmount) then
		if GAME_MODULE_OPEN.NEW_STORE and checkint(costGoodsId) == DIAMOND_ID then
			app.uiMgr:showDiamonTips(nil, true)
		else
			local goodsConfig = CommonUtils.GetConfig('goods', 'goods', costGoodsId)
			uiMgr:ShowInformationTips(string.format(__('%s不足'), goodsConfig.name))
		end
		return
	end

	----- network command -----
	local function callback(responseData)

		-- 处理数据
		self:GetBData():addBuyRevivalTime(1)

		-- 扣除免费买活次数
		self:GetBData():costBuyRevivalFree()

		-- 扣除消耗
		CommonUtils.DrawRewards({
			{goodsId = costGoodsId, num = -costGoodsAmount}
		})

		-- 移除买活界面
		self:GetViewComponent():RemoveUILayerByTag(BUY_REVIVAL_LAYER_TAG)

		local reviveBegin = function ()

			for i = #self:GetBData().sortDustObjs.friend, 1, -1 do
				local obj = self:GetBData().sortDustObjs.friend[i]

				-- 创建一个复活spine动画
				local reviveSpine = SpineCache(SpineCacheName.BATTLE):createWithName('hurt_18')
				reviveSpine:setPosition(obj:getLocation().po)
				self:GetBattleRoot():addChild(reviveSpine, obj.view.viewComponent:getLocalZOrder())
				reviveSpine:setAnimation(0, 'idle', false)

				reviveSpine:registerSpineEventHandler(
					function (event)
						if sp.CustomEvent.cause_effect == event.eventData.name then
							obj:revive(1, 0)
						end
					end,
					sp.EventType.ANIMATION_EVENT
				)

				reviveSpine:registerSpineEventHandler(
					function (event)
						-- 移除自己
						reviveSpine:runAction(cc.RemoveSelf:create())
					end,
					sp.EventType.ANIMATION_COMPLETE
				)
			end

		end

		local reviveMiddle = function ()
			-- 重置所有obj站位
			for i = #self:GetBData().sortBattleObjs.friend, 1, -1 do
				local obj = self:GetBData().sortBattleObjs.friend[i]
				obj:resetLocation()
			end

			for i = #self:GetBData().sortBattleObjs.enemy, 1, -1 do
				local obj = self:GetBData().sortBattleObjs.enemy[i]
				obj:resetLocation()
			end
		end

		local reviveEnd = function ()
			-- 重置游戏状态 游戏继续开始
			self:SetGState(GState.START)
			self:SetBattleTouchEnable(true)
		end

		local scene = __Require('battle.miniGame.RescueAllFriendScene').new({
			callbacks = {
				reviveBegin = reviveBegin,
				reviveMiddle = reviveMiddle,
				reviveEnd = reviveEnd,
			}
		})
		self:GetViewComponent():addChild(scene, BATTLE_E_ZORDER.CI)
	end
	----- network command -----
	local serverCommand = self:GetBData():getBattleConstructor():GetServerCommand()
	self.BNetworkMediator:CommonNetworkRequest(
		serverCommand.buyCheatRequestCommand,
		serverCommand.buyCheatResponseSignal,
		serverCommand.buyCheatRequestData,
		callback
	)
end
--[[
进入后台
--]]
function BattleManager:AppEnterBackground()
	------------ 弹出暂停界面 ------------
	-- 判断游戏状态 如果结束直接不处理
	local returnGState = {
		[GState.READY] = true,
		[GState.OVER] = true,
		[GState.BLOCK] = true,
		[GState.SUCCESS] = true,
		[GState.FAIL] = true
	}
	if true == returnGState[self:GetGState()] then return end

	-- 判断一些界面是否存在 如果存在也不弹
	if nil ~= self:GetViewComponent() then
		if nil ~= self:GetViewComponent():getChildByTag(PAUSE_SCENE_TAG) then
			return
		end

		self:PauseGame()
	end
	------------ 弹出暂停界面 ------------
end
--[[
进入前台
--]]
function BattleManager:AppEnterForeground()

end
------------------------------------------------------------------------------------------------------
-- battle control end --
------------------------------------------------------------------------------------------------------

---------------------------------------------------
-- view control begin --
---------------------------------------------------
--[[
刷新波数文字
@params currentWave int 当前波数
@params totalWave int 总波数
--]]
function BattleManager:RefreshWaveInfo(currentWave, totalWave)
	local waveLabel = self:GetViewComponent().viewData.waveLabel
	local waveIcon = self:GetViewComponent().viewData.waveIcon

	-- 刷新波数文字
	waveLabel:setString(string.format('%d/%d', currentWave, totalWave))
	-- waveLabel:setString(string.format('%d/%d', 88, 88))
	-- 刷新波数icon
	display.commonUIParams(waveIcon, {po = cc.p(
		waveLabel:getPositionX() - waveLabel:getContentSize().width,
		waveLabel:getPositionY() + 4
	)})
end
--[[
进入下一波 进行一些显示
@params params table {
	wave int 当前波数
	callback function 文字结束后的回调
}
--]]
function BattleManager:ShowNextWave(params)
	self:ShowNextWaveClearInfo()
	self:ShowNextWaveRemind(params)
end
--[[
显示下一波文字 boss文字
@params params table {
	wave int 当前波数
	callback function 文字结束后的回调
}
--]]
function BattleManager:ShowNextWaveRemind(params)
	if self:GetBData().nextWaveTips.hasBoss then
		self:ShowBossAppear()
	end
	local uiLayer = self:GetViewComponent().viewData.uiLayer
	local roundBg = display.newImageView(_res('ui/battle/battle_bg_black.png'), -display.width * 0.5, display.height * 0.5, {scale9 = true, size = cc.size(display.width, 144)})
	uiLayer:addChild(roundBg, BATTLE_E_ZORDER.UI_EFFECT)

	local plate = display.newNSprite(_res('ui/battle/battle_bg_switch.png'), display.width * 0.5, display.height * 0.5)
	uiLayer:addChild(plate, BATTLE_E_ZORDER.UI_EFFECT)
	plate:setScale(0)

	local knifeDeltaP = cc.p(50, -50)
	local knife = display.newNSprite(_res('ui/battle/battle_ico_switch_1.png'), display.width * 0.5 - knifeDeltaP.x, display.height * 0.5 - knifeDeltaP.y)
	uiLayer:addChild(knife, BATTLE_E_ZORDER.UI_EFFECT)
	knife:setOpacity(0)

	local forkDeltaP = cc.p(-50, -50)
	local fork = display.newNSprite(_res('ui/battle/battle_ico_switch_2.png'), display.width * 0.5 - forkDeltaP.x, display.height * 0.5 - forkDeltaP.y)
	uiLayer:addChild(fork, BATTLE_E_ZORDER.UI_EFFECT)
	fork:setOpacity(0)

	local labelBg = display.newNSprite(_res('ui/battle/battle_bg_switch_word.png'), 0, 0)
	display.commonUIParams(labelBg, {ap = cc.p(0, 0.5), po = cc.p(display.width * 0.5 - labelBg:getContentSize().width * 0.5, display.height * 0.5)})
	uiLayer:addChild(labelBg, BATTLE_E_ZORDER.UI_EFFECT)
	labelBg:setScaleX(0)

	-- local waveLabel = display.newNSprite(_res(params.wavePath), display.width * 0.5, display.height * 0.5)
	local waveStr = ''
	if 1 == params.wave then
		waveStr = __('战斗开始')
	else
		waveStr = string.format(__('第%s回合'), CommonUtils.GetChineseNumber(checkint(params.wave)))
	end
	local waveLabel = display.newLabel(display.width * 0.5, display.height * 0.5,
		{text = waveStr, fontSize = 32, color = '#ffffff', ttf = true, font = TTF_GAME_FONT, outline = '#2e1e14'})
	uiLayer:addChild(waveLabel, BATTLE_E_ZORDER.UI_EFFECT)
	waveLabel:setOpacity(0)

	local bgActionSeq = cc.Sequence:create(
		cc.MoveBy:create(0.15, cc.p(display.width, 0)),
		cc.DelayTime:create(1.15),
		cc.FadeTo:create(0.2, 0),
		cc.RemoveSelf:create())
	roundBg:runAction(bgActionSeq)

	local plateActionSeq = cc.Sequence:create(
		cc.DelayTime:create(0.15),
		cc.ScaleTo:create(0.1, 1),
		cc.DelayTime:create(1.05),
		cc.FadeTo:create(0.2, 0),
		cc.RemoveSelf:create())
	plate:runAction(plateActionSeq)

	local knifeActionSeq = cc.Sequence:create(
		cc.DelayTime:create(0.2),
		cc.Spawn:create(
			cc.MoveBy:create(0.1, knifeDeltaP),
			cc.FadeTo:create(0.1, 255)),
		cc.DelayTime:create(1),
		cc.FadeTo:create(0.2, 0),
		cc.RemoveSelf:create())
	knife:runAction(knifeActionSeq)

	local forkActionSeq = cc.Sequence:create(
		cc.DelayTime:create(0.25),
		cc.Spawn:create(
			cc.MoveBy:create(0.1, forkDeltaP),
			cc.FadeTo:create(0.1, 255)),
		cc.DelayTime:create(0.95),
		cc.FadeTo:create(0.2, 0),
		cc.RemoveSelf:create())
	fork:runAction(forkActionSeq)

	local labelBgActionSeq = cc.Sequence:create(
		cc.DelayTime:create(0.35),
		cc.EaseSineOut:create(cc.ScaleTo:create(0.15, 1, 1)),
		cc.DelayTime:create(0.8),
		cc.FadeTo:create(0.2, 0),
		cc.RemoveSelf:create())
	labelBg:runAction(labelBgActionSeq)

	local labelActionSeq = cc.Sequence:create(
		cc.DelayTime:create(0.35),
		cc.FadeTo:create(0.2, 255),
		cc.DelayTime:create(0.75),
		cc.FadeTo:create(0.2, 0),
		cc.CallFunc:create(function ()
			if params.callback then
				params.callback()
			end
		end),
		cc.RemoveSelf:create())
	waveLabel:runAction(labelActionSeq)

end
--[[
显示下一波过关条件
--]]
function BattleManager:ShowNextWaveClearInfo()
	self:GetViewComponent():AutoShowStageClearView(10)
end
--[[
显示boss来袭
@params params table {
	wavePath string 显示的文字图片路径
	callback function 文字结束后的回调
}
--]]
function BattleManager:ShowBossAppear(params)
	local waringBg = display.newNSprite(_res('ui/battle/battle_bg_warning.png'), display.width * 0.5, display.height * 0.5)
	local waringBgSize = waringBg:getContentSize()
	waringBg:setScaleX(display.width / waringBgSize.width)
	waringBg:setScaleY(display.height / waringBgSize.height)
	self:GetViewComponent().viewData.uiLayer:addChild(waringBg)
	waringBg:setOpacity(0)
	local waringActionSeq = cc.Sequence:create(
		cc.Repeat:create(cc.Sequence:create(
			cc.FadeTo:create(0.5, 255),
			cc.DelayTime:create(0.25),
			cc.FadeTo:create(0.5, 0)
		), 3),
		cc.RemoveSelf:create()
	)
	waringBg:runAction(waringActionSeq)
end
--[[
显示释放主角技遮罩
--]]
function BattleManager:ShowCastPlayerSkillCover()
	local waringBg = display.newNSprite(_res('ui/battle/battle_bg_warning.png'), display.width * 0.5, display.height * 0.5)
	waringBg:setColor(cc.c3b(0, 0, 0))
	local waringBgSize = waringBg:getContentSize()
	waringBg:setScaleX(display.width / waringBgSize.width)
	waringBg:setScaleY(display.height / waringBgSize.height)
	self:GetViewComponent().viewData.uiLayer:addChild(waringBg)
	waringBg:setOpacity(0)
	local waringActionSeq = cc.Sequence:create(
		cc.FadeTo:create(0.5, 255),
		cc.DelayTime:create(2.5),
		cc.FadeTo:create(0.5, 0),
		cc.RemoveSelf:create()
	)
	waringBg:runAction(waringActionSeq)
end
--[[
显示ci
@params params table
@return view layer ci场景
--]]
function BattleManager:ShowCIScene(params)
	local scene = __Require('battle.miniGame.CutinScene').new(params)
	self:GetViewComponent():addChild(scene, BATTLE_E_ZORDER.CI)
	self:GetBData().ciScenes.pause[tostring(params.tag)] = scene
	return scene
end
--[[
调出boss弱点层
@params params table
@return view layer boss弱点场景
--]]
function BattleManager:ShowBossWeak(params)
	local scene = __Require('battle.miniGame.BossWeakScene').new(params)
	self:GetViewComponent():addChild(scene, BATTLE_E_ZORDER.CI)
	self:GetBData().ciScenes.normal[tostring(params.tag)] = scene
	return scene
end
--[[
调出boss ci
@params params table
@return view layer ci场景
--]]
function BattleManager:ShowBossCIScene(params)
	local scene = __Require('battle.miniGame.BossCutinScene').new(params)
	self:GetViewComponent():addChild(scene, BATTLE_E_ZORDER.CI)
	self:GetBData().ciScenes.pause[tostring(params.tag)] = scene
	return scene
end
--[[
调出小游戏场景
@params params table
@return view layer boss弱点场景
--]]
function BattleManager:ShowMiniGame(params)
	local className = 'LineConnectGame'
	params.time = 5
	local scene = __Require('battle.miniGame.' .. className).new(params)
	self:GetViewComponent():addChild(scene, BATTLE_E_ZORDER.CI)
	self:GetBData().ciScenes.pause[tostring(params.tag)] = scene
	return scene
end
--[[
换波场景
@params params table
--]]
function BattleManager:ShowWaveTransition(params)
	local scene = __Require('battle.miniGame.WaveTransitionScene').new(params)
	self:GetViewComponent():addChild(scene, BATTLE_E_ZORDER.CI)
	return scene
end
--[[
显示游戏成功
@params responseData table 服务器返回信息
--]]
function BattleManager:ShowGameSuccess(responseData)
	if self:NeedShowActAfterGameOver(BattleResult.BR_SUCCESS) then
		local function callback()
			self:CreateBattleSuccessView(responseData)	
		end
		self:ShowActAfterGameOver(callback, BattleResult.BR_SUCCESS, responseData)
	else
		self:CreateBattleSuccessView(responseData)
	end
end
--[[
显示游戏失败
@params responseData table 服务器返回信息
--]]
function BattleManager:ShowGameFail(responseData)
	if self:NeedShowActAfterGameOver(BattleResult.BR_FAIL) then
		local function callback()
			self:CreateBattleFailView(responseData)	
		end
		self:ShowActAfterGameOver(callback, BattleResult.BR_FAIL, responseData, responseData)
	else
		self:CreateBattleFailView(responseData)
	end
end
--[[
创建战斗成功界面
@params responseData table 服务器返回信息
--]]
function BattleManager:CreateBattleSuccessView(responseData)
	local className = 'battle.view.BattleSuccessView'
	local p_ = {}

	-- 结算类型
	local viewType = self:GetBattleResultViewType()

	if self:IsShareBoss() then

		className = 'battle.view.ShareBossSuccessView'

		p_ = {
			totalTime = responseData.requestData.passTime,
			totalDamage = responseData.requestData.totalDamage
		}
		
	elseif ConfigBattleResultType.POINT_HAS_RESULT == viewType or
		ConfigBattleResultType.POINT_NO_RESULT == viewType then

		className = 'battle.view.PointSettleView'

		p_ = {
			battleResult = BattleResult.BR_SUCCESS
		}

	elseif ConfigBattleResultType.NO_RESULT_DAMAGE_COUNT == viewType then

		className = 'battle.view.ShareBossSuccessView'

		p_ = {
			totalTime = responseData.requestData.passTime,
			totalDamage = checknumber(responseData.totalDamage)
		}

	end

	-- 三星条件
	local cleanCondition = nil
	if self:GetBData():getBattleConstructData().canRechallenge then
		cleanCondition = self:GetBData():getBattleConstructData().cleanCondition
	end

	local showMessage = QuestBattleType.ROBBERY == self:GetBData():getBattleConstructData().questBattleType

	local viewParams = {
		viewType = viewType,
		cleanCondition = cleanCondition,
		showMessage = showMessage,
		canRepeatChallenge = false,
		teamData = self:GetBData():getFriendMembers(1),
		trophyData = responseData
	}

	for k,v in pairs(p_) do
		viewParams[k] = v
	end

	local layer = __Require(className).new(viewParams)
	display.commonUIParams(layer, {ap = cc.p(0, 0), po = cc.p(0, 0)})
	self:GetViewComponent():AddUILayer(layer)

	layer:setTag(GAME_RESULT_LAYER_TAG)
end
--[[
创建战斗失败界面
@params responseData table 服务器返回信息
--]]
function BattleManager:CreateBattleFailView(responseData)
	local className = 'battle.view.BattleFailView'
	local p_ = {}

	-- 结算类型
	local viewType = ConfigBattleResultType.NO_EXP
	local questBattleType = self:GetQuestBattleType()
	local configResultType = self:GetBattleResultViewType()

	if QuestBattleType.SEASON_EVENT == questBattleType or 
		QuestBattleType.SAIMOE == questBattleType then

		viewType = self:GetBattleResultViewType()

	end

	if ConfigBattleResultType.POINT_NO_RESULT == configResultType or
		ConfigBattleResultType.NO_RESULT_DAMAGE_COUNT == configResultType then

		viewType = configResultType

	end

	if self:IsShareBoss() then

		className = 'battle.view.ShareBossSuccessView'

		p_ = {
			totalTime = responseData.requestData.passTime,
			totalDamage = responseData.requestData.totalDamage
		}

	elseif ConfigBattleResultType.POINT_HAS_RESULT == viewType or
		ConfigBattleResultType.POINT_NO_RESULT == viewType then

		className = 'battle.view.PointSettleView'		

		p_ = {
			battleResult = BattleResult.BR_FAIL
		}

	elseif ConfigBattleResultType.NO_RESULT_DAMAGE_COUNT == viewType then

		className = 'battle.view.ShareBossSuccessView'

		p_ = {
			totalTime = responseData.requestData.passTime,
			totalDamage = checknumber(responseData.totalDamage)
		}

	end

	local viewParams = {
		viewType = viewType,
		cleanCondition = nil,
		showMessage = false,
		canRepeatChallenge = false,
		teamData = self:GetBData():getFriendMembers(1),
		trophyData = responseData
	}

	for k,v in pairs(p_) do
		viewParams[k] = v
	end

	local layer = __Require(className).new(viewParams)
	display.commonUIParams(layer, {ap = cc.p(0, 0), po = cc.p(0, 0)})
	self:GetViewComponent():AddUILayer(layer)

	layer:setTag(GAME_RESULT_LAYER_TAG)
end
--[[
显示买活界面
--]]
function BattleManager:ShowBuyRevival()
	local layer = __Require('battle.view.BattleBuyRevivalView').new({
		stageId = self:GetBData():getCurStageId(),
		questBattleType = self:GetBData():getQuestBattleType(),
		buyRevivalTime = self:GetBData():getBattleConstructData().buyRevivalTime,
		buyRevivalTimeMax = self:GetBData():getBattleConstructData().buyRevivalTimeMax
	})
	layer:setTag(BUY_REVIVAL_LAYER_TAG)
	display.commonUIParams(layer, {ap = cc.p(0, 0), po = cc.p(0, 0)})
	self:GetViewComponent():AddUILayer(layer)

	for k,btn in pairs(layer.actionButtons) do
		display.commonUIParams(btn, {cb = handler(self, self.ButtonActions)})
	end
end
--[[
显示伤害数字
@params damageData table {
	damage number 伤害数字
	targetTag int 目标tag
	attackerTag int 攻击者tag
	isCritical bool 是否暴击
	casterTag int 施法者tag
	skillInfo table 技能信息
}
@params worldP cc.p 世界坐标
@params towards bool 朝向 是否向右
--]]
function BattleManager:ShowDamageNumber(damageData, worldP, towards)
	-- 伤害数字 分三种 暴击 治疗 普通
	local colorPath = 'white'
	local fontSize = 50
	local actionSeq = nil
	local fps = 30
	local parentNode = self:GetBattleRoot()
	local pos = parentNode:convertToNodeSpace(worldP)
	local sign = towards and -1 or 1

	local zorder = BATTLE_E_ZORDER.DAMAGE_NUMBER
	local attackerTag = damageData.healerTag or damageData.attackerTag
	if nil ~= attackerTag and self.connectSkillHighlightEvent and self.connectSkillHighlightEvent:IfCausedHighlightByCasterTag(attackerTag) then
		zorder = zorder + self:GetFixedHighlightZOrder()
	end

	if nil ~= damageData.healerTag then

		if true == damageData.isCritical then
			fontSize = 80
		end

		-- 治疗数值
		colorPath = 'green'

		-- 为治疗错开一定的横坐标
		pos.x = pos.x + math.random(-35, 35)

		local deltaP1 = cc.p(0, 50 + math.random(40))
		local actionP1 = cc.pAdd(pos, deltaP1)
		local actionP2 = cc.pAdd(actionP1, cc.p(0, deltaP1.y * 0.5))

		actionSeq = cc.Sequence:create(
			cc.EaseSineIn:create(
				cc.Spawn:create(
					cc.ScaleTo:create(9 / fps, 1),
					cc.MoveTo:create(9 / fps, actionP1))
			),
			cc.Spawn:create(
				cc.Sequence:create(
					cc.MoveTo:create(19 / fps, actionP2),
					cc.MoveTo:create(11 / fps, pos)),
				cc.Sequence:create(
					cc.DelayTime:create(13 / fps),
					cc.ScaleTo:create(17 / fps, 0)),
				cc.Sequence:create(
					cc.DelayTime:create(19 / fps),
					cc.FadeTo:create(11 / fps, 0))
			),
			cc.RemoveSelf:create()
		)

	elseif true == damageData.isCritical then

		-- 暴击数值
		colorPath = 'orange'
		fontSize = 70
		local deltaP1 = cc.p(60 + math.random(40), 60 + math.random(40))
		local actionP1 = cc.p(pos.x + sign * deltaP1.x, pos.y + deltaP1.y)
		local actionP2 = cc.p(pos.x + sign * deltaP1.x * 2, pos.y + deltaP1.y * 0.25)
		local bezierConf2 = {
			actionP1,
			cc.p(actionP1.x + sign * deltaP1.x * 0.5, actionP1.y + deltaP1.y * 0.25),
			actionP2
		}

		actionSeq = cc.Sequence:create(
			cc.EaseSineOut:create(cc.Spawn:create(
				cc.ScaleTo:create(6 / fps, 1),
				cc.MoveTo:create(6 / fps, actionP1))
			),
			cc.Spawn:create(
				cc.BezierTo:create(33 / fps, bezierConf2),
				cc.Sequence:create(
					cc.DelayTime:create(22 / fps),
					cc.Spawn:create(
						cc.ScaleTo:create(11 / fps, 0),
						cc.FadeTo:create(11 / fps, 0)
					)
				)
			),
			cc.RemoveSelf:create()
		)

	else

		-- 普通伤害数值
		local deltaP1 = cc.p(15 + math.random(30), 15 + math.random(30))
		local actionP1 = cc.p(pos.x + sign * deltaP1.x, pos.y + deltaP1.y)
		local actionP2 = cc.p(pos.x + sign * deltaP1.x * 2, pos.y)
		local bezierConf2 = {
			actionP1,
			cc.p(actionP1.x + sign * deltaP1.x, actionP1.y + deltaP1.y),
			actionP2
		}

		actionSeq = cc.Sequence:create(
			cc.Spawn:create(
				cc.ScaleTo:create(5 / fps, 1),
				cc.MoveTo:create(5 / fps, actionP1)),
			-- cc.EaseOut:create(cc.Spawn:create(
			-- 	cc.ScaleTo:create(5 / fps, 1),
			-- 	cc.MoveTo:create(5 / fps, actionP1)),
			-- 	1
			-- ),
			cc.Spawn:create(
				cc.BezierTo:create(34 / fps, bezierConf2),
				cc.Sequence:create(
					cc.DelayTime:create(22 / fps),
					cc.Spawn:create(
						cc.ScaleTo:create(12 / fps, 0),
						cc.FadeTo:create(12 / fps, 0)
					)
				)
			),
			cc.RemoveSelf:create()
		)

	end

	local damageLabel = CLabelBMFont:create(
		string.format('%d', math.ceil(damageData:GetDamageValue())),
		string.format('font/battle_font_%s.fnt', colorPath))
	damageLabel:setBMFontSize(fontSize)
	damageLabel:setAnchorPoint(cc.p(0.5, 0.5))
	damageLabel:setPosition(pos)
	parentNode:addChild(damageLabel, zorder)

	-- 初始化动画状态
	damageLabel:setScale(0)
	if actionSeq then
		damageLabel:runAction(actionSeq)
	end

end
--[[
刷新时间
@params leftTime int 剩余秒数
--]]
function BattleManager:RefreshTimeLabel(leftTime)
	local m = math.floor(leftTime / 60)
	local s = math.floor(leftTime - m * 60)
    if self:GetViewComponent().viewData then
        self:GetViewComponent().viewData.battleTimeLabel:setString(string.format('%d:%02d', m, s))
    end
end
--[[
添加连携技按钮
--]]
function BattleManager:InitConnectButton()
	local x = 1
	local obj = nil
	local otag = nil
	local scale = 1

	self.connectButtonsIndex = {}

	-- 移除一次过期的连携技按钮
	local t = {}
	for otag_, btns in pairs(self:GetViewComponent().viewData.connectButtons) do
		for sid, btn in pairs(btns) do
			obj = self:IsObjAliveByTag(otag_)
			if nil == obj then
				-- 移除按钮
				btn:setVisible(false)
				btn:runAction(cc.RemoveSelf:create())
				self:GetViewComponent().viewData.connectButtons[otag_][sid] = nil
			else
				table.insert(t, btn)
			end
		end
	end

	-- 排序
	table.sort(t, function (a, b)
		return a:getPositionX() > b:getPositionX()
	end)

	for i,v in ipairs(t) do
		local btnSize = cc.size(v:getContentSize().width * scale, v:getContentSize().height * scale)
		v:setPositionX(display.SAFE_R - 20 - (btnSize.width * 0.5) - (btnSize.width + 25) * (x - 1))

		local index = #self.connectButtonsIndex + 1
		self.connectButtonsIndex[index] = connectButton

		x = x + 1
	end

	-- 创建友军的连携按钮
	for i = #self:GetBData().sortBattleObjs.friend, 1, -1 do
		obj = self:GetBData().sortBattleObjs.friend[i]
		otag = obj:getOTag()

		for i, sid in ipairs(obj.castDriver:GetConnectSkills()) do
			if nil == self:GetConnectButton(otag, checkint(sid)) then
				local connectButton = __Require('battle.view.ConnectButton').new({
					objTag = otag,
					debugTxt = obj:getOCardName(),
					skillId = checkint(sid),
					callback = handler(self, self.ConnectButtonCallback)
				})
				connectButton:setTag(i)
				local btnSize = cc.size(connectButton:getContentSize().width * scale, connectButton:getContentSize().height * scale)
				display.commonUIParams(connectButton, {
					po = cc.p(display.SAFE_R - 20 - (btnSize.width * 0.5) - (btnSize.width + 25) * (x - 1), 20 + btnSize.height * 0.5)})
				self:GetViewComponent().viewData.uiLayer:addChild(connectButton)

				if nil == self:GetViewComponent().viewData.connectButtons[tostring(otag)] then
					self:GetViewComponent().viewData.connectButtons[tostring(otag)] = {}
				end
				local index = #self.connectButtonsIndex + 1
				self:GetViewComponent().viewData.connectButtons[tostring(otag)][tostring(sid)] = connectButton
				self.connectButtonsIndex[index] = connectButton

				connectButton:RefreshButton(obj:getEnergy():ObtainVal(), obj:canAct(), obj:getState(), obj:isSilent(), obj:isEnchanting())

				x = x + 1
			end
		end
	end
end
--[[
设置连携技按钮因复仇而可用的状态
@params tag int obj tag
@params skillId int 技能id
--]]
function BattleManager:EnableConnectButtonByRevenge(tag, skillId)
	if tag >= ENEMY_TAG then return end
	local btns = self:GetViewComponent().viewData.connectButtons[tostring(tag)]
	btns[tostring(skillId)]:EnableConnectButtonByRevenge()
end
--[[
获取连携技按钮
@params tag int 战斗物体tag
@params skillId int 技能id
@return _ ConnectButton 连携技按钮对象
--]]
function BattleManager:GetConnectButton(tag, skillId)
	if tag < ENEMY_TAG then
		local btns = self:GetViewComponent().viewData.connectButtons[tostring(tag)]
		if nil ~= btns then
			return btns[tostring(skillId)]
		end
	end
	return nil
end
--[[
根据右向左的序号获取连携技按钮
@params index int 序号
@return _ ConnectButton 连携技按钮对象
--]]
function BattleManager:GetConnectButtonByIndex(index)
	return self.connectButtonsIndex[index]
end
--[[
设置触摸屏蔽
@params enable bool 设置是否可触摸
--]]
function BattleManager:SetBattleTouchEnable(enable)
	self:GetViewComponent().viewData.eaterLayer:setVisible(not enable)
end
--[[
全屏是否响应触摸
@return _ bool 是否响应触摸
--]]
function BattleManager:IsBattleTouchEnable()
	return not self:GetViewComponent().viewData.eaterLayer:isVisible()
end
--[[
发射子弹
@params bulletData ObjectSendBulletData 发射子弹传参
--]]
function BattleManager:sendBullet(bulletData)
	local parent = self:GetBattleRoot()
	local zorder = BATTLE_E_ZORDER.BULLET
	-- 处理层级
	if ConfigEffectCauseType.SCREEN == bulletData.causeType then

		-- 全屏 只存在顶部和底部 加到战斗root上
		zorder = bulletData.bulletZOrder < 0 and 1 or BATTLE_E_ZORDER.BULLET
		if bulletData.needHighlight then
			zorder = zorder + self:GetFixedHighlightZOrder()
		end

	elseif ConfigEffectBulletType.SPINE_EFFECT == bulletData.otype and ConfigEffectCauseType.POINT == bulletData.causeType then

		local target = nil
		if true == bulletData.targetDead then
			target = self:GetDeadObjByTag(bulletData.targetTag)
		else
			target = self:IsObjAliveByTag(bulletData.targetTag)
		end

		if nil ~= target then
			-- 修正父节点
			parent = target.view.viewComponent
			-- 指向 加到物体身上 只存在顶部和底部
			zorder = bulletData.bulletZOrder < 0 and -1 or BATTLE_E_ZORDER.BULLET
			-- 修正指向性的子弹位置
			local fixedPosInView = target.view.viewComponent:convertUnitPosToRealPos(bulletData.fixedPos)
			-- bulletData.targetLocation = parent:convertToNodeSpace(self:GetBattleRoot():convertToWorldSpace(bulletData.targetLocation))
			bulletData.targetLocation = fixedPosInView
		end

	elseif ConfigEffectCauseType.SINGLE == bulletData.causeType then

		-- 范围连接点 真实zorder
		zorder = self:GetZorderInBattle(bulletData.targetLocation)
		if bulletData.needHighlight then
			zorder = zorder + self:GetFixedHighlightZOrder()
		end

	elseif ConfigEffectBulletType.SPINE_UFO_STRAIGHT == bulletData.otype or
		ConfigEffectBulletType.SPINE_UFO_CURVE == bulletData.otype or
		ConfigEffectBulletType.SPINE_LASER == bulletData.otype or
		ConfigEffectBulletType.SPINE_WINDSTICK == bulletData.otype then

		-- 投掷物 转换一次原始坐标
		bulletData.oriLocation = parent:convertToNodeSpace(bulletData.oriLocation)
		if bulletData.needHighlight then
			zorder = zorder + self:GetFixedHighlightZOrder()
		end

	else

	end

	local bullet = self:GetABullet(bulletData)
	parent:addChild(bullet.view.viewComponent, zorder)
	bullet:awake()
end
--[[
展示一段表演
@params callback function 表演结束的回调
@params r BattleResult 战斗结果
@params responseData table 服务器返回信息
--]]
function BattleManager:ShowActAfterGameOver(callback, r, responseData)
	-- 判断类型
	if QuestBattleType.UNION_BEAST == self:GetBData():getBattleConstructData().questBattleType then
		-- 创建神兽吃能量场景
		local beastId = self:GetBData():getBattleConstructor():GetUnionBeastId()
		local babyEnergyLevel = checkint(responseData.energyLevel)
		local deltaEnergy = checkint(responseData.energy)
		if 0 < babyEnergyLevel and 0 ~= beastId then
			local scene = __Require('battle.miniGame.UnionBeastBabyEatScene').new({
				beastId = beastId,
				energyLevel = babyEnergyLevel,
				deltaEnergy = deltaEnergy,
				callback = callback
			})
			self:GetViewComponent():addChild(scene, BATTLE_E_ZORDER.CI)
		else
			callback()
		end
	end
end
--[[
根据过关条件数据刷新过关条件展示
@params stageCompleteInfo StageCompleteSturct 过关配置信息
--]]
function BattleManager:RefreshWaveClearInfo(stageCompleteInfo)
	local waveClearDescr = self:GetStageCompleteDescrByInfo(stageCompleteInfo)
	self:GetViewComponent():RefreshBattleClearTargetDescr(waveClearDescr)

	if ConfigStageCompleteType.ALIVE == stageCompleteInfo.completeType then
		self:GetViewComponent():InitAliveStageClear(stageCompleteInfo.aliveTime)
	else

	end
	-- 隐藏一些不需要的ui
	self:GetViewComponent():HideStageClearByStageCompleteType(stageCompleteInfo.completeType)

	-- 刷一次所有物体的目标
	self:RefreshAllWaveTargetMark()
end
--[[
刷一次所有物体的目标
--]]
function BattleManager:RefreshAllWaveTargetMark()
	local endDriver = self:GetEndDriver()
	if nil ~= endDriver then
		local completeType = endDriver:GetCompleteType()
		local friendTarget = {}
		local enemyTarget = {}
		if ConfigStageCompleteType.SLAY_ENEMY == completeType then
			friendTarget = endDriver:GetTargetsInfoByCampType(ConfigCampType.FRIEND)
			enemyTarget = endDriver:GetTargetsInfoByCampType(ConfigCampType.ENEMY)
		elseif ConfigStageCompleteType.HEAL_FRIEND == completeType then
			friendTarget = endDriver:GetTargetsInfoByCampType(ConfigCampType.FRIEND)
			enemyTarget = endDriver:GetTargetsInfoByCampType(ConfigCampType.ENEMY)
		end

		-- dump(friendTarget)
		-- dump(enemyTarget)

		-- 为目标打上mark 为非目标消去mark
		local obj = nil
		for i = #self:GetBData().sortBattleObjs.friend, 1, -1 do
			obj = self:GetBData().sortBattleObjs.friend[i]
			local targetId = obj:getOCardId()
			if nil ~= friendTarget[tostring(targetId)] then
				obj:ShowStageClearTargetMark(completeType, true)
			else
				obj:HideAllStageClearTargetMark()
			end
		end

		for i = #self:GetBData().sortBattleObjs.enemy, 1, -1 do
			obj = self:GetBData().sortBattleObjs.enemy[i]
			local targetId = obj:getOCardId()
			if nil ~= enemyTarget[tostring(targetId)] then
				obj:ShowStageClearTargetMark(completeType, true)
			else
				obj:HideAllStageClearTargetMark()
			end
		end
	end
end
--[[
显示强制退出的对话框
--]]
function BattleManager:ShowForceQuitLayer()
	-- 判断游戏状态
	if not self:IsBattleSceneLoadingOver() then return end

	local layer = uiMgr:GetCurrentScene():GetDialogByTag(FORCE_QUIT_LAYER_TAG)

	if nil ~= layer then
		-- 存在弹窗 消去这个弹窗
		layer:runAction(cc.RemoveSelf:create())
		return
	end

	local gameResultLayer = self:GetViewComponent():GetUIByTag(GAME_RESULT_LAYER_TAG)
	if nil ~= gameResultLayer then
		-- 如果已经结束 退出游戏
		self:BackToPrevious()
		return
	end

	-- 检查组队本的结算
	gameResultLayer = self:GetViewComponent():GetUIByTag(BATTLE_SUCCESS_VIEW_TAG)
	if nil ~= gameResultLayer then
		-- 如果已经结束 退出游戏
		self:BackToPrevious()
		return
	end

	layer = require('common.CommonTip').new({
		text = __('确定要退出吗?'),
		descr = __('退出本场战斗会被认定为失败'),
		callback = function (sender)
			self:BackToPrevious()
		end
	})
	layer:setTag(FORCE_QUIT_LAYER_TAG)
	layer:setPosition(display.center)
	uiMgr:GetCurrentScene():AddDialog(layer)
end
--[[
根据effect id强制移除一次obj上hold的动画
@params effectId string effect id
--]]
function BattleManager:ForceRemoveAttachEffectByEffectId(effectId)
	local obj = nil
	-- 存活的战斗物体
	for i = #self:GetBData().sortBattleObjs.friend, 1, -1 do
		obj = self:GetBData().sortBattleObjs.friend[i]
		obj.view.viewComponent:RemoveAttachEffectByEffectId(effectId)
	end
	for i = #self:GetBData().sortBattleObjs.enemy, 1, -1 do
		obj = self:GetBData().sortBattleObjs.enemy[i]
		obj.view.viewComponent:RemoveAttachEffectByEffectId(effectId)
	end
	for i = #self:GetBData().sortBattleObjs.beckonObj, 1, -1 do
		obj = self:GetBData().sortBattleObjs.beckonObj[i]
		obj.view.viewComponent:RemoveAttachEffectByEffectId(effectId)
	end

	-- 死亡的战斗物体
	for i = #self:GetBData().sortDustObjs.friend, 1, -1 do
		obj = self:GetBData().sortDustObjs.friend[i]
		obj.view.viewComponent:RemoveAttachEffectByEffectId(effectId)
	end
	for i = #self:GetBData().sortDustObjs.enemy, 1, -1 do
		obj = self:GetBData().sortDustObjs.enemy[i]
		obj.view.viewComponent:RemoveAttachEffectByEffectId(effectId)
	end
	for i = #self:GetBData().sortDustObjs.beckonObj, 1, -1 do
		obj = self:GetBData().sortDustObjs.beckonObj[i]
		obj.view.viewComponent:RemoveAttachEffectByEffectId(effectId)
	end
end
---------------------------------------------------
-- view control end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
获取战斗数据
--]]
function BattleManager:GetBData()
	return self.bdata
end
--[[
获取战斗配置
--]]
function BattleManager:GetBConf()
	return self.bconf
end
--[[
获取随机数管理器
--]]
function BattleManager:GetRandomManager()
	return self.randomManager
end
--[[
获取战斗场景
--]]
function BattleManager:GetViewComponent()
	return self.viewComponent
end
--[[
设置战斗场景
--]]
function BattleManager:SetViewComponent(viewComponent)
	self.viewComponent = viewComponent
end
--[[
获取战斗节点
--]]
function BattleManager:GetBattleRoot()
	-- return self:GetBData():getBattleRoot()
	return self:GetViewComponent().viewData.battleLayer
end
--[[
游戏状态
--]]
function BattleManager:GetGState()
	return self:GetBData().gameState
end
function BattleManager:SetGState(gstate)
	self:GetBData().gameState = gstate
end
--[[
根据row col 获取格子信息
@params r int 行
@params c int 列
@return t table {
	cx number cell center x
	cy number cell center y
	box cc.rect cell boundingbox
}
--]]
function BattleManager:GetCellPosByRC(r, c)
	if (r >= 1 and r <= self.bconf.ROW) and
		(c >= 1 and c <= self.bconf.COL) then
		return self.bconf.cellsCoordinate[r][c]
	else
		-- 超边坐标
		return {
			cx = self.bconf.BATTLE_AREA.x + self.bconf.cellSize.width * 0.5 + ((c - 1) * self.bconf.cellSize.width),
			cy = self.bconf.BATTLE_AREA.y + self.bconf.cellSize.height * 0.5 + ((r - 1) * self.bconf.cellSize.height),
			box = cc.rect(
				self.bconf.BATTLE_AREA.x + ((c - 1) * self.bconf.cellSize.width),
				self.bconf.BATTLE_AREA.y + ((r - 1) * self.bconf.cellSize.height),
				self.bconf.cellSize.width,
				self.bconf.cellSize.height
			)
		}
	end
end
--[[
根据坐标获取row col 纵向边界算下面一格 横向边界算右边一格
@params p cc.p 坐标
@return {r, c} table 行列 
--]]
function BattleManager:GetRowColByPos(p)
	local fixP = cc.p(p.x - self.bconf.BATTLE_AREA.x, p.y - self.bconf.BATTLE_AREA.y)
	return {r = math.ceil(fixP.y / self.bconf.cellSize.height), c = math.floor(fixP.x / self.bconf.cellSize.width) + 1}
end
--[[
获取游戏变速参数
--]]
function BattleManager:GetTimeScale()
	return self:GetBData().timeScale
end
--[[
设置游戏变速参数
--]]
function BattleManager:SetTimeScale(i)
	if 0 == i then return end
	self:GetBData().timeScale = i
	self:GetViewComponent().viewData.accelerateButton:getNormalImage():setTexture(_res(string.format('ui/battle/battle_btn_accelerate_%d.png', checkint(i))))
	cc.Director:getInstance():getScheduler():setTimeScale(i)
end
--[[
获取objzorder
@params pos cc.p 位置坐标
@params isEnemy bool 是否是敌人
@params isInHighlight bool 是否处于高亮状态
@return zorder int local zorder
--]]
function BattleManager:GetObjZorder(pos, isEnemy, isInHighlight)
	local zorder = self:GetZorderInBattle(pos)
	if isEnemy then
		zorder = zorder - 1
	end
	if isInHighlight then
		zorder = zorder + self:GetFixedHighlightZOrder()
	end
	return zorder
end
--[[
根据坐标获取战场上的zorder
@params p cc.p 战场上的坐标
--]]
function BattleManager:GetZorderInBattle(p)
	local zorderMax = self:GetBConf().BATTLE_AREA.height * 2
	local zorder = zorderMax - checkint(p.y - self:GetBConf().BATTLE_AREA.y)
	return zorder
end
--[[
根据tag获取obj 无视死活
@params tag int obj tag
@return result obj 理论上不应该存在返回的obj为空的情况
--]]
function BattleManager:GetObjByTagForce(tag)
	if nil == tag then return nil end
	local result = nil
	tag = checkint(tag)
	if (FRIEND_TAG < tag and WEATHER_TAG > tag) or BULLET_TAG < tag then
		result = self:GetBData().battleObjs[tostring(tag)]
		if nil == result then
			result = self:GetBData().dustObjs[tostring(tag)]
		end
	elseif WEATHER_TAG < tag and FRIEND_PLAYER_TAG > tag then
		result = self:GetBData().weather[tostring(tag)]
	elseif FRIEND_PLAYER_TAG < tag and OBSERVER_TAG > tag then
		result = self:GetBData().playerObj[tostring(tag)]
	end
	return result
end
--[[
判断tag对应的obj是否存活
@params tag int objtag
@return result obj 存活直接返回obj指针 否则返回nil
--]]
function BattleManager:IsObjAliveByTag(tag)
	if nil == tag then return nil end
	local result = nil
	tag = checkint(tag)
	if (FRIEND_TAG < tag and WEATHER_TAG > tag) or BULLET_TAG < tag then
		result = self:GetBData().battleObjs[tostring(tag)]
	elseif WEATHER_TAG < tag and FRIEND_PLAYER_TAG > tag then
		result = self:GetBData().weather[tostring(tag)]
	elseif FRIEND_PLAYER_TAG < tag and OBSERVER_TAG > tag then
		result = self:GetBData().playerObj[tostring(tag)]
	elseif GLOBAL_EFFECT_TAG < tag and DIRECTOR_TAG > tag then
		result = self:GetBData():GetGlobalEffectObj()
	end
	return result
end
--[[
判断cardId对应的obj是否存活
@params cardId int card id
@params isEnemy int 是否是敌人
@return result bool 是否存活
--]]
function BattleManager:IsObjAliveByCardId(cardId, isEnemy)
	if not cardId then return nil end
	local obj = nil
	if isEnemy then
		for i = #self:GetBData().sortBattleObjs.enemy, 1, -1 do
			obj = self:GetBData().sortBattleObjs.enemy[i]
			if checkint(cardId) == checkint(obj:getOCardId()) then
				return obj
			end
		end
	else
		for i = #self:GetBData().sortBattleObjs.friend, 1, -1 do
			obj = self:GetBData().sortBattleObjs.friend[i]
			if checkint(cardId) == checkint(obj:getOCardId()) then
				return obj
			end
		end
	end
	return nil
end
--[[
强制获取cardId对应的obj
@params id int card id
@params isEnemy int 是否是敌人
@return result bool 
--]]
function BattleManager:GetObjByCardIdForce(id, isEnemy)
	if not id then return nil end
	local obj = nil
	if isEnemy then

		for i = #self:GetBData().sortBattleObjs.enemy, 1, -1 do
			obj = self:GetBData().sortBattleObjs.enemy[i]
			if checkint(id) == checkint(obj:getOCardId()) then
				return obj
			end
		end

		for i = #self:GetBData().sortDustObjs.enemy, 1, -1 do
			obj = self:GetBData().sortDustObjs.enemy[i]
			if checkint(id) == checkint(obj:getOCardId()) then
				return obj
			end
		end

	else

		for i = #self:GetBData().sortBattleObjs.friend, 1, -1 do
			obj = self:GetBData().sortBattleObjs.friend[i]
			if checkint(id) == checkint(obj:getOCardId()) then
				return obj
			end
		end

		for i = #self:GetBData().sortDustObjs.friend, 1, -1 do
			obj = self:GetBData().sortDustObjs.friend[i]
			if checkint(id) == checkint(obj:getOCardId()) then
				return obj
			end
		end

	end

	return nil
end
--[[
获取死亡对象
@params tag int objtag
@return result obj 死亡直接返回obj指针 否则返回nil
--]]
function BattleManager:GetDeadObjByTag(tag)
	if nil == tag then return nil end
	local result = nil
	tag = checkint(tag)
	if (FRIEND_TAG < tag and WEATHER_TAG > tag) or BULLET_TAG < tag then
		result = self:GetBData().dustObjs[tostring(tag)]
	end
	return result
end
--[[
获取编队中是否存在指定cardid的卡牌
@params cardId int 卡牌id
@params isEnemy bool 敌友性
--]]
function BattleManager:IsCardInTeam(cardId, isEnemy)
	-- local objs = self:GetBData():getFriendMembers(1)
	-- if isEnemy then
	-- 	objs = self:GetBData():getEnemyMembers(self:GetBData():getCurrentWave())
	-- end
	local objs = self:GetCurrentTeam(isEnemy)
	for i,v in ipairs(objs) do
		if nil ~= v.cardId and (checkint(cardId) == checkint(v.cardId)) then
			return true
		end
	end
	return false
end
--[[
获取当前队伍阵容
@params isEnemy bool 敌友性
@return _ list 战斗物体
--]]
function BattleManager:GetCurrentTeam(isEnemy)
	local currentTeamIndex = self:GetCurrentTeamIndex(isEnemy)
	if isEnemy then
		return self:GetBData():getEnemyMembers(currentTeamIndex)
	else
		return self:GetBData():getFriendMembers(currentTeamIndex)
	end
end
--[[
获取当前队伍序号
@params isEnemy bool 敌友性
@return _ int 队伍序号
--]]
function BattleManager:GetCurrentTeamIndex(isEnemy)
	return self:GetBattleDriver(BattleDriverType.SHIFT_DRIVER):GetCurrentTeamIndex(isEnemy)
end
--[[
游戏是否暂停
--]]
function BattleManager:IsPause()
	return self:GetBData().isPause
end
--[[
根据tag获取战斗元素类型 不从战斗物体获取
@params tag int 目标tag
@params _ BattleElementType 战斗元素类型
--]]
function BattleManager:GetBattleElementTypeByTag(tag)

	if BULLET_TAG < tag then

		return BattleElementType.BET_BULLET

	elseif WEATHER_TAG > tag then

		return BattleElementType.BET_CARD

	elseif WEATHER_TAG < tag and FRIEND_PLAYER_TAG > tag then

		return BattleElementType.BET_WEATHER

	elseif FRIEND_PLAYER_TAG < tag and OBSERVER_TAG > tag then

		return BattleElementType.BET_PLAYER

	elseif OBSERVER_TAG < tag and BULLET_TAG > tag then

		return BattleElementType.BET_OB

	end

	return BattleElementType.BET_BASE

end
--[[
根据卡牌id获取转阶段内容
@params npcId int 卡牌怪物的配表id
--]]
function BattleManager:GetPhaseChangeDataByNpcId(npcId)
	if nil == self:GetBData():getPhaseChangeData() then
		return nil
	else
		return self:GetBData():getPhaseChangeData()[tostring(npcId)]
	end
end
--[[
根据卡牌id获取spine缩放比
@params cardId int 卡牌id
@return scale number spine缩放
--]]
function BattleManager:GetSpineAvatarScaleByCardId(cardId)
	local cardConf = CardUtils.GetCardConfig(cardId)
	
	local avatarId = cardId
	local scale = CARD_DEFAULT_SCALE
	local isMonster = false
	if true == CardUtils.IsMonsterCard(cardId) then

		avatarId = checkint(cardConf.drawId)
		isMonster = true

		-- 判断卡牌初始缩放比
		if ConfigMonsterType.ELITE == checkint(cardConf.type) then
			scale = ELITE_DEFAULT_SCALE
		elseif ConfigMonsterType.BOSS == checkint(cardConf.type) then
			scale = BOSS_DEFAULT_SCALE
		end

		if true ~= CardUtils.IsMonsterCard(avatarId) then
			-- 如果是怪物使用卡牌的情况 则加载时不做缩放
			scale = CARD_DEFAULT_SCALE
		end

	end
	return scale
end
--[[
根据卡牌id获取spine avatar相对于卡牌的缩放比
@params cardId int 卡牌id
@return scale number spine缩放
--]]
function BattleManager:GetSpineAvatarScale2CardByCardId(cardId)
	return self:GetSpineAvatarScaleByCardId(cardId) / CARD_DEFAULT_SCALE
end
--[[
获取高亮修正zorder
--]]
function BattleManager:GetFixedHighlightZOrder()
	return BATTLE_E_ZORDER.SPECIAL_EFFECT + 1
end
--[[
根据敌友性获取主角建模
@params isEnemy bool 是否是敌人
@return result obj 主角模型
--]]
function BattleManager:GetPlayerObj(isEnemy)
	if isEnemy then
		return self:GetBData().playerObj[tostring(ENEMY_PLAYER_TAG + 1)]
	else
		return self:GetBData().playerObj[tostring(FRIEND_PLAYER_TAG + 1)]
	end
end
--[[
初始化战斗场景按钮回调
--]]
function BattleManager:InitialActions()
	if self:GetViewComponent() then
		for k, btn in pairs(self:GetViewComponent().viewData.actionButtons) do
			display.commonUIParams(btn, {animate = false, cb = handler(self, self.ButtonActions)})
		end

		------------ 录屏回调 ------------
		if BattleConfigUtils.IsScreenRecordEnable() and nil ~= self:GetViewComponent().viewData.screenRecordBtn then
			display.commonUIParams(self:GetViewComponent().viewData.screenRecordBtn, {
				cb = handler(self, self.ScreenRecordClickHandler)
			})
		end
		------------ 录屏回调 ------------
	end
end
--[[
获取原始的战斗构造数据
--]]
function BattleManager:GetOriBattleConstructData()
	return self.battleConstructor:GetBattleConstructData()
end
--[[
获取原始的战斗构造器
--]]
function BattleManager:GetOriBattleConstructor()
	return self.battleConstructor
end
--[[
是否可以装载连携技
@return _ bool 是否可以装载连携技
--]]
function BattleManager:CanUseFriendConnectSkill()
	return self:GetBData():getBattleConstructData().enableConnect
end
--[[
是否自动释放连携技
@return _ bool 是否自动释放连携技
--]]
function BattleManager:AutoUseFriendConnectSkill()
	return self:GetBData():getBattleConstructData().autoConnect
end
--[[
是否加载完毕
@return _ bool 战斗场景是否加载完毕
--]]
function BattleManager:IsBattleSceneLoadingOver()
	return self.battleSceneLoadingOver
end
--[[
设置战斗场景加载完毕
@params over bool 是否加载完毕
--]]
function BattleManager:SetBattleSceneLoadingOver(over)
	self.battleSceneLoadingOver = over
end
--[[
设置结束驱动
@params wave int 波数
@params battleDriver BaseBattleDriver
--]]
function BattleManager:SetEndDriver(wave, battleDriver)
	if nil == self:GetBattleDriver(BattleDriverType.END_DRIVER) then
		self:SetBattleDriver(BattleDriverType.END_DRIVER, {})
	end

	self:GetBattleDriver(BattleDriverType.END_DRIVER)[wave] = battleDriver
end
--[[
获取结束驱动
@params wave int 波数
--]]
function BattleManager:GetEndDriver(wave)
	if nil == wave then
		wave = self:GetBData():getCurrentWave()
	end
	local endDriver = self:GetBattleDriver(BattleDriverType.END_DRIVER)[wave]
	if nil == endDriver then
		endDriver = self:GetBattleDriver(BattleDriverType.END_DRIVER)[1]
	end
	return endDriver
end
--[[
获取战斗驱动
@params battleDriverType BattleDriverType 战斗驱动类型
--]]
function BattleManager:GetBattleDriver(battleDriverType)
	return self.drivers[battleDriverType]
end
--[[
设置战斗驱动
@params battleDriverType BattleDriverType 战斗驱动类型
@params battleDriver BaseBattleDriver
--]]
function BattleManager:SetBattleDriver(battleDriverType, battleDriver)
	self.drivers[battleDriverType] = battleDriver
end
--[[
判断是否是世界boss类型
@return _ bool 是否是世界boss类型
--]]
function BattleManager:IsShareBoss()
	local b = QuestBattleType.UNION_BEAST == self:GetBData():getQuestBattleType() or
		QuestBattleType.WORLD_BOSS == self:GetBData():getQuestBattleType()
	return b
end
--[[
判断是否是pvc模式
@return _ bool 是否是 card vs card
--]]
function BattleManager:IsCardVSCard()
	local questBattleType = self:GetBData():getQuestBattleType()
	local battleTypeConfig = {
		[QuestBattleType.ROBBERY] 			= true, -- 打劫
		[QuestBattleType.PVC] 				= true, -- 皇家对决
		[QuestBattleType.TAG_MATCH_3V3] 	= true, -- 3v3
		[QuestBattleType.UNION_PVC] 		= true, -- 工会战打人
		[QuestBattleType.ULTIMATE_BATTLE] 	= true, -- 巅峰对决
		[QuestBattleType.SKIN_CARNIVAL] 	= true  -- 皮肤嘉年华
	}
	return true == battleTypeConfig[questBattleType]
end
--[[
是否是车轮战
@return _ bool 是否是多队vs多队的车轮战
--]]
function BattleManager:IsTagMatchBattle()
	if QuestBattleType.TAG_MATCH_3V3 == self:GetQuestBattleType() then
		return true
	end

	if 1 < #self:GetBattleMembers(false) then
		return true
	end

	return false
end
--[[
判断是否可以重新开始
@return b bool 是否可以重新开始
--]]
function BattleManager:CanRestartGame()
	local questBattleType = self:GetBData():getQuestBattleType()
	local b = not (self:IsCardVSCard() or self:IsShareBoss() or (QuestBattleType.ACTIVITY_QUEST == questBattleType))
	return b
end
--[[
获取目标变化血量
@return deltaHp int 变化的血量
--]]
function BattleManager:GetTargetMonsterDeltaHP()
	-- 走一次配表逻辑
	local deltaHp, useConfigLogic = self:GetTargetMonsterDeltaHPByConfig()

	if not useConfigLogic then

		-- 使用老的逻辑 走share boss的逻辑
		if self:IsShareBoss() then

			deltaHp = self:GetTargetMonsterDeltaHPByShareBoss()

		else

			deltaHp = nil

		end

	end

	return deltaHp
end
--[[
根据配表信息判断需要传给服务器的delta hp
@return deltaHp, useConfigLogic number, bool 变化的血量 是否使用配表逻辑
--]]
function BattleManager:GetTargetMonsterDeltaHPByConfig()
	local deltaHp = 0
	local useConfigLogic = false

	-- 查找次怪物指针
	for otag, obj in pairs(self:GetBData().battleObjs) do
		if ConfigMonsterRecordDeltaHP.DO == obj:GetRecordDeltaHp() then
			-- 记录变化的血量
			deltaHp = deltaHp + obj:getMainProperty():getDeltaHp()
			-- 置为true 不再走老逻辑
			if not useConfigLogic then
				useConfigLogic = true
			end
		end
	end

	for otag, obj in pairs(self:GetBData().dustObjs) do
		if ConfigMonsterRecordDeltaHP.DO == obj:GetRecordDeltaHp() then
			-- 记录变化的血量
			deltaHp = deltaHp + obj:getMainProperty():getDeltaHp()
			-- 置为true 不再走老逻辑
			if not useConfigLogic then
				useConfigLogic = true
			end
		end
	end

	return deltaHp, useConfigLogic
end
--[[
写死的老逻辑 共享血量boss传一次变化的血量
@return deltaHp number 变化的血量
--]]
function BattleManager:GetTargetMonsterDeltaHPByShareBoss()
	local deltaHp = 0
	if nil ~= self:GetBData():getCurStageId() then
		-- 获取阵容
		local enemyConfig = CommonUtils.GetConfig('quest', 'enemy', self:GetBData():getCurStageId())
		if nil ~= enemyConfig then
			local targetMonsterId = nil
			for wave, waveConfig in pairs(enemyConfig) do
				local needBreak = false
				for _, npcConfig in ipairs(waveConfig.npc) do
					targetMonsterId = checkint(npcConfig.npcId)
					needBreak = true
					break
				end
				if needBreak then
					break
				end
			end
			if nil ~= targetMonsterId then
				-- 查找次怪物指针
				for otag, obj in pairs(self:GetBData().battleObjs) do
					if nil ~= obj.getOCardId then
						if targetMonsterId == obj:getOCardId() then
							deltaHp = obj:getMainProperty():getDeltaHp()
							return deltaHp
						end
					end
				end

				for otag, obj in pairs(self:GetBData().dustObjs) do
					if nil ~= obj.getOCardId then
						if targetMonsterId == obj:getOCardId() then
							deltaHp = obj:getMainProperty():getDeltaHp()
							return deltaHp
						end
					end
				end
			end
		end
	end
	return deltaHp
end
--[[
获取战斗结束后的表演信息
@params r BattleResult 战斗结果
@return _ bool 是否需要展示表演信息
--]]
function BattleManager:NeedShowActAfterGameOver(r)
	if QuestBattleType.UNION_BEAST == self:GetBData():getBattleConstructData().questBattleType then
		return true
	end
	return false
end
--[[
根据波数获取过关配置
@params wave int 波数
@return _ StageCompleteSturct 过关配置信息
--]]
function BattleManager:GetStageCompleteInfoByWave(wave)
	if nil ~= self:GetBData() then
		return self:GetBData():getBattleConstructData().stageCompleteInfo[wave]
	end
	return nil
end
--[[
根据波数重新设置过关配置
@params wave int 波数
@params stageCompleteInfo StageCompleteSturct 过关配置信息
--]]
function BattleManager:SetStageCompleteInfoByWave(wave, stageCompleteInfo)
	self:GetBData():getBattleConstructData().stageCompleteInfo[wave] = stageCompleteInfo
end
--[[
根据过关配置信息获取过关描述
@params stageCompleteInfo StageCompleteSturct 过关配置信息
@return str string 过关描述
--]]
function BattleManager:GetStageCompleteDescrByInfo(stageCompleteInfo)
	local str = tostring(self:GetBData():getCurrentWave())
	local passType = stageCompleteInfo.completeType
	local passConfig = CommonUtils.GetConfig('quest', 'passType', tostring(passType))
	if nil ~= passConfig then
		str = tostring(passConfig.descr)
	end
	return str
end
--[[
是否存在下一波
--]]
function BattleManager:HasNextWave()
	return self:GetEndDriver():HasNextWave()
end
--[[
获取关卡类型
@return _ QuestBattleType 关卡类型
--]]
function BattleManager:GetQuestBattleType()
	return self:GetOriBattleConstructData().questBattleType
end
--[[
根据敌友性获取是否存在下一波阵容
@params isEnemy bool 敌友性
@return _ bool 是否存在下一波阵容
--]]
function BattleManager:HasNextTeam(isEnemy)
	return self:GetBattleDriver(BattleDriverType.SHIFT_DRIVER):HasNextTeam(isEnemy)
end
--[[
是否可以创建qte召唤物
--]]
function BattleManager:CanCreateBeckonFromBuff()
	return MAX_BECKON_AMOUNT_LIMIT > #BMediator:GetBData().sortBattleObjs.beckonObj
end
--[[
获取战斗界面结算类型
@return _ ConfigBattleResultType 结算类型
--]]
function BattleManager:GetBattleResultViewType()
	return self:GetOriBattleConstructData().resultType
end
--[[
获取阵容信息
@params isEnemy bool 是否是敌人
@return _ FormationStruct
--]]
function BattleManager:GetTeamData(isEnemy)
	if isEnemy then
		return self:GetOriBattleConstructData().enemyFormation
	else
		return self:GetOriBattleConstructData().friendFormation
	end
end
--[[
获取阵容成员信息
@params isEnemy bool 是否是敌人
@params wave int 波数
@return _ list 阵容信息
--]]
function BattleManager:GetBattleMembers(isEnemy, wave)
	if nil == wave then
		return self:GetTeamData(isEnemy).members
	else
		return self:GetTeamData(isEnemy).members[wave]	
	end
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

---------------------------------------------------
-- callback begin --
---------------------------------------------------
--[[
场景按钮回调
1001 暂停游戏
1002 变速
1003 退出游戏
1004 重新开始
1005 继续游戏
1006 下一关
1007 成功后的再次挑战
1008 放弃买活
--]]
function BattleManager:ButtonActions(sender)

	PlayUIEffects(AUDIOS.UI.ui_click_normal.id)

	local tag = sender:getTag()

	if 1001 == tag then

		if false == self:GetBData().isPause then
			-- 判断是否可以触摸
			if not self:IsBattleTouchEnable() then return end

			print('should pause')
			self:PauseGame()
		end

	elseif 1002 == tag then

		-- 判断是否可以触摸
		if not self:IsBattleTouchEnable() then return end

		print('should accelerate game')
		local gameTimeScale = self:GetTimeScale()
		gameTimeScale = 3 - gameTimeScale
		self:SetTimeScale(gameTimeScale)
		------------ 刷新本地加速记录 ------------
		gameMgr:UpdatePlayer({localBattleAccelerate = gameTimeScale})
		------------ 刷新本地加速记录 ------------

	elseif 1003 == tag then

		if QuestBattleType.PVC == self:GetBData():getBattleConstructData().questBattleType then
			local layer = require('common.CommonTip').new({
				text = __('确定要退出吗?'),
				descr = __('退出本场战斗会被认定为失败'),
				callback = function (sender)
					self:BackToPrevious()
				end
			})
			layer:setPosition(display.center)
			uiMgr:GetCurrentScene():AddDialog(layer)
		else
			self:BackToPrevious()
		end

	elseif 1004 == tag then

		if not self:CanRestartGame() then
			uiMgr:ShowInformationTips(__('无法重新开始!!!'))
		else
			self:RestartGame(self:GetBData():getCurStageId())
		end

	elseif 1005 == tag then

		if true == self:GetBData().isPause then
			print('should resume')
			self:ResumeGame()
		end

	elseif 1006 == tag then

		-- 现在不再有下一关的逻辑

		-- local nextStageConf = CommonUtils.GetConfig('quest', 'quest', self:GetBData():getCurStageId() + 1)
		-- if nil == nextStageConf then
		-- 	-- 返回主界面
		-- 	local CommonTip  = require( 'common.CommonTip' ).new({text = __('后续关卡暂未开放'),isOnlyOK = true, callback = function ()
	 --    		self:BackToPrevious()
		--     end})
		-- 	CommonTip:setPosition(display.center)
		-- 	self:GetViewComponent():AddDialog(CommonTip)
		-- else
		-- 	-- 下一关 跳回主界面
		-- 	self:BackToPrevious()
		-- end

	elseif 1007 == tag then

		-- 判断是否可以再次挑战
		--## new logic todo ##--
		if false then
			local leftChallengeTimes = CommonUtils.GetRechallengeLeftTimesByStageId(self:GetBData():getCurStageId())
			if QuestRechallengeTime.QRT_NONE == leftChallengeTimes then
				-- 次数不够
				uiMgr:ShowInformationTips(__('挑战次数不足\n挑战次数每日0:00重置'))
				return
			end
		end
		self:RestartGame(self:GetBData():getCurStageId())
		--## new logic todo ##--

	elseif 1008 == tag then	

		-- 放弃买活
		self:GetViewComponent():RemoveUILayerByTag(BUY_REVIVAL_LAYER_TAG)
		self:CancelRescue()

	elseif 1009 == tag then	

		-- 买活
		self:RescueAllFriend()

	end
end
--[[
连携按钮回调
@params tag int 释放连携技的目标tag
@params skillId int 技能id
--]]
function BattleManager:ConnectButtonCallback(tag, skillId)
	-- 判断是否可以触摸
	if not self:IsBattleTouchEnable() then return end

	PlayUIEffects(AUDIOS.UI.ui_click_normal.id)

	-- 是否可以手动释放
	if self:AutoUseFriendConnectSkill() then
		-- 当前为自动释放连携技模式
		uiMgr:ShowInformationTips(__('当前为自动释放连携技模式'))
		return
	end

	local obj = self:IsObjAliveByTag(tag)
	if obj and (BattleResult.BR_CONTINUE == self:isGameOver()) and false == self:IsPause() then
		obj:castConnectSkill(skillId)
	end
end
--[[
录屏按钮回调
--]]
function BattleManager:ScreenRecordClickHandler(sender)
	local start = BattleUtils.StartScreenRecord()
	if start then
		PlayUIEffects(AUDIOS.UI.ui_click_normal.id)

		-- 设置图标变红
		self:GetViewComponent().viewData.recordLabel:setTexture(_res('ui/battle/battle_btn_video_under.png'))
		self:GetViewComponent().viewData.recordMark:setTexture(_res('ui/battle/battle_ico_video_state.png'))
	end
end
---------------------------------------------------
-- callback end --
---------------------------------------------------

---------------------------------------------------
-- load res begin --
---------------------------------------------------
--[[
加载资源
--]]
function BattleManager:LoadResources()
	local resLoaderDriver = self:GetBattleDriver(BattleDriverType.RES_LOADER)
	resLoaderDriver:OnLogicEnter(1)
end
---------------------------------------------------
-- load res end --
---------------------------------------------------

---------------------------------------------------
-- network handler begin --
---------------------------------------------------
--[[
进入游戏 发送请求
--]]
function BattleManager:EnterBattle()
	-- 初始化资源加载驱动
	local className = 'battle.battleDriver.BattleResLoadDriver'

	if self:IsTagMatchBattle() then
		className = 'battle.battleDriver.TagMatchResLoadDriver'
	end

	local resLoaderDriver = __Require(className).new({
		owner = self
	})
	self:SetBattleDriver(BattleDriverType.RES_LOADER, resLoaderDriver)

	-- 第一次进入战斗请求在外部处理
	-- 60帧
	cc.Director:getInstance():setAnimationInterval(RENDER_FPS)
	resLoaderDriver:LoadSoundResources()
	self:StartGameAndLoadingResources()
end
--[[
返回上一个界面
--]]
function BattleManager:BackToPrevious()

	-- 此处防止一次连点
	if nil == self.bdata then return end

	self:ExitGame()

	if nil == self:GetOriBattleConstructData().fromtoData then
		AppFacade.GetInstance():RetrieveMediator("Router"):ClearMediators()
		uiMgr:SwitchToTargetScene(DEBUG_SCENE_NAME)
		return
	end

	AppFacade.GetInstance():DispatchObservers(
		'BATTLE_BACK_TO_PREVIOUS',
		{
			questBattleType = self:GetQuestBattleType(),
			isPassed = self:IsBattleOver(),
			battleConstructor = self:GetOriBattleConstructor()
		}
	)
end
--[[
获取战斗结果请求公共参数
@params isPassed int 战斗是否胜利 1 胜利 0 失败
@params result table 参数集合
--]]
function BattleManager:GetExitRequestCommonParameters(isPassed)
	local result = {
		teamId = self:GetBData():getTeamData(false).teamId,
		deadCards = self:GetBData():getDeadCardsStr(),
		passTime = math.ceil((self:GetBData():getGameTime() - self:GetBData().leftTime) * 1000) * 0.001,
		fightData = self:GetBData():getFightDataStr(),
		fightRound = self:GetBData():getCurrentWave(),
		isPassed = isPassed,
		skadaDamage = 0,
		skadaHeal = 0,
		skadaGotDamage = 0
	}

	-- 上传一次变化的血量
	result.totalDamage = self:GetTargetMonsterDeltaHP()

	return result
end
--[[
记录战斗流程到本地
--]]
function BattleManager:RecordBattle()
	self:GetBData():writeBattle()
end
--[[
获取战斗是否结束
@return _ PassedBattle
--]]
function BattleManager:IsBattleOver()
	return checkint(checktable(self:GetOriBattleConstructor():GetServerCommand().exitBattleRequestData).isPassed)
end
---------------------------------------------------
-- network handler end --
---------------------------------------------------

---------------------------------------------------
-- debug begin --
---------------------------------------------------
--[[
显示debug信息
--]]
function BattleManager:ShowDebugInfo()
	for r = 1, self:GetBConf().ROW do
		for c = 1, self:GetBConf().COL do
			local cellInfo = self:GetCellPosByRC(r, c)
			local t = display.newImageView(_res('ui/common/common_hint_circle_red_ico.png'), cellInfo.cx, cellInfo.cy)
			self:GetBattleRoot():addChild(t)
			local posLabel = display.newLabel(t:getContentSize().width * 0.5, t:getContentSize().height + 10,
				{text = string.format('(%d,%d)', r, c), fontSize = 14, color = '#6c6c6c'})
			t:addChild(posLabel)
		end
	end
end
--[[
debug collision box
--]]
function BattleManager:ShowAllCollisionBox()
	self.debugCollisionBox = {}
	local parent = self:GetViewComponent().viewData.uiLayer

	local CreateAllCollisionBox = function ()
		local obj = nil
		for i,v in ipairs(self:GetBData().sortBattleObjs.friend) do
			local collisionBox = v:getStaticCollisionBox()
			local pos = parent:convertToNodeSpace(cc.p(collisionBox.x, collisionBox.y))
			local collisionLayer = display.newLayer(pos.x, pos.y, {size = cc.size(collisionBox.width, collisionBox.height)})
			collisionLayer:setBackgroundColor(cc.c4b(math.random(255), math.random(255), math.random(255), 128))
			parent:addChild(collisionLayer, 999)
			self.debugCollisionBox[tostring(v:getOTag())] = collisionLayer
		end

		for i,v in ipairs(self:GetBData().sortBattleObjs.enemy) do
			local collisionBox = v:getStaticCollisionBox()
			local pos = parent:convertToNodeSpace(cc.p(collisionBox.x, collisionBox.y))
			local collisionLayer = display.newLayer(pos.x, pos.y, {size = cc.size(collisionBox.width, collisionBox.height)})
			collisionLayer:setBackgroundColor(cc.c4b(math.random(255), math.random(255), math.random(255), 128))
			parent:addChild(collisionLayer, 999)
			self.debugCollisionBox[tostring(v:getOTag())] = collisionLayer
		end
	end

	-- 手动刷新场上物体碰撞框
	local updateCollisionBoxBtn = display.newButton(0, 0, {
		n = _res('ui/common/common_btn_blue_default.png'),
		cb = function (sender)
			-- 移除老框
			for k,v in pairs(self.debugCollisionBox) do
				v:setVisible(false)
				v:runAction(cc.RemoveSelf:create())
			end

			self.debugCollisionBox = {}

			-- 创建新框
			CreateAllCollisionBox()
		end
	})
	display.commonUIParams(updateCollisionBoxBtn, {po = cc.p(
		self:GetViewComponent().viewData.pauseButton:getPositionX(),
		self:GetViewComponent().viewData.pauseButton:getPositionY() - self:GetViewComponent().viewData.pauseButton:getContentSize().height * 0.5 - updateCollisionBoxBtn:getContentSize().height * 0.5 - 20
	)})
	display.commonLabelParams(updateCollisionBoxBtn, fontWithColor('14', {text = '刷新框'}))
	parent:addChild(updateCollisionBoxBtn, 1000)

	CreateAllCollisionBox()
end
--[[
引导debug
--]]
function BattleManager:ShowGuideDebug()
	-- 创建一个ob物体 引导精灵
	local isEnemy = false
	local location = ObjectLocation.New(0, 0, 0, 0)
	local objInfo = ObjectConstructorStruct.New(
		nil, location, 1, BattleObjectFeature.BASE, ConfigCardCareer.BASE, isEnemy,
		nil, nil, nil, nil, false, nil,
		nil, nil, nil,
		nil
	)
	local tagInfo = self:GetBData():getObserverTag()

	local obObject = __Require('battle.object.BaseOBObject').new({
		tag = tagInfo.tag,
		oname = tagInfo.name,
		battleElementType = BattleElementType.BET_OB,
		objInfo = objInfo
	})
	self:GetBData():addAObserver(obObject)
end
---------------------------------------------------
-- debug end --
---------------------------------------------------

return BattleManager
