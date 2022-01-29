--[[
 * author : liuzhipeng
 * descpt : 杀人案（19夏活）积分奖励Mediator
--]]
local Mediator = mvc.Mediator
local MurderPointRewardsMediator = class("MurderPointRewardsMediator", Mediator)
local NAME = "Game.mediator.activity.murder.MurderPointRewardsMediator"
MurderPointRewardsMediator.NAME = NAME

function MurderPointRewardsMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.ctorArgs_ = checktable(params)
end

-------------------------------------------------
-- inheritance method
function MurderPointRewardsMediator:Initial(key)
    self.super.Initial(self, key)

    self.datas = {}
    self.isControllable_ = true

    -- create view
    local viewComponent = require('Game.views.activity.murder.MurderPointRewardsView').new({mediatorName = NAME})
    self.viewData_      = viewComponent:GetViewData()
    self:SetViewComponent(viewComponent)
    self:InitOwnerScene_()
    display.commonUIParams(viewComponent,{po = display.center, ap = display.CENTER})
    self:GetOwnerScene():AddDialog(viewComponent)

    -- init data
    self:InitData_(self.ctorArgs_.homeData or {})

    -- init view
    self:InitView_()
    
end

function MurderPointRewardsMediator:InitData_(homeData)
    local datas = {}
    local curPoint = nil
    local curPlot = 0

    ------------------------- 初始化剧情列表数据 -------------------------
    local serStory = homeData.unlockStoryInfo or {}
    local serUnlockStory = {}
    for i, v in ipairs(serStory) do
        serUnlockStory[tostring(v)] = v
    end

    local plotConf = CommonUtils.GetConfigAllMess('storyDamagePoint', 'newSummerActivity') or {}
    local plotDatas = {}
    if next(plotConf) ~= nil then
        local plotStaeIndexs = {}
        for i, plotData in orderedPairs(plotConf) do
            local goodsId  = checkint(app.murderMgr:GetPointGoodsId())
            local goodsNum = checkint(plotData.targetNum)
            if curPoint == nil then
                curPoint = app.murderMgr:GetPointNum()
            end
            if not serUnlockStory[tostring(plotData.storyId)] and curPoint >= goodsNum then
                -- plotStaeIndex = i
                table.insert(plotStaeIndexs, i)
            end
            table.insert(plotDatas, {
                targetGoodsId = goodsId,
                targetNum = goodsNum,
                storyId = plotData.storyId,
                state = self:InitPlotState(goodsNum, curPoint),
                unlockClockLevel = plotData.unlockClockLevel
            })
        end
        -- 设置最新剧情状态
        if next(plotStaeIndexs) ~= nil then
            for _, index in ipairs(plotStaeIndexs) do
                plotDatas[checkint(index)].state = 2
            end
        end
    end
        
    ------------------------- 初始化剧情奖励列表数据 -------------------------
    -- todo  从home 取
    local serPlotPointRewards = homeData.hasDrawnDamagePointRewards or {}
    local plotPointRewards = {}
    for i, v in ipairs(serPlotPointRewards) do
        plotPointRewards[tostring(v)] = v
    end
    local plotPointRewardDatas = {}
    local plotPointRewardsConf = CommonUtils.GetConfigAllMess('damageAccumulative', 'newSummerActivity') or {}
    local rarePlotPointRewardData = {}
    if next(plotPointRewardsConf) ~= nil then
        for i, v in orderedPairs(plotPointRewardsConf) do
            local consumeGoodsId = app.murderMgr:GetPointGoodsId()
            local consumeNum = checkint(v.num)
            local data = {confData = v, rewardsId = v.id, consumeGoodsId = consumeGoodsId, consumeNum = consumeNum, state = self:InitPlotRewardDrawState(plotPointRewards, v.id, consumeNum, curPoint)}
            if checkint(v.highlight) > 0 then
                rarePlotPointRewardData = data
            else
                table.insert(plotPointRewardDatas, data)
            end
        end
    end

    self:SortPlotRewards(plotPointRewardDatas)

    self.curPoint = curPoint
    self.plotDatas = plotDatas
    self.serUnlockStory = serUnlockStory
    self.plotPointRewards = plotPointRewards
    self.plotPointRewardDatas = plotPointRewardDatas
    self.rarePlotPointRewardData = rarePlotPointRewardData

end

