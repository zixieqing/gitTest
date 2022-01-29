--[[
 * author : kaishiqi
 * descpt : 3x3打牌游戏 管理器
]]
local BaseManager        = require('Frame.Manager.ManagerBase')
local TTGameConfigParser = require('Game.Datas.Parser.BattleCardConfigParser')
---@class TripleTriadGameManager:BaseManager
local TripleTriadGameManager = class('TripleTriadGameManager', BaseManager)

-------------------------------------------------
-- const define

TTGAME_DEFINE = {
    CONF_TYPE       = TTGameConfigParser.TYPE, -- 配表类型
    CURRENCY_ID     = 900028,                  -- 专用货币id
    EXCHANGE_ID     = 890044,                  -- 转换兑换id
    ROOM_ID_LEN     = 9,                       -- 房间号最大长度
    DECK_CARD_NUM   = 5,                       -- 卡组的卡牌数量
    DECK_FREE_NUM   = 1,                       -- 卡组自由卡数量
    DECK_MAXIMUM    = 4,                       -- 卡组最大数量
    STAR_MAXIMUM    = 6,                       -- 卡牌最高星级
    FILTER_TYPE_ALL = 0,                       -- 过滤类型全部
    ROUND_SECONDS   = 40,                      -- 每回合的秒数
    DESK_ELEM_ROWS  = 3,                       -- 桌面元素行数
    DESK_ELEM_COLS  = 3,                       -- 桌面元素列数
    BATTLE_TYPE     = {
        NONE        = 0, -- 默认
        PVE         = 1, -- pve
        PVP         = 2, -- pvp
        FRIEND      = 3, -- 好友
        ANNIVERSARY = 4, -- 周年庆
    },
    RESULT_TYPE     = {
        NONE = 0, -- 未知
        WIN  = 1, -- 胜利
        DRAW = 2, -- 平局
        FAIL = 3, -- 失败
    },
    STAR_LEVEL_LIST = {
        'I', 'II', 'III', 'IV', 'V', 'VI'
    }
}


-------------------------------------------------
-- const define

