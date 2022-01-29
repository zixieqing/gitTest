--[[
工会神兽养成管理器
--]]
local Mediator = mvc.Mediator
local UnionBeastBabyDevMediator = class("UnionBeastBabyDevMediator", Mediator)
local NAME = "UnionBeastBabyDevMediator"

------------ import ------------
local uiMgr = AppFacade.GetInstance():GetManager('UIManager')
local cardMgr = AppFacade.GetInstance():GetManager('CardManager')
local unionMgr = AppFacade.GetInstance():GetManager('UnionManager')
local gameMgr = AppFacade.GetInstance():GetManager('GameManager')

local UnionConfigParser  = require('Game.Datas.Parser.UnionConfigParser')
------------ import ------------

------------ define ------------
------------ define ------------

--[[
constructor
--]]
function UnionBeastBabyDevMediator:ctor(params, viewComponent)
	Mediator.ctor(self, NAME, viewComponent)
end
---------------------------------------------------
-- mediator extend begin --
---------------------------------------------------
function UnionBeastBabyDevMediator:InterestSignals()
	local signals = {
		------------ server ------------
		POST.UNION_PET.sglName,
		POST.UNION_FEEDPET.sglName,
		POST.UNION_FEEDPETLOG.sglName,
		------------ local ------------
		'CLOSE_UNION_BEASTBABYDEV',
		'SHOW_UNION_FEED_SATIETY',
		'HIDE_UNION_FEED_SATIETY',
		'FEED_BEAST_BABY',
		'SHOW_UNION_FEED_LOG',
		'SHOW_UNION_HUNT_BY_BEAST_BABY',
		SIGNALNAMES.RecipeCookingMaking_Callback,
		SIGNALNAMES.RecipeUnlock_Callback
	}

	return signals
end
function UnionBeastBabyDevMediator:ProcessSignal( signal )
	local name = signal:GetName()
	local responseData = signal:GetBody()

	if POST.UNION_PET.sglName == name then
		-- home返回
		self:UnionPetHomeCallback(responseData)

	elseif POST.UNION_FEEDPET.sglName == name then

		-- 显示喂养神兽幼崽的界面
		self:FeedBeastBabyCallback(responseData)

	elseif POST.UNION_FEEDPETLOG.sglName == name then

		-- 显示喂养神兽日志界面
		self:ShowUnionFeedLogCallback(responseData)

	elseif 'CLOSE_UNION_BEASTBABYDEV' == name then

		-- 显示喂养神兽幼崽的界面
		self:CloseSelf()

	elseif 'SHOW_UNION_FEED_SATIETY' == name then

		-- 显示喂养神兽幼崽的界面
		self:ShowUnionFeedSatiety(responseData)

	elseif 'HIDE_UNION_FEED_SATIETY' == name then

		-- 关闭喂养神兽幼崽
		self:HideUnionFeedSatiety()

	elseif 'FEED_BEAST_BABY' == name then

		-- 喂养神兽幼崽
		self:FeedBeastBaby(responseData)

	elseif 'SHOW_UNION_FEED_LOG' == name then

		-- 显示喂养神兽幼崽日志
		self:ShowUnionFeedLog()

	elseif 'SHOW_UNION_HUNT_BY_BEAST_BABY' == name then

		-- 显示打神兽界面
		self:ShowUnionHuntView(responseData)

	elseif SIGNALNAMES.RecipeCookingMaking_Callback == name then

		-- 菜品数量变化 刷新一次界面
		self:RefreshFeedViewByFoodData()

	elseif SIGNALNAMES.RecipeUnlock_Callback == name then

		-- 解锁了新菜谱 刷新一次界面
		self:RefreshFeedViewByFoodData()

	end
end
function UnionBeastBabyDevMediator:Initial( key )
	self.super.Initial(self, key)
end
function UnionBeastBabyDevMediator:OnRegist()
	-- 注册信号
	regPost(POST.UNION_PET, true)
	regPost(POST.UNION_FEEDPET)
	regPost(POST.UNION_FEEDPETLOG)

	-- 初始化数据结构
	self.feedFavoriteFoodBonus = 1
	self.beastBabiesData = nil
	self.allBeastBabiesConfig = nil

	-- 请求一次home
	self:SendSignal(POST.UNION_PET.cmdName)
