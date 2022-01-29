--[[
 * author : kaishiqi
 * descpt : 武道会 - 玩家详情视图
]]
local ChampionshipPlayerDetailView = class('ChampionshipPlayerDetailView', function()
    return ui.layer({name = 'Game.views.championship.ChampionshipPlayerDetailView', enableEvent = true})
end)

local RES_DICT = {
    PLAYER_BG    = _res('ui/championship/guess/budo_ticket_bg_message_ren.png'),
    TEAM_BG      = _res('ui/championship/guess/budo_ticket_bg_message_team.png'),
    INFO_BG      = _res('ui/championship/guess/budo_ticket_bg_message.png'),
    LEADER_ICON  = _res('ui/championship/auditions/team_ico_captain.png'),
    TEAM_FRAME   = _res('ui/tagMatch/3v3_ranks_bg.png'),
    VOTE_BTN_N   = _res('ui/common/common_btn_orange.png'),
    VOTE_BTN_D   = _res('ui/common/common_btn_orange_disable.png'),
    CUTTING_LINE = _res('ui/common/common_ico_line_1.png'),
}

local ACTION_ENUM = {
    RELOAD_GUESS_DATA  = 1,
    RELOAD_PLAYER_VOTE = 2,
    RELOAD_PLAYER_TEAM = 3,
}

local MAIN_PROXY_NAME     = FOOD.CHAMPIONSHIP.MAIN.PROXY_NAME
local MAIN_PROXY_STRUCT   = FOOD.CHAMPIONSHIP.MAIN.PROXY_STRUCT
local DETAIL_PROXY_NAME   = FOOD.CHAMPIONSHIP.PLAYER_DETAIL.PROXY_NAME
local DETAIL_PROXY_STRUCT = FOOD.CHAMPIONSHIP.PLAYER_DETAIL.PROXY_STRUCT


function ChampionshipPlayerDetailView:ctor(args)
    -- create view
    self.viewData_ = ChampionshipPlayerDetailView.CreateView()
    self:addChild(self.viewData_.view)

    -- bind model
    self.mainProxy_     = app:RetrieveProxy(MAIN_PROXY_NAME)
    self.detailProxy_   = app:RetrieveProxy(DETAIL_PROXY_NAME)
    self.detailBindMap_ = {
        [DETAIL_PROXY_STRUCT.PLAYER_TAKE] = self.onUpdatePlayerTeam_,
    }
    self.mainBindMap_ = {
        [MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.GUESS_DETAIL.GUESS_DATA]                     = self.onUpdateGuessInfo_,
        [MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.GUESS_DETAIL.GUESS_DATA.GUESS_NUM]           = self.onUpdateGuessInfo_,
        [MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.GUESS_DETAIL.GUESS_DATA.PLAYER_ID]           = self.onUpdateGuessInfo_,
        [MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.PROMOTION_SCHEDULE.MATCH_DATA.ATTACKER_VOTE] = self.onUpdateVoteInfo_,
        [MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.PROMOTION_SCHEDULE.MATCH_DATA.DEFENDER_VOTE] = self.onUpdateVoteInfo_,
    }

    -- update view
    local handlerList1 = VoProxy.EventBind(MAIN_PROXY_NAME, self.mainBindMap_, self)
    local handlerList2 = VoProxy.EventBind(DETAIL_PROXY_NAME, self.detailBindMap_, self)
    table.each(handlerList1, function(_, v) v(self) end)
    table.each(handlerList2, function(_, v) v(self) end)
    self:updatePlayerInfo_()
end


function ChampionshipPlayerDetailView:onCleanup()
    VoProxy.EventUnbind(MAIN_PROXY_NAME, self.mainBindMap_, self)
    VoProxy.EventUnbind(DETAIL_PROXY_NAME, self.detailBindMap_, self)
end


function ChampionshipPlayerDetailView:getViewData()
    return self.viewData_
end


-------------------------------------------------
-- private

