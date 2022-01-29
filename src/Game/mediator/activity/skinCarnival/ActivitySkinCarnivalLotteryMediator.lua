--[[
 * author : liuzhipeng
 * descpt : 活动 皮肤嘉年华 抽奖活动Mediator
--]]
local ActivitySkinCarnivalLotteryMediator = class('ActivitySkinCarnivalLotteryMediator', mvc.Mediator)
local NAME = "activity.skinCarnival.ActivitySkinCarnivalLotteryMediator"
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
function ActivitySkinCarnivalLotteryMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.homeData = checktable(params)
    self.lotteryData = nil 
end

-------------------------------------------------
------------------ inheritance ------------------
function ActivitySkinCarnivalLotteryMediator:Initial( key )
    self.super.Initial(self, key)
	local viewComponent  = require('Game.views.activity.skinCarnival.ActivitySkinCarnivalLotteryView').new({group = self.homeData.group})
	viewComponent:setPosition(display.center)
	app.uiMgr:GetCurrentScene():AddDialog(viewComponent)
    self:SetViewComponent(viewComponent)
    local viewData = viewComponent:GetViewData()
    viewComponent.eaterLayer:setOnClickScriptHandler(handler(self, self.EaterLayerCallback))
    viewData.titleBtn:setOnClickScriptHandler(handler(self, self.TitleButtonCallback))
    viewData.switchBtn:setOnClickScriptHandler(handler(self, self.SwitchButtonCallback))
    viewData.storyBtn:setOnClickScriptHandler(handler(self, self.StoryButtonCallback))
    viewData.buyBtn:setOnClickScriptHandler(handler(self, self.BuyButtonCallback))
    viewData.previewBtn:setOnClickScriptHandler(handler(self, self.PreviewButtonCallback))
    viewData.currencyAddBtn:setOnClickScriptHandler(handler(self, self.CurrencyAddButtonCallback))
    viewData.currencyIcon:setOnClickScriptHandler(handler(self, self.CurrencyIconButtonCallback))
    viewData.drawOneBtn:setOnClickScriptHandler(handler(self, self.DrawOneButtonCallback))
    viewData.drawTenBtn:setOnClickScriptHandler(handler(self, self.DrawTenButtonCallback))
    viewData.rewardGoodsNode:RefreshSelf({callBack = handler(self, self.RewardButtonCallback)})
    -- 绑定spine事件
    viewData.drawOneEffect:registerSpineEventHandler(handler(self, self.DrawOneEffectEndCallback), sp.EventType.ANIMATION_END)
    self:RefreshSkin()
    viewComponent:EnterAction(self:GetHomeData().pos)
end

function ActivitySkinCarnivalLotteryMediator:InterestSignals()
    local signals = {
        POST.SKIN_CARNIVAL_LOTTERY.sglName,
        POST.SKIN_CARNIVAL_LOTTERY_GRAB.sglName,
        POST.SKIN_CARNIVAL_LOTTERY_REWARD_DRAW.sglName,
	}
	return signals
end
function ActivitySkinCarnivalLotteryMediator:ProcessSignal( signal )
    local name = signal:GetName()
    local body = signal:GetBody()
    if name == POST.SKIN_CARNIVAL_LOTTERY.sglName then -- home
        body.previewData = self:ConvertPreviewData(body.pool)
        self:SetLotteryData(body)
        self:InitView()
    elseif name == POST.SKIN_CARNIVAL_LOTTERY_GRAB.sglName then -- 抽奖
        -- 扣除道具
        local lotteryData = self:GetLotteryData()
        local temp = {}
        temp.goodsId = checkint(lotteryData.lotteryGoodsId)
        if body.requestData.type == 2 then
            temp.num = -checkint(lotteryData.lotteryGoodsNum) * 10
            lotteryData.lotteryTimes = checkint(lotteryData.lotteryTimes) + 10
        else
            temp.num = -checkint(lotteryData.lotteryGoodsNum)
            lotteryData.lotteryTimes = checkint(lotteryData.lotteryTimes) + 1
        end
        CommonUtils.DrawRewards({temp})
        app.uiMgr:AddDialog('common.RewardPopup', body[1])
        self:RefreshRewardProgressBar()
        self:RefreshLotteryCurrency()
        self:RefreshBtnState()
        self:RefreshRemindIcon()
    elseif name == POST.SKIN_CARNIVAL_LOTTERY_REWARD_DRAW.sglName then -- 领奖
        -- 消耗道具
        if body.requestData.isBuy then
            local homeData = self:GetHomeData()
            CommonUtils.DrawRewards({{goodsId = checkint(homeData.currency), num = -checkint(homeData.price)}})
        end
        app.uiMgr:AddDialog('common.RewardPopup', body)
        self:RefreshBtnState()
        self:RefreshRemindIcon()
    end
