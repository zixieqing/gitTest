--[[
进入战斗的管理器
@params table {
	battleReadyView GameScene 战斗准备界面
	disableUpdateBackButton bool 禁用更新返回按钮
}
--]]
local Mediator = mvc.Mediator
local EnterBattleMediator = class("EnterBattleMediator", Mediator)
local NAME = "EnterBattleMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local PlayerSkillCommand = require('Game.command.PlayerSkillCommand')
local BattleCommand = require('battleEntry.network.BattleCommand')
local QuestCommentMediator = require("Game.mediator.QuestCommentMediator")
local httpMgr = AppFacade.GetInstance():GetManager("HttpManager")

---------------------------------------------------
-- mediator extend begin --
---------------------------------------------------
function EnterBattleMediator:ctor( params, viewComponent )
	self.super:ctor(NAME, viewComponent)
	params = params or {}
	self.battleReadyView = params.battleReadyView
	self.teamFormationView = nil
	self.battleConstructor = nil

	self.disableUpdateBackButton = params.disableUpdateBackButton

	-- 回调函数集
	self.networkCallbacks = {}
end
function EnterBattleMediator:InterestSignals()
	local signals = {
		-- 进入战斗统一的消息处理
		SIGNALNAMES.Battle_Enter,
		SIGNALNAMES.Battle_Raid_Enter,
		---------- 更换主角技 ----------
		SIGNALNAMES.Quest_SwitchPlayerSkill_Callback,
		"CHANGE_PLAYER_SKILL",
		"SHOW_SELECT_PLAYER_SKILL",
		---------- 更换魔法食物 ----------
		"SHOW_SELECT_MAGIC_FOOD",
		---------- 关卡扫荡 ----------
		"SHOW_SWEEP_POPUP",
		"QUEST_SWEEP",
		---------- 更换编队 ----------
		"SHOW_TEAM_FORMATION",
		"CLOSE_TEAM_FORMATION",
		---------- 购买挑战次数 ----------
		"SHOW_BUY_CHALLENGE_TIME",
		"BUY_CHALLENGE_TIME",
		POST.QUEST_PURCHASE_CHALLENGE_TIME.sglName,
		---------- 操作战斗准备界面 ----------
		"SHOW_BATTLE_READY_POPUP",
		"HIDE_BATTLE_READY_POPUP",
		HomeScene_ChangeCenterContainer_TeamFormation,
		SGL.QUEST_CHALLENGE_TIME_UPDATE,
	}
	return signals
