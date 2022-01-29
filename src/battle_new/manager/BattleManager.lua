--[[
战斗总管理器
@params _ table {
	battleConstructor BattleConstructor 战斗构造器
}
--]]
local BaseBattleManager = __Require('battle.manager.BaseBattleManager')
local BattleManager = class('BattleManager', BaseBattleManager)

------------ import ------------
__Require('battle.defines.BattleImportDefine')
------------ import ------------

------------ define ------------
local NAME = 'BattleMediator'
------------ define ------------

--[[
construtor
--]]
function BattleManager:ctor( ... )
	BaseBattleManager.ctor(self, ...)
end

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化整个的逻辑
--]]
function BattleManager:Init()
	BaseBattleManager.Init(self)

	-- 注册全局变量
	G_BattleMgr = self

	-- 初始化一些数值
	self:InitValue()

	-- 初始化逻辑层管理器
	self:InitLogicManager(self:GetBattleConstructor())

	-- 初始化渲染层管理器
	self:InitRenderManager(self:GetBattleConstructor())
end
--[[
初始化数值
--]]
function BattleManager:InitValue()
	-- 是否加载完成战斗场景
	self.battleSceneLoadingOver = false

	-- 主循环可用
	self.mainUpdateOn = false
	-- 主循环回调
	self.mainUpdateHandler = nil

	-- 当前手机时间
	self.sysTimeStamp = 0
	-- 未调用逻辑帧的时间间隔
	self.logicUpdateInterval = 0

	-- 战斗是否已经无效
	self.isBattleInvalid = false

	-- 战斗是否产生结果
	self.isPassed = PassedBattle.NO_RESULT
end
--[[
重置一些缓存数据
--]]
function BattleManager:ResetValue()
	-- 是否加载完成战斗场景
	self.battleSceneLoadingOver = false
	-- 当前手机时间
	self.sysTimeStamp = 0
	-- 未调用逻辑帧的时间间隔
	self.logicUpdateInterval = 0
	-- 战斗是否产生结果
	self.isPassed = PassedBattle.NO_RESULT
end
--[[
初始化逻辑管理器
@params battleConstructor BattleConstructor 战斗构造器
--]]
function BattleManager:InitLogicManager(battleConstructor)
	local logicManager = __Require('battle.manager.BattleLogicManager').new({
		battleConstructor = battleConstructor
	})

	-- 注册全局变量
	G_BattleLogicMgr = logicManager
end
--[[
初始化渲染管理器
@params battleConstructor BattleConstructor 战斗构造器
--]]
function BattleManager:InitRenderManager(battleConstructor)
	local renderManager = __Require('battle.manager.BattleRenderManager').new({
		battleConstructor = battleConstructor
	})

	-- 注册全局变量
	G_BattleRenderMgr = renderManager
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- control begin --
---------------------------------------------------
--[[
开始进入游戏
--]]
function BattleManager:EnterBattle()
	-- 渲染层进入战斗
	G_BattleRenderMgr:EnterBattle()
	-- 逻辑层进入战斗
	G_BattleLogicMgr:EnterBattle()

	-- 切场景开始加载
	self:SwitchSceneStartLoading()
end
--[[
切换场景开始加载
--]]
function BattleManager:SwitchSceneStartLoading()
	-- 设置加载未结束
	self:SetBattleSceneLoadingOver(false)

	local stageId = self:GetCurStageId()

	-- 开始切场景
	local params = {
		stageId = stageId,
		loadTasks = handler(self, self.LoadResources),
		done = handler(self, self.LoadOverSwitchBattleScene)
	}

	app.uiMgr:SwitchToWelcomScene(params)
end
--[[
加载完毕切换至战斗场景
--]]
function BattleManager:LoadOverSwitchBattleScene()
	-- 设置帧数
	self:SetGameFPSInterval(RENDER_FPS)
	-- 设置战斗可用
	self:SetBattleInvalid(false)

	local params = {
		backgroundId = self:GetBattleBgInfo(1).bgId,
		weatherId = self:GetStageWeatherConfig(),
		questBattleType = self:GetQuestBattleType(),
		friendTeams = self:GetBattleMembers(false),
		enemyTeams = self:GetBattleMembers(true)
	}

	app.uiMgr:SwitchToTargetScene(_GBC('battle.view.BattleScene'), params)
