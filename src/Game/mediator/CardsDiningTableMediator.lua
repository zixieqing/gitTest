local Mediator = mvc.Mediator

local CardsDiningTableMediator = class("CardsDiningTableMediator", Mediator)


local NAME = "CardsDiningTableMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local timerMgr = AppFacade.GetInstance():GetManager("TimerManager")
CHOOSE_DELICATE_FOOD = 'CHOOSE_DELICATE_FOOD'
function CardsDiningTableMediator:ctor(param, viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.callback = nil
	self.cardData = {}
	if param then
		if param.callback then
			self.callback = param.callback
		end
		if param.cardData then
			self.cardData = param.cardData
		end
	end
	self.chooseGoodsData = {}
end


function CardsDiningTableMediator:InterestSignals()
	local signals = {
		CHOOSE_DELICATE_FOOD,
		SIGNALNAMES.Hero_EatFood_Callback,
	}

	return signals
end

function CardsDiningTableMediator:ProcessSignal(signal )
	local name = signal:GetName()
	-- print(name)
	-- dump(signal:GetBody())
	if name == CHOOSE_DELICATE_FOOD then
		self:Updataview(signal:GetBody())
	elseif name == SIGNALNAMES.Hero_EatFood_Callback then
		CommonUtils.PlayCardSoundByCardId(self.cardData.cardId, SoundType.TYPE_CARD_EAT_FOOD, SoundChannel.CARD_MANUAL)

		uiMgr:GetCurrentScene():AddViewForNoTouch()
        local body = signal:GetBody()
        for boxId,val in pairs(body.feedLeftTimes) do
            gameMgr:UpdateRemainLoveFeedTimes(self.cardData.id, checkint(boxId), checkint(val))
        end
        --需要更新本地缓存中的卡牌的好感度与好感等级
		if signal:GetBody().favorability then
            local favorability = checkint(signal:GetBody().favorability)
			self.cardData.favorability = favorability
            gameMgr:UpdateCardDataById(self.cardData.id, {favorability = favorability})
		end
		local showContractAction = 1
		if signal:GetBody().favorabilityLevel then
            local favorabilityLevel = checkint(signal:GetBody().favorabilityLevel)
			if checkint(self.cardData.favorabilityLevel) == favorabilityLevel then
				showContractAction = 1
			else
				showContractAction = 2
			end
			self.cardData.favorabilityLevel = favorabilityLevel
            gameMgr:UpdateCardDataById(self.cardData.id, {favorabilityLevel = favorabilityLevel})
		end
		local viewData = self.viewComponent.viewData
		local tempBtnSpine = {}
		for i,v in ipairs(viewData.buttons) do
			if self.chooseGoodsData[tostring(i)] then
				local btnSpine = sp.SkeletonAnimation:create('effects/contract/haogan2.json', 'effects/contract/haogan2.atlas', 1)
				btnSpine:update(0)
				btnSpine:setAnimation(0, 'baodian', false)
				v:getParent():addChild(btnSpine,100)
				btnSpine:setPosition(v:getPosition())

				btnSpine:registerSpineEventHandler(function (event)
			  		if event.animation == "baodian" then
				  		btnSpine:runAction(cc.RemoveSelf:create())
				  	end
				end, sp.EventType.ANIMATION_END)
			end
		end

        local btnSpine = sp.SkeletonAnimation:create('effects/contract/haogan.json', 'effects/contract/haogan.atlas', 1)
		btnSpine:update(0)
		btnSpine:setAnimation(0, 'shengxing3', false)
		self.viewComponent.viewData.view:addChild(btnSpine,100)
		btnSpine:setPosition(cc.p(0,-100))
		btnSpine:registerSpineEventHandler(function (event)
		  	if event.animation == "shengxing3" then
	        	btnSpine:runAction(cc.RemoveSelf:create())
	        end
		end, sp.EventType.ANIMATION_END)

        self:GetFacade():DispatchObservers(CardDetail_UpDataUI_Callback)
        self:GetFacade():DispatchObservers(CardsLove_Callback,1)

		self:InitUi()
		self.chooseGoodsData = {}
		local actionStop = 0
		local resetFood = json.decode(body.requestData.foods)
		for k, v in pairs(resetFood) do
			self:setFoodVisible(checkint(k), v, false, function ()
				actionStop = actionStop + 1
				if actionStop == table.nums(resetFood) then
					local withoutFoods = {}
					for index, foodId in pairs(resetFood) do
						if 0 == body.feedLeftTimes[index] then
						elseif 0 == gameMgr:GetAmountByGoodId(foodId) then
							table.insert(withoutFoods, foodId)
							-- uiMgr:ShowInformationTips(__('食物已用完'))
						else
							self:Updataview({index = tonumber(index), goodsId = foodId})
						end
					end

					local noFoods = {}
					for _, foodId in pairs(withoutFoods) do
						local isHave = false
						for _, showFoodId in pairs(self.chooseGoodsData) do
							if foodId == showFoodId then
								isHave = true
								break
							end
						end
						if not isHave then
							table.insert(noFoods, foodId)
						end
					end
					if next(noFoods) then
						uiMgr:ShowInformationTips(__('有食物吃完了'))
					end
				end
			end)
		end

	end
end


function CardsDiningTableMediator:Updataview( data )
 	local viewData = self.viewComponent.viewData
	local showTimeBtn = viewData.showTimeBtn
	local v = viewData.showFoodsLayout[data.index]
	if v then
		local tempImg = v:getChildByTag(1) -- 阴影图片
		local img = v:getChildByTag(2)	   -- 食物图标
		local tempBtn = v:getChildByTag(3) -- 加号图片

		if data.goodsId then
			if self.chooseGoodsData[tostring(data.index)] then
				self:UpdataGoodsData(self.chooseGoodsData[tostring(data.index)],1)
			end
			self.chooseGoodsData[tostring(data.index)] = data.goodsId
			self:UpdataGoodsData(self.chooseGoodsData[tostring(data.index)],-1)
			-- img:setVisible(true)
			-- tempImg:setVisible(true)
			-- tempBtn:setVisible(false)
			-- img:setTexture(CommonUtils.GetGoodsIconPathById(data.goodsId))
			self:setFoodVisible(data.index, data.goodsId, true)
			viewData.buttons[data.index]:setNormalImage(_res("ui/home/lobby/cooking/restaurant_kitchen_ico_dish_default.png"))
			viewData.buttons[data.index]:setSelectedImage(_res('ui/home/lobby/cooking/restaurant_kitchen_ico_dish_default.png'))
		end
	end
    showTimeBtn:setNormalImage(_res('ui/common/common_btn_orange.png'))
    showTimeBtn:setSelectedImage(_res('ui/common/common_btn_orange.png'))
    display.commonLabelParams(showTimeBtn,fontWithColor(14,{text = __('喂食'),offset = cc.p(0,0)}))
end

function CardsDiningTableMediator:Initial( key )
	self.super.Initial(self,key)
	local scene = uiMgr:GetCurrentScene()
	local viewComponent  = require( 'Game.views.CardsDiningTableView' ).new()-- CardsDiningTableView
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	scene:AddDialog(viewComponent)


    viewComponent.eaterLayer:setOnClickScriptHandler(function(sender)
        PlayAudioByClickNormal()
    	if self.callback then
    		self.callback()
    	end
		AppFacade.GetInstance():UnRegsitMediator("CardsDiningTableMediator")
	end)

    local viewData = self.viewComponent.viewData
    viewData.showTimeBtn:setOnClickScriptHandler(handler(self,self.EatFoodsButtonActions))


	--绑定相关的事件
	for i, v in ipairs( viewData.buttons ) do
		v:setOnClickScriptHandler(handler(self,self.ButtonActions))
	end

	self:InitUi()
end

function CardsDiningTableMediator:InitUi()
	local viewData = self.viewComponent.viewData
	local showTimeBtn = viewData.showTimeBtn

	for i, v in ipairs( viewData.showFoodsLayout ) do
		local tempImg = v:getChildByTag(1) -- 阴影图片
		local img = v:getChildByTag(2)	   -- 食物图标
		local tempBtn = v:getChildByTag(3) -- 加号图片
        local remainNumLabel = v:getChildByName('REMAIN_TIMES_LABEL')
		img:setVisible(false)
		tempImg:setVisible(false)
		tempBtn:setVisible(true)
        remainNumLabel:setVisible(true)
		viewData.buttons[i]:setNormalImage(_res("ui/home/lobby/cooking/restaurant_kitchen_ico_dish_default.png"))
		viewData.buttons[i]:setSelectedImage(_res('ui/home/lobby/cooking/restaurant_kitchen_ico_dish_default.png'))
		if next(self.chooseGoodsData) then
			if self.chooseGoodsData[tostring(i)] then
				img:setVisible(true)
				tempBtn:setVisible(false)
			end
		end

        local remainTimes = gameMgr:GetRemainLoveFeedTimes(self.cardData.id, i)
        if i == CARD_FEED_TYPES.FEED_HOLE_TWO then--第二个槽位解锁条件根据好感度等级判断
			if checkint(self.cardData.favorabilityLevel) < 2 then--好感度等级小于2级锁定
				img:setVisible(true)
				tempImg:setVisible(true)
				tempBtn:setVisible(false)
                remainNumLabel:setVisible(false)
				viewData.buttons[i]:setNormalImage(_res("ui/home/lobby/cooking/restaurant_kitchen_ico_dish_disabled.png"))
				viewData.buttons[i]:setSelectedImage(_res('ui/home/lobby/cooking/restaurant_kitchen_ico_dish_disabled.png'))
			else
                remainNumLabel:setString(string.fmt('_num/_count',{_num = remainTimes, _count = gameMgr:GetUserInfo().feedTimes}))
            end
        elseif i == CARD_FEED_TYPES.FEED_HOLE_MEMEBER then--第三个槽位解锁条件根据是否购买月卡判断
            --判断月卡是否达成的逻辑
            if CommonUtils.getVipTotalLimitByField('feedBox') < 1 then
                img:setVisible(true)
                tempImg:setVisible(true)
                tempBtn:setVisible(false)
                remainNumLabel:setVisible(false)
                viewData.buttons[i]:setNormalImage(_res("ui/home/lobby/cooking/restaurant_kitchen_ico_dish_disabled.png"))
                viewData.buttons[i]:setSelectedImage(_res('ui/home/lobby/cooking/restaurant_kitchen_ico_dish_disabled.png'))
            else
                remainNumLabel:setString(string.fmt('_num/_count',{_num = remainTimes, _count = gameMgr:GetUserInfo().feedTimes}))
            end
        else
            remainNumLabel:setString(string.fmt('_num/_count',{_num = remainTimes, _count = gameMgr:GetUserInfo().feedTimes}))
        end
	end
    showTimeBtn:setNormalImage(_res('ui/common/common_btn_orange.png'))
    showTimeBtn:setSelectedImage(_res('ui/common/common_btn_orange.png'))
    display.commonLabelParams(showTimeBtn,fontWithColor(14,{text = __('喂食'),offset = cc.p(0,0)}))
end

--[[
在橱窗里显示食物
@param index 橱窗位置
@param foodId 食物ID
@param isVisible 是否显示
@param cb 动画结束回调
--]]
function CardsDiningTableMediator:setFoodVisible(index, foodId, isVisible, cb)
	local initPosY = 100
	local moveOffset = 15
	local moveTime = 0.5
	local viewData = self.viewComponent.viewData
	local windows = viewData.showFoodsLayout[index]
	local tempImg = windows:getChildByTag(1) 			-- 阴影图片
	local img = windows:getChildByTag(2)	   	-- 食物图标
	local tempBtn = windows:getChildByTag(3) 	-- 加号图片
	img:setTexture(CommonUtils.GetGoodsIconPathById(foodId))
	tempImg:setVisible(true)
	img:setVisible(true)
	tempBtn:setVisible(false)
	tempImg:stopAllActions()
	img:stopAllActions()
	if isVisible then
		tempImg:setOpacity(0)
		tempImg:runAction(cc.FadeIn:create(moveTime))

		img:setPositionY(initPosY - moveOffset)
		img:setOpacity(0)
		img:runAction(cc.Sequence:create(
			cc.Spawn:create(
				cc.MoveBy:create(moveTime, cc.p(0, moveOffset)),
				cc.FadeIn:create(moveTime)
			),
			cc.CallFunc:create(function ()
				tempImg:setVisible(true)
				if cb then
					cb()
				end
			end)
		))
	else
		tempImg:setOpacity(255)
		tempImg:runAction(cc.FadeOut:create(moveTime))

		img:setPositionY(initPosY)
		img:setOpacity(255)
		img:runAction(cc.Sequence:create(
			cc.Spawn:create(
				cc.MoveBy:create(moveTime, cc.p(0, moveOffset)),
				cc.FadeOut:create(moveTime)
			),
			cc.Hide:create(),
			cc.CallFunc:create(function ()
				tempBtn:setVisible(true)
				if cb then
					cb()
				end
			end)
		))
	end
end

function CardsDiningTableMediator:UpdataGoodsData( goodsId, mount )
	gameMgr:UpdateBackpackByGoodId(goodsId, mount)
end

function CardsDiningTableMediator:EatFoodsButtonActions(sender)
    PlayAudioByClickNormal()
	if next(self.chooseGoodsData) == nil then
		uiMgr:ShowInformationTips(__('未选择食物'))
		return
	end
    self:SendSignal(COMMANDS.COMMAND_Hero_EatFood, { playerCardId = self.cardData.id,foods = json.encode(self.chooseGoodsData)})
end

--[[
主页面tab按钮的事件处理逻辑
@param sender button对象
--]]
function CardsDiningTableMediator:ButtonActions( sender )
    PlayAudioByClickNormal()
	local tag = sender:getTag()
    if tag == CARD_FEED_TYPES.FEED_HOLE_TWO then--第二个槽位解锁条件根据好感度等级判断
        if checkint(self.cardData.favorabilityLevel) < 2 then--好感度等级小于2级锁定
            uiMgr:ShowInformationTips(__('当前槽位需与飨灵好感度等级到达2级自动解锁'))
            return
        end
    end

    if tag == CARD_FEED_TYPES.FEED_HOLE_MEMEBER then
        if CommonUtils.getVipTotalLimitByField('feedBox') < 1 then
            uiMgr:ShowInformationTips(__('当前槽位需会员解锁'))
            if self.callback then
                self.callback()
            end
            AppFacade.GetInstance():UnRegsitMediator('CardsDiningTableMediator')
			if GAME_MODULE_OPEN.NEW_STORE then
				app.uiMgr:showGameStores({storeType = GAME_STORE_TYPE.DIAMOND})
			else
				app.router:Dispatch({name = "HomeMediator"}, {name = "ShopMediator"})
			end
            return
        end
    end
    local remainTimes = gameMgr:GetRemainLoveFeedTimes(self.cardData.id, tag)
    if remainTimes <= 0 then
		uiMgr:ShowInformationTips(__('当前所选槽位次数不足'))
		return
    end
	-- dump(self.cardData)
	local cardTables = CommonUtils.GetConfigAllMess('card', 'card' )[tostring(self.cardData.cardId)]
	local favoriteFood = cardTables.favoriteFood
	local showStarCondition = {}   -- 道具显示星星的条件
	for i,id in ipairs(favoriteFood) do
		showStarCondition[tostring(id)] = i
	end
	showStarCondition[tostring(LUXURY_BENTO_ID)] = table.nums(showStarCondition) + 1
	AppFacade.GetInstance():DispatchObservers(EVENT_CHOOSE_A_GOODS_BY_TYPE, {
		goodsType = GoodsType.TYPE_FOOD,
		callbackSignalName = CHOOSE_DELICATE_FOOD,
		parameter = {index = tag},
		sticky = {LUXURY_BENTO_ID},
		except = {},
		showWaring = false,
		noThingText = __('你还没有精致的食物?'),
		showStarCondition = showStarCondition,  -- map
        cardId = self.cardData.cardId
	})
end

function CardsDiningTableMediator:OnRegist(  )
	local CardsListCommand = require( 'Game.command.CardsListCommand')
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Hero_EatFood, CardsListCommand)

end

function CardsDiningTableMediator:OnUnRegist(  )

	for k,v in pairs(self.chooseGoodsData) do
		self:UpdataGoodsData(v,1)
	end
	--称出命令
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Hero_EatFood)
	local scene = uiMgr:GetCurrentScene()
	scene:RemoveGameLayer(self.viewComponent)
end

return CardsDiningTableMediator
