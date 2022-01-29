--[[
 * author : liuzhipeng
 * descpt : 活动 皮肤嘉年华 主界面Mediator
]]
local ActivitySkinCarnivalMediator = class('ActivitySkinCarnivalMediator', mvc.Mediator)
local NAME = "activity.skinCarnival.ActivitySkinCarnivalMediator"
local CARNIVAL_TYPE = {
    FLASH_SALE = 1, -- 秒杀
    TASK       = 2, -- 任务
    LOTTERY    = 3, -- 抽奖
    CHALLENGE  = 4, -- 挑战
}
function ActivitySkinCarnivalMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.backMediatorName = params.requestData.backMediatorName
    self.activityId = checkint(params.requestData.activityId) -- 活动Id
    self.homeData = nil -- homeData
    self.rewardsLayoutShow = false -- 奖励页面是否显示
end

-------------------------------------------------
------------------ inheritance ------------------
function ActivitySkinCarnivalMediator:Initial( key )
    self.super.Initial(self, key)
    local viewComponent = app.uiMgr:SwitchToTargetScene('Game.views.activity.skinCarnival.ActivitySkinCarnivalScene')
    self:SetViewComponent(viewComponent)
    local viewData = viewComponent:GetViewData()
    viewData.tabNameLabel:setOnClickScriptHandler(handler(self, self.TipsButtonCallback))
    viewData.chestBtn:setOnClickScriptHandler(handler(self, self.ChestButtonCallback))
    viewData.backBtn:setOnClickScriptHandler(handler(self, self.BackButtonCallback))
    if self.payload then
        self:ConvertHomeData(self.payload)
        self:InitView()
    end
end

function ActivitySkinCarnivalMediator:InterestSignals()
    local signals = {
        POST.SKIN_CARNIVAL_HOME.sglName,
        POST.SKIN_CARNIVAL_DRAW_COLLECT.sglName,
        ACTIVITY_SKIN_CARNIVAL_ENTER_ACTION_END,
        ACTIVITY_SKIN_CARNIVAL_BACK_HOME,
        ACTIVITY_SKIN_CARNIVAL_REFRESH_REMIND_ICON,
	}
	return signals
end
function ActivitySkinCarnivalMediator:ProcessSignal( signal )
    local name = signal:GetName()
    local body = signal:GetBody()
    if name == POST.SKIN_CARNIVAL_HOME.sglName then -- home
        self:ConvertHomeData(body)
        self:InitView()
    elseif name == POST.SKIN_CARNIVAL_DRAW_COLLECT.sglName then -- 领取收集奖励
        app.uiMgr:AddDialog('common.RewardPopup', body)
        -- 更新本地数据
        local homeData = self:GetHomeData()
        for i, v in ipairs(homeData.collect) do
            if checkint(v.id) == checkint(body.requestData.collectId) then
                v.hasDrawn = true
                break
            end
        end
        -- 刷新页面
        self:RefreshChest()
        if self:GetRewardsLayoutShow() then
            local viewComponent = self:GetViewComponent()
            viewComponent:AddRewardLayout(homeData.collect, self:GetCollectedSkinNum(), handler(self, self.RewardGoodsButtonCallback))
        end
    elseif name == ACTIVITY_SKIN_CARNIVAL_ENTER_ACTION_END then -- 皮肤嘉年华入口进入动画结束
        self:ShowChildActivityView(body.index, body.pos)
    elseif name == ACTIVITY_SKIN_CARNIVAL_BACK_HOME then -- 皮肤嘉年华返回入口信号
        local homeData = self:GetHomeData()
        local viewComponent = self:GetViewComponent()
        viewComponent:ChildActivityBackAction()
        -- 刷新子活动入口
        viewComponent:RefreshSkinEntry(homeData.skin, homeData.tips)
        -- 刷新宝箱状态
        self:RefreshChest()
    elseif name == ACTIVITY_SKIN_CARNIVAL_REFRESH_REMIND_ICON then -- 刷新红点状态
        local homeData = self:GetHomeData()
        if body.state then
            homeData.tips[tostring(body.id)] = tostring(body.id)
        else
            homeData.tips[tostring(body.id)] = nil 
        end
        self:RefreshRemindIcon()
    end
end

function ActivitySkinCarnivalMediator:OnRegist()
	-- 隐藏顶部条
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightHide")
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "allhide")
    regPost(POST.SKIN_CARNIVAL_HOME)
    regPost(POST.SKIN_CARNIVAL_DRAW_COLLECT)
    -- self:EnterLayer()
