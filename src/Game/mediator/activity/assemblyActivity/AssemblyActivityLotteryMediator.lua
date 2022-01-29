--[[
 * author : liuzhipeng
 * descpt : 活动 组合活动 抽奖Mediator
]]
local AssemblyActivityLotteryMediator = class('AssemblyActivityLotteryMediator', mvc.Mediator)
local NAME = "activity.assemblyActivity.AssemblyActivityLotteryMediator"
function AssemblyActivityLotteryMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    local args = checktable(params)
    self.activityId = checkint(args.activityId)
    self.homeData = {}
    self.lotteryData = {}
end
-------------------------------------------------
------------------ inheritance ------------------
function AssemblyActivityLotteryMediator:Initial( key )
    self.super.Initial(self, key)
end

function AssemblyActivityLotteryMediator:InterestSignals()
    local signals = {
        POST.ASSEMBLY_ACTIVITY_LOTTERY_HOME.sglName,
        POST.ASSEMBLY_ACTIVITY_LOTTERY_DRAW.sglName,
        SGL.REFRESH_NOT_CLOSE_GOODS_EVENT,
	}
	return signals
end
function AssemblyActivityLotteryMediator:ProcessSignal( signal )
    local name = signal:GetName()
    local body = signal:GetBody()
    if name == POST.ASSEMBLY_ACTIVITY_LOTTERY_HOME.sglName then -- home
        self:SetHomeData(body)
        self:ConvertLotteryData()
        self:InitView()
        self:RefreshView()
        AppFacade.GetInstance():DispatchObservers("REFRESH_ANNIVERASARY19_LOTTERY_RARE_VIEW", body)
    elseif name == POST.ASSEMBLY_ACTIVITY_LOTTERY_DRAW.sglName then -- 抽奖
        -- 扣除道具
        local comsume = self:GetConsume()
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
        local viewComponent = self:GetViewComponent()
        viewComponent:ShowRewardSpine()
    elseif name == SGL.REFRESH_NOT_CLOSE_GOODS_EVENT then
        self:GetViewComponent():UpdateGoodsNum()
    end
end

function AssemblyActivityLotteryMediator:OnRegist()
    regPost(POST.ASSEMBLY_ACTIVITY_LOTTERY_HOME)
    regPost(POST.ASSEMBLY_ACTIVITY_LOTTERY_DRAW)
    self:EnterLayer()
end
function AssemblyActivityLotteryMediator:OnUnRegist()
    unregPost(POST.ASSEMBLY_ACTIVITY_LOTTERY_HOME)
    unregPost(POST.ASSEMBLY_ACTIVITY_LOTTERY_DRAW)
end

function AssemblyActivityLotteryMediator:CleanupView()
    if self:GetViewComponent() and not tolua.isnull(self:GetViewComponent()) then
        local scene = app.uiMgr:GetCurrentScene()
        scene:RemoveDialog(self:GetViewComponent())
    end
end
------------------ inheritance ------------------
-------------------------------------------------

-------------------------------------------------
-------------------- handler --------------------
--[[
提示按钮点击回调
--]]
function AssemblyActivityLotteryMediator:TabTipsButtonCallback( sender )
    PlayAudioByClickNormal()
    app.uiMgr:ShowIntroPopup({moduleId = '-70'})
end
--[[
返回按钮回调
--]]
function AssemblyActivityLotteryMediator:BackButtonCallback( sender )
    PlayAudioByClickClose()
    app:UnRegsitMediator(NAME)
end
--[[
概率按钮点击回调
--]]
function AssemblyActivityLotteryMediator:ProbabilityButtonCallback( sender )
    PlayAudioByClickNormal()
    local lotteryData = self:GetLotteryData()
    local rate = {}
    for i, v in ipairs(lotteryData.rate ) do
        table.insert(rate, {descr = v.descr, rate = v.pro})
    end
    local LotteryProbabilityView = require( 'Game.views.drawCards.CapsuleProbabilityView' ).new({rate = rate})
    display.commonLabelParams(LotteryProbabilityView.viewData_.title, fontWithColor(18, {text = __('概率')}))
    local scene = app.uiMgr:GetCurrentScene()
    scene:AddDialog(LotteryProbabilityView)
end
--[[]
稀有奖励按钮回调
--]]
function AssemblyActivityLotteryMediator:RareRewardButtonCallback( sender )
    PlayAudioByClickNormal()
    local homeData = self:GetHomeData()
    local params = {
        groupId = homeData.groupId, 
        drawnRewards = homeData.rewards,
        rewardsData = homeData.groups,
    }
    local mediator = require('Game.mediator.anniversary19.Anniversary19LotteryRareMediator').new(params)
    app:RegistMediator(mediator)
end
--[[
抽一次按钮回调
--]]
function AssemblyActivityLotteryMediator:DrawOneButtonCallback( sender )
    PlayAudioByClickNormal()
    -- 判断道具是否足够
    local consume = self:GetConsume()
    if app.gameMgr:GetAmountByIdForce(consume.goodsId) >= checkint(consume.num) then
        self:SendSignal(POST.ASSEMBLY_ACTIVITY_LOTTERY_DRAW.cmdName, {times = 1, activityId = self.activityId})
    else
        local conf = CommonUtils.GetConfig('goods', 'goods', consume.goodsId) or {}
        app.uiMgr:ShowInformationTips(string.fmt(__('_name_不足'), {['_name_'] = tostring(conf.name)}))
        local mediator = require("Game.mediator.activity.assemblyActivity.AssemblyActivityStoreMediator").new({activityId = self.activityId})
        app:RegistMediator(mediator)
    end
