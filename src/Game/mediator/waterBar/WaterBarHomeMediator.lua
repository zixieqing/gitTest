--[[
 * author : kaishiqi
 * descpt : 水吧 - 主界面中介者
]]
local WaterBarHomeMediator = class('WaterBarHomeMediator', mvc.Mediator)

function WaterBarHomeMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'waterBar.WaterBarHomeMediator', viewComponent)  -- 因为用了 app:BackMediator 所以这里名字需要携带路径
    local initArgs = checktable(params)
    self.ctorArgs_ = initArgs.requestData or {}
    self.homeArgs_ = initArgs
    self.homeArgs_.requestData = nil
end


-------------------------------------------------
-- life cycle
function WaterBarHomeMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    self.isControllable_ = true

    -- create view
    self.viewDode_ = app.uiMgr:SwitchToTargetScene('Game.views.waterBar.WaterBarHomeScene')
    self:SetViewComponent(self:getViewNode())

    -- add listener
    local brewViewData = self:getViewNode():getBrewViewData()
    self.statusRefreshClocker_ = app.timerMgr.CreateClocker(handler(self, self.onStatusRefreshUpdateHandler_))
    display.commonUIParams(self:getViewData().backBtn, {cb = handler(self, self.onClickBackButtonHandler_)})
    display.commonUIParams(self:getViewData().titleBtn, {cb = handler(self, self.onClickTitleButtonHandler_)})
    display.commonUIParams(self:getViewData().brewBtn, {cb = handler(self, self.onClickBrewButtonHandler_)})
    display.commonUIParams(self:getViewData().infoBtn, {cb = handler(self, self.onClickInfoButtonHandler_)})
    display.commonUIParams(self:getViewData().storeBtn, {cb = handler(self, self.onClickStoreButtonHandler_)})
    display.commonUIParams(self:getViewData().marketBtn, {cb = handler(self, self.onClickMarketButtonHandler_)})
    display.commonUIParams(self:getViewData().putawayBtn, {cb = handler(self, self.onClickPutawayButtonHandler_)})
    display.commonUIParams(self:getViewData().customersBtn, {cb = handler(self, self.onClickCustomersButtonHandler_)})
    display.commonUIParams(brewViewData.blockLayer, {cb = handler(self, self.onClickBrewBlockButtonHandler_), animate = false})
    display.commonUIParams(brewViewData.researchBtn, {cb = handler(self, self.onClickResearchButtonHandler_)})
    display.commonUIParams(brewViewData.makeBtn, {cb = handler(self, self.onClickMakeButtonHandler_)})
    for _, customerCell in ipairs(self:getViewData().customerCellList) do
        display.commonUIParams(customerCell, {cb = handler(self, self.onClickServeCustomerCellHandler_), animate = false})
    end
    ui.bindClick(self:getViewData().bagBtn, handler(self, self.onClickBagButtonHandler_))

    self:initHomeData_(self.homeArgs_)

    -- 检测回头客奖励领取红点
    app.badgeMgr:CheckHasFrequencyPointRewards()

    -- update views
    self.isControllable_ = false
    self:getViewNode():showUI(function()
        self.isControllable_ = true
    end)
end


function WaterBarHomeMediator:CleanupView()
    self.statusRefreshClocker_:stop()
end


function WaterBarHomeMediator:OnRegist()
    app:DispatchObservers(HomeScene_ChangeCenterContainer, 'rightHide')
    app:DispatchObservers(HomeScene_ChangeCenterContainer, 'allhide')

    regPost(POST.WATER_BAR_HOME)
end


function WaterBarHomeMediator:OnUnRegist()
    app:DispatchObservers(HomeScene_ChangeCenterContainer, 'rightShow')
    app:DispatchObservers(HomeScene_ChangeCenterContainer, 'hide')

    unregPost(POST.WATER_BAR_HOME)
end


function WaterBarHomeMediator:InterestSignals()
    return {
        POST.WATER_BAR_HOME.sglName
    }
end
function WaterBarHomeMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    -------------------------------------------------
    -- waterBar home
    if name == POST.WATER_BAR_HOME.sglName then
        self:initHomeData_(data)
    end
end


-------------------------------------------------
-- get / set

function WaterBarHomeMediator:getViewNode()
    return self.viewDode_
end
function WaterBarHomeMediator:getViewData()
    return self:getViewNode():getViewData()
end


-------------------------------------------------
-- public

function WaterBarHomeMediator:close()
    self:GetFacade():UnRegsitMediator(self:GetMediatorName())

    -- back to homeLandMdt
    app.router:Dispatch({name = 'waterBar.WaterBarHomeMediator'}, {name = 'HomelandMediator'})
end


function WaterBarHomeMediator:closeAllMdt()
    app:BackMediator(self:GetMediatorName())
end


-------------------------------------------------
-- private

