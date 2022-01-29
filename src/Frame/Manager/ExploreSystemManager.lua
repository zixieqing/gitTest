--[[
探索工具管理模块
--]]
local ManagerBase = require( "Frame.Manager.ManagerBase" )
---@class ExploreSystemManager
local ExploreSystemManager = class('ExploreSystemManager',ManagerBase)
ExploreSystemManager.instances = {}

--------------- import ---------------
local ExploreSystemConfigParser = require('Game.Datas.Parser.ExploreSystemConfigParser')
--------------- import ---------------

ExploreSystemManager.QUEST_STATE = {
    CLOSE   = -1,   -- 关闭
    PREPARE = 0,    -- 未开始
    ONGOING = 1,    -- 进行中
    END     = 2,    -- 已完成等待领取奖励
}

ExploreSystemManager.QUEST_TYPE = {
    CARD_STAR              = '1',        -- 卡牌星级
    CARD_LV                = '2',        -- 卡牌等级
    CARD_QUALITY           = '3',        -- 卡牌稀有度
    CARD_FAVORABILITYLEVEL = '4',        -- 卡牌好感度
    CARD_CAREER            = '5',        -- 卡牌职业
    CARD_BATTLEPOINT       = '6',        -- 卡牌灵力
    CARD_VIGOUR            = '7',        -- 卡牌新鲜度
}

--[[
    如果有配置 source 则 获取卡牌相关数据 优先从source获取
    如果有配置 comparison 则 则使用 comparison  否则默认为 >=
--]]
ExploreSystemManager.CONDITION_TYPE = {
    [ExploreSystemManager.QUEST_TYPE.CARD_STAR]              = {target = 'breakLevel'},
    [ExploreSystemManager.QUEST_TYPE.CARD_LV]                = {target = 'level'},
    [ExploreSystemManager.QUEST_TYPE.CARD_QUALITY]           = {target = 'qualityId', source = 'cardConf', comparison = '='},
    [ExploreSystemManager.QUEST_TYPE.CARD_FAVORABILITYLEVEL] = {target = 'favorabilityLevel'},
    [ExploreSystemManager.QUEST_TYPE.CARD_CAREER]            = {target = 'career',    source = 'cardConf', comparison = '='},
    [ExploreSystemManager.QUEST_TYPE.CARD_BATTLEPOINT]       = {target = 'battlePoint'},
    [ExploreSystemManager.QUEST_TYPE.CARD_VIGOUR]            = {target = 'vigour'},
}

---------------------------------------------------
-- mediator extend begin --
---------------------------------------------------
function ExploreSystemManager:ctor( key )
    self.super.ctor(self)
    if ExploreSystemManager.instances[key] ~= nil then
        funLog(Logger.INFO,"注册相关的facade类型" )
        return
    end
    
    self.parseConfig = nil
    self.confDatas   = {}
    ExploreSystemManager.instances[key] = self
end


function ExploreSystemManager.GetInstance(key)
    key = (key or "ExploreSystemManager")
    if ExploreSystemManager.instances[key] == nil then
        ExploreSystemManager.instances[key] = ExploreSystemManager.new(key)
    end
    return ExploreSystemManager.instances[key]
end

function ExploreSystemManager.Destroy( key )
    key = (key or "ExploreSystemManager")
    if ExploreSystemManager.instances[key] == nil then
        return
    end
    ExploreSystemManager.instances[key] = nil
end

