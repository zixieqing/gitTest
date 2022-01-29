--[[
 * author : liuzhipeng
 * descpt : type nameMediator
--]]
local AssemblyActivityTenPalaceMediator = class('AssemblyActivityTenPalaceMediator', mvc.Mediator)
local NAME = 'activity.assemblyActivity.AssemblyActivityTenPalaceMediator'
local PoolPreviewView = require('Game.views.drawCards.CapsulePoolPreviewView')
function AssemblyActivityTenPalaceMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    local args = checktable(params)
	self.activityId = args.activityId
	self.activityData = {}
	self.showDrawConfirm = false

	self.currentConsumeInfo = {goodsId = nil, goodsAmount = nil}
	self.tempDrawRewardsData = nil
end
-------------------------------------------------
------------------ inheritance ------------------
function AssemblyActivityTenPalaceMediator:InterestSignals()
    local signals = {
		------------ server ------------
		POST.ASSEMBLY_ACTIVITY_SQUARED_HOME.sglName,
		POST.ASSEMBLY_ACTIVITY_SQUARED_LUCKY.sglName,
		POST.ASSEMBLY_ACTIVITY_SQUARED_NEXT_ROUND.sglName,
		------------ local ------------
		'NINE_PALACE_DRAW_CARD',
		'NINE_PALACE_NEXT_ROUND',
		'BANDIT_ANIMATION_OVER',
		'NEXT_ROUND_ANIMATION_REFRESH',
		'NEXT_ROUND_ANIMATION_OVER',
		'SHOW_GOODS_DETAIL'
    }
    return signals
end
function AssemblyActivityTenPalaceMediator:ProcessSignal(signal)
	local name = signal:GetName()
	local responseData = signal:GetBody()

	------------ server ------------
    if POST.ASSEMBLY_ACTIVITY_SQUARED_HOME.sglName == name then
        self:resetHomeData(responseData)
	elseif POST.ASSEMBLY_ACTIVITY_SQUARED_LUCKY.sglName == name then

		local errcode = checkint(responseData.errcode)
		local activityId = nil
		if 0 ~= errcode then
			activityId = responseData.data.requestData.activityId
		else
			activityId = responseData.requestData.activityId
		end

		if self:IsSameActivity(activityId) then
			-- 抽卡回调
			self:DrawOneTimeCallback(responseData)
		end

	elseif POST.ASSEMBLY_ACTIVITY_SQUARED_NEXT_ROUND.sglName == name then

		local errcode = checkint(responseData.errcode)
		local activityId = nil
		if 0 ~= errcode then
			activityId = responseData.data.requestData.activityId
		else
			activityId = responseData.requestData.activityId
		end

		if self:IsSameActivity(activityId) then
			-- 下一轮回调
			self:EnterNextRoundCallback(responseData)
		end

	------------ local ------------
	else

		-- 本地信号 检查一次activityId
		if not self:IsSameActivity(responseData.activityId) then return end

		if 'NINE_PALACE_DRAW_CARD' == name then

			-- 抽卡按钮回调
			self:DrawOneTime()

		elseif 'NINE_PALACE_NEXT_ROUND' == name then

			-- 进入下一轮
			self:EnterNextRound()

		elseif 'BANDIT_ANIMATION_OVER' == name then

			-- 老虎机动画结束
			self:BanditAnimationOverCallback(responseData)

		elseif 'NEXT_ROUND_ANIMATION_OVER' == name then

			-- 进入下一轮动画结束
			self:EnterNextRoundAnimationOver()

		elseif 'NEXT_ROUND_ANIMATION_REFRESH' == name then

			-- 进入下一轮动画刷新界面
			self:EnterNextRoundAnimationRefresh()

		elseif 'SHOW_GOODS_DETAIL' == name then

			-- 进入下一轮动画结束
			self:ShowGoodsDetail(responseData)
		end

	end
end
function AssemblyActivityTenPalaceMediator:Initial(key)
	self.super.Initial(self, key)
	self:InitScene()
	self:GetViewComponent():setVisible(false)
end
function AssemblyActivityTenPalaceMediator:CleanupView()
	if self:GetViewComponent() then
		self:GetViewComponent():stopAllActions()
		self:GetViewComponent():runAction(cc.RemoveSelf:create())
		self:SetViewComponent(nil)
	end
end

