--[[
离线pvp
@params table {
	pvcData 竞技场信息
}
--]]
local Mediator = mvc.Mediator
local PVCMediator = class("PVCMediator", Mediator)
local NAME = "PVCMediator"

------------ import ------------
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager('CardManager')
local PVCCommand = require('Game.command.PVCCommand')
local timerMgr = AppFacade.GetInstance():GetManager("TimerManager")
------------ import ------------

------------ define ------------
local changeTeamMemberLayerTag = 791
local selectRivalLayerTag = 7901
local activePointRewardLayerTag = 7902
local rewardsDetailLayerTag = 7903
local reportLayerTag = 7904
local CHANGE_DEFENSE_TEAN_SIGNAL = 'CHANGE_DEFENSE_TEAN_SIGNAL'
local CHANGE_FIGHT_TEAM_SIGNAL = 'CHANGE_FIGHT_TEAM_SIGNAL'
local PVC_REFRESH_TIMER_NAME = 'PVC_REFRESH_TIMER_NAME'

PVC_LOCAL_RIVAL_ID_KEY = 'pvclocalrivalplayerid'
MAX_PVC_FIGHT_TIMES = 5

MAX_FREE_SHUFFLE_RIVAL_TIMES = 2
------------ define ------------

--[[
constructor
--]]
function PVCMediator:ctor(params, viewComponent)
	Mediator.ctor(self, NAME, viewComponent)
	-- dump(params)

	self:InitData(params)
end
---------------------------------------------------
-- mediator extend begin --
---------------------------------------------------
function PVCMediator:InterestSignals()
	local signals = {
		------------ server ------------
		SIGNALNAMES.PVC_OfflineArena_Home_Callback, 						-- home刷新所有服务器返回信号
		SIGNALNAMES.PVC_OfflineArena_SetDefenseTeam_Callback, 				-- 设置防御队伍服务器返回信号
		SIGNALNAMES.PVC_OfflineArena_SetFightTeam_Callback, 				-- 设置进攻队伍服务器返回信号
		SIGNALNAMES.PVC_OfflineArena_MatchOpponent_Callback,				-- 更换竞技场对手服务器返回信号
		SIGNALNAMES.PVC_OfflineArena_FirstWinReward_Callback, 				-- 领取首胜奖励服务器返回信号
		SIGNALNAMES.PVC_OfflineArena_BuyArenaQuestTimes_Callback, 			-- 购买战斗次数服务器返回信号
		SIGNALNAMES.PVC_OfflineArena_ArenaRecord, 							-- 查看竞技场战报服务器返回信号
		------------ local ------------
		'SHOW_ACTIVE_POINT_DETAIL', 										-- 显示活跃度详细情况
		'SHOW_CHANGE_FRIEND_DEFENSE_TEAM', 									-- 显示更换防守队伍场景
		'SHOW_CHANGE_FRIEND_FIGHT_TEAM', 									-- 显示更换进攻队伍场景
		'SHOW_SELECT_RIVAL', 												-- 显示选择对手界面
		'SHUFFLE_ALL_RIVALS',												-- 更换一批竞技场对手
		'SELECT_A_RIVAL', 													-- 选择一个竞技场对手
		'READY_TO_DUEL', 													-- pvc战斗按钮
		'DRAW_FIRST_WIN_REWARD', 											-- 领取首胜奖励
		'BUY_CHALLENGE_TIME', 												-- 购买进攻次数
		'SHOW_CHECK_RECORD', 												-- 显示查看竞技场战报
		'SHOW_PVC_RANK', 													-- 显示pvc排行榜
		'SHOW_PVC_SHOP', 													-- 显示pvc商城
		'EXIT_PVC_HOME', 													-- 退出界面
		CHANGE_DEFENSE_TEAN_SIGNAL, 										-- 更换防御卡牌信号
		CHANGE_FIGHT_TEAM_SIGNAL 											-- 更换进攻卡牌信号
	}
	return signals
