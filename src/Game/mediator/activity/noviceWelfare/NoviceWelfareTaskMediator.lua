--[[
 * author : liuzhipeng
 * descpt : 活动 新手福利 任务Mediator
--]]
local NoviceWelfareTaskMediator = class('NoviceWelfareTaskMediator', mvc.Mediator)
local NAME = 'activity.noviceWelfare.NoviceWelfareTaskMediator'
function NoviceWelfareTaskMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    local args = checktable(params)
    self.selectedDay = nil
end
-------------------------------------------------
------------------ inheritance ------------------
function NoviceWelfareTaskMediator:Initial( key )
    self.super.Initial(self, key)
    local viewComponent = require('Game.views.activity.noviceWelfare.NoviceWelfareTaskView').new()
    self:SetViewComponent(viewComponent)
    local viewData = viewComponent.viewData
    for i, v in ipairs(viewData.dayBtnList) do
        v:setOnClickScriptHandler(handler(self, self.DayButtonCallback))
    end
    viewData.taskGridView:setCellUpdateHandler(handler(self, self.OnUpdateTaskListCellHandler))
    viewData.taskGridView:setCellInitHandler(handler(self, self.OnInitTaskListCellHandler))
end
    
function NoviceWelfareTaskMediator:InterestSignals()
    local signals = {
        POST.NOVICE_WELFARE_TASK_DRAW.sglName,
        POST.NOVICE_WELFARE_POINT_DRAW.sglName,
    }
    return signals
end
function NoviceWelfareTaskMediator:ProcessSignal( signal )
    local name = signal:GetName()
    local body = signal:GetBody()
    if name == POST.NOVICE_WELFARE_TASK_DRAW.sglName then
        self:DrawTaskResponseHandler(body)
    elseif name == POST.NOVICE_WELFARE_POINT_DRAW.sglName then
        self:DrawPointRewardsResponseHandler(body)
    end
end

function NoviceWelfareTaskMediator:OnRegist()
    regPost(POST.NOVICE_WELFARE_TASK_DRAW)
    regPost(POST.NOVICE_WELFARE_POINT_DRAW)
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, 'rightHide')
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, 'allhide')
end
function NoviceWelfareTaskMediator:OnUnRegist()
    unregPost(POST.NOVICE_WELFARE_TASK_DRAW)
    unregPost(POST.NOVICE_WELFARE_POINT_DRAW)
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, 'rightShow')
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, 'hide')
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
日期按钮点击回调
--]]
function NoviceWelfareTaskMediator:DayButtonCallback( sender )
    local homeData = self:GetHomeData()
    local tag = sender:getTag()
    if tag > homeData.today then
        -- 不可以提前查看任务
        app.uiMgr:ShowInformationTips(string.format(__('任务未开启')))
        return
    end
    PlayAudioByClickNormal()
    self:SelectDayTab(tag)
end
--[[
列表刷新
--]]
function NoviceWelfareTaskMediator:OnUpdateTaskListCellHandler( cellIndex, cellViewData )
    local homeData = self:GetHomeData()
    local viewComponent = self:GetViewComponent()
    local selectedDay = self:GetSelectedDay()
    local taskData = homeData.tasks[selectedDay][cellIndex]
    cellViewData.button:setTag(cellIndex)
    viewComponent:RefreshTaskState(cellViewData, taskData, homeData.today)
end
--[[
列表cell初始化
--]]
function NoviceWelfareTaskMediator:OnInitTaskListCellHandler( cellViewData )
    display.commonUIParams(cellViewData.button, {cb = handler(self, self.TaskDrawBtnCallback)})
