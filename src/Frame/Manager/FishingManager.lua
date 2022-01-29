---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by xingweihao.
--- DateTime: 2018/8/15 12:06 PM
---
--[[
钓场管理模块
--]]
local ManagerBase = require( "Frame.Manager.ManagerBase" )
---@class FishingManager :ManagerBase
local FishingManager = class('FishingManager',ManagerBase)
FishingManager.instances = {}

local BUFF_TYPE = {
    REDUCE_FISH_TIME  =1001 , --减少钓鱼时间的type
}
local  BAIT_CONSUME_VIGOUR = 2 -- 单位钓饵消耗的新鲜度

---------------------------------------------------
-- mediator extend begin --
---------------------------------------------------
function FishingManager:ctor( key )
    self.super.ctor(self)
    if FishingManager.instances[key] ~= nil then
        funLog(Logger.INFO,"注册相关的facade类型" )
        return
    end
    self.homeData = { isFishLimit = false }
    self.parseConfig = nil
    self.confDatas   = {}
    self.queryFishRewards = {}
    self.queryFishRewardsTime = 0
    FishingManager.instances[key] = self
    regPost(POST.FISHPLACE_SYN_DATA)
end


function FishingManager.GetInstance(key)
    key = (key or "FishingManager")
    if FishingManager.instances[key] == nil then
        FishingManager.instances[key] = FishingManager.new(key)
    end
    return FishingManager.instances[key]
end

function FishingManager.Destroy( key )
    key = (key or "FishingManager")
    if FishingManager.instances[key] == nil then
        return
    end
    AppFacade.GetInstance():UnRegsitMediator(POST.FISHPLACE_SYN_DATA.sglName , FishingManager.instances[key] )
    FishingManager.instances[key] = nil
end
--[[
　　---@Description: 检测是否达到收获
　　---@param :
　  ---@return :
　　---@author : xingweihao
　　---@date : 2018/9/12 7:23 PM
--]]
function FishingManager:CheckLimitRewards()
    local parserConfig  = self:GetConfigParse()
    local paramConfig = self:GetConfigDataByName(parserConfig.TYPE.PARAM_CONFIG)
    local limitRewardNum = checkint(paramConfig["1"].rewardNum)
    local rewardNum =  0
    local fishRewards = self:GetHomeDataByKey('fishRewards') or {}
    local isHave = false 
    for k , v in pairs(fishRewards) do
        if rewardNum  >= limitRewardNum  then
            isHave = true
        end
    end
    self:SetHomeDataByKeyalue('isFishLimit' , isHave)
end
--[[
    初始化钓场的数据
--]]
function FishingManager:InitFishDatas(datas)
    datas = datas or {}
    local requestData = datas.requestData  or {}
    if requestData.queryPlayerId and checkint(requestData.queryPlayerId) == checkint(app.gameMgr:GetUserInfo().playerId) then
        self.homeData = datas
        self:CheckLimitRewards()
        local minSecond , seatPos = self:GetMinLeftSeconds()
        if minSecond then
            self:StartCountDown(minSecond,seatPos)
        end
    end
end
--[[
　　---@Description: 获取到玩家钓场的buffId
　　---@param :
　  ---@return :
　　---@author : xingweihao
　　---@date : 2018/8/29 2:02 PM
--]]
function FishingManager:GetPlayerFishBuffIdAndTime()
    local buffData = self:GetHomeDataByKey('buff' ) or {}
    local buffId = 0
    local leftSeconds = checkint(buffData.leftSeconds)
    if leftSeconds > 0  then
        buffId =  buffData.buffId
    end
    return buffId ,leftSeconds
end
--[[
　　---@Description: 获取钓饵消耗的最小值 和 位置
　　---@param :
　  ---@return :minSecond 最小请求秒数 seatPos 位置
　　---@author : xingweihao
　　---@date : 2018/8/15 3:59 PM
--]]
function FishingManager:GetMinLeftSeconds()
    local fishCards = self:GetHomeDataByKey("fishCards")
    local minSecond = nil
    local seatPos = 0
    for seatId  , fishCardData in pairs(fishCards) do
        if fishCardData.baitId and fishCardData.endTime then
            if not  minSecond then
                minSecond =  checkint( fishCardData.endTime)
            else
                if checkint(fishCardData.endTime) < minSecond then
                    minSecond = checkint(fishCardData.endTime)
                    seatPos  =  seatId
                end
            end
        end
    end
    return minSecond , seatPos
