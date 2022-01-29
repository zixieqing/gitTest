--[[
 * author : kaishiqi
 * descpt : 小红点 管理器
]]
local BaseManager  = require('Frame.Manager.ManagerBase')
---@class BadgeManager : BaseManager
local BadgeManager = class('BadgeManager', BaseManager)


-------------------------------------------------
-- manager method

BadgeManager.DEFAULT_NAME = 'BadgeManager'
BadgeManager.instances_   = {}


function BadgeManager.GetInstance(instancesKey)
    instancesKey = instancesKey or BadgeManager.DEFAULT_NAME

    if not BadgeManager.instances_[instancesKey] then
        BadgeManager.instances_[instancesKey] = BadgeManager.new(instancesKey)
    end
    return BadgeManager.instances_[instancesKey]
end


function BadgeManager.Destroy(instancesKey)
    instancesKey = instancesKey or BadgeManager.DEFAULT_NAME

    if BadgeManager.instances_[instancesKey] then
        BadgeManager.instances_[instancesKey]:release()
        BadgeManager.instances_[instancesKey] = nil
    end
end


-------------------------------------------------
-- life cycle

function BadgeManager:ctor(instancesKey)
    self.super.ctor(self)

    if BadgeManager.instances_[instancesKey] then
        funLog(Logger.INFO, "注册相关的facade类型")
    else
        self:initial()
    end
end


function BadgeManager:initial()
    self.cardCollTaskDataMap_  = {}  -- 收集任务数据二维字典 { [groupId : int] = { [taskType : int] = progressNum : int, ... }, ... }
    self.cardCollTaskRedMap_   = {}  -- 收集任务红点二维字典 { [groupId : int] = { [taskType : int] = isHasRed : bool, ... }, ... }
    self.cardCollTaskConfMap_  = {}  -- 收集类型对应的收集配表字典 { [taskType : int] = taskConf, ... }
    self.cardCollTaskGroupMap_ = {}  -- 飨灵id对应的收集组别id字典 { [cardId : int] = { groupId : int, ... }, ... }
    self.cardSkinStatueMap_    = {}  -- 新获得的皮肤

    -- grouping card coll task conf by task type
    for _, taskConf in pairs(CONF.CARD.CARD_COLL_TASK:GetAll()) do
        local taskType = checkint(taskConf.taskType)
        if not self.cardCollTaskConfMap_[taskType] then
            self.cardCollTaskConfMap_[taskType] = {}
        end
        table.insert(self.cardCollTaskConfMap_[taskType], taskConf)
    end

    -- grouping groupId by cardId
    for _, groupInfo in pairs(CONF.CARD.CARD_COLL_BOOK:GetAll()) do
        for _, cardId in ipairs(groupInfo.cardIds) do
            if not self.cardCollTaskGroupMap_[checkint(cardId)] then
                self.cardCollTaskGroupMap_[checkint(cardId)] = {}
            end
            table.insert(self.cardCollTaskGroupMap_[checkint(cardId)], checkint(groupInfo.id))
        end
    end

    AppFacade.GetInstance():RegistObserver(SGL.CARD_COLL_RED_DATA_UPDATE, mvc.Observer.new(self.onCardCollTaskDataChangeHandler_, self))
    AppFacade.GetInstance():RegistObserver(SGL.CARD_COLL_GET_REWARD_HANDLER, mvc.Observer.new(self.onCardCollGetRewardHandler_, self))
    AppFacade.GetInstance():RegistObserver(SGL.SKIN_COLL_RED_DATA_UPDATE, mvc.Observer.new(self.updateSkinCollTaskRedStatueHandler_, self))
    AppFacade.GetInstance():RegistObserver(SGL.CARD_SKIN_NEW_GET, mvc.Observer.new(self.updateNewCardSkinRedStatueHandler_, self))
end


function BadgeManager:release()
    self.cardCollTaskConfMap_  = {}
    self.cardCollTaskRedMap_   = {}
    self.cardCollTaskConfMap_  = {}
    self.cardCollTaskGroupMap_ = {}
    self.cardSkinStatueMap_    = {}
    AppFacade.GetInstance():UnRegistObserver(SGL.CARD_COLL_RED_DATA_UPDATE, self)
    AppFacade.GetInstance():UnRegistObserver(SGL.CARD_COLL_GET_REWARD_HANDLER, self)
    AppFacade.GetInstance():UnRegistObserver(SGL.SKIN_COLL_RED_DATA_UPDATE, self)
    AppFacade.GetInstance():UnRegistObserver(SGL.CARD_SKIN_NEW_GET, self)
end


-------------------------------------------------
-- handler

--[[
--更新飨灵收集红点数据
--]]
function BadgeManager:onCardCollTaskDataChangeHandler_(signal)
    local data = signal:GetBody()

    local groupIds = self:getCardCollTaskGroupIdsByCardId_(data.cardId)
    if next(groupIds) == nil then
        return
    end

    for _, groupId in ipairs(groupIds) do
        self:updateCardCollTaskRedData_(checkint(groupId), checkint(data.taskType), data.addNum)
    end
end

function BadgeManager:onCardCollGetRewardHandler_(signal)
    local data = signal:GetBody()

    local groupId = checkint(data.groupId)
    for _, taskId in ipairs(data.idList) do
        if not app.gameMgr:GetUserInfo().cardCollectionBookMap[groupId] then
            app.gameMgr:GetUserInfo().cardCollectionBookMap[groupId] = {}
        end
        app.gameMgr:GetUserInfo().cardCollectionBookMap[groupId][checkint(taskId)] = true
    end

    if #data.idList <= 1 then
        local taskConf = CONF.CARD.CARD_COLL_TASK:GetValue(data.idList[1])
        local taskType = taskConf.taskType
        self:updateCardCollTaskRedData_(groupId, checkint(taskType), 0)
    else
        for _, taskType in pairs(CardUtils.CARD_COLL_TASK_TYPE) do
            self:setCardCollTaskRedDataByGroupAndTaskType_(groupId, checkint(taskType), false)
        end
        self:setCardCollTaskRedDataByGroup_(groupId, false)
        -- 进行根节点的刷新检测
        self:setCardCollTaskRedData_()
    end
end


-------------------------------------------------
-- public method

--==============================--
--desc:该方法是用于判断是否可以满足外卖车升级
-- 添加红点判断
--time:2017-07-14 02:42:27
--@return
--==============================--
function BadgeManager:JudageTakeAwayCarAddRed()
    local isStaisty = false
    if CommonUtils.UnLockModule(RemindTag.CARVIEW) then
        -- 判断是否到达解锁的等级
        local takeAwayData  = app.takeawayMgr:GetDatas()
        local diningCarData = takeAwayData.diningCar or {}

        --if table.nums(diningCarData) > 0 then
        --    local diningCarLevelTable = CommonUtils.GetConfigAllMess('diningCarLevelUp', 'takeaway')
        --    -- 升级条件表
        --    local countLevel = table.nums(diningCarLevelTable)
        --
        --    for k, v in pairs(diningCarData) do
        --        local isStaistyUpgrade = true
        --        -- 判断是否满足升级的要求 满级的时候将不升级
        --        if checkint(v.status) ==4 or (v.status ==3 and checkint(v.leftSeconds) == 0 ) then
        --            isStaistyUpgrade = false
        --        elseif checkint(v.level) == countLevel then
        --            isStaistyUpgrade = false
        --        else
        --            local consumeGoods = diningCarLevelTable[tostring(v.level + 1)].consumeGoods
        --            if consumeGoods and #consumeGoods == 0 then
        --
        --                isStaistyUpgrade = true
        --                isStaisty = true
        --                app.dataMgr:AddRedDotNofication("TakeAway", tostring(k))
        --            else
        --                for k, v in pairs(consumeGoods) do
        --                    local countConsume = v.num
        --                    local countOwner = CommonUtils.GetCacheProductNum(v.goodsId)
        --                    if checkint(countConsume) > checkint(countOwner) then
        --                        -- 比较已经拥有的和未拥有的
        --                        isStaistyUpgrade = false
        --                        break
        --                    end
        --                end
        --            end
        --        end
        --        if isStaistyUpgrade then -- 外部只做单个判断 内部去做同意判断
        --            isStaisty = true
        --            break
        --        end
        --    end
        --end
        if not isStaisty then
            -- 下面这个判断是外卖车是否可以解锁
            local carNum = table.nums(diningCarData)
            if carNum < DINING_CAR_LIMITE_NUM then
                local diningCarUnLockTable = CommonUtils.GetConfigAllMess('diningCar', 'takeaway')
                for i = 1, DINING_CAR_LIMITE_NUM do
                    -- 外卖车不一定是按照顺序解锁的 所以这里
                    local isHave = false
                    for k, v in pairs(diningCarData) do
                        if checkint(v.diningCarId) == i then
                            isHave = true
                        end
                    end
                    if not isHave then
                        local isUnlock = (not CommonUtils.CheckLockCondition(checktable(diningCarUnLockTable[tostring(carNum + 1)]).unlockType))
                        if isUnlock then
                            isStaisty = isUnlock
                            break
                        end
                    end
                end

            end
        end
    end
    -- 全部归类到订单的接口
    if isStaisty then
        app.dataMgr:AddRedDotNofication( tostring(RemindTag.ORDER), tostring( RemindTag.ORDER))
    end
    AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, { countdown = 0, tag = RemindTag.ORDER })
    app.gameMgr:GetUserInfo().isCardRed = isStaisty
    return isStaisty
end


-- 检测个人信息是否添加红点
function BadgeManager:CheckHomeInforRed()
    local isRed = false
    if CommonUtils.GetIsOpenPhone() then
        if app.gameMgr:GetUserInfo().isFirstPhoneLock == 1 then
            isRed = true
        end
    end
    if app.gameMgr:GetUserInfo().personalMessage == 1 then
        isRed = true
    end
    if isElexSdk() then
        if app.gameMgr:GetUserInfo().isGuest == 1 then
            isRed = true 
        end 
    end 
    
    --判断是否开启新创觉
    if GAME_MODULE_OPEN.NEW_CREATE_ROLE then
        local gameMgr = app.gameMgr
        local userInfo = gameMgr:GetUserInfo()
        local birthday = userInfo.birthday
        if string.len(birthday) == 0  then
            isRed = true
        end
    end
    if isRed then
        app.dataMgr:AddRedDotNofication(RemindTag.MYSELF_INFOR, RemindTag.MYSELF_INFOR, "[主界面-个人信息]BadgeManager:CheckHomeInforRed")
    else
        app.dataMgr:ClearRedDotNofication(RemindTag.MYSELF_INFOR, RemindTag.MYSELF_INFOR, "[主界面-个人信息]BadgeManager:CheckHomeInforRed")
    end
    AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, { countdown = 0, tag = RemindTag.MYSELF_INFOR })
