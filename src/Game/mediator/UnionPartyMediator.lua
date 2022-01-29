--[[
 * author : kaishiqi
 * descpt : 工会派对中介者
]]
local PartyModelFactory   = require('Game.models.UnionPartyModelFactory')
local UnionPartyModel     = PartyModelFactory.getModelType('UnionParty')
local UnionPartyView      = require('Game.views.union.UnionPartyView')
local DialogueMediator    = require('Game.mediator.union.UnionPartyDialogueMediator')
local DropFoodMediator    = require('Game.mediator.union.UnionPartyDropFoodMediator')
local BossQuestMediator   = require('Game.mediator.union.UnionPartyBossQuestMediator')
local AnimationMediator   = require('Game.mediator.union.UnionPartyAnimationMediator')
local RollRewardsMediator = require('Game.mediator.union.UnionPartyRollRewardsMediator')
local RoundResultMediator = require('Game.mediator.union.UnionPartyRoundResultMediator')
local UnionPartyMediator  = class('UnionPartyMediator', mvc.Mediator)

function UnionPartyMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'UnionPartyMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance method

function UnionPartyMediator:Initial(key)
    self.super.Initial(self, key)

    self.partyModel_      = UnionPartyModel.new()
    self.isPauseStep_     = true
    self.isNeedShareMdt_  = false
    self.isControllable_  = true
    
    self.currentPartyStepId_    = UNION_PARTY_STEPS.UNOPEN
    self.currentPartyRoundNum_  = 0
    self.prevDropFoodDuration_  = 0
    self.lastDropFoodDuration_  = 0
    self.prevDropFoodEndedTime_ = 0
    self.lastDropFoodEndedTime_ = 0

    -- create view
    self.partyView_  = UnionPartyView.new()
    local uiManager  = self:GetFacade():GetManager('UIManager')
    self.ownerScene_ = uiManager:GetCurrentScene()
    self.ownerScene_:AddDialog(self.partyView_)

    self.roundViewData_ = self:getPartyView():createRoundView()
    self.roundViewData_.view:setLocalZOrder(100)
    self.ownerScene_:AddDialog(self.roundViewData_.view)

    -- update view
    self:getPartyView():hidePartyView(true)
    self:getPartyView():updateFoodScore(0)
    self:getPartyView():updateGoldScore(0)
    self:getPartyView():updateCountdown(0)
    self:getPartyView():updateRoundProgress(0)
end


function UnionPartyMediator:CleanupView()
    self:stopPartyProgressCountdown_()
    self:closeRunningStep_()

    if self.ownerScene_ then
        if self.partyView_ and self.partyView_:getParent() then
            self.ownerScene_:RemoveDialog(self.partyView_)
            self.partyView_  = nil
        end
        if self.roundViewData_ and self.roundViewData_.view and self.roundViewData_.view:getParent() then
            self.ownerScene_:RemoveDialog(self.roundViewData_.view)
            self.roundViewData_ = nil
        end
        self.ownerScene_ = nil
    end
    self:removeQuestBossView_()
end


function UnionPartyMediator:OnRegist()
    regPost(POST.UNION_PARTY_CHOP, true)
    regPost(POST.UNION_PARTY_DROP_FOOD_GRADE, true)
    regPost(POST.UNION_PARTY_BOSS_QUEST_RESULT, true)

    self:setHomeTopLayerControllable(false)
    self:SendSignal(POST.UNION_PARTY_CHOP.cmdName, {partyBaseTime = app.unionMgr:getPartyBaseTime()})
end
function UnionPartyMediator:OnUnRegist()
    unregPost(POST.UNION_PARTY_CHOP)
    unregPost(POST.UNION_PARTY_DROP_FOOD_GRADE)
    unregPost(POST.UNION_PARTY_BOSS_QUEST_RESULT)

    self:setHomeTopLayerControllable(true)
end


