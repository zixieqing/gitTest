--[[
扭蛋系统mediator
--]]
local Mediator = mvc.Mediator
---@class Anniversary20ExploreMonsterMediator :Mediator
local Anniversary20ExploreMonsterMediator = class("Anniversary20ExploreMonsterMediator", Mediator)
local NAME = "Anniversary20ExploreMonsterMediator"
local BUTTON_TAG = {
	GIVE_UP   = 1001, --放弃
	CHALLENGE = 1002, --挑战
}
local ANNIV20_ENTER_BATTLE = 'ANNIV20_ENTER_BATTLE'
local ANNIV20_CHANGE_TEAM_VIEW_TAG = 4099
---ctor
---@param param table @{ mapGridId : int}
---@param viewComponent table
function Anniversary20ExploreMonsterMediator:ctor(param ,  viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.mapGridId = param.mapGridId
	app.anniv2020Mgr:setExploreCardsDataHpAndEnergyByTeamState()
end
function Anniversary20ExploreMonsterMediator:InterestSignals()
	local signals = {
		"ANNIVERSARY_2020_EXPLORE_STEP_CLOSE_EVENT" ,
		ANNIV20_ENTER_BATTLE ,
	}
	return signals
end

function Anniversary20ExploreMonsterMediator:ProcessSignal( signal )
	local data = signal:GetBody()
	local name = signal:GetName()
	if name == ANNIV20_ENTER_BATTLE then
		self:MonsterEnterBattle(data)
	elseif name == "ANNIVERSARY_2020_EXPLORE_STEP_CLOSE_EVENT" then
		self:GetFacade():UnRegistMediator(NAME)
	end


end

function Anniversary20ExploreMonsterMediator:Initial( key )
	self.super.Initial(self, key)
	---@type Anniversary20ExploreMonsterView
	local viewComponent = require("Game.views.anniversary20.Anniversary20ExploreMonsterView").new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	app.uiMgr:GetCurrentScene():AddGameLayer(viewComponent)
	viewComponent:AddDiffView(self.mapGridId )
	viewComponent:UpdateUI(self.mapGridId)
	local viewData = viewComponent.viewData
	display.commonUIParams(viewData.leftButton , {cb = handler(self , self.ButtonAction)})
	viewData.leftButton:setTag(BUTTON_TAG.GIVE_UP)
	display.commonUIParams(viewData.rightButton , {cb = handler(self , self.ButtonAction)})
	viewData.rightButton:setTag(BUTTON_TAG.CHALLENGE)

end

function Anniversary20ExploreMonsterMediator:ButtonAction(sender)
	PlayAudioByClickNormal()
	local tag = sender:getTag()
	if tag == BUTTON_TAG.CHALLENGE then
		self:ShowEditTeamMemberView()
	end
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
function Anniversary20ExploreMonsterMediator:GetTeamData()
	return app.anniv2020Mgr:GetTeamData()
end
function Anniversary20ExploreMonsterMediator:SetTeamData(teamData)
	app.anniv2020Mgr:SetTeamData(teamData)
end
--[[
显示队伍编辑 准备进入战斗
@params data table {
	floorId int 当前的层id
	questId int 当前层对应的关卡id
	isEX bool 是否是ex关卡
}
--]]
function Anniversary20ExploreMonsterMediator:ShowEditTeamMemberView()
	local HP =  FOOD.ANNIV2020.TEAM_STATE.HP
	local ENERGY =  FOOD.ANNIV2020.TEAM_STATE.ENERGY
	local layer = require('Game.views.pvc.PVCChangeTeamScene').new({
	   teamDatas = self:GetTeamData(),
	   maxTeamAmount = 1,
	   title = __('编辑队伍'),
	   teamTowards = 1,
	   avatarTowards = 1,
	   enterBattleSignalName = ANNIV20_ENTER_BATTLE,
	   battleType = 1,
	   banList = {
		   career = {},
		   quality = {},
		   card = {}
	   },
	   showCardStatus = {
		   hpFieldName = HP,
		   energyFieldName = ENERGY
	   },
	   costGoodsInfo = nil,
	   battleButtonSkinType = 1,
	   isDisableHomeTopSignal = true
   })
	layer:setAnchorPoint(cc.p(0.5, 0.5))
	layer:setPosition(display.center)
	layer:setTag(ANNIV20_CHANGE_TEAM_VIEW_TAG)
	app.uiMgr:GetCurrentScene():AddDialog(layer)
end
--[[
进入战斗回调
@params data map {
	teamData list 队伍信息
}
--]]
function Anniversary20ExploreMonsterMediator:MonsterEnterBattle(data)
	---@type Anniversary20ExploreMonsterView
	local viewComponent = self:GetViewComponent()
	local viewData = viewComponent.viewData
	viewData.rightButton:setEnabled(false)
	viewData.rightButton:runAction(cc.Sequence:create(
		cc.DelayTime:create(0.1),
		cc.CallFunc:create(function()
			viewData.rightButton:setEnabled(true)
		end)
	))
	-- 创建战斗构造器
	local battleConstructor = require('battleEntry.BattleConstructor').new()
	local teamData = data.teamData
	-- 怪物配置信息

	local refId = app.anniv2020Mgr:getExploreingMapRefIdAt(self.mapGridId)
	local mapGridType = app.anniv2020Mgr:getExploreingMapTypeAt(self.mapGridId)
	local monsterQuestConf =  FOOD.ANNIV2020.EXPLORE_TYPE_CONF[mapGridType]:GetValue(refId)
	local questId = checkint(monsterQuestConf.questId)
	local formattedEnemyTeamData = battleConstructor:GetCommonEnemyTeamDataByStageId(questId)
	-- 格式化后的友军阵容
	local ENERGY = FOOD.ANNIV2020.TEAM_STATE.ENERGY
	local HP = FOOD.ANNIV2020.TEAM_STATE.HP
	local formattedFriendTeamData = battleConstructor:ConvertSelectCards2FormattedTeamData(
		teamData, 1, {
			[CardUtils.PROPERTY_TYPE.HP] = {fieldName = HP },
			[CardUtils.PROPERTY_TYPE.ENERGY] = {fieldName = ENERGY},
		}
	)
	-- 服务器参数
	local cards = {}
	for i, v in pairs(teamData[1]) do
		cards[#cards+1] =  v.id
	end
	local cardStr = table.concat(cards , ",")
	local serverCommand = BattleNetworkCommandStruct.New(
			POST.ANNIV2020_EXPLORE_QUEST_AT.cmdName,
			{gridId = self.mapGridId , questId = questId, cards = cardStr},
			POST.ANNIV2020_EXPLORE_QUEST_AT.sglName,
			POST.ANNIV2020_EXPLORE_QUEST_GRADE.cmdName,
			{gridId = self.mapGridId , questId = questId, cards = cardStr },
			POST.ANNIV2020_EXPLORE_QUEST_GRADE.sglName,
			nil,
			nil,
			nil
	)

	local skillBuffs = app.anniv2020Mgr:GetExploreBattleSkillData()

	-- 跳转信息
	local fromToStruct = BattleMediatorsConnectStruct.New(
			"anniversary20.Anniversary20ExploreHomeMediator",
			"anniversary20.Anniversary20ExploreHomeMediator"
	)
	
	battleConstructor:InitByCommonData(
			questId, QuestBattleType.ANNIV2020_EXPLORE, ConfigBattleResultType.ONLY_RESULT ,
			formattedFriendTeamData, formattedEnemyTeamData,
			nil, app.gameMgr:GetUserInfo().allSkill, nil, nil,
			skillBuffs, nil,
			nil, nil, nil,
			nil, false,
			serverCommand, fromToStruct
	)
	battleConstructor:OpenBattle()
	-- 关闭阵容界面
	AppFacade.GetInstance():DispatchObservers('CLOSE_CHANGE_TEAM_SCENE')

end

function Anniversary20ExploreMonsterMediator:OnRegist()

end
function Anniversary20ExploreMonsterMediator:OnUnRegist()
	local viewComponent = self:GetViewComponent()
	if viewComponent and (not tolua.isnull(viewComponent)) then
		viewComponent:removeFromParent()
	end
end

return Anniversary20ExploreMonsterMediator
