--[[
 * author : kaishiqi
 * descpt : 猫屋工具类
]]
CatHouseUtils = {}


CatHouseUtils.AVATAR_NODE_DEBUG = false


CatHouseUtils.AVATAR_STYLE_TYPE = {
    IDENTITY  = 1, -- 名片
    BUBBLE    = 2, -- 气泡
}


CatHouseUtils.AVATAR_DEFAULT_HEAD_ID     = CardUtils.DEFAULT_SKIN_ID
CatHouseUtils.ATTR_LEAD_TO_DISEASE_LIMIT = 10


CatHouseUtils.AVATAR_STYLE_TYPE_NAME_FUNC_MAP = {
    [CatHouseUtils.AVATAR_STYLE_TYPE.IDENTITY] = function() return __("名片") end,
    [CatHouseUtils.AVATAR_STYLE_TYPE.BUBBLE]   = function() return __("气泡") end,
}


CatHouseUtils.AVATAR_TYPE = {
    NONE     = 0,  -- 空白
    DECORATE = 1,  -- 装饰类
    CATTERY  = 2,  -- 猫窝
    FLOOR    = 3,  -- 地板
    WALL     = 4,  -- 墙面
    CELLING  = 5,  -- 吊顶
}


CatHouseUtils.AVATAR_TAB_TYPE = {
    ALL         = 0,  -- 全部
    LIVING_ROOM = 1,  -- 起居室
    BEDROOM     = 2,  -- 卧室
    HALL        = 3,  -- 门厅
    CATTERY     = 4,  -- 猫窝
    FLOOR       = 5,  -- 地板
    WALL        = 6,  -- 墙壁
    CELLING     = 7,  -- 天花板
}


CatHouseUtils.AVATAR_CATTERY_TYPE = {
    CATTERY     = 1, -- 猫窝
    TOILET      = 2, -- 猫厕
}


CatHouseUtils.AVATAR_TAB_TYPE_NAME_FUNC_MAP = {
    [CatHouseUtils.AVATAR_TAB_TYPE.ALL]         = function() return __("全部") end,
    [CatHouseUtils.AVATAR_TAB_TYPE.LIVING_ROOM] = function() return __("起居室") end,
    [CatHouseUtils.AVATAR_TAB_TYPE.BEDROOM]     = function() return __("卧室") end,
    [CatHouseUtils.AVATAR_TAB_TYPE.HALL]        = function() return __("门厅") end,
    [CatHouseUtils.AVATAR_TAB_TYPE.CATTERY]     = function() return __("猫窝") end,
    [CatHouseUtils.AVATAR_TAB_TYPE.FLOOR]       = function() return __("地板") end,
    [CatHouseUtils.AVATAR_TAB_TYPE.WALL]        = function() return __("墙壁") end,
    [CatHouseUtils.AVATAR_TAB_TYPE.CELLING]     = function() return __("天花板") end,
}


CatHouseUtils.AVATAR_TAB_ICON_MAP = {
    [CatHouseUtils.AVATAR_TAB_TYPE.ALL]         = 'ui/catHouse/preset/decorate_ico_ornament.png',
    [CatHouseUtils.AVATAR_TAB_TYPE.LIVING_ROOM] = 'ui/catHouse/preset/decorate_ico_front.png',
    [CatHouseUtils.AVATAR_TAB_TYPE.BEDROOM]     = 'ui/catHouse/preset/decorate_ico_bed.png',
    [CatHouseUtils.AVATAR_TAB_TYPE.HALL]        = 'ui/catHouse/preset/decorate_ico_vestibule.png',
    [CatHouseUtils.AVATAR_TAB_TYPE.CATTERY]     = 'ui/catHouse/preset/decorate_ico_cat.png',
    [CatHouseUtils.AVATAR_TAB_TYPE.FLOOR]       = 'ui/catHouse/preset/decorate_ico_floor.png',
    [CatHouseUtils.AVATAR_TAB_TYPE.WALL]        = 'ui/catHouse/preset/decorate_ico_wall.png',
    [CatHouseUtils.AVATAR_TAB_TYPE.CELLING]     = 'ui/catHouse/preset/decorate_ico_hang.png',
}


CatHouseUtils.HOUSE_CMD_TAG = {
    NONE       = 0,
    TO_APPEND  = 1,
    TO_REMOVE  = 2,
    TO_CANCLE  = 3,
    DO_CANCLE  = 4,
    DO_PREPARE = 5,
    DO_REMOVE  = 6,
    DO_CONFIRM = 7,
    BY_REMOVE  = 8,
    DO_MOVED   = 9,
    BY_CONFIRM = 10,
}


-- @see CONF.CAT_HOUSE.EVENT_TYPE
CatHouseUtils.HOUSE_EVENT_TYPE = {
    INVITE  = 1, -- 邀请事件
    BREED   = 2, -- 繁育事件
}


CatHouseUtils.HANDLER_TYPE = {
    AVATAR = 1,
    REPAIR = 2,
    CAT    = 3,
}

CatHouseUtils.MEMBER_TYPE = {
    ROLE = 1,
    CAT  = 2,
}


