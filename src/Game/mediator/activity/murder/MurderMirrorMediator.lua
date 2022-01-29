--[[
 * author : liuzhipeng
 * descpt : 杀人案（19夏活）抽奖Mediator
]]
local MurderMirrorMediator = class('MurderMirrorMediator', mvc.Mediator)
local NAME = "activity.murder.MurderMirrorMediator"
local UIState = {
	SHOW = 1,
	HIDE = 2,
}

function MurderMirrorMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'MurderMirrorMediator', viewComponent)
end
-------------------------------------------------
-- inheritance methods

function MurderMirrorMediator:Initial(key)
    self.super.Initial(self, key)
    local viewComponent = app.uiMgr:SwitchToTargetScene('Game.views.activity.murder.MurderMirrorScene')
	self:SetViewComponent(viewComponent)
    local viewData = viewComponent:GetViewData()
	-- 绑定事件
	viewData.tabNameLabel:setOnClickScriptHandler(handler(self, self.TipsButtonCallback))
	viewData.drawTenBtn:setOnClickScriptHandler(handler(self, self.DrawTenButtonCallback))
	viewData.drawOneBtn:setOnClickScriptHandler(handler(self, self.DrawOneButtonCallback))
	viewData.capsulePoolBtn:setOnClickScriptHandler(handler(self, self.CapsulePoolButtonCallback))
	viewData.exCapsuleLayoutBg:setOnClickScriptHandler(handler(self, self.ExCapsuleButtonCallback))
	-- spine事件绑定
	viewComponent.viewData.mirrorSpine:registerSpineEventHandler(handler(self, self.MirrorSpineEndHandler), sp.EventType.ANIMATION_END)
end

function MurderMirrorMediator:InterestSignals()
    local signals = {
		POST.MURDER_LOTTERY_HOME.sglName,
		POST.MURDER_LOTTERY.sglName,
        SIGNALNAMES.CACHE_MONEY_UPDATE_UI,
	}
	return signals
end
function MurderMirrorMediator:ProcessSignal(signal)
    local name = signal:GetName()
	local body = signal:GetBody()
	if name == POST.MURDER_LOTTERY_HOME.sglName then -- home
		-- 刷新界面
		self:ConvertLotteryData(checktable(body))
		self:InitView()
		AppFacade.GetInstance():DispatchObservers("REFRESH_CARNIE_CAPSULE", body)
	elseif name == POST.MURDER_LOTTERY.sglName then -- 抽奖
		self:CapsuleDraw(body)
    elseif name == SIGNALNAMES.CACHE_MONEY_UPDATE_UI then -- 刷新顶部状态栏
        self:GetViewComponent():UpdateMoneyBar()
    end
end

function MurderMirrorMediator:OnRegist()
	
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightHide")
	regPost(POST.MURDER_LOTTERY_HOME)
	regPost(POST.MURDER_LOTTERY)
	PlayBGMusic(app.murderMgr:GetBgMusic(AUDIOS.GHOST.Food_ghost_dancing.id))
	self:EnterLayer()
	local spinePath = app.murderMgr:GetSpinePath('ui/home/activity/murder/effect/murder_draw_watch').path
	SpineCache(SpineCacheName.MURDER):addCacheData(spinePath , spinePath , 1)
end
function MurderMirrorMediator:OnUnRegist()
	SpineCache(SpineCacheName.MURDER):removeCacheData(app.murderMgr:GetSpinePath('ui/home/activity/murder/effect/murder_draw_watch').path)
    -- 移除界面
	-- local scene = app.uiMgr:GetCurrentScene()
	-- scene:RemoveDialog(self:GetViewComponent())
	regPost(POST.MURDER_LOTTERY_HOME)
	regPost(POST.MURDER_LOTTERY)
end
-------------------------------------------------
-- handler method
--[[
顶部tips按钮点击回调
--]]
function MurderMirrorMediator:TipsButtonCallback( sender )
	PlayAudioByClickNormal()
    app.uiMgr:ShowIntroPopup({moduleId = '-30'})
