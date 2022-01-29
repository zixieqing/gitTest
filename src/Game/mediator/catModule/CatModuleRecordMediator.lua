--[[
 * author : panmeng
 * descpt : 猫屋猫咪档案界面
]]

local CatModuleRecordView     = require('Game.views.catModule.CatModuleRecordView')
local CatModuleRecordMediator = class('CatModuleRecordMediator', mvc.Mediator)

function CatModuleRecordMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'CatModuleRecordMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end

local PAGE_TAG = CatModuleRecordView.PAGE_TAG
local PAGE_DEFINES = {
    {viewName = "CatModuleRecordInfoView",         initCallback = 'initCatHouseRecordInfoView'},
    {viewName = "CatModuleRecordDailyView",        initCallback = 'initCatHouseRecordDailyView'},
    {viewName = "CatModuleRecordFavorabilityView", initCallback = 'initCatHouseRecordFavorabilityView'},
}


-------------------------------------------------
-- inheritance

function CatModuleRecordMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    self.isControllable_ = true
    self.pageNodeMap_    = {}

    -- create view
    self.viewNode_ = CatModuleRecordView.new()
    self:SetViewComponent(self:getViewNode())
    app.uiMgr:GetCurrentScene():AddDialog(self:getViewNode())

    -- add listener
    ui.bindClick(self:getViewData().backBtn, handler(self, self.onClickBackButtonHandler_))
    ui.bindClick(self:getViewData().blockLayer, handler(self, self.onClickBackButtonHandler_), false)
    for _, btnNode in ipairs(self:getViewData().funcBtnGroup) do
        btnNode:setOnClickScriptHandler(handler(self, self.onClickPageButtonHandler_))
    end

    -- init
    self:setCatUuid(self.ctorArgs_.catUuid)
    self:setCurPageIndex(self.ctorArgs_.pageIndex or PAGE_TAG.INFO)
end


function CatModuleRecordMediator:CleanupView()
    if self:getViewNode() and not tolua.isnull(self:getViewNode()) then
        self:getViewNode():removeFromParent()
        self.viewNode_ = nil
    end
end


function CatModuleRecordMediator:OnRegist()
end


function CatModuleRecordMediator:OnUnRegist()
end


function CatModuleRecordMediator:InterestSignals()
    return {}
end
function CatModuleRecordMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()
end


-------------------------------------------------
-- get / set

function CatModuleRecordMediator:getViewNode()
    return  self.viewNode_
end
function CatModuleRecordMediator:getViewData()
    return self:getViewNode():getViewData()
end


function CatModuleRecordMediator:getCurPageIndex()
    return checkint(self.curPageIndex_)
end
function CatModuleRecordMediator:setCurPageIndex(pageIndex)
    local oldPageIndex = self:getCurPageIndex()
    self.curPageIndex_ = checkint(pageIndex)
    if self:getCurPageIndex() == oldPageIndex then
        return
    end

    if oldPageIndex ~= 0 and self:getPageNodeByIndex(oldPageIndex) then
        self:getPageNodeByIndex(oldPageIndex):setVisible(false)
        self:getViewData().funcBtnGroup[oldPageIndex]:setChecked(false)
    end
    self:getViewData().funcBtnGroup[self:getCurPageIndex()]:setChecked(true)

    self:showPageViewByIndex_(self:getCurPageIndex())
end
function CatModuleRecordMediator:getPageNodeByIndex(pageIndex)
    return self.pageNodeMap_[checkint(pageIndex)]
end


-- cat uuid
function CatModuleRecordMediator:getCatUuid()
    return self.catUuid_
end
function CatModuleRecordMediator:setCatUuid(catUuid)
    self.catUuid_  = catUuid
    self.catModel_ = app.catHouseMgr:getCatModel(self:getCatUuid())
    self.catGeneList_ = table.keys(self:getCatModel():getGeneMap())
end


