--[[
游乐园（夏活）扭蛋mediator
--]]
local Mediator = mvc.Mediator
local CarnieCapsuleMediator = class("CarnieCapsuleMediator", Mediator)
local NAME = "summerActivity.carnie.CarnieCapsuleMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager('GameManager')
local timerMgr = AppFacade.GetInstance():GetManager("TimerManager")
local summerActMgr = app.summerActMgr
local UIState = {
	SHOW = 1,
	HIDE = 2,
}
function CarnieCapsuleMediator:ctor( params, viewComponent )
	self.super:ctor(NAME, viewComponent)
	self.dailyRewards   = {} -- 每日奖励
    self.drawnRewards   = {} -- 已抽到的奖励列表
    self.remainTime     = 0  -- 剩余刷新时间
    self.drawTimes      = 0  -- 已抽奖总次数
	self.accReward      = 0  -- 是否领取累计奖励
	self.groupId        = 0  -- 每日奖励组别
	self.lotteryTimes   = 0  -- 抽奖总次数
	self.lotteryRewards = {} -- 抽奖奖励
	self.rareGoods      = {} -- 抽到的特典奖励
end


function CarnieCapsuleMediator:InterestSignals()
	local signals = {
		POST.CARNIE_CAPSULE_HOME.sglName,
		POST.CARNIE_CAPSULE_DRAW.sglName,
		POST.CARNIE_CAPSULE_ACC_DRAW.sglName,
		SIGNALNAMES.CACHE_MONEY_UPDATE_UI,
	}
	return signals
end

function CarnieCapsuleMediator:ProcessSignal( signal )
	local name = signal:GetName()
	print(name)
	local data = checktable(signal:GetBody())
	if name == SIGNALNAMES.CACHE_MONEY_UPDATE_UI then
		self:UpdateCountUI()
	elseif name == POST.CARNIE_CAPSULE_HOME.sglName then
		timerMgr:RemoveTimer(NAME) 
		local errcode = checkint(data.errcode)
		if errcode ~= 0 then 
			self:BackHome()
			return 
		end
		self:InitData(data)
		timerMgr:AddTimer({name = NAME, countdown = self.remainTime, callback = handler(self, self.UpdateRemainTime)})
		AppFacade.GetInstance():DispatchObservers("REFRESH_CARNIE_CAPSULE", data)
	elseif name == POST.CARNIE_CAPSULE_DRAW.sglName then
		AppFacade.GetInstance():DispatchObservers("DOT_LOG_EVENT_SEND" , {eventId = "1007-01"})
		local errcode = checkint(data.errcode)
		if errcode ~= 0 then 
			self:BackHome()
			return 
		end
		self:CapsuleDraw(data)
	elseif name == POST.CARNIE_CAPSULE_ACC_DRAW.sglName then
		local errcode = checkint(data.errcode)
		if errcode ~= 0 then 
			self:BackHome()
			return 
		end
		self:CapsuleAccDraw(data)
	end
end

function CarnieCapsuleMediator:Initial( key )
	self.super.Initial(self, key)
	-- 创建MailPopup
	local viewComponent = require( 'Game.views.summerActivity.carnie.CarnieCapsuleView' ).new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	uiMgr:SwitchToScene(viewComponent)
	if self.payload then
		self:InitData(self.payload)
	end
	-- 绑定事件
	viewComponent.viewData.tabNameLabel:setOnClickScriptHandler(handler(self, self.TipsButtonCallback))
	viewComponent.viewData.drawTenBtn:setOnClickScriptHandler(handler(self, self.DrawTenButtonCallback))
	viewComponent.viewData.drawOneBtn:setOnClickScriptHandler(handler(self, self.DrawOneButtonCallback))
	viewComponent.viewData.capsulePoolBtn:setOnClickScriptHandler(handler(self, self.capsulePoolButtonCallback))
	viewComponent.viewData.accRewardBg:setOnClickScriptHandler(handler(self, self.AccRewardButtonCallback))
	viewComponent.viewData.exCapsuleLayoutBg:setOnClickScriptHandler(handler(self, self.ExCapsuleButtonCallback))
	-- spine事件绑定
	viewComponent.viewData.jokerSpine:registerSpineEventHandler(handler(self, self.JokerSpineEndHandler), sp.EventType.ANIMATION_END)
	-- 开启定时器
	if self.remainTime > 0 then
		self:UpdateRemainTime(self.remainTime)
		timerMgr:AddTimer({name = NAME, countdown = self.remainTime, callback = handler(self, self.UpdateRemainTime)})
	else
		self:SendSignal(POST.CARNIE_CAPSULE_HOME.cmdName)
	end
	-- 更新顶部状态栏
	self:UpdateCountUI()
