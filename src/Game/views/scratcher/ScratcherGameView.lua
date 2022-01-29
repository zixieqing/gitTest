local GameScene = require( "Frame.GameScene" )
---@class ScratcherGameView : GameScene
local ScratcherGameView = class("ScratcherGameView", GameScene)

local RES_DICT = {
    COMMON_BTN_BACK                 = _res('ui/common/common_btn_back.png'),
    COM_TITLE_BAR                   = _res('ui/common/common_title.png'),
    COMMON_BTN_ORANGE               = _res('ui/common/common_btn_orange.png'),
    COMMON_BTN_WHITE_DEFAULT        = _res('ui/common/common_btn_white_default.png'),
    COMMON_HINT_CIRCLE_RED_ICO      = _res('ui/common/common_hint_circle_red_ico.png'),
    SUMMON_NEWHAND_BTN_DRAW         = _res('ui/home/capsuleNew/common/summon_newhand_btn_draw.png'),
    MAIN_BG_MONEY                   = _res('ui/home/nmain/main_bg_money'),
    CARDMATCH_BTN_KEEPSAKE          = _res('ui/scratcher/cardmatch_btn_keepsake.png'),
    CARDMATCH_SCRATCH_BG            = _res('ui/scratcher/cardmatch_scratch_bg.jpg'),
    CARDMATCH_SCRATCH_CARD_BG       = _res('ui/scratcher/cardmatch_scratch_card_bg.png'),
    CARDMATCH_SCRATCH_CARD_BG2      = _res('ui/scratcher/cardmatch_scratch_card_bg_2.png'),
    CARDMATCH_SCRATCH_REWARD_BG_1   = _res('ui/scratcher/cardmatch_scratch_reward_bg_1.png'),
    CARDMATCH_SCRATCH_REWARD_BG_2   = _res('ui/scratcher/cardmatch_scratch_reward_bg_3.png'),
    CARDMATCH_SCRATCH_CARD_SPINE    = _spn('ui/scratcher/cardmatch_scratch_card_1'),
}

function ScratcherGameView:ctor( ticketGoodsId )
	GameScene.ctor(self, 'Game.views.scratcher.ScratcherGameView')
	self.ticketGoodsId = ticketGoodsId

    self:InitUI()
    
    self.blockLayer = display.newLayer(0, 0, {color = cc.r4b(0), enable = true})
    self.blockLayer:setVisible(false)
    self:addChild(self.blockLayer, 99999999)
end

