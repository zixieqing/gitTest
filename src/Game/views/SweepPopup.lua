--[[
扫荡选择界面
@params table {
	stageId int 关卡id
	sweepRequestCommand COMMANDS 扫荡的请求
	sweepRequestData table 扫荡的额外参数
	sweepResponseSignal COMMANDS 扫荡请求返回的信号
	canSweepCB function 是否可以扫荡
}
--]]
local CommonDialog = require('common.CommonDialog')
local SweepPopup = class('SweepPopup', CommonDialog)

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")

local BattleCommand = require('battleEntry.network.BattleCommand')

--[[
override
initui
--]]
function SweepPopup:InitialUI()

	self.stageId = checkint(self.args.stageId)
	self.sweepRequestCommand = self.args.sweepRequestCommand
	self.sweepRequestData = self.args.sweepRequestData
	self.sweepResponseSignal = self.args.sweepResponseSignal
	self.canSweepCB = self.args.canSweepCB

	self.equipedMagicFoodId = nil

	self:RegistSignal()

	local function CreateView()

		local stageConf = CommonUtils.GetQuestConf(checkint(self.stageId))

		-- bg
		local bg = display.newImageView(_res('ui/common/common_bg_8.png'), 0, 0)
		local size = bg:getContentSize()

		-- view
		local view = display.newLayer(0, 0, {size = size, ap = cc.p(0.5, 0.5)})
		display.commonUIParams(bg, {po = utils.getLocalCenter(bg)})
		view:addChild(bg, 1)

		-- 诱饵相关
		local addMagicFoodLabel = display.newLabel(size.width * 0.5, size.height - 40,
			fontWithColor(6,{text = __('添加诱饵')}))
		view:addChild(addMagicFoodLabel, 5)
		addMagicFoodLabel:setVisible(false)

		-- 选择按钮
		local magicFoodNodeScale = 0.8
		local equipMagicFoodNode = display.newButton(0, 0, {n = _res('ui/common/common_frame_goods_1.png'), cb = function (sender)
			PlayAudioByClickNormal()
			self:ShowEquipMagicFoodPopup()
		end})
		equipMagicFoodNode:setScale(magicFoodNodeScale)
		display.commonUIParams(equipMagicFoodNode, {po = cc.p(addMagicFoodLabel:getPositionX(), addMagicFoodLabel:getPositionY() - 60)})
		view:addChild(equipMagicFoodNode, 5)
		equipMagicFoodNode:setVisible(false)

		local addIcon = display.newNSprite(_res('ui/common/maps_fight_btn_pet_add.png'), utils.getLocalCenter(equipMagicFoodNode).x, utils.getLocalCenter(equipMagicFoodNode).y)
		equipMagicFoodNode:addChild(addIcon)

		-- 扫荡券
		local sweepTicketLabel = display.newLabel(size.width * 0.5, 125,
			fontWithColor(8,{text = string.format(__('拥有扫荡券:%d'), gameMgr:GetAmountByGoodId(890001))}))
		view:addChild(sweepTicketLabel, 5)
		sweepTicketLabel:setVisible(false)

		-- sweep btn
		local t = {
			{times = 1, vip = 0},
			{times = 5, vip = 5}
		}
		if checkint(stageConf.difficulty)  == 2 then
			t[2].times = checkint( stageConf.challengeTime)
		end
		for i,v in ipairs(t) do
			local sweepBtn = display.newButton(0, 0,
				{n = _res('ui/common/common_btn_orange.png'), cb = handler(self, self.SweepBtnCallback), scale9 = true, size = cc.size(124,62)})
			display.commonLabelParams(sweepBtn, fontWithColor(14,{text = string.format(__('挑战%d次'),  checkint(v.times)) ,  reqW = 130}))
            local lwidth = display.getLabelContentSize(sweepBtn).width
            if lwidth < 124 then lwidth = 124 end
            sweepBtn:setContentSize(cc.size(lwidth + 16, 62))
			display.commonUIParams(sweepBtn,
				-- {po = cc.p(size.width * 0.5 + (i - 1.5) * 170, 65)})
				{po = cc.p(size.width * 0.5 + (i - 1.5) * 170, size.height * 0.5)})
			view:addChild(sweepBtn, 6)
			sweepBtn:setTag(v.times)

			local costLabel = display.newLabel(0, 0,
				fontWithColor(6,{text = string.format(__('消耗%d'), checkint(stageConf.consumeHp) * v.times)}))
			view:addChild(costLabel, 6)

			local iconScale = 0.15
			local costIconPath = CommonUtils.GetGoodsIconPathById(HP_ID)
			if QuestBattleType.ACTIVITY_QUEST == CommonUtils.GetQuestBattleByQuestId(self.stageId) then
				costIconPath = CommonUtils.GetGoodsIconPathById(ACTIVITY_QUEST_HP)
			elseif QuestBattleType.SAIMOE == CommonUtils.GetQuestBattleByQuestId(self.stageId) then
				costIconPath = CommonUtils.GetGoodsIconPathById(SAIMOE_POWER_ID)
				costLabel:setString(string.format(__('消耗%d'), checkint(stageConf.consumeGoodsLoseNum) * v.times))
			elseif QuestBattleType.MURDER == CommonUtils.GetQuestBattleByQuestId(self.stageId) then
				costIconPath = CommonUtils.GetGoodsIconPathById(app.murderMgr:GetMurderHpId())
				costLabel:setString(string.format(__('消耗%d'), checkint(stageConf.consumeHpNum) * v.times))
			elseif QuestBattleType.SPRING_ACTIVITY_20 == CommonUtils.GetQuestBattleByQuestId(self.stageId) then
				costIconPath = CommonUtils.GetGoodsIconPathById(app.springActivity20Mgr:GetHPGoodsId())
				costLabel:setString(string.format(__('消耗%d'), checkint(stageConf.consumeHpNum) * v.times))
			end

			local costIcon = display.newImageView(_res(costIconPath),
				0, 0, {ap = cc.p(0, 0.5)})
			costIcon:setScale(iconScale)
			view:addChild(costIcon, 6)

			display.setNodesToNodeOnCenter(sweepBtn, {costLabel, costIcon}, {y = -15})
		end


		return {
			view = view,
			equipMagicFoodNode = equipMagicFoodNode,
			sweepTicketLabel = sweepTicketLabel
		}

	end

	xTry(function ( )
		self.viewData = CreateView( )
	end, __G__TRACKBACK__)

