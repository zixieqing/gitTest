--[[
打气球活动mediator
--]]
local Mediator = mvc.Mediator
local ActivityBalloonMediator = class("ActivityBalloonMediator", Mediator)
local NAME = "ActivityBalloonMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager('GameManager')
local scheduler = require('cocos.framework.scheduler')
function ActivityBalloonMediator:ctor( params, viewComponent )
	self.super:ctor(NAME, viewComponent)
	local datas = params or {}
	self.activityId = checkint(datas.activityId) -- 活动Id
	self.leftSeconds = checkint(datas.leftSeconds) -- 剩余时间
	self.activityData = {} -- 活动home数据
	self.activityTitle = datas.title -- 活动标题
	self.isControllable_ = true
end


function ActivityBalloonMediator:InterestSignals()
	local signals = {
		POST.ACTIVITY_BALLOON_HOME.sglName,
		POST.ACTIVITY_BALLOON_BREAK.sglName,
		'REFRESH_NOT_CLOSE_GOODS_EVENT'
	}
	return signals
end

function ActivityBalloonMediator:ProcessSignal( signal )
	local name = signal:GetName()
	print(name)
	local body = checktable(signal:GetBody())
	if name == POST.ACTIVITY_BALLOON_HOME.sglName then -- 打气球活动home
		self.activityData = body
		self:RefreshView()
	elseif name == POST.ACTIVITY_BALLOON_BREAK.sglName then -- 抽奖
		self:DrawBack(body)
	elseif name == 'REFRESH_NOT_CLOSE_GOODS_EVENT' then 
		self:RefreshLabel()
	end
end

function ActivityBalloonMediator:Initial( key )
	self.super.Initial(self, key)
	-- 创建MailPopup
	local viewComponent = require( 'Game.views.activity.balloon.ActivityBalloonView' ).new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	local scene = uiMgr:GetCurrentScene()
	scene:AddGameLayer(viewComponent)
	viewComponent.viewData.drawOneBtn:setOnClickScriptHandler(handler(self, self.DrawOneButtonCallback))
	viewComponent.viewData.drawAllBtn:setOnClickScriptHandler(handler(self, self.DrawAllButtonCallback))
	viewComponent.viewData.exchangeBtn:setOnClickScriptHandler(handler(self, self.ExchangeButtonCallback))
	viewComponent.viewData.getBtn:setOnClickScriptHandler(handler(self, self.GetButtonCallback))
	viewComponent.viewData.tabNameLabel:getLabel():setString(self.activityTitle)
	-- 开启定时器
	if checkint(self.leftSeconds) > 0 then
		self.timeScheduler = scheduler.scheduleGlobal(handler(self, self.UpdateLeftSeconds), 1)
		self.enterTimeStamp = os.time()
	end
end
--[[
刷新活动页面
--]]
function ActivityBalloonMediator:RefreshView()
	self:RefreshBalloonState()
	self:RefreshLabel()
end
--[[
刷新气球状态
--]]
function ActivityBalloonMediator:RefreshBalloonState()
	local activityData = self.activityData
	local viewData = self:GetViewComponent().viewData
	local balloonImgs = viewData.balloonImgs
	local balloonSpines = viewData.balloonSpines
	for i, v in ipairs(activityData.bubbleDrops) do
		local hasDrawn = checkint(v.hasDrawn) == 1
		if balloonImgs[i] then
			balloonImgs[i]:setVisible(hasDrawn)
		end
		if balloonSpines[i] then
			balloonSpines[i]:setVisible(not hasDrawn)
		end
	end
end
--[[
刷新文本框
--]]
function ActivityBalloonMediator:RefreshLabel()
	self:RefreshDrawConsume()
	self:RefreshOwnGoodsNum()