function ScratcherGameView:InitUI()
    local function CreateView()
        local view = CLayout:create(display.size)
        display.commonUIParams(view, {po = display.center})
        self:addChild(view)    

        local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 120))
        eaterLayer:setTouchEnabled(true)
        eaterLayer:setContentSize(display.size)
        eaterLayer:setPosition(cc.p(display.cx, display.cy))
        view:addChild(eaterLayer)

        local BG = display.newImageView(RES_DICT.CARDMATCH_SCRATCH_BG, display.cx, display.cy,
        {
            ap = display.CENTER,
        })
        view:addChild(BG)
        view:addChild(display.newLayer(0, 0, {color = cc.c4b(0,0,0,150)}))

        local Image_1 = display.newImageView(RES_DICT.CARDMATCH_SCRATCH_CARD_BG, display.cx - 218, display.cy - -23,
        {
            ap = display.CENTER,
        })
        view:addChild(Image_1)

        local Image_2 = display.newImageView(RES_DICT.CARDMATCH_SCRATCH_CARD_BG2, Image_1:getPositionX() + Image_1:getContentSize().width/2, Image_1:getPositionY(),
        {
            ap = display.LEFT_CENTER,
        })
        view:addChild(Image_2)

        local previewImage = display.newLayer(display.cx - -434-10, display.cy - -23)
        view:addChild(previewImage)

        local resetBtn = display.newButton(display.cx - 14, display.height - 64,
        {
            ap = display.CENTER,
            n = RES_DICT.COMMON_BTN_WHITE_DEFAULT,
            enable = true,
        })
        display.commonLabelParams(resetBtn, fontWithColor(14, {text = __('重置卡池')}))
        view:addChild(resetBtn)

        local detailBtn = display.newButton(display.cx - -141, display.height - 64,
        {
            ap = display.CENTER,
            n = RES_DICT.COMMON_BTN_ORANGE,
            enable = true,
        })
        display.commonLabelParams(detailBtn, fontWithColor(14, {text = __('卡池详情')}))
        view:addChild(detailBtn)

        ----------------souvenirBtn start-----------------
        local souvenirBtn = display.newButton(display.cx - 521, 72,
        {
            ap = display.CENTER,
            n = RES_DICT.CARDMATCH_BTN_KEEPSAKE,
            enable = true,
        })
        display.commonLabelParams(souvenirBtn, fontWithColor(14, {text = __('收集小票\n领取大奖'), fontSize = 22, color = '#ffffff', w = 300, hAlign = cc.TEXT_ALIGNMENT_CENTER}))
        view:addChild(souvenirBtn)

        local redPointImage = display.newImageView(RES_DICT.COMMON_HINT_CIRCLE_RED_ICO, 226, 67,
        {
            ap = display.CENTER,
        })
        souvenirBtn:addChild(redPointImage)
        redPointImage:setVisible(false)

        -----------------souvenirBtn end------------------
        local onceBtn = display.newButton(display.cx - -81, 77,
        {
            ap = display.CENTER,
            n = RES_DICT.SUMMON_NEWHAND_BTN_DRAW,
            enable = true,
            tag = 1,
        })
        view:addChild(onceBtn)

        local fiveBtn = display.newButton(display.cx - -475, 77,
        {
            ap = display.CENTER,
            n = RES_DICT.SUMMON_NEWHAND_BTN_DRAW,
            enable = true,
        })
        view:addChild(fiveBtn)

        local onceText = string.fmt( __("刮_num_次"), {_num_=1} )
        display.commonLabelParams(onceBtn, fontWithColor(14, {ap = display.RIGHT_CENTER, fontSize = 26, color = '#ffffff', offset = cc.p(15,0), text = onceText}))
        display.commonLabelParams(fiveBtn, fontWithColor(14, {ap = display.RIGHT_CENTER, fontSize = 26, color = '#ffffff', offset = cc.p(15,0), text = ""}))

        local oncecostIcon = display.newImageView(CommonUtils.GetGoodsIconPathById(self.ticketGoodsId), 0, 0)
        oncecostIcon:setScale(0.4)
        oncecostIcon:setPositionX(utils.getLocalCenter(onceBtn).x + 50)
        oncecostIcon:setPositionY(utils.getLocalCenter(onceBtn).y)
        onceBtn:addChild(oncecostIcon)

        local fivecostIcon = display.newImageView(CommonUtils.GetGoodsIconPathById(self.ticketGoodsId), 0, 0)
        fivecostIcon:setScale(0.4)
        fivecostIcon:setPositionX(utils.getLocalCenter(fiveBtn).x + 50)
        fivecostIcon:setPositionY(utils.getLocalCenter(fiveBtn).y)
        fiveBtn:addChild(fivecostIcon)

        local Text_1 = display.newLabel(display.cx - -425, display.cy - 163,
        {
            text = __('飨灵刮刮乐'),
            ap = display.CENTER,
            fontSize = 50,
            color = '#ffe59f',
            font = TTF_GAME_FONT, ttf = true,
            outline = '#5b3c25',
            outlineSize = 2,
        })
        view:addChild(Text_1)

        local backBtn = display.newButton(display.SAFE_L + 75, display.height - 53,
        {
            ap = display.CENTER,
            n = RES_DICT.COMMON_BTN_BACK,
            enable = true,
        })
        -- display.commonLabelParams(backBtn, fontWithColor(14, {text = ''}))
        view:addChild(backBtn)

        -- title button
        local titlePos = cc.p(display.SAFE_L + 120, display.height + 2)
        local titleBtn = display.newButton(titlePos.x, titlePos.y, {n = RES_DICT.COM_TITLE_BAR, ap = display.LEFT_TOP})
        display.commonLabelParams(titleBtn, fontWithColor(1, {text = __('飨灵刮刮乐'), offset = cc.p(0,-10)}))
        view:addChild(titleBtn)
        titleBtn:setPosition(cc.p(titlePos.x, titlePos.y + 190))
        titleBtn:runAction(cc.EaseBounceOut:create(cc.MoveTo:create(1, titlePos)))

        local GoodPurchaseNode = require('common.GoodPurchaseNode')
        -- top icon
        local currencyBG = display.newImageView(RES_DICT.MAIN_BG_MONEY, 0, 0, {enable = false})
        display.commonUIParams(currencyBG,{ap = cc.p(1.0,1.0), po = cc.p(display.width + 400, display.height)})
        view:addChild(currencyBG)

        local currency = { self.ticketGoodsId }
        local moneyNodes = {}
        for i,v in ipairs(currency) do
            local purchaseNode = GoodPurchaseNode.new({id = v, animate = false, isEnableGain = true})
            purchaseNode:updataUi(checkint(v))
            display.commonUIParams(purchaseNode,
                    {ap = cc.p(1, 0.5), po = cc.p(display.SAFE_R - 20 - (( #currency - i) * (purchaseNode:getContentSize().width + 16)), currencyBG:getPositionY()- 26)})
            view:addChild(purchaseNode, 5)
            purchaseNode:setName('purchaseNode' .. i)
            purchaseNode.viewData.touchBg:setTag(checkint(v))
            moneyNodes[tostring( v )] = purchaseNode
        end

        return {
            view                    = view,
            BG                      = BG,
            Image_1                 = Image_1,
            previewImage            = previewImage,
            resetBtn                = resetBtn,
            detailBtn               = detailBtn,
            souvenirBtn             = souvenirBtn,
            redPointImage           = redPointImage,
            onceBtn                 = onceBtn,
            fiveBtn                 = fiveBtn,
            fivecostIcon            = fivecostIcon,
            Text_1                  = Text_1,
            backBtn                 = backBtn,
            moneyNodes              = moneyNodes,
            goodsIcons              = {},
            goodsFrames             = {},
        }
    end

	xTry(function ( )
        self.viewData = CreateView()
	end, __G__TRACKBACK__)
end


function ScratcherGameView:updatePoolCardImg(cardId)
    self.viewData.previewImage:removeAllChildren()
    local imgPath = _res('ui/scratcher/cardmatch_scratch_card_' .. cardId)
    self.viewData.previewImage:addChild(display.newImageView(imgPath))
end

function ScratcherGameView:updateGoodsFrame(index, has, x, y)
    if self.viewData.goodsFrames[tostring(index)] then
        self.viewData.goodsFrames[tostring(index)]:removeFromParent()
        self.viewData.goodsFrames[tostring(index)] = nil
    end
    local imgNode = display.newImageView(has == true and RES_DICT.CARDMATCH_SCRATCH_REWARD_BG_2 or RES_DICT.CARDMATCH_SCRATCH_REWARD_BG_1)
    imgNode:setPosition(checkint(x), checkint(y))
    self.viewData.view:addChild(imgNode)
    self.viewData.goodsFrames[tostring(index)] = imgNode
end

function ScratcherGameView:addLotterySpine(x, y, callback)
    local spine = display.newPathSpine(RES_DICT.CARDMATCH_SCRATCH_CARD_SPINE)
    spine:setPosition(checkint(x) - 55, checkint(y) - 55)
    self.viewData.view:addChild(spine, 100)
    
    spine:registerSpineEventHandler(function(event)
        spine:unregisterSpineEventHandler(sp.EventType.ANIMATION_COMPLETE)
        if callback then callback() end
        spine:runAction(cc.RemoveSelf:create())
    end, sp.EventType.ANIMATION_COMPLETE)
    spine:setAnimation(0, 'idle', false)
end

return ScratcherGameView
