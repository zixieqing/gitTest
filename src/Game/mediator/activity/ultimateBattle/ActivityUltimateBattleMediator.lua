--[[
 * author : liuzhipeng
 * descpt : 巅峰对决 Mediator
]]
local Mediator = mvc.Mediator
local ActivityUltimateBattleMediator = class("ActivityUltimateBattleMediator", Mediator)
local NAME = "activity.ultimateBattle.ActivityUltimateBattleMediator"

local ULTIMATE_BATTLE_ATTEND_TIMES = 20 -- 每期参加次数
local ULTIMATE_BATTLE_BUY_ATTEND_TIMES = 5 -- 每次购买增加次数
local ULTIMATE_BATTLE_BUY_ATTEND_TIMES_PRICE = 50 -- 购买钻石价格
local COUNT_DOWN_TAG_ULTIMATE = 'COUNT_DOWN_TAG_ULTIMATE' 
local ULTIMATE_BATTLE_SELECTED_TEAM_ID = 'ULTIMATE_BATTLE_SELECTED_TEAM_ID' 

function ActivityUltimateBattleMediator:ctor( params, viewComponent )
	self.super:ctor(NAME, viewComponent)
	self.activityData = {} -- 活动home数据
	self.isControllable_ = true
	self.selectedTeamId = 1
end


function ActivityUltimateBattleMediator:InterestSignals()
	local signals = {
        POST.ACTIVITY_ULTIMATE_BATTLE_HOME.sglName,
        POST.ACTIVITY_ULTIMATE_BATTLE_DRAW.sglName,
        POST.ACTIVITY_ULTIMATE_BATTLE_BUY_ATTEND_TIMES.sglName,
	}
	return signals
end

function ActivityUltimateBattleMediator:ProcessSignal( signal )
	local name = signal:GetName()
	-- print(name)
	local body = checktable(signal:GetBody())
	if name == POST.ACTIVITY_ULTIMATE_BATTLE_HOME.sglName then
		self.homeData = self:InitHomeData(body)
		self:InitView()
	elseif name == POST.ACTIVITY_ULTIMATE_BATTLE_DRAW.sglName then
		local viewComponent = self:GetViewComponent()
		local homeData =self:GetHomeData()
		local idx = nil
		local rewardsData = nil
		for i, v in ipairs(homeData.battleRewards) do
			if checkint(v.groupId) == body.requestData.groupId then
				v.hasDrawn = 1
				idx = i
				rewardsData = v
				break
			end
		end
		viewComponent:RefreshRewardsNode(viewComponent.viewData.rewardNodeList[idx], rewardsData)
		app.uiMgr:AddDialog('common.RewardPopup', {rewards = body.rewards})
	elseif name == POST.ACTIVITY_ULTIMATE_BATTLE_BUY_ATTEND_TIMES.sglName then
		-- 更新钻石属性
		app.gameMgr:GetUserInfo().diamond = body.diamond
		app:DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI,{diamond = body.sdiamond})
		local homeData =self:GetHomeData()
		homeData.leftAttendTimes = homeData.leftAttendTimes + ULTIMATE_BATTLE_BUY_ATTEND_TIMES
		self:RefreshLeftTimes()
	end
end

function ActivityUltimateBattleMediator:Initial( key )
    self.super.Initial(self, key)
    
	local viewComponent = require( 'Game.views.activity.ultimateBattle.ActivityUltimateBattleView' ).new()
	display.commonUIParams(viewComponent, {ap = display.CENTER, po = display.center})
	self:SetViewComponent(viewComponent)
	local viewData = viewComponent:GetViewData()
	viewData.tipsBtn:setOnClickScriptHandler(handler(self, self.TipsButtonCallback))
	viewData.buyTimesBtn:setOnClickScriptHandler(handler(self, self.BuyTimesButtonCallback))
	viewData.selectTeamBtn:setOnClickScriptHandler(handler(self, self.SelectTeamButtonCallback))
	viewData.pageupBtn:setOnClickScriptHandler(handler(self, self.PageupButtonCallback))
	viewData.pagedownBtn:setOnClickScriptHandler(handler(self, self.PagedownButtonCallback))
	viewData.rankBtn:setOnClickScriptHandler(handler(self, self.RankButtonCallback))
	for i, v in ipairs(viewData.rewardNodeList) do	
		v.bgBtn:setOnClickScriptHandler(handler(self, self.PreviewButtonCallback))
		-- v.drawBtn:setOnClickScriptHandler(handler(self, self.DrawButtonCallback))
	end
