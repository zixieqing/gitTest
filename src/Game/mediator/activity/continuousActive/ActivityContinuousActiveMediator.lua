--[[
 * author : liuzhipeng
 * descpt : 活动 连续活跃活动 Mediator
]]
local Mediator = mvc.Mediator
local ActivityContinuousActiveMediator = class("ActivityContinuousActiveMediator", Mediator)
local NAME = "activity.continuousActive.ActivityContinuousActiveMediator"

function ActivityContinuousActiveMediator:ctor( params, viewComponent )
	self.super:ctor(NAME, viewComponent)
	local datas = params or {}
	self.activityId = checkint(datas.activityId) -- 活动Id
	self.activityData = {} -- 活动home数据
	self.isLastWeek = false 
	self.isControllable_ = true
end


function ActivityContinuousActiveMediator:InterestSignals()
	local signals = {
        POST.ACTIVITY_CONTINUOUS_ACTIVE_HOME.sglName,
        POST.ACTIVITY_CONTINUOUS_ACTIVE_YEAR_DRAW.sglName,
        POST.ACTIVITY_CONTINUOUS_ACTIVE_WEEKLY_SUPPLEMENT.sglName,
		POST.ACTIVITY_CONTINUOUS_ACTIVE_WEEKLY_DRAW.sglName,
		POST.ACTIVITY_CONTINUOUS_ACTIVE_YEAR_SUPPLEMENT.sglName,
		ACTIVITY_CONTINUOUS_ACTIVE_SUPPLEMENT
	}
	return signals
end

function ActivityContinuousActiveMediator:ProcessSignal( signal )
	local name = signal:GetName()
	-- print(name)
	local body = checktable(signal:GetBody())
    if name == POST.ACTIVITY_CONTINUOUS_ACTIVE_HOME.sglName then
		self.homeData = checktable(body)
		self.yearReawrds = self:ConvertYearRewards(self.homeData.yearRewards)
		self:InitView()
	elseif name == POST.ACTIVITY_CONTINUOUS_ACTIVE_YEAR_DRAW.sglName then -- 领取连续活跃奖励
		app.uiMgr:AddDialog('common.RewardPopup', {rewards = body.rewards})
		-- 更新本地数据
		local yearRewards = self:GetCurrentRewards()
		for i, v in ipairs(yearRewards) do
			if body.requestData.day == checkint(v.day) then
				v.hasDrawn = 1
				self:GetViewComponent():GetViewData().rewardNodeList[i]:SetState(1)
				break 
			end
		end
		self:RefreshActivityRemindIcon()
	elseif name == POST.ACTIVITY_CONTINUOUS_ACTIVE_YEAR_SUPPLEMENT.sglName then -- 连续活跃补签
		-- 扣除道具
		CommonUtils.DrawRewards( {rewards = {goodsId = self.homeData.yearSupplementCurrency, num = -body.requestData.num * checkint(self.homeData.yearSupplementPrice)}})
		app.uiMgr:ShowInformationTips(__('补签成功'))
		self:SendSignal(POST.ACTIVITY_CONTINUOUS_ACTIVE_HOME.cmdName)
	elseif name == POST.ACTIVITY_CONTINUOUS_ACTIVE_WEEKLY_SUPPLEMENT.sglName then -- 周活跃补签
		local homeData = self:GetHomeData()
		CommonUtils.DrawRewards({
			{
				goodsId = checkint(homeData.weeklySupplementCurrency),
				num = - checkint(homeData.weeklySupplementPrice)
			}
		})
		if body.requestData.type == 1 then -- 1:本周，2：上周
			table.insert(checktable(homeData.currentWeeklyProgress), body.requestData.day)
		else
			table.insert(checktable(homeData.lastWeeklyProgress), body.requestData.day)
		end
		self:RefreshWeeklyLayout()
		self:RefreshActivityRemindIcon()
	elseif name == POST.ACTIVITY_CONTINUOUS_ACTIVE_WEEKLY_DRAW.sglName then -- 周活跃奖励领取
		local homeData = self:GetHomeData()
		app.uiMgr:AddDialog('common.RewardPopup', {rewards = body.rewards})
		if body.requestData.type == 1 then -- 1:本周，2：上周
			homeData.currentWeeklyRewardsHasDrawn = 1
		else
			homeData.lastWeeklyRewardsHasDrawn = 1
		end
		self:RefreshWeeklyLayout()
		self:RefreshActivityRemindIcon()
	elseif name == ACTIVITY_CONTINUOUS_ACTIVE_SUPPLEMENT then
		self:SendSignal(POST.ACTIVITY_CONTINUOUS_ACTIVE_YEAR_SUPPLEMENT.cmdName, {day = body.str, num = body.num})
	end
