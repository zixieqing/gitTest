--[[
 * author : kaishiqi
 * descpt : 物品设定 相关定义
]]
local GOODS = {}


-------------------------------------------------------------------------------
-- id定义
-------------------------------------------------------------------------------

GOODS.DEFINE = {
    --                        = water bar
    WATER_BAR_CURRENCY_ID     = 900034, -- 水吧 专用货币id
    WATER_BAR_POPULARITY_ID   = 900035, -- 水吧 知名度id
    WATER_BAR_FREQUENCY_ID    = 900036, -- 水吧 熟客度id
    WATER_BAR_HIDE_FORMULA_ID = 439999, -- 水吧 隐藏饮品的配方id
    --                        = championship
    CHAMPIONSHIP_CURRENCY_ID  = 900029, -- 武道会 专用货币id
    NEW_KOF_CURRENCY_ID       = 900046, -- 新天成演武 专用货币id
}


GOODS.TYPE = {}


return GOODS
