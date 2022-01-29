--[[
luna塔home管理器
--]]
local Mediator = mvc.Mediator
local LunaTowerHomeMediator = class("LunaTowerHomeMediator", Mediator)
local NAME = "lunaTower.LunaTowerHomeMediator"

------------ import ------------
local BossDetailMediator = require('Game.mediator.BossDetailMediator')
------------ import ------------

------------ define ------------
local LT_ENTER_BATTLE = 'LT_ENTER_BATTLE'
local LT_CHANGE_TEAM_VIEW_TAG = 4099
------------ define ------------

--[[
constructor
--]]
function LunaTowerHomeMediator:ctor(params, viewComponent)
	Mediator.ctor(self, NAME, viewComponent)

	self:InitData(params)
end

---------------------------------------------------
-- mediator extend begin --
---------------------------------------------------
function LunaTowerHomeMediator:InterestSignals()
	local signals = {
		------------ server ------------
		POST.LUNA_TOWER_RESURRECTION.sglName,
		------------ local ------------
		'LT_SHOW_EDIT_TEAM_MEMBER',
		'COMMON_RESET_ALL_CARDS_STATUS',
		LT_ENTER_BATTLE,
		'SHOW_LUNA_TOWER_MONSTER_DETAIL',
		'EXIT_LUNA_TOWER_HOME',
		'CLOSE_CHANGE_TEAM_SCENE'
	}

	return signals
end

function LunaTowerHomeMediator:ProcessSignal(signal)
	local name = signal:GetName()
	local responseData = signal:GetBody()

	if POST.LUNA_TOWER_RESURRECTION.sglName == name then

		-- 重置所有卡牌血量回调
		self:ResetCardsStatusCallback(responseData)

	elseif 'LT_SHOW_EDIT_TEAM_MEMBER' == name then

		-- 编辑阵容
		self:ShowEditTeamMemberView(responseData)

	elseif 'COMMON_RESET_ALL_CARDS_STATUS' == name then

		-- 重置所有卡牌血量
		self:ResetCardsStatus(responseData)

	elseif LT_ENTER_BATTLE == name then

		-- 进入战斗
		self:LunaTowerEnterBattle(responseData)

	elseif 'SHOW_LUNA_TOWER_MONSTER_DETAIL' == name then

		-- 显示怪物详情
		self:ShowMonsterDetailView(responseData)

	elseif 'EXIT_LUNA_TOWER_HOME' == name then

		-- 退出luna塔
		self:ExitLunaTowerHome()

	elseif 'CLOSE_CHANGE_TEAM_SCENE' == name then

		-- 退出编队界面
		self:ExitEditTeam()

	end
end

function LunaTowerHomeMediator:Initial(key)
	self.super.Initial(self, key)
end

function LunaTowerHomeMediator:OnRegist()
	-- 初始化界面
	self:InitScene()

	-- 隐藏顶部条
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightHide")
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "allhide")

	-- 注册信号
	regPost(POST.LUNA_TOWER_RESURRECTION)
end

function LunaTowerHomeMediator:OnUnRegist()
	-- 恢复顶部条
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightShow")
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "hide")
	
	-- 注销信号
	unregPost(POST.LUNA_TOWER_RESURRECTION)

	-- 清理spine缓存
	SpineCache(SpineCacheName.TOWER):clearCache()
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
function LunaTowerHomeMediator:InitData(responseData)
	self.lunaTowerData = responseData
