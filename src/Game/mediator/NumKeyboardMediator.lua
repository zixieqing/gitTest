--[[
数字键盘
@params
M nums     ：最高可输入位数 必须传 比如参数为2即只能输入2位数
M model 	 ：键盘输入模式 必须传  1为输入密码模式 该模式必须输入满传入的最高可输入位数   2为自由输入模式 可随意输入最高可输入位数的数字
O callback ：回调函数。返回值为输入的数字 string
O titleText：标题文字 默认为'请输入数字密码'
O defaultContent：默认显示的文字
--]]
local Mediator = mvc.Mediator

local NumKeyboardMediator = class("NumKeyboardMediator", Mediator)


local NAME = "NumKeyboardMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
function NumKeyboardMediator:ctor(params, viewComponent )
	self.super:ctor(NAME,viewComponent)

	-- 初始化参数
	self.callback = nil
	self.nums = 1
	self.titleText = ''
	self.model = 1 --输入模式 1：密码。2：随意输入

	if params then
		self.callback = params.callback
		self.nums = params.nums
		self.titleText = params.titleText or __('请输入数字密码')
		self.model = params.model or 1
		self.defaultContent = params.defaultContent or ''
	end
end


function NumKeyboardMediator:InterestSignals()
	local signals = {

	}

	return signals
end

function NumKeyboardMediator:ProcessSignal(signal )
	local name = signal:GetName()
	print(name)
	-- dump(signal:GetBody())
end


function NumKeyboardMediator:Initial( key )
	self.super.Initial(self,key)

	-- 初始化场景
	local scene = uiMgr:GetCurrentScene()
	local viewComponent  = require( 'Game.views.NumKeyboardView' ).new({nums = self.nums, model = self.model})
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	scene:AddDialog(viewComponent)

	local viewComponent = self:GetViewComponent()
	self.viewData = viewComponent.viewData

 	for i,v in ipairs(viewComponent.viewData.clickNums) do
 		v:setOnClickScriptHandler(handler(self,self.ClickButtonActions))
 	end

 	display.commonUIParams(self.viewData.eaterButton, {cb = function (sender)
 		self:CloseSelf()
 	end})

 	self.viewData.titleLabel:setString(self.titleText)
 	self.next = 1
 	if self.model == 1 then
	 	self:SetConfirmOrCancel(false)
	else
		self:SetConfirmOrCancel(true)
	end

	-- 初始化默认显示的内容
	self:InitDefaultContent(self.defaultContent)
end


function NumKeyboardMediator:ClickButtonActions( sender )
	PlayAudioByClickNormal()

	local tag = sender:getTag()

	if tag ~= 888 and tag ~= 999 then
		if self.model == 1 then

			------------ 清空默认的文字 ------------
			if 1 == self.next then
				self:ClearDefaultContent()
			end
			------------ 清空默认的文字 ------------

			------------ 填充选中的文字 ------------
			if self.nums >= self.next then
				self.viewData.showNums[self.next]:setString(tostring(tag))

				self.next = self.next + 1

				-- 设置右下按钮为确定
				self:SetConfirmOrCancel(self:CanConfirm())
			end
			------------ 填充选中的文字 ------------

		else

			------------ 清空默认的文字 ------------
			if 1 == self.next then
				self:ClearDefaultContent()
			end
			------------ 清空默认的文字 ------------

			------------ 填充选中的文字 ------------
			if self.nums < self.next then
				uiMgr:ShowInformationTips(string.fmt(__('最高只能输入_num_位数'), { _num_ = self.nums}))
				return
			end

			local str = self.viewData.showNums[1]:getString() .. tag
			self.viewData.showNums[1]:setString(str)

			self.next = self.next + 1
			------------ 填充选中的文字 ------------

		end

	elseif 888 == tag then
		-- 回退一格
		if 1 == self.model then
			------------ 清空默认的文字 ------------
			if 1 == self.next then
				self:ClearDefaultContent()
			end
			------------ 清空默认的文字 ------------

			-- 计数器-1
			self.next = math.max(1, self.next - 1)
			-- 刷新数字
			if 1 <= self.next then
				self.viewData.showNums[self.next]:setString('')
			end
			-- 设置右下按钮为确定
			self:SetConfirmOrCancel(self:CanConfirm())
		else
			------------ 清空默认的文字 ------------
			if 1 == self.next then
				self:ClearDefaultContent()
			end
			------------ 清空默认的文字 ------------

			if 1 == self.next then
				self.viewData.showNums[1]:setString('')
			else
				self.next = self.next - 1
				local str = self.viewData.showNums[1]:getString()
				if 1 == self.next then
					str = ''
				else
					str = string.sub(str, 1, math.max(1, self.next - 1))
				end
				self.viewData.showNums[1]:setString(str)
			end
		end

	elseif 999 == tag then

		if self:CanConfirm() then
			-- 提交
			if self.callback then
				local str = ''
				for i, v in ipairs(self.viewData.showNums) do
					str = str .. v:getString()
				end
				self.callback(str)
				self:CloseSelf()
			end
 		else
			PlayAudioByClickClose()
			self:CloseSelf()
		end

	end