CatHouseUtils.AVATAR_TILED_SIZE = cc.size(20, 20)  -- 平铺单元尺寸
CatHouseUtils.AVATAR_TILED_AREA = cc.size(58, 24)  -- 平铺面积范围
CatHouseUtils.AVATAR_SAFE_SIZE  = cc.size(
    CatHouseUtils.AVATAR_TILED_SIZE.width  * CatHouseUtils.AVATAR_TILED_AREA.width, 
    CatHouseUtils.AVATAR_TILED_SIZE.height * CatHouseUtils.AVATAR_TILED_AREA.height
)

CatHouseUtils.CAT_BREED_STATE = {
    CREATE   = 1, -- 新建
    PAIRING  = 2, -- 配对
    BREEDING = 3, -- 生育
    FINISH   = 4, -- 生育完成
    EMPTY    = 5, -- 空闲
    INVITED  = 6, -- 受邀
}

CatHouseUtils.CAT_WAREHOUSE_EXPAND_NUM = 1  -- 猫咪 仓库扩容增加量
CatHouseUtils.CAT_ATTR_ALERT_NUM       = 20 -- 猫咪 属性警示数值
CatHouseUtils.CAT_YOUTH_AGE_NUM        = 1  -- 猫咪 幼年期年纪


CatHouseUtils.CAT_SEX_TYPE = {
    BOY  = 1, -- 男
    GIRL = 2, -- 女
}


CatHouseUtils.CAT_GENE_TYPE = {
    FACADE  = 1, -- 外观
    ABILITY = 2, -- 功能
    SUIT    = 3, -- 套装
}


CatHouseUtils.CAT_GENE_PART = {
    NONE  = 0, -- 无
    HEAD  = 1, -- 头部
    EYE   = 2, -- 眼睛
    TAIL  = 3, -- 尾巴
    TRUNK = 4, -- 身体
}


CatHouseUtils.CAT_GENE_CELL_STATU = {
    NORMAL = 1, -- 普通
    UNLOCK = 2, -- 未解锁
    SELECT = 3, -- 选中
}


CatHouseUtils.CAT_FRIEND_INTERACT_ACTION = {
    PLYA  = 1,  -- 玩耍
    FEED  = 2,  -- 喂食
    DRIVE = 3,  -- 驱赶
}


CatHouseUtils.CAT_CHOOSE_POPUP_TYPE = {
    HOUSE_PLACE = 1, -- 猫屋放置
    OUT_GOING   = 2, -- 外出派遣
    EQUIP_CAT   = 3, -- 猫咪装备
}


CatHouseUtils.CAT_EFFECT_SOURCE_ENUM = {
    GENE  = 1,  -- 基因效果
    STATE = 2,  -- 状态效果
}


CatHouseUtils.CAT_EFFECT_TYPE_ENUM = {
    ATTR_REDUCE_RATE      = 1,  -- _id_属性【衰减速度】增加/减少_num_%
    ATTR_REDUCE_DISABLE   = 2,  -- _id_属性【不会减少】
    ATTR_UPPER_LIMIT      = 3,  -- _id_属性【上限】增加/减少_num_点
    ATTR_EARNINGS_RATE    = 4,  -- _id_属性【效果收益】提高/降低_num_%（任何改变属性的情况，如喂食、玩耍、洗澡、睡觉、上厕所）
    GOODS_ELIMINATE_RATE  = 5,  -- _id_物品【状态消除率】提高_num_%
    SHOWER_GOODS_AUTO     = 6,  -- 洗澡【自动使用】洗漱用品
    WORK_EXTRA_MONEY_RATE = 7,  -- 工作【可额外获得】_num_%喵币
    WORK_EXTRA_EXP_RATE   = 8,  -- 工作【可额外获得】_num_%经验
    STYDY_CONSUME_RATE    = 9,  -- 学习【支付花费】降低_num_%
    STYDY_EXTRA_ABILITY   = 10, -- 学习【可额外获得】_num_点能力
    PLAY_EXTRA_ATTR       = 11, -- 玩耍【可额外获得】_num_点属性
    LIKE_EXTRA_NUM        = 12, -- 好感度【每次操作后】额外增加_num_点
    FEED_DISABLE          = 13, -- 无法【进食】
    MAKING_CATS_RATE      = 14, -- 交配后【_num1_%概率获得】_num2_只小猫
    AVATAR_DAMAGED_NUM    = 15, -- 损坏家具次数_num_
    OUT_DISPERSE_DISABLE  = 16, -- 外出时【驱赶按钮隐藏】
    AGE_EXTRA_SECONDS     = 17, -- _id_年龄【成长时间增加_num_秒】
    STATE_SICK_SECONDS    = 18, -- 疾病等负面【状态时间】减少_num_%
    OUT_MAX_COUNT         = 19, -- 外出【每日最大次数】增加_num_
    LIKE_DISABLE          = 20, -- 好感度【不能增加】
    SLEEP_DISABLE         = 21, -- 无法【入睡】
    FEED_GOODS_QUALITY    = 22, -- 只能吃【_id_品质及以上】的食物
    TOILET_DISABLE        = 23, -- 无法【上厕所】
    GENE_FACADE_DISABLE   = 24, -- 外表基因【失效】
    ANYTHING_DISABLE      = 25, -- 无法【进行任何操作】
}


