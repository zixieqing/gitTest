--[[
 * author : kaishiqi
 * descpt : 武道会 - 历届冠军视图
]]
local ChampionshipHistoryChampionView = class('ChampionshipHistoryChampionView', function()
    return ui.layer({name = 'Game.views.championship.ChampionshipHistoryChampionView', enableEvent = true})
end)

local RES_DICT = {
    VIEW_FRAME  = _res('ui/championship/history/budo_close_bg_reward.png'),
    LIST_FRAME  = _res('ui/championship/history/budo_close_bg_reward_list.png'),
    EMPTY_IMG   = _res('ui/common/common_bg_dialogue_tips.png'),
    --          = cell
    CELL_FRAME  = _res('ui/championship/history/budo_close_bg_reward_list_ren.png'),
    CELL_TEAM   = _res('ui/championship/history/budo_close_bg_reward_list_leader.png'),
    CELL_TITLE  = _res('ui/championship/history/budo_close_bg_reward_list_head.png'),
    --          = team
    POPUP_FRAME = _res('ui/championship/history/budo_close_bg_reward_list_team.png'),
    LEADER_ICON = _res('ui/championship/auditions/team_ico_captain.png'),
    TEAM_FRAME  = _res('ui/tagMatch/3v3_ranks_bg.png'),
}

local ACTION_ENUM = {
    RELOAD_HISTORY = 1,
}

local HISTORY_PROXY_NAME   = FOOD.CHAMPIONSHIP.HISTORY.PROXY_NAME
local HISTORY_PROXY_STRUCT = FOOD.CHAMPIONSHIP.HISTORY.PROXY_STRUCT


function ChampionshipHistoryChampionView:ctor(args)
    -- create view
    self.viewData_ = ChampionshipHistoryChampionView.CreateView()
    self:addChild(self.viewData_.view)

    self.teamPopupVD_ = ChampionshipHistoryChampionView.CreateTeamPopup()
    self:addChild(self.teamPopupVD_.view)

    -- init view
    self:getViewData().historyTableView:setCellUpdateHandler(handler(self, self.onUpdateHistoryCellHandler_))

    -- bind model
    self.historyProxy_ = app:RetrieveProxy(HISTORY_PROXY_NAME)
    self.viewBindMap_  = {
        [HISTORY_PROXY_STRUCT.HISTORY_TAKE.PAGE_DATA]               = self.onUpdateHistoryTableView_, -- clean all / update all
        [HISTORY_PROXY_STRUCT.HISTORY_TAKE.PAGE_DATA.CHAMPION_DATA] = self.onUpdateHistoryTableView_, -- add key / del key
    }

    -- update view
    local handlerList = VoProxy.EventBind(HISTORY_PROXY_NAME, self.viewBindMap_, self)
    table.each(handlerList, function(_, v) v(self) end)
    self:hideTeamPopup()
end


function ChampionshipHistoryChampionView:onCleanup()
    VoProxy.EventUnbind(HISTORY_PROXY_NAME, self.viewBindMap_, self)
end


function ChampionshipHistoryChampionView:getViewData()
    return self.viewData_
end


function ChampionshipHistoryChampionView:getTeamPopupVD()
    return self.teamPopupVD_
end


-------------------------------------------------
-- public

function ChampionshipHistoryChampionView:hideTeamPopup()
    self:getTeamPopupVD().view:setVisible(false)
end
function ChampionshipHistoryChampionView:showTeamPopup(historyIndex)
    self:getTeamPopupVD().view:setVisible(true)

    local CELL_STRUCT = HISTORY_PROXY_STRUCT.HISTORY_TAKE.PAGE_DATA.CHAMPION_DATA
    local cellVoProxy = self.historyProxy_:get(CELL_STRUCT, historyIndex)
    for teamIndex, cardsList in ipairs(self:getTeamPopupVD().teamCardsList) do
        local TEAM_STRUCT  = CELL_STRUCT[string.fmt('TEAM%1_CARDS', teamIndex)]
        local teamCardList = TEAM_STRUCT and string.split2(cellVoProxy:get(TEAM_STRUCT), ',') or {}
        for cardIndex, cardHead in ipairs(cardsList) do
            local teamCardId = checkint(teamCardList[MAX_TEAM_MEMBER_AMOUNT - cardIndex + 1])
            cardHead:setVisible(teamCardId > 0)
            if teamCardId > 0 then
                cardHead:RefreshUI({cardData = {cardId = teamCardId}})
            end
        end
    end
end


-------------------------------------------------
-- handler

function ChampionshipHistoryChampionView:onUpdateHistoryTableView_(signal)
    -- reload goodsGridView （当同一时间填充多条数据时，会导致的连续触发刷新。所以action动作能保证在下一帧时直接刷新最终结果）
    if not self:getActionByTag(ACTION_ENUM.RELOAD_HISTORY) then
        self:runAction(cc.CallFunc:create(function()
            local historyCount = self.historyProxy_:size(HISTORY_PROXY_STRUCT.HISTORY_TAKE.PAGE_DATA)
            self:getViewData().historyTableView:resetCellCount(historyCount, false, true)
            self:getViewData().historyEmptyLayer:setVisible(historyCount <= 0)
        end)):setTag(ACTION_ENUM.RELOAD_HISTORY)
    end
