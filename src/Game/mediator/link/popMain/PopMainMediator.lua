--[[
 * author : liuzhipeng
 * descpt : 联动 pop子 关卡Mediator
--]]
---@class PopMainMediator:Mediator
local PopMainMediator = class('PopMainMediator', mvc.Mediator)
local NAME = "popTeam.PopMainMediator"
local FARM_STATUS = {
	LOCK_ZONE             = 1, -- 区域未解锁
	UNLOCK_FIRST_ZONE     = 2, -- 解锁第一区域
	UNLOCK_FIRST_LAND     = 3, -- 解锁第一区域
	CLEAR_FIRST_ZONE      = 4, -- 通关上篇区域
	UNLOCK_SECOND_ZONE    = 5, -- 解锁第二区域
	CLEAR_SECOND_ZONE     = 6, -- 通关下篇区域
}
local POP_MAIN_EVENT = {
	POP_EVENT                      = "POP_EVENT",                                  -- 左侧弹出框弹出
	IN_COME_EVENT                  = "IN_COME_EVENT",                              -- 左侧弹出框收入
	PART_ONE_EVENT                 = "PART_ONE_EVENT",                             -- 上篇事件
	PART_TWO_EVENT                 = "PART_TWO_EVENT",                             -- 下篇事件
	UNLOCK_VEGETABLE_EVENT         = "UNLOCK_VEGETABLE_EVENT",                     -- 开荒事件
	POP_REWARD_RECORD_EVENT        = "POP_REWARD_RECORD_EVENT",                    -- 收获记录
	POP_SOW_SEED_EVENT             = "POP_SOW_SEED_EVENT",                         -- 播种事件
	POP_ONE_KEY_REWARD_EVENT       = "POP_ONE_KEY_REWARD_EVENT",                   -- 一键领取事件
	POP_BUY_SEED_EVENT             = "POP_BUY_SEED_EVENT",                         -- 购买种子事件
	POP_BUY_SEED_SUCCESS_EVENT     = "POP_BUY_SEED_SUCCESS_EVENT",                 -- 种子购买成功
	POP_RECIPE_EVENT               = "POP_RECIPE_EVENT",                           -- 弹出菜谱制作界面
	POP_SHOW_BATTLE_BOSS_EVENT     = "POP_SHOW_BATTLE_BOSS_EVENT",                 -- 显示boss副本界面
	POP_VEGETABLE_CELL_CLICK_EVENT = "POP_VEGETABLE_CELL_CLICK_EVENT",             -- 菜地点击事件
	POP_BOSS_FREE_EVENT            = "POP_BOSS_FREE_EVENT",                       -- boss 是否有免费挑战次数显示
}

function PopMainMediator:ctor(params, viewComponent)
	self.super.ctor(self, NAME, viewComponent)
	params = checktable(params)
	local requestData = params.requestData or {}
	self.homeData = params
	self.lockStatus = self:GetFarmStatus()
	self.activityId = requestData.activityId
	self:AddBossMediator(requestData)
	self.zoneArray = self:GetZoneKeySort()
	self.landPreTimes = {   -- 记录各个地块进入倒计时的时间点

	}
end

------------------ inheritance ------------------
function PopMainMediator:Initial( key )
	self.super.Initial(self, key)
	---@type PopMainScene
	local viewComponent = app.uiMgr:SwitchToTargetScene('Game.views.link.popMain.PopMainScene', {
		lockStatus = self.lockStatus ,
		summaryId = self:GetSummaryId() ,
		zoneArray = self.zoneArray ,
		isClearance = self:CheckBossUnlock(),
	})
	self:SetViewComponent(viewComponent)
	viewComponent:AddMenusGoodLayout(self:GetMenuGoods())
	viewComponent:UpdateIncomeStatus(self:GetZones())
	local bottomData = viewComponent.bottomData
	display.commonUIParams(bottomData.backBtn , {cb = handler(self, self.BackActivityMediator)})
	self:CreateTimer()
	local zones = self:GetZones()
	if #zones >  0 then
		viewComponent:UpdateAllVegeTableNode(self:GetLandAllData())
		viewComponent:UpdateSeeds(self:GetSeeds())
		for index , zoneData in pairs(zones) do
			if checkint(zoneData.zoneId) == self.zoneArray[1] and self.lockStatus >= FARM_STATUS.CLEAR_FIRST_ZONE then
				viewComponent:CreateOneCome()
			elseif checkint(zoneData.zoneId) == self.zoneArray[2] and self.lockStatus >= FARM_STATUS.CLEAR_SECOND_ZONE then
				viewComponent:CreateTwoCome()
			end
		end
	end
	viewComponent:UpdateModuleName(self:GetActivityName())
	self:TraverseFarmLandCanUnlock()
