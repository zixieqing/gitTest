--[[
 * author : liuzhipeng
 * descpt : 抽卡 常驻皮肤卡池Mediator
]]
local CapsuleBasicSkinMediator = class('CapsuleBasicSkinMediator', mvc.Mediator)

local CreateView = nil
local CapsuleBasicSkinView = require("Game.views.drawCards.CapsuleBasicSkinView")

function CapsuleBasicSkinMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'CapsuleBasicSkinMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
    self.showDrawConfirm = false -- 是否显示抽卡确认框
end


-------------------------------------------------
------------------ inheritance ------------------
function CapsuleBasicSkinMediator:Initial(key)
    self.super.Initial(self, key)

    self.ownerNode_ = self.ctorArgs_.ownerNode

    -- create view
    if self.ownerNode_ then
        local size = self.ownerNode_:getContentSize()
        local view = CapsuleBasicSkinView.new({size = size})
        display.commonUIParams(view, {po = cc.p(size.width * 0.5, size.height * 0.5)})
        self.ownerNode_:addChild(view,19)
        self:SetViewComponent(view)
        local viewData = self.viewComponent.viewData
        viewData.drawOnceBtn:setOnClickScriptHandler(handler(self, self.DrawOnceButtonCallback))
        viewData.drawMuchBtn:setOnClickScriptHandler(handler(self, self.DrawMuchButtonCallback))
        viewData.storeBtn:setOnClickScriptHandler(handler(self, self.StoreButtonCallback))
    end
end


function CapsuleBasicSkinMediator:CleanupView()
    if self.ownerNode_ then
        if self.viewComponent and self.viewComponent:getParent() then
            self.viewComponent:runAction(cc.RemoveSelf:create())
            self.viewComponent = nil
        end
        self.ownerNode_ = nil
    end
end


function CapsuleBasicSkinMediator:OnRegist()
    regPost(POST.GAMBLING_BASE_CARDSKIN_LUCKY)
end
function CapsuleBasicSkinMediator:OnUnRegist()
    unregPost(POST.GAMBLING_BASE_CARDSKIN_LUCKY)
end


function CapsuleBasicSkinMediator:InterestSignals()
    local signals = {
        POST.GAMBLING_BASE_CARDSKIN_LUCKY.sglName
	}
	return signals
end
function CapsuleBasicSkinMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody()
    if name == POST.GAMBLING_BASE_CARDSKIN_LUCKY.sglName then
        self:CapsuleDrawResponseHandler(body)
    end
end
------------------ inheritance ------------------
-------------------------------------------------

-------------------------------------------------
-------------------- handler --------------------
--[[
抽一次按钮点击回调
--]]
function CapsuleBasicSkinMediator:DrawOnceButtonCallback( sender )
    PlayAudioByClickNormal()
    local homeData = self.homeData_
    local capsuleConsume = homeData.oneConsume[1] or {}
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
	    			self:SendSignal(POST.GAMBLING_BASE_CARDSKIN_LUCKY.cmdName, {type = 1})
	    		end
	    	})
	    	tipsView:setPosition(display.center)
	    	app.uiMgr:GetCurrentScene():AddDialog(tipsView)
	    else
	    	self:SendSignal(POST.GAMBLING_BASE_CARDSKIN_LUCKY.cmdName, {type = 1})
	    end
    else
        -- 道具不足
        app.capsuleMgr:ShowGoodsShortageTips(capsuleConsume.goodsId)
    end
end
--[[
抽十次按钮点击回调
--]]
function CapsuleBasicSkinMediator:DrawMuchButtonCallback( sender )
    PlayAudioByClickNormal()
    local homeData = self.homeData_
    local capsuleConsume = homeData.tenConsume[1]
    if app.gameMgr:GetAmountByGoodId(capsuleConsume.goodsId) >= checkint(capsuleConsume.num) then
        -- 道具足够
        if self:GetShowDrawConfirm() then
            local goodsConf = CommonUtils.GetConfig('goods', 'goods', capsuleConsume.goodsId) or {}
            local goodsName = tostring(goodsConf.name)
	    	local tipsView  = require('common.CommonTip').new({
	    		text  = __('是否确定召唤？'),
	    		descr = string.fmt(__('本次召唤会消耗_num_个_name_'), {_name_ = goodsName, _num_ = capsuleConsume.num}),
	    		callback = function (sender)
	    			self:SetShowDrawConfirm(false)
	    			self:SendSignal(POST.GAMBLING_BASE_CARDSKIN_LUCKY.cmdName, {type = 2})
	    		end
	    	})
	    	tipsView:setPosition(display.center)
	    	app.uiMgr:GetCurrentScene():AddDialog(tipsView)
	    else
	    	self:SendSignal(POST.GAMBLING_BASE_CARDSKIN_LUCKY.cmdName, {type = 2})
	    end
    else
        -- 道具不足
        app.capsuleMgr:ShowGoodsShortageTips(capsuleConsume.goodsId)
    end