end
--[[
设置游戏帧数
@params interval number 一帧的时间
--]]
function BattleManager:SetGameFPSInterval(interval)
	cc.Director:getInstance():setAnimationInterval(interval)
end
--[[
根据游戏速率设置一帧的时间
@params timeScale int 游戏速率
--]]
function BattleManager:SetRenderTimeScale(timeScale)
	cc.Director:getInstance():getScheduler():setTimeScale(timeScale)
end
function BattleManager:GetRenderTimeScale()
	return cc.Director:getInstance():getScheduler():getTimeScale()
end
---------------------------------------------------
-- control end --
---------------------------------------------------

---------------------------------------------------
-- res load begin --
---------------------------------------------------
--[[
加载资源
--]]
function BattleManager:LoadResources()
	-- 开始加载资源
	G_BattleRenderMgr:StartLoadResources()
end
--[[
加载完毕 开始初始化战斗逻辑
@params data table {
	battleScene  cc.Node 战斗场景实例
}
--]]
function BattleManager:LoadingOverAndInitBattleLogic(data)
	local battleScene = data.battleScene

	-- 设置战斗场景
	self:SetViewComponent(battleScene)

	-- 加载完毕
	self:SetBattleSceneLoadingOver(true)

	-- 设置不可触摸
	self:SetBattleTouchEnable(false)

	-- 通知渲染层加载结束
	G_BattleRenderMgr:LoadResourcesOver()

	-- 通知逻辑层加载结束
	G_BattleLogicMgr:LoadResourcesOver()

	-- 逻辑层初始化完毕 渲染层再初始化一些东西
	G_BattleRenderMgr:LogicInitOver()

	-- 注册主循环
	self:RegistMainUpdate()
	
	-- 准备开始下一波
	--###---------- 刷新逻辑层 ----------###--
	-- 回传逻辑层 切波黑屏完毕 准备刷新场景
	G_BattleRenderMgr:AddPlayerOperate(
		'G_BattleLogicMgr',
		'RenderReadyStartNextWaveHandler'
	)
	--###---------- 刷新逻辑层 ----------###--
end
---------------------------------------------------
-- res load end --
---------------------------------------------------

---------------------------------------------------
-- update begin --
---------------------------------------------------
--[[
主循环
--]]
function BattleManager:MainUpdate(dt)
	if not self:IsMainUpdateValid() then return end

	-- 跑渲染帧
	self:RunRenderLogic(dt)

	-- 跑逻辑帧
	self:RunLogicUpdate(dt, function()

		if self:IsMainUpdateValid() then
			-- 解析渲染层操作
			self:AnalyzeRenderOperate()
		end

	end)

	-- 走完上面两步可能会导致update失效
	if not self:IsMainUpdateValid() then return end
end
--[[
注册主循环
--]]
function BattleManager:RegistMainUpdate()
	self:RefreshSysTimeStamp()

	if nil == self.mainUpdateHandler then
		local scheduler = require('cocos.framework.scheduler')

		self:SetMainUpdateValid(true)
		self.mainUpdateHandler = scheduler.scheduleUpdateGlobal(handler(self, self.MainUpdate))
	else

	end
end
function BattleManager:UnregistMainUpdate()
	if nil ~= self.mainUpdateHandler then
		local scheduler = require('cocos.framework.scheduler')
		
		self:SetMainUpdateValid(false)
		scheduler.unscheduleGlobal(self.mainUpdateHandler)
		self.mainUpdateHandler = nil
	end