end
function PopMainMediator:GetZoneKeySort()
	local farmZoneConf = CONF.ACTIVITY_POP.FARM_ZONE:GetValue(self:GetSummaryId())
	local keys = table.keys(farmZoneConf)
	table.sort(keys , function(a, b)
		return a < b
	end)
	return keys
end
function PopMainMediator:GetActivityName()
	local activityHomeData = app.gameMgr:GetUserInfo().activityHomeData
	local activity = activityHomeData.activity
	local activityData = nil
	for i , v in pairs(activity) do
		if checkint(v.activityId) == self.activityId then
			activityData = v
			break
		end
	end
	local activityName = ""
	if activityData then
		activityName = activityData.title[i18n.getLang()]
	end
	return activityName
end
function PopMainMediator:AddBossMediator(requestData)
	if checkint(requestData.bossId) > 0 then
		sceneWorld:runAction(
			cc.Sequence:create(
				cc.DelayTime:create(0.1),
				cc.CallFunc:create(function()
					self:ShowBossMediator(requestData.bossId)
				end)
			)
		)
	end
end

function PopMainMediator:InterestSignals()
	local signals = {
		POST.POP_TEAM_HOME.sglName  ,
		POST.POP_FARM_LAND_UNLOCK.sglName ,
		POST.POP_FARM_PLANT.sglName ,
		POST.POP_FARM_MATURE.sglName ,
		POST.POP_FARM_ZONE_UNLOCK.sglName ,
		POP_MAIN_EVENT.IN_COME_EVENT ,
		POP_MAIN_EVENT.POP_EVENT ,
		POP_MAIN_EVENT.POP_BUY_SEED_EVENT ,
		POP_MAIN_EVENT.POP_SOW_SEED_EVENT ,
		POP_MAIN_EVENT.POP_BUY_SEED_SUCCESS_EVENT ,
		POP_MAIN_EVENT.UNLOCK_VEGETABLE_EVENT ,
		POP_MAIN_EVENT.POP_REWARD_RECORD_EVENT ,
		POP_MAIN_EVENT.PART_ONE_EVENT ,
		POP_MAIN_EVENT.PART_TWO_EVENT ,
		POP_MAIN_EVENT.POP_ONE_KEY_REWARD_EVENT ,
		POP_MAIN_EVENT.POP_VEGETABLE_CELL_CLICK_EVENT ,
		POP_MAIN_EVENT.POP_RECIPE_EVENT ,
		POP_MAIN_EVENT.POP_SHOW_BATTLE_BOSS_EVENT ,
		POP_MAIN_EVENT.POP_BOSS_FREE_EVENT,
		SGL.REFRESH_NOT_CLOSE_GOODS_EVENT,
	}
	return signals
end
function PopMainMediator:ProcessSignal( signal )
	local name = signal:GetName()
	local body = signal:GetBody()
	if name == POST.POP_FARM_LAND_UNLOCK.sglName then
		self:FarmLandUnlock(body)
	elseif name == POST.POP_FARM_PLANT.sglName then
		self:FarmPlant(body)
	elseif name == POST.POP_FARM_MATURE.sglName then
		self:FarmMature(body)
	elseif name == POP_MAIN_EVENT.IN_COME_EVENT then
		self:InComeEvent(body)
	elseif name == POP_MAIN_EVENT.POP_EVENT then
		self:PopEvent(body)
	elseif name == POP_MAIN_EVENT.PART_ONE_EVENT then
		self:PartOneEvent()
	elseif name == POP_MAIN_EVENT.PART_TWO_EVENT then
		self:PartTwoEvent()
	elseif name == POST.POP_FARM_ZONE_UNLOCK.sglName then
		self:UnLockZone(body)
	elseif name == POP_MAIN_EVENT.POP_ONE_KEY_REWARD_EVENT then
		self:OneKeyRewardEvent(body)
	elseif name == POP_MAIN_EVENT.POP_RECIPE_EVENT then
		self:PopMakeRecipeView()
	elseif name == POP_MAIN_EVENT.POP_BUY_SEED_EVENT then
		self:PopShowShopView(body)
	elseif name == POP_MAIN_EVENT.POP_SHOW_BATTLE_BOSS_EVENT then
		self:ShowBossMediator()
	elseif name == POP_MAIN_EVENT.POP_SOW_SEED_EVENT then
		self:SowSeedEvent(body)
	elseif name == POP_MAIN_EVENT.POP_REWARD_RECORD_EVENT then
		local view = require("Game.views.link.popMain.PopRecordView").new(self:GetHarvest())
		view:setPosition(display.center)
		app.uiMgr:GetCurrentScene():AddDialog(view)
	elseif name == POP_MAIN_EVENT.POP_VEGETABLE_CELL_CLICK_EVENT then
		self:PopVegeTableCellClickEvent(body)
	elseif name == POP_MAIN_EVENT.POP_BUY_SEED_SUCCESS_EVENT then
		self:BuySeedSuccess(body)
	elseif name == SGL.REFRESH_NOT_CLOSE_GOODS_EVENT then
		self:UpdateMenuGoods()
	elseif name == POP_MAIN_EVENT.UNLOCK_VEGETABLE_EVENT then
		self:UnlockVegetableEvent()
	elseif name == POP_MAIN_EVENT.POP_BOSS_FREE_EVENT then
		self:UpdateBossFreeRedIcon(body)
	end