TTGameUtils = nil
TTGameUtils = {

    ---@see TTGameConfigParser.TYPE
    GetConf = function(confType)
        return CommonUtils.GetConfigAllMess(confType, TTGameConfigParser.SUB) or {}
    end,

    GetConfAt = function(confType, confId)
        return TTGameUtils.GetConf(confType)[tostring(confId)] or {}
    end,

    -- 获取 总表id 范围内的 排期id列表
    GetScheduleIdList = function(summaryId)
        local scheduleIdList    = {}
        local isFindSchedule    = false
        local scheduleConfFile  = TTGameUtils.GetConf(TTGAME_DEFINE.CONF_TYPE.SCHEDULE)
        local activityConfInfo  = TTGameUtils.GetConfAt(TTGAME_DEFINE.CONF_TYPE.ACTIVITY, summaryId)
        local activityBeganDate = tostring(activityConfInfo['start'])
        local activityEndedDate = tostring(activityConfInfo['end'])

        for i = 1, table.nums(scheduleConfFile) do
            local scheduleConf = scheduleConfFile[tostring(i)] or {}
            local scheduleDate = tostring(scheduleConf.date)
            -- check began
            if scheduleDate == activityBeganDate then
                isFindSchedule = true
            end
            -- append id
            if isFindSchedule then
                table.insert(scheduleIdList, scheduleConf.id)
            end
            -- check ended
            if scheduleDate == activityEndedDate then
                break
            end
        end
        return scheduleIdList
    end,

    -- 获取 规则图标节点
    GetRuleIconNode = function(ruleId)
        local ruleConfInfo = TTGameUtils.GetConfAt(TTGAME_DEFINE.CONF_TYPE.RULE_DEFINE, ruleId)
        local ruleIconPath = _res(string.fmt('ui/ttgame/arts/ruleIcon/cardgame_rules_ico_%1.png', tostring(ruleConfInfo.id)))
        return display.newImageView(ruleIconPath, 0, 0)
    end,

    -- 获取 类别图标路径
    GetTypeIconPath = function(typeId)
        local typeConfInfo = TTGameUtils.GetConfAt(TTGAME_DEFINE.CONF_TYPE.CARD_CAMP, typeId)
        return _res(string.fmt('ui/ttgame/arts/typeIcon/cardgame_series_ico_%1.png', tostring(typeConfInfo.id)))
    end,
    -- 获取 类别图标节点
    GetTypeIconNode = function(typeId)
        return display.newImageView(TTGameUtils.GetTypeIconPath(typeId), 0, 0)
    end,

    -- 获取 卡牌立绘路径
    GetCardDrawPath = function(cardId)
        local cardConfInfo = TTGameUtils.GetConfAt(TTGAME_DEFINE.CONF_TYPE.CARD_DEFINE, cardId)
        return _res(string.fmt('arts/ttgame/card/cardgame_card_%1.png', tostring(cardConfInfo.id)))
    end,
    -- 获取 卡牌立绘节点
    GetCardDrawNode = function(cardId)
        return display.newImageView(TTGameUtils.GetCardDrawPath(cardId), 0, 0)
    end,
    
    -- 获取 NPC立绘节点
    GetNpcDrawNode = function(pveNpcId)
        local npcConfInfo = TTGameUtils.GetConfAt(TTGAME_DEFINE.CONF_TYPE.NPC_DEFINE, pveNpcId)
        local npcDrawName = CardUtils.GetCardDrawNameBySkinId(npcConfInfo.draw)
        local drawImgPath = _res(string.fmt('ui/ttgame/arts/pveNpc/cardgame_pve_npc_img_%1.jpg', tostring(npcDrawName)))
        return display.newImageView(drawImgPath, 0, 0)
    end,

    -- 获取 战斗卡牌节点 
    GetBattleCardNode = function(args)
        return require('Game.views.ttGame.TripleTriadGameBattleCardNode').new(args)
    end,

    -- 获取 卡牌等级文字
    GetCardLevelText = function(level)
        return tostring(TTGAME_DEFINE.STAR_LEVEL_LIST[level])
    end,

    -- 清空spine缓存
    CleanSpineCache = function(spnData)
        SpineCache(SpineCacheName.TTGAME):clearCache()
    end,

    -- 创建spine
    CreateSpine = function(spnData)
        local spinePath = spnData.path
        if not SpineCache(SpineCacheName.TTGAME):hasSpineCacheData(spinePath) then
            SpineCache(SpineCacheName.TTGAME):addCacheData(spinePath, spinePath, 1)
        end
        return SpineCache(SpineCacheName.TTGAME):createWithName(spinePath)
    end,

    -- 是否 sp卡牌
    IsSpCard = function(cardId)
        local cardConfInfo = TTGameUtils.GetConfAt(TTGAME_DEFINE.CONF_TYPE.CARD_DEFINE, cardId)
        return checkint(cardConfInfo.star) > 5
    end,
}


-------------------------------------------------
-- manager method

TripleTriadGameManager.DEFAULT_NAME = 'TripleTriadGameManager'
TripleTriadGameManager.instances_   = {}


function TripleTriadGameManager.GetInstance(instancesKey)
    instancesKey = instancesKey or TripleTriadGameManager.DEFAULT_NAME

    if not TripleTriadGameManager.instances_[instancesKey] then
        TripleTriadGameManager.instances_[instancesKey] = TripleTriadGameManager.new(instancesKey)
    end
    return TripleTriadGameManager.instances_[instancesKey]
end


function TripleTriadGameManager.Destroy(instancesKey)
    instancesKey = instancesKey or TripleTriadGameManager.DEFAULT_NAME

    if TripleTriadGameManager.instances_[instancesKey] then
        TripleTriadGameManager.instances_[instancesKey]:release()
        TripleTriadGameManager.instances_[instancesKey] = nil
    end
end


-------------------------------------------------
-- life cycle

function TripleTriadGameManager:ctor(instancesKey)
    self.super.ctor(self)

    if TripleTriadGameManager.instances_[instancesKey] then
        funLog(Logger.INFO, "注册相关的facade类型")
    else
        self:initial()
    end
end


function TripleTriadGameManager:initial()
    self:setHomeData()
end


function TripleTriadGameManager:release()
    self:socketDestroy()
end


-------------------------------------------------
-- public method

function TripleTriadGameManager:getLastBattleResult()
    return self.lastBattleResult_
