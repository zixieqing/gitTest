--[[
 * author : kaishiqi
 * descpt : 武道会 - 赛程视图
]]
local ChampionshipScheduleNode = require('Game.views.championship.ChampionshipScheduleNode')
local ChampionshipScheduleView = class('ChampionshipScheduleView', function()
    return ui.layer({name = 'Game.views.championship.ChampionshipScheduleView', enableEvent = true})
end)

local RES_DICT = {
    COM_BACK_BTN  = _res('ui/common/common_btn_back.png'),
    COM_TITLE_BAR = _res('ui/common/common_title.png'),
    COM_TIPS_ICON = _res('ui/common/common_btn_tips.png'),
    --            = center
    BG_IMAGE      = _res('ui/championship/home/budo_bg_common_bg.jpg'),
}


function ChampionshipScheduleView:ctor(args)
    -- create view
    self.viewData_ = ChampionshipScheduleView.CreateView()
    self:addChild(self.viewData_.view)
end


function ChampionshipScheduleView:getViewData()
    return self.viewData_
end


-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function ChampionshipScheduleView.CreateView()
    local view = ui.layer()
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    -- bg [img | black | block]
    local backGroundGroup = view:addList({
        ui.image({img = RES_DICT.BG_IMAGE, p = cpos}),
        ui.layer({color = cc.r4b(0), enable = true}),
    })

    ------------------------------------------------- [center]
    local centerLayer = ui.layer()
    view:add(centerLayer)

    -- schedul node
    local scheduleNode = ChampionshipScheduleNode.new({type = FOOD.CHAMPIONSHIP.PLAYER_DETAIL.TYPE.VIEW})
    centerLayer:add(scheduleNode)


    ------------------------------------------------- [top]
    local topLayer = ui.layer()
    view:add(topLayer)

    -- back button
    local backBtn = ui.button({n = RES_DICT.COM_BACK_BTN})
    topLayer:addList(backBtn):alignTo(nil, ui.lt, {offsetX = display.SAFE_L + 30, offsetY = -15})

    -- title button
    local titleBtn = ui.button({n = RES_DICT.COM_TITLE_BAR}):updateLabel({fnt = FONT.D1, text = __('凌云争锋'), offset = cc.p(0,-10)})
    titleBtn:addList(ui.image({img = RES_DICT.COM_TIPS_ICON})):alignTo(nil, ui.rc, {offsetX = -15, offsetY = -10})
    topLayer:addList(titleBtn):alignTo(backBtn, ui.rc, {offsetX = 2, offsetY = 10})


    return {
        view         = view,
        --           = top
        titleBtn     = titleBtn,
        backBtn      = backBtn,
        --           = center
        scheduleNode = scheduleNode,
    }
end


return ChampionshipScheduleView
