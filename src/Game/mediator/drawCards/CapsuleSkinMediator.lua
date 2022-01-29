--[[
扭蛋系统 皮肤卡池mediator
--]]
local Mediator = mvc.Mediator
local CapsuleSkinMediator = class("CapsuleSkinMediator", Mediator)
local NAME = "CapsuleSkinMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")

local CapsuleSkinEntryView = require("Game.views.drawCards.CapsuleSkinEntryView")

function CapsuleSkinMediator:ctor( params, viewComponent )
    self.super.ctor(self, NAME, viewComponent)
    self.ctorArgs_ = checktable(params)
end

function CapsuleSkinMediator:InterestSignals()
	local signals = {
        POST.GAMBLING_SKIN_CHOOSE.sglName,
        POST.GAMBLING_SKIN_DRAW.sglName,
	}
	return signals
end

function CapsuleSkinMediator:ProcessSignal( signal )
	local name = signal:GetName()
	local body = signal:GetBody()
	-- dump(body, name)
    if name == POST.GAMBLING_SKIN_CHOOSE.sglName then
        --选卡池
        self.datas.leftGamblingTimes = checkint(body.leftGamblingTimes)
        local cardSkinId = checkint(body.requestData.cardSkinId)
        self.datas.currentCardSkin = cardSkinId
        self:getSkinView():ShowDrawCardUI(self.datas)
    elseif name == POST.GAMBLING_SKIN_DRAW.sglName then
        --抽卡
        local dType = checkint(body.requestData.type)
        if dType == 2 then
            self.datas.leftGamblingTimes = checkint(self.datas.leftGamblingTimes) - 10
        else
            self.datas.leftGamblingTimes = checkint(self.datas.leftGamblingTimes) - 1
        end
        if self.datas.leftGamblingTimes == 0 then
            --当前卡池次数抽完了
        end
        self:getSkinView():UpdateDrawButtonState()
        local consumeGoodsNo = checkint(body.requestData.consumeNum)
        local goodsId = checkint(body.requestData.consumeId) --扣道具数量
        if goodsId == PAID_DIAMOND_ID then
            CommonUtils.RefreshDiamond({diamond = gameMgr:GetAmountByGoodId(DIAMOND_ID) - consumeGoodsNo,
                    paidDiamond = gameMgr:GetAmountByGoodId(PAID_DIAMOND_ID) - consumeGoodsNo
                })
        else
            CommonUtils.DrawRewards({{goodsId = goodsId, num = - consumeGoodsNo}})
        end

        local rewards = body.rewards
        if body.diamond then
            gameMgr:UpdatePlayer({diamond = checkint(body.diamond)})
        end
        AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI, { diamond = gameMgr:GetUserInfo().diamond })
        self:getSkinView().viewData.countNumLabel:setString(string.fmt(__("剩余抽卡次数：_num_"), {_num_ = self.datas.leftGamblingTimes}))
        if rewards then
            --弹奖励
            --此处特殊处理下因为有可能会转化为其他道具依服务端返回转换为准
            -- local targetRewards = {}
            -- for _,val in pairs(rewards) do
            --     if val.turnGoodsId and val.turnGoodsNum and checkint(val.turnGoodsNum) > 0 then
            --         table.insert(targetRewards,{goodsId = val.turnGoodsId, num = val.turnGoodsNum, type = val.type})
            --     else
            --         table.insert(targetRewards,val)
            --     end
            -- end            
            -- 判断奖励中是否存在稀有奖励
            self.rewardsData = body
            local cb = handler(self, self.ShowActivityRewards)
            local mediator = require("Game.mediator.drawCards.CapsuleSkinAnimateMediator").new({rewards = rewards, cb = cb})
            AppFacade.GetInstance():RegistMediator(mediator)
        end
    end
end

