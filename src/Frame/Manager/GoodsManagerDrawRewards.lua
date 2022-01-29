--[[
 * author : kaishiqi
 * descpt : 游戏道具 管理器 -> DrawRewards相关的逻辑
--]]
local GoodsManager = {}


-------------------------------------------------
-- init method

--[[
初始化
--]]
function GoodsManager:InitLogicUnit()
    -- 道具数量对应checkin玩家数据中单独的字段 其道具更新规则
    self.goodsDataInCheckinMap = nil

    -- 道具信息对应xxxManager中缓存的值 其道具更新规则
    self.goodsDataInManagerMap = nil

    -- 道具信息对应活动体力 其道具更新规则
    self.goodsDataInActivityHpMap = nil

    -- 道具信息对应不同的道具类型的更新规则
    self.goodsDataByGoodsTypeMap = nil
end
GoodsManager:InitLogicUnit()


-------------------------------------------------
-- logic method

--[[
通用方法 领取奖励 更新本地数据的逻辑
@params props table {
	{goodsId = id, num = 数量, --其他的一些数据}
}
@params isDelayEvent bool 如果升级了 先弹出获取界面 后升级
@params isGuide bool 是否是为了引导刚进入模块把道具插入背包
@params isRefreshGoods bool 是否发送刷新道具的事件
--]]
function GoodsManager:DrawRewards(props, isDelayEvent, isGuide, isRefreshGoods)
    -- 延迟事件回调 领取完奖励的回调
    local delayFuncList = {}
    if isRefreshGoods == nil then
        isRefreshGoods = true
    end

    -- 传参类型判断
    if type(props) == 'table' and next(props) ~= nil then

        for k, property in pairs(props) do

            -- 过滤部分table中的封装的requestData服务器请求数据
            if k ~= 'requestData' then

                -- 向背包中插入一个奖励
                self:DrawOneReward(property, isDelayEvent, isGuide, isRefreshGoods, delayFuncList)

            else
                --不存在goodsId
                printInfo("不存在的goodsId项")
            end

        end

    end

    if isRefreshGoods then
        AppFacade.GetInstance():DispatchObservers(SGL.REFRESH_NOT_CLOSE_GOODS_EVENT, { isGuide = isGuide })
    end

    return delayFuncList
end


--[[
通用方法 领取一个奖励 更新本地数据的逻辑
@params property table {goodsId = id, num = 数量, --其他的一些数据}
@params isDelayEvent bool 如果升级了 先弹出获取界面 后升级
@params isGuide bool 是否是为了引导刚进入模块把道具插入背包
@params isRefreshGoods bool 是否发送刷新道具的事件
@params delayFuncList list 领取奖励完成回调
--]]
function GoodsManager:DrawOneReward(property, isDelayEvent, isGuide, isRefreshGoods, delayFuncList)
    -- 非法数据
    if not property.goodsId then return end

    ------------ tmp data ------------
    -- 道具id
    local goodsId = checkint(property.goodsId)
    local goodsType = GoodsUtils.GetGoodsTypeById(goodsId)
    local goodsAmount = nil
    ------------ tmp data ------------

    -- 是否存在数量的更新
    local num = nil
    if property.num then
        num = checkint(property.num)
        property.amount = num
    end

    -- 不稳定道具格式转换
    if goodsType == GoodsType.TYPE_UN_STABLE then
        if checkint(checktable(property).turnGoodsId) > 0 and checkint(checktable(property).turnGoodsNum) > 0 then
            property.goodsId = checkint(checktable(property).turnGoodsId)
            property.amount  = checkint(checktable(property).turnGoodsNum)
            property.num     = checkint(checktable(property).turnGoodsNum)

            -- 刷新道具信息
            goodsId = property.goodsId
            -- goodsType = GoodsUtils.GetGoodsTypeById(goodsId)
        end
    end

    goodsAmount = checknumber(property.amount)

    -- 更新完道具后的回调参数 {callbackFunc = nil}
    local handleResult = nil

    -- FIXME 暂时还想不通，隐藏道具检测的判断有啥意义？先去掉试试看
    -- 判断道具是否进背包
    -- if GoodsUtils.IsHiddenGoods(goodsId) then

        -- 不进背包的道具 外部自己处理
        -- AppFacade.GetInstance():DispatchObservers(SGL.CACHE_MONEY_UPDATE_UI, {
        --     hideGoodsId = goodsId, num = goodsAmount
        -- })

    -- else

        -- 进背包的道具
        handleResult = self:UpdateGoodsAmountByGoodsId(goodsId, goodsAmount, property)

    -- end

    -- 判断是否存在更新完玩家数据之后的回调参数
    if nil ~= handleResult then

        -- 存在更新后的回调
        if nil ~= handleResult.callbackFunc then
            -- 函数回调
            if isDelayEvent then
                -- 延迟回调
                table.insert(delayFuncList, handleResult.callbackFunc)
            else
                handleResult.callbackFunc()
            end
        end
        
    end
    
end


---------------------------------------------------
-- checkin data <-> goods --
--[[
    定义结构 = {
        keyName      : str     userInfo的字段
        canMinus     : bool    是否 可以为负数
        updateTopBar : bool    是否 更新货币条
        getFunc      : func    具体 get 回调
        setFunc      : func    具体 set 回调
        updateFunc   : func    更新数据的回调
    }

    如果用 物品类型 区分，则定义到 GoodsManager:GoodsDataConfigByGoodsType
    
    负责用 物品id 则为3类：
    1、userInfo 的属性字段，定义到 GoodsManager:GoodsDataConfigInCheckin
    2、如果为不确定的动态id，定义到 GoodsManager:PerfectCustomizeGoods
    3、其他的id字段全部定义到 GoodsManager:GoodsDataInManager
]]
---------------------------------------------------

