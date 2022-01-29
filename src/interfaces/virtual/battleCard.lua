--[[
 * author : kaishiqi
 * descpt : 关于 打牌游戏数据 的本地模拟
]]
virtualData = virtualData or {}

local _r  = virtualData._r
local j2t = virtualData.j2t
local t2t = virtualData.t2t

local activityConfFile   = TTGameUtils.GetConf(TTGAME_DEFINE.CONF_TYPE.ACTIVITY)
local scheduleConfFile   = TTGameUtils.GetConf(TTGAME_DEFINE.CONF_TYPE.SCHEDULE)
local cardInitConfFile   = TTGameUtils.GetConf(TTGAME_DEFINE.CONF_TYPE.CARD_INIT)
local npcDefineConfFile  = TTGameUtils.GetConf(TTGAME_DEFINE.CONF_TYPE.NPC_DEFINE)
local cardAlbumConfFile  = TTGameUtils.GetConf(TTGAME_DEFINE.CONF_TYPE.CARD_ALBUM)
local cardDefineConfFile = TTGameUtils.GetConf(TTGAME_DEFINE.CONF_TYPE.CARD_DEFINE)
local cardPackConfFile   = TTGameUtils.GetConf(TTGAME_DEFINE.CONF_TYPE.CARD_PACK)

local DebugDefines = {
    pveOpenStatus  = 2,  -- PVE开放状态（0：随机，1：未开放，2：进行中）
    pvpOpenStatus  = 2,  -- PVP开放状态（0：随机，1：未开放，2：进行中）
    initCardStatus = 2,  -- 初始卡牌状态（0：全部，1：初始设置，2：初始+随机）
}