function UnionPartyMediator:InterestSignals()
    return {
        SGL.UNION_PARTY_STEP_CHANGE,
        SGL.UNION_PARTY_MODEL_FOOD_SCORE_CHANGE,
        SGL.UNION_PARTY_MODEL_GOLD_SCORE_CHANGE,
        POST.UNION_PARTY_CHOP.sglName,
        POST.UNION_PARTY_DROP_FOOD_GRADE.sglName,
        POST.UNION_PARTY_BOSS_QUEST_RESULT.sglName,
    }
end
function UnionPartyMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    -- party step change
    if name == SGL.UNION_PARTY_STEP_CHANGE then
        if not self.isPauseStep_ or data.stepId == UNION_PARTY_STEPS.ENDING then
            self:gotoPartyStep_(data.stepId, data.isTimely)
        end


    -- enter party
    elseif name == POST.UNION_PARTY_CHOP.sglName then
        AppFacade.GetInstance():DispatchObservers("DOT_LOG_EVENT_SEND" , {eventId = "52-02"})
        local hasError = checkint(data.errcode) ~= 0
        if hasError then
            self:close()
        else
            self.isPauseStep_ = false
            
            -- model init data
            local partyModel = self:getPartyModel()
            partyModel:setPartyLevel(checkint(data.partyLevel))
            partyModel:setUnionLevel(checkint(data.unionLevel))
            partyModel:setFoodGradeMap(checktable(data.foodGrade))
            partyModel:setFoodScoreMap(checktable(data.foodScore))
            partyModel:setGoldScoreMap(checktable(data.goldScore))
            partyModel:setBossQuestMap(checktable(data.bossQuest))
            partyModel:setBossResultMap(checktable(data.bossResult))
            partyModel:setSelfPassedMap(checktable(data.selfPassed))

            -- init step
            self:getPartyView():updatePartyName(self:getPartyModel():getPartyLevel())
            self:getPartyView():showPartyView()
            self:gotoPartyStep_()

            -- update views
            self:updateRoundFoodScore_()
            self:updateRoundGoldScore_()
            self:updatePartyProgressInfo_()
            self:startPartyProgressCountdown_()
            self:getPartyView():updateRoundNum(self.currentPartyRoundNum_)
        end


    -- update party foodScore
    elseif name == SGL.UNION_PARTY_MODEL_FOOD_SCORE_CHANGE then
        self:updateRoundFoodScore_()


    -- update party goldScore
    elseif name == SGL.UNION_PARTY_MODEL_GOLD_SCORE_CHANGE then
        self:updateRoundGoldScore_()


    -- dropFood grade
    elseif name == POST.UNION_PARTY_DROP_FOOD_GRADE.sglName then
        local gameManager = self:GetFacade():GetManager('GameManager')
        local foodStepId  = checkint(data.requestData.stepId)

        -- check has error
        if checkint(data.errcode) ~= 0 then
            -- reset party score
            self:getPartyModel():setFoodScore(foodStepId, 0)
            self:getPartyModel():setGoldScore(foodStepId, 0)

            -- reset player unionPoint
            app.goodsMgr:SetGoodsAmountByGoodsId(UNION_POINT_ID, checkint(self:getPartyModel():getTempPlayerGold()))
            AppFacade.GetInstance():DispatchObservers(SGL.CACHE_MONEY_UPDATE_UI)

        else
            -- update party score
            self:getPartyModel():setFoodScore(foodStepId, checkint(data.foodScore))
            self:getPartyModel():setGoldScore(foodStepId, checkint(data.goldScore))
            
            -- update player unionPoint
            app.goodsMgr:SetGoodsAmountByGoodsId(UNION_POINT_ID, checkint(data.playerGold))
            AppFacade.GetInstance():DispatchObservers(SGL.CACHE_MONEY_UPDATE_UI)
        end
        self:getPartyModel():setFoodGradeSync(foodStepId, true)
        

    -- party questResult
    elseif name == POST.UNION_PARTY_BOSS_QUEST_RESULT.sglName then
        self.isPauseStep_ = false
        
        local questStepId = checkint(data.requestData.questStepId)
        self:getPartyModel():setBossKillNum(questStepId, data.memberWinTimes)
        self:getPartyModel():setBossResultSync(questStepId, true)
        
        local isPassQuest    = self:getPartyModel():isPassBossQuest(questStepId)
        self.isNeedShareMdt_ = isPassQuest == false
        self:gotoPartyStep_()

    end
