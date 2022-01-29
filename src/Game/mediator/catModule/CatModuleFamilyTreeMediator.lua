--[[
 * author : panmeng
 * descpt : 猫咪族谱
]]
local CatModuleFamilyTreeView     = require('Game.views.catModule.CatModuleFamilyTreeView')
local CatModuleFamilyTreeMediator = class('CatModuleFamilyTreeMediator', mvc.Mediator)

function CatModuleFamilyTreeMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'CatModuleFamilyTreeMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end

-------------------------------------------------
-- inheritance

function CatModuleFamilyTreeMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    self.isControllable_ = true

    -- create view
    self.viewNode_ = CatModuleFamilyTreeView.new()
    self:SetViewComponent(self:getViewNode())
    app.uiMgr:GetCurrentScene():AddDialog(self:getViewNode())

    -- add listener
    ui.bindClick(self:getViewData().blockLayer, handler(self, self.onClickBackButtonHandler_), false)
    for _, entranceBtn in pairs(self:getViewData().entranceBtnGroup) do
        ui.bindClick(entranceBtn, handler(self, self.onClickEntranceBtnHandler_), false)
    end
    self:getViewData().teamGeneTView:setCellUpdateHandler(handler(self, self.onUpdateTeamGeneCell_))
    self:getViewData().teamGeneTView:setCellInitHandler(function(cellViewData)
        for _, geneNode in pairs(cellViewData.geneNodeDatas) do
            ui.bindClick(geneNode:getViewData().view, handler(self, self.onClickGeneNodeBtnHandler_))
        end
        ui.bindClick(cellViewData.title, handler(self, self.onClickTeamGeneBtnHandler_), false)
    end)

    self:getViewData().normalGeneTView:setCellUpdateHandler(handler(self, self.onUpdateNormalGeneCell_))
    self:getViewData().normalGeneTView:setCellInitHandler(function(cellViewData)
        for _, geneNode in pairs(cellViewData.geneNodeDatas) do
            ui.bindClick(geneNode:getViewData().view, handler(self, self.onClickGeneNodeBtnHandler_))
        end
    end)

    self:initGeneDataMap_()
    self:setSelectedTabTag(1)
end


function CatModuleFamilyTreeMediator:CleanupView()
    if self:getViewNode() and not tolua.isnull(self:getViewNode()) then
        self:getViewNode():removeFromParent()
        self.viewNode_ = nil
    end
end


function CatModuleFamilyTreeMediator:OnRegist()
end


function CatModuleFamilyTreeMediator:OnUnRegist()
end


function CatModuleFamilyTreeMediator:InterestSignals()
    return {}
end
function CatModuleFamilyTreeMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()
end


-------------------------------------------------
-- get / set

function CatModuleFamilyTreeMediator:getViewNode()
    return  self.viewNode_
end
function CatModuleFamilyTreeMediator:getViewData()
    return self:getViewNode():getViewData()
end


function CatModuleFamilyTreeMediator:getSelectedTabTag()
    return checkint(self.selectedTabTag_)
end

function CatModuleFamilyTreeMediator:setSelectedTabTag(tabTag)
    if checkint(self.selectedTabTag_) == checkint(tabTag) then
        return
    end

    self.selectedTabTag_  = checkint(tabTag)
    self.curGeneListData_ = checktable(self.geneIdListMap_[self:getSelectedTabTag()])
    self:getViewNode():setSelectedEntrance(self:getSelectedTabTag(), #self.curGeneListData_)
    self:getViewNode():setUnlockProgress(self.geneUnlockedNumMap_[self:getSelectedTabTag()], #self.curGeneListData_)
end


function CatModuleFamilyTreeMediator:getGeneDataByGeneId(geneId)
    return checktable(self.allGeneDatasMap_[checkint(geneId)])
end


-------------------------------------------------
-- public

function CatModuleFamilyTreeMediator:close()
    app:UnRegsitMediator(self:GetMediatorName())
end


-------------------------------------------------
-- private

function CatModuleFamilyTreeMediator:initGeneDataMap_()
    self.allGeneDatasMap_    = {}
    self.geneIdListMap_      = {}
    self.geneUnlockedNumMap_ = {}

    for _, geneData in pairs(CONF.CAT_HOUSE.CAT_GENE:GetAll()) do
        local geneType = CatHouseUtils.GetCatGeneTypeByGeneId(geneData.id)
        if not self.geneIdListMap_[geneType] then
            self.geneIdListMap_[geneType] = {}
        end
        table.insert(self.geneIdListMap_[geneType], geneData.id)
        self.allGeneDatasMap_[checkint(geneData.id)] = geneData

        local unlocked = true
        if geneType == CatHouseUtils.CAT_GENE_TYPE.SUIT then
            for _, geneId in ipairs(geneData.compound) do
                if not app.catHouseMgr:isCatsUnlockedGeneId(geneId) then
                    unlocked = false
                    break
                end
            end 
        else
            unlocked = app.catHouseMgr:isCatsUnlockedGeneId(geneData.id)
        end

        if unlocked then
            self.geneUnlockedNumMap_[geneType] = checkint(self.geneUnlockedNumMap_[geneType]) + 1
        end

    end
end


function CatModuleFamilyTreeMediator:onUpdateTeamGeneCell_(cellIndex, cellViewData)
    local suitGeneId   = self.curGeneListData_[cellIndex]
    local suitGeneData = self:getGeneDataByGeneId(suitGeneId)

    cellViewData.title:updateLabel({text = tostring(suitGeneData.name)})
    cellViewData.title:setTag(suitGeneId)
    display.commonLabelParams(cellViewData.descr, {text = tostring(suitGeneData.descr), reqW = 900})
    for index, geneNode in ipairs(cellViewData.geneNodeDatas) do
        local geneId   = checkint(suitGeneData.compound[index] )
        local geneData = self:getGeneDataByGeneId(geneId)
        self:getViewNode():updateGeneCell(geneNode, geneData)
    end
end


function CatModuleFamilyTreeMediator:onUpdateNormalGeneCell_(cellIndex, cellViewData)
    for index, geneNode in ipairs(cellViewData.geneNodeDatas) do
        local geneId   = checkint(self.curGeneListData_[(cellIndex - 1) * 8 + index])
        local geneData = self:getGeneDataByGeneId(geneId)
        self:getViewNode():updateGeneCell(geneNode, geneData)
    end
end


-------------------------------------------------
-- handler

function CatModuleFamilyTreeMediator:onClickBackButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    self:close()
end


function CatModuleFamilyTreeMediator:onClickEntranceBtnHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    sender:setChecked(true)
    self:setSelectedTabTag(sender:getTag())
end


function CatModuleFamilyTreeMediator:onClickGeneNodeBtnHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    sender.clickCloseCB(true)
    local genePopup = require('Game.views.catModule.CatModuleGenePopup').new({
        geneId  = sender:getTag(),
        closeCB = function()
            sender.clickCloseCB(false)
        end
    })
    app.uiMgr:GetCurrentScene():AddDialog(genePopup)
end


function CatModuleFamilyTreeMediator:onClickTeamGeneBtnHandler_(sender)
    local genePopup = require('Game.views.catModule.CatModuleGenePopup').new({
        geneId  = sender:getTag(),
    })
    app.uiMgr:GetCurrentScene():AddDialog(genePopup)
end


return CatModuleFamilyTreeMediator
