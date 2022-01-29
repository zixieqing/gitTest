--[[
 * author : kaishiqi
 * descpt : 道具工具类
--]]
GoodsUtils = {}

--================================================================================================
-- defines
--================================================================================================

-- cut from dataMgr
COOK_ID                           = 900005 -- 厨力点 id
HP_ID                             = 900003 -- 体力的id
GOLD_ID                           = 900002 -- 金币的id
DIAMOND_ID                        = 900001 -- 幻晶石的id
FTPOINT_ID                        = 900020 -- 点券
REPUTATION_ID                     = 900026 -- 商会的声望值
EXP_ID                            = 979999 -- 玩家经验值id
CARD_EXP_ID                       = 979998 -- 卡牌经验值id
POPULARITY_ID                     = 900006 -- 知名度
TIPPING_ID                        = 900007 -- 餐厅小费
UNION_POINT_ID                    = 900009 -- 工会币
ACTIVITY_QUEST_HP                 = 900010 -- 活动副本体力
KOF_CURRENCY_ID                   = 900011 -- 拳皇竞技场货币
NEW_KOF_CURRENCY_ID               = 900046 -- 新天成演武 专用货币id
SUMMER_ACTIVITY_HP_ID             = 900012 -- 18夏活行动力

CRYSTAL_ID                        = 350001 -- cg碎片转换器
SAIMOE_POWER_ID                   = 900021 -- 应援力
PAID_DIAMOND_ID                   = 900022 -- 付费钻石
PASS_TICKET_ID                    = 900024 -- pass卡入场券
SPRING_19_TICKET_ID               = 900025 -- 19春活入场券
MEMORY_CURRENCY_M_ID              = 900038 -- 记忆商店m卡商店货币
MEMORY_CURRENCY_SP_ID             = 900039 -- 记忆商店sp卡商店货币
FREE_DIAMOND_ID                   = 9111111 -- 免费钻石（为了统一处理定义个常量）
SUPER_GET_ID                      = 880109 -- 超得道具
PVC_POINT_ID                      = 9999997 -- 竞技场积分id
PVC_MEDAL_ID                      = 900008 -- 竞技场勋章id
PVC_ACTIVE_POINT_ID               = 9999998 -- 竞技场活跃度id
UNION_BEAST_ENERGY_ID             = 899001 -- 神兽能量id
FOOD_RESIDUE_ID                   = 199980 -- 料理残渣
UNION_HIGH_ROLL_ID                = 890009 --
UNIVERSAL_PET_ID                  = 890011 --
EVOLUTION_STONE_ID                = 890012 --
UNIVERSAL_UR_ARTIFACT_FRAGMENT_ID = 890016 --
UNIVERSAL_SR_ARTIFACT_FRAGMENT_ID = 890015 --
UNIVERSAL_R_ARTIFACT_FRAGMENT_ID  = 890014 --
EXPLORE_ACCELERATE_ID             = 890021 -- 探索加速劵
WATER_CRYSTALLIZATION_ID          = 890022 -- 水结晶
WIND_CRYSTALLIZATION_ID           = 890023 -- 风结晶
RAY_CRYSTALLIZATION_ID            = 890024 -- 雷结晶
FISH_POPULARITY_ID                = 900013 -- 钓场人气度
ARTIFACT_ROAD_TICKET              = 890038 -- 神器之路门票
UNION_CONTRIBUTION_POINT_ID       = 9999999 -- 工会贡献值积分
HIGHESTPOPULARITY_ID              = 100000002 -- 最高知名度
GREEN_TEA_ID                      = 150052 --
SWEEP_QUEST_ID                    = 890001 -- 扫荡券
CAPSULE_VOUCHER_ID                = 890002 -- 抽卡券
SKIN_COUPON_ID                    = 890006 -- 皮肤卷
AGENT_COUPON_ID                   = 890007 -- 委托券
MAGIC_INK_ID                      = 890010 -- 魔法墨水
LUXURY_BENTO_ID                   = 890013 -- 豪华餐盒
YEARS_WINS_ID                     = 880005 -- 岁酒
DOOR_GUN_ID                       = 880016 -- 开门炮
SUMMER_ACTIVITY_LAMP_ID           = 880057 -- 夏活神灯
CARNIE_GAME_COIN                  = 880058 -- 游戏币（游乐场）
CARNIE_SPRING_19_GAME_COIN        = 880127 -- 19 春活 游戏币（游乐场）
CARNIE_SPRING_19_LAMP_ID          = 880128 -- 19 春活 神灯
PET_DEVELOP_WATERING_ID           = 890003 -- 灵体净化浇灌道具类型
CAT_COPPER_COIN_ID                = 900042 -- 喵铜币
CAT_SILVER_COIN_ID                = 900043 -- 喵银币
CAT_GOLD_COIN_ID                  = 900044 -- 喵金币
CAT_STUDY_COIN_ID                 = 900045 -- 喵学习币
MID_AUTUMN_BOX_ID                 = 121001 -- 中秋礼盒
VIGOUR_RECOVERY_GOODS_ID          = {180004, 180005, 180001, 180003}


