--[[
工会狩猎管理器
@params {
	godBeastId int 神兽id
}
--]]
local Mediator = mvc.Mediator
local UnionHuntMediator = class("UnionHuntMediator", Mediator)
local NAME = "UnionHuntMediator"

------------ import ------------
local unionMgr = AppFacade.GetInstance():GetManager("UnionManager")
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local timerMgr = AppFacade.GetInstance():GetManager("TimerManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")

local UnionConfigParser  = require('Game.Datas.Parser.UnionConfigParser')
------------ import ------------

------------ define ------------
local UNION_BEAST_REFRESH_TIMER_NAME = 'UNION_BEAST_REFRESH_TIMER_NAME'
local DefaultHuntCountdown = 7 * 24 * 3600
------------ define ------------

--[[
constructor
--]]
function UnionHuntMediator:ctor(params, viewComponent)
	Mediator.ctor(self, NAME, viewComponent)

	self.enterPost = false
	self.isInRefresh = false

	self.initBeastId = nil

	if params then
		self.initBeastId = params.godBeastId
	end
end
---------------------------------------------------
-- mediator extend begin --
---------------------------------------------------
function UnionHuntMediator:InterestSignals()
	local signals = {
		------------ server ------------
		POST.UNION_HUNTING.sglName,
		POST.UNION_HUNTING_ACCELERATE.sglName,
		------------ local ------------
		'CLOSE_UNION_HUNT',
		'SHOW_UNION_BEAST_DAMAGE_RANKING',
		'HUNT_UNION_BEAST',
		'ENTER_UNION_BEAST_BATTLE',
		'AWAKE_UNION_BEAST',
		'SHOW_UNION_BEAST_BABY_DETAIL'
	}

	return signals
end
function UnionHuntMediator:ProcessSignal( signal )
	local name = signal:GetName()
	local responseData = signal:GetBody()

	if POST.UNION_HUNTING.sglName == name then

		-- 刷新全部
		self:RefreshAllCallback(responseData)

	elseif POST.UNION_HUNTING_ACCELERATE.sglName == name then

		-- 狩猎加速
		self:AwakeUnionBeastCallback(responseData)

	elseif 'CLOSE_UNION_HUNT' == name then

		-- 关闭自己
		self:CloseSelf()

	elseif 'SHOW_UNION_BEAST_DAMAGE_RANKING' == name then

		-- 显示神兽伤害排名
		self:ShowBeastDamageRanking(responseData)

	elseif 'HUNT_UNION_BEAST' == name then

		-- 进入神兽狩猎战斗
		self:HuntUnionBeast(responseData)

	elseif 'ENTER_UNION_BEAST_BATTLE' == name then

		-- 进入神兽狩猎战斗
		self:EnterUnionHuntBattle(responseData)

	elseif 'AWAKE_UNION_BEAST' == name then

		-- 唤醒沉睡的神兽
		self:AwakeUnionBeast(responseData)

	elseif 'SHOW_UNION_BEAST_BABY_DETAIL' == name then

		-- 显示神兽幼崽详情
		self:ShowUnionBeastBabyDetail(responseData)

	end
end
function UnionHuntMediator:Initial( key )
	self.super.Initial(self, key)
end
function UnionHuntMediator:OnRegist()
	self.selectedBeastId = nil

	-- 初始化信号
	regPost(POST.UNION_HUNTING, true)
	regPost(POST.UNION_HUNTING_ACCELERATE)

	-- 请求一次home
	self:SendSignal(POST.UNION_HUNTING.cmdName)
end
function UnionHuntMediator:OnUnRegist()
	-- 注销信号
	unregPost(POST.UNION_HUNTING)
	unregPost(POST.UNION_HUNTING_ACCELERATE)

	-- 移除计时器
	timerMgr:StopTimer(UNION_BEAST_REFRESH_TIMER_NAME)
	timerMgr:RemoveTimer(UNION_BEAST_REFRESH_TIMER_NAME)

	-- 销毁界面
	if self:GetViewComponent() and not tolua.isnull(self:GetViewComponent()) then
		uiMgr:GetCurrentScene():RemoveDialog(self:GetViewComponent())
	end
