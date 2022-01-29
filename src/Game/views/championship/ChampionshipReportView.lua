--[[
 * author : kaishiqi
 * descpt : 武道会 - 战报视图
]]
local ChampionshipReportView = class('ChampionshipReportView', function()
    return ui.layer({name = 'Game.views.championship.ChampionshipReportView', enableEvent = true})
end)

local RES_DICT = {
    VIEW_FRAME   = _res('ui/championship/report/budo_pvp_bg_report.png'),
    EMPTY_TITLE  = _res('ui/common/common_bg_float_text.png'),
    EMPTY_IMG    = _res('ui/championship/report/budo_ticket_bg_report_nothing.png'),
    --           = cell
    CELL_FRAME_N = _res('ui/championship/report/budo_pvp_bg_report_list_grey.png'),
    CELL_FRAME_D = _res('ui/championship/report/budo_pvp_bg_report_list.png'),
    CELL_FRAME_S = _res('ui/championship/report/budo_pvp_btn_report_list_top.png'),
    TITLE_BAR_N  = _res('ui/championship/report/budo_pvp_bg_time_list.png'),
    TITLE_BAR_D  = _res('ui/championship/report/budo_pvp_bg_time_list_grey.png'),
    MATCH_BAR_N  = _res('ui/championship/report/budo_pvp_line_report_list_red.png'),
    MATCH_BAR_D  = _res('ui/championship/report/budo_pvp_line_report_list_grey_.png'),
    LOST_ICON    = _res('ui/championship/report/pvp_report_ico_defeat.png'),
    REPLAY_BTN   = _res('ui/championship/report/starplan_vs_btn_playback_small.png'),
    VS_ICON_N    = _res('ui/championship/report/starplan_vs_icon_vs_small.png'),
    VS_ICON_D    = _res('ui/championship/report/starplan_vs_icon_vs_lost.png'),
    GUESS_BG_N   = _res('ui/championship/report/budo_ticket_bg_report_money.png'),
    GUESS_BG_D   = _res('ui/championship/report/budo_ticket_bg_report_money_grey.png'),
}

local ACTION_ENUM = {
    RELOAD_REPORT = 1,
}

local MAIN_PROXY_NAME     = FOOD.CHAMPIONSHIP.MAIN.PROXY_NAME
local MAIN_PROXY_STRUCT   = FOOD.CHAMPIONSHIP.MAIN.PROXY_STRUCT
local REPORT_PROXY_NAME   = FOOD.CHAMPIONSHIP.REPORT.PROXY_NAME
local REPORT_PROXY_STRUCT = FOOD.CHAMPIONSHIP.REPORT.PROXY_STRUCT


function ChampionshipReportView:ctor(args)
    -- create view
    self.viewData_ = ChampionshipReportView.CreateView()
    self:addChild(self.viewData_.view)

    -- init view
    self:getViewData().reportTableView:setCellUpdateHandler(handler(self, self.onUpdateReportCellHandler_))

    -- bind model
    self.mainProxy_   = app:RetrieveProxy(MAIN_PROXY_NAME)
    self.reportProxy_ = app:RetrieveProxy(REPORT_PROXY_NAME)
    self.viewBindMap_  = {
        [REPORT_PROXY_STRUCT.PROMOTION_MATCHES] = self.onUpdateReportTableView_, -- clean all / update all
    }

    -- update view
    local handlerList = VoProxy.EventBind(REPORT_PROXY_NAME, self.viewBindMap_, self)
    table.each(handlerList, function(_, v) v(self) end)
    self:updateReportTitle_()
end


function ChampionshipReportView:onCleanup()
    VoProxy.EventUnbind(REPORT_PROXY_NAME, self.viewBindMap_, self)
end


function ChampionshipReportView:getViewData()
    return self.viewData_
end


-------------------------------------------------
-- private

function ChampionshipReportView:updateReportTitle_()
    local titleText  = ''
    local emptyText  = ''
    local reportType = self.reportProxy_:get(REPORT_PROXY_STRUCT.REPORT_TYPE)
    if reportType == FOOD.CHAMPIONSHIP.REPORT.TYPE.BATTLE then
        titleText = __('比赛记录')
        emptyText = __('暂无记录')
    elseif reportType == FOOD.CHAMPIONSHIP.REPORT.TYPE.GUESS then
        titleText = __('竞猜记录')
        emptyText = __('尚未投票')
    end
    self:getViewData().titleBar:updateLabel({text = titleText})
    self:getViewData().emptyLabel:updateLabel({text = emptyText})
