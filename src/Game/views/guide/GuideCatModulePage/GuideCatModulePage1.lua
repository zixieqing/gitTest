--[[
 * author : panmeng
 * descpt : 猫咪 指南 猫咪日常：喂食，洗澡，玩耍
]]
local GuideCatModulePage1 = class('GuideCatModulePage1', function()
    return ui.layer({name = 'Game.views.guide.GuideCatModulePage.GuideCatModulePage1', enableEvent = true})
end)

local SUB_TYPE = {
    FEED = 1,
    BATN = 2,
    PLAY = 3,
}

local SUB_RES = {
    [SUB_TYPE.FEED] = {
        ICON = _res("ui/catModule/catInfo/life/grow_cat_life_ico_food.png"),
        BG   = _res('guide/catModule/cat_book_life_food.png'),
    },
    [SUB_TYPE.BATN] = {
        ICON = _res("ui/catModule/catInfo/life/grow_cat_life_ico_shower.png"),
        BG   = _res('guide/catModule/cat_book_life_bath.png'),
    },
    [SUB_TYPE.PLAY] = {
        ICON = _res("ui/catModule/catInfo/life/grow_cat_life_ico_play.png"),
        BG   = _res('guide/catModule/cat_book_life_play.png'),    
    }
}

local RES_DICT = {
    LEFT_CENTER  = _res('guide/catModule/cat_book_life.png'),
    RIGTH_TOP_BG = _res('guide/catModule/cat_book_life_number.png'),
    TIP_BG       = _res('guide/catModule/cat_book_red.png'),
    HAND_IMG     = _res('guide/guide_ico_hand.png'),
    LINE_IMG     = _res('guide/guide_frame_dottedline.png'),
    COMMON_BTN   = _res('ui/common/common_btn_orange.png'),
}




function GuideCatModulePage1:ctor(args)
    -- init res
    self.pageIndex = args.pageIndex and checkint(args.pageIndex) or 1
    table.merge(RES_DICT, SUB_RES[self.pageIndex])

    -- create view
    self.viewData_ = GuideCatModulePage1.CreateView()
    self:addChild(self.viewData_.view)
end


function GuideCatModulePage1:getViewData()
    return self.viewData_
end


function GuideCatModulePage1:refreshUI(data)
    self:getViewData().leftTitle:updateLabel({text = tostring(data['3']), reqW = 120})
    self:getViewData().iconTitle:setText(tostring(data['4']))
    display.commonLabelParams(self:getViewData().rightTopDescr, {text = CommonUtils.parserGuideDesc(tostring(data['5']))})
    self:getViewData().tipsTitle:updateLabel({text = tostring(data['6']), reqW = 370})
    self:getViewData().confirmTitle:updateLabel({text = tostring(data['7']), reqW = 110})
end


-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function GuideCatModulePage1.CreateView()
    local view = ui.layer({size = GuideUtils.GUIDE_VIEW_SIZE})

    -- left view
    local leftTitle = ui.title({n = RES_DICT.LEFT_CENTER}):updateLabel({fnt = FONT.D14, text = "--", offset = cc.p(5, -47)})
    view:addList(leftTitle):alignTo(nil, ui.cc, {offsetX = -GuideUtils.GUIDE_VIEW_SIZE.width * 0.25, offsetY = -20})

    local leftHandImg = ui.image({img = RES_DICT.HAND_IMG})
    leftTitle:addList(leftHandImg):alignTo(nil, ui.lb, {offsetY = 20, offsetX = -10})

    -- rigth view
    local rightViewP     = cc.p(GuideUtils.GUIDE_VIEW_SIZE.width * 0.73, GuideUtils.GUIDE_VIEW_SIZE.height * 0.5)
    local rightViewGroup = view:addList({
        ui.image({img = RES_DICT.RIGTH_TOP_BG}),
        ui.title({n = RES_DICT.TIP_BG}):updateLabel({fnt = FONT.D4, text = "--"}),
        ui.image({img = RES_DICT.BG}),
        ui.image({img = RES_DICT.LINE_IMG}),
    })
    ui.flowLayout(rightViewP, rightViewGroup, {type = ui.flowV, ap = ui.cc, gapH = -5})

    local rightTopLayer = rightViewGroup[1]
    rightTopLayer:setPositionX(rightTopLayer:getPositionX() + 40)

    local iconTitle = ui.title({n = RES_DICT.ICON}):updateLabel({fnt = FONT.D14, text = "--", offset = cc.p(0, -40)})
    rightTopLayer:addList(iconTitle):alignTo(nil, ui.lc, {offsetX = 50})

    local rightHand = ui.image({img = RES_DICT.HAND_IMG})
    iconTitle:addList(rightHand):alignTo(nil, ui.lb, {offsetX = -80, offsetY = -15})

    local rightTopDescr = ui.label({fnt = FONT.D9, color = "#76553b", text = "--", hAlign = display.TAC})
    rightTopLayer:addList(rightTopDescr):alignTo(nil, ui.cc, {offsetX = 65})


    local lineImg      = rightViewGroup[4]
    local confirmTitle = ui.title({n = RES_DICT.COMMON_BTN}):updateLabel({fnt = FONT.D14, text = "--"})
    lineImg:addList(confirmTitle):alignTo(nil, ui.cc)

    return {
        view          = view,
        leftTitle     = leftTitle,
        rightTopDescr = rightTopDescr,
        confirmTitle  = confirmTitle,
        iconTitle     = iconTitle,
        tipsTitle     = rightViewGroup[2],
    }
end


return GuideCatModulePage1
