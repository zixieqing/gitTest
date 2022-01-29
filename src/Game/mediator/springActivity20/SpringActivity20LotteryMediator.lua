--[[
 * author : liuzhipeng
 * descpt : 活动 20春活 抽奖Mediator
]]
local SpringActivity20LotteryMediator = class('SpringActivity20LotteryMediator', mvc.Mediator)
local NAME = "springActivity20.SpringActivity20LotteryMediator"
function SpringActivity20LotteryMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.homeData = {}
    self.lotteryData = {}
end
-------------------------------------------------
------------------ inheritance ------------------
function SpringActivity20LotteryMediator:Initial( key )
    self.super.Initial(self, key)
	local viewComponent  = require('Game.views.springActivity20.SpringActivity20LotteryView').new()
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

function SpringActivity20LotteryMediator:InterestSignals()
    local signals = {
        POST.SPRING_ACTIVITY_20_LOTTERY_HOME.sglName,
        POST.SPRING_ACTIVITY_20_LOTTERY.sglName,
        SGL.REFRESH_NOT_CLOSE_GOODS_EVENT,
	}
	return signals
end
function SpringActivity20LotteryMediator:ProcessSignal( signal )
    local name = signal:GetName()
    local body = signal:GetBody()
    if name == POST.SPRING_ACTIVITY_20_LOTTERY_HOME.sglName then -- home
        self:SetHomeData(body)
        self:ConvertLotteryData()
        self:InitView()
        AppFacade.GetInstance():DispatchObservers("REFRESH_ANNIVERASARY19_LOTTERY_RARE_VIEW", body)
    elseif name == POST.SPRING_ACTIVITY_20_LOTTERY.sglName then -- 抽奖
        -- 扣除道具
        local comsume = app.springActivity20Mgr:GetLotteryConsume()
        local temp = {
            goodsId = checkint(comsume.goodsId),
            num = - checkint(comsume.num) * body.requestData.times,
        }
        CommonUtils.DrawRewards({temp})
        self.rewards = body
        -- 判断是否弹出tips提示
        local leftNum = self:GetLeftRewardsNum() - body.requestData.times
        if leftNum == 0 then
            self.rewards.closeCallback = function ()
                app.uiMgr:AddDialog('Game.views.springActivity20.SpringActivity20LotteryEmptyTipsView')
            end
        end

        app.uiMgr:GetCurrentScene():AddViewForNoTouch()
        local viewComponent = self:GetViewComponent(body.requestData.times)
        viewComponent:ShowRewardSpine()
    elseif name == SGL.REFRESH_NOT_CLOSE_GOODS_EVENT then
        self:GetViewComponent():UpdateGoodsNum()
    end
end

function SpringActivity20LotteryMediator:OnRegist()
    regPost(POST.SPRING_ACTIVITY_20_LOTTERY_HOME)
    regPost(POST.SPRING_ACTIVITY_20_LOTTERY)
    self:EnterLayer()
end
function SpringActivity20LotteryMediator:OnUnRegist()
    unregPost(POST.SPRING_ACTIVITY_20_LOTTERY_HOME)
    unregPost(POST.SPRING_ACTIVITY_20_LOTTERY)
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
function SpringActivity20LotteryMediator:TabTipsButtonCallback( sender )
    PlayAudioByClickNormal()
    app.uiMgr:ShowIntroPopup({moduleId = '-62'})
end
--[[
返回按钮回调
--]]
function SpringActivity20LotteryMediator:BackButtonCallback( sender )
    PlayAudioByClickClose()
    app:UnRegsitMediator("springActivity20.SpringActivity20LotteryMediator")
end
--[[
概率按钮点击回调
--]]
function SpringActivity20LotteryMediator:ProbabilityButtonCallback( sender )
    PlayAudioByClickNormal()
    local homeData = self:GetHomeData()
    local rate = {}
    local rateConf = CommonUtils.GetConfig('springActivity2020', 'lotteryRate', homeData.groupId)
    for i, v in orderedPairs(rateConf) do
        table.insert(rate, {descr = v.descr, rate = v.pro})
    end
    local capsuleProbabilityView = require( 'Game.views.drawCards.CapsuleProbabilityView' ).new({rate = rate})
    display.commonLabelParams(capsuleProbabilityView.viewData_.title, fontWithColor(18, {text = app.springActivity20Mgr:GetPoText(__('概率'))}))
    local scene = app.uiMgr:GetCurrentScene()
    scene:AddDialog(capsuleProbabilityView)
end
--[[]
稀有奖励按钮回调
--]]
function SpringActivity20LotteryMediator:RareRewardButtonCallback( sender )
    PlayAudioByClickNormal()
    local homeData = self:GetHomeData()
    local rewardBaseConf = CommonUtils.GetConfigAllMess('lotteryLoop', 'springActivity2020')
    local rewardConf = CommonUtils.GetConfigAllMess('lottery', 'springActivity2020')
    local params = {
        groupId = homeData.groupId, 
        drawnRewards = homeData.rewards,
        rewardBaseConf = rewardBaseConf,
        rewardConf = rewardConf,
    }
    local mediator = require('Game.mediator.anniversary19.Anniversary19LotteryRareMediator').new(params)
    app:RegistMediator(mediator)