end
--[[
显示装备魔法诱饵界面
--]]
function SweepPopup:ShowEquipMagicFoodPopup()
	AppFacade.GetInstance():DispatchObservers("SHOW_SELECT_MAGIC_FOOD", {
		equipedMagicFoodId = self.equipedMagicFoodId,
		equipCallback = handler(self, self.RefreshMagicFoodState)
	})
end
--[[
刷新诱饵状态
@params magicFoodId int 魔法食物id
--]]
function SweepPopup:RefreshMagicFoodState(magicFoodId)
	if nil == magicFoodId then
		self.viewData.equipMagicFoodNode:setVisible(true)
		if self.viewData.magicFoodNode then
			self.viewData.magicFoodNode:setVisible(false)
		end
	else
		self.viewData.equipMagicFoodNode:setVisible(false)
		if self.viewData.magicFoodNode then
			self.viewData.magicFoodNode:removeFromParent()
			self.viewData.magicFoodNode = nil
		end
		self.viewData.magicFoodNode = require('common.GoodNode').new({
			id = magicFoodId,
			showAmount = true,
			amount = gameMgr:GetAmountByGoodId(magicFoodId),
			callBack = function (sender)
				self:ShowEquipMagicFoodPopup()
			end})
		self.viewData.magicFoodNode:setScale(self.viewData.equipMagicFoodNode:getScale())
		display.commonUIParams(self.viewData.magicFoodNode, {po = cc.p(self.viewData.equipMagicFoodNode:getPositionX(), self.viewData.equipMagicFoodNode:getPositionY())})
		self.viewData.equipMagicFoodNode:getParent():addChild(self.viewData.magicFoodNode, 5)

	end

	self.equipedMagicFoodId = magicFoodId
end
--[[
扫荡按钮回调
--]]
function SweepPopup:SweepBtnCallback(sender)
	PlayAudioByClickNormal()
	local times = sender:getTag()

	self:SweepStage(self.stageId, times)
	-- local requestData = {questId = self.stageId, times = times, magicFoodId = self.equipedMagicFoodId}
	-- AppFacade.GetInstance():DispatchObservers("QUEST_SWEEP", {
	-- 	requestData = requestData
	-- })
end
--[[
扫荡关卡
@params stageId int 关卡id
@params times int 扫荡次数
--]]
function SweepPopup:SweepStage(stageId, times)
	if self:CanSweep(stageId, times) then
		-- 可以扫荡
		local requestData = {
			questId 			= self.stageId,
			times 				= times,
			magicFoodId 		= self.equipedMagicFoodId
		}

		if nil ~= self.sweepRequestData then
			for k,v in pairs(self.sweepRequestData) do
				requestData[k] = v
			end
		end

		local requestCommand = self.sweepRequestCommand or POST.QUEST_SWEEP.cmdName

		local mediator = AppFacade.GetInstance():RetrieveMediator("AppMediator")
		mediator:SendSignal(
			requestCommand,
			requestData
		)
	end