end


--[[
检测哪个区域有红点
--]]
function BadgeManager:CheckTastingTourZoneRed()
    local redTable  =  {}
    ---@type TastingTourManager
    local tastingTourMgr = app.cuisineMgr
    local homeData = tastingTourMgr:GetStyleHomeData()
    local cuisineStars = homeData.cuisineStars or {}
    local totalRewardConfig = tastingTourMgr:GetConfigDataByName(tastingTourMgr:GetConfigParse().TYPE.TOTAL_REWARDS)
    local zoneRewardTable = {}
    local totalRewards = homeData.totalRewards or {}
    for i, v in pairs(totalRewardConfig) do
        if not  zoneRewardTable[tostring(v.zoneId)] then
            zoneRewardTable[tostring(v.zoneId)] = {}
        end
        zoneRewardTable[tostring(v.zoneId)][tostring(v.id)] = v
    end
    local zoneNumTable = {}
    for i, v in pairs(cuisineStars) do
        for ii, vv in pairs(v) do
            zoneNumTable[tostring(i)] = checkint(zoneNumTable[tostring(i)]) + vv
        end
    end
    for i, v in pairs(zoneNumTable) do
        for ii, vv in pairs(zoneRewardTable[tostring(i)] or {}) do
            if checkint(v ) >= checkint(vv.starNum )  then -- 判断星级是否满足 ，
                totalRewards[tostring(i)] = totalRewards[tostring(i)] or {}
                totalRewards[tostring(i)][tostring(vv.id)] =  totalRewards[tostring(i)][tostring(vv.id)] or {}
                local hasDrawn = checkint(totalRewards[tostring(i)][tostring(vv.id)].hasDrawn)
                if hasDrawn == 0 or hasDrawn == 2  then -- 判断是否领取过
                    redTable[tostring(i)] = checkint(redTable[tostring(i)]) +1
                end
            end
        end
    end
    if next(redTable) then --- 此处给红点的判断复制
        app.gameMgr:GetUserInfo().zoneCuisine = 1
    else
        app.gameMgr:GetUserInfo().zoneCuisine = 0
    end
    return redTable
end


--[[
检测料理副本功能红点
--]]
function BadgeManager:CheckTastingTourRed()
    local isRed = app.gameMgr:GetUserInfo().zoneCuisine
    if isRed == 1  then
        app.dataMgr:AddRedDotNofication(tostring(RemindTag.TASTINGTOUR) ,RemindTag.TASTINGTOUR, "[料理副本]BadgeManager:CheckTastingTourRed")
    else
        app.dataMgr:ClearRedDotNofication(tostring(RemindTag.TASTINGTOUR) ,RemindTag.TASTINGTOUR ,"[料理副本]BadgeManager:CheckTastingTourRed")
    end
    AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, { countdown = 0  , tag  = RemindTag.TASTINGTOUR  })
end


--[[
检测工会任务的红点
--]]
function BadgeManager:CheckUnionTaskRed()
    if not app.gameMgr:hasUnion() then
        app.gameMgr:GetUserInfo().unionTaskCacheData_ = {}
    end

    local isRed = checkint(app.gameMgr:GetUserInfo().unionTaskCacheData_.canReceiveCount) > 0

    if isRed then
        app.dataMgr:AddRedDotNofication(tostring(RemindTag.UNION_TASK) ,RemindTag.UNION_TASK , "[工会任务]BadgeManager:CheckUnionTaskRed")
    else
        app.dataMgr:ClearRedDotNofication(tostring(RemindTag.UNION_TASK) ,RemindTag.UNION_TASK, "[工会任务]BadgeManager:CheckUnionTaskRed")
    end
    AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.UNION_TASK})
    return isRed
end


--[[
检测工会申请的红点
--]]
function BadgeManager:CheckUnionApplyRed()
    local mediator = AppFacade.GetInstance():RetrieveMediator("UnionApplyMediator")
    local isRed = false
    if mediator then
        app.unionMgr.applyMessage  = 0
    end
    if  app.unionMgr.applyMessage == 1 and   checkint(app.unionMgr:getUnionData().job) < UNION_JOB_TYPE.COMMON  and  checkint(app.unionMgr:getUnionData().job) > 0   then
        isRed = true
        app.dataMgr:AddRedDotNofication(tostring(RemindTag.UNION_INFO) ,RemindTag.UNION_INFO, "[工会申请]BadgeManager:CheckUnionApplyRed")
    else
        isRed = false
        app.unionMgr.applyMessage  = 0
        app.dataMgr:ClearRedDotNofication(tostring(RemindTag.UNION_INFO) ,RemindTag.UNION_INFO, "[工会申请]BadgeManager:CheckUnionApplyRed")
    end
    AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, { countdown = 0  , tag  = RemindTag.UNION_INFO  })
    return isRed
end


--[[
检测工会是否添加红点
--]]
function BadgeManager:CheckUnionRed()
    local isRed = false
    if self:CheckUnionApplyRed() then
        isRed = true
    end
    if self:CheckUnionTaskRed() then
        isRed = true
    end
    if isRed then
        app.dataMgr:AddRedDotNofication(tostring(RemindTag.UNION) ,RemindTag.UNION, "[工会]BadgeManager:CheckUnionRed")
    else
        app.dataMgr:ClearRedDotNofication(tostring(RemindTag.UNION) ,RemindTag.UNION ,"[工会]BadgeManager:CheckUnionRed")
    end
    AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, { countdown = 0  , tag  = RemindTag.UNION  })
end


--[[
检测日常是否添加红点 (日常任务和成就任务)
--]]
function BadgeManager:CheckTaskHomeRed()
    local isShowRed = false

    -- check daily red point
    if checkint(app.gameMgr:GetUserInfo().dailyTaskCacheData_.daily) > 0 or
       checkint(app.gameMgr:GetUserInfo().dailyTaskCacheData_.activePoint) > 0 then
        isShowRed = true
    end

    -- check achievement red point
    if checkint(app.gameMgr:GetUserInfo().achievementCacheData_.canReceiveCount) > 0 then
        isShowRed = true
    end

    -- checkint union task red point
    if app.gameMgr:hasUnion() and checkint(app.gameMgr:GetUserInfo().unionTaskCacheData_.canReceiveCount) > 0 then
        isShowRed = true
    end

    if isShowRed then
        app.dataMgr:AddRedDotNofication(tostring(RemindTag.TASK), RemindTag.TASK, "[日常-成就-工会任务]BadgeManager:CheckTaskHomeRed")
    else
        app.dataMgr:ClearRedDotNofication(tostring(RemindTag.TASK),RemindTag.TASK, "[日常-成就-工会任务]BadgeManager:CheckTaskHomeRed")
    end
    AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.TASK})
end


function BadgeManager:refreshDailyTaskCacheData(body)
    local isRequestDailyTask = app.gameMgr:GetUserInfo().dailyTaskCacheData_.isRequestDailyTask
    app.gameMgr:GetUserInfo().dailyTaskCacheData_ = {
        daily       = 0,
        activePoint = 0,
        isRequestDailyTask = isRequestDailyTask
    }
    local taskList = body.tasks or {}
    local taskCanReceiveCount = 0
    for i, task in pairs(taskList) do
        if checkint(task.hasDrawn) == 0 and checkint(task.progress) >= checkint(task.targetNum) then
            taskCanReceiveCount = taskCanReceiveCount + 1
        end
    end

    local curActivePoint      = checkint(body.activePoint)
    local activePointRewards  = body.activePointRewards or {}
    local activePointCanReceiveCount = 0
    for i, activePointReward in ipairs(activePointRewards) do
        if activePointReward.hasDrawn == 0 and curActivePoint >= checkint(activePointReward.activePoint) then
            activePointCanReceiveCount = activePointCanReceiveCount + 1
        end
    end
    app.gameMgr:GetUserInfo().dailyTaskCacheData_.daily       = taskCanReceiveCount
    app.gameMgr:GetUserInfo().dailyTaskCacheData_.activePoint = activePointCanReceiveCount

    app.badgeMgr:CheckTaskHomeRed()
end


function BadgeManager:initAchievementCacheData(body)
    app.gameMgr:GetUserInfo().achievementCacheData_ = {
        canReceiveCount    = 0,     -- 能领取的个数
        unreceivedTaskList = {}     -- 未领取的任务列表(只有在这个列表的才是有效的taskId)
    }
    local taskList = body.tasks or {}
    for i, task in ipairs(taskList) do
        local taskId   = tostring(task.taskId)
        local taskConf = CommonUtils.GetConfig('task', 'task', taskId)
        if taskConf then
            local progress  = checkint(task.progress)
            local targetNum = checkint(taskConf.targetNum)

            if targetNum > 0 then
                if progress >= targetNum then
                    app.gameMgr:GetUserInfo().achievementCacheData_.canReceiveCount = app.gameMgr:GetUserInfo().achievementCacheData_.canReceiveCount + 1
                else
                    app.gameMgr:GetUserInfo().achievementCacheData_.unreceivedTaskList[taskId] = taskId
                end
            end
        end

    end

    app.badgeMgr:CheckTaskHomeRed()
end


function BadgeManager:refreshAchievementCacheData(args)
    app.gameMgr:GetUserInfo().achievementCacheData_.unreceivedTaskList = app.gameMgr:GetUserInfo().achievementCacheData_.unreceivedTaskList or {}
    local taskIds = checktable(args.taskNotDrawn)
    for i, taskId in pairs(taskIds) do
        -- 有效的taskId才添加红点
        if app.gameMgr:GetUserInfo().achievementCacheData_.unreceivedTaskList[tostring(taskId)] then
            app.gameMgr:GetUserInfo().achievementCacheData_.canReceiveCount = app.gameMgr:GetUserInfo().achievementCacheData_.canReceiveCount + 1
            app.gameMgr:GetUserInfo().achievementCacheData_.unreceivedTaskList[tostring(taskId)] = nil
        end
    end

    app.badgeMgr:CheckTaskHomeRed()
