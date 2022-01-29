--[[
堕神 升级 强化 洗炼 3tab 界面管理器
@params table {
	mainId int 主体堕神数据库id
}
--]]
local Mediator = mvc.Mediator
local PetUpgradeMediator = class("PetUpgradeMediator", Mediator)
local NAME = "PetUpgradeMediator"

------------ import ------------
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local petMgr = AppFacade.GetInstance():GetManager("PetManager")

if nil == SortOrder then
	require('common.CommonSortBoard')
end

local PetDevelopCommand = require('Game.command.PetDevelopCommand')
------------ import ------------

------------ define ------------
local TabModuleType = {
	LEVEL 			= 1, -- 升级
	BREAK 			= 2, -- 强化
	PROPERTY 		= 3, -- 洗炼
	EVOLUTION       = 4  -- 异化
}

local PetSortRule = {
	DEFAULT 			= 0, -- 默认排序
	LOCK 				= 1, -- 是否上锁
	LEVEL 				= 2, -- 等级
	BREAK_LEVEL 		= 3, -- 强化等级
	QUALITY 			= 4  -- 品质
}
------------ define ------------

--[[
constructor
--]]
function PetUpgradeMediator:ctor(params, viewComponent)
	Mediator.ctor(self, NAME, viewComponent)

	self.mainId = params.mainId

	self.petsData = {
		[TabModuleType.LEVEL] = {},
		[TabModuleType.BREAK] = {}
	}

	------------ level ------------
	self.levelSelectedPets = {}
	self.levelMaterialSlotData = {}
	-- 初始化升级狗粮槽数据
	local maxLevelMaterialAmount = petMgr.GetPetLevelUpMaxMaterialAmount()
	for i = 1, maxLevelMaterialAmount do
		self.levelMaterialSlotData[i] = {id = nil}
	end
	self.levelExpPreview = 0

	self.levelSortRule = PetSortRule.LOCK
	self.levelSortOrder = SortOrder.ASC
	------------ level ------------

	------------ break ------------
	self.breakSelectedPets = {}
	--------------- 记录完成堕神的数量 -----------
	self.universalNum = 0
	self.breakMaterialSlotData = {}
	-- 初始化强化狗粮槽数据
	self:InitBreakMaterialSlotData()

	self.breakSortRule = PetSortRule.LOCK
	self.breakSortOrder = SortOrder.ASC
	------------ break ------------

	------------ prop ------------
	------------ prop ------------
end
---------------------------------------------------
-- mediator extend begin --
---------------------------------------------------
function PetUpgradeMediator:InterestSignals()
	local signals = {
		------------ server ------------
		SIGNALNAMES.Pet_Develop_Pet_PetLevelUp, 						-- 堕神升级信号
		SIGNALNAMES.Pet_Develop_Pet_PetBreakUp, 						-- 堕神强化信号
		SIGNALNAMES.Pet_Develop_Pet_PetAttributeReset, 					-- 堕神洗炼信号
		POST.PET_EVOLUTION.sglName,
		SGL.REFRESH_NOT_CLOSE_GOODS_EVENT ,                             -- 道具刷新
		------------ local ------------
		'REMOVE_PET_UPGRADE_SCENE', 									-- 关闭本弹窗
		'PET_UPGRADE_CHANGE_TAB', 										-- 点击切换tab页
		'LEVEL_SELECT_PET_BY_PET_ICON', 								-- 点击列表堕神头像选择升级狗粮
		'LEVEL_SELECT_PET_SLOT', 										-- 升级狗粮插槽按钮
		'LEVEL_UPGRADE', 												-- 点击升级按钮升级
		'ONE_KEY_LEVEL_UPGRADE', 									    -- 一键升级按钮升级
		'LEVEL_SORT_PET', 												-- 点击排序升级狗粮
		'BREAK_SELECT_PET_BY_PET_ICON', 								-- 点击列表堕神头像选择强化狗粮
		'BREAK_SELECT_PET_SLOT', 										-- 点击狗粮插槽按钮
		'BREAK_UPGRADE', 												-- 点击强化按钮强化
		'BREAK_SORT_PET', 												-- 点击排序强化狗粮
		'PROP_RECAST' 													-- 点击属性洗炼

	}
	return signals
end


function PetUpgradeMediator:ProcessSignal( signal )
	local name = signal:GetName()
	local responseData = signal:GetBody()

	------------ server ------------
	if SIGNALNAMES.Pet_Develop_Pet_PetLevelUp == name then

		-- 升级成功
		self:LevelUpgradeCallback(responseData)

	elseif SIGNALNAMES.Pet_Develop_Pet_PetBreakUp == name then

		-- 强化成功
		self:BreakUpgradeCallback(responseData)

	elseif SIGNALNAMES.Pet_Develop_Pet_PetAttributeReset == name then

		-- 强化成功
		self:PropRecastCallback(responseData)
	elseif 	POST.PET_EVOLUTION.sglName == name then
		self:EvolutionCallBack(responseData)
	------------ local ------------
	elseif 'REMOVE_PET_UPGRADE_SCENE' == name then

		-- 移除自己
		AppFacade.GetInstance():UnRegsitMediator(NAME)

	elseif 'PET_UPGRADE_CHANGE_TAB' == name then

		-- 切换tab页
		self:ChangeTabByModuleType(responseData.index)

	elseif 'LEVEL_SELECT_PET_BY_PET_ICON' == name then

		-- 点选狗粮
		self:SelectLevelMaterial(responseData)

	elseif 'LEVEL_SELECT_PET_SLOT' == name then

		-- 点选狗粮
		self:LevelMaterialSlot(responseData)

	elseif 'LEVEL_UPGRADE' == name then

		-- 点击升级
		self:LevelUpgrade()
	elseif 'ONE_KEY_LEVEL_UPGRADE' == name then

		-- 点击升级
		self:OneKeyLevelUpgrade()

	elseif 'LEVEL_SORT_PET' == name then

		-- 点击排序
		self:SortLevelPets(responseData)

	elseif 'BREAK_SELECT_PET_BY_PET_ICON' == name then

		-- 点击升级
		self:SelectBreakMaterial(responseData)

	elseif 'BREAK_SELECT_PET_SLOT' == name then
		self:BreakMaterialSlot(responseData)
		
		-- 点击升级


	elseif 'BREAK_UPGRADE' == name then

		-- 点击升级
		self:BreakUpgrade()

	elseif 'BREAK_SORT_PET' == name then

		-- 点击排序
		self:SortBreakPets(responseData)

	elseif 'PROP_RECAST' == name then

		-- 点击洗炼
		self:PropRecast(responseData)
	elseif SGL.REFRESH_NOT_CLOSE_GOODS_EVENT == name then
		-- 道具刷新的事件
		self:GoodsRefreshCallBack()
	end
end
function PetUpgradeMediator:Initial( key )
	Mediator.Initial(self, key)
end
function PetUpgradeMediator:OnRegist()

	self:GetFacade():RegistSignal(COMMANDS.COMMANDS_Pet_Develop_Pet_PetLevelUp, PetDevelopCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMANDS_Pet_Develop_Pet_PetBreakUp, PetDevelopCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMANDS_Pet_Develop_Pet_PetAttributeReset, PetDevelopCommand)
	regPost(POST.PET_EVOLUTION)
	-- 初始化界面
	self:InitScene()

	-- 初始化选中第一个标签
	self:ChangeTabByModuleType(TabModuleType.LEVEL)

