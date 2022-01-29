--[[
 * author : liuzhipeng
 * descpt : 联动 pop子 关卡Mediator
--]]
---@class PopBattleBossMediator:Mediator
local PopBattleBossMediator = class('PopBattleBossMediator', mvc.Mediator)
local NAME = "popTeam.PopBattleBossMediator"
local userDefault = cc.UserDefault:getInstance()
function PopBattleBossMediator:ctor(params, viewComponent)
	self.super.ctor(self, NAME, viewComponent)
	params = params or {}
	self.bossId = checkint(params.bossId)
	self.activityId = params.activityId
	self.summaryId = params.summaryId or "1"
	self.selectIndex = 1
	self.bossData = nil
end

------------------ inheritance ------------------
function PopBattleBossMediator:Initial(  key )
	self.super.Initial(self, key)
	---@type PopBattleBossView
	local viewComponent = require('Game.views.link.popMain.PopBattleBossView').new({
		summaryId = self:GetSummaryId() })
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	app.uiMgr:GetCurrentScene():AddDialog(viewComponent)
	local viewData = viewComponent.viewData
	display.commonUIParams(viewData.backBtn , {cb = handler(self, self.CloseMedtior)})
	display.commonUIParams(viewData.bossDetailBtn , {cb = handler(self, self.ShowBossDetailsClick)})
	display.commonUIParams(viewData.timeLayout , {cb = handler(self, self.BuyChallengeTimeClick)})
	display.commonUIParams(viewData.addCardLayer , {cb = handler(self, self.AddCardClick)})
	display.commonUIParams(viewData.battleCommonBtn, {cb = handler(self, self.BattleCallBack)})
	display.commonUIParams(viewData.bossAchieveBtn, {cb = handler(self, self.AchieveClick)})
end
function PopBattleBossMediator:AddCardClick(sender)
	local bossData = self:GetBossData()
	local farmBossLimitConf = CONF.ACTIVITY_POP.FARM_BOSS_LIMIT:GetValue(bossData[self.selectIndex].bossId)
	local limitCardsCareers = farmBossLimitConf.career
	local limitCardsQualities = farmBossLimitConf.qualityId
	local layer = require('Game.views.pvc.PVCChangeTeamScene').new({
       teamDatas = {[1] = clone(self.teamData[self.selectIndex])},
       title = __('编辑战斗队伍'),
       teamTowards = -1,
       avatarTowards = 1,
       teamChangeSingalName =  "TEAM_CHANGE_NOTICE" ,
       isDisableHomeTopSignal =  true ,
       limitCardsCareers =  limitCardsCareers,
       limitCardsQualities =  limitCardsQualities,
       battleType  = BATTLE_SCRIPT_TYPE.MATERIAL_TYPE
   })
	layer:setAnchorPoint(cc.p(0.5, 0.5))
	layer:setPosition(display.center)
	layer:setTag(4001)
	app.uiMgr:GetCurrentScene():AddDialog(layer)
	self.chooseTeamLayer = layer
end
function PopBattleBossMediator:AchieveClick()
	local activityHomeData = app.gameMgr:GetUserInfo().activityHomeData
	local activity = activityHomeData.activity
	local activityData = nil
	for i , v in pairs(activity) do
		if checkint(v.activityId) == self.activityId then
			activityData = v
			break
		end
	end
	local mediator = require('Game.mediator.activity.allRound.ActivityAllRoundMediator').new({activityId = activityData.relatedActivityId})
	app:RegistMediator(mediator)
