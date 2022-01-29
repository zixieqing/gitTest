--[[
 * author : kaishiqi
 * descpt : local ttGame server
]]
local BaseServer   = require('interfaces.server.BaseServer')
local TTGameServer = class('TTGameServer', BaseServer)

TTGAME_DEFINE.ROUND_SECONDS = 300 -- debug use

local ENABLE_QUICK_BATTLE = not false
local ENABLE_INIT_RULE =  false


local EmptyDeskMapFunc = function()
    local deskMap = {}
    for row = 1, TTGAME_DEFINE.DESK_ELEM_ROWS do
        for col = 1, TTGAME_DEFINE.DESK_ELEM_ROWS do
            local idx = (row-1) * TTGAME_DEFINE.DESK_ELEM_ROWS + col
            deskMap[tostring(idx)] = {
                -- rowCount   = row,
                -- colCount   = col,
                positionId = idx,
            }
        end
    end
    return deskMap
end


local RandomOrderFunc = function(cardList)
    local cardOrder = {}
    for index, value in ipairs(cardList) do
        table.insert(cardOrder, index)
    end

    for i = 1, 10 do
        local orderIndex = virtualData._r(#cardOrder)
        local cardIndex  = table.remove(cardOrder, orderIndex)
        table.insert(cardOrder, cardIndex)
    end
    return cardOrder
end


local RandomCardListFunc = function()
    local randomIdList = {}
    local cardIdList   = table.keys(TTGameUtils.GetConf(TTGAME_DEFINE.CONF_TYPE.CARD_DEFINE))
    for i = 1, TTGAME_DEFINE.DECK_CARD_NUM do
        local cardId = table.remove(cardIdList, virtualData._r(#cardIdList))
        table.insert(randomIdList, cardId)
    end
    return randomIdList
end


function TTGameServer:ctor()
    self.super.ctor(self, 'TTGameServer', Platform.TTGameTCPPort)
end


function TTGameServer:onReceiveData_(clientKey, cmdId, data)
    self.super.onReceiveData_(self, clientKey, cmdId, data)

    -- 10999 网络握手
    if cmdId == NetCmd.TTGAME_NET_LINK then
        self:sendClientAt(clientKey, cmdId)


    -------------------------------------------------
    -- 10021 网络同步
    elseif cmdId == NetCmd.TTGAME_NET_SYNC then
        for i = 1, 2 do  -- debug use
            if not self:isBattleOver() then
                self:appendDeskCardAuto(true)
                self:switchBattleRound()
            end
        end
        self:sendClientAt(clientKey, cmdId, {data = {
            roomNo                  = virtualData.ttGameBattle_.roomNumber,                 -- 房间号
            --                      = opponent
            opponentUuid            = virtualData.ttGameBattle_.opponentUuid,               -- 对手唯一ID
            opponentName            = virtualData.ttGameBattle_.opponentName,               -- 对手名称
            opponentAvatar          = virtualData.ttGameBattle_.opponentAvatar,             -- 对手头像
            opponentAvatarFrame     = virtualData.ttGameBattle_.opponentFrame,              -- 对手头像框
            opponentBattleCards     = virtualData.ttGameBattle_.opponentCards,              -- 对手牌组卡牌列表
            opponentPlayBattleCards = virtualData.ttGameBattle_.opponentPlays,              -- 对手打出的牌组卡牌位置列表（从1开始）
            --                      = player
            myBattleCards           = virtualData.ttGameBattle_.playerCards,                -- 我的牌组卡牌列表
            myPlayBattleCards       = virtualData.ttGameBattle_.playerPlays,                -- 我打出的牌组卡牌位置列表（从1开始）
            --                      = round
            currentHandMemberUuid   = virtualData.ttGameBattle_.roundPlayerId,              -- 当前是谁出牌
            currentRoundLeftSeconds = virtualData.ttGameBattle_.roundTimestamp - os.time(), -- 当前回合剩余秒数
            map                     = virtualData.ttGameBattle_.deskDataMap,                -- 最新桌面数据
        }})
        self:updateBattleRound()

        -- 模拟报错
        -- self:sendClientAt(clientKey, cmdId, {data = {},
        --     errcode = -99,
        --     errmsg  = '',
        -- })


    -------------------------------------------------
    -- 10001 pvp进入
    elseif cmdId == NetCmd.TTGAME_PVE_ENTER then
        virtualData.ttGameBattleRoomId_ = virtualData.generateUuid()
        virtualData.ttGameBattleDeckId_ = data.deckId

        -- notice 10001 : enter pve
        self:sendClientAt(clientKey, cmdId, {data = {
            roomNo = virtualData.ttGameBattleRoomId_,
        }})

        local npcConfInfo = TTGameUtils.GetConfAt(TTGAME_DEFINE.CONF_TYPE.NPC_DEFINE, data.npcId)
        local npcCardList = checktable(npcConfInfo.deck[virtualData._r(#npcConfInfo.deck)])
        -- npcCardList = {391004, 391004, 391004, 391004, 391004} -- debug use : all same card
        self:startBattleCard(TTGAME_DEFINE.BATTLE_TYPE.PVE, {
            opponentUuid   = npcConfInfo.id,
            opponentName   = npcConfInfo.name,
            opponentAvatar = npcConfInfo.head,
            opponentFrame  = npcConfInfo.headFrame,
            opponentCards  = npcCardList,
        })

        
    -------------------------------------------------
    -- 10017 主动认输
    elseif cmdId == NetCmd.TTGAME_GAME_ABANDON then
        self:stopRoundScheduler()
        self:sendClientAt(clientKey, cmdId, {data = {
            roomNo = virtualData.ttGameBattle_.roomNumber,
        }})


    -------------------------------------------------
    -- 打牌出牌 10014
    elseif cmdId == NetCmd.TTGAME_GAME_PLAY_CARD then
        self:sendClientAt(clientKey, cmdId, {data = {
            roomNo = virtualData.ttGameBattle_.roomNumber,
        }})
        self:appendDeskCardAt(data.uuid, data.position, data.battleCardIndex)
        self:switchBattleRound()
        self:updateBattleRound()


    -------------------------------------------------
    -- 10007 pvp匹配
    elseif cmdId == NetCmd.TTGAME_PVP_MATCH then
        virtualData.ttGameBattleRoomId_ = virtualData.generateUuid()
        virtualData.ttGameBattleDeckId_ = data.deckId
        self:sendClientAt(clientKey, cmdId, {data = {
            roomNo = virtualData.ttGameBattleRoomId_,
        }})

        if virtualData.ttGamePvpScheduler_ then
            scheduler.unscheduleGlobal(virtualData.ttGamePvpScheduler_)
            virtualData.ttGamePvpScheduler_ = nil
        end
        if data.match == 1 then
            virtualData.ttGamePvpScheduler_ = scheduler.performWithDelayGlobal(function()
                self:startBattleCard(TTGAME_DEFINE.BATTLE_TYPE.PVP, {
                    opponentUuid   = virtualData.generateUuid(),
                    opponentName   = virtualData.createName(virtualData._r(8, 16)),
                    opponentAvatar = virtualData.createAvatarId(),
                    opponentFrame  = virtualData.createAvatarFrameId(),
                    opponentCards  = RandomCardListFunc(),
                })
            end, 1)
        end


    -------------------------------------------------
    -- 10002 房间创建
    elseif cmdId == NetCmd.TTGAME_ROOM_CREATE then
        virtualData.ttGameBattleRoomId_ = virtualData.generateUuid()
        virtualData.ttGameBattleFriend_ = {
            uuid   = virtualData.generateUuid(),
            name   = virtualData.createName(virtualData._r(8, 16)),
            avatar = virtualData.createAvatarId(),
            aFrame = virtualData.createAvatarFrameId(),
            cards  = RandomCardListFunc(),
        }
        self:sendClientAt(clientKey, cmdId, {data = {
            roomNo = virtualData.ttGameBattleRoomId_,
        }})

        virtualData.ttGameFriendScheduler_ = scheduler.performWithDelayGlobal(function()
            -- 10004 房间进入通知
            self:sendAllClient(NetCmd.TTGAME_ROOM_ENTER_NOTICE, {data = {
                roomNo              = virtualData.ttGameBattleRoomId_,
                opponentUuid        = virtualData.ttGameBattleFriend_.uuid,
                opponentName        = virtualData.ttGameBattleFriend_.name,
                opponentAvatar      = virtualData.ttGameBattleFriend_.avatar,
                opponentAvatarFrame = virtualData.ttGameBattleFriend_.aFrame,
                opponentCards       = virtualData.ttGameBattleFriend_.cards,
            }})

            -- 10006 房间准备通知
            virtualData.ttGameFriendScheduler_ = scheduler.performWithDelayGlobal(function()
                self:sendAllClient(NetCmd.TTGAME_ROOM_READY_NOTICE, {data = {
                    roomNo = virtualData.ttGameBattleRoomId_,
                    ready  = 1,
                }})
            end, 2)
        end, 2)


    -------------------------------------------------
    -- 10003 房间进入
    elseif cmdId == NetCmd.TTGAME_ROOM_ENTER then
        virtualData.ttGameBattleRoomId_ = data.roomNo
        virtualData.ttGameBattleFriend_ = {
            uuid   = virtualData.generateUuid(),
            name   = virtualData.createName(virtualData._r(8, 16)),
            avatar = virtualData.createAvatarId(),
            aFrame = virtualData.createAvatarFrameId(),
            cards  = RandomCardListFunc(),
        }
        self:sendClientAt(clientKey, cmdId, {data = {
            roomNo              = virtualData.ttGameBattleRoomId_,
            opponentUuid        = virtualData.ttGameBattleFriend_.uuid,
            opponentName        = virtualData.ttGameBattleFriend_.name,
            opponentAvatar      = virtualData.ttGameBattleFriend_.avatar,
            opponentAvatarFrame = virtualData.ttGameBattleFriend_.aFrame,
            opponentCards       = virtualData.ttGameBattleFriend_.cards,
            opponentReady       = virtualData._r(0,1),  -- 0:对手未准备 1:对手已准备
        }})

        virtualData.ttGameFriendScheduler_ = scheduler.performWithDelayGlobal(function()
            -- 10020 房间离开通知
            self:sendAllClient(NetCmd.TTGAME_ROOM_LEAVE_NOTICE, {data = {
                roomNo = virtualData.ttGameBattleRoomId_,
            }})
        end, 5)

        -- debug use
        -- self:sendClientAt(clientKey, cmdId, {
        --     errcode = 1,
        --     errmsg  = '????',
        --     data    = {
        --         roomNo = virtualData.ttGameBattleRoomId_,
        --     }
        -- })

    
    -------------------------------------------------
    -- 10019 房间离开
    elseif cmdId == NetCmd.TTGAME_ROOM_LEAVE then
        self:sendClientAt(clientKey, cmdId, {data = {
            roomNo = virtualData.ttGameBattleRoomId_,
        }})

        if virtualData.ttGameFriendScheduler_ then
            scheduler.unscheduleGlobal(virtualData.ttGameFriendScheduler_)
            virtualData.ttGameFriendScheduler_ = nil
        end


    -------------------------------------------------
    -- 10005 房间准备
    elseif cmdId == NetCmd.TTGAME_ROOM_READY then
        if virtualData.ttGameFriendScheduler_ then
            scheduler.unscheduleGlobal(virtualData.ttGameFriendScheduler_)
            virtualData.ttGameFriendScheduler_ = nil
        end
        
        self:sendClientAt(clientKey, cmdId, {data = {
            roomNo = virtualData.ttGameBattleRoomId_,
        }})

        if data.ready == 1 then
            virtualData.ttGameBattleDeckId_    = data.deckId
            virtualData.ttGameFriendScheduler_ = scheduler.performWithDelayGlobal(function()
                self:startBattleCard(TTGAME_DEFINE.BATTLE_TYPE.FRIEND, {
                    opponentUuid   = virtualData.ttGameBattleFriend_.uuid,
                    opponentName   = virtualData.ttGameBattleFriend_.name,
                    opponentAvatar = virtualData.ttGameBattleFriend_.avatar,
                    opponentFrame  = virtualData.ttGameBattleFriend_.aFrame,
                    opponentCards  = virtualData.ttGameBattleFriend_.cards,
                })
            end, 1)
        end

    
    -------------------------------------------------
    -- 10009 房间发送心情
    elseif cmdId == NetCmd.TTGAME_ROOM_MOOD then
        scheduler.performWithDelayGlobal(function()
            -- 10010 房间心情通知
            local moodConfFile = TTGameUtils.GetConf(TTGAME_DEFINE.CONF_TYPE.CHAT_MOOD)
            local moodIdList   = table.keys(moodConfFile)
            self:sendClientAt(clientKey, NetCmd.TTGAME_ROOM_MOOD_NOTICE, {data = {
                roomNo    = virtualData.ttGameBattleRoomId_,
                messageId = moodIdList[virtualData._r(#moodIdList)],
            }})
        end, 0.5)
        
    end
end


function TTGameServer:startBattleCard(battleType, opponentInfo)
    virtualData.ttGameBattle_ = {
        roomNumber     = virtualData.ttGameBattleRoomId_,
        battleType     = battleType,
        deskDataMap    = EmptyDeskMapFunc(),
        playerUuid     = virtualData.playerData.playerId,
        playerName     = virtualData.playerData.playerName,
        playerAvatar   = virtualData.playerData.avatar,
        playerFrame    = virtualData.playerData.avatarFrame,
        playerCards    = virtualData.ttGame_.deck[tostring(virtualData.ttGameBattleDeckId_)],
        playerPlays    = {},
        opponentUuid   = opponentInfo.opponentUuid,
        opponentName   = opponentInfo.opponentName,
        opponentAvatar = opponentInfo.opponentAvatar,
        opponentFrame  = opponentInfo.opponentFrame,
        opponentCards  = opponentInfo.opponentCards,
        opponentPlays  = {},
    }

    -- round info
    virtualData.ttGameBattle_.roundSeconds   = TTGAME_DEFINE.ROUND_SECONDS
    virtualData.ttGameBattle_.roundPlayerId  = virtualData.ttGameBattle_.playerUuid
    virtualData.ttGameBattle_.roundTimestamp = os.time() + virtualData.ttGameBattle_.roundSeconds

    -- rule info
    local pveNpcConfInfo = TTGameUtils.GetConfAt(TTGAME_DEFINE.CONF_TYPE.NPC_DEFINE, virtualData.ttGameBattle_.opponentUuid)
    local pveNpcRuleList = checktable(pveNpcConfInfo.rules)
    if TTGAME_DEFINE.BATTLE_TYPE.PVE == battleType and table.nums(pveNpcRuleList) > 0 then
        virtualData.ttGameBattle_.rules = pveNpcRuleList
    else
        local schduleConfInfo = TTGameUtils.GetConfAt(TTGAME_DEFINE.CONF_TYPE.SCHEDULE, virtualData.ttGame_.scheduleId)
        virtualData.ttGameBattle_.rules = checktable(schduleConfInfo.rules)
    end

    -- notice 10004 : enter room
    self:sendAllClient(NetCmd.TTGAME_ROOM_ENTER_NOTICE, {data = {
        roomNo              = virtualData.ttGameBattle_.roomNumber,     -- 房间号
        opponentUuid        = virtualData.ttGameBattle_.opponentUuid,   -- 对手名称
        opponentName        = virtualData.ttGameBattle_.opponentName,   -- 对手uuid
        opponentAvatar      = virtualData.ttGameBattle_.opponentAvatar, -- 对手头像
        opponentAvatarFrame = virtualData.ttGameBattle_.opponentFrame,  -- 对手头像框
        opponentBattleCards = virtualData.ttGameBattle_.opponentCards,  -- 对手卡组
        rules               = virtualData.ttGameBattle_.rules,          -- 打牌规则
    }})

    -- battle init data
    local battleInitData = {
        roomNo              = virtualData.ttGameBattle_.roomNumber,           -- 房间号
        opponentUuid        = virtualData.ttGameBattle_.opponentUuid,         -- 对手名称
        opponentName        = virtualData.ttGameBattle_.opponentName,         -- 对手uuid
        opponentAvatar      = virtualData.ttGameBattle_.opponentAvatar,       -- 对手头像
        opponentAvatarFrame = virtualData.ttGameBattle_.opponentFrame,        -- 对手头像框
        opponentBattleCards = clone(virtualData.ttGameBattle_.opponentCards), -- 对手卡组
        firstHandMemberUuid = virtualData.ttGameBattle_.roundPlayerId,        -- 先手玩家
        initialRuleEffects  = {},                                             -- 战前规则
            -- swap  : map  交换规则（key: 成员ID, value: 交换出去的卡牌位置（位置从1开始））
            -- chaos : map  混乱规则（key: 成员ID, value: 卡牌位置顺序list（位置从1开始））
    }
    
    -- init rule
    -- 4 : 混乱
    -- 7 : 交换
    local hasInitSwap  = false
    local hasInitChaos = false
    for index, ruleId in ipairs(virtualData.ttGameBattle_.rules) do
        if checkint(ruleId) == 4 then
            hasInitChaos = true
        end
        if checkint(ruleId) == 7 then
            hasInitSwap = true
        end
    end
    
    if ENABLE_INIT_RULE or hasInitChaos then
        -- 4 混乱
        local operatorOrder = RandomOrderFunc(virtualData.ttGameBattle_.playerCards)
        local opponentOrder = RandomOrderFunc(virtualData.ttGameBattle_.opponentCards)
        table.insert(battleInitData.initialRuleEffects, {chaos = {
            [tostring(virtualData.ttGameBattle_.playerUuid)]   = operatorOrder,
            [tostring(virtualData.ttGameBattle_.opponentUuid)] = opponentOrder,
        }})
    end
        
    if ENABLE_INIT_RULE or hasInitSwap then
        -- 7 交换
        local operatorIndex  = virtualData._r(#virtualData.ttGameBattle_.playerCards)
        local opponentIndex  = virtualData._r(#virtualData.ttGameBattle_.opponentCards)
        local operatorCardId = virtualData.ttGameBattle_.playerCards[operatorIndex]
        local opponentCardId = virtualData.ttGameBattle_.opponentCards[opponentIndex]
        virtualData.ttGameBattle_.playerCards[operatorIndex]   = opponentCardId
        virtualData.ttGameBattle_.opponentCards[opponentIndex] = operatorCardId
        table.insert(battleInitData.initialRuleEffects, {swap = {
            [tostring(virtualData.ttGameBattle_.playerUuid)]   = operatorIndex,
            [tostring(virtualData.ttGameBattle_.opponentUuid)] = opponentIndex,
        }})
    end


    -- notice 100008 : start battle
    self:sendAllClient(NetCmd.TTGAME_GAME_MATCHED_NOTICE, {data = battleInitData})
    
    -- start round
    self:updateBattleRound()
end


function TTGameServer:appendDeskCardAuto(isIgnoreNotice)
    local handCardIdList = {}
    local useCardIdxList = {}
    local battleCardIdx  = -1
    if virtualData.ttGameBattle_.roundPlayerId == virtualData.ttGameBattle_.playerUuid then
        handCardIdList = virtualData.ttGameBattle_.playerCards
        useCardIdxList = virtualData.ttGameBattle_.playerPlays
    else
        handCardIdList = virtualData.ttGameBattle_.opponentCards
        useCardIdxList = virtualData.ttGameBattle_.opponentPlays
    end
    
    -- filter idleCards
    local idleCardIdxList = {}
    local tempUsedIdxList = clone(useCardIdxList)
    for handIndex, _ in ipairs(handCardIdList) do
        local isUsedCard = false
        for listIndex, usedIndex in ipairs(tempUsedIdxList) do
            if checkint(handIndex) == checkint(usedIndex) then
                table.remove(tempUsedIdxList, listIndex)
                isUsedCard = true
                break
            end
        end
        
        if not isUsedCard then
            table.insert(idleCardIdxList, handIndex)
        end
    end
    
    -- random battleCard
    if #idleCardIdxList > 0 then
        battleCardIdx = checkint(idleCardIdxList[virtualData._r(#idleCardIdxList)])
    end

    -- filter idleSite
    local idleDeskCells = {}
    local battleSiteId  = 0
    for siteId, deskCellData in pairs(virtualData.ttGameBattle_.deskDataMap) do
        if not deskCellData.battleCardId then
            table.insert(idleDeskCells, siteId)
        end
    end

    -- random deskSite
    if #idleDeskCells > 0 then
        battleSiteId = checkint(idleDeskCells[virtualData._r(#idleDeskCells)])
    end
    
    if battleSiteId > 0 and battleCardIdx > 0 then
        self:appendDeskCardAt(virtualData.ttGameBattle_.roundPlayerId, battleSiteId, battleCardIdx, isIgnoreNotice)
    end
end


function TTGameServer:appendDeskCardAt(owerId, siteId, cardIndex, isIgnoreNotice)
    -- use battleCard
    local handCardIdList = {}
    local useCardIdxList = {}
    if tostring(owerId) == tostring(virtualData.ttGameBattle_.playerUuid) then
        handCardIdList = virtualData.ttGameBattle_.playerCards
        useCardIdxList = virtualData.ttGameBattle_.playerPlays
    else
        handCardIdList = virtualData.ttGameBattle_.opponentCards
        useCardIdxList = virtualData.ttGameBattle_.opponentPlays
    end
    table.insert(useCardIdxList, cardIndex)

    -- append deskData
    local deskData        = virtualData.ttGameBattle_.deskDataMap[tostring(siteId)]
    deskData.ownerId      = owerId
    deskData.battleCardId = handCardIdList[cardIndex]

    -- random allDesk owner
    for _, deskCellData in pairs(virtualData.ttGameBattle_.deskDataMap) do
        if checkint(deskCellData.battleCardId) > 0 then

            deskCellData.ownerId = virtualData._rValue({
                virtualData.ttGameBattle_.playerUuid,
                virtualData.ttGameBattle_.opponentUuid,
            })[1]

            deskCellData.cardAttrs     = {
                ['1'] = virtualData._r(0,10),
                ['2'] = virtualData._r(0,10),
                ['3'] = virtualData._r(0,10),
                ['4'] = virtualData._r(0,10),
            }
        end
    end

    if isIgnoreNotice ~= true then
        -- playCardNotice 10015
        self:sendAllClient(NetCmd.TTGAME_GAME_PLAY_CARD_NOTICE, {data = {
            uuid            = owerId,
            position        = siteId,
            battleCardIndex = cardIndex,
            map             = virtualData.ttGameBattle_.deskDataMap,
            roomNo          = virtualData.ttGameBattle_.roomNumber,
        }})
    end
end


function TTGameServer:isBattleOver()
    local battleCardNum = 0
    for _, deskData in pairs(virtualData.ttGameBattle_.deskDataMap) do
        if checkint(deskData.battleCardId) > 0 then
            battleCardNum = battleCardNum + 1
        end
    end
    local totalDeskCell = TTGAME_DEFINE.DESK_ELEM_ROWS * TTGAME_DEFINE.DESK_ELEM_ROWS
    return battleCardNum >= totalDeskCell
end


function TTGameServer:updateBattleRound()
    self:stopRoundScheduler()
    
    if self:isBattleOver() then
        local operatorScore = #virtualData.ttGameBattle_.playerCards   - #virtualData.ttGameBattle_.playerPlays
        local opponentScore = #virtualData.ttGameBattle_.opponentCards - #virtualData.ttGameBattle_.opponentPlays
        for _, deskData in pairs(virtualData.ttGameBattle_.deskDataMap) do
            if deskData.ownerId == virtualData.ttGameBattle_.opponentUuid then
                opponentScore = opponentScore + 1
            elseif deskData.ownerId == virtualData.ttGameBattle_.playerUuid then
                operatorScore = operatorScore + 1
            end
        end
        -- result 10016
        local gameResult = TTGAME_DEFINE.RESULT_TYPE.DRAW
        if operatorScore > opponentScore then
            gameResult = TTGAME_DEFINE.RESULT_TYPE.WIN
        elseif operatorScore < opponentScore then
            gameResult = TTGAME_DEFINE.RESULT_TYPE.FAIL
        end
        ttGameServer:sendAllClient(NetCmd.TTGAME_GAME_RESULT_NOTICE, {data = {
            result      = gameResult,
            rewards     = gameResult == TTGAME_DEFINE.RESULT_TYPE.WIN and virtualData.createGoodsList(4) or {},
            rewardIndex = virtualData._r(4),
            roomNo      = virtualData.ttGameBattle_.roomNumber,
        }})
    else
        -- 敌方秒出牌
        if ENABLE_QUICK_BATTLE and virtualData.ttGameBattle_.roundPlayerId == virtualData.ttGameBattle_.opponentUuid then
            self:stopRoundScheduler()
            self:appendDeskCardAuto()
            self:switchBattleRound()
            self:updateBattleRound()
        else
            self:startRoundScheduler()
        end
    end
end


function TTGameServer:stopRoundScheduler()
    if virtualData.ttGameRoundScheduler_ then
        scheduler.unscheduleGlobal(virtualData.ttGameRoundScheduler_)
        virtualData.ttGameRoundScheduler_ = nil
    end
end
function TTGameServer:startRoundScheduler()
    if virtualData.ttGameRoundScheduler_ then return end
    virtualData.ttGameRoundScheduler_ = scheduler.performWithDelayGlobal(function()
        self:stopRoundScheduler()
        self:appendDeskCardAuto()
        self:switchBattleRound()
        self:updateBattleRound()
    end, TTGAME_DEFINE.ROUND_SECONDS)
end
function TTGameServer:switchBattleRound()
    if virtualData.ttGameBattle_.roundPlayerId == virtualData.ttGameBattle_.playerUuid then
        virtualData.ttGameBattle_.roundPlayerId = virtualData.ttGameBattle_.opponentUuid
    else
        virtualData.ttGameBattle_.roundPlayerId = virtualData.ttGameBattle_.playerUuid
    end
    virtualData.ttGameBattle_.roundSeconds   = TTGAME_DEFINE.ROUND_SECONDS
    virtualData.ttGameBattle_.roundTimestamp = os.time() + virtualData.ttGameBattle_.roundSeconds
end


return TTGameServer