end
--[[
抽取一次按钮点击回调
--]]
function MurderMirrorMediator:DrawOneButtonCallback( sender )
	-- PlayAudioClip(AUDIOS.UI2.UI_PIG_ONE.id)
	PlayAudioByClickNormal()
	if self:GetCapsuleLeftNum() >= 1 then -- 判断库存是否充足
		if app.gameMgr:GetAmountByGoodId(app.murderMgr:GetLotteryGoodsId()) >= 1 then -- 判断货币是否充足
			self:SendSignal(POST.MURDER_LOTTERY.cmdName, {lotteryTimes = 1})
		else
			local goodsConf = CommonUtils.GetConfig('goods','activity', app.murderMgr:GetLotteryGoodsId())
			app.uiMgr:ShowInformationTips(string.fmt(app.murderMgr:GetPoText(__('_name_不足')), {['_name_'] = goodsConf.name}))
		end
	else
		app.uiMgr:ShowInformationTips(app.murderMgr:GetPoText(__('剩余扭蛋不足')))
	end
end
--[[
抽取十次按钮点击回调
--]]
function MurderMirrorMediator:DrawTenButtonCallback( sender )
	-- PlayAudioClip(AUDIOS.UI2.UI_PIG_TEN.id)
	PlayAudioByClickNormal()
	if self:GetCapsuleLeftNum() >= 10 then -- 判断库存是否充足
		if app.gameMgr:GetAmountByGoodId(app.murderMgr:GetLotteryGoodsId()) >= 10 then -- 判断货币是否充足
			self:SendSignal(POST.MURDER_LOTTERY.cmdName, {lotteryTimes = 10})
		else
			local goodsConf = CommonUtils.GetConfig('goods','activity', app.murderMgr:GetLotteryGoodsId())
			app.uiMgr:ShowInformationTips(string.fmt(app.murderMgr:GetPoText(__('_name_不足')), {['_name_'] = goodsConf.name}))
		end
	else
		app.uiMgr:ShowInformationTips(app.murderMgr:GetPoText(__('剩余扭蛋不足')))
	end
end
--[[
今日蛋池按钮点击回调
--]]
function MurderMirrorMediator:CapsulePoolButtonCallback( sender )
	PlayAudioByClickNormal()
	local lotteryData = app.murderMgr:GetLotteryData()
	if lotteryData then
		app.router:Dispatch({name = 'HomeMediator'}, {name = 'activity.murder.MurderMirrorPoolMediator', params = {rewards = lotteryData.dailyRewards, groupId = lotteryData.groupId, rareGoods = lotteryData.rareGoods}})
	end
end
--[[
特典蛋池按钮点击回调
--]]
function MurderMirrorMediator:ExCapsuleButtonCallback( sender )
	PlayAudioByClickNormal()
	local lotteryData = app.murderMgr:GetLotteryData()
	if lotteryData then
		app.router:Dispatch({name = 'MurderMirrorMediator'}, {name = 'activity.murder.MurderExCapsuleMediator', params = {groupId = lotteryData.groupId, drawnRewards = lotteryData.drawnRewards}})
	end
end
--[[
spine播放结束回调
--]]
function MurderMirrorMediator:MirrorSpineEndHandler( event )
	local viewData = self:GetViewComponent().viewData
	if event.animation == 'play1' or event.animation == 'play2' then
		self:GetViewComponent():performWithDelay(
			function ()
				local backCallback = function ()
					self:ChangeUIState(UIState.SHOW)
					self:CheckForUpdate()
				end
				-- 弹出领奖页面
				AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'}, {name = 'activity.murder.MurderCapsuleRewardMediator', params = {rewards = self.lotteryRewards, backCallback = backCallback}})
				-- 还原spine状态
				viewData.mirrorSpine:update(0)
				viewData.mirrorSpine:setToSetupPose()
				viewData.mirrorSpine:setAnimation(0, 'idle', true)
			end,
            (1 * cc.Director:getInstance():getAnimationInterval())
		)
	end
end
-------------------------------------------------
-- get /set