end
function FishingManager:StartCountDown(leftSecond , seatPos)
    app.timerMgr:RemoveTimer(COUNT_DOWN_FISH_BAIT)
    if leftSecond == 0  then
        local preSeverTime = os.time()
        local callback = function (countdown, remindTag, timeNum, params, name)
            local currentSeverTime = os.time()
            local distanceS = currentSeverTime - preSeverTime
            if distanceS >= leftSecond  then
                self:SendSignalSysReq(seatPos)
            end
        end
        app.timerMgr:AddTimer({name = COUNT_DOWN_FISH_BAIT, countdown = leftSecond + 2, callback = callback})
    else
        self:SendSignalSysReq(seatPos)
    end

end
function FishingManager:RegistObserver()
    self:GetFacade():RegistObserver(POST.FISHPLACE_SYN_DATA.sglName, mvc.Observer.new(function(context, signal)
        local body = signal:GetBody()
        local fishCards = body.fishCards
        local fishBaits = body.fishBaits
        -- 设置钓鱼和钓饵的相关数据
        self:SetHomeDataByKeyalue("fishCards" ,fishCards )
        self:SetHomeDataByKeyalue("fishBaits" ,fishBaits )
        local minSecond , seatPos = self:GetMinLeftSeconds()
        -- 开启倒计时 只要时间存在 就开启倒计时
        if minSecond  then
            self:StartCountDown(minSecond,seatPos )
        end
    end)
    )
end
--[[
　　---@Description: 发送同步数据的请求
　　---@param :
　  ---@return :
　　---@author : xingweihao
　　---@date : 2018/8/15 5:38 PM
--]]
function FishingManager:SendSignalSysReq(seatNum )
    -- self:GetFacade():DispatchSignal(POST.FISHPLACE_SYN_DATA.cmdName , {
    -- })
end

---@return FishConfigParser
function FishingManager:GetConfigParse()
    if not self.parseConfig then
        ---@type DataManager
        self.parseConfig = app.dataMgr:GetParserByName('fish')
    end
    return self.parseConfig
end
function  FishingManager:GetConfigDataByName(name  )
    ---@type FishConfigParser
    local parseConfig = self:GetConfigParse()
    local configData  = parseConfig:GetVoById(name)
    return configData
end
--[[
　　---@Description: 获取到homeData 的数据
　　---@param :
　  ---@return : table 类型
　　---@author : xingweihao
　　---@date : 2018/8/15 2:09 PM
--]]
function FishingManager:GetFishHomeData()
   return self.homeData
end
--[[
　　---@Description: 由键值获取到homeData 的value
　　---@param :
　  ---@return :不确定
　　---@author : xingweihao
　　---@date : 2018/8/15 2:09 PM
--]]
function FishingManager:GetHomeDataByKey(key )
    return  self.homeData[tostring(key)]
end

--[[
　　---@Description: 设置homeData 的数据
　　---@param : key homeData 的键值 value 对应的值 isMerge 不传的时候当value 的类型为table 的时候 合并数据
　  ---@return :
　　---@author : xingweihao
　　---@date : 2018/8/8 8:53 PM
--]]
function FishingManager:SetHomeDataByKeyalue(key , value , isMerge)
    -- 如果是table 表就合并数据
    isMerge = isMerge == nil  and  true or isMerge
    if type(value) == 'table' and isMerge and type(self.homeData[tostring(key)]) == 'table'   then
        table.merge(self.homeData[tostring(key)] , value)
    else
        self.homeData[tostring(key)] = value
    end
