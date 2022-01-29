--[[
 * author : liuzhipeng
 * descpt : 活动 皮肤嘉年华 任务活动Mediator
--]]
local ActivitySkinCarnivalTaskMediator = class('ActivitySkinCarnivalTaskMediator', mvc.Mediator)
local NAME = "activity.skinCarnival.ActivitySkinCarnivalTaskMediator"
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
function ActivitySkinCarnivalTaskMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.homeData = checktable(params)
    self.taskData = nil 
end

-------------------------------------------------
------------------ inheritance ------------------
function ActivitySkinCarnivalTaskMediator:Initial( key )
	self.super.Initial(self, key)
	local viewComponent  = require('Game.views.activity.skinCarnival.ActivitySkinCarnivalTaskView').new({group = self.homeData.group})
	viewComponent:setPosition(display.center)
	app.uiMgr:GetCurrentScene():AddDialog(viewComponent)
    self:SetViewComponent(viewComponent)
    local viewData = viewComponent:GetViewData()
    viewComponent.eaterLayer:setOnClickScriptHandler(handler(self, self.EaterLayerCallback))
    viewData.titleBtn:setOnClickScriptHandler(handler(self, self.TitleButtonCallback))
    viewData.switchBtn:setOnClickScriptHandler(handler(self, self.SwitchButtonCallback))
    viewData.storyBtn:setOnClickScriptHandler(handler(self, self.StoryButtonCallback))
    viewData.buyBtn:setOnClickScriptHandler(handler(self, self.BuyButtonCallback))
    viewData.rewardGoodsNode:RefreshSelf({callBack = handler(self, self.RewardButtonCallback)})
    self:RefreshSkin()
    viewComponent:EnterAction(self:GetHomeData().pos)
end

function ActivitySkinCarnivalTaskMediator:InterestSignals()
    local signals = {
        POST.SKIN_CARNIVAL_TASK.sglName,
        POST.SKIN_CARNIVAL_TASK_REWARD_DRAW.sglName,
	}
	return signals
end
function ActivitySkinCarnivalTaskMediator:ProcessSignal( signal )
    local name = signal:GetName()
    local body = signal:GetBody()
    if name == POST.SKIN_CARNIVAL_TASK.sglName then
        self:SetTaskData(body.tasks)
        self:InitView()
    elseif name == POST.SKIN_CARNIVAL_TASK_REWARD_DRAW.sglName then
        -- 消耗道具
        if body.requestData.isBuy then
            local homeData = self:GetHomeData()
            CommonUtils.DrawRewards({{goodsId = checkint(homeData.currency), num = -checkint(homeData.price)}})
        end
        app.uiMgr:AddDialog('common.RewardPopup', {rewards = body.rewards})
        self:RefreshBtnState()
        self:RefreshRemindIcon()
    end
end

function ActivitySkinCarnivalTaskMediator:OnRegist()
    regPost(POST.SKIN_CARNIVAL_TASK)
    regPost(POST.SKIN_CARNIVAL_TASK_REWARD_DRAW)
    self:EnterLayer()
end
function ActivitySkinCarnivalTaskMediator:OnUnRegist()
    app.uiMgr:GetCurrentScene():RemoveDialog(self:GetViewComponent())
    unregPost(POST.SKIN_CARNIVAL_TASK)
    unregPost(POST.SKIN_CARNIVAL_TASK_REWARD_DRAW)
    
end
------------------ inheritance ------------------
-------------------------------------------------

-------------------------------------------------
-------------------- handler --------------------
--[[
吞噬层点击回调
--]]
function ActivitySkinCarnivalTaskMediator:EaterLayerCallback( sender )
    PlayAudioByClickClose()
    local viewComponent = self:GetViewComponent()
    viewComponent:BackAction(self:GetHomeData().pos)
end
--[[
标题按钮点击回调
--]]
function ActivitySkinCarnivalTaskMediator:TitleButtonCallback( sender )
    PlayAudioByClickNormal()
    app.uiMgr:ShowIntroPopup({moduleId = INTRODUCE_MODULE_ID.SKIN_CARNIVAL_TASK})