end
function PVCMediator:ProcessSignal(signal)
	local name = signal:GetName()
	local responseData = signal:GetBody()

	------------ server ------------
	if SIGNALNAMES.PVC_OfflineArena_Home_Callback == name then

		-- home 刷新所有
		self:RefreshAllCallback(responseData)

	elseif SIGNALNAMES.PVC_OfflineArena_SetDefenseTeam_Callback == name then

		-- 设置防御队伍成功
		self:ChangeFriendDefenseTeamCallback(responseData)

	elseif SIGNALNAMES.PVC_OfflineArena_SetFightTeam_Callback == name then

		-- 设置进攻队伍成功
		self:ChangeFriendFightTeamCallback(responseData)

	elseif SIGNALNAMES.PVC_OfflineArena_MatchOpponent_Callback == name then

		-- 更换竞技场对手
		self:ShuffleAllRivalsCallback(responseData)

	elseif SIGNALNAMES.PVC_OfflineArena_FirstWinReward_Callback == name then

		-- 领取首胜奖励成功
		self:DrawFirstWinRewardCallback(responseData)

	elseif SIGNALNAMES.PVC_OfflineArena_BuyArenaQuestTimes_Callback == name then

		-- 购买战斗次数
		self:BuyChallengeTimeCallback(responseData)

	elseif SIGNALNAMES.PVC_OfflineArena_ArenaRecord == name then

		-- 查看竞技场战报
		self:ShowCheckRecordCallback(responseData)

	------------ local ------------
	elseif 'SHOW_ACTIVE_POINT_DETAIL' == name then

		-- 活跃度详细情况回调
		self:ShowActivePointDetail(responseData)

	elseif 'SHOW_CHANGE_FRIEND_DEFENSE_TEAM' == name then

		-- 显示编辑防御队伍场景
		self:ShowChangeFriendDefenseTeam()

	elseif 'SHOW_CHANGE_FRIEND_FIGHT_TEAM' == name then

		-- 显示编辑防御队伍场景
		self:ShowChangeFriendFightTeam()

	elseif 'SHOW_SELECT_RIVAL' == name then

		-- 显示选择对手界面回调
		self:ShowSelectRival()

	elseif 'SHUFFLE_ALL_RIVALS' == name then

		-- 洗牌所有对手回调
		self:ShuffleAllRivals()

	elseif 'SELECT_A_RIVAL' == name then

		-- 选择一个对手回调
		self:SelectARival(responseData)

	elseif 'READY_TO_DUEL' == name then

		-- 战斗事件回调
		self:ReadyToDuel()

	elseif 'DRAW_FIRST_WIN_REWARD' == name then

		-- 领取首胜奖励
		self:DrawFirstWinReward()

	elseif 'BUY_CHALLENGE_TIME' == name then

		-- 购买进攻次数
		self:BuyChallengeTime()

	elseif 'SHOW_CHECK_RECORD' == name then

		-- 查看竞技场战报
		self:ShowCheckRecord()

	elseif 'SHOW_PVC_RANK' == name then

		-- 显示竞技场排行榜
		self:ShowPVCRank()

	elseif 'SHOW_PVC_SHOP' == name then

		-- 显示竞技场排行榜
		self:ShowPVCShop()

	elseif 'EXIT_PVC_HOME' == name then

		-- 退出竞技场界面
		self:ExitPVCHome()

	elseif CHANGE_DEFENSE_TEAN_SIGNAL == name then

		-- 活跃度详细情况回调
		self:ChangeFriendDefenseTeam(responseData)

	elseif CHANGE_FIGHT_TEAM_SIGNAL == name then

		-- 活跃度详细情况回调
		self:ChangeFriendFightTeam(responseData)

	end
end
function PVCMediator:Initial(key)
	self.super:Initial(key)
