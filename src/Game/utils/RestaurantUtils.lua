--[[
 * author : kaishiqi
 * descpt : 餐厅工具类
]]
RestaurantUtils = {}


RESTAURANT_AVATAR_NODE_DEBUG = false

DRAG_AREA_RECT = cc.rect(86, 222, 1248, 448)

RESTAURANT_TILED_SIZE = 16

RESTAURANT_TILED_WIDTH = 84
RESTAURANT_TILED_HEIGHT = 62


RESTAURANT_ROLE_TYPE = {
    Waiters  = 1, --服务员
    Visitors = 2, --来客
}


RESTAURANT_EAT_STATS = {
    WAITING   = 0,
    EATING    = 1,
    FINISHING = 2,
    SERVICING = 3, --正在被服务中的逻辑
}


RESTAURANT_EVENTS = {
    EVENT_DESTINATION                        = 'EVENT_DESTINATION',                                 --到达目标点位置
    EVENT_SERVICE_ANIMATION                  = 'EVENT_SERVICE_ANIMATION',                           --服务员在桌子边服务时动画的逻辑结束后的消息
    EVENT_NEW_CUSTOM_ARRIVAL                 = 'EVENT_NEW_CUSTOM_ARRIVAL',                          --新的客人到来通知，取等待队列的逻辑
    EVENT_DESK_INFO                          = 'EVENT_DESK_INFO',                                   --空桌子信息的逻辑
    EVENT_SWITCH_WAITER                      = 'EVENT_SWITCH_WAITER',                               --更换服务员
    EVENT_BACK_DECORATE                      = 'EVENT_BACK_DECORATE',
    EVENT_CLICK_DESK                         = 'EVENT_CLICK_DESK',
    EVENT_AVATAR_SHOP                        = 'EVENT_AVATAR_SHOP',                                 -- 家具商店
    EVENT_AVATAR_SHOP_SIGN_OUT               = 'EVENT_AVATAR_SHOP_SIGN_OUT',                        -- 退出家具商店
    EVENT_AVATAR_SHOP_THEME_VISIBLE_UNREGIST = 'EVENT_AVATAR_SHOP_THEME_VISIBLE_UNREGIST',          -- 隐藏 家具商店 主题 或解除注册
    EVENT_AVATAR_SHOP_UPDATE_REMIND          = 'EVENT_AVATAR_SHOP_UPDATE_REMIND',                   -- 更新商店红点
    EVENT_EMPTY_RECIPE                       = 'EVENT_EMPTY_RECIPE',                                --清空菜谱
    EVENT_EMPTY_ONE_RECIPE                   = 'EVENT_EMPTY_ONE_RECIPE',
    EVENT_CLOSE_MAKE_RECIPE                  = 'EVENT_CLOSE_MAKE_RECIPE',
    EVENT_CLOSED_MAKING_SCHEDULER            = 'EVENT_CLOSED_MAKING_SCHEDULER',                     --关闭做菜倒计时
    EVENT_UPDATA_COOKLIMIT_NUM               = 'EVENT_UPDATA_COOKLIMIT_NUM',                        --刷新橱窗上限
    EVENT_AVARAR_DATA_SYS                    = "AVARAR_DATA_SYS"  -- 同步avatar 数据
}


ATTRIBUTE_ADDITION = {
    POPULARITY  = 1, --知名度
    VELOCITY    = 2, --上座速度
    SELL_PRICE  = 3, --售价
    SELL_AMOUNT = 4, --出售数量
}


VISITOR_STATES = {
    IDLE     = {id = 1, name = 'idle'},
    IDLE_TWO = {id = 2, name = 'idle2'},
    IDLE3    = {id = 3, name = 'idle3'},
    RUN      = {id = 4, name = 'run'},
    EAT      = {id = 5, name = 'eat'},
}


WaiterPositions = {
    {w = 2*2, h = 40}, { w = 4, h = 30}, { w = 4, h = 20}, {w = 4, h = 10}
}


