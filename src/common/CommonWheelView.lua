--[[
通用转盘活动
@params table{
	content table 奖励
	leftSeconds int 剩余秒数
	leftBtnCost table 左侧按钮点击消耗
	rightBtnCost table 右侧按钮点击消耗
	leftDrawnTimes int 剩余抽奖次数(-1为不限制次数)
	activityId int 活动id
	leftBtnCallback function 左侧按钮点击回调
	rightBtnCallback function 右侧按钮点击回调
	closeCallback function 领奖结束回调
	discount int 折扣
	isFree bool 是否是首次抽奖
	timesRewards table 兑换奖励
	drawnTimes int 抽奖次数
	tips str 提示
	tipsBtnCallback function tips按钮点击回调
	backBtnCallback function 返回按钮点击回调
	type int 1:活动大转盘 2:组合副本大转盘
}
--]]
local CommonWheelView = class('CommonWheelView', function ()
	local node = CLayout:create(display.size)
	node.name = 'home.CommonWheelView'
	node:enableNodeEvents()
	return node
end)
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local WHEEL_TYPE  = {
	COMMON = 1,				-- 通常
	ASSEMBLY_ACTIVITY = 2   -- 组合副本
}
local function CreateView( self )
	local view = CLayout:create(display.size)
	local sectorNum = #self.args.content
	-- 转盘圆心
	local centerPos = cc.p(display.cx - 12, display.cy - 15)
	-- 屏蔽层
	local maskLayer = CColorView:create(cc.c4b(0, 0, 0, 0))
	maskLayer:setTouchEnabled(true)
	maskLayer:setContentSize(cc.size(600, 600))
	maskLayer:setPosition(centerPos)
	maskLayer:setAnchorPoint(0.5, 0.5)
	view:addChild(maskLayer, -1)
	-- 背景
	local bg = display.newImageView(_res('ui/home/activity/activity_turntable_bg_3.png'), display.cx, display.cy)
	view:addChild(bg, 1)

	-- 创建扇形区域
	local angle = 360/sectorNum
	for i=1, sectorNum do
		local bgType = nil 
		if i%2 == 0 then
			bgType = 1
		else
			bgType = 2
		end
		local powerBar = cc.ProgressTimer:create(cc.Sprite:create(_res('ui/home/activity/activity_turntable_bg_' .. tostring(bgType) .. '.png')))
		powerBar:setType(cc.PROGRESS_TIMER_TYPE_RADIAL)
		powerBar:setMidpoint(cc.p(0.5, 0.5))
		powerBar:setPercentage(100/sectorNum)
		powerBar:setPosition(centerPos)
		powerBar:setRotation((i-1.5)*angle)
		view:addChild(powerBar, 3)
		local rewards = self.args.content[i]
		local goodsIcon = require('common.GoodNode').new({id = rewards.rewards[1].goodsId, amount = rewards.rewards[1].num, showAmount = true, highlight = rewards.isHighlight})
		goodsIcon:setScale(1-(90-angle)/125)
		display.commonUIParams(goodsIcon, {animate = false, cb = function (sender)
			uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = rewards.rewards[1].goodsId, type = 1})
		end})
		local radian = math.rad((i-1)*angle)
		local radius = 165
		local goodsPos = cc.p(centerPos.x + radius*math.sin(radian), centerPos.y + radius*math.cos(radian))
		goodsIcon:setPosition(goodsPos)
		view:addChild(goodsIcon, 6)
	end

	local line = display.newImageView(_res('ui/home/activity/activity_turntable_bg_lines.png'), centerPos.x, centerPos.y)
	view:addChild(line, 5)
	local arrowBg = display.newImageView(_res('ui/home/activity/activity_turntable_yuan.png'), centerPos.x, centerPos.y)
	view:addChild(arrowBg, 6)
	local arrowIcon = display.newImageView(_res('ui/home/activity/activity_turntable_arrow.png'), centerPos.x , centerPos.y, {ap = cc.p(0.5, 0.305)})
	view:addChild(arrowIcon, 7)

	local timeTitleBg = display.newImageView(_res('ui/home/activity/activity_turntable_bg_time.png'), centerPos.x, display.cy + 272)
	view:addChild(timeTitleBg, 8)
	local timeTitle = display.newLabel(centerPos.x, display.cy + 272, fontWithColor(18, {text = __('剩余时间')}))
	view:addChild(timeTitle, 10)
	local timeLabelBg = display.newImageView(_res('ui/home/activity/activity_turntable_title_time.png'), centerPos.x, display.cy + 238)
	view:addChild(timeLabelBg, 8)
	local timeLabel = display.newLabel(centerPos.x, display.cy + 238, fontWithColor(10, {text = '15天21小时'}))
	view:addChild(timeLabel, 10)

	-- local luckyDrawBtn = display.newButton(centerPos.x, centerPos.y, {n = ''})
	-- luckyDrawBtn:setContentSize(cc.size(150, 150))
	-- view:addChild(luckyDrawBtn, 10)
	-- 抽奖按钮
	local oneDrawBtn = display.newButton(centerPos.x - 108, display.cy - 310, {n = _res('ui/home/kitchen/kitchen_make_btn_orange.png')})
	view:addChild(oneDrawBtn, 10)
	local buttonSize = oneDrawBtn:getContentSize()
	local oneDrawCostGoods = display.newImageView(CommonUtils.GetGoodsIconPathById(DIAMOND_ID), 74, buttonSize.height/2)
	oneDrawCostGoods:setScale(0.2)
	oneDrawBtn:addChild(oneDrawCostGoods)
	local oneDrawTitle = display.newLabel(125, buttonSize.height/2, {text = __('抽一次'), fontSize = 22, ttf = true, font = TTF_GAME_FONT, color = 'ffffff', outline = '#5b3c25', outlineSize = 1})
	oneDrawBtn:addChild(oneDrawTitle)
	local oneDrawCostNums = display.newLabel(56, buttonSize.height/2, {ap = cc.p(1, 0.5), text = '',fontSize = 22, ttf = true, font = TTF_GAME_FONT, color = 'ffffff', outline = '#5b3c25', outlineSize = 1})
	oneDrawBtn:addChild(oneDrawCostNums) 
	local freeLabel = display.newLabel(buttonSize.width/2, buttonSize.height/2, {text = __('今日首次免费'), w = 160 , hAlign = display.TAC  , fontSize = 22, ttf = true, font = TTF_GAME_FONT, color = 'ffffff', outline = '#5b3c25', outlineSize = 1})
	oneDrawBtn:addChild(freeLabel)

	local multiDrawBtn = display.newButton(centerPos.x + 108, display.cy - 310, {n = _res('ui/home/kitchen/kitchen_make_btn_red.png')})
	view:addChild(multiDrawBtn, 10)

	--local multiDrawCostGoods = display.newImageView(CommonUtils.GetGoodsIconPathById(DIAMOND_ID), 74, buttonSize.height/2)
	--multiDrawCostGoods:setScale(0.2)
	--multiDrawBtn:addChild(multiDrawCostGoods)
	--
	--local multiDrawTitle = display.newLabel(125, 32, {text = __('抽十次'), fontSize = 22, ttf = true, font = TTF_GAME_FONT, color = 'ffffff', outline = '#5b3c25', outlineSize = 1})
	--multiDrawBtn:addChild(multiDrawTitle)
	--
	--local  multiDrawCostNums = display.newLabel(56, buttonSize.height/2, {ap = cc.p(1, 0.5), text = '',fontSize = 22, ttf = true, font = TTF_GAME_FONT, color = 'ffffff', outline = '#5b3c25', outlineSize = 1})
	--multiDrawBtn:addChild(multiDrawCostNums)

	local multiDrawCostNums = display.newRichLabel(100 , buttonSize.height/2 -10, { c = {
		fontWithColor(12, {text = ""})
	}} )
	multiDrawBtn:addChild(multiDrawCostNums)

	local origCostNums = display.newRichLabel(90, 50,{ap = cc.p(0.5, 0.5), c= {
		{ap = cc.p(1, 0.5), text = __('原价 100'), fontSize = 22, ttf = true, font = TTF_GAME_FONT, color = 'ffffff', outline = '#5b3c25', outlineSize = 1}
	} })
	multiDrawBtn:addChild(origCostNums)

	local line = display.newImageView(_res('ui/home/activity/activity_xiashitehi_line_sale.png'), buttonSize.width/2, 50)
	multiDrawBtn:addChild(line, 10)
	-- 兑换按钮
	local exchangeLayoutSize = cc.size(170, 130)
	local exchangeLayout = CLayout:create(exchangeLayoutSize)
	view:addChild(exchangeLayout, 10)
	exchangeLayout:setPosition(display.width - 100 - display.SAFE_L, display.height - 120)
	local exchangeBtn = display.newButton(exchangeLayoutSize.width/2, exchangeLayoutSize.height/2, {n = _res('arts/goods/goods_icon_191006.png')})
	exchangeBtn:setScale(0.8)
	exchangeLayout:addChild(exchangeBtn)
    local exchangeRemindIcon = display.newImageView(_res('ui/common/common_hint_circle_red_ico.png'), exchangeLayoutSize.width - 30, exchangeLayoutSize.height - 30)
    exchangeLayout:addChild(exchangeRemindIcon)
    local exBtnTitle = display.newButton(exchangeLayoutSize.width/2, 30, {n = _res('ui/cards/propertyNew/card_bar_bg.png')})
    display.commonLabelParams(exBtnTitle, {text = __('豪华奖励'), fontSize = 22, ttf = true, font = TTF_GAME_FONT, color = 'ffffff', outline = '#5b3c25', outlineSize = 1})
    exchangeLayout:addChild(exBtnTitle)

	-- 抽奖次数限制
	local drawLimitTitle = display.newButton(centerPos.x, display.cy - 248 , {scale9 = true ,n = _res('ui/home/activity/activity_turntable_bg_time.png') })
	view:addChild(drawLimitTitle, 10)
	local tipsBtn = display.newButton(centerPos.x + 150, display.cy - 248, {n = _res('ui/common/common_btn_tips.png')})
	view:addChild(tipsBtn, 10)
	-- 页面特效
	local dotSpine = sp.SkeletonAnimation:create('effects/activity/dian.json', 'effects/activity/dian.atlas', 1)
	dotSpine:update(0) 
	dotSpine:setAnimation(0, 'idle', true)
	dotSpine:setPosition(cc.p(centerPos.x, centerPos.y - 315))
	view:addChild(dotSpine, 10)
	local lightSpine = sp.SkeletonAnimation:create('effects/activity/guang.json', 'effects/activity/guang.atlas', 1)
	lightSpine:update(0) 
	lightSpine:setAnimation(0, 'idle', true)
	lightSpine:setPosition(cc.p(centerPos.x, centerPos.y - 315))
	view:addChild(lightSpine, 10)

	local arrowSpine = sp.SkeletonAnimation:create('effects/activity/choujiang.json', 'effects/activity/choujiang.atlas', 1)
	arrowSpine:update(0)
	arrowSpine:setAnimation(0, 'idle1', true)
	view:addChild(arrowSpine, 6)
	arrowSpine:setPosition(centerPos)
	-- 返回按钮
	local backBtn = display.newButton(0, 0, {n = _res("ui/common/common_btn_back")})
	backBtn:setPosition(cc.p(display.SAFE_L + backBtn:getContentSize().width * 0.5 + 30, display.height - 53))
	view:addChild(backBtn, 10)
	-- CommonMoneyBar
	local moneyBar = require("common.CommonMoneyBar").new()
	view:addChild(moneyBar)

	return {
		view 			   = view,
		angle              = angle,
		arrowIcon          = arrowIcon,
		timeLabel          = timeLabel,
		drawLimitTitle     = drawLimitTitle,
		oneDrawCostNums        = oneDrawCostNums,
		tipsBtn 	       = tipsBtn,
		oneDrawBtn         = oneDrawBtn,
		multiDrawBtn       = multiDrawBtn,
		centerPos          = centerPos,
		oneDrawCostGoods   = oneDrawCostGoods,
		oneDrawTitle  	   = oneDrawTitle,
		multiDrawCostNums  = multiDrawCostNums,
		origCostNums       = origCostNums,
		line   	 		   = line,
		freeLabel  	       = freeLabel,
		exchangeBtn        = exchangeBtn,
		exchangeLayout     = exchangeLayout,
		exchangeRemindIcon = exchangeRemindIcon, 
		backBtn 	 	   = backBtn,
		moneyBar		   = moneyBar,
	}