end


-------------------------------------------------
-- get / set

function UnionPartyMediator:getPartyView()
    return self.partyView_
end


function UnionPartyMediator:getPartyModel()
    return self.partyModel_
end


function UnionPartyMediator:getLobbyMediator()
    return self:GetFacade():RetrieveMediator('UnionLobbyMediator')
end


-------------------------------------------------
-- public method

function UnionPartyMediator:close()
    self:GetFacade():UnRegsitMediator(self:GetMediatorName())
end


function UnionPartyMediator:setHomeTopLayerControllable(isControllable)
    local appMediator  = AppFacade.GetInstance():RetrieveMediator('AppMediator')
	local homeTopLayer = appMediator and appMediator:GetViewComponent() or nil
	if homeTopLayer then
        homeTopLayer:setControllable(isControllable)
    end
end


-------------------------------------------------
-- private method

function UnionPartyMediator:closeRunningStep_()
    if self.runningStepMdt_ then
        if self.runningStepMdt_:GetMediatorName() == BossQuestMediator.NAME then
            self:removeQuestBossView_()
        end
        
        self:GetFacade():UnRegsitMediator(self.runningStepMdt_:GetMediatorName())
        self.runningStepMdt_ = nil
    end
end
function UnionPartyMediator:cleanPartyOtherObj_()
    self:GetFacade():DispatchObservers(SGL.Battle_UI_Destroy_Battle_Ready)

    -- remove other mdts
    local closeMdtList = {
    }
    for _, v in ipairs(closeMdtList) do
        self:GetFacade():UnRegsitMediator(v)
    end

    -- remove other views
    local cleanViewsList = {
        'common.CommonTipBoard',
    }
    for _, v in ipairs(cleanViewsList) do
        local dialogNode = sceneWorld:getChildByName(v)
        if dialogNode then
            sceneWorld:removeChild(dialogNode)
        elseif self.ownerScene_ then
            self.ownerScene_:RemoveDialogByName(v)
        end
    end
end


function UnionPartyMediator:startPartyProgressCountdown_()
    if self.partyProgressCountdownHandler_ then return end
    self.partyProgressCountdownHandler_ = scheduler.scheduleGlobal(function()
        if (self.currentPartyStepId_ == UNION_PARTY_STEPS.R1_DROP_FOOD_1 or self.currentPartyStepId_ == UNION_PARTY_STEPS.R1_DROP_FOOD_2 or
            self.currentPartyStepId_ == UNION_PARTY_STEPS.R2_DROP_FOOD_1 or self.currentPartyStepId_ == UNION_PARTY_STEPS.R2_DROP_FOOD_2 or
            self.currentPartyStepId_ == UNION_PARTY_STEPS.R3_DROP_FOOD_1 or self.currentPartyStepId_ == UNION_PARTY_STEPS.R3_DROP_FOOD_2) then
            self:updatePartyProgressInfo_()
        end
    end, 1)
end
function UnionPartyMediator:stopPartyProgressCountdown_()
    if self.partyProgressCountdownHandler_ then
        scheduler.unscheduleGlobal(self.partyProgressCountdownHandler_)
        self.partyProgressCountdownHandler_ = nil
    end
end
function UnionPartyMediator:updatePartyProgressInfo_()
    local prevDropFoodLeftTime = math.max(0, math.min(self.prevDropFoodEndedTime_ - getServerTime(), self.prevDropFoodDuration_))
    local lastDropFoodLeftTime = math.max(0, math.min(self.lastDropFoodEndedTime_ - getServerTime(), self.lastDropFoodDuration_))
    local prevDropFoodProgress = math.max(0, math.min((self.prevDropFoodDuration_ - prevDropFoodLeftTime) / self.prevDropFoodDuration_, 1))
    local lastDropFoodProgress = math.max(0, math.min((self.lastDropFoodDuration_ - lastDropFoodLeftTime) / self.lastDropFoodDuration_, 1))
    self:getPartyView():updateRoundProgress((prevDropFoodProgress + lastDropFoodProgress) * 50)
    self:getPartyView():updateCountdown(prevDropFoodLeftTime + lastDropFoodLeftTime)