end
---------------------------------------------------
-- mediator extend end --
---------------------------------------------------

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
第一次进入
@params responseData table server response data
--]]
function UnionHuntMediator:EnterHome(responseData)
	self.enterPost = true

	-- 如果存在errcode 移除自己
	local errcode = checkint(responseData.errcode)
	if 0 ~= errcode then
		-- 移除自己
		AppFacade.GetInstance():UnRegsitMediator(NAME)
		return
	end

	-- responseData = {
	-- 	godBeast = {
	-- 		['1'] = {
	-- 			id = '1',
	-- 			level = 2,
	-- 			captured = 1,
	-- 			remainHp = 0,
	-- 			leftHuntTimes = 1,
	-- 			leftBuyLiveNum = 1,
	-- 			maxBuyLiveNum = 1,
	-- 			leftSeconds = 551139
	-- 		}
	-- 	}
	-- }

	self:SetBeastsData(responseData.godBeast)

	-- 初始化界面
	self:InitScene()
	-- 初始化倒计时
	self:InitCountdown()
end
--[[
初始化界面
--]]
function UnionHuntMediator:InitScene()
	local scene = require('Game.views.union.UnionHuntScene').new()
	display.commonUIParams(scene, {ap = cc.p(0.5, 0.5), po = cc.p(display.cx, display.cy)})
	uiMgr:GetCurrentScene():AddDialog(scene)

	self:SetViewComponent(scene)

	local index = self:GetBeastIndexByBeastId(self.initBeastId)
	-- print('here check fuck index<<<<<<<<<<<<<<<<<', index, self.initBeastId)
	scene:RefreshUI(self:GetSortedBeastsConfig(), self:GetBeastsData(), unionMgr:getUnionData().level, index)
end
--[[
初始化倒计时
--]]
function UnionHuntMediator:InitCountdown()
	timerMgr:AddTimer({
		name = UNION_BEAST_REFRESH_TIMER_NAME,
		countdown = DefaultHuntCountdown,
		callback = handler(self, self.RefreshCountdownCallback)
	})
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- control begin --
---------------------------------------------------
--[[
关闭自己
--]]
function UnionHuntMediator:CloseSelf()
	AppFacade.GetInstance():UnRegsitMediator(NAME)
end
--[[
显示神兽伤害排名
@params data table {
	beastId int 神兽id
}
--]]
function UnionHuntMediator:ShowBeastDamageRanking(data)
	local beastId = checkint(data.beastId)
	-- uiMgr:ShowInformationTips('此处显示神兽id : ' .. beastId .. ' 伤害排行榜')
	local mediator = require("Game.mediator.UnionRankMediator").new({unionRankTypes = UnionRankTypes.GODBEAST_DAMAGE})
    self:GetFacade():RegistMediator(mediator)
    self:GetFacade():UnRegsitMediator(mediator)
end
--[[
进入神兽狩猎战
@params data table {
	beastId int 神兽id
}
--]]
function UnionHuntMediator:HuntUnionBeast(data)
	local beastId = checkint(data.beastId)
	self.selectedBeastId = beastId
	local beastData = self:GetBeastDataById(beastId)
	local stageId = CommonUtils.GetBeastQuestIdByIdAndLevel(beastId, checkint(beastData.level))

	------------ 查错 ------------
	if 0 >= checkint(beastData.leftHuntTimes) then
		-- 次数不足
		uiMgr:ShowInformationTips(__('挑战次数不足!!!'))
		return
	end
	------------ 查错 ------------

	-- 显示编队界面
	local battleReadyData = BattleReadyConstructorStruct.New(
		3,
		gameMgr:GetUserInfo().localCurrentBattleTeamId,
		gameMgr:GetUserInfo().localCurrentEquipedMagicFoodId,
		stageId,
		CommonUtils.GetQuestBattleByQuestId(stageId),
		nil,
		POST.UNION_HUNTING_QUEST_AT.cmdName,
		{godBeastId = beastId},
		POST.UNION_HUNTING_QUEST_AT.sglName,
		POST.UNION_HUNTING_QUEST_GRADE.cmdName,
		{godBeastId = beastId},
		POST.UNION_HUNTING_QUEST_GRADE.sglName,
		NAME,
		NAME
	)

	local layer = require('Game.views.BattleReadyView').new(battleReadyData)
	layer:setPosition(cc.p(display.cx, display.cy))
	uiMgr:GetCurrentScene():AddDialog(layer)

