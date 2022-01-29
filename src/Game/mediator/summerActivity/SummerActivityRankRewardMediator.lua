--[[
 * descpt : 夏活首页 中介者
]]
local NAME = 'summerActivity.SummerActivityRankRewardMediator'
local SummerActivityRankRewardMediator = class(NAME, mvc.Mediator)

local appIns   = AppFacade.GetInstance()
local uiMgr    = appIns:GetManager('UIManager')
local summerActMgr = appIns:GetManager("SummerActivityManager")

local TAB_CONFIG = {
    'SummerActivityPlayRewardView',
    'SummerActivityTotalDotRewardView',
    'SummerActivityDamageRewardView',
}

function SummerActivityRankRewardMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)

    -- 根据配表奖励个数 区分 界面
    local confDatas = summerActMgr:GetConfigDataByName(summerActMgr:GetConfigParse().TYPE.QUEST_REWARDS) or {}
    local count = 0
    for key, value in pairs(confDatas) do
        count = count + 1;
        if count > 1 then
            break
        end
    end
    if count > 1 then
        TAB_CONFIG[1] = 'SummerActivityPlayRewardNewView' 
    else
        TAB_CONFIG[1] = 'SummerActivityPlayRewardView' 
    end
    self.ctorArgs_ = checktable(params)
end

-------------------------------------------------
-- inheritance method
function SummerActivityRankRewardMediator:Initial(key)
    self.super.Initial(self, key)

    self.datas           = {}
    self.viewStore       = {}
    self.preChoiceIndex  = nil
    self.isControllable_ = true
    
    -- create view
    local viewComponent = require('Game.views.summerActivity.SummerActivityRankRewardView').new({mediatorName = NAME})
    self.viewData_      = viewComponent:getViewData()
    self:SetViewComponent(viewComponent)
    -- add layer
    self:initOwnerScene_()
    display.commonUIParams(viewComponent,{po = display.center, ap = display.CENTER})
    self:getOwnerScene():AddDialog(viewComponent)

    -- init view
    -- self:initData_()

    -- init view
    self:initView_()
    
end

function SummerActivityRankRewardMediator:initOwnerScene_()
    self.ownerScene_ = uiMgr:GetCurrentScene()
end

function SummerActivityRankRewardMediator:initDataByName(name, tag)
    if name == 'SummerActivityPlayRewardView' then
        self.datas[tag] = summerActMgr:GetPlayRewardDatasByQuestTimes(checkint(self.ctorArgs_.questTimes), checkint(self.ctorArgs_.questOverHasDraw))
    elseif name == 'SummerActivityPlayRewardNewView' then
        self.datas[tag] = summerActMgr:GetNewPlayRewardDatasByQuestTimes(checkint(self.ctorArgs_.questTimes), checktable(self.ctorArgs_.questTimesDrawn))
    elseif name == 'SummerActivityTotalDotRewardView' then
        local mySummerPointRank = checkint(self.ctorArgs_.mySummerPointRank)
        local summerPointRank   = self.ctorArgs_.summerPointRank or {}
        self.datas[tag] = summerActMgr:GetPointRankDataByRank(mySummerPointRank, summerPointRank)
    elseif name == 'SummerActivityDamageRewardView' then
        self.datas[tag] = summerActMgr:GetDamageRankRewardData()
    end
end

function SummerActivityRankRewardMediator:initView_()
    local viewData     = self:getViewData()
    local tabs         = viewData.tabs
    for i, tab in ipairs(tabs) do
        display.commonUIParams(tab, {cb = handler(self, self.onClickTabAction)})
        tab:setTag(i)
    end

end

