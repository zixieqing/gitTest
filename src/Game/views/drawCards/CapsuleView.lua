--[[
扭蛋系统UI
--]]
local CapsuleView = class('CapsuleView', function ()
	local node = CLayout:create(display.size)
	node.name = 'home.CardsListView'
	node:enableNodeEvents()
	return node
end)
local BTNRECT = {
	blue   = cc.rect(220, 720, 120, 115),
	white  = cc.rect(150, 600, 120, 115),
	orange = cc.rect(135, 465, 120, 115)
}
local GoodPurchaseNode = require('common.GoodPurchaseNode')
local function CreateView( )
	local view = display.newLayer(0,0,{size = display.size, ap = cc.p(0.5,0.5)})
	local frontBg = display.newImageView(_res('ui/home/capsule/draw_card_bg_front.png'), display.cx, display.cy)
	view:addChild(frontBg, 5)
	local bg = display.newImageView(_res('ui/home/capsule/capsule_bg.png'), display.cx, display.cy)
    view:setName('views.CapsuleView')
	view:addChild(bg)

	local bgSize = bg:getContentSize()

	-- 抽奖动画
	local capsuleAnimation = sp.SkeletonAnimation:create(
      'effects/capsule/capsule.json',
      'effects/capsule/capsule.atlas',
      1)

    -- capsuleAnimation:update(0)
    -- capsuleAnimation:setToSetupPose()
    capsuleAnimation:setAnimation(0, 'idle', true)
    capsuleAnimation:setPosition(cc.p(0, 0))
    bg:addChild(capsuleAnimation, 2)

    -- 火焰动画
    local fireAnimation = sp.SkeletonAnimation:create(
      'effects/capsule/capsule.json',
      'effects/capsule/capsule.atlas',
      1)
    fireAnimation:update(0)
    fireAnimation:setToSetupPose()
    fireAnimation:setAnimation(0, 'huo1', true)
    fireAnimation:setPosition(cc.p(bgSize.width / 2, bgSize.height / 2))
    bg:addChild(fireAnimation, 2)

    local finger = display.newImageView(_res('ui/home/capsule/finger.png'), display.cx + 477, display.cy - 185, {ap = cc.p(0.785, 0.5)})
    view:addChild(finger)
    finger:setRotation(2) -- 2~90 
    -- 单抽
    local extractSize = cc.size(400, 250)
    local extractLayout = CLayout:create(extractSize)
    view:addChild(extractLayout, 100)
    extractLayout:setPosition(cc.p(cc.p(display.cx + 440, display.cy - 250)))
    extractLayout:setName('extractLayout')
    local extractBtnAct = sp.SkeletonAnimation:create(
      'effects/capsule/conjure.json',
      'effects/capsule/conjure.atlas',
      1)
    extractBtnAct:update(0)
    extractBtnAct:setToSetupPose()
    extractBtnAct:setAnimation(0, 'idle', true)
    extractLayout:addChild(extractBtnAct, 10)
    extractBtnAct:setPosition(cc.p(270, extractSize.height/2))

	local extractBtn = display.newButton(270, extractSize.height/2, {n = _res('ui/home/capsule/draw_card_btn_summon.png')})
	extractLayout:addChild(extractBtn, 9)
    extractBtn:setName('extractBtn')
	extractBtn:setTag(101)
	display.commonLabelParams(extractBtn, {text = '', fontSize = 28, color = '#ffffff'})
	local extractTextBg = display.newButton(130, 50,{n = _res('ui/home/capsule/draw_card_bg_text_btn.png'), enable = false})
    extractLayout:addChild(extractTextBg, 7)
	local extractRichLabel = display.newLabel(130, 50, fontWithColor(14, {text = __('点击召唤')})) 
	extractLayout:addChild(extractRichLabel, 10)
	-- 剩余抽卡次数
	local numLabel = display.newLabel(270, extractSize.height/2 - 22,
		{text =' ', fontSize = 20, color = '#5c5c5c'})
	extractLayout:addChild(numLabel, 10)
	-- 摇一摇
	-- local shakeImage = display.newImageView(_res('ui/home/capsule/draw_card_btn_shake.png'), display.cx - 593, display.cy - 270)
 --    view:addChild(shakeImage, 10)
	-- local shakeBtnAct = sp.SkeletonAnimation:create(
 --      'effects/capsule/shake.json',
 --      'effects/capsule/shake.atlas',
 --      1)
 --    shakeBtnAct:update(0)
 --    shakeBtnAct:setToSetupPose()
 --    shakeBtnAct:setAnimation(0, 'idle', true)
 --    view:addChild(shakeBtnAct, 10)
 --    shakeBtnAct:setPosition(cc.p(display.cx - 490, display.cy - 258))

 --    local shakeTextBg = display.newButton(display.cx - 550, display.cy - 325,{n = _res('ui/home/capsule/draw_card_bg_text_btn.png'), enable = false})
 --    view:addChild(shakeTextBg)
	-- local shakeRichLabel = display.newRichLabel(display.cx - 550, display.cy - 325, {}) 
	-- view:addChild(shakeRichLabel, 10)
	-- local shakeBtn = display.newButton(display.cx - 550, display.cy - 280, {size = cc.size(250, 150)})
	-- view:addChild(shakeBtn, 10)
	-- shakeBtn:setTag(102)
	
	local priceLabel = display.newLabel(isJapanSdk() and 280 or 255, extractSize.height/2,
		{text = '', fontSize = 20, color = '#5c5c5c'})
	extractLayout:addChild(priceLabel, 10)

	local diamondIcon = display.newImageView(_res('arts/goods/goods_icon_' .. DIAMOND_ID ..  '.png'), isJapanSdk() and 250 or 290, extractSize.height/2)
	diamondIcon:setScale(0.18)
	extractLayout:addChild(diamondIcon, 10)

	-- local shakePriceLabel = display.newLabel(display.cx - 510, display.cy - 260, 
	-- 	{text = '', fontSize = 20, color = '#5c5c5c'})
	-- view:addChild(shakePriceLabel, 10)
	-- local shakeDiamondIcon = display.newImageView(_res('arts/goods/goods_icon_' .. DIAMOND_ID ..  '.png'),display.cx - 480, display.cy - 260)
	-- shakeDiamondIcon:setScale(0.18)
	-- view:addChild(shakeDiamondIcon, 10)
	------------六连抽---------------
	local multipleLayout = CLayout:create(cc.size(250, 250))
	multipleLayout:setPosition(cc.p(display.cx - 520, display.cy - 258))
	view:addChild(multipleLayout, 10)
	local multipleBtnAct = sp.SkeletonAnimation:create(
      'effects/capsule/liulian.json',
      'effects/capsule/liulian.atlas',
      1)
    multipleBtnAct:update(0)
    multipleBtnAct:setToSetupPose()
    multipleBtnAct:setAnimation(0, 'animation', true)
    multipleLayout:addChild(multipleBtnAct, 10)
    multipleBtnAct:setPosition(cc.p(135, 145))
    local multipleBtn = display.newButton(135, 145, {n = _res('ui/home/capsule/draw_card_multihop_bg_number.png'), tag = 103})
    multipleLayout:addChild(multipleBtn, 10)
	local multipleIcon = display.newImageView(_res('arts/goods/goods_icon_' .. DIAMOND_ID ..  '.png'), isJapanSdk() and 115 or 160, 146)
	multipleIcon:setScale(0.18)
	multipleLayout:addChild(multipleIcon, 10)
	local multiplePriceLabel = display.newLabel(144, 146,
		{text = '', fontSize = 20, color = '#5c5c5c', ap = cc.p(1, 0.5)})
	multipleLayout:addChild(multiplePriceLabel, 10)
	local multipleTextBg = display.newButton(120, 35,{n = _res('ui/home/capsule/draw_card_bg_text_btn.png'), enable = false})
    multipleLayout:addChild(multipleTextBg, 10)
	local multiplTextLabel = display.newLabel(120, 35,
		fontWithColor(14, {text = __('连续召唤×6')}))
	multipleLayout:addChild(multiplTextLabel, 10)
	------------六连抽---------------
	------------卡池切换-------------
	local chooseLayoutSize = cc.size(440, 160)
	local chooseLayout = CLayout:create(chooseLayoutSize)
	chooseLayout:setAnchorPoint(cc.p(1, 0.5))
	chooseLayout:setPosition(cc.p(display.width - display.SAFE_L, display.height - 150))
	view:addChild(chooseLayout, 10)
	local cardPoolTitleBtn = display.newButton(chooseLayoutSize.width/2, 120, {n = _res('ui/home/capsule/draw_choice_btn')})
	chooseLayout:addChild(cardPoolTitleBtn)
	display.commonLabelParams(cardPoolTitleBtn, {text = '', fontSize = 34, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#5c1919', outlineSize = 1, offset = cc.p(10, 0) , reqW = 300 })
	local chooseTipsIcon = display.newImageView(_res('ui/common/common_btn_tips.png'), chooseLayoutSize.width - 60, 120)
	chooseLayout:addChild(chooseTipsIcon, 5)
	local chooseBtn = display.newButton(chooseLayoutSize.width - 30  , 40, {ap = display.RIGHT_CENTER ,  n = _res('ui/common/common_btn_orange.png') , scale9 = true })
	chooseLayout:addChild(chooseBtn)
	display.commonLabelParams(chooseBtn, fontWithColor(14, {text = __('切换召唤')  , paddingW = 10 }))
	local activityImg = display.newImageView('empty', bgSize.width / 2, bgSize.height / 2)
	bg:addChild(activityImg, 1)
	------------卡池切换-------------
	-- 能量条
	local powerBg = display.newImageView(_res('ui/home/capsule/draw_card_bg_loading.png'), display.cx - 561, display.cy + 220)
	view:addChild(powerBg)
	local powerLightBg = display.newImageView(_res('ui/home/capsule/draw_card_ico_light.png'),display.cx - 538 , display.cy + 210)
	view:addChild(powerLightBg)
	local powerBar = cc.ProgressTimer:create(cc.Sprite:create(_res('ui/home/capsule/draw_card_ico_loading.png')))
	powerBar:setType(cc.PROGRESS_TIMER_TYPE_BAR)
	powerBar:setMidpoint(cc.p(0, 0))
	powerBar:setBarChangeRate(cc.p(0, 1))
	powerBar:setPercentage(100)
	powerBar:setPosition(cc.p(display.cx - 538 , display.cy + 205))
	view:addChild(powerBar)
	-- 重写顶部状态条
    local topLayoutSize = cc.size(display.width, 80)
    local moneyNode = CLayout:create(topLayoutSize)
    moneyNode:setName('TOP_LAYOUT')
    display.commonUIParams(moneyNode, {ap = display.CENTER_TOP, po = cc.p(display.cx, display.height)})
    view:addChild(moneyNode,100)

    -- local backBtn = display.newButton(0, 0, {n = _res("ui/common/common_btn_back")})
    -- display.commonUIParams(backBtn, {po = cc.p(backBtn:getContentSize().width * 0.5 + 30, topLayoutSize.height - 18 - backBtn:getContentSize().height * 0.5)})
    -- backBtn:setName('btn_backButton')
    -- moneyNode:addChild(backBtn, 5)
    -- top icon
    local imageImage = display.newImageView(_res('ui/home/nmain/main_bg_money.png'),0,0,{enable = false,
    scale9 = true, size = cc.size(900,54)})
    display.commonUIParams(imageImage,{ap = cc.p(1.0,1.0), po = cc.p(display.width,80)})
    moneyNode:addChild(imageImage)
    local moneyNods = {}
    local iconData = {CAPSULE_VOUCHER_ID, HP_ID, GOLD_ID, DIAMOND_ID}
    for i,v in ipairs(iconData) do
		local isShowHpTips = (v == HP_ID) and 1 or -1
        local purchaseNode = GoodPurchaseNode.new({id = v, isShowHpTips = isShowHpTips})
        display.commonUIParams(purchaseNode,
        {ap = cc.p(1, 0.5), po = cc.p(topLayoutSize.width - 30 - (( 4 - i) * (purchaseNode:getContentSize().width + 16)), imageImage:getPositionY()- 26)})
        moneyNode:addChild(purchaseNode, 5)
        purchaseNode:setName('purchaseNode' .. i)
        purchaseNode.viewData.touchBg:setTag(checkint(v))
        moneyNods[tostring( v )] = purchaseNode
    end
	return {
		view             = view,
		bg               = bg,
		bgSize           = bgSize,
		priceLabel       = priceLabel,
		-- shakePriceLabel  = shakePriceLabel,
		extractBtnAct    = extractBtnAct,
		diamondIcon      = diamondIcon,
		extractBtn       = extractBtn,
		numLabel         = numLabel,
		capsuleAnimation = capsuleAnimation,
		fireAnimation    = fireAnimation,
		finger           = finger,
		-- shakeBtn         = shakeBtn,
		extractTextBg    = extractTextBg,
		powerBar		 = powerBar,
		-- shakeRichLabel   = shakeRichLabel,
		extractRichLabel = extractRichLabel,
		-- shakeDiamondIcon = shakeDiamondIcon,
		moneyNods        = moneyNods,
		multipleBtn      = multipleBtn,
		multiplePriceLabel = multiplePriceLabel,
		multipleIcon     = multipleIcon,
		multipleLayout   = multipleLayout,
		extractLayout    = extractLayout,
		chooseLayout 	 = chooseLayout,
		cardPoolTitleBtn = cardPoolTitleBtn,
		chooseBtn  	 	 = chooseBtn,
		activityImg      = activityImg



	}
end
function CapsuleView:ctor( ... )
	self.canRotate = true -- 判断指针是否可以触摸
	self.canClick = true -- 判断左侧按钮是否可以点击
	-- self.canShake = false -- 判断是否可以摇晃
	self.clickNum = 0 -- 按钮点击计数
	self.clickStr = '' -- 点击顺序
	self.rotate = 2 -- 指针角度
	local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 100))
	eaterLayer:setTouchEnabled(true)
	eaterLayer:setContentSize(display.size)
	eaterLayer:setAnchorPoint(cc.p(0.5, 1.0))
	eaterLayer:setPosition(cc.p(display.cx, display.height))
	self:addChild(eaterLayer, -1)
	self.viewData_ = CreateView()
	display.commonUIParams(self.viewData_.view, {po = display.center})
	self:addChild(self.viewData_.view, 1)
	-- 注册监听事件
	self.touchListener_ = cc.EventListenerTouchOneByOne:create()
    self.touchListener_:registerScriptHandler(handler(self, self.onTouchBegan_), cc.Handler.EVENT_TOUCH_BEGAN)
    self.touchListener_:registerScriptHandler(handler(self, self.onTouchMoved_), cc.Handler.EVENT_TOUCH_MOVED)
    self.touchListener_:registerScriptHandler(handler(self, self.onTouchEnded_), cc.Handler.EVENT_TOUCH_ENDED)
    cc.Director:getInstance():getEventDispatcher():addEventListenerWithSceneGraphPriority(self.touchListener_, self)
    -- 添加摇晃监听
    -- self.shakeListener = cc.EventListenerCustom:create('ShakeOver',function (event)
   	-- 	if self.canShake == true then
   	-- 		self.canShake = false
   	-- 		local mediator = AppFacade.GetInstance():RetrieveMediator('CapsuleMediator')
   	-- 		mediator:SendSignal(POST.GAMBLING_LUCKY.cmdName, {type = 1})
   	-- 	end
   	-- end)
   	-- cc.Director:getInstance():getEventDispatcher():addEventListenerWithSceneGraphPriority(self.shakeListener, self)
