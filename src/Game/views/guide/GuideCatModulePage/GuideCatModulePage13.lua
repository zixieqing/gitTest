--[[
 * author : panmeng
 * descpt : 猫咪 指南 猫咪日常：疾病1
]]
local GuideCatModulePage13 = class('GuideCatModulePage13', function()
    return ui.layer({name = 'Game.views.guide.GuideCatModulePage.GuideCatModulePage13', enableEvent = true})
end)

local RES_DICT = {
    LEFT_CENTER  = _res('guide/catModule/cat_book_life_ball.png'),
    RIGTH_TOP_BG = _res('guide/catModule/cat_book_life_sick.png'),
    TIP_BG       = _res('guide/catModule/cat_book_red.png'),
    HAND_IMG     = _res('guide/guide_ico_hand.png'),
    RIGTH_BG     = _res('guide/catModule/cat_book_life_pill.png'),
    LINE_IMG     = _res('guide/guide_line_dotted_1.png'),
}




function GuideCatModulePage13:ctor(args)
    -- create view
    self.viewData_ = GuideCatModulePage13.CreateView()
    self:addChild(self.viewData_.view)
end


function GuideCatModulePage13:getViewData()
    return self.viewData_
end


function GuideCatModulePage13:refreshUI(data)
    self:getViewData().iconTitle:setString(tostring(data['3']))
    display.commonLabelParams(self:getViewData().topDescr1, {text = tostring(data['4']), reqW = 120})
    display.commonLabelParams(self:getViewData().topDescr2, {text = tostring(data['5']), reqW = 120})
    self:getViewData().tipsTitle:updateLabel({text = tostring(data['6']), reqW = 370})  
end


-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function GuideCatModulePage13.CreateView()
    local view = ui.layer({size = GuideUtils.GUIDE_VIEW_SIZE})

    ----------------------------------------------------- left view
    local leftBg = ui.image({img = RES_DICT.LEFT_CENTER})
    view:addList(leftBg):alignTo(nil, ui.cc, {offsetX = -GuideUtils.GUIDE_VIEW_SIZE.width * 0.25, offsetY = -20})

    ----------------------------------------------------- rigth view
    local rightViewP     = cc.p(GuideUtils.GUIDE_VIEW_SIZE.width * 0.73, GuideUtils.GUIDE_VIEW_SIZE.height * 0.5)
    local rightViewGroup = view:addList({
        ui.image({img = RES_DICT.RIGTH_TOP_BG}),
        ui.image({img = RES_DICT.LINE_IMG, mt = 20}),
        ui.title({n = RES_DICT.TIP_BG, zorder = 2}):updateLabel({fnt = FONT.D4, text = "--"}),
        ui.image({img = RES_DICT.RIGTH_BG, mt = -30}),
    })
    ui.flowLayout(rightViewP, rightViewGroup, {type = ui.flowV, ap = ui.cc, gapH = 5})

    ---------- right top layer
    local rightTopLayer = rightViewGroup[1]
    rightTopLayer:setPositionX(rightTopLayer:getPositionX() + 40)

    local iconTitle = ui.label({fnt = FONT.D14, text = "--", offset = cc.p(0, -40)})
    rightTopLayer:addList(iconTitle):alignTo(nil, ui.lc, {offsetX = 90, offsetY = -20})

    local rightHand = ui.image({img = RES_DICT.HAND_IMG})
    iconTitle:addList(rightHand):alignTo(nil, ui.lb, {offsetX = -110, offsetY = -10})

    local topDescr1 = ui.label({fnt = FONT.D9, color = "#76553b", text = "--", hAlign = display.TAC})
    rightTopLayer:addList(topDescr1):alignTo(nil, ui.lb, {offsetX = 140, offsetY = 35})

    local topDescr2 = ui.label({fnt = FONT.D9, color = "#c02b13", text = "--", hAlign = display.TAC})
    rightTopLayer:addList(topDescr2):alignTo(nil, ui.rb, {offsetX = -120, offsetY = 35})


    return {
        view          = view,
        topDescr1     = topDescr1,
        topDescr2     = topDescr2,
        iconTitle     = iconTitle,
        tipsTitle     = rightViewGroup[3],
    }
end


return GuideCatModulePage13
