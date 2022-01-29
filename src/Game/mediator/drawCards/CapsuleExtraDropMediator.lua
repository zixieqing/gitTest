--[[
 * author : liuzhipeng
 * descpt : 新抽卡 - 十连送道具抽卡
]]
local CapsuleExtraDropMediator = class('CapsuleExtraDropMediator', mvc.Mediator)

local CreateView = nil
local CapsuleExtraDropView = require("Game.views.drawCards.CapsuleExtraDropView")

function CapsuleExtraDropMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'CapsuleExtraDropMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
    self.showDrawConfirm = true
end


-------------------------------------------------
-- inheritance method

function CapsuleExtraDropMediator:Initial(key)
    self.super.Initial(self, key)

    self.homeData_  = {}
    self.ownerNode_ = self.ctorArgs_.ownerNode

    -- create view
    if self.ownerNode_ then
        local size = self.ownerNode_:getContentSize()
        local view = CapsuleExtraDropView.new({size = size})
        display.commonUIParams(view, {po = cc.p(size.width * 0.5, size.height * 0.5)})
        self.ownerNode_:addChild(view,19)
        self:SetViewComponent(view)
        local viewData = self.viewComponent.viewData
        viewData.drawOneBtn:setOnClickScriptHandler(handler(self, self.CapsuleButtonCallback))
        viewData.drawTenBtn:setOnClickScriptHandler(handler(self, self.CapsuleButtonCallback))
    end
end


function CapsuleExtraDropMediator:CleanupView()
    if self.ownerNode_ then
        if self.viewComponent and self.viewComponent:getParent() then
            self.viewComponent:runAction(cc.RemoveSelf:create())
            self.viewComponent = nil
        end
        self.ownerNode_ = nil
    end
end


function CapsuleExtraDropMediator:OnRegist()
    regPost(POST.GAMBLING_EXTRA_DROP_LUCKY)
end
function CapsuleExtraDropMediator:OnUnRegist()
    unregPost(POST.GAMBLING_EXTRA_DROP_LUCKY)
end


function CapsuleExtraDropMediator:InterestSignals()
    local signals = {
        POST.GAMBLING_EXTRA_DROP_LUCKY.sglName,
	}
	return signals
end
function CapsuleExtraDropMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody()
    if name == POST.GAMBLING_EXTRA_DROP_LUCKY.sglName then
        self:CapsuleDraw(body)
    end
end


-------------------------------------------------
-- handler method
function CapsuleExtraDropMediator:CapsuleButtonCallback( sender )
    PlayAudioByClickNormal()
    local tag = sender:getTag()
    local consumeList = {}
    if tag == 1 then
        consumeList = self.homeData_.oneConsume
    elseif tag == 2 then
        consumeList = self.homeData_.tenConsume
    end
    local capsuleConsume = CommonUtils.GetCapsuleConsume(consumeList) or {}
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
	    			self:SendSignal(POST.GAMBLING_EXTRA_DROP_LUCKY.cmdName, {activityId = self.homeData_.requestData.activityId, type = tag})
	    		end
	    	})
	    	tipsView:setPosition(display.center)
	    	app.uiMgr:GetCurrentScene():AddDialog(tipsView)
	    else
	    	self:SendSignal(POST.GAMBLING_EXTRA_DROP_LUCKY.cmdName, {activityId = self.homeData_.requestData.activityId, type = tag})
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
function CapsuleExtraDropMediator:GetShowDrawConfirm()
    if isJapanSdk() then
        return false
    end
	return self.showDrawConfirm
end
function CapsuleExtraDropMediator:SetShowDrawConfirm(show)
	self.showDrawConfirm = show
end
-------------------------------------------------
-- private method
--[[
奖励领取
--]]
function CapsuleExtraDropMediator:CapsuleDraw( body )
    -- 扣除道具
    if body.requestData.type == 1 then 
        local capsuleConsume = CommonUtils.GetCapsuleConsume(self.homeData_.oneConsume)
        CommonUtils.DrawRewards({
            {goodsId = capsuleConsume.goodsId, num = -capsuleConsume.num}
        })
    elseif body.requestData.type == 2 then
        local capsuleConsume = CommonUtils.GetCapsuleConsume(self.homeData_.tenConsume)
        CommonUtils.DrawRewards({
            {goodsId = capsuleConsume.goodsId, num = -capsuleConsume.num}
        })
    end
    -- 更新数据
    if body.requestData.type == 2 and checkint(self.homeData_.tenTimes) > 0 then
        self.homeData_.tenTimesGamblingTimes = checkint(self.homeData_.tenTimesGamblingTimes) + 1
    end
    self:GetViewComponent():RefreshView(self.homeData_)
    -- 奖励动画
    local mediator = require("Game.mediator.drawCards.CapsuleAnimateMediator").new(body)
    AppFacade.GetInstance():RegistMediator(mediator)
end
-------------------------------------------------
-- public method
function CapsuleExtraDropMediator:resetHomeData(homeData)
    self.homeData_ = homeData
    self:GetViewComponent():RefreshView(homeData)
end


return CapsuleExtraDropMediator
