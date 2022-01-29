--[[
 * author : panmeng
 * descpt : 猫咪养成 主界面
]]
local CatModuleMainView     = require('Game.views.catModule.CatModuleMainView')
local CatModuleMainMediator = class('CatModuleMainMediator', mvc.Mediator)

function CatModuleMainMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'CatModuleMainMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- life cycle
function CatModuleMainMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    self.isControllable_ = true

    -- create view
    self.viewNode_ = CatModuleMainView.new()
    self:SetViewComponent(self:getViewNode())
    app.uiMgr:GetCurrentScene():AddGameLayer(self:getViewNode())

    -- add listener
    ui.bindClick(self:getViewData().backBtn, handler(self, self.onClickBackButtonHandler_))
    ui.bindClick(self:getViewData().titleBtn, handler(self, self.onClickTitleButtonHandler_))
    ui.bindClick(self:getViewData().shopBtn, handler(self, self.onClickShopButtonHandler_), false)
    ui.bindClick(self:getViewData().catteryBtn, handler(self, self.onClickCatteryButtonHandler_), false)
    ui.bindClick(self:getViewData().familyBtn, handler(self, self.onClickFamilyButtonHandler_), false)
    ui.bindClick(self:getViewData().catListBtn, handler(self, self.onClickCatListButtonHandler_), false)

    -- update views
    self.isControllable_ = false
    self:getViewNode():showUI(function()
        self.isControllable_ = true
    end)
end


function CatModuleMainMediator:CleanupView()
    if self:getViewNode() and not tolua.isnull(self:getViewNode()) then
        self:getViewNode():removeFromParent()
        self.viewNode_ = nil
    end
end


function CatModuleMainMediator:OnRegist()
end


function CatModuleMainMediator:OnUnRegist()
end


function CatModuleMainMediator:InterestSignals()
    return {
    }
end
function CatModuleMainMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()
end


-------------------------------------------------
-- get / set

function CatModuleMainMediator:getViewNode()
    return self.viewNode_
end
function CatModuleMainMediator:getViewData()
    return self:getViewNode():getViewData()
end


-------------------------------------------------
-- public

function CatModuleMainMediator:close()
    app:UnRegsitMediator(self:GetMediatorName())
end


-------------------------------------------------
-- private


-------------------------------------------------
-- handler

function CatModuleMainMediator:onClickBackButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    self:close()
end


function CatModuleMainMediator:onClickTitleButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    app.uiMgr:ShowIntroPopup({moduleId = MODULE_DATA[tostring(RemindTag.CAT_HOUSE)]})
end


function CatModuleMainMediator:onClickCatteryButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end
    local mediator = require("Game.mediator.catHouse.CatHouseBreedMediator").new()
	app:RegistMediator(mediator)
end


function CatModuleMainMediator:onClickShopButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local mediator = require("Game.mediator.catModule.CatModuleShopMediator").new()
    app:RegistMediator(mediator)
end


function CatModuleMainMediator:onClickFamilyButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local mediator = require("Game.mediator.catModule.CatModuleFamilyTreeMediator").new()
    app:RegistMediator(mediator)
end


function CatModuleMainMediator:onClickCatListButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local mediator = require("Game.mediator.catModule.CatModuleCatListMediator").new()
    app:RegistMediator(mediator)
end


return CatModuleMainMediator
    