CatHouseUtils.CAT_GENE_TYPE_DEFINE_MAP = {
    [CatHouseUtils.CAT_GENE_TYPE.FACADE] = {
        ['titleFunc']                              = function() return __("身体") end,
        ['bigIconPath']                            = 'ui/catModule/familyTree/grow_book_btn_body.png',
        [CatHouseUtils.CAT_GENE_CELL_STATU.NORMAL] = 'ui/catModule/familyTree/grow_book_ico_body_birth.png',
        [CatHouseUtils.CAT_GENE_CELL_STATU.UNLOCK] = 'ui/catModule/familyTree/grow_book_ico_body_grey.png',
        [CatHouseUtils.CAT_GENE_CELL_STATU.SELECT] = 'ui/catModule/familyTree/grow_book_ico_body_light.png',
    },
    [CatHouseUtils.CAT_GENE_TYPE.ABILITY] = {
        ['titleFunc']                              = function() return __("功能") end,
        ['bigIconPath']                            = 'ui/catModule/familyTree/grow_book_btn_all.png',
        [CatHouseUtils.CAT_GENE_CELL_STATU.NORMAL] = 'ui/catModule/familyTree/grow_book_ico_buff_birth.png',
        [CatHouseUtils.CAT_GENE_CELL_STATU.UNLOCK] = 'ui/catModule/familyTree/grow_book_ico_buff_grey.png',
        [CatHouseUtils.CAT_GENE_CELL_STATU.SELECT] = 'ui/catModule/familyTree/grow_book_ico_buff_light.png',   
    },
    [CatHouseUtils.CAT_GENE_TYPE.SUIT] = {
        ['titleFunc']                              = function() return __("套装") end,
        ['bigIconPath']                            = 'ui/catModule/familyTree/grow_book_btn_team.png',
        [CatHouseUtils.CAT_GENE_CELL_STATU.NORMAL] = 'ui/catModule/familyTree/grow_book_ico_team_birth.png',
        [CatHouseUtils.CAT_GENE_CELL_STATU.UNLOCK] = 'ui/catModule/familyTree/grow_book_ico_team_grey.png',
        [CatHouseUtils.CAT_GENE_CELL_STATU.SELECT] = 'ui/catModule/familyTree/grow_book_ico_team_light.png',  
    },
}


CatHouseUtils.CAT_GENE_PART_DEFINE_MAP = {
    [CatHouseUtils.CAT_GENE_PART.HEAD]  = {
        ['nameFunc'] = function() return __('头部') end,
    },
    [CatHouseUtils.CAT_GENE_PART.EYE]   = {
        ['nameFunc'] = function() return __('眼睛') end,
    },
    [CatHouseUtils.CAT_GENE_PART.TAIL]  = {
        ['nameFunc'] = function() return __('尾巴') end,
    },
    [CatHouseUtils.CAT_GENE_PART.TRUNK] = {
        ['nameFunc'] = function() return __('躯干') end,
    },
}


CatHouseUtils.CAT_GOODS_TYPE = {
    FOOD       = 1, -- 食品
    DRUG       = 2, -- 药品
    CLEAN_ITEM = 3, -- 清洁用品
    TOY        = 4, -- 玩具
    OTHER      = 5, -- 其他
}


CatHouseUtils.CAT_STATE_ANIM_TAG = {
    WORK_DONE    = 1, -- 工作完成
    RELEASE_DONE = 2, -- 放生成功
    STUDY_DONE   = 3, -- 学习完成
    DEAD_DONE    = 4, -- 死亡埋葬
    BRAR_DONE    = 5, -- 生育完成
    RETURN_DONE  = 6, -- 外出归来
}


local CAT_PARMS_FUNC = function(confKey, checkFunc)
    return function() 
        return checkFunc(CONF.CAT_HOUSE.CAT_PARMS:GetValue(confKey))
    end
