--[[
 * author : kaishiqi
 * descpt : 武道会 - 赛程节点
]]
local ChampionshipScheduleNode = class('ChampionshipScheduleNode', function()
    return ui.layer({name = 'ChampionshipScheduleNode', enableEvent = true})
end)

local RES_DICT = {
    BG_IMAGE        = _res('ui/championship/schedule/budo_bg_common_bg_2.png'),
    TITLE_FRAME     = _res('ui/championship/schedule/budo_ticket_bg_head.png'),
    TYPE_BTN_S      = _res('ui/championship/schedule/budo_ticket_btn_team_chose.png'),
    TYPE_BTN_N      = _res('ui/championship/schedule/budo_ticket_btn_team_grey.png'),
    TEAM_BTN_S      = _res('ui/championship/schedule/budo_ticket_bg_team_name.png'),
    TEAM_FRAME      = _res('ui/championship/schedule/budo_ticket_bg_team_list.png'),
    TEAM_CLINE      = _res('ui/championship/schedule/budo_ticket_line_team_list.png'),
    FIRE_SPINE      = _spn('ui/championship/schedule/skeleton'),
    --              = group panel
    REPLAY_BTN      = _res('ui/championship/report/starplan_vs_btn_playback_small.png'),
    VS_ICON_D       = _res('ui/championship/report/starplan_vs_icon_vs_lost.png'),
    VS_ICON_N       = _res('ui/championship/report/starplan_vs_icon_vs_small.png'),
    MATCH_FINAL     = _res('ui/championship/schedule/budo_ticket_line_final.png'),
    MATCH_GROUP     = _res('ui/championship/schedule/budo_ticket_line_group.png'),
    --              = player cell
    GROUP_FRAME_R1  = _res('ui/championship/schedule/budo_ticket_bg_ren_1.png'),
    GROUP_FRAME_R2  = _res('ui/championship/schedule/budo_ticket_bg_ren_2.png'),
    GROUP_FRAME_R3  = _res('ui/championship/schedule/budo_ticket_bg_ren_3.png'),
    GROUP_FRAME_R0  = _res('ui/championship/schedule/budo_ticket_bg_ren_4.png'),
    FINAL_FRAME_R4  = _res('ui/championship/schedule/budo_ticket_bg_ren_big_1.png'),
    FINAL_FRAME_R5  = _res('ui/championship/schedule/budo_ticket_bg_ren_big_2.png'),
    FINAL_FRAME_R0  = _res('ui/championship/schedule/budo_ticket_bg_ren_big_4.png'),
    GROUP_FRAME_D   = _res('ui/championship/schedule/budo_ticket_bg_ren_lost.png'),
    FINAL_FRAME_D   = _res('ui/championship/schedule/budo_ticket_bg_ren_lost_2.png'),
    FINAL_PLAYER_S  = _res('ui/championship/schedule/budo_ticket_btn_ren_light_big_1.png'),
    FINAL_PLAYER_D  = _res('ui/championship/schedule/budo_ticket_btn_ren_big_grey.png'),
    FINAL_PLAYER_N  = _res('ui/championship/schedule/budo_ticket_btn_ren_big.png'),
    GROUP_PLAYER_S  = _res('ui/championship/schedule/budo_ticket_btn_ren_light_1.png'),
    GROUP_PLAYER_D  = _res('ui/championship/schedule/budo_ticket_btn_ren_grey.png'),
    GROUP_PLAYER_N  = _res('ui/championship/schedule/budo_ticket_btn_ren.png'),
    TOP_WINNER_ICON = _res('ui/championship/schedule/budo_ticket_ico_ren_win.png'),
    LOST_ICON       = _res('ui/championship/report/pvp_report_ico_defeat.png'),
    GUESS_ICON      = _res('ui/championship/schedule/budo_ticket_ico_xin.png'),
}

local ACTION_ENUM = {
    RELOAD_PLAYER_VOTE = 1,
}

local MAIN_PROXY_NAME   = FOOD.CHAMPIONSHIP.MAIN.PROXY_NAME
local MAIN_PROXY_STRUCT = FOOD.CHAMPIONSHIP.MAIN.PROXY_STRUCT


-------------------------------------------------
-- life cycle

