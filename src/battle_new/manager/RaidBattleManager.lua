--[[
组队战斗总控制器
@params _ table {
	battleConstructor BattleConstructor 战斗构造器
}
--]]
local BattleManager = __Require('battle.manager.BattleManager')
local RaidBattleManager = class('RaidBattleManager', BattleManager)

------------ import ------------
__Require('battle.defines.BattleImportDefine')

local scheduler = require('cocos.framework.scheduler')
------------ import ------------

------------ define ------------
-- 渲染帧帧率
local RENDER_FPS = 1 / 60
-- ui界面帧率
local UI_FPS = 1 / 45
------------ define ------------

--[[
construtor
--]]
function RaidBattleManager:ctor( ... )
	BattleManager.ctor(self, ...)
end

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化整个的逻辑
--]]
function RaidBattleManager:Init()
	BattleManager.Init(self)

	-- 开局等待其他玩家
	self.raidBattleWaitingOtherPlayers = true
	-- 开局准备开始的倒计时回调
	self.startRaidBattleCountdownHandler_ = nil
	-- 开局准备开始的倒计时
	self.startRaidBattleCountdown = 0
	-- 时间间隔时间戳
	self.startRaidBattleCountdownPreTimeStamp = 0


	-- 结束等待其他玩家
	self.raidBattleOverWaitingOtherPlayers = true
	-- 最后准备结束的倒计时回调
	self.overRaidBattleCountdownHandler_ = nil
	-- 最后准备结束的倒计时
	self.overRaidBattleCountdown = 0
	-- 时间间隔的时间戳
	self.overRaidBattleCountdownPreTimeStamp = 0

	-- 缓存的玩家奖励数据
	self.playerRewardsData = {}
	-- 缓存的玩家显示普通奖励标识位
	self.canShowNormalRewards = {}
	--[[
	{
		['playerId'] = {playerId = nil, rewardIndex = nil, rewards = nil},
		['playerId'] = {playerId = nil, rewardIndex = nil, rewards = nil},
		...
	}
	--]]
end
--[[
@override
初始化渲染管理器
@params battleConstructor BattleConstructor 战斗构造器
--]]
function RaidBattleManager:InitRenderManager(battleConstructor)
	local renderManager = __Require('battle.manager.RaidBattleRenderManager').new({
		battleConstructor = battleConstructor
	})

	-- 注册全局变量
	G_BattleRenderMgr = renderManager
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- res load begin --
---------------------------------------------------
--[[
@override
加载完毕 组队本战斗不在这里开始
@params data table {
	battleScene  cc.Node 战斗场景实例
}
--]]
function RaidBattleManager:LoadingOverAndInitBattleLogic(data)
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
end
---------------------------------------------------
-- res load end --
---------------------------------------------------

---------------------------------------------------
-- wait teammate begin --
---------------------------------------------------
--[[
初始化等待其他玩家的逻辑
@params countdown int 倒计时
--]]
function RaidBattleManager:ShowWaitingOtherMember()
	G_BattleRenderMgr:ShowWaitingOtherMember()
end
--[[
开始进行开始战斗的倒计时
@params countdown int 倒计时秒数
--]]
function RaidBattleManager:BeginStartRaidBattleCountdown(countdown)
	-- 刷新渲染层
	G_BattleRenderMgr:BeginStartRaidBattleCountdown(countdown)

	------------ data ------------
	self:RegistStartRaidBattleCountdown()
	-- 此处+5秒防止出现多次移除
	self:SetStartRaidBattleCountdown(countdown + 5)
	self:SetStartRaidBattleCountdownTimeStamp(os.time())
	------------ data ------------
end
--[[
移除准备提示 开始战斗
--]]
function RaidBattleManager:RemoveReadyStateAndStart()
	if not self:WaitingOtherPlayersAtStart() then return end

	-- 移除渲染层提示
	G_BattleRenderMgr:RemoveReadyStateAtStart()

	-- 等待结束
	self:SetWaitingOtherPlayersAtStart(false)

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
--[[
初始化战斗结束等待其他玩家的逻辑
--]]
function RaidBattleManager:ShowWaitingOtherMemberOver()
	G_BattleRenderMgr:ShowWaitingOtherMemberOver()
end
--[[
开始进行结束战斗的倒计时
@params countdown int 倒计时秒数
--]]
function RaidBattleManager:BeginOverRaidBattleCountdown(countdown)
	-- 刷新渲染层
	G_BattleRenderMgr:BeginOverRaidBattleCountdown(countdown)

	------------ data ------------
	self:RegistOverRaidBattleCountdown()
	-- 此处+5秒防止出现多次移除
	self:SetOverRaidBattleCountdown(countdown + 5)
	self:SetOverRaidBattleCountdownTimeStamp(os.time())
	------------ data ------------