end
-- 添加点击的响应动画
function CapsuleView:CreateCot( position, type )

	local cotAnimation = sp.SkeletonAnimation:create(
   		'effects/capsule/capsule_click.json',
   		'effects/capsule/capsule_click.atlas',
   		1)
   	-- cotAnimation:update(0)
   	-- cotAnimation:setToSetupPose()
   	cotAnimation:setAnimation(0, type, false)
   	cotAnimation:setPosition(position)
   	self.viewData_.bg:addChild(cotAnimation, 10)
   	-- 结束后移除
   	cotAnimation:registerSpineEventHandler(function (event)
   		cotAnimation:runAction(cc.RemoveSelf:create())
   	end, sp.EventType.ANIMATION_END)
end
-- 更改点击次数，记录点击顺序 
function CapsuleView:ChangeClickNum( type )
	self.clickNum = self.clickNum + 1
	if self.clickNum == 3 then
		-- self.viewData_.fireAnimation:update(0)
    	-- self.viewData_.fireAnimation:setToSetupPose()
 --    	self.viewData_.fireAnimation:setAnimation(0, 'fire2', true)
    elseif self.clickNum == 15 then
    	PlayAudioClip(AUDIOS.UI.ui_flame.id)
    	self.canClick = false
    	self:runAction(
    		cc.Sequence:create(
    			cc.DelayTime:create(0.4),
    			cc.CallFunc:create(
    				function ()
    					self.viewData_.fireAnimation:setToSetupPose()
    					self.viewData_.fireAnimation:setAnimation(0, 'huo2', true)		
    				end
    			)
    		)
    	)
    	self:CreateCot(cc.p(self.viewData_.bgSize.width/2, self.viewData_.bgSize.height/2), 'baodian1')
	end
	self.clickStr = self.clickStr .. type
	local percentage = (15 - self.clickNum) *100/15
	self.viewData_.powerBar:runAction(cc.ProgressTo:create(0.3, percentage))
