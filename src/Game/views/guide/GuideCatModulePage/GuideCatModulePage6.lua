--[[
 * author : panmeng
 * descpt : 猫咪 指南 猫咪深造-学习
]]
local GuideCatModulePage6 = class('GuideCatModulePage6', function()
    return ui.layer({name = 'Game.views.guide.GuideCatModulePage.GuideCatModulePage6', enableEvent = true})
end)

local RES_DICT = {
    LEFT_CENTER  = _res('guide/catModule/cat_book_work.png'),
    RIGTH_TOP_BG = _res('guide/catModule/cat_book_work_study.png'),
    RIGTH_BG     = _res('guide/catModule/cat_book_work_up.png'),
    HAND_IMG     = _res('guide/guide_ico_hand.png'),
    TIP_BG       = _res('guide/catModule/cat_book_work_ability.png'),
    ARROW_IMG    = _res('guide/catModule/cat_book_work_arrow.png'),
}

function GuideCatModulePage6:ctor(args)
    -- create view
    self.viewData_ = GuideCatModulePage6.CreateView()
    self:addChild(self.viewData_.view)
end


function GuideCatModulePage6:getViewData()
    return self.viewData_
end


function GuideCatModulePage6:refreshUI(data)
    self:getViewData().iconTitle:setText(tostring(data['3']))
    display.commonLabelParams(self:getViewData().rightTopDescr, {text = tostring(data['4']), reqW = 240})
    display.commonLabelParams(self:getViewData().tipsLabel, {text = tostring(data['5']), reqW = 400})
end


-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function GuideCatModulePage6.CreateView()
    local view = ui.layer({size = GuideUtils.GUIDE_VIEW_SIZE})

    ----------------------------------------------------- left view
    local leftTitle = ui.title({n = RES_DICT.LEFT_CENTER})
    view:addList(leftTitle):alignTo(nil, ui.cc, {offsetX = -GuideUtils.GUIDE_VIEW_SIZE.width * 0.25, offsetY = -20})

    local leftHandImg = ui.image({img = RES_DICT.HAND_IMG})
    leftTitle:addList(leftHandImg):alignTo(nil, ui.lb, {offsetY = 20, offsetX = -10})

    ----------------------------------------------------- rigth view
    local rightViewP     = cc.p(GuideUtils.GUIDE_VIEW_SIZE.width * 0.5, GuideUtils.GUIDE_VIEW_SIZE.height * 0.5)
    local rightViewGroup = view:addList({
        ui.title({n = RES_DICT.RIGTH_TOP_BG, ml = 50}):updateLabel({fnt = FONT.D14, text = "--", offset = cc.p(0, -40)}),
        ui.image({img = RES_DICT.TIP_BG, ml = -12, mt = -20, zorder = 2}),
        ui.label({fnt = FONT.D9, color = "#76553b", text = "--", ml = 20, ap = ui.lc, zorder = 3}),
        ui.image({img = RES_DICT.RIGTH_BG, mt = -10}),
    })
    ui.flowLayout(cc.rep(rightViewP, 0, -20), rightViewGroup, {type = ui.flowV, ap = ui.lc, gapH = -5})

    ---------- right top layer
    local iconTitle = rightViewGroup[1]
    local rightHand = ui.image({img = RES_DICT.HAND_IMG})
    iconTitle:addList(rightHand):alignTo(nil, ui.lb, {offsetX = -50, offsetY = 15})

    local rightTopDescr = ui.label({fnt = FONT.D9, color = "#76553b", text = "--", ap = ui.lc})
    iconTitle:addList(rightTopDescr):alignTo(nil, ui.rc, {offsetY = -10})


    ----------- tipImg
    local tipImg   = rightViewGroup[2]
    local arrowImg = ui.image({img = RES_DICT.ARROW_IMG})
    tipImg:addList(arrowImg):alignTo(nil, ui.rb, {offsetX = 5, offsetY = -70})

    return {
        view          = view,
        iconTitle     = iconTitle,
        rightTopDescr = rightTopDescr,
        tipsLabel     = rightViewGroup[3],
    }
end


return GuideCatModulePage6