--==============================--
--desc: 初始化剧情状态
--@params targetNum int    需求数量
--@params curPoint  int    当前数量
--@return state int 0 不满足条件 1 满足条件 2  满足条件并且是最新解锁剧情
--==============================--
function MurderPointRewardsMediator:InitPlotState(targetNum, curPoint)
    local state = 0
    if curPoint >= targetNum then
        state = 1
    end
    return state
end

--==============================--
--@desc: 初始化剧情奖励领取状态
--@params plotPointRewards table  已领取的剧情奖励ID
--@params rewardsId  int  剧情ID
--@params consume table  消耗列表
--@params curPoint  int  当前点数
--@return state int 1 不可领取 2 可领取 3 已领取
--==============================--
function MurderPointRewardsMediator:InitPlotRewardDrawState(plotPointRewards, rewardsId, consumeNum, curPoint)
    local state = 1
    if plotPointRewards[tostring(rewardsId)] then
        state = 3
    elseif curPoint >= checkint(consumeNum) then
        state = 2
    end
    return state
end

function MurderPointRewardsMediator:InitView_()
    local viewData = self:GetViewData()
    viewData.drawBtn:SetCallback(handler(self, self.OnClickDrawBtnAction))

    local viewComponent = self:GetViewComponent()
    viewData.tableView:setDataSourceAdapterScriptHandler(handler(self, self.OnDataSourceAdapter))
    viewComponent:UpdateTableView(self.plotPointRewardDatas)
    viewComponent:UpdateNumLabel(self.curPoint)
    viewComponent:UpdateRareReward(self.rarePlotPointRewardData)
    
    viewComponent:InitPlotListView(self.plotDatas)
    local plotLayer = viewData.plotLayer
    for i, node in ipairs(plotLayer:getChildren()) do
        if checkint(node:getTag()) > 0 then
            display.commonUIParams(node, {cb = handler(self, self.OnClicEnterPlotAction)})
        end
    end

end

function MurderPointRewardsMediator:InitOwnerScene_()
    self.ownerScene_ = app.uiMgr:GetCurrentScene()
end

function MurderPointRewardsMediator:cleanupView()
    local viewComponent = self:GetViewComponent()
    if self.ownerScene_ and viewComponent and not tolua.isnull(viewComponent) then
        self.ownerScene_:RemoveDialog(viewComponent)
        self.ownerScene_ = nil
    end
end


function MurderPointRewardsMediator:OnRegist()
    regPost(POST.MURDER_DRAW_DAMAGE_POINT_REWARDS)
    regPost(POST.MURDER_STORY_UNLOCK)
    self:EnterLayer()
end
function MurderPointRewardsMediator:OnUnRegist()
    unregPost(POST.MURDER_DRAW_DAMAGE_POINT_REWARDS)
    unregPost(POST.MURDER_STORY_UNLOCK)
    self:cleanupView()
end


function MurderPointRewardsMediator:InterestSignals()
    return {
        POST.MURDER_DRAW_DAMAGE_POINT_REWARDS.sglName,
        POST.MURDER_STORY_UNLOCK.sglName
    }
end

function MurderPointRewardsMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody() or {}

    if name == POST.MURDER_DRAW_DAMAGE_POINT_REWARDS.sglName then
        -- show reward
        local rewards = body.rewards or {}

        
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
        local rewardId = requestData.rewardId
        local homeData = self.ctorArgs_.homeData
        if homeData.hasDrawnDamagePointRewards then
            table.insert(homeData.hasDrawnDamagePointRewards, rewardId)
        else
            homeData.hasDrawnDamagePointRewards = {rewardId}
        end
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
        app:DispatchObservers(MURDER_PROGRESSBAR_REMINDICON_REFRESH)
    elseif POST.MURDER_STORY_UNLOCK.sglName == name then
        local requestData = body.requestData or {}
        local storyId = requestData.storyId
        local index = requestData.index
        local homeData = self.ctorArgs_.homeData or {}
        table.insert(homeData.unlockStoryInfo or {}, storyId)
        self.serUnlockStory[tostring(storyId)] = storyId

        -- 使用  storyId  反查 下标
        local data = nil
        local index = nil
        for i, v in ipairs(self.plotDatas) do
            if v.storyId == storyId then
                self.plotDatas[i].state = 1
                data = self.plotDatas[i]
                index = i
                break
            end
        end
        if data then
            self:GetViewComponent():UpdatePlotListNodeByIndex(index, data)
        end
        app.murderMgr:UnlockStory(storyId)
    end
end

