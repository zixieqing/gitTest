--[[
 * author : kaishiqi
 * descpt : 水吧功能 相关定义
]]
local WATER_BAR = {}


-------------------------------------------------------------------------------
-- 通用定义
-------------------------------------------------------------------------------

WATER_BAR.DEFINE = {
    FORMULA_STAR_MAX = 3, -- 配方最大星级
    CUSTOMER_BAR_MAX = 5, -- 招待最大数量
}
-- 隐藏饮品显示的formulaId
WATER_BAR.HIDE_FORMULA_ICON_ID = 439999

-- 主页状态
WATER_BAR.STATUS_TYPE = {
    UNKNOWN = 0, -- 未知
    OPENING = 1, -- 营业
    CLOSING = 2, -- 打烊
}

-- 配方状态
WATER_BAR.FORMULA_STATUS = {
    UNLOCK_MAKE     = 1, -- 已研发
    UNLCOK_NOT_MAKE = 2, -- 已解锁未研发
    LEVEL_LOCK      = 3, -- 等级锁定
    HIDE            = 4, -- 隐藏状态
}

-- 饮品类型
WATER_BAR.DRINK_TYPE = {
    ALL    = 0, -- 全部
    ALCOHO = 1, -- 酒水
    SOFT   = 2, -- 软饮
}

-- 功能解锁等级
WATER_BAR.UNLCOK_LEVEL = {
    FREE_DEV = 5 , -- 自由调制
}

-- 食材类型
WATER_BAR.MATERIAL_TYPE = {
    ALL     = 0, -- 全部
    BASIC   = 1, -- 基酒
    FLAVOUR = 2, -- 调味酒
    OTHER   = 3, -- 其他
    SEARCH  = 4, -- 搜索
}