function SummerActivityRankRewardMediator:initChildView(childName, tag)
    local view = self.viewStore[childName]
    if view == nil then return end

    self:initDataByName(childName, tag)

    local childViewData = view:getViewData()
    local gridView = childViewData.gridView
    if childName == 'SummerActivityPlayRewardView' then
        local data = self.datas[tag]
        childViewData.drawBtn:setOnClickScriptHandler(handler(self, self.DrawButtonCallback))
        childViewData.progressBar:setMaxValue(data.targetTimes)
        childViewData.progressBar:setValue(data.questTimes)
        childViewData.progressLabel:setString(string.format('%d/%d', math.min(data.questTimes, data.targetTimes), data.targetTimes))
        self:RefreshDrawBtnState()
        return 
    elseif childName == 'SummerActivityPlayRewardNewView' then
        local data = self.datas[tag]
        local overRewardDatas = data.overRewardDatas
        local conf = overRewardDatas.conf
        childViewData.rewardCell:refreshUI(conf, 1, false, summerActMgr:getThemeTextByText(__('累计完成小丑关卡奖励')))
        childViewData.drawBtn:RefreshUI({drawState = overRewardDatas.state})

        local maxValue = checkint(conf.times)
        local value = checkint(self.ctorArgs_.questTimes)
        local progressBar = childViewData.progressBar
        progressBar:setMaxValue(maxValue)
        progressBar:setValue(value > maxValue and maxValue or value)
        display.commonLabelParams(childViewData.progressLabel, {text = string.format('%s/%s', value, maxValue)})

        local tableView = childViewData.tableView
        tableView:setDataSourceAdapterScriptHandler(handler(self, self.PlayRewardNewAdapter))
        tableView:setCountOfCell(#data.ordinaryDatas)
        tableView:reloadData()

        childViewData.cardPreviewBtn:RefreshUI({goodsId = checktable(conf.rewards)[1].goodsId})

        childViewData.drawBtn:SetCallback(handler(self, self.OnClickPlayRewardBtnAction))
        return
    elseif childName == 'SummerActivityTotalDotRewardView' then
        gridView:setDataSourceAdapterScriptHandler(handler(self, self.totalDotGridViewDataAdapter))
        
        local rankLabel = childViewData.rankLabel
        local mySummerPointRank = checkint(self.ctorArgs_.mySummerPointRank)
        local rankText = mySummerPointRank == 0 and summerActMgr:getThemeTextByText(__('未入榜')) or tostring(mySummerPointRank)
        display.commonLabelParams(rankLabel, {text = rankText})

        local dotLabel  = childViewData.dotLabel
        display.commonLabelParams(dotLabel, {text = tostring(self.ctorArgs_.summerPoint)})

        local rankBtn = childViewData.rankBtn
        display.commonUIParams(rankBtn, {cb = handler(self, self.onClickRankAction)})

    elseif childName == 'SummerActivityDamageRewardView' then
        gridView:setDataSourceAdapterScriptHandler(handler(self, self.damageRewardGridViewDataAdapter))
    end

    local data = self.datas[tag]
    if data then
        if tag == 3 then
            local rewardTipLayer = childViewData.rewardTipLayer
            local stageRewardConfs = data.stageRewardConfs
            rewardTipLayer:refreshUI(stageRewardConfs, 1, false, string.format(summerActMgr:getThemeTextByText(__('每个章节小丑伤害排行榜前%s名可获得：')), stageRewardConfs.lowerLimit or 100))
        end
        gridView:setCountOfCell(#(data.additionalDatas or data))
        gridView:reloadData()
    end
end

function SummerActivityRankRewardMediator:CleanupView()
    local viewComponent = self:GetViewComponent()
    if self.ownerScene_ and viewComponent and not tolua.isnull(viewComponent) then
        self.ownerScene_:RemoveDialog(viewComponent)
        self.ownerScene_ = nil
    end
end


function SummerActivityRankRewardMediator:OnRegist()
    regPost(POST.SUMMER_ACTIVITY_QUEST_REWARD_DRAW)
    regPost(POST.SUMMER_ACTIVITY_DRAW_QUEST_TIMES_REWARDS)
    self:enterLayer()
end
function SummerActivityRankRewardMediator:OnUnRegist()
    unregPost(POST.SUMMER_ACTIVITY_QUEST_REWARD_DRAW)
    unregPost(POST.SUMMER_ACTIVITY_DRAW_QUEST_TIMES_REWARDS)
end


function SummerActivityRankRewardMediator:InterestSignals()
    return {
        POST.SUMMER_ACTIVITY_HOME.sglName,
        POST.SUMMER_ACTIVITY_QUEST_REWARD_DRAW.sglName,
        POST.SUMMER_ACTIVITY_DRAW_QUEST_TIMES_REWARDS.sglName
    }
end

function SummerActivityRankRewardMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody()

    if name == POST.SUMMER_ACTIVITY_HOME.sglName then
        self.ctorArgs_ = body

        local viewData     = self:getViewData()
        local tabs         = viewData.tabs
        self:onClickTabAction(tabs[1])
        app.summerActMgr:setIsClosed(checkint(self.ctorArgs_.isEnd) == 1)
    elseif name == POST.SUMMER_ACTIVITY_QUEST_REWARD_DRAW.sglName then
        uiMgr:AddDialog('common.RewardPopup', {rewards = body.rewards})
        self.datas[1].questOverHasDraw = 1
        self:RefreshDrawBtnState()
    elseif name == POST.SUMMER_ACTIVITY_DRAW_QUEST_TIMES_REWARDS.sglName then
        uiMgr:AddDialog('common.RewardPopup', {rewards = body.rewards})
        local requestData = body.requestData
        local times = requestData.times
        local index = requestData.index
        local data = self.datas[1]

        local viewName = TAB_CONFIG[1]
        local view = self.viewStore[viewName]
        local childViewData = view:getViewData()

        if index > 0 then
            local ordinaryDatas   = data.ordinaryDatas
            ordinaryDatas[index].state = 3
            local tableView = childViewData.tableView
            local cell = tableView:cellAtIndex(index - 1)
            if cell then
                view:updateCell(cell.viewData, ordinaryDatas[index])
            end
        else
            local overRewardDatas = data.overRewardDatas
            overRewardDatas.state = 3
            childViewData.drawBtn:RefreshUI({drawState = overRewardDatas.state})
        end
        
        if self.ctorArgs_.questTimesDrawn == nil then
            self.ctorArgs_.questTimesDrawn = {}
        end
        table.insert(self.ctorArgs_.questTimesDrawn, times)
        
    end
end

-------------------------------------------------
-- get / set

function SummerActivityRankRewardMediator:getViewData()
    return self.viewData_
end

function SummerActivityRankRewardMediator:getOwnerScene()
    return self.ownerScene_
end

-------------------------------------------------
-- public method
function SummerActivityRankRewardMediator:enterLayer()
    self:SendSignal(POST.SUMMER_ACTIVITY_HOME.cmdName)
end

-------------------------------------------------
-- private method

function SummerActivityRankRewardMediator:PlayRewardNewAdapter(p_convertview, idx)
    local pCell = p_convertview
    local index = idx + 1
    local viewName = TAB_CONFIG[1]
    if viewName == nil then return end
    local view = self.viewStore[viewName]

    if pCell == nil then
        local childViewData = view:getViewData()
        pCell = view:CreateCell(childViewData.tableView:getSizeOfCell())
        pCell.viewData.drawBtn:SetCallback(handler(self, self.OnClickPlayRewardBtnAction))
    end

    local datas = self.datas[1]
    if datas then
        local data = datas.ordinaryDatas[index]
        
        view:updateCell(pCell.viewData, data)
        pCell.viewData.drawBtn:setTag(index)
    end

    return pCell
end

function SummerActivityRankRewardMediator:totalDotGridViewDataAdapter(p_convertview, idx )
	local pCell = p_convertview
    local index = idx + 1
    local viewName = TAB_CONFIG[2]
    if viewName == nil then return end
    local view = self.viewStore[viewName]
    if view == nil then return end
    if pCell == nil then
        pCell = view:CreateCell()
    end
    local viewData = pCell.viewData

    local datas = self.datas[2]
    if datas then
        local data = datas[index]
        view:updateCell(viewData, data)
    end
    
    return pCell
end

function SummerActivityRankRewardMediator:damageRewardGridViewDataAdapter(p_convertview, idx )
    local pCell = p_convertview
    local index = idx + 1
    local viewName = TAB_CONFIG[3]
    if viewName == nil then return end
    local view = self.viewStore[viewName]
    if view == nil then return end
    if pCell == nil then
        pCell = view:CreateCell()
    end
    local viewData = pCell.viewData
    local datas = checktable(self.datas[3]).additionalDatas
    if datas then
        local data = datas[index]
        view:updateCell(viewData, data)
    end
    pCell.viewData.headNode:setTag(index)
    
    return pCell
end

-------------------------------------------------
-- check

-------------------------------------------------
-- handler
function SummerActivityRankRewardMediator:onClickRankAction(sender)
    AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'summerActivity.SummerActivityHomeMediator'}, {name = 'summerActivity.carnie.CarnieRankMediator'})
