--[[
 * author : kaishiqi
 * descpt : 爬塔 - 准备界面中介者
]]
local TowerModelFactory       = require('Game.models.TowerQuestModelFactory')
local TowerQuestModel         = TowerModelFactory.getModelType('TowerQuest')
local UnitDefineModel         = TowerModelFactory.getModelType('UnitDefine')
local TowerQuestReadyView     = require('Game.views.TowerQuestReadyView')
local EditCardLibraryMediator = require('Game.mediator.TowerQuestEditCardLibraryMediator')
local TowerQuestReadyMediator = class('TowerQuestReadyMediator', mvc.Mediator)

function TowerQuestReadyMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'TowerQuestReadyMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance method

function TowerQuestReadyMediator:Initial(key)
    self.super.Initial(self, key)

    local isIgnoreShowView = self.ctorArgs_.isIgnoreShowView == true
    self.towerHomeMdt_     = self:GetFacade():RetrieveMediator('TowerQuestHomeMediator')
    self.isControllable_   = true
    self.isSweepEnter_     = false

    -- create view
    local homeScene = self.towerHomeMdt_:getHomeScene()
    self.readyView_ = TowerQuestReadyView.new()
	homeScene:AddGameLayer(self.readyView_)

    -- editCardLibrary mediator
    local towerModel  = self.towerHomeMdt_:getTowerModel()
    local cardLibrary = towerModel:getCardLibrary()
    self.editCardLibraryMdt_ = EditCardLibraryMediator.new({selectedCards = clone(cardLibrary), isIgnoreShowView = isIgnoreShowView})
    self:GetFacade():RegistMediator(self.editCardLibraryMdt_)
    
    -- init view
    local readyViewData = self.readyView_:getViewData()
    display.commonUIParams(readyViewData.editBar, {cb = handler(self, self.onClickEditBarHandler_)})
    display.commonUIParams(readyViewData.enterBtn, {cb = handler(self, self.onClickEnterButtonHandler_)})

    -- update view
    self:updateCardLibrary_()
    self:updateEnterLeftTimes_()

    -- show ui
    self.isControllable_ = false
    if not isIgnoreShowView then
        self:showUI(nil, true)
    end
end


function TowerQuestReadyMediator:CleanupView()
    if self.readyView_ then
        local homeScene = self.towerHomeMdt_:getHomeScene()
        homeScene:RemoveGameLayer(self.readyView_)
        self.readyView_ = nil
    end
    if self.editCardLibraryMdt_ then
        self.editCardLibraryMdt_:close()
        self.editCardLibraryMdt_ = nil
    end
end


function TowerQuestReadyMediator:OnRegist()
    regPost(POST.TOWER_ENTER)
end
function TowerQuestReadyMediator:OnUnRegist()
    unregPost(POST.TOWER_ENTER)
end


function TowerQuestReadyMediator:InterestSignals()
    return {
        POST.TOWER_ENTER.sglName,
        SGL.TOWER_QUEST_SET_CARD_LIBRARY,
        SGL.TOWER_QUEST_MODEL_CARD_LIBRARY_CHANGE,
        SGL.TOWER_QUEST_MODEL_ENTER_LEFT_TIMES_CHANGE,
    }
end
function TowerQuestReadyMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    if name == SGL.TOWER_QUEST_SET_CARD_LIBRARY then
        local towerModel = self.towerHomeMdt_:getTowerModel()
        towerModel:setCardLibrary(data.cardList)
        towerModel:setCacheCardLibrary(table.concat(data.cardList, ','))


    elseif name == POST.TOWER_ENTER.sglName then
        local towerModel = self.towerHomeMdt_:getTowerModel()

        local unitDefineData  = checktable(data.unitDefine)
        local unitDefineModel = UnitDefineModel.new()
        if next(unitDefineData) then
            unitDefineModel:setUnitId(checkint(unitDefineData.unitId))
            unitDefineModel:setChestRewardsMap(checktable(unitDefineData.unitChest))
            unitDefineModel:setContractIdList(checktable(unitDefineData.unitContracts))
        end
        towerModel:setUnitDefineModel(unitDefineModel)

        towerModel:setEnterLeftTimes(towerModel:getEnterLeftTimes() - 1)

        if self.isSweepEnter_ then
            -- show reward popup
            local uiManager = self:GetFacade():GetManager('UIManager')
            uiManager:AddDialog('common.RewardPopup', {
                rewards       = checktable(data.rewards),
                closeCallback = function()
                    -- 不能立刻执行切界面，会闪退，所以delay执行
                    self.isControllable_ = false
                    scheduler.performWithDelayGlobal(function()
                        local towerModel = self.towerHomeMdt_:getTowerModel()
                        towerModel:setCurrentFloor(towerModel:getSweepFloor() + 1)
                        towerModel:setTowerEntered(true)  -- to map mediator
                    end, 0.5)
                end
            })
        else
            towerModel:setCurrentFloor(1)
            towerModel:setTowerEntered(true)  -- to map mediator
        end


    elseif name == SGL.TOWER_QUEST_MODEL_ENTER_LEFT_TIMES_CHANGE then
        self:updateEnterLeftTimes_()


    elseif name == SGL.TOWER_QUEST_MODEL_CARD_LIBRARY_CHANGE then
        self:updateCardLibrary_()


    end
