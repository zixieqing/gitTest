--[[
常驻累充卡牌预览view
--]]
local CumulativeRechargeCardView = class('CumulativeRechargeCardView', function ()
    local node = CLayout:create(display.size)
    node.name = 'home.CumulativeRechargeCardView'
    node:enableNodeEvents()
    return node
end)

function CumulativeRechargeCardView:ctor( ... )
    self.args = unpack({...})
    self.cardId = checkint(self.args.cardId or 200001)
    self:InitUI()
end
--[[
init ui
--]]
function CumulativeRechargeCardView:InitUI()
    local cardId = self.cardId
    local gtype = CommonUtils.GetGoodTypeById(cardId)

    if tostring(gtype) == GoodsType.TYPE_CARD_FRAGMENT then
        local fragmentData = CommonUtils.GetConfig('goods', 'goods', cardId)
        cardId = fragmentData.cardId
    end
    local cardData = CommonUtils.GetConfig('cards', 'card', cardId)

    local function CreateView()
        local career = {
            [1] = 'blue',
            [2] = 'red',
            [3] = 'purple',
            [4] = 'green',
        }
        local view = CLayout:create(display.size)
        local bg = display.newImageView(_res('ui/home/capsule/draw_card_bg.png'), display.cx, display.cy)
        view:addChild(bg, 1)
        local backBtn = display.newButton(30 + display.SAFE_L, display.height - 18, {n = _res('ui/common/common_btn_back.png'), ap = cc.p(0, 1)})
        view:addChild(backBtn, 5)
        -- ur角色替换背景
        local rareIcon = display.newImageView(CardUtils.GetCardQualityTextPathByCardId(cardId), 157 + display.SAFE_L, display.height - 130, {ap = cc.p(0.5, 0.5)})
        view:addChild(rareIcon, 2)
        -- 立绘
        local cardDrawNode = require('common.CardSkinDrawNode').new({confId = cardId, coordinateType = COORDINATE_TYPE_CAPSULE})
        cardDrawNode:setAnchorPoint(cc.p(0.21, 0.5))
        cardDrawNode:setPosition(cc.p(display.width * 0.47, display.height / 2))
        view:addChild(cardDrawNode, 2)
        -- 卡牌名称背景
        local nameBg = display.newImageView(_res('ui/home/capsule/draw_card_bg_name.png'), display.width - 354 - display.SAFE_L, display.height - 60, {ap = cc.p(0, 0.5)})
        view:addChild(nameBg, 2)
        -- 卡牌名称
        local nameLabel = display.newLabel(display.width - 147- display.SAFE_L, display.height - 80, {text = cardData.name, fontSize = 30, color = '#ffdf89', ap = cc.p(1, 0)})
        view:addChild(nameLabel,2)
        -- 卡牌定位Label
        local careerIcon = display.newButton( display.width - 133 - display.SAFE_L, display.height - 92, {n = _res('ui/home/capsule/card_order_ico_' .. career[checkint(cardData.career)] .. '_l.png'), ap = cc.p(0, 0), enable = false})
        view:addChild(careerIcon, 2)
        -- 卡牌描述
        local descrBg = display.newImageView(_res('ui/home/capsule/draw_card_bg_text.png'), display.width / 2, 10, {ap = cc.p(0.5, 0)})
        descrBg:setCascadeOpacityEnabled(true)
        view:addChild(descrBg,2)
        self.dialogue = CommonUtils.GetCurrentCvLinesByGroupType(cardId, SoundType.TYPE_GET_CARD)
        local descrLabel = display.newLabel(60, 135, {text = dialogue, fontSize = 22, color = 'ffffff', ap = cc.p(0, 1), w = 500})
        descrBg:addChild(descrLabel)
        descrLabel:setCascadeOpacityEnabled(true)
        local cv = '???'
        if cardData.cv ~= '' then
            cv = CommonUtils.GetCurrentCvAuthorByCardId(cardData.cardId  or cardData.id)
        end
        local cvLabel = display.newLabel(display.width - 153 - display.SAFE_L, display.height - 108, {text = cv , fontSize = 20, color = '#fca702', ap = cc.p(1, 0)})
        view:addChild(cvLabel,3)
        return {
            view                = view, 
            backBtn             = backBtn
        }
    end 
    -- eaterLayer
    local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 255*0.6))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    self:addChild(eaterLayer, -1)
    xTry(function ( )
        self.viewData_ = CreateView( )
        display.commonUIParams(self.viewData_.view, {po = display.center})
        self:addChild(self.viewData_.view)
        self.viewData_.backBtn:setOnClickScriptHandler(function ()
            self:runAction(
                cc.Sequence:create(
                    cc.FadeOut:create(0.15),
                    cc.RemoveSelf:create()
                )
            )
        end)
        self:EnterAction()
    end, __G__TRACKBACK__)
end
function CumulativeRechargeCardView:EnterAction()
    self:setOpacity(0)
    self:runAction(cc.FadeIn:create(0.15))
end
return CumulativeRechargeCardView