function CapsuleSkinMediator:Initial( key )
    self.super.Initial(self, key)
    self.ownerNode_ = self.ctorArgs_.ownerNode
    -- create view
    if self.ownerNode_ then
        local size = self.ownerNode_:getContentSize()
        local view = CapsuleSkinEntryView.new({size = size})
        display.commonUIParams(view, {po = cc.p(size.width * 0.5, size.height * 0.5)})
        self.ownerNode_:addChild(view,19)
        self:SetViewComponent(view)
        --注册按钮相关的事件处理逻辑
        view.viewData.selectButton:setOnClickScriptHandler(handler(self, self.ChooseSkinPool))
        view.viewData.drawOnceBtn:setOnClickScriptHandler(handler(self, self.OneShotAction))
        view.viewData.drawMuchBtn:setOnClickScriptHandler(handler(self, self.TenShotAction))
        view.viewData.shopBtn:setOnClickScriptHandler(handler(self, self.ChooseShopAction))
    end
end


function CapsuleSkinMediator:getSkinView()
    return self.viewComponent
end


function CapsuleSkinMediator:ChooseSkinPool(sender)
    PlayAudioByClickNormal()
    local currentCardSkin = checkint(self.datas.currentCardSkin)
    --如果当前选择的皮肤已选择过
    if currentCardSkin > 0 then
        self:getSkinView():ShowDrawCardUI(self.datas)
    else
        if self:IsAllObtained() then
            self:getSkinView():ShowDrawCardUI(self.datas)
        else
            --请求选择卡
            local skinId = self:getSkinView():GetSelectSkinId()
            if skinId > 0 then
                -- local currentId = self.datas.cardSkins[currentCardSkin].rareCardSkinId
                -- if skinId == checkint(currentId) then
                --     --选的是上一次的直接进入 并且没有这个皮肤
                --     local skinView = self:getSkinView()
                --     if skinView then
                --         skinView:ShowDrawCardUI(self.datas)
                --     end
                -- else
                    --出一个提示判断的逻辑
                    local commonTip = require( 'common.CommonTip' ).new({ text = __('确认选择这珍稀外观进入卡池吗?'),
                            descr = __('确认后直到抽到该外观前，不能替换重置该卡池'), callback = function()
                                self:SendSignal(POST.GAMBLING_SKIN_CHOOSE.cmdName, {activityId = self.activityId, cardSkinId = skinId})
                            end})
                        commonTip:setPosition(display.center)
                        commonTip:setTag(5555)
                    uiMgr:GetCurrentScene():AddDialog(commonTip, 10)
                -- end
            end
        end
    end
end
-------------------------------------------------
-- public method

function CapsuleSkinMediator:resetHomeData(homeData, activityId)
    self.datas = homeData
    self.activityId = activityId
    if checkint(homeData.reset) == 1 then
        local CommonTip  = require( 'common.NewCommonTip' ).new({text = __('您已经在别处获得了目前卡池内的珍稀外观，需重置卡池，重新选择其他珍稀外观哦~'),
        isOnlyOK = true})
        CommonTip:setPosition(display.center)
        local scene = uiMgr:GetCurrentScene()
        scene:AddDialog(CommonTip)
    end
    local skinView = self:getSkinView()
    if skinView then
        --更新界面相关的逻辑
        if checkint(homeData.currentCardSkin) > 0 then
            --已经选择过皮肤卡池了
            skinView:ShowDrawCardUI(homeData)
        else
            if self:IsAllObtained() then
                skinView:ShowDrawCardUI(homeData)
            else
                skinView:ShowSelectCard(homeData)
            end
        end
    end
end

