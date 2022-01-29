--[[
 * author : liuzhipeng
 * descpt : 杀人案（2019夏活） 管理器
]]
---@type ChangeSkinManager
local ChangeSkinManager = require("Frame.Manager.ChangeSkinManager")
---@class MurderManager :ChangeSkinManager
local MurderManager = class('MurderManager', ChangeSkinManager)
-- 换皮的配置数据
MurderManager.CHANGE_SKIN_CONF = {
    SKIN_MODE = GAME_MOUDLE_EXCHANGE_SKIN.MURDER, -- 换皮的模式
    SKIN_PATH = "murder" , -- 换皮的路径
}
-------------------------------------------------
-- manager method

MurderManager.DEFAULT_NAME = 'MurderManager'
MurderManager.instances_   = {}

local MURDER_BOSS_COUNTDOWN = 'MURDER_BOSS_COUNTDOWN'

MURDER_MOUDLE_TYPE = {
    QUEST   = '1', -- 材料副本
    BOSS    = '2', -- BOSS
    BUFF    = '3', -- 掉落加成
    STORE   = '4', -- 商店
    CAPSULE = '5', -- 扭蛋机
    CLUE    = '6', -- 线索
}
MURDER_CLOCK_STATE = {
    UPGRADE = 1,  -- 升级
    BOSS    = 2,  -- BOSS
    REWARD  = 3,  -- 奖励
    FINAL   = 4,  -- 最终剧情

}
function MurderManager.GetInstance(instancesKey)
    instancesKey = instancesKey or MurderManager.DEFAULT_NAME

    if not MurderManager.instances_[instancesKey] then
        MurderManager.instances_[instancesKey] = MurderManager.new(instancesKey)
    end
    return MurderManager.instances_[instancesKey]
end


function MurderManager.Destroy(instancesKey)
    instancesKey = instancesKey or MurderManager.DEFAULT_NAME

    if MurderManager.instances_[instancesKey] then
        MurderManager.instances_[instancesKey]:release()
        MurderManager.instances_[instancesKey] = nil
    end
end


-------------------------------------------------
-- life cycle

function MurderManager:ctor(instancesKey)
    self.super.ctor(self)

    if MurderManager.instances_[instancesKey] then
        funLog(Logger.INFO, "注册相关的facade类型")
    else
        self:initial()
    end
end


function MurderManager:initial()
    self.homeData = {} -- 活动home数据
    self.debugMode = false -- debug模式
    self.selectedDifficulty = 1 -- 选中的boss难度
end


function MurderManager:release()
end


-------------------------------------------------
-- public method
--[[
更新homeData
--]]
function MurderManager:UpdateHomeData()
    local homeMediator = AppFacade.GetInstance():RetrieveMediator("MurderHomeMediator")
    if homeMediator then
        homeMediator:UpdateHomeData()
    end
end
--[[
停止boss倒计时
--]]
function MurderManager:StopBossCountdown()
    if app.timerMgr:RetriveTimer(MURDER_BOSS_COUNTDOWN) then
        app.timerMgr:RemoveTimer(MURDER_BOSS_COUNTDOWN)
    end
end
--[[
开始boss倒计时
--]]
function MurderManager:StartBOSSCountdown()
    local homeData = self:GetHomeData()
    self:StopBossCountdown()
    if checkint(homeData.leftSeconds) == 0 then return end
    local callback = function(countdown, remindTag, timeNum, datas, timerName)
        homeData.leftSeconds = countdown
        AppFacade.GetInstance():DispatchObservers(MURDER_BOSS_COUNTDOWN_UPDATE, {countdown = countdown})
        if countdown <= 0 then
            self:UpdateHomeData()
        end
    end
    app.timerMgr:AddTimer({name = MURDER_BOSS_COUNTDOWN, callback = callback, countdown = homeData.leftSeconds})
end
--[[
显示奖品刷新提示
--]]
function MurderManager:ShowMirrorRefreshTips()
    local murderMirrorRefreshTipsView = require('Game.views.activity.murder.MurderMirrorRefreshTipsView').new()
    murderMirrorRefreshTipsView:setPosition(display.center)
    app.uiMgr:GetCurrentScene():AddDialog(murderMirrorRefreshTipsView)
