--[[
 * author : liuzhipeng
 * descpt : 新抽卡 - 福袋抽卡
]]
local CapsuleLuckyBagMediator = class('CapsuleLuckyBagMediator', mvc.Mediator)

local CreateView = nil
local CapsuleLuckyBagView = require("Game.views.drawCards.CapsuleLuckyBagView")

function CapsuleLuckyBagMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'CapsuleLuckyBagMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
    self.showDrawConfirm = true
    display.removeUnusedSpriteFrames()
end


-------------------------------------------------
-- inheritance method

function CapsuleLuckyBagMediator:Initial(key)
    self.super.Initial(self, key)

    self.homeData_  = {}
    self.ownerNode_ = self.ctorArgs_.ownerNode

    -- create view
    if self.ownerNode_ then
        local size = self.ownerNode_:getContentSize()
        local view = CapsuleLuckyBagView.new({size = size})
        display.commonUIParams(view, {po = cc.p(size.width * 0.5, size.height * 0.5)})
        self.ownerNode_:addChild(view,19)
        self:SetViewComponent(view)
        local viewData = self.viewComponent.viewData
        viewData.drawBtn:setOnClickScriptHandler(handler(self, self.CapsuleButtonCallback))
    end
end


function CapsuleLuckyBagMediator:CleanupView()
    if self.ownerNode_ then
        if self.viewComponent and self.viewComponent:getParent() then
            self.viewComponent:runAction(cc.RemoveSelf:create())
            self.viewComponent = nil
        end
        self.ownerNode_ = nil
    end
end


function CapsuleLuckyBagMediator:OnRegist()
    regPost(POST.GAMBLING_LUCKY_BAG_PREVIEW)
end
function CapsuleLuckyBagMediator:OnUnRegist()
    unregPost(POST.GAMBLING_LUCKY_BAG_PREVIEW)
end


function CapsuleLuckyBagMediator:InterestSignals()
    local signals = {
        POST.GAMBLING_LUCKY_BAG_PREVIEW.sglName,
        CAPSULE_LUCKY_BAG_DRAW_END,
	}
	return signals
end
function CapsuleLuckyBagMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody()
    if name == POST.GAMBLING_LUCKY_BAG_PREVIEW.sglName then
        self:CapsuleDraw(body)
    elseif name == CAPSULE_LUCKY_BAG_DRAW_END then
        -- 抽卡完成
        self.homeData_.lastLuckyPreview = nil
        self.homeData_.lastLuckyRefreshTimes = nil
    end
end


-------------------------------------------------
-- handler method
function CapsuleLuckyBagMediator:CapsuleButtonCallback( sender )
    PlayAudioByClickNormal()
    if checkint(self.homeData_.hasGamblingTimes) >= checkint(self.homeData_.maxGamblingTimes) then
        app.uiMgr:ShowInformationTips(__('次数已用完'))
        return
    end
    local capsuleConsume = CommonUtils.GetCapsuleConsume(self.homeData_.consume) or {}
    if next(capsuleConsume) ~= nil and app.gameMgr:GetAmountByGoodId(capsuleConsume.goodsId) >= checkint(capsuleConsume.num) then
        -- 道具足够
        if self:GetShowDrawConfirm() then
            local goodsConf = CommonUtils.GetConfig('goods', 'goods', capsuleConsume.goodsId) or {}
            local goodsName = tostring(goodsConf.name)
	    	local tipsView  = require('common.CommonTip').new({
	    		text  = __('是否确定召唤？'),
	    		descr = string.fmt(__('本次召唤会消耗_num_个_name_'), {_name_ = goodsName, _num_ = capsuleConsume.num}),
	    		callback = function (sender)
	    			self:SetShowDrawConfirm(false)
	    			self:SendSignal(POST.GAMBLING_LUCKY_BAG_PREVIEW.cmdName, {activityId = self.homeData_.requestData.activityId})
	    		end
	    	})
	    	tipsView:setPosition(display.center)
	    	app.uiMgr:GetCurrentScene():AddDialog(tipsView)
	    else
	    	self:SendSignal(POST.GAMBLING_LUCKY_BAG_PREVIEW.cmdName, {activityId = self.homeData_.requestData.activityId})
	    end
    else
        -- 道具不足
        app.capsuleMgr:ShowGoodsShortageTips(capsuleConsume.goodsId)
    end
