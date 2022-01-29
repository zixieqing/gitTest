--[[
世界boss管理器
@params table {
	
}
--]]
local Mediator = mvc.Mediator
local WorldBossMediator = class("WorldBossMediator", Mediator)
local NAME = "WorldBossMediator"

------------ import ------------
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local timerMgr = AppFacade.GetInstance():GetManager("TimerManager")
------------ import ------------

------------ define ------------
local WB_CHANGE_TEAM_MEMBER_SIGNAL = 'WB_CHANGE_TEAM_MEMBER_SIGNAL'
local LOCAL_WB_TEAM_MEMBERS_KEY = 'LOCAL_WB_TEAM_MEMBERS_KEY'
local WB_REFRESH_TIMER_NAME = 'WB_REFRESH_TIMER_NAME'
local LOCAL_WB_TEAM_CUSTOM_ID_KEY = 'LOCAL_WB_TEAM_CUSTOM_ID_KEY'

local changeTeamMemberViewTag = 8801
local battleBuffViewTag = 8802
------------ define ------------

--[[
constructor
--]]
function WorldBossMediator:ctor(params, viewComponent)
	Mediator.ctor(self, NAME, viewComponent)

	self.questId = checkint(params.questId)
	
	-- self.bossData = params
	-- self.questId = self.bossData.requestData.questId

	-- self.bossData = {
	-- 	requestData = {questId = 20001},
	-- 	remainHp = 1,
	-- 	leftSeconds = 3000,
	-- 	currentDamage = 888,
	-- 	maxDamage = 999,
	-- 	leftTimes = 1
	-- }
	-- self.questId = self.bossData.requestData.questId
end
---------------------------------------------------
-- mediator extend begin --
---------------------------------------------------
function WorldBossMediator:InterestSignals()
	local signals = {
		------------ server ------------
		POST.WORLD_BOSS_BUY_BUFF.sglName,
		POST.WORLD_BOSS_HOME.sglName,
		POST.PRESET_TEAM_GET_TEAM_CUSTOM_DETAIL.sglName,
		------------ local ------------
		'WB_SHOW_EDIT_TEAM_MEMBER',
		'WB_SHOW_READY_ENTER_BATTLE',
		'WB_SHOW_BOSS_DETAIL',
		'WB_SHOW_REWARD_REVIEW',
		'WB_SHOW_RANK',
		'WB_SHOW_MANUAL',
		'WB_ENTER_BATTLE',
		'WB_BUY_BUFF',
		WB_CHANGE_TEAM_MEMBER_SIGNAL,
		SGL.PRESET_TEAM_SELECT_CARDS,
	}

	return signals
end
function WorldBossMediator:ProcessSignal(signal)
	local name = signal:GetName()
	local responseData = signal:GetBody()

	if POST.WORLD_BOSS_HOME.sglName == name then

		self:RefreshAllCallback(responseData)

	elseif POST.WORLD_BOSS_BUY_BUFF.sglName == name then

		-- 购买buff回调
		self:BuyWBBuffCallback(responseData)

	elseif POST.PRESET_TEAM_GET_TEAM_CUSTOM_DETAIL.sglName == name then

		if checkint(responseData.valid) == 1 then
			-- 刷新预设编队
			self:RefreshPresetTeam(responseData)
        else
            app.uiMgr:ShowInformationTips(__('当前预设编队已失效'))
        end

	elseif 'WB_SHOW_EDIT_TEAM_MEMBER' == name then

		local teamCustomId = self:GetTeamCustomId()
		if teamCustomId > 0 then
			app.uiMgr:AddNewCommonTipDialog({
				text = __('使用预设编队不能进行单独修改，是否使用普通编队？'),
				callback = function()
					--- 清除 预设编队id
					self:SetTeamCustomId(0)
					self:SetLocalTeamCustomId()
					self:SetTeamData({})
					self:SetLocalWBTeamMembers(self:GetTeamData())
					self:GetViewComponent():RefreshTeamMember(self:GetTeamData())
					self.presetFixedTeamData_ = nil

					-- 显示编辑队伍成员界面
					self:ShowEditTeamMemberView()
				end
			})
			return
		else
			-- 显示编辑队伍成员界面
			self:ShowEditTeamMemberView()
		end

	elseif 'WB_SHOW_READY_ENTER_BATTLE' == name then

		-- 编辑队伍信号回调
		self:ShowReadyEnterBattleView()

	elseif 'WB_SHOW_BOSS_DETAIL' == name then

		-- 显示boss详情
		self:ShowBossDetail()

	elseif 'WB_SHOW_REWARD_REVIEW' == name then

		-- 显示奖励预览
		self:ShowRewardReview()

	elseif 'WB_SHOW_RANK' == name then

		-- 显示排行榜
		self:ShowRank()

	elseif 'WB_SHOW_MANUAL' == name then

		-- 显示手册
		self:ShowManual()

	elseif 'WB_ENTER_BATTLE' == name then

		-- 进入战斗
		self:ReadyEnterWBBattle(responseData)

	elseif 'WB_BUY_BUFF' == name then

		-- 购买buff
		self:BuyWBBuff(responseData)

	elseif WB_CHANGE_TEAM_MEMBER_SIGNAL == name then

		-- 编辑队伍信号回调
		self:EditTeamMemberCallback(responseData)

	elseif SGL.PRESET_TEAM_SELECT_CARDS == name then

		-- 获取预设编队的详情
		local presetTeamData = checktable(responseData.presetTeamData)
		local presetTeamId   = checkint(presetTeamData.teamId)
		self:SetTeamCustomId(presetTeamId)
		self:SetLocalTeamCustomId(presetTeamId)
		self:SendSignal(POST.PRESET_TEAM_GET_TEAM_CUSTOM_DETAIL.cmdName, {teamId = presetTeamId})
		
	end
