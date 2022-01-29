--[[
餐厅信息页面Mediator
--]]
local Mediator = mvc.Mediator
---@class FishingInformationMediator:Mediator
local FishingInformationMediator = class("FishingInformationMediator", Mediator)

local NAME = "FishingInformationMediator"
---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local LobbyInformationCell = require('home.LobbyInformationCell')
local BTN_TAG = {
    FISHING_INFORMATION = RemindTag.BTN_FISH_UPGRADE
}
local BTNDATA = {
    {name = __('垂钓信息'), tag = BTN_TAG.FISHING_INFORMATION },
}
function FishingInformationMediator:ctor( params, viewComponent )
    self.super:ctor(NAME,viewComponent)
    self.selectedTab = 1 -- 选择的页签
    self.tabMediator = {}  -- tab 页对应的mediator
end

function FishingInformationMediator:InterestSignals()
    local signals = {
        FISH_LEVEL_UP_EVENT
    }
    return signals
end

function FishingInformationMediator:ProcessSignal( signal )
    local name = signal:GetName()
    if name == FISH_LEVEL_UP_EVENT then
        local viewData = self:GetViewComponent().viewData
        local cell =  viewData.gridView:cellAtIndex(0)
        local canUpgrade = app.fishingMgr:CheckFishUpgradeLevel()
        if canUpgrade then
            app.dataMgr:AddRedDotNofication(tostring(BTN_TAG.FISHING_INFORMATION),tostring(BTN_TAG.FISHING_INFORMATION))
        else
            app.dataMgr:ClearRedDotNofication(tostring(BTN_TAG.FISHING_INFORMATION),tostring(BTN_TAG.FISHING_INFORMATION))
        end
        app:DispatchObservers(COUNT_DOWN_ACTION , { countdown = 0 , tag =  BTN_TAG.FISHING_INFORMATION  })
        if cell and ( not tolua.isnull(cell))  then
            self:ButtonDataSource(cell , 0)
        end
    end
end


function FishingInformationMediator:Initial( key )
    self.super.Initial(self,key)
    ---@type GameScene
    local scene = uiMgr:GetCurrentScene()
    ---@type FishingInformationView
    local viewComponent  = require( 'Game.views.fishing.FishingInformationView' ).new()
    self:SetViewComponent(viewComponent)
    viewComponent:setPosition(display.center)
    scene:AddDialog(viewComponent)
    local viewData = viewComponent.viewData
    display.commonUIParams(viewData.eaterLayer , { cb = function()
         self:GetFacade():UnRegsitMediator(NAME)
    end})
    viewData.gridView:setDataSourceAdapterScriptHandler(handler(self, self.ButtonDataSource))
    viewData.gridView:setCountOfCell(table.nums(BTNDATA))
    viewData.gridView:reloadData()
    self:TabButtonCallback(self.selectedTab)
end
function FishingInformationMediator:ButtonDataSource( p_convertview,idx )
    local pCell = p_convertview
    local index = idx + 1
    local cSize = cc.size(226, 90)

    if pCell == nil then
        pCell = LobbyInformationCell.new(cSize)
    else

    end
    xTry(function()
        pCell.nameLabel:setString(BTNDATA[index].name)
        pCell.bgBtn:setOnClickScriptHandler(handler(self, self.TabButtonCallback))
        pCell.bgBtn:setTag(index)
        if BTNDATA[index].tag == BTN_TAG.FISHING_INFORMATION then
            -- 返回红点日志的数量
            local canUpgrade = app.dataMgr:GetRedDotNofication( tostring(BTN_TAG.FISHING_INFORMATION) ,tostring(BTN_TAG.FISHING_INFORMATION))
            canUpgrade = canUpgrade > 0 and true or false
            pCell.remindIcon:setVisible(canUpgrade)
        else
            pCell.remindIcon:setVisible(false)
        end
    end,__G__TRACKBACK__)
    return pCell
end
--[[
　　---@Description: 点击tab 按钮响应事件
　　---@param :
　  ---@return :
　　---@author : xingweihao
　　---@date : 2018/8/8 11:22 AM
--]]
function FishingInformationMediator:TabButtonCallback(sender)
    PlayAudioByClickNormal()
    local tag = 0
    local viewData = self:GetViewComponent().viewData
    local gridView = viewData.gridView
    if type(sender) == 'number' then
        tag = sender
    else
        tag = sender:getTag()
        if self.selectedTab == tag then
            return
        else
            -- 添加点击音效
            local index = self.selectedTab - 1
            gridView:cellAtIndex(index).bgBtn:setChecked(false)
            gridView:cellAtIndex(index).bgBtn:setEnabled(true)
            gridView:cellAtIndex(index).nameLabel:setColor(cc.c3b(118, 85, 59))
            if self.showLayer[tostring(BTNDATA[self.selectedTab].tag)] then
                self.showLayer[tostring(BTNDATA[self.selectedTab].tag)]:setVisible(false)
            end
            self.selectedTab = tag
        end
    end
    local index = self.selectedTab - 1
    gridView:cellAtIndex(index).bgBtn:setChecked(true)
    gridView:cellAtIndex(index).bgBtn:setEnabled(false)
    gridView:cellAtIndex(index).nameLabel:setColor(cc.c3b(255, 255, 255))
    self:SwitchView(BTNDATA[self.selectedTab].tag)
end
--[[
切换页面
@params tag int 选择的页面
--]]
function FishingInformationMediator:SwitchView( tag)
    if not  self.tabMediator[tostring(tag)] then
        local viewData = self.viewComponent.viewData
        if tag == BTN_TAG.FISHING_INFORMATION then
            local mediator = require("Game.mediator.fishing.FishingPopularityMediator").new()
            self:GetFacade():RegistMediator(mediator)
            self.tabMediator[tostring(tag)] = mediator
            local viewComponent  = mediator:GetViewComponent()
            viewData.showLayout:addChild(viewComponent)
        end
    end
    for mediatorTag,mediator  in pairs(self.tabMediator) do
        mediator:GetViewComponent():setVisible(false)
    end
    self.tabMediator[tostring(tag)]:GetViewComponent():setVisible(true)
    self.tabMediator[tostring(tag)]:UpdateUI()
end

function FishingInformationMediator:OnRegist(  )
end

function FishingInformationMediator:OnUnRegist(  )
    -- 先清除自己所属子项的mediator 在清除自己的viewCompent
    for i, v in pairs(self.tabMediator) do
        self:GetFacade():UnRegsitMediator(v.mediatorName)
    end
    local viewComponent = self:GetViewComponent()
    if viewComponent and (not tolua.isnull(viewComponent)) then
        viewComponent:stopAllActions()
        viewComponent:runAction(cc.RemoveSelf:create())
    end
end

return FishingInformationMediator