end
--[[
　　---@Description: 获取到钓场等级配表数据
　　---@param :
　  ---@return :
　　---@author : xingweihao
　　---@date : 2018/8/15 2:18 PM
--]]
function FishingManager:GetLevelConfig()
    local parserConfig = self:GetConfigParse()
    local levelConfig = parserConfig:GetVoById(parserConfig.TYPE.LEVEL)
    return levelConfig
end
--[[
　　---@Description: 获取到钓场某一等级的配表数据
　　---@param : level int 钓场等级
　  ---@return :
　　---@author : xingweihao
　　---@date : 2018/8/15 2:18 PM
--]]
function FishingManager:GetOneLevelConfig(level)
    local  levelConfig  = self:GetLevelConfig()
    return levelConfig[tostring(level)] or {}
end
--[[
　　---@Description: 获取到钓场升级消耗的材料,和所需的熟练度
　　---@param : level int 钓场等级
　  ---@return :
　　---@author : xingweihao
　　---@date : 2018/8/15 2:29 PM
--]]
function FishingManager:GetUpgradeLevelConsumeFishingPopularityByLevel(level)
    local levelOneConfig = self:GetOneLevelConfig(level)
    local consumeData = clone(levelOneConfig.consume or {})
    local fishingPopularity = checkint(levelOneConfig.fishingPopularity)
    return consumeData ,fishingPopularity
end
--[[
　　---@Description: 获取到当前等级钓场钓饵的容量
　　---@param : fishLevel int 钓场的等级
　  ---@return : capacity int 该等级钓饵的容量
　　---@author : xingweihao
　　---@date : 2018/8/15 3:15 PM
--]]
function FishingManager:GetFishBaitCapacityByFishLevel(fishLevel)
    local levelOneConfig = self:GetOneLevelConfig(fishLevel)
    local capacity = checkint(levelOneConfig.baitNum)
    return capacity
end
--[[
　　---@Description: 获取到当前等级钓场钓鱼座位容量
　　---@param :fishLevel int 钓场的等级
　  ---@return :capacity int 该等级钓场的钓鱼座位容量
　　---@author : xingweihao
　　---@date : 2018/8/15 3:15 PM
--]]
function FishingManager:GetFishSeatCapacityByFishLevel(fishLevel)
    local levelOneConfig = self:GetOneLevelConfig(fishLevel)
    local capacity = checkint(levelOneConfig.seatNum)
    return capacity
end

--[[
　　---@Description: 获取到钓场商店的配表数据
　　---@param :
　  ---@return :
　　---@author : xingweihao
　　---@date : 2018/8/15 2:18 PM
--]]
function FishingManager:GetMallConfig()
    local parserConfig = self:GetConfigParse()
    local mallConfig = parserConfig:GetVoById(parserConfig.TYPE.MALL)
    return mallConfig
end

--[[
　　---@Description: 获取到钓场商店某一商品数据
　　---@param : id  mallconfig 的唯一索引标识
　  ---@return :
　　---@author : xingweihao
　　---@date : 2018/8/15 2:18 PM
--]]
function FishingManager:GetOneMallConfigById(id)
    local mallConfig = self:GetMallConfig()
    return mallConfig[tostring(id)] or {}
end
--[[
　　---@Description: 购买钓场商店物品消耗
　　---@param :id  mallconfig 的唯一索引标识 num 购买的数量
　  ---@return :
　　---@author : xingweihao
　　---@date : 2018/8/15 2:18 PM
--]]
function FishingManager:BuyMallGoodsConsumeData(id , num)
    local mallOneConfig = self:GetOneMallConfigById(id)
    local consumeData = clone(mallOneConfig.consume or {})
    return consumeData
end
--[[
　　---@Description: 获取已经添加的钓饵的数量
　　---@param :
　  ---@return : maxAddBaitNum int  可以添加的最大钓饵数量
　　---@author : xingweihao
　　---@date : 2018/8/15 3:13 PM
--]]
function FishingManager:GetFishBaitNum()
    local alreadyBaitNum = 0
    local fishBaits = self:GetHomeDataByKey('fishBaits')
    for id, baitData in pairs(fishBaits) do
        alreadyBaitNum  = checkint(baitData ) + alreadyBaitNum
    end
    return alreadyBaitNum