end

function ActivitySkinCarnivalLotteryMediator:OnRegist()
    regPost(POST.SKIN_CARNIVAL_LOTTERY)
    regPost(POST.SKIN_CARNIVAL_LOTTERY_GRAB)
    regPost(POST.SKIN_CARNIVAL_LOTTERY_REWARD_DRAW)
    self:EnterLayer()
end
function ActivitySkinCarnivalLotteryMediator:OnUnRegist()
    app.uiMgr:GetCurrentScene():RemoveDialog(self:GetViewComponent())
    unregPost(POST.SKIN_CARNIVAL_LOTTERY)
    regPost(POST.SKIN_CARNIVAL_LOTTERY_GRAB)
    unregPost(POST.SKIN_CARNIVAL_LOTTERY_REWARD_DRAW)
end
------------------ inheritance ------------------
-------------------------------------------------

-------------------------------------------------
-------------------- handler --------------------
--[[
吞噬层点击回调
--]]
function ActivitySkinCarnivalLotteryMediator:EaterLayerCallback( sender )
    PlayAudioByClickClose()
    local viewComponent = self:GetViewComponent()
    viewComponent:BackAction(self:GetHomeData().pos)
end
--[[
标题按钮点击回调
--]]
function ActivitySkinCarnivalLotteryMediator:TitleButtonCallback( sender )
    PlayAudioByClickNormal()
    app.uiMgr:ShowIntroPopup({moduleId = INTRODUCE_MODULE_ID.SKIN_CARNIVAL_LOTTERY})
end
--[[
切换按钮点击回调
--]]
function ActivitySkinCarnivalLotteryMediator:SwitchButtonCallback( sender )
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
function ActivitySkinCarnivalLotteryMediator:StoryButtonCallback( sender )
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
function ActivitySkinCarnivalLotteryMediator:BuyButtonCallback( sender )
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
			self:SendSignal(POST.SKIN_CARNIVAL_LOTTERY_REWARD_DRAW.cmdName, {activityId = homeData.activityId, group = homeData.group, isBuy = 1})
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
奖池预览按钮点击回调
--]]
function ActivitySkinCarnivalLotteryMediator:PreviewButtonCallback( sender )
    PlayAudioByClickNormal()
    local lotteryData = self:GetLotteryData()
    local capsulePrizeView = require( 'Game.views.anniversary.AnniversaryCapsulePoolView' ).new(lotteryData.previewData)
    display.commonUIParams(capsulePrizeView, {ap = display.CENTER, po = display.center})
    local scene = app.uiMgr:GetCurrentScene()
    scene:AddDialog(capsulePrizeView)
end
--[[
货币获取按钮点击回调
--]]
function ActivitySkinCarnivalLotteryMediator:CurrencyAddButtonCallback( sender )
    PlayAudioByClickNormal()
    local lotteryData = self:GetLotteryData()
    app.uiMgr:AddDialog("common.GainPopup", {goodId = lotteryData.lotteryGoodsId})
end
--[[
货币图标按钮点击回调
--]]
function ActivitySkinCarnivalLotteryMediator:CurrencyIconButtonCallback( sender )
    PlayAudioByClickNormal()
    local lotteryData = self:GetLotteryData()
    app.uiMgr:ShowInformationTipsBoard({
        targetNode = sender,
        iconId = checkint(lotteryData.lotteryGoodsId),
        type = 1
    })
end
--[[
召唤1次按钮点击回调
--]]
function ActivitySkinCarnivalLotteryMediator:DrawOneButtonCallback( sender )
    PlayAudioByClickNormal()
    -- 判断道具是否足够
    local lotteryData = self:GetLotteryData()
    if app.gameMgr:GetAmountByIdForce(lotteryData.lotteryGoodsId) >= checkint(lotteryData.lotteryGoodsNum) then
        local viewComponent = self:GetViewComponent()
        viewComponent:ShowDrawOneEffect(1)
    else
        local conf = CommonUtils.GetConfig('goods', 'goods', lotteryData.lotteryGoodsId) or {}
        app.uiMgr:ShowInformationTips(string.fmt(__('_name_不足'), {['_name_'] = tostring(conf.name)}))
    end
end
--[[
召唤10次按钮点击回调
--]]
function ActivitySkinCarnivalLotteryMediator:DrawTenButtonCallback( sender )
    PlayAudioByClickNormal()
    -- 判断道具是否足够
    local lotteryData = self:GetLotteryData()
    if app.gameMgr:GetAmountByIdForce(lotteryData.lotteryGoodsId) >= checkint(lotteryData.lotteryGoodsNum) * 10 then
        local viewComponent = self:GetViewComponent()
        viewComponent:ShowDrawOneEffect(10)
    else
        local conf = CommonUtils.GetConfig('goods', 'goods', lotteryData.lotteryGoodsId) or {}
        app.uiMgr:ShowInformationTips(string.fmt(__('_name_不足'), {['_name_'] = tostring(conf.name)}))
    end