function ChampionshipPlayerDetailView:updatePlayerInfo_()
    local detailType     = self.detailProxy_:get(DETAIL_PROXY_STRUCT.DETAIL_TYPE)
    local playerId       = self.detailProxy_:get(DETAIL_PROXY_STRUCT.PLAYER_ID)
    local PLAYERS_STRUCT = MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.PROMOTION_PLAYERS
    local playerProxy    = self.mainProxy_:get(PLAYERS_STRUCT.PLAYER_DATA, tostring(playerId))
    local playerName     = playerProxy:get(PLAYERS_STRUCT.PLAYER_DATA.NAME)
    local playerUnion    = playerProxy:get(PLAYERS_STRUCT.PLAYER_DATA.UNION)
    local playerAvatar   = playerProxy:get(PLAYERS_STRUCT.PLAYER_DATA.AVATAR)
    local playerFrame    = playerProxy:get(PLAYERS_STRUCT.PLAYER_DATA.FRAME)
    local playerLevel    = playerProxy:get(PLAYERS_STRUCT.PLAYER_DATA.LEVEL)
    local unionText      = string.len(playerUnion) > 0 and string.fmt(__('工会：_name_'), {_name_ = playerUnion}) or ''
    self:getViewData().playerNameLabel:updateLabel({text = playerName})
    self:getViewData().playerUnionLabel:updateLabel({text = unionText})
    self:getViewData().playerHeadNode:RefreshUI({
        playerId    = playerId,
        avatar      = playerId > 0 and playerAvatar or 500375,
        avatarFrame = playerId > 0 and playerFrame or 0,
        playerLevel = playerId > 0 and playerLevel or 0,
        showLevel   = playerId > 0,
    })

    if detailType == FOOD.CHAMPIONSHIP.PLAYER_DETAIL.TYPE.VOTE then
        self:getViewData().rewardTitle:setVisible(true)
        self:getViewData().rewardIntro:setVisible(true)
    else
        self:getViewData().rewardTitle:setVisible(false)
        self:getViewData().rewardIntro:setVisible(false)
    end
end


function ChampionshipPlayerDetailView:updateGuessInfo_()
    local detailType   = self.detailProxy_:get(DETAIL_PROXY_STRUCT.DETAIL_TYPE)
    local playerId     = self.detailProxy_:get(DETAIL_PROXY_STRUCT.PLAYER_ID)
    local matchId      = self.detailProxy_:get(DETAIL_PROXY_STRUCT.MATCH_ID)
    local scheduleStep = self.mainProxy_:get(MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.SCHEDULE_STEP)
    local GUESS_STRUCT = MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.GUESS_DETAIL
    local guessProxy   = self.mainProxy_:get(GUESS_STRUCT.GUESS_DATA, tostring(matchId))
    local guessPlayer  = guessProxy:get(GUESS_STRUCT.GUESS_DATA.PLAYER_ID)
    local guessNum     = guessProxy:get(GUESS_STRUCT.GUESS_DATA.GUESS_NUM)
    local CURRENCY_ID  = FOOD.GOODS.DEFINE.CHAMPIONSHIP_CURRENCY_ID
    local goodsAmount  = app.goodsMgr:getGoodsNum(CURRENCY_ID)

    if detailType == FOOD.CHAMPIONSHIP.PLAYER_DETAIL.TYPE.VOTE then
        if scheduleStep < FOOD.CHAMPIONSHIP.STEP.VOTING_16 then
            self:getViewData().guessVoteBtn:setVisible(true)
            self:getViewData().guessVoteBtn:setEnabled(false)
            self:getViewData().guessNumRLabel:reload({
                {fnt = FONT.D1, fontSize = 22, color = '#b1613a', text = __('投票还未开始')},
            })
    
        elseif scheduleStep > FOOD.CHAMPIONSHIP.STEP.VOTING_1 then
            self:getViewData().guessVoteBtn:setVisible(true)
            self:getViewData().guessVoteBtn:setEnabled(false)
            self:getViewData().guessNumRLabel:reload({
                {fnt = FONT.D1, fontSize = 22, color = '#b1613a', text = __('投票阶段已结束')},
            })
    
        else
            local nextStep = scheduleStep + 1
            if matchId > nextStep then
                self:getViewData().guessVoteBtn:setVisible(true)
                self:getViewData().guessVoteBtn:setEnabled(false)
                self:getViewData().guessNumRLabel:reload({
                    {fnt = FONT.D1, fontSize = 22, color = '#b1613a', text = __('本场比赛未开始')},
                })
    
            elseif matchId < nextStep then
                self:getViewData().guessVoteBtn:setVisible(true)
                self:getViewData().guessVoteBtn:setEnabled(false)
                self:getViewData().guessNumRLabel:reload({
                    {fnt = FONT.D1, fontSize = 22, color = '#b1613a', text = __('本场比赛已结束')},
                })
    
            else
                if guessPlayer == 0 then
                    guessNum = FOOD.CHAMPIONSHIP.calculateVoteNum(goodsAmount)
                    self:getViewData().guessVoteBtn:setVisible(true)
                    self:getViewData().guessVoteBtn:setEnabled(true)
                    self:getViewData().guessVoteBtn:updateLabel({text = __('竞猜')})
                    self:getViewData().guessNumRLabel:reload({
                        {fnt = FONT.D1, fontSize = 22, color = '#b1613a', text = tostring(guessNum)},
                        {img = GoodsUtils.GetIconPathById(CURRENCY_ID), scale = 0.18}
                    })
                else
                    if playerId == guessPlayer then
                        self:getViewData().guessVoteBtn:updateLabel({text = __('已投票')})
                        self:getViewData().guessVoteBtn:setVisible(true)
                        self:getViewData().guessVoteBtn:setEnabled(false)
                        self:getViewData().guessNumRLabel:reload({
                            {fnt = FONT.D1, fontSize = 22, color = '#b1613a', text = tostring(guessNum)},
                            {img = GoodsUtils.GetIconPathById(CURRENCY_ID), scale = 0.18}
                        })
                    else
                        self:getViewData().guessVoteBtn:setVisible(false)
                        self:getViewData().guessVoteBtn:setEnabled(false)
                        self:getViewData().guessNumRLabel:reload({
                            {fnt = FONT.D1, fontSize = 22, color = '#b1613a', text = __('本轮已投给另一方')},
                        })
                    end
                end
            end
        end
        
    else
        self:getViewData().guessVoteBtn:setVisible(false)
        self:getViewData().guessVoteBtn:setEnabled(false)
        self:getViewData().guessNumRLabel:reload()
    end