end
--[[
　　---@Description: 获取当前可以添加最大的钓饵数量
　　---@param :
　  ---@return : maxAddBaitNum int  可以添加的最大钓饵数量
　　---@author : xingweihao
　　---@date : 2018/8/15 3:13 PM
--]]
function FishingManager:GetAddMaxBaitNum()
    local fishLevel = self:GetHomeDataByKey('level')
    local capacityBaitNum =  self:GetFishBaitCapacityByFishLevel(fishLevel)
    local alreadyBaitNum = self:GetFishBaitNum()
    local maxAddBaitNum = capacityBaitNum - alreadyBaitNum
    return  maxAddBaitNum
end
--[[
　　---@Description: 根据好友的id 获取到可以添加的最大钓饵的数量
　　---@param :
　  ---@return : maxAddBaitNum int  可以添加的最大钓饵数量
　　---@author : xingweihao
　　---@date : 2018/8/15 3:13 PM
--]]
function FishingManager:GetAddMaxFriendBaitNum(friendId)
    local myFriendFish   = self:GetHomeDataByKey('myFriendFish') or {}
    local  maxAddBaitNum = 0
    for i, v in pairs(myFriendFish) do
        if checkint( i) ==  friendId then
            local cardData  = app.gameMgr:GetCardDataByCardId(v.cardId)
            maxAddBaitNum = checkint(cardData.vigour / 2)
        end
    end
    return  maxAddBaitNum
end
--[[
　　---@Description: 获取到诱饵消耗的预估时间
　　---@param :
　　---@author : xingweihao
　　---@date : 2018/8/15 8:57 PM
--]]
function FishingManager:GetEstimatedtime()
    local buffId ,leftSeconds = self:GetPlayerFishBuffIdAndTime()
    local  baitLeftSeconds = 0
    local fishCards = self:GetHomeDataByKey('fishCards')
    for i, v in pairs(fishCards) do
        if v.leftSeconds and checkint(v.leftSeconds)   > 0  then
            if baitLeftSeconds == 0   then
                baitLeftSeconds =  checkint(v.leftSeconds)
            else
                baitLeftSeconds = math.min(baitLeftSeconds , v.leftSeconds )
            end
        end
    end
    local parserConfig  = self:GetConfigParse()
    local produceConfig = self:GetConfigDataByName(parserConfig.TYPE.PRODUCE_CONFIG)
    local prayConfig    = self:GetConfigDataByName(parserConfig.TYPE.PRAY)
    local reduceTable   = {
        buffLeftTimes = 0, -- 剩余buff 时间
        buffParams    = 0, --buff缩减概率
    }

    if checkint(buffId ) == BUFF_TYPE.REDUCE_FISH_TIME  then
        -- 是否存在缩减时间的钓饵
        reduceTable.buffLeftTimes = (leftSeconds - baitLeftSeconds ) > 0 and (leftSeconds - baitLeftSeconds)  or 0
        reduceTable.buffParams    = prayConfig[tostring(buffId)].buffParam
    end
    local fishCardsData = self:GetHomeDataByKey('fishCards')
    local fishBaitsData = self:GetHomeDataByKey('fishBaits')
    local totalTime     = 0
    --  首先计算钓饵总共作用的时间
    local totalNum      = 0
    for baitId, baitData in pairs(fishBaitsData) do
        local num           = baitData
        local baitOndConfig = produceConfig[tostring(baitId)] or {}
        totalTime           = num * checkint(baitOndConfig.time) + totalTime
        totalNum            = totalNum + num
    end
    -- 算出来平均时间

    local averageTime = 0
    if totalNum ~= 0   then
        averageTime =  totalTime / totalNum
    end
    local minVigour   = nil  -- 钓鱼队伍中最小的新鲜度
    local cardNum     = 0  -- 计算卡牌的数量
    for i, v in pairs(fishCardsData) do
        if next(v) then
            local cardData = app.gameMgr:GetCardDataById(v.playerCardId )
            cardData.vigour = checkint(cardData.vigour)  > 0 and checkint(cardData.vigour) or 0
            minVigour      = (minVigour and math.min(minVigour, cardData.vigour)) or cardData.vigour
            cardNum        = cardNum + 1
        end
    end
    minVigour = minVigour or 0
    -- 可以消耗的钓饵数量
    local num            = checkint(minVigour) / BAIT_CONSUME_VIGOUR
    local minConsumeTime = 0
    if num * cardNum > totalNum then
        minConsumeTime = totalNum / cardNum * averageTime
    else
        minConsumeTime = num *  averageTime
    end
    -- 算出卡牌的最小的消耗时间后 计算buff 的缩减时间
    if checkint(reduceTable.buffLeftTimes) > 0 then
        if reduceTable.buffLeftTimes > minConsumeTime then
            minConsumeTime = minConsumeTime * (1 - reduceTable.buffParams)
        else
            minConsumeTime = minConsumeTime - reduceTable.buffLeftTimes  / (1 - reduceTable.buffParams) +  reduceTable.buffLeftTimes
        end
    end
    return checkint(minConsumeTime)
