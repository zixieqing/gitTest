--[[
 * author : kaishiqi
 * descpt : 武道会 - 投票竞猜视图
]]
local ChampionshipScheduleNode  = require('Game.views.championship.ChampionshipScheduleNode')
local ChampionshipVoteGuessView = class('ChampionshipVoteGuessView', function()
    return ui.layer({name = 'Game.views.championship.ChampionshipVoteGuessView', enableEvent = true})
end)

local RES_DICT = {
    FUNCITON_FRAME = _res('ui/championship/auditions/budo_bg_common_list.png'),
    GUESS_LOG_BTN  = _res('ui/championship/guess/budo_ico_common_report.png'),
    SHOP_BTN       = _res('ui/championship/auditions/budo_ico_common_shop.png'),
    TIME_FRAME     = _res('ui/championship/guess/budo_ticket_bg_time.png'),
}

local ACTION_ENUM = {
    RELOAD_HOME_DATA  = 1,
}

local MAIN_PROXY_NAME   = FOOD.CHAMPIONSHIP.MAIN.PROXY_NAME
local MAIN_PROXY_STRUCT = FOOD.CHAMPIONSHIP.MAIN.PROXY_STRUCT


function ChampionshipVoteGuessView:ctor(args)
    -- create view
    self.viewData_ = ChampionshipVoteGuessView.CreateView()
    self:addChild(self.viewData_.view)

    -- bind model
    self.mainProxy_   = app:RetrieveProxy(MAIN_PROXY_NAME)
    self.viewBindMap_ = {
        [MAIN_PROXY_STRUCT.MAIN_HOME_TAKE]               = self.onUpdateHomeData_,
        [MAIN_PROXY_STRUCT.REFRESH_COUNTDOWN]            = self.onUpdateRefreshTime_,
        [MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.SCHEDULE_STEP] = self.onUpdateScheduleStep_,
    }

    -- update view
    local handlerList = VoProxy.EventBind(MAIN_PROXY_NAME, self.viewBindMap_, self)
    table.each(handlerList, function(_, v) v(self) end)
end


function ChampionshipVoteGuessView:onCleanup()
    VoProxy.EventUnbind(MAIN_PROXY_NAME, self.viewBindMap_, self)
end


function ChampionshipVoteGuessView:getViewData()
    return self.viewData_
end


-------------------------------------------------
-- handler

function ChampionshipVoteGuessView:onUpdateRefreshTime_(signal)
    local leftSeconds = self.mainProxy_:get(MAIN_PROXY_STRUCT.REFRESH_COUNTDOWN)
    local refreshText = CommonUtils.getTimeFormatByType(leftSeconds, 3)
    self:getViewData().countdownLabel:updateLabel({text = string.fmt(__('剩余：_time_'), {_time_ = refreshText})})
end


function ChampionshipVoteGuessView:onUpdateScheduleStep_(signal)
    local scheduleStep  = self.mainProxy_:get(MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.SCHEDULE_STEP)
    local stepTitleFunc = FOOD.CHAMPIONSHIP.GUESS_TITLE[scheduleStep]
    self:getViewData().statusLabel:updateLabel({text = stepTitleFunc and stepTitleFunc() or '----'})
end


function ChampionshipVoteGuessView:onUpdateHomeData_(signal)
    local updateEventType = signal and signal:GetBody().eventType or VoProxy.EVENTS.CHANGE
    if updateEventType == VoProxy.EVENTS.CHANGE then

        if not self:getActionByTag(ACTION_ENUM.RELOAD_HOME_DATA) then
            self:runAction(cc.CallFunc:create(function()

                self:getViewData().scheduleNode:updateToScheduleStep()
                
            end)):setTag(ACTION_ENUM.RELOAD_HOME_DATA)
        end
        
    end
end


-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function ChampionshipVoteGuessView.CreateView()
    local view = ui.layer()
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    ------------------------------------------------- [center]
    local centerLayer = ui.layer()
    view:add(centerLayer)

    -- schedul node
    local scheduleNode = ChampionshipScheduleNode.new({type = FOOD.CHAMPIONSHIP.PLAYER_DETAIL.TYPE.VOTE})
    centerLayer:add(scheduleNode)


    ------------------------------------------------- [left]
    local leftLayer = ui.layer()
    view:add(leftLayer)

    local timeGroup = leftLayer:addList({
        ui.image({img = RES_DICT.TIME_FRAME, enable = true}),
        ui.label({fnt = FONT.D7, fontSize = 22, color = '#540E0E', ap = ui.lc, ml = 90, mb = 57}),
        ui.label({fnt = FONT.D9, fontSize = 20, color = '#B77F7F', ap = ui.lc, ml = 90, mb = 18}),
    })
    ui.flowLayout(cc.rep(cc.sizep(size, ui.lt), display.SAFE_L - 60, -170), timeGroup, {type = ui.flowC, ap = ui.lb})
    


    ------------------------------------------------- [right]
    local rightLayer = ui.layer()
    view:add(rightLayer)

    local rightFuncFrame = ui.image({img = RES_DICT.FUNCITON_FRAME, size = cc.size(200, 40 + 140*2), cut = cc.dir(30,30,30,30), ap = ui.ct})
    rightLayer:addList(rightFuncFrame):alignTo(nil, ui.rt, {offsetX = -display.SAFE_L, offsetY = -60})
    
    -- rightFunc group
    local rightFuncGroup = rightLayer:addList({
        ui.button({n = RES_DICT.SHOP_BTN}):updateLabel({fnt = FONT.D19, fontSize = 24, text = __('印记商店'), offset = cc.p(0,-50)}),
        ui.button({n = RES_DICT.GUESS_LOG_BTN}):updateLabel({fnt = FONT.D19, fontSize = 24, text = __('竞猜记录'), offset = cc.p(0,-50)}),
    })
    ui.flowLayout(cc.rep(rightFuncFrame, 0, -10), rightFuncGroup, {type = ui.flowV, ap = ui.cb})


    return {
        view           = view,
        --             = center
        scheduleNode   = scheduleNode,
        --             = left
        scheduleFrame  = timeGroup[1],
        statusLabel    = timeGroup[2],
        countdownLabel = timeGroup[3],
        --             = right
        shopBtn        = rightFuncGroup[1],
        guessLogBtn    = rightFuncGroup[2],
    }
end


return ChampionshipVoteGuessView