-- 道具类型
GoodsType = {
    TYPE_UNKNOWN              = '00', -- 未知的
    TYPE_AVATAR               = '10', -- 餐厅avatar
    TYPE_DIAMOND              = '11', -- 幻晶石
    TYPE_GOLD                 = '12', -- 金币
    TYPE_EXP_ITEM             = '13', -- 经验道具
    TYPE_CARD_FRAGMENT        = '14', -- 卡牌碎片
    TYPE_FOOD                 = '15', -- 食物
    TYPE_FOOD_MATERIAL        = '16', -- 食材
    TYPE_UPGRADE_ITEM         = '17', -- 升级用消耗材料
    TYPE_MAGIC_FOOD           = '18', -- 魔法食物
    TYPE_GOODS_CHEST          = '19', -- 道具礼包
    TYPE_CARD                 = '20', -- 卡牌
    TYPE_PET                  = '21', -- 堕神
    TYPE_RECIPE               = '22', -- 食谱
    TYPE_SEASONING            = '23', -- 调料
    TYPE_PET_EGG              = '24', -- 堕神灵体
    TYPE_CARD_SKIN            = '25', -- 卡牌皮肤
    TYPE_UN_STABLE            = '26', -- 不稳定道具
    TYPE_THEME                = '27', -- 餐厅avatar主题
    TYPE_GEM                  = '28', -- 宝石
    TYPE_ARTIFACR             = '29', -- 神器碎片
    TYPE_BAIT                 = '32', -- 钓场钓饵
    TYPE_PRIVATEROOM_THEME    = '33', -- 包厢主题
    TYPE_PRIVATEROOM_SOUVENIR = '34', -- 包厢纪念品
    TYPE_CRYSTAL              = '35', -- 转换CG 碎片的水晶
    TYPE_CG_FRAGMENT          = '36', -- CG的碎片
    TYPE_APPOINT_PET          = '37', -- 指定堕神
    TYPE_EXP                  = '38', -- 经验加成道具
    TYPE_TTGAME_CARD          = '39', -- ttGame卡牌
    TYPE_TTGAME_PACK          = '40', -- ttGame卡包
    TYPE_WATERBAR_MATERIALS   = '41', -- 水吧材料
    TYPE_WATERBAR_DRINKS      = '42', -- 水吧饮品
    TYPE_WATERBAR_FORMULA     = '43', -- 水吧配方
    TYPE_ACTIVITY_CHEST       = '45', -- 宝箱活动
    TYPE_ARCHIVE_REWARD       = '50', -- 成就
    TYPE_HOUSE_AVATAR         = '60', -- 猫屋avatar
    TYPE_HOUSE_STYLE          = '61', -- 猫屋样式
    TYPE_CAT_GOODS            = '62', -- 猫咪道具
    TYPE_ACTIVITY             = '88', -- 活动类别
    TYPE_OTHER                = '89', -- 其他(券)
    TYPE_MONEY                = '90', -- 通用货币
    TYPE_OPTIONAL_CHEST       = '98', -- 可选礼包
}


