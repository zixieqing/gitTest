--[[
 * author : liuzhipeng
 * descpt : 新抽卡 - 十连抽卡
]]
local CapsuleTenTimesMediator = class('CapsuleTenTimesMediator', mvc.Mediator)

local CreateView = nil
local CapsuleTenTimesView = require("Game.views.drawCards.CapsuleTenTimesView")

function CapsuleTenTimesMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'CapsuleTenTimesMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
    self.showDrawConfirm = false -- 是否显示抽卡确认框
end


-------------------------------------------------
-- inheritance method

function CapsuleTenTimesMediator:Initial(key)
    self.super.Initial(self, key)

    self.ownerNode_ = self.ctorArgs_.ownerNode
    self.homeData_  = {}

    -- create view
    if self.ownerNode_ then
        local size = self.ownerNode_:getContentSize()
        local view = CapsuleTenTimesView.new({size = size})
        display.commonUIParams(view, {po = cc.p(size.width * 0.5, size.height * 0.5)})
        self.ownerNode_:addChild(view,19)
        self:SetViewComponent(view)
        local viewData = self.viewComponent.viewData
        viewData.capsuleBtn:setOnClickScriptHandler(handler(self, self.CapsuleButtonCallback))
    end
end


function CapsuleTenTimesMediator:CleanupView()
    if self.ownerNode_ then
        if self.viewComponent and self.viewComponent:getParent() then
            self.viewComponent:runAction(cc.RemoveSelf:create())
            self.viewComponent = nil
        end
        self.ownerNode_ = nil
    end
end


function CapsuleTenTimesMediator:OnRegist()
    regPost(POST.GAMBLING_TEN_LUCKY)
end
function CapsuleTenTimesMediator:OnUnRegist()
    unregPost(POST.GAMBLING_TEN_LUCKY)
end


function CapsuleTenTimesMediator:InterestSignals()
    local signals = {
        POST.GAMBLING_TEN_LUCKY.sglName,
	}
	return signals
end
function CapsuleTenTimesMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody()
    if name == POST.GAMBLING_TEN_LUCKY.sglName then
        AppFacade.GetInstance():DispatchObservers("DOT_LOG_EVENT_SEND" , {eventId = "1004-M3-01"})
        self:DrawAction(body)
    end
end


-------------------------------------------------
-- handler method
function CapsuleTenTimesMediator:CapsuleButtonCallback( sender )
    PlayAudioByClickNormal()
    if not self.homeData_ then return end
    local capsuleConsume = self:GetCurrentCapsuleConsume() or {}
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
	    			self:SendSignal(POST.GAMBLING_TEN_LUCKY.cmdName, {activityId = self.homeData_.requestData.activityId})
	    		end
	    	})
	    	tipsView:setPosition(display.center)
	    	app.uiMgr:GetCurrentScene():AddDialog(tipsView)
	    else
	    	self:SendSignal(POST.GAMBLING_TEN_LUCKY.cmdName, {activityId = self.homeData_.requestData.activityId})
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
function CapsuleTenTimesMediator:GetShowDrawConfirm()
	return self.showDrawConfirm
end
function CapsuleTenTimesMediator:SetShowDrawConfirm(show)
	self.showDrawConfirm = show
end
-------------------------------------------------
-- private method
--[[
刷新页面
--]]
function CapsuleTenTimesMediator:RefreshView()
    local priceData = {
        consume = self:GetCapsuleConsume(self.homeData_.consume),
        discountConsume = self:GetCapsuleConsume(self.homeData_.discountConsume),
        isDiscount = self.homeData_.isDiscount
    }
    self:GetViewComponent():RefreshPrice(priceData)
    self:GetViewComponent():RefreshRewardList(self.homeData_.step)
end
--[[
获取展示的抽卡道具消耗
@params consume list 抽卡消耗 {
    goodsId int 道具id
    num     int 道具数量
}
--]]
function CapsuleTenTimesMediator:GetCapsuleConsume( consume )
    if not consume or next(consume) == nil then return end
    local capsuleConsume = {}
    for i, v in ipairs(consume) do
        if i == #consume then
            capsuleConsume = v
            break
        else
            if app.gameMgr:GetAmountByGoodId(v.goodsId) >= checkint(v.num) then
                capsuleConsume = v
                break
            end
        end
    end
    return capsuleConsume
end
--[[
获取当前抽卡道具消耗  
--]]
function CapsuleTenTimesMediator:GetCurrentCapsuleConsume()
    if checkint(self.homeData_.isDiscount) == 1 then
        return self:GetCapsuleConsume(self.homeData_.discountConsume)
    else
        return self:GetCapsuleConsume(self.homeData_.consume)
    end
end
--[[
抽卡处理
--]]
function CapsuleTenTimesMediator:DrawAction( data )
    -- 扣除道具
    local capsuleConsume = self:GetCurrentCapsuleConsume()
    CommonUtils.DrawRewards({
        {goodsId = capsuleConsume.goodsId, num = -capsuleConsume.num}
    })
    -- 奖励动画
    local mediator = require("Game.mediator.drawCards.CapsuleAnimateMediator").new(data)
    AppFacade.GetInstance():RegistMediator(mediator)
    -- 刷新请求
    self:SendSignal(POST.GAMBLING_TEN_ENTER.cmdName, {activityId = self.homeData_.requestData.activityId})
end
-------------------------------------------------
-- public method

function CapsuleTenTimesMediator:resetHomeData(homeData)
    self.homeData_ = checktable(homeData)
    self:RefreshView()
end


return CapsuleTenTimesMediator