end
--[[
初始化数据
--]]
function CarnieCapsuleMediator:InitData( data )	
	local rewardPoolConf = CommonUtils.GetConfigAllMess('rewardPool', 'summerActivity')
    self.drawnRewards = checktable(data.rewards)
    self.remainTime   = checkint(data.remainTime) + 2
    self.drawTimes    = checkint(data.lotteryTimes) 
	self.accReward     = checkint(data.overTimeReward)	
	self.groupId      = checkint(data.groupId)
	self.lotteryTimes = checkint(data.lotteryTimes)
	self.rareGoods    = checktable(data.rareGoods)
	self.dailyRewards = {}
	for i, v in orderedPairs(rewardPoolConf[tostring(self.groupId)]) do
		if self.drawnRewards[tostring(v.id)] then
			v.stock = checkint(v.num) - checkint(self.drawnRewards[tostring(v.id)])
		else
			v.stock = checkint(v.num)
		end
		table.insert(self.dailyRewards, v)
	end
	self:InitView()
end
--[[
初始化页面
--]]
function CarnieCapsuleMediator:InitView()
	local viewData = self:GetViewComponent().viewData
	-- 刷新剩余扭蛋数目
	viewData.numComponent:SetStartNumber(self:GetCapsuleLeftNum())
	-- 刷新累计奖励页面
	self:RefreshAccRewardLayout()
	-- 刷新今日特典扭蛋页面
	self:RefreshExCapsuleLayout()
end
--[[
获取剩余扭蛋数量
--]]
function CarnieCapsuleMediator:GetCapsuleLeftNum()
	local num = 0 
	for i, v in ipairs(self.dailyRewards) do
		num = num + checkint(v.stock)
	end
	return num 
end
--[[
获取扭蛋总数
--]]
function CarnieCapsuleMediator:GetCapsuleTotalNum()
	local num = 0 
	for i, v in ipairs(self.dailyRewards) do
		num = num + checkint(v.num)
	end
	return num 
end
--[[
获取特殊扭蛋集合
--]]
function CarnieCapsuleMediator:GetExCapsuleRewards()
	local exRewards = {}
	local temp = {}
	for i, v in ipairs(self.dailyRewards) do
		if checkint(v.isRare) == 1 then
			table.insert(temp, clone(v))
		end
	end
	for i, v in ipairs(temp) do
		local num = checkint(v.num)
		local stock = checkint(v.stock)
		local drawnNum = num - stock
		for i = 1, num do
			if i <= drawnNum then
				v.hasDrawn = 1
			else
				v.hasDrawn = 0
			end
			table.insert(exRewards, clone(v))
		end
	end
	return exRewards
end
--[[
刷新累计奖励页面
--]]
function CarnieCapsuleMediator:RefreshAccRewardLayout()
	local viewData = self:GetViewComponent().viewData
	local accRewardLayout = viewData.accRewardLayout
	local accRemindIcon = viewData.accRemindIcon
	local accRewardTitle = viewData.accRewardTitle
	local accProgressBar = viewData.accProgressBar
	local accProgressLabel = viewData.accProgressLabel
	local accRewardBgLight = viewData.accRewardBgLight
	local accRewardConf = CommonUtils.GetConfigAllMess('overTimeReward', 'summerActivity')['1']
	local totalNum = checkint(accRewardConf.times)
	local lotteryTimes = checkint(self.lotteryTimes)
	-- 更新进度
	accProgressBar:setMaxValue(totalNum)
	accProgressBar:setValue(lotteryTimes)
	-- 更新显示文字
	accProgressLabel:setString(string.format('%s/%s', tostring(math.min(totalNum, lotteryTimes)), tostring(totalNum)))
	-- 更新小红点状态
	accRemindIcon:setVisible(self.accReward == 0 and lotteryTimes >= totalNum)
	accRewardBgLight:setVisible(self.accReward == 0 and lotteryTimes >= totalNum)
	if self.accReward == 1 then
		accRewardTitle:getLabel():setString(summerActMgr:getThemeTextByText(__('已领取')))
	end
	--
