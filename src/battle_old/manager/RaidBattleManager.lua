--[[
组队战斗总控制器
@params _ table {
	battleConstructor BattleConstructor 战斗构造器
}
--]]
local BattleManager = __Require('battle.manager.BattleManager')
local RaidBattleManager = class('RaidBattleManager', BattleManager)

------------ import ------------
__Require('battle.controller.BattleConstants') 
__Require('battle.controller.BattleExpression')
__Require('battle.util.BattleUtils')
__Require('battle.battleStruct.BaseStruct')
__Require('battle.battleStruct.ObjStruct')
__Require('battle.object.ObjProperty')
__Require('battle.object.MonsterProperty')

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local cardMgr = AppFacade.GetInstance():GetManager('CardManager')
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local bsm = AppFacade.GetInstance():GetManager("BattleSocketManager")
local scheduler = require('cocos.framework.scheduler')
------------ import ------------

------------ define ------------
local RENDER_FPS = 1 / 60
local UI_FPS = 1 / 45

local BUY_REVIVAL_LAYER_TAG = 2301
local GAME_RESULT_LAYER_TAG = 2321
local PAUSE_SCENE_TAG = 1001
local READY_LAYER_TAG = 3301
local READY_RESULT_LAYER_TAG = 3303
local BATTLE_SUCCESS_VIEW_TAG = 3302
local NAME = 'RaidBattleMediator'
------------ define ------------
--[[
construtor
--]]
function RaidBattleManager:ctor( ... )
	BattleManager.ctor(self, ...)
	BMediator = self
	local args = unpack({...})

	print('\n\n\n\n\n<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<here raid battle manager come>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n\n\n\n\n')

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

	self.startRaidBattleCountdownLabel = nil
	self.startRaidBattleCountdown = 0
	self.startRaidBattleCountdownPreTimeStamp = 0
	self.startRaidBattleCountdownHandler_ = nil
	self.raidBattleWaitingOtherPlayers = true

	self.overRaidBattleCountdownLabel = nil
	self.overRaidBattleCountdown = 0
	self.overRaidBattleCountdownPreTimeStamp = 0
	self.overRaidBattleCountdownHandler_ = nil
	self.raidBattleOverWaitingOtherPlayers = true

	self.isPassed = PassedBattle.NO_RESULT

end
---------------------------------------------------
-- logic init begin --
---------------------------------------------------
--[[
初始化等待其他玩家的逻辑
@params countdown int 倒计时
--]]
function RaidBattleManager:ShowWaitingOtherMember()
	local uiLayer = self:GetViewComponent().viewData.uiLayer

	local waitingBg = display.newImageView(_res('ui/battle/battle_bg_black.png'), display.width * 0.5, display.height * 0.5,
		{scale9 = true, size = cc.size(display.width, 144)})
	uiLayer:addChild(waitingBg)

	waitingBg:setTag(READY_LAYER_TAG)

	local waitingLabel = display.newLabel(0, 0,
		{text = __('等待其他玩家'), fontSize = 30, ttf = true, font = TTF_GAME_FONT, outline = '#5b3c25'})
	display.commonUIParams(waitingLabel, {po = utils.getLocalCenter(waitingBg)})
	waitingBg:addChild(waitingLabel)
end
--[[
初始化战斗结束等待其他玩家的逻辑
--]]
function RaidBattleManager:ShowWaitingOtherMemberOver()
	local uiLayer = self:GetViewComponent().viewData.uiLayer

	local waitingBg = display.newImageView(_res('ui/battle/battle_bg_black.png'), display.width * 0.5, display.height * 0.5,
		{scale9 = true, size = cc.size(display.width, 144)})
	uiLayer:addChild(waitingBg)

	waitingBg:setTag(READY_RESULT_LAYER_TAG)

	local waitingLabel = display.newLabel(0, 0,
		{text = __('正在与队友同步战斗结果...'), fontSize = 30, ttf = true, font = TTF_GAME_FONT, outline = '#5b3c25'})
	display.commonUIParams(waitingLabel, {po = utils.getLocalCenter(waitingBg)})
	waitingBg:addChild(waitingLabel)