end
function PetUpgradeMediator:OnUnRegist()
	unregPost(POST.PET_EVOLUTION)
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
function PetUpgradeMediator:InitScene()

	-- 创建场景
	local tag = 892
	local data = {
		tag = tag,
		id = self:GetMainPetId(),
		isNeedCloseLayer = false,
		showLabel = false,
	}
	local layer = require('Game.views.pet.PetUpgradeScene').new(data)
	display.commonUIParams(layer, {ap = cc.p(0.5, 0.5), po = cc.p(display.cx, display.cy)})
	layer:setTag(tag)
	uiMgr:GetCurrentScene():AddDialog(layer)

	self:SetViewComponent(layer)

end
--[[
	初始化堕神消耗
--]]
function PetUpgradeMediator:InitBreakMaterialSlotData()
	self.breakMaterialSlotData = {}
	local mainPetData = gameMgr:GetPetDataById(self.mainId)
	local breakLevel = checkint(mainPetData.breakLevel)
	local maxBreakLevel = petMgr.GetPetMaxBreakLevelById(self.mainId)
	if breakLevel <  maxBreakLevel then
		local  maxBreakMaterialAmount = petMgr.GetPetBreakUpMaxMaterialAmountByBreakLevel(breakLevel +1)
		for i = 1, maxBreakMaterialAmount do
			self.breakMaterialSlotData[i] = {id = nil}
		end
	end
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- control begin --
---------------------------------------------------
--[[
为升级页签堕神列表排序
@params data table {
	sortType PetSortRule 排序规则
	sortOrder SortOrder 升降序规则
}
--]]
function PetUpgradeMediator:SortLevelPets(data)
	local sortType = data.sortType
	local sortOrder = data.sortOrder

	self.levelSortRule = sortType
	self.levelSortOrder = sortOrder

	------------ data ------------
	-- 刷新堕神数据
	self:UpdataLevelPetsDataBySortRule(self.levelSortRule, self.levelSortOrder)
	------------ data ------------

	------------ view ------------
	self:GetMainLayer():RefreshLevelLayerGridView(self:GetPetsDataByModuleType(TabModuleType.LEVEL))
	------------ view ------------

end
--[[
为强化页签堕神列表排序
@params data table {
	sortType PetSortRule 排序规则
	sortOrder SortOrder 升降序规则
}
--]]
function PetUpgradeMediator:SortBreakPets(data)
	local sortType = data.sortType
	local sortOrder = data.sortOrder

	self.breakSortRule = sortType
	self.breakSortOrder = sortOrder

	------------ data ------------
	-- 刷新堕神数据
	self:UpdateBreakPetsDataBySortRule(self.breakSortRule, self.breakSortOrder)
	------------ data ------------

	------------ view ------------
	self:GetMainLayer():RefreshBreakLayerGridView(self:GetPetsDataByModuleType(TabModuleType.BREAK))
	------------ view ------------
end
--[[
根据排序规则刷新升级可以选择的狗粮pet
@params sortRule PetSortRule
@params sortOrder SortOrder 升降序
--]]
function PetUpgradeMediator:UpdataLevelPetsDataBySortRule(sortRule, sortOrder)
	self.petsData[TabModuleType.LEVEL] = {}

	local allPetsData = {}
	for k,v in pairs(gameMgr:GetUserInfo().pets) do
		if self:GetMainPetId() ~= checkint(v.id) then
			table.insert(allPetsData, checkint(v.id))
		end
	end

	local judgeSign = 1
	if SortOrder.DESC == sortOrder then
		judgeSign = -1
	end

	if PetSortRule.LOCK == sortRule then

		table.sort(allPetsData, function (a, b)
			local petDataA = gameMgr:GetPetDataById(a)
			local petDataB = gameMgr:GetPetDataById(b)

			local deltaLock = checkint(petDataA.isProtect) - checkint(petDataB.isProtect)
			if 0 == deltaLock then
				local deltaLevel = checkint(petDataA.level) - checkint(petDataB.level)
				if 0 == deltaLevel then
					local deltaBreakLevel = checkint(petDataA.breakLevel) - checkint(petDataB.breakLevel)
					if 0 == deltaBreakLevel then
						local deltaQuality = checkint(petMgr.GetPetQualityByPetId(petDataA.petId)) - checkint(petMgr.GetPetQualityByPetId(petDataB.petId))
						if 0 == deltaQuality then
							return checkint(petDataA.id) < checkint(petDataB.id)
						else
							return deltaQuality * judgeSign < 0
						end
					else
						return deltaBreakLevel * judgeSign < 0
					end
				else
					return deltaLevel * judgeSign < 0
				end
			else
				return deltaLock * judgeSign < 0
			end
		end)

		self.petsData[TabModuleType.LEVEL] = allPetsData

	elseif PetSortRule.LEVEL == sortRule then

		table.sort(allPetsData, function (a, b)
			local petDataA = gameMgr:GetPetDataById(a)
			local petDataB = gameMgr:GetPetDataById(b)

			local deltaLevel = checkint(petDataA.level) - checkint(petDataB.level)
			if 0 == deltaLevel then
				local deltaLock = checkint(petDataA.isProtect) - checkint(petDataB.isProtect)
				if 0 == deltaLock then
					local deltaBreakLevel = checkint(petDataA.breakLevel) - checkint(petDataB.breakLevel)
					if 0 == deltaBreakLevel then
						local deltaQuality = checkint(petMgr.GetPetQualityByPetId(petDataA.petId)) - checkint(petMgr.GetPetQualityByPetId(petDataB.petId))
						if 0 == deltaQuality then
							return checkint(petDataA.id) < checkint(petDataB.id)
						else
							return deltaQuality * judgeSign < 0
						end
					else
						return deltaBreakLevel * judgeSign < 0
					end
				else
					return deltaLock * judgeSign < 0
				end
			else
				return deltaLevel * judgeSign < 0
			end
		end)

		self.petsData[TabModuleType.LEVEL] = allPetsData

	elseif PetSortRule.BREAK_LEVEL == sortRule then

		table.sort(allPetsData, function (a, b)
			local petDataA = gameMgr:GetPetDataById(a)
			local petDataB = gameMgr:GetPetDataById(b)

			local deltaBreakLevel = checkint(petDataA.breakLevel) - checkint(petDataB.breakLevel)
			if 0 == deltaBreakLevel then
				local deltaLock = checkint(petDataA.isProtect) - checkint(petDataB.isProtect)
				if 0 == deltaLock then
					local deltaLevel = checkint(petDataA.level) - checkint(petDataB.level)
					if 0 == deltaLevel then
						local deltaQuality = checkint(petMgr.GetPetQualityByPetId(petDataA.petId)) - checkint(petMgr.GetPetQualityByPetId(petDataB.petId))
						if 0 == deltaQuality then
							return checkint(petDataA.id) < checkint(petDataB.id)
						else
							return deltaQuality * judgeSign < 0
						end
					else
						return deltaLevel * judgeSign < 0
					end
				else
					return deltaLock * judgeSign < 0
				end
			else
				return deltaBreakLevel * judgeSign < 0
			end
		end)

		self.petsData[TabModuleType.LEVEL] = allPetsData


	elseif PetSortRule.QUALITY == sortRule then

		table.sort(allPetsData, function (a, b)
			local petDataA = gameMgr:GetPetDataById(a)
			local petDataB = gameMgr:GetPetDataById(b)

			local deltaQuality = checkint(petMgr.GetPetQualityByPetId(petDataA.petId)) - checkint(petMgr.GetPetQualityByPetId(petDataB.petId))
			if 0 == deltaQuality then
				local deltaLock = checkint(petDataA.isProtect) - checkint(petDataB.isProtect)
				if 0 == deltaLock then
					local deltaLevel = checkint(petDataA.level) - checkint(petDataB.level)
					if 0 == deltaLevel then
						local deltaBreakLevel = checkint(petDataA.breakLevel) - checkint(petDataB.breakLevel)
						if 0 == deltaBreakLevel then
							return checkint(petDataA.id) < checkint(petDataB.id)
						else
							return deltaBreakLevel * judgeSign < 0
						end
					else
						return deltaLevel * judgeSign < 0
					end
				else
					return deltaLock * judgeSign < 0
				end
			else
				return deltaQuality * judgeSign < 0
			end
		end)

		self.petsData[TabModuleType.LEVEL] = allPetsData

	else

		self.petsData[TabModuleType.LEVEL] = allPetsData

	end