end
function WorldBossMediator:Initial(key)
	self.super.Initial(self, key)
end
function WorldBossMediator:OnRegist()
	regPost(POST.WORLD_BOSS_HOME, true)
	regPost(POST.WORLD_BOSS_BUY_BUFF)
	regPost(POST.PRESET_TEAM_GET_TEAM_CUSTOM_DETAIL)


	-- 隐藏顶部信息
	-- self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightHide")
	-- self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "allhide")
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "GONE")

	-- 请求一次home
	self:SendSignal(POST.WORLD_BOSS_HOME.cmdName, {questId = self:GetWorldBossQuestId()})
end
function WorldBossMediator:OnUnRegist()
	-- 显示顶部信息
	-- self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightShow")
	-- self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "hide")
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "OPEN")

    -- 注销倒计时
    self:UnregistTimer()

    unregPost(POST.WORLD_BOSS_BUY_BUFF)
    unregPost(POST.WORLD_BOSS_HOME)
	unregPost(POST.PRESET_TEAM_GET_TEAM_CUSTOM_DETAIL)
end
---------------------------------------------------
-- mediator extend end --
---------------------------------------------------

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化数据
--]]

function WorldBossMediator:InitValue()
	-- 初始化一次编队数据
	local initTeamData = {}
	
	-- 缓存的编队数据
	local localTeamData = self:GetLocalWBTeamMembers()
	if nil ~= localTeamData and 'table' == type(localTeamData) then
		for i = 1, MAX_TEAM_MEMBER_AMOUNT do
			local t = checktable(localTeamData[i])
			if 0 ~= checkint(t.id) and app.gameMgr:GetUserInfo().cards[tostring(t.id)] then
				initTeamData[i] = {id = checkint(t.id)}
			else
				initTeamData[i] = {}
			end
		end
	end
	self:SetTeamData(initTeamData)

	-- 读取预设编队设置
	self:SetTeamCustomId(self:GetLocalTeamCustomId())
end
--[[
刷新所有
@params responseData table 服务器返回数据
--]]
function WorldBossMediator:RefreshAllCallback(responseData)
	local errcode = checkint(responseData.errcode)
	if 2 == errcode then
		-- 跳回世界地图
		AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = NAME}, {name = 'WorldMediator'})
		return
	elseif 0 ~= errcode then
		-- 跳回世界地图
		AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = NAME}, {name = 'WorldMediator'})
		return
	end

	self.bossData = responseData

	-- 正常
	self:InitValue()
	self:InitScene()

	---获取预设编队阵容卡牌数据
	if self:GetTeamCustomId() > 0 then
		self:SendSignal(POST.PRESET_TEAM_GET_TEAM_CUSTOM_DETAIL.cmdName, {teamId = self:GetTeamCustomId()})
	end

	-- 注册倒计时
	self:RegistTimer()
