--[[
堕神养成管理器
--]]
local Mediator = mvc.Mediator
local PetDevelopMediator = class("PetDevelopMediator", Mediator)
local NAME = "PetDevelopMediator"

------------ import ------------
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local timerMgr = AppFacade.GetInstance():GetManager("TimerManager")
local petMgr = AppFacade.GetInstance():GetManager("PetManager")

if nil == SortOrder then
	require('common.CommonSortBoard')
end

local PetDevelopCommand = require('Game.command.PetDevelopCommand')
------------ import ------------

------------ define ------------
local PetModuleType = {
	PURGE 			= 1, -- 灵体净化
	DEVELOP 		= 2, -- 堕神养成
	SMELTING 		= 3  -- 堕神熔炼
}

local WateringConfig = {
	MAX_WATERING_VALUE = 50,
	BASE_WATERING_VALUE = 10
}

-- 堕神排序规则
local PetSortRule = {
	DEFAULT 		= 0, -- 默认规则
	QUALITY 		= 1, -- 品质
	LEVEL 			= 2, -- 等级
	BREAK_LEVEL 	= 3  -- 强化等级
}

local PET_DEVELOP_FIRST_ID = 210023 --堕神养成需要在第一位置的id影响引导

-- -- 培养皿数据结构
-- local PurgePodData = {
-- 	--[[
-- 	@params pondId int 培养皿id
-- 	@params petEggId int 灵体id
-- 	@params nutrition int 营养值
-- 	@params magicFoods string 魔法菜品 逗号分隔
-- 	@params cdTime int 净化剩余时间 s
-- 	--]]
-- 	New = function (pondId, petEggId, nutrition, magicFoods, cdTime)
-- 		local this = {}
-- 		setmetatable(this, {__index = PurgePodData})

-- 		this.pondId = pondId
-- 		this.petEggId = petEggId
-- 		this.nutrition = nutrition
-- 		this.magicFoods = magicFoods
-- 		this.cdTime = cdTime

-- 		return this
-- 	end,
-- 	SetEmpty = function (self)
-- 		self.petEggId = nil
-- 	end
-- }
------------ define ------------

--[[
constructor
--]]
function PetDevelopMediator:ctor(params, viewComponent)
	Mediator.ctor(self, NAME, viewComponent)

	------------ 堕神净化data ------------
	self.purgePodsData = params.petPonds
	-- self.petEggsData = gameMgr:GetAllGoodsDataByGoodsType(GoodsType.TYPE_PET_EGG)
	self:UpdatePetEggsDataBySortRule(PetSortRule.QUALITY, SortOrder.ASC)
	self.freeWateringTime = checkint(params.freeTime)
	self.purgePodTimeCounters = {}
	------------ 堕神净化data ------------

	------------ 堕神养成data ------------
	self.petDevelopSortRule = PetSortRule.LEVEL
	self.petDevelopSortOrder = SortOrder.DESC
	self:UpdatePetsDataBySortRule(self.petDevelopSortRule, self.petDevelopSortOrder)
	------------ 堕神养成data ------------

	self.selectedModuleType = nil

	-- debug --
	-- self.purgePodsData = {
	-- 	petPonds = {
	-- 		['1'] = {pondId = 1, petEggId = 240002, cleanTime = 5678},
	-- 		['2'] = {pondId = 2, petEggId = 240003, cleanTime = 0},
	-- 		['3'] = {}
	-- 	}
	-- }
	-- debug --
end
---------------------------------------------------
-- mediator extend begin --
---------------------------------------------------
function PetDevelopMediator:InterestSignals()
	local signals = {
		------------ server ------------
		SIGNALNAMES.Pet_Develop_Pet_Pond_Unlock_Callback, 			-- 解锁培养皿信号
		SIGNALNAMES.Pet_Develop_Pet_Pet_Awaken, 					-- 唤醒信号
		SIGNALNAMES.Pet_Develop_Pet_Pet_Egg_Into_Pond, 				-- 堕神进入净化池信号
		SIGNALNAMES.Pet_Develop_Pet_Pet_Clean, 						-- 领取堕神信号
		SIGNALNAMES.Pet_Develop_Pet_Pet_Clean_All, 				    -- 领取全部堕神信号
		SIGNALNAMES.Pet_Develop_Pet_Pet_Egg_Watering, 				-- 浇水信号
		SIGNALNAMES.Pet_Develop_Pet_AddMagicFoodPond, 				-- 添加魔法菜品信号
		SIGNALNAMES.Pet_Develop_Pet_Accelerate_Pet_Clean, 			-- 加速净化信号
		SIGNALNAMES.Pet_Develop_Pet_PetLock, 						-- 锁定堕神信号
		SIGNALNAMES.Pet_Develop_Pet_PetUnlock, 						-- 解锁堕神信号
		SIGNALNAMES.Pet_Develop_Pet_PetRelease, 					-- 堕神放生信号
		SGL.GO_TO_SMELTING_EVENT,
		------------ local ------------
		'PET_PURGE_POD_CLICK_CALLBACK', 							-- 培养皿点击事件
		'BUY_PURGE_POD', 											-- 购买培养皿事件
		'PET_EGG_AWAKE_CLICK_CALLBACK', 							-- 直接唤醒灵体按钮回调
		'PET_EGG_PURGE_CLICK_CALLBACK', 							-- 堕神净化按钮回调
		'DRAW_PET_AFTER_PURGE', 									-- 领取净化完成的堕神事件
		'WATERING_CLICK_CALLBACK', 									-- 浇灌按钮回调
		'ACCELERATE_PURGE_CLICK_CALLBACK', 							-- 加速按钮回调
		'CHECK_MAGIC_FOOD_CLICK_CALLBACK', 							-- 魔法菜品按钮回调
		'CHOOSE_A_MAGIC_FOOD', 										-- 选择了一个魔菜
		'SHOW_PET_EGG_DETAIL', 										-- 显示堕神蛋可能出现的详情
		'LOCK_PET', 												-- 锁定堕神
		'DELETE_PET', 												-- 放生堕神
		'DELETE_ONE_KIND_PET', 										-- 删除一个种类的堕神
		'PET_PURGE_SORT', 											-- 灵体排序
		'PET_DEVELOP_SORT', 										-- 堕神排序
		'PET_PURGE_POD_All_CLICK_CALLBACK', 						-- 领取全部堕神的事件
		EVENT_UPGRADE_LEVEL, 										-- 堕神升级成功
		EVENT_UPGRADE_BREAK, 										-- 堕神强化成功
		EVENT_UPGRADE_PROP, 										-- 堕神洗炼成功
		EVENT_UPGRADE_EVOLUTION, 										-- 堕神洗炼成功
		'REFRESH_NOT_CLOSE_GOODS_EVENT',							-- 引导前接受奖励
		'SHARE_BUTTON_BACK_EVENT' 									-- 分享界面返回按钮回调
	}
	return signals
end
function PetDevelopMediator:ProcessSignal( signal )
	local name = signal:GetName()
	local responseData = signal:GetBody()

	------------ server ------------
	if SIGNALNAMES.Pet_Develop_Pet_Pond_Unlock_Callback == name then

		-- 购买成功
		self:BuyPurgePodCallback(responseData)

	elseif SIGNALNAMES.Pet_Develop_Pet_Pet_Awaken == name then

		-- 直接唤醒灵体
		self:AwakePetEggCallback(responseData)

	elseif SIGNALNAMES.Pet_Develop_Pet_Pet_Egg_Into_Pond == name then

		-- 灵体进入净化皿
		self:PurgePetEggCallback(responseData)

	elseif SIGNALNAMES.Pet_Develop_Pet_Pet_Clean == name then

		-- 领取净化完成的堕神回调
		self:DrawPetAfterPurgeCallback(responseData)
	elseif SIGNALNAMES.Pet_Develop_Pet_Pet_Clean_All == name then

		-- 领取净化完成的堕神回调
		self:DrawAllPetAfterPurgeCallback(responseData)
	elseif SIGNALNAMES.Pet_Develop_Pet_Pet_Egg_Watering == name then

		-- 浇水成功回调
		self:WateringCallback(responseData)

	elseif SIGNALNAMES.Pet_Develop_Pet_Accelerate_Pet_Clean == name then

		-- 加速成功回调
		self:AcceleratePurgeCallback(responseData)

	elseif SIGNALNAMES.Pet_Develop_Pet_AddMagicFoodPond == name then

		-- 添加魔菜回调
		self:ChooseMagicFoodCallback(responseData)

	elseif SIGNALNAMES.Pet_Develop_Pet_PetLock == name then

		-- 锁定成功回调
		self:LockPetCallback(responseData, true)

	elseif SIGNALNAMES.Pet_Develop_Pet_PetUnlock == name then

		-- 解锁成功回调
		self:LockPetCallback(responseData, false)

	elseif SIGNALNAMES.Pet_Develop_Pet_PetRelease == name then

		-- 锁定堕神处理

		local playerPetId = responseData.requestData.playerPetId
		local x, y = string.find(playerPetId , ",")
		if x  then
			self:DeleteOneKindPetCallback(responseData)
		else
			self:DeletePetCallback(responseData)
		end
	------------ local ------------
	elseif 'PET_PURGE_POD_CLICK_CALLBACK' == name then

		-- 点击培养皿事件
		self:PurgePodClickCallback(responseData)
	elseif 'PET_PURGE_POD_All_CLICK_CALLBACK' == name then

		-- 点击培养皿事件
		self:PurgePodDrawAllClickCallback(responseData)
	elseif 'BUY_PURGE_POD' == name then

		-- 购买培养皿事件
		self:BuyPurgePod(responseData)

	elseif 'PET_EGG_AWAKE_CLICK_CALLBACK' == name then

		-- 直接唤醒灵体事件
		self:AwakePetEgg(responseData)

	elseif 'PET_EGG_PURGE_CLICK_CALLBACK' == name then

		-- 净化灵体事件
		self:PurgePetEgg(responseData)

	elseif 'DRAW_PET_AFTER_PURGE' == name then

		-- 领取堕神事件
		self:DrawPetAfterPurge(responseData)

	elseif 'WATERING_CLICK_CALLBACK' == name then

		-- 浇灌事件
		self:Watering(responseData)

	elseif 'ACCELERATE_PURGE_CLICK_CALLBACK' == name then

		-- 加速事件
		self:AcceleratePurge(responseData)

	elseif 'CHECK_MAGIC_FOOD_CLICK_CALLBACK' == name then

		-- 添加魔法菜品事件
		self:CheckMagicFood(responseData)

	elseif 'CHOOSE_A_MAGIC_FOOD' == name then

		-- 确认选择了魔菜
		self:ChooseMagicFood(responseData)

	elseif 'SHOW_PET_EGG_DETAIL' == name then

		-- 显示堕神蛋可能出现的详情
		self:ShowPetEggDetailLayer(responseData)

	elseif 'LOCK_PET' == name then

		-- 锁定堕神处理
		self:LockPet(responseData)

	elseif 'DELETE_PET' == name then

		-- 锁定堕神处理
		self:DeletePet(responseData)
	elseif 'DELETE_ONE_KIND_PET' == name then

		-- 锁定堕神处理
		self:DeleteOneKindPet(responseData)

	elseif 'PET_PURGE_SORT' == name then

		-- 灵体排序
		self:SortPetEggs(responseData)

	elseif 'PET_DEVELOP_SORT' == name then

		-- 堕神排序
		self:SortPets(responseData)

	elseif EVENT_UPGRADE_LEVEL == name then

		-- 堕神升级处理
		self:PetUpgradeLevelHandler(responseData)

	elseif EVENT_UPGRADE_BREAK == name then

		-- 堕神强化处理
		self:PetUpgradeBreakHandler(responseData)

	elseif EVENT_UPGRADE_PROP == name then

		-- 堕神洗炼处理
		self:PetUpgradePropHandler(responseData)
	elseif EVENT_UPGRADE_EVOLUTION == name then
		self:PetUpgradeEvolutionHandler(responseData)

	elseif 'REFRESH_NOT_CLOSE_GOODS_EVENT' == name then
		-- dump('responseData.isGuide')
		-- dump(gameMgr:GetUserInfo().pets)
		if responseData.isGuide then
			-- dump(responseData.isGuide)
			self:UpdatePetEggsDataBySortRule(PetSortRule.QUALITY, SortOrder.ASC)
			self:UpdatePetsDataBySortRule(self.petDevelopSortRule, self.petDevelopSortOrder)
			self.selectedModuleType = nil
			self:RefreshMuduleByModuleType(PetModuleType.PURGE, true)
		end
		-- dump(self.petsData)
	elseif 'SHARE_BUTTON_BACK_EVENT' == name then

		-- 关闭分享界面
		uiMgr:GetCurrentScene():RemoveDialogByTag(5361)
	elseif name ==  SGL.GO_TO_SMELTING_EVENT then
		local mediator = self:GetFacade():RetrieveMediator("PetSmeltingMediator")
		if not  mediator then
			local mediator = require("Game.mediator.PetSmeltingMediator").new()
			self:GetFacade():RegistMediator(mediator)
			self:GetViewComponent():addChild(mediator:GetViewComponent() ,  30 )
			--mediator:GetViewComponent():setVisible(false)
		end
		if self:GetViewComponent().viewData.petPurgeLayer then
			self:GetViewComponent().viewData.petPurgeLayer.ShowSelf(false)
		end
	end
