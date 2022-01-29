--[[
新卡池 福袋抽卡 view
--]]
local CapsuleLuckyBagView = class('CapsuleLuckyBagView', function ()
    local node = CLayout:create()
    node.name = 'home.CapsuleLuckyBagView'
    node:enableNodeEvents()
    return node
end)
local RES_DICT = {
    BOTTOM_BG          = _res('ui/home/capsuleNew/common/summon_activity_bg_.png'),
    BTN_DRAW           = _res('ui/home/capsuleNew/common/summon_newhand_btn_draw.png'),
    BTN_DRAW_DISABLED  = _res('ui/home/capsuleNew/common/summon_newhand_btn_draw_disabled.png'),
    PRIZE_BG           = _res('ui/home/capsuleNew/common/summon_newhand_label_num.png'),
    PRIZE_BG_DISABLED  = _res('ui/home/capsuleNew/common/summon_newhand_label_num_disabled.png'),
    SALE_LINE          = _res('ui/home/capsuleNew/common/summon_newhand_line_delete.png'),   
    SALE_LINE_DISABELD = _res('ui/home/capsuleNew/common/summon_newhand_line_delete_2.png'),   
}
function CapsuleLuckyBagView:ctor( ... )
	local args = unpack({...})
    self.size = args.size
    self:InitUI()
end
 
