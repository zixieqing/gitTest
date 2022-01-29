--[[
 * author : liuzhipeng
 * descpt : 活动 皮肤嘉年华 挑战活动Mediator
--]]
local ActivitySkinCarnivalChallengeMediator = class('ActivitySkinCarnivalChallengeMediator', mvc.Mediator)
local NAME = "activity.skinCarnival.ActivitySkinCarnivalChallengeMediator"
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
function ActivitySkinCarnivalChallengeMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.homeData = checktable(params)
    self.challengeData = nil 
end

-------------------------------------------------
------------------ inheritance ------------------
function ActivitySkinCarnivalChallengeMediator:Initial( key )
	self.super.Initial(self, key)
	local viewComponent  = require('Game.views.activity.skinCarnival.ActivitySkinCarnivalChallengeView').new({group = self.homeData.group})
	viewComponent:setPosition(display.center)
	app.uiMgr:GetCurrentScene():AddDialog(viewComponent)
    self:SetViewComponent(viewComponent)
    local viewData = viewComponent:GetViewData()
    viewComponent.eaterLayer:setOnClickScriptHandler(handler(self, self.EaterLayerCallback))
    viewData.titleBtn:setOnClickScriptHandler(handler(self, self.TitleButtonCallback))
    viewData.switchBtn:setOnClickScriptHandler(handler(self, self.SwitchButtonCallback))
    viewData.storyBtn:setOnClickScriptHandler(handler(self, self.StoryButtonCallback))
    viewData.buyBtn:setOnClickScriptHandler(handler(self, self.BuyButtonCallback))
    viewData.challengeBtn:setOnClickScriptHandler(handler(self, self.ChallengeButtonCallback))
    self:RefreshSkin()
    viewComponent:EnterAction(self:GetHomeData().pos)
end

function ActivitySkinCarnivalChallengeMediator:InterestSignals()
    local signals = {
        POST.SKIN_CARNIVAL_CHALLENGE.sglName,
        POST.SKIN_CARNIVAL_CHALLENGE_REWARD_DRAW.sglName,
	}
	return signals
end
function ActivitySkinCarnivalChallengeMediator:ProcessSignal( signal )
    local name = signal:GetName()
    local body = signal:GetBody()
    if name == POST.SKIN_CARNIVAL_CHALLENGE.sglName then -- home
        self:SetChallengeData(body)
        self:InitView()
    elseif name == POST.SKIN_CARNIVAL_CHALLENGE_REWARD_DRAW.sglName then -- 皮肤购买
        -- 领奖
        app.uiMgr:AddDialog('common.RewardPopup', body)
        -- 扣除道具
        local homeData = self:GetHomeData()
        local challengeData = self:GetChallengeData()
        local price = homeData.price
        -- 判断是否为折扣购买
        if checkint(challengeData.discountId) > 0 then
            local discountConfig = CommonUtils.GetConfig('skinCarnival', 'questDiscount', challengeData.discountId)
            price = checkint(discountConfig.price)
        end
        CommonUtils.DrawRewards({
            {goodsId = homeData.currency, num = -price}
        })
        -- 刷新页面
        self:RefreshBtnState()
    end
end

function ActivitySkinCarnivalChallengeMediator:OnRegist()
    regPost(POST.SKIN_CARNIVAL_CHALLENGE)
    regPost(POST.SKIN_CARNIVAL_CHALLENGE_REWARD_DRAW)
    self:EnterLayer()
end
function ActivitySkinCarnivalChallengeMediator:OnUnRegist()
    app.uiMgr:GetCurrentScene():RemoveDialog(self:GetViewComponent())
    unregPost(POST.SKIN_CARNIVAL_CHALLENGE)
    unregPost(POST.SKIN_CARNIVAL_CHALLENGE_REWARD_DRAW)
end
------------------ inheritance ------------------
-------------------------------------------------

-------------------------------------------------
-------------------- handler --------------------
--[[
吞噬层点击回调
--]]
function ActivitySkinCarnivalChallengeMediator:EaterLayerCallback( sender )
    PlayAudioByClickClose()
    local viewComponent = self:GetViewComponent()
    viewComponent:BackAction(self:GetHomeData().pos)
end
--[[
标题按钮点击回调
--]]
function ActivitySkinCarnivalChallengeMediator:TitleButtonCallback( sender )
    PlayAudioByClickNormal()
    app.uiMgr:ShowIntroPopup({moduleId = INTRODUCE_MODULE_ID.SKIN_CARNIVAL_CHALLENGE})