end

function PopMainMediator:CreateTimer()
	local viewComponent = self:GetViewComponent()
	viewComponent:runAction(cc.RepeatForever:create(
		cc.Sequence:create(
			cc.CallFunc:create(function()
				local lands = self:GetLandAllData()
				for i , v in pairs(lands) do
					if v.seed and checkint(v.seed.seedId) > 0 then
						local matureLeftSeconds = checkint(v.seed.matureLeftSeconds)
						if matureLeftSeconds > 0  then
							local landId = v.landId
							local preTime = self:GetLandPreTime(landId)
							if not preTime then
								preTime = os.time()
								self:SetLandPreTime(landId ,preTime )
							end
							matureLeftSeconds = matureLeftSeconds - os.time() +  preTime
							matureLeftSeconds  = matureLeftSeconds <= 0 and 0  or matureLeftSeconds
						end
						if matureLeftSeconds >= 0 then
							self:GetFacade():DispatchObservers(
							string.format("POP_VEGETABLE_NODE_EVENT_%d" ,v.landId ),
							{
								summaryId = self:GetSummaryId() ,
								landId = v.landId ,
								seed = {
									seedId = v.seed.seedId ,
									matureLeftSeconds = matureLeftSeconds
								}
							})
							local viewComponent = self:GetViewComponent()
							viewComponent:UpdateOneKeyAnimation({
                                [tostring(v.landId)] = ( matureLeftSeconds == 0)
                            })
						end
					end
				end
			end),
			cc.DelayTime:create(1)
		)
	))
end
function PopMainMediator:UpdateMenuGoods()
	---@type PopMainScene
	local viewComponent = self:GetViewComponent()
	viewComponent:UpdateMenusGoods()
end
function PopMainMediator:PopShowShopView(body)
	---@type PopShopMediator
	local mediator = require("Game.mediator.link.popMain.PopShopMediator").new({
		summaryId = self:GetSummaryId() ,
		activityId = self.activityId
   })
	app:RegistMediator(mediator)
end
--[[
种菜种植
--]]
function PopMainMediator:FarmPlant(body)
	local requestData = body.requestData
	local activityId = requestData.activityId
	-- 不是同一个活动就直接返回
	if checkint(self.activityId) ~= checkint(activityId) then
		return
	end
	local landId = body.landId
	local seedId = requestData.seedId
	self:SetLandDataMap(landId ,{
		landId            = landId,
		seed  = {
			seedId            = seedId,
			matureLeftSeconds = body.matureLeftSeconds,
		}
	})
	self:ReducedSeed({goodsId = seedId , num = 1})
	---@type PopMainScene
	local viewComponent = self:GetViewComponent()
	viewComponent:UpdateVegeTableNode({landId = landId  , unlock = true ,seed = {
		seedId            = seedId,
		matureLeftSeconds = body.matureLeftSeconds
	} })
	viewComponent:UpdateSeeds(self:GetSeeds())
end

function PopMainMediator:OneKeyRewardEvent(body)
	self:SendSignal(POST.POP_FARM_MATURE.cmdName , {activityId = self.activityId ,landId = 0  })
end

