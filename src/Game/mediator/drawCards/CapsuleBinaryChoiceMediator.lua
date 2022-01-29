--[[
 * author : liuzhipeng
 * descpt : 新抽卡 双抉卡池Mediator
]]
local CapsuleBinaryChoiceMediator = class('CapsuleBinaryChoiceMediator', mvc.Mediator)

local CreateView = nil
local CapsuleTenTimesView = require("Game.views.drawCards.CapsuleBinaryChoiceView")

function CapsuleBinaryChoiceMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'CapsuleBinaryChoiceMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
    self.showDrawConfirm = false -- 是否显示抽卡确认框
    self.runAction = false -- 是否播放动画
end


-------------------------------------------------
------------------ inheritance ------------------
function CapsuleBinaryChoiceMediator:Initial(key)
    self.super.Initial(self, key)

    self.ownerNode_ = self.ctorArgs_.ownerNode

    -- create view
    if self.ownerNode_ then
        local size = self.ownerNode_:getContentSize()
        local view = CapsuleTenTimesView.new({size = size})
        display.commonUIParams(view, {po = cc.p(size.width * 0.5, size.height * 0.5)})
        self.ownerNode_:addChild(view,19)
        self:SetViewComponent(view)
        local viewData = self.viewComponent.viewData
        viewData.capsuleBtn:setOnClickScriptHandler(handler(self, self.CapsuleButtonCallback))
        viewData.resetBtn:setOnClickScriptHandler(handler(self, self.ResetButtonCallback))
    end
end


function CapsuleBinaryChoiceMediator:CleanupView()
    if self.ownerNode_ then
        if self.viewComponent and self.viewComponent:getParent() then
            self.viewComponent:runAction(cc.RemoveSelf:create())
            self.viewComponent = nil
        end
        self.ownerNode_ = nil
    end
end


function CapsuleBinaryChoiceMediator:OnRegist()
    regPost(POST.GAMBLING_BINARY_CHOICE_ENTER)
    regPost(POST.GAMBLING_BINARY_CHOICE_LUCKY)
    regPost(POST.GAMBLING_BINARY_CHOICE_RESET)
end
function CapsuleBinaryChoiceMediator:OnUnRegist()
    unregPost(POST.GAMBLING_BINARY_CHOICE_ENTER)
    unregPost(POST.GAMBLING_BINARY_CHOICE_LUCKY)
    unregPost(POST.GAMBLING_BINARY_CHOICE_RESET)
end


function CapsuleBinaryChoiceMediator:InterestSignals()
    local signals = {
        POST.GAMBLING_BINARY_CHOICE_ENTER.sglName,
        POST.GAMBLING_BINARY_CHOICE_LUCKY.sglName,
        POST.GAMBLING_BINARY_CHOICE_RESET.sglName,
        CAPSULE_BINARY_CHOICE_CONFIRM,
        CAPSULE_BINARY_CHOICE_ACTION_END,
	}
	return signals
end
function CapsuleBinaryChoiceMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody()
    if name == POST.GAMBLING_BINARY_CHOICE_ENTER.sglName then
        self.runAction = true
        self:SendSignal(POST.GAMBLING_BINARY_CHOICE_HOME.cmdName, {activityId = self.homeData_.requestData.activityId})
    elseif name == POST.GAMBLING_BINARY_CHOICE_LUCKY.sglName then
        self:DrawAction(body)
    elseif name == POST.GAMBLING_BINARY_CHOICE_RESET.sglName then
        self:SendSignal(POST.GAMBLING_BINARY_CHOICE_HOME.cmdName, {activityId = self.homeData_.requestData.activityId})
    elseif name == CAPSULE_BINARY_CHOICE_CONFIRM then
        self:SendSignal(POST.GAMBLING_BINARY_CHOICE_ENTER.cmdName, {cardIds = body.cardIds, activityId = self.homeData_.requestData.activityId})
    elseif name == CAPSULE_BINARY_CHOICE_ACTION_END then
        self.runAction = false
        local capsuleNewMediator = AppFacade.GetInstance():RetrieveMediator('CapsuleNewMediator')
        if capsuleNewMediator then
            capsuleNewMediator:updatePreviewBtnShowState(true)
        end
    end
end
------------------ inheritance ------------------
-------------------------------------------------

-------------------------------------------------
-------------------- handler --------------------
function CapsuleBinaryChoiceMediator:CapsuleButtonCallback( sender )
    if  self.runAction then return end
    PlayAudioByClickNormal()
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
	    			self:SendSignal(POST.GAMBLING_BINARY_CHOICE_LUCKY.cmdName, {activityId = self.homeData_.requestData.activityId})
	    		end
	    	})
	    	tipsView:setPosition(display.center)
	    	app.uiMgr:GetCurrentScene():AddDialog(tipsView)
	    else
	    	self:SendSignal(POST.GAMBLING_BINARY_CHOICE_LUCKY.cmdName, {activityId = self.homeData_.requestData.activityId})
	    end
    else
        -- 道具不足
        app.capsuleMgr:ShowGoodsShortageTips(capsuleConsume.goodsId)
    end
