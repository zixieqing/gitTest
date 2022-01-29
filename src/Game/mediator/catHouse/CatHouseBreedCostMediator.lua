--[[
 * author : liuzhipeng
 * descpt : 猫屋 繁殖消耗Mediator
--]]
local CatHouseBreedCostMediator = class('CatHouseBreedCostMediator', mvc.Mediator)
local NAME = 'catHouse.CatHouseBreedCostMediator'
function CatHouseBreedCostMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self:SetCatModel(params.catModel)
    self:SetInviterData(params.inviterData)
end
-------------------------------------------------
------------------ inheritance ------------------
function CatHouseBreedCostMediator:Initial( key )
    self.super.Initial(self, key)
    local viewComponent = require('Game.views.catHouse.CatHouseBreedCostView').new()
    viewComponent:setPosition(display.center)
    app.uiMgr:GetCurrentScene():AddDialog(viewComponent)
    self:SetViewComponent(viewComponent)
    local viewData = viewComponent.viewData

    viewComponent.eaterLayer:setOnClickScriptHandler(handler(self, self.BackButtonCallback))
    viewData.cancelBtn:setOnClickScriptHandler(handler(self, self.CancelButtonCallback))
    viewData.confirmBtn:setOnClickScriptHandler(handler(self, self.ConfirmButtonCallback))
    self:InitView()
end
    
function CatHouseBreedCostMediator:InterestSignals()
    local signals = {
    }
    return signals
end
function CatHouseBreedCostMediator:ProcessSignal( signal )
    local name = signal:GetName()
    local body = signal:GetBody()
end

function CatHouseBreedCostMediator:OnRegist()

end
function CatHouseBreedCostMediator:OnUnRegist()
end

function CatHouseBreedCostMediator:CleanupView()
    -- 移除界面
    if self:GetViewComponent() and not tolua.isnull(self:GetViewComponent()) then
        self:GetViewComponent():removeFromParent()
        self:SetViewComponent(nil)
    end
end
------------------ inheritance ------------------
-------------------------------------------------

-------------------------------------------------
-------------------- handler --------------------
--[[
返回主界面
--]]
function CatHouseBreedCostMediator:BackButtonCallback( sender )
    PlayAudioByClickClose()
    app:UnRegsitMediator(NAME)
end
--[[
取消按钮点击回调
--]]
function CatHouseBreedCostMediator:CancelButtonCallback( sender )
    PlayAudioByClickNormal()
    app:UnRegsitMediator(NAME)
end
--[[
确定按钮点击回调
--]]
function CatHouseBreedCostMediator:ConfirmButtonCallback( sender )
    PlayAudioByClickNormal()
    if self:GetInviterData() then
        app:DispatchObservers(SGL.CAT_HOUSE_BREED_LIST_INVITEE_SELECTED, {catModel = self:GetCatModel(), inviterData = self:GetInviterData()})
    else
        app:DispatchObservers(SGL.CAT_HOUSE_BREED_LIST_SELECTED, {catModel = self:GetCatModel()})
    end
    app:UnRegsitMediator(NAME)
end
-------------------- handler --------------------
-------------------------------------------------

-------------------------------------------------
-------------------- private --------------------
--[[
初始化view
--]]
function CatHouseBreedCostMediator:InitView()
    local catModel = self:GetCatModel()
    local viewComponent = self:GetViewComponent()
    viewComponent:RefreshView(catModel)
end
-------------------- private --------------------
-------------------------------------------------

-------------------------------------------------
------------------- get / set -------------------
--[[
设置catModel
--]]
function CatHouseBreedCostMediator:SetCatModel( catModel )
    self.catModel = catModel
end
--[[
获取catModel
--]]
function CatHouseBreedCostMediator:GetCatModel()
    return self.catModel
end
--[[
设置邀请者id
--]]
function CatHouseBreedCostMediator:SetInviterData( inviterData )
    self.inviterData = inviterData
end
--[[
获取邀请者id
--]]
function CatHouseBreedCostMediator:GetInviterData()
    return self.inviterData
end
------------------- get / set -------------------
-------------------------------------------------
return CatHouseBreedCostMediator