--[[
种菜成熟
--]]
function PopMainMediator:FarmMature(body)
	local requestData = body.requestData
	local activityId = checkint(requestData.activityId)
	if checkint(self.activityId) ~= activityId  then
		return
	end
	-- 表示未成熟领取
	local rewards = clone(body.rewards)
	local landIds = clone(body.landIds)
	self:AddHarvest(rewards)
	local landId = checkint(requestData.landId)
	---@type PopMainScene
	local viewComponent = self:GetViewComponent()
	if landId == 0 then
		-- landId 等于零 表示一键领取
		for i , landId in pairs(landIds) do
			self:SetLandDataMap(landId , {landId = landId})
			self:ClearLandPreTime(landId)
			viewComponent:UpdateVegeTableNode({landId = landId , unlock = true , status = 1 })
		end
	else
		local status = requestData.status
		if status < 3 then
			local lands = self:GetLandAllData()
			local landData = nil
			for i , v in pairs(lands) do
				if checkint(v.landId ) == landId then
					landData = v
					break
				end
			end
			local preTime = self:GetLandPreTime(landId)
			local currentTime = os.time()
			local distanceTime = currentTime - preTime
			if distanceTime > 0 then
				local farmSeedConf    = CONF.ACTIVITY_POP.FARM_SEED:GetValue(self:GetSummaryId())
				local oneFarmSeedConf = farmSeedConf[tostring(landData.seed.seedId)]
				local duration =checkint(oneFarmSeedConf.duration)
				local accelerateConsume = oneFarmSeedConf.accelerateConsume
				local consumeNum = math.ceil(( (landData.seed.matureLeftSeconds - distanceTime)/duration) * checkint(accelerateConsume.num))
				rewards[#rewards+1] = {
					goodsId = accelerateConsume.goodsId,
					num = - consumeNum,
				}
			end
		end
		self:SetLandDataMap(landId , {landId = landId})
		self:ClearLandPreTime(landId)
		viewComponent:UpdateVegeTableNode({landId = landId , unlock = true , status = 1})
	end
	local landsMature = {}
	for i , landId in pairs(landIds) do
		landsMature[tostring(landId)] = false
	end
	viewComponent:UpdateOneKeyAnimation(landsMature)
	CommonUtils.DrawRewards(rewards)
	app.uiMgr:AddDialog("common.RewardPopup", {rewards = body.rewards ,addBackpack = false})
end
function PopMainMediator:PopEvent(body)
	local zones = self:GetZones()
	---@type PopMainScene
	local viewComponent = self:GetViewComponent()
	viewComponent:CreatePopupLayout()
	viewComponent:UpdatePopStatus(zones)
end

function PopMainMediator:InComeEvent(body)
	local zones = self:GetZones()
	---@type PopMainScene
	local viewComponent = self:GetViewComponent()
	viewComponent:UpdateIncomeStatus(zones)
end

-- 解锁区域
function PopMainMediator:UnLockZone(body)
	local requestData = body.requestData
	local zoneId = requestData.zoneId
	local farmZoneConf = CONF.ACTIVITY_POP.FARM_ZONE:GetValue(self:GetSummaryId())
	local unlock = clone(farmZoneConf[tostring(zoneId)].unlock)
	app.uiMgr:ShowInformationTips(__('土地解锁成功'))
	if #unlock > 0 then
		for i , v in pairs(unlock) do
			v.num =  -v.num
		end
		CommonUtils.DrawRewards(unlock)
	end
	self:AddZoneData({zoneId = zoneId})
	if checkint(zoneId) == checkint(self.zoneArray[1]) then
		---@type PopMainScene
		local viewComponent = self:GetViewComponent()
		local viewLockVegeTableData = viewComponent.viewLockVegeTableData
		viewLockVegeTableData.vegeTableLayout:runAction(cc.RemoveSelf:create())
		viewLockVegeTableData.vegeTableLayout = nil
		viewComponent.bottomData.bgImage:setTexture(_res("ui/link/popMain/pop_bg_1.jpg"))
		viewComponent:CreateVegeTableLayout()
		viewComponent:UpdateAllVegeTableNode(self:GetLandAllData())
		viewComponent:UpdateLockStatus(FARM_STATUS.UNLOCK_FIRST_ZONE)
		viewComponent:UpdatePopStatus(self:GetZones())

	elseif checkint(zoneId) == checkint(self.zoneArray[2]) then
		---@type PopMainScene
		local viewComponent = self:GetViewComponent()
		viewComponent:UpdatePopStatus(self:GetZones())
	end
	self:TraverseFarmLandCanUnlock()
end

function PopMainMediator:FarmLandUnlock(body)
	local requestData = body.requestData
	local landId = requestData.landId
	local lands = self:GetLandAllData()
	---@type PopMainScene
	local viewComponent = self:GetViewComponent()
	if #lands == 0  then
		viewComponent:CreateTopLayer()
		viewComponent:UpdateSeeds({})
	end
	self:SetLandDataMap(landId , {landId = landId})
	viewComponent:UpdateVegeTableNode({landId = landId , unlock = true })
	local eventName = string.format("POP_VEGETABLE_NODE_UNLOCK_SPINE_SHOW_EVENT_%d" , landId)
	app:DispatchObservers(eventName , {landId = landId , canUnLock = false})
end

function PopMainMediator:SowSeedEvent(body)
	local seedId = body.seedId
	local seeds = self:GetSeeds()
	local num = checkint(seeds[tostring(seedId)])
	if num > 0  then
		local lands = self:GetLandAllData()
		local isFreeLand = false
		for i , v in pairs(lands) do
			if not (v.seed and v.seed.seedId) then
				isFreeLand = true
				app.uiMgr:AddDialog("Game.views.link.popMain.PopSowSeedView" , {
					summaryId = self:GetSummaryId() ,
					seedId = seedId ,
					callfunc = function()
						self:SendSignal(POST.POP_FARM_PLANT.cmdName , {
							activityId = self.activityId ,
							seedId = seedId
						})
					end
				})
				break
			end
		end
		if not isFreeLand then
			app.uiMgr:ShowInformationTips(__('暂无空闲的菜地'))
			return
		end
	else
		self:PopShowShopView()
	end
