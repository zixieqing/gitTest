--[[
 * author : liuzhipeng
 * descpt : 活动 组合活动 抽奖Mediator
--]]
local AssemblyActivityWheelMediator = class('AssemblyActivityWheelMediator', mvc.Mediator)
local NAME = 'activity.assemblyActivity.AssemblyActivityWheelMediator'
function AssemblyActivityWheelMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    local args = checktable(params)
    self.activityId = checkint(args.activityId)
end
-------------------------------------------------
------------------ inheritance ------------------
function AssemblyActivityWheelMediator:Initial( key )
    self.super.Initial(self, key)
end
    
function AssemblyActivityWheelMediator:InterestSignals()
    local signals = {
        POST.ASSEMBLY_ACTIVITY_BIGWHEEL_HOME.sglName,
		POST.ASSEMBLY_ACTIVITY_BIGWHEEL_DRAW.sglName,
		'ASSEMBLY_ACTIVITY_WHEEL_EXCHANGE_CLEAR'
    }
    return signals
end
function AssemblyActivityWheelMediator:ProcessSignal( signal )
    local name = signal:GetName()
    local body = signal:GetBody()
    if name == POST.ASSEMBLY_ACTIVITY_BIGWHEEL_HOME.sglName then
        self:SetHomeData(body)
        self:ShowWheelView()
	elseif name == POST.ASSEMBLY_ACTIVITY_BIGWHEEL_DRAW.sglName then
		self:ChargeWheelDrawResponse(body)
	elseif name == 'ASSEMBLY_ACTIVITY_WHEEL_EXCHANGE_CLEAR' then
		-- 如果存在转盘页面，刷新页面
		local wheelView = app.uiMgr:GetCurrentScene():GetGameLayerByName("wheelView")
		if wheelView then
			wheelView:ChargeWheelRemindIconClear()
		end
    end
end

function AssemblyActivityWheelMediator:OnRegist()
    regPost(POST.ASSEMBLY_ACTIVITY_BIGWHEEL_HOME)
    regPost(POST.ASSEMBLY_ACTIVITY_BIGWHEEL_DRAW)
    self:EnterLayer()
end
function AssemblyActivityWheelMediator:OnUnRegist()
    regPost(POST.ASSEMBLY_ACTIVITY_BIGWHEEL_HOME)
    regPost(POST.ASSEMBLY_ACTIVITY_BIGWHEEL_DRAW)
    -- 移除界面
    local scene = app.uiMgr:GetCurrentScene()
    scene:RemoveDialog(self:GetViewComponent())
end
------------------ inheritance ------------------
-------------------------------------------------

-------------------------------------------------
-------------------- handler --------------------
--[[
返回主界面
--]]
function AssemblyActivityWheelMediator:BackButtonCallback( sender )
    PlayAudioByClickClose()
    app:UnRegsitMediator(NAME)
end
--[[
收费转盘活动单抽按钮回调
--]]
function AssemblyActivityWheelMediator:ChargeWheelOneDrawBtnCallback( sender )
	PlayAudioByClickNormal()
	local activityId = self.activityId
	local activityDatas = self:GetHomeData()
	if checkint(activityDatas.leftDrawnTimes) > 0 or checkint(activityDatas.leftDrawnTimes) == -1 then
		if activityDatas.isOneFree then
			self:ChargeWheelAddMaskView()
			self:SendSignal(POST.ASSEMBLY_ACTIVITY_BIGWHEEL_DRAW.cmdName, {activityId = activityId, drawTimes = 1})
		else
			for i,v in ipairs(activityDatas.oneConsumeGoods) do
				local hasNums = app.gameMgr:GetAmountByGoodId(v.goodsId)
				if checkint(hasNums) < checkint(v.num) then
					if GAME_MODULE_OPEN.NEW_STORE and checkint(v.goodsId) == DIAMOND_ID then
						app.uiMgr:showDiamonTips()
					else
						local goodsDatas = CommonUtils.GetConfig('goods', 'goods', v.goodsId)
						app.uiMgr:ShowInformationTips(string.fmt(__('_name_不足'), {['_name_'] = goodsDatas.name}))
					end
					return
				end
			end
			self:ChargeWheelAddMaskView()
			self:SendSignal(POST.ASSEMBLY_ACTIVITY_BIGWHEEL_DRAW.cmdName, {activityId = activityId, drawTimes = 1})
		end
		DotGameEvent.SendEvent(DotGameEvent.EVENTS.RETURN_LOTTERY_ONE)
	else
		app.uiMgr:ShowInformationTips(__('今日祈愿次数不足'))
	end
