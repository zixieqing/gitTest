--[[
 * author : zhipeng
 * descpt : 猫屋 - 排行榜 中介者
]]
local CatHouseRankView     = require('Game.views.catHouse.CatHouseRankView')
local CatHouseRankMediator = class('CatHouseRankMediator', mvc.Mediator)

function CatHouseRankMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'CatHouseRankMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance

function CatHouseRankMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    self.isControllable_ = true

    -- create view
    self.viewNode_ = CatHouseRankView.new()
    self:SetViewComponent(self:getViewNode())
    app.uiMgr:GetCurrentScene():AddGameLayer(self:getViewNode())

    -- add listener
    ui.bindClick(self:getViewData().backBtn, handler(self, self.onClickBackButtonHandler_))
    ui.bindClick(self:getViewData().blockLayer, handler(self, self.onClickBackButtonHandler_), false)
    ui.bindClick(self:getViewData().cancelBtn, handler(self, self.onClickCancelButtonHandler_))
    ui.bindClick(self:getViewData().confirmBtn, handler(self, self.onClickConfirmButtonHandler_))

    -- update views
    self:setDescrData('zhipeng...')
end


function CatHouseRankMediator:CleanupView()
    if self:getViewNode() and not tolua.isnull(self:getViewNode()) then
        self:getViewNode():removeFromParent()
        self.viewNode_ = nil
    end
end


function CatHouseRankMediator:OnRegist()
end


function CatHouseRankMediator:OnUnRegist()
end


function CatHouseRankMediator:InterestSignals()
    return {}
end
function CatHouseRankMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()
end


-------------------------------------------------
-- get / set

function CatHouseRankMediator:getViewNode()
    return  self.viewNode_
end
function CatHouseRankMediator:getViewData()
    return self:getViewNode():getViewData()
end


function CatHouseRankMediator:getDescrData()
    return self.descrData_
end
function CatHouseRankMediator:setDescrData(descr)
    self.descrData_ = tostring(descr)
    self:updateSelectDescr_()
end


-------------------------------------------------
-- public

function CatHouseRankMediator:close()
    app:UnRegsitMediator(self:GetMediatorName())
end


-------------------------------------------------
-- private

function CatHouseRankMediator:updateSelectDescr_()
    self:getViewNode():updateDescr(self:getDescrData())
end


-------------------------------------------------
-- handler

function CatHouseRankMediator:onClickBackButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    self:close()
end


function CatHouseRankMediator:onClickConfirmButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    app.uiMgr:ShowInformationTips('confirm')
end


function CatHouseRankMediator:onClickCancelButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    app.uiMgr:ShowInformationTips('cancel')
end


return CatHouseRankMediator