end

function ActivityUltimateBattleMediator:enterLayer()
	self:SendSignal(POST.ACTIVITY_ULTIMATE_BATTLE_HOME.cmdName)
end

function ActivityUltimateBattleMediator:CleanupView()
	local viewComponent = self:GetViewComponent()
	local scene = app.uiMgr:GetCurrentScene()
    if scene and viewComponent and not tolua.isnull(viewComponent) then
		scene:RemoveGameLayer(viewComponent)
		scene:RemoveViewForNoTouch()
    end
end

function ActivityUltimateBattleMediator:OnRegist(  )
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "show")
	regPost(POST.ACTIVITY_ULTIMATE_BATTLE_HOME)
	regPost(POST.ACTIVITY_ULTIMATE_BATTLE_DRAW)
	regPost(POST.ACTIVITY_ULTIMATE_BATTLE_BUY_ATTEND_TIMES)
	self:enterLayer()
end

function ActivityUltimateBattleMediator:OnUnRegist(  )
	unregPost(POST.ACTIVITY_ULTIMATE_BATTLE_HOME)
	unregPost(POST.ACTIVITY_ULTIMATE_BATTLE_DRAW)
	unregPost(POST.ACTIVITY_ULTIMATE_BATTLE_BUY_ATTEND_TIMES)
	if app.timerMgr:RetriveTimer(COUNT_DOWN_TAG_ULTIMATE) then
		app.timerMgr:RemoveTimer(COUNT_DOWN_TAG_ULTIMATE)
	end
end
-------------------------------------
-------------- handler --------------
--[[
提示按钮点击回调
--]]
function ActivityUltimateBattleMediator:TipsButtonCallback( sender )
	PlayAudioByClickNormal()
	app.uiMgr:ShowIntroPopup({moduleId = JUMP_MODULE_DATA.ULTIMATE_BATTLE})
end
--[[
上一页按钮点击回调
--]]
function ActivityUltimateBattleMediator:PageupButtonCallback( sender )
	PlayAudioByClickNormal()
	if self.selectedTeamId > 1 then
		self.selectedTeamId = self.selectedTeamId - 1
	end
	self:RefreshTeam()
	cc.UserDefault:getInstance():setStringForKey(ULTIMATE_BATTLE_SELECTED_TEAM_ID, tostring(self.selectedTeamId))
end
--[[
下一页按钮点击回调
--]]
function ActivityUltimateBattleMediator:PagedownButtonCallback( sender )
	PlayAudioByClickNormal()
	if self.selectedTeamId < #self:GetHomeData().enemies then
		self.selectedTeamId = self.selectedTeamId + 1
	end
	self:RefreshTeam()
	cc.UserDefault:getInstance():setStringForKey(ULTIMATE_BATTLE_SELECTED_TEAM_ID, tostring(self.selectedTeamId))
end
--[[
购买次数按钮点击回调
--]]
function ActivityUltimateBattleMediator:BuyTimesButtonCallback( sender )
	PlayAudioByClickNormal()
	app.uiMgr:AddCommonTipDialog({
		callback = function () 
			self:SendSignal(POST.ACTIVITY_ULTIMATE_BATTLE_BUY_ATTEND_TIMES.cmdName, {times = 1})
		end,
		text = string.fmt(__('是否花费_num1_幻晶石购买_num2_次挑战次数？'), {['_num1_'] = ULTIMATE_BATTLE_BUY_ATTEND_TIMES_PRICE, ['_num2_'] = ULTIMATE_BATTLE_BUY_ATTEND_TIMES}) ,
	})
