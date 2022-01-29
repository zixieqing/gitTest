--[[
 * author : liuzhipeng
 * descpt : 杀人案（19夏活）奖励预览Mediator
--]]
local NAME = 'activity.murder.MurderRewardPreviewMediator'
local MurderRewardPreviewMediator = class(NAME, mvc.Mediator)

local appIns   = AppFacade.GetInstance()
local uiMgr    = appIns:GetManager('UIManager')
local summerActMgr = appIns:GetManager("SummerActivityManager")

local TAB_CONFIG = {
    'MurderAdvanceRewardsView',
    'MurderPointRankRewardsView',
}

function MurderRewardPreviewMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.ctorArgs_ = app.murderMgr:GetHomeData()
end

-------------------------------------------------
-- inheritance method
function MurderRewardPreviewMediator:Initial(key)
    self.super.Initial(self, key)

    self.datas           = {}
    self.viewStore       = {}
    self.preChoiceIndex  = nil
    self.isControllable_ = true
    
    -- create view
    local viewComponent = require('Game.views.activity.murder.MurderRewardPreviewView').new({mediatorName = NAME})
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

function MurderRewardPreviewMediator:initOwnerScene_()
    self.ownerScene_ = uiMgr:GetCurrentScene()
end

function MurderRewardPreviewMediator:initDataByName(name, tag)
    if name == 'MurderAdvanceRewardsView' then
        self.datas[tag] = self:GetPlayRewardData(checkint(self.ctorArgs_.clockLevel), checkint(self.ctorArgs_.hasClockOverTimesDrawn))
    elseif name == 'MurderPointRankRewardsView' then
        self.datas[tag] = self:GetDamageRankRewardData()
    end
end

function MurderRewardPreviewMediator:initView_()
    local viewData     = self:getViewData()
    local tabs         = viewData.tabs
    for i, tab in ipairs(tabs) do
        display.commonUIParams(tab, {cb = handler(self, self.onClickTabAction)})
        tab:setTag(i)
    end

end

