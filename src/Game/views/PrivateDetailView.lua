--[[
主界面聊天UI
--]]

local GameScene = require( "Frame.GameScene" )
local PrivateDetailView = class('PrivateDetailView', GameScene)

local function CreateView( )
	local view = display.newLayer(0,0,{size = cc.size(display.size.width,display.size.height), ap = cc.p(0.5,0.5)})
	-- view:setBackgroundColor(cc.c4b(0,100,0,100))

	--屏蔽触摸穿透
	local cview = display.newLayer(0,0,{color = cc.c4b(0,0,0,0),enable = true,size = cc.size(0,0), ap = cc.p(0,0)})
	view:addChild(cview)

	--背景
	local bg = display.newImageView(_res('ui/common/common_bg_4.png'), 0, 0,
		{scale9 = true, size = cc.size(584,display.size.height)})
	bg:setAnchorPoint(cc.p(0,0))
	view:addChild(bg)

	local bgSize = bg:getContentSize()
	cview:setContentSize(bgSize)
	
	--顶部发送消息部分
	local topView = display.newLayer(2,bgSize.height - 5,{size = cc.size(0,0), ap = cc.p(0,1)})
	view:addChild(topView,2)

	local topBg = display.newImageView(_res('ui/home/chatSystem/dialogue_bg_send.png'), 2, bgSize.height - 5,
		{scale9 = true, size = cc.size(bgSize.width - 6,68)})
	topBg:setAnchorPoint(cc.p(0,1))
	topView:setContentSize(topBg:getContentSize())
	view:addChild(topBg)

	local tipsLabel = display.newLabel(0, 0, {text = __('该频道下不能发言'), fontSize = 20, color = '#4c4c4c', ap = cc.p(0.5, 0.5)})
	display.commonUIParams(tipsLabel, {po = cc.p(topBg:getContentSize().width * 0.5 ,topBg:getContentSize().height * 0.5)})
	topBg:addChild(tipsLabel,1)
	tipsLabel:setVisible(false)


  	local sendVoiceBtn = display.newButton(0, 0,
    	{n = _res('ui/home/chatSystem/dialogue_btn_voice.png')})--, animate = true, cb = handler(self, self.breakBtnCallback)
    display.commonUIParams(sendVoiceBtn, {ap = cc.p(0,0.5),po = cc.p( 20, topBg:getContentSize().height * 0.5)})
    topView:addChild(sendVoiceBtn)

 	local sendBox = ccui.EditBox:create(cc.size(330, 40), _res('ui/home/chatSystem/dialogue_bg_text.png'))
	display.commonUIParams(sendBox, {po = cc.p(90, topBg:getContentSize().height * 0.5),ap = cc.p(0,0.5)})
	topView:addChild(sendBox)
	sendBox:setFontSize(26)
	sendBox:setFontColor(ccc3FromInt('#4c4c4c'))
	sendBox:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
	sendBox:setPlaceHolder(__('请输入内容'))
	sendBox:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)
	sendBox:setMaxLength(100)


  	-- local sendImgBtn = display.newButton(0, 0,
   --  	{n = _res('ui/home/chatSystem/dialogue_btn_face.png')})--, animate = true, cb = handler(self, self.breakBtnCallback)
   --  display.commonUIParams(sendImgBtn, {ap = cc.p(0,0.5),po = cc.p(sendBox:getContentSize().width+ 90, topBg:getContentSize().height * 0.5)})
   --  topView:addChild(sendImgBtn)


  	local sendBtn = display.newButton(0, 0,
    	{n = _res('ui/home/chatSystem/dialogue_btn_side_selected.png')})--, animate = true, cb = handler(self, self.breakBtnCallback)
    display.commonUIParams(sendBtn, {ap = cc.p(1,0.5),po = cc.p(topBg:getContentSize().width - 20, topBg:getContentSize().height * 0.5)})
    display.commonLabelParams(sendBtn, fontWithColor(14,{text = __('发送')}))
    topView:addChild(sendBtn)



	--聊天list
	local listSize = cc.size(bgSize.width - 10,bgSize.height - topBg:getContentSize().height - 10)
 	local chatListView = CListView:create(listSize)
 	chatListView:setDirection(eScrollViewDirectionVertical)
 	chatListView:setBounceable(true)
 	chatListView:setAnchorPoint(cc.p(0, 0))
 	chatListView:setPosition(cc.p(4, 6))
 	view:addChild(chatListView,3)
 	-- chatListView:setBackgroundColor(cc.c4b(0,100,0,100))

	return {
		view             = view,
		bg               = bg,
		bgSize           = bgSize,

		topView			= topView,
		tipsLabel 		= tipsLabel,
		sendVoiceBtn	= sendVoiceBtn,
		sendBox			= sendBox,
		sendBtn 		= sendBtn,

		chatListView 	= chatListView,
	}
end
function PrivateDetailView:ctor( ... )
	local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 0))
	eaterLayer:setTouchEnabled(true)
	eaterLayer:setContentSize(display.size)
	eaterLayer:setAnchorPoint(cc.p(0.5, 1.0))
	eaterLayer:setPosition(cc.p(display.cx, display.height))
	self:addChild(eaterLayer, -1)
	eaterLayer:setOnClickScriptHandler(function (sender)
		PlayAudioByClickClose()
		AppFacade.GetInstance():UnRegsitMediator("ChatSystemDetailMediator")
	end)


	xTry(function ()	

		-- window
		self.window = CWidgetWindow:create()
		self.window:setAnchorPoint(display.LEFT_BOTTOM)
		self.window:setContentSize(display.size)
		self.window:setMultiTouchEnabled(false)
		self:addChild(self.window, 100)

		-- create view
		self.viewData = CreateView()
		self.viewData.view:setPosition(cc.p(display.size.width * 0.5,display.size.height * 0.5))
		self.window:addChild(self.viewData.view,1)



		local cview = display.newLayer(0,0,{color = cc.c4b(0,0,0,0),enable = true,size = cc.size(0,0), ap = cc.p(0,0)})
		self:addChild(cview)
		cview:setContentSize(self.viewData.bgSize)

 	end, __G__TRACKBACK__)


	-- self.viewData.bg:setTouchEnabled(true)
 --    self.viewData.bg:setOnClickScriptHandler(function( sender )
 --    	print('呵呵')
 --    end)
end



function PrivateDetailView:onCleanup()

end
return PrivateDetailView