end
--[[
初始化场景
--]]
function WorldBossMediator:InitScene()
	-- 创建场景
	local scene = uiMgr:SwitchToTargetScene('Game.views.worldboss.WorldBossScene')
	self:SetViewComponent(scene)

	self:GetViewComponent():RefreshUI(self:GetWorldBossQuestId(), self:GetWorldBossData())
	-- 刷新阵容
	self:GetViewComponent():RefreshTeamMember(self:GetTeamData())
end
--[[
注册倒计时
--]]
function WorldBossMediator:RegistTimer()
	-- 初始化计时器
	timerMgr:AddTimer({
		name = WB_REFRESH_TIMER_NAME,
		countdown = checkint(self:GetWorldBossData().leftSeconds),
		callback = handler(self, self.RefreshCountDownCallback)
	})
end
--[[
注销倒计时
--]]
function WorldBossMediator:UnregistTimer()
	-- 移除计时器
	timerMgr:StopTimer(WB_REFRESH_TIMER_NAME)
	timerMgr:RemoveTimer(WB_REFRESH_TIMER_NAME)
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- view control begin --
---------------------------------------------------

---刷新预设编队
---@param responseData table
function WorldBossMediator:RefreshPresetTeam(responseData)
	self.presetFixedTeamData_ = {}
	
	local fixedTeamData  = {}
	local presetTeamInfo = checktable(responseData.info)[1] or {}
	for i = 1, MAX_TEAM_MEMBER_AMOUNT do
		local serverCardInfo = checktable(presetTeamInfo[i])
		if next(serverCardInfo) ~= nil then
			--- 把最新卡牌数据的 堕神和神器数据 替换为 预设编队中卡牌拥有的堕神和神器数据
			local cardUuid = checkint(serverCardInfo.id)
			local cardData = clone(gameMgr:GetCardDataById(cardUuid))
			cardData.pets  = serverCardInfo.pets or {}
			cardData.artifactTalent = serverCardInfo.artifactTalent or {}
			table.insert(self.presetFixedTeamData_, cardData)
			fixedTeamData[i] = {id = cardUuid}
		else
			fixedTeamData[i] = {}
		end
	end

	-- 刷新数据
	self:EditTeamMemberCallback({teamData = fixedTeamData})
end

--[[
显示编辑队伍成员界面
--]]
function WorldBossMediator:ShowEditTeamMemberView()

	local layer = require('Game.views.pvc.PVCChangeTeamScene').new({
		teamDatas = {[1] = self:GetTeamData()},
		title = __('编辑队伍'),
		teamTowards = 1,
		avatarTowards = 1,
		teamChangeSingalName = WB_CHANGE_TEAM_MEMBER_SIGNAL,
		battleType = 1
	})
	layer:setAnchorPoint(cc.p(0.5, 0.5))
	layer:setPosition(display.center)
	layer:setTag(changeTeamMemberViewTag)
	uiMgr:GetCurrentScene():AddDialog(layer)
end
--[[
编辑队伍信号回调
@params data table 数据
--]]
function WorldBossMediator:EditTeamMemberCallback(data)
	------------ data ------------
	self:SetTeamData(data.teamData)
	-- 保存一次本地缓存
	self:SetLocalWBTeamMembers(self:GetTeamData())
	------------ data ------------

	------------ view ------------
	-- 关闭阵容界面
	AppFacade.GetInstance():DispatchObservers('CLOSE_CHANGE_TEAM_SCENE')

	self:GetViewComponent():RefreshTeamMember(self:GetTeamData())
	------------ view ------------
end
--[[
显示选buff界面
--]]
function WorldBossMediator:ShowReadyEnterBattleView()
	local view = require('Game.views.worldboss.WorldBossBuffView').new({
		questId = self:GetWorldBossQuestId(),
		buyBuffId = (checkint(self:GetWorldBossData().buffId) ~= 0) and checkint(self:GetWorldBossData().buffId) or nil
	})
	display.commonUIParams(view, {ap = cc.p(0.5, 0.5), po = display.center})
	uiMgr:GetCurrentScene():AddDialog(view)
	view:setTag(battleBuffViewTag)

	view:RefreshUI(
		checkint(self:GetWorldBossData().leftTimes),
		self:GetTeamData()
	)