end


-------------------------------------------------
-- handler

function ChampionshipReportView:onUpdateReportTableView_(signal)
    -- reload goodsGridView （当同一时间填充多条数据时，会导致的连续触发刷新。所以action动作能保证在下一帧时直接刷新最终结果）
    if not self:getActionByTag(ACTION_ENUM.RELOAD_REPORT) then
        self:runAction(cc.CallFunc:create(function()
            local reportCount = self.reportProxy_:size(REPORT_PROXY_STRUCT.PROMOTION_MATCHES)
            self:getViewData().reportTableView:resetCellCount(reportCount, false, true)
            self:getViewData().reportEmptyLayer:setVisible(reportCount <= 0)
        end)):setTag(ACTION_ENUM.RELOAD_REPORT)
    end
end


function ChampionshipReportView:onUpdateReportCellHandler_(cellIndex, cellViewData)
    if cellViewData == nil then return end

    -- get cell data
    local CELL_STRUCT = REPORT_PROXY_STRUCT.PROMOTION_MATCHES.MATCH_ID
    local cellMatchId = self.reportProxy_:get(CELL_STRUCT, cellIndex)
    local reportType  = self.reportProxy_:get(REPORT_PROXY_STRUCT.REPORT_TYPE)

    -- update tag
    cellViewData.view:setTag(cellIndex)
    cellViewData.replayBtn:setTag(cellIndex)

    --
    local scheduleStep    = self.mainProxy_:get(MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.SCHEDULE_STEP)
    local SCHEDULE_STRUCT = MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.PROMOTION_SCHEDULE
    local matchDataProxy  = self.mainProxy_:get(SCHEDULE_STRUCT.MATCH_DATA, tostring(cellMatchId))
    local matchAttackerId = matchDataProxy:get(SCHEDULE_STRUCT.MATCH_DATA.ATTACKER_ID)
    local matchDefenderId = matchDataProxy:get(SCHEDULE_STRUCT.MATCH_DATA.DEFENDER_ID)
    local matchWinnerId   = matchDataProxy:get(SCHEDULE_STRUCT.MATCH_DATA.WINNER_ID)
    local PLAYERS_STRUCT  = MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.PROMOTION_PLAYERS
    local attackerProxy   = self.mainProxy_:get(PLAYERS_STRUCT.PLAYER_DATA, tostring(matchAttackerId))
    local defenderProxy   = self.mainProxy_:get(PLAYERS_STRUCT.PLAYER_DATA, tostring(matchDefenderId))
    local GUESS_STRUCT    = MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.GUESS_DETAIL
    local guessDataProxy  = self.mainProxy_:get(GUESS_STRUCT.GUESS_DATA, tostring(cellMatchId))
    local guessPlayerId   = guessDataProxy:get(GUESS_STRUCT.GUESS_DATA.PLAYER_ID)
    local guessMoneyNum   = guessDataProxy:get(GUESS_STRUCT.GUESS_DATA.GUESS_NUM)
    local isNotStarted    = cellMatchId > scheduleStep
    local isAttackerWin   = isNotStarted or matchAttackerId == matchWinnerId
    local isDefenderWin   = isNotStarted or matchDefenderId == matchWinnerId
    local selfPlayerId    = app.gameMgr:GetPlayerId()
    
    -- update attacker info
    local attackerName = attackerProxy:get(PLAYERS_STRUCT.PLAYER_DATA.NAME)
    cellViewData.attackerLost:setVisible(not isAttackerWin)
    cellViewData.attackerName:updateLabel({text = attackerName, maxW = 110, color = isAttackerWin and '#654130' or '#686868'})
    cellViewData.attackerHead:setColor(isAttackerWin and cc.c3b(255,255,255) or cc.c3b(100,100,100))
    cellViewData.attackerHead:RefreshUI({
        avatar      = matchAttackerId > 0 and attackerProxy:get(PLAYERS_STRUCT.PLAYER_DATA.AVATAR) or 500375,
        avatarFrame = matchAttackerId > 0 and attackerProxy:get(PLAYERS_STRUCT.PLAYER_DATA.FRAME) or 0,
        playerLevel = matchAttackerId > 0 and attackerProxy:get(PLAYERS_STRUCT.PLAYER_DATA.LEVEL) or 0,
        showLevel   = matchAttackerId > 0,
    })

    -- update defender info
    local defenderName = defenderProxy:get(PLAYERS_STRUCT.PLAYER_DATA.NAME)
    cellViewData.defenderLost:setVisible(not isDefenderWin)
    cellViewData.defenderName:updateLabel({text = defenderName, maxW = 110, color = isDefenderWin and '#654130' or '#686868'})
    cellViewData.defenderHead:setColor(isDefenderWin and cc.c3b(255,255,255) or cc.c3b(100,100,100))
    cellViewData.defenderHead:RefreshUI({
        avatar      = matchDefenderId > 0 and defenderProxy:get(PLAYERS_STRUCT.PLAYER_DATA.AVATAR) or 500375,
        avatarFrame = matchDefenderId > 0 and defenderProxy:get(PLAYERS_STRUCT.PLAYER_DATA.FRAME) or 0,
        playerLevel = matchDefenderId > 0 and defenderProxy:get(PLAYERS_STRUCT.PLAYER_DATA.LEVEL) or 0,
        showLevel   = matchDefenderId > 0,
    })

    
    if reportType == FOOD.CHAMPIONSHIP.REPORT.TYPE.BATTLE then
        local roundTitleText  = ''
        for roundNum, stepDefine in ipairs(FOOD.CHAMPIONSHIP.ROUND_NUM) do
            local beganStep = checkint(stepDefine.beganStep)
            local endedStep = checkint(stepDefine.endedStep)
            if beganStep <= cellMatchId and cellMatchId <= endedStep then
                roundTitleText = stepDefine.getTitle()
                break
            end
        end
        cellViewData.vsDisable:setVisible(false)
        cellViewData.guessLayer:setVisible(false)

        if isNotStarted then
            -- frame
            cellViewData.frameSelect:setVisible(true)
            cellViewData.frameNormal:setVisible(false)
            cellViewData.frameDisable:setVisible(false)
            -- title
            cellViewData.titleNormal:setVisible(true)
            cellViewData.titleDisable:setVisible(false)
            cellViewData.titleLabel:updateLabel({text = roundTitleText, color = '#6C2923'})
            -- match
            cellViewData.matchNormal:setVisible(true)
            cellViewData.matchDisable:setVisible(false)
            -- other
            cellViewData.vsNormal:setVisible(true)
            cellViewData.replayBtn:setVisible(false)
            cellViewData.stateLabel:updateLabel({text = __('未开始'), color = '#C6A083'})

        else
            local isWin = matchWinnerId == selfPlayerId
            -- frame
            cellViewData.frameSelect:setVisible(false)
            cellViewData.frameNormal:setVisible(isWin)
            cellViewData.frameDisable:setVisible(not isWin)
            -- title
            cellViewData.titleNormal:setVisible(isWin)
            cellViewData.titleDisable:setVisible(not isWin)
            cellViewData.titleLabel:updateLabel({text = roundTitleText, color = isWin and '#6C2923' or '#363636'})
            -- match
            cellViewData.matchNormal:setVisible(isWin)
            cellViewData.matchDisable:setVisible(not isWin)
            -- other
            cellViewData.vsNormal:setVisible(false)
            cellViewData.replayBtn:setVisible(true)
            cellViewData.stateLabel:updateLabel({text = isWin and __('胜利') or __('失败'), color = isWin and '#F06332' or '#686868'})
        end


    elseif reportType == FOOD.CHAMPIONSHIP.REPORT.TYPE.GUESS then
        local stepTitleFunc  = FOOD.CHAMPIONSHIP.GUESS_TITLE[cellMatchId - 1]
        local roundTitleText = stepTitleFunc and stepTitleFunc() or '----'
        cellViewData.replayBtn:setVisible(false)

        if isNotStarted then
            -- frame
            cellViewData.frameSelect:setVisible(true)
            cellViewData.frameNormal:setVisible(false)
            cellViewData.frameDisable:setVisible(false)
            -- title
            cellViewData.titleNormal:setVisible(true)
            cellViewData.titleDisable:setVisible(false)
            cellViewData.titleLabel:updateLabel({text = roundTitleText, color = '#6C2923'})
            -- match
            cellViewData.matchNormal:setVisible(true)
            cellViewData.matchDisable:setVisible(false)
            -- other
            cellViewData.vsNormal:setVisible(true)
            cellViewData.vsDisable:setVisible(false)
            cellViewData.guessLayer:setVisible(false)
            cellViewData.stateLabel:updateLabel({text = __('未开始'), color = '#C6A083'})

        else
            local isWin = matchWinnerId == guessPlayerId
            -- frame
            cellViewData.frameSelect:setVisible(false)
            cellViewData.frameNormal:setVisible(isWin)
            cellViewData.frameDisable:setVisible(not isWin)
            -- title
            cellViewData.titleNormal:setVisible(isWin)
            cellViewData.titleDisable:setVisible(not isWin)
            cellViewData.titleLabel:updateLabel({text = roundTitleText, color = isWin and '#6C2923' or '#363636'})
            -- match
            cellViewData.matchNormal:setVisible(isWin)
            cellViewData.matchDisable:setVisible(not isWin)
            -- other
            cellViewData.vsNormal:setVisible(isWin)
            cellViewData.vsDisable:setVisible(not isWin)
            cellViewData.guessLayer:setVisible(true)
            cellViewData.stateLabel:updateLabel({text = isWin and __('已猜中') or __('未猜中'), color = isWin and '#F06332' or '#686868'})
            -- guess
            cellViewData.guessNormal:setVisible(isWin)
            cellViewData.guessDisable:setVisible(not isWin)
            cellViewData.guessResult:updateLabel({text = isWin and __('获得') or __('失去'), color = isWin and '#A4472D' or '#686868'})
            cellViewData.guessMoney:reload({
                {fnt = FONT.D12, color = isWin and '#FFFFFF' or '#DEDEDE', text = string.fmt('%1%2  ', isWin and '+' or '-', guessMoneyNum)},
                {img = GoodsUtils.GetIconPathById(FOOD.GOODS.DEFINE.CHAMPIONSHIP_CURRENCY_ID), scale = 0.15}
            })
        end
    end
