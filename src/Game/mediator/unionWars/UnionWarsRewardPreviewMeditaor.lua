--[[
工会战奖励预览mediator
--]]
local Mediator = mvc.Mediator
---@class UnionWarsRewardPreviewMeditaor :Mediator
local UnionWarsRewardPreviewMeditaor = class("UnionWarsRewardPreviewMeditaor", Mediator)
local NAME = "unionWars.UnionWarsRewardPreviewMeditaor"

local uiMgr    = app.uiMgr
local unionMgr = app.unionMgr

local UnionWarsRewardPreviewView = require("Game.views.unionWars.UnionWarsRewardPreviewView")

local VIEW_TAG = 1111
local CHILD_VIEW_TAG = {
    BASE = 100,
    RANK   = 101,
}
local TAB_CONFS = {
    {name = __('基础奖励'), tag = CHILD_VIEW_TAG.BASE},
    {name = __('排行奖励'), tag = CHILD_VIEW_TAG.RANK},
}

-- 排行奖励类型 
local RANK_REWARD_TYPE = 4

function UnionWarsRewardPreviewMeditaor:ctor(param ,  viewComponent )
    self.super:ctor(NAME,viewComponent)

    local unionWarsModel = unionMgr:getUnionWarsModel()
    self.viewStore       = {}
    self.skinId          = unionWarsModel.SHOW_CARD_ID
    self.curChildViewTag = CHILD_VIEW_TAG.BASE
    self.childViewMap_   = {
        [tostring(CHILD_VIEW_TAG.BASE)] = UnionWarsRewardPreviewView,
        [tostring(CHILD_VIEW_TAG.RANK)] = UnionWarsRewardPreviewView,
    }
end

function UnionWarsRewardPreviewMeditaor:InterestSignals()
    local signals = {
    }
    return signals
end

function UnionWarsRewardPreviewMeditaor:ProcessSignal( signal )
    local name = signal:GetName()
    local body = signal:GetBody() or {}
    
end

function UnionWarsRewardPreviewMeditaor:Initial( key )
    self.super:Initial(key)
    
    ---@type AnniversaryRewardPreviewView
    local viewComponent  = require('Game.views.anniversary.AnniversaryRewardPreviewView').new({mediatorName = NAME, tabConfs = TAB_CONFS})
    self.viewData_      = viewComponent:getViewData()
    self:InitRankView_()
    self:SetViewComponent(viewComponent)
    display.commonUIParams(viewComponent, {ap = display.CENTER, po = display.center})
    viewComponent:updateCardPreviewTipLabel(__('皮肤预览'))

    self.ownerScene_ = uiMgr:GetCurrentScene()
    self:GetOwnerScene():AddDialog(viewComponent)

    self:InitData_()

    self:InitView_()

    self:SwiChildView_(self.curChildViewTag)
end

-------------------------------------------------
-- private method

function UnionWarsRewardPreviewMeditaor:InitData_()
    -- challengePointRewards
    local confs = CommonUtils.GetConfigAllMess('warsRewards', 'union') or {}
    local datas = {
        [tostring(CHILD_VIEW_TAG.BASE)] = {},
        [tostring(CHILD_VIEW_TAG.RANK)] = {},
    }
    for key, value in orderedPairs(confs) do
        local flag = RANK_REWARD_TYPE == checkint(value.type) and CHILD_VIEW_TAG.RANK or CHILD_VIEW_TAG.BASE
        table.insert(datas[tostring(flag)], value)
    end
    self.datas = datas
end

function UnionWarsRewardPreviewMeditaor:InitRankView_()
    local viewData = self:GetViewData()
    local view     = viewData.view
    local size     = view:getContentSize()
    -----------------rankingBtn start-----------------
    local rankingBtn = display.newButton(size.width - 85, size.height - 51,
    {
        ap = display.CENTER,
        n = _res('ui/home/nmain/main_btn_rank.png'),
        enable = true,
    })
    view:addChild(rankingBtn)

    local rankingBG = display.newImageView(_res('ui/home/activity/ptDungeon/activity_ptfb_main_frame_btn_name.png'), size.width - 85, size.height - 96,
    {
        ap = display.CENTER,
    })
    view:addChild(rankingBG)

    local rankingLabel = display.newLabel(48, 18,
    {
        text = __('排行榜'),
        ap = display.CENTER,
        fontSize = 24,
        color = '#ffffff',
        font = TTF_GAME_FONT, ttf = true,
        outline = '#5b3c25',
    })
    rankingBG:addChild(rankingLabel)

    viewData.rankingBtn = rankingBtn