end
CatHouseUtils.CAT_PARAM_FUNCS = {
    WAREHOUSE_INIT_NUM = CAT_PARMS_FUNC('initialWarehouseCapacity', checkint),           -- 仓库 初始格子
    WAREHOUSE_MAX_NUM  = CAT_PARMS_FUNC('maxWarehouseCapacity', checkint),               -- 仓库 最大格子
    WAREHOUSE_CONSUME  = CAT_PARMS_FUNC('warehouseExpandConsume', checktable),           -- 仓库 升级消耗
    BIRTH_CONSUME      = CAT_PARMS_FUNC('birthConsume', checktable),                     -- 生育 所需消耗
    BIRTH_REWARDS      = CAT_PARMS_FUNC('birthRewards', checktable),                     -- 生育 获得奖励
    BIRTH_REWARD_NUM   = CAT_PARMS_FUNC('dailyMaxMatingBeInvitedRewardTimes', checkint), -- 生育 奖励次数
    BIRTH_HOUSE_TIME   = CAT_PARMS_FUNC('matingHouseDuration', checkint),                -- 生育 小屋时间
    REBIRTH_GENERATION = CAT_PARMS_FUNC('rebirthGeneration', checkint),                  -- 回归 所需代数
    REBIRTH_CONSUME    = CAT_PARMS_FUNC('rebirthConsume', checktable),                   -- 回归 所需消耗
    RENAME_CONSUME     = CAT_PARMS_FUNC('renameConsume', checktable),                    -- 改名 所需消耗
    ACHV_RESET_CONSUME = CAT_PARMS_FUNC('achievementConsume', checktable),               -- 成就 重置消耗
    REBORN_CONSUME     = CAT_PARMS_FUNC('rebornConsume', checktable),                    -- 复活 所需消耗
    JOURNAL_MAX        = CAT_PARMS_FUNC('maxJournalNum', checkint),                      -- 日记 最大数量
    MAX_ACTION_TIMES   = CAT_PARMS_FUNC('dailyMaxActionTimes', checkint),                -- 工作/学习 最大次数
    TOILET_TIME        = CAT_PARMS_FUNC('toiletTime', checkint),                         -- 厕所 消耗时间
    SLEEP_TIME         = CAT_PARMS_FUNC('sleepTime', checkint),                          -- 睡眠 消耗时间
    INIT_AGENE_NUM     = CAT_PARMS_FUNC('initAppearanceGeneNum', checkint),              -- 初始 功能基因数
    INIT_FGENE_NUM     = CAT_PARMS_FUNC('initFeatureGeneNum', checkint),                 -- 初始 外表基因数
    INIT_AGE_NUM       = CAT_PARMS_FUNC('birthAge', checkint),                           -- 初始 出生年龄
    GENE_ADD_NUM       = CAT_PARMS_FUNC('ageIncreaseGeneNum', checkint),                 -- 基因 增长数量
    AGE_MAX            = CAT_PARMS_FUNC('maxAge', checkint),                             -- 年龄 最大上限
    GENERATION_MAX     = CAT_PARMS_FUNC('maxGeneration', checkint),                      -- 代数 最大上限
    CAREER_LEVEL_MAX   = CAT_PARMS_FUNC('maxCareerLevel', checkint),                     -- 职业 最大等级
    OUT_NEED_ATTR      = CAT_PARMS_FUNC('outNeedAttr', checktable),                      -- 外出 所需属性
    OUT_MAX            = CAT_PARMS_FUNC('dailyMaxOutTimes', checkint),                   -- 外出 最大次数
    OUT_TIME           = CAT_PARMS_FUNC('outDuration', checkint),                        -- 外出 消耗时间
    OUT_RECOVER_ATTR   = CAT_PARMS_FUNC('outRecoverAbilities', checktable),              -- 外出 恢复属性
    LIKE_ADD_EXP       = CAT_PARMS_FUNC('actionFavorabilityAddition', checkint),         -- 好感 增加经验
    LIKE_CONSUME       = CAT_PARMS_FUNC('favorabilityActionConsume', checktable),        -- 好感 操作消耗
    LIKE_FEED_MAX      = CAT_PARMS_FUNC('dailyMaxFavorabilityFeedTimes', checkint),      -- 好感 喂食上限
    LIKE_STROKE_MAX    = CAT_PARMS_FUNC('dailyMaxFavorabilityPlayTimes', checkint),      -- 好感 抚摸上限
    REBORN_ATTR        = CAT_PARMS_FUNC('rebornAttrs', checktable),                      -- 复活 重置属性
}


local HOUSE_PARMS_FUNC = function(confKey, checkFunc)
    return function()
        return checkFunc(CONF.CAT_HOUSE.BASE_PARMS:GetValue(confKey))
    end
end
CatHouseUtils.HOUSE_PARAM_FUNCS = {
    HOUSE_LEVEL_MAX    = HOUSE_PARMS_FUNC('maxHouseLevel', checkint),           -- 猫屋 等级上限
    AVATAR_SUIT_MAX    = HOUSE_PARMS_FUNC('maxAvatarCustomSuitNum', checkint),  -- 家具 预设上限
    AVATAR_DAMAGE_MAX  = HOUSE_PARMS_FUNC('dailyMaxDamageAvatarNum', checkint), -- 家具 损坏上限
    AVATAR_FIX_PERCENT = HOUSE_PARMS_FUNC('repairAvatarPrice', checknumber),    -- 家具 修复折扣（向下取整）
    EVENT_VISIT_MAX    = HOUSE_PARMS_FUNC('maxEventNum', checkint),             -- 事件 拜访上限
    EVENT_MATING_MAX   = HOUSE_PARMS_FUNC('maxMatingEventNum', checkint),       -- 事件 生育上限
    EVENT_SHOW_TIME    = HOUSE_PARMS_FUNC('maxEventDuration', checkint),        -- 事件 持续时间
    PLACE_CAT_MAX      = HOUSE_PARMS_FUNC('maxPlaceCatNum', checkint),          -- 放置 猫咪上限
    FRIEND_CAT_MAX     = HOUSE_PARMS_FUNC('maxFriendCatNum', checkint),         -- 好友 猫咪上限
    INIT_IDENTITY_ID   = HOUSE_PARMS_FUNC('defaultBusinessCard', checkint),     -- 初始 名片id
    INIT_BUBBLE_ID     = HOUSE_PARMS_FUNC('defaultBubble', checkint),           -- 初始 气泡id
    INIT_GUEST_POS     = function()                                             -- 初始 游客位置
        local initConf = checktable(CONF.CAT_HOUSE.BASE_PARMS:GetValue('guestInitialLocation'))
        return cc.p(display.cx + checkint(initConf[1]), checkint(initConf[2]))
    end,
}


