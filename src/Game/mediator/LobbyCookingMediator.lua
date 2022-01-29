--[[
大堂做菜
--]]
local Mediator = mvc.Mediator

local LobbyCookingMediator = class("LobbyCookingMediator", Mediator)


EVENT_EAT_FEED = 'EVENT_EAT_FEED'--厨师使用新鲜度
EVENT_MAKE_DONE = 'EVENT_MAKE_DONE'--倒计时做完菜后刷新界面
EVENT_EAT_FOODS = 'EVENT_EAT_FOODS'--客人食用制作好的菜品

local NAME = "LobbyCookingMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
function LobbyCookingMediator:ctor(params, viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.cilckRecipeBtn = nil
	self.recipeMess = {}--已经制作好菜信息
	-- dump(params.recipe)
	if params.recipe then
		self.recipe = params.recipe
		local x = 1
		for k,v in pairs(params.recipe) do
			local t = {}
			t.recipeId = k
			t.recipeNum = v
			-- table.insert(self.recipeMess,t)
			self.recipeMess[tostring(x)] = {}
			self.recipeMess[tostring(x)] = t
			x = x + 1
		end

	end
	self.recipeCookingMess = params.recipeCooking or {} ----正在制作菜信息
	-- dump(self.recipeCookingMess)
	-- dump(self.recipeMess)
	self.TtimeUpdateFunc = {} -- 灶台倒计时table
end


function LobbyCookingMediator:InterestSignals()
	local signals = {
	    SIGNALNAMES.Lobby_RecipeCooking_Callback,--做菜
	    SIGNALNAMES.Lobby_AccelerateRecipeCooking_Callback,--加速做菜
	    SIGNALNAMES.Lobby_CancelRecipeCooking_Callback,--取消做菜
	    SIGNALNAMES.Lobby_EmptyRecipe_Callback,--清空菜谱
	    SIGNALNAMES.Lobby_RecipeCookingDone_Callback,
		RESTAURANT_EVENTS.EVENT_AVARAR_DATA_SYS ,
	    EVENT_EAT_FEED,
	    EVENT_MAKE_DONE,
	    EVENT_EAT_FOODS,
	    SIGNALNAMES.IcePlace_AddCard_Callback,
        "COOKING_TIME_COUNT"
	}

	return signals
end

function LobbyCookingMediator:ProcessSignal(signal )
	local name = signal:GetName()
	-- print(name)
	-- dump(signal:GetBody())
	local data = signal:GetBody()
	if name == SIGNALNAMES.Lobby_RecipeCooking_Callback then--做菜
		--更新UI
        if checkint(data.showCaptcha) == 1 then
            AppFacade.GetInstance():DispatchSignal(POST.CAPTCHA_HOME.cmdName)
        end
		local playerCardId = gameMgr:GetUserInfo().chef[tostring(data.requestData.employeeId)]
		self.recipeCookingMess[tostring(playerCardId)] = {}
		self.recipeCookingMess[tostring(playerCardId)].recipeId = data.requestData.recipeId
		self.recipeCookingMess[tostring(playerCardId)].recipeNum = data.requestData.num
		self.recipeCookingMess[tostring(playerCardId)].cd = data.leftSeconds
		gameMgr:UpdateCardDataById(playerCardId, {vigour = data.vigour})
		gameMgr:GetUserInfo().gold = data.gold
		self:GetFacade():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI,{gold = (gameMgr:GetUserInfo().gold)})
		self:UpdateCookUI( data.requestData.employeeId )
		AppFacade.GetInstance():DispatchObservers(RESTAURANT_EVENTS.EVENT_CLOSE_MAKE_RECIPE)

    elseif name == 'COOKING_TIME_COUNT' then
        --计时器更新界面
        self:CheckMakeTimeScheduler(checkint(data.index))
	elseif name == RESTAURANT_EVENTS.EVENT_AVARAR_DATA_SYS then
		self.recipe = data.recipe
		self.recipeCookingMess = data.recipeCooking
		local x = 1
		for k,v in pairs(self.recipe) do
			local t = {}
			t.recipeId = k
			t.recipeNum = v
			self.recipeMess[tostring(x)] = {}
			self.recipeMess[tostring(x)] = t
			x = x + 1
		end
		self:UpdateCookUI(1)
		self:UpdateCookUI(2)
		self:UpdateRecipeUI()
		self:UpdatashopWindowNum()
	elseif name == SIGNALNAMES.Lobby_AccelerateRecipeCooking_Callback then--加速做菜
		-- dump(signal:GetBody())
		local index = 1
		if checkint(data.requestData.employeeId) == 2 then
			index = 1
		elseif checkint(data.requestData.employeeId) == 3 then
			index = 2
		end
		local vv = self.viewData.Tcooks[index]
		local timeBtn = vv.timeBtn
		local buyBtn = vv.buyBtn
        buyBtn:getLabel():setString(' ')
        timeBtn:getLabel():setString(' ')

		local playerCardId = gameMgr:GetUserInfo().chef[tostring(data.requestData.employeeId)]
		local recipeId  = self.recipeCookingMess[tostring(playerCardId)].recipeId
		local recipeNum = self.recipeCookingMess[tostring(playerCardId)].recipeNum
		-- dump(self.recipeCookingMess[tostring(playerCardId)])
		-- dump(self.recipeMess)
		local bool = false
		for i=1,4 do
			if self.recipeMess[tostring(i)] then
				if checkint(self.recipeMess[tostring(i)].recipeId) == checkint(recipeId) then
					bool = true
					break
				end
			end
		end

		for i=1,4 do
			if not self.recipeMess[tostring(i)] and bool == false then
				self.recipeMess[tostring(i)] = {}
				self.recipeMess[tostring(i)].recipeId = recipeId
				self.recipeMess[tostring(i)].recipeNum = recipeNum
				self.recipe[tostring(recipeId)] = recipeNum
				break
			else
				if self.recipeMess[tostring(i)] then
					if checkint(self.recipeMess[tostring(i)].recipeId) == checkint(recipeId) then
						self.recipeMess[tostring(i)].recipeNum = self.recipeMess[tostring(i)].recipeNum + recipeNum
						self.recipe[tostring(recipeId)] = self.recipeMess[tostring(i)].recipeNum
						break
					end
				end
			end
		end
		-- dump(self.recipeMess)
		self.recipeCookingMess[tostring(playerCardId)] = nil
		self:UpdateCookUI(data.requestData.employeeId)
		self:UpdateRecipeUI()
		self:UpdatashopWindowNum()
		gameMgr:GetUserInfo().diamond = data.diamond
		self:GetFacade():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI,{diamond = (gameMgr:GetUserInfo().diamond)})
        local avatarMediator = self:GetFacade():RetrieveMediator('AvatarMediator')
        avatarMediator:PushRequestQueue(6007)

        AppFacade.GetInstance():DispatchObservers(RESTAURANT_EVENTS.EVENT_CLOSED_MAKING_SCHEDULER,index)
		GuideUtils.DispatchStepEvent()

		local cardData = gameMgr:GetCardDataById(playerCardId) or {}
		CommonUtils.PlayCardSoundByCardId(cardData.cardId, SoundType.TYPE_COOKED, SoundChannel.FAST_COOKING)


	elseif name == SIGNALNAMES.Lobby_CancelRecipeCooking_Callback then--取消做菜
		local index = 1
		if data.requestData.employeeId == 2 then
			index = 1
		elseif data.requestData.employeeId == 3 then
			index = 2
		end
		AppFacade.GetInstance():DispatchObservers(RESTAURANT_EVENTS.EVENT_CLOSED_MAKING_SCHEDULER,index)

		local playerCardId = gameMgr:GetUserInfo().chef[tostring(data.requestData.employeeId)]
		self.recipeCookingMess[tostring(playerCardId)] = nil


		local vv = self.viewData.Tcooks[index]
		local timeBtn = vv.timeBtn
		local buyBtn = vv.buyBtn
        buyBtn:getLabel():setString(' ')
        timeBtn:getLabel():setString(' ')

        self:UpdateCookUI(data.requestData.employeeId)
	elseif name == SIGNALNAMES.Lobby_EmptyRecipe_Callback then--清空菜谱
		local messLayout = self.viewData.recipeMessLayout
		messLayout:setVisible(false)
		if data.requestData then
			local tag = self.cilckRecipeBtn:getTag()
			self.recipeMess[tostring(tag)] = nil
			self.recipe[tostring(data.requestData.recipeId)] = nil

			self.viewData.TshowCooks[tag]:setVisible(false)
			AppFacade.GetInstance():DispatchObservers(RESTAURANT_EVENTS.EVENT_EMPTY_ONE_RECIPE)
		else
			self.recipeMess = {}
			self.recipe = {}

			for k,v in ipairs(self.viewData.TshowCooks) do
				v:setVisible(false)
			end
			AppFacade.GetInstance():DispatchObservers(RESTAURANT_EVENTS.EVENT_EMPTY_RECIPE)
		end
		if self.cilckRecipeBtn then
			self.cilckRecipeBtn:setNormalImage(_res("ui/home/lobby/cooking/restaurant_kitchen_ico_dish_default.png"))
			self.cilckRecipeBtn:setSelectedImage(_res("ui/home/lobby/cooking/restaurant_kitchen_ico_dish_default.png"))
			self.cilckRecipeBtn = nil
		end
		self:UpdatashopWindowNum()
	-- elseif name == SIGNALNAMES.Lobby_RecipeCookingDone_Callback then--cd到了请求完成同步数据
	elseif name == EVENT_MAKE_DONE then
		-- dump(data)
		print("EVENT_MAKE_DONE "  )
		local playerCardId = gameMgr:GetUserInfo().chef[tostring(data.requestData.employeeId)]
		local recipeCookingMess = self.recipeCookingMess[tostring(playerCardId)] or {}
		local recipeId = recipeCookingMess.recipeId
		local recipeNum = recipeCookingMess.recipeNum
		local bool = false
		for i=1,4 do
			if self.recipeMess[tostring(i)] then
				if checkint(self.recipeMess[tostring(i)].recipeId) == checkint(recipeId) then
					bool = true
					break
				end
			end
		end
		for i=1,4 do
			if not self.recipeMess[tostring(i)] and bool == false then
				self.recipeMess[tostring(i)] = {}
				self.recipeMess[tostring(i)].recipeId = recipeId
				self.recipeMess[tostring(i)].recipeNum = recipeNum
				self.recipe[tostring(recipeId)] = recipeNum
				break
			else
				if self.recipeMess[tostring(i)] then
					if checkint(self.recipeMess[tostring(i)].recipeId) == checkint(recipeId) then
						self.recipeMess[tostring(i)].recipeNum = checkint(self.recipeMess[tostring(i)].recipeNum) + checkint(recipeNum)
						self.recipe[tostring(recipeId)] = self.recipeMess[tostring(i)].recipeNum
						break
					end
				end
			end
		end
		self.recipeCookingMess[tostring(playerCardId)] = nil
		self:UpdateCookUI(data.requestData.employeeId)
		self:UpdateRecipeUI()
		self:UpdatashopWindowNum()
        local avatarMediator = self:GetFacade():RetrieveMediator('AvatarMediator')
        avatarMediator:PushRequestQueue(6007)

	elseif  name == EVENT_EAT_FEED then--吃新鲜度药刷新界面
		-- dump(EVENT_EAT_FEED)
		for i,v in ipairs(self.viewData.Tcooks) do
			local qExpressionBg = v.qExpressionBg
			local cooksIndex = v.cooksIndex
			local cookId = gameMgr:GetUserInfo().chef[tostring(cooksIndex)]
			if checkint(cookId) == checkint(data.cardId) then
				qExpressionBg:setVisible(false)
				self:AddVigourEffect(v)
			end
		end
	elseif name == EVENT_EAT_FOODS then
		-- dump(data)
		local recipeId = data.recipeId
		local recipeNum = data.recipeNum
		for k,v in pairs(self.recipeMess) do
			if checkint(v.recipeId) == checkint(recipeId) then
				if checkint(v.recipeNum) - checkint(recipeNum) <= 0 then
					self.recipeMess[k] = nil
					self.recipe[tostring(recipeId)] = nil
				else
					v.recipeNum = v.recipeNum - recipeNum
					self.recipe[tostring(recipeId)] = v.recipeNum
				end
				break
			end
		end

		-- dump(self.recipe, 'EVENT_EAT_FOODS22')
		self:UpdateRecipeUI()
		self:UpdatashopWindowNum()

	elseif name == SIGNALNAMES.IcePlace_AddCard_Callback then
        if not signal:GetBody().errcode then
            for k,v in pairs(gameMgr:GetUserInfo().employee) do
                local typee =  CommonUtils.GetConfigNoParser('restaurant','employee',k).type
                if typee == LOBBY_CHEF and checkint(v) == checkint(signal:GetBody().newPlayerCard.playerCardId) then
                    gameMgr:DelCardOnePlace( signal:GetBody().newPlayerCard.playerCardId,CARDPLACE.PLACE_ASSISTANT)
                    gameMgr:SetCardPlace({}, {{id = signal:GetBody().newPlayerCard.playerCardId}}, CARDPLACE.PLACE_ICE_ROOM)
                    if checktable(signal:GetBody().oldPlayerCard).playerCardId then
                        local oldCardId = checkint(signal:GetBody().oldPlayerCard.playerCardId)
                        local ovigour = checkint(signal:GetBody().oldPlayerCard.vigour)
                        gameMgr:UpdateCardDataById(oldCardId, {vigour = ovigour})
                        gameMgr:DelCardOnePlace( oldCardId ,CARDPLACE.PLACE_ICE_ROOM)
                    end
                    --[[ if checkint(body.newPlayerCard.recoverTime) > 0 then ]]
                        -- --添加新的q版到冰场上时，添加计时器
                        -- --添加恢复时间的逻辑
                        -- local id = checkint(body.newPlayerCard.playerCardId)
                        -- timerMgr:RemoveTimer(string.format('ICEROOM_%s',tostring(id))) --移除旧的计时器，活加新计时器
                        -- timerMgr:AddTimer({name = string.format('ICEROOM_%s',tostring(id)),countdown = checkint(body.newPlayerCard.recoverTime), tag = RemindTag.ICEROOM, autoDelete = true, isLosetime = false} )
                    -- end
                    v = nil
                    gameMgr:GetUserInfo().chef[k] = nil
                    gameMgr:GetUserInfo().employee[k] = nil
                    self:UpdateCookUI(k)
                    AppFacade.GetInstance():UnRegsitMediator("AvatarFeedMediator")
                    uiMgr:ShowInformationTips(__('添加成功'))
                    break
                end
            end

        end
	end
