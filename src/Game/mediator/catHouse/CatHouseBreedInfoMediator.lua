--[[
 * author : liuzhipeng
 * descpt : 猫屋 繁殖信息Mediator
--]]
local CatHouseBreedInfoMediator = class('CatHouseBreedInfoMediator', mvc.Mediator)
local NAME = 'catHouse.CatHouseBreedInfoMediator'
--[[
@params map {
    tips list 消息列表
}
--]]
function CatHouseBreedInfoMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self:SetInfoData(self:ConvertInfoData(params.tips))
end
-------------------------------------------------
------------------ inheritance ------------------
function CatHouseBreedInfoMediator:Initial( key )
    self.super.Initial(self, key)
    local viewComponent = require('Game.views.catHouse.CatHouseBreedInfoView').new()
    viewComponent:setPosition(display.center)
    app.uiMgr:GetCurrentScene():AddDialog(viewComponent)
    self:SetViewComponent(viewComponent)
    local viewData = viewComponent.viewData

    viewComponent.eaterLayer:setOnClickScriptHandler(handler(self, self.BackButtonCallback))
    viewData.successTableView:setCellUpdateHandler(handler(self, self.OnUpdateSuccessListCellHandler))
    viewData.failureTableView:setCellUpdateHandler(handler(self, self.OnUpdateFailureListCellHandler))
    
    self:InitView()
end
    
function CatHouseBreedInfoMediator:InterestSignals()
    local signals = {
    }
    return signals
end
function CatHouseBreedInfoMediator:ProcessSignal( signal )
    local name = signal:GetName()
    local body = signal:GetBody()
end

function CatHouseBreedInfoMediator:OnRegist()
end
function CatHouseBreedInfoMediator:OnUnRegist()
end

function CatHouseBreedInfoMediator:CleanupView()
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
function CatHouseBreedInfoMediator:BackButtonCallback( sender )
    PlayAudioByClickClose()
    app:UnRegsitMediator(NAME)
end
--[[
成功列表刷新
--]]
function CatHouseBreedInfoMediator:OnUpdateSuccessListCellHandler( cellIndex, cellViewData )
    local viewComponent = self:GetViewComponent()
    local infoData = self:GetInfoData()
    local playerCatId = infoData.success[cellIndex]
    viewComponent:RefreshListCell(cellViewData, cellIndex, playerCatId)
end
--[[
失败列表刷新
--]]
function CatHouseBreedInfoMediator:OnUpdateFailureListCellHandler( cellIndex, cellViewData )
    local viewComponent = self:GetViewComponent()
    local infoData = self:GetInfoData()
    local playerCatId = infoData.failure[cellIndex]
    viewComponent:RefreshListCell(cellViewData, cellIndex, playerCatId)
end
-------------------- handler --------------------
-------------------------------------------------

-------------------------------------------------
-------------------- private --------------------
--[[
初始化view
--]]
function CatHouseBreedInfoMediator:InitView()
    local infoData = self:GetInfoData()
    local viewData = self:GetViewComponent().viewData
    viewData.successTableView:resetCellCount(#infoData.success)
    viewData.failureTableView:resetCellCount(#infoData.failure)
end
--[[
转换infoData
--]]
function CatHouseBreedInfoMediator:ConvertInfoData( tips )
    local infoData = {success = {}, failure = {}}
    for i, v in ipairs(tips) do
        if app.catHouseMgr:getCatModel(CatHouseUtils.BuildCatUuid(app.gameMgr:GetPlayerId(), v.playerCatId)) then
            if checkint(v.type) == 1 then
                table.insert(infoData.success, v.playerCatId)
            elseif checkint(v.type) == 2 then
                table.insert(infoData.failure, v.playerCatId)
            end
        end
    end
    return infoData
end
-------------------- private --------------------
-------------------------------------------------

-------------------------------------------------
------------------- get / set -------------------
--[[
设置infoData
--]]
function CatHouseBreedInfoMediator:SetInfoData( infoData )
    self.infoData = infoData or {}
end
--[[
获取infoData
--]]
function CatHouseBreedInfoMediator:GetInfoData()
    return self.infoData
end
------------------- get / set -------------------
-------------------------------------------------
return CatHouseBreedInfoMediator