end
function UnionBeastBabyDevMediator:OnUnRegist()
	-- 注销信号
	unregPost(POST.UNION_PET)
	unregPost(POST.UNION_FEEDPET)
	unregPost(POST.UNION_FEEDPETLOG)

	-- 销毁界面
	if self:GetViewComponent() and not tolua.isnull(self:GetViewComponent()) then
		uiMgr:GetCurrentScene():RemoveDialog(self:GetViewComponent())
	end
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
function UnionBeastBabyDevMediator:InitScene()
	local scene = require('Game.views.union.UnionBeastBabyDevScene').new()
	display.commonUIParams(scene, {ap = cc.p(0.5, 0.5), po = cc.p(display.cx, display.cy)})
	uiMgr:GetCurrentScene():AddDialog(scene)

	self:SetViewComponent(scene)
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- handler begin --
---------------------------------------------------
--[[
home请求回调
@params responseData table 服务器返回数据
--]]
function UnionBeastBabyDevMediator:UnionPetHomeCallback(responseData)
	-- 如果存在errcode 移除自己
	local errcode = checkint(responseData.errcode)
	if 0 ~= errcode then
		-- 移除自己
		AppFacade.GetInstance():UnRegsitMediator(NAME)
		return
	end

	-- 判断是否需要播放剧情
	if nil ~= responseData.pet and 0 < table.nums(responseData.pet) and not unionMgr:OpenedBeastBaby() then
		-- 解锁了幼崽 并且没有看过剧情 播放剧情
		local storyPath  = string.format('conf/%s/union/story.json', i18n.getLang())
		local storyStage = require('Frame.Opera.OperaStage').new({id = 3, path = storyPath, guide = true, cb = function(sender)
			unionMgr:SetOpenedBeastBaby()
			self:FirstInit(responseData)
        end})
        storyStage:setPosition(display.center)
        sceneWorld:addChild(storyStage, GameSceneTag.Dialog_GameSceneTag)
	else
		self:FirstInit(responseData)
	end
end
--[[
初始化一次
@params responseData table 服务器返回数据
--]]
function UnionBeastBabyDevMediator:FirstInit(responseData)
	if nil == self:GetViewComponent() then
		-- 创建一次界面
		self:InitScene()

		self.feedFavoriteFoodBonus = checknumber(responseData.feedFavoriteFoodBonus)
		self:SetBeastBabiesData(responseData.pet)

		self:GetViewComponent():RefreshUI(
			self:GetSortedBeastBabiesConfig(),
			self:GetBeastBabiesData(),
			checkint(unionMgr:getUnionData().level)
		)
	end
end
--[[
显示神兽幼崽喂养的界面
@params data table {
	beastBabyId int 神兽幼崽id
}
--]]
function UnionBeastBabyDevMediator:ShowUnionFeedSatiety(data)
	local beastBabyId = checkint(data.beastBabyId)

	-- 处理一次数据
	local beastBabyData = self:GetBeastBabyDataById(beastBabyId)
	local fixedfoodsData = self:GetFixedFoodsInfo(beastBabyData.favoriteFoods)

	self:GetViewComponent():ShowFeedView(fixedfoodsData, self.feedFavoriteFoodBonus)
end
--[[
关闭神兽幼崽喂养界面
--]]
function UnionBeastBabyDevMediator:HideUnionFeedSatiety()
	self:GetViewComponent():HideFeedView()
end
--[[
关闭自己
--]]
function UnionBeastBabyDevMediator:CloseSelf()
	AppFacade.GetInstance():UnRegsitMediator(NAME)
end
--[[
喂食神兽幼崽
@params data table 喂食的菜品信息
--]]
function UnionBeastBabyDevMediator:FeedBeastBaby(data)
	if nil == next(data) then
		uiMgr:ShowInformationTips(__('喂食菜品不能为空!!!'))
		return
	end

	local petId = self:GetViewComponent():GetSelectedBeastBabyId()
	self:SendSignal(POST.UNION_FEEDPET.cmdName, {petId = petId, foods = json.encode(data)})
	-- debug --
	-- local responseData = json.decode('{"satiety":490,"satietyLevel":"1","leftFeedPetNumber":14,"unionPoint":49,"contributionPoint":49}')
	-- responseData.requestData = {
	-- 	petId = 990001,
	-- 	foods = '{"150001":1,"150002":1,"150004":1,"150003":1,"150005":1}'
	-- }
	-- self:FeedBeastBabyCallback(responseData)
	-- debug --
