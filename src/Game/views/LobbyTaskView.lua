--[[
餐厅任务view
--]]
local LobbyTaskView = class('LobbyTaskView', function ()
	local node = CLayout:create(display.size)
	node.name = 'home.LobbyTaskView'
	node:enableNodeEvents()
	return node
end)
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local function CreateView( )
	local view = CLayout:create(display.size)
	local title = display.newButton(display.cx, display.cy + 300, {enable = false, n = _res('ui/common/common_bg_title_3') ,scale9 = true })
	view:addChild(title, 10)
	display.commonLabelParams(title, fontWithColor(4, {text = __('餐厅任务') , paddingW = 60 }))
	local tips = display.newLabel(display.cx, display.cy + 250, fontWithColor(18, {text = __('tips：每次可以从三个任务中选择一个进行完成')}))
	view:addChild(tips, 10)
	local revokeBtn = display.newButton(display.cx, display.cy - 320, {n = _res('ui/common/common_btn_orange.png')})
	view:addChild(revokeBtn, 10)
	revokeBtn:setVisible(false)
	display.commonLabelParams(revokeBtn, fontWithColor(14, {text = __('撤销')}))
		return {
		view 			 = view,
		revokeBtn		 = revokeBtn
	}
end

function LobbyTaskView:ctor( ... )
	local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 255*0.7))
	eaterLayer:setTouchEnabled(true)
	eaterLayer:setContentSize(display.size)
	eaterLayer:setPosition(utils.getLocalCenter(self))
	self:addChild(eaterLayer, -1)
	self.eaterLayer = eaterLayer

	self.viewData_ = CreateView()
	self:addChild(self.viewData_.view, 1)
	self.viewData_.view:setPosition(utils.getLocalCenter(self))
end
return LobbyTaskView