end
--[[
任务领取按钮回调
--]]
function NoviceWelfareTaskMediator:TaskDrawBtnCallback( sender )
	PlayAudioByClickNormal()
    local tag = sender:getTag()
    local homeData = self:GetHomeData()
    local taskData = homeData.tasks[self:GetSelectedDay()][tag]
    local taskId = taskData.id

    if checkint(taskData.isTimeLimit) == 1 and checkint(taskData.openDay) ~= checkint(homeData.today) then
        -- 花费道具补领
        if app.goodsMgr:GetGoodsAmountByGoodsId(taskData.skipGoodsId) >= checkint(taskData.skipGoodsNum) then
            local config = CommonUtils.GetConfig('goods', 'goods', taskData.skipGoodsId) or {}
            app.uiMgr:AddCommonTipDialog({
                text =  string.fmt(__('是否花费_num__name_领取奖励？'), {['_num_'] = checkint(taskData.skipGoodsNum), ['_name_'] = tostring(config.name)}) ,
                callback = function ()
                    self:SendSignal(POST.NOVICE_WELFARE_TASK_DRAW.cmdName, {taskId = taskId, skipGoodsId = taskData.skipGoodsId, skipGoodsNum = taskData.skipGoodsNum})
                end,
            })
        else
            -- 道具不足
            local config = CommonUtils.GetConfig('goods', 'goods', homeData.skipGoodsId) or {}
            app.uiMgr:ShowInformationTips(string.fmt(__('_name_不足'), {['_name_'] = tostring(config.name)}))
        end
        return 
    end
    if checkint(taskData.progress) >= checkint(taskData.targetNum) then
        -- 领奖
        self:SendSignal(POST.NOVICE_WELFARE_TASK_DRAW.cmdName, {taskId = taskId})
    else
        -- 跳转
        app:UnRegsitMediator('activity.noviceWelfare.NoviceWelfareMediator')
        CommonUtils.JumpModuleByTaskData( taskData, true )
        sceneWorld:runAction(
            cc.Sequence:create(
                cc.CallFunc:create(function()
                    self.isGoto = true
                end),
                cc.DelayTime:create(2) ,
                cc.CallFunc:create(function()
                    self.isGoto = false
                end)
            )
        )
    end
end
-------------------- handler --------------------
-------------------------------------------------

-------------------------------------------------
-------------------- private --------------------
--[[
计算默认显示天数
--]]
function NoviceWelfareTaskMediator:CaluculateDefaultDay()
    local homeData = self:GetHomeData()
    -- if homeData.isLimit then
    --     -- 限定任务显示当天
    --     local day = math.min(checkint(homeData.today), 7)
    --     self:SetSelectedDay(day)
    -- else
    --     -- 非限定显示未完成的那天
    --     local default = #homeData.tasks
    --     for day, tasks in ipairs(homeData.tasks) do
    --         for _, task in ipairs(tasks) do
    --             if checkint(task.hasDrawn) == 0 then
    --                 self.selectedDay = day
    --                 return
    --             end
    --         end
    --     end 
    --     -- 全完成显示最后一天
    --     self:SetSelectedDay(default)
    -- end
    local day = math.min(checkint(homeData.today), 7)
    self:SetSelectedDay(day)
end
--[[
刷新点数进度条
--]]
function NoviceWelfareTaskMediator:RefreshPointProgressBar()
    local homeData = self:GetHomeData()
    local viewComponent = self:GetViewComponent()
    viewComponent:RefreshPointProgressBar(homeData.activePoints, homeData.currentActivePoint)
end
--[[
刷新卡牌预览按钮
--]]
function NoviceWelfareTaskMediator:RefreshCardPreviewButton()
    local homeData = self:GetHomeData()
    local viewComponent = self:GetViewComponent()
    local goodsId = homeData.activePoints[1].rewards[1].goodsId
    viewComponent:RefreshCardPreviewButton(goodsId)
end
--[[
选中日期页签
@params day int 日期
--]]
function NoviceWelfareTaskMediator:SelectDayTab( day )
    local homeData = self:GetHomeData()
    local viewComponent = self:GetViewComponent()
    local viewData = viewComponent:GetViewData()
    viewComponent:RefreshTabSelectState(self:GetSelectedDay(), false)
    viewComponent:RefreshTabSelectState(day, true)
    self:SetSelectedDay(day)
    viewData.taskGridView:resetCellCount(#homeData.tasks[day])
end
--[[
任务领取处理
--]]
function NoviceWelfareTaskMediator:DrawTaskResponseHandler( responseData )
    app.uiMgr:AddDialog('common.RewardPopup', responseData)
    if responseData.requestData.skipGoodsId then
        CommonUtils.DrawRewards({
            {goodsId = responseData.requestData.skipGoodsId, num = - checkint(responseData.requestData.skipGoodsNum)},
        })
        self:GetFacade():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI)
    end
    app:DispatchObservers('NOVICE_WELFARE_UPDATE_HOMEDATA')
end
--[[
点数奖励领取处理
--]]
function NoviceWelfareTaskMediator:DrawPointRewardsResponseHandler( responseData )
    app.uiMgr:AddDialog('common.RewardPopup', responseData)
    app:DispatchObservers('NOVICE_WELFARE_UPDATE_HOMEDATA')
