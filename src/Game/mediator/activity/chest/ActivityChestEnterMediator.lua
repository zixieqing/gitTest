--[[
 * author : liuzhipeng
 * descpt : KFC签到活动 Mediator
--]]
local Mediator = mvc.Mediator
local NAME = "ActivityChestEnterMediator"
---@class ActivityChestEnterMediator : Mediator
local ActivityChestEnterMediator = class(NAME, Mediator)
--[[
@params table{
}
--]]
function ActivityChestEnterMediator:ctor(params, viewComponent )
	self.super:ctor(NAME,viewComponent)
	local data = params or {}
	self.detail = data.activityHomeData.rule[i18n.getLang()] or ""
	self.rule = data.activityHomeData.detail[i18n.getLang()] or ""
	self.title = data.activityHomeData.title[i18n.getLang()] or ""
	self.activityId = checkint(data.activityHomeData.activityId) -- 活动Id
	self.backgroundImage = data.activityHomeData.backgroundImage[i18n.getLang()]
	self.leftSeconds = data.activityHomeData.leftSeconds
	self.activityCountDownName = app.activityMgr:getActivityCountdownNameByType(ACTIVITY_TYPE.CHEST_ACTIVITY , self.activityId)  -- 活动的名称
end

function ActivityChestEnterMediator:InterestSignals()
	local signals = {
		self.activityCountDownName
	}
	return signals
end

function ActivityChestEnterMediator:ProcessSignal(signal)
	local body = signal:GetBody()
	local name = body:GetName()
	if name == COUNT_DOWN_ACTION then
		local timerName = body.timerName
		if self.activityCountDownName == timerName then
			local viewComponent = self:GetViewComponent()
			local countTime = body.countdown
			viewComponent:SetTimeLabel(countTime)
		end
	end
end
function ActivityChestEnterMediator:Initial(key)
	self.super.Initial(self, key)
	---@type ActivityChestEnterView
	local viewComponent  = require('Game.views.activity.chest.ActivityChestEnterView').new({})
	display.commonUIParams(viewComponent, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
	self:SetViewComponent(viewComponent)
	local viewData_ = viewComponent.viewData_
	viewData_.gotoBtn:setOnClickScriptHandler(handler(self, self.GotoActivity))
	viewComponent:UpdateRuleLable(self.rule)
	viewComponent:UpdateActivityNameLabel(self.title)
	if type(self.backgroundImage) == 'string' and  string.len(self.backgroundImage) > 0   then
		viewComponent.viewData_.bg:setWebURL(self.backgroundImage)
	end
end
---GotoActivity 前往活动
---@param sender userdata
function ActivityChestEnterMediator:GotoActivity(sender)
	if self.leftSeconds <=  0  then
		app.uiMgr:ShowInformationTips(__('活动已结束'))
		return
	end
	---@type Router
	local router =  app:RetrieveMediator("Router")
	router:Dispatch({} , { name = "activity.chest.ActivityChestMediator", params = {
			ruleDescr  = self.detail ,
			activityId  = self.activityId ,
			activityName = self.title
	}})
end

function ActivityChestEnterMediator:OnRegist()

end

function ActivityChestEnterMediator:OnUnRegist()
	local viewComponent = self:GetViewComponent()
	if viewComponent and (not tolua.isnull(viewComponent)) then
		viewComponent:stopAllActions()
	end
end
return ActivityChestEnterMediator
