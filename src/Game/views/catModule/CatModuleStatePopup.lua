--[[
 * author : panmeng
 * descpt : 猫咪状态弹窗
]]
local CommonDialog        = require('common.CommonDialog')
local CatModuleStatePopup = class('CatModuleStatePopup', CommonDialog)


local STATE_INFO_DEFINE = {
    [CatHouseUtils.CAT_STATE_ANIM_TAG.WORK_DONE]    = {text = __("猫咪工作归来了")},
    [CatHouseUtils.CAT_STATE_ANIM_TAG.RELEASE_DONE] = {text = __("猫咪永远的走了")},
    [CatHouseUtils.CAT_STATE_ANIM_TAG.STUDY_DONE]   = {text = __("猫咪学习归来了")},
    [CatHouseUtils.CAT_STATE_ANIM_TAG.DEAD_DONE]    = {text = __("猫咪去喵星了")},
}

function CatModuleStatePopup:ctor(args)
    self.args = checktable(args)
    self.super.ctor(self, args)
end

function CatModuleStatePopup:InitialUI()
    -- create view
    self.viewData = CatModuleStatePopup.CreateView(self.args.animTag)
    self:setPosition(display.center)

    -- update view
    self:getViewData().centerLayer:runAction(cc.Sequence:create(
        cc.DelayTime:create(1),
        cc.ScaleTo:create(0.5, 1, 0),
        cc.CallFunc:create(function()
            self:runAction(cc.RemoveSelf:create())
            if self.args.endCB then
                self.args.endCB()
            end
        end)
    ))
end


function CatModuleStatePopup:getViewData()
    return self.viewData
end


-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function CatModuleStatePopup.CreateView(animTag)
    local view = ui.layer()
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    -- block layer | center layer
    local backGroundGroup = view:addList({
        ui.layer({color = cc.r4b(0), enable = true}),
        ui.layer({ap = ui.cc}),
    })
    ui.flowLayout(cpos, backGroundGroup, {type = ui.flowC, ap = ui.cc})

    ------------------------------------------------- [center]
    local centerLayer = backGroundGroup[2]

    local bg = ui.image({img = string.format(_res("ui/catModule/catInfo/state_bg_%s.png"), animTag), scale = 2})
    centerLayer:addList(bg):alignTo(nil, ui.cc)

    local tipLabel    = ui.label({fnt = FONT.D14, fontSize = 50, text = STATE_INFO_DEFINE[animTag].text, reqW = 600})
    centerLayer:addList(tipLabel):alignTo(nil, ui.cc, {offsetX = 95})


    return {
        centerLayer = centerLayer,
        view        = view,
    }
end


return CatModuleStatePopup



