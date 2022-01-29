--[[
皮肤卡池动画硬币node
--]]
local CapsuleBasicSkinAnimationCardNode = class('CapsuleBasicSkinAnimationCardNode', function ()
    local node = CLayout:create(cc.size(240, 300))
    node.name = 'privateRoom.CapsuleBasicSkinAnimationCardNode'
    node:enableNodeEvents()
    return node
end)
local RES_DICT = {
    DEFAULT_COIN_BG       = _res('ui/home/capsuleNew/basicSkin/summon_skin_animation_bg_card_1.png'),
    DEFAULT_COIN_FRONT    = _res('ui/home/capsuleNew/common/summon_skin_ico_skin_coin_1.png'),
    CARD_SPINE            = _spn('ui/home/capsuleNew/basicSkin/effect/summon_skin_ten'), 
    CLICK_LIGHT_SPINE     = _spn('ui/home/capsuleNew/common/effect/yinbi'),
    BG_LIGHT_SPINE        = _spn('ui/home/capsuleNew/common/effect/fx_yinbi_f'),
    BG_ICON_MASK          = _res('ui/home/capsuleNew/basicSkin/summon_skin_animation_bg_card_black.png'),
    CARD_FARME            = _res('ui/home/capsuleNew/basicSkin/summon_skin_animation_bg_card_up_small_1.png'),
    NEW_ICON              = _res('ui/home/cardslistNew/card_preview_ico_new.png'),
    GOODS_TYPE_BG         = _res('ui/home/capsuleNew/basicSkin/summon_skin_animation_bg_card_name_1.png'),
    CHANGE_ARROW          = _res('ui/home/capsuleNew/common/summon_ico_arrow_change.png'),
    CHANGE_GOODS_BG       = _res('ui/home/capsuleNew/common/summon_skin_bg_goods_change.png')
    
}
function CapsuleBasicSkinAnimationCardNode:ctor( ... )
    local args = unpack({ ... })
    self.reward = args.reward or {}
    self.isShow = false
    self:InitUI()
    self:RefreshUI(self.reward)
