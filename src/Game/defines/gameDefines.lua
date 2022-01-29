--[[
 * author : kaishiqi
 * descpt : 初始化游戏功能定义
]]
FOOD = {}


copyStruct = function(defineStruct, newKey)
    local newStruct = clone(defineStruct)
    newStruct._key  = newKey
    return newStruct
end


-------------------------------------------------------------------------------
-- 基础定义
-------------------------------------------------------------------------------

FOOD.COMMON = require('Game.defines.base.common')

FOOD.GOODS = require('Game.defines.base.goods')


-------------------------------------------------------------------------------
-- 历练相关
-------------------------------------------------------------------------------

FOOD.CHAMPIONSHIP = require('Game.defines.trials.championship')


-------------------------------------------------------------------------------
-- 家园相关
-------------------------------------------------------------------------------

FOOD.WATER_BAR = require('Game.defines.homeLand.waterBar')


-------------------------------------------------------------------------------
-- 活动相关
-------------------------------------------------------------------------------

FOOD.ANNIV2020 = require('Game.defines.activity.anniv2020')

FOOD.NEW_KOF = require('Game.defines.activity.newKofArena')