function AssemblyActivityTenPalaceMediator:OnRegist()
    regPost(POST.ASSEMBLY_ACTIVITY_SQUARED_HOME)
    regPost(POST.ASSEMBLY_ACTIVITY_SQUARED_LUCKY)
    regPost(POST.ASSEMBLY_ACTIVITY_SQUARED_NEXT_ROUND)
    self:SetTouchEnable(true)
    self:EnterLayer()
end
function AssemblyActivityTenPalaceMediator:OnUnRegist()
    unregPost(POST.ASSEMBLY_ACTIVITY_SQUARED_HOME)
    unregPost(POST.ASSEMBLY_ACTIVITY_SQUARED_LUCKY)
    unregPost(POST.ASSEMBLY_ACTIVITY_SQUARED_NEXT_ROUND)
    -- 移除界面
    local scene = app.uiMgr:GetCurrentScene()
    scene:RemoveDialog(self:GetViewComponent())
end
--[[
刷新一次数据
@params activityData table 数据
--]]
function AssemblyActivityTenPalaceMediator:resetHomeData(activityData)
	self.activityData = activityData
	-- self.activityData = json.decode('{"data":{"currentRound":7,"totalRound":11,"goods":[{"squaredId":1,"goodsId":"900005","num":"1000","big":0,"hasDrawn":0},{"squaredId":2,"goodsId":"890021","num":"3","big":0,"hasDrawn":0},{"squaredId":3,"goodsId":"890006","num":"20","big":0,"hasDrawn":0},{"squaredId":4,"goodsId":"890006","num":"5","big":0,"hasDrawn":0},{"squaredId":5,"goodsId":"173001","num":"3","big":0,"hasDrawn":1},{"squaredId":6,"goodsId":"890002","num":"50","big":0,"hasDrawn":0},{"squaredId":7,"goodsId":"900003","num":"70","big":0,"hasDrawn":0},{"squaredId":8,"goodsId":"180001","num":"3","big":0,"hasDrawn":0},{"squaredId":9,"goodsId":880111,"num":3,"big":1,"hasDrawn":1}],"consume":[{"goodsId":880110,"type":88,"num":1},{"goodsId":900001,"type":90,"num":50}],"preview":[[890002],[880111],[190408],[880111],[250073],[890004],[880111],[260004],[890009],[880111],[250563]],"slaveView":"draw_probability_role_7"},"timestamp":1540546017,"errcode":0,"errmsg":"","rand":"5bd2dde14e58b1540546017","sign":"8d2c963588d9c3ee9b90d1c46c6a24f2"}').data
	self:InitValue()
	self:GetViewComponent():FixContentPosition()
	self:GetViewComponent():setVisible(true)
	-- 设置一次场景的活动id
    self:GetViewComponent():SetActivityId(self:GetActivityId())
    self:InitMoneyBar()
	self:RefreshScene()
end
------------------ inheritance ------------------
-------------------------------------------------

-------------------------------------------------
-------------------- handler --------------------
--[[
返回主界面
--]]
function AssemblyActivityTenPalaceMediator:BackButtonCallback( sender )
    PlayAudioByClickClose()
    app:UnRegsitMediator(NAME)
end
--[[
提示按钮点击回调
--]]
function AssemblyActivityTenPalaceMediator:TipsButtonCallback( sender )
    PlayAudioByClickNormal()
    app.uiMgr:ShowIntroPopup({moduleId = '-72'})
end
--[[
预览按钮点击回调
--]]
function AssemblyActivityTenPalaceMediator:PreviewButtonCallback( sender )
    PlayAudioByClickNormal()
    local activityData = self:GetActivityData()
    local cardPoolDatas = {
        preview      = activityData.preview,
        slaveView    = activityData.slaveView,
        activityType = ACTIVITY_TYPE.DRAW_NINE_GRID,
    }
    local poolView  = PoolPreviewView.new({cardPoolDatas = cardPoolDatas})
    app.uiMgr:GetCurrentScene():AddDialog(poolView)
end
-------------------- handler --------------------
-------------------------------------------------

-------------------------------------------------
--------------------- init ----------------------
--[[
初始化数据
--]]
function AssemblyActivityTenPalaceMediator:InitValue()
	-- 刷新一次当前消耗信息
	self:RefreshCurrentConsumeInfo()