end
--[[
调用逻辑帧的逻辑
--]]
function BattleManager:RunLogicUpdate(dt, cb)
	if G_BattleLogicMgr == nil then return end
	
	-- 获取运行的tick时间
	local deltaTime = dt

	-- 记录没有运行的逻辑帧时间
	self.logicUpdateInterval = self.logicUpdateInterval + deltaTime

	local render2logicInterval = G_BattleLogicMgr:GetRenderFrameInterval()
	local logicFrameInterval   = G_BattleLogicMgr:GetLogicFrameInterval()

	if (render2logicInterval <= self.logicUpdateInterval) then

		-- 跑逻辑帧
		for i = 1, G_BattleLogicMgr:GetCurrentTimeScale() do
			if G_BattleLogicMgr then
				G_BattleLogicMgr:MainUpdate(logicFrameInterval)
			end
			if cb then cb() end
		end

		self.logicUpdateInterval = self.logicUpdateInterval - render2logicInterval

	end
end
--[[
调用渲染帧的逻辑
--]]
function BattleManager:RunRenderLogic(dt)
	if G_BattleRenderMgr then
		G_BattleRenderMgr:MainUpdate(dt)
	end
end
--[[
解析渲染层操作
@params operates list<RenderOperateStruct>
--]]
function BattleManager:AnalyzeRenderOperate(operates)
	if G_BattleLogicMgr == nil then return end

	local operates_ = operates or self:GetBData():GetNextRenderOperate()

	if nil ~= operates_ then

		for _, operate in ipairs(operates_.operate) do

			local functionName = operate.functionName
			local params = operate.variableParams

			if nil ~= G_BattleRenderMgr[functionName] then
				G_BattleRenderMgr[functionName](G_BattleRenderMgr, unpack(params, 1, operate.maxParams))
			end

		end

	end

end
--[[
主循环可用
--]]
function BattleManager:IsMainUpdateValid()
	return self.mainUpdateOn
end
function BattleManager:SetMainUpdateValid(valid)
	self.mainUpdateOn = valid
end
--[[
获取消耗的系统时间
@return _ number 与上一次的间隔时间
--]]
function BattleManager:GetSysTick()
	-- 获取当前系统时间 毫秒
	local currentTimeStamp = utils.currentTimeMillis()
	local deltaTime = math.max(0, currentTimeStamp - self:GetSysTimeStamp()) * 0.001
	self:RefreshSysTimeStamp(currentTimeStamp)
	return deltaTime
end
--[[
刷新系统时间戳
@params timeStamp number 时间戳
--]]
function BattleManager:RefreshSysTimeStamp(timeStamp)
	self.sysTimeStamp = timeStamp or utils.currentTimeMillis()
end
--[[
获取系统时间戳
@return _ number 时间戳
--]]
function BattleManager:GetSysTimeStamp()
	return self.sysTimeStamp
end
---------------------------------------------------
-- update end --
---------------------------------------------------

---------------------------------------------------
-- battle touch control begin --
---------------------------------------------------
--[[
设置触摸屏蔽
@params enable bool 设置是否可触摸
--]]
function BattleManager:SetBattleTouchEnable(enable)
	G_BattleRenderMgr:SetBattleTouchEnable(enable)
end
--[[
全屏是否响应触摸
@return _ bool 是否响应触摸
--]]
function BattleManager:IsBattleTouchEnable()
	return G_BattleRenderMgr:IsBattleTouchEnable()
end
---------------------------------------------------
-- battle touch control end --
---------------------------------------------------

---------------------------------------------------
-- game over begin --
---------------------------------------------------
--[[
战斗结束
@params isPassed int 1 成功 0 失败
@params commonParams table 通用战斗结算传参
--]]
function BattleManager:GameOver(isPassed, commonParams)
	local serverCommand = self:GetServerCommand()
	
	local callback = nil
	if PassedBattle.FAIL == isPassed then
		callback = handler(self, self.GameFailServerHandler)
	elseif PassedBattle.SUCCESS == isPassed then
		callback = handler(self, self.GameSuccessServerHandler)
	end

	if nil == serverCommand then
		AppFacade.GetInstance():DispatchObservers('BATTLE_REPLAY_OVER', {
			isPassed     = isPassed,
			commonParams = commonParams,
		})

		callback({
			cardExp = {}
		})
		return
	end

	-- 将获得的参数设置到战斗构造器中
	self:AddGameOverServerCommandParameters(commonParams)

	----- network command -----
	AppFacade.GetInstance():DispatchObservers('BATTLE_GAME_OVER', {
		isPassed     = isPassed,
		commonParams = commonParams,
		battleConstructor = self:GetBattleConstructor(),
		callback = callback
	})
	----- network command -----
