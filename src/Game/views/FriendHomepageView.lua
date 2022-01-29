--[[
好友主页页面
--]]
local FriendHomepageView = class('FriendHomepageView', function ()
	local node = CLayout:create(cc.size(668, 450))
	node:setAnchorPoint(cc.p(0, 0))
	node.name = 'home.FriendHomepageView'
	node:enableNodeEvents()
	return node
end)

local function CreateView( )
	local size = cc.size(674, 450)
	local view = CLayout:create(size)
	view:setAnchorPoint(0, 0)
	for i=1, 8 do
		local displayBtn = display.newButton(10 + (i-1)%4*172, 240 - math.floor((i-1)/4)*190, {n = _res('ui/home/friend/friend_bg_kongjian_tianjia.png'), ap = cc.p(0, 0)})
		displayBtn:setTag(300 + i)
		view:addChild(displayBtn)
	end


	return {
		view         = view,
	}
end

function FriendHomepageView:ctor( ... )
	self.viewData_ = CreateView()
	self:addChild(self.viewData_.view, 1)
	self.viewData_.view:setPosition(cc.p(0, 0))
end

return FriendHomepageView