--[[
checkin中玩家信息单独的道具字段配置
@return table 全部的配置信息
--]]
function GoodsManager:GoodsDataConfigInCheckin()
    if nil == self.goodsDataInCheckinMap then
        local CHAMPIONSHIP_CURRENCY_ID = FOOD.GOODS.DEFINE.CHAMPIONSHIP_CURRENCY_ID
        self.goodsDataInCheckinMap = {
            [HP_ID]                     = {keyName = 'hp',                  canMinus = true, updateTopBar = true,  getFunc = nil, setFunc = nil, updateFunc = self.UpdateGoodsDataHp}, -- 体力
            [CAPSULE_VOUCHER_ID]        = {keyName = nil,                   canMinus = true, updateTopBar = true,  getFunc = nil, setFunc = nil, updateFunc = self.UpdateGoodsDataCapsuleVoucher}, -- 灵火种
            [DIAMOND_ID]                = {keyName = 'diamond',             canMinus = true, updateTopBar = true,  getFunc = nil, setFunc = nil, updateFunc = nil}, -- 幻晶石
            [PAID_DIAMOND_ID]           = {keyName = 'paidDiamond',         canMinus = true, updateTopBar = true,  getFunc = nil, setFunc = nil, updateFunc = self.UpdateGoodsDataPaidDiamond}, -- 有偿幻晶石
            [FREE_DIAMOND_ID]           = {keyName = 'freeDiamond',         canMinus = true, updateTopBar = true,  getFunc = nil, setFunc = nil, updateFunc = nil}, -- 无偿幻晶石
            [COOK_ID]                   = {keyName = 'cookingPoint',        canMinus = true, updateTopBar = true,  getFunc = nil, setFunc = nil, updateFunc = nil}, -- 厨力点
            [GOLD_ID]                   = {keyName = 'gold',                canMinus = true, updateTopBar = true,  getFunc = nil, setFunc = nil, updateFunc = nil}, -- 金币
            [UNION_POINT_ID]            = {keyName = 'unionPoint',          canMinus = true, updateTopBar = true,  getFunc = nil, setFunc = nil, updateFunc = nil}, -- 工会币
            [REPUTATION_ID]             = {keyName = 'commerceReputation',  canMinus = true, updateTopBar = true,  getFunc = nil, setFunc = nil, updateFunc = nil}, -- 商会声望值
            [EXP_ID]                    = {keyName = 'mainExp',             canMinus = true, updateTopBar = false, getFunc = nil, setFunc = nil, updateFunc = self.UpdateGoodsDataMainExp}, -- 主角经验
            [POPULARITY_ID]             = {keyName = 'popularity',          canMinus = true, updateTopBar = false, getFunc = nil, setFunc = nil, updateFunc = self.UpdateGoodsDataPopularity}, -- 知名度
            [HIGHESTPOPULARITY_ID]      = {keyName = 'highestPopularity',   canMinus = true, updateTopBar = false, getFunc = nil, setFunc = nil, updateFunc = self.UpdateGoodsDataHighestPopularity}, -- 最高知名度
            [TIPPING_ID]                = {keyName = 'tip',                 canMinus = true, updateTopBar = true,  getFunc = nil, setFunc = nil, updateFunc = nil}, -- 餐厅小费
            [PVC_MEDAL_ID]              = {keyName = 'medal',               canMinus = true, updateTopBar = true,  getFunc = nil, setFunc = nil, updateFunc = nil}, -- 皇家对决牌子
            [MAGIC_INK_ID]              = {keyName = nil,                   canMinus = true, updateTopBar = false, getFunc = nil, setFunc = nil, updateFunc = self.UpdateGoodsDataMagicInk}, -- 魔法墨水
            [KOF_CURRENCY_ID]           = {keyName = 'kofPoint',            canMinus = true, updateTopBar = true,  getFunc = nil, setFunc = nil, updateFunc = nil}, -- 天城演武点数
            [NEW_KOF_CURRENCY_ID]       = {keyName = 'newKofPoint',         canMinus = true, updateTopBar = true,  getFunc = nil, setFunc = nil, updateFunc = nil}, -- 新天城演武点数
            [FISH_POPULARITY_ID]        = {keyName = 'fishPopularity',      canMinus = true, updateTopBar = true,  getFunc = nil, setFunc = nil, updateFunc = nil}, -- 钓场知名度
            [TTGAME_DEFINE.CURRENCY_ID] = {keyName = 'battleCardPoint',     canMinus = true, updateTopBar = true,  getFunc = nil, setFunc = nil, updateFunc = nil}, -- ttGame 专用货币
            [MEMORY_CURRENCY_M_ID]      = {keyName = 'cardFragmentM',       canMinus = true, updateTopBar = true,  getFunc = nil, setFunc = nil, updateFunc = nil}, -- 记忆商店m卡商店货币
            [MEMORY_CURRENCY_SP_ID]     = {keyName = 'cardFragmentSP',      canMinus = true, updateTopBar = true,  getFunc = nil, setFunc = nil, updateFunc = nil}, -- 记忆商店sp卡商店货币
            [ACTIVITY_QUEST_HP]         = {keyName = 'activityQuestHp',     canMinus = true, updateTopBar = true,  getFunc = nil, setFunc = nil, updateFunc = nil}, -- 活动体力
            [CHAMPIONSHIP_CURRENCY_ID]  = {keyName = 'championshipPoint',   canMinus = true, updateTopBar = true,  getFunc = nil, setFunc = nil, updateFunc = nil}, -- 武道会货币
            [CAT_SILVER_COIN_ID]        = {keyName = 'houseCatSilverPoint', canMinus = true, updateTopBar = true,  getFunc = nil, setFunc = nil, updateFunc = nil}, -- 猫银币}
            [CAT_COPPER_COIN_ID]        = {keyName = 'houseCatCopperPoint', canMinus = true, updateTopBar = true,  getFunc = nil, setFunc = nil, updateFunc = nil}, -- 猫铜币}
            [CAT_GOLD_COIN_ID]          = {keyName = 'houseCatGoldPoint',   canMinus = true, updateTopBar = true,  getFunc = nil, setFunc = nil, updateFunc = nil}, -- 猫金币}
            [CAT_STUDY_COIN_ID]         = {keyName = 'houseCatStudyPoint',  canMinus = true, updateTopBar = true,  getFunc = nil, setFunc = nil, updateFunc = nil}, -- 猫学习币}
        }
    end

    return self.goodsDataInCheckinMap
