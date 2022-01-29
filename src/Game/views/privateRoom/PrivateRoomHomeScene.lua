--[[
包厢功能 主页面 scene  
--]]
local GameScene = require('Frame.GameScene')
local PrivateRoomHomeScene = class('PrivateRoomHomeScene', GameScene)
local PRIVATEROOM_CUTLERY_TIMER = 'PRIVATEROOM_CUTLERY_TIMER'
------------ import ------------
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
------------ import ------------
local RES_DICT = {
	COMMON_TITLE         = _res('ui/common/common_title_new.png'),
	COMMON_TIPS          = _res('ui/common/common_btn_tips.png'),
	VIP_BTN              = _res('ui/privateRoom/vip_main_btn_customer.png'),
	REMIND_ICON          = _res('ui/common/common_hint_circle_red_ico.png'),
	WAITER_BOARD         = _res('ui/privateRoom/vip_main_bg_waiter.png'),
	WAITER_BOARD_TITLE   = _res('ui/privateRoom/vip_main_label_waiter.png'),
	WAITER_BOARD_ADD     = _res('ui/common/maps_fight_btn_pet_add.png'),
	WAITER_BOARD_HEAD_BG = _res('ui/tower/library/tower_bg_card_slot.png'),
	BOTTOM_BG  	 	 	 = _res('ui/privateRoom/vip_main_bg_below.png'),
	DECORATION_ICON  	 = _res('ui/privateRoom/vip_main_ico_deco.png'),
	SOUVENIR_ICON  	     = _res('ui/privateRoom/vip_main_ico_gift.png'),
	BOTTOM_BTN_BG        = _res('ui/privateRoom/vip_main_bg_function_plate.png'),
	BOTTOM_BTN_TITLE_BG  = _res('ui/privateRoom/vip_main_bg_function.png'),
	SERVICE_BTN_BG       = _res('ui/privateRoom/vip_main_bg_serve.png'),
	SERVICE_BTN 	     = _res('ui/privateRoom/vip_main_btn_serve.png'),
	SERVICE_BTN_DISABLE  = _res('ui/privateRoom/vip_main_btn_serve_disable.png'),
	SERVICE_LABEL_BG     = _res('ui/privateRoom/vip_main_btn_times_add.png'),
	REFRESH_TIME_BG      = _res('ui/privateRoom/vip_main_label_info.png'), 
	DIALOGUE_BG_LEFT 	 = _res('ui/privateRoom/dialogue_bg_2_left.png'),
	DIALOGUE_BG_RIGHT    = _res('ui/privateRoom/dialogue_bg_2_right.png'),
	BTN_FRIEND           = _res('avatar/ui/restaurant_btn_my_friends'),
	MAIN_LABEL_TIPS      = _res('ui/privateRoom/vip_main_label_tips.png'),
	SKIP_BTN 	 	 	 = _res('arts/stage/ui/opera_btn_skip.png'),

	SPINE_BOOK           = _spn('ui/privateRoom/effect/vip_shu'),
}
-- 通用对话类型
local COMMON_DIALOGUE_TYPE = {
	ENTER = 'enterDialogueId', -- 进入对话
	WAIT  = 'waitDialogueId',  -- 等待对话
	LEAVE = 'leaveDialogueId', -- 离开对话
}
function PrivateRoomHomeScene:ctor( ... )
    self.super.ctor(self, 'views.priviateRoom.PrivateRoomHomeScene')
	local args = unpack({...})
	self.breakDialogue = false -- 是否打断对话
	self.rewardsData = {} 	   -- 奖励数据
	self.selectedCutlery = nil 
	self:InitUI()
