--[[
 * author : kaishiqi
 * descpt : 武道会 - 回放视图
]]
local ChampionshipReplayView = class('ChampionshipReplayView', function()
    return ui.layer({name = 'Game.views.championship.ChampionshipReplayView', enableEvent = true})
end)

local RES_DICT = {
    BACK_BTN       = _res('ui/common/common_btn_back.png'),
    VS_IMG         = _res('ui/championship/auditions/starplan_vs_icon_vs.png'),
    ATTACKER_BAR   = _res('ui/championship/replay/budo_ticket_bg_playback_bule.png'),
    DEFENDER_BAR   = _res('ui/championship/replay/budo_ticket_bg_playback_red.png'),
    REPLAY_BTN     = _res('ui/championship/replay/starplan_vs_btn_playback_big.png'),
    MATCH_BAR_N    = _res('ui/championship/report/budo_pvp_line_report_list_red.png'),
    MATCH_BAR_D    = _res('ui/championship/report/budo_pvp_line_report_list_grey_.png'),
    LEADER_ICON    = _res('ui/championship/auditions/team_ico_captain.png'),
    TEAM_FRAME_N   = _res('ui/tagMatch/3v3_ranks_bg.png'),
    TEAM_FRAME_D   = _res('ui/tagMatch/3v3_ranks_bg_grey.png'),
    ATK_TEAM_FRAME = _res('ui/championship/replay/budo_bg_common_bg_3_bule.png'),
    DEF_TEAM_FRAME = _res('ui/championship/replay/budo_bg_common_bg_3_red.png'),
}

local ACTION_ENUM = {
    RELOAD_ATTACKER_TEAM = 1,
    RELOAD_DEFENDER_TEAM = 2,
    RELOAD_REPLAY_RESULT = 3,
}

local MAIN_PROXY_NAME     = FOOD.CHAMPIONSHIP.MAIN.PROXY_NAME
local MAIN_PROXY_STRUCT   = FOOD.CHAMPIONSHIP.MAIN.PROXY_STRUCT
local REPLAY_PROXY_NAME   = FOOD.CHAMPIONSHIP.REPLAY.PROXY_NAME
local REPLAY_PROXY_STRUCT = FOOD.CHAMPIONSHIP.REPLAY.PROXY_STRUCT


function ChampionshipReplayView:ctor(args)
    -- create view
    self.viewData_ = ChampionshipReplayView.CreateView()
    self:addChild(self.viewData_.view)

    -- bind model
    self.mainProxy_   = app:RetrieveProxy(MAIN_PROXY_NAME)
    self.replayProxy_ = app:RetrieveProxy(REPLAY_PROXY_NAME)
    self.viewBindMap_ = {
        [REPLAY_PROXY_STRUCT.REPLAY_RESULT_TAKE.RESULT]      = self.onUpdateReplayResult_, -- clean all / update all
        [REPLAY_PROXY_STRUCT.REPLAY_RESULT_TAKE.RESULT.DATA] = self.onUpdateReplayResult_,
    }

    -- update view
    local handlerList = VoProxy.EventBind(REPLAY_PROXY_NAME, self.viewBindMap_, self)
    table.each(handlerList, function(_, v) v(self) end)
    self:updateAttackerInfo_()
    self:updateDefenderInfo_()
end


function ChampionshipReplayView:onCleanup()
    VoProxy.EventUnbind(REPLAY_PROXY_NAME, self.viewBindMap_, self)
end


function ChampionshipReplayView:getViewData()
    return self.viewData_
end


-------------------------------------------------
-- private

function ChampionshipReplayView:updateAttackerInfo_()
    local attackerId     = self.replayProxy_:get(REPLAY_PROXY_STRUCT.ATTACKER_ID)
    local PLAYERS_STRUCT = MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.PROMOTION_PLAYERS
    local attackerProxy  = self.mainProxy_:get(PLAYERS_STRUCT.PLAYER_DATA, tostring(attackerId))
    local attackerName   = attackerProxy:get(PLAYERS_STRUCT.PLAYER_DATA.NAME)
    local attackerUnion  = attackerProxy:get(PLAYERS_STRUCT.PLAYER_DATA.UNION)
    local attackerAvatar = attackerProxy:get(PLAYERS_STRUCT.PLAYER_DATA.AVATAR)
    local attackerFrame  = attackerProxy:get(PLAYERS_STRUCT.PLAYER_DATA.FRAME)
    local attackerLevel  = attackerProxy:get(PLAYERS_STRUCT.PLAYER_DATA.LEVEL)
    local unionText      = string.len(attackerUnion) > 0 and string.fmt(__('工会：_name_'), {_name_ = attackerUnion}) or ''
    self:getViewData().attackerName:updateLabel({text = attackerName})
    self:getViewData().attackerUnion:updateLabel({text = unionText})
    self:getViewData().attackerHead:RefreshUI({
        playerId    = attackerId,
        avatar      = attackerId > 0 and attackerAvatar or 500375,
        avatarFrame = attackerId > 0 and attackerFrame or 0,
        playerLevel = attackerId > 0 and attackerLevel or 0,
        showLevel   = attackerId > 0,
    })
