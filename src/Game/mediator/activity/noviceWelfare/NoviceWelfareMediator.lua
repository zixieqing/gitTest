--[[
 * author : liuzhipeng
 * descpt : 活动 新手福利Mediator
--]]
local NoviceWelfareMediator = class('NoviceWelfareMediator', mvc.Mediator)
local NAME = 'activity.noviceWelfare.NoviceWelfareMediator'
local VIEW_TYPE = {
    WAIT_VIEW     = 1,
    ACTIVITY_VIEW = 2,
}
local TAB_TYPE = {
    NOVICE_WEIFARE_DAILY      = 1,
    NOVICE_WEIFARE_TASK_LIMIT = 2,
    NOVICE_WEIFARE_GIFT_LIMIT = 3,
}
function NoviceWelfareMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.selectedTab = TAB_TYPE.NOVICE_WEIFARE_DAILY
    self.taskLayerMdt = nil 
    self.giftLayerMdt = nil 
end

-------------------------------------------------
------------------ inheritance ------------------
function NoviceWelfareMediator:Initial( key )
    self.super.Initial(self, key)
end
    
function NoviceWelfareMediator:InterestSignals()
    local signals = {
        POST.NOVICE_WELFARE_HOME.sglName,
        'NOVICE_WELFARE_UPDATE_HOMEDATA',
        EVENT_PAY_MONEY_SUCCESS_UI,
    }
    return signals
end
function NoviceWelfareMediator:ProcessSignal( signal )
    local name = signal:GetName()
    local body = signal:GetBody()
    if name == POST.NOVICE_WELFARE_HOME.sglName then
        self:InitView(body)
    elseif name == 'NOVICE_WELFARE_UPDATE_HOMEDATA' then
        self:SendSignal(POST.NOVICE_WELFARE_HOME.cmdName)
    elseif name == EVENT_PAY_MONEY_SUCCESS_UI then
        if checkint(body.type) == PAY_TYPE.NOVICE_WELFARE_GIFT then
			self:SendSignal(POST.NOVICE_WELFARE_HOME.cmdName)
		end
    end
end

function NoviceWelfareMediator:OnRegist()
    regPost(POST.NOVICE_WELFARE_HOME)
    self:EnterLayer()
end
function NoviceWelfareMediator:OnUnRegist()
    unregPost(POST.NOVICE_WELFARE_HOME)
    -- 关闭定时器
    if app.timerMgr:RetriveTimer(NAME) then
        app.timerMgr:RemoveTimer(NAME)
	end
    app:UnRegsitMediator('activity.noviceWelfare.NoviceWelfareTaskMediator')
	app:UnRegsitMediator('activity.noviceWelfare.NoviceWelfareGiftMediator')
    -- 移除界面
    if self:GetViewComponent() and not tolua.isnull(self:GetViewComponent()) then
        self:GetViewComponent():removeFromParent()
        self:SetViewComponent(nil)
    end
end
------------------ inheritance ------------------
-------------------------------------------------

-------------------------------------------------
-------------------- handler --------------------
--[[
返回主界面
--]]
function NoviceWelfareMediator:BackButtonCallback( sender )
    PlayAudioByClickClose()
    app:UnRegsitMediator(NAME)
end
--[[
提示按钮点击回调
--]]
function NoviceWelfareMediator:TipsButtonCallback( sender )
    PlayAudioByClickNormal()
    app.uiMgr:ShowIntroPopup({moduleId = INTRODUCE_MODULE_ID.NOVICE_WELFARE})
end
--[[
右边不同类型model按钮的事件处理逻辑
@param sender button对象
--]]
function NoviceWelfareMediator:TabButtonCallback( sender )
	local tag = sender:getTag()
	PlayAudioClip(AUDIOS.UI.ui_depot_tabchange.id)
	if self.selectedTab == tag then
		return
	end
    self:SwitchTab(tag)
end
-------------------- handler --------------------
-------------------------------------------------

-------------------------------------------------
-------------------- private --------------------
--[[
进入页面
--]]
function NoviceWelfareMediator:EnterLayer()
    self:SendSignal(POST.NOVICE_WELFARE_HOME.cmdName)
end
--[[
初始化页面
--]]
function NoviceWelfareMediator:InitView( responseData )
    self:ConvertHomeData(responseData)
    local type = checkint(responseData.today) == 0 and VIEW_TYPE.WAIT_VIEW or VIEW_TYPE.ACTIVITY_VIEW
    if self:GetViewComponent() == nil or tolua.isnull(self:GetViewComponent()) or self:GetViewComponent():GetType() ~= type then
        self:CreateView(type)
    end
    -- 如果today字段为0,表示是预告阶段
    if checkint(responseData.today) == 0 then
        self:GetViewComponent():UpdateWaitTimeLabel(self:GetHomeData().nextDayLeftSeconds)
    else
        self:SwitchTab(self.selectedTab)
    end
    self:StartTimer()
    self:CheckNoviceWelfareRemindIcon()