end
function PVCMediator:OnRegist()
	-- 注册信号
	self:GetFacade():RegistSignal(COMMANDS.COMMANDS_PVC_OfflineArena_Home, PVCCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMANDS_PVC_OfflineArena_SetDefenseTeam, PVCCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMANDS_PVC_OfflineArena_SetFightTeam, PVCCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMANDS_PVC_OfflineArena_MatchOpponent, PVCCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMANDS_PVC_OfflineArena_FirstWinReward, PVCCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMANDS_PVC_OfflineArena_BuyArenaQuestTimes, PVCCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMANDS_PVC_OfflineArena_ArenaRecord, PVCCommand)

	-- 初始化界面
	self:InitScene()
	if isGuideOpened('pvp') then
		local guideNode = require('common.GuideNode').new({tmodule = 'pvp'})
		display.commonUIParams(guideNode, { po = display.center})
		sceneWorld:addChild(guideNode, GameSceneTag.Guide_GameSceneTag)
	end

	-- 初始化计时器
	timerMgr:AddTimer({
		name = PVC_REFRESH_TIMER_NAME,
		countdown = checkint(self:GetPVCData().refreshTime),
		callback = handler(self, self.RefreshCountDownCallback)
	})

	-- 隐藏顶部条
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightHide")
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "allhide")
end
function PVCMediator:OnUnRegist()
	-- 销毁信号
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_PVC_OfflineArena_Home)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_PVC_OfflineArena_SetDefenseTeam)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_PVC_OfflineArena_SetFightTeam)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_PVC_OfflineArena_MatchOpponent)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_PVC_OfflineArena_FirstWinReward)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_PVC_OfflineArena_BuyArenaQuestTimes)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_PVC_OfflineArena_ArenaRecord)

	-- 移除计时器
	timerMgr:StopTimer(PVC_REFRESH_TIMER_NAME)
	timerMgr:RemoveTimer(PVC_REFRESH_TIMER_NAME)

	-- 恢复顶部条
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightShow")
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "hide")
end
---------------------------------------------------
-- mediator extend end --
---------------------------------------------------

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化数据
@params responseData table 服务器返回数据
--]]
function PVCMediator:InitData(responseData)
	self.pvcData = nil

	self:SetPVCData(responseData)

	-- 查找本地保存的竞技场对手id
	self.rivalPlayerId = gameMgr:GetLoaclPVCRivalPlayerId()

	-- cc.UserDefault:getInstance():setStringForKey(PVC_LOCAL_RIVAL_ID_KEY, 0)
	-- cc.UserDefault:getInstance():flush()

	-- 是否正在刷新整个界面
	self.isInRefresh = false
end
--[[
初始化界面
--]]
function PVCMediator:InitScene()
	-- 隐藏顶部状态
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "show")

	-- 创建场景
	local scene = uiMgr:SwitchToTargetScene("Game.views.pvc.PVCHomeScene")
	self:SetViewComponent(scene)

	-- 刷新界面
	scene:RefreshUI(self:GetPVCData(), self.rivalPlayerId)

	-- 活跃度打脸奖励
	self:DrawActivePointRewards()
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- view control begin --
---------------------------------------------------
--[[
显示活跃度详细情况
@params data table {
	show
}
--]]
function PVCMediator:ShowActivePointDetail(data)
	if true == data.show then
		-- 显示那层
		self:GetViewComponent():ShowActivePointRewardsLayer(data.show)
	else
		-- 如果已经显示 则显示奖励详细
		self:GetViewComponent():ActivePointRewardPreviewClickHandler(self:GetViewComponent().viewData.activeBtnBg)
	end
end
--[[
显示编辑防守队伍界面
--]]
function PVCMediator:ShowChangeFriendDefenseTeam()
	local teamData = self:ConvertTeamDataByString(self:GetPVCData().defenseTeam)
	local tag = changeTeamMemberLayerTag

	local layer = require('Game.views.pvc.PVCChangeTeamScene').new({
		teamDatas = {[1] = teamData},
		title = __('编辑防守队伍'),
		teamTowards = -1,
		avatarTowards = -1,
		teamChangeSingalName = CHANGE_DEFENSE_TEAN_SIGNAL
	})
	layer:setAnchorPoint(cc.p(0.5, 0.5))
	layer:setPosition(display.center)
	layer:setTag(tag)
	uiMgr:GetCurrentScene():AddDialog(layer)
end
--[[
显示编辑进攻队伍界面
--]]
function PVCMediator:ShowChangeFriendFightTeam()
	local teamData = self:ConvertTeamDataByString(self:GetPVCData().fightTeam)
	local tag = changeTeamMemberLayerTag

	local layer = require('Game.views.pvc.PVCChangeTeamScene').new({
		teamDatas = {[1] = teamData},
		title = __('编辑进攻队伍'),
		teamTowards = 1,
		avatarTowards = 1,
		teamChangeSingalName = CHANGE_FIGHT_TEAM_SIGNAL
	})
	layer:setAnchorPoint(cc.p(0.5, 0.5))
	layer:setPosition(display.center)
	layer:setTag(tag)
	uiMgr:GetCurrentScene():AddDialog(layer)
