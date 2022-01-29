--[[
 * author : kaishiqi
 * descpt : 关于 商城数据 的本地模拟
]]
virtualData = virtualData or {}

local _r  = virtualData._r
local j2t = virtualData.j2t
local t2t = virtualData.t2t


-------------------------------------------------
virtualData['mall/home'] = function(args)
    local data = {
        diamond  = true,
        member   = true,
        chest    = true,
        goods    = true,
        cardSkin = true,
    }

    -------------------------------------------------
    -- diamond
    while data.diamond == true do
        data.diamond = {}
        local diamondData = {
            {price = 6, num = 30},
            {price = 30, num = 150},
            {price = 68, num = 350},
            {price = 128, num = 670},
            {price = 648, num = 3800},
            {price = 68, num = 3800, id = 10001, original = 368},
            {price = 58, num = 2800, id = 10002, original = 358},
            {price = 48, num = 1800, id = 10003, original = 348},
        }
        for i, v in ipairs(diamondData) do
            table.insert(data.diamond, {
                channelProductId      = v.id or virtualData.generateUuid(),
                productId             = v.id or virtualData.generateUuid(),
                num                   = v.num,
                price                 = v.price,
                point                 = v.price * 10,
                originalPrice         = v.original,
                name                  = string.fmt('充值%1元', v.price),
                isFirst               = _r(0,1),
                leftSeconds           = _r(999),
                lifeLeftPurchasedNum  = _r(9),                              -- 总剩余可购买次数.-1表示无限
                todayLeftPurchasedNum = _r(9),                              -- 每日剩余可购买次数.
                lifeStock             = _r(9),                              -- 总库存. -1表示无限
                stock                 = _r(9),                              -- 库存
                sequence              = i,                                  -- 排序
            })
        end
        break
    end

    -------------------------------------------------
    -- member
    while data.member == true do
        data.member = {}
        local memberData = {
            {vip = 4, price = 10, num = 100, exNum = 10, name = '周卡', icon = 'shop_diamonds_week_ico_card_1'},
            {vip = 1, price = 30, num = 350, exNum = 30, name = '召唤月卡'},
            {vip = 2, price = 30, num = 250, exNum = 20, name = '冒险月卡'},
            {vip = 3, price = 18, num = 150, exNum = 10, name = '皇家经营特权'},
            {vip = 1, price = 11, num = 150, exNum = 10, original = 648, id = 10001},
            {vip = 2, price = 12, num = 150, exNum = 10, original = 328, id = 10002},
        }
        for i, v in ipairs(memberData) do
            table.insert(data.member, {
                memberId              = v.vip,                               -- 会员id
                productId             = v.id or virtualData.generateUuid(),  -- 商品id（大于10000为活动）
                channelProductId      = v.id or virtualData.generateUuid(), -- 渠道商品id
                price                 = v.price,                             -- 商品价格
                originalPrice         = v.original,                          -- 商品原价
                name                  = v.name,                              -- 商品名称
                num                   = v.num,                               -- 商品数量
                extraNum              = v.exNum,                             -- 额外赠送数量
                leftSeconds           = _r(999),                             -- 到期时间
                purchaseLeftSeconds   = _r(999),                             -- 购买到期时间秒数, -1表示永不过期
                lifeLeftPurchasedNum  = -1,                                  -- 总剩余可购买次数.-1表示无限
                todayLeftPurchasedNum = _r(9),                               -- 每日剩余可购买次数.
                lifeStock             = -1,                                  -- 总库存. -1表示无限
                stock                 = _r(9),                               -- 库存
                iconName              = v.icon or '',
            })
        end
        break
    end

    -------------------------------------------------
    -- chest
    while data.chest == true do
        data.chest = {}
        local chestConfs  = virtualData.getConf('goods', 'chest')
        local chestIdList = table.keys(chestConfs)
        for i = 1, math.min(20, #chestIdList) do
            local chestId      = table.remove(chestIdList, _r(#chestIdList))
            local chestConf    = chestConfs[chestId] or {}
            local hasIcon      = _r(100) > 50
            local goodsIcon    = hasIcon and string.fmt('shop_tag_iconid_%1', _r(1,6)) or ''
            local iconName     = hasIcon and GAME_STORE_GOODS_ICON_NAME_FUNC_MAP[goodsIcon]() or ''
            local isLimitStock = _r(100) > 50

            table.insert(data.chest, {
                productId             = virtualData.generateUuid(),                               -- 商品id
                channelProductId      = virtualData.generateUuid(),                               -- 渠道商品id
                name                  = chestConf.name,                                           -- 商品名称
                rewards               = virtualData.createGoodsList(_r(2,5)),                     -- 奖励
                price                 = _r(99),                                                   -- 价格
                photo                 = chestConf.photoId,                                        -- 图片id
                descr                 = _r(100) > 50 and virtualData.createName(_r(12,24)) or '', -- 描述
                icon                  = goodsIcon,                                                -- 促销中 商品图标id
                iconTitle             = iconName,                                                 -- 促销中 商品图标名
                stock                 = _r(100) > 50 and _r(0,9) or -1,                           -- 今日剩余 库存数量
                todayLeftPurchasedNum = _r(100) > 50 and _r(0,9) or -1,                           -- 今日剩余 可购次数
                lifeStock             = isLimitStock and _r(0,9) or -1,                           -- 总剩余 库存数量，-1表示无限
                lifeLeftPurchasedNum  = isLimitCount and _r(0,9) or -1,                           -- 总剩余 可购次数，-1表示无限
                shelfLeftSeconds      = _r(100) > 50 and _r(19) or nil,                           -- 限时上架 剩余秒数
            })
        end
        break
    end

    -------------------------------------------------
    -- goods
    while data.goods == true do
        data.goods = {}
        local goodsTypsConfs = virtualData.goodsTypsConfs
        for typeId, typeConf in pairs(goodsTypsConfs) do
            local goodsTypeRef = CommonUtils.GetGoodsTypeTrueRef(typeConf.ref)
            local goodsRefConf = virtualData.getConf('goods', goodsTypeRef)
            local goodsKeyList = table.keys(goodsRefConf)
            local goodsListLen = #goodsKeyList

            for i = 1, 2 do
                local goodsId      = checkint(goodsKeyList[_r(1, goodsListLen)])
                local hasIcon      = _r(100) > 50
                local goodsIcon    = hasIcon and string.fmt('shop_tag_iconid_%1', _r(1,6)) or ''
                local iconName     = hasIcon and GAME_STORE_GOODS_ICON_NAME_FUNC_MAP[goodsIcon]() or ''
                local isLimitStock = _r(100) > 50
                local isLimitCount = _r(100) > 50
                
                table.insert(data.goods, {
                    type                  = _r(1,2),                          -- 购买方式 1:一次性购买 2:一个一个买
                    productId             = virtualData.generateUuid(),       -- 商品id
                    goodsId               = goodsId,                          -- 道具id
                    goodsNum              = _r(9),                            -- 道具数量
                    currency              = GOLD_ID,--virtualData.generateCurrencyId(), -- 货币id
                    price                 = _r(99),                           -- 价格
                    discount              = _r(10)*10,                        -- 折扣
                    icon                  = goodsIcon,                        -- 促销中 商品图标id
                    iconTitle             = iconName,                         -- 促销中 商品图标名
                    lifeStock             = isLimitStock and _r(0,9) or -1,   -- 总剩余 库存数量，-1表示无限
                    lifeLeftPurchasedNum  = isLimitCount and _r(0,9) or -1,   -- 总剩余 可购次数，-1表示无限
                    stock                 = _r(0,9),                          -- 今日剩余 库存数量，-1表示无限
                    todayLeftPurchasedNum = _r(100) > 50 and _r(0,9) or -1,   -- 今日剩余 可购次数，-1表示无限
                    shelfLeftSeconds      = _r(100) > 50 and _r(19) or nil,   -- 限时上架 剩余秒数
                    discountLeftSeconds   = _r(100) > 50 and _r(19) or nil,   -- 限时折扣 剩余秒数
                })
            end
        end
        break
    end

    -------------------------------------------------
    -- cardSkin
    while data.cardSkin == true do
        data.cardSkin = {}
        local skinConfs = virtualData.getConf('goods', 'cardSkin')
        for k, v in pairs(skinConfs or {}) do
            if _r(100) > 95 then
                table.insert(data.cardSkin, {
                    productId             = virtualData.generateUuid(),            -- 商品id
                    type                  = _r(1,2),                               -- 购买方式：1、一次性购买；2、一个个购买
                    goodsId               = v.id,                                  -- 道具id
                    goodsNum              = _r(3),                                 -- 道具数量
                    stock                 = _r(10),                                -- 库存
                    discount              = 100,                                   -- 折扣 1-100
                    memberDiscount        = 100,                                   -- 会员折扣 1-100
                    currency              = "890006;900002",
                    price                 = "988;2000",
                    sale                  = {["890006"]="988", ["900002"]="2000"},
                    todayLeftPurchasedNum = _r(3),                                 -- 每日剩余可购次数
                    lifeLeftPurchasedNum  = _r(100) > 50 and _r(19) or -1,         -- 总剩余可购买次数.-1表示无限
                    shelfLeftSeconds      = _r(100) > 50 and _r(19) or -1,         -- 限时上架剩余秒数.-1表示无限
                    lifeStock             = -1,                                    -- 总库存，-1表示无限
                })
            end
        end
        break
    end

    -------------------------------------------------
    -- others
    do
        local normalShops = {
            {currency = 900007, name = 'restaurant'},   -- 小费 商城
            {currency = 900008, name = 'arena'},        -- pvp 商城
            {currency = 900011, name = 'kofArena'},     -- kof 商城
            {currency = 900029, name = 'championship'}, -- 武道会 商城
        }
        for _, shopDefine in ipairs(normalShops) do
            local shopData = {
                nextRefreshLeftSeconds = _r(99), -- 刷新剩余秒数
                refreshLeftTimes       = _r(9),  -- 刷新剩余次数
                refreshDiamond         = _r(99), -- 刷新钻石单价
                products               = {},     -- 商品列表
            }
            for _, goodsData in ipairs(virtualData.createGoodsList(_r(6,12))) do
                table.insert(shopData.products, {
                    productId = virtualData.generateUuid(), -- 商品id
                    goodsId   = goodsData.goodsId,          -- 道具id
                    currency  = shopDefine.currency,        -- 货币id
                    goodsNum  = _r(99),                     -- 道具数量
                    price     = _r(999),                    -- 价格
                    purchased = _r(0,1),                    -- 是否已购买 (1 已购，0 未购)
                    sale      = {
                        [tostring(shopDefine.currency)] = _r(999)
                    },
                })
            end
            data[shopDefine.name] = shopData
        end
    end

    return t2t(data)
end


virtualData['mall/buy'] = function(args)
    local data = {
        rewards = virtualData.createGoodsList(_r(2,5))
    }
    return t2t(data)
end
virtualData['mall/buyMulti'] = function(args)
    local data = {
        rewards = virtualData.createGoodsList(_r(2,5))
    }
    return t2t(data)
end


virtualData['mall/restaurantRefresh'] = function(args)
    virtualData.playerData.diamond = virtualData.playerData.diamond - 1
    local data = {
        diamond  = virtualData.playerData.diamond,
        products = virtualData['mall/home']().data.restaurant.products,
    }
    return t2t(data)
end
virtualData['mall/arenaRefresh'] = function(args)
    virtualData.playerData.diamond = virtualData.playerData.diamond - 1
    local data = {
        diamond  = virtualData.playerData.diamond,
        products = virtualData['mall/home']().data.arena.products,
    }
    return t2t(data)
end
virtualData['mall/kofArenaRefresh'] = function(args)
    virtualData.playerData.diamond = virtualData.playerData.diamond - 1
    local data = {
        diamond  = virtualData.playerData.diamond,
        products = virtualData['mall/home']().data.kofArena.products,
    }
    return t2t(data)
end
virtualData['mall/championshipRefresh'] = function(args)
    virtualData.playerData.diamond = virtualData.playerData.diamond - 1
    local data = {
        diamond  = virtualData.playerData.diamond,
        products = virtualData['mall/home']().data.championship.products,
    }
    return t2t(data)
end
virtualData['mall/barRefresh'] = function(args)
    virtualData.playerData.diamond = virtualData.playerData.diamond - 1
    local data = {
        diamond  = virtualData.playerData.diamond,
        products = virtualData['mall/home']().data.bar.products,
    }
    return t2t(data)
end


-------------------------------------------------
-- pay 接口

virtualData['pay/order'] = function(args)
    local data = {
        orderNo = '', -- 订单号
        productId = args.productId, -- 商品id
    }
    return t2t(data)
end


-------------------------------------------------
-- avatar 接口
-------------------------------------------------

virtualData['mall/avatar'] = function(args)
    return t2t({})
end
virtualData['mall/buyAvatar'] = function(args)
    return t2t({})
end