end
function TripleTriadGameManager:setLastBattleResult(result)
    self.lastBattleResult_ = result or TTGAME_DEFINE.RESULT_TYPE.RESULT_TYPE
end


-- ttGameSocket
function TripleTriadGameManager:socketLaunch()
    if not self.ttGameSocket_ then
        self.ttGameSocket_ = app:AddManager('Frame.Manager.TTGameSocketManager')
        self.ttGameSocket_:connect(Platform.TTGameTCPHost, Platform.TTGameTCPPort)
    end
end
function TripleTriadGameManager:socketDestroy()
    if self.ttGameSocket_ then
        self.ttGameSocket_:release(true)
        self.ttGameSocket_ = nil
        app:RemoveManager('TTGameSocketManager')
    end
end
function TripleTriadGameManager:socketSendData(cmdId, data)
    if self.ttGameSocket_ then
        self.ttGameSocket_:sendData(cmdId, data)
    end
end


-- battleModel
function TripleTriadGameManager:getBattleModel()
    return self.battleModel_
end
function TripleTriadGameManager:setBattleModel(battleModel)
    self.battleModel_ = battleModel
end


-- home data
function TripleTriadGameManager:getHomeData()
    return self.homeData_ or {}
end
function TripleTriadGameManager:setHomeData(initData)
    self.homeData_ = initData or {}
    
    -- pre-settings
    self.homeData_.pvpLeftTimestamp = getServerTime() + checkint(self.homeData_.pvpLeftSeconds)
    self.homeData_.pveLeftTimestamp = getServerTime() + checkint(self.homeData_.pveLeftSeconds)
    self.homeData_.battleCardTotal  = table.nums(TTGameUtils.GetConf(TTGAME_DEFINE.CONF_TYPE.CARD_DEFINE))

    self.homeData_.collectAlbumMap = {}
    for _, albumId in ipairs(self.homeData_.collects or {}) do
        self.homeData_.collectAlbumMap[tostring(albumId)] = true
    end

    self.homeData_.battleCardMap = {}
    for _, cardId in ipairs(self.homeData_.battleCards or {}) do
        self.homeData_.battleCardMap[tostring(cardId)] = true
    end

    self.homeData_.pveNpcInfoMap = {}
    for _, npcData in ipairs(self.homeData_.npc or {}) do
        self.homeData_.pveNpcInfoMap[tostring(npcData.npcId)] = npcData
    end

    self:updateCurrentStarLimit_()
end


-- summaryId
function TripleTriadGameManager:getSummaryId()
    return checkint(self:getHomeData().summaryId)
end


-- scheduleId
function TripleTriadGameManager:getScheduleId()
    return checkint(self:getHomeData().scheduleId)
end


-- today rule
function TripleTriadGameManager:getTodayRuleList()
    local schduleConfInfo = TTGameUtils.GetConfAt(TTGAME_DEFINE.CONF_TYPE.SCHEDULE, self:getScheduleId())
    return schduleConfInfo.rules or {}
    -- return {3,4,5,7,8}  -- all init
    -- return {6,9,10,11,12}  -- all not init
end


-- pvp/pve opening
function TripleTriadGameManager:isOpeningPve()
    return checkint(self:getHomeData().pveStatus) == 2
end
function TripleTriadGameManager:isOpeningPvp()
    return checkint(self:getHomeData().pvpStatus) == 2
end


-- pvp/pve seconds 
function TripleTriadGameManager:getPveLeftSeconds()
    return self:getHomeData().pveLeftTimestamp - getServerTime()
end
function TripleTriadGameManager:getPvpLeftSeconds()
    return self:getHomeData().pvpLeftTimestamp - getServerTime()
end


-- about deck
function TripleTriadGameManager:getAllDeckMap()
    return self:getHomeData().deck or {}
end
function TripleTriadGameManager:getDeckCardsAt(deckId)
    local cardList = self:getAllDeckMap()[tostring(deckId)]
    return self:isEmptyDeckCards(cardList) and {} or cardList
end
function TripleTriadGameManager:setDeckCardsAt(deckId, cardList)
    self:getAllDeckMap()[tostring(deckId)] = not self:isEmptyDeckCards(cardList) and cardList or nil
