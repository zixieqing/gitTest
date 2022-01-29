--[[
订单页面界面view
--]]
local LargeAndOrdinaryOrder = class('LargeAndOrdinaryOrder', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.LargeAndOrdinaryOrder'
	node:enableNodeEvents()
	return node
end)
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local socket = require('socket')
local AdditionalTime = 150
local CompleteOrder = 4
local WaitingShipping = 1
local PublicOrder = 2  -- 公有订单
local PrivateOrder =1  -- 私有订单
local MiddleLayoutTable  = {
		completeImage =  _res("ui/home/takeaway/takeout_ico_complete.png"),
		noCompleteImage =  _res("ui/home/takeaway/takeout_ico_complete_notnulock.png") ,
		nocompleteLineImage = _res("ui/home/takeaway/takeout_line_complete_notnulock.png"),
		completeLineImage = _res("ui/home/takeaway/takeout_line_complete.png")
	}

local 	ImageCollect =  -- 图片背景的集合
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
local 	StatusTable =   -- 不同状态下订单的位置 以及小人是否可见 1. 未完成订单 2.表示完成订单
	 {
		{
			leftIsVisible = true ,
			rightIsVisible = true,
			leftPosition =  cc.p(display.cx/2,display.cy),
			rightPosition =  cc.p(display.cx/2*3,display.cy),
			sendOrPullText = __('配 送')
		},

		{
			leftIsVisible = false ,
			rightIsVisible = true,
			leftPosition =  cc.p(display.cx/2,display.cy),
			rightPosition =  cc.p(display.cx,display.cy),
			sendOrPullText = __('领 取')
		}
	}


