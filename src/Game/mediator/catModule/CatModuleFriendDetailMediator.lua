--[[
 * author : panmeng
 * descpt : 猫屋好友详情
]]

local CatModuleFriendDetailView     = require('Game.views.catModule.CatModuleFriendDetailView')
local CatModuleFriendDetailMediator = class('CatModuleFriendDetailMediator', mvc.Mediator)

function CatModuleFriendDetailMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'CatModuleFriendDetailMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance

function CatModuleFriendDetailMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    self.isControllable_ = true

    -- create view
    self.viewNode_ = CatModuleFriendDetailView.new()
    self:SetViewComponent(self:getViewNode())
    app.uiMgr:GetCurrentScene():AddDialog(self:getViewNode())

    -- add listener
    ui.bindClick(self:getViewData().blackLayer, handler(self, self.onClickBackButtonHandler_), false)
    self:getViewData().catTableView:setCellUpdateHandler(handler(self, self.onUpdateCatCellHandler_))
    self:getViewData().catTableView:setCellInitHandler(function(cell)
        ui.bindClick(cell, handler(self, self.onClickCatNodeBtnHandler_))
    end)
    self:getViewData().geneGridView:setCellUpdateHandler(function(cellIndex, cellNode)
        local geneId       = self:getSelectedCatData().gene[cellIndex]
        local isGeneEffect = CatHouseUtils.IsGeneEffect(self:getSelectedCatData().age)
        local geneState    = isGeneEffect and CatHouseUtils.CAT_GENE_CELL_STATU.SELECT or CatHouseUtils.CAT_GENE_CELL_STATU.UNLOCK
        cellNode:updateView(geneId, geneState)
    end)

    -- update view
    self:setCatUuid(self.ctorArgs_.catUuid)
    self:setFriendId(self.ctorArgs_.friendId)
end


function CatModuleFriendDetailMediator:CleanupView()
    if self:getViewNode() and not tolua.isnull(self:getViewNode()) then
        self:getViewNode():removeFromParent()
        self.viewNode_ = nil
    end
end


function CatModuleFriendDetailMediator:OnRegist()
end


function CatModuleFriendDetailMediator:OnUnRegist()
end


function CatModuleFriendDetailMediator:InterestSignals()
    return {}
end
function CatModuleFriendDetailMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()
end


-------------------------------------------------
-- get / set

function CatModuleFriendDetailMediator:getViewNode()
    return  self.viewNode_
end
function CatModuleFriendDetailMediator:getViewData()
    return self:getViewNode():getViewData()
end


-- selected catId
function CatModuleFriendDetailMediator:setSelectedCatUuid(catUuid)
    local oldCatUuid   = self:getSelectedCatUuid()
    self.selectedUuid_ = catUuid
    if oldCatUuid == self:getSelectedCatUuid() then
        return
    end

    -- update tableView
    for _, cellNode in pairs(self:getViewData().catTableView:getCellViewDataDict()) do
        cellNode:updateSelectedImgVisible(cellNode:getCatData().friendCatUuid == self:getSelectedCatUuid())
    end

    -- update detail page
    self:getViewNode():updatePageView(self:getSelectedCatData(), self:getCatModel())
end
function CatModuleFriendDetailMediator:getSelectedCatUuid()
    return self.selectedUuid_
end
function CatModuleFriendDetailMediator:getSelectedCatData()
    return self:getCatModel():getLikeFriendCatData(self:getSelectedCatUuid())
end



-- cur catId
function CatModuleFriendDetailMediator:setCatUuid(catUuid)
    self.catUuid_  = catUuid
    self.catModel_ = app.catHouseMgr:getCatModel(self:getCatUuid())
    self:initPage_()
end
function CatModuleFriendDetailMediator:getCatUuid()
    return self.catUuid_
end


---@type HouseCatModel
function CatModuleFriendDetailMediator:getCatModel()
    return self.catModel_
end


-- friendId
function CatModuleFriendDetailMediator:setFriendId(friendId)
    self.friendId_ = checkint(friendId)
    self:initPage_()
end
function CatModuleFriendDetailMediator:getFriendId()
    return checkint(self.friendId_)
end


-------------------------------------------------
-- public

function CatModuleFriendDetailMediator:close()
    app:UnRegsitMediator(self:GetMediatorName())
end


-------------------------------------------------
-- private

function CatModuleFriendDetailMediator:updateSelectDescr_()
    self:getViewNode():updateDescr(self:getDescrData())
end


function CatModuleFriendDetailMediator:initPage_()
    if self:getFriendId() <= 0 or not self:getCatModel() then
        return
    end
    self.catList_ = self:getCatModel():getLikeFriendCatsList(self:getFriendId())
    self:getViewData().catTableView:resetCellCount(#self.catList_)
    self:setSelectedCatUuid(self.catList_[1])
end


-------------------------------------------------
-- handler

function CatModuleFriendDetailMediator:onClickBackButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    self:close()
end


function CatModuleFriendDetailMediator:onClickCatNodeBtnHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    self:setSelectedCatUuid(sender:getCatData().friendCatUuid)
end


function CatModuleFriendDetailMediator:onUpdateCatCellHandler_(cellIndex, cellNode)
    local catUuid = self.catList_[cellIndex]
    local catData = self:getCatModel():getLikeFriendCatData(catUuid)
    if not catData then
        return
    end
    cellNode:setCatData(catData)
end


return CatModuleFriendDetailMediator