end
---
--[[
    战斗的回调
-- ]]
function PopBattleBossMediator:BattleCallBack(data)
	local bossDatas = self:GetBossData()
	local bossData = bossDatas[self.selectIndex]
	if checkint(bossData.leftFreeChallengeTimes) <= 0 and checkint(bossData.leftBuyChallengeTimes) <= 0 then
		app.uiMgr:ShowInformationTips(__('挑战次数不足!!!'))
		return
	end
	local cards = {}
	local teamDatas = self:GetTeamData()
	local teamData = teamDatas[self.selectIndex]
	for i , v in pairs(teamData) do
		if checkint(v.id) > 0 then
			cards[#cards+1] = v.id
		else
			cards[#cards+1] = ""
		end
	end


	local bossData = bossDatas[self.selectIndex]
	local serverCommand = BattleNetworkCommandStruct.New(
			POST.POP_FARM_BOSS_QUEST_AT.cmdName,
			{questId = checkint(bossData.bossId) ,activityId = self.activityId , cards = table.concat(cards , ",")  },
			POST.POP_FARM_BOSS_QUEST_AT.sglName,
			POST.POP_FARM_BOSS_QUEST_GRADE.cmdName,
			{questId = checkint(bossData.bossId) , activityId = self.activityId},
			POST.POP_FARM_BOSS_QUEST_GRADE.sglName,
			nil,
			nil,
			nil
	)
	-- 跳转信息
	local fromToStruct = BattleMediatorsConnectStruct.New(
			"link.popMain.PopMainMediator",
			"link.popMain.PopMainMediator"
	)
	-- 阵容信息
	local  teamCards = {}
	for k, v in pairs(teamData) do
		teamCards[checkint(k)] = checkint(v.id)
	end
	-- 选择的主角技信息
	local playerSkillData = {
		0, 0
	}
	-- 创建战斗构造器
	local battleConstructor = require('battleEntry.BattleConstructorEx').new()
	local questBattleType = CommonUtils.GetQuestBattleByQuestId(bossData.bossId)
	local auditionsFriendTeamData = {[1] = cards}
	local formattedFriendTeamData = battleConstructor:GetFormattedTeamsDataByTeamsMyCardData(auditionsFriendTeamData)
	local formattedEnemyTeamData = battleConstructor:GetCommonEnemyTeamDataByStageId(bossData.bossId)
	-- 初始战斗结构体
	battleConstructor:InitByCommonData(
			bossData.bossId,                        -- 关卡 id
			questBattleType, -- 战斗类型
			ConfigBattleResultType.NO_RESULT_DAMAGE_COUNT,       -- 结算类型
			----
			formattedFriendTeamData,                -- 友方阵容
			formattedEnemyTeamData,                 -- 敌方阵容
			----
			nil,                                    -- 友方携带的主角技
			nil,                                    -- 友方所有主角技
			nil,                                    -- 敌方携带的主角技
			nil,                                    -- 敌方所有主角技
			----
			nil,                                    -- 全局buff
			nil,                                    -- 卡牌能力增强信息
			----
			nil,                                    -- 已买活次数
			nil,                                    -- 最大买活次数
			false,                                  -- 是否开启买活
			----
			nil,                                    -- 随机种子
			false,                                  -- 是否是战斗回放
			----
			serverCommand,                          -- 与服务器交互的命令信息
			fromToStruct                            -- 跳转信息
	)
	battleConstructor:OpenBattle()

	--battleConstructor:InitStageDataByNormalEvent(
	--		checkint(bossData.bossId),
	--		serverCommand,
	--		fromToStruct,
	--		teamCards,
	--		playerSkillData
	--)
	--
	--battleConstructor:OpenBattle()
end
function PopBattleBossMediator:GetTeamData()
	local teamDataStr = userDefault:getStringForKey(table.concat({"LINK_POP" , self.activityId , app.gameMgr:GetUserInfo().playerId} , "-")   , "")
	if string.len(teamDataStr) > 0 then
		self.teamData = json.decode(teamDataStr)
	else
		-- 初始化teamData 的数据
		local farmBossLimitConf = CONF.ACTIVITY_POP.FARM_BOSS_LIMIT:GetAll()
		local count = table.nums(farmBossLimitConf)
		self.teamData ={}
		for i = 1, count do
			self.teamData[i] = {
				{}, {} ,{} ,{} ,{}
			}
		end
	end
	return self.teamData
end

function PopBattleBossMediator:SaveTeamData()
	userDefault:setStringForKey(table.concat({"LINK_POP" , self.activityId , app.gameMgr:GetUserInfo().playerId} , "-")  , json.encode(self.teamData))
	userDefault:flush()
end

function PopBattleBossMediator:InterestSignals()
	local signals = {
		POST.POP_FARM_BOSS.sglName,
		POST.FARM_BOSS_BUY_TIMES.sglName,
		"TEAM_CHANGE_NOTICE"
	}
	return signals
end

function PopBattleBossMediator:ProcessSignal( signal )
	local name = signal:GetName()
	local body = signal:GetBody()
	if name == POST.POP_FARM_BOSS.sglName then
		self.bossData = body.boss
		local bossData = self:GetBossData()
		if self.bossId > 0  then
			for i , v in pairs(bossData) do
				if checkint(v.bossId) == self.bossId then
					self.selectIndex = i
					break
				end
			end
		end

		local viewComponent = self:GetViewComponent()

		viewComponent:CreateBossInfo(bossData)
		viewComponent:UpdateView(self.bossData , self.selectIndex)
		local teamData = self:GetTeamData()
		viewComponent:UpdateCardNodes(teamData[self.selectIndex])
		self:BindBossCellClick()
		local isFree = false
		for i, v in pairs(self.bossData) do
			if checkint(v.leftFreeChallengeTimes) == 1 then
				isFree = true
				break
			end
		end
		app:DispatchObservers("POP_BOSS_FREE_EVENT" , { isFree  = isFree})
	elseif name == "TEAM_CHANGE_NOTICE" then
		self.teamData[self.selectIndex] = body.teamData
		if self.chooseTeamLayer and not  tolua.isnull(self.chooseTeamLayer) then
			-- 删除选卡界面
			self.chooseTeamLayer:runAction(cc.RemoveSelf:create())
		end
		local viewComponent = self:GetViewComponent()
		viewComponent:UpdateCardNodes(self.teamData[self.selectIndex])
		self:SaveTeamData()
	elseif name == POST.FARM_BOSS_BUY_TIMES.sglName then
		local requestData = body.requestData
		local bossId = checkint(requestData.bossId)
		local bossData = self:GetBossData()
		for i , boss in pairs(bossData) do
			if checkint(boss.bossId) == bossId then
				boss.leftBuyChallengeTimes = checkint(boss.leftBuyChallengeTimes) + 1
				boss.leftDailyBuyTimes = checkint(boss.leftDailyBuyTimes) - 1
				local viewComponent = self:GetViewComponent()
				viewComponent:UpdateChallegeTimes(boss.leftBuyChallengeTimes)
				break
			end
		end
		local farmConf = CONF.ACTIVITY_POP.FARM:GetValue(self:GetSummaryId())
		local bossChallengeTimesConsume = - checkint(farmConf.bossChallengeTimesConsume)
		CommonUtils.DrawRewards({{goodsId = DIAMOND_ID , num = bossChallengeTimesConsume }})
	end
end

function PopBattleBossMediator:GetBossData()
	return self.bossData
end
-- 购买挑战次数


-- 绑定BossCellClick
function PopBattleBossMediator:BindBossCellClick()
	---@type PopBattleBossView
	local viewComponent = self:GetViewComponent()
	local bossCellViewData = viewComponent.viewData.bossCellViewData
	for i = 1 , #bossCellViewData do
		display.commonUIParams(bossCellViewData[i].bossbgImage , {cb = handler(self , self.BossCellClick)})
	end
end

function PopBattleBossMediator:BuyChallengeTimeClick(sender)
	local farmConf = CONF.ACTIVITY_POP.FARM:GetValue(self:GetSummaryId())
	local bossChallengeTimesConsume = checkint(farmConf.bossChallengeTimesConsume)
	local ownerNum = CommonUtils.GetCacheProductNum(DIAMOND_ID)
	local goodName = GoodsUtils.GetGoodsNameById(DIAMOND_ID)
	if ownerNum < bossChallengeTimesConsume then
		app.uiMgr:ShowInformationTips(string.fmt(__('_name_ 不足'), { _name_ = goodName}))
		return
	end
	local bossDatas = self:GetBossData()
	local leftDailyBuyTimes = bossDatas[self.selectIndex].leftDailyBuyTimes
	local bossChallengeTimesMaxBuyTimes = checkint(farmConf.bossChallengeTimesMaxBuyTimes)
	if checkint(leftDailyBuyTimes) <= 0 then
		app.uiMgr:ShowInformationTips(__('今日购买次数已经用完'))
		return
	end
	app.uiMgr:AddCommonTipDialog({
         text = string.fmt(__('是否使用_num_个_goodName_增加次数' ),{
        _num_ = bossChallengeTimesConsume,
        _goodName_ = goodName }),
		 descr = string.fmt(__("今日剩余购买次数：_num1_/_num2_") , { _num1_ = leftDailyBuyTimes ,_num2_ = bossChallengeTimesMaxBuyTimes}),
		callback = function()
	        local bossData = self:GetBossData()
	        local bossOneData = bossData[self.selectIndex] or {}
			self:SendSignal(POST.FARM_BOSS_BUY_TIMES.cmdName , {
				activityId = checkint(self.activityId) ,
				bossId = checkint(bossOneData.bossId)
			})
		end
    })
end
-- BossCellClick 点击事件
function PopBattleBossMediator:BossCellClick(sender)
	local tag = sender:getTag()
	if tag == self.selectIndex then
		return
	end
	local viewComponent = self:GetViewComponent()
	viewComponent:UpdateView(self:GetBossData() , tag)
	viewComponent:UpdateCardNodes(self.teamData[tag])
	self.selectIndex = tag
end
-- 关闭界面
function PopBattleBossMediator:CloseMedtior()
	self:GetFacade():UnRegistMediator(NAME)
end
function PopBattleBossMediator:GetSummaryId()
	return self.summaryId
end
-- 显示boss详情
function PopBattleBossMediator:ShowBossDetailsClick(sender)
	local bossData = self.bossData[self.selectIndex]
	local bossDetailMediator = require('Game.mediator.BossDetailMediator').new({questId = bossData.bossId})
	self:GetFacade():RegistMediator(bossDetailMediator)
end

function PopBattleBossMediator:EnterLayer()
	self:SendSignal(POST.POP_FARM_BOSS.cmdName, {activityId = self.activityId})
end

function PopBattleBossMediator:OnRegist()
	regPost(POST.POP_FARM_BOSS)
	regPost(POST.FARM_BOSS_BUY_TIMES)
	regPost(POST.POP_FARM_BOSS_QUEST_AT)
	self:EnterLayer()
end

function PopBattleBossMediator:OnUnRegist()
	unregPost(POST.POP_FARM_BOSS)
	unregPost(POST.FARM_BOSS_BUY_TIMES)
	unregPost(POST.POP_FARM_BOSS_QUEST_AT)
	local viewComponent = self:GetViewComponent()
	if viewComponent and (not tolua.isnull(viewComponent)) then
		viewComponent:runAction(cc.RemoveSelf:create())
		self:SetViewComponent(nil)
	end
end


return PopBattleBossMediator