end


--[[
checkin中玩家信息单独的道具配置 道具信息保存在xxxManager中
@return table 全部的配置信息
--]]
function GoodsManager:GoodsDataInManager()
    if nil == self.goodsDataInManagerMap then
        self.goodsDataInManagerMap = {
            -- 周年庆收入货币
            [app.anniversaryMgr:GetIncomeCurrencyID()] = {
                keyName = nil, canMinus = true, updateTopBar = true,
                getFunc = self.GetAnniversaryIncomeCurrencyAmount, setFunc = self.SetAnniversaryIncomeCurrencyAmount, updateFunc = self.UpdateAnniversaryIncomeCurrencyAmount
            },
            -- 周年庆ringgame
            [app.anniversaryMgr:GetRingGameID()] = {
                keyName = nil, canMinus = true, updateTopBar = true,
                getFunc = self.GetAnniversaryIncomeCurrencyAmount, setFunc = self.SetAnniversaryIncomeCurrencyAmount, updateFunc = self.UpdateAnniversaryIncomeCurrencyAmount
            },
            -- pass卡ticket
            [PASS_TICKET_ID] = {
                keyName = nil, canMinus = true, updateTopBar = true,
                getFunc = self.GetPassTicketAmount, setFunc = self.SetPassTicketAmount, updateFunc = self.UpdatePassTicketAmount
            },
            -- 水吧货币
            [FOOD.GOODS.DEFINE.WATER_BAR_CURRENCY_ID] = {
                keyName = nil, canMinus = true, updateTopBar = true,
                getFunc = self.GetBarPoint, setFunc = self.SetBarPoint, updateFunc = self.UpdateBarPoint
            },
            -- 水吧知名度
            [FOOD.GOODS.DEFINE.WATER_BAR_POPULARITY_ID] = {
                keyName = nil, canMinus = true, updateTopBar = true,
                getFunc = self.GetBarPopularity, setFunc = self.SetBarPopularity, updateFunc = self.UpdateBarPopularity
            },
            -- 工会贡献度积分
            [UNION_CONTRIBUTION_POINT_ID] = {
                keyName = nil, canMinus = true, updateTopBar = true,
                getFunc = self.GetUnionContributionPoint, setFunc = self.SetUnionContributionPoint, updateFunc = self.UpdateUnionContributionPoint
            },
            -- 春活boss ticket
            [app.springActivity20Mgr:GetBossTicketGoodsId()] = {
                keyName = nil, canMinus = true, updateTopBar = true,
                getFunc = self.GetSummerBossTicketGoods, setFunc = self.SetSummerBossTicketGoods, updateFunc = self.UpdateSummerBossTicketGoods
            },
            -- 周年庆2020 商店经验
            [app.anniv2020Mgr:getShopExpId()] = {
                keyName = nil, canMinus = true, updateTopBar = true,
                getFunc = GetAnniv2020ShopExpAmount, setFunc = SetAnniv2020ShopExpAmount, updateFunc = self.UpdateAnniv2020ShopExpAmount
            },
        }
    end
    
    return self.goodsDataInManagerMap
end