-------------------------------------------------------------------------------
-- 网络协议
-------------------------------------------------------------------------------
do
    WATER_BAR.NETWORK = {}


    -------------------------------------------------
    -- 水吧升级

    WATER_BAR.NETWORK.BAR_UPGRADE = {
        POST = POST.WATER_BAR_LEVELUP,

        SEND = {},

        TAKE = { _map = 1, _key = 'BAR_UPGRADE_TAKE',
            NEW_BAR_LEVEL  = { _int = 1, _key = 'newLevel' },         -- 新等级
            NEW_POPULARITY = { _int = 1, _key = 'newBarPopularity' }, -- 新知名度
        },
    }


    -------------------------------------------------
    -- 市场主页
    WATER_BAR.NETWORK.MARKET_HOME = {
        POST = POST.WATER_BAR_MARKET_HOME,

        SEND = {},

        TAKE = { _map = 1, _key = 'MARKET_HOME_TAKE',
            REFRESH_DIAMOND      = { _int = 1, _key = 'refreshDiamond' },         -- 刷新钻石单价
            REFRESH_LEFT_TIEMS   = { _int = 1, _key = 'refreshLeftTimes' },       -- 刷新剩余次数
            REFRESH_LEFT_SECONDS = { _int = 1, _key = 'nextRefreshLeftSeconds' }, -- 刷新剩余秒数
            PRODUCTS             = { _lst = 1, _key = 'products',                 -- 商品列表
                PRODUCT_DATA = { _map = 1, _key = '$productData', -- 商品数据
                    PRODUCT_ID  = { _int = 1, _key = 'productId' }, -- 商品id
                    GOODS_ID    = { _int = 1, _key = 'goodsId' },   -- 道具id
                    GOODS_NUM   = { _int = 1, _key = 'goodsNum' },  -- 道具数量
                    CURRENCY_ID = { _int = 1, _key = 'currency' },  -- 货币id
                    PRICE_NUM   = { _int = 1, _key = 'price' },     -- 价格
                    PURCHASED   = { _int = 1, _key = 'purchased' }, -- 购买状态（0：未购，1：已购）
                    ICON_ID     = { _int = 1, _key = 'icon' },      -- 图标id
                    ICON_TITLE  = { _str = 1, _key = 'iconTitle' }, -- 图标标题
                    MULTI_SALE  = { _map = 1, _key = 'sale', -- 多售卖方式（key:货币，value:价格）
                        PRICE_NUM = { _int = 1, _key = '$price' },
                    },
                },
            },
        },
    }


    -- 市场刷新
    WATER_BAR.NETWORK.MARKET_REFRESH = {
        POST = POST.WATER_BAR_MARKET_REFRESH,

        SEND = {},

        TAKE = { _map = 1, _key = 'MARKET_REFRESH_TAKE',
            DIAMOND  = { _int = 1, _key = 'diamond' },            -- 玩家当前钻石
            PRODUCTS = WATER_BAR.NETWORK.MARKET_HOME.TAKE.PRODUCTS, -- 最新的商品列表
        },
    }


    -- 市场购买
    WATER_BAR.NETWORK.MARKET_BUY = {
        POST = POST.WATER_BAR_MARKET_BUY,

        SEND = { _map = 1, _key = 'MARKET_BUY_SEND',
            PRODUCT_IDS = { _str = 1, _key = 'productIds' },  -- 商品ID们（逗号分隔）
        },

        TAKE = { _map = 1, _key = 'MARKET_BUY_TAKE',
            REWARDS = { _lst = 1, _key = 'rewards', -- 奖励列表
                GOODS_DATA = { _map = 1, _key = '$goods', -- 物品数据
                    GOODS_ID  = { _int = 1, _key = 'goodsId'}, -- 物品ID
                    GOODS_NUM = { _int = 1, _key = 'num'},     -- 物品数量
                },
            },
        },
    }


    -------------------------------------------------
    -- 配方 喜爱/不喜爱
    WATER_BAR.NETWORK.FORMULA_LIKE = {
        POST = POST.WATER_BAR_FORMULA_LIKE,
        
        SEND = { _map = 1, _key = 'FORMULA_LIKE_SEND',
            FORMULA_IDS = { _str = 1, _key = 'formulaIds' }, -- 配方ID，逗号分隔（传一次会反转喜爱状态，空为全部取消喜爱）
        },

        TAKE = {},
    }


    -------------------------------------------------
    -- 饮品 上架/下架
    WATER_BAR.NETWORK.PUTAWAY_ON = {
        POST = POST.WATER_BAR_SHELF_ON,
        
        SEND = { _map = 1, _key = 'PUTAWAY_ON_SEND',
            DRINKS = { _str = 1, _key = 'drinks' }, -- json(key:饮品ID value:数量)
        },

        TAKE = {},
    }


    WATER_BAR.NETWORK.PUTAWAY_OFF = {
        POST = POST.WATER_BAR_SHELF_ON,
        
        SEND = { _map = 1, _key = 'PUTAWAY_OFF_SEND',
            DRINKS = { _str = 1, _key = 'drinks' }, -- json(key:饮品ID value:数量)
        },

        TAKE = {},
    }


    -------------------------------------------------
    -- 商店主页
    WATER_BAR.NETWORK.SHOP_HOME = {
        POST = POST.WATER_BAR_SHOP_HOME,

        SEND = {},

        TAKE = { _map = 1, _key = 'SHOP_HOME_TAKE',
            REFRESH_LEFT_SECONDS = { _int = 1, _key = 'nextRefreshLeftSeconds' }, -- 刷新剩余秒数
            PRODUCTS             = { _lst = 1, _key = 'products',                 -- 商品列表
                PRODUCT_DATA = { _map = 1, _key = '$productData', -- 商品数据
                    PRODUCT_ID  = { _int = 1, _key = 'productId' },       -- 商品id
                    GOODS_ID    = { _int = 1, _key = 'goodsId' },         -- 道具id
                    GOODS_NUM   = { _int = 1, _key = 'goodsNum' },        -- 道具数量
                    CURRENCY_ID = { _int = 1, _key = 'currency' },        -- 货币id
                    PRICE_NUM   = { _int = 1, _key = 'price' },           -- 价格
                    ICON_ID     = { _int = 1, _key = 'icon' },            -- 图标id
                    ICON_TITLE  = { _str = 1, _key = 'iconTitle' },       -- 图标标题
                    OPEN_LEVEL  = { _int = 1, _key = 'openLevel'},        -- 开启等级
                    STOCK_TOTAL = { _int = 1, _key = 'stock'},            -- 可购买次数
                    STOCK_LEFT  = { _int = 1, _key = 'leftPurchasedNum'}, -- 剩余购买次数
                },
            },
        },
    }


    -- 商店购买
    WATER_BAR.NETWORK.SHOP_BUY = {
        POST = POST.WATER_BAR_SHOP_BUY,

        SEND = { _map = 1, _key = 'SHOP_BUY_SEND',
            PRODUCT_ID  = { _str = 1, _key = 'productId' }, -- 商品ID
            PRODUCT_NUM = { _int = 1, _key = 'num' },       -- 商品数量
        },

        TAKE = { _map = 1, _key = 'SHOP_BUY_TAKE',
            REWARDS = { _lst = 1, _key = 'rewards', -- 奖励列表
                GOODS_DATA = { _map = 1, _key = '$goods', -- 物品数据
                    GOODS_ID  = { _int = 1, _key = 'goodsId'}, -- 物品ID
                    GOODS_NUM = { _int = 1, _key = 'num'},     -- 物品数量
                },
            },
        },
    }


    -- 商店批量购买
    WATER_BAR.NETWORK.SHOP_MULTI_BUY = {
        POST = POST.WATER_BAR_SHOP_MULTI_BUY,

        SEND = { _map = 1, _key = 'SHOP_MULTI_BUY_SEND',
            PRODUCT_IDS = { _str = 1, _key = 'products' },  -- 商品ID们（逗号分隔）
        },

        TAKE = { _map = 1, _key = 'SHOP_MULIT_BUY_TAKE',
            REWARDS = WATER_BAR.NETWORK.SHOP_BUY.TAKE.REWARDS, -- 奖励列表
        },
    }