end



function LobbyCookingMediator:Initial( key )
	self.super.Initial(self,key)
	local scene = uiMgr:GetCurrentScene()
	local viewComponent  = require( 'Game.views.LobbyCookingView' ).new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	scene:AddDialog(viewComponent)

	local viewComponent = self:GetViewComponent()
	local viewData = viewComponent.viewData
	self.viewData = viewComponent.viewData

	self.viewData.closeBtn:setOnClickScriptHandler(function( sender )
		PlayAudioByClickClose()
		-- AppFacade.GetInstance():DispatchObservers(RESTAURANT_EVENTS.EVENT_CLOSE_MAKE_RECIPE)
		GuideUtils.DispatchStepEvent()
		AppFacade.GetInstance():UnRegsitMediator("LobbyCookingMediator")
	end)

	--桌布按钮
	for i,v in ipairs(viewData.Tbuttons) do
		v:setOnClickScriptHandler(handler(self,self.ChooseRecipeButtonCallback))
	end
	for i,v in ipairs(self.viewData.Tcooks) do
		local stoveBtn = v.stoveBtn
		stoveBtn:setTag(v.cooksIndex)
		stoveBtn:setOnClickScriptHandler(handler(self,self.StoveButtonCallback))

		local buyBtn = v.buyBtn
		buyBtn:setTag(v.cooksIndex)
		buyBtn:setOnClickScriptHandler(handler(self,self.AccelerateButtonCallback))
	end

	self.cookers = {}
	for k,v in pairs(gameMgr:GetUserInfo().chef) do
		table.insert(self.cookers,v)
	end

	viewData.emptyRecipeBtn:setOnClickScriptHandler(handler(self,self.EmptyRecipeButtonCallback))
	viewComponent.eaterLayer:setOnClickScriptHandler(function (sender)
		local messLayout = self.viewData.recipeMessLayout
		messLayout:setVisible(false)
		if self.cilckRecipeBtn then
			self.cilckRecipeBtn:setNormalImage(_res("ui/home/lobby/cooking/restaurant_kitchen_ico_dish_default.png"))
			self.cilckRecipeBtn:setSelectedImage(_res("ui/home/lobby/cooking/restaurant_kitchen_ico_dish_default.png"))
			self.cilckRecipeBtn = nil
		end
	end)


	self:InitCookUI( )
	self:UpdateRecipeUI( )
	self:UpdatashopWindowNum()
