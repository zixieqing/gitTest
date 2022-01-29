--[[
 * author : liuzhipeng
 * descpt : 活动 皮肤嘉年华 秒杀活动Mediator
--]]
local ActivitySkinCarnivalFlashSaleMediator = class('ActivitySkinCarnivalFlashSaleMediator', mvc.Mediator)
local NAME = "activity.skinCarnival.ActivitySkinCarnivalFlashSaleMediator"
local SKIN_CARNIVAL_FLASH_SALE_COUNTDOWN = 'SKIN_CARNIVAL_FLASH_SALE_COUNTDOWN'
--[[
@params map {
    id         int id
    activityId int 活动id
    group      int 组别
    currency   int 直接购买用的货币
    price      int 直接购买的价格
    skinId     int 皮肤id
    summaryId  int 总表id
    title      int 活动标题
    type       int 活动类型
    pos        pos 动画开始坐标
}
--]]
function ActivitySkinCarnivalFlashSaleMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.homeData = checktable(params)
    self.flashSaleData = nil 
end

-------------------------------------------------
------------------ inheritance ------------------
function ActivitySkinCarnivalFlashSaleMediator:Initial( key )
	self.super.Initial(self, key)
	local viewComponent  = require('Game.views.activity.skinCarnival.ActivitySkinCarnivalFlashSaleView').new({group = self.homeData.group})
	viewComponent:setPosition(display.center)
	app.uiMgr:GetCurrentScene():AddDialog(viewComponent)
    self:SetViewComponent(viewComponent)
    local viewData = viewComponent:GetViewData()
    viewComponent.eaterLayer:setOnClickScriptHandler(handler(self, self.EaterLayerCallback))
    viewData.titleBtn:setOnClickScriptHandler(handler(self, self.TitleButtonCallback))
    viewData.switchBtn:setOnClickScriptHandler(handler(self, self.SwitchButtonCallback))
    viewData.storyBtn:setOnClickScriptHandler(handler(self, self.StoryButtonCallback))
    viewData.buyBtn:setOnClickScriptHandler(handler(self, self.BuyButtonCallback))
    viewData.rewardBtn:setOnClickScriptHandler(handler(self, self.RewardButtonCallback))
    self:RefreshSkin()
    viewComponent:EnterAction(self:GetHomeData().pos)
end

function ActivitySkinCarnivalFlashSaleMediator:InterestSignals()
    local signals = {
        POST.SKIN_CARNIVAL_FLASH_SALE.sglName,
        POST.SKIN_CARNIVAL_FLASH_SALE_RUSH.sglName,
        POST.SKIN_CARNIVAL_FLASH_SALE_BUY.sglName,
        POST.SKIN_CARNIVAL_FLASH_SALE_DRAW.sglName,
        ACTIVITY_SKIN_CARNIVAL_FLASH_SALE_CHOOSE_REWRARD, 
	}
	return signals
