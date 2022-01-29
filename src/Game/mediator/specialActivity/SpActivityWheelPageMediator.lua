--[[
 * author : liuzhipeng
 * descpt : 特殊活动 兑换活动页签mediator
]]
local SpActivityWheelPageMediator = class('SpActivityWheelPageMediator', mvc.Mediator)

local CreateView = nil
local SpActivityWheelPageView = require("Game.views.specialActivity.SpActivityWheelPageView")

function SpActivityWheelPageMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'SpActivityWheelPageMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance method

function SpActivityWheelPageMediator:Initial(key)
    self.super.Initial(self, key)
    self.ownerNode_ = self.ctorArgs_.ownerNode
    self.typeData_  = self.ctorArgs_.typeData

    -- create view
    if self.ownerNode_ then
        local size = self.ownerNode_:getContentSize()
        local view = SpActivityWheelPageView.new({size = size})
        display.commonUIParams(view, {po = cc.p(size.width * 0.5, size.height * 0.5)})
        self.ownerNode_:addChild(view,19)
        self:SetViewComponent(view)
        local viewData = self.viewComponent.viewData
        viewData.enterBtn:setOnClickScriptHandler(handler(self, self.EnterButtonCallback))
        viewData.drawBtn:setOnClickScriptHandler(handler(self, self.DrawButtonCallback))
    end
end


function SpActivityWheelPageMediator:CleanupView()
    if self.ownerNode_ then
        if self.viewComponent and self.viewComponent:getParent() then
            self.viewComponent:runAction(cc.RemoveSelf:create())
            self.viewComponent = nil
        end
        self.ownerNode_ = nil
    end
end


function SpActivityWheelPageMediator:OnRegist()
    regPost(POST.ACTIVITY_WHEEL_DRAW)
end
function SpActivityWheelPageMediator:OnUnRegist()
    unregPost(POST.ACTIVITY_WHEEL_DRAW)
end


function SpActivityWheelPageMediator:InterestSignals()
    local signals = {
        POST.ACTIVITY_WHEEL_DRAW.sglName,
	}
	return signals
end
function SpActivityWheelPageMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody()
    if name == POST.ACTIVITY_WHEEL_DRAW.sglName then
        self:ChargeWheelDrawAction(body)
    end
end


-------------------------------------------------
-- handler method

-------------------------------------------------
-- get /set
-------------------------------------------------
-- private method
--[[
刷新页面
--]]
function SpActivityWheelPageMediator:RefreshView()
    local viewComponent = self:GetViewComponent()
	local activityHomeDatas = self.typeData_
	local activityDatas = self.homeData_
	-- 判断是否存在次数奖励
	if activityDatas.timesRewards and next(activityDatas.timesRewards) ~= nil then
		viewComponent.viewData.drawBtn:setVisible(true)
		viewComponent.viewData.enterBtn:setVisible(true)
		viewComponent.viewData.drawBg:setVisible(true)
		viewComponent.viewData.btnBg:setVisible(true)
	else
		viewComponent.viewData.drawBtn:setVisible(false)
		viewComponent.viewData.drawBg:setVisible(false)
        viewComponent.viewData.enterBtn:setPositionX(viewComponent.viewData.view:getContentSize().width / 2 + 273)
		viewComponent.viewData.enterBtn:setVisible(true)
		viewComponent.viewData.btnBg:setVisible(true)
	end
end
--[[
前往按钮回调
--]]
function SpActivityWheelPageMediator:EnterButtonCallback( sender )
    PlayAudioByClickNormal()
	local activityId = checkint(self.typeData_.activityId)
	local activityHomeDatas = self.typeData_
	local activityDatas = self.homeData_
	local params = {
		content = activityDatas.rateRewards,
		leftBtnCost = activityDatas.oneConsumeGoods,
		rightBtnCost = activityDatas.tenConsumeGoods,
		leftDrawnTimes = activityDatas.leftDrawnTimes,
		activityId = activityDatas.requestData.activityId,
		leftBtnCallback = handler(self, self.ChargeWheelOneDrawBtnCallback),
		rightBtnCallback = handler(self, self.ChargeWheelMultiDrawBtnCallback),
		discount = activityDatas.discount,
		isFree = activityDatas.isOneFree,
		timesRewards = activityDatas.timesRewards,
        drawnTimes = checkint(activityDatas.drawnTimes),
		leftSeconds = checkint(activityHomeDatas.closeTimestamp_) - os.time(),
		tips = activityHomeDatas.detail[i18n.getLang()]
	}
	if checkint(activityDatas.endStoryId) > 0 then -- 结束剧情
		local function closeCallback()
			app.activityMgr:ShowActivityStory({
				activityId = activityDatas.requestData.activityId,
				storyId = activityDatas.endStoryId,
				storyType = 'END',
			})
		end
		params.closeCallback = handler(self, closeCallback)
	end
	local function enterView ()
		local scene = AppFacade.GetInstance():GetManager("UIManager"):GetCurrentScene()
		local view = require("common.CommonWheelView").new(params)
		view:setName('wheelView')
		view:setPosition(display.center)
		scene:AddGameLayer(view)
	end

	if checkint(activityDatas.startStoryId) > 0 then
		app.activityMgr:ShowActivityStory({
			activityId = activityDatas.requestData.activityId,
			storyId = activityDatas.startStoryId,
			storyType = 'START',
			callback = enterView
		})
	else
		enterView()
	end