-- 道具类型定义
local GOODS_TYPE_DEFINES = {
    [GoodsType.TYPE_AVATAR]               = {lower = 101001, upper = 110000},  -- 餐厅avatar
    [GoodsType.TYPE_DIAMOND]              = {lower = 110000, upper = 120000},  -- 钻石道具
    [GoodsType.TYPE_GOLD]                 = {lower = 120000, upper = 130000},  -- 金币道具
    [GoodsType.TYPE_EXP_ITEM]             = {lower = 130000, upper = 140000},  -- 经验道具
    [GoodsType.TYPE_CARD_FRAGMENT]        = {lower = 140000, upper = 150000},  -- 卡牌碎片
    [GoodsType.TYPE_FOOD]                 = {lower = 150000, upper = 160000},  -- 食物
    [GoodsType.TYPE_FOOD_MATERIAL]        = {lower = 160000, upper = 170000},  -- 食材
    [GoodsType.TYPE_UPGRADE_ITEM]         = {lower = 170000, upper = 180000},  -- 升级用消耗材料
    [GoodsType.TYPE_MAGIC_FOOD]           = {lower = 180000, upper = 190000},  -- 魔法食物
    [GoodsType.TYPE_GOODS_CHEST]          = {lower = 190000, upper = 200000},  -- 道具礼包
    [GoodsType.TYPE_CARD]                 = {lower = 200000, upper = 210000},  -- 卡牌
    [GoodsType.TYPE_PET]                  = {lower = 210000, upper = 220000},  -- 堕神
    [GoodsType.TYPE_RECIPE]               = {lower = 220000, upper = 230000},  -- 食谱
    [GoodsType.TYPE_SEASONING]            = {lower = 230000, upper = 240000},  -- 调料
    [GoodsType.TYPE_PET_EGG]              = {lower = 240000, upper = 250000},  -- 堕神灵体
    [GoodsType.TYPE_CARD_SKIN]            = {lower = 250000, upper = 260000},  -- 卡牌皮肤
    [GoodsType.TYPE_UN_STABLE]            = {lower = 260000, upper = 270000},  -- 不稳定道具
    [GoodsType.TYPE_THEME]                = {lower = 270000, upper = 280000},  -- 餐厅avatar主题
    [GoodsType.TYPE_GEM]                  = {lower = 280000, upper = 290000},  -- 宝石
    [GoodsType.TYPE_ARTIFACR]             = {lower = 290000, upper = 300000},  -- 神器碎片
    [GoodsType.TYPE_BAIT]                 = {lower = 321000, upper = 321100},  -- 钓场钓饵
    [GoodsType.TYPE_PRIVATEROOM_THEME]    = {lower = 330000, upper = 340000},  -- 包厢主题
    [GoodsType.TYPE_PRIVATEROOM_SOUVENIR] = {lower = 340000, upper = 350000},  -- 包厢纪念品
    [GoodsType.TYPE_CRYSTAL]              = {lower = 350000, upper = 360000},  -- 转换cg碎片的水晶
    [GoodsType.TYPE_CG_FRAGMENT]          = {lower = 360000, upper = 370000},  -- cg碎片
    [GoodsType.TYPE_APPOINT_PET]          = {lower = 370000, upper = 380000},  -- 指定堕神
    [GoodsType.TYPE_EXP]                  = {lower = 380000, upper = 390000},  -- 使用主角经验道具
    [GoodsType.TYPE_TTGAME_CARD]          = {lower = 390000, upper = 400000},  -- ttgame卡牌
    [GoodsType.TYPE_TTGAME_PACK]          = {lower = 400000, upper = 410000},  -- ttgame卡包
    [GoodsType.TYPE_WATERBAR_MATERIALS]   = {lower = 410000, upper = 420000},  -- 水吧材料
    [GoodsType.TYPE_WATERBAR_DRINKS]      = {lower = 420000, upper = 430000},  -- 水吧饮品
    [GoodsType.TYPE_WATERBAR_FORMULA]     = {lower = 430000, upper = 440000},  -- 水吧配方
    [GoodsType.TYPE_ACTIVITY_CHEST]       = {lower = 450000, upper = 460000},  -- 宝箱活动
    [GoodsType.TYPE_ARCHIVE_REWARD]       = {lower = 500001, upper = 510000},  -- 成就
    [GoodsType.TYPE_HOUSE_AVATAR]         = {lower = 600001, upper = 610000},  -- 猫屋avatar
    [GoodsType.TYPE_HOUSE_STYLE]          = {lower = 610001, upper = 620000},  -- 猫屋个人样式
    [GoodsType.TYPE_CAT_GOODS]            = {lower = 620001, upper = 630000},  -- 猫咪道具
    [GoodsType.TYPE_ACTIVITY]             = {lower = 880001, upper = 890000},  -- 活动类别
    [GoodsType.TYPE_OTHER]                = {lower = 890000, upper = 900000},  -- 其他
    [GoodsType.TYPE_MONEY]                = {lower = 900001, upper = 980000},  -- 通用货币
    [GoodsType.TYPE_OPTIONAL_CHEST]       = {lower = 980000, upper = 1000000}, -- 可选礼包
}