end

function UnionWarsRewardPreviewMeditaor:InitView_()
    local viewData = self:GetViewData()
    local tabs     = viewData.tabs
    for tag, tab in pairs(tabs) do
        display.commonUIParams(tab, {cb = handler(self, self.OnClickTabAction)})
    end

    display.commonUIParams(viewData.rankingBtn, {cb = handler(self, self.OnClickBtnAction)})
end

--==============================--
--desc: 切换子view
--@params viewTag int 视图标识
--@params data table  视图数据
--==============================--
function UnionWarsRewardPreviewMeditaor:SwiChildView_(viewTag)
    local view = self:GetViewByTag(tostring(viewTag))
    if view == nil then return end

    if not self.viewStore[viewTag] then
        local viewData     = self:GetViewData()
        local contentLayer = viewData.contentLayer
        local viewIns  = view.new()
        local contentLayerSize = contentLayer:getContentSize()
        contentLayer:addChild(viewIns)
        display.commonUIParams(viewIns,{po = cc.p(contentLayerSize.width / 2, contentLayerSize.height / 2), ap = display.CENTER})
        
        self.viewStore[viewTag] = viewIns
    end

    if self.curChildViewTag ~= viewTag then
        self:GetViewComponent():updateTab(self.curChildViewTag, false)
        self.viewStore[self.curChildViewTag]:setVisible(false)
        self.viewStore[viewTag]:setVisible(true)
        self.curChildViewTag = viewTag
    end

    self:GetViewComponent():updateTab(viewTag, true)
    self:GetViewComponent():updateCardPreviewBySkinId(self.skinId, handler(self, self.OnClickCardPreviewAction))
    self.viewStore[viewTag]:RefreshUI(self.datas[tostring(viewTag)], self.skinId)
end

function UnionWarsRewardPreviewMeditaor:OnClickTabAction(sender)
    local tag = sender:getTag()
    if self.curChildViewTag == tag then return end
    self:SwiChildView_(tag)
end

function UnionWarsRewardPreviewMeditaor:OnClickBtnAction(sender)
    local RankingListMediator = require( 'Game.mediator.RankingListMediator' )
    local mediator = RankingListMediator.new({rankTypes = RankTypes.UNION_WARS})
    self:GetFacade():RegistMediator(mediator)
end

function UnionWarsRewardPreviewMeditaor:OnClickCardPreviewAction(sender)
    local ShowCardSkinLayer = require('common.CommonCardGoodsDetailView').new({
        goodsId = self.skinId,
    })
    display.commonUIParams(ShowCardSkinLayer, {ap = display.CENTER, po = cc.p(display.cx, display.cy)})
    app.uiMgr:GetCurrentScene():AddDialog(ShowCardSkinLayer)
end
-------------------------------------------------
-- get / set

function UnionWarsRewardPreviewMeditaor:GetViewData()
    return self.viewData_
end

function UnionWarsRewardPreviewMeditaor:GetOwnerScene()
    return self.ownerScene_
end

function UnionWarsRewardPreviewMeditaor:GetViewByTag(tag)
    return self.childViewMap_[tag]
end

function UnionWarsRewardPreviewMeditaor:CleanupView()
    local viewComponent = self:GetViewComponent()
    if self.ownerScene_ and viewComponent and not tolua.isnull(viewComponent) then
        self.ownerScene_:RemoveDialog(viewComponent)
        self.ownerScene_ = nil
    end
end

function UnionWarsRewardPreviewMeditaor:OnRegist()
end

function UnionWarsRewardPreviewMeditaor:OnUnRegist()
    
end

return UnionWarsRewardPreviewMeditaor