end
--[[
开始进行开始战斗的倒计时
@params countdown int 倒计时秒数
--]]
function RaidBattleManager:BeginStartRaidBattleCountdown(countdown)
	------------ view ------------
	if nil == self.startRaidBattleCountdownLabel then
		local uiLayer = self:GetViewComponent().viewData.uiLayer
		local parentNode = uiLayer:getChildByTag(READY_LAYER_TAG)
		if nil ~= parentNode then
			local label = CLabelBMFont:create(
				tostring(self.startRaidBattleCountdown),
				'font/battle_ico_time_1.fnt')
			label:setBMFontSize(36)
			label:setAnchorPoint(cc.p(1, 0))
			label:setPosition(cc.p(
				parentNode:getContentSize().width - 20,
				10
			))
			parentNode:addChild(label)

			self.startRaidBattleCountdownLabel = label
		end
	end
	------------ view ------------

	------------ data ------------
	if nil == self.startRaidBattleCountdownHandler then
		self.raidBattleWaitingOtherPlayers = true

		self:RegistStartRaidBattleCountdown()
	end
	-- 此处+5秒防止出现多次移除
	self.startRaidBattleCountdown = countdown + 5
	self.startRaidBattleCountdownPreTimeStamp = os.time()
	------------ data ------------
end
--[[
开始进行结束战斗的倒计时
@params countdown int 倒计时秒数
--]]
function RaidBattleManager:BeginOverRaidBattleCountdown(countdown)
	------------ view ------------
	if nil == self.overRaidBattleCountdownLabel then
		local uiLayer = self:GetViewComponent().viewData.uiLayer
		local parentNode = uiLayer:getChildByTag(READY_RESULT_LAYER_TAG)
		if nil ~= parentNode then
			local label = CLabelBMFont:create(
				tostring(self.startRaidBattleCountdown),
				'font/battle_ico_time_1.fnt')
			label:setBMFontSize(36)
			label:setAnchorPoint(cc.p(1, 0))
			label:setPosition(cc.p(
				parentNode:getContentSize().width - 20,
				10
			))
			parentNode:addChild(label)

			self.overRaidBattleCountdownLabel = label
		end
	end
	------------ view ------------

	------------ data ------------
	if nil == self.overRaidBattleCountdownHandler_ then
		self.raidBattleOverWaitingOtherPlayers = true

		self:RegistOverRaidBattleCountdown()
	end
	-- 此处+5秒防止出现多次移除
	self.overRaidBattleCountdown = countdown + 5
	self.overRaidBattleCountdownPreTimeStamp = os.time()
	------------ data ------------
end
--[[
是否可以开始游戏
--]]
function RaidBattleManager:CanRemoveCountdownAndStartGame()
	return self:IsBattleSceneLoadingOver() and
		nil ~= self:GetViewComponent() and
		nil ~= self:GetViewComponent().viewData
end
---------------------------------------------------
-- logic init end --
---------------------------------------------------

------------------------------------------------------------------------------------------------------
-- battle control begin --
------------------------------------------------------------------------------------------------------
--[[
开始战斗的倒计时
--]]
function RaidBattleManager:StartRaidBattleCountdownHandler(dt)
	if not self.raidBattleWaitingOtherPlayers then
		print('here start countdown remove by tcp')
		self:UnregistStartRaidBattleCountdown()
		return
	end

	local curTimeStamp = os.time()
	local realDeltaTime = math.max(0, os.time() - self.startRaidBattleCountdownPreTimeStamp)

	self.startRaidBattleCountdown = math.max(0, self.startRaidBattleCountdown - realDeltaTime)
	self.startRaidBattleCountdownPreTimeStamp = curTimeStamp

	if nil ~= self.startRaidBattleCountdownLabel then
		self.startRaidBattleCountdownLabel:setString(tostring(self.startRaidBattleCountdown))
	end

	if self.raidBattleWaitingOtherPlayers and 0 >= self.startRaidBattleCountdown then
		-- 结束倒计时
		print('here start countdown remove by self')
		self:RemoveReadyStateAndStart()
		self:UnregistStartRaidBattleCountdown()
	end