end


function BadgeManager:initUnionTaskCacheData(body)
    app.gameMgr:GetUserInfo().unionTaskCacheData_ = {
        canReceiveCount    = 0,     -- 能领取的个数
        unreceivedTaskList = {}     -- 未领取的任务列表(只有在这个列表的才是有效的taskId)
    }

    local personalContributionPoint = checkint(body.personalContributionPoint)
    local personalContributionPointRewards = body.personalContributionPointRewards or {}
    for i, v in ipairs(personalContributionPointRewards) do
        if checkint(v.hasDrawn) == 0 then
            if personalContributionPoint >= checkint(v.contributionPoint) then
                app.gameMgr:GetUserInfo().unionTaskCacheData_.canReceiveCount = app.gameMgr:GetUserInfo().unionTaskCacheData_.canReceiveCount + 1
            else
                local rewardId = tostring(v.rewardId)
                app.gameMgr:GetUserInfo().unionTaskCacheData_.unreceivedTaskList[rewardId] = rewardId
            end
        end
    end

    app.badgeMgr:CheckTaskHomeRed()
    self:CheckUnionRed()
end


function BadgeManager:refreshUnionTaskCacheData(args)
    local taskIds = checktable(args.taskId)
    for _, taskId in pairs(taskIds) do
        -- 有效的taskId才添加红点
        if app.gameMgr:GetUserInfo().unionTaskCacheData_.unreceivedTaskList[tostring(taskId)] then
            app.gameMgr:GetUserInfo().unionTaskCacheData_.canReceiveCount = app.gameMgr:GetUserInfo().unionTaskCacheData_.canReceiveCount + 1
            app.gameMgr:GetUserInfo().unionTaskCacheData_.unreceivedTaskList[tostring(taskId)] = nil
        end
    end

    app.badgeMgr:CheckTaskHomeRed()
    self:CheckUnionRed()
end

function BadgeManager:initGrowthFundCacheData(args)
    local userInfo = app.gameMgr:GetUserInfo()
    local growthFundCacheData_ = userInfo.growthFundCacheData_ or {}
    table.merge(growthFundCacheData_, args or {})

    local canReceiveCount = 0
    local level = checkint(userInfo.level)
    local payLevelRewards = growthFundCacheData_.payLevelRewards or {}
    local isOpen = 0
    for i, v in ipairs(payLevelRewards) do
        local target = checkint(v.target)
        if checkint(v.hasDrawn) <= 0 then
            if level >= target then
                canReceiveCount = canReceiveCount + 1
            end
            isOpen = isOpen + 1
        end
    end

    growthFundCacheData_.isOpen = isOpen
end

--- 判断升级是否添加红点
function BadgeManager:GetUpgradeRecipeLevelRed()
    local upgradeTable      = {}
    local recipeAllData     = CommonUtils.GetConfigAllMess('recipe', "cooking")
    local upgradeRecipeData = CommonUtils.GetConfigAllMess('grade', "cooking")
    local countLevel        = table.nums(upgradeRecipeData)
    local cookingStyles     = app.cookingMgr:GetStyleTable()
    local isUpgradelevel    = false
    local gameMgr = app.gameMgr
    local dataMgr = app.dataMgr
    --- 首先清除一次红点信息 防止上一次的缓存出错的问题
    dataMgr:ClearRedDotNofication(RemindTag.DISCOVER, RemindTag.DISCOVER, "[研究]BadgeManager:GetUpgradeRecipeLevelRed")
    if not gameMgr:GetUserInfo().recipeStylesRed[ALL_RECIPE_STYLE] then
        gameMgr:GetUserInfo().recipeStylesRed[ALL_RECIPE_STYLE] = {}
    end
    for k, v in pairs(cookingStyles) do
        if not gameMgr:GetUserInfo().recipeStylesRed[k] and checkint(v.initial) ~= 2 then
            -- 获取到玩家菜谱的种类  该表是用来是用来收集不同的菜系的信息
            gameMgr:GetUserInfo().recipeStylesRed[k] = {}
        end
    end
    for kk, vv in pairs(gameMgr:GetUserInfo().cookingStyles) do
        if kk ~= "" and kk ~= nil then
            if cookingStyles[tostring(kk)] and checkint(cookingStyles[tostring(kk)].initial) ~= 2 then
                for k, v in pairs(vv) do
                    local num = dataMgr:GetRedDotNofication(tostring(v.recipeId), tostring(v.recipeId) )
                    if num > 0 and checkint(v.growthTotal) == 0 then
                        if not isUpgradelevel then
                            dataMgr:AddRedDotNofication(RemindTag.DISCOVER, RemindTag.DISCOVER, "[研究] -BadgeManager:GetUpgradeRecipeLevelRed[v.growthTotal]", false)
                        end
                        gameMgr:GetUserInfo().recipeNewRed[tostring(v.recipeId)]                      = true
                        gameMgr:GetUserInfo().recipeStylesRed[kk][tostring(v.recipeId)]               = true
                        gameMgr:GetUserInfo().recipeStylesRed[ALL_RECIPE_STYLE][tostring(v.recipeId)] = true
                        dataMgr:AddRedDotNofication(tostring(v.recipeId), tostring(v.recipeId) , "[菜]-", false)
                        isUpgradelevel = true
                    else
                        local nowgrade = checkint(v.gradeId)
                        if nowgrade < countLevel then
                            local growthTotal     = checkint(v.growthTotal) -- 当前菜谱的成值
                            local needGrowthTotal = checkint(upgradeRecipeData[tostring(nowgrade + 1)].sum)
                            if needGrowthTotal <= growthTotal then
                                -- 判断当前的值是否大于等于要升级的值
                                dataMgr:AddRedDotNofication(tostring(v.recipeId), tostring(v.recipeId), "[菜]-nowgrade", false)
                                if not isUpgradelevel then
                                    dataMgr:AddRedDotNofication(RemindTag.DISCOVER, RemindTag.DISCOVER, "[研究]-needGrowthTotal", false)
                                end
                                upgradeTable[v.recipeId]                                                      = true
                                gameMgr:GetUserInfo().recipeStylesRed[kk][tostring(v.recipeId)]               = true
                                gameMgr:GetUserInfo().recipeStylesRed[ALL_RECIPE_STYLE][tostring(v.recipeId)] = true
                                isUpgradelevel                                                                = true
                            end

                        end
                    end
                end
            end

        end
    end
    dataMgr:SaveAllRedDotNoficationData()
    gameMgr:GetUserInfo().recipeUpgradeRed = upgradeTable
end


--- 清除不符合升级和新菜的菜谱
function BadgeManager:ClearUpgradeRecipeLevelAndNewRed(recipeId, styles)
    local recipeId = tostring(recipeId)
    if checkint(styles) == checkint(ALL_RECIPE_STYLE) then
        -- 如果是全部菜谱  需要找到菜谱所属的种类
        local recipeData    = CommonUtils.GetConfigAllMess('recipe', 'cooking')
        local recipeOneData = recipeData[tostring(recipeId)] or {}
        styles              = recipeOneData.cookingStyleId
        if not styles then
            return
        else
            styles = tostring(styles)
        end
    end
    styles                                                      = tostring(styles)
    app.gameMgr:GetUserInfo().cookingStyles[styles]             = app.gameMgr:GetUserInfo().cookingStyles[styles] or {}
    app.gameMgr:GetUserInfo().recipeStylesRed[styles]           = app.gameMgr:GetUserInfo().recipeStylesRed[styles] or {}
    app.gameMgr:GetUserInfo().recipeStylesRed[ALL_RECIPE_STYLE] = app.gameMgr:GetUserInfo().recipeStylesRed[ALL_RECIPE_STYLE] or {}
    local data                                                  = app.gameMgr:GetUserInfo().cookingStyles[styles][recipeId] or {}
    app.gameMgr:GetUserInfo().recipeNewRed[recipeId]            = nil
    app.gameMgr:GetUserInfo().recipeUpgradeRed[recipeId]        = nil
    app.dataMgr:ClearRedDotNofication(recipeId, recipeId, "[升级和新菜的菜谱]BadgeManager:ClearUpgradeRecipeLevelAndNewRed")
    --判断菜系是否存在
    app.gameMgr:GetUserInfo().recipeStylesRed[styles][recipeId]           = nil
    app.gameMgr:GetUserInfo().recipeStylesRed[ALL_RECIPE_STYLE][recipeId] = nil
end

--- 添加符合菜谱升级和新菜的红点
function BadgeManager:AddUpgradeRecipeLevelAndNewRed(recipeId, styles)
    local recipeId = tostring(recipeId)
    if checkint(styles) == checkint(ALL_RECIPE_STYLE) then
        -- 如果是全部菜谱  需要找到菜谱所属的种类
        local recipeData    = CommonUtils.GetConfigAllMess('recipe', 'cooking')
        local recipeOneData = recipeData[tostring(recipeId)] or {}
        styles              = recipeOneData.cookingStyleId
        if not styles then
            return
        else
            styles = tostring(styles)
        end
    end
    app.gameMgr:GetUserInfo().cookingStyles[styles] = app.gameMgr:GetUserInfo().cookingStyles[styles] or {}
    local data                                      = app.gameMgr:GetUserInfo().cookingStyles[styles][recipeId] or {}
    styles                                          = tostring(styles)
    if checkint(data.growthTotal) == 0 then
        app.gameMgr:GetUserInfo().recipeNewRed[recipeId]     = true
        app.gameMgr:GetUserInfo().recipeUpgradeRed[recipeId] = nil
        app.dataMgr:ClearRedDotNofication(recipeId, recipeId, "[合菜谱升级和新菜]BadgeManager:AddUpgradeRecipeLevelAndNewRed-data.growthTotal")
    else
        --可以升级的肯定不是最新的菜谱
        app.gameMgr:GetUserInfo().recipeNewRed[recipeId]     = nil
        app.gameMgr:GetUserInfo().recipeUpgradeRed[recipeId] = true
        app.dataMgr:ClearRedDotNofication(recipeId, recipeId, "[合菜谱升级和新菜]BadgeManager:AddUpgradeRecipeLevelAndNewRed[growthTotal不为0]")
    end
    app.gameMgr:GetUserInfo().recipeStylesRed[styles]                     = app.gameMgr:GetUserInfo().recipeStylesRed[styles] or {}
    app.gameMgr:GetUserInfo().recipeStylesRed[ALL_RECIPE_STYLE]           = app.gameMgr:GetUserInfo().recipeStylesRed[ALL_RECIPE_STYLE] or {}
    app.gameMgr:GetUserInfo().recipeStylesRed[styles][recipeId]           = true
    app.gameMgr:GetUserInfo().recipeStylesRed[ALL_RECIPE_STYLE][recipeId] = true
    app.dataMgr:AddRedDotNofication(recipeId, recipeId, "[合菜谱升级和新菜]BadgeManager:AddUpgradeRecipeLevelAndNewRed")