--[[
    初始化探索数据

    @return datas bool 探索数据
--]]
function ExploreSystemManager:initExploreDatas(datas)
    datas = datas or {}
    local confDatas = self:getConfDataByConfType(self:getConfigParse().TYPE.QUEST)
    local questList = datas.questList or {}
    local dataLen = #questList
    local totalTeam = checkint(datas.totalTeam)
    local surplusTeam = totalTeam

    local isShowRemain = false
    local minCompleteTime = nil

    for i, quest in ipairs(questList) do
        local status = checkint(quest.status)
        if status == ExploreSystemManager.QUEST_STATE.ONGOING then
            surplusTeam = surplusTeam - 1
            local completeTime = checkint(quest.completeTime)
            if minCompleteTime == nil then
                minCompleteTime = completeTime
            else
                minCompleteTime = math.min(completeTime, minCompleteTime)
            end
        elseif status == ExploreSystemManager.QUEST_STATE.END then
            surplusTeam = surplusTeam - 1
            isShowRemain = true
        end
        quest.confData = confDatas[tostring(quest.questId)] or {}
    end
    datas.surplusTeam = surplusTeam

    self:updateRemain(isShowRemain, minCompleteTime)

    self:sortQuestList(questList)

    self:startExploreSystemCountdown_(checkint(datas.nextRefreshTime))
    return datas
end

--[[
    检查探索红点提示

    @params questList table 探索数据
--]]
function ExploreSystemManager:checkRemain(questList)
    local isShowRemain = false
    local minCompleteTime = nil
    for i, quest in ipairs(questList) do
        local status = checkint(quest.status)
        if status == ExploreSystemManager.QUEST_STATE.END then
            isShowRemain = true
        elseif status == ExploreSystemManager.QUEST_STATE.ONGOING then
            local completeTime = checkint(quest.completeTime)
            if minCompleteTime == nil then
                minCompleteTime = completeTime
            else
                minCompleteTime = math.min(completeTime, minCompleteTime)
            end
        end
    end

    self:updateRemain(isShowRemain, minCompleteTime)
end

--[[
    更新探索红点提示
    @params isShowRemain    bool 是否显示红点
    @params minCompleteTime int  最小完成时间
--]]
function ExploreSystemManager:updateRemain(isShowRemain, minCompleteTime)
    if isShowRemain then
        app.gameMgr:SetExploreSystemRedPoint(1)
    else
        app.gameMgr:SetExploreSystemRedPoint(0)
    end
    if minCompleteTime then
        app.timerMgr:RemoveTimer('EXPLORE_SYSTEM_REMAIN_TIME')
        app.gameMgr:GetUserInfo().exploreSystemLeftSeconds = minCompleteTime + 5
        local appMe = app:RetrieveMediator("AppMediator")
        if appMe then
            appMe:CheckExploreSystemRemainTime()
        end
    end
end

--[[
    初始化条件数据

    @return condition table 条件
--]]
function ExploreSystemManager:initConditionData(condition)
    if condition == nil then return end

    -- logInfo.add(5, tableToString(condition))
    local conditionConfData = self:getConfDataByConfType(self:getConfigParse().TYPE.CONDITION) or {}

    for i, v in ipairs(condition) do
        local questType = tostring(v.type)
        local desc = conditionConfData[tostring(questType)]
        if desc then
            local temp = checkint(v.number)
            if questType == ExploreSystemManager.QUEST_TYPE.CARD_QUALITY then
                temp = CardUtils.GetCardQualityName(temp)
            elseif questType == ExploreSystemManager.QUEST_TYPE.CARD_CAREER then
                temp = CardUtils.GetCardCareerName(temp)
            end
            desc = string.fmt(desc, {_target_num1_ = tostring(temp)})
            v.desc = desc
        else
            v.desc = ''
        end

    end

    -- self:sortConditionData(condition)
    sortByMember(condition, "type", true)
end

