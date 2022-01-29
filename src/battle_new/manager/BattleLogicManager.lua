--[[
战斗逻辑控制器
@params _ table {
	battleConstructor BattleConstructor 战斗构造器
}
--]]
---@type BaseBattleManager
local BaseBattleManager = __Require('battle.manager.BaseBattleManager')
---@class BattleLogicManager : BaseBattleManager
local BattleLogicManager = class('BattleLogicManager', BaseBattleManager)

------------ import ------------
local QTEAttachModel = __Require('battle.object.logicModel.BaseAttachModel')
------------ import ------------

------------ define ------------
-- 逻辑帧帧率
local LOGIC_FPS = 1 / 30

local BUY_REVIVAL_LAYER_TAG = 2301
local FORCE_QUIT_LAYER_TAG = 2311

-- 逻辑帧先跑的帧数 -1为不跑渲染帧
local LOGIC_FRAME_ADVANCE = -1
------------ define ------------

--[[
construtor
--]]
function BattleLogicManager:ctor( ... )
	BaseBattleManager.ctor(self, ...)
end

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化
--]]
function BattleLogicManager:Init()
	BaseBattleManager.Init(self)

	-- 初始化数据
	self:InitValue()
end
--[[
初始化数据
--]]
function BattleLogicManager:InitValue()
	------------ battle temp data ------------
	-- 战斗配置信息数据
	self.bconf = nil

	-- 战斗缓存数据
	self.bdata = nil

	-- 物体事件处理函数集合
	self.objEvents = {}

	-- 全局事件处理函数集合
	self.globalEvents = {}

	-- 是否可以触摸
	self.canTouch = false
	------------ battle temp data ------------
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- enter game begin --
---------------------------------------------------
--[[
进入游戏
--]]
function BattleLogicManager:EnterBattle()
	-- 初始化战斗驱动器
	self:InitBattleDrivers()

	-- 初始化战斗缓存数据
	self:InitBattleData()
end
--[[
初始化战斗驱动器
--]]
function BattleLogicManager:InitBattleDrivers()
	-- 切波驱动器
	local shiftDriverClassName = 'battle.battleDriver.BattleShiftDriver'

	local questBattleType = self:GetQuestBattleType()
	local isTagMatch = self:IsTagMatchBattle()

	if isTagMatch then

		shiftDriverClassName = 'battle.battleDriver.TagMatchShiftDriver'

	end

	-- 创建切波驱动器
	local shiftDriver = __Require(shiftDriverClassName).new({owner = self})
	self:SetBattleDriver(BattleDriverType.SHIFT_DRIVER, shiftDriver)

	-- 战斗结束驱动器
	local completeType = nil

	for wave, stageCompleteInfo in ipairs(self:GetBattleConstructData().stageCompleteInfo) do

		completeType = stageCompleteInfo.completeType

		local endDriverClassName = 'battle.battleDriver.BattleEndDriver'

		if ConfigStageCompleteType.SLAY_ENEMY == completeType then

			endDriverClassName = 'battle.battleDriver.SlayEndDriver'

		elseif ConfigStageCompleteType.HEAL_FRIEND == completeType then

			endDriverClassName = 'battle.battleDriver.HealEndDriver'

		elseif ConfigStageCompleteType.ALIVE == completeType then

			endDriverClassName = 'battle.battleDriver.AliveEndDriver'

		elseif ConfigStageCompleteType.TAG_MATCH == completeType or isTagMatch then

			endDriverClassName = 'battle.battleDriver.TagMatchEndDriver'

		end

		-- 创建结束驱动器
		local endDriver = __Require(endDriverClassName).new({
			owner = self,
			wave = wave,
			stageCompleteInfo = stageCompleteInfo
		})
		self:SetEndDriver(wave, endDriver)

	end

	-- 伤害统计插件
	local skadaDriver = __Require('battle.battleDriver.BattleSkadaDriver').new({owner = self})
	self:SetBattleDriver(BattleDriverType.SKADA_DRIVER, skadaDriver)
end
--[[
初始化battleData
--]]
function BattleLogicManager:InitBattleData()
	local bdata = __Require('battle.controller.BattleData').new({
		battleConstructor = self:GetBattleConstructor()
	})

	self:SetBData(bdata)
end
---------------------------------------------------
-- enter game end --
---------------------------------------------------

---------------------------------------------------
-- res load begin --
---------------------------------------------------
--[[
资源加载完成回调
--]]
function BattleLogicManager:LoadResourcesOver()
	-- 初始化战斗逻辑
	self:InitBattleLogic()

	if DEBUG_MEM then
		print("----------------------------------------")
		print("battle start and check lua men")
		print(string.format("LUA VM MEMORY USED: %0.2f KB", collectgarbage("count")))
		print("----------------------------------------")
	end
end
---------------------------------------------------
-- res load end --
---------------------------------------------------

---------------------------------------------------
-- init battle logic begin --
---------------------------------------------------
--[[
初始化战斗逻辑
--]]
function BattleLogicManager:InitBattleLogic()
	------------ 初始化上传的构造器数据 ------------
	self:Init2ServerConstructorData()
	------------ 初始化上传的构造器数据 ------------

	------------ 初始化逻辑外物体 ------------
	-- 初始化ob物体 用于cc
	self:InitOBOjbect()
	------------ 初始化逻辑外物体 ------------

	------------ 初始化随机数配置 ------------
	self:InitRandomManager()
	------------ 初始化随机数配置 ------------

	------------ 初始化战场信息 ------------
	self:InitBattleConfig()
	------------ 初始化战场信息 ------------

	------------ 初始化逻辑内物体 ------------
	-- 初始化全局buff物体
	self:InitGlobalEffect()

	-- 初始化战斗物体
	self:CreateNextWave()

	-- 初始化天气物体
	self:InitWeather()

	-- 初始化主角模型
	self:InitPlayer()

	-- 战斗物体初始化完成 初始化光环
	self:InitHalosEffect()
	------------ 初始化逻辑内物体 ------------

	------------ 初始化一些外部配置 ------------
	-- 初始化事件控制器
	self:InitEventController()

	-- 初始化加速记录
	self:InitTimeScale()

	-- 初始化功能模块
	self:InitFunctionModule()
	------------ 初始化一些外部配置 ------------

	-- 记录一次所有物体的属性
	self:GetBData():RecordStartAliveFriendObjPStr()

	self:ForceAnalyzeRenderOperate()
end
--[[
初始化随机数管理器
--]]
function BattleLogicManager:InitRandomManager()
	local randomManager = __Require('battle.controller.RandomManagerNew').new()
	self:SetRandomManager(randomManager)

	-- 设置一次随机种子
	self:GetRandomManager():SetRandomseed(self:GetRandomseed())
end
--[[
初始化功能模块
--]]
function BattleLogicManager:InitFunctionModule()

end
--[[
初始化一次游戏加速
--]]
function BattleLogicManager:InitTimeScale()
	local timeScale = self:GetBattleConstructData().gameTimeScale

	-- 初始化加速记录
	self:SetTimeScale(timeScale)

	--***---------- 刷新渲染层 ----------***--
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'SetBattleTimeScale',
		timeScale
	)
	--***---------- 刷新渲染层 ----------***--
end
---------------------------------------------------
-- init battle logic end --
---------------------------------------------------

---------------------------------------------------
-- init battle obj begin --
---------------------------------------------------
--[[
初始化ob物体 用于cc
--]]
function BattleLogicManager:InitOBOjbect()
	local isEnemy = false
	local location = ObjectLocation.New(0, 0, 0, 0)

	local objInfo = ObjectConstructorStruct.New(
		nil, location, 1, BattleObjectFeature.BASE, ConfigCardCareer.BASE, isEnemy,
		nil, nil, nil, nil, false, nil,
		nil, nil, nil,
		nil
	)

	local tag = self:GetBData():GetTagByTagType(BattleTags.BT_OBSERVER)
	local objData = ObjectLogicModelConstructorStruct.New(
		ObjectIdStruct.New(tag, BattleElementType.BET_OB),
		objInfo
	)
	local obj = __Require('battle.object.logicModel.objectModel.OBObjectModel').new(objData)
	self:GetBData():AddAOBLogicModel(obj)
	self:GetBData():SetOBObject(obj)
end
--[[
初始化全局效果
--]]
function BattleLogicManager:InitGlobalEffect()
	local isEnemy = false
	local location = ObjectLocation.New(0, 0, 0, 0)

	local objInfo = ObjectConstructorStruct.New(
		nil, location, 1, BattleObjectFeature.BASE, ConfigCardCareer.BASE, isEnemy,
		nil, nil, nil, nil, false, nil,
		nil, nil, nil,
		nil
	)

	local tag = self:GetBData():GetTagByTagType(BattleTags.BT_GLOBAL_EFFECT)
	local objData = ObjectLogicModelConstructorStruct.New(
		ObjectIdStruct.New(tag, BattleElementType.BET_OB),
		objInfo
	)
	local obj = __Require('battle.object.logicModel.objectModel.GlobalEffectObjectModel').new(objData)
	self:GetBData():SetGlobalEffectObj(obj)

	------------ 初始化全局效果 ------------
	-- 全局效果技能
	if QuestBattleType.TOWER == self:GetQuestBattleType() then
		obj:AddTowerEffects(self:GetGlobalEffects())
	else
		obj:AddSkills(self:GetGlobalEffects())
	end
	-- 工会神兽技能
	obj:AddUnionPetsEffect(nil)

	-- 跑一次其他类型的效果
	self:InitSceneSkillEffect()
	------------ 初始化全局效果 ------------
end
--[[
初始化天气
--]]
function BattleLogicManager:InitWeather()
	local weatherInfo = self:GetBData():GetStageWeatherConfig()

	if nil ~= weatherInfo then

		local weatherConfig = nil
		local isEnemy = false
		local location = ObjectLocation.New(0, 0, 0, 0)

		for _, weatherId_ in ipairs(weatherInfo) do

			local weatherId = checkint(weatherId_)
			weatherConfig = CommonUtils.GetConfig('quest', 'weather', weatherId)

			if nil ~= weatherConfig then

				local objInfo = ObjectConstructorStruct.New(
					weatherId, location, 1, BattleObjectFeature.BASE, ConfigCardCareer.BASE, isEnemy,
					nil, nil, nil, nil, false, nil,
					nil, nil, nil,
					nil
				)
				local tag = self:GetBData():GetTagByTagType(BattleTags.BT_WEATHER)

				local objData = ObjectLogicModelConstructorStruct.New(
					ObjectIdStruct.New(tag, BattleElementType.BET_WEATHER),
					objInfo
				)
				local obj = __Require('battle.object.logicModel.objectModel.WeatherObjectModel').new(objData)

				self:GetBData():AddAOtherLogicModel(obj)
			end

		end

	end
end
--[[
初始化主角模型
--]]
function BattleLogicManager:InitPlayer()
	-- 友方主角
	local friendPlayerCampType = false
	local friendPlayerSkills = self:GetPlayerSkilInfo(friendPlayerCampType)
	local location = ObjectLocation.New(0, 0, 0, 0)
	local objInfo = ObjectConstructorStruct.New(
		ConfigSpecialCardId.PLAYER, location, 1, BattleObjectFeature.BASE, ConfigCardCareer.BASE, friendPlayerCampType,
		nil, friendPlayerSkills, nil, nil, false, nil,
		nil, nil, nil,
		nil
	)
	local tag = self:GetBData():GetTagByTagType(BattleTags.BT_FRIEND_PLAYER)
	local objData = ObjectLogicModelConstructorStruct.New(
		ObjectIdStruct.New(tag, BattleElementType.BET_PLAYER),
		objInfo
	)
	local obj = __Require('battle.object.logicModel.objectModel.BasePlayerObjectModel').new(objData)

	self:GetBData():AddAOtherLogicModel(obj)

	-- 敌方主角
	local enemyCampType = true
	local enemyPlayerSkills = self:GetPlayerSkilInfo(enemyCampType)
	if nil ~= enemyPlayerSkills then
		local location = ObjectLocation.New(0, 0, 0, 0)
		local objInfo = ObjectConstructorStruct.New(
			ConfigSpecialCardId.PLAYER, location, 1, BattleObjectFeature.BASE, ConfigCardCareer.BASE, enemyCampType,
			nil, enemyPlayerSkills, nil, nil, false, nil,
			nil, nil, nil,
			nil
		)
		local tag = self:GetBData():GetTagByTagType(BattleTags.BT_ENEMY_PLAYER)
		local objData = ObjectLogicModelConstructorStruct.New(
			ObjectIdStruct.New(tag, BattleElementType.BET_PLAYER),
			objInfo
		)
		local obj = __Require('battle.object.logicModel.objectModel.EnemyPlayerObjectModel').new(objData)

		self:GetBData():AddAOtherLogicModel(obj)
	end