-- 道具图标定义
--[[
    nomalPath : func    普通图标路径。
    largePath : func    大图标路径，如果需要有大图标的话则定义出来。 (optional)
    defaultId : func     默认物品id，当正常id获取不到时，会使用默认id的图标。 (optional)
    confValue : str     物品读表获取图标的规则。(optional)
]]
local GOODS_ICON_DEFINES = {
    [EXP_ID]                      = { nomalPath = function(id) return _res('ui/common/common_ico_exp.png') end },
    [CARD_EXP_ID]                 = { nomalPath = function(id) return _res('ui/common/common_ico_cardexp.png') end },
    [POPULARITY_ID]               = { nomalPath = function(id) return _res('ui/common/common_ico_fame.png') end },
    [PVC_POINT_ID]                = { nomalPath = function(id) return _res('ui/pvc/pvp_ico_point.png') end },
    [PVC_ACTIVE_POINT_ID]         = { nomalPath = function(id) return _res('ui/pvc/pvp_ico_vitality.png') end },
    [UNION_CONTRIBUTION_POINT_ID] = { nomalPath = function(id) return _res('ui/union/guild_ico_CTBpoint.png') end },
    [UNION_HIGH_ROLL_ID]          = { nomalPath = function(id) return _res(string.fmt('arts/goods/goods_icon_%1.png', id)) end },
    [ACTIVITY_QUEST_HP]           = { nomalPath = function(id) return _res(string.fmt('arts/goods/goods_icon_%1.png', id)) end },
    [PAID_DIAMOND_ID]             = { nomalPath = function(id) return _res(string.fmt('arts/goods/goods_icon_%1.png', DIAMOND_ID)) end },
    [GoodsType.TYPE_UNKNOWN] = {
        nomalPath = function(id) return _res(string.fmt('arts/goods/goods_icon_%1.png', id)) end,
        largePath = function(id) return _res(string.fmt('arts/goods_big/goods_icon_%1.png', id)) end,
    },
    [GoodsType.TYPE_WATERBAR_DRINKS] = {
        confValue = function(id) return GoodsUtils.GetGoodsConfById(id)['photoId'] end,
        nomalPath = function(id) return _res(string.fmt('arts/waterBar/goodsSmall/goods_icon_%1.png', id)) end,
        largePath = function(id) return _res(string.fmt('arts/waterBar/goodsBig/goods_icon_%1.png', id)) end,
    },
    [GoodsType.TYPE_WATERBAR_FORMULA] = {
        confValue = function(id) return GoodsUtils.GetGoodsConfById(id)['photoId'] end,
        nomalPath = function(id) return _res(string.fmt('arts/waterBar/goodsSmall/goods_icon_%1.png', id)) end,
        largePath = function(id) return _res(string.fmt('arts/waterBar/goodsBig/goods_icon_%1.png', id)) end,
    },
    [GoodsType.TYPE_WATERBAR_MATERIALS] = {
        confValue = function(id) return GoodsUtils.GetGoodsConfById(id)['photoId'] end,
        nomalPath = function(id) return _res(string.fmt('arts/waterBar/goodsSmall/goods_icon_%1.png', id)) end,
        largePath = function(id) return _res(string.fmt('arts/waterBar/goodsBig/goods_icon_%1.png', id)) end,
    },
    [GoodsType.TYPE_TTGAME_PACK] = {
        confValue = function(id) return checktable(CommonUtils.GetConfig('goods', 'battleCardPack', id))['photoId'] end,
        nomalPath = function(id) return _res(string.fmt('arts/ttgame/goods/goods_icon_%1.png', id)) end,
    },
    [GoodsType.TYPE_TTGAME_CARD] = {
        confValue = function(id) return checktable(TTGameUtils.GetConfAt(TTGAME_DEFINE.CONF_TYPE.NPC_DEFINE, id))['id'] end,
        nomalPath = function(id) return _res(string.fmt('arts/ttgame/card/cardgame_card_%1.png', id)) end,
    },
    [GoodsType.TYPE_OPTIONAL_CHEST] = {
        confValue = function(id) return checktable(CommonUtils.GetConfig('goods', 'optionalChest', id))['photoId'] end,
        nomalPath = function(id) return _res(string.fmt('arts/goods/goods_icon_%1.png', id)) end,
    },
    [GoodsType.TYPE_GOODS_CHEST] = {
        confValue = function(id) return checktable(CommonUtils.GetConfig('goods', 'chest', id))['photoId'] end,
        nomalPath = function(id) return _res(string.fmt('arts/goods/goods_icon_%1.png', id)) end,
    },
    [GoodsType.TYPE_ACTIVITY] = {
        confValue = function(id) return checktable(CommonUtils.GetConfig('goods', 'activity', id))['photoId'] end,
        nomalPath = function(id) return _res(string.fmt('arts/goods/goods_icon_%1.png', id)) end,
    },
    [GoodsType.TYPE_EXP] = {
        confValue = function(id) return checktable(CommonUtils.GetConfig('goods', 'expBuff', id))['photoId'] end,
        nomalPath = function(id) return _res(string.fmt('arts/goods/goods_icon_%1.png', id)) end,
    },
    [GoodsType.TYPE_OTHER] = {
        confValue = function(id) return GoodsUtils.GetGoodsConfById(id)['photoId'] end,
        nomalPath = function(id) return _res(string.fmt('arts/goods/goods_icon_%1.png', id)) end,
        largePath = function(id) return _res(string.fmt('arts/goods_big/goods_icon_%1.png', id)) end,
    },
    [GoodsType.TYPE_CG_FRAGMENT] = {
        confValue = function(id) return GoodsUtils.GetGoodsConfById(id)['photoId'] end,
        nomalPath = function(id) return _res(string.fmt('arts/goods/goods_icon_%1.png', id)) end,
    },
    [GoodsType.TYPE_UN_STABLE] = {
        confValue = function(id) return checktable(CommonUtils.GetConfig('goods', 'unstable', id))['photoId'] end,
        nomalPath = function(id) return _res(string.fmt('arts/goods/goods_icon_%1.png', id)) end,
    },
    [GoodsType.TYPE_GEM] = {
        nomalPath = function(id) return _res(string.fmt('arts/artifact/small/goods_icon_%1.png', id)) end,
        largePath = function(id) return _res(string.fmt('arts/artifact/big/goods_icon_%1.png', id)) end,
        defaultId = function(id) return 280001 end,
    },
    [GoodsType.TYPE_ARTIFACR] = {
        nomalPath = function(id) return _res(string.fmt('arts/artifact/small/core_icon_%1.png', id)) end,
        largePath = function(id) return _res(string.fmt('arts/artifact/big/core_icon_%1.png', id)) end,
        defaultId = function(id) return 280001 end,
    },
    [GoodsType.TYPE_AVATAR] = {
        nomalPath = function(id) return AssetsUtils.GetRestaurantSmallAvatarPath(id) end,
        defaultId = function(id) return 101001 end,
    },
    [GoodsType.TYPE_THEME] = {
        nomalPath = function(id) return _res(string.fmt('avatar/small/theme_pic_%1_s.jpg', id)) end,
        largePath = function(id) return _res(string.fmt('avatar/theme_pic_%1.jpg', id)) end,
        defaultId = function(id) return 270003 end,
    },
    [GoodsType.TYPE_CARD] = {
        nomalPath = function(id) return CardUtils.GetCardHeadPathByCardId(id) end,
        defaultId = function(id) return 200001 end,
    },
    [GoodsType.TYPE_CARD_SKIN] = {
        nomalPath = function(id) return CardUtils.GetCardHeadPathBySkinId(id) end,
        defaultId = function(id) return 200001 end,
    },
    [GoodsType.TYPE_CARD_FRAGMENT] = {
        nomalPath = function(id) return AssetsUtils.GetCardHeadPath( checkint(id) + 60000) end,
    },
    [GoodsType.TYPE_PET] = {
        confValue = function(id) return checktable(CommonUtils.GetConfig('pet', 'pet', id))['drawId'] end,
        nomalPath = function(id) return AssetsUtils.GetCardHeadPath(id) end,
    },
    [GoodsType.TYPE_PET_EGG] = {
        confValue = function(id) return checktable(CommonUtils.GetConfig('pet', 'petEgg', id))['drawId'] end,
        nomalPath = function(id) return AssetsUtils.GetCardHeadPath(id) end,
    },
    [GoodsType.TYPE_APPOINT_PET] = {
        confValue = function(id) return checktable(CommonUtils.GetConfig('goods', 'petConvert', id))['photoId'] end,
        nomalPath = function(id) return AssetsUtils.GetCardHeadPath(id) end,
    },
    [GoodsType.TYPE_FOOD] = {
        confValue = function(id) return 151000 > checkint(id) and id or checkint(id) - 1000 end,
        nomalPath = function(id) return _res(string.fmt('arts/goods/goods_icon_%1.png', id)) end,
        largePath = function(id) return _res(string.fmt('arts/goods_big/goods_icon_%1.png', id)) end,
    },
    [GoodsType.TYPE_ARCHIVE_REWARD] = {
        confValue = function(id) return {id = id, type = checktable(CommonUtils.GetConfig('goods', 'achieveReward', id))['rewardType']} end,
        nomalPath = function(vo) return _res(string.fmt('ui/head/avator_%1_%2.png', ({'trophy', 'icon', 'frame'})[checkint(vo.type)], vo.id)) end,
    },
    [GoodsType.TYPE_HOUSE_AVATAR] = {
        nomalPath = function(id) return AssetsUtils.GetCatHouseSmallAvatarPath(id) end,
        defaultId = function(id) return 600001 end,
    },
    [GoodsType.TYPE_HOUSE_STYLE] = {
        nomalPath = function(id) return _res(string.fmt('arts/catHouse/itemStyle/cat_icon_%1.png', id)) end,
        defaultId = function(id) return CatHouseUtils.GetDressDefaultIdByGoodsId(id) end,
    },
    [GoodsType.TYPE_CAT_GOODS] = {
        confValue = function(id) return GoodsUtils.GetGoodsConfById(id)['photoId'] end,
        nomalPath = function(id) return _res(string.fmt('arts/catHouse/catGoods/goods_icon_%1.png', id)) end,
    }
}


