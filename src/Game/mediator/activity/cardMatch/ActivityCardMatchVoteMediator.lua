--[[
飨灵投票初赛投票mediator
--]]
local Mediator = mvc.Mediator
local ActivityCardMatchVoteMediator = class("ActivityCardMatchVoteMediator", Mediator)
local NAME = "activity.cardMatch.ActivityCardMatchVoteMediator"

local app     = app
local uiMgr   = app.uiMgr
local gameMgr = app.gameMgr

function ActivityCardMatchVoteMediator:ctor( params, viewComponent )
	self.super:ctor(NAME, viewComponent)
	local datas = params or {}
	self.activityId      = checkint(checktable(datas.requestData).activityId) -- 活动Id
	self.activityDatas   = datas
	self.datas           = {}
	self.isControllable_ = true
	self.isTimeEnd       = false

end

function ActivityCardMatchVoteMediator:InterestSignals()
	local signals = {
		POST.FOOD_VOTE_RANK.sglName,
		POST.FOOD_VOTE_VOTE.sglName,
		COUNT_DOWN_ACTION
	}
	return signals
end

function ActivityCardMatchVoteMediator:ProcessSignal( signal )
	local name = signal:GetName()
	local body = checktable(signal:GetBody())
	if name == POST.FOOD_VOTE_RANK.sglName then
		local result =  body.result or {}
		self:InitData_(result)
		self:GetViewComponent():UpdateGridView(self:GetViewData(), self.activityDatas)
	elseif name == POST.FOOD_VOTE_VOTE.sglName then

		local view = self:GetOwnerScene():GetDialogByTag(5001)
		if view then
			view:setVisible(false)
			view:runAction(cc.RemoveSelf:create())--兑换详情弹出框
		end

		local rewards = body.rewards or {}
		if next(rewards) then
			self.activityDatas.hasPrize = 1
			self:GetViewComponent():UpdateRewardsLayer(self:GetViewData(), self.activityDatas)
			uiMgr:AddDialog('common.RewardPopup', {rewards = rewards})
		end

		-- 更新投票券数量
		local viewComponent = self:GetViewComponent()
		local viewData = self:GetViewData()
		local requestData = body.requestData or {}
		CommonUtils.DrawRewards({{goodsId = requestData.goodsId, num = -requestData.num}})
		viewComponent:UpdateVoteTicket(viewData, self.activityDatas)

		-- 每日领取投票奖励所需次数
		self.activityDatas.times = checkint(body.times)
		viewComponent:UpdateRewardsDrawTimes(viewData, self.activityDatas)

		self:EnterLayer()

	elseif name == COUNT_DOWN_ACTION then
		local timerName = body.timerName
		if timerName == "activity.cardMatch.ActivityCardMatchPageMediator" then
			local countdown = body.countdown
			if countdown <= 0 then
				self.isTimeEnd = true
			end
		end
	end
end

function ActivityCardMatchVoteMediator:Initial( key )
    self.super.Initial(self, key)
    
	local viewComponent = require( 'Game.views.activity.cardMatch.ActivityCardMatchVoteView' ).new()
	display.commonUIParams(viewComponent, {ap = display.CENTER, po = display.center})
	self:SetViewComponent(viewComponent)
	self.ownerScene_ = uiMgr:GetCurrentScene()
    self:GetOwnerScene():AddDialog(viewComponent)

	self.viewData_ = viewComponent:GetViewData()
	self:InitView_()
end

function ActivityCardMatchVoteMediator:cleanupView()
	local viewComponent = self:GetViewComponent()
    if self.ownerScene_ and viewComponent and not tolua.isnull(viewComponent) then
		self.ownerScene_:RemoveGameLayer(viewComponent)
		self.ownerScene_ = nil
    end
end

function ActivityCardMatchVoteMediator:OnRegist(  )
	regPost(POST.FOOD_VOTE_RANK)
	regPost(POST.FOOD_VOTE_VOTE)
	self:EnterLayer()
end

function ActivityCardMatchVoteMediator:OnUnRegist(  )
	unregPost(POST.FOOD_VOTE_RANK)
	unregPost(POST.FOOD_VOTE_VOTE)
	self:cleanupView()
end

-------------------------------------------------
-- private method

function ActivityCardMatchVoteMediator:InitData_(result)
	local datas = {}
	for i, v in ipairs(result) do
		datas[tostring(v.playerId)] = v
	end

	self.datas = datas

	if next(datas) == nil then return end

	local cards = self.activityDatas.cards or {}

	local getPriority = function (data)
		local rank = checkint(data.rank)
		return rank == 0 and 999999 or rank
	end

	table.sort(cards, function(a, b)
		local aData = datas[tostring(a)] or {}
		local bData = datas[tostring(b)] or {}

		local aPriority = getPriority(aData)
		local bPriority = getPriority(bData)
		local aScore = checkint(aData.score)
		local bScore = checkint(bData.score)
		if aPriority ~= bPriority then
			return aPriority < bPriority
		elseif aScore ~= bScore then
			return aScore > bScore
		end
		return checkint(a) < checkint(b)
	end)
