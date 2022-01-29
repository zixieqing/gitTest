--[[
    进阶卡池mediator
--]]
local Mediator = mvc.Mediator
local CapsuleStepMediator = class("CapsuleStepMediator", Mediator)
local NAME = "CapsuleStepMediator"

local app       = app
local uiMgr     = app.uiMgr
local gameMgr   = app.gameMgr
local cardMgr   = app.cardMgr

function CapsuleStepMediator:ctor( params, viewComponent )
    self.super.ctor(self, NAME, viewComponent)
    self.ctorArgs_ = checktable(params)
end

function CapsuleStepMediator:InterestSignals()
	local signals = {
        POST.GAMBLING_SETP_LUCKY.sglName,     
	}
	return signals
end

function CapsuleStepMediator:ProcessSignal( signal )
	local name = signal:GetName()
	local body = signal:GetBody()
    -- dump(body, name)
    if name == POST.GAMBLING_SETP_LUCKY.sglName then
		-- 抽的回调
		if self:IsSameActivity(body.requestData.activityId) then
			-- 抽卡回调
			self:SummonCallback(body)
		end
        
    end
end

function CapsuleStepMediator:Initial( key )
    self.super.Initial(self, key)
    self.ownerNode_ = self.ctorArgs_.ownerNode
    if self.ownerNode_ then

        -- create view
        local size = self.ownerNode_:getContentSize()
        local view = require("Game.views.drawCards.CapsuleStepView").new({size = size})
        display.commonUIParams(view, {po = cc.p(size.width * 0.5, size.height * 0.5)})
        self.ownerNode_:addChild(view)
        self:SetViewComponent(view)

        local viewData = view:getViewData()
        local SummonBtn = viewData.SummonBtn
        SummonBtn:setOnClickScriptHandler(handler(self, self.onClickSummonBtnAction))

    end
end

function CapsuleStepMediator:resetHomeData(homeData, activityId)
    self.datas = homeData
    self.activityId = activityId

    self.viewComponent:RefreshUI(homeData)
end

function CapsuleStepMediator:onClickSummonBtnAction(sender)
    local currentStep = math.max(checkint(self.datas.currentStep), 1)
    local step = self.datas.step[tostring(currentStep)] or self.datas.step[currentStep]
    local cost = self.viewComponent:GetCost(step)

    if self.viewComponent:IsSummonEnd(self.datas) then
        -- all the summon round clear
        uiMgr:ShowInformationTips(__('次数已用完'))
        return
    end
    if not next(step.consume or {}) then
        -- free
        self.currentConsumeInfo = {}
        self:SendSignal(POST.GAMBLING_SETP_LUCKY.cmdName, {activityId = self.activityId})
        return
    end
    self.currentConsumeInfo = step.consume[cost] or step.consume[1] or {}
    if CommonUtils.GetCacheProductNum(self.currentConsumeInfo.goodsId) >= tonumber(self.currentConsumeInfo.num) then
        self:SendSignal(POST.GAMBLING_SETP_LUCKY.cmdName, {activityId = self.activityId})
    else
        app.capsuleMgr:ShowGoodsShortageTips(self.currentConsumeInfo.goodsId)
    end
end

function CapsuleStepMediator:IsSameActivity(targetActivityId)
	return checkint(targetActivityId) == checkint(self.activityId)
end

function CapsuleStepMediator:SummonCallback(responseData)
	local poolId = checkint(responseData.requestData and responseData.requestData.poolId)
	------------ 扣除消耗 ------------
    local consumeInfo = self.currentConsumeInfo or {}
	if next(consumeInfo) then
		local costGoodsId = checkint(consumeInfo.goodsId)
		local costGoodsAmount = checknumber(consumeInfo.num)
		CommonUtils.DrawRewards({
			{goodsId = costGoodsId, num = -1 * costGoodsAmount}
		})
		self:GetFacade():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI)
	end
	------------ 扣除消耗 ------------

	-- 奖励动画
    local mediator = require("Game.mediator.drawCards.CapsuleAnimateMediator").new(responseData)
    AppFacade.GetInstance():RegistMediator(mediator)

    local currentStep = math.max(checkint(self.datas.currentStep), 1) + 1
    local CurrentRound = math.max(checkint(self.datas.currentRound), 1)
    if 6 < currentStep then
        currentStep = 1
        CurrentRound = CurrentRound + 1
    end
    self.datas.currentStep = currentStep
    self.datas.currentRound = CurrentRound
    self.viewComponent:RefreshUI(self.datas)
end

function CapsuleStepMediator:OnRegist()
    regPost(POST.GAMBLING_SETP_LUCKY)
end

function CapsuleStepMediator:OnUnRegist()
    unregPost(POST.GAMBLING_SETP_LUCKY)
end

function CapsuleStepMediator:CleanupView()
	if self:GetViewComponent() then
		self:GetViewComponent():stopAllActions()
		self:GetViewComponent():runAction(cc.RemoveSelf:create())
		self:SetViewComponent(nil)
	end
end

return CapsuleStepMediator
