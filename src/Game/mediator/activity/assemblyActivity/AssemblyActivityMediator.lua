--[[
 * author : liuzhipeng
 * descpt : 活动 组合活动Mediator
--]]
local AssemblyActivityMediator = class('AssemblyActivityMediator', mvc.Mediator)
local NAME = "activity.assemblyActivity.AssemblyActivityMediator"
local MODULE_TYPE = {
    TASK        = 1,
    EXCHANGE    = 2,
    NINE_PALACE = 3,
    WHEEL       = 4,
    CAPSULE     = 5,
    STORE       = 6,
    RANK        = 7
}
function AssemblyActivityMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent) 
    self.activityId = checkint(params.activityId)
end
-------------------------------------------------
------------------ inheritance ------------------
function AssemblyActivityMediator:Initial( key )
    self.super.Initial(self, key)
    local viewComponent = app.uiMgr:SwitchToTargetScene('Game.views.activity.assemblyActivity.AssemblyActivityScene')
    self:SetViewComponent(viewComponent)
    local viewData = viewComponent.viewData
    viewData.backBtn:setOnClickScriptHandler(handler(self, self.BackButtonCallback))
    viewData.tabNameLabel:setOnClickScriptHandler(handler(self, self.TipsButtonCallback))
end

function AssemblyActivityMediator:InterestSignals()
    local signals = {
        POST.ASSEMBLY_ACTIVITY_HOME.sglName,
        POST.ASSEMBLY_ACTIVITY_EXCHANGE_HOME.sglName,
    }
    return signals
end
function AssemblyActivityMediator:ProcessSignal( signal )
    local name = signal:GetName()
    local body = signal:GetBody()
    if name == POST.ASSEMBLY_ACTIVITY_HOME.sglName then
        dump(body)
        self:SetHomeData(body)
        local homeData = self:ConvertHomeData()
        self:InitView()
    elseif name == POST.ASSEMBLY_ACTIVITY_EXCHANGE_HOME.sglName then
        self:ShowExchangeView(body)
    end
end

function AssemblyActivityMediator:OnRegist()
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightHide")
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "allhide")
    regPost(POST.ASSEMBLY_ACTIVITY_HOME)
    regPost(POST.ASSEMBLY_ACTIVITY_EXCHANGE_HOME)
    regPost(POST.ASSEMBLY_ACTIVITY_EXCHANGE)
    self:EnterLayer()
end
function AssemblyActivityMediator:OnUnRegist()
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightShow")
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "hide")
    unregPost(POST.ASSEMBLY_ACTIVITY_HOME)
    unregPost(POST.ASSEMBLY_ACTIVITY_EXCHANGE_HOME)
    unregPost(POST.ASSEMBLY_ACTIVITY_EXCHANGE)
    local scene = app.uiMgr:GetCurrentScene()
	scene:RemoveGameLayer(self.viewComponent)
end
------------------ inheritance ------------------
-------------------------------------------------

-------------------------------------------------
-------------------- handler --------------------
--[[
提示按钮点击回调
--]]
function AssemblyActivityMediator:TipsButtonCallback( sender )
    PlayAudioByClickNormal()
    app.uiMgr:ShowIntroPopup({moduleId = '-69'})
end
--[[
返回按钮点击回调
--]]
function AssemblyActivityMediator:BackButtonCallback( sender )
    PlayAudioByClickClose()
   self:GetFacade():BackHomeMediator()
