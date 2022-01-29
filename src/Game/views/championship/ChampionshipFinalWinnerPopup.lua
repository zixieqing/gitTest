--[[
 * author : kaishiqi
 * descpt : 武道会 - 最终冠军弹窗
]]
local CommonDialog                 = require('common.CommonDialog')
local ChampionshipFinalWinnerPopup = class('ChampionshipFinalWinnerPopup', CommonDialog)

local RES_DICT = {
    INFO_BG     = _res('ui/championship/home/budo_bg_common_drum_big.png'),
    TEAM_BG     = _res('ui/championship/guess/budo_ticket_bg_message_team.png'),
    TITLE_FRAME = _res('ui/championship/closed/budo_close_bg_drum_tip.png'),
    INFO_LINE1  = _res('ui/championship/home/kitchen_tool_split_line.png'),
    INFO_LINE2  = _res('ui/championship/home/kitchen_tool_split_line_2.png'),
    INFO_FRAME  = _res('ui/championship/guess/budo_ticket_bg_message_ren.png'),
    WINNER_ICON = _res('ui/championship/schedule/budo_ticket_ico_ren_win.png'),
    LEADER_ICON = _res('ui/championship/auditions/team_ico_captain.png'),
    TEAM_FRAME  = _res('ui/tagMatch/3v3_ranks_bg.png'),
}

local MAIN_PROXY_NAME   = FOOD.CHAMPIONSHIP.MAIN.PROXY_NAME
local MAIN_PROXY_STRUCT = FOOD.CHAMPIONSHIP.MAIN.PROXY_STRUCT


function ChampionshipFinalWinnerPopup:InitialUI()
    self.isControllable_ = true

    -- init model
    self.mainProxy_ = app:RetrieveProxy(MAIN_PROXY_NAME)

    -- create view
    self.viewData = ChampionshipFinalWinnerPopup.CreateView()

    -- add listener
    self.viewBindMap_ = {
        [MAIN_PROXY_STRUCT.CHAMPION_PLAYER_TAKE] = self.onUpdateChampionTeam_,
    }
    for index, teamVD in ipairs(self:getViewData().teamVDList) do
        ui.bindClick(teamVD.clickArea, handler(self, self.onClickTeamClickAreaHandler_), false)
    end

    -- update view
    local handlerList = VoProxy.EventBind(MAIN_PROXY_NAME, self.viewBindMap_, self)
    table.each(handlerList, function(_, v) v(self) end)
    self:updateChampionInfo_()
end


function ChampionshipFinalWinnerPopup:onCleanup()
    VoProxy.EventUnbind(MAIN_PROXY_NAME, self.viewBindMap_, self)
end


function ChampionshipFinalWinnerPopup:getViewData()
    return self.viewData
end


-------------------------------------------------
-- private

function ChampionshipFinalWinnerPopup:updateChampionInfo_()
    local championId     = self.mainProxy_:get(MAIN_PROXY_STRUCT.CHAMPION_PLAYER_SEND.PLAYER_ID)
    local PLAYERS_STRUCT = MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.PROMOTION_PLAYERS
    local playerProxy    = self.mainProxy_:get(PLAYERS_STRUCT.PLAYER_DATA, tostring(championId))
    local playerName     = playerProxy:get(PLAYERS_STRUCT.PLAYER_DATA.NAME)
    local playerUnion    = playerProxy:get(PLAYERS_STRUCT.PLAYER_DATA.UNION)
    local playerAvatar   = playerProxy:get(PLAYERS_STRUCT.PLAYER_DATA.AVATAR)
    local playerFrame    = playerProxy:get(PLAYERS_STRUCT.PLAYER_DATA.FRAME)
    local playerLevel    = playerProxy:get(PLAYERS_STRUCT.PLAYER_DATA.LEVEL)
    local unionText      = string.len(playerUnion) > 0 and string.fmt(__('工会：_name_'), {_name_ = playerUnion}) or ''
    self:getViewData().playerNameLabel:updateLabel({text = playerName})
    self:getViewData().playerUnionLabel:updateLabel({text = unionText})
    self:getViewData().playerHeadNode:RefreshUI({
        playerId    = championId,
        avatar      = playerAvatar,
        avatarFrame = playerFrame,
        playerLevel = playerLevel,
    })
end


-------------------------------------------------
-- handler

function ChampionshipFinalWinnerPopup:onUpdateChampionTeam_(signal)
    -- update opponent promotionTeam
    for teamIndex, teamVDList in ipairs(self:getViewData().teamVDList) do
        local teamPower = 0
        for cardIndex, cardHand in ipairs(teamVDList.cardHandList) do
            local CARD_DETAIL_STRUCT = MAIN_PROXY_STRUCT.CHAMPION_PLAYER_TAKE['TEAM' .. teamIndex].CARD_DETAIL
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