end


function ChampionshipReplayView:updateDefenderInfo_()
    local defenderId     = self.replayProxy_:get(REPLAY_PROXY_STRUCT.DEFENDER_ID)
    local PLAYERS_STRUCT = MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.PROMOTION_PLAYERS
    local defenderProxy  = self.mainProxy_:get(PLAYERS_STRUCT.PLAYER_DATA, tostring(defenderId))
    local defenderName   = defenderProxy:get(PLAYERS_STRUCT.PLAYER_DATA.NAME)
    local defenderUnion  = defenderProxy:get(PLAYERS_STRUCT.PLAYER_DATA.UNION)
    local defenderAvatar = defenderProxy:get(PLAYERS_STRUCT.PLAYER_DATA.AVATAR)
    local defenderFrame  = defenderProxy:get(PLAYERS_STRUCT.PLAYER_DATA.FRAME)
    local defenderLevel  = defenderProxy:get(PLAYERS_STRUCT.PLAYER_DATA.LEVEL)
    local unionText      = string.len(defenderUnion) > 0 and string.fmt(__('工会：_name_'), {_name_ = defenderUnion}) or ''
    self:getViewData().defenderName:updateLabel({text = defenderName})
    self:getViewData().defenderUnion:updateLabel({text = unionText})
    self:getViewData().defenderHead:RefreshUI({
        playerId    = defenderId,
        avatar      = defenderId > 0 and defenderAvatar or 500375,
        avatarFrame = defenderId > 0 and defenderFrame or 0,
        playerLevel = defenderId > 0 and defenderLevel or 0,
        showLevel   = defenderId > 0,
    })
end