end
--[[
刷新抽奖按钮消耗
--]]
function ActivityBalloonMediator:RefreshDrawConsume()
	local activityData = self.activityData
	local viewData = self:GetViewComponent().viewData
	if viewData == nil then return end
	-- 抽一次
    display.reloadRichLabel(viewData.oneConsumeRichLabel, {c = {
       {fontSize = 16, color = '#5b3c25',text = __('消耗')},
       fontWithColor(16, {text = ' '}),
       {text = 1, fontSize = 18, color = '#d23d3d'},
       fontWithColor(16, {text = ' '}),
       {img = CommonUtils.GetGoodsIconPathById(activityData.bubbleGoodsId), scale = 0.24}
	}})
    -- 抽全部
    local leftBalloonNum = self:GetLeftBalloonNum()
    display.reloadRichLabel(viewData.allConsumeRichLabel, {c = {
	   {fontSize = 16, color = '#5b3c25',text = __('消耗')},
       fontWithColor(16, {text = ' '}),
       {text = tostring(leftBalloonNum), fontSize = 18, color = '#d23d3d'},
       -- {text = tostring(#activityData.bubbleDrops), fontSize = 24, color = '#d23d3d'},
       fontWithColor(16, {text = ' '}),
       {img = CommonUtils.GetGoodsIconPathById(activityData.bubbleGoodsId), scale = 0.24}
    }})
end
--[[
刷新拥有抽奖道具数量
--]]
function ActivityBalloonMediator:RefreshOwnGoodsNum()
	local activityData = self.activityData
	local viewData = self:GetViewComponent().viewData
	local hasNum = self:GetDrawGoodsNum()
    display.reloadRichLabel(viewData.hasRichLabel, {c = {
       {text = __('拥有'), fontSize = 26, ttf = true, font = TTF_GAME_FONT, color = '#5b3c25'},
       fontWithColor(16, {text = ' '}),
       {text = tostring(hasNum), fontSize = 28, color = '#5b3c25'},
       fontWithColor(16, {text = ' '}),
       {img = CommonUtils.GetGoodsIconPathById(activityData.bubbleGoodsId), scale = 0.24}
    }})
end
--[[
获取剩余气球数量
--]]
function ActivityBalloonMediator:GetLeftBalloonNum()
	local activityData = self.activityData
	local balloonNum = 0
	for i, v in ipairs(activityData.bubbleDrops) do
		if checkint(v.hasDrawn) == 0 then
			balloonNum = balloonNum + 1
		end
	end
	return balloonNum
end
--[[
获取抽奖道具数量
--]]
function ActivityBalloonMediator:GetDrawGoodsNum()
	return checkint(gameMgr:GetAmountByGoodId(self.activityData.bubbleGoodsId))
end
--[[
抽奖完成的处理
--]]
function ActivityBalloonMediator:DrawBack( responseData )
	local activityData = self.activityData
	-- 扣除花费道具
	local consumeGoods = {{goodsId = activityData.bubbleGoodsId, num = -#responseData.bubbles}}
	CommonUtils.DrawRewards(consumeGoods)
	-- 更新本地状态
	for i,v in ipairs(responseData.bubbles) do
		self.activityData.bubbleDrops[checkint(v)].hasDrawn = 1 
	end
	self:DrawAction(responseData.bubbles, responseData.rewards)
end
--[[
重置气球列表
--]]
function ActivityBalloonMediator:ResetBubbleDrops()
	local activityData = self.activityData
	for i, v in ipairs(activityData.bubbleDrops) do
		v.hasDrawn = 0
	end
	self:RefreshLabel()
	self:ResetAction()
end
--[[
抽奖动画
@params bubbles list 中奖列表
		rewards list 奖励
--]]
function ActivityBalloonMediator:DrawAction( bubbles, rewards )
	local activityData = self.activityData
	local viewData = self:GetViewComponent().viewData
	local randBubbles = self:RandSort(bubbles)
   	self.isControllable_ = false
	local scene = uiMgr:GetCurrentScene()
	scene:AddViewForNoTouch()
	for i, v in ipairs(randBubbles) do
    	transition.execute(viewData.view, nil, {delay = (i-1)*0.15, complete = function()
			viewData.balloonSpines[checkint(v)]:setAnimation(0, 'play', false)
			if app.audioMgr:IsOpenAudio() then
				AudioEngine.playEffect('res/music/Sound/ui_activity_dart.mp3')
			end
    		transition.execute(viewData.view, nil, {delay = 0.2, complete = function()
				if app.audioMgr:IsOpenAudio() then
					AudioEngine.playEffect('res/music/Sound/ui_activity_ballon.mp3')
				end
    		end})
    	end})
    	viewData.balloonImgs[checkint(v)]:setVisible(true)
    	viewData.balloonImgs[checkint(v)]:setOpacity(0)
    	viewData.balloonImgs[checkint(v)]:runAction(
    		cc.Sequence:create(
    			cc.DelayTime:create(0.5 + (i - 1) * 0.15),
    			cc.TargetedAction:create(viewData.balloonSpines[checkint(v)], cc.Hide:create()),
    			cc.FadeTo:create(0.2, 255*0.2)
    		)
    	)
	end
	-- 领奖
    transition.execute(viewData.view, nil, {delay = 1 + (#randBubbles-1) * 0.15, complete = function()
    	uiMgr:AddDialog('common.RewardPopup', {rewards = rewards, closeCallback = function ()
    		-- 判断是否需要刷新
    		if self:GetLeftBalloonNum()	== 0 then
    			self:ResetBubbleDrops()
    		else    		
    			self.isControllable_ = true
			end
    	end})
		local scene = uiMgr:GetCurrentScene()
		scene:RemoveViewForNoTouch()
    	self:RefreshLabel()
    end})
end
function ActivityBalloonMediator:ResetAction()
	local activityData = self.activityData
	local viewData = self:GetViewComponent().viewData
	self.isControllable_ = false
	for i, v in ipairs(activityData.bubbleDrops) do
		viewData.balloonSpines[i]:update(0)
		viewData.balloonSpines[i]:setToSetupPose()
		viewData.balloonSpines[i]:setAnimation(0, 'idle', true)
		viewData.balloonSpines[i]:runAction(
			cc.Sequence:create(
				cc.DelayTime:create((i - 1) * 0.1),
				cc.TargetedAction:create(viewData.balloonImgs[i], cc.Hide:create()),
				cc.ScaleTo:create(0.01, 0.2),
				cc.Show:create(),
				cc.EaseBounceOut:create(
					cc.ScaleTo:create(0.3, 1)
				)
			)
		)
	end
    transition.execute(viewData.view, nil, {delay = 0.4 + (#activityData.bubbleDrops-1) * 0.1, complete = function()
    	self.isControllable_ = true
    end})
end
--[[
兑换按钮回调
--]]
function ActivityBalloonMediator:ExchangeButtonCallback( sender )
	if not self.isControllable_ then return end
	PlayAudioByClickNormal()
	local activityData = self.activityData
	local params = {
		isLarge = true,
		exchangePost = POST.ACTIVITY_BALLOON_EXCHANGE, 
		exchangeListData = activityData.exchange,
		leftSeconds = self.leftSeconds,
		extra = {activityId = self.activityId},
		exchangeIdName = 'exchangeId',
	}
	if checkint(activityData.endStoryId) > 0 then
		if app.gameMgr:GetAmountByIdForce(activityData.endStoryGoods) >= checkint(activityData.endStoryGoodsNum) then
			params.exchangeBack = function ()
				app.activityMgr:ShowActivityStory({
					activityId = activityData.requestData.activityId,
					storyId = activityData.endStoryId,
					storyType = 'END',
				})
			end
		end
	end
	local mediator = require("Game.mediator.activity.ActivityExchangeLargeMediator").new(params)
	self:GetFacade():RegistMediator(mediator)
end
--[[
单抽按钮回调
--]]
function ActivityBalloonMediator:DrawOneButtonCallback( sender )
	if not self.isControllable_ then return end
	PlayAudioByClickNormal()
	local goodsNum = self:GetDrawGoodsNum()
	if goodsNum >= 1 then
		self:SendSignal(POST.ACTIVITY_BALLOON_BREAK.cmdName, {activityId = self.activityId, type = 1})
	else
		uiMgr:ShowInformationTips(__('道具不足'))
	end
end
--[[
抽取全部按钮回调
--]]
function ActivityBalloonMediator:DrawAllButtonCallback( sender )
	if not self.isControllable_ then return end
	PlayAudioByClickNormal()
	local activityData = self.activityData
	local balloonNum = #activityData.bubbleDrops
	local goodsNum = self:GetDrawGoodsNum()
	local leftNum = self:GetLeftBalloonNum()
	if goodsNum >= leftNum then -- 判断道具是否足够
		self:SendSignal(POST.ACTIVITY_BALLOON_BREAK.cmdName, {activityId = self.activityId, type = 2})
	else
		uiMgr:ShowInformationTips(__('道具不足'))
	end
end
--[[
获取抽奖道具按钮回调
--]]
function ActivityBalloonMediator:GetButtonCallback( sender )
	if not self.isControllable_ then return end
	PlayAudioByClickNormal()
	local activityData = self.activityData
	local exchangeListData = clone(activityData.bubbleConsume)
	for i,v in ipairs(exchangeListData) do
		v.rewards = {{
			goodsId = checkint(activityData.bubbleGoodsId),
			num = checkint(v.bubbleGoodsNum),
		}}
		v.leftExchangeTimes = -1
		v.require = clone(v.consume)
	end
	local mediator = require("Game.mediator.activity.ActivityExchangeLargeMediator").new({
		isLarge = false,
		exchangePost = POST.ACTIVITY_BALLOON_GET_BREAK_GOODS, 
		exchangeListData = exchangeListData,
		leftSeconds = self.leftSeconds,
		extra = {activityId = self.activityId},
		exchangeIdName = 'breakBubbleId',

	})
	self:GetFacade():RegistMediator(mediator)
end
--[[
随机排序
--]]
function ActivityBalloonMediator:RandSort( t )
    math.randomseed( tonumber(tostring(os.time()):reverse():sub(1,6)))
    local pool = clone(t)
    local poolSize = #pool
    local result = {}
    for i=1, poolSize  do
        local rand = math.random(i, poolSize)
        local tmp = pool[rand] or rand
        pool[rand] = pool[i] or i
        pool[i] = tmp
        table.insert(result, tmp)
    end
    return result
end
--[[
定时器回调
--]]
function ActivityBalloonMediator:UpdateLeftSeconds()
	local curTime = os.time()
	local deltaTime = math.abs(curTime - self.enterTimeStamp)
	self.enterTimeStamp = curTime
	self.leftSeconds = self.leftSeconds - deltaTime
	if self.leftSeconds - deltaTime <= 0 then
		AppFacade.GetInstance():UnRegsitMediator("ActivityBalloonMediator")
	end
end
function ActivityBalloonMediator:EnterLayer()
	self:SendSignal(POST.ACTIVITY_BALLOON_HOME.cmdName, {activityId = self.activityId})
end
function ActivityBalloonMediator:OnRegist(  )
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "show")
	regPost(POST.ACTIVITY_BALLOON_HOME)
	regPost(POST.ACTIVITY_BALLOON_BREAK)
	self:EnterLayer()
end

function ActivityBalloonMediator:OnUnRegist(  )
	unregPost(POST.ACTIVITY_BALLOON_HOME)
	unregPost(POST.ACTIVITY_BALLOON_BREAK)
	-- 移除定时器
	if self.timeScheduler then
		scheduler.unscheduleGlobal(self.timeScheduler)
	end
	-- 移除界面
	local scene = uiMgr:GetCurrentScene()
	scene:RemoveGameLayer(self:GetViewComponent())

end
return ActivityBalloonMediator