end
function ActivitySkinCarnivalMediator:OnUnRegist()
	-- 恢复顶部条
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightShow")
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "hide")
    unregPost(POST.SKIN_CARNIVAL_HOME)
    unregPost(POST.SKIN_CARNIVAL_DRAW_COLLECT)
end
------------------ inheritance ------------------
-------------------------------------------------

-------------------------------------------------
-------------------- handler --------------------
--[[
tips按钮点击回调  
--]]
function ActivitySkinCarnivalMediator:TipsButtonCallback( sender )
    PlayAudioByClickNormal()
    app.uiMgr:ShowIntroPopup({moduleId = INTRODUCE_MODULE_ID.SKIN_CARNIVAL})
end
--[[
奖励宝箱按钮点击回调
--]]
function ActivitySkinCarnivalMediator:ChestButtonCallback( sender )
    PlayAudioByClickNormal()
    local viewComponent = self:GetViewComponent()
    local homeData =self:GetHomeData()
    if self:GetRewardsLayoutShow() then
        -- 移除奖励页面
        viewComponent:RemoveRewardLayout()
    else
        -- 创建奖励页面
        viewComponent:AddRewardLayout(homeData.collect, self:GetCollectedSkinNum(), handler(self, self.RewardGoodsButtonCallback))
    end
    self:SetRewardsLayoutShow(not self:GetRewardsLayoutShow())
end
--[[
宝箱奖励道具点击回调
--]]
function ActivitySkinCarnivalMediator:RewardGoodsButtonCallback( sender )
    PlayAudioByClickNormal()
    local tag = sender:getTag()
    local homeData = self:GetHomeData()
    local goodsData = homeData.collect[tag]
    local collectedSkinNum = self:GetCollectedSkinNum()
    if collectedSkinNum >= checkint(goodsData.targetNum) and not goodsData.hasDrawn then
        self:SendSignal(POST.SKIN_CARNIVAL_DRAW_COLLECT.cmdName, {activityId = self:GetActivityId(), collectId = goodsData.id})
    else
        app.uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = checkint(goodsData.rewards[1].goodsId), type = 1})
    end
end
--[[
皮肤活动入口点击回调
--]]
function ActivitySkinCarnivalMediator:SkinEntryButtonCallback( sender )
    PlayAudioByClickNormal()
    local tag = sender:getTag()
    local viewComponent = self:GetViewComponent()
    viewComponent:ChildActivityEnterAction(tag)
    self.rewardsLayoutShow = false
end
--[[
返回按钮点击回调
--]]
function ActivitySkinCarnivalMediator:BackButtonCallback( sender )
    PlayAudioByClickClose()
    app.router:Dispatch({name = NAME}, {name = self:GetBackToMediator()})
end
-------------------- handler --------------------
-------------------------------------------------

-------------------------------------------------
-------------------- private --------------------
--[[
转变homeData结构
--]]
function ActivitySkinCarnivalMediator:ConvertHomeData( homeData )
    local convertData = {}
    convertData.activitySummeryId = homeData.activitySummeryId
    local summaryConfig = CommonUtils.GetConfig('skinCarnival', 'summary', homeData.activitySummeryId)
    local skinConfig = CommonUtils.GetConfigAllMess('skin', 'skinCarnival')
    -- 奖励数据
    convertData.collect = {} 
    for k, v in pairs(summaryConfig.collect) do
        local tmp = clone(v)
        tmp.id = k
        -- 添加领取信息
        tmp.hasDrawn = false
        for _, id in ipairs(homeData.collectHasDrawn) do
            if checkint(k) == checkint(id) then
                tmp.hasDrawn = true
                break
            end
        end
        table.insert(convertData.collect, tmp)
    end
    table.sort(convertData.collect, function(a, b) return checkint(a.targetNum) < checkint(b.targetNum) end)
    -- 皮肤数据
    convertData.skin = {} 
    for k, v in pairs(skinConfig) do
        if checkint(v.summaryId) == checkint(homeData.activitySummeryId) then
            table.insert(convertData.skin, clone(v))
        end
    end
    table.sort(convertData.skin, function(a, b) return checkint(a.id) < checkint(b.id) end)
    -- 红点数据
    convertData.tips = {}
    for i, v in ipairs(homeData.tips) do
        convertData.tips[tostring(v)] = v
    end
    self:SetHomeData(convertData)
end
--[[
初始化页面
--]]
function ActivitySkinCarnivalMediator:InitView()
    local homeData = self:GetHomeData()
    local viewComponent = self:GetViewComponent()
    viewComponent:RefreshView(homeData.skin, checkint(homeData.activitySummeryId), checktable(homeData.tips), handler(self, self.SkinEntryButtonCallback))
    self:RefreshChest()
    self:RefreshRemindIcon()