end
function PetDevelopMediator:Initial( key )
	self.super:Initial(key)
end
function PetDevelopMediator:OnRegist()
	-- 初始化网络命令
	self:GetFacade():RegistSignal(COMMANDS.COMMANDS_Pet_Develop_Pet_Home, PetDevelopCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMANDS_Pet_Develop_Pet_Pond_Unlock, PetDevelopCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMANDS_Pet_Develop_Pet_Pet_Awaken, PetDevelopCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMANDS_Pet_Develop_Pet_Pet_EggIntoPond, PetDevelopCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMANDS_Pet_Develop_Pet_Pet_Clean, PetDevelopCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMANDS_Pet_Develop_Pet_Pet_Clean_All, PetDevelopCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMANDS_Pet_Develop_Pet_PetEggWatering, PetDevelopCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMANDS_Pet_Develop_AcceleratePetClean, PetDevelopCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMANDS_Pet_Develop_Pet_AddMagicFoodPond, PetDevelopCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMANDS_Pet_Develop_Pet_PetLock, PetDevelopCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMANDS_Pet_Develop_Pet_PetUnlock, PetDevelopCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMANDS_Pet_Develop_Pet_PetRelease, PetDevelopCommand)

	--新的引导逻辑如果不存在引导，需要触发引导的问题
	GuideUtils.GetDirector():PetDevelopGuide()

	-- 初始化界面
	self:InitScene()
end
function PetDevelopMediator:OnUnRegist()
	-- 停掉所有定时器
	for k,v in pairs(self.purgePodTimeCounters) do
		self:RemoveAPurgePodTimeCounter(checkint(k))
	end

	--主界面堕神入口红点相关处理
	local tempData = {}
	for k,v in pairs(self.purgePodsData) do
		if v.petEggId then
			table.insert(tempData,v)
		end
	end
	if next(tempData) ~= nil then
		gameMgr:GetUserInfo().showRedPointForPetPurge = true
		sortByMember(tempData, "cdTime", true)
		local t = tempData[1]
		app.badgeMgr:UpdataPetPurgeLeftSeconds( t.cdTime )
	else
		gameMgr:GetUserInfo().showRedPointForPetPurge = false
	end

	self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_Pet_Develop_Pet_Home )
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_Pet_Develop_Pet_Pond_Unlock )
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_Pet_Develop_Pet_Pet_Awaken)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_Pet_Develop_Pet_Pet_EggIntoPond )
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_Pet_Develop_Pet_Pet_Clean)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_Pet_Develop_Pet_PetEggWatering)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_Pet_Develop_AcceleratePetClean)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_Pet_Develop_Pet_AddMagicFoodPond)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_Pet_Develop_Pet_PetLock)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_Pet_Develop_Pet_PetUnlock)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_Pet_Develop_Pet_PetRelease)
end
---------------------------------------------------
-- mediator extend end --
---------------------------------------------------

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化界面
--]]
function PetDevelopMediator:InitScene()
	-- 隐藏顶部状态
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "show")

	-- 创建场景
	local scene = uiMgr:SwitchToTargetScene("Game.views.pet.PetDevelopScene")
	self:SetViewComponent(scene)
	self:InitialActions()

	-- 初始化模块
	self:RefreshMuduleByModuleType(PetModuleType.PURGE, false)
	-- self:RefreshMuduleByModuleType(PetModuleType.DEVELOP, false)
end
--[[
初始化净化层
--]]
function PetDevelopMediator:InitPetPurgeLayer()
	-- 初始化净化界面
	self:GetViewComponent():InitPetPurgeLayer()
	self:InitialActions()


	-- 初始化培养皿
	-- bind handler
	self:GetViewComponent().viewData.petPurgeLayer.poolTableView:setCellUpdateHandler(function(cellIndex, podNode)
		podNode:setTag(cellIndex)
		self:GetViewComponent():RefreshPurgePod(podNode, self.purgePodsData[tostring(cellIndex)])
	end)

	self:GetViewComponent():InitPurgePods(self.purgePodsData)
	-- 初始化净化倒计时
	self:InitPetPurgeTimeCounters()
end
--[[
初始化培养层
--]]
function PetDevelopMediator:InitPetDevelopLayer()
	self:GetViewComponent():InitPetDevelopLayer()
end
--[[
初始化viewComponent中内容
--]]
function PetDevelopMediator:InitialActions()
	local viewData = self:GetViewComponent().viewData

	-- 初始化按钮回调
	for i,v in ipairs(viewData.moduleTabBtns) do
		v:setOnClickScriptHandler(handler(self, self.ModuleTabBtnClickHandler))
	end
end
--[[
初始化倒计时
--]]
function PetDevelopMediator:InitPetPurgeTimeCounters()
	for k,v in pairs(self.purgePodsData) do
		if 0 < checkint(v.cdTime) then
			-- 添加一个倒计时
			self:AddAPurgePodTimeCounter(checkint(v.pondId))
		end
	end
end
--[[
根据排序规则刷新堕神蛋数据
@params sortRule PetSortRule 排序规则
@params sortOrder SortOrder 升降序
--]]
function PetDevelopMediator:UpdatePetEggsDataBySortRule(sortRule, sortOrder)
	self.petEggsData = {}

	local allPetEggsData = gameMgr:GetAllGoodsDataByGoodsType(GoodsType.TYPE_PET_EGG)
	if PetSortRule.QUALITY == sortRule then

		if SortOrder.ASC == sortOrder then

			table.sort(allPetEggsData, function (a, b)
				local qaConfig = CommonUtils.GetConfig('goods', 'petEgg', checkint(a.goodsId)) or {}
				local qbConfig =  CommonUtils.GetConfig('goods', 'petEgg', checkint(b.goodsId)) or {}
				local qa =checkint(qaConfig.quality)
				local qb =checkint(qbConfig.quality)
				if qa < qb then
					return true
				elseif qa > qb then
					return false
				else
					return checkint(a.goodsId) <  checkint(b.goodsId)
				end

			end)

			self.petEggsData = allPetEggsData

		elseif SortOrder.DESC == sortOrder then

			table.sort(allPetEggsData, function (a, b)

				local qa = checkint(CommonUtils.GetConfig('goods', 'petEgg', checkint(a.goodsId)).quality)
				local qb = checkint(CommonUtils.GetConfig('goods', 'petEgg', checkint(b.goodsId)).quality)

				if qa > qb then
					return true
				elseif qa < qb then
					return false
				else
					return checkint(a.goodsId) < checkint(b.goodsId)
				end

			end)

			self.petEggsData = allPetEggsData

		end

	else

		petEggsData = allPetEggsData

	end