end
--[[
根据排序规则刷新强化可以选择的狗粮pei
@params sortRule PetSortRule
@params sortOrder SortOrder 升降序
--]]
function PetUpgradeMediator:UpdateBreakPetsDataBySortRule(sortRule, sortOrder)
	self.petsData[TabModuleType.BREAK] = {}

	local petData = gameMgr:GetPetDataById(self:GetMainPetId())
	local petId = checkint(petData.petId)

	local allPetsData = {}
	for k,v in pairs(gameMgr:GetUserInfo().pets) do
		if self:GetMainPetId() ~= checkint(v.id) and petId == checkint(v.petId) then
			table.insert(allPetsData, checkint(v.id))
		end
	end

	local judgeSign = 1
	if SortOrder.DESC == sortOrder then
		judgeSign = -1
	end

	if PetSortRule.LOCK == sortRule then

		table.sort(allPetsData, function (a, b)
			local petDataA = gameMgr:GetPetDataById(a)
			local petDataB = gameMgr:GetPetDataById(b)

			local deltaLock = checkint(petDataA.isProtect) - checkint(petDataB.isProtect)
			if 0 == deltaLock then
				local deltaLevel = checkint(petDataA.level) - checkint(petDataB.level)
				if 0 == deltaLevel then
					local deltaBreakLevel = checkint(petDataA.breakLevel) - checkint(petDataB.breakLevel)
					if 0 == deltaBreakLevel then
						return checkint(petDataA.id) < checkint(petDataB.id)
					else
						return deltaBreakLevel * judgeSign < 0
					end
				else
					return deltaLevel * judgeSign < 0
				end
			else
				return deltaLock * judgeSign < 0
			end
		end)

		self.petsData[TabModuleType.BREAK] = allPetsData

	elseif PetSortRule.LEVEL == sortRule then

		table.sort(allPetsData, function (a, b)
			local petDataA = gameMgr:GetPetDataById(a)
			local petDataB = gameMgr:GetPetDataById(b)

			local deltaLevel = checkint(petDataA.level) - checkint(petDataB.level)
			if 0 == deltaLevel then
				local deltaLock = checkint(petDataA.isProtect) - checkint(petDataB.isProtect)
				if 0 == deltaLock then
					local deltaBreakLevel = checkint(petDataA.breakLevel) - checkint(petDataB.breakLevel)
					if 0 == deltaBreakLevel then
						return checkint(petDataA.id) < checkint(petDataB.id)
					else
						return deltaBreakLevel * judgeSign < 0
					end
				else
					return deltaLock * judgeSign < 0
				end
			else
				return deltaLevel * judgeSign < 0
			end
		end)

		self.petsData[TabModuleType.BREAK] = allPetsData

	elseif PetSortRule.BREAK_LEVEL == sortRule then

		table.sort(allPetsData, function (a, b)
			local petDataA = gameMgr:GetPetDataById(a)
			local petDataB = gameMgr:GetPetDataById(b)

			local deltaBreakLevel = checkint(petDataA.breakLevel) - checkint(petDataB.breakLevel)
			if 0 == deltaBreakLevel then
				local deltaLock = checkint(petDataA.isProtect) - checkint(petDataB.isProtect)
				if 0 == deltaLock then
					local deltaLevel = checkint(petDataA.level) - checkint(petDataB.level)
					if 0 == deltaLevel then
						return checkint(petDataA.id) < checkint(petDataB.id)
					else
						return deltaLevel * judgeSign < 0
					end
				else
					return deltaLock * judgeSign < 0
				end
			else
				return deltaBreakLevel * judgeSign < 0
			end
		end)

		self.petsData[TabModuleType.BREAK] = allPetsData

	else

		self.petsData[TabModuleType.BREAK] = allPetsData

	end
	table.insert(self.petsData[TabModuleType.BREAK] , 1, { goodsId = UNIVERSAL_PET_ID , num = CommonUtils.GetCacheProductNum(UNIVERSAL_PET_ID) })
end
--[[
刷新一次列表数据
@params moduleType TabModuleType 页签模块类型
--]]
function PetUpgradeMediator:UpdatePetsData(moduleType)
	if TabModuleType.LEVEL == moduleType then

		self:UpdataLevelPetsDataBySortRule(self.levelSortRule, self.levelSortOrder)

	elseif TabModuleType.BREAK == moduleType then

		self:UpdateBreakPetsDataBySortRule(self.breakSortRule, self.breakSortOrder)

	end
end
--[[
根据序号切换tab页
@params moduleType TabModuleType 序号
--]]
function PetUpgradeMediator:ChangeTabByModuleType(moduleType)
	self:UpdatePetsData(moduleType)
	self:GetMainLayer():RefreshUIByIndex(moduleType)
	self:GetMainLayer():RefreshPetsDataByIndex(moduleType, self:GetPetsDataByModuleType(moduleType))
	-- 清空其他模块的temp状态
	self:ClearTempStateByCurModuleType(moduleType)
	GuideUtils.DispatchStepEvent()
end
--[[
根据选择的模块类型清空其他tab的所有缓存状态
@params moduleType TabModuleType 模块
--]]
function PetUpgradeMediator:ClearTempStateByCurModuleType(moduleType)
	if TabModuleType.LEVEL == moduleType then
		self:ClearBreakTempState()
		self:ClearPropertyTempState()
		self:GetMainLayer():ResetUniversalPet()
		self:ResetUniversalPet()
	elseif TabModuleType.BREAK == moduleType then
		self:ClearLevelTempState()
		self:ClearPropertyTempState()
		self:InitBreakMaterialSlotData()
	elseif TabModuleType.PROPERTY == moduleType then
		self:ClearLevelTempState()
		self:ClearBreakTempState()
		self:GetMainLayer():ResetUniversalPet()
		self:ResetUniversalPet()
	elseif	 TabModuleType.EVOLUTION == moduleType then
		self:ClearLevelTempState()
		self:ClearBreakTempState()
		self:GetMainLayer():ResetUniversalPet()
		self:ResetUniversalPet()
	end