end
--[[
收费转盘活动十连按钮回调
--]]
function AssemblyActivityWheelMediator:ChargeWheelMultiDrawBtnCallback( sender )
	PlayAudioByClickNormal()
	local activityId = self.activityId
	local activityDatas = self:GetHomeData()
	if checkint(activityDatas.leftDrawnTimes) >= 10 or checkint(activityDatas.leftDrawnTimes) == -1 then
		for i,v in ipairs(activityDatas.tenConsumeGoods) do
			local hasNums = app.gameMgr:GetAmountByGoodId(v.goodsId)
			if checkint(hasNums) < math.ceil(checkint(v.num) * checkint(activityDatas.discount or 100)/100)  then
				if GAME_MODULE_OPEN.NEW_STORE and checkint(v.goodsId) == DIAMOND_ID then
					app.uiMgr:showDiamonTips()
				else
					local goodsDatas = CommonUtils.GetConfig('goods', 'goods', v.goodsId)
					app.uiMgr:ShowInformationTips(string.fmt(__('_name_不足'), {['_name_'] = tostring(goodsDatas.name)}))
				end
				return
			end
		end
		self:ChargeWheelAddMaskView()
		self:SendSignal(POST.ASSEMBLY_ACTIVITY_BIGWHEEL_DRAW.cmdName, {activityId = activityId, drawTimes = 10})
		DotGameEvent.SendEvent(DotGameEvent.EVENTS.RETURN_LOTTERY_TEN)
	else
		app.uiMgr:ShowInformationTips(__('今日祈愿次数不足'))
	end
end
--[[
收费转盘提示按钮回调
--]]
function AssemblyActivityWheelMediator:ChargeWheelTipsButtonCallback( sender )
	PlayAudioByClickNormal()
	local homeData = self:GetHomeData()
	local capsuleProbabilityView = require( 'Game.views.drawCards.CapsuleProbabilityView' ).new({rate = homeData.rate})
    display.commonLabelParams(capsuleProbabilityView.viewData_.title, fontWithColor(18, {text = __('概率')}))
    local scene = app.uiMgr:GetCurrentScene()
    scene:AddDialog(capsuleProbabilityView)
end
--[[
收费转盘返回按钮回调
--]]
function AssemblyActivityWheelMediator:ChargeWheelBackButtonCallback( sender )
	PlayAudioByClickClose()
	app:UnRegsitMediator(NAME)
end
-------------------- handler --------------------
-------------------------------------------------

-------------------------------------------------
-------------------- private --------------------
--[[
初始化view
--]]
function AssemblyActivityWheelMediator:InitView()

end
function AssemblyActivityWheelMediator:EnterLayer()
    self:SendSignal(POST.ASSEMBLY_ACTIVITY_BIGWHEEL_HOME.cmdName, {activityId = self.activityId})
end
--[[
显示转盘页面
--]]
function AssemblyActivityWheelMediator:ShowWheelView(  )
	if app.uiMgr:GetCurrentScene():GetGameLayerByName('wheelView') then
		return 
	end
    local homeData = self:GetHomeData()
    local params = {
		content = homeData.rateRewards,
		leftBtnCost = homeData.oneConsumeGoods,
		rightBtnCost = homeData.tenConsumeGoods,
		leftDrawnTimes = homeData.leftDrawnTimes,
		activityId = self.activityId,
		leftBtnCallback = handler(self, self.ChargeWheelOneDrawBtnCallback),
		rightBtnCallback = handler(self, self.ChargeWheelMultiDrawBtnCallback),
		discount = homeData.discount or 100,
		isFree = homeData.isOneFree,
		timesRewards = homeData.timesRewards,
        drawnTimes = checkint(homeData.drawnTimes),
		leftSeconds = checkint(homeData.leftSeconds),
		tipsBtnCallback = handler(self, self.ChargeWheelTipsButtonCallback),
		backBtnCallback = handler(self, self.ChargeWheelBackButtonCallback),
		type = 2
    }
    local view = require("common.CommonWheelView").new(params)
    view:setName('wheelView')
	view:setPosition(display.center)
	self:SetViewComponent(view)
    app.uiMgr:GetCurrentScene():AddGameLayer(view)
