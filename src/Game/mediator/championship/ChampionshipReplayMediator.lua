--[[
 * author : kaishiqi
 * descpt : 武道会 - 回放中介者
]]
local ChampionshipReplayView     = require('Game.views.championship.ChampionshipReplayView')
local ChampionshipReplayMediator = class('ChampionshipReplayMediator', mvc.Mediator)

local MAIN_PROXY_NAME     = FOOD.CHAMPIONSHIP.MAIN.PROXY_NAME
local MAIN_PROXY_STRUCT   = FOOD.CHAMPIONSHIP.MAIN.PROXY_STRUCT
local REPLAY_PROXY_NAME   = FOOD.CHAMPIONSHIP.REPLAY.PROXY_NAME
local REPLAY_PROXY_STRUCT = FOOD.CHAMPIONSHIP.REPLAY.PROXY_STRUCT

function ChampionshipReplayMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'ChampionshipReplayMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance

function ChampionshipReplayMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    local replayMatchId  = checkint(self.ctorArgs_.matchId)
    self.isControllable_ = true

    -- init model
    self.mainProxy_   = app:RetrieveProxy(MAIN_PROXY_NAME)
    self.replayProxy_ = regVoProxy(REPLAY_PROXY_NAME, REPLAY_PROXY_STRUCT)
    self.replayProxy_:set(REPLAY_PROXY_STRUCT.REPLAY_MATCH_ID, replayMatchId)
    self:initReplayModel_()

    -- create view
    self.viewNode_ = ChampionshipReplayView.new()
    self:SetViewComponent(self:getViewNode())
    app.uiMgr:GetCurrentScene():AddDialog(self:getViewNode())

    -- add listener
    ui.bindClick(self:getViewData().backBtn, handler(self, self.onClickBackButtonHandler_))
    for teamIndex = 1, 3 do
        ui.bindClick(self:getViewData().replayBtnList[teamIndex], handler(self, self.onClickReplayButtonHandler_))
        ui.bindClick(self:getViewData().atkTeamVDList[teamIndex].clickArea, handler(self, self.onClickAttackerTeamAreaHandler_))
        ui.bindClick(self:getViewData().defTeamVDList[teamIndex].clickArea, handler(self, self.onClickDefenderTeamAreaHandler_))
    end
end


function ChampionshipReplayMediator:CleanupView()
    unregVoProxy(REPLAY_PROXY_NAME)

    app.uiMgr:GetCurrentScene():RemoveDialogByName('common.PreviewTeamDetailPopup')
    if self:getViewNode() and not tolua.isnull(self:getViewNode()) then
        self:getViewNode():removeFromParent()
        self.viewNode_ = nil
    end
end


function ChampionshipReplayMediator:OnRegist()
    regPost(POST.CHAMPIONSHIP_REPLAY_RESULT)
    regPost(POST.CHAMPIONSHIP_REPLAY_DETAIL)

    -- request replay result
    local SEND_STRUCT = REPLAY_PROXY_STRUCT.REPLAY_RESULT_SEND
    self:SendSignal(POST.CHAMPIONSHIP_REPLAY_RESULT.cmdName, self.replayProxy_:get(SEND_STRUCT):getData())
end


function ChampionshipReplayMediator:OnUnRegist()
    unregPost(POST.CHAMPIONSHIP_REPLAY_RESULT)
    unregPost(POST.CHAMPIONSHIP_REPLAY_DETAIL)
end


function ChampionshipReplayMediator:InterestSignals()
    return {
        POST.CHAMPIONSHIP_REPLAY_RESULT.sglName,
        POST.CHAMPIONSHIP_REPLAY_DETAIL.sglName,
    }