end


function UnionPartyMediator:updateRoundFoodScore_()
    local unionManager  = self:GetFacade():GetManager('UnionManager')
    local currentRound  = unionManager:getPartyCurrentRoundNum()
    local prevFoodScore = self:getPartyModel():getFoodScore(UNION_PARTY_STEPS[string.fmt('R%1_DROP_FOOD_1', currentRound)])
    local lastFoodScore = self:getPartyModel():getFoodScore(UNION_PARTY_STEPS[string.fmt('R%1_DROP_FOOD_2', currentRound)])
    self:getPartyView():updateFoodScore(prevFoodScore + lastFoodScore)
end
function UnionPartyMediator:updateRoundGoldScore_()
    local unionManager  = self:GetFacade():GetManager('UnionManager')
    local currentRound  = unionManager:getPartyCurrentRoundNum()
    local prevGoldScore = self:getPartyModel():getGoldScore(UNION_PARTY_STEPS[string.fmt('R%1_DROP_FOOD_1', currentRound)])
    local lastGoldScore = self:getPartyModel():getGoldScore(UNION_PARTY_STEPS[string.fmt('R%1_DROP_FOOD_2', currentRound)])
    self:getPartyView():updateGoldScore(prevGoldScore + lastGoldScore)
end


function UnionPartyMediator:createQuestBossView_(questStepId)
    self:removeQuestBossView_()
    local partyQuestId   = self:getPartyModel():getBossQuestId(questStepId) or 0
    self.partyBossSpine_ = self:getPartyView():createPartyBoss(partyQuestId)
    if self.ownerScene_ then
        self.ownerScene_:AddDialog(self.partyBossSpine_)
    end
end
function UnionPartyMediator:removeQuestBossView_()
    if self.partyBossSpine_ and self.partyBossSpine_:getParent() then
        self.partyBossSpine_:removeFromParent()
        self.partyBossSpine_  = nil
    end
end


