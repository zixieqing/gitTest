--[[
周年庆奖励预览mediator
--]]
local Mediator = mvc.Mediator
---@class AnniversaryRewardPreviewMeditaor :Mediator
local AnniversaryRewardPreviewMeditaor = class("AnniversaryRewardPreviewMeditaor", Mediator)
local NAME = "anniversary.AnniversaryRewardPreviewMeditaor"

local uiMgr = app.uiMgr
local anniversaryManager = app.anniversaryMgr

local AnniversaryPlotUnlockRewardMediator = require("Game.mediator.anniversary.AnniversaryPlotUnlockRewardMediator")
local AnniversaryChallengeRewardMediator  = require("Game.mediator.anniversary.AnniversaryChallengeRewardMediator")
local AnniversaryRankRewardMediator       = require("Game.mediator.anniversary.AnniversaryRankRewardMediator")

local VIEW_TAG = 1111
local CHILD_VIEW_TAG = {
    PLOT_UNLOCK = 100,
    CHALLENGE   = 101,
    RANK        = 102,
}

function AnniversaryRewardPreviewMeditaor:ctor(param ,  viewComponent )
    self.super:ctor(NAME,viewComponent)
    self.mediatorStore = {}
    self.curChildViewTag = CHILD_VIEW_TAG.PLOT_UNLOCK

    self.childMediaorClassMap_ = {
        [tostring(CHILD_VIEW_TAG.PLOT_UNLOCK)] = AnniversaryPlotUnlockRewardMediator,
        [tostring(CHILD_VIEW_TAG.CHALLENGE)]   = AnniversaryChallengeRewardMediator,
        [tostring(CHILD_VIEW_TAG.RANK)]        = AnniversaryRankRewardMediator,
    }
    self.childMediaorNames_    = {}
end

function AnniversaryRewardPreviewMeditaor:InterestSignals()
    local signals = {
        'ANNIVERSARY_REWARD_PREVIEW_REFRESH_CARD_PREVIEW'
    }
    return signals
end

function AnniversaryRewardPreviewMeditaor:ProcessSignal( signal )
    local name = signal:GetName()
    local body = signal:GetBody() or {}
    if name == 'ANNIVERSARY_REWARD_PREVIEW_REFRESH_CARD_PREVIEW' then
        local showCardIndex = body.showCardIndex
        local confId = self.showCards[showCardIndex]
        self:GetViewComponent():updateCardPreview(confId)
    end
end

function AnniversaryRewardPreviewMeditaor:Initial( key )
    self.super:Initial(key)
    
    ---@type AnniversaryRewardPreviewView
    local viewComponent  = require('Game.views.anniversary.AnniversaryRewardPreviewView').new({mediatorName = NAME})
    self.viewData_      = viewComponent:getViewData()
    self:SetViewComponent(viewComponent)
    display.commonUIParams(viewComponent, {ap = display.CENTER, po = display.center})

    self.ownerScene_ = uiMgr:GetCurrentScene()
    self:getOwnerScene():AddDialog(viewComponent)

    self:initData_()

    self:initView_()

    self:swiChildView_(self.curChildViewTag)
end

-------------------------------------------------
-- private method

function AnniversaryRewardPreviewMeditaor:initData_()
    local parserConfig = anniversaryManager:GetConfigParse()
    local paramConfig = checktable(anniversaryManager:GetConfigDataByName(parserConfig.TYPE.PARAMETER))["1"] or {}
    self.showCards = paramConfig.showCards or {}
end

function AnniversaryRewardPreviewMeditaor:initView_()
    local viewData = self:getViewData()
    local tabs     = viewData.tabs
    for tag, tab in pairs(tabs) do
        display.commonUIParams(tab, {cb = handler(self, self.onClickTabAction)})
    end
end

--==============================--
--desc: 切换子view
--@params viewTag int 视图标识
--@params data table  视图数据
--==============================--
function AnniversaryRewardPreviewMeditaor:swiChildView_(viewTag, data)
    local Mediator = self:getMediatorByTag(tostring(viewTag))
    if Mediator == nil then return end

    if not self.mediatorStore[viewTag] then
        local viewData     = self:getViewData()
        local contentLayer = viewData.contentLayer
        local mediatorIns  = Mediator.new()
        self:GetFacade():RegistMediator(mediatorIns)
        local mediatorViewComponent = mediatorIns:GetViewComponent()
        local contentLayerSize = contentLayer:getContentSize()
        contentLayer:addChild(mediatorViewComponent)
        display.commonUIParams(mediatorViewComponent,{po = cc.p(contentLayerSize.width / 2, contentLayerSize.height / 2), ap = display.CENTER})
        
        self.mediatorStore[viewTag] = mediatorIns
    end

    if self.curChildViewTag ~= viewTag then
        self:GetViewComponent():updateTab(self.curChildViewTag, false)
        self.mediatorStore[self.curChildViewTag]:GetViewComponent():setVisible(false)
        self.mediatorStore[viewTag]:GetViewComponent():setVisible(true)
        self.curChildViewTag = viewTag
    end

    self:GetViewComponent():updateTab(viewTag, true)
    self.mediatorStore[viewTag]:refreshUI(data)
end

function AnniversaryRewardPreviewMeditaor:onClickTabAction(sender)
    local tag = sender:getTag()
    if self.curChildViewTag == tag then return end
    self:swiChildView_(tag)
end

-------------------------------------------------
-- get / set

function AnniversaryRewardPreviewMeditaor:getViewData()
    return self.viewData_
end

function AnniversaryRewardPreviewMeditaor:getOwnerScene()
    return self.ownerScene_
end

function AnniversaryRewardPreviewMeditaor:getMediatorByTag(tag)
    return self.childMediaorClassMap_[tag]
end

function AnniversaryRewardPreviewMeditaor:CleanupView()
    for _, mdtClass in pairs(self.childMediaorClassMap_) do
        self:GetFacade():UnRegsitMediator(mdtClass.NAME)
    end
    self.mediatorStore = nil

    local viewComponent = self:GetViewComponent()
    if self.ownerScene_ and viewComponent and not tolua.isnull(viewComponent) then
        self.ownerScene_:RemoveDialog(viewComponent)
        self.ownerScene_ = nil
    end
end

function AnniversaryRewardPreviewMeditaor:OnRegist()
end

function AnniversaryRewardPreviewMeditaor:OnUnRegist()
    
end

return AnniversaryRewardPreviewMeditaor
