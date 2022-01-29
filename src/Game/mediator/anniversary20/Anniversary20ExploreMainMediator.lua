--[[
 * author : kaishiqi
 * descpt : 2020周年庆 - 探索入口 中介者
]]
local Anniversary20ExploreMainScene    = require('Game.views.anniversary20.Anniversary20ExploreMainScene')
local Anniversary20ExploreMainMediator = class('Anniversary20ExploreMainMediator', mvc.Mediator)

function Anniversary20ExploreMainMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'Anniversary20ExploreMainMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end

local ENTRANCE_STATUE = Anniversary20ExploreMainScene.ENTRANCE_STATUE

-------------------------------------------------
-- inheritance

function Anniversary20ExploreMainMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    self.unlockedProgress_ = 1
    self.isControllable_   = true

    -- create view
    self.ownerScene_ = app.uiMgr:SwitchToTargetScene('Game.views.anniversary20.Anniversary20ExploreMainScene')
    self:SetViewComponent(self.ownerScene_)

    -- add listener
    ui.bindClick(self:getViewData().backBtn, handler(self, self.onClickBackButtonHandler_))
    ui.bindClick(self:getViewData().titleBtn, handler(self, self.onClickTitleButtonHandler_))
    ui.bindClick(self:getViewData().sweepBtn, handler(self, self.onClickSweepButtonHandler_))
    for _, entranceBtn in ipairs(self:getViewData().entranceBtns) do
        ui.bindClick(entranceBtn, handler(self, self.onClickEntranceButtonHandler_))
    end

    -- update views
    self.isControllable_ = false
    self:getViewNode():showUI(function()
        self.isControllable_ = true
    end)
    self:initHomeData_()
end


function Anniversary20ExploreMainMediator:CleanupView()
end


function Anniversary20ExploreMainMediator:OnRegist()
    app:DispatchObservers(HomeScene_ChangeCenterContainer, 'rightHide')
    app:DispatchObservers(HomeScene_ChangeCenterContainer, 'allhide')

    regPost(POST.ANNIV2020_EXPLORE_HOME)
    regPost(POST.ANNIV2020_EXPLORE_ENTER)

    if self.ctorArgs_.needRefresh then
        self:SendSignal(POST.ANNIV2020_EXPLORE_HOME.cmdName)
    end
end


function Anniversary20ExploreMainMediator:OnUnRegist()
    app:DispatchObservers(HomeScene_ChangeCenterContainer, 'rightShow')
    app:DispatchObservers(HomeScene_ChangeCenterContainer, 'hide')

    unregPost(POST.ANNIV2020_EXPLORE_HOME)
    unregPost(POST.ANNIV2020_EXPLORE_ENTER)
end


function Anniversary20ExploreMainMediator:InterestSignals()
    return {
        POST.ANNIV2020_EXPLORE_HOME.sglName,
        POST.ANNIV2020_EXPLORE_ENTER.sglName,
    }
end
function Anniversary20ExploreMainMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    if name == POST.ANNIV2020_EXPLORE_HOME.sglName then
        app.anniv2020Mgr:updateExploreMainData(data)
        self:initHomeData_()


    elseif name == POST.ANNIV2020_EXPLORE_ENTER.sglName then
        -- upate cost
        local exploreConf = checktable(CONF.ANNIV2020.EXPLORE_ENTRANCE:GetValue(app.anniv2020Mgr:getExploringId()))
        CommonUtils.DrawRewards({
            {goodsId = app.anniv2020Mgr:getHpGoodsId(), num = -checkint(exploreConf.consumeNum)}
        })
        
        -- update exploreHomeData
        app.anniv2020Mgr:updateExploreHomeData(data)

        -- to exploreHome
        app.router:Dispatch({name = 'anniversary20.Anniversary20ExploreMainMediator'}, {name = 'anniversary20.Anniversary20ExploreHomeMediator'})
    end
end


-------------------------------------------------
-- get / set

function Anniversary20ExploreMainMediator:getViewNode()
    return  self.ownerScene_
end
function Anniversary20ExploreMainMediator:getViewData()
    return self:getViewNode():getViewData()
end


-------------------------------------------------
-- public