function UnionPartyMediator:gotoPartyStep_(stepId, isTimely)
    local unionManager  = self:GetFacade():GetManager('UnionManager')
    local partyStepId   = stepId == nil and unionManager:getPartyCurrentStepId() or checkint(stepId)
    local isJumpSteps   = self.currentPartyStepId_ >= 0 and (partyStepId - self.currentPartyStepId_) > 1
    local isStepTimely  = isTimely == nil and unionManager:isPartyTimelyCurrentStep() or (isTimely == true)
    
    -- update current stepId
    self.currentPartyStepId_ = partyStepId
    self:updatePartyProgressInfo_()

    -- check clean prev step
    self:cleanPartyOtherObj_()
    if not self.isNeedShareMdt_ or isJumpSteps then
        self:closeRunningStep_()
    end
    self.isNeedShareMdt_ = false

    -------------------------------------------------
    if partyStepId == UNION_PARTY_STEPS.UNOPEN then
        self:close()

    -- goto opening step
    elseif partyStepId == UNION_PARTY_STEPS.OPENING then
        self:runOpeningStep_(isStepTimely)

    -- goto closing step
    elseif partyStepId == UNION_PARTY_STEPS.ENDING then
        self:runClosingStep_(isStepTimely, partyStepId)
        self:getPartyView():hidePartyView()

    -- goto readyStart step
    elseif (partyStepId == UNION_PARTY_STEPS.R2_READY_START or
            partyStepId == UNION_PARTY_STEPS.R3_READY_START) then
            self:runRoundReadyStep_(isStepTimely, partyStepId)

    -- goto prev dropFood step
    elseif (partyStepId == UNION_PARTY_STEPS.R1_DROP_FOOD_1 or 
            partyStepId == UNION_PARTY_STEPS.R2_DROP_FOOD_1 or 
            partyStepId == UNION_PARTY_STEPS.R3_DROP_FOOD_1) then
        self:runDropFoodStep_(isStepTimely, partyStepId, nil, false)
        self:getPartyView():showPartyView()

    -- goto bossQuest step
    elseif (partyStepId == UNION_PARTY_STEPS.R1_BOSS_QUEST or 
            partyStepId == UNION_PARTY_STEPS.R2_BOSS_QUEST or 
            partyStepId == UNION_PARTY_STEPS.R3_BOSS_QUEST) then
        self:runBossQuestStep_(isStepTimely, partyStepId)

    -- goto bossResult step
    elseif (partyStepId == UNION_PARTY_STEPS.R1_BOSS_RESULT or 
            partyStepId == UNION_PARTY_STEPS.R2_BOSS_RESULT or 
            partyStepId == UNION_PARTY_STEPS.R3_BOSS_RESULT) then
        self:runBossResultStep_(isStepTimely, partyStepId)

    -- goto rollRewards step
    elseif (partyStepId == UNION_PARTY_STEPS.R1_ROLL_REWARDS or 
            partyStepId == UNION_PARTY_STEPS.R2_ROLL_REWARDS or 
            partyStepId == UNION_PARTY_STEPS.R3_ROLL_REWARDS) then
        local questStepId = partyStepId - 2
        if self:getPartyModel():isBossResultSync(questStepId) then
            self:runRollRewardsStep_(isStepTimely, partyStepId)
        else
            self.isPauseStep_ = true
            self:SendSignal(POST.UNION_PARTY_BOSS_QUEST_RESULT.cmdName, {questStepId = questStepId, partyBaseTime = app.unionMgr:getPartyBaseTime()})
        end

    -- goto rollResult step
    elseif (partyStepId == UNION_PARTY_STEPS.R1_ROLL_RESULT or 
            partyStepId == UNION_PARTY_STEPS.R2_ROLL_RESULT or 
            partyStepId == UNION_PARTY_STEPS.R3_ROLL_RESULT) then
        self:runRollResultStep_(isStepTimely, partyStepId)

    -- goto last dropFood step
    elseif (partyStepId == UNION_PARTY_STEPS.R1_DROP_FOOD_2 or 
            partyStepId == UNION_PARTY_STEPS.R2_DROP_FOOD_2 or 
            partyStepId == UNION_PARTY_STEPS.R3_DROP_FOOD_2) then
        self:runDropFoodStep_(isStepTimely, partyStepId, nil, true)
        
    end

    -------------------------------------------------
    -- check round change
    local currentRoundNum = unionManager:getPartyCurrentRoundNum()
    if currentRoundNum ~= self.currentPartyRoundNum_ then
        -- update current roundNum
        self.currentPartyRoundNum_ = currentRoundNum

        -- update round stepInfo
        local prevDropFoodStepId    = UNION_PARTY_STEPS[string.fmt('R%1_DROP_FOOD_1', currentRoundNum)]
        local lastDropFoodStepId    = UNION_PARTY_STEPS[string.fmt('R%1_DROP_FOOD_2', currentRoundNum)]
        local prevDropFoodStepInfo  = unionManager:getPartyStepInfo(prevDropFoodStepId) or {}
        local lastDropFoodStepInfo  = unionManager:getPartyStepInfo(lastDropFoodStepId) or {}
        self.prevDropFoodDuration_  = checkint(prevDropFoodStepInfo.duration)
        self.lastDropFoodDuration_  = checkint(lastDropFoodStepInfo.duration)
        self.prevDropFoodEndedTime_ = checkint(prevDropFoodStepInfo.endedTime)
        self.lastDropFoodEndedTime_ = checkint(lastDropFoodStepInfo.endedTime)
    end
end