end
--[[
组队战斗同步结束 开始请求结算
--]]
function RaidBattleManager:RemoveReadyStateAndOver()
	if not self:WaitingOtherPlayersAtOver() then return end

	-- 移除渲染层提示
	G_BattleRenderMgr:RemoveReadyStateAtOver()

	-- 等待结束
	self:SetWaitingOtherPlayersAtOver(false)

	-- 发送结束请求请求战斗结果
	AppFacade.GetInstance():DispatchObservers(EVENT_RAID_BATTLE_OVER_FOR_RESULT, self:GetGameOverServerCommandParameters())
end
--[[
组队本战斗全部结束
--]]
function RaidBattleManager:RaidBattleAllOver()
	self:RemoveReadyStateAndOver()
end
---------------------------------------------------
-- wait teammate end --
---------------------------------------------------

---------------------------------------------------
-- game over begin --
---------------------------------------------------
--[[
强制退出战斗
--]]
function RaidBattleManager:QuitBattleForce()
	if true == self:GetBattleInvalid() then return end

	self:DestroyBattle()

	-- 返回上一级
	self:BackToPreviousForce()
end
--[[
@override
战斗结束
@params isPassed int 1 成功 0 失败
@params commonParams table 通用战斗结算传参
--]]
function RaidBattleManager:GameOver(isPassed, commonParams)
	local serverCommand = self:GetServerCommand()
	if nil == serverCommand then
		-- 直接退出
		self:QuitBattle()
		return
	end

	-- 将获得的参数设置到战斗构造器中
	self:AddGameOverServerCommandParameters(commonParams)

	-- 设置一次是否通过
	self:SetRaidBattleOver(isPassed)

	----- network command -----
	AppFacade.GetInstance():DispatchObservers('BATTLE_GAME_OVER', {
		isPassed     = isPassed,
		commonParams = commonParams,
		requestData  = commonParams
	})
	----- network command -----
end
--[[
处理战斗结果
@params responseData 服务器返回的战斗结果
--]]
function RaidBattleManager:HandleBattleResult(responseData)
	local isPassed = checkint(responseData.isPassed)

	if PassedBattle.SUCCESS == isPassed then
		-- 游戏胜利
		self:GameSuccessServerHandler(responseData)
	elseif PassedBattle.FAIL == isPassed then
		-- 游戏失败
		self:GameFailServerHandler(responseData)
	end
end
--[[
战斗成功请求回调
@params responseData table 服务器返回数据
--]]
function RaidBattleManager:GameSuccessServerHandler(responseData)
	-- 胜利后刷新数据
	self:RefreshDataAfterGameSuccess()

	G_BattleRenderMgr:ShowGameSuccess(responseData, self:GetPlayerRewardsData(), self:GetCanShowNormalRewards())

	local selfPlayerId = checkint(app.gameMgr:GetUserInfo().playerId)
	-- 发送信号 将所有成员状态置为未准备
	AppFacade.GetInstance():DispatchObservers(EVENT_RAID_BATTLE_GAME_RESULT)
	-- 刷新自己的挑战次数
	-- AppFacade.GetInstance():DispatchObservers(EVENT_RAID_UPDATE_PLAYER_LEFT_CHALLENGE_TIMES, {playerId = selfPlayerId, deltaValue = -1})
end
--[[
战斗失败请求回调
@params responseData table 服务器返回数据
--]]
function RaidBattleManager:GameFailServerHandler(responseData)
	-- 失败后刷新数据
	self:RefreshDataAfterGameFail()
	
	G_BattleRenderMgr:ShowGameFail(responseData, nil, nil)

	-- 发送信号 将所有成员状态置为未准备
	AppFacade.GetInstance():DispatchObservers(EVENT_RAID_BATTLE_GAME_RESULT)
end
---------------------------------------------------
-- game over end --
---------------------------------------------------

---------------------------------------------------
-- countdown handler begin --
---------------------------------------------------
--[[
注册开始组队战斗倒计时
--]]
function RaidBattleManager:RegistStartRaidBattleCountdown()
	if nil == self.startRaidBattleCountdownHandler_ then
		self:SetWaitingOtherPlayersAtStart(true)
		self.startRaidBattleCountdownHandler_ = scheduler.scheduleUpdateGlobal(handler(self, self.StartRaidBattleCountdownHandler))
	end
end
--[[
注销开始组队战斗倒计时
--]]
function RaidBattleManager:UnregistStartRaidBattleCountdown()
	if nil ~= self.startRaidBattleCountdownHandler_ then
		scheduler.unscheduleGlobal(self.startRaidBattleCountdownHandler_)
		self.startRaidBattleCountdownHandler_ = nil
	end
