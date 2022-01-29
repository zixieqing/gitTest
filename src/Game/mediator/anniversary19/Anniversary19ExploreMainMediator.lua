--[[
仙境梦游-探索主界面 mediator
--]]
local Mediator = mvc.Mediator
---@class Anniversary19ExploreMainMediator :Mediator
local Anniversary19ExploreMainMediator = class("Anniversary19ExploreMainMediator", Mediator)
local NAME = "anniversary19.Anniversary19ExploreMainMediator"
Anniversary19ExploreMainMediator.NAME = NAME

local app = app

function Anniversary19ExploreMainMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.ctorArgs_ = checktable(params)
end

-------------------------------------------------
-- inheritance method
function Anniversary19ExploreMainMediator:Initial(key)
    self.super.Initial(self, key)

    self.datas = {}
    self.isControllable_ = true

    ---@type Anniversary19ExploreMainView
    local viewComponent = require('Game.views.anniversary19.Anniversary19ExploreMainView').new({mediatorName = NAME})
    self.viewData_      = viewComponent:GetViewData()
    self:SetViewComponent(viewComponent)
    app.uiMgr:SwitchToScene(viewComponent)

    self:InitOwnerScene_()

    -- init data
    self:InitData_()

    -- init view
    self:InitView_()
    
end

function Anniversary19ExploreMainMediator:InitData_()

    --  检查boss 是否升级
    local datas    = {}
    local mgr      = app.anniversary2019Mgr
    local homeData = mgr:GetHomeData()
    local explore  = homeData.explore or {}

    for exploreModuleId, value in pairs(explore) do
        local chapterConf   = CommonUtils.GetConfig('anniversary2', 'chapter', exploreModuleId) or {}
        local bossConf      = CommonUtils.GetConfig('anniversary2', 'boss', chapterConf.bossId) or {}
        local bossLevelData = bossConf[tostring(checkint(value.bossLevel) + 1)]
        -- 未达到boss 最大等级 并且 BOSS下次升级剩余发现次数 是0
        if bossLevelData and checkint(value.nextBossLevelLeftDiscoveryTimes) == 0 then
            self.upgradeExploreModuleId = exploreModuleId
            --self:SendSignal(POST.ANNIVERSARY2_HOME.cmdName , {})
            break
        end
    end

    
end

function Anniversary19ExploreMainMediator:InitView_()
    local viewData      = self:GetViewData()
    local viewComponent = self:GetViewComponent()

    local mgr      = app.anniversary2019Mgr
    local homeData = mgr:GetHomeData()
    local explore  = homeData.explore or {}
    local exploreNodes = viewData.exploreNodes
    for index, exploreNode in ipairs(exploreNodes) do
        local exploreModuleId = exploreNode:getTag()

        local exploreNodeViewData = exploreNode.viewData
        local exploreBtn = exploreNodeViewData.exploreBtn
        exploreBtn:setTag(exploreModuleId)
        display.commonUIParams(exploreBtn, { animate =false ,  cb = handler(self, self.OnClickExploreBtnAction)})
        
        local bossHeadNode = exploreNodeViewData.bossHeadNode
        local touchView = bossHeadNode:GetViewData().touchView
        display.commonUIParams(touchView, {cb = handler(self, self.OnClickBossHeadNodeAction)})
        touchView:setTag(exploreModuleId)

        viewComponent:UpdateExploreNode(exploreNode, explore[tostring(exploreModuleId)] or {}, exploreModuleId)
    end

    -- 初始化占卜信息
    local auguryId = homeData.auguryId
    viewComponent:PlayAugurySpine(auguryId, true)
    viewComponent:UpdateAuguryDesc(viewData, auguryId)

    local hpId = mgr:GetHPGoodsId()
    viewComponent:UpdateMoneyBarGoodList({moneyIdMap = {[tostring(hpId)] = checkint(hpId)}, isEnableGain= true})

    -- 未触发升级 直接执行动画 否则 等home 拉完后再 执行
    if self.upgradeExploreModuleId == nil then
        self.isControllable_ = false
        viewComponent:ShowAction(function ()
            self.isControllable_ = true
        end)
    end

    viewData.augurySpine:registerSpineEventHandler(handler(self, self.AugurySpineEndAction), sp.EventType.ANIMATION_END)

    display.commonUIParams(viewData.backBtn, {cb = handler(self, self.OnClickBackBtnAction), animate = false})
    display.commonUIParams(viewData.titleBtn, {cb = handler(self, self.OnClickTitleBtnAction)})
    display.commonUIParams(viewData.taskBtn, {cb = handler(self, self.OnClickTaskBtnAction)})
    display.commonUIParams(viewData.refreshBtn, {cb = handler(self, self.OnClickRefreshBtnAction)})
