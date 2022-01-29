--[[
皮肤卡池动画硬币node
--]]
local CapsuleSkinAnimateCoinNode = class('CapsuleSkinAnimateCoinNode', function ()
    local node = CLayout:create(cc.size(240, 300))
    node.name = 'privateRoom.CapsuleSkinAnimateCoinNode'
    node:enableNodeEvents()
    return node
end)
local RES_DICT = {
    DEFAULT_COIN_BG       = _res('ui/home/capsuleNew/common/summon_skin_result_bg_goods_1.png'),
    DEFAULT_COIN_FRONT    = _res('ui/home/capsuleNew/common/summon_skin_ico_skin_coin_1.png'),
    COIN_LIGHT_SPINE      = _spn('ui/home/capsuleNew/common/effect/fx_yinbi'), 
    CLICK_LIGHT_SPINE     = _spn('ui/home/capsuleNew/common/effect/yinbi'),
    BG_LIGHT_SPINE        = _spn('ui/home/capsuleNew/common/effect/fx_yinbi_f'),
    GOODS_ICON_MASK       = _res('ui/home/capsuleNew/common/summon_skin_bg_card_mask.png'),
    GOODS_ICON_FRONT_MASK = _res('ui/home/capsuleNew/common/summon_skin_bg_mask.png'),
    NEW_ICON              = _res('ui/home/cardslistNew/card_preview_ico_new.png'),
    GOODS_TYPE_BG         = _res('ui/home/capsuleNew/common/summon_detail_bg_up.png'),
    CHANGE_ARROW          = _res('ui/home/capsuleNew/common/summon_ico_arrow_change.png'),
    CHANGE_GOODS_BG       = _res('ui/home/capsuleNew/common/summon_skin_bg_goods_change.png')
    
}
function CapsuleSkinAnimateCoinNode:ctor( ... )
    local args = unpack({ ... })
    self.reward = args.reward or {}
    self.isShow = false
    self:InitUI()
    self:RefreshUI(self.reward)