end

function CommonWheelView:ctor( ... )
	self.args = unpack({...}) or {}
	local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 255 * 0.6))
	eaterLayer:setTouchEnabled(true)
	eaterLayer:setContentSize(display.size)
	eaterLayer:setPosition(utils.getLocalCenter(self))
	self.eaterLayer = eaterLayer
	self:addChild(eaterLayer, -1)
	self.viewData_ = CreateView( self )
	self:addChild(self.viewData_.view, 1)
	self.viewData_.view:setPosition(utils.getLocalCenter(self))
	AppFacade.GetInstance():DispatchObservers(HomeScene_ChangeCenterContainer, "GONE")
	self.viewData_.backBtn:setOnClickScriptHandler(handler(self, self.RemoveSelf_))
	-- 添加监听
	AppFacade.GetInstance():RegistObserver(SHOP_EXIT_SHOP, mvc.Observer.new(function () 
		AppFacade.GetInstance():DispatchObservers(HomeScene_ChangeCenterContainer, "GONE")
	end, self))
	AppFacade.GetInstance():RegistObserver(ACTIVITY_PROP_EXCHANGE_EXIT, mvc.Observer.new(function () 
		AppFacade.GetInstance():DispatchObservers(HomeScene_ChangeCenterContainer, "GONE")
	end, self))
	AppFacade.GetInstance():RegistObserver(SGL.REFRESH_NOT_CLOSE_GOODS_EVENT, mvc.Observer.new(function () 
		self.viewData_.moneyBar:updateMoneyBar()
	end, self))
	self:InitUi()