end
--[[
初始化场景
--]]
function LunaTowerHomeMediator:InitScene()
	-- 隐藏顶部状态
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "show")

	-- 创建场景
	local scene = app.uiMgr:SwitchToTargetScene("Game.views.lunaTower.LunaTowerHomeScene")
	self:SetViewComponent(scene)

	-- 刷新场景
	local openedFloors = self:GetOpenedFloors()
	local maxFloor = self:GetMaxFloor()
	local currentFloor = self:GetCurrentPassedFloorId()
	local exData = self:GetEXData()
	local currentFloorHp = self:GetCurrentFloorHp()
	local lastTeamData = self:GetLastTeamData()

	scene:RefreshScene(openedFloors, maxFloor, currentFloor, exData, currentFloorHp, teamData, app.gameMgr:GetUserInfo().level)
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- view control begin --
---------------------------------------------------
--[[
显示队伍编辑 准备进入战斗
@params data table {
	floorId int 当前的层id
	questId int 当前层对应的关卡id
	isEX bool 是否是ex关卡
}
--]]
function LunaTowerHomeMediator:ShowEditTeamMemberView(data)
	local floorId = checkint(data.floorId)
	local questId = checkint(data.questId)
	local isEX = data.isEX
	local banList = CommonUtils.GetConfig('lunaTower', 'ban', questId)

	local layer = require('Game.views.pvc.PVCChangeTeamScene').new({
		teamDatas = self:GetTeamData(),
		maxTeamAmount = isEX and MAX_TAG_MATCH_TEAM_AMOUNT or 1,
		title = __('编辑队伍'),
		teamTowards = 1,
		avatarTowards = 1,
		enterBattleSignalName = LT_ENTER_BATTLE,
		battleType = 1,
		banList = {
			career = banList.career,
			quality = banList.quality,
			card = banList.card
		},
		showCardStatus = {
			hpFieldName = 'lunaTowerHp',
			energyFieldName = 'lunaTowerEnergy'
		},
		costGoodsInfo = self:GetResetCostGoodsInfo(),
		battleButtonSkinType = (true == isEX and BattleButtonSkinType.EX or BattleButtonSkinType.BASE),
		isDisableHomeTopSignal = true
	})
	layer:setAnchorPoint(cc.p(0.5, 0.5))
	layer:setPosition(display.center)
	layer:setTag(LT_CHANGE_TEAM_VIEW_TAG)
	app.uiMgr:GetCurrentScene():AddDialog(layer)

	-- 设置滑动列表不可触摸
	self:GetViewComponent():SetCanTouch(false)

end
--[[
退出编队界面
--]]
function LunaTowerHomeMediator:ExitEditTeam()
	-- 恢复列表触摸
	self:GetViewComponent():SetCanTouch(true)
end
--[[
刷新卡牌状态
@params data map {
	resetHp bool 是否刷新血量
	resetEnergy bool 是否刷新能量
}
--]]
function LunaTowerHomeMediator:ResetCardsStatus(data)
	local costGoodsInfo = self:GetResetCostGoodsInfo()
	-- 检查是否满足消耗
	local costGoodsId = checkint(costGoodsInfo.goodsId)
	local costGoodsAmount = checkint(costGoodsInfo.num)
	local costGoodsConfig = CommonUtils.GetConfig('goods', 'goods', costGoodsId)

	if costGoodsAmount > app.gameMgr:GetAmountByIdForce(costGoodsId) then
		if GAME_MODULE_OPEN.NEW_STORE and checkint(costGoodsId) == DIAMOND_ID then
			app.uiMgr:showDiamonTips()
		else
			app.uiMgr:ShowInformationTips(string.format(__('%s不足!!!'), tostring(costGoodsConfig.name)))
		end
		return
	else
		-- 道具够 弹确认
		local layer = require('common.CommonTip').new({
			text = __('确定刷新所有卡牌血量?'),
			callback = function (sender)
				-- 请求服务器
				self:SendSignal(POST.LUNA_TOWER_RESURRECTION.cmdName)
			end
		})
		layer:setPosition(display.center)
		app.uiMgr:GetCurrentScene():AddDialog(layer)
	end
end
--[[
刷新卡牌血量状态回调
@params responseData map 服务器返回数据
--]]
function LunaTowerHomeMediator:ResetCardsStatusCallback(responseData)
	-- 扣除消耗
	local costGoodsInfo = self:GetResetCostGoodsInfo()
	local costGoodsId = checkint(costGoodsInfo.goodsConsume)
	local costGoodsAmount = checkint(costGoodsInfo.goodsConsumeNum)

	CommonUtils.DrawRewards({
		{goodsId = costGoodsId, amount = -1 * costGoodsAmount}
	})

	-- 刷新卡牌血量
	app.gameMgr:ResetCardStatus('lunaTowerHp', 1)

	-- 刷新界面
	AppFacade.GetInstance():DispatchObservers('LT_REFRESH_CARD_STATUS')
end
--[[
进入战斗回调
@params data map {
	teamData list 队伍信息
}
--]]
function LunaTowerHomeMediator:LunaTowerEnterBattle(data)
	-- 获取当前关卡信息
	local floorId, questId, enemyId = self:GetViewComponent():GetCurrentStageInfo()

	self:LunaTowerEnterBattleByStageInfo(floorId, questId, enemyId, data.teamData)