end
--[[
保存编队
@params data table {
	teamData = {
		{id = nil},
		{id = nil},
		{id = nil},
		...
	}
}
--]]
function PVCMediator:ChangeFriendDefenseTeam(data)
	-- 可行性判断
	local isTeamEmpty = true
	for i,v in ipairs(data.teamData) do
		if nil ~= v.id then
			isTeamEmpty = false
		end
	end
	if isTeamEmpty then
		uiMgr:ShowInformationTips(__('队伍不能为空!!!'))
		return
	end

	local teamStr = self:ConvertTeamData2String(data.teamData)

	self:SendSignal(COMMANDS.COMMANDS_PVC_OfflineArena_SetDefenseTeam, {defenseTeam = teamStr})
end
--[[
保存编队回调
@params responseData table
--]]
function PVCMediator:ChangeFriendDefenseTeamCallback(responseData)
	-- 弹提示
	uiMgr:ShowInformationTips(__('更改防御队伍成功!!!'))

	------------ data ------------
	local teamStrData = self:ConvertTeamDataFromString2StrList(responseData.requestData.defenseTeam)
	local newPVCData = {
		defenseTeam = teamStrData
	}
	self:UpdatePVCData(newPVCData)
	------------ data ------------

	------------ view ------------
	self:GetViewComponent():RefreshFriendDefenseTeam(self:GetPVCData().defenseTeam)

	-- 关闭阵容界面
	AppFacade.GetInstance():DispatchObservers('CLOSE_CHANGE_TEAM_SCENE')
	------------ view ------------
end
--[[
保存进攻编队
@params data table {
	teamData = {
		{id = nil},
		{id = nil},
		{id = nil},
		...
	}
}
--]]
function PVCMediator:ChangeFriendFightTeam(data)
	-- 可行性判断
	local isTeamEmpty = true
	for i,v in ipairs(data.teamData) do
		if nil ~= v.id then
			isTeamEmpty = false
		end
	end
	if isTeamEmpty then
		uiMgr:ShowInformationTips(__('队伍不能为空!!!'))
		return
	end

	local teamStr = self:ConvertTeamData2String(data.teamData)
	print('here check fuck string?>>>>>>>>>>>>>>>>', teamStr)

	self:SendSignal(COMMANDS.COMMANDS_PVC_OfflineArena_SetFightTeam, {fightTeam = teamStr})
end
--[[
保存进攻编队回调
@params responseData table
--]]
function PVCMediator:ChangeFriendFightTeamCallback(responseData)
	-- 弹提示
	uiMgr:ShowInformationTips(__('更改进攻队伍成功!!!'))

	------------ data ------------
	local teamStrData = self:ConvertTeamDataFromString2StrList(responseData.requestData.fightTeam)
	local newPVCData = {
		fightTeam = teamStrData
	}
	self:UpdatePVCData(newPVCData)
	------------ data ------------

	------------ view ------------
	self:GetViewComponent():RefreshFriendFightTeam(self:GetPVCData().fightTeam)

	-- 关闭阵容界面
	AppFacade.GetInstance():DispatchObservers('CLOSE_CHANGE_TEAM_SCENE')
	------------ view ------------
end
--[[
显示选择对手界面
--]]
function PVCMediator:ShowSelectRival()
	local tag = selectRivalLayerTag
	local layer = require('Game.views.pvc.PVCSelectRivalView').new({
		tag = selectRivalLayerTag,
		maxMatchFreeTimes = MAX_FREE_SHUFFLE_RIVAL_TIMES,
		matchFreeTimes = self:GetPVCData().matchFreeTimes,
		rivalsInfo = self:GetPVCData().matchOpponent
	})
	display.commonUIParams(layer, {ap = cc.p(0.5, 0.5), po = cc.p(
		display.cx,
		display.cy
	)})
	layer:setTag(tag)
	uiMgr:GetCurrentScene():AddDialog(layer)