function ChampionshipScheduleNode:ctor(args)
    local initArgs   = checktable(args)
    self.detailType_ = initArgs.type

    -- init vars
    self.currentPanelVD_ = nil
    self.isControllable_ = true

    -- create view
    self.viewData_ = ChampionshipScheduleNode.CreateView(self:isGuessType())
    self:addChild(self.viewData_.view)

    -- bind model
    self.mainProxy_ = app:RetrieveProxy(MAIN_PROXY_NAME)

    -- add listener
    if self:isGuessType() then
        self.viewBindMap_ = {
            [MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.PROMOTION_SCHEDULE.MATCH_DATA.ATTACKER_VOTE] = self.onUpdateVoteInfo_,
            [MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.PROMOTION_SCHEDULE.MATCH_DATA.DEFENDER_VOTE] = self.onUpdateVoteInfo_,
        }
        local handlerList = VoProxy.EventBind(MAIN_PROXY_NAME, self.viewBindMap_, self)
        table.each(handlerList, function(_, v) v(self) end)
    end

    ui.bindClick(self:getViewData().finalTypeTBtn, handler(self, self.onClickGroupButtonHandler_), false)
    for _, teamBtn in ipairs(self:getViewData().teamBtnList) do
        ui.bindClick(teamBtn, handler(self, self.onClickGroupButtonHandler_))
    end
    for roundNum, replayBtnList in ipairs(self:getViewData().groupPanelVD.replayBtnList) do
        for matchIndex, replayBtn in ipairs(replayBtnList) do
            ui.bindClick(replayBtn, handler(self, self.onClickReplayButtonHandler_))
        end
    end
    for roundNum, replayBtnList in ipairs(self:getViewData().finalPanelVD.replayBtnList) do
        for matchIndex, replayBtn in ipairs(replayBtnList) do
            ui.bindClick(replayBtn, handler(self, self.onClickReplayButtonHandler_))
        end
    end
    for roundNum, playerVDList in ipairs(self:getViewData().groupPanelVD.atkPlayerVDList) do
        for matchIndex, playerVD in ipairs(playerVDList) do
            ui.bindClick(playerVD.clickArea, handler(self, self.onClickAttackerCellHandler_))
        end
    end
    for roundNum, playerVDList in ipairs(self:getViewData().finalPanelVD.atkPlayerVDList) do
        for matchIndex, playerVD in ipairs(playerVDList) do
            ui.bindClick(playerVD.clickArea, handler(self, self.onClickAttackerCellHandler_))
        end
    end
    for roundNum, playerVDList in ipairs(self:getViewData().groupPanelVD.defPlayerVDList) do
        for matchIndex, playerVD in ipairs(playerVDList) do
            ui.bindClick(playerVD.clickArea, handler(self, self.onClickDefenerCellHandler_))
        end
    end
    for roundNum, playerVDList in ipairs(self:getViewData().finalPanelVD.defPlayerVDList) do
        for matchIndex, playerVD in ipairs(playerVDList) do
            ui.bindClick(playerVD.clickArea, handler(self, self.onClickDefenerCellHandler_))
        end
    end
    ui.bindClick(self:getViewData().finalPanelVD.groupWinnerVD.clickArea, handler(self, self.onClickWinnerCellHandler_))
    ui.bindClick(self:getViewData().groupPanelVD.groupWinnerVD.clickArea, handler(self, self.onClickWinnerCellHandler_))

    -- update views
    self:updateGroupGuessNum_()
    self:updateToScheduleStep()
end


function ChampionshipScheduleNode:release()
    if self.viewBindMap_ then
        VoProxy.EventUnbind(MAIN_PROXY_NAME, self.viewBindMap_, self)
    end
end


-------------------------------------------------
-- get / set

function ChampionshipScheduleNode:getViewData()
    return self.viewData_
end


function ChampionshipScheduleNode:isGuessType()
    return self.detailType_ == FOOD.CHAMPIONSHIP.PLAYER_DETAIL.TYPE.VOTE
end


function ChampionshipScheduleNode:getGroupIndex()
    return checkint(self.groupIndex_)
end
function ChampionshipScheduleNode:setGroupIndex(index)
    self.groupIndex_ = checkint(index)
    self:updateGroupBtns_()
    self:updateGroupPanel_()
end


-------------------------------------------------
-- public

function ChampionshipScheduleNode:updateToScheduleStep()
    local scheduleStep = self.mainProxy_:get(MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.SCHEDULE_STEP)
    local groupIndex   = self:calculateGroupIndex_(scheduleStep + (self:isGuessType() and 1 or 0))
    self:setGroupIndex(groupIndex)
end


-------------------------------------------------
-- private

