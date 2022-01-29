--[[
卡片工具管理模块
--]]
local ManagerBase = require( "Frame.Manager.ManagerBase" )
---@class TastingTourManager
local TastingTourManager = class('TastingTourManager',ManagerBase)
TastingTourManager.instances = {}

-- 品鉴之旅单个探索任务最大星级
local TASTING_TOUR_SINGLE_QUEST_MAX_STAR_NUM = 3
---------------------------------------------------
-- mediator extend begin --
---------------------------------------------------
function TastingTourManager:ctor( key )
    self.super.ctor(self)
    if TastingTourManager.instances[key] ~= nil then
        funLog(Logger.INFO,"注册相关的facade类型" )
        return
    end
    self.parseConfig = nil
    self.homeData = {}  -- 关于菜系等级和星级的显示
    self.questGroupDatas = {} -- 区域数据
    self.leftSecondList = {} -- 倒计时列表
    self.cuisineGroupMaps = {}
    TastingTourManager.instances[key] = self
end
--[[
    初始化关卡的数据
--]]
function TastingTourManager:SetQuestStyleData(data,styleId)
    self.questData[tostring(styleId)] = data
end

function TastingTourManager:SetTotalRewardsMap()
    local homeData = self:GetStyleHomeData()
    local totalRewards = homeData.totalRewards
    homeData.totalRewards = {}
    for i, v in pairs(totalRewards) do
        for ii, vv in pairs(v) do
            if checkint(vv.id) then
                v[tostring(vv.id)] = vv
            end
        end
    end
    homeData.totalRewards = totalRewards
end
--[[
    更新获取奖励的状态
--]]
function TastingTourManager:SetTotalRewardsMapOneDataByZoneId(zoneId , data)
    local homeData = self:GetStyleHomeData()
    local totalRewards = homeData.totalRewards
    if totalRewards[tostring(zoneId)] then
        totalRewards[tostring(zoneId)][tostring(data.id)] = data
    else
        totalRewards[tostring(zoneId)] = {}
        totalRewards[tostring(zoneId)][tostring(data.id)] = data
    end
end

--[[
    根据styleId关卡的数据
--]]
function TastingTourManager:GetQuestStyleData(styleId)
     return  self.questData[tostring(styleId)]
end
--[[
 根据questId 和styleId 更新关卡信息
    	->data示例:<-
    	{
    	    grade =
    	    starNum =
    	    leftSeconds = 
    	}
--]]
function TastingTourManager:UpdateQuestIdByStyleIdAndQuestId(styleId, questId, data)
    local questData = self:GetQuestStyleData(styleId)
    for i, v in pairs(questData) do
        if checkint(v.questId) == checkint(questId) then

        end
    end
end
--[[
   设置菜谱数据总的信息
--]]
function TastingTourManager:SetStyleHomeData(data)
    self.homeData = data
    self:SetTotalRewardsMap()
    local maxLeftSecond = self:GetMaxLeftSecond(data.quests)
    if maxLeftSecond ~= 0 then
        self:StartCountDown(maxLeftSecond)
    end
end
--[[
   获取菜谱数据总的信息
--]]
function TastingTourManager:GetStyleHomeData()
    return self.homeData
end

--[[
    获取到CuisineTourConfigParser的对象
--]]
---@return CuisineConfigParser
function TastingTourManager:GetConfigParse()
    if not self.parseConfig then
        ---@type DataManager
        self.parseConfig = app.dataMgr:GetParserByName('cuisine')
    end
    return self.parseConfig
end


--[[
    获取到关卡的数据
--]]
function TastingTourManager:GetQuestData()
    return self.homeData.quests
end

function TastingTourManager:GetQuestOneDataByQuestId(id)
    return self.homeData.quests[tostring(id)] or {}