end
--[[
更新Ui
--]]
function CommonWheelView:InitUi()
	local datas = self.args
	local viewData = self.viewData_
	if datas.leftDrawnTimes and checkint(datas.leftDrawnTimes) ~= -1 then
		--viewData.drawLimitTitle:setString(string.fmt(__('剩余次数：_num_'), {['_num_'] = datas.leftDrawnTimes}))
		display.commonLabelParams(viewData.drawLimitTitle , fontWithColor(18, {text =string.fmt(__('剩余次数：_num_'), {['_num_'] = datas.leftDrawnTimes}) , paddingW = 20  }))
		local drawLimitTitleSize = viewData.drawLimitTitle:getContentSize()
		local X = viewData.drawLimitTitle:getPositionX()
		viewData.tipsBtn:setPositionX(X +10+ drawLimitTitleSize.width/2)
		viewData.drawLimitTitle:setVisible(true)
		viewData.tipsBtn:setVisible(true)
	else
		viewData.drawLimitTitle:setVisible(false)
		viewData.tipsBtn:setVisible(false)
	end
	if datas.leftSeconds then
		viewData.timeLabel:setString(self:ChangeTimeFormat(checkint(datas.leftSeconds)))
	end
	if datas.activityId then
		viewData.oneDrawBtn:setTag(checkint(datas.activityId))
		viewData.multiDrawBtn:setTag((checkint(datas.activityId)))
	end
	if datas.leftBtnCost then
		viewData.oneDrawCostNums:setString(checkint(datas.leftBtnCost[1].num)) 
		viewData.oneDrawCostGoods:setTexture(CommonUtils.GetGoodsIconPathById(datas.leftBtnCost[1].goodsId))
	end
	if datas.rightBtnCost then
		--viewData.multiDrawCostNums:setString(checkint(datas.rightBtnCost[1].num))
		--viewData.multiDrawCostGoods:setTexture(CommonUtils.GetGoodsIconPathById(datas.rightBtnCost[1].goodsId))
		--display.commonLabelParams(viewData.origCostNums , { text = string.fmt(__('原价 _num_'), {['_num_'] = checkint(datas.rightBtnCost[1].num)})})
		--viewData.origCostGoods:setTexture(CommonUtils.GetGoodsIconPathById(datas.rightBtnCost[1].goodsId))
		--print(CommonUtils.GetGoodsIconPathById(datas.rightBtnCost[1].goodsId))

		display.reloadRichLabel(viewData.multiDrawCostNums  ,{
			c= {
				{ fontSize = 22, ttf = true, font = TTF_GAME_FONT, color = 'ffffff', outline = '#5b3c25', outlineSize = 1, text = checkint(datas.rightBtnCost[1].num) },
				{ img = CommonUtils.GetGoodsIconPathById(datas.rightBtnCost[1].goodsId),scale = 0.2 },
				{text = __('抽十次'), fontSize = 22, ttf = true, font = TTF_GAME_FONT, color = 'ffffff', outline = '#5b3c25', outlineSize = 1}
			}
		})
		CommonUtils.AddRichLabelTraceEffect(viewData.multiDrawCostNums)
		CommonUtils.SetNodeScale(viewData.multiDrawCostNums , {width = 150})


		display.reloadRichLabel(viewData.origCostNums  ,{
			c= {
				{ fontSize = 22, ttf = true, font = TTF_GAME_FONT, color = 'ffffff', outline = '#5b3c25', outlineSize = 1, text = string.fmt(__('原价 _num_'), { ['_num_'] = checkint(datas.rightBtnCost[1].num) }) }

			,{
					img = CommonUtils.GetGoodsIconPathById(datas.rightBtnCost[1].goodsId),scale = 0.2
				}
			}
		})

		CommonUtils.AddRichLabelTraceEffect(viewData.origCostNums)
		CommonUtils.SetNodeScale(viewData.origCostNums , {width = 160})

	end
	if datas.leftBtnCallback then
		viewData.oneDrawBtn:setOnClickScriptHandler(datas.leftBtnCallback)
	end
	if datas.rightBtnCallback then
		viewData.multiDrawBtn:setOnClickScriptHandler(datas.rightBtnCallback)
	end
	if checkint(datas.discount) == 100 then
		viewData.origCostNums:setVisible(false)
		--viewData.origCostGoods:setVisible(false)
		viewData.line:setVisible(false)
	else
		viewData.origCostNums:setVisible(true)
		viewData.line:setVisible(true)
		display.reloadRichLabel(viewData.multiDrawCostNums  ,{
			c= {
				{ fontSize = 22, ttf = true, font = TTF_GAME_FONT, color = 'ffffff', outline = '#5b3c25', outlineSize = 1, text = math.ceil(checkint(datas.rightBtnCost[1].num) * checkint(datas.discount) / 100) },
				{ img = CommonUtils.GetGoodsIconPathById(datas.rightBtnCost[1].goodsId),scale = 0.2 },
				{text = __('抽十次'), fontSize = 22, ttf = true, font = TTF_GAME_FONT, color = 'ffffff', outline = '#5b3c25', outlineSize = 1}
			}
		})
		CommonUtils.AddRichLabelTraceEffect(viewData.multiDrawCostNums)
		CommonUtils.SetNodeScale(viewData.multiDrawCostNums , {width = 150})

	end
	if datas.isFree then
		viewData.oneDrawCostNums:setVisible(false)
		viewData.oneDrawCostGoods:setVisible(false)
		viewData.oneDrawTitle:setVisible(false)
		viewData.freeLabel:setVisible(true)
	else
		viewData.freeLabel:setVisible(false)
	end
	if datas.timesRewards and next(datas.timesRewards) ~= nil then
		viewData.exchangeLayout:setVisible(true)
		viewData.exchangeBtn:setOnClickScriptHandler(handler(self, self.ExchangeBtnCallback))
		self:UpdateExchangeBtnState()
	else
		viewData.exchangeLayout:setVisible(false)
	end
	viewData.tipsBtn:setOnClickScriptHandler(handler(self, self.TipsButtonCallback))
	self:UpdateMoneyBarGoodList(viewData, datas.rightBtnCost[1].goodsId)