end


-------------------------------------------------
-- public method

function TowerQuestReadyMediator:showUI(endCB, isOnlyShowUI)
    self.readyView_:showUI(function()
        self.isControllable_ = true
        if endCB then endCB() end
    end)
    if not isOnlyShowUI then
        self.editCardLibraryMdt_:showUI()
    end
end


-------------------------------------------------
-- private method

function TowerQuestReadyMediator:updateEnterLeftTimes_()
    local towerModel    = self.towerHomeMdt_:getTowerModel()
    local readyViewData = self.readyView_:getViewData()
    local leftTimesText = string.fmt(__('今日剩余次数：_num_'), {_num_ = towerModel:getEnterLeftTimes()})
    display.commonLabelParams(readyViewData.timesBar, {text = leftTimesText ,reqW = 250 })

    self:updateEnterButtonStatus_()
end


function TowerQuestReadyMediator:updateCardLibrary_()
    local readyViewData = self.readyView_:getViewData()
    local towerModel    = self.towerHomeMdt_:getTowerModel()
    local cardLibrary   = towerModel:getCardLibrary()

    if table.nums(cardLibrary) > 0 then
        readyViewData.editLayer:setVisible(false)
    else
        readyViewData.editLayer:setVisible(true)
    end

    self:updateEnterButtonStatus_()
end


function TowerQuestReadyMediator:updateEnterButtonStatus_()
    local readyViewData      = self.readyView_:getViewData()
    local towerModel         = self.towerHomeMdt_:getTowerModel()
    local cardLibraryLen     = table.nums(towerModel:getCardLibrary())
    local isLibraryEnough    = cardLibraryLen >= TowerQuestModel.LIBRARY_CARD_MIN and cardLibraryLen <= TowerQuestModel.LIBRARY_CARD_MAX
    local isEnterTimesEnough = towerModel:getEnterLeftTimes() > 0
    readyViewData.enterBtn:setEnabled(isLibraryEnough and isEnterTimesEnough)
end


function TowerQuestReadyMediator:showEditCardLibraryLayer_()
    self.editCardLibraryMdt_:toEditStatus()
end


-------------------------------------------------
-- handler

function TowerQuestReadyMediator:onClickEnterButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end
    
    local towerModel = self.towerHomeMdt_:getTowerModel()
    if towerModel:getSweepFloor() > 0 then
        local homeScene = self.towerHomeMdt_:getHomeScene()
        local commonTip = require('common.CommonTip').new({
            text       = string.fmt(__('是否扫荡邪神遗迹到达_num_层？'), {_num_ = towerModel:getSweepFloor()}),
            descr      = string.fmt(__('扫荡进入可获得_num_层之前所有的满签契约奖励'), {_num_ = towerModel:getSweepFloor()}),
            useAllText = __('直接进入'),
            useOneText = __('扫荡进入'),
            callback   = function()
                self.isSweepEnter_ = true
                self:SendSignal(POST.TOWER_ENTER.cmdName, {isSweep = 1})
            end,
            cancelBack = function()
                self.isSweepEnter_ = false
                self:SendSignal(POST.TOWER_ENTER.cmdName, {isSweep = 0})
            end
        })
        commonTip:setPosition(display.center)
        homeScene:AddDialog(commonTip, 10)

    else
        self.isSweepEnter_ = false
        self:SendSignal(POST.TOWER_ENTER.cmdName, {isSweep = 0})
    end

    self.isControllable_ = false
    transition.execute(self.readyView_, nil, {delay = 0.3, complete = function()
        self.isControllable_ = true
    end})
end


function TowerQuestReadyMediator:onClickEditBarHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end
    self:showEditCardLibraryLayer_()
end


return TowerQuestReadyMediator