end
---------------------------------------------------
-- init battle obj end --
---------------------------------------------------

---------------------------------------------------
-- battle config begin --
---------------------------------------------------
--[[
初始化战场信息
--]]
function BattleLogicManager:InitBattleConfig()
	-- 战斗区域是大小定死的矩形
	local designScreenSize = cc.size(1334, 750)

	-- 战斗背景图大小
	local designBgImgSize = cc.size(1334, 1002)

	-- 基础配置 原点配置
	local oriL, oriR, oriB, oriT = 0, 1334, 200, 530
	local oriW = oriR - oriL
	local oriH = oriT - oriB

	-- 战斗区域原点位置
	local x = designBgImgSize.width * 0.5 - oriW * 0.5
	local y = oriB + designScreenSize.height * 0.5 - designBgImgSize.height * 0.5

	-- 战斗区域信息
	local battleArea = cc.rect(x, y, oriW, oriH)

	-- 战斗区域中最长直线距离
	local battleAreaMaxDis = battleArea.width * battleArea.width + battleArea.height * battleArea.height

	-- 战斗区域中总行数
	local totalRow = 5

	-- 战斗区域中总列数
	local totalCol = 30

	-- 战斗区域中的cellsize
	local cellSizeWidth = battleArea.width / totalCol
	local cellSizeHeight = battleArea.height / totalRow
	local cellSize = cc.size(cellSizeWidth, cellSizeHeight)

	local bconf = {
		BATTLE_AREA 				= battleArea,
		BATTLE_AREA_MAX_DIS 		= battleAreaMaxDis,
		ROW 						= totalRow,
		COL 						= totalCol,
		cellSizeWidth 				= cellSizeWidth,
		cellSizeHeight 				= cellSizeHeight,
		cellSize 					= cellSize,
		designScreenSize 			= designScreenSize,
	}
	self:SetBConf(bconf)

	-- 初始化格子信息
	self:InitCellsCoordinate()
end
--[[
初始化战斗格子坐标
--]]
function BattleLogicManager:InitCellsCoordinate()
	local bconf = self:GetBConf()

	bconf.cellsCoordinate = {}

	for r = 1, bconf.ROW do

		if nil == bconf.cellsCoordinate[r] then
			-- 初始化一次行集合
			bconf.cellsCoordinate[r] = {}
		end

		for c = 1, bconf.COL do

			bconf.cellsCoordinate[r][c] = {
				cx = bconf.BATTLE_AREA.x + bconf.cellSize.width * 0.5 + ((c - 1) * bconf.cellSize.width),
				cy = bconf.BATTLE_AREA.y + bconf.cellSize.height * 0.5 + ((r - 1) * bconf.cellSize.height),
				box = cc.rect(
					bconf.BATTLE_AREA.x + ((c - 1) * bconf.cellSize.width),
					bconf.BATTLE_AREA.y + ((r - 1) * bconf.cellSize.height),
					bconf.cellSize.width,
					bconf.cellSize.height
				)
			}

		end

	end
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
function BattleLogicManager:GetCellPosByRC(r, c)
	local bconf = self:GetBConf()

	if (r >= 1 and r <= bconf.ROW) and
		(c >= 1 and c <= bconf.COL) then

		return bconf.cellsCoordinate[r][c]

	else

		-- 超边坐标
		return {
			cx = bconf.BATTLE_AREA.x + bconf.cellSize.width * 0.5 + ((c - 1) * bconf.cellSize.width),
			cy = bconf.BATTLE_AREA.y + bconf.cellSize.height * 0.5 + ((r - 1) * bconf.cellSize.height),
			box = cc.rect(
				bconf.BATTLE_AREA.x + ((c - 1) * bconf.cellSize.width),
				bconf.BATTLE_AREA.y + ((r - 1) * bconf.cellSize.height),
				bconf.cellSize.width,
				bconf.cellSize.height
			)
		
		}
	end
end
--[[
根据坐标获取row col 纵向边界算下面一格 横向边界算右边一格
@params p cc.p 坐标
@return {r, c} table 行列 
--]]
function BattleLogicManager:GetRowColByPos(p)
	local bconf = self:GetBConf()

	local fixP = cc.p(p.x - bconf.BATTLE_AREA.x, p.y - bconf.BATTLE_AREA.y)
	return {r = math.ceil(fixP.y / bconf.cellSize.height), c = math.floor(fixP.x / bconf.cellSize.width) + 1}
end
--[[
获取屏幕设计尺寸
@return _ cc.size
--]]
function BattleLogicManager:GetDesignScreenSize()
	return self:GetBConf().designScreenSize
end
--[[
获取战斗配置的单格的size
@return _ cc.size
--]]
function BattleLogicManager:GetCellSize()
	return self:GetBConf().cellSize
end
---------------------------------------------------
-- battle config end --
---------------------------------------------------

---------------------------------------------------
-- battle control begin --
---------------------------------------------------
--[[
游戏是否结束
@return _ BattleResult 判断结果
--]]
function BattleLogicManager:IsGameOver()
	return self:GetEndDriver():CanDoLogic()
end
---------------------------------------------------
-- battle control end --
---------------------------------------------------

---------------------------------------------------
-- battle wave change end --
---------------------------------------------------
--[[
创建下一波敌人 在此处将波数+1
--]]
function BattleLogicManager:CreateNextWave()
	self:GetBattleDriver(BattleDriverType.SHIFT_DRIVER):OnCreateNextWaveEnter()
end
--[[
进入下一波
@params dt number 
--]]
function BattleLogicManager:EnterNextWave(dt)
	self:GetBattleDriver(BattleDriverType.SHIFT_DRIVER):OnLogicEnter(dt)
end
--[[
判断是否能进入下一波 判断动画是否播完
@params dt number
@return result bool 是否能进入下一波
--]]
function BattleLogicManager:CanEnterNextWave(dt)
	return self:GetBattleDriver(BattleDriverType.SHIFT_DRIVER):CanEnterNextWave(dt)
end
--[[
准备开始下一波
--]]
function BattleLogicManager:ReadyStartNextWave()
	local bdata = self:GetBData()

	--***---------- 刷新渲染层 ----------***--
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'ShowEnterNextWave',
		bdata:GetCurrentWave(),
		bdata:NextWaveHasElite(),
		bdata:NextWaveHasBoss()
	)
	--***---------- 刷新渲染层 ----------***--

	if self:IsCalculator() then
		--###---------- 刷新逻辑层 ----------###--
		-- 此处直接插入操作
		self:AddPlayerOperate2TimeLine(
			'G_BattleLogicMgr',
			ANITIME_NEXT_WAVE_REMIND,
			'RenderStartNextWaveHandler'
		)
		--###---------- 刷新逻辑层 ----------###--
	end
end
--[[
开始下一波
--]]
function BattleLogicManager:StartNextWave()
	local sk = sortByKey(self:GetBData().battleObjs)
	local obj = nil

	for _, key in ipairs(sk) do

		obj = self:GetBData().battleObjs[key]
		obj:AwakeObject()

	end

	self:SetGState(GState.START)

	-- 设置触摸可用
	self:SetBattleTouchEnable(true)
end
---------------------------------------------------
-- battle wave change end --
---------------------------------------------------

---------------------------------------------------
-- battle update begin --
---------------------------------------------------
--[[
主循环
--]]
function BattleLogicManager:MainUpdate(dt)
	-- 自增一次逻辑帧帧数
	self:GetBData():AddLogicFrameIndex()
	-- print('here check logic frame index in ->BattleLogicManager:MainUpdate<-', self:GetBData():GetLogicFrameIndex())

	-- 初始化渲染层数据
	self:GetBData():InitNextRenderOperate()

	-- 先分析手操内容 再跑逻辑帧
	self:AnalyzePlayerOperate()

	-- 初始化玩家手操数据
	self:GetBData():InitNextPlayerOperate(true)

	if GState.OVER == self:GetGState() then return end

	-- 主循环被暂停 跳出
	if self:IsMainLogicPause() then return end

	-- 走逻辑帧
	self:LogicMainUpdate(dt)
end
--[[
逻辑帧update逻辑
@params dt number deltaTime
@params onlyLogic bool 是否仅逻辑 不创建界面
--]]
function BattleLogicManager:LogicMainUpdate(dt, onlyLogic)
	-- if not self:CanEnterNextLogicUpdate() then return end

	------------ 规则外物体逻辑 ------------
	for i = #self:GetBData().sortOBObjs, 1, -1 do
		self:GetBData().sortOBObjs[i]:Update(dt)
	end
	------------ 规则外物体逻辑 ------------

	------------ object view ------------
	self:UpdateViewModel(dt)
	------------ object view ------------

	if GState.START == self:GetGState() then

		------------ 转阶段信息最优先判断 ------------
		local needReturnLogic = self:UpdatePhaseChange(dt)
		if true == needReturnLogic then
			return
		end
		------------ 转阶段信息最优先判断 ------------

		------------ 判断游戏是否应该结束 ------------
		local result = self:IsGameOver()
		needReturnLogic = self:GetEndDriver():OnLogicEnter(result)
		if true == needReturnLogic then
			return
		end
		------------ 判断游戏是否应该结束 ------------

		------------ time logic ------------
		if not self:IsTimerPause() then
			self:UpdateTimer(dt)
		end
		------------ time logic ------------

		------------ object logic ------------
		self:UpdateLogicModel(dt)
		------------ object logic ------------

	elseif GState.TRANSITION == self:GetGState() then

		self:EnterNextWave(dt)

	elseif GState.SUCCESS == self:GetGState() then

		if true ~= onlyLogic then
			self:GameSuccess(dt)
		end
		return PassedBattle.SUCCESS

	elseif GState.FAIL == self:GetGState() then

		if true ~= onlyLogic then
			self:GameFail(dt)
		end
		return PassedBattle.FAIL

	elseif GState.BLOCK == self:GetGState() then

		self:GameRescue(dt)

	end

	-- print('here one logic frame over ==================== \n')
end
--[[
从帧角度判断是否可以进行下一个逻辑帧
--]]
function BattleLogicManager:CanEnterNextLogicUpdate()
	if -1 == LOGIC_FRAME_ADVANCE then return true end

	return self:GetBData():GetLogicFrameIndex() - self:GetBData():GetRenderFrameIndex() <= LOGIC_FRAME_ADVANCE
end
--[[
刷一次展示层模型
--]]
function BattleLogicManager:UpdateViewModel(dt)
	-- logs('<<<<<<<<<<<<< BattleLogicManager:Update [View] Model <<<<<<<<<<<<<<<', self:GetBData():GetLogicFrameIndex())
	local viewModel = nil

	for i = #self:GetBData().sortObjViewModels, 1, -1 do
		viewModel = self:GetBData().sortObjViewModels[i]
		viewModel:Update(dt)
	end