end
--[[
奖励道具点击回调
--]]
function ActivitySkinCarnivalLotteryMediator:RewardButtonCallback( sender )
    PlayAudioByClickNormal()
    if app.cardMgr.IsHaveCardSkin(self:GetSkinId()) then
        app.uiMgr:ShowInformationTips(__('已获得该皮肤'))
    else
        local lotteryData = self:GetLotteryData()
        if checkint(lotteryData.lotteryTimes) >= checkint(lotteryData.lotteryTargetTimes) then
            local homeData = self:GetHomeData()
            self:SendSignal(POST.SKIN_CARNIVAL_LOTTERY_REWARD_DRAW.cmdName, {activityId = homeData.activityId, group = homeData.group})
        else
            app.uiMgr:ShowInformationTips(__('完成进度可领取'))
        end
    end
end
--[[
抽奖一次动画结束回调
--]]
function ActivitySkinCarnivalLotteryMediator:DrawOneEffectEndCallback( event )
    local viewComponent = self:GetViewComponent()
    local homeData = self:GetHomeData()
    if event.animation == 'play_1' then
        self:SendSignal(POST.SKIN_CARNIVAL_LOTTERY_GRAB.cmdName, {activityId = homeData.activityId, group = homeData.group, type = 1}) -- type 1代表抽1次
        viewComponent:HideDrawOneEffect()
    elseif event.animation == 'play_10' then
        self:SendSignal(POST.SKIN_CARNIVAL_LOTTERY_GRAB.cmdName, {activityId = homeData.activityId, group = homeData.group, type = 2}) -- type 2代表抽10次
        viewComponent:HideDrawOneEffect()
	end
end
-------------------- handler --------------------
-------------------------------------------------

-------------------------------------------------
-------------------- private --------------------
--[[
转换抽奖数据
@params 
--]]
function ActivitySkinCarnivalLotteryMediator:ConvertPreviewData( pool )
    local previewData = {rate = {}, rewardPreviewDatas = {[0] = {}, [1] = {}}}
    previewData.rewardPreviewDatas[0].title = __('普通')
    previewData.rewardPreviewDatas[1].title = __('稀有')
    previewData.rewardPreviewDatas[0].list = {}
    previewData.rewardPreviewDatas[1].list = {}
    for k, v in ipairs(pool) do
        local config = CommonUtils.GetConfig('goods', 'goods', v.goodsId)
        local descr = config.name
        if checkint(v.goodsNum) > 1 then
            descr = descr .. ' x ' .. tostring(v.goodsNum)
        end
        table.insert(previewData.rate, {descr = descr, rateText = string.format('%s%%', tostring(tonumber(v.rate) * 100))})
        table.insert(previewData.rewardPreviewDatas[checkint(v.rareGoods)].list, {reward = {goodsId = v.goodsId, num = v.goodsNum}})
    end
    previewData.roleBgPath = string.format('ui/home/capsule/activityCapsule/summon_pre_img_%d.png', self:GetSkinId())
    return previewData
end
--[[
初始化页面
--]]
function ActivitySkinCarnivalLotteryMediator:InitView()
    -- 刷新标题
    self:RefreshTitle()
    -- 刷新皮肤购买消耗
    self:RefreshBuySkinConsume()
    -- 刷新奖励描述
    self:RefreshRewardDescrLabel()
    -- 刷新按钮状态
    self:RefreshBtnState()
    -- 刷新抽奖货币
    self:RefreshLotteryCurrency()
    -- 刷新奖励道具节点
    self:RefreshRewardGoodsNode()
    -- 刷新奖励进度条
    self:RefreshRewardProgressBar()
    -- 刷新小红点
    self:RefreshRemindIcon()
end
--[[
刷新标题
--]]
function ActivitySkinCarnivalLotteryMediator:RefreshTitle()
    local homeData = self:GetHomeData()
    local viewComponent = self:GetViewComponent()
    viewComponent:RefreshTitle(homeData.title)
end
--[[
刷新皮肤购买消耗
--]]
function ActivitySkinCarnivalLotteryMediator:RefreshBuySkinConsume()
    local homeData = self:GetHomeData()
    local currency = checkint(homeData.currency) -- 购买所需货币
    local price = checkint(homeData.price) -- 皮肤价格
    local viewComponent = self:GetViewComponent()
    viewComponent:RefreshBuyBtnConsumeRichlabel({goodsId = currency, num = price})
end
--[[
刷新奖励描述
--]]
function ActivitySkinCarnivalLotteryMediator:RefreshRewardDescrLabel()
    local skinId = self:GetSkinId()
    local viewComponent = self:GetViewComponent()
    local lotteryData = self:GetLotteryData()
    viewComponent:RefreshRewardDescrLabel(lotteryData.lotteryTargetTimes, skinId)