end
--[[
    data ={
       questId = '11'  这个是必须有的 其他的根据要求修改
    }
--]]
function TastingTourManager:setQuestOneData(data)
    local questData = self:GetQuestData()
    if questData[tostring(data.questId)] then
        if data.score  then
            for i, v in pairs(data) do
                if i == "score" then  -- 先比较sorce
                    if checkint(v) >=  checkint(questData[tostring(data.questId)].score)  then
                        questData[tostring(data.questId)].score = data.score
                        if data.foods and data.assistantId then
                            questData[tostring(data.questId)].bestFoods = {}
                            questData[tostring(data.questId)].bestFoods.foods = data.foods
                            questData[tostring(data.questId)].bestFoods.assistantId =  data.assistantId
                        end
                    end
                else
                    questData[tostring(data.questId)][tostring(i)] = v
                end
            end
        else
            table.merge(questData[tostring(data.questId)] , data)
        end
    else
        questData[tostring(data.questId)] = data
        if data.foods and data.assistantId then
            questData[tostring(data.questId)].bestFoods = {}
            questData[tostring(data.questId)].bestFoods.foods = data.foods
            questData[tostring(data.questId)].bestFoods.assistantId =  data.assistantId
        end
    end
end
--[[
    获取到大章节的星数
--]]
function TastingTourManager:GetStageStarNumByStyleId(styleId)
    local homeData = self:GetStyleHomeData()
    local cuisineStars = homeData.cuisineStars
    local starNum = 0
    if cuisineStars then
        for i, v in pairs(cuisineStars) do
            for iii, vvv in pairs(v) do
                if checkint(styleId)  == checkint(iii) then
                    starNum = checkint(vvv)
                    return starNum
                end
            end
        end
    end
    return starNum
end
function TastingTourManager.GetInstance(key)
    key = (key or "TastingTourManager")
    if TastingTourManager.instances[key] == nil then
        TastingTourManager.instances[key] = TastingTourManager.new(key)
    end
    return TastingTourManager.instances[key]
end

function TastingTourManager.Destroy( key )
    key = (key or "TastingTourManager")
    if TastingTourManager.instances[key] == nil then
        return
    end
    --清除配表数据
    TastingTourManager.instances[key] = nil
end

--[[
    根据zoneId 返回区域的总星数
]]
function TastingTourManager:GetZoneStarNumByZoneId(zoneId)
    local homeData = self:GetStyleHomeData()
    local cuisineStars = homeData.cuisineStars or {}
    for kk, vv in pairs(cuisineStars) do
        if checkint(kk) == checkint(zoneId) then
            local count = 0
            for iii, vvv in pairs(vv) do
                count = checkint(vvv) + count
            end
            return count
        end
    end
    return  0
end
--[[
    检测菜系是否解锁
    ]]
function TastingTourManager:CheckUnLockRecipeStyle(styleId)
    local cookingStyles = app.gameMgr:GetUserInfo().cookingStyles
    local parseConfig = self:GetConfigParse()
    -- 食谱的tag
    -- 大关卡的配表
    local stageConfig = self:GetConfigDataByName(parseConfig.TYPE.STAGE) or {}
    local isUnlock = 0
    for i, v in pairs(stageConfig) do
        -- 判断关卡是否有相同的菜系
        if checkint(v.cookId) == checkint(styleId) then  -- 说明是正常的菜谱关卡
            if cookingStyles[tostring(styleId)]
                    and table.nums(cookingStyles[tostring(styleId)]) >0  then
                isUnlock = 1
                break
            elseif checkint(styleId) < 0  then      -- 菜系的id 小于零的时候说明是混合考
                local count = self:GetZoneStarNumByZoneId(v.zoneId)
                if count >= checkint(v.unlockStarNum)  then
                    isUnlock = 1
                    break
                end
            end
        end
    end
    return isUnlock