end
function ActivitySkinCarnivalFlashSaleMediator:ProcessSignal( signal )
    local name = signal:GetName()
    local body = signal:GetBody()
    if name == POST.SKIN_CARNIVAL_FLASH_SALE.sglName then -- home
        self:SetFlashSaleData(body)
        self:InitView()
        -- 开启定时器
        self:StartTimer()
    elseif name == POST.SKIN_CARNIVAL_FLASH_SALE_RUSH.sglName then -- 秒杀购买
        -- 判断是否购买成功
        if body.rewards then
            -- 领奖
            app.uiMgr:AddDialog('common.RewardPopup', body)
            -- 扣除道具
            local flashSaleConfig = CommonUtils.GetConfig('skinCarnival', 'flashSale', body.requestData.flashSaleId)
            CommonUtils.DrawRewards({
                {goodsId = flashSaleConfig.currency, num = -flashSaleConfig.price}
            })
            -- 刷新页面
            self:RefreshBtnState()
            self:RefreshRemindIcon()
        else
            app.uiMgr:ShowInformationTips(__('库存不足'))
            self:EnterLayer()
        end
    elseif name == POST.SKIN_CARNIVAL_FLASH_SALE_BUY.sglName then -- 原价购买
        -- 领奖
        app.uiMgr:AddDialog('common.RewardPopup', body)
        -- 扣除道具
        local homeData = self:GetHomeData()
        CommonUtils.DrawRewards({
			{goodsId = homeData.currency, num = -homeData.price}
        })
        -- 刷新页面
        self:RefreshBtnState()
        self:RefreshRemindIcon()
    elseif name == POST.SKIN_CARNIVAL_FLASH_SALE_DRAW.sglName then -- 领取奖励
        app.uiMgr:AddDialog('common.RewardPopup', body)
        local flashSaleData = self:GetFlashSaleData()
        flashSaleData.optionRewardDrawn = 1
        self:RefreshBtnState()
        self:RefreshRemindIcon()
    elseif name == ACTIVITY_SKIN_CARNIVAL_FLASH_SALE_CHOOSE_REWRARD then -- 奖励选择
        if app.cardMgr.IsHaveCardSkin(self:GetSkinId()) then
            local homeData = self:GetHomeData()
            self:SendSignal(POST.SKIN_CARNIVAL_FLASH_SALE_DRAW.cmdName, {activityId = homeData.activityId, group = homeData.group, option = body.id})
        else
            app.uiMgr:ShowInformationTips(__('皮肤未获得'))
        end
    end
end

function ActivitySkinCarnivalFlashSaleMediator:OnRegist()
    regPost(POST.SKIN_CARNIVAL_FLASH_SALE)
    regPost(POST.SKIN_CARNIVAL_FLASH_SALE_RUSH)
    regPost(POST.SKIN_CARNIVAL_FLASH_SALE_BUY)
    regPost(POST.SKIN_CARNIVAL_FLASH_SALE_DRAW)
    self:EnterLayer()
end
function ActivitySkinCarnivalFlashSaleMediator:OnUnRegist()
    app.uiMgr:GetCurrentScene():RemoveDialog(self:GetViewComponent())
    unregPost(POST.SKIN_CARNIVAL_FLASH_SALE)
    unregPost(POST.SKIN_CARNIVAL_FLASH_SALE_RUSH)
    unregPost(POST.SKIN_CARNIVAL_FLASH_SALE_BUY)
    unregPost(POST.SKIN_CARNIVAL_FLASH_SALE_DRAW)
    if app.timerMgr:RetriveTimer(SKIN_CARNIVAL_FLASH_SALE_COUNTDOWN) then
        app.timerMgr:RemoveTimer(SKIN_CARNIVAL_FLASH_SALE_COUNTDOWN)
    end
end
------------------ inheritance ------------------
-------------------------------------------------

-------------------------------------------------
-------------------- handler --------------------
--[[
吞噬层点击回调
--]]
function ActivitySkinCarnivalFlashSaleMediator:EaterLayerCallback( sender )
    PlayAudioByClickClose()
    local viewComponent = self:GetViewComponent()
    viewComponent:BackAction(self:GetHomeData().pos)
end
--[[
标题按钮点击回调
--]]
function ActivitySkinCarnivalFlashSaleMediator:TitleButtonCallback( sender )
    PlayAudioByClickNormal()
    app.uiMgr:ShowIntroPopup({moduleId = INTRODUCE_MODULE_ID.SKIN_CARNIVAL_FLASH_SALE})
end
--[[
切换按钮点击回调
--]]
function ActivitySkinCarnivalFlashSaleMediator:SwitchButtonCallback( sender )
    PlayAudioByClickNormal()
    local ShowCardSkinLayer = require('common.CommonCardGoodsDetailView').new({
        goodsId = self:GetSkinId(),
    })
    ShowCardSkinLayer:setPosition(display.center)
    app.uiMgr:GetCurrentScene():AddDialog(ShowCardSkinLayer)
end
--[[
故事按钮点击回调
--]]
function ActivitySkinCarnivalFlashSaleMediator:StoryButtonCallback( sender )
    PlayAudioByClickNormal()
    local homeData = self:GetHomeData()
    local skinId = self:GetSkinId()
    if app.cardMgr.IsHaveCardSkin(skinId) then
        local storyConfig = CommonUtils.GetConfig('skinCarnival', 'skinStory', skinId)
        app.uiMgr:AddDialog("Game.views.activity.skinCarnival.ActivitySkinCarnivalStoryPopup", {title = homeData.title, story = storyConfig.descr, skinId = skinId})
    else
        app.uiMgr:ShowInformationTips(__('获得外观，解锁专属故事'))
    end