function CapsuleLuckyBagView:InitUI()
    local size = self.size 
    self:setContentSize(size)
    local function CreateView()
        local view = CLayout:create(size)
        local bottomLayer = display.newLayer(size.width - 600, 50, {bg = RES_DICT.BOTTOM_BG, ap = cc.p(0, 0)})
        view:addChild(bottomLayer, 1) 
        local bottomLayerSize = bottomLayer:getContentSize()
        local limitTimesLabel = display.newLabel(300, 160, {text = '', fontSize = 22, color = '#f0ad61'})
        bottomLayer:addChild(limitTimesLabel)
        local drawBtn = display.newButton(300, 90, {n = RES_DICT.BTN_DRAW})
        bottomLayer:addChild(drawBtn, 1)
        local drawBtnSize = drawBtn:getContentSize()
        local btnNameLabel = display.newLabel(drawBtnSize.width / 2, 90, {text = __('召唤x10'), fontSize = 24, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#5c5c5c', outlineSize = 2})
        drawBtn:addChild(btnNameLabel, 1)
        local prizeBg = display.newImageView(RES_DICT.SALE_BG, drawBtnSize.width / 2, 55)
        prizeBg:setVisible(false)
        drawBtn:addChild(prizeBg, 1)
        local consumeNumLabel = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '')
        consumeNumLabel:setHorizontalAlignment(display.TAR)
        consumeNumLabel:setPosition(cc.p(drawBtnSize.width / 2 - 14, 55))
        drawBtn:addChild(consumeNumLabel, 1)
        local consumeIcon = display.newImageView(CommonUtils.GetGoodsIconPathById(DIAMOND_ID), drawBtnSize.width / 2, 55)
        consumeIcon:setScale(0.15)
        drawBtn:addChild(consumeIcon, 1)
        local saleLine = display.newImageView(RES_DICT.SALE_LINE, drawBtnSize.width / 2, 55)
        drawBtn:addChild(saleLine, 3)
        local saleConsumeRichLabel = display.newRichLabel(300, 20)
        bottomLayer:addChild(saleConsumeRichLabel, 1)
        return {      
            view                 = view,
            drawBtn              = drawBtn,
            limitTimesLabel      = limitTimesLabel,
            consumeNumLabel      = consumeNumLabel,
            consumeIcon          = consumeIcon,
            prizeBg              = prizeBg,
            saleConsumeRichLabel = saleConsumeRichLabel,
            saleLine             = saleLine,
        }
    end
    xTry(function ( )
        self.viewData = CreateView()
        self.viewData.view:setPosition(utils.getLocalCenter(self))
        self:addChild(self.viewData.view, 1)
	end, __G__TRACKBACK__)
end
--[[
刷新限购次数
@params hasGamblingTimes int 已抽卡次数
@params maxGamblingTimes int 最大抽卡次数
--]]
function CapsuleLuckyBagView:RefreshLimitTimes( hasGamblingTimes, maxGamblingTimes )
    if checkint(hasGamblingTimes) >= checkint(maxGamblingTimes) then
        -- 次数用完
        display.commonLabelParams(self.viewData.limitTimesLabel, {text = __('次数已用完'), fontSize = 22, color = '#ffffff'})
    else
        -- 剩余次数
        local str = string.fmt(__('限购_num1_/_num2_次'), {['_num1_'] = maxGamblingTimes - hasGamblingTimes, ['_num2_'] = maxGamblingTimes})
        display.commonLabelParams(self.viewData.limitTimesLabel, {text = str, fontSize = 22, color = '#f0ad61'})
    end
end
--[[
刷新基础价格
@params consume map {
    goodsId int 道具id
    num     int 道具数量
}
--]]
function CapsuleLuckyBagView:RefreshPrize( consume )
    self.viewData.consumeNumLabel:setString(consume.num)
    self.viewData.consumeIcon:setTexture(CommonUtils.GetGoodsIconPathById(consume.goodsId))
    self.viewData.consumeIcon:setPositionX(self.viewData.consumeNumLabel:getContentSize().width / 2 + self.viewData.drawBtn:getContentSize().width / 2)
    self.viewData.prizeBg:setVisible(true)
end
--[[
刷新折扣价格
@params consume map {
    goodsId int 道具id
    num     int 道具数量
}
@params isGary  bool 是否变灰
--]]
function CapsuleLuckyBagView:RefreshSalePrize( consume, isGary )
    local goodsConf = CommonUtils.GetConfig('goods', 'goods', consume.goodsId) or {}
    if isGary then
        display.reloadRichLabel(self.viewData.saleConsumeRichLabel, {r = true, c = {
            {text = __('消耗'), fontSize = 22, color = '#bcbcbc', font = TTF_GAME_FONT, ttf = true, outline = '#58362c', outlineSize = 2},
            {text = tostring(consume.num), fontSize = 22, color = '#bcbcbc', font = TTF_GAME_FONT, ttf = true, outline = '#58362c', outlineSize = 2},
            {text = goodsConf.name, fontSize = 22, color = '#bcbcbc', font = TTF_GAME_FONT, ttf = true, outline = '#58362c', outlineSize = 2},
        }})
    else
        display.reloadRichLabel(self.viewData.saleConsumeRichLabel, {r = true, c = {
            {img = CommonUtils.GetGoodsIconPathById(consume.goodsId), scale = 0.18},
            {text = __('消耗'), fontSize = 22, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#5c372c', outlineSize = 2},
            {text = tostring(consume.num), fontSize = 22, color = '#d9bc00', font = TTF_GAME_FONT, ttf = true, outline = '#5c372c', outlineSize = 2},
            {text = goodsConf.name, fontSize = 22, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#5c372c', outlineSize = 2},
        }})
    end
end
--[[
刷新抽奖按钮
--]]
function CapsuleLuckyBagView:SetButtonEnabled( enabled )
    if enabled then
        self.viewData.drawBtn:setNormalImage(RES_DICT.BTN_DRAW)
        self.viewData.drawBtn:setSelectedImage(RES_DICT.BTN_DRAW)
        self.viewData.prizeBg:setTexture(RES_DICT.PRIZE_BG)
        self.viewData.saleLine:setTexture(RES_DICT.SALE_LINE)
    else
        self.viewData.drawBtn:setNormalImage(RES_DICT.BTN_DRAW_DISABLED)
        self.viewData.drawBtn:setSelectedImage(RES_DICT.BTN_DRAW_DISABLED)
        self.viewData.prizeBg:setTexture(RES_DICT.PRIZE_BG_DISABLED)
        self.viewData.saleLine:setTexture(RES_DICT.SALE_LINE_DISABELD)
    end
end
return CapsuleLuckyBagView
