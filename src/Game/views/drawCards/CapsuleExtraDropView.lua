--[[
新卡池 十连送道具抽卡 view
--]]
local CapuleExtraDropView = class('CapuleExtraDropView', function ()
    local node = CLayout:create()
    node.name = 'home.CapuleExtraDropView'
    node:enableNodeEvents()
    return node
end)
local CapsuleCommonPrizeNode = require("Game.views.drawCards.CapsuleCommonPrizeNode")
local RES_DICT = {
    BOTTOM_BG  = _res('ui/home/capsuleNew/common/summon_activity_bg_.png'),
    TIPS_BG    = _res('ui/home/capsuleNew/common/summon_newhand_bg_count.png'),
    COMMON_BTN = _res('ui/common/common_btn_big_orange_2.png'),
    NEWLAND_LABEL_HIGHTLIGHT = _res("ui/home/capsuleNew/newPlayerCapsule/summon_newhand_label_highlight.png"),
}
function CapuleExtraDropView:ctor( ... )
	local args = unpack({...})
    self.size = args.size
    self:InitUI()
end
 
function CapuleExtraDropView:InitUI()
    local size = self.size 
    self:setContentSize(size)
    local function CreateView()
        local view = CLayout:create(size)
        -- bottomLayer --
        local bottomLayer = display.newLayer(size.width / 2, 5, {bg = RES_DICT.BOTTOM_BG, ap = cc.p(0.5, 0)})
        if isJapanSdk() then
            bottomLayer:setPositionY(-25)
        end
        view:addChild(bottomLayer, 1) 
        local bottomLayerSize = bottomLayer:getContentSize()
        local drawOneBtn = display.newButton(300, 120, {n = RES_DICT.COMMON_BTN})
        drawOneBtn:setTag(1)
        bottomLayer:addChild(drawOneBtn, 1)
        local drawOneTitleLabel = display.newLabel(drawOneBtn:getContentSize().width / 2, drawOneBtn:getContentSize().height - 10, fontWithColor(14, {text = __('召唤'), ap = cc.p(0.5, 1)}))
        drawOneBtn:addChild(drawOneTitleLabel, 1)
        local drawOneNumLabel = display.newLabel(drawOneBtn:getContentSize().width / 2, 10, fontWithColor(14, {text = 'x1', ap = cc.p(0.5, 0)}))
        drawOneBtn:addChild(drawOneNumLabel, 1)
        local drawOnePrize = CapsuleCommonPrizeNode.new()
        drawOnePrize:setPosition(300, 55)
        drawOnePrize:setVisible(false)
        bottomLayer:addChild(drawOnePrize, 1)
        if isJapanSdk() then
            display.commonLabelParams(drawOneNumLabel, {text = __('1次'), ap = cc.p(0.5, 1)})
            display.commonLabelParams(drawOneTitleLabel, {ap = cc.p(0.5, 0)})
            drawOneNumLabel:setPositionY(drawOneBtn:getContentSize().height - 10)
            drawOneTitleLabel:setPositionY(10)
        end

        local drawTenBtn = display.newButton(bottomLayerSize.width - 300, 120, {n = RES_DICT.COMMON_BTN})
        drawTenBtn:setTag(2)
        bottomLayer:addChild(drawTenBtn, 1)
        local drawTenTitleLabel = display.newLabel(drawTenBtn:getContentSize().width / 2, drawTenBtn:getContentSize().height - 10, fontWithColor(14, {text = __('召唤'), ap = cc.p(0.5, 1)}))
        drawTenBtn:addChild(drawTenTitleLabel, 1)
        local drawTenNumLabel = display.newLabel(drawTenBtn:getContentSize().width / 2, 10, fontWithColor(14, {text = 'x10', ap = cc.p(0.5, 0)}))
        drawTenBtn:addChild(drawTenNumLabel, 1)
        if isJapanSdk() then
            display.commonLabelParams(drawTenNumLabel, {text = __('十连'), ap = cc.p(0.5, 1)})
            display.commonLabelParams(drawTenTitleLabel, {ap = cc.p(0.5, 0)})
            drawTenNumLabel:setPositionY(drawTenBtn:getContentSize().height - 10)
            drawTenTitleLabel:setPositionY(10)
        end
        local greatShowButton = display.newButton(drawTenBtn:getContentSize().width *0.5, 96, {
            n = RES_DICT.NEWLAND_LABEL_HIGHTLIGHT, enable = false, ap = display.CENTER
        })
        display.commonLabelParams(greatShowButton, {fontSize = 20, color = 'fffffff', text = string.fmt(__("必出_name_"),{_name = "SR"}), })
        drawTenBtn:addChild(greatShowButton)
        local drawTenPrize = CapsuleCommonPrizeNode.new()
        drawTenPrize:setPosition(bottomLayerSize.width - 300, 55)
        drawTenPrize:setVisible(false)
        bottomLayer:addChild(drawTenPrize, 1)

        -- bottomLayer --
        -- tipsLayer -- 
        local tipsLayer = display.newLayer(size.width, 5, {bg = RES_DICT.TIPS_BG, ap = cc.p(1, 0)})
        view:addChild(tipsLayer, 5)
        local tipsLayerSize = tipsLayer:getContentSize()
        local tipsLabel = display.newLabel(tipsLayerSize.width / 2, tipsLayerSize.height / 2,{text = '', fontSize = 22, color = '#d9c198'})
        tipsLayer:addChild(tipsLabel, 3)
        tipsLayer:setVisible(false)
        -- tipsLayer -- 
        return {      
            view             = view,
            bottomLayer      = bottomLayer,
            drawOneBtn       = drawOneBtn,
            drawTenBtn       = drawTenBtn,
            tipsLayer        = tipsLayer,
            tipsLabel        = tipsLabel,
            drawOnePrize     = drawOnePrize,
            drawTenPrize     = drawTenPrize,
        }
    end
    xTry(function ( )
        self.viewData = CreateView()
        self.viewData.view:setPosition(utils.getLocalCenter(self))
        self:addChild(self.viewData.view, 1)
	end, __G__TRACKBACK__)