end
--[[
    获取所有菜系的风格
--]]
function TastingTourManager:GetAllRecipeStyleAndStatus()
    ---@type CuisineConfigParser
    local parseConfig = self:GetConfigParse()
    -- 食谱的tag
    -- 大关卡的配表
    local stageConfig = self:GetConfigDataByName(parseConfig.TYPE.STAGE) or {}
    local stageData = {}
    for i, v in pairs(stageConfig) do
        stageData[#stageData+1] = clone(v)
        stageData[#stageData].isUnlock = self:CheckUnLockRecipeStyle(v.cookId)
    end
    return stageData
end
--[[
    根据区域id 获取当前区域的已经得到总星数
--]]
function TastingTourManager:GetZoneAlreadyStarNumByZoneId(zoneId)
    local cuisineStars = self.homeData.cuisineStars
    local count = 0
    for k ,v in pairs(cuisineStars[tostring(zoneId)] or {}) do
        count = count + checkint(v)
    end
    return count
end
-------------------------------------------------
function  TastingTourManager:GetConfigDataByName(name  )
    ---@type CuisineConfigParser
    local parseConfig = self:GetConfigParse()
    local configData  = parseConfig:GetVoById(name)
    return configData
end
--[[
    设置小本本的关卡数据

--]]
function TastingTourManager:SetQuestSecretFoods(questId , secretFoods)
    local quests = self:GetStyleHomeData().quests or {}
    for i, v in pairs(quests) do
        -- 查找到该关卡
        if checkint(v.questId) == checkint(questId)   then
            v.secretStatus = 1
            v.secretFoods = secretFoods
        end
    end
end
--[[
    根据关卡的id 获取到小本本的食物
--]]
function TastingTourManager:GetQuestSecretFoodsByQuestId(questId )
    local quests = self:GetStyleHomeData().quests or {}
    for i, v in pairs(quests) do
        -- 查找到该关卡
        if checkint(v.questId) == checkint(questId)   then
           return v.secretFoods or {}
        end
    end
    return  nil
end

--[[
    获取到餐厅里面的装饰数据
--]]
function TastingTourManager:GetRestaurantDecorationData()
    return self.homeData.location or {}
end
--[[
    获取到装饰的值
--]]
function TastingTourManager:GetDecorationValue()
    local avatarConfig = CommonUtils.GetConfigAllMess('avatar' , 'restaurant')
    local decorationValue = 0
    local location = self:GetRestaurantDecorationData()
    for i, v in pairs(location) do
        if avatarConfig[tostring(v.goodsId)] then
            local avatarOneConfig = avatarConfig[tostring(v.goodsId)]
            decorationValue = decorationValue + checkint(avatarOneConfig.beautyNum)
        end
    end
    return decorationValue
end
--[[
    设置族群领取的奖励
--]]
function TastingTourManager:SetGroupRewards(data)
    local data = data or {}
    local homeData = self:GetStyleHomeData()
    homeData.groupRewards = data
end
--[[
    设置族群领取的奖励
--]]
function TastingTourManager:GetGroupRewards()
    local homeData = self:GetStyleHomeData()
    return homeData.groupRewards or {}
end

--[[
   根据id 获取到奖励的data
--]]
function TastingTourManager:GetGroupRewardsByGroupRewardId(id)
    local groupRewardsData = self:GetGroupRewards()
    return groupRewardsData[tostring(id)] or  {}
end

--[[
    data = {
        id = '',
        hasDrawn = 0 ,
    }
--]]
function TastingTourManager:SetGroupDrawGroupReward(data)
    if data and checkint(data.id) > 0 then
        local groupRewards =  self:GetGroupRewards()
        groupRewards[tostring(data.id)] = data
    end
end

function TastingTourManager:GetGroupStarNum(stageId , id)
    local stageConfig = self:GetConfigDataByName(self:GetConfigParse().TYPE.STAGE)
    local stageOneConfig = stageConfig[tostring(stageId)]
    local questGroupConfig = self:GetConfigDataByName(self:GetConfigParse().TYPE.QUEST_GROUP)
    local zoneId = stageOneConfig.zoneId
    local oneGroupConfig = questGroupConfig[tostring(zoneId)][stageId][tostring(id)]
    local questData = self:GetQuestData()
    local starAlreadyNum = 0
    for i, v in pairs(oneGroupConfig) do
        local questOneData = questData[tostring(v)]
        if questOneData  then
            starAlreadyNum  = starAlreadyNum + checkint( questOneData.starNum)
        end
    end
    return starAlreadyNum
end

function TastingTourManager:GetGroupStarNumByQuestIds(questIds)
    questIds = questIds or {}
    local fishStarNum = 0
    for i, questId in ipairs(questIds) do
        local serQuestData = self:GetSerQuestDataByQuestId(questId)
        fishStarNum = fishStarNum + checkint(serQuestData.starNum)
    end
    return fishStarNum
end

function TastingTourManager:GetOneGroupRewardConfig(id)
    local groupRewardConfig = self:GetConfigDataByName(self:GetConfigParse().TYPE.GROUP_REWARDS)
    return groupRewardConfig[tostring(id)] or {}
end

--[[
    判断当前的groupId 的领取状态 0；未完成 1：可领取 2：已完成
--]]
function TastingTourManager:GetGroupRewardStatus(groupRewardId, fishStarNum)
    local rewardStatus = 0
    local oneGroupRewardConf = self:GetOneGroupRewardConfig(groupRewardId)
    local startNum = checkint(oneGroupRewardConf.starNum)
    if startNum <= fishStarNum then
        local groupOneRewards = self:GetGroupRewardsByGroupRewardId(groupRewardId)
        if checkint(groupOneRewards.hasDrawn) == 0 then
            rewardStatus = 1
        else
            rewardStatus = 2
        end
    end
    return rewardStatus
end

--[[
    判断当前的groupId 的领取状态 0 , 未领取 并且不能领取 ， 1 .已经领取 2. 满足领取条件
--]]
function TastingTourManager:JudageGroupRewardStatusByGroupId(stageId ,id)
    local groupOneRewards = self:GetGroupRewardsByGroupRewardId(id)
    -- 关卡的配置
    if checkint(groupOneRewards.hasDrawn) == 0  then
        local groupOneConfig = self:GetOneGroupRewardConfig(id)
        local startNum = checkint(groupOneConfig.starNum)
        local  starAlreadyNum  = self:GetGroupStarNum(stageId, id)
        groupOneRewards.startNum = startNum
        if starAlreadyNum >= startNum  then
            groupOneRewards.hasDrawn = 2
        else
            groupOneRewards.hasDrawn =  0
        end
        local groupRewards =  self:GetGroupRewards()
        groupRewards[tostring(id)] = groupOneRewards
    end
    return groupOneRewards.hasDrawn
end

--[[
    获取到章节的总星数
--]]
function TastingTourManager:GetStageCountStarById(id)
    local configTypeTable = self:GetConfigParse().TYPE
    local questGroupConfig = self:GetConfigDataByName(configTypeTable.QUEST_GROUP)
    local stageConfig  = self:GetConfigDataByName(configTypeTable.STAGE)
    local stageOneConfig = stageConfig[tostring(id)]
    if stageOneConfig then
        local zoneId = stageOneConfig.zoneId
        local questStage = questGroupConfig[tostring(zoneId)]
        local count = 0
        for i, v in pairs(questStage[tostring(id)]) do
            count = table.nums(v) + count
        end
        return count * 3
    end
    return  0
end
--[[
    根据关卡属性和食物tag分类
--]]
function TastingTourManager:GetSortRecipeByAttrAndFoodTag(styleId,attr , foodTag)
    local styleData = app.gameMgr:GetUserInfo().cookingStyles[tostring(styleId)] or {}
    if table.nums(styleData) > 0 then
        ---@type CuisineConfigParser
        local parseConfig = self:GetConfigParse()
        -- 食谱的tag
        local foodTagConfig = self:GetConfigDataByName(parseConfig.TYPE.FOOD_TAG) or {}
        local recipeKeyTable  = {}
        local recipeTable = {}
        for k ,v in pairs(styleData) do
            local data =  foodTagConfig[tostring(v.recipeId)] or {}
            if checkint(data.foodTagMainType) == foodTag  or foodTag == 0  then
                recipeKeyTable[#recipeKeyTable+1] = v.recipeId
                recipeTable[tostring(v.recipeId)] =  v
            end
        end
        local recipeConnfig = CommonUtils.GetConfigAllMess('recipe','cooking')
        -- 种类的table
        if attr == 'all' then  -- 按照菜谱的等级排序
            table.sort(recipeKeyTable , -- 按照成长的总值排序
            function (a,b )
                if checkint(recipeTable[tostring(a)].growthTotal) <=  checkint(recipeTable[tostring(b)].growthTotal) then
                    return false
                end
                return true
            end)
        else
            -- 判断是否又该属性
            table.sort(recipeKeyTable,
            function (a,b)
                if checkint(recipeConnfig[tostring(a)][attr]) <=    checkint(recipeConnfig[tostring(b)][attr]) then
                    return false
                end
                return true
            end)
            --for i, v in pairs(recipeKeyTable) do
            --    print(recipeConnfig[tostring(v)][attr])
            --end
        end
        local sortTable = {}
        for k ,v in pairs(recipeKeyTable) do
            sortTable[#sortTable+1] = recipeTable[tostring(v)]
        end
        local foodTagConfig =  self:GetConfigDataByName(self:GetConfigParse().TYPE.FOOD_TAG)
        local recipeConfig  = CommonUtils.GetConfigAllMess('recipe' , 'cooking')

        for i, v in pairs(foodTagConfig) do
            if  (not  recipeTable[tostring(v.id)])  and
                    ( checkint(recipeConfig[tostring(v.id)].cookingStyleId) == checkint(styleId)  or checkint(styleId) == -1)   then
                if checkint(v.foodTagMainType)  == checkint(foodTag)  or  foodTag == 0  then
                    sortTable[#sortTable+1] = {
                        recipeId    = v.id,
                        taste       = 0,
                        museFeel    = 0,
                        fragrance   = 0,
                        exterior    = 0,
                        growthTotal = 0
                    }
                end
            end
        end
        return sortTable
    end
    return {}
end

--[[
    获得关卡最大剩余倒计时时间
--]]
function TastingTourManager:GetMaxLeftSecond(quests)
    local maxLeftSecond = 0
    self.leftSecondList  = {}
    for questId, quest in pairs(quests) do
        local leftSeconds = checkint(quest.leftSeconds)
        if leftSeconds > 0 and checkint(quest.starNum) < TASTING_TOUR_SINGLE_QUEST_MAX_STAR_NUM then
            self:AddLeftSecond(questId, leftSeconds)
            maxLeftSecond = math.max(maxLeftSecond, leftSeconds)
        end
    end
    return maxLeftSecond
end

function TastingTourManager:StartCountDown(leftSecond)
    self.preTime = checkint(leftSecond)
    local timerInfo = app.timerMgr:RetriveTimer(COUNT_DOWN_TAG_TASTING_TOUR_QUEST)
    if timerInfo then
        local countdown = checkint(timerInfo.countdown)
        leftSecond = math.max(leftSecond, countdown)
        timerInfo.countdown = leftSecond
        self.preTime = leftSecond
    else
        local callback = function (countdown, remindTag, timeNum, params, name)
            local deltaTime = self.preTime - countdown
            self.preTime = countdown
            for questId, leftSecond in pairs(self.leftSecondList) do
                local time = checkint(leftSecond) - deltaTime
                leftSecond = math.max(time, 0)
                if leftSecond <= 0 then 
                    self:ClearLeftSecondByQuestId(questId)
                    self:setQuestOneData({questId = questId, leftSeconds = 0})
                    -- 检查 是否移除倒计时
                    if next(self.leftSecondList) == nil then
                        app.timerMgr:RemoveTimer(COUNT_DOWN_TAG_TASTING_TOUR_QUEST)
                    end
                else
                    self:AddLeftSecond(questId, leftSecond)
                    self:setQuestOneData({questId = questId, leftSeconds = leftSecond})
                end
            end
            
            self:GetFacade():DispatchObservers(COUNT_DOWN_ACTION_UI_ACTION_TASTING_TOUR_QUEST)
        end
        app.timerMgr:AddTimer({name = COUNT_DOWN_TAG_TASTING_TOUR_QUEST, countdown = leftSecond, callback = callback})
    end
end

function TastingTourManager:AddLeftSecond(questId, leftSecond)
    self.leftSecondList[tostring(questId)] = leftSecond
end

function TastingTourManager:ClearLeftSecondByQuestId(questId)
    self.leftSecondList[tostring(questId)] = nil
end

function TastingTourManager:GetLeftSecondList()
    return self.leftSecondList
end

--[[
    添加新的探索数据
--]]
function TastingTourManager:IsCanUnlockNextGroup(stageId, groupId)
    local configTypeTable   = self:GetConfigParse().TYPE
    local groupConfig       = self:GetConfigDataByName(configTypeTable.GROUP)
    local groupConf         = groupConfig[tostring(groupId)]
    local openLevel         = chekint(groupConf.level)
    local curRestaurantLevel = checkint(app.gameMgr:GetUserInfo().restaurantLevel)

    -- 能解锁下一group的条件 1. 有配表 2.区域相同同 3. 达到对应的餐厅等级
    return groupConf ~= nil and checkint(groupConf.stageId) == checkint(stageId) and openLevel <= curRestaurantLevel
end

--[[
    添加新的探索数据
--]]
function TastingTourManager:AddQuestDatas(zoneId, stageId, groupId)
    
    -- 没有 探索组数据 或 要加的探索组 不是 传入的探索组 (一般是 最后一组数据了)
    if not self:IsCanUnlockNextGroup(stageId, groupId) then return end

    local configTypeTable   = self:GetConfigParse().TYPE
    local questGroupConfig  = self:GetConfigDataByName(configTypeTable.QUEST_GROUP)
    local questsConf        = questGroupConfig[tostring(zoneId)][tostring(stageId)][tostring(groupId)]
    
    local homeDatas = self:GetStyleHomeData() or {}
    local quests    = homeDatas.quests or {}
    
    for i, questId in ipairs(questsConf) do
        local data = {
            questId = questId,
            starNum = 0,
            leftSeconds = 0,
            secretStatus = 0,
        }
        self:setQuestOneData(data)
    end

end

--[[
    获得已经解锁的料理组
--]]
function TastingTourManager:GetCuisineGroups()
    local homeDatas = self:GetStyleHomeData() or {}
    return homeDatas.cuisineGroups or {}
end

--[[
    获得已经解锁的料理组map格式
--]]
function TastingTourManager:GetCuisineGroupMaps()
    local cuisineGroups    = self:GetCuisineGroups()
    -- if next(cuisineGroups) == nil then return {} end
    if next(self.cuisineGroupMaps) ~= nil then return self.cuisineGroupMaps end
    return self:SetCuisineGroupMaps(cuisineGroups)
end

--[[
    设置map格式已经解锁的料理组
--]]
function TastingTourManager:SetCuisineGroupMaps(cuisineGroups)
    local cuisineGroupMaps = {}
    -- 1.获取 已经解锁的料理组 长度
    for i, cuisineGroup in ipairs(cuisineGroups) do
        cuisineGroupMaps[tostring(cuisineGroup)] = i
    end
    
    self.cuisineGroupMaps = cuisineGroupMaps
    return cuisineGroupMaps
end

function TastingTourManager:MergeCuisineGroupMaps(cuisineGroupMaps)
    if cuisineGroupMaps == nil or next(cuisineGroupMaps) == nil then return end
    
    table.merge(self.cuisineGroupMaps,cuisineGroupMaps)
end

function TastingTourManager:InitQuestGroupDatas(zoneId, stageId)
    local configTypeTable   = self:GetConfigParse().TYPE
    local questGroupConfig  = self:GetConfigDataByName(configTypeTable.QUEST_GROUP)
    
    -- 1.获取所有 探索组配置
    local questGroupsConf   = questGroupConfig[tostring(zoneId)][tostring(stageId)]
    if questGroupsConf == nil then return {} end
    local questGroupDatas = {}
    -- 2.获取 当前的探索组id 并填充数据
    local index = 0           -- 当前group index
    local curGroupId = 0      -- 当前group id
    for groupId, questIds in pairs(questGroupsConf) do
        local unlocked = self:CheckIsUnlockedGroup(groupId)
        -- 如果已经解锁 则保留最大的groupId 
        if unlocked then
            curGroupId = math.max(curGroupId, checkint(groupId))
        end
        local questGroupData = {unlocked = unlocked, groupId = groupId, questIds = questIds}

        table.insert(questGroupDatas, questGroupData)
    end

    self.questGroupDatas = questGroupDatas
    self:SortQuestGroupDatas()
    local questIndex = 1
    
    -- 3.检查当前组的完成状态
    if curGroupId ~= 0 then
        -- 3.1 添加完成状态
        for i, questGroupData in ipairs(questGroupDatas) do
            if checkint(questGroupData.groupId) == curGroupId then
            -- 3.1 检查当前组的完成状态
                local questIds = questGroupData.questIds or {}
                local isComplete, curQuestIndex = self:CheckQuestGroupCompleteState(questIds)
                questGroupData.isComplete = isComplete
                index = i
                questIndex = curQuestIndex
                -- 如果当前组 已经完成 那么 检查下一组 是否能解锁 如果能解锁 那个 给个能解锁的状态
                if isComplete and questGroupDatas[i + 1] then
                    local nextQuestGroupData = questGroupDatas[i + 1]
                    local groupId = nextQuestGroupData.groupId
                    local nextGroupConf = self:GetGroupConfDataByGroupId(groupId)
                    local nextGroupUnlockLv = checkint(nextGroupConf.level)
                    local curRestaurantLevel = checkint(app.gameMgr:GetUserInfo().restaurantLevel)
                    if curRestaurantLevel >= nextGroupUnlockLv then
                        nextQuestGroupData.canUnlock = true
                    end
                end
            elseif checkint(questGroupData.groupId) < curGroupId then
            -- 3.2 由于 探索组 是只有当前 上一组探索任务全部完成 才能解锁  所以可以得出只要小于最新组 那么必已经完成  
                questGroupData.isComplete = true
            end
        end
    else
        index = 0
    end

    return index, questIndex
end

--[[
    检查是否解锁过该组
--]]
function TastingTourManager:CheckIsUnlockedGroup(groupId)
    local cuisineGroupMaps     = self:GetCuisineGroupMaps()
    return checkint(cuisineGroupMaps[tostring(groupId)]) > 0
end

--[[
    检查探索组完成状态
--]]
function TastingTourManager:CheckQuestGroupCompleteState(questIds)
    -- 获取关卡数据
    local questDatas = self:GetQuestData() or {}
    -- 每个组 探索总数
    local questTotalCount = #questIds
    -- 完成探索的个数
    local questCompleteCount = 0
    local curQuestIndex = 1
    for i = 1, questTotalCount do
        local questId = questIds[i]
        local serQuestData = questDatas[tostring(questId)] or {}
        local starNum   = checkint(serQuestData.starNum)
        if starNum < TASTING_TOUR_SINGLE_QUEST_MAX_STAR_NUM then
            curQuestIndex = i
            break
        else
            questCompleteCount = questCompleteCount + 1
        end
    end
    
    local isComplete = questCompleteCount == questTotalCount
    return isComplete, curQuestIndex
end

--[[
    通过组id获得探索组配表数据
--]]
function TastingTourManager:GetGroupConfDataByGroupId(groupId)
    local configTypeTable   = self:GetConfigParse().TYPE
    local groupConfig       = self:GetConfigDataByName(configTypeTable.GROUP)
    
    local groupConfData = groupConfig[tostring(groupId)] or {}
    return groupConfData
end

--[[
    通过探索id获得探索配表数据
--]]
function TastingTourManager:GetQuestConfigDataByQuestId(questId)
    local configTypeTable   = self:GetConfigParse().TYPE
    local questConfig       = self:GetConfigDataByName(configTypeTable.QUEST)

    local confData = questConfig[tostring(questId)] or {}
    
    return confData
end

--[[
    通过探索id获得服务端探索数据
--]]
function TastingTourManager:GetSerQuestDataByQuestId(questId)
    local questDatas = self:GetQuestData() or {}
    local serQuestData = questDatas[tostring(questId)] or {}
    return serQuestData
end

--[[
    给探索组排序
--]]
function TastingTourManager:SortQuestGroupDatas()
    local datas = self:GetQuestGroupDatas()
    local defGroupSorter = function (a, b)
        if a == nil then return true end
        if b == nil then return false end

        local aGroupId = checkint(a.groupId)
        local bGroupId = checkint(b.groupId)

        return aGroupId < bGroupId
    end

    table.sort(datas, defGroupSorter)
end

--[[
    给探索数据排序
--]]
function TastingTourManager:SortQuestDatas(questDatas)
    local getQuestPriority = function (data)
        local priority = 0
        local isComplete = data.isComplete
        local isStartCountDown = checkint(data.questSerData.leftSeconds) > 0
        if isComplete then
            priority = 0
        elseif isStartCountDown then
            priority = 1
        else
            priority = 2
        end
        local id = checkint(data.questConfData.id)
        return priority, id
    end

    local defQuestSorter = function (a, b)
        if a == nil then return true end
        if b == nil then return false end

        local aPriority, aId = getQuestPriority(a)
        local bPriority, bId = getQuestPriority(b)
        if aPriority == bPriority then
            return aId < bId
        end
        return aPriority > bPriority
    end

    table.sort(questDatas, defQuestSorter)
end

function TastingTourManager:GetQuestGroupDatas()
    return self.questGroupDatas
end

function TastingTourManager:GetStageConfByStageId(stageId)
    local configTypeTable   = self:GetConfigParse().TYPE
    local stageConfigs       = self:GetConfigDataByName(configTypeTable.STAGE) or {}
    return stageConfigs[tostring(stageId)] or {}
end

function TastingTourManager:GetStageNameByStageId(stageId)
    local stageConfig       = self:GetStageConfByStageId(stageId)
    local name = stageConfig.name or ''
    return name
end


return TastingTourManager