end
--[[
抽十次按钮回调
--]]
function AssemblyActivityLotteryMediator:DrawTenButtonCallback( sender )
    PlayAudioByClickNormal()
    local consume = self:GetConsume()
    if app.gameMgr:GetAmountByIdForce(consume.goodsId) >= checkint(consume.num) * 10 then
        self:SendSignal(POST.ASSEMBLY_ACTIVITY_LOTTERY_DRAW.cmdName, {times = 10, activityId = self.activityId})
    else
        local conf = CommonUtils.GetConfig('goods', 'goods', consume.goodsId) or {}
        app.uiMgr:ShowInformationTips(string.fmt(__('_name_不足'), {['_name_'] = tostring(conf.name)}))
        local mediator = require("Game.mediator.activity.assemblyActivity.AssemblyActivityStoreMediator").new({activityId = self.activityId})
        app:RegistMediator(mediator)
    end
end
--[[
奖励spine结束回调
--]]
function AssemblyActivityLotteryMediator:RwardSpineEndCallback( event )
    if event.animation == 'play1' or event.animation == 'play2' or event.animation == 'play' then
        local viewComponent = self:GetViewComponent()
        viewComponent:HideRewardSpine()
        app.uiMgr:AddDialog('common.RewardPopup', self.rewards)
        app.uiMgr:GetCurrentScene():RemoveViewForNoTouch()
        self:SendSignal(POST.ASSEMBLY_ACTIVITY_LOTTERY_HOME.cmdName, {activityId = self.activityId})
	end
end
-------------------- handler --------------------
-------------------------------------------------

-------------------------------------------------
-------------------- private --------------------
--[[
转换抽奖数据
--]]
function AssemblyActivityLotteryMediator:ConvertLotteryData()
    local homeData = self:GetHomeData()
    local lotteryData = {
        rareRewards = {},
        commonRewards = {}
    }
    -- 计算当前组别属于哪一轮次
    local groupsIndex = 1
    local curRound = checkint(homeData.round)
    local round = 0
    for i, v in ipairs(homeData.groups) do
        round = round + checkint(v.loop)
        if curRound <= round then
            groupsIndex = i
            break
        end
    end
    for i, v in ipairs(homeData.groups[groupsIndex].totalRewards) do
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
    for i, v in ipairs(homeData.groups) do
        if checkint(homeData.groupId) == checkint(v.group) then
            lotteryData.rate = v.rate
            break
        end
    end
    self:SetLotteryData(lotteryData)
end
--[[
初始化view
--]]
function AssemblyActivityLotteryMediator:InitView()
    if self:GetViewComponent() and not tolua.isnull(self:GetViewComponent()) then return end
    local homeData = self:GetHomeData()
    local params = {
        npc      = homeData.npc,
        cartoon  = homeData.cartoon,
        cartoon2 = homeData.cartoon2
    }
	local viewComponent  = require('Game.views.activity.assemblyActivity.AssemblyActivityLotteryView').new(params)
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
--[[
刷新view
--]]
function AssemblyActivityLotteryMediator:RefreshView()
    local viewComponent = self:GetViewComponent()
    -- 更新顶部道具栏
    local moneyIdMap = {}
    local goodsId = self:GetConsume().goodsId
    moneyIdMap[tostring(goodsId)] = goodsId
    if viewComponent and (not tolua.isnull(viewComponent)) then
        viewComponent:ReloadMoneyBar(moneyIdMap, false)
    end
    -- 刷新奖励Layout
    self:RefreshRewardLayout()
    -- 刷新抽奖Layout
    self:RefreshLotteryLayout()
end
--[[
刷新奖励layout
--]]
function AssemblyActivityLotteryMediator:RefreshRewardLayout()
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
function AssemblyActivityLotteryMediator:RefreshLotteryLayout()
    local viewComponent = self:GetViewComponent()
    local consume = self:GetConsume()
    local leftNum = self:GetLeftRewardsNum()
    local params = {
        consume = consume,
        leftNum = leftNum,
    }
    viewComponent:RefreshLotteryLayout(params)
end

function AssemblyActivityLotteryMediator:EnterLayer()
	self:SendSignal(POST.ASSEMBLY_ACTIVITY_LOTTERY_HOME.cmdName, {activityId = self.activityId})
end
-------------------- private --------------------
-------------------------------------------------

-------------------------------------------------
------------------- get / set -------------------
--[[
设置homeData
--]]
function AssemblyActivityLotteryMediator:SetHomeData( homeData )
    self.homeData = homeData
end
--[[
获取homeData
--]]
function AssemblyActivityLotteryMediator:GetHomeData()
    return self.homeData or {}
end
--[[
设置奖励数据
--]]
function AssemblyActivityLotteryMediator:SetLotteryData( lotteryData )
    self.lotteryData = checktable(lotteryData)
end
--[[
获取奖励数据
--]]
function AssemblyActivityLotteryMediator:GetLotteryData()
    return self.lotteryData or {}
end
--[[
获取总奖励数量
--]]
function AssemblyActivityLotteryMediator:GetTotalRewardsNum()
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
function AssemblyActivityLotteryMediator:GetLeftRewardsNum()
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
--[[
获取抽奖消耗
--]]
function AssemblyActivityLotteryMediator:GetConsume()
    local homeData = self:GetHomeData()
    local consume = {
        goodsId = checkint(homeData.consumeGoodsId),
        num = checkint(homeData.consumeGoodsNum)
    }
    return consume
end
------------------- get / set -------------------
-------------------------------------------------
return AssemblyActivityLotteryMediator