end
--[[
开始战斗的倒计时
@params dt number delta time
--]]
function RaidBattleManager:StartRaidBattleCountdownHandler(dt)
	if not self:WaitingOtherPlayersAtStart() then
		print('here start countdown remove by tcp')
		self:UnregistStartRaidBattleCountdown()
		return
	end

	local curTimeStamp = os.time()
	local realDeltaTime = math.max(0, os.time() - self:GetStartRaidBattleCountdownTimeStamp())
	local countdown = math.max(0, self:GetStartRaidBattleCountdown() - realDeltaTime)
	self:SetStartRaidBattleCountdown(countdown)
	self:SetStartRaidBattleCountdownTimeStamp(curTimeStamp)

	-- 刷新渲染层
	if G_BattleRenderMgr then
		G_BattleRenderMgr:RefreshStartRaidBattleCountdownLabel(math.ceil(countdown))
	end

	if self:WaitingOtherPlayersAtStart() and 0 >= countdown then
		-- 结束倒计时
		print('here start countdown remove by self')
		self:RemoveReadyStateAndStart()
		self:UnregistStartRaidBattleCountdown()
	end
end
--[[
注册组队结束倒计时
--]]
function RaidBattleManager:RegistOverRaidBattleCountdown()
	if nil == self.overRaidBattleCountdownHandler_ then
		self:SetWaitingOtherPlayersAtOver(true)
		self.overRaidBattleCountdownHandler_ = scheduler.scheduleUpdateGlobal(handler(self, self.OverRaidBattleCountdownHandler))
	end
end
--[[
注销组队结束倒计时
--]]
function RaidBattleManager:UnregistOverRaidBattleCountdown()
	if nil ~= self.overRaidBattleCountdownHandler_ then
		scheduler.unscheduleGlobal(self.overRaidBattleCountdownHandler_)
		self.overRaidBattleCountdownHandler_ = nil
	end
end
--[[
战斗结束的倒计时
--]]
function RaidBattleManager:OverRaidBattleCountdownHandler(dt)
	if not self:WaitingOtherPlayersAtOver() then
		print('here over countdown remove by tcp')
		self:UnregistOverRaidBattleCountdown()
		return
	end

	local curTimeStamp = os.time()
	local realDeltaTime = math.max(0, os.time() - self:GetOverRaidBattleCountdownTimeStamp())
	local countdown = math.max(0, self:GetOverRaidBattleCountdown() - realDeltaTime)
	self:SetOverRaidBattleCountdown(countdown)
	self:SetOverRaidBattleCountdownTimeStamp(curTimeStamp)

	-- 刷新渲染层
	if G_BattleRenderMgr then
		G_BattleRenderMgr:RefreshOverRaidBattleCountdownLabel(math.ceil(countdown))
	end

	if self:WaitingOtherPlayersAtOver() and 0 >= countdown then
		-- 结束倒计时
		print('here start countdown remove by self')
		self:RemoveReadyStateAndOver()
		self:UnregistOverRaidBattleCountdown()
	end
end
---------------------------------------------------
-- countdown handler end --
---------------------------------------------------

---------------------------------------------------
-- game over begin --
---------------------------------------------------
--[[
跳回到前一个界面
--]]
function RaidBattleManager:BackToPrevious()
	-- 暂停一些计时器
	self:UnregistStartRaidBattleCountdown()

	-- 发送一次战斗结果数据
	AppFacade.GetInstance():DispatchObservers(
		'BATTLE_BACK_TO_PREVIOUS',
		{
			questBattleType = self:GetQuestBattleType(),
			isPassed = self:IsRaidBattleOver(),
			battleConstructor = self:GetBattleConstructor()
		}
	)

	local questBattleType = self:GetQuestBattleType()
	------------ 处理返回时的跳转 ------------
	if QuestBattleType.RAID == questBattleType then
		-- 跳转回组队界面
		AppFacade.GetInstance():DispatchObservers(EVENT_RAID_BATTLE_EXIT_TO_TEAM)
	end
	------------ 处理返回时的跳转 ------------
end
--[[
强制退出
--]]
function RaidBattleManager:BackToPreviousForce()
	-- 暂停一些计时器
	self:UnregistStartRaidBattleCountdown()

	-- 发送一次战斗结果数据
	AppFacade.GetInstance():DispatchObservers(
		'BATTLE_BACK_TO_PREVIOUS',
		{
			questBattleType = self:GetQuestBattleType(),
			isPassed = self:IsRaidBattleOver(),
			battleConstructor = self:GetBattleConstructor()
		}
	)

	local questBattleType = self:GetQuestBattleType()
	------------ 处理返回时的跳转 ------------
	if QuestBattleType.RAID == questBattleType then
		-- 跳转回组队大厅界面
		AppFacade.GetInstance():DispatchObservers('EVENT_RAID_BATTLE_EXIT_TO_TEAM_FORCE')
	end
	------------ 处理返回时的跳转 ------------