end
--[[
　　---@Description: 获取到好友到玩家钓场的预估时间
　　---@param : fisherman 设置的好友钓手信息
　　---@author : xingweihao
　　---@date : 2018/8/15 8:57 PM
--]]
function FishingManager:GetFriendEstimatedTime(fisherman, buffData)
    local friendFish = fisherman or self:GetHomeDataByKey('friendFish')
    local buffData = buffData or self:GetHomeDataByKey('buff') or {}
    friendFish = friendFish or {}
    local estimatedTime = 0
    if table.nums(friendFish) > 0  then
        local consumeVigour = checkint(friendFish.baitNum) * BAIT_CONSUME_VIGOUR
        local consumeBaitNum  = 0
        if consumeVigour > checkint(friendFish.vigour) then
            consumeBaitNum = friendFish.vigour/ BAIT_CONSUME_VIGOUR
        else
            consumeBaitNum = friendFish.baitNum
        end
        estimatedTime = self:GetBaitConumeTimeAndVigour(friendFish.baitId ,consumeBaitNum ,buffData.buffId , buffData.leftSeconds )
    end

    return estimatedTime
end 
--[[
　　---@Description: 获取到所有卡牌消耗的新鲜度
　　---@param :
　  ---@return :
　　---@author : xingweihao
　　---@date : 2018/8/21 2:05 PM
--]]
function FishingManager:GetFishCardsConsumeVigour()
    local fishCards = self:GetHomeDataByKey("fishCards")
    local minVigour = nil
    local cardNum = 0
    for i, v in pairs(fishCards) do
        if v.cardId then
            cardNum = cardNum +1
            local cardData = app.gameMgr:GetCardDataById(v.playerCardId or  v.cardId)
            local vigour = checkint(cardData.vigour)
            if not  minVigour then
                minVigour = vigour
            else
                minVigour = math.floor(minVigour ,vigour )
            end
        end
    end
    minVigour = minVigour or 0 
    local fishBaitsData = self:GetHomeDataByKey('fishBaits')
    local  consumeVigour  =  0

    for i, v in pairs(fishBaitsData) do
        local  time   , vigour  = self:GetBaitConumeTimeAndVigour(i ,v )
        consumeVigour = consumeVigour + vigour
    end
    minVigour = minVigour * cardNum
    if minVigour > consumeVigour then
        minVigour = consumeVigour
    end
    return consumeVigour