end
--[[
检查点数奖励是否可领取
--]]
function NoviceWelfareTaskMediator:CheckPointRewards()
    local homeData = self:GetHomeData()
    for i, v in ipairs(homeData.activePoints) do
        if homeData.currentActivePoint >= checkint(v.activePoint) and checkint(v.hasDrawn) == 0 then
            self:SendSignal(POST.NOVICE_WELFARE_POINT_DRAW.cmdName, {activePointId = v.id})
            break
        end
    end
end
--[[
任务排序
--]]
function NoviceWelfareTaskMediator:SortTasks()
    local homeData = self:GetHomeData()
    for i, v in ipairs(homeData.tasks) do
        table.sort(v, function(aTaskData , bTaskData)
            local isTrue  = true
            if checkint(aTaskData.hasDrawn) ==  checkint(bTaskData.hasDrawn) then
                if checkint(aTaskData.hasDrawn) == 1 then
                    if checkint(aTaskData.id) >= checkint(bTaskData.id)  then
                         isTrue = false
                    else
                        isTrue = true
                    end
                else
                    local aReady = 0
                    local bReady = 0
                    if checkint(aTaskData.progress)  >=  checkint(aTaskData.targetNum) then
                        aReady = 1
                    end
                    if checkint(bTaskData.progress)  >=  checkint(bTaskData.targetNum) then
                        bReady = 1
                    end
                    if aReady == bReady  then
                        if checkint(aTaskData.id) >= checkint(bTaskData.id)  then
                            isTrue = false
                        else
                            isTrue = true
                        end
                    else
                        isTrue = aReady > bReady and true or false
                    end
                end
            else
                if checkint(aTaskData.hasDrawn) == 1 then
                    isTrue = false
                else
                    isTrue = true
                end
            end
            return isTrue
        end)
    end
end
--[[
刷新日期页签状态
--]]
function NoviceWelfareTaskMediator:RefreshTabState( )
    local homeData = self:GetHomeData()
    local viewComponent = self:GetViewComponent()
    viewComponent:RefreshTabState(homeData.tasks, homeData.today)
end
--[[
刷新日期按钮小红点
--]]
function NoviceWelfareTaskMediator:RefreshDayButtonRemindIcon( )
    local homeData = self:GetHomeData()
    local viewComponent = self:GetViewComponent()
    viewComponent:RefreshDayButtonRemindIcon(homeData.tasks, homeData.isLimit, homeData.today)
end
-------------------- private --------------------
-------------------------------------------------

-------------------------------------------------
-------------------- public ---------------------
--[[
刷新页面
@params map {
    tasks              list    任务数据
    isLimit            int     是否为限时任务
    currentActivePoint int     当前活动点数
    today              int     当前日期
    activePoint        map     活跃奖励
}
--]]
function NoviceWelfareTaskMediator:RefreshView( params )
    local viewComponent = self:GetViewComponent()
    if self:GetSelectedDay() then
        viewComponent:RefreshTabSelectState(self:GetSelectedDay(), false)
    end
    if not self:GetHomeData() or self:GetHomeData().isLimit ~= params.isLimit then
        self:SetHomeData(params)
        self:CaluculateDefaultDay()
    else
        self:SetHomeData(params)
    end
    self:RefreshPointProgressBar()
    self:RefreshCardPreviewButton()
    self:SortTasks()
    self:RefreshTabState()
    self:SelectDayTab(self:GetSelectedDay())
    self:CheckPointRewards()
    self:RefreshDayButtonRemindIcon()
end
--[[
隐藏页面
--]]
function NoviceWelfareTaskMediator:HideView( )
    self:GetViewComponent():setVisible(false)
end
--[[
显示页面
--]]
function NoviceWelfareTaskMediator:ShowView( )
    self:GetViewComponent():setVisible(true)
end
-------------------- public ---------------------
-------------------------------------------------

-------------------------------------------------
------------------- get / set -------------------
--[[
设置homeData
--]]
function NoviceWelfareTaskMediator:SetHomeData( homeData )
    self.homeData = homeData
end
--[[
获取homeData
--]]
function NoviceWelfareTaskMediator:GetHomeData()
    return self.homeData 
end
--[[
设置选定的日期
--]]
function NoviceWelfareTaskMediator:SetSelectedDay( selectedDay )
    self.selectedDay = selectedDay
end
--[[
获取选定的日期
--]]
function NoviceWelfareTaskMediator:GetSelectedDay()
    return self.selectedDay
end
------------------- get / set -------------------
-------------------------------------------------
return NoviceWelfareTaskMediator