end


--- 检测红点升级和菜谱红点
function BadgeManager:CheckUpgradeRecipeUpgradeLevelAndNewRed()
    local count   = table.nums(app.gameMgr:GetUserInfo().recipeUpgradeRed)
    local coutNew = table.nums(app.gameMgr:GetUserInfo().recipeNewRed)
    if count > 0 or coutNew > 0 then
        return true
    else
        return false
    end
end


--- 是否清除研究的小红点
--- 研究的小红点有三个分别是
--- 1.可升级
--- 2.可制作
--- 3.研发已经完成
function BadgeManager:CheckClearResearchRecipeRed()
    local upgradered = self:CheckUpgradeRecipeUpgradeLevelAndNewRed()
    if upgradered then
        app.dataMgr:AddRedDotNofication(RemindTag.DISCOVER, RemindTag.DISCOVER, "[菜]BadgeManager:CheckClearResearchRecipeRed")
        AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, { countdown = 0, tag = RemindTag.DISCOVER })
        return
    end
    local leftsecondtims = app.cookingMgr:GetRecipeLeftSecodTime()
    if leftsecondtims > 0 then
        -- 大于零直接清除
        app.dataMgr:ClearRedDotNofication(RemindTag.DISCOVER, RemindTag.DISCOVER, "[研究的小红点]BadgeManager:CheckClearResearchRecipeRed,-时间大于0")
        app.dataMgr:ClearRedDotNofication( "RecipeReach", "time" )
    elseif leftsecondtims == 0 then
        app.dataMgr:AddRedDotNofication(RemindTag.DISCOVER, RemindTag.DISCOVER, "[研究的小红点]BadgeManager:CheckClearResearchRecipeRed,-时间等于0")
    elseif leftsecondtims < 0 then
        app.dataMgr:ClearRedDotNofication(RemindTag.DISCOVER, RemindTag.DISCOVER, "[研究的小红点]BadgeManager:CheckClearResearchRecipeRed,-时间小于0")
        app.dataMgr:ClearRedDotNofication( "RecipeReach", "time" , "[研究的小红点]BadgeManager:CheckClearResearchRecipeRed,计时器")
    end
    -- 最终都要刷新一下红点
    AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, { countdown = 0, tag = RemindTag.DISCOVER })
end


function BadgeManager:GetLevelChestTime()
    local levelChestData = app.activityMgr:GetLevelChestData() or {}
    local maxTime        = 0
    for k, v in pairs(levelChestData) do
        if app.gameMgr:GetUserInfo().level >= checkint( v.openLevel) and checkint(v.hasPurchased) == 0 then
            maxTime = checkint(v.discountLeftSeconds) > maxTime and checkint(v.discountLeftSeconds) or maxTime
        end
    end
    if table.nums( levelChestData) == 0 then
        app.gameMgr:GetUserInfo().tips.levelChest = app.gameMgr:GetUserInfo().tips.levelChest
        return
    end
    app.gameMgr:GetUserInfo().tips.levelChest = maxTime
end
--- 添加关于等级宝箱的定时器
function BadgeManager:AddChestLevelDataRed()
    -- 有的话先删除当前的定时器
    self:GetLevelChestTime()
    if not ( app.gameMgr:GetUserInfo().levelChest and checkint(app.gameMgr:GetUserInfo().tips.levelChest) > 0) then
        -- 首先判断倒计时是否开启
        if checkint(app.gameMgr:GetUserInfo().tips.levelChest) == 0 then
            app.timerMgr:RemoveTimer("LEVEL_CHEST")
            AppFacade.GetInstance():DispatchObservers(SGL.REFRES_LEVEL_CHEST_ICON, { countdown = 0, tag = RemindTag.LEVEL_CHEST })
        end
        return
    end
    if checkint(app.gameMgr:GetUserInfo().tips.levelChest) == 0 then
        app.timerMgr:RemoveTimer("LEVEL_CHEST")
        AppFacade.GetInstance():DispatchObservers(SGL.REFRES_LEVEL_CHEST_ICON, { countdown = 0, tag = RemindTag.LEVEL_CHEST })
        return
    end
    app.timerMgr:RemoveTimer("LEVEL_CHEST")
    local startTimes = os.time()

    local callfunc   = function( countdown, remindTag, timeNum, datas, timerName)
        local curTime        = os.time()
        local distanceTime   = curTime - startTimes
        local levelChestData = app.activityMgr:GetLevelChestData() or {}

        for k, v in pairs(levelChestData) do
            if checkint(v.openLevel) <= app.gameMgr:GetUserInfo().level then
                -- 等级尚未达到的时候不对宝箱进行任何操作
                if checkint(v.discountLeftSeconds) > 0 then
                    v.discountLeftSeconds = v.discountLeftSeconds - distanceTime
                    if v.discountLeftSeconds < 0 then
                        v.discountLeftSeconds = v.discountLeftSeconds > 0 and v.discountLeftSeconds or 0
                    end
                elseif checkint(v.discountLeftSeconds) ~= -1 then
                    v.discountLeftSeconds = 0
                end
            end
        end
        app.gameMgr:GetUserInfo().tips.levelChest = countdown
        startTimes                                = curTime
        AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = countdown, tag = remindTag, timeNum = timeNum, datas = datas, timerName = timerName})

        if countdown <= 0 then
            AppFacade.GetInstance():DispatchObservers(SGL.REFRES_LEVEL_CHEST_ICON, { countdown = 0, tag = RemindTag.LEVEL_CHEST })
        end
    end
    -- 添加定时器
    app.timerMgr:AddTimer({ tag = RemindTag.LEVEL_CHEST, callback = callfunc, name = "LEVEL_CHEST", countdown = app.gameMgr:GetUserInfo().tips.levelChest, isUnLosetime = false })
    AppFacade.GetInstance():DispatchObservers(SGL.REFRES_LEVEL_CHEST_ICON, { countdown = 0, tag = RemindTag.LEVEL_CHEST })
end

--- 添加菜谱倒计时
function BadgeManager:AddRecipeTimeInfoRed()
    local timecallback = function( countdown, remindTag, timeNum, datas)
        app.cookingMgr:SetRecipeLeftSecodTime(countdown)
        if countdown == 0 then
            app.timerMgr:RemoveTimer("RecipeReach") -- 直接删除定时器
            app.dataMgr:AddRedDotNofication(RemindTag.DISCOVER, RemindTag.DISCOVER, "[研究]BadgeManager:AddRecipeTimeInfoRed-菜谱倒计时")
            AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, { countdown = countdown, tag = RemindTag.DISCOVER })
            app.dataMgr:AddRedDotNofication( "RecipeReach", "time" )
        end
    end
    if app.cookingMgr:GetRecipeLeftSecodTime() then
        if app.cookingMgr:GetRecipeLeftSecodTime() > 0 then
            app.timerMgr:RemoveTimer("RecipeReach") -- 有的话直接删除
            app.timerMgr:AddTimer({ tag = RemindTag.DISCOVER, callback = timecallback, name = "RecipeReach", countdown = checkint(app.cookingMgr:GetRecipeLeftSecodTime()), isUnLosetime = false })
        elseif app.cookingMgr:GetRecipeLeftSecodTime() == 0 then
            app.timerMgr:RemoveTimer("RecipeReach")
            app.dataMgr:AddRedDotNofication(RemindTag.DISCOVER, RemindTag.DISCOVER, "[研究]BadgeManager:AddRecipeTimeInfoRed-GetRecipeLeftSecodTime-菜谱倒计时")
            AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, { countdown = 0, tag = RemindTag.DISCOVER })
        end
    end
end


--- 坐标点的Id  探索的时间
function BadgeManager:AddSetExploreTimeInfoRed(areaFixedPointId, time )
    if not time then
        return
    end
    local tag  = RemindTag.ORDER
    local time = checkint(time)
    --- 检测是否第一次打开数据
    if app.gameMgr:GetUserInfo().clock[JUMP_MODULE_DATA.EXPLORATIN] and checkint(app.gameMgr:GetUserInfo().clock[JUMP_MODULE_DATA.EXPLORATIN]) > -1 then
        app.timerMgr:ResumeTimer("ExploreFirst")
        app.gameMgr:GetUserInfo().clock[JUMP_MODULE_DATA.EXPLORATIN] = -1
    end
    local timecallback = function( countdown, remindTag, timeNum, datas)
        app.gameMgr:GetUserInfo().exploreAreasRedData[tostring(datas.areaFixedPointId)] = countdown
        if countdown == 0 then
            app.timerMgr:RemoveTimer("areaFixedPointId" .. areaFixedPointId)
            app.dataMgr:AddRedDotNofication(tag, tag)
            AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, { countdown = countdown, tag = RemindTag.ORDER })
            app.dataMgr:AddRedDotNofication( "areaFixedPointId", tostring(datas.areaFixedPointId ))
        end
    end
    if time > 0 then
        app.timerMgr:RemoveTimer("areaFixedPointId" .. areaFixedPointId)
        app.timerMgr:AddTimer({ tag = RemindTag.ORDER, callback = timecallback, name = "areaFixedPointId" .. areaFixedPointId, countdown = time, datas = { areaFixedPointId = areaFixedPointId } })
    elseif time == 0 then
        app.timerMgr:RemoveTimer("areaFixedPointId" .. areaFixedPointId)
        app.gameMgr:GetUserInfo().exploreAreasRedData[tostring(areaFixedPointId)] = 0
        app.dataMgr:AddRedDotNofication(tag, tag)
        app.dataMgr:AddRedDotNofication("areaFixedPointId", tostring(areaFixedPointId) )
        AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, { countdown = 0, tag = RemindTag.ORDER, datas = { areaFixedPointId = areaFixedPointId } })
    end