-- 分类类型
RESTAURANT_AVATAR_TYPE = {
    ALL                   = 0,  --全部
    CHAIR                 = 1,  --椅子
    CHAIR_SIGNLE          = 11,
    CHAIR_DOUBLE          = 12,
    DECORATION            = 2,  --装饰
    DECORATION_FLOWER     = 21,
    DECORATION_DECORATION = 22,
    DECORATION_FUNITURE   = 23, --家具
    DECORATION_PET        = 24, --萌宠
    WALL                  = 3,
    COUNTER               = 4,  --柜台
    FLOOR                 = 5,  --地板
    CEILING               = 6,  --顶
    THEME                 = 100, -- 主题
}


-- 投放类型
RESTAURAN_AVATAR_SELL_TYPE = {
    AVATAR_SHOP  = 1, --家具商店
    SKIN_CAPSULE = 2, --皮肤卡池
}


-- avatar 类型名称
RESTAURANT_AVATAR_MAIN_TYPE_NAME_FUNCTION_MAP = {
    [RESTAURANT_AVATAR_TYPE.THEME]      = function () return __('主题') end,
    [RESTAURANT_AVATAR_TYPE.CHAIR]      = function () return __('桌椅') end,
    [RESTAURANT_AVATAR_TYPE.DECORATION] = function () return __('装饰') end,
    [RESTAURANT_AVATAR_TYPE.WALL]       = function () return __('墙纸') end,
    [RESTAURANT_AVATAR_TYPE.FLOOR]      = function () return __('地板') end,
    [RESTAURANT_AVATAR_TYPE.CEILING]    = function () return __('吊饰') end,
}


function RestaurantUtils.ConvertTiledToPixelsCenter(tiledPos)
    return cc.p(tiledPos.w * RESTAURANT_TILED_SIZE + RESTAURANT_TILED_SIZE / 2, tiledPos.h * RESTAURANT_TILED_SIZE + RESTAURANT_TILED_SIZE/ 2)
end



--[[
--将位置信息转换为tile点的逻辑
--]]
function RestaurantUtils.ConvertPixelsToTiled(pos)
    local w = pos and math.floor(pos.x / RESTAURANT_TILED_SIZE) or 0
    local h = pos and math.floor(pos.y / RESTAURANT_TILED_SIZE) or 0
    return {w = w, h = h}
end


--[[
    得到对应的子类别
--]]
function RestaurantUtils.GetAvatarSubType(mainType, subType)
    if not subType then subType = 0 end
    local ret = 0
    if checkint(subType) > 0 then
        ret = checkint(mainType) * 10 + checkint(subType)
    else
        ret = checkint(mainType)
    end
    return ret
end


--[[
根据 avatar 类型 获取 avatar 类型名称
@params avatarType      int    avatar 类型
@return avatarTypeName  string avatar 类型名称
--]]
function RestaurantUtils.GetAvatarMainTypeName(avatarType)
	local nameFunc = RESTAURANT_AVATAR_MAIN_TYPE_NAME_FUNCTION_MAP[checkint(avatarType)]
    return nameFunc and nameFunc() or ''
end


-- 通过 mangerId 获得代理店长icon
function RestaurantUtils.GetLobbyAgentShopOwnerIconByMangerId(_mangerId)
    local mangerId = checkint(_mangerId)
    local photoId = nil
    local allConfs = CommonUtils.GetConfigAllMess('manager', 'restaurant')
    for _, conf in pairs(allConfs) do
        if checkint(conf.id) == mangerId then
            photoId = conf.photoId
        end
    end
    return CommonUtils.GetNpcIconPathById(photoId, NpcImagType.TYPE_HEAD)
end


--[[
    根据指定类型，获取到配表中全部对应的avatar的数据。
    @param atype 指定类别
--]]
function RestaurantUtils.GetAllAvatarByType(atype)
    local datas       = CommonUtils.GetConfigAllMess('avatar', 'restaurant')
    local targetDatas = {}
    for name, val in pairs(datas) do
        if checkint(atype) == RESTAURANT_AVATAR_TYPE.CHAIR then
            if checkint(atype) == checkint(val.mainType) then
                table.insert(targetDatas, val)
            end
        else
            if atype == RESTAURANT_AVATAR_TYPE.DECORATION then
                if checkint(atype) == checkint(val.mainType) then
                    table.insert(targetDatas, val)
                end
            else
                local tType = RestaurantUtils.GetAvatarSubType(val.mainType, val.subType)
                if checkint(atype) == tType then
                    table.insert(targetDatas, val)
                end
            end
        end
    end
    if table.nums(targetDatas) > 0 then
        sortByMember(targetDatas, 'id')
    end
    return targetDatas