end
--[[
战斗结束的倒计时
--]]
function RaidBattleManager:OverRaidBattleCountdownHandler(dt)
	if not self.raidBattleOverWaitingOtherPlayers then
		print('here over countdown remove by tcp')
		self:UnregistOverRaidBattleCountdown()
		return
	end

	local curTimeStamp = os.time()
	local realDeltaTime = math.max(0, os.time() - self.overRaidBattleCountdownPreTimeStamp)

	self.overRaidBattleCountdown = math.max(0, self.overRaidBattleCountdown - realDeltaTime)
	self.overRaidBattleCountdownPreTimeStamp = curTimeStamp

	if nil ~= self.overRaidBattleCountdownLabel then
		self.overRaidBattleCountdownLabel:setString(tostring(self.overRaidBattleCountdown))
	end

	if self.raidBattleOverWaitingOtherPlayers and 0 >= self.overRaidBattleCountdown then
		-- 结束倒计时
		print('here over countdown remove by self')
		self:RaidBattleAllOver()
		self:UnregistOverRaidBattleCountdown()
	end
end
--[[
@override
--]]
function RaidBattleManager:MainUpdate(dt)
	local dt_ = math.ceil(cc.Director:getInstance():getScheduler():getTimeScale() * 1 * cc.Director:getInstance():getAnimationInterval() * 10000) * 0.0001
	BattleManager.MainUpdate(self, dt_)
end
--[[
@override
加载完毕 开始初始化战斗逻辑
@params data table {
	battleScene  cc.Node 战斗场景实例
}
--]]
function RaidBattleManager:LoadingOverAndInitBattleLogic(data)
	local battleScene = data.battleScene
	
	-- 设置战斗场景
	self:SetViewComponent(battleScene)
	-- 初始化逻辑
	self:InitialActions()
	self:InitBattleLogic()

	self:SetBattleSceneLoadingOver(true)
end
--[[
@override
移除准备提示 开始战斗
--]]
function RaidBattleManager:RemoveReadyStateAndStart()
	if not self.raidBattleWaitingOtherPlayers then return end
	self.raidBattleWaitingOtherPlayers = false
	-- 移除准备界面
	self.startRaidBattleCountdownLabel = nil
	self:GetViewComponent().viewData.uiLayer:removeChildByTag(READY_LAYER_TAG)
	-- 开始战斗
	self:GameStart()
end
--[[
@override
游戏胜利
--]]
function RaidBattleManager:GameSuccess(dt)
	if not self:CanEnterNextWave(dt) then return end
	self:SetGState(GState.OVER)

	local isPassed = PassedBattle.SUCCESS
	self:SetRaidBattleOver(isPassed)

	local requestData = self:GetExitRequestCommonParameters(isPassed)
	local outerParams = self:GetBData():getBattleConstructor():GetServerCommand().exitBattleRequestData
	if nil ~= outerParams then
		for k,v in pairs(outerParams) do
			requestData[k] = v
		end
	end

	AppFacade.GetInstance():DispatchObservers(EVENT_RAID_BATTLE_OVER, requestData)
end
--[[
@override
显示游戏成功
@params responseData table 服务器返回信息
--]]
function RaidBattleManager:ShowGameSuccess(responseData)
	local className = 'battle.view.RaidBattleSuccessView'
	local playersData = self:GetBData():getBattleConstructor():GetMemberData()

	local viewType = ConfigBattleResultType.RAID
	local layer = __Require(className).new({
		viewType = viewType,
		cleanCondition = nil,
		showMessage = false,
		canRepeatChallenge = false,
		teamData = self:GetBData():getFriendMembers(1),
		trophyData = responseData,
		playersData = playersData,
		playerRewardsData = self.playerRewardsData,
		canShowNormalRewards = self.canShowNormalRewards
	})
	layer:setTag(BATTLE_SUCCESS_VIEW_TAG)

	display.commonUIParams(layer, {ap = cc.p(0, 0), po = cc.p(0, 0)})
	self:GetViewComponent():AddUILayer(layer)

	local selfPlayerId = checkint(gameMgr:GetUserInfo().playerId)
	-- 发送信号 将所有成员状态置为未准备
	AppFacade.GetInstance():DispatchObservers(EVENT_RAID_BATTLE_GAME_RESULT)
	-- 刷新自己的挑战次数
	-- AppFacade.GetInstance():DispatchObservers(EVENT_RAID_UPDATE_PLAYER_LEFT_CHALLENGE_TIMES, {playerId = selfPlayerId, deltaValue = -1})