end

function LobbyCookingMediator:UpdatashopWindowNum()
	local allRecipeNum = 0
	for k,v in pairs(self.recipe) do
		allRecipeNum = allRecipeNum+v
	end

	local shopWindowLimit = CommonUtils.GetConfigNoParser('restaurant','levelUp',gameMgr:GetUserInfo().restaurantLevel).shopWindowLimit
	shopWindowLimit = app.restaurantMgr:getCookCanScaleFoodsNum( shopWindowLimit )
	self.viewData.desLabel:setString(string.fmt(__('橱窗占位(_Num1_/_Num2_)'),{_Num1_ = allRecipeNum,_Num2_ = shopWindowLimit}))
end

function LobbyCookingMediator:EmptyRecipeButtonCallback(sender)
    PlayAudioByClickNormal()
	if table.nums(self.recipe) > 0 then
		local scene = uiMgr:GetCurrentScene()
		local CommonTip  = require( 'common.CommonTip' ).new({text = __('是否确定清空全部菜谱') ,callback = function ()
			if checkint(gameMgr:GetUserInfo().avatarCacheData.mangerId) <= 0 then
				self:SendSignal(COMMANDS.COMMANDS_Lobby_EmptyRecipe)
			else
				uiMgr:ShowInformationTips(__('在代理店长工作的期间内，要保证橱窗内起码有一道菜品哦~'))
			end
	    end})
		CommonTip:setPosition(display.center)
		scene:AddDialog(CommonTip,10)
	else
		uiMgr:ShowInformationTips(__('当前无菜谱'))
	end
