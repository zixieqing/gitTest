--[[
 * author : liuzhipeng
 * descpt : 活动 周年庆19 主界面Mediator
]]
---@class Anniversary19HomeMediator : Mediator
local Anniversary19HomeMediator = class('Anniversary19HomeMediator', mvc.Mediator)
local NAME = "anniversary19.Anniversary19HomeMediator"
function Anniversary19HomeMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
end
local TOP_BTN_TAG = {
    STORY = 1, 
    CARD  = 2,
    SHOP  = 3,
}
-------------------------------------------------
------------------ inheritance ------------------
function Anniversary19HomeMediator:Initial( key )
    self.super.Initial(self, key)
    local viewComponent = app.uiMgr:SwitchToTargetScene('Game.views.anniversary19.Anniversary19HomeSence')
    self:SetViewComponent(viewComponent)
    local viewData = viewComponent.viewData
    viewData.treeSpine:registerSpineEventHandler(handler(self, self.TreeSpineEndCallback), sp.EventType.ANIMATION_END)
    viewData.tabNameLabel:setOnClickScriptHandler(handler(self, self.TabTipsButtonCallback))
    viewData.rewardBtn:setOnClickScriptHandler(handler(self, self.RewardButtonCallback))
    viewData.exploreBtn:setOnClickScriptHandler(handler(self, self.ExploreButtonCallback))
    viewData.wonderlandBtn:setOnClickScriptHandler(handler(self, self.Anniversary19ButtonCallback))
    viewData.lotteryBtn:setOnClickScriptHandler(handler(self, self.LotteryButtonCallback))
    viewData.backBtn:setOnClickScriptHandler(handler(self, self.BackHomeMediator))
    for i, v in ipairs(viewData.topBtnComponentList) do
        v.btn:setOnClickScriptHandler(handler(self, self.TopButtonCallback))
    end
    if self.payload then
        app.anniversary2019Mgr:InitData(self.payload)
        self:InitView()
    end
end

function Anniversary19HomeMediator:InterestSignals()
    local signals = {
        POST.ANNIVERSARY2_HOME.sglName,
        POST.ANNIVERSARY2_STORY_UNLOCK.cmdName, 
        SIGNALNAMES.CACHE_MONEY_UPDATE_UI,
        SGL.REFRESH_NOT_CLOSE_GOODS_EVENT,
        SGL.NEXT_TIME_DATE,
        'ANNIVERSARY19_HOME_SHOW_SLEEP_SPINE',
	}
	return signals
end
function Anniversary19HomeMediator:ProcessSignal( signal )
    local name = signal:GetName()
    local body = signal:GetBody()
    if name == POST.ANNIVERSARY2_HOME.sglName then -- home
        app.anniversary2019Mgr:InitData(body)
        self:GetViewComponent():UpdateMoneyBar()
    elseif name == POST.ANNIVERSARY2_STORY_UNLOCK.sglName then -- 剧情解锁
        local requestData = body.requestData or {}
        app.anniversary2019Mgr:UpdateUnlockStoryMap(requestData.storyId)
    elseif name == SIGNALNAMES.CACHE_MONEY_UPDATE_UI then -- 刷新顶部状态栏
        self:GetViewComponent():UpdateGoodsNum()
    elseif name == SGL.REFRESH_NOT_CLOSE_GOODS_EVENT then
        self:GetViewComponent():UpdateGoodsNum()
    elseif name == SGL.NEXT_TIME_DATE then -- 同步本地数据
        self:SendSignal(POST.ANNIVERSARY2_HOME.cmdName)
    elseif name == 'ANNIVERSARY19_HOME_SHOW_SLEEP_SPINE' then
        self:GetViewComponent():ShowSleepSpine()
    end
end

function Anniversary19HomeMediator:OnRegist()
    app.anniversary2019Mgr:PlayBGMusic("Food_alice_dream")
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightHide")
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "allhide")
    regPost(POST.ANNIVERSARY2_HOME)
    regPost(POST.ANNIVERSARY2_STORY_UNLOCK)
end
function Anniversary19HomeMediator:OnUnRegist()
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightShow")
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "hide")
    unregPost(POST.ANNIVERSARY2_HOME)
    unregPost(POST.ANNIVERSARY2_STORY_UNLOCK)
    app.anniversary2019Mgr:RemoveSpineCache()
end
------------------ inheritance ------------------
-------------------------------------------------

-------------------------------------------------
-------------------- handler --------------------
--[[
提示按钮点击回调
--]]
function Anniversary19HomeMediator:TabTipsButtonCallback( sender )
    PlayAudioByClickNormal()
    -- todo -- 
    app.uiMgr:ShowIntroPopup({moduleId = MODULE_DATA.ANNIVERSARY19})
end
--[[
奖励按钮点击回调
--]]
function Anniversary19HomeMediator:RewardButtonCallback( sender )
    PlayAudioByClickNormal()
    local mediator = require("Game.mediator.anniversary19.Anniversary19PlotRewardMediator").new()
    app:RegistMediator(mediator)