end
--[[
战斗成功请求回调
@params responseData table 服务器返回数据
--]]
function BattleManager:GameSuccessServerHandler(responseData)
	-- 胜利后刷新数据
	if self:GetServerCommand() then
		self:RefreshDataAfterGameSuccess(responseData)
	end

	G_BattleRenderMgr:ShowGameSuccess(responseData)
end
--[[
游戏胜利之后刷新一些数据
@params responseData table 服务器返回数据
--]]
function BattleManager:RefreshDataAfterGameSuccess(responseData)
	-- 设置一次是否通过
	self:SetBattleOver(PassedBattle.SUCCESS)

	local stageId = self:GetCurStageId()

	if nil ~= stageId then
		-- 刷新一次怪物图鉴
		CommonUtils.CheckEncounterMonster(stageId)

		-- 刷新一次pass卡的数据
		if nil ~= app.passTicketMgr and nil ~= app.passTicketMgr.UpdateExpByQuestId then
			app.passTicketMgr:UpdateExpByQuestId(stageId, true)
		end
	end

	-- 广播一次战斗后的数据
	AppFacade.GetInstance():DispatchObservers('BATTLE_GAME_OVER_WITH_RESPONSE_DATA', {
		questBattleType = self:GetQuestBattleType(),
		responseData = responseData
	})
end
--[[
战斗失败请求回调
@params responseData table 服务器返回数据
--]]
function BattleManager:GameFailServerHandler(responseData)
	-- 失败后刷新数据
	if self:GetServerCommand() then
		self:RefreshDataAfterGameFail(responseData)
	end

	G_BattleRenderMgr:ShowGameFail(responseData)
end
--[[
游戏失败之后刷新一些数据
@params responseData table 服务器返回数据
--]]
function BattleManager:RefreshDataAfterGameFail(responseData)
	-- 设置一次是否通过
	self:SetBattleOver(PassedBattle.FAIL)

	-- 广播一次战斗后的数据
	AppFacade.GetInstance():DispatchObservers('BATTLE_GAME_OVER_WITH_RESPONSE_DATA', {
		questBattleType = self:GetQuestBattleType(),
		responseData = responseData
	})
end
--[[
重开战斗
--]]
function BattleManager:RestartGame()
	local callback = function (responseData)
		self:DestroyBattle()

		-- 重新初始化一些数据
		self:ResetValue()

		-- 重新初始化战斗管理器
		self:InitLogicManager(self:GetBattleConstructor())
		self:InitRenderManager(self:GetBattleConstructor())

		self:EnterBattle()
	end

	----- network command -----
	AppFacade.GetInstance():DispatchObservers('BATTLE_RESTART', {
		battleConstructor = self:GetBattleConstructor(),
		callback = callback
	})
	----- network command -----
end
--[[
退出战斗
--]]
function BattleManager:QuitBattle()
	if true == self:GetBattleInvalid() then return end

	-- debug --
	-- print('\n\n ========here check loaded spine\n')
	-- print(json.encode(G_BattleLogicMgr:GetBData():GetLoadedResources()))

	-- print('\n\n ========here check render operate\n')
	-- print(json.encode(G_BattleLogicMgr:GetBData():GetRenderOperateRecord()))

	-- print('\n\n ========here check player operate\n')
	-- print(json.encode(G_BattleLogicMgr:GetBData():GetPlayerOperateRecord()))

	-- print('\n\n ========here check constructor data\n')
	-- print(json.encode(G_BattleLogicMgr:GetBData():GetConstructorData()))
	-- debug --

	self:DestroyBattle()

	-- 返回上一级
	self:BackToPrevious()