end

function ActivityCardMatchVoteMediator:InitView_()
	local viewData  = self:GetViewData()
	display.commonUIParams(viewData.blockLayer, {cb = handler(self, self.OnClickBlockLayerAction), animate = false})
	display.commonUIParams(viewData.refreshBtn, {cb = handler(self, self.OnClickRefreshBtnAction)})

	viewData.gridView:setDataSourceAdapterScriptHandler(handler(self, self.OnDataSourceAdapter))

	local viewComponent = self:GetViewComponent()
	viewComponent:UpdateRewardsDrawTimes(viewData, self.activityDatas)
	viewComponent:UpdateRewardsLayer(viewData, self.activityDatas)
	viewComponent:UpdateVoteTicket(viewData, self.activityDatas)
end

function ActivityCardMatchVoteMediator:OnDataSourceAdapter(p_convertview, idx)
	local pCell = p_convertview
    local index = idx + 1

	local viewComponent = self:GetViewComponent()

	if pCell == nil then
		local gridView = self:GetViewData().gridView
        pCell = viewComponent:CreateCell(gridView:getSizeOfCell())
        
        display.commonUIParams(pCell.viewData.voteBtn, {cb = handler(self, self.OnClickVoteBtnAction)})
    end

	local cards = self.activityDatas.cards
	local cardId = cards[index]
	local data = self.datas[tostring(cardId)]
	viewComponent:UpdateCell(pCell.viewData, data, cardId)
	
	pCell.viewData.voteBtn:setTag(index)
    
	return pCell
end

-------------------------------------------------
-- public method

function ActivityCardMatchVoteMediator:EnterLayer()
	 self:SendSignal(POST.FOOD_VOTE_RANK.cmdName, {activityId = self.activityId})
end

-------------------------------------------------
-- get / set
function ActivityCardMatchVoteMediator:GetViewData()
	return self.viewData_
end

function ActivityCardMatchVoteMediator:GetOwnerScene()
	return self.ownerScene_
end

-------------------------------------------------
-- handler

---OnClickVoteBtnAction
---投票按钮点击事件
---@param sender userdata 投票按钮
function ActivityCardMatchVoteMediator:OnClickVoteBtnAction(sender)
	local index = sender:getTag()
	local activityDatas = self.activityDatas
	local voteGoodsId = activityDatas.voteGoodsId
	local ownVoteGoodsNum = CommonUtils.GetCacheProductNum(voteGoodsId)
	local cards = self.activityDatas.cards
	local cardId = cards[index]
	local data = {consumeNum = 1, goodsId = voteGoodsId, cardId = cardId, rankData = self.datas[tostring(cardId)]}
	local popupView = require( 'Game.views.activity.cardMatch.ActivityCardMatchVotePopup' ).new({
		tag = 5001,
		maxSelectNum = math.max(0, ownVoteGoodsNum),
		mediatorName = NAME,
		data = data,
	})
	display.commonUIParams(popupView, {ap = display.CENTER, po = display.center})
	popupView:setTag(5001)
	self:GetOwnerScene():AddDialog(popupView)

	local purchaseBtn = popupView:GetViewData().purchaseBtn
	display.commonUIParams(purchaseBtn, {cb = handler(self, self.OnClickVoteBtnAction_)})
	purchaseBtn:setTag(index)
end

function ActivityCardMatchVoteMediator:OnClickVoteBtnAction_(sender)
	local index    = sender:getTag()
	local num      = sender:getUserTag()
	local cards = self.activityDatas.cards
	local cardId = cards[index]
	local voteGoodsId = self.activityDatas.voteGoodsId
	local ownVoteGoodsNum = CommonUtils.GetCacheProductNum(voteGoodsId)
	if ownVoteGoodsNum < num then
		local goodsConf = CommonUtils.GetConfig('goods', 'goods', voteGoodsId)
		uiMgr:ShowInformationTips(string.format(__('%s不足'), tostring(goodsConf.name)))
		return
	end

	self:SendSignal(POST.FOOD_VOTE_VOTE.cmdName, {
		activityId = self.activityId,
		goodsId = voteGoodsId,
		cardId = cardId,
		num = num,
	    index = index
	})

end

function ActivityCardMatchVoteMediator:OnClickBlockLayerAction(sender)
	app:UnRegsitMediator(NAME)
end

function ActivityCardMatchVoteMediator:OnClickRefreshBtnAction(sender)
	if self.isTimeEnd then
		uiMgr:ShowInformationTips(__('时间已结束'))
		return
	end
	if not self.isControllable_ then
		return
	end
	
	self:EnterLayer()
end

return ActivityCardMatchVoteMediator