--[[
根据道具类型获取道具更新规则
@return _ map 全部的道具配置
--]]
function GoodsManager:GoodsDataConfigByGoodsType()
    if nil == self.goodsDataByGoodsTypeMap then
        self.goodsDataByGoodsTypeMap = {
            -- 卡牌
            [GoodsType.TYPE_CARD] = {
                keyName = nil, canMinus = false, updateTopBar = false,
                -- getFunc = self.GetGoodsCard, setFunc = self.SetGoodsCard, updateFunc = self.UpdateGoodsCard
                getFunc = self.GetGoodsCard, setFunc = nil, updateFunc = self.UpdateGoodsCard
            },
            -- 堕神
            [GoodsType.TYPE_PET] = {
                keyName = nil, canMinus = false, updateTopBar = false,
                -- getFunc = self.GetGoodsPet, setFunc = self.SetGoodsPet, updateFunc = self.UpdateGoodsPet,
                getFunc = self.GetGoodsPet, setFunc = nil, updateFunc = self.UpdateGoodsPet
            },
            -- 指定堕神
            [GoodsType.TYPE_APPOINT_PET] = {
                keyName = nil, canMinus = false, updateTopBar = false,
                -- getFunc = self.GetGoodsPet, setFunc = self.SetGoodsPet, updateFunc = self.UpdateGoodsPet,
                getFunc = nil, setFunc = nil, updateFunc = self.UpdateGoodsPet
            },
            -- 菜谱
            [GoodsType.TYPE_RECIPE] = {
                keyName = nil, canMinus = false, updateTopBar = false,
                -- getFunc = self.GetGoodsRecipe, setFunc = self.SetGoodsRecipe, updateFunc = self.UpdateGoodsRecipe,
                getFunc = nil, setFunc = nil, updateFunc = self.UpdateGoodsRecipe
            },
            -- tt game 卡牌
            [GoodsType.TYPE_TTGAME_CARD] = {
                keyName = nil, canMinus = false, updateTopBar = false,
                -- getFunc = self.GetGoodsTTGameCard, setFunc = self.SetGoodsTTGameCard, updateFunc = self.UpdateGoodsTTGameCard,
                getFunc = nil, setFunc = nil, updateFunc = self.UpdateGoodsTTGameCard
            },
            -- 水吧材料
            [GoodsType.TYPE_WATERBAR_MATERIALS] = {
                keyName = nil, canMinus = false, updateTopBar = false,
                -- getFunc = self.GetGoodsWaterBarMaterials, setFunc = self.SetGoodsWaterBarMaterials, updateFunc = self.UpdateGoodsWaterBarMaterials,
                getFunc = self.GetGoodsWaterBarMaterials, setFunc = nil, updateFunc = self.UpdateGoodsWaterBarMaterials
            },
            -- 水吧饮品
            [GoodsType.TYPE_WATERBAR_DRINKS] = {
                keyName = nil, canMinus = false, updateTopBar = false,
                -- getFunc = self.GetGoodsWaterBarDrinks, setFunc = self.SetGoodsWaterBarDrinks, updateFunc = self.UpdateGoodsWaterBarDrinks,
                getFunc = self.GetGoodsWaterBarDrinks, setFunc = nil, updateFunc = self.UpdateGoodsWaterBarDrinks
            },
            -- 水吧配方
            [GoodsType.TYPE_WATERBAR_FORMULA] = {
                keyName = nil, canMinus = false, updateTopBar = false,
                -- getFunc = self.GetGoodsWaterBarFormula, setFunc = self.SetGoodsWaterBarFormula, updateFunc = self.UpdateGoodsWaterBarFormula,
                getFunc = nil, setFunc = nil, updateFunc = self.UpdateGoodsWaterBarFormula
            },
            -- 卡牌皮肤
            [GoodsType.TYPE_CARD_SKIN] = {
                keyName = nil, canMinus = false, updateTopBar = false,
                -- getFunc = self.GetGoodsCardSkin, setFunc = self.SetGoodsCardSkin, updateFunc = self.UpdateGoodsCardSkin,
                getFunc = nil, setFunc = nil, updateFunc = self.UpdateGoodsCardSkin
            },
            -- 其他道具
            [GoodsType.TYPE_OTHER] = {
                keyName = nil, canMinus = false, updateTopBar = false,
                -- getFunc = self.GetGoodsOthers, setFunc = self.SetGoodsOthers, updateFunc = self.UpdateGoodsOthers,
                getFunc = nil, setFunc = nil, updateFunc = self.UpdateGoodsOthers
            },
            -- 主角经验道具
            [GoodsType.TYPE_EXP] = {
                keyName = nil, canMinus = false, updateTopBar = false,
                -- getFunc = self.GetGoodsExp, setFunc = self.SetGoodsExp, updateFunc = self.UpdateGoodsExp,
                getFunc = nil, setFunc = nil, updateFunc = self.UpdateGoodsExp
            },
            -- 猫屋家具
            [GoodsType.TYPE_HOUSE_AVATAR] = {
                keyName = nil, canMinus = false, updateTopBar = false,
                getFunc = nil, setFunc = nil, updateFunc = self.UpdateBackpackGoods
            },
            -- 猫咪道具
            [GoodsType.TYPE_CAT_GOODS] = {
                keyName = nil, canMinus = false, updateTopBar = false,
                getFunc = nil, setFunc = nil, updateFunc = self.UpdateBackpackGoods
            }
        }
    end
    return self.goodsDataByGoodsTypeMap
end


--[[
完全自定义道具的信息配置
id不满足 1 固定不变的特定道具id 2 固定不变的特定道具类型
@params goodsId int 道具id
@return _ map 道具配置
--]]
function GoodsManager:PerfectCustomizeGoods(goodsId)
    if nil == self.customizeGoodsList then
        self.customizeGoodsList = {
            -- pt能多开，所以这个体力id为动态值，进不同pt本的主界面都会被改写。（但当前生效实际为最后一次进入的pt本id）
            -- 活动体力
            {
                judgeFunc = function (goodsId)
                    return app.activityHpMgr:HasHpData(goodsId)
                end,
                mapConfig = {
                    keyName = nil, canMinus = true, updateTopBar = true,
                    getFunc = self.GetActivityHpByGoodsId, setFunc = self.SetActivityHpByGoodsId, updateFunc = self.UdpateActivityHpByGoodsId
                }
            },
        }
    end

    for _, mapInfo in ipairs(self.customizeGoodsList) do
        if true == mapInfo.judgeFunc(goodsId) then
            -- 命中条件 直接返回
            return mapInfo.mapConfig
        end
    end

    -- 没有找到自定义配置
    return nil
end


--[[
根据道具id获取checkin玩家信息中对应的道具信息配置 是否是单独的字段 get set update 方法等
-- 分两步
-- 第一步 根据唯一id判断是否需要特殊处理 
-- 第二步 根据道具类型判断是否需要特殊处理
@params goodsId int 道具id
@return _ map 道具配置
--]]
function GoodsManager:GetGoodsDataConfigByGoodsId(goodsId)
    local goodsDataConfig = self:GetGoodsDataConfigByUniqueGoodsId(goodsId) or self:GetGoodsDataConfigByGoodsType(goodsId)
    return goodsDataConfig
end


--[[
根据id判断
@params goodsId int 道具id
@return _ map 道具配置
--]]
function GoodsManager:GetGoodsDataConfigByUniqueGoodsId(goodsId)
    local goodsDataConfig = self:GoodsDataConfigInCheckin()[checkint(goodsId)] or
                            self:GoodsDataInManager()[goodsId] or
                            self:PerfectCustomizeGoods(goodsId)
    return goodsDataConfig
end


--[[
根据道具类型判断
@params goodsId int 道具id
@return _ map 道具配置
--]]
function GoodsManager:GetGoodsDataConfigByGoodsType(goodsId)
    local goodsType = GoodsUtils.GetGoodsTypeById(goodsId)
    return self:GoodsDataConfigByGoodsType()[goodsType]
end


--[[
根据道具id获取玩家道具所持数量
@params goodsId int 道具id
@return amount int 道具数量
--]]
function GoodsManager:GetGoodsAmountByGoodsId(goodsId)
    local checkinGoodsDataConfig = self:GetGoodsDataConfigByGoodsId(goodsId)
    if nil ~= checkinGoodsDataConfig then
        if nil ~= checkinGoodsDataConfig.getFunc then
            -- 自定义的get方法
            return checkint(checkinGoodsDataConfig.getFunc(self, goodsId))
        elseif nil ~= checkinGoodsDataConfig.keyName then
            -- 通用的get方法 直接用字段名去读userInfo
            return checkint(app.gameMgr:GetUserInfo()[checkinGoodsDataConfig.keyName])
        else
            -- 啥都没读背包
            return self:GetGoodsAmountInBackpack(goodsId)
        end
    else
        -- 不存在道具信息配置 走读背包逻辑
        return self:GetGoodsAmountInBackpack(goodsId)
    end
