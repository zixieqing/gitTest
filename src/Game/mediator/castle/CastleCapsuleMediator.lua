--[[
奖励mediator
--]]
local Mediator = mvc.Mediator
---@class CastleCapsuleMediator :Mediator
local CastleCapsuleMediator = class("CastleCapsuleMediator", Mediator)
local NAME = "Game.mediator.castle.CastleCapsuleMediator"
CastleCapsuleMediator.NAME = NAME


function CastleCapsuleMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.ctorArgs_ = checktable(params)
end

-------------------------------------------------
-- inheritance method
function CastleCapsuleMediator:Initial(key)
    self.super.Initial(self, key)

    self.datas = {}
    self.isControllable_ = true

    -- create view
    local viewComponent = require('Game.views.castle.CastleCapsuleView').new({mediatorName = NAME})
    self.viewData_      = viewComponent:GetViewData()
    self:SetViewComponent(viewComponent)
    self:InitOwnerScene_()
    display.commonUIParams(viewComponent,{po = display.center, ap = display.CENTER})
    self:GetOwnerScene():AddDialog(viewComponent)

    -- init data
    self:InitData_()

    -- init view
    self:InitView_()
    
    viewComponent:EnterAction()
end

function CastleCapsuleMediator:InitData_()
    local luckyConsumeConf = CommonUtils.GetConfigAllMess('luckyConsume', 'springActivity') or {}
    self.luckyConsume = luckyConsumeConf['1'] or {}

    local extraRewardsConf = CommonUtils.GetConfigAllMess('extraRewards', 'springActivity') or {}
    self.extraRewardsData = extraRewardsConf['1'] or {}
end

function CastleCapsuleMediator:InitRewardPreviewData()
    local luckyRewards = CommonUtils.GetConfigAllMess('lucky', 'springActivity') or {}
    local rewardPreviewDatas = {}
    local rateList = {}
    local totalRate = 0
    for _, d in pairs(luckyRewards) do
        local rewards = d.rewards or {}
        local rareGoods = checkint(d.rareGoods)
        if rewardPreviewDatas[rareGoods] == nil then
            rewardPreviewDatas[rareGoods] = {title = rareGoods == 1 and app.activityMgr:GetCastleText(__('稀有')) or app.activityMgr:GetCastleText(__('普通')), list = {}}
        end

        local baseData = {
            goodsSort = d.goodsSort,
            id = d.id,
        }
        local baseRateData = {
            goodsSort = d.goodsSort,
            descr     = '',
            rate  = checkint(d.rate) --d.rate
        }
        totalRate = totalRate + checkint(d.rate)
        for i, v in ipairs(rewards) do
            baseData.reward = v
            baseRateData.descr = string.fmt( "_name_x_num_", {_name_ = tostring(checktable(CommonUtils.GetConfig('goods', 'goods', v.goodsId)).name), _num_ = tostring(v.num)})
            table.insert(rateList, baseRateData)
            table.insert(rewardPreviewDatas[rareGoods].list, baseData)
        end
    end

    local listSortFunc = function (a, b)
        return checkint(a.goodsSort) > checkint(b.goodsSort)
    end

    for i, v in pairs(rewardPreviewDatas) do
        table.sort(v.list or {}, listSortFunc)
    end

    for i, v in ipairs(rateList) do
        v.rateText = math.ceil(checkint(v.rate)/totalRate * 10000) / 100  .. "%"
    end
    table.sort(rateList, listSortFunc)
    for i, v in pairs(rewardPreviewDatas[1].list) do
        local  reward = v.reward
        local goodType = CommonUtils.GetGoodTypeById(reward.goodsId)
        if goodType == GoodsType.TYPE_CARD then
            self.superRewardsGoodsId = reward.goodsId
        end
    end
    self.rewardPreviewDatas = rewardPreviewDatas
    self.rateList = rateList
end