---@return HouseCatModel
function CatModuleRecordMediator:getCatModel()
    return self.catModel_
end


function CatModuleRecordMediator:getCatGeneList()
    return checktable(self.catGeneList_)
end


-------------------------------------------------
-- public

function CatModuleRecordMediator:close()
    app:UnRegsitMediator(self:GetMediatorName())
end


-------------------------------------------------
-- private
function CatModuleRecordMediator:showPageViewByIndex_(pageIndex)
    local curPageNode = self:getPageNodeByIndex(pageIndex)
    if curPageNode then
        curPageNode:setVisible(true)
    else
        pageIndex      = checkint(pageIndex)
        local pageDefine = PAGE_DEFINES[pageIndex]
        if not pageDefine then
            return
        end
        local viewClassPath = string.fmt('Game.views.catModule.%1', pageDefine.viewName)
        curPageNode = require(viewClassPath).new()
        self:getViewData().centerLayer:addList(curPageNode):alignTo(nil, ui.lc, {offsetX = 20})
        self.pageNodeMap_[pageIndex] = curPageNode

        if self[pageDefine.initCallback] then
            self[pageDefine.initCallback](self, curPageNode)
        end
    end
end


function CatModuleRecordMediator:initCatHouseRecordInfoView(viewNode)
    viewNode:getViewData().geneGridView:setCellUpdateHandler(function(cellIndex, cell)
        local geneId       = self:getCatGeneList()[cellIndex]
        local isGeneEffect = CatHouseUtils.IsGeneEffect(self:getCatModel():getAge())
        local geneState    = isGeneEffect and CatHouseUtils.CAT_GENE_CELL_STATU.SELECT or CatHouseUtils.CAT_GENE_CELL_STATU.UNLOCK
        cell:updateView(geneId, geneState)
    end)

    viewNode:getViewData().geneGridView:resetCellCount(#self:getCatGeneList())
    viewNode:updateDescr(self:getCatGeneList(), self:getCatModel():getRace())
end


function CatModuleRecordMediator:initCatHouseRecordDailyView(viewNode)
    viewNode:getViewData().dailyGridView:setCellUpdateHandler(function(cellIndex, cellViewData)
        local journalData = self:getCatModel():getJournalList()[cellIndex]
        viewNode:updateJournalHandler(cellIndex, cellViewData, journalData)
    end)

    viewNode:updateProgress(#self:getCatModel():getJournalList(), CONF.CAT_HOUSE.CAT_JOURNAL:GetLength())
    viewNode:getViewData().dailyGridView:resetCellCount(#self:getCatModel():getJournalList())
end


function CatModuleRecordMediator:initCatHouseRecordFavorabilityView(viewNode)
    viewNode:getViewData().friendGridView:setCellInitHandler(function(cellViewData)
        ui.bindClick(cellViewData.detailBtn, handler(self, self.onClickFriendCatDetailBtnHandler_))
    end)
    viewNode:getViewData().friendGridView:setCellUpdateHandler(function(cellIndex, cellViewData)
        local friendId = self:getCatModel():getLikeFriendList()[cellIndex]
        viewNode:updateFriendCell(cellIndex, cellViewData, friendId)
    end)
    
    viewNode:setFriendDataNum(#self:getCatModel():getLikeFriendList())
end


-------------------------------------------------
-- handler

function CatModuleRecordMediator:onClickBackButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    self:close()
end


function CatModuleRecordMediator:onClickPageButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    sender:setChecked(true)
    self:setCurPageIndex(sender:getTag())
end


function CatModuleRecordMediator:onClickFriendCatDetailBtnHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local friendCatListMdt = require('Game.mediator.catModule.CatModuleFriendDetailMediator').new({
        friendId = checkint(sender:getTag()),
        catUuid  = self:getCatUuid(),
    })
    app:RegistMediator(friendCatListMdt)
end


return CatModuleRecordMediator
