--[[
 * author : kaishiqi
 * descpt : 新游戏商店 - 杂货铺商店中介者
]]
local GroceryStoreView     = require('Game.views.stores.GroceryStoreView')
local GroceryStoreMediator = class('GroceryStoreMediator', mvc.Mediator)

function GroceryStoreMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'GroceryStoreMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance method

function GroceryStoreMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    self.ownerNode_      = self.ctorArgs_.ownerNode
    self.isControllable_ = true

    -- create view
    if self.ownerNode_ then
        self.storesView_ = GroceryStoreView.new(self.ownerNode_:getContentSize())
        self.ownerNode_:addChild(self.storesView_)

        -- add listener
        self.storesView_.viewData_.subStoreGridView:setCellInitHandler(function(cellViewData)
            ui.bindClick(cellViewData.clickArea, handler(self, self.onClickSubStoreButtonHandler_))
        end)
    end
end


function GroceryStoreMediator:CleanupView()
    if self.storesView_  and (not tolua.isnull(self.storesView_)) then
        self.storesView_:runAction(cc.RemoveSelf:create())
        self.storesView_ = nil
    end
end


function GroceryStoreMediator:OnRegist()
end


function GroceryStoreMediator:OnUnRegist()
end


function GroceryStoreMediator:InterestSignals()
    return {}
end
function GroceryStoreMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()
end


-------------------------------------------------
-- get / set

function GroceryStoreMediator:getStoresView()
    return self.storesView_
end
function GroceryStoreMediator:getStoresViewData()
    return self:getStoresView() and self:getStoresView():getViewData() or {}
end


-------------------------------------------------
-- public

function GroceryStoreMediator:close()
    self:GetFacade():UnRegsitMediator(self:GetMediatorName())
end


function GroceryStoreMediator:setStoreData(storeData)
end


function GroceryStoreMediator:openSubType(subType)
    if subType == GAME_STORE_TYPE.RESTAURANT then
        local storeMdt = require("Game.mediator.stores.LobbyShopViewMediator").new()
        self:GetFacade():RegistMediator(storeMdt)

    elseif subType == GAME_STORE_TYPE.PVP_ARENA then
        local storeMdt = require("Game.mediator.stores.PVCShopViewMediator").new()
        self:GetFacade():RegistMediator(storeMdt)

    elseif subType == GAME_STORE_TYPE.KOF_ARENA then
        local storeMdt = require("Game.mediator.stores.KOFShopViewMediator").new({type = 5})
        self:GetFacade():RegistMediator(storeMdt)

    elseif subType == GAME_STORE_TYPE.NEW_KOF_ARENA then
        local storeMdt = require("Game.mediator.tagMatchNew.NewKofArenaShopMediator").new()
        self:GetFacade():RegistMediator(storeMdt)    

    elseif subType == GAME_STORE_TYPE.UNION then
        local storeMdt = require("Game.mediator.UnionShopMediator").new()
        self:GetFacade():RegistMediator(storeMdt)
    
    elseif subType == GAME_STORE_TYPE.UNION_WARS then
        local storeMdt = require("Game.mediator.unionWars.UnionWarsShopMediator").new()
        self:GetFacade():RegistMediator(storeMdt)

    elseif subType == GAME_STORE_TYPE.WATER_BAR then
        local storeMdt = require("Game.mediator.waterBar.WaterBarShopMediator").new()
        self:GetFacade():RegistMediator(storeMdt)

    elseif subType == GAME_STORE_TYPE.MEMORY then
        local storeMdt = require("Game.mediator.stores.MemoryStoreMediator").new()
        self:GetFacade():RegistMediator(storeMdt)

    elseif subType == GAME_STORE_TYPE.CHAMPIONSHIP then
        local storeMdt = require("Game.mediator.championship.ChampionshipShopMediator").new()
        self:GetFacade():RegistMediator(storeMdt)

    end
end


-------------------------------------------------
-- private


-------------------------------------------------
-- handler

function GroceryStoreMediator:onClickSubStoreButtonHandler_(sender)
    PlayAudioByClickNormal()

    local subStoreType = checkint(sender:getTag())
    self:openSubType(subStoreType)
end


return GroceryStoreMediator
