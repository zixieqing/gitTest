--[[
好友系统菜单页面
--]]
local FriendMenuView = class('FriendMenuView', function ()
	local node = CLayout:create(cc.size(668, 450))
	node:setAnchorPoint(cc.p(0, 0))
	node.name = 'home.FriendMenuView'
	node:enableNodeEvents()
	return node
end)

local function CreateView( )
	local buttonDatas = {
		{name = __('空间'), iconPath = '', tag = 101, },
		{name = __('餐厅'), iconPath = '', tag = 102, },
		{name = __('冰箱'), iconPath = '', tag = 103, },
		{name = __('切磋'), iconPath = '', tag = 104, },
		{name = __('删除'), iconPath = '', tag = 105, },
	}
	local buttons = {}
	local size = cc.size(674, 450)
	local view = CLayout:create(size)
	view:setAnchorPoint(0, 0)
	local topLine = display.newImageView(_res('ui/home/friend/friend_img_fengexian_right.png'), size.width/2, size.height)
	view:addChild(topLine, 5)
	for i, v in ipairs(buttonDatas) do
		local menuBtn = display.newButton(0, 0, {ap = cc.p(0, 0), n = 'ui/home/friend/friend_bg_shouye.png'})
		view:addChild(menuBtn)
		menuBtn:setTag(v.tag)
		display.commonLabelParams(menuBtn, {text = v.name, fontSize = 24, color = '#ffffff', offset = cc.p(0, 86)})
		if i <= 3 then 
			menuBtn:setPosition(cc.p(27 + (i-1)*217, 230))
		else
			menuBtn:setPosition(cc.p(132 + (i-4)*226, 5))
		end
		buttons[tostring( v.tag )] = menuBtn
	end
	return {
		view    = view,
		buttons = buttons
	}
end

function FriendMenuView:ctor( ... )
	self.viewData_ = CreateView()
	self:addChild(self.viewData_.view, 1)
	self.viewData_.view:setPosition(cc.p(0, 0))
end

return FriendMenuView