end


--[[
根据道具id获取背包中的道具数量
@params goodsId int 道具id
@return _ number 道具数量
--]]
function GoodsManager:GetGoodsAmountInBackpack(goodsId)
    local goodsNum  = 0
    local goodsData = app.goodsMgr:GetBackpackDataByGoodsId(goodsId)
    
    if goodsData then
        goodsNum = checkint(goodsData.amount)
    end

    return goodsNum
end


--[[
根据道具id设置道具数量
@params goodsId int 道具id
@params amount int 道具数量 最终值
--]]
function GoodsManager:SetGoodsAmountByGoodsId(goodsId, amount)
    local checkinGoodsDataConfig = self:GetGoodsDataConfigByGoodsId(goodsId)
    if nil ~= checkinGoodsDataConfig then
        if nil ~= checkinGoodsDataConfig.setFunc then
            -- 自定义的set方法
            checkinGoodsDataConfig.setFunc(self, goodsId, amount)
        elseif nil ~= checkinGoodsDataConfig.keyName then
            -- 通用的set方法 直接用字段名去读userInfo
            app.gameMgr:GetUserInfo()[checkinGoodsDataConfig.keyName] = amount
        else
            -- 啥都没
            -- self:SetGoodsAmountInBackpack(goodsId, amount)
        end
    else
        -- 不存在道具信息配置 走读背包逻辑
        -- self:SetGoodsAmountInBackpack(goodsId, amount)
        
    end
end


--[[
根据道具id获取背包中的道具数量
@params goodsId int 道具id
@params amount int 道具数量 最终值
--]]
function GoodsManager:SetGoodsAmountInBackpack(goodsId, amount)
    app.goodsMgr:SetBackpackAmountByGoodsId(goodsId, amount)
end


--[[
根据道具id更新道具数量
@params goodsId int 道具id
@params deltaAmount number 变化的数量
@params goodsData table 更新的道具信息
@return updateResult table 更新完以后的参数返回 处理一些回调
--]]
function GoodsManager:UpdateGoodsAmountByGoodsId(goodsId, deltaAmount, goodsData)
    local checkinGoodsDataConfig = self:GetGoodsDataConfigByGoodsId(goodsId)

    if nil ~= checkinGoodsDataConfig then

        if nil ~= checkinGoodsDataConfig.updateFunc then

            -- 自定义的更新逻辑
            return checkinGoodsDataConfig.updateFunc(self, goodsId, deltaAmount, goodsData)

        elseif nil ~= checkinGoodsDataConfig.keyName then

            -- 根据字段名更新的通用逻辑
            return self:UpdateGoodsAmountByKey(checkinGoodsDataConfig.keyName, goodsId, deltaAmount, goodsData)

        else

            -- 不存在字段配置等信息 走通用更新背包逻辑
            return self:UpdateGoodsAmountInBackpack(goodsId, deltaAmount)

        end

    else

        -- 不存在字段配置等信息 走通用更新背包逻辑
        return self:UpdateGoodsAmountInBackpack(goodsId, deltaAmount)

    end
end


--[[
更新背包中的道具数量
@params goodsId int 道具id
@params deltaAmount number 变化的数量
@params autoRemove bool 物品数量 <= 0 时，是否自动清除数据。默认true
@return updateResult table 更新完以后的参数返回 处理一些回调
--]]
function GoodsManager:UpdateGoodsAmountInBackpack(goodsId, deltaAmount, autoRemove)
    app.gameMgr:UpdateBackpackByGoodId(goodsId, deltaAmount, autoRemove)

    return nil
end


--[[
根据checkin玩家数据中单独的key更新道具信息
@params keyName string 对应的字段名
@params goodsId int 道具id
@params deltaAmount number 变化的数量
@params goodsData table 道具信息
@return updateResult table 更新完以后的参数返回 处理一些回调
--]]
function GoodsManager:UpdateGoodsAmountByKey(keyName, goodsId, deltaAmount, goodsData)
    local checkinGoodsDataConfig = self:GetGoodsDataConfigByGoodsId(goodsId)
    if nil == checkinGoodsDataConfig then return nil end

    -- 更新数量
    app.gameMgr:GetUserInfo()[keyName] = app.gameMgr:GetUserInfo()[keyName] + checkint(deltaAmount)

    -- 是否可以为负数
    if false == checkinGoodsDataConfig.canMinus then
        app.gameMgr:GetUserInfo()[keyName] = math.max(0, app.gameMgr:GetUserInfo()[keyName])
    end

    -- 是否需要更新home top bar
    if true == checkinGoodsDataConfig.updateTopBar then
        AppFacade.GetInstance():DispatchObservers(SGL.CACHE_MONEY_UPDATE_UI, {
            [keyName] = app.gameMgr:GetUserInfo()[keyName]
        })
    end

    return nil
end


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- 具体的更新处理
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------


--[[
更新体力
@params goodsId int 道具id
@params deltaAmount number 变化的数量
@return updateResult table 更新完以后的参数返回 处理一些回调
--]]
function GoodsManager:UpdateGoodsDataHp(goodsId, deltaAmount)
    app.gameMgr:UpdateHp(app.gameMgr:GetUserInfo().hp + deltaAmount)
    AppFacade.GetInstance():DispatchObservers(SGL.CACHE_MONEY_UPDATE_UI, {
        ['hp'] = app.gameMgr:GetUserInfo().hp
    })
    return nil
end