end
--[[
根据排序规则刷新管理器堕神数据
@params sortRule PetSortRule 排序规则
@params sortOrder SortOrder 升降序
--]]
function PetDevelopMediator:UpdatePetsDataBySortRule(sortRule, sortOrder)
	self.petsData = {}

	local allPetsData = {}
	for k,v in pairs(gameMgr:GetUserInfo().pets) do
		table.insert(allPetsData, v)
	end

	local judgeSign = 1
	if SortOrder.DESC == sortOrder then
		judgeSign = -1
	end
	if PetSortRule.LEVEL == sortRule then

		table.sort(allPetsData, function (a, b)
			local deltaLevel = checkint(a.level) - checkint(b.level)
			if 0 == deltaLevel then
				local deltaQuality = checkint(petMgr.GetPetQualityByPetId(a.petId)) - checkint(petMgr.GetPetQualityByPetId(b.petId))
				if 0 == deltaQuality then
					local deltaBreakLevel = checkint(a.breakLevel) - checkint(b.breakLevel)
					if 0 == deltaBreakLevel then
						return checkint(a.petId) < checkint(b.petId)
					else
						return deltaBreakLevel * judgeSign < 0
					end
				else
					return deltaQuality * judgeSign < 0
				end
			else
				return deltaLevel * judgeSign < 0
			end
		end)

		-- self.petsData = allPetsData

	elseif PetSortRule.QUALITY == sortRule then

		table.sort(allPetsData, function (a, b)
			local deltaQuality = checkint(petMgr.GetPetQualityByPetId(a.petId)) - checkint(petMgr.GetPetQualityByPetId(b.petId))
			if 0 == deltaQuality then
				local deltaLevel = checkint(a.level) - checkint(b.level)
				if 0 == deltaLevel then
					local deltaBreakLevel = checkint(a.breakLevel) - checkint(b.breakLevel)
					if 0 == deltaBreakLevel then
						return checkint(a.petId) < checkint(b.petId)
					else
						return deltaBreakLevel * judgeSign < 0
					end
				else
					return deltaLevel * judgeSign < 0
				end
			else
				return deltaQuality * judgeSign < 0
			end
		end)

		-- self.petsData = allPetsData

	elseif PetSortRule.BREAK_LEVEL == sortRule then

		table.sort(allPetsData, function (a, b)
			local deltaBreakLevel = checkint(a.breakLevel) - checkint(b.breakLevel)
			if 0 == deltaBreakLevel then
				local deltaLevel = checkint(a.level) - checkint(b.level)
				if 0 == deltaLevel then
					local deltaQuality = checkint(petMgr.GetPetQualityByPetId(a.petId)) - checkint(petMgr.GetPetQualityByPetId(b.petId))
					if 0 == deltaQuality then
						return checkint(a.petId) < checkint(b.petId)
					else
						return deltaQuality * judgeSign < 0
					end
				else
					return deltaLevel * judgeSign < 0
				end
			else
				return deltaBreakLevel * judgeSign < 0
			end
		end)

		-- self.petsData = allPetsData

	else

		-- self.petsData = allPetsData

	end

	------------ 为引导修正一次堕神数据 将指定的一个堕神提到最前 ------------
	if next(allPetsData) ~= nil then
		if not GuideUtils.IsGuiding() then
			--不在引导的过程中
			self.petsData = allPetsData
		else
			local hasMoveFirst = false
			for idx,val in pairs(allPetsData) do
				if (not hasMoveFirst) and checkint(val.petId) == PET_DEVELOP_FIRST_ID then
					hasMoveFirst = true
					table.insert(self.petsData, 1, val)
				else
					table.insert(self.petsData, val)
				end
			end
		end
	end
	------------ 为引导修正一次堕神数据 将指定的一个堕神提到最前 ------------
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- logic control begin --
---------------------------------------------------
--[[
/***********************************************************************************************************************************\
 * pet purge
\***********************************************************************************************************************************/
--]]
--[[
购买培养皿事件
@params data table {
	purgePodId int 培养皿id
}
--]]
function PetDevelopMediator:BuyPurgePod(data)
	local purgePodId = data.purgePodId
	------------ 判断本地道具是否满足购买消耗 ------------
	local purgePodConfig = CommonUtils.GetConfig('pet', 'petPond', purgePodId)
	local costGoodsId = checkint(purgePodConfig.consume)
	local costGoodsAmount = checkint(purgePodConfig.consumeNum)
	local costGoodsConfig = CommonUtils.GetConfig('goods', 'goods', costGoodsId)
	if costGoodsConfig then
		if DIAMOND_ID == costGoodsId then
			if costGoodsAmount > gameMgr:GetUserInfo().diamond then
				-- 幻晶石不足
				if GAME_MODULE_OPEN.NEW_STORE then
					app.uiMgr:showDiamonTips()
				else
					local CommonTip  = require( 'common.NewCommonTip' ).new({text = __('幻晶石不足是否去商城购买？'),
						isOnlyOK = false, callback = function ()
							app.router:Dispatch({name = "HomeMediator"}, {name = "ShopMediator"})
						end})
					CommonTip:setPosition(display.center)
					app.uiMgr:GetCurrentScene():AddDialog(CommonTip)
				end
				return
			end
		elseif GOLD_ID == costGoodsId then
			if costGoodsAmount > gameMgr:GetUserInfo().diamond then
				-- 金币不足
				uiMgr:ShowInformationTips(__('金币不足!!!'))
				return
			end
		else
			if costGoodsAmount > gameMgr.GetAmountByGoodId(costGoodsId) then
				uiMgr:ShowInformationTips(string.format(__('%s不足!!!'), costGoodsConfig.name))
				return
			end
		end
	end
	------------ 判断本地道具是否满足购买消耗 ------------

	------------ 一切就绪 请求服务端 ------------
	self:SendSignal(COMMANDS.COMMANDS_Pet_Develop_Pet_Pond_Unlock, {pondId = purgePodId})
	------------ 一切就绪 请求服务端 ------------

end
--[[
购买培养皿成功
@params responseData table 服务器返回
--]]
function PetDevelopMediator:BuyPurgePodCallback(responseData)
	------------ data ------------
	-- 扣道具
	local purgePodId = responseData.requestData.pondId
	local purgePodConfig = CommonUtils.GetConfig('pet', 'petPond', purgePodId)
	local costGoodsId = checkint(purgePodConfig.consume)
	local costGoodsAmount = checkint(purgePodConfig.consumeNum)
	if 0 ~= costGoodsId then
		CommonUtils.DrawRewards({
			{goodsId = costGoodsId, num = -costGoodsAmount}
		})
	end
	-- 解锁培养皿数据
	self:UnlockPurgePodById(purgePodId)
	------------ data ------------

	------------ view ------------
	-- 弹提示
	uiMgr:ShowInformationTips(__('解锁成功'))
	-- 刷新界面
	self:GetViewComponent():UnlockAPurgePod(purgePodId)
	------------ view ------------
end
--[[
直接唤醒灵体
@params data table {
	petEggId int 灵体id
	amount int 灵体剩余数量
}
--]]
function PetDevelopMediator:AwakePetEgg(data)
	-- 判断堕神数量是否超出堕神上限
	if table.nums(gameMgr:GetUserInfo().pets) >= CommonUtils.getVipTotalLimitByField('petNumLimit') then
		uiMgr:ShowInformationTips(__('堕神数量达到上限 无法唤醒'))
		return
	end

	local limitNum = checkint(CONF.PET.PARMS:GetValue('awakenMaxTimes'))

	local awakePopup = require('Game.views.pet.PetAwakePopup').new({
		title      = __('确定觉醒净化?'),
		descr      = __('觉醒净化可能会失败并损失灵体'),
		numTitle   = __('觉醒数量:'),
		confirmStr = __("觉醒"),
		limitNum   = limitNum,
		maxNum     = math.min(data.amount, CommonUtils.getVipTotalLimitByField('petNumLimit') - table.nums(gameMgr:GetUserInfo().pets), limitNum),
		callback   = function(awakeNum)
			self:AwakePetEggByAmount(data, awakeNum)
		end
	})
	uiMgr:GetCurrentScene():AddDialog(awakePopup)

	-- if self:GetViewComponent():GetShowAwakeWaring() then
	-- 	-- 弹提示
	-- 	local commonTip = require('common.NewCommonTip').new({
	-- 		text = __('直接唤醒可能会失败并消耗灵体 是否继续?'),
	-- 		callback = function ()
	-- 			-- 可以唤醒
	-- 			self:SendSignal(COMMANDS.COMMANDS_Pet_Develop_Pet_Pet_Awaken, {petEggId = data.petEggId, num = 1})
	-- 		end
	-- 	})
	-- 	commonTip:setPosition(display.center)
	-- 	uiMgr:GetCurrentScene():AddDialog(commonTip)

	-- else
	-- 	-- 可以唤醒
	-- 	self:SendSignal(COMMANDS.COMMANDS_Pet_Develop_Pet_Pet_Awaken, {petEggId = data.petEggId, num = 1})
	-- end

end
--[[
根据数量唤醒灵体
@params data table {
	petEggId int 灵体id
	amount int 灵体剩余数量
}
@params amount int 数量
--]]
function PetDevelopMediator:AwakePetEggByAmount(data, amount)
	-- 判断灵体数量
	if amount > checkint(data.amount) then
		uiMgr:ShowInformationTips(__('灵体不足!!!'))
		return
	end

	-- 判断剩余堕神位够不够
	local leftPetAmount = CommonUtils.getVipTotalLimitByField('petNumLimit') - table.nums(gameMgr:GetUserInfo().pets)
	if amount > leftPetAmount then
		uiMgr:ShowInformationTips(__('堕神即将到达数量上限!!!'))
		return
	end

	self:SendSignal(COMMANDS.COMMANDS_Pet_Develop_Pet_Pet_Awaken, {petEggId = data.petEggId, num = amount})
end
--[[
唤醒灵体回调
@params responseData table 服务器返回
--]]
function PetDevelopMediator:AwakePetEggCallback(responseData)
	local amount = 1
	if responseData.requestData then
		if nil ~= responseData.requestData.num then
			amount = checkint(responseData.requestData.num)
		end
	end

	if 1 >= amount then
		self:AwakeAPetEggCallback(responseData)
	else
		self:AwakePetEggsCallback(responseData)
	end