--[[
    初始化条件奖励

    @return questConf table 探索配置
--]]
function ExploreSystemManager:initConditionReward(questConf)
    local conditionRewardList = {}
    if questConf == nil then
        return conditionRewardList
    end

    local extraRewards = questConf.extraRewards or {}

    if next(extraRewards) == nil then
        table.insert(conditionRewardList, {
            demondConditionCount = 0,
            extraReward = clone(questConf.rewards or {})
        })
        
        return conditionRewardList
    end
    
    for demondConditionCount, extraReward in pairs(extraRewards) do
        if checkint(demondConditionCount) > 0 then
            table.insert(conditionRewardList, {
                demondConditionCount = demondConditionCount,
                extraReward = clone(extraReward)
            })
        end
    end

    sortByMember(conditionRewardList, "demondConditionCount", true)

    local mergeReward = function (reward1, reward2)
        for ii, vv in ipairs(reward1) do
            table.insert(reward2, vv)
        end

        local temp = {}
        for ii, vv in ipairs(reward2) do
            if temp[vv.goodsId] then
                temp[vv.goodsId].num = temp[vv.goodsId].num + vv.num
            else
                temp[vv.goodsId] = vv
            end
        end

        local reward = {}
        for ii, vv in pairs(temp) do
            table.insert(reward, vv)
        end
        return reward
    end

    local index = 1
    for i, v in ipairs(conditionRewardList) do
        if i > index then
            local extraReward1 = conditionRewardList[index].extraReward
            local extraReward2 = conditionRewardList[i].extraReward
            v.extraReward = mergeReward(extraReward1, extraReward2)
            index = i
        else
            local rewards = questConf.rewards or {}
            local extraReward = conditionRewardList[i].extraReward
            v.extraReward = mergeReward(rewards, extraReward)
        end 
        
    end

    return conditionRewardList
end

--[[
    懒初始化探索数据

    @return isCan bool 是否能解锁团队
--]]
function ExploreSystemManager:lazyInitQuestData(data)
    if data == nil or next(data) == nil then return end

    if data.isInitConditionData ~= true then
        local condition = data.condition
        self:initConditionData(condition)
        data.isInitConditionData = true
        data.conditionRewardList = self:initConditionReward(data.confData)
    end

    local selectedCardIds = {}
    if data.teamData == nil then
        local teamData = {}
        local cards = data.cards or {}
        local cardCount = #cards

        for i = 1, cardCount do
            local id = cards[i]
            if checkint(id) > 0 then
                table.insert(teamData, {id = cards[i]})
                selectedCardIds[tostring(id)] = id
            end
        end
        local confData = data.confData or {}
        local cardsNum = checkint(confData.cardsNum)
        data.isCanQuest = cardCount == cardsNum
        data.teamData = teamData
    end

    if data.curRewardIndex == nil then
        local curSatisfyConditionCount = nil
        local conditionCompleteNum = data.conditionCompleteNum
        if conditionCompleteNum then
            curSatisfyConditionCount = checkint(conditionCompleteNum)
        else
            local confData = data.confData or {}
            local cardsNum = checkint(confData.cardsNum)
            local satisfyConditionList = self:getSatisfyConditionList(selectedCardIds, data.condition, cardsNum)
            curSatisfyConditionCount = self:getSatisfyConditionCount(satisfyConditionList)
        end

        local curRewardIndex = self:getCurConditionRewardIndex(data.conditionRewardList, curSatisfyConditionCount)
        data.curRewardIndex = curRewardIndex
    end
end

function ExploreSystemManager:stopExploreSystemCountdown()
    if app.timerMgr:RetriveTimer(COUNT_DOWN_TAG_EXPLORE_SYSTEM) then
        app.timerMgr:RemoveTimer(COUNT_DOWN_TAG_EXPLORE_SYSTEM)
    end
end
function ExploreSystemManager:startExploreSystemCountdown_(seconds)
    self:stopExploreSystemCountdown()

    local countTime = math.max(2, checkint(seconds))
    app.timerMgr:AddTimer({name = COUNT_DOWN_TAG_EXPLORE_SYSTEM, countdown = countTime})
end

--[[
    获取到ExploreSystemConfigParser的对象

    @return ExploreSystemConfigParser
--]]
function ExploreSystemManager:getConfigParse()
    if not self.parseConfig then
        ---@type DataManager
        self.parseConfig = app.dataMgr:GetParserByName('exploreSystem')
    end
    return self.parseConfig
end