end
--[[
转换商城数据
--]]
function MurderManager:ConvertStoreData()
    local config = CommonUtils.GetConfigAllMess('shop', 'newSummerActivity')
    local homeData = self:GetHomeData()
    local mallBuy = checktable(homeData.mallBuy)
    local storeData = {}
    for k, v in orderedPairs(config) do
        local temp = {}
        temp.id       = v.id
        temp.currency = v.consume[1].goodsId
        temp.price    = v.consume[1].num
        temp.goodsId  = v.rewards[1].goodsId
        temp.goodsNum = v.rewards[1].num
        temp.leftPurchasedNum = checkint(v.exchangeLimit)
        temp.stock    = checkint(v.exchangeLimit)
        if mallBuy[tostring(v.id)] then
            temp.leftPurchasedNum = temp.leftPurchasedNum - checkint(mallBuy[tostring(v.id)])
            temp.stock = temp.stock - checkint(mallBuy[tostring(v.id)])
        end
        table.insert(storeData, temp)
    end
    return storeData
end
--[[
商店购买
@params shopId int 商品id
@params num    int 购买数量
--]]
function MurderManager:StoreBuyItems( shopId, num )
    local homeData = self:GetHomeData()
    homeData.mallBuy[tostring(shopId)] = checkint(homeData.mallBuy[tostring(shopId)]) + checkint(num)
end
--[[
boss奖励是否领取
--]]
function MurderManager:IsBossRewardsDraw( bossId )
    local homeData = self:GetHomeData()
    local isDraw = false
    for i, v in ipairs(checktable(homeData.bossScheduleRewards)) do
        if checkint(v) == checkint(bossId) then
            isDraw = true
            break
        end
    end
    return isDraw
end
--[[
boss奖励是否可领取
@params bossId int boss排期id
--]]
function MurderManager:IsBossRewardsCanDraw( bossId )
    if self:IsBossRewardsDraw(bossId) then return false end
    local homeData = self:GetHomeData()
    local fullServerPoint = homeData.fullServerPoint or {}
    local bossConfig = CommonUtils.GetConfig('newSummerActivity', 'bossSchedule', bossId) or {}
    return checkint(fullServerPoint[tostring(bossId)]) >= checkint(bossConfig.bossMaxHp)
end
--[[
boss奖励领取,更新本地数据
@params bossId int bossId
--]]
function MurderManager:DrawBossRewards( bossId )
    local homeData = self:GetHomeData()
    table.insert(homeData.bossScheduleRewards, checkint(bossId))
end
--[[
材料本是否可以扫荡
--]]
function MurderManager:IsMaterialQuestCanSkip( questId )
    local homeData = self:GetHomeData()
    local canSkip = false
    for i,v in ipairs(checktable(homeData.passQuests)) do
        if checkint(questId) == checkint(v) then
            canSkip = true 
            break
        end
    end
    return canSkip
end
--[[
线索奖励领取,更新本地数据
@params clueId int 线索id
--]]
function MurderManager:DrawClueRewards( clueId )
    local homeData = self:GetHomeData()
    table.insert(homeData.hasDrawnPuzzleRewards, checkint(clueId))
