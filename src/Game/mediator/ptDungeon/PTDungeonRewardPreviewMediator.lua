--[[
周年庆奖励预览mediator
--]]
local Mediator = mvc.Mediator
---@class PTDungeonRewardPreviewMediator :Mediator
local PTDungeonRewardPreviewMediator = class("PTDungeonRewardPreviewMediator", Mediator)
local NAME = "PTDungeonRewardPreviewMediator"

local uiMgr = app.uiMgr

local CHILD_VIEW_TAG = {
    SCORE_RANKING       = 100,
    HIGHEST_DAMAGE      = 101,
}

function PTDungeonRewardPreviewMediator:ctor(param ,  viewComponent )
    self.super:ctor(NAME,viewComponent)
    self.curChildViewTag = CHILD_VIEW_TAG.SCORE_RANKING
    self.ctorArgs_ = checktable(param)
    self.activityId = checktable(self.ctorArgs_.requestData).activityId
    self.ptId = tostring(self.ctorArgs_.ptId) or '1'
    self.data = {}
    self.scoreDotLabels = string.split(__('当前段位最后一名pt点数：|_num_|'), '|')
    self.damageDotLabels = string.split(__('当前段位最后一名累计伤害：|_num_|'), '|')
end

function PTDungeonRewardPreviewMediator:InterestSignals()
    local signals = {
        POST.PT_RANK.sglName,
    }
    return signals
end

function PTDungeonRewardPreviewMediator:ProcessSignal( signal )
    local name = signal:GetName()
    local body = signal:GetBody() or {}
    -- dump(body, name)
    if name == POST.PT_RANK.sglName then
        self.data = body
        self:UpdateStatus()
    end
end

function PTDungeonRewardPreviewMediator:Initial( key )
    self.super.Initial(self, key)
    
    ---@type PTDungeonRewardPreviewView
    local viewComponent  = require('Game.views.ptDungeon.PTDungeonRewardPreviewView').new({mediatorName = NAME})
    self.viewData_      = viewComponent:getViewData()
    self:SetViewComponent(viewComponent)
    display.commonUIParams(viewComponent, {ap = display.CENTER, po = display.center})

    self.ownerScene_ = uiMgr:GetCurrentScene()
    self:getOwnerScene():AddDialog(viewComponent)

    self:initView_()
    display.commonUIParams(self.viewData_.rankingBtn, {cb = handler(self, self.onClickTipsAction)})

    self:swiChildView_(self.curChildViewTag)
end

-------------------------------------------------
-- private method

function PTDungeonRewardPreviewMediator:initView_()
    local viewData = self:getViewData()
    local tabs     = viewData.tabs
    for tag, tab in pairs(tabs) do
        display.commonUIParams(tab, {cb = handler(self, self.onClickTabAction)})
    end

    local integralLabel = viewData.integralLabel
    integralLabel:setString(self.ctorArgs_.point)

    local confId = self.ctorArgs_.cardPicture
    viewData.rewardBg:setTexture(_res('ui/home/capsule/activityCapsule/summon_pre_img_' .. confId))
    viewData.rewardBg:setScale(0.85)
    local cardPreviewBtn = viewData.cardPreviewBtn
    local oldConfId = checkint(cardPreviewBtn:getTag())
    if oldConfId == checkint(confId) then return end
    cardPreviewBtn:RefreshUI({confId = confId})

    local pointRankRewards = CommonUtils.GetConfigAllMess('pointRankRewards', 'pt')[self.ptId]
    self.pointRankRewards = pointRankRewards
    local tableView = viewData.tableView
    tableView:setDataSourceAdapterScriptHandler(handler(self, self.onDataSourceAdapter))
    
    local damageRankRewards = CommonUtils.GetConfigAllMess('damageRankRewards', 'pt')[self.ptId]
    self.damageRankRewards = damageRankRewards
end

function PTDungeonRewardPreviewMediator:onClickTipsAction()
    -- uiMgr:ShowIntroPopup({moduleId = '-23'})
    local mediator = require( 'Game.mediator.ptDungeon.PTDungeonRankMediator').new({data = self.data, ptId = self.ptId})
    app:RegistMediator(mediator)