end
--[[
刷新逻辑层模型
--]]
function BattleLogicManager:UpdateLogicModel(dt)
	-- logs('>>>>>>>>>>>>> BattleLogicManager:Update [Logic] Model >>>>>>>>>>>>>>>', self:GetBData():GetLogicFrameIndex())
	local objs = nil
	local obj = nil

	-- 逻辑内其他物体
	objs = self:GetOtherLogicObjs()
	for i = #objs, 1, -1 do
		obj = objs[i]
		obj:Update(dt)
	end

	-- 所有子弹
	objs = self:GetBulletObjs()
	for i = #objs, 1, -1 do
		obj = objs[i]
		obj:Update(dt)
	end

	-- 存活的战斗物体
	objs = self:GetAliveBattleObjs(false)
	for i = #objs, 1, -1 do
		obj = objs[i]
		obj:Update(dt)
	end
	objs = self:GetAliveBattleObjs(true)
	for i = #objs, 1, -1 do
		obj = objs[i]
		obj:Update(dt)
	end
	objs = self:GetAliveBeckonObjs()
	for i = #objs, 1, -1 do
		obj = objs[i]
		obj:Update(dt)
	end
end
--[[
刷新时间
--]]
function BattleLogicManager:UpdateTimer(dt)
	-- 刷新计时
	self:GetBData():SetLeftTime(math.max(0, self:GetBData():GetLeftTime() - dt))
	-- logs('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ BattleLogicManager:UpdateTimer', self:GetBData():GetLeftTime())
	-- 刷新战斗结束驱动
	self:GetEndDriver():OnLogicUpdate(dt)

	--***---------- 刷新渲染层 ----------***--
	self:AddRenderOperate(
		'G_BattleRenderMgr',
		'RefreshTimeLabel',
		self:GetBData():GetLeftTime()
	)
	--***---------- 刷新渲染层 ----------***--
end
--[[
分析玩家手操内容
--]]
function BattleLogicManager:AnalyzePlayerOperate()
	local operates = self:GetBData():GetNextPlayerOperate()
	-- print('here check fuck daaaaaaaaaaaaaaaaaaaaaa, ', self:GetBData():GetLogicFrameIndex())
	-- dump(operates)
	if nil ~= operates then
		for _, operate in ipairs(operates.operate) do
			local functionName = operate.functionName
			local params = operate.variableParams

			if nil ~= self[functionName] then
				self[functionName](self, unpack(params, 1, operate.maxParams))
			end
			

		end
	end
end
--[[
走一帧转阶段的逻辑
@params dt number delta time
@return needReturnLogic bool 是否需要阻塞主逻辑
--]]
function BattleLogicManager:UpdatePhaseChange(dt)
	local needReturnLogic = false
	local triggerPhaseNpcTag = nil
	local triggerPhaseNpc = nil
	local phaseData = nil

	local dt_ = dt

	-- 非阻塞型
	local phaseChangeDatas = self:GetBData():GetNextPhaseChange(false)

	for i = #phaseChangeDatas, 1, -1 do

		phaseData = phaseChangeDatas[i]
		triggerPhaseNpcTag = phaseData.objTag
		triggerPhaseNpc = self:IsObjAliveByTag(triggerPhaseNpcTag)

		if 0 >= phaseData.delayTime then

			-- 延迟时间结束
			if nil ~= triggerPhaseNpc then
				-- 进行阶段转换
				triggerPhaseNpc.phaseDriver:OnActionEnter(phaseData.index)

				-- 如果是死亡触发 计数器-1
				if true == phaseData.isDieTrigger then
					triggerPhaseNpc.phaseDriver:SetDiePhaseChangeCounter(triggerPhaseNpc.phaseDriver:GetDiePhaseChangeCounter() - 1)
					-- 死亡转阶段需要阻塞主逻辑
					needReturnLogic = true
				end

				-- 发送一次触发转阶段的事件
				self:SendObjEvent(ObjectEvent.OBJECT_PHASE_CHANGE, {
					triggerPhaseNpcTag = triggerPhaseNpcTag,
					phaseId = phaseData.phaseId
				})
			end

			-- 移除该转阶段信息
			self:GetBData():RemoveAPhaseChange(false, i)

		else

			-- 延迟时间未结束
			phaseData.delayTime = math.max(0, phaseData.delayTime - dt_)

		end

	end

	-- 阻塞型
	phaseChangeDatas = self:GetBData():GetNextPhaseChange(true)

	for i = #phaseChangeDatas, 1, -1 do

		phaseData = phaseChangeDatas[i]
		triggerPhaseNpcTag = phaseData.objTag
		triggerPhaseNpc = self:IsObjAliveByTag(triggerPhaseNpcTag)

		if 0 >= phaseData.delayTime then

			-- 延迟时间结束
			if nil ~= triggerPhaseNpc then
				-- 进行阶段转换
				triggerPhaseNpc.phaseDriver:OnActionEnter(phaseData.index)

				-- 如果是死亡触发 计数器-1
				if true == phaseData.isDieTrigger then
					triggerPhaseNpc.phaseDriver:SetDiePhaseChangeCounter(triggerPhaseNpc.phaseDriver:GetDiePhaseChangeCounter() - 1)
					-- 死亡转阶段需要阻塞主逻辑
					needReturnLogic = true
				end

				-- 发送一次触发转阶段的事件
				self:SendObjEvent(ObjectEvent.OBJECT_PHASE_CHANGE, {
					triggerPhaseNpcTag = triggerPhaseNpcTag,
					phaseId = phaseData.phaseId
				})
			end

			-- 移除该转阶段信息
			self:GetBData():RemoveAPhaseChange(true, i)
			return true

		else

			-- 延迟时间未结束
			phaseData.delayTime = math.max(0, phaseData.delayTime - dt_)

		end

	end

	return needReturnLogic
end
---------------------------------------------------
-- battle update end --
---------------------------------------------------

---------------------------------------------------
-- battle logic pause begin --
---------------------------------------------------
--[[
暂停整场战斗
--]]
function BattleLogicManager:PauseGame()
	-- 禁用触摸
	self:SetBattleTouchEnable(false)

	-- 暂停主逻辑
	self:PauseMainLogic()
	-- 暂停计时器
	self:PauseTimer()
	-- 暂停所有物体
	self:PauseBattleObjects()

	--***---------- 刷新渲染层 ----------***--
	self:AddRenderOperate(
		'G_BattleRenderMgr',
		'PauseGame'
	)
	--***---------- 刷新渲染层 ----------***--
end
function BattleLogicManager:ResumeGame()
	-- 恢复主逻辑
	self:ResumeMainLogic()
	-- 恢复计时器
	self:ResumeTimer()
	-- 恢复所有物体
	self:ResumeBattleObjects()

	-- 启用触摸
	self:SetBattleTouchEnable(true)

	--***---------- 刷新渲染层 ----------***--
	self:AddRenderOperate(
		'G_BattleRenderMgr',
		'ResumeGame'
	)
	--***---------- 刷新渲染层 ----------***--
end
--[[
暂停主循环
--]]
function BattleLogicManager:PauseMainLogic()
	self:GetBData().isPause = true
end
function BattleLogicManager:ResumeMainLogic()
	self:GetBData().isPause = false
end
function BattleLogicManager:IsMainLogicPause()
	return self:GetBData().isPause
end
--[[
暂停倒计时
--]]
function BattleLogicManager:PauseTimer()
	self:GetBData().isPauseTimer = true
end

function BattleLogicManager:ResumeTimer()
	self:GetBData().isPauseTimer = false
end
function BattleLogicManager:IsTimerPause()
	return self:GetBData().isPauseTimer
end
--[[
暂停所有战斗物体
@params ex map 排除的物体tag
--]]
function BattleLogicManager:PauseBattleObjects(ex)
	ex = ex or {}

	local objs = nil
	local obj = nil

	-- 逻辑内的其他物体
	objs = self:GetOtherLogicObjs()
	for i = #objs, 1, -1 do
		obj = objs[i]
		if nil == ex[obj:GetOTag()] then
			obj:PauseLogic()
		end
	end

	-- 友方卡牌物体
	objs = self:GetAliveBattleObjs(false)
	for i = #objs, 1, -1 do
		obj = objs[i]
		if nil == ex[obj:GetOTag()] then
			obj:PauseLogic()
		end
	end

	-- 敌方卡牌物体
	objs = self:GetAliveBattleObjs(true)
	for i = #objs, 1, -1 do
		obj = objs[i]
		if nil == ex[obj:GetOTag()] then
			obj:PauseLogic()
		end
	end

	-- 召唤物
	objs = self:GetAliveBeckonObjs()
	for i = #objs, 1, -1 do
		obj = objs[i]
		if nil == ex[obj:GetOTag()] then
			obj:PauseLogic()
		end
	end

	-- 休息区物体
	objs = self:GetRestObjs()
	for i = #objs, 1, -1 do
		obj = objs[i]
		if nil == ex[obj:GetOTag()] then
			obj:PauseLogic()
		end
	end

	-- 子弹
	objs = self:GetBulletObjs()
	for i = #objs, 1, -1 do
		obj = objs[i]
		if nil == ex[obj:GetOTag()] then
			obj:PauseLogic()
		end
	end

	-- 死亡物体
	objs = self:GetDeadBattleObjs(false)
	for i = #objs, 1, -1 do
		obj = objs[i]
		if nil == ex[obj:GetOTag()] then
			obj:PauseLogic()
		end
	end
	objs = self:GetDeadBattleObjs(true)
	for i = #objs, 1, -1 do
		obj = objs[i]
		if nil == ex[obj:GetOTag()] then
			obj:PauseLogic()
		end
	end

	-- 死亡的召唤物
	objs = self:GetDeadBeckonObjs()
	for i = #objs, 1, -1 do
		obj = objs[i]
		if nil == ex[obj:GetOTag()] then
			obj:PauseLogic()
		end
	end
end
function BattleLogicManager:ResumeBattleObjects(ex)
	ex = ex or {}

	local objs = nil
	local obj = nil

	-- 逻辑内的其他物体
	objs = self:GetOtherLogicObjs()
	for i = #objs, 1, -1 do
		obj = objs[i]
		if nil == ex[obj:GetOTag()] then
			obj:ResumeLogic()
		end
	end

	-- 友方卡牌物体
	objs = self:GetAliveBattleObjs(false)
	for i = #objs, 1, -1 do
		obj = objs[i]
		if nil == ex[obj:GetOTag()] then
			obj:ResumeLogic()
		end
	end

	-- 敌方卡牌物体
	objs = self:GetAliveBattleObjs(true)
	for i = #objs, 1, -1 do
		obj = objs[i]
		if nil == ex[obj:GetOTag()] then
			obj:ResumeLogic()
		end
	end

	-- 召唤物
	objs = self:GetAliveBeckonObjs()
	for i = #objs, 1, -1 do
		obj = objs[i]
		if nil == ex[obj:GetOTag()] then
			obj:ResumeLogic()
		end
	end

	-- 休息区物体
	objs = self:GetRestObjs()
	for i = #objs, 1, -1 do
		obj = objs[i]
		if nil == ex[obj:GetOTag()] then
			obj:ResumeLogic()
		end
	end

	-- 子弹
	objs = self:GetBulletObjs()
	for i = #objs, 1, -1 do
		obj = objs[i]
		if nil == ex[obj:GetOTag()] then
			obj:ResumeLogic()
		end
	end

	-- 死亡物体
	objs = self:GetDeadBattleObjs(false)
	for i = #objs, 1, -1 do
		obj = objs[i]
		if nil == ex[obj:GetOTag()] then
			obj:ResumeLogic()
		end
	end
	objs = self:GetDeadBattleObjs(true)
	for i = #objs, 1, -1 do
		obj = objs[i]
		if nil == ex[obj:GetOTag()] then
			obj:ResumeLogic()
		end
	end

	-- 死亡的召唤物
	objs = self:GetDeadBeckonObjs()
	for i = #objs, 1, -1 do
		obj = objs[i]
		if nil == ex[obj:GetOTag()] then
			obj:ResumeLogic()
		end
	end
end
--[[
ci场景暂停逻辑
@params sceneTag int 场景tag
--]]
function BattleLogicManager:CIScenePauseGame(sceneTag)
	self:PauseTimer()
	self:PauseBattleObjects()
	self:PauseNormalCIScene()

	--***---------- 刷新渲染层 ----------***--
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'PauseCISceneStart',
		sceneTag
	)
	--***---------- 刷新渲染层 ----------***--