end
function EnterBattleMediator:ProcessSignal( signal )
	local name = signal:GetName()
	local responseData = signal:GetBody()

	if SIGNALNAMES.Battle_Enter == name then

		-- 准备进入战斗 请求服务器
		self:EnterBattle(responseData)

	
	elseif SIGNALNAMES.Battle_Raid_Enter == name then

		-- 准备进入战斗 请求服务器
		self:EnterRaidBattle(responseData)

	
	elseif SIGNALNAMES.Quest_SwitchPlayerSkill_Callback == name then

		if self.networkCallbacks.changePlayerSkillCallback then
			self.networkCallbacks.changePlayerSkillCallback(responseData)
		end

	elseif "SHOW_SELECT_MAGIC_FOOD" == name then

		-- 显示装备魔法堕神弹窗
		self:ShowEquipMagicFoodPopup(responseData)

	elseif "SHOW_SELECT_PLAYER_SKILL" == name then
		
		-- 显示更换主角技弹窗
		self:ShowSelectPlayerSkillPopup(responseData)

	elseif "CHANGE_PLAYER_SKILL" == name then

		-- 请求切换主角技接口
		--debug
		-- local s = string.split(responseData.requestData.skills, ',')
		-- responseData.responseCallback({skill = s})
		--debug
		self.networkCallbacks.changePlayerSkillCallback = responseData.responseCallback
		self:SendSignal(COMMANDS.COMMAND_Quest_SwitchPlayerSkill, responseData.requestData)

	elseif "SHOW_SWEEP_POPUP" == name then

		-- 显示扫荡选择弹窗
		if QuestBattleType.MAP == CommonUtils.GetQuestBattleByQuestId(responseData.stageId) then
			self:ShowSweepPopup(responseData.stageId)
		end

	elseif "SHOW_TEAM_FORMATION" == name then

		-- 显示编队界面
		 self:ShowTeamFormation(responseData)


	elseif "CLOSE_TEAM_FORMATION" == name then

		-- 关闭编队界面
		self:GetFacade():DispatchObservers(TeamFormationScene_ChangeCenterContainer)


	elseif HomeScene_ChangeCenterContainer_TeamFormation == name then

		-- 编队界面关闭成功 回调函数
		self:CloseTeamFormation()


	elseif "SHOW_BATTLE_READY_POPUP" == name then

		-- 显示战斗准备界面
		self:ShowBattleReadyView(true)

	elseif "HIDE_BATTLE_READY_POPUP" == name then

		-- 隐藏战斗准备界面
		self:ShowBattleReadyView(false)

	elseif "SHOW_BUY_CHALLENGE_TIME" == name then

		-- 显示购买挑战次数界面
		self:ShowBuyChallengePopup(responseData.stageId)

	elseif "BUY_CHALLENGE_TIME" == name then

		-- 购买剩余挑战次数
		local requestData = {
			questId = responseData.questId,
			num = responseData.num
		}
		self:SendSignal(POST.QUEST_PURCHASE_CHALLENGE_TIME.cmdName, requestData)

	elseif POST.QUEST_PURCHASE_CHALLENGE_TIME.sglName == name then

		-- 购买剩余挑战次数成功
		uiMgr:ShowInformationTips(__('购买成功'))
		-- 刷新幻晶石
		CommonUtils.DrawRewards({
			{goodsId = DIAMOND_ID, num = checkint(responseData.diamond) - checkint(gameMgr:GetUserInfo().diamond)}
		})
		-- 刷新剩余挑战次数
		local challengeTime = gameMgr:GetChallengeTimeByStageId(responseData.requestData.questId)
		if nil ~= challengeTime then
			gameMgr:UpdateChallengeTimeByStageId(responseData.requestData.questId, checkint(challengeTime) + responseData.requestData.num)
		end
		-- 刷新界面
		if nil ~= self.battleReadyView then
			self.battleReadyView:RefreshChallengeTime()
		end

	elseif name == SGL.QUEST_CHALLENGE_TIME_UPDATE then
		if self.battleReadyView ~= nil then
			self.battleReadyView:RefreshChallengeTime()
		end

	end
end
function EnterBattleMediator:OnRegist()
	------------ 注册接口 ------------
	if not self.disableUpdateBackButton then
		uiMgr:UpdateBackButton(false)
	end
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Quest_SwitchPlayerSkill, PlayerSkillCommand)
	self:GetFacade():RegistSignal(POST.QUEST_PURCHASE_CHALLENGE_TIME.cmdName, BattleCommand)
	------------ 注册接口 ------------

	-- 初始化战斗网络管理器

	self.BNetworkMediator = AppFacade.GetInstance():RetrieveMediator('BattleNetworkMediator')
	if not self.BNetworkMediator then
		local BattleNetworkMediator = require('battleEntry.network.BattleNetworkMediator')
		self.BNetworkMediator = BattleNetworkMediator.new()
		self:GetFacade():RegistMediator(self.BNetworkMediator)
	end