end
function CapsuleSkinAnimateCoinNode:InitUI()
    local function CreateView()
        local size = self:getContentSize()
        local view = CLayout:create(size)
        -- bgLayer
        local bgLayer = display.newLayer(size.width / 2, size.height / 2, {size = size, ap = display.CENTER})
        view:addChild(bgLayer, 1)
        local bgLightSpine = sp.SkeletonAnimation:create(
            RES_DICT.BG_LIGHT_SPINE.json,
            RES_DICT.BG_LIGHT_SPINE.atlas,
        0.735)
        bgLightSpine:setPosition(cc.p(size.width / 2, 170))
        bgLightSpine:setAnimation(0, 'idle', true)
        bgLayer:addChild(bgLightSpine, 8)
        local bgBtn = display.newButton(size.width / 2, 170,{n = RES_DICT.DEFAULT_COIN_BG})
        bgLayer:addChild(bgBtn, 1)
		-- 裁剪道具icon
		bgLayer:setCascadeOpacityEnabled(true)
		local goodsClipNode = cc.ClippingNode:create()
		goodsClipNode:setCascadeOpacityEnabled(true)
		goodsClipNode:setPosition(cc.p(bgBtn:getContentSize().width / 2, bgBtn:getContentSize().height / 2))
		bgBtn:addChild(goodsClipNode, 5)

		local stencilNode = display.newNSprite(RES_DICT.GOODS_ICON_MASK, 0, 0)
		stencilNode:setScale(1)
		goodsClipNode:setAlphaThreshold(0.1)
		goodsClipNode:setStencil(stencilNode)

		local goodsNode = display.newImageView(CommonUtils.GetGoodsIconPathById(GOLD_ID), 0, 0)
        goodsClipNode:addChild(goodsNode)
        local frontMask = display.newImageView(RES_DICT.GOODS_ICON_FRONT_MASK, bgBtn:getContentSize().width / 2, bgBtn:getContentSize().height / 2)
        bgBtn:addChild(frontMask, 7)
        
        local newIcon = display.newImageView(RES_DICT.NEW_ICON, 45, 240)
        bgLayer:addChild(newIcon, 10)
        
        local typeBg = display.newImageView(RES_DICT.GOODS_TYPE_BG, size.width / 2, 56)
        typeBg:setCascadeOpacityEnabled(true)
        bgLayer:addChild(typeBg, 10)
        
        local typeLabel = display.newLabel(typeBg:getContentSize().width / 2, typeBg:getContentSize().height / 2, {text = '', fontSize = 18, color = '#d3d0b7'})
        typeBg:addChild(typeLabel, 1)
        typeLabel:setCascadeOpacityEnabled(true)

        local nameLabel = display.newLabel(size.width / 2, 42, {text = '', fontSize = 24, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#372018', outlineSize = 2, w = 180, ap = cc.p(0.5, 1), hAlign = cc.TEXT_ALIGNMENT_CENTER})
        bgLayer:addChild(nameLabel, 10)
        -- 转换
        local changeArrow = display.newImageView(RES_DICT.CHANGE_ARROW, size.width / 2 + 15, 105)
        bgLayer:addChild(changeArrow, 10)

        local changeIconBg = display.newImageView(RES_DICT.CHANGE_GOODS_BG, 200, 115)
        changeIconBg:setCascadeOpacityEnabled(true)
        bgLayer:addChild(changeIconBg, 9)

        local changeIcon = display.newImageView(CommonUtils.GetGoodsIconPathById(GOLD_ID), changeIconBg:getContentSize().width / 2, changeIconBg:getContentSize().height / 2)
        changeIcon:setScale(0.25)
        changeIconBg:addChild(changeIcon, 1)

        local changeLabel = display.newLabel(changeIconBg:getContentSize().width / 2, changeIconBg:getContentSize().height - 15, {text = __('转换'), fontSize = 18, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#372018', outlineSize = 1})
        changeIconBg:addChild(changeLabel, 2)
        
        local changeNumLabel = display.newLabel(changeIconBg:getContentSize().width / 2, 15, {text = 'x50', fontSize = 18, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#372018', outlineSize = 1})
        changeIconBg:addChild(changeNumLabel, 2)

        local clickLightSpine = sp.SkeletonAnimation:create(
            RES_DICT.CLICK_LIGHT_SPINE.json,
            RES_DICT.CLICK_LIGHT_SPINE.atlas,
        0.735)
        clickLightSpine:setPosition(cc.p(size.width / 2, 170))
        bgLayer:addChild(clickLightSpine, 10)
        -- frontLayer
        local frontLayer = display.newLayer(size.width / 2, size.height / 2, {size = size, ap = display.CENTER})
        view:addChild(frontLayer, 5)
        local frontBtn = display.newButton(size.width / 2, 170,{n = RES_DICT.DEFAULT_COIN_FRONT})
        frontBtn:setScale(1.4)
        frontLayer:addChild(frontBtn, 1)

        local lightSpine = sp.SkeletonAnimation:create(
            RES_DICT.COIN_LIGHT_SPINE.json,
            RES_DICT.COIN_LIGHT_SPINE.atlas,
        0.7)
        lightSpine:setPosition(cc.p(size.width / 2, 170))
        frontLayer:addChild(lightSpine, 5)

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
            lightSpine       = lightSpine,
            clickLightSpine  = clickLightSpine,
            bgLightSpine     = bgLightSpine,

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
function CapsuleSkinAnimateCoinNode:RefreshUI( rewardData )
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
    viewData.frontBtn:setNormalImage(_res(string.format('ui/home/capsuleNew/common/summon_skin_ico_%s_coin_%d.png', rateData.buttonType, rateData.rate)))
    viewData.frontBtn:setSelectedImage(_res(string.format('ui/home/capsuleNew/common/summon_skin_ico_%s_coin_%d.png', rateData.buttonType, rateData.rate)))
    viewData.bgBtn:setNormalImage(_res(string.format('ui/home/capsuleNew/common/summon_skin_result_bg_%s_%d.png', rateData.buttonType, rateData.rate)))
    viewData.bgBtn:setSelectedImage(_res(string.format('ui/home/capsuleNew/common/summon_skin_result_bg_%s_%d.png', rateData.buttonType, rateData.rate)))
    if rateData.rate == 1 then
        viewData.lightSpine:setAnimation(0, 'idle1', true)
        viewData.bgLightSpine:setVisible(true)
    elseif rateData.rate == 2 then
        viewData.lightSpine:setAnimation(0, 'idle2', true)
        viewData.bgLightSpine:setVisible(false)
    else
        viewData.lightSpine:setVisible(false)
        viewData.bgLightSpine:setVisible(false)
    end
    viewData.goodsNode:setTexture(CommonUtils.GetGoodsIconPathById(goodsId))
    viewData.nameLabel:setString(goodsConfig.name)
    display.commonLabelParams(viewData.nameLabel , {  text =  goodsConfig.name })
    if display.getLabelContentSize(viewData.nameLabel).height > 50    then
        display.commonLabelParams(viewData.nameLabel , { w= 250 , reqH = 50 ,  text =  goodsConfig.name })
    end


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
function CapsuleSkinAnimateCoinNode:CoinButtonCallback( sender )
    self.isShow = true
    AppFacade.GetInstance():DispatchObservers(CAPSULE_SKIN_COIN_CLICK)
    self:CoinClickAction()
end
--[[
硬币点击动画
--]]
function CapsuleSkinAnimateCoinNode:CoinClickAction()
    PlayAudioClip(AUDIOS.UI.ui_skin_result.id)
    local viewData = self.viewData
    self.isShow = true
    viewData.frontBtn:setEnabled(false)
    viewData.bgBtn:setScale(0.9)
    viewData.typeBg:setOpacity(0)
    viewData.nameLabel:setOpacity(0)
    viewData.newIcon:setOpacity(0)
    viewData.changeArrow:setOpacity(0)
    viewData.changeArrow:setScaleX(0)
    viewData.changeIconBg:setOpacity(0)
    viewData.changeIconBg:setScale(0)

    viewData.clickLightSpine:setAnimation(0, 'play1', false)
    self:runAction(
        cc.Sequence:create(
            cc.TargetedAction:create(viewData.frontBtn, cc.ScaleBy:create(0.15, 0.9)),
            cc.TargetedAction:create(viewData.frontLayer, cc.Hide:create()),
            cc.TargetedAction:create(viewData.bgLayer, cc.Show:create()),
            cc.TargetedAction:create(viewData.bgBtn, cc.EaseBackOut:create(cc.ScaleTo:create(0.2, 1))),
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
function CapsuleSkinAnimateCoinNode:BgCoinButtonCallback( sender )
    PlayAudioByClickNormal()
    local capsuleSkinDetailView = require("Game.views.drawCards.CapsuleSkinDetailView").new({reward = self.reward, showAnimation = false})
    capsuleSkinDetailView:setPosition(cc.p(display.cx, display.cy))
    app.uiMgr:GetCurrentScene():AddDialog(capsuleSkinDetailView)
end
--[[
获取硬币是否为展示状态
--]]
function CapsuleSkinAnimateCoinNode:IsCoinShow()
    return self.isShow
end
return CapsuleSkinAnimateCoinNode