end
--[[
购买按钮点击回调
--]]
function ActivitySkinCarnivalFlashSaleMediator:BuyButtonCallback( sender )
    PlayAudioByClickNormal()
    -- 如果已拥有皮肤则不可购买
    if app.cardMgr.IsHaveCardSkin(self:GetSkinId()) then
        app.uiMgr:ShowInformationTips(__('已获得该皮肤'))
        return 
    end
    local homeData = self:GetHomeData()
    local currency = checkint(homeData.currency) -- 购买所需货币
    local currencyConfig = CommonUtils.GetConfig('goods', 'goods', currency)
    local price = checkint(homeData.price) -- 皮肤价格
    local text = __('是否确认购买？')
    local descrRich = {
        {text = __('一旦购买，本次活动该外观其他获得方式全部关闭。'), color = '#d23d3d'}
    }
	local callback = function ()
		if app.gameMgr:GetAmountByGoodId(currency) >= price then
			self:SendSignal(POST.SKIN_CARNIVAL_FLASH_SALE_BUY.cmdName, {activityId = homeData.activityId, group = homeData.group, isBuy = 1})
		else
            if currency == DIAMOND_ID then
                if CommonUtils.GetModuleAvailable(MODULE_SWITCH.PAY) and CommonUtils.GetModuleAvailable(MODULE_SWITCH.SHOP) then
                    if GAME_MODULE_OPEN.NEW_STORE then
                        app.uiMgr:showGameStores({storeType = GAME_STORE_TYPE.DIAMOND})
                    else
                        app.router:Dispatch({name = "HomeMediator"}, {name = "ShopMediator"})
                    end
                end
            else
                app.uiMgr:AddDialog("common.GainPopup", {goodId = currency})
            end
		end
    end
    local costInfo = {
        goodsId = currency,
        num = price,
    }
	-- 显示购买弹窗
	local layer = require('common.CommonTip').new({
		text = text,
		defaultRichPattern = true,
		costInfo = costInfo,
        callback = callback,
        descrRich = descrRich,
	})
	layer:setPosition(display.center)
    app.uiMgr:GetCurrentScene():AddDialog(layer)
end
--[[
领取奖励按钮点击回调
--]]
function ActivitySkinCarnivalFlashSaleMediator:RewardButtonCallback( sender )
    PlayAudioByClickNormal()
    local homeData = self:GetHomeData()
    local flashSaleData = self:GetFlashSaleData()
    local skinId = self:GetSkinId()
    local skinConfig = CardUtils.GetCardSkinConfig(skinId)
    local rewardsConfig = CommonUtils.GetConfig('skinCarnival', 'flashSaleReward', homeData.group)
    local title = string.fmt(__('获得_name_可解锁'), {['_name_'] = skinConfig.name})
    local descr = __('2选1')
    local params = {
        title = title,
        descr = descr,
        hasDrawn = checkint(flashSaleData.optionRewardDrawn),
        hasSkin = app.cardMgr.IsHaveCardSkin(skinId),
        rewardList = clone(rewardsConfig.rewards),
        signal = ACTIVITY_SKIN_CARNIVAL_FLASH_SALE_CHOOSE_REWRARD,
    }
    app.uiMgr:AddDialog("Game.views.activity.skinCarnival.ActivitySkinCarnivalChoosePopup", params)