end
--[[
清空堕神升级的所有缓存状态
--]]
function PetUpgradeMediator:ClearLevelTempState()
	-- 清空所有的选中狗粮
	for i,v in ipairs(self.levelMaterialSlotData) do
		if nil ~= v.id then
			self:RemoveALevelMaterial(v.id)
		end
	end
end
--[[
清空堕神强化的所有缓存状态
--]]
function PetUpgradeMediator:ClearBreakTempState()
	-- 清空选中的狗粮
	for i,v in ipairs(self.breakMaterialSlotData) do
		if nil ~= v.id then
			self:RemoveABreakMaterial(v.id)
		end
	end
end
--[[
清空堕神洗炼的所有缓存状态
--]]
function PetUpgradeMediator:ClearPropertyTempState()
	-- 清空选中状态
	self:GetMainLayer():RefreshRecastPropByIndex(nil)
end
--[[
选择升级狗粮
@params data table {
	index int 选择狗粮列表序号
}
--]]
function PetUpgradeMediator:SelectLevelMaterial(data)
	local index = data.index
	local id = self:GetPetIdByModuleTypeAndIndex(TabModuleType.LEVEL, index)
	local petSelected = self:GetLevelPetSelectedById(id)
	-- 判断是否入槽
	if petSelected then
		self:RemoveALevelMaterial(id)
        GuideUtils.DispatchStepEvent()
	else
		self:AddALevelMaterial(id)
	end
	-- GuideUtils.DispatchStepEvent()
end
--[[
装上一个狗粮
@params id int 堕神数据库id
--]]
function PetUpgradeMediator:AddALevelMaterial(id)
	local petData = gameMgr:GetPetDataById(id)
	local mainPetData = gameMgr:GetPetDataById(self:GetMainPetId())

	local petMaxLevel = petMgr:GetPetMaxLevel()
	if checkint(mainPetData.level) >= petMaxLevel and
			checkint(mainPetData.exp) >= checkint(CommonUtils.GetConfig('pet', 'level', petMaxLevel).exp) then
		-- 满了
		uiMgr:ShowInformationTips(__('!!!堕神经验已满 无法添加!!!'))
        GuideUtils.EnableShowSkip() --是否显示引导的逻辑
		return
	end

	if 0 ~= checkint(petData.isProtect) then
		-- 被保护 无法添加
		uiMgr:ShowInformationTips(__('!!!堕神已锁 无法添加!!!'))
        GuideUtils.EnableShowSkip() --是否显示引导的逻辑
		return
	end
	if 0 ~= checkint(petData.playerCardId) then
		-- 被装备 无法添加
		uiMgr:ShowInformationTips(__('堕神已装备，无法添加。'))
        GuideUtils.EnableShowSkip() --是否显示引导的逻辑
		return
	end

	-- 判断是否可以再加入一个狗粮
	local emptyLevelMaterialSlotIndex = self:GetAEmptyLevelMaterialSlotIndex()
	if nil == emptyLevelMaterialSlotIndex then
		-- 满了
		uiMgr:ShowInformationTips(__('!!!槽位已满 无法添加!!!'))
		return
	end

	-- 没满
	------------ data ------------
	-- 处理添加逻辑
	self:AddALevelMaterialData(emptyLevelMaterialSlotIndex, id)
	-- 列表中的选中状态
	self:SetLevelPetSelectedById(id, true)
	------------ data ------------

	------------ view ------------
	-- 刷新槽位选中状态
	self:GetMainLayer():RefreshLevelMaterialSlotByIndex(emptyLevelMaterialSlotIndex, id)
	-- 刷新列表选中状态
	self:GetMainLayer():RefreshLevelPetIconSelectById(
			id,
			self:GetLevelPetSelectedById(id)
	)
	-- 刷新经验值预览
	self:GetMainLayer():RefreshExpPreview(checkint(mainPetData.exp) + self:GetLevelPetExpPreview())
	------------ view ------------
	GuideUtils.DispatchStepEvent()
end
--[[
卸下一个狗粮
@params id int 狗粮id
--]]
function PetUpgradeMediator:RemoveALevelMaterial(id)
	local petData = gameMgr:GetPetDataById(id)
	local mainPetData = gameMgr:GetPetDataById(self:GetMainPetId())
	local slotIndex = self:GetLevelMaterialSlotIndexById(id)
	------------ data ------------
	-- 处理槽位数据
	self:RemoveALevelMaterialData(slotIndex)
	-- 处理列表数据
	self:SetLevelPetSelectedById(id, false)
	------------ data ------------

	------------ view ------------
	-- 刷新槽位中状态
	self:GetMainLayer():RefreshLevelMaterialSlotByIndex(slotIndex, nil)
	-- 刷新列表中选中状态
	self:GetMainLayer():RefreshLevelPetIconSelectById(
			id,
			self:GetLevelPetSelectedById(id)
	)
	-- 刷新经验值预览
	self:GetMainLayer():RefreshExpPreview(checkint(mainPetData.exp) + self:GetLevelPetExpPreview())
	------------ view ------------
end
--[[
点击插槽按钮
@params data table {
	index int 选择的插槽序号
}
--]]
function PetUpgradeMediator:LevelMaterialSlot(data)
	local slotIndex = data.index
	local id = self:GetLevelMaterialIdBySlotIndex(slotIndex).id

	if nil == id then
		-- 空插槽 弹提示
		uiMgr:ShowInformationTips(__('!!!未选择狗粮!!!'))
		return
	end

	-- 不为空 卸下操作
	self:RemoveALevelMaterial(id)
end
--[[
点击升级
--]]
function PetUpgradeMediator:LevelUpgrade()
	-- 转换数据结构
	local hasMaterial = false
	local materialStr = ''
	for i,v in ipairs(self.levelMaterialSlotData) do
		if nil ~= v.id then
			hasMaterial = true
			materialStr = materialStr .. tostring(v.id) .. ','
		end
	end

	if not hasMaterial then
		-- 空狗粮 弹提示
		uiMgr:ShowInformationTips(__('!!!未选择狗粮!!!'))
		return
	end

	-- 删掉最后一个逗号
	materialStr = string.sub(materialStr, 1, string.len(materialStr) - 1)

	self:SendSignal(COMMANDS.COMMANDS_Pet_Develop_Pet_PetLevelUp, {playerPetId = self:GetMainPetId(), petFoods = materialStr})
end
--[[
点击升级
--]]
function PetUpgradeMediator:OneKeyLevelUpgrade()
	-- 转换数据结构
	local pets = gameMgr:GetUserInfo().pets
	local petData = pets[tostring(self.mainId)]
	if petData then
		local maxLevel = petMgr.GetPetMaxLevel()
		if maxLevel > checkint(petData.level) then
			local view = require('Game.views.pet.PetOneKeyUpgradeView').new({id = self.mainId})
			app.uiMgr:GetCurrentScene():AddDialog(view)
			view:setPosition(display.center)
		else
			uiMgr:ShowInformationTips(__('该堕神已经满级'))
		end
	end