end
--[[
　　---@Description: 更具钓饵和数量 获取到钓饵可以消耗的时间和新鲜度
　　---@param :baitId 钓饵  num 钓饵数量 buffId 的效果  buffTime 作用的剩余时间
　  ---@return :
　　---@author : xingweihao
　　---@date : 2018/8/21 4:41 PM
--]]
function FishingManager:GetBaitConumeTimeAndVigour(baitId , num , buffId , buffTime  )
    buffTime  = checkint(buffTime)
    buffId = checkint(buffId)
    local parserConfig  = self:GetConfigParse()
    local produceConfig = self:GetConfigDataByName(parserConfig.TYPE.PRODUCE_CONFIG)
    local produceOneConfig = produceConfig[tostring(baitId)] or {}
    num = math.floor(num)
    local times = checkint(produceOneConfig.time) * num
    if buffId == BUFF_TYPE.REDUCE_FISH_TIME  then
        local parserConfig = self:GetConfigParse()
        local prayConfig    = self:GetConfigDataByName(parserConfig.TYPE.PRAY)
        local buffParam  = prayConfig[tostring(buffId)] and tonumber( prayConfig[tostring(buffId)].buffParam) or 0
        local currentBuffTimes = times * ( 1- buffParam)
        if checkint(buffTime)  <  checkint(currentBuffTimes)   then
            currentBuffTimes =  times -  buffTime/(1- buffParam) +  buffTime
        end
        times = checkint(currentBuffTimes)
    end
    local vigour = checkint(num)  * BAIT_CONSUME_VIGOUR
    return times , vigour
end

--[[
　　---@Description: 设置钓场奖励查看时间
　　---@param : queryFishRewardsTime  时间戳
　  ---@return :
　　---@author : xingweihao
　　---@date : 2018/8/9 5:15 PM
--]]
function FishingManager:SetQueryFishRewardsTime(queryFishRewardsTime)
    self.queryFishRewardsTime = queryFishRewardsTime
end

--[[
　　---@Description: 获取钓场奖励查看时间
　　---@param :
　  ---@return : queryFishRewardsTime  时间戳
　　---@author : xingweihao
　　---@date : 2018/8/9 5:15 PM
--]]
function FishingManager:GetQueryFishRewardsTime()
    return  self.queryFishRewardsTime
end


--[[
　　---@Description: 设置钓场奖励查看时间
　　---@param : queryFishRewards  rewards 格式
　  ---@return :
　　---@author : xingweihao
　　---@date : 2018/8/9 5:15 PM
--]]
function FishingManager:SetQueryFishRewards(queryFishRewards)
    self.queryFishRewards = queryFishRewards
    local data  = {}
    for i, v in pairs(self.queryFishRewards) do
        data[tostring(v.goodsId)] = v.num
    end
    self:SetHomeDataByKeyalue('fishRewards' , data , false)
    self:CheckLimitRewards()
end

--[[
　　---@Description: 获取钓场奖励
　　---@param :
　  ---@return :queryFishRewards  rewards 格式
　　---@author : xingweihao
　　---@date : 2018/8/9 5:15 PM
--]]
function FishingManager:GetQueryFishRewards()
    return  self.queryFishRewards
end
--[[
　　---@Description: 设置钓场卡牌的信息
　　---@param :
　  ---@return :
　　---@author : xingweihao
　　---@date : 2018/8/29 11:43 AM
--]]
function FishingManager:SetFishCardPlace(playerCardId  , fishPlaceId)
    local fishCards = app.fishingMgr:GetHomeDataByKey("fishCards")
    local oldPlayerCardId =  fishCards[tostring(fishPlaceId)] and  fishCards[tostring(fishPlaceId)].playerCardId
    local oldCards = {}
    if checkint(oldPlayerCardId)  > 0 then  -- 判断原来卡牌位置上面是否有飨灵
        table.insert(oldCards , {id = oldPlayerCardId} )
    end
    if checkint(playerCardId ) > 0  then  -- 飨灵卡牌存在就添加 不存在就是卸下
        app.gameMgr:SetCardPlace(oldCards , {{id = playerCardId}}, CARDPLACE.PLACE_FISH_PLACE)
    else
        app.gameMgr:DeleteCardPlace(oldCards ,CARDPLACE.PLACE_FISH_PLACE)
    end
