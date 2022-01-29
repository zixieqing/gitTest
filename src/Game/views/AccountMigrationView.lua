--[[
 * author : panmeng
 * descpt : 账号迁移 界面 实现
]]

local AccountMigrationView = class('AccountMigrationView', function()
    return ui.layer({name = 'Game.views.AccountMigrationView', enableEvent = true})
end)

local RES_DICT = {
    VIEW_FRAME     = _res('ui/home/accountMigration/account_bg_1.png'),
    BACK_BTN       = _res('ui/common/common_btn_quit.png'),
    TITLE_BAR      = _res('ui/common/common_bg_title_2.png'),
    BTN_GET_CODE_N = _res('ui/common/common_btn_white_default.png'),
    BTN_GET_CODE_D = _res('ui/common/common_btn_orange_disable.png'),
    BTN_COMMIT     = _res('ui/common/common_btn_big_orange_2.png'),
    BTN_RETRY      = _res('ui/common/common_btn_big_white_default_2.png'),
    ACCOUNT_BG     = _res('ui/home/accountMigration/account_bg_line_1.png'),
    CODE_BG        = _res('ui/home/accountMigration/account_bg_line_2.png'),
    GOOD_BG        = _res('ui/home/accountMigration/goods_icon_1.png'),
    TIPS_BG        = _res('ui/home/accountMigration/account_bg_line_3.png'),
    ALPHA_IMG      = _res('ui/common/story_tranparent_bg.png'),
    CARTOON        = _res('ui/home/accountMigration/account_bg_role_1.png'),
}


function AccountMigrationView:ctor(args)
    -- create view
    self.viewData_ = AccountMigrationView.CreateView()
    self:addChild(self.viewData_.view)
end


function AccountMigrationView:getViewData()
    return self.viewData_
end


