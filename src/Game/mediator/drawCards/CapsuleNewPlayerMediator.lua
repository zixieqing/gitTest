--[[
扭蛋系统mediator
--]]
local Mediator = mvc.Mediator
local CapsuleNewPlayerMediator = class("CapsuleNewPlayerMediator", Mediator)
local NAME = "CapsuleNewPlayerMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")

local CapsuleNewPlayerView = require("Game.views.drawCards.CapsuleNewPlayerView")

function CapsuleNewPlayerMediator:ctor( params, viewComponent )
    self.super.ctor(self, NAME, viewComponent)
    self.ctorArgs_ = checktable(params)
end

function CapsuleNewPlayerMediator:InterestSignals()
	local signals = {
        POST.GAMBLING_NEWBIE_LUCKY.sglName,
        POST.GAMBLING_NEWBIE_FINAL_DRAW.sglName,
	}
	return signals
end

function CapsuleNewPlayerMediator:ProcessSignal( signal )
	local name = signal:GetName()
	local body = signal:GetBody()
	-- dump(body, name)
	if name == POST.GAMBLING_NEWBIE_LUCKY.sglName then
        --抽卡请求的结果
        --添加总钻石数量的处理逻辑
        -- 不在这里处理
        --if body.diamond then
        --    gameMgr:UpdatePlayer({diamond = checkint(body.diamond)})
        --    AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI, { diamond = gameMgr:GetUserInfo().diamond })
        --end
        self:UpdateDrawcardInfo(body)
	    local mediator = require("Game.mediator.drawCards.CapsuleAnimateMediator").new(body)
	    AppFacade.GetInstance():RegistMediator(mediator)
    elseif name == POST.GAMBLING_NEWBIE_FINAL_DRAW.sglName then
        --领取奖励的请求结果
        local rewards = body.rewards
        self.datas.finalRewardsHasDrawn = 1
        if rewards then
            --弹奖励
            CommonUtils.DrawRewards(rewards)
            uiMgr:AddDialog('common.RewardPopup', {rewards = rewards, addBackpack = false})
        end
        local scene = uiMgr:GetCurrentScene()
        scene:RemoveDialogByTag(5555)
    end
end

function CapsuleNewPlayerMediator:Initial( key )
    self.super.Initial(self, key)
    self.ownerNode_ = self.ctorArgs_.ownerNode
    -- create view
    if self.ownerNode_ then
        local size = self.ownerNode_:getContentSize()
        local view = CapsuleNewPlayerView.new({size = size})
        display.commonUIParams(view, {po = cc.p(size.width * 0.5, size.height * 0.5)})
        self.ownerNode_:addChild(view,19)
        self:SetViewComponent(view)
        local viewData = self.viewComponent.viewData
        viewData.bgGrowButton:setOnClickScriptHandler(handler(self, self.OpenDrawRewardAction))
        -- viewData.oneshotButton:SetClick(handler(self, self.OneShotAction))
        viewData.tenShotButton:SetClick(handler(self, self.TenShotAction))
    end
end

-------------------------------------------------
-- public method

function CapsuleNewPlayerMediator:resetHomeData(homeData)
    self.datas = homeData
    local viewData = self.viewComponent.viewData
    viewData.rightView:setVisible(true)
    viewData.bottomView:setVisible(true)
    self:CheckMaxGamblingTimes(self.datas.gamblingTimes)
    --看是否可领取状态页面更新
    if checkint(self.datas.gamblingTimes) < checkint(self.datas.maxGamblingTimes) then
        self:FreshUI()
    end
end