function CastleCapsuleMediator:InitView_()
    local viewData = self:GetViewData()

    -- back
    display.commonUIParams(viewData.backBtn, {cb = handler(self, self.OnClickBackBtnAction), animate = false})
    -- rule
    display.commonUIParams(viewData.titleBtn, {cb = handler(self, self.OnClickTitleBtnAction), animate = false})
    display.commonUIParams(viewData.flowerImg, {cb = handler(self, self.OnClickFlowerImgAction), animate = false})
    display.commonUIParams(viewData.needleImg, {cb = handler(self, self.OnClickNeedleImgAction), animate = false})
    display.commonUIParams(viewData.rewardPreview, {cb = handler(self, self.OnClickRewardPreviewAction)})
    display.commonUIParams(viewData.purifyOneTimesBtn, {cb = handler(self, self.OnClickOneTimesBtnAction), animate = false})
    display.commonUIParams(viewData.purifyTenTimesBtn, {cb = handler(self, self.OnClickTenTimesBtnAction), animate = false})

    self:RefreshUI()
end

function CastleCapsuleMediator:InitOwnerScene_()
    self.ownerScene_ = app.uiMgr:GetCurrentScene()
end

function CastleCapsuleMediator:CleanupView_()
    local viewComponent = self:GetViewComponent()
    if self.ownerScene_ and viewComponent and not tolua.isnull(viewComponent) then
        self.ownerScene_:RemoveDialog(viewComponent)
        self.ownerScene_ = nil
    end
end


function CastleCapsuleMediator:OnRegist()
    regPost(POST.SPRING_ACTIVITY_LOTTERY)
    self:EnterLayer()
end
function CastleCapsuleMediator:OnUnRegist()
    unregPost(POST.SPRING_ACTIVITY_LOTTERY)
    self:CleanupView_()
end


function CastleCapsuleMediator:InterestSignals()
    return {
        "CASTLE_CAPSULE_SHOW_REWARD",
        POST.SPRING_ACTIVITY_LOTTERY.sglName,
    }
end

function CastleCapsuleMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody() or {}

    if name == POST.SPRING_ACTIVITY_LOTTERY.sglName then
        --self.isControllable_ = false

        local requestData = body.requestData or {}
        local times       = requestData.times
        self.capsuleRewards = {}
        for index, value in ipairs(self.extraRewardsData.rewards or {}) do
            table.insert(self.capsuleRewards, {goodsId = value.goodsId, num = checkint(value.num) * times})
        end

        self.isRate = false
        local gambling = body.gambling or {}
        local rewardLists = body.rewards or {}
        for i, rewardList in pairs(rewardLists) do
            local highlight = gambling[i]
            self.isRate = self.isRate or (checkint(highlight) > 0)
            for i, reward in ipairs(rewardList) do
                table.insert(self.capsuleRewards, reward)
            end
        end
        
        CommonUtils.DrawRewards(self.capsuleRewards)
        
        local consumeData = clone(self.luckyConsume.consume or {})
        
        for i, v in ipairs(consumeData) do
            consumeData[i].num = consumeData[i].num * times * -1
        end
        CommonUtils.DrawRewards(consumeData)

        self:GetViewComponent():PlayCapsuleAnimateByTimes(times)

        self:RefreshUI()
    elseif "CASTLE_CAPSULE_SHOW_REWARD" == name then
        if self.capsuleRewards and next(self.capsuleRewards) ~= nil then
            --self:GetOwnerScene():AddViewForNoTouch()
            app.uiMgr:AddDialog('common.RewardPopup', {rewards = self.capsuleRewards, addBackpack = false})
            self.capsuleRewards = nil
            if self.isRate then
                self.isRate = nil
                local cotAnimation = sp.SkeletonAnimation:create(
                    'effects/capsule/capsule.json',
                    'effects/capsule/capsule.atlas',
                    1)
                cotAnimation:update(0)
                cotAnimation:setToSetupPose()
                cotAnimation:setAnimation(0, 'chouka_qian', false)
                cotAnimation:setPosition(display.center)
                -- 结束后移除
                cotAnimation:registerSpineEventHandler(function (event)
                    cotAnimation:runAction(cc.RemoveSelf:create())
                end, sp.EventType.ANIMATION_END)
                sceneWorld:addChild(cotAnimation, GameSceneTag.Dialog_GameSceneTag)
            end

            --transition.execute(self:GetViewComponent(), nil, {delay = 0.8, complete = function()
            --    self:GetOwnerScene():RemoveViewForNoTouch()
            --    self.isControllable_ = true
            --end})
        end
    end