--[[
    生成猫咪唯一id
    @return string
]]
function CatHouseUtils.BuildCatUuid(playerId, playerCatId)
    return string.fmt('%1_%2', tostring(playerId), tostring(playerCatId))
end

--[[
    根据猫咪唯一id获取猫咪id
    @return string
]]
function CatHouseUtils.GetPlayerCatId(catUuid)
    return checkint(CatHouseUtils.GetCatInfoIdArray(catUuid)[2])
end

--[[
    根据猫咪唯一id获取猫咪主人id
    @return string
]]
function CatHouseUtils.GetPlayerId(catUuid)
    return checkint(CatHouseUtils.GetCatInfoIdArray(catUuid)[1])
end

--[[
    根据猫咪唯一id获取解析出来的id列表
    @return array
]]
function CatHouseUtils.GetCatInfoIdArray(catUuid)
    return string.split2(catUuid, "_")
end

--[[
    根据 avatarId 获取 avatar修复的道具数据
]]
function CatHouseUtils.GetAvatarRepairConsume(avatarId)
    local repairConsume = CatHouseUtils.HOUSE_PARAM_FUNCS.AVATAR_FIX_PERCENT()
    local avatarConf    = CONF.CAT_HOUSE.AVATAR_INFO:GetValue(avatarId)
    local currencyId    = checkint(avatarConf.currency)
    local repairPrice   = math.floor(checkint(avatarConf.price) * repairConsume)
    return {
        goodsId = currencyId,
        num     = repairPrice,
    }
end



--[[
    根据 装扮样式类型 获取 类型名字
]]
function CatHouseUtils.GetAvatarStyleTypeName(styleType)
	local nameFunc = CatHouseUtils.AVATAR_STYLE_TYPE_NAME_FUNC_MAP[checkint(styleType)]
    return nameFunc and nameFunc() or ''
end


--[[
    根据 家具页签类型 获取 类型名字
]]
function CatHouseUtils.GetAvatarTabTypeName(avatarTabId)
	local nameFunc = CatHouseUtils.AVATAR_TAB_TYPE_NAME_FUNC_MAP[checkint(avatarTabId)]
    return nameFunc and nameFunc() or ''
end


--[[
    根据 家具页签类型 获取 类型图标
]]
function CatHouseUtils.GetAvatarTabTypeIcon(avatarTabId)
    return _res(CatHouseUtils.AVATAR_TAB_ICON_MAP[checkint(avatarTabId)])
end


--[[
    根据id 获取 avatar类型
--]]
function CatHouseUtils.GetAvatarTypeByGoodsId(goodsId)
    local avatarConf = CONF.CAT_HOUSE.AVATAR_INFO:GetValue(goodsId) or {}
    return checkint(avatarConf.mainType)
end


--[[
    根据id 获取 舒适度信息
--]]
function CatHouseUtils.GetComfortValueByGoodsId(goodsId)
    local avatarConf = CONF.CAT_HOUSE.AVATAR_INFO:GetValue(goodsId) or {}
    return checkint(avatarConf.comfort)
end


--[[
    根据奖杯id 获取奖杯的路径
--]]
function CatHouseUtils.GetTrophyImageByTrophyId(trophyId)
    return _res(string.format('ui/catHouse/trophy/icon/cat_trophy_%d', checkint(trophyId)))
end

--[[
通过支付类型获取商城货币
@params payType int 支付类型 / 1:金币 2:幻晶石
--]]
function CatHouseUtils.GetCurrencyByPayType( payType )
    local currencyType = {
        GOLD_ID,
        DIAMOND_ID
    }
    return currencyType[checkint(payType)]
end

--[[
根据 道具id 获取 装饰品类型
--]]
function CatHouseUtils.GetDressTypeByGoodsId( goodsId )
    local goodsConf = GoodsUtils.GetGoodsConfById(goodsId)
    local effectType = checkint(goodsConf.effectType)
    if effectType == 1 then
        return CatHouseUtils.AVATAR_STYLE_TYPE.IDENTITY
    elseif effectType == 2 then
        return CatHouseUtils.AVATAR_STYLE_TYPE.BUBBLE
    else
        app.uiMgr:ShowInformationTips('类型错误：' .. tostring(goodsId))
    end
end 


--[[
根据 道具id 获取 默认装饰品id
--]]
function CatHouseUtils.GetDressDefaultIdByGoodsId( goodsId )
    local dressType = CatHouseUtils.GetDressTypeByGoodsId(goodsId)
    if dressType == CatHouseUtils.AVATAR_STYLE_TYPE.IDENTITY then
        return CatHouseUtils.HOUSE_PARAM_FUNCS.INIT_IDENTITY_ID()
    elseif dressType == CatHouseUtils.AVATAR_STYLE_TYPE.BUBBLE then
        return CatHouseUtils.HOUSE_PARAM_FUNCS.INIT_BUBBLE_ID()
    else
        -- type都找不到无法分类
        return CatHouseUtils.HOUSE_PARAM_FUNCS.INIT_IDENTITY_ID()
    end