end
--[[
显示boss详情
--]]
function WorldBossMediator:ShowBossDetail()
	local questId = self:GetWorldBossQuestId()
	AppFacade.GetInstance():DispatchObservers(EVENT_SHOW_BOSS_DETAIL_VIEW, {questId = questId})
end
--[[
显示奖励预览
--]]
function WorldBossMediator:ShowRewardReview()
	-- 奖励数据
	local rewardsDatas = CommonUtils.GetConfigAllMess('personalRewards', 'worldBossQuest')

	local tag = 1200
	local rankRewardsView = require('Game.views.LobbyRewardListView').new({
		tag = tag,
		showTips = true,
		title = __('本日排行榜奖励'),
		msg = __('奖励发放时间：每日 00:00'),
		rewardsDatas = rewardsDatas
	})
	rankRewardsView:setTag(tag)
	rankRewardsView:setPosition(display.center)
	uiMgr:GetCurrentScene():AddDialog(rankRewardsView)
end
--[[
显示排行榜
--]]
function WorldBossMediator:ShowRank()
	local RankingListMediator = require('Game.mediator.RankingListMediator')
	local mediator = RankingListMediator.new({rankTypes = RankTypes.BOSS_PERSON})
	self:GetFacade():RegistMediator(mediator)
end
--[[
显示手册
--]]
function WorldBossMediator:ShowManual()
	local bossManualMdt = require('Game.mediator.WorldBossManualMediator').new()
    self:GetFacade():RegistMediator(bossManualMdt)
end
--[[
倒计时控制
--]]
function WorldBossMediator:RefreshCountDownCallback(countdown)
	local newLeftSecond = math.max(0, countdown)

	------------ data ------------
	local newData = {leftSeconds = newLeftSecond}
	self:UpdateWorldBossData(newData)
	------------ data ------------

	------------ view ------------
	self:RefreshSceneByTimer()
	------------ view ------------
end
--[[
根据倒计时刷新场景
--]]
function WorldBossMediator:RefreshSceneByTimer()
	-- 刷新倒计时
	self:GetViewComponent():RefreshLeftTime(checkint(self:GetWorldBossData().leftSeconds))
end
--[[
进入世界boss战斗
@params data {
	buffId int 战前buffid
}
--]]
function WorldBossMediator:ReadyEnterWBBattle(data)
	-- 检查倒计时
	local leftTime = checkint(self:GetWorldBossData().leftSeconds)
	if 0 >= leftTime then
		uiMgr:ShowInformationTips(__('灾祸已经平息!!!'))
		return
	end

	-- 检查剩余次数
	local leftChallengeTime = checkint(self:GetWorldBossData().leftTimes)
	if 0 >= leftChallengeTime then
		uiMgr:ShowInformationTips(__('次数不足!!!'))
		return
	end

	-- 检查阵容
	local hasCard = false
	for i,v in ipairs(self:GetTeamData()) do
		if nil ~= v.id then
			local c_id = checkint(v.id)
			local cardData = gameMgr:GetCardDataById(c_id)
			if nil ~= cardData and 0 ~= checkint(cardData.cardId) then
				hasCard = true
				break
			end
		end
	end

	if not hasCard then
		-- 没带卡
		uiMgr:ShowInformationTips(__('队伍不能为空!!!'))
		return
	end

	local buffId = data.buffId
	if nil == buffId or 0 == checkint(buffId) then
		-- 没带buff
		local layer = require('common.CommonTip').new({
			text = __('没有选择祝福 确定开始?'),
			callback = function (sender)
				self:EnterBattleChecker()
			end
		})
		layer:setPosition(display.center)
		uiMgr:GetCurrentScene():AddDialog(layer)
	else
		-- 带了buff
		self:EnterBattleChecker()
	end