end

-------------------------------------------------
-- get / set

function CastleCapsuleMediator:GetViewData()
    return self.viewData_
end

function CastleCapsuleMediator:GetOwnerScene()
    return self.ownerScene_
end

-------------------------------------------------
-- public method
function CastleCapsuleMediator:EnterLayer()
end

function CastleCapsuleMediator:RefreshUI()
    local viewComponent = self:GetViewComponent()
    viewComponent:UpdateCapsuleConsume(self.luckyConsume)
end


-------------------------------------------------
-- private method

-------------------------------------------------
-- check

--==============================--
--desc: 检查是否能抽卡
--@params times        int  抽卡次数
--@return isCanCapsule bool 是否能抽卡
--==============================--
function CastleCapsuleMediator:CheckIsCanCapsule(times)
    local isCanCapsule = true
    local consumeDatas = self.luckyConsume.consume
    local ownNum = 0
    local goodsId = nil
    for i, consumeData in ipairs(consumeDatas) do
        local connsumeGoodsId = consumeData.goodsId
        ownNum = app.gameMgr:GetAmountByGoodId(connsumeGoodsId)
        local num = checkint(consumeData.num) * times
        if ownNum < num then
            isCanCapsule = false
            goodsId = connsumeGoodsId
            break
        end
    end

    if goodsId then
        local goodsConfig = CommonUtils.GetConfig('goods', 'goods', goodsId) or {}
        app.uiMgr:ShowInformationTips(string.format(app.activityMgr:GetCastleText(__('当前%s数量不足')), tostring(goodsConfig.name)))
    end

    return isCanCapsule
end

-------------------------------------------------
-- handler
function CastleCapsuleMediator:OnClickBackBtnAction(sender)
    if not self.isControllable_ then end
    app:UnRegsitMediator(NAME)
end

function CastleCapsuleMediator:OnClickTitleBtnAction()
    if not self.isControllable_ then end

    app.uiMgr:ShowIntroPopup({moduleId = -28})
end

function CastleCapsuleMediator:OnClickFlowerImgAction(sender)
    if not self.isControllable_ then end
    app.uiMgr:AddDialog("common.GainPopup", {goodId = sender:getTag()})
end

function CastleCapsuleMediator:OnClickNeedleImgAction(sender)
    if not self.isControllable_ then end
    app.uiMgr:AddDialog("common.GainPopup", {goodId = sender:getTag()})
end

function CastleCapsuleMediator:OnClickOneTimesBtnAction(sender)
    if not self.isControllable_ then end

    local isCanCapsule = self:CheckIsCanCapsule(1)
    if not isCanCapsule then return end

    self:SendSignal(POST.SPRING_ACTIVITY_LOTTERY.cmdName, {times = 1})
end

function CastleCapsuleMediator:OnClickTenTimesBtnAction(sender)
    if not self.isControllable_ then end

    local isCanCapsule = self:CheckIsCanCapsule(10)
    if not isCanCapsule then return end

    self:SendSignal(POST.SPRING_ACTIVITY_LOTTERY.cmdName, {times = 10})
end

function CastleCapsuleMediator:OnClickRewardPreviewAction()
    if not self.isControllable_ then end

    if self.rewardPreviewDatas == nil then
        self:InitRewardPreviewData()
    end

    local capsulePrizeView = require( 'Game.views.anniversary.AnniversaryCapsulePoolView' ).new({
        confId = self.superRewardsGoodsId, rewardPreviewDatas = self.rewardPreviewDatas, 
        rate = self.rateList, roleBgPath = app.activityMgr:CastleResEx('ui/castle/capsule/castle_draw_rewards_bg_card.png')
    })
    display.commonUIParams(capsulePrizeView, {ap = display.CENTER, po = display.center})
    local scene = app.uiMgr:GetCurrentScene()
    scene:AddDialog(capsulePrizeView)
end

return CastleCapsuleMediator