end


-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function ChampionshipReportView.CreateView()
    local view = ui.layer()
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    -- black / block layer
    local backGroundGroup = view:addList({
        ui.layer({color = cc.c4b(0,0,0,150)}),
        ui.layer({color = cc.r4b(0), enable = true}),
    })


    ------------------------------------------------- [top]
    local topLayer = ui.layer()
    view:add(topLayer)

    -- back button
    local backBtn = ui.button({n = RES_DICT.BACK_BTN})
    topLayer:addList(backBtn):alignTo(nil, ui.lt, {offsetX = display.SAFE_L + 30, offsetY = -15})


    ------------------------------------------------- [center]
    local centerLayer = ui.layer()
    view:add(centerLayer)

    -- view frame
    local viewFrameNode = ui.layer({p = cpos, bg = RES_DICT.VIEW_FRAME, ap = ui.cc, enable = true})
    local viewFrameSize = viewFrameNode:getContentSize()
    centerLayer:add(viewFrameNode)

    
    -- title bar
    local titleBar = ui.label({fnt = FONT.D14, text = __('报告')})
    viewFrameNode:addList(titleBar):alignTo(nil, ui.ct, {offsetY = -70})


    -- report group
    local reportSize  = cc.resize(viewFrameSize, -40, -140)
    local reportGroup = centerLayer:addList({
        ui.tableView({size = cc.resize(reportSize, -8, -8), dir = display.SDIR_V, csizeH = 210}),
        ui.layer({size = reportSize}),
    })
    ui.flowLayout(cc.rep(cpos, 2, -30), reportGroup, {type = ui.flowC, ap = ui.cc})
    reportGroup[1]:setCellCreateHandler(ChampionshipReportView.CreateReportCell)


    -- empty group
    local reportEmptyLayer = reportGroup[2]
    local reportEmptyGroup = reportEmptyLayer:addList({
        ui.title({img = RES_DICT.EMPTY_TITLE}):updateLabel({fnt = FONT.D18, text = __('暂无记录')}),
        ui.image({img = RES_DICT.EMPTY_IMG}),
    })
    ui.flowLayout(cc.sizep(reportEmptyLayer, ui.cc), reportEmptyGroup, {type = ui.flowV, ap = ui.cc})


    return {
        view             = view,
        titleBar         = titleBar,
        blackLayer       = backGroundGroup[1],
        blockLayer       = backGroundGroup[2],
        --               = center
        reportTableView  = reportGroup[1],
        reportEmptyLayer = reportEmptyLayer,
        emptyLabel       = reportEmptyGroup[1],
    }
