--[[
 * author : kaishiqi
 * descpt : 关于 冰场数据 的本地模拟
]]
virtualData = virtualData or {}

local _r  = virtualData._r
local j2t = virtualData.j2t
local t2t = virtualData.t2t


-- 冰场首页
virtualData['IcePlace/home'] = function(args)
    if not virtualData.icePlace_ then
        virtualData.icePlace_ = {
            icePlace                = {},
            leftEventRewardTimes    = _r(9),
            iceVigourRecoverSeconds = _r(99),
        }
    end
    return t2t(virtualData.icePlace_)
    -- return j2t([[{"data":
    --     {"icePlace":{"1":{"id":"219683","playerId":"800378","icePlaceName":"冰场一号","icePlaceId":"1","icePlaceBed":{"1910693":{"vigour":"82","recoverTime":0,"newVigour":100},"1869072":{"vigour":"82","recoverTime":0,"newVigour":100}},"icePlaceBedNum":"8","createTime":"2018-02-22 10:20:58"}},"leftEventRewardTimes":10,"iceVigourRecoverSeconds":15}
    -- }]])
end


-- 冰场上场
virtualData['IcePlace/addCardInIcePlace'] = function(args)
    local data = {
        newPlayerCard = {
            playerCardId = args.playerCardId,
            vigour       = 100,
            recoverTime  = -1,
        }
    }
    return t2t(data)
end