end

function PopMainMediator:PartOneEvent(body)
	local zones = self:GetZones()
	local summaryId = self:GetSummaryId()
	local farmZoneConf = CONF.ACTIVITY_POP.FARM_ZONE:GetValue(summaryId)
	if #zones == 0 then
		local unlock = farmZoneConf["1"].unlock
		if #unlock == 0 then
			---@type PopMainScene
			local viewComponent = self:GetViewComponent()
			viewComponent:UnlockVegeTableAnimation()
		end
	else
		self:JumpToMapMediator(1)
	end
end

function PopMainMediator:PartTwoEvent(body)
	local zones = self:GetZones()
	local summaryId = self:GetSummaryId()
	local farmZoneConf = CONF.ACTIVITY_POP.FARM_ZONE:GetValue(summaryId)
	if #zones == 0 then
		app.uiMgr:ShowInformationTips(__('请先通关上篇'))
	elseif #zones == 1 then
		if self.lockStatus == FARM_STATUS.CLEAR_FIRST_ZONE then
			local unlock = clone(farmZoneConf[tostring(self.zoneArray[2])].unlock or {})
			local isEnough = self:JudageGoodsEnough(unlock)
			local goodsName =  GoodsUtils.GetGoodsNameById(unlock[1].goodsId)
			local needNum = checkint(unlock[1].num)
			local ownGoodsNum = CommonUtils.GetCacheProductNum(unlock[1].goodsId)
			local text = string.fmt(__('消耗_num_个_goodName_解锁剧情下篇'),{_num_ = needNum ,_goodName_ = goodsName })
			local commonTip = require('common.CommonPopTip').new({
				 viewType = 1,
				 text = text,
				 textW = 260,
				 ownTip =  string.fmt(__('拥有_goodsName_:_num_'), {_goodsName_ =goodsName , _num_ =  ownGoodsNum}),
				 btnTextR = isEnough and __("确定") or __('获取'),
				 btnImgR = _res('ui/common/common_btn_white_default.png'),
				 callback = function (sender)
					 if isEnough then
						 self:SendSignal(POST.POP_FARM_ZONE_UNLOCK.cmdName , { activityId = self.activityId , zoneId = self.zoneArray[2]})
					 else
						 app.uiMgr:AddDialog("common.GainPopup", {goodId =unlock[1].goodsId })
					 end
				 end
			 })
			commonTip:setName('CommonPopTip')
			commonTip:setPosition(display.center)
			app.uiMgr:GetCurrentScene():AddDialog(commonTip)
		else
			app.uiMgr:ShowInformationTips(__('请先通关上篇'))
		end
	elseif #zones == 2 then
		self:JumpToMapMediator(self.zoneArray[2])
	end
end

function PopMainMediator:JumpToMapMediator(zoneId)
	local activityId = self.activityId
	local zones = self:GetZones()
	local zoneIndex = 1
	for i , v in pairs(zones) do
		if checkint(zoneId) == checkint(v.zoneId) then
			zoneIndex = i
			break
		end
	end
	app:RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'}, {name = 'link.popTeam.PopTeamStageMediator', params = {activityId = activityId, zoneIndex = zoneIndex}}, {isBack = false}, true)
end

function PopMainMediator:UnlockVegetableEvent()
	local summaryId = self:GetSummaryId()
	local farmZoneConf = CONF.ACTIVITY_POP.FARM_ZONE:GetValue(summaryId)
	local unlock = clone(farmZoneConf["1"].unlock or {})
	local isEnough = self:JudageGoodsEnough(unlock)
	if isEnough then
		self:SendSignal(POST.POP_FARM_ZONE_UNLOCK.cmdName , { activityId = self.activityId , zoneId = self.zoneArray[1]})
	else
		local goodsName =  GoodsUtils.GetGoodsNameById(unlock[1].goodsId)
		app.uiMgr:ShowInformationTips(string.fmt(__('_name_ 不足') , { _name_ = goodsName}) )
		return
	end