function Anniversary20ExploreMainMediator:close()
    app.router:Dispatch({name = 'anniversary20.Anniversary20ExploreMainMediator'}, {name = 'anniversary20.Anniversary20HomeMediator'})
end


-------------------------------------------------
-- private

function Anniversary20ExploreMainMediator:initHomeData_()
    -- update unlocked progress
    self.unlockedProgress_ = 1
    for _, exploreData in ipairs(app.anniv2020Mgr:getExploreEntranceDatas()) do
        if checkint(exploreData.maxFloor) >= FOOD.ANNIV2020.DEFINE.EXPLORE_FLOOR_MAX then
            self.unlockedProgress_ = math.max(self.unlockedProgress_, checkint(exploreData.exploreModuleId) + 1)
        end
    end

    -- refresh status
    self:updateEntrancesStates_()
end


function Anniversary20ExploreMainMediator:updateEntrancesStates_()
    for moduleId, entranceBtn in ipairs(self:getViewData().entranceBtns) do
        if moduleId == self.unlockedProgress_ then
            -- 检测是否第一次解锁
            local localDefine = LOCAL.ANNIV2020.EXPLORE_CHAPTER_OPEN_PROGRESS()
            if localDefine:Load() + 1 == moduleId then
                -- update cache
                localDefine:Save(moduleId)
                
                -- do animation
                self.isControllable_ = false
                self:getViewNode():updateEntranceStatus(entranceBtn, ENTRANCE_STATUE.UNLOCKING, {unlockedCB = function()
                    self.isControllable_ = true
                end})
                
            -- 已解锁
            else
                self:getViewNode():updateEntranceStatus(entranceBtn, ENTRANCE_STATUE.UNLOCKED)
            end

        -- 未解锁
        elseif moduleId > self.unlockedProgress_ then
            self:getViewNode():updateEntranceStatus(entranceBtn, ENTRANCE_STATUE.LOCKED)

        -- 已通关
        elseif moduleId < self.unlockedProgress_ then
            self:getViewNode():updateEntranceStatus(entranceBtn, ENTRANCE_STATUE.PASSED)
        end
    end
end


-------------------------------------------------
-- handler

function Anniversary20ExploreMainMediator:onClickBackButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    self:close()
end


function Anniversary20ExploreMainMediator:onClickTitleButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    app.uiMgr:ShowIntroPopup({moduleId = MODULE_DATA.ANNIV20_EXPLORE})
end


function Anniversary20ExploreMainMediator:onClickEntranceButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    -- check exploreModuleId is unlock
    local exploreModuleId = checkint(sender:getTag())
    if exploreModuleId > self.unlockedProgress_ then
        app.uiMgr:ShowInformationTips(__('请先通关前面的梦境吧'))
        return 
    end
    
    -- check conf is null
    local exploreConf = CONF.ANNIV2020.EXPLORE_ENTRANCE:GetValue(exploreModuleId)
    if not exploreConf then
        return
    end

    -- check hpGoodsNum
    if app.goodsMgr:getGoodsNum(app.anniv2020Mgr:getHpGoodsId()) < checkint(exploreConf.consumeNum) then
        app.uiMgr:ShowInformationTips(string.fmt(__('_name_不足'), {_name_ = GoodsUtils.GetGoodsNameById(app.anniv2020Mgr:getHpGoodsId())}))
        return
    end

    local storyEndCallBack = function()
        -- save exploringId
        app.anniv2020Mgr:setExploringId(exploreModuleId)

        -- send signal to go home
        self:SendSignal(POST.ANNIV2020_EXPLORE_ENTER.cmdName, {exploreModuleId = app.anniv2020Mgr:getExploringId()})
    end

    local storyId = checkint(exploreConf.firstStory)
    if app.anniv2020Mgr:isStoryUnlocked(storyId) then
        storyEndCallBack()
    else
        app.anniv2020Mgr:toUnlockStory(storyId, function()
            app.anniv2020Mgr:playStory(storyId, storyEndCallBack)
        end)
    end
end


function Anniversary20ExploreMainMediator:onClickSweepButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local exploreSweepMediator = require('Game.mediator.anniversary20.Anniversary20SweepMediator').new()
	app:RegistMediator(exploreSweepMediator)
end


return Anniversary20ExploreMainMediator