end
--[[
切换按钮点击回调
--]]
function ActivitySkinCarnivalTaskMediator:SwitchButtonCallback( sender )
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
function ActivitySkinCarnivalTaskMediator:StoryButtonCallback( sender )
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
function ActivitySkinCarnivalTaskMediator:BuyButtonCallback( sender )
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
            self:SendSignal(POST.SKIN_CARNIVAL_TASK_REWARD_DRAW.cmdName, {activityId = homeData.activityId, group = homeData.group, isBuy = 1})
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
奖励道具点击回调
--]]
function ActivitySkinCarnivalTaskMediator:RewardButtonCallback( sender )
    PlayAudioByClickNormal()
    if app.cardMgr.IsHaveCardSkin(self:GetSkinId()) then
        app.uiMgr:ShowInformationTips(__('已获得该皮肤'))
    else
        local progressData = self:GetRewardProgress()
        if progressData.canDraw then
            local homeData = self:GetHomeData()
            self:SendSignal(POST.SKIN_CARNIVAL_TASK_REWARD_DRAW.cmdName, {activityId = homeData.activityId, group = homeData.group})
        else
            app.uiMgr:ShowInformationTipsBoard({
                targetNode = sender, iconId = self:GetSkinId(), type = 1
            })
            app.uiMgr:ShowInformationTips(__('完成任务可领取'))
        end
    end
end
-------------------- handler --------------------
-------------------------------------------------

-------------------------------------------------
-------------------- private --------------------
--[[
初始化页面
--]]
function ActivitySkinCarnivalTaskMediator:InitView()
    -- 刷新标题
    self:RefreshTitle()
    -- 刷新皮肤购买消耗
    self:RefreshBuySkinConsume()
    -- 刷新按钮状态
    self:RefreshBtnState()
    -- 刷新奖励
    self:RefreshRward()
    -- 刷新任务列表
    self:RefreshTaskList()
    -- 刷新小红点
    self:RefreshRemindIcon()
end
--[[
刷新标题
--]]
function ActivitySkinCarnivalTaskMediator:RefreshTitle()
    local homeData = self:GetHomeData()
    local viewComponent = self:GetViewComponent()
    viewComponent:RefreshTitle(homeData.title)
end
--[[
刷新皮肤购买消耗
--]]
function ActivitySkinCarnivalTaskMediator:RefreshBuySkinConsume()
    local homeData = self:GetHomeData()
    local currency = checkint(homeData.currency) -- 购买所需货币
    local price = checkint(homeData.price) -- 皮肤价格
    local viewComponent = self:GetViewComponent()
    viewComponent:RefreshBuyBtnConsumeRichlabel({goodsId = currency, num = price})
end
--[[
刷新皮肤节点
--]]
function ActivitySkinCarnivalTaskMediator:RefreshSkin()
    local viewComponent = self:GetViewComponent()
    local homeData = self:GetHomeData()
    local skinId = self:GetSkinId()
    viewComponent:RefreshSkinDrawNode(skinId, homeData.showEffect)
    viewComponent:ShowCardSkin()
end
--[[
刷新按钮状态
--]]
function ActivitySkinCarnivalTaskMediator:RefreshBtnState()
    local viewComponent = self:GetViewComponent()
    local skinId = self:GetSkinId()
    local progressData = self:GetRewardProgress()
    viewComponent:RefreshBtnState(app.cardMgr.IsHaveCardSkin(skinId, progressData.canDraw, skinId))
end
--[[
刷新奖励
--]]
function ActivitySkinCarnivalTaskMediator:RefreshRward()
    local viewComponent = self:GetViewComponent()
    local progressData = self:GetRewardProgress()
    viewComponent:RefreshRewardLayout(progressData.completionNum, progressData.targetNum, self:GetSkinId())
end
--[[
刷新任务列表
--]]
function ActivitySkinCarnivalTaskMediator:RefreshTaskList()
    local viewComponent = self:GetViewComponent()
    -- 转换后的任务数据
    local taskData = self:ConvertTaskData(self:GetTaskData())
    viewComponent:RefreshTaskListView(taskData)