function ChampionshipReplayView:updateReplayTeamResult_(teamIndex)
    local RESULT_DATA_STRUCT = REPLAY_PROXY_STRUCT.REPLAY_RESULT_TAKE.RESULT.DATA
    local isEmptyTeamResult  = self.replayProxy_:size(REPLAY_PROXY_STRUCT.REPLAY_RESULT_TAKE.RESULT) == 0
    local resultDataProxy    = self.replayProxy_:get(RESULT_DATA_STRUCT, tostring(teamIndex))

    -- update attacker team
    local attackerTeamPower  = 0
    local attackerTeamVDList = self:getViewData().atkTeamVDList[teamIndex]
    for cardIndex, cardHand in ipairs(attackerTeamVDList.cardHandList) do
        local CARD_DETAIL_STRUCT = RESULT_DATA_STRUCT.ATTACKER_TEAM.CARD_DETAIL
        local cardDetailProxy    = resultDataProxy:get(CARD_DETAIL_STRUCT, cardIndex)
        if cardDetailProxy:get(CARD_DETAIL_STRUCT.UUID) > 0 then
            cardHand:RefreshUI({cardData = cardDetailProxy:getData()})
            cardHand:setVisible(true)
        else
            cardHand:setVisible(false)
        end
        attackerTeamPower = attackerTeamPower + CardUtils.GetCardStaticBattlePointByCardData(cardDetailProxy:getData())
    end
    attackerTeamVDList.powerLabel:updateLabel({text = string.fmt(__('总灵力：_num_'), {_num_ = attackerTeamPower})})


    -- update defender team
    local defenderTeamPower  = 0
    local defenderTeamVDList = self:getViewData().defTeamVDList[teamIndex]
    for cardIndex, cardHand in ipairs(defenderTeamVDList.cardHandList) do
        local CARD_DETAIL_STRUCT = RESULT_DATA_STRUCT.DEFENDER_TEAM.CARD_DETAIL
        local cardDetailProxy    = resultDataProxy:get(CARD_DETAIL_STRUCT, cardIndex)
        if cardDetailProxy:get(CARD_DETAIL_STRUCT.UUID) > 0 then
            cardHand:RefreshUI({cardData = cardDetailProxy:getData()})
            cardHand:setVisible(true)
        else
            cardHand:setVisible(false)
        end
        defenderTeamPower = defenderTeamPower + CardUtils.GetCardStaticBattlePointByCardData(cardDetailProxy:getData())
    end
    defenderTeamVDList.powerLabel:updateLabel({text = string.fmt(__('总灵力：_num_'), {_num_ = defenderTeamPower})})


    -- update battle result
    local battleResult  = resultDataProxy:get(RESULT_DATA_STRUCT.BATTLE_RESULT)
    local isAttackerWin = battleResult == 1
    if isEmptyTeamResult then
        attackerTeamVDList.frameNormal:setVisible(true)
        defenderTeamVDList.frameNormal:setVisible(true)
        attackerTeamVDList.frameDisable:setVisible(false)
        defenderTeamVDList.frameDisable:setVisible(false)
        attackerTeamVDList.leaderIcon:setColor(cc.c3b(255,255,255))
        defenderTeamVDList.leaderIcon:setColor(cc.c3b(255,255,255))
        attackerTeamVDList.powerLabel:setColor(ccc3FromInt('#DAA855'))
        defenderTeamVDList.powerLabel:setColor(ccc3FromInt('#DAA855'))
        attackerTeamVDList.titleLabel:setColor(ccc3FromInt('#FFFFFF'))
        defenderTeamVDList.titleLabel:setColor(ccc3FromInt('#FFFFFF'))
        for cardIndex, cardHand in ipairs(attackerTeamVDList.cardHandList) do
            cardHand:setColor(cc.c3b(255,255,255))
        end
        for cardIndex, cardHand in ipairs(defenderTeamVDList.cardHandList) do
            cardHand:setColor(cc.c3b(255,255,255))
        end

    else
        attackerTeamVDList.frameNormal:setVisible(isAttackerWin)
        defenderTeamVDList.frameNormal:setVisible(not isAttackerWin)
        attackerTeamVDList.frameDisable:setVisible(not isAttackerWin)
        defenderTeamVDList.frameDisable:setVisible(isAttackerWin)
        attackerTeamVDList.leaderIcon:setColor(isAttackerWin and cc.c3b(255,255,255) or cc.c3b(150,150,150))
        defenderTeamVDList.leaderIcon:setColor(isAttackerWin and cc.c3b(150,150,150) or cc.c3b(255,255,255))
        attackerTeamVDList.powerLabel:setColor(isAttackerWin and ccc3FromInt('#DAA855') or ccc3FromInt('#CCCCCC'))
        defenderTeamVDList.powerLabel:setColor(isAttackerWin and ccc3FromInt('#CCCCCC') or ccc3FromInt('#DAA855'))
        attackerTeamVDList.titleLabel:setColor(isAttackerWin and ccc3FromInt('#FFFFFF') or ccc3FromInt('#CCCCCC'))
        defenderTeamVDList.titleLabel:setColor(isAttackerWin and ccc3FromInt('#CCCCCC') or ccc3FromInt('#FFFFFF'))
        for cardIndex, cardHand in ipairs(attackerTeamVDList.cardHandList) do
            cardHand:setColor(isAttackerWin and cc.c3b(255,255,255) or cc.c3b(150,150,150))
        end
        for cardIndex, cardHand in ipairs(defenderTeamVDList.cardHandList) do
            cardHand:setColor(isAttackerWin and cc.c3b(150,150,150) or cc.c3b(255,255,255))
        end
    end
end


-------------------------------------------------
-- handler

function ChampionshipReplayView:onUpdateReplayResult_(signal)
    if not self:getActionByTag(ACTION_ENUM.RELOAD_REPLAY_RESULT) then
        self:runAction(cc.CallFunc:create(function()

            for teamIndex = 1, 3 do
                self:updateReplayTeamResult_(teamIndex)
            end
            
        end)):setTag(ACTION_ENUM.RELOAD_REPLAY_RESULT)
    end
end