end
--[[
升级成功
@params responseData table 服务器返回
--]]
function PetUpgradeMediator:LevelUpgradeCallback(responseData)
	local levelUp = checkint(responseData.level) > checkint(gameMgr:GetPetDataById(self:GetMainPetId()).level)
	------------ data ------------
	-- 清空狗粮槽
	self:ClearLevelMaterialSlot()

	-- 清空列表选择状态
	self:ClearLevelPetSelected()

	-- 本地堕神数据
	local newPetData = {
		level = checkint(responseData.level),
		exp = checkint(responseData.exp)
	}
	gameMgr:UpdatePetDataById(self:GetMainPetId(), newPetData)
  
	-- 删除狗粮数据
	local materialStr = responseData.requestData.petFoods
	local materialIds = string.split(materialStr, ',')
	for i,v in ipairs(materialIds) do
		gameMgr:DeleteAPetById(checkint(v))
	end

	-- 刷新一次管理器数据
	self:UpdatePetsData(TabModuleType.LEVEL)
	------------ data ------------

	------------ view ------------
	self:GetMainLayer():DoLevelUpgrade(self:GetPetsDataByModuleType(TabModuleType.LEVEL), levelUp)
	------------ view ------------

	-- 刷新全局数据
	AppFacade.GetInstance():DispatchObservers(EVENT_UPGRADE_LEVEL, {
		upgradePetId = self:GetMainPetId()
	})

	GuideUtils.DispatchStepEvent()
end
--[[
选择强化狗粮
@params data table {
	index int 选择狗粮列表序号
}
--]]
function PetUpgradeMediator:SelectBreakMaterial(data)
	local index = data.index

	if index == 1  then
		self:AddUniversalMaterial()
	else
		local id = self:GetPetIdByModuleTypeAndIndex(TabModuleType.BREAK, index)
		local petSelected = self:GetBreakPetSelectedById(id)
		-- 判断是否入槽
		if petSelected then
			self:RemoveABreakMaterial(id)
		else
			self:AddABreakMaterial(id)
		end
		GuideUtils.DispatchStepEvent()
	end

end
function PetUpgradeMediator:AddUniversalMaterial()

	local ownNum = CommonUtils.GetCacheProductNum(UNIVERSAL_PET_ID)
	if ownNum <= 0 then
		uiMgr:AddDialog('common.GainPopup' , {goodsId =  UNIVERSAL_PET_ID })
		return
	end
	local isReturn = petMgr.GetPaxMaxBreakLevelTipById(self.mainId)
	if string.len(isReturn) > 0  then
		uiMgr:ShowInformationTips(isReturn)
		 return
	end
	local mainPetData = gameMgr:GetPetDataById(self:GetMainPetId())
	local petNum = petMgr.GetPetBreakUpMaxMaterialAmountByBreakLevel(checkint(mainPetData.breakLevel)  +1 )
	local num  = self:GetSelectPetNum()
	if petNum >  num then
		local petIdNum = table.nums(self.breakSelectedPets)
		-- 需要填充的镜像体
		local needNum  = petNum - petIdNum
		local unverialNum = CommonUtils.GetCacheProductNum(UNIVERSAL_PET_ID)
		if needNum > unverialNum  then
			uiMgr:AddDialog("common.GainPopup", {goodId = UNIVERSAL_PET_ID})
			--uiMgr:ShowInformationTips(__('镜像体不足。!!!'))
			return
		end
		self:AddUniversalPetNum()
		self:GetMainLayer():SetUniversalPetNum(self:GetUniversalPet())
		self:GetMainLayer():RefreshBreakMaterialSlotByIndex(nil, nil , true)
		self:GetMainLayer():RefreshBreakUniveralPet()
	else
		if petNum == 1  then
			if self:GetUniversalPet() == 0 then
				------------ data ------------
				local emptySlotIndex = 1
				-- 只有一个槽 判断是否选择了强化狗粮 选择了则替换 未选择则装备
				local breakMaterialData = self:GetBreakMaterialDataBySlotIndex(emptySlotIndex)
				if nil ~= breakMaterialData.id then
					-- 当前已有狗粮 卸下
					self:RemoveABreakMaterial(breakMaterialData.id)
				end
				self:AddUniversalMaterial()
			else
				uiMgr:ShowInformationTips(__('堕神数量已满。'))
				return
			end
		else
			uiMgr:ShowInformationTips(__('堕神数量已满。'))
			return
		end
	end
	-- 刷新属性预览
	local deltaBreakLevel = petMgr.GetDeltaBreakLevel()
	self:GetMainLayer():RefreshPetAllPPreview(
			petMgr.GetPetAllBaseProps(self:GetMainPetId()),
			mainPetData.breakLevel + deltaBreakLevel,
			checkint(mainPetData.character)
	)
	-- 刷新突破等级预览
	self:GetMainLayer():RefreshBreakMainPetLevel(mainPetData.breakLevel + deltaBreakLevel)

end
--[[
装上一个强化狗粮
@params id int 堕神数据库id
--]]
function PetUpgradeMediator:AddABreakMaterial(id)
	local petData = gameMgr:GetPetDataById(id)

	local mainPetData = gameMgr:GetPetDataById(self:GetMainPetId())

	if 0 ~= checkint(petData.isProtect) then
		-- 被保护 无法添加
		uiMgr:ShowInformationTips(__('!!!堕神已锁 无法添加!!!'))
		return
	end

	if 0 ~= checkint(petData.playerCardId) then
		-- 被装备 无法添加
		uiMgr:ShowInformationTips(__('堕神已装备，无法添加。'))
		return
	end

	local isReturn = petMgr.GetPaxMaxBreakLevelTipById(self.mainId)
	if string.len(isReturn) > 0  then
		uiMgr:ShowInformationTips(isReturn)
		return
	end

	local petNum = petMgr.GetPetBreakUpMaxMaterialAmountByBreakLevel(checkint(mainPetData.breakLevel)  +1 )
	if petNum == 1  then
		------------ data ------------
		local emptySlotIndex = 1
		-- 只有一个槽 判断是否选择了强化狗粮 选择了则替换 未选择则装备
		local breakMaterialData = self:GetBreakMaterialDataBySlotIndex(emptySlotIndex)

		if nil ~= breakMaterialData.id then
			-- 当前已有狗粮 卸下
			self:RemoveABreakMaterial(breakMaterialData.id)
		end
		local consumePetNum = self:GetUniversalPet()
		if consumePetNum == 1 then
			self:ReduceUniversalPet()
			self:GetMainLayer():SetUniversalPetNum(self:GetUniversalPet())
			self:GetMainLayer():RefreshBreakUniveralPet()
		end
		-- 添加新增强化狗粮
		self:AddABreaMaterialData(emptySlotIndex, id)
		-- 列表中的选中状态
		self:SetBreakPetSelectedById(id, true)
		self:GetMainLayer():SetBreakPetSelectedById(id, true )
		self:GetMainLayer():RefreshBreakMaterialSlotByIndex(emptySlotIndex, id)
	else
		local num  = self:GetSelectPetNum()
		if petNum >  num then
			local index =  self:GetFirstBreakMaterialIndex()
			self:AddABreaMaterialData(index , id)
			self:SetBreakPetSelectedById(id, true)
			self:GetMainLayer():SetBreakPetSelectedById(id, true )
			self:GetMainLayer():RefreshBreakMaterialSlotByIndex(nil , id ,false)
		else
			uiMgr:ShowInformationTips(__('堕神数量已满。'))
			return
		end
	end
	------------ data ------------

	------------ view ------------
	-- 刷新槽位选中状态

	-- 刷新列表选中状态
	self:GetMainLayer():RefreshBreakPetIconSelectById( id, true)
	-- 刷新属性预览
	local deltaBreakLevel = petMgr.GetDeltaBreakLevel()
	self:GetMainLayer():RefreshPetAllPPreview(
			petMgr.GetPetAllBaseProps(self:GetMainPetId()),
			mainPetData.breakLevel + deltaBreakLevel,
			checkint(mainPetData.character)
	)
	-- 刷新突破等级预览
	self:GetMainLayer():RefreshBreakMainPetLevel(mainPetData.breakLevel + deltaBreakLevel)
	------------ view ------------