end
--[[
探索按钮点击回调
--]]
function Anniversary19HomeMediator:ExploreButtonCallback( sender )
    PlayAudioByClickNormal()
    if app.anniversary2019Mgr:IsEnd() then
        app.uiMgr:ShowInformationTips(__('当前活动已结束'))
        return
    end
    -- app.anniversary2019Mgr:CheckStoryIsUnlocked(2, function ()
    --     --todo 进入 探索界面
        
    -- end)
    app:RetrieveMediator('Router'):Dispatch({name = NAME}, {name = 'anniversary19.Anniversary19ExploreMainMediator'})
end
--[[
幻境按钮点击回调
--]]
function Anniversary19HomeMediator:Anniversary19ButtonCallback( sender )
    PlayAudioByClickNormal()

    if app.anniversary2019Mgr:IsEnd() then
        app.uiMgr:ShowInformationTips(__('当前活动已结束'))
        return
    end
    -- 加上了needKeepGameScene之后
    -- 需要在Route里面添加exclude
    app:RetrieveMediator('Router'):Dispatch({name = 'HomeMediator'}, {name = 'anniversary19.Anniversary19SuppressMediator', params = {status = 1, needKeepGameScene = 1}})
end
--[[
抽奖按钮点击回调
--]]
function Anniversary19HomeMediator:LotteryButtonCallback( sender )
    PlayAudioByClickNormal()
    local viewComponent = self:GetViewComponent()
    viewComponent:HideSleepSpine()
    local mediator = require('Game.mediator.anniversary19.Anniversary19LotteryMediator').new()
    app:RegistMediator(mediator)
end
--[[
返回主界面
--]]
function Anniversary19HomeMediator:BackHomeMediator( sender )
    PlayAudioByClickClose()
    PlayBGMusic()
    self:GetFacade():BackHomeMediator()
end
--[[
顶部按钮点击回调
--]]
function Anniversary19HomeMediator:TopButtonCallback( sender )
    PlayAudioByClickNormal()
    local tag = sender:getTag()
    if tag == TOP_BTN_TAG.STORY then
        self:StoryButtonCallback(sender)
    elseif tag == TOP_BTN_TAG.CARD then
        self:CardButtonCallback(sender)
    elseif tag == TOP_BTN_TAG.SHOP then
        self:ShopButtonCallback(sender)
    end
end
--[[
剧情按钮点击回调
--]]
function Anniversary19HomeMediator:StoryButtonCallback( sender )
    PlayAudioByClickNormal()
    local mediator = require("Game.mediator.anniversary19.Anniversary19StoryMeditaor").new()
    app:RegistMediator(mediator)
end
--[[
打牌按钮点击回调
--]]
function Anniversary19HomeMediator:CardButtonCallback( sender )
    PlayAudioByClickNormal()
    if app.anniversary2019Mgr:IsEnd() then
        app.uiMgr:ShowInformationTips(__('当前活动已结束'))
        return
    end
    app.router:Dispatch({name = "HomeMediator"}, {name = "ttGame.TripleTriadGameHomeMediator", params = {backMdt = 'anniversary19.Anniversary19HomeMediator'}})
end
--[[
商店按钮点击回调
--]]
function Anniversary19HomeMediator:ShopButtonCallback( sender )
    PlayAudioByClickNormal()
    local mediator = require("Game.mediator.anniversary19.Anniversary19ShopMeditaor").new()
    app:RegistMediator(mediator)
end
--[[
treeSpine动画结束回调
--]]
function Anniversary19HomeMediator:TreeSpineEndCallback( event )
    local viewComponent = self:GetViewComponent()
    viewComponent:RandomTreeSpineAnimation()
end
-------------------- handler --------------------
-------------------------------------------------

-------------------------------------------------
-------------------- private --------------------
--[[
初始化view
--]]
function Anniversary19HomeMediator:InitView()
    local view = self:GetViewComponent()
    local viewComponent = self:GetViewComponent()
    -- 更新顶部道具栏
    local moneyIdMap = {}
    moneyIdMap[tostring(app.anniversary2019Mgr:GetHPGoodsId())] = app.anniversary2019Mgr:GetHPGoodsId()
    view:ReloadMoneyBar(moneyIdMap, false)
    -- 判断开始剧情是否播放
    local paramConfig = CommonUtils.GetConfigAllMess('parameter', 'anniversary2')
    if app.anniversary2019Mgr:IsStoryUnlock(paramConfig.story1) then
        viewComponent:EnterAction('play2')
    else
        app.anniversary2019Mgr:CheckStoryIsUnlocked(paramConfig.story1, function()
            viewComponent:EnterAction('play1')
        end)
    end
    -- 刷新点数
    viewComponent:RefreshRewardPointNum()
end
-------------------- private --------------------
-------------------------------------------------

-------------------------------------------------
------------------- get / set -------------------
--[[
设置homeData
--]]
function Anniversary19HomeMediator:SetHomeData( homeData )
    self.homeData = homeData
end
--[[
获取homeData
--]]
function Anniversary19HomeMediator:GetHomeData()
    return self.homeData
end
------------------- get / set -------------------
-------------------------------------------------
return Anniversary19HomeMediator