end
--[[
插入剧情
@params table {
	storyId int 剧情id
    callback function 剧情结束后回调
    backHomeMediator bool 是否回到活动主界面
}
--]]
function MurderManager:ShowActivityStory(params)
    -- 判断是否跳过剧情
    local actStoryKey = string.format('IS_MURDER_ACTIVITY_STORY_SHOWED_%s_%s_%s', tostring(self:GetActivityId()), tostring(app.gameMgr:GetUserInfo().playerId), tostring(params.storyId))
    local isSkipStory = cc.UserDefault:getInstance():getBoolForKey(actStoryKey, false)
    if isSkipStory then
        if params.callback then
            params.callback()
        end
    else
        local storyPath  = string.format('conf/%s/newSummerActivity/story.json', i18n.getLang())
        local storyStage = require('Frame.Opera.OperaStage').new({id = checkint(params.storyId), path = storyPath, guide = true, cb = function(sender)
            cc.UserDefault:getInstance():setBoolForKey(actStoryKey, true)
            if params.callback then
                params.callback()
            end
            if params.backHomeMediator then
                app:RetrieveMediator('Router'):Dispatch({name = 'homeMediator'}, {name = 'activity.murder.MurderHomeMediator'}, {isBack = true})
            end
        end})
        storyStage:setPosition(display.center)
        sceneWorld:addChild(storyStage, GameSceneTag.Dialog_GameSceneTag)
    end
end
--[[
剧情是否解锁
@params int storyId 剧情id
--]]
function MurderManager:IsStoryUnlock( storyId )
    local actStoryKey = string.format('IS_MURDER_ACTIVITY_STORY_SHOWED_%s_%s_%s', tostring(self:GetActivityId()), tostring(app.gameMgr:GetUserInfo().playerId), tostring(storyId))
    return cc.UserDefault:getInstance():getBoolForKey(actStoryKey, false)
end
--[[
解锁剧情
@params storyId int 剧情id
--]]
function MurderManager:UnlockStory( storyId )
    local homeData = self:GetHomeData()
    -- 去重
    homeData.unlockStoryInfo = homeData.unlockStoryInfo or {}
    for i, v in ipairs(homeData.unlockStoryInfo) do
        if checkint(v) == storyId then
            return 
        end
    end
    table.insert(homeData.unlockStoryInfo, checkint(storyId))
end
--[[
开启debug模式
取消飨灵伤害加成
--]]
function MurderManager:OpenDebugMode()
    self.debugMode = true
end
--[[
关闭debug模式
开启飨灵伤害加成
--]]
function MurderManager:CloseDebugMode()
    self.debugMode = false
end
-------------------------------------------------
-- get/set
--[[
设置活动homeData
@params homeData table 活动home数据
--]]
function MurderManager:SetHomeData( homeData )
    -- dump(homeData)
    self.homeData = checktable(homeData)
    -- 初始化活动体力
	self:InitActivityHp()
end
--[[
获取活动homeData
--]]
function MurderManager:GetHomeData( )
    return self.homeData or {}
end

function MurderManager:isClosed()
    return checkint(self:GetHomeData().isEnd) == 1
end

--[[
获取当前阶段最大时钟等级
--]]
function MurderManager:GetMaxClockLevel()
    return checkint(self.homeData.maxClockLevel)
end
--[[
获取当前时钟等级
--]]
function MurderManager:GetClockLevel()
    return checkint(self.homeData.clockLevel)
end
--[[
设置当前时钟等级
@params newClockLevel int 新的时钟等级
--]]
function MurderManager:SetClockLevel( newClockLevel )
    self.homeData.clockLevel = checkint(newClockLevel)
end
--[[
获取商城数据
--]]
function MurderManager:GetStoreData()  
    local storeData = self:ConvertStoreData()
    return storeData 
end
--[[
获取商店货币道具
--]]
function MurderManager:GetStoreCurrency()
    local config = CommonUtils.GetConfig('newSummerActivity', 'building', 1)
    local consume = config.consume
    local currencyMap = {}
    for i, v in ipairs(consume) do
        currencyMap[tostring(v.goodsId)] = v.goodsId
    end
    return currencyMap
end
--[[
获取抽奖道具
--]]
function MurderManager:GetLotteryGoodsId()
    return checkint(self:GetHomeData().lotteryGoodsId)
end
--[[
获取探索点数道具id
--]]
function MurderManager:GetPointGoodsId()
    local goodsId = 880178
    if self.skinMode then
        local changeSkinData = app.murderMgr:GetChangeSkinData()
        local murderGoods   = changeSkinData.murderGoods
        goodsId = murderGoods.point_goods_id
    end
    return goodsId