end

function PTDungeonRewardPreviewMediator:onDataSourceAdapter(p_convertview, idx)
    local pCell = p_convertview
    local index = idx + 1
    
    if pCell == nil then
        pCell = self:GetViewComponent():CreateRankTabCell()
    end

    xTry(function()
        local viewData = pCell.viewData
        local RankReward = self.SourceData[index]

        viewData.titleLabel:setString(RankReward.title)

        local rewardLayer      = viewData.rewardLayer
        local rewardLayerSize = rewardLayer:getContentSize()
        local width = rewardLayerSize.width / 2 - (table.nums(RankReward.rewards) - 1) * 47
        local height = rewardLayerSize.height / 2
        local rewardNodes      = viewData.rewardNodes
        local num = table.nums(rewardNodes)
        for k,v in pairs(rewardNodes) do
            v:setVisible(false)
        end
        for i,v in ipairs(RankReward.rewards) do
            local goodNode
            if tonumber(i) > tonumber(num) then
                goodNode = require('common.GoodNode').new({id = v.goodsId, amount = v.num, showAmount = true, callBack = function (sender)
                    app.uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = sender.goodId, type = 1})
                end})
                goodNode:setScale(0.8)
                rewardLayer:addChild(goodNode)
                table.insert(rewardNodes, goodNode)
            else
                goodNode = rewardNodes[i]
                goodNode:setVisible(true)
                goodNode:RefreshSelf({id = v.goodsId, amount = v.num})
            end
            display.commonUIParams(goodNode, {po = cc.p(width + (i - 1) * 94, height)})
        end
        local cur = CHILD_VIEW_TAG.SCORE_RANKING == self.curChildViewTag and self.data.myRangeId or self.data.myDamageRangeId
        pCell.viewData.cellSelectImg:setVisible(tonumber(cur) == tonumber(RankReward.id))
        pCell.viewData.tipsBg:setVisible(tonumber(cur) == tonumber(RankReward.id))

        if CHILD_VIEW_TAG.SCORE_RANKING == self.curChildViewTag then
            local texts = {}
            local sourceRangeRank = self.data.pointRangeRank or {}
            for k,v in pairs(self.scoreDotLabels) do
                if '_num_' == v then
                    if sourceRangeRank[tostring(index)] then
                        table.insert(texts, checkint(sourceRangeRank[tostring(index)].score))
                    else
                        texts = {}
                        break
                    end
                elseif '' ~= v then
                    table.insert(texts, v)
                end
            end
            pCell.viewData.curDotLabel:setString(table.concat( texts ))
        else
            local texts = {}
            local sourceRangeRank = self.data.damageRangeRank or {}
            for k,v in pairs(self.damageDotLabels) do
                if '_num_' == v then
                    if sourceRangeRank[tostring(index)] then
                        table.insert(texts, checkint(sourceRangeRank[tostring(index)].score))
                    else
                        texts = {}
                        break
                    end
                elseif '' ~= v then
                    table.insert(texts, v)
                end
            end
            pCell.viewData.curDotLabel:setString(table.concat( texts ))
        end
        
    end,__G__TRACKBACK__)
    return pCell
end

--==============================--
--desc: 切换子view
--@params viewTag int 视图标识
--==============================--
function PTDungeonRewardPreviewMediator:swiChildView_(viewTag)
    self:GetViewComponent():updateTab(self.curChildViewTag, false)
    self.curChildViewTag = viewTag
    self:GetViewComponent():updateTab(viewTag, true)

    local viewData = self:getViewData()
    local tableView = viewData.tableView
    if CHILD_VIEW_TAG.SCORE_RANKING == viewTag then
        self.SourceData = self.pointRankRewards
    else
        self.SourceData = self.damageRankRewards
    end
    tableView:setCountOfCell(table.nums(self.SourceData))
    tableView:reloadData()
    self:UpdateStatus()
end