-- 道具名字方法定义
local GOODS_NAME_DEFINES = {
	[GOLD_ID]       = function() return __('金币') end,
	[DIAMOND_ID]    = function() return __('幻晶石') end,
	[HP_ID]         = function() return __('体力') end,
	[EXP_ID]        = function() return __('经验值') end,
	[POPULARITY_ID] = function() return __('知名度') end,
}


--================================================================================================
-- method
--================================================================================================

--[[
    获取道具类型，根据道具id
    @params goodsId   : int    道具id
    @return GoodsType : str    道具类型
--]]
function GoodsUtils.GetGoodsTypeById(goodsId)
    local goodsType = nil
    local goodsId   = checkint(goodsId)
    if 0 < goodsId then
        for type, config in pairs(GOODS_TYPE_DEFINES) do
            if goodsId >= config.lower and goodsId < config.upper then
                goodsType = type
                break
            end
        end
    end
    return goodsType
end


--[[
    获取道具配表，根据道具id
    @params goodsId : int    道具id
]]
function GoodsUtils.GetGoodsConfById(goodsId)
    return CommonUtils.GetConfig('goods', 'goods', goodsId) or {}
end


--[[
    获取道具品质，根据道具id
    @params goodsId   : int    道具id
    @return qualityId : int    道具品质
]]
function GoodsUtils.GetGoodsQualityById(goodsId)
    local goodsId   = checkint(goodsId)
    local goodsType = GoodsUtils.GetGoodsTypeById(goodsId)
    local qualityId = 1

    if GoodsType.TYPE_PET == goodsType then
        qualityId = app.petMgr.GetPetQualityByPetId(goodsId)
    else
        local goodsConf = GoodsUtils.GetGoodsConfById(goodsId)
        if goodsConf.quality then
            qualityId = checkint(goodsConf.quality)
        end
    end
    return qualityId