end
--[[
　　---@Description: 卡牌的数据信息
　　---@param :
　  ---@return :
　　---@author : xingweihao
　　---@date : 2018/8/28 3:01 PM
--]]
function FishingManager:AddFriendCardsData(cardData , friendId)
    local friendList = app.gameMgr:GetUserInfo().friendList
    local friendId = checkint(friendId)
    for i, v in pairs(friendList) do
        if v.friendId == friendId then
            if table.nums(cardData) > 0  then
                v.friendFish = {}
                v.friendFish.friendId  = app.gameMgr:GetUserInfo().playerId
                local cardOneData = app.gameMgr:GetCardDataById(cardData.playerCardId)
                v.friendFish.playerCardId = cardData.playerCardId
                v.friendFish.baitNum = cardData.baitNum
                v.friendFish.baitId = cardData.baitId
                v.friendFish.vigour = cardData.vigour
                v.friendFish.cardId = cardOneData.cardId
                app:DispatchObservers(FISH_FRIEND_CARD_UNLOAD_AND_LOAD_EVENT ,{index  = i })
            end
            break
        end
    end
end
--[[
　　---@Description: 去好友钓场添加卡牌的数据
　　---@param :friendId 好友的id
　  ---@return :
　　---@author : xingweihao
　　---@date : 2018/8/28 5:43 PM
--]]
function FishingManager:AddMyFriendFishCardData(cardData , friendId)
    app.gameMgr:SetCardPlace({},{{id = cardData.playerCardId }} ,CARDPLACE.PLACE_FISH_PLACE)
    local myFriendFish = self:GetHomeDataByKey('myFriendFish') or {}
    myFriendFish[tostring(friendId)] = cardData
    self:SetHomeDataByKeyalue( 'myFriendFish' , myFriendFish)
    self:AddFriendCardsData(cardData , friendId)
end
--[[
　　---@Description: 好友添加到自己钓场卡牌
　　---@param :
　  ---@return :
　　---@author : xingweihao
　　---@date : 2018/8/28 9:19 PM
--]]
function FishingManager:FriendAddCardDataFish(cardData)
    local friendFish = self:GetHomeDataByKey('friendFish') or {}
    local buffId , leftSeconds = self:GetPlayerFishBuffIdAndTime()
    local leftSeconds  = self:GetBaitConumeTimeAndVigour(cardData.baitId , 1 , buffId , leftSeconds)
    cardData.leftSeconds = leftSeconds
    friendFish =  clone(cardData)
    self:SetHomeDataByKeyalue("friendFish" , friendFish ,true )
    app:DispatchObservers(FISH_FRIEND_ADD_CARD_EVENT , {})
end
--[[
　　---@Description: 卸下在好友的钓场钓场的信息
　　---@param :
　  ---@return :
　　---@author : xingweihao
　　---@date : 2018/8/28 3:01 PM
--]]
function FishingManager:UnloadFriendFishCardsData(data)
    -- 收回剩余的钓饵
    --if checkint( data.baitId) > 0 and checkint(data.baitNum) > 0  then
    --    CommonUtils.DrawRewards({ {goodsId = data.baitId , num =data.baitNum } })
    --end
    -- 删除好友卡牌的钓鱼位
    app.gameMgr:DeleteCardPlace({{id = data.playerCardId }} , CARDPLACE.PLACE_FISH_PLACE)
    app.gameMgr:UpdateCardDataById(data.playerCardId ,{vigour = data.vigour})
    local myFriendFish = self:GetHomeDataByKey('myFriendFish') or {}
    local friendId = nil
    dump(myFriendFish)
    dump(data)
    for i, v in pairs(myFriendFish) do
        if checkint(v.playerCardId) ~= 0 and  checkint(v.playerCardId)  == checkint(data.playerCardId)   then
            friendId =checkint(i)
            break
        end
    end
    local friendList = app.gameMgr:GetUserInfo().friendList
    print("friendId == " ,friendId)
    if friendId  then
        local cardData  =  myFriendFish[tostring(friendId)]
        myFriendFish[tostring(friendId)] = nil
        table.merge(data, {friendId = friendId})
        app:DispatchObservers(FISHERMAN_ALTER_IN_FRIEND_EVENT, data)
        -- local mediator = app:RetrieveMediator("FishingGroundMediator")
        -- if mediator then
        --     app:DispatchObservers(POST.FISHPLACE_KICK_FRIEND_FISH_CARD.sglName ,{requestData = {
        --         friendId = friendId,
        --         playerCardId = cardData.playerCardId ,
        --     } })
        -- end
        for i, v in pairs(friendList) do
            if checkint(v.friendId) == friendId   then
                v.friendFish = {}
                app:DispatchObservers(FISH_FRIEND_CARD_UNLOAD_AND_LOAD_EVENT ,{index  = i })
            end
        end
    else
        for i, v in pairs(friendList) do
            if type(v.friendFish) == 'table' and
            checkint( v.friendFish.playerCardId ) == checkint(data.playerCardId )
            and  checkint( v.friendFish.playerId ) == checkint(data.playerId )  then
                v.friendFish = {}
                app:DispatchObservers(FISH_FRIEND_CARD_UNLOAD_AND_LOAD_EVENT ,{index  = i })
            end
        end
    end