end
--[[
选择队伍按钮点击回调
--]]
function ActivityUltimateBattleMediator:SelectTeamButtonCallback( sender )
	PlayAudioByClickNormal()
	if not self.isControllable_ then 
		app.uiMgr:ShowInformationTips(__('活动已结束'))
		return 
	end
	local homeData = self:GetHomeData()
	if checkint(homeData.leftAttendTimes) <= 0 then
		app.uiMgr:ShowInformationTips(__('挑战次数不足'))
		return
	end
	-- 构建战斗数据
	local groupId = self:GetGroupId()
	AppFacade.GetInstance():DispatchObservers("DOT_LOG_EVENT_SEND" , {eventId = "94-01"})
	AppFacade.GetInstance():DispatchObservers("DOT_SET_LOG_EVENT" , {eventId = "94-02"})
	local serverCommand = BattleNetworkCommandStruct.New(
		POST.ACTIVITY_ULTIMATE_BATTLE_QUEST_AT.cmdName ,
		{groupId = groupId},
		POST.ACTIVITY_ULTIMATE_BATTLE_QUEST_AT.sglName,

		POST.ACTIVITY_ULTIMATE_BATTLE_QUEST_GRADE.cmdName ,
		{groupId = groupId},
		POST.ACTIVITY_ULTIMATE_BATTLE_QUEST_GRADE.sglName,

		nil,
		nil,
		nil
	)
	local fromToStruct = BattleMediatorsConnectStruct.New(
		"activity.ultimateBattle.ActivityUltimateBattleMediator",
		"ActivityMediator"
	)
	local battleData = {
		questBattleType = QuestBattleType.ULTIMATE_BATTLE,
		settlementType = ConfigBattleResultType.ONLY_RESULT,
		rivalTeamData = homeData.enemies[self.selectedTeamId].cards,
		serverCommand = serverCommand,
		fromtoData = fromToStruct
	}
	local teamData = {}
	if homeData.enemies[self.selectedTeamId].lastChallengeCards then
		for i, v in ipairs(homeData.enemies[self.selectedTeamId].lastChallengeCards) do
			table.insert(teamData, {id = v})
		end
	end
	local banConfig = CommonUtils.GetConfig('ultimateBattle', 'ban', homeData.enemies[self.selectedTeamId].enemyId)
	local editTeamLayer = require('Game.views.pvc.PVCChangeTeamScene').new({
		teamDatas             = {[1] = teamData},
		teamTowards           = -1,
		avatarTowards         = 1,
		isDisableHomeTopSignal = true,
		battleData 	 	 	  = battleData,
		banList 	 	      = banConfig,
	}) 
	editTeamLayer:setAnchorPoint(display.CENTER)
	editTeamLayer:setPosition(display.center)
	editTeamLayer:setTag(4001)
	app.uiMgr:GetCurrentScene():AddDialog(editTeamLayer)
end
--[[
领取奖励按钮点击回调
--]]
function ActivityUltimateBattleMediator:DrawButtonCallback( sender )
	PlayAudioByClickNormal()
	if not self.isControllable_ then 
		app.uiMgr:ShowInformationTips(__('活动已结束'))
		return 
	end
	local tag = sender:getTag()
	self:SendSignal(POST.ACTIVITY_ULTIMATE_BATTLE_DRAW.cmdName, {groupId = self:GetGroupId(tag)})
end
--[[
奖励预览按钮点击回调
--]]
function ActivityUltimateBattleMediator:PreviewButtonCallback( sender )
	PlayAudioByClickNormal()
	local tag = sender:getTag()
	local homeData = self:GetHomeData()
	local rewardsDetail = homeData.battleRewards[tag].rewardsDetail
	app.uiMgr:ShowInformationTipsBoard({
		targetNode = sender, iconIds = rewardsDetail, type = 4, title = __('奖励预览'),
	})
end
--[[
排行榜按钮点击回调
--]]
function ActivityUltimateBattleMediator:RankButtonCallback( sender )
	PlayAudioByClickNormal()
	if not self.isControllable_ then 
		app.uiMgr:ShowInformationTips(__('活动已结束'))
		return 
	end
	local NumKeyboardMediator = require( 'Game.mediator.activity.ultimateBattle.ActivityUltimateBattleRankMediator' )
	local mediator = NumKeyboardMediator.new({leftSeconds = self:GetHomeData().leftSeconds})
	self:GetFacade():RegistMediator(mediator)
end
--[[
倒计时
--]]
function ActivityUltimateBattleMediator:TimeUpdateHandler( countdown, remindTag, timeNum, datas, timerName )
	local viewComponent = self:GetViewComponent()
	if countdown > 0 then
		viewComponent:UpdateTimeLabel(countdown)
	else 
		viewComponent:UpdateTimeLabel(0)
		self.isControllable_ = false
	end
end
-------------- handler --------------
-------------------------------------

-------------------------------------
-------------- private --------------
--[[
初始化数据
--]]
function ActivityUltimateBattleMediator:InitHomeData( homeData )
	local homeData_ = checktable(homeData)
	local battleRewards_ = {}
	for _, enemyData in ipairs(homeData_.enemies) do
		for _, rewards in ipairs(homeData_.battleRewards) do
			if checkint(rewards.groupId) == checkint(enemyData.groupId) then
				table.insert(battleRewards_, rewards)
				break
			end
		end
	end
	homeData_.battleRewards = battleRewards_
	return homeData_