end
--[[
初始化场景
--]]
function AssemblyActivityTenPalaceMediator:InitScene()
	local scene = require('Game.views.activity.assemblyActivity.AssemblyActivityTenPalaceView').new({
		activityId = checkint(self:GetActivityId())
    })
    app.uiMgr:GetCurrentScene():AddDialog(scene)
    self:SetViewComponent(scene)
    local viewData = scene.viewData
    viewData.backBtn:setOnClickScriptHandler(handler(self, self.BackButtonCallback))
    viewData.tabNameLabel:setOnClickScriptHandler(handler(self, self.TipsButtonCallback))
    viewData.previewBtn:setOnClickScriptHandler(handler(self, self.PreviewButtonCallback))
end
--------------------- init ----------------------
-------------------------------------------------

-------------------------------------------------
--------------------- logic ---------------------
--[[
初始化顶部货币栏
--]]
function AssemblyActivityTenPalaceMediator:InitMoneyBar()
    local activityData = self:GetActivityData()
    local viewComponent = self:GetViewComponent()
    local moneyIdMap = activityData.moneyIdMap
    viewComponent:InitMoneyBar(moneyIdMap)
end
--[[
刷新一次当前消耗信息
--]]
function AssemblyActivityTenPalaceMediator:RefreshCurrentConsumeInfo()
	local consumeList = self:GetActivityData().consume
	local goodsId = nil
	local goodsAmount = nil
	for i,v in ipairs(consumeList) do
		goodsId = checkint(v.goodsId)
		goodsAmount = checknumber(v.num)
		-- 判断本地道具是否足够
		local localGoodsAmount = app.gameMgr:GetAmountByIdForce(goodsId)
		if nil ~= localGoodsAmount and goodsAmount <= localGoodsAmount then
			self:SetCurrentConsumeGoodsInfo(goodsId, goodsAmount)
			return
		end
	end
	-- 全都不够 显示第一种货币
	self:SetCurrentConsumeGoodsInfo(checkint(consumeList[1].goodsId), checknumber(consumeList[1].num))
end
--[[
根据活动信息刷新场景
--]]
function AssemblyActivityTenPalaceMediator:RefreshScene()
	local activityData = self:GetActivityData()
	self:GetViewComponent():RefreshUI(
		self:GetCurrentRound(),
		self:GetTotalRound(),
		activityData.goods,
		self:GetCurrentConsumeGoodsInfo()
	)
end
--[[
抽卡按钮回调
--]]
function AssemblyActivityTenPalaceMediator:DrawOneTime()
	local activityData = self:GetActivityData()

	-- 判断还有没有奖品能抽
	local hasRewards = false
	for i,v in ipairs(activityData.goods) do
		if 0 == checkint(v.hasDrawn) then
			hasRewards = true
			break
		end
	end

	if not hasRewards then
		app.uiMgr:ShowInformationTips(__('已经抽到所有奖品了，可进入下一轮继续抽奖。'))
		return
	end

	-- 检查消耗道具是否满足抽卡条件
	local costGoodsId, costGoodsAmount = self:GetCurrentConsumeGoodsInfo()
	local localGoodsAmount = app.gameMgr:GetAmountByIdForce(costGoodsId)
	if nil == localGoodsAmount or costGoodsAmount > localGoodsAmount then
		local goodsConfig = CommonUtils.GetConfig('goods', 'goods', costGoodsId)
		local goodsName = goodsConfig.name
		if GAME_MODULE_OPEN.NEW_STORE and checkint(costGoodsId) == DIAMOND_ID then
			app.uiMgr:showDiamonTips()
		else
			app.uiMgr:ShowInformationTips(string.format(__('%s不足!!!'), goodsName))
		end
		return
	end

	-- 第一次抽弹个确认框
	if self:GetShowDrawConfirm() then
		local goodsConf = CommonUtils.GetConfig('goods', 'goods', costGoodsId) or {}
		local goodsName = tostring(goodsConf.name)
		local layer = require('common.CommonTip').new({
			text = __('是否确定抽奖？'),
			descr = string.fmt(__('本次抽奖会消耗_num_个_name_'), {_name_ = goodsName, _num_ = costGoodsAmount}),
			callback = function (sender)
				self:SetShowDrawConfirm(false)
				self:GoDrawOneTime()
			end
		})
		layer:setPosition(display.center)
		app.uiMgr:GetCurrentScene():AddDialog(layer)
	else
		self:GoDrawOneTime()
	end
