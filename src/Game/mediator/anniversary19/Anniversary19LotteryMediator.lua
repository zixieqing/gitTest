--[[
 * author : liuzhipeng
 * descpt : 活动 周年庆19 抽奖Mediator
]]
local Anniversary19LotteryMediator = class('Anniversary19LotteryMediator', mvc.Mediator)
local NAME = "anniversary19.Anniversary19LotteryMediator"
function Anniversary19LotteryMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.homeData = {}
    self.lotteryData = {}
    self.lotteryTimes = 1
end
-------------------------------------------------
------------------ inheritance ------------------
function Anniversary19LotteryMediator:Initial( key )
    self.super.Initial(self, key)
	local viewComponent  = require('Game.views.anniversary19.Anniversary19LotteryView').new()
	viewComponent:setPosition(display.center)
	app.uiMgr:GetCurrentScene():AddDialog(viewComponent)
    self:SetViewComponent(viewComponent)
    local viewData = viewComponent.viewData
    viewData.tabNameLabel:setOnClickScriptHandler(handler(self, self.TabTipsButtonCallback))
    viewData.backBtn:setOnClickScriptHandler(handler(self, self.BackButtonCallback))
    viewData.probabilityBtn:setOnClickScriptHandler(handler(self, self.ProbabilityButtonCallback)) 
    viewData.rareRewardBtn:setOnClickScriptHandler(handler(self, self.RareRewardButtonCallback))
    viewData.drawOneBtn:setOnClickScriptHandler(handler(self, self.DrawOneButtonCallback))
    viewData.drawTenBtn:setOnClickScriptHandler(handler(self, self.DrawTenButtonCallback))
    -- 绑定spine事件
    viewData.rewardSpine:registerSpineEventHandler(handler(self, self.RwardSpineEndCallback), sp.EventType.ANIMATION_END)
end

function Anniversary19LotteryMediator:InterestSignals()
    local signals = {
        POST.ANNIVERSARY2_LOTTERY_HOME.sglName,
        POST.ANNIVERSARY2_LOTTERY.sglName,
        SGL.REFRESH_NOT_CLOSE_GOODS_EVENT,
	}
	return signals
end
function Anniversary19LotteryMediator:ProcessSignal( signal )
    local name = signal:GetName()
    local body = signal:GetBody()
    if name == POST.ANNIVERSARY2_LOTTERY_HOME.sglName then -- home
        self:SetHomeData(body)
        self:ConvertLotteryData()
        self:InitView()
        AppFacade.GetInstance():DispatchObservers("REFRESH_ANNIVERASARY19_LOTTERY_RARE_VIEW", body)
    elseif name == POST.ANNIVERSARY2_LOTTERY.sglName then -- 抽奖
        -- 扣除道具
        local comsume = app.anniversary2019Mgr:GetLotteryConsume()
        local lotteryTimes = checkint(body.requestData.lotteryTimes)
        local temp = {
            goodsId = checkint(comsume.goodsId),
            num = - checkint(comsume.num) * lotteryTimes,
        }
        CommonUtils.DrawRewards({temp})
        self.rewards = body
        -- 判断是否弹出tips提示
        local leftNum = self:GetLeftRewardsNum() - lotteryTimes
        if leftNum == 0 then
            self.rewards.closeCallback = function ()
                app.uiMgr:AddDialog('Game.views.anniversary19.Anniversary19LotteryTipsView')
            end
        end
        app.uiMgr:GetCurrentScene():AddViewForNoTouch()
        local viewComponent = self:GetViewComponent()
        if lotteryTimes > 1 and app.anniversary2019Mgr.CHANGE_SKIN_CONF.SKIN_MODE then
            viewComponent:ShowRewardSpine("play2")
        else
            viewComponent:ShowRewardSpine("play")
        end

    elseif name == SGL.REFRESH_NOT_CLOSE_GOODS_EVENT then
        self:GetViewComponent():UpdateGoodsNum()
    end
end

function Anniversary19LotteryMediator:OnRegist()
    regPost(POST.ANNIVERSARY2_LOTTERY_HOME)
    regPost(POST.ANNIVERSARY2_LOTTERY)
    self:EnterLayer()
end
function Anniversary19LotteryMediator:OnUnRegist()
    unregPost(POST.ANNIVERSARY2_LOTTERY_HOME)
    unregPost(POST.ANNIVERSARY2_LOTTERY)
    -- 移除界面
	local scene = app.uiMgr:GetCurrentScene()
	scene:RemoveDialog(self:GetViewComponent())
end
------------------ inheritance ------------------
-------------------------------------------------