end


--[[
    获取道具名字，根据道具id
    @params goodsId   : int    道具id
    @return goodsName : str    道具名字
]]
function GoodsUtils.GetGoodsNameById(goodsId)
    local goodsId   = checkint(goodsId)
    local nameFunc  = GOODS_NAME_DEFINES[goodsId]
    local goodsName = ''
    if nameFunc then
        goodsName = nameFunc()
    else
        local goodsConf = GoodsUtils.GetGoodsConfById(goodsId)
        if next(goodsConf) == nil then
            goodsName = string.fmt(__('_id_不存在'), {_id_ = tostring(goodsId)})
        else
            goodsName = tostring(goodsConf.name)
        end
    end
    return goodsName
end


--[[
    道具是否进背包
    @params goodsId  : int     道具id
    @return isHidden : bool    是否进背包
--]]
function GoodsUtils.IsHiddenGoods(goodsId)
    local hideConf = CONF.GOODS.HIDDEN:GetValue(goodsId)
    return checkint(hideConf) > 0
end


--[[
    获取道具图标路径，根据道具id
    @params goodsId  : int     道具id
    @params isBig    : bool    是否大图
    @return iconPath : str     图标路径
]]
function GoodsUtils.GetIconPathById(goodsId, isBig)
    local goodsId   = checkint(goodsId)
    local goodsType = GoodsUtils.GetGoodsTypeById(goodsId)
    local iconName  = tostring(goodsId)
    local iconPath  = ''

    if goodsId >= 101 and goodsId <= 999 then
        iconPath = _res(string.format( 'arts/union/head/guild_head_%s.png', iconName))

    elseif GoodsType.TYPE_RECIPE == goodsType then
        local recipeConf    = CommonUtils.GetConfig('cooking', 'recipe', goodsId) or {}
        local recipeGoodsId = checktable(checktable(recipeConf.foods)[1]).goodsId
        iconPath = GoodsUtils.GetIconPathById(recipeGoodsId, isBig)

    else
        local iconDefine = GOODS_ICON_DEFINES[goodsId] or GOODS_ICON_DEFINES[goodsType] or GOODS_ICON_DEFINES[GoodsType.TYPE_UNKNOWN]
        if iconDefine then
            
            -- conf value
            if iconDefine.confValue then
                iconName = iconDefine.confValue(goodsId)
            end

            -- large path
            if isBig and iconDefine.largePath then
                iconPath = iconDefine.largePath(iconName)
    
                if not app.gameResMgr:isExistent(iconPath) and iconDefine.defaultId then
                    iconPath = iconDefine.largePath(iconDefine.defaultId(goodsId))
                end
    
            -- nomal path
            elseif iconDefine.nomalPath then
                iconPath = iconDefine.nomalPath(iconName)
    
                if not app.gameResMgr:isExistent(iconPath) and iconDefine.defaultId then
                    iconPath = iconDefine.nomalPath(iconDefine.defaultId(goodsId))
                end
            end
    
            -- error path
            if not app.gameResMgr:isExistent(iconPath) then
                iconPath = _res('arts/goods/goods_icon_error.png')
            end
        end
    end
    return iconPath
