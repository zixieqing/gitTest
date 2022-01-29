--[[
主界面聊天UI
--]]
local ChatSystemView = class('ChatSystemView', function ()
	local node = CLayout:create(display.size)
	node.name = 'home.CardsListView'
	-- node:setBackgroundColor(cc.c4b(0,100,0,100))
	node:enableNodeEvents()
	return node
end)

local function CreateView( )
	local view = display.newLayer(0,0,{size = cc.size(357,206), ap = cc.p(0,0.5)})
	-- view:setBackgroundColor(cc.c4b(0,100,0,100))
	local bg = display.newImageView(_res('ui/home/chatSystem/main_bg_common_dialogue.png'), 0, 0,
		{scale9 = true, size = cc.size(357,86)})
	bg:setAnchorPoint(cc.p(0,0))
	view:addChild(bg)

	local bgSize = bg:getContentSize()

	local scaleDialogueImg = display.newImageView(_res('ui/home/chatSystem/main_ico_dialogue_arrow.png'), bgSize.width  - 12, bgSize.height - 12)
	scaleDialogueImg:setAnchorPoint(cc.p(0.5,0.5))
	view:addChild(scaleDialogueImg,3)



	--聊天list
	local listSize = cc.size(bgSize.width - 5, bgSize.height - 5)
 	local chatListView = CListView:create(listSize)
 	chatListView:setDirection(eScrollViewDirectionVertical)
 	chatListView:setBounceable(false)
 	chatListView:setAnchorPoint(cc.p(0, 0))
 	chatListView:setPosition(cc.p(2, 2))
 	chatListView:setDragable(false)
 	view:addChild(chatListView,1)
 	-- chatListView:setBackgroundColor(cc.c4b(0,100,0,100))


	local touchLayer = CColorView:create(cc.c4b(0, 0, 0, 0))
	touchLayer:setTouchEnabled(true)
	touchLayer:setContentSize(listSize)
	touchLayer:setAnchorPoint(cc.p(0, 0))
	touchLayer:setPosition(cc.p(2, 2))
	view:addChild(touchLayer,2)

	return {
		view             = view,
		bg               = bg,
		scaleDialogueImg = scaleDialogueImg,
		bgSize           = bgSize,
		chatListView 	= chatListView,
		touchLayer 		= touchLayer,
	}
end
function ChatSystemView:ctor( ... )
	xTry(function ()	
 		self.viewData = CreateView()
 	end, __G__TRACKBACK__)

	display.commonUIParams(self.viewData.view, {po = cc.p(0,display.size.height * 0.35)})
	self:addChild(self.viewData.view, 1)

end


function ChatSystemView:onCleanup()

end
return ChatSystemView