end

function LobbyCookingMediator:CheckMakeTimeScheduler(indexx)
	for k,v in pairs(self.recipeCookingMess) do
		local employeeId = 2
		for kk,vv in pairs(gameMgr:GetUserInfo().chef) do
		 	if checkint(k) == checkint(vv) then
		 		employeeId = kk
		 		break
		 	end
		end
        local index = 1
        if checkint(employeeId) == 2 then
            index = 1
        elseif checkint(employeeId) == 3 then
            index = 2
        end
        local vv = self.viewData.Tcooks[index]
        local timeBtn = vv.timeBtn
        local buyBtn = vv.buyBtn

        -- if indexx then
        if checkint(indexx) == checkint(index) then
            if checkint(v.cd) <= 0 then
                buyBtn:getLabel():setString(' ')
                timeBtn:getLabel():setString(' ')
            else
                timeBtn:getLabel():setString(string.formattedTime(checkint(v.cd),'%02i:%02i:%02i'))
                if checkint(v.cd) <= 180 then
                    buyBtn:getLabel():setString('1')
                else
                    local x = math.ceil(checkint(v.cd)/180)
                    buyBtn:getLabel():setString(tostring(x))
                end
            end
            --[[ self.TtimeUpdateFunc[tostring(index)] = scheduler.scheduleGlobal(function(dt) ]]
            -- if checkint(v.cd) <= 0 then
            -- scheduler.unscheduleGlobal(self.TtimeUpdateFunc[tostring(index)])
            -- -- self:SendSignal(COMMANDS.COMMANDS_Lobby_RecipeCookingDone,{employeeId = employeeId})
            -- buyBtn:getLabel():setString(' ')
            -- timeBtn:getLabel():setString(' ')
            -- else
            -- timeBtn:getLabel():setString(string.formattedTime(checkint(v.cd),'%02i:%02i:%02i'))
            -- if checkint(v.cd) <= 180 then
            -- buyBtn:getLabel():setString('1')
            -- else
            -- local x = math.ceil(checkint(v.cd)/180)
            -- buyBtn:getLabel():setString(tostring(x))
            -- end
            -- end
            -- end
            --[[ end,1.0) ]]
        end
    end
end

function LobbyCookingMediator:ChooseRecipeButtonCallback( sender )
    PlayAudioByClickNormal()
	local tag = sender:getTag()
	if not self.recipeMess[tostring(tag)] then
        local levelDatas = CommonUtils.GetConfigAllMess('levelUp', 'restaurant')
        local maxNum = checkint(checktable(levelDatas[tostring(gameMgr:GetUserInfo().restaurantLevel)]).sellFoodLimit)
        local unlockLevel = 0
		if checkint(tag) > checkint(maxNum) then
			for i,v in pairs(levelDatas) do
				if checkint(v.sellFoodLimit) == checkint(tag) then
                    if unlockLevel == 0 then unlockLevel = checkint(v.level) end
                    if checkint(v.level) < unlockLevel then unlockLevel = checkint(v.level) end
				end
			end
		end
        if unlockLevel > 0 then
            uiMgr:ShowInformationTips(string.fmt(__('餐厅等级达到_num_级可使用该橱窗'),{_num_ = unlockLevel}))
        end
		return
	end

	local messLayout = self.viewData.recipeMessLayout
	if self.cilckRecipeBtn then
		if self.cilckRecipeBtn == sender then
			return
		end
	end

	messLayout:setVisible(true)
	messLayout:setPositionX(sender:getPositionX())
	self.cilckRecipeBtn = sender
	sender:setNormalImage(_res("ui/home/lobby/cooking/restaurant_kitchen_ico_dish_selected.png"))
	sender:setSelectedImage(_res("ui/home/lobby/cooking/restaurant_kitchen_ico_dish_selected.png"))

	local messdata = self.recipeMess[tostring(tag)]
	local recipeId = messdata.recipeId
	local recipeConf = CommonUtils.GetConfig('goods','recipe',recipeId) or {}
	local cookingConf = CommonUtils.GetConfigNoParser('cooking','recipe',recipeId) or {}
	local iconId = checktable(checktable(cookingConf.foods)[1]).goodsId
	local recipeMess = self.viewData.TrecipeMess
	recipeMess.cancelBtn:setTag(tag)
	recipeMess.cancelBtn:setOnClickScriptHandler(handler(self,self.RecipeCancelButtonCallback))
	recipeMess.recipeImg:setTexture(CommonUtils.GetGoodsIconPathById(iconId))
	display.commonLabelParams(recipeMess.nameLabel , {reqW = 220 , text = recipeConf.name})
	--recipeMess.nameLabel:setString(data.name)
	-- dump(messdata)
	local cookingStyleId = cookingConf.cookingStyleId

	-- dump(math.round(messdata['exterior']/400+1,0))
	local tempData = {}
	for i,v in ipairs(gameMgr:GetUserInfo().cookingStyles[cookingStyleId] or {}) do
		if checkint(recipeId) == checkint(v.recipeId) then
			tempData = v
			break
		end
	end
	local profileNum = checkint(checktable(checktable(cookingConf.grade)[tostring(tempData.gradeId)]).popularity)
	if tempData['taste'] then
		profileNum = profileNum + math.floor(tempData['taste']/200)
	end

	local gold = cookingConf.gold
	recipeMess.priceLabel:setString(string.fmt('_num_', {_num_ = tonumber(checktable(checktable(cookingConf.grade)[tostring(tempData.gradeId)]).gold)}))
	recipeMess.profileLabel:setString(string.fmt(('_num_'), {_num_ = profileNum }))
	recipeMess.diningTimeLabel:setString(string.fmt(('_num_'), {_num_ = checkint(cookingConf.eatingTime)}))

	for k,v in pairs(recipeMess.Tlabel) do
		if tempData[k] then
			v:setString(tostring(tempData[k]))
		end
	end
	GuideUtils.DispatchStepEvent()
