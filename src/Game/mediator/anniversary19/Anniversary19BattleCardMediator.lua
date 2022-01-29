--[[
扭蛋系统mediator
--]]
local Mediator = mvc.Mediator
---@class Anniversary19BattleCardMediator :Mediator
local Anniversary19BattleCardMediator = class("Anniversary19BattleCardMediator", Mediator)
local NAME = "Anniversary19BattleCardMediator"
local BUTTON_TAG = {
	GIVE_UP   = 1001, --放弃
	CHALLENGE = 1002, --挑战
}
local gameMgr            = app.gameMgr
local anniversary2019Mgr = app.anniversary2019Mgr
---ctor
---@param viewComponent table
function Anniversary19BattleCardMediator:ctor(param ,  viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.exploreId = param.exploreId  or  1
	self.exploreModuleId = param.exploreModuleId  or  1
end
function Anniversary19BattleCardMediator:InterestSignals()
	local signals = {
	}

	return signals
end

function Anniversary19BattleCardMediator:ProcessSignal( signal )

end
function Anniversary19BattleCardMediator:Initial( key )
	self.super.Initial(self, key)
	---@type Anniversary19BattleCardView
	local viewComponent = require("Game.views.anniversary19.Anniversary19BattleCardView").new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	app.uiMgr:GetCurrentScene():AddGameLayer(viewComponent)
	viewComponent:AddDiffView(self.exploreModuleId , self.exploreId )
	viewComponent:UpdateUI(self.exploreModuleId  , self.exploreId , nil )
	local viewData = viewComponent.viewData

	display.commonUIParams(viewData.leftButton , {cb = handler(self , self.ButtonAction)})
	viewData.leftButton:setTag(BUTTON_TAG.GIVE_UP)
	display.commonUIParams(viewData.rightButton , {cb = handler(self , self.ButtonAction)})
	viewData.rightButton:setTag(BUTTON_TAG.CHALLENGE)
end
function Anniversary19BattleCardMediator:ButtonAction(sender)
	PlayAudioByClickNormal()
	local tag = sender:getTag()
	if tag ==  BUTTON_TAG.GIVE_UP then
		local commonTip = require('common.NewCommonTip').new({
			text = app.anniversary2019Mgr:GetPoText(__('确定要放弃当前关卡吗？')) ,
			extra = app.anniversary2019Mgr:GetPoText(__('放弃当前奖励进入下一关')) ,
			callback = function()
				self:SendSignal(POST.ANNIVERSARY2_EXPLORE_SECTION_GIVE_UP.cmdName , { exploreModuleId = self.exploreModuleId })
			end
		})
		commonTip:setPosition(display.center )
		app.uiMgr:GetCurrentScene():AddDialog(commonTip)
	elseif tag == BUTTON_TAG.CHALLENGE then
		local conf = anniversary2019Mgr:GetDreamQuestTypeConfByDreamQuestType(anniversary2019Mgr.dreamQuestType.CARDS_SHUT)
		local oneConf = conf[tostring(self.exploreModuleId)][tostring(self.exploreId)]
		app.router:Dispatch({name = "HomeMediator"}, {name = "ttGame.TripleTriadGameHomeMediator",
		  params = {
			  backMdt = 'anniversary19.Anniversary19DreamCircleMainMediator' ,
			  resultSglName = ANNIVERSARY19_EXPLORE_RESULT_EVENT ,
			  battleType    = TTGAME_DEFINE.BATTLE_TYPE.ANNIVERSARY,
			  battleNpdId   = oneConf.questId,
		  }})
	end
end

function Anniversary19BattleCardMediator:OnRegist()

end
function Anniversary19BattleCardMediator:OnUnRegist()
	local viewComponent = self:GetViewComponent()
	if viewComponent and (not tolua.isnull(viewComponent)) then
		viewComponent:removeFromParent()
	end
end

return Anniversary19BattleCardMediator