end
--[[
唤醒一个堕神
@params responseData table 服务器返回
--]]
function PetDevelopMediator:AwakeAPetEggCallback(responseData)
	local awakeAmount = checkint(responseData.requestData.num)

	if 0 == checkint(responseData.isRouse) then

		-- 唤醒失败
		uiMgr:ShowInformationTips(__('唤醒失败'))
		self:GetViewComponent():DoAwakeFail()

	elseif 1 == checkint(responseData.isRouse) then

		-- 唤醒成功
		-- 刷新一次本地堕神数据
		self:GetANewPet(responseData.newPet[1])

	else
		print('server back error')
	end

	local currentSelectedPetEggIndex = self:GetViewComponent():GetCurrentSelectedPetEggIndex()

	-- 扣掉本地灵体数量
	local currentPetEggData = self.petEggsData[currentSelectedPetEggIndex]

	-- 选中灵体下一次不再显示警告
	self:GetViewComponent():SetShowAwakeWaring(false)

	-- debug check logic --
	if CC_SHOW_FPS and currentPetEggData.goodsId ~= responseData.requestData.petEggId then
		assert(false, 'we find u awake the pet egg id not equals the currnet selected pet egg id')
	end
	-- debug check logic --


	currentPetEggData.amount = math.max(0, currentPetEggData.amount - awakeAmount)
	if 0 >= currentPetEggData.amount then

		------------ data ------------
		table.remove(self.petEggsData, currentSelectedPetEggIndex)
		------------ data ------------

		------------ view ------------
		-- 刷新一次所有蛋
		self:GetViewComponent():RefreshPetEggs(self.petEggsData)
		-- 为玩家恢复到初始选择状态
		self:GetViewComponent():RefreshPetPurgeCenterByIndex(nil)
		------------ view ------------

	else

		------------ data ------------
		self.petEggsData[currentSelectedPetEggIndex] = currentPetEggData
		------------ data ------------

		------------ view ------------
		-- 刷新一次所有蛋
		self:GetViewComponent():RefreshPetEggs(self.petEggsData)
		------------ view ------------

	end

	-- 刷新一次本地灵体数据
	CommonUtils.DrawRewards({
		{goodsId = currentPetEggData.goodsId, num = -awakeAmount}
	})
end
--[[
批量唤醒堕神
@params responseData table 服务器返回
--]]
function PetDevelopMediator:AwakePetEggsCallback(responseData)
	local awakeAmount = checkint(responseData.requestData.num)

	if 0 == checkint(responseData.isRouse) then

		-- 唤醒失败
		uiMgr:ShowInformationTips(__('全部唤醒失败'))
		self:GetViewComponent():DoBatchAwakeFail()

	elseif 1 == checkint(responseData.isRouse) then

		-- 唤醒成功
		self:GetNewPetsByBatchAwake(awakeAmount, responseData.newPet)

	else
		print('server back error')
	end

	local currentSelectedPetEggIndex = self:GetViewComponent():GetCurrentSelectedPetEggIndex()

	-- 扣掉本地灵体数量
	local currentPetEggData = self.petEggsData[currentSelectedPetEggIndex]

	-- 选中灵体下一次不再显示警告
	self:GetViewComponent():SetShowAwakeWaring(false)

	-- debug check logic --
	if CC_SHOW_FPS and currentPetEggData.goodsId ~= responseData.requestData.petEggId then
		assert(false, 'we find u awake the pet egg id not equals the currnet selected pet egg id')
	end
	-- debug check logic --

	currentPetEggData.amount = math.max(0, currentPetEggData.amount - awakeAmount)
	if 0 >= currentPetEggData.amount then

		------------ data ------------
		table.remove(self.petEggsData, currentSelectedPetEggIndex)
		------------ data ------------

		------------ view ------------
		-- 刷新一次所有蛋
		self:GetViewComponent():RefreshPetEggs(self.petEggsData)
		-- 为玩家恢复到初始选择状态
		self:GetViewComponent():RefreshPetPurgeCenterByIndex(nil)
		------------ view ------------

	else

		------------ data ------------
		self.petEggsData[currentSelectedPetEggIndex] = currentPetEggData
		------------ data ------------

		------------ view ------------
		-- 刷新一次所有蛋
		self:GetViewComponent():RefreshPetEggs(self.petEggsData)
		------------ view ------------

	end

	-- 刷新一次本地灵体数据
	CommonUtils.DrawRewards({
		{goodsId = currentPetEggData.goodsId, num = -awakeAmount}
	})