end
--[[
ci场景恢复逻辑
@params sceneTag int 场景tag
--]]
function BattleLogicManager:CISceneResumeGame(sceneTag)
	self:ResumeTimer()
	self:ResumeBattleObjects()
	self:ResumeNormalCIScene()

	--***---------- 刷新渲染层 ----------***--
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'PauseCISceneOver',
		sceneTag
	)
	--***---------- 刷新渲染层 ----------***--

	self:SetBattleTouchEnable(true)
end
--[[
暂停一般的ci场景
--]]
function BattleLogicManager:PauseNormalCIScene()
	--***---------- 刷新渲染层 ----------***--
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'PauseNormalScene'
	)
	--***---------- 刷新渲染层 ----------***--
end
--[[
恢复一般的ci场景
--]]
function BattleLogicManager:ResumeNormalCIScene()
	--***---------- 刷新渲染层 ----------***--
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'ResumeNormalScene'
	)
	--***---------- 刷新渲染层 ----------***--
end
---------------------------------------------------
-- battle logic pause end --
---------------------------------------------------

---------------------------------------------------
-- app background begin --
---------------------------------------------------
--[[
退后台暂停的逻辑
--]]
function BattleLogicManager:AppEnterBackground()
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

	self:RenderPauseBattleHandler()
	------------ 弹出暂停界面 ------------
end
--[[
从后台返回前台的逻辑
--]]
function BattleLogicManager:AppEnterForeground()

end
---------------------------------------------------
-- app background end --
---------------------------------------------------

---------------------------------------------------
-- battle skill begin --
---------------------------------------------------
--[[
初始化光环
--]]
function BattleLogicManager:InitHalosEffect()
	local objs = nil
	local obj = nil

	-- 逻辑内的其他物体
	objs = self:GetOtherLogicObjs()
	for i = #objs, 1, -1 do
		obj = objs[i]
		obj:CastAllHalos()
	end

	-- 友方卡牌物体
	objs = self:GetAliveBattleObjs(false)
	for i = #objs, 1, -1 do
		obj = objs[i]
		obj:CastAllHalos()
	end

	-- 敌方卡牌物体
	objs = self:GetAliveBattleObjs(true)
	for i = #objs, 1, -1 do
		obj = objs[i]
		obj:CastAllHalos()
	end

	-- 全局效果物体
	self:GetGlobalEffectObj():CastAllHalos()
end
--[[
初始化情景技能效果
--]]
function BattleLogicManager:InitSceneSkillEffect()
	-- 初始化一次情景技能效果
	self:GetGlobalEffectObj():CastAllSceneSkills()
end
---------------------------------------------------
-- battle skill end --
---------------------------------------------------

---------------------------------------------------
-- battle obj begin --
---------------------------------------------------
--[[
判断tag对应的obj是否存活
@params tag int obj tag
@return result obj 存活直接返回obj指针 否则返回nil
--]]
function BattleLogicManager:IsObjAliveByTag(tag)
	return self:GetBData():IsObjAliveByTag(tag)
end
--[[
判断cardId对应的obj是否存活
@params cardId int card id
@params isEnemy int 是否是敌人
@return result bool 是否存活
--]]
function BattleLogicManager:IsObjAliveByCardId(cardId, isEnemy)
	return self:GetBData():IsObjAliveByCardId(cardId, isEnemy)
end
--[[
根据tag获取obj 无视死活
@params tag int obj tag
@return result obj 理论上不应该存在返回的obj为空的情况
--]]
function BattleLogicManager:GetObjByTagForce(tag)
	return self:GetBData():GetObjByTagForce(tag)
end
--[[
强制获取cardId对应的obj
@params cardId int card id
@params isEnemy int 是否是敌人
@return result bool 
--]]
function BattleLogicManager:GetObjByCardIdForce(cardId, isEnemy)
	return self:GetBData():GetObjByCardIdForce(id, isEnemy)
end
--[[
创建一个battleObj
@params tag int 唯一tag
@params objInfo ObjectConstructorStruct 战斗物体构造参数
@return obj BaseObj
--]]
function BattleLogicManager:GetABattleObj(tag, objInfo)
	local objClassName = 'battle.object.logicModel.objectModel.CardObjectModel'

	local objData = ObjectLogicModelConstructorStruct.New(
		ObjectIdStruct.New(tag, BattleElementType.BET_CARD),
		objInfo
	)
	local obj = __Require(objClassName).new(objData)

	self:GetBData():AddABattleObjLogicModel(obj)

	return obj
end
--[[
创建一个beckon obj
@params tag int 唯一tag
@params objInfo ObjectConstructorStruct 战斗物体构造参数
@return obj BaseObj
--]]
function BattleLogicManager:GetABeckonObj(tag, objInfo)
	local objClassName = 'battle.object.logicModel.objectModel.BeckonObjectModel'

	local objData =  ObjectLogicModelConstructorStruct.New(
		ObjectIdStruct.New(tag, BattleElementType.BET_CARD),
		objInfo
	)
	local obj = __Require(objClassName).new(objData)

	self:GetBData():AddABeckonObjLogicModel(obj)

	return obj
end
--[[
获取死亡对象
@params tag int objtag
@return result obj 死亡直接返回obj指针 否则返回nil
--]]
function BattleLogicManager:GetDeadObjByTag(tag)
	if nil == tag then return nil end
	local result = nil
	tag = checkint(tag)
	local tagType = self:GetBData():GetBattleTagType(tag)
	if BattleTags.BT_FRIEND == tagType or 
		BattleTags.BT_CONFIG_ENEMY == tagType or 
		BattleTags.BT_OTHER_ENEMY == tagType or 
		BattleTags.BT_BECKON == tagType or 
		BattleTags.BT_BULLET == tagType then
		result = self:GetBData().dustObjs[tostring(tag)]
	end
	return result
end
--[[
根据tag获取战斗元素类型 不从战斗物体获取
@params tag int 目标tag
@params _ BattleElementType 战斗元素类型
--]]
function BattleLogicManager:GetBattleElementTypeByTag(tag)
	return self:GetBData():GetBattleElementTypeByTag(tag)
end
--[[
获取一个qte attach 物体
@params qteBuffsInfo QTEAttachObjectConstructStruct qte数据信息
@return qteAttachModel BaseAttachModel qte物体模型
--]]
function BattleLogicManager:GetAQTEAttachObject(qteBuffsInfo)
	-- 创建一个qte点击物体 加入内存
	local idInfo = ObjectIdStruct.New(
		G_BattleLogicMgr:GetBData():GetTagByTagType(BattleTags.BT_QTE_ATTACH),
		BattleElementType.BASE
	)
	local data = ObjectLogicModelConstructorStruct.New(
		idInfo, qteBuffsInfo
	)

	local qteAttachModel = QTEAttachModel.new(data)

	return qteAttachModel
end
---------------------------------------------------
-- battle obj end --
---------------------------------------------------

---------------------------------------------------
-- beckon obj begin --
---------------------------------------------------
--[[
是否可以创建qte召唤物
--]]
function BattleLogicManager:CanCreateBeckonFromBuff()
	return self:GetBData():CanCreateBeckonFromBuff()
end
---------------------------------------------------
-- beckon obj end --
---------------------------------------------------







---------------------------------------------------
-- battle driver begin --
---------------------------------------------------
--[[
设置结束驱动
@params wave int 波数
@params battleDriver BaseBattleDriver
--]]
function BattleLogicManager:SetEndDriver(wave, battleDriver)
	if nil == self:GetBattleDriver(BattleDriverType.END_DRIVER) then
		self:SetBattleDriver(BattleDriverType.END_DRIVER, {})
	end

	self:GetBattleDriver(BattleDriverType.END_DRIVER)[wave] = battleDriver
end
--[[
获取结束驱动
@params wave int 波数
--]]
function BattleLogicManager:GetEndDriver(wave)
	if nil == wave then
		wave = self:GetBData():GetCurrentWave()
	end
	local endDriver = self:GetBattleDriver(BattleDriverType.END_DRIVER)[wave]
	if nil == endDriver then
		endDriver = self:GetBattleDriver(BattleDriverType.END_DRIVER)[1]
	end
	return endDriver
end
---------------------------------------------------
-- battle driver end --
---------------------------------------------------

---------------------------------------------------
-- skada begin --
---------------------------------------------------
--[[
记录一条skada
@params skadaType SkadaType 伤害统计类型
@params objectTag int 物体tag
@params damageData ObjectDamageStruct 伤害数据
@params trueDamage number 修正的有效伤害数值
--]]
function BattleLogicManager:SkadaWork(skadaType, objectTag, damageData, trueDamage)
	if nil ~= self:GetBattleDriver(BattleDriverType.SKADA_DRIVER) then
		self:GetBattleDriver(BattleDriverType.SKADA_DRIVER):OnLogicEnter(skadaType, objectTag, damageData, trueDamage)
	end
end
--[[
记录物体的映射关系
@params teamIndex int 队伍序号
@params memberIndex int 在队伍中的序号
@params objectTag int 对应的物体tag
@params isEnemy bool 是否为敌人
--]]
function BattleLogicManager:SkadaAddObjectTag(teamIndex, memberIndex, objectTag, isEnemy)
	if nil ~= self:GetBattleDriver(BattleDriverType.SKADA_DRIVER) then
		self:GetBattleDriver(BattleDriverType.SKADA_DRIVER):SkadaAddObjectTag(teamIndex, memberIndex, objectTag, isEnemy)
	end
end
---------------------------------------------------
-- skada end --
---------------------------------------------------

---------------------------------------------------
-- obj event begin --
---------------------------------------------------
--[[
注册事件
@params name string 事件名称
@params obj obj 注册物体
@params callback function 回调
--]]
function BattleLogicManager:AddObjEvent(ename, o, callback)
	if nil == self.objEvents[ename] then
		self.objEvents[ename] = {}
	end
	table.insert(self.objEvents[ename], {tag = o:GetOTag(), callback = callback})
end
--[[
注销事件
@params name string 事件名称
@params obj obj 注册物体
--]]
function BattleLogicManager:RemoveObjEvent(ename, o)
	if nil == self.objEvents[ename] then
		funLog(Logger.INFO,'can not find obj event -> ' .. ename)
	else
		local targetTag = o:GetOTag()
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
function BattleLogicManager:SendObjEvent(ename, ...)
	if nil ~= self.objEvents[ename] then
		local args = unpack({...})
		local callbackInfo = nil

		for i = #self.objEvents[ename], 1, -1 do
			callbackInfo = self.objEvents[ename][i]
			callbackInfo.callback(args)
		end
	end
end
--[[
初始化事件控制器
--]]
function BattleLogicManager:InitEventController()
	self.connectSkillHighlightEvent = __Require('battle.event.ConnectSkillHighlightEvent').new({
		owner = self
	})
end
---------------------------------------------------
-- obj event end --
---------------------------------------------------