end
--[[
根据buff id 购买buff
@params data table {
	buffId int buff id
}
--]]
function WorldBossMediator:BuyWBBuff(data)
	local buffId = checkint(data.buffId)
	local buffConfig = self:GetWBBuffConfig(buffId)

	if nil == buffConfig then
		uiMgr:ShowInformationTips(__('祝福不存在!!!'))
		return
	end

	-- 检查消耗是否满足
	local costGoodsId = checkint(buffConfig.goodsConsume)
	local costGoodsAmount = checkint(buffConfig.goodsConsumeNum)
	local costGoodsConfig = CommonUtils.GetConfig('goods', 'goods', costGoodsId)

	if 0 < costGoodsAmount then
		if costGoodsAmount > gameMgr:GetAmountByIdForce(costGoodsId) then
			if GAME_MODULE_OPEN.NEW_STORE and checkint(costGoodsId) == DIAMOND_ID then
				app.uiMgr:showDiamonTips()
			else
				uiMgr:ShowInformationTips(string.format(__('%s不足!!!'), tostring(costGoodsConfig.name)))
			end
			return
		end
	end

	-- 请求服务器
	self:SendSignal(POST.WORLD_BOSS_BUY_BUFF.cmdName, {questId = self:GetWorldBossQuestId(), buffId = buffId})
end
--[[
购买buff回调
@params responseData table 服务器返回信息
--]]
function WorldBossMediator:BuyWBBuffCallback(responseData)
	local buffId = checkint(responseData.requestData.buffId)
	local buffConfig = self:GetWBBuffConfig(buffId)

	------------ data ------------
	-- 刷新本地消耗
	local costGoodsId = checkint(buffConfig.goodsConsume)
	local costGoodsAmount = checkint(buffConfig.goodsConsumeNum)
	if 0 < costGoodsAmount then
		CommonUtils.DrawRewards({
			{goodsId = costGoodsId, amount = -1 * costGoodsAmount}
		})
	end

	-- 刷新本地缓存数据
	local newBossData = {
		buffId = buffId
	}
	self:UpdateWorldBossData(newBossData)
	------------ data ------------

	------------ view ------------
	-- 刷新买buff界面
	local battleBuffView = uiMgr:GetCurrentScene():GetDialogByTag(battleBuffViewTag)
	if nil ~= battleBuffView then
		battleBuffView:BuyBuffCallback(buffId)
	end

	uiMgr:ShowInformationTips(__('选择成功!!!'))
	------------ view ------------
end

function WorldBossMediator:EnterBattleChecker()
	if self.presetFixedTeamData_ then
		self:EnterWBBattleByPresetTeam(self.presetFixedTeamData_)
	else
		self:EnterWBBattle()
	end
end