end

--[[
更新剩余抽奖次数
--]]
function CommonWheelView:UpdateLeftDrawnTime( drawTimes )
	local viewData = self.viewData_
	local leftDrawnTimes = self.args.leftDrawnTimes
	leftDrawnTimes = checkint(leftDrawnTimes) - checkint(drawTimes)
	display.commonLabelParams(viewData.drawLimitTitle , fontWithColor(18 , { text = string.fmt(__('剩余次数：_num_'), {['_num_'] = leftDrawnTimes}) , paddingW = 20 }))

	local drawLimitTitleSize = viewData.drawLimitTitle:getContentSize()
	local X = viewData.drawLimitTitle:getPositionX()
	viewData.tipsBtn:setPositionX(X +10+ drawLimitTitleSize.width/2)
	self.args.leftDrawnTimes = leftDrawnTimes
end
--[[
刷新抽奖次数
--]]
function CommonWheelView:UpdateDrawnTime( drawnTimes )
	self.args.drawnTimes = self.args.drawnTimes + checkint(drawnTimes)
	self:UpdateExchangeBtnState()
end
--[[
tips按钮回调
--]]
function CommonWheelView:TipsButtonCallback( sender )
	if self.args.tipsBtnCallback then
		self.args.tipsBtnCallback()
	else
		PlayAudioByClickNormal()
		uiMgr:ShowIntroPopup({title = __('转盘活动规则说明'), descr = self.args.tips})
	end