end
---@params zoneId 区域id
---@deprecated 检测当前区域是否通关
function PopMainMediator:CheckZoneIdClearanceByQuestId(zoneId)
	local zones = self:GetZones()
	zoneId = checkint(zoneId)
	local questId = 0
	for index, zoneData in pairs(zones) do
		if checkint(zoneData.zoneId) == zoneId then
			questId = checkint(zoneData.newestQuestId)
			break
		end
	end
	if questId > 0 then
		local farmQuestConf = CONF.ACTIVITY_POP.FARM_QUEST_TYPE:GetValue(tostring(zoneId))[tostring(questId)]
		if table.nums(farmQuestConf) > 0  then
			if checkint(farmQuestConf.zoneId) ~= zoneId then
				return true
			end
		else
			return true
		end
	end
	return false
end

function PopMainMediator:CheckBossUnlock()
	local farmConf = CONF.ACTIVITY_POP.FARM:GetValue(self:GetSummaryId())
	local bossOpenZoneId = farmConf.bossOpenZoneId
	local isClearance = self:CheckZoneIdClearanceByQuestId(bossOpenZoneId)
	return isClearance
end

function PopMainMediator:PopVegeTableCellClickEvent(body)
	local landId = body.landId
	local landData = self:GetLandDataByLandId(landId)
	if not landData then
		-- 不存在表示解锁
		local farmLandConf = CONF.ACTIVITY_POP.FARM_LAND:GetValue(self:GetSummaryId())[tostring(landId)]
		local unlockType = farmLandConf.unlockType
		local zones = self:GetZones()
		local maxQuestId = 0
		for index  , zoneData in pairs(zones) do
			local newestQuestId = checkint(zoneData.newestQuestId)
			maxQuestId  = newestQuestId > maxQuestId and newestQuestId or maxQuestId 
		end
		local isUnlock = true
		for lockType , lockData in pairs(unlockType) do
			if checkint(lockType) == 131 then
				local questId = checkint(lockData.targetId)
				if questId >= maxQuestId then
					local questName = ""
					local farmQuestConf = CONF.ACTIVITY_POP.FARM_QUEST_TYPE:GetAll()
					for zoneId, zoneQuestConf in pairs(farmQuestConf) do
						if zoneQuestConf[tostring(questId)] then
							questName = zoneQuestConf[tostring(questId)].checkpointName
							break
						end
					end
					app.uiMgr:ShowInformationTips(string.fmt(__('通关_questName_解锁'), { _questName_ = questName}) )
					isUnlock = false
					break
				end
			elseif checkint(lockType) == 64 then
				local cardId = lockData.targetId
				local cardData = app.gameMgr:GetCardDataByCardId(cardId)
				local needBreakLevel = checkint(lockData.targetNum)
				if not cardData then
					local cardConf = CommonUtils.GetConfigAllMess('card', 'card')[tostring(cardId)] or {}
					app.uiMgr:ShowInformationTips(string.fmt(__('_name_突破_level_星解锁') , {_name_ =cardConf.name  or "" , _level_ = needBreakLevel }) )
					isUnlock = false
					break
				end
				local breakLevel = checkint(cardData.breakLevel)
				if breakLevel < needBreakLevel then
					local cardConf = CommonUtils.GetConfigAllMess('card', 'card')[tostring(cardId)] or {}
					app.uiMgr:ShowInformationTips(string.fmt(__('_name_突破_level_星解锁') , {_name_ =cardConf.name  or "" , _level_ = needBreakLevel }) )
					isUnlock = false
					break
				end
			end
		end
		if isUnlock then
			self:SendSignal(POST.POP_FARM_LAND_UNLOCK.cmdName , {activityId = self.activityId , landId = landId})
		end
	else
		-- 存在有两种情况 1. 领取 ， 2 .加速
		if not (landData.seed and landData.seed.seedId) then
			return
		end
		local matureLeftSeconds = checkint(landData.seed.matureLeftSeconds)
		local distanceTime = 0
		if matureLeftSeconds > 0 then
			local preTime = self:GetLandPreTime(landId)
			local currentTime = os.time()
			distanceTime = currentTime - preTime
		end
		if matureLeftSeconds - distanceTime <= 0 then -- 倒计时已经结束 ， 直接领取成熟的奖励
			self:SendSignal(POST.POP_FARM_MATURE.cmdName , {activityId = self.activityId ,  landId = landId , status = 3 })
		else
			local summaryId = self:GetSummaryId()
			local farmSeedConf = CONF.ACTIVITY_POP.FARM_SEED:GetValue(summaryId)[tostring(landData.seed.seedId)]
			local accelerateConsume = farmSeedConf.accelerateConsume
			local num = math.ceil(accelerateConsume.num *  (matureLeftSeconds - distanceTime) /checkint(farmSeedConf.duration) )
			dump(farmSeedConf)
			local ownerNum = CommonUtils.GetCacheProductNum(accelerateConsume.goodsId)
			if ownerNum >= num then
				app.uiMgr:AddNewCommonTipDialog({
                richtext = {
	                {fontSize = 24 ,color = "#b1613a", text = string.fmt(__('是否使用_num_') , {_num_ = num})},
	                {img = CommonUtils.GetGoodsIconPathById(accelerateConsume.goodsId) , scale = 0.2},
	                {fontSize = 24 ,color = "#b1613a", text = string.fmt( __('进行_name_加速') ,{_name_= farmSeedConf.name})}
                },
                callback = function()
	                self:SendSignal(POST.POP_FARM_MATURE.cmdName , {activityId = self.activityId ,  landId = landId , status = 1})
				end})
			else
				app.uiMgr:ShowInformationTips(string.fmt(__('_name_不足'), {_name_ = GoodsUtils.GetGoodsNameById(accelerateConsume.goodsId)  }) )
			end
		end
	end