--[[
更新灵火种
@params goodsId int 道具id
@params deltaAmount number 变化的数量
@return updateResult table 更新完以后的参数返回 处理一些回调
--]]
function GoodsManager:UpdateGoodsDataCapsuleVoucher(goodsId, deltaAmount)
    -- 更新道具数量，灵火种可以显示负数，所以要传 false 数量小于0不清背包记录。
    self:UpdateGoodsAmountInBackpack(goodsId, deltaAmount, false)

    return nil
end


--[[
更新有偿幻晶石
@params goodsId int 道具id
@params deltaAmount number 变化的数量
@return updateResult table 更新完以后的参数返回 处理一些回调
--]]
function GoodsManager:UpdateGoodsDataPaidDiamond(goodsId, deltaAmount)
    --有偿幻晶石
    app.gameMgr:GetUserInfo().paidDiamond = app.gameMgr:GetUserInfo().paidDiamond + checkint(deltaAmount)
    --总幻晶石
    app.gameMgr:GetUserInfo().diamond = app.gameMgr:GetUserInfo().diamond + checkint(deltaAmount)
    AppFacade.GetInstance():DispatchObservers(SGL.CACHE_MONEY_UPDATE_UI, { diamond = app.gameMgr:GetUserInfo().diamond })

    return nil
end


--[[
更新主角经验
@params goodsId int 道具id
@params deltaAmount number 变化的数量
@return updateResult table 更新完以后的参数返回 处理一些回调
--]]
function GoodsManager:UpdateGoodsDataMainExp(goodsId, deltaAmount)
    local isLevel, oldLevel, newLevel = app.gameMgr:UpdateExpAndLevel(checkint(deltaAmount))
    local func = function()
        --主角经验值时的处理
        AppFacade.GetInstance():DispatchObservers(SGL.PlayerLevelUpExchange, { isLevel = isLevel, oldLevel = oldLevel, newLevel = newLevel })
    end

    return {
        callbackFunc = func
    }
end


--[[
更新知名度
@params goodsId int 道具id
@params deltaAmount number 变化的数量
@return updateResult table 更新完以后的参数返回 处理一些回调
--]]
function GoodsManager:UpdateGoodsDataPopularity(goodsId, deltaAmount)
    -- 更新当前知名度
    app.gameMgr:GetUserInfo().popularity = app.gameMgr:GetUserInfo().popularity + checkint(deltaAmount)
    -- 更新一次历史最高知名度
    app.gameMgr:UpdateHighestPopularity(app.gameMgr:GetUserInfo().popularity)
    AppFacade.GetInstance():DispatchObservers(SGL.CACHE_MONEY_UPDATE_UI, { popularity = app.gameMgr:GetUserInfo().popularity })

    return nil
end


--[[
更新最高知名度
@params goodsId int 道具id
@params deltaAmount number 变化的数量
@return updateResult table 更新完以后的参数返回 处理一些回调
--]]
function GoodsManager:UpdateGoodsDataHighestPopularity(goodsId, deltaAmount)
    local val = app.gameMgr:GetUserInfo().highestPopularity + checkint(deltaAmount)
    app.gameMgr:UpdateHighestPopularity(val)

    return nil
end


--[[
更新魔法墨水
@params goodsId int 道具id
@params deltaAmount number 变化的数量
@return updateResult table 更新完以后的参数返回 处理一些回调
--]]
function GoodsManager:UpdateGoodsDataMagicInk(goodsId, deltaAmount)
    self:UpdateGoodsAmountInBackpack(goodsId, deltaAmount)
    AppFacade.GetInstance():DispatchObservers(SGL.CACHE_MAGIC_INK_UPDATE)

    return nil
end


--================================================================================================
-- goods data in xxxManager
--================================================================================================

-------------------------------------------------
-- app.anniversaryMgr:GetIncomeCurrencyID() 周年庆收入货币
-- app.anniversaryMgr
-------------------------------------------------

function GoodsManager:GetAnniversaryIncomeCurrencyAmount(goodsId)
    return app.gameMgr:GetUserInfo().voucherNum
end
function GoodsManager:SetAnniversaryIncomeCurrencyAmount(goodsId, amount)
    app.gameMgr:GetUserInfo().voucherNum = checkint(amount)
end
function GoodsManager:UpdateAnniversaryIncomeCurrencyAmount(goodsId, deltaAmount)
    app.gameMgr:GetUserInfo().voucherNum = app.gameMgr:GetUserInfo().voucherNum + checkint(deltaAmount)

    return nil
end


-------------------------------------------------
-- PASS_TICKET_ID pass卡ticket
-- app.passTicketMgr
-------------------------------------------------

function GoodsManager:GetPassTicketAmount(goodsId)
    return nil
end
function GoodsManager:SetPassTicketAmount(goodsId, amount)
    
end
function GoodsManager:UpdatePassTicketAmount(goodsId, deltaAmount)
    if app.passTicketMgr and app.passTicketMgr.InitUpgradeData then
        app.passTicketMgr:InitUpgradeData(checkint(deltaAmount))
    end

    return nil
end


-------------------------------------------------
-- FOOD.GOODS.DEFINE.WATER_BAR_CURRENCY_ID 水吧货币
-- app.waterBarMgr
-------------------------------------------------

function GoodsManager:GetBarPoint(goodsId)
    return app.waterBarMgr:getBarPoint()
end
function GoodsManager:SetBarPoint(goodsId, amount)
    
end
function GoodsManager:UpdateBarPoint(goodsId, deltaAmount)
    app.waterBarMgr:setBarPoint(app.waterBarMgr:getBarPoint() + checkint(deltaAmount))
    AppFacade.GetInstance():DispatchObservers(SGL.CACHE_MONEY_UPDATE_UI, {})

    return nil
end


-------------------------------------------------
-- FOOD.GOODS.DEFINE.WATER_BAR_POPULARITY_ID 水吧知名度
-- app.waterBarMgr
-------------------------------------------------

function GoodsManager:GetBarPopularity(goodsId)
    return app.waterBarMgr:getBarPopularity(goodsId)
end
function GoodsManager:SetBarPopularity(goodsId, amount)
    