-------------------------------------------------
-- get / set

function MurderPointRewardsMediator:GetViewData()
    return self.viewData_
end

function MurderPointRewardsMediator:GetOwnerScene()
    return self.ownerScene_
end

-------------------------------------------------
-- public method
function MurderPointRewardsMediator:EnterLayer()
end

function MurderPointRewardsMediator:RefreshUI()
    local viewComponent = self:GetViewComponent()
    -- viewComponent:InitPlotListView(self.plotDatas)

end

-------------------------------------------------
-- private method

function MurderPointRewardsMediator:SortPlotRewards(plotRewards)
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

function MurderPointRewardsMediator:OnDataSourceAdapter(p_convertview, idx)
    local pCell = p_convertview
    local index = idx + 1

    local viewComponent = self:GetViewComponent()
    if pCell == nil then
        local tableView = self:GetViewData().tableView
        pCell = viewComponent:CreateCell(tableView:getSizeOfCell())

        pCell.viewData.drawBtn:SetCallback(handler(self, self.OnClickDrawBtnAction))
    end

    xTry(function()

        viewComponent:UpdateCell(pCell.viewData,  self.plotPointRewardDatas[index] or {})

        pCell.viewData.drawBtn:setTag(index)
    end,__G__TRACKBACK__)
    return pCell
end

-------------------------------------------------
-- check

-------------------------------------------------
-- handler

function MurderPointRewardsMediator:OnClicEnterPlotAction(sender)
    local index = sender:getTag()
    -- local state   = checkint(sender:getUserTag())
    local data = self.plotDatas[index] or {}
    local state = checkint(data.state)
    local storyId = data.storyId
    if state == 0 then
        local storyCollectConf = CommonUtils.GetConfigAllMess('branchStoryCollection', 'newSummerActivity') or {}
        local storyCollect = storyCollectConf[tostring(storyId)] or {}
        local scene = app.uiMgr:GetCurrentScene()
        local CommonTip  = require( 'common.NewCommonTip' ).new({text = tostring(storyCollect.name), extra = app.murderMgr:GetPoText(__('解锁需要收集:')),
        richtext = {
            {text = data.targetNum, fontSize = 24, color = '#da3c3c'},
 			{img = CommonUtils.GetGoodsIconPathById(data.targetGoodsId), scale = 0.2},
        },
        richTextW = 80,
        isOnlyOK = true, callback = function ()
        end})
        CommonTip.extra:setHorizontalAlignment(display.TAC)
        CommonTip.richLabel:setPositionY(CommonTip.view:getContentSize().height * 0.4)
        CommonTip:setPosition(display.center)
        scene:AddDialog(CommonTip)
        return
    end

    local path = string.format("conf/%s/newSummerActivity/story.json",i18n.getLang())
    local stage = require( "Frame.Opera.OperaStage" ).new({
        id = storyId, path = path, guide = false, NoShowSkipBtn = false, 
        disableQuitBgMusic = true, showBackBtn = true, cb = function (tag)

        -- play bg music
        -- PlayBGMusic(AUDIOS.GHOST.Food_ghost_dancing.id)

        if not self.serUnlockStory[tostring(storyId)] then
            self:SendSignal(POST.MURDER_STORY_UNLOCK.cmdName , {
                storyId = storyId,
                index = index,
            })
            -- app:DispatchObservers(POST.MURDER_STORY_UNLOCK.sglName, {requestData = {storyId = storyId, index = index}})
        end

    end})
    stage:setPosition(cc.p(display.cx,display.cy))
    sceneWorld:addChild(stage, GameSceneTag.Dialog_GameSceneTag)
end

function MurderPointRewardsMediator:OnClickDrawBtnAction(sender)
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
        app.uiMgr:ShowInformationTips(string.format(app.murderMgr:GetPoText(__('当前%s数量不足')), tostring(goodsConfig.name)))
        return 
    elseif state == 3 then
        app.uiMgr:ShowInformationTips(app.murderMgr:GetPoText(__('已领取')))
        return 
    end

    self:SendSignal(POST.MURDER_DRAW_DAMAGE_POINT_REWARDS.cmdName, {rewardId = data.rewardsId, index = index})
    -- app:DispatchObservers(POST.MURDER_DRAW_DAMAGE_POINT_REWARDS.sglName, {rewards = {{goodsId = 151066, num = 11}}, requestData = {rewardId = data.rewardsId, index = index}})
end


return MurderPointRewardsMediator
