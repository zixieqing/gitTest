--[[
奖励mediator
--]]
local Mediator = mvc.Mediator
---@class Anniversary19PlotRewardMediator :Mediator
local Anniversary19PlotRewardMediator = class("Anniversary19PlotRewardMediator", Mediator)
local NAME = "anniversary19.Anniversary19PlotRewardMediator"
Anniversary19PlotRewardMediator.NAME = NAME

local app = app

local RANK_REWARD_TYPE = {
    BASE    = 0,
    ADVANCE = 1,
}

function Anniversary19PlotRewardMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.ctorArgs_ = checktable(params)
end

-------------------------------------------------
-- inheritance method
function Anniversary19PlotRewardMediator:Initial(key)
    self.super.Initial(self, key)

    self.datas = {}
    self.isControllable_ = true

    -- create view
    local viewComponent = require('Game.views.anniversary19.Anniversary19PlotRewardView').new({mediatorName = NAME})
    self.viewData_      = viewComponent:GetViewData()
    self:SetViewComponent(viewComponent)
    self:InitOwnerScene_()
    display.commonUIParams(viewComponent,{po = display.center, ap = display.CENTER})
    self:GetOwnerScene():AddDialog(viewComponent)

    -- init data
    self:InitData_()

    -- init view
    self:InitView_()
    
end

function Anniversary19PlotRewardMediator:InitData_()
    local mgr = app.anniversary2019Mgr
    local consumeGoodsId = mgr:GetIntegralGoodsId()
    local homeData = mgr:GetHomeData()
    local curPoint = app.gameMgr:GetAmountByGoodId(consumeGoodsId)

    ------------------------- 初始化排行奖励数据 -------------------------
    
    local parameterConf =  CommonUtils.GetConfigAllMess('parameter', 'anniversary2') or {}
    local rankBaseRewards = parameterConf.rankBaseRewards or {}
    local chapterConf =  CommonUtils.GetConfigAllMess('chapter', 'anniversary2') or {}
    local rankRewards = {
        {rewards = rankBaseRewards, desc = app.anniversary2019Mgr:GetPoText(__('每个梦境中参与击杀boss次数前100的玩家可获得')), type = RANK_REWARD_TYPE.BASE}
    }

    for index, value in orderedPairs(chapterConf) do
        table.insert(rankRewards, {rewards = {{goodsId = value.rewardGoodsId, num = 1}},
             desc = string.format(app.anniversary2019Mgr:GetPoText(__('参与击杀%s数量前10的玩家可获得：')), value.bossName), type = RANK_REWARD_TYPE.ADVANCE})
    end

    ------------------------- 初始化积分奖励数据 -------------------------
    local pointRewardDrawn = homeData.pointRewardDrawn or {}
    
    local plotPointRewards = {}
    for i, v in ipairs(pointRewardDrawn) do
        plotPointRewards[tostring(v)] = v
    end
    local plotPointRewardDatas = {}
    local rarePlotPointRewardData = {}
    local pointRewardsConfs = CommonUtils.GetConfigAllMess('point', 'anniversary2') or {}
    if next(pointRewardsConfs) ~= nil then
        for i, v in orderedPairs(pointRewardsConfs) do
            local rewardsId = v.id
            local consumeNum = checkint(v.targetNum)
            local data = {confData = v, rewardsId = rewardsId, consumeGoodsId = consumeGoodsId, 
                consumeNum = consumeNum, state = self:InitPlotRewardDrawState(plotPointRewards, rewardsId, consumeNum, curPoint)}
            if checkint(v.highlight) > 0 then
                rarePlotPointRewardData = data
            else
                table.insert(plotPointRewardDatas, data)
            end
        end

        self:SortPlotRewards(plotPointRewardDatas)
    end

    self.curPoint                = curPoint
    self.consumeGoodsId          = consumeGoodsId
    self.rankRewards             = rankRewards
    self.plotPointRewards        = plotPointRewards
    self.plotPointRewardDatas    = plotPointRewardDatas
    self.rarePlotPointRewardData = rarePlotPointRewardData
end

--==============================--
--@desc: 初始化剧情奖励领取状态
--@params plotPointRewards table  已领取的剧情奖励ID
--@params rewardsId  int  剧情ID
--@params consumeNum int  消耗数量
--@params curPoint   int  当前点数
--@return state int 1 不可领取 2 可领取 3 已领取
--==============================--
function Anniversary19PlotRewardMediator:InitPlotRewardDrawState(plotPointRewards, rewardsId, consumeNum, curPoint)
    local state = 1
    if plotPointRewards[tostring(rewardsId)] then
        state = 3
    elseif curPoint >= checkint(consumeNum) then
        state = 2
    end
    return state
end

function Anniversary19PlotRewardMediator:InitView_()
    local viewData = self:GetViewData()
    viewData.drawBtn:SetCallback(handler(self, self.OnClickDrawBtnAction))

    display.commonUIParams(viewData.rankBtn, {cb = handler(self , self.OnClickRankBtnAction)})

    local viewComponent = self:GetViewComponent()
    viewData.tableView:setDataSourceAdapterScriptHandler(handler(self, self.OnDataSourceAdapter))
    viewComponent:UpdateTableView(self.plotPointRewardDatas)
    viewComponent:UpdateCollLabel(viewData, self.consumeGoodsId)
    viewComponent:UpdateNumLabel(self.curPoint)
    viewComponent:UpdateRareReward(self.rarePlotPointRewardData)

    viewComponent:InitRankRewardListView(self.rankRewards)
end

function Anniversary19PlotRewardMediator:InitOwnerScene_()
    self.ownerScene_ = app.uiMgr:GetCurrentScene()
end