end
--[[
获取探索点数数量
--]]
function MurderManager:GetPointNum()
    local homeData = self:GetHomeData()
    return checkint(homeData.bossTotalDamage)
end
--[[
获取已经解锁的boss排期id
--]]
function MurderManager:GetUnlockBossId()
    local config = self:GetUnlockModuleByType(MURDER_MOUDLE_TYPE.BOSS)
    if config then
        return checkint(config.subType)
    else
        return 0
    end
end
--[[
获取当前已解锁的最新模块
--]]
function MurderManager:GetUnlockModuleByType( moudleType )
    local clockLevel = self:GetClockLevel()
    local moduleConfig = CommonUtils.GetConfigAllMess('moduleUnlock', 'newSummerActivity')
    local grade = 0
    local config = nil
    for i, v in pairs(moduleConfig) do
        if checkint(v.grade) <= clockLevel and tostring(v.type) == tostring(moudleType) then
            if checkint(v.subType) > grade then
                config = v
                grade = checkint(v.subType)
            end
        end
    end
    return config
end
--[[
获取当前进行的boss排期id
--]]
function MurderManager:GetCurrentBossId() 
    return checkint(self:GetHomeData().currentBossScheduleId)
end
--[[
获取当前生效的boss排期id
--]]
function MurderManager:GetEffectBossId()
    local effectBossScheduleId = checkint(self:GetHomeData().effectBossScheduleId)
    if effectBossScheduleId == 0 then
        effectBossScheduleId = 1
    end
    return effectBossScheduleId
end
--[[
设置抽奖数据
--]]
function MurderManager:SetLotteryData( lotteryData )
    self.lotteryData = checktable(lotteryData)
end
--[[
获取抽奖数据
--]]
function MurderManager:GetLotteryData()
    return self.lotteryData
end
--[[
获取材料本加成角色
--]]
function MurderManager:GetMaterialQuestAdditionCardsByQuestId( questId )
    local dropAdditionData = self:GetDropAdditionDataByQuestId(questId)
    return dropAdditionData.cardsId or {}
end
--[[
通过材料本关卡id获取掉落加成数据
--]]
function MurderManager:GetDropAdditionDataByQuestId( questId )
    local materialConfig = CommonUtils.GetConfigAllMess('materialSchedule', 'newSummerActivity')
    local materialId = nil
    for _, v in ipairs(materialConfig) do
        for i, value in ipairs(v.pointId) do
            if checkint(questId) == checkint(value) then
                materialId = checkint(i)
                break
            end
        end
    end
    local dropAdditionData = CommonUtils.GetConfig('newSummerActivity', 'dropAddition', 4 - checkint(materialId))
    return checktable(dropAdditionData)
end
--[[
获取boss战加成角色
--]]
function MurderManager:GetBossQuestAdditionCards()
    if self.debugMode then return {} end
    local config = CommonUtils.GetConfigAllMess('cardAddition', 'newSummerActivity')
    local activeCards = {}
    for i, v in pairs(config) do
        local tempActiveCards = v.activeCards or {}
        for i, cardId in ipairs(tempActiveCards) do
            activeCards[tostring(cardId)] = cardId
        end
    end

    return table.values(activeCards) or {}
end
--[[
获取队伍的材料本加成
@params teamCardIds map 编队卡牌id
@params questId int 
@return addition map {
    goodsId int 道具id
    num     int 队伍总计加成数目
}
--]]
function MurderManager:GetTeamMaterialQuestAddition( teamCardIds, questId )
    local dropAdditionData = self:GetDropAdditionDataByQuestId(questId)
    local addition = {
        goodsId = checkint(dropAdditionData.targetGoodsId),
        num = 0,
    }
    for _, v in pairs(checktable(teamCardIds)) do
        for i, value in ipairs(dropAdditionData.cardsId) do
            if checkint(v) == checkint(value) then
                addition.num = addition.num + checkint(dropAdditionData.addNum)
                break
            end
        end
    end
    if addition.num > 0 then
        return addition
    else
        return
    end