function ChampionshipFinalWinnerPopup:onClickTeamClickAreaHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local teamIndex      = checkint(sender:getTag())
    local TEAM_STRUCT    = MAIN_PROXY_STRUCT.CHAMPION_PLAYER_TAKE['TEAM' .. teamIndex]
    local PLAYERS_STRUCT = MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.PROMOTION_PLAYERS
    local championId     = self.mainProxy_:get(MAIN_PROXY_STRUCT.CHAMPION_PLAYER_SEND.PLAYER_ID)
    local playerProxy    = self.mainProxy_:get(PLAYERS_STRUCT.PLAYER_DATA, tostring(championId))
    local playerName     = playerProxy:get(PLAYERS_STRUCT.PLAYER_DATA.NAME)
    local playerUnion    = playerProxy:get(PLAYERS_STRUCT.PLAYER_DATA.UNION)
    local playerAvatar   = playerProxy:get(PLAYERS_STRUCT.PLAYER_DATA.AVATAR)
    local playerFrame    = playerProxy:get(PLAYERS_STRUCT.PLAYER_DATA.FRAME)
    local playerLevel    = playerProxy:get(PLAYERS_STRUCT.PLAYER_DATA.LEVEL)
    app.uiMgr:AddDialog('common.PreviewTeamDetailPopup', {
        playerId = playerId,
        name     = playerName,
        union    = playerUnion,
        avatar   = playerAvatar,
        frame    = playerFrame,
        level    = playerLevel,
        teamData = self.mainProxy_:get(TEAM_STRUCT):getData(),
    })
end


-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function ChampionshipFinalWinnerPopup.CreateView()
    local size = cc.size(1000, 500)
    local view = ui.layer({size = size})
    local cpos = cc.sizep(size, ui.cc)

    -- layer [block | team | info]
    local layerGroup = view:addList({
        ui.layer({size = size, color = cc.r4b(0), enable = true}),
        ui.layer({bg = RES_DICT.TEAM_BG, size = cc.size(900,470), scale9 = true, ml = 150}),
        ui.layer({bg = RES_DICT.INFO_BG, mr = 300, mb = 30}),
    })
    ui.flowLayout(cpos, layerGroup, {type = ui.flowC, ap = ui.cc})


    -- title | gap | line1 | playerLayer | line2
    local infoLayer = layerGroup[3]
    local infoGroup = infoLayer:addList({
        ui.title({n = RES_DICT.TITLE_FRAME, cut = cc.dir(50,5,50,5), size = cc.size(200,50)}):updateLabel({fnt = FONT.D19, fontSize = 24, text = __('本届优胜者'), paddingW = 50}),
        ui.layer({size = cc.size(0, 5)}),
        ui.image({img = RES_DICT.INFO_LINE1, mb = -12}),
        ui.layer({bg = RES_DICT.INFO_FRAME, scale9 = true, size = cc.size(300,230), alpha = 100}),
        ui.image({img = RES_DICT.INFO_LINE2, mt = -12}),
    })
    ui.flowLayout(cc.rep(cc.sizep(infoLayer, ui.cc), 0, 15), infoGroup, {type = ui.flowV, ap = ui.cc})


    -- playerLayer
    local playerLayer = infoGroup[4]
    local playerGroup = playerLayer:addList({
        ui.playerHeadNode({scale = 0.7}),
        ui.label({fnt = FONT.D1, color = '#933D2c', fontSize = 24}),
        ui.label({fnt = FONT.D3, color = '#C89B79', mt = 10}),
    })
    ui.flowLayout(cc.rep(cc.sizep(playerLayer, ui.cc), 0, 5), playerGroup, {type = ui.flowV, ap = ui.cc, gapH = 25})
    playerLayer:addList(ui.image({img = RES_DICT.WINNER_ICON})):alignTo(playerGroup[1], ui.cc, {offsetX = -50, offsetY = 50})
    playerLayer.bg:setOpacity(150)


    -- teamLayer
    local teamLayer = layerGroup[2]
    local teamNodes  = {}
    local teamVDList = {}
    for teamIndex = 1, 3 do
        teamVDList[teamIndex] = ChampionshipFinalWinnerPopup.CreateTeamView(teamIndex)
        teamNodes[teamIndex]  = teamVDList[teamIndex].view
    end
    teamLayer:addList(teamNodes)
    ui.flowLayout(cc.rep(cc.sizep(teamLayer, ui.lc), 280, 0), teamNodes, {type = ui.flowV, ap = ui.lc})

    return {
        view             = view,
        playerHeadNode   = playerGroup[1],
        playerNameLabel  = playerGroup[2],
        playerUnionLabel = playerGroup[3],
        teamVDList       = teamVDList,
    }
end


function ChampionshipFinalWinnerPopup.CreateTeamView(teamIndex, isRight)
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


return ChampionshipFinalWinnerPopup