end
function CapsuleView:onTouchBegan_(touch, event)
	local point = touch:getLocation()
	local origin = cc.p(self.viewData_.finger:getPositionX(), self.viewData_.finger:getPositionY())
	local rotate = self.viewData_.finger:getRotation()

	local radius = math.sqrt((point.y - origin.y)*(point.y - origin.y) + (point.x - origin.x)*(point.x - origin.x))
	local rotate_P = math.abs(math.deg(math.atan((point.y - origin.y)/(point.x - origin.x))))
	if self.canRotate then -- 判断指针是否可以滑动
		if radius < 220 and origin.x-220 < point.x and point.x<origin.x and origin.y<point.y and point.y<origin.y+220 then
			if rotate_P>= rotate-20 and rotate_P <= rotate+20 then
				return true
			end
		end
	end
	if self.canClick then -- 判断按钮是否可以点击
		local pointBg = self.viewData_.bg:convertToNodeSpace(point)
		if cc.rectContainsPoint(BTNRECT.blue, pointBg) then -- 蓝色按钮
			PlayAudioClip(AUDIOS.UI.ui_additive.id)
			self:ChangeClickNum('1')
			self:CreateCot(cc.p(280, 777.5), 'dianji1')
			self:CreateCot(cc.p(self.viewData_.bgSize.width/2, self.viewData_.bgSize.height/2), 'dianji_quan_1')
		elseif cc.rectContainsPoint(BTNRECT.white, pointBg) then -- 白色按钮
			PlayAudioClip(AUDIOS.UI.ui_additive.id)
			self:ChangeClickNum('2')
			self:CreateCot(cc.p(210, 657.5), 'dianji2')
			self:CreateCot(cc.p(self.viewData_.bgSize.width/2, self.viewData_.bgSize.height/2), 'dianji_quan_1')
		elseif cc.rectContainsPoint(BTNRECT.orange, pointBg) then -- 橙色按钮
			PlayAudioClip(AUDIOS.UI.ui_additive.id)
			self:ChangeClickNum('3')
			self:CreateCot(cc.p(195, 522.5), 'dianji3')
			self:CreateCot(cc.p(self.viewData_.bgSize.width/2, self.viewData_.bgSize.height/2), 'dianji_quan_1')
		end

	end