end
--[[
初始化view
--]]
function ActivityUltimateBattleMediator:InitView()
	local viewComponent = self:GetViewComponent()
	local homeData = self:GetHomeData()
	if app.timerMgr:RetriveTimer(COUNT_DOWN_TAG_ULTIMATE) then
        app.timerMgr:RemoveTimer(COUNT_DOWN_TAG_ULTIMATE)
	end
	if checkint(homeData.leftSeconds) > 0 then
		viewComponent:UpdateTimeLabel(homeData.leftSeconds)
		app.timerMgr:AddTimer({name = COUNT_DOWN_TAG_ULTIMATE, callback = handler(self, self.TimeUpdateHandler), countdown = homeData.leftSeconds})
	end
	self:RefreshSelectedTeamId()
	self:RefreshRewardsList()
	self:RefreshLeftTimes()
	self:RefreshTeam()
	-- 检测是否就奖励可领取（为了省去小红点）
	self:CheckReawrds()
end
--[[
刷新选中编队Id
--]]
function ActivityUltimateBattleMediator:RefreshSelectedTeamId()
	local homeData = self:GetHomeData()
	local maxTeamId = table.nums(homeData.enemies)
	local teamId = checkint(cc.UserDefault:getInstance():getStringForKey(ULTIMATE_BATTLE_SELECTED_TEAM_ID, ''))
	if teamId <= 0 or teamId > maxTeamId then
		teamId = 1
	end
	self:SetSelectedTeamId(teamId)
end
--[[
刷新奖励列表
--]]
function ActivityUltimateBattleMediator:RefreshRewardsList()
	local rewardsData = self:GetHomeData().battleRewards
	local viewComponent = self:GetViewComponent()
	for i, v in ipairs(viewComponent:GetViewData().rewardNodeList) do
		v.node:setVisible(true)
		viewComponent:RefreshRewardsNode(v, rewardsData[i])
	end
end
--[[
刷新剩余次数
--]]
function ActivityUltimateBattleMediator:RefreshLeftTimes()
	local homeData = self:GetHomeData()
	local viewComponent = self:GetViewComponent()
	viewComponent:RefreshLeftTimes(checkint(homeData.leftAttendTimes), ULTIMATE_BATTLE_ATTEND_TIMES)
end
--[[
刷新编队
--]]
function ActivityUltimateBattleMediator:RefreshTeam()
	local homeData = self:GetHomeData()
	local viewComponent = self:GetViewComponent()
	local teamData = homeData.enemies[self.selectedTeamId]
	local groupConfig = CommonUtils.GetConfig('ultimateBattle', 'group', teamData.groupId)
	local params = {
		cards = teamData.cards,
		name = groupConfig.name,
		difficulty = groupConfig.display,
		teamNum = #homeData.enemies, 
		teamId = self.selectedTeamId,
	}
	viewComponent:RefereshTeamLayout(params)
end
--[[
检查是否有奖励未领取
--]]
function ActivityUltimateBattleMediator:CheckReawrds()
	local homeData = self:GetHomeData()
	for i, v in ipairs(homeData.battleRewards) do
		if checkint(v.canDrawn) == 1 and checkint(v.hasDrawn) == 0 then
			-- 存在未领取的奖励，发送领取请求
			self:SendSignal(POST.ACTIVITY_ULTIMATE_BATTLE_DRAW.cmdName, {groupId = v.groupId})
			break
		end
	end
end
-------------- private --------------
-------------------------------------

-------------------------------------
-------------- get/set --------------
--[[
获取homeData
--]]
function ActivityUltimateBattleMediator:GetHomeData()
	return self.homeData or {}
end
--[[
获取组别id
--]]
function ActivityUltimateBattleMediator:GetGroupId( teamId )
	return checkint(self:GetHomeData().battleRewards[checkint(teamId or self.selectedTeamId)].groupId)
end
--[[
设置选中的编队Id 
--]]
function ActivityUltimateBattleMediator:SetSelectedTeamId( selectedTeamId )
	self.selectedTeamId = checkint(selectedTeamId)
end
--[[
获取选中的编队Id 
--]]
function ActivityUltimateBattleMediator:GetSelectedTeamId()
	return self.selectedTeamId
end
-------------- get/set --------------
-------------------------------------
return ActivityUltimateBattleMediator