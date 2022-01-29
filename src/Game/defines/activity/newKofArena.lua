--[[
 * author : kaishiqi
 * descpt : 水吧功能 相关定义
]]
local NEW_KOF = {}


-------------------------------------------------------------------------------
-- 网络协议
-------------------------------------------------------------------------------
do
    NEW_KOF.NETWORK = {}


    -------------------------------------------------
    -- 商店主页
    NEW_KOF.NETWORK.SHOP_HOME = {
        POST = POST.NEW_TAG_MATCH_MALL,

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
    NEW_KOF.NETWORK.SHOP_BUY = {
        POST = POST.NEW_TAG_MATCH_BUY,

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
    NEW_KOF.NETWORK.SHOP_MULTI_BUY = {
        POST = POST.NEW_TAG_MATCH_MALL_BUY_MULTI,

        SEND = { _map = 1, _key = 'SHOP_MULTI_BUY_SEND',
            PRODUCT_IDS = { _str = 1, _key = 'products' },  -- 商品ID们（逗号分隔）
        },

        TAKE = { _map = 1, _key = 'SHOP_MULIT_BUY_TAKE',
            REWARDS = NEW_KOF.NETWORK.SHOP_BUY.TAKE.REWARDS, -- 奖励列表
        },
    }
end


-------------------------------------------------------------------------------
-- 商店相关
-------------------------------------------------------------------------------
do
    NEW_KOF.SHOP = {}

    NEW_KOF.SHOP.PROXY_NAME = 'NEW_KOF.SHOP.PROXY_NAME'

    NEW_KOF.SHOP.PROXY_STRUCT = { _map = 1, _key = NEW_KOF.SHOP.PROXY_NAME,
        SHOP_HOME_TAKE       = NEW_KOF.NETWORK.SHOP_HOME.TAKE,          -- 市场主页 接收数据
        SHOP_BUY_TAKE        = NEW_KOF.NETWORK.SHOP_BUY.TAKE,           -- 市场购买 接收数据
        SHOP_BUY_SEND        = NEW_KOF.NETWORK.SHOP_BUY.SEND,           -- 市场购买 发送数据
        SHOP_MULTI_BUY_TAKE  = NEW_KOF.NETWORK.SHOP_MULTI_BUY.TAKE,     -- 市场批量购买 接收数据
        SHOP_MULTI_BUY_SEND  = NEW_KOF.NETWORK.SHOP_MULTI_BUY.SEND,     -- 市场批量购买 发送数据
        REFRESH_TIMESTAMP    = { _int = 1, _key = 'refreshTimestamp' },   -- 市场刷新的时间戳
        SELECT_PRODUCT_MAP   = { _map = 1, _key = 'selectProductMap',     -- 选择的商品id表 [key:productId]
            PURCHASED_NUM = { _int = 1, _key = '$purchasedNum' }
        },
    }
end


return NEW_KOF