end
--[[
刷新特典扭蛋页面
--]]
function CarnieCapsuleMediator:RefreshExCapsuleLayout()
	local viewData = self:GetViewComponent().viewData
	local exCapsuleView = viewData.exCapsuleView
	local exCapsuleRewards = self:GetExCapsuleRewards()
	exCapsuleView:removeAllChildren()
	for i, v in ipairs(exCapsuleRewards) do
		if i <= 5 then
			local function callBack(sender)
				AppFacade.GetInstance():GetManager("UIManager"):ShowInformationTipsBoard({targetNode = sender, iconId = v.rewards[1].goodsId, type = 1})
			end
			local goodsNode = require('common.GoodNode').new({id = v.rewards[1].goodsId, showAmount = true, num = v.rewards[1].num, callBack = callBack})
			goodsNode:setScale(0.7)
			exCapsuleView:addChild(goodsNode)
			if v.hasDrawn == 1 then
				local icon = display.newImageView(_res('ui/common/raid_room_ico_ready.png'), goodsNode:getContentSize().width/2, goodsNode:getContentSize().height/2)
				goodsNode:addChild(icon, 5)
			end
			if i > 0 and i <= 3 then
				goodsNode:setPosition(cc.p(55 + i * 90, 275))
			elseif i > 3 and i <= 5 then
				goodsNode:setPosition(cc.p(105 + (i - 3) * 90, 185))
			end
		end
	end
end
--[[
刷新剩余时间
--]]
function CarnieCapsuleMediator:UpdateRemainTime( remainTime )
	if checkint(remainTime) > 0 then
		local hour   = math.floor(remainTime / 3600)
		local minute = math.floor((remainTime - hour*3600) / 60)
		local sec    = (remainTime - hour * 3600 - minute * 60)
		c = string.format("%.2d:%.2d:%.2d", hour, minute, sec)
		local viewData = self:GetViewComponent().viewData
		viewData.refreshTimeLabel:setString(c)
	else
		self:SendSignal(POST.CARNIE_CAPSULE_HOME.cmdName)
	end
end
--------------------------------------------------------------
------------------------- 点击回调 ----------------------------
--[[
顶部tips按钮点击回调
--]]
function CarnieCapsuleMediator:TipsButtonCallback( sender )
	PlayAudioByClickNormal()
	uiMgr:ShowIntroPopup({moduleId = '-4'})
end
--[[
抽取一次按钮点击回调
--]]
function CarnieCapsuleMediator:DrawOneButtonCallback( sender )
	PlayAudioClip(AUDIOS.UI2.UI_PIG_ONE.id)
	
	if self:GetCapsuleLeftNum() >= 1 then -- 判断库存是否充足
		if gameMgr:GetAmountByGoodId(summerActMgr:getCurCarnieCoin()) >= 1 then -- 判断货币是否充足
			self:SendSignal(POST.CARNIE_CAPSULE_DRAW.cmdName, {lotteryTimes = 1})
		else
			local goodsConf = CommonUtils.GetConfig('goods','activity', summerActMgr:getCurCarnieCoin())
			uiMgr:ShowInformationTips(string.fmt(summerActMgr:getThemeTextByText(__('_name_不足')), {['_name_'] = goodsConf.name}))
		end
	else
		uiMgr:ShowInformationTips(summerActMgr:getThemeTextByText(__('剩余扭蛋不足')))
	end
