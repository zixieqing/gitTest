--[[
    通用货币条
--]]
local GoodPurchaseNode = require('common.GoodPurchaseNode')
---@class CommonMoneyBar
local CommonMoneyBar = class('CommonMoneyBar', function ()
    return display.newLayer(0, 0, {name = 'common.CommonMoneyBar', enableEvent = true})
end)

local RES_DICT = {
    MAIN_BG_MONEY = _res('ui/home/nmain/main_bg_money.png'),
}

local CreateView = nil

--[[
    hidePlus     是否 隐藏加号图标（默认：false，隐藏加号并不会禁用点击）
    disable      是否 禁止点击弹出行为（默认：false）
    restoreTips  是否 点击显示恢复提示（默认：false，回复体力之类的使用）
    showAnimate  是否 用动画方式变化数值（默认：false）
    {hidePlus = false, disable = false, restoreTips = false, showAnimate = false}
    -- gainPopup    是否 点击显示获取弹窗（默认：false）改为整体控制了，因为可能某个界面下全部不想打开前往去跳转
]]
local MONEY_DEFINES = {
    [DIAMOND_ID]                                 = {hidePlus = false},
    [GOLD_ID]                                    = {hidePlus = false},
    [HP_ID]                                      = {hidePlus = true},
    [SKIN_COUPON_ID]                             = {hidePlus = true},
    [TTGAME_DEFINE.CURRENCY_ID]                  = {hidePlus = true},
    [TTGAME_DEFINE.EXCHANGE_ID]                  = {hidePlus = true},
    [FOOD.GOODS.DEFINE.WATER_BAR_CURRENCY_ID]    = {hidePlus = true},
    [FOOD.GOODS.DEFINE.CHAMPIONSHIP_CURRENCY_ID] = {hidePlus = true},
}


function CommonMoneyBar:ctor(...)
    local args = unpack({...}) or {}

    -- create view
    self.viewData_ = CreateView()
    self:addChild(self.viewData_.view)

    self:RefreshUI(args)
end


CreateView = function()
    local view = display.newLayer()
    local size = view:getContentSize()

    -- money barBg
    local moneyBarBg = display.newImageView(_res(RES_DICT.MAIN_BG_MONEY), size.width, size.height, {ap = display.RIGHT_TOP, scale9 = true, size = cc.size(1, 54)})
    view:addChild(moneyBarBg)

    -- money layer
    local moneyLayer = display.newLayer()
    view:addChild(moneyLayer)

    return {
        view         = view,
        moneyBarBg   = moneyBarBg,
        moneyLayer   = moneyLayer,
    }
end


function CommonMoneyBar:getViewData()
    return self.viewData_
end


--[[
    是否 点击加号弹出获取弹窗
]]
function CommonMoneyBar:isEnableGainPopup()
    return self.isEnableGainPopup_ == true
end
function CommonMoneyBar:setEnableGainPopup(isEnable)
    self.isEnableGainPopup_ = isEnable == true
    self:updateMoneyBar()
end


--[[
    重载货币条
    -- @param moneyIdList   : list    货币id列表（默认自带金币和钻石）
    -- @param isHideDefault : bool    是否隐藏默认的金币和钻石（默认值：false)
    -- @param customDefine  : map     自定义定义模式（默认值：nil）
]]
function CommonMoneyBar:reloadMoneyBar(_moneyIdList, isHideDefault, customDefine)
    local moneyIdList = checktable(_moneyIdList)
    if isHideDefault ~= true then
        for i = #moneyIdList, 1, -1 do
            local moneyId = checkint(moneyIdList[i])
            if checkint(moneyId) == GOLD_ID or checkint(moneyId) == DIAMOND_ID then
                table.remove(moneyIdList, i)
            end
        end
        table.insert(moneyIdList, GOLD_ID)
        table.insert(moneyIdList, DIAMOND_ID)
    end
    
    -- clean moneyLayer
    local moneyBarBg = self:getViewData().moneyBarBg
    local moneyLayer = self:getViewData().moneyLayer
    moneyLayer:removeAllChildren()

    -- update moneyLayer
    local MONEY_NODE_GAP = 16
    local moneyLayerSize = moneyLayer:getContentSize()
    local moneryBarSize  = cc.size(20, moneyBarBg:getContentSize().height)
    for i = #moneyIdList, 1, -1 do
        local moneyId     = checkint(moneyIdList[i])
        local moneyDefine = customDefine and customDefine[moneyId] or checktable(MONEY_DEFINES[moneyId])
        local moneyNode = GoodPurchaseNode.new({
            id           = moneyId,
            disable      = moneyDefine.hidePlus == true,
            animate      = moneyDefine.showAnimate ~= true,
            isShowHpTips = moneyDefine.restoreTips == true,
            isEnableGain = self:isEnableGainPopup(),
        })
        moneyNode.viewData.touchBg:setTag(checkint(moneyId))
        moneyNode:setPosition(display.SAFE_R - moneryBarSize.width, moneyLayerSize.height - 26)
        moneyNode:setControllable(not (moneyDefine.disable == true))
        moneyNode:setAnchorPoint(display.RIGHT_CENTER)
        moneyNode:setName(moneyId)
        moneyLayer:addChild(moneyNode)

        moneryBarSize.width = moneryBarSize.width + moneyNode:getContentSize().width + MONEY_NODE_GAP
    end

    -- update moneyBarBg
    moneryBarSize.width = 40 + moneryBarSize.width + (display.width - display.SAFE_R)
    moneyBarBg:setContentSize(moneryBarSize)

    -- update money value
    self:updateMoneyBar()