--[[
    获取到过滤后的卡牌
    @params filterQuestTypes table 过滤探索类型map

    @return filterCards table 过滤后的卡牌
--]]
function ExploreSystemManager:getFilterCards(filterQuestTypes)
    local cards = app.gameMgr:GetUserInfo().cards

    filterQuestTypes = filterQuestTypes or {}
    if next(filterQuestTypes) == nil then
        return
    end

    local filterCards = {}
    for i, card in pairs(cards) do
        local isSatisfy = self:checkIsSatisfyAllCondition(card, filterQuestTypes)
        if isSatisfy then
            table.insert(filterCards, card)
        end
    end
    
    return filterCards
end

--[[
    获取到满足探索条件的列表
    @params selectedCardIds table 选中卡牌id
    @params conditionDatas table 条件数据
    
    @return satisfyConditionList table 满足条件的列表
--]]
function ExploreSystemManager:getSatisfyConditionList(selectedCardIds, conditionDatas, cardsNum)
    if selectedCardIds == nil or next(selectedCardIds) == nil then
        return {}
    end

    local cardDatas = {}
    for k, id in pairs(selectedCardIds) do
        local cardData = app.gameMgr:GetCardDataById(id)
        table.insert(cardDatas, cardData)
    end

    local satisfyConditionList = {}
    for i, conditionData in ipairs(conditionDatas) do
        local filerType = conditionData.type
        -- 需要满足条件的个数
        local demandSatisfyNum = cardsNum
        local satisfyNum = 0
        for ii, cardData in ipairs(cardDatas) do
            local isSatisfy = self:checkIsSatisfySingleCondition(cardData, conditionData)
            if isSatisfy then
                satisfyNum = satisfyNum + 1
            end
        end

        satisfyConditionList[i] = satisfyNum >= demandSatisfyNum
    end

    return satisfyConditionList
end

--[[
    根据配表type获取到新探索配表数据
    @params confType string 配表类型

    @return confData
--]]
function ExploreSystemManager:getConfDataByConfType(confType)
    local confData = self.confDatas[confType]
    if confData then
        return confData
    end
    self.confDatas[confType] = CommonUtils.GetConfigAllMess(confType, 'exploreSystem')
    return self.confDatas[confType]
end


--[[
    获取满足条件的个数
    @params satisfyConditionList list 满足条件列表

    @return count int 满足条件的个数
--]]
function ExploreSystemManager:getSatisfyConditionCount(satisfyConditionList)
    local count = 0
    if next(satisfyConditionList) ~= nil then
        for i, v in ipairs(satisfyConditionList) do
            if v then
                count = count + 1
            end
        end
    end
    return count
end

--[[
    获取当前条件奖励的下标
    @params conditionRewardList list 条件奖励列表
    @params curSatisfyConditionCount list 满足条件的个数

    @return index int 当前条件奖励的下标
--]]
function ExploreSystemManager:getCurConditionRewardIndex(conditionRewardList, curSatisfyConditionCount)
    local index = 0
    for i, v in ipairs(conditionRewardList) do
        if curSatisfyConditionCount >= checkint(v.demondConditionCount) then
            index = math.max(index, i)
        end
    end
    return index
end

--[[
    根据条件Id 列表 获取到条件奖励
    @params ids list 满足条件id列表

    @return conditionReward
--]]
function ExploreSystemManager:getConditionRewardByIds(ids, confData)
    local conditionReward = {}
    ids = ids or {}
    local extraRewards = confData.extraRewards or {}
    for i, v in ipairs(ids) do
        local extraReward = extraRewards[tostring(v)]
        if extraReward and next(extraReward) ~= nil  then
            for i, v in ipairs(extraReward) do
                table.insert(conditionReward, v)
            end
        end
    end

    return conditionReward
end

function ExploreSystemManager:getRecommedCacheCards()
    return self.recommedCacheCard
end

function ExploreSystemManager:setRecommedCacheCards(cards)
    self.recommedCacheCard = cards
end

