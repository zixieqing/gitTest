local CommonDialog   = require('common.CommonDialog')
local CardRedSettingPopup = class('CardRedSettingPopup', CommonDialog)

local RES_DICT = {
    BG_FRAME   = _res('ui/home/cardslistNew/role_remind_bg_list.png'),
    BTN_BG     = _res('ui/home/cardslistNew/setup_btn_bg.png'),
    BTN_OPENED = _res('ui/home/cardslistNew/setup_btn_bg_open.png'),
    BTN_CLOSED = _res('ui/home/cardslistNew/setup_btn_bg_close.png')
}

local SET_BTN_TAG = {
    LEVEL_UP = 1,
    SKILL_UP = 2,
    STAR_UP  = 3,
    FEL_GOD  = 4,
}

local SET_INFO_DEFINES = {
    -- [SET_BTN_TAG.LEVEL_UP] = {text = __("升级提醒"), localDefine = LOCAL.CARDLIST.IS_SHOW_LEVEL_UP_TIPS()},
    -- [SET_BTN_TAG.SKILL_UP] = {text = __("技能提醒"), localDefine = LOCAL.CARDLIST.IS_SHOW_SKILL_UP_TIPS()},
    [SET_BTN_TAG.STAR_UP]  = {text = __("升星提醒"), localDefine = LOCAL.CARDLIST.IS_SHOW_STAR_UP_TIPS()},
    -- [SET_BTN_TAG.FEL_GOD]  = {text = __("堕神提醒"), localDefine = LOCAL.CARDLIST.IS_SHOW_FEL_GOD_TIPS()},
}


function CardRedSettingPopup:InitialUI()
    -- create view
    self.viewData = CardRedSettingPopup.CreateView()
    self:setPosition(display.center)

    -- update view
    self:initPage()
end


function CardRedSettingPopup:getViewData()
    return self.viewData
end

-------------------------------------------------------------------------------
-- public
-------------------------------------------------------------------------------
function CardRedSettingPopup:initPage()
    for btnTag, btnNode in pairs(self:getViewData().setBtnMaps) do
        self:updateCheckedState(btnNode, SET_INFO_DEFINES[btnTag].localDefine:Load(), false)
        btnNode:setOnClickScriptHandler(handler(self, self.onClickSetBtnHandler_))
    end
end


function CardRedSettingPopup:updateCheckedState(btnNode, isChecked, isNeedAnim)
    local btnSize  = btnNode:getContentSize()
    local viewSize = btnNode:getParent():getContentSize()
    btnNode:stopAllActions()
    btnNode:setChecked(isChecked)
    if isChecked then
        if isNeedAnim then
            btnNode:setPositionX(viewSize.width / 2)
            btnNode:runAction(cc.MoveBy:create(0.05, cc.p(viewSize.width - btnSize.width, 0)))
        else
            btnNode:setPositionX(viewSize.width - btnSize.width / 2)
        end
    else
        if isNeedAnim then
            btnNode:setPositionX(viewSize.width - btnSize.width / 2)
            btnNode:runAction(cc.MoveBy:create(0.05, cc.p(btnSize.width - viewSize.width, 0)))
        else
            btnNode:setPositionX(btnSize.width / 2)
        end
    end
end
-------------------------------------------------------------------------------
-- handler
-------------------------------------------------------------------------------
function CardRedSettingPopup:onClickSetBtnHandler_(sender)
    local btnTag = checkint(sender:getTag())
    local define = SET_INFO_DEFINES[btnTag].localDefine
    local isOpen = define:Load()

    -- update local data
    define:Save(not isOpen)

    -- update view
    self:updateCheckedState(sender, not isOpen, true)

    -- 更新红点状态
end
-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function CardRedSettingPopup.CreateView()
    local view = ui.layer({bg = RES_DICT.BG_FRAME, scale9 = true})
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    local setInfoLayerList = {ui.label({fnt = FONT.D7, color = "#c1a089", fontSize = 30, text = __("飨灵设置"), mb = 20})}
    local setBtnMaps = {}
    for setBtnTag, setInfoDefine in pairs(SET_INFO_DEFINES) do
        local layer = ui.layer({size = cc.size(570, 70)})

        local frameGroup = layer:addList({
            ui.label({fnt = FONT.D4, fontsize = 30, color = "#fff5e3", text = setInfoDefine.text}),
            ui.layer({bg = RES_DICT.BTN_BG}),
        })
        ui.flowLayout(cc.sizep(layer, ui.cc), frameGroup, {type = ui.flowH, ap = ui.cc, gapW = 270})

        local btnLayer = frameGroup[2]
        local tButton  = ui.tButton({n = RES_DICT.BTN_CLOSED, s = RES_DICT.BTN_OPENED})
        tButton:setTag(setBtnTag)
        btnLayer:addList(tButton):alignTo(nil, ui.lc)
        tButton:getNormalImage():addList(ui.label({fnt = FONT.D9, text = __("关闭"), reqW = 70})):alignTo(nil, ui.cc)
        tButton:getSelectedImage():addList(ui.label({fnt = FONT.D9, text = __("打开"), reqW = 70})):alignTo(nil, ui.cc)
        
        setBtnMaps[setBtnTag] = tButton
        table.insert(setInfoLayerList, layer)
    end
    view:addList(setInfoLayerList)
    ui.flowLayout(cc.rep(cc.sizep(size, ui.ct), 0, -65), setInfoLayerList, {type = ui.flowV, ap = ui.cb})

    return {
        view       = view,
        setBtnMaps = setBtnMaps,
    }
end


return CardRedSettingPopup