-------------------------------------------------
-------------------- handler --------------------
--[[
提示按钮点击回调
--]]
function Anniversary19LotteryMediator:TabTipsButtonCallback( sender )
    PlayAudioByClickNormal()
    app.uiMgr:ShowIntroPopup({moduleId = '-42'})
end
--[[
返回按钮回调
--]]
function Anniversary19LotteryMediator:BackButtonCallback( sender )
    PlayAudioByClickClose()
    AppFacade.GetInstance():DispatchObservers('ANNIVERSARY19_HOME_SHOW_SLEEP_SPINE')
    app:UnRegsitMediator("anniversary19.Anniversary19LotteryMediator")
end
--[[
概率按钮点击回调
--]]
function Anniversary19LotteryMediator:ProbabilityButtonCallback( sender )
    PlayAudioByClickNormal()
    local homeData = self:GetHomeData()
    local rate = {}
    local rateConf = CommonUtils.GetConfig('anniversary2', 'lotterryRate', homeData.groupId)
    for i, v in orderedPairs(rateConf) do
        table.insert(rate, {descr = v.descr, rate = v.pro})
    end
    local capsuleProbabilityView = require( 'Game.views.drawCards.CapsuleProbabilityView' ).new({rate = rate})
    display.commonLabelParams(capsuleProbabilityView.viewData_.title, fontWithColor(18, {text = app.anniversary2019Mgr:GetPoText(__('概率'))}))
    local scene = app.uiMgr:GetCurrentScene()
    scene:AddDialog(capsuleProbabilityView)
end
--[[]
稀有奖励按钮回调
--]]
function Anniversary19LotteryMediator:RareRewardButtonCallback( sender )
    PlayAudioByClickNormal()
    local homeData = self:GetHomeData()
    local params = {groupId = homeData.groupId, drawnRewards = homeData.rewards}
    local mediator = require('Game.mediator.anniversary19.Anniversary19LotteryRareMediator').new(params)
    app:RegistMediator(mediator)
end
--[[
抽一次按钮回调
--]]
function Anniversary19LotteryMediator:DrawOneButtonCallback( sender )
    PlayAudioByClickNormal()
    -- 判断道具是否足够
    local consume = app.anniversary2019Mgr:GetLotteryConsume()
    if app.gameMgr:GetAmountByIdForce(consume.goodsId) >= checkint(consume.num) then
        self:SendSignal(POST.ANNIVERSARY2_LOTTERY.cmdName, {lotteryTimes = 1})
    else
        local conf = CommonUtils.GetConfig('goods', 'goods', consume.goodsId) or {}
        app.uiMgr:ShowInformationTips(string.fmt(app.anniversary2019Mgr:GetPoText(__('_name_不足')), {['_name_'] = tostring(conf.name)}))
    end
end
--[[
抽十次按钮回调
--]]
function Anniversary19LotteryMediator:DrawTenButtonCallback( sender )
    PlayAudioByClickNormal()
    local consume = app.anniversary2019Mgr:GetLotteryConsume()
    if app.gameMgr:GetAmountByIdForce(consume.goodsId) >= checkint(consume.num) * 10 then
        self:SendSignal(POST.ANNIVERSARY2_LOTTERY.cmdName, {lotteryTimes = 10})
    else
        local conf = CommonUtils.GetConfig('goods', 'goods', consume.goodsId) or {}
        app.uiMgr:ShowInformationTips(string.fmt(app.anniversary2019Mgr:GetPoText(__('_name_不足')), {['_name_'] = tostring(conf.name)}))
    end
end
--[[
奖励spine结束回调
--]]
function Anniversary19LotteryMediator:RwardSpineEndCallback( event )
    if event.animation == 'play' or event.animation == 'play2' then
        local viewComponent = self:GetViewComponent()
        viewComponent:HideRewardSpine()
        app.uiMgr:AddDialog('common.RewardPopup', self.rewards)
        app.uiMgr:GetCurrentScene():RemoveViewForNoTouch()
        self:SendSignal(POST.ANNIVERSARY2_LOTTERY_HOME.cmdName)

	end
end
-------------------- handler --------------------
-------------------------------------------------

