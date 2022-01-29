--[[
 * author : kaishiqi
 * descpt : 关于 排行榜 的本地模拟
]]
virtualData = virtualData or {}

local _r  = virtualData._r
local j2t = virtualData.j2t
local t2t = virtualData.t2t


-- 排行 餐厅
virtualData['Rank/restaurant'] = function(args)
    return t2t({})
end


-- 排行 公会捐献
virtualData['Rank/unionContributionPoint'] = function(args)
    return t2t({})
end


-- 排行 工会战
virtualData['Rank/unionWars'] = function(args)
    local data = {
        unionRank                = {},
        myUnionRank              = _r(99),   -- 我的工会排行
        myUnionWarsScore         = _r(9999), -- 我的工会竞赛排行积分
        unionWarsRankLeftSeconds = _r(9),    -- 工会排行榜剩余秒数
        myLastUnionRank          = _r(99),   -- 上周我的工会排名
        myLastUnionWarsScore     = _r(9999), -- 上周我的工会竞赛排行积分
        lastUnionRank            = {},       -- 上周工会排名
    }
    for i, memberData in ipairs(checktable(virtualData.union_).member or {}) do
        table.insert(data.unionRank, {
            unionId            = memberData.playerId,          -- 工会ID
            unionName          = memberData.playerName,        -- 工会名称
            unionAvatar        = memberData.playerAvatar,      -- 工会头像
            playerAvatarFrame  = memberData.playerAvatarFrame, -- 工会头像
            unionLevel         = memberData.playerLevel,       -- 工会等级
            unionWarsPoint     = _r(9999),                     -- 工会竞赛排行积分
            rank               = _r(99),                       -- 排名
            attackSuccessTimes = _r(99),                       -- 进攻成功次数
            defendSuccessTimes = _r(99),                       -- 防守成功次数
        })
    end
    return t2t(data)
end


-- 排行 竞技场
virtualData['Rank/kofArenaRank'] = function(args)
    local segmentConfs = virtualData.getConf('kofArena', 'levelSegment')
    local data = {
        kofArenaRank            = {},                           -- 排名, key为分区ID, value为排名list
        myKofArenaRank          = _r(99),                       -- 我的排名
        myKofArenaScore         = _r(999),                      -- 我的记录
        myKofArenaSegment       = _r(table.nums(segmentConfs)), -- 我的分区id
        lastKofArenaRank        = {},                           -- 上周积分排名
        myLastKofArenaRank      = _r(99),                       -- 上周我的排名
        myLastKofArenaScore     = _r(999),                      -- 上周我的记录
        myLastKofArenaSegment   = _r(table.nums(segmentConfs)), -- 上周我的分区id
        kofArenaRankLeftSeconds = _r(999),                      -- 竞技场排行榜剩余秒数
    }
    for segmentId, _ in pairs(segmentConfs) do
        -- kofArenaRank
        data.kofArenaRank[segmentId] = {}
        for i = 1, _r(5,10) do
            local playerId    = virtualData.createPlayerId()
            local playerCards = {}
            for teamIndex = 1, 3 do
                playerCards[tostring(teamIndex)] = {cards = {}, combatValue = _r(999999)}
                for cardIndex = 1, 5 do
                    table.insert(playerCards[tostring(teamIndex)].cards, virtualData.createCardData(nil, playerId))
                end
            end
            table.insert(data.kofArenaRank[segmentId], {
                playerId          = playerId,                          -- 玩家id
                playerName        = virtualData.createName(_r(8, 16)), -- 玩家名字
                playerLevel       = _r(100),                           -- 玩家等级
                playerAvatar      = virtualData.createAvatarId(),      -- 玩家头像
                playerAvatarFrame = virtualData.createAvatarFrameId(), -- 玩家头像框
                rank              = _r(999),                           -- 玩家排名
                winTimes          = _r(999),                           -- 胜利积分
                fightTeam         = playerCards,                       -- map 战斗队伍, key 为队伍序号
            })
        end

        -- lastKofArenaRank
        data.lastKofArenaRank[segmentId] = {}
        for i = 1, _r(5,15) do
            table.insert(data.lastKofArenaRank[segmentId], {
                playerName = virtualData.createName(_r(8, 16)), -- 玩家名字
                rank       = _r(999),                           -- 玩家排名
                winTimes   = _r(999),                           -- 胜利积分
            })
        end
    end
    return t2t(data)
end