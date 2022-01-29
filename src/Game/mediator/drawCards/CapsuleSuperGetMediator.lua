--[[
超得抽卡
@params {
	ownerNode cc.node 父节点
	activityId int 活动id
	activityData map 卡池数据
}
--]]
local Mediator = mvc.Mediator
local CapsuleSuperGetMediator = class("CapsuleSuperGetMediator", Mediator)
local NAME = "CapsuleSuperGetMediator"

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

--[[
constructor
--]]
function CapsuleSuperGetMediator:ctor(params, viewComponent)
	Mediator.ctor(self, NAME, viewComponent)

	self.activityId = params.activityId
	self.activityData = params.activityData
	self.parentNode = params.ownerNode
	self.currentConsumeInfo = nil

	self.showDrawConfirm = false
end

---------------------------------------------------
-- mediator extend begin --
---------------------------------------------------
function CapsuleSuperGetMediator:InterestSignals()
	local signals = {
		------------ server ------------
		POST.GAMBLING_SUPER_LUCKY.sglName,
		------------ local ------------
		'SUPER_GET_DRAW'
	}

	return signals
end
function CapsuleSuperGetMediator:ProcessSignal(signal)
	local name = signal:GetName()
	local responseData = signal:GetBody()

	if POST.GAMBLING_SUPER_LUCKY.sglName == name then
		AppFacade.GetInstance():DispatchObservers("DOT_LOG_EVENT_SEND" , {eventId = "1004-M4-01"})
		-- 抽的回调
		if self:IsSameActivity(responseData.requestData.activityId) then
			-- 抽卡回调
			self:DrawOneTimeCallback(responseData)
		end

	else

		-- 本地信号 检查一次activityId
		if not self:IsSameActivity(responseData.activityId) then return end

		if 'SUPER_GET_DRAW' == name then

			-- 抽
			self:DrawOneTime(checkint(responseData.poolId))

		end

	end

end
function CapsuleSuperGetMediator:Initial(key)
	self.super.Initial(self, key)
	-- 初始化场景
	self:InitScene()
	self:GetViewComponent():setVisible(false)
end
function CapsuleSuperGetMediator:CleanupView()
	if self:GetViewComponent() then
		self:GetViewComponent():stopAllActions()
		self:GetViewComponent():runAction(cc.RemoveSelf:create())
		self:SetViewComponent(nil)
	end
end
function CapsuleSuperGetMediator:OnRegist()
	-- 注册信号
	regPost(POST.GAMBLING_SUPER_LUCKY)
end
function CapsuleSuperGetMediator:OnUnRegist()
	unregPost(POST.GAMBLING_SUPER_LUCKY)
end
--[[
刷新一次数据
@params activityData table 数据
@params activityId int 活动id
--]]
function CapsuleSuperGetMediator:resetHomeData(activityData, activityId)
	self.activityData = activityData
	self.activityId = activityId
	self:InitValue()

	-- 设置一次场景的活动id
	self:GetViewComponent():SetActivityId(self:GetActivityId())

	-- 刷新场景
	self:RefreshScene()

	self:GetViewComponent():setVisible(true)
end
---------------------------------------------------
-- mediator extend end --
---------------------------------------------------

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化数据
--]]
function CapsuleSuperGetMediator:InitValue()
	-- 刷新一次当前消耗信息
	self:RefreshCurrentConsumeInfo()
end
--[[
初始化场景
--]]
function CapsuleSuperGetMediator:InitScene()
	local scene = require('Game.views.drawCards.CapsuleSuperGetView').new({
		parentNode = self:GetParentNode(),
		activityId = checkint(self:GetActivityId())
	})
	display.commonUIParams(scene, {ap = cc.p(0.5, 0.5), po = utils.getLocalCenter(self:GetParentNode())})
	self:GetParentNode():addChild(scene)

	self:SetViewComponent(scene)
end
--[[
刷新一次卡池消耗信息
--]]
function CapsuleSuperGetMediator:RefreshCurrentConsumeInfo()
	local consumeInfo = {}
	for poolIndex, poolData in ipairs(self:GetActivityData().pool) do

		local poolId = checkint(poolData.poolId)
		local costGoodsId, costGoodsAmount = nil, nil

		for _, consumeInfo_ in ipairs(poolData.consume) do
			local costGoodsId_ = checkint(consumeInfo_.goodsId)
			local costGoodsAmount_ = checkint(consumeInfo_.num)
			local localGoodsAmount = app.gameMgr:GetAmountByIdForce(localGoodsAmount)

			if nil ~= localGoodsAmount and costGoodsAmount_ <= localGoodsAmount then
				costGoodsId = costGoodsId_
				costGoodsAmount = costGoodsAmount_
				break
			end
		end

		if nil == costGoodsId then
			-- 如果全都不够 默认取第一种消耗
			costGoodsId = checkint(poolData.consume[1].goodsId)
			costGoodsAmount = checkint(poolData.consume[1].num)
		end

		consumeInfo[tostring(poolId)] = {goodsId = costGoodsId, goodsAmount = costGoodsAmount}

	end

	self:SetCurrentConsumeInfo(consumeInfo)
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- logic begin --
---------------------------------------------------
--[[
抽卡
@params poolId int 卡池id
--]]
function CapsuleSuperGetMediator:DrawOneTime(poolId)
	-- 检查消耗是否够
	local consumeInfo = self:GetCurrentConsumeInfoByPoolId(poolId)
	if nil ~= consumeInfo then
		local costGoodsId = checkint(consumeInfo.goodsId)
		local costGoodsAmount = checknumber(consumeInfo.goodsAmount)
		local localGoodsAmount = app.gameMgr:GetAmountByIdForce(costGoodsId)
		if nil == localGoodsAmount or costGoodsAmount > localGoodsAmount then
			if GAME_MODULE_OPEN.NEW_STORE and checkint(costGoodsId) == DIAMOND_ID then
				app.uiMgr:showDiamonTips()
			else
				-- 道具不足
				app.capsuleMgr:ShowGoodsShortageTips(costGoodsId)
			end
			return
		end
	end

	-- 第一次抽弹个确认框
	if self:GetShowDrawConfirm() then
		local goodData = CommonUtils.GetConfig('goods', 'goods', consumeInfo.goodsId)
		local layer = require('common.CommonTip').new({
			text = __('是否确定抽奖？'),
			descr = string.fmt(__('抽奖会消耗_capsule_super_get_item_'), {_capsule_super_get_item_ = goodData.name}),
			callback = function (sender)
				self:SetShowDrawConfirm(false)
				self:GoDrawOneTime(poolId)
			end
		})
		layer:setPosition(display.center)
		app.uiMgr:GetCurrentScene():AddDialog(layer)
	else
		self:GoDrawOneTime(poolId)
	end