function ChampionshipScheduleNode:calculateMatchId_(sender)
    local roundNumber   = checkint(sender.roundNumber)
    local matchIndex    = checkint(sender.matchIndex)
    local matchIdList   = FOOD.CHAMPIONSHIP.MATCH_ID[roundNumber] or {}
    local replayMatchId = 0
    if self:getGroupIndex() == 0 then
        replayMatchId = checkint(matchIdList[matchIndex])
    else
        local TEAM_SIZE  = 4
        local matchCount = checkint(#matchIdList / TEAM_SIZE)
        replayMatchId = checkint(matchIdList[matchIndex + (self:getGroupIndex()-1) * matchCount])
    end
    return replayMatchId
end


function ChampionshipScheduleNode:calculateGroupIndex_(stepId)
    local matchIndex = checkint(stepId)
    local groupIndex = checkint(FOOD.CHAMPIONSHIP.GROUP_MAP[matchIndex])
    return groupIndex
end


function ChampionshipScheduleNode:updateGroupBtns_()
    -- 0 is final
    if self:getGroupIndex() == 0 then
        self:getViewData().finalTypeTBtn:setChecked(true)
        self:getViewData().groupTypeTBtn:setChecked(false)
        self:getViewData().finalPanelVD.view:setVisible(true)
        self:getViewData().groupPanelVD.view:setVisible(false)
        self.currentPanelVD_ = self:getViewData().finalPanelVD
    else
        self:getViewData().finalTypeTBtn:setChecked(false)
        self:getViewData().groupTypeTBtn:setChecked(true)
        self:getViewData().finalPanelVD.view:setVisible(false)
        self:getViewData().groupPanelVD.view:setVisible(true)
        self.currentPanelVD_ = self:getViewData().groupPanelVD
    end

    for groupIndex, teamBtn in ipairs(self:getViewData().teamBtnList) do
        teamBtn.selectImg:setVisible(self:getGroupIndex() == groupIndex)
    end
end


function ChampionshipScheduleNode:updateGroupGuessNum_()
    local groupGuessMap = {}
    local GUESS_STRUCT  = MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.GUESS_DETAIL
    for matchIndex, _ in pairs(self.mainProxy_:get(GUESS_STRUCT):getData()) do
        local groupIndex = FOOD.CHAMPIONSHIP.GROUP_MAP[checkint(matchIndex)]
        groupGuessMap[tostring(groupIndex)] = checkint(groupGuessMap[tostring(groupIndex)]) + 1
    end

    local updateGuessNum = function(teamBtn, groupGuessNum)
        teamBtn.guessIcon:setVisible(groupGuessNum > 0)
        teamBtn.guessLabel:setVisible(groupGuessNum > 0)
        teamBtn.guessLabel:updateLabel({text = string.fmt('x%1', groupGuessNum)})
    end

    -- group A\B\C\D
    for groupIndex, teamBtn in ipairs(self:getViewData().teamBtnList) do
        local groupGuessNum = checkint(groupGuessMap[tostring(groupIndex)])
        updateGuessNum(teamBtn, groupGuessNum)
        
    end

    -- group final
    local groupGuessNum = checkint(groupGuessMap['0'])
    updateGuessNum(self:getViewData().finalTypeTBtn, groupGuessNum)
end


function ChampionshipScheduleNode:updateGroupPanel_()
    if self.currentPanelVD_ == nil then return end
    
    local nowRoundNum  = 0
    local scheduleStep = self.mainProxy_:get(MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.SCHEDULE_STEP)
    local isGameOver   = scheduleStep >= FOOD.CHAMPIONSHIP.STEP.OFF_SEASON
    if isGameOver then
        nowRoundNum = #FOOD.CHAMPIONSHIP.ROUND_NUM
    else
        for roundNum, stepDefine in ipairs(FOOD.CHAMPIONSHIP.ROUND_NUM) do
            local beganStep = checkint(stepDefine.beganStep)
            local endedStep = checkint(stepDefine.endedStep)
            if beganStep <= scheduleStep and scheduleStep <= endedStep then
                nowRoundNum = roundNum
                break
            end
        end
    end
    
    -- update all matchResault
    for roundNum, replayBtnList in ipairs(self.currentPanelVD_.replayBtnList) do
        for matchIndex, replayBtn in ipairs(replayBtnList) do
            self:updateMatchResault_(
                self.currentPanelVD_.replayBtnList[roundNum][matchIndex],
                self.currentPanelVD_.vsNormalImgList[roundNum][matchIndex],
                self.currentPanelVD_.vsDisableImgList[roundNum][matchIndex],
                nowRoundNum,
                scheduleStep
            )
        end
    end

    -- update all playerCell
    for roundNum, playerVDList in ipairs(self.currentPanelVD_.atkPlayerVDList) do
        for matchIndex, playerVD in ipairs(playerVDList) do
            self:updatePlayerCell_(playerVD, nowRoundNum, scheduleStep, 'atk')
        end
    end
    for roundNum, playerVDList in ipairs(self.currentPanelVD_.defPlayerVDList) do
        for matchIndex, playerVD in ipairs(playerVDList) do
            self:updatePlayerCell_(playerVD, nowRoundNum, scheduleStep, 'def')
        end
    end
    self:updatePlayerCell_(self.currentPanelVD_.groupWinnerVD, nowRoundNum, scheduleStep, 'win')
end


function ChampionshipScheduleNode:updateMatchResault_(replayBtn, vsNormalImg, vsDisableImg, nowRoundNum, scheduleStep)
    if replayBtn and  vsNormalImg and vsDisableImg then

        -- 回合未开始 : 空状态
        if checkint(nowRoundNum) < replayBtn.roundNumber then
            replayBtn:setVisible(false)
            vsNormalImg:setVisible(false)
            vsDisableImg:setVisible(false)

        else
            local replayMatchId = self:calculateMatchId_(replayBtn)
            local isResulted    = checkint(scheduleStep) >= replayMatchId
            if isResulted then
                -- 显示战果
                local isGameOver = scheduleStep >= FOOD.CHAMPIONSHIP.STEP.OFF_SEASON
                replayBtn:setVisible(not isGameOver)
                vsNormalImg:setVisible(false)
                vsDisableImg:setVisible(true)
            else
                -- 等待结果
                replayBtn:setVisible(false)
                vsNormalImg:setVisible(true)
                vsDisableImg:setVisible(false)
            end
        end

    end
end


function ChampionshipScheduleNode:updatePlayerCell_(playerCellVD, nowRoundNum, scheduleStep, sourceType)
    if playerCellVD == nil then return end

    local toEmptyStatue = function()
        playerCellVD.clickArea:setVisible(false)
        playerCellVD.lostMask:setVisible(false)
        playerCellVD.lostIcon:setVisible(false)
        playerCellVD.guessIcon:setVisible(false)
        playerCellVD.frameNormal:setVisible(false)
        playerCellVD.frameSelect:setVisible(false)
        playerCellVD.frameDisable:setVisible(false)
        playerCellVD.playerHeadNode:setVisible(false)
        playerCellVD.playerNameLabel:setVisible(false)
        playerCellVD.playerVoteLabel:setVisible(false)
    end

    -- 回合未开始 : 空状态
    if checkint(nowRoundNum) < playerCellVD.clickArea.roundNumber then
        toEmptyStatue()

    else
        
        -- schedule info
        local playerMatchId   = self:calculateMatchId_(playerCellVD.clickArea)
        local SCHEDULE_STRUCT = MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.PROMOTION_SCHEDULE
        local matchProxy      = self.mainProxy_:get(SCHEDULE_STRUCT.MATCH_DATA, tostring(playerMatchId))
        local winnerId        = matchProxy:get(SCHEDULE_STRUCT.MATCH_DATA.WINNER_ID)
        local attackerId      = matchProxy:get(SCHEDULE_STRUCT.MATCH_DATA.ATTACKER_ID)
        local defenderId      = matchProxy:get(SCHEDULE_STRUCT.MATCH_DATA.DEFENDER_ID)
        local attackerVote    = matchProxy:get(SCHEDULE_STRUCT.MATCH_DATA.ATTACKER_VOTE)
        local defenderVote    = matchProxy:get(SCHEDULE_STRUCT.MATCH_DATA.DEFENDER_VOTE)
        local roundNumber     = checkint(playerCellVD.clickArea.roundNumber)

        -- player info
        local playerId   = 0
        local playerVote = 0
        local isEmptyTop = false
        local isResulted = checkint(scheduleStep) >= playerMatchId
        local voteColor  = isResulted and '#E1CDB8' or '#DB7109'
        local isTopCell  = false
        if sourceType == 'atk' then
            playerId   = attackerId
            playerVote = attackerVote
        elseif sourceType == 'def' then
            playerId   = defenderId
            playerVote = defenderVote
        elseif sourceType == 'win' then
            isTopCell  = true
            playerId   = isResulted and winnerId or 0  -- winner must need result
            playerVote = winnerId == attackerId and attackerVote or defenderVote
        end

        local hasPlayer = playerId > 0
        if isTopCell and hasPlayer == false and isResulted == false then
            toEmptyStatue()
        else
            local PLAYERS_STRUCT = MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.PROMOTION_PLAYERS
            local playerProxy    = self.mainProxy_:get(PLAYERS_STRUCT.PLAYER_DATA, tostring(playerId))
            local playerAvatar   = playerProxy:get(PLAYERS_STRUCT.PLAYER_DATA.AVATAR)
            local playerFrame    = playerProxy:get(PLAYERS_STRUCT.PLAYER_DATA.FRAME)
            local playerLevel    = playerProxy:get(PLAYERS_STRUCT.PLAYER_DATA.LEVEL)
            local team1Power     = playerProxy:get(PLAYERS_STRUCT.PLAYER_DATA.POWER1)
            local isShowPlayer   = hasPlayer and (team1Power > 0 or roundNumber == 1)
            local playerName     = isShowPlayer and playerProxy:get(PLAYERS_STRUCT.PLAYER_DATA.NAME) or __('已弃权')
            playerCellVD.frameNormal:setVisible(not isResulted)
            playerCellVD.clickArea:setVisible(true)
            playerCellVD.playerHeadNode:setVisible(true)
            playerCellVD.playerNameLabel:setVisible(true)
            playerCellVD.playerVoteLabel:setVisible(isShowPlayer)
            playerCellVD.playerVoteLabel:updateLabel({text = string.fmt(__('票数：_num_'), {_num_ = playerVote}), color = voteColor})
            playerCellVD.playerNameLabel:updateLabel({maxW = playerCellVD.playerNameLabel.maxW, text = playerName, color = '#67402D'})
            playerCellVD.playerHeadNode:RefreshUI({
                playerId    = playerId,
                avatar      = isShowPlayer and playerAvatar or 500375,
                avatarFrame = isShowPlayer and playerFrame or 0,
                playerLevel = isShowPlayer and playerLevel or 0
            })
    
            local GUESS_STRUCT   = MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.GUESS_DETAIL
            local guessDataProxy = self.mainProxy_:get(GUESS_STRUCT.GUESS_DATA, tostring(playerMatchId))
            local guessPlayerId  = guessDataProxy:get(GUESS_STRUCT.GUESS_DATA.PLAYER_ID)
            if self:isGuessType() and guessPlayerId > 0 then
                playerCellVD.guessIcon:setVisible(isTopCell == false and playerId == guessPlayerId)
            else
                playerCellVD.guessIcon:setVisible(false)
            end
    
            -- 场次已结束 : 显示结果
            if isResulted then
                local isWinner = playerId > 0 and playerId == winnerId
                playerCellVD.lostMask:setVisible(not isWinner)
                playerCellVD.lostIcon:setVisible(not isWinner)
                playerCellVD.frameDisable:setVisible(isWinner)
                playerCellVD.playerNameLabel:setColor(ccc3FromInt(isWinner and '#67402D' or '#CCA18E'))
                if self:isGuessType() then
                    playerCellVD.frameSelect:setVisible(false)
                else
                    playerCellVD.frameSelect:setVisible(isTopCell == false and scheduleStep == playerMatchId)
                end
                
            -- 场次未开始 : 等待状态
            else
                playerCellVD.lostMask:setVisible(false)
                playerCellVD.lostIcon:setVisible(false)
                playerCellVD.frameDisable:setVisible(false)
                if self:isGuessType() then
                    playerCellVD.frameSelect:setVisible(isTopCell == false and (scheduleStep+1) == playerMatchId)
                else
                    playerCellVD.frameSelect:setVisible(false)
                end
            end
        end

    end
end


-------------------------------------------------
-- handler

function ChampionshipScheduleNode:onCleanup()
    self:release()
end


function ChampionshipScheduleNode:onUpdateVoteInfo_(signal)
    if not self:getActionByTag(ACTION_ENUM.RELOAD_PLAYER_VOTE) then
        self:runAction(cc.CallFunc:create(function()

            self:updateGroupPanel_()
            self:updateGroupGuessNum_()

        end)):setTag(ACTION_ENUM.RELOAD_PLAYER_VOTE)
    end
end


function ChampionshipScheduleNode:onClickGroupButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local groupIndex = checkint(sender:getTag())
    self:setGroupIndex(groupIndex)
end


function ChampionshipScheduleNode:onClickReplayButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local matchId         = self:calculateMatchId_(sender)
    local SCHEDULE_STRUCT = MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.PROMOTION_SCHEDULE
    local dataProxy       = self.mainProxy_:get(SCHEDULE_STRUCT.MATCH_DATA, tostring(matchId))
    local attackerId      = dataProxy:get(SCHEDULE_STRUCT.MATCH_DATA.ATTACKER_ID)
    local defenderId      = dataProxy:get(SCHEDULE_STRUCT.MATCH_DATA.DEFENDER_ID)
    local PLAYERS_STRUCT  = MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.PROMOTION_PLAYERS
    local attackerProxy   = self.mainProxy_:get(PLAYERS_STRUCT.PLAYER_DATA, tostring(attackerId))
    local defenderProxy   = self.mainProxy_:get(PLAYERS_STRUCT.PLAYER_DATA, tostring(defenderId))
    local atkTeam1Power   = attackerProxy:get(PLAYERS_STRUCT.PLAYER_DATA.POWER1)
    local defTeam1Power   = defenderProxy:get(PLAYERS_STRUCT.PLAYER_DATA.POWER1)
    if attackerId > 0 and defenderId > 0 and atkTeam1Power > 0 and defTeam1Power > 0 then
        local replayMdt = require('Game.mediator.championship.ChampionshipReplayMediator').new({matchId = matchId})
        app:RegistMediator(replayMdt)
    else
        app.uiMgr:ShowInformationTips(__('有选手放弃了比赛，无法回看'))
    end
end


function ChampionshipScheduleNode:onClickAttackerCellHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local replayMatchId   = self:calculateMatchId_(sender)
    local SCHEDULE_STRUCT = MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.PROMOTION_SCHEDULE
    local matchDataProxy  = self.mainProxy_:get(SCHEDULE_STRUCT.MATCH_DATA, tostring(replayMatchId))
    local matchAttackerId = matchDataProxy:get(SCHEDULE_STRUCT.MATCH_DATA.ATTACKER_ID)
    local PLAYERS_STRUCT  = MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.PROMOTION_PLAYERS
    local playerProxy     = self.mainProxy_:get(PLAYERS_STRUCT.PLAYER_DATA, tostring(matchAttackerId))
    local team1Power      = playerProxy:get(PLAYERS_STRUCT.PLAYER_DATA.POWER1)
    if matchAttackerId > 0 and team1Power > 0 then
        local playerDetailMdt = require('Game.mediator.championship.ChampionshipPlayerDetailMediator').new({
            detailType = self.detailType_,
            matchId    = replayMatchId,
            playerId   = matchAttackerId,
        })
        app:RegistMediator(playerDetailMdt)
    else
        app.uiMgr:ShowInformationTips(__('该选手放弃了比赛'))
    end
end


function ChampionshipScheduleNode:onClickDefenerCellHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local replayMatchId   = self:calculateMatchId_(sender)
    local SCHEDULE_STRUCT = MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.PROMOTION_SCHEDULE
    local matchDataProxy  = self.mainProxy_:get(SCHEDULE_STRUCT.MATCH_DATA, tostring(replayMatchId))
    local matchDefenderId = matchDataProxy:get(SCHEDULE_STRUCT.MATCH_DATA.DEFENDER_ID)
    local PLAYERS_STRUCT  = MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.PROMOTION_PLAYERS
    local playerProxy     = self.mainProxy_:get(PLAYERS_STRUCT.PLAYER_DATA, tostring(matchDefenderId))
    local team1Power      = playerProxy:get(PLAYERS_STRUCT.PLAYER_DATA.POWER1)
    if matchDefenderId > 0 and team1Power > 0 then
        local playerDetailMdt = require('Game.mediator.championship.ChampionshipPlayerDetailMediator').new({
            detailType = self.detailType_,
            matchId    = replayMatchId,
            playerId   = matchDefenderId,
        })
        app:RegistMediator(playerDetailMdt)
    else
        app.uiMgr:ShowInformationTips(__('该选手放弃了比赛'))
    end
end


function ChampionshipScheduleNode:onClickWinnerCellHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local replayMatchId   = self:calculateMatchId_(sender)
    local SCHEDULE_STRUCT = MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.PROMOTION_SCHEDULE
    local matchDataProxy  = self.mainProxy_:get(SCHEDULE_STRUCT.MATCH_DATA, tostring(replayMatchId))
    local matchWinnerId   = matchDataProxy:get(SCHEDULE_STRUCT.MATCH_DATA.WINNER_ID)
    local PLAYERS_STRUCT  = MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.PROMOTION_PLAYERS
    local playerProxy     = self.mainProxy_:get(PLAYERS_STRUCT.PLAYER_DATA, tostring(matchWinnerId))
    local team1Power      = playerProxy:get(PLAYERS_STRUCT.PLAYER_DATA.POWER1)
    if matchWinnerId > 0 and team1Power > 0 then
        local playerDetailMdt = require('Game.mediator.championship.ChampionshipPlayerDetailMediator').new({
            detailType = FOOD.CHAMPIONSHIP.PLAYER_DETAIL.TYPE.VIEW,
            matchId    = replayMatchId,
            playerId   = matchWinnerId,
        })
        app:RegistMediator(playerDetailMdt)
    else
        app.uiMgr:ShowInformationTips(__('该选手放弃了比赛'))
    end
end


-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function ChampionshipScheduleNode.CreateView(isGuess)
    local view = ui.layer()
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    -- bg [img | black | block]
    local backGroundGroup = view:addList({
        ui.image({img = RES_DICT.BG_IMAGE, p = cpos}),
        ui.layer({color = cc.r4b(0), enable = true}),
        ui.spine({path = RES_DICT.FIRE_SPINE, init = 'budo_vs_fire', p = cpos}),
    })


    ------------------------------------------------- [center]
    local centerLayer = ui.layer()
    view:add(centerLayer)

    -- panel [final | group]
    local finalPanelVD = ChampionshipScheduleNode.CreateGroupPanel(true)
    local groupPanelVD = ChampionshipScheduleNode.CreateGroupPanel(false)
    centerLayer:add(finalPanelVD.view)
    centerLayer:add(groupPanelVD.view)
    

    ------------------------------------------------- [top]
    local topLayer = ui.layer()
    view:add(topLayer)

    -- title bar
    local titleText = isGuess and __('为选手投票吧') or __('查看赛程')
    local titleBar  = ui.title({img = RES_DICT.TITLE_FRAME}):updateLabel({fnt = FONT.D14, color = '#F0EAC3', offset = cc.p(0, 30), text = titleText})
    topLayer:addList(titleBar):alignTo(nil, ui.ct)


    ------------------------------------------------- [left]
    local leftLayer = ui.layer()
    view:add(leftLayer)

    -- type group
    local typeGroup = leftLayer:addList({
        ui.tButton({n = RES_DICT.TYPE_BTN_N, zorder = 1, s = RES_DICT.TYPE_BTN_S, ml = -15, tag = 0}),
        ui.tButton({n = RES_DICT.TYPE_BTN_N, zorder = 1, s = RES_DICT.TYPE_BTN_S, ml = -15, enable = false}),
        ui.layer({bg = RES_DICT.TEAM_FRAME, mt = -10}),
    })
    ui.flowLayout(cc.rep(cc.sizep(size, ui.lt), display.SAFE_L - 50, -170), typeGroup, {type = ui.flowV, ap = ui.lb})
    
    local finalTypeTBtn = typeGroup[1]
    finalTypeTBtn:addList(ui.label({fnt = FONT.D19, fontSize = 24, text = __('决赛')})):alignTo(nil, ui.cc, {offsetX = 15})
    finalTypeTBtn.guessIcon  = finalTypeTBtn:addList(ui.image({img = RES_DICT.GUESS_ICON, scale = 0.7})):alignTo(nil, ui.cc, {offsetX = 70})
    finalTypeTBtn.guessLabel = finalTypeTBtn:addList(ui.label({fnt = FONT.D19, fontSize = 18, ap = ui.lt})):alignTo(nil, ui.cc, {offsetX = 70})
    

    local groupTypeTBtn = typeGroup[2]
    groupTypeTBtn:addList(ui.label({fnt = FONT.D19, fontSize = 24, text = __('小组赛')})):alignTo(nil, ui.cc, {offsetX = 15})


    -- team group
    local teamDefines = {
        {text = __('A组'), group = 1},
        {text = __('B组'), group = 2},
        {text = __('C组'), group = 3},
        {text = __('D组'), group = 4},
    }
    local teamLayer = typeGroup[3]
    local teamGroup = teamLayer:addList({
        ChampionshipScheduleNode.CreateTeamButton(teamDefines[1]),
        ui.image({img = RES_DICT.TEAM_CLINE}),
        ChampionshipScheduleNode.CreateTeamButton(teamDefines[2]),
        ui.image({img = RES_DICT.TEAM_CLINE}),
        ChampionshipScheduleNode.CreateTeamButton(teamDefines[3]),
        ui.image({img = RES_DICT.TEAM_CLINE}),
        ChampionshipScheduleNode.CreateTeamButton(teamDefines[4]),
    })
    ui.flowLayout(cc.sizep(teamLayer, ui.cc), teamGroup, {type = ui.flowV, ap = ui.cc})


    return {
        view          = view,
        --            = top
        titleBar      = titleBar,
        --            = left
        finalTypeTBtn = finalTypeTBtn,
        groupTypeTBtn = groupTypeTBtn,
        teamBtnList   = { teamGroup[1], teamGroup[3], teamGroup[5], teamGroup[7] },
        --            = center
        finalPanelVD  = finalPanelVD,
        groupPanelVD  = groupPanelVD,
    }
end


function ChampionshipScheduleNode.CreateTeamButton(teamDefine)
    local btnSize   = cc.size(160, 55)
    local teamBtn   = ui.layer({size = btnSize, color = cc.r4b(0), enable = true})
    local viewGroup = teamBtn:addList({
        ui.image({img = RES_DICT.TEAM_BTN_S}),
        ui.label({fnt = FONT.D14, color = '#D3C2AE', outline = '#450B08', text = checkstr(teamDefine.text), ml = 10}),
        ui.image({img = RES_DICT.GUESS_ICON, scale = 0.7, ml = 55}),
        ui.label({fnt = FONT.D19, fontSize = 18, ap = ui.lt, ml = 55}),
    })
    ui.flowLayout(cc.sizep(btnSize, ui.cc), viewGroup, {type = ui.flowC, ap = ui.cc})

    teamBtn:setTag(checkint(teamDefine.group))
    teamBtn.selectImg  = viewGroup[1]
    teamBtn.textLabel  = viewGroup[2]
    teamBtn.guessIcon  = viewGroup[3]
    teamBtn.guessLabel = viewGroup[4]
    return teamBtn
end


function ChampionshipScheduleNode.CreatePlayerCell(isFinal, isTop, roundNumber, matchIndex)
    local size = isFinal and cc.size(270, 120) or cc.size(140, 160)
    local view = ui.layer({size = size, ap = ui.cc})
    local cpos = cc.sizep(size, ui.cc)
    if isFinal and isTop then
        view:setScale(1.3)
    end

    -- center [frame | select | disable | normal | head | name | vote | mask | lost | top | guess]
    local frameImgKey = string.fmt('%1_FRAME_R%2', isFinal and 'FINAL' or 'GROUP', isTop and 0 or roundNumber)
    local centerGroup = view:addList({
        ui.image({img = RES_DICT[frameImgKey]}),
        ui.image({img = isFinal and RES_DICT.FINAL_PLAYER_S or RES_DICT.GROUP_PLAYER_S}),
        ui.image({img = isFinal and RES_DICT.FINAL_PLAYER_D or RES_DICT.GROUP_PLAYER_D}),
        ui.image({img = isFinal and RES_DICT.FINAL_PLAYER_N or RES_DICT.GROUP_PLAYER_N}),
        ui.playerHeadNode({scale = 0.6, mb = isFinal and 0 or 25, mr = isFinal and 75 or 0}),
        ui.label({fnt = FONT.D5, color = '#67402D', ap = isFinal and ui.lc or ui.cc, mt = isFinal and -20 or 40, mr = isFinal and 20 or 0}),
        ui.label({fnt = FONT.D8, color = '#DB7109', ap = isFinal and ui.lc or ui.cc, mt = isFinal and 20 or 65, mr = isFinal and 20 or 0}),
        ui.image({img = isFinal and RES_DICT.FINAL_FRAME_D or RES_DICT.GROUP_FRAME_D, alpha = 150}),
        ui.image({img = RES_DICT.LOST_ICON, mb = isFinal and 0 or 20, mr = isFinal and 75 or 0}),
        ui.image({img = RES_DICT.TOP_WINNER_ICON, mr = cpos.x, mb = cpos.y}),
        ui.image({img = RES_DICT.GUESS_ICON, mr = cpos.x - 10, mb = cpos.y - 10}),
    })
    ui.flowLayout(cpos, centerGroup, {type = ui.flowC, ap = ui.cc})

    local playerNameLabel = centerGroup[6]
    playerNameLabel.maxW = size.width - (isFinal and 120 or 20)

    local winnerIcon = centerGroup[10]
    winnerIcon:setVisible(isTop)
    
    -- clickArea
    local clickArea = ui.layer({size = size, color = cc.r4b(0), enable = true})
    clickArea.roundNumber = checkint(roundNumber)
    clickArea.matchIndex  = checkint(matchIndex)
    view:add(clickArea)

    return {
        view            = view,
        clickArea       = clickArea,
        frameSelect     = centerGroup[2],
        frameDisable    = centerGroup[3],
        frameNormal     = centerGroup[4],
        playerHeadNode  = centerGroup[5],
        playerNameLabel = playerNameLabel,
        playerVoteLabel = centerGroup[7],
        lostMask        = centerGroup[8],
        lostIcon        = centerGroup[9],
        guessIcon       = centerGroup[11],
    }
end


function ChampionshipScheduleNode.CreateGroupPanel(isFinal)
    local view = ui.layer()
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)
    
    local replayBtnList    = {}
    local vsNormalImgList  = {}
    local vsDisableImgList = {}
    local atkPlayerVDList  = {}
    local defPlayerVDList  = {}
    local BASE_PLAYER_POS  = cc.rep(cpos, 0, 0)
    local ROUND_GAP_LIST   = {}
    local MATCH_GAP_LIST   = {}

    if isFinal then
        ROUND_GAP_LIST = {
            {w = 675, h = -120, offList = { cc.p(-45,0), cc.p(45,0) }},
            {w =   0, h = -120},
            {w =   0, h = 180},
        }
        MATCH_GAP_LIST = {
            {w =   0, h = 320},
            {w = 360, h = 0},
            {w =   0, h = 0},
        }
    else
        ROUND_GAP_LIST = {
            {w = 310, h = -280},
            {w = 620, h = -90},
            {w =   0, h = 65},
            {w =   0, h = 190},
        }
        MATCH_GAP_LIST = {
            {w = 155, h = 0},
            {w = 310, h = 0},
            {w = 620, h = 0},
            {w =   0, h = 0},
        }
    end

    -- match line
    local matchLinePos = cc.rep(BASE_PLAYER_POS, 0, -80)
    view:add(ui.image({img = isFinal and RES_DICT.MATCH_FINAL or RES_DICT.MATCH_GROUP, p = matchLinePos}))
    
    -- match views
    local TEAM_SIZE = 4
    local ROUND_MAX = isFinal and 2 or 3
    local ROUND_IDX = isFinal and #FOOD.CHAMPIONSHIP.MATCH_ID - ROUND_MAX or 0
    for roundNum = 1, ROUND_MAX do
        local replayList = {}
        local vsNormalList  = {}
        local vsDisableList = {}
        local atkRoundList  = {}
        local defRoundList  = {}
        local matchIdList   = FOOD.CHAMPIONSHIP.MATCH_ID[ROUND_IDX + roundNum] or {}
        local matchCount    = isFinal and #matchIdList or checkint(#matchIdList / TEAM_SIZE)
        local roundNumber   = ROUND_IDX + roundNum
        for matchIndex = 1, matchCount do

            -- playerCell [atk | def]
            local atkPlayerCellVD    = ChampionshipScheduleNode.CreatePlayerCell(isFinal, false, roundNumber, matchIndex)
            local defPlayerCellVD    = ChampionshipScheduleNode.CreatePlayerCell(isFinal, false, roundNumber, matchIndex)
            atkRoundList[matchIndex] = atkPlayerCellVD
            defRoundList[matchIndex] = defPlayerCellVD
            view:add(atkPlayerCellVD.view)
            view:add(defPlayerCellVD.view)

            local roundOffX = (matchCount/2-0.5) * ROUND_GAP_LIST[roundNum].w
            local roundPosX = BASE_PLAYER_POS.x - roundOffX + (matchIndex-1) * ROUND_GAP_LIST[roundNum].w
            local roundPosY = BASE_PLAYER_POS.y + ROUND_GAP_LIST[roundNum].h
            local matchGapW = MATCH_GAP_LIST[roundNum].w / 2
            local matchGapH = MATCH_GAP_LIST[roundNum].h / 2
            atkPlayerCellVD.view:setPosition(roundPosX - matchGapW, roundPosY + matchGapH)
            defPlayerCellVD.view:setPosition(roundPosX + matchGapW, roundPosY - matchGapH)
            atkPlayerCellVD.view:setLocalZOrder(ROUND_MAX - roundNum)
            defPlayerCellVD.view:setLocalZOrder(ROUND_MAX - roundNum)

            -- center [normalVs | disableVs | replayBtn]
            local centerOffPos = checktable(ROUND_GAP_LIST[roundNum].offList)[matchIndex] or PointZero
            local centerGroup   = view:addList({
                ui.image({img = RES_DICT.VS_ICON_N, zorder = ROUND_MAX}),
                ui.image({img = RES_DICT.VS_ICON_D, zorder = ROUND_MAX}),
                ui.button({n = RES_DICT.REPLAY_BTN, zorder = ROUND_MAX}),
            })
            ui.flowLayout(cc.p(roundPosX + centerOffPos.x, roundPosY + centerOffPos.y), centerGroup, {type = ui.flowC, ap = ui.cc})
            vsNormalList[matchIndex]  = centerGroup[1]
            vsDisableList[matchIndex] = centerGroup[2]
            replayList[matchIndex]    = centerGroup[3]

            local replayBtn       = centerGroup[3]
            replayBtn.roundNumber = roundNumber
            replayBtn.matchIndex  = matchIndex
            
        end
        replayBtnList[roundNum]    = replayList
        vsNormalImgList[roundNum]  = vsNormalList
        vsDisableImgList[roundNum] = vsDisableList
        atkPlayerVDList[roundNum]  = atkRoundList
        defPlayerVDList[roundNum]  = defRoundList
    end

    -- groupWinner
    local groupWinnerX  = BASE_PLAYER_POS.x
    local groupWinnerY  = BASE_PLAYER_POS.y + ROUND_GAP_LIST[ROUND_MAX + 1].h
    local groupWinnerVD = ChampionshipScheduleNode.CreatePlayerCell(isFinal, true, ROUND_IDX + ROUND_MAX, 1)
    groupWinnerVD.view:setPosition(groupWinnerX, groupWinnerY)
    view:add(groupWinnerVD.view)

    return {
        view             = view,
        replayBtnList    = replayBtnList,
        vsNormalImgList  = vsNormalImgList,
        vsDisableImgList = vsDisableImgList,
        atkPlayerVDList  = atkPlayerVDList,
        defPlayerVDList  = defPlayerVDList,
        groupWinnerVD    = groupWinnerVD,
    }
end


return ChampionshipScheduleNode
