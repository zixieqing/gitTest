--[[
周年庆挑战奖励mediator
--]]
local Mediator = mvc.Mediator
---@class AnniversaryRankRewardMediator :Mediator
local AnniversaryRankRewardMediator = class("AnniversaryRankRewardMediator", Mediator)
local NAME = "anniversary.AnniversaryRankRewardMediator"
AnniversaryRankRewardMediator.NAME = NAME

local RANK_TAGS = {
    DAILY_OPERATE = 200,
    TOTAL_OPERATE = 201,
    INTEGRAL      = 202,
}

local SHOW_CARD_INDEX_CONF = {
    [RANK_TAGS.DAILY_OPERATE] = 2,
    [RANK_TAGS.TOTAL_OPERATE] = 3,
    [RANK_TAGS.INTEGRAL]      = 4,
}

local RULE_TAG = {
    [RANK_TAGS.DAILY_OPERATE] = "-13",
    [RANK_TAGS.TOTAL_OPERATE] = "-14",
    [RANK_TAGS.INTEGRAL]      = "-15",
}

local RANK_CONFS = {
    {name = app.anniversaryMgr:GetPoText(__('庆典积分排名')), tag = RANK_TAGS.INTEGRAL},
    {name = app.anniversaryMgr:GetPoText(__('每日摊位排名')), tag = RANK_TAGS.DAILY_OPERATE},
    {name = app.anniversaryMgr:GetPoText(__('摊位总排名')), tag = RANK_TAGS.TOTAL_OPERATE},
}

function AnniversaryRankRewardMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.ctorArgs_ = checktable(params)
end

-------------------------------------------------
-- inheritance method
function AnniversaryRankRewardMediator:Initial(key)
    self.super.Initial(self, key)

    self.datas = {}
    self.isControllable_ = true
    self.curTag = self.ctorArgs_.defTag or RANK_TAGS.INTEGRAL

    -- create view
    local viewComponent = require('Game.views.anniversary.AnniversaryRankRewardView').new({tabConfs = RANK_CONFS})
    self.viewData_      = viewComponent:getViewData()
    self:SetViewComponent(viewComponent)
    
    -- init data
    self:initData_()

    -- init view
    self:initView_()
    
end

function AnniversaryRankRewardMediator:initData_()

end

function AnniversaryRankRewardMediator:initView_()
    local viewData = self:getViewData()
    local tableView = viewData.tableView
    tableView:setDataSourceAdapterScriptHandler(handler(self, self.onDataSourceAdapter))

    local ruleBtn        = viewData.ruleBtn
    display.commonUIParams(ruleBtn, {cb = handler(self, self.onClickRuleBtnAction)})
    
    local tabCells       = viewData.tabCells
    for tag, tabCell in pairs(tabCells) do
        display.commonUIParams(tabCell, {cb = handler(self, self.onClickTabCellAction)})
        tabCell:setTag(checkint(tag))

        if checkint(tag) == self.curTag then
            self:GetViewComponent():updateTabCellShowState(tabCell, true)
        end
    end

end

function AnniversaryRankRewardMediator:CleanupView()
end


function AnniversaryRankRewardMediator:OnRegist()
    regPost(POST.ANNIVERSARY_MY_RANK)
    self:enterLayer()
end
function AnniversaryRankRewardMediator:OnUnRegist()
    unregPost(POST.ANNIVERSARY_MY_RANK)
end


function AnniversaryRankRewardMediator:InterestSignals()
    return {
        POST.ANNIVERSARY_MY_RANK.sglName
    }
end

function AnniversaryRankRewardMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody() or {}

    if name == POST.ANNIVERSARY_MY_RANK.sglName then
        self.datas    = {}
        self.serDatas = body

        self:updateUI(self.curTag)
    end
end

-------------------------------------------------
-- get / set

function AnniversaryRankRewardMediator:getViewData()
    return self.viewData_
end

function AnniversaryRankRewardMediator:getOwnerScene()
    return self.ownerScene_
end

function AnniversaryRankRewardMediator:getServerDataFieldNameByTag(tag)
    local conf = {
        [RANK_TAGS.DAILY_OPERATE] = 'myDailyMarketRank',
        [RANK_TAGS.TOTAL_OPERATE] = 'myTotalMarketRank',
        [RANK_TAGS.INTEGRAL]      = 'myChallengeRank',
    }
    return conf[tag]