end
--[[
切换按钮点击回调
--]]
function ActivitySkinCarnivalChallengeMediator:SwitchButtonCallback( sender )
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
function ActivitySkinCarnivalChallengeMediator:StoryButtonCallback( sender )
    PlayAudioByClickNormal()
    local homeData = self:GetHomeData()
    local skinId = self:GetSkinId()
    if app.cardMgr.IsHaveCardSkin(self:GetSkinId()) then
        local storyConfig = CommonUtils.GetConfig('skinCarnival', 'skinStory', skinId)
        app.uiMgr:AddDialog("Game.views.activity.skinCarnival.ActivitySkinCarnivalStoryPopup", {title = homeData.title, story = storyConfig.descr, skinId = skinId})
    else
        app.uiMgr:ShowInformationTips(__('获得外观，解锁专属故事'))
    end
end
--[[
购买按钮点击回调
--]]
function ActivitySkinCarnivalChallengeMediator:BuyButtonCallback( sender )
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
			self:SendSignal(POST.SKIN_CARNIVAL_CHALLENGE_REWARD_DRAW.cmdName, {activityId = homeData.activityId, group = homeData.group})
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
折扣购买按钮点击回调
--]]
function ActivitySkinCarnivalChallengeMediator:DiscountBuyButtonCallback( sender )
    PlayAudioByClickNormal()
    -- 判断条件是否满足
    local homeData = self:GetHomeData()
    local challengeData = self:GetChallengeData()
    local discountConfig = CommonUtils.GetConfig('skinCarnival', 'questDiscount', challengeData.discountId)
    if not discountConfig then return end

    local currency = checkint(discountConfig.currency) -- 购买所需货币
    local currencyConfig = CommonUtils.GetConfig('goods', 'goods', currency)
    local price = checkint(discountConfig.price) -- 皮肤价格
    local text = __('是否确认购买？')
    local descrRich = {
        {text = __('一旦购买，本次活动该外观其他获得方式全部关闭。'), color = '#d23d3d'}
    }
    if app.gameMgr:GetAmountByIdForce(currency) >= checkint(price) then
        -- 条件满足，弹出二次确认框
        local callback = function ()
            self:SendSignal(POST.SKIN_CARNIVAL_CHALLENGE_REWARD_DRAW.cmdName, {activityId = homeData.activityId, group = homeData.group})
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
    else
        -- 条件不满足
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
        -- app.uiMgr:ShowInformationTips(string.fmt(__("_name_不足"), {['_name_'] = currencyConfig.name}))
    end
end
--[[
挑战按钮点击回调
--]]
function ActivitySkinCarnivalChallengeMediator:ChallengeButtonCallback( sender )
    PlayAudioByClickNormal()
    local homeData = self:GetHomeData()
    local challengeData = self:GetChallengeData()
	-- 构建战斗数据
	local serverCommand = BattleNetworkCommandStruct.New(
		POST.SKIN_CARNIVAL_CHALLENGE_QUEST_AT.cmdName ,
		{activityId = homeData.activityId, group = homeData.group},
		POST.SKIN_CARNIVAL_CHALLENGE_QUEST_AT.sglName,

		POST.SKIN_CARNIVAL_CHALLENGE_QUEST_GRADE.cmdName ,
		{activityId = homeData.activityId, group = homeData.group},
		POST.SKIN_CARNIVAL_CHALLENGE_QUEST_GRADE.sglName,
		nil,
		nil,
		nil
	)
	local fromToStruct = BattleMediatorsConnectStruct.New(
		"activity.skinCarnival.ActivitySkinCarnivalChallengeMediator",
		"activity.skinCarnival.ActivitySkinCarnivalMediator"
	)
	local battleData = {
		questBattleType = QuestBattleType.SKIN_CARNIVAL,
		settlementType = ConfigBattleResultType.ONLY_RESULT,
		rivalTeamData = challengeData.enemies,
		serverCommand = serverCommand,
		fromtoData = fromToStruct
	}
	local teamData = {}
	if challengeData.enemies.lastChallengeCards then
		for i, v in ipairs(challengeData.enemies.lastChallengeCards) do
			table.insert(teamData, {id = v})
		end
    end
    local banConfig = CommonUtils.GetConfig('skinCarnival', 'questBan', homeData.group)
	local editTeamLayer = require('Game.views.pvc.PVCChangeTeamScene').new({
		teamDatas             = {[1] = teamData},
		teamTowards           = -1,
		avatarTowards         = 1,
		isDisableHomeTopSignal = true,
		battleData 	 	 	  = battleData,
		banList 	 	      = banConfig,
	}) 
	editTeamLayer:setAnchorPoint(display.CENTER)
	editTeamLayer:setPosition(display.center)
	editTeamLayer:setTag(4001)
	app.uiMgr:GetCurrentScene():AddDialog(editTeamLayer)