function PTDungeonRewardPreviewMediator:UpdateStatus(  )
    local viewData = self:getViewData()
    local tableView = viewData.tableView
    -- 玩家的档位
    if CHILD_VIEW_TAG.SCORE_RANKING == self.curChildViewTag then
        local MyRank = __('未入榜')
        if self.data.myRangeId then
            MyRank = self.pointRankRewards[tonumber(self.data.myRangeId)].title

            local cell = tableView:cellAtIndex(tonumber(self.data.myRangeId) - 1)
            if cell then
                cell.viewData.cellSelectImg:setVisible(true)
                cell.viewData.tipsBg:setVisible(true)
            end
        end
        self:GetViewComponent():refreshUI({{title = __('当前pt点数'), num = self.ctorArgs_.point},{title = __('当前段位'), num = MyRank}})
    else
        local damageRank = self.data.damageRank or {}
        local first = damageRank[1] or {}
        self:GetViewComponent():refreshUI({{title = __('最高累计伤害'), num = checkint(first.score)},{title = __('我的累计伤害'), num = checkint(self.data.myDamage)}})

        if self.data.myDamageRangeId then
            local cell = tableView:cellAtIndex(tonumber(self.data.myDamageRangeId) - 1)
            if cell then
                cell.viewData.cellSelectImg:setVisible(true)
                cell.viewData.tipsBg:setVisible(true)
            end
        end
    end

    -- 档位最低
    if CHILD_VIEW_TAG.SCORE_RANKING == self.curChildViewTag then
        local texts = {}
        local sourceRangeRank = self.data.pointRangeRank or {}
        for i=1,table.nums(sourceRangeRank) do
            for k,v in pairs(self.scoreDotLabels) do
                if '_num_' == v then
                    if sourceRangeRank[tostring(i)] then
                        table.insert(texts, checkint(sourceRangeRank[tostring(i)].score))
                    else
                        texts = {}
                        break
                    end
                elseif '' ~= v then
                    table.insert(texts, v)
                end
            end
            local cell = tableView:cellAtIndex(i - 1)
            if cell then
                cell.viewData.curDotLabel:setString(table.concat( texts ))
            end
            texts = {}
        end
    else
        local texts = {}
        local sourceRangeRank = self.data.damageRangeRank or {}
        for i=1,table.nums(sourceRangeRank) do
            for k,v in pairs(self.damageDotLabels) do
                if '_num_' == v then
                    if sourceRangeRank[tostring(i)] then
                        table.insert(texts, checkint(sourceRangeRank[tostring(i)].score))
                    else
                        texts = {}
                        break
                    end
                elseif '' ~= v then
                    table.insert(texts, v)
                end
            end
            local cell = tableView:cellAtIndex(i - 1)
            if cell then
                display.commonLabelParams(cell.viewData.curDotLabel , {reqW = 420  , text = table.concat( texts ) })

            end
            texts = {}
        end
    end
end

function PTDungeonRewardPreviewMediator:onClickTabAction(sender)
    local tag = sender:getTag()
    if self.curChildViewTag == tag then return end
    self:swiChildView_(tag)
end

-------------------------------------------------
-- get / set

function PTDungeonRewardPreviewMediator:getViewData()
    return self.viewData_
end

function PTDungeonRewardPreviewMediator:getOwnerScene()
    return self.ownerScene_
end

function PTDungeonRewardPreviewMediator:CleanupView()
    local viewComponent = self:GetViewComponent()
    if self.ownerScene_ and viewComponent and not tolua.isnull(viewComponent) then
        self.ownerScene_:RemoveDialog(viewComponent)
        self.ownerScene_ = nil
    end
end

function PTDungeonRewardPreviewMediator:enterLayer()
	self:SendSignal(POST.PT_RANK.cmdName, {activityId = self.activityId})
end

function PTDungeonRewardPreviewMediator:OnRegist()
    regPost(POST.PT_RANK)
    self:enterLayer()
end

function PTDungeonRewardPreviewMediator:OnUnRegist()
    unregPost(POST.PT_RANK)
end

return PTDungeonRewardPreviewMediator
