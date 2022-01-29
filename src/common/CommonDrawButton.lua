--[[
通用领取按钮版式
@params table {
	drawState int  1 不可领取
				   2 可领取
				   3 已领取
	drawStateTexts table 领取状态文字列表
	drawStateImgs  table 领取状态图片列表
}
--]]
local CommonDrawButton = class('CommonDrawButton', function ()
	-- local node = CButton:create()
	-- node.name = 'common.CommonDrawButton'
	-- node:enableNodeEvents()
	local node = CLayout:create(cc.size(123, 62))
	node.name = 'common.CommonDrawButton'
	node:enableNodeEvents()
	return node
end)

local RES_DIR = {
	COMMON_BTN           = _res('ui/common/common_btn_orange.png'),
    COMMON_BTN_DISABLE   = _res('ui/common/common_btn_orange_disable.png'),
    COMMON_BTN_DRAWN     = _res('ui/common/activity_mifan_by_ico.png'),
}

--[[
contrustor
--]]
function CommonDrawButton:ctor( ... )
	local args = unpack({...}) or {}
	self:InitButton(args)
	-- self:InitButtonCommonParams(args)

	self.curDrawState   = args.drawState or 1
	self.drawStateTexts = args.drawStateTexts or {
		[1] = __('领取'),
		[2] = __('领取'),
		[3] = __('已领取'),
	}
	self.drawStateImgs  = args.drawStateImgs or {
		[1] = RES_DIR.COMMON_BTN_DISABLE,
		[2] = RES_DIR.COMMON_BTN,
		[3] = RES_DIR.COMMON_BTN_DRAWN,
	}
	self:InitUI()
end
---------------------------------------------------
-- logic init begin --
---------------------------------------------------

function CommonDrawButton:InitButton(params)
	local btnParams = params.btnParams or {}
	local size = btnParams.size or cc.size(123, 62)
	self:setContentSize(size)
	
	local btn = display.newButton(size.width / 2, size.height / 2, btnParams)
	display.commonUIParams(btn, {ap = display.CENTER})
    self:addChild(btn)

	local receivedLabel = display.newLabel(0, 0, fontWithColor(7, {fontSize = 24}))
    display.commonUIParams(receivedLabel, {po = utils.getLocalCenter(btn), ap = display.CENTER})
    btn:addChild(receivedLabel, 5)
    -- receivedLabel:setVisible(false)

	self.receivedLabel = receivedLabel
	self.btn = btn
end

-- function CommonDrawButton:InitButtonCommonParams(params)
-- 	local scale9 = false
-- 	if params.scale9 or params.capInsets then
--         scale9 = true
--         params.capInsets = params.capInsets or RECT_ZERO
--         params.rect = params.rect or RECT_ZERO
--     end
--     if scale9 == true then
--         self:setScale9Enabled(true)
--     end
-- end

--[[
初始化样式
--]]
function CommonDrawButton:InitUI()
	------------ 按钮底板 ------------
	local img = self:GetImgByDrawState(self.curDrawState)
	self.btn:setNormalImage(img)
	self.btn:setDisabledImage(img)
	------------ 按钮底板 ------------

	------------ 按钮文字 ------------
	local isState3 = self.curDrawState == 3
	local text = self:GetTextByDrawState(self.curDrawState)
	local btnLabel = self.btn:getLabel()
	btnLabel:setVisible(not isState3)
	self.receivedLabel:setVisible(isState3)
	
	if isState3 then
		display.commonLabelParams(self.receivedLabel, {text = text})
	else
		display.commonLabelParams(self.btn, fontWithColor(14, {text = text}))
	end
	------------ 按钮文字 ------------
end

function CommonDrawButton:RefreshUI(args)
	self.curDrawState = args.drawState or 1
	self:InitUI()
end

--[[
初始化按钮回调
--]]
function CommonDrawButton:InitClickCallback()
	display.commonUIParams(self.btn, {cb = handler(self, self.ClickHandler)})
end

function CommonDrawButton:SetCallback(cb)
	if cb then
		self.ClickHandler = cb
		self:InitClickCallback()
	end
end

function CommonDrawButton:SetButtonEnable(enable)
	self.btn:setEnabled(checkbool(enable))
end

---------------------------------------------------
-- logic init end --
---------------------------------------------------

---------------------------------------------------
-- get/set begin --
---------------------------------------------------

--[[
通关领取状态获取按钮文本信息
--]]
function CommonDrawButton:GetTextByDrawState(drawState)
	return self.drawStateTexts[drawState] or __('领取')
end

--[[
通关领取状态获取按钮底板
--]]
function CommonDrawButton:GetImgByDrawState(drawState)
	return self.drawStateImgs[drawState] or RES_DIR.COMMON_BTN
end

---------------------------------------------------
-- get/set end --
---------------------------------------------------
return CommonDrawButton