end

function ActivityContinuousActiveMediator:Initial( key )
    self.super.Initial(self, key)
    
	local viewComponent = require( 'Game.views.activity.continuousActive.ActivityContinuousActiveView' ).new()
	display.commonUIParams(viewComponent, {ap = display.CENTER, po = display.center})
	self:SetViewComponent(viewComponent)
	local viewData = viewComponent:GetViewData()
	viewData.tipsBtn:setOnClickScriptHandler(handler(self, self.TipsButtonCallback))
	viewData.supplementBtn:setOnClickScriptHandler(handler(self, self.SupplementButtonCallback))
	viewData.weeklyDrawBtn:setOnClickScriptHandler(handler(self, self.WeeklyDrawButtonCallback))
	viewData.weeklySwitchBtn:setOnClickScriptHandler(handler(self, self.WeeklySwitchButtonCallback))
end

function ActivityContinuousActiveMediator:enterLayer()
	self:SendSignal(POST.ACTIVITY_CONTINUOUS_ACTIVE_HOME.cmdName)
end

function ActivityContinuousActiveMediator:CleanupView()
	local viewComponent = self:GetViewComponent()
	local scene = app.uiMgr:GetCurrentScene()
    if scene and viewComponent and not tolua.isnull(viewComponent) then
		scene:RemoveGameLayer(viewComponent)
		scene:RemoveViewForNoTouch()
    end
end

function ActivityContinuousActiveMediator:OnRegist(  )
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "show")
	regPost(POST.ACTIVITY_CONTINUOUS_ACTIVE_HOME)
	regPost(POST.ACTIVITY_CONTINUOUS_ACTIVE_YEAR_DRAW)
	regPost(POST.ACTIVITY_CONTINUOUS_ACTIVE_WEEKLY_SUPPLEMENT)
	regPost(POST.ACTIVITY_CONTINUOUS_ACTIVE_WEEKLY_DRAW)
	regPost(POST.ACTIVITY_CONTINUOUS_ACTIVE_YEAR_SUPPLEMENT)
	self:enterLayer()
end

function ActivityContinuousActiveMediator:OnUnRegist(  )
	unregPost(POST.ACTIVITY_CONTINUOUS_ACTIVE_HOME)
	unregPost(POST.ACTIVITY_CONTINUOUS_ACTIVE_YEAR_DRAW)
	unregPost(POST.ACTIVITY_CONTINUOUS_ACTIVE_WEEKLY_SUPPLEMENT)
	unregPost(POST.ACTIVITY_CONTINUOUS_ACTIVE_WEEKLY_DRAW)
	unregPost(POST.ACTIVITY_CONTINUOUS_ACTIVE_YEAR_SUPPLEMENT)
end
-------------------------------------
-------------- handler --------------
--[[
提示按钮点击回调
--]]
function ActivityContinuousActiveMediator:TipsButtonCallback( sender )
	PlayAudioByClickNormal()
	app.uiMgr:ShowIntroPopup({moduleId = JUMP_MODULE_DATA.CONTINUOUS_ACTIVE})
