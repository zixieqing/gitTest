--[[
 * author : kaishiqi
 * descpt : 本地虚拟数据
]]
-- lua的随机函数有点小毛病，如果时间太短，那么取到的随机数可能是一样的，如果随机的数字太小也有点毛病。所以我们自己的随机函数代码下：
math.randomseed(os.clock() * math.random(1000000, 9000000) * math.random(1000000, 9000000))

local subVirtualList = {
    'user', 'player', 'takeaway', 'questTeam', 'tower', 'activity', 'restaurant', 'kofArena', 'artifact',
    'market', 'gambling', 'commerce', 'cooking', 'mall', 'card', 'airship', 'explore', 'friend', 'plot', 
    'pet', 'union', 'worldBoss', 'icePlace', 'rank', 'collection', 'battleCard', 'bar', 'championship',
    'lunaTower', 'anniv2020', 'house',
}

local goodsTypsConfs = clone(CommonUtils.GetConfigAllMess('type', 'goods') or {})
goodsTypsConfs['10'] = nil -- avatar
goodsTypsConfs['21'] = nil -- pet
goodsTypsConfs['25'] = nil -- skin
goodsTypsConfs['27'] = nil -- avatar theme
goodsTypsConfs['30'] = nil -- monster
goodsTypsConfs['50'] = nil -- achieve (hand avatar)
goodsTypsConfs['99'] = {ref = 'other'}

-- 剔除瞎配的ref类型，导致找到空表的定义
for goodsType, goodsTypeConf in pairs(goodsTypsConfs) do
    local goodsTypeRef  = CommonUtils.GetGoodsTypeTrueRef(goodsTypeConf.ref)
    local goodsTypeConf = CommonUtils.GetConfigAllMess(goodsTypeRef, 'goods')
    if next(goodsTypeConf) == nil then
        goodsTypsConfs[goodsType] = nil
    end
end


local moneyIdList  = table.keys(CommonUtils.GetConfigAllMess('money', 'goods') or {900001})
local ticketIdList = table.keys(CommonUtils.GetConfigAllMess('other', 'goods') or {890002})
local currencyIdList = {}
table.insertto(currencyIdList, moneyIdList)
table.insertto(currencyIdList, ticketIdList)


-- 过滤出有小小的卡牌id和皮肤id，方便后面创建卡牌使用
-- local resConfFile  = CommonUtils.GetConfigAllMess('onlineResourceTrigger', 'card')
local cardConfFile = CommonUtils.GetConfigAllMess('card', 'card')
local skinConfFile = CommonUtils.GetConfigAllMess('cardSkin', 'goods')
local validCardIdList = {}
local validCardIdMap  = {}
for cardId, cardConf in pairs(cardConfFile) do
    validCardIdMap[tostring(cardId)] = {}
    for _, skinMap in pairs(cardConf.skin) do
        local skinId = table.keys(skinMap)[1]
        validCardIdMap[tostring(cardId)][tostring(skinId)] = false
    end
end
for skinId, skinConf in pairs(skinConfFile) do
    if utils.isExistent(_res(string.format('cards/spine/avatar/%s.json', tostring(skinConf.spineId)))) then
        if validCardIdMap[tostring(skinConf.cardId)] then
            validCardIdMap[tostring(skinConf.cardId)][tostring(skinId)] = true
        end
    end
end
for cardId, skinMap in pairs(validCardIdMap) do
    for skinId, isValid in pairs(skinMap) do
        if isValid == false then
            skinMap[skinId] = nil
        end
    end
    if next(skinMap) == nil then
        validCardIdMap[cardId] = nil
    end
end
validCardIdList = table.keys(validCardIdMap)


-- local servers
gameServer   = gameServer or require('interfaces.server.GameServer').new()
chatServer   = chatServer or require('interfaces.server.ChatServer').new()
ttGameServer = ttGameServer or require('interfaces.server.TTGameServer').new()

