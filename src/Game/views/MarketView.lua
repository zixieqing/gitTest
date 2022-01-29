--[[
市场系统UI
--]]
local GameScene = require( "Frame.GameScene" )

local MarketView = class('MarketView', GameScene)

local RES_DICT = {
	Btn_Normal 			= "ui/common/common_btn_sidebar_common.png",
	Btn_Pressed 		= "ui/common/common_btn_sidebar_selected.png",

}

function MarketView:ctor( ... )
	self.viewData_ = nil

	local view = require("common.TitlePanelBg").new({ title = __('市场'), type = 13, cb = function()
        PlayAudioByClickClose()
        self:runAction(cc.RemoveSelf:create())
        AppFacade.GetInstance():UnRegsitMediator("MarketMediator")
    end})
	display.commonUIParams(view, {ap = display.CENTER, po = cc.p(display.cx, display.cy)})
	self:addChild(view)

	local function CreateView()
		local layout = CLayout:create(cc.size(1190, 641))
		local frameSize = layout:getContentSize()

		-- 添加多个按钮功能
		local tabsData = {
			{name = __('购买'), tag = 1001, },
			{name = __('出售'), tag = 1002, },
			{name = __('售后'), tag = 1003, }
		}
		local buttons = {}
		local tabNameLabels = {}
		for i,v in ipairs(tabsData) do
			local tabButton = display.newCheckBox(0, 0,
				{n = _res(RES_DICT.Btn_Normal),
				s = _res(RES_DICT.Btn_Pressed)})

			local buttonSize = tabButton:getContentSize()

			display.commonUIParams(
				tabButton,
				{
					ap = cc.p(1, 0.5),
					po = cc.p(frameSize.width,
						frameSize.height - 40 - (i) * (buttonSize.height - 20))
				})
			layout:addChild(tabButton, layout:getLocalZOrder() - 1)
			tabButton:setTag(v.tag)

			buttons[tostring( v.tag )] = tabButton
			local tabNameLabel = display.newLabel(utils.getLocalCenter(tabButton).x - 5 , utils.getLocalCenter(tabButton).y +15,
				{ttf = true, w  =120 , hAlign = display.TAC,  font = fontWithColor('2').font, text = v.name, fontSize = 22, color = fontWithColor('2').color, reqH = 50,  ap = cc.p(0.5, 0.5)})
			tabButton:addChild(tabNameLabel)
			tabNameLabels[tostring( v.tag )] = tabNameLabel
		end
		-- 展示页面
		local modelLayout = CLayout:create(cc.size(1082, 641))
		modelLayout:setAnchorPoint(cc.p(0, 0))
		modelLayout:setPosition(cc.p(0, 0))
		layout:addChild(modelLayout)

		view:AddContentView(layout)
		return {
			view 			= layout,
			buttons     	= buttons,
			tabNameLabels   = tabNameLabels,
			modelLayout     = modelLayout
		}
	end
	self.viewData_ = CreateView()
end

return MarketView