end

--已制作菜谱详情取消按钮
function LobbyCookingMediator:RecipeCancelButtonCallback( sender )
    PlayAudioByClickNormal()
	local tag = sender:getTag()
	local data = self.recipeMess[tostring(tag)]
	local recipeId = data.recipeId
	local scene = uiMgr:GetCurrentScene()

	-- 没有 代理店长 或  有 并且 有两个以上菜谱
	if checkint(gameMgr:GetUserInfo().avatarCacheData.mangerId) <= 0 or (checkint(gameMgr:GetUserInfo().avatarCacheData.mangerId) > 0 and table.nums(self.recipeMess) > 1) then
		local CommonTip  = require( 'common.CommonTip' ).new({text = __('是否确定清空该菜谱') ,callback = function ()
			self:SendSignal(COMMANDS.COMMANDS_Lobby_EmptyRecipe,{recipeId = tonumber(recipeId)})
		end})
		CommonTip:setPosition(display.center)
		scene:AddDialog(CommonTip, 10)
	else
		uiMgr:ShowInformationTips(__('在代理店长工作的期间内，要保证橱窗内起码有一道菜品哦~'))
	end
end

--更新已做好菜的区域ui
function LobbyCookingMediator:UpdateRecipeUI(  )
	local maxNum = CommonUtils.GetConfigNoParser('restaurant','levelUp',gameMgr:GetUserInfo().restaurantLevel).sellFoodLimit
	for i,v in ipairs(self.viewData.TshowCooks) do
		v:setVisible(true)
		local tempBtn = self.viewData.Tbuttons[i]
		local recipeImg = v:getChildByTag(1)
		local numBtn  = v:getChildByTag(2)
		local tempImg  = v:getChildByTag(3) -- 阴影图片
		local numLabel = numBtn:getLabel()
		recipeImg:setVisible(false)
		numBtn:setVisible(false)
		tempImg:setVisible(false)
		if checkint(i) > checkint(maxNum) then
			tempBtn:setNormalImage(_res('ui/home/lobby/cooking/restaurant_kitchen_ico_dish_disabled.png'))
			tempBtn:setSelectedImage(_res('ui/home/lobby/cooking/restaurant_kitchen_ico_dish_disabled.png'))
		else
			tempBtn:setNormalImage(_res('ui/home/lobby/cooking/restaurant_kitchen_ico_dish_default.png'))
			tempBtn:setSelectedImage(_res('ui/home/lobby/cooking/restaurant_kitchen_ico_dish_default.png'))
			if self.recipeMess[tostring(i)] and next(self.recipeMess[tostring(i)]) ~= nil then
				-- dump(self.recipeMess[tostring(i)])
				local data = self.recipeMess[tostring(i)]
				recipeImg:setVisible(true)
				numBtn:setVisible(true)
				tempImg:setVisible(true)
				-- dump(CommonUtils.GetConfigNoParser('cooking','recipe',data.recipeId))
				local iconId = checktable(checktable(CommonUtils.GetConfigNoParser('cooking','recipe',data.recipeId).foods)[1]).goodsId
				recipeImg:setTexture(CommonUtils.GetGoodsIconPathById(iconId))
				numLabel:setString(data.recipeNum)
			end
		end
	end
end

function LobbyCookingMediator:MakeRecipeCallback(data )
	self:SendSignal(COMMANDS.COMMANDS_Lobby_RecipeCooking,data)
end

--灶台按钮
function LobbyCookingMediator:StoveButtonCallback( sender )
    PlayAudioClip(AUDIOS.UI.ui_select.id)
	local tag = sender:getTag()
	if gameMgr:GetUserInfo().chef[tostring(tag)] then--有厨师
		local cookId = gameMgr:GetUserInfo().chef[tostring(tag)]
		if self.recipeCookingMess[tostring(cookId)] then--在做菜
			self:SkipGuide()
			uiMgr:ShowInformationTips(__('正在做菜ing'))
			return
		end

		local CardData = gameMgr:GetCardDataById(cookId)
		if checkint(CardData.vigour) <= 0 then
			CommonUtils.PlayCardSoundByCardId(CardData.cardId, SoundType.TYPE_CAN_NOT_BATTLE, SoundChannel.LOBBY_VIGOUR)
			self:SkipGuide()
			uiMgr:ShowInformationTips(__('厨师新鲜度不足'))

			return
		end

		local allRecipeNum = 0
		for k,v in pairs(self.recipe) do
			allRecipeNum = allRecipeNum+v
		end

		for k,v in pairs(self.recipeCookingMess) do
			allRecipeNum = allRecipeNum + v.recipeNum
		end


		local shopWindowLimit = CommonUtils.GetConfigNoParser('restaurant','levelUp',gameMgr:GetUserInfo().restaurantLevel).shopWindowLimit
		shopWindowLimit = app.restaurantMgr:getCookCanScaleFoodsNum( shopWindowLimit )
		if checkint(allRecipeNum) >= checkint(shopWindowLimit) then
			self:SkipGuide()
			uiMgr:ShowInformationTips(__('当前橱窗占位已满'))
			return
		end




		local t = {}
		t.recipe = self.recipe
		t.allRecipeNum = allRecipeNum
		t.cardId = cookId
		t.employeeId = tag
		t.recipeCookingMess = self.recipeCookingMess
		t.callback = handler(self,self.MakeRecipeCallback)
		local ChooseRecipeMediator = require( 'Game.mediator.ChooseRecipeMediator' )
		local mediator = ChooseRecipeMediator.new(t)
		self:GetFacade():RegistMediator(mediator)
		GuideUtils.DispatchStepEvent()
	else
		self:SkipGuide()
		uiMgr:ShowInformationTips(__('该灶台无厨师'))
	end
