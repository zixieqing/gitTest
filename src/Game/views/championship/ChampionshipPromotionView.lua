--[[
 * author : kaishiqi
 * descpt : 武道会 - 晋级赛视图
]]
local ChampionshipPromotionView = class('ChampionshipPromotionView', function()
    return ui.layer({name = 'Game.views.championship.ChampionshipPromotionView', enableEvent = true})
end)

local RES_DICT = {
    --                  = top
    CEILING_FRAME       = _res('ui/championship/auditions/budo_bg_common_top_head.png'),
    COUNTDOWN_BAR       = _res('ui/championship/auditions/budo_pvp_bg_reward_number_2.png'),
    --                  = center
    MATCH_TABLE         = _res('ui/championship/auditions/budo_bg_common_spine_table.png'),
    MATCH_VS            = _res('ui/championship/auditions/starplan_vs_icon_vs.png'),
    PLATE_BLUE          = _res('ui/championship/auditions/budo_sea_bg_base_blue.png'),
    PLATE_RED           = _res('ui/championship/auditions/budo_sea_bg_base_red.png'),
    EDIT_TEAM           = _res('ui/championship/auditions/budo_sea_btn_add_ren.png'),
    OPPONENT_LIGHT      = _res('ui/championship/promotion/tower_prepare_bg_light.png'),
    OPPONENT_UNKNOW     = _res('ui/championship/promotion/pvp_main_ico_base_unknow.png'),
    OPPONENT_CARD       = _res('ui/championship/promotion/budo_pvp_bg_opponent.png'),
    OPPONENT_CHECK      = _res('ui/championship/promotion/budo_pvp_btn_opponent.png'),
    FUNCITON_FRAME      = _res('ui/championship/auditions/budo_bg_common_list.png'),
    SCHEDULE_BTN        = _res('ui/championship/promotion/budo_ico_common_record.png'),
    REWARD_BTN          = _res('ui/championship/auditions/budo_ico_common_reward.png'),
    SHOP_BTN            = _res('ui/championship/auditions/budo_ico_common_shop.png'),
    BOTTOM_DEC_BAR      = _res('ui/championship/promotion/budo_pvp_bg_bottom_middle.png'),
    APPLY_FRAME         = _res('ui/championship/promotion/budo_pvp_bg_bottom_right.png'),
    APPLY_BTN           = _res('ui/championship/promotion/budo_pvp_btn_sign.png'),
    --                  = left
    PLAYER_INFO_FRAME   = _res('ui/championship/promotion/budo_pvp_bg_team_message.png'),
    PLAYER_TEAM_FRAME   = _res('ui/championship/promotion/budo_pvp_bg_team_bule.png'),
    --                  = right
    REPORT_TITLE        = _res('ui/championship/history/budo_close_bg_reward_list_head.png'),
    REPORT_FRAME        = _res('ui/championship/promotion/budo_pvp_bg_reward.png'),
    REPORT_REWARD_BG    = _res('ui/championship/promotion/budo_pvp_bg_reward_small.png'),
    REPORT_REWARD_LINE  = _res('ui/championship/promotion/budo_pvp_line_reward_small.png'),
    REPORT_REWARD_TITLE = _res('ui/championship/promotion/budo_pvp_bg_reward_number.png'),
    REPORT_BTN          = _res('ui/common/common_btn_orange.png'),
    OPPONENT_TEAM_FRAME = _res('ui/championship/promotion/budo_pvp_bg_team_red.png'),
    --                  = team
    LEADER_ICON         = _res('ui/championship/auditions/team_ico_captain.png'),
    TEAM_FRAME          = _res('ui/tagMatch/3v3_ranks_bg.png'),
}

local ACTION_ENUM = {
    RELOAD_PROMOTION_TEAM  = 1,
    RELOAD_PROMOTION_STATE = 2,
}

local PLAYER_AREA = {
    EDIT_TEAM = 1,  -- 编队报名
    SHOW_TEAM = 2,  -- 编队展示
}

local RESULT_AREA = {
    OPPONENT_UNKNOW = 1,  -- 对手问号
    OPPONENT_SHOW   = 2,  -- 对手头像
    REPORT_WIN      = 3,  -- 胜利报告
    REPORT_OUT      = 4,  -- 失败报告
}

local MAIN_PROXY_NAME   = FOOD.CHAMPIONSHIP.MAIN.PROXY_NAME
local MAIN_PROXY_STRUCT = FOOD.CHAMPIONSHIP.MAIN.PROXY_STRUCT


