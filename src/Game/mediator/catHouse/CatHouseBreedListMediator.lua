--[[
 * author : liuzhipeng
 * descpt : 猫屋 繁殖列表Mediator
--]]
local CatHouseBreedListMediator = class('CatHouseBreedListMediator', mvc.Mediator)
local NAME = 'catHouse.CatHouseBreedListMediator'

-------------------------------------------------
------------------ inheritance ------------------
--[[
@params map {
    sex int 性别
    inviterData map 邀请者数据
}
--]]
function CatHouseBreedListMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self:SetSex(checktable(params).sex)
    self:SetInviterData(checktable(params).inviterData)
end
 
function CatHouseBreedListMediator:Initial( key )
    self.super.Initial(self, key)
    local viewComponent = require('Game.views.catHouse.CatHouseBreedListView').new()
    viewComponent:setPosition(display.center)
    app.uiMgr:GetCurrentScene():AddDialog(viewComponent)
    self:SetViewComponent(viewComponent)
    local viewData = viewComponent.viewData

    viewComponent.eaterLayer:setOnClickScriptHandler(handler(self, self.BackButtonCallback))
    viewData.catGridView:setCellUpdateHandler(handler(self, self.OnUpdateListCellHandler))
    viewData.catGridView:setCellInitHandler(handler(self, self.OnInitListCellHandler))
    self:InitView()
end
    
function CatHouseBreedListMediator:InterestSignals()
    local signals = {
        SGL.CAT_MODEL_CAT_INFO_VIEW_CLOSE
    }
    return signals
end
function CatHouseBreedListMediator:ProcessSignal( signal )
    local name = signal:GetName()
    local body = signal:GetBody()
    if name == SGL.CAT_MODEL_CAT_INFO_VIEW_CLOSE then
        self:InitView()
    end
end

function CatHouseBreedListMediator:OnRegist()

end
function CatHouseBreedListMediator:OnUnRegist()
end

function CatHouseBreedListMediator:CleanupView()
    -- 移除界面
    local scene = app.uiMgr:GetCurrentScene()
    scene:RemoveDialog(self:GetViewComponent())
end
------------------ inheritance ------------------
-------------------------------------------------

-------------------------------------------------
-------------------- handler --------------------
--[[
返回主界面
--]]
function CatHouseBreedListMediator:BackButtonCallback( sender )
    PlayAudioByClickNormal()
    app:UnRegsitMediator(NAME)
end
--[[
列表刷新
--]]
function CatHouseBreedListMediator:OnUpdateListCellHandler( cellIndex, cellViewData )
    local catModel = self:GetCatData()[cellIndex]
    local viewComponent = self:GetViewComponent()
    cellViewData.clickArea:setTag(cellIndex)
    cellViewData.infoBtn:setTag(cellIndex)
    cellViewData.view:setTag(cellIndex)
    viewComponent:RefreshListCell(cellViewData, catModel, self:GetInviterData())
end
--[[
列表cell初始化
--]]
function CatHouseBreedListMediator:OnInitListCellHandler( cellViewData )
    cellViewData.clickArea:setOnClickScriptHandler(handler(self, self.CellButtonCallBack))
    cellViewData.infoBtn:setOnClickScriptHandler(handler(self, self.InfoButtonCallback))
end
--[[
cell点击回调
--]]
function CatHouseBreedListMediator:CellButtonCallBack( sender )
    PlayAudioByClickNormal()
    local tag = sender:getTag()
    local catModel = self:GetCatData()[tag]
    if self:GetInviterData() then
        if catModel:isMatingToFriend(self:GetInviterData(), true) then
            local mediator = require("Game.mediator.catHouse.CatHouseBreedCostMediator").new({catModel = catModel, inviterData = self:GetInviterData()})
            app:RegistMediator(mediator)
            app:UnRegsitMediator(NAME)
        end
    else
        if catModel:checkMatingToFriend(nil, true) then
            local mediator = require("Game.mediator.catHouse.CatHouseBreedCostMediator").new({catModel = catModel})
            app:RegistMediator(mediator)
            app:UnRegsitMediator(NAME)
        end
    end
end
--[[
详情按钮点击回调
--]]
function CatHouseBreedListMediator:InfoButtonCallback( sender )
    PlayAudioByClickNormal()
    local tag = sender:getTag()
    local catModel = self:GetCatData()[tag]
    local catInfoMdt = require('Game.mediator.catModule.CatModuleCatInfoMediator').new({catUuid = catModel:getUuid()})
    app:RegistMediator(catInfoMdt)
end
-------------------- handler --------------------
-------------------------------------------------

-------------------------------------------------
-------------------- private --------------------
--[[
初始化view
--]]
function CatHouseBreedListMediator:InitView()
    local catData = self:ConvertCatData()
    self:SetCatData(catData)
    local viewComponent = self:GetViewComponent()
    local catGridView = viewComponent:GetViewData().catGridView
    catGridView:resetCellCount(#catData)
end
--[[
转换catData
--]]
function CatHouseBreedListMediator:ConvertCatData()
    local catData = app.catHouseMgr:getCatsModelMap()
    local convertedData = {}
    if self:GetSex() then
        for _, v in pairs(catData) do
            if v:getSex() == self:GetSex() then
                table.insert(convertedData, v)
            end
        end
    else
        for _, v in pairs(catData) do
            table.insert(convertedData, v)
        end
    end
    table.sort(convertedData, function(aCatModel, bCatModel)
        local aMatingToFriend = aCatModel:isMatingToFriend(self:GetInviterData()) and 1 or 0
        local bMatingToFriend = bCatModel:isMatingToFriend(self:GetInviterData()) and 1 or 0
        return aMatingToFriend > bMatingToFriend
    end)
    return convertedData
end
-------------------- private --------------------
-------------------------------------------------

-------------------------------------------------
------------------- get / set -------------------
--[[
设置catData
--]]
function CatHouseBreedListMediator:SetCatData( catData )
    self.catData = catData
end
--[[
获取catData
--]]
function CatHouseBreedListMediator:GetCatData()
    return self.catData
end
--[[
设置性别
--]]
function CatHouseBreedListMediator:SetSex( sex )
    self.sex = sex
end
--[[
获取性别
--]]
function CatHouseBreedListMediator:GetSex()
    return self.sex
end
--[[
设置邀请者id
--]]
function CatHouseBreedListMediator:SetInviterData( inviterData )
    self.inviterData = inviterData
end
--[[
获取邀请者id
--]]
function CatHouseBreedListMediator:GetInviterData()
    return self.inviterData
end
------------------- get / set -------------------
-------------------------------------------------
return CatHouseBreedListMediator