end

function LobbyCookingMediator:SkipGuide()
	if GuideUtils.IsGuiding() and GuideUtils.GetGuidingId() == GUIDE_MODULES.MODULE_LOBBY then
		CommonUtils.ModulePanelIsOpen(true)
		self:GetFacade():BackHomeMediator()
		GuideUtils.ForceShowSkip() --是否显示引导的逻辑
	end
end

--加速立即完成按钮
function LobbyCookingMediator:AccelerateButtonCallback( sender )
    PlayAudioByClickNormal()
	local tag = sender:getTag()
	if checkint(sender:getLabel():getString()) <= gameMgr:GetUserInfo().diamond then
		local scene = uiMgr:GetCurrentScene()
		local CommonTip  = require( 'common.CommonTip' ).new({text = __('是否确定消耗幻晶石立即完成制作该菜谱') ,callback = function ()
			self:SendSignal(COMMANDS.COMMANDS_Lobby_AccelerateRecipeCooking,{employeeId = tonumber(tag)})
	    end})
	    CommonTip:setName('CommonTip')
		CommonTip:setPosition(display.center)
		scene:AddDialog(CommonTip,10)
		GuideUtils.DispatchStepEvent()
	else
		if GuideUtils.IsGuiding() and GuideUtils.GetGuidingId() == GUIDE_MODULES.MODULE_LOBBY then
			self:SkipGuide()
		else
			if GAME_MODULE_OPEN.NEW_STORE then
				app.uiMgr:showDiamonTips()
			else
				local CommonTip  = require( 'common.NewCommonTip' ).new({text = __('幻晶石不足是否去商城购买？'),
					isOnlyOK = false, callback = function ()
						app.router:Dispatch({name = "HomeMediator"}, {name = "ShopMediator"})
					end})
				CommonTip:setPosition(display.center)
				app.uiMgr:GetCurrentScene():AddDialog(CommonTip)
			end
		end

	end
end

--更新做菜的区域ui
function LobbyCookingMediator:UpdateCookUI( index )
	for i,v in ipairs(self.viewData.Tcooks) do
		local timeBtn = v.timeBtn
		local buyBtn = v.buyBtn
		local stoveBtn = v.stoveBtn
		local qBg = v.qBg
		local timeImg = v.timeImg
		local nowCookRecipeLayout = v.nowCookRecipeLayout
		local nowCookImg = v.nowCookImg
		local nowCookNumBtn = v.nowCookNumBtn
		local nowCookNameLabel = v.nowCookNameLabel
		local nowCookCloseBtn = v.nowCookCloseBtn
		local bowlQBg = v.bowlQBg
		local cooksIndex = v.cooksIndex
		local speakBtn = v.speakBtn
		local qExpressionBg = v.qExpressionBg

		if checkint(cooksIndex) == checkint(index) then
			qExpressionBg:setVisible(false)
			speakBtn:setVisible(false)

			if not gameMgr:GetUserInfo().chef[tostring(cooksIndex)] then--没有厨师
				qBg:removeAllChildren()
			else--有厨师
				local cookId = gameMgr:GetUserInfo().chef[tostring(cooksIndex)]
				local CardData = gameMgr:GetCardDataById(cookId)


				if self.recipeCookingMess[tostring(cookId)] then--在做菜
					timeImg:setVisible(true)
					timeBtn:setVisible(true)
					timeBtn:getLabel():setString(string.formattedTime(checkint(self.recipeCookingMess[tostring(cookId)].cd),'%02i:%02i:%02i'))
					buyBtn:setVisible(true)

					if checkint(self.recipeCookingMess[tostring(cookId)].cd) <= 180 then
                    	buyBtn:getLabel():setString('1')
                    else
                    	local x = math.ceil(checkint(self.recipeCookingMess[tostring(cookId)].cd)/180)
                    	buyBtn:getLabel():setString(tostring(x))
                    end

					nowCookRecipeLayout:setVisible(true)

					stoveBtn:setNormalImage(_res('ui/home/lobby/cooking/restaurant_kitchen_btn_active.png'))
					stoveBtn:setSelectedImage(_res('ui/home/lobby/cooking/restaurant_kitchen_btn_active.png'))

					if not bowlQBg:getChildByTag(1) then--effects/kitchenBowl
						local qAvatar = sp.SkeletonAnimation:create('effects/kitchenBowl/restaurant_kitchen_ico_bowl.json', 'effects/kitchenBowl/restaurant_kitchen_ico_bowl.atlas', 0.7)
					    qAvatar:update(0)
					    qAvatar:setTag(1)
					    qAvatar:setAnimation(0, 'idle', true)
					    qAvatar:setPosition(cc.p(bowlQBg:getContentSize().width * 0.5,60))
					    bowlQBg:addChild(qAvatar)
					    bowlQBg:setTouchEnabled(true)
					end

					local recipeId = self.recipeCookingMess[tostring(cookId)].recipeId
					local data = CommonUtils.GetConfig('goods','recipe',recipeId)
					local iconId = CommonUtils.GetConfigNoParser('cooking','recipe',recipeId).foods[1].goodsId
					nowCookImg:setTexture(CommonUtils.GetGoodsIconPathById(iconId))
					nowCookNumBtn:getLabel():setString(tostring(self.recipeCookingMess[tostring(cookId)].recipeNum))
					nowCookNameLabel:setString(data.name)
					nowCookCloseBtn:setTag(index)
					nowCookCloseBtn:setOnClickScriptHandler(handler(self,self.NowCookCloseButtonCallback))
				else
					speakBtn:setVisible(true)
					speakBtn:getLabel():setString(__('请点击灶台'))
					if checkint(CardData.vigour) <= 0 then
						qExpressionBg:setVisible(true)
						speakBtn:getLabel():setString(__('飨灵新鲜度不足'))
					else
						qExpressionBg:setVisible(false)
					end

					timeImg:setVisible(false)
					timeBtn:setVisible(false)
					buyBtn:setVisible(false)
					nowCookRecipeLayout:setVisible(false)
					stoveBtn:setNormalImage(_res('ui/home/lobby/cooking/restaurant_kitchen_btn_start_cook.png'))
					stoveBtn:setSelectedImage(_res('ui/home/lobby/cooking/restaurant_kitchen_btn_start_cook.png'))
					bowlQBg:removeAllChildren()
				end

			end
			break
		end
	end