-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function AccountMigrationView.CreateView()
    local view = ui.layer()
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    -- black / block layer
    -- local backGroundGroup = view:addList({
    --     ui.layer({color = cc.c4b(0,0,0,150)}),
    --     --ui.layer({color = cc.r4b(0), enable = true}),
    -- })
    local blockLayer = view:addList(ui.layer({color = cc.c4b(0,0,0,150), enable = true}))
    ------------------------------------------------- [center]
    local centerLayer = ui.layer()
    view:add(centerLayer)

    -- view frame
    local viewFrameNode = ui.layer({p = cpos, bg = RES_DICT.VIEW_FRAME, ap = ui.cc, enable = true})
    local viewFrameSize = viewFrameNode:getContentSize()
    centerLayer:add(viewFrameNode)


    -- title bar
    local titleBar = ui.label({fnt = FONT.D3, text = __('账号迁移')})
    viewFrameNode:addList(titleBar):alignTo(nil, ui.ct, {offsetY = -45})

    -- [migrationView | resultLayer]
    local viewGroup = view:addList({
        ui.layer({size = cc.resize(viewFrameSize, -80, -110)}),
        ui.layer({size = cc.resize(viewFrameSize, -80, -110)}),
    })
    ui.flowLayout(cc.rep(cc.sizep(centerLayer, ui.cc), 0, -20), viewGroup, {type = ui.flowC, ap = ui.cc})

    --------------------- migrationView
    local migrationLayer = viewGroup[1]
    migrationLayer:addList(ui.image({img = RES_DICT.GOOD_BG, ap = ui.cb})):alignTo(nil, ui.cb)

    local textStr = __("    亲爱的御侍大人，因运营商更换缘故，《食之契约》将进行账号迁移流程，请您尽快进行角色数据绑定操作，绑定成功后可领取惊喜大礼包！")
    local migrationViewGroup = migrationLayer:addList({
        ui.label({text = textStr, color = "#5d5d5e", fontSize = 24, w = 580, mt = 53}),
        ui.image({img = RES_DICT.ACCOUNT_BG}),
        ui.layer({size = cc.size(431, 82)}),
        ui.button({n = RES_DICT.BTN_COMMIT, mt = 20}):updateLabel({fnt = FONT.D14, text = __("确认提交"), reqW = 170}),
    })
    ui.flowLayout(cc.sizep(migrationLayer, ui.ct), migrationViewGroup, {type = ui.flowV, gapW = 20, ap = ui.cb})

    local accountEditBoxBg = migrationViewGroup[2]
    local accountEditBox = AccountMigrationView.CreateEditBox(cc.resize(accountEditBoxBg:getContentSize(), -40, -30), __("请输入邮箱号"), nil, 50)
    accountEditBoxBg:addList(accountEditBox):alignTo(nil, ui.cc)

    local codeLayer = migrationViewGroup[3]
    local codeGroup = codeLayer:addList({
        ui.image({img = RES_DICT.CODE_BG, scale9 = true, size = cc.size(230, 72)}),
        ui.button({n = RES_DICT.BTN_GET_CODE_N, d = RES_DICT.BTN_GET_CODE_D, scale9 = true, size = cc.size(180, 60)}):updateLabel({fnt = FONT.D7, text = __("获取验证码"), outline = "#72443f", reqW = 170, fontSize = 18}),
    })
    ui.flowLayout(cc.rep(cc.sizep(codeLayer, ui.cc), -5, 0), codeGroup, {type = ui.flowH, ap = ui.cc, gapW = 5})

    local codeEditBoxBg = codeGroup[1]
    local codeEditBox = AccountMigrationView.CreateEditBox(cc.resize(codeEditBoxBg:getContentSize(), -40, -30), __("请输入验证码"))
    codeEditBoxBg:addList(codeEditBox):alignTo(nil, ui.cc)


    ------------------------ resultView
    local resultLayer = viewGroup[2]

    local resultLayerGroup = resultLayer:addList({
        ui.title({n = RES_DICT.TIPS_BG}):updateLabel({fontSize = 36, text = __("您已获得迁移码，请查看邮箱"), reqW = 600, color = "#5b3e25"}),
        ui.image({img = RES_DICT.CARTOON}), 
        ui.layer({size = cc.size(400, 90)}),
    })
    ui.flowLayout(cc.sizep(resultLayer, ui.cc), resultLayerGroup, {type = ui.flowV, gapH = 20, ap = ui.cc})

    local resultButtonLayer = resultLayerGroup[3]
    local resultButtonGroup = resultButtonLayer:addList({
        ui.button({n = RES_DICT.BTN_RETRY}):updateLabel({fnt = FONT.D14, text = __("重新获取"), reqW = 170}),
        ui.button({n = RES_DICT.BTN_COMMIT}):updateLabel({fnt = FONT.D14, text = __("前往绑定"), reqW = 170}),
    })
    ui.flowLayout(cc.rep(cc.sizep(resultButtonLayer, ui.cc), 0, 20), resultButtonGroup, {type = ui.flowH, gapW = 30, ap = ui.cc})
    resultLayer:setVisible(false)

    ------------------------------------------------- [top]
    local topLayer = ui.layer()
    view:add(topLayer)

    -- back button
    local backBtn = ui.button({n = RES_DICT.BACK_BTN})
    topLayer:addList(backBtn):alignTo(viewFrameNode, ui.rt, {offsetX = -50, offsetY = -120})


    return {
        view           = view,
        --             = top
        backBtn        = backBtn,
        --             = center
        blockLayer     = blockLayer,
        migrationLayer = migrationLayer,
        resultLayer    = resultLayer,
        accountEditBox = accountEditBox,
        codeEditBox    = codeEditBox,
        codeBtn        = codeGroup[2],
        commitBtn      = migrationViewGroup[4],
        retryBtn       = resultButtonGroup[1],
        bindingBtn     = resultButtonGroup[2],
    }
end

function AccountMigrationView.CreateEditBox(size, placeHolder, inputType, length)
    inputType = inputType or cc.EDITBOX_INPUT_MODE_SINGLELINE
    length = length or 20
    local editBox = ccui.EditBox:create(size, RES_DICT.ALPHA_IMG)
    display.commonUIParams(editBox, {po = cc.sizep(size, ui.cc)})
    editBox:setFontSize(18)
    editBox:setFontColor(ccc3FromInt("#5d5d5d"))
    editBox:setInputMode(inputType)
    editBox:setPlaceHolder(placeHolder)
    editBox:setPlaceholderFontSize(18)
    editBox:setPlaceholderFontColor(ccc3FromInt("#c5c5c5"))
    editBox:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)
    editBox:setMaxLength(length)

    return editBox
end

---------------------------------------------------------------------
-- public

function AccountMigrationView:updateResultLayerVisible(visible)
    self:getViewData().resultLayer:setVisible(visible)
    self:getViewData().migrationLayer:setVisible(not visible)
end

function AccountMigrationView:resetCodeState()
    self:resetCodeBtnState()

    self:getViewData().codeEditBox:setText("")
end

function AccountMigrationView:resetCodeBtnState()
    self:getViewData().codeBtn:setEnabled(true)
    self:getViewData().codeBtn:setText(__("获取验证码"))
end


return AccountMigrationView