---------------------------------------------------
-- bullet logic begin --
---------------------------------------------------
--[[
发射子弹
@params bulletData ObjectSendBulletData 发射子弹传参
--]]
function BattleLogicManager:SendBullet(bulletData)
	-- local parent = self:GetBattleRoot()
	-- local zorder = BATTLE_E_ZORDER.BULLET
	-- -- 处理层级
	-- if ConfigEffectCauseType.SCREEN == bulletData.causeType then

	-- 	-- 全屏 只存在顶部和底部 加到战斗root上
	-- 	zorder = bulletData.bulletZOrder < 0 and 1 or BATTLE_E_ZORDER.BULLET
	-- 	if bulletData.needHighlight then
	-- 		zorder = zorder + self:GetFixedHighlightZOrder()
	-- 	end

	-- elseif ConfigEffectBulletType.SPINE_EFFECT == bulletData.otype and ConfigEffectCauseType.POINT == bulletData.causeType then

	-- 	local target = nil
	-- 	if true == bulletData.targetDead then
	-- 		target = self:GetDeadObjByTag(bulletData.targetTag)
	-- 	else
	-- 		target = self:IsObjAliveByTag(bulletData.targetTag)
	-- 	end

	-- 	if nil ~= target then
	-- 		-- 修正父节点
	-- 		parent = target.view.viewComponent
	-- 		-- 指向 加到物体身上 只存在顶部和底部
	-- 		zorder = bulletData.bulletZOrder < 0 and -1 or BATTLE_E_ZORDER.BULLET
	-- 		-- 修正指向性的子弹位置
	-- 		local fixedPosInView = target.view.viewComponent:convertUnitPosToRealPos(bulletData.fixedPos)
	-- 		-- bulletData.targetLocation = parent:convertToNodeSpace(self:GetBattleRoot():convertToWorldSpace(bulletData.targetLocation))
	-- 		bulletData.targetLocation = fixedPosInView
	-- 	end

	-- elseif ConfigEffectCauseType.SINGLE == bulletData.causeType then

	-- 	-- 范围连接点 真实zorder
	-- 	zorder = self:GetZorderInBattle(bulletData.targetLocation)
	-- 	if bulletData.needHighlight then
	-- 		zorder = zorder + self:GetFixedHighlightZOrder()
	-- 	end

	-- elseif ConfigEffectBulletType.SPINE_UFO_STRAIGHT == bulletData.otype or
	-- 	ConfigEffectBulletType.SPINE_UFO_CURVE == bulletData.otype or
	-- 	ConfigEffectBulletType.SPINE_LASER == bulletData.otype or
	-- 	ConfigEffectBulletType.SPINE_WINDSTICK == bulletData.otype then

	-- 	-- 投掷物 转换一次原始坐标
	-- 	bulletData.oriLocation = parent:convertToNodeSpace(bulletData.oriLocation)
	-- 	if bulletData.needHighlight then
	-- 		zorder = zorder + self:GetFixedHighlightZOrder()
	-- 	end

	-- else

	-- end

	-- local bullet = self:GetABullet(bulletData)
	-- parent:addChild(bullet.view.viewComponent, zorder)
	-- bullet:awake()

	local bullet = self:GetABullet(bulletData)
	bullet:AwakeObject()
end
--[[
创建一发子弹
@params bulletData ObjectSendBulletData 发射子弹传参
@return obj BaseBullet
--]]
function BattleLogicManager:GetABullet(bulletData)
	local className = 'battle.object.logicModel.bulletModel.BaseBulletModel'

	if ConfigEffectBulletType.BASE == bulletData.otype then

		className = 'battle.object.logicModel.bulletModel.BaseBulletModel'

	elseif ConfigEffectBulletType.SPINE_EFFECT == bulletData.otype then

		className = 'battle.object.logicModel.bulletModel.BaseSpineBulletModel'

	elseif ConfigEffectBulletType.SPINE_PERSISTANCE == bulletData.otype then

		className = 'battle.object.logicModel.bulletModel.SpinePersistenceBulletModel'

	elseif ConfigEffectBulletType.SPINE_UFO_STRAIGHT == bulletData.otype then

		className = 'battle.object.logicModel.bulletModel.SpineUFOBulletModel'

	elseif ConfigEffectBulletType.SPINE_UFO_CURVE == bulletData.otype then

		className = 'battle.object.logicModel.bulletModel.SpineUFOCurveBulletModel'

	elseif ConfigEffectBulletType.SPINE_WINDSTICK == bulletData.otype then

		className = 'battle.object.logicModel.bulletModel.SpineWindStickBulletModel'

	elseif ConfigEffectBulletType.SPINE_LASER == bulletData.otype then

		className = 'battle.object.logicModel.bulletModel.SpineLaserBulletModel'
		
	else

	end

	local idInfo = ObjectIdStruct.New(
		self:GetBData():GetTagByTagType(BattleTags.BT_BULLET),
		BattleElementType.BET_BULLET
	)
	local objData = ObjectLogicModelConstructorStruct.New(
		idInfo,
		bulletData
	)

	local obj = __Require(className).new(objData)

	self:GetBData():AddABulletModel(obj)

	return obj
end
--[[
判断子弹的特效是否是贴在object view上的
@params bulletData ObjectSendBulletData 发射子弹传参
@return _ bool
--]]
function BattleLogicManager:IsBulletAdd2ObjectView(bulletData)
	local bulletType = bulletData.otype
	local causeType = bulletData.causeType

	if ConfigEffectCauseType.POINT == causeType then
		local config = {
			[ConfigEffectBulletType.SPINE_EFFECT] = true,
			[ConfigEffectBulletType.SPINE_PERSISTANCE] = true
		}

		if true == config[bulletType] then
			return true
		end
	end

	return false
end
---------------------------------------------------
-- bullet logic end --
---------------------------------------------------

---------------------------------------------------
-- conenct skill logic begin --
---------------------------------------------------
--[[
刷新一次所有友军物体连携技状态
@params isEnemy bool 是否是敌军
--]]
function BattleLogicManager:RefreshAllConnectButtons(isEnemy)
	local objs = self:GetAliveBattleObjs(isEnemy)
	local obj = nil

	for i = #objs, 1, -1 do
		obj = objs[i]
		--***---------- 刷新渲染层 ----------***--
		self:AddRenderOperate(
			'G_BattleRenderMgr',
			'RefreshObjectConnectButtons',
			obj:GetOTag(),
			obj:GetEnergyPercent(), obj:CanAct(), obj:GetState(), not obj:CanCastConnectByAbnormalState()
		)
		--***---------- 刷新渲染层 ----------***--
	end
end
--[[
进攻方 是否可以装载连携技
@return _ bool 是否可以装载连携技
--]]
function BattleLogicManager:CanUseFriendConnectSkill()
	return self:GetBattleConstructData().enableConnect
end
--[[
进攻方 是否自动释放连携技
@return _ bool 是否自动释放连携技
--]]
function BattleLogicManager:AutoUseFriendConnectSkill()
	return self:GetBattleConstructData().autoConnect
end
--[[
防守方 是否可以装载连携技
@return _ bool 是否可以装载连携技
--]]
function BattleLogicManager:CanUseEnemyConnectSkill()
	return self:GetBattleConstructData().enemyEnableConnect
end
--[[
防守方 是否自动释放连携技
@return _ bool 是否自动释放连携技
--]]
function BattleLogicManager:AutoUseEnemyConnectSkill()
	return self:GetBattleConstructData().enemyAutoConnect
end
--[[
连携技场景开始回调
@params tag int obj tag
@params skillId int 技能id
@params sceneTag int 场景tag
--]]
function BattleLogicManager:ConnectCISceneEnter(tag, skillId, sceneTag)
	BattleUtils.PrintBattleActionLog(string.format('ConnectCISceneEnter [tag=%s, skillId = %s, senceTag = %s] (frame %d)', 
		tostring(tag), 
		tostring(skillId), 
		tostring(sceneTag), 
		self:GetBData():GetLogicFrameIndex()
	))
	self:CIScenePauseGame(sceneTag)
end
--[[
连携技场景结束回调
@params tag int obj tag
@params skillId int 技能id
@params sceneTag int 场景tag
--]]
function BattleLogicManager:ConnectCISceneExit(tag, skillId, sceneTag)
	BattleUtils.PrintBattleActionLog(string.format('ConnectCISceneExit [tag=%s, skillId = %s, senceTag = %s] (frame %d)', 
		tostring(tag), 
		tostring(skillId), 
		tostring(sceneTag), 
		self:GetBData():GetLogicFrameIndex()
	))
	self:CISceneResumeGame()

	-- 连携技物体进入施法
	local obj = self:IsObjAliveByTag(tag)
	if nil ~= obj then
		obj.castDriver:OnConnectSkillCastEnter(skillId)
	end
end
---------------------------------------------------
-- conenct skill logic end --
---------------------------------------------------

---------------------------------------------------
-- highlight begin --
---------------------------------------------------
--[[
高亮逻辑
@params skillId int 技能id
@params casterTag int 施法者tag
@params targets list 目标集合
--]]
function BattleLogicManager:ConnectSkillHighlightEventEnter(skillId, casterTag, targets)
	self.connectSkillHighlightEvent:OnEventEnter(skillId, casterTag, targets)
end
function BattleLogicManager:ConnectSkillHighlightEventExit(skillId, casterTag)
	self.connectSkillHighlightEvent:OnEventExit(skillId, casterTag)
end
---------------------------------------------------
-- highlight end --
---------------------------------------------------

---------------------------------------------------
-- boss ci scene begin --
---------------------------------------------------
--[[
bossci场景开始回调
@params tag int obj tag
@params skillId int 技能id
@params sceneTag int 场景tag
--]]
function BattleLogicManager:BossCISceneEnter(tag, skillId, sceneTag)
	self:CIScenePauseGame(sceneTag)
end
--[[
bossci场景结束回调
@params tag int obj tag
@params skillId int 技能id
@params sceneTag int 场景tag
--]]
function BattleLogicManager:BossCISceneExit(tag, skillId, sceneTag)
	self:CISceneResumeGame(sceneTag)

	-- boss开始释放技能
	local obj = self:IsObjAliveByTag(tag)
	if nil ~= obj then
		obj.castDriver:OnCastEnter(skillId)
	end
end
---------------------------------------------------
-- boss ci scene end --
---------------------------------------------------

---------------------------------------------------
-- game result logic begin --
---------------------------------------------------
--[[
游戏结束
@params gameResult BattleResult 3 成功 4 失败 
--]]
function BattleLogicManager:GameOver(gameResult)
	self:GetEndDriver():GameOver(gameResult)
end
--[[
游戏胜利
--]]
function BattleLogicManager:GameSuccess(dt)
	if not self:CanEnterNextWave(dt) then return end

	-- 设置游戏状态
	self:SetGState(GState.OVER)

	BattleUtils.PrintBattleWaringLog('here game success !!!')

	local bdata = self:GetBData()
	------------ 所有obj做win动画 ------------
	local objs = nil
	local obj = nil

	objs = self:GetAliveBattleObjs(false)
	for i = #objs, 1, -1 do
		obj = objs[i]
		obj:Win()
	end
	------------ 所有obj做win动画 ------------

	local isPassed = PassedBattle.SUCCESS
	local params = self:GetExitCommonParameters(isPassed)

	--***---------- 刷新渲染层 ----------***--
	G_BattleMgr:GameOver(isPassed, params)
	--***---------- 刷新渲染层 ----------***--
end
--[[
游戏失败
--]]
function BattleLogicManager:GameFail(dt)
	if not self:CanEnterNextWave(dt) then return end

	-- 设置游戏状态
	self:SetGState(GState.OVER)

	BattleUtils.PrintBattleWaringLog('here game failed !!!')

	local isPassed = PassedBattle.FAIL
	local params = self:GetExitCommonParameters(isPassed)

	--***---------- 刷新渲染层 ----------***--
	G_BattleMgr:GameOver(isPassed, params)
	--***---------- 刷新渲染层 ----------***--
end
---------------------------------------------------
-- game result logic end --
---------------------------------------------------

---------------------------------------------------
-- game rescue begin --
---------------------------------------------------
--[[
抢救游戏结果
--]]
function BattleLogicManager:GameRescue(dt)
	if not self:CanEnterNextWave(dt) then return end

	self:SetGState(GState.OVER)

	--***---------- 刷新渲染层 ----------***--
	self:AddRenderOperate(
		'G_BattleRenderMgr',
		'ShowBuyRevivalScene',
		self:GetBData():CanBuyRevivalFree()
	)
	--***---------- 刷新渲染层 ----------***--
end
--[[
取消买活
--]]
function BattleLogicManager:CancelRescue()
	self:GameOver(BattleResult.BR_FAIL)