end


--[[
    获取道具图标节点，根据道具id（Ps：推荐用这个方法，少用 GetIconPathById，因为可能存在拼合图标）
    @params goodsId      : int        道具id
    @params posX         : int        x坐标
    @params posY         : int        y坐标
    @params params       : table      @see display.newImageView(x, y, params)
    @params params.isBig : bool       是否大图
    @return iconNode     : cc.Node    道具图标节点
]]
function GoodsUtils.GetIconNodeById(goodsId, posX, posY, params)
    local goodsConf = GoodsUtils.GetGoodsConfById(goodsId) or {}
    local iconPath  = GoodsUtils.GetIconPathById(goodsId, checktable(params).isBig)
    local iconNode  = display.newImageView(iconPath, posX, posY, params)
    iconNode:setCascadeOpacityEnabled(true)
    iconNode:setCascadeColorEnabled(true)

    if string.len(checkstr(goodsConf.photoUpper)) > 0 then
        local upperPath  = GoodsUtils.GetIconPathById(goodsConf.photoUpper)
        local upperNode  = display.newImageView(upperPath)
        local offsetInfo = checktable(goodsConf.offset)
        local offsetPos  = cc.p(checkint(offsetInfo[1]), checkint(offsetInfo[2]))
        upperNode:setScale(math.min(checkint(goodsConf.scale)/100, 5))
        upperNode:setPosition(cc.pAdd(utils.getLocalCenter(iconNode), offsetPos))
        iconNode:addChild(upperNode)
    end
    return iconNode