function WaterBarHomeMediator:initHomeData_(homeData)
    -- init homeData
    app.waterBarMgr:setHomeData(homeData)

    -- re-start stausRefreshClocker
    self.statusRefreshClocker_:start()

    -- popup BusinessRewa
    if app.waterBarMgr:hasBusinessRewards() then
        app.uiMgr:AddDialog('Game.views.waterBar.WaterBarBusinessPopup')
    end

    -- update homeState
    self:getViewNode():updateStatus()

    -- udate all serveCustomer
    local allCustomerData = app.waterBarMgr:getAllServeCustomers()
    local allDrinkIdList  = {}
    for drinkId, drinkNum in pairs(app.waterBarMgr:getAllPutaways() or {}) do
        if checkint(drinkNum) > 0 then
            table.insert(allDrinkIdList, drinkId)
        end
    end
    local allDrinkLegnth  = #allDrinkIdList
    for index = 1, FOOD.WATER_BAR.DEFINE.CUSTOMER_BAR_MAX do
        if app.waterBarMgr:isHomeOpening() then
            local customerId = allCustomerData[index] and allCustomerData[index].customerId or 0
            local storyId    = allCustomerData[index] and allCustomerData[index].storyId or 0
            local drinkId    = allDrinkLegnth > 0 and allDrinkIdList[math.random(allDrinkLegnth)] or 0
            self:getViewNode():updateServeCustomer(index, customerId, drinkId, storyId)
        else
            self:getViewNode():updateServeCustomer(index, 0, 0, 0)
        end
    end
end


-------------------------------------------------
-- handler

function WaterBarHomeMediator:onStatusRefreshUpdateHandler_()
    local currentTime = os.time()
    local refreshTime = app.waterBarMgr:getHomeTimestamp()
    local leftSeconds = refreshTime - currentTime
    
    if leftSeconds >= 0 then
        self:getViewNode():updateLeftSeconds(leftSeconds)
    else
        self:closeAllMdt()
        self.statusRefreshClocker_:stop()
        self:SendSignal(POST.WATER_BAR_HOME.cmdName)
    end
end


function WaterBarHomeMediator:onClickBackButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    -- close
    self:close()
end


function WaterBarHomeMediator:onClickTitleButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    app.uiMgr:ShowIntroPopup({moduleId = MODULE_DATA[tostring(RemindTag.WATER_BAR)]})
end


function WaterBarHomeMediator:onClickCustomersButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end
    local meditaor = require("Game.mediator.waterBar.WaterBarReturnCustomerMediator").new()
    self:GetFacade():RegistMediator(meditaor)
end


function WaterBarHomeMediator:onClickStoreButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local waterBarStoreMdt = require("Game.mediator.waterBar.WaterBarShopMediator").new()
    self:GetFacade():RegistMediator(waterBarStoreMdt)
end


function WaterBarHomeMediator:onClickBrewButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    self.isControllable_ = false
    self:getViewNode():showBrewView(function()
        self.isControllable_ = true
    end)
end


function WaterBarHomeMediator:onClickPutawayButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local waterBarPutawayMdt = require('Game.mediator.waterBar.WaterBarPutawayMediator').new()
    app:RegistMediator(waterBarPutawayMdt)
end


function WaterBarHomeMediator:onClickInfoButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local waterBarInfoMdt = require('Game.mediator.waterBar.WaterBarInfoMediator').new()
    app:RegistMediator(waterBarInfoMdt)
end


function WaterBarHomeMediator:onClickMarketButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local waterBarMarketMdt = require('Game.mediator.waterBar.WaterBarMarketMediator').new()
    app:RegistMediator(waterBarMarketMdt)
end


function WaterBarHomeMediator:onClickBagButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local backpack = require('Game.views.waterBar.WaterBarBackpackPopup').new()
    app.uiMgr:GetCurrentScene():AddDialog(backpack)
end


function WaterBarHomeMediator:onClickBrewBlockButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    self.isControllable_ = false
    self:getViewNode():hideBrewView(function()
        self.isControllable_ = true
    end)
end


function WaterBarHomeMediator:onClickResearchButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    if not app.waterBarMgr:GetIsUnLockFreeDev() then
        app.uiMgr:ShowInformationTips(string.fmt(__('自由调制功能在水吧_num_级时解锁') , {_num_ =  FOOD.WATER_BAR.UNLCOK_LEVEL.FREE_DEV}))
        return
    end

    self.isControllable_ = false
    self:getViewNode():hideBrewView(function()
        self.isControllable_ = true
        local mediator = require("Game.mediator.waterBar.WaterBarDeployFormulaMediator").new({
            developWay = 1
        })
        app:RegistMediator(mediator)
    end)
end


function WaterBarHomeMediator:onClickMakeButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    self.isControllable_ = false
    self:getViewNode():hideBrewView(function()
        self.isControllable_ = true
        local mediator = require("Game.mediator.waterBar.WaterBarMenuFormulaMediator").new()
        app:RegistMediator(mediator)

    end)
end


function WaterBarHomeMediator:onClickServeCustomerCellHandler_(sender)
    if not self.isControllable_ then return end
    
    local storyId = checkint(sender:getTag())
    if storyId > 0 then
        PlayAudioByClickNormal()

        -- mark trigger story
        if not app.waterBarMgr:isUserStoryTrigger(storyId) then
            app.waterBarMgr:saveUserStoryTrigger(storyId)
            self:getViewNode():updateServeCustomerStoryIcon(sender)
        end
        
        local storyPath  = string.format('conf/%s/bar/customerStory.json', i18n.getLang())
        local operaStage = require( "Frame.Opera.OperaStage" ).new({path = storyPath, id = storyId, isHideBackBtn = true, cb = function()
        end})
		operaStage:setName('operaStage')
		display.commonUIParams(operaStage, {po = display.center})
		sceneWorld:addChild(operaStage, GameSceneTag.Dialog_GameSceneTag)
    end
end


return WaterBarHomeMediator