end
--[[
抽取十次按钮点击回调
--]]
function CarnieCapsuleMediator:DrawTenButtonCallback( sender )
	PlayAudioClip(AUDIOS.UI2.UI_PIG_TEN.id)
	
	if self:GetCapsuleLeftNum() >= 10 then -- 判断库存是否充足
		if gameMgr:GetAmountByGoodId(summerActMgr:getCurCarnieCoin()) >= 10 then -- 判断货币是否充足
			self:SendSignal(POST.CARNIE_CAPSULE_DRAW.cmdName, {lotteryTimes = 10})
		else
			local goodsConf = CommonUtils.GetConfig('goods','activity', summerActMgr:getCurCarnieCoin())
			uiMgr:ShowInformationTips(string.fmt(summerActMgr:getThemeTextByText(__('_name_不足')), {['_name_'] = goodsConf.name}))
		end
	else
		uiMgr:ShowInformationTips(summerActMgr:getThemeTextByText(__('剩余扭蛋不足')))
	end
end
--[[
今日蛋池按钮点击回调
--]]
function CarnieCapsuleMediator:capsulePoolButtonCallback( sender )
	PlayAudioByClickNormal()
	AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'}, {name = 'summerActivity.carnie.CarnieCapsulePoolMediator', params = {rewards = self.dailyRewards, groupId = self.groupId, rareGoods = self.rareGoods}})
end
--[[
累计奖励按钮点击回调
--]]
function CarnieCapsuleMediator:AccRewardButtonCallback( sender )
	PlayAudioByClickNormal()
	local accRewardConf = CommonUtils.GetConfigAllMess('overTimeReward', 'summerActivity')['1']
	local totalNum = checkint(accRewardConf.times)
	local lotteryTimes = checkint(self.lotteryTimes)
	if checkint(self.accReward) == 0 then
		if lotteryTimes >= totalNum then
			self:SendSignal(POST.CARNIE_CAPSULE_ACC_DRAW.cmdName, {rewardId = '1'})
		else
			AppFacade.GetInstance():GetManager("UIManager"):ShowInformationTipsBoard({targetNode = sender, iconId = accRewardConf.rewards[1].goodsId, type = 1})
		end
	else
		uiMgr:ShowInformationTips(summerActMgr:getThemeTextByText(__('奖励已领取')))
	end
end
--[[
特典蛋池按钮点击回调
--]]
function CarnieCapsuleMediator:ExCapsuleButtonCallback( sender )
	PlayAudioByClickNormal()
	AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'CarnieCapsuleMediator'}, {name = 'summerActivity.carnie.CarnieExCapsuleMediator', params = {groupId = self.groupId, rareGoods = self.rareGoods}})
end
------------------------- 点击回调 ----------------------------
--------------------------------------------------------------

--------------------------------------------------------------
------------------------- 动画相关 ----------------------------
--[[
单抽动画
@params isRare bool 是否为稀有扭蛋
--]]
function CarnieCapsuleMediator:DrawOneAction( isRare )
	PlayAudioClip(AUDIOS.UI.ui_machine_one.id)
	local viewData = self:GetViewComponent().viewData
	viewData.jokerSpine:update(0)
	viewData.jokerSpine:setToSetupPose()
	if isRare then
		viewData.jokerSpine:setAnimation(0, 'play2', false)
	else
		viewData.jokerSpine:setAnimation(0, 'play1', false)
	end
end
--[[
十连动画
--]]
function CarnieCapsuleMediator:DrawTenAction()
	PlayAudioClip(AUDIOS.UI.ui_machine_ten.id)
	local viewData = self:GetViewComponent().viewData
	viewData.jokerSpine:update(0)
	viewData.jokerSpine:setToSetupPose()
	viewData.jokerSpine:setAnimation(0, 'play3', false)
