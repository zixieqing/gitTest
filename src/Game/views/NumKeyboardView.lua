--[[
输入数字的通用界面
@params table {
	nums int 最大输入数字位数
	model int 模式 1 密码 2 随意输入
}
--]]
local GameScene = require( "Frame.GameScene" )
local NumKeyboardView = class('NumKeyboardView', GameScene)

------------ import ------------
local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
------------ import ------------

------------ define ------------
local numsConfig = {
	1, 2, 3, 888,
	4, 5, 6, 0,
	7, 8, 9, 999
}
------------ define ------------

--[[
constructor
--]]
function NumKeyboardView:ctor( ... )
	local args = unpack({...})

	self.nums = args.nums
	self.model = args.model

	self:InitUI()
end
---------------------------------------------------
-- view control begin --
---------------------------------------------------
--[[
初始化ui
--]]
function NumKeyboardView:InitUI()

	local CreateView = function ()

		local layerSize = self:getContentSize()
		self:setBackgroundColor(cc.c4b(0, 0, 0, 180))

		-- 吃触摸
		local eaterButton = display.newButton(0, 0, {size = layerSize, animate = false})
		display.commonUIParams(eaterButton, {ap = cc.p(0.5, 0.5), po = utils.getLocalCenter(self)})
		self:addChild(eaterButton, 1)

		-- 键盘层
		local keyboardSize = cc.size(layerSize.width, 450)
		local keyboardLayer = display.newLayer(0, 0, {size = keyboardSize})
		display.commonUIParams(keyboardLayer, {ap = cc.p(0.5, 0.5), po = cc.p(
			display.cx,
			keyboardSize.height * 0.5
		)})
		self:addChild(keyboardLayer, 5)

		-- 键盘吃触摸
		local keyboardEaterButton = display.newButton(0, 0, {size = keyboardSize, animate = false})
		display.commonUIParams(keyboardEaterButton, {ap = cc.p(0.5, 0.5), po = utils.getLocalCenter(keyboardLayer)})
		keyboardLayer:addChild(keyboardEaterButton)

		-- 标题
		local titleLabel = display.newLabel(layerSize.width * 0.5 , keyboardSize.height + 120,
			fontWithColor('7', {text = __('请输入数字密码'), fontSize = 32}))--2b2017
		keyboardLayer:addChild(titleLabel)

		-- 输入板背景图
		local bg = display.newImageView(_res('ui/home/numkeyboard/password_keyboard_bg.png'), 0, 0,
			{ap = cc.p(0, 0), scale9 = true, size = keyboardSize})
		keyboardLayer:addChild(bg)

		-- 创建顶部显示数字按钮
		local showNums = {}
		if 1 == self.model then
			for i = 1, self.nums do
				local topNumBtn = display.newButton(0, 0,
					{n = _res('ui/home/numkeyboard/password_input_frame_default.png')})
				display.commonUIParams(topNumBtn, {ap = cc.p(0, 0), po = cc.p(
					keyboardSize.width * 0.5 - (self.nums * 0.5) * topNumBtn:getContentSize().width + 140 * (i - 1),
					keyboardSize.height + 10
				)})
				display.commonLabelParams(topNumBtn, fontWithColor('8', {text = '', fontSize = 60}))
				keyboardLayer:addChild(topNumBtn)

				table.insert(showNums, topNumBtn:getLabel())
			end
		else
			local topNumBtn = display.newButton(0, 0,
				{n = _res('ui/common/commcon_bg_text.png'), scale9 = true, size = cc.size(540, 80)})
			display.commonUIParams(topNumBtn, {ap = cc.p(0.5, 0), po = cc.p(
				keyboardSize.width * 0.5,
				keyboardSize.height + 10
			)})
			display.commonLabelParams(topNumBtn, fontWithColor('8', {text = '', fontSize = 60}))
			keyboardLayer:addChild(topNumBtn)

			table.insert(showNums, topNumBtn:getLabel())
		end

		-- 创建输入的按钮
		local clickNums = {}
		local index = 1
		local row = 3
		local col = 4
		for i = 1, row do
			for j = 1, col do
				-- 按钮
				local numBtn = display.newButton(0, 0, {
					n = _res('ui/home/numkeyboard/password_keyboard_btn_default.png'),
					s = _res('ui/home/numkeyboard/password_keyboard_btn_press.png')
				})
				display.commonUIParams(numBtn, {ap = cc.p(0.5, 0), po = cc.p(
					keyboardSize.width * 0.5 + (j - 0.5 - col * 0.5) * 300,
					300 - 140 * (i - 1)
				)})
				display.commonLabelParams(numBtn, fontWithColor('8', {text = tostring(numsConfig[index]), fontSize = 80}))
				numBtn:setTag(numsConfig[index])
				keyboardLayer:addChild(numBtn)
				table.insert(clickNums, numBtn)

				if 888 == numsConfig[index] then
					numBtn:getLabel():setString('')
					local image = display.newImageView(_res('ui/home/numkeyboard/password_keyboard_ico_backspace.png'), 0, 0)
					display.commonUIParams(image, {po = utils.getLocalCenter(numBtn)})
					numBtn:addChild(image)
				elseif 999 == numsConfig[index] then
					if 1 == self.model then
						display.commonLabelParams(numBtn, {text = __('取消') , reqW = 250})
					else
                        display.commonLabelParams(numBtn, {fontSize = 70})
						display.commonLabelParams(numBtn, {fontSize = 70, text = __('确定') , reqW = 250})
					end
				end

				index = index + 1
			end
		end


		return {
			view 		= keyboardLayer,
			showNums 	= showNums,
			clickNums 	= clickNums,
			titleLabel 	= titleLabel,
			eaterButton = eaterButton
		}
	end

	xTry(function ( )
		self.viewData = CreateView()
	end, __G__TRACKBACK__)

end
---------------------------------------------------
-- view control end --
---------------------------------------------------

function NumKeyboardView:onEnter()
    -- add touch listener
end

function NumKeyboardView:onExit()
end

return NumKeyboardView