end

function SummerActivityRankRewardMediator:onClickTabAction(sender)
    local tag = sender:getTag()
    if self.preChoiceIndex == tag then return end
    -- logInfo.add(5, 'tag = ' .. tag)
    local viewName = TAB_CONFIG[tag] or 'SummerActivityTotalDotRewardView'
    local viewData = self:getViewData()
    if not self.viewStore[viewName] then
        local view = require("Game.views.summerActivity." .. viewName).new()
        local contentLayer = viewData.contentLayer
        contentLayer:addChild(view)
        local contentLayerSize = contentLayer:getContentSize()
        display.commonUIParams(view, {ap = display.CENTER, po = cc.p(contentLayerSize.width / 2, contentLayerSize.height / 2)})
        self.viewStore[viewName] = view

        self:initChildView(viewName, tag)
    end

    if self.preChoiceIndex then
        local tabs = viewData.tabs
        tabs[self.preChoiceIndex]:setChecked(false)
        local oldView = self.viewStore[TAB_CONFIG[self.preChoiceIndex]]
        if oldView then
            oldView:setVisible(false)
        end
    end
    sender:setChecked(true)
    -- logInfo.add(5, "viewName = " .. viewName)
    self.viewStore[viewName]:setVisible(true)
    self.preChoiceIndex = tag