end
--[[
初始化ui
--]]
function PrivateRoomHomeScene:InitUI()
	local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 0))
	eaterLayer:setTouchEnabled(true)
	eaterLayer:setContentSize(display.size)
	eaterLayer:setAnchorPoint(cc.p(0.5, 0.5))
	eaterLayer:setPosition(cc.p(display.cx, display.cy))
	self:addChild(eaterLayer)
	self.eaterLayer = eaterLayer
	self.avatarLayoutNodes = {}

	local CreateView = function ()
		local size = display.size
		local view = CLayout:create(size)
		view:setPosition(size.width / 2, size.height / 2)
		-- 标题版
		local tabNameLabel = display.newButton(display.SAFE_L + 130, display.height, {n = RES_DICT.COMMON_TITLE,enable = true,ap = cc.p(0, 1)})
		display.commonLabelParams(tabNameLabel, {ttf = true, font = TTF_GAME_FONT, text = __('包厢'), fontSize = 30, color = '473227',offset = cc.p(0,-8)})
		self:addChild(tabNameLabel, 20)
		-- 提示按钮
		local tabtitleTips = display.newImageView(RES_DICT.COMMON_TIPS, 242, 28)
		tabNameLabel:addChild(tabtitleTips, 1)
		-- themeNode
		local themeNode = require('Game.views.privateRoom.PrivateRoomThemeNode').new()
		themeNode:setPosition(size.width / 2, size.height / 2)
		view:addChild(themeNode, 1)
		-- 贵宾信息
		local VIPLayer = display.newLayer()
		view:addChild(VIPLayer, 15)
		local VIPBtn = display.newButton(size.width - 80 - display.SAFE_L, size.height - 130, {n = RES_DICT.VIP_BTN})
		VIPLayer:addChild(VIPBtn)
		display.commonLabelParams(VIPBtn, {text = __('贵宾信息'), fontSize = 24, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#46260d', outlineSize = 2, offset = cc.p(0, -44)})
		-- local VIPRemindIcon = display.newImageView(RES_DICT.REMIND_ICON, 0, VIPBtn:getContentSize().width - 10)
		-- VIPBtn:addChild(VIPRemindIcon, 10)
		-- 底部Layout -- 
		local bottomLayoutSize = cc.size(size.width, 200)
		local bottomLayout = CLayout:create(bottomLayoutSize)
		display.commonUIParams(bottomLayout, {po = cc.p(size.width/2, 0), ap = cc.p(0.5, 0)})
		view:addChild(bottomLayout, 10)
		-- 背景
		local bottomLayoutBg = display.newImageView(RES_DICT.BOTTOM_BG, bottomLayoutSize.width / 2, 0, {ap = cc.p(0.5, 0)})
		bottomLayout:addChild(bottomLayoutBg, 1)
		-- 服务员面板
		local waiterBoardBtn = display.newButton(0, 0, {n = RES_DICT.WAITER_BOARD, useS = false})
		display.commonUIParams(waiterBoardBtn, {ap = cc.p(0, 0), po = cc.p(display.SAFE_L, 0)})
		bottomLayout:addChild(waiterBoardBtn, 5)
		local waiterBoardTitle = display.newButton(waiterBoardBtn:getContentSize().width/2, waiterBoardBtn:getContentSize().height, {n = RES_DICT.WAITER_BOARD_TITLE, enable = false})
		display.commonLabelParams(waiterBoardTitle, {text = __('今日服务员'), reqW = 170,  fontSize = 20, color = '#ffffff'})
		waiterBoardBtn:addChild(waiterBoardTitle, 5)
		local waiterBoardHeadBg = display.newImageView(RES_DICT.WAITER_BOARD_HEAD_BG, 100, 72)
		waiterBoardHeadBg:setScale(0.5)
		waiterBoardBtn:addChild(waiterBoardHeadBg, 1)
		local waiterBoardAddImg = display.newImageView(RES_DICT.WAITER_BOARD_ADD, 100, 72)
		waiterBoardBtn:addChild(waiterBoardAddImg, 3)
		local cardHeadNode = require('common.CardHeadNode').new({specialType = 1})
		cardHeadNode:setPosition(cc.p(100, 72))
		waiterBoardBtn:addChild(cardHeadNode, 5)
		cardHeadNode:setScale(0.6)
		cardHeadNode:setVisible(false)

		local function CreateButtonLayout( iconPath, title )
			local btnSize = cc.size(140, 135)
			local btnLayout = CLayout:create(btnSize)
			local btnBg = display.newImageView(RES_DICT.BOTTOM_BTN_BG, btnSize.width / 2, 75)
			btnLayout:addChild(btnBg, 1)
			local btn = display.newButton(btnSize.width / 2, 75, {n = iconPath})
			btnLayout:addChild(btn, 5)
			local titleBg = display.newImageView(RES_DICT.BOTTOM_BTN_TITLE_BG, btnSize.width / 2, 30)
			btnLayout:addChild(titleBg, 3)
			local titleLabel = display.newLabel(btnSize.width / 2, 25, {text = title or '', fontSize = 24, color = '#ffffff', ttf = true, font = TTF_GAME_FONT, outline = '#46260d', outlineSize = 2})
			btnLayout:addChild(titleLabel, 5)
			return {
				btnLayout  = btnLayout,
				btn 	   = btn,
				titleLabel = titleLabel,
			}
		end
		-- 装修
		local decorationBtnData = CreateButtonLayout(RES_DICT.DECORATION_ICON, __('装修'))
		display.commonUIParams(decorationBtnData.btnLayout, {ap = cc.p(0.5, 0), po = cc.p(344 + display.SAFE_L, 0)})
		bottomLayout:addChild(decorationBtnData.btnLayout, 5)
		-- 纪念品
		local souvenirBtnData = CreateButtonLayout(RES_DICT.SOUVENIR_ICON, __('纪念品'))
		display.commonUIParams(souvenirBtnData.btnLayout, {ap = cc.p(0.5, 0), po = cc.p(490 + display.SAFE_L, 0)})
		bottomLayout:addChild(souvenirBtnData.btnLayout, 5) 
		-- 招待
		local serviceBtnBg = display.newImageView(RES_DICT.SERVICE_BTN_BG, bottomLayoutSize.width - 140 - display.SAFE_L, 120)
		bottomLayout:addChild(serviceBtnBg, 3)
		local serviceBtn = display.newButton(bottomLayoutSize.width - 140 - display.SAFE_L, 120, {n = RES_DICT.SERVICE_BTN})
		bottomLayout:addChild(serviceBtn, 5)
		local serviceLabelBg = display.newButton(bottomLayoutSize.width - 140 - display.SAFE_L, 35, {n = RES_DICT.SERVICE_LABEL_BG})
		view:addChild(serviceLabelBg, 12)
		local serviceRichLabel = display.newRichLabel(bottomLayoutSize.width - 65 - display.SAFE_L, 35, {ap = cc.p(1, 0.5)})
		view:addChild(serviceRichLabel, 12)
		-- 刷新时间
		local timeBg = display.newImageView(RES_DICT.REFRESH_TIME_BG, bottomLayoutSize.width - 360 - display.SAFE_L, 35)
		view:addChild(timeBg, 10)
		local timeRichLabel = display.newRichLabel(bottomLayoutSize.width - 510 - display.SAFE_L, 35)
		view:addChild(timeRichLabel, 10)
		-- 底部Layout -- 
        -- 好友
        local friendBtn = display.newButton(display.SAFE_R + 4, (display.size.height - TOP_HEIGHT) / 2, {n = RES_DICT.BTN_FRIEND, ap = display.RIGHT_CENTER})
        self:addChild(friendBtn, GameScene.TAGS.TagGameLayer)
		return {
			view 	          = view,
			tabNameLabel      = tabNameLabel,
			tabtitleTips      = tabtitleTips,
			decorationBtnData = decorationBtnData,
			souvenirBtnData   = souvenirBtnData,
			waiterBoardBtn    = waiterBoardBtn,
			serviceBtn        = serviceBtn,
			serviceLabelBg    = serviceLabelBg,
			bgLayout 	 	  = themeNode.viewData.bgLayout,
			avatarLayout      = themeNode.viewData.avatarLayout,
			VIPLayer          = VIPLayer,
			VIPBtn  	 	  = VIPBtn, 
			wallView 	 	  = themeNode.viewData.wallView,
			wallBg   	 	  = themeNode.viewData.wallBg,
			cardHeadNode	  = cardHeadNode,
			bottomLayout	  = bottomLayout,
			themeNode 	      = themeNode,
			timeRichLabel     = timeRichLabel,
			serviceRichLabel  = serviceRichLabel,
			friendBtn 	 	  = friendBtn,
		}
	end

	xTry(function ()
		self.viewData = CreateView()
		self:addChild(self.viewData.view)
		-- 弹出标题板
		local tabNameLabelPos = cc.p(self.viewData.tabNameLabel:getPosition())
		self.viewData.tabNameLabel:setPositionY(display.height + 100)
		local action = cc.EaseBounceOut:create(cc.MoveTo:create(1, tabNameLabelPos))
		self.viewData.tabNameLabel:runAction( action )

		self:CreatePlotUnlockLayer()
		
	end, __G__TRACKBACK__)
end
--[[
刷新陈列墙
@params wallData map 纪念品数据
--]]
function PrivateRoomHomeScene:RefreshWall( wallData )
	self.viewData.themeNode:RefreshWall(wallData)
	self.viewData.themeNode.viewData.wallView:SetSouvenirsEnabled(false)
end
--[[ 
刷新主题信息
@params themeId int 主题id
--]]
function PrivateRoomHomeScene:RefreshTheme( themeId )
	self.avatarLayoutNodes = {}
	local avatarNodes = self.viewData.themeNode:SetTheme(themeId)
	self.avatarLayoutNodes.avatar = avatarNodes.avatars
	self.avatarLayoutNodes.menuBtn = avatarNodes.menuBtn
	self.avatarLayoutNodes.putThings = avatarNodes.putThings
	self.avatarLayoutNodes.menuBtn:setOnClickScriptHandler(function() 
		PlayAudioByClickNormal()
		local privateRoomData = app.privateRoomMgr:GetPrivateRoomData()
		app.router:loadMdt('Game.mediator.privateRoom.PrivateRoomMenuMediator', privateRoomData)
	end)
end
--[[
更新剩余刷新时间
@params seconds int 剩余秒数
--]]
function PrivateRoomHomeScene:UpdateTimeLabel( seconds )
	local str = string.split(string.fmt(__('距离下次刷新还有 |_time_'), {['_time_'] = string.formattedTime(seconds, '%02i:%02i:%02i')}), '|')
	display.reloadRichLabel(self.viewData.timeRichLabel, { c = {
		{text = str[1], fontSize = 22, color = '#d6cbc2'},
		{text = str[2], fontSize = 22, color = '#ffffff'}
	}})
	CommonUtils.SetNodeScale(self.viewData.timeRichLabel , { width = 400 })
end
--[[
更新剩余服务次数
@params leftTimes int 剩余服务次数
@params maxTimes int 最大服务次数
--]]
function PrivateRoomHomeScene:UpdateServeTimesLabel( leftTimes, maxTimes )
	local color = '#ffffff'
	if checkint(leftTimes) == 0 then
		color = '#f46565'
		self.viewData.serviceBtn:setNormalImage(RES_DICT.SERVICE_BTN_DISABLE)
		self.viewData.serviceBtn:setSelectedImage(RES_DICT.SERVICE_BTN_DISABLE)
	else
		color = '#ffffff'
		self.viewData.serviceBtn:setNormalImage(RES_DICT.SERVICE_BTN)
		self.viewData.serviceBtn:setSelectedImage(RES_DICT.SERVICE_BTN)
	end
	-- 次数满的时候不显示倒计时
	self.viewData.timeRichLabel:setVisible(not (checkint(leftTimes) >= checkint(maxTimes)))
	display.reloadRichLabel(self.viewData.serviceRichLabel, { c = {
		{text = __('本轮可招待：'), fontSize = 22, color = '#fed4b1'},
		{text = tostring(leftTimes), fontSize = 22, color = color},
		{text = '/' .. tostring(maxTimes), fontSize = 22, color = '#ffffff'}
	}})
	CommonUtils.SetNodeScale(self.viewData.serviceRichLabel , {width = 220 })
end
--[[
刷新服务员状态
@params PlayerCardId int 卡牌自增id
--]]
function PrivateRoomHomeScene:RefreshWaiter( playerCardId )
	if self.avatarLayoutNodes.waiter then
		self.avatarLayoutNodes.waiter:removeFromParent()
	end
	local cardData = app.gameMgr:GetCardDataById(playerCardId)
	local servePos = app.privateRoomMgr:GetWaiterServePos(self.avatarLayoutNodes.avatar[1], self.viewData.avatarLayout)
	local callback = function ()
		uiMgr:AddDialog('common.CardKitchenNode', {id = playerCardId, from = 2, moduleId = CARD_BUSINESS_SKILL_MODEL_PRIVATEROOM})
	end
	local cardSkinId = app.gameMgr:GetCardDataById(playerCardId).defaultSkinId
	local qAvatar = require('Game.views.privateRoom.PrivateRoomWaiterNode').new({cardSkinId = cardSkinId,  servePos = servePos, callback = callback})
	self.viewData.avatarLayout:addChild(qAvatar, 15)
	self.avatarLayoutNodes.waiter = qAvatar
	self:RefreshWaiterHead(playerCardId)
end
--[[
设置服务员点击状态
@params enabled bool 是否可点击
--]]
function PrivateRoomHomeScene:SetWaiterEnabled( enabled ) 
	self.avatarLayoutNodes.waiter:SetEnabled(enabled)
end
--[[
刷新服务员头像
--]]
function PrivateRoomHomeScene:RefreshWaiterHead( playerCardId )
	self.viewData.cardHeadNode:RefreshUI({id = playerCardId, showActionState = false})
	self.viewData.cardHeadNode:setVisible(true)
end
--[[
变为服务状态
--]]
function PrivateRoomHomeScene:ChangeToServeState()
	local guestId = app.privateRoomMgr:GetGuestId()
	if guestId then
		self:CreateGuest()
		for i, v in ipairs(checktable(self.avatarLayoutNodes.guest)) do
			v:SetSitPos()
		end
		self.avatarLayoutNodes.waiter:SetServePos()
		self:SetMenuBtnVisible(true)
		self:SetWallBgEnabled(false)
		self:SetWaiterEnabled(false)
		self.viewData.bottomLayout:setVisible(false)
		self.viewData.bottomLayout:setPosition(display.cx, - 200)
	end
end
--[[
创建客人
--]]
function PrivateRoomHomeScene:CreateGuest( )
	if self.avatarLayoutNodes.guest and next(self.avatarLayoutNodes.guest) ~= nil then
		for i, v in ipairs(self.avatarLayoutNodes.guest) do
			v:removeFromParent()
		end
	end
	self.avatarLayoutNodes.guest = {}
	local waiterServePos = app.privateRoomMgr:GetWaiterServePos(self.avatarLayoutNodes.avatar[1], self.viewData.avatarLayout)
	local guestId = app.privateRoomMgr:GetGuestId()
	local sitPos = app.privateRoomMgr:GetThemeAdditionsPos(self.avatarLayoutNodes.avatar[1], self.viewData.avatarLayout)[1]
	local guest = require('Game.views.privateRoom.PrivateRoomGuestNode').new({guestId = guestId,  sitPos = sitPos, isMainGuest = true, defaultPosY = waiterServePos.y})
	self.viewData.avatarLayout:addChild(guest, 10)
	table.insert(self.avatarLayoutNodes.guest, guest)
	
	local secondGuest = app.privateRoomMgr:GetSecondGuest()
	if secondGuest then
		local secSitPos = app.privateRoomMgr:GetThemeAdditionsPos(self.avatarLayoutNodes.avatar[1], self.viewData.avatarLayout)[2]
		local secGuest = require('Game.views.privateRoom.PrivateRoomGuestNode').new({guestId = secondGuest,  sitPos = secSitPos, isMainGuest = false, defaultPosY = waiterServePos.y})
		self.viewData.avatarLayout:addChild(secGuest, 10)
		table.insert(self.avatarLayoutNodes.guest, secGuest)
	end
end
--[[
客人到达动画
--]]
function PrivateRoomHomeScene:GuestArrivedAction()
	PlayAudioClip(AUDIOS.UI.ui_dining_ring.id)
	local waiter = self.avatarLayoutNodes.waiter
	local bottomLayout = self.viewData.bottomLayout
	-- 添加屏蔽层
	uiMgr:GetCurrentScene():AddViewForNoTouch()
	-- 隐藏 ui界面
	bottomLayout:runAction(
		cc.Sequence:create(
			cc.MoveTo:create(0.5, cc.p(display.cx, - 200)),
			cc.Hide:create()
		)
	)
	-- 服务员
	self:SetWaiterEnabled(false)
	waiter:MoveToServePos()

	-- 客人
	self:CreateGuest()
	for i, v in ipairs(self.avatarLayoutNodes.guest) do
		v:MoveToSitPos()
	end
	-- 对话
	self:CreateCommonDialogue(COMMON_DIALOGUE_TYPE.ENTER)
end
--[[
客人到达动画结束
--]]
function PrivateRoomHomeScene:ArrivalActionEnd()
	-- 移除屏蔽层
	uiMgr:GetCurrentScene():RemoveViewForNoTouch()
	self:SetMenuBtnVisible(true)
	self.avatarLayoutNodes.menuBtn:getChildByName('spine'):setAnimation(0, 'play', false)
	self.avatarLayoutNodes.menuBtn:getChildByName('spine'):addAnimation(0, 'idle', true)
	self:SetWallBgEnabled(false)
end
--[[
菜单是否显示
--]]
function PrivateRoomHomeScene:SetMenuBtnVisible( isVisible )
	if self.avatarLayoutNodes.menuBtn then
		self.avatarLayoutNodes.menuBtn:setVisible(isVisible)
	end
end
--[[
是否屏蔽陈列墙
--]]
function PrivateRoomHomeScene:SetWallBgEnabled( isEnabled )
	self.viewData.wallBg:setEnabled(isEnabled)
end
--[[
开始服务
--]]
function PrivateRoomHomeScene:StartServing( rewardsData )
	-- 添加屏蔽层
	uiMgr:GetCurrentScene():AddViewForNoTouch()
	self:SetMenuBtnVisible(false)
	-- 如果当前处于对话则直接移除
	self:SkipDialogue()
	self.rewardsData = rewardsData or {}
	self.foodsData = app.privateRoomMgr:GetFoods()
	self.avatarLayoutNodes.dishes = {}
	self:ServingEvent()
end
--[[
上菜动作
--]]
function PrivateRoomHomeScene:ServingEvent()
	self.avatarLayoutNodes.waiter:ServeTheDishAction()
end
--[[
上菜动作结束
--]]
function PrivateRoomHomeScene:ServingEventEnd()
	for i = 1, #self.foodsData do
		self:AddDishOnTable(i, self.foodsData[i].goodsId)
		self.avatarLayoutNodes.putThings[i]:setVisible(false)
	end
	-- 所有菜品上菜完成
	self:AllTheDishesServed()
end
--[[
所有菜品已上齐
--]]
function PrivateRoomHomeScene:AllTheDishesServed()
	self.avatarLayoutNodes.waiter:MoveToDefaultPos()
	local stroyId = app.privateRoomMgr:GetGuestDialogueId()
	transition.execute(self, nil, {delay = 3, complete = function()
		for i, v in ipairs(self.avatarLayoutNodes.guest) do
			v:SetSpineAnimation('eat')
		end
		self:AddCutlery()
		self:AddStorySkipView()
		self:CreateDialogue(stroyId, handler(self, self.StoryFinished))
		uiMgr:GetCurrentScene():RemoveViewForNoTouch()
	end})
end
--[[
添加刀叉动画
--]]
function PrivateRoomHomeScene:AddCutlery()
	local putThings = app.privateRoomMgr:GetDishPutPos(app.privateRoomMgr:GetThemeId())
	self.avatarLayoutNodes.cutlery = {}
	for i = 1, #self.foodsData do
		local pos = putThings[i]
		local cutlery = sp.SkeletonAnimation:create(
			'avatar/animate/canpan.json',
			'avatar/animate/canpan.atlas',
			1)
		cutlery:setToSetupPose()
		cutlery:setAnimation(0, 'idle', true)
		cutlery:setPosition(cc.p(pos.x, pos.y))
		cutlery:setVisible(false)
		table.insert(self.avatarLayoutNodes.cutlery, cutlery)
		self.avatarLayoutNodes.avatar[1]:addChild(cutlery, 1024)
	end
	self:RunCutleryAction()
end
--[[
开启刀叉动画
--]]
function PrivateRoomHomeScene:RunCutleryAction()
	local temp = {}
	for i = 1, #self.foodsData do
		if i ~= self.selectedCutlery then
			table.insert(temp, i)
		end
	end
	if next(temp) == nil then
		table.insert(temp, 1)
	end
	local randomNum = temp[math.random(#temp)]
	self.selectedCutlery = randomNum
	local cutlery = self.avatarLayoutNodes.cutlery[randomNum]
	if cutlery then
		cutlery:runAction(
			cc.Sequence:create(
				cc.Show:create(),
				cc.DelayTime:create(2),
				cc.Hide:create(),
				cc.CallFunc:create(handler(self, self.RunCutleryAction))
			)
		)
	end
end
--[[
添加菜品
--]]
function PrivateRoomHomeScene:AddDishOnTable( index, goodsId )
	local putThings = app.privateRoomMgr:GetDishPutPos(app.privateRoomMgr:GetThemeId())
	local pos = putThings[index] or cc.p(0, 0)
	local dish = display.newImageView(CommonUtils.GetGoodsIconPathById(goodsId), pos.x, pos.y)
	dish:setScale(0.7)
	table.insert(self.avatarLayoutNodes.dishes, dish)
	self.avatarLayoutNodes.avatar[1]:addChild(dish, 1024 - pos.y) 
end
--[[
创建通用客人对话
@params guestId int 顾客id
@params dialogueType COMMON_DIALOGUE_TYPE 对话类型
--]]
function PrivateRoomHomeScene:CreateCommonDialogue( dialogueType, guestId )
	if not guestId then
		guestId = app.privateRoomMgr:GetGuestId()
	end
	local guestConf = CommonUtils.GetConfig('privateRoom', 'guest', guestId)
	if not guestConf then return end
	local dialgoues = guestConf[dialogueType]
	local dialgoueGroupId = dialgoues[math.random(1, #dialgoues)]
	if dialogueType == COMMON_DIALOGUE_TYPE.LEAVE then
		self:CreateDialogue(dialgoueGroupId, handler(self, self.GuestsLeft))
	elseif dialogueType == COMMON_DIALOGUE_TYPE.WAIT then
		self:CreateDialogue(dialgoueGroupId, handler(self, self.WaitDialogueEnd))
	else
		self:CreateDialogue(dialgoueGroupId)
	end
end
--[[
创建对话
@params dialgoueGroupId int 对话组别id
@params callback function 对话完成回调
--]]
function PrivateRoomHomeScene:CreateDialogue( dialgoueGroupId, callback )
	self.breakDialogue = false
	local dialogueConf = CommonUtils.GetConfig('privateRoom', 'guestDialogueContent', dialgoueGroupId)
	if dialogueConf then
		for i, v in ipairs(checktable(dialogueConf)) do
			if self.breakDialogue then break end
			transition.execute(self, nil, {delay = (i - 1) * 3, complete = function()
				if not self.breakDialogue then
					local cb = nil
					if i == #dialogueConf and callback then
						cb = callback
					end
					self:AddDialogue(v, cb)
				end
			end})
		end
	end
end
--[[
添加对话框
@params dialogueData table 对话信息
@params callback function 对话完成回调
--]]
function PrivateRoomHomeScene:AddDialogue( dialogueData, callback )
	if dialogueData then
		local dialogueNode = nil
		if checkint(dialogueData.speaker) == 1 then -- 主对话
			dialogueNode = display.newImageView(RES_DICT.DIALOGUE_BG_RIGHT, 800, 700)
		elseif checkint(dialogueData.speaker) == 2 then -- 服务员对话
			dialogueNode = display.newImageView(RES_DICT.DIALOGUE_BG_LEFT, 450, 700)
		elseif checkint(dialogueData.speaker) == 3 then -- 副对话
			dialogueNode = display.newImageView(RES_DICT.DIALOGUE_BG_LEFT, 800, 700)
		end 
		self.viewData.avatarLayout:addChild(dialogueNode, 20)
		self.avatarLayoutNodes.dialogue = dialogueNode
		local textLabel = display.newLabel(60, 170, fontWithColor(6, {w = 480, maxL = 5, ap = cc.p(0, 1), text = dialogueData.content}))
		dialogueNode:addChild(textLabel, 1)
		dialogueNode:setScale(0.5)
		dialogueNode:runAction(
			cc.Sequence:create(
				cc.EaseBackOut:create(
					cc.ScaleTo:create(0.45, 1)
				),
				cc.DelayTime:create(2),
				cc.EaseBackIn:create(
					cc.ScaleTo:create(0.45, 0)
				),
				cc.CallFunc:create(function()
					if callback then
						callback()
					end
					self.avatarLayoutNodes.dialogue = nil 
				end),
				cc.RemoveSelf:create()
			)
		)
	end
end
--[[
客人故事对话结束
--]]
function PrivateRoomHomeScene:StoryFinished()
	self:RemoveStorySkipView()
	local isUnlockPlot = app.privateRoomMgr:SetGuest()
	if isUnlockPlot then
		self:PlayPlotUnlockAction(handler(self, self.PopServeReward))
	else
		self:PopServeReward()
	end
 end
--[[
添加剧情跳过页面
--]]
function PrivateRoomHomeScene:AddStorySkipView()
	local skipView = CLayout:create(display.size)
	skipView:setPosition(cc.p(display.cx, display.cy))
	local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 0))
	eaterLayer:setTouchEnabled(true)
	eaterLayer:setContentSize(display.size)
	eaterLayer:setAnchorPoint(cc.p(0.5, 0.5))
	eaterLayer:setPosition(cc.p(display.cx, display.cy))
	skipView:addChild(eaterLayer, -1)
	local skipBtn = display.newButton(display.width, 105, {n = RES_DICT.SKIP_BTN, ap = cc.p(1, 0.5)})
	skipView:addChild(skipBtn, 10)
	skipBtn:setOnClickScriptHandler(function() 
		self:SkipDialogue()
		self:StoryFinished()
	end)
	local skipLabel = display.newLabel(skipBtn:getContentSize().width - 44, skipBtn:getContentSize().height / 2, {fontSize = 26, text = __("跳过"),color = "#220404"})
	skipBtn:addChild(skipLabel, 1)
	self.skipView = skipView
	app.uiMgr:GetCurrentScene():AddDialog(skipView)
end
--[[
移除剧情跳过页面	
--]]
function PrivateRoomHomeScene:RemoveStorySkipView()
	if self.skipView then
		app.uiMgr:GetCurrentScene():RemoveDialog(self.skipView)
		self.skipView = nil
	end
end
--[[
创建剧情解锁Layer
--]]
 function PrivateRoomHomeScene:CreatePlotUnlockLayer()
	local VIPLayer = self.viewData.VIPLayer
	local VIPLayerSize = VIPLayer:getContentSize()

	local plotTipLayerSize = cc.size(720, 200)
	local plotTipLayer = display.newLayer(VIPLayerSize.width / 2 + 100, VIPLayerSize.height / 2 + 134, {ap = display.CENTER, size = plotTipLayerSize})
	VIPLayer:addChild(plotTipLayer)

	local titleBg = display.newImageView(RES_DICT.MAIN_LABEL_TIPS, plotTipLayerSize.width / 2, plotTipLayerSize.height / 2, {scale9 = true, ap = display.CENTER})
	plotTipLayer:addChild(titleBg)

    local bookIcon = sp.SkeletonAnimation:create(
		RES_DICT.SPINE_BOOK.json,
		RES_DICT.SPINE_BOOK.atlas,
        1)
    bookIcon:update(0)
    bookIcon:setToSetupPose()
    
	bookIcon:setPosition(cc.p(110, titleBg:getPositionY()))
	plotTipLayer:addChild(bookIcon)

	local titleLabel = display.newLabel(167, titleBg:getPositionY(), fontWithColor(18, {ap = display.LEFT_CENTER, text = '测试'}))
	plotTipLayer:addChild(titleLabel)

	plotTipLayer:setVisible(false)
	VIPLayer.viewData = {
		plotTipLayer = plotTipLayer,
		titleBg      = titleBg,
		bookIcon     = bookIcon,
		titleLabel   = titleLabel,
	}
	
 end
 function PrivateRoomHomeScene:PlayPlotUnlockAction(cb)
	uiMgr:GetCurrentScene():AddViewForNoTouch()
	local VIPLayer         = self.viewData.VIPLayer
	local VIPLayerViewData = VIPLayer.viewData
	local titleBg          = VIPLayerViewData.titleBg
	local plotTipLayer     = VIPLayerViewData.plotTipLayer
	local bookIcon         = VIPLayerViewData.bookIcon
	bookIcon:setToSetupPose()
	bookIcon:setAnimation(0, 'idle', true)
	local privateRoomMgr   = app.privateRoomMgr
	local dialogueConf     = privateRoomMgr:GetGuestDialogueConfByDialogueId(privateRoomMgr:GetGuestDialogueId())
	local titleLabel       = VIPLayerViewData.titleLabel
	display.commonLabelParams(titleLabel, {text = string.fmt(__('飨灵逸闻：《__name__》已收录'), {__name__ = tostring(dialogueConf.name)})})

	plotTipLayer:setScale(0)

	plotTipLayer:setVisible(true)
	local bookIconPos = cc.p(bookIcon:getPositionX(), bookIcon:getPositionY())	
	local VIPBtn = self.viewData.VIPBtn

	local plotTipLayerPos = cc.p(plotTipLayer:getPositionX(), plotTipLayer:getPositionY())
	VIPLayer:runAction(cc.Sequence:create({
		cc.TargetedAction:create(plotTipLayer, cc.Sequence:create({
			cc.Show:create(),
			cc.ScaleTo:create(5 /30, 0.5),
			cc.ScaleTo:create(5 /30, 1.1),
			cc.ScaleTo:create(5 /30, 1),
			cc.DelayTime:create(0.8),
			cc.CallFunc:create(function ()
				bookIcon:setAnimation(0, 'play', true)
			end),
			cc.Spawn:create({
				cc.TargetedAction:create(titleBg, cc.FadeOut:create(8 / 30)),
				cc.TargetedAction:create(titleLabel, cc.FadeOut:create(8 / 30)),
			}),
			cc.CallFunc:create(function ()
				bookIcon:setAnimation(0, 'idle', true)
			end),
			cc.BezierTo:create(0.8, {
				cc.p(plotTipLayerPos.x, VIPBtn:getPositionY()),
				cc.p(VIPBtn:getPositionX(), plotTipLayerPos.y),
				cc.p(VIPBtn:getPositionX() + plotTipLayer:getContentSize().width / 2 -  bookIconPos.x, VIPBtn:getPositionY())
			}),
		})),
		cc.CallFunc:create(function ()
			display.commonUIParams(plotTipLayer, {po = plotTipLayerPos})
			plotTipLayer:setVisible(false)
			titleBg:setOpacity(255)
			titleLabel:setOpacity(255)
			bookIcon:setAnimation(0, 'idle', false)
			if cb then cb() end
		end)
	}))

 end
--[[
弹出招待奖励
--]]
function PrivateRoomHomeScene:PopServeReward()
	
	uiMgr:GetCurrentScene():RemoveViewForNoTouch()
	local closeCallback = function ()
		for i, v in ipairs(self.avatarLayoutNodes.guest) do
			v:SetSpineAnimation('idle')
		end
		uiMgr:GetCurrentScene():AddViewForNoTouch()
		self:ClearCutlery()
		self:ClearDishes()
		self:RecoverPutThings()
		local guestId = app.privateRoomMgr:GetGuestId()
		self:CreateCommonDialogue(COMMON_DIALOGUE_TYPE.LEAVE, guestId)
	end

	-- 领取奖励
	uiMgr:AddDialog('common.RewardPopup', {rewards = self.rewardsData.rewards, closeCallback = closeCallback})
	if self.rewardsData.gold and self.rewardsData.popularity then
		app.gameMgr:GetUserInfo().gold = checkint(self.rewardsData.gold)
		app.gameMgr:GetUserInfo().popularity = checkint(self.rewardsData.popularity)
		app.gameMgr:GetUserInfo().diamond = checkint(self.rewardsData.diamond)
		AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI)
	end
 end
--[[
放弃订单
--]]
function PrivateRoomHomeScene:AbandonOrder()
	-- 添加屏蔽层
	uiMgr:GetCurrentScene():AddViewForNoTouch()	
	for i, v in ipairs(checktable(self.avatarLayoutNodes.guest)) do
		v:LeavePrivateRoom()
	end
	self:SetMenuBtnVisible(false)
	self:SetWallBgEnabled(false)
	self:SetWaiterEnabled(true)
	self.avatarLayoutNodes.waiter:MoveToDefaultPos()
end
--[[
客人离开
--]]
function PrivateRoomHomeScene:GuestsLeft()
	for i, v in ipairs(checktable(self.avatarLayoutNodes.guest)) do
		v:MoveToDefaultPos()
	end
end
--[[
等待对话播放结束	
--]]
function PrivateRoomHomeScene:WaitDialogueEnd()
	AppFacade.GetInstance():DispatchObservers(PRIVATEROOM_WAIT_DIALOGUE_END)
end
--[[
服务结束，还原包厢
--]]
function PrivateRoomHomeScene:RestoredPrivateRoom()
	if self.rewardsData and next(self.rewardsData) ~= nil then
		-- 完成订单
		self:ClearGuests()
		self.rewardsData = {}
	else
		-- 放弃订单
		self:ClearGuests()
	end
	-- 显示ui界面
	local bottomLayout = self.viewData.bottomLayout
	bottomLayout:runAction(
		cc.Sequence:create(
			cc.Show:create(),
			cc.MoveTo:create(0.5, cc.p(display.cx, 0)),
			cc.CallFunc:create(function () 
				self:SetWaiterEnabled(true)
				self:SetWallBgEnabled(true)
				-- 移除屏蔽层
				uiMgr:GetCurrentScene():RemoveViewForNoTouch()	
			end)
		)
	)
end
--[[
跳过对话
--]]
function PrivateRoomHomeScene:SkipDialogue()
	self.breakDialogue = true
	self:stopAllActions()
	if self.avatarLayoutNodes.dialogue then
		self.avatarLayoutNodes.dialogue:removeFromParent()
	end
end
--[[
清除餐具
--]]
function PrivateRoomHomeScene:ClearCutlery()
	self.selectedCutlery = nil
	if self.avatarLayoutNodes.cutlery then
		for i, v in ipairs(self.avatarLayoutNodes.cutlery) do
			v:removeFromParent()
		end
		self.avatarLayoutNodes.cutlery = {}
	end
end
--[[
清除菜品
--]]
function PrivateRoomHomeScene:ClearDishes()
	if self.avatarLayoutNodes.dishes and next(self.avatarLayoutNodes.dishes) ~= nil then
		for i, v in ipairs(self.avatarLayoutNodes.dishes) do
			v:removeFromParent()
		end
		self.avatarLayoutNodes.dishes = {}
	end
end
--[[
恢复纪念品
--]]
function PrivateRoomHomeScene:RecoverPutThings()
	for i, v in ipairs(self.avatarLayoutNodes.putThings) do
		v:setVisible(true)
	end
end
--[[
清除顾客
--]]
function PrivateRoomHomeScene:ClearGuests()
	if self.avatarLayoutNodes.guest and next(self.avatarLayoutNodes.guest) ~= nil then
		for i, v in ipairs(self.avatarLayoutNodes.guest) do
			v:removeFromParent()
		end
		self.avatarLayoutNodes.guest = {}
	end
end
return PrivateRoomHomeScene
