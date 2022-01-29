--[[
通用提示弹窗
@params {
    title          string 标题
    text           string/table 文本提示
    textW          int  文本提示宽度
    callback       function 确认按钮回调
    cancelBack     function 取消按钮回调
    closeBgCB      function 点击背景关闭回调
    isOnlyOK       bool 是否只显示确认按钮
    isForced_      bool 是否屏蔽点击背景关闭界面
    ownTip         string/table 拥有道具提示
    viewType       int 视图显示类型 1 按钮偏移
    priceData   table {
        priceTipText            string 价格提示
        originalPriceTipText    strin  原价提示
        originalPrice           int    原价
        discountPrice           int    折扣价格
        currencyId              int    货币id
    }
}
--]]
local GameScene = require( "Frame.GameScene" )
---@class CommonPopTip
local CommonPopTip = class('CommonPopTip', GameScene)

function CommonPopTip:ctor( ... )
    local arg = unpack({...})
    self.args = arg
    self:init()
end

function CommonPopTip:init()
    local args         = self.args
    local title        = args.title
    local titleW       = args.titleW or 350
    local text         = args.text
    local textW        = args.textW
    self.callback      = args.callback
    self.cancelBack    = args.cancelBack
    self.closeBgCB     = args.closeBgCB
    self.isOnlyOK      = args.isOnlyOK == true
    self.isForced_     = args.isForced == true
    local ownTip       = args.ownTip
    local viewType     = args.viewType
    local priceData = args.priceData or {}

    local btnTextL   = args.btnTextL or __('取消')
    local btnTextR   = args.btnTextR or __('确定')
    local btnImgL    = args.btnImgL or _res('ui/common/common_btn_white_default.png')
    local btnImgR    = args.btnImgR or _res('ui/common/common_btn_orange.png')
    
   local commonBG = require('common.CloseBagNode').new({callback = function()
        -- self:runAction(cc.RemoveSelf:create())
        if not self.isForced_ then
            PlayAudioByClickClose()
            if self.closeBgCB then
                self.closeBgCB()
            end
            self:removeFromParent()
        end
    end, showLabel = not self.isForced_})
    commonBG:setName('CLOSE_BAG') 
    commonBG:setPosition(utils.getLocalCenter(self))
    self:addChild(commonBG)

    --view
    local view = CLayout:create()
    view:setName('view')
    view:setPosition(display.cx, display.cy)
    view:setAnchorPoint(display.CENTER)
    self.view = view

    local outline = display.newImageView(_res('ui/common/common_bg_8.png'),{
        enable = true
    })
    local size = outline:getContentSize()
    outline:setAnchorPoint(display.LEFT_BOTTOM)
    view:addChild(outline)
    view:setContentSize(size)
    commonBG:addContentView(view)


    if title then
        local titleLabel = self:CreateLabel(title, titleW)
        display.commonUIParams(titleLabel, {ap = display.LEFT_CENTER, po = cc.p((size.width - titleW) * 0.5, size.height - 60)})
        view:addChild(titleLabel)
        self.titleLabel = titleLabel
    end

    if text then
        local textLabel = self:CreateLabel(text, textW)
        display.commonUIParams(textLabel, {ap = display.LEFT_TOP, po = cc.p((size.width - (textW or 0)) * 0.5, size.height - 80)})
        view:addChild(textLabel)
        self.textLabel = textLabel
    end

    -- cancel button
    local cancelBtn = display.newButton(size.width/2 - 80,50,{
        n = btnImgL,
        cb = function(sender)
            PlayAudioByClickClose()
            if self.cancelBack then
                self.cancelBack()
            end
            self:removeFromParent()
        end
    })
    display.commonLabelParams(cancelBtn,fontWithColor(14,{text = __(btnTextL)}))
    view:addChild(cancelBtn)
    
    -- entry button
    local entryBtn = display.newButton(size.width/2 + 80, 50, {
       n = btnImgR,
       cb = function(sender)
            PlayAudioByClickNormal()
            if self.callback then
                self.callback()
            end
            self:removeFromParent()
        end
    })
    entryBtn:setName('entryBtn')
    display.commonLabelParams(entryBtn,fontWithColor(14, {text = __(btnTextR)}))
    view:addChild(entryBtn)
    
    ----------------------------
    -- init price tip
    local entryBtnSize = entryBtn:getContentSize()
    local cancelBtnSize = cancelBtn:getContentSize()
    local priceTipPattern, originalPrice, price, originalPriceTip
    if priceData.price then
        entryBtn:getLabel():setVisible(false)
        price = priceData.price

    elseif priceData.discountPrice then
        entryBtn:getLabel():setVisible(false)
        price = priceData.discountPrice
        priceTipPattern = {color = "#8241bf", fontSize = 22, text = priceData.priceTipText or __('折扣价')}
        
        originalPrice = priceData.originalPrice
        cancelBtn:getLabel():setVisible(false)
    elseif priceData.originalPrice then
        entryBtn:getLabel():setVisible(false)
        price = priceData.originalPrice
        priceTipPattern = {color = "#cc7043", fontSize = 22, text = priceData.priceTipText or __('原价')}
    end

    if priceData.originalPriceTipText then
        local originalPriceTip = display.newLabel(entryBtnSize.width * 0.5, 0, fontWithColor(5, {ap = display.CENTER_TOP, text = priceData.originalPriceTipText}))
        entryBtn:addChild(originalPriceTip)
        local originalPriceTipSize = originalPriceTip:getContentSize()
        
        local lineImage = display.newImageView(_res('ui/home/capsuleNew/tenTimes/summon_img_line_sale.png'), originalPriceTipSize.width * 0.5 , originalPriceTipSize.height * 0.5, 
            {ap = display.CENTER, scale9 = true})
        lineImage:setContentSize(cc.size(originalPriceTipSize.width, lineImage:getContentSize().height))
        originalPriceTip:addChild(lineImage )
    end

    if priceTipPattern then
        priceTipPattern.ap = display.CENTER_BOTTOM
        local priceTip = display.newLabel(entryBtnSize.width * 0.5, entryBtnSize.height + 4, priceTipPattern)
        entryBtn:addChild(priceTip)
    end

    if price then
        local t = {
            fontWithColor(14, {text = price}),
            {img = CommonUtils.GetGoodsIconPathById(priceData.currencyId), scale = 0.2}
        }
        local currencyPriceLabel = self:CreateLabel(t)
        display.commonUIParams(currencyPriceLabel, {display.CENTER, po = cc.p(entryBtnSize.width * 0.5 + 4, entryBtnSize.height * 0.5 + 4)})
        entryBtn:addChild(currencyPriceLabel)
        self.currencyPriceLabel = currencyPriceLabel
        CommonUtils.AddRichLabelTraceEffect(currencyPriceLabel)
    end
    
    if originalPrice then
        local t = {
            fontWithColor(14, {text = originalPrice}),
            {img = CommonUtils.GetGoodsIconPathById(priceData.currencyId), scale = 0.2}
        }
        local currencyPriceLabel = self:CreateLabel(t)
        display.commonUIParams(currencyPriceLabel, {display.CENTER, po = cc.p(cancelBtnSize.width * 0.5 + 4, cancelBtnSize.height * 0.5 + 4)})
        cancelBtn:addChild(currencyPriceLabel)
        CommonUtils.AddRichLabelTraceEffect(currencyPriceLabel)
    end

    -- init price tip
    ----------------------------

    if ownTip then
        local ownTipLabel = self:CreateLabel(ownTip)
        display.commonUIParams(ownTipLabel, {ap = display.RIGHT_CENTER, po = cc.p(size.width - 60, 40)})
        view:addChild(ownTipLabel)
    end

    if self.isOnlyOK then
        cancelBtn:setVisible(false)
        entryBtn:setPositionX(size.width/2)
    end

    if viewType == 1 then
        display.commonUIParams(cancelBtn, {po = cc.p(cancelBtn:getPositionX(), 95)})
        display.commonUIParams(entryBtn, {po = cc.p(entryBtn:getPositionX(), 95)})
    elseif viewType == 2 then
        cancelBtn:setPositionY(70)
        entryBtn:setPositionY(70)
    end
end

function CommonPopTip:CreateLabel(text, textW)
    local label = nil
    if tolua.type(text) == 'string' then
        label = display.newLabel(0, 0, fontWithColor('6', {text = text, w = textW}))
    elseif tolua.type(text) == 'table' then
        label = display.newRichLabel(0, 0, {w = textW or 100, r = true, sp = 5, c = text})
    end

    return label
end

return CommonPopTip