end
--[[
抽卡
--]]
function AssemblyActivityTenPalaceMediator:GoDrawOneTime()
	-- 道具足够 请求服务器抽卡
	self:SetTempDrawRewardsData(nil)
	self:SendSignal(POST.ASSEMBLY_ACTIVITY_SQUARED_LUCKY.cmdName, {activityId = self:GetActivityId()})
end
--[[
抽卡请求回调
@params responseData list 服务器返回信息 {
	squaredId int 道具唯一id
	goodsId int 道具id
	num int 道具id
}
--]]
function AssemblyActivityTenPalaceMediator:DrawOneTimeCallback(responseData)
	local errcode = checkint(responseData.errcode)
	if 0 ~= errcode then
		-- 请求挂了 恢复触摸
		self:SetTouchEnable(true)
		return
	end

	self:SetTouchEnable(false)

	self:SetTempDrawRewardsData(responseData)

	------------ 先扣除消耗 ------------
	local costGoodsId, costGoodsAmount = self:GetCurrentConsumeGoodsInfo()
	if costGoodsId then
		CommonUtils.DrawRewards({
			{goodsId = costGoodsId, num = -1 * costGoodsAmount}
		})
	end
	------------ 先扣除消耗 ------------
	self:GetViewComponent():DoDrawOneTime(checkint(responseData.rewards[1].squaredId))
end
--[[
老虎机动画结束
@params table {
	squaredId int 奖品唯一id
}
--]]
function AssemblyActivityTenPalaceMediator:BanditAnimationOverCallback(params)
	local rewardsData = self:GetTempDrawRewardsData()

	-- 弹奖励
	self:DrawBanditRewards(rewardsData.rewards)

	-- 刷新一次消耗货币
	self:RefreshCurrentConsumeInfo()

	-- 刷新本地数据
	self:UpdateLocalHomeData(rewardsData.rewards)

	------------ 强刷一次钻石 ------------
	if nil ~= rewardsData.diamond then
		local finalDiamond = checkint(rewardsData.diamond)
		local deltaDiamond = finalDiamond - app.gameMgr:GetAmountByIdForce(DIAMOND_ID)
		if 0 ~= deltaDiamond then
			CommonUtils.DrawRewards({
				{goodsId = DIAMOND_ID, num = deltaDiamond}
			})
		end
	end
	------------ 强刷一次钻石 ------------

	self:SetTempDrawRewardsData(nil)

	local activityData = self:GetActivityData()

	------------ 刷新界面 ------------
	self:RefreshScene()
	------------ 刷新界面 ------------

	self:SetTouchEnable(true)
end
--[[
领取获得的奖励
@params rewardsData list 奖励信息
--]]
function AssemblyActivityTenPalaceMediator:DrawBanditRewards(rewardsData)
	-- local popupRewards = {}

	-- for _, rewardData in ipairs(rewardsData) do
	-- 	local goodsType = CommonUtils.GetGoodTypeById(checkint(rewardData.goodsId))
	-- 	if GoodsType.TYPE_CARD == goodsType then

	-- 		-- 抽到卡


	-- 	elseif GoodsType.TYPE_CARD_SKIN == goodsType then

	-- 		-- 抽到卡牌皮肤
	-- 		local tag = 1067
	-- 		local goodsLayer = require('common.CommonCardGoodsShareView').new({
	-- 			goodsId = checkint(rewardData.goodsId),
	-- 			confirmCallback = function (sender)
	-- 				app.uiMgr:GetCurrentScene():RemoveDialogByTag(tag)
	-- 			end
	-- 		})
	-- 		display.commonUIParams(goodsLayer, {ap = cc.p(0.5, 0.5), po = display.center})
	-- 		goodsLayer:setTag(tag)
	-- 		app.uiMgr:GetCurrentScene():AddDialog(goodsLayer)

	-- 		-- 皮肤直接更新数据
	-- 		CommonUtils.DrawRewards({
	-- 			rewardData
	-- 		})

	-- 	else

	-- 		-- 抽到其他道具
	-- 		table.insert(popupRewards, rewardData)

	-- 	end
	-- end

	-- 更新奖励的道具
	app.uiMgr:AddDialog('common.RewardPopup', {
		rewards = rewardsData
	})