end
--[[
卸下一个强化狗粮
@params id int 堕神数据库id
--]]
function PetUpgradeMediator:RemoveABreakMaterial(id)
	local slotIndex = self:GetBreakMaterialSlotIndexById(id)
	------------ data ------------
	-- 处理槽位数据
	self:RemoveABreakMaterialData(slotIndex)
	-- 处理列表数据
	self:SetBreakPetSelectedById(id, false)
	------------ data ------------

	------------ view ------------
	-- 刷新列表选中状态
	self:GetMainLayer():RefreshBreakPetIconSelectById(id, false)
	-- 刷新槽位选中状态
	self:GetMainLayer():RefreshBreakMaterialSlotByIndex(slotIndex, nil)
	-- 刷新属性预览值
	-- self:GetMainLayer():ClearPetPPreview()
	local  selectNum = self:GetSelectPetNum()
	-- 刷新突破等级预览
	if selectNum == 0  then
		local mainPetData = gameMgr:GetPetDataById(self:GetMainPetId())
		self:GetMainLayer():RefreshBreakMainPetLevel(mainPetData.breakLevel)
	end

	------------ view ------------
end
--[[
点选狗粮
@params data table {
	index int 选择的插槽序号
}
--]]
function PetUpgradeMediator:BreakMaterialSlot(data)

	self:InitBreakMaterialSlotData()
	self:ClearBreakPetSelected()
	self:ResetUniversalPet()
	self:GetMainLayer():ClearBreakPetSelected()
	self:GetMainLayer():RefreshBreakMaterialSlotByIndex()
	self:GetMainLayer():RefreshBreakLayerGridView()
	local mainPetData = gameMgr:GetPetDataById(self.mainId)
	self:GetMainLayer():RefreshBreakMainPetLevel(mainPetData.breakLevel)

	
end
--[[
	获取到当前堕神突破要消耗的堕神
--]]
function PetUpgradeMediator:GetBreakLevelNeedAmountNum()
	local mainPetData = gameMgr:GetPetDataById(self.mainId)
	local breakLevel = checkint(mainPetData.breakLevel)
	local maxBreakLevel = petMgr.GetPetMaxBreakLevelById()

	if breakLevel <  maxBreakLevel then
		local maxBreakMaterialAmount = petMgr.GetPetBreakUpMaxMaterialAmountByBreakLevel(breakLevel +1)
		return maxBreakMaterialAmount
	else
		return 0
	end
end
--[[
点击强化
--]]
function PetUpgradeMediator:BreakUpgrade()
	local mainPetData = gameMgr:GetPetDataById(self:GetMainPetId())
	-- 判断是否可以强化
	local isReturn = petMgr.GetPaxMaxBreakLevelTipById(self.mainId)
	if string.len(isReturn) > 0  then
		uiMgr:ShowInformationTips(isReturn)
		return
	end
	local num = self:GetSelectPetNum()
	local petNum = petMgr.GetPetBreakUpMaxMaterialAmountByBreakLevel(checkint(mainPetData.breakLevel) + 1)
	if num < petNum then
		uiMgr:ShowInformationTips(__('堕神数量不足。'))
		return
	end
	local breakCostConfig = petMgr.GetBreakCostConfig(checkint(mainPetData.breakLevel) + 1)
	local goodsId = nil
	local num = nil
	for i,v in ipairs(breakCostConfig) do
		goodsId = checkint(v.goodsId)
		num = checkint(v.num)
		if num > CommonUtils.GetCacheProductNum(goodsId) then
			if GAME_MODULE_OPEN.NEW_STORE and checkint(goodsId) == DIAMOND_ID then
				app.uiMgr:showDiamonTips()
			else
				local goodsConfig = CommonUtils.GetConfig('goods', 'goods', goodsId)
				uiMgr:ShowInformationTips(string.format(__('%s不足!!!'), goodsConfig.name))
			end
			return
		end
	end
	-- 转换数据结构
	local hasMaterial = false
	local materialStr = ''

	for i,v in ipairs(self.breakMaterialSlotData) do
		if nil ~= v.id then
			hasMaterial = true
			materialStr = materialStr .. tostring(v.id) .. ','
		end
	end

	if not hasMaterial then
		-- 空狗粮 弹提示
		--uiMgr:ShowInformationTips(__('!!!未选择狗粮!!!'))
		--return
		materialStr = ""
	else
		-- 删掉最后一个逗号
		materialStr = string.sub(materialStr, 1, string.len(materialStr) - 1)
	end



	-- 确定弹窗
	local commonTip = require('common.NewCommonTip').new({
		text = __('强化可能会失败并消耗狗粮,是否继续?'),
		callback = function ()
			-- 可以唤醒
			self:SendSignal(COMMANDS.COMMANDS_Pet_Develop_Pet_PetBreakUp, {playerPetId = self:GetMainPetId(), petFoods = materialStr})
		end
	})
	commonTip:setName('NewCommonTip')
	commonTip:setPosition(display.center)
	uiMgr:GetCurrentScene():AddDialog(commonTip)
	GuideUtils.DispatchStepEvent()
end

function PetUpgradeMediator:EvolutionCallBack()
	local newPetData = {
		isEvolution =1
	}
	local mainPetData = gameMgr:GetPetDataById(self:GetMainPetId())
	local petId = mainPetData.petId
	local breakCostConfig = petMgr.GetEvoltuionCostConfig(petId)

	local goodsId = nil
	local num = nil
	for i,v in ipairs(breakCostConfig) do
		goodsId = checkint(v.goodsId)
		num = checkint(v.num)
		CommonUtils.DrawRewards({ {goodsId = goodsId, num = - num} })
	end
	gameMgr:UpdatePetDataById(self:GetMainPetId(), newPetData)

	self:GetMainLayer():EvolutionAction()
	self:GetFacade():DispatchObservers(EVENT_UPGRADE_EVOLUTION , {upgradePetId = self:GetMainPetId()})
end
--[[
	添加万能堕神
--]]
function PetUpgradeMediator:AddUniversalPetNum()
	local petNum =table.nums(self.breakSelectedPets)
	local mainPetData = gameMgr:GetPetDataById(self:GetMainPetId())
	local needNum = petMgr.GetPetBreakUpMaxMaterialAmountByBreakLevel(mainPetData.breakLevel +1)
	self.universalNum = (needNum - petNum) > 0   and (needNum - petNum) or 0
	local ownNum = CommonUtils.GetCacheProductNum(UNIVERSAL_PET_ID)
	self.universalNum = ownNum > self.universalNum and self.universalNum or ownNum