end
function ChampionshipReplayMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    if name == POST.CHAMPIONSHIP_REPLAY_RESULT.sglName then
        self.replayProxy_:set(REPLAY_PROXY_STRUCT.REPLAY_RESULT_TAKE, data)


    elseif name == POST.CHAMPIONSHIP_REPLAY_DETAIL.sglName then
        local DETAIL_DATA_STRUCT  = REPLAY_PROXY_STRUCT.REPLAY_DETAIL_TAKE
        local RESULT_DATA_STRUCT  = REPLAY_PROXY_STRUCT.REPLAY_RESULT_TAKE.RESULT.DATA
        local replaySequenceIndex = self.replayProxy_:get(REPLAY_PROXY_STRUCT.REPLAY_DETAIL_SEND.SEQUENCE)
        local resultDataProxy     = self.replayProxy_:get(RESULT_DATA_STRUCT, tostring(replaySequenceIndex))
        local attackerTeamData    = resultDataProxy:get(RESULT_DATA_STRUCT.ATTACKER_TEAM):getData()
        local defenderTeamData    = resultDataProxy:get(RESULT_DATA_STRUCT.DEFENDER_TEAM):getData()
        self.replayProxy_:set(DETAIL_DATA_STRUCT, data)
        
        -- 跳转参数
        local fromToStruct = BattleMediatorsConnectStruct.New(
            'championship.ChampionshipHomeMediator', -- from mdt
            'championship.ChampionshipHomeMediator'  -- to mdt
        )

        -- 回放战斗
        local battleConstructor = require('battleEntry.BattleConstructor').new()
        battleConstructor:OpenReplay(
            nil,                                                      -- 关卡id
            self.replayProxy_:get(DETAIL_DATA_STRUCT.DATA.CTOR_JSON), -- 构造器json
            json.encode({attackerTeamData}),                          -- 友方阵容json
            json.encode({defenderTeamData}),                          -- 敌方阵容json
            self.replayProxy_:get(DETAIL_DATA_STRUCT.DATA.LOAD_JSON), -- 加载资源表json
            self.replayProxy_:get(DETAIL_DATA_STRUCT.DATA.OPTE_JSON), -- 玩家手操信息json
            fromToStruct                                              -- 跳转信息
        )
    end
end


-------------------------------------------------
-- get / set

function ChampionshipReplayMediator:getViewNode()
    return  self.viewNode_
end
function ChampionshipReplayMediator:getViewData()
    return self:getViewNode():getViewData()
end


-------------------------------------------------
-- public

function ChampionshipReplayMediator:close()
    app:UnRegsitMediator(self:GetMediatorName())
end


-------------------------------------------------
-- private

function ChampionshipReplayMediator:initReplayModel_()
    local replayMatchId   = self.replayProxy_:get(REPLAY_PROXY_STRUCT.REPLAY_MATCH_ID)
    local SCHEDULE_STRUCT = MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.PROMOTION_SCHEDULE
    local matchDataProxy  = self.mainProxy_:get(SCHEDULE_STRUCT.MATCH_DATA, tostring(replayMatchId))
    local matchAttackerId = matchDataProxy:get(SCHEDULE_STRUCT.MATCH_DATA.ATTACKER_ID)
    local matchDefenderId = matchDataProxy:get(SCHEDULE_STRUCT.MATCH_DATA.DEFENDER_ID)
    self.replayProxy_:set(REPLAY_PROXY_STRUCT.ATTACKER_ID, matchAttackerId)
    self.replayProxy_:set(REPLAY_PROXY_STRUCT.DEFENDER_ID, matchDefenderId)
    self.replayProxy_:set(REPLAY_PROXY_STRUCT.REPLAY_RESULT_SEND.MATCH_ID, replayMatchId)
    self.replayProxy_:set(REPLAY_PROXY_STRUCT.REPLAY_DETAIL_SEND.MATCH_ID, replayMatchId)
end


-------------------------------------------------
-- handler

function ChampionshipReplayMediator:onClickBackButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    self:close()
end


function ChampionshipReplayMediator:onClickReplayButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local teamIndex   = checkint(sender:getTag())
    local DATA_STRUCT = REPLAY_PROXY_STRUCT.REPLAY_RESULT_TAKE.RESULT.DATA
    local resultProxy = self.replayProxy_:get(DATA_STRUCT, tostring(teamIndex))
    
    if resultProxy:size(DATA_STRUCT.ATTACKER_TEAM) == 0 then
        app.uiMgr:ShowInformationTips(__('进攻方队伍为空，无法播放战斗'))
        return
    end
    
    if resultProxy:size(DATA_STRUCT.DEFENDER_TEAM) == 0 then
        app.uiMgr:ShowInformationTips(__('防守方队伍为空，无法播放战斗'))
        return
    end
    
    local SEND_STRUCT = REPLAY_PROXY_STRUCT.REPLAY_DETAIL_SEND
    self.replayProxy_:set(SEND_STRUCT.SEQUENCE, teamIndex)
    self:SendSignal(POST.CHAMPIONSHIP_REPLAY_DETAIL.cmdName, self.replayProxy_:get(SEND_STRUCT):getData())