end
--[[
根据当前选定的关卡进入战斗
@params floorId int 层id
@params questId int 关卡id
@params enemyId int 敌军配置id
@params teamData list 队伍信息
--]]
function LunaTowerHomeMediator:LunaTowerEnterBattleByStageInfo(floorId, questId, enemyId, teamData)
	-- 创建战斗构造器
	local battleConstructor = require('battleEntry.BattleConstructor').new()

	-- 等级信息
	local cardLevel = nil
	local skillLevel = nil
	local levelInfo = CommonUtils.GetConfig('battle', 'cardLevel', app.gameMgr:GetUserInfo().level)
	if nil ~= levelInfo then
		cardLevel = checkint(levelInfo.level)
		skillLevel = checkint(levelInfo.skillLevel)
	end

	-- 怪物配置信息
	local enemyOneTeamData = CardUtils.GetCustomizeEnemyOneTeamById(
		enemyId,
		cardLevel, skillLevel
	)

	-- 怪物血量信息
	local monsterAttrData = {
		['1'] = nil
	}
	local hpData = self:GetHpDataByFloorId(floorId)
	local attrData = {}
	if nil ~= hpData then
		for i = 1, table.nums(hpData) do
			attrData[i] = {
				[CardUtils.PROPERTY_TYPE.HP] = {percent = checknumber(hpData[tostring(i)] or 1), value = -1}
			}
		end
	end
	monsterAttrData['1'] = attrData

	-- 格式化后的敌方阵容信息
	local enemyConfig = {
		['1'] = {
			npc = enemyOneTeamData
		}
	}
	local formattedEnemyTeamData = battleConstructor:GetFEnemyTeamDataByIntensityData(
		enemyConfig, nil, monsterAttrData
	)
	
	-- 格式化后的友军阵容
	local maxTeamAmount = self:IsEXQuest(floorId, questId) and 3 or 1
	local formattedFriendTeamData = battleConstructor:ConvertSelectCards2FormattedTeamData(
		teamData, maxTeamAmount, {
			[CardUtils.PROPERTY_TYPE.HP] = {fieldName = 'lunaTowerHp'},
			[CardUtils.PROPERTY_TYPE.ENERGY] = {fieldName = 'lunaTowerEnergy'},
		}
	)

	-- 服务器参数
	local cards = {}
	for teamIndex = 1, table.nums(teamData) do

		if nil ~= teamData[teamIndex] then

			cards[tostring(teamIndex)] = ''
			
			for i = 1, MAX_TEAM_MEMBER_AMOUNT do
				
				if nil ~= teamData[teamIndex][i] and nil ~= teamData[teamIndex][i].id then
					cards[tostring(teamIndex)] = cards[tostring(teamIndex)] .. tostring(teamData[teamIndex][i].id)
				else
					cards[tostring(teamIndex)] = cards[tostring(teamIndex)] .. ''
				end

				if i < MAX_TEAM_MEMBER_AMOUNT then
					cards[tostring(teamIndex)] = cards[tostring(teamIndex)] .. ','
				end

			end

		end

	end

	local serverCommand = BattleNetworkCommandStruct.New(
		POST.LUNA_TOWER_QUEST_AT.cmdName,
		{floor = floorId, cards = json.encode(cards)},
		POST.LUNA_TOWER_QUEST_AT.sglName,
		POST.LUNA_TOWER_QUEST_GRADE.cmdName,
		{floor = floorId},
		POST.LUNA_TOWER_QUEST_GRADE.sglName,
		nil,
		nil,
		nil
	)

	-- 跳转信息
	local fromToStruct = BattleMediatorsConnectStruct.New(
		NAME,
		NAME
	)

	battleConstructor:InitByCommonData(
		questId, QuestBattleType.LUNA_TOWER, ConfigBattleResultType.BASE,
		formattedFriendTeamData, formattedEnemyTeamData,
		nil, app.gameMgr:GetUserInfo().allSkill, nil, nil,
		nil, nil,
		nil, nil, nil,
		nil, false,
		serverCommand, fromToStruct
	)
	battleConstructor:OpenBattle()

	-- 关闭阵容界面
	AppFacade.GetInstance():DispatchObservers('CLOSE_CHANGE_TEAM_SCENE')