end


function ChampionshipHistoryChampionView:onUpdateHistoryCellHandler_(cellIndex, cellViewData)
    if cellViewData == nil then return end

    -- get cell data
    local CELL_STRUCT = HISTORY_PROXY_STRUCT.HISTORY_TAKE.PAGE_DATA.CHAMPION_DATA
    local cellVoProxy = self.historyProxy_:get(CELL_STRUCT, cellIndex)

    -- update tag
    cellViewData.view:setTag(cellIndex)
    cellViewData.leaderHeadArea:setTag(cellIndex)
    
    -- update title
    local seasonId = cellVoProxy:get(CELL_STRUCT.SEASON_ID)
    cellViewData.titleBar:updateLabel({text = string.fmt(__('第_num_届优胜者'), {_num_ = seasonId - (FOOD.CHAMPIONSHIP.IS_XIAOBO_FIX() and 1 or 0)})})

    -- update playerInfo
    local playerId     = cellVoProxy:get(CELL_STRUCT.PLAYER_ID)
    local playerName   = cellVoProxy:get(CELL_STRUCT.PLAYER_NAME)
    local playerLevel  = cellVoProxy:get(CELL_STRUCT.PLAYER_LEVEL)
    local playerAvatar = cellVoProxy:get(CELL_STRUCT.PLAYER_AVATAR)
    local playerFrame  = cellVoProxy:get(CELL_STRUCT.PLAYER_FRAME)
    local playerUnion  = cellVoProxy:get(CELL_STRUCT.PLAYER_UNION)
    local unionText    = string.len(playerUnion) > 0 and string.fmt(__('工会：_name_'), {_name_ = playerUnion}) or ''
    cellViewData.playerNameLabel:updateLabel({text = playerName})
    cellViewData.unionNameLabel:updateLabel({text = unionText, maxW = 250})
    cellViewData.playerHeadNode:RefreshUI({
        playerId        = playerId,
        playerLevel     = playerLevel,
        avatar          = playerAvatar,
        avatarFrame     = playerFrame,
        defaultCallback = true,
    })
    
    -- update leaderHead
    for teamIndex, leaderHead in ipairs(cellViewData.leaderHeadList) do
        local TEAM_STRUCT  = CELL_STRUCT[string.fmt('TEAM%1_CARDS', teamIndex)]
        local teamCardList = TEAM_STRUCT and string.split2(cellVoProxy:get(TEAM_STRUCT), ',') or {}
        local leaderCardId = checkint(teamCardList[1])
        leaderHead:setVisible(leaderCardId > 0)
        if leaderCardId > 0 then
            leaderHead:RefreshUI({cardData = {cardId = leaderCardId}})
        end
    end

    -- updateCell callback
    if self.historyCellUpdatedCB then
        self.historyCellUpdatedCB(cellIndex)
    end
end


-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function ChampionshipHistoryChampionView.CreateView()
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
    local viewFrameNode = ui.layer({p = cpos, bg = RES_DICT.VIEW_FRAME, ap = ui.cc, enable = true})
    local viewFrameSize = viewFrameNode:getContentSize()
    centerLayer:add(viewFrameNode)


    -- history group
    local historySize  = cc.resize(viewFrameSize, -40, -80)
    local historyGroup = centerLayer:addList({
        ui.image({img = RES_DICT.LIST_FRAME, size = historySize, scale9 = true}),
        ui.tableView({size = cc.resize(historySize, -8, -8), dir = display.SDIR_V, csizeH = 220}),
        ui.layer({size = historySize}),
    })
    ui.flowLayout(cc.rep(cpos, 2, -20), historyGroup, {type = ui.flowC, ap = ui.cc})
    historyGroup[2]:setCellCreateHandler(ChampionshipHistoryChampionView.CreateHistoryCell)


    -- empty group
    local historyEmptyLayer = historyGroup[3]
    local historyEmptyGroup = historyEmptyLayer:addList({
        ui.title({img = RES_DICT.EMPTY_IMG, cut = cc.dir(135,10,65,92)}):updateLabel({fnt = FONT.D6, w = 220, text = __('暂无历届冠军记录'), paddingH = 40, hAlign = display.TAC}),
        ui.image({img = AssetsUtils.GetCartoonPath(3), scale = 0.45}),
    })
    ui.flowLayout(cc.sizep(historyEmptyLayer, ui.cc), historyEmptyGroup, {type = ui.flowH, ap = ui.cc})

    
    return {
        view              = view,
        blackLayer        = backGroundGroup[1],
        blockLayer        = backGroundGroup[2],
        --                = center
        historyTableView  = historyGroup[2],
        historyEmptyLayer = historyEmptyLayer,
    }
end