-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function ChampionshipReplayView.CreateView()
    local view = ui.layer()
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    -- black / block layer
    local backGroundGroup = view:addList({
        ui.layer({color = cc.c4b(0,0,0,150)}),
        ui.layer({color = cc.r4b(0), enable = true}),
    })

    -- team frame
    local atkTeamFrame = ui.image({img = RES_DICT.ATK_TEAM_FRAME})
    local defTeamFrame = ui.image({img = RES_DICT.DEF_TEAM_FRAME})
    view:addList(atkTeamFrame):alignTo(nil, ui.lc, {offsetX = display.SAFE_L - 60})
    view:addList(defTeamFrame):alignTo(nil, ui.rc, {offsetX = -display.SAFE_L + 60})


    ------------------------------------------------- [top]
    local topLayer = ui.layer()
    view:add(topLayer)

    -- back button
    local backBtn = ui.button({n = RES_DICT.BACK_BTN})
    topLayer:addList(backBtn):alignTo(nil, ui.lt, {offsetX = display.SAFE_L + 30, offsetY = -15})


    ------------------------------------------------- [center]
    local centerLayer = ui.layer()
    view:add(centerLayer)

    local playerInfoOffsetX = 100
    local playerInfoOffsetY = 200
    local playerTeamOffsetY = -97
    

    -- attacker [bar | name | head]
    local attackerGroup = centerLayer:addList({
        ui.image({img = RES_DICT.ATTACKER_BAR, ml = -playerInfoOffsetX - 60}),
        ui.label({fnt = FONT.D12, color = '#FFFFCC', ap = ui.lb, ml = 120, mb = 5}),
        ui.label({fnt = FONT.D18, color = '#FFFFFF', ap = ui.lb, ml = 120, mt = 22}),
        ui.playerHeadNode({scale = 0.7, showLevel = true, mb = 25}),
    })
    ui.flowLayout(cc.p(display.SAFE_L + playerInfoOffsetX, cpos.y + playerInfoOffsetY), attackerGroup, {type = ui.flowC, ap = ui.lc})


    -- defender [bar | name | head]
    local defenderGroup = centerLayer:addList({
        ui.image({img = RES_DICT.DEFENDER_BAR, mr = -playerInfoOffsetX - 60}),
        ui.label({fnt = FONT.D12, color = '#FFFFCC', ap = ui.rb, mr = 120, mb = 5}),
        ui.label({fnt = FONT.D18, color = '#FFFFFF', ap = ui.rb, mr = 120, mt = 22}),
        ui.playerHeadNode({scale = 0.7, showLevel = true, mb = 25}),
    })
    ui.flowLayout(cc.p(display.SAFE_R - playerInfoOffsetX, cpos.y + playerInfoOffsetY), defenderGroup, {type = ui.flowC, ap = ui.rc})


    -- vsImage
    local vsImg = ui.image({img = RES_DICT.VS_IMG})
    centerLayer:addList(vsImg):alignTo(nil, ui.cc, {offsetY = playerInfoOffsetY + 25})


    -- team list
    local teamLayerList = {}
    local replayBtnList = {}
    local atkTeamVDList = {}
    local defTeamVDList = {}
    for teamIndex = 1, 3 do
        replayBtnList[teamIndex] = ui.button({n = RES_DICT.REPLAY_BTN, tag = teamIndex})
        atkTeamVDList[teamIndex] = ChampionshipReplayView.CreateTeamView(teamIndex, false)
        defTeamVDList[teamIndex] = ChampionshipReplayView.CreateTeamView(teamIndex, true)
        
        local teamLayer = ui.layer({size = cc.size(size.width, 160), color1 = cc.r4b(100)})
        local teamGroup = teamLayer:addList({
            ui.image({img = RES_DICT.MATCH_BAR_N}),
            atkTeamVDList[teamIndex].view:setMargin(0, 360, 0, 0),
            defTeamVDList[teamIndex].view:setMargin(0, 0, 0, 360),
            replayBtnList[teamIndex],
        })
        ui.flowLayout(cc.sizep(teamLayer, ui.cc), teamGroup, {type = ui.flowC, ap = ui.cc})
        teamLayerList[teamIndex] = teamLayer
    end
    centerLayer:addList(teamLayerList)
    ui.flowLayout(cc.rep(cpos, 0, playerTeamOffsetY), teamLayerList, {type = ui.flowV, ap = ui.cc})
    

    return {
        view          = view,
        blackLayer    = backGroundGroup[1],
        blockLayer    = backGroundGroup[2],
        --            = top
        backBtn       = backBtn,
        --            = center
        attackerUnion = attackerGroup[2],
        attackerName  = attackerGroup[3],
        attackerHead  = attackerGroup[4],
        defenderUnion = defenderGroup[2],
        defenderName  = defenderGroup[3],
        defenderHead  = defenderGroup[4],
        replayBtnList = replayBtnList,
        atkTeamVDList = atkTeamVDList,
        defTeamVDList = defTeamVDList,
    }
end


function ChampionshipReplayView.CreateTeamView(teamIndex, isRight)
    local size = cc.size(520, 150)
    local view = ui.layer({size = size})
    local cpos = cc.sizep(size, ui.cc)

    -- frame [normal | desable]
    local frameGroup = view:addList({
        ui.image({img = RES_DICT.TEAM_FRAME_N, scaleX = isRight and -1 or 1}),
        ui.image({img = RES_DICT.TEAM_FRAME_D, scaleX = isRight and -1 or 1}),
    })
    ui.flowLayout(cpos, frameGroup, {type = ui.flowC, ap = ui.cc})

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
        frameNormal  = frameGroup[1],
        frameDisable = frameGroup[2],
        cardHandList = cardHandList,
        titleLabel   = titleLabel,
        leaderIcon   = leaderIcon,
        powerLabel   = powerLabel,
        clickArea    = clickArea,
    }
end


return ChampionshipReplayView
