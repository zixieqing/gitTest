--[[
 * author : liuzhipeng
 * descpt : 活动 皮肤嘉年华 皮肤故事popup
--]]
local NoviceWelfareGiftPopup = class('NoviceWelfareGiftPopup', function ()
    local node = CLayout:create(display.size)
    node.name = 'NoviceWelfareGiftPopup'
    node:enableNodeEvents()
    return node
end)
local RES_DICT = {
    BG           = _res('ui/common/common_bg_8.png'),
    COMMON_BTN_W = _res('ui/common/common_btn_white_default.png'),
    COMMON_BTN_G = _res('ui/common/common_btn_green.png'),
}
--[[
@params map {
    giftData map 礼包数据
    isDiscount bool 是否折扣
    index      int 礼包序号
}
--]]
function NoviceWelfareGiftPopup:ctor( params )
    local params = checktable(params)
    self.data = params.giftData
    self.isDiscount = params.isDiscount
    self.index = params.index
    self:InitUI()
end
--[[
init ui
--]]
function NoviceWelfareGiftPopup:InitUI()
    local data = self.data
    local isDiscount = self.isDiscount
    local function CreateView()
        -- 背景
        local bg = display.newImageView(RES_DICT.BG, 0, 0)
        local size = bg:getContentSize()
        -- view
        local view = CLayout:create(size)
        bg:setPosition(size.width / 2, size.height / 2)
        view:addChild(bg)
        -- mask --
        local mask = display.newLayer(size.width/2 ,size.height/2, {ap = display.CENTER , size = size, enable = true, color = cc.c4b(0,0,0,0)})
        view:addChild(mask, -1)
        -- 提示
        local tipsLabel = display.newLabel(size.width / 2, size.height - 62, {text = __('是否确认购买？'), fontSize = 24, color = '#7e2b1a',reqW = 340})
        view:addChild(tipsLabel, 5)
        -- 奖励
        local params = {parent = view, midPointX = size.width * 0.5, midPointY = size.height * 0.5 + 20, maxCol= 4, scale = 0.7, rewards = data.rewards, hideCustomizeLabel = true, hideAmount = false}
        CommonUtils.createPropList(params)
        -- 取消按钮
        local cancelBtn = display.newButton(size.width / 2 - 80, 80, {n = RES_DICT.COMMON_BTN_W})
        display.commonLabelParams(cancelBtn, fontWithColor(14, {text = __('取消')}))
        view:addChild(cancelBtn, 5)
        -- 购买按钮
        local purchaseBtn = display.newButton(size.width / 2 + 80, 80, {n = RES_DICT.COMMON_BTN_G})
        local price = nil 
        if isDiscount then
            price = __('￥') .. data.discountPrice
        else
            price = __('￥') .. data.originalPrice
        end
        display.commonLabelParams(purchaseBtn, fontWithColor(14, {text = price}))
        view:addChild(purchaseBtn, 5)
        return {
            bg               = bg,  
            view             = view,
            cancelBtn        = cancelBtn,
            purchaseBtn      = purchaseBtn,
        }
    end
    -- eaterLayer
    local eaterLayer = display.newLayer(display.cx, display.cy, {size = display.size, ap = display.CENTER, color = cc.c4b(0, 0, 0, 255 * 0.6), enable = true})
    eaterLayer:setOnClickScriptHandler(handler(self, self.CloseAction))
    self:addChild(eaterLayer, -1)
    self.eaterLayer = eaterLayer
    xTry(function ( )
        self.viewData = CreateView( )
        self:addChild(self.viewData.view)
        self.viewData.view:setPosition(display.center)
        self.viewData.cancelBtn:setOnClickScriptHandler(handler(self, self.CloseAction))
        self.viewData.purchaseBtn:setOnClickScriptHandler(handler(self, self.PurchaseButtonCallback))
        self:EnterAction()
    end, __G__TRACKBACK__)
end
--[[
关闭页面
--]]
function NoviceWelfareGiftPopup:CloseAction()
    self:runAction(cc.RemoveSelf:create())
end
--[[
购买按钮点击回调
--]]
function NoviceWelfareGiftPopup:PurchaseButtonCallback( sender )
    PlayAudioByClickNormal()
    local data = self.data
    local productId = data.productId
    app:RetrieveMediator("AppMediator"):SendSignal(COMMANDS.COMMANDS_All_Shop_GetPayOrder,{productId = productId , name = 'welfareGift', index = self.index})
    self:CloseAction()
end
--[[
进入动画
--]]
function NoviceWelfareGiftPopup:EnterAction(  )
    local viewData = self:GetViewData()
    viewData.view:setOpacity(255 * 0.3)
    viewData.view:runAction(
        cc.FadeIn:create(0.2)
    )
end
--[[
获取viewData
--]]
function NoviceWelfareGiftPopup:GetViewData()
    return self.viewData
end
return NoviceWelfareGiftPopup