end
--[[
入口按钮点击回调
--]]
function AssemblyActivityMediator:EntryButtonCallback( sender )
    PlayAudioByClickNormal()
    local moduleId = sender:getTag()
    if moduleId == MODULE_TYPE.TASK then -- 任务
        DotGameEvent.SendEvent(DotGameEvent.EVENTS.RETURN_DIALY_ACTIVE)
        local mediator = require("Game.mediator.activity.assemblyActivity.AssemblyActivityTaskMediator").new({activityId = self.activityId})
        app:RegistMediator(mediator)
    elseif moduleId == MODULE_TYPE.EXCHANGE then -- 兑换
        DotGameEvent.SendEvent(DotGameEvent.EVENTS.RETURN_CHANGE)
        self:SendSignal(POST.ASSEMBLY_ACTIVITY_EXCHANGE_HOME.cmdName, {activityId = self.activityId})
    elseif moduleId == MODULE_TYPE.NINE_PALACE then -- 十宫格
        local mediator = require("Game.mediator.activity.assemblyActivity.AssemblyActivityTenPalaceMediator").new({activityId = self.activityId})
        app:RegistMediator(mediator)
    elseif moduleId == MODULE_TYPE.WHEEL then -- 大转盘
        DotGameEvent.SendEvent(DotGameEvent.EVENTS.RETURN_LOTTERY)
        local mediator = require("Game.mediator.activity.assemblyActivity.AssemblyActivityWheelMediator").new({activityId = self.activityId})
        app:RegistMediator(mediator)
    elseif moduleId == MODULE_TYPE.CAPSULE then -- 副本抽奖
        local mediator = require("Game.mediator.activity.assemblyActivity.AssemblyActivityLotteryMediator").new({activityId = self.activityId})
        app:RegistMediator(mediator)
    elseif moduleId == MODULE_TYPE.STORE then -- 商城
        DotGameEvent.SendEvent(DotGameEvent.EVENTS.RETURN_MALL)
        local mediator = require("Game.mediator.activity.assemblyActivity.AssemblyActivityStoreMediator").new({activityId = self.activityId})
        app:RegistMediator(mediator)
    elseif moduleId == MODULE_TYPE.RANK then -- 排行榜
        local mediator = require("Game.mediator.activity.assemblyActivity.AssemblyActivityRankMediator").new({activityId = self.activityId})
        app:RegistMediator(mediator)
    end
end
-------------------- handler --------------------
-------------------------------------------------

-------------------------------------------------
-------------------- private --------------------
--[[
初始化view
--]]
function AssemblyActivityMediator:InitView()
    local view = self:GetViewComponent()
    local viewComponent = self:GetViewComponent()
    viewComponent:CreateEntry(self:GetMainModuleList(), self:GetTopModuleList(), handler(self, self.EntryButtonCallback))
end
--[[
进入页面
--]]
function AssemblyActivityMediator:EnterLayer()
    self:SendSignal(POST.ASSEMBLY_ACTIVITY_HOME.cmdName, {activityId = self.activityId})
end
--[[
转换home数据
--]]
function AssemblyActivityMediator:ConvertHomeData( )
    local homeData = self:GetHomeData()
    local mainModuleList = {}
    local topModuleList = {}
    for i, v in ipairs(checktable(homeData.module)) do
        if checkint(v.moduleId) <= 5 then
            table.insert(mainModuleList, v)
        else
            table.insert(topModuleList, v)
        end
    end
    self:SetMainModuleList(mainModuleList)
    self:SetTopModuleList(topModuleList)
end
--[[
显示兑换页面
--]]
function AssemblyActivityMediator:ShowExchangeView( responseData )
    local mediator = require("Game.mediator.activity.ActivityExchangeLargeMediator").new({
        isLarge = true,
        exchangePost = POST.ASSEMBLY_ACTIVITY_EXCHANGE, 
        exchangeListData = responseData.exchange,
        hideTimer = true, 
        extra = {activityId = self.activityId},

    })
    self:GetFacade():RegistMediator(mediator)
end
-------------------- private --------------------
-------------------------------------------------

-------------------------------------------------
------------------- get / set -------------------
--[[
设置homeData
--]]
function AssemblyActivityMediator:SetHomeData( homeData )
    self.homeData = homeData
end
--[[
获取homeData
--]]
function AssemblyActivityMediator:GetHomeData()
    return self.homeData
end
--[[
设置mainModuleList
--]]
function AssemblyActivityMediator:SetMainModuleList( mainModuleList )
    self.mainModuleList = mainModuleList
end
--[[
获取mainModuleList
--]]
function AssemblyActivityMediator:GetMainModuleList()
    return self.mainModuleList
end
--[[
设置topModuleList
--]]
function AssemblyActivityMediator:SetTopModuleList( topModuleList )
    self.topModuleList = topModuleList
end
--[[
获取topModuleList
--]]
function AssemblyActivityMediator:GetTopModuleList()
    return self.topModuleList
end
------------------- get / set -------------------
-------------------------------------------------
return AssemblyActivityMediator