end


--- 退出该区域的时候清除探索点
function BadgeManager:ClearExploreAreaTimeAndRed(areaFixedPointId, type )
    if app.gameMgr:GetUserInfo().exploreAreasRedData[tostring(areaFixedPointId)] then
        app.dataMgr:ClearRedDotNofication("areaFixedPointId", areaFixedPointId , "[探索点]-BadgeManager:ClearExploreAreaTimeAndRed")
        app.timerMgr:RemoveTimer("areaFixedPointId" .. areaFixedPointId)
        app.gameMgr:GetUserInfo().exploreAreasRedData[tostring(areaFixedPointId)] = nil
    end
end


--- 检测是否有探索的点符合红点结构
function BadgeManager:CheckExploreRed()
    local isHave = false
    if  not (CommonUtils.CheckModuleIsExitByModuleId(JUMP_MODULE_DATA.EXPLORE_SYSTEM)
            and CommonUtils.GetModuleAvailable(MODULE_SWITCH.EXPLORE_SYSTEM))  then
        if CommonUtils.UnLockModule(RemindTag.QUEST_ARMY) then
            --首先判断关卡是否解锁
            if app.gameMgr:GetUserInfo().clock[JUMP_MODULE_DATA.EXPLORATIN] then
                if app.gameMgr:GetUserInfo().clock[JUMP_MODULE_DATA.EXPLORATIN] == 0 then
                    return true
                end
            end
            for k, v in pairs(app.gameMgr:GetUserInfo().exploreAreasRedData) do
                if v == 0 then
                    isHave = true
                    break
                end
            end
        end
    end
    return isHave
end


function BadgeManager:CheckOrderTimeAndRed()
    local isHave = false
    if CommonUtils.UnLockModule(RemindTag.CARVIEW) then
        ---@type TakeawayManager
        local takeawayInstance = app.takeawayMgr
        for k, v in pairs(takeawayInstance:GetDatas().diningCar or {}) do
            local orderData = takeawayInstance:GetOrderInfoByOrderInfo( { orderId = v.orderId, orderType = v.orderType }) or {}
            if orderData.leftSeconds and checkint(orderData.leftSeconds) == 0 and checkint(v.status) > 1 then
                isHave = true
                break
            end
        end
    end
    return isHave
end


--- 检测订单是否显示红点
function BadgeManager:CheckOrderRed()
    local exploreRed         = self:CheckExploreRed()
    local takeawayRed        = self:CheckOrderTimeAndRed()
    -- 增加了外卖车升级和外卖车解锁的优化
    local isUnLockAndUpgrade = self:JudageTakeAwayCarAddRed()
    local tag                = tostring(RemindTag.ORDER)
    if takeawayRed or exploreRed or isUnLockAndUpgrade then
        app.dataMgr:AddRedDotNofication( tag, tag, "[外卖订单][BadgeManager:CheckOrderRed]")
    else
        app.dataMgr:ClearRedDotNofication(tag, tag, "[外卖订单][BadgeManager:CheckOrderRed]")
    end
    AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, { countdown = 0, tag = RemindTag.ORDER })
end


--检查世界地图红点
function BadgeManager:CheckWorldMapRedPoint()
    local isHasRedPoint = false

    -- 是否有世界地图有解锁的点
    if self:CheckWorldMapAreaUnlocked() then
        isHasRedPoint = true
    end

    -- 是否有世界BOSS手册红点
    if self:CheckWorldManualRedPoint() then
        isHasRedPoint = true
    end

    -- 是否有新探索红点
    if  self:CheckEexploreSystemRedPoint() then
        isHasRedPoint = true
    end

    -- 是否有全区域主线剧情红点（全区域快速检查，只要有一个区域有，世界地图就亮）
    if self:CheckPlotRemind() then
        isHasRedPoint = true
    end

    -- 当前区域是否有主线剧情红点（当前区域快速检测，给主界面地图提示用）
    if self:CheckAreaPlotRemindAt(app.gameMgr:GetAreaId(), true) then
        isHasRedPoint = true
    end

    --居在有解锁的点时
    if isHasRedPoint then
        app.dataMgr:AddRedDotNofication(tostring(RemindTag.WORLDMAP), RemindTag.WORLDMAP, "[世界地图]-HomeMediator:CheckLayerRedPoint_")
    else
        app.dataMgr:ClearRedDotNofication(tostring(RemindTag.WORLDMAP), RemindTag.WORLDMAP, "[世界地图]-HomeMediator:CheckLayerRedPoint_")
    end
    AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.WORLDMAP})
end


-- 检查历练红点
function BadgeManager:CheckTrialsRedPoint()
    local isHasRedPoint = false

    if CommonUtils.UnLockModule(RemindTag.MODELSELECT) then
        -- 武道会
        if not isHasRedPoint then
            isHasRedPoint = self:CheckChampionshipRedPoint()
        end
    end

    --在有解锁的点时
    if isHasRedPoint then
        app.dataMgr:AddRedDotNofication(tostring(RemindTag.MODELSELECT), RemindTag.MODELSELECT, "[历练]-BadgeManager:CheckTrialsRedPoint")
    else
        app.dataMgr:ClearRedDotNofication(tostring(RemindTag.MODELSELECT), RemindTag.MODELSELECT, "[历练]-BadgeManager:CheckTrialsRedPoint")
    end
    AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.MODELSELECT})
end


-- 检测武道会红点
function BadgeManager:CheckChampionshipRedPoint()
    local isHasRedPoint = false

    if CommonUtils.UnLockModule(RemindTag.CHAMPIONSHIP) then
        -- 武道会是否开启(1是 0否)
        isHasRedPoint = app.gameMgr:GetUserInfo().tips.championship == 1
    end

    --在有解锁的点时
    if isHasRedPoint then
        app.dataMgr:AddRedDotNofication(tostring(RemindTag.CHAMPIONSHIP), RemindTag.CHAMPIONSHIP, "[武道会]-BadgeManager:CheckChampionshipRedPoint")
    else
        app.dataMgr:ClearRedDotNofication(tostring(RemindTag.CHAMPIONSHIP), RemindTag.CHAMPIONSHIP, "[武道会]-BadgeManager:CheckChampionshipRedPoint")
    end
    AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.CHAMPIONSHIP})

    return isHasRedPoint
end

-- 清除武道会红点
function BadgeManager:CleanChampionshipRedPoint()
    app.gameMgr:GetUserInfo().tips.championship = 0
    self:CheckChampionshipRedPoint()
end


--是否世界地图有解锁的点
function BadgeManager:CheckWorldMapAreaUnlocked()
    local areaDatas = CommonUtils.GetConfigAllMess('area', 'common')
    local isHasAreaUnlocked = false
    if areaDatas and table.nums(areaDatas) > 0 then
        local newestAreaId = checkint(app.gameMgr.userInfo.newestAreaId)
        for name,cityInfo in pairs(areaDatas) do
            if not CommonUtils.CheckLockCondition(cityInfo.unlockType) and checkint(cityInfo.id) > newestAreaId then
                --锁定的，调用解锁接口
                local tag = RemindTag["WORLD_AREA_" .. tostring(cityInfo.id)]
                app.dataMgr:AddRedDotNofication(tostring(tag) , tostring(tag))
                app:DispatchObservers(COUNT_DOWN_ACTION ,{countdown = 0 , tag = tag })
                isHasAreaUnlocked = true
                break
            end
        end
    end
    return isHasAreaUnlocked
end


--检查世界地图手册红点
function BadgeManager:CheckWorldManualRedPoint()
    local worldBossTestReward = checkint(app.gameMgr:GetWorldBossTestReward())
    local isHasRedPoint = worldBossTestReward > 0
    if isHasRedPoint then
        app.dataMgr:AddRedDotNofication(tostring(RemindTag.WORLD_BOSS_MANUAL), RemindTag.WORLD_BOSS_MANUAL, "[世界BOSS手册]-HomeMediator:CheckLayerRedPoint_")
    else
        app.dataMgr:ClearRedDotNofication(tostring(RemindTag.WORLD_BOSS_MANUAL), RemindTag.WORLD_BOSS_MANUAL, "[世界BOSS手册]-HomeMediator:CheckLayerRedPoint_")
    end
    AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.WORLD_BOSS_MANUAL})
    return isHasRedPoint
end


function BadgeManager:CheckEexploreSystemRedPoint()
    local exploreSystemRedPoint = checkint(app.gameMgr:GetExploreSystemRedPoint())
    local isHasRedPoint = exploreSystemRedPoint > 0
    if isHasRedPoint then
        app.dataMgr:AddRedDotNofication(tostring(RemindTag.EXPLORE_SYSTEM), RemindTag.EXPLORE_SYSTEM, "[探索系统]-HomeMediator:CheckLayerRedPoint_")
    else
        app.dataMgr:ClearRedDotNofication(tostring(RemindTag.EXPLORE_SYSTEM), RemindTag.EXPLORE_SYSTEM, "[探索系统]-HomeMediator:CheckLayerRedPoint_")
    end
    AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.EXPLORE_SYSTEM})
    return isHasRedPoint
end


--[[
--是否有卡牌能升星 显示红点
--]]
function BadgeManager:IsShowRedPointForCardBreak()
    local bool = false
    if app.gameMgr:GetUserInfo().cards then
        for i, v in pairs(app.gameMgr:GetUserInfo().cards) do
            --是否满足可升星条件
            local cardConf = CommonUtils.GetConfig('cards', 'card', v.cardId) or {}
            if checkint(v.breakLevel) + 1 < table.nums(cardConf.breakLevel or {}) then
                local goodsid = 0
                goodsid       = checkint(v.cardId) % 200000
                goodsid       = goodsid + 140000
                local quality = checkint(cardConf.qualityId)
                if checkint(app.gameMgr:GetAmountByGoodId(goodsid)) >= checkint(CommonUtils.GetConfig('cards', 'cardBreak', quality).breakConsume[v.breakLevel + 1]) and
                        app.gameMgr:GetUserInfo().gold >= checkint(CommonUtils.GetConfig('cards', 'cardBreak', quality).breakGoldConsume[v.breakLevel + 1]) then
                    bool = true
                    break
                end
            end
        end
    end
    return bool