function ChampionshipPromotionView:ctor(args)
    -- create view
    self.viewData_ = ChampionshipPromotionView.CreateView()
    self:addChild(self.viewData_.view)

    self.opponentVD_ = ChampionshipPromotionView.CreateOpponentView()
    self:addChild(self.opponentVD_.view)

    -- bind model
    self.mainProxy_   = app:RetrieveProxy(MAIN_PROXY_NAME)
    self.viewBindMap_ = {
        [MAIN_PROXY_STRUCT.MAIN_HOME_TAKE]                 = self.onUpdateHomeData_,
        [MAIN_PROXY_STRUCT.REFRESH_COUNTDOWN]              = self.onUpdateRefreshTime_,
        [MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.SCHEDULE_STEP]   = self.onUpdateScheduleStep_,
        [MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.PROMOTION_TEAM1] = self.onUpdatePromotionTeam_, -- clean all / update all
        [MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.PROMOTION_TEAM2] = self.onUpdatePromotionTeam_, -- clean all / update all
        [MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.PROMOTION_TEAM3] = self.onUpdatePromotionTeam_, -- clean all / update all
    }

    -- update view
    local handlerList = VoProxy.EventBind(MAIN_PROXY_NAME, self.viewBindMap_, self)
    table.each(handlerList, function(_, v) v(self) end)
    self:updatePlayerAreaState_()
    self:updateReportAreaState_()
    self:updateSeasonTitle_()
    self:hideOpponentTeam()
end


function ChampionshipPromotionView:onCleanup()
    VoProxy.EventUnbind(MAIN_PROXY_NAME, self.viewBindMap_, self)
end


function ChampionshipPromotionView:getViewData()
    return self.viewData_
end
function ChampionshipPromotionView:getOpponentVD()
    return self.opponentVD_
end


-------------------------------------------------
-- private

function ChampionshipPromotionView:updateSeasonTitle_()
    local seasonId   = self.mainProxy_:get(MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.SEASON_ID)
    local seasonText = string.fmt(__('第_num_届凌云争锋'), {_num_ = seasonId - (FOOD.CHAMPIONSHIP.IS_XIAOBO_FIX() and 1 or 0)})
    self:getViewData().seasonLabel:updateLabel({text = seasonText})
end


function ChampionshipPromotionView:updatePlayerAreaState_(state)
    if state == PLAYER_AREA.EDIT_TEAM then
        self:getViewData().applyLayer:setVisible(true)
        self:getViewData().playerLayer:setVisible(false)
        
    elseif state == PLAYER_AREA.SHOW_TEAM then
        self:getViewData().applyLayer:setVisible(false)
        self:getViewData().playerLayer:setVisible(true)
        
    else
        self:getViewData().applyLayer:setVisible(false)
        self:getViewData().playerLayer:setVisible(false)
    end
end


function ChampionshipPromotionView:updateReportAreaState_(state)
    if state == RESULT_AREA.OPPONENT_UNKNOW then
        self:getViewData().vsImg:setVisible(true)
        self:getViewData().opponentLayer:setVisible(true)
        self:getViewData().outReportLayer:setVisible(false)
        self:getViewData().winReportLayer:setVisible(false)
        self:getViewData().opponentUnknowImg:setVisible(true)
        self:getViewData().opponetPlayerLayer:setVisible(false)
        
    elseif state == RESULT_AREA.OPPONENT_SHOW then
        self:getViewData().vsImg:setVisible(true)
        self:getViewData().opponentLayer:setVisible(true)
        self:getViewData().outReportLayer:setVisible(false)
        self:getViewData().winReportLayer:setVisible(false)
        self:getViewData().opponentUnknowImg:setVisible(false)
        self:getViewData().opponetPlayerLayer:setVisible(true)
        self:updateOpponetHeadInfo_()
        
        
    elseif state == RESULT_AREA.REPORT_WIN then
        self:getViewData().vsImg:setVisible(false)
        self:getViewData().opponentLayer:setVisible(false)
        self:getViewData().outReportLayer:setVisible(false)
        self:getViewData().winReportLayer:setVisible(true)
        self:getViewData().opponentUnknowImg:setVisible(false)
        self:getViewData().opponetPlayerLayer:setVisible(false)
        
    elseif state == RESULT_AREA.REPORT_OUT then
        self:getViewData().vsImg:setVisible(false)
        self:getViewData().opponentLayer:setVisible(false)
        self:getViewData().outReportLayer:setVisible(true)
        self:getViewData().winReportLayer:setVisible(false)
        self:getViewData().opponentUnknowImg:setVisible(false)
        self:getViewData().opponetPlayerLayer:setVisible(false)
        self:updateOutReportInfo_()

    else
        self:getViewData().vsImg:setVisible(true)
        self:getViewData().opponentLayer:setVisible(false)
        self:getViewData().outReportLayer:setVisible(false)
        self:getViewData().winReportLayer:setVisible(false)
        self:getViewData().opponentUnknowImg:setVisible(false)
        self:getViewData().opponetPlayerLayer:setVisible(false)
    end

    if state ~= RESULT_AREA.OPPONENT_SHOW then
        self:hideOpponentTeam()
    end
