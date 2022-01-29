--[[
好友系统View
--]]
local GameScene = require( "Frame.GameScene" )

local FriendView = class('FriendView', GameScene)

local RES_DICT = {
	Btn_Normal 			= "ui/common/common_btn_sidebar_common.png",
	Btn_Pressed 		= "ui/common/common_btn_sidebar_selected.png",
}
function FriendView:ctor( ... )
	self.viewData_ = nil
	local view = require("common.TitlePanelBg").new({ title = __('好友'), type = 99, cb = function()
        PlayAudioByClickClose()
        AppFacade.GetInstance():UnRegsitMediator('FriendMediator')
        -- AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = "FriendMediator"},
        -- {name = "HomeMediator"})

    end})

	display.commonUIParams(view, {ap = display.CENTER, po = cc.p(display.cx, display.cy)})
	self:addChild(view)
	local function CreateView( ... )
		local cview = CLayout:create(cc.size(1250,641))
		local size  = cview:getContentSize()
		--添加多个按钮功能
		local taskCData = {
			{name = __('好友'), iconPath = '', tag = 1001, },
			{name = __('捐助'), iconPath = '', tag = 1002, },
		}
		-- 添加好友切磋开关
		if GAME_MODULE_OPEN.FRIEND_BATTLE then
			table.insert(taskCData, {name = __('切磋'), iconPath = '', tag = 1003, })
		end
		local frameSize = cview:getContentSize()
		local buttons = {}
		for i,v in ipairs(taskCData) do
			local tabButton = display.newCheckBox(0,0,
				{n = _res(RES_DICT.Btn_Normal),
				s = _res(RES_DICT.Btn_Pressed),})

			local buttonSize = tabButton:getContentSize()

			display.commonUIParams(
				tabButton,
				{
					ap = cc.p(1, 0.5),
					po = cc.p(frameSize.width + 4,
						frameSize.height - 50 - (i) * (buttonSize.height - 20))
				})
			cview:addChild(tabButton, cview:getLocalZOrder() - 1)
			tabButton:setTag(v.tag)
			buttons[tostring( v.tag )] = tabButton


			local tabNameLabel1 = display.newLabel(utils.getLocalCenter(tabButton).x - 5 , utils.getLocalCenter(tabButton).y,
				fontWithColor(2,{text = v.name, color = '#5c5c5c', fontSize = 22, ap = cc.p(0.5, 0)}))
			tabButton:addChild(tabNameLabel1)
			tabNameLabel1:setName('title')
			tabNameLabel1:setTag(3)
			local remindIcon = display.newImageView(_res('ui/common/common_hint_circle_red_ico.png'), 100, 100)
			remindIcon:setName('remindIcon')
			tabButton:addChild(remindIcon, 10)
			remindIcon:setVisible(false)
		end

		local modelLayout = CLayout:create(cc.size(1068, 574))
		modelLayout:setAnchorPoint(cc.p(0,0))
		modelLayout:setPosition(cc.p(40,10))
		cview:addChild(modelLayout)

		view:AddContentView(cview)
		return {
			view 			= cview,
			buttons         = buttons,
			modelLayout     = modelLayout
		}
	end
	self.viewData_ = CreateView()
end

return FriendView