end

function LobbyCookingMediator:NowCookCloseButtonCallback(sender)
    PlayAudioByClickNormal()
	local scene = uiMgr:GetCurrentScene()
	local tag = sender:getTag()
	self:NowCookClose(tag)
end
function LobbyCookingMediator:NowCookClose(employeeId)
	local CommonTip  = require( 'common.CommonTip' ).new({text = __('是否确定取消制作该菜谱') ,callback = function ()
		self:SendSignal(COMMANDS.COMMANDS_Lobby_CancelRecipeCooking,{employeeId = employeeId})
    end})
	CommonTip:setPosition(display.center)
	CommonTip:setTag(5000)
	local scene = uiMgr:GetCurrentScene()
	scene:AddDialog(CommonTip,10)
end 

--初始化做菜的区域ui
function LobbyCookingMediator:InitCookUI( )
	for i,v in ipairs(self.viewData.Tcooks) do
		local timeBtn = v.timeBtn
		local buyBtn = v.buyBtn
		local stoveBtn = v.stoveBtn
		local qBg = v.qBg
		local timeImg = v.timeImg
		local nowCookRecipeLayout = v.nowCookRecipeLayout
		local nowCookImg = v.nowCookImg
		local nowCookNumBtn = v.nowCookNumBtn
		local nowCookNameLabel = v.nowCookNameLabel
		local nowCookCloseBtn = v.nowCookCloseBtn
		local bowlQBg = v.bowlQBg
		local cooksIndex = v.cooksIndex
		local speakBtn = v.speakBtn
		local qExpressionBg = v.qExpressionBg
		qExpressionBg:setVisible(false)
		speakBtn:setVisible(false)
		timeImg:setVisible(false)
		timeBtn:setVisible(false)
		buyBtn:setVisible(false)
		nowCookRecipeLayout:setVisible(false)
		stoveBtn:setNormalImage(_res('ui/home/lobby/cooking/restaurant_kitchen_btn_start_cook.png'))
		stoveBtn:setSelectedImage(_res('ui/home/lobby/cooking/restaurant_kitchen_btn_start_cook.png'))
		bowlQBg:removeAllChildren()
		qBg:setTouchEnabled(false)
		-- dump(cooksIndex)
		-- dump(gameMgr:GetUserInfo().chef)
		if not gameMgr:GetUserInfo().chef[tostring(cooksIndex)] then--没有厨师
		else--有厨师
			local cookId = gameMgr:GetUserInfo().chef[tostring(cooksIndex)]
			local CardData = gameMgr:GetCardDataById(cookId)
			if not qBg:getChildByTag(1) then

				local cardInfo = gameMgr:GetCardDataById(cookId)
				local qAvatar  = AssetsUtils.GetCardSpineNode({skinId = cardInfo.defaultSkinId, scale = 0.7})
			    qAvatar:update(0)
			    qAvatar:setTag(1)
			    qAvatar:setAnimation(0, 'idle', true)
			    qAvatar:setPosition(cc.p(qBg:getContentSize().width * 0.5,-30))
			    qBg:addChild(qAvatar)
			    qBg:setTouchEnabled(true)
                qBg:setUserTag(cooksIndex)
	    	    qBg:setOnClickScriptHandler(function( sender )
                    PlayAudioByClickNormal()
			        xTry(function()
                        local cookIndex = sender:getUserTag()
                        if gameMgr:GetUserInfo().chef[tostring(cookIndex)] then
                            local AvatarFeedMediator = require( 'Game.mediator.AvatarFeedMediator')
                            local delegate = AvatarFeedMediator.new({id = cookId, type = 1})
                            AppFacade.GetInstance():RegistMediator(delegate)
                            local mediator = AppFacade.GetInstance():RetrieveMediator('AvatarMediator')
                            if mediator then
                                mediator:SetClickCardId(cookId)
                            end
                        end
			        end,__G__TRACKBACK__)
			    end)
			end


			if self.recipeCookingMess[tostring(cookId)] then--在做菜
				timeImg:setVisible(true)
				timeBtn:setVisible(true)
				timeBtn:getLabel():setString(string.formattedTime(checkint(self.recipeCookingMess[tostring(cookId)].cd),'%02i:%02i:%02i'))
				buyBtn:setVisible(true)
				if checkint(self.recipeCookingMess[tostring(cookId)].cd) <= 180 then
                	buyBtn:getLabel():setString('1')
                else
                	local x = math.ceil(checkint(self.recipeCookingMess[tostring(cookId)].cd)/180)
                	buyBtn:getLabel():setString(tostring(x))
                end
				nowCookRecipeLayout:setVisible(true)

				stoveBtn:setNormalImage(_res('ui/home/lobby/cooking/restaurant_kitchen_btn_active.png'))
				stoveBtn:setSelectedImage(_res('ui/home/lobby/cooking/restaurant_kitchen_btn_active.png'))

				if not bowlQBg:getChildByTag(1) then--effects/kitchenBowl
					local qAvatar = sp.SkeletonAnimation:create('effects/kitchenBowl/restaurant_kitchen_ico_bowl.json', 'effects/kitchenBowl/restaurant_kitchen_ico_bowl.atlas', 0.7)
				    qAvatar:update(0)
				    qAvatar:setTag(1)
				    qAvatar:setAnimation(0, 'idle', true)
				    qAvatar:setPosition(cc.p(bowlQBg:getContentSize().width * 0.5,60))
				    bowlQBg:addChild(qAvatar)
				    bowlQBg:setTouchEnabled(true)
				end

				local recipeId = self.recipeCookingMess[tostring(cookId)].recipeId
				local data = CommonUtils.GetConfig('goods','recipe',recipeId)
				local iconId = CommonUtils.GetConfigNoParser('cooking','recipe',recipeId).foods[1].goodsId
				nowCookImg:setTexture(CommonUtils.GetGoodsIconPathById(iconId))
				nowCookNumBtn:getLabel():setString(tostring(self.recipeCookingMess[tostring(cookId)].recipeNum))
				nowCookNameLabel:setString(data.name)
				nowCookCloseBtn:setTag(cooksIndex)
				nowCookCloseBtn:setOnClickScriptHandler(handler(self,self.NowCookCloseButtonCallback))
			else
				speakBtn:setVisible(true)
				speakBtn:getLabel():setString(__('请点击灶台'))
				if checkint(CardData.vigour) <= 0 then
					qExpressionBg:setVisible(true)
					speakBtn:getLabel():setString(__('飨灵新鲜度不足'))
					CommonUtils.PlayCardSoundByCardId(CardData.cardId, SoundType.TYPE_CAN_NOT_BATTLE, SoundChannel.LOBBY_VIGOUR)
				else
					qExpressionBg:setVisible(false)
				end

			end
		end
	end