end
--[[
更换一批竞技场对手
--]]
function PVCMediator:ShuffleAllRivals()
	local shuffleCostConfig = {
		goodsId = DIAMOND_ID,
		amount = 5
	}
	local goodsConfig = CommonUtils.GetConfig('goods', 'goods', shuffleCostConfig.goodsId)

	local remindTips = ''

	-- 可行性检查
	if 0 >= checkint(self:GetPVCData().matchFreeTimes) then
		-- 免费次数耗尽
		if shuffleCostConfig.amount > gameMgr:GetAmountByIdForce(shuffleCostConfig.goodsId) then
			-- 消耗道具不足 弹提示
			if GAME_MODULE_OPEN.NEW_STORE and checkint(shuffleCostConfig.goodsId) == DIAMOND_ID then
				app.uiMgr:showDiamonTips()
			else
				uiMgr:ShowInformationTips(string.format(__('%s不足!!!'), goodsConfig.name))
			end
			return
		end

		remindTips = string.format(__('本次需要消耗%d%s,确定要换一批?'), shuffleCostConfig.amount, goodsConfig.name)
	else
		-- 免费次数没有耗尽
		remindTips = __('本次免费,确定要换一批?')
	end

	local layer = require('common.CommonTip').new({
		text = remindTips,
		callback = function (sender)
			self:SendSignal(COMMANDS.COMMANDS_PVC_OfflineArena_MatchOpponent)
		end
	})
	layer:setPosition(display.center)
	uiMgr:GetCurrentScene():AddDialog(layer)
end
--[[
更换一批竞技场对手回调
@params responseData table server response data
--]]
function PVCMediator:ShuffleAllRivalsCallback(responseData)
	------------ data ------------
	-- 刷新本地pvc home数据
	local newPVCData = {
		matchFreeTimes = checkint(responseData.matchFreeTimes),
		matchOpponent = responseData.matchOpponent
	}
	self:UpdatePVCData(newPVCData)

	-- 刷新幻晶石数量
	local diamondInfo = {
		{goodsId = DIAMOND_ID, num = checkint(responseData.diamond) - gameMgr:GetAmountByIdForce(DIAMOND_ID)}
	}
	CommonUtils.DrawRewards(diamondInfo)

	-- 置空userDefault保存的对手id
	self.rivalPlayerId = 0
	gameMgr:SetLocalPVCRivalPlayerId(self.rivalPlayerId)
	------------ data ------------

	------------ view ------------
	-- 更换成功提示
	uiMgr:ShowInformationTips(__('更换成功!!!'))

	-- 刷新选对手弹窗
	local layer = uiMgr:GetCurrentScene():GetDialogByTag(selectRivalLayerTag)
	if layer then
		-- 刷新对手信息
		layer:RefreshAllRivals(responseData.matchOpponent)
		-- 刷新剩余次数
		layer:RefreshShuffleInfo(self:GetPVCData().matchFreeTimes, MAX_FREE_SHUFFLE_RIVAL_TIMES)
	end

	-- 置空home当前选手状态
	self:GetViewComponent():RefreshRivalInfo()
	------------ view ------------
end
--[[
选择一个对手
@params data table {
	rivalInfo table 对手信息
}
--]]
function PVCMediator:SelectARival(data)
	local rivalInfo = data.rivalInfo
	local rivalPlayerId = checkint(rivalInfo.opponentId)
	if 0 == rivalPlayerId then
		uiMgr:ShowInformationTips(__('选择的对手无效!!!'))
		return
	end

	------------ data ------------
	-- 将对手id保存到本地文件
	self.rivalPlayerId = rivalPlayerId
	gameMgr:SetLocalPVCRivalPlayerId(self.rivalPlayerId)
	------------ data ------------

	------------ view ------------
	-- 刷新对手
	self:GetViewComponent():RefreshRivalInfo(rivalInfo)
	-- 弹提示
	uiMgr:ShowInformationTips(__('选择对手成功!!!'))
	local layer = uiMgr:GetCurrentScene():GetDialogByTag(selectRivalLayerTag)
	if layer then
		layer:CloseHandler()
	end
	------------ view ------------
end
--[[
倒计时回调
--]]
function PVCMediator:RefreshCountDownCallback(countdown, remindTag, timeNum, datas)
	if self.isInRefresh then
		return
	end

	-- local newCDTime = math.max(0, checkint(self:GetPVCData().refreshTime) - 1)
	local newCDTime = math.max(0, countdown)
	local newSeasonCDTime = math.max(0, checkint(self:GetPVCData().seasonRefreshTime) - 1)

	------------ data ------------
	if 0 >= newCDTime or 0 >= newSeasonCDTime then
		self:RefreshAll()
		return
	end

	local newPVCData = {
		refreshTime = newCDTime,
		seasonRefreshTime = newSeasonCDTime
	}
	self:UpdatePVCData(newPVCData)
	------------ data ------------

	------------ view ------------
	self:RefreshPVCSceneByTimer()
	------------ view ------------
