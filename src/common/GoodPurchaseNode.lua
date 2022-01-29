--[[
主界面顶部道具node
@params{
	id         int  道具id
	disable    bool 是否启用加号
	isEnableGain bool 点击加号是否显示获取路径
}
--]]
---@type GameManager
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")

local shareFacade = AppFacade.GetInstance()

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")

local size = cc.size(190, 40)
local DELTAX = 20
---@class GoodPurchaseNode
local GoodPurchaseNode = class('GoodPurchaseNode', function ()
	local node = CLayout:create()
	node.name = 'common.GoodPurchaseNode'
	node:enableNodeEvents()
	return node
end)

local function CreateView(view )
	local touchBg = display.newLayer(0, 0, {
		color = cc.c4b(200,200,200,0), size = size, enable = true
	})
	view:addChild(touchBg)
	local bg = display.newImageView(_res('ui/home/nmain/common_btn_huobi.png'), DELTAX, size.height * 0.5)
	display.commonUIParams(bg, {ap = display.LEFT_CENTER})
	view:addChild(bg)

	local amountLabel = display.newLabel(46 + DELTAX, size.height * 0.5,
		{ttf = true, font = TTF_GAME_FONT, text = "", fontSize = 21, color = '#ffffff'})
	display.commonUIParams(amountLabel, {ap = display.LEFT_CENTER})
	view:addChild(amountLabel, 6)
	return {
		touchBg = touchBg,
        bg = bg,
		-- actionButton = purchaseBtn,
		amountLabel = amountLabel,
	}
end

function GoodPurchaseNode:ctor( ... )
	self.args = unpack({...})
	self.callback = nil
	self:setContentSize(size)
	self.viewData = CreateView(self)
	self.goodIcon = nil
	self.isDisable = self.args.disable
	self.isEnableGain = self.args.isEnableGain
    -- self:setBackgroundColor(cc.c4b(200,100,100,100))
	--添加icon文件
	local goodIconPath = CommonUtils.GetGoodsIconPathById(self.args.id)
	if utils.isExistent(goodIconPath) then
		local goodIcon = display.newImageView(goodIconPath, DELTAX, size.height * 0.5, {enable = true, cb = function (sender)
			uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = self.args.id, type = 1, isShowHpTips = self.args.isShowHpTips})
		end})
		goodIcon:setScale(0.26)
		self:addChild(goodIcon)
		self.goodIcon = goodIcon
	end
	local disabledTouch = {
		COOK_ID,
		POPULARITY_ID,
		TIPPING_ID,
		-- CAPSULE_VOUCHER_ID,
		KOF_CURRENCY_ID,
		NEW_KOF_CURRENCY_ID,
		WATER_CRYSTALLIZATION_ID,
		WIND_CRYSTALLIZATION_ID,
		RAY_CRYSTALLIZATION_ID,
		FISH_POPULARITY_ID,
		SUPER_GET_ID,
	}
	if not CommonUtils.GetModuleAvailable(MODULE_SWITCH.MONEYTREE) then
		table.insert( disabledTouch, GOLD_ID )
	end
	if not CommonUtils.GetModuleAvailable(MODULE_SWITCH.PAY) then
		table.insert( disabledTouch, DIAMOND_ID )
	end
	if GoodsType.TYPE_ARTIFACR == CommonUtils.GetGoodTypeById(self.args.id) then
		table.insert( disabledTouch, self.args.id )
	end
	if self.isDisable then
		self.viewData.bg:setTexture(_res('ui/common/common_btn_huobi_2'))
	else
		for i,v in ipairs(disabledTouch) do
			if checkint(self.args.id) == v then
				self.viewData.bg:setTexture(_res('ui/common/common_btn_huobi_2'))
				break
			end
		end
	end
    -- if checkint(self.args.id) == COOK_ID or checkint(self.args.id) == POPULARITY_ID or checkint(self.args.id) == TIPPING_ID then
    --     self.viewData.bg:setTexture(_res('ui/common/common_btn_huobi_2'))
    -- end
	self.viewData.touchBg:setOnClickScriptHandler(handler(self,self.purchaseCallback))
	-- self.viewData.actionButton:setOnClickScriptHandler(handler(self,self.purchaseCallback))
	self:setControllable(true)
