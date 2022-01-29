local CreatePlayerInviteCodeView = class('CreatePlayerInviteCodeView', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.createPlayer.CreatePlayerInviteCodeView'
	node:enableNodeEvents()
	return node
end)

local BTN_TAG = {
    -- 邀请码 tag
	TAG_INVITE_CODE_BACK = 2000,
	TAG_INVITE_CODE_CONFIRM = 2001,
}

function CreatePlayerInviteCodeView:ctor( ... )
    self.args = unpack({...})
    
    local function CreateView()
        local view = display.newLayer(0, 0, {size = display.size, ap = display.LEFT_BOTTOM})

        local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 122))
        eaterLayer:setTouchEnabled(true)
        eaterLayer:setContentSize(view:getContentSize())
        eaterLayer:setPosition(utils.getLocalCenter(view))
        view:addChild(eaterLayer)

        local bg = display.newLayer(utils.getLocalCenter(view).x, utils.getLocalCenter(view).y, {bg = _res('ui/author/login_bg_account.png'), ap = cc.p(0.5, 0.5)})
        view:addChild(bg)
        local bgSize = bg:getContentSize()
        bg:addChild(display.newLayer(0,0,{ap = display.LEFT_BOTTOM, color = cc.c4b(0, 0, 0, 0), enable = true, size = bgSize}))

        local titleBg = display.newImageView(_res('ui/author/login_bg_title.png'), utils.getLocalCenter(bg).x, bgSize.height, {ap = cc.p(0.5, 1)})
        bg:addChild(titleBg)

        local titleLabel = display.newLabel(utils.getLocalCenter(titleBg).x, utils.getLocalCenter(titleBg).y,
            {text = __('请输入邀请码'), fontSize = fontWithColor('M2PX').fontSize, color = fontWithColor('TC1').color})
        titleBg:addChild(titleLabel)

        local backBtn = display.newButton(0, 0, {n = _res('ui/author/login_btn_back.png')})
        display.commonUIParams(backBtn, {po = cc.p(15 + backBtn:getContentSize().width * 0.5, bgSize.height - 15 - backBtn:getContentSize().height * 0.5)})
        backBtn:setTag(BTN_TAG.TAG_INVITE_CODE_BACK)
        bg:addChild(backBtn)

        local inviteCode = ccui.EditBox:create(cc.size(500, 70), _res('ui/author/login_bg_Accounts_info.png'))
        display.commonUIParams(inviteCode, {po = cc.p(utils.getLocalCenter(bg).x, bgSize.height * 0.55)})
        bg:addChild(inviteCode)
        inviteCode:setFontSize(fontWithColor('M2PX').fontSize)
        inviteCode:setFontColor(ccc3FromInt('#9f9f9f'))
        inviteCode:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
        inviteCode:setPlaceHolder(__('请输入邀请码'))
        inviteCode:setPlaceholderFontSize(fontWithColor('M2PX').fontSize)
        inviteCode:setPlaceholderFontColor(ccc3FromInt('#9c9c9c'))
        inviteCode:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)

        local confirmButton = display.newButton(bgSize.width * 0.5, bgSize.height * 0.2, {n = _res('ui/author/login_btn_enter_Accounts.png'), scale9 = true, size = cc.size(220, 67)})
        display.commonLabelParams(confirmButton, {text = __('确  定'), fontSize = fontWithColor('M2PX').fontSize, color = fontWithColor('BC').color})
        confirmButton:setTag(BTN_TAG.TAG_INVITE_CODE_CONFIRM)
        bg:addChild(confirmButton)

        return {
            view          = view,
            eaterLayer    = eaterLayer,
            backBtn       = backBtn,
            inviteCode    = inviteCode,
            confirmButton = confirmButton,
            bg            = bg,
        }
    end

    self.viewData = CreateView()
    self:addChild(self.viewData.view)

end

function CreatePlayerInviteCodeView:GetViewData()
    return self.viewData
end

return CreatePlayerInviteCodeView