end
--[[
创建页面
@params viewType int 页面类型
--]]
function NoviceWelfareMediator:CreateView( viewType )
    local viewComponent = nil
    if self:GetViewComponent() and not tolua.isnull(self:GetViewComponent())then
        self:GetViewComponent():ChangeViewType(viewType)
        viewComponent = self:GetViewComponent()
    else
        viewComponent = require('Game.views.activity.noviceWelfare.NoviceWelfareView').new({type = viewType})
        self:SetViewComponent(viewComponent)
        viewComponent:setPosition(display.center)
        app.uiMgr:GetCurrentScene():AddDialog(viewComponent)
    end
    if viewType == VIEW_TYPE.ACTIVITY_VIEW then
        --绑定相关的事件
        for k, v in pairs( viewComponent.viewData.tabBtnDict ) do
            v:setOnClickScriptHandler(handler(self,self.TabButtonCallback))
        end
    end
    local viewData = viewComponent.viewData
    viewData.tipsBtn:setOnClickScriptHandler(handler(self, self.TipsButtonCallback))
    viewComponent.eaterLayer:setOnClickScriptHandler(handler(self, self.BackButtonCallback))
end
--[[
转换为homeData所需格式
@params data map 服务器返还数据
--]]
function NoviceWelfareMediator:ConvertHomeData( data )
    -- 预告阶段的数据要特殊处理
    if checkint(data.today) == 0 then
        local homeData = {
            nextDayLeftSeconds = data.nextDayLeftSeconds or data.beginLeftSeconds,
            today              = data.today,
        }    
        self:SetHomeData(homeData)
        return 
    end

    -- 正式的数据处理
    local homeData = {
        chests             = data.chests,
        currentActivePoint = data.currentActivePoint,
        endLeftSeconds     = data.endLeftSeconds,
        nextDayLeftSeconds = data.nextDayLeftSeconds,
        activePoints       = data.activePoints,
        today              = data.today,
        tasks              = {},
        limitTasks         = {}
    }

    -- 把限时任务和非限时任务区分开来
    for k, tasksData in orderedPairs(data.tasks) do
        homeData.tasks[checkint(k)] = {}
        homeData.limitTasks[checkint(k)] = {}
        for i, taskData in ipairs(tasksData) do
            if checkint(taskData.isTimeLimit) == 1 then
                table.insert(homeData.limitTasks[checkint(k)], taskData)
            else
                table.insert(homeData.tasks[checkint(k)], taskData)
            end
        end
    end
    self:SetHomeData(homeData)
end
--[[
切换页签
--]]
function NoviceWelfareMediator:SwitchTab( tag )
    local homeData = self:GetHomeData()
    local viewData = self:GetViewComponent():GetViewData()
	for k, v in pairs( viewData.tabBtnDict ) do
		local curTag = v:getTag()
		if tag == curTag then
			v:setChecked(true)
			v:setEnabled(false)
			v:getChildByName('title'):setColor(cc.c3b(233, 73, 26))
		else
			v:setChecked(false)
			v:setEnabled(true)
			v:getChildByName('title'):setColor(cc.c3b(92, 92, 92))
		end
    end
    -- 隐藏已创建页面
    if self.selectedTab == TAB_TYPE.NOVICE_WEIFARE_GIFT_LIMIT then
        if self.giftLayerMdt then
            self.giftLayerMdt:HideView()
        end
    else
        if self.taskLayerMdt then
            self.taskLayerMdt:HideView()
        end
    end
	self.selectedTab = tag
	local centerLayout = viewData.centerLayout
    -- 显示所选页面
    if tag == TAB_TYPE.NOVICE_WEIFARE_GIFT_LIMIT then
        -- 礼包页面
        if self.giftLayerMdt then
            self.giftLayerMdt:ShowView()
        else
            
            local NoviceWelfareGiftMediator = require('Game.mediator.activity.noviceWelfare.NoviceWelfareGiftMediator').new()
            app:RegistMediator(NoviceWelfareGiftMediator)
            self.giftLayerMdt = NoviceWelfareGiftMediator
            self.giftLayerMdt:GetViewComponent():setPosition(utils.getLocalCenter(centerLayout))
            centerLayout:addChild(self.giftLayerMdt:GetViewComponent())
        end
        local params = {
            chests = homeData.chests,
            today  = checkint(homeData.today),
            nextDayLeftSeconds = homeData.leftSeconds or homeData.nextDayLeftSeconds
        }   
        self.giftLayerMdt:RefreshView(params)
    else
        -- 任务页面
        if self.taskLayerMdt then
            self.taskLayerMdt:ShowView()
        else
            local NoviceWelfareTaskMediator = require('Game.mediator.activity.noviceWelfare.NoviceWelfareTaskMediator').new()
            app:RegistMediator(NoviceWelfareTaskMediator)
            self.taskLayerMdt = NoviceWelfareTaskMediator
            self.taskLayerMdt:GetViewComponent():setPosition(utils.getLocalCenter(centerLayout))
            centerLayout:addChild(self.taskLayerMdt:GetViewComponent())
        end
        local params = {}
        if tag == TAB_TYPE.NOVICE_WEIFARE_DAILY then -- 日常任务
            params.tasks = homeData.tasks
            params.isLimit = false
        elseif tag == TAB_TYPE.NOVICE_WEIFARE_TASK_LIMIT then -- 限时任务
            params.tasks = homeData.limitTasks
            params.isLimit = true
        end
        params.currentActivePoint = homeData.currentActivePoint
        params.today = homeData.today
        params.activePoints = homeData.activePoints
        self.taskLayerMdt:RefreshView(params)
    end