-- 打牌首页
virtualData['BattleCard/home'] = function(args)
    local pveStatus = DebugDefines.pveOpenStatus == 0 and _r(1,2) or DebugDefines.pveOpenStatus
    local pvpStatus = DebugDefines.pvpOpenStatus == 0 and _r(1,2) or DebugDefines.pvpOpenStatus

    if not virtualData.ttGame_ then
        local activityConfKeys  = table.keys(activityConfFile)
        local activityConfInfo  = activityConfFile[tostring(activityConfKeys[_r(#activityConfKeys)])] or {}
        local activitySummaryId = 2--checkint(activityConfInfo.id)
        local scheduleConfKeys  = TTGameUtils.GetScheduleIdList(activitySummaryId)
        local scheduleConfInfo  = scheduleConfFile[tostring(scheduleConfKeys[_r(#scheduleConfKeys)])] or {}

        local initDeckDict = {}
        local initCardList = {}
        local initCardMap  = {}
        for cardId, cardDefine in orderedPairs(cardInitConfFile) do
            for _, deckIndex in ipairs(cardDefine.deck) do
                initDeckDict[tostring(deckIndex)] = initDeckDict[tostring(deckIndex)] or {}
                table.insert(initDeckDict[tostring(deckIndex)], cardId)
            end
            if DebugDefines.initCardStatus == 1 then
                table.insert(initCardList, cardId)
            end
            initCardMap[tostring(cardId)] = true
        end
        
        if DebugDefines.initCardStatus == 0 then
            for cardId, cardConf in orderedPairs(cardDefineConfFile) do
                table.insert(initCardList, cardId)
            end
        elseif DebugDefines.initCardStatus == 2 then
            for cardId, cardConf in orderedPairs(cardDefineConfFile) do
                if initCardMap[tostring(cardId)] then
                    table.insert(initCardList, cardId)
                else
                    if _r(100) > 50 then
                        table.insert(initCardList, cardId)
                    end
                end
            end
        end

        local initNpcDataList = {}
        for _, npcId in ipairs(scheduleConfInfo.npc or {}) do
            local npcConfInfo = npcDefineConfFile[tostring(npcId)] or {}
            table.insert(initNpcDataList, {
                npcId              = checkint(npcId),             -- NPC ID
                leftRewardTimes    = _r(npcConfInfo.rewardTimes), -- NPC剩余奖励次数
                leftRewardBuyTimes = _r(npcConfInfo.maxBuyTimes), -- NPC剩余奖励购买次数
            })
        end

        -- debug use : all same card
        -- for deckIndex, deckCardList in pairs(initDeckDict) do
        --     for cardIndex, _ in ipairs(deckCardList) do
        --         deckCardList[cardIndex] = 391004
        --     end
        -- end

        local pvpRewardTimes = checkint(scheduleConfInfo.pvpRewardTimes)
        virtualData.ttGame_ = {
            summaryId          = activitySummaryId,   -- 总表id
            scheduleId         = scheduleConfInfo.id, -- 排期id
            battleCards        = initCardList,        -- 我拥有的卡牌
            deck               = initDeckDict,        -- 我的牌组, key为牌组编号 value为卡牌list
            npc                = initNpcDataList,     -- NPC列表
            pveStatus          = pveStatus,           -- PVE状态 1:未开始 2:进行中
            pvpStatus          = pvpStatus,           -- PVP状态 1:未开始 2:进行中
            pveLeftSeconds     = _r(60*60*24*3),      -- PVE当前状态剩余秒数
            pvpLeftSeconds     = _r(9),               -- PVP当前状态剩余秒数
            pvpLeftRewardTimes = _r(pvpRewardTimes),  -- PVP剩余奖励次数
            collects           = {},                  -- 已领取的奖励
        }

    else
        virtualData.ttGame_.pvpStatus      = pvpStatus
        virtualData.ttGame_.pvpLeftSeconds = _r(999)
    end

    ttGameServer:launch()
    return t2t(virtualData.ttGame_)
end


-- 打牌战报
virtualData['BattleCard/report'] = function(args)
    local data = {
        report = {}
    }
    local cardIdList = table.keys(cardDefineConfFile)
    for i = 1, _r(0,10) do
        local battleCards = {}
        for i = 1, _r(1,5) do
            table.insert(battleCards, cardIdList[_r(#cardIdList)])
        end
        local offsetDire = _r(100) > 50 and 1 or -1
        local offsetTime = offsetDire * virtualData.createSecond('d:100:?,h:24:?,s:60:?,m:60:?')
        table.insert(data.report, {
            result              = _r(1,3),                                              -- 1: 胜利 2:平局 3:失败
            createTime          = os.time() + offsetTime, -- 战斗时间戳
            opponentLevel       = _r(99),                                               -- 对手等级
            opponentId          = virtualData.createPlayerId(),                         -- 对手id
            opponentName        = virtualData.createName(_r(6,12)),                     -- 对手名称
            opponentAvatar      = virtualData.createAvatarId(),                         -- 对手头像
            opponentAvatarFrame = virtualData.createAvatarFrameId(),                    -- 对手头像框
            opponentBattleCards = battleCards,                                          -- 对手的出战卡牌列表
        })
    end
    return t2t(data)
end


-- 收集奖励
virtualData['BattleCard/drawCollect'] = function(args)
    table.insert(virtualData.ttGame_.collects, checkint(args.collectId))
   
    local albumConfInfo = cardAlbumConfFile[tostring(args.collectId)] or {}
    local data = {
        rewards = albumConfInfo.rewards or {}
    }
    return t2t(data)
end


-- 保存卡组
virtualData['BattleCard/saveDeck'] = function(args)
    virtualData.ttGame_.deck[tostring(args.deckId)] = string.split2(args.battleCards, ',')
    return t2t({})
end


-- 卡包商店
virtualData['BattleCard/cardPackMall'] = function(args)
    local data = {
        mall = {}
    }

    -- local cardPackConfFile = virtualData.getConf('goods', 'battleCardPack')
    for packId, packData in orderedPairs(cardPackConfFile) do
        local goodsId      = checkint(packData.id)
        local hasIcon      = _r(100) > 50
        local goodsIcon    = hasIcon and string.fmt('shop_tag_iconid_%1', _r(1,6)) or ''
        local iconName     = hasIcon and GAME_STORE_GOODS_ICON_NAME_FUNC_MAP[goodsIcon]() or ''
        local isLimitStock = _r(100) > 50
        local isLimitCount = _r(100) > 50
        
        table.insert(data.mall, {
            type                  = _r(1,2),                          -- 购买方式 1:一次性购买 2:一个一个买
            productId             = virtualData.generateUuid(),       -- 商品id
            goodsId               = goodsId,                          -- 道具id
            goodsNum              = _r(9),                            -- 道具数量
            currency              = TTGAME_DEFINE.CURRENCY_ID,--virtualData.generateCurrencyId(), -- 货币id
            price                 = _r(99),                           -- 价格
            -- discount              = _r(10)*10,                        -- 折扣
            icon                  = goodsIcon,                        -- 促销中 商品图标id
            iconTitle             = iconName,                         -- 促销中 商品图标名
            -- lifeStock             = isLimitStock and _r(0,9) or -1,   -- 总剩余 库存数量，-1表示无限
            -- lifeLeftPurchasedNum  = isLimitCount and _r(0,9) or -1,   -- 总剩余 可购次数，-1表示无限
            -- stock                 = _r(0,9),                          -- 今日剩余 库存数量，-1表示无限
            -- todayLeftPurchasedNum = _r(100) > 50 and _r(0,9) or -1,   -- 今日剩余 可购次数，-1表示无限
            -- shelfLeftSeconds      = _r(100) > 50 and _r(19) or nil,   -- 限时上架 剩余秒数
            -- discountLeftSeconds   = _r(100) > 50 and _r(19) or nil,   -- 限时折扣 剩余秒数
        })
    end

    virtualData.ttGameCardPackMall_ = data.mall
    return t2t(data)
    -- return j2t([[
    --     {"data":{"mall":[{"productId":"1","type":"1","goodsId":"400001","goodsNum":"1","currency":"900028","price":"400","icon":"","iconTitle":"","goodsDiscountGoodsId":"","goodsDiscountGoodsNum":"","goodsDiscount":""},{"productId":"2","type":"2","goodsId":"400001","goodsNum":"10","currency":"900028","price":"4000","icon":"","iconTitle":"","goodsDiscountGoodsId":"","goodsDiscountGoodsNum":"","goodsDiscount":""},{"productId":"3","type":"2","goodsId":"400002","goodsNum":"1","currency":"900028","price":"700","icon":"","iconTitle":"","goodsDiscountGoodsId":"","goodsDiscountGoodsNum":"","goodsDiscount":""},{"productId":"4","type":"2","goodsId":"400002","goodsNum":"10","currency":"900028","price":"7000","icon":"","iconTitle":"","goodsDiscountGoodsId":"","goodsDiscountGoodsNum":"","goodsDiscount":""}]},"timestamp":1574600669,"errcode":0,"errmsg":"","rand":"5dda7fdd7ee4c1574600669","sign":"98c2b0215e440ef31cb5e7a28ff632ad"}
    -- ]])
end


-- 卡包购买
virtualData['BattleCard/cardPackMallBuy'] = function(args)
    local data = {
        rewards = {}
    }

    -- have cardDict
    local battleCardDict = {}
    for _, cardId in ipairs(virtualData.ttGame_.battleCards) do
        battleCardDict[tostring(cardId)] = true
    end

    for _, goodsData in ipairs(virtualData.ttGameCardPackMall_) do
        if goodsData.productId == checkint(args.productId) then

            -- consume currency
            virtualData.playerData.backpack[tostring(goodsData.currency)] = virtualData.playerData.backpack[tostring(goodsData.currency)] - goodsData.price
            
            -- each cardPack.cards
            local cardPackConfInfo = cardPackConfFile[tostring(goodsData.goodsId)] or {}
            for cardIndex, cardId in ipairs(cardPackConfInfo.cards) do
                if #data.rewards < 10 then
                    -- check has card
                    if not battleCardDict[tostring(cardId)] then
                        table.insert(virtualData.ttGame_.battleCards, cardId)
                    end
                    -- append rewards
                    table.insert(data.rewards, {
                        goodsId     = goodsData.goodsId,
                        num         = 1,
                        turnGoodsId = cardId,
                    })
                end
            end
            break
        end
    end
    
    if #data.rewards == 0 then
        table.insert(data.rewards, {
            goodsId = GOLD_ID,
            num     = 1,
        })
    end
    return t2t(data)
end


-- 兑换卡牌
virtualData['BattleCard/compose'] = function(args)
    table.insert(virtualData.ttGame_.battleCards, args.battleCardId)
    return t2t({})
end


-- 购买次数
virtualData['BattleCard/buyRewardTimes'] = function(args)
    for _, npcData in ipairs(virtualData.ttGame_.npc) do
        if npcData.npcId == checkint(args.npcId) then
            local pveNpcConfInfo           = TTGameUtils.GetConfAt(TTGAME_DEFINE.CONF_TYPE.NPC_DEFINE, args.npcId)
            npcData.leftRewardTimes        = npcData.leftRewardTimes + checkint(pveNpcConfInfo.buyAdditionTimes)
            npcData.leftRewardBuyTimes     = npcData.leftRewardBuyTimes - 1
            virtualData.playerData.diamond = virtualData.playerData.diamond - checkint(pveNpcConfInfo.diamond)
            break
        end
    end

    local data = {
        diamond = virtualData.playerData.diamond
    }
    return t2t(data)
end