end
--[[
喂食神兽幼崽回调
@params responseData table 服务器返回数据
--]]
function UnionBeastBabyDevMediator:FeedBeastBabyCallback(responseData)
	local petId = checkint(responseData.requestData.petId)
	local foods = json.decode(responseData.requestData.foods)

	local leftFeedAmount = checkint(responseData.leftFeedPetNumber)
	local maxFeedAmount = CommonUtils.getVipTotalLimitByField('unionFeedNum')
	------------ data ------------
	local gotUnionPointAmount = checkint(responseData.unionPoint) - gameMgr:GetAmountByIdForce(UNION_POINT_ID)
	local gotUnionConPointAmount = checkint(responseData.contributionPoint) - checkint(unionMgr:getUnionData().playerContributionPoint)
	local rewards = {
		{goodsId = UNION_POINT_ID, num = gotUnionPointAmount},
		{goodsId = UNION_CONTRIBUTION_POINT_ID, num = gotUnionConPointAmount}
	}

	-- 刷新一次背包中的食物数据
	local newFoodsData = {}
	for k,v in pairs(foods) do
		table.insert(newFoodsData, {goodsId = checkint(k), amount = checkint(v) * -1})
	end
	-- 插入工会币
	table.insert(newFoodsData, {goodsId = UNION_POINT_ID, amount = gotUnionPointAmount})
	CommonUtils.DrawRewards(newFoodsData)

	-- 刷新全局工会数据
	local newUnionData = {
		leftFeedPetNumber = checkint(responseData.leftFeedPetNumber),
		playerContributionPoint = checkint(responseData.contributionPoint)
	}
	unionMgr:updateUnionData(newUnionData)

	-- 刷新一次神兽幼崽的数据
	local newBeastBabyData = {
		petId = petId,
		satiety = checkint(responseData.satiety),
		satietyLevel = checkint(responseData.satietyLevel)
	}
	self:UpdateBeastBabyData(newBeastBabyData)
	self:GetViewComponent().beastBabiesData = self:GetBeastBabiesData()
	------------ data ------------

	------------ view ------------
	local beastBabyData = self:GetBeastBabyDataById(petId)
	local fixedfoodsData = self:GetFixedFoodsInfo(beastBabyData.favoriteFoods)

	-- AppFacade.GetInstance():DispatchObservers('UNION_BEASTBABY_DO_FEED', {leftFeedAmount = leftFeedAmount, maxFeedAmount = maxFeedAmount})
	self:GetViewComponent():DoFeed(
		petId,
		checkint(responseData.satietyLevel),
		checkint(responseData.satiety),
		leftFeedAmount,
		maxFeedAmount,
		rewards,
		fixedfoodsData
	)
	------------ view ------------
end
--[[
显示神兽喂养日志
--]]
function UnionBeastBabyDevMediator:ShowUnionFeedLog()
	self:SendSignal(POST.UNION_FEEDPETLOG.cmdName)
end
--[[
喂养日志回调
@params responseData table 服务器返回数据
--]]
function UnionBeastBabyDevMediator:ShowUnionFeedLogCallback(responseData)
	local tag = 3901
	local layer = require('Game.views.union.UnionBeastBabyDevLogView').new({
		tag = tag,
		feedPetLog = responseData.feedPetLog
	})
	layer:setTag(tag)
	layer:setAnchorPoint(cc.p(0.5, 0.5))
	layer:setPosition(cc.p(display.cx, display.cy))
	uiMgr:GetCurrentScene():AddDialog(layer)
end
--[[
显示打神兽界面
@params data table {
	beastBabyId int 神兽幼崽id
}
--]]
function UnionBeastBabyDevMediator:ShowUnionHuntView(data)
	local beastBabyId = checkint(data.beastBabyId)
	local beastBabyConfig = cardMgr.GetBeastBabyConfig(beastBabyId)

	local beastId = nil
	if nil ~= beastBabyConfig then
		beastId = checkint(beastBabyConfig.godBeastId)
	end

	local mediator = require("Game.mediator.UnionHuntMediator").new({
		godBeastId = beastId
	})
    self:GetFacade():RegistMediator(mediator)
end
--[[
根据食物信息 刷新喂食的选菜栏
--]]
function UnionBeastBabyDevMediator:RefreshFeedViewByFoodData()
	if self:GetViewComponent() and not tolua.isnull(self:GetViewComponent()) then
		local petId = self:GetViewComponent():GetSelectedBeastBabyId()
		local beastBabyData = self:GetBeastBabyDataById(petId)
		local fixedfoodsData = self:GetFixedFoodsInfo(beastBabyData.favoriteFoods)

		-- 刷新界面
		self:GetViewComponent():RefreshByFoodsData(fixedfoodsData)
	end