end
--[[
抽卡结束刷新本地数据
@params rewardsData
--]]
function AssemblyActivityTenPalaceMediator:UpdateLocalHomeData(rewardsData)
	if nil ~= rewardsData then
		for _, rewardData in ipairs(rewardsData) do
			self:UpdateRewardDrawStateBySquareId(checkint(rewardData.squaredId), 1)
		end
	end
end
--[[
进入下一轮
--]]
function AssemblyActivityTenPalaceMediator:EnterNextRound()
	-- 检查是否能进入下一轮
	local activityData = self:GetActivityData()
	if activityData.currentRound >= self:GetTotalRound() then
		app.uiMgr:ShowInformationTips(__('已经没有下一轮了!!!'))
		return
	end

	local getBigReward = self:HasGotBigReward()
	if not getBigReward then
		app.uiMgr:ShowInformationTips(__('需要抽中大奖或抽到所有奖品才可进入下一轮!!!'))
		return
	end

	-- 可以进入下一轮
	local layer = require('common.CommonTip').new({
		text = __('确定进入下一轮?'),
		descr = __('进入下一轮后当前未获取的奖励无法获得。'),
		callback = function (sender)
			self:SendSignal(POST.ASSEMBLY_ACTIVITY_SQUARED_NEXT_ROUND.cmdName, {activityId = self:GetActivityId()})
			-- self:EnterNextRoundCallback()
		end
	})
	layer:setPosition(display.center)
	app.uiMgr:GetCurrentScene():AddDialog(layer)
end
--[[
进入下一轮回调
@params responseData list 服务器返回信息
--]]
function AssemblyActivityTenPalaceMediator:EnterNextRoundCallback(responseData)
	local errcode = checkint(responseData.errcode)
	if 0 ~= errcode then
		-- 请求挂了 恢复触摸
		self:SetTouchEnable(true)
		return
	end

	self:SetTouchEnable(false)

	-- 更新奖品信息
	self:UpdateRewardsData(responseData.goods)
	-- 更新当前波数
	self:SetCurrentRound(self:GetCurrentRound() + 1)

	------------ 刷新界面 ------------
	-- 进入下一波动画
	self:GetViewComponent():DoEnterNextRound()
	------------ 刷新界面 ------------
end
--[[
进入下一轮动画刷新
--]]
function AssemblyActivityTenPalaceMediator:EnterNextRoundAnimationRefresh()
	------------ 刷新界面 ------------
	self:RefreshScene()
	------------ 刷新界面 ------------
end
--[[
进入下一轮动画结束
--]]
function AssemblyActivityTenPalaceMediator:EnterNextRoundAnimationOver()
	self:SetTouchEnable(true)
end
--[[
显示道具详情
@params data table {
	goodsId int 道具id
}
--]]
function AssemblyActivityTenPalaceMediator:ShowGoodsDetail(data)
	local goodsId = checkint(data.goodsId)
	local targetNode = data.targetNode
	local goodsType = CommonUtils.GetGoodTypeById(goodsId)
	if GoodsType.TYPE_CARD == goodsType then

		-- 显示卡牌预览
		local layer = require('common.CardPreviewView').new({
			cardId = goodsId,
			skinId = CardUtils.GetCardSkinId(goodsId),
			cardDrawChangeType = 1
		})
		display.commonUIParams(layer, {ap = display.CENTER, po = cc.p(display.cx, display.cy)})
		app.uiMgr:GetCurrentScene():AddDialog(layer)

	elseif GoodsType.TYPE_CARD_SKIN == goodsType then

		-- 显示皮肤预览
		local layer = require('common.CommonCardGoodsDetailView').new({
			goodsId = goodsId
		})
		display.commonUIParams(layer, {ap = display.CENTER, po = cc.p(display.cx, display.cy)})
		app.uiMgr:GetCurrentScene():AddDialog(layer)

	else
		app.uiMgr:ShowInformationTipsBoard({
			targetNode = targetNode,
			type = 1,
			iconId = goodsId
		})
	end
end
--------------------- logic ---------------------
-------------------------------------------------

--------------------------------------------------
-------------------- control ---------------------
--[[
设置全屏不可点击
@params enable bool 是否可以点击
--]]
function AssemblyActivityTenPalaceMediator:SetTouchEnable(enable)
if not self:GetViewComponent() then return end
local currentScene = app.uiMgr:GetCurrentScene()
if not enable then
    currentScene:AddViewForNoTouch()
else
    currentScene:RemoveViewForNoTouch()