-------------------------------------------------
-- private method
--[[
进入
--]]
function MurderMirrorMediator:EnterLayer()
	self:SendSignal(POST.MURDER_LOTTERY_HOME.cmdName)
end
--[[
转换数据
--]]
function MurderMirrorMediator:ConvertLotteryData( homeData )
	local config = clone(CommonUtils.GetConfigAllMess('rewardPool', 'newSummerActivity'))
	local lotteryData = {}
	lotteryData.groupId = checkint(homeData.groupId)
	lotteryData.rareGoods = checktable(homeData.rareGoods)
	lotteryData.lotteryTimes = checkint(homeData.lotteryTimes)
	lotteryData.drawnRewards = checktable(homeData.rewards)
	lotteryData.round = checkint(homeData.round)
	lotteryData.dailyRewards = {}
	for i, v in orderedPairs(config) do
		if checkint(v.group) == checkint(homeData.groupId) then
			if lotteryData.drawnRewards[tostring(v.id)] then
				v.stock = checkint(v.num) - checkint(lotteryData.drawnRewards[tostring(v.id)])
			else
				v.stock = checkint(v.num)
			end
			table.insert(lotteryData.dailyRewards, v)
		end
	end
	app.murderMgr:SetLotteryData(lotteryData)
end
--[[
初始化页面
--]]
function MurderMirrorMediator:InitView()
	local view = self:GetViewComponent()
	local viewData = view:GetViewData()
	local moneyIdMap = {}
	local goodsId = app.murderMgr:GetLotteryGoodsId()
    moneyIdMap[tostring(goodsId)] = goodsId
	view:ReloadMoneyBar(moneyIdMap, false)
	-- 刷新剩余扭蛋数目
	viewData.numComponent:SetStartNumber(self:GetCapsuleLeftNum())
	-- 刷新今日特典扭蛋页面
	self:RefreshExCapsuleLayout()
	-- 刷新轮数
	viewData.turnLabel:setString(string.fmt(__('当前轮数: _num_'), {['_num_'] = checkint(app.murderMgr:GetLotteryData().round)}))
	-- 更新抽卡货币
	local lotteryGoodsId = app.murderMgr:GetLotteryGoodsId()
	viewData.drawOneCostIcon:setTexture(CommonUtils.GetGoodsIconPathById(lotteryGoodsId))
	viewData.drawTenCostIcon:setTexture(CommonUtils.GetGoodsIconPathById(lotteryGoodsId))
end
--[[
获取剩余扭蛋数量
--]]
function MurderMirrorMediator:GetCapsuleLeftNum()
	local lotteryData = app.murderMgr:GetLotteryData()
	local num = 0 
	for i, v in ipairs(lotteryData.dailyRewards) do
		num = num + checkint(v.stock)
	end
	return num 
end
--[[
获取扭蛋总数
--]]
function MurderMirrorMediator:GetCapsuleTotalNum()
	local lotteryData = app.murderMgr:GetLotteryData()
	local num = 0 
	for i, v in ipairs(lotteryData.dailyRewards) do
		num = num + checkint(v.num)
	end
	return num 
end
--[[
获取特殊扭蛋集合
--]]
function MurderMirrorMediator:GetExCapsuleRewards()
	local lotteryData = app.murderMgr:GetLotteryData()
	local exRewards = {}
	local temp = {}
	for i, v in ipairs(lotteryData.dailyRewards) do
		if checkint(v.isRare) > 0 then
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
刷新特典扭蛋页面
--]]
function MurderMirrorMediator:RefreshExCapsuleLayout()
	local viewData = self:GetViewComponent():GetViewData()
	local exCapsuleView = viewData and viewData.exCapsuleView or nil
	if exCapsuleView then
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
					local icon = display.newImageView(app.murderMgr:GetResPath('ui/common/raid_room_ico_ready.png'), goodsNode:getContentSize().width/2, goodsNode:getContentSize().height/2)
					goodsNode:addChild(icon, 10)
				end
				if i > 0 and i <= 2 then
					goodsNode:setPosition(cc.p(375 + (i - 3) * 90, 200))
				elseif i > 2 and i <= 5 then
					goodsNode:setPosition(cc.p(150 + (i - 3) * 90, 300))
				end
			end
		end
	end
