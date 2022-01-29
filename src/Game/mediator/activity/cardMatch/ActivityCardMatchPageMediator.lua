--[[
飨灵投票初赛入口mediator
--]]
local Mediator = mvc.Mediator
local ActivityCardMatchPageMediator = class("ActivityCardMatchPageMediator", Mediator)
local NAME = "activity.cardMatch.ActivityCardMatchPageMediator"

local app = app
local uiMgr = app.uiMgr

function ActivityCardMatchPageMediator:ctor( params, viewComponent )
	self.super:ctor(NAME, viewComponent)
	local datas = params or {}
	self.activityId      = checkint(datas.activityId) -- 活动Id
	self.activityDatas   = datas.activityData or {}   -- 活动home数据
	self.datas           = nil                        -- FOOD_VOTE_INFO data
	self.isControllable_ = true
	self.isTimeEnd       = false
	
end


function ActivityCardMatchPageMediator:InterestSignals()
	local signals = {
		POST.FOOD_VOTE_INFO.sglName,
		POST.FOOD_VOTE_PICK.sglName,
		SGL.CACHE_MONEY_UPDATE_UI,
		SGL.REFRESH_NOT_CLOSE_GOODS_EVENT,
		COUNT_DOWN_ACTION
	}
	return signals
end

function ActivityCardMatchPageMediator:ProcessSignal( signal )
	local name = signal:GetName()
	local body = checktable(signal:GetBody())
	if name == POST.FOOD_VOTE_INFO.sglName then

		self.datas = body

		local viewData      = self:GetViewData()
		local viewComponent = self:GetViewComponent()
		viewComponent:UpdateReceiveBtn(viewData, body)
		viewComponent:UpdateGoodNode(viewData, body)

	elseif name == POST.FOOD_VOTE_PICK.sglName then
		self.datas.hasPicked = 1

		local rewards = {{goodsId = self.datas.voteGoodsId, num = self.datas.voteDailyGet}}
		uiMgr:AddDialog('common.RewardPopup', {rewards = rewards})

		self:GetViewComponent():UpdateReceiveBtn(self:GetViewData(), self.datas)

	elseif name == COUNT_DOWN_ACTION then
		local timerName = body.timerName
		if timerName == NAME then
			local countdown = body.countdown
			if countdown <= 0 then
				self.isTimeEnd = true
			end
			self:GetViewComponent():UpdateCountDown(countdown)
		end
	end
end

function ActivityCardMatchPageMediator:Initial( key )
    self.super.Initial(self, key)
    
	local viewComponent = require( 'Game.views.activity.cardMatch.ActivityCardMatchPageView' ).new(self.activityDatas)
	display.commonUIParams(viewComponent, {ap = display.CENTER, po = display.center})
	self:SetViewComponent(viewComponent)

	self.viewData_ = viewComponent:GetViewData()
	self:InitView_()
end

function ActivityCardMatchPageMediator:CleanupView()
	local viewComponent = self:GetViewComponent()

	local scene = uiMgr:GetCurrentScene()
    if scene and viewComponent and not tolua.isnull(viewComponent) then
		scene:RemoveGameLayer(viewComponent)
    end
end

function ActivityCardMatchPageMediator:OnRegist(  )
	regPost(POST.FOOD_VOTE_INFO)
	regPost(POST.FOOD_VOTE_PICK)
	self:EnterLayer()
	self:AddTimer_(self.activityDatas.leftSeconds)
end

function ActivityCardMatchPageMediator:OnUnRegist(  )
	self:StopTimer_()
	unregPost(POST.FOOD_VOTE_INFO)
	unregPost(POST.FOOD_VOTE_PICK)
end

function ActivityCardMatchPageMediator:InitView_()
	local viewData = self:GetViewData()
	
	display.commonUIParams(viewData.enterBtn, {cb = handler(self, self.OnClickEnterBtnAction)})
	display.commonUIParams(viewData.receiveBtn, {cb = handler(self, self.OnClickReceiveBtnAction)})

end

---AddTimer_
---添加倒计时
---@param leftTime number 剩余时间
function ActivityCardMatchPageMediator:AddTimer_(leftTime)
	app.activityMgr:createCountdownTemplate(checkint(leftTime) + 10, NAME) 
end
function ActivityCardMatchPageMediator:StopTimer_()
	app.activityMgr:stopCountdown(NAME)
end

function ActivityCardMatchPageMediator:EnterLayer()
	self:SendSignal(POST.FOOD_VOTE_INFO.cmdName, {activityId = self.activityId})
end

function ActivityCardMatchPageMediator:OnClickRuleBtnAction()
	app.uiMgr:ShowIntroPopup({moduleId = -29})
end

---OnClickEnterBtnAction
---投票入口按钮点击事件
function ActivityCardMatchPageMediator:OnClickEnterBtnAction()
	local mediator = require('Game.mediator.activity.cardMatch.ActivityCardMatchVoteMediator').new(self.datas)
	app:RegistMediator(mediator)
end

function ActivityCardMatchPageMediator:OnClickReceiveBtnAction(sender)
	local data = self.datas
	local isReceive = checkint(data.hasPicked) > 0

	if isReceive then
		uiMgr:ShowInformationTips(__('已领取'))
		return
	end

	self:SendSignal(POST.FOOD_VOTE_PICK.cmdName, {activityId = self.activityId})
end

function ActivityCardMatchPageMediator:GetViewData()
	return self.viewData_
end

return ActivityCardMatchPageMediator