end


--[[
根据 基因id 获取 基因类型
--]]
function CatHouseUtils.GetCatGeneTypeByGeneId(geneId)
    local catGeneConf = CONF.CAT_HOUSE.CAT_GENE:GetValue(geneId)
    local geneType = CatHouseUtils.CAT_GENE_TYPE.FACADE
    if checkint(catGeneConf.part) == 0 then
        geneType = CatHouseUtils.CAT_GENE_TYPE.ABILITY
    elseif checkint(catGeneConf.part) == 5 then
        geneType = CatHouseUtils.CAT_GENE_TYPE.SUIT
    end
    return geneType
end


--[[
根据 基因id 获取 基因部位
@see CatHouseUtils.CAT_GENE_PART
]]
function CatHouseUtils.GetCatGenePartByGeneId(geneId)
    local catGeneConf = CONF.CAT_HOUSE.CAT_GENE:GetValue(geneId)
    return checkint(catGeneConf.part)
end


--[[
根据 属性id，属性状态 获取 猫咪属性图标路径
@see CatHouseUtils.CAT_GENE_CELL_STATU
--]]
function CatHouseUtils.GetCatGeneIconPathByGeneId(geneId, state)
    local geneType  = CatHouseUtils.GetCatGeneTypeByGeneId(geneId)
    local geneState = state or CatHouseUtils.CAT_GENE_CELL_STATU.NORMAL
    return CatHouseUtils.GetCatGeneIconPathByGeneType(geneType, geneState)
end


--[[
根据 基因类型 获取 基因图标路径
@see CatHouseUtils.CAT_GENE_TYPE
--]]
function CatHouseUtils.GetCatGeneIconPathByGeneType(geneType, geneState)
    local catGeneType  = checkint(geneType)
    local catGeneState = checkint(geneState)
    return _res(CatHouseUtils.CAT_GENE_TYPE_DEFINE_MAP[catGeneType][catGeneState])
end


--[[
根据 基因类型 获取 基因大图标路径
@see CatHouseUtils.CAT_GENE_TYPE
--]]
function CatHouseUtils.GetCatGeneBigIconPathByGeneType(geneType)
    local catGeneType = checkint(geneType)
    return _res(CatHouseUtils.CAT_GENE_TYPE_DEFINE_MAP[catGeneType]['bigIconPath'])
end


--[[
根据 基因类型 获取 基因名称
@see CatHouseUtils.CAT_GENE_TYPE
--]]
function CatHouseUtils.GetCatGeneTypeNameByGeneType(geneType)
    local catGeneType = checkint(geneType)
    if CatHouseUtils.CAT_GENE_TYPE_DEFINE_MAP[catGeneType] then
        return CatHouseUtils.CAT_GENE_TYPE_DEFINE_MAP[catGeneType]['titleFunc']()
    else
        return '----'
    end
end


--[[
根据 基因部位 获取 基因名称
@see CatHouseUtils.CAT_GENE_TYPE
--]]
function CatHouseUtils.GetCatGenePartNameByGenePart(genePart)
    local catGenePart = checkint(genePart)
    if CatHouseUtils.CAT_GENE_PART_DEFINE_MAP[catGenePart] then
        return CatHouseUtils.CAT_GENE_PART_DEFINE_MAP[catGenePart]['nameFunc']()
    else
        return '----'
    end
end


--[[
    猫咪状态 是否会致死
]]
function CatHouseUtils.IsCatStateCanDoSick(stateId)
    local stateConf = CONF.CAT_HOUSE.CAT_STATUS:GetValue(stateId)
    return checkint(stateConf.deathSeconds) > 0
end


--[[
    猫咪状态 能否被治愈
]]
function CatHouseUtils.IsCatStateCanBeCure(stateId)
    local stateConf = CONF.CAT_HOUSE.CAT_STATUS:GetValue(stateId)
    return checkint(stateConf.cureGoodsId) > 0
end


--[[
    猫咪好感等级
]]
function CatHouseUtils.GetCatLikeLevel(likeExp)
    local likeLevel = 0
    local expNumber = checkint(likeExp)
    for _, expId in ipairs(CONF.CAT_HOUSE.CAT_LIKE_LEVEL:GetIdListDown()) do
        local levelConf = CONF.CAT_HOUSE.CAT_LIKE_LEVEL:GetValue(expId)
        if expNumber >= checkint(levelConf.totalExp) then
            likeLevel = checkint(levelConf.level)
            break
        end
    end
    return likeLevel
end


--[[
根据 属性id/属性值 获取 猫咪属性图标
--]]
function CatHouseUtils.GetCatAttrTypeIconPath(attrType, isRedIcon)
    local catAttrType = checkint(attrType)
    local mainPath    = "ui/catModule/catInfo/attrIcon/"
    if isRedIcon then
        return _res(string.format(mainPath .. "attribute_red_%s.png", attrType % 100))
    else
        return _res(string.format(mainPath .. "attribute_%s", attrType % 100))
    end