end
--[[
抽卡
--]]
function CapsuleSuperGetMediator:GoDrawOneTime(poolId)
	-- 道具足够 请求服务器抽卡
	self:SendSignal(POST.GAMBLING_SUPER_LUCKY.cmdName, {activityId = self:GetActivityId(), poolId = poolId})
end
--[[
抽卡回调
@params responseData list 服务器返回信息
--]]
function CapsuleSuperGetMediator:DrawOneTimeCallback(responseData)
	local poolId = checkint(responseData.requestData and responseData.requestData.poolId)
	------------ 扣除消耗 ------------
	local consumeInfo = self:GetCurrentConsumeInfoByPoolId(poolId)
	if nil ~= consumeInfo then
		local costGoodsId = checkint(consumeInfo.goodsId)
		local costGoodsAmount = checknumber(consumeInfo.goodsAmount)
		CommonUtils.DrawRewards({
			{goodsId = costGoodsId, num = -1 * costGoodsAmount}
		})
		self:GetFacade():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI)
	end
	------------ 扣除消耗 ------------

	-- local rewardsData = {}
	-- if nil ~= responseData.rewards then
	-- 	for i,v in ipairs(responseData.rewards) do
	-- 		table.insert(rewardsData, v)
	-- 	end
	-- end

	-- if nil ~= responseData.activityRewards then
	-- 	for i,v in ipairs(responseData.activityRewards) do
	-- 		table.insert(rewardsData, v)
	-- 	end
	-- end

	-- -- 弹奖励
	-- self:DrawRewards(rewardsData)
	-- 奖励动画
    local mediator = require("Game.mediator.drawCards.CapsuleAnimateMediator").new(responseData)
    AppFacade.GetInstance():RegistMediator(mediator)

	-- 刷新一次消耗货币
	self:RefreshCurrentConsumeInfo()

	-- 强刷一次界面
	------------ 刷新界面 ------------
	self:RefreshScene()
	------------ 刷新界面 ------------
end
--[[
领取获得的奖励
@params rewardsData list 奖励信息
--]]
function CapsuleSuperGetMediator:DrawRewards(rewardsData)
	-- 更新奖励的道具
	app.uiMgr:AddDialog('common.RewardPopup', {
		rewards = rewardsData
	})
end
---------------------------------------------------
-- logic end --
---------------------------------------------------

---------------------------------------------------
-- view control begin --
---------------------------------------------------
--[[
刷新场景
--]]
function CapsuleSuperGetMediator:RefreshScene()
	self:GetViewComponent():RefreshUI(self:GetActivityData().pool, self:GetCurrentConsumeInfo())
end
---------------------------------------------------
-- view control end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
获取活动id
--]]
function CapsuleSuperGetMediator:GetActivityId()
	return self.activityId
end
--[[
获取卡池信息
--]]
function CapsuleSuperGetMediator:GetActivityData()
	return self.activityData
end
--[[
获取传入的父节点
--]]
function CapsuleSuperGetMediator:GetParentNode()
	return self.parentNode
end
--[[
当前的消耗信息
@params consumeInfo map
--]]
function CapsuleSuperGetMediator:GetCurrentConsumeInfo()
	return self.currentConsumeInfo
end
function CapsuleSuperGetMediator:SetCurrentConsumeInfo(consumeInfo)
	self.currentConsumeInfo = consumeInfo
end
--[[
根据卡池获取当前的消耗信息
@params poolId int 卡池id
--]]
function CapsuleSuperGetMediator:GetCurrentConsumeInfoByPoolId(poolId)
	return self:GetCurrentConsumeInfo()[tostring(poolId)]
end
--[[
获取是否要弹抽卡确认框
--]]
function CapsuleSuperGetMediator:GetShowDrawConfirm()
	return self.showDrawConfirm
end
function CapsuleSuperGetMediator:SetShowDrawConfirm(show)
	self.showDrawConfirm = show
end
--[[
判断是否是本mediator的信号
@params targetActivityId int 信号的活动id
--]]
function CapsuleSuperGetMediator:IsSameActivity(targetActivityId)
	return checkint(targetActivityId) == checkint(self:GetActivityId())
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return CapsuleSuperGetMediator