end
--[[
spine播放结束回调
--]]
function CarnieCapsuleMediator:JokerSpineEndHandler( event )
	local viewData = self:GetViewComponent().viewData
	if event.animation == 'play1' or event.animation == 'play2' then -- 单抽
		self:GetViewComponent():performWithDelay(
			function ()
				local backCallback = function ()
					self:ChangeUIState(UIState.SHOW)
				end
				-- 弹出领奖页面
				AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'}, {name = 'summerActivity.carnie.CarnieCapsuleRewardMediator', params = {rewards = self.lotteryRewards, backCallback = backCallback}})
				-- 还原spine状态
				viewData.jokerSpine:update(0)
				viewData.jokerSpine:setToSetupPose()
				viewData.jokerSpine:setAnimation(0, 'idle', true)
			end,
            (1 * cc.Director:getInstance():getAnimationInterval())
		)
	elseif event.animation == 'play3' then -- 十连
		local backCallback = function ()
			self:GetViewComponent():performWithDelay(
				function ()
					-- 改变spine状态
					viewData.jokerSpine:update(0)
					viewData.jokerSpine:setToSetupPose()
					viewData.jokerSpine:setAnimation(0, 'stop', false)
				end,
				(1 * cc.Director:getInstance():getAnimationInterval())
			)
		end
		-- 弹出领奖页面
		AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'}, {name = 'summerActivity.carnie.CarnieCapsuleRewardMediator', params = {rewards = self.lotteryRewards, backCallback = backCallback}})
	elseif event.animation == 'stop' then -- 十连恢复状态
		self:GetViewComponent():performWithDelay(
			function ()
				-- 还原spine状态
				viewData.jokerSpine:update(0)
				viewData.jokerSpine:setToSetupPose()
				viewData.jokerSpine:setAnimation(0, 'idle', true)
			end,
			(1 * cc.Director:getInstance():getAnimationInterval())
		)
		self:ChangeUIState(UIState.SHOW)
	end
end
--[[
改变抽卡界面UI状态
@params state UIState ui状态
--]]
function CarnieCapsuleMediator:ChangeUIState( state )
	local scene = uiMgr:GetCurrentScene()
	local viewData = self:GetViewComponent().viewData
	local bottomLayout = viewData.bottomLayout
	local accRewardLayout = viewData.accRewardLayout
	local exCapsuleLayout = viewData.exCapsuleLayout
	local jokerSpine = viewData.jokerSpine
	if state == UIState.SHOW then
		-- scene:RemoveViewForNoTouch()
		jokerSpine:runAction(
			cc.ScaleTo:create(0.4, 0.85)
		)
		bottomLayout:runAction(
			cc.Spawn:create(
				cc.FadeIn:create(0.4),
				cc.MoveTo:create(0.4, cc.p(bottomLayout:getPositionX(), 0))
			)
		)
		accRewardLayout:runAction(
			cc.Spawn:create(
				cc.FadeIn:create(0.4),
				cc.MoveTo:create(0.4, cc.p(display.SAFE_L, accRewardLayout:getPositionY()))
			)	
		)
		exCapsuleLayout:runAction(
			cc.Spawn:create{
				cc.FadeIn:create(0.4),
				cc.MoveTo:create(0.4, cc.p(80 + display.width - display.SAFE_L, exCapsuleLayout:getPositionY()))
			}
		)
		-- 刷新累计奖励页面
		self:RefreshAccRewardLayout()
		-- 刷新今日特典扭蛋页面
		self:RefreshExCapsuleLayout()
		-- 更新剩余扭蛋数目
		self:GetViewComponent():performWithDelay(
			function ()
				self:ChangeCapsuleLeftNum()
			end, 
			0.5
		)
	elseif state == UIState.HIDE then
		scene:AddViewForNoTouch()
		jokerSpine:runAction(
			cc.ScaleTo:create(0.4, 1)
		)
		bottomLayout:runAction(
			cc.Spawn:create(
				cc.FadeOut:create(0.4),
				cc.MoveTo:create(0.4, cc.p(bottomLayout:getPositionX(), -viewData.bottomLayoutSize.height))
			)
		)
		accRewardLayout:runAction(
			cc.Spawn:create(
				cc.FadeOut:create(0.4),
				cc.MoveTo:create(0.4, cc.p(-viewData.bottomLayoutSize.width, accRewardLayout:getPositionY()))
			)	
		)
		exCapsuleLayout:runAction(
			cc.Spawn:create{
				cc.FadeOut:create(0.4),
				cc.MoveTo:create(0.4, cc.p(display.width + viewData.exCapsuleLayoutSize.width, exCapsuleLayout:getPositionY()))
			}
		)
	end