end


-------------------------------------------------
-- handler

function ChampionshipPlayerDetailView:onUpdatePlayerTeam_(signal)
    if not self:getActionByTag(ACTION_ENUM.RELOAD_PLAYER_TEAM) then
        self:runAction(cc.CallFunc:create(function()

            -- update player team
            for teamIndex, teamVDList in ipairs(self:getViewData().teamVDList) do
                local teamPower = 0
                for cardIndex, cardHand in ipairs(teamVDList.cardHandList) do
                    local CARD_DETAIL_STRUCT = DETAIL_PROXY_STRUCT.PLAYER_TAKE['TEAM' .. teamIndex].CARD_DETAIL
                    local cardDetailProxy    = self.detailProxy_:get(CARD_DETAIL_STRUCT, cardIndex)
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

        end)):setTag(ACTION_ENUM.RELOAD_PLAYER_TEAM)
    end
end


function ChampionshipPlayerDetailView:onUpdateVoteInfo_(signal)
    if not self:getActionByTag(ACTION_ENUM.RELOAD_PLAYER_VOTE) then
        self:runAction(cc.CallFunc:create(function()

            local playerId        = self.detailProxy_:get(DETAIL_PROXY_STRUCT.PLAYER_ID)
            local matchId         = self.detailProxy_:get(DETAIL_PROXY_STRUCT.MATCH_ID)
            local SCHEDULE_STRUCT = MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.PROMOTION_SCHEDULE
            local matchProxy      = self.mainProxy_:get(SCHEDULE_STRUCT.MATCH_DATA, tostring(matchId))
            local attackerId      = matchProxy:get(SCHEDULE_STRUCT.MATCH_DATA.ATTACKER_ID)
            local defenderId      = matchProxy:get(SCHEDULE_STRUCT.MATCH_DATA.DEFENDER_ID)
            local attackerVote    = matchProxy:get(SCHEDULE_STRUCT.MATCH_DATA.ATTACKER_VOTE)
            local defenderVote    = matchProxy:get(SCHEDULE_STRUCT.MATCH_DATA.DEFENDER_VOTE)
            local playerVoteNum   = -1
            if playerId == attackerId then
                playerVoteNum = attackerVote
            elseif playerId == defenderId then
                playerVoteNum = defenderVote
            end
            self:getViewData().playerVoteLabel:updateLabel({text = string.fmt(__('票数：_num_'), {_num_ = playerVoteNum})})
            
        end)):setTag(ACTION_ENUM.RELOAD_PLAYER_VOTE)
    end
end