end
function GoodsManager:UpdateBarPopularity(goodsId, deltaAmount)
    app.waterBarMgr:setBarPopularity(app.waterBarMgr:getBarPopularity() + checkint(deltaAmount))
    AppFacade.GetInstance():DispatchObservers(SGL.CACHE_MONEY_UPDATE_UI, {})

    return nil
end


-------------------------------------------------
-- UNION_CONTRIBUTION_POINT_ID 工会贡献度积分
-- app.gameMgr
-------------------------------------------------

function GoodsManager:GetUnionContributionPoint(goodsId)
    if nil ~= app.gameMgr:getUnionData() then
        return checkint(app.gameMgr:getUnionData().playerContributionPoint)
    end
    return 0
end
function GoodsManager:SetUnionContributionPoint(goodsId, amount)
    
end
function GoodsManager:UpdateUnionContributionPoint(goodsId, deltaAmount)
    return nil
end


-------------------------------------------------
-- app.springActivity20Mgr:GetBossTicketGoodsId() 春活boss ticket
-- app.springActivity20Mgr
-------------------------------------------------

function GoodsManager:GetSummerBossTicketGoods(goodsId)
    return app.springActivity20Mgr:GetBossTicketAmount()
end
function GoodsManager:SetSummerBossTicketGoods(goodsId, amount)
    
end
function GoodsManager:UpdateSummerBossTicketGoods(goodsId, deltaAmount)
    return nil
end


-------------------------------------------------
-- app.activityHpMgr:HasHpData(id) 活动体力
-- app.activityHpMgr
-------------------------------------------------

function GoodsManager:GetActivityHpByGoodsId(goodsId)
    return app.activityHpMgr:GetHpAmountByHpGoodsId(goodsId)
end
function GoodsManager:SetActivityHpByGoodsId(goodsId, amount)
    
end
function GoodsManager:UdpateActivityHpByGoodsId(goodsId, deltaAmount)
    app.activityHpMgr:UpdateHp(goodsId, checkint(deltaAmount))

    return nil
end


-------------------------------------------------
-- app.anniv2020Mgr:getShopExpId() 周年庆商店经验
-- app.anniv2020Mgr
-------------------------------------------------

function GoodsManager:GetAnniv2020ShopExpAmount(goodsId)
    return self:GetGoodsAmountInBackpack(goodsId)
end
function GoodsManager:SetAnniv2020ShopExpAmount(goodsId, amount)
    
end
function GoodsManager:UpdateAnniv2020ShopExpAmount(goodsId, deltaAmount)
    self:UpdateGoodsAmountInBackpack(goodsId, deltaAmount)
    
    local oldLevel = app.anniv2020Mgr:getShopLevel()
    app.anniv2020Mgr:checkShopLevel()
    local newLevel = app.anniv2020Mgr:getShopLevel()
    return {
        callbackFunc = function()
            app:DispatchObservers(SGL.ANNIV2020_SHOP_UPGRADE, { isUpgrade = newLevel > oldLevel, oldLevel = oldLevel, newLevel = newLevel })
        end
    }
end


--================================================================================================
-- goods data by goods type
--================================================================================================


-------------------------------------------------
-- GoodsType.TYPE_CARD
-------------------------------------------------

function GoodsManager:GetGoodsCard(goodsId)
    return 1
end
function GoodsManager:SetGoodsCard(goodsId, amount, goodsData)
    
end
function GoodsManager:UpdateGoodsCard(goodsId, deltaAmount, goodsData)
    local cardId   = checkint(goodsId)
    local cardConf = CommonUtils.GetConfig('cards', 'card', cardId) or {}
    if app.gameMgr:GetCardDataByCardId(cardId) then
    
        -- 已经拥有该卡牌 转换为卡牌碎片
        local qualityId          = cardConf.qualityId or 1
        local cardConversionConf = CommonUtils.GetConfig('cards', 'cardConversion', qualityId) or { decomposition = 10 }
        goodsData.goodsId        = checkint(cardConf.fragmentId)
        goodsData.amount         = checkint(cardConversionConf.decomposition)

        -- 插入背包
        self:UpdateGoodsAmountInBackpack(goodsData.goodsId, goodsData.amount)

    else

        -- 未拥有 新获得 更新卡牌数据
        local cardData  = clone(cardConf)
        cardData.id     = goodsData.playerCardId
        cardData.cardId = cardId
        app.gameMgr:UpdateCardDataByCardId(cardId, cardData)

    end

    return nil
end


-------------------------------------------------
-- GoodsType.TYPE_PET 堕神
-- GoodsType.TYPE_APPOINT_PET 指定堕神
-------------------------------------------------

function GoodsManager:GetGoodsPet(goodsId)
    -- 堕神
    local amount = 0
    for key, value in pairs(app.gameMgr:GetUserInfo().pets) do
        if goodsId == checkint(value.petId) then
            amount = amount + 1
        end
    end
    return amount
end
function GoodsManager:SetGoodsPet(goodsId, amount, goodsData)
    
end
function GoodsManager:UpdateGoodsPet(goodsId, deltaAmount, goodsData)
    local petData = goodsData.playerPet or {}
    local id      = checkint(petData.id)
    local petId   = checkint(petData.petId)

    app.gameMgr:UpdatePetDataById(id, petData)

    if checkint(deltaAmount) > 0 then
        -- 检测该堕神是否是正值
        app.petMgr:CheckMonsterIsLock(petId)
    end

    return nil
end


-------------------------------------------------
-- GoodsType.TYPE_RECIPE 菜谱
-------------------------------------------------

function GoodsManager:GetGoodsRecipe(goodsId)
    
end
function GoodsManager:SetGoodsRecipe(goodsId, amount, goodsData)
    
end
function GoodsManager:UpdateGoodsRecipe(goodsId, deltaAmount, goodsData)
    app.cookingMgr:UpdateCookingStyleDataById(goodsId)

    return nil
end


-------------------------------------------------
-- GoodsType.TYPE_TTGAME_CARD ttgame卡牌
-------------------------------------------------