end
--[[
准备进入神兽狩猎战
@params data table
--]]
function UnionHuntMediator:EnterUnionHuntBattle(data)
	local beastId = self.selectedBeastId
	local beastData = self:GetBeastDataById(beastId)
	local stageId = CommonUtils.GetBeastQuestIdByIdAndLevel(beastId, checkint(beastData.level))
	local teamIdx = checkint(data.teamIdx)

	dump(data)

	-- 拼装一次卡牌数据
	local localTeamData = gameMgr:getTeamCardsInfo(teamIdx)
	local cardsStr = ''
	for i,v in ipairs(localTeamData) do
		if nil ~= v.id and 0 ~= checkint(v.id) then
			local cardData = gameMgr:GetCardDataById(checkint(v.id))
			if nil ~= cardData and 0 ~= checkint(cardData.cardId) then
				cardsStr = cardsStr .. tostring(v.id)
			end
		end
		cardsStr = cardsStr .. ','
	end

	-- 拼装一次主角技数据
	local skill = {active = {}}
	local playerSkillsStr = self:ConvertPlayerSkills2Str(skill)
	AppFacade.GetInstance():DispatchObservers("DOT_LOG_EVENT_SEND" , {eventId = "53-01"})
	AppFacade.GetInstance():DispatchObservers("DOT_SET_LOG_EVENT" , {eventId = "53-02"})
	local serverCommand = BattleNetworkCommandStruct.New(
		POST.UNION_HUNTING_QUEST_AT.cmdName,
		{godBeastId = beastId, cards = cardsStr, skill = playerSkillsStr},
		POST.UNION_HUNTING_QUEST_AT.sglName,
		POST.UNION_HUNTING_QUEST_GRADE.cmdName,
		{questId = stageId, godBeastId = beastId},
		POST.UNION_HUNTING_QUEST_GRADE.sglName,
		POST.UNION_HUNTING_BUY_LIVE.cmdName,
		nil,
		POST.UNION_HUNTING_BUY_LIVE.sglName
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
				[CardUtils.PROPERTY_TYPE.HP] = {percent = 1, value = checknumber(beastData.remainHp)}
			}
		}
	}
	------------ 初始化怪物血量参数 这里写死一波一个怪 ------------

	battleConstructor:InitDataByShareBoss(
		stageId,
		teamIdx,
		monsterAttrData,
		checkint(beastData.leftBuyLiveNum),
		checkint(beastData.maxBuyLiveNum),
		checkint(beastData.leftBuyLiveNum) > 0,
		{},
		nil,
		serverCommand,
		fromToStruct
	)
	battleConstructor:SetUnionBeastId(beastId)

	if not AppFacade.GetInstance():RetrieveMediator('EnterBattleMediator') then
		local enterBattleMediator = require('Game.mediator.EnterBattleMediator').new()
		AppFacade.GetInstance():RegistMediator(enterBattleMediator)
	end

	GuideUtils.DispatchStepEvent()
	AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.Battle_Enter, battleConstructor)
end
--[[
倒计时回调
--]]
function UnionHuntMediator:RefreshCountdownCallback(countdown)
	if self.isInRefresh then
		return
	end

	------------ data ------------
	-- 刷新一次所有的本地倒计时
	for k,v in pairs(self:GetBeastsData()) do
		-- 如果是已捕获的神兽 并且倒计时为-1 不做处理
		if not (1 == checkint(v.captured) and -1 == checkint(v.leftSeconds)) then
			v.leftSeconds = math.max(0, checkint(v.leftSeconds) - 1)
			if 0 >= v.leftSeconds then
				-- 有倒计时到期 刷新一次all
				self:RefreshAll()
				break
			end
		end
	end
	self:GetViewComponent():SetBeastsData(self:GetBeastsData())
	------------ data ------------

	------------ view ------------
	self:GetViewComponent():RefreshCenterCountdown()
	------------ view ------------
