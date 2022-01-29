--[[
 * author : kaishiqi
 * descpt : 周年庆2020 相关定义
]]
local ANNIV2020 = {}

-------------------------------------------------------------------------------
-- 通用定义
-------------------------------------------------------------------------------

ANNIV2020.DEFINE = {
    EXPLORE_FLOOR_MAX  = 30, -- 探索 最大层数
    EXPLORE_FLOOR_BOSS = 10, -- 探索 boss层数
    EXPLORE_MAP_ROWS   = 4,  -- 探索 地图行数
    EXPLORE_MAP_COLS   = 4,  -- 探索 地图列数
}

ANNIV2020.TEAM_STATE = {
    HP = "anniv2020ExploreHp" ,
    ENERGY = "anniv2020ExploreEnergy"
}

-- 探索类型
ANNIV2020.EXPLORE_TYPE = {
    MONSTER_NORMAL = 1, -- 小怪
    MONSTER_ELITE  = 2, -- 精英
    MONSTER_BOSS   = 3, -- boss
    OPTION         = 4, -- 选项
    CHEST          = 5, -- 宝箱
    BUFF           = 6, -- buff
    EMPTY          = 7, -- 空格
}

ANNIV2020.EXPLORE_BUFF_TYPE = {
    MAP_ALL         = 3,
    WEAK_OF_DEAD    = 4,
    COMPLETE_TASK   = 5
}
-- 探索类型配表
---@type  ConfProxy[]
ANNIV2020.EXPLORE_TYPE_CONF = {
    [ANNIV2020.EXPLORE_TYPE.MONSTER_NORMAL] = CONF.ANNIV2020.EXPLORE_MONSTER_NORMAL,
    [ANNIV2020.EXPLORE_TYPE.MONSTER_ELITE]  = CONF.ANNIV2020.EXPLORE_MONSTER_ELITE,
    [ANNIV2020.EXPLORE_TYPE.MONSTER_BOSS]   = CONF.ANNIV2020.EXPLORE_MONSTER_BOSS,
    [ANNIV2020.EXPLORE_TYPE.OPTION]         = CONF.ANNIV2020.EXPLORE_OPTION,
    [ANNIV2020.EXPLORE_TYPE.CHEST]          = CONF.ANNIV2020.EXPLORE_CHEST,
    [ANNIV2020.EXPLORE_TYPE.BUFF]           = CONF.ANNIV2020.EXPLORE_BUFF,
}


