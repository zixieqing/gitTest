--[[
好友列表view
--]]
local FriendListView = class('FriendListView', function ()
	local node = CLayout:create(cc.size(1068, 574))
	node:setAnchorPoint(cc.p(0, 0))
	node.name = 'home.FriendListView'
	node:enableNodeEvents()
	return node
end)

local ListType = {
	RECENT_CONTACTS = 1, -- 最近联系人
	MY_FRIENDS      = 2, -- 我的好友
	ADD_FRIENDS     = 3  -- 添加好友
}
FriendListView.isSearchOnlyUID = isChinaSdk()
local function CreateView( )
	local size = cc.size(1068, 574)
	local view = CLayout:create(size)
	view:setAnchorPoint(0, 0)
	local line = display.newImageView(_res('ui/home/friend/friend_img_fengexian.png'), 464, size.height/2)
	view:addChild(line, 10)
	-- 好友列表
	local listLayout = CLayout:create(cc.size(464, size.height))
	listLayout:setPosition(cc.p(232, size.height/2))
	view:addChild(listLayout, 10)
	local tabDatas = {
		{name = __('最近联系'), tag = ListType.RECENT_CONTACTS},
		{name = __('我的好友'), tag = ListType.MY_FRIENDS},
		{name = __('添加好友'), tag = ListType.ADD_FRIENDS}
	}
	local tabButtons = {}
	for i,v in ipairs(tabDatas) do
		local tabBtn = display.newButton(87+144*(i-1), 540, {n =  _res('ui/common/common_btn_tab_default.png'), s = _res('ui/common/common_btn_tab_select.png'), d = _res('ui/common/common_btn_tab_select.png')})
		listLayout:addChild(tabBtn, 3)
		tabBtn:setTag(v.tag)
		local title = display.newLabel(70, 27, {text = v.name, fontSize = 20, color = '#ffffff' , w = 130 , hAlign = display.TAC})
		title:setName('title')
		tabBtn:addChild(title)
		local remindIcon = display.newImageView(_res('ui/common/common_hint_circle_red_ico.png'), 130, 40)
		remindIcon:setName('remindIcon')
		tabBtn:addChild(remindIcon, 10)
		remindIcon:setVisible(false)
		table.insert(tabButtons, tabBtn)
	end
	local listBg = display.newImageView(_res('ui/home/friend/friends_bg_brown.png'), 232, 268, {scale9 = true, size = cc.size(440, 502)})
	listLayout:addChild(listBg, 5)

	-- 聊天页面
	local chatLayout = CLayout:create(cc.size(604, size.height))
	chatLayout:setPosition(cc.p(766, size.height/2))
	view:addChild(chatLayout, 10)
	local titleLabel = display.newLabel(30, 542, {text = '陌生人', fontSize = 22, color = '#5b3c25', ap = cc.p(0, 0.5)})
	chatLayout:addChild(titleLabel, 10)
	local addBtn = display.newButton(120, 546, {n = _res('ui/home/friend/friends_ico_add.png')})
	chatLayout:addChild(addBtn, 10)
	local generalizeBtn = display.newButton(530, 546, {n = _res('ui/tower/library/btn_selection_unused.png')})
	chatLayout:addChild(generalizeBtn, 10)
	display.commonLabelParams(generalizeBtn, fontWithColor(18, {text = __('推广员')}))
	local chatBg = display.newImageView(_res('ui/home/friend/friends_bg_brown.png'), 302, 302, {scale9 = true, size = cc.size(580, 434)})
	chatLayout:addChild(chatBg, 3)
	-- 聊天列表
	local listSize = cc.size(580, 434)
 	local chatListView = CListView:create(listSize)
 	chatListView:setDirection(eScrollViewDirectionVertical)
 	chatListView:setBounceable(true)
 	chatListView:setAnchorPoint(cc.p(0.5, 0.5))
 	chatListView:setPosition(cc.p(303, 302))
	chatLayout:addChild(chatListView, 15)

	-- 全空状态
	local rightbgSize = listSize
	local rightEmptyView = display.newLayer(766, size.height/2,{size = rightbgSize, ap = cc.p(0.5,0.5)})
	view:addChild(rightEmptyView,20)
	local emptyGodScale = 0.75
	local msgEmptyImg = display.newNSprite(_res('arts/cartoon/card_q_3.png'),rightbgSize.width * 0.5, rightbgSize.height * 0.6)
	msgEmptyImg:setScale(emptyGodScale)
	rightEmptyView:addChild(msgEmptyImg)

	local msgEmptyLabel = display.newLabel(
		 msgEmptyImg:getPositionX(),
		 msgEmptyImg:getPositionY() - msgEmptyImg:getContentSize().height * 0.5 * emptyGodScale - 40,
		 fontWithColor('14', {text = __('没有聊天内容')}))
	rightEmptyView:addChild(msgEmptyLabel)

 	-- 输入栏
	local voiceBtn = display.newButton(42, 46, {n = _res('ui/home/friend/friends_btn_white.png')})
	voiceBtn:setVisible(false)
 	chatLayout:addChild(voiceBtn)
 	local voiceImg = display.newImageView(_res('ui/home/friend/friend_ico_yuyin.png'), voiceBtn:getContentSize().width/2, voiceBtn:getContentSize().height/2)
 	voiceBtn:addChild(voiceImg)
    if isElexSdk() then
        voiceBtn:setVisible(false)
    end
 	local expressionBtn = display.newButton(432, 46, {n = _res('ui/home/friend/friends_btn_white.png')})
 	chatLayout:addChild(expressionBtn)
 	local expressionImg = display.newImageView(_res('ui/home/friend/friend_ico_biaoqing.png'), expressionBtn:getContentSize().width/2, expressionBtn:getContentSize().height/2)
 	expressionBtn:addChild(expressionImg)
 	expressionBtn:setVisible(false)

 	local sendBox = ccui.EditBox:create(cc.size(316, 54), _res('ui/home/friend/friends_bg_input.png'))
	display.commonUIParams(sendBox, {po = cc.p(236, 46)})
	chatLayout:addChild(sendBox)
	sendBox:setFontSize(26)
	sendBox:setFontColor(ccc3FromInt('#5c5c5c'))
	sendBox:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
	-- sendBox:setPlaceHolder(__(''))
	-- sendBox:setPlaceholderFontSize(24)
	-- sendBox:setPlaceholderFontColor(ccc3FromInt('#4c4c4c'))
	sendBox:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)
	sendBox:setMaxLength(100)

 	local sendBtn = display.newButton(532, 46, {n = _res('ui/common/common_btn_orange.png')})
 	chatLayout:addChild(sendBtn)
 	display.commonLabelParams(sendBtn, fontWithColor(14,{text = __('发送')}))
 	chatLayout:setVisible(false)

 	-- 添加好友页面
 	local emptyBtn = display.newButton(10, 24, {n = _res('ui/home/friend/friends_btn_empty.png.png')})
 	view:addChild(emptyBtn, 15)
 	display.commonLabelParams(emptyBtn, {text = __('清空请求'), fontSize = 22, color = '#ffffff', reqW = 170, font = TTF_GAME_FONT, ttf = true, outline = '#5b3c25', outlineSize = 1, offset = cc.p(0, - 30)})
 	local addFriendsLayout = CLayout:create(cc.size(604, size.height))
	addFriendsLayout:setPosition(cc.p(766, size.height/2))
	view:addChild(addFriendsLayout, 10)
	local title = display.newButton(addFriendsLayout:getContentSize().width/2, 544, {n = _res('ui/common/common_title_5.png'), enable = false , scale9 = true })
	addFriendsLayout:addChild(title, 10)
	display.commonLabelParams(title, fontWithColor(5, {text = __('查找好友'),paddingW = 30  }))
	local searchBox = ccui.EditBox:create(cc.size(412, 54), _res('empty'))
	display.commonUIParams(searchBox, {po = cc.p(15, 490)})
	searchBox:setAnchorPoint(cc.p(0, 0.5))
	addFriendsLayout:addChild(searchBox, 10)
	searchBox:setFontSize(22)
	searchBox:setFontColor(ccc3FromInt('#4c4c4c'))
	searchBox:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
	searchBox:setPlaceHolder(__('请输入好友昵称或UID'))
	searchBox:setPlaceholderFontSize(18)
	searchBox:setPlaceholderFontColor(ccc3FromInt('#9c9c9c'))
	searchBox:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)
	searchBox:setMaxLength(40)
	local searchBg = display.newImageView(_res('ui/home/friend/friends_bg_input.png'), 15, 490, {scale9 = true, size = cc.size(446, 54), ap = cc.p(0, 0.5)})
	addFriendsLayout:addChild(searchBg, 3)

	local searchBtn = display.newButton(532, 490, {n = _res('ui/common/common_btn_orange.png')})
	addFriendsLayout:addChild(searchBtn, 10)
	display.commonLabelParams(searchBtn, fontWithColor(14, {text = __('搜索')}))

	local deleteBtn = display.newButton(438, 490, {n = _res('ui/home/friend/friends_btn_delete.png')})
	addFriendsLayout:addChild(deleteBtn, 10)
	local commendTitle = display.newButton(addFriendsLayout:getContentSize().width/2, 414, {n = _res('ui/common/common_title_5.png'), enable = false , scale9 =true })
	addFriendsLayout:addChild(commendTitle, 10)
	display.commonLabelParams(commendTitle, fontWithColor(5, {text = __('推荐好友') , paddingW = 20}))
	local changeBtn = display.newButton(536, 412, {n = _res('ui/home/friend/friends_btn_white_long.png')})
	addFriendsLayout:addChild(changeBtn, 10)
	display.commonLabelParams(changeBtn, fontWithColor(16, {text = __('换一批') , reqW = 105}))
	local commendBg = display.newImageView(_res('ui/home/friend/friends_bg_brown.png'), addFriendsLayout:getContentSize().width/2, 18, {scale9 = true, size = cc.size(580, 366), ap = cc.p(0.5, 0)})
	addFriendsLayout:addChild(commendBg, 3)
	local commendGridView = CGridView:create(cc.size(576, 364))
	commendGridView:setSizeOfCell(cc.size(288, 106))
	commendGridView:setDirection(eScrollViewDirectionVertical)
	commendGridView:setAnchorPoint(cc.p(0.5, 0))
	commendGridView:setPosition(cc.p(addFriendsLayout:getContentSize().width/2, 20))
	commendGridView:setColumns(2)
	addFriendsLayout:addChild(commendGridView, 10)

	addFriendsLayout:setVisible(false)
	chatLayout:setVisible(false)
	emptyBtn:setVisible(false)

	--- 我的好友 批量删除相关
	local myFriendLayout = CLayout:create(cc.size(439, 62))
	view:addChild(myFriendLayout, 10)
	myFriendLayout:setPosition(cc.p(232, 62))
	local tipBg = display.newImageView(_res('ui/home/friend/guild_hunt_bg_moster_info.png'), 0, 20, {ap = cc.p(0, 0.5)})
	myFriendLayout:addChild(tipBg)
	local delConfirmBtn = display.newButton(300, 20, {n = _res('ui/home/friend/friends_btn_list_delete_confirm.png')})
	myFriendLayout:addChild(delConfirmBtn)
	display.commonLabelParams(delConfirmBtn, {text = __('确认'), fontSize = 22, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#5b3c25', outlineSize = 1, offset = cc.p(0, 0)})
	local delCancelBtn = display.newButton(130, 20, {n = _res('ui/home/friend/friends_btn_list_delete_cancel.png')})
	myFriendLayout:addChild(delCancelBtn)
	display.commonLabelParams(delCancelBtn, {text = __('取消'), fontSize = 22, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#5b3c25', outlineSize = 1, offset = cc.p(0, 0)})
	local removeMultiFriendsBtn = display.newButton(10, 24, {n = _res('ui/home/friend/friends_btn_empty.png.png')})
	view:addChild(removeMultiFriendsBtn, 10)
	display.commonLabelParams(removeMultiFriendsBtn, {text = __('批量删除'), fontSize = 22, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#5b3c25', outlineSize = 1, offset = cc.p(0, - 30)})
	myFriendLayout:setVisible(false)
	removeMultiFriendsBtn:setVisible(false)

	return {
		view                  = view,
		tabButtons            = tabButtons,
		listLayout            = listLayout,
		voiceBtn              = voiceBtn,
		expressionBtn         = expressionBtn,
		sendBtn               = sendBtn,
		addBtn                = addBtn,
		sendBox               = sendBox,
		chatLayout            = chatLayout,
		addFriendsLayout      = addFriendsLayout,
		commendGridView       = commendGridView,
		searchBtn             = searchBtn,
		emptyBtn              = emptyBtn,
		deleteBtn             = deleteBtn,
		changeBtn             = changeBtn,
		searchBox             = searchBox,
		titleLabel            = titleLabel,
		chatListView          = chatListView,
		generalizeBtn         = generalizeBtn,
		myFriendLayout        = myFriendLayout,
		removeMultiFriendsBtn = removeMultiFriendsBtn,
		delConfirmBtn         = delConfirmBtn,
		delCancelBtn          = delCancelBtn,
		rightEmptyView	      = rightEmptyView,
	}
end

function FriendListView:ctor( ... )
	xTry(function ()
		self.viewData_ = CreateView()
		self.viewData_.view:setPosition(cc.p(0, 0))
		self:addChild(self.viewData_.view,1)
 	end, __G__TRACKBACK__)
end

return FriendListView