end
--[[
	弹出做菜界面
--]]
function PopMainMediator:PopMakeRecipeView()
	AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = ''},{name = 'RecipeResearchAndMakingMediator', params = {recipeStyle = RECIPE_STYLE.ACTIVITY_RECIPE_STYLE } })
end

function PopMainMediator:ShowBossMediator(bossId)
	local bossUnlock = self:CheckBossUnlock()
	local farmConf = CONF.ACTIVITY_POP.FARM:GetValue(self:GetSummaryId())
	if not bossUnlock then
		app.uiMgr:ShowInformationTips(string.fmt(__('请通关第_num_区域') ,{ _num_ = farmConf.bossOpenZoneId}) )
		return
	end
	local mediator = require("Game.mediator.link.popMain.PopBattleBossMediator").new({ activityId = self.activityId , bossId = bossId , summaryId = self:GetSummaryId()})
	app:RegistMediator(mediator)

end
-- 判断道具是否充足
function PopMainMediator:JudageGoodsEnough(unlock)
	local goodsMgr = app.goodsMgr
	local isEnough = true
	for i , val in pairs(unlock) do
		local ownerNum = goodsMgr:GetGoodsAmountByGoodsId(val.goodsId)
		if checkint(ownerNum) < checkint(val.num) then
			isEnough = false
			break
		end
	end
	return isEnough
end
-- 获取所有土地的数据
function PopMainMediator:GetLandAllData()
	if not self.homeData.lands then
		self.homeData.lands = {}
	end
	return self.homeData.lands 
end

function PopMainMediator:GetLandDataByLandId(landId)
	local lands = self:GetLandAllData()
	landId = checkint(landId)
	for index  , landData in pairs(lands) do
		if checkint(landData.landId) == landId then
			return landData
		end
	end
	return nil
end