end


-------------------------------------------------------------------------------
-- 市场相关
-------------------------------------------------------------------------------
do
    WATER_BAR.MARKET = {}

    WATER_BAR.MARKET.PROXY_NAME = 'WATER_BAR.MARKET.PROXY_NAME'

    WATER_BAR.MARKET.PROXY_STRUCT = { _map = 1, _key = WATER_BAR.MARKET.PROXY_NAME,
        MARKET_HOME_TAKE     = WATER_BAR.NETWORK.MARKET_HOME.TAKE,        -- 市场主页 接收数据
        MARKET_REFRESH_TAKE  = WATER_BAR.NETWORK.MARKET_REFRESH.TAKE,     -- 市场刷新 接收数据
        MARKET_BUY_TAKE      = WATER_BAR.NETWORK.MARKET_BUY.TAKE,         -- 市场购买 接收数据
        MARKET_BUY_SEND      = WATER_BAR.NETWORK.MARKET_BUY.SEND,         -- 市场购买 发送数据
        SEARCH_GOODS_ID      = { _int = 1, _key = 'searchGoodsId' },      -- 搜索的道具id
        MARKET_CURRENCY_ID   = { _int = 1, _key = 'marketCurrencyId' },   -- 市场交易货币id
        SELECT_MATERIAL_TYPE = { _int = 1, _key = 'selectMaterialType' }, -- 当前选中的材料类型
        REFRESH_TIMESTAMP    = { _int = 1, _key = 'refreshTimestamp' },   -- 市场刷新的时间戳
        SELECT_PRODUCT_MAP   = { _map = 1, _key = 'selectProductMap',     -- 选择的商品id表 [key:productId]
            SELECTED = { _bol = 1, _key = '$isSelected' }
        },
    }
end


-------------------------------------------------------------------------------
-- 信息相关
-------------------------------------------------------------------------------
do
    WATER_BAR.INFO = {}

    WATER_BAR.INFO.TAB_FUNC_ENUM = {
        UPGRADE = 1, -- 升级
        BILL    = 2, -- 营收
        EXPIRE  = 3, -- 过期
    }

    WATER_BAR.INFO.PROXY_NAME = 'WATER_BAR.INFO.PROXY_NAME'

    WATER_BAR.INFO.PROXY_STRUCT = { _map = 1, _key = WATER_BAR.INFO.PROXY_NAME,
        UPGRADE_TAKE          = WATER_BAR.NETWORK.BAR_UPGRADE.TAKE,        -- 水吧升级 接收数据
        SELECT_TAB_INDEX      = { _int = 1, _key = 'selectTabName' },      -- 所选页签索引
        WATER_BAR_LEVEL       = { _int = 1, _key = 'waterBarLevel' },      -- 当前水吧等级
        WATER_BAR_POPULARITY  = { _int = 1, _key = 'waterBarPopularity' }, -- 当前水吧知名度
        YESTERDAY_EXPIRE_LIST = { _lst = 1, _key = 'yesterdayExpire',      -- 昨日过期账目
            GOODS_DATA = { _map = 1, _key = '$goodsData',
                GOODS_ID  = { _int = 1, _key = 'goodsId' },
                GOODS_NUM = { _int = 1, _key = 'num' },
            },
        },
        YESTERDAY_BILL_LIST = { _lst = 1, _key = 'billInfoList',          -- 昨日营业账目
            BILL_DATA = { _map = 1, _key = '$billData',
                CUSTOMER_ID = { _int = 1, _key = 'customerId' }, -- 客人id
                CONSUMES    = { _lst = 1, _key = 'consume',      -- 消耗数据
                    GOODS_DATA = { _map = 1, _key = '$goodsData',
                        GOODS_ID  = { _int = 1, _key = 'goodsId' },
                        GOODS_NUM = { _int = 1, _key = 'num' },
                    },
                },
                REWARDS    = { _lst = 1, _key = 'rewards',       -- 收入数据
                    GOODS_DATA = { _map = 1, _key = '$goodsData',
                        GOODS_ID  = { _int = 1, _key = 'goodsId' },
                        GOODS_NUM = { _int = 1, _key = 'num' },
                    },
                },
            },
        },
    }
end