end


function Anniversary19ExploreMainMediator:InitOwnerScene_()
    self.ownerScene_ = app.uiMgr:GetCurrentScene()
end

function Anniversary19ExploreMainMediator:cleanupView()

    local viewComponent = self:GetViewComponent()
    -- 停止文字滚动
    viewComponent:StopTextScroll()

    if self.ownerScene_ and viewComponent and not tolua.isnull(viewComponent) then
        self.ownerScene_:RemoveDialog(viewComponent)
        self.ownerScene_ = nil
    end
end


function Anniversary19ExploreMainMediator:OnRegist()
    regPost(POST.ANNIVERSARY2_HOME)
    regPost(POST.ANNIVERSARY2_AUGURY)
    regPost(POST.ANNIVERSARY2_STORY_UNLOCK)
    if self.upgradeExploreModuleId then
        self:EnterLayer()
    end
    app:DispatchObservers(HomeScene_ChangeCenterContainer, "rightHide")
    app:DispatchObservers(HomeScene_ChangeCenterContainer, "allhide")
end
function Anniversary19ExploreMainMediator:OnUnRegist()
    unregPost(POST.ANNIVERSARY2_HOME)
    unregPost(POST.ANNIVERSARY2_AUGURY)
    unregPost(POST.ANNIVERSARY2_STORY_UNLOCK)
    self:cleanupView()

    -- self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "show")
end

function Anniversary19ExploreMainMediator:InterestSignals()
    return {
        POST.ANNIVERSARY2_HOME.sglName,
        POST.ANNIVERSARY2_AUGURY.sglName,
        POST.ANNIVERSARY2_STORY_UNLOCK.sglName,
        SGL.CACHE_MONEY_UPDATE_UI,
        SGL.REFRESH_NOT_CLOSE_GOODS_EVENT,
        SGL.NEXT_TIME_DATE,
        'UPDATA_MONEY_BAR',
    }
end

function Anniversary19ExploreMainMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody() or {}

    if name == POST.ANNIVERSARY2_AUGURY.sglName then

        self.isControllable_ = false
        local parameterConf = CommonUtils.GetConfigAllMess('parameter', 'anniversary2') or {}
        local auguryConsume = clone(parameterConf.auguryConsume or {})
        for index, value in ipairs(auguryConsume) do
            value.num = -checknumber(value.num)
        end
        CommonUtils.DrawRewards(auguryConsume)

        local auguryId     = body.auguryId
        local mgr          = app.anniversary2019Mgr
        local homeData     = mgr:GetHomeData()
        -- 更新 占卜id
        homeData.auguryId  = auguryId
        self.auguryId = auguryId

        local viewComponent = self:GetViewComponent()
        -- viewComponent:UpdateAuguryDesc(self:GetViewData(), auguryId)
        viewComponent:PlayAugurySpine(auguryId)

        mgr:StartAuguryRefreshCountdown(body.expire)

        self.isControllable_ = true

    elseif name == POST.ANNIVERSARY2_STORY_UNLOCK.sglName then
        self.isControllable_ = false

        local requestData = body.requestData or {}
        app.anniversary2019Mgr:UpdateUnlockStoryMap(requestData.storyId)
        
        self.isControllable_ = true
    elseif name == POST.ANNIVERSARY2_HOME.sglName then

        local mgr           = app.anniversary2019Mgr
        local requestData   = body.requestData or {}
        mgr:InitData(body)

        local explore = body.explore or {}
        local viewComponent = self:GetViewComponent()
        if self.upgradeExploreModuleId then
            self.isControllable_ = false

            local exploreModuleId = self.upgradeExploreModuleId
            local exploreData = explore[tostring(exploreModuleId)] or {}
            
            viewComponent:ShowAction(function ()
                local upgradeDialog = require('Game.views.anniversary19.Anniversary19ExploreLevelUpgradeView').new({
                    exploreModuleId = exploreModuleId,
                    level = exploreData.bossLevel,
                    nextBossLevelLeftDiscoveryTimes = exploreData.nextBossLevelLeftDiscoveryTimes
                })
                self:GetOwnerScene():AddDialog(upgradeDialog)
                self.isControllable_ = true
            end)
    
            self.upgradeExploreModuleId = nil
        end
        -- 更新占卜描述
        viewComponent:UpdateAuguryDesc(self:GetViewData(), checkint(body.auguryId))

        -- 更新boss等级
        local exploreNodes = self:GetViewData().exploreNodes
        for index, exploreNode in ipairs(exploreNodes) do
            local exploreData = explore[tostring(exploreNode:getTag())] or {}
            exploreNode.viewData.bossHeadNode:UpdateBossLevel(exploreData.bossLevel or 1)
        end

        app:DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI, {diamond = true})
    elseif name == SGL.NEXT_TIME_DATE then
        self:SendSignal(POST.ANNIVERSARY2_HOME.cmdName)
    elseif name == 'UPDATA_MONEY_BAR' then

        local moneyData = body.moneyData
        local viewComponent = self:GetViewComponent()
        if moneyData == nil then
            local hpId = app.anniversary2019Mgr:GetHPGoodsId()
            moneyData = {moneyIdMap = {[tostring(hpId)] = checkint(hpId)}, isEnableGain = true}
        end
        viewComponent:UpdateMoneyBarGoodList(moneyData)

    elseif name == SGL.CACHE_MONEY_UPDATE_UI or name == SGL.REFRESH_NOT_CLOSE_GOODS_EVENT then -- 刷新顶部状态栏
        self:GetViewComponent():UpdateMoneyBarGoodNum()
    
    end