end
--[[
游玩奖励领取按钮点击回调
--]]
function SummerActivityRankRewardMediator:DrawButtonCallback(sender)
    PlayAudioByClickNormal()
    local data = self.datas[1]
    if data.questTimes >= data.targetTimes then
        self:SendSignal(POST.SUMMER_ACTIVITY_QUEST_REWARD_DRAW.cmdName)
    else
        uiMgr:ShowInformationTips(summerActMgr:getThemeTextByText(__('次数未达到')))
    end
end

function SummerActivityRankRewardMediator:OnClickPlayRewardBtnAction(sender)
    PlayAudioByClickNormal()
    local index = sender:getTag()
    local data
    local datas = self.datas[1]
    if index > 0 then
        data = datas.ordinaryDatas[index]
    else
        data = datas.overRewardDatas
    end
    local state = data.state
    if state == 1 then
        uiMgr:ShowInformationTips(summerActMgr:getThemeTextByText(__('次数未达到')))
        return
    elseif state == 3 then
        uiMgr:ShowInformationTips(summerActMgr:getThemeTextByText(__('已领取')))
        return
    end

    self:SendSignal(POST.SUMMER_ACTIVITY_DRAW_QUEST_TIMES_REWARDS.cmdName, {times = data.times, index = index})
    -- app:DispatchObservers(POST.SUMMER_ACTIVITY_DRAW_QUEST_TIMES_REWARDS.sglName, {requestData = {times = data.times, index = index}, rewards = {{goodsId = 890002, num = 1}}})
end

--[[
刷新领取按钮状态
--]]
function SummerActivityRankRewardMediator:RefreshDrawBtnState()
    local data = self.datas[1]
    local view = self.viewStore[TAB_CONFIG[1]]
    if view == nil then return end
    if data.questOverHasDraw == 1 then
        view:ChangeDrawBtnState(3)
    else
        if data.questTimes >= data.targetTimes then
            view:ChangeDrawBtnState(1)
        else
            view:ChangeDrawBtnState(2)
        end
    end
end
return SummerActivityRankRewardMediator