end
--[[
收费转盘抽奖返回处理
--]]
function AssemblyActivityWheelMediator:ChargeWheelDrawResponse( datas )
	local activityId = self.activityId
	local activityDatas = self:GetHomeData()
	-- 扣除道具
	if checkint(datas.requestData.drawTimes) == 1 then
		if activityDatas.isOneFree then
			activityDatas.isOneFree = false
		else
			local temp = clone(activityDatas.oneConsumeGoods)
			for i,v in ipairs(temp) do
				v.num = -v.num
			end
			CommonUtils.DrawRewards(temp)
		end
	else
		local temp = clone(activityDatas.tenConsumeGoods)
		for i,v in ipairs(temp) do
			if activityDatas.discount then
				v.num = -math.ceil(checkint(v.num) * checkint(activityDatas.discount or 100) / 100)
			else
				v.num = -v.num
			end
		end
		CommonUtils.DrawRewards(temp)
	end
	if checkint(activityDatas.leftDrawnTimes) ~= -1 then
		local leftDrawnTimes = checkint(activityDatas.leftDrawnTimes) - checkint(datas.requestData.drawTimes)
		activityDatas.leftDrawnTimes = leftDrawnTimes
	end
	-- 转换奖励的数据结构
	local cloneDatas = clone(datas)
	local temp = {}
	cloneDatas.requestData = nil
	for i,v in orderedPairs(cloneDatas) do
		table.insert(temp, v)
	end
	-- 更新本地抽奖次数
	activityDatas.drawnTimes = checkint(activityDatas.drawnTimes) + #temp
	local wheelView = app.uiMgr:GetCurrentScene():GetGameLayerByName("wheelView")
	if wheelView then
		local closeAction = nil
		if checkint(activityDatas.endStoryGoods) > 0 then
			closeAction = self:ChargeWheelHasRareGoods(checkint(activityDatas.endStoryGoods), checkint(activityDatas.endStoryGoodsNum), temp)
		end
		wheelView:DrawAction({rateRewards = temp, closeAction = closeAction})
	end
end
--[[
添加屏蔽层
--]]
function AssemblyActivityWheelMediator:ChargeWheelAddMaskView()
	local scene = app.uiMgr:GetCurrentScene()
	scene:AddViewForNoTouch()
	local view = self:GetViewComponent()
	view:runAction(
		cc.Sequence:create(
			cc.DelayTime:create(3),
			cc.CallFunc:create(function()
				local wheelView = app.uiMgr:GetCurrentScene():GetGameLayerByName("wheelView")
				if not wheelView then
					scene:RemoveViewForNoTouch()
				end
			end)
		)
	)
end
--[[
判断是否抽到剧情关键道具或者剧情关键道具数目是足够
--]]
function AssemblyActivityWheelMediator:ChargeWheelHasRareGoods( goodsId, goodsNum, rewards )
	local goodsEnough = false
	if checkint(goodsNum) > 1 then
		local hasNum = app.gameMgr:GetAmountByGoodId(checkint(goodsId))
		if checkint(hasNum) >= goodsNum then
			goodsEnough = true
		end
	elseif checkint(goodsNum) == 1 then
		for i,v in ipairs(checktable(rewards)) do
			if checkint(v.rewards[1].goodsId) == checkint(goodsId) then
				goodsEnough = true
				break
			end
		end
	end
	return goodsEnough
end
-------------------- private --------------------
-------------------------------------------------

-------------------------------------------------
------------------- get / set -------------------
--[[
设置homeData
--]]
function AssemblyActivityWheelMediator:SetHomeData( homeData )
    self.homeData = homeData
end
--[[
获取homeData
--]]
function AssemblyActivityWheelMediator:GetHomeData()
    return self.homeData
end
------------------- get / set -------------------
-------------------------------------------------
return AssemblyActivityWheelMediator