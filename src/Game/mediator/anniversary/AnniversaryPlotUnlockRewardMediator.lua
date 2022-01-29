--[[
周年庆剧情解锁奖励mediator
--]]
local Mediator = mvc.Mediator
---@class AnniversaryPlotUnlockRewardMediator :Mediator
local AnniversaryPlotUnlockRewardMediator = class("AnniversaryPlotUnlockRewardMediator", Mediator)
local NAME = "anniversary.AnniversaryPlotUnlockRewardMediator"
AnniversaryPlotUnlockRewardMediator.NAME = NAME

local uiMgr              = app.uiMgr
local anniversaryManager = app.anniversaryMgr

function AnniversaryPlotUnlockRewardMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.ctorArgs_ = checktable(params)
end

-------------------------------------------------
-- inheritance method
function AnniversaryPlotUnlockRewardMediator:Initial(key)
    self.super.Initial(self, key)

    self.isControllable_ = true

    -- create view
    local viewComponent = require('Game.views.anniversary.AnniversaryPlotUnlockRewardView').new()
    self.viewData_      = viewComponent:getViewData()
    self:SetViewComponent(viewComponent)
    
    -- init data
    self:initData_()

    -- init view
    self:initView_()
    
end

function AnniversaryPlotUnlockRewardMediator:initData_()
    self.datas = {
        mainStory = {},
        branchStory = {}
    }
    local homeData = anniversaryManager:GetHomeData()
    local storyRewards = homeData.storyRewards or {}
    
    local storyRewardsMap = {}
    for i, groupId in pairs(storyRewards) do
        storyRewardsMap[tostring(groupId)] = groupId
    end
    
    local story = homeData.story or {}
    local storyGroupData = {}
    local parserConfig = anniversaryManager:GetConfigParse()
    local storyCollectionConf = anniversaryManager:GetConfigDataByName(parserConfig.TYPE.STORY_COLLECTION) or {}
    for _, storyId in pairs(story) do
        local storyCollectionConfData = storyCollectionConf[tostring(storyId)] or {}
        local groupId = storyCollectionConfData.groupId
        if groupId then
            storyGroupData[tostring(groupId)] = storyGroupData[tostring(groupId)] or {}
            table.insert(storyGroupData[tostring(groupId)], storyId)
        end
    end
    
    local storyGroupRewardsConfDatas = anniversaryManager:GetConfigDataByName(parserConfig.TYPE.STORY_REWARDS) or {}
    self.datas.mainStory.confData = storyGroupRewardsConfDatas['1'] or {}
    self.datas.mainStory.drawState = self:getDrawState('1', storyGroupData, storyRewardsMap[tostring('1')])
    
    if next(storyGroupRewardsConfDatas) ~= nil then
        for _, confData in orderedPairs(storyGroupRewardsConfDatas) do
            local groupId = confData.id
            if tonumber(groupId) > 1 then
                table.insert(self.datas.branchStory, {
                    confData = confData,
                    drawState = self:getDrawState(groupId, storyGroupData, storyRewardsMap[tostring(groupId)])
                })
            end
        end
    end
    -- logInfo.add(5, tableToString(self.datas.branchStory))
end

