--[[
 * author : kaishiqi
 * descpt : 关于 飞船数据 的本地模拟
]]
virtualData = virtualData or {}

local _r  = virtualData._r
local j2t = virtualData.j2t
local t2t = virtualData.t2t


-- 探索首页
virtualData['Explore/home'] = function(args)
    if not virtualData.explore_ then
        virtualData.explore_ = {}
    end
    return t2t(virtualData.explore_)
end


-- 探索首页
virtualData['Explore/enter'] = function(args)
    local areaPointId   = checkint(args.areaFixedPointId)
    local areaPointConf = virtualData.getConf('explore', 'exploreAreaFixedPoint', areaPointId)
    local exploreData   = {}
    for _, explorePointId in pairs(areaPointConf) do
        exploreData[tostring(explorePointId)] = {
            explorePointId = explorePointId,
            baseReward     = virtualData.createGoodsList(_r(1,2)),
        }
    end
    return t2t(exploreData)
end


-- 开始探索
virtualData['Explore/explore'] = function(args)
    -- local data = {
    --     explore = {},
    --     currentFloorInfo = {},
    -- }
    -- return t2t(data)
    return j2t([[{"data":
        {
            "explore": {
                "playerId": 100363,
                "teamId": "1",
                "teamCards": [
                    "546",
                    "",
                    "",
                    "",
                    ""
                ],
                "areaId": "1",
                "areaFixedPointId": 2,
                "explorePointId": 1,
                "currentFloor": 1,
                "createTime": "2018-07-11 14:47:29",
                "status": 0,
                "deleted": 0,
                "id": "1165"
            },
            "currentFloorInfo": {
                "playerId": 100363,
                "exploreId": "1165",
                "floor": 1,
                "roomId": "101",
                "baseDrawn": 0,
                "hasDrawn": 0,
                "fightStatus": 0,
                "fightNum": "0",
                "floorRooms": {
                    "101": {
                        "roomId": "101",
                        "isBossQuest": false
                    }
                },
                "baseReward": [
                    {
                        "goodsId": 170001,
                        "type": 17,
                        "num": 1
                    }
                ],
                "chestReward": {
                    "1": {
                        "reward": {
                            "goodsId": 191001,
                            "type": 19,
                            "num": 1
                        },
                        "hasDrawn": 0,
                        "isBossChest": 0
                    }
                },
                "needTime": 1,
                "endTime": 1531291650,
                "isFinalLevel": 0,
                "id": "3169"
            }
        }
    }]])
end


virtualData['Explore/exploreContinue'] = function(args)
    return virtualData['Explore/explore'](args)
end


virtualData['Explore/exitExplore'] = function(args)
    local data = {
        exploreRecord = {},
        boss = {}
    }
    return t2t(data)
end


-- 领取探索基础奖励
virtualData['Explore/drawBaseReward'] = function(args)
    local data = {
        baseReward = virtualData.createGoodsList(_r(1,3))
    }
    return t2t(data)
end


-- 领取碳素宝箱奖励
virtualData['Explore/drawChestReward'] = function(args)
    local data = {
        rewards = virtualData.createGoodsList(_r(1,3))
    }
    return t2t(data)
end