end
function ChampionshipPromotionView:updateOutReportInfo_()
    local myRankRange   = 0
    local myLastMatchId = FOOD.CHAMPIONSHIP.LAST_MATCH_ID
    
    local MY_MATCHS_STRUCT = MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.PROMOTION_MATCHES
    local PLAYERS_STRUCT   = MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.PROMOTION_PLAYERS
    local playerProxy      = self.mainProxy_:get(PLAYERS_STRUCT.PLAYER_DATA, tostring(app.gameMgr:GetPlayerId()))
    local team1Power       = playerProxy:get(PLAYERS_STRUCT.PLAYER_DATA.POWER1)
    if team1Power > 0 then
        for _, matchId in pairs(self.mainProxy_:get(MY_MATCHS_STRUCT):getData()) do
            local tempMatchId = self.mainProxy_:get(MY_MATCHS_STRUCT.MATCH_ID, tostring(matchId))
            myLastMatchId = math.max(myLastMatchId, tempMatchId)
        end
    end

    -- update rankLabel
    for roundNum, matchIdList in ipairs(FOOD.CHAMPIONSHIP.MATCH_ID) do
        local beganStep = checkint(matchIdList[1])
        local endedStep = checkint(matchIdList[#matchIdList])
        if beganStep <= myLastMatchId and myLastMatchId <= endedStep then
            myRankRange = #matchIdList * 2 -- 因为是输了，所以数量*2表示向下一级
            self:getViewData().outRankLabel:updateLabel({text = string.fmt(__('排名：前_num_强'), {_num_ = myRankRange})})
            break
        end
    end
    
    -- update rankRewards
    self:getViewData().outRewardsLayer:removeAllChildren()
    for _, rewardsConf in pairs(CONF.CHAMPIONSHIP.KNOCKOUT_REWARD:GetAll()) do
        if checkint(rewardsConf.lower) >= myRankRange and myRankRange >= checkint(rewardsConf.upper) then
            local goodsIconList = {}
            for goodsIndex, goodsData in ipairs(rewardsConf.rewards or {}) do
                goodsIconList[goodsIndex] = ui.goodsNode({goodsId = goodsData.goodsId, num = goodsData.num, defaultCB = true, showAmount = true})
            end
            self:getViewData().outRewardsLayer:addList(goodsIconList)
            ui.flowLayout(cc.sizep(self:getViewData().outRewardsLayer, ui.cc), goodsIconList, {type = ui.flowH, ap = ui.cc, gapW = 15})
            break
        end
    end
end
function ChampionshipPromotionView:updateOpponetHeadInfo_()
    -- find currentRoundNum
    local currentMatchId   = 0
    local currentRoundNum  = 0
    local currentBeganStep = 0
    local currentEndedStep = 0
    local scheduleStep     = self.mainProxy_:get(MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.SCHEDULE_STEP)
    local SCHEDULE_STRUCT  = MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.PROMOTION_SCHEDULE
    local PLAYERS_STRUCT   = MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.PROMOTION_PLAYERS
    for roundNum, stepDefine in ipairs(FOOD.CHAMPIONSHIP.ROUND_NUM) do
        local beganStep = checkint(stepDefine.beganStep)
        local endedStep = checkint(stepDefine.endedStep)
        if beganStep <= scheduleStep and scheduleStep <= endedStep then
            currentRoundNum  = roundNum
            currentBeganStep = beganStep
            currentEndedStep = endedStep
            break
        end
    end

    -- find currentMatchId
    for matchId = currentBeganStep, currentEndedStep do
        local matchProxy = self.mainProxy_:get(SCHEDULE_STRUCT.MATCH_DATA, tostring(matchId))
        local attackerId = matchProxy:get(SCHEDULE_STRUCT.MATCH_DATA.ATTACKER_ID)
        local defenderId = matchProxy:get(SCHEDULE_STRUCT.MATCH_DATA.DEFENDER_ID)
        if attackerId == app.gameMgr:GetPlayerId() or defenderId == app.gameMgr:GetPlayerId() then
            currentMatchId = matchId
            break
        end
    end

    -- update opponet headNode
    local matchProxy    = self.mainProxy_:get(SCHEDULE_STRUCT.MATCH_DATA, tostring(currentMatchId))
    local attackerId    = matchProxy:get(SCHEDULE_STRUCT.MATCH_DATA.ATTACKER_ID)
    local defenderId    = matchProxy:get(SCHEDULE_STRUCT.MATCH_DATA.DEFENDER_ID)
    local opponetId     = app.gameMgr:GetPlayerId() == attackerId and defenderId or attackerId
    local opponetProxy  = self.mainProxy_:get(PLAYERS_STRUCT.PLAYER_DATA, tostring(opponetId))
    local opponetName   = opponetProxy:get(PLAYERS_STRUCT.PLAYER_DATA.NAME)
    local opponetAvatar = opponetProxy:get(PLAYERS_STRUCT.PLAYER_DATA.AVATAR)
    local opponetFrame  = opponetProxy:get(PLAYERS_STRUCT.PLAYER_DATA.FRAME)
    local opponetLevel  = opponetProxy:get(PLAYERS_STRUCT.PLAYER_DATA.LEVEL)
    self:getViewData().opponetPlayerLayer:setUserTag(opponetId)
    self:getViewData().opponetNameLabel:updateLabel({text = opponetName, maxW = 140})
    self:getViewData().opponetHeadNode:RefreshUI({
        playerId    = opponetId,
        avatar      = opponetId > 0 and opponetAvatar or 500375,
        avatarFrame = opponetId > 0 and opponetFrame or 0,
        playerLevel = opponetId > 0 and opponetLevel or 0,
        showLevel   = opponetId > 0,
    })
end


-------------------------------------------------
-- handler

function ChampionshipPromotionView:onUpdateRefreshTime_(signal)
    local leftSeconds = self.mainProxy_:get(MAIN_PROXY_STRUCT.REFRESH_COUNTDOWN)
    local refreshText = CommonUtils.getTimeFormatByType(leftSeconds, 3)
    self:getViewData().countdownLabel:updateLabel({text = string.fmt(__('剩余：_time_'), {_time_ = refreshText})})
    
    if self:getViewData().applyLayer:isVisible() then
        self:getViewData().applyTimeLabel:updateLabel({text = string.fmt(__('报名倒计时：_time_'), {_time_ = refreshText})})
    end
end


function ChampionshipPromotionView:onUpdateScheduleStep_(signal)
    local scheduleStep  = self.mainProxy_:get(MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.SCHEDULE_STEP)
    local stepTitleFunc = FOOD.CHAMPIONSHIP.MATCH_TITLE[scheduleStep]
    self:getViewData().statusLabel:updateLabel({text = stepTitleFunc and stepTitleFunc() or '----'})
end


function ChampionshipPromotionView:onUpdateHomeData_(signal)
    local updateEventType = signal and signal:GetBody().eventType or VoProxy.EVENTS.CHANGE
    if updateEventType == VoProxy.EVENTS.CHANGE then
        
        if not self:getActionByTag(ACTION_ENUM.RELOAD_PROMOTION_STATE) then
            self:runAction(cc.CallFunc:create(function()

                local playerAreaState = nil
                local reportAreaState = nil
                
                -- 晋级赛-报名阶段：自己编队 | 对手问号
                local scheduleStep = self.mainProxy_:get(MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.SCHEDULE_STEP)
                if scheduleStep == FOOD.CHAMPIONSHIP.STEP.PROMOTION then
                    local isApplied = self.mainProxy_:size(MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.PROMOTION_TEAM1) > 0
                    playerAreaState = isApplied and PLAYER_AREA.SHOW_TEAM or PLAYER_AREA.EDIT_TEAM
                    reportAreaState = RESULT_AREA.OPPONENT_UNKNOW

                -- 晋级赛-第一轮投票：自己队伍 | 对手头像
                elseif scheduleStep == FOOD.CHAMPIONSHIP.STEP.VOTING_16 then
                    playerAreaState = PLAYER_AREA.SHOW_TEAM
                    reportAreaState = RESULT_AREA.OPPONENT_SHOW
                    
                -- 晋级赛-其他阶段：
                else
                    -- 自己队伍 | ----
                    playerAreaState      = PLAYER_AREA.SHOW_TEAM
                    local PLAYERS_STRUCT = MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.PROMOTION_PLAYERS
                    local playerProxy    = self.mainProxy_:get(PLAYERS_STRUCT.PLAYER_DATA, tostring(app.gameMgr:GetPlayerId()))
                    local isGameOver     = self.mainProxy_:get(MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.PROMOTION_OVER) == 1
                    local team1Power     = playerProxy:get(PLAYERS_STRUCT.PLAYER_DATA.POWER1)

                    -- 是否结束了
                    if isGameOver or team1Power == 0 then
                        reportAreaState = RESULT_AREA.REPORT_OUT
                    
                    else
                        -- 其余投票阶段，显示对手头像等着
                        if (scheduleStep == FOOD.CHAMPIONSHIP.STEP.VOTING_8 or 
                            scheduleStep == FOOD.CHAMPIONSHIP.STEP.VOTING_4 or 
                            scheduleStep == FOOD.CHAMPIONSHIP.STEP.VOTING_2 or 
                            scheduleStep == FOOD.CHAMPIONSHIP.STEP.VOTING_1) then
                            reportAreaState = RESULT_AREA.OPPONENT_SHOW
                        else
                            local currentMatchId    = 0
                            local currentWinnerId   = 0
                            local currentRoundNum   = 0
                            local currentBeganStep  = 0
                            local currentEndedStep  = 0
                            local MY_MATCHS_STRUCT  = MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.PROMOTION_MATCHES
                            local SCHEDULE_STRUCT   = MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.PROMOTION_SCHEDULE
                            for roundNum, stepDefine in ipairs(FOOD.CHAMPIONSHIP.ROUND_NUM) do
                                local beganStep = checkint(stepDefine.beganStep)
                                local endedStep = checkint(stepDefine.endedStep)
                                if beganStep <= scheduleStep and scheduleStep <= endedStep then
                                    currentRoundNum  = roundNum
                                    currentBeganStep = beganStep
                                    currentEndedStep = endedStep
                                    break
                                end
                            end

                            -- 遍历到当前阶段所在回合
                            for matchId = currentBeganStep, currentEndedStep do
                                local matchProxy = self.mainProxy_:get(SCHEDULE_STRUCT.MATCH_DATA, tostring(matchId))
                                local attackerId = matchProxy:get(SCHEDULE_STRUCT.MATCH_DATA.ATTACKER_ID)
                                local defenderId = matchProxy:get(SCHEDULE_STRUCT.MATCH_DATA.DEFENDER_ID)
                                local winnerId   = matchProxy:get(SCHEDULE_STRUCT.MATCH_DATA.WINNER_ID)
                                if attackerId == app.gameMgr:GetPlayerId() or defenderId == app.gameMgr:GetPlayerId() then
                                    currentMatchId  = matchId
                                    currentWinnerId = winnerId
                                    break
                                end
                            end

                            if 0 < currentMatchId and currentMatchId <= scheduleStep then
                                -- 进度过了自己回合，没输就是本回合赢了
                                if currentWinnerId == app.gameMgr:GetPlayerId() then
                                    reportAreaState = RESULT_AREA.REPORT_WIN
                                else
                                    reportAreaState = RESULT_AREA.REPORT_OUT
                                end
                            else
                                -- 进度没到自己回合，就先等着
                                reportAreaState = RESULT_AREA.OPPONENT_SHOW
                            end
                        end
                    end
                end

                -- update player/report state
                self:updatePlayerAreaState_(playerAreaState)
                self:updateReportAreaState_(reportAreaState)
                
            end)):setTag(ACTION_ENUM.RELOAD_PROMOTION_STATE)
        end
        
    end
end


function ChampionshipPromotionView:onUpdatePromotionTeam_(signal)
    if not self:getActionByTag(ACTION_ENUM.RELOAD_PROMOTION_TEAM) then
        self:runAction(cc.CallFunc:create(function()

            -- update player headNode
            self:getViewData().playerHeadNode:RefreshUI({
                avatar      = app.gameMgr:GetUserInfo().avatar,
                avatarFrame = app.gameMgr:GetUserInfo().avatarFrame,
                playerLevel = app.gameMgr:GetUserInfo().level,
                showLevel   = true,
            })

            -- update player nameLabel
            self:getViewData().playerNameLabel:updateLabel({text = app.gameMgr:GetUserInfo().playerName})

            -- update player promotionTeam
            for teamIndex, teamVDList in ipairs(self:getViewData().playerTeamVDList) do
                local teamPower = 0
                for cardIndex, cardHand in ipairs(teamVDList.cardHandList) do
                    local CARD_DETAIL_STRUCT = MAIN_PROXY_STRUCT.MAIN_HOME_TAKE['PROMOTION_TEAM' .. teamIndex].CARD_DETAIL
                    local cardDetailProxy    = self.mainProxy_:get(CARD_DETAIL_STRUCT, cardIndex)
                    if cardDetailProxy:get(CARD_DETAIL_STRUCT.UUID) > 0 then
                        local cardData = app.gameMgr:GetCardDataById(cardDetailProxy:get(CARD_DETAIL_STRUCT.UUID))
                        cardHand:RefreshUI({cardData = cardData})
                        cardHand:setVisible(true)
                    else
                        cardHand:setVisible(false)
                    end
                    teamPower = teamPower + CardUtils.GetCardStaticBattlePointByCardData(cardDetailProxy:getData())
                end
                teamVDList.powerLabel:updateLabel({text = string.fmt(__('总灵力：_num_'), {_num_ = teamPower})})
            end

            -- switch applyLayer status
            self:onUpdateHomeData_()

        end)):setTag(ACTION_ENUM.RELOAD_PROMOTION_TEAM)
    end
end


-------------------------------------------------
-- public

function ChampionshipPromotionView:hideOpponentTeam()
    self:getOpponentVD().view:setVisible(false)
    if self.hideOpponentTeamCB then
        self.hideOpponentTeamCB()
    end
end
function ChampionshipPromotionView:showOpponentTeam()
    self:getOpponentVD().view:setVisible(true)

    -- update opponent promotionTeam
    for teamIndex, teamVDList in ipairs(self:getOpponentVD().teamVDList) do
        local teamPower = 0
        for cardIndex, cardHand in ipairs(teamVDList.cardHandList) do
            local CARD_DETAIL_STRUCT = MAIN_PROXY_STRUCT.PROMOTION_PLAYER_TAKE['TEAM' .. teamIndex].CARD_DETAIL
            local cardDetailProxy    = self.mainProxy_:get(CARD_DETAIL_STRUCT, cardIndex)
            if cardDetailProxy:get(CARD_DETAIL_STRUCT.UUID) > 0 then
                cardHand:RefreshUI({cardData = cardDetailProxy:getData()})
                cardHand:setVisible(true)
            else
                cardHand:setVisible(false)
            end
            teamPower = teamPower + CardUtils.GetCardStaticBattlePointByCardData(cardDetailProxy:getData())
        end
        teamVDList.powerLabel:updateLabel({text = string.fmt(__('总灵力：_num_'), {_num_ = teamPower})})
    end
end


-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function ChampionshipPromotionView.CreateView()
    local view = ui.layer()
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    ------------------------------------------------- [center]
    local centerLayer = ui.layer()
    view:add(centerLayer)

    -- tableImg | vsImg
    local decorateGroup = centerLayer:addList({
        ui.image({img = RES_DICT.MATCH_VS, mt = -80}),
        ui.image({img = RES_DICT.MATCH_TABLE, mt = -20}),
    })
    ui.flowLayout(cc.rep(cpos, 0, 5), decorateGroup, {type = ui.flowV, ap = ui.cb})

    
    local leaderAvatarSize = cc.size(200, 300)
    
    ------------------------------------------------- [center.apply]
    local applyLayer = ui.layer()
    centerLayer:add(applyLayer)

    -- apply decImg
    local applyDecImg = ui.image({img = RES_DICT.BOTTOM_DEC_BAR, ap = ui.cb})
    applyLayer:addList(applyDecImg):alignTo(nil, ui.cb, {offsetY = -8})

    -- applyFrame | applyButton | applyTimeLabel
    local applyGroup = applyLayer:addList({
        ui.image({img = RES_DICT.APPLY_FRAME}),
        ui.button({n = RES_DICT.APPLY_BTN, ml = 11, mb = 17}):updateLabel({fnt = FONT.D20, fontSize = 36, text = __('报名')}),
        ui.label({fnt = FONT.D13, color = '#B77F77', ap = ui.cc, mt = 65}),
    })
    ui.flowLayout(cc.p(display.SAFE_R - 200, 121), applyGroup, {type = ui.flowC, ap = ui.cc})

    -- player avatarLayer | plateImg
    local playerAvatarGroup = applyLayer:addList({
        ui.layer({size = leaderAvatarSize, mb = -15, zorder = 1, color = cc.r4b(0), enable = true}),
        ui.image({img = RES_DICT.PLATE_BLUE}),
    })
    ui.flowLayout(cc.rep(cpos, -255, -180-30), playerAvatarGroup, {type = ui.flowV, ap = ui.ct})

    -- editTeamIcon
    local editTeamIcon = ui.image({img = RES_DICT.EDIT_TEAM, ap = ui.cb})
    applyLayer:addList(editTeamIcon):alignTo(playerAvatarGroup[2], ui.ct, {offsetY = 50})
    editTeamIcon:runAction(cc.RepeatForever:create(cc.Sequence:create({
        cc.DelayTime:create(0.8),
        cc.ScaleTo:create(0.1, 1.1, 0.8),
        cc.ScaleTo:create(0.1, 1),
        cc.JumpBy:create(0.4, cc.p(0,0), 60, 1),
        cc.ScaleTo:create(0.1, 1.1, 0.8),
        cc.ScaleTo:create(0.1, 1)
    })))
    
    ------------------------------------------------- [center.opponent]
    local opponentLayer = ui.layer()
    centerLayer:add(opponentLayer)
    
    -- opponent avatarLayer | plateImg
    local opponentAvatarGroup = opponentLayer:addList({
        ui.layer({size = leaderAvatarSize, mb = -15, zorder = 1}),
        ui.image({img = RES_DICT.PLATE_RED}),
    })
    ui.flowLayout(cc.rep(cpos, 255, -180-30), opponentAvatarGroup, {type = ui.flowV, ap = ui.ct})

    -- opponent lightImg | unknowImg | playerLayer
    local opponentAvatarLayer = opponentAvatarGroup[1]
    local opponentStatusGroup = opponentAvatarLayer:addList({
        ui.image({img = RES_DICT.OPPONENT_LIGHT}),
        ui.image({img = RES_DICT.OPPONENT_UNKNOW, mb = 50}),
        ui.layer({size = cc.size(150,210), mb = 60, color = cc.r4b(0), enable = true}),
    })
    ui.flowLayout(cc.sizep(opponentAvatarLayer, ui.cb), opponentStatusGroup, {type = ui.flowC, ap = ui.cb})

    -- opponent player cardFrame | checkBar | checkIntro | nameLabel | headNode
    local opponetPlayerLayer = opponentStatusGroup[3]
    local opponetPlayerGroup = opponetPlayerLayer:addList({
        ui.image({img = RES_DICT.OPPONENT_CARD}),
        ui.image({img = RES_DICT.OPPONENT_CHECK, ml = 5, mt = 80}),
        ui.label({fnt = FONT.D19, fontSize = 24, mt = 77, text = __('队伍详情')}),
        ui.label({fnt = FONT.D8, mb = 80}),
        ui.playerHeadNode({scale = 0.7, mb = 10, showLevel = true}),
    })
    ui.flowLayout(cc.sizep(opponetPlayerLayer, ui.cc), opponetPlayerGroup, {type = ui.flowC, ap = ui.cc})

    
    ------------------------------------------------- [left]
    local leftLayer = ui.layer()
    view:add(leftLayer)

    local playerLayer = ui.layer()
    leftLayer:add(playerLayer)
    
    -- player infoFrame | teamFrame
    local applyInfoGroup = playerLayer:addList({
        ui.layer({bg = RES_DICT.PLAYER_INFO_FRAME, ml = -60, size = cc.size(500, 85), scale9 = true}),
        ui.layer({bg = RES_DICT.PLAYER_TEAM_FRAME, ml = -60, mt = -6}),
    })
    ui.flowLayout(cc.p(display.SAFE_L, cpos.y - 30), applyInfoGroup, {type = ui.flowV, ap = ui.lc})

    -- player headNode | nameLabel
    local playerInfoLayer = applyInfoGroup[1]
    local playerInfoGroup = playerInfoLayer:addList({
        ui.playerHeadNode({scale = 0.6}),
        ui.label({fnt = FONT.D18, ap = ui.lb, ml = 20, mb = 5}),
    })
    ui.flowLayout(cc.p(90, 12), playerInfoGroup, {type = ui.flowH, ap = ui.lb})

    -- player teamGorup
    local playerTeamLayer  = applyInfoGroup[2]
    local playerTeamNodes  = {}
    local playerTeamVDList = {}
    for teamIndex = 1, 3 do
        playerTeamVDList[teamIndex] = ChampionshipPromotionView.CreateTeamView(teamIndex)
        playerTeamNodes[teamIndex]  = playerTeamVDList[teamIndex].view
    end
    playerTeamLayer:addList(playerTeamNodes)
    ui.flowLayout(cc.rep(cc.sizep(playerTeamLayer, ui.lc), 90, 0), playerTeamNodes, {type = ui.flowV, ap = ui.lc, gapH = 15})


    ------------------------------------------------- [right]
    local rightLayer = ui.layer()
    view:add(rightLayer)

    local rightFuncFrame = ui.image({img = RES_DICT.FUNCITON_FRAME, size = cc.size(200, 40 + 140*3), cut = cc.dir(30,30,30,30), ap = ui.ct})
    rightLayer:addList(rightFuncFrame):alignTo(nil, ui.rt, {offsetX = -display.SAFE_L, offsetY = -60})
    
    -- rightFunc group
    local rightFuncGroup = rightLayer:addList({
        ui.button({n = RES_DICT.SHOP_BTN}):updateLabel({fnt = FONT.D19, fontSize = 24, text = __('印记商店'), offset = cc.p(0,-50)}),
        ui.button({n = RES_DICT.REWARD_BTN}):updateLabel({fnt = FONT.D19, fontSize = 24, text = __('奖励预览'), offset = cc.p(0,-50)}),
        ui.button({n = RES_DICT.SCHEDULE_BTN}):updateLabel({fnt = FONT.D19, fontSize = 24, text = __('查看赛程'), offset = cc.p(0,-50)}),
    })
    ui.flowLayout(cc.rep(rightFuncFrame, 0, -10), rightFuncGroup, {type = ui.flowV, ap = ui.cb})


    -- out reportLayer
    local outReportLayer = ui.layer({bg = RES_DICT.REPORT_FRAME, ap = ui.cc})
    rightLayer:addList(outReportLayer):alignTo(nil, ui.cc, {offsetX = 220, offsetY = -80})

    -- out title | descr | rankLabel | rewardLine | rewardLayer | rewardLine | reportBtn
    local outReportGroup = outReportLayer:addList({
        ui.title({img = RES_DICT.REPORT_TITLE, mb = -20}):updateLabel({fnt = FONT.D19, fontSize = 24, text = __('比赛奖励')}),
        ui.label({fnt = FONT.D15, hAlign = display.TAC, w = 500, h = 55}):updateLabel({text = __('发放规则：奖励通过邮件发放\n发放时间：活动结束后两小时')}),
        ui.title({img = RES_DICT.REPORT_REWARD_TITLE}):updateLabel({fnt = FONT.D16, fontSize = 24}),
        ui.image({img = RES_DICT.REPORT_REWARD_LINE}),
        ui.layer({bg = RES_DICT.REPORT_REWARD_BG, cut = cc.dir(30,30,30,30), size = cc.size(440,180)}),
        ui.image({img = RES_DICT.REPORT_REWARD_LINE}),
        ui.button({n = RES_DICT.REPORT_BTN, mt = 10}):updateLabel({fnt = FONT.D14, text = __('战报')}),
    })
    ui.flowLayout(cc.rep(cc.sizep(outReportLayer, ui.cb), 0, 30), outReportGroup, {type = ui.flowV, ap = ui.ct})


    -- win reportLayer
    local winReportLayer = ui.layer({bg = RES_DICT.REPORT_FRAME, ap = ui.cc, scale9 = true, size = cc.size(470, 350)})
    rightLayer:addList(winReportLayer):alignTo(nil, ui.cc, {offsetX = 220, offsetY = -60})

    -- win title | descr | reportBtn
    local winReportGroup = winReportLayer:addList({
        ui.title({img = RES_DICT.REPORT_TITLE, mb = -20}):updateLabel({fnt = FONT.D19, fontSize = 24, text = __('比赛晋级')}),
        ui.label({fnt = FONT.D15, hAlign = display.TAC, w = 500, h = 55}):updateLabel({text = __('成功晋级下轮比赛\n等待后续比赛开始')}),
        ui.button({n = RES_DICT.REPORT_BTN, mt = 10}):updateLabel({fnt = FONT.D14, text = __('战报')}),
    })
    ui.flowLayout(cc.rep(cc.sizep(winReportLayer, ui.cb), 0, 40), winReportGroup, {type = ui.flowV, ap = ui.ct})


    ------------------------------------------------- [top]
    local topLayer = ui.layer()
    view:add(topLayer)

    -- ceilingFrame | countdownBar | seasonLabel | statusLabel | countdownLabel
    local ceilingGroup = topLayer:addList({
        ui.image({img = RES_DICT.CEILING_FRAME, enable = true}),
        ui.image({img = RES_DICT.COUNTDOWN_BAR, mt = 22}),
        ui.label({fnt = FONT.D19, fontSize = 22, mb = 52}),
        ui.label({fnt = FONT.D12, fontSize = 22, mb = 12}),
        ui.label({fnt = FONT.D16, fontSize = 22, mt = 22, color = '#540e0e'}),
    })
    ui.flowLayout(cc.rep(cc.sizep(size, ui.ct), -5, -120), ceilingGroup, {type = ui.flowC, ap = ui.cc})
    

    return {
        view                = view,
        --                  = center
        vsImg               = decorateGroup[1],
        applyLayer          = applyLayer,
        applyBtn            = applyGroup[2],
        applyTimeLabel      = applyGroup[3],
        playerAvatarLayer   = playerAvatarGroup[1],
        opponentLayer       = opponentLayer,
        opponentUnknowImg   = opponentStatusGroup[2],
        opponetPlayerLayer  = opponetPlayerLayer,
        opponetNameLabel    = opponetPlayerGroup[4],
        opponetHeadNode     = opponetPlayerGroup[5],
        opponentAvatarLayer = opponentAvatarLayer,
        --                  = left
        playerLayer         = playerLayer,
        playerHeadNode      = playerInfoGroup[1],
        playerNameLabel     = playerInfoGroup[2],
        playerTeamVDList    = playerTeamVDList,
        --                  = right
        rightLayer          = rightLayer,
        shopBtn             = rightFuncGroup[1],
        rewardBtn           = rightFuncGroup[2],
        scheduleBtn         = rightFuncGroup[3],
        outReportLayer      = outReportLayer,
        outRankLabel        = outReportGroup[3],
        outRewardsLayer     = outReportGroup[5],
        outReportBtn        = outReportGroup[7],
        winReportLayer      = winReportLayer,
        winReportBtn        = winReportGroup[3],
        --                  = top
        topLayer            = topLayer,
        scheduleFrame       = ceilingGroup[1],
        seasonLabel         = ceilingGroup[3],
        statusLabel         = ceilingGroup[4],
        countdownLabel      = ceilingGroup[5],
    }
end


function ChampionshipPromotionView.CreateTeamView(teamIndex, isRight)
    local size = cc.size(520, 150)
    local view = ui.layer({size = size})
    local cpos = cc.sizep(size, ui.cc)
    view:add(ui.image({p = cpos, img = RES_DICT.TEAM_FRAME, scaleX = isRight and -1 or 1}))

    -- cardHand list
    local cardHandList = {}
    for cardIndex = 1, MAX_TEAM_MEMBER_AMOUNT do
        cardHandList[cardIndex] = ui.cardHeadNode({scale = 0.45})
    end
    view:addList(cardHandList)
    ui.flowLayout(cc.p(22 + (isRight and 20 or 0), 22), cardHandList, {type = ui.flowH, ap = ui.lb, gapW = 7})

    if not isRight then
        cardHandList = table.reverse(cardHandList)
    end

    -- titleLabel
    local titleLabel = ui.label({fnt = FONT.D14, fontSize = 20, text = string.fmt(__('队伍_num_'), {_num_ = teamIndex})})
    if isRight then
        view:addList(titleLabel):alignTo(nil, ui.ct, {offsetX = -8, offsetY = -6})
    else
        view:addList(titleLabel):alignTo(nil, ui.lt, {offsetX = 12, offsetY = -6})
    end

    -- powerLabel
    local powerLabel = ui.label({fnt = FONT.D15, color = '#DAA855', ap = ui.rt})
    if isRight then
        view:addList(powerLabel):alignTo(nil, ui.rt, {offsetX = -12, offsetY = -8})
    else
        view:addList(powerLabel):alignTo(nil, ui.ct, {offsetX = 32, offsetY = -8})
    end

    -- leaderIcon
    local leaderIcon = ui.image({img = RES_DICT.LEADER_ICON})
    view:addList(leaderIcon):alignTo(cardHandList[1], ui.cc, {offsetY = 40})

    -- clickArea
    local clickArea = ui.layer({size = size, color = cc.r4b(0), enable = true})
    clickArea:setTag(teamIndex)
    view:add(clickArea)
    

    return {
        view         = view,
        cardHandList = cardHandList,
        powerLabel   = powerLabel,
        clickArea    = clickArea,
    }
end


function ChampionshipPromotionView.CreateOpponentView()
    local view = ui.layer()
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    -- block layer
    local blockLayer = ui.layer({color = cc.c4b(0,0,0,100), enable = true})
    view:add(blockLayer)

    -- team layer    
    local teamLayer = ui.layer({bg = RES_DICT.OPPONENT_TEAM_FRAME})
    view:addList(teamLayer):alignTo(nil, ui.rc, {offsetX = 60 - display.SAFE_L, offsetY = -70})

    -- team gorup
    local teamNodes  = {}
    local teamVDList = {}
    for teamIndex = 1, 3 do
        teamVDList[teamIndex] = ChampionshipPromotionView.CreateTeamView(teamIndex, true)
        teamNodes[teamIndex]  = teamVDList[teamIndex].view
    end
    teamLayer:addList(teamNodes)
    ui.flowLayout(cc.rep(cc.sizep(teamLayer, ui.rc), -90, 0), teamNodes, {type = ui.flowV, ap = ui.rc, gapH = 15})

    return {
        view       = view,
        blockLayer = blockLayer,
        teamVDList = teamVDList,
    }
end


return ChampionshipPromotionView