-------------------
-- opening step
--
function UnionPartyMediator:runOpeningStep_(isTimely)
    local unionManager    = self:GetFacade():GetManager('UnionManager')
    local openingStepInfo = unionManager:getPartyStepInfo(UNION_PARTY_STEPS.OPENING) or {}

    local openingDialogueFunc = function(dialogId)
        local countdownDescr = string.fmt(__('第_num_回合即将开始'), {_num_ = 1})
        local countdownTime  = openingStepInfo.endedTime - math.ceil(self:getPartyView():getRoundSwitchTimeDefine().SWITCH_TOTAL_TIME)

        -- check countdown time
        if countdownTime - getServerTime() <= 1 then
            countdownTime = openingStepInfo.endedTime
        end
        
        self.runningStepMdt_ = DialogueMediator.new({dialogId = dialogId, targetTime = countdownTime, descrText = countdownDescr})
        self:GetFacade():RegistMediator(self.runningStepMdt_)

        if countdownTime ~= openingStepInfo.endedTime then
            -- round switch action
            self.runningStepMdt_:setCountdownCB(function(countTime)
                if countTime == 0 then
                    self:closeRunningStep_()
                    self:getPartyView():runRoundSwitchAction(self.roundViewData_, unionManager:getPartyCurrentRoundNum())
                end
            end)
        end

    end

    if isTimely then
        -- show opening animation
        self.runningStepMdt_ = AnimationMediator.new({spinePath = 'effects/union/party/kaichang'})
        self:GetFacade():RegistMediator(self.runningStepMdt_)

        -- play show animation
        self.runningStepMdt_:playAnimation('show')
        self.runningStepMdt_:listenSpineCompleteCB(function(event)
    
            if event.animation == 'show' then
                -- show party levelFrame
                local unionPartyLevel = self:getPartyModel():getPartyLevel()
                local levelFrameView  = self:getPartyView():createPartyLevelFrameView(unionPartyLevel)
                self.ownerScene_:AddDialog(levelFrameView)

                self:getPartyView():showPartyLevelFrameAction(levelFrameView, function()
                    -- play hide animation
                    self.runningStepMdt_:playAnimation('hide')
                    self:getLobbyMediator():reloadRoomBackground()
                end)

    
            elseif event.animation == 'hide' then
                -- show opeing dialogue
                self:closeRunningStep_()
                openingDialogueFunc(DialogueMediator.TYPE.OPENING)
            end
        end)

    else
        openingDialogueFunc()
    end
end


-------------------
-- closing step
--
function UnionPartyMediator:runClosingStep_(isTimely, stepId)
    local closingDialogueFunc = function()
        -- show closing dialogue
        self.runningStepMdt_ = DialogueMediator.new({dialogId = DialogueMediator.TYPE.CLOSING})
        self:GetFacade():RegistMediator(self.runningStepMdt_)
    
        self.runningStepMdt_:setFinishCB(function()
            self:closeRunningStep_()
    
            -- show closing animation
            self.runningStepMdt_ = AnimationMediator.new({spinePath = 'effects/union/party/kaichang'})
            self:GetFacade():RegistMediator(self.runningStepMdt_)
        
            -- play show animation
            self.runningStepMdt_:playAnimation('show')
            self.runningStepMdt_:listenSpineCompleteCB(function(event)
        
                if event.animation == 'show' then
                    -- play hide animation
                    self.runningStepMdt_:playAnimation('hide')
                    self:getLobbyMediator():reloadRoomBackground()
        
                elseif event.animation == 'hide' then
                    self:close()
                end
            end)
        end)
    end

    if isTimely then
        self.runningStepMdt_ = RoundResultMediator.new({readyStepId = stepId, partyModel = self:getPartyModel()})
        self:GetFacade():RegistMediator(self.runningStepMdt_)
    
        self.runningStepMdt_:setTimeEndCB(function()
            self:closeRunningStep_()
            closingDialogueFunc()
        end)
    else
        closingDialogueFunc()
    end
end