end

function AnniversaryRankRewardMediator:getRankConfNameByTag(tag)
    local conf = {
        [RANK_TAGS.DAILY_OPERATE] = 'marketDailyRankRewards',
        [RANK_TAGS.TOTAL_OPERATE] = 'marketTotalRankRewards',
        [RANK_TAGS.INTEGRAL]      = 'challengeRankRewards',
    }
    return conf[tag]
end

function AnniversaryRankRewardMediator:getRankConfDataByTag(tag)
    return CommonUtils.GetConfigAllMess(self:getRankConfNameByTag(tag), 'anniversary') or {}
end

function AnniversaryRankRewardMediator:getRankDataByTag(tag)
    local rankData = {
        rankList = {}
    }
    local filedName = self:getServerDataFieldNameByTag(tag)
    local serData = self.serDatas[filedName] or {}
    table.merge(rankData, serData)
    local confDatas = self:getRankConfDataByTag(tag)
    for i, confData in orderedPairs(confDatas) do
        table.insert(rankData.rankList, {
            confData = confData,
        })
    end
    return rankData
end

-------------------------------------------------
-- public method
function AnniversaryRankRewardMediator:enterLayer()
    -- local rd = function ()
    --     return  {
    --         rank = math.random(0, 100000),
    --         score = math.random(0, 100000),
    --         rangeId = math.random(0, 10),
    --     }
    -- end
    -- app:DispatchObservers(POST.ANNIVERSARY_MY_RANK.sglName, {
    --     dailyMarketRank = rd(),
    --     totalMarketRank = rd(),
    --     challengeRank = rd(),
    -- })
    self:SendSignal(POST.ANNIVERSARY_MY_RANK.cmdName)
end

function AnniversaryRankRewardMediator:refreshUI(isRefreshUI)
    self:updateCardPreview()
end

function AnniversaryRankRewardMediator:updateCardPreview()
    app:DispatchObservers('ANNIVERSARY_REWARD_PREVIEW_REFRESH_CARD_PREVIEW', {showCardIndex = SHOW_CARD_INDEX_CONF[self.curTag]})
end

function AnniversaryRankRewardMediator:updateUI(tag)
    if self.datas[tag] == nil then
        self.datas[tag] = self:getRankDataByTag(tag)
    end
    self:GetViewComponent():updateUI(self.datas[tag], tag)
end

-------------------------------------------------
-- private method
function AnniversaryRankRewardMediator:onDataSourceAdapter(p_convertview, idx)
    local pCell = p_convertview
    local index = idx + 1
    
    if pCell == nil then
        local tableView = self:getViewData().tableView
        pCell = self:GetViewComponent():CreateCell(tableView:getSizeOfCell())
    end

    xTry(function()
        local rankDatas = self.datas[self.curTag] or {}
        local rangeId   = checkint(rankDatas.rangeId)
        local rankList  = rankDatas.rankList or {}
        
        self:GetViewComponent():updateCell(pCell.viewData, rankList[index] or {}, rangeId)
    end,__G__TRACKBACK__)
    return pCell
end

-------------------------------------------------
-- check

-------------------------------------------------
-- handler
function AnniversaryRankRewardMediator:onBtnAction(sender)
end

function AnniversaryRankRewardMediator:onClickRuleBtnAction(sender)
    local ruleTag = RULE_TAG[self.curTag]
    if ruleTag then
        app.uiMgr:ShowIntroPopup({moduleId = ruleTag})
    end
end

function AnniversaryRankRewardMediator:onClickTabCellAction(sender)
    local tag = sender:getTag()
    if tag == self.curTag then return end

    local viewData       = self:getViewData()
    local tabCells       = viewData.tabCells
    local viewComponent  = self:GetViewComponent()
    viewComponent:updateTabCellShowState(tabCells[tostring(self.curTag)], false)
    viewComponent:updateTabCellShowState(tabCells[tostring(tag)], true)
    self.curTag = tag
    self:updateUI(tag)
    self:updateCardPreview()
end

return AnniversaryRankRewardMediator
