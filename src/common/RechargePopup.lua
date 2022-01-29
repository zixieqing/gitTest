--[[
充值界面
@params table {
	mediatorName string parent mediator name
	tag int self tag
	stageId int 关卡id
}
--]]
local CommonPopup = require('common.CommonDialog')
local RechargePopup = class('RechargePopup', CommonPopup)

--[[
override
initui
--]]
function RechargePopup:InitialUI()

	local function CreateView()
		-- bg
		local bg = display.newImageView(_res('ui/common/common_bg_2.png'), 0, 0)
		local bgSize = bg:getContentSize()

		-- bg view
		local view = display.newLayer(0, 0, {size = bgSize, ap = cc.p(0.5, 0.5)})
		display.commonUIParams(bg, {po = cc.p(utils.getLocalCenter(view))})
		view:addChild(bg, 5)

		-- title
		local titleBg = display.newButton(0, 0, {n = _res('ui/common/common_bg_title_2.png'), animation = false})
		display.commonUIParams(titleBg, {po = cc.p(bgSize.width * 0.5, bgSize.height - titleBg:getContentSize().height * 0.5)})
		display.commonLabelParams(titleBg,
			{text = __('充值'),
			fontSize = fontWithColor('SPX').fontSize, color = fontWithColor('BC').color,
			offset = cc.p(0, -2)})
		bg:addChild(titleBg)

		-- -- close btn
		-- local closeBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_quit.png'), animaion = false, cb = handler(self, self.CloseHandler)})
		-- display.commonUIParams(closeBtn, {po = cc.p(bgSize.width - 10 + closeBtn:getContentSize().width * 0.5, bgSize.height - closeBtn:getContentSize().height * 0.5)})
		-- view:addChild(closeBtn, 4)

		-- recharge buttons
		local rechargeInfo = {
			{cash = 6, diamond = 6, iconPath = 'ui/common/recharge_ico_1.png'},
			{cash = 30, diamond = 30, iconPath = 'ui/common/recharge_ico_1.png'},
			{cash = 68, diamond = 68, iconPath = 'ui/common/recharge_ico_1.png'},
			{cash = 128, diamond = 128, iconPath = 'ui/common/recharge_ico_1.png'},
			{cash = 328, diamond = 328, iconPath = 'ui/common/recharge_ico_1.png'},
			{cash = 648, diamond = 648, iconPath = 'ui/common/recharge_ico_1.png'},
		}
		for i,v in ipairs(rechargeInfo) do
			local button = display.newButton(0, 0, {n = 'ui/common/recharge_btn.png', animate = false})
			local btnSize = button:getContentSize()
			display.commonUIParams(button, {
				ap = cc.p(0, 0),
				po = cc.p(35 + (i - 1)%3 * (btnSize.width + 5), bgSize.height - 50 - ((btnSize.height + 20) * math.ceil(i/3)))})
			view:addChild(button, 10)

			local icon = display.newNSprite(_res(v.iconPath), btnSize.width * 0.5, btnSize.height * 0.55)
			button:addChild(icon)

			local diamondLabel = display.newLabel(btnSize.width * 0.5, btnSize.height * 0.85,
				{text = string.format(__('%d幻晶石'), v.diamond), fontSize = 26, color = '#641818'})
			button:addChild(diamondLabel)

			local cashLabel = display.newLabel(btnSize.width * 0.5, btnSize.height * 0.1,
				{text = string.format(__('¥%s'), "--"), fontSize = 30, color = '#ffffff'})
			button:addChild(cashLabel)
		end

		return {
			view = view,
		}
	end

	self.viewData = CreateView()

end


function RechargePopup:CloseHandler()
    self:setVisible(false)
    self:runAction(cc.Sequence:create(cc.DelayTime:create(0.2),cc.RemoveSelf:create()))
end

return RechargePopup