end
--[[
刷新页面
--]]
function CapuleExtraDropView:RefreshView( data )
    local viewData = self.viewData
    -- 刷新价格
    viewData.drawOnePrize:RefreshUI(CommonUtils.GetCapsuleConsume(data.oneConsume))
    viewData.drawTenPrize:RefreshUI(CommonUtils.GetCapsuleConsume(data.tenConsume))
    viewData.drawOnePrize:setVisible(true)
    viewData.drawTenPrize:setVisible(true)
    -- 刷新tips
    if checkint(data.tenTimes) > 0 and checkint(data.tenTimes) ~= 1 then
        local tenTimesGamblingTimes = checkint(data.tenTimesGamblingTimes)
        local tenTimes = checkint(data.tenTimes)
        local nextExtraDropTimes = tenTimes - tenTimesGamblingTimes % checkint(tenTimes)
        local extraGoodsId = data.tenTimesGoods[1].goodsId
        local goodsConf = CommonUtils.GetConfig('goods', 'goods', extraGoodsId) or {}
        viewData.tipsLabel:setString(string.fmt(__('已达到_num1_次10连，离下次获得_name_还剩下：_num2_次'), {['_num1_'] = tenTimesGamblingTimes, ['_name_'] = goodsConf.name, ['_num2_'] = nextExtraDropTimes}))
        viewData.tipsLayer:setVisible(true)
        if isJapanSdk() then
            viewData.bottomLayer:setPositionY(5)
        end
    else
        viewData.tipsLayer:setVisible(false)
        if isJapanSdk() then
            viewData.bottomLayer:setPositionY(-25)
        end
    end
end
return CapuleExtraDropView