end

function GoodPurchaseNode:SetCallback( cb )
	self.callback = cb
end

function GoodPurchaseNode:purchaseCallback(sender)
	if not self:isControllable() then return end
	local tag = sender:getTag()
	if tag == GOLD_ID then
		if not uiMgr:GetCurrentScene():getChildByName('MoneyTreeView') and CommonUtils.GetModuleAvailable(MODULE_SWITCH.MONEYTREE) then
			local layer = require( 'Game.views.MoneyTreeView' ).new({callback = function ()
				shareFacade:DispatchSignal(COMMANDS.COMMAND_CACHE_MONEY, {type = GOLD_ID})
			end
			})
			layer:setPosition(display.center)
            -- layer:setLocalZOrder(400)
			-- uiMgr:GetCurrentScene():addChild(layer)
			uiMgr:GetCurrentScene():AddDialog(layer)
			layer:setName('MoneyTreeView')
		end
	elseif tag == HP_ID then
		local totalBuyHpLimit = CommonUtils.getVipTotalLimitByField('buyHpLimit') or {}
		local costNum = (math.ceil((totalBuyHpLimit - gameMgr:GetUserInfo().buyHpRestTimes)/2) - 1)* 5 + 25
		local leftBuyTimes = gameMgr:GetUserInfo().buyHpRestTimes
		uiMgr:AddDialog('Game.views.AddPowerPopup', {payId = HP_ID, callback = function ()
			local hasDiamond = CommonUtils.GetCacheProductNum(DIAMOND_ID)
			if GAME_MODULE_OPEN.NEW_STORE and hasDiamond < costNum then
				app.uiMgr:showDiamonTips()
			else
				shareFacade:DispatchSignal(COMMANDS.COMMAND_CACHE_MONEY, {type = HP_ID})
			end
		end, costNum = costNum, goodsNum = 60, leftBuyTimes = leftBuyTimes})
	elseif tag == DIAMOND_ID then
		if CommonUtils.GetModuleAvailable(MODULE_SWITCH.PAY) and CommonUtils.GetModuleAvailable(MODULE_SWITCH.SHOP) then
			if GAME_MODULE_OPEN.NEW_STORE then
				app.uiMgr:showGameStores({storeType = GAME_STORE_TYPE.DIAMOND})
			else
				app.router:Dispatch({name = "HomeMediator"}, {name = "ShopMediator"})
			end
		end
		-- local tag = 10001
		-- local layer = require('common.RechargePopup').new({mediatorName = NAME, tag = tag})
		-- display.commonUIParams(layer, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
		-- layer:setTag(tag)
  --       uiMgr:GetCurrentScene():AddDialog(layer)
    elseif tag == COOK_ID then
	elseif tag == app.anniversaryMgr:GetAnniversaryTicketID()  then
		uiMgr:AddDialog("common.GainPopup", {goodId =app.anniversaryMgr:GetAnniversaryTicketID()})
	elseif tag == app.anniversaryMgr:GetIncomeCurrencyID()  then
		if CommonUtils.GetModuleAvailable(MODULE_SWITCH.PAY) and CommonUtils.GetModuleAvailable(MODULE_SWITCH.SHOP) then
			if GAME_MODULE_OPEN.NEW_STORE then
				app.uiMgr:showGameStores({storeType = GAME_STORE_TYPE.GIFTS})
			else
				app.router:Dispatch({name = "HomeMediator"}, {name = "ShopMediator", params = { goShopIndex = 'chest' }})
			end
		end
	elseif tag == app.anniversaryMgr:GetRingGameID()  then
		if CommonUtils.GetModuleAvailable(MODULE_SWITCH.PAY) and CommonUtils.GetModuleAvailable(MODULE_SWITCH.SHOP) then
			if GAME_MODULE_OPEN.NEW_STORE then
				app.uiMgr:showGameStores({storeType = GAME_STORE_TYPE.GIFTS})
			else
				app.router:Dispatch({name = "HomeMediator"}, {name = "ShopMediator", params = { goShopIndex = 'chest' }})
			end
		end
   	elseif tag == ACTIVITY_QUEST_HP then
   		AppFacade.GetInstance():DispatchObservers(ACTIVITY_QUEST_BUY_HP)
 	elseif tag == TIPPING_ID then
 	elseif tag == KOF_CURRENCY_ID then
	elseif tag == DOOR_GUN_ID then
		if GAME_MODULE_OPEN.NEW_STORE then
			app.uiMgr:showGameStores({storeType = GAME_STORE_TYPE.PROPS})
		else
			app.router:Dispatch({ name = "SeasonLiveMediator" }, { name = "ShopMediator", params ={  goShopIndex = "goods" } })
		end
	elseif tag == app.summerActMgr:getCurCarnieCoin() then
		uiMgr:AddDialog("common.GainPopup", {goodId = app.summerActMgr:getCurCarnieCoin()})
	elseif tag == SAIMOE_POWER_ID then
		local questHpPrice = CommonUtils.GetConfigAllMess('questHpPrice', 'cardComparison')
		local priceId = table.nums(questHpPrice) - checkint(checktable(self.args.datas).remainBuyTimes) + 1
		local price = questHpPrice[tostring(priceId)] or {}
		local goodsNum = price.questHp
		local costNum = price.price
	
		uiMgr:AddDialog('Game.views.AddPowerPopup', {payId = SAIMOE_POWER_ID, callback = function ()
			if CommonUtils.GetCacheProductNum(DIAMOND_ID) < checkint(price.price) then
				if GAME_MODULE_OPEN.NEW_STORE then
					app.uiMgr:showDiamonTips()
				else
					uiMgr:ShowInformationTips(__('幻晶石不足'))
				end
			else
				if 0 >= checkint(checktable(self.args.datas).remainBuyTimes) then
					uiMgr:ShowInformationTips(__('购买次数不足'))
				else
					shareFacade:DispatchSignal(POST.SAIMOE_BUY_HP.cmdName)
				end
			end
		end, leftBuyTimes = checkint(checktable(self.args.datas).remainBuyTimes), goodsNum = goodsNum, costNum = costNum})
	elseif tag == ARTIFACT_ROAD_TICKET then
		local datas = CommonUtils.GetConfig('goods', 'goods', ARTIFACT_ROAD_TICKET)
		local openType = datas.openType
		for k,v in pairs(openType) do
			if tostring(v) == JUMP_MODULE_DATA.GOODS_SHOP then
				if GAME_MODULE_OPEN.NEW_STORE then
					app.uiMgr:showGameStores({storeType = GAME_STORE_TYPE.PROPS})
				else
					app.router:Dispatch({name = "HomeMediator"}, {name = "ShopMediator", params = {goShopIndex = 'goods'}})
				end
				return
			elseif tostring(v) == JUMP_MODULE_DATA.GIFT_SHOP then
				if GAME_MODULE_OPEN.NEW_STORE then
					app.uiMgr:showGameStores({storeType = GAME_STORE_TYPE.GIFTS})
				else
					app.router:Dispatch({name = "HomeMediator"}, {name = "ShopMediator", params = {goShopIndex = 'chest'}})
				end
				return
			end
		end
		uiMgr:AddDialog("common.GainPopup", {goodId = ARTIFACT_ROAD_TICKET})
	elseif tag == app.murderMgr:GetMurderGoodsIdByKey("murder_ticket_id") then
		app:RetrieveMediator('Router'):Dispatch({name = 'HomeMediator'}, {name = 'activity.murder.MurderStoreMediator'})
	elseif app.activityHpMgr:GetHpDefineMap(tag) then
		if app.activityHpMgr:GetHpDefineMap(tag).isAddHp then
			local goodsId       = tag
			local activityId    = app.activityHpMgr:GetActivityId(goodsId)
			local buyHpConsume  = app.activityHpMgr:GetHpPurchaseConsume(goodsId)
			local totalBuyLimit = app.activityHpMgr:GetHpMaxPurchaseTimes(goodsId)
			local leftBuyTimes  = app.activityHpMgr:GetHpPurchaseAvailableTimes(goodsId)
			local buyHpNum      = app.activityHpMgr:GetHpBuyOnceNum(goodsId) or app.activityHpMgr:GetHpUpperLimit(goodsId)
			uiMgr:AddDialog('Game.views.AddPowerPopup', {payId = goodsId, callback = function ()
				-- draw type
				if app.activityHpMgr:GetHpDefineMap(tag).isDrawType then
					local countdownName  = CommonUtils.getCurrencyRestoreKeyByGoodsId(goodsId)
					local countdownTimer = app.timerMgr:RetriveTimer(countdownName)
					if countdownTimer and checkint(countdownTimer.countdown) > 0 then
						app.uiMgr:ShowInformationTips(string.fmt(__('距离领取还剩_time_秒'), {_time_ = countdownTimer.countdown}))
					else
						if buyHpNum > 0 then
							local hpPurchaseCmd = app.activityHpMgr:GetHpPurchaseCmd(tag)
							app.httpMgr:Post(hpPurchaseCmd.postUrl, hpPurchaseCmd.sglName, {activityId = activityId})
						else
							app.uiMgr:ShowInformationTips(string.fmt(__('领取数量为0')))
						end
					end
					return
				end

				-- buy type
				if next(buyHpConsume) ~= nil and CommonUtils.GetCacheProductNum(buyHpConsume.goodsId) < checkint(buyHpConsume.num) then
					if GAME_MODULE_OPEN.NEW_STORE and checkint(buyHpConsume.goodsId) == DIAMOND_ID then
						app.uiMgr:showDiamonTips()
					else
						local datas = CommonUtils.GetConfig('goods', 'goods', buyHpConsume.goodsId) or {}
						uiMgr:ShowInformationTips(string.fmt(__('_name_不足'), {['_name_'] = tostring(datas.name)}))
					end
				else
					-- 购买次数非无限，并且 剩余购买次数用光
					if -1 ~= totalBuyLimit and 0 >= checkint(leftBuyTimes) and not isJapanSdk() then
						uiMgr:AddDialog("common.GainPopup", {goodId = goodsId})
					else
						local hpPurchaseCmd = app.activityHpMgr:GetHpPurchaseCmd(tag)
						app.httpMgr:Post(hpPurchaseCmd.postUrl, hpPurchaseCmd.sglName, {activityId = activityId})
					end
				end
			end, goodsNum = checkint(buyHpNum), costId = buyHpConsume.goodsId, costNum = buyHpConsume.num, leftBuyTimes = leftBuyTimes, totalBuyLimit = totalBuyLimit})
		else
			uiMgr:AddDialog("common.GainPopup", {goodId = tag})
		end
	elseif self.isEnableGain then
		uiMgr:AddDialog("common.GainPopup", {goodId = tag})
	end
	-- if self.callback then
	-- 	print('aaaaaa')
	-- 	self.callback(sender)
	-- end

end

--[[
刷新整个node
@params goodsId int 道具id
--]]
function GoodPurchaseNode:RefershUI(goodsId)
	self.goodIcon:setTexture(_res(CommonUtils.GetGoodsIconPathById(goodsId)))
	self:updataUi(goodsId)
end

function GoodPurchaseNode:updataUi(tag, params)
	local text = '--'
	if tag == DIAMOND_ID then
		text = tostring(gameMgr:GetUserInfo().diamond)
	elseif tag == GOLD_ID then
		text = tostring(GetMoneyFormat(checkint(gameMgr:GetUserInfo().gold)))
	elseif tag == app.anniversaryMgr:GetIncomeCurrencyID()  then
		text = tostring(checkint(gameMgr:GetUserInfo().voucherNum))
	elseif tag == app.anniversaryMgr:GetRingGameID()  then
		text = tostring(checkint(gameMgr:GetUserInfo().voucherNum))
	elseif tag == app.anniversaryMgr:GetAnniversaryTicketID() then
		text = tostring(gameMgr:GetAmountByGoodId(app.anniversaryMgr:GetAnniversaryTicketID()))
	elseif tag == HP_ID then
		text = string.format('%s / %s', tostring(gameMgr:GetUserInfo().hp), tostring(gameMgr:GetHpMaxLimit()))
	elseif tag == SAIMOE_POWER_ID then
		text = string.format('%s / %s', tostring(checktable(self.args.datas).questHp), tostring(200))
	elseif tag == REPUTATION_ID then
		text = tostring(gameMgr:GetUserInfo().commerceReputation)
	elseif app.activityHpMgr:GetHpDefineMap(tag) then
		local current = app.activityHpMgr:GetHpAmountByHpGoodsId(tag)
		local upLimit = app.activityHpMgr:GetHpUpperLimit(tag)
		if checkint(upLimit) == -1 then
			text = tostring(current)
		else
			text = string.format('%s / %s', tostring(current), tostring(upLimit))
		end
	else
		text = tostring(app.gameMgr:GetAmountByIdForce(tag))
	end
	
	local ww = string.utf8len(text) * 21
	if tag == WATER_CRYSTALLIZATION_ID or tag == WIND_CRYSTALLIZATION_ID or tag == RAY_CRYSTALLIZATION_ID or tag == FISH_POPULARITY_ID then
		display.commonUIParams(self.viewData.amountLabel, {ap = display.CENTER, po = cc.p(80 + DELTAX, size.height * 0.5)})
	elseif tag ~= SAIMOE_POWER_ID and not app.activityHpMgr:GetHpDefineMap(tag) and ww * 0.5 > 60 then
		local offsetX = 44 + (60 - ww * 0.5)
		display.commonUIParams(self.viewData.amountLabel, {ap = display.LEFT_CENTER, po = cc.p(offsetX + 20, size.height * 0.5)})
	else
		if tag == SAIMOE_POWER_ID or app.activityHpMgr:GetHpDefineMap(tag) then
			display.commonUIParams(self.viewData.amountLabel, {ap = display.CENTER, po = cc.p(70 + DELTAX, size.height * 0.5)})
        else
            display.commonUIParams(self.viewData.amountLabel, {ap = display.CENTER, po = cc.p(60 + DELTAX, size.height * 0.5)})
        end
	end
	if tag ~= GOLD_ID then
		self:updataLabelAndIcon(text)
	else
		if uiMgr:GetCurrentScene() and not tolua.isnull(uiMgr:GetCurrentScene()) and uiMgr:GetCurrentScene():GetDialogByName('MoneyTreeView')  then--getChildByName('MoneyTreeView')
			local nums = checkint(text) - checkint(self.viewData.amountLabel:getString())
			if params then
				nums = checkint(gameMgr:GetUserInfo().gold) - checkint(params.originGold)
			end
			self:updataLabelAndIcon(text)
			-- PlayAudioClip(AUDIOS.UI.ui_gold_smash.id)
			uiMgr:GetCurrentScene():GetDialogByName('MoneyTreeView'):UpdataUi({nums = nums,updatauiCallback = function ()
                -- self:updataLabelAndIcon(text)
			end})
		else
			self:updataLabelAndIcon(text)
		end

	end
end

function GoodPurchaseNode:updataLabelAndIcon(text)
    if self.args.animate then
        self.viewData.amountLabel:setString(text)
    else
        if self.viewData.amountLabel:getString() ~= text then--检测数字发生变化是执行动作
            local a = cc.MoveBy:create(0.2,cc.p(0,-8))
            -- local a = cc.ScaleBy:create(0.4, 1.4)
            local b = a:reverse()
            local c = cc.Sequence:create(a,b)
            self.goodIcon:runAction(c)
        end

        self.viewData.amountLabel:setString(text)
        self.goodIcon:setPosition(cc.p(DELTAX, size.height * 0.5))
    end
end


function GoodPurchaseNode:isControllable()
	return self.isControllable_
end
function GoodPurchaseNode:setControllable(isControllable)
	self.isControllable_ = isControllable == true
end


return GoodPurchaseNode