end


--[[
--是否有新的队伍栏位解锁
--]]
function BadgeManager:IsShowRedPointForUnLockTeam()
    local bool       = false
    local teamNum    = table.nums(app.gameMgr:GetUserInfo().teamFormation) or 1
    local unlockData = {}
    if teamNum >= table.nums(CommonUtils.GetConfigAllMess('teamUnlock' ,'player') or {}) then
        return bool
    end

    local data = CommonUtils.GetConfig('player', 'teamUnlock', teamNum + 1)
    if data then
        for k, v in pairs(data.unlockType) do
            unlockData.unlockType = checkint(k)
            unlockData.unlockNums = checkint(v.targetNum)
        end
    end

    if next(unlockData) ~= nil then
        if unlockData.unlockType == 1 then
            if unlockData.unlockNums then
                if app.gameMgr:GetUserInfo().level >= unlockData.unlockNums then
                    bool = true
                end
            end
            -- elseif unlockData.unlockType == 3 then
            --     if unlockData.unlockNums then
            --         if app.gameMgr:GetUserInfo().diamond >= unlockData.unlockNums then
            --             bool = true
            --         end
            --     end
        end
    end

    return bool
end


--检测堕神净化倒计时 红点
function BadgeManager:CheckPetPurgeLeftSeconds()
    --堕神灵体净化倒计时的逻辑
    app.timerMgr:RemoveTimer( 'PET_ENTRY_RED_HERT' )
    if app.gameMgr:GetUserInfo().petPurgeLeftSeconds > 0 then
        local function timecallback( countdown, remindTag, timeNum, datas)
            if app.gameMgr:GetUserInfo().petPurgeLeftSeconds then
                app.gameMgr:GetUserInfo().petPurgeLeftSeconds = countdown
                if countdown == 0 then
                    app.dataMgr:AddRedDotNofication(tostring(RemindTag.PET),RemindTag.PET)
                    AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, { countdown = 0, tag = RemindTag.PET  })
                end
            end
        end
        app.timerMgr:AddTimer({name = 'PET_ENTRY_RED_HERT', countdown = checkint(app.gameMgr:GetUserInfo().petPurgeLeftSeconds), callback = timecallback} )
    else
        if app.gameMgr:GetUserInfo().showRedPointForPetPurge == true then--说明有灵体正在净化
            app.dataMgr:AddRedDotNofication(tostring(RemindTag.PET),RemindTag.PET)
            AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, { countdown = 0, tag = RemindTag.PET  })
        end
    end
end

--检测堕神净化倒计时 红点
function BadgeManager:UpdataPetPurgeLeftSeconds(data)
    --堕神灵体净化倒计时的逻辑
    app.timerMgr:RemoveTimer( 'PET_ENTRY_RED_HERT' )
    app.gameMgr:GetUserInfo().petPurgeLeftSeconds = checkint(data)
    app.dataMgr:ClearRedDotNofication(tostring(RemindTag.PET), RemindTag.PET)
    if app.gameMgr:GetUserInfo().petPurgeLeftSeconds > 0 then
        local function timecallback( countdown, remindTag, timeNum, datas)
            if app.gameMgr:GetUserInfo().petPurgeLeftSeconds then
                app.gameMgr:GetUserInfo().petPurgeLeftSeconds = countdown
                if countdown == 0 then
                    app.dataMgr:AddRedDotNofication(tostring(RemindTag.PET),RemindTag.PET, "[净化倒计时]-AppMediator:UpdataPetPurgeLeftSeconds")
                    AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, { countdown = 0, tag = RemindTag.PET  })
                end
            end
        end
        app.timerMgr:AddTimer({name = 'PET_ENTRY_RED_HERT', countdown = checkint(app.gameMgr:GetUserInfo().petPurgeLeftSeconds), callback = timecallback} )
    else
        app.dataMgr:AddRedDotNofication(tostring(RemindTag.PET),RemindTag.PET, "[堕神计时]-AppMediator:UpdataPetPurgeLeftSeconds直接显示")
        AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, { countdown = 0, tag = RemindTag.PET  })
    end
end

--[[
周年庆抽奖附加奖励红点
--]]
function BadgeManager:CheckAnniversaryExtraRewardTipRed()
    local anniversaryMgr = app.anniversaryMgr
    local homeData = anniversaryMgr:GetHomeData() or {}
    local mysteriousCircleNum = checkint(homeData.mysteriousCircleNum)
    local hasDrawn = checkint(homeData.supperRewardsHasDrawn) > 0
    local parserConfig = anniversaryMgr:GetConfigParse()
    local paramConfig = checktable(anniversaryMgr:GetConfigDataByName(parserConfig.TYPE.PARAMETER))["1"] or {}
    local superRewardTimes = checkint(paramConfig.superRewardTimes)
    local isRed = hasDrawn and 0 or (mysteriousCircleNum < superRewardTimes and 0 or 1)
    if isRed == 1  then
        app.dataMgr:AddRedDotNofication(tostring(RemindTag.ANNIVERSARY_EXTRA_REWARD_TIP) ,RemindTag.ANNIVERSARY_EXTRA_REWARD_TIP, "[周年庆]BadgeManager:CheckAnniversaryExtraRewardTipRed")
    else
        app.dataMgr:ClearRedDotNofication(tostring(RemindTag.ANNIVERSARY_EXTRA_REWARD_TIP) ,RemindTag.ANNIVERSARY_EXTRA_REWARD_TIP ,"[周年庆]BadgeManager:CheckAnniversaryExtraRewardTipRed")
    end
    AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, { countdown = 0  , tag  = RemindTag.ANNIVERSARY_EXTRA_REWARD_TIP  })
end

--[[
根据活动Id获取活动小红点状态
@params activityId int 活动id
--]]
function BadgeManager:GetActivityTipByActivitiyId( activityId )
    local activityHomeData = app.gameMgr:GetUserInfo().activityHomeData.activity
    for i,v in ipairs(activityHomeData) do
        if checkint(activityId) == checkint(v.activityId) then
            return checkint(v.tip)
        end
    end
    return 0
end
--[[
根据活动Id设置活动小红点状态
@params activityId int 活动id
status int 红点状态(0 or 1)
--]]
function BadgeManager:SetActivityTipByActivitiyId( activityId, status )
    local activityHomeData = app.gameMgr:GetUserInfo().activityHomeData.activity
    for i,v in ipairs(activityHomeData) do
        if checkint(activityId) == checkint(v.activityId) then
            v.tip = status
            break
        end
    end
end


function BadgeManager:checkActivityRedPoint(activityIds)
    activityIds    = activityIds or {}
    local userInfo = app.gameMgr:GetUserInfo()
    for activityId,v in pairs(userInfo.serverTask) do
		if activityIds[tostring(activityId)] == nil then
            userInfo.serverTask[tostring(activityId)] = nil
        end
	end
    for activityId,v in pairs(checktable(userInfo.accumulativePay)) do
        if activityIds[tostring(activityId)] == nil then
            userInfo.accumulativePay[tostring(activityId)] = nil
        end
    end
    for activityId,v in pairs(userInfo.cvShare) do
        if activityIds[tostring(activityId)] == nil then
            userInfo.cvShare[tostring(activityId)] = nil
        end
    end
    for activityId,v in pairs(userInfo.login) do
        if activityIds[tostring(activityId)] == nil then
            userInfo.login[tostring(activityId)] = nil
        end
    end
    for activityId, state in pairs(userInfo.binggoTask) do
		if activityIds[tostring(activityId)] == nil then
            userInfo.binggoTask[tostring(activityId)] = nil
        end
	end
end


function BadgeManager:checkSpActivityRedPoint()
    if self.DRAW_CARD_TYPE_DEFINE_ == nil then
        self.DRAW_CARD_TYPE_DEFINE_ = require('Game.mediator.drawCards.CapsuleNewMediator').DRAW_TYPE_DEFINE
    end
    if self.ACTIVITY_TYPE_DEFINE_ == nil then
        self.ACTIVITY_TYPE_DEFINE_ = require('Game.mediator.specialActivity.SpActivityMediator').ACTIVITY_TYPE_DEFINE
    end
    local hasSpActTip = false
    local spOpenTime  = app.gameMgr:GetUserInfo().activityHomeData.spActivityOpenTime
    if spOpenTime then
        for i, v in ipairs(app.gameMgr:GetUserInfo().activityHomeData.activity) do
            if not self.DRAW_CARD_TYPE_DEFINE_[v.type] then -- 剔除抽卡活动
                if self.ACTIVITY_TYPE_DEFINE_[tostring(v.type)] and checkint(v.tip) == 1 then -- 筛选特殊活动
                    if checkint(v.fromTime) > checkint(spOpenTime) then
                        hasSpActTip = true
                        break
                    end
                end
            end
        end
    end
	return hasSpActTip == true
end

function BadgeManager:AddCrBoxTimerByActivityId(activityId , countdown )
    local timerName = { "COUNT_DOWN_TAG_CHEST_ACTIVITY" , "TIPS" , activityId }
    local remindTag = checkint(activityId)
    local timerInfo = app.timerMgr:RetriveTimer(timerName)
    if timerInfo then
        app.timerMgr:RemoveTimer(timerName)
    end
    local callfunc = function( countdown, remindTag, timeNum, datas, timerName)
        local activityId = checkint(remindTag)
        local activitHomeData = app.gameMgr:GetUserInfo().activityHomeData.activity or {}
        for k , v in pairs(activitHomeData) do
            if checkint(v.activityId) == activityId then
                if countdown == 0  then
                    v.tip = 1
                else
                    v.tip = countdown
                end
            end
        end
    end
    app.timerMgr:AddTimer({ tag = remindTag, callback = callfunc, name = timerName, countdown = countdown})
