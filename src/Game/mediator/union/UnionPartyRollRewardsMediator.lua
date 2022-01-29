--[[
 * author : kaishiqi
 * descpt : 工会派对 - ROLL点中介者
]]
local UnionPartyRollResultView      = require('Game.views.union.UnionPartyRollResultView')
local UnionPartyRollRewardsView     = require('Game.views.union.UnionPartyRollRewardsView')
local UnionPartyRollRewardsMediator = class('UnionPartyRollRewardsMediator', mvc.Mediator)
UnionPartyRollRewardsMediator.NAME  = 'UnionPartyBossQuestMediator'

function UnionPartyRollRewardsMediator:ctor(params, viewComponent)
    self.super.ctor(self, UnionPartyRollRewardsMediator.NAME, viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance method

function UnionPartyRollRewardsMediator:Initial(key)
    self.super.Initial(self, key)

    -- parse args
    self.resultStepId_   = checkint(self.ctorArgs_.resultStepId)
    self.rewardsStepId_  = checkint(self.ctorArgs_.rewardsStepId)
    self.memberResults_  = {}
    self.rollRewardsMap_ = {}
    self.memberCellDict_ = {}
    self.isControllable_ = true
    self.isEnableOffset_ = false

    local gameManager  = self:GetFacade():GetManager('GameManager')
    self.selfPlayerId_ = gameManager:GetUserInfo().playerId

    local unionManager     = self:GetFacade():GetManager('UnionManager')
    local rewardsStepInfo  = unionManager:getPartyStepInfo(self.rewardsStepId_) or {}
    self.rewardsEndedTime_ = checkint(rewardsStepInfo.endedTime)
    self.rewardsTotalTime_ = checkint(rewardsStepInfo.duration)

    -- create view
    local uiManager       = self:GetFacade():GetManager('UIManager')
    self.ownerScene_      = uiManager:GetCurrentScene()
    self.rollRewardsView_ = UnionPartyRollRewardsView.new()
    self.ownerScene_:AddDialog(self.rollRewardsView_)

    -- update view
    local rollRewardsViewData = self:getRollRewardsView():getViewData()
    display.commonUIParams(rollRewardsViewData.giveUpBtn, {cb = handler(self, self.onClickGiveUpButtonHandler_)})
    display.commonUIParams(rollRewardsViewData.toRollButton, {cb = handler(self, self.onClickToRollButtonHandler_)})
    rollRewardsViewData.memberGridView:setDataSourceAdapterScriptHandler(handler(self, self.onMemberGridDataAdapterHandler_))
end


function UnionPartyRollRewardsMediator:CleanupView()
    self:stopRollRewardsCountdown_()

    if self.ownerScene_ then

        if self.rollRewardsView_ and self.rollRewardsView_:getParent() then
            self.ownerScene_:RemoveDialog(self.rollRewardsView_)
            self.rollRewardsView_ = nil
        end

        if self.rollResultView_ and self.rollResultView_:getParent() then
            self.ownerScene_:RemoveDialog(self.rollResultView_)
            self.rollResultView_ = nil
        end

        self.ownerScene_ = nil
    end
end


function UnionPartyRollRewardsMediator:OnRegist()
    regPost(POST.UNION_PARTY_CHOP_ROLL_AT)
    regPost(POST.UNION_PARTY_CHOP_ROLL_HOME)
    regPost(POST.UNION_PARTY_CHOP_ROLL_RESULT)
end
function UnionPartyRollRewardsMediator:OnUnRegist()
    unregPost(POST.UNION_PARTY_CHOP_ROLL_AT)
    unregPost(POST.UNION_PARTY_CHOP_ROLL_HOME)
    unregPost(POST.UNION_PARTY_CHOP_ROLL_RESULT)
end


function UnionPartyRollRewardsMediator:InterestSignals()
    return {
        SGL.UNION_PARTY_ROLL_RESULT_UPDATE,
        POST.UNION_PARTY_CHOP_ROLL_AT.sglName,
        POST.UNION_PARTY_CHOP_ROLL_HOME.sglName,
        POST.UNION_PARTY_CHOP_ROLL_RESULT.sglName
    }
end
function UnionPartyRollRewardsMediator:ProcessSignal( signal )
    local name = signal:GetName()
    local data = signal:GetBody()

    if name == POST.UNION_PARTY_CHOP_ROLL_HOME.sglName then
        self.memberResults_  = checktable(data.rollResult)
        self.rollRewardsMap_ = checktable(data.rollRewards)
        self:getRollRewardsView():showRewardsView()
        self:realignMemberResults_()
        
        for index, goodsData in pairs(self.rollRewardsMap_) do
            self:getRollRewardsView():updateRewardsIcon(index, goodsData.goodsId, goodsData.num)
        end


    elseif name == POST.UNION_PARTY_CHOP_ROLL_AT.sglName then
        self:getRollRewardsView():updateRollStatus(true)
        
        local rollPoint = checkint(data.rollPoint)
        if rollPoint > 0 then
            local rollAnimationView = self:getRollRewardsView():showRollAnimation(checkint(data.rollPoint), function()
                AppFacade.GetInstance():DispatchObservers(SGL.UNION_PARTY_ROLL_RESULT_UPDATE, {
                    memberId  = self.selfPlayerId_,
                    rollPoint = rollPoint
                })
            end)
            self.ownerScene_:AddDialog(rollAnimationView)
        else
            self:resetMemberRollResult_(self.selfPlayerId_, rollPoint)
        end
    

    elseif name == SGL.UNION_PARTY_ROLL_RESULT_UPDATE then
        self:resetMemberRollResult_(data.memberId, data.rollPoint)
        

    elseif name == POST.UNION_PARTY_CHOP_ROLL_RESULT.sglName then
        local leftSeconds = checkint(data.leftSeconds)
        if leftSeconds > 0 then
            self.rewardsEndedTime_ = getServerTime() + leftSeconds
            self.rewardsTotalTime_ = self.rewardsTotalTime_ + leftSeconds
            self:startRollRewardsCountdown_()

        else
            self:getRollRewardsView():hideRewardsView()

            if self.rollResultView_ and self.rollResultView_:getParent() then
                self.ownerScene_:RemoveDialog(self.rollResultView_)
                self.rollResultView_ = nil
            end

            self.rollResultView_ = UnionPartyRollResultView.new({rollResult = data.result, resultStepId = self.resultStepId_})
            self.ownerScene_:AddDialog(self.rollResultView_)
        end

    end
end


-------------------------------------------------
-- public method

function UnionPartyRollRewardsMediator:getRollRewardsView()
    return self.rollRewardsView_
end


function UnionPartyRollRewardsMediator:toRewardsStatus()
    self.rewardsCountdownEndedCB_ = nil
    self:updateRollRewardsLeftTime_()
    self:startRollRewardsCountdown_()
    
    self:SendSignal(POST.UNION_PARTY_CHOP_ROLL_HOME.cmdName, {stepId = self.rewardsStepId_, partyBaseTime = app.unionMgr:getPartyBaseTime()})
end


function UnionPartyRollRewardsMediator:toResultStatus()
    self.rewardsCountdownEndedCB_ = function()
        self:stopRollRewardsCountdown_()
        self:SendSignal(POST.UNION_PARTY_CHOP_ROLL_RESULT.cmdName, {stepId = self.resultStepId_, partyBaseTime = app.unionMgr:getPartyBaseTime()})
    end
    self:getRollRewardsView():updateRollStatus(true)
    self.rewardsCountdownEndedCB_()
end


-------------------------------------------------
-- private method

function UnionPartyRollRewardsMediator:startRollRewardsCountdown_()
    if self.rollRewardsCountdownHandler_ then return end
    self.rollRewardsCountdownHandler_ = scheduler.scheduleGlobal(function()
        self:updateRollRewardsLeftTime_()
    end, 1)
end
function UnionPartyRollRewardsMediator:stopRollRewardsCountdown_()
    if self.rollRewardsCountdownHandler_ then
        scheduler.unscheduleGlobal(self.rollRewardsCountdownHandler_)
        self.rollRewardsCountdownHandler_ = nil
    end
end
function UnionPartyRollRewardsMediator:updateRollRewardsLeftTime_()
    local rollTimeLeft = checkint(self.rewardsEndedTime_) - getServerTime()
    self:getRollRewardsView():updateTimeProgress(rollTimeLeft, self.rewardsTotalTime_)

    if rollTimeLeft <= 0 and self.rewardsCountdownEndedCB_ then
        self.rewardsCountdownEndedCB_()
    end
end


function UnionPartyRollRewardsMediator:resetMemberRollResult_(memberId, rollPoint)
    for _, memberData in ipairs(self.memberResults_) do
        if checkint(memberData.playerId) == checkint(memberId) then
            memberData.rollPoint = checkint(rollPoint)
            break
        end
    end

    self:realignMemberResults_()
end


function UnionPartyRollRewardsMediator:realignMemberResults_()
    -- realign data
    table.sort(self.memberResults_, function (a, b)
        return checkint(a.rollPoint) > checkint(b.rollPoint)
    end)

    -- update list view
    local memberGridView  = self:getRollRewardsView():getViewData().memberGridView
    local beforeOffsetPos = memberGridView:getContentOffset()
    memberGridView:setCountOfCell(#self.memberResults_)
    memberGridView:reloadData()

    if self.isEnableOffset_ then
        local offsetY = math.min(memberGridView:getMaxOffset().y, math.max(beforeOffsetPos.y, memberGridView:getMinOffset().y))
        memberGridView:setContentOffset(cc.p(0, offsetY))
    else
        self.isEnableOffset_ = true
    end

    -- update left num
    local leftNumberNum = 0
    for _, memberData in ipairs(self.memberResults_) do
        if checkint(memberData.rollPoint) == 0 then
            leftNumberNum = leftNumberNum + 1
        end
    end
    self:getRollRewardsView():updateLeftMemberNum(leftNumberNum)
end


function UnionPartyRollRewardsMediator:updateMemberCell_(index, cellViewData)
    local memberGridView = self:getRollRewardsView():getViewData().memberGridView
    local cellViewData   = cellViewData or self.memberCellDict_[memberGridView:cellAtIndex(index - 1)]
    local memberData     = self.memberResults_[index]

    if cellViewData and memberData then
        
        -- update cell bg
        local memberId   = checkint(memberData.playerId)
        local isSelf = self.selfPlayerId_ == memberId
        cellViewData.normalBg:setVisible(not isSelf)
        cellViewData.selectBg:setVisible(isSelf)

        -- update giveUp status
        local rollPoint = checkint(memberData.rollPoint)
        local isGiveUp  = rollPoint < 0
        cellViewData.blackFg:setVisible(isGiveUp)
        cellViewData.giveUpLabel:setVisible(isGiveUp)
        cellViewData.scoreLabel:setVisible(not isGiveUp)

        -- update playerName
        display.commonLabelParams(cellViewData.nameLabel, {text = tostring(memberData.playerName)})

        -- update score text
        local scoreText  = rollPoint == 0 and '--' or tostring(rollPoint)
        local scoreColor = self:getRollRewardsView():getRankIndexColor(index)
        display.commonLabelParams(cellViewData.scoreLabel, {text = scoreText, color = scoreColor})
    end
end


-------------------------------------------------
-- handler

function UnionPartyRollRewardsMediator:onClickGiveUpButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    self:SendSignal(POST.UNION_PARTY_CHOP_ROLL_AT.cmdName, {stepId = self.rewardsStepId_, giveUp = 1, partyBaseTime = app.unionMgr:getPartyBaseTime()})

    self.isControllable_ = false
    transition.execute(self:getRollRewardsView(), nil, {delay = 0.3, complete = function()
        self.isControllable_ = true
    end})
end


function UnionPartyRollRewardsMediator:onClickToRollButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    self:SendSignal(POST.UNION_PARTY_CHOP_ROLL_AT.cmdName, {stepId = self.rewardsStepId_, giveUp = 0, partyBaseTime = app.unionMgr:getPartyBaseTime()})

    self.isControllable_ = false
    transition.execute(self:getRollRewardsView(), nil, {delay = 0.3, complete = function()
        self.isControllable_ = true
    end})
end


function UnionPartyRollRewardsMediator:onMemberGridDataAdapterHandler_(cell, idx)
    local pCell = cell
    local index = idx + 1

    local memberGridView = self:getRollRewardsView():getViewData().memberGridView
    local memberCellSize = memberGridView:getSizeOfCell()

    -- create cell
    if pCell == nil then
        local cellViewData = self:getRollRewardsView():createMemberCell(memberCellSize)

        pCell = cellViewData.view
        self.memberCellDict_[pCell] = cellViewData
    end

    -- init cell
    local cellViewData = self.memberCellDict_[pCell]

    -- update cell
    self:updateMemberCell_(index, cellViewData)

    return pCell
end


return UnionPartyRollRewardsMediator