end
---------------------------------------------------
-- game over end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
是否正在等待其他玩家
--]]
function RaidBattleManager:WaitingOtherPlayersAtStart()
	return self.raidBattleWaitingOtherPlayers
end
function RaidBattleManager:SetWaitingOtherPlayersAtStart(waiting)
	self.raidBattleWaitingOtherPlayers = waiting
end
--[[
设置开局开始游戏的倒计时
--]]
function RaidBattleManager:SetStartRaidBattleCountdown(countdown)
	self.startRaidBattleCountdown = countdown
end
function RaidBattleManager:GetStartRaidBattleCountdown()
	return self.startRaidBattleCountdown
end
--[[
设置开局开始游戏倒计时的间隔时间戳
--]]
function RaidBattleManager:SetStartRaidBattleCountdownTimeStamp(time)
	self.startRaidBattleCountdownPreTimeStamp = time
end
function RaidBattleManager:GetStartRaidBattleCountdownTimeStamp()
	return self.startRaidBattleCountdownPreTimeStamp
end
--[[
是否可以开始游戏
--]]
function RaidBattleManager:CanRemoveCountdownAndStartGame()
	return self:IsBattleSceneLoadingOver() and
		nil ~= G_BattleRenderMgr and
		nil ~= G_BattleRenderMgr:GetBattleScene() and
		nil ~= G_BattleRenderMgr:GetBattleScene().viewData
end
--[[
结束等待其他玩家
--]]
function RaidBattleManager:WaitingOtherPlayersAtOver()
	return self.raidBattleOverWaitingOtherPlayers
end
function RaidBattleManager:SetWaitingOtherPlayersAtOver(waiting)
	self.raidBattleOverWaitingOtherPlayers = waiting
end
--[[
设置最后结束游戏的倒计时
--]]
function RaidBattleManager:SetOverRaidBattleCountdown(countdown)
	self.overRaidBattleCountdown = countdown
end
function RaidBattleManager:GetOverRaidBattleCountdown()
	return self.overRaidBattleCountdown
end
--[[
设置最后结束游戏倒计时的间隔时间戳
--]]
function RaidBattleManager:SetOverRaidBattleCountdownTimeStamp(time)
	self.overRaidBattleCountdownPreTimeStamp = time
end
function RaidBattleManager:GetOverRaidBattleCountdownTimeStamp()
	return self.overRaidBattleCountdownPreTimeStamp
end
--[[
获取缓存的玩家奖励
--]]
function RaidBattleManager:GetPlayerRewardsData()
	return self.playerRewardsData
end
--[[
获取缓存的玩家显示普通奖励标识位
--]]
function RaidBattleManager:GetCanShowNormalRewards()
	return self.canShowNormalRewards
end
--[[
累加一次其他玩家获得的奖励
@params data table 其他玩家获得的奖励信息
--]]
function RaidBattleManager:AddMemberRewards(data)
	local playerId = checkint(data.playerId)
	local rewardIndex = checkint(data.rewardIndex)
	local rewards = data.rewards
	local rareRewards = checktable(data.rareRewards)
	local extraRewards = checktable(data.extraRewards)

	if self:IsBattleSceneLoadingOver() then
		local resultLayer = G_BattleRenderMgr:GetRaidBattleSuccessView()
		if nil ~= resultLayer then
			resultLayer:AddPlayerRewards(
				playerId,
				rewardIndex,
				rewards,
				rareRewards,
				extraRewards
			)
			return
		end
	end

	-- 如果不存在结算界面 添加到管理器缓存
	self.playerRewardsData[tostring(playerId)] = {
		playerId = playerId,
		rewardIndex = rewardIndex,
		rewards = rewards,
		rareRewards = rareRewards,
		extraRewards = extraRewards
	}
end
--[[
刷新一次是否能显示其他玩家的普通奖励信息
@params data table {
	playerId int 玩家id
}
--]]
function RaidBattleManager:AddMemberChooseRewards(data)
	local playerId = checkint(data.playerId)

	if self:IsBattleSceneLoadingOver() then
		local resultLayer = G_BattleRenderMgr:GetRaidBattleSuccessView()
		if nil ~= resultLayer then
			resultLayer:SetCanShowNormalRewards(playerId, true)
			return
		end
	end

	-- 如果不存在结算界面 添加到管理器缓存
	self.canShowNormalRewards[tostring(playerId)] = true
end
--[[
获取战斗是否已经产生结果
@return _ PassedBattle 是否产生了结果
--]]
function RaidBattleManager:IsRaidBattleOver()
	return self.isPassed
end
function RaidBattleManager:SetRaidBattleOver(isPassed)
	self.isPassed = isPassed
end
---------------------------------------------------
-- get set end --
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











return RaidBattleManager