function ChampionshipPlayerDetailView:onUpdateGuessInfo_(signal)
    if not self:getActionByTag(ACTION_ENUM.RELOAD_GUESS_DATA) then
        self:runAction(cc.CallFunc:create(function()

            self:updateGuessInfo_()

        end)):setTag(ACTION_ENUM.RELOAD_GUESS_DATA)
    end
end


-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function ChampionshipPlayerDetailView.CreateView()
    local view = ui.layer()
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    -- black / block layer
    local backGroundGroup = view:addList({
        ui.layer({color = cc.c4b(0,0,0,150)}),
        ui.layer({color = cc.r4b(0), enable = true}),
    })


    ------------------------------------------------- [center]
    local centerLayer = ui.layer()
    view:add(centerLayer)

    -- view frame
    local viewFrameSize = cc.size(1050, 550)
    local viewFrameNode = ui.layer({p = cpos, size = viewFrameSize, ap = ui.cc})
    viewFrameNode:add(ui.layer({size = viewFrameSize, color = cc.r4b(0), enable = true}))
    centerLayer:add(viewFrameNode)


    -- layer [team | info]
    local layerGroup = viewFrameNode:addList({
        ui.layer({bg = RES_DICT.INFO_BG, zorder = 1}),
        ui.layer({bg = RES_DICT.TEAM_BG}),
    })
    ui.flowLayout(cc.sizep(viewFrameNode, ui.cc), layerGroup, {type = ui.flowH, ap = ui.cc, gapW = -20})


    -- infoLayer
    local infoLayer = layerGroup[1]
    local infoGroup = infoLayer:addList({
        ui.label({fnt = FONT.D20, fontSize = 24, color = '#FFC980', text = __('竞猜成功双倍返还货币')}),
        ui.layer({size = cc.size(0, 10)}),
        ui.label({fnt = FONT.D3, fontSize = 20, color = '#B3A399', text = __('发放形式：通过邮件发放')}),
        ui.layer({size = cc.size(0, 15)}),
        ui.image({img = RES_DICT.CUTTING_LINE, mb = -10}),
        ui.layer({bg = RES_DICT.PLAYER_BG}),
        ui.image({img = RES_DICT.CUTTING_LINE, mt = -10}),
        ui.layer({size = cc.size(0, 15)}),
        ui.button({n = RES_DICT.VOTE_BTN_N, d = RES_DICT.VOTE_BTN_D}):updateLabel({fnt = FONT.D14, text = __('竞猜')}),
        ui.rLabel({ap = ui.cc, mt = 15}),
    })
    ui.flowLayout(cc.sizep(infoLayer, ui.cc), infoGroup, {type = ui.flowV, ap = ui.cc})


    -- playerLayer
    local playerLayer = infoGroup[6]
    local playerGroup = playerLayer:addList({
        ui.playerHeadNode({scale = 0.7, showLevel = true}),
        ui.label({fnt = FONT.D1, color = '#933D2c', fontSize = 24}),
        ui.label({fnt = FONT.D3, color = '#C89B79'}),
        ui.label({fnt = FONT.D3, color = '#C89B79'}),
    })
    ui.flowLayout(cc.sizep(playerLayer, ui.cc), playerGroup, {type = ui.flowV, ap = ui.cc, gapH = 40})
    
    

    -- teamLayer
    local teamLayer = layerGroup[2]
    local teamNodes  = {}
    local teamVDList = {}
    for teamIndex = 1, 3 do
        teamVDList[teamIndex] = ChampionshipPlayerDetailView.CreateTeamView(teamIndex)
        teamNodes[teamIndex]  = teamVDList[teamIndex].view
    end
    teamLayer:addList(teamNodes)
    ui.flowLayout(cc.rep(cc.sizep(teamLayer, ui.lc), 25, 0), teamNodes, {type = ui.flowV, ap = ui.lc, gapH = 10})

    
    return {
        view             = view,
        blackLayer       = backGroundGroup[1],
        blockLayer       = backGroundGroup[2],
        rewardTitle      = infoGroup[1],
        rewardIntro      = infoGroup[3],
        guessVoteBtn     = infoGroup[9],
        guessNumRLabel   = infoGroup[10],
        playerHeadNode   = playerGroup[1],
        playerNameLabel  = playerGroup[2],
        playerUnionLabel = playerGroup[3],
        playerVoteLabel  = playerGroup[4],
        teamVDList       = teamVDList,
    }
end


function ChampionshipPlayerDetailView.CreateTeamView(teamIndex, isRight)
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


return ChampionshipPlayerDetailView