end
--[[
@override
游戏失败
--]]
function RaidBattleManager:GameFail(dt)
	if not self:CanEnterNextWave(dt) then return end
	self:SetGState(GState.OVER)

	local isPassed = PassedBattle.FAIL
	self:SetRaidBattleOver(isPassed)

	local requestData = self:GetExitRequestCommonParameters(isPassed)
	local outerParams = self:GetBData():getBattleConstructor():GetServerCommand().exitBattleRequestData
	if nil ~= outerParams then
		for k,v in pairs(outerParams) do
			requestData[k] = v
		end
	end

	AppFacade.GetInstance():DispatchObservers(EVENT_RAID_BATTLE_OVER, requestData)
end
--[[
@override
显示游戏失败
@params responseData table 服务器返回信息
--]]
function RaidBattleManager:ShowGameFail(responseData)
	local className = 'battle.view.RaidBattleFailView'
	local p_ = {}

	-- 结算类型
	local viewType = ConfigBattleResultType.NO_EXP

	local viewParams = {
		viewType = ConfigBattleResultType.NO_EXP,
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

	-- 发送信号 将所有成员状态置为未准备
	AppFacade.GetInstance():DispatchObservers(EVENT_RAID_BATTLE_GAME_RESULT)
end
--[[
跳回到前一个界面
--]]
function RaidBattleManager:BackToPrevious()
	self:ExitGame()

	self:UnregistStartRaidBattleCountdown()

	-- 发送一次战斗结果数据
	AppFacade.GetInstance():DispatchObservers(
		'BATTLE_BACK_TO_PREVIOUS',
		{
			questBattleType = self:GetQuestBattleType(),
			isPassed = self:IsRaidBattleOver(),
			battleConstructor = self:GetOriBattleConstructor()
		}
	)

	local questBattleType = self:GetOriBattleConstructData().questBattleType
	------------ 处理返回时的跳转 ------------
	if QuestBattleType.RAID == questBattleType then
		-- 跳转回组队界面
		AppFacade.GetInstance():DispatchObservers(EVENT_RAID_BATTLE_EXIT_TO_TEAM)
	end
	------------ 处理返回时的跳转 ------------
end
--[[
强制退出战斗 跳转
--]]
function RaidBattleManager:BackToPreviousForce(params)
	self:ExitGame()

	self:UnregistStartRaidBattleCountdown()

	-- 发送一次战斗结果数据
	AppFacade.GetInstance():DispatchObservers(
		'BATTLE_BACK_TO_PREVIOUS',
		{
			questBattleType = self:GetQuestBattleType(),
			isPassed = self:IsRaidBattleOver(),
			battleConstructor = self:GetOriBattleConstructor()
		}
	)

	local questBattleType = self:GetOriBattleConstructData().questBattleType
	------------ 处理返回时的跳转 ------------
	if QuestBattleType.RAID == questBattleType then
		-- 跳转回组队大厅界面
		AppFacade.GetInstance():DispatchObservers('EVENT_RAID_BATTLE_EXIT_TO_TEAM_FORCE')
	end
	------------ 处理返回时的跳转 ------------
end
--[[
强制退出战斗
--]]
function RaidBattleManager:QuitBattleForce()
	self:BackToPreviousForce()
end

--[[
组队战斗同步结束 开始请求结算
--]]
function RaidBattleManager:RaidBattleAllOver()
	if not self.raidBattleOverWaitingOtherPlayers then return end
	self.raidBattleOverWaitingOtherPlayers = false

	-- 移除等待结算界面
	self:GetViewComponent().viewData.uiLayer:removeChildByTag(READY_RESULT_LAYER_TAG)

	local requestData = self:GetExitRequestCommonParameters(self:IsRaidBattleOver())
	local outerParams = self:GetBData():getBattleConstructor():GetServerCommand().exitBattleRequestData
	if nil ~= outerParams then
		for k,v in pairs(outerParams) do
			requestData[k] = v
		end
	end

	AppFacade.GetInstance():DispatchObservers(EVENT_RAID_BATTLE_OVER_FOR_RESULT, requestData)
end
------------------------------------------------------------------------------------------------------
-- battle control end --
------------------------------------------------------------------------------------------------------

---------------------------------------------------
-- init logic begin --
---------------------------------------------------
--[[
初始化战斗功能模块
--]]
function RaidBattleManager:InitFunctionModule()
	BattleManager.InitFunctionModule(self)
end
---------------------------------------------------
-- init logic end --
---------------------------------------------------

---------------------------------------------------
-- handler begin --
---------------------------------------------------
--[[
处理战斗结果
@params responseData 服务器返回的战斗结果
--]]
function RaidBattleManager:HandleBattleResult(responseData)

	local isPassed = checkint(responseData.isPassed)

	if 1 == isPassed then
		-- 游戏胜利
		self:HandleBattleSuccess(responseData)
	elseif 0 == isPassed then
		-- 游戏失败
		self:HandleBattleFail(responseData)
	end

end
--[[
处理战斗胜利
@params responseData 服务器返回的战斗结果
--]]
function RaidBattleManager:HandleBattleSuccess(responseData)
	-- 胜利动作
	for i = #self:GetBData().sortBattleObjs.friend, 1, -1 do
		obj = self:GetBData().sortBattleObjs.friend[i]
		obj:win()
	end

	-- 刷新一些数据
	self:RefreshDataAfterGameSuccess()

	self:ShowGameSuccess(responseData)
end
--[[
处理游戏失败
@params responseData 服务器返回的战斗结果
--]]
function RaidBattleManager:HandleBattleFail(responseData)
	self:ShowGameFail(responseData)
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
		local resultLayer = self:GetViewComponent():GetUIByTag(BATTLE_SUCCESS_VIEW_TAG)
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
		local resultLayer = self:GetViewComponent():GetUIByTag(BATTLE_SUCCESS_VIEW_TAG)
		if nil ~= resultLayer then
			resultLayer:SetCanShowNormalRewards(playerId, true)
			return
		end
	end

	-- 如果不存在结算界面 添加到管理器缓存
	self.canShowNormalRewards[tostring(playerId)] = true
	return
end
--[[
@override
获取战斗结果请求公共参数
@params isPassed int 战斗是否胜利 1 胜利 0 失败
@params result table 参数集合
--]]
function RaidBattleManager:GetExitRequestCommonParameters(isPassed)
	local result = BattleManager.GetExitRequestCommonParameters(self, isPassed)
	result.fightData = self:GetBData():getRaidFightDataStr()

	return result
end
--[[
注册开始组队战斗倒计时
--]]
function RaidBattleManager:RegistStartRaidBattleCountdown()
	if nil == self.startRaidBattleCountdownHandler_ then
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
注册组队结束倒计时
--]]
function RaidBattleManager:RegistOverRaidBattleCountdown()
	if nil == self.overRaidBattleCountdownHandler_ then
		self.overRaidBattleCountdownHandler_ = scheduler.scheduleUpdateGlobal(handler(self, self.OverRaidBattleCountdownHandler))
	end
end
function RaidBattleManager:UnregistOverRaidBattleCountdown()
	if nil ~= self.overRaidBattleCountdownHandler_ then
		scheduler.unscheduleGlobal(self.overRaidBattleCountdownHandler_)
		self.overRaidBattleCountdownHandler_ = nil
	end
end
---------------------------------------------------
-- handler end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
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

return RaidBattleManager
