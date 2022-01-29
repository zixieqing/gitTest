--[[
 * author : panmeng
 * descpt : 猫咪 指南 猫咪好感度
]]
local GuideCatModulePage8 = class('GuideCatModulePage8', function()
    return ui.layer({name = 'Game.views.guide.GuideCatModulePage.GuideCatModulePage8', enableEvent = true})
end)

local RES_DICT = {
    LEFT_CENTER  = _res('guide/catModule/cat_book_love_like.png'),
    RIGTH_TOP_BG = _res('guide/catModule/cat_book_love_star.png'),
    RIGTH_BG     = _res('guide/catModule/cat_book_love_visit.png'),
    BOTTON_BG    = _res('guide/catModule/cat_book_love_book.png'),
    HAND_IMG     = _res('guide/guide_ico_hand.png'),
    LINE_IMG     = _res('guide/guide_line_dotted_1.png'),
    LOVE_ICON    = _res('ui/catHouse/friend/restaurant_friends_ico_kill_visit.png'),
}

function GuideCatModulePage8:ctor(args)
    -- create view
    self.viewData_ = GuideCatModulePage8.CreateView()
    self:addChild(self.viewData_.view)
end


function GuideCatModulePage8:getViewData()
    return self.viewData_
end


function GuideCatModulePage8:refreshUI(data)
    display.commonLabelParams(self:getViewData().loveTipLabel, {text = tostring(data['3'])})
    display.commonLabelParams(self:getViewData().bookLable, {text = tostring(data['4'])})
end


-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function GuideCatModulePage8.CreateView()
    local view = ui.layer({size = GuideUtils.GUIDE_VIEW_SIZE})

    ----------------------------------------------------- left view
    local leftTitle = ui.title({n = RES_DICT.LEFT_CENTER})
    view:addList(leftTitle):alignTo(nil, ui.cc, {offsetX = -GuideUtils.GUIDE_VIEW_SIZE.width * 0.25, offsetY = -20})

    ----------------------------------------------------- rigth view
    local rightViewP     = cc.p(GuideUtils.GUIDE_VIEW_SIZE.width * 0.73, GuideUtils.GUIDE_VIEW_SIZE.height * 0.5)
    local rightViewGroup = view:addList({
        ui.layer({size = cc.size(GuideUtils.GUIDE_VIEW_SIZE.width * 0.5, 130)}),
        ui.image({img = RES_DICT.RIGTH_TOP_BG, ml = 20, mt = -140}),
        ui.image({img = RES_DICT.RIGTH_BG}),
        ui.image({img = RES_DICT.LINE_IMG}),
        ui.image({img = RES_DICT.BOTTON_BG}),
    })
    ui.flowLayout(cc.rep(rightViewP, 0, -30), rightViewGroup, {type = ui.flowV, ap = ui.cc, gapH = -5})

    ---------- right top layer
    local topLayer = rightViewGroup[1]
    local topGroup = topLayer:addList({
        ui.image({img = RES_DICT.HAND_IMG, ml = 30, mt = 50, zorder = 2}),
        ui.image({img = RES_DICT.LOVE_ICON, mt = 20, ml = -20}),
        ui.label({fnt = FONT.D9, color = "#97766f", text = "--", w = 280, ap = ui.rc, ml = 15, mt = 40})
    })
    ui.flowLayout(cc.sizep(topLayer, ui.lt), topGroup, {type = ui.flowH, ap = ui.lt})

    ----------- tipImg
    local bottomLayer = rightViewGroup[5]
    local bookLable   = ui.label({fnt = FONT.D14, fontSize = 28, text = "--"})
    bottomLayer:addList(bookLable):alignTo(nil, ui.lc, {offsetX = 85, offsetY = -40})


    return {
        view          = view,
        loveTipLabel  = topGroup[3],
        bookLable     = bookLable,
    }
end


return GuideCatModulePage8