end
--[[
	获取万能堕神
--]]
function PetUpgradeMediator:GetUniversalPet()
	return self.universalNum
end

--[[
	减少万能堕神
--]]
function PetUpgradeMediator:ReduceUniversalPet()
	self.universalNum = self.universalNum -1
	return self.universalNum
end

--[[
	重置万能堕神
--]]
function PetUpgradeMediator:ResetUniversalPet()
	self.universalNum = 0
	return self.universalNum
end


--[[
强化成功
@params responseData table 服务器返回
--]]
function PetUpgradeMediator:BreakUpgradeCallback(responseData)
	------------ data ------------
	-- 扣除消耗的道具
	local dobreakLevel = checkint(responseData.breakLevel)
	-- 如果失败需要加上1 扣除的是目标等级的消耗
	if 0 == checkint(responseData.isBreak) then
		dobreakLevel = dobreakLevel + 1
	end
	local breakCostConfig = petMgr.GetBreakCostConfig(dobreakLevel)
	local goodsId = nil
	local num = nil
	local data = {}
	for i,v in ipairs(breakCostConfig) do
		goodsId = checkint(v.goodsId)
		num = checkint(v.num)

		--CommonUtils.DrawRewards({
		--	{goodsId = goodsId, num = -num}
		--})
		data[#data+1] = {goodsId = goodsId, num = -num}
	end
	local mainPetData = gameMgr:GetPetDataById(self.mainId)
	local breakTimes = checkint(responseData.isBreak) == 0 and checkint(mainPetData.breakTimes)  + 1 or 0
	-- 本地堕神数据
	local newPetData = {
		breakLevel = checkint(responseData.breakLevel),
		breakTimes =  breakTimes
	}
	gameMgr:UpdatePetDataById(self:GetMainPetId(), newPetData)

	-- 删除狗粮
	local materialStr = responseData.requestData.petFoods
	local materialIds = string.split(materialStr, ',')
	local count = 0
	for i,v in ipairs(materialIds) do
		if checkint(v) > 0   then
			count = count +1
			gameMgr:DeleteAPetById(checkint(v))
		end
	end
	local petNum = petMgr.GetPetBreakUpMaxMaterialAmountByBreakLevel(dobreakLevel)
	local alreadyNum = count
	data[#data+1] = { num = alreadyNum - petNum , goodsId = UNIVERSAL_PET_ID }
	CommonUtils.DrawRewards(data)


	self:ClearBreakPetSelected()
	self:ResetUniversalPet()
	self:InitBreakMaterialSlotData()
	-- 刷新一次管理器数据
	self:UpdatePetsData(TabModuleType.BREAK)
	------------ data ------------

	------------ view ------------
	-- 弹提示
	if 0 ~= checkint(responseData.isBreak) then
		uiMgr:ShowInformationTips(__('强化成功!!!'))
	else
		uiMgr:ShowInformationTips(__('强化失败!!!'))
	end

	-- 刷新界面
	self:GetMainLayer():DoBreakLevel(self:GetPetsDataByModuleType(TabModuleType.BREAK), 0 ~= checkint(responseData.isBreak))
	------------ view ------------

	-- 刷新全局界面
	AppFacade.GetInstance():DispatchObservers(EVENT_UPGRADE_BREAK, {
		upgradePetId = self:GetMainPetId()
	})
	GuideUtils.DispatchStepEvent()
end
--[[
点击属性洗炼
@params data table {
	resetAttrNum int 洗炼属性序号
}
--]]
function PetUpgradeMediator:PropRecast(data)
	local index = data.resetAttrNum
	if nil == index then
		uiMgr:ShowInformationTips(__('请选择一个属性'))
		return
	end

	local petPData = petMgr.GetPetAllFixedProps(self:GetMainPetId())[index]
	-- 判断是否可以洗炼
	if not petPData.unlock then
		uiMgr:ShowInformationTips(__('!!!该属性未解锁!!!'))
		return
	end

	local costConfig = petMgr.GetPropRecastCostConfig()
	local goodsConfig = CommonUtils.GetConfig('goods', 'goods', costConfig.goodsId)
	if costConfig.num > gameMgr:GetAmountByGoodId(costConfig.goodsId) then
		uiMgr:AddDialog("common.GainPopup", {goodId = costConfig.goodsId})
		-- uiMgr:ShowInformationTips(string.format(__('%s不足!!!'), goodsConfig.name))
		return
	end

	-- 蓝色品质以上弹确认框
	if PetPQuality.BLUE < checkint(petPData.pquality) then
		-- 确定弹窗
		local commonTip = require('common.NewCommonTip').new({
			text = __('确定要进行洗炼?'),
			callback = function ()
				self:SendSignal(COMMANDS.COMMANDS_Pet_Develop_Pet_PetAttributeReset,
						{playerPetId = self:GetMainPetId(), resetAttrNum = index})
			end
		})
		commonTip:setName('NewCommonTip')
		commonTip:setPosition(display.center)
		uiMgr:GetCurrentScene():AddDialog(commonTip)
		GuideUtils.DispatchStepEvent()
	else
		-- 可以洗炼
		self:SendSignal(COMMANDS.COMMANDS_Pet_Develop_Pet_PetAttributeReset,
				{playerPetId = self:GetMainPetId(), resetAttrNum = index})
	end

end
--[[
洗炼成功
@params responseData table 服务器返回
--]]
function PetUpgradeMediator:PropRecastCallback(responseData)
	local recastIndex = responseData.requestData.resetAttrNum
	local pConfig = petMgr.GetPetPInfo()[recastIndex]
	------------ data ------------
	-- 刷新本地堕神属性信息
	local newPetData = {
		[pConfig.ptypeName] 		= responseData.extraAttrType,
		[pConfig.pnumName] 			= responseData.extraAttrNum,
		[pConfig.pqualityName] 		= responseData.extraAttrQuality
	}
	gameMgr:UpdatePetDataById(self:GetMainPetId(), newPetData)

	-- 扣除消耗道具
	local costConfig = petMgr.GetPropRecastCostConfig()
	CommonUtils.DrawRewards({
		{goodsId = costConfig.goodsId, num = -costConfig.num}
	})
	------------ data ------------

	------------ view ------------
	-- 提示
	-- uiMgr:ShowInformationTips(__('洗炼成功!!!'))
	-- 刷新消耗
	self:GetMainLayer():RefreshPropRecastCost(costConfig.num, gameMgr:GetAmountByGoodId(costConfig.goodsId))
	-- 做转盘动画
	self:GetMainLayer():DoPropUpgrade(
			recastIndex,
			checkint(responseData.extraAttrType),
			checknumber(responseData.extraAttrNum),
			checkint(responseData.extraAttrQuality)
	)
	------------ view ------------

	-- 刷新全局界面
	AppFacade.GetInstance():DispatchObservers(EVENT_UPGRADE_PROP, {
		upgradePetId = self:GetMainPetId(),
		pindex = recastIndex
	})
	GuideUtils.DispatchStepEvent()
end
--[[
	道具刷新的回调事件
--]]
function PetUpgradeMediator:GoodsRefreshCallBack()
	self:GetMainLayer():RefreshEvolutionLayerGoods()
	self:GetMainLayer():RefreshBreakLayerGoods()

end
---------------------------------------------------
-- control end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
获取场景主体堕神数据库id
--]]
function PetUpgradeMediator:GetMainPetId()
	return self.mainId