end
--[[
获取全服点数
--]]
function MurderManager:GetFullServerPoint()
    local homeData = self:GetHomeData()
    local bossId = self:GetUnlockBossId()
    if bossId == 0 then return 0 end
    local point = homeData.fullServerPoint[tostring(bossId)]
    return checkint(point)
end
--[[
获取目标全服点数
--]]
function MurderManager:GetTargetFullServerPoint()
    local bossId = self:GetUnlockBossId()
    if bossId == 0 then return 1 end
    local bossConfig = CommonUtils.GetConfig('newSummerActivity', 'bossSchedule', bossId)
    return checkint(bossConfig.bossMaxHp)
end
--[[
获取时钟状态
--]]
function MurderManager:GetClockState()
    local unlockBossId = self:GetUnlockBossId()   -- 已解锁的bossId
    local clockLevel = self:GetClockLevel()       -- 当前时钟等级
    local currentBossId = self:GetCurrentBossId() -- 获取当前进行的bossId
    local state = MURDER_CLOCK_STATE.UPGRADE
    if unlockBossId < currentBossId then -- 判断是否有未解锁的boss
        if unlockBossId == 0 then -- 为0时未打过boss，不需要领奖
            -- 时钟升级 -- 
            state = MURDER_CLOCK_STATE.UPGRADE
        elseif unlockBossId < currentBossId then
            if self:GetEffectBossId() == unlockBossId then -- boss是否打过
                -- boss --
                state = MURDER_CLOCK_STATE.BOSS
            else
                if self:IsBossRewardsCanDraw(unlockBossId) then
                    -- 奖励领取 --
                    state = MURDER_CLOCK_STATE.REWARD
                else 
                    -- 时钟升级 --
                    state = MURDER_CLOCK_STATE.UPGRADE 
                end
            end
        else
            -- 当期boss --
            state = MURDER_CLOCK_STATE.BOSS
        end
    else
        if currentBossId == 0 then
            if self:IsBossRewardsCanDraw(unlockBossId) then
                -- 奖励领取 --
                state = MURDER_CLOCK_STATE.REWARD
            else
                -- 回顾 -- 
                state = MURDER_CLOCK_STATE.FINAL
            end
        else
            -- 当期boss --
            state = MURDER_CLOCK_STATE.BOSS
        end
    end
    return state 
end
--[[
获取线索数据
--]]
function MurderManager:GetClueData()
    local homeData = self:GetHomeData()
    local clueData = {}
    local puzzleConfig = CommonUtils.GetConfigAllMess('puzzle', 'newSummerActivity')
    local unlock = checkint(self:GetUnlockModuleByType(MURDER_MOUDLE_TYPE.CLUE).subType)
    local lastDrawId = self:GetClueLastDrawId()
    for i, v in orderedPairs(puzzleConfig) do
        local data = clone(v)
        local isDrawn = false
        for _, id in ipairs(homeData.hasDrawnPuzzleRewards) do
            if checkint(i) == checkint(id) then
                isDrawn = true
                break
            end
        end
        data.isDrawn = isDrawn -- 是否领取
        if checkint(i) <= lastDrawId then
            data.isClick = true
        else
            data.isClick = cc.UserDefault:getInstance():getBoolForKey(string.format('MURDER_CLUE_%d_IS_CLICK_%d_%d', i, app.gameMgr:GetUserInfo().playerId, self:GetActivityId()), false)
        end
        data.isUnlock = checkint(i) <= unlock * 2 -- 一次解锁两个剧情
        table.insert(clueData, data)
    end
    return clueData
end
--[[
获取最近的线索领奖id
--]]
function MurderManager:GetClueLastDrawId()
    local drawId = 0
    local homeData = self:GetHomeData()
    for k, v in pairs(homeData.hasDrawnPuzzleRewards) do
        if checkint(v) > drawId then
            drawId = checkint(v)
        end
    end
    return drawId
end
--[[
获取活动id
--]]
function MurderManager:GetActivityId()
    local activityHomeData = app.gameMgr:GetUserInfo().activityHomeData
    for i, v in ipairs(activityHomeData.activity) do
        if checkint(v.type) == checkint(ACTIVITY_TYPE.MURDER) then
            return checkint(v.activityId)
        end
    end
    return 0