end
--[[
补签按钮点击回调
--]]
function ActivityContinuousActiveMediator:SupplementButtonCallback( sender )
	PlayAudioByClickNormal()
	local homeData = self:GetHomeData()
	local detail = self:ProgressDetailDecode(homeData.yearProgressDetail)
	-- 如果字符串长度与持续天数不符，用0补齐
	if checkint(homeData.yearContinuousDay) > string.len(detail) then
		for i = 1, checkint(homeData.yearContinuousDay) - string.len(detail) do
			detail = detail .. '0'
		end
	end
	app.uiMgr:AddDialog('Game.views.activity.continuousActive.ActivityContinuousActiveSupplementView', {
		yearProgressDetail = detail,
		yearSupplementCurrency = homeData.yearSupplementCurrency,
		yearSupplementPrice = homeData.yearSupplementPrice,
	})
end
--[[
周奖励领取按钮点击回调
--]]
function ActivityContinuousActiveMediator:WeeklyDrawButtonCallback( sender )
	PlayAudioByClickNormal()
	self:SendSignal(POST.ACTIVITY_CONTINUOUS_ACTIVE_WEEKLY_DRAW.cmdName, {type = self.isLastWeek and 2 or 1})
end
--[[
周奖励切换按钮点击回调
--]]
function ActivityContinuousActiveMediator:WeeklySwitchButtonCallback( sender )
	PlayAudioByClickNormal()
	self.isLastWeek = not self.isLastWeek 
	self:RefreshWeeklyLayout()
end
--[[
连续奖励领取按钮点击回调
--]]
function ActivityContinuousActiveMediator:ContinuousDrawButtonCallback( sender )
	PlayAudioByClickNormal()
	local tag = sender:getTag()
	self:SendSignal(POST.ACTIVITY_CONTINUOUS_ACTIVE_YEAR_DRAW.cmdName, {day = tag})
end
--[[
每周活跃补签按钮点击回调
--]]
function ActivityContinuousActiveMediator:WeeklySupplementButtonCallback( sender )
	PlayAudioByClickNormal()
	local tag = sender:getTag()
	local homeData = self:GetHomeData()
	if app.gameMgr:GetAmountByIdForce(homeData.weeklySupplementCurrency) >= checkint(homeData.weeklySupplementPrice) then
		local config = CommonUtils.GetConfig('goods', 'goods', homeData.weeklySupplementCurrency) or {}

		app.uiMgr:AddCommonTipDialog({
			text =  string.fmt(__('是否花费_num__name_复原？'), {['_num_'] = checkint(homeData.weeklySupplementPrice), ['_name_'] = tostring(config.name)}) ,
			callback = function ()
				PlayAudioByClickNormal()
				self:SendSignal(POST.ACTIVITY_CONTINUOUS_ACTIVE_WEEKLY_SUPPLEMENT.cmdName, {type = self.isLastWeek and 2 or 1, day = tag})
			end,
		})
	else
		-- 道具不足
		local config = CommonUtils.GetConfig('goods', 'goods', homeData.weeklySupplementCurrency) or {}
		app.uiMgr:ShowInformationTips(string.fmt(__('_name_不足'), {['_name_'] = tostring(config.name)}))
	end
end
-------------- handler --------------
-------------------------------------

-------------------------------------
-------------- private --------------
--[[
初始化view
--]]
function ActivityContinuousActiveMediator:InitView()
	local viewComponent = self:GetViewComponent()
	self:RefreshProgressBar()
	self:RefreshRewards()
	self:RefreshWeeklyLayout()
	self:RefreshActivityRemindIcon()
end
--[[
刷新进度条
--]]
function ActivityContinuousActiveMediator:RefreshProgressBar()
	local viewComponent = self:GetViewComponent()
	local homeData = self:GetHomeData()
	local maxDays = self:GetProgressBarMaxDays()
	viewComponent:RefreshProgressBar(homeData.yearProgress, homeData.yearContinuousDay, maxDays)
end
--[[
刷新连续活跃奖励
--]]
function ActivityContinuousActiveMediator:RefreshRewards()
	local viewComponent = self:GetViewComponent()
	local homeData = self:GetHomeData()
	local yearRewards = self:GetCurrentRewards()
	viewComponent:RefreshRewardsLayout({
		yearRewards = checktable(yearRewards),
		continuousDays = checkint(homeData.yearProgress),
		callback = handler(self, self.ContinuousDrawButtonCallback)
	})