end

function BadgeManager:RemoveCrBoxTimerByActivityId(activityId)
    local timerName = { "COUNT_DOWN_TAG_CHEST_ACTIVITY" , "TIPS" , activityId }
    app.timerMgr:RemoveTimer(timerName)
end


function BadgeManager:CheckCrBoxActivityRedPoint()
    local activitHomeData = app.gameMgr:GetUserInfo().activityHomeData.activity or {}
    local  activityType = checkint(ACTIVITY_TYPE.CHEST_ACTIVITY)
    local activityData = {}
    for k , v in pairs(activitHomeData) do
        if checkint(v.type) == activityType then
            activityData[#activityData+1] = v
        end
    end
    local isRedPoint =  0
    for i, v in pairs(activityData) do
        if checkint(v.tip) == 1 then
            isRedPoint = 1
            break
        end
    end
    return isRedPoint == 1
end

function BadgeManager:AddAllCrBoxTimer()
    local activitHomeData = app.gameMgr:GetUserInfo().activityHomeData.activity or {}
    local  activityType = ACTIVITY_TYPE.CHEST_ACTIVITY
    local activityData = {}
    for k , v in pairs(activitHomeData) do
        if checkint(v.type) == activityType then
            activityData[#activityData+1] = v
        end
    end
    for i, v in pairs(activityData) do
        if checkint(v.tip) > 1  then
            self:AddCrBoxTimerByActivityId(v.activityId , v.tip)
            break
        end
    end

end


--[[
清理所有任务的红点缓存数据
--]]
function BadgeManager:clearAllTaskRedPointCacheData()
    local userInfo = app.gameMgr:GetUserInfo()
    userInfo.dailyTaskCacheData_   = {}
    userInfo.achievementCacheData_ = {}
    userInfo.unionTaskCacheData_   = {}

    self:CheckUnionRed()
    self:CheckTaskHomeRed()
end

function BadgeManager:GetPlotRemindTag(questId)
    return 2400000 + checkint(questId)
end
function BadgeManager:GetZreaRemindTag(areaId)
    return 2300000 + checkint(areaId)
end

function BadgeManager:CheckAreaPlotRemindAt(checkAreaId, isQuickMode)
    local isHasRedPoint  = false
    local plotRemindData = app.gameMgr:GetUserInfo().plotRemindDatas[tostring(checkAreaId)] or {}
    local remindTag      = self:GetZreaRemindTag(checkAreaId)
    if next(plotRemindData) then 

        local isShowZreaTip = false
        for chapterId, storyIds in pairs(plotRemindData) do
            
            if next(storyIds) then
                for _, storyId in pairs(storyIds) do
                    if checkint(storyId) > 0 then
                        local tag = self:GetPlotRemindTag(storyId)
                        isHasRedPoint = true
                        isShowZreaTip = true
                        
                        app.dataMgr:AddRedDotNofication(tostring(tag), tag, "[主线剧情点]-HomeMediator:CheckLayerRedPoint_")
                        app:DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = tag})

                        if isQuickMode then
                            break
                        end
                    end
                end
            end

            if isQuickMode and isHasRedPoint then
                break
            end
        end

        if isShowZreaTip then
            app.dataMgr:AddRedDotNofication(tostring(remindTag), remindTag, "[主线剧情区域]-HomeMediator:CheckLayerRedPoint_")
        else
            app.dataMgr:ClearRedDotNofication(tostring(remindTag), remindTag, "[主线剧情区域]-HomeMediator:CheckLayerRedPoint_")    
        end
    end
    return isHasRedPoint
end

function BadgeManager:GetRelatedIsShowRemind( activityHomeData, data)
    if not data.relatedActivityId then return 0 end
    for i, v in ipairs(activityHomeData) do
        if checkint(v.activityId) == checkint(data.relatedActivityId) then
            return checkint(v.tip)
        end
    end
    return 0
end
function BadgeManager:CheckAreaPlotRemindAll(isQuickMode)
    local isHasRedPoint   = false
    local plotRemindDatas = app.gameMgr:GetUserInfo().plotRemindDatas
    for areaId, plotRemindData in pairs(plotRemindDatas) do
        local remindTag = self:GetZreaRemindTag(areaId)
        if next(plotRemindData) then
            isHasRedPoint = self:CheckAreaPlotRemindAt(areaId, true)
        else
            app.dataMgr:ClearRedDotNofication(tostring(remindTag), remindTag, "[主线剧情区域]-HomeMediator:CheckLayerRedPoint_")
        end
        app:DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = remindTag})

        if isQuickMode and isHasRedPoint then
            break
        end
    end
    return isHasRedPoint
end
function BadgeManager:CheckPlotRemind()
    return self:CheckAreaPlotRemindAll(true)
end

function BadgeManager:InitPlotRemindData()
    local dataMgr          = app.dataMgr
    local gameMgr          = app.gameMgr
    local userInfo         = gameMgr:GetUserInfo()
    local newestQuestId    = userInfo.newestQuestId
    local storyRewardConf  = CommonUtils.GetConfigAllMess("storyReward", "plot") or {}
    local questStory       = userInfo.questStory
    local plotRemindDatas  = {}
    local removedAreaIdIds = {}
    local isUnlockPlot     = CommonUtils.UnLockModule(RemindTag.PLOT_COLLECT)
    for key, value in pairs(storyRewardConf) do
        -- 初始化时先移除所有红点
        local areaId    = tostring(value.areaId)
        if not removedAreaIdIds[areaId] then
            removedAreaIdIds[areaId] = areaId
            local zoneTag   = self:GetZreaRemindTag(areaId)
            dataMgr:ClearRedDotNofication(tostring(zoneTag), zoneTag, "[主线剧情区域]-HomeMediator:CheckLayerRedPoint_")    
        end
        local remindTag = self:GetPlotRemindTag(value.id)
        dataMgr:ClearRedDotNofication(tostring(remindTag), remindTag, "[主线剧情区域]-HomeMediator:CheckLayerRedPoint_")

        if GAME_MODULE_OPEN.NEW_PLOT and isUnlockPlot and checkint(value.areaId) > 0 and checkint(value.unlock) < newestQuestId and not questStory[tostring(value.id)] then
            -- 清空缓存数据
            plotRemindDatas[areaId] = plotRemindDatas[areaId] or {}
            local chapterId         = tostring(value.chapterId)
            plotRemindDatas[areaId][chapterId] = plotRemindDatas[areaId][chapterId] or {}
            local storyId           = tostring(value.id)
            plotRemindDatas[areaId][chapterId][storyId] = storyId
        end
    end

    userInfo.plotRemindDatas = plotRemindDatas
    -- self:CheckPlotRemind()  -- 等着主界面调用就好了，这里不调用了
end

function BadgeManager:RemovePlotRemindData(data)
    local areaId    = tostring(data.areaId)
    local chapterId = tostring(data.chapterId)
    local storyId   = tostring(data.storyId)
    local plotRemindDatas = app.gameMgr:GetUserInfo().plotRemindDatas
    if plotRemindDatas[areaId] and plotRemindDatas[areaId][chapterId] and plotRemindDatas[areaId][chapterId][storyId] then
        -- 移除红点的地方 是用0 判断
        plotRemindDatas[areaId][chapterId][storyId] = nil
        local tag = self:GetPlotRemindTag(data.storyId)
        app.dataMgr:ClearRedDotNofication(tostring(tag), tag, "[主线剧情点]-MapMediator:ProcessSignal")
        app:DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = tag})
    end

end
----=======================----
--@author : xingweihao
--@date : 2020/4/9 5:19 PM
--@Description 检测酒吧熟客值奖励的是否可以领取
--@params
--@return
---=======================----
function BadgeManager:CheckHasFrequencyPointRewards()
    local customerFrequencyPointConf = CONF.BAR.CUSTOMER_FREQUENCY_POINT:GetAll()
    local customers = app.waterBarMgr:getAllCustomers()
    local isReward = false
    for index , coustomerData in pairs(customers) do
        local customerId = coustomerData.customerId
        local frequencyPoint = checkint(coustomerData.frequencyPoint)
        local count = 0
        for rewardPoint ,rewardData  in pairs(customerFrequencyPointConf[tostring(customerId)]) do
            if checkint(rewardPoint) <= frequencyPoint then
                count = count + 1
            end
        end
        if table.nums(coustomerData.frequencyPointRewards) < count then
            isReward = true
            break
        end
    end
    if  isReward then
        app.dataMgr:AddRedDotNofication(tostring(RemindTag.WARTER_BAR_FRE_POINT_REWARD) ,RemindTag.WARTER_BAR_FRE_POINT_REWARD, "[酒吧回头客奖励]")
    else
        app.dataMgr:ClearRedDotNofication(tostring(RemindTag.WARTER_BAR_FRE_POINT_REWARD) ,RemindTag.WARTER_BAR_FRE_POINT_REWARD, "[酒吧回头客奖励]")
    end
    AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, { countdown = 0  , tag  = RemindTag.WARTER_BAR_FRE_POINT_REWARD  })
end

----=======================----
--@Description 检测飨灵皮肤的红点数据
--@params
--@return
---=======================----

--[[
--检测飨灵收集红点数据并刷新红点状态
--]]
function BadgeManager:CheckCardCollRedPoint()
    if GAME_MODULE_OPEN.CARD_ALBUM then
        self:initCardCollTaskRedData_()
    end
    self:updateCardCollTaskRedPointStatue()
end

--[[   
--更新飨灵收集红点状态
--]]
function BadgeManager:updateCardCollTaskRedPointStatue()
    if self:getCardCollTaskRedData_() then
        app.dataMgr:AddRedDotNofication(tostring(RemindTag.CARD_ALBUM), RemindTag.CARD_ALBUM, "[图鉴 飨灵收集]-HomeMediator:CheckLayerRedPoint_")
    else
        app.dataMgr:ClearRedDotNofication(tostring(RemindTag.CARD_ALBUM), RemindTag.CARD_ALBUM, "[图鉴 飨灵收集]-HomeMediator:CheckLayerRedPoint_")
    end
    AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.CARD_ALBUM})
end