end
--[[
秒杀按钮点击回调
--]]
function ActivitySkinCarnivalFlashSaleMediator:FlashSaleButtonCallback( sender )
    PlayAudioByClickNormal()
    local flashSaleId = sender:getTag()
    local homeData = self:GetHomeData()
    local flashSaleData = self:GetFlashSaleData()
    local flashSaleConfig = CommonUtils.GetConfig('skinCarnival', 'flashSale', flashSaleId)
    if app.gameMgr:GetAmountByIdForce(flashSaleConfig.currency) >= checkint(flashSaleConfig.price) then
        local homeData = self:GetHomeData()
        self:SendSignal(POST.SKIN_CARNIVAL_FLASH_SALE_RUSH.cmdName, {activityId = homeData.activityId, group = homeData.group, flashSaleId = flashSaleId})
    else
        local currency = checkint(flashSaleConfig.currency)
        if currency == DIAMOND_ID then
            if CommonUtils.GetModuleAvailable(MODULE_SWITCH.PAY) and CommonUtils.GetModuleAvailable(MODULE_SWITCH.SHOP) then
                if GAME_MODULE_OPEN.NEW_STORE then
                    app.uiMgr:showGameStores({storeType = GAME_STORE_TYPE.DIAMOND})
                else
                    app.router:Dispatch({name = "HomeMediator"}, {name = "ShopMediator"})
                end
            end
        else
            app.uiMgr:AddDialog("common.GainPopup", {goodId = currency})
        end
    end
end
--[[
名单按钮点击回调
--]]
function ActivitySkinCarnivalFlashSaleMediator:PurchaseListButtonCallback( sender )
    PlayAudioByClickNormal()
    local flashSaleId = sender:getTag()
    local flashSaleData = self:GetFlashSaleData()
    local winningList = {}
    for i, v in ipairs(flashSaleData.flashSale) do
        if checkint(v.flashSaleId) == flashSaleId then
            winningList = checktable(v.winningList)
            break
        end
    end
    app.uiMgr:AddDialog("Game.views.activity.skinCarnival.ActivitySkinCarnivalGetListPopup", {winningList = winningList})
end
-------------------- handler --------------------
-------------------------------------------------

-------------------------------------------------
-------------------- private --------------------
--[[
初始化页面
--]]
function ActivitySkinCarnivalFlashSaleMediator:InitView()
    -- 刷新标题
    self:RefreshTitle()
    -- 刷新皮肤购买消耗
    self:RefreshBuySkinConsume()
    -- 刷新按钮状态
    self:RefreshBtnState()
    -- 刷新秒杀列表
    self:RefreshFLashSaleListView()
    -- 刷新奖励描述
    self:RefreshRewardDescrLabel()
    -- 刷新小红点
    self:RefreshRemindIcon()
end
--[[
刷新标题
--]]
function ActivitySkinCarnivalFlashSaleMediator:RefreshTitle()
    local homeData = self:GetHomeData()
    local viewComponent = self:GetViewComponent()
    viewComponent:RefreshTitle(homeData.title) 
end
--[[
刷新皮肤购买消耗
--]]
function ActivitySkinCarnivalFlashSaleMediator:RefreshBuySkinConsume()
    local homeData = self:GetHomeData()
    local currency = checkint(homeData.currency) -- 购买所需货币
    local price = checkint(homeData.price) -- 皮肤价格
    local viewComponent = self:GetViewComponent()
    viewComponent:RefreshBuyBtnConsumeRichlabel({goodsId = currency, num = price})
end
--[[
刷新奖励描述
--]]
function ActivitySkinCarnivalFlashSaleMediator:RefreshRewardDescrLabel()
    local skinId = self:GetSkinId()
    local viewComponent = self:GetViewComponent()
    viewComponent:RefreshRewardDescrLabel(skinId) 
end
--[[
刷新皮肤节点
--]]
function ActivitySkinCarnivalFlashSaleMediator:RefreshSkin()
    local viewComponent = self:GetViewComponent()
    local homeData = self:GetHomeData()
    local skinId = self:GetSkinId()
    viewComponent:RefreshSkinDrawNode(skinId, homeData.showEffect)
    viewComponent:ShowCardSkin()
end
--[[
刷新按钮状态
--]]
function ActivitySkinCarnivalFlashSaleMediator:RefreshBtnState()
    local viewComponent = self:GetViewComponent()
    local skinId = self:GetSkinId()
    local homeData = self:GetHomeData()
    local flashSaleData = self:GetFlashSaleData()
    viewComponent:RefreshBtnState(app.cardMgr.IsHaveCardSkin(skinId), checkint(flashSaleData.optionRewardDrawn) == 1)