--[[
--单抽事件
--]]
function CapsuleSkinMediator:OneShotAction(sender)
    PlayAudioByClickNormal()
    local remainTimes = checkint(self.datas.leftGamblingTimes)
    if not (remainTimes == 0)  then
        --可抽
        local consumeGoodsNo = sender:getTag()
        local goodsId = sender:getUserTag()
        --是否弹出确认提示
        -- if checktable(GAME_MODULE_OPEN).DUAL_DIAMOND then
            -- self:ShotComfirmPopup({type = 1, consumeId = goodsId, consumeNum = consumeGoodsNo}, function ( ... )
                -- self:SendSignal(POST.GAMBLING_SKIN_DRAW.cmdName, {type = 1, activityId = self.activityId})
            -- end)
        -- else
        local hasNo = gameMgr:GetAmountByGoodId(goodsId)
        if hasNo >= consumeGoodsNo then
            self:SendSignal(POST.GAMBLING_SKIN_DRAW.cmdName, {type = 1, activityId = self.activityId, consumeId = goodsId, consumeNum = consumeGoodsNo})
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
        -- end
    end
end
--[[
--十抽事件
--]]
function CapsuleSkinMediator:TenShotAction(sender)
    PlayAudioByClickNormal()
    local remainTimes = checkint(self.datas.leftGamblingTimes)
    if remainTimes >= 10 or remainTimes < 0 then
        --可抽
        local consumeGoodsNo = sender:getTag()
        local goodsId = sender:getUserTag()
        -- if checktable(GAME_MODULE_OPEN).DUAL_DIAMOND then
            -- self:ShotComfirmPopup({type = 10, consumeId = goodsId, consumeNum = consumeGoodsNo}, function ( ... )
                -- self:SendSignal(POST.GAMBLING_SKIN_DRAW.cmdName, {type = 2, activityId = self.activityId})
            -- end)
        -- else
        local hasNo = gameMgr:GetAmountByGoodId(goodsId)
        if hasNo >= consumeGoodsNo then
            self:SendSignal(POST.GAMBLING_SKIN_DRAW.cmdName, {type = 2, activityId = self.activityId, consumeId = goodsId, consumeNum = consumeGoodsNo})
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
        -- end
    end
end

function CapsuleSkinMediator:ChooseShopAction(sender)
    PlayAudioByClickNormal()
    -- AppFacade.GetInstance():RetrieveMediator('Router'):Dispatch({name = NAME}, {name = 'drawCards.CapsuleMallMediaor'})
    local contentMdtClass  = require('Game.mediator.drawCards.CapsuleMallMediaor')
    local contentMdtObject = contentMdtClass.new({activityId = self.activityId})
    -- contentMdtObject.mediatorName = drawMdtName
    app:RegistMediator(contentMdtObject)
end