end
--[[
强制退出战斗
--]]
function BattleManager:QuitBattleForce()
	self:QuitBattle()
end
--[[
杀死战斗
--]]
function BattleManager:KillBattle()
	if true == self:IsBattleSceneLoadingOver() then
		-- 加载结束以后 直接杀掉自己 讲界面跳转交给外部逻辑
		self:DestroyBattle()
	else
		-- TODO 加载未结束
		self:DestroyBattle()
	end
end
--[[
销毁战斗
--]]
function BattleManager:DestroyBattle()
	if true == self:GetBattleInvalid() then return end

	-- 设置战斗无效
	self:SetBattleInvalid(true)

	-- 停掉update
	self:UnregistMainUpdate()
	-- 还原游戏速度缩放
	self:SetRenderTimeScale(1)

	G_BattleLogicMgr:QuitBattle()
	G_BattleRenderMgr:QuitBattle()

	G_BattleLogicMgr = nil
	G_BattleRenderMgr = nil
end
--[[
返回上一级
--]]
function BattleManager:BackToPrevious()
	AppFacade.GetInstance():DispatchObservers(
		'BATTLE_BACK_TO_PREVIOUS',
		{
			questBattleType = self:GetQuestBattleType(),
			isPassed = self:IsBattleOver(),
			battleConstructor = self:GetBattleConstructor()
		}
	)
end
--[[
获取战斗是否已经产生结果
@return _ PassedBattle 是否产生了结果
--]]
function BattleManager:IsBattleOver()
	return self.isPassed
end
function BattleManager:SetBattleOver(isPassed)
	self.isPassed = isPassed
end
--[[
显示伤害统计
@params isEnemy bool 是否是敌人
--]]
function BattleManager:ShowSkada(isEnemy)
	G_BattleRenderMgr:ShowSkada(isEnemy)
end
---------------------------------------------------
-- game over end --
---------------------------------------------------

---------------------------------------------------
-- app background begin --
---------------------------------------------------
function BattleManager:AppEnterBackground()
	-- 判断游戏状态
	if not self:IsBattleSceneLoadingOver() then return end

	if nil ~= G_BattleLogicMgr and nil ~= G_BattleRenderMgr then
		G_BattleRenderMgr:AppEnterBackground()
	end
end
--[[
安卓返回键处理
--]]
function BattleManager:GoogleBack()
	-- 判断游戏状态
	if not self:IsBattleSceneLoadingOver() then return end
	if nil ~= G_BattleLogicMgr and nil ~= G_BattleRenderMgr then
		if G_BattleLogicMgr:IsMainLogicPause() then
			if G_BattleRenderMgr.RenderResumeBattleHandler then
				G_BattleRenderMgr:RenderResumeBattleHandler()
			end
		else
			G_BattleRenderMgr:AppEnterBackground()
		end
	end
end
--[[
显示强制退出的对话框
--]]
function BattleManager:ShowForceQuitLayer()
	-- 判断游戏状态
	if not self:IsBattleSceneLoadingOver() then return end

	if nil ~= G_BattleLogicMgr and nil ~= G_BattleRenderMgr then
		G_BattleRenderMgr:ShowForceQuitLayer()
	end
end
--[[
显示强制退出的对话框
--]]
function BattleManager:ShowForceQuitLayer()
	-- 判断游戏状态
	if not self:IsBattleSceneLoadingOver() then return end

	if nil ~= G_BattleLogicMgr and nil ~= G_BattleRenderMgr then
		G_BattleRenderMgr:ShowForceQuitLayer()
	end
end
---------------------------------------------------
-- game rescue end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
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
获取bdata
--]]
function BattleManager:GetBData()
	return G_BattleLogicMgr:GetBData()
end
--[[
设置战斗是否失效
--]]
function BattleManager:SetBattleInvalid(invalid)
	self.isBattleInvalid = invalid
end
function BattleManager:GetBattleInvalid()
	return self.isBattleInvalid
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return BattleManager