function PopMainMediator:SetLandDataMap(landId , data)
	local landId = checkint(landId)
	local lands = self:GetLandAllData()
	local isHave = false
	for i = 1 , #lands do
		if landId == checkint(lands[i].landId) then
			isHave = true
			lands[i] = data
			break
		end
	end
	if not isHave then
		lands[#lands+1] = data
	end
end

function PopMainMediator:GetHarvest()
	if not self.homeData.harvest then
		self.homeData.harvest = {}
	end
	return self.homeData.harvest
end

function PopMainMediator:GetSeeds()
	if not self.homeData.seeds then
		self.homeData.seeds = {}
	end
	return self.homeData.seeds
end

function PopMainMediator:ReducedSeed(data)
	self.homeData.seeds[tostring(data.goodsId)] = checkint(self.homeData.seeds[tostring(data.goodsId)]) - data.num
end
function PopMainMediator:GetZones()
	if not self.homeData.zones then
		self.homeData.zones = {}
	end
	return self.homeData.zones
end
function PopMainMediator:AddZoneData(zoneData)
	local zones = self:GetZones()
	local unLockZoneId = checkint(zoneData.zoneId)
	local isUnlock = false
	for index  , oneZoneData in pairs(zones) do
		local zoneId = checkint(oneZoneData.zoneId)
		if zoneId == unLockZoneId then
			isUnlock = true 
			break
		end
	end
	if not isUnlock then
		zones[#zones+1] = zoneData
	end
end
function PopMainMediator:UpdateBossFreeRedIcon(body)
	local isFree = body.isFree
	local viewComponent = self:GetViewComponent()
	viewComponent:UpdateBossRedIcon(isFree)
end

function PopMainMediator:BuySeedSuccess(body)
	self:AddSeed(body)
	---@type PopMainScene
	local viewComponent = self:GetViewComponent()
	viewComponent:UpdateSeeds(self:GetSeeds())
end
function PopMainMediator:AddSeed(data)
	local seeds = self:GetSeeds()
	if not seeds[tostring(data.goodsId)] then
		seeds[tostring(data.goodsId)] = 0
	end
	seeds[tostring(data.goodsId)]  =  seeds[tostring(data.goodsId)] + checkint(data.num)
end
function PopMainMediator:CheckCanUnlockByLandId(landId)
	local landsData = self:GetLandAllData()
	landId = checkint(landId)
	for i,landData in pairs(landsData) do
		if checkint(landData.landId) == landId then
			-- 检测土地是否解锁
			return false
		end
	end
	local farmLandConf = CONF.ACTIVITY_POP.FARM_LAND:GetValue(self:GetSummaryId())[tostring(landId)]
	local unlockType = farmLandConf.unlockType
	local isCanUnlock = true
	for unlock, unlockData in pairs(unlockType) do
		if checkint(unlock) == 131 then
			local isClearance = false
			for i, v in pairs(self:GetZones()) do
				if checkint(v.newestQuestId) > checkint(unlockData.targetId) then
					isClearance = true
					break 
				end
			end

			if not isClearance then
				isCanUnlock = false
				break
			end
		elseif checkint(unlock) == 64 then
			local cardId = unlockData.targetId
			local cardData = app.gameMgr:GetCardDataByCardId(cardId)
			if cardData then
				local breakLevel = checkint(cardData.breakLevel)
				if breakLevel < checkint(unlockData.targetNum) then
					isCanUnlock = false
				end
			else
				isCanUnlock = false
			end
			if not isCanUnlock then
				break
			end
		end
	end
	return isCanUnlock
end
function PopMainMediator:TraverseFarmLandCanUnlock()
	local farmLandConf = CONF.ACTIVITY_POP.FARM_LAND:GetValue(self:GetSummaryId())
	for i, v in pairs(farmLandConf) do
		local isCanUnlock = self:CheckCanUnlockByLandId(v.id)
		local eventName = string.format("POP_VEGETABLE_NODE_UNLOCK_SPINE_SHOW_EVENT_%d" , checkint(v.id))
		app:DispatchObservers(eventName , {landId = v.id , canUnLock = isCanUnlock })
	end
end
function PopMainMediator:GetLandPreTime(landId)
	return self.landPreTimes[tostring(landId)]
end

function PopMainMediator:SetLandPreTime(landId , times )
	self.landPreTimes[tostring(landId)] = times
end

function PopMainMediator:ClearLandPreTime(landId)
	self.landPreTimes[tostring(landId)] = nil
end

function PopMainMediator:AddHarvest(data)
	local harvest = self:GetHarvest()
	for i = 1 , #data do
		local goodsId = tostring(data[i].goodsId)
		if not harvest[goodsId] then
			harvest[goodsId] = 0
		end
		harvest[goodsId] = checkint(harvest[goodsId]) + data[i].num
	end
end
function PopMainMediator:GetMenuGoods()
	return self.homeData.menuGoods or {}
end
-- 获取菜地的状态
function PopMainMediator:GetFarmStatus()
	local zones = self.homeData.zones or {}
	local num = #zones
	if num == 0 then
		return FARM_STATUS.LOCK_ZONE
	end
	if #zones == 1 then
		local zoneId = checkint(zones[1].zoneId)
		local isClearance = self:CheckZoneIdClearanceByQuestId(zoneId)
		if isClearance then
			return FARM_STATUS.CLEAR_FIRST_ZONE
		else
			local landData = self:GetLandAllData()
			if #landData >= 1 then
				return FARM_STATUS.UNLOCK_FIRST_LAND
			else
				return FARM_STATUS.UNLOCK_FIRST_ZONE
			end
		end
	end
	if #zones == 2 then
		local zoneId = checkint(zones[2].zoneId)
		local isClearance = self:CheckZoneIdClearanceByQuestId(zoneId)
		if isClearance then
			return FARM_STATUS.CLEAR_SECOND_ZONE
		else
			return FARM_STATUS.UNLOCK_SECOND_ZONE
		end
	end
	return FARM_STATUS.LOCK_ZONE
end
function PopMainMediator:GetSummaryId()
	return self.homeData.summaryId
end
function PopMainMediator:BackActivityMediator()
	local router = app:RetrieveMediator("Router")
	router:Dispatch({name = 'NAME'}, {name = 'ActivityMediator', params = {activityId = self.activityId}})
end
function PopMainMediator:OnRegist()
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightHide")
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "allhide")
	regPost(POST.POP_FARM_ZONE_UNLOCK)
	regPost(POST.POP_FARM_PLANT)
	regPost(POST.POP_FARM_LAND_UNLOCK)
	regPost(POST.POP_FARM_MATURE)
end

function PopMainMediator:OnUnRegist()
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightShow")
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "hide")
	unregPost(POST.POP_FARM_ZONE_UNLOCK)
	unregPost(POST.POP_FARM_PLANT)
	unregPost(POST.POP_FARM_LAND_UNLOCK)
	unregPost(POST.POP_FARM_MATURE)
end


return PopMainMediator