--[[
--抽空二次确认框
--]]
function CapsuleSkinMediator:ShotComfirmPopup( data, cb )
	local scene = uiMgr:GetCurrentScene()
	local DiamondLuckyDrawPopup  = require('Game.views.DiamondLuckyDrawPopup').new({tag = 5001, mediatorName = "CapsuleSkinMediator", data = data, cb = function ()
        if cb then
            cb()
        end
	end})
	display.commonUIParams(DiamondLuckyDrawPopup, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
	DiamondLuckyDrawPopup:setTag(5001)
	scene:AddDialog(DiamondLuckyDrawPopup)
end

--[[
--正常的抽卡状态下更新相关界面显示
--]]
function CapsuleSkinMediator:FreshUI()

end

--[[
--更新抽卡次数的方法，包括修改总抽卡次数
--]]
function CapsuleSkinMediator:UpdateDrawcardInfo(body)
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
    if checkint(self.datas.gamblingTimes) <= checkint(self.datas.maxGamblingTimes) then
        self:FreshUI()
        if checkint(self.datas.gamblingTimes) <= checkint(self.datas.maxGamblingTimes) then
            local viewData = self.viewComponent.viewData
            viewData.rewardDrawNumLabel:setText(__('点击领取'))
        end
    end
end

--[[
--判断是否到达了最大的抽卡次数大奖励可领的状态
--]]
function CapsuleSkinMediator:CheckMaxGamblingTimes(gamblingTimes, isUpdateGamblingTimes)
    -- self.datas.gamblingTimes = gamblingTimes
    -- local viewData = self.viewComponent.viewData
    -- if gamblingTimes >= checkint(self.datas.maxGamblingTimes) then
    --     --到达最大次数了
    --     gamblingTimes = checkint(self.datas.maxGamblingTimes)
    --     if isUpdateGamblingTimes then
    --         self.datas.gamblingTimes = gamblingTimes
    --     end
    --     --更新关的界面逻辑
    -- end
end
--[[
获取列表选中状态
--]]
function CapsuleSkinMediator:GetSelectIndex()
    return self:getSkinView():GetPreIndex()
end
--[[
是否所有皮肤全部获得
--]]
function CapsuleSkinMediator:IsAllObtained()
    local allObtained = true
    for i, v in ipairs(self.datas.cardSkins) do
        if not app.cardMgr.IsHaveCardSkin(checkint(v.rareCardSkinId)) then
            allObtained = false
            break
        end
    end
    return allObtained
end
--[[
判断奖励中是否存在稀有奖励
--]]
function CapsuleSkinMediator:HasDrawCurrentSkin( rewards )
    if not rewards then return end
    local currentCardSkin = checkint(self.datas.currentCardSkin)
    if currentCardSkin > 0 then
        for i, v in ipairs(rewards) do
            if checkint(v.goodsId) == currentCardSkin then
                -- 存在稀有奖励
                return true 
            end
        end
    end
    return false
end
--[[
判断是否有活动道具奖励
--]]
function CapsuleSkinMediator:IsHasActivityRewards( acticityRewards )
    if acticityRewards and next(acticityRewards) ~= nil then
        return true
    else
        return false
    end
end
--[[
显示活动奖励
--]]
function CapsuleSkinMediator:ShowActivityRewards()
    if self:IsHasActivityRewards(self.rewardsData.activityRewards) then
        local cb = nil
        if self:HasDrawCurrentSkin(self.rewardsData.rewards) then
            cb = handler(self, self.ShowTips)
        end
        uiMgr:AddDialog('common.RewardPopup', {rewards = self.rewardsData.activityRewards, closeCallback = cb})
    else
        if self:HasDrawCurrentSkin(self.rewardsData.rewards) then
            self:ShowTips()
        end
    end
end
--[[
显示提示框
--]]
function CapsuleSkinMediator:ShowTips()
    if self:IsAllObtained() then
        local commonTip = require( 'common.CommonTip' ).new({ text = __('珍稀外观都已获得，御侍大人可以继续在卡池内召唤其余的飨灵外观和其他道具。'), isOnlyOK = true, 
        callback = function()
            self.datas.currentCardSkin = nil
            self.datas.leftGamblingTimes = -1
            self:getSkinView():ShowDrawCardUI(self.datas)
        end})
        commonTip:setPosition(display.center)
        commonTip:setTag(5555)
        uiMgr:GetCurrentScene():AddDialog(commonTip, 10)
    else
        local commonTip = require( 'common.CommonTip' ).new({ text = __('恭喜您获得了一个珍稀外观，请继续选择另一个珍稀外观投入卡池召唤'), isOnlyOK = true,
        callback = function()
            self.datas.currentCardSkin = nil
            self:getSkinView():ShowSelectCard(self.datas)
        end})
        commonTip:setPosition(display.center)
        commonTip:setTag(5555)
        uiMgr:GetCurrentScene():AddDialog(commonTip, 10)
    end
end

function CapsuleSkinMediator:OnRegist()
    regPost(POST.GAMBLING_SKIN_CHOOSE)
    regPost(POST.GAMBLING_SKIN_DRAW)
end

function CapsuleSkinMediator:OnUnRegist()
    unregPost(POST.GAMBLING_SKIN_CHOOSE)
    unregPost(POST.GAMBLING_SKIN_DRAW)
end

function CapsuleSkinMediator:CleanupView()
    if self.ownerNode_ then
        if self.viewComponent and self.viewComponent:getParent() then
            self.viewComponent:runAction(cc.RemoveSelf:create())
            self.viewComponent = nil
        end
        self.ownerNode_ = nil
    end
end

return CapsuleSkinMediator