end
-------------------- handler --------------------
-------------------------------------------------

-------------------------------------------------
-------------------- private --------------------
--[[
初始化页面
--]]
function ActivitySkinCarnivalChallengeMediator:InitView()
    -- 刷新标题
    self:RefreshTitle()
    -- 刷新皮肤购买消耗
    self:RefreshBuySkinConsume()
    -- 刷新按钮状态
    self:RefreshBtnState()
    -- 刷新挑战列表
    self:RefreshChallengeListView()
    -- 刷新敌人
    self:RefreshEnemy()
end
--[[
刷新标题
--]]
function ActivitySkinCarnivalChallengeMediator:RefreshTitle()
    local homeData = self:GetHomeData()
    local viewComponent = self:GetViewComponent()
    viewComponent:RefreshTitle(homeData.title)
end
--[[
刷新皮肤购买消耗
--]]
function ActivitySkinCarnivalChallengeMediator:RefreshBuySkinConsume()
    local homeData = self:GetHomeData()
    local currency = checkint(homeData.currency) -- 购买所需货币
    local price = checkint(homeData.price) -- 皮肤价格
    local viewComponent = self:GetViewComponent()
    viewComponent:RefreshBuyBtnConsumeRichlabel({goodsId = currency, num = price})
end
--[[
刷新皮肤节点
--]]
function ActivitySkinCarnivalChallengeMediator:RefreshSkin()
    local viewComponent = self:GetViewComponent()
    local homeData = self:GetHomeData()
    local skinId = self:GetSkinId()
    viewComponent:RefreshSkinDrawNode(skinId, homeData.showEffect)
    viewComponent:ShowCardSkin()
end
--[[
刷新按钮状态
--]]
function ActivitySkinCarnivalChallengeMediator:RefreshBtnState()
    local viewComponent = self:GetViewComponent()
    local skinId = self:GetSkinId()
    local challengeData = self:GetChallengeData()
    viewComponent:RefreshBtnState(app.cardMgr.IsHaveCardSkin(skinId), challengeData.discountId)
end
--[[
刷新挑战列表
--]]
function ActivitySkinCarnivalChallengeMediator:RefreshChallengeListView()
    local viewComponent = self:GetViewComponent()
    local homeData = self:GetHomeData()
    local challengeData = self:GetChallengeData()
    local config = CommonUtils.GetConfigAllMess('questDiscount', 'skinCarnival')
    local listData = {}
    for k, v in orderedPairs(config) do
        if checkint(v.group) == checkint(homeData.group) then
            local temp = {
                currency = checkint(v.currency),
                price    = checkint(v.price),
                displayDiscount = tonumber(v.displayDiscount),
                condition = v.conditionDescr,
                discountId = checkint(v.id),
            }
            table.insert(listData, temp)
        end
    end
    viewComponent:RefreshChallengeListView(listData, challengeData.discountId, handler(self, self.DiscountBuyButtonCallback))
end
--[[
刷新敌人
--]]
function ActivitySkinCarnivalChallengeMediator:RefreshEnemy()
    local challengeData = self:GetChallengeData()
    local viewComponent = self:GetViewComponent()
    viewComponent:RefreshEnemy(challengeData.enemies)
end
function ActivitySkinCarnivalChallengeMediator:EnterLayer()
    local homeData = self:GetHomeData()
    self:SendSignal(POST.SKIN_CARNIVAL_CHALLENGE.cmdName, {activityId = homeData.activityId, group = homeData.group})
end
-------------------- private --------------------
-------------------------------------------------

-------------------------------------------------
------------------- get / set -------------------
--[[
获取homeData
--]]
function ActivitySkinCarnivalChallengeMediator:GetHomeData()
    return self.homeData
end
--[[
设置任务数据
--]]
function ActivitySkinCarnivalChallengeMediator:SetChallengeData( challengeData )
    self.challengeData = checktable(challengeData)
end
--[[
获取任务数据
--]]
function ActivitySkinCarnivalChallengeMediator:GetChallengeData()
    return self.challengeData
end
--[[
获取皮肤id
--]]
function ActivitySkinCarnivalChallengeMediator:GetSkinId()
    local homeData = self:GetHomeData()
    return checkint(homeData.skinId)
end
------------------- get / set -------------------
-------------------------------------------------
return ActivitySkinCarnivalChallengeMediator
