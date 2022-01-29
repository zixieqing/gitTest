--[[
 * author : liuzhipeng
 * descpt : KFC签到活动 Mediator
--]]
local Mediator = mvc.Mediator
local NAME = "PopEnterMediator"
---@class PopEnterMediator : Mediator
local PopEnterMediator = class(NAME, Mediator)
----@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
--[[
@params table{
}
--]]
function PopEnterMediator:ctor(params, viewComponent )
	self.super:ctor(NAME,viewComponent)
	local data = params or {}
	self.detail = data.activityHomeData.rule[i18n.getLang()] or ""
	self.rule = data.activityHomeData.detail[i18n.getLang()] or ""
	self.title = data.activityHomeData.title[i18n.getLang()] or ""
	self.activityId = checkint(data.activityHomeData.activityId) -- 活动Id
	self.relatedActivityId = checkint(data.activityHomeData.relatedActivityId) -- 关联活动Id
	self.tip = checkint(data.activityHomeData.tip) -- 关联活动Id
	self.backgroundImage = data.activityHomeData.backgroundImage[i18n.getLang()]
	self.leftSeconds = data.activityHomeData.leftSeconds
	self.relatedTip = data.relatedTip -- 关联活动红点
end

function PopEnterMediator:InterestSignals()
	local signals = {
		'ACTIVITY_ALL_ROUND_CLEAR_REMIND_ICON'
	}
	return signals
end

function PopEnterMediator:ProcessSignal(signal)
	local name = signal:GetName()
    local body = signal:GetBody()
	if name == 'ACTIVITY_ALL_ROUND_CLEAR_REMIND_ICON' then
		-- 移除收集红点
		if checkint(self.relatedActivityId) == checkint(body.activityId) then
			self.relatedTip = 0
			local viewData_ = self:GetViewComponent().viewData_
			viewData_.redIconCompound:setVisible(false)
		end
    end
end
function PopEnterMediator:Initial(key)
	self.super.Initial(self, key)
	local viewComponent  = require('Game.views.link.popMain.PopEnterView').new({})
	display.commonUIParams(viewComponent, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
	self:SetViewComponent(viewComponent)
	local viewData_ = viewComponent.viewData_
	viewData_.compoundBtn:setOnClickScriptHandler(handler(self, self.CompoundClick))
	viewData_.gotoBtn:setOnClickScriptHandler(handler(self, self.GoToClick))
	if self.tip > 0 then
		viewData_.redIconPopLink:setVisible(true)
	end
	if self.relatedTip > 0 then
		viewData_.redIconCompound:setVisible(true)
	end
	viewComponent:UpdateRuleLable(self.rule)
	viewComponent:UpdateActivityNameLabel(self.title)
	if type(self.backgroundImage) == 'string' and  string.len(self.backgroundImage) > 0   then
		viewComponent.viewData_.bg:setWebURL(self.backgroundImage)
	end
end
---CompoundClick 收集
---@param sender userdata
function PopEnterMediator:CompoundClick(sender)
	PlayAudioByClickNormal()
	if self.leftSeconds <=  0  then
		app.uiMgr:ShowInformationTips(__('活动已结束'))
		return
	end
	local mediator = require('Game.mediator.activity.allRound.ActivityAllRoundMediator').new({activityId = self.relatedActivityId})
    app:RegistMediator(mediator)
end

---ShareCV2Click 前往开荒
---@param sender userdata
function PopEnterMediator:GoToClick(sender)
	if self.leftSeconds <= 0  then
		app.uiMgr:ShowInformationTips(__('活动已结束'))
		return
	end
	---@type Router
	local router = app:RetrieveMediator("Router")
	router:Dispatch({}, {name = "link.popMain.PopMainMediator" , params ={activityId = self.activityId} })
end
function PopEnterMediator:UpdateTimeLabel()
	local recordTime = os.time()
	local viewComponent = self:GetViewComponent()
	viewComponent:runAction(
			cc.RepeatForever:create(
					cc.Sequence:create(
							cc.DelayTime:create(1) ,
							cc.CallFunc:create(function()
								local currentTime = os.time()
								local leftSeconds = self.leftSeconds - (currentTime - recordTime)
								if leftSeconds >= 0 then
									viewComponent:setTimeLabel(leftSeconds)
								else
									self.leftSeconds = leftSeconds
									viewComponent:stopAllActions()
								end
							end)
					)
			)
	)
end

function PopEnterMediator:OnRegist()

end

function PopEnterMediator:OnUnRegist()
	local viewComponent = self:GetViewComponent()
	if viewComponent and (not tolua.isnull(viewComponent)) then
		viewComponent:stopAllActions()
	end
end
return PopEnterMediator
