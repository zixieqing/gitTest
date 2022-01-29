--[[
 * author : liuzhipeng
 * descpt : KFC签到活动 Mediator
--]]
local Mediator = mvc.Mediator
local NAME = "ShareCV2EnterMediator"
---@class ShareCV2EnterMediator : Mediator
local ShareCV2EnterMediator = class(NAME, Mediator)
----@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
--[[
@params table{
}
--]]
function ShareCV2EnterMediator:ctor(params, viewComponent )
	self.super:ctor(NAME,viewComponent)
	local data = params or {}
	self.detail = data.activityHomeData.rule[i18n.getLang()] or ""
	self.rule = data.activityHomeData.detail[i18n.getLang()] or ""
	self.title = data.activityHomeData.title[i18n.getLang()] or ""
	self.activityId = checkint(data.activityHomeData.activityId) -- 活动Id
	self.backgroundImage = data.activityHomeData.backgroundImage[i18n.getLang()]
	self.leftSeconds = data.activityHomeData.leftSeconds
	
end

function ShareCV2EnterMediator:InterestSignals()
	local signals = {
	}
	return signals
end

function ShareCV2EnterMediator:ProcessSignal(signal)

end
function ShareCV2EnterMediator:Initial(key)
	self.super.Initial(self, key)
	local viewComponent  = require('Game.views.activity.shareCV2.ShareCV2EnterView').new({})
	display.commonUIParams(viewComponent, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
	self:SetViewComponent(viewComponent)
	local viewData_ = viewComponent.viewData_
	viewData_.compoundBtn:setOnClickScriptHandler(handler(self, self.CompoundClick))
	viewData_.cvShareBtn:setOnClickScriptHandler(handler(self, self.ShareCV2Click))
	viewComponent:UpdateRuleLable(self.rule)
	viewComponent:UpdateActivityNameLabel(self.title)
	if type(self.backgroundImage) == 'string' and  string.len(self.backgroundImage) > 0   then
		viewComponent.viewData_.bg:setWebURL(self.backgroundImage)
	end
end
---CompoundClick 前往任务拼图
---@param sender userdata
function ShareCV2EnterMediator:CompoundClick(sender)
	if self.leftSeconds <=  0  then
		app.uiMgr:ShowInformationTips(__('活动已结束'))
		return
	end
	local mediator = require("Game.mediator.activity.shareCV2.ShareCV2TaskMediator").new({detail  = self.detail ,title = self.title })
	app:RegistMediator(mediator)
end

---ShareCV2Click 前往剧情分享
---@param sender userdata
function ShareCV2EnterMediator:ShareCV2Click(sender)
	if self.leftSeconds <= 0  then
		app.uiMgr:ShowInformationTips(__('活动已结束'))
		return
	end
	local mediator = require("Game.mediator.activity.shareCV2.ShareCV2PlotMediator").new()
	app:RegistMediator(mediator)
end
function ShareCV2EnterMediator:UpdateTimeLabel()
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
						self.leftSeconds = leftSecondsShareCV2PlotMediator
						viewComponent:stopAllActions()
					end
				end)
			)
		)
	)
end

function ShareCV2EnterMediator:OnRegist()

end

function ShareCV2EnterMediator:OnUnRegist()
	local viewComponent = self:GetViewComponent()
	if viewComponent and (not tolua.isnull(viewComponent)) then
		viewComponent:stopAllActions()
	end
end
return ShareCV2EnterMediator