end
--[[
刷新宝箱
--]]
function ActivitySkinCarnivalMediator:RefreshChest()
    local homeData = self:GetHomeData()
    local viewComponent = self:GetViewComponent()
    viewComponent:RefreshChest(homeData.collect, self:GetCollectedSkinNum())
end
--[[
显示子活动页面
@params index int 皮肤活动序号
--]]
function ActivitySkinCarnivalMediator:ShowChildActivityView( index, pos )
    local homeData = self:GetHomeData()
    local mediator = nil
    local params = clone(homeData.skin[index])
    params.activityId = self:GetActivityId()
    params.pos = pos
    if checkint(params.type) == CARNIVAL_TYPE.FLASH_SALE then -- 秒杀
        mediator = require('Game.mediator.activity.skinCarnival.ActivitySkinCarnivalFlashSaleMediator').new(params)
    elseif checkint(params.type) == CARNIVAL_TYPE.TASK then -- 任务
        mediator = require('Game.mediator.activity.skinCarnival.ActivitySkinCarnivalTaskMediator').new(params)
    elseif checkint(params.type) == CARNIVAL_TYPE.LOTTERY then -- 抽奖
        mediator = require('Game.mediator.activity.skinCarnival.ActivitySkinCarnivalLotteryMediator').new(params)
    elseif checkint(params.type) == CARNIVAL_TYPE.CHALLENGE then -- 挑战
        mediator = require('Game.mediator.activity.skinCarnival.ActivitySkinCarnivalChallengeMediator').new(params)
    else
        return
    end
    app:RegistMediator(mediator)
end
--[[
刷新红点状态
--]]
function ActivitySkinCarnivalMediator:RefreshRemindIcon()
    local homeData = self:GetHomeData()
    if next(homeData.tips) == nil and not self:GetChestDrawState() then
        app.badgeMgr:SetActivityTipByActivitiyId(self:GetActivityId(), false)
    else
        app.badgeMgr:SetActivityTipByActivitiyId(self:GetActivityId(), true)
    end
end
--[[
获取宝箱领取状态
@return canDraw bool 是否可领取
--]]
function ActivitySkinCarnivalMediator:GetChestDrawState()
    local homeData = self:GetHomeData()
    local collectedSkinNum = self:GetCollectedSkinNum()
    local canDraw = false
	for i, v in ipairs(checktable(homeData.collect)) do
		if not v.hasDrawn and collectedSkinNum >= checkint(v.targetNum) then
			canDraw = true
			break
		end
    end
    return canDraw
end
function ActivitySkinCarnivalMediator:EnterLayer()
    self:SendSignal(POST.SKIN_CARNIVAL_HOME.cmdName, {activityId = self:GetActivityId()})
end
-------------------- private --------------------
-------------------------------------------------

-------------------------------------------------
------------------- get / set -------------------
--[[
获取活动id
--]]
function ActivitySkinCarnivalMediator:GetActivityId()
    return self.activityId
end
--[[
设置homeData
@params map {
    activitySummeryId int  总表Id
    collect           list 收集奖励
    skin              list 皮肤信息
}
--]]
function ActivitySkinCarnivalMediator:SetHomeData( homeData )
    self.homeData = homeData
end
--[[
获取homeData
@return map {
    activitySummeryId int  总表Id
    collect           list 收集奖励
    skin              list 皮肤信息
}
--]]
function ActivitySkinCarnivalMediator:GetHomeData()
    return self.homeData
end
--[[
设置奖励页面显示状态
@params isShow bool 奖励页面是否显示
--]]
function ActivitySkinCarnivalMediator:SetRewardsLayoutShow( isShow )
    self.rewardsLayoutShow = isShow
end
--[[
获取奖励页面显示状态
--]]
function ActivitySkinCarnivalMediator:GetRewardsLayoutShow()
    return self.rewardsLayoutShow
end
--[[
获取本次活动皮肤获取数量
--]]
function ActivitySkinCarnivalMediator:GetCollectedSkinNum()
    local homeData = self:GetHomeData()
    local num = 0
    for i, v in ipairs(homeData.skin) do
        if app.cardMgr.IsHaveCardSkin(v.skinId) then
            num = num + 1
        end
    end
    return num 
end
--[[
获取返回的mediator信息
@return name string 返回的mediator名字
--]]
function ActivitySkinCarnivalMediator:GetBackToMediator()
	local name = 'HomeMediator'
	if nil ~= self.backMediatorName then
		name = self.backMediatorName
	end
	return name
end
------------------- get / set -------------------
-------------------------------------------------
return ActivitySkinCarnivalMediator