function MurderRewardPreviewMediator:initChildView(childName, tag)
    local view = self.viewStore[childName]
    if view == nil then return end

    self:initDataByName(childName, tag)

    local childViewData = view:getViewData()
    local gridView = childViewData.gridView
    if childName == 'MurderAdvanceRewardsView' then
        local data = self.datas[tag]
        childViewData.drawBtn:setOnClickScriptHandler(handler(self, self.DrawButtonCallback))
        childViewData.progressBar:setMaxValue(data.targetTimes)
        childViewData.progressBar:setValue(data.clockLevel)
        childViewData.progressLabel:setString(string.format('%d/%d', math.min(data.clockLevel, data.targetTimes), data.targetTimes))
        self:RefreshDrawBtnState()
        return 
    elseif childName == 'MurderPointRankRewardsView' then
        gridView:setDataSourceAdapterScriptHandler(handler(self, self.damageRewardGridViewDataAdapter))
        local rankBtn = childViewData.rankBtn
        display.commonUIParams(rankBtn, {cb = handler(self, self.onClickRankAction)})
    end

    local data = self.datas[tag]
    if data then
        if tag == 2 then
            local rewardTipLayer = childViewData.rewardTipLayer
            local stageRewardConfs = data.stageRewardConfs
            rewardTipLayer:refreshUI(stageRewardConfs, 1, false, string.format(app.murderMgr:GetPoText(__('各个调查排行榜的前%s名可获得：')), stageRewardConfs.lowerLimit or 100))
        end
        gridView:setCountOfCell(#(data.additionalDatas or data))
        gridView:reloadData()
    end
end

function MurderRewardPreviewMediator:CleanupView()
    local viewComponent = self:GetViewComponent()
    if self.ownerScene_ and viewComponent and not tolua.isnull(viewComponent) then
        self.ownerScene_:RemoveDialog(viewComponent)
        self.ownerScene_ = nil
    end
end


function MurderRewardPreviewMediator:OnRegist()
    regPost(POST.MURDER_CLOCK_REWARDS)
    self:enterLayer()
end
function MurderRewardPreviewMediator:OnUnRegist()
    unregPost(POST.MURDER_CLOCK_REWARDS)
end


function MurderRewardPreviewMediator:InterestSignals()
    return {
        POST.MURDER_HOME.sglName,
        POST.MURDER_CLOCK_REWARDS.sglName,
    }
end

function MurderRewardPreviewMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody()

    if name == POST.MURDER_HOME.sglName then
        self.ctorArgs_ = body

        local viewData     = self:getViewData()
        local tabs         = viewData.tabs
        self:onClickTabAction(tabs[1])
    elseif name == POST.MURDER_CLOCK_REWARDS.sglName then
        uiMgr:AddDialog('common.RewardPopup', {rewards = body.rewards})
        self.datas[1].hasClockOverTimesDrawn = 1
        app.murderMgr:GetHomeData().hasClockOverTimesDrawn = 1  
        self:RefreshDrawBtnState()
        app:DispatchObservers(MURDER_PROGRESSBAR_REMINDICON_REFRESH)
    end
end

-------------------------------------------------
-- get / set

function MurderRewardPreviewMediator:getViewData()
    return self.viewData_
end

function MurderRewardPreviewMediator:getOwnerScene()
    return self.ownerScene_
end

-------------------------------------------------
-- public method
function MurderRewardPreviewMediator:enterLayer()
    -- self:SendSignal(POST.MURDER_HOME.cmdName)
    local viewData     = self:getViewData()
    local tabs         = viewData.tabs
    self:onClickTabAction(tabs[1])
end

-------------------------------------------------
-- private method
function MurderRewardPreviewMediator:damageRewardGridViewDataAdapter(p_convertview, idx )
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
    local datas = checktable(self.datas[2]).additionalDatas
    if datas then
        local data = datas[index]
        view:updateCell(viewData, data)
    end
    pCell.viewData.headNode:setTag(index)
    
    return pCell
end

function MurderRewardPreviewMediator:GetPlayRewardData(clockLevel, hasClockOverTimesDrawn)
    local rewardConf = CommonUtils.GetConfig('newSummerActivity', 'overTimeReward', 1) or {}
    local data = {
        clockLevel = checkint(clockLevel),
        targetTimes = checkint(rewardConf.gradeId),
        hasClockOverTimesDrawn = checkint(hasClockOverTimesDrawn)
    }
    return data
end
function MurderRewardPreviewMediator:GetDamageRankRewardData()
    local damageRankRewardDatas = CommonUtils.GetConfigAllMess('damageRankRewards', 'newSummerActivity')
    if next(damageRankRewardDatas) == nil then return {} end

    local additionalDatas = {}
    local chapterIds = {}
    for chapterId, damageRankRewardData in pairs(damageRankRewardDatas) do
        table.insert(chapterIds, chapterId)
    end

    local titleConfs = {
        ['1'] =  app.murderMgr:GetPoText(__('嫌疑人A')),
        ['2'] =  app.murderMgr:GetPoText(__('嫌疑人B')),
        ['3'] =  app.murderMgr:GetPoText(__('嫌疑人C')),
        ['4'] =  app.murderMgr:GetPoText(__('嫌疑人D')),
        ['5'] =  app.murderMgr:GetPoText(__('嫌疑人E')),
    }

    local descConfs = {
        ['1'] =  app.murderMgr:GetPoText(__('从嫌疑人A累计调查点数前10名的玩家可以获得。')),
        ['2'] =  app.murderMgr:GetPoText(__('从嫌疑人B累计调查点数前10名的玩家可以获得。')),
        ['3'] =  app.murderMgr:GetPoText(__('从嫌疑人C累计调查点数前10名的玩家可以获得。')),
        ['4'] =  app.murderMgr:GetPoText(__('从嫌疑人D累计调查点数前10名的玩家可以获得。')),
        ['5'] =  app.murderMgr:GetPoText(__('从嫌疑人E累计调查点数前10名的玩家可以获得。')),
    }

    table.sort(chapterIds, function (a, b)
        if a == nil then return true end
        if b == nil then return false end
        return checkint(a) < checkint(b)
    end)

    for i, chapterId in ipairs(chapterIds) do
        local damageRankRewardData = damageRankRewardDatas[chapterId]

        table.insert(additionalDatas, {
            data = damageRankRewardData[1] or {},
            title = titleConfs[tostring(chapterId)],
            desc = descConfs[tostring(chapterId)],
        })
    end

    local damageRankRewardData = damageRankRewardDatas['1'] or {}
    local stageRewardConfs = damageRankRewardData[2] or {}
    local data = {
        stageRewardConfs = stageRewardConfs,
        additionalDatas = additionalDatas
    }
    
    return data
end
-------------------------------------------------
-- check

-------------------------------------------------
-- handler
function MurderRewardPreviewMediator:onClickTabAction(sender)
    local tag = sender:getTag()
    if self.preChoiceIndex == tag then return end
    -- logInfo.add(5, 'tag = ' .. tag)
    local viewName = TAB_CONFIG[tag] or 'MurderAdvanceRewardsView'
    local viewData = self:getViewData()
    if not self.viewStore[viewName] then
        local view = require("Game.views.activity.murder." .. viewName).new()
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
function MurderRewardPreviewMediator:DrawButtonCallback(sender)
    PlayAudioByClickNormal()
    local data = self.datas[1]
    if data.clockLevel >= data.targetTimes then
        self:SendSignal(POST.MURDER_CLOCK_REWARDS.cmdName)
    else
        uiMgr:ShowInformationTips(app.murderMgr:GetPoText(__('等级未达到')))
    end
end

--[[
刷新领取按钮状态
--]]
function MurderRewardPreviewMediator:RefreshDrawBtnState()
    local data = self.datas[1]
    local view = self.viewStore[TAB_CONFIG[1]]
    if view == nil then return end
    if data.hasClockOverTimesDrawn == 1 then
        view:ChangeDrawBtnState(3)
    else
        if data.clockLevel >= data.targetTimes then
            view:ChangeDrawBtnState(1)
        else
            view:ChangeDrawBtnState(2)
        end
    end
end
function MurderRewardPreviewMediator:onClickRankAction(sender)
    AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'activity.murder.MurderRewardPreviewMediator'}, {name = 'activity.murder.MurderRankMediator'})
end
return MurderRewardPreviewMediator
