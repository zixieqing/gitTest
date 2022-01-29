--[[
 * author : kaishiqi
 * descpt : 关于 外卖数据 的本地模拟
]]
virtualData = virtualData or {}

local _r  = virtualData._r
local j2t = virtualData.j2t
local t2t = virtualData.t2t


-- 经营订单
virtualData['Business/order'] = function(args)
    local data = {
        takeawayOrder = virtualData.takeawayHomeData_.diningCar,
        exploreOrder  = {},
    }
    return t2t(data)
end


-- 外卖订单
virtualData['Takeaway/home'] = function(args)
    local data = {
        diningCar                   = {},     -- 餐车
        publicOrder                 = {},     -- 公众订单
        privateOrder                = {},     -- 私有订单
        nextPublicOrderRefreshTime  = -1,     -- 下个私有订单出现剩余秒数, -1表示不会刷新
        nextPrivateOrderRefreshTime = -1,     -- 下个公众订单出现剩余秒数, -1表示不会刷新
        leftRobberyTimes            = _r(4),  -- 剩余打劫次数
        nextRobberyTimeSeconds      = _r(99), -- 下次打劫恢复剩余秒数
        robberyTimesRecoverTime     = 60,     -- 一次打劫恢复所需秒数
    }

    local currentAreaId      = virtualData.playerData.newestAreaId
    local locationList       = clone(HOME_MAP_LOCATION_MAP[tostring(currentAreaId)] or {})
    local takeawayRoleConfs  = virtualData.getConf('takeaway', 'role')
    local takeawayRoleIdList = table.keys(takeawayRoleConfs)
    local orderIndex         = 1

    -- create public order
    local publicOrderConfs  = virtualData.getConf('takeaway', 'publicOrder')
    local publicOrderIdList = table.keys(publicOrderConfs)
    for status = 1, 4 do
        for loop = 1, 1 do
            if #publicOrderIdList > 0 and #locationList > 0 then
                local orderData = {
                    orderId              = orderIndex,--virtualData.generateUuid(),
                    roleId               = takeawayRoleIdList[_r(#takeawayRoleIdList)],
                    location             = table.remove(locationList, _r(#locationList)),
                    takeawayId           = table.remove(publicOrderIdList, _r(#publicOrderIdList)),
                    areaId               = currentAreaId,
                    status               = status,
                    endLeftSeconds       = _r(99),  -- 公众订单特有的过期时间
                    leftSeconds          = _r(99),
                    totalDeliverySeconds = 99,
                }
                table.insert(data.publicOrder, orderData)
                orderIndex = orderIndex + 1
            end
        end
    end

    -- create private order
    local privateOrderConfs  = virtualData.getConf('takeaway', 'privateOrder')
    local privateOrderIdList = table.keys(privateOrderConfs)
    for status = 1, 4 do
        for loop = 1, 1 do
            if #privateOrderIdList > 0 and #locationList > 0 then
                local orderData = {
                    orderId              = orderIndex,--virtualData.generateUuid(),
                    roleId               = takeawayRoleIdList[_r(#takeawayRoleIdList)],
                    location             = table.remove(locationList, _r(#locationList)),
                    takeawayId           = table.remove(privateOrderIdList, _r(#privateOrderIdList)),
                    areaId               = currentAreaId,
                    status               = status,
                    leftSeconds          = _r(99),
                    totalDeliverySeconds = 99,
                }
                table.insert(data.privateOrder, orderData)
                orderIndex = orderIndex + 1
            end
        end
    end

    -- create dining car
    for index, orderData in ipairs(data.privateOrder) do
        if orderData.status == 2 or orderData.status == 4 then
            table.insert(data.diningCar, {
                takeawayId    = orderData.takeawayId,
                orderId       = orderData.orderId,
                status        = orderData.status,
                areaId        = orderData.areaId,
                roleId        = orderData.roleId,
                teamId        = #data.diningCar + 1,
                diningCarId   = #data.diningCar + 1,
                level         = _r(99),
                leftSeconds   = _r(999),
                orderType     = 1,
                beRobbed      = 0,
                robberyResult = 0,
            })
        end
    end

    virtualData.takeawayHomeData_ = data
    return t2t(data)
end


-- 捣乱列表
virtualData['Takeaway/robberyList'] = function(args)
    local data = {
        orders                  = {},
        leftRobberyTimes        = _r(4),  -- 剩余打劫次数
        nextRobberyTimeSeconds  = _r(9), -- 下次打劫恢复剩余秒数
        robberyTimesRecoverTime = 60,     -- 一次打劫恢复所需秒数
    }

    local currentAreaId      = virtualData.playerData.newestAreaId
    local locationList       = clone(HOME_MAP_LOCATION_MAP[tostring(currentAreaId)] or {})
    local publicOrderConfs   = virtualData.getConf('takeaway', 'publicOrder')
    local privateOrderConfs  = virtualData.getConf('takeaway', 'privateOrder')
    local publicOrderIdList  = table.keys(publicOrderConfs)
    local privateOrderIdList = table.keys(privateOrderConfs)
    for loop = 1, 3*2 do
        if #locationList > 0 then
            local orderData = {
                areaId         = currentAreaId,
                uuid           = loop,
                -- uuid           = virtualData.generateUuid(),
                orderId        = virtualData.generateUuid(),
                playerId       = virtualData.createPlayerId(),
                playerName     = virtualData.createName(_r(6,12)),
                playerAvatar   = virtualData.createAvatarId(),
                location       = table.remove(locationList, _r(#locationList)),
                threatDegree   = _r(5),
                hasExtraReward = _r(0,1),
            }
            if loop % 2 == 0 then
                if #publicOrderIdList > 0 then
                    orderData.orderType  = Types.TYPE_TAKEAWAY_PUBLIC
                    orderData.takeawayId = table.remove(publicOrderIdList, _r(#publicOrderIdList))
                    table.insert(data.orders, orderData)
                end
            else
                if #privateOrderIdList > 0 then
                    orderData.orderType  = Types.TYPE_TAKEAWAY_PRIVATE
                    orderData.takeawayId = table.remove(privateOrderIdList, _r(#privateOrderIdList))
                    table.insert(data.orders, orderData)
                end
            end
        end
    end
    return t2t(data)
end


-- 订单信息
virtualData['Takeaway/order'] = function(args)
    local data = {
        hasDeliveredNumber   = _r(9),                                -- 已发车的数量
        lastDeliveredPlayers = {},                                   -- 最近20个发车的玩家
        robbery              = {},                                   -- 打劫信息
        rewards              = virtualData.createGoodsList(_r(1,4)), -- 剩下的奖励
    }
    return t2t(data)
end