end
--[[
买活
--]]
function BattleLogicManager:RescueAllFriend()
	-- 处理买活数据
	self:GetBData():AddBuyRevivalTime(1)

	-- 扣除免费买活次数
	self:GetBData():CostBuyRevivalFree()

	--***---------- 刷新渲染层 ----------***--
	local viewModelTags = {}
	local objs = self:GetDeadBattleObjs(false)
	local obj = nil
	for i = #objs, 1, -1 do
		obj = objs[i]
		local viewModelTag = obj:GetViewModelTag()
		if nil ~= viewModelTag then
			table.insert(viewModelTags, viewModelTag)
		end
	end
	self:AddRenderOperate(
		'G_BattleRenderMgr',
		'StartRescueAllFriend',
		viewModelTags
	)
	--***---------- 刷新渲染层 ----------***--
end
--[[
买活成功 重置站位
--]]
function BattleLogicManager:RescueAllFriendComplete()
	local objs = self:GetDeadBattleObjs(false)
	local obj = nil

	for i = #objs, 1, -1 do

		obj = objs[i]
		obj:Revive(1, 0)
		obj:ResetLocation()
		obj:DoAnimation(true, nil, sp.AnimationName.idle, true)

		--***---------- 刷新渲染层 ----------***--
		-- 重置站位
		obj:RefreshRenderViewPosition()
		-- 重置朝向
		obj:RefreshRenderViewTowards()
		-- 重置动画
		obj:RefreshRenderAnimation(true, nil, sp.AnimationName.idle, true)
		--***---------- 刷新渲染层 ----------***--

	end

	objs = self:GetAliveBattleObjs(true)
	for i = #objs, 1, -1 do

		obj = objs[i]
		obj:ResetLocation()
		obj:DoAnimation(true, nil, sp.AnimationName.idle, true)

		--***---------- 刷新渲染层 ----------***--
		-- 重置站位
		obj:RefreshRenderViewPosition()
		-- 重置朝向
		obj:RefreshRenderViewTowards()
		-- 重置动画
		obj:RefreshRenderAnimation(true, nil, sp.AnimationName.idle, true)
		--***---------- 刷新渲染层 ----------***--

	end
end
--[[
买活结束 重开游戏
--]]
function BattleLogicManager:RescueAllFriendOver()
	self:SetGState(GState.START)
	self:SetBattleTouchEnable(true)
end
---------------------------------------------------
-- game rescue end --
---------------------------------------------------

---------------------------------------------------
-- phase change begin --
---------------------------------------------------
--[[
根据卡牌id获取转阶段内容
@params npcId int 卡牌怪物的配表id
--]]
function BattleLogicManager:GetPhaseChangeDataByNpcId(npcId)
	if nil == self:GetBData():GetPhaseChangeData() then
		return nil
	else
		return self:GetBData():GetPhaseChangeData()[tostring(npcId)]
	end
end
--[[
添加一条下一帧即将运行的阶段转换数据
@params pauseLogic bool 是否阻塞主逻辑
@params phaseData ObjectPhaseSturct 触发转阶段的信息
--]]
function BattleLogicManager:AddAPhaseChange(pauseLogic, phaseData)
	self:GetBData():AddAPhaseChange(pauseLogic, phaseData)
end
--[[
根据序号移除一条转阶段信息
@params pauseLogic bool 是否阻塞主逻辑
@params index int 序号
--]]
function BattleLogicManager:RemoveAPhaseChange(pauseLogic, index)
	self:GetBData():RemoveAPhaseChange(pauseLogic, phaseData)
end
---------------------------------------------------
-- phase change end --
---------------------------------------------------

---------------------------------------------------
-- spine calc begin --
---------------------------------------------------
--[[
根据卡牌id获取spine缩放比
@params cardId int 卡牌id
@return scale number spine缩放
--]]
function BattleLogicManager:GetSpineAvatarScaleByCardId(cardId)
	local cardConf = CardUtils.GetCardConfig(cardId)
	
	local avatarId = cardId
	local scale = CARD_DEFAULT_SCALE
	local isMonster = false
	if ConfigSpecialCardId.PLAYER == cardId or ConfigSpecialCardId.WEATHER == cardId then

		scale = CARD_DEFAULT_SCALE

	elseif nil ~= cardConf and true == CardUtils.IsMonsterCard(cardId) then

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
function BattleLogicManager:GetSpineAvatarScale2CardByCardId(cardId)
	return self:GetSpineAvatarScaleByCardId(cardId) / CARD_DEFAULT_SCALE
end
---------------------------------------------------
-- spine calc end --
---------------------------------------------------

---------------------------------------------------
-- battle utils begin --
---------------------------------------------------
--[[
获取编队中是否存在指定cardid的卡牌
@params cardId int 卡牌id
@params isEnemy bool 敌友性
--]]
function BattleLogicManager:IsCardInTeam(cardId, isEnemy)
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
function BattleLogicManager:GetCurrentTeam(isEnemy)
	local currentTeamIndex = self:GetCurrentTeamIndex(isEnemy)
	if isEnemy then
		return self:GetBData():GetEnemyMembers(currentTeamIndex)
	else
		return self:GetBData():GetFriendMembers(currentTeamIndex)
	end
end
--[[
获取当前队伍序号
@params isEnemy bool 敌友性
@return _ int 队伍序号
--]]
function BattleLogicManager:GetCurrentTeamIndex(isEnemy)
	return self:GetBattleDriver(BattleDriverType.SHIFT_DRIVER):GetCurrentTeamIndex(isEnemy)
end
--[[
插入渲染层操作信息
@params managerName string 管理器名字
@params functionName string 方法名
@params ... 参数集
--]]
function BattleLogicManager:AddRenderOperate(managerName, functionName, ...)
	local renderOperateStruct = RenderOperateStruct.New(
		managerName, functionName, ...
	)
	self:GetBData():AddRenderOperate(renderOperateStruct)
end
--[[
获取当前波数
--]]
function BattleLogicManager:GetCurrentWave()
	return self:GetBData():GetCurrentWave()
end
--[[
获取下一波波数
--]]
function BattleLogicManager:GetNextWave()
	return self:GetBData():GetNextWave()
end
---------------------------------------------------
-- battle utils end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
获取战斗数据
--]]
function BattleLogicManager:GetBData()
	return self.bdata
end
function BattleLogicManager:SetBData(bdata)
	self.bdata = bdata
end
--[[
获取战斗配置
--]]
function BattleLogicManager:GetBConf()
	return self.bconf
end
function BattleLogicManager:SetBConf(bconf)
	self.bconf = bconf
end
--[[
获取随机数管理器
--]]
function BattleLogicManager:GetRandomManager()
	return self.randomManager
end
function BattleLogicManager:SetRandomManager(randomManager)
	self.randomManager = randomManager
end
--[[
获取本场战斗的随机种子
--]]
function BattleLogicManager:GetRandomseed()
	return self:GetBattleConstructor():GetBattleRandomConfig().randomseed
end
--[[
获取游戏变速参数
--]]
function BattleLogicManager:GetTimeScale()
	return self:GetBData():GetTimeScale()
end
--[[
设置游戏变速参数
--]]
function BattleLogicManager:SetTimeScale(timeScale)
	if 0 == timeScale then return end

	self:GetBData():SetTimeScale(timeScale)

	print('=====<<<< here set battle time scale ->', timeScale)
end
--[[
获取当前的游戏变速参数
--]]
function BattleLogicManager:GetCurrentTimeScale()
	return self:GetBData():GetCurrentTimeScale()
end
function BattleLogicManager:SetCurrentTimeScale(timeScale)
	if 0 == timeScale then return end

	self:GetBData():SetCurrentTimeScale(timeScale)

	print('=====<<<< here set battle temp time scale ->', timeScale)
end
--[[
游戏状态
--]]
function BattleLogicManager:GetGState()
	return self:GetBData().gameState
end
function BattleLogicManager:SetGState(gstate)
	self:GetBData().gameState = gstate
end
--[[
获取逻辑帧之间的间隔
@return _ number 时间间隔
--]]
function BattleLogicManager:GetLogicFrameInterval()
	return LOGIC_FPS
end
--[[
获取渲染帧转换逻辑帧的时间间隔
@return _ number 时间间隔
--]]
function BattleLogicManager:GetRenderFrameInterval()
	return LOGIC_FPS * self:GetCurrentTimeScale()
end
--[[
根据一倍速的动画帧数换算实时帧数
@params frame int 一倍速时的帧数
@return fixedFrame int 修正后的实时帧数
--]]
function BattleLogicManager:GetFixedAnimtionFrame(frame)
	local fixedFrame = math.ceil(frame / self:GetCurrentTimeScale())
	return fixedFrame
end
--[[
获取当前存活的战斗物体
@params isEnemy bool 是否是敌人
@return _ list 存活的战斗物体
--]]
function BattleLogicManager:GetAliveBattleObjs(isEnemy)
	if true == isEnemy then
		return self:GetBData().sortBattleObjs.enemy
	else
		return self:GetBData().sortBattleObjs.friend
	end
end
--[[
获取当前所有的子弹物体
@return _ list 子弹物体
--]]
function BattleLogicManager:GetBulletObjs()
	return self:GetBData().sortBattleObjs.bullet
end
--[[
获取当前墓地中的战斗物体
@params isEnemy bool 是否是敌人
@return _ list 死亡的战斗物体
--]]
function BattleLogicManager:GetDeadBattleObjs(isEnemy)
	if true == isEnemy then
		return self:GetBData().sortDustObjs.enemy
	else
		return self:GetBData().sortDustObjs.friend
	end
end
--[[
获取当前存活的召唤物
@return _ list 存活的召唤物
--]]
function BattleLogicManager:GetAliveBeckonObjs()
	return self:GetBData().sortBattleObjs.beckonObj
end
--[[
获取当前墓地中的召唤物
@return _ list 墓地中的召唤物
--]]
function BattleLogicManager:GetDeadBeckonObjs()
	return self:GetBData().sortDustObjs.beckonObj
end
--[[
获取全局效果物体
@return _ BaseLogicModel
--]]
function BattleLogicManager:GetGlobalEffectObj()
	return self:GetBData():GetGlobalEffectObj()
end
--[[
获取ob物体
@return _ BaseLogicModel
--]]
function BattleLogicManager:GetOBObject()
	return self:GetBData():GetOBObject()
end
--[[
获取当前存活的逻辑内的其他物体
@return _ list 存活的其他物体
--]]
function BattleLogicManager:GetOtherLogicObjs()
	return self:GetBData().sortOtherObjs
end
--[[
获取当前休息区中的物体
@return _ list 存活的其他物体
--]]
function BattleLogicManager:GetRestObjs()
	return self:GetBData().sortRestObjs
end
--[[
根据敌友性获取是否存在下一波阵容
@params isEnemy bool 敌友性
@return _ bool 是否存在下一波阵容
--]]
function BattleLogicManager:HasNextTeam(isEnemy)
	return self:GetBattleDriver(BattleDriverType.SHIFT_DRIVER):HasNextTeam(isEnemy)
end
--[[
是否存在下一波
--]]
function BattleLogicManager:HasNextWave()
	return self:GetEndDriver():HasNextWave()
end
--[[
获取战斗记录的fight data
@return _ string 
--]]
function BattleLogicManager:GetRecordFightDataStr()
	return self:GetBData():GetFightDataStr()
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

---------------------------------------------------
-- battle touch begin --
---------------------------------------------------
--[[
战斗场景触摸是否有效
--]]
function BattleLogicManager:SetBattleTouchEnable(enable)
	self.canTouch = enable
end
function BattleLogicManager:IsBattleTouchEnable()
	return self.canTouch
end
---------------------------------------------------
-- battle touch end --
---------------------------------------------------

---------------------------------------------------
-- player operate handler begin --
---------------------------------------------------
--[[
退出游戏处理
--]]
function BattleLogicManager:RenderQuitGameHandler()
	-- 屏蔽触摸
	self:SetBattleTouchEnable(false)

	G_BattleMgr:QuitBattle()
end
--[[
暂停按钮处理
--]]
function BattleLogicManager:RenderPauseBattleHandler()
	if not self:IsBattleTouchEnable() then return end

	if not self:IsMainLogicPause() then
		-- 暂停游戏
		self:PauseGame()
	end