end
--[[
拉一次home刷新整个场景
--]]
function PVCMediator:RefreshAll()
	uiMgr:ShowInformationTips(__('开始刷新!!!'))
	self.isInRefresh = true
	self:SendSignal(COMMANDS.COMMANDS_PVC_OfflineArena_Home)
end
--[[
刷新所有
@params responseData table server response data
--]]
function PVCMediator:RefreshAllCallback(responseData)
	------------ data ------------
	self:SetPVCData(responseData)
	timerMgr:RetriveTimer(PVC_REFRESH_TIMER_NAME).countdown = checkint(self:GetPVCData().refreshTime)
	timerMgr:ResumeTimer(PVC_REFRESH_TIMER_NAME)
	------------ data ------------

	------------ view ------------
	uiMgr:ShowInformationTips(__('已刷新!!!'))
	-- 刷新界面
	self:GetViewComponent():RefreshUI(self:GetPVCData(), self.rivalPlayerId)
	------------ view ------------

	self.isInRefresh = false
end
--[[
根据时间倒计时刷新pvc主场景
--]]
function PVCMediator:RefreshPVCSceneByTimer()
	-- 刷新时间倒计时
	self:GetViewComponent():RefreshPVCLeftRefreshTime(checkint(self:GetPVCData().refreshTime))
end
--[[
进入战斗
--]]
function PVCMediator:ReadyToDuel()
	-- 可行性判断
	if 0 >= checkint(self:GetPVCData().remainTimes) then
		-- 没有剩余次数
		uiMgr:ShowInformationTips(__('剩余次数已用完!!!'))
		return
	end

	if 0 == checkint(self.rivalPlayerId) or nil == self:GetRivalInfoByPlayerId(checkint(self.rivalPlayerId)) then
		uiMgr:ShowInformationTips(__('选择的对手无效!!!'))
		return
	end

	AppFacade.GetInstance():DispatchObservers("DOT_LOG_EVENT_SEND" , {eventId = "42-01"})
	AppFacade.GetInstance():DispatchObservers("DOT_SET_LOG_EVENT" , {eventId = "42-02"})
	-- 可以进行战斗
	local serverCommand = BattleNetworkCommandStruct.New(
		POST.PVC_QUEST_AT.cmdName,
		{opponentId = self.rivalPlayerId},
		POST.PVC_QUEST_AT.sglName,
		POST.PVC_QUEST_GRADE.cmdName,
		{opponentId = self.rivalPlayerId},
		POST.PVC_QUEST_GRADE.sglName,
		nil,
		nil,
		nil
	)

	local fromToStruct = BattleMediatorsConnectStruct.New(
		NAME,
		NAME
	)

	local rivalTeamData = self:GetRivalInfoByPlayerId(checkint(self.rivalPlayerId))

	local battleConstructor = require('battleEntry.BattleConstructor').new()

	battleConstructor:InitDataByPVC(
		self:GetPVCData().fightTeam,
		rivalTeamData,
		nil,
		serverCommand,
		fromToStruct
	)

	if not AppFacade.GetInstance():RetrieveMediator('EnterBattleMediator') then
		local enterBattleMediator = require('Game.mediator.EnterBattleMediator').new()
		AppFacade.GetInstance():RegistMediator(enterBattleMediator)
	end
	GuideUtils.DispatchStepEvent()
	AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.Battle_Enter, battleConstructor)

	-- 刷掉一次本地保存的对手id
	cc.UserDefault:getInstance():setStringForKey(PVC_LOCAL_RIVAL_ID_KEY, 0)
	cc.UserDefault:getInstance():flush()