end


function CommonMoneyBar:updateMoneyBar(signal)
    for _, moneyNode in ipairs(self:getViewData().moneyLayer:getChildren()) do
        local moneyId = checkint(moneyNode:getName())
        moneyNode.isEnableGain = self:isEnableGainPopup()
        moneyNode:updataUi(moneyId, signal and signal:GetBody() or {})
    end
end


function CommonMoneyBar:onEnter()
    app:RegistObserver(SGL.CACHE_MONEY_UPDATE_UI, mvc.Observer.new(self.updateMoneyBar, self))
    app:RegistObserver(SGL.REFRESH_NOT_CLOSE_GOODS_EVENT, mvc.Observer.new(self.updateMoneyBar, self))
end
function CommonMoneyBar:onExit()
    app:UnRegistObserver(SGL.CACHE_MONEY_UPDATE_UI, self)
    app:UnRegistObserver(SGL.REFRESH_NOT_CLOSE_GOODS_EVENT, self)
end


-------------------------------------------------
-- 下面的方法渐渐淘汰，使用上面的方式

function CommonMoneyBar:RefreshUI(args)
    self:IninValue(args)
    self:UpdateUI()
end
function CommonMoneyBar:IninValue(args)
    local moneyIdMap = args.moneyIdMap or {}
    if moneyIdMap and not args.hideDefault then
        moneyIdMap[tostring(GOLD_ID)]         = nil
        moneyIdMap[tostring(DIAMOND_ID)]      = nil
        moneyIdMap[tostring(PAID_DIAMOND_ID)] = nil
        moneyIdMap[tostring(FREE_DIAMOND_ID)] = nil
    end

    -- money data
    local moneyIdList = args.moneyIdList or table.keys(moneyIdMap or {})
    if not args.hideDefault then
        table.insert(moneyIdList, GOLD_ID)
        table.insert(moneyIdList, DIAMOND_ID)
    end
    self.moneyIdList = moneyIdList
    self.isEnableGain = args.isEnableGain
    self:setEnableGainPopup(self.isEnableGain == true)
end
function CommonMoneyBar:UpdateUI()
    -- clean moneyLayer
    local viewData   = self:getViewData()
    local moneyBarBg = viewData.moneyBarBg
    local moneyLayer = viewData.moneyLayer
    if moneyLayer:getChildrenCount() > 0 then
        moneyLayer:removeAllChildren()
    end

    -- update moneyLayer
    local MONEY_NODE_GAP = 16
    local moneyLayerSize = moneyLayer:getContentSize()
    local moneryBarSize  = cc.size(20, moneyBarBg:getContentSize().height)
    for i = #self.moneyIdList, 1, -1 do
        local moneyId = checkint(self.moneyIdList[i])
        local isDisable = moneyId ~= HP_ID and moneyId ~= GOLD_ID and moneyId ~= DIAMOND_ID and moneyId ~= app.ptDungeonMgr:GetHPGoodsId() and not self.isEnableGain
        local moneyNode = GoodPurchaseNode.new({id = moneyId, animate = true, disable = isDisable, isEnableGain = self.isEnableGain})
        moneyNode.viewData.touchBg:setTag(checkint(moneyId))
        moneyNode:setPosition(display.SAFE_R - moneryBarSize.width, moneyLayerSize.height - 26)
        moneyNode:setAnchorPoint(display.RIGHT_CENTER)
        moneyNode:setName(moneyId)
        moneyLayer:addChild(moneyNode)

        moneryBarSize.width = moneryBarSize.width + moneyNode:getContentSize().width + MONEY_NODE_GAP
    end

    -- update moneyBarBg
    moneryBarSize.width = 40 + moneryBarSize.width + (display.width - display.SAFE_R)
    moneyBarBg:setContentSize(moneryBarSize)

    -- update money value
    self:updateMoneyBar()
end


return CommonMoneyBar