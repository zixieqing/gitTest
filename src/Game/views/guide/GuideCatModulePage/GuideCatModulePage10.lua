--[[
 * author : panmeng
 * descpt : 猫咪 指南 猫咪繁殖-配对2
]]
local GuideCatModulePage10 = class('GuideCatModulePage10', function()
    return ui.layer({name = 'Game.views.guide.GuideCatModulePage.GuideCatModulePage10', enableEvent = true})
end)

local RES_DICT = {
    LEFT_CENTER  = _res('guide/catModule/cat_book_love_time.png'),
    RIGTH_TOP_BG = _res('guide/catModule/cat_book_love_done.png'),
    RIGTH_BG     = _res('guide/catModule/cat_book_love_cat.png'),
}


function GuideCatModulePage10:ctor(args)
    -- create view
    self.viewData_ = GuideCatModulePage10.CreateView()
    self:addChild(self.viewData_.view)
end


function GuideCatModulePage10:getViewData()
    return self.viewData_
end


function GuideCatModulePage10:refreshUI(data)
    display.commonLabelParams(self:getViewData().tipsLabel, {text = tostring(data['3'])})
end


-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function GuideCatModulePage10.CreateView()
    local view = ui.layer({size = GuideUtils.GUIDE_VIEW_SIZE})

    ----------------------------------------------------- left view
    local leftTitle = ui.title({n = RES_DICT.LEFT_CENTER})
    view:addList(leftTitle):alignTo(nil, ui.cc, {offsetX = -GuideUtils.GUIDE_VIEW_SIZE.width * 0.25, offsetY = -20})

    ----------------------------------------------------- rigth view
    local rightViewP     = cc.p(GuideUtils.GUIDE_VIEW_SIZE.width * 0.73, GuideUtils.GUIDE_VIEW_SIZE.height * 0.47)
    local rightViewGroup = view:addList({
        ui.image({img = RES_DICT.RIGTH_TOP_BG}),
        ui.label({fnt = FONT.D4, text = "--", w = 400, ap = ui.ct}),
        ui.image({img = RES_DICT.RIGTH_BG, mt = 50}),
    })
    ui.flowLayout(rightViewP, rightViewGroup, {type = ui.flowV, ap = ui.cc})

    return {
        view          = view,
        tipsLabel     = rightViewGroup[2],
    }
end


return GuideCatModulePage10