---根据预设编队阵容进入世界boss战斗
---@param responseData table
function WorldBossMediator:EnterWBBattleByPresetTeam(presetFixedTeamData)
	local teamDataStr = self:ConvertTeamData2Str(self:GetTeamData())
	local fixedTeamData = checktable(presetFixedTeamData)

	AppFacade.GetInstance():DispatchObservers("DOT_LOG_EVENT_SEND" , {eventId = "60-01"})
	AppFacade.GetInstance():DispatchObservers("DOT_SET_LOG_EVENT" , {eventId = "60-02"})
	-- 服务器参数
	local serverCommand = BattleNetworkCommandStruct.New(
			POST.WORLD_BOSS_QUESTAT.cmdName,
			{questId = self:GetWorldBossQuestId(), cards = teamDataStr},
			POST.WORLD_BOSS_QUESTAT.sglName,
			POST.WORLD_BOSS_QUESTGRADE.cmdName,
			{questId = self:GetWorldBossQuestId(), teamCustomId = self:GetTeamCustomId()},
			POST.WORLD_BOSS_QUESTGRADE.sglName,
			POST.WORLD_BOSS_BUYLIVE.cmdName,
			nil,
			POST.WORLD_BOSS_BUYLIVE.sglName
	)

	local fromToStruct = BattleMediatorsConnectStruct.New(
			NAME,
			NAME
	)

	local battleConstructor = require('battleEntry.BattleConstructorEx').new()
	------------ 初始化怪物血量参数 这里写死一波一个怪 ------------
	local stageId = self:GetWorldBossQuestId()
	local questBattleType = CommonUtils.GetQuestBattleByQuestId(stageId)

	--- 友方阵容
	local formattedFriendTeamData = battleConstructor:GetFormattedTeamsDataByTeamsCardData({[1] = fixedTeamData})

	------------ 初始化怪物血量参数 这里写死一波一个怪 ------------
	local monsterAttrData = {
		['1'] = {
			[1] = {
				[CardUtils.PROPERTY_TYPE.HP] = {percent = 1, value = checknumber(self:GetWorldBossData().remainHp)}
			}
		}
	}
	------------ 初始化怪物血量参数 这里写死一波一个怪 ------------

	--- 敌方阵容
	local formattedEnemyTeamData = battleConstructor:ExConvertEnemyFormationData(
			stageId, questBattleType, {
				monsterIntensityData = nil, monsterAttrData = monsterAttrData
	})

	local buffId = checkint(self:GetWorldBossData().buffId)
	local buffs = nil
	if nil ~= buffId and 0 ~= checkint(buffId) then
		buffs = {
			{buffId = buffId, level = 1}
		}
	end

	local maxBuyLiveTimes = checkint(self:GetWorldBossData().maxBuyLiveTimes)
	local buyLiveTimes = checkint(self:GetWorldBossData().buyLiveTimes)

	battleConstructor:InitByCommonData(
			stageId, questBattleType, nil,                  --- 关卡相关数据
			formattedFriendTeamData, formattedEnemyTeamData,               --- 友方阵容 和 敌方阵容
			nil, app.gameMgr:GetUserInfo().allSkill,          --- 友方技能
			nil, nil,                       --- 敌方技能
			battleConstructor:GetFormattedGlobalSkillsByBuffs(buffs), nil, ---  buff 相关
			buyLiveTimes, maxBuyLiveTimes, true,
			nil, false,
			serverCommand, fromToStruct
	)

	if not AppFacade.GetInstance():RetrieveMediator('EnterBattleMediator') then
		local enterBattleMediator = require('Game.mediator.EnterBattleMediator').new()
		AppFacade.GetInstance():RegistMediator(enterBattleMediator)
	end

	GuideUtils.DispatchStepEvent()
	AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.Battle_Enter, battleConstructor)

	-- 移除战斗buff界面
	uiMgr:GetCurrentScene():RemoveDialogByTag(battleBuffViewTag)
end

--[[
进入战斗
--]]
function WorldBossMediator:EnterWBBattle()
	local teamDataStr = self:ConvertTeamData2Str(self:GetTeamData())
	local fixedTeamData = {}
	for i = 1, MAX_TEAM_MEMBER_AMOUNT do
		local cardInfo = self:GetTeamData()[i]
		if nil ~= cardInfo and nil ~= cardInfo.id then
			fixedTeamData[i] = checkint(cardInfo.id)
		end
	end
	AppFacade.GetInstance():DispatchObservers("DOT_LOG_EVENT_SEND" , {eventId = "60-01"})
	AppFacade.GetInstance():DispatchObservers("DOT_SET_LOG_EVENT" , {eventId = "60-02"})
	-- 服务器参数
	local serverCommand = BattleNetworkCommandStruct.New(
		POST.WORLD_BOSS_QUESTAT.cmdName,
		{questId = self:GetWorldBossQuestId(), cards = teamDataStr},
		POST.WORLD_BOSS_QUESTAT.sglName,
		POST.WORLD_BOSS_QUESTGRADE.cmdName,
		{questId = self:GetWorldBossQuestId()},
		POST.WORLD_BOSS_QUESTGRADE.sglName,
		POST.WORLD_BOSS_BUYLIVE.cmdName,
		nil,
		POST.WORLD_BOSS_BUYLIVE.sglName
	)

	local fromToStruct = BattleMediatorsConnectStruct.New(
		NAME,
		NAME
	)

	local battleConstructor = require('battleEntry.BattleConstructor').new()

	------------ 初始化怪物血量参数 这里写死一波一个怪 ------------
	local monsterAttrData = {
		['1'] = {
			[1] = {
				[CardUtils.PROPERTY_TYPE.HP] = {percent = 1, value = checknumber(self:GetWorldBossData().remainHp)}
			}
		}
	}
	------------ 初始化怪物血量参数 这里写死一波一个怪 ------------

	local buffId = checkint(self:GetWorldBossData().buffId)
	local buffs = nil
	if nil ~= buffId and 0 ~= checkint(buffId) then
		buffs = {
			{buffId = buffId, level = 1}
		}
	end

	local maxBuyLiveTimes = checkint(self:GetWorldBossData().maxBuyLiveTimes)
	local buyLiveTimes = checkint(self:GetWorldBossData().buyLiveTimes)
	local leftBuyLiveTimes = math.max(0, maxBuyLiveTimes - buyLiveTimes)

	battleConstructor:InitDataByShareBossCustomizeCard(
		self:GetWorldBossQuestId(),
		fixedTeamData,
		monsterAttrData,
		leftBuyLiveTimes,
		maxBuyLiveTimes,
		true,
		{},
		serverCommand,
		fromToStruct,
		buffs
	)

	if not AppFacade.GetInstance():RetrieveMediator('EnterBattleMediator') then
		local enterBattleMediator = require('Game.mediator.EnterBattleMediator').new()
		AppFacade.GetInstance():RegistMediator(enterBattleMediator)
	end

	GuideUtils.DispatchStepEvent()
	AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.Battle_Enter, battleConstructor)

	-- 移除战斗buff界面
	uiMgr:GetCurrentScene():RemoveDialogByTag(battleBuffViewTag)