end

-------------------------------------------------
-- get / set

function Anniversary19ExploreMainMediator:GetViewData()
    return self.viewData_
end

function Anniversary19ExploreMainMediator:GetOwnerScene()
    return self.ownerScene_
end

-------------------------------------------------
-- public method
function Anniversary19ExploreMainMediator:EnterLayer()
    
    self:SendSignal(POST.ANNIVERSARY2_HOME.cmdName)
end

function Anniversary19ExploreMainMediator:RefreshUI()
    local viewComponent = self:GetViewComponent()
    -- viewComponent:InitPlotListView(self.plotDatas)

end

-------------------------------------------------
-- private method

-------------------------------------------------
-- check

-------------------------------------------------
-- handler

---OnClickBossHeadNodeAction
---点击boss头像事件
---@param sender userdata
function Anniversary19ExploreMainMediator:OnClickBossHeadNodeAction(sender)
    PlayAudioByClickNormal()

    local exploreModuleId = sender:getTag()
    local mgr             = app.anniversary2019Mgr
    local homeData        = mgr:GetHomeData()
    local explore         = homeData.explore or {}
    local exploreData     = explore[tostring(exploreModuleId)] or {}

    local bossLevel = math.max(checkint(exploreData.bossLevel), 1)
    local chapterConf = CommonUtils.GetConfig('anniversary2', 'chapter', exploreModuleId) or {}
    local bossId = chapterConf.bossId

    local bossConf = CommonUtils.GetConfig('anniversary2', 'boss', bossId) or {}
    local bossLevelData = bossConf[tostring(bossLevel + 1)]
    local nextBossLevelLeftDiscoveryTimes = checkint(exploreData.nextBossLevelLeftDiscoveryTimes)
    local viewTypeData
    if bossLevelData and nextBossLevelLeftDiscoveryTimes ~= 0 then
        local upgradeTotalCondition = checkint(bossLevelData.upgradeTotalCondition)
        -- BOSS下次升级剩余发现次数
        viewTypeData = {maxVal = upgradeTotalCondition, curVal = upgradeTotalCondition - nextBossLevelLeftDiscoveryTimes}
    else
        viewTypeData = {isFullLevel  = true}
    end
    
    app.uiMgr:ShowInformationTipsBoard({
        targetNode   = sender,
        bgSize       = cc.size(420, 250),
        type         = 17,
        title        = string.format(app.anniversary2019Mgr:GetPoText(__('当前Boss等级：%s')), bossLevel),
        descr        = tostring(chapterConf.dialogue),
        viewTypeData = viewTypeData,
    })
end

