--[[
主界面聊天UI
--]]
local HomeChatSystemView = class('HomeChatSystemView', function ()
	local node = CLayout:create(display.size)
	node.name = 'home.HomeChatSystemView'
	-- node:setBackgroundColor(cc.c4b(0,100,0,100))
	node:enableNodeEvents()
	return node
end)

local function CreateView( )
	local view = display.newLayer(0,0,{size = cc.size(450,41), ap = cc.p(1,0)})
	-- view:setBackgroundColor(cc.c4b(0,100,0,100))
	-- local bg = display.newImageView(_res('ui/home/nmain/main_bg_common_dialogue.png'), 0, 0)
		-- ,{scale9 = true, size = cc.size(357,41)})
	-- bg:setAnchorPoint(cc.p(0,0))
	-- view:addChild(bg)

	-- local bgSize = bg:getContentSize()

	-- local scaleDialogueImg = display.newImageView(_res('ui/home/chatSystem/main_ico_dialogue_arrow.png'), bgSize.width  - 12, bgSize.height - 12)
	-- scaleDialogueImg:setAnchorPoint(cc.p(0.5,0.5))
	-- view:addChild(scaleDialogueImg,3)


	--聊天list
	local listSize = cc.size(400, 38)
 	local chatListView = CListView:create(listSize)
 	chatListView:setDirection(eScrollViewDirectionVertical)
 	chatListView:setBounceable(false)
 	chatListView:setAnchorPoint(cc.p(0, 0))
 	chatListView:setPosition(cc.p(50, 0))
 	chatListView:setDragable(false)
 	view:addChild(chatListView,1)
 	-- chatListView:setBackgroundColor(cc.c4b(0,100,0,100))


	local touchLayer = CColorView:create(cc.c4b(0, 0, 0, 0))
	touchLayer:setTouchEnabled(true)
	touchLayer:setContentSize(listSize)
	touchLayer:setAnchorPoint(cc.p(0, 0))
	touchLayer:setPosition(cc.p(50, 2))
	view:addChild(touchLayer,2)

	local setBtn = display.newButton(0, 0, {n = _res('ui/home/chatSystem/main_ico_dialogue_setting.png')})
	display.commonUIParams(setBtn, {ap = cc.p(0.5,0.5),po = cc.p(20,16)})
    view:addChild(setBtn, 3)
    

    local defaultView = display.newLayer(50,0,{size = listSize, ap = cc.p(0,0)})
    view:addChild(defaultView, 600)
    -- defaultView:setBackgroundColor(cc.c4b(0,100,0,100))

	local channelLabel = display.newButton(2, listSize.height * 0.5 - 4, {n = 'ui/home/chatSystem/main_bg_common_dialogue_name.png'})
	channelLabel:setAnchorPoint(cc.p(0,0.5))
	display.commonLabelParams(channelLabel, fontWithColor(14 ,{text = __('世界')}))
	defaultView:addChild(channelLabel)
	channelLabel:getLabel():setColor(cc.c3b(185,105,59))


	local defaultLabel = display.newLabel(0, 0,
		{text = __('点击输入文字'),fontSize = 22, color = '#c9b2a9',ap = cc.p(0,0.5)})
	defaultLabel:setPosition(cc.p(60, listSize.height * 0.5 - 4))
	defaultView:addChild(defaultLabel)

	return {
		view             = view,
		-- bg               = bg,
		-- scaleDialogueImg = scaleDialogueImg,
		-- bgSize           = bgSize,
		chatListView 	= chatListView,
		touchLayer 		= touchLayer,
		defaultView     = defaultView,
	}
end
function HomeChatSystemView:ctor( ... )
	xTry(function ()	
 		self.viewData = CreateView()
 	end, __G__TRACKBACK__)

	display.commonUIParams(self.viewData.view, {po = cc.p(display.SAFE_R - 130,2)})
	self:addChild(self.viewData.view, 1)
end


function HomeChatSystemView:onCleanup()

end
return HomeChatSystemView