end
--[[
豪华奖励按钮回调
--]]
function SpActivityWheelPageMediator:DrawButtonCallback( sender )
    local activityId = checkint(self.typeData_.activityId)
	local activityHomeDatas = self.typeData_
	local mediator = require( 'Game.mediator.ActivityPropExchangeMediator').new({data = {activityId = activityId, leftSeconds = checkint(activityHomeDatas.closeTimestamp_) - os.time(), tag = 110125}})
	self:GetFacade():RegistMediator(mediator)
end
--[[
收费转盘活动单抽按钮回调
--]]
function SpActivityWheelPageMediator:ChargeWheelOneDrawBtnCallback( sender )
	PlayAudioByClickNormal()
	local activityId = checkint(self.typeData_.activityId)
	local activityDatas = self.homeData_
	if checkint(activityDatas.leftDrawnTimes) > 0 or checkint(activityDatas.leftDrawnTimes) == -1 then
		if activityDatas.isOneFree then
			self:ChargeWheelAddMaskView()
			self:SendSignal(POST.ACTIVITY_WHEEL_DRAW.cmdName, {activityId = activityId, drawTimes = 1})
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
		self:SendSignal(POST.ACTIVITY_WHEEL_DRAW.cmdName, {activityId = activityId, drawTimes = 1})
		end
	else
		app.uiMgr:ShowInformationTips(__('今日祈愿次数不足'))
	end
end
--[[
收费转盘活动十连按钮回调
--]]
function SpActivityWheelPageMediator:ChargeWheelMultiDrawBtnCallback( sender )
	PlayAudioByClickNormal()
	local activityId = checkint(self.typeData_.activityId)
	local activityDatas = self.homeData_
	if checkint(activityDatas.leftDrawnTimes) >= 10 or checkint(activityDatas.leftDrawnTimes) == -1 then
		for i,v in ipairs(activityDatas.tenConsumeGoods) do
			local hasNums = app.gameMgr:GetAmountByGoodId(v.goodsId)
			if checkint(hasNums) < math.ceil(checkint(v.num) * checkint(activityDatas.discount)/100)  then
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
		self:SendSignal(POST.ACTIVITY_WHEEL_DRAW.cmdName, {activityId = activityId, drawTimes = 10})
	else
		app.uiMgr:ShowInformationTips(__('今日祈愿次数不足'))
	end
end
--[[
添加屏蔽层
--]]
function SpActivityWheelPageMediator:ChargeWheelAddMaskView()
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
收费转盘抽奖回调
--]]
function SpActivityWheelPageMediator:ChargeWheelDrawAction( datas )
	local activityId = checkint(self.typeData_.activityId)
	local activityDatas = self.homeData_
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
				v.num = -math.ceil(checkint(v.num) * checkint(activityDatas.discount) / 100)
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
	-- 判断红点状态
	-- if not self:GetChargeWheelRemindIconState(activityId) then
	-- 	self:ClearRemindIcon(activityId)
	-- end
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
判断付费转盘活动红点状态
--]]
function SpActivityWheelPageMediator:GetChargeWheelRemindIconState( activityId )
	local activityDatas = self.homeData_
	if not activityDatas then return end
	local state = true
	if not activityDatas.isOneFree then -- 是否存在免费次数
		for i,v in ipairs(activityDatas.oneConsumeGoods) do -- 物品是否足够
			local hasNums = app.gameMgr:GetAmountByGoodId(v.goodsId)
			if checkint(hasNums) < checkint(v.num) then
				state = false
				break
			end
		end
	end
	if checkint(activityDatas.leftDrawnTimes) == 0 then -- 是否有抽奖次数
		state = false
	end
	return state
end
--[[
付费转盘兑换红点清空
--]]
function SpActivityWheelPageMediator:ChargeWheelRemindIconClear( activityId )
	local activityDatas = self.homeData_
	local drawnTimes = checkint(activityDatas.drawnTimes)
	for k, v in pairs(activityDatas.timesRewards) do
		if drawnTimes >= checkint(v.times) then
			v.hasDrawn = 1
		end
	end
	-- 如果存在转盘页面，刷新页面
	local wheelView = app.uiMgr:GetCurrentScene():GetGameLayerByName("wheelView")
	if wheelView then
		wheelView:ChargeWheelRemindIconClear()
	end
end
--[[
判断是否抽到剧情关键道具或者剧情关键道具数目是足够
--]]
function SpActivityWheelPageMediator:ChargeWheelHasRareGoods( goodsId, goodsNum, rewards )
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
-------------------------------------------------
-- public method
function SpActivityWheelPageMediator:resetHomeData(homeData)
    self.homeData_ = homeData
    self:RefreshView()
end


return SpActivityWheelPageMediator