function ChampionshipHistoryChampionView.CreateHistoryCell(cellParent)
    local view = cellParent
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    view:add(ui.image({p = cc.rep(cpos, 0, -12), img = RES_DICT.CELL_FRAME}))

    -- title bar
    local titleBar = ui.title({img = RES_DICT.CELL_TITLE}):updateLabel({fnt = FONT.D19, fontSize = 24})
    view:addList(titleBar):alignTo(nil, ui.ct, {offsetY = 32})

    -- player group
    local playerGroup = view:addList({
        ui.playerHeadNode({showLevel = true, scale = 0.65}),
        ui.label({fnt = FONT.D8, fontSize = 22, ap = ui.lc, ml = 110, mb = 22}),
        ui.label({fnt = FONT.D13, fontSize = 22, ap = ui.lc, ml = 110, mt = 22}),
    })
    ui.flowLayout(cc.p(45, 75), playerGroup, {type = ui.flowC, ap = ui.lc})
    
    
    -- team group
    local teamGroup = view:addList({
        ui.image({img = RES_DICT.CELL_TEAM}),
        ui.layer({color = cc.r4b(0), size = cc.size(290, 105), enable = true}),
    })
    ui.flowLayout(cc.p(size.width - 185, 75), teamGroup, {type = ui.flowC, ap = ui.cc})


    -- leader head list
    local leaderHeadArea = teamGroup[2]
    local leaderHeadCPos = cc.sizep(leaderHeadArea, ui.cc)
    local leaderHeadList = {}
    local leaderIconList = {}
    for teamIndex = 1, 3 do
        leaderHeadList[teamIndex] = ui.cardHeadNode({scale = 0.45})
        leaderIconList[teamIndex] = ui.image({img = RES_DICT.LEADER_ICON})
    end
    leaderHeadArea:addList(leaderHeadList)
    leaderHeadArea:addList(leaderIconList)
    ui.flowLayout(cc.rep(leaderHeadCPos, 0, -8), leaderHeadList, {type = ui.flowH, ap = ui.cc, gapW = 8})
    ui.flowLayout(cc.rep(leaderHeadCPos, 0, 28), leaderIconList, {type = ui.flowH, ap = ui.cc, gapW = 8})
    
    return {
        view            = view,
        titleBar        = titleBar,
        leaderHeadArea  = leaderHeadArea,
        leaderHeadList  = leaderHeadList,
        playerHeadNode  = playerGroup[1],
        playerNameLabel = playerGroup[2],
        unionNameLabel  = playerGroup[3],
    }
end


function ChampionshipHistoryChampionView.CreateTeamPopup()
    local view = ui.layer()
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)
    
    -- black / block layer
    local backGroundGroup = view:addList({
        ui.layer({color = cc.c4b(0,0,0,50)}),
        ui.layer({color = cc.r4b(0), enable = true}),
    })

    ------------------------------------------------- [center]
    local centerLayer = ui.layer()
    view:add(centerLayer)

    -- view frame
    local viewFrameSize = cc.size(560, 500)
    local viewFrameNode = ui.layer({p = cpos, bg = RES_DICT.POPUP_FRAME, ap = ui.cc, size = viewFrameSize, scale9 = true})
    centerLayer:add(viewFrameNode)


    -- teamLayerList
    local teamCardsList = {}
    local teamLayerList = {}
    for teamIndex = 1, 3 do
        local cardHandList  = {}
        local teamLayerNode = ui.layer({bg = RES_DICT.TEAM_FRAME, ap = ui.cc})
        teamLayerList[teamIndex] = teamLayerNode
        teamCardsList[teamIndex] = cardHandList

        -- cardHandList
        for cardIndex = 1, MAX_TEAM_MEMBER_AMOUNT do
            cardHandList[cardIndex] = ui.cardHeadNode({scale = 0.45})
        end
        teamLayerNode:addList(cardHandList)
        ui.flowLayout(cc.p(22, 22), cardHandList, {type = ui.flowH, ap = ui.lb, gapW = 7})

        -- teamTitleLabel
        local teamTitleLabel = ui.label({fnt = FONT.D14, fontSize = 20, text = string.fmt(__('队伍_num_'), {_num_ = teamIndex})})
        teamLayerNode:addList(teamTitleLabel):alignTo(nil, ui.lt, {offsetX = 12, offsetY = -6})

        -- teamLeaderIcon
        local tealLeaderIcon = ui.image({img = RES_DICT.LEADER_ICON})
        teamLayerNode:addList(tealLeaderIcon):alignTo(cardHandList[MAX_TEAM_MEMBER_AMOUNT], ui.cc, {offsetY = 40})
    end
    viewFrameNode:addList(teamLayerList)
    ui.flowLayout(cc.sizep(viewFrameSize, ui.cc), teamLayerList, {type = ui.flowV, ap = ui.cc, gapH = 10})


    return {
        view          = view,
        blackLayer    = backGroundGroup[1],
        blockLayer    = backGroundGroup[2],
        --            = center
        teamCardsList = teamCardsList,
    }
end


return ChampionshipHistoryChampionView
