--[[
 * author : kaishiqi
 * descpt : 酒吧 - 剧情回顾 中介者
]]
local PlotCollectWaterBarStoryView     = require('Game.views.plotCollect.PlotCollectWaterBarStoryView')
local PlotCollectWaterBarStoryMediator = class('PlotCollectWaterBarStoryMediator', mvc.Mediator)

function PlotCollectWaterBarStoryMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'PlotCollectWaterBarStoryMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance

function PlotCollectWaterBarStoryMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    self.allStoryDataMap_ = {}
    self.unlockStoryMap_  = {}
    self.isControllable_  = true

    -- create view
    self.viewNode_ = PlotCollectWaterBarStoryView.new()
    self:SetViewComponent(self:getViewNode())
    app.uiMgr:GetCurrentScene():AddDialog(self:getViewNode())

    -- add listener
    ui.bindClick(self:getViewData().blockLayer, handler(self, self.onClickCloseButtonHandler_))
    self:getViewData().customerTableView:setCellUpdateHandler(handler(self, self.onUpdateCustomerCellHandler_))
    self:getViewData().customerTableView:setCellInitHandler(function(cellViewData)
        ui.bindClick(cellViewData.clickArea, handler(self, self.onClickCustomerCellHandler_))
    end)
    self:getViewData().storyTableView:setCellUpdateHandler(handler(self, self.onUpdateStoryCellHandler_))
    self:getViewData().storyTableView:setCellInitHandler(function(cellViewData)
        ui.bindClick(cellViewData.clickArea, handler(self, self.onClickStoryCellHandler_))
    end)

    -- init data
    self:setCustomerIdList(CONF.BAR.CUSTOMER:GetIdListUp())
end


function PlotCollectWaterBarStoryMediator:CleanupView()
    if self:getViewNode() and not tolua.isnull(self:getViewNode()) then
        self:getViewNode():removeFromParent()
        self.viewNode_ = nil
    end
end


function PlotCollectWaterBarStoryMediator:OnRegist()
    regPost(POST.WATER_BAR_CUSTOMER_STORY)

    self:SendSignal(POST.WATER_BAR_CUSTOMER_STORY.cmdName)
end


function PlotCollectWaterBarStoryMediator:OnUnRegist()
    unregPost(POST.WATER_BAR_CUSTOMER_STORY)
end


function PlotCollectWaterBarStoryMediator:InterestSignals()
    return {
        POST.WATER_BAR_CUSTOMER_STORY.sglName
    }
end
function PlotCollectWaterBarStoryMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    if name == POST.WATER_BAR_CUSTOMER_STORY.sglName then
        self.unlockStoryMap_  = checktable(data.customerMap)
        self.allStoryDataMap_ = {}
        
        -- update all count
        for _, cell in pairs(self:getViewData().customerTableView:getCellViewDataDict()) do
            self:getViewData().customerTableView:updateCellViewData(cell.clickArea:getTag(), nil, 'count')
        end

        -- auto select 1
        self:setSelectCustomerIndex(1)
    end
end


-------------------------------------------------
-- get / set

function PlotCollectWaterBarStoryMediator:getViewNode()
    return  self.viewNode_
end
function PlotCollectWaterBarStoryMediator:getViewData()
    return self:getViewNode():getViewData()
end


function PlotCollectWaterBarStoryMediator:getCustomerIdList()
    return checktable(self.customerIdList_)
