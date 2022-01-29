--[[
 * author : liuzhipeng
 * descpt : 新抽卡 - 限购抽卡
]]
local CapsuleLimitMediator = class('CapsuleLimitMediator', mvc.Mediator)

local CreateView = nil
local CapsuleLimitView = require("Game.views.drawCards.CapsuleLimitView")

function CapsuleLimitMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'CapsuleLimitMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
    self.showDrawConfirm = true
end


-------------------------------------------------
-- inheritance method

function CapsuleLimitMediator:Initial(key)
    self.super.Initial(self, key)

    self.ownerNode_ = self.ctorArgs_.ownerNode

    -- create view
    if self.ownerNode_ then
        local size = self.ownerNode_:getContentSize()
        local view = CapsuleLimitView.new({size = size})
        display.commonUIParams(view, {po = cc.p(size.width * 0.5, size.height * 0.5)})
        self.ownerNode_:addChild(view,19)
        self:SetViewComponent(view)
        local viewData = self.viewComponent.viewData
        viewData.drawBtn:setOnClickScriptHandler(handler(self, self.CapsuleButtonCallback))
    end
end


function CapsuleLimitMediator:CleanupView()
    if self.ownerNode_ then
        if self.viewComponent and self.viewComponent:getParent() then
            self.viewComponent:runAction(cc.RemoveSelf:create())
            self.viewComponent = nil
        end
        self.ownerNode_ = nil
    end
end


function CapsuleLimitMediator:OnRegist()
    regPost(POST.GAMBLING_LIMIT_LUCKY)
end
function CapsuleLimitMediator:OnUnRegist()
    unregPost(POST.GAMBLING_LIMIT_LUCKY)
end


function CapsuleLimitMediator:InterestSignals()
    local signals = {
        POST.GAMBLING_LIMIT_LUCKY.sglName,
	}
	return signals
end
function CapsuleLimitMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody()
    if name == POST.GAMBLING_LIMIT_LUCKY.sglName then
		AppFacade.GetInstance():DispatchObservers("DOT_LOG_EVENT_SEND" , {eventId = "1004-M2-01"})
        self:CapsuleDraw(body)
    end
end


-------------------------------------------------
-- handler method
function CapsuleLimitMediator:CapsuleButtonCallback( sender )
    PlayAudioByClickNormal()
    if not self.homeData_ then return end
    local capsuleConsume = CommonUtils.GetCapsuleConsume(self.homeData_.consume) or {}
    if checkint(self.homeData_.hasGamblingTimes) >= checkint(self.homeData_.maxGamblingTimes) then
        app.uiMgr:ShowInformationTips(__('次数已用完'))
        return
    end
    if next(capsuleConsume) ~= nil and app.gameMgr:GetAmountByGoodId(capsuleConsume.goodsId) >= checkint(capsuleConsume.num) then
        -- 道具足够
        if self:GetShowDrawConfirm() then
            if isJapanSdk() and tonumber(capsuleConsume.goodsId) == PAID_DIAMOND_ID then
                self:ShotComfirmPopup({type = 10, consumeNum = capsuleConsume.num, showNoMore = true}, function (noMore)
                    self.noMore = noMore
                    self:SendSignal(POST.GAMBLING_LIMIT_LUCKY.cmdName, {activityId = self.homeData_.requestData.activityId})
                end)
                return
            end
            local goodsConf = CommonUtils.GetConfig('goods', 'goods', capsuleConsume.goodsId) or {}
            local goodsName = tostring(goodsConf.name)
	    	local tipsView  = require('common.CommonTip').new({
	    		text  = __('是否确定召唤？'),
	    		descr = string.fmt(__('本次召唤会消耗_num_个_name_'), {_name_ = goodsName, _num_ = capsuleConsume.num}),
	    		callback = function (sender)
	    			self:SetShowDrawConfirm(false)
	    			self:SendSignal(POST.GAMBLING_LIMIT_LUCKY.cmdName, {activityId = self.homeData_.requestData.activityId})
	    		end
	    	})
	    	tipsView:setPosition(display.center)
	    	app.uiMgr:GetCurrentScene():AddDialog(tipsView)
	    else
	    	self:SendSignal(POST.GAMBLING_LIMIT_LUCKY.cmdName, {activityId = self.homeData_.requestData.activityId})
	    end
    else
        -- 道具不足
        if isJapanSdk() and tonumber(capsuleConsume.goodsId) == PAID_DIAMOND_ID then
            self:ShotComfirmPopup({type = 10, consumeNum = capsuleConsume.num})
        else
            app.capsuleMgr:ShowGoodsShortageTips(capsuleConsume.goodsId)
        end
    end
end

--[[
--抽卡二次确认框
--]]
function CapsuleLimitMediator:ShotComfirmPopup( data, cb )
    local scene = app.uiMgr:GetCurrentScene()
    local DiamondLuckyDrawPopup  = require('Game.views.DiamondLuckyDrawPopup').new({tag = 5001, mediatorName = "CapsuleNewPlayerMediator", data = data, cb = function ()
        if cb then
            cb()
        end
    end})
    display.commonUIParams(DiamondLuckyDrawPopup, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
    DiamondLuckyDrawPopup:setTag(5001)
    scene:AddDialog(DiamondLuckyDrawPopup)
end
-------------------------------------------------
-- get /set
--[[
获取是否要弹抽卡确认框
--]]
function CapsuleLimitMediator:GetShowDrawConfirm()
    if isJapanSdk() then
        return false
    end
	return self.showDrawConfirm and not self.noMore
end
function CapsuleLimitMediator:SetShowDrawConfirm(show)
	self.showDrawConfirm = show
end
-------------------------------------------------
-- private method
--[[
刷新页面
--]]
function CapsuleLimitMediator:RefreshView()
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
function CapsuleLimitMediator:CapsuleDraw( body )
    -- 扣除道具
    local capsuleConsume = CommonUtils.GetCapsuleConsume(self.homeData_.consume)
    CommonUtils.DrawRewards({
        {goodsId = capsuleConsume.goodsId, num = -capsuleConsume.num}
    })
    -- 更新数据
    self.homeData_.hasGamblingTimes = checkint(self.homeData_.hasGamblingTimes) + 1
    self:RefreshView(self.homeData_)
    -- 奖励动画
    local mediator = require("Game.mediator.drawCards.CapsuleAnimateMediator").new(body)
    AppFacade.GetInstance():RegistMediator(mediator)
end
-------------------------------------------------
-- public method
function CapsuleLimitMediator:resetHomeData(homeData)
    self.homeData_ = homeData
    self:RefreshView()
end


return CapsuleLimitMediator