end
--[[
刷新所有界面
--]]
function UnionHuntMediator:RefreshAll()
	uiMgr:ShowInformationTips(__('开始刷新!!!'))
	self.isInRefresh = true
	self:SendSignal(POST.UNION_HUNTING.cmdName)
end
--[[
刷新所有界面回调
@params responseData table server response data
--]]
function UnionHuntMediator:RefreshAllCallback(responseData)
	if not self.enterPost or nil == self:GetViewComponent() then
		self:EnterHome(responseData)
		return
	end

	-- TODO -- 如果存在errcode 移除自己
	local errcode = checkint(responseData.errcode)
	if 0 ~= errcode then
		-- 移除自己
		AppFacade.GetInstance():UnRegsitMediator(NAME)
		return
	end

	------------ data ------------
	self:SetBeastsData(responseData.godBeast)
	timerMgr:RetriveTimer(UNION_BEAST_REFRESH_TIMER_NAME).countdown = DefaultHuntCountdown
	timerMgr:ResumeTimer(UNION_BEAST_REFRESH_TIMER_NAME)
	------------ data ------------

	------------ view ------------
	uiMgr:ShowInformationTips(__('已刷新!!!'))
	-- 刷新所有界面
	self:GetViewComponent():AutoRefreshUI(self:GetSortedBeastsConfig(), self:GetBeastsData(), unionMgr:getUnionData().level)
	------------ view ------------

	self.isInRefresh = false
end
--[[
唤醒神兽
@params data table {
	beastId int 神兽id
}
--]]
function UnionHuntMediator:AwakeUnionBeast(data)
	local beastId = checkint(data.beastId)
	local beastData = self:GetBeastDataById(beastId)

	if nil == beastData then
		uiMgr:ShowInformationTips(__('神兽信息出错!!!'))
		return
	end

	if 1 ~= checkint(beastData.captured) then
		uiMgr:ShowInformationTips(__('未捕获神兽!!!'))
		return
	end

	if 0 >= checkint(beastData.leftSeconds) then
		uiMgr:ShowInformationTips(__('神兽已刷新!!!'))
		return
	end

	local costConfig = {
		goodsId = DIAMOND_ID,
		amount = math.ceil(checkint(beastData.leftSeconds) / 60)
	}
	local goodsConfig = CommonUtils.GetConfig('goods', 'goods', costConfig.goodsId) or {}
	if costConfig.amount > gameMgr:GetAmountByIdForce(costConfig.goodsId) then
		if GAME_MODULE_OPEN.NEW_STORE and checkint(costConfig.goodsId) == DIAMOND_ID then
			app.uiMgr:showDiamonTips()
		else
			uiMgr:ShowInformationTips(string.format(__('%s不足!!!'), tostring(goodsConfig.name)))
		end
		return
	end

	local textRich = {
		{text = __('确定要唤醒远古堕神吗')},
	}
	local descrRich = {
		{text = __('唤醒后血量会被重置')},
	}
	local layer = require('common.CommonTip').new({
		textRich = textRich,
		descrRich = descrRich,
		defaultRichPattern = true,
		costInfo = {goodsId = costConfig.goodsId, num = costConfig.amount},
		callback = function (sender)
			-- 一切就绪 请求服务器
			self:SendSignal(POST.UNION_HUNTING_ACCELERATE.cmdName, {godBeastId = beastId})
		end
	})
	layer:setPosition(display.center)
    uiMgr:GetCurrentScene():AddDialog(layer)