end
function PlotCollectWaterBarStoryMediator:setCustomerIdList(idList)
    self.customerIdList_ = checktable(idList)
    self:getViewData().customerTableView:resetCellCount(#self.customerIdList_)
end


function PlotCollectWaterBarStoryMediator:getSelectCustomerIndex()
    return checkint(self.selectCustomerIndex_)
end
function PlotCollectWaterBarStoryMediator:setSelectCustomerIndex(index)
    local oldSelectIndex      = self.selectCustomerIndex_
    self.selectCustomerIndex_ = checkint(index)
    -- update customer status
    self:getViewData().customerTableView:updateCellViewData(oldSelectIndex, nil, 'status')
    self:getViewData().customerTableView:updateCellViewData(self.selectCustomerIndex_, nil, 'status')
    -- update current storyDatas
    self:setCurrentStoryDatas(self:getCustomerStoryDatas(self.selectCustomerIndex_))
end


function PlotCollectWaterBarStoryMediator:getCurrentStoryDatas()
    return checktable(self.currentStoryDatas_)
end
function PlotCollectWaterBarStoryMediator:setCurrentStoryDatas(storyDatas)
    self.currentStoryDatas_ = checktable(storyDatas)
    self:getViewData().storyTableView:resetCellCount(#self.currentStoryDatas_)
end


function PlotCollectWaterBarStoryMediator:getUnlockStoryIdList(customerId)
    return checktable(self.unlockStoryMap_[tostring(customerId)])
end


function PlotCollectWaterBarStoryMediator:getCustomerStoryDatas(index)
    if self.allStoryDataMap_[checkint(index)] == nil then
        local customerId     = self:getCustomerIdList()[checkint(index)]
        local customerConf   = CONF.BAR.CUSTOMER:GetValue(customerId)
        local customerData   = {}
        local unlockStoryMap = {}
        for index, storyId in ipairs(self:getUnlockStoryIdList(customerId)) do
            unlockStoryMap[tostring(storyId)] = true
        end
        for index, storyId in ipairs(customerConf.story or {}) do
            customerData[index] = {storyId = storyId, isUnlock = unlockStoryMap[tostring(storyId)] == true}
        end
        self.allStoryDataMap_[checkint(index)] = customerData
    end
    return self.allStoryDataMap_[checkint(index)]
end


-------------------------------------------------
-- public

function PlotCollectWaterBarStoryMediator:close()
    app:UnRegsitMediator(self:GetMediatorName())
end


-------------------------------------------------
-- handler

function PlotCollectWaterBarStoryMediator:onClickCloseButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    self:close()
end


function PlotCollectWaterBarStoryMediator:onUpdateCustomerCellHandler_(cellIndex, cellViewData, updateType)
    if cellViewData == nil then return end

    local customerId   = self:getCustomerIdList()[cellIndex]
    local customerConf = CONF.BAR.CUSTOMER:GetValue(customerId)

    if updateType == nil then
        cellViewData.clickArea:setTag(cellIndex)
        self:getViewNode():updateCustomerCardInfo(cellViewData, customerConf.cardId)
    end

    if updateType == nil or updateType == 'status' then
        self:getViewNode():updateCustomerSelectStatus(cellViewData, cellIndex == self:getSelectCustomerIndex())
    end

    if updateType == nil or updateType == 'count' then
        self:getViewNode():updateCustomerStoryCount(cellViewData, customerConf.story, self:getUnlockStoryIdList(customerId))
    end
end


function PlotCollectWaterBarStoryMediator:onClickCustomerCellHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local customerIndex = checkint(sender:getTag())
    self:setSelectCustomerIndex(customerIndex)
end


function PlotCollectWaterBarStoryMediator:onUpdateStoryCellHandler_(cellIndex, cellViewData)
    if cellViewData == nil then return end
    
    local storyData  = self:getCustomerStoryDatas(self:getSelectCustomerIndex())[cellIndex]
    local customerId = self:getCustomerIdList()[self:getSelectCustomerIndex()]
    local storyConf  = CONF.BAR.CUSTOMER_STORY_COLLECTION:GetValue(storyData.storyId)
    
    cellViewData.clickArea:setTag(cellIndex)
    
    self:getViewNode():updateStoryTitle(cellViewData, storyConf.name)
    
    self:getViewNode():updateStoryUnlockStatus(cellViewData, storyData.isUnlock)
end


function PlotCollectWaterBarStoryMediator:onClickStoryCellHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local storyIndex = checkint(sender:getTag())
    local storyData  = self:getCustomerStoryDatas(self:getSelectCustomerIndex())[storyIndex]

    if storyData.isUnlock then
        local storyId    = checkint(storyData.storyId)
        local storyPath  = string.format('conf/%s/bar/customerStory.json', i18n.getLang())
        local operaStage = require( "Frame.Opera.OperaStage" ).new({path = storyPath, id = storyId, isHideBackBtn = true, isReview = true, cb = function() end})
        display.commonUIParams(operaStage, {po = display.center})
        sceneWorld:addChild(operaStage, GameSceneTag.Dialog_GameSceneTag)
    else
        app.uiMgr:ShowInformationTips(__('该剧情还未解锁'))
    end
end


return PlotCollectWaterBarStoryMediator