end


function NumKeyboardMediator:OnRegist(  )
	AppFacade.GetInstance():DispatchObservers(FRIEND_REFRESH_EDITBOX, {isEnabled = false ,tag = DISABLE_EDITBOX_MEDIATOR.CHAT_INPUT_TAG})

end

function NumKeyboardMediator:OnUnRegist(  )
	AppFacade.GetInstance():DispatchObservers(FRIEND_REFRESH_EDITBOX, {isEnabled = true ,tag = DISABLE_EDITBOX_MEDIATOR.CHAT_INPUT_TAG})
	-- 移除本界面
	self:GetViewComponent():setVisible(false)
	local scene = uiMgr:GetCurrentScene()
	scene:RemoveGameLayer(self:GetViewComponent())
end
--[[
初始化默认显示的内容
@params content string 默认显示的内容
--]]
function NumKeyboardMediator:InitDefaultContent(content)
	local contentLength = string.len(string.gsub(content, ' ', ''))
	if 0 < contentLength then
		if 1 == self.model then
			for i,v in ipairs(self.viewData.showNums) do
				local char = string.sub(content, i, i)
				if nil ~= char then
					v:setString(char)
				end
			end
		else
			display.commonLabelParams(self.viewData.showNums[1] , {reqW = 500 , text = content})
		end
	end
end
--[[
清空默认显示的内容
--]]
function NumKeyboardMediator:ClearDefaultContent()
	if 1 == self.model then
		for i,v in ipairs(self.viewData.showNums) do
			v:setString('')
		end
	else
		self.viewData.showNums[1]:setString('')
	end
end
--[[
关闭自己
--]]
function NumKeyboardMediator:CloseSelf()
	AppFacade.GetInstance():UnRegsitMediator(NAME)
end
--[[
设置右下按钮样式
@params confirm bool 是否是确定按钮
--]]
function NumKeyboardMediator:SetConfirmOrCancel(confirm)
	local btn = self:GetViewComponent().viewData.clickNums[#self:GetViewComponent().viewData.clickNums]

	local nImagePath = 'ui/home/numkeyboard/password_keyboard_btn_default.png'
	local sImagePath = 'ui/home/numkeyboard/password_keyboard_btn_press.png'
	local str = __('取消')
	local color = '#78564b'

	if confirm then
		nImagePath = 'ui/home/numkeyboard/password_keyboard_btn_ok.png'
		sImagePath = 'ui/home/numkeyboard/password_keyboard_btn_ok.png'
		str = __('确定')
		color = '#ffffff'
	end

	btn:setNormalImage(_res(nImagePath))
	btn:setSelectedImage(_res(sImagePath))

	btn:getLabel():setString(str)
	btn:getLabel():setColor(ccc3FromInt(color))
end
function NumKeyboardMediator:GoogleBack()
	app:UnRegsitMediator(NAME)
	return true
end
--[[
是否可以提交数字
@return result 是否可以提交数字
--]]
function NumKeyboardMediator:CanConfirm()
	local result = true
	if 1 == self.model and self.nums >= self.next then
		result = false
	end
	return result
end

return NumKeyboardMediator