end


function ChampionshipReportView.CreateReportCell(cellParent)
    local view = cellParent
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    -- frame [normal | disable | select]
    local frameGroup = view:addList({
        ui.image({img = RES_DICT.CELL_FRAME_D}),
        ui.image({img = RES_DICT.CELL_FRAME_N}),
        ui.image({img = RES_DICT.CELL_FRAME_S}),
    })
    ui.flowLayout(cpos, frameGroup, {type = ui.flowC, ap = ui.cc})
    
    -- title [normal | disable | label]
    local titleGroup = view:addList({
        ui.image({img = RES_DICT.TITLE_BAR_N}),
        ui.image({img = RES_DICT.TITLE_BAR_D}),
        ui.label({fnt = FONT.D3, ap = ui.lt, ml = 8, mt = 8}),
    })
    ui.flowLayout(cc.rep(cc.sizep(size, ui.lt), 10, -12), titleGroup, {type = ui.flowC, ap = ui.lt})
    
    -- matchBar [normal | disable]
    local matchGroup = view:addList({
        ui.image({img = RES_DICT.MATCH_BAR_N}),
        ui.image({img = RES_DICT.MATCH_BAR_D}),
    })
    ui.flowLayout(cpos, matchGroup, {type = ui.flowC, ap = ui.cc})

    -- attacker [headNode | lostIcon | nameLabel]
    local attackerGroup = view:addList({
        ui.playerHeadNode({scale = 0.6, showLevel = true}),
        ui.image({img = RES_DICT.LOST_ICON}),
        ui.label({fnt = FONT.D6, mt = 70}),
    })
    ui.flowLayout(cc.rep(cpos, -170, 0), attackerGroup, {type = ui.flowC, ap = ui.cc})

    -- defender [headNode | lostIcon | nameLabel]
    local defenderGroup = view:addList({
        ui.playerHeadNode({scale = 0.6, showLevel = true}),
        ui.image({img = RES_DICT.LOST_ICON}),
        ui.label({fnt = FONT.D6, mt = 70}),
    })
    ui.flowLayout(cc.rep(cpos, 170, 0), defenderGroup, {type = ui.flowC, ap = ui.cc})

    -- center [normalVs | disableVs | replayBtn | stateLabel]
    local centerGroup = view:addList({
        ui.image({img = RES_DICT.VS_ICON_N}),
        ui.image({img = RES_DICT.VS_ICON_D}),
        ui.button({n = RES_DICT.REPLAY_BTN}),
        ui.label({fnt = FONT.D1, fontSize = 24, mb = 65}),
    })
    ui.flowLayout(cpos, centerGroup, {type = ui.flowC, ap = ui.cc})

    -- guessLayer
    local guessLayer = ui.layer({size = size})
    view:add(guessLayer)

    -- guess [normalBg | disableBg | resultLabel | moneyRLabel]
    local guessGroup = guessLayer:addList({
        ui.image({img = RES_DICT.GUESS_BG_N}),
        ui.image({img = RES_DICT.GUESS_BG_D}),
        ui.label({fnt = FONT.D1, fontSize = 22, mb = 12}),
        ui.rLabel({mt = 13}),
    })
    ui.flowLayout(cc.rep(cpos, 0, -55), guessGroup, {type = ui.flowC, ap = ui.cc})
    
    return {
        view         = view,
        frameNormal  = frameGroup[1],
        frameDisable = frameGroup[2],
        frameSelect  = frameGroup[3],
        titleNormal  = titleGroup[1],
        titleDisable = titleGroup[2],
        titleLabel   = titleGroup[3],
        matchNormal  = matchGroup[1],
        matchDisable = matchGroup[2],
        attackerHead = attackerGroup[1],
        attackerLost = attackerGroup[2],
        attackerName = attackerGroup[3],
        defenderHead = defenderGroup[1],
        defenderLost = defenderGroup[2],
        defenderName = defenderGroup[3],
        vsNormal     = centerGroup[1],
        vsDisable    = centerGroup[2],
        replayBtn    = centerGroup[3],
        stateLabel   = centerGroup[4],
        guessLayer   = guessLayer,
        guessNormal  = guessGroup[1],
        guessDisable = guessGroup[2],
        guessResult  = guessGroup[3],
        guessMoney   = guessGroup[4],
    }
end


return ChampionshipReportView