--[[
    获取推荐卡牌
    @params cards table 需要查询的卡牌
    @params conditionDatas table  探索条件所需的数量
    @params cardsNum int  最小卡牌个数
    @params dataTag  int  数据标识

    @return conditionReward
--]]
function ExploreSystemManager:getRecommedCards(cards, conditionDatas, cardsNum, dataTag)
    if cards == nil then return {} end
    if self:getRecommedCacheCards() then return self:getRecommedCacheCards() end
    
    local effectiveCards = {}

    local insert = table.insert

    for i, cardData in pairs(cards) do
        local id = checkint(cardData.id)
        -- logInfo.add(5, "id = " .. id)
        if app.gameMgr:CanSwitchCardStatus({id = id}, CARDPLACE.PLACE_EXPLORE_SYSTEM) then
            insert(effectiveCards, cardData)
        end
    end
    
    local keys = {}
    local keyCount = 0
    local satisfyTypeCouns = {}
    local satisfyConditionCards = {}
    
    -- 如果没有有效卡牌 直接 返回
    if next(effectiveCards) == nil then return effectiveCards end

    for i, conditionData in ipairs(conditionDatas) do
        local filerType = conditionData.type
        -- 需要满足条件的个数
        local demandSatisfyNum = cardsNum
        local satisfyCondCardNum = 0
        for ii, cardData in ipairs(effectiveCards) do
            local isSatisfy = self:checkIsSatisfySingleCondition(cardData, conditionData)
            if isSatisfy then
                satisfyConditionCards[tostring(filerType)] = satisfyConditionCards[tostring(filerType)] or {}
                local id = checkint(cardData.id)
                satisfyConditionCards[tostring(filerType)][tostring(id)] = id

                satisfyCondCardNum = satisfyCondCardNum + 1
            end
        end

        -- 条件类型满足的数量 必须大于 卡牌数 否组记为无效
        if satisfyCondCardNum >= cardsNum then
            keyCount = keyCount + 1
            insert(keys, {satisfyCondCardNum = satisfyCondCardNum, filerType = filerType})
        end
    end

    local recommedCards = {}
    if keyCount == 0 then
        -- 在卡牌列表中随机 cardsNum 个卡牌
        local cardCount = 0
        for i, cardData in ipairs(effectiveCards) do
            local id = checkint(cardData.id)
            table.insert(recommedCards, {id = id})

            cardCount = cardCount + 1
            if cardCount == cardsNum then
                break
            end
        end

    elseif keyCount == 1 then
        local keyData = keys[keyCount]
        local satisfyNum, filerType = keyData.satisfyCondCardNum, keyData.filerType
        local cards = satisfyConditionCards[tostring(filerType)]
        for id, _ in pairs(cards) do
            table.insert(recommedCards, {id = id})
            if i == cardsNum then
                break
            end
        end
    else

        local getIntersection = function (preCards, cards)
            local intersectionCards = {}
            local count = 0
            for k, v in pairs(cards) do
                if preCards[k] then
                    intersectionCards[k] = v
                    count = count + 1
                end
            end
            -- intersectionCards.count = count
            return intersectionCards, count
        end

        local getNotUsedKeys = function (keys, ownKeys)
            local notUsedKeys = {}
            for i, keyData in ipairs(keys) do
                local filerType = keyData.filerType
                if not ownKeys[tostring(filerType)] then
                    notUsedKeys[tostring(filerType)] = filerType
                end
            end
            return notUsedKeys
        end
        
        local mergeAllCard = function (keys)
            local cards = nil
            local isMergeSuc = true
            for i, keyData in ipairs(keys) do
                local filerType = keyData.filerType
                if i == 1 then
                    cards = clone(satisfyConditionCards[tostring(filerType)])
                else
                    local tempCards = satisfyConditionCards[tostring(filerType)]
                    local intersectionCards, count = getIntersection(cards, tempCards)
                    if count < cardsNum then
                        return
                    else
                        cards = intersectionCards
                    end
                end
            end

            return cards
        end

        local getOptimalCards = nil
        getOptimalCards = function (keys, optimalCards)
            local temp = {}
            local maxCardCount = 0
            
            local useKeys = nil
            if optimalCards then
                useKeys = optimalCards.useKeys
            end

            for i, keyData in ipairs(keys) do
                local filerType = keyData.filerType
                if useKeys then
                    if useKeys[tostring(filerType)] == nil then
                        local cards = satisfyConditionCards[tostring(filerType)]
                        local preCards = optimalCards.intersectionCards
                        local intersectionCards, count = getIntersection(preCards, cards)
                        if count > cardsNum then
                            temp[count] = {
                                intersectionCards = intersectionCards,
                            }
                            temp[count].useKeys = {}
                            for i, v in pairs(useKeys) do
                                temp[count].useKeys[i] = v
                            end
                            temp[count].useKeys[tostring(filerType)] = filerType
                            maxCardCount = math.max(maxCardCount, count)
                        elseif optimalCards.notUsedKeys then
                            optimalCards.notUsedKeys[tostring(filerType)] = nil
                            -- 如果没有未使用的key 直接结束当前循环
                            if next(optimalCards.notUsedKeys) == nil then
                                break
                            end
                        end
                    end
                else
                    if i > 1 then
                        local cards = satisfyConditionCards[tostring(filerType)]
                        local preFilerType = keys[i - 1].filerType
                        local preCards = satisfyConditionCards[tostring(preFilerType)]
                        local intersectionCards, count = getIntersection(preCards, cards)
                        if count > cardsNum then
                            temp[count] = {
                                intersectionCards = intersectionCards,
                                useKeys = {
                                    [tostring(filerType)] = filerType,
                                    [tostring(preFilerType)] = preFilerType,
                                }
                            }
                            maxCardCount = math.max(maxCardCount, count)
                        end
                    end
                end
            end

            if maxCardCount ~= 0 then
                if temp[maxCardCount].notUsedKeys == nil then
                    if optimalCards and optimalCards.notUsedKeys and (next(optimalCards.notUsedKeys) ~= nil) then
                        
                        temp[maxCardCount].notUsedKeys = {}
                        for i, v in pairs(optimalCards.notUsedKeys) do
                            if not temp[maxCardCount].useKeys[i] then
                                temp[maxCardCount].notUsedKeys[i] = v
                            end
                        end
                        
                    else
                        temp[maxCardCount].notUsedKeys = getNotUsedKeys(keys, temp[maxCardCount].useKeys)
                    end
                end
                if next(temp[maxCardCount].notUsedKeys) == nil then
                    return temp[maxCardCount].intersectionCards
                end
                return getOptimalCards(keys, temp[maxCardCount])
            else
                return optimalCards and (optimalCards.intersectionCards or {}) or {}
            end
        end

        -- 先检查 是否 能合并所有满足条件的卡牌
        local intersectionCards = mergeAllCard(keys)
        if intersectionCards == nil or next(intersectionCards) == nil then
            intersectionCards = getOptimalCards(keys)
        end
        
        if next(intersectionCards) == nil then
            local keyData = keys[1]
            intersectionCards = satisfyConditionCards[tostring(keyData.filerType)]
        end
        
        local cardCount = 0
        for id, _ in pairs(intersectionCards) do
            table.insert(recommedCards, {id = id})
            cardCount = cardCount + 1
            
            if cardCount == cardsNum then
                break
            end
        end

    end

    self:setRecommedCacheCards(recommedCards)

    return recommedCards