end
---------------------------------------------------
-- view control end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
获取当前世界boss关卡id
@return _ 关卡id
--]]
function WorldBossMediator:GetWorldBossQuestId()
	return self.questId
end
--[[
获取世界boss数据
@return table 数据
--]]
function WorldBossMediator:GetWorldBossData()
	return self.bossData
end
function WorldBossMediator:UpdateWorldBossData(newData)
	for k,v in pairs(newData) do
		self.bossData[k] = v
	end
end
--[[
获取编队数据
--]]
function WorldBossMediator:GetTeamData()
	return self.teamData_
end
function WorldBossMediator:SetTeamData(data)
	self.teamData_ = data
end
--[[
本地保存的队伍信息
--]]
function WorldBossMediator:GetLocalWBTeamMembers()
	local str = cc.UserDefault:getInstance():getStringForKey(self:GetLocalTeamDataKey(), '')
	local table = json.decode(str)
	return table
end
function WorldBossMediator:SetLocalWBTeamMembers(data)
	local str = json.encode(data)
	cc.UserDefault:getInstance():setStringForKey(self:GetLocalTeamDataKey(), str)
	cc.UserDefault:getInstance():flush()
end
--[[
获取保存阵容的本地key
--]]
function WorldBossMediator:GetLocalTeamDataKey()
	return tostring(gameMgr:GetUserInfo().playerId) .. LOCAL_WB_TEAM_MEMBERS_KEY
end
--[[
获取转换后传给服务器的阵容数据
@params teamData table
@return str string 阵容数据
--]]
function WorldBossMediator:ConvertTeamData2Str(teamData)
	local str = ''
	for i = 1, MAX_TEAM_MEMBER_AMOUNT do
		local cardInfo = teamData[i]
		if nil ~= cardInfo and nil ~= cardInfo.id and 0 ~= checkint(cardInfo.id) then
			str = str .. cardInfo.id
		end
		str = str .. ','
	end
	return str
end
--[[
获取buff配置
@params buffId int buffid
--]]
function WorldBossMediator:GetWBBuffConfig(buffId)
	return CommonUtils.GetConfig('common', 'payBuff', buffId)
end

--[[
设置预设编队Id
--]]
function WorldBossMediator:GetTeamCustomId()
	return checkint(self.teamCustomId_)
end
function WorldBossMediator:SetTeamCustomId(teamCustomId)
	self.teamCustomId_ = checkint(teamCustomId)
end
--[[
本地保存的预设编队id
--]]
function WorldBossMediator:GetLocalTeamCustomId()
	local teamCustomId = cc.UserDefault:getInstance():getIntegerForKey(self:GetLocalTeamCustomIdKey(), 0)
	return teamCustomId
end
function WorldBossMediator:SetLocalTeamCustomId()
	local teamCustomId = self:GetTeamCustomId()
	cc.UserDefault:getInstance():setIntegerForKey(self:GetLocalTeamCustomIdKey(), teamCustomId)
	cc.UserDefault:getInstance():flush()
end
--[[
获取保存阵容的本地key
--]]
function WorldBossMediator:GetLocalTeamCustomIdKey()
	return tostring(gameMgr:GetUserInfo().playerId) .. LOCAL_WB_TEAM_CUSTOM_ID_KEY
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return WorldBossMediator