end
--[[
批量唤醒灵体显示奖励回调
@params batchAwakeAmount int 批量唤醒的总数
@params petsData list 唤醒得到的堕神
--]]
function PetDevelopMediator:GetNewPetsByBatchAwake(batchAwakeAmount, petsData)
	------------ data ------------
	-- 刷一次本地堕神数据
	local fixedPetsGoodsData = {}
	for _, petData in ipairs(petsData) do
		local p_ = {goodsId = petData.petId, num = 1, playerPet = petData}
		table.insert(fixedPetsGoodsData, p_)
	end

	CommonUtils.DrawRewards(fixedPetsGoodsData)
	------------ data ------------

	------------ view ------------
	local title      = string.format(__('本次觉醒%d个灵体 成功觉醒%d个灵体'), batchAwakeAmount, #petsData)
	local rewardsMap = {}
	for _, rewardData in pairs(fixedPetsGoodsData) do
		local goodsId = checkint(rewardData.goodsId)
		if not rewardsMap[goodsId] then
			rewardsMap[goodsId] = {goodsId = goodsId, num = rewardData.num}
		else
			rewardsMap[goodsId].num = rewardsMap[goodsId].num + rewardData.num
		end
	end
	-- uiMgr:AddDialog('common.RewardPopup', {rewards = fixedPetsGoodsData, addBackpack = false, msg = title})
	uiMgr:AddDialog('common.RewardPopup', {rewards = table.values(rewardsMap), addBackpack = false})
	------------ view ------------
end
--[[
进入净化皿回调
@params data table {
	petEggId int 灵体id
	amount int 灵体剩余数量
}
--]]
function PetDevelopMediator:PurgePetEgg(data)
	-- 查找一个空的净化皿
	local emptyPodId = self:GetAEmptyPurgePodId()
	if nil == emptyPodId then
		-- 净化皿为空
		uiMgr:ShowInformationTips(__('没有空闲的净化池'))
		GuideUtils.EnableShowSkip() --是否显示引导的逻辑
		return
	end

	local emptyPurgePodAmount = self:GetEmptyPurgePodAmount()

	local singleAmount = 1
	local batchAmount = math.min(emptyPurgePodAmount, checkint(data.amount))
	if 1 >= batchAmount then
		-- 没必要弹窗，直接单抽
		self:SendSignal(COMMANDS.COMMANDS_Pet_Develop_Pet_Pet_EggIntoPond, {petEggId = data.petEggId, pondId = emptyPodId})
		return
	end
	local commonTip = require('common.NewCommonTip').new({
		text 				= __('确定净化?'),
		btnTextL 			= string.format(__('净化%d个'), singleAmount),
		btnTextR 			= string.format(__('净化%d个'), batchAmount),
		cancelBack 			= function ()
			-- 净化一个
			self:SendSignal(COMMANDS.COMMANDS_Pet_Develop_Pet_Pet_EggIntoPond, {petEggId = data.petEggId, pondId = emptyPodId})
		end,
		callback 			= function ()
			-- 净化多个（传0代表一次净化最大数量）
			self:SendSignal(COMMANDS.COMMANDS_Pet_Develop_Pet_Pet_EggIntoPond, {petEggId = data.petEggId, pondId = 0})
		end
	})
	commonTip:setPosition(display.center)
	uiMgr:GetCurrentScene():AddDialog(commonTip)
end
--[[
进入净化皿回调
@params responseData table 服务器返回
--]]
function PetDevelopMediator:PurgePetEggCallback(responseData)
	if checkint(responseData.requestData.pondId) ~= 0 then
		-- 净化一个
		self:PurgeAPetEggCallback(responseData)
	else
		-- 批量净化
		self:PurgePetEggsCallback(responseData)
	end
end
--[[
净化一个灵体回调
@params responseData table 服务器返回
--]]
function PetDevelopMediator:PurgeAPetEggCallback(responseData)
	------------ data ------------
	-- 刷新培养皿数据
	local purgePodId = responseData.requestData.pondId
	if nil ~= self:GetPurgePodDataById(purgePodId) then
		local newPurgePodData = {
			pondId = purgePodId,
			petEggId = responseData.requestData.petEggId,
			nutrition = 0,
			magicFoods = nil,
			cdTime = responseData.cdTime
		}
		self:UpdatePurgePodDataById(purgePodId, newPurgePodData)
	end
	-- 消耗灵体
	local currentSelectedPetEggIndex = responseData.currentSelectedPetEggIndex or self:GetViewComponent():GetCurrentSelectedPetEggIndex()
	if not currentSelectedPetEggIndex then return end
	local currentPetEggData = self.petEggsData[currentSelectedPetEggIndex]



	currentPetEggData.amount = currentPetEggData.amount - 1
	CommonUtils.DrawRewards({
		{goodsId = currentPetEggData.goodsId, num = -1}
	})

	if 0 >= currentPetEggData.amount then

		------------ data ------------
		table.remove(self.petEggsData, currentSelectedPetEggIndex)
		------------ data ------------
	else

		------------ data ------------
		self.petEggsData[currentSelectedPetEggIndex] = currentPetEggData
		------------ data ------------
	end

	-- 添加一个倒计时
	self:AddAPurgePodTimeCounter(purgePodId)
	------------ data ------------

	------------ view ------------
	-- 刷新培养皿状态
	self:GetViewComponent():RefreshPurgePodById(purgePodId, self:GetPurgePodDataById(purgePodId))
	-- 刷新一次所有蛋状态
	self:GetViewComponent():RefreshPetEggs(self.petEggsData)
	-- 刷新净化池状态
	if not responseData.currentSelectedPetEggIndex then 
		--净化一个才要刷新，批量净化最后统一刷新，不然会有问题
		self:GetViewComponent():RefreshCenterPurgePoolByIndex(checkint(purgePodId), self:GetPurgePodDataById(purgePodId), self.freeWateringTime)
	end
	------------ view ------------

	GuideUtils.DispatchStepEvent()
end
--[[
批量净化灵体回调
@params responseData table 服务器返回
--]]
function PetDevelopMediator:PurgePetEggsCallback(responseData)
	local emptyPurgePodList = self:GetEmptyPurgePodList()
	local currentSelectedPetEggIndex = self:GetViewComponent():GetCurrentSelectedPetEggIndex()
	local purgePodId = 1
	local amount = checkint(self.petEggsData[currentSelectedPetEggIndex].amount) -- 获取数量
	for i, pondId in ipairs(emptyPurgePodList) do
		if amount <= 0 then
			break
		end
		self:PurgeAPetEggCallback(
			{
				cdTime = responseData.cdTime,
				currentSelectedPetEggIndex = currentSelectedPetEggIndex,
				requestData = {
					pondId = pondId,
					petEggId = responseData.requestData.petEggId
				}
			}
		)
		amount = amount - 1
		purgePodId = pondId
	end
	-- 最后刷新净化池状态
	self:GetViewComponent():RefreshCenterPurgePoolByIndex(purgePodId, self:GetPurgePodDataById(purgePodId), self.freeWateringTime)
end
--[[
领取堕神事件
@params data table {
	purgePodId int 培养皿id
}
--]]
function PetDevelopMediator:DrawPetAfterPurge(data)
	-- 判断堕神数量是否超出堕神上限
	if table.nums(gameMgr:GetUserInfo().pets) >= CommonUtils.getVipTotalLimitByField('petNumLimit') then
		uiMgr:ShowInformationTips(__('堕神数量达到上限。。。'))
		return
	end

	self:SendSignal(COMMANDS.COMMANDS_Pet_Develop_Pet_Pet_Clean, {pondId = data.purgePodId})
end
--[[
领取净化完成的堕神回调
@params responseData table 服务器返回
--]]
function PetDevelopMediator:DrawPetAfterPurgeCallback(responseData)
	------------ data ------------
	-- 置空上一个培养皿
	local purgePodId = responseData.requestData.pondId
	self:SetPurgePodEmptyById(purgePodId)
	self:GetANewPet(responseData.newPet)
	------------ data ------------

	------------ view ------------
	-- 刷新一次顶部培养皿状态
	self:GetViewComponent():RefreshPurgePodById(purgePodId, self:GetPurgePodDataById(purgePodId))
	-- 刷新顶部培养皿选中状态
	self:GetViewComponent():RefreshCenterPurgePoolByIndex(nil)
	------------ view ------------
	GuideUtils.DispatchStepEvent()
end
--[[
领取所有净化完成的堕神回调
@params responseData table 服务器返回
--]]
function  PetDevelopMediator:DrawAllPetAfterPurgeCallback(responseData)
	local newPets = responseData.newPets
	local pets = {}
	for purgePodId , petData in pairs(newPets) do
		self:SetPurgePodEmptyById(purgePodId)
		------------ view ------------
		-- 刷新一次顶部培养皿状态
		self:GetViewComponent():RefreshPurgePodById(purgePodId, self:GetPurgePodDataById(purgePodId))

		local petRewardData = {goodsId = petData.petId, num = 1, playerPet = petData}
		pets[#pets+1] = petRewardData
		-- 刷新顶部培养皿选中状态
		--self:GetANewPet(responseData.petData)
	end
	self:GetViewComponent():RefreshCenterPurgePoolByIndex(nil)
	uiMgr:AddDialog('common.RewardPopup' , { rewards = pets})
end
--[[
浇灌
@params data table {
	purgePodId int 净化皿id
}
--]]
function PetDevelopMediator:Watering(data)
	local purgePodId = checkint(data.purgePodId)
	-- 判断是否可以浇灌
	if 0 >= self.freeWateringTime then
		if 0 >= gameMgr:GetAmountByGoodId(PET_DEVELOP_WATERING_ID) then
			uiMgr:ShowInformationTips(__('浇水需要的道具不足!!'))
			return
		end
	end
	if WateringConfig.MAX_WATERING_VALUE <= checkint(self:GetPurgePodDataById(purgePodId).nutrition) then
		uiMgr:ShowInformationTips(__('满了 不需要浇水!!!'))
		return
	end
	if 0 >= checkint(self:GetPurgePodDataById(purgePodId).cdTime) then
		uiMgr:ShowInformationTips(__('净化结束 无法浇水!!!'))
		return
	end

	-- 可以浇灌 发送信号
	self:SendSignal(COMMANDS.COMMANDS_Pet_Develop_Pet_PetEggWatering, {pondId = purgePodId})
end
--[[
成功浇水回调
@params responseData table 服务器返回
--]]
function PetDevelopMediator:WateringCallback(responseData)
	------------ data ------------
	local purgePodId = checkint(responseData.requestData.pondId)

	-- 判断是否解锁魔法菜品
	local preWateringValue = checkint(self:GetPurgePodDataById(purgePodId).nutrition)
	local deltaWateringValue = checkint(responseData.nutrition)
	local curWateringValue = math.min(WateringConfig.MAX_WATERING_VALUE, preWateringValue + deltaWateringValue)

	local magicFoodUnlockConfig = CommonUtils.GetConfigAllMess('petMagicFoodUnlock', 'pet')
	for k, v in pairs(magicFoodUnlockConfig) do
		if preWateringValue < checkint(v.nutritionNum) and curWateringValue >= checkint(v.nutritionNum) then
			-- 解锁魔法菜品槽
			self:GetViewComponent():UnlockAMagicFoodSlot(checkint(v.id))
		end
	end

	-- 刷新消耗
	if 0 >= self.freeWateringTime then
		-- 消耗道具
		CommonUtils.DrawRewards({
			{goodsId = PET_DEVELOP_WATERING_ID, num = -1}
		})
	end
	-- 刷新剩余浇灌次数
	self.freeWateringTime = checkint(responseData.freeTime)

	-- 刷新本地培养皿数据
	local newPurgePodData = {
		nutrition = curWateringValue
	}
	self:UpdatePurgePodDataById(purgePodId, newPurgePodData)
	------------ data ------------

	------------ view ------------
	-- 做动画
	self:GetViewComponent():DoPurgeWatering(WateringConfig.BASE_WATERING_VALUE < deltaWateringValue)
	-- 刷新界面
	self:GetViewComponent():RefreshWateringBar(self:GetPurgePodDataById(purgePodId).nutrition, self.freeWateringTime)

	-- if WateringConfig.BASE_WATERING_VALUE < deltaWateringValue then
	-- 	uiMgr:ShowInformationTips(__('!!!浇水成功 暴     击 暂无动画!!!'))
	-- else
	-- 	uiMgr:ShowInformationTips(__('!!!浇水成功 暂无动画!!!'))
	-- end
	------------ view ------------
end
--[[
加速净化
@params data table {
	purgePodId int 净化皿id
}
--]]
function PetDevelopMediator:AcceleratePurge(data)
	local purgePodId = data.purgePodId
	-- 计算消耗
	local costGoodsId, costGoodsAmount = self:GetViewComponent():GetAccelerateCost(checkint(checktable(self:GetPurgePodDataById(purgePodId)).cdTime))
	local costGoodsConfig = CommonUtils.GetConfig('goods', 'goods', costGoodsId)

	if costGoodsAmount > gameMgr:GetAmountByIdForce(costGoodsId) then
		uiMgr:ShowInformationTips(string.format(__('%s不足 需要%d!!!'), costGoodsConfig.name, costGoodsAmount))
		--如果是在引导过程中加速的时候，材料不足时显示跳过
		GuideUtils.EnableShowSkip() --是否显示引导的逻辑
		return
	end

	-- 弹提示
	local commonTip = require('common.NewCommonTip').new({
		text = string.format(__('是否消耗%d%s加速灵体净化?'), costGoodsAmount, costGoodsConfig.name),
		callback = function ()
			-- 可以加速
			self:SendSignal(COMMANDS.COMMANDS_Pet_Develop_AcceleratePetClean, {pondId = purgePodId})
		end
	})
	commonTip:setName('NewCommonTip')
	commonTip:setPosition(display.center)
	uiMgr:GetCurrentScene():AddDialog(commonTip)
	GuideUtils.DispatchStepEvent()
end
--[[
加速净化成功回调
@params responseData table 服务器返回
--]]
function PetDevelopMediator:AcceleratePurgeCallback(responseData)
	local purgePodId = responseData.requestData.pondId
	------------ data ------------
	-- 刷新幻晶石
	CommonUtils.DrawRewards({
		{goodsId = DIAMOND_ID, num = checkint(responseData.diamond) - gameMgr:GetUserInfo().diamond}
	})
	-- 刷新本地培养皿数据
	local newPurgePodData = {
		cdTime = 0
	}
	self:UpdatePurgePodDataById(purgePodId, newPurgePodData)
	-- 移除一个倒计时
	self:RemoveAPurgePodTimeCounter(purgePodId)
	------------ data ------------

	------------ view ------------
	-- uiMgr:ShowInformationTips(__('!!!加速净化成功 暂无动画!!!'))
	-- 刷新顶部培养皿
	self:GetViewComponent():RefreshPurgePodById(purgePodId, self:GetPurgePodDataById(purgePodId))
	-- 刷新界面
	self:GetViewComponent():RefreshCenterPurgePoolCounter(checkint(self:GetPurgePodDataById(purgePodId).cdTime))
	-- 做动画
	self:GetViewComponent():DoAccelerate()
	------------ view ------------

	GuideUtils.DispatchStepEvent()
end
--[[
魔法菜品事件回调
@params data table {
	purgePodId int 培养皿id
	magicFoodSlotIndex int 插槽序号
}
--]]
function PetDevelopMediator:CheckMagicFood(data)
	local purgePodId = data.purgePodId
	local purgePodData = self:GetPurgePodDataById(purgePodId)
	local magicFoodSlotIndex = data.magicFoodSlotIndex
	local magicFoodId = self:GetMagicFoodIdByPodIdAndSlotIdx(purgePodId, magicFoodSlotIndex)

	if nil ~= magicFoodId then

		-- 显示魔菜tips
		uiMgr:ShowInformationTipsBoard({
			targetNode = self:GetViewComponent().viewData.petPurgeLayer.magicFoodBtn[checkint(magicFoodSlotIndex)],
			iconId = self:GetMagicFoodIdByPodIdAndSlotIdx(purgePodId, magicFoodSlotIndex),
			type = 1
		})
		return

	else
		-- 为空 进一步判断
		if 0 >= checkint(purgePodData.cdTime) then

			-- 时间已到无法添加菜品
			uiMgr:ShowInformationTips(__('净化结束 无法再添加菜品'))
			return

		else

			-- 时间没到 判断营养值是否满足条件
			local magicFoodUnlockConfig = CommonUtils.GetConfig('pet', 'petMagicFoodUnlock', magicFoodSlotIndex)
			if checkint(magicFoodUnlockConfig.nutritionNum) <= checkint(purgePodData.nutrition) then
				-- 营养值满足 弹添加魔菜弹窗
				AppFacade.GetInstance():DispatchObservers(EVENT_CHOOSE_A_GOODS_BY_TYPE, {
					goodsType = GoodsType.TYPE_MAGIC_FOOD,
					callbackSignalName = 'CHOOSE_A_MAGIC_FOOD',
					parameter = data,
					except = self:GetNotMagicFoods(),
					showWaring = true,
					waringText = __('是否确认添加魔法菜品? 添加后无法改变!')
				})
			else
				-- 营养值不满足
				uiMgr:ShowInformationTips(__('浇灌值不足 无法添加魔法菜品'))
				return
			end

		end
	end
end
--[[
选择了魔菜
@params data table {
	purgePodId int 培养皿id
	magicFoodSlotIndex int 插槽序号
	goodsId int 魔菜id
}
--]]
function PetDevelopMediator:ChooseMagicFood(data)
	-- 添加魔菜 请求服务器
	self:SendSignal(COMMANDS.COMMANDS_Pet_Develop_Pet_AddMagicFoodPond,
			{pondId = data.purgePodId, magicFoodUnlockId = data.magicFoodSlotIndex, magicFoodId = data.goodsId})
end
--[[
选择了魔菜服务器回调
@params responseData table 服务器返回
--]]
function PetDevelopMediator:ChooseMagicFoodCallback(responseData)
	local purgePodId = responseData.requestData.pondId
	local magicSlotIndex = responseData.requestData.magicFoodUnlockId
	------------ data ------------
	-- 刷新魔菜数据
	local newPurgePodData = {
		magicFoods = responseData.magicFoods
	}
	self:UpdatePurgePodDataById(responseData.requestData.pondId, newPurgePodData)

	-- 刷新本地魔菜数据
	CommonUtils.DrawRewards({
		{goodsId = responseData.requestData.magicFoodId, num = -1}
	})
	------------ data ------------

	------------ view ------------
	-- 刷新界面
	self:GetViewComponent():RefreshAMagicFoodSlot(
			magicSlotIndex,
			checkint(self:GetPurgePodDataById(purgePodId).nutrition),
			self:GetMagicFoodIdByPodIdAndSlotIdx(purgePodId, magicSlotIndex))

	uiMgr:ShowInformationTips(__('添加成功!!!'))
	------------ view ------------
end
--[[
获得新的堕神
@params petData table 堕神信息
--]]
function PetDevelopMediator:GetANewPet(petData)
	-- debug --
	-- uiMgr:ShowInformationTips(__('!!!获得新堕神 暂无动画!!!'))
	local layer = require('common.RewardPopupSingle').new({
		viewType = 1,
		goodsId = checkint(petData.petId),
		bonusInfo = {
			petCharacterId = checkint(petData.character)
		}
	})
	layer:setName('RewardPopupSingle')
	layer:setAnchorPoint(cc.p(0.5, 0.5))
	layer:setPosition(cc.p(display.cx, display.cy))
	uiMgr:GetCurrentScene():AddDialog(layer)

	-- 添加分享
	-- local shareNode = require('common.ShareNode').new({visitNode = layer})
	-- display.commonUIParams(shareNode, {po = cc.p(display.cx, display.cy)})
	-- layer:addChild(shareNode, 999)
	-- debug --

	local petRewardData = {goodsId = petData.petId, num = 1, playerPet = petData}

	CommonUtils.DrawRewards({
		petRewardData
	})
end
--[[
添加一个倒计时
@params purgePodId int 培养皿id
--]]
function PetDevelopMediator:AddAPurgePodTimeCounter(purgePodId)
	local purgePodData = self:GetPurgePodDataById(purgePodId)
	local timerName = self:GetPurgePodTimerNameByPurgePodId(purgePodId)
	timerMgr:AddTimer({
		name = timerName,
		countdown = checkint(purgePodData.cdTime),
		callback = handler(self, self.PurgePodTimeCounter),
		datas = {
			purgePodId = purgePodId
		}
	})
	self.purgePodTimeCounters[tostring(purgePodId)] = true
end
--[[
移除一个倒计时
@params purgePodId int 培养皿id
--]]
function PetDevelopMediator:RemoveAPurgePodTimeCounter(purgePodId)
	local timerName = self:GetPurgePodTimerNameByPurgePodId(purgePodId)
	timerMgr:StopTimer(timerName)
	timerMgr:RemoveTimer(timerName)
	self.purgePodTimeCounters[tostring(purgePodId)] = nil
end
--[[
培养皿时间倒计时逻辑
--]]
function PetDevelopMediator:PurgePodTimeCounter(countdown, remindTag, timeNum, datas)
	local purgePodId = checkint(datas.purgePodId)

	------------ data ------------
	-- 刷新倒计时
	-- local newCDTime = math.max(0, checkint(self:GetPurgePodDataById(purgePodId).cdTime) - 1)
	local newCDTime = math.max(0,countdown)

	-- 如果倒计时为0 删除timer
	if 0 >= newCDTime then
		self:RemoveAPurgePodTimeCounter(purgePodId)
	end

	local newPurgePodData = {
		cdTime = newCDTime
	}
	self:UpdatePurgePodDataById(purgePodId, newPurgePodData)
	------------ data ------------

	------------ view ------------
	-- 刷新界面倒计时
	local purgePod = self:GetViewComponent():GetPurgePodNodeByPurgePodId(purgePodId)
	if nil ~= purgePod then
		self:GetViewComponent():RefreshPurgePodByCounter(purgePod, newCDTime)
	end

	-- 刷新净化池中间倒计时
	if purgePodId == self:GetViewComponent():GetCurrentSelectedPurgePodIndex() then
		-- print('here check fuck select pod index>>>>>>>>>>>>>?', purgePodId, self:GetViewComponent():GetCurrentSelectedPurgePodIndex())
		self:GetViewComponent():RefreshCenterPurgePoolCounter(newCDTime)
	end
	------------ view ------------

end
--[[
显示堕神蛋可能出现的详情
@params data table {
	show bool 是否显示
	selectedPetEggIndex int 选择的蛋序号 or selectedPurgePodIndex int 选择的培养皿序号
}
--]]
function PetDevelopMediator:ShowPetEggDetailLayer(data)
	local petEggId = nil
	if data.selectedPetEggIndex then
		local petEggData = self.petEggsData[data.selectedPetEggIndex]
		if petEggData then
			petEggId = petEggData.goodsId
		end
	elseif data.selectedPurgePodIndex then
		local purgePodData = self:GetPurgePodDataById(data.selectedPurgePodIndex)
		if purgePodData then
			petEggId = purgePodData.petEggId
		end
	end

	self:GetViewComponent():ShowPetEggDetailLayer(petEggId, data.show)
end
--[[
为灵体排序
@params data table {
	sortType PetSortRule 排序规则
	sortOrder SortOrder 升降序规则
}
--]]
function PetDevelopMediator:SortPetEggs(data)
	local sortType = data.sortType
	local sortOrder = data.sortOrder
	local selectedPetEggIndex = self:GetViewComponent():GetCurrentSelectedPetEggIndex()
	local selectedPetEggData = nil
	if nil ~= selectedPetEggIndex then
		selectedPetEggData = self.petEggsData[selectedPetEggIndex]
	end

	------------ data ------------
	-- 刷新堕神蛋数据
	self:UpdatePetEggsDataBySortRule(sortType, sortOrder)
	-- 刷新选中序号
	if nil ~= selectedPetEggIndex and nil ~= selectedPetEggData then
		for i,v in ipairs(self.petEggsData) do
			if checkint(v.goodsId) == checkint(selectedPetEggData.goodsId) then
				selectedPetEggIndex = i
				break
			end
		end
	end
	self:GetViewComponent().selectedPetEggIndex = selectedPetEggIndex
	------------ data ------------

	------------ view ------------
	-- 刷新一次所有蛋
	self:GetViewComponent():RefreshPetEggs(self.petEggsData, true)
	------------ view ------------
end
--[[
/***********************************************************************************************************************************\
 * pet develop
\***********************************************************************************************************************************/
--]]
--[[
堕神上锁处理
@params data table {
	id int 堕神id
}
--]]
function PetDevelopMediator:LockPet(data)
	local id = data.id
	if nil == id then
		uiMgr:ShowInformationTips(__('请选择一个堕神!!!'))
		return
	end

	local petData = self:GetPetDataById(id)
	local lock = 0 ~= checkint(petData.isProtect)

	if lock then
		-- 解锁
		self:SendSignal(COMMANDS.COMMANDS_Pet_Develop_Pet_PetUnlock, {playerPetId = id})
	else
		-- 锁定
		self:SendSignal(COMMANDS.COMMANDS_Pet_Develop_Pet_PetLock, {playerPetId = id})
	end
end
--[[
堕神上锁处理处理成功
@params responseData table 服务器返回
@params lock bool 是否是锁定操作
--]]
function PetDevelopMediator:LockPetCallback(responseData, lock)
	local id = responseData.requestData.playerPetId
	------------ data ------------
	-- 刷新本地堕神数据
	local newPetData = {
		isProtect = lock and 1 or 0
	}
	gameMgr:UpdatePetDataById(id, newPetData)

	-- 刷新排序后数据
	self:UpdatePetDataByIndex(self:GetCurrentSelectedPetIndex(), newPetData)
	------------ data ------------

	------------ view ------------
	local remindStr = ''
	if lock then
		remindStr = __('锁定成功!!!')
	else
		remindStr = __('解锁成功!!!')
	end
	uiMgr:ShowInformationTips(remindStr)

	-- 刷新单个单元格状态
	self:GetViewComponent().pets = self.petsData
	self:GetViewComponent():RefreshPetGridViewCellByIndex(self:GetCurrentSelectedPetIndex())

	-- 刷新左侧锁定状态
	self:GetViewComponent():RefreshPetPreviewLock(lock)
	------------ view ------------
end
--[[
堕神放生
@params data table {
	id int 堕神数据库id
}
--]]
function PetDevelopMediator:DeletePet(data)
	local id = data.id

	if nil == id then
		uiMgr:ShowInformationTips(__('请选择一个堕神!!!'))
		return
	end

	-- 判断是否上锁 上锁后的堕神无法放生
	local petData = self:GetPetDataById(id)
	if 0 ~= checkint(petData.isProtect) then
		-- 上锁堕神无法放生
		uiMgr:ShowInformationTips(__('堕神已上锁 无法放生!!!'))
		return
	end

	-- 装备的堕神无法放生
	if 0 ~= checkint(petData.playerCardId) then
		uiMgr:ShowInformationTips(__('堕神已装备 无法放生!!!'))
		return
	end

	-- 弹确认框
	local commonTip = require('common.NewCommonTip').new({
		text = __('确认要放生该堕神吗?放生后该堕神将永久消失!!!'),
		callback = function ()
			self:SendSignal(COMMANDS.COMMANDS_Pet_Develop_Pet_PetRelease, {playerPetId = id})
		end
	})
	commonTip:setPosition(display.center)
	uiMgr:GetCurrentScene():AddDialog(commonTip)
end

--[[
堕神放生
@params data table {
	id int 堕神数据库id
}
--]]
function PetDevelopMediator:DeleteOneKindPet(data)
	local petsData = data.petsData
	if table.nums(petsData) == 0  then
		app.uiMgr:ShowInformationTips(__('该种类的堕神没有可以放生的了'))
		return
	end
	-- 弹确认框
	local commonTip = require('common.NewCommonTip').new({
		text = __('确认要放生堕神吗?放生后堕神将永久消失!!!'),
		callback = function ()
			self:SendSignal(COMMANDS.COMMANDS_Pet_Develop_Pet_PetRelease, {playerPetId = table.concat(petsData , "," ) })
		end
	})
	commonTip:setPosition(display.center)
	uiMgr:GetCurrentScene():AddDialog(commonTip)
end

--[[
堕神放生成功
@params responseData table 服务器返回
--]]
function PetDevelopMediator:DeleteOneKindPetCallback(responseData)
	local playerPetId = responseData.requestData.playerPetId
	local pets = string.split2(playerPetId , ",")
	local petKeys = {}
	for index, id in pairs(pets) do
		petKeys[tostring(id )] = id
	end
	------------ data ------------
	-- 删除本地数据
	for i, id in pairs(petKeys) do
		gameMgr:DeleteAPetById(id)
	end
	for i = #self.petsData , 1, -1 do
		local petData = self.petsData[i]
		if petKeys[tostring(petData.id)]  then
			table.remove(self.petsData , i)
		end
	end
	-- 删除管理器数据
	------------ data ------------
	------------ view ------------
	uiMgr:ShowInformationTips(__('已放生!!!'))
	-- 刷新所有堕神状态
	self:GetViewComponent():RefreshPets(self.petsData)
	-- 刷新选中状态
	if 1 == self:GetViewComponent().selectedPetIndex then
		self:GetViewComponent().selectedPetIndex = nil
	end
	self:GetViewComponent():RefreshPetDevelopDetailByIndex(0 < #self.petsData and 1 or nil)
	------------ view ------------
	self:GetViewComponent().viewData.petDevelopLayer.gridView:setContentOffsetToBottom()
end
--[[
堕神放生成功
@params responseData table 服务器返回
--]]
function PetDevelopMediator:DeletePetCallback(responseData)
	local id = responseData.requestData.playerPetId

	------------ data ------------
	-- 删除本地数据
	gameMgr:DeleteAPetById(id)
	-- 删除管理器数据
	self:DeleteAPetByIndex(self:GetCurrentSelectedPetIndex())
	------------ data ------------

	------------ view ------------
	uiMgr:ShowInformationTips(__('已放生!!!'))
	-- 刷新所有堕神状态
	self:GetViewComponent():RefreshPets(self.petsData)
	-- 刷新选中状态
	if 1 == self:GetViewComponent().selectedPetIndex then
		self:GetViewComponent().selectedPetIndex = nil
	end
	self:GetViewComponent():RefreshPetDevelopDetailByIndex(0 < #self.petsData and 1 or nil)
	------------ view ------------

end
--[[
为堕神排序
@params data table {
	sortType PetSortRule 排序规则
	sortOrder SortOrder 升降序规则
}
--]]
function PetDevelopMediator:SortPets(data)
	local sortType = data.sortType
	local sortOrder = data.sortOrder

	self.petDevelopSortRule = sortType
	self.petDevelopSortOrder = sortOrder

	local selectedPetIndex = self:GetCurrentSelectedPetIndex()
	local selectedPetData = self:GetCurrentSelectedPetData()

	------------ data ------------
	-- 刷新堕神蛋数据
	self:UpdatePetsDataBySortRule(self.petDevelopSortRule, self.petDevelopSortOrder)
	-- 刷新选中序号
	if nil ~= selectedPetIndex and selectedPetData then
		for i,v in ipairs(self.petsData) do
			if checkint(v.id) == checkint(selectedPetData.id) then
				selectedPetIndex = i
				break
			end
		end
	end
	------------ data ------------

	------------ view ------------
	-- 刷新列表和详细状态
	self:GetViewComponent():RefreshPets(self.petsData)
	self:GetViewComponent():RefreshPetDevelopDetailByIndex(selectedPetIndex)
	------------ view ------------

end
---------------------------------------------------
-- logic control end --
---------------------------------------------------

---------------------------------------------------
-- view control begin --
---------------------------------------------------
--[[
根据序号刷新选中的模块页签
@params moduleType PetModuleType 模块序号
@params doAction bool 是否做动画
--]]
function PetDevelopMediator:RefreshMuduleByModuleType(moduleType, doAction)
	-- 当前页签按钮
	local curModuleTabBtn = self:GetViewComponent().viewData.moduleTabBtns[moduleType]
	if curModuleTabBtn then
		curModuleTabBtn:setChecked(true)
	end

	if not moduleType or moduleType == self.selectedModuleType then return end

	-- 刷新一次所有堕神数据
	if PetModuleType.DEVELOP == moduleType then
		self:UpdatePetsDataBySortRule(self.petDevelopSortRule, self.petDevelopSortOrder)
	end

	if self.selectedModuleType then
		-- 前一个页签按钮
		local preModuleTabBtn = self:GetViewComponent().viewData.moduleTabBtns[self.selectedModuleType]
		if preModuleTabBtn then
			preModuleTabBtn:setChecked(false)
		end
	end

	self.selectedModuleType = moduleType

	self:NeedInitByModuleType(moduleType)
	-- 刷新界面
	self:GetViewComponent():RefreshSceneByModuleType(
			self.selectedModuleType,
			{petEggs = self.petEggsData, selectedPetEggIndex = nil, pets = self.petsData, selectedPetIndex = 1},
			doAction
	)
end
--[[
根据模块判断是否需要初始化
@params moduleType PetModuleType 模块序号
--]]
function PetDevelopMediator:NeedInitByModuleType(moduleType)
	if PetModuleType.PURGE == moduleType then
		if nil == self:GetViewComponent().viewData.petPurgeLayer then
			print('here init fuck pet purge layer')
			self:InitPetPurgeLayer()
		end
	elseif PetModuleType.DEVELOP == moduleType then
		if nil == self:GetViewComponent().viewData.petDevelopLayer then
			self:InitPetDevelopLayer()
		end
	end

end
--[[
堕神升级成功界面回调信号
@params data table {
	upgradePetId int 更新堕神id
}
--]]
function PetDevelopMediator:PetUpgradeLevelHandler(data)
	local upgradePetId = data.upgradePetId
	------------ data ------------
	-- 刷新管理器列表数据
	self:UpdatePetsDataBySortRule(self.petDevelopSortRule, self.petDevelopSortOrder)
	------------ data ------------

	------------ view ------------
	self:GetViewComponent().selectedPetIndex = nil
	-- 查找当前选中的堕神
	local index = self:GetPetIndexById(upgradePetId)

	-- 刷新列表和详细状态
	self:GetViewComponent():RefreshPets(self.petsData)
	self:GetViewComponent():RefreshPetDevelopDetailByIndex(index)
	------------ view ------------
end
--[[
堕神强化成功界面回调信号
@params data table {
	upgradePetId int 更新堕神id
}
--]]
function PetDevelopMediator:PetUpgradeBreakHandler(data)
	local upgradePetId = data.upgradePetId
	------------ data ------------
	-- 刷新管理器列表数据
	self:UpdatePetsDataBySortRule(self.petDevelopSortRule, self.petDevelopSortOrder)
	------------ data ------------

	------------ view ------------
	self:GetViewComponent().selectedPetIndex = nil
	-- 查找当前选中的堕神
	local index = self:GetPetIndexById(upgradePetId)

	-- 刷新列表和详细信息
	self:GetViewComponent():RefreshPets(self.petsData)
	self:GetViewComponent():RefreshPetDevelopDetailByIndex(index)
	------------ view ------------
end
--[[
堕神洗炼成功界面回调信号
@params data table {
	upgradePetId int 洗炼堕神id
	pindex int 洗炼属性序号
}
--]]
function PetDevelopMediator:PetUpgradePropHandler(data)
	local upgradePetId = data.upgradePetId
	local pindex = data.pindex

	------------ data ------------
	-- 刷新管理器列表数据
	self:UpdatePetsDataBySortRule(self.petDevelopSortRule, self.petDevelopSortOrder)
	------------ data ------------

	------------ view ------------
	self:GetViewComponent().selectedPetIndex = nil
	-- 查找当前选中的堕神
	local index = self:GetPetIndexById(upgradePetId)

	-- 刷新列表和详细信息
	self:GetViewComponent():RefreshPets(self.petsData)
	self:GetViewComponent():RefreshPetDevelopDetailByIndex(index)
	------------ view ------------
end

--[[
堕神异化
@params data table {
	upgradePetId int 洗炼堕神id
	pindex int 洗炼属性序号
}
--]]
function PetDevelopMediator:PetUpgradeEvolutionHandler(data)
	local upgradePetId = data.upgradePetId
	------------ data ------------
	-- 刷新管理器列表数据
	self:UpdatePetsDataBySortRule(self.petDevelopSortRule, self.petDevelopSortOrder)
	------------ data ------------

	------------ view ------------
	self:GetViewComponent().selectedPetIndex = nil
	-- 查找当前选中的堕神
	local index = self:GetPetIndexById(upgradePetId)

	-- 刷新列表和详细信息
	self:GetViewComponent():RefreshPets(self.petsData)
	self:GetViewComponent():RefreshPetDevelopDetailByIndex(index)
	------------ view ------------
	------------ view ------------
end



---------------------------------------------------
-- view control end --
---------------------------------------------------

---------------------------------------------------
-- click handler begin --
---------------------------------------------------
--[[
页签按钮回调
--]]
function PetDevelopMediator:ModuleTabBtnClickHandler(sender)
	PlayAudioClip(AUDIOS.UI.ui_depot_tabchange.id)
	local moduleType = sender:getTag()
	self:RefreshMuduleByModuleType(moduleType, true)
	GuideUtils.DispatchStepEvent()
end
--[[
培养皿按钮回调
@params data table {
	purgePodId int 培养皿id
}
--]]
function PetDevelopMediator:PurgePodClickCallback(data)
	local purgePodId = data.purgePodId
	local purgePodData = self:GetPurgePodDataById(tostring(purgePodId))
	if nil == purgePodData then
		-- 消耗道具
		local purgePodConfig = CommonUtils.GetConfig('pet', 'petPond', purgePodId)
		local costGoodsId = checkint(purgePodConfig.consume)
		local costGoodsConfig = CommonUtils.GetConfig('goods', 'goods', costGoodsId)
		local hintStr = nil

		if costGoodsConfig then
			-- 有消耗
			hintStr = string.format(__('是否花费%d%s购买净化皿?'), checkint(purgePodConfig.consumeNum), costGoodsConfig.name)
		else
			-- 无消耗
			hintStr = __('解锁净化皿?')
		end

		local commonTip = require('common.NewCommonTip').new({
			text = hintStr,
			callback = function ()
				AppFacade.GetInstance():DispatchObservers('BUY_PURGE_POD', {purgePodId = purgePodId})
			end
		})
		commonTip:setPosition(display.center)
		uiMgr:GetCurrentScene():AddDialog(commonTip)
	else
		-- 培养皿已经解锁
		if 0 == checkint(purgePodData.petEggId) then

			-- 培养皿中为空
			uiMgr:ShowInformationTips(__('选择一个灵体进行净化'))
			return

		else
			-- 培养皿不为空

			-- 刷新净化池
			self:GetViewComponent():RefreshCenterPurgePoolByIndex(checkint(purgePodId), purgePodData, self.freeWateringTime)

			------------ old ------------
			-- if nil ~= purgePodData.cdTime and 0 >= checkint(purgePodData.cdTime) then
			-- 	-- 完成 可以领取
			-- 	AppFacade.GetInstance():DispatchObservers('DRAW_PET_AFTER_PURGE', {purgePodId = purgePodId})
			-- else
			-- 	-- 没有净化完成 刷新净化池
			-- 	self:GetViewComponent():RefreshCenterPurgePoolByIndex(checkint(purgePodId), purgePodData, self.freeWateringTime)
			-- end
			------------ old ------------
		end
	end
	GuideUtils.DispatchStepEvent()
end
--==============================--
---@Description: 领取全部培养皿按钮回调
---@author : xingweihao
---@date : 2019/1/7 1:38 PM
--==============================--

function PetDevelopMediator:PurgePodDrawAllClickCallback()
	local poolConfig = CommonUtils.GetConfigAllMess('petPond', 'pet')
	local poolTotalAmount = table.nums(poolConfig)
	local isDraw = false
	for purgePodId = 1, poolTotalAmount do
		local purgePodData = self:GetPurgePodDataById(tostring(purgePodId))
		if purgePodData and  nil ~= purgePodData.petEggId and  checkint(purgePodData.petEggId) > 0  then
			local petEggLeftTime = checkint(purgePodData.cdTime)
			if petEggLeftTime <= 0  then
				isDraw = true
				break
			end
		end
	end
	if isDraw then
		self:SendSignal(COMMANDS.COMMANDS_Pet_Develop_Pet_Pet_Clean_All , {})
	else
		uiMgr:ShowInformationTips(__('暂无可领取的堕神'))
	end
end
---------------------------------------------------
-- click handler end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
获取一个空的净化皿id
@return emptyPodId int 空的净化皿id
--]]
function PetDevelopMediator:GetAEmptyPurgePodId()
	-- 获取所有净化皿配置
	local purgePodsConfig = CommonUtils.GetConfigAllMess('petPond', 'pet')
	local purgePodTotalAmount = table.nums(purgePodsConfig)

	local purgePodData = nil
	for i = 1, purgePodTotalAmount do
		purgePodData = self.purgePodsData[tostring(i)]
		if nil ~= purgePodData and (nil == purgePodData.petEggId or 0 == checkint(purgePodData.petEggId)) then
			-- 净化皿可用并且为空
			return i
		end
	end
	return nil
end
--[[
获取空闲净化皿数量
@emptyPurgePodAmount int 空的净化皿数量
--]]
function PetDevelopMediator:GetEmptyPurgePodAmount()
	local emptyPurgePodList = self:GetEmptyPurgePodList()
	local emptyPurgePodAmount = #emptyPurgePodList
	return emptyPurgePodAmount
end
--[[
获取空闲净化皿
@retrun emptyPurgePodList list 净化皿可用列表
--]]
function PetDevelopMediator:GetEmptyPurgePodList()
	-- 获取所有净化皿配置
	local purgePodsConfig = CommonUtils.GetConfigAllMess('petPond', 'pet')
	local purgePodTotalAmount = table.nums(purgePodsConfig)

	local emptyPurgePodList = {}

	for i = 1, purgePodTotalAmount do
		purgePodData = self.purgePodsData[tostring(i)]
		if nil ~= purgePodData and (nil == purgePodData.petEggId or 0 == checkint(purgePodData.petEggId)) then
			-- 净化皿可用并且为空
			table.insert(emptyPurgePodList, i)
		end
	end
	return emptyPurgePodList
end
--[[
根据培养皿id设置培养皿为空
@params purgePodId int 培养皿id
--]]
function PetDevelopMediator:SetPurgePodEmptyById(purgePodId)
	local purgePodData = self.purgePodsData[tostring(purgePodId)]
	if nil == purgePodData then
		print('here find a logic error u want empty a locked purge pod')
	else
		self.purgePodsData[tostring(purgePodId)] = {pondId = checkint(purgePodData.pondId)}
	end
end
--[[
根据id获取培养皿当前状态
@params purgePodId int 培养皿id
@return _ table 培养皿状态
--]]
function PetDevelopMediator:GetPurgePodDataById(purgePodId)
	return self.purgePodsData[tostring(purgePodId)]
end
--[[
刷新一个培养皿状态
@params purgePodId int 培养皿id
@params purgePodData table 培养皿数据 {
	pondId int 培养皿id
	petEggId int 灵体id
	nutrition int 营养值
	magicFoods string 魔法菜品 逗号分隔
	cdTime int 净化剩余时间 s
}
--]]
function PetDevelopMediator:UpdatePurgePodDataById(purgePodId, purgePodData)
	if nil ~= self:GetPurgePodDataById(purgePodId) then
		if purgePodData.pondId then
			self.purgePodsData[tostring(purgePodId)].pondId = checkint(purgePodData.pondId)
		end
		if purgePodData.petEggId then
			self.purgePodsData[tostring(purgePodId)].petEggId = purgePodData.petEggId
		end
		if purgePodData.nutrition then
			self.purgePodsData[tostring(purgePodId)].nutrition = purgePodData.nutrition
		end
		if purgePodData.magicFoods then
			self.purgePodsData[tostring(purgePodId)].magicFoods = purgePodData.magicFoods
		end
		if purgePodData.cdTime then
			self.purgePodsData[tostring(purgePodId)].cdTime = purgePodData.cdTime
		end
	end
end
--[[
解锁一个培养皿
@params purgePodId int 培养皿id
--]]
function PetDevelopMediator:UnlockPurgePodById(purgePodId)
	self.purgePodsData[tostring(purgePodId)] = {pondId = checkint(purgePodId)}
end
--[[
根据培养皿id和魔菜槽位获取魔菜id
@params purgePodId int 培养皿id
@params slotIndex int 槽位
@return magicFoodId int 当前槽位魔菜id
--]]
function PetDevelopMediator:GetMagicFoodIdByPodIdAndSlotIdx(purgePodId, slotIndex)
	local purgePodData = self:GetPurgePodDataById(purgePodId)
	if nil == purgePodData.magicFoods or string.len(string.gsub(purgePodData.magicFoods, ' ', '')) <= 1 then
		return nil
	else
		local ids = string.split(purgePodData.magicFoods, ',')
		local magicFoodId = ids[slotIndex]
		if 0 == checkint(magicFoodId) then
			return nil
		else
			return checkint(magicFoodId)
		end
	end
end
--[[
获取非魔菜集合
@return _ map 非魔菜道具id集合
--]]
function PetDevelopMediator:GetNotMagicFoods()
	return {
		['180001'] = {goodsId = 180001},
		['180002'] = {goodsId = 180002},
		['180003'] = {goodsId = 180003},
		['180004'] = {goodsId = 180004},
		['180005'] = {goodsId = 180005}
	}
end
--[[
根据培养皿id获取定时器名字
@params purgePodId int 培养皿id
@return _ string 定时器名字
--]]
function PetDevelopMediator:GetPurgePodTimerNameByPurgePodId(purgePodId)
	return NAME .. '_' .. purgePodId
end
--[[
根据堕神数据库id获取堕神data
@params id int 堕神id
@return petData table 堕神信息
--]]
function PetDevelopMediator:GetPetDataById(id)
	return gameMgr:GetPetDataById(id)
end
--[[
获取当前选中的堕神data
@return petData table 堕神信息
--]]
function PetDevelopMediator:GetCurrentSelectedPetData()
	local curIdx = self:GetViewComponent():GetCurrentSelectedPetIndex()
	if nil == curIdx then
		return nil
	end
	return self.petsData[curIdx]
end
--[[
根据堕神id获取堕神index
@params id int 堕神id
@return index int 堕神序号
--]]
function PetDevelopMediator:GetPetIndexById(id)
	local index = nil
	for i,v in ipairs(self.petsData) do
		if id == checkint(v.id) then
			return i
		end
	end
	return index
end
--[[
获取当前选择的堕神index
@return _ int 堕神index
--]]
function PetDevelopMediator:GetCurrentSelectedPetIndex()
	return self:GetViewComponent():GetCurrentSelectedPetIndex()
end
--[[
根据序号刷新堕神数据
@params index int 堕神序号
@params newPetData table 新的堕神数据
--]]
function PetDevelopMediator:UpdatePetDataByIndex(index, newPetData)
	if nil == self.petsData then return end
	for k,v in pairs(newPetData) do
		self.petsData[index][k] = v
	end
end
--[[
根据序号删除堕神数据
@params index int 堕神序号
--]]
function PetDevelopMediator:DeleteAPetByIndex(index)
	if nil == self.petsData[index] then
		print('here find logic error in pet develop mediator !!!!!!!!!!????????????????\n\n\n\n ********** you delete a pet which not exist')
		return
	end

	table.remove(self.petsData, index)
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return PetDevelopMediator