end
---------------------------------------------------
-- handler end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
获取神兽幼崽格式化后的配置
@return _ table 神兽幼崽配置
--]]
function UnionBeastBabyDevMediator:GetSortedBeastBabiesConfig()
	if nil == self.allBeastBabiesConfig then
		-- 获取配置
		local beastBabiesConfig = CommonUtils.GetConfigAllMess(UnionConfigParser.TYPE.GODBEASTATTR, 'union')
		local beastBabiesConfig_ = {}

		for k,v in pairs(beastBabiesConfig) do
			table.insert(beastBabiesConfig_, v)
		end

		table.sort(beastBabiesConfig_, function (a, b)
			local aBeastId = cardMgr.GetBeastIdByBeastBabyId(checkint(a.id))
			local aBeastConfig = cardMgr.GetBeastConfig(aBeastId)
			local bBeastId = cardMgr.GetBeastIdByBeastBabyId(checkint(b.id))
			local bBeastConfig = cardMgr.GetBeastConfig(bBeastId)

			if checkint(aBeastConfig.openUnionLevel) == checkint(bBeastConfig.openUnionLevel) then
				return checkint(a.id) < checkint(b.id)
			else
				return checkint(aBeastConfig.openUnionLevel) < checkint(bBeastConfig.openUnionLevel)
			end
		end)

		self.allBeastBabiesConfig = beastBabiesConfig_
	end
	return self.allBeastBabiesConfig
end
--[[
根据id获取神兽幼崽信息
@params id int id
@params _ table 幼崽信息
--]]
function UnionBeastBabyDevMediator:GetBeastBabyDataById(id)
	for i,v in ipairs(self:GetBeastBabiesData()) do
		if checkint(id) == checkint(v.petId) then
			return v
		end
	end
	return nil 
end
--[[
获取修正后的菜品数据
@params favoriteFoods list 喜欢的菜
@return fixedFoods list 修正后的菜品信息
--]]
function UnionBeastBabyDevMediator:GetFixedFoodsInfo(favoriteFoods)
	local fixedFoods = {}
	local favorFoodIds = {}
	-- 无论是否持有 解锁都先插入一次喜欢的菜品
	for _, favorFoodId in ipairs(checktable(favoriteFoods)) do
		local unlockFoodStyle, unlockFoodRecipe, gradeId = app.cookingMgr:GetFoodUnlockInfoByFoodId(checkint(favorFoodId))
		local foodInfo_ = {
			id = checkint(favorFoodId),
			unlockFoodStyle = unlockFoodStyle,
			unlockFoodRecipe = unlockFoodRecipe,
			amount = checkint(gameMgr:GetAmountByGoodId(favorFoodId)),
			gradeId = gradeId,
			favor = true
		}
		favorFoodIds[tostring(favorFoodId)] = true
		table.insert(fixedFoods, foodInfo_)
	end

	local foodsInBackpack = {}
	-- 插入一次拥有的菜品
	for _, goodsData in ipairs(gameMgr:GetUserInfo().backpack) do
		local goodsId = checkint(goodsData.goodsId)
		if favorFoodIds[tostring(goodsId)] then
			-- 如果背包里该物品是喜欢的菜 直接跳过
		else
			if GoodsType.TYPE_FOOD == CommonUtils.GetGoodTypeById(goodsId) then
				-- 如果是菜品 去掉精致的菜
				local goodsConfig = CommonUtils.GetConfig('goods', 'food', goodsId)
				if nil ~= goodsConfig and 1 == checkint(goodsConfig.quality) then
					local gradeId = 1
					local recipeData = app.cookingMgr:GetRecipeDataByRecipeId(checkint(goodsConfig.recipeId))
					if nil ~= recipeData then
						gradeId = checkint(recipeData.gradeId)
					end
					local foodInfo_ = {
						id = goodsId,
						unlockFoodStyle = true,
						unlockFoodRecipe = true,
						amount = checkint(goodsData.amount),
						gradeId = gradeId,
						favor = false
					}
					table.insert(foodsInBackpack, foodInfo_)
				end
			end
		end
	end

	-- 为背包中菜品排序
	table.sort(foodsInBackpack, function (a, b)
		if a.gradeId == b.gradeId then
			return a.id < b.id
		else
			return a.gradeId > b.gradeId
		end
	end)

	-- 整合一次数据
	table.insertto(fixedFoods, foodsInBackpack)

	return fixedFoods
end
--[[
获取神兽幼崽信息
--]]
function UnionBeastBabyDevMediator:GetBeastBabiesData()
	return self.beastBabiesData
end
function UnionBeastBabyDevMediator:SetBeastBabiesData(data)
	self.beastBabiesData = data
end
function UnionBeastBabyDevMediator:UpdateBeastBabyData(newData)
	for _, babyData in ipairs(self:GetBeastBabiesData()) do
		if checkint(newData.petId) == checkint(babyData.petId) and 0 ~= checkint(babyData.petId) then
			for k,v in pairs(newData) do
				if nil ~= babyData[k] then
					babyData[k] = v
				end
			end
		end
	end
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return UnionBeastBabyDevMediator