end
--[[
刷新皮肤节点
--]]
function ActivitySkinCarnivalLotteryMediator:RefreshSkin()
    local viewComponent = self:GetViewComponent()
    local homeData = self:GetHomeData()
    local skinId = self:GetSkinId()
    viewComponent:RefreshSkinDrawNode(skinId, homeData.showEffect)
    viewComponent:ShowCardSkin()
end
--[[
刷新按钮状态
--]]
function ActivitySkinCarnivalLotteryMediator:RefreshBtnState()
    local viewComponent = self:GetViewComponent()
    local lotteryData = self:GetLotteryData()
    local skinId = self:GetSkinId()
    local canDraw = checkint(lotteryData.lotteryTimes) > checkint(lotteryData.lotteryTargetTimes)
    viewComponent:RefreshBtnState(app.cardMgr.IsHaveCardSkin(skinId), canDraw, skinId)
end
--[[
刷新抽奖货币
--]]
function ActivitySkinCarnivalLotteryMediator:RefreshLotteryCurrency()
    local viewComponent = self:GetViewComponent()
    local lotteryData = self:GetLotteryData()
    viewComponent:RefreshLotteryCurrency(lotteryData.lotteryGoodsId, lotteryData.lotteryGoodsNum)
end
--[[
刷新奖励道具节点
--]]
function ActivitySkinCarnivalLotteryMediator:RefreshRewardGoodsNode()
    local viewComponent = self:GetViewComponent()
    viewComponent:RefreshRewardGoodsNode(self:GetSkinId())
end
--[[
刷新奖励进度条
--]]
function ActivitySkinCarnivalLotteryMediator:RefreshRewardProgressBar()
    local viewComponent = self:GetViewComponent()
    local lotteryData = self:GetLotteryData()
    viewComponent:RefreshRewardProgressBar(lotteryData.lotteryTimes, lotteryData.lotteryTargetTimes)
end
--[[
刷新小红点
--]]
function ActivitySkinCarnivalLotteryMediator:RefreshRemindIcon( )
    local viewComponent = self:GetViewComponent()
    local homeData = self:GetHomeData()
    local lotteryData = self:GetLotteryData()
    local skinId = self:GetSkinId()
    if app.cardMgr.IsHaveCardSkin(skinId) then
        -- 拥有皮肤则小红点消失
        viewComponent:RefreshDrawRemindIcon(false, false)
        viewComponent:RefreshRewardRemindIcon(false)
        app:DispatchObservers(ACTIVITY_SKIN_CARNIVAL_REFRESH_REMIND_ICON, {id = homeData.id, state = false})
        return 
    end
    -- 刷新抽奖小红点
    local drawOneState = app.gameMgr:GetAmountByIdForce(lotteryData.lotteryGoodsId) >= checkint(lotteryData.lotteryGoodsNum)
    local drawTenState = app.gameMgr:GetAmountByIdForce(lotteryData.lotteryGoodsId) >= checkint(lotteryData.lotteryGoodsNum) * 10
    viewComponent:RefreshDrawRemindIcon(drawOneState, drawTenState)
    local rewardState = checkint(lotteryData.lotteryTimes) >= checkint(lotteryData.lotteryTargetTimes)
    viewComponent:RefreshRewardRemindIcon(rewardState)
    -- 刷新home
    app:DispatchObservers(ACTIVITY_SKIN_CARNIVAL_REFRESH_REMIND_ICON, {id = homeData.id, state = drawOneState or drawTenState or rewardState})
end

function ActivitySkinCarnivalLotteryMediator:EnterLayer()
    local homeData = self:GetHomeData()
    self:SendSignal(POST.SKIN_CARNIVAL_LOTTERY.cmdName, {activityId = homeData.activityId, group = homeData.group})
end
-------------------- private --------------------
-------------------------------------------------

-------------------------------------------------
------------------- get / set -------------------
--[[
获取homeData
--]]
function ActivitySkinCarnivalLotteryMediator:GetHomeData()
    return self.homeData
end
--[[
设置任务数据
--]]
function ActivitySkinCarnivalLotteryMediator:SetLotteryData( lotteryData )
    self.lotteryData = checktable(lotteryData)
end
--[[
获取任务数据
--]]
function ActivitySkinCarnivalLotteryMediator:GetLotteryData()
    return self.lotteryData
end
--[[
获取皮肤id
--]]
function ActivitySkinCarnivalLotteryMediator:GetSkinId()
    local homeData = self:GetHomeData()
    return checkint(homeData.skinId)
end
------------------- get / set -------------------
-------------------------------------------------
return ActivitySkinCarnivalLotteryMediator