end
--[[
刷新小红点
--]]
function ActivitySkinCarnivalTaskMediator:RefreshRemindIcon()
    local viewComponent = self:GetViewComponent()
    local homeData = self:GetHomeData()
    local taskData = self:GetTaskData()
    local skinId = self:GetSkinId()
    if app.cardMgr.IsHaveCardSkin(skinId) then
        -- 拥有皮肤则小红点消失
        viewComponent:RefreshRewardRemindIcon(false)
        app:DispatchObservers(ACTIVITY_SKIN_CARNIVAL_REFRESH_REMIND_ICON, {id = homeData.id, state = false})
        return 
    end
    -- 刷新抽奖小红点
    local rewardState = self:GetRewardProgress().canDraw
    viewComponent:RefreshRewardRemindIcon(rewardState)
    -- 刷新home
    app:DispatchObservers(ACTIVITY_SKIN_CARNIVAL_REFRESH_REMIND_ICON, {id = homeData.id, state = rewardState})
end
--[[
将任务数据转换为列表所需的格式
@params taskData 服务端返回的任务数据
--]]
function ActivitySkinCarnivalTaskMediator:ConvertTaskData( taskData )
    local convertData = {}
    local config = CommonUtils.GetConfigAllMess('task', 'skinCarnival')
    for i, v in ipairs(checktable(taskData)) do
        local temp = clone(config[tostring(v.taskId)])
        temp.progress = checkint(v.progress)
        table.insert(convertData, temp)
    end
    -- 排序
    table.sort(convertData,function(a,b)
        if (checkint(a.progress) >= checkint(a.targetNum)) == (checkint(b.progress) >= checkint(b.targetNum)) then
            return a.id < b.id
        else
            return checkint(a.progress) < checkint(a.targetNum)
        end
    end)
    return convertData
end
function ActivitySkinCarnivalTaskMediator:EnterLayer()
    local homeData = self:GetHomeData()
    self:SendSignal(POST.SKIN_CARNIVAL_TASK.cmdName, {activityId = homeData.activityId, group = homeData.group})
end
-------------------- private --------------------
-------------------------------------------------

-------------------------------------------------
------------------- get / set -------------------
--[[
获取homeData
--]]
function ActivitySkinCarnivalTaskMediator:GetHomeData()
    return self.homeData
end
--[[
设置任务数据
--]]
function ActivitySkinCarnivalTaskMediator:SetTaskData( taskData )
    self.taskData = checktable(taskData)
end
--[[
获取任务数据
--]]
function ActivitySkinCarnivalTaskMediator:GetTaskData()
    return self.taskData
end
--[[
获取皮肤id
--]]
function ActivitySkinCarnivalTaskMediator:GetSkinId()
    local homeData = self:GetHomeData()
    return checkint(homeData.skinId)
end
--[[
获取奖励进度
@return progressData {
    completionNum int  任务完成数目
    targetNum     int  目标完成数目
    canDraw       bool 是否可领取皮肤
}
--]]
function ActivitySkinCarnivalTaskMediator:GetRewardProgress()
    local homeData = self:GetHomeData()
    local taskData = self:GetTaskData()
    local targetNumConfig = CommonUtils.GetConfig('skinCarnival', 'taskTargetNum', homeData.group)
    local completionNum = 0 -- 任务完成数目
    for i, v in ipairs(taskData) do
        local taskConfig = CommonUtils.GetConfig('skinCarnival', 'task', v.taskId)
        -- 根据配表中的目标数目判断任务是否完成
        if checkint(v.progress) >= checkint(taskConfig.targetNum) then
            completionNum = completionNum + 1
        end
    end
    local progressData = {
        completionNum = completionNum,
        targetNum = checkint(targetNumConfig.targetNum),
        canDraw = completionNum >= checkint(targetNumConfig.targetNum)
    }
    return progressData
end
------------------- get / set -------------------
-------------------------------------------------
return ActivitySkinCarnivalTaskMediator
