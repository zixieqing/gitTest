--[[
 * author : kaishiqi
 * descpt : 2020周年庆 - 主界面 中介者
]]
local Anniversary20HomeMediator = class('Anniversary20HomeMediator', mvc.Mediator)

function Anniversary20HomeMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'Anniversary20HomeMediator', viewComponent)
    local initArgs = checktable(params)
    self.ctorArgs_ = initArgs.requestData or {}
    self.homeArgs_ = initArgs
    self.homeArgs_.requestData = nil
end


-------------------------------------------------
-- life cycle
function Anniversary20HomeMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    self.isControllable_ = true

    -- create view
    self.ownerScene_ = app.uiMgr:SwitchToTargetScene('Game.views.anniversary20.Anniversary20HomeScene')
    self:SetViewComponent(self.ownerScene_)

    -- add listener
    self.homeRefreshClocker_ = app.timerMgr.CreateClocker(handler(self, self.onHomeRefreshUpdateHandler_))
    ui.bindClick(self:getViewData().backBtn, handler(self, self.onClickBackButtonHandler_))
    ui.bindClick(self:getViewData().titleBtn, handler(self, self.onClickTitleButtonHandler_))
    ui.bindClick(self:getViewData().storyBtn, handler(self, self.onClickStoryButtonHandler_))
    ui.bindClick(self:getViewData().drawBtn, handler(self, self.onClickDrawButtonHandler_))
    ui.bindClick(self:getViewData().shopBtn, handler(self, self.onClickShopButtonHandler_))
    ui.bindClick(self:getViewData().hangBtn, handler(self, self.onClickHangButtonHandler_))
    ui.bindClick(self:getViewData().puzzleBtn, handler(self, self.onClickPuzzleButtonHandler_))
    ui.bindClick(self:getViewData().exploreBtn, handler(self, self.onClickExploreButtonHandler_))

    -- update views
    self.isControllable_ = false
    self:getViewNode():showUI(function()
        self:initHomeData_(self.homeArgs_)
        self:updateShopLevelInfo_()
        self.isControllable_ = true
    end)
end


function Anniversary20HomeMediator:CleanupView()
    self.homeRefreshClocker_:stop()
end


function Anniversary20HomeMediator:OnRegist()
    app:DispatchObservers(HomeScene_ChangeCenterContainer, 'rightHide')
    app:DispatchObservers(HomeScene_ChangeCenterContainer, 'allhide')

    regPost(POST.ANNIV2020_MAIN_HOME)
    regPost(POST.ANNIV2020_EXPLORE_HOME)
    regPost(POST.ANNIV2020_EXPLORE_ENTER)
end


function Anniversary20HomeMediator:OnUnRegist()
    app:DispatchObservers(HomeScene_ChangeCenterContainer, 'rightShow')
    app:DispatchObservers(HomeScene_ChangeCenterContainer, 'hide')

    unregPost(POST.ANNIV2020_MAIN_HOME)
    unregPost(POST.ANNIV2020_EXPLORE_HOME)
    unregPost(POST.ANNIV2020_EXPLORE_ENTER)
end


function Anniversary20HomeMediator:InterestSignals()
    return {
        SGL.ANNIV2020_SHOP_UPGRADE,
        POST.ANNIV2020_MAIN_HOME.sglName,
        POST.ANNIV2020_EXPLORE_HOME.sglName,
        POST.ANNIV2020_EXPLORE_ENTER.sglName,
    }
end
function Anniversary20HomeMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    if name == POST.ANNIV2020_MAIN_HOME.sglName then
        self:initHomeData_(data)


    elseif name == POST.ANNIV2020_EXPLORE_HOME.sglName then
        -- update exploreMainData
        app.anniv2020Mgr:updateExploreMainData(data)
        
        if app.anniv2020Mgr:getExploringId() > 0 then
            self:SendSignal(POST.ANNIV2020_EXPLORE_ENTER.cmdName, {exploreModuleId = app.anniv2020Mgr:getExploringId()})
        else
            app.router:Dispatch({name = 'anniversary20.Anniversary20HomeMediator'}, {name = 'anniversary20.Anniversary20ExploreMainMediator'})
        end
        
        
    elseif name == POST.ANNIV2020_EXPLORE_ENTER.sglName then
        -- update exploreHomeData
        app.anniv2020Mgr:updateExploreHomeData(data)

        -- to exploreHome
        app.router:Dispatch({name = 'anniversary20.Anniversary20HomeMediator'}, {name = 'anniversary20.Anniversary20ExploreHomeMediator'})


    elseif name == SGL.ANNIV2020_SHOP_UPGRADE then
        self:updateShopLevelInfo_()
    end
end


-------------------------------------------------
-- get / set

function Anniversary20HomeMediator:getViewNode()
    return self.ownerScene_
end
function Anniversary20HomeMediator:getViewData()
    return self:getViewNode():getViewData()
end


-------------------------------------------------
-- public