end


--[[
    猫咪属性衰减时间，根据能力换算得出。
]]
function CatHouseUtils.GetCatAbilityToAttrReduceTime(abilityId, abilityValue)
    local abilityConf  = CONF.CAT_HOUSE.CAT_ABILITY:GetValue(abilityId)
    local effectAttrId = checkint(abilityConf.effectAttr)
    local effectReduce = checknumber(abilityConf.effectAttrReduce)
    local catAttrConf  = CONF.CAT_HOUSE.CAT_ATTR:GetValue(effectAttrId)
    local reduceTime   = checkint(catAttrConf.reduceSeconds)
    if effectAttrId > 0 then
        -- e.g: 1 / (1-20*0.01) * 60
        local reduceRate = math.max(1 - checkint(abilityValue) * effectReduce, 0)
        if reduceRate > 0 then
            reduceTime = math.ceil(1 / reduceRate * reduceTime)
        else
            reduceTime = 0
        end
    end
    return reduceTime
end


--[[
    根据来源获取 猫咪效果id列表
]]
---@param sourceType number @see CatHouseUtils.CAT_EFFECT_SOURCE_ENUM
---@param sourceRefId number
---@return number[]
function CatHouseUtils.GetCatEffectIdListBySource(sourceType, sourceRefId)
    local effectIdList = {}
    if sourceType == CatHouseUtils.CAT_EFFECT_SOURCE_ENUM.GENE then
        local geneConf = CONF.CAT_HOUSE.CAT_GENE:GetValue(sourceRefId)
        local effectId = checkint(geneConf.effectId)
        table.insert(effectIdList, effectId)
        
    elseif sourceType == CatHouseUtils.CAT_EFFECT_SOURCE_ENUM.STATE then
        local stateConf = CONF.CAT_HOUSE.CAT_STATUS:GetValue(sourceRefId)
        for _, effectId in ipairs(stateConf.effectIds or {}) do
            table.insert(effectIdList, effectId)
        end
    end
    return effectIdList
end


--[[
    是否有 禁用驱逐效果 的基因
]]
function CatHouseUtils.IsHaveDisableDisperseByGeneList(geneIdList)
    for _, geneId in ipairs(geneIdList or {}) do
        local effectIdList = CatHouseUtils.GetCatEffectIdListBySource(CatHouseUtils.CAT_EFFECT_SOURCE_ENUM.GENE, geneId)
        for _, effectId in ipairs(effectIdList) do
            local effectConf = CONF.CAT_HOUSE.CAT_EFFECT:GetValue(effectId)
            if checkint(effectConf.type) == CatHouseUtils.CAT_EFFECT_TYPE_ENUM.OUT_DISPERSE_DISABLE then
                return true
            end
        end
    end
    return false
end


--[[
根据 catModel 获取 学习花费
--]]
---@param catModel HouseCatModel
function CatHouseUtils.GetCatStudyConsume(studyId, catModel)
    local studyConf   = CONF.CAT_HOUSE.CAT_STUDY:GetValue(studyId)
    local consumeList = {}
    local consumeRate = catModel and catModel:getStydyConsumeRate() or 0
    for goodsIndex, goodsData in ipairs(studyConf.consume or {}) do
        consumeList[goodsIndex] = {
            goodsId = checkint(goodsData.goodsId),
            num     = math.ceil(checkint(goodsData.num) * (1 + consumeRate/100))
        }
    end
    return consumeList
end


-------------------------------------------------------------------------------
-- views
-------------------------------------------------------------------------------

--[[
    创建 人物名片node
    @param goodsId : int     名片id
    @param text    : str     名片文字
    @param initPos : cc.p    初始坐标（optional)
]]
function CatHouseUtils.GetBusinessCardNode(goodsId, text, initPos)
    local nodeSize  = cc.size(200, 80)
    local namePath  = GoodsUtils.GetIconPathById(goodsId)
    local textLabel = ui.label({fnt = FONT.D12, text = tostring(text), maxW = 200})
    local textSize  = display.getLabelContentSize(textLabel)
    local cardNodeW = math.max(textSize.width + 60, nodeSize.width)
    local cardNode  = ui.layer({bg = namePath, size = cc.size(cardNodeW, nodeSize.height), cut = cc.dir(99, 40, 99, 38), p = initPos})
    cardNode:addList(textLabel):alignTo(nil, ui.cc, {offsetY = -3})
    return cardNode
end


--[[
    创建 对话气泡node
    @param goodsId : int     气泡id
    @param text    : str     气泡文字
    @param initPos : cc.p    初始坐标（optional)
    @param presetW : int     预制宽度（optional)
]]
function CatHouseUtils.GetBubbleNode(goodsId, text, initPos, presetW)
    local nodeSize   = cc.size(presetW or 300, 140)
    local textLabel  = ui.label({fnt = FONT.D12, text = tostring(text), w = nodeSize.width - 60})
    local textSize   = display.getLabelContentSize(textLabel)
    local bubbleH    = math.max(textSize.height + 80, nodeSize.height)
    local bubblePath = GoodsUtils.GetIconPathById(goodsId)
    local bubbleNode = ui.layer({bg = bubblePath, size = cc.size(nodeSize.width, bubbleH), cut = cc.dir(99, 70, 99, 68), p = initPos})
    bubbleNode:addList(textLabel):alignTo(nil, ui.cc)
    return bubbleNode