end
--[[
显示怪物详情
@params data {
	floorId int 层id
	questId int 关卡id
	monsterInfo map 怪物详情
}
--]]
function LunaTowerHomeMediator:ShowMonsterDetailView(data)
	local cardId = nil
	if nil ~= data.monsterInfo then
		cardId = data.monsterInfo.cardId
	end

	if nil == cardId or 0 == checkint(cardId) then
		app.uiMgr:ShowInformationTips(string.format(__('未找到%d层该怪物的信息!!!'), data.floorId))
		return
	end

	if CardUtils.IsMonsterCard(cardId) then
		-- 如果是怪物单位 显示boss详情
		local questConfig = CommonUtils.GetQuestConf(data.questId)
		if nil ~= questConfig and 0 < #checktable(questConfig.monsterInfo) then
			AppFacade.GetInstance():RegistMediator(BossDetailMediator.new({questId = data.questId}))
		else
			app.uiMgr:ShowInformationTips(string.format(__('未找到%d层该boss的信息!!!'), data.floorId))
			return
		end
	else
		-- 如果是卡牌单位 显示卡牌带神器的详情
		local cardDetailData = {
			cardData = {
				cardId = cardId,
				level = data.monsterInfo.level,
				breakLevel = data.monsterInfo.breakLevel,
				favorLevel = data.monsterInfo.favorLevel,
				skinId = data.monsterInfo.defaultSkinId,
				artifactTalent = data.monsterInfo.artifactTalent,
				isArtifactUnlock = 1
			},
			petsData = data.monsterInfo.pets,
			viewType = 1
		}
		local playerCardDetailView = require('Game.views.raid.PlayerCardDetailView').new(cardDetailData)
		playerCardDetailView:setTag(2222)
		display.commonUIParams(playerCardDetailView, {ap = cc.p(0.5, 0.5), po = cc.p(
			display.cx, display.cy
		)})
		app.uiMgr:GetCurrentScene():AddDialog(playerCardDetailView)
	end
end
--[[
退出竞技场
--]]
function LunaTowerHomeMediator:ExitLunaTowerHome()
	app.router:Dispatch({name = NAME}, {name = self:GetBackToMediator()})
end
---------------------------------------------------
-- view control end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
获取开放的最高层数
@return _ int 最高层数
--]]
function LunaTowerHomeMediator:GetMaxFloor()
	return checkint(self.lunaTowerData.maxFloor)
end
--[[
获取当前通过的最高层数
@return _ int 通过的最高层
--]]
function LunaTowerHomeMediator:GetCurrentPassedFloorId()
	return checkint(self.lunaTowerData.currentFloor or 0)
end
--[[
获取ex关卡的信息
@return _ map ex关卡的通关情况
--]]
function LunaTowerHomeMediator:GetEXData()
	return self.lunaTowerData.ex
end
--[[
获取当前攻略中关卡的血量信息
@return _ map 血量信息
--]]
function LunaTowerHomeMediator:GetCurrentFloorHp()
	return self.lunaTowerData.challengeFloorHp
end
--[[
根据层id获取血量信息
@params floorId int 层id
@return _ map 血量信息
--]]
function LunaTowerHomeMediator:GetHpDataByFloorId(floorId)
	if floorId == self:GetCurrentPassedFloorId() + 1 then
		-- 当前层
		return self:GetCurrentFloorHp()
	else
		-- 非当前层
		local exData = self:GetEXData()[tostring(floorId)]
		if nil ~= exData then
			return exData.hp
		end
	end
	return nil
end
--[[
获取上一次攻略的队伍信息
@return _ map
--]]
function LunaTowerHomeMediator:GetLastTeamData()
	return self.lunaTowerData.team or {}
end
--[[
获取开放的层id集合
@return openedFloors list<floorId>
--]]
function LunaTowerHomeMediator:GetOpenedFloors()
	local openedFloors = {}

	local maxFloor = self:GetMaxFloor()
	local floorConfigTable = CommonUtils.GetConfigAllMess('floor', 'lunaTower')

	local floorConfig = nil
	for i = 1, maxFloor do
		floorConfig = floorConfigTable[tostring(i)]
		if nil ~= floorConfig then
			table.insert(openedFloors, 1, checkint(floorConfig.id))
		end
	end

	return openedFloors
end
--[[
获取消耗信息
@return costGoodsInfo map {
	goodsId int 道具id
	num int 道具数量
}
--]]
function LunaTowerHomeMediator:GetResetCostGoodsInfo()
	local costGoodsId = nil
	local costGoodsAmount = 0

	if nil ~= self.lunaTowerData.resurrection and 1 <= #self.lunaTowerData.resurrection then
		for _, goodsInfo in ipairs(self.lunaTowerData.resurrection) do
			costGoodsId = checkint(goodsInfo.goodsId)
			costGoodsAmount = checkint(goodsInfo.num)

			if app.gameMgr:GetAmountByIdForce(costGoodsId) >= costGoodsAmount then
				return {
					goodsId = costGoodsId,
					num = costGoodsAmount
				}
			end
		end

		-- 如果走一遍还没取到 直接取第一种道具
		if nil ~= self.lunaTowerData.resurrection[1] then
			costGoodsId = checkint(self.lunaTowerData.resurrection[1].goodsId)
			costGoodsAmount = checkint(self.lunaTowerData.resurrection[1].num)
		end
	end

	return {
		goodsId = costGoodsId,
		num = costGoodsAmount
	}