function AnniversaryPlotUnlockRewardMediator:initView_()
    local viewData = self:getViewData()
    
    self:GetViewComponent():updateMainStoryUI(self.datas.mainStory)

    local mainRewardReceiveBtn = viewData.mainRewardReceiveBtn
    mainRewardReceiveBtn:SetCallback(handler(self, self.onClickMainReceiveBtnAction))

    local tableView = viewData.tableView
    tableView:setDataSourceAdapterScriptHandler(handler(self, self.onDataSourceAdapter))
    tableView:setCountOfCell(#self.datas.branchStory)
    tableView:reloadData()
end

function AnniversaryPlotUnlockRewardMediator:CleanupView()
end


function AnniversaryPlotUnlockRewardMediator:OnRegist()
    regPost(POST.ANNIVERSARY_DRAW_PLOT_REWARDS)
    self:enterLayer()
end
function AnniversaryPlotUnlockRewardMediator:OnUnRegist()
    unregPost(POST.ANNIVERSARY_DRAW_PLOT_REWARDS)
end


function AnniversaryPlotUnlockRewardMediator:InterestSignals()
    return {
        POST.ANNIVERSARY_DRAW_PLOT_REWARDS.sglName,
    }
end

function AnniversaryPlotUnlockRewardMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody() or {}

    if name == POST.ANNIVERSARY_DRAW_PLOT_REWARDS.sglName then
        uiMgr:AddDialog('common.RewardPopup', {rewards = body.rewards})
        -- todo update ui
        local requestData = body.requestData or {}
        local rewardId = checkint(requestData.rewardId)

        -- 1. 更新homedata 中的缓存数据
        local homeData = app.anniversaryMgr:GetHomeData()
        local storyRewards = homeData.storyRewards or {}
        table.insert(storyRewards, rewardId)

        if rewardId == 1 then
            local mainStory = self.datas.mainStory or {}
            mainStory.drawState = 3
            self:GetViewComponent():updateMainRewardReceiveBtn(self:getViewData(), mainStory)
        else
            local branchStory = self.datas.branchStory or {}
            for i, v in ipairs(branchStory) do
                local confData  = v.confData or {}
                local groupId   = checkint(confData.id)
                if groupId == rewardId then
                    branchStory[i].drawState = 3
                    local tableView = self:getViewData().tableView
                    local cell = tableView:cellAtIndex(i - 1)
                    if cell then
                        self:GetViewComponent():updateDrawBtn(cell.viewData, branchStory[i])
                    end
                    break
                end
            end
        end

    end
end

-------------------------------------------------
-- get / set

function AnniversaryPlotUnlockRewardMediator:getViewData()
    return self.viewData_
end

function AnniversaryPlotUnlockRewardMediator:getOwnerScene()
    return self.ownerScene_
end

function AnniversaryPlotUnlockRewardMediator:getDrawState(groupId, story, storyState)
    local drawState = 1
    if checkint(storyState) > 0 then
        drawState = 3
    elseif table.nums(story[tostring(groupId)] or {}) >= table.nums(CommonUtils.GetConfig('anniversary', 'storyCollectionGroup', groupId) or {}) then
        drawState = 2
    end
    return drawState
end

function AnniversaryPlotUnlockRewardMediator:getDrawErrorTextByDrawState(drawState)
    local drawErrorTexts = {
        [1] = app.anniversaryMgr:GetPoText(__('未达到领取条件')),
        [3] = app.anniversaryMgr:GetPoText(__('已领取')),
    }
    return drawErrorTexts[drawState]
end

-------------------------------------------------
-- public method
function AnniversaryPlotUnlockRewardMediator:enterLayer()

end

function AnniversaryPlotUnlockRewardMediator:refreshUI(isRefreshUI)
    app:DispatchObservers('ANNIVERSARY_REWARD_PREVIEW_REFRESH_CARD_PREVIEW')
end

-------------------------------------------------
-- private method
function AnniversaryPlotUnlockRewardMediator:onDataSourceAdapter(p_convertview, idx)
    local pCell = p_convertview
    local index = idx + 1
    
    if pCell == nil then
        local tableView = self:getViewData().tableView
        pCell = self:GetViewComponent():CreateCell(tableView:getSizeOfCell())
        pCell.viewData.drawBtn:SetCallback(handler(self, self.onClickDrawBtnAction))
    end

    xTry(function()
        local storyRewardData = self.datas.branchStory[index] or {}
        self:GetViewComponent():updateCell(pCell.viewData, storyRewardData)

        pCell.viewData.drawBtn:setTag(index)
    end,__G__TRACKBACK__)
    return pCell
end

-------------------------------------------------
-- check

-------------------------------------------------
-- handler
function AnniversaryPlotUnlockRewardMediator:onBtnAction(sender)
end

function AnniversaryPlotUnlockRewardMediator:onClickMainReceiveBtnAction(sender)
    local mainStory = self.datas.mainStory or {}
    local drawErrorText = self:getDrawErrorTextByDrawState(mainStory.drawState)
    
    if drawErrorText then
        uiMgr:ShowInformationTips(drawErrorText)
        return 
    end
    self:SendSignal(POST.ANNIVERSARY_DRAW_PLOT_REWARDS.cmdName, {rewardId = '1'})
end

function AnniversaryPlotUnlockRewardMediator:onClickDrawBtnAction(sender)
    local tag = sender:getTag()
    local branchStory = self.datas.branchStory or {}
    local storyRewardData = self.datas.branchStory[tag] or {}
    local drawErrorText = self:getDrawErrorTextByDrawState(storyRewardData.drawState)
    if drawErrorText then
        uiMgr:ShowInformationTips(drawErrorText)
        return 
    end
    local confData   = storyRewardData.confData or {}
    local rewardId = confData.id
    self:SendSignal(POST.ANNIVERSARY_DRAW_PLOT_REWARDS.cmdName, {rewardId = rewardId})
end

return AnniversaryPlotUnlockRewardMediator