-------------------
-- roundReady step
--
function UnionPartyMediator:runRoundReadyStep_(isTimely, stepId)
    local unionManager    = self:GetFacade():GetManager('UnionManager')
    local partyStepInfo   = unionManager:getPartyStepInfo(stepId) or {}
    local openingStepInfo = unionManager:getPartyStepInfo(UNION_PARTY_STEPS.OPENING) or {}

    local readyCountdownFunc = function(countdownTime)
        self:getPartyView():hidePartyView()
        self:getPartyView():updateRoundNum(self.currentPartyRoundNum_)

        -- wait countdown
        local countdownDescr = string.fmt(__('第_num_回合即将开始'), {_num_ = unionManager:getPartyCurrentRoundNum()})
        self.runningStepMdt_ = DialogueMediator.new({targetTime = countdownTime, descrText = countdownDescr})
        self:GetFacade():RegistMediator(self.runningStepMdt_)
    end

    if isTimely then
        self.runningStepMdt_ = RoundResultMediator.new({readyStepId = stepId, partyModel = self:getPartyModel()})
        self:GetFacade():RegistMediator(self.runningStepMdt_)

        self.runningStepMdt_:setTimeEndCB(function()
            self:closeRunningStep_()

            local countdownTime = partyStepInfo.endedTime - math.ceil(self:getPartyView():getRoundSwitchTimeDefine().SWITCH_TOTAL_TIME)
            
            -- check countdown time
            if countdownTime - getServerTime() <= 1 then
                countdownTime = openingStepInfo.endedTime
            end
            readyCountdownFunc(countdownTime)

            if countdownTime ~= partyStepInfo.endedTime then
                -- round switch action
                self.runningStepMdt_:setCountdownCB(function(countTime)
                    if countTime == 0 then
                        self:closeRunningStep_()
                        self:getPartyView():runRoundSwitchAction(self.roundViewData_, unionManager:getPartyCurrentRoundNum())
                    end
                end)
            end
        end)
    else
        -- wait countdown
        readyCountdownFunc(partyStepInfo.endedTime)
    end
end


-------------------
-- dropFood step
--
function UnionPartyMediator:runDropFoodStep_(isTimely, stepId, errMsg, isLast)
    local unionManager  = self:GetFacade():GetManager('UnionManager')
    local partyStepInfo = unionManager:getPartyStepInfo(stepId) or {}
    
    -- check last dropFood
    local isRoundFail = false
    local questStepId = stepId - 4
    if isLast then
        isRoundFail = self:getPartyModel():isPassBossQuest(questStepId) == false
    end

    -- check round fail
    if isRoundFail then
        local bossQuestMdt = self:GetFacade():RetrieveMediator(BossQuestMediator.NAME)
        if not bossQuestMdt then
            self:createQuestBossView_(questStepId)

            bossQuestMdt = BossQuestMediator.new({questStepId = questStepId, partyModel = self:getPartyModel()})
            self:GetFacade():RegistMediator(bossQuestMdt)
        end
        
        self.runningStepMdt_ = bossQuestMdt
        self.runningStepMdt_:toFailStatus()

    else
        if isTimely then
            -- run dropFood
            local foodAtErrorCB = function(foodStepId, errorMsg)
                self:runDropFoodStep_(false, foodStepId, errorMsg)
            end
            self.runningStepMdt_ = DropFoodMediator.new({stepId = stepId, partyModel = self:getPartyModel(), foodAtErrorCB = foodAtErrorCB})
            self:GetFacade():RegistMediator(self.runningStepMdt_)

        else
            -- wait countdown
            local countdownDescr = string.fmt(__('_cause_\n请等待下一环节'), {_cause_ = errMsg or __('未能及时参加本轮美食分享')})
            self.runningStepMdt_ = DialogueMediator.new({targetTime = partyStepInfo.endedTime, descrText = countdownDescr})
            self:GetFacade():RegistMediator(self.runningStepMdt_)
        end
    end
end