end
function CapsuleBasicSkinAnimationCardNode:InitUI()
    local function CreateView()
        local size = self:getContentSize()
        local view = CLayout:create(size)
        -- bgLayer
        local bgLayer = display.newLayer(size.width / 2, size.height / 2, {size = size, ap = display.CENTER})
        view:addChild(bgLayer, 1)
        local bgBtn = display.newButton(size.width / 2, size.height / 2,{n = RES_DICT.DEFAULT_COIN_BG})
        bgLayer:addChild(bgBtn, 1)

        local goodsNode = display.newImageView(CommonUtils.GetGoodsIconPathById(GOLD_ID), size.width / 2, 190)
        goodsNode:setScale(1.2)
        bgLayer:addChild(goodsNode, 5)
        local iconMask = display.newImageView(RES_DICT.BG_ICON_MASK, size.width / 2, size.height / 2)
        bgLayer:addChild(iconMask, 5)
        local cardFrame = display.newImageView(RES_DICT.CARD_FARME, size.width / 2, size.height / 2)
        bgLayer:addChild(cardFrame, 7)
        
        local newIcon = display.newImageView(RES_DICT.NEW_ICON, 45, 255)
        bgLayer:addChild(newIcon, 10)
        
        local typeBg = display.newImageView(RES_DICT.GOODS_TYPE_BG, size.width / 2, 48)
        typeBg:setCascadeOpacityEnabled(true)
        bgLayer:addChild(typeBg, 6)
        
        local typeLabel = display.newLabel(typeBg:getContentSize().width / 2, typeBg:getContentSize().height - 12, {text = '', fontSize = 18, color = '#d3d0b7'})
        typeBg:addChild(typeLabel, 1)
        typeLabel:setCascadeOpacityEnabled(true)

        local nameLabel = display.newLabel(size.width / 2, 56, {text = '', fontSize = 24, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#372018', outlineSize = 2, w = 180, ap = cc.p(0.5, 1), hAlign = cc.TEXT_ALIGNMENT_CENTER})
        bgLayer:addChild(nameLabel, 10)
        -- 转换
        local changeArrow = display.newImageView(RES_DICT.CHANGE_ARROW, 34, size.height - 50)
        bgLayer:addChild(changeArrow, 10)

        local changeIconBg = display.newImageView(RES_DICT.CHANGE_GOODS_BG, 90, size.height - 40)
        changeIconBg:setCascadeOpacityEnabled(true)
        bgLayer:addChild(changeIconBg, 9)

        local changeIcon = display.newImageView(CommonUtils.GetGoodsIconPathById(GOLD_ID), changeIconBg:getContentSize().width / 2, changeIconBg:getContentSize().height / 2)
        changeIcon:setScale(0.25)
        changeIconBg:addChild(changeIcon, 1)

        local changeLabel = display.newLabel(changeIconBg:getContentSize().width / 2, changeIconBg:getContentSize().height - 15, {text = __('转换'), fontSize = 18, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#372018', outlineSize = 1})
        changeIconBg:addChild(changeLabel, 2)
        
        local changeNumLabel = display.newLabel(changeIconBg:getContentSize().width / 2, 15, {text = 'x50', fontSize = 18, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#372018', outlineSize = 1})
        changeIconBg:addChild(changeNumLabel, 2)

        -- frontLayer
        local frontLayer = display.newLayer(size.width / 2, size.height / 2, {size = size, ap = display.CENTER})
        view:addChild(frontLayer, 5)
        local frontBtn = display.newButton(size.width / 2, size.height / 2,{n = 'empty', size = size})
        frontLayer:addChild(frontBtn, 1)

        local cardSpine = sp.SkeletonAnimation:create(
            RES_DICT.CARD_SPINE.json,
            RES_DICT.CARD_SPINE.atlas,
        0.75)
        cardSpine:setPosition(cc.p(size.width / 2, size.height / 2))
        frontLayer:addChild(cardSpine, 5)

        return {
            view             = view,
            bgLayer          = bgLayer,
            bgBtn            = bgBtn,
            goodsNode        = goodsNode,
            newIcon          = newIcon,
            typeBg           = typeBg,
            typeLabel        = typeLabel,
            nameLabel        = nameLabel,
            changeArrow      = changeArrow,
            changeIconBg     = changeIconBg,
            changeIcon       = changeIcon,
            changeNumLabel   = changeNumLabel,
            frontLayer       = frontLayer,
            frontBtn         = frontBtn,
            cardSpine        = cardSpine,
            cardFrame        = cardFrame,
            
        }
    end
    xTry(function ( )
        self.viewData = CreateView( )
        self:addChild(self.viewData.view, 1)
        self.viewData.view:setPosition(utils.getLocalCenter(self))
        self.viewData.frontBtn:setOnClickScriptHandler(handler(self, self.CoinButtonCallback))
        self.viewData.bgBtn:setOnClickScriptHandler(handler(self, self.BgCoinButtonCallback))
    end, __G__TRACKBACK__)    
end
--[[
刷新ui
--]]
function CapsuleBasicSkinAnimationCardNode:RefreshUI( rewardData )
    if not rewardData then 
        rewardData = self.reward
    end
    local viewData = self.viewData
    local goodsId = rewardData.goodsId
    local goodsConfig = CommonUtils.GetConfig('goods', 'goods', goodsId)
    local rateData = app.capsuleMgr:GetRateDataByGoodsId(goodsId)
    if tostring(goodsConfig.type) == GoodsType.TYPE_CARD_SKIN then
        viewData.newIcon:setVisible(not(rewardData.turnGoodsId and true or false))
    else
        viewData.newIcon:setVisible(false)
    end
    viewData.cardSpine:setAnimation(0, string.format('summon_skin_animation_bg_%s_%d', rateData.buttonType == 'goods' and 'house' or 'skin', rateData.rate), false)
    viewData.cardSpine:setTimeScale(0)
    viewData.bgBtn:setNormalImage(_res(string.format('ui/home/capsuleNew/basicSkin/summon_skin_animation_bg_card_%d.png', rateData.rate)))
    viewData.bgBtn:setSelectedImage(_res(string.format('ui/home/capsuleNew/basicSkin/summon_skin_animation_bg_card_%d.png', rateData.rate)))
    viewData.cardFrame:setTexture(_res(string.format('ui/home/capsuleNew/basicSkin/summon_skin_animation_bg_card_up_small_%d.png', rateData.rate)))
    viewData.typeBg:setTexture(_res(string.format('ui/home/capsuleNew/basicSkin/summon_skin_animation_bg_card_name_%d.png', rateData.rate)))
    viewData.goodsNode:setTexture(CommonUtils.GetGoodsIconPathById(goodsId))
    viewData.nameLabel:setString(goodsConfig.name)
    local typeConf = CommonUtils.GetConfig('goods', 'type', goodsConfig.type)
    display.commonLabelParams(viewData.typeLabel, {text = typeConf.type})
    -- 分解
    if checkint(rewardData.turnGoodsId) > 0 then
        viewData.changeIcon:setTexture(CommonUtils.GetGoodsIconPathById(rewardData.turnGoodsId))
        viewData.changeNumLabel:setString('x' .. tostring(checkint(rewardData.turnGoodsNum)))
    else
        viewData.changeArrow:setVisible(false)
        viewData.changeIconBg:setVisible(false)
    end

    viewData.bgLayer:setVisible(false)
    viewData.frontLayer:setVisible(true)
end
--[[
硬币按钮点击回调
--]]
function CapsuleBasicSkinAnimationCardNode:CoinButtonCallback( sender )
    self.isShow = true
    AppFacade.GetInstance():DispatchObservers(CAPSULE_SKIN_COIN_CLICK)
    self:CoinClickAction()
end
--[[
硬币点击动画
--]]
function CapsuleBasicSkinAnimationCardNode:CoinClickAction()
    PlayAudioClip(AUDIOS.UI.ui_skin_result.id)
    local viewData = self.viewData
    self.isShow = true
    viewData.frontBtn:setEnabled(false)
    viewData.typeBg:setOpacity(0)
    viewData.nameLabel:setOpacity(0)
    viewData.newIcon:setOpacity(0)
    viewData.changeArrow:setOpacity(0)
    viewData.changeArrow:setScaleX(0)
    viewData.changeIconBg:setOpacity(0)
    viewData.changeIconBg:setScale(0)

    -- 开始播放spine动画
    viewData.cardSpine:setTimeScale(1)
    -- 执行动作
    self:runAction(
        cc.Sequence:create(
            cc.DelayTime:create(1.4),
            cc.TargetedAction:create(viewData.bgLayer, cc.Show:create()),
            cc.DelayTime:create(0.3),
            cc.TargetedAction:create(viewData.frontLayer, cc.Hide:create()),
            cc.Spawn:create(
                cc.TargetedAction:create(viewData.typeBg, cc.FadeIn:create(0.3)),
                cc.TargetedAction:create(viewData.nameLabel, cc.Sequence:create(
                    cc.DelayTime:create(0.2),
                    cc.FadeIn:create(0.3)
                )),
                cc.TargetedAction:create(viewData.newIcon, cc.Sequence:create(
                    cc.DelayTime:create(0.4),
                    cc.FadeIn:create(0.3)
                )),
                cc.TargetedAction:create(viewData.changeArrow, cc.Sequence:create(
                    cc.DelayTime:create(0.4),
                    cc.Spawn:create(
                        cc.FadeIn:create(0.3),
                        cc.ScaleTo:create(0.2, 1)
                    )
                )),
                cc.TargetedAction:create(viewData.changeIconBg, cc.Sequence:create(
                    cc.DelayTime:create(0.6),
                    cc.Spawn:create(
                        cc.FadeIn:create(0.3),
                        cc.EaseBackOut:create(cc.ScaleTo:create(0.4, 1))
                    )
                ))
            )
        )
    )
end
--[[
背景按钮点击回调
--]]
function CapsuleBasicSkinAnimationCardNode:BgCoinButtonCallback( sender )
    PlayAudioByClickNormal()
    local capsuleSkinDetailView = require("Game.views.drawCards.CapsuleSkinDetailView").new({reward = self.reward, showAnimation = false})
    capsuleSkinDetailView:setPosition(cc.p(display.cx, display.cy))
    app.uiMgr:GetCurrentScene():AddDialog(capsuleSkinDetailView)
end
--[[
获取硬币是否为展示状态
--]]
function CapsuleBasicSkinAnimationCardNode:IsCoinShow()
    return self.isShow
end
return CapsuleBasicSkinAnimationCardNode