function CapsuleNewPlayerMediator:OpenDrawRewardAction(sender)
    PlayAudioByClickNormal()
    if checkint(self.datas.gamblingTimes) >= checkint(self.datas.maxGamblingTimes) then
        if checkint(self.datas.finalRewardsHasDrawn) == 0 then
            local scene = uiMgr:GetCurrentScene()
            local rewardPanel = require("Game.views.drawCards.NewPlayerDrawRewardPanel").new({tag = 5555, isClose = true, datas = self.datas.finalRewards})
            display.commonUIParams(rewardPanel, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
            rewardPanel:setTag(5555)
            scene:AddDialog(rewardPanel)
        else
            uiMgr:ShowInformationTips(__("最终奖励已领取"))
        end
    end
end

--[[
--单抽事件
--]]
function CapsuleNewPlayerMediator:OneShotAction(sender)
    PlayAudioByClickNormal()
    local remainTimes = checkint(self.datas.maxGamblingTimes) - checkint(self.datas.gamblingTimes)
    if remainTimes >= 1  then
        --可抽
        local consumeGoodsNo = sender:getTag()
        local goodsId = sender:getUserTag()
        print(goodsId)
        --是否弹出确认提示
        if checktable(GAME_MODULE_OPEN).DUAL_DIAMOND then
            self:ShotComfirmPopup({type = 1, consumeId = goodsId, consumeNum = consumeGoodsNo}, function ( ... )
                self:SendSignal(POST.GAMBLING_NEWBIE_LUCKY.cmdName, {type = 1, consumeGoodsNo = consumeGoodsNo, goodsId = goodsId})
            end)
        else
            local hasNo = gameMgr:GetAmountByGoodId(goodsId)
            if hasNo >= consumeGoodsNo then
                self:SendSignal(POST.GAMBLING_NEWBIE_LUCKY.cmdName, {type = 1, consumeGoodsNo = consumeGoodsNo, goodsId = goodsId})
            else
                local data = CommonUtils.GetConfig('goods', 'goods',goodsId)
                if data then
                    if GAME_MODULE_OPEN.NEW_STORE and checkint(goodsId) == DIAMOND_ID then
                        app.uiMgr:showDiamonTips()
                    else
                        uiMgr:ShowInformationTips(string.fmt(__("_name_数量不足"), {_name_ = data.name}))
                    end
                end
            end
        end
    end
end
--[[
--十抽事件
--]]
function CapsuleNewPlayerMediator:TenShotAction(sender)
    PlayAudioByClickNormal()
    local remainTimes = checkint(self.datas.maxGamblingTimes) - checkint(self.datas.gamblingTimes)
    if remainTimes >= 10  then
        --可抽
        local consumeGoodsNo = sender:getTag()
        local goodsId = sender:getUserTag()
        if checktable(GAME_MODULE_OPEN).DUAL_DIAMOND then
            self:ShotComfirmPopup({type = 10, consumeId = goodsId, consumeNum = consumeGoodsNo}, function ( ... )
                self:SendSignal(POST.GAMBLING_NEWBIE_LUCKY.cmdName, {type = 2, consumeGoodsNo = consumeGoodsNo, goodsId = goodsId})
            end)
        else
            local hasNo = gameMgr:GetAmountByGoodId(goodsId)
            if hasNo >= consumeGoodsNo then
                self:SendSignal(POST.GAMBLING_NEWBIE_LUCKY.cmdName, {type = 2, consumeGoodsNo = consumeGoodsNo, goodsId = goodsId})
            else
                local data = CommonUtils.GetConfig('goods', 'goods',goodsId)
                if data then
                    if GAME_MODULE_OPEN.NEW_STORE and checkint(goodsId) == DIAMOND_ID then
                        app.uiMgr:showDiamonTips()
                    else
                        -- 道具不足时弹出通用获取弹窗
                        app.uiMgr:AddDialog("common.GainPopup", {goodId = goodsId})
                        -- uiMgr:ShowInformationTips(string.fmt(__("_name_数量不足"), {_name_ = data.name}))
                    end
                end
            end
        end
    end
end
--[[
--抽卡二次确认框
--]]
function CapsuleNewPlayerMediator:ShotComfirmPopup( data, cb )
    if isJapanSdk() then
        if cb then
            cb()
        end
    else
        local scene = uiMgr:GetCurrentScene()
        local DiamondLuckyDrawPopup  = require('Game.views.DiamondLuckyDrawPopup').new({tag = 5001, mediatorName = "CapsuleNewPlayerMediator", data = data, cb = function ()
            if cb then
                cb()
            end
        end})
        display.commonUIParams(DiamondLuckyDrawPopup, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
        DiamondLuckyDrawPopup:setTag(5001)
        scene:AddDialog(DiamondLuckyDrawPopup)
    end
end

--[[
--正常的抽卡状态下更新相关界面显示
--]]
function CapsuleNewPlayerMediator:FreshUI()
    local viewData = self.viewComponent.viewData
    local max = checkint(self.datas.maxGamblingTimes)
    local pro = checkint(self.datas.gamblingTimes)
    viewData.progressBar:setValue( pro / max * 100)
    viewData.rewardDrawNumLabel:setText(string.fmt(__('累计抽卡_num_ 次奖励'), {_num_ = max}))
    viewData.countNumLabel:setString(string.fmt(__("剩余抽卡次数：_num_"), {_num_ = max - pro}))
    self.viewComponent:RefreshCardList(checktable(self.datas.finalRewards))
    -- viewData.oneshotButton:UpdateUI(self.datas)
    viewData.tenShotButton:UpdateUI(self.datas)
end

--[[
--更新抽卡次数的方法，包括修改总抽卡次数
--]]
function CapsuleNewPlayerMediator:UpdateDrawcardInfo(body)
    local drawType = checkint(body.requestData.type)

    local consumeGoodsNo = checkint(body.requestData.consumeGoodsNo)
    local goodsId = checkint(body.requestData.goodsId) --扣道具数量
    if goodsId == PAID_DIAMOND_ID then
        CommonUtils.RefreshDiamond({diamond = gameMgr:GetAmountByGoodId(DIAMOND_ID) - consumeGoodsNo,
                                    paidDiamond = gameMgr:GetAmountByGoodId(PAID_DIAMOND_ID) - consumeGoodsNo
        })
    else
        CommonUtils.DrawRewards({{goodsId = goodsId, num = - consumeGoodsNo}})
    end
    --检查次数
    local gamblingTimes = checkint(self.datas.gamblingTimes)
    if drawType == 1 then
        gamblingTimes = gamblingTimes + 1
        self.datas.oneGamblingTimes = checkint(self.datas.oneGamblingTimes) + 1
    else
        gamblingTimes = gamblingTimes + 10
        self.datas.tenGamblingTimes = checkint(self.datas.tenGamblingTimes) + 1
    end
    self:CheckMaxGamblingTimes(gamblingTimes, true)
    local rewards = body.rewards
    local activityRewards = body.activityRewards
    if activityRewards then
        for _,val in pairs(activityRewards) do
            local hasIt = 0
            for _,vv in pairs(rewards) do
                if checkint(val.goodsId) == checkint(vv.goodsId) then
                    vv.num = checkint(vv.num) + checkint(val.num)
                    hasIt = 1
                end
            end
            if hasIt == 0 then
                table.insert(rewards, val)
            end
        end
    end
    -- if #rewards > 0 then
    --     --弹出通用奖励框
    --     CommonUtils.DrawRewards(rewards)
    --     uiMgr:AddDialog('common.RewardPopup', {rewards = rewards, addBackpack = false})
    -- end
    --看是否可领取状态页面更新
    if checkint(self.datas.gamblingTimes) < checkint(self.datas.maxGamblingTimes) then
        self:FreshUI()
    end
end

--[[
--判断是否到达了最大的抽卡次数大奖励可领的状态
--]]
function CapsuleNewPlayerMediator:CheckMaxGamblingTimes(gamblingTimes, isUpdateGamblingTimes)
    self.datas.gamblingTimes = gamblingTimes
    local viewData = self.viewComponent.viewData
    if gamblingTimes >= checkint(self.datas.maxGamblingTimes) then
        --到达最大次数了
        gamblingTimes = checkint(self.datas.maxGamblingTimes)
        if isUpdateGamblingTimes then
            self.datas.gamblingTimes = gamblingTimes
        end
        --更新关的界面逻辑
        viewData.bottomView:setVisible(false)
        viewData.rightView:setVisible(false)
        viewData.progressBar:setValue(100)
        viewData.bgGrow:setVisible(true)
        if checkint(self.datas.gamblingTimes) >= checkint(self.datas.maxGamblingTimes) then
            viewData.rewardDrawNumLabel:setText(__('点击领取'))
        else
            local max = checkint(self.datas.maxGamblingTimes)
            viewData.rewardDrawNumLabel:setText(string.fmt(__('累计抽卡_num_ 次奖励'), {_num_ = max}))
        end
    end
end


function CapsuleNewPlayerMediator:OnRegist()
    regPost(POST.GAMBLING_NEWBIE_LUCKY)
    regPost(POST.GAMBLING_NEWBIE_FINAL_DRAW)
end

function CapsuleNewPlayerMediator:OnUnRegist()
    unregPost(POST.GAMBLING_NEWBIE_LUCKY)
    unregPost(POST.GAMBLING_NEWBIE_FINAL_DRAW)
end

function CapsuleNewPlayerMediator:CleanupView()
    if self.ownerNode_ then
        if self.viewComponent and self.viewComponent:getParent() then
            self.viewComponent:runAction(cc.RemoveSelf:create())
            self.viewComponent = nil
        end
        self.ownerNode_ = nil
    end
end

return CapsuleNewPlayerMediator