end
--[[
唤醒神兽回调
@params responseData table server response data
--]]
function UnionHuntMediator:AwakeUnionBeastCallback(responseData)
	------------ data ------------
	-- 刷新一次幻晶石
	local diamond = checkint(responseData.diamond)
	local deltaDiamond = diamond - gameMgr:GetAmountByIdForce(DIAMOND_ID)
	local t = {
		{goodsId = DIAMOND_ID, amount = deltaDiamond}
	}
	CommonUtils.DrawRewards(t)

	local beastId = checkint(responseData.requestData.godBeastId)
	local beastData = self:GetBeastsData(beastId)

	local newBeastData = {
		level = checkint(responseData.level),
		remainHp = checkint(responseData.remainHp),
		leftSeconds = checkint(responseData.leftSeconds)
	}
	self:UpdateBeastData(beastId, newBeastData)
	------------ data ------------

	------------ view ------------
	uiMgr:ShowInformationTips(__('唤醒成功!!!'))
	self:GetViewComponent().beastsData[tostring(beastId)] = self:GetBeastDataById(beastId)
	local index = self:GetViewComponent().selectedBeastIndex
	self:GetViewComponent().selectedBeastIndex = nil
	self:GetViewComponent():RefreshCenterContentByIndex(index)
	------------ view ------------
end
--[[
显示神兽幼崽详情
@params data {
	beastId int 神兽id
}
--]]
function UnionHuntMediator:ShowUnionBeastBabyDetail(data)
	local beastId = checkint(data.beastId)
	local beastBabyId = cardMgr.GetBeastBabyIdByBeastId(beastId)

	local layer = require('common.MonsterIntroductionView').new({
		monsterId = beastBabyId
	})
	display.commonUIParams(layer, {ap = cc.p(0.5, 0.5), po = cc.p(display.cx, display.cy)})
	uiMgr:GetCurrentScene():AddDialog(layer)
end
---------------------------------------------------
-- control end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
神兽信息
--]]
function UnionHuntMediator:GetBeastsData()
	return self.beastsData
end
function UnionHuntMediator:SetBeastsData(beastsData)
	self.beastsData = beastsData
end
--[[
根据神兽id获取神兽对应的序号
@params beastId int 神兽id
@return index int 序号
--]]
function UnionHuntMediator:GetBeastIndexByBeastId(beastId)
	if nil == beastId then return nil end
	local index = nil
	for i,v in ipairs(self:GetSortedBeastsConfig()) do
		if checkint(beastId) == checkint(v.id) then
			index = i
			break
		end
	end
	return index
end
--[[
更新单个神兽的信息
@params beastId int 神兽id
@params data table 神兽信息
--]]
function UnionHuntMediator:UpdateBeastData(beastId, data)
	if nil ~= self:GetBeastDataById(beastId) then
		for k,v in pairs(data) do
			if nil ~= self.beastsData[tostring(beastId)][k] then
				self.beastsData[tostring(beastId)][k] = v
			end
		end
	end
end
function UnionHuntMediator:GetSortedBeastsConfig()
	if nil == self.allBeastsConfig then
		-- 获取配置
		local beastsConfig = CommonUtils.GetConfigAllMess(UnionConfigParser.TYPE.GODBEAST, 'union')
		local beastsConfig_ = {}

		for k,v in pairs(beastsConfig) do
			table.insert(beastsConfig_, v)
		end

		table.sort(beastsConfig_, function (a, b)
			if checkint(a.openUnionLevel) == checkint(b.openUnionLevel) then
				return checkint(a.id) < checkint(b.id)
			else
				return checkint(a.openUnionLevel) < checkint(b.openUnionLevel)
			end
		end)

		self.allBeastsConfig = beastsConfig_
	end
	return self.allBeastsConfig
end
--[[
根据神兽id获取神兽信息
@params beastId int 神兽id
@return _ table 神兽信息
--]]
function UnionHuntMediator:GetBeastDataById(beastId)
	return self:GetBeastsData()[tostring(beastId)]
end
--[[
获取主角技转换后的字符串
@params playerSkills table {
	active = {} list
	passive = {} list
}
@return str string 转换后的字符串
--]]
function UnionHuntMediator:ConvertPlayerSkills2Str(playerSkills)
	local str = ''
	if nil ~= playerSkills and nil ~= playerSkills.active then
		for i,v in ipairs(playerSkills.active) do
			str = str .. tostring(v) .. ','
		end
	end
	return str
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return UnionHuntMediator
