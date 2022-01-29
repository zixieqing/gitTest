--[[
 * author : kaishiqi
 * descpt : 关于 飞船数据 的本地模拟
]]
virtualData = virtualData or {}

local _r  = virtualData._r
local j2t = virtualData.j2t
local t2t = virtualData.t2t


-- 飞艇首页
virtualData['airship/home'] = function(args)
    if not virtualData.airship_ then
        virtualData.airship_ = {
            pack                     = {},
            ladeRewards              = virtualData.createGoodsList(_r(4,8)),
            airshipPoint             = _r(999),                              -- 飞艇积分
            ladeUnitPrice            = 10,                                   -- 立即到达1钻石需要的时间(秒)
            nextArrivalLeftSeconds   = 0,                                    -- 下一个飞艇到达剩余秒数
            accelerateArrivalDiamond = _r(99),                               -- 立即到达所需钻石数
        }

        for i=1, _r(1,8) do
            table.insert(virtualData.airship_.pack, {
                packId = i,
                num     = _r(9),
                goodsId = virtualData.createGoodsList(1)[1].goodsId,
                rewards = virtualData.createGoodsList(_r(3)),
                hasDone = _r(0,1),  -- 0: 未完成 1: 已完成
            })
        end
    end
    
    virtualData.airship_.nextArrivalLeftSeconds = _r(99)
    return t2t(virtualData.airship_)
end