virtualData = {
    uuid_ = 0,

    goodsTypsConfs  = goodsTypsConfs, -- all goods type conf
    currencyIdList  = currencyIdList, -- all goods currency id
    ticketIdList    = ticketIdList,   -- all goods ticket id
    moneyIdList     = moneyIdList,    -- all goods money id
    confCacheMap    = {},             -- load conf file cache
    validCardIdMap  = validCardIdMap,
    validCardIdList = validCardIdList,

    
    -- get conf file by cache
    getConf = function(moduleFolder, jsonName, id)
        if virtualData.confCacheMap[tostring(moduleFolder)] == nil then
            virtualData.confCacheMap[tostring(moduleFolder)] = {}
        end
        if virtualData.confCacheMap[tostring(moduleFolder)][tostring(jsonName)] == nil then
            virtualData.confCacheMap[tostring(moduleFolder)][tostring(jsonName)] = CommonUtils.GetConfigAllMess(jsonName, moduleFolder)
        end
        if id == nil then
            return virtualData.confCacheMap[tostring(moduleFolder)][tostring(jsonName)] or {}
        else
            return checktable(virtualData.confCacheMap[tostring(moduleFolder)][tostring(jsonName)])[tostring(id)] or {}
        end
    end,


    -- generate uuid
    generateUuid = function()
        virtualData.uuid_ = virtualData.uuid_ + 1
        return virtualData.uuid_
    end,


    generateCurrencyId = function()
        return currencyIdList[virtualData._r(#currencyIdList)]
    end,


    -- 创建指定范围内的随机数
    -- e.g. _r(3)
    -- e.g. _r(10,20)
    _r = function(n, m)
        n = n or 0
        if m == nil then
            m = checkint(n)
            n = 1
        elseif checkint(n) > checkint(m) then
            local t = n
            n = checkint(m)
            m = checkint(t)
        else
            m = checkint(m)
        end
        if n > m then
            return math.random(m, n)
        else
            return math.random(n, m)
        end
    end,


    -- 随机选项
    _rValue = function(optionList, count)
        local valueList  = {}
        local valueCount = count or 1
        local optionMap  = {}
        for index, value in ipairs(optionList) do
            optionMap[tostring(index)] = true
        end
        for i = 1, math.min(valueCount, #optionList) do
            local leftKeys = table.keys(optionMap)
            local rIndex   = leftKeys[virtualData._r(1, #leftKeys)]
            local rValue   = optionList[checkint(rIndex)]
            table.insert(valueList, rValue)
            optionMap[rIndex] = nil
        end
        return valueList
    end,


    -- http jsonStr result to table
    j2t = function(jsonStr)
        return json.decode(jsonStr) or {}
    end,


    -- tableData to http table result
    t2t = function(tableData, errcode, errmsg)
        return {data = clone(tableData), errcode = errcode or 0, errmsg = errmsg or ''}
    end,


    -- 创建随机玩家ID
    createPlayerId = function()
        -- return checkint(string.format('100%03s', tostring(_r(999))))
        return virtualData.generateUuid()
    end,


    -- 创建随机名字（目前只支持英文）
    createName = function(len)
        len = len and len or virtualData._r(5, 10)
        local nameChars = {}
        for i=1, len do
            local char = string.char(virtualData._r(97, 122))  -- 小写ansic字母范围
            table.insert(nameChars, char)
        end
        return table.concat(nameChars, '')
    end,


    -- 根据时间格式创建秒数
    -- 天 d
    -- 时 h
    -- 分 s
    -- 秒 m
    -- ? 是否为随机
    -- e.g. 'd:3,h:12'      -- 3天12小时 的秒数
    -- e.g. 'h:3,m:30'      -- 3小时30秒 的秒数
    -- e.g. 'h:3:?,s:30:?'  -- 3的随机小时 + 30的随机分钟 的秒数
    createSecond = function(createStr)
        local createList = string.split(createStr, ',')
        local second = 0
        for _,v in pairs(createList) do
            local createArgs = string.split(v, ':')
            local createType = tostring(createArgs[1])
            local createNum  = checkint(createArgs[2])
            local isRandom   = tostring(createArgs[3]) == '?'

            if createType == 'd' then
                second = second + (isRandom and virtualData._r(createNum) or createNum) * 24*60*60
            elseif createType == 'h' then
                second = second + (isRandom and virtualData._r(createNum) or createNum) * 60*60
            elseif createType == 's' then
                second = second + (isRandom and virtualData._r(createNum) or createNum) * 60
            elseif createType == 'm' then
                second = second + (isRandom and virtualData._r(createNum) or createNum)
            end
        end
        return second
    end,


    createFormatTime = function(intTime)
        return os.date('%Y-%m-%d %H:%M:%S', intTime or os.time())
    end,


    -- 生成随机道具列表
    createGoodsList = function(len)
        local goodsList = {}
        local loopCount = 0
        -- while #goodsList < len and loopCount < 100 do
            for i=1, len do
                local typeKeyList   = table.keys(goodsTypsConfs)
                local goodsType     = checkint(typeKeyList[virtualData._r(1, #typeKeyList)])
                local goodsTypeConf = goodsTypsConfs[tostring(goodsType)] or {}
                local goodsTypeRef  = CommonUtils.GetGoodsTypeTrueRef(goodsTypeConf.ref)
                local goodsRefConf  = virtualData.getConf('goods', goodsTypeRef)
                local goodsKeyList  = table.keys(goodsRefConf)
                local goodsId       = checkint(goodsKeyList[virtualData._r(1, #goodsKeyList)])
                local goodsNum      = virtualData._r(1, 10)
                if goodsId > 0 then
                    table.insert(goodsList, {goodsId = goodsId, num = goodsNum, type = goodsType})
                end
            end
        --     loopCount = loopCount + 1
        -- end
        return goodsList
    end,


    -- 生成卡牌数据
    createCardData = function(cardId, playerId, level, breakLevel)
        local cardConfs  = virtualData.getConf('card', 'card')
        local cardIdList = validCardIdList
        local cardData   = {}
        local cardId     = cardId or cardIdList[virtualData._r(#cardIdList)]
        local skinList   = table.keys(validCardIdMap[tostring(cardId)])
        local cardConf   = cardConfs[tostring(cardId)] or {}
        local isSelf     = virtualData.playerData and playerId == virtualData.playerData.playerId or true
        local cardLevel  = math.max(1, level or virtualData._r(cardConf.maxLevel))
        cardData = {
            id                  = isSelf and virtualData.generateUuid() or nil,
            exp                 = virtualData._r(600000, 800000),
            level               = cardLevel,
            breakLevel          = breakLevel or virtualData._r(0, #checktable(cardConf.breakLevel) - 1),
            teamId              = 0,
            place               = {},
            skill               = {},
            playerId            = playerId or virtualData.playerData.playerId,
            cardId              = cardConf.id,
            -- cardName            = virtualData.createName(virtualData._r(6,12)),
            hp                  = cardConf.hp,
            vigour              = cardConf.vigour,
            attack              = cardConf.attack,
            defence             = cardConf.defence,
            attackRate          = cardConf.attackRate,
            critRate            = cardConf.critRate,
            critDamage          = cardConf.critDamage,
            defaultSkinId       = skinList[1], --table.values(checktable(cardConf.skin)['1'] or {})[1],
            businessSkill       = {},
            favorability        = 13,
            isArtifactUnlock    = virtualData._r(0,1), 
            favorabilityLevel   = virtualData._r(1,6),
            nextFeedLeftSeconds = 0,
            lunaTowerHp         = cardConf.hp,
        }
        for i,v in ipairs(cardConf.skill or {}) do
            cardData.skill[tostring(v)] = {level = virtualData._r(1,40)}
        end
        return cardData
    end,

    -- 根据卡牌配表id查找卡牌数据
    findCardByConfId = function(cardConfId)
        local findCardData = nil
        for _, cardData in pairs(virtualData.playerData.cards) do
            if checkint(cardData.cardId) == checkint(cardConfId) then
                findCardData = cardData
                break
            end
        end
        return findCardData
    end,


    -- 生成堕神数据
    createPetData = function(petId, playerId)
        local characterConfs  = virtualData.getConf('pet', 'petCharacter')
        local characterIdList = table.keys(characterConfs)
        local characterId     = checkint(characterIdList[virtualData._r(#characterIdList)])
        local characterConf   = characterConfs[tostring(characterId)] or {}

        local petConfs = virtualData.getConf('goods', 'pet')
        local levConfs = virtualData.getConf('pet', 'level')
        local breConfs = virtualData.getConf('pet', 'petBreak')
        local petConf  = petConfs[tostring(petId)] or {}
        local petData  = {
            playerId   = playerId,
            createTime = virtualData.createFormatTime(),
            id         = virtualData.generateUuid(),           -- 自增id
            petId      = petId,                                -- 堕神id
            level      = virtualData._r(table.nums(levConfs)), -- 堕神等级
            exp        = 0,                                    -- 堕神经验
            breakLevel = virtualData._r(table.nums(breConfs)), -- 堕神强化等级
            isProtect  = 0,                                    -- 是否被保护（0否，1是）
            character  = characterId,                          -- 堕神性格
        }
        local levConf = levConfs[tostring(petData.level)] or {}
        petData.exp   = checkint(levConf.totalExp)
        
        local petAttrTypeList    = table.values(PetP)
        local petAttrQualityList = table.values(PetPQuality)
        for i=1,4 do
            petData['extraAttrNum' .. i]     = virtualData._r(99)
            petData['extraAttrType' .. i]    = petAttrTypeList[virtualData._r(#petAttrTypeList)]
            petData['extraAttrQuality' .. i] = petAttrQualityList[virtualData._r(#petAttrQualityList)]
        end
        return petData
    end,


    -- 生成玩家装饰id
    createPlayerDressId_ = function(dressType)
        local dressConfs = virtualData.getConf('goods', 'achieveReward')
        local dressList  = {}
        for _, dressConf in pairs(dressConfs) do
            if checkint(dressConf.rewardType) == checkint(dressType) then
                table.insert(dressList, checkint(dressConf.id))
            end
        end
        return #dressList > 0 and table.remove(dressList, virtualData._r(#dressList)) or ''
    end,
    createAvatarId = function()
        return virtualData.createPlayerDressId_(CHANGE_TYPE.CHANGE_HEAD)
    end,
    createAvatarFrameId = function()
        return virtualData.createPlayerDressId_(CHANGE_TYPE.CHANGE_HEAD_FRAME)
    end,


    -- launch local server
    launchLocalServer = function()
        gameServer:launch()
        chatServer:launch()
    end
}

-------------------------------------------------
local _r  = virtualData._r
local j2t = virtualData.j2t
local t2t = virtualData.t2t


-- init userData
local foodConfs  = virtualData.getConf('goods', 'food')
local foodIdList = table.keys(foodConfs)
virtualData.userData = {
    userId            = 1,    -- 用户Id
    isGuest           = 0,    -- 是否游客, 0: 不是游客， 1：是游客
    lastLoginServerId = nil,  -- 最后一次登录的服务器ID
    sessionId         = 'this_is_debug_session_id',
    servers           = {},
}
for i=1,3 do
    local serverData = {
        id          = i,
        name        = 'Server'..i,
        playerId    = 10000 + i,
        playerName  = 'Debuger'..i,
        isRecommend = _r(0,1),
        foodIconId  = foodIdList[_r(#foodIdList)],
    }
    table.insert(virtualData.userData.servers, serverData)
end


-- init playerData
local serverTimezone   = 8*60*60
local serverTimeSecond = os.time()
local defaultPlayer    = virtualData.userData.servers[1]
local nowTimetable     = os.date("*t")
local zeroTimetable    = {
    year    = nowTimetable.year,
    month   = nowTimetable.month,
    day     = nowTimetable.day,
    hour    = 0,
    min     = 0,
    sec     = 0,
}
local tomorrowLeftSeconds = os.difftime(os.time(zeroTimetable)+86400, os.time(nowTimetable))


-------------------------------------------------
local playerTips  = {
    -- recoverCard: map, key为冰场ID, value为恢复的卡牌数
    recoverCard = {},
    -- finishFoods: map, key为灶台ID, value为灶台完成的菜品数
    finishFoods = {},
    championship = 1,  -- 武道会是否开启(1是 0否)
}

-------------------------------------------------
-- about quest
local worldAreaConfs          = virtualData.getConf('common', 'area')
local playerNewestAreaId      = checkint(checktable(worldAreaConfs[tostring(table.nums(worldAreaConfs)-1)]).id)
local currentAreaConf         = virtualData.getConf('common', 'area', playerNewestAreaId)
local currentCityId           = currentAreaConf.cities and checkint(currentAreaConf.cities[_r(#currentAreaConf.cities)]) or 0
local currentCityConf         = virtualData.getConf('quest', 'city', currentCityId)
local currentQuestMap         = currentCityConf.quests or {}
local normalQuestList         = currentQuestMap[tostring(QUEST_DIFF_NORMAL)] or {}
local hardQuestList           = currentQuestMap[tostring(QUEST_DIFF_HARD)] or {}
local playerNewestQuestId     = checkint(normalQuestList[_r(#normalQuestList)])
local playerNewestHardQuestId = checkint(hardQuestList[_r(#hardQuestList)])

-- set default home area
local retriveAreaKey   = string.format("AreaRetriveKey_%d", checkint(defaultPlayer.playerId))
local shareUserDefault = cc.UserDefault:getInstance()
shareUserDefault:setStringForKey(retriveAreaKey, playerNewestAreaId)
shareUserDefault:flush()

-- 全部关卡得分
local playerAllGrades = {}
for areaId = 1, playerNewestAreaId do
    local areaConf = worldAreaConfs[tostring(areaId)]
    for _, cityId in ipairs(areaConf.cities or {}) do
        if currentCityId >= cityId then
            -- grades:map, key为关卡ID, value为星级评价
            local gradesMap = { grades = {} }
            local cityConf  = virtualData.getConf('quest', 'city', currentCityId)
            for diff, questList in pairs(cityConf.quests or {}) do
                for _, questId in ipairs(questList) do
                    local isInclude = false
                    if checkint(diff) == QUEST_DIFF_NORMAL then
                        isInclude = playerNewestQuestId >= checkint(questId)
                    elseif checkint(diff) == QUEST_DIFF_HARD then
                        isInclude = playerNewestHardQuestId >= checkint(questId)
                    end
                    
                    -- local questConf = virtualData.getConf('quest', 'quest', questId)
                    -- if isInclude and checkint(questConf.repeatChallenge) == QuestRechallenge.QR_CAN then  -- can repeate
                    --     gradesMap.grades[tostring(questId)] = _r(table.nums(questConf.allClean or {}))
                    -- end
                    if isInclude then
                        gradesMap.grades[tostring(questId)] = _r(0,3)
                    end
                end
            end
            -- key为城市ID, value为关卡数据
            playerAllGrades[tostring(cityId)] = gradesMap
        end
    end
end

-- 最新主线任务
local questPlotConfs       = virtualData.getConf('quest', 'questPlot')
local questPlotConfList    = {}
local playerNewestPlotTask = {}
for _, questPlotConf in pairs(questPlotConfs) do
    if checkint(questPlotConf.areaId) == playerNewestAreaId then
        -- if checkint(questPlotConf.taskType) == 8 or checkint(questPlotConf.taskType) == 9 then
            table.insert(questPlotConfList, questPlotConf)
        -- end
    end
end
local newestPlotConf = questPlotConfList[_r(#questPlotConfList)]
if newestPlotConf then
    playerNewestPlotTask.taskId   = newestPlotConf.id
    playerNewestPlotTask.status   = 2  -- 完成状态 (1 未接受 2 未完成 3 已完成)
    playerNewestPlotTask.hasDrawn = 0  -- 领取状态 (1:已领取 0:未领取)
end
-- 最新支线任务
local playerBranchList = {}
local questBranchConfs = virtualData.getConf('quest', 'branch')
for branchId, questBranchConf in pairs(questBranchConfs) do
    playerBranchList[tostring(branchId)] = {
        status   = _r(1,3),  -- 完成状态 (1 未接受 2 未完成 3 已完成)
        hasDrawn = _r(0,1),  -- 领取状态 (1:已领取 0:未领取)
    }
end


-- 主线剧情
local playerQuestStory = {}

-------------------------------------------------
-- cooking style
local cookingRecipeMap    = {}
local cookingRecipeConfs  = virtualData.getConf('cooking', 'recipe')
for k, recipeConf in pairs(cookingRecipeConfs) do
    local cookingStyleId = checkint(recipeConf.cookingStyleId)
    cookingRecipeMap[tostring(cookingStyleId)] = cookingRecipeMap[tostring(cookingStyleId)] or {}
    table.insert(cookingRecipeMap[tostring(cookingStyleId)], recipeConf)
end

local cookingStyleConfs   = virtualData.getConf('cooking', 'style')
local cookingStyleIdList = {}
for k,v in pairs(cookingStyleConfs) do
    if #checktable(v.initialRecipe) > 0 then
        table.insert(cookingStyleIdList, k)
    end
end

local isAllCookingRecipes = true
local playerCookingStyles = {}
for i=1, (isAllCookingRecipes and #cookingStyleIdList or 1) do
    local cookingStyleId = checkint(table.remove(cookingStyleIdList, _r(#cookingStyleIdList)))
    if checkint(cookingStyleId) > 0 then
        local cookingRecipeList    = cookingRecipeMap[tostring(cookingStyleId)]
        local playerCookingRecipes = {}
        playerCookingStyles[tostring(cookingStyleId)] = playerCookingRecipes

        for j=1, (isAllCookingRecipes and #cookingRecipeList or 3) do
            local cookingRecipeConf = table.remove(cookingRecipeList, _r(#cookingRecipeList))
            if cookingRecipeConf then
                local playerRecipeData = {
                    recipeId       = checkint(cookingRecipeConf.id),             -- 菜谱id
                    cookingStyleId = checkint(cookingRecipeConf.cookingStyleId), -- 菜谱风格
                    taste          = _r(checkint(cookingRecipeConf.taste)),      -- 口味
                    museFeel       = _r(checkint(cookingRecipeConf.museFeel)),   -- 口感
                    fragrance      = _r(checkint(cookingRecipeConf.fragrance)),  -- 香味
                    exterior       = _r(checkint(cookingRecipeConf.exterior)),   -- 外观
                    growthTotal    = 100,                                          -- 成长总值
                    gradeId        = _r(1,4),                                          -- 成长评级id
                    seasoning      = '',                                         -- 用过的调料，逗号分隔
                    like           = _r(0,1),                                    -- 是否喜爱（1喜爱 0不喜爱）
                }
                table.insert(playerCookingRecipes, playerRecipeData)
            end
        end
    end
end


-------------------------------------------------
-- talent skill
local playerSkill      = {}
local playerAllSkill   = {}
local talentSkillNames = {'talentAssist', 'talentControl', 'talentDamage'}
for i, talentSkillName in ipairs(talentSkillNames) do
    local skillMap = {}
    for k, talentSkillConf in pairs(virtualData.getConf('player', talentSkillName)) do
        local skills = checktable(talentSkillConf.skill)
        skillMap[k] = checkint(skills[#skills])
    end
    for k, talentSkillConf in pairs(virtualData.getConf('player', talentSkillName)) do
        skillMap[tostring(talentSkillConf.coverTalent)] = nil
    end
    for k, skillId in pairs(skillMap) do
        table.insert(playerAllSkill, skillId)
    end
end

-------------------------------------------------
-- player cards
local playerCards     = {}
local playerCardSkins = {}
local cardConfs       = virtualData.getConf('card', 'card')
-- local initCards       = {200001,200009,200011,200013,200023,200012,200017}--, 200200}
-- local initCards       = {200001,200009,200011,200013,200023,200012,200017, 200004,200037,200039,200048,200058,200074,200079,200153, 200199,200200}
local initCards       = validCardIdList
for i, cardId in ipairs(initCards) do
    -- if _r(100) > 30 then
        local cardData = virtualData.createCardData(cardId, defaultPlayer.playerId)
        playerCards[tostring(cardData.id)] = cardData

        local cardConf = cardConfs[tostring(cardId)] or {}
        for skinId, _ in pairs(validCardIdMap[tostring(cardId)]) do
            table.insert(playerCardSkins, skinId)
        end
    -- end
end

-- default playerCard
local allCardUuids        = table.keys(playerCards)
local playerDefaultCardId = allCardUuids[_r(#allCardUuids)] or CardUtils.DEFAULT_CARD_ID

for cardUuid, cardData in pairs(playerCards) do
    if cardData.cardId == 200153 then
        cardData.defaultSkinId = 251533
    -- if cardData.cardId == 200004 then
    --     cardData.defaultSkinId = 250043

        playerDefaultCardId = cardUuid
        break
    end
end


local playerAllTeams = {}
for i = 1, 1 do
    local teamData = {
        teamId = i,
        cards  = {}
    }
    for j=1, 5 do
        local cardUuid = checkint(table.remove(allCardUuids, _r(#allCardUuids)))
        if cardUuid > 0 then
            table.insert(teamData.cards, {id = tostring(cardUuid)})
        end
    end
    if #teamData.cards > 0 then
        teamData.captainId = teamData.cards[1].id
    end
    playerAllTeams[i] = teamData
end

-------------------------------------------------
-- 餐厅职位： 键为职位Id,值为卡牌自增Id
local playerEmployee = {}
local cardsUuidList  = table.keys(playerCards)
for i = 1, 7 do  -- 1：主管、2：主厨、3：副厨、4-7：4个服务员
    local cardUuid = table.remove(cardsUuidList, _r(#cardsUuidList))
    playerEmployee[tostring(i)] = cardUuid
end


-------------------------------------------------
-- 背包数据 list
-- { goodsId: int, amount: int, IsNew: 是否新的(1是 0否) }
local playerBackpack = {}
for typeId, typeConf in pairs(goodsTypsConfs) do
    local goodsTypeRef = CommonUtils.GetGoodsTypeTrueRef(typeConf.ref)
    local goodsRefConf = virtualData.getConf('goods', goodsTypeRef)
    for goodsId, goodsConf in pairs(goodsRefConf) do
        playerBackpack[tostring(goodsConf.id)] = _r(99)
    end
end

for _, currencyId in ipairs(currencyIdList) do
    playerBackpack[tostring(currencyId)] = _r(999999)
end

local avatarConfs = virtualData.getConf('restaurant', 'avatar')
for _,v in pairs(avatarConfs) do
    local type = checkint(v.mainType)
    if type == 3 or type == 5 or type == 6 then
        playerBackpack[tostring(v.id)] = 1
    else
        playerBackpack[tostring(v.id)] = _r(9)
    end
end

-- init avatar
local avatarInitConfs = virtualData.getConf('restaurant', 'avatarInit')
for i,v in ipairs(avatarInitConfs) do
    playerBackpack[tostring(v.goodsId)] = checkint(playerBackpack[tostring(v.goodsId)]) + 1
end


-------------------------------------------------
-- 堕神数据
local petConfs   = virtualData.getConf('goods', 'pet')
local playerPets = {}
for _, petConf in pairs(petConfs) do
    for i=1,2 do
        local petId   = checkint(petConf.id)
        local petData = virtualData.createPetData(petId)
        playerPets[tostring(petData.id)] = petData
    end
end

local playerMonster       = {}
local collectMonsterConfs = virtualData.getConf('collention', 'monster')
for monsterId, collectMonsterConf in pairs(collectMonsterConfs) do
    playerMonster[tostring(monsterId)] = 3--_r(1,3) -- 1：未知，2：解锁，3：获得
end


-------------------------------------------------
-- 好友列表
local playerFriendList     = {}
local houseLevelConfs      = virtualData.getConf('house', 'levelUp')
local restaurantLevelConfs = virtualData.getConf('restaurant', 'levelUp')
local maxRestaurantLevel   = table.nums(restaurantLevelConfs)
local maxHouseLevel        = table.nums(houseLevelConfs)
for i=1, _r(3,6) do
    local loginTime  = os.time() - virtualData.createSecond('d:100:?,h:24:?,s:60:?')
    local friendData = {
        friendId             = virtualData.createPlayerId(),            -- 玩家ID
        name                 = virtualData.createName(_r(8, 16)),       -- 玩家名字
        level                = _r(100),                                 -- 玩家等级
        avatar               = virtualData.createAvatarId(),            -- 玩家头像
        avatarFrame          = virtualData.createAvatarFrameId(),       -- 玩家头像
        playerSign           = virtualData.createName(_r(0, 100)),      -- 玩家签名
        newFriendMessage     = _r(0,1),                                 -- 是否有新私信 1:有 0:无
        isOnline             = _r(0, 1),                                -- 是否在线 1:在线 0:不在线
        lastLoginTime        = virtualData.createFormatTime(loginTime), -- 最后一次登录时间
        restaurantBug        = _r(1,3),                                 -- 1:没虫子 2:有虫子, 没求助 3:求助
        restaurantQuestEvent = _r(1,3),                                 -- 1:没霸王餐 2:求助 3:正在打霸王餐
        closePoint           = _r(990),                                 -- 亲密度
        restaurantLevel      = _r(maxRestaurantLevel),                  -- 餐厅等级
        houseLevel           = _r(maxHouseLevel),                       -- 猫屋等级
        lastExitTime         = virtualData.createSecond('d:10:?,h:24:?,s:60:?'),
    }
    playerFriendList[i] = friendData
end


-------------------------------------------------
-- 爱心便当
local playerLeveBento = {
    ['1'] = {
        startTime  = '12:00',
        endTime    = '14:00',
        name       = '午餐',
        goodsId    = checktable(virtualData.createGoodsList(1)[1]).goodsId,
        goodsNum   = _r(9),
        isReceived = 0,
    },
    ['2'] = {
        startTime  = '18:00',
        endTime    = '20:00',
        name       = '晚餐',
        goodsId    = checktable(virtualData.createGoodsList(1)[1]).goodsId,
        goodsNum   = _r(9),
        isReceived = 0,
    },
    ['3'] = {
        startTime  = '21:00',
        endTime    = '23:00',
        name       = '夜宵',
        goodsId    = checktable(virtualData.createGoodsList(1)[1]).goodsId,
        goodsNum   = _r(9),
        isReceived = 0,
    },
}

-------------------------------------------------
-- player union

local unionPartySizeConfs = virtualData.getConf('union', 'partySize')
local playerUnion = {
    id            = _r(999),                              -- 工会id
    level         = 1,                                    -- 工会等级
    name          = virtualData.createName(_r(6, 12)),    -- 工会名字
    partyLevel    = _r(table.nums(unionPartySizeConfs)),  -- 派对等级
    partyBaseTime = serverTimeSecond + 8,              -- 派对起始时间
    partyBaseTime = 0,  -- close party
}

local unionPartyTimeConfs = virtualData.getConf('union', 'partyTimeLine')
for i = 1, UNION_PARTY_STEPS.OPENING - 1 + 1 do
    local unionPartyTimeConf  = unionPartyTimeConfs[tostring(i)] or {}
    local unionPartyBaseTime  = playerUnion.partyBaseTime
    playerUnion.partyBaseTime = unionPartyBaseTime - checkint(unionPartyTimeConf.seconds)
end


-------------------------------------------------
-- player guide
local playerGuide    = {}
local guideStepConfs = virtualData.getConf('guide', 'step')
for _, moduleId in pairs(GUIDE_MODULES) do
    local guideStepConf = guideStepConfs[tostring(moduleId)] or {}
    local stepKeyList   = table.keys(guideStepConf)
    table.sort(stepKeyList, function(a, b) return checkint(a) < checkint(b) end)
    playerGuide[tostring(moduleId)] = checkint(stepKeyList[#stepKeyList]) + 1
end

-------------------------------------------------
-- init player data
virtualData.playerData = {
    playerId                         = defaultPlayer.playerId,  -- 玩家ID
    playerName                       = defaultPlayer.playerName,-- 玩家角色名
    playerSign                       = nil,                     -- 玩家签名
    level                            = checkint(SUBPACKAGE_LEVEL) > 0 and SUBPACKAGE_LEVEL or 99,       -- 玩家等级
    mainExp                          = 0,                       -- 玩家经验
    nextHpSeconds                    = 0,                       -- 下点体力恢复时间
    hpRecoverSeconds                 = 10,                      -- 一点体力恢复时间为 恒定值
    hp                               = 100,                     -- 玩家体力值
    gold                             = 987654321,               -- 玩家金币数
    diamond                          = 123456,                  -- 玩家幻晶石数
    tip                              = 11000,                   -- 小费币
    medal                            = 12000,                   -- 竞技场勋章币
    kofPoint                         = 13000,                   -- kof竞技场代币
    unionPoint                       = 14000,                   -- 工会币
    petCoin                          = 0,                       -- 堕神币
    avatar                           = virtualData.createAvatarId(),
    avatarFrame                      = virtualData.createAvatarFrameId(),
    hasCreateRole                    = 1,                       -- 是否已经创建角色？0: 未创角， 1：已创角
    openCodeModule                   = 1,                       -- 是否开启验证码功能
    tcp                              = string.fmt('%1:%2', Platform.TCPHost, Platform.TCPPort),             -- 长连接IP地址:端口
    chatRoomTcp                      = string.fmt('%1:%2', Platform.ChatTCPHost, Platform.ChatTCPPort),     -- 聊天长连接IP地址:端口
    battleCardTcp                    = string.fmt('%1:%2', Platform.TTGameTCPHost, Platform.TTGameTCPPort), -- 打牌长连接IP地址:端口
    serverTime                       = serverTimeSecond,        -- 服务器时间戳（有时区）
    serverTimeOffset                 = serverTimezone,          -- 服务器时区秒数
    tomorrowLeftSeconds              = tomorrowLeftSeconds,     -- 距离明天还剩多少秒
    newestAreaId                     = playerNewestAreaId,      -- 最新区域ID
    newestQuestId                    = playerNewestQuestId,     -- 普通关卡ID
    newestHardQuestId                = playerNewestHardQuestId, -- 困难关卡ID
    questStory                       = playerQuestStory,        -- 主线剧情
    newestInsaneQuestId              = 0,                       -- 史诗关卡ID
    restaurantLevel                  = 29,                      -- 餐厅等级
    maxBuyGoldTimes                  = 10,                      -- 购买金币最大次数
    maxBuyHpTimes                    = 10,                      -- 购买体力最大次数
    buyGoldRestTimes                 = 10,                      -- 购买金币剩余次数
    buyHpRestTimes                   = 10,                      -- 购买体力剩余次数
    cookingPoint                     = 98765,                   -- 料理点
    popularity                       = 0,                       -- 知名度
    pets                             = playerPets,              -- 堕神
    guide                            = playerGuide,             -- 引导
    tips                             = playerTips,              -- 小红点显示数据
    allGrades                        = playerAllGrades,         -- 全部关卡星级
    branchList                       = playerBranchList,        -- 全部支线进度
    newestPlotTask                   = playerNewestPlotTask,    -- 最新主线任务
    cards                            = playerCards,             -- 玩家所拥有的卡牌列表和数量
    cardSkins                        = playerCardSkins,         -- 玩家所拥有的卡牌皮肤列表
    backpack                         = playerBackpack,          -- 玩家所拥有的道具ID列表和数量
    cookingStyles                    = playerCookingStyles,     -- 烹饪风格
    allTeams                         = playerAllTeams,          -- 编队阵容
    skill                            = playerSkill,             -- 选中的主角技
    allSkill                         = playerAllSkill,          -- 所有的主角技
    unlockTeamNeed                   = {diamond={}, level={}},  -- 解锁编队需求
    clientData                       = nil,                     -- 客户端数据
    employee                         = playerEmployee,          -- 餐厅职位： 键为职位Id, 值为卡牌自增Id
    defaultCardId                    = playerDefaultCardId,     -- 看板娘uuid
    friendList                       = playerFriendList,        -- 好友列表
    monster                          = playerMonster,           -- 收集堕神
    firstPay                         = 1,                       -- 首冲, 1: 未充值 2: 已充值 未领取 3: 已领取）
    levelChest                       = 0,                       -- 等级礼包是否开启
    loveBentoConf                    = playerLeveBento,         -- 爱心便当
    newbieTaskRemainTime             = 0,                       -- 新手七天
    restaurantCleaningLeftTimes      = _r(5),                   -- 餐厅帮好友打扫虫子剩余次数
    restaurantEventHelpLeftTimes     = _r(5),                   -- 餐厅帮好友打霸王餐剩余次数
    restaurantEventNeedHelpLeftTimes = _r(5),                   -- 餐厅需要好友打霸王餐剩余次数
    nextAirshipArrivalLeftSeconds    = _r(99),                  -- 空艇到达剩余时间
    triggerChest                     = {},                      -- 限时特惠礼包
    activityAd                       = {},                      -- 活动打脸
    isOpenedAnniversaryPV            = 0,                       -- 是否开启周年庆（0：未开启，1：开启）
    isOpenedAnniversary2019PV        = 0,                       -- 是否开启2019周年庆（0：未开启，1：开启）
    isOpenedAnniversary2020PV        = 1,                       -- 是否开启2020周年庆（0：未开启，1：开启）
    union                            = playerUnion,             -- 工会数据
    battleCardPoint                  = 13579,                   -- 打牌货币
    championshipPoint                = 24680,                   -- 武道会货币
    openLive2D                       = 1,                       -- live2d 开关（1：打开）
    shareData                        = {shareNum = 0, rewards = virtualData.createGoodsList(1)},
    --                               = 水吧
    barLevel                         = _r(9),                   -- 水吧等级
    barPoint                         = 345678,                  -- 水吧货币
    barPopularity                    = 998877,                  -- 水吧知名度
    houseLevel                       = _r(9),                   -- 猫屋等级
    foodCompareResultAck             = 1,                       -- 是否打脸新飨灵比拼结果（0：未打过，1：打过了）
    cardFragmentM                    = 987,                     -- M卡牌碎片数量
    cardFragmentSP                   = 789,                     -- SP卡牌碎片数量
}
local playerLevelConfs = virtualData.getConf('player', 'level')
virtualData.playerData.mainExp = checkint(checktable(playerLevelConfs[tostring(virtualData.playerData.level + 1)]).totalExp) - 1

-- auto draw firstPay reward
if not true then
    virtualData.playerData.firstPay = 2
end

-- auto newbie 15 day
if not true then
    virtualData.playerData.newbie15Day      = 1  -- 新手15日活动, 1:显示 0:不显示
    virtualData.playerData.tips.newbie15Day = 1
end

-- auto draw monthly login
if not true then
    virtualData.playerData.tips.monthlyLogin = 1
end

-- show activityAd
if not true then
    for i=1,13 do
        local activityAdData = {
            activityId = virtualData.generateUuid(),
            type       = _r(99),
            image      = {
                [i18n.getLang()] = 'http://fondant-activity.oss-cn-hangzhou.aliyuncs.com/activity/f236291a3a155643c436b0580de8e83a.jpg'
            },
            name       = {
                [i18n.getLang()] = virtualData.createName(_r(8,16))
            },
            fromTime   = os.time() - _r(9)*86400,
            toTime     = os.time() + _r(9)*86400,
        }
        table.insert(virtualData.playerData.activityAd, activityAdData)
    end
end

-- open level chest
if  true then
    virtualData.playerData.levelChest      = 1
    virtualData.playerData.tips.levelChest = _r(99)  -- 等级礼包限时折扣倒计时(秒)
end

-- newbie task reward
if  true then
    virtualData.playerData.newbieTaskRemainTime = _r(99)
end

-- limit chest reward
if  true then
    for i=1,2 do
        local chestData = {
            iconId              = i,                                                     -- icon ID
            uiTplId             = _r(1,2),                                               -- 界面模板ID
            discountLeftSeconds = _r(99),                                                -- 折扣剩余秒数
            productId           = virtualData.generateUuid(),                            -- 商品ID
            channelProductId    = virtualData.createName(9),                             -- 渠道商品ID
            name                = i % 2 == 0 and virtualData.createName(_r(4,8)) or nil, -- 商品名称
            rewards             = virtualData.createGoodsList(_r(4,8)),                  -- 奖励
            price               = _r(99),                                                -- 价格
            discount            = _r(100),                                               -- 折扣 1~100
            discountPrice       = _r(99),                                                -- 折扣价格
        }
        table.insert(virtualData.playerData.triggerChest, chestData)
    end
end


local upgradeUnlockModuleKey = string.fmt('UPGRADE_LEVEL_UNLOCK_MODULE_%1', virtualData.playerData.playerId)
cc.UserDefault:getInstance():setStringForKey(upgradeUnlockModuleKey, '')
cc.UserDefault:getInstance():setBoolForKey('SubpackageRes_' .. tostring(FTUtils:getAppVersion()), false)

-- virtualData.playerData.level   = 16
-- local playerLevelConfs         = virtualData.getConf('player', 'level')
-- local playerLevelConf          = playerLevelConfs[tostring(virtualData.playerData.level + 1)] or {}
-- virtualData.playerData.mainExp = checkint(playerLevelConf.totalExp) - 1


-- debug guide
local guideLevel = 0
if guideLevel > 0 then
    GuideUtils.GetDirector()
    virtualData.INIT_CARDS = {200009, 200011, 200013, 200023}  -- 可丽饼, 三明治, 冰糖葫芦, 牛奶

    local playerLevelConfs = virtualData.getConf('player', 'level')
    local getLevelTotalExp = function(playerLevel)
        local playerLevelConf = playerLevelConfs[tostring(playerLevel)] or {}
        return checkint(playerLevelConf.totalExp)
    end

    local upgradeUnlockModuleKey = string.fmt('UPGRADE_LEVEL_UNLOCK_MODULE_%1', virtualData.playerData.playerId)
    cc.UserDefault:getInstance():setStringForKey(upgradeUnlockModuleKey, '')

    local homeExtraPanelOpenKey = string.fmt('%1_ModulePanelIsOpen', virtualData.playerData.playerId)
    cc.UserDefault:getInstance():setBoolForKey(homeExtraPanelOpenKey, false)
    cc.UserDefault:getInstance():flush()

    -- 餐厅引导:1
    if guideLevel >= 1 then
        virtualData.playerData.mainExp             = 0
        virtualData.playerData.level               = 1
        virtualData.playerData.guide               = {}
        virtualData.playerData.cards               = {}
        virtualData.playerData.backpack            = {}
        virtualData.playerData.allTeams            = {}
        virtualData.playerData.employee            = {}
        virtualData.playerData.friendList          = {}
        virtualData.playerData.branchList          = {}
        virtualData.playerData.newestPlotTask      = {}
        virtualData.playerData.cookingStyles       = {}
        virtualData.playerData.defaultCardId       = nil
        virtualData.playerData.restaurantLevel     = 1
        virtualData.playerData.newestAreaId        = 1
        virtualData.playerData.newestQuestId       = 1
        virtualData.playerData.newestHardQuestId   = 0
        virtualData.playerData.newestInsaneQuestId = 0
        virtualData.playerData.isFirstPassed       =  true

        -- backpack: food material
        local foodMaterialConfs = virtualData.getConf('goods', 'foodMaterial')
        for _, foodMaterialConf in pairs(foodMaterialConfs) do
            virtualData.playerData.backpack[tostring(foodMaterialConf.id)] = _r(99)
        end

        -- backpack: pet egg
        local petEggConfs = virtualData.getConf('goods', 'petEgg')
        for _, petEggConf in pairs(petEggConfs) do
            virtualData.playerData.backpack[tostring(petEggConf.id)] = _r(99)
        end

        -- pets
        for petId, petData in pairs(virtualData.playerData.pets) do
            if petData.breakLevel > 5 then
                virtualData.playerData.pets[petId] = nil
            end
        end

        -- cards
        for _, cardId in ipairs(virtualData.INIT_CARDS) do
            local cardData  = virtualData.createCardData(cardId, virtualData.playerData.playerId, 1, 0)
            virtualData.playerData.cards[tostring(cardData.id)] = cardData
        end

        -- team
        local teamData = { teamId = 1, cards  = {
            {id = checktable(virtualData.findCardByConfId(200023)).id}, -- 牛奶 200023
            {id = checktable(virtualData.findCardByConfId(200009)).id}, -- 可丽饼 200009
            {},
            {},
            {}
        } }
        if #teamData.cards > 0 then
            teamData.captainId = teamData.cards[1].id
        end
        virtualData.playerData.allTeams[1] = teamData

        -- default user define
        local retriveAreaKey   = string.format("AreaRetriveKey_%d", checkint(virtualData.playerData.playerId))
        local shareUserDefault = cc.UserDefault:getInstance()
        shareUserDefault:setStringForKey(retriveAreaKey, virtualData.playerData.newestAreaId)
        shareUserDefault:flush()
    end


    -- 抽卡引导:2
    if guideLevel >= 2 then
        virtualData.playerData.guide['1']    = playerGuide['1']  -- 餐厅
        virtualData.playerData.cookingStyles = playerCookingStyles

        -- virtualData.playerData.employee["2"] = virtualData.findCardByConfId(200013).id
        -- virtualData.playerData.employee["4"] = virtualData.findCardByConfId(200011).id
    end
    
    
    -- 编队引导:3
    if guideLevel >= 3 then
        virtualData.playerData.guide['2'] = playerGuide['2']  -- 抽卡

        local cardIdList = clone(validCardIdList)
        for i = 1, 2 do
            local cardId   = checkint(table.remove(cardIdList, _r(#cardIdList)))
            local cardData = virtualData.createCardData(cardId, defaultPlayer.playerId)
            virtualData.playerData.cards[tostring(cardData.id)] = cardData
        end
    end


    -- 主线引导:100,101
    if guideLevel >= 4 then
        virtualData.playerData.guide['3'] = playerGuide['3']  -- 编队

        virtualData.playerData.level         = CONDITION_LEVELS.FINISH_STORY_TASK - 1
        virtualData.playerData.mainExp       = getLevelTotalExp(virtualData.playerData.level + 1) - 1
        virtualData.playerData.newestQuestId = 2
    end


    -- 研发引导:102
    if guideLevel >= 5 then
        virtualData.playerData.guide['100'] = playerGuide['100']
        virtualData.playerData.guide['101'] = playerGuide['101']

        virtualData.playerData.level         = CONDITION_LEVELS.DISCOVER_DISH - 1
        virtualData.playerData.mainExp       = getLevelTotalExp(virtualData.playerData.level + 1) - 1
        virtualData.playerData.newestQuestId = 3

        virtualData.playerData.allGrades['1'] = {
            grades = {
                ['1'] = 3,
                ['2'] = 3,
            }
        }
    end


    -- 天赋引导:1000
    if guideLevel >= 6 then
        virtualData.playerData.guide['102'] = playerGuide['102']

        virtualData.playerData.level   = CommonUtils.GetModuleOpenLevel(RemindTag.TALENT)
        virtualData.playerData.mainExp = getLevelTotalExp(virtualData.playerData.level + 1) - 1
    end


    -- 地图引导:1001
    if guideLevel >= 7 then
        virtualData.playerData.level   = CommonUtils.GetModuleOpenLevel(RemindTag.WORLDMAP)
        virtualData.playerData.mainExp = getLevelTotalExp(virtualData.playerData.level + 1) - 1
    end


    -- 堕神引导:103
    if guideLevel >= 8 then
        virtualData.playerData.level   = CONDITION_LEVELS.PET - 1
        virtualData.playerData.mainExp = getLevelTotalExp(virtualData.playerData.level + 1) - 1
    end
end


-- local checkinJson                    = io.readfile(cc.FileUtils:getInstance():fullPathForFilename('checkin'))
-- virtualData.playerData               = json.decode(checkinJson)
-- virtualData.playerData.tcp           = string.fmt('%1:%2', Platform.TCPHost, Platform.TCPPort)             -- 长连接IP地址:端口
-- virtualData.playerData.chatRoomTcp   = string.fmt('%1:%2', Platform.ChatTCPHost, Platform.ChatTCPPort)     -- 聊天长连接IP地址:端口
-- virtualData.playerData.battleCardTcp = string.fmt('%1:%2', Platform.TTGameTCPHost, Platform.TTGameTCPPort) -- 打牌长连接IP地址:端口


-------------------------------------------------
-- merger sub parser
for _, name in ipairs(subVirtualList) do
    local path = string.format('interfaces/virtual/%s.lua', name)
    if utils.isExistent(path) then
        require(string.format('interfaces.virtual.%s', name))
    end
end