end
--[[
获取场景主要展示层
--]]
function PetUpgradeMediator:GetMainLayer()
	return self:GetViewComponent().viewData.view
end
--[[
根据index获取堕神数据
@params index TabModuleType
@return _ list pet data
--]]
function PetUpgradeMediator:GetPetsDataByModuleType(moduleType)
	return self.petsData[moduleType]
end
--[[
根据模块和index获取堕神数据
@params moduleType TabModuleType 模块类型
@params index int 列表序号
--]]
function PetUpgradeMediator:GetPetIdByModuleTypeAndIndex(moduleType, index)
	return self:GetPetsDataByModuleType(moduleType)[index]
end
--[[
获取一个空的升级狗粮槽
@return _ int 空的狗粮槽序号
--]]
function PetUpgradeMediator:GetAEmptyLevelMaterialSlotIndex()
	for i,v in ipairs(self.levelMaterialSlotData) do
		if nil == v.id then
			return i
		end
	end
	return nil
end
--[[
向槽位中添加一个升级狗粮
@params slotIndex int 槽位序号
@params id int 堕神id
--]]
function PetUpgradeMediator:AddALevelMaterialData(slotIndex, id)
	self.levelMaterialSlotData[slotIndex].id = id

	-- 刷新经验值预览
	local petData = gameMgr:GetPetDataById(id)
	local deltaExp = petMgr.GetPetExpByPetIdAndLevel(checkint(petData.petId), checkint(petData.level))
	self:AddLevelPetExpPreview(deltaExp)
end
--[[
从槽位中移除一个升级狗粮
@params slotIndex int 槽位序号
--]]
function PetUpgradeMediator:RemoveALevelMaterialData(slotIndex)
	local id = self.levelMaterialSlotData[slotIndex].id
	-- 刷新经验值预览
	local petData = gameMgr:GetPetDataById(id)
	local deltaExp = petMgr.GetPetExpByPetIdAndLevel(checkint(petData.petId), checkint(petData.level))
	self:AddLevelPetExpPreview(-deltaExp)

	self.levelMaterialSlotData[slotIndex].id = nil
end
--[[
根据id获取对应的狗粮槽位index
@params id int pet id not config id
@return index int level material slot index
--]]
function PetUpgradeMediator:GetLevelMaterialSlotIndexById(id)
	for i,v in ipairs(self.levelMaterialSlotData) do
		if v.id == id then
			return i
		end
	end
	return nil
end
--[[
根据插槽序号获取该插槽中的堕神数据
@params index int 插槽序号
@return _ table 堕神数据
--]]
function PetUpgradeMediator:GetLevelMaterialIdBySlotIndex(index)
	return self.levelMaterialSlotData[index]
end
--[[
清空狗粮槽
--]]
function PetUpgradeMediator:ClearLevelMaterialSlot()
	for i,v in ipairs(self.levelMaterialSlotData) do
		if nil ~= v.id then
			self:RemoveALevelMaterialData(i)
		end
	end

	self:ClearLevelPetExpPreview()
end

--[[
获取一个空的强化狗粮槽
@return _ int 空的狗粮槽序号
--]]
function PetUpgradeMediator:GetAEmptyBreakMaterialSlotIndex()
	for i,v in ipairs(self.breakMaterialSlotData) do
		if nil == v.id then
			return i
		end
	end
	return nil
end
--[[
向槽位中添加一个强化狗粮
@params slotIndex int 槽位序号
@params id int 堕神id
--]]
function PetUpgradeMediator:AddABreaMaterialData(slotIndex, id)
	if self.breakMaterialSlotData[slotIndex] then
		self.breakMaterialSlotData[slotIndex].id = id
	end
end
--[[
从槽位中移除一个升级狗粮
@params slotIndex int 槽位序号
--]]
function PetUpgradeMediator:RemoveABreakMaterialData(slotIndex)
	if self.breakMaterialSlotData[slotIndex] then
		self.breakMaterialSlotData[slotIndex].id = nil
	end
end
--[[
根据id获取对应的强化狗粮槽位index
@params id int pet id not config id
@return index int level material slot index
--]]
function PetUpgradeMediator:GetBreakMaterialSlotIndexById(id)
	for i,v in ipairs(self.breakMaterialSlotData) do
		if v.id == id then
			return i
		end
	end
	return nil
end
--[[
根据插槽序号获取该插槽中的堕神数据
@params slotIndex int 插槽序号
@return _ table 堕神数据
--]]
function PetUpgradeMediator:GetBreakMaterialDataBySlotIndex(slotIndex)
	return self.breakMaterialSlotData[slotIndex]
end
--[[
清空强化狗粮槽
--]]
function PetUpgradeMediator:ClearBreakMaterialSlot()
	for i,v in ipairs(self.breakMaterialSlotData) do
		if nil ~= v.id then
			self:RemoveABreakMaterialData(i)
		end
	end
	self:ResetUniversalPet()
end




------------ 升级狗粮的选中状态 ------------
function PetUpgradeMediator:SetLevelPetSelectedById(id, selected)
	if selected then
		self.levelSelectedPets[tostring(id)] = selected
	else
		self.levelSelectedPets[tostring(id)] = nil
	end
end
function PetUpgradeMediator:GetLevelPetSelectedById(id)
	return self.levelSelectedPets[tostring(id)]
end
function PetUpgradeMediator:ClearLevelPetSelected()
	for k,v in pairs(self.levelSelectedPets) do
		self:SetLevelPetSelectedById(checkint(k), false)
	end
end

------------ 经验值预览的temp值 ------------
function PetUpgradeMediator:AddLevelPetExpPreview(deltaExp)
	self.levelExpPreview = self.levelExpPreview + deltaExp
end
function PetUpgradeMediator:GetLevelPetExpPreview()
	return self.levelExpPreview
end
function PetUpgradeMediator:ClearLevelPetExpPreview()
	self.levelExpPreview = 0
end
function PetUpgradeMediator:GetFirstBreakMaterialIndex()
	for i, v in pairs(self.breakMaterialSlotData) do
		if not  v.id  then
			return i
		end
	end
end
------------ 强化狗粮的选中状态 ------------
function PetUpgradeMediator:SetBreakPetSelectedById(id, selected)
	if selected then
		self.breakSelectedPets[tostring(id)] = selected
	else
		self.breakSelectedPets[tostring(id)] = nil
	end
end
function PetUpgradeMediator:GetBreakPetSelectedById(id)
	return self.breakSelectedPets[tostring(id)]
end
function PetUpgradeMediator:ClearBreakPetSelected()
	self.breakSelectedPets = {}
	--for k,v in pairs(self.breakSelectedPets) do
	--	self:SetBreakPetSelectedById(checkint(k), false)
	--end
end

function PetUpgradeMediator:GetSelectPetNum()
	local count =  table.nums(self.breakSelectedPets)
	local universalNum = self:GetUniversalPet()
	return count + universalNum
end


---------------------------------------------------
-- get set end --
---------------------------------------------------


return PetUpgradeMediator