end
--[[
根据层id 关卡id判断该关卡是否是ex关卡
@params floorId int 层id
@params questId int 关卡id
@return isEX bool 是否是ex关卡
--]]
function LunaTowerHomeMediator:IsEXQuest(floorId, questId)
	local isEX = false
	
	local floorConfig = CommonUtils.GetConfig('lunaTower', 'floor', floorId)
	if nil ~= floorConfig and nil ~= floorConfig.questId and 1 < #floorConfig.questId then
		if questId == checkint(floorConfig.questId[2]) then
			isEX = true
		end
	end

	return isEX
end
--[[
获取队伍信息
@return _ list {
	[1] = {
		{id = nil},
		{id = nil},
		{id = nil},
		...
	},
	...
}
--]]
function LunaTowerHomeMediator:GetTeamData()
	return self:ConvertTeamStr2Data(self:GetLastTeamData())
end
--[[
根据数据库id获取luna塔的卡牌继承状态
@params id int 卡牌数据库id
@return hpPercent, energyPercent number, number 血量百分比, 能量百分比
--]]
function LunaTowerHomeMediator:GetCardStatusById(id)
	local cardData = app.gameMgr:GetCardDataById(id)
	if nil ~= cardData and 0 ~= checkint(cardData.cardId) then
		return checknumber(cardData.lunaTowerHp), checknumber(cardData.lunaTowerEnergy)
	end
	return 0, 0
end
--[[
本地队伍数据->服务器字符串
@params teamData list 本地编队数据
@return teamStr string 传给服务器的数据
--]]
function LunaTowerHomeMediator:ConvertTeamData2Str(teamData)
	local teamAmount = table.nums(teamData)
	local teamData_ = nil
	local cardData_ = nil
	local fixedTeamData = {}

	for teamIndex = 1, teamAmount do
		
		fixedTeamData[tostring(teamIndex)] = ''
		teamData_ = teamData[teamIndex]
		if nil ~= teamData_ then

			for i = 1, MAX_TEAM_MEMBER_AMOUNT do

				cardData_ = teamData_[i]
				if nil ~= cardData_ and 0 ~= checkint(cardData_.id) then
					fixedTeamData[tostring(teamIndex)] = fixedTeamData[tostring(teamIndex)] .. tostring(cardData_.id)
				else
					fixedTeamData[tostring(teamIndex)] = fixedTeamData[tostring(teamIndex)] .. ''
				end

				if i < MAX_TEAM_MEMBER_AMOUNT then
					fixedTeamData[tostring(teamIndex)] = fixedTeamData[tostring(teamIndex)] .. ','
				end

			end

		end

	end

	return json.encode(fixedTeamData)
end
--[[
服务器编队信息 -> 本地队伍数据
@params teamStr map {
	['1'] = {'1', '2', '3', ...},
	...
}
@return fixedTeamData list 本地编队数据
--]]
function LunaTowerHomeMediator:ConvertTeamStr2Data(teamStr)
	local teamAmount = table.nums(teamStr)
	local teamData_ = nil
	local fixedTeamData = {}
	
	for teamIndex = 1, teamAmount do

		fixedTeamData[teamIndex] = {}
		teamData_ = teamStr[tostring(teamIndex)]
		if nil ~= teamData_ then

			for i = 1, MAX_TEAM_MEMBER_AMOUNT do

				if nil ~= teamData_[i] and 0 ~= checkint(teamData_[i]) then
					fixedTeamData[teamIndex][i] = {id = checkint(teamData_[i])}
				else
					fixedTeamData[teamIndex][i] = {id = nil}
				end

			end

		end

	end

	return fixedTeamData
end
--[[
获取返回的mediator信息
@return name string 返回的mediator名字
--]]
function LunaTowerHomeMediator:GetBackToMediator()
	local name = 'HomeMediator'
	if nil ~= self.lunaTowerData.requestData and nil ~= self.lunaTowerData.requestData.backMediatorName then
		name = self.lunaTowerData.requestData.backMediatorName
	end
	return name
end
---------------------------------------------------
-- get set end --
---------------------------------------------------













return LunaTowerHomeMediator