end


--[[
根据 avatarId 获取到 buffDesc
--]]
function RestaurantUtils.GetBuffDescByAvatarId(avatarId)
    local avatarConf = CommonUtils.GetConfigNoParser('restaurant', 'avatar', avatarId) or {}

    local buffDescrList = {}
    -- for name, val in pairs(avatarConf.buffType or {}) do
    --     local buffInfo = CommonUtils.GetConfigNoParser('restaurant', 'buffType', val.targetType)
    --     if buffInfo then
    --         table.insert(buffDescrList, checkstr(CommonUtils.GetBufferDescription(buffInfo.descr, val)))
    --     end
    -- end
    -- local buffInfo = CommonUtils.GetConfigNoParser('restaurant', 'buffType', val.targetType)
    -- local buffDesc = table.concat(buffDescrList, '\n')
    local buffDesc = string.fmt(__('餐厅美观度提高_target_num_点'), {['_target_num_'] = avatarConf.beautyNum})

    return buffDesc, avatarConf.name
end


--==============================--
--desc: 创建 DragNode
--@params goodsId int  道具id
--@params enable  bool  是否启用拖拽
--@return isHave  bool 是否拥有
--==============================--
function RestaurantUtils.CreateDragNode(goodsId, enable)
    if CommonUtils.GetGoodTypeById(goodsId) ~= GoodsType.TYPE_AVATAR then
        print('>>> error <<< -> goodsId not is avatar in #RestaurantUtils.CreateDragNode#', tostring(goodsId))
        return
    end
    local avatarConfig   =  CommonUtils.GetConfigNoParser('restaurant', 'avatar', goodsId)
    if avatarConfig == nil then
        print('>>> error <<< -> can not find avatar config in #RestaurantUtils.CreateDragNode#', tostring(goodsId))
        return
    end
    local locationConfig =  CommonUtils.GetConfigNoParser('restaurant', 'avatarLocation', goodsId)
    if locationConfig == nil then
        print('>>> error <<< -> can not find avatarLocation config in #RestaurantUtils.CreateDragNode#', tostring(goodsId))
        return
    end
    local nType          = checkint(avatarConfig.mainType)
    local goodIcon = require('Game.views.restaurant.DragNode').new({id = goodsId, avatarId = goodsId, nType = nType, configInfo = locationConfig, enable = checkbool(enable)})
    goodIcon:setTag(goodsId)
    return goodIcon
end


--==============================--
--desc: udpate DragNode
--@params oldDragNode userdata 旧的drag node
--@params goodsId int  道具id
--@params enable  bool  是否启用拖拽
--@return isHave  bool 是否拥有
--==============================--
function RestaurantUtils.UpdateDragNode(oldDragNode, goodsId, benchmarkSize, enable)
    if oldDragNode then
        if checkint(oldDragNode:getTag()) == checkint(goodsId) then
            return
		end
        oldDragNode:setVisible(false)
        oldDragNode:runAction(cc.RemoveSelf:create())
    end
    local node = RestaurantUtils.CreateDragNode(goodsId, enable)
    RestaurantUtils.FixNodeScale(node, benchmarkSize)
    return node
end


--==============================--
--desc: 修正 node 位置
--@params node          userdata node
--@params benchmarkSize table  基准大小
--@return 
--==============================--
function RestaurantUtils.FixNodeScale(node, benchmarkSize)
    local nodeSize     = node:getContentSize()
    local scaleX, scaleY = 1, 1
    local curNodeWidth = nodeSize.width
    local curNodeHeight = nodeSize.height

    benchmarkSize = benchmarkSize or cc.size(160, 160)

    local benchmarkWidth = benchmarkSize.width
    local benchmarkHeight = benchmarkSize.height

	if curNodeWidth > benchmarkWidth then
        scaleX = benchmarkWidth / curNodeWidth
    end
    if curNodeHeight > benchmarkHeight then
        scaleY = benchmarkHeight / curNodeHeight
    end
    node:setScale(math.min(scaleX, scaleY))
end
