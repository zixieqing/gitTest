--[[
 * author : panmeng
 * descpt : 归回确认界面
]]

local CommonDialog   = require('common.CommonDialog')
local CatModuleRebirthPopup = class('CatModuleRebirthPopup', CommonDialog)

local RES_DICT = {
    BG_FRAME    = _res('ui/cards/propertyNew/card_attribute_bg.png'),
    COM_TITLE   = _res('ui/common/common_bg_title_2.png'),
    BG_CELL     = _res('ui/common/card_bg_attribute_number.png'),
    IMG_LINE    = _res('ui/cards/propertyNew/card_ico_attribute_line.png'),
    IMG_ARROW   = _res('ui/cards/propertyNew/card_ico_green_arrow.png'),
    BTN_CANCEL  = _res('ui/common/common_btn_white_default.png'),
    BTN_CONFIRM = _res('ui/common/common_btn_orange.png'),
    COST_BG     = _res('ui/catModule/catInfo/work/grow_main_shop_bg_money.png'),
}

function CatModuleRebirthPopup:ctor(args)
    self.super.ctor(self, args)
    self.args = checktable(args)
    self.confirmCB_ = self.args.confirmCB
end


function CatModuleRebirthPopup:InitialUI()
    -- create view
    self.viewData = CatModuleRebirthPopup.CreateView()
    self:setPosition(display.center)

    -- handler
    ui.bindClick(self:getViewData().confirmBtn, handler(self, self.onClickConfirmBtnHandler_))
    ui.bindClick(self:getViewData().cancelBtn, handler(self, self.onClickCancelBtnHandler_))
end


function CatModuleRebirthPopup:getViewData()
    return self.viewData
end

-------------------------------------------------------------------------------
-- handler
-------------------------------------------------------------------------------
function CatModuleRebirthPopup:onClickConfirmBtnHandler_(sender)
    PlayAudioByClickNormal()

    if self.confirmCB_ then
        self.confirmCB_()
    end
    self:CloseHandler()
end

function CatModuleRebirthPopup:onClickCancelBtnHandler_(sender)
    PlayAudioByClickClose()

    self:CloseHandler()
end

-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function CatModuleRebirthPopup.CreateView()
    local size = cc.size(450, 490)
    local view = ui.layer({size = size})
    local cpos = cc.sizep(size, ui.cc)

    local bgLayer = ui.layer({size = cc.resize(size, 0, -90), bg = RES_DICT.BG_FRAME, scale9 = true, cut = cc.dir(10, 200, 10, 10)})
    view:addList(bgLayer):alignTo(nil, ui.ct)

    local title = ui.label({fnt = FONT.D6, color = "#bfa08a", text = __("归回将回到第一代, 同时保留属性,能力值。提升属性值上限"), w = size.width - 20})
    bgLayer:addList(title):alignTo(nil, ui.ct, {offsetY = -50, offsetX = 10})

    local CELL_SIZE = cc.size(357, 37)
    local attrNodeList = {}
    for attrIndex, attrId in ipairs(CONF.CAT_HOUSE.CAT_ATTR:GetIdList()) do
        local attrConf = CONF.CAT_HOUSE.CAT_ATTR:GetValue(attrId)
        local isDouble = attrIndex % 2 == 0
        local view = isDouble and ui.layer({bg = RES_DICT.BG_CELL}) or ui.layer({size = CELL_SIZE})
        table.insert(attrNodeList, view)

        local icon = ui.image({img = _res(string.format('ui/catModule/catInfo/attrIcon/attribute_circle_%d.png', attrId % 100))})
        view:addList(icon):alignTo(nil, ui.lc)

        local attrNameLabel = ui.label({fnt = FONT.D9, color = "#e2c0b5", text = attrConf.name, ap = ui.lc})
        view:addList(attrNameLabel):alignTo(nil, ui.lc, {offsetX = 50})

        local curValueLabel = ui.label({fnt = FONT.D9, color = "#e2c0b5", text = attrConf.max, ap = ui.lc})
        view:addList(curValueLabel):alignTo(nil, ui.lc, {offsetX = 310})

        local arrImg = ui.image({img = RES_DICT.IMG_ARROW})
        view:addList(arrImg):alignTo(nil, ui.rc, {offsetX = -50})

        local nextValueLabel = ui.label({fnt = FONT.D9, color = "#66b526", text = attrConf.rebirthMax, ap = ui.rc})
        view:addList(nextValueLabel):alignTo(nil, ui.rc, {offsetX = -80})
    end
    bgLayer:addList(attrNodeList)
    ui.flowLayout(cc.rep(cc.sizep(view, ui.cb), 0, 16), attrNodeList, {type = ui.flowV, ap = ui.ct})

    local btnGroup = view:addList({
        ui.button({n = RES_DICT.BTN_CANCEL}):updateLabel({fnt = FONT.D14, text = __("取消"), reqW = 110}),
        ui.button({n = RES_DICT.BTN_CONFIRM}):updateLabel({fnt = FONT.D14, text = __("归回"), reqW = 110}),
    })
    ui.flowLayout(cc.rep(cc.sizep(view, ui.cb), 0, 20), btnGroup, {type = ui.flowH, ap = ui.cb, gapW = 140})

    local costBg = ui.image({img = RES_DICT.COST_BG})
    view:addList(costBg):alignTo(btnGroup[2], cb, {offsetY = -43})

    local costLabelList = {}
    for _, goodsData in ipairs(CatHouseUtils.CAT_PARAM_FUNCS.REBIRTH_CONSUME()) do
        table.insert(costLabelList, {fnt = FONT.D9, color = "#e5ded9", text = goodsData.num})
        table.insert(costLabelList, {img = GoodsUtils.GetIconPathById(goodsData.goodsId), scale = 0.15})
    end
    if #costLabelList > 0 then
        local costRichLabel = ui.rLabel({r = true, c = costLabelList})
        costBg:addList(costRichLabel):alignTo(nil, ui.cc)
    end

    return {
        view       = view,
        confirmBtn = btnGroup[2],
        cancelBtn  = btnGroup[1],
    }
end


return CatModuleRebirthPopup