end
--[[
兑换按钮回调
--]]
function CommonWheelView:ExchangeBtnCallback( sender )
	PlayAudioByClickNormal()
	local tag = 110125
	if self.args.type == WHEEL_TYPE.COMMON then 
		tag = 110125
	elseif self.args.type == WHEEL_TYPE.ASSEMBLY_ACTIVITY then

		tag = 110129
	end
	local mediator = require( 'Game.mediator.ActivityPropExchangeMediator').new({data = {activityId = self.args.activityId, leftSeconds = self.args.leftSeconds, tag = tag}})
	AppFacade.GetInstance():RegistMediator(mediator)
end
function CommonWheelView:BackAction()
	PlayAudioByClickClose()
	self:GetViewComponent():CloseHandler()
end

--[[
更新兑换按钮红点状态2
--]]
function CommonWheelView:UpdateExchangeBtnState()
	if self.args.timesRewards and next(self.args.timesRewards) ~= nil then
		local timesRewards = self.args.timesRewards
		local drawnTimes = self.args.drawnTimes
		local showRemindIcon = false
		for k,v in pairs(timesRewards) do
			if checkint(v.hasDrawn) == 0 then
				if checkint(drawnTimes) >= checkint(v.times) then
					showRemindIcon = true
					break
				end
			end
		end
		if showRemindIcon then
			self.viewData_.exchangeRemindIcon:setVisible(true)
		else
			self.viewData_.exchangeRemindIcon:setVisible(false)
		end
	end