end

function LobbyCookingMediator:CheckCurretEmployeeId()
	local playerCardId = 0 
	local employeeId = 0 
	for bPlayerCardId, playerCardData in pairs(self.recipeCookingMess or {}) do
		if checkint(playerCardData.recipeId) > 0   then
			playerCardId = checkint(bPlayerCardId) 
			break 
		end
	end
	if playerCardId > 0  then
		for index , aPlayerCardId in pairs(gameMgr:GetUserInfo().chef or {}) do
			if checkint(aPlayerCardId) == playerCardId  then
				employeeId = checkint(index) 
			end
		end 
	end
	return  employeeId
end

function LobbyCookingMediator:GoogleBack(v)
	---@type GameScene
	-- local currentScene = app.uiMgr:GetCurrentScene()
	-- local dialog = currentScene:GetDialogByTag(5000)
	-- if dialog then 
	-- 	return false 
	-- end 	
	-- local  employeeId =  self:CheckCurretEmployeeId()
	-- if employeeId > 0  then
	-- 	self:NowCookClose(employeeId)
	-- 	return false 
	-- end
	local Mediator = app:RetrieveMediator("LobbyCookingMediator")
	if Mediator then
		app:UnRegsitMediator("LobbyCookingMediator")
		return false 
	end
	return true 
end 
function LobbyCookingMediator:AddVigourEffect(v)
	local speakBtn = v.speakBtn
	local qBg = v.qBg
	speakBtn:getLabel():setString(__('请点击灶台'))
    local animateNode = qBg:getChildByName('AddVigourEffect')
    if animateNode then return end
    local animateNode = sp.SkeletonAnimation:create("arts/effects/xxd.json","arts/effects/xxd.atlas", 0.8)
    animateNode:setAnimation(0, 'idle', false)
    animateNode:setName("AddVigourEffect")
    local size = qBg:getContentSize()
    display.commonUIParams(animateNode, {ap = display.CENTER_BOTTOM,po = cc.p(size.width * 0.5, 0)})

	animateNode:registerSpineEventHandler(function (event)
        animateNode:unregisterSpineEventHandler(sp.EventType.ANIMATION_COMPLETE)
        animateNode:runAction(cc.Spawn:create(cc.FadeOut:create(0.1),cc.RemoveSelf:create()))
	end,sp.EventType.ANIMATION_COMPLETE)
    qBg:addChild(animateNode,10)
end



function LobbyCookingMediator:OnRegist(  )
	local LobbyCookingCommand = require( 'Game.command.LobbyCookingCommand')
	self:GetFacade():RegistSignal(COMMANDS.COMMANDS_Lobby_RecipeCooking, LobbyCookingCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMANDS_Lobby_AccelerateRecipeCooking, LobbyCookingCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMANDS_Lobby_CancelRecipeCooking, LobbyCookingCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMANDS_Lobby_EmptyRecipe, LobbyCookingCommand)
	-- self:GetFacade():RegistSignal(COMMANDS.COMMANDS_Lobby_RecipeCookingDone, LobbyCookingCommand)
end

function LobbyCookingMediator:OnUnRegist(  )
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_Lobby_RecipeCooking)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_Lobby_AccelerateRecipeCooking)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_Lobby_CancelRecipeCooking)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_Lobby_EmptyRecipe)
    local scene = uiMgr:GetCurrentScene()
	scene:RemoveGameLayer(self.viewComponent)
end

return LobbyCookingMediator