end
function CapsuleView:onTouchMoved_(touch, event)
	local point = touch:getLocation()
	local origin = cc.p(self.viewData_.finger:getPositionX(), self.viewData_.finger:getPositionY())
	local rotate = self.viewData_.finger:getRotation()
	local rotate_P = math.abs(math.deg(math.atan((point.y - origin.y)/(point.x - origin.x))))
	if point.x <= origin.x then
		if point.y >= origin.y then
			if rotate_P >= 2 and rotate_P <= 90 then
				self.viewData_.finger:setRotation(rotate_P)
				self.rotate = rotate_P
			end
		else
			self.viewData_.finger:setRotation(2)
			self.rotate = 2
		end
	else
		if point.y >= origin.y then
			self.viewData_.finger:setRotation(90)
			self.rotate = 90
		else
		end
	end
end
function CapsuleView:onTouchEnded_(touch, event)
end
--[[
重置左侧按钮
--]]
function CapsuleView:ResetLeftBtn()
	local viewData = self.viewData_
	viewData.powerBar:runAction(cc.ProgressTo:create(1, 100))
	viewData.fireAnimation:setToSetupPose()
    viewData.fireAnimation:setAnimation(0, 'huo1', true)
    viewData.fireAnimation:setVisible(true)
    self.clickNum = 0
    self.clickStr = ''
end
function CapsuleView:onCleanup()
    local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
    -- eventDispatcher:removeCustomEventListeners('ShakeOver')
    eventDispatcher:removeEventListener(self.touchListener_)
end
return CapsuleView
