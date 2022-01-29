--[[
 * author : panmeng
 * descpt : 猫咪 指南 猫咪繁殖-配对1
]]
local GuideCatModulePage9 = class('GuideCatModulePage9', function()
    return ui.layer({name = 'Game.views.guide.GuideCatModulePage.GuideCatModulePage9', enableEvent = true})
end)

local RES_DICT = {
    LEFT_CENTER  = _res('guide/catModule/cat_book_love_home.png'),
    RIGTH_TOP_BG = _res('guide/catModule/cat_book_love_choose.png'),
    TIP_BG       = _res('guide/catModule/cat_book_work_ability.png'),
    HAND_IMG     = _res('guide/guide_ico_hand.png'),
    LINE_IMG     = _res('guide/guide_frame_dottedline.png'),
    COMMON_BTN   = _res('ui/common/common_btn_orange.png'),
}


function GuideCatModulePage9:ctor(args)
    -- create view
    self.viewData_ = GuideCatModulePage9.CreateView()
    self:addChild(self.viewData_.view)
end


function GuideCatModulePage9:getViewData()
    return self.viewData_
end


function GuideCatModulePage9:refreshUI(data)
    display.commonLabelParams(self:getViewData().tipsLabel, {text = tostring(data['3'])})
    self:getViewData().confirmTitle:updateLabel({text = tostring(data['4']), reqW = 110})
end


-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function GuideCatModulePage9.CreateView()
    local view = ui.layer({size = GuideUtils.GUIDE_VIEW_SIZE})

    ----------------------------------------------------- left view
    local leftTitle = ui.title({n = RES_DICT.LEFT_CENTER})
    view:addList(leftTitle):alignTo(nil, ui.cc, {offsetX = -GuideUtils.GUIDE_VIEW_SIZE.width * 0.25, offsetY = -20})

    local leftHandImg = ui.image({img = RES_DICT.HAND_IMG})
    leftTitle:addList(leftHandImg):alignTo(nil, ui.lb, {offsetY = 20, offsetX = 30})

    ----------------------------------------------------- rigth view
    local rightViewP     = cc.p(GuideUtils.GUIDE_VIEW_SIZE.width * 0.73, GuideUtils.GUIDE_VIEW_SIZE.height * 0.5)
    local rightViewGroup = view:addList({
        ui.image({img = RES_DICT.RIGTH_TOP_BG}),
        ui.label({fnt = FONT.D9, color = "#97766f", text = "--", ap = ui.lc, mt = 40}),
        ui.title({n = RES_DICT.TIP_BG, mt = -5}),
        ui.image({img = RES_DICT.LINE_IMG}),
    })
    ui.flowLayout(rightViewP, rightViewGroup, {type = ui.flowV, ap = ui.cc, gapH = -5})

    ---------- right top layer
    local rightTopLayer = rightViewGroup[1]
    local rightHand = ui.image({img = RES_DICT.HAND_IMG})
    rightTopLayer:addList(rightHand):alignTo(nil, ui.lb, {offsetX = 20, offsetY = 15})

    ---------- tipLabels
    local tipsLabel = rightViewGroup[2]
    tipsLabel:setPositionX(tipsLabel:getPositionX() - 170)

    ----------- line img
    local lineImg      = rightViewGroup[4]
    local confirmTitle = ui.title({n = RES_DICT.COMMON_BTN}):updateLabel({fnt = FONT.D14, text = "--"})
    lineImg:addList(confirmTitle):alignTo(nil, ui.cc)

    return {
        view          = view,
        confirmTitle  = confirmTitle,
        tipsLabel     = tipsLabel,
    }
end


return GuideCatModulePage9