end
--[[
改变剩余扭蛋数目
--]]
function MurderMirrorMediator:ChangeCapsuleLeftNum()
	local viewData = self:GetViewComponent():GetViewData()
	local leftNum = self:GetCapsuleLeftNum()
	viewData.numComponent:ChangeNumber(leftNum)
end
--[[
抽奖回调处理
--]]
function MurderMirrorMediator:CapsuleDraw( data )
	local lotteryData = app.murderMgr:GetLotteryData()
	-- 扣除道具
	CommonUtils.DrawRewards( {rewards = {goodsId = app.murderMgr:GetLotteryGoodsId(), num = -checkint(data.requestData.lotteryTimes)}})
	self:GetFacade():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI)
	local rewards = {} -- 奖励
	for k, time in pairs(data.rands) do
		-- 更新本地数据
		if lotteryData.drawnRewards[k] then
			lotteryData.drawnRewards[k] = lotteryData.drawnRewards[k] + checkint(time)
		else
			lotteryData.drawnRewards[k] = checkint(time)
		end
		for i, val in ipairs(lotteryData.dailyRewards) do
			if checkint(val.id) == checkint(k) then
				val.stock = val.stock - checkint(time)
				for i = 1, checkint(time) do
					local temp = clone(val.rewards[1])
					temp.isRare = val.isRare
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
				self:DrawOneAction()
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
改变抽卡界面UI状态
@params state UIState ui状态
--]]
function MurderMirrorMediator:ChangeUIState( state )
	local scene = app.uiMgr:GetCurrentScene()
	local viewData = self:GetViewComponent():GetViewData()
	local bottomLayout = viewData.bottomLayout
	local exCapsuleLayout = viewData.exCapsuleLayout
	local mirrorSpine = viewData.mirrorSpine
	if state == UIState.SHOW then
		-- scene:RemoveViewForNoTouch()
		bottomLayout:runAction(
			cc.Spawn:create(
				cc.FadeIn:create(0.4),
				cc.MoveTo:create(0.4, cc.p(bottomLayout:getPositionX(), 0))
			)
		)
		exCapsuleLayout:runAction(
			cc.Spawn:create{
				cc.FadeIn:create(0.4),
				cc.MoveTo:create(0.4, cc.p(80 + display.width - display.SAFE_L, exCapsuleLayout:getPositionY()))
			}
		)
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
		bottomLayout:runAction(
			cc.Spawn:create(
				cc.FadeOut:create(0.4),
				cc.MoveTo:create(0.4, cc.p(bottomLayout:getPositionX(), -viewData.bottomLayoutSize.height))
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
单抽动画
@params isRare bool 是否为稀有扭蛋
--]]
function MurderMirrorMediator:DrawOneAction(  )
	-- PlayAudioClip(AUDIOS.UI.ui_machine_one.id)
	PlayAudioByClickNormal()
	local viewData = self:GetViewComponent():GetViewData()
	viewData.mirrorSpine:update(0)
	viewData.mirrorSpine:setToSetupPose()
	viewData.mirrorSpine:setAnimation(0, 'play1', false)
end
--[[
十连动画
--]]
function MurderMirrorMediator:DrawTenAction()
	-- PlayAudioClip(AUDIOS.UI.ui_machine_ten.id)
	PlayAudioByClickNormal()
	local viewData = self:GetViewComponent():GetViewData()
	viewData.mirrorSpine:update(0)
	viewData.mirrorSpine:setToSetupPose()
	viewData.mirrorSpine:setAnimation(0, 'play2', false)
end
--[[
随机排序
--]]
function MurderMirrorMediator:RandSort( t )
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
检查是否需要更新界面
--]]
function MurderMirrorMediator:CheckForUpdate()
	if self:GetCapsuleLeftNum() == 0 then
		app.murderMgr:ShowMirrorRefreshTips()
		self:SendSignal(POST.MURDER_LOTTERY_HOME.cmdName)
	end
end
-------------------------------------------------
-- public method


return MurderMirrorMediator