end


--[[
    获取到条件图标
    @params questType string 探索条件类型
    @params demandNum int    探索条件所需的数量

    @return conditionReward
--]]
function ExploreSystemManager:getConditionIcon(questType, demandNum)
    questType = tostring(questType)
    local icon = nil
    if questType == ExploreSystemManager.QUEST_TYPE.CARD_STAR then
        icon = string.format( "ui/exploreSystem/icon/explor_term_star_%s.png", checkint(demandNum))
    elseif questType == ExploreSystemManager.QUEST_TYPE.CARD_LV then
        icon = string.format( "ui/exploreSystem/icon/explor_term_lv_%s.png", checkint(demandNum) / 10)
    elseif questType == ExploreSystemManager.QUEST_TYPE.CARD_QUALITY then
        icon = string.format( "ui/exploreSystem/icon/explor_term_grade_%s.png", checkint(demandNum))
    elseif questType == ExploreSystemManager.QUEST_TYPE.CARD_FAVORABILITYLEVEL then
        icon = string.format( "ui/exploreSystem/icon/explor_term_heart_%s.png", checkint(demandNum))
    elseif questType == ExploreSystemManager.QUEST_TYPE.CARD_CAREER then
        icon = string.format( "ui/exploreSystem/icon/explor_term_battle_type_%s.png", checkint(demandNum))
    elseif questType == ExploreSystemManager.QUEST_TYPE.CARD_BATTLEPOINT then
        icon = "ui/exploreSystem/icon/explor_term_battle_level_1"
    else
        icon = "ui/exploreSystem/icon/explor_term_fresh_1"
    end

    return _res(icon)
