--[[
 * author : kaishiqi
 * descpt : 武道会 - 休赛期视图
]]
local ChampionshipOffSeasonView = class('ChampionshipOffSeasonView', function()
    return ui.layer({name = 'Game.views.championship.ChampionshipOffSeasonView', enableEvent = true})
end)

local RES_DICT = {
    MATCH_TABLE    = _res('ui/championship/auditions/budo_bg_common_spine_table.png'),
    CLOSED_FRAME   = _res('ui/championship/closed/budo_bg_common_spine_drum.png'),
    COUNTDOWN_BAR  = _res('ui/championship/closed/budo_close_bg_drum_tip.png'),
    FLAG_BLUE      = _res('ui/championship/closed/budo_bg_common_spine_bule.png'),
    FLAG_RED       = _res('ui/championship/closed/budo_bg_common_spine_red.png'),
    NPC_IMAGE      = _res('ui/championship/closed/budo_bg_common_spine_npc.png'),
    DIALOGUE_FRAME = _res('arts/stage/ui/dialogue_bg_2.png'),
    FUNCITON_FRAME = _res('ui/championship/auditions/budo_bg_common_list.png'),
    CHAMPION_BTN   = _res('ui/championship/closed/budo_ico_common_win.png'),
    SCHEDULE_BTN   = _res('ui/championship/promotion/budo_ico_common_record.png'),
    SHOP_BTN       = _res('ui/championship/auditions/budo_ico_common_shop.png'),
}

local MAIN_PROXY_NAME   = FOOD.CHAMPIONSHIP.MAIN.PROXY_NAME
local MAIN_PROXY_STRUCT = FOOD.CHAMPIONSHIP.MAIN.PROXY_STRUCT


function ChampionshipOffSeasonView:ctor(args)
    -- create view
    self.viewData_ = ChampionshipOffSeasonView.CreateView()
    self:addChild(self.viewData_.view)

    -- bind model
    self.mainProxy_   = app:RetrieveProxy(MAIN_PROXY_NAME)
    self.viewBindMap_ = {
        [MAIN_PROXY_STRUCT.REFRESH_COUNTDOWN] = self.onUpdateRefreshTime_,
    }

    -- update view
    local handlerList = VoProxy.EventBind(MAIN_PROXY_NAME, self.viewBindMap_, self)
    table.each(handlerList, function(_, v) v(self) end)
    self:updateScheduleStep_()
    self:updateSeasonTitle_()
end


function ChampionshipOffSeasonView:onCleanup()
    VoProxy.EventUnbind(MAIN_PROXY_NAME, self.viewBindMap_, self)
end


function ChampionshipOffSeasonView:getViewData()
    return self.viewData_
end


-------------------------------------------------
-- private

function ChampionshipOffSeasonView:updateSeasonTitle_()
    local seasonId   = self.mainProxy_:get(MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.SEASON_ID)
    local seasonText = string.fmt(__('第_num_届凌云争锋'), {_num_ = seasonId + (FOOD.CHAMPIONSHIP.IS_XIAOBO_FIX() and 0 or 1)})
    self:getViewData().seasonLabel:updateLabel({text = seasonText})
end


function ChampionshipOffSeasonView:updateScheduleStep_()
    local statusText = __('开赛倒计时')
    self:getViewData().statusLabel:updateLabel({text = statusText})
end


-------------------------------------------------
-- handler

function ChampionshipOffSeasonView:onUpdateRefreshTime_(signal)
    local leftSeconds = self.mainProxy_:get(MAIN_PROXY_STRUCT.REFRESH_COUNTDOWN)
    local refreshText = CommonUtils.getTimeFormatByType(leftSeconds, 3)
    self:getViewData().countdownLabel:updateLabel({text = tostring(refreshText)})
end


-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function ChampionshipOffSeasonView.CreateView()
    local view = ui.layer()
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    ------------------------------------------------- [center]
    local centerLayer = ui.layer()
    view:add(centerLayer)

    -- table | flag blue | flag red
    centerLayer:add(ui.image({p = cc.rep(cpos, 0, -55), img = RES_DICT.MATCH_TABLE, ap = ui.ct}))
    centerLayer:add(ui.image({p = cc.rep(cc.sizep(size, ui.lc), display.SAFE_L - 60, 60), img = RES_DICT.FLAG_BLUE, ap = ui.lb}))
    centerLayer:add(ui.image({p = cc.rep(cc.sizep(size, ui.rc), -display.SAFE_L + 60, 60), img = RES_DICT.FLAG_RED, ap = ui.rb}))

    
    -- closedFrame | countdownBar | seasonLabel | statusLabel | countdownLabel
    local closedGroup = centerLayer:addList({
        ui.image({img = RES_DICT.CLOSED_FRAME}),
        ui.image({img = RES_DICT.COUNTDOWN_BAR, mt = 30}),
        ui.label({fnt = FONT.D19, fontSize = 30, mb = 52}),
        ui.label({fnt = FONT.D16, fontSize = 24, mt = 14}),
        ui.label({fnt = FONT.D16, fontSize = 24, mt = 46, color = '#540e0e'}),
    })
    ui.flowLayout(cc.rep(cpos, 200, 0), closedGroup, {type = ui.flowC, ap = ui.cc})


    -- npc | dialogue | text
    local npcGroup = centerLayer:addList({
        ui.image({img = RES_DICT.NPC_IMAGE}),
        ui.image({img = RES_DICT.DIALOGUE_FRAME, ml = 380, mt = 100}),
        ui.label({fnt = FONT.D3, color = '#540E0E', ml = 380, mt = 100, w = 320}),
    })
    ui.flowLayout(cc.rep(cpos, -330, -130), npcGroup, {type = ui.flowC, ap = ui.cc})
    npcGroup[3]:updateLabel({text = __('现在休馆中')})


    ------------------------------------------------- [right]
    local rightLayer = ui.layer()
    view:add(rightLayer)

    local rightFuncFrame = ui.image({img = RES_DICT.FUNCITON_FRAME, size = cc.size(200, 40 + 140*3), cut = cc.dir(30,30,30,30), ap = ui.ct})
    rightLayer:addList(rightFuncFrame):alignTo(nil, ui.rt, {offsetX = -display.SAFE_L, offsetY = -60})
    
    -- rightFunc group
    local rightFuncGroup = rightLayer:addList({
        ui.button({n = RES_DICT.SHOP_BTN}):updateLabel({fnt = FONT.D19, fontSize = 24, text = __('印记商店'), offset = cc.p(0,-50)}),
        ui.button({n = RES_DICT.CHAMPION_BTN}):updateLabel({fnt = FONT.D19, fontSize = 24, text = __('优胜榜单'), offset = cc.p(0,-50)}),
        ui.button({n = RES_DICT.SCHEDULE_BTN}):updateLabel({fnt = FONT.D19, fontSize = 24, text = __('查看赛程'), offset = cc.p(0,-50)}),
    })
    ui.flowLayout(cc.rep(rightFuncFrame, 0, -10), rightFuncGroup, {type = ui.flowV, ap = ui.cb})


    return {
        view           = view,
        --             = center
        seasonLabel    = closedGroup[3],
        statusLabel    = closedGroup[4],
        countdownLabel = closedGroup[5],
        --             = right
        shopBtn        = rightFuncGroup[1],
        championBtn    = rightFuncGroup[2],
        scheduleBtn    = rightFuncGroup[3],
    }
end


return ChampionshipOffSeasonView
