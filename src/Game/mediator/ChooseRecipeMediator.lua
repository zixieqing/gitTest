--[[
选择做菜UI
--]]
local Mediator = mvc.Mediator

local ChooseRecipeMediator = class("ChooseRecipeMediator", Mediator)

local NAME = "ChooseRecipeMediator"

-- local styleType = {
-- 	{descr = __('菜系1'), typeDescr = __('菜系1'), tag = 1},
-- 	{descr = __('菜系2'), typeDescr = __('菜系2'), tag = 2},
-- 	{descr = __('菜系3'), typeDescr = __('菜系3'), tag = 3},
-- 	-- {descr = __('菜系4'), typeDescr = __('菜系4'), tag = 4},
-- }


local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
function ChooseRecipeMediator:ctor(params, viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.cellClickTag = 0
	self.cellClickImg = nil
	self.employeeId = params.employeeId or 1
	self.callback = params.callback or nil
	self.cardId = params.cardId or nil
	self.allRecipeNum = params.allRecipeNum or 0
	self.recipe = params.recipe or {}
	self.recipeCookingMess = params.recipeCookingMess or {}
	self.cardData = {}
	self.chooseNum = 1
	self.maxChooseNum = 1
	self.chooseRecipeStyle = nil
	self.checkUnlocRecipeData = {}
	self.isControllable_ = true
end


function ChooseRecipeMediator:InterestSignals()
	local signals = {
		LOBBY_FESTIVAL_ACTIVITY_END,   -- 餐厅活动结束事件
		POST.Activity_Draw_restaurant.sglName,
		POST.COOKING_RECIPE_LIKE.sglName,
	}

	return signals
end

function ChooseRecipeMediator:ProcessSignal(signal )
	local name = signal:GetName()
	local body = signal:GetBody()

	if name == LOBBY_FESTIVAL_ACTIVITY_END then
		local messTouchView = self.viewData.messTouchView
		local lobbyFestivalTipView = self.viewData.lobbyFestivalTipView
		messTouchView:setVisible(false)
		lobbyFestivalTipView:setVisible(false)

		self.chooseRecipeStyle = ALL_RECIPE_STYLE
		self:UpdateStyleTab(true)

	elseif name == POST.Activity_Draw_restaurant.sglName then
		local messTouchView = self.viewData.messTouchView
		messTouchView:setVisible(true)

		self:UpdateStyleTab()

	elseif name == POST.COOKING_RECIPE_LIKE.sglName then
		local requestData  = body.requestData or {}
		local recipeIdList = string.split2(checkstr(requestData.recipeIds), ',')
		if #recipeIdList > 0 then
			-- flip like/unlike status
			for _, recipeId in ipairs(recipeIdList) do
				for _, recipeData in pairs(self.showRecipeData) do
					if checkint(recipeData.recipeId) == checkint(recipeId) then
						recipeData.like = checkint(recipeData.like) == 1 and 0 or 1
						break
					end
				end
			end
		else
			-- unlike all
			for _, recipeData in pairs(self.showRecipeData) do
				recipeData.like = 0
			end
		end

		local gridView = self.viewData.gridView
		for _, cell in ipairs(gridView:getCells()) do
			local recepeData = self.showRecipeData[cell:getTag()]
			local RecipeCell = cell:getChildByTag(2345)
			if RecipeCell then
				RecipeCell:setLike(checkint(recepeData.like) == 1)
			end
		end
	end
end


function ChooseRecipeMediator:Initial( key )
	self.super.Initial(self,key)
	local scene = uiMgr:GetCurrentScene()
	local viewComponent  = require( 'Game.views.ChooseRecipeView' ).new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	scene:AddDialog(viewComponent)
	-- scene:AddGameLayer(viewComponent)
	-- scene:addChild(viewComponent)

	self.cardData = gameMgr:GetCardDataById(self.cardId)
	-- self.businessSkill = CommonUtils.GetBusinessSkillByCardId(self.cardData.cardId)
	-- self.addBuffNum = 0
	-- self.minusTimePre = 0
	-- local skillData = CommonUtils.GetConfigAllMess('assistant','business')[tostring(self.cardData.cardId)].skill
	-- if self.businessSkill then
	-- 	dump(self.businessSkill)
	-- 	for i,v in ipairs(self.businessSkill) do
	-- 		local bool = false
	-- 		for i,vv in ipairs(v.employee) do
	-- 			if checkint(vv) == checkint(LOBBY_CHEF) then
	-- 				bool = true
	-- 			end
	-- 		end

	-- 		if bool == true then
	-- 			local assistantSkillData = CommonUtils.GetConfig('business','assistantSkill',v.skillId)
	-- 			local assistantSkillTypeData = CommonUtils.GetConfig('business','assistantSkillType',assistantSkillData.type[1].targetType)
	-- 			if assistantSkillData.type[1].targetType == 25 then
	-- 				self.addBuffNum = assistantSkillData.type[1].targetNum[1]
	-- 			elseif assistantSkillData.type[1].targetType == 26 then
	-- 				self.minusTimePre = assistantSkillData.type[1].targetNum[1]
	-- 			end
	-- 		end
	-- 	end
	-- end
	-- dump(self.addBuffNum)
	-- dump(self.minusTimePre)
	local viewComponent = self:GetViewComponent()
	local viewData = viewComponent.viewData
	self.viewData = viewComponent.viewData


	self.viewData.closeBtn:setOnClickScriptHandler(function( sender )
        PlayAudioByClickNormal()
		AppFacade.GetInstance():UnRegsitMediator("ChooseRecipeMediator")
	end)

	local gridView = viewData.gridView
	gridView:setDataSourceAdapterScriptHandler(handler(self,self.OnDataSourceAction))


	self.checkUnlocRecipeData = app.cookingMgr:getResearchStyleTable()

	-- for k,v in pairs(gameMgr:GetUserInfo().cookingStyles) do
	-- 	dump(k)
	-- end
	-- dump(self.checkUnlocRecipeData)
	-- cc.UserDefault:getInstance():setStringForKey('chooseRecipeStyle', '')
	-- cc.UserDefault:getInstance():flush()
	local styleDatas = CommonUtils.GetConfigAllMess('style', 'cooking') -- 解析配表
	-- 不是引导中 并且 有餐厅活动
	if app.activityMgr:isDefaultSelectFestivalMenu() then
		self.chooseRecipeStyle = FESTIVAL_RECIPE_STYLE
	-- elseif cc.UserDefault:getInstance():getStringForKey('chooseRecipeStyle') then
	-- 	local chooseRecipeStyle = cc.UserDefault:getInstance():getStringForKey('chooseRecipeStyle', '')
	-- 	self.chooseRecipeStyle = chooseRecipeStyle == '' and self.chooseRecipeStyle or chooseRecipeStyle
    --     -- dump(self.chooseRecipeStyle)
    --     -- dump(gameMgr:GetUserInfo().cookingStyles)
	-- 	if gameMgr:GetUserInfo().cookingStyles[self.chooseRecipeStyle] then
	-- 		if table.nums(gameMgr:GetUserInfo().cookingStyles[self.chooseRecipeStyle]) <= 0 then
	-- 			for k,v in pairs(gameMgr:GetUserInfo().cookingStyles) do
    --                 if table.nums(v) > 0 and checkint(checktable(styleDatas[tostring(k)]).initial) == 1 then
    --                     self.chooseRecipeStyle = k
    --                     break
    --                 end
    --             end
	-- 		end
	-- 	else
	-- 		for k,v in pairs(gameMgr:GetUserInfo().cookingStyles) do
    --             if table.nums(v) > 0 and checkint(checktable(styleDatas[tostring(k)]).initial) == 1 then
    --                 self.chooseRecipeStyle = k
    --                 break
    --             end
    --         end
	-- 	end
	else
		self.chooseRecipeStyle = ALL_RECIPE_STYLE
        --for k,v in pairs(gameMgr:GetUserInfo().cookingStyles) do
        --    if table.nums(v) > 0 and checkint(checktable(styleDatas[tostring(k)]).initial) == 1 then
        --        self.chooseRecipeStyle = k
        --        break
        --    end
        --end
	end

	viewData.makeBtn:setOnClickScriptHandler(handler(self,self.MakeRecipeBtnCallback))
	if isElexSdk() and(not isNewUSSdk()) then
		viewData.priceTagBtn:setOnClickScriptHandler(handler(self,self.PriceTagBtnCallback))
	end
	viewData.btn_minus:setOnClickScriptHandler(handler(self,self.ChooseNumBtnCallback))
	viewData.btn_add:setOnClickScriptHandler(handler(self,self.ChooseNumBtnCallback))
	viewData.styleBtn:setOnClickScriptHandler(handler(self,self.ChooseRecipeStyleBtnCallback))
    viewData.btn_num:setEnabled(true)
    viewData.btn_num:setOnClickScriptHandler(function(sender)
        uiMgr:ShowNumberKeyBoard({
                nums      = 3,
                model     = 2,
                titleText = __('请输入制作数量'),
                callback  = handler(self, self.InputRecipeNumCallback),
                -- defaultContent = self.passwordStr
            })
	end)
	viewData.messTouchView:setOnClickScriptHandler(handler(self,self.MessTouchViewCallback))
	for i,v in ipairs(viewComponent.viewData.styleTab) do
		v:setOnClickScriptHandler(handler(self, self.StyleTypeBtnCallback))
		if v:getTag() == checkint(self.chooseRecipeStyle) then
			self:StyleTypeBtnCallback(v)
		end
	end
end

--[[
筛选按钮回调
--]]
function ChooseRecipeMediator:ChooseRecipeStyleBtnCallback(sender)
    PlayAudioByClickNormal()
	local checked = sender:isChecked()
	self:ShowStyleBoard(checked)
end
--[[
显示筛选排序板
@params visible bool 是否显示排序板
--]]
function ChooseRecipeMediator:ShowStyleBoard(visible)
	self:GetViewComponent().viewData.styleBtn:setChecked(visible)
	if visible == true then
		self:GetViewComponent().viewData.styleBoard:setScaleY(0)
		for i=1,10 do
			self:GetViewComponent().viewData.styleBoard:runAction(cc.Sequence:create(cc.DelayTime:create(i*0.01),cc.CallFunc:create(function ()
					self:GetViewComponent().viewData.styleBoard:setScaleY(i*0.1)
				end)))
		end
		self:GetViewComponent().viewData.styleBoard:setVisible(visible)

		for i,v in ipairs(self:GetViewComponent().viewData.styleTab) do
			if not self.checkUnlocRecipeData[tostring(v:getTag())] then
				local data  = CommonUtils.GetConfigNoParser('cooking','style',v:getTag())
				 v:getLabel():setString(string.format(__('%s(未解锁)'),data.name))
			end
		end

	else
		self:GetViewComponent().viewData.styleBoard:setScaleY(1)
		self:GetViewComponent().viewData.styleBoard:setVisible(visible)
	end
end

--[[
筛选按钮点击回调
--]]
function ChooseRecipeMediator:StyleTypeBtnCallback(sender)
	if not self.isControllable_ then return end
    PlayAudioByClickNormal()
	local tag = sender:getTag()

	if self.checkUnlocRecipeData[tostring(tag)] then
		if self.cellClickImg then
			self.cellClickImg:setVisible(false)
			self.cellClickImg = nil
			self.cellClickTag = 0
			local messLayout = self.viewData.messLayout
			messLayout:setVisible(false)
		end

		local data  = app.cookingMgr:GetStyleTable()[tostring(tag)]
		display.reloadRichLabel(self.viewData.styleLabel , {
			c = {
				fontWithColor(14,{fontSize = 22,text = data.name}),
				{img = _res("ui/home/kitchen/cooking_title_ico_down.png"), ap = cc.p(-0.2, -0.5) }
			}
		})
		CommonUtils.SetNodeScale(self.viewData.styleLabel , {width = 240 })
		CommonUtils.AddRichLabelTraceEffect(self.viewData.styleLabel )
		self:ShowStyleBoard(false)
		self.chooseRecipeStyle = tostring(tag)
		-- cc.UserDefault:getInstance():setStringForKey('chooseRecipeStyle', self.chooseRecipeStyle)
		-- cc.UserDefault:getInstance():flush()
		-- self.showRecipeData = clone(gameMgr:GetUserInfo().cookingStyles[self.chooseRecipeStyle]) or {}
		self.showRecipeData = app.cookingMgr:SortRecipeKindsOfStyleByGradeThenOrder(self.chooseRecipeStyle, true) or {}
		self.viewData.gridView:setCountOfCell(table.nums(self.showRecipeData))
		self.viewData.gridView:reloadData()
	else
		uiMgr:ShowInformationTips(__('该菜系还未解锁'))
	end

end


function ChooseRecipeMediator:InputRecipeNumCallback( str )
    if str == '' then
        str = '1'
    end
    if checkint(str) <= 0 then
        str = 1
    end

    self.chooseNum = checkint(str)
    local recepeData = self.showRecipeData[self.cellClickTag]
	if recepeData == nil then return end
	
    local data = CommonUtils.GetConfigNoParser('cooking','recipe',recepeData.recipeId)
    local btn_num = self.viewData.btn_num
    local vigour = checkint(self.cardData.vigour)
    local num = math.floor( 2*vigour - ( ( math.sqrt(1+8*vigour) - 1 ) / 2 ) )
    if checkint(self.chooseNum) > checkint(num) then
        self.chooseNum = checkint(num)
        uiMgr:ShowInformationTips(__('已达到可消耗最大新鲜度'))
    end

    local makingMax = tonumber(data.grade[tostring(recepeData.gradeId)].makingMax)
    makingMax = app.restaurantMgr:getCookMakeFoodNum( makingMax,self.cardData.id,recepeData.recipeId)
    if checkint(self.chooseNum) > checkint(makingMax) then
        self.chooseNum = checkint(makingMax)
        uiMgr:ShowInformationTips(__('超过该菜谱当前单次制作的最大数量'))
    end

	local needGoldNum = math.round(data.goldConsume - recepeData['exterior']/200,0)--data.goldConsume
    if needGoldNum < 1 then
        needGoldNum  = 1
    end
    if self.recipe then
        local maxNum = CommonUtils.GetConfigNoParser('restaurant','levelUp',gameMgr:GetUserInfo().restaurantLevel).sellFoodLimit

        local tempTab = {}
        for k,v in pairs(self.recipe) do
            tempTab[k] = k
        end
        for k,v in pairs(self.recipeCookingMess) do
            tempTab[tostring(v.recipeId)] = tostring(v.recipeId)
        end
        if table.nums(tempTab) >= checkint(maxNum) then
            local bool = false
            for k,v in pairs(self.recipe) do
                if checkint(k) == checkint(recepeData.recipeId) then
                    bool = true
                    break
                end
            end

            for k,v in pairs(self.recipeCookingMess) do
                if checkint(v.recipeId) == checkint(recepeData.recipeId) then
                    bool = true
                    break
                end
            end

            if bool == false then
                uiMgr:ShowInformationTips(string.fmt(__('当前餐厅等级只能出售_num_种菜品'), {_num_ = maxNum}))
                return
            end
        end
        local shopWindowLimit = CommonUtils.GetConfigNoParser('restaurant','levelUp',gameMgr:GetUserInfo().restaurantLevel).shopWindowLimit
        shopWindowLimit = app.restaurantMgr:getCookCanScaleFoodsNum( shopWindowLimit )
        local canMakeNum = checkint(shopWindowLimit) - checkint(self.allRecipeNum) - self.chooseNum
        if canMakeNum <= 0 then
            uiMgr:ShowInformationTips(__('已达到橱窗最大占位数'))
            return
        end
		
        if (self.chooseNum * needGoldNum) > checkint(gameMgr:GetUserInfo().gold) then
            -- uiMgr:ShowInformationTips(__('已达到可消耗最大金币数'))
            uiMgr:ShowInformationTips(__('您的金币不足~'))
            return
        end

    end
    btn_num:getLabel():setString(tostring(self.chooseNum))

    local priceLabel = self.viewData.priceLabel
    local makeTimeBtn = self.viewData.makeTimeBtn
    local needVigourBtn = self.viewData.needVigourBtn
    priceLabel:setString(tostring(needGoldNum*self.chooseNum))

    local makingTime = data.grade[tostring(recepeData.gradeId)].makingTime
    makingTime = app.restaurantMgr:getReduceMakingTime( makingTime,self.cardData.id,recepeData.recipeId )
    makeTimeBtn:getLabel():setString(string.formattedTime(checkint(makingTime*self.chooseNum),'%02i:%02i:%02i'))
    --TODO-- 消耗新鲜度暂定为一点一个菜 缺少计算公式
    --	飨灵消耗新鲜度根据单次制作的数量不同而不同。
    --消耗新鲜度=ROUNDUP((单次做菜数量^0.5+单次做菜数量)/1.9,0)
    local needvigour = math.ceil( (math.sqrt(self.chooseNum) + self.chooseNum) / 2 )

    needVigourBtn:getLabel():setString(tostring(needvigour))



end

function ChooseRecipeMediator:ChooseNumBtnCallback(sender)
    PlayAudioByClickNormal()
	local tag = sender:getTag()

	if self.chooseNum <= 0 then
		return
	end
	local recepeData = self.showRecipeData[self.cellClickTag]
	local data = CommonUtils.GetConfigNoParser('cooking','recipe',recepeData.recipeId)
	local needGoldNum = math.round(data.goldConsume - recepeData['exterior']/200,0)--data.goldConsume
	if needGoldNum < 1 then
		needGoldNum  = 1
	end
	local btn_num = self.viewData.btn_num
	if tag == 1 then--减
		if checkint(self.chooseNum) > 1 then
			self.chooseNum = self.chooseNum - 1
		end
	elseif tag == 2 then--加
		local vigour = checkint(self.cardData.vigour)
		local num = math.floor( 2*vigour - ( ( math.sqrt(1+8*vigour) - 1 ) / 2 ) )
		if checkint(self.chooseNum) >= checkint(num) then
			uiMgr:ShowInformationTips(__('已达到可消耗最大新鲜度'))
			return
		end

		local makingMax = tonumber(data.grade[tostring(recepeData.gradeId)].makingMax)
		makingMax = app.restaurantMgr:getCookMakeFoodNum( makingMax,self.cardData.id,recepeData.recipeId)
		if checkint(self.chooseNum) >= checkint(makingMax) then
			uiMgr:ShowInformationTips(__('已到达该菜谱当前单次制作的最大数量'))
			return
		end

		

		if self.recipe then
			local maxNum = CommonUtils.GetConfigNoParser('restaurant','levelUp',gameMgr:GetUserInfo().restaurantLevel).sellFoodLimit

			local tempTab = {}
			for k,v in pairs(self.recipe) do
				tempTab[k] = k
			end
			for k,v in pairs(self.recipeCookingMess) do
				tempTab[tostring(v.recipeId)] = tostring(v.recipeId)
			end
			if table.nums(tempTab) >= checkint(maxNum) then
				local bool = false
				for k,v in pairs(self.recipe) do
					if checkint(k) == checkint(recepeData.recipeId) then
						bool = true
						break
					end
				end

				for k,v in pairs(self.recipeCookingMess) do
					if checkint(v.recipeId) == checkint(recepeData.recipeId) then
						bool = true
						break
					end
				end

				if bool == false then
					uiMgr:ShowInformationTips(string.fmt(__('当前餐厅等级只能出售_num_种菜品'), {_num_ = maxNum}))
					return
				end
			end
		end

		local shopWindowLimit = CommonUtils.GetConfigNoParser('restaurant','levelUp',gameMgr:GetUserInfo().restaurantLevel).shopWindowLimit
		shopWindowLimit = app.restaurantMgr:getCookCanScaleFoodsNum( shopWindowLimit )
		local canMakeNum = checkint(shopWindowLimit) - checkint(self.allRecipeNum) - self.chooseNum
		if canMakeNum <= 0 then
			uiMgr:ShowInformationTips(__('已达到橱窗最大占位数'))
			return
		end
		
		if (checkint(self.viewData.priceLabel:getString()) + needGoldNum) > checkint(gameMgr:GetUserInfo().gold) then
			uiMgr:ShowInformationTips(__('已达到可消耗最大金币数'))
			return
		end
		self.chooseNum = self.chooseNum + 1
	end
	btn_num:getLabel():setString(tostring(self.chooseNum))



	local priceLabel = self.viewData.priceLabel
	local makeTimeBtn = self.viewData.makeTimeBtn
	local needVigourBtn = self.viewData.needVigourBtn
	
	priceLabel:setString(tostring(needGoldNum*self.chooseNum))

	local makingTime = data.grade[tostring(recepeData.gradeId)].makingTime
	makingTime = app.restaurantMgr:getReduceMakingTime( makingTime,self.cardData.id,recepeData.recipeId )
	makeTimeBtn:getLabel():setString(string.formattedTime(checkint(makingTime*self.chooseNum),'%02i:%02i:%02i'))
	--TODO-- 消耗新鲜度暂定为一点一个菜 缺少计算公式
	--	飨灵消耗新鲜度根据单次制作的数量不同而不同。
	--消耗新鲜度=ROUNDUP((单次做菜数量^0.5+单次做菜数量)/1.9,0)
	local needvigour = math.ceil( (math.sqrt(self.chooseNum) + self.chooseNum) / 2 )


	needVigourBtn:getLabel():setString(tostring(needvigour))
	GuideUtils.DispatchStepEvent()
end
function ChooseRecipeMediator:PriceTagBtnCallback(sender)
	PlayAudioByClickNormal()

	local node = require("common.PriceDetailBoard").new({targetNode = self:GetViewComponent().viewData.priceTagBtn, recipeData = self.showRecipeData[self.cellClickTag]})
	-- node:setTag(tag)
	display.commonUIParams(node, {po = cc.p(0, 0)})
	node:setLocalZOrder(6200)
	uiMgr:GetCurrentScene():AddDialog(node)
end


function ChooseRecipeMediator:MakeRecipeBtnCallback(sender)
    PlayAudioByClickNormal()
	if self.chooseNum <= 0 then
		return
	end
	if self.chooseNum > self.maxChooseNum then
		uiMgr:ShowInformationTips(__('超过可制作数量'))
		return
	end

	if checkint(self.viewData.priceLabel:getString()) > checkint(gameMgr:GetUserInfo().gold) then
		if GuideUtils.IsGuiding() and GuideUtils.GetGuidingId() ==  GUIDE_MODULES.MODULE_LOBBY  then
			CommonUtils.ModulePanelIsOpen(true)
			self:GetFacade():BackHomeMediator()
			GuideUtils.ForceShowSkip() --是否显示跳过引导
		end
		uiMgr:ShowInformationTips(__('金币数量不足'))
		return
	end
	local recepeData = self.showRecipeData[self.cellClickTag]
	if self.recipe then
		local maxNum = CommonUtils.GetConfigNoParser('restaurant','levelUp',gameMgr:GetUserInfo().restaurantLevel).sellFoodLimit
		local tempTab = {}
		for k,v in pairs(self.recipe) do
			tempTab[k] = k
		end
		for k,v in pairs(self.recipeCookingMess) do
			tempTab[tostring(v.recipeId)] = tostring(v.recipeId)
		end
		if table.nums(tempTab) >= checkint(maxNum) then
			local bool = false
			for k,v in pairs(self.recipe) do
				if checkint(k) == checkint(recepeData.recipeId) then
					bool = true
					break
				end
			end
			for k,v in pairs(self.recipeCookingMess) do
				if checkint(v.recipeId) == checkint(recepeData.recipeId) then
					bool = true
					break
				end
			end

			if bool == false then
				uiMgr:ShowInformationTips(string.fmt(__('当前餐厅等级只能出售_num_种菜品'), {_num_ = maxNum}))
				return
			end
		end
	end

	local shopWindowLimit = CommonUtils.GetConfigNoParser('restaurant','levelUp',gameMgr:GetUserInfo().restaurantLevel).shopWindowLimit
	shopWindowLimit = app.restaurantMgr:getCookCanScaleFoodsNum( shopWindowLimit )
	local canMakeNum = checkint(shopWindowLimit) - checkint(self.allRecipeNum) - self.chooseNum
	if canMakeNum < 0 then
		uiMgr:ShowInformationTips(__('已达到橱窗最大占位数'))
		return
	end

	local data = CommonUtils.GetConfigNoParser('cooking','recipe',recepeData.recipeId)
	local makingMax = tonumber(data.grade[tostring(recepeData.gradeId)].makingMax)
	makingMax = app.restaurantMgr:getCookMakeFoodNum( makingMax,self.cardData.id ,recepeData.recipeId)
	if checkint(self.chooseNum) > checkint(makingMax) then
		uiMgr:ShowInformationTips(__('已达到该菜谱能制作最大数量'))
		return
	end

	-- local data = self.showRecipeData[self.cellClickTag]
	-- local data = CommonUtils.GetConfigNoParser('cooking','recipe',recepeData.recipeId)
	if self.callback then
		local t = {}
		t.employeeId = self.employeeId
		t.recipeId = recepeData.recipeId
		t.num = self.chooseNum
		self.callback(t)
	end
	GuideUtils.DispatchStepEvent()
	AppFacade.GetInstance():UnRegsitMediator("ChooseRecipeMediator")
end

function ChooseRecipeMediator:UpdataMessUI(index)
	local recepeData = self.showRecipeData[index]
	local messLayout = self.viewData.messLayout
	local makeBtn = self.viewData.makeBtn
	local nameLabel = self.viewData.nameLabel
	local saleLabel = self.viewData.saleLabel
	local diningTimeLabel =  self.viewData.diningTimeLabel
	local diningDesLabel =  self.viewData.diningDesLabel
	local TmessLabe = self.viewData.TmessLabe
	local priceLabel = self.viewData.priceLabel
	local btn_num = self.viewData.btn_num
	local makeTimeBtn = self.viewData.makeTimeBtn
	local needVigourBtn = self.viewData.needVigourBtn
	local canMakeLabel = self.viewData.canMakeLabel
	local img_money_type = self.viewData.img_money_type
	local messTouchView = self.viewData.messTouchView
	local lobbyFestivalTipView = self.viewData.lobbyFestivalTipView

	for k,v in pairs(TmessLabe) do
		if recepeData[k] then
			v:setString(tostring(recepeData[k]))
		end
	end
    --128479
	-- local data = CommonUtils.GetConfig('goods','recipe',recepeData.recipeId)
	local data = CommonUtils.GetConfigNoParser('cooking','recipe',recepeData.recipeId)
	--
	local needGoldNum = math.round(data.goldConsume - recepeData['exterior']/200,0)--data.goldConsume
	if needGoldNum < 1 then
		needGoldNum  = 1
	end

	-- getReduceMakingTime
	local makingTime = data.grade[tostring(recepeData.gradeId)].makingTime
	local makingMax = tonumber(data.grade[tostring(recepeData.gradeId)].makingMax)

	makingTime = app.restaurantMgr:getReduceMakingTime( makingTime,self.cardData.id,recepeData.recipeId )
	-- dump(makingMax)
	makingMax = app.restaurantMgr:getCookMakeFoodNum( makingMax,self.cardData.id,recepeData.recipeId )

	local shopWindowLimit = CommonUtils.GetConfigNoParser('restaurant','levelUp',gameMgr:GetUserInfo().restaurantLevel).shopWindowLimit
	shopWindowLimit = app.restaurantMgr:getCookCanScaleFoodsNum( shopWindowLimit )
	local canMakeNum = checkint(shopWindowLimit) - checkint(self.allRecipeNum)

	-- dump(self.cardData.id)
	-- dump(makingMax)
	-- local vigour =  app.restaurantMgr:getCardVigourLimit( self.cardData.id )

	local vigour = checkint(self.cardData.vigour)
	local num = math.floor( 2*vigour - ( ( math.sqrt(1+8*vigour) - 1 ) / 2 ) )
	dump(num)

	local x = 0
	local y = 0
	-- local z = 0
	if makingMax <= checkint(num) then
		x = makingMax
	else
		x = checkint(num)
	end

	if x <= canMakeNum then
		y = x
	else
		y = canMakeNum
	end
	
	local price = needGoldNum * y
	local ownGoldCount = CommonUtils.GetCacheProductNum(GOLD_ID)
	if ownGoldCount < price then
		y = math.floor( ownGoldCount / data.goldConsume )
	end
	self.chooseNum = y
	self.maxChooseNum = y
    -- data.goldConsume
	canMakeLabel:setString(string.fmt(__('本菜单一次可制作：_num_'),{_num_ = makingMax}))
	btn_num:getLabel():setString(tostring(self.chooseNum))
	priceLabel:setString(tostring(needGoldNum*self.chooseNum))
	makeTimeBtn:getLabel():setString(string.formattedTime(checkint(makingTime*self.chooseNum),'%02i:%02i:%02i'))
	nameLabel:setString(CommonUtils.GetConfig('goods','recipe',recepeData.recipeId).name)
	local needvigour = math.ceil( (math.sqrt(self.chooseNum) + self.chooseNum) / 2 )
	needVigourBtn:getLabel():setString(tostring(needvigour))

	if ( not isNewUSSdk()) and isElexSdk() then
		local member = app.gameMgr:GetUserInfo().member
		local times = 2
		-- 召唤月卡
		local memberInfo1 = member['1']
		if memberInfo1 then
			times = times + 2
		end
		-- 冒险月卡
		local memberInfo2 = member['2']
		if memberInfo2 then
			times = times + 3
		end
		-- 皇家经营特权
		local memberInfo3 = member['3']
		if memberInfo3 then
			times = times + 0.1
		end

		saleLabel:setString(string.fmt('_num_', {_num_ = tonumber(data.grade[tostring(recepeData.gradeId)].gold) * times}))
	else
		saleLabel:setString(string.fmt('_num_', {_num_ = tonumber(data.grade[tostring(recepeData.gradeId)].gold)}))
	end
	img_money_type:setPositionX(saleLabel:getPositionX() + saleLabel:getBoundingBox().width + 5 )
	diningTimeLabel:setString(tostring(data.eatingTime))
	diningDesLabel:setPositionX(diningTimeLabel:getPositionX() + diningTimeLabel:getBoundingBox().width + 5 )

	-- 餐厅活动 开启 并且 是餐厅活动菜谱

	local recepeFestivalData = app.activityMgr:getLobbyFestivalMenuData(recepeData.recipeId)
	if app.activityMgr:isOpenLobbyFestivalActivity() and recepeFestivalData ~= nil then
		lobbyFestivalTipView:setVisible(true)
		messTouchView:setVisible(true)
		
		self:UpdateLobbyFestivalTipUi(recepeFestivalData, recepeData)

	else
		messTouchView:setVisible(false)
		lobbyFestivalTipView:setVisible(false)
	end

end

function ChooseRecipeMediator:MessTouchViewCallback(sender)
	local view = self.viewData.lobbyFestivalTipView
	view:setVisible(not view:isVisible())
end

function ChooseRecipeMediator:UpdateLobbyFestivalTipUi( recepeFestivalData, recepeData)
	local lobbyFestivalTipView = self.viewData.lobbyFestivalTipView
	lobbyFestivalTipView:updateUi(recepeFestivalData, recepeData)
end

function ChooseRecipeMediator:UpdateStyleTab(isUpdateDesc)
	self.isControllable_ = false
	local viewComponent = self:GetViewComponent()
	local styleTabViewData = viewComponent:CreateStyleTab(viewComponent.viewData.styleBoard)
	viewComponent.viewData.styleTab = styleTabViewData.styleTab
	viewComponent.viewData.splitLines = styleTabViewData.splitLines
	self.viewData.styleBtn:setChecked(false)
	self.checkUnlocRecipeData = app.cookingMgr:getResearchStyleTable()
	self.isControllable_ = true
	for i,v in ipairs(viewComponent.viewData.styleTab) do
		v:setOnClickScriptHandler(handler(self, self.StyleTypeBtnCallback))
		if isUpdateDesc then
			print(v:getTag(), checkint(self.chooseRecipeStyle))
			if checkint(v:getTag()) == checkint(self.chooseRecipeStyle) then
				self:StyleTypeBtnCallback(v)
			end
		end
	end

end

function ChooseRecipeMediator:onClickRecipeCellHandler_(sender)
	local RecipeCell = sender:getParent()
	local tag = RecipeCell:getParent():getTag()
	if self.cellClickTag == tag then return end
	PlayAudioByClickNormal()
	
	if self.cellClickImg then
		self.cellClickImg:setVisible(false)
	end
	self.cellClickTag = tag
	local gridView = self.viewData.gridView
	local img =  gridView:cellAtIndex(tag-1):getChildByTag(2345)
	if img then
		img.selectImg:setVisible(true)
	end
	self.cellClickImg = img.selectImg
	local messLayout = self.viewData.messLayout
	messLayout:setVisible(true)
	self:UpdataMessUI(tag)
	GuideUtils.DispatchStepEvent()
end

function ChooseRecipeMediator:onClickRecipeCellLikeButtonHandler_(sender)
	PlayAudioByClickNormal()
	local RecipeCell = sender:getParent()
	local tag = RecipeCell:getParent():getTag()
	local recepeData = self.showRecipeData[tag]
	if checkstr(recepeData.recipeId) ~= '' then
		self:SendSignal(POST.COOKING_RECIPE_LIKE.cmdName, {recipeIds = recepeData.recipeId})
	end
end


function ChooseRecipeMediator:OnDataSourceAction(c, i)
	local cell = c
	local index = i + 1
	local RecipeCell = nil
	local selectImg = nil
	local recepeData = self.showRecipeData[index]
	local iconId = CommonUtils.GetConfigNoParser('cooking','recipe',recepeData.recipeId).foods[1].goodsId
	if nil == cell then
		cell = CGridViewCell:new()
		cell:setContentSize(self.viewData.gridView:getSizeOfCell())

		RecipeCell = require('Game.views.RecipeCell').new()

		RecipeCell:setPosition(utils.getLocalCenter(cell))
		display.commonUIParams(RecipeCell.hotspotBtn, {cb = handler(self, self.onClickRecipeCellHandler_)})
		display.commonUIParams(RecipeCell.likeBtn, {cb = handler(self, self.onClickRecipeCellLikeButtonHandler_)})
		cell:addChild(RecipeCell)
		RecipeCell:setTag(2345)

		RecipeCell.recipeImg:setTexture(CommonUtils.GetGoodsIconPathById(iconId))-- recepeData.recipeId
		RecipeCell.nameLabel:setString(CommonUtils.GetConfig('goods','recipe',recepeData.recipeId).name)
		local path = _res('ui/home/kitchen/cooking_grade_ico_'..recepeData.gradeId..'.png')
		if not utils.isExistent(path) then
			path = _res('ui/home/kitchen/cooking_grade_ico_1.png')
		end
		RecipeCell.qualityImg:setTexture(path)

	else
		RecipeCell = cell:getChildByTag(2345)
		RecipeCell.recipeImg:setTexture(CommonUtils.GetGoodsIconPathById(iconId))-- recepeData.recipeId
		RecipeCell.nameLabel:setString(CommonUtils.GetConfig('goods','recipe',recepeData.recipeId).name)
		local path = _res('ui/home/kitchen/cooking_grade_ico_'..recepeData.gradeId..'.png')
		if not utils.isExistent(path) then
			path = _res('ui/home/kitchen/cooking_grade_ico_1.png')
		end
		RecipeCell.qualityImg:setTexture(path)
	end

	RecipeCell:setLike(checkint(recepeData.like) == 1)
	if index == self.cellClickTag then
		RecipeCell.selectImg:setVisible(true)
		self.cellClickImg = RecipeCell.selectImg
	else
		RecipeCell.selectImg:setVisible(false)
	end

	-- cell:setBackgroundColor(cc.c4b(0, 100, 0, 100))
	cell:setTag(index)

	return cell
end
function ChooseRecipeMediator:GoogleBack(v)
	local Mediator = app:RetrieveMediator("ChooseRecipeMediator")
	if Mediator then
		app:UnRegsitMediator("ChooseRecipeMediator")
		return false 
	end
	return true 
end 

function ChooseRecipeMediator:OnRegist(  )
	regPost(POST.COOKING_RECIPE_LIKE)
end

function ChooseRecipeMediator:OnUnRegist(  )
	--称出命令
	unregPost(POST.COOKING_RECIPE_LIKE)
	local scene = uiMgr:GetCurrentScene()
	scene:RemoveGameLayer(self.viewComponent)
end

return ChooseRecipeMediator