end


-------------------------------------------------------------------------------
-- 未梳理，纯剪切过来的方法们
-------------------------------------------------------------------------------

--[[
刷新钻石数
datas = {
	freeDiamond  = 0, 免费钻石
	paidDiamond  = 0, 有偿钻石
	totalDiamond / diamond  = 0, 总钻石
}
--]]
function GoodsUtils.RefreshDiamond(datas)
    local userInfo     = app.gameMgr:GetUserInfo()
    local totalDiamond = datas.totalDiamond or datas.diamond

    if totalDiamond and type(totalDiamond) ~= 'table' then
        userInfo.diamond = checkint(totalDiamond)
    end

    local paidDiamond = datas.paidDiamond
    if paidDiamond then
        userInfo.paidDiamond = checkint(paidDiamond)
    end

    if checkint(userInfo.paidDiamond) > checkint(userInfo.diamond) then
        userInfo.paidDiamond = checkint(userInfo.diamond)
    end

    userInfo.freeDiamond = checkint(userInfo.diamond) - checkint(userInfo.paidDiamond)

    AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI, { diamond = userInfo.diamond })
end


--[[
判断多项资源扣除是否合格
multipGoodsData = {
    {goodsId, num}, ...
}
@params isShowTips : bool 是否展示提示
--]]
function GoodsUtils.CheckMultipCosts(multipGoodsData, isShowTips)
    local isFit = true
    for _, goodsData in ipairs(multipGoodsData) do
        if not GoodsUtils.CheckSingleCosts(goodsData, isShowTips) then
            isFit = false
            break
        end
    end
    return isFit
end


--[[
判断单项资源扣除是否合格
goodsData = {
    goodsId, 
    num,
}
@params isShowTips : bool 是否展示提示
--]]
function GoodsUtils.CheckSingleCosts(goodsData, isShowTips)
    local isFit = app.goodsMgr:getGoodsNum(goodsData.goodsId) >= checkint(goodsData.num)
    if not isFit and isShowTips then
        if GAME_MODULE_OPEN.NEW_STORE and checkint(goodsData.goodsId) == DIAMOND_ID then
            app.uiMgr:showDiamonTips()
        else
            app.uiMgr:ShowInformationTips(string.fmt(__("_name_不足"), {_name_ = GoodsUtils.GetGoodsNameById(goodsData.goodsId)}))
        end
    end
    return isFit
end


--[[
获取多项资源消耗的字符串
multipGoodsData = {
    {goodsId, num}, ....
}
--]]
function GoodsUtils.GetMultipleConsumeStr(multipGoodsData, isShowTips)
    local consumeStr = ""
    for goodIndex, goodsData in pairs(multipGoodsData) do
        local goodsStr  = GoodsUtils.GetSingleConsumeStr(goodsData)
        consumeStr = checkint(goodIndex) == 1 and consumeStr ..  goodsStr or consumeStr .. ',' .. goodsStr
    end
    return consumeStr
end


--[[
获取单项资源消耗的字符串
goodsData = {
    goodsId, 
    num
}
--]]
function GoodsUtils.GetSingleConsumeStr(goodsData)
    return checkint(goodsData.num) .. GoodsUtils.GetGoodsNameById(goodsData.goodsId)
end


--[[
根据配表获取单项资源扣除列表
goodsData = {
    goodsId, 
    num
}
--]]
function GoodsUtils.GetSingleCostList(goodsData)
    return {goodsId = checkint(goodsData.goodsId), num = checkint(goodsData.num) * -1}
end


--[[
根据配表获取多项资源扣除列表
multipGoodsData = {
    {goodsId, num} ...
}
--]]
function GoodsUtils.GetMultipCostList(multipGoodsData)
    local multipCostList = {}
    for goodIndex, goodsData in pairs(multipGoodsData) do
        table.insert(multipCostList, GoodsUtils.GetSingleCostList(goodsData))
    end
    return multipCostList
end