function Anniversary20HomeMediator:close()
    app:UnRegsitMediator(self:GetMediatorName())

    -- back to homeMdt
    local backMdtName = self.ctorArgs_.backMediatorName or 'HomeMediator'
    app.router:Dispatch({name = 'anniversary20.Anniversary20HomeMediator'}, {name = backMdtName})

    -- clean spineCache
    app.anniv2020Mgr:cleanAllSpineCache()
end


-------------------------------------------------
-- private

function Anniversary20HomeMediator:initHomeData_(homeData)
    app.anniv2020Mgr:setHomeData(homeData)

    -- start homeRefreshClocker
    self.homeRefreshClocker_:start()
end


function Anniversary20HomeMediator:updateShopLevelInfo_()
    local level  = app.anniv2020Mgr:getShopLevel()
    local nowExp = app.anniv2020Mgr:getShopExp()
    local minExp = 0
    local maxExp = 0

    if app.anniv2020Mgr:isShopMaxLevel() then
        maxExp = nowExp
    else
        for _, levelConf in pairs(CONF.ANNIV2020.MALL_LEVEL:GetAll()) do
            if checkint(levelConf.level) == level then
                minExp = checkint(levelConf.totalExp)
            end
            if checkint(levelConf.level) == level + 1 then
                maxExp = checkint(levelConf.totalExp)
            end
        end
    end
    self:getViewNode():updateShopExpProgress(minExp, maxExp, nowExp, level)
end


-------------------------------------------------
-- handler

function Anniversary20HomeMediator:onClickBackButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    self:close()
end


function Anniversary20HomeMediator:onClickTitleButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    app.uiMgr:ShowIntroPopup({moduleId = MODULE_DATA.ANNIVERSARY20})
end


function Anniversary20HomeMediator:onClickDrawButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    if app.anniv2020Mgr:isClosed() then
        app.uiMgr:ShowInformationTips(__('当前活动已结束'))
        return
    end

    local goodsId  = app.anniv2020Mgr:getHpGoodsId()
    local buyHpNum = app.activityHpMgr:GetHpBuyOnceNum(goodsId)
    app.uiMgr:AddDialog('Game.views.AddPowerPopup', {payId = goodsId, callback = function()
        local countdownName  = CommonUtils.getCurrencyRestoreKeyByGoodsId(goodsId)
        local countdownTimer = app.timerMgr:RetriveTimer(countdownName)
        if countdownTimer and checkint(countdownTimer.countdown) > 0 then
            app.uiMgr:ShowInformationTips(string.fmt(__('距离领取还剩_time_秒'), {_time_ = checkint(countdownTimer.countdown)}))
        else
            local hpPurchaseCmd = app.activityHpMgr:GetHpPurchaseCmd(goodsId)
            app.httpMgr:Post(hpPurchaseCmd.postUrl, hpPurchaseCmd.sglName)
        end
    end, goodsNum = checkint(buyHpNum), totalBuyLimit = -1})
end


function Anniversary20HomeMediator:onClickStoryButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local storyMdt = require('Game.mediator.anniversary20.Anniversary20StoryMediator').new()
    app:RegistMediator(storyMdt)
end


function Anniversary20HomeMediator:onClickShopButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local shopMdt = require('Game.mediator.anniversary20.Anniversary20ShopMediator').new()
    app:RegistMediator(shopMdt)
end


function Anniversary20HomeMediator:onClickExploreButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    if app.anniv2020Mgr:isClosed() then
        app.uiMgr:ShowInformationTips(__('当前活动已结束'))
        return
    end

    app.anniv2020Mgr:checkPlayExploreOpenStory(function()
        self:SendSignal(POST.ANNIV2020_EXPLORE_HOME.cmdName)
    end)
end


function Anniversary20HomeMediator:onClickPuzzleButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    app.anniv2020Mgr:checkPlayPuzzleStory(function()
        local puzzleMdt = require('Game.mediator.anniversary20.Anniversary20PuzzleMediator').new()
        app:RegistMediator(puzzleMdt)
    end)
end


function Anniversary20HomeMediator:onClickHangButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    app.anniv2020Mgr:checkPlayHangOpenStory(function()
        local hangMdt = require('Game.mediator.anniversary20.Anniversary20HangMediator').new()
        app:RegistMediator(hangMdt)
    end)
end


function Anniversary20HomeMediator:onHomeRefreshUpdateHandler_()
    
    -- update hpTime
    local hpGoodsId      = app.anniv2020Mgr:getHpGoodsId()
    local countdownName  = CommonUtils.getCurrencyRestoreKeyByGoodsId(hpGoodsId)
    local countdownTimer = app.timerMgr:RetriveTimer(countdownName)
    local leftSeconds    = countdownTimer and countdownTimer.countdown or 0
    self:getViewNode():updateDrawHpTime(leftSeconds)
    
    
    -- update hangTime
    local currentTime = os.time()
    local refreshTime = app.anniv2020Mgr:getHangingTimestamp()
    local leftSeconds = refreshTime - currentTime
    self:getViewNode():updateOpenChestTime(leftSeconds)
end


return Anniversary20HomeMediator