end
--[[
开启定时器
--]]
function NoviceWelfareMediator:StartTimer()
    local homeData = self:GetHomeData()
	if app.timerMgr:RetriveTimer(NAME) then
        app.timerMgr:RemoveTimer(NAME)
	end
	local callback = function(countdown, remindTag, timeNum, datas, timerName)
        if countdown > 0 then
            self:UpdateLeftSeconds(countdown)
        else
            app.timerMgr:RemoveTimer(NAME)
            self:SendSignal(POST.NOVICE_WELFARE_HOME.cmdName)
		end
    end
	app.timerMgr:AddTimer({name = NAME, callback = callback, countdown = homeData.nextDayLeftSeconds})
end
--[[
更新剩余时间
--]]
function NoviceWelfareMediator:UpdateLeftSeconds( leftSeconds )
    self:GetHomeData().leftSeconds = leftSeconds
    if self:GetViewComponent() then
        self:GetViewComponent():UpdateWaitTimeLabel(leftSeconds)
    end
    if self.giftLayerMdt then
        self.giftLayerMdt:UpdateLeftSeconds(leftSeconds)
    end
end
--[[
检查新手福利红点
--]]
function NoviceWelfareMediator:CheckNoviceWelfareRemindIcon( )
    local homeData = self:GetHomeData()
    if checkint(homeData.today) == 0 then return end
    local viewComponent = self:GetViewComponent()
    local showNormalRemindIcon = false
    local showLimitRemindIcon = false
    -- 检查普通任务红点
    for i = 1, checkint(homeData.today) do
        for _, v in ipairs(checktable(homeData.tasks[i])) do
            if checkint(v.progress) >= checkint(v.targetNum) and checkint(v.hasDrawn) == 0 then
                showNormalRemindIcon = true
                break
            end
        end
    end
    viewComponent:RefreshTabRemindIcon(TAB_TYPE.NOVICE_WEIFARE_DAILY, showNormalRemindIcon)
    -- 检查限时任务红点
    local limitTaskData = homeData.limitTasks[checkint(homeData.today)]
    for _, v in ipairs(checktable(limitTaskData)) do
        if checkint(v.progress) >= checkint(v.targetNum) and checkint(v.hasDrawn) == 0 then
            showLimitRemindIcon = true
            break
        end
    end
    viewComponent:RefreshTabRemindIcon(TAB_TYPE.NOVICE_WEIFARE_TASK_LIMIT, showLimitRemindIcon)
    if showNormalRemindIcon or showLimitRemindIcon then
        app.gameMgr:GetUserInfo().tips.newbie14Task = 1
        app.dataMgr:AddRedDotNofication(tostring(RemindTag.NOVICE_WELFARE), RemindTag.NOVICE_WELFARE)
        app:DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.NOVICE_WELFARE})
        return 
    end
    -- 清除红点
    app.gameMgr:GetUserInfo().tips.newbie14Task = 0
    app.dataMgr:ClearRedDotNofication(tostring(RemindTag.NOVICE_WELFARE), RemindTag.NOVICE_WELFARE)
    app:DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.NOVICE_WELFARE})
end
-------------------- private --------------------
-------------------------------------------------

-------------------------------------------------
------------------- get / set -------------------
--[[
设置homeData
--]]
function NoviceWelfareMediator:SetHomeData( homeData )
    self.homeData = homeData
end
--[[
获取homeData
--]]
function NoviceWelfareMediator:GetHomeData()
    return self.homeData
end
------------------- get / set -------------------
-------------------------------------------------
return NoviceWelfareMediator