-------------------------------------------------
-------------------- private --------------------
--[[

--]]
function Anniversary19LotteryMediator:ConvertLotteryData()
    local homeData = self:GetHomeData()
    local lotteryData = {
        rareRewards = {},
        commonRewards = {}
    }
    local rewardPoolConf = CommonUtils.GetConfigAllMess('lotteryPool', 'anniversary2')
    for i, v in orderedPairs(rewardPoolConf) do
        if checkint(v.group) == checkint(homeData.groupId) then
            local temp = clone(v)
            if homeData.rewards[tostring(temp.id)] then
                temp.stock = checkint(temp.num) - checkint(homeData.rewards[tostring(temp.id)])
            else
                temp.stock = checkint(temp.num)
            end
            if checkint(v.isRare) == 1 then
                -- 稀有
                table.insert(lotteryData.rareRewards, temp)
            else
                -- 普通
                table.insert(lotteryData.commonRewards, temp)
            end
        end
    end
    self:SetLotteryData(lotteryData)
end
--[[
初始化view
--]]
function Anniversary19LotteryMediator:InitView()
    local viewComponent = self:GetViewComponent()
    -- 更新顶部道具栏
    local moneyIdMap = {}
    local goodsId = app.anniversary2019Mgr:GetLotteryConsume().goodsId
    moneyIdMap[tostring(goodsId)] = goodsId
    viewComponent:ReloadMoneyBar(moneyIdMap, false)
    -- 刷新奖励Layout
    self:RefreshRewardLayout()
    -- 刷新抽奖Layout
    self:RefreshLotteryLayout()
    -- 刷新卡牌Layout
    self:RefreshCardLayout()
end
--[[
刷新奖励layout
--]]
function Anniversary19LotteryMediator:RefreshRewardLayout()
    local viewComponent = self:GetViewComponent()
    local lotteryData = self:GetLotteryData()
    local homeData = self:GetHomeData()
    local totalNum = self:GetTotalRewardsNum()
    local leftNum  = self:GetLeftRewardsNum()
    local params = {
        round       = checkint(homeData.round),
        totalNum    = totalNum,
        leftNum     = leftNum,
        lotteryData = lotteryData,
    }
    viewComponent:RefreshRewardLayout(params)
end
--[[
刷新抽奖layout
--]]
function Anniversary19LotteryMediator:RefreshLotteryLayout()
    local viewComponent = self:GetViewComponent()
    local paramConfig = CommonUtils.GetConfigAllMess('parameter', 'anniversary2')
    local consume = app.anniversary2019Mgr:GetLotteryConsume()
    local leftNum = self:GetLeftRewardsNum()
    local params = {
        consume = consume,
        leftNum = leftNum,
    }
    viewComponent:RefreshLotteryLayout(params)
end
--[[
刷新卡牌layout
--]]
function Anniversary19LotteryMediator:RefreshCardLayout()
    local viewComponent = self:GetViewComponent()
    local paramConfig = CommonUtils.GetConfigAllMess('parameter', 'anniversary2')
    viewComponent:RefreshCardLayout(paramConfig.gashaponNpc)
end
function Anniversary19LotteryMediator:EnterLayer()
	self:SendSignal(POST.ANNIVERSARY2_LOTTERY_HOME.cmdName)
end
-------------------- private --------------------
-------------------------------------------------

-------------------------------------------------
------------------- get / set -------------------
--[[
设置homeData
--]]
function Anniversary19LotteryMediator:SetHomeData( homeData )
    self.homeData = homeData
end
--[[
获取homeData
--]]
function Anniversary19LotteryMediator:GetHomeData()
    return self.homeData or {}
end
--[[
设置奖励数据
--]]
function Anniversary19LotteryMediator:SetLotteryData( lotteryData )
    self.lotteryData = checktable(lotteryData)
end
--[[
获取奖励数据
--]]
function Anniversary19LotteryMediator:GetLotteryData()
    return self.lotteryData or {}
end
--[[
获取总奖励数量
--]]
function Anniversary19LotteryMediator:GetTotalRewardsNum()
    local lotteryData = self:GetLotteryData()
    local totalNum = 0
    for i, v in ipairs(lotteryData.rareRewards) do
        totalNum = totalNum + checkint(v.num)
    end
    for i, v in ipairs(lotteryData.commonRewards) do
        totalNum = totalNum + checkint(v.num)
    end
    return totalNum
end
--[[
获取总奖励数量
--]]
function Anniversary19LotteryMediator:GetLeftRewardsNum()
    local lotteryData = self:GetLotteryData()
    local leftNum = 0
    for i, v in ipairs(lotteryData.rareRewards) do
        leftNum = leftNum + checkint(v.stock)
    end
    for i, v in ipairs(lotteryData.commonRewards) do
        leftNum = leftNum + checkint(v.stock)
    end
    return leftNum
end
------------------- get / set -------------------
-------------------------------------------------
return Anniversary19LotteryMediator