function GoodsManager:GetGoodsTTGameCard(goodsId)
    
end
function GoodsManager:SetGoodsTTGameCard(goodsId, amount, goodsData)
    
end
function GoodsManager:UpdateGoodsTTGameCard(goodsId, deltaAmount, goodsData)
    --ttGame卡牌
    if not app.ttGameMgr:hasBattleCardId(goodsId) then
        app.ttGameMgr:addBattleCardId(goodsId)
    end

    return nil
end


-------------------------------------------------
-- GoodsType.TYPE_WATERBAR_MATERIALS 水吧材料
-------------------------------------------------

function GoodsManager:GetGoodsWaterBarMaterials(goodsId)
    return app.waterBarMgr:getMaterialNum(goodsId)
end
function GoodsManager:SetGoodsWaterBarMaterials(goodsId, amount, goodsData)
    
end
function GoodsManager:UpdateGoodsWaterBarMaterials(goodsId, deltaAmount, goodsData)
    app.waterBarMgr:addMaterialNum(goodsId, deltaAmount)

    return nil
end


-------------------------------------------------
-- GoodsType.TYPE_WATERBAR_DRINKS 水吧饮品
-------------------------------------------------

function GoodsManager:GetGoodsWaterBarDrinks(goodsId)
    return app.waterBarMgr:getDrinkNum(goodsId)
end
function GoodsManager:SetGoodsWaterBarDrinks(goodsId, amount, goodsData)
    
end
function GoodsManager:UpdateGoodsWaterBarDrinks(goodsId, deltaAmount, goodsData)
    app.waterBarMgr:addDrinkNum(goodsId, deltaAmount)
end


-------------------------------------------------
-- GoodsType.TYPE_WATERBAR_FORMULA 水吧配方
-------------------------------------------------

function GoodsManager:GetGoodsWaterBarFormula(goodsId)
    
end
function GoodsManager:SetGoodsWaterBarFormula(goodsId, amount, goodsData)
    
end
function GoodsManager:UpdateGoodsWaterBarFormula(goodsId, deltaAmount, goodsData)
    app.waterBarMgr:setFormulaData(goodsId, {formulaId = goodsId})

    return nil
end


-------------------------------------------------
-- GoodsType.TYPE_CARD_SKIN 卡牌皮肤
-------------------------------------------------

function GoodsManager:GetGoodsCardSkin(goodsId)
    
end
function GoodsManager:SetGoodsCardSkin(goodsId, amount, goodsData)
    
end
function GoodsManager:UpdateGoodsCardSkin(goodsId, deltaAmount, goodsData)
    --卡牌皮肤
    local isHave = app.cardMgr.IsHaveCardSkin(goodsId)

    if not isHave then
        -- 新获得
        app.gameMgr:UpdateCardSkinsBySkinId(goodsId)
        -- 购买皮肤券大于一的时候就相当于已经拥有
        if goodsData.num > 1 then
            isHave = true
            goodsData.num = goodsData.num - 1
        end

        AppFacade.GetInstance():DispatchObservers(SGL.SKIN_COLL_RED_DATA_UPDATE)
        AppFacade.GetInstance():DispatchObservers(SGL.CARD_SKIN_NEW_GET, {skinId = goodsId, statue = true})
    end

    if isHave then
        -- 已有 获得转换道具
        local skinConfig = CommonUtils.GetConfig('goods', 'cardSkin', goodsId) or {}
        local data = clone(skinConfig.changeGoods)
        for _, value in pairs(data) do
            value.num = checkint(value.num) * deltaAmount
        end
        -- warning --
        CommonUtils.DrawRewards(data)
        -- warning --
    end

    return nil
end


-------------------------------------------------
-- GoodsType.TYPE_OTHER 其他
-------------------------------------------------

function GoodsManager:GetGoodsOthers(goodsId)
    
end
function GoodsManager:SetGoodsOthers(goodsId, amount, goodsData)
    
end
function GoodsManager:UpdateGoodsOthers(goodsId, deltaAmount, goodsData)
    local goodsData = CommonUtils.GetConfig('goods', 'other', goodsId) or {}
    -- effectType 不是 月卡类型
    if goodsData.effectType ~= USE_ITEM_TYPE_MEMBER then
        -- 其他道具相关逻辑
        self:UpdateGoodsAmountInBackpack(goodsId, deltaAmount)
    end

    return nil
end


-------------------------------------------------
-- GoodsType.TYPE_EXP 主角经验道具
-------------------------------------------------

function GoodsManager:GetGoodsExp(goodsId)
    
end
function GoodsManager:SetGoodsExp(goodsId, amount, goodsData)
    
end
function GoodsManager:UpdateGoodsExp(goodsId, deltaAmount, goodsData)
    local goodsConfig = CommonUtils.GetConfig('goods', 'expBuff', goodsId) or {}
    local expAddition = CommonUtils.GetConfig('player', 'expAddition', tostring(goodsConfig.buff))
    local increment = (goodsConfig.buffTime or expAddition.duration) * 86400 * checkint(deltaAmount)
    local max = (goodsConfig.stack or expAddition.max) * increment
    local expBuff = app.gameMgr:GetUserInfo().expBuff
    expBuff[tostring(goodsConfig.buff)] = math.min(checkint(expBuff[tostring(goodsConfig.buff)]) + increment, max)

    return nil
end


-------------------------------------------------
-- 通用 背包数据
-------------------------------------------------

function GoodsManager:UpdateBackpackGoods(goodsId, deltaAmount, goodsData)
    -- 更新背包数量
    self:UpdateGoodsAmountInBackpack(goodsId, deltaAmount)

    local goodsType    = GoodsUtils.GetGoodsTypeById(goodsId)
    local targetAmount = self:GetGoodsAmountInBackpack(goodsId)
    AppFacade.GetInstance():DispatchObservers(SGL.BACKPACK_GOODS_REFRESH, {goodsId = goodsId, goodsAmount = targetAmount, goodsType = goodsType})
end


return GoodsManager