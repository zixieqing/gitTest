--[[
    登记个人信息弹窗
--]]
local shareFacade = AppFacade.GetInstance()

local RecordInfoLayer = class('RecordInfoLayer', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.RecordInfoLayer'
	node:enableNodeEvents()
	print('RecordInfoLayer', ID(node))
	return node
end)

function RecordInfoLayer:ctor( ... )
	self.args = unpack({...}) or {}

	local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 122))
	eaterLayer:setTouchEnabled(true)
	eaterLayer:setContentSize(self:getContentSize())
	eaterLayer:setPosition(utils.getLocalCenter(self))
	self:addChild(eaterLayer)
	eaterLayer:setOnClickScriptHandler(function()
		PlayAudioByClickClose()
		if self.args.cb then
			self.args.cb()
			self:runAction(cc.RemoveSelf:create())
		else
			shareFacade:UnRegsitMediator("RecordInfoMediator")
		end
	end)

	local function CreateView()
		local actionButtons = {}

		local bg = display.newLayer(utils.getLocalCenter(self).x, utils.getLocalCenter(self).y, {enable = true, bg = _res('ui/common/common_bg_9.png'), ap = cc.p(0.5, 0.5)})
		self:addChild(bg)
		local bgSize = bg:getContentSize()

		local xx = display.cx
    	local yy = display.cy - bgSize.height / 2 - 14
    	local closeLabel = display.newButton(xx,yy,{
    	    n = _res('ui/common/common_bg_close.png'),-- common_click_back
    	})
    	closeLabel:setEnabled(false)
    	display.commonLabelParams(closeLabel,{fontSize = 18,text = __('点击空白处关闭')})
		self:addChild(closeLabel, 10)
		
		-- title
		local titleBg = display.newButton(0, 0, {n = _res('ui/common/common_bg_title_2.png'), animation = false})
		display.commonUIParams(titleBg, {po = cc.p(bgSize.width * 0.5, bgSize.height - titleBg:getContentSize().height * 0.5 -3)})
		display.commonLabelParams(titleBg,
			{text = __('登记信息'),
			fontSize = fontWithColor('3').fontSize, color = fontWithColor('3').color,
			offset = cc.p(0, -2)})
        bg:addChild(titleBg)

		local nameLabel = display.newLabel(utils.getLocalCenter(bg).x, bgSize.height * 0.86,
			fontWithColor(6,{text = __('请输入您的姓名')}))
        bg:addChild(nameLabel)
        
		local nameBox = ccui.EditBox:create(cc.size(300, 44), _res('ui/common/common_bg_input_default.png'))
		display.commonUIParams(nameBox, {po = cc.p(utils.getLocalCenter(bg).x, bgSize.height * 0.86 - 40)})
		bg:addChild(nameBox)
		nameBox:setFontSize(fontWithColor('M2PX').fontSize)
		nameBox:setFontColor(ccc3FromInt('#9f9f9f'))
		nameBox:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
		-- nameBox:setPlaceHolder(__('请输入姓名'))
		nameBox:setPlaceholderFontSize(fontWithColor('M2PX').fontSize)
		nameBox:setPlaceholderFontColor(ccc3FromInt('#9c9c9c'))
		nameBox:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)
		-- nameBox:setMaxLength(12)

		local phoneLabel = display.newLabel(utils.getLocalCenter(bg).x, bgSize.height * 0.7,
			fontWithColor(6,{text = __('请输入您的电话号码')}))
        bg:addChild(phoneLabel)
        
		local phoneBox = ccui.EditBox:create(cc.size(300, 44), _res('ui/common/common_bg_input_default.png'))
		display.commonUIParams(phoneBox, {po = cc.p(nameBox:getPositionX(), bgSize.height * 0.7 - 40)})
		bg:addChild(phoneBox)
		phoneBox:setFontSize(fontWithColor('M2PX').fontSize)
		phoneBox:setFontColor(ccc3FromInt('#9f9f9f'))
		phoneBox:setInputMode(cc.EDITBOX_INPUT_MODE_PHONENUMBER)
		phoneBox:setPlaceholderFontSize(fontWithColor('M2PX').fontSize)
		phoneBox:setPlaceholderFontColor(ccc3FromInt('#9c9c9c'))
		phoneBox:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)
		-- phoneBox:setMaxLength(12)

		local addressLabel = display.newLabel(utils.getLocalCenter(bg).x, bgSize.height * 0.54,
			fontWithColor(6,{text = __('请输入您的地址')}))
        bg:addChild(addressLabel)
        
		local addressBox = ccui.EditBox:create(cc.size(300, 44), _res('ui/common/common_bg_input_default.png'))
		display.commonUIParams(addressBox, {po = cc.p(nameBox:getPositionX(), bgSize.height * 0.54 - 40)})
		bg:addChild(addressBox)
		addressBox:setFontSize(fontWithColor('M2PX').fontSize)
		addressBox:setFontColor(ccc3FromInt('#9f9f9f'))
		addressBox:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
		addressBox:setPlaceholderFontSize(fontWithColor('M2PX').fontSize)
		addressBox:setPlaceholderFontColor(ccc3FromInt('#9c9c9c'))
		addressBox:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)
		-- addressBox:setMaxLength(12)

        local confirmButton = display.newButton(bgSize.width * 0.5, bgSize.height * 0.2, {n = _res('ui/common/common_btn_orange.png')})
	    display.commonLabelParams(confirmButton, fontWithColor(14,{text = __('确认')}))
		bg:addChild(confirmButton)
		confirmButton:setTag(1004)
		actionButtons[tostring(1004)] = confirmButton

		return {
			nameBox = nameBox,
			phoneBox = phoneBox,
			addressBox = addressBox,
			actionButtons = actionButtons,
		}
	end

	xTry(function ( )
		self.viewData = CreateView( )
	end, __G__TRACKBACK__)
end

return RecordInfoLayer