end
--[[
通过时钟等级获取当前boss关卡id 
@params clockId int 时钟等级
--]]
function MurderManager:GetQuestIdByBossId( bossId )
    local config = CommonUtils.GetConfig('newSummerActivity', 'bossSchedule', bossId)
    local list = {}
    if config then
        list[tostring(config.pointId1)] = config.pointId1
        list[tostring(config.pointId2)] = config.pointId2
        list[tostring(config.pointId3)] = config.pointId3
    end
    return list 
end
--[[
获取boss通关后的storyId
@return int storyId 剧情id
--]]
function MurderManager:GetBossPassedStoryId( )
    local clockLevel = self:GetClockLevel()
    local config = CommonUtils.GetConfig('newSummerActivity', 'building', clockLevel)
    local storyId = config.storyId2 
    return checkint(storyId)
end
--[[
获取当前debug是否开启
--]]
function MurderManager:GetDebugMode()
    return self.debugMode
end
--[[
设置boss难度
--]]
function MurderManager:SetBossDifficulty( difficulty )
    self.selectedDifficulty = checkint(difficulty)
end
--[[
获取boss难度
--]]
function MurderManager:GetBossDifficulty( )
    return self.selectedDifficulty
end
--[[
获取副本体力道具id
--]]
function MurderManager:GetMurderHpId()
    local config = CommonUtils.GetConfig('newSummerActivity', 'param', 1) or {}
    return checkint(config.goodsId or 880179)
end

--[[
初始化活动体力
--]]
function MurderManager:InitActivityHp()
    local homeData = self:GetHomeData()
    local paramConfig = CommonUtils.GetConfig('newSummerActivity', 'param', 1)
    local hpData = {
        hpGoodsId                = self:GetMurderHpId(),
        hpPurchaseAvailableTimes = checkint(homeData.buyActivityHpTimes),
        hpMaxPurchaseTimes       = checkint(paramConfig.buyActivityHpTimes),
        hpNextRestoreTime        = checkint(homeData.nextActivityHpSeconds),
        hpRestoreTime            = checkint(homeData.activityHpRecoverSeconds),
        hpUpperLimit             = checkint(homeData.activityHpUpperLimit),
        hp                       = checkint(homeData.activityHp),
        hpPurchaseConsume        = paramConfig.buyHpConsume[1],
        hpPurchaseCmd            = POST.MURDER_BUY_HP,
    }
    app.activityHpMgr:InitHpData(hpData)
end

function MurderManager:GetMurderGoodsIdByKey(key)
    if self.CHANGE_SKIN_CONF.SKIN_MODE then
        local changeSkinData = self:GetChangeSkinData()
        local murderGoods = changeSkinData.murderGoods
        return murderGoods[key] or DIAMOND_ID
    else
        local data = {
            murder_ticket_id = 880176 , -- 打boss 的门票
            munder_book_id = 880177  --打boss 掉落的道具
        }
        return data[key] or DIAMOND_ID
    end
end
---@param key string   获取配置文件中对应的卡牌 
---@param originCarId number 初始的卡牌id 
---@param basePath string  基本路径 
---@return string 最终路径
function MurderManager:GetChangeImagePath(key, originCarId ,basePath  )
    local cardId = nil 
    if self.skinMode then 
        local changeSkinData = self:GetChangeSkinData()
        cardId = changeSkinData.replaceImage[key]
    else 
        cardId = originCarId
    end
    return app.murderMgr:GetResPath(string.fmt("_basePath__cardId_" , { _basePath_ =basePath ,_cardId_ =  cardId })) 
end
---@param original number  original 原来的倍数
---@return number  返回修正后的倍数
function MurderManager:GetNumTimes(original)
    local skinData = self:GetChangeSkinData()
    local numN = skinData.numN ~= nil and skinData.numN or 1
    return checkint(original) * numN
end
-------------------------------------------
return MurderManager
