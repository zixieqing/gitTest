--[[
扭蛋系统mediator
--]]
local Mediator = mvc.Mediator
---@class Anniversary19LittleMonsterMediator :Mediator
local Anniversary19LittleMonsterMediator = class("Anniversary19LittleMonsterMediator", Mediator)
local NAME = "Anniversary19LittleMonsterMediator"
local BUTTON_TAG = {
	GIVE_UP   = 1001, --放弃
	CHALLENGE = 1002, --挑战
}
local gameMgr            = app.gameMgr
local anniversary2019Mgr = app.anniversary2019Mgr
---ctor
---@param viewComponent table
function Anniversary19LittleMonsterMediator:ctor(param ,  viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.exploreId = param.exploreId  or  1
	self.exploreModuleId = param.exploreModuleId  or  1
	self.progress = anniversary2019Mgr:GetCurrentExploreProgress()
end
function Anniversary19LittleMonsterMediator:InterestSignals()
	local signals = {
		POST.ANNIVERSARY2_EXPLORE_SECTION_GIVE_UP.sglName
	}
	return signals
end

function Anniversary19LittleMonsterMediator:ProcessSignal( signal )
	local data = signal:GetBody()
	local name = signal:GetName()
	local progress = anniversary2019Mgr:GetCurrentExploreProgress()
	if  not self.progress == progress then
		app.uiMgr:ShowInformationTips(app.anniversary2019Mgr:GetPoText(__('已通过该探索')))
		return
	end

end
function Anniversary19LittleMonsterMediator:Initial( key )
	self.super.Initial(self, key)
	---@type Anniversary19LittleMonsterView
	local viewComponent = require("Game.views.anniversary19.Anniversary19LittleMonsterView").new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	app.uiMgr:GetCurrentScene():AddGameLayer(viewComponent)
	viewComponent:AddDiffView(self.exploreModuleId , self.exploreId )
	local exploreData = anniversary2019Mgr:GetExploreData()
	local result = exploreData.section[checkint(self.progress)].result
	viewComponent:UpdateUI(self.exploreModuleId  , self.exploreId , result )
	local viewData = viewComponent.viewData
	display.commonUIParams(viewData.leftButton , {cb = handler(self , self.ButtonAction)})
	viewData.leftButton:setTag(BUTTON_TAG.GIVE_UP)
	display.commonUIParams(viewData.rightButton , {cb = handler(self , self.ButtonAction)})
	viewData.rightButton:setTag(BUTTON_TAG.CHALLENGE)

end
function Anniversary19LittleMonsterMediator:ButtonAction(sender)
	PlayAudioByClickNormal()
	local tag = sender:getTag()
	local progress = anniversary2019Mgr:GetCurrentExploreProgress()
	if  not self.progress == progress then
		app.uiMgr:ShowInformationTips(app.anniversary2019Mgr:GetPoText(__('该探索已通过')))
		return
	end
	if tag ==  BUTTON_TAG.GIVE_UP then
		local commonTip = require('common.NewCommonTip').new({
			text = app.anniversary2019Mgr:GetPoText(__('确定要放弃当前关卡吗？')) ,
			extra = app.anniversary2019Mgr:GetPoText(__('放弃当前奖励进入下一关')) ,
			callback = function()
				self:SendSignal(POST.ANNIVERSARY2_EXPLORE_SECTION_GIVE_UP.cmdName, { exploreModuleId = self.exploreModuleId })
			end
		})
		commonTip:setPosition(display.center )
		app.uiMgr:GetCurrentScene():AddDialog(commonTip)

	elseif tag == BUTTON_TAG.CHALLENGE then
		local conf = anniversary2019Mgr:GetDreamQuestTypeConfByDreamQuestType(anniversary2019Mgr.dreamQuestType.LITTLE_MONSTER)
		local oneConf = conf[tostring(self.exploreModuleId)][tostring(self.exploreId)]
		local questId = oneConf.questId
		local battleReadyData = BattleReadyConstructorStruct.New(
				1,
				gameMgr:GetUserInfo().localCurrentBattleTeamId,
				gameMgr:GetUserInfo().localCurrentEquipedMagicFoodId,
				questId ,
				QuestBattleType.WONDERLAND,
				nil ,
				POST.ANNIVERSARY2_EXPLORE_SECTION_MONSTER_QUEST_AT.cmdName,
				{exploreModuleId = self.exploreModuleId},
				POST.ANNIVERSARY2_EXPLORE_SECTION_MONSTER_QUEST_AT.sglName,
				POST.ANNIVERSARY2_EXPLORE_SECTION_MONSTER_QUEST_GRADE.cmdName,
				{exploreModuleId = self.exploreModuleId},
				 POST.ANNIVERSARY2_EXPLORE_SECTION_MONSTER_QUEST_GRADE.sglName ,
				NAME,
"anniversary19.Anniversary19DreamCircleMainMediator"
		)
		battleReadyData.disableUpdateBackButton = true
		battleReadyData.battleType = QuestBattleType.WONDERLAND
		------------ 战斗准备界面 ------------
		AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.Battle_UI_Create_Battle_Ready, battleReadyData)
	end
end

function Anniversary19LittleMonsterMediator:OnRegist()

end
function Anniversary19LittleMonsterMediator:OnUnRegist()
	local viewComponent = self:GetViewComponent()
	if viewComponent and (not tolua.isnull(viewComponent)) then
		viewComponent:removeFromParent()
	end
end

return Anniversary19LittleMonsterMediator