end
--[[
是否可以扫荡
@params stageId int 关卡id
@params times int 扫荡次数
@return _ bool 是否可以扫荡
--]]
function SweepPopup:CanSweep(stageId, times)
	local stageConf = CommonUtils.GetQuestConf(stageId)
	local battleType = CommonUtils.GetQuestBattleByQuestId(stageId)

	if QuestBattleType.MAP == battleType then
		local cityId = checkint(stageConf.cityId)

		-- 本关三星
		if nil == gameMgr:GetUserInfo().questGrades[tostring(cityId)] or
			3 > checkint(gameMgr:GetUserInfo().questGrades[tostring(cityId)].grades[tostring(stageId)]) then

			uiMgr:ShowInformationTips(__('达成本关三星才能扫荡'))
			return false

		end

		-- 扫荡次数
		if checkint(stageConf.consumeHp) * times > gameMgr:GetUserInfo().hp then

			uiMgr:ShowInformationTips(__('体力不足'))
			return false

		end

		-- 剩余次数
		local leftRechallengeTimes = CommonUtils.GetRechallengeLeftTimesByStageId(stageId)
		if QuestRechallengeTime.QRT_NONE == leftRechallengeTimes then
			uiMgr:ShowInformationTips(__('挑战次数不足\n挑战次数每日0:00重置'))
			return false
		elseif QuestRechallengeTime.QRT_INFINITE ~= leftRechallengeTimes and leftRechallengeTimes < times then
			uiMgr:ShowInformationTips(__('挑战次数不足\n挑战次数每日0:00重置'))
			return false
		end

		return true
	else
		if self.canSweepCB then
			return self.canSweepCB(stageId, times)
		end
	end

	return false