end
--[[
　　---@Description: 钓饵获得结晶
　　---@param : baitId 钓饵的id
　  ---@return :
　　---@author : xingweihao
　　---@date : 2018/8/24 11:52 AM
--]]
function FishingManager:GetOutput( baitId )
    if 321001 == checkint(baitId) then
        return WATER_CRYSTALLIZATION_ID
    elseif 321002 == checkint(baitId) then
        return WATER_CRYSTALLIZATION_ID
    elseif 321003 == checkint(baitId) then
        return WATER_CRYSTALLIZATION_ID
    elseif 321004 == checkint(baitId) then
        return WIND_CRYSTALLIZATION_ID
    elseif 321005 == checkint(baitId) then
        return WIND_CRYSTALLIZATION_ID
    elseif 321006 == checkint(baitId) then
        return WIND_CRYSTALLIZATION_ID
    elseif 321007 == checkint(baitId) then
        return RAY_CRYSTALLIZATION_ID
    elseif 321008 == checkint(baitId) then
        return RAY_CRYSTALLIZATION_ID
    elseif 321009 == checkint(baitId) then
        return RAY_CRYSTALLIZATION_ID
    end
    return GOLD_ID
end
--[[
　　---@Description: 检测钓场是否可以升级
　　---@param :
　  ---@return :
　　---@author : xingweihao
　　---@date : 2018/8/29 7:08 PM
--]]
function FishingManager:CheckFishUpgradeLevel()
    local fishPlaceLevel = app.gameMgr:GetUserInfo().fishPlaceLevel
    local fishPopularity = CommonUtils.GetCacheProductNum(FISH_POPULARITY_ID)
    local isUpgrade  = false
    if fishPlaceLevel then
        local levelConfig = self:GetOneLevelConfig(fishPlaceLevel+1)
        if table.nums(levelConfig) > 0   then
            local needFishingPopularity =  checkint(levelConfig.fishingPopularity)
            if  fishPopularity >= needFishingPopularity  then
                local isUpgradeTwo =  true
                for i,v in ipairs(levelConfig.consume) do
                    local hasNum = app.gameMgr:GetAmountByGoodId(v.goodsId)
                    if hasNum < v.num then
                        isUpgradeTwo = false
                    end
                end
                isUpgrade = isUpgradeTwo
            end
        end
    end
    return isUpgrade
end
--[[
　　---@Description: 更新钓场的等级
　　---@param : restaurantLevel 餐厅的等级
　  ---@return :
　　---@author : xingweihao
　　---@date : 2018/9/3 2:46 PM
--]]
function FishingManager:UpdateFishLevel()
    -- 如果是0 级证明还没有正常的升过级
    if  checkint(app.gameMgr:GetUserInfo().fishPlaceLevel) == 0  then
        local isUnLock = CommonUtils.UnLockModule(JUMP_MODULE_DATA.FISHING_GROUND)
        if isUnLock then
            app.gameMgr:GetUserInfo().fishPlaceLevel = 1
        end
    end
    
end
return FishingManager