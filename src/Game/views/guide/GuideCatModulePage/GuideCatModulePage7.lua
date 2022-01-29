--[[
 * author : panmeng
 * descpt : 猫咪 指南 猫咪深造-工作
]]
local GuideCatModulePage7 = class('GuideCatModulePage7', function()
    return ui.layer({name = 'Game.views.guide.GuideCatModulePage.GuideCatModulePage7', enableEvent = true})
end)

local RES_DICT = {
    LEFT_CENTER  = _res('guide/catModule/cat_book_work.png'),
    RIGTH_TOP_BG = _res('guide/catModule/cat_book_work_star.png'),
    RIGTH_BG     = _res('guide/catModule/cat_book_work_gold.png'),
    HAND_IMG     = _res('guide/guide_ico_hand.png'),
}

function GuideCatModulePage7:ctor(args)
    -- create view
    self.viewData_ = GuideCatModulePage7.CreateView()
    self:addChild(self.viewData_.view)
end


function GuideCatModulePage7:getViewData()
    return self.viewData_
end


function GuideCatModulePage7:refreshUI(data)
    display.commonLabelParams(self:getViewData().titleLabel, {text = tostring(data['3'])})
    display.commonLabelParams(self:getViewData().workTipLabel, {text = tostring(data['4'])})
    display.commonLabelParams(self:getViewData().workNameLabel, {text = tostring(data['5']), reqW = 220})
    display.commonLabelParams(self:getViewData().rewardTip, {text = tostring(data['6']), reqW = 250})
    display.commonLabelParams(self:getViewData().rewardTitle, {text = tostring(data['7']), reqW = 120})
end


-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function GuideCatModulePage7.CreateView()
    local view = ui.layer({size = GuideUtils.GUIDE_VIEW_SIZE})

    ----------------------------------------------------- left view
    local leftTitle = ui.title({n = RES_DICT.LEFT_CENTER})
    view:addList(leftTitle):alignTo(nil, ui.cc, {offsetX = -GuideUtils.GUIDE_VIEW_SIZE.width * 0.25, offsetY = -20})

    local leftHandImg = ui.image({img = RES_DICT.HAND_IMG})
    leftTitle:addList(leftHandImg):alignTo(nil, ui.lb, {offsetY = 20, offsetX = -10})

    ----------------------------------------------------- rigth view
    local rightViewP     = cc.p(GuideUtils.GUIDE_VIEW_SIZE.width * 0.5, GuideUtils.GUIDE_VIEW_SIZE.height * 0.5)
    local rightViewGroup = view:addList({
        ui.image({img = RES_DICT.RIGTH_TOP_BG, ml = 20}),
        ui.image({img = RES_DICT.RIGTH_BG}),
    })
    ui.flowLayout(cc.rep(rightViewP, 0, -20), rightViewGroup, {type = ui.flowV, ap = ui.lc, gapH = -5})

    ---------- right top layer
    local rightTopLayer = rightViewGroup[1]
    local titleLabel    = ui.label({fnt = FONT.D14, text = "--"})
    rightTopLayer:addList(titleLabel):alignTo(nil, ui.lc, {offsetX = 130, offsetY = 55})

    local rightHand = ui.image({img = RES_DICT.HAND_IMG})
    rightTopLayer:addList(rightHand):alignTo(nil, ui.lc, {offsetX = 0, offsetY = 60})

    local workTipLabel = ui.label({fnt = FONT.D9, color = "#97766f", text = "--", w = 220, ap = ui.rt})
    rightTopLayer:addList(workTipLabel):alignTo(nil, ui.rt, {offsetX = -70, offsetY = -20})

    local workNameLabel = ui.label({fnt = FONT.D9, color = "#562c22", text = "--", ap = ui.lc})
    rightTopLayer:addList(workNameLabel):alignTo(nil, ui.lc, {offsetX = 100, offsetY = -5})

    ----------- tipImg
    local rewardLayer = rightViewGroup[2]
    local rewardTip   = ui.label({fnt = FONT.D9, color = "#DDBC89", text = "--"})
    rewardLayer:addList(rewardTip):alignTo(nil, ui.lt, {offsetX = 170, offsetY = -40})

    local rewardTitle = ui.label({fnt = FONT.D6, color = "#5b3c25", text = "--"})
    rewardLayer:addList(rewardTitle):alignTo(nil, ui.lt, {offsetX = 170, offsetY = -80})

    return {
        view          = view,
        titleLabel    = titleLabel,
        workTipLabel  = workTipLabel,
        workNameLabel = workNameLabel,
        rewardTip     = rewardTip,
        rewardTitle   = rewardTitle,
    }
end


return GuideCatModulePage7