end
--[[
扫荡服务器回调
@params responseData table 服务器返回信息
--]]
function SweepPopup:ShowSweepPopup(responseData)
	local delayList = {}
	local function ShowSweepRewardPopup()
		------------ 展示扫荡奖励 ------------
		local tag = 2005
		--uiMgr:AddDialog('common.RewardPopup', {rewards = signal:GetBody().rewards,mainExp = signal:GetBody().mainExp, tag = self.rewardsLayer})
		local passTicketPoint = 0
		if nil ~= app.passTicketMgr and nil ~= app.passTicketMgr.UpdateExpByTask then
			local questId = responseData.requestData.questId
			app.passTicketMgr:UpdateExpByQuestId(questId, true, responseData.requestData.times)
			
			passTicketPoint = app.passTicketMgr:GetTaskPointByQuestId(questId)
		end
		if checkint(responseData.requestData.times ) == 1 then 
			if checkint(responseData.sweep['1'].mainExp) > 0 then
				responseData.sweep['1'].rewards[#responseData.sweep['1'].rewards+1] = {goodsId = EXP_ID, num = responseData.sweep['1'].mainExp}
			end
			local realRewards = nil
			if passTicketPoint > 0 then
				realRewards = clone(responseData.sweep['1'].rewards)
				table.insert(realRewards, {goodsId = PASS_TICKET_ID, num = passTicketPoint})
			end
			uiMgr:AddDialog('common.RewardPopup', {rewards = realRewards or responseData.sweep['1'].rewards,mainExp = responseData.sweep['1'].mainExp ,addBackpack = false,delayFuncList_ = delayList})
		else
			local layer = require('Game.views.SweepRewardPopup').new({tag = tag, rewardsData = responseData , executeAction = true , delayFuncList_ = delayList, passTicketPoint = passTicketPoint})
			display.commonUIParams(layer, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
			layer:setTag(tag)
			uiMgr:GetCurrentScene():AddDialog(layer)
		end
		------------ 展示扫荡奖励 ------------
	end

	-- 检测堕神 弹堕神弹窗
	local petViews = {}
	local function ShowNextPetView()
		local curPetView = petViews[1]
        uiMgr:GetCurrentScene():RemoveDialog(curPetView)
		table.remove(petViews, 1)

		if 0 < table.nums(petViews) then
			-- 存在下一个view 继续
			petViews[1]:setVisible(true)
		else
			-- 不存在 弹出扫荡奖励弹窗
			ShowSweepRewardPopup()
		end
	end

	local stageId = checkint(responseData.requestData.questId)
	local stageConf = CommonUtils.GetQuestConf(stageId)
	local battleType = CommonUtils.GetQuestBattleByQuestId(stageId)

	------------ 刷新本地数据 ------------
	-- 金币
	CommonUtils.DrawRewards({
		{goodsId = GOLD_ID, num  = responseData.totalGold}
	})
	if QuestBattleType.MAP == battleType then
		-- 体力
		CommonUtils.DrawRewards({
			{goodsId = HP_ID, num = -checkint(stageConf.consumeHp) * responseData.requestData.times}
		})

		-- 剩余挑战次数
		if responseData.challengeTime then
			gameMgr:UpdateChallengeTimeByStageId(stageId, checkint(responseData.challengeTime))
			-- 刷新界面
			self.enterBattleMediator = AppFacade.GetInstance():RetrieveMediator('EnterBattleMediator')
			if self.enterBattleMediator then
				if nil ~= self.enterBattleMediator.battleReadyView then
					self.enterBattleMediator.battleReadyView:RefreshChallengeTime()
				end
			end
		end
	end

	if responseData.sweep then
		for k,v in pairs(responseData.sweep) do
	        CommonUtils.DrawRewards(checktable(v.rewards))			
		end
	end

	if responseData.totalMainExp then
		-- 经验
		-- dump(responseData.totalMainExp)
	 	delayList = CommonUtils.DrawRewards({
	 		{goodsId = EXP_ID, num = (checkint(responseData.totalMainExp) - gameMgr:GetUserInfo().mainExp)}
	 	}, true)
	end

	-- 魔法诱饵
	if responseData.requestData.magicFoodId then
		CommonUtils.DrawRewards({{goodsId = responseData.requestData.magicFoodId, num = - math.min(gameMgr:GetAmountByGoodId(responseData.requestData.magicFoodId), responseData.requestData.times)}})
	end

	-- 扫荡券
	CommonUtils.DrawRewards({{goodsId = SWEEP_QUEST_ID, num = - math.min(gameMgr:GetAmountByGoodId(SWEEP_QUEST_ID), responseData.requestData.times)}})
	------------ 刷新本地数据 ------------

	-- 刷新扫荡界面
	self:RefreshSelfData()

	ShowSweepRewardPopup()

	if self.sweepResponseSignal then
		-- 向外发送一次信号
		AppFacade.GetInstance():DispatchObservers("QUEST_SWEEP_OVER", {
			responseData = responseData
		})
	end
end
--[[
刷新扫荡界面
--]]
function SweepPopup:RefreshSelfData()
	if self.equipedMagicFoodId then
		if self.viewData.magicFoodNode then
			self.viewData.magicFoodNode:removeFromParent()
			self.viewData.magicFoodNode = nil
		end
		self.viewData.magicFoodNode = require('common.GoodNode').new({
			id = self.equipedMagicFoodId,
			showAmount = true,
			amount = gameMgr:GetAmountByGoodId(self.equipedMagicFoodId),
			callBack = function (sender)
				self:ShowEquipMagicFoodPopup()
			end})
		self.viewData.magicFoodNode:setScale(self.viewData.equipMagicFoodNode:getScale())
		display.commonUIParams(self.viewData.magicFoodNode, {po = cc.p(self.viewData.equipMagicFoodNode:getPositionX(), self.viewData.equipMagicFoodNode:getPositionY())})
		self.viewData.equipMagicFoodNode:getParent():addChild(self.viewData.magicFoodNode, 5)
	end

	self.viewData.sweepTicketLabel:setString(string.format(__('拥有扫荡券:%d'), gameMgr:GetAmountByGoodId(890001)))
end
--[[
注册信号
--]]
function SweepPopup:RegistSignal()

	AppFacade.GetInstance():RegistSignal(POST.QUEST_SWEEP.cmdName, BattleCommand)

	------------ 扫荡回调 ------------
	local sweepResponseSignal = self.sweepResponseSignal or POST.QUEST_SWEEP.sglName

	AppFacade.GetInstance():RegistObserver(sweepResponseSignal, mvc.Observer.new(function (_, signal)
		local responseData = signal:GetBody()
		dump(responseData)
		self:ShowSweepPopup(responseData)
	end, self))
	------------ 扫荡回调 ------------
end
--[[
注销信号
--]]
function SweepPopup:UnregistSignal()
	AppFacade.GetInstance():UnRegsitSignal(POST.QUEST_SWEEP.cmdName)

	------------ 扫荡回调 ------------
	local sweepResponseSignal = self.sweepResponseSignal or POST.QUEST_SWEEP.sglName

	AppFacade.GetInstance():UnRegistObserver(sweepResponseSignal, self)
	------------ 扫荡回调 ------------
end

function SweepPopup:onCleanup()
	self:UnregistSignal()
end

return SweepPopup