function Anniversary19PlotRewardMediator:cleanupView()
    local viewComponent = self:GetViewComponent()
    if self.ownerScene_ and viewComponent and not tolua.isnull(viewComponent) then
        self.ownerScene_:RemoveDialog(viewComponent)
        self.ownerScene_ = nil
    end
end


function Anniversary19PlotRewardMediator:OnRegist()
    regPost(POST.ANNIVERSARY2_POINT_REWARD_DRAW)
    
    self:EnterLayer()
end
function Anniversary19PlotRewardMediator:OnUnRegist()
    unregPost(POST.ANNIVERSARY2_POINT_REWARD_DRAW)
    self:cleanupView()
end


function Anniversary19PlotRewardMediator:InterestSignals()
    return {
        POST.ANNIVERSARY2_POINT_REWARD_DRAW.sglName,
        
    }
end

function Anniversary19PlotRewardMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody() or {}

    if name == POST.ANNIVERSARY2_POINT_REWARD_DRAW.sglName then

        -- update local data cache data
        local requestData = body.requestData or {}
        local index = requestData.index
        local data = nil
        if index == -1 then
            data = self.rarePlotPointRewardData
        else
            data = self.plotPointRewardDatas[index] or {}
        end
        data.state = 3

        -- update home data cache data
        local rewardId = requestData.pointId
        local homeData = app.anniversary2019Mgr:GetHomeData()
        if homeData.pointRewardDrawn then
            table.insert(homeData.pointRewardDrawn, rewardId)
        else
            homeData.pointRewardDrawn = {rewardId}
        end

        -- show reward
        local rewards = body.rewards or {}
        -- 修改完homeData 的数据在进行刷新的判断
        if next(rewards) ~= nil then
            app.uiMgr:AddDialog('common.RewardPopup', {rewards = rewards})
        end

        -- update reward cell
        if index == -1 then
            self:GetViewData().drawBtn:RefreshUI({drawState = data.state})
        else
            local tableView = self:GetViewData().tableView
            local cell = tableView:cellAtIndex(index - 1)
            if cell then
                self:GetViewComponent():UpdateCell(cell.viewData,  data)
            end
        end
    
    end
end

-------------------------------------------------
-- get / set

function Anniversary19PlotRewardMediator:GetViewData()
    return self.viewData_
end

function Anniversary19PlotRewardMediator:GetOwnerScene()
    return self.ownerScene_
end

-------------------------------------------------
-- public method
function Anniversary19PlotRewardMediator:EnterLayer()
end

function Anniversary19PlotRewardMediator:RefreshUI()
    local viewComponent = self:GetViewComponent()
    -- viewComponent:InitPlotListView(self.plotDatas)

end

-------------------------------------------------
-- private method

function Anniversary19PlotRewardMediator:SortPlotRewards(plotRewards)
    if next(plotRewards) == nil then return end
    local getPriority = function (data)
        local state = data.state
        if state == 3 then
            return 1
        elseif state == 2 then
            return 3
        elseif state == 1 then
            return 2
        end
        return 0
    end
    table.sort(plotRewards, function (a, b)
        local aPriority = getPriority(a)
        local bPriority = getPriority(b)
        if aPriority ~= bPriority then
            return aPriority > bPriority
        end
        return a.rewardsId < b.rewardsId
    end)
end

function Anniversary19PlotRewardMediator:OnDataSourceAdapter(p_convertview, idx)
    local pCell = p_convertview
    local index = idx + 1

    local data = self.plotPointRewardDatas[index] or {}
    local viewComponent = self:GetViewComponent()
    if pCell == nil then
        local tableView = self:GetViewData().tableView
        pCell = viewComponent:CreateCell(tableView:getSizeOfCell())
        pCell.viewData.pointIcon:setTexture(CommonUtils.GetGoodsIconPathById(data.consumeGoodsId))
        pCell.viewData.drawBtn:SetCallback(handler(self, self.OnClickDrawBtnAction))
    end

    xTry(function()

        viewComponent:UpdateCell(pCell.viewData, data)

        pCell.viewData.drawBtn:setTag(index)
    end,__G__TRACKBACK__)
    return pCell
end

-------------------------------------------------
-- check

-------------------------------------------------
-- handler

function Anniversary19PlotRewardMediator:OnClickDrawBtnAction(sender)
    PlayAudioByClickNormal()

    local index = checkint(sender:getTag())
    local data = nil
    if index == -1 then
        data = self.rarePlotPointRewardData
    else
        data = self.plotPointRewardDatas[index] or {}
    end

    local state = data.state
    if state == 1 then
        local goodsConfig = CommonUtils.GetConfig('goods', 'goods', data.consumeGoodsId) or {}
        app.uiMgr:ShowInformationTips(string.format(app.anniversary2019Mgr:GetPoText(__('当前%s数量不足')), tostring(goodsConfig.name)))
        return 
    elseif state == 3 then
        app.uiMgr:ShowInformationTips(app.anniversary2019Mgr:GetPoText(__('已领取')))
        return 
    end

    self:SendSignal(POST.ANNIVERSARY2_POINT_REWARD_DRAW.cmdName, {pointId = data.rewardsId, index = index})
    -- app:DispatchObservers(POST.ANNIVERSARY2_POINT_REWARD_DRAW.sglName, {rewards = {{goodsId = 151066, num = 11}}, requestData = {rewardId = data.rewardsId, index = index}})
end

function Anniversary19PlotRewardMediator:OnClickRankBtnAction(sender)
    PlayAudioByClickNormal()

    local mediator = require("Game.mediator.anniversary19.Anniversary19RankMediator").new()
    app:RegistMediator(mediator)    
end



return Anniversary19PlotRewardMediator