end
function TripleTriadGameManager:isEmptyDeckAt(deckId)
    return self:isEmptyDeckCards(self:getDeckCardsAt(deckId))
end
function TripleTriadGameManager:isEmptyDeckCards(cardList)
    local deckCards = checktable(cardList)
    local isEmpty   = true
    for i, cardId in ipairs(deckCards) do
        if checkint(cardId) > 0 then
            isEmpty = false
            break
        end
    end
    return isEmpty
end


-- about album
function TripleTriadGameManager:getCollectAlbumList()
    return table.key(self:getHomeData().collectAlbumMap or {})
end
function TripleTriadGameManager:hasCollecAlbumId(albumId)
    return self:getHomeData().collectAlbumMap[tostring(albumId)] == true
end
function TripleTriadGameManager:addCollectAlbumId(albumId)
    self:getHomeData().collectAlbumMap[tostring(albumId)] = true
end


-- about card
function TripleTriadGameManager:getHasBattleCardNum()
    return table.nums(self:getHomeData().battleCardMap or {})
end
function TripleTriadGameManager:getBattleCardList()
    local battleCardList = table.keys(self:getHomeData().battleCardMap or {})
    table.sort(battleCardList, function(a, b) return checkint(a) < checkint(b) end)
    return battleCardList
end
function TripleTriadGameManager:hasBattleCardId(cardId)
    return self:getHomeData().battleCardMap[tostring(cardId)] == true
end
function TripleTriadGameManager:addBattleCardId(cardId)
    self:getHomeData().battleCardMap[tostring(cardId)] = true
    app:DispatchObservers(SGL.TTGAME_BATTLE_CARD_ADD)
    self:updateCurrentStarLimit_()
end


function TripleTriadGameManager:getBattleCardNum()
    return table.nums(self:getHomeData().battleCardMap or {})
end
function TripleTriadGameManager:getBattleCardTotal()
    return checkint(self.homeData_.battleCardTotal)
end


-- about starLimit
function TripleTriadGameManager:getCurrentStarLimit()
    return self.homeData_.unlockStarLimit
end
function TripleTriadGameManager:updateCurrentStarLimit_()
    local unlockStarLimit   = 1
    local hasBattleCardNum  = self:getBattleCardNum()
    local deckLimitConfFile = TTGameUtils.GetConf(TTGAME_DEFINE.CONF_TYPE.DECK_LIMIT)
    for i = table.nums(deckLimitConfFile), 1, -1 do
        local deckLimitConfInfo = deckLimitConfFile[tostring(i)] or {}
        if hasBattleCardNum >= checkint(deckLimitConfInfo.collectNum) then
            unlockStarLimit = checkint(deckLimitConfInfo.starLimit)
            break
        end
    end
    self.homeData_.unlockStarLimit = unlockStarLimit
end


-- about pveNpc
function TripleTriadGameManager:getPveNpcData(npcId)
    return checktable(self:getHomeData().pveNpcInfoMap[tostring(npcId)])
end


-- about rewards
function TripleTriadGameManager:getPvpTodayRewardList()
    local schduleConfInfo = TTGameUtils.GetConfAt(TTGAME_DEFINE.CONF_TYPE.SCHEDULE, self:getScheduleId())
    return schduleConfInfo.rewards or {}
end
function TripleTriadGameManager:getPveTodayRewardListAt(npcId)
    local pveNpcConfInfo = TTGameUtils.GetConfAt(TTGAME_DEFINE.CONF_TYPE.NPC_DEFINE, npcId)
    return pveNpcConfInfo.rewards or {}
end


function TripleTriadGameManager:getPvpTodayRewardTimes()
    return checkint(self:getHomeData().pvpLeftRewardTimes)
end
function TripleTriadGameManager:setPvpTodayRewardTimes(rewardTimes)
    self:getHomeData().pvpLeftRewardTimes = checkint(rewardTimes)
end


function TripleTriadGameManager:getPveTodayRewardTimesAt(npcId)
    return checkint(self:getPveNpcData(npcId).leftRewardTimes)
end
function TripleTriadGameManager:setPveTodayRewardTimesAt(npcId, rewardTimes)
    self:getPveNpcData(npcId).leftRewardTimes = checkint(rewardTimes)
end


-------------------------------------------------
-- private method


return TripleTriadGameManager
