local SweepChoiceView     = require('Game.views.map.SweepChoiceView')
local SweepChoiceMediator = class('SweepChoiceMediator', mvc.Mediator)

function SweepChoiceMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'SweepChoiceMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance
local MAX_LIMIT_NUM = 20
function SweepChoiceMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    self.isControllable_ = true

    -- create view
    self.viewNode_ = SweepChoiceView.new()
    self:SetViewComponent(self:getViewNode())
    app.uiMgr:GetCurrentScene():AddDialog(self:getViewNode())

    -- add listener
    ui.bindClick(self:getViewData().blockLayer, handler(self, self.onClickBackButtonHandler_), false)
    ui.bindClick(self:getViewData().delBtn, handler(self, self.onClickDelButtonHandler_))
    ui.bindClick(self:getViewData().addBtn, handler(self, self.onClickAddButtonHandler_))
    ui.bindClick(self:getViewData().numBtn, handler(self, self.onClickNumButtonHandler_), false)
    ui.bindClick(self:getViewData().sweepBtn, handler(self, self.onClickSweepButtonHandler_))
    ui.bindClick(self:getViewData().minBtn, handler(self, self.onClickMinButtonHandler_))
    ui.bindClick(self:getViewData().maxBtn, handler(self, self.onClickMaxButtonHandler_))

    -- update views
    self:setChooseLimitNum(MAX_LIMIT_NUM)
    self:setStageId(self.ctorArgs_.stageId)
    self:setSweepNum(1)
end


function SweepChoiceMediator:CleanupView()
    if self:getViewNode() and not tolua.isnull(self:getViewNode()) then
        self:getViewNode():removeFromParent()
        self.viewNode_ = nil
    end
end


function SweepChoiceMediator:OnRegist()
    regPost(POST.QUEST_SWEEP)
end


function SweepChoiceMediator:OnUnRegist()
    unregPost(POST.QUEST_SWEEP)
end


function SweepChoiceMediator:InterestSignals()
    return {
        POST.QUEST_SWEEP.sglName,
    }
end
function SweepChoiceMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    if name == POST.QUEST_SWEEP.sglName then
        local stageId    = checkint(data.requestData.questId)
        local stageConf  = CommonUtils.GetQuestConf(stageId)
        local battleType = CommonUtils.GetQuestBattleByQuestId(stageId)
    
        -- refresh good data
        CommonUtils.DrawRewards({
            {goodsId = GOLD_ID, num  = data.totalGold},
            {goodsId = HP_ID, num = -checkint(stageConf.consumeHp) * data.requestData.times}
        })
        for k,v in pairs(data.sweep or {}) do
            CommonUtils.DrawRewards(checktable(v.rewards))			
        end

        -- refresh changeTime
        if data.challengeTime and data.challengeTime ~= -1 then
            app.gameMgr:UpdateChallengeTimeByStageId(stageId, checkint(data.challengeTime))
            AppFacade.GetInstance():DispatchObservers(SGL.QUEST_CHALLENGE_TIME_UPDATE)
            self:setChooseLimitNum(app.gameMgr:GetUserInfo().allQuestChallengeTimes[tostring(self:getStageId())])
        end
        self:setSweepNum(1)
        
        self:showSweepRewardPopup(data)
    end
end


-------------------------------------------------
-- get / set

function SweepChoiceMediator:getViewNode()
    return  self.viewNode_
end
function SweepChoiceMediator:getViewData()
    return self:getViewNode():getViewData()
end


function SweepChoiceMediator:setStageId(stageId)
    self.stageId_ = checkint(stageId)

    local stageConf = CommonUtils.GetQuestConf(self:getStageId())
    if stageConf and checkint(stageConf.difficulty)  == 2 then
        local challengeNum = checkint(app.gameMgr:GetUserInfo().allQuestChallengeTimes[tostring(self:getStageId())])
        if self:getChooseLimitNum() > challengeNum then
            self:setChooseLimitNum(challengeNum)
        end
    end
end
function SweepChoiceMediator:getStageId()
    return checkint(self.stageId_)
end


function SweepChoiceMediator:setChooseLimitNum(num)
    self.chooseLimitNum_ = checkint(num)
    self:getViewNode():updateLimitNum(self:getChooseLimitNum())
end
function SweepChoiceMediator:getChooseLimitNum()
    return checkint(self.chooseLimitNum_)
end


function SweepChoiceMediator:setSweepNum(num)
    self.sweepNum_ = checkint(num)
    self:getViewNode():updateNumHandler(self:getSweepNum(), self:getStageId())
end
function SweepChoiceMediator:getSweepNum()
    return checkint(self.sweepNum_)
end
-------------------------------------------------
-- public

function SweepChoiceMediator:close()
    app:UnRegsitMediator(self:GetMediatorName())
end


