--[[
 * author : liuzhipeng
 * descpt : 抽卡 管理器
]]
local BaseManager     = require('Frame.Manager.ManagerBase')
---@class CapsuleManager
local CapsuleManager = class('CapsuleManager', BaseManager)

CAPSULE_SKIN_TYPE = {
    ONE_CARD_SKIN = 1, -- 单抽皮肤
    ONE_GOODS     = 2, -- 单抽道具
    TEN           = 3, -- 十连
}
-------------------------------------------------
-- manager method

CapsuleManager.DEFAULT_NAME = 'CapsuleManager'
CapsuleManager.instances_   = {}


function CapsuleManager.GetInstance(instancesKey)
    instancesKey = instancesKey or CapsuleManager.DEFAULT_NAME

    if not CapsuleManager.instances_[instancesKey] then
        CapsuleManager.instances_[instancesKey] = CapsuleManager.new(instancesKey)
    end
    return CapsuleManager.instances_[instancesKey]
end


function CapsuleManager.Destroy(instancesKey)
    instancesKey = instancesKey or CapsuleManager.DEFAULT_NAME

    if CapsuleManager.instances_[instancesKey] then
        CapsuleManager.instances_[instancesKey]:release()
        CapsuleManager.instances_[instancesKey] = nil
    end
end


-------------------------------------------------
-- life cycle

function CapsuleManager:ctor(instancesKey)
    self.super.ctor(self)

    self.randomPoolFirstEntry = true -- 用于判断是否是第一次进入铸池抽卡活动

    if CapsuleManager.instances_[instancesKey] then
        funLog(Logger.INFO, "注册相关的facade类型")
    else
        self:initial()
    end
end


function CapsuleManager:initial()
end


function CapsuleManager:release()
end


-------------------------------------------------
-- public method
--[[
获取展示的抽卡道具消耗
@params consume list 抽卡消耗 {
    goodsId int 道具id
    num     int 道具数量
}
--]]
function CapsuleManager:GetCapsuleConsume( consume )
    if not consume or next(consume) == nil then return {} end
    local capsuleConsume = {}
    for i, v in ipairs(consume) do
        if i == #consume then
            capsuleConsume = v
            break
        else
            if app.gameMgr:GetAmountByGoodId(v.goodsId) >= checkint(v.num) then
                capsuleConsume = v
                break
            end
        end
    end
    return capsuleConsume
end
--[[
获取物品等级信息
@params goodsId int 物品id
@return map {
    rate       int 物品等级
    coinType   int 硬币类型
    buttonType str 按钮类型
}
--]]
function CapsuleManager:GetRateDataByGoodsId( goodsId )
    local goodsConf = CommonUtils.GetConfig('goods', 'goods', goodsId)
    local coinType = 1
    local rate = 1
    local buttonType = 'goods'
    if goodsConf then
        if tostring(goodsConf.type) == GoodsType.TYPE_CARD_SKIN then
            -- 皮肤
            rate = checkint(goodsConf.rate)
            coinType = 1
            buttonType = 'skin'
        else
            -- 其他
            if checkint(goodsConf.quality) <= 1 then
                rate = 3
            elseif checkint(goodsConf.quality) <= 3 then
                rate = 2
            elseif checkint(goodsConf.quality) <= 5 then
                rate = 1
            end
            coinType = 2
            buttonType = 'goods'
        end
    end
    return {
        coinType   = coinType,
        rate       = rate,
        buttonType = buttonType,
    }
end

--[[
皮肤卡池商店 商品列表排序
@params products table 商品列表
--]]
function CapsuleManager:SortProductDatas(products)
    if products == nil or next(products) == nil then return end

    local getPriority = function (leftPurchaseNum)
        return (leftPurchaseNum <= 0 and leftPurchaseNum ~= -1) and 0 or 1
    end
    local listSortFunc = function (a, b)
        local aLeftNum = checkint(a.leftPurchaseNum)
        local bLeftNum = checkint(b.leftPurchaseNum)

        local aPriority = getPriority(aLeftNum)
        local bPriority = getPriority(bLeftNum)
        if aPriority == bPriority then
            return checkint(a.productId) < checkint(b.productId)
        end
        return aPriority > bPriority
    end
    table.sort(products, listSortFunc)
end
--[[
通过卡牌碎片id获取卡牌id
--]]
function CapsuleManager:GetCardIdByFragmentId( fragmentId )
    if CommonUtils.GetGoodTypeById(checkint(fragmentId)) == GoodsType.TYPE_CARD_FRAGMENT then
        local fragmentData = CommonUtils.GetConfig('goods', 'goods', fragmentId) or {}
        local cardId = checkint(fragmentData.cardId)
        return cardId
    end
end
--[[
转换奖励数据结构
--]]
function CapsuleManager:ConvertRewardsData( data )
    if not data then return {} end
    local rewardsData = clone(data.rewards)
    for i, v in ipairs(checktable(rewardsData)) do
        -- 碎片转换
        if CommonUtils.GetGoodTypeById(v.goodsId) == GoodsType.TYPE_CARD_FRAGMENT then
            local cardId = self:GetCardIdByFragmentId(v.goodsId)
            v.turnGoodsId = v.goodsId 
            v.turnGoodsNum = v.num
            v.goodsId = cardId
            v.num = 1
        end
    end
    -- 处理额外奖励
    if data.extraRewards then
        for i, v in ipairs(checktable(data.extraRewards)) do
            table.insert(rewardsData, v)
        end
    end
    -- 处理活动奖励
    if data.activityRewards then
        for i, v in ipairs(checktable(data.activityRewards)) do
            table.insert(rewardsData, v)  
        end
    end
    return rewardsData
end
--[[
抽卡道具不足提示
@params consumeGoodsId int 需求道具id
--]]
function CapsuleManager:ShowGoodsShortageTips( consumeGoodsId )
    if not consumeGoodsId then return end
    if checkint(consumeGoodsId) == DIAMOND_ID then
        if GAME_MODULE_OPEN.NEW_STORE then
            app.uiMgr:showDiamonTips()
        else
            local tipsText = __('幻晶石不足是否去商城购买？')
            local tipsView = require('common.NewCommonTip').new({text = tipsText, callback = function()
                app.router:Dispatch({name = 'HomeMediator'}, {name = 'ShopMediator'})
            end, isOnlyOK = false})
            tipsView:setPosition(display.center)
            app.uiMgr:GetCurrentScene():AddDialog(tipsView)
        end
    else
        app.uiMgr:AddDialog('common.GainPopup', {goodId = consumeGoodsId})
    end
end
--[[
获取抽卡页签的屏幕中心点
--]]
function CapsuleManager:GetPageViewCenter()
    local contentOffX  = 290
    local contentOffY  = 85
    local cx = display.cx - contentOffX - display.SAFE_L
    local cy = display.cy
    return cc.p(cx, cy)
end
--[[
获取铸池卡池状态（是否为首次进入）
@return randomPoolFirstEntry bool 是否是第一次进入铸池抽卡
--]]
function CapsuleManager:GetRandomPoolState()
    return self.randomPoolFirstEntry
end
--[[
设置铸池卡池状态（是否为首次进入）
@params randomPoolFirstEntry bool 是否是第一次进入铸池抽卡
--]]
function CapsuleManager:SetRandomPoolState( randomPoolFirstEntry )
    self.randomPoolFirstEntry = randomPoolFirstEntry
end
-------------------------------------------------
-- private method


return CapsuleManager
