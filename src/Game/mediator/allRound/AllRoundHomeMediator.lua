---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by xingweihao.
--- DateTime: 2018/10/15 2:07 PM
---
--[[
扭蛋系统mediator
--]]
local Mediator                      = mvc.Mediator

---@type UIManager
local uiMgr =  app.uiMgr
---@class AllRoundHomeMediator :Mediator
local AllRoundHomeMediator = class("AllRoundHomeMediator", Mediator)
local NAME                          = "AllRoundHomeMediator"
local BUTTON_TAG                    = {
    CLOSE_VIEW = 11001 ,
    TIP_BUTTON = 11002 ,
}
--==============================--
---@Description: TODO
---@author : xingweihao
---@date : 2018/10/13 10:22 AM
--==============================--

function AllRoundHomeMediator:ctor(param, viewComponent)
    self.super:ctor(NAME, viewComponent)
    self.homeData = {}
end

function AllRoundHomeMediator:InterestSignals()
    local signals = {
        POST.CARD_CALL_HOME.sglName ,
        POST.CARD_CALL_DRAW_FINAL_REWARD.sglName ,
        POST.CARD_CALL_DRAW_ROUTE_REWARD.sglName ,
        ALL_DRAW_TASK_REWARD_EVENT
    }
    return signals
end

function AllRoundHomeMediator:ProcessSignal(signal)
    local data  = signal:GetBody()
    local name = signal:GetName()
    if name == POST.CARD_CALL_HOME.sglName then
        self.homeData = data
        self:UpdateUI()
    elseif name == POST.CARD_CALL_DRAW_FINAL_REWARD.sglName then
        -- 最终奖励领取
        self:DrawFinalRequestCallBack(data)
        app:BackHomeMediator()
    elseif name == POST.CARD_CALL_DRAW_ROUTE_REWARD.sglName then
        -- 各个路线的奖励领取
        self:DrawRouteRequestCallBack(data)
    elseif name == ALL_DRAW_TASK_REWARD_EVENT then
        self:DrawTaskRewardEventCallBack(data)
    end
end
--==============================--
---@Description: 路线奖励回调
---@author : xingweihao
---@date : 2018/11/30 11:12 AM
--==============================--
function AllRoundHomeMediator:DrawRouteRequestCallBack(data)
    local requestData = data.requestData
    local routeId = requestData.routeId
    local routeData = {}
    for i, v in ipairs(self.homeData.routes) do
        if checkint(v.routeId ) == checkint(routeId) then
            v.hasDrawn = 1
            routeData = v
        end
    end
    app.uiMgr:AddDialog('common.RewardPopup',data)
    local allRoundHasDraw = 1
    for i, v in ipairs(self.homeData.routes) do
        if checkint(v.hasDrawn ) == 0  then
            allRoundHasDraw = 0
        end
    end
    ---@type  AllRoundHomeView
    local viewComponent = self:GetViewComponent()
    local viewData = viewComponent.viewData
    local moduleBtns = viewData.moduleBtns
    -- 更新单个的cell 信息
    viewComponent:UpdateCellLayout(moduleBtns[checkint(routeId)],routeData)
    if allRoundHasDraw == 1 then
        -- 满足领取条件 更新 avatarLayout 的信息
        viewComponent:UpdateAvatarLayout(1)
    end
end
--==============================--
---@Description: 最终简历回调处理
---@author : xingweihao
---@date : 2018/12/4 11:02 AM
--==============================--
function AllRoundHomeMediator:DrawFinalRequestCallBack(data)
    local routeId =  5
    local routeData = {}
    app.uiMgr:AddDialog('common.RewardPopup',data)
    for i, v in ipairs(self.homeData.routes) do
        if checkint(v.routeId ) == checkint(routeId) then
            v.hasDrawn = 1
            routeData = v
        end
    end
    ---@type AllRoundHomeView
    local viewComponent = self:GetViewComponent()
    viewComponent:UpdateAvatarLayout(2)
end

function AllRoundHomeMediator:DrawTaskRewardEventCallBack(data)
    local routeId = checkint(data.routeId)
    local taskId = checkint(data.taskId)
    for i, v in pairs(self.homeData.routes) do
        if checkint(v.routeId) == routeId then
            for index , taskData in ipairs(v.tasks) do
                if checkint(taskData.taskId) == taskId then
                    taskData.hasDrawn = 1
                    ---@type AllRoundHomeView
                    local viewComponent = self:GetViewComponent()
                    local viewData = viewComponent.viewData
                    local isRed =  self:GetRedTableByRouter(v.routeId)
                    viewComponent:UpdateCellLayout(viewData.moduleBtns[routeId] , v , isRed  )
                    return
                end
            end
        end
    end
end
function AllRoundHomeMediator:Initial(key)
    self.super.Initial(self, key)
    ---@type AnniversaryBlackMarketStoreView
    local viewComponent = require('Game.views.allRound.AllRoundHomeView').new({callback = handler(self, self.MoudleCallBack) })
    self:SetViewComponent(viewComponent)
    uiMgr:SwitchToScene(viewComponent)
    local viewData = viewComponent.viewData
    local backBtn = viewData.backBtn
    local tabNameLabel = viewData.tabNameLabel
    backBtn:setTag(BUTTON_TAG.CLOSE_VIEW)
    tabNameLabel:setTag(BUTTON_TAG.TIP_BUTTON)
    display.commonUIParams(backBtn , { cb = handler(self, self.ButtonAction)})
    display.commonUIParams(tabNameLabel , { cb = handler(self, self.ButtonAction)})