end
--[[
领取首胜奖励
--]]
function PVCMediator:DrawFirstWinReward()
	-- 可行性判断
	if 1 == self:GetPVCData().firstWinStatus then
		self:SendSignal(COMMANDS.COMMANDS_PVC_OfflineArena_FirstWinReward)
	else
		PlayAudioClip(AUDIOS.UI.ui_mission.id)
		local tag = rewardsDetailLayerTag
		local rewards = CommonUtils.GetConfigAllMess('firstWinReward' ,'arena').rewards
		local layer = require('common.RewardDetailPopup').new({tag = tag, rewards = rewards})
		display.commonUIParams(layer, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
		layer:setTag(tag)
		uiMgr:GetCurrentScene():AddDialog(layer)
	end
end
--[[
领取首胜奖励成功
@params responseData table server response data
--]]
function PVCMediator:DrawFirstWinRewardCallback(responseData)
	------------ data ------------
	-- 刷新本地奖励
	uiMgr:AddDialog('common.RewardPopup', {
		rewards = responseData.reward,
		tag = activePointRewardLayerTag
	})

	-- 刷新本地数据
	local newPVCData = {
		firstWinStatus = 2
	}
	self:UpdatePVCData(newPVCData)
	------------ data ------------

	------------ view ------------
	self:GetViewComponent():RefreshFirstWinReward(checkint(responseData.firstWinStatus))
	------------ view ------------
end
--[[
活跃度奖励打脸
--]]
function PVCMediator:DrawActivePointRewards()
	if nil ~= self:GetPVCData().activityPointReward and 0 < #self:GetPVCData().activityPointReward then
		-- 先弹第一个
		local rewardData = self:GetPVCData().activityPointReward[1]

		uiMgr:AddDialog('common.RewardPopup', {
			rewards = rewardData,
			tag = activePointRewardLayerTag,
			closeCallback = handler(self, self.DrawActivePointRewards)
		})

		-- 删除第一个奖励的信息
		table.remove(self:GetPVCData().activityPointReward, 1)
		if 0 >= #self:GetPVCData().activityPointReward then
			self:GetPVCData().activityPointReward = nil
		end
	end
end
--[[
购买奖励次数
--]]
function PVCMediator:BuyChallengeTime()
	local costInfo = {goodsId = DIAMOND_ID, num = 25}

	local challengeTimes = CommonUtils.getVipTotalLimitByField('pvp')
	local textRich = {
		{text = __('确定要追加')},
		{text = tostring(CommonUtils.getVipTotalLimitByField('pvp')), fontSize = 26, color = '#ff0000'},
		{text = __('次挑战次数吗?')}
	}
	local descrRich = {
		{text = __('当前还可以购买')},
		{text = tostring(self:GetPVCData().buyPvpNum), fontSize = fontWithColor('15').fontSize, color = '#ff0000'},
		{text = __('次')},
	}
	-- 显示购买弹窗
	local layer = require('common.CommonTip').new({
		textRich = textRich,
		descrRich = descrRich,
		defaultRichPattern = true,
		costInfo = costInfo,
		callback = handler(self, self.BuyChallengeTimeClickHandler)
	})
	layer:setPosition(display.center)
	uiMgr:GetCurrentScene():AddDialog(layer)

end
--[[
购买奖励次数回调
--]]
function PVCMediator:BuyChallengeTimeClickHandler()
	local costInfo = {goodsId = DIAMOND_ID, num = 25}

	-- 可行性判断
	local goodsAmount = gameMgr:GetAmountByIdForce(costInfo.goodsId)
	if costInfo.num > goodsAmount then
		if GAME_MODULE_OPEN.NEW_STORE and checkint(costInfo.goodsId) == DIAMOND_ID then
			app.uiMgr:showDiamonTips()
		else
			local goodsConfig = CommonUtils.GetConfig('goods', 'goods', costInfo.goodsId)
			uiMgr:ShowInformationTips(string.format(__('%s不足!!!'), goodsConfig.name))
		end
		return
	end

	if 0 >= checkint(self:GetPVCData().buyPvpNum) then
		uiMgr:ShowInformationTips(__('剩余购买次数已用完!!!'))
		return
	end

	self:SendSignal(COMMANDS.COMMANDS_PVC_OfflineArena_BuyArenaQuestTimes)
end
--[[
购买奖励次数服务器回调
@params responseData table server response data
--]]
function PVCMediator:BuyChallengeTimeCallback(responseData)
	------------ data ------------
	-- 刷新本地数据
	local newPVCData = {
		buyPvpNum = self:GetPVCData().buyPvpNum - 1,
		remainTimes = checkint(responseData.pvpNum)
	}
	self:UpdatePVCData(newPVCData)

	-- 刷新幻晶石数量
	local diamondInfo = {
		{goodsId = DIAMOND_ID, num = checkint(responseData.diamond) - gameMgr:GetAmountByIdForce(DIAMOND_ID)}
	}
	CommonUtils.DrawRewards(diamondInfo)
	------------ data ------------

	------------ view ------------
	uiMgr:ShowInformationTips(__('购买挑战次数成功!!!'))
	self:GetViewComponent():RefreshPVCLeftFightTimes(checkint(self:GetPVCData().remainTimes))
	------------ view ------------
end
--[[
查看竞技场战报
--]]
function PVCMediator:ShowCheckRecord()
	self:SendSignal(COMMANDS.COMMANDS_PVC_OfflineArena_ArenaRecord)
end
--[[
查卡竞技场战报服务器回调
@params responseData table server response data
--]]
function PVCMediator:ShowCheckRecordCallback(responseData)
	local tag = reportLayerTag
	local layer = require('Game.views.pvc.PVCReportView').new({
		tag = reportLayerTag,
		winTimes = checkint(self:GetPVCData().victoryTimes),
		loseTimes = checkint(self:GetPVCData().failureTimes),
		reportData = responseData.opponents
	})
	layer:setTag(tag)
	layer:setAnchorPoint(cc.p(0.5, 0.5))
	layer:setPosition(cc.p(display.cx, display.cy))
	uiMgr:GetCurrentScene():AddDialog(layer)
end
--[[
显示竞技场排行榜
--]]
function PVCMediator:ShowPVCRank()
	AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = "PVCMediator"},
		{name = "RankingListMediator", params = {rankTypes = RankTypes.PVC_WEEKLY}})