end


--[[
    根据 猫咪id 获取 猫咪节点
    @param catParams : table   用法1：自己的猫咪 { catUuid : int }
    @param catParams : table   用法2：指定数据的猫咪 { catData : {
        catId : int  猫咪种族
        age   : int  猫咪年龄（可选，默认值1）
        gene  : list 猫咪基因id列表（可选，默认初始皮）
    } }
--]]

---@return CatSpineNode
function CatHouseUtils.GetCatSpineNode(catParams, initPos)
    local catNode = require('Game.views.catModule.cat.CatSpineNode').new(catParams)
    catNode:setPosition(initPos or PointZero)
    return catNode
end
---[[
---@description 判断猫咪是否为幼年期
---@param age number 猫咪年龄
---@return boolean 是否为幼年期
---]]
function CatHouseUtils.IsYouthAge( age )
    return checkint(age) <= CatHouseUtils.CAT_YOUTH_AGE_NUM
end
---[[
---@description 判断猫咪是否基因生效
---@param age number 猫咪年龄
---@return boolean 是否基因生效
---]]
function CatHouseUtils.IsGeneEffect( age )
    return not CatHouseUtils.IsYouthAge(age)
end
---[[
---获取配偶性别
---@params sex CatHouseUtils.CAT_SEX_TYPE 性别
---]]
function CatHouseUtils.GetMateSex( sex )
    return checkint(sex) == CatHouseUtils.CAT_SEX_TYPE.BOY and CatHouseUtils.CAT_SEX_TYPE.GIRL or CatHouseUtils.CAT_SEX_TYPE.BOY 
end
---[[
---获取装备的猫咪的生效基因
---]]
function CatHouseUtils.GetEquippedCatGene()
    local equippedHouseCat = app.gameMgr:GetUserInfo().equippedHouseCat
    local equippedHouseCatTimeStamp = app.gameMgr:GetUserInfo().equippedHouseCatTimeStamp
    if next(equippedHouseCat) == nil then return {} end
    -- 计算当前年龄
    local curAge = checkint(equippedHouseCat.age)
    if curAge < CONF.CAT_HOUSE.CAT_AGE:GetLength() then
        local seconds = equippedHouseCatTimeStamp - os.time()
        if seconds >= checkint(equippedHouseCat.nextAgeLeftSeconds) then
            curAge = curAge + 1
            seconds = seconds - checkint(equippedHouseCat.nextAgeLeftSeconds)
            while curAge < CONF.CAT_HOUSE.CAT_AGE:GetLength() and seconds >= checkint(CONF.CAT_HOUSE.CAT_AGE:GetValue(curAge).growthTime) do
                curAge = curAge + 1
                seconds = seconds - checkint(CONF.CAT_HOUSE.CAT_AGE:GetValue(curAge).growthTime)
            end
        end
    end
    -- 幼年期基因效果不生效
    if not CatHouseUtils.IsGeneEffect(curAge) then return {} end

    -- 获取生效基因
    local gene = {}
    for k, ageGene in pairs(checktable(equippedHouseCat.geneOriginal)) do
        if curAge >= checkint(k) then
            for _, geneId in pairs(ageGene) do
                gene[tostring(geneId)] = true
            end
        end
    end
    return gene
end
---[[
---获取猫咪的增益效果
---@param geneMap table 基因map
---]]
function CatHouseUtils.GetCatBuff( geneMap )
    local buff = {}
    -- local geneConf = CONF.CAT_HOUSE.CAT_GENE:GetAll() !! 打开服务端就报错了
    -- 服务器跑战斗逻辑的时候，是没有 CONF 加载，所以这里只能使用老办法加载配表
    local geneConf = CommonUtils.GetConfigAllMess('catGene', 'house') or {}
    for geneId, effective in pairs(checktable(geneMap)) do
        if effective and geneConf[tostring(geneId)] and next(geneConf[tostring(geneId)].buff) ~= nil then
            for attr, value in pairs(geneConf[tostring(geneId)].buff) do
                if buff[checkint(attr)] then
                    buff[checkint(attr)] = buff[checkint(attr)] + tonumber(value)
                else
                    buff[checkint(attr)] = tonumber(value)
                end
            end
        end
    end
    return buff
end

---[[
---获取猫咪的增益总值
---@param geneMap table 基因map
---]]
function CatHouseUtils.CalculateBuffTotalAddition( geneMap )
    local buff = CatHouseUtils.GetCatBuff( geneMap )
    local count = 0
    for i, v in pairs(buff) do
        count = count + tonumber(v)
    end
    return count
end
---[[
---判断猫咪是否处于装备中
---@param catUuid string catUuid
---]]
function CatHouseUtils.IsCatEquipped( catUuid )
    local id = CatHouseUtils.BuildCatUuid(app.gameMgr:GetPlayerId(), app.gameMgr:GetUserInfo().equippedHouseCat.id)
    return id == catUuid
end