end
--[[
刷新周奖励
--]]
function ActivityContinuousActiveMediator:RefreshWeeklyLayout()
	local viewComponent = self:GetViewComponent()
	local homeData = self:GetHomeData()
	local data = {}
	data.weeklyRewards = homeData.weeklyRewards
	data.isLastWeek = self.isLastWeek
	data.callback = handler(self, self.WeeklySupplementButtonCallback)
	if self.isLastWeek then
		-- 上周数据
		data.weeklyProgress = homeData.lastWeeklyProgress
		data.hasDrawn = checkint(homeData.lastWeeklyRewardsHasDrawn) == 1 or false
	else
		-- 本周数据
		data.weeklyProgress = homeData.currentWeeklyProgress
		data.hasDrawn = checkint(homeData.currentWeeklyRewardsHasDrawn) == 1 or false
	end
	viewComponent:RefreshWeeklyLayout(data)
end
--[[
活跃详情解码
@params str string 加密后的字符串
@return binStr string 解码后的二进制字符串
--]]
function ActivityContinuousActiveMediator:ProgressDetailDecode( str ) 
	if not str then return '' end
    local codec = require('codec')
    local zlib = require("zlib")
    local binStr = zlib.inflate()(codec.base64_decode(str))
    return binStr
end
--[[
刷新活动红点
--]]
function ActivityContinuousActiveMediator:RefreshActivityRemindIcon()
	local homeData = self:GetHomeData()
	local activityMediator = self:GetFacade():RetrieveMediator('ActivityMediator') 
	if not activityMediator then return end
	local show = false
	local yearRewards = self:GetCurrentRewards()
	for i, v in ipairs(yearRewards) do
		if checkint(homeData.yearProgress) >= checkint(v.day) and checkint(v.hasDrawn) == 0 then
			show = true 
			break
		end
	end
	if not show then
		if #checktable(homeData.lastWeeklyProgress) == 7 and checkint(homeData.lastWeeklyRewardsHasDrawn) == 0 then
			show = true
		end
		if #checktable(homeData.currentWeeklyProgress) == 7 and checkint(homeData.currentWeeklyRewardsHasDrawn) == 0 then
			show = true
		end
	end

	if show then
		-- 活动页添加红点
		activityMediator:AddRemindIcon(checkint(ACTIVITY_ID.CONTINUOUS_ACTIVE))
		app.gameMgr:GetUserInfo().tips.continuousActive = 1
	else
		-- 活动页移除红点
		activityMediator:ClearRemindIcon(checkint(ACTIVITY_ID.CONTINUOUS_ACTIVE))
		app.gameMgr:GetUserInfo().tips.continuousActive = 0
	end
end
--[[
转换奖励数据
--]]
function ActivityContinuousActiveMediator:ConvertYearRewards( oriData )
	local yearRewards = {}
	for i, v in ipairs(checktable(oriData)) do
		if not yearRewards[checkint(v.type)] then
			yearRewards[checkint(v.type)] = {}
		end
		table.insert(yearRewards[checkint(v.type)], v)
	end
	return yearRewards
end
-------------- private --------------
-------------------------------------

-------------------------------------
-------------- get/set --------------
--[[
获取homeData
--]]
function ActivityContinuousActiveMediator:GetHomeData()
	return self.homeData
end
--[[
获取当前奖励
--]]
function ActivityContinuousActiveMediator:GetCurrentRewards()
	for type, rewards in ipairs(self.yearReawrds) do
		for _, v in ipairs(rewards) do
			if checkint(v.hasDrawn) == 0 then
				return rewards
			end
		end
	end
	return self.yearReawrds[#self.yearReawrds]
end
--[[
获取进度条最大天数
--]]
function ActivityContinuousActiveMediator:GetProgressBarMaxDays()
	local rewards = self:GetCurrentRewards()
	return checkint(rewards[#rewards].day)
end
-------------- get/set --------------
-------------------------------------
return ActivityContinuousActiveMediator