end
function EnterBattleMediator:OnUnRegist()
	------------ 注销接口 ------------
	if not self.disableUpdateBackButton then
		uiMgr:UpdateBackButton(true)
	end
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Quest_SwitchPlayerSkill)
	self:GetFacade():UnRegsitSignal(POST.QUEST_PURCHASE_CHALLENGE_TIME.cmdName)
	------------ 注销接口 ------------
	if nil ~= self.battleReadyView then
	    uiMgr:GetCurrentScene():RemoveDialog(self.battleReadyView)
	end

	local cleanDialogList = {
		'SweepPopup',
		'DropPetView',
		'SelectMagicFoodPopup',
		'SelectPlayerSkillPopup',
		'BuyChallengeTimePopup',
		'ChooseBattleHeroView'
	}
	for _, dialogName in ipairs(cleanDialogList) do
		uiMgr:GetCurrentScene():RemoveDialogByName(dialogName)
	end
	self:GetFacade():UnRegsitMediator('TeamFormationMediator')
	self:GetFacade():UnRegsitMediator('SweepChoiceMediator')
end
---------------------------------------------------
-- mediator extend end --
---------------------------------------------------

---------------------------------------------------
-- view control begin --
---------------------------------------------------
--[[
显示装备堕神诱饵界面
@params data table 参数
--]]
function EnterBattleMediator:ShowEquipMagicFoodPopup(data)
	data = data or {}
	local tag = 3001
	local mediatorName = NAME
	local layer = require('Game.views.SelectMagicFoodPopup').new({
		tag = tag,
		equipedMagicFoodId = data.equipedMagicFoodId,
		equipCallback = data.equipCallback})
	display.commonUIParams(layer, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
	layer:setName('SelectMagicFoodPopup')
	layer:setTag(tag)
	uiMgr:GetCurrentScene():AddDialog(layer)
end
--[[
显示更换主角技弹窗
@parmas data table 参数
--]]
function EnterBattleMediator:ShowSelectPlayerSkillPopup(data)
	data = data or {}
	local tag = 4002
	data.tag = tag
	local layer = require('Game.views.SelectPlayerSkillPopup').new(data)
	display.commonUIParams(layer, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
	layer:setName('SelectPlayerSkillPopup')
	layer:setTag(tag)
	uiMgr:GetCurrentScene():AddDialog(layer)
end
--[[
显示扫荡弹窗
--]]
function EnterBattleMediator:ShowSweepPopup(stageId)
	if not gameMgr:CanSweepQuestByQuestGrade(stageId) then
		uiMgr:ShowInformationTips(__('达成本关三星才能扫荡'))
		return
	end

	local stageConf = CommonUtils.GetQuestConf(stageId)
    if stageConf and checkint(stageConf.difficulty)  == 2 then
		local tag = 4001
		local layer = require('Game.views.SweepPopup').new({
			tag = tag,
			stageId = stageId
		})
		display.commonUIParams(layer, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
		layer:setTag(tag)
		layer:setName('SweepPopup')
		uiMgr:GetCurrentScene():AddDialog(layer)
	else
		local sweepMdt = require('Game.mediator.map.SweepChoiceMediator').new({stageId = stageId})
		app:RegistMediator(sweepMdt)
	end
end
--[[
显示扫荡奖励
@params responseData table 服务器返回信息
--]]
function EnterBattleMediator:ShowSweepReward(responseData)
	-- local delayList = {}
	-- local function ShowSweepRewardPopup()
	-- 	------------ 展示扫荡奖励 ------------
	-- 	local tag = 2005
	-- 	--uiMgr:AddDialog('common.RewardPopup', {rewards = signal:GetBody().rewards,mainExp = signal:GetBody().mainExp, tag = self.rewardsLayer})
	-- 	if checkint(responseData.requestData.times )  == 1 then
	-- 		responseData.sweep['1'].rewards[#responseData.sweep['1'].rewards+1] = {goodsId = EXP_ID, num = responseData.sweep['1'].mainExp}
	-- 		uiMgr:AddDialog('common.RewardPopup', {rewards = responseData.sweep['1'].rewards,mainExp = responseData.sweep['1'].mainExp ,addBackpack = false,delayFuncList_ = delayList})
	-- 	else
	-- 		local layer = require('Game.views.SweepRewardPopup').new({tag = tag, rewardsData = responseData , executeAction = true , delayFuncList_ = delayList})
	-- 		display.commonUIParams(layer, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
	-- 		layer:setTag(tag)
	-- 		uiMgr:GetCurrentScene():AddDialog(layer)
	-- 	end
	-- 	------------ 展示扫荡奖励 ------------
	-- end

	-- -- 检测堕神 弹堕神弹窗
	-- local petViews = {}
	-- local function ShowNextPetView()
	-- 	local curPetView = petViews[1]
 --        uiMgr:GetCurrentScene():RemoveDialog(curPetView)
	-- 	table.remove(petViews, 1)

	-- 	if 0 < table.nums(petViews) then
	-- 		-- 存在下一个view 继续
	-- 		petViews[1]:setVisible(true)
	-- 	else
	-- 		-- 不存在 弹出扫荡奖励弹窗
	-- 		ShowSweepRewardPopup()
	-- 	end


	-- end

	-- local stageConf = CommonUtils.GetConfig('quest', 'quest', responseData.requestData.questId)

	-- ------------ 刷新本地数据 ------------
	-- -- 金币体力
	-- -- local newPlayerInfo = {
	-- 	-- hp = math.max(gameMgr:GetUserInfo().hp - checkint(stageConf.consumeHp) * responseData.requestData.times, 0)
	-- -- }
	-- -- gameMgr:UpdatePlayer(newPlayerInfo) --修正扫荡时显示体力为负的问题
	-- CommonUtils.DrawRewards({{ goodsId =  GOLD_ID , num  = responseData.totalGold  },{ goodsId =  HP_ID  ,num =  - checkint(stageConf.consumeHp) * responseData.requestData.times}})
	-- -- 魔法诱饵
	-- if responseData.requestData.magicFoodId then
	-- 	CommonUtils.DrawRewards({{goodsId = responseData.requestData.magicFoodId, num = - math.min(gameMgr:GetAmountByGoodId(responseData.requestData.magicFoodId), responseData.requestData.times)}})
	-- end
	-- -- 扫荡券
	-- CommonUtils.DrawRewards({{goodsId = SWEEP_QUEST_ID, num = - math.min(gameMgr:GetAmountByGoodId(SWEEP_QUEST_ID), responseData.requestData.times)}})
	-- -- 剩余挑战次数
	-- if responseData.challengeTime then
	-- 	gameMgr:UpdateChallengeTimeByStageId(responseData.requestData.questId, checkint(responseData.challengeTime))
	-- 	-- 刷新界面
	-- 	if nil ~= self.battleReadyView then
	-- 		self.battleReadyView:RefreshChallengeTime()
	-- 	end
	-- end
	-- -- 经验
	-- -- dump(responseData.totalMainExp)
 -- 	delayList = CommonUtils.DrawRewards({{goodsId = EXP_ID, num = (checkint(responseData.totalMainExp) - gameMgr:GetUserInfo().mainExp)}  },true )
	-- -- 获得奖励道具
	-- local monsterConf = nil
	-- for k,v in pairs(responseData.sweep) do
	-- 	CommonUtils.DrawRewards(checktable(v.rewards))
	-- 	-- 遍历堕神
	-- 	for i,m in ipairs(checktable(v.monsters)) do
	-- 		monsterConf = CommonUtils.GetConfig('monster', 'monster', m.monsterId)

	-- 		local dropPetView = nil
	-- 		if MONSTER_ELITE == checkint(monsterConf.type) or 
	-- 			MONSTER_BOSS == checkint(monsterConf.type) then

	-- 			-- 精英 boss 级别堕神无视一切创建抓宠界面
	-- 			dropPetView = require('Game.views.DropPetView').new({
	-- 				stageId = responseData.requestData.questId,
	-- 				monsterId = checkint(m.monsterId),
	-- 				dropMonsterTicket = tostring(m.dropMonsterTicket),
	-- 				cancelCB = function ()
	-- 					ShowNextPetView()
	-- 				end,
	-- 				buyCB = function (requestData)
	-- 					self.BNetworkMediator:CatchPet(requestData, function (responseData)
	-- 						-- 将抓到的堕神插入奖励中
	-- 						table.insert(v.rewards, {goodsId = responseData.pet.petId, num = 1})
	-- 						gameMgr:UpdatePetDataById(responseData.pet.petId, responseData.pet)
	-- 						ShowNextPetView()
	-- 					end)
	-- 				end,
	-- 				showCover = true
	-- 			})

	-- 		else

	-- 			-- 普通小怪 插入奖励
	-- 			table.insert(v.rewards, {goodsId = m.pet.petId, num = 1})

	-- 			-- 将小怪数据插入本地
	-- 			gameMgr:UpdatePetDataById(m.pet.petId, m.pet)

	-- 			-- 首次掉落 跳抓宠界面 但是不需要购买
	-- 			if m.isFirstDrop then
	-- 				dropPetView = require('Game.views.DropPetView').new({
	-- 					stageId = responseData.requestData.questId,
	-- 					monsterId = checkint(m.monsterId),
	-- 					dropMonsterTicket = tostring(m.dropMonsterTicket),
	-- 					cancelCB = function ()
	-- 						ShowNextPetView()
	-- 					end,
	-- 					showCover = true
	-- 				})
	-- 			end

	-- 		end

	-- 		if nil ~= dropPetView then
	-- 			dropPetView:setVisible(false)
	-- 			dropPetView:setName('DropPetView')
	-- 			dropPetView:setTag(5001 + table.nums(petViews))
	-- 			dropPetView:setPosition(display.center)
	-- 			uiMgr:GetCurrentScene():AddDialog(dropPetView)
	-- 			table.insert(petViews, dropPetView)
	-- 		end
	-- 	end

	-- end
	-- -- 刷新扫荡界面
	-- local sweepPopup = uiMgr:GetCurrentScene():GetDialogByTag(4001)
	-- if sweepPopup and sweepPopup.RefreshSelfData then
	-- 	sweepPopup:RefreshSelfData()
	-- end
	-- ------------ 刷新本地数据 ------------

	-- ------------ 检测是否需要弹出抓宠弹窗 ------------
	-- if table.nums(petViews) > 0 then
	-- 	petViews[1]:setVisible(true)
	-- else
	-- 	ShowSweepRewardPopup()
	-- end
	-- ------------ 检测是否需要弹出抓宠弹窗 ------------
end
--[[
显示编队界面
--]]
function EnterBattleMediator:ShowTeamFormation(selectedTeamIdx)
	local TeamFormationMediator = require( 'Game.mediator.TeamFormationMediator')
	local mediator = TeamFormationMediator.new({isCommon = true,jumpTeamIndex = selectedTeamIdx})
	self:GetFacade():RegistMediator(mediator)
	self.teamMediator = mediator
	self:ShowBattleReadyView(false)
end
--[[
关闭编队界面
--]]
function EnterBattleMediator:CloseTeamFormation()
	if self.teamMediator then
		-- 编队完成 关闭编队界面 刷新战斗准备界面阵容
		self:ShowBattleReadyView(true)
		if nil ~= self.battleReadyView then
			self.battleReadyView:RefreshTeamFormation(gameMgr:GetUserInfo().teamFormation)
		end
	else
		print('\n**************\n', 'logic error here should remove teamMediator in EnterBattleMediator but teamMediator is nil', '\n**************\n')
	end
end
--[[
显示或隐藏战斗准备界面
@params visible bool 是否显示
--]]
function EnterBattleMediator:ShowBattleReadyView(visible)
	if self.battleReadyView then
		self.battleReadyView:setVisible(visible)
	end
end
--[[
显示购买剩余挑战次数界面
@params stageId int 关卡id
--]]
function EnterBattleMediator:ShowBuyChallengePopup(stageId)
	local tag = 4003
	local layer = require('Game.views.map.BuyChallengeTimePopup').new({
		tag = tag,
		stageId = stageId
	})
	display.commonUIParams(layer, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
	layer:setName('BuyChallengeTimePopup')
	layer:setTag(tag)
	uiMgr:GetCurrentScene():AddDialog(layer)
end
---------------------------------------------------
-- view control end --
---------------------------------------------------

---------------------------------------------------
-- logic control begin --
---------------------------------------------------
--[[
一切就绪 请求服务器开始一场战斗
@params battleConstructor BattleConstructor 战斗构造器
--]]
function EnterBattleMediator:EnterBattle(battleConstructor)
	self.battleConstructor = battleConstructor

	local teamCardsInfo = self.battleConstructor.battleConstructorData.friendFormation.members[1]
	for i,v in ipairs(teamCardsInfo) do
		local cardId = checkint(v.cardId)
		if cardId > 0 then
			local soundTypes = { SoundType.TYPE_TEAM, SoundType.TYPE_TEAM_CAPTAIN }
			CommonUtils.PlayCardSoundByCardId(cardId, soundTypes[math.random(#soundTypes)], SoundChannel.AVATAR_QUEST)
			break
		end
	end

	if nil == battleConstructor:GetServerCommand() then
		self:StartBattle()
	else
		self.BNetworkMediator:ReadyToEnterBattle(battleConstructor, handler(self, self.StartBattle))
	end
end
--[[
请求完成 进入游戏回调
--]]
function EnterBattleMediator:StartBattle(responseData)
	local serverCommand = self.battleConstructor:GetServerCommand()
	local fromToData = self.battleConstructor:GetFromToData()
	local stageId = self.battleConstructor:GetBattleConstructData().stageId

	-- 写死一个看过第一场战斗的标识位
	if 8999 == stageId then
		cc.UserDefault:getInstance():setIntegerForKey(ENTERED_FIRST_P_BATTLE_KEY, 1)
		cc.UserDefault:getInstance():flush()
	end

	if serverCommand then
		if QuestBattleType.ROBBERY == self.battleConstructor:GetBattleConstructData().questBattleType then
			local enemyFormationData = FormationStruct.New(
				nil,
				self.battleConstructor:GetFormattedTeamsDataByTeamsCardData({[1] = responseData.cards}),
				nil,
				ObjectPropertyFixedAttrStruct.New()
			)
			self.battleConstructor:UpdateEnemyFormation(enemyFormationData)
		end

		------------ 初始化一次随机种子 ------------
		if responseData and responseData.randomSeed then
			self.battleConstructor:GetBattleRandomConfig().randomseed = tostring(responseData.randomSeed)
		end
		------------ 初始化一次随机种子 ------------
	end

	self:GetFacade():RetrieveMediator("Router"):Dispatch(
		{name = fromToData.fromMediatorName},
		{name = 'BattleMediator', params = self.battleConstructor}
	)

end
--[[
进入组队战斗
@params battleConstructor BattleConstructor 战斗构造器
--]]
function EnterBattleMediator:EnterRaidBattle(battleConstructor)
	self.battleConstructor = battleConstructor

	-- 进入前不做特殊处理
	self:StartRaidBattle()
end
--[[
开始组队战斗
@params responseData table 服务器返回的信息
--]]
function EnterBattleMediator:StartRaidBattle(responseData)
	local serverCommand = self.battleConstructor:GetServerCommand()
	local fromToData = self.battleConstructor:GetFromToData()

	self:GetFacade():RetrieveMediator("Router"):Dispatch(
		{name = fromToData.fromMediatorName},
		{name = 'RaidBattleMediator', params = self.battleConstructor}
	)
end
---------------------------------------------------
-- logic control end --
---------------------------------------------------

function EnterBattleMediator:GoogleBack()
	app:UnRegistMediator(NAME)
end

return EnterBattleMediator
