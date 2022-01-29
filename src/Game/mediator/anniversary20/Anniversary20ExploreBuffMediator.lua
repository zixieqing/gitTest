--[[
扭蛋系统mediator
--]]
local Mediator = mvc.Mediator
---@class Anniversary20ExploreBuffMediator :Mediator
local Anniversary20ExploreBuffMediator = class("Anniversary20ExploreBuffMediator", Mediator)
local NAME = "Anniversary20ExploreBuffMediator"
local BUTTON_TAG = {
	CONTINUE  = 1001, --继续
	CHALLENGE = 1002, --打开
}
---ctor
---@param param table @{ mapGridId : int}
---@param viewComponent table
function Anniversary20ExploreBuffMediator:ctor(param ,  viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.mapGridId = param.mapGridId
	self.selectTag = nil
	self.isPassed = nil
	self.playerCardId = nil

end
function Anniversary20ExploreBuffMediator:InterestSignals()
	local signals = {
		"ANNIVERSARY_2020_EXPLORE_STEP_CLOSE_EVENT" ,
		POST.ANNIV2020_EXPLORE_BUFF.sglName
	}
	return signals
end

function Anniversary20ExploreBuffMediator:ProcessSignal( signal )
	local data = signal:GetBody()
	local name = signal:GetName()
	if name == "ANNIVERSARY_2020_EXPLORE_STEP_CLOSE_EVENT" then
		self:CloseMeditor()
	elseif name == POST.ANNIV2020_EXPLORE_BUFF.sglName then
		self.isPassed = 1
		self.playerCardId = checkint(data.playerCardId)
	end
end
function Anniversary20ExploreBuffMediator:Initial( key )
	self.super.Initial(self, key)
	---@type Anniversary20ExploreMonsterView
	local viewComponent = require("Game.views.anniversary20.Anniversary20ExploreBuffView").new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	app.uiMgr:GetCurrentScene():AddGameLayer(viewComponent)
	viewComponent:AddDiffView(self.mapGridId )
	viewComponent:UpdateUI(self.mapGridId)
	local viewData = viewComponent.viewData
	display.commonUIParams(viewData.leftButton , {cb = handler(self , self.ButtonAction)})
	viewData.leftButton:setTag(BUTTON_TAG.CONTINUE)
	display.commonUIParams(viewData.rightButton , {cb = handler(self , self.ButtonAction)})
	viewData.rightButton:setTag(BUTTON_TAG.CHALLENGE)

end
function Anniversary20ExploreBuffMediator:ButtonAction(sender)
	PlayAudioByClickNormal()
	local tag = sender:getTag()
	if self.selectTag == tag then
		return
	end
	if tag == BUTTON_TAG.CHALLENGE then
		---@type Anniversary20ExploreBuffView
		local viewComponent = self:GetViewComponent()
		local viewData = viewComponent.viewData
		local spineNode =  viewData.centerLayout:getChildByName("spineNode")
		local refId = app.anniv2020Mgr:getExploreingMapRefIdAt(self.mapGridId)
		local buffConf =  CONF.ANNIV2020.EXPLORE_BUFF:GetValue(refId)
		local skillType = checkint(buffConf.type)
		local indexTable = {2,1}
		if spineNode then
			local spinecallBack = function (event)
				if event.animation ==   "play" .. indexTable[skillType] then
					spineNode:setAnimation(0 , "play" ..indexTable[skillType] + 2  , false)
					---@type Anniversary20ExploreBuffView
					local viewComponent = self:GetViewComponent()
					viewComponent:SetOnlyLeftOneBtn()
					local viewData = viewComponent.viewData
					display.commonLabelParams(viewData.leftButton , fontWithColor(14,{text = __('继续')}))
					viewComponent:runAction(
						cc.Sequence:create(
							cc.CallFunc:create(function()
								local ANNIV2020 = FOOD.ANNIV2020
								if checkint(refId) == ANNIV2020.EXPLORE_BUFF_TYPE.WEAK_OF_DEAD then
									if checkint(self.playerCardId) > 0 then
										local cardData = app.gameMgr:GetCardDataById(self.playerCardId)
										local cardId = cardData.cardId
										local cardConf = CommonUtils.GetConfigAllMess("card" , 'card')
										local name = cardConf[tostring(cardId)].name
										local HP = ANNIV2020.TEAM_STATE.HP
										if (cardData[HP] and tonumber(cardData[HP]) > 0) or (not cardData[HP]) then
											viewComponent:UpdateBuffLabel(string.fmt(__("卡牌_name_血量回满"),{_name_ = name}))
										else
											viewComponent:UpdateBuffLabel(string.fmt(__("卡牌_name__descr_"),{_name_ = name ,_descr_ =  buffConf.descr}))
										end
									else
										viewComponent:UpdateBuffLabel(__('暂无复活卡牌'))
									end
								else
									viewComponent:UpdateBuffLabel(buffConf.descr)
								end
							end)
						)
					)

				elseif event.animation == "play" .. indexTable[skillType] + 2 then

				end
			end
			spineNode:registerSpineEventHandler(spinecallBack, sp.EventType.ANIMATION_COMPLETE)
			spineNode:setAnimation(0 , "play" ..indexTable[skillType]  , false)
			self:SendSignal(POST.ANNIV2020_EXPLORE_BUFF.cmdName , {  gridId = self.mapGridId})
		end
		self.selectTag = tag
	elseif tag == BUTTON_TAG.CONTINUE then
		if self.isPassed then
			self:CloseMeditor()
		else
			self.selectTag = tag
		end
	end
end

function Anniversary20ExploreBuffMediator:CloseMeditor()
	if self.isPassed then
		self:GetFacade():UnRegistMediator(NAME)
		self:GetFacade():DispatchObservers(ANNIVERSARY20_EXPLORE_RESULT_EVENT, {
			mapGridId  = self.mapGridId  , isPassed  = self.isPassed  , playerCardId = checkint(self.playerCardId)
		})
	else
		self:GetFacade():UnRegistMediator(NAME)
	end
end

function Anniversary20ExploreBuffMediator:OnRegist()
	regPost(POST.ANNIV2020_EXPLORE_BUFF)
end
function Anniversary20ExploreBuffMediator:OnUnRegist()
	unregPost(POST.ANNIV2020_EXPLORE_BUFF)
	local viewComponent = self:GetViewComponent()
	if viewComponent and (not tolua.isnull(viewComponent)) then
		viewComponent:removeFromParent()
	end
end

return Anniversary20ExploreBuffMediator