end
end
--------------------- control --------------------
--------------------------------------------------




-------------------------------------------------
-------------------- private --------------------
--[[
进入页面
--]]
function AssemblyActivityTenPalaceMediator:EnterLayer()
    self:SendSignal(POST.ASSEMBLY_ACTIVITY_SQUARED_HOME.cmdName, {activityId = self.activityId})
end
-------------------- private --------------------
-------------------------------------------------

-------------------------------------------------
------------------- get / set -------------------
--[[
获取活动id
--]]
function AssemblyActivityTenPalaceMediator:GetActivityId()
	return self.activityId
end
--[[
获取卡池信息
--]]
function AssemblyActivityTenPalaceMediator:GetActivityData()
	return self.activityData
end
--[[
获取当前波数
--]]
function AssemblyActivityTenPalaceMediator:GetCurrentRound()
	return self:GetActivityData().currentRound
end
function AssemblyActivityTenPalaceMediator:SetCurrentRound(round)
	self:GetActivityData().currentRound = math.min(round, self:GetTotalRound())
end
--[[
获取总轮数
--]]
function AssemblyActivityTenPalaceMediator:GetTotalRound()
	return #self:GetActivityData().preview
end
--[[
设置临时的奖品信息
--]]
function AssemblyActivityTenPalaceMediator:SetTempDrawRewardsData(rewardsData)
	self.tempDrawRewardsData = rewardsData
end
function AssemblyActivityTenPalaceMediator:GetTempDrawRewardsData()
	return self.tempDrawRewardsData
end
--[[
设置抽卡消耗
@params goodsId, goodsAmount int, int 道具id, 道具数量
--]]
function AssemblyActivityTenPalaceMediator:SetCurrentConsumeGoodsInfo(goodsId, goodsAmount)
	self.currentConsumeInfo.goodsId = goodsId
	self.currentConsumeInfo.goodsAmount = goodsAmount
end
--[[
获取抽卡消耗
@return goodsId, goodsAmount int, int 道具id, 道具数量
--]]
function AssemblyActivityTenPalaceMediator:GetCurrentConsumeGoodsInfo()
	return self.currentConsumeInfo.goodsId, self.currentConsumeInfo.goodsAmount
end
--[[
是否已经获取大奖
@return _ bool
--]]
function AssemblyActivityTenPalaceMediator:HasGotBigReward()
	for i,v in ipairs(self:GetActivityData().goods) do
		if 1 == checkint(v.big) and 1 == checkint(v.hasDrawn) then
			return true
		end
	end
	return false
end
--[[
根据奖品唯一id获取奖品信息
@params squaredId int 奖品唯一id
@return _ map reward data
--]]
function AssemblyActivityTenPalaceMediator:GetDrawRewardDataBySquaredId(squaredId)
	local rewardsData = self:GetTempDrawRewardsData()
	if nil ~= rewardsData then
		for _, rewardData in ipairs(rewardsData.rewards) do
			if squaredId == checkint(rewardData.squaredId) then
				return rewardData
			end
		end
	end
	return nil
end
--[[
刷新奖品的领取状态
@params squaredId int 奖品唯一id
@params hasDrawn int 1:已领取 0:未领取
--]]
function AssemblyActivityTenPalaceMediator:UpdateRewardDrawStateBySquareId(squaredId, hasDrawn)
	for _, rewardData in ipairs(self:GetActivityData().goods) do
		if squaredId == checkint(rewardData.squaredId) then
			rewardData.hasDrawn = hasDrawn
			break
		end
	end
end
--[[
更新卡池奖品信息
@params rewards list 卡池奖品信息
--]]
function AssemblyActivityTenPalaceMediator:UpdateRewardsData(rewards)
	self.activityData.goods = rewards
end
--[[
获取是否要弹抽卡确认框
--]]
function AssemblyActivityTenPalaceMediator:GetShowDrawConfirm()
	return self.showDrawConfirm
end
function AssemblyActivityTenPalaceMediator:SetShowDrawConfirm(show)
	self.showDrawConfirm = show
end
--[[
判断是否是本mediator的信号
@params targetActivityId int 信号的活动id
--]]
function AssemblyActivityTenPalaceMediator:IsSameActivity(targetActivityId)
	return checkint(targetActivityId) == checkint(self:GetActivityId())
end
------------------- get / set -------------------
-------------------------------------------------
return AssemblyActivityTenPalaceMediator