end


function ChampionshipReplayMediator:onClickAttackerTeamAreaHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local teamIndex   = checkint(sender:getTag())
    local DATA_STRUCT = REPLAY_PROXY_STRUCT.REPLAY_RESULT_TAKE.RESULT.DATA
    local resultProxy = self.replayProxy_:get(DATA_STRUCT, tostring(teamIndex))
    local TEAM_STRUCT = DATA_STRUCT.ATTACKER_TEAM
    if resultProxy:size(TEAM_STRUCT) > 0 then
        local attackerId     = self.replayProxy_:get(REPLAY_PROXY_STRUCT.ATTACKER_ID)
        local PLAYERS_STRUCT = MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.PROMOTION_PLAYERS
        local attackerProxy  = self.mainProxy_:get(PLAYERS_STRUCT.PLAYER_DATA, tostring(attackerId))
        local attackerName   = attackerProxy:get(PLAYERS_STRUCT.PLAYER_DATA.NAME)
        local attackerUnion  = attackerProxy:get(PLAYERS_STRUCT.PLAYER_DATA.UNION)
        local attackerAvatar = attackerProxy:get(PLAYERS_STRUCT.PLAYER_DATA.AVATAR)
        local attackerFrame  = attackerProxy:get(PLAYERS_STRUCT.PLAYER_DATA.FRAME)
        local attackerLevel  = attackerProxy:get(PLAYERS_STRUCT.PLAYER_DATA.LEVEL)
        app.uiMgr:AddDialog('common.PreviewTeamDetailPopup', {
            playerId = attackerId,
            name     = attackerName,
            union    = attackerUnion,
            avatar   = attackerAvatar,
            frame    = attackerFrame,
            level    = attackerLevel,
            teamData = resultProxy:get(TEAM_STRUCT):getData(),
        })
    else
        app.uiMgr:ShowInformationTips(__('进攻方队伍为空'))
    end
end


function ChampionshipReplayMediator:onClickDefenderTeamAreaHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local teamIndex   = checkint(sender:getTag())
    local DATA_STRUCT = REPLAY_PROXY_STRUCT.REPLAY_RESULT_TAKE.RESULT.DATA
    local resultProxy = self.replayProxy_:get(DATA_STRUCT, tostring(teamIndex))
    local TEAM_STRUCT = DATA_STRUCT.DEFENDER_TEAM
    if resultProxy:size(TEAM_STRUCT) > 0 then
        local defenderId     = self.replayProxy_:get(REPLAY_PROXY_STRUCT.DEFENDER_ID)
        local PLAYERS_STRUCT = MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.PROMOTION_PLAYERS
        local defenderProxy  = self.mainProxy_:get(PLAYERS_STRUCT.PLAYER_DATA, tostring(defenderId))
        local defenderName   = defenderProxy:get(PLAYERS_STRUCT.PLAYER_DATA.NAME)
        local defenderUnion  = defenderProxy:get(PLAYERS_STRUCT.PLAYER_DATA.UNION)
        local defenderAvatar = defenderProxy:get(PLAYERS_STRUCT.PLAYER_DATA.AVATAR)
        local defenderFrame  = defenderProxy:get(PLAYERS_STRUCT.PLAYER_DATA.FRAME)
        local defenderLevel  = defenderProxy:get(PLAYERS_STRUCT.PLAYER_DATA.LEVEL)
        app.uiMgr:AddDialog('common.PreviewTeamDetailPopup', {
            playerId = defenderId,
            name     = defenderName,
            union    = defenderUnion,
            avatar   = defenderAvatar,
            frame    = defenderFrame,
            level    = defenderLevel,
            teamData = resultProxy:get(TEAM_STRUCT):getData(),
        })
    else
        app.uiMgr:ShowInformationTips(__('防守方队伍为空'))
    end
end


return ChampionshipReplayMediator