end

-------------------------------------------------
-- get /set
--[[
获取是否要弹抽卡确认框
--]]
function CapsuleLuckyBagMediator:GetShowDrawConfirm()
	return self.showDrawConfirm
end
function CapsuleLuckyBagMediator:SetShowDrawConfirm(show)
	self.showDrawConfirm = show
end
-------------------------------------------------
-- private method
--[[
刷新页面
--]]
function CapsuleLuckyBagMediator:RefreshView()
    local viewComponent = self:GetViewComponent()
    local hasGamblingTimes = checkint(self.homeData_.hasGamblingTimes)
    local maxGamblingTimes = checkint(self.homeData_.maxGamblingTimes)
    viewComponent:RefreshLimitTimes(hasGamblingTimes, maxGamblingTimes)
    if hasGamblingTimes >= maxGamblingTimes then
        viewComponent:RefreshSalePrize(CommonUtils.GetCapsuleConsume(self.homeData_.consume, true))
        viewComponent:SetButtonEnabled(false)
    else
        viewComponent:RefreshSalePrize(CommonUtils.GetCapsuleConsume(self.homeData_.consume, false))
        viewComponent:SetButtonEnabled(true)
    end
    viewComponent:RefreshPrize(CommonUtils.GetCapsuleConsume(self.homeData_.originalConsume))

end
--[[
奖励领取
--]]
function CapsuleLuckyBagMediator:CapsuleDraw( body )
    -- 扣除道具
    local capsuleConsume = CommonUtils.GetCapsuleConsume(self.homeData_.consume)
    CommonUtils.DrawRewards({
        {goodsId = capsuleConsume.goodsId, num = -capsuleConsume.num}
    })
    -- 更新数据
    self.homeData_.hasGamblingTimes = checkint(self.homeData_.hasGamblingTimes) + 1
    self:RefreshView(self.homeData_)
    -- 转换数据格式
    body.rewards = {}
    for i, v in ipairs(checktable(body.cards)) do
        table.insert(body.rewards, {goodsId = v.cardId, num = 1})
    end
    body.maxReplaceTimes = self.homeData_.maxReplaceTimes
    -- 奖励动画
    body.activityId = self.homeData_.requestData.activityId
    local mediator = require("Game.mediator.drawCards.CapsuleLuckyBagAnimationMediator").new(body)
    AppFacade.GetInstance():RegistMediator(mediator)
end
--[[
检测是否存在未完成的抽卡
--]]
function CapsuleLuckyBagMediator:CheckIncompleteDraw()
    local homeData = self.homeData_
    if homeData.lastLuckyPreview and next(homeData.lastLuckyPreview) ~= nil then
        -- 存在未完成的抽卡，继续上次抽卡
        local capsuleData = {}
        capsuleData.cards = homeData.lastLuckyPreview
        table.sort(capsuleData.cards, function(a, b) 
            return checkint(a.positionId) < checkint(b.positionId)
        end)
        -- 转换数据格式
        capsuleData.rewards = {}
        for i, v in ipairs(checktable(capsuleData.cards)) do
            table.insert(capsuleData.rewards, {goodsId = v.cardId, num = 1})
        end
        capsuleData.maxReplaceTimes = self.homeData_.maxReplaceTimes
        -- 奖励动画
        capsuleData.activityId = self.homeData_.requestData.activityId
        capsuleData.leftReplaceTimes = checkint(self.homeData_.maxReplaceTimes) - checkint(self.homeData_.lastLuckyRefreshTimes)
        local mediator = require("Game.mediator.drawCards.CapsuleLuckyBagAnimationMediator").new(capsuleData)
        AppFacade.GetInstance():RegistMediator(mediator)
    end
end
-------------------------------------------------
-- public method
function CapsuleLuckyBagMediator:resetHomeData(homeData)
    self.homeData_ = homeData
    -- 检测是否有未完成的抽卡
    self:CheckIncompleteDraw()
    self:RefreshView()
end


return CapsuleLuckyBagMediator