---OnClickExploreBtnAction
---点击探索按钮事件
---@param sender userdata
function Anniversary19ExploreMainMediator:OnClickExploreBtnAction(sender)
    if not self.isControllable_ then return end
    PlayAudioByClickNormal()

    local exploreModuleId = sender:getTag()
    local mgr             = app.anniversary2019Mgr
    local homeData        = mgr:GetHomeData()
    local explore         = homeData.explore or {}
    local exploreData     = explore[tostring(exploreModuleId)] or {}
    local exploring       = checkint(exploreData.exploring)

    local exploreConf = CommonUtils.GetConfig('anniversary2', 'explore', exploreModuleId) or {}
    if exploring <= 0 then
        -- 检查探索道具是否足够
        local goodsId    = app.anniversary2019Mgr:GetHPGoodsId()
        local ownNum     = CommonUtils.GetCacheProductNum(goodsId)
        local consumeNum = checkint(exploreConf.consumeNum)
        if ownNum < consumeNum then
            local goodsConfig = CommonUtils.GetConfig('goods', 'goods', goodsId) or {}
            app.uiMgr:ShowInformationTips(string.format(app.anniversary2019Mgr:GetPoText(__('%s不足')), tostring(goodsConfig.name)))
            return
        end
    end
    sender:setEnabled(false)
    local worldStory = exploreConf.worldStory
    app.anniversary2019Mgr:CheckStoryIsUnlocked(worldStory, function ()
        app:RetrieveMediator('Router'):Dispatch({name = 'HomeMediator'}, {name = 'anniversary19.Anniversary19DreamCircleMainMediator' , params = { exploreModuleId = exploreModuleId }})
    end)
end

---OnClickTaskBtnAction
---点击委托任务按钮事件
---@param sender userdata
function Anniversary19ExploreMainMediator:OnClickTaskBtnAction(sender)
    PlayAudioByClickNormal()
    local mediator = require("Game.mediator.anniversary19.Anniversary19ExploreTaskMediator").new()
    app:RegistMediator(mediator)    
end

---OnClickTaskBtnAction
---点击规则按钮事件
---@param sender userdata
function Anniversary19ExploreMainMediator:OnClickTitleBtnAction(sender)
    PlayAudioByClickNormal()

    app.uiMgr:ShowIntroPopup({moduleId = '-44'})
end

---OnClickTaskBtnAction
---点击返回键按钮事件
---@param sender userdata
function Anniversary19ExploreMainMediator:OnClickBackBtnAction(sender)
    if not self.isControllable_ then return end
    PlayAudioByClickClose()

    app:RetrieveMediator('Router'):Dispatch({name = 'HomeMediator'}, {name = 'anniversary19.Anniversary19HomeMediator'})
end

---OnClickTaskBtnAction
---点击刷新按钮事件
---@param sender userdata
function Anniversary19ExploreMainMediator:OnClickRefreshBtnAction(sender)
    PlayAudioByClickNormal()

    local parameterConf = CommonUtils.GetConfigAllMess('parameter', 'anniversary2') or {}
    local auguryConsume = parameterConf.auguryConsume or {}
    local auguryConsumeData = auguryConsume[1] or {}
    local consumeGoodsId = auguryConsumeData.goodsId
    local consumeNum = checkint(auguryConsumeData.num)

    local determineCb = function ()
        if consumeNum > CommonUtils.GetCacheProductNum(consumeGoodsId) then
            app.uiMgr:AddDialog("common.GainPopup", {goodId = consumeGoodsId})
            return
        end
        self:SendSignal(POST.ANNIVERSARY2_AUGURY.cmdName)
    end
    
    local dateText = string.format(app.anniversary2019Mgr:GetPoText(__('%s:00')), tostring(parameterConf.auguryRefreshTime))
    local goodConf = CommonUtils.GetConfig('goods', 'goods', consumeGoodsId) or {}
    local CommonTip  = require( 'common.CommonPopTip' ).new({
        title = "    "  ..string.format(app.anniversary2019Mgr:GetPoText(__('是否使用%s%s刷新占卜效果？')), consumeNum, tostring(goodConf.name)),
        text = "         "  .. string.format(app.anniversary2019Mgr:GetPoText(__('每日%s免费自动刷新')), dateText),
        textW = 330,
        callback = determineCb,
        priceData = {
            price = consumeNum,
            currencyId = consumeGoodsId,
        },
    })
    CommonTip:setPosition(display.center)
    display.commonLabelParams(CommonTip.textLabel, fontWithColor(15))
    self:GetOwnerScene():AddDialog(CommonTip)

end

function Anniversary19ExploreMainMediator:AugurySpineEndAction(event)
    local animation = event.animation
    if self.auguryId and string.find(animation, 'play') then
        self:GetViewComponent():UpdateAuguryDesc(self:GetViewData(), self.auguryId)

        self.auguryId = nil
    end
end

return Anniversary19ExploreMainMediator
