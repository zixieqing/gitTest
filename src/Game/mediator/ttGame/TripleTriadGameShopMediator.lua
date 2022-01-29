--[[
 * author : kaishiqi
 * descpt : 打牌游戏 - 牌店中介者
]]
local TTGameShopView     = require('Game.views.ttGame.TripleTriadGameShopView')
local TTGameShopMediator = class('TripleTriadGameShopMediator', mvc.Mediator)

local TYPE_SHOP_DEFINES = {
    {mdtName = 'TripleTriadGameShopPackageMediator'},
    {mdtName = 'TripleTriadGameShopComposeMediator', isNeedStarFilter = true},
}

function TTGameShopMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'TripleTriadGameShopMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance

function TTGameShopMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    self.contentMdtDict_ = {}
    self.isControllable_ = true

    -- create view
    self.shopView_   = TTGameShopView.new()
    self.ownerScene_ = app.uiMgr:GetCurrentScene()
    self:getOwnerScene():AddGameLayer(self:getShopView())
    self:SetViewComponent(self:getShopView())

    -- add listener
    display.commonUIParams(self:getViewData().backBtn, {cb = handler(self, self.onClickBackButtonHandler_)})
    display.commonUIParams(self:getViewData().titleBtn, {cb = handler(self, self.onClickTitleButtonHandler_)})

    for _, cellViewData in ipairs(self:getShopView():getTypeCellViewDataList()) do
        display.commonUIParams(cellViewData.hotspot, {cb = handler(self, self.onClickShopTypeCellHandler_)})
    end
    for _, cellViewData in ipairs(self:getShopView():getStarCellViewDataList()) do
        display.commonUIParams(cellViewData.hotspot, {cb = handler(self, self.onClickStarFilterCellHandler_)})
    end

    -- update views
    self:setTypeSelectIndex(1)
end


function TTGameShopMediator:CleanupView()
    local viewComponent = self:GetViewComponent()
    if self.ownerScene_ and viewComponent and not tolua.isnull(viewComponent) then
        self.ownerScene_:RemoveGameLayer(viewComponent)
        self.ownerScene_ = nil
    end
end


function TTGameShopMediator:OnRegist()
end


function TTGameShopMediator:OnUnRegist()
    for _, mdtName in pairs(self.contentMdtDict_) do
        self:GetFacade():UnRegsitMediator(mdtName)
    end
end


function TTGameShopMediator:InterestSignals()
    return {
        SGL.CACHE_MONEY_UPDATE_UI,
    }
end
function TTGameShopMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    if name == SGL.CACHE_MONEY_UPDATE_UI then
        self:getShopView():updateMoneyBar()
    end
end


-------------------------------------------------
-- get / set

function TTGameShopMediator:getOwnerScene()
    return self.ownerScene_
end


function TTGameShopMediator:getShopView()
    return self.shopView_
end
function TTGameShopMediator:getViewData()
    return self:getShopView():getViewData()
end


-------------------------------------------------
-- public

function TTGameShopMediator:close()
    app:UnRegsitMediator(self:GetMediatorName())
end

function TTGameShopMediator:getTypeSelectIndex()
    return self.selectTypeIndex_
end
function TTGameShopMediator:setTypeSelectIndex(index)
    self.selectTypeIndex_ = checkint(index)
    self:updateSelectTypeIndex_()
end


-------------------------------------------------
-- private

function TTGameShopMediator:updateSelectTypeIndex_()
    local typeShopDefine   = TYPE_SHOP_DEFINES[self:getTypeSelectIndex()] or {}
    local isNeedStarFilter = typeShopDefine.isNeedStarFilter == true

    -- update all typeCells status
    self:getShopView():updateSelectTypeIndex(self:getTypeSelectIndex(), isNeedStarFilter)

    -- update content panel
    self:updateShopContentPanel_(self:getTypeSelectIndex())

    if isNeedStarFilter then
        self:updateShopFilterStatus_(1, TTGAME_DEFINE.FILTER_TYPE_ALL)
    end
end


function TTGameShopMediator:updateShopContentPanel_(index)
    -- new shopMdt
    if not self.contentMdtDict_[tostring(index)] then
        local typeShopDefine  = TYPE_SHOP_DEFINES[index] or {}
        local typeShopMdtName = checkstr(typeShopDefine.mdtName)
        if string.len(typeShopMdtName) > 0 then
            xTry(function()
                local contentMdtClass  = require(string.fmt('Game.mediator.ttGame.%1', typeShopMdtName))
                local contentMdtObject = contentMdtClass.new({ownerNode = self:getViewData().storeLayer})
                self:GetFacade():RegistMediator(contentMdtObject)
                self.contentMdtDict_[tostring(index)] = contentMdtObject:GetMediatorName()
            end, __G__TRACKBACK__)
        end
    end

    -- update all shopMdt
    for mdtIndex, mdtName in pairs(self.contentMdtDict_) do
        local mdtObject = self:GetFacade():RetrieveMediator(mdtName)
        if mdtObject then
            if checkint(mdtIndex) == index then
                mdtObject:show()
            else
                mdtObject:hide()
            end
        end
    end
end


function TTGameShopMediator:updateShopFilterStatus_(filterStar, filterType)
    local currentMdtName = checkstr(self.contentMdtDict_[tostring(self:getTypeSelectIndex())])
    if string.len(currentMdtName) > 0 then
        local contentMdtObject = self:GetFacade():RetrieveMediator(currentMdtName)
        if contentMdtObject then

            if filterStar and contentMdtObject.setFilterCardStar then
                contentMdtObject:setFilterCardStar(filterStar)
            end
            
            if filterType and contentMdtObject.setFilterCardType then
                contentMdtObject:setFilterCardType(filterType)
            end
            
            -- if filterStar and contentMdtObject.getStarCardNumMap then
            --     self:getShopView():updateFilterStarStatus(filterStar, contentMdtObject:getStarCardNumMap())
            -- end
        end
    end
end


-------------------------------------------------
-- handler

function TTGameShopMediator:onClickBackButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    self:close()
end


function TTGameShopMediator:onClickTitleButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    app.uiMgr:ShowIntroPopup({moduleId = MODULE_DATA.TTGAME_SHOP})
end


function TTGameShopMediator:onClickShopTypeCellHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    if self:getTypeSelectIndex() ~= sender:getTag() then
        self:setTypeSelectIndex(sender:getTag())
    end
end


function TTGameShopMediator:onClickStarFilterCellHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local currentMdtName = checkstr(self.contentMdtDict_[tostring(self:getTypeSelectIndex())])
    if string.len(currentMdtName) > 0 then
        local currentMdtObject = self:GetFacade():RetrieveMediator(currentMdtName)
        if currentMdtObject and currentMdtObject.getFilterCardStar then 
            if currentMdtObject:getFilterCardStar() ~= sender:getTag() then
                self:updateShopFilterStatus_(sender:getTag())
            end
        end
    end
end


return TTGameShopMediator
