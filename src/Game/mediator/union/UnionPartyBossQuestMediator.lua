--[[
 * author : kaishiqi
 * descpt : 工会派对 - BOSS挑战中介者
]]
local UnionConfigParser           = require('Game.Datas.Parser.UnionConfigParser')
local UnionPartyBossQuestView     = require('Game.views.union.UnionPartyBossQuestView')
local UnionPartyBossQuestMediator = class('UnionPartyBossQuestMediator', mvc.Mediator)
UnionPartyBossQuestMediator.NAME  = 'UnionPartyBossQuestMediator'

function UnionPartyBossQuestMediator:ctor(params, viewComponent)
    self.super.ctor(self, UnionPartyBossQuestMediator.NAME, viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance method

function UnionPartyBossQuestMediator:Initial(key)
    self.super.Initial(self, key)

    -- parse args
    self.partyModel_       = self.ctorArgs_.partyModel
    self.bossQuestStepId_  = checkint(self.ctorArgs_.questStepId)
    self.boosResultStepId_ = self.bossQuestStepId_ + 1
    self.roundEndedStepId_ = self.bossQuestStepId_ + 4
    self.isControllable_   = true

    -- create view
    local uiManager     = self:GetFacade():GetManager('UIManager')
    self.ownerScene_    = uiManager:GetCurrentScene()
    self.bossQuestView_ = UnionPartyBossQuestView.new()
    self.ownerScene_:AddDialog(self.bossQuestView_)

    -- add listener
    local bossViewData = self:getBossQuestView():getViewData()
    display.commonUIParams(bossViewData.questFightBtn, {cb = handler(self, self.onClickBossQuestHandler_)})

    -- update views
    local partyQuestConf = CommonUtils.GetConfigNoParser('union', UnionConfigParser.TYPE.PARTY_QUEST, self:getBossQuestId()) or {}
    self:getBossQuestView():updateQuestTargetDescr(partyQuestConf.stageCompleteDescr)
    self:getBossQuestView():updateQuestProgressMax(self.partyModel_:getBossKillTarget())
    self:updateQuestProgressNum_()
    self:updateSelfPassedBoss_()
end


function UnionPartyBossQuestMediator:CleanupView()
    self:stopBossQuestUpdate_()
    self:stopBossResultUpdate_()
    self:stopRoundEndedUpdate_()

    if self.ownerScene_ then
        if self.bossQuestView_ and self.bossQuestView_:getParent() then
            self.ownerScene_:RemoveDialog(self.bossQuestView_)
            self.bossQuestView_ = nil
        end
        self.ownerScene_ = nil
    end
end


function UnionPartyBossQuestMediator:OnRegist()
end
function UnionPartyBossQuestMediator:OnUnRegist()
end


function UnionPartyBossQuestMediator:InterestSignals()
    return {
        SGL.UNION_PARTY_BOSS_RESULT_UPDATE,
        SGL.UNION_PARTY_MODEL_BOSS_KILL_CHANGE,
        SGL.UNION_PARTY_MODEL_SELF_PASSED_CHANGE,
    }
end
function UnionPartyBossQuestMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    if name == SGL.UNION_PARTY_MODEL_BOSS_KILL_CHANGE then
        self:updateQuestProgressNum_()


    elseif name == SGL.UNION_PARTY_MODEL_SELF_PASSED_CHANGE then
        self:updateSelfPassedBoss_()


    elseif name == SGL.UNION_PARTY_BOSS_RESULT_UPDATE then
        self.partyModel_:setBossKillNum(data.questStepId, data.memberWinTimes)
    
    end
end


-------------------------------------------------
-- get / set

function UnionPartyBossQuestMediator:getBossQuestView()
    return self.bossQuestView_
end


function UnionPartyBossQuestMediator:getBossQuestId()
    return self.partyModel_ and self.partyModel_:getBossQuestId(self.bossQuestStepId_) or 0
end


-------------------------------------------------
-- public method

function UnionPartyBossQuestMediator:close()
    self:GetFacade():UnRegsitMediator(self:GetMediatorName())
end


function UnionPartyBossQuestMediator:toQuestStatus()
    local unionManager    = self:GetFacade():GetManager('UnionManager')
    local questStepInfo   = unionManager:getPartyStepInfo(self.bossQuestStepId_) or {}
    self.questEndedTime_  = checkint(questStepInfo.endedTime)
    self:getBossQuestView():getViewData().questLayer:setVisible(true)
    self:getBossQuestView():getViewData().resultLayer:setVisible(false)
    self:getBossQuestView():getViewData().failLayer:setVisible(false)

    self:updateBossQuestStatus_()
    self:startBossQuestUpdate_()
    self:stopBossResultUpdate_()
    self:stopRoundEndedUpdate_()
end


function UnionPartyBossQuestMediator:toResultStatus()
    local unionManager     = self:GetFacade():GetManager('UnionManager')
    local resultStepInfo   = unionManager:getPartyStepInfo(self.boosResultStepId_) or {}
    self.resultEndedTime_  = checkint(resultStepInfo.endedTime)
    self:getBossQuestView():getViewData().questLayer:setVisible(false)
    self:getBossQuestView():getViewData().resultLayer:setVisible(true)
    self:getBossQuestView():getViewData().failLayer:setVisible(false)

    self:updateBossResultStatus_()
    self:stopBossQuestUpdate_()
    self:startBossResultUpdate_()
    self:stopRoundEndedUpdate_()
end


function UnionPartyBossQuestMediator:toFailStatus()
    local unionManager   = self:GetFacade():GetManager('UnionManager')
    local endedStepInfo  = unionManager:getPartyStepInfo(self.roundEndedStepId_) or {}
    self.roundEndedTime_ = checkint(endedStepInfo.endedTime)
    self:getBossQuestView():getViewData().questLayer:setVisible(false)
    self:getBossQuestView():getViewData().resultLayer:setVisible(false)
    self:getBossQuestView():getViewData().failLayer:setVisible(true)

    self:updateRoundEndedStatus_()
    self:stopBossQuestUpdate_()
    self:stopBossQuestUpdate_()
    self:stopBossResultUpdate_()
    self:startRoundEndedUpdate_()
end


-------------------------------------------------
-- private method

function UnionPartyBossQuestMediator:updateQuestProgressNum_()
    local bossKillNum = self.partyModel_:getBossKillNum(self.bossQuestStepId_)
    self:getBossQuestView():updateQuestProgressNum(bossKillNum)
end


function UnionPartyBossQuestMediator:updateSelfPassedBoss_()
    local isPassedBoss = self.partyModel_:isSelfPassedBoss(self.bossQuestStepId_)
    self:getBossQuestView():getViewData().questFightBtn:setEnabled(not isPassedBoss)
end


-- bossQuest update
function UnionPartyBossQuestMediator:startBossQuestUpdate_()
    if self.bossQuestUpdateHandler_ then return end
    self.bossQuestUpdateHandler_ = scheduler.scheduleGlobal(function()
        self:updateBossQuestStatus_()
    end, 1)
end
function UnionPartyBossQuestMediator:stopBossQuestUpdate_()
    if self.bossQuestUpdateHandler_ then
        scheduler.unscheduleGlobal(self.bossQuestUpdateHandler_)
        self.bossQuestUpdateHandler_ = nil
    end
end
function UnionPartyBossQuestMediator:updateBossQuestStatus_()
    local questTimeLeft = checkint(self.questEndedTime_) - getServerTime()
    self:getBossQuestView():updateQuestTime(questTimeLeft)
end


-- bossResult update
function UnionPartyBossQuestMediator:startBossResultUpdate_()
    if self.bossResultUpdateHandler_ then return end
    self.bossResultUpdateHandler_ = scheduler.scheduleGlobal(function()
        self:updateBossResultStatus_()
    end, 1)
end
function UnionPartyBossQuestMediator:stopBossResultUpdate_()
    if self.bossResultUpdateHandler_ then
        scheduler.unscheduleGlobal(self.bossResultUpdateHandler_)
        self.bossResultUpdateHandler_ = nil
    end
end
function UnionPartyBossQuestMediator:updateBossResultStatus_()
    local resultTimeLeft = checkint(self.resultEndedTime_) - getServerTime()
    self:getBossQuestView():updateResultTime(resultTimeLeft)
end


-- roundEnded update
function UnionPartyBossQuestMediator:startRoundEndedUpdate_()
    if self.roundEndedUpdateHandler_ then return end
    self.roundEndedUpdateHandler_ = scheduler.scheduleGlobal(function()
        self:updateRoundEndedStatus_()
    end, 1)
end
function UnionPartyBossQuestMediator:stopRoundEndedUpdate_()
    if self.roundEndedUpdateHandler_ then
        scheduler.unscheduleGlobal(self.roundEndedUpdateHandler_)
        self.roundEndedUpdateHandler_ = nil
    end
end
function UnionPartyBossQuestMediator:updateRoundEndedStatus_()
    local endedTimeLeft = checkint(self.roundEndedTime_) - getServerTime()
    self:getBossQuestView():updateEndedTime(endedTimeLeft)
end


-------------------------------------------------
-- handler

function UnionPartyBossQuestMediator:onClickBossQuestHandler_(sender)
    PlayAudioByClickNormal()

    -- to call battleReadyView
    local gameManager     = AppFacade.GetInstance():GetManager('GameManager')
    local gameUserInfo    = gameManager:GetUserInfo()
    local battleReadyData = BattleReadyConstructorStruct.New(
        1,                                           -- 战斗模式（1:通用战斗）
        gameUserInfo.localCurrentBattleTeamId,       -- 默认 编队序号
        gameUserInfo.localCurrentEquipedMagicFoodId, -- 默认 携带魔法诱饵
        self:getBossQuestId(),                       -- 派对关卡id
        QuestBattleType.UNION_PARTY,                 -- 战斗类型
        nil,
        POST.UNION_PARTY_BOSS_QUEST_AT.cmdName,      -- 战斗进入 命令
        {
            stepId        = self.bossQuestStepId_,
            partyBaseTime = app.unionMgr:getPartyBaseTime()
        },                                           -- 战斗进入 参数
        POST.UNION_PARTY_BOSS_QUEST_AT.sglName,      -- 战斗进入 信号
        POST.UNION_PARTY_BOSS_QUEST_GRADE.cmdName,   -- 战斗结算 命令
        {
            stepId        = self.bossQuestStepId_,
            partyBaseTime = app.unionMgr:getPartyBaseTime()
        },                                           -- 战斗结算 参数
        POST.UNION_PARTY_BOSS_QUEST_GRADE.sglName,   -- 战斗结算 信号
        self:GetMediatorName(),                      -- 来自哪个 mdt
        'UnionLobbyMediator'                         -- 回到哪个 mdt
    )
    self:GetFacade():DispatchObservers(SGL.Battle_UI_Create_Battle_Ready, battleReadyData)
end


return UnionPartyBossQuestMediator