end
--[[
重置按钮点击回调
--]]
function CapsuleBinaryChoiceMediator:ResetButtonCallback( sender )
    if  self.runAction then return end
    PlayAudioByClickNormal()
    if self:CheckReset() then
        self:SendSignal(POST.GAMBLING_BINARY_CHOICE_RESET.cmdName, {activityId = self.homeData_.requestData.activityId})
    else
        app.uiMgr:ShowInformationTips(__('需将四项奖励全部领取才能进行重置！'))
    end
end
-------------------- handler --------------------
-------------------------------------------------

-------------------------------------------------
------------------- get / set -------------------
--[[
获取是否要弹抽卡确认框
--]]
function CapsuleBinaryChoiceMediator:GetShowDrawConfirm()
	return self.showDrawConfirm
end
function CapsuleBinaryChoiceMediator:SetShowDrawConfirm(show)
	self.showDrawConfirm = show
end
------------------- get / set -------------------
-------------------------------------------------

-------------------------------------------------
-------------------- private --------------------
--[[
刷新页面
--]]
function CapsuleBinaryChoiceMediator:RefreshView()
    local viewComponent = self:GetViewComponent()
    if next(checktable(self.homeData_.step)) ~= nil then
        -- 抽卡界面
        local priceData = {
            consume = app.capsuleMgr:GetCapsuleConsume(self.homeData_.consume),
            discountConsume = app.capsuleMgr:GetCapsuleConsume(self.homeData_.discountConsume),
            isDiscount = self.homeData_.isDiscount
        }
        local cardId = app.capsuleMgr:GetCardIdByFragmentId(self.homeData_.step[3].rewards[1].goodsId)
        viewComponent:RefreshRoleImg(cardId)
        if self.runAction then
            -- 执行动画
            viewComponent:ChooseAction(priceData, self.homeData_.step)
            return 
        end
        viewComponent:GetViewData().bottomLayout:setVisible(true)
        viewComponent:GetViewData().resetBtn:setVisible(true)
        viewComponent:GetViewData().roleImg:setVisible(true)
        viewComponent:RefreshPrice(priceData)
        viewComponent:RefreshRewardList(self.homeData_.step)
        
    else
        viewComponent:HideUI()
        -- 选卡界面
        local capsuleNewMediator = AppFacade.GetInstance():RetrieveMediator('CapsuleNewMediator')
        if capsuleNewMediator then
            capsuleNewMediator:updatePreviewBtnShowState(false)
        end
        viewComponent:CreateChoiceView(self.homeData_.cards)
    end
    self:RefreshResetBtnState()
end
--[[
刷新重置按钮状态
--]]
function CapsuleBinaryChoiceMediator:RefreshResetBtnState()
    local viewComponent = self:GetViewComponent()
    viewComponent:RefreshResetBtnState(self:CheckReset())
end
--[[
获取当前抽卡道具消耗  
--]]
function CapsuleBinaryChoiceMediator:GetCurrentCapsuleConsume()
    if checkint(self.homeData_.isDiscount) == 1 then
        return app.capsuleMgr:GetCapsuleConsume(self.homeData_.discountConsume)
    else
        return app.capsuleMgr:GetCapsuleConsume(self.homeData_.consume)
    end
end
--[[
抽卡处理
--]]
function CapsuleBinaryChoiceMediator:DrawAction( data )
    -- 扣除道具
    local capsuleConsume = self:GetCurrentCapsuleConsume()
    CommonUtils.DrawRewards({
        {goodsId = capsuleConsume.goodsId, num = -capsuleConsume.num}
    })
    -- 奖励动画
    local mediator = require("Game.mediator.drawCards.CapsuleAnimateMediator").new(data)
    AppFacade.GetInstance():RegistMediator(mediator)
    -- 刷新请求
    self:SendSignal(POST.GAMBLING_BINARY_CHOICE_HOME.cmdName, {activityId = self.homeData_.requestData.activityId})
end
--[[
检查是否可以重置
@return canReset bool 是否可以重置
--]]
function CapsuleBinaryChoiceMediator:CheckReset()
    if next(checktable(self.homeData_.step)) == nil then return false end
    local canReset = true
    for i, v in ipairs(self.homeData_.step) do
        if checkint(v.hasDrawn) == 0 then
            canReset = false
            break
        end
    end
    return canReset
end
-------------------- private --------------------
-------------------------------------------------

-------------------------------------------------
-------------------- public ---------------------
function CapsuleBinaryChoiceMediator:resetHomeData(homeData)
    self.homeData_ = homeData
    self:RefreshView()
end
-------------------- public ---------------------
-------------------------------------------------

return CapsuleBinaryChoiceMediator