-------------------
-- bossQuest step
function UnionPartyMediator:runBossQuestStep_(isTimely, stepId)
    local enterBossQuestFunc = function()
        self.isNeedShareMdt_ = true
        self.runningStepMdt_ = BossQuestMediator.new({questStepId = stepId, partyModel = self:getPartyModel()})
        self:GetFacade():RegistMediator(self.runningStepMdt_)
        self.runningStepMdt_:toQuestStatus()
    end

    if isTimely then
        self:createQuestBossView_(stepId)
        self:getPartyView():runPartyBossShowingAction(self.partyBossSpine_, function()
            
            -- party opeing dialogue
            self.runningStepMdt_ = DialogueMediator.new({dialogId = DialogueMediator.TYPE.BOSS_QUEST})
            self:GetFacade():RegistMediator(self.runningStepMdt_)
            
            self.runningStepMdt_:setFinishCB(function()
                -- bossQuest mediator
                self:closeRunningStep_()
                enterBossQuestFunc()
            end)
        end)


    else
        self:createQuestBossView_(stepId)
        enterBossQuestFunc()
    end
end


-------------------
-- bossResult step
function UnionPartyMediator:runBossResultStep_(isTimely, stepId)
    local bossQuestMdt = self:GetFacade():RetrieveMediator(BossQuestMediator.NAME)
    if not bossQuestMdt then
        local questStepId = stepId - 1
        self:createQuestBossView_(questStepId)

        bossQuestMdt = BossQuestMediator.new({questStepId = stepId - 1, partyModel = self:getPartyModel()})
        self:GetFacade():RegistMediator(bossQuestMdt)
    end
    
    self.isNeedShareMdt_ = true
    self.runningStepMdt_ = bossQuestMdt
    self.runningStepMdt_:toResultStatus()
end


-------------------
-- rollRewards step
function UnionPartyMediator:runRollRewardsStep_(isTimely, stepId)
    local questStepId = stepId - 2
    local isPassQuest = self:getPartyModel():isPassBossQuest(questStepId)

    if isPassQuest then
        self:closeRunningStep_()
        
        self.isNeedShareMdt_ = true
        self.runningStepMdt_ = RollRewardsMediator.new({rewardsStepId = stepId, resultStepId = stepId + 1})
        self:GetFacade():RegistMediator(self.runningStepMdt_)
        self.runningStepMdt_:toRewardsStatus()

    else
        local bossQuestMdt = self:GetFacade():RetrieveMediator(BossQuestMediator.NAME)
        if not bossQuestMdt then
            self:createQuestBossView_(questStepId)

            bossQuestMdt = BossQuestMediator.new({questStepId = questStepId, partyModel = self:getPartyModel()})
            self:GetFacade():RegistMediator(bossQuestMdt)
        end

        self.isNeedShareMdt_ = true
        self.runningStepMdt_ = bossQuestMdt
        self.runningStepMdt_:toFailStatus()
    end
end


-------------------
-- rollResult step
function UnionPartyMediator:runRollResultStep_(isTimely, stepId)
    local questStepId = stepId - 3
    local isPassQuest = self:getPartyModel():isPassBossQuest(questStepId)

    if isPassQuest then
        local rollRewardsMdt = self:GetFacade():RetrieveMediator(RollRewardsMediator.NAME)
        if not rollRewardsMdt then
            rollRewardsMdt = RollRewardsMediator.new({rewardsStepId = stepId - 1, resultStepId = stepId})
            self:GetFacade():RegistMediator(rollRewardsMdt)
        end
        
        self.runningStepMdt_ = rollRewardsMdt
        self.runningStepMdt_:toResultStatus()
        
    else
        local bossQuestMdt = self:GetFacade():RetrieveMediator(BossQuestMediator.NAME)
        if not bossQuestMdt then
            self:createQuestBossView_(questStepId)

            bossQuestMdt = BossQuestMediator.new({questStepId = questStepId, partyModel = self:getPartyModel()})
            self:GetFacade():RegistMediator(bossQuestMdt)
        end
        
        self.isNeedShareMdt_ = true
        self.runningStepMdt_ = bossQuestMdt
        self.runningStepMdt_:toFailStatus()
    end
end


return UnionPartyMediator
