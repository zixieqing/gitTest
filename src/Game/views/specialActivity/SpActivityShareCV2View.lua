--[[
 * author : liuzhipeng
 * descpt : 特殊活动 通用跳转页签view
--]]
local SpActivityShareCV2View = class('SpActivityShareCV2View', function ()
	local node = CLayout:create()
	node.name = 'home.SpActivityShareCV2View'
	node:enableNodeEvents()
	return node
end)
local RES_DICT = {
	BTN_BG     = _res('ui/home/specialActivity/unni_activity_bg_button.png'),
	COMMON_BTN = _res('ui/common/common_btn_orange_big.png')
}
function SpActivityShareCV2View:ctor( ... )
	local args = unpack({...})
	self.size = args.size
	self:InitUI()
end

function SpActivityShareCV2View:InitUI()
	local size = self.size
	self:setContentSize(size)
	local function CreateView()
		local view = CLayout:create(size)
		local btnBg = display.newImageView(RES_DICT.BTN_BG, size.width / 2 + 273, size.height / 2 - 200)
		view:addChild(btnBg, 2)
		local enterPlotBtn = display.newButton(size.width / 2 + 273, size.height / 2 - 200, {n = RES_DICT.COMMON_BTN})
		view:addChild(enterPlotBtn, 3)
		local textLabel = display.newLabel(enterPlotBtn:getContentSize().width / 2, enterPlotBtn:getContentSize().height / 2, fontWithColor(14, {text = __('情节播放')}))
		enterPlotBtn:addChild(textLabel, 1)

		local btnBg = display.newImageView(RES_DICT.BTN_BG, size.width / 2 , size.height / 2 - 200)
		view:addChild(btnBg, 2)
		local enterTaskBtn = display.newButton(size.width / 2, size.height / 2 - 200, {n = RES_DICT.COMMON_BTN})
		view:addChild(enterTaskBtn, 3)
		local textLabel = display.newLabel(enterPlotBtn:getContentSize().width / 2, enterPlotBtn:getContentSize().height / 2, fontWithColor(14, {text = __('前往拼图')}))
		enterTaskBtn:addChild(textLabel, 1)
		return {
			view                 = view,
			enterPlotBtn             = enterPlotBtn,
			enterTaskBtn             = enterTaskBtn,
		}
	end
	xTry(function ( )
		self.viewData = CreateView()
		self.viewData.view:setPosition(utils.getLocalCenter(self))
		self:addChild(self.viewData.view, 1)
	end, __G__TRACKBACK__)
end

return SpActivityShareCV2View