-------------------------------------------------------------------------------
-- 经营相关
-------------------------------------------------------------------------------
do
    WATER_BAR.BUSINESS = {}

    WATER_BAR.BUSINESS.PROXY_NAME = 'WATER_BAR.BUSINESS.PROXY_NAME'

    WATER_BAR.BUSINESS.PROXY_STRUCT = { _map = 1, _key = WATER_BAR.BUSINESS.PROXY_NAME,
        FREQUENCY_MAP = { _map = 1, _key = 'customerFrequencyPoint', -- 客人增加的熟客值 [key:customerId]
            POINT = { _int = 1, _key = '$point' },
        },
        REWARD_MAP = { _map = 1, _key = 'rewards',       -- 收入奖励 [key:customerId]
            REWARDS = { _lst = 1, _key = '$rewards',
                GOODS_DATA = { _map = 1, _key = '$goodsData',
                    GOODS_ID  = { _int = 1, _key = 'goodsId' },
                    GOODS_NUM = { _int = 1, _key = 'num' },
                },
            },
        },
    }
end


-------------------------------------------------------------------------------
-- 上架相关
-------------------------------------------------------------------------------
do
    WATER_BAR.PUTAWAY = {}

    WATER_BAR.PUTAWAY.PROXY_NAME = 'WATER_BAR.PUTAWAY.PROXY_NAME'

    WATER_BAR.PUTAWAY.PROXY_STRUCT = { _map = 1, _key = WATER_BAR.PUTAWAY.PROXY_NAME,
        PUTAWAY_ON_SEND   = WATER_BAR.NETWORK.PUTAWAY_ON.SEND,      -- 水吧上架 发送数据
        PUTAWAY_OFF_SEND  = WATER_BAR.NETWORK.PUTAWAY_OFF.SEND,     -- 水吧下架 发送数据
        FORMULA_LIKE_SEND = WATER_BAR.NETWORK.FORMULA_LIKE.SEND,   -- 配方喜爱 发送数据
        PUTAWAY_LIMIT_NUM = { _int = 1, _key = 'putawayLimitNum' }, -- 上架上限数量
        PUTAWAY_DRINK_NUM = { _int = 1, _key = 'putawayDrinkNum' }, -- 上架饮品数量
        SELECT_DRINK_TYPE = { _int = 1, _key = 'selectDrinkType' }, -- 所选饮料类型
        LIBRARY_DRINK_MAP = { _map = 1, _key = 'libraryDrinkMap',   -- 拥有的饮品 [key:drinkId]
            COUNT = { _int = 1, _key = '$drinkNum' },
        },
        PUTAWAY_DRINK_MAP = { _map = 1, _key = 'putawayDrinkMap',   -- 上架的饮品 [key:drinkId]
            COUNT = { _int = 1, _key = '$drinkNum' },
        },
        FORMULA_DATA_MAP = { _map = 1, _key = 'formulaDataMap',   -- 配方数据
            FORMULA_DATA = { _map = 1, _key = '$formulaData',
                FORMULA_ID   = { _int = 1, _key = 'formulaId' }, -- 配方id
                FORMULA_LIKE = { _int = 1, _key = 'like' },      -- 是否喜爱（0:不喜、1:喜欢）
                FORMULA_STAR = { _int = 1, _key = 'madeStars' }, -- 做到的星级
            },
        },
    }
end


-------------------------------------------------------------------------------
-- 商店相关
-------------------------------------------------------------------------------
do
    WATER_BAR.SHOP = {}

    WATER_BAR.SHOP.PROXY_NAME = 'WATER_BAR.SHOP.PROXY_NAME'

    WATER_BAR.SHOP.PROXY_STRUCT = { _map = 1, _key = WATER_BAR.SHOP.PROXY_NAME,
        SHOP_HOME_TAKE       = WATER_BAR.NETWORK.SHOP_HOME.TAKE,          -- 市场主页 接收数据
        SHOP_BUY_TAKE        = WATER_BAR.NETWORK.SHOP_BUY.TAKE,           -- 市场购买 接收数据
        SHOP_BUY_SEND        = WATER_BAR.NETWORK.SHOP_BUY.SEND,           -- 市场购买 发送数据
        SHOP_MULTI_BUY_TAKE  = WATER_BAR.NETWORK.SHOP_MULTI_BUY.TAKE,     -- 市场批量购买 接收数据
        SHOP_MULTI_BUY_SEND  = WATER_BAR.NETWORK.SHOP_MULTI_BUY.SEND,     -- 市场批量购买 发送数据
        REFRESH_TIMESTAMP    = { _int = 1, _key = 'refreshTimestamp' },   -- 市场刷新的时间戳
        SELECT_PRODUCT_MAP   = { _map = 1, _key = 'selectProductMap',     -- 选择的商品id表 [key:productId]
            PURCHASED_NUM = { _int = 1, _key = '$purchasedNum' }
        },
    }
end


return WATER_BAR