end
--[[
显示竞技场商城
--]]
function PVCMediator:ShowPVCShop()
	if GAME_MODULE_OPEN.NEW_STORE then
		app.uiMgr:showGameStores({storeType = GAME_STORE_TYPE.GROCERY, subType = GAME_STORE_TYPE.PVP_ARENA})
	else
		app.router:Dispatch({name = "HomeMediator"}, {name = "ShopMediator",params = {goShopIndex = 'arena'}})
	end
end
--[[
退出竞技场
--]]
function PVCMediator:ExitPVCHome()
	app.router:Dispatch({name = NAME}, {name = self:GetBackToMediator()})
end
---------------------------------------------------
-- view control end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
友方阵容信息字符串转换成通用数据结构
@params slist list 字符串集合
@return teamData list 队伍信息
--]]
function PVCMediator:ConvertTeamDataByString(slist)
	local teamData = {}
	for i,v in ipairs(slist) do
		teamData[i] = {}
		local cardId = self:GetViewComponent():GetIdByCardDataString(v)
		if nil ~= cardId then
			local cardData = gameMgr:GetCardDataById(cardId)
			if nil ~= cardId then
				teamData[i] = {id = checkint(cardData.id)}
			end
		end
	end
	return teamData
end
--[[
友方阵容信息转换成服务器用字符串
@params teamData table 阵容信息
@return result string 友方阵容信息字符串
--]]
function PVCMediator:ConvertTeamData2String(teamData)
	local result = ''
	for i,v in ipairs(teamData) do
		if nil ~= v.id then
			result = result .. tostring(v.id) .. ','
		else
			result = result .. ','
		end
	end

	result = string.sub(result, 1, (string.len(result) - 1))

	return result
end
--[[
友方阵容信息数据转换 字符串->基础结构
@params teamStr string 字符串
@params slist list 字符串集合
--]]
function PVCMediator:ConvertTeamDataFromString2StrList(teamStr)
	local ss = string.split(teamStr, ',')
	slist = ss
	return slist
end

------------ 竞技场数据 ------------
function PVCMediator:SetPVCData(data)
	self.pvcData = data
end
function PVCMediator:GetPVCData()
	return self.pvcData
end
function PVCMediator:UpdatePVCData(data)
	for k,v in pairs(data) do
		self.pvcData[k] = v
	end
end
function PVCMediator:GetRivalInfoByPlayerId(playerId)
	for i,v in ipairs(self:GetPVCData().matchOpponent) do
		if playerId == checkint(v.opponentId) then
			return v.defenseTeam
		end
	end
	return nil
end
--[[
获取返回的mediator信息
@return name string 返回的mediator名字
--]]
function PVCMediator:GetBackToMediator()
	local name = 'HomeMediator'
	if nil ~= self:GetPVCData().requestData and nil ~= self:GetPVCData().requestData.backMediatorName then
		name = self:GetPVCData().requestData.backMediatorName
	end
	return name
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return PVCMediator