end
--[[
继续按钮处理
--]]
function BattleLogicManager:RenderResumeBattleHandler()
	-- 恢复游戏
	self:ResumeGame()
end
--[[
加速按钮处理
--]]
function BattleLogicManager:RenderAccelerateHandler()
	if not self:IsBattleTouchEnable() then return end

	local timeScaleConfig = 2 + 1
	local currentTimeScale = self:GetBData():GetTimeScale()
	local newTimeScale = timeScaleConfig - currentTimeScale

	self:SetTimeScale(newTimeScale)

	--***---------- 刷新渲染层 ----------***--
	self:AddRenderOperate(
		'G_BattleRenderMgr',
		'SetBattleTimeScale',
		newTimeScale
	)
	--***---------- 刷新渲染层 ----------***--
end
--[[
连携技按钮回调
@params tag int 释放连携技的目标tag
@params skillId int 技能id
--]]
function BattleLogicManager:RenderConnectSkillHandler(tag, skillId)
	if not self:IsBattleTouchEnable() then return end

	-- 自动释放连携技模式
	if self:AutoUseFriendConnectSkill() then
		print('当前处于自动释放连携技模式')
		return
	end

	local obj = self:IsObjAliveByTag(tag)
	if nil ~= obj then
		obj:CastConnectSkill(skillId)
	else
		print('目标连携技物体死亡')
	end
end
--[[
qte冰块点击回调
@params ownerTag int 拥有者tag
@params tag int qte object tag
@params skillId int 对应的技能id
--]]
function BattleLogicManager:RenderQTEAttachObjectHandler(ownerTag, tag, skillId)
	if not self:IsBattleTouchEnable() then return end

	local owner = self:IsObjAliveByTag(ownerTag)
	if nil ~= owner then
		local qteAttachModel = owner:GetQTEBySkillId(skillId)
		if nil ~= qteAttachModel then
			qteAttachModel:TouchedAttachObject()
		end
	end
end
--[[
召唤物物体点击回调
@params tag int obj tag
--]]
function BattleLogicManager:RenderBeckonObjectHandler(tag)
	if not self:IsBattleTouchEnable() then return end

	local obj = self:IsObjAliveByTag(tag)
	if nil ~= obj then
		obj:TouchedHandler()
	end
end
--[[
设置临时的速度缩放
@params timeScale number time scale
--]]
function BattleLogicManager:RenderSetTempTimeScaleHandler(timeScale)
	self:SetCurrentTimeScale(timeScale)

	--***---------- 刷新渲染层 ----------***--
	self:AddRenderOperate(
		'G_BattleRenderMgr',
		'SetBattleTimeScale',
		timeScale
	)
	--***---------- 刷新渲染层 ----------***--
end
--[[
恢复临时的速度缩放
--]]
function BattleLogicManager:RenderRecoverTempTimeScaleHandler()
	local oriTimeScale = self:GetTimeScale()

	self:SetCurrentTimeScale(oriTimeScale)

	--***---------- 刷新渲染层 ----------***--
	self:AddRenderOperate(
		'G_BattleRenderMgr',
		'SetBattleTimeScale',
		oriTimeScale
	)
	--***---------- 刷新渲染层 ----------***--
end
--[[
弱点按钮回调
@params sceneTag int 弱点场景tag
@params touchedPointId int 点击的弱点
--]]
function BattleLogicManager:RenderWeakPointClickHandler(sceneTag, touchedPointId)
	if not self:IsBattleTouchEnable() then return end

	--***---------- 刷新渲染层 ----------***--
	self:AddRenderOperate(
		'G_BattleRenderMgr',
		'WeakPointBomb',
		sceneTag, touchedPointId
	)
	--***---------- 刷新渲染层 ----------***--
end
--[[
弱点按钮结束处理
@params ownerTag int obj tag
@params skillId int 释放的技能id
@params result table 点击的结果
--]]
function BattleLogicManager:RenderWeakChantOverHandler(ownerTag, skillId, result)
	local obj = self:IsObjAliveByTag(ownerTag)
	if nil ~= obj then
		obj.castDriver:ChantClickHandler(skillId, result)
	end
end
--[[
主角技按钮回调
@params tag int obj tag
@params skillId int 技能id
--]]
function BattleLogicManager:RenderPlayerSkillClickHandler(tag, skillId)
	if not self:IsBattleTouchEnable() then return end

	local obj = self:IsObjAliveByTag(tag)
	if nil ~= obj then
		obj:CastPlayerSkill(skillId)
	end
end
--[[
阶段转换动画结束回调
@params deformTargetTag int 变身目标的tag
--]]
function BattleLogicManager:RenderPhaseChangeSpeakAndDeformOverHandler(deformTargetTag)
	local obj = self:IsObjAliveByTag(deformTargetTag)
	if nil ~= obj then
		-- 唤醒物体
		obj:AwakeObject()
		-- 发送创建物体事件
		self:SendObjEvent(ObjectEvent.OBJECT_CREATED, {tag = obj:GetOTag()})
	end

	-- 各单位眩晕解除
	for i = #self:GetBData().sortBattleObjs.friend, 1, -1 do
		obj = self:GetBData().sortBattleObjs.friend[i]
		obj:ForceStun(false)
	end

	-- 恢复主逻辑
	G_BattleLogicMgr:ResumeMainLogic()
end
--[[
喊话逃跑喊话结束
@params tag int object tag
--]]
function BattleLogicManager:RenderPhaseChangeSpeakOverStartEscapeHandler(tag)
	local obj = self:GetBData():GetALogicModelFromRest(tag)
	if nil ~= obj then
		obj:StartEscape()
	end
end
--[[
喊话逃跑逃跑结束
@params tag int object tag
--]]
function BattleLogicManager:RenderPhaseChangeEscapeOverHandler(tag)
	local obj = self:GetBData():GetALogicModelFromRest(tag)
	if nil ~= obj then
		obj:OverEscape()
	end
end
--[[
自定义变身结束
@params deformSourceTag int 变身源的tag
@params deformTargetTag int 变身后的tag
--]]
function BattleLogicManager:RenderPhaseChangeDeformCustomizeOverHandler(deformSourceTag, deformTargetTag)
	local deformSource = self:IsObjAliveByTag(deformSourceTag)

	local deformTarget = self:IsObjAliveByTag(deformTargetTag)
	if nil ~= deformTarget then
		-- 唤醒物体
		deformTarget:AwakeObject()
		-- 发送创建物体事件
		self:SendObjEvent(ObjectEvent.OBJECT_CREATED, {tag = deformTarget:GetOTag()})
	end

	-- 恢复主逻辑
	G_BattleLogicMgr:ResumeMainLogic()
end
--[[
镜头动画结束 ConfigCameraActionType.SHAKE_ZOOM 抖动+变焦
@params tag int obj tag
@params cameraActionTag int 镜头特效tag
--]]
function BattleLogicManager:RenderCameraActionShakeAndZoomOverHandler(tag, cameraActionTag)
	local obj = self:IsObjAliveByTag(tag)
	if nil ~= obj then
		obj:CameraActionOverHandler(cameraActionTag)
	end
end
--[[
切波场景初始化完成 刷新逻辑
@params wave int 波数
--]]
function BattleLogicManager:RenderWaveTransitionStartHandler(wave)
	self:GetBattleDriver(BattleDriverType.SHIFT_DRIVER):OnShiftBegin()
end
--[[
切波场景运行完成 刷新逻辑
@params wave int 波数
--]]
function BattleLogicManager:RenderWaveTransitionOverHandler(wave)
	self:GetBattleDriver(BattleDriverType.SHIFT_DRIVER):OnShiftEnd()
end
--[[
准备开始下一波
@params wave int 波数
--]]
function BattleLogicManager:RenderReadyStartNextWaveHandler(wave)
	self:ReadyStartNextWave()
end
--[[
正式开始下一波
@params wave int 波数
--]]
function BattleLogicManager:RenderStartNextWaveHandler(wave)
	self:StartNextWave()
end
--[[
取消买活
--]]
function BattleLogicManager:RenderCancelRescueHandler()
	self:CancelRescue()
end
--[[
重开游戏
--]]
function BattleLogicManager:RenderRestartGameHandler()
	if self:CanRestartGame() then
		self:RestartGame()
	end
end
--[[
引导结束
--]]
function BattleLogicManager:RenderGuideOverHandler()
	self:GetOBObject():GuideOver()
end
---------------------------------------------------
-- player operate handler end --
---------------------------------------------------

---------------------------------------------------
-- render function begin --
---------------------------------------------------
--[[
强制刷一次渲染层的操作
--]]
function BattleLogicManager:ForceAnalyzeRenderOperate()
	-- 刷一次
	G_BattleMgr:AnalyzeRenderOperate(self:GetBData():GetNextRenderOperate())
end
--[[
创建一个物体的渲染层
@params viewModelTag int 展示层tag
@params objInfo ObjectConstructorStruct 物体的构造数据
--]]
function BattleLogicManager:RenderCreateAObjectView(viewModelTag, objInfo)
	--***---------- 刷新渲染层 ----------***--
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'CreateAObjectView',
		viewModelTag, objInfo
	)
	--***---------- 刷新渲染层 ----------***--
end
function BattleLogicManager:RenderCreateABeckonObjectView(viewModelTag, tag, objInfo)
	--***---------- 刷新渲染层 ----------***--
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'CreateABeckonObjectView',
		viewModelTag, tag, objInfo
	)
	--***---------- 刷新渲染层 ----------***--
end
--[[
播放一段战斗音效
@params soundEffectId string 音效id
--]]
function BattleLogicManager:RenderPlayBattleSoundEffect(soundEffectId)
	--***---------- 刷新渲染层 ----------***--
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'PlayBattleSoundEffect',
		soundEffectId
	)
	--***---------- 刷新渲染层 ----------***--
end
--[[
插入延时的模拟手操内容 做动画延时模拟
@params managerName string 管理器名字
@params delayFrame int 延时的帧数
@params functionName string 方法名
@params ... 参数集
--]]
function BattleLogicManager:AddPlayerOperate2TimeLine(managerName, delayFrame, functionName, ...)
	local playerOperateStruct = LogicOperateStruct.New(
		managerName, functionName, ...
	)
	-- logs('BattleLogicManager:AddPlayerOperate2TimeLine', managerName, delayFrame, functionName)
	self:GetBData():AddPlayerOperate(playerOperateStruct, delayFrame)
end
---------------------------------------------------
-- render function end --
---------------------------------------------------

---------------------------------------------------
-- server command begin --
---------------------------------------------------
--[[
获取战斗结果公共参数
@params isPassed int 战斗是否胜利 1 胜利 0 失败
@params result table 参数集合
--]]
function BattleLogicManager:GetExitCommonParameters(isPassed)
	-- 构造器数据
	local constructorStr = Table2StringNoMeta(self:GetBData():GetConstructorData())

	-- 资源加载数据
	local loadResStr = Table2StringNoMeta(self:GetBData():GetLoadedResources())

	-- 玩家手操内容
	local playerOperate = self:GetBData():GetPlayerOperateRecord()
	local playerOperateStr = Table2StringNoMeta(playerOperate)

	-- 伤害统计数据
	local skadaData = nil
	local skadaResult = nil
	local skadaDamage, skadaHeal, skadaGotDamage = 0, 0, 0
	if nil ~= self:GetBattleDriver(BattleDriverType.SKADA_DRIVER) then
		skadaData = self:GetBattleDriver(BattleDriverType.SKADA_DRIVER):GetSkada2Server()
		skadaDamage = skadaData[SkadaType.DAMAGE]
		skadaHeal = skadaData[SkadaType.HEAl]
		skadaGotDamage = skadaData[SkadaType.GOT_DAMAGE]

		-- 打印全部伤害统计
		skadaResult = self:GetBattleDriver(BattleDriverType.SKADA_DRIVER):DumpSkadaData()
	end

	local result = {
		teamId = self:GetTeamId(false),
		deadCards = self:GetBData():GetDeadCardsStr(),
		passTime = self:GetBData():GetPassedTime(),
		fightData = self:GetBData():GetFightDataStr(),
		fightRound = self:GetBData():GetCurrentWave(),
		isPassed = isPassed,
		constructorJson = constructorStr,
		loadedResourcesJson = loadResStr,
		playerOperateJson = playerOperateStr,
		skadaDamage = skadaDamage,
		skadaHeal = skadaHeal,
		skadaResult = json.encode(skadaResult),
		skadaGotDamage = skadaGotDamage,
		fightResult = json.encode(self:GetBData():GetAliveFriendObjStatus()),
		enemyHp = json.encode(self:GetBData():GetAliveEnemyObjStatus())
	}

	-- 上传一次变化的血量
	result.totalDamage = self:GetTargetMonsterDeltaHP()

	return result
