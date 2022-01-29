--[[
周年庆挑战奖励mediator
--]]
local Mediator = mvc.Mediator
---@class AnniversaryChallengeRewardMediator :Mediator
local AnniversaryChallengeRewardMediator = class("AnniversaryChallengeRewardMediator", Mediator)
local NAME = "anniversary.AnniversaryChallengeRewardMediator"
AnniversaryChallengeRewardMediator.NAME = NAME

local uiMgr = app.uiMgr
local anniversaryManager = app.anniversaryMgr

function AnniversaryChallengeRewardMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.ctorArgs_ = checktable(params)
end

-------------------------------------------------
-- inheritance method
function AnniversaryChallengeRewardMediator:Initial(key)
    self.super.Initial(self, key)

    self.isControllable_ = true

    -- create view
    local viewComponent = require('Game.views.anniversary.AnniversaryChallengeRewardView').new()
    self.viewData_      = viewComponent:getViewData()
    self:SetViewComponent(viewComponent)
    
    -- init data
    self:initData_()

    -- init view
    self:initView_()
    
end

function AnniversaryChallengeRewardMediator:initData_()
    self.datas = {}
    local homeData = anniversaryManager:GetHomeData()
    local challengePoint = checkint(homeData.challengePoint)
    local challengeRewards = homeData.challengeRewards or {}
    local challengeRewardsMap = {}
    for i, id in pairs(challengeRewards) do
        challengeRewardsMap[tostring(id)] = checkint(id)
    end

    local parserConfig = anniversaryManager:GetConfigParse()
    local confDatas = anniversaryManager:GetConfigDataByName(parserConfig.TYPE.CHALLENGE_POINT_REWARDS) or {}
    if next(confDatas) == nil then return end
    
    for i, confData in orderedPairs(confDatas) do
        local id = confData.id
        local employee = checkint(confData.employee)
        table.insert(self.datas, {
            confData = confData,
            drawState    = self:getDrawState(challengePoint, employee, challengeRewardsMap[tostring(id)]),
        })
    end
end

function AnniversaryChallengeRewardMediator:initView_()
    local viewData = self:getViewData()

    local homeData = anniversaryManager:GetHomeData()
    local challengePoint = checkint(homeData.challengePoint)
    self:GetViewComponent():updateIntegralLabel(viewData, challengePoint)

    local tableView = viewData.tableView
    tableView:setDataSourceAdapterScriptHandler(handler(self, self.onDataSourceAdapter))
    tableView:setCountOfCell(#self.datas)
    tableView:reloadData()
end

function AnniversaryChallengeRewardMediator:CleanupView()
end


function AnniversaryChallengeRewardMediator:OnRegist()
    regPost(POST.ANNIVERSARY_DRAW_CHALLENGE_POINT_REWARDS)
    self:enterLayer()
end
function AnniversaryChallengeRewardMediator:OnUnRegist()
    unregPost(POST.ANNIVERSARY_DRAW_CHALLENGE_POINT_REWARDS)
end


function AnniversaryChallengeRewardMediator:InterestSignals()
    return {
        POST.ANNIVERSARY_DRAW_CHALLENGE_POINT_REWARDS.sglName
    }
end

function AnniversaryChallengeRewardMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody() or {}

    if name == POST.ANNIVERSARY_DRAW_CHALLENGE_POINT_REWARDS.sglName then
        local rewards = body.rewards or {}
        if next(rewards) ~= nil then
            uiMgr:AddDialog('common.RewardPopup', {rewards = body.rewards})
        end

        local requestData = body.requestData or {}
        local rewardId = checkint(requestData.rewardId)

        -- 1. 更新homedata 中的缓存数据
        local homeData = anniversaryManager:GetHomeData()
        local challengeRewards = homeData.challengeRewards or {} 
        table.insert(challengeRewards, rewardId)

        for i, v in ipairs(self.datas) do
            local confData  = v.confData or {}
            local id   = checkint(confData.id)
            if id == rewardId then
                self.datas[i].drawState = 3
                local tableView = self:getViewData().tableView
                local cell = tableView:cellAtIndex(i - 1)
                if cell then
                    self:GetViewComponent():updateDrawBtn(cell.viewData, self.datas[i])
                end
                break
            end
        end
    end
end

-------------------------------------------------
-- get / set

function AnniversaryChallengeRewardMediator:getViewData()
    return self.viewData_
end

function AnniversaryChallengeRewardMediator:getOwnerScene()
    return self.ownerScene_
end

function AnniversaryChallengeRewardMediator:getDrawState(challengePoint, employee, rewardId)
    local drawState = 1
    if checkint(rewardId) > 0 then
        drawState = 3
    elseif challengePoint >= employee then
        drawState = 2
    end
    return drawState
end

function AnniversaryChallengeRewardMediator:getDrawErrorTextByDrawState(drawState)
    local drawErrorTexts = {
        [1] = app.anniversaryMgr:GetPoText(__('未达到领取条件')),
        [3] = app.anniversaryMgr:GetPoText(__('已领取')),
    }
    return drawErrorTexts[drawState]
end

-------------------------------------------------
-- public method
function AnniversaryChallengeRewardMediator:enterLayer()

end

function AnniversaryChallengeRewardMediator:refreshUI(isRefreshUI)
    app:DispatchObservers('ANNIVERSARY_REWARD_PREVIEW_REFRESH_CARD_PREVIEW', {showCardIndex = 1})
end

-------------------------------------------------
-- private method
function AnniversaryChallengeRewardMediator:onDataSourceAdapter(p_convertview, idx)
    local pCell = p_convertview
    local index = idx + 1
    
    if pCell == nil then
        local tableView = self:getViewData().tableView
        pCell = self:GetViewComponent():CreateCell(tableView:getSizeOfCell())
        pCell.viewData.drawBtn:SetCallback(handler(self, self.onClickDrawBtnAction))
    end

    xTry(function()
        self:GetViewComponent():updateCell(pCell.viewData, self.datas[index])
        pCell.viewData.drawBtn:setTag(index)
    end,__G__TRACKBACK__)
    return pCell
end

-------------------------------------------------
-- check

-------------------------------------------------
-- handler
function AnniversaryChallengeRewardMediator:onBtnAction(sender)
end

function AnniversaryChallengeRewardMediator:onClickDrawBtnAction(sender)
    local tag = sender:getTag()
    local data = self.datas[tag] or {}
    local drawErrorText = self:getDrawErrorTextByDrawState(data.drawState)
    -- logInfo.add(5, "233")
    if drawErrorText then
        uiMgr:ShowInformationTips(drawErrorText)
        return 
    end
    local confData = data.confData or {}
    local rewardId = confData.id
    self:SendSignal(POST.ANNIVERSARY_DRAW_CHALLENGE_POINT_REWARDS.cmdName, {rewardId = rewardId})
end

return AnniversaryChallengeRewardMediator