-------------------------------------------------------------------------------
-- 网络协议
-------------------------------------------------------------------------------
do
    ANNIV2020.NETWORK = {}


    -------------------------------------------------
    -- 商店主页
    ANNIV2020.NETWORK.SHOP_HOME = {
        POST = POST.ANNIV2020_SHOP_HOME,

        SEND = {},

        TAKE = { _map = 1, _key = 'SHOP_HOME_TAKE',
            PRODUCTS = { _lst = 1, _key = 'products', -- 商品列表
                PRODUCT_DATA = { _map = 1, _key = '$productData', -- 商品数据
                    PRODUCT_ID  = { _int = 1, _key = 'productId' },        -- 商品id
                    GOODS_ID    = { _int = 1, _key = 'goodsId' },          -- 道具id
                    GOODS_NUM   = { _int = 1, _key = 'goodsNum' },         -- 道具数量
                    CURRENCY_ID = { _int = 1, _key = 'currency' },         -- 货币id
                    PRICE_NUM   = { _int = 1, _key = 'price' },            -- 价格
                    ICON_ID     = { _int = 1, _key = 'icon' },             -- 图标id
                    ICON_TITLE  = { _str = 1, _key = 'iconTitle' },        -- 图标标题
                    OPEN_LEVEL  = { _int = 1, _key = 'openLevel' },        -- 开启等级
                    STOCK_TOTAL = { _int = 1, _key = 'stock' },            -- 可购买次数
                    STOCK_LEFT  = { _int = 1, _key = 'leftPurchasedNum' }, -- 剩余购买次数
                    ACTIVITY    = { _int = 1, _key = 'activity' },         -- 是否活动道具（0：否，1：是）
                },
            },
        },
    }


    -- 商店购买
    ANNIV2020.NETWORK.SHOP_BUY = {
        POST = POST.ANNIV2020_SHOP_BUY,

        SEND = { _map = 1, _key = 'SHOP_BUY_SEND',
            PRODUCT_ID  = { _str = 1, _key = 'productId' }, -- 商品ID
            PRODUCT_NUM = { _int = 1, _key = 'num' },       -- 商品数量
        },

        TAKE = { _map = 1, _key = 'SHOP_BUY_TAKE',
            REWARDS = { _lst = 1, _key = 'rewards', -- 奖励列表
                GOODS_DATA = { _map = 1, _key = '$goods', -- 物品数据
                    GOODS_ID        = { _int = 1, _key = 'goodsId'},       -- 物品ID
                    GOODS_NUM       = { _int = 1, _key = 'num'},           -- 物品数量
                    PLAYER_CARD_ID  = { _int = 1, _key = 'playerCardId'},  -- 卡牌uuid（购买整卡返回）
                    PLAYER_PET_DATA = { _map = 1, _key = "playerPet",      -- 宠物数据（购买堕神返回）
                        PLAYER_ID          = { _int = 1, _key = "playerId"},
                        PET_UUID           = { _int = 1, _key = "id"},
                        PET_ID             = { _int = 1, _key = "petId"},
                        PET_LV             = { _int = 1, _key = "level"},
                        PET_EXP            = { _int = 1, _key = "exp"},
                        PET_BLV            = { _int = 1, _key = "breakLevel"},
                        CHARACTER          = { _int = 1, _key = "character"},
                        CREATE_TIME        = { _str = 1, _key = "createTime"},
                        IS_PROTECT         = { _int = 1, _key = "isProtect"},
                        IS_EVOLUTION       = { _int = 1, _key = "isEvolution"},
                        EXT_ATTR_TYPE_1    = { _int = 1, _key = "extraAttrType1"},
                        EXT_ATTR_NUM_1     = { _int = 1, _key = "extraAttrNum1"},
                        EXT_ATTR_QUALITY_1 = { _int = 1, _key = "extraAttrQuality1"},
                        EXT_ATTR_TYPE_2    = { _int = 1, _key = "extraAttrType2"},
                        EXT_ATTR_NUM_2     = { _int = 1, _key = "extraAttrNum2"},
                        EXT_ATTR_QUALITY_2 = { _int = 1, _key = "extraAttrQuality2"},
                        EXT_ATTR_TYPE_3    = { _int = 1, _key = "extraAttrType3"},
                        EXT_ATTR_NUM_3     = { _int = 1, _key = "extraAttrNum3"},
                        EXT_ATTR_QUALITY_3 = { _int = 1, _key = "extraAttrQuality3"},
                        EXT_ATTR_TYPE_4    = { _int = 1, _key = "extraAttrType4"},
                        EXT_ATTR_NUM_4     = { _int = 1, _key = "extraAttrNum4"},
                        EXT_ATTR_QUALITY_4 = { _int = 1, _key = "extraAttrQuality4"},
                    },
                },
            },
        },
    }


    -- 商店批量购买
    ANNIV2020.NETWORK.SHOP_MULTI_BUY = {
        POST = POST.ANNIV2020_SHOP_MULTI_BUY,

        SEND = { _map = 1, _key = 'SHOP_MULTI_BUY_SEND',
            PRODUCT_IDS = { _str = 1, _key = 'products' },  -- 商品ID们（逗号分隔）
        },

        TAKE = { _map = 1, _key = 'SHOP_MULIT_BUY_TAKE',
            REWARDS = ANNIV2020.NETWORK.SHOP_BUY.TAKE.REWARDS, -- 奖励列表
        },
    }
end


-------------------------------------------------------------------------------
-- 商店相关
-------------------------------------------------------------------------------
do
    ANNIV2020.SHOP = {}

    ANNIV2020.SHOP.TYPE_ENUM = {
        ALL      = 0, -- 显示全部
        SEARCH   = 1, -- 索索道具
        ACTIVITY = 2, -- 活动道具
        COMMON   = 3, -- 普通道具
    }

    ANNIV2020.SHOP.PROXY_NAME = 'ANNIV2020.SHOP.PROXY_NAME'

    ANNIV2020.SHOP.PROXY_STRUCT = { _map = 1, _key = ANNIV2020.SHOP.PROXY_NAME,
        SHOP_HOME_TAKE      = ANNIV2020.NETWORK.SHOP_HOME.TAKE,       -- 市场主页 接收数据
        SHOP_BUY_TAKE       = ANNIV2020.NETWORK.SHOP_BUY.TAKE,        -- 市场购买 接收数据
        SHOP_BUY_SEND       = ANNIV2020.NETWORK.SHOP_BUY.SEND,        -- 市场购买 发送数据
        SHOP_MULTI_BUY_TAKE = ANNIV2020.NETWORK.SHOP_MULTI_BUY.TAKE,  -- 市场批量购买 接收数据
        SHOP_MULTI_BUY_SEND = ANNIV2020.NETWORK.SHOP_MULTI_BUY.SEND,  -- 市场批量购买 发送数据
        SEARCH_GOODS_ID     = { _int = 1, _key = 'searchGoodsId' },   -- 搜索的道具id
        SELECT_TYPE         = { _int = 1, _key = 'selectType' },      -- 所选类型
        SELECT_PRODUCT_MAP   = { _map = 1, _key = 'selectProductMap', -- 选择的商品id表 [key:productId]
            PURCHASED_NUM = { _int = 1, _key = '$purchasedNum' }
        },
    }
end


return ANNIV2020