end
--[[
获取目标变化血量
@return deltaHp int 变化的血量
--]]
function BattleLogicManager:GetTargetMonsterDeltaHP()
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
function BattleLogicManager:GetTargetMonsterDeltaHPByConfig()
	local deltaHp = 0
	local useConfigLogic = false

	-- 查找次怪物指针
	for otag, obj in pairs(self:GetBData().battleObjs) do
		if ConfigMonsterRecordDeltaHP.DO == obj:GetRecordDeltaHp() then
			-- 记录变化的血量
			deltaHp = deltaHp + obj:GetMainProperty():GetDeltaHp()
			-- 置为true 不再走老逻辑
			if not useConfigLogic then
				useConfigLogic = true
			end
		end
	end

	for otag, obj in pairs(self:GetBData().dustObjs) do
		if ConfigMonsterRecordDeltaHP.DO == obj:GetRecordDeltaHp() then
			deltaHp = deltaHp + obj:GetMainProperty():GetDeltaHp()
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
function BattleLogicManager:GetTargetMonsterDeltaHPByShareBoss()
	local deltaHp = 0
	local stageId = self:GetCurStageId()

	if nil ~= stageId then
		-- 获取阵容
		local enemyConfig = CommonUtils.GetConfig('quest', 'enemy', stageId)
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
					if targetMonsterId == obj:GetObjectConfigId() then
						deltaHp = obj:GetMainProperty():GetDeltaHp()
						return deltaHp
					end
				end

				for otag, obj in pairs(self:GetBData().dustObjs) do
					if targetMonsterId == obj:GetObjectConfigId() then
						deltaHp = obj:GetMainProperty():GetDeltaHp()
						return deltaHp
					end
				end
			end

		end
	end

	return deltaHp
end
---------------------------------------------------
-- server command end --
---------------------------------------------------

---------------------------------------------------
-- quit game begin --
---------------------------------------------------
--[[
退出战斗 处理一些东西
--]]
function BattleLogicManager:QuitBattle()
	-- 屏蔽触摸
	self:SetBattleTouchEnable(false)
	-- 设置游戏状态
	self:SetGState(GState.OVER)
	-- 清空battleData
	self:GetBData():Destroy()
	-- 清空缓存数据
	self:DestroyValue()
end
--[[
清空战斗管理器缓存
--]]
function BattleLogicManager:DestroyValue()
	self.bconf = nil
	self.objEvents = {}
	self.globalEvents = {}
end
--[[
重新开始游戏
--]]
function BattleLogicManager:RestartGame()
	-- 销毁
	G_BattleMgr:RestartGame()
end
---------------------------------------------------
-- quit game end --
---------------------------------------------------

---------------------------------------------------
-- record data begin --
---------------------------------------------------
--[[
记录加载的资源
@params wave int 波数
@params resmap map 加载的资源
--]]
function BattleLogicManager:RecordLoadedResources(wave, resmap)
	self:GetBData():RecordLoadedResources(wave, resmap)
end
---------------------------------------------------
-- record data end --
---------------------------------------------------

---------------------------------------------------
-- checker begin --
---------------------------------------------------
--[[
初始化上传服务器的构造器数据
--]]
function BattleLogicManager:Init2ServerConstructorData()
	local constructorData = self:GetBattleConstructor():CalcRecordConstructData(true)
	self:GetBData():RecordConstructorData(constructorData)
end
--[[
设置客户端记录的玩家手操内容
@params playerOperate map 玩家的操作信息
--]]
function BattleLogicManager:SetRecordPlayerOperate(playerOperate)
	self:GetBData():SetPlayerOperateRecord(playerOperate)
end
--[[
主循环
--]]
function BattleLogicManager:CheckerMainUpdate(dt)
	-- 自增一次逻辑帧帧数
	self:GetBData():AddLogicFrameIndex()
	-- print('check obj number<>>>>>>>', #self:GetAliveBattleObjs(false), #self:GetAliveBattleObjs(true))
	-- print('\nlogic frame index in ->BattleLogicManager:CheckerMainUpdate<-', self:GetBData():GetLogicFrameIndex())

	-- 初始化渲染层数据
	self:GetBData():InitNextRenderOperate()

	-- 先分析手操内容 再跑逻辑帧
	self:AnalyzeRecordPlayerOperate()

	if GState.OVER == self:GetGState() then return end

	-- 主循环被暂停 跳出
	if self:IsMainLogicPause() then return end

	-- 走逻辑帧
	return self:CheckerLogicMainUpdate(dt)
end
--[[
分析记录的玩家手操内容
--]]
function BattleLogicManager:AnalyzeRecordPlayerOperate()
	local currentLogicFrameIndex = self:GetBData():GetLogicFrameIndex()
	local playerOperates = self:GetBData():GetPlayerOperateRecord()[currentLogicFrameIndex]
	if nil ~= playerOperates then
		for _, operate in ipairs(playerOperates) do
			local functionName = operate.functionName
			local params = operate.variableParams

			if nil ~= self[functionName] then
				self[functionName](self, unpack(params, 1, operate.maxParams))
			end
		end
	end
end
--[[
逻辑帧update逻辑
--]]
function BattleLogicManager:CheckerLogicMainUpdate(dt)
	------------ 规则外物体逻辑 ------------
	for i = #self:GetBData().sortOBObjs, 1, -1 do
		self:GetBData().sortOBObjs[i]:Update(dt)
	end
	------------ 规则外物体逻辑 ------------

	------------ object view ------------
	self:UpdateViewModel(dt)
	------------ object view ------------
	if GState.START == self:GetGState() then

		------------ 转阶段信息最优先判断 ------------
		local needReturnLogic = self:UpdatePhaseChange(dt)
		if true == needReturnLogic then
			return
		end
		------------ 转阶段信息最优先判断 ------------

		------------ 判断游戏是否应该结束 ------------
		local result = self:IsGameOver()
		needReturnLogic = self:GetEndDriver():OnLogicEnter(result)
		if true == needReturnLogic then
			return
		end
		------------ 判断游戏是否应该结束 ------------

		------------ time logic ------------
		if not self:IsTimerPause() then
			self:UpdateTimer(dt)
		end
		------------ time logic ------------

		------------ object logic ------------
		self:UpdateLogicModel(dt)
		------------ object logic ------------

	elseif GState.TRANSITION == self:GetGState() then

		self:EnterNextWave(dt)

	elseif GState.SUCCESS == self:GetGState() then

		return PassedBattle.SUCCESS

	elseif GState.FAIL == self:GetGState() then

		return PassedBattle.FAIL

	elseif GState.BLOCK == self:GetGState() then

		self:CheckerGameRescue(dt)

	end

	-- print('here one logic frame over ==================== \n')
end
--[[
抢救游戏结果
--]]
function BattleLogicManager:CheckerGameRescue(dt)
	if not self:CanEnterNextWave(dt) then return end

	self:SetGState(GState.OVER)
end
---------------------------------------------------
-- checker end --
---------------------------------------------------

---------------------------------------------------
-- calculator begin --
---------------------------------------------------
--[[
主循环
--]]
function BattleLogicManager:CalculatorMainUpdate(dt)
	-- 自增一次逻辑帧帧数
	self:GetBData():AddLogicFrameIndex()

	-- 初始化渲染层数据
	self:GetBData():InitNextRenderOperate()

	-- 先分析手操内容 再跑逻辑帧
	self:AnalyzePlayerOperate()

	-- 初始化玩家手操数据
	self:GetBData():InitNextPlayerOperate(true)

	if GState.OVER == self:GetGState() then return end

	-- 主循环被暂停 跳出
	if self:IsMainLogicPause() then return end

	-- 走逻辑帧
	return self:LogicMainUpdate(dt, true)
end
---------------------------------------------------
-- calculator end --
---------------------------------------------------


---------------------------------------------------
-- replay begin --
---------------------------------------------------
--[[
录像的主循环
--]]
function BattleLogicManager:ReplayMainUpdate(dt)
	-- 自增一次逻辑帧帧数
	self:GetBData():AddLogicFrameIndex()
	-- print('here check logic frame index in ->BattleLogicManager:MainUpdate<-', self:GetBData():GetLogicFrameIndex())

	-- 初始化渲染层数据
	self:GetBData():InitNextRenderOperate()

	if (1 == self:GetBData():GetLogicFrameIndex()) then
		-- 人肉解一次0帧操作
		self:ReplayAnalyzePlayerOperateByIndex(0)
	end

	-- 先分析手操内容 再跑逻辑帧
	self:AnalyzeRecordPlayerOperate()

	if GState.OVER == self:GetGState() then return end

	-- 主循环被暂停 跳出
	if self:IsMainLogicPause() then return end

	-- 走逻辑帧
	self:LogicMainUpdate(dt)
end
--[[
录像特殊逻辑 根据index分析手操内容
@params index int 帧序号
--]]
function BattleLogicManager:ReplayAnalyzePlayerOperateByIndex(index)
	local playerOperates = self:GetBData():GetPlayerOperateRecord()[index]
	if nil ~= playerOperates then
		for _, operate in ipairs(playerOperates) do
			local functionName = operate.functionName
			local params = operate.variableParams

			if nil ~= self[functionName] then
				self[functionName](self, unpack(params, 1, operate.maxParams))
			end
		end
	end
end
---------------------------------------------------
-- replay end --
---------------------------------------------------


















--[[ pikapika
=====================================================================================================================================
        quu..__
         $$$b  `---.__
          "$$b        `--.                          ___.---uuudP
           `$$b           `.__.------.__     __.---'      $$$$"              .
             "$b          -'            `-.-'            $$$"              .'|
               ".                                       d$"             _.'  |
                 `.   /                              ..."             .'     |
                   `./                           ..::-'            _.'       |
                    /                         .:::-'            .-'         .'
                   :                          ::''\          _.'            |
                  .' .-.             .-.           `.      .'               |
                  : /'$$|           .@"$\           `.   .'              _.-'
                 .'|$u$$|          |$$,$$|           |  <            _.-'
                 | `:$$:'          :$$$$$:           `.  `.       .-'
                 :                  `"--'             |    `-.     \
                :##.       ==             .###.       `.      `.    `\
                |##:                      :###:        |        >     >
                |#'     `..'`..'          `###'        x:      /     /
                 \                                   xXX|     /    ./
                  \                                xXXX'|    /   ./
                  /`-.                                  `.  /   /
                 :    `-  ...........,                   | /  .'
                 |         ``:::::::'       .            |<    `.
                 |             ```          |           x| \ `.:``.
                 |                         .'    /'   xXX|  `:`M`M':.
                 |    |                    ;    /:' xXXX'|  -'MMMMM:'
                 `.  .'                   :    /:'       |-'MMMM.-'
                  |  |                   .'   /'        .'MMM.-'
                  `'`'                   :  ,'          |MMM<
                    |                     `'            |tbap\
                     \                                  :MM.-'
                      \                 |              .''
                       \.               `.            /
                        /     .:::::::.. :           /
                       |     .:::::::::::`.         /
                       |   .:::------------\       /
                      /   .''               >::'  /
                      `',:                 :    .'
                                           `:.:'
=====================================================================================================================================
--]]

return BattleLogicManager
