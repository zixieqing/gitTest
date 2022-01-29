--[[
登录弹窗
--]]
local LoginLayer = class('LoginLayer', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.LoginLayer'
	node:enableNodeEvents()
	print('LoginLayer', ID(node))
	return node
end)


function LoginLayer:ctor( ... )
	self.args = unpack({...})

	local function CreateView()
		local actionButtons = {}

		local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 122))
		eaterLayer:setTouchEnabled(true)
		eaterLayer:setContentSize(self:getContentSize())
		eaterLayer:setPosition(utils.getLocalCenter(self))
		self:addChild(eaterLayer)

		-- local bg = display.newImageView(_res('ui/author/login_bg_account.png'), utils.getLocalCenter(self).x, utils.getLocalCenter(self).y)
		local bg = display.newLayer(utils.getLocalCenter(self).x, utils.getLocalCenter(self).y, {bg = _res('ui/author/login_bg_account.png'), ap = cc.p(0.5, 0.5)})
		self:addChild(bg)
		local bgSize = bg:getContentSize()

		local titleBg = display.newImageView(_res('ui/author/login_bg_title.png'), utils.getLocalCenter(bg).x, bgSize.height, {ap = cc.p(0.5, 1)})
		bg:addChild(titleBg)

		local titleLabel = display.newLabel(utils.getLocalCenter(titleBg).x, utils.getLocalCenter(titleBg).y,
			{text = __('帐号登录'), fontSize = fontWithColor('M2PX').fontSize, color = fontWithColor('TC1').color})
		titleBg:addChild(titleLabel)

		local backBtn = display.newButton(0, 0, {n = _res('ui/author/login_btn_back.png')})
		display.commonUIParams(backBtn, {po = cc.p(15 + backBtn:getContentSize().width * 0.5, bgSize.height - 15 - backBtn:getContentSize().height * 0.5)})
		bg:addChild(backBtn)
		backBtn:setTag(10020)
		actionButtons[tostring(10020)] = backBtn

		local nameBox = ccui.EditBox:create(cc.size(500, 70), _res('ui/author/login_bg_Accounts_info.png'))
		display.commonUIParams(nameBox, {po = cc.p(utils.getLocalCenter(bg).x, bgSize.height * 0.7)})
		bg:addChild(nameBox)
		nameBox:setFontSize(fontWithColor('M2PX').fontSize)
		nameBox:setFontColor(ccc3FromInt('#9f9f9f'))
		nameBox:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
		nameBox:setPlaceHolder(__('请输入用户名'))
		nameBox:setPlaceholderFontSize(fontWithColor('M2PX').fontSize)
		nameBox:setPlaceholderFontColor(ccc3FromInt('#9c9c9c'))
		nameBox:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)
		-- nameBox:setMaxLength(12)
		nameBox:registerScriptEditBoxHandler(function(eventType)
	        if eventType == 'began' then  -- 输入开始
	        elseif eventType == 'ended' then  -- 输入结束
	        elseif eventType == 'changed' then  -- 内容变化
	        elseif eventType == 'return' then  -- 从输入返回
	            nameBox:setText(utf8sub(nameBox:getText(), 1, 12))
	        end
	    end)

		local passBox = ccui.EditBox:create(cc.size(500, 70), _res('ui/author/login_bg_Accounts_info.png'))
		display.commonUIParams(passBox, {po = cc.p(nameBox:getPositionX(), nameBox:getPositionY() - passBox:getContentSize().height - 25)})
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

		local registButton = display.newButton(bgSize.width * 0.3, bgSize.height * 0.2, {n = _res('ui/author/login_btn_create_new.png'), scale9 = true, size = cc.size(220, 67)})
		display.commonLabelParams(registButton, {text = __('注  册'), fontSize = fontWithColor('M2PX').fontSize, color = fontWithColor('BC').color})
		bg:addChild(registButton)
		registButton:setTag(1004)
		actionButtons[tostring(1004)] = registButton

		local loginButton = display.newButton(bgSize.width * 0.7, bgSize.height * 0.2, {n = _res('ui/author/login_btn_enter_Accounts.png'), scale9 = true, size = cc.size(220, 67)})
		display.commonLabelParams(loginButton, {text = __('登  录'), fontSize = fontWithColor('M2PX').fontSize, color = fontWithColor('BC').color})
		bg:addChild(loginButton)
		loginButton:setTag(1003)
		actionButtons[tostring(1003)] = loginButton

		return {
			nameBox = nameBox,
			passBox = passBox,
			actionButtons = actionButtons,
		}
	end

	xTry(function ( )
		self.viewData = CreateView( )
	end, __G__TRACKBACK__)
end












return LoginLayer