end
--[[
改变剩余扭蛋数目
--]]
function CarnieCapsuleMediator:ChangeCapsuleLeftNum()
	local viewData = self:GetViewComponent().viewData
	local leftNum = self:GetCapsuleLeftNum()
	viewData.numComponent:ChangeNumber(leftNum)
end
------------------------- 动画相关 ----------------------------
--------------------------------------------------------------
--[[
抽奖回调处理
--]]
function CarnieCapsuleMediator:CapsuleDraw( data )
	-- 扣除道具
	CommonUtils.DrawRewards( {rewards = {goodsId = summerActMgr:getCurCarnieCoin(), num = -checkint(data.requestData.lotteryTimes)}})
	self:GetFacade():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI)
	-- 更新本地数据 
	self.lotteryTimes = self.lotteryTimes + checkint(data.requestData.lotteryTimes)
	local rewards = {} -- 奖励
	for k, time in pairs(data.rands) do
		for i, val in ipairs(self.dailyRewards) do
			if checkint(val.id) == checkint(k) then
				val.stock = val.stock - checkint(time)
				for i = 1, checkint(time) do
					local temp = clone(val.rewards[1])
					temp.isRare = checkint(val.isRare) == 1
					table.insert(rewards, temp)
				end
				break 
			end
		end
	end
	self.lotteryRewards = self:RandSort(rewards)
	if checkint(data.requestData.lotteryTimes) == 1 then -- 单抽
		self:ChangeUIState(UIState.HIDE)
		self:GetViewComponent():performWithDelay(
			function ()
				self:DrawOneAction(rewards[1].isRare)
			end, 
			0.5
		)
	elseif checkint(data.requestData.lotteryTimes) == 10 then -- 十连
		self:ChangeUIState(UIState.HIDE)
		self:GetViewComponent():performWithDelay(
			function ()
				self:DrawTenAction()
			end, 
			0.5
		)
	end
end
--[[
累计奖励领取处理
--]]
function CarnieCapsuleMediator:CapsuleAccDraw( data )
	self.accReward = 1
	uiMgr:AddDialog('common.RewardPopup', {rewards = data.rewards})
	self:RefreshAccRewardLayout()
end
--[[
更新顶部货币数量
--]]
function CarnieCapsuleMediator:UpdateCountUI()
	local viewData = self:GetViewComponent().viewData
	if viewData.moneyNods then
		for id,v in pairs(viewData.moneyNods) do
			v:updataUi(checkint(id)) --刷新每一个货币数量
		end
	end
end
--[[
随机排序
--]]
function CarnieCapsuleMediator:RandSort( t )
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
返回主界面
--]]
function CarnieCapsuleMediator:BackHome()
    PlayBGMusic()
	app:RetrieveMediator("Router"):Dispatch({name = NAME}, {name = "HomeMediator"})
end
function CarnieCapsuleMediator:EnterLayer()
end
function CarnieCapsuleMediator:OnRegist(  )
	-- self:EnterLayer()
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightHide")
	regPost(POST.CARNIE_CAPSULE_HOME, true)
	regPost(POST.CARNIE_CAPSULE_DRAW, true)
	regPost(POST.CARNIE_CAPSULE_ACC_DRAW, true)
end

function CarnieCapsuleMediator:OnUnRegist(  )
	unregPost(POST.CARNIE_CAPSULE_HOME)
	unregPost(POST.CARNIE_CAPSULE_DRAW)
	unregPost(POST.CARNIE_CAPSULE_ACC_DRAW)
	timerMgr:RemoveTimer(NAME) 
	-- 移除界面
	local scene = uiMgr:GetCurrentScene()
	scene:RemoveDialog(self:GetViewComponent())
end
return CarnieCapsuleMediator