function LargeAndOrdinaryOrder:ctor(param)

	self.orderType  = param.orderType   -- 订单类型  1.普通订单 2.超级订单
	self.orderId =  param.orderId  -- 订单的编号
	self.status  =  param.status   -- 外卖订单的状态
	-- self.status = 2
	self.takeawayId = param.takeawayId or 1
	if param.status == WaitingShipping   then
		self.orderSwithType = 1 --  以表示的是有效任务出现
	end
	self.foodEnough = true
	self.data = param.data
	self.time = param.time
	self.deliveryTime = param.deliveryTime or 0
	self.totalDeliverySeconds = param.totalDeliverySeconds
	self.startTime = socket.gettime()
	self.roleId =  param.roleId   --
	self.orderData = param.orderData
 	if self.status > 1 then
		self.businessData = app.restaurantMgr:GetAllAssistantBuff(3)
	end


	if not self.role then
		self.role =1
	end
	local dataOrder = {}   -- 此处赋值所学要的材料和id
	local str = nil
	if self.orderType == PrivateOrder then
		str = 'privateOrder'
	elseif self.orderType == PublicOrder then
		str = 'publicOrder'
	end
	local diningCarData = AppFacade.GetInstance():GetManager('TakeawayManager'):GetDatas().diningCar
	self.dingCarTable =    {}
	for k, v in ipairs(diningCarData) do
		if v.diningCarId then
			table.insert(self.dingCarTable,#self.dingCarTable+1, v)
		end
	end
	dataOrder =  CommonUtils.GetConfigAllMess(str,'takeaway') or {}
	-- CommonUtils.GetConfig('takeaway', str, self.orderId)
	dataOrder = dataOrder[tostring(self.takeawayId)] or {}
	self.dataOrder = dataOrder
	self.diaText = CommonUtils.GetConfigAllMess('role','takeaway')[tostring(self.roleId)]['descr']

	local orderSize = cc.size(563,631)  --右侧区域
	local rightlayout  = CLayout:create(orderSize)
	self.orderSize = orderSize
	self.rightlayout = rightlayout

	rightlayout:setPosition(StatusTable[1].rightPosition)
	self:addChild(rightlayout,2)
	-- 顶部的图片



	local guideBtn = CommonUtils.GetGuideBtn("takeout")
	guideBtn:setPosition(cc.p(orderSize.width  -50 , orderSize.height -35))
	rightlayout:addChild(guideBtn ,100)

	local bgImageView = display.newImageView(ImageCollect[self.orderType].bgImage, orderSize.width/2, orderSize.height/2)
	rightlayout:addChild(bgImageView)
	self.bgImageView = bgImageView
	local  swallowLayout = display.newLayer(orderSize.width/2, orderSize.height/2, {size = orderSize, ap = display.CENTER, color = cc.c4b(0,0,0,0), enable = true})
	rightlayout:addChild(swallowLayout)
	local offHeight = 10

	if self.orderType == PublicOrder then
		local titleImageView = display.newImageView(ImageCollect[self.orderType].title)
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
		if checkint(self.status)  >  1 then
			local robberyButton = display.newLayer(orderSize.width - 75 , orderSize.height -490   , { ap = display.CENTER , size = cc.size(100,100) , color =  cc.c4b( 0,0,0,0 ) , cb = function()
			AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = "HomeMediator"},
				{name = "RobberyDetailMediator" , params = { type =1 ,orderId =  self.orderId ,orderType = self.orderType }  })
				end   , enable = true })
			local robberyAvatar = sp.SkeletonAnimation:create("ui/home/carexplore/rob_ico_human.json", "ui/home/carexplore/rob_ico_human.atlas", 1.0)
			robberyAvatar:setPosition(cc.p( 40 , 0))
			robberyButton:addChild(robberyAvatar)
			rightlayout:addChild(robberyButton, 20)
			robberyAvatar:setToSetupPose()
			robberyAvatar:setAnimation(0, 'idle', true)
			robberyAvatar:setScale(1.2)
			self.robberyButton  = robberyButton
		end
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
						fontWithColor(6,{text =text , fontSize = 20 }),
						fontWithColor(10,{text = "00:00:00" , fontSize = 20})
					}})
			flowbg:addChild(numLabel)
			local callBack =  function ()
				self.time = self.time or 0
				if self.time <= 0 then
					numLabel:stopAllActions()
					return
				end
				local curTime = socket.gettime()
				self.time =  self.time - math.floor(curTime - self.startTime + 0.5 )
				self.startTime = curTime
				local str = self:ChangeTimeFormat(self.time)
				display.reloadRichLabel(numLabel, {c = {
			fontWithColor(6,{text = text}),
			fontWithColor(10,{text = str})}})
				CommonUtils.SetNodeScale(numLabel , {width  = 360})
			end
			if  self.orderType == PublicOrder  then
				text =  __('订单消失时间：')
				numLabel:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.DelayTime:create(1),cc.CallFunc:create(callBack))))
			else
				self.time = (self.deliveryTime+ AdditionalTime  ) * 2
				local reduceTime = 0
				local index  = nil
				for k , v in pairs(self.dingCarTable) do
					if v.status == WaitingShipping then
						 index = k
						break
					end
				end
				if index then
					if self.dingCarTable[index].speed  then
						reduceTime = self.dingCarTable[index].speed
					end
				end
				local str = self:ChangeTimeFormat(self.time)
				display.reloadRichLabel(numLabel, {c = {
					fontWithColor(6,{text = text , fontSize = 20 }),
					fontWithColor(10,{text = str})}})
				CommonUtils.SetNodeScale(numLabel , {width = 360})
			end

		end
		local foodbg = display.newImageView(_res('ui/home/takeaway/takeout_bg_font_name.png'),90,flowContentSize.height -30)
		local foodbgContentSize = foodbg:getContentSize()
		local foodLabel = display.newLabel(foodbgContentSize.width/2 , foodbgContentSize.height/2, fontWithColor(6,{reqW = 125 ,  text = __('客户点单')}))
		foodbg:addChild(foodLabel)
		flowbg:addChild(foodbg)
		flowbg:setCascadeOpacityEnabled(true)
		foodbg:setCascadeOpacityEnabled(true)
		foodLabel:setCascadeOpacityEnabled(true)
		local goodLayout =  self:needGood(dataOrder)

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
	---s
	local createOrderStatusDisplay = function ( )
		local middleSize = cc.size(537, 188)
		local middlebg = display.newLayer(0,0, { size = middleSize , ap = display.CENTER })

		local middleLayout = CLayout:create(middleSize)
		local middleLayoutPos = nil
		if PublicOrder == self.orderType then
			local  middlebgImage = display.newImageView(_res('ui/home/takeaway/takeout_flow_bg_1.png'),middleSize.width/2 , middleSize.height/2, { ap = display.CENTER , scale9 = true , size = middleSize  })
			middleLayout:addChild(middlebgImage)
			middleLayoutPos = cc.p(orderSize.width/2,orderSize.height - 70)

		elseif PrivateOrder == self.orderType then
			middleLayoutPos = cc.p(orderSize.width/2 - 10,orderSize.height - 70)
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
						fontWithColor(6,{text =text , fontSize = 20 }),
						fontWithColor(10,{text = "00:00:00", fontSize = 20})
					}})
			middleLayout:addChild(numLabel)

			local callBack =  function ()
				self.time = self.time or 0
				if self.time <= 0 then

					if self.status ~= WaitingShipping then
						self.status = CompleteOrder
						self:UpdateUI()
						numLabel:stopAllActions()
					else
						self.sendMessage:getLabel():setString(__('订单过期'))
					end
					return
				end

				local curTime = socket.gettime()
				self.time =  self.time -  math.floor(curTime - self.startTime + 0.5 )
				self.startTime = curTime
				local preStatus = self.status -- 记录当前的外卖订单状态
				self:judageOrderStatus()
				if self.status ~= preStatus then -- 判断外卖状态是否发生改变
					self:UpdateUI()
				end
				local str = self:ChangeTimeFormat(self.time)
				display.reloadRichLabel(numLabel, {c = {
			fontWithColor(6,{text = text, fontSize = 24}),
			fontWithColor(10,{text = str})}})
				CommonUtils.SetNodeScale(numLabel, {w = 360 })
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
			local progressLable =  display.newLabel((i-1) *linewidth + (i-0.5) * yuanWith,middleSize.height/2 - 75 ,  fontWithColor(6,{text = labelTextTable[i]}))
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
	--==============================--
	--desc:创建跑马灯 用于显示当前的
	--time:2017-04-27 10:55:55
	--return
	--==============================--
	local createMarQueue = function (  )
		local noticeImage = display.newImageView(_res('ui/home/takeaway/takeout_bg_notice.png'))
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
	self.createMarQueue = createMarQueue
	local data = checktable(dataOrder)
	if self.orderType == 1 then
		self:judageOrderStatus()
		if self.status > 1 then
			createOrderStatusDisplay()
		else
			self.foodData = createNeedFoods()
		end
		self.treasureType = 0
		if self.status  ==  WaitingShipping then
			local layout = self:createRewardLayout(dataOrder.rewards or {})
			layout:setPosition(orderSize.width/2 , 220 + offHeight )
			rightlayout:addChild(layout)
		end
	elseif  self.orderType ==  2 then
		local bgLight =  display.newImageView(_res('ui/home/takeaway/takeout_supertakeout_bg_light.png'),orderSize.width/2,orderSize.height/2)
		rightlayout:addChild(bgLight, -1)
		if self.status >  WaitingShipping then
			createOrderStatusDisplay()
		else
			self.foodData =  createNeedFoods()
			createMarQueue()
			self.treasureType = 0
			local layout =self:createRewardLayout(dataOrder.baseRewards or {})
			layout:setPosition(orderSize.width/4 , 220 )
			rightlayout:addChild(layout)
			local layout =self:createRewardLayout(dataOrder.submitRewards or {} , true )
			layout:setPosition(orderSize.width*3/4 , 220 )
			rightlayout:addChild(layout)
			self.treasureLayout = layout
		end

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
	self.eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 100))
	self.eaterLayer:setTouchEnabled(true)
	self.eaterLayer:setContentSize(display.size)
	self.eaterLayer:setAnchorPoint(cc.p(0.5, 1.0))
	self.eaterLayer:setPosition(cc.p(display.cx, display.height))
	self:addChild(self.eaterLayer, -1)
   	self.sendMessage = sendMessage
	self.cancelBtn = cancelBtn

   	if self.orderSwithType == 1 then  -- 当orderSwithType 等于1 显示左侧区域 否则不显示
		self.rightlayout:setVisible(false)
   		local roleNode = self:updatePeopleAndPeople()
		if self.orderType == PublicOrder then
			rightlayout:setPosition(cc.p(display.width/4*3-50,display.height/2))
		else
   			rightlayout:setPosition(cc.p(display.cx/2*3,display.cy))
		end
   		--左侧区域
   		local roleLayout =  roleNode
   		local roleSize = roleLayout:getContentSize()
   		self:addChild(roleLayout)
		local height  =  657 - 124
		if display.height/display.width > 0.65 then
			height  =  657
		end
   		local dialogue = display.newImageView(_res('arts/stage/ui/dialogue_bg_2.png'),0,  0, {ap = cc.p(0.5, 0.5)})
		local size = dialogue:getContentSize()
		dialogue:setScaleX(0.65)
        -- dialogue:setScaleY(1.5)
		dialogue:setPosition(cc.p(size.width*0.8/2 , size.height*0.8/2))
		local content = display.newLayer(128, 110, { size =cc.size(size.width*0.8, size.height*0.8)})
		content:addChild(dialogue)
		self:addChild(content,5)
		local cornuluView =  display.newImageView(_res('arts/stage/ui/dialogue_horn.png'),300,18, {ap = cc.p(0, 1)})
		dialogue:addChild(cornuluView)
		dialogue:setScaleY(-0.7)
		--self:addChild(dialogue, 5)
		--dialogue:setScale(0.7)
		local  dialogueText = display.newLabel(dialogue:getContentSize().width*0.8 / 2, dialogue:getContentSize().height*0.8 / 2,
			{text = self.diaText, fontSize = 20, color = '#5b3c25', w = 420})
		content:addChild(dialogueText)
		dialogueText:setVisible(false)
		self.roleLayout = roleLayout
		self.dialogue = dialogue
		self.dialogueText = dialogueText
		self:runActionWithPeople()
   	else
   		rightlayout:setPosition(cc.p(display.cx,display.cy))
   	end
   	rightlayout:setVisible(true)
    self:UpdateUI()

end
function LargeAndOrdinaryOrder:getSelectDiningCarid ()
	local selectCarId =  nil
	for k , v in pairs(self.dingCarTable) do
		if v.status == WaitingShipping then
			selectCarId  = k
			break
		end
	end
	return 	selectCarId
end
function LargeAndOrdinaryOrder:judageOrderStatus()
	-- body
	if  self.totalDeliverySeconds then
		if self.status == 2  and  self.totalDeliverySeconds  /2 > self.time and self.time ~= 0 then
			self.status = 3
		end

	end
end
function LargeAndOrdinaryOrder:updateNeedGoodLayout()
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

--- 显示被打劫后的奖励
--- 打劫的奖励
function LargeAndOrdinaryOrder:CreateRobberyedReward(data)
	local data = clone(data)
	local treasureType =   self.treasureType    -- 0 的时候是一般的goods 1 为金宝箱 2.为银宝箱

	local layoutSize
	if PublicOrder == self.orderType then
		layoutSize = cc.size(537,280)
	elseif  PrivateOrder == self.orderType then
		layoutSize = cc.size(537,200)
	end

	local layout = display.newLayer(0,0 ,{ ap = display.CENTER , size = layoutSize})
	--CLayout:create(layoutSize)
	--local rewardImageBg =  display.newImageView(_res("ui/common/common_title_5.png"),layoutSize.width/2, layoutSize.height/2 + 80 )
	--layout:addChild(rewardImageBg)
	--local rewardImageBgSize = rewardImageBg:getContentSize()
	--local text = __('基础奖励')
	--if self.orderType == PublicOrder  then
	--	text = __('外卖奖励')
	--end
	--local rewardTextLabel   = display.newLabel(rewardImageBgSize.width/2, rewardImageBgSize.height/2  ,{text =  __('基础奖励'), fontSize = fontWithColor('8').fontSize, color = fontWithColor('8').color})
	--rewardImageBg:addChild(rewardTextLabel)
	--rewardImageBg:setCascadeOpacityEnabled(true)
	--rewardTextLabel:setCascadeOpacityEnabled(true)
	local rewardImageBg = display.newButton(layoutSize.width/2, layoutSize.height/2 + 80 , {ap = display.CENTER , n =_res("ui/common/common_title_5.png") , scale9 = true ,enable = false  })
	display.commonLabelParams(rewardImageBg , fontWithColor(8, {text = __('基础奖励') , paddingW = 20 } ))
	layout:addChild(rewardImageBg)
	local  topGoods = {}
	for i = #data , 1 ,-1 do
		local v = clone(data[i])

		if checkint(v.goodsId ) == COOK_ID then
			table.insert( topGoods, #topGoods+1 , v)
			table.remove(data,i)
		elseif  checkint(v.goodsId )  == GOLD_ID then
			table.insert( topGoods, #topGoods+1 , v)
			table.remove(data,i)
		end
	end

	---@type TakeawayManager
	local takeawayMgr = AppFacade.GetInstance():GetManager("TakeawayManager")
	local activityData = takeawayMgr:GetTakeAwayGoodData()
	for i = 1, #activityData do
		activityData[i].isActivity = true
		data[#data+1]  = activityData[i]
	end
	local width = 105
	local layoutContentSize = cc.size ((#data )*width  ,200)
	local layoutContent = CLayout:create(cc.size(layoutContentSize.width,layoutContentSize.height))
	layout:addChild(layoutContent)
	local offwidth = 140
	local mainExp = checkint(self.dataOrder.mainExp)
	local popularity  = checkint(self.dataOrder.completePopularity)
	---  配有经验的时候添加经验
	if  mainExp > 0 then
		table.insert(topGoods,#topGoods+1 ,{goodsId = EXP_ID , num = mainExp})
	end
	--- 知名度是否添加的判断
	if popularity > 0 then
		table.insert(topGoods,#topGoods+1 ,{goodsId = POPULARITY_ID , num = popularity})
	end

	local topWidth  = (#topGoods) * offwidth
	local numbei =1
	local width  =  40
	if self.orderType == PublicOrder then
		numbei = #topGoods /2
		topWidth = offwidth * 2
		width = 60
	end
	local topContentSize = cc.size(topWidth , width * numbei)
	local topLayout = display.newLayer(0,0,{ ap = display.CENTER , size = topContentSize})
	--CLayout:create(topContentSize)
	topLayout:setAnchorPoint(display.CENTER)

	topLayout:setPosition(cc.p(layoutSize.width/2, layoutContentSize.height -70))
	layout:addChild(topLayout,10)

	local count = table.nums(data)
	local chestWidth = 120
	local chestSize = cc.size(chestWidth * count ,chestWidth)


	if self.orderType == PublicOrder then
		topLayout:setPosition(cc.p(layoutSize.width/2, layoutContentSize.height -40))
		local chestLayout =CLayout:create( chestSize )
		for k ,v in pairs(data) do
			if v  then
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
				goodNode:setPosition(cc.p((k- 0.5 )* chestWidth ,chestSize.height/2 - 30 ))
				chestLayout:addChild(goodNode)
			end
		end
		chestLayout:setPosition(cc.p(layoutSize.width/2 , layoutSize.height/2 -50 ) )
		layout:addChild(chestLayout)
		local height = 40
		for i  =1 ,#topGoods  do
			local data = topGoods[i]
			local iconPath = CommonUtils.GetGoodsIconPathById(data.goodsId)
			local num = math.ceil(#topGoods/2 ) -   math.ceil(i/2) +1
			local mod = i % 2
			if mod %2 == 0 then
				mod = 2
				num = math.ceil(#topGoods/2 ) -   math.ceil(i/2) +1
			end
			local rewardsNum = display.newButton((mod - 0.5)* offwidth - 25 + layoutSize.width/2 - 244 ,(num -0.5)*height +5,{ n = _res('ui/home/takeaway/takeout_bg_reward_number.png'), s = _res('ui/home/takeaway/takeout_bg_reward_number.png'), enable = true , animate = true})
			local baseNum = data.num
			--- 只有厨力点会有点击的效果
			if checkint(data.goodsId) == COOK_ID then -- 因为服务端已经返回了获得物品的总数据 所以 这里面的数据就不用添加了
				rewardsNum:setTag(COOK_ID)
				rewardsNum:setOnClickScriptHandler(handler(self, self.UpdateBounslayout))
			elseif checkint(data.goodsId) == POPULARITY_ID  then
			end
			local rcihLabel = display.newRichLabel(0, 0, { r = true , c = {
				{ img = iconPath  ,scale = 0.2} ,
				{ color = fontWithColor("10").color, fontSize = fontWithColor('10').fontSize,text = " " .. baseNum , ap = display.CENTER}
			}})
			local rewardsNumSize = rewardsNum:getContentSize()
			rcihLabel:setPosition(cc.p(rewardsNumSize.width/2 , rewardsNumSize.height/2))
			rewardsNum:addChild(rcihLabel)
			topLayout:addChild(rewardsNum)
			rcihLabel:setCascadeOpacityEnabled(true)
			rewardsNum:setCascadeOpacityEnabled(true)
		end
	else
		local chestLayout =CLayout:create( chestSize )
		for k ,v in pairs(data) do
			if v  then
				local data =  v
				local  showAmount = true
				if data.isActivity then
					showAmount = false
				end
				local goodNode = require('common.GoodNode').new({id = data.goodsId, amount = data.num, showAmount = showAmount})
				display.commonUIParams(goodNode, {animate = false, cb = function (sender)
					uiMgr:AddDialog("common.GainPopup", {goodId = data.goodsId})
				end})
				goodNode:setAnchorPoint(cc.p(0.5,0.5))
				goodNode:setScale(0.9)
				goodNode:setPosition(cc.p((k- 0.5 )* chestWidth ,chestSize.height/2 - 5 ))
				chestLayout:addChild(goodNode)
			end
		end
		chestLayout:setPosition(cc.p(layoutSize.width/2 , layoutSize.height/2 -50 ) )
		layout:addChild(chestLayout)
		for i  =1 ,#topGoods  do
			local data = topGoods[i]
			local iconPath = CommonUtils.GetGoodsIconPathById(data.goodsId)
			local rewardsNum = display.newButton((i- 0.5)* offwidth,topContentSize.height/2 ,{ n = _res('ui/home/takeaway/takeout_bg_reward_number.png'), s = _res('ui/home/takeaway/takeout_bg_reward_number.png'), enable = true , animate = true})
			local baseNum = data.num
			--- 只有厨力点会有点击的效果
			if checkint(data.goodsId) == COOK_ID then -- 因为服务端已经返回了获得物品的总数据 所以 这里面的数据就不用添加了
				rewardsNum:setTag(COOK_ID)
				rewardsNum:setOnClickScriptHandler(handler(self, self.UpdateBounslayout))
			elseif checkint(data.goodsId) == POPULARITY_ID  then
			end
			local rcihLabel = display.newRichLabel(0, 0, { r = true , c = {
				{ img = iconPath  ,scale = 0.2} ,
				{ color = fontWithColor("10").color, fontSize = fontWithColor('10').fontSize,text = " " .. baseNum , ap = display.CENTER}

			}})
			local rewardsNumSize = rewardsNum:getContentSize()
			rcihLabel:setPosition(cc.p(rewardsNumSize.width/2 , rewardsNumSize.height/2))
			rewardsNum:addChild(rcihLabel)
			topLayout:addChild(rewardsNum)
			rcihLabel:setCascadeOpacityEnabled(true)
			rewardsNum:setCascadeOpacityEnabled(true)
		end

	end
	return layout
end
function LargeAndOrdinaryOrder:createRewardLayout(data ,Additional) -- 用于创建下面额奖励获得
	local data = clone(data)
	local treasureType =   self.treasureType    -- 0 的时候是一般的goods 1 为金宝箱 2.为银宝箱
	local layoutSize = cc.size(537,200)
	local layout = display.newLayer(0,0, { size  = layoutSize , ap = display.CENTER })
	--CLayout:create(layoutSize)

	if treasureType == 0 then
		local text = Additional and __('急速响应奖励') or __('基础奖励')
		local rewardImageBg = display.newButton(layoutSize.width/2, layoutSize.height/2 + 80 , {ap = display.CENTER , n =_res("ui/common/common_title_5.png") , scale9 = true ,enable = false  })
		display.commonLabelParams(rewardImageBg , fontWithColor(8, {text = text ,paddingW = 20 }))
		layout:addChild(rewardImageBg)
		--local rewardImageBg =  display.newImageView(_res("ui/common/common_title_5.png"),layoutSize.width/2, layoutSize.height/2 + 80 )
		--layout:addChild(rewardImageBg)
		--local rewardImageBgSize = rewardImageBg:getContentSize()
		--local text = Additional and __('急速响应奖励') or __('基础奖励')
		--local rewardTextLabel   = display.newLabel(rewardImageBgSize.width/2, rewardImageBgSize.height/2  ,{text = text, fontSize = fontWithColor('8').fontSize, color = fontWithColor('8').color})
		--rewardImageBg:addChild(rewardTextLabel)
		--rewardImageBg:setCascadeOpacityEnabled(true)
		--rewardTextLabel:setCascadeOpacityEnabled(true)
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
		layout:addChild(layoutContent,2)
		if self.orderType == PrivateOrder then
			local offwidth = 140
			local mainExp = checkint(self.dataOrder.mainExp)
			local popularity  = checkint(self.dataOrder.completePopularity)
			if  mainExp > 0 then
				table.insert(topGoods,#topGoods+1 ,{goodsId = EXP_ID , num = mainExp})
			end
			if popularity > 0 then
				table.insert(topGoods,#topGoods+1 ,{goodsId = POPULARITY_ID , num = popularity})
			end
			local topWidth  = (#topGoods) * offwidth
			local topContentSize = cc.size(topWidth, 40)
			local topLayout = CLayout:create(topContentSize)
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
			if self.status == 1 then
				for i  =1 ,#topGoods  do
					local data = topGoods[i]
					local iconPath = CommonUtils.GetGoodsIconPathById(data.goodsId)
					local rcihLabel = display.newRichLabel(0, 0, { r = true , c = {
						{ img = iconPath  ,scale = 0.2} ,
						{ color = fontWithColor("10").color, fontSize = fontWithColor('10').fontSize,text = " " .. data.num , ap = display.CENTER}

					}})
					local rewardsNum = display.newImageView(_res('ui/home/takeaway/takeout_bg_reward_number.png'),(i- 0.5)* offwidth,topContentSize.height/2)
					local rewardsNumSize = rewardsNum:getContentSize()
					rcihLabel:setPosition(cc.p(rewardsNumSize.width/2 , rewardsNumSize.height/2))
					rewardsNum:addChild(rcihLabel)
					topLayout:addChild(rewardsNum)
					rcihLabel:setCascadeOpacityEnabled(true)
					rewardsNum:setCascadeOpacityEnabled(true)
				end
			end
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
				local iconPath = CommonUtils.GetGoodsIconPathById(data.goodsId)
				local num = math.ceil(#topGoods/2 ) -   math.ceil(i/2) +1
				local mod = i % 2
				if mod %2 == 0 then
					mod = 2
					num = math.ceil(#topGoods/2 ) -   math.ceil(i/2) +1
				end
				local icon = display.newImageView(iconPath,(mod - 0.5)* width - 25,(num -0.5)*height)
				icon:setScale(0.2)
				topLayout:addChild(icon)
				local goodTextNum = display.newLabel((mod - 0.5)* width - 10 ,(num -0.5)*height,{ color = fontWithColor("10").color, fontSize = fontWithColor('10').fontSize,text = data.num, ap = display.LEFT_CENTER})
				topLayout:addChild(goodTextNum)
			end
			layoutContent:setPosition(layoutSize.width/2,layoutSize.height/2 - 70)
			---@type TakeawayManager
			local takeawayMgr = AppFacade.GetInstance():GetManager("TakeawayManager")
			local activityData = takeawayMgr:GetTakeAwayGoodData()
			local datas = clone(data)
			local hegitUp = 0
			local hegitDown = 0
			if not  Additional then
				for i = 1, #activityData do
					hegitUp = 70
					hegitDown = -120
					activityData[i].isActivity = true
					datas[#datas+1] = activityData[i]
				end
				topLayout:setPosition(cc.p(layoutSize.width/2, layoutContentSize.height - 80 + hegitDown))
			end
			local width = 120
			local chestSize = cc.size(width*(#datas),200)
			local chestLayout =CLayout:create(chestSize)
			layoutContentSize = cc.size(chestSize.width, layoutContentSize.height)
			layoutContent:setContentSize(layoutContentSize)
			chestLayout:setPosition(cc.p(layoutContentSize.width/2 , layoutContentSize.height /2  + 20))
			for  i =1, #datas do
				local data = datas[i]
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

					goodNode:setPosition(cc.p((i-0.5)*width ,chestSize.height/2  - 30 + hegitUp))
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
function LargeAndOrdinaryOrder:runActionWithPeople()
	local dialogue = self.dialogue
	local dialogueText = self.dialogueText
	self.rightlayout:setOpacity(0)
	self.roleLayout:setOpacity(0)
	self.dialogue:setOpacity(0)
	self.dialogue:setCascadeOpacityEnabled(true)
	self.rightlayout:setVisible(true)
	local moveAct  = cc.FadeIn:create(0.3)
	local fadeIn = cc.TargetedAction:create(self.dialogue, cc.FadeIn:create(0.2))
	local function callback1()
		dialogue:setVisible(true)
	end
	local function callback2()
		dialogueText:setVisible(true)
	end
	local function callback3()
		if self.status ~= CompleteOrder then
			self.rightlayout:setOpacity(0)
			self.rightlayout:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.FadeIn:create(0.25)))
		end
	end
	-- 打字机效果
	local writer = TypewriterAction:create(1)
	local writerAct = cc.Sequence:create(cc.DelayTime:create(0.1), cc.TargetedAction:create(dialogueText, writer))
	self.roleLayout:runAction(cc.Sequence:create(moveAct, cc.CallFunc:create(callback1),fadeIn, cc.Spawn:create(cc.CallFunc:create(callback3), cc.TargetedAction:create(dialogueText, cc.FadeIn:create(0.2)), writerAct)))
end
function LargeAndOrdinaryOrder:needGood(datas) -- 需要的材料集中适配的东西集中适配
	self.foodEnough  = true
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
		end})
		goodNode:setAnchorPoint(cc.p(0.5,0.5))
		goodNode:setPosition(cc.p((i-0.5)*distanceWidth ,needSize.height/2))
		local fontNum = '6'
		if checkint(gameMgr:GetAmountByGoodId(data.goodsId)) < checkint(data.num) then
			self.foodEnough = false
			fontNum = '10'
		end
		local labelNum =display.newRichLabel((i-0.5)*distanceWidth,needSize.height/2 - 70,{ap = display.CENTER, c = {
						{text = tostring(checkint(gameMgr:GetAmountByGoodId(data.goodsId))) ..'/', fontSize = fontWithColor(fontNum).fontSize, color =  fontWithColor(fontNum).color},
						{text = tostring(data.num), fontSize = fontWithColor('6').fontSize, color = fontWithColor('6').color}
					}})
		display.reloadRichLabel( labelNum,{ap = display.CENTER,c = {
			{text = tostring(checkint(gameMgr:GetAmountByGoodId(data.goodsId))) ..'/' , fontSize = 30, color =  fontWithColor(fontNum).color},
			{text = tostring(data.num), fontSize = 30, color = fontWithColor('6').color}}})
		labelNum:setPosition(cc.p((i-0.5)*distanceWidth,needSize.height/2 - 80))
		layout:addChild(goodNode)
		layout:addChild(labelNum)

	end
	return layout
end
function LargeAndOrdinaryOrder:ChangeTimeFormat( remainSeconds )
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
function LargeAndOrdinaryOrder:updateTestsureAndMarqueue(hasDelivery,playerListInfo)
	local count = #playerListInfo
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

		if not self.noticeImage then
			self.createMarQueue()
		end
		local noticeImageSize =  self.noticeImage:getContentSize()
		local label = display.newLabel(noticeImageSize.width,noticeImageSize.height/2,{ text = playerListText ,ap = display.LEFT_CENTER ,fontSize = fontWithColor('8').fontSize , color = fontWithColor('8').color})
		local labelContentSize =label:getContentSize()
		self.noticeImage:addChild(label)
		local second =  (noticeImageSize.width + labelContentSize.width)/200
		local callBack2 = nil

		local callback = function ()
			if numCount < count then
				local  startNum = numCount + 1
				playerListText = ""
				local endNum  =(numCount + 4) < count and (numCount + 4) or count
				numCount = (numCount + 4) < count and (numCount + 4) or 0
				for i = startNum , endNum do
					playerListText =  playerListText .. playerListInfo[i]
					if i< count then
						playerListText = playerListText .. __('已抢单发车').. blankStr
					end
				end
				label:setString(playerListText)

				labelContentSize =label:getContentSize()
				second =  (noticeImageSize.width + labelContentSize.width)/200
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
	if self.treasureLayout then
		local  treasure =  self.treasureLayout:getChildByTag(888)
		local treasureLayoutSize = self.treasureLayout:getContentSize()
		if checkint(hasDelivery) < checkint(self.orderData.bestOrderNum) then
			if treasure then
			else
				local treasureSize = treasure:getContentSize()
				local tiltleImage  = display.newImageView(_res('ui/home/takeaway/takeout_bg_sellout.png'),treasureSize.width/2,treasureSize.height/2)
				local tiltleImageSize = tiltleImage:getContentSize()
				local tiltleLabel =  display.newLabel(tiltleImageSize.width/2,tiltleImageSize.height/2,{ text = _res('以抢完'),ap = display.CENTER ,fontSize = 22 , color = "#ffffff"})
				tiltleImage:addChild(tiltleLabel)
				treasure:addChild(tiltleImage)
				treasure:setColor(cc.c3b(80,80,80))
			end
			local remainImage = display.newImageView(_res('ui/home/takeaway/takeout_bg_places.png') ,0,0, {scale9 =  true ,
																										   size = cc.size(150,39) ,capInsets = cc.rect(20,19,85,1)
			})
			local remainImageSize =  remainImage:getContentSize()
			local remainText = display.newLabel(0,0,fontWithColor(8, { text = __('剩余名额'),ap = display.RIGHT_CENTER}))
			local remainTextSize = remainText:getContentSize()
			remainText:setPosition(cc.p(remainTextSize.width/2+20,remainImageSize.height/2))
			remainImage:setPosition(cc.p(remainImageSize.width/2 + remainTextSize.width  - 20,remainImageSize.height/2))
			local remainNumText = display.newRichLabel(remainImageSize.width/2,remainImageSize.height /2,{ap = display.CENTER, c = {
				fontWithColor(10,{text = tostring( checkint(self.orderData.bestOrderNum)  - checkint(hasDelivery) ) ,  fontSize =  26}),
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
			local remainText = display.newLabel(treasureLayoutSize.width/2,0,fontWithColor(8, { text = __('急速响应奖励名额已抢完'), w = 225 , hAlign = display.TAC ,ap = display.CENTER}))
			self.treasureLayout:addChild(remainText)
		end
	end

end
function LargeAndOrdinaryOrder:updatePeopleAndPeople()
    local roleNode = CLayout:create()
    local cardDrawId = self.roleId
    local roleName = ""
	local realRoleId = CommonUtils.GetConfigAllMess('role','takeaway')[tostring(self.roleId)]["realRoleId"]
    realRoleId = CommonUtils.GetSwapRoleId(realRoleId)
	local roleTable =  CommonUtils.GetConfigAllMess('role','quest')
	local roleData =  roleTable[realRoleId]
    if  string.match(realRoleId, '^%d+') then
        --数字表示是卡牌
        self.iscard = true
        -- 突破后的立绘不存在 使用默认立绘
        roleName =   tostring(CardUtils.GetCardConfig(realRoleId).name)
    else
        self.iscard = false
        --角色人物
        local rInfo = gameMgr:GetRoleInfo(realRoleId)
        if rInfo then
            roleName = rInfo.roleName
        end
    end
    local lwidth = 200
    local cardView = CommonUtils.GetRoleNodeById(realRoleId)
	local mediatorSize = cardView:getContentSize()
	local scaleNum = 0
	local nodePosition = cc.p(0,0)
	if roleData['takeaway']  then
		if roleData['takeaway'].x ~= "" and roleData['takeaway'].y ~= ""  then
			scaleNum = checkint(roleData['takeaway'].scale)/100
			--nodePosition = cc.p(checkint( roleData['takeaway'].x ), checkint(roleData['takeaway'].y))
			if display.height/display.width > 0.65 then
				nodePosition = cc.p(checkint( roleData['takeaway'].x ), (checkint(roleData['takeaway'].y) -mediatorSize.height)*0.8)
			else
				nodePosition = cc.p(checkint( roleData['takeaway'].x ), (checkint(roleData['takeaway'].y) -mediatorSize.height)*0.8)
			end
		end
	end
	cardView:setScale(scaleNum)
    lwidth = mediatorSize.width*scaleNum
	lheight = mediatorSize.height*scaleNum
    roleNode:setContentSize(cc.size(lwidth,lheight))
    display.commonUIParams(cardView, {ap = cc.p(0.5,0.5), po = cc.p(lwidth/2, lheight/2)})
    cardView:setTag(888)
	-- self:addChild(cardView)
    roleNode:addChild(cardView)
	roleNode:setAnchorPoint(cc.p(0.5,0))
	roleNode:setPosition(nodePosition)
    return roleNode
end
function LargeAndOrdinaryOrder:UpdateUI()  -- 更新UI逻辑
	if not  self.orderType  then
		return
	end
	local data = self.dataOrder
	local textTitle = data.name
	self.bgImageView:setTexture(ImageCollect[self.orderType].bgImage)
	self.titleLabel:setString(data.name)
	if self.titleImageView then
		self.titleImageView:setTexture(ImageCollect[self.orderType].title)
	end
	if checkint(self.status)  ==  CompleteOrder or  (checkint(self.status ) > WaitingShipping and   self.time == 0)   then
		self.sendMessage:getLabel():setString(__("领 取"))
		self.cancelBtn:setVisible(false)
		self.sendMessage:setPosition(cc.p(self.orderSize.width/2,35) )
	elseif ( checkint(self.status) ~=  WaitingShipping and self.time > 0 ) then
		self:judageOrderStatus()
		self.sendMessage:getLabel():setString(__("撤销订单"))
		self.cancelBtn:setVisible(false)
		self.sendMessage:setPosition(cc.p(self.orderSize.width/2,35) )
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

function LargeAndOrdinaryOrder:createBonusLayout()
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

function LargeAndOrdinaryOrder:UpdateBounslayout(sender)
	local tag  = sender:getTag()
	local fScale = sender:getScaleX()
	sender:setEnabled(false)
	transition.execute(sender,cc.Sequence:create(
	cc.EaseOut:create(cc.ScaleTo:create(0.03, 0.92*fScale, 0.92*fScale), 0.03),
	cc.EaseOut:create(cc.ScaleTo:create(0.03, 1*fScale, 1*fScale), 0.03),
	cc.CallFunc:create(function()
		sender:setEnabled(true)
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
	local offsetRight = 20
	listView:removeAllNodes()
	local lineHeight = 35
	local cookingBouns = { self.orderData.recipeCookingPoint ,self.orderData.assistantCookingPoint }
	local cookingName = {__('菜谱') ,__('厨房') }
	if tag == COOK_ID then
		for  i =1 , #cookingBouns do
			if checkint(cookingBouns[i] ) > 0 then
				local iconPath = CommonUtils.GetGoodsIconPathById(COOK_ID)
				local richLabel = display.newRichLabel(0,0,{ r = true , c = {
					fontWithColor('16', { text = cookingName[i] .. "  " }) ,
					fontWithColor('10', { text =  " +" .. cookingBouns[i] }),
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
	local tableNodes = listView:getNodes()
	if table.nums(tableNodes) > 0  then
		local bounsSzie =   bounsLayout:getContentSize()
		local label = display.newLabel(bounsSzie.width/2 , bounsSzie .height - 40 ,fontWithColor( '6', { ap = display.CENTER_BOTTOM, text = __('资源加成')}))
		bounsLayout:addChild(label)
		listView:reloadData()
	else
		local listSize = listView:getContentSize()
		local contentLayout = display.newLayer(listSize.width /2 , listSize.height /2 , { size = listSize })
		local label = display.newLabel(listSize.width/2 , listSize .height/2 + 10 ,fontWithColor( '6', { ap = display.CENTER_BOTTOM, text = __('暂无加成效果')}))
		contentLayout:addChild(label)
		listView:insertNodeAtLast(contentLayout)
		listView:reloadData()
	end
end


return LargeAndOrdinaryOrder