end
--[[
抽一次按钮回调
--]]
function SpringActivity20LotteryMediator:DrawOneButtonCallback( sender )
    PlayAudioByClickNormal()
    -- 判断道具是否足够
    local consume = app.springActivity20Mgr:GetLotteryConsume()
    if app.gameMgr:GetAmountByIdForce(consume.goodsId) >= checkint(consume.num) then
        self:SendSignal(POST.SPRING_ACTIVITY_20_LOTTERY.cmdName, {times = 1})
    else
        local conf = CommonUtils.GetConfig('goods', 'goods', consume.goodsId) or {}
        app.uiMgr:ShowInformationTips(string.fmt(app.springActivity20Mgr:GetPoText(__('_name_不足')), {['_name_'] = tostring(conf.name)}))
    end
end
--[[
抽十次按钮回调
--]]
function SpringActivity20LotteryMediator:DrawTenButtonCallback( sender )
    PlayAudioByClickNormal()
    local consume = app.springActivity20Mgr:GetLotteryConsume()
    if app.gameMgr:GetAmountByIdForce(consume.goodsId) >= checkint(consume.num) * 10 then
        self:SendSignal(POST.SPRING_ACTIVITY_20_LOTTERY.cmdName, {times = 10})
    else
        local conf = CommonUtils.GetConfig('goods', 'goods', consume.goodsId) or {}
        app.uiMgr:ShowInformationTips(string.fmt(app.springActivity20Mgr:GetPoText(__('_name_不足')), {['_name_'] = tostring(conf.name)}))
    end
end
--[[
奖励spine结束回调
--]]
function SpringActivity20LotteryMediator:RwardSpineEndCallback( event )
    if event.animation == 'play1' or event.animation == 'play2' then
        local viewComponent = self:GetViewComponent()
        viewComponent:HideRewardSpine()
        app.uiMgr:AddDialog('common.RewardPopup', self.rewards)
        app.uiMgr:GetCurrentScene():RemoveViewForNoTouch()
        self:SendSignal(POST.SPRING_ACTIVITY_20_LOTTERY_HOME.cmdName)
	end
end
-------------------- handler --------------------
-------------------------------------------------

-------------------------------------------------
-------------------- private --------------------
--[[
转换抽奖数据
--]]
function SpringActivity20LotteryMediator:ConvertLotteryData()
    local homeData = self:GetHomeData()
    local lotteryData = {
        rareRewards = {},
        commonRewards = {}
    }
    local rewardPoolConf = CommonUtils.GetConfigAllMess('lottery', 'springActivity2020')
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
function SpringActivity20LotteryMediator:InitView()
    local viewComponent = self:GetViewComponent()
    -- 更新顶部道具栏
    local moneyIdMap = {}
    local goodsId = app.springActivity20Mgr:GetLotteryConsume().goodsId
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
function SpringActivity20LotteryMediator:RefreshRewardLayout()
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
function SpringActivity20LotteryMediator:RefreshLotteryLayout()
    local viewComponent = self:GetViewComponent()
    local paramConfig = CommonUtils.GetConfigAllMess('param', 'springActivity2020')
    local consume = app.springActivity20Mgr:GetLotteryConsume()
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
function SpringActivity20LotteryMediator:RefreshCardLayout()
    local viewComponent = self:GetViewComponent()
    local paramConfig = CommonUtils.GetConfigAllMess('param', 'springActivity2020')
    viewComponent:RefreshCardLayout(paramConfig.gashaponNpc)
end
function SpringActivity20LotteryMediator:EnterLayer()
	self:SendSignal(POST.SPRING_ACTIVITY_20_LOTTERY_HOME.cmdName)
end
-------------------- private --------------------
-------------------------------------------------

-------------------------------------------------
------------------- get / set -------------------
--[[
设置homeData
--]]
function SpringActivity20LotteryMediator:SetHomeData( homeData )
    self.homeData = homeData
end
--[[
获取homeData
--]]
function SpringActivity20LotteryMediator:GetHomeData()
    return self.homeData or {}
end
--[[
设置奖励数据
--]]
function SpringActivity20LotteryMediator:SetLotteryData( lotteryData )
    self.lotteryData = checktable(lotteryData)
end
--[[
获取奖励数据
--]]
function SpringActivity20LotteryMediator:GetLotteryData()
    return self.lotteryData or {}
end
--[[
获取总奖励数量
--]]
function SpringActivity20LotteryMediator:GetTotalRewardsNum()
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
function SpringActivity20LotteryMediator:GetLeftRewardsNum()
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
return SpringActivity20LotteryMediator