end

function AllRoundHomeMediator:UpdateUI()
    local routes = self.homeData.routes
    ---@type AllRoundHomeView
    local viewComponent = self:GetViewComponent()
    local viewData = viewComponent.viewData
    for i, routerData in ipairs(routes) do
        local routeId = checkint(routerData.routeId)
        local isRed = false
        if checkint(routerData.hasDrawn ) ~= 1 then
            isRed = self:GetRedTableByRouter(routerData.routeId)
        end
        viewComponent:UpdateCellLayout( viewData.moduleBtns[routeId]  , routerData ,isRed )
    end
    local status = checkint(self.homeData.finalRewardsHasDrawn)
    if status == 0  then
        status = 1
        for i, routerData in ipairs(routes) do
            if checkint(routerData.hasDrawn)  == 0  then
                status = 0
                break
            end
        end
    elseif status == 1 then
        status = 2
    end
    viewComponent:UpdateAvatarLayout(status)
end
function AllRoundHomeMediator:GetRedTableByRouter(routerId)
    local isRed = false
    for i, routerData in pairs(self.homeData.routes) do
        if checkint(routerData.routeId) ==  checkint(routerId)  then
            for taskId, taskData in pairs(routerData.tasks) do
                if checkint(taskData.hasDrawn) == 0  and  checkint(taskData.progress) >= checkint(taskData.targetNum) then
                    isRed = true
                    break
                end
            end
            break
        end
    end
    return isRed
end


function AllRoundHomeMediator:ButtonAction(sender)
    local tag = sender:getTag()
    if tag == BUTTON_TAG.CLOSE_VIEW  then
       self:GetFacade():BackHomeMediator()
    elseif tag == BUTTON_TAG.TIP_BUTTON then
        app.uiMgr:ShowIntroPopup({moduleId = JUMP_MODULE_DATA.ALL_ROUND})
    end
end

function AllRoundHomeMediator:MoudleCallBack(sender)
    local tag = sender:getTag()
    local routeId  = math.floor(tag/10)
    local lookTag  = tag % 10
    if routeId <= 4  then
        if lookTag == 1 then -- 查看最终奖励
            local  mediator = require('Game.mediator.allRound.AllRoundModuleTaskMediator').new({routeData  = self.homeData.routes[checkint(routeId)]  })
            app:RegistMediator(mediator)
        elseif lookTag == 2 then -- 调起任务界面
            local view = require('Game.views.allRound.AllRoundLookRewardView').new({routeId = routeId})
            app.uiMgr:GetCurrentScene():AddDialog(view)
            view:setPosition(display.center)
        elseif lookTag == 3 then -- 领取奖励
            self:SendSignal(POST.CARD_CALL_DRAW_ROUTE_REWARD.cmdName , { routeId = routeId })
        end
    elseif  routeId == 5  then
        if lookTag == 1 then -- 查看最终奖励
            local view = require('Game.views.allRound.AllRoundLookRewardView').new({routeId = routeId})
            app.uiMgr:GetCurrentScene():AddDialog(view)
            view:setPosition(display.center)
        elseif lookTag == 3 then
            local allRoundHasDraw = 1
            for i, v in ipairs(self.homeData.routes) do
                if checkint(v.hasDrawn ) == 0  then
                    allRoundHasDraw = 0
                end
            end
            if allRoundHasDraw == 1 and checkint(self.homeData.routes.finalRewardsHasDrawn) ~= 1  then
                self:SendSignal(POST.CARD_CALL_DRAW_FINAL_REWARD.cmdName , {  })
            end
        end
    end
end
function AllRoundHomeMediator:EnterLayer()
    self:SendSignal(POST.CARD_CALL_HOME.cmdName , {})
end
function AllRoundHomeMediator:OnRegist()
    app:DispatchObservers(HomeScene_ChangeCenterContainer, "rightHide")
    app:DispatchObservers(HomeScene_ChangeCenterContainer, "allhide")
    regPost(POST.CARD_CALL_HOME)
    regPost(POST.CARD_CALL_DRAW_ROUTE_REWARD)
    regPost(POST.CARD_CALL_DRAW_FINAL_REWARD)
    self:EnterLayer()
end
function AllRoundHomeMediator:OnUnRegist()
    app:DispatchObservers(HomeScene_ChangeCenterContainer, "rightShow")
    app:DispatchObservers(HomeScene_ChangeCenterContainer, "hide")
    unregPost(POST.CARD_CALL_HOME)
    unregPost(POST.CARD_CALL_DRAW_ROUTE_REWARD)
    unregPost(POST.CARD_CALL_DRAW_FINAL_REWARD)
    local viewComponent = self:GetViewComponent()
    if viewComponent and (not tolua.isnull(viewComponent)) then
        viewComponent:stopAllActions()
        viewComponent:runAction(cc.RemoveSelf:create())
    end
end

return AllRoundHomeMediator