end
--[[
付费转盘兑换红点清空
--]]
function CommonWheelView:ChargeWheelRemindIconClear()
	local drawnTimes = checkint(self.args.drawnTimes)
	for k, v in pairs(self.args.timesRewards) do
		if drawnTimes >= checkint(v.times) then
			v.hasDrawn = 1
		end
	end
	self:UpdateExchangeBtnState()
end
--[[
抽奖处理
--]]
function CommonWheelView:DrawAction( datas )
	PlayAudioClip(AUDIOS.UI.ui_activity_wheel.id)
	local viewData = self.viewData_
	-- 判断是否是免费抽奖
	if #datas.rateRewards == 1 and self.args.isFree then
		viewData.oneDrawCostNums:setVisible(true)
		viewData.oneDrawCostGoods:setVisible(true)
		viewData.oneDrawTitle:setVisible(true)
		viewData.freeLabel:setVisible(false)
	end
	-- 刷新抽奖次数
	self:UpdateDrawnTime(#datas.rateRewards)
	-- 刷新剩余抽奖次数
	if checkint(self.args.leftDrawnTimes) > 0 then
		self:UpdateLeftDrawnTime(#datas.rateRewards)
	end

	local rewardIndex = checkint(datas.rateRewards[#datas.rateRewards].id)
	local scene = uiMgr:GetCurrentScene()
	scene:AddViewForNoTouch()
	-- 抽奖特效
	local drawEffect = sp.SkeletonAnimation:create('effects/activity/choujiang.json', 'effects/activity/choujiang.atlas', 1)
	drawEffect:setAnimation(0, 'idle2', false)
	viewData.view:addChild(drawEffect, 10)
	drawEffect:setPosition(viewData.centerPos)
	drawEffect:registerSpineEventHandler(function() 
		drawEffect:unregisterSpineEventHandler(sp.EventType.ANIMATION_END)
		drawEffect:runAction(cc.RemoveSelf:create())
	end,
	sp.EventType.ANIMATION_END)

	-- 抽奖动作
	viewData.arrowIcon:runAction(
		cc.Sequence:create(
			cc.DelayTime:create(1),
			cc.EaseSineIn:create(
				cc.RotateBy:create(0.5, 1080 - viewData.arrowIcon:getRotation()%360)
			),
			cc.RotateBy:create(0.5, 1080),
			cc.EaseSineOut:create(
				cc.RotateBy:create(1, 720+(rewardIndex-1)*viewData.angle)
			),
			-- cc.DelayTime:create(1),
			cc.CallFunc:create(function ()
					scene:RemoveViewForNoTouch()
					local rewards = {}
					for _,v in ipairs(datas.rateRewards) do
						table.insert(rewards, v.rewards[1])
					end
					if datas.closeAction then
						uiMgr:AddDialog('common.RewardPopup', {rewards = rewards, closeCallback = self.args.closeCallback})
					else
						uiMgr:AddDialog('common.RewardPopup', {rewards = rewards})
					end
				end
			)
		)
	)
end
--[[
刷新时间
--]]
function CommonWheelView:UpdateTimeLabel( seconds, activityId )
	if checkint(activityId) ~= checkint(self.args.activityId) then return end
	if checkint(seconds) > 0 then
		local viewData = self.viewData_
		viewData.timeLabel:setString(self:ChangeTimeFormat(checkint(seconds)))
	else
		self:runAction(cc.RemoveSelf:create())
	end
end
--[[
时间转换
--]]
function CommonWheelView:ChangeTimeFormat( seconds )
	local c = nil
	if checkint(seconds) >= 86400 then
		local day = math.floor(seconds/86400)
		local hour = math.floor((seconds%86400)/3600)
		c = string.fmt(__('_num1_天_num2_小时'), {['_num1_'] = tostring(day),['_num2_'] = tostring(hour)})
	else
		local hour   = math.floor(seconds / 3600)
		local minute = math.floor((seconds - hour*3600) / 60)
		local sec    = (seconds - hour*3600 - minute*60)
		c = string.format("%.2d:%.2d:%.2d", hour, minute, sec)
	end
	return c
end
--[[
刷新货币条
--]]
function CommonWheelView:UpdateMoneyBarGoodList(viewData, goodsId)
    local args = {}
    local currency = checkint(goodsId)
    if currency > 0 then
        args.moneyIdMap = {}
		args.moneyIdMap[tostring(currency)] = currency
		args.isEnableGain = true
    end
    viewData.moneyBar:RefreshUI(args)
end
function CommonWheelView:RemoveSelf_()
	if self.args.backBtnCallback then
		self.args.backBtnCallback() 
	else
		PlayAudioByClickClose()
		self:runAction(cc.RemoveSelf:create())
	end
end
function CommonWheelView:onCleanup()
	AppFacade.GetInstance():DispatchObservers(HomeScene_ChangeCenterContainer, "OPEN")
	AppFacade.GetInstance():UnRegistObserver(SHOP_EXIT_SHOP, self)
	AppFacade.GetInstance():UnRegistObserver(SGL.REFRESH_NOT_CLOSE_GOODS_EVENT, self)
	AppFacade.GetInstance():UnRegistObserver(ACTIVITY_PROP_EXCHANGE_EXIT, self)
end
return CommonWheelView