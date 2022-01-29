--[[
登录弹窗
--]]
local RegistLayer = class('RegistLayer', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.RegistLayer'
	node:enableNodeEvents()
	print('RegistLayer', ID(node))
	return node
end)


function RegistLayer:ctor( ... )
	self.args = unpack({...})

	local function CreateView()
		local actionButtons = {}

		local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 122))
		eaterLayer:setTouchEnabled(true)
		eaterLayer:setContentSize(self:getContentSize())
		eaterLayer:setPosition(utils.getLocalCenter(self))
		self:addChild(eaterLayer)

		if isEliteSDK() then
			SS_SHOW_INVITECODE = true
		end
        local bgSize = cc.size(652, 488)
        if SS_SHOW_INVITECODE then
            bgSize = cc.size(652, 534)
        end
		local bg = display.newLayer(utils.getLocalCenter(self).x, utils.getLocalCenter(self).y, {bg = _res('ui/author/login_bg_account.png'), ap = cc.p(0.5, 0.5),
            scale9 = true, size = bgSize})
		self:addChild(bg)
		-- local bgSize = bg:getContentSize()

		local titleBg = display.newImageView(_res('ui/author/login_bg_title.png'), utils.getLocalCenter(bg).x, bgSize.height, {ap = cc.p(0.5, 1)})
		bg:addChild(titleBg)

		local titleLabel = display.newLabel(utils.getLocalCenter(titleBg).x, utils.getLocalCenter(titleBg).y,
			{text = __('注册新帐号'), fontSize = fontWithColor('M2PX').fontSize, color = fontWithColor('TC1').color})
		titleBg:addChild(titleLabel)

		local backBtn = display.newButton(0, 0, {n = _res('ui/author/login_btn_back.png')})
		display.commonUIParams(backBtn, {po = cc.p(15 + backBtn:getContentSize().width * 0.5, bgSize.height - 15 - backBtn:getContentSize().height * 0.5)})
		bg:addChild(backBtn)
		backBtn:setTag(10040)
		actionButtons[tostring(10040)] = backBtn

        local offsetY = 16
		local nameBox = ccui.EditBox:create(cc.size(500, 70), _res('ui/author/login_bg_Accounts_info.png'))
		display.commonUIParams(nameBox, {po = cc.p(utils.getLocalCenter(bg).x, bgSize.height * 0.75)})
        if SS_SHOW_INVITECODE then 
            display.commonUIParams(nameBox, {po = cc.p(utils.getLocalCenter(bg).x, bgSize.height * 0.78)})
        end
		bg:addChild(nameBox)
		nameBox:setFontSize(fontWithColor('M2PX').fontSize)
		nameBox:setFontColor(ccc3FromInt('#9f9f9f'))
		nameBox:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
		nameBox:setPlaceHolder(__('请输入用户名'))
		nameBox:setPlaceholderFontSize(fontWithColor('M2PX').fontSize)
		nameBox:setPlaceholderFontColor(ccc3FromInt('#9c9c9c'))
		nameBox:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)
		nameBox:setMaxLength(12)

		local passBox = ccui.EditBox:create(cc.size(500, 70), _res('ui/author/login_bg_Accounts_info.png'))
		display.commonUIParams(passBox, {po = cc.p(nameBox:getPositionX(), nameBox:getPositionY() - passBox:getContentSize().height - offsetY)})
		bg:addChild(passBox)
		passBox:setFontSize(fontWithColor('M2PX').fontSize)
		passBox:setFontColor(ccc3FromInt('#9f9f9f'))
		passBox:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
		passBox:setInputFlag(cc.EDITBOX_INPUT_FLAG_PASSWORD)
		passBox:setPlaceHolder(__('请输入6-12位密码'))
		passBox:setPlaceholderFontSize(fontWithColor('M2PX').fontSize)
		passBox:setPlaceholderFontColor(ccc3FromInt('#9c9c9c'))
		passBox:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)
		passBox:setMaxLength(12)

		local mailBox = ccui.EditBox:create(cc.size(500, 70), _res('ui/author/login_bg_Accounts_info.png'))
		display.commonUIParams(mailBox, {po = cc.p(nameBox:getPositionX(), passBox:getPositionY() - mailBox:getContentSize().height - offsetY)})
		bg:addChild(mailBox)
		mailBox:setFontSize(fontWithColor('M2PX').fontSize)
		mailBox:setFontColor(ccc3FromInt('#9f9f9f'))
		mailBox:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
		mailBox:setPlaceHolder(__('请输入邮箱'))
		mailBox:setPlaceholderFontSize(fontWithColor('M2PX').fontSize)
		mailBox:setPlaceholderFontColor(ccc3FromInt('#9c9c9c'))
		mailBox:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)


        local positionY = bgSize.height * 0.175
        if SS_SHOW_INVITECODE then
            positionY = 68
        end
		local registButton = display.newButton(bgSize.width * 0.5, positionY, {n = _res('ui/author/login_btn_create_new.png')})
		display.commonLabelParams(registButton, {text = __('注  册'), fontSize = fontWithColor('M2PX').fontSize, color = fontWithColor('BC').color})
		bg:addChild(registButton)
		registButton:setTag(1005)
		actionButtons[tostring(1005)] = registButton

        local viewData = {
			nameBox = nameBox,
			passBox = passBox,
			mailBox = mailBox,
			actionButtons = actionButtons,
		}
		if SS_SHOW_INVITECODE then
            local inviteCodBox = ccui.EditBox:create(cc.size(500, 70), _res('ui/author/login_bg_Accounts_info.png'))
            display.commonUIParams(inviteCodBox, {po = cc.p(mailBox:getPositionX(), mailBox:getPositionY() - inviteCodBox:getContentSize().height - offsetY)})
            bg:addChild(inviteCodBox)
            inviteCodBox:setFontSize(fontWithColor('M2PX').fontSize)
            inviteCodBox:setFontColor(ccc3FromInt('#9f9f9f'))
            inviteCodBox:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
            inviteCodBox:setPlaceHolder(__('请输入邀请码'))
            inviteCodBox:setPlaceholderFontSize(fontWithColor('M2PX').fontSize)
            inviteCodBox:setPlaceholderFontColor(ccc3FromInt('#9c9c9c'))
            inviteCodBox:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)
            viewData.inviteCodeBox = inviteCodBox
        end
        return viewData
	end

	xTry(function ( )
		self.viewData = CreateView( )
	end, __G__TRACKBACK__)
end


return RegistLayer
