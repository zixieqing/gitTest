--[[
 * author : panmeng
 * descpt : 猫咪 指南 猫咪日常-死亡
]]
local GuideCatModulePage12 = class('GuideCatModulePage12', function()
    return ui.layer({name = 'Game.views.guide.GuideCatModulePage.GuideCatModulePage12', enableEvent = true})
end)

local RES_DICT = {
    LEFT_CENTER  = _res('guide/catModule/cat_book_life_death.png'),
    RIGTH_TOP_BG = _res('guide/catModule/cat_book_life_revive.png'),
    RIGTH_BG     = _res('guide/catModule/cat_book_life_free.png'),
    LINE_IMG     = _res('guide/guide_line_dotted_1.png'),
    HAND_IMG     = _res('guide/guide_ico_hand.png'),
}


function GuideCatModulePage12:ctor(args)
    -- create view
    self.viewData_ = GuideCatModulePage12.CreateView()
    self:addChild(self.viewData_.view)
end


function GuideCatModulePage12:getViewData()
    return self.viewData_
end


function GuideCatModulePage12:refreshUI(data)
    self:getViewData().rebornTitle:setText(tostring(data['3']))
    self:getViewData().freeTitle:setText(tostring(data['4']))
end


-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function GuideCatModulePage12.CreateView()
    local view = ui.layer({size = GuideUtils.GUIDE_VIEW_SIZE})

    ----------------------------------------------------- left view
    local leftTitle = ui.title({n = RES_DICT.LEFT_CENTER})
    view:addList(leftTitle):alignTo(nil, ui.cc, {offsetX = -GuideUtils.GUIDE_VIEW_SIZE.width * 0.25, offsetY = -20})

    ----------------------------------------------------- rigth view
    local rightViewP     = cc.p(GuideUtils.GUIDE_VIEW_SIZE.width * 0.74, GuideUtils.GUIDE_VIEW_SIZE.height * 0.45)
    local rightViewGroup = view:addList({
        ui.title({n = RES_DICT.RIGTH_TOP_BG}):updateLabel({fnt = FONT.D14, text = "--", offset = cc.p(-78, 50)}),
        ui.image({img = RES_DICT.LINE_IMG}),
        ui.title({n = RES_DICT.RIGTH_BG, mt = -25}):updateLabel({fnt = FONT.D14, text = "--", offset = cc.p(118, 20)}),
    })
    ui.flowLayout(rightViewP, rightViewGroup, {type = ui.flowV, ap = ui.cc})

    local rebornTitle = rightViewGroup[1]
    rebornTitle:addList(ui.image({img = RES_DICT.HAND_IMG})):alignTo(nil, ui.lt, {offsetY = -90, offsetX = 20})

    local freeTitle = rightViewGroup[3]
    freeTitle:addList(ui.image({img = RES_DICT.HAND_IMG, scaleX = -1})):alignTo(nil, ui.rt, {offsetY = -130})

    return {
        view          = view,
        rebornTitle   = rebornTitle,
        freeTitle     = freeTitle,
    }
end


return GuideCatModulePage12