end



function ExploreSystemManager:getQuestIndexByQuestId(questList, questId)
    local index = 0
    for i, v in ipairs(questList) do
        if v.questId == questId then
            index = i
            break
        end
    end
    return index
end

--[[
    检查卡牌是否满足所有过滤的类型
    @params cardData table/int 卡牌数据 / 卡牌数据库ID
    @params filerTypes table 过滤探索类型map

    @return isSatisfy bool 是否满足条件
--]]
function ExploreSystemManager:checkIsSatisfyAllCondition(cardData, conditionDatas)

    if type(cardData) ~= 'table' then
        cardData = app.gameMgr:GetCardDataById(cardData)
    end

    if cardData == nil then
        print('未发现卡牌数据')
        return false 
    end

    local isSatisfy = true
    for i, conditionData in pairs(conditionDatas) do
        isSatisfy = self:checkIsSatisfySingleCondition(cardData, conditionData)

        if not isSatisfy then
            break
        end
    end

    return isSatisfy
end

--[[
    检查卡牌是否满足单个过滤的类型
    @params cardData table 卡牌数据
    @params conditionData table 条件数据

    @return isSatisfy bool 是否满足条件
--]]
function ExploreSystemManager:checkIsSatisfySingleCondition(cardData, conditionData)
    local filerType = conditionData.type
    local demandNum = checkint(conditionData.number)
    local conditionType = ExploreSystemManager.CONDITION_TYPE[tostring(filerType)]
    local isSatisfy = false
    if conditionType == nil then
        print('未知 filerType = ' .. tostring(filerType))
    else
        local source = conditionType.source
        local target = conditionType.target
        local comparison = conditionType.comparison
    
        local ownNum = 0
    
        if source == 'cardConf' then
            local cardId = cardData.cardId
            local cardConf = CardUtils.GetCardConfig(cardId) or {}
            ownNum = checkint(cardConf[target])
        elseif target == 'battlePoint' then
            ownNum = app.cardMgr.GetCardStaticBattlePointByCardData(cardData)
        else
            ownNum = checkint(cardData[target])
        end
    
        if comparison == '=' then
            isSatisfy = ownNum == demandNum
        else
            isSatisfy = ownNum >= demandNum
        end
    end

    return isSatisfy
end

--[[
    检查团队是否改变
    @params oldTeamData table 旧的团队数据
    @params teamData    table 新团队数据

    @return isChange    bool  是否改变
--]]
function ExploreSystemManager:checkTeamDataIsChange(oldTeamData, teamData)
    local isChange = false
    for i = 1, MAX_TEAM_MEMBER_AMOUNT do
        local oldCardData = oldTeamData[i] or {}
        local cardData    = teamData[i] or {}

        if (next(oldCardData) == nil and next(cardData) ~= nil)
        or (checkint(oldCardData.id) ~= checkint(cardData.id)) then
            isChange = true
            break
        end
    end

    return isChange