end
--[[
商城按钮点击回调
--]]
function CapsuleBasicSkinMediator:StoreButtonCallback( sender )
    PlayAudioByClickNormal()
    local capsuleBasicSkinStoreMediator  = require('Game.mediator.drawCards.CapsuleBasicSkinStoreMediator').new()
    app:RegistMediator(capsuleBasicSkinStoreMediator)
end
-------------------- handler --------------------
-------------------------------------------------

-------------------------------------------------
------------------- get / set -------------------
--[[
获取是否要弹抽卡确认框
--]]
function CapsuleBasicSkinMediator:GetShowDrawConfirm()
	return self.showDrawConfirm
end
function CapsuleBasicSkinMediator:SetShowDrawConfirm(show)
	self.showDrawConfirm = show
end
------------------- get / set -------------------
-------------------------------------------------

-------------------------------------------------
-------------------- private --------------------
--[[
刷新页面
--]]
function CapsuleBasicSkinMediator:RefreshView()
    local homeData = self.homeData_
    local viewComponent = self:GetViewComponent()
    -- 刷新抽卡消耗
    viewComponent:RefreshConsumeLabel(homeData.oneConsume[1], homeData.tenConsume[1])
    viewComponent:RefreshFirstDrawLabel(homeData.isFirst)
end
--[[
抽奖回调处理
--]]
function CapsuleBasicSkinMediator:CapsuleDrawResponseHandler( responseData )
    local homeData = self.homeData_
    local dType = checkint(responseData.requestData.type)
    local consume = nil 
    if dType == 1 then
        consume = homeData.oneConsume[1]
    elseif dType == 2 then
        consume = homeData.tenConsume[1]
        if checkint(homeData.isFirst) == 1 then
            homeData.isFirst = 0
        end
    else
        return
    end
    CommonUtils.DrawRewards({{goodsId = consume.goodsId, num = -consume.num}})

    local rewards = responseData.rewards
    if rewards then         
        self.rewardsData = responseData
        local cb = handler(self, self.ShowExRewards)
        local mediator = require("Game.mediator.drawCards.CapsuleBasicSkinAnimationMediator").new({rewards = rewards, cb = cb})
        -- local mediator = require("Game.mediator.drawCards.CapsuleSkinAnimateMediator").new({rewards = rewards, cb = cb})
        AppFacade.GetInstance():RegistMediator(mediator)
    end   
    self:RefreshView()
end
--[[
显示额外奖励（首次十连赠送和活动奖励）
--]]
function CapsuleBasicSkinMediator:ShowExRewards()
    if self:IsHasExRewards(self.rewardsData) then
        local rewards = {}
        -- 处理特别奖励 
        if self.rewardsData.extraRewards then
            for i, v in ipairs(checktable(self.rewardsData.extraRewards)) do
                table.insert(rewards, v)
            end
        end
        -- 处理活动奖励
        if self.rewardsData.activityRewards then
            for i, v in ipairs(checktable(self.rewardsData.activityRewards)) do
                table.insert(rewards, v)  
            end
        end
        app.uiMgr:AddDialog('common.RewardPopup', {rewards = rewards})
    end
end
--[[
判断是否有额外道具奖励
--]]
function CapsuleBasicSkinMediator:IsHasExRewards( rewardsData )
    if (rewardsData.activityRewards and next(rewardsData.activityRewards) ~= nil)
    or (rewardsData.extraRewards and next(rewardsData.extraRewards) ~= nil) then
        return true
    else
        return false
    end
end
-------------------- private --------------------
-------------------------------------------------

-------------------------------------------------
-------------------- public ---------------------
function CapsuleBasicSkinMediator:resetHomeData(homeData)
    self.homeData_ = homeData
    self.homeData_.oneConsume = self.homeData_.oneConsume or {}
    self.homeData_.tenConsume = self.homeData_.tenConsume or {}
    self:RefreshView()
end
-------------------- public ---------------------
-------------------------------------------------

return CapsuleBasicSkinMediator
