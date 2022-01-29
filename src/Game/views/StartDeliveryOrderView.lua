--[[
开始配送订单页面 view
--]]
---@class StartDeliveryOrderView
local StartDeliveryOrderView = class('StartDeliveryOrderView', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.StartDeliveryOrderView'
	node:enableNodeEvents()
	return node
end)
local socket = require('socket')
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
---@type TakeawayManager
local takeawayInstance = AppFacade.GetInstance():GetManager('TakeawayManager')
local AdditionalTime = 150
local CompleteOrder = 4
local WaitingShipping = 1
local PublicOrder = 2
local PrivateOrder =1
local PreTeam  = 1001
local NextTeam  = 1002
local PreDingCar = 1003
local NextDingCar = 1004
local  MiddleLayoutTable  = {
	completeImage =  _res("ui/home/takeaway/takeout_ico_complete.png"),
	noCompleteImage =  _res("ui/home/takeaway/takeout_ico_complete_notnulock.png") ,
	nocompleteLineImage = _res("ui/home/takeaway/takeout_line_complete_notnulock.png"),
	completeLineImage = _res("ui/home/takeaway/takeout_line_complete.png")
}
local  ImageCollect =  -- 图片背景的集合
{
	{
		bgImage  =_res("ui/home/takeaway/takeout_takeout_bg.png"),
		title = _res("ui/home/takeaway/takeout_takeout_title.png"),
		titleText = __('普通外卖订单')

	},
	{
		bgImage  =_res("ui/home/takeaway/takeout_supertakeout_bg.png"),
		title = _res("ui/home/takeaway/takeout_supertakeout_title.png") ,
		titleText = __('超大外卖订单')
	}
}
function StartDeliveryOrderView:ctor(param)
	self.teamBattlePoint = 0  -- 记录队伍的战斗灵力
	self.orderType  = param.orderType   -- 订单类型  1.普通订单 2.超级订单
	self.orderId =  param.orderId  -- 订单的编号
	self.status  =  param.status   -- 外卖订单的状态
	self.time = checkint(param.time)
	self.recipeCookingPoint = 0
	self.assistantCookingPoint = 0
	self.hasDeliveredNumber  = param.hasDeliveredNumber
	self.lastDeliveredPlayers = param.lastDeliveredPlayers
	self.deliveryTime = param.deliveryTime or  0
	self.takeawayId = param.takeawayId
	self.firstGo = 1 -- 是否是第一次调整队伍
	self.businessData = app.restaurantMgr:GetAllAssistantBuff(3)
	self.startTime = math.floor(socket.gettime())
	local data = takeawayInstance:GetDatas().diningCar or {}
	self.recipeUpgradeRefreshUI = {}
	self.dingCarTable =    {}
	self.orderData = takeawayInstance:GetOrderInfoByOrderInfo({orderId = self.orderId ,orderType = self.orderType  }) or {}
	for k, v in ipairs(data) do
		if v.diningCarId then
			table.insert(self.dingCarTable,#self.dingCarTable+1, v)
		end
	end

	if param.status ~= 4 then
		self.orderSwithType = 1 --  以表示的是有效任务出现
	end

	local dataOrder = {}   -- 此处赋值所学要的材料和id
	local str = nil
	if self.orderType == PrivateOrder then
		str = 'privateOrder'
	elseif self.orderType == PublicOrder then
		str = 'publicOrder'
	end
	dataOrder =  CommonUtils.GetConfigAllMess(str,'takeaway')

	dataOrder = dataOrder[tostring(self.takeawayId)]
	self.dataOrder = dataOrder or {}

	local orderSize = cc.size(563,631)  --右侧区域
	self.orderSize = orderSize
	local rightlayout  = CLayout:create(orderSize)
	self.rightlayout = rightlayout

	self:addChild(rightlayout,2)
	-- 顶部的图片
	-- body
	local bgImageView = display.newImageView(checktable(ImageCollect[self.orderType]).bgImage, orderSize.width/2, orderSize.height/2)
	rightlayout:addChild(bgImageView)
	self.bgImageView = bgImageView
	local  swallowLayout = display.newLayer(orderSize.width/2, orderSize.height/2, {size = orderSize, ap = display.CENTER, color = cc.c4b(0,0,0,0), enable = true})
	rightlayout:addChild(swallowLayout)
	local offHeight = 10

	if self.orderType == PublicOrder then
		local titleImageView = display.newImageView(checktable(ImageCollect[self.orderType]).title)
		rightlayout:addChild(titleImageView,3)
		local bgSize = titleImageView:getContentSize()
		local position = nil
		local bgImageViewPosition = nil
		position = cc.p(bgSize.width/2,bgSize.height/2)
		local titleLabel = display.newLabel(position.x, position.y +10,  {ttf = true , text = '', fontSize = 24 , font =  TTF_GAME_FONT, color = fontWithColor('BC').color})

		display.commonLabelParams(titleLabel, {ttf = true, font = TTF_GAME_FONT, text = '', fontSize = 24, color = fontWithColor('BC').color})
		titleImageView:addChild(titleLabel)
		self.bgImageView = bgImageView
		self.titleLabel = titleLabel
		self.titleImageView = titleImageView
		titleImageView:setCascadeOpacityEnabled(true)
		position = cc.p(bgSize.width/2,bgSize.height/2)
		bgImageViewPosition = cc.p(orderSize.width/2, orderSize.height - 20)
		titleImageView:setPosition(bgImageViewPosition)
	elseif self.orderType == PrivateOrder then
		--position = cc.p(bgSize.width/2,bgSize.height/2)
		local titleLabel = display.newLabel(orderSize.width/2 - 15, orderSize.height - 35 , fontWithColor('14', {outline = false , text = "" ,color = "5b3c25" }) )
		rightlayout:addChild(titleLabel)
		self.titleLabel = titleLabel
		-- 下面底部的背景调整
		local flowbg_two = display.newImageView(_res('ui/home/takeaway/takeout_flow_bg_2.png'))
		flowbg_two:setPosition(cc.p(orderSize.width/2 -10, orderSize.height/2 + offHeight ))
		flowbg_two:setAnchorPoint(display.CENTER)
		self.rightlayout:addChild(flowbg_two)
		local flowbg_twoSize = flowbg_two:getContentSize()
		local rewardsImage = display.newImageView(_res('ui/home/takeaway/takeout_bg_reward.png'), flowbg_twoSize.width/2 , 0, { ap = display.CENTER_BOTTOM})
		flowbg_two:addChild(rewardsImage)
		flowbg_two:setCascadeOpacityEnabled(true)
		rewardsImage:setCascadeOpacityEnabled(true)
	end

	-- 顶部下
	--==============================--
	--desc:该方法是创建顶部的内容
	--time:2017-04-24 06:34:00
	--@param:
	--return
	--==============================--
	local createNeedFoods =  function () -- 构建上半部分的所需食物的列表
		local flowbg = nil
		local flowContentSize = cc.size(537, 188)
		if self.orderType == PublicOrder then
			flowbg = display.newImageView(_res('ui/home/takeaway/takeout_flow_bg_1.png'))
		elseif self.orderType == PrivateOrder then
			flowbg =  display.newLayer(flowContentSize.width/2, flowContentSize.height/2, { size = flowContentSize , ap = display.CENTER  })
		end

		--flowbg:getContentSize()
		local flowLayout = CLayout:create(flowContentSize)
		flowbg:setPosition(cc.p(flowContentSize.width/2, flowContentSize.height/2+offHeight))
		flowLayout:setAnchorPoint(display.CENTER_TOP)
		flowLayout:addChild(flowbg)
		rightlayout:addChild(flowLayout)
		local flowPosition =  nil
		if PublicOrder == self.orderType then
			flowPosition = cc.p(orderSize.width/2 ,orderSize.height - 70)
		elseif PrivateOrder == self.orderType then
			flowPosition = cc.p(orderSize.width/2 -10,orderSize.height - 70)
		end
		flowLayout:setPosition(flowPosition)
		if self.status  == WaitingShipping  then
			local text =  __('配送时间：')
			local numLabel= display.newRichLabel(flowContentSize.width - 10,flowContentSize.height - 30,{ap = display.RIGHT_CENTER, c = {
				fontWithColor(6,{text =text}),
				fontWithColor(10,{text = "00:00:00"})
			}})
			flowbg:addChild(numLabel)
			self.numLabel = numLabel
			self:UpdateDeliveryTime()

		end
		local foodbg = display.newImageView(_res('ui/home/takeaway/takeout_bg_font_name.png'),90,flowContentSize.height -30)
		local foodbgContentSize = foodbg:getContentSize()
		local foodLabel = display.newLabel(foodbgContentSize.width/2, foodbgContentSize.height/2, fontWithColor(6,{text = __('客户点单'), reqW = 140}))
		foodbg:addChild(foodLabel)
		flowbg:addChild(foodbg)
		flowbg:setCascadeOpacityEnabled(true)
		foodLabel:setCascadeOpacityEnabled(true)
		flowbg:setCascadeOpacityEnabled(true)
		local goodLayout =  self:needGood(dataOrder)
		self.goodLayout = goodLayout
		local foodSize = cc.size(orderSize.width,160)
		local foodLayout = CLayout:create(foodSize)
		foodLayout:setAnchorPoint(display.CENTER)
		foodLayout:setPosition(cc.p(flowContentSize.width/2,flowContentSize.height/2))
		goodLayout:setScale(0.85)
		goodLayout:setPosition(cc.p(foodSize.width/2,foodSize.height/2))
		foodLayout:addChild(goodLayout)
		flowLayout:addChild(foodLayout)
		return  {
			foodLayout = foodLayout ,
			goodLayout = goodLayout
		}
	end


	--菜不足的说明
	--==============================--
	--desc:用于创建外卖车状态的方法
	--time:2017-04-24 06:34:00
	--@param:
	--return
	--==============================--
	local createOrderStatusDisplay = function ( )
		-- body

		local middlebg = display.newImageView(_res('ui/home/takeaway/takeout_flow_bg_2.png'))
		-- local middleSize = cc.size(orderSize.width,173)

		local middleSize = middlebg:getContentSize()
		local middleLayout = CLayout:create(middleSize)
		local middleLayoutPos = nil
		if PublicOrder == self.orderType then
			middleLayoutPos = cc.p(orderSize.width/2,orderSize.height - 70)
		elseif PrivateOrder == self.orderType then
			middleLayoutPos = cc.p(orderSize.width/2 - 20,orderSize.height - 70)
		end

		middleLayout:setAnchorPoint(display.CENTER_TOP)
		middleLayout:addChild(middlebg)
		middlebg:setPosition(cc.p(middleSize.width/2,middleSize.height/2))
		middleLayout:setPosition(middleLayoutPos)
		rightlayout:addChild(middleLayout)
		local numLabel = nil
		if self.status  ~= WaitingShipping or  self.orderType == PublicOrder then
			local text =  __('预计配送时间：')
			if   self.status  == WaitingShipping  then
				text =  __('订单消失时间：')
			end

			numLabel= display.newRichLabel(middleSize.width /2,middleSize.height - 30,{c = {
				fontWithColor(6,{text =text}),
				fontWithColor(10,{text = "00:00:00"})
			}})
			middleLayout:addChild(numLabel)
			self.numLabel = numLabel
			local callBack =  function ()
				self.time = self.time or 0
				if self.time <= 0 then
					if self.status ~= WaitingShipping then
						self.sendMessage:getLabel():setString(__('领 取'))
						self.status = CompleteOrder
					else
						self.sendMessage:getLabel():setString(__('订单过期'))
					end
					return
				end

				local curTime = math.floor(socket.gettime())
				self.time =  self.time - (curTime - self.startTime)
				self.startTime = curTime
			end

			numLabel:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.DelayTime:create(1),cc.CallFunc:create(callBack))))
		end
		local  iconCompleteTable = {}
		local  iconCompleteLineTable = {}
		local  ico_carTable = {}
		local  iconCompleteWith = 33
		local  iconCompleteLinewith = 160
		local  progressLableTable = {}
		local count  = 2
		local width1 =  ( iconCompleteWith + iconCompleteLinewith)/2
		local iconCompletePos ={}
		local labelTextTable = {
			__('配送中'),
			__('返回中'),
			__('订单完成')
		}
		local yuanWith = 50
		local linewidth = 160

		local middleContentSize = cc.size(2*linewidth + 3*yuanWith ,middleSize.height)
		local middleContentlayout = CLayout:create(middleContentSize)
		middleContentlayout:setPosition(cc.p(middleSize.width/2,middleSize.height/2))
		middleLayout:addChild(middleContentlayout)
		for i =1,3 do
			local iconCompleteImage1 =  display.newImageView(MiddleLayoutTable.noCompleteImage, (i-1) *linewidth + (i-0.5) * yuanWith ,middleSize.height/2-45)
			table.insert(iconCompletePos,#iconCompletePos+1,cc.p((i-1) *linewidth + yuanWith ,middleSize.height/2))
			middleContentlayout:addChild(iconCompleteImage1)
			table.insert(iconCompleteTable,#iconCompleteTable+1,iconCompleteImage1)
			local progressLable =  display.newLabel((i-1) *linewidth + (i-0.5) * yuanWith,middleSize.height/2 - 90 , fontWithColor(6,{text = labelTextTable[i]}))
			middleContentlayout:addChild(progressLable)
			table.insert(progressLableTable,#progressLableTable+1,progressLable)
			local  ico_car = display.newImageView(_res('ui/home/takeaway/takeout_ico_car_notactive.png'),(i-1) *linewidth + (i-0.5) * yuanWith,middleSize.height/2 + 15 )
			middleContentlayout:addChild(ico_car)
			table.insert( ico_carTable,#ico_carTable+1 ,ico_car)
		end
		for i =1 ,2 do
			local iconCompleteLineImage1 =  display.newImageView(_res('ui/home/takeaway/takeout_line_complete_notnulock.png'),i*yuanWith +(i- 0.5) * linewidth , middleSize.height/2-45 )
			middleContentlayout:addChild(iconCompleteLineImage1)
			table.insert(iconCompleteLineTable,#iconCompleteLineTable+1,iconCompleteLineImage1)
		end

		self.iconCompleteTable = iconCompleteTable
		self.iconCompleteLineTable = iconCompleteLineTable
		self.progressLableTable =  progressLableTable
		self.ico_carTable = ico_carTable
	end

	local createMarQueue = function (  )
		-- body
		local noticeImage = display.newImageView(_res('ui/home/takeaway/takeout_bg_notice.png'))
		-- noticeImage:setPosition(cc.p(orderSize.width/2,orderSize.height -285))
		-- rightlayout:addChild(noticeImage)
		local noticeImageSize = noticeImage:getContentSize()
		noticeImage:setCascadeOpacityEnabled(true)
		noticeImage:setOpacity(0)
		noticeImage:runAction(cc.Sequence:create(cc.DelayTime:create(1),cc.FadeIn:create(0.5)))
		local clippingNode = cc.ClippingNode:create()
		clippingNode:setAnchorPoint(cc.p(0.5,0.5))
		noticeImage:setPosition(cc.p(noticeImageSize.width/2,noticeImageSize.height/2))
		clippingNode:setContentSize( cc.size(noticeImageSize.width,noticeImageSize.height))
		clippingNode:addChild(noticeImage)
		clippingNode:setPosition(cc.p(orderSize.width/2,orderSize.height -285))
		rightlayout:addChild(clippingNode)
		local stencilNode = display.newImageView(_res('ui/home/takeaway/takeout_bg_notice.png'),noticeImageSize.width/2,noticeImageSize.height/2)
		clippingNode:setStencil(stencilNode)
		clippingNode:setAlphaThreshold(1)
		clippingNode:setInverted(false)
		self.noticeImage = noticeImage
	end
	local data = dataOrder
	if self.orderType == 1 then
		self:judageOrderStatus()
		if self.status > 1 then
			createOrderStatusDisplay()
		else
			self.foodData = createNeedFoods()
		end
		self.treasureType = 0
		local layout = self:createRewardLayout(dataOrder.rewards)
		layout:setPosition(orderSize.width/2 , 220 )
		rightlayout:addChild(layout)
	elseif  self.orderType ==  2 then
		local bgLight =  display.newImageView(_res('ui/home/takeaway/takeout_supertakeout_bg_light.png'),orderSize.width/2,orderSize.height/2)
		rightlayout:addChild(bgLight, -1)
		if self.status > 1 then
			createOrderStatusDisplay()
		else
			createNeedFoods()
		end
		createMarQueue()
		self.treasureType= 0
		local layout =self:createRewardLayout(dataOrder.baseRewards)
		layout:setPosition(orderSize.width/4 , 220 )
		rightlayout:addChild(layout)
		local layout =self:createRewardLayout(dataOrder.submitRewards,true)
		layout:setPosition(orderSize.width*3/4 , 220 )
		rightlayout:addChild(layout)
		self.treasureLayout = layout
		self:updateTestsureAndMarqueue(self.hasDeliveredNumber,self.lastDeliveredPlayers or {})
	end
	local sendMessage = display.newButton(orderSize.width/2 + 100 ,35,{
		n = _res('ui/common/common_btn_orange.png'), scale = true , size = cc.size(130, 58)
	})

	display.commonLabelParams(sendMessage,fontWithColor(14,{text = __('配 送'),ap = cc.p(0.5,0.5)}))
	-- sendMessage:setPosition(cc.p(orderSize.width /2,55))
	--sendMessage:setScale(0.9)
	rightlayout:addChild(sendMessage)
	local cancelBtn = display.newButton(orderSize.width/2 -  100 ,35,{
		n = _res('ui/common/common_btn_white_default.png'), scale = true , size = cc.size(130, 58)
	})
	display.commonLabelParams(cancelBtn,fontWithColor(14,{text = __('取 消')}))

	rightlayout:addChild(cancelBtn)
	self.rightlayout = rightlayout

	self.eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 100))
	self.eaterLayer:setTouchEnabled(true)
	self.eaterLayer:setContentSize(display.size)
	self.eaterLayer:setAnchorPoint(cc.p(0.5, 1.0))
	self.eaterLayer:setPosition(cc.p(display.cx, display.height))
	self:addChild(self.eaterLayer, -1)
	self.sendMessage = sendMessage

	self.cancelBtn = cancelBtn
	local teamLayout = CLayout:create(cc.size(display.width,display.height))
	teamLayout:setPosition(cc.p(0,display.cy))
	self:addChild(teamLayout)
	self.teamLayout = teamLayout
	self:UpdateUI()

	-- 为右半部分区域
	local centerBg = display.newImageView(_res('ui/home/takeaway/takeout_car_bg.png'), display.cx*1.5 - 10, display.cy*1.3+30,
	{scale9 = true, size = cc.size(495, 126), enable = true, animate = false})
	self.teamLayout:addChild(centerBg, 5)
	centerBg:setCascadeOpacityEnabled(true)
	local teamInstructionsLabel  = display.newRichLabel(0, 0,
	{ap = cc.p(0, 0.5), c = {
		{text = string.format(__('每次消耗每位队员%d点新鲜度')  ,checkint(self.dataOrder.consumeVigour) ) , fontSize = 20, color = '#ffd852'},
	}
	})
	teamInstructionsLabel:setPosition(cc.p(0, -70))
	centerBg:addChild(teamInstructionsLabel)
	teamInstructionsLabel:setVisible(false)

	local everyTeamLabel  = display.newRichLabel(0, 0,
	{ap = cc.p(0, 0.5), c = {
		{text = string.format(__('每次消耗每位队员%d点新鲜度')  ,checkint(self.dataOrder.consumeVigour) ) , fontSize = 20, color = '#ffd852'},
	}
	})
	everyTeamLabel:setPosition(cc.p(0, -100))
	everyTeamLabel:reloadData()
	centerBg:addChild(everyTeamLabel)
	everyTeamLabel:setVisible(false)

	self.viewData = {
		everyTeamLabel = everyTeamLabel ,
		teamInstructionsLabel = teamInstructionsLabel ,
		centerBg = centerBg,
	}
	self:InitTeamFormationPanel()


	-- 下面外卖车部分的界面
	local diningCarSize = cc.size(570,400)
	local diningCarLayout = CLayout:create(diningCarSize)
	local diningCarBg  = display.newImageView(_res('ui/home/takeaway/takeout_car_bg.png'), diningCarSize.width/2, diningCarSize.height/2,{animate = false, enable = true})
	diningCarLayout:addChild(diningCarBg)
	diningCarBg:setCascadeOpacityEnabled(true)

	self.diningCarLayout = diningCarLayout
	-- 下面区域的三个点的切换
	local circleLayoutSize = cc.size(25*3,30)
	local circleLayout = CLayout:create(circleLayoutSize)
	circleLayout:setAnchorPoint(0.5,1)
	circleLayout:setPosition(cc.p(diningCarBg:getContentSize().width/2,0))
	diningCarBg:addChild(circleLayout)

	local circleTable = {}
	for i = 1 , 3 do
		local  circle = display.newImageView(_res('ui/home/takeaway/takeout_ico_spot_default.png'),(i - 0.5)*25,circleLayoutSize.height/2)
		table.insert(circleTable,#circleTable+1,circle)
		circleLayout:addChild(circle)
	end
	self.circleTable = circleTable

	diningCarLayout:setPosition(cc.p(display.width/4*3,display.height/8*2))
	self.teamLayout:addChild(diningCarLayout)
	local dingCarSwallow = display.newLayer(diningCarSize.width/2,diningCarSize.height/2 , {ap = display.CENTER , color = cc.r4b(0,0,0,0) ,size = cc.size(diningCarSize.width + 20, diningCarSize.height -200)  ,enable = true  })
	diningCarLayout:addChild(dingCarSwallow,19)
	-- 前后按钮
	local preBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_switch.png'), cb = handler(self, self.ChangeDiningCarBtnCallback)})
	preBtn:setScaleX(-1)
	display.commonUIParams(preBtn, {po = cc.p(
	preBtn:getContentSize().width * 0.5 - 10 -15,
	diningCarSize.height/2)})
	diningCarLayout:addChild(preBtn, 20)

	preBtn:setTag(PreDingCar)
	self.preBtn = preBtn
	local nextBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_switch.png'), cb = handler(self, self.ChangeDiningCarBtnCallback)})
	display.commonUIParams(nextBtn, {po = cc.p(
	diningCarSize.width - nextBtn:getContentSize().width * 0.5 + 10 + 15,
	diningCarSize.height/2)})
	diningCarLayout:addChild(nextBtn, 20)
	nextBtn:setTag(NextDingCar)
	self.nextBtn = nextBtn

	local withOffset = 0
	local bgDingCarSize =  diningCarBg:getContentSize()
	local spnPath = _spn(HOME_THEME_STYLE_DEFINE.LONGXIA_SPINE or 'ui/home/takeaway/longxiache')
	local qAvatar = sp.SkeletonAnimation:create(spnPath.json, spnPath.atlas, 1.0)
	qAvatar:setPosition(cc.p(bgDingCarSize.width/2,bgDingCarSize.height - 30 ))
	diningCarBg:addChild(qAvatar,5)
	qAvatar:setToSetupPose()
	qAvatar:setAnimation(0, 'idle', true)
	-- qAvatar:setScale(1.5)

	local deliveryStatusBg = display.newImageView(_res('ui/home/takeaway/takeout_bg_distribution.png'),bgDingCarSize.width/2,bgDingCarSize.height)
	deliveryStatusBgSize = deliveryStatusBg:getContentSize()
	local deliveryStatusText =   display.newLabel(deliveryStatusBgSize.width/2,deliveryStatusBgSize.height-15, { fontSize = 26, color = "#ffffff" , text = __('配送中')})
	deliveryStatusText:setCascadeOpacityEnabled(true)
	diningCarBg:addChild(deliveryStatusBg,12)
	deliveryStatusBg:addChild(deliveryStatusText,12)
	deliveryStatusBg:setCascadeOpacityEnabled(true)
	self.deliveryStatusBg = deliveryStatusBg
	self.deliveryStatusBg :setVisible(false)
	self.deliveryStatusText = deliveryStatusText
	local dingCarLevel = display.newLabel(bgDingCarSize.width/2, bgDingCarSize.height - 50,
	{text = "XXXXXXX", fontSize = 25, color = '##ffd852',ap = cc.p(0.5,0.5)})

	diningCarBg:addChild(dingCarLevel)
	self.dingCarLevel = dingCarLevel

	withOffset = bgDingCarSize.height - 130 +20
	--
	if not  self.time then
		self.time = 0
	end
	local speedLabel = display.newRichLabel(0, 0,
	{ap = cc.p(0.5, 0.5), c = {
		{text = tostring(math.floor(self.time)), fontSize = fontWithColor('M2PX').fontSize, color = fontWithColor('BC').color},
		{text = '.', fontSize = fontWithColor('SPX').fontSize, color = fontWithColor('BC').color},
		{text = tostring(math.floor((self.time - math.floor(self.time)) * 10)), fontSize = fontWithColor('SPX').fontSize, color = fontWithColor('BC').color},
		{text = 's', fontSize = fontWithColor('SPX').fontSize, color = fontWithColor('BC').color},
	}
	})
	local takecarSpeedLine =  display.newImageView(_res('ui/home/takeaway/takeout_car_line.png'),bgDingCarSize.width/2, withOffset - 15)
	diningCarBg:addChild(speedLabel)
	speedLabel:setPosition(cc.p(bgDingCarSize.width/2,withOffset))
	speedLabel:reloadData()
	diningCarBg:addChild(takecarSpeedLine,5)
	self.dingCarLevel = dingCarLevel
	self.speedLabel  = speedLabel
	--self.maxExpLabel = maxExpLabel
	self.selectIndexCar =self.selectIndexCar or  1
	self.selectedTeamIdx =  self.selectedTeamIdx or 1
	self:runActionFadeIn()

	self:UpdateDingCarInfo(self.selectIndexCar)
end
--==============================--
--desc:该方法是用于计算外卖车的配送时间
--time:2017-06-30 06:01:10
--@return
--==============================--
function StartDeliveryOrderView:UpdateDeliveryTime()
	local diningCarLevelTable = CommonUtils.GetConfigAllMess('diningCarLevelUp','takeaway')
	---  获取餐
	if not self.selectIndexCar then
		self:getSelectDiningCarid()
	end
	local diningCarId = self.selectIndexCar or 1
	local oneCarData =  self.dingCarTable[diningCarId]
	if not oneCarData then
		return
	end
	local level = oneCarData.level
	local speed = checkint( checktable(diningCarLevelTable[tostring(level)]).speed) or 0
	local reduces = self:GeRestaurantReduceTakeawayTime()
	--- 订单时间 = math.ceil(( 基本时间  + 额外固定时间  - 外卖车速度 - 厨房技能的buff))  * ( 1 - 厨房技能缩减百分比) * 2
	local deliveryTime = math.ceil((self.deliveryTime  - speed - checkint(reduces[tostring(RestaurantSkill.SKILL_TYPE_TAKEAWAY_DELIVERY_SPEED_UP_CONSTANT)]) ) * (1 - tonumber(reduces[tostring(RestaurantSkill.SKILL_TYPE_TAKEAWAY_DELIVERY_SPEED_UP_PERCENT)]))  ) * 2 + AdditionalTime * 2
	print(deliveryTime)
	local text =  __('预计配送时间：')
	local str = self:ChangeTimeFormat(deliveryTime)
	self.time = deliveryTime
	display.reloadRichLabel(self.numLabel, {c = {
		fontWithColor(6,{text = text, fontSize = 20}),
		fontWithColor(10,{text = str ,fontSize = 20 })}})
end
function StartDeliveryOrderView:runActionFadeIn()
	local  layotActionTable = {self.rightlayout,self.diningCarLayout,self.teamLayout}
	for i = 1, #layotActionTable do
		layotActionTable[i]:setOpacity(0)

		local seqTable = {}
		if i==1 then
			layotActionTable[i]:setPosition(cc.p(display.cx/2*3 - 50,display.cy))
			seqTable[#seqTable+1] = cc.Spawn:create(cc.FadeIn:create(0.3))
		else
			seqTable[#seqTable+1] =  cc.DelayTime:create((i-1)*0.3)
			seqTable[#seqTable+1] =  cc.FadeIn:create(0.25)
		end
		local seqAction = cc.Sequence:create(seqTable)
		layotActionTable[i]:runAction(seqAction)
	end
end
--- 订单缩减的外卖时间
function StartDeliveryOrderView:GeRestaurantReduceTakeawayTime()
	local reduces = {
		[tostring( RestaurantSkill.SKILL_TYPE_TAKEAWAY_DELIVERY_SPEED_UP_CONSTANT)]  = 0 ,
		[tostring( RestaurantSkill.SKILL_TYPE_TAKEAWAY_DELIVERY_SPEED_UP_PERCENT)]  = 0 ,
	}
	for kk , vv in pairs(self.businessData or {}) do
		for k , v in pairs(vv) do
			if v.allEffectNum   then
				if checkint(v.allEffectNum.targetType ) == RestaurantSkill.SKILL_TYPE_TAKEAWAY_DELIVERY_SPEED_UP_PERCENT then
					if v.allEffectNum.effectNum then
						-- 这里面厨力点不为整数的时候 四舍五入
						reduces[tostring(RestaurantSkill.SKILL_TYPE_TAKEAWAY_DELIVERY_SPEED_UP_PERCENT)] = tonumber(v.allEffectNum.effectNum[1])
					end
				elseif checkint(v.allEffectNum.targetType)  == RestaurantSkill.SKILL_TYPE_TAKEAWAY_DELIVERY_SPEED_UP_CONSTANT then
					if v.allEffectNum.effectNum then

						reduces[tostring( RestaurantSkill.SKILL_TYPE_TAKEAWAY_DELIVERY_SPEED_UP_CONSTANT)] = tonumber(v.allEffectNum.effectNum[1])
					end
				end
			end
		end
	end
	return reduces
end

function StartDeliveryOrderView:judageOrderStatus()
	-- body
	if  self.status == 2 and self.time <  checkint(self.dataOrder.deliveryTime)/2 then
		self.status = 3
	end
end
--[[
	更新外卖车界面逻辑
]]


function StartDeliveryOrderView:UpdateDingCarInfo(index)
	if index > #self.dingCarTable then
		return
	end
	local data = CommonUtils.GetConfigAllMess('diningCarLevelUp', 'takeaway')
	if self.dingCarTable[index] then
		local levelCar  = self.dingCarTable[index].level
		local speedNum  = checkint(checktable(data[tostring(levelCar)]).speed)
		local deliverySize = self.deliveryStatusBg:getParent():getContentSize()

		local setPosAndOpacity = function (node,pos)
			node:stopAllActions()
			node:setOpacity(0)
			node:setPosition(pos)
		end
		--setPosAndOpacity(self.maxExpLabel,cc.p(deliverySize.width,self.maxExpLabel:getPositionY()))
		setPosAndOpacity(self.dingCarLevel,cc.p(deliverySize.width/4*5,self.dingCarLevel:getPositionY()))
		setPosAndOpacity(self.speedLabel,cc.p(deliverySize.width/4*5,self.speedLabel:getPositionY()))
		display.reloadRichLabel(self.speedLabel , {c = {
			{text = __('减少配送时间:'), fontSize = 20 , color = '#ffffff'},
			{text = string.format(__('%d秒'), speedNum *2) , fontSize = 20, color ='#ffd852' }

		}})

		--display.reloadRichLabel(self.maxExpLabel , {c = {
		--    {text = __('经验:'), fontSize = 20 , color = '#ffffff'},
		--    {text ="+" .. maxExpNum , fontSize = 20, color ='#ffd852' }
		--
		--}})
		local Num = 0
		local returnAction =  function()
			local spawnTable = {}
			spawnTable[#spawnTable+1] = cc.EaseBackOut:create(cc.MoveBy:create(0.5,cc.p(-deliverySize.width*3/4,0)))
			spawnTable[#spawnTable+1] = cc.FadeIn:create(0.5)
			local spawnAction = cc.Spawn:create(spawnTable)
			local  seqAction = cc.Sequence:create({cc.DelayTime:create(Num*0.15),spawnAction})
			Num = Num + 1
			return seqAction
		end
		self.dingCarLevel:runAction(returnAction())
		self.speedLabel:runAction(returnAction())
		--self.maxExpLabel:runAction(returnAction())

		self.dingCarLevel:setString(string.format(__('%d级外卖外卖车'),levelCar))
		if self.dingCarTable[index].status == WaitingShipping then
			self.deliveryStatusBg:setVisible(false)
		else
			self.deliveryStatusBg:setVisible(true)
		end
		if 1 == #self.dingCarTable then
			self.preBtn:setVisible(false)
			self.nextBtn:setVisible(false)
		end
	end
end
--[[
	更新圆圈图标
]]
function StartDeliveryOrderView:updateCircleTexture(inder)
	local Num =  self.selectIndexCar %3
	if Num == 0  then
		Num = 3
	end
	for i = 1 ,3 do
		self.circleTable[i]:setTexture(_res("ui/home/takeaway/takeout_ico_spot_default.png"))
	end
	self.circleTable[Num]:setTexture(_res("ui/home/takeaway/takeout_ico_spot_selected.png"))
	-- body
end
--[[
	外卖车切换事件
]]
function StartDeliveryOrderView:ChangeDiningCarBtnCallback(sender)
	local tag  = sender:getTag()
	if tag == PreDingCar then
		self.selectIndexCar = self.selectIndexCar -1
		if self.selectIndexCar <= 0 then
			self.selectIndexCar = #self.dingCarTable
		end
	elseif  tag == NextDingCar then
		self.selectIndexCar = self.selectIndexCar +1
		if self.selectIndexCar > #self.dingCarTable  then
			self.selectIndexCar = 1
		end
	end
	self:updateCircleTexture(self.selectIndexCar)
	self:UpdateDingCarInfo(self.selectIndexCar)
	self:UpdateDeliveryTime()
end
function StartDeliveryOrderView:createRewardLayout(data ,Additional ) -- 用于创建下面额奖励获得
	local data = clone(data)
	local treasureType =   self.treasureType    -- 0 的时候是一般的goods 1 为金宝箱 2.为银宝箱
	local layoutSize = cc.size(537,200)
	local layout = display.newLayer(0, 0 ,{ size = layoutSize ,ap = display.CENTER})
	--CLayout:create(layoutSize)
	if treasureType == 0 then
		local rewardImageBg =  display.newImageView(_res("ui/common/common_title_5.png"),layoutSize.width/2, layoutSize.height/2 + 80 )
		layout:addChild(rewardImageBg)
		local rewardImageBgSize = rewardImageBg:getContentSize()
		local text = Additional and __('急速响应奖励') or __('基础奖励')
		local rewardTextLabel   = display.newLabel(rewardImageBgSize.width/2, rewardImageBgSize.height/2  ,{text = text, fontSize = fontWithColor('8').fontSize, color = fontWithColor('8').color})
		rewardImageBg:addChild(rewardTextLabel)
		rewardImageBg:setCascadeOpacityEnabled(true)
		rewardTextLabel:setCascadeOpacityEnabled(true)

		local topGoods  = {}
		for i = #data , 1 ,-1 do
			local v = clone(data[i])

			if v.goodsId == COOK_ID then
				table.insert( topGoods, #topGoods+1 , v)
				table.remove(data,i)
			elseif  v.goodsId == GOLD_ID then
				table.insert( topGoods, #topGoods+1 , v)
				table.remove(data,i)
			end
		end

		local width = 105
		local layoutContentSize = cc.size ((#data > 1 and #data or 1 )*width  ,200)
		local layoutContent = CLayout:create(cc.size(layoutContentSize.width,layoutContentSize.height))
		layout:addChild(layoutContent)
		if self.orderType == PrivateOrder then
			local offwidth = 140
			local mainExp = checkint(self.dataOrder.mainExp)
			local popularity = checkint(self.dataOrder.completePopularity)
			if mainExp  > 0 then
				table.insert(topGoods,#topGoods+1 ,{goodsId = EXP_ID , num = mainExp})
			end
			if  popularity > 0  then
				table.insert(topGoods,#topGoods+1 ,{goodsId = POPULARITY_ID , num = popularity})
			end
			local topWidth  = (#topGoods) * offwidth
			local topContentSize = cc.size(topWidth, 40)
			local topLayout = display.newLayer(0, 0 ,{ size = topContentSize , ap = display.CENTER})
			topLayout:setAnchorPoint(display.CENTER)
			topLayout:setPosition(cc.p(layoutSize.width/2, layoutContentSize.height -70))
			layout:addChild(topLayout)
			---@type TakeawayManager
			local takeawayMgr = AppFacade.GetInstance():GetManager("TakeawayManager")
			local activityData = takeawayMgr:GetTakeAwayGoodData()
			local  chestData = clone(self.dataOrder.chest)
			for i = 1, #activityData do
				activityData[i].isActivity = true
				chestData[#chestData+1]  = activityData[i]
			end
			local count = table.nums(chestData)
			local chestWidth  = 120
			local chestSize = cc.size(chestWidth * count ,80)
			local chestLayout =CLayout:create(chestSize)
			for k ,  v in pairs(chestData) do
				if v then
					local data =  v
					local  showAmount = true
					if data.isActivity then
						showAmount = false
					end
					local goodNode = require('common.GoodNode').new({id = data.goodsId, amount = data.num, showAmount = showAmount})
					display.commonUIParams(goodNode, {animate = false, cb = function (sender)
						uiMgr:AddDialog("common.GainPopup", {goodId =data.goodsId})
					end})
					goodNode:setAnchorPoint(cc.p(0.5,0.5))
					goodNode:setScale(0.9)
					goodNode:setPosition(cc.p((k- 0.5 )*chestWidth ,chestSize.height/2 - 5 ))
					chestLayout:addChild(goodNode)
				end
			end
			chestLayout:setPosition(cc.p(layoutSize.width/2 , layoutSize.height/2 -50 ) )
			layout:addChild(chestLayout)
			for i  =1 ,#topGoods  do
				local data = clone(topGoods[i])
				local baseNum =  data.num
				local iconPath = CommonUtils.GetGoodsIconPathById(data.goodsId)
				local rewardsNum = display.newImageView(_res('ui/home/takeaway/takeout_bg_reward_number.png'),(i- 0.5)* offwidth,topContentSize.height/2 , { enable = true})
				local rewardsNumSize = rewardsNum:getContentSize()
				if checkint( data.goodsId) == COOK_ID  then
					--- 厨力点的计算等于 厨力点 = 基本奖励 + 基本奖励 * 主厨技能的百分比加成 + 主厨的基本加成 + 菜谱加成
					rewardsNum:setTag(COOK_ID)
					rewardsNum:setOnClickScriptHandler(handler(self, self.UpdateBounslayout))
					-- 主厨技能加成
					for kk , vv in pairs(self.businessData or {}) do
						for k , v in pairs(vv) do
							if v.allEffectNum   then
								if checkint(v.allEffectNum.targetType ) == RestaurantSkill.SKILL_TYPE_TAKEAWAY_COOKING_POINT_PERCENT then
									if v.allEffectNum.effectNum then
										-- 这里面厨力点不为整数的时候 四舍五入
										self.assistantCookingPoint =  math.floor(baseNum * tonumber(v.allEffectNum.effectNum[1]) + 0.5)

									end
								elseif checkint(v.allEffectNum.targetType)  == RestaurantSkill.SKILL_TYPE_TAKEAWAY_COOKING_POINT_CONSTANT then
									if v.allEffectNum.effectNum then
										dump(v.allEffectNum.effectNum)
										self.assistantCookingPoint = self.assistantCookingPoint + tonumber(v.allEffectNum.effectNum[1])
									end
								end
							end
						end
					end
					--- 菜谱加成
					local foodData =  self.dataOrder.foods
					for k , v in pairs( foodData ) do
						local recipeData = app.cookingMgr:GetFoodIdByRecipeData(k)
						local value = app.cookingMgr:GetRecipeIdByRewardCookingNum(recipeData.recipeId)
						self.recipeCookingPoint = self.recipeCookingPoint + checkint(value)
					end
					data.num = self.recipeCookingPoint + self.assistantCookingPoint + baseNum
					self.baseCookingpoint =  baseNum
				elseif 	checkint( data.goodsId) == POPULARITY_ID then
				end

				local rcihLabel = display.newRichLabel(0, 0, { r = true , c = {
					{ img = iconPath  ,scale = 0.2} ,
					{ color = fontWithColor("10").color, fontSize = fontWithColor('10').fontSize,text = " " .. data.num , ap = display.CENTER}

				}})
				self.recipeUpgradeRefreshUI = {[tostring(COOK_ID)] = rcihLabel }
				rcihLabel:setPosition(cc.p(rewardsNumSize.width/2 , rewardsNumSize.height/2))
				rewardsNum:addChild(rcihLabel)
				topLayout:addChild(rewardsNum)
				rcihLabel:setCascadeOpacityEnabled(true)
				rewardsNum:setCascadeOpacityEnabled(true)
			end
			layoutContent:setPosition(layoutSize.width/2,layoutSize.height/2 - 40)
		elseif self.orderType == PublicOrder then
			local width = 90
			local height = 40
			local topWidth  = 2 * width
			if not  Additional then
				local mainExp = checkint(self.dataOrder.mainExp)
				local popularity = checkint(self.dataOrder.completePopularity)
				if mainExp > 0 then
					table.insert(topGoods,#topGoods+1 ,{goodsId = EXP_ID , num = mainExp})
				end
				if popularity > 0 then
					table.insert(topGoods,#topGoods+1 ,{goodsId = POPULARITY_ID , num = popularity})
				end
			end
			local topContentSize = cc.size(topWidth,height *math.ceil((#topGoods)/2))
			local topLayout = CLayout:create(topContentSize)
			topLayout:setAnchorPoint(display.CENTER)
			topLayout:setPosition(cc.p(layoutSize.width/2, layoutContentSize.height - 80))
			layout:addChild(topLayout)

			for i  =1 ,#topGoods  do
				local data = topGoods[i]
				local baseNum =  data.num
				local iconPath = CommonUtils.GetGoodsIconPathById(data.goodsId)
				local num = math.ceil(#topGoods/2 ) -   math.ceil(i/2) +1
				local mod = i % 2
				if mod %2 == 0 then
					mod = 2
					num = math.ceil(#topGoods/2 ) -   math.ceil(i/2) +1
				end
				--local icon = display.newImageView(iconPath,(mod - 0.5)* width - 25,(num -0.5)*height )
				local layoutSize = cc.size(90, 40)
				local layout = display.newLayer((mod - 0.5)*width,(num -0.5)*height , { ap = display.CENTER , size = layoutSize , color = cc.c4b(0,0,0,0 )})

				if checkint( data.goodsId) == COOK_ID  then
					--- 厨力点的计算等于 厨力点 = 基本奖励 + 基本奖励 * 主厨技能的百分比加成 + 主厨的基本加成 + 菜谱加成
					layout:setTag(COOK_ID)
					layout:setTouchEnabled(true)
					layout:setOnClickScriptHandler(handler(self, self.UpdateBounslayout))
					-- 主厨技能加成
					for kk , vv in pairs(self.businessData or {}) do
						for k , v in pairs(vv) do
							if v.allEffectNum   then
								if checkint(v.allEffectNum.targetType ) == RestaurantSkill.SKILL_TYPE_TAKEAWAY_COOKING_POINT_PERCENT then
									if v.allEffectNum.effectNum then
										-- 这里面厨力点不为整数的时候 四舍五入
										self.assistantCookingPoint =  math.floor(baseNum * tonumber(v.allEffectNum.effectNum[1]) + 0.5)

									end
								elseif checkint(v.allEffectNum.targetType)  == RestaurantSkill.SKILL_TYPE_TAKEAWAY_COOKING_POINT_CONSTANT then
									if v.allEffectNum.effectNum then
										self.assistantCookingPoint = self.assistantCookingPoint + tonumber(v.allEffectNum.effectNum[1])
									end
								end
							end
						end
					end
					local foodData =  self.dataOrder.foods
					for k , v in pairs( foodData ) do
						local recipeData = app.cookingMgr:GetFoodIdByRecipeData(k)
						local value = app.cookingMgr:GetRecipeIdByRewardCookingNum(recipeData.recipeId)
						self.recipeCookingPoint = self.recipeCookingPoint + checkint(value)
					end
					data.num = self.recipeCookingPoint + self.assistantCookingPoint + baseNum
					self.baseCookingpoint =  baseNum
				end
				--icon:setScale(0.2)
				local richLabel = display.newRichLabel(layoutSize.width/2 , layoutSize.height/2 , { r = true ,
					c = {
						{ img = iconPath , scale = 0.2 } ,
						fontWithColor('10', { text = data.num})
					}
				} )
				layout:addChild(richLabel)
				topLayout:addChild(layout)
				--local goodTextNum = display.newLabel((mod - 0.5)* width - 10 ,(num -0.5)*height,{ color = fontWithColor("10").color, fontSize = fontWithColor('10').fontSize,text = data.num, ap = display.LEFT_CENTER})
				--topLayout:addChild(goodTextNum)
			end
			layoutContent:setPosition(layoutSize.width/2,layoutSize.height/2 - 70)
			---@type TakeawayManager
			local takeawayMgr = AppFacade.GetInstance():GetManager("TakeawayManager")
			local activityData = takeawayMgr:GetTakeAwayGoodData()
			local data = clone(data)
            local hegitUp = 0
            local hegitDown = 0
            if not  Additional then
                for i = 1, #activityData do
                    hegitUp = 70
                    hegitDown = -120
                    activityData[i].isActivity = true
                    data[#data+1] = activityData[i]
                end
                topLayout:setPosition(cc.p(layoutSize.width/2, layoutContentSize.height - 80 + hegitDown))
            end
			local width = 120
			local chestSize = cc.size(width*(#data),200)
			local chestLayout = CLayout:create(chestSize)
			layoutContentSize = cc.size(chestSize.width, layoutContentSize.height)
			layoutContent:setContentSize(layoutContentSize)
			chestLayout:setPosition(cc.p(layoutContentSize.width/2 , layoutContentSize.height /2  + 20))
			for  i =1, #data do
				local data = data[i]
				local  showAmount = true
				if data.isActivity then
					showAmount = false
				end
				local goodNode = require('common.GoodNode').new({id = data.goodsId, amount = data.num, showAmount = showAmount})
				display.commonUIParams(goodNode, {animate = false, cb = function (sender)
					uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = data.goodsId, type = 1})
				end})
				goodNode:setScale(0.9)
				if Additional then
					goodNode:setPosition(cc.p((i-0.5)*width ,chestSize.height/2 + 40 ))
				else
					goodNode:setPosition(cc.p((i-0.5)*width ,chestSize.height/2 - 30  + hegitUp))
				end
				chestLayout:addChild(goodNode)

			end

			layoutContent:addChild(chestLayout)
			if Additional then
				layoutContent:setTag(888)
			end
		end

	end
	return layout
end

function StartDeliveryOrderView:createBonusLayout()
	local layoutSize = cc.size(265, 195)
	local layout =  display.newLayer(0, 0	, { size = layoutSize , ap = display.CENTER})
	local bgImage = display.newImageView(_res('ui/common/common_bg_tips_common.png'), layoutSize.width/2, layoutSize.height/2, {scale9 = true , size = layoutSize })
	layout:addChild(bgImage)
	local tips = display.newImageView(	_res('ui/common/common_bg_tips_horn.png') , layoutSize.width/2 , layoutSize.height-2)
	layout:addChild(tips)
	local listView = CListView:create(cc.size(layoutSize.width -25 , layoutSize.height -50) )
	listView:setDirection(eScrollViewDirectionVertical)
	listView:setPosition(cc.p(layoutSize.width/2, layoutSize.height/2 -20  ))
	layout:addChild(listView)
	listView:setAnchorPoint(display.CENTER)
	listView:setName("listView")
	layout:setName("bounsLayout")
	layout:setAnchorPoint(display.CENTER_TOP)
	return layout
end

function StartDeliveryOrderView:UpdateBounslayout(sender)
	local tag  = sender:getTag()
	local fScale = sender:getScaleX()
	sender:setTouchEnabled(false)
	transition.execute(sender,cc.Sequence:create(
	cc.EaseOut:create(cc.ScaleTo:create(0.03, 0.92*fScale, 0.92*fScale), 0.03),
	cc.EaseOut:create(cc.ScaleTo:create(0.03, 1*fScale, 1*fScale), 0.03),
	cc.CallFunc:create(function()
		sender:setTouchEnabled(true)
	end)
	))
	local bounsLayout = self:getChildByName("bounsLayout")
	local listView = nil
	if bounsLayout and ( not  tolua.isnull(bounsLayout)) then
		listView = bounsLayout:getChildByName("listView")
	else
		bounsLayout =  self:createBonusLayout()
		self:addChild(bounsLayout,10)
		listView = bounsLayout:getChildByName("listView")
	end
	local pos = cc.p(sender:getPosition())
	local parentNode = sender:getParent()
	pos = parentNode:convertToWorldSpace(pos)
	if not  self.preTag  then
		bounsLayout:setVisible(true)
	else
		if self.preTag == tag then
			local isVisible = bounsLayout:isVisible()
			bounsLayout:setVisible(not isVisible)
			bounsLayout:setPosition(cc.p(pos.x , pos.y -20) )
			return
		else
			bounsLayout:setVisible(true)
		end
	end
	self.preTag = tag
	bounsLayout:setPosition(cc.p(pos.x , pos.y -20) )
	local contentWidth = 240
	local offsetRight = 0
	listView:removeAllNodes()
	local lineHeight = 35
	if tag == COOK_ID then
		local baseNum  = self.baseCookingpoint
		local iconPath = CommonUtils.GetGoodsIconPathById(COOK_ID)
		for kk , vv in pairs(self.businessData or {}) do
			for k , v in pairs(vv) do
				if v.allEffectNum then
					if checkint(v.allEffectNum.targetType ) == RestaurantSkill.SKILL_TYPE_TAKEAWAY_COOKING_POINT_PERCENT then
						if v.allEffectNum.effectNum then
							-- 这里面厨力点不为整数的时候 四舍五入
							local num  =   math.floor(baseNum * tonumber(v.allEffectNum.effectNum[1]) + 0.5)
							---@type CardManager
							local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
							local cardData = CardUtils.GetCardConfig(tostring(v.cardId))
							local cardName = cardData.name
							local assistantSkillData = CommonUtils.GetConfig('business', 'assistantSkill', v.skillId)
							local skillName = assistantSkillData.name
							local richLabel = display.newRichLabel(0,0,{ r = true , c = {
								fontWithColor('16', {text = cardName .. "  " }) ,
								fontWithColor('16', {text = skillName  }) ,
								fontWithColor('10', { text =  " +" .. num }),
								{ img = iconPath , scale = 0.2  }

							}})
							local richSize = richLabel:getContentSize()
							local contentSize  = cc.size(contentWidth, lineHeight)
							local contentLayout = display.newLayer(0,0,{size =  contentSize  })
							local image = display.newImageView(_res("ui/home/takeaway/takeout_line.png") ,contentSize.width/2 , contentSize.height )
							contentLayout:addChild(image)
							richLabel:setAnchorPoint(display.RIGHT_CENTER)
							local scaleNum  = richSize.width > contentSize.width and (  contentSize.width   / richSize.width) or   1
							richLabel:setScale(scaleNum)
							richLabel:setPosition(cc.p(contentSize.width -offsetRight ,contentSize.height/2))
							contentLayout:addChild(richLabel)
							listView:insertNodeAtLast(contentLayout)
						end
					elseif checkint(v.allEffectNum.targetType)  == RestaurantSkill.SKILL_TYPE_TAKEAWAY_COOKING_POINT_CONSTANT then
						if v.allEffectNum.effectNum then
							local num  =  tonumber(v.allEffectNum.effectNum[1])
							local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
							local cardData = CardUtils.GetCardConfig(tostring(v.cardId))
							local cardName = cardData.name
							local assistantSkillData = CommonUtils.GetConfig('business', 'assistantSkill', v.skillId)
							local skillName = assistantSkillData.name
							local richLabel = display.newRichLabel(0,0,{ r = true , c = {
								fontWithColor('16', {text = cardName .. "  " }) ,
								fontWithColor('16', {text = skillName  }) ,
								fontWithColor('10', { text =  " +" .. num }),
								{ img = iconPath , scale = 0.2  }
							}})
							local richSize = recichLabel:getContentSize()
							local contentSize  = cc.size(contentWidth,lineHeight)
							local contentLayout = display.newLayer(0,0,{size =  contentSize })
							local image = display.newImageView(_res("ui/home/takeaway/takeout_line.png") ,contentSize.width/2 , contentSize.height )
							contentLayout:addChild(image)
							richLabel:setAnchorPoint(display.RIGHT_CENTER)
							richLabel:setPosition(cc.p(contentSize.width -offsetRight,contentSize.height/2))
							local scaleNum  = richSize.width > contentSize.width and (  contentSize.width   / richSize.width) or   1
							richLabel:setScale(scaleNum)
							contentLayout:addChild(richLabel)
							listView:insertNodeAtLast(contentLayout)
						end
					end
				end
			end
		end
		for k ,v in  pairs(self.dataOrder.foods) do
			local recipeOneData = app.cookingMgr:GetFoodIdByRecipeData(k)
			local cookingvalue = app.cookingMgr:GetRecipeIdByRewardCookingNum(recipeOneData.recipeId)
			if checkint(cookingvalue) > 0 then
				local foodName = CommonUtils.GetConfig('goods'	, 'goods' , k).name
				local gradeId = recipeOneData.gradeId
				local gradePath =  _res(string.format('ui/home/kitchen/cooking_grade_ico_%d.png', checkint(gradeId) or 1))
				local richLabel = display.newRichLabel(0,0,{ r = true , c = {
					fontWithColor('16', {text = foodName .. "  " }) ,
					{ img = gradePath , scale = 0.5  },
					fontWithColor('10', { text =  " +" .. cookingvalue }),
					{ img = iconPath , scale = 0.2  }
				}})
				local richSize = richLabel:getContentSize()
				local contentSize  = cc.size(contentWidth, lineHeight)
				local contentLayout = display.newLayer(0,0,{size =  contentSize })
				local image = display.newImageView(_res("ui/home/takeaway/takeout_line.png") ,contentSize.width/2 , contentSize.height )
				contentLayout:addChild(image)
				richLabel:setAnchorPoint(display.RIGHT_CENTER)
				richLabel:setPosition(cc.p(contentSize.width -offsetRight ,contentSize.height/2))
				contentLayout:addChild(richLabel)
				listView:insertNodeAtLast(contentLayout)
			end
		end

	elseif tag == POPULARITY_ID then

	end
	local name =  CommonUtils.GetConfig('goods', 'goods' , tag ).name  or ''
	local tableNodes = listView:getNodes()
	if table.nums(tableNodes) > 0  then
		local bounsSzie =   bounsLayout:getContentSize()
		local label = display.newLabel(bounsSzie.width/2 , bounsSzie .height - 40 ,fontWithColor( '6', { ap = display.CENTER_BOTTOM, text = string.format(__('%s加成效果'), name)}))
		bounsLayout:addChild(label)
		listView:reloadData()
	else
		local listSize = listView:getContentSize()
		local contentLayout = display.newLayer(listSize.width /2 , listSize.height /2 , { size = listSize })
		local label = display.newLabel(listSize.width/2 , listSize .height/2+10,fontWithColor( '6', { ap = display.CENTER_BOTTOM, text =  string.format(__('暂无%s加成效果') , name)}))
		contentLayout:addChild(label)
		listView:insertNodeAtLast(contentLayout)
		listView:reloadData()
	end

end

-- 更新layout
function StartDeliveryOrderView:updateNeedGoodLayout()
	if self.foodData  then
		local posX =  self.foodData.goodLayout:getPositionX()
		local posY =  self.foodData.goodLayout:getPositionY()
		self.foodData.goodLayout:removeFromParent()
		local goodNode = self:needGood(self.dataOrder)
		goodNode:setScale(0.85)
		goodNode:setPosition(cc.p(posX , posY))
		self.foodData.foodLayout:addChild(goodNode)
		self.foodData.goodLayout = goodNode
		goodNode:setVisible(true)
	end
end
function StartDeliveryOrderView:needGood(datas) -- 需要的材料集中适配的东西集中适配
	self.foodEnough = true
	if not datas then
		return CLayout:create(cc.size(100,100))
	end
	local distanceWidth = 140

	local reqdata = {} -- 加工组合数据
	for k ,v in pairs (datas.foods) do
		table.insert(reqdata,#reqdata+1,{})
		reqdata[#reqdata].goodsId = k
		reqdata[#reqdata].num = v
	end
	local datas = reqdata
	local count =  #datas
	local needSize = cc.size(distanceWidth*(#datas),108)
	local layout = CLayout:create(needSize)

	for i =1 , #datas do
		local data = datas[i]
		local goodNode = require('common.GoodNode').new({id = data.goodsId, amount = data.num, showAmount = false})
		display.commonUIParams(goodNode, {animate = false, cb = function (sender)
			uiMgr:AddDialog("common.GainPopup", {goodId =data.goodsId})
			-- uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = data.goodsId, type = 1})
		end})
		-- goodNode:setVisible(false)
		goodNode:setAnchorPoint(cc.p(0.5,0.5))
		goodNode:setPosition(cc.p((i-0.5)*distanceWidth ,needSize.height/2))
		local fontNum = '6'
		if checkint(gameMgr:GetAmountByGoodId(data.goodsId)) < checkint(data.num) then
			self.foodEnough = false
			fontNum = '10'
		end
		local labelNum =display.newRichLabel((i-0.5)*distanceWidth,needSize.height/2 - 70,{ap = display.CENTER, c = {
			fontWithColor(fontNum,{text = tostring(checkint(gameMgr:GetAmountByGoodId(data.goodsId))) ..'/'}),
			fontWithColor(6,{text = tostring(data.num)})
		}})
		display.reloadRichLabel( labelNum,{ap = display.CENTER,c = {
			fontWithColor(fontNum,{text = tostring(checkint(gameMgr:GetAmountByGoodId(data.goodsId))) ..'/' , fontSize = 30}),
			fontWithColor(6,{text = tostring(data.num), fontSize = 30})}})
		labelNum:setPosition(cc.p((i-0.5)*distanceWidth,needSize.height/2 - 80))
		layout:addChild(goodNode)
		layout:addChild(labelNum)

	end
	return layout
end



function StartDeliveryOrderView:ChangeTimeFormat( remainSeconds )
	local hour   = math.floor(remainSeconds / 3600)
	local minute = math.floor((remainSeconds - hour*3600) / 60)
	local sec    = (remainSeconds - hour*3600 - minute*60)
	return string.format("%.2d:%.2d:%.2d", hour, minute, sec)
end

--==============================--
--desc:	更新宝箱和跑马灯信息
--time:2017-04-25 03:09:25
--return
--==============================--
function StartDeliveryOrderView:updateTestsureAndMarqueue(hasDelivery,playerListInfo)
	local count =  table.nums(playerListInfo)
	local playerListText = ""
	local blankStr = "      "
	local numCount = 2
	if count > 0 then
		for i = 1 , 4 do
			if i > count then
				playerListText =  playerListText .. playerListInfo[i%count == 0 and count or i%count ]
			else
				playerListText =  playerListText .. playerListInfo[i]
			end
			playerListText = playerListText ..__('已抢单发车').. blankStr
		end
		numCount = 4
		local noticeImageSize =  self.noticeImage:getContentSize()
		local label = display.newLabel(noticeImageSize.width,noticeImageSize.height/2,fontWithColor(8,{ text = playerListText ,ap = display.LEFT_CENTER }))
		local labelContentSize =label:getContentSize()
		self.noticeImage:addChild(label)
		local second =  (noticeImageSize.width + labelContentSize.width)/500
		local callBack2 = nil
		local callback = function ()
			if numCount < count then
				startNum = numCount + 1
				playerListText = ""
				endNum  =(numCount + 4) < count and (numCount + 4) or count
				numCount = (numCount + 4) < count and (numCount + 4) or 0
				for i = startNum , endNum do
					playerListText =  playerListText .. playerListInfo[i]
					if i< count then
						playerListText = playerListText ..__('已抢单发车').. blankStr
					end
				end
				label:setString(playerListText)
				labelContentSize =label:getContentSize()
				second =  (noticeImageSize.width + labelContentSize.width)/500
			end
			label:setPosition(cc.p(noticeImageSize.width,noticeImageSize.height/2))
			callBack2()
		end
		callBack2 = function ( )
			label:runAction(
			cc.Sequence:create( cc.MoveTo:create( second , cc.p( -labelContentSize.width/2,noticeImageSize.height/2)) ,cc.CallFunc:create(callback))
			)
		end
		callBack2()
	end
	local  treasure =  self.treasureLayout:getChildByTag(888)
	local treasureLayoutSize = self.treasureLayout:getContentSize()
	if checkint(hasDelivery) < checkint(self.orderData.bestOrderNum) then
		if treasure then
			---- local treasurePos = treasure:getPosition()
			--local  boxLight = display.newImageView(_res('ui/home/takeaway/takeout_bg_box_light.png'),treasure:getPositionX(),treasure:getPositionY())
			--self.treasureLayout:addChild(boxLight,1)
			--local  boxLight = display.newImageView(_res('ui/home/takeaway/takeout_bg_box_light.png'),treasure:getPositionX(),treasure:getPositionY())
			--self.treasureLayout:addChild(boxLight,1)

		else
			local treasureSize = treasure:getContentSize()
			local tiltleImage  = display.newImageView(_res('ui/home/takeaway/takeout_bg_sellout.png'),treasureSize.width/2,treasureSize.height/2)
			local tiltleImageSize = tiltleImage:getContentSize()
			local tiltleLabel =  display.newLabel(tiltleImageSize.width/2,tiltleImageSize.height/2,{ text = _res('已抢完'),ap = display.CENTER ,fontSize = 22 , color = "#ffffff"})
			tiltleImage:addChild(tiltleLabel)
			treasure:addChild(tiltleImage)
			treasure:setColor(cc.c3b(80,80,80))
		end
		local remainImage = display.newImageView(_res('ui/home/takeaway/takeout_bg_places.png'),0,0,
					 {scale9 =  true ,
					  size = cc.size(150,39) ,capInsets = cc.rect(20,19,85,1)
					 })
		local remainImageSize =  remainImage:getContentSize()
		local remainText = display.newLabel(0,0,fontWithColor(8, { text = __('剩余名额'),ap = display.CENTER}))
		local remainTextSize = remainText:getContentSize()
		remainText:setPosition(cc.p(remainTextSize.width/2+20,remainImageSize.height/2))
		remainImage:setPosition(cc.p(remainImageSize.width/2 + remainTextSize.width  - 20,remainImageSize.height/2))
		local remainNumText = display.newRichLabel(remainImageSize.width/2,remainImageSize.height /2,{ap = display.CENTER, c = {
			fontWithColor(10,{text = tostring( checkint(self.orderData.bestOrderNum)  - checkint(hasDelivery )) ,  fontSize =  26}),
			fontWithColor(10,{text = tostring(checkint(self.orderData.bestOrderNum)), fontSize = 26 })
		}})
		remainImage:addChild(remainNumText)
		display.reloadRichLabel(remainNumText, {c = {
			fontWithColor(10,{text = tostring( checkint(self.orderData.bestOrderNum)  - checkint(hasDelivery )),fontSize =  26}),
			fontWithColor(8,{text = '/' .. tostring(checkint(self.orderData.bestOrderNum)), fontSize = 26 })
		}})
		local bottomLayout = CLayout:create(cc.size(remainImageSize.width + remainTextSize.width , remainImageSize.height))
		bottomLayout:setAnchorPoint(display.CENTER_TOP)
		bottomLayout:setPosition(treasureLayoutSize.width/2,0)
		bottomLayout:addChild(remainText)
		bottomLayout:addChild(remainImage)
		self.treasureLayout:addChild(bottomLayout)
	else
		local remainText = display.newLabel(treasureLayoutSize.width/2,0,fontWithColor(8, { text = __('急速响应奖励名额已抢完'),ap = display.CENTER}))
		self.treasureLayout:addChild(remainText)
	end
end
function StartDeliveryOrderView:UpdateUI()  -- 更新UI逻辑
	if not  self.orderType  then
		return
	end
	local data = self.dataOrder
	if checktable(ImageCollect[self.orderType]).bgImage then
		self.bgImageView:setTexture(checktable(ImageCollect[self.orderType]).bgImage)
	end
	self.titleLabel:setString(data.name)
	if self.titleImageView and checktable(ImageCollect[self.orderType]).title then
		self.titleImageView:setTexture(checktable(ImageCollect[self.orderType]).title)
	end
	if checkint(self.status)  ==  CompleteOrder and checkint(self.time) == 0  then
		self.sendMessage:getLabel():setString(__("领 取"))
		self.cancelBtn:setVisible(false)
		self.sendMessage:setPosition(cc.p(self.orderSize.width/2,55) )
	elseif ( checkint(self.status) ~=  WaitingShipping and checkint(self.time) > 0 ) then
		self:judageOrderStatus()
		self.sendMessage:getLabel():setString(__("撤销订单"))
		self.cancelBtn:setVisible(false)
		self.sendMessage:setPosition(cc.p(self.orderSize.width/2,55) )
	elseif checkint(self.status) ==  WaitingShipping then
		self.sendMessage:getLabel():setString(__("配 送"))
		if self.orderType == PublicOrder then
			self.cancelBtn:setVisible(false)
			self.sendMessage:setPosition(cc.p(self.orderSize.width/2,35) )
		end
	end
	for i = 1 , self.status-1 do -- 更新配送的状态需要改变得东西
		self.iconCompleteTable[i]:setTexture(MiddleLayoutTable.completeImage)
		self.progressLableTable[i]:setColor(ccc3FromInt(fontWithColor('10').color))
		self.ico_carTable[i]:setTexture(_res('ui/home/takeaway/takeout_ico_car.png'))
		if  i -1 > 0 then
			self.iconCompleteLineTable[i-1]:setTexture(MiddleLayoutTable.completeLineImage)
		end
	end
end
--[[
	这个方法是为了显示附加效果

]]

function StartDeliveryOrderView:InitTeamFormationPanel()
	local bgSize = self.viewData.centerBg:getContentSize()
	local centerBgPos = cc.p(self.viewData.centerBg:getPositionX(), self.viewData.centerBg:getPositionY())

	-- deliveryTeamText:setFontSize(30)
	-- 队伍序号
	local teamFormationLabelBg = display.newImageView(_res('ui/common/maps_fight_bg_title_s.png'), 0, 0)
	display.commonUIParams(teamFormationLabelBg, {po = cc.p(
	centerBgPos.x - bgSize.width * 0.5 + 5 + teamFormationLabelBg:getContentSize().width * 0.5,
	centerBgPos.y + bgSize.height * 0.5 - 5 - teamFormationLabelBg:getContentSize().height * 0.5 + 20 )})
	local teamFormationLabelBg =  display.newLayer(teamFormationLabelBg:getPositionX(),teamFormationLabelBg:getPositionY(),{ size = teamFormationLabelBg:getContentSize()  ,ap = display.CENTER})
	self.teamLayout:addChild(teamFormationLabelBg, 10)
	local deliveryTeamText = display.newLabel(centerBgPos.x ,
	centerBgPos.y , { ttf = true, font  = TTF_GAME_FONT, fontSize =  30 ,color = '#ffffff',text = __('队伍正在配送中') })
	self.teamLayout:addChild(deliveryTeamText ,60 )
	deliveryTeamText:setVisible(false)
	self.deliveryTeamText = deliveryTeamText
	local teamFormationLabel = display.newLabel(teamFormationLabelBg:getContentSize().width * 0.4, teamFormationLabelBg:getContentSize().height * 0.5,
	fontWithColor(3,{text = string.format(__('出战队伍:%d'), 0)}))
	teamFormationLabelBg:addChild(teamFormationLabel)
	teamFormationLabel:setCascadeOpacityEnabled(true)
	-- 队伍战斗力
	local teamBattlePointBg = display.newImageView(_res('ui/common/maps_fight_bg_sword1.png'), 0, 0)
	display.commonUIParams(teamBattlePointBg, {po = cc.p(
	centerBgPos.x + bgSize.width * 0.5 + 30 - teamBattlePointBg:getContentSize().width * 0.5 - 35,
	centerBgPos.y + bgSize.height * 0.5 - 5 - teamBattlePointBg:getContentSize().height * 0.5+ 40 )})
	self.teamLayout:addChild(teamBattlePointBg, 10)
	teamBattlePointBg:setCascadeOpacityEnabled(true)
	local teamBattlePointLabel = display.newLabel(teamBattlePointBg:getContentSize().width * 0.48, teamBattlePointBg:getContentSize().height * 0.5 - 10,
	fontWithColor(3,{text = string.format(__('队伍灵力:%d'), 0)}))
	teamBattlePointBg:addChild(teamBattlePointLabel)

	-- 调整队伍
	local changeTeamFormationBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_orange.png')})
	display.commonUIParams(changeTeamFormationBtn, {po = cc.p(
	centerBgPos.x + bgSize.width * 0.5 - changeTeamFormationBtn:getContentSize().width * 0.5,
	centerBgPos.y - bgSize.height * 0.5 - 6 - changeTeamFormationBtn:getContentSize().height * 0.5),
		cb = function (sender)
			AppFacade.GetInstance():DispatchObservers("SHOW_TEAM_FORMATION",self.selectedTeamIdx)
		end
	})
	display.commonLabelParams(changeTeamFormationBtn, fontWithColor(14,{text = __('调整')  }))
	self.teamLayout:addChild(changeTeamFormationBtn, 10)

	-- 前后按钮
	local preBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_switch.png'), cb = handler(self, self.ChangeTeamFormationBtnCallback)})
	preBtn:setScaleX(-1)
	display.commonUIParams(preBtn, {po = cc.p(
	centerBgPos.x - bgSize.width * 0.5 + preBtn:getContentSize().width * 0.5 - 45 -10 -10,
	centerBgPos.y - bgSize.height * 0.5 + 65)})
	self.teamLayout:addChild(preBtn, 20)
	preBtn:setTag(PreTeam)

	local nextBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_switch.png'), cb = handler(self, self.ChangeTeamFormationBtnCallback)})
	display.commonUIParams(nextBtn, {po = cc.p(
	centerBgPos.x + bgSize.width * 0.5 - nextBtn:getContentSize().width * 0.5 + 45 + 10 + 10,
	centerBgPos.y - bgSize.height * 0.5 + 65)})
	self.teamLayout:addChild(nextBtn, 20)
	nextBtn:setTag(NextTeam)

	self.viewData.teamFormationLabelBg = teamFormationLabelBg
	self.viewData.teamBattlePointBg = teamBattlePointBg
	self.viewData.teamFormationLabel = teamFormationLabel
	self.viewData.teamBattlePointLabel = teamBattlePointLabel
	self.viewData.changeTeamFormationBtn = changeTeamFormationBtn
	self.viewData.preTeamBtn = preBtn
	self.viewData.nextTeamBtn = nextBtn
	self.viewData.teamTabs = {}
	self.viewData.cardHeadNodes = {}
	self:getSelectDiningCarid()
	self:RefreshTeamFormation(gameMgr:GetUserInfo().teamFormation)
end

--[[
	获取到选中的外卖车
--]]
function StartDeliveryOrderView:getSelectDiningCarid ()

	for k , v in pairs(self.dingCarTable) do
		if v.status == WaitingShipping then
			self.selectIndexCar = k
			break
		end
	end

end

--==============================--
--desc:选择队伍的顺序是要经过三层的选择 首先是不在外卖中在 其次是不在他探索中 新鲜足够 上述条件没有满足 默认选择第一个队伍
--time:2017-06-30 06:26:52
--@return
--==============================--
function StartDeliveryOrderView:AutoSelectTeam()
	local have = nil
	if self.firstGo == 1 then
		self.firstGo = self.firstGo +  1
		--for k ,v in pairs(self.teamData) do
		local count =  0
		for i = #self.teamData ,1, -1 do
			k = i
			v = self.teamData[i]
			have = true
			count = table.nums(v.members)
			if gameMgr:isInDeliveryTeam(v.teamId)  then
				have = false
			end
			if table.nums(v.members) > 0 then
				-- local places =  gameMgr:GetCardPlace({id = v.members[1].id}) --判断当前的队伍是否是在探索中
				-- if places  and  (places[tostring(CARDPLACE.PLACE_EXPLORATION)] or places[tostring(CARDPLACE.PLACE_EXPLORE_SYSTEM)]) then
				-- 	have = false
				-- end
				if have then --判断当前探索队伍的活力值是否足够
					for kkk , cardIdData in pairs (v.members) do
						local vigour = checkint(app.restaurantMgr:GetMaxCardVigourById(cardIdData.id))
						local data = gameMgr:GetCardDataById(cardIdData.id)
						if checkint( data.vigour ) <  checkint(  checknumber(self.dataOrder.consumeVigour)  * vigour  / count) then
							have = false
							break
						end
					end
				end
			else
				have = false
			end
			if  have  then  -- 不在外卖队伍中并且
				self.selectedTeamIdx = checkint(v.teamId)
				break
			end
		end
	end

end
--[[
刷新中间队伍区域
@params data table 队伍信息
--]]
function StartDeliveryOrderView:RefreshTeamFormation(data)
	------------ 处理编队数据 ------------
	local teamData = {}
	for tNo, tData in ipairs(data) do
		teamData[tNo] = {teamId = tData.teamId, members = {}}
		for no, card in ipairs(tData.cards) do
			if card.id then
				local id = checkint(card.id)
				table.insert(teamData[tNo].members, {id = id, isLeader = id == checkint(tData.captainId)})
			end
		end
	end
	self.teamData = teamData
	self:AutoSelectTeam()
	self:RefreshTeamTabs()
end

--[[
刷新队伍周围信息
--]]
function StartDeliveryOrderView:RefreshTeamTabs()
	if table.nums(self.teamData) ~= table.nums(self.viewData.teamTabs) then
		for i,v in ipairs(self.viewData.teamTabs) do
			v:removeFromParent()
		end

		self.viewData.teamTabs = {}

		for i,v in ipairs(self.teamData) do
			local teamCircle = display.newNSprite(_res('ui/common/maps_fight_ico_round_default.png'), 0, 0)
			self.teamLayout:addChild(teamCircle, 5)
			table.insert(self.viewData.teamTabs, teamCircle)
		end

		display.setNodesToNodeOnCenter(self.viewData.centerBg, self.viewData.teamTabs, {spaceW = 5, y = -15})
	end

	self:RefreshTeamSelectedState(self.selectedTeamIdx or 1)
end

--[[
	获取团队的团队ID号
--]]
function StartDeliveryOrderView:getTeamSelectTeamId()
	local  index  = self.selectedTeamIdx or 1
	local teamData = self.teamData[index]
	if #(teamData.members) then
		return teamData.teamId
	end
	return {}
end
--[[
刷新队伍选中状态
--]]
function StartDeliveryOrderView:RefreshTeamSelectedState(index)
	-- 刷新选中状态
	local preCircle = self.viewData.teamTabs[self.selectedTeamIdx]
	if preCircle then
		preCircle:setTexture(_res('ui/common/maps_fight_ico_round_default.png'))
	end
	local curCircle = self.viewData.teamTabs[index]
	if curCircle then
		curCircle:setTexture(_res('ui/common/maps_fight_ico_round_select.png'))
	end

	if table.nums(self.teamData) <= 1 then
		self.viewData.preTeamBtn:setVisible(false)
		self.viewData.nextTeamBtn:setVisible(false)
	elseif index == 1 then
		self.viewData.preTeamBtn:setVisible(false)
		self.viewData.nextTeamBtn:setVisible(true)
	elseif index == table.nums(self.teamData) then
		self.viewData.preTeamBtn:setVisible(true)
		self.viewData.nextTeamBtn:setVisible(false)
	else
		self.viewData.preTeamBtn:setVisible(true)
		self.viewData.nextTeamBtn:setVisible(true)
	end

	self.selectedTeamIdx = index

	-- 刷新队伍信息

	self.viewData.teamFormationLabel:setString(string.format(__('队伍%d'), self.selectedTeamIdx))
	self:RefreshTeamInfo(self.teamData[checkint(self.selectedTeamIdx) ],gameMgr:isInDeliveryTeam(self.selectedTeamIdx))
	-- 刷新队伍的新鲜度扣除问题
	local teamData = self.teamData[self.selectedTeamIdx]
	if not  teamData or table.nums( teamData.members)  == 0  then
		self.viewData.teamInstructionsLabel:setVisible(false)
		self.viewData.everyTeamLabel:setVisible(false)
		return
	else
		self.viewData.teamInstructionsLabel:setVisible(true)
		self.viewData.everyTeamLabel:setVisible(true)
	end
	local count = table.nums( teamData.members)

	local percent =  checknumber( self.dataOrder.consumeVigour) * 100
	local memberConsume =  math.ceil( (percent / count ) *  10 ) / 10
	display.reloadRichLabel(self.viewData.teamInstructionsLabel , { c = {
		{text = string.format(__('本次配送 需消耗队伍总新鲜度%d%%')  ,percent ) , fontSize = 20, color = '#ffd852'}
	}})
	display.reloadRichLabel(self.viewData.everyTeamLabel , { c = {
		{text = string.format(__('队伍中现在有%d个飨灵,每个飨灵消耗%s%%新鲜度')  ,count,tostring(memberConsume)), fontSize = 20, color = '#ffd852'}
	}})
	CommonUtils.SetNodeScale(self.viewData.everyTeamLabel,{width = 550 })
end

--[[
刷新队伍信息
@params teamData table 队伍信息
--]]
function StartDeliveryOrderView:RefreshTeamInfo(teamData)
	-- 刷新头像
	for i,v in ipairs(self.viewData.cardHeadNodes) do
		v:removeFromParent()
	end
	self.deliveryTeamText:setVisible(false)
	local  isHave = gameMgr:isInDeliveryTeam(teamData.teamId)
	if isHave  then
		self.deliveryTeamText:setVisible(true)
		self.deliveryTeamText:setString(__('队伍正在配送中'))
	end
	-- local cardData = teamData.members
	-- if #cardData > 0 then
	-- 	local places =  gameMgr:GetCardPlace({id = cardData[1].id} )
	-- 	if places  and  (places[tostring(CARDPLACE.PLACE_EXPLORATION)] or places[tostring(CARDPLACE.PLACE_EXPLORE_SYSTEM)]) then
	-- 		isHave = true
	-- 		self.deliveryTeamText:setVisible(true)
	-- 		self.deliveryTeamText:setString(__('队伍正在探索中'))
	-- 	end
	-- end
	self.viewData.cardHeadNodes = {}

	local bgSize = self.viewData.centerBg:getContentSize()
	local centerBgPos = cc.p(self.viewData.centerBg:getPositionX(), self.viewData.centerBg:getPositionY())

	local totalBattlePoint = 0
	local teamMemberMax = 5
	local paddingX = 10
	local cellWidth = (bgSize.width - paddingX * 2) / teamMemberMax
	local scale = 0.625 * 0.8
	for i,v in ipairs(teamData.members) do
		local cardHeadNode = require('common.CardHeadNode').new({id = checkint(v.id), showActionState = false,isgrassColor = isHave })
		cardHeadNode:setScale(scale)
		cardHeadNode:setPosition(cc.p(
		(centerBgPos.x - bgSize.width * 0.5 + paddingX) + cellWidth * (i - 0.5),
		centerBgPos.y - bgSize.height * 0.5 + cardHeadNode:getContentSize().height * 0.5 * scale + 8))
		self.teamLayout:addChild(cardHeadNode, 15)
		table.insert(self.viewData.cardHeadNodes, cardHeadNode)

		-- 计算战斗力
		totalBattlePoint = totalBattlePoint + cardMgr.GetCardStaticBattlePointById(checkint(v.id))
	end
	self.teamBattlePoint =  totalBattlePoint
	-- 刷新战斗力
	self.viewData.teamBattlePointLabel:setString(string.format(__('队伍灵力:%d'), totalBattlePoint))

end
--[[
阵容前后按钮点击回调
1001 前
1002 后
--]]
function StartDeliveryOrderView:ChangeTeamFormationBtnCallback(sender)
	local tag = sender:getTag()
	if 1001 == tag then
		self:RefreshTeamSelectedState(math.max(1, self.selectedTeamIdx - 1))
	elseif 1002 == tag then
		self:RefreshTeamSelectedState(math.min(table.nums(self.teamData), self.selectedTeamIdx + 1))
	end
end
return StartDeliveryOrderView