--[[
--更新飨灵收集组别红点状态
--]]
function BadgeManager:GetCardCollTaskGroupRemindTag(groupId)
    return 1300 + checkint(groupId)
end
function BadgeManager:updateCardCollTaskGroupRedPointStatue(groupId)
    local cardCollTaskGroupTag = self:GetCardCollTaskGroupRemindTag(groupId)

    if self:getCardCollTaskRedDataByGroupAndTaskType_(groupId, CardUtils.CARD_COLL_TASK_TYPE_ROOT) then
        app.dataMgr:AddRedDotNofication(tostring(cardCollTaskGroupTag), cardCollTaskGroupTag, "[飨灵收集任务]-HomeMediator:CheckLayerRedPoint_")
    else
        app.dataMgr:ClearRedDotNofication(tostring(cardCollTaskGroupTag), cardCollTaskGroupTag, "[飨灵收集任务]-HomeMediator:CheckLayerRedPoint_")
    end
    AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = cardCollTaskGroupTag})
end

--------------------------------------------private method
--[[
--通过任务类型获取飨灵收集任务
--]]
function BadgeManager:getTaskConfByTaskType_(taskType)
    return checktable(self.cardCollTaskConfMap_[taskType])
end

--[[
--根据飨灵id拿到飨灵收集任务的组别信息
--]]
function BadgeManager:getCardCollTaskGroupIdsByCardId_(cardId)
    return checktable(self.cardCollTaskGroupMap_[checkint(cardId)])
end

--[[
--更新飨灵收集任务红点数据 
-- addNum > 0 计入进度增加值，刷新红点
-- addNum = 0 刷新红点
-- addNum == nil 重新计算进度增加值，刷新红点
--]]
function BadgeManager:updateCardCollTaskRedData_(groupId, taskType, addNum)
    -- 进度数据改动时， 更新进度数据
    if addNum ~= nil then
        if checkint(addNum) > 0 then
            -- 根据指定类型，检测增量
            self:setCardCollTaskProgressByGroupAndTaskType_(groupId, taskType, checkint(addNum))
        else
            -- 根据指定类型，检测全数据
            self:setCardCollTaskRedDataByGroupAndTaskType_(groupId, taskType)
        end
    else
        -- 根据指定类型，生成全数据
        self:setCardCollTaskProgressByGroupAndTaskType_(groupId, taskType)
    end
    
    -- 进行指定组别的刷新检测
    self:setCardCollTaskRedDataByGroup_(groupId)
    -- 进行根节点的刷新检测
    self:setCardCollTaskRedData_()
end

--[[
--初始化飨灵收集任务红点数据
--]]
function BadgeManager:initCardCollTaskRedData_()
    for _, cardCollTaskGroupConf in pairs(CONF.CARD.CARD_COLL_BOOK:GetAll()) do
        for _, taskType in pairs(CardUtils.CARD_COLL_TASK_TYPE) do
            self:setCardCollTaskProgressByGroupAndTaskType_(checkint(cardCollTaskGroupConf.id), checkint(taskType))
        end
        self:setCardCollTaskRedDataByGroup_(checkint(cardCollTaskGroupConf.id))
    end
    self:setCardCollTaskRedData_()
end

--[[
--根据飨灵收集任务的组别和任务类型  得到/获取 红点数据
--]]
function BadgeManager:checkCardCollTaskRedDataByGroupAndTaskType_(groupId, taskType)
    local taskConfs  = self:getTaskConfByTaskType_(taskType)
    local currentNum = self:getCardCollTaskProgressByGroupAndTaskType_(groupId, taskType)
    local isCouldGet = false
    
    for _, taskConf in ipairs(taskConfs) do
        if checkint(taskConf.targetNum) <= currentNum and (not app.gameMgr:GetUserInfo().cardCollectionBookMap[groupId] or not app.gameMgr:GetUserInfo().cardCollectionBookMap[groupId][checkint(taskConf.id)]) then --判断是否已经领取过
            isCouldGet = true
            break
        end
    end
    self:setCardCollTaskRedDataByGroupAndTaskType_(groupId, taskType, isCouldGet)
end

function BadgeManager:setCardCollTaskRedDataByGroupAndTaskType_(groupId, taskType, isHasRed)
    if isHasRed == nil then
        -- 获取红点数据
        self:checkCardCollTaskRedDataByGroupAndTaskType_(groupId, taskType)
    else
        if not self.cardCollTaskRedMap_[groupId] then
            self.cardCollTaskRedMap_[groupId] = {}
        end
        -- 设置红点数据
        self.cardCollTaskRedMap_[groupId][taskType] = isHasRed
    end
end

function BadgeManager:getCardCollTaskRedDataByGroupAndTaskType_(groupId, taskType)
    local groupRedData = checktable(self.cardCollTaskRedMap_[groupId])
    return checkbool(groupRedData[taskType])
end

--[[
--根据飨灵收集任务的组别  得到/获取 红点数据
--]]
function BadgeManager:setCardCollTaskRedDataByGroup_(groupId, isHasGroupRed)
    if not self.cardCollTaskRedMap_[groupId] then
        self.cardCollTaskRedMap_[groupId] = {}
    end
    if isHasGroupRed == nil then
        isHasGroupRed = false

        for taskType, isHasRed in pairs(self.cardCollTaskRedMap_[groupId] or {}) do
            if isHasRed == true and checkint(taskType) ~= CardUtils.CARD_COLL_TASK_TYPE_ROOT then
                isHasGroupRed = true
                break
            end
        end
    end
    self.cardCollTaskRedMap_[groupId][CardUtils.CARD_COLL_TASK_TYPE_ROOT] = isHasGroupRed

    self:updateCardCollTaskGroupRedPointStatue(groupId)
end

function BadgeManager:getCardCollTaskRedDataByGroup(groupId)
    return checktable(self.cardCollTaskRedMap_[groupId])
end

--[[
--飨灵收集任务  得到/获取 红点数据
--]]
function BadgeManager:setCardCollTaskRedData_(isHasCardTaskCollRed)
    if isHasCardTaskCollRed ~= nil then
        self.cardCollTaskRedMap_[CardUtils.CARD_COLL_TASK_GROUP_ROOT] = isHasCardTaskCollRed
    else
        self.cardCollTaskRedMap_[CardUtils.CARD_COLL_TASK_GROUP_ROOT] = false
        for groupId, groupRedData in pairs(self.cardCollTaskRedMap_) do
            if checkint(groupId) ~= CardUtils.CARD_COLL_TASK_GROUP_ROOT and groupRedData[CardUtils.CARD_COLL_TASK_TYPE_ROOT] == true then
                self.cardCollTaskRedMap_[CardUtils.CARD_COLL_TASK_GROUP_ROOT] = true
                break
            end
        end
    end
    self:updateCardCollTaskRedPointStatue()
end

function BadgeManager:getCardCollTaskRedData_()
    return checkbool(self.cardCollTaskRedMap_[CardUtils.CARD_COLL_TASK_GROUP_ROOT])
end

--[[
--根据飨灵收集任务的组别和任务类型  得到/获取 当前进度
--]]
function BadgeManager:checkCardCollTaskProgressByGroupAndTaskType_(groupId, taskType)
    local cardGroupConf = CONF.CARD.CARD_COLL_BOOK:GetValue(groupId)
    if not cardGroupConf.cardIds then
        return
    end
    local currentNum = app.cardMgr.CalculateCardAlbumTaskProgress(taskType, cardGroupConf.cardIds)
    self:setCardCollTaskProgressByGroupAndTaskType_(groupId, taskType, currentNum)
end

function BadgeManager:setCardCollTaskProgressByGroupAndTaskType_(groupId, taskType, addNum)
    if not self.cardCollTaskDataMap_[groupId] then
        self.cardCollTaskDataMap_[groupId] = {}
    end

    -- 设置数据
    if not addNum then
        -- 清空数据
        self.cardCollTaskDataMap_[groupId][taskType] = 0
        -- 获取进度值
        self:checkCardCollTaskProgressByGroupAndTaskType_(groupId, taskType)
    else
        -- 设置进度
        self.cardCollTaskDataMap_[groupId][taskType] = checkint(self.cardCollTaskDataMap_[groupId][taskType]) + addNum

        -- 判断是否刷新红点数据    
        -- 如果该组别中该任务类型本身就有红点，进度值增加的情况下不刷新红点数据
        if addNum > 0 and not self:getCardCollTaskRedDataByGroupAndTaskType_(groupId, taskType) then
            self:setCardCollTaskRedDataByGroupAndTaskType_(groupId, taskType)
        end
    end    
end

function BadgeManager:getCardCollTaskProgressByGroupAndTaskType_(groupId, taskType)
    local groupData = checktable(self.cardCollTaskDataMap_[groupId])
    return checkint(groupData[taskType])
end

--[[
--外观收集任务 红点刷新
--]]
function BadgeManager:updateSkinCollTaskRedStatueHandler_()
    local hasRedPoint = false
    for groupId, taskId in pairs(app.cardMgr:getOnGoingCardCollTaskMap()) do
        local taskConf = CONF.CARD.SKIN_COLL_TASK:GetValue(taskId)
        local currentNum = app.cardMgr:getCardSkinCollNumByType(checkint(taskConf.targetId))

        if currentNum >= checkint(taskConf.targetNum) then
            hasRedPoint = true
            break
        end
    end

    if hasRedPoint then
        app.dataMgr:AddRedDotNofication(tostring(RemindTag.SKIN_COLL_TASK), RemindTag.SKIN_COLL_TASK, "[外观收集任务]-红点刷新")
    else
        app.dataMgr:ClearRedDotNofication(tostring(RemindTag.SKIN_COLL_TASK), RemindTag.SKIN_COLL_TASK, "[外观收集任务]-红点刷新")
    end
    AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.SKIN_COLL_TASK})
end
--[[
--外观收集 红点数据
--]]
function BadgeManager:updateNewCardSkinRedStatueHandler_(signal)
    local data = signal:GetBody()
    local skinId = data.skinId
    local statue = data.statue

    self.cardSkinStatueMap_[checkint(skinId)] = checkbool(statue)
end

function BadgeManager:checkCardSkinIsNew(skinId)
    return checkbool(self.cardSkinStatueMap_[checkint(skinId)])
end

return BadgeManager