end
--[[
刷新秒杀列表
--]]
function ActivitySkinCarnivalFlashSaleMediator:RefreshFLashSaleListView()
    local viewComponent = self:GetViewComponent()
    local flashSaleData = self:GetFlashSaleData()
    local serverTimestamp = getServerTime()
    for i, v in ipairs(flashSaleData.flashSale) do
        if checkint(v.left) == 0 then
            v.status = 3
        end
    end
    table.sort(flashSaleData.flashSale, function (a, b)
        if checkint(a.status) == checkint(b.status) then
            return checkint(a.startTime) < checkint(b.startTime)
        else
            if checkint(a.status) == 2 or checkint(b.status) == 2 then
                return (a.status) == 2
            else
                return checkint(a.status) < checkint(b.status)
            end
        end
    end)
    local skinId = self:GetSkinId()
    viewComponent:RefreshFlashSaleListView(flashSaleData.flashSale, skinId, handler(self, self.FlashSaleButtonCallback), handler(self, self.PurchaseListButtonCallback))
end
--[[
刷新小红点
--]]
function ActivitySkinCarnivalFlashSaleMediator:RefreshRemindIcon()
    local viewComponent = self:GetViewComponent()
    local homeData = self:GetHomeData()
    local flashSaleData = self:GetFlashSaleData()
    local skinId = self:GetSkinId()
    -- 刷新抽奖小红点
    local rewardState = checkint(flashSaleData.optionRewardDrawn) == 0 and app.cardMgr.IsHaveCardSkin(skinId)
    viewComponent:RefreshRewardRemindIcon(rewardState)
    -- 刷新home
    app:DispatchObservers(ACTIVITY_SKIN_CARNIVAL_REFRESH_REMIND_ICON, {id = homeData.id, state = rewardState})
end
--[[
开启定时器
--]]
function ActivitySkinCarnivalFlashSaleMediator:StartTimer()
    local flashSaleData = self:GetFlashSaleData()
    -- 获取最近一个要开始的秒杀活动时间戳
    local startTime = nil
    for i, v in ipairs(flashSaleData.flashSale) do
        if checkint(v.status) == 1 then
            if not startTime or checkint(v.startTime) < checkint(startTime) then
                startTime = checkint(v.startTime)
            end
        end
    end
    local callback = function( countdown, remindTag, timeNum, datas)
        if countdown == 0 then
            app.timerMgr:RemoveTimer(SKIN_CARNIVAL_FLASH_SALE_COUNTDOWN)
            if self.enterLayer then
                self:enterLayer()
            end
        end
    end
    if startTime and startTime > os.time() then
        -- 开启定时器
        app.timerMgr:AddTimer({name = SKIN_CARNIVAL_FLASH_SALE_COUNTDOWN, callback = callback, countdown = startTime - os.time()})
    end
end
function ActivitySkinCarnivalFlashSaleMediator:EnterLayer()
    local homeData = self:GetHomeData()
    self:SendSignal(POST.SKIN_CARNIVAL_FLASH_SALE.cmdName, {activityId = homeData.activityId, group = homeData.group})
end
-------------------- private --------------------
-------------------------------------------------

-------------------------------------------------
------------------- get / set -------------------
--[[
获取homeData
--]]
function ActivitySkinCarnivalFlashSaleMediator:GetHomeData()
    return self.homeData
end
--[[
设置任务数据
--]]
function ActivitySkinCarnivalFlashSaleMediator:SetFlashSaleData( flashSaleData )
    self.flashSaleData = checktable(flashSaleData)
end
--[[
获取任务数据
--]]
function ActivitySkinCarnivalFlashSaleMediator:GetFlashSaleData()
    return self.flashSaleData
end
--[[
获取皮肤id
--]]
function ActivitySkinCarnivalFlashSaleMediator:GetSkinId()
    local homeData = self:GetHomeData()
    return checkint(homeData.skinId)
end
------------------- get / set -------------------
-------------------------------------------------
return ActivitySkinCarnivalFlashSaleMediator