-------------------------------------------------
-- private
function SweepChoiceMediator:checkIsCanSweep_()
	local stageConf  = CommonUtils.GetQuestConf(self:getStageId())
	local battleType = CommonUtils.GetQuestBattleByQuestId(self:getStageId())

    local isCanSweep = false
    local cityId = checkint(stageConf.cityId)
    -- 本关三星
    local leftRechallengeTimes = CommonUtils.GetRechallengeLeftTimesByStageId(self:getStageId())
    if nil == app.gameMgr:GetUserInfo().questGrades[tostring(cityId)] or
        3 > checkint(app.gameMgr:GetUserInfo().questGrades[tostring(cityId)].grades[tostring(self:getStageId())]) then
        app.uiMgr:ShowInformationTips(__('达成本关三星才能扫荡'))
    -- 扫荡次数
    elseif checkint(stageConf.consumeHp) * self:getSweepNum() > app.goodsMgr:GetGoodsAmountByGoodsId(HP_ID) then
        app.uiMgr:ShowInformationTips(__('体力不足'))
    -- 剩余次数
    elseif QuestRechallengeTime.QRT_NONE == leftRechallengeTimes then
        app.uiMgr:ShowInformationTips(__('挑战次数不足\n挑战次数每日0:00重置'))
    elseif QuestRechallengeTime.QRT_INFINITE ~= leftRechallengeTimes and leftRechallengeTimes < self:getSweepNum() then
        app.uiMgr:ShowInformationTips(__('挑战次数不足\n挑战次数每日0:00重置'))
    elseif self:getSweepNum() <= 0 then
        app.uiMgr:ShowInformationTips(__("请输入有效的扫荡次数"))
    else
        isCanSweep = true
    end

	return isCanSweep
end


function SweepChoiceMediator:showSweepRewardPopup(data)
    local tag             = 2005
    local passTicketPoint = 0
    local delayList       = nil
    if data.totalMainExp then
        delayList = CommonUtils.DrawRewards({{goodsId = EXP_ID, num = (checkint(data.totalMainExp) - app.gameMgr:GetUserInfo().mainExp)}}, true)
    end
    if nil ~= app.passTicketMgr and nil ~= app.passTicketMgr.UpdateExpByTask then
        local questId = data.requestData.questId
        app.passTicketMgr:UpdateExpByQuestId(questId, true, data.requestData.times)
        
        passTicketPoint = app.passTicketMgr:GetTaskPointByQuestId(questId)
    end
    if checkint(data.requestData.times ) == 1 then 
        if checkint(data.sweep['1'].mainExp) > 0 then
            data.sweep['1'].rewards[#data.sweep['1'].rewards+1] = {goodsId = EXP_ID, num = data.sweep['1'].mainExp}
        end
        local realRewards = nil
        if passTicketPoint > 0 then
            realRewards = clone(data.sweep['1'].rewards)
            table.insert(realRewards, {goodsId = PASS_TICKET_ID, num = passTicketPoint})
        end
        app.uiMgr:AddDialog('common.RewardPopup', {rewards = realRewards or data.sweep['1'].rewards,mainExp = data.sweep['1'].mainExp ,addBackpack = false,delayFuncList_ = delayList})
    else
        local layer = require('Game.views.SweepRewardPopup').new({tag = tag, rewardsData = data , executeAction = true , delayFuncList_ = delayList, passTicketPoint = passTicketPoint})
        display.commonUIParams(layer, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
        layer:setTag(tag)
        app.uiMgr:GetCurrentScene():AddDialog(layer)
    end
end

-------------------------------------------------
-- handler
function SweepChoiceMediator:onClickBackButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    self:close()
end


function SweepChoiceMediator:onClickDelButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    local curSweepNum = self:getSweepNum() - 1
    if curSweepNum <= 0 then
        app.uiMgr:ShowInformationTips(__("扫荡次数已达最低下限"))
    else
        self:setSweepNum(curSweepNum)
    end
end


function SweepChoiceMediator:onClickNumButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end
	
	local tempData = {
        callback = handler(self, self.onClickKeyBoardReturn),
        titleText = string.fmt(__('请输入扫荡的次数(最高_num_次)'), {_num_ = MAX_LIMIT_NUM}),
        nums = math.floor(math.log10(MAX_LIMIT_NUM)) + 1,
        model = NumboardModel.freeModel,
    }

	local mediator = require( 'Game.mediator.NumKeyboardMediator' ).new(tempData)
	app:RegistMediator(mediator)
end


function SweepChoiceMediator:onClickAddButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local curSweepNum = self:getSweepNum() + 1
    if curSweepNum > self:getChooseLimitNum() then
        app.uiMgr:ShowInformationTips(__("扫荡次数已达最大上限"))
    else
        self:setSweepNum(curSweepNum)
    end
end


function SweepChoiceMediator:onClickSweepButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    if self:checkIsCanSweep_() then
        self:SendSignal(POST.QUEST_SWEEP.cmdName, {questId = self:getStageId(), times = self:getSweepNum()})
	end
end

function SweepChoiceMediator:onClickKeyBoardReturn(data)
    if not data then return end
    local sweepNum = checkint(data)
    if sweepNum <= 0 then
        sweepNum = 1
    elseif sweepNum > self:getChooseLimitNum() then
        sweepNum = self:getChooseLimitNum()
    end
    self:setSweepNum(sweepNum)
end


function SweepChoiceMediator:onClickMinButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local goodsNum  = app.goodsMgr:GetGoodsAmountByGoodsId(HP_ID)
    local stageConf = CommonUtils.GetQuestConf(self:getStageId())
    local onceNum   = checkint(stageConf.consumeHp)
    local maxSweepNum = math.max(math.floor(goodsNum / onceNum), 0)
    self:setSweepNum(math.min(1, maxSweepNum, self:getChooseLimitNum()))
end


function SweepChoiceMediator:onClickMaxButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end


    local goodsNum  = app.goodsMgr:GetGoodsAmountByGoodsId(HP_ID)
    local stageConf = CommonUtils.GetQuestConf(self:getStageId())
    local onceNum   = checkint(stageConf.consumeHp)
    local maxSweepNum = math.max(math.floor(goodsNum / onceNum), 0)
    self:setSweepNum(math.min(maxSweepNum, self:getChooseLimitNum()))
end


return SweepChoiceMediator