end

--[[
    是否能解锁团队

    @return isCan bool 是否能解锁团队
--]]
function ExploreSystemManager:checkIsCanUnlockTeam(newLevel, oldLevel)
    local confData = self:getConfDataByConfType(self:getConfigParse().TYPE.TEAM_UNLOCK)
    
    local isCan = false
    for k, data in pairs(confData) do
        local unlockType = data.unlockType or {}
        local unlockNum = checkint(unlockType.unlockNum)
        if oldLevel < unlockNum and newLevel >= unlockNum then
            isCan = true
            break 
        end
    end

    return isCan
end

--[[
    排序条件数据

    @return conditionData table 条件数据
--]]
function ExploreSystemManager:sortConditionData(conditionData)
    table.sort(conditionData, function (a, b)
        if a == nil then return true end
        if b == nil then return false end

        return checkint(a.type) < checkint(b.type)
    end)
end

function ExploreSystemManager:sortQuestList(questList)

    local getPriority = function (questData)
        local priority = 0
        local status = questData.status == nil and ExploreSystemManager.QUEST_STATE.CLOSE or checkint(questData.status)
        if status == ExploreSystemManager.QUEST_STATE.END then
            priority = 4
        elseif status == ExploreSystemManager.QUEST_STATE.ONGOING then
            priority = 3
        elseif status == ExploreSystemManager.QUEST_STATE.PREPARE then
            priority = 2
        elseif status == ExploreSystemManager.QUEST_STATE.CLOSE then
            priority = 1
        end
        return priority, status
    end

    table.sort(questList, function (a, b)
        if a == nil then return true end
        if b == nil then return false end
        
        local aPriority = getPriority(a)
        local bPriority = getPriority(b)
        
        local aQuestId, aStatus = checkint(a.questId)
        local bQuestId, bStatus = checkint(b.questId)

        if aPriority == bPriority then
            local aConfData = a.confData or {}
            local bConfData = b.confData or {}
            local aCompleteTime = checkint(aConfData.completeTime)
            local bCompleteTime = checkint(bConfData.completeTime)
            
            if aCompleteTime == bCompleteTime then
                local aCardsNum = checkint(aConfData.cardsNum)
                local bCardsNum = checkint(bConfData.cardsNum)
                if aCardsNum == bCardsNum then
                    return aQuestId < bQuestId
                else
                    return aCardsNum < bCardsNum
                end
            else
                return aCompleteTime < bCompleteTime
            end
        end

        return aPriority > bPriority
    end)
end


--- 第一次获取探索的数据
function ExploreSystemManager:AddGetFirstExporeTimer()
    local tag = RemindTag.ORDER
    if not app.gameMgr:GetUserInfo().clock[JUMP_MODULE_DATA.EXPLORATIN] then
        return
    end

    local time = checkint(app.gameMgr:GetUserInfo().clock[JUMP_MODULE_DATA.EXPLORATIN])
    if time == 0 then
        app.timerMgr:RemoveTimer("ExploreFirst")
        app.dataMgr:AddRedDotNofication(tag, tag)
        AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, { countdown = 0, tag = RemindTag.ORDER })
    elseif time > 0 then
        local timecallback = function( countdown, remindTag, timeNum, datas)
            app.gameMgr:GetUserInfo().clock[JUMP_MODULE_DATA.EXPLORATIN] = countdown
            if countdown == 0 then
                app.timerMgr:RemoveTimer("ExploreFirst")
                app.dataMgr:AddRedDotNofication(tag, tag)
                AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, { countdown = countdown, tag = RemindTag.ORDER })
            end
        end
        app.timerMgr:AddTimer({ tag = RemindTag.ORDER, callback = timecallback, name = "ExploreFirst", countdown = time })
    end
end


return ExploreSystemManager