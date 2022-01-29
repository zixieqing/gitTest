--[[
皮肤卡池展示页面物品cell
--]]
local VIEW_SIZE = display.size
local CapsuleSkinSettlementAvatarCell = class('CapsuleSkinSettlementAvatarCell', function ()
    local node = CLayout:create(VIEW_SIZE)
    node.name = 'Game.views.drawCards.CapsuleSkinSettlementAvatarCell'
    node:enableNodeEvents()
    return node
end)

local RES_DICT = {
    SUMMON_SKIN_BG_TITLE_EFFECT      =  _res('ui/home/capsuleNew/skinCapsule/summon_skin_bg_title_effect.png'),
    SUMMON_SKIN_DETAIL_BG_GOODS_TEXT =  _res('ui/home/capsuleNew/skinCapsule/summon_skin_detail_bg_goods_text.png'),
    CONFIRM_BUTTON                   = _res("ui/common/common_btn_orange.png"),
    LIGHT_SPINE                      = _spn('ui/home/capsuleNew/common/effect/yinbi'),
    DRAW_CARD_BG_TEXT_TIPS           = _res('ui/home/capsule/draw_card_bg_text_tips.png'),
}

local DragNode = require('Game.views.restaurant.DragNode')

local uiMgr = app.uiMgr
local CreateView              = nil
local CreateOrnamentsInfoView = nil

function CapsuleSkinSettlementAvatarCell:ctor( ... )
    local args = unpack({...}) or {}
    self.reward = args.reward or {}
    self.cb = args.cb
    self.showAnimation = args.showAnimation or false
    self:InitUI()
    self:RefreshUI(self.reward)
    self:ShowEnterAnimation(self.showAnimation)
end

function CapsuleSkinSettlementAvatarCell:InitUI()
    xTry(function ( )
		self.viewData = CreateView(VIEW_SIZE)
        self:addChild(self.viewData.view)
        self.viewData.confirmBtn:setOnClickScriptHandler(handler(self, self.ConfirmButtonCallback))
        self:InitView()
	end, __G__TRACKBACK__)
end

function CapsuleSkinSettlementAvatarCell:InitView()
    local viewData   = self:GetViewData()
end

function CapsuleSkinSettlementAvatarCell:RefreshUI(args)
    local avatarId = args.goodsId
    if checkint(avatarId) <= 0 then return end

    local avatarConf = CommonUtils.GetConfig('goods', 'goods', avatarId)

    local viewData = self:GetViewData()
    self:UpdateAvatarName(viewData, avatarConf)
    self:UpdateDragNode(viewData, avatarId)
    self:UpdateDescr(viewData, avatarConf)
    self:UpdateOrnamentsInfoView(viewData, avatarConf, avatarId)
    self:UpdateGoodsGetTipLabel(viewData, args)
end

function CapsuleSkinSettlementAvatarCell:UpdateAvatarName(viewData, avatarConf)
    display.commonLabelParams(viewData.avatarName, {text = tostring(avatarConf.name)})
    local typeConf = CommonUtils.GetConfig('goods', 'type', avatarConf.type)
    display.commonLabelParams(viewData.avatarTypeName, {text = typeConf.type})
end

function CapsuleSkinSettlementAvatarCell:UpdateDragNode(viewData, avatarId)
    if CommonUtils.GetGoodTypeById(avatarId) == GoodsType.TYPE_AVATAR then
        local dragNode = RestaurantUtils.UpdateDragNode(viewData.dragNode, avatarId, cc.size(300,300))
        if dragNode then
            display.commonUIParams(dragNode, {ap = display.CENTER, po = cc.p(VIEW_SIZE.width / 2, VIEW_SIZE.height / 2 + 30)})
            viewData.view:addChild(dragNode, 7)
            viewData.dragNode = dragNode
        end
    else
        local goodsIcon = display.newImageView(CommonUtils.GetGoodsIconPathById(avatarId), VIEW_SIZE.width / 2, VIEW_SIZE.height / 2)
        viewData.view:addChild(goodsIcon, 7)
    end 
end

function CapsuleSkinSettlementAvatarCell:UpdateDescr(viewData, avatarConf)
    local descrBg = viewData.descrBg
    display.commonLabelParams(viewData.descrLabel, {text = tostring(avatarConf.descr)})
end

function CapsuleSkinSettlementAvatarCell:UpdateOrnamentsInfoView(viewData, avatarConf, avatarId)
    local ornamentsInfoView = viewData.ornamentsInfoView
    local goodsType = CommonUtils.GetGoodTypeById(avatarId)
    if goodsType == GoodsType.TYPE_AVATAR then
        local avatarConf = CommonUtils.GetConfigNoParser('restaurant', 'avatar', avatarId)
        if avatarConf then
            local buffDesc = string.fmt(__('餐厅美观度提高_target_num_点'), {['_target_num_'] = avatarConf.beautyNum})
            display.commonLabelParams(ornamentsInfoView.ornamentsDescrLabel, {text = buffDesc})
        else
            ornamentsInfoView.view:setVisible(false)
        end
    elseif goodsType == GoodsType.TYPE_PRIVATEROOM_SOUVENIR then
        local buffData = app.privateRoomMgr:GetBuffDescrByGoodsId(avatarId)
        display.commonLabelParams(ornamentsInfoView.ornamentsDescrLabel, {text = buffData.buffDescr})
    else
        ornamentsInfoView.view:setVisible(false)
    end
end

function CapsuleSkinSettlementAvatarCell:UpdateGoodsGetTipLabel(viewData, reward)
    local goodsGetTipBg     = viewData.goodsGetTipBg
    local turnGoodsId = checkint(reward.turnGoodsId)
    goodsGetTipBg:setVisible(turnGoodsId > 0)

    if turnGoodsId > 0 then
        local goodsId     = checkint(reward.goodsId)
        local goodsConfig = CommonUtils.GetConfig('goods', 'goods', goodsId) or {}
        local turnGoodsConfig = CommonUtils.GetConfig('goods', 'goods', turnGoodsId) or {}
        display.commonLabelParams(viewData.goodsGetTipLabel, {text = string.fmt(__('_good_name_已获得，已经把_good_name_转变成_good_turn_name_*_num_'),
            {_good_name_ = tostring(goodsConfig.name), _good_turn_name_ = tostring(turnGoodsConfig.name), _num_ = checkint(reward.turnGoodsNum)})})
    end
    
end

function CapsuleSkinSettlementAvatarCell:ConfirmButtonCallback( sender )
    if self.cb then
        self.cb()
    end
    self:runAction(cc.RemoveSelf:create())
end

function CapsuleSkinSettlementAvatarCell:ShowEnterAnimation( showAnimation )
    local viewData = self:GetViewData()
    if showAnimation then
        viewData.confirmBtn:setOpacity(0)
        viewData.descrBg:setOpacity(0)
        viewData.ornamentsInfoView.view:setOpacity(0)
        viewData.goodsGetTipBg:setOpacity(0)
        viewData.lightSpine:setAnimation(0, 'play1', false)
        self:runAction(
            cc.Sequence:create(
                cc.DelayTime:create(0.1),
                cc.Spawn:create(
                    cc.TargetedAction:create( -- 道具描述
                        viewData.descrBg, 
                        cc.Sequence:create(
                            cc.FadeIn:create(1)
                        )
                    ),
                    cc.TargetedAction:create( -- avatar效果
                        viewData.ornamentsInfoView.view, 
                        cc.Sequence:create(
                            cc.DelayTime:create(0.3),
                            cc.FadeIn:create(0.8)
                        )
                    ),
                    cc.TargetedAction:create( -- 分解提示
                        viewData.goodsGetTipBg, 
                        cc.Sequence:create(
                            cc.DelayTime:create(0.3),
                            cc.FadeIn:create(0.8)
                        )
                    ),
                    cc.TargetedAction:create( -- 确定按钮
                        viewData.confirmBtn, 
                        cc.Sequence:create(
                            cc.DelayTime:create(1.2),
                            cc.Show:create(),
                            cc.FadeIn:create(0.4)
                        )
                    )
                )
            )
        )
    else
        viewData.lightSpine:setVisible(false)
        viewData.confirmBtn:setVisible(true)
    end
end

CreateView = function(size)
    local view = display.newLayer()

    local avatarName = display.newLabel(size.width / 2, size.height / 2 + 260, fontWithColor(19))
    view:addChild(avatarName)

    local avatarTypeName = display.newLabel(size.width / 2, size.height / 2 + 230, fontWithColor(16))
    view:addChild(avatarTypeName)

    local descrBgSize = cc.size(767, 153)
    local descrBg = display.newNSprite(RES_DICT.SUMMON_SKIN_DETAIL_BG_GOODS_TEXT, size.width / 2, 10, {ap = display.CENTER_BOTTOM, scale9 = true, size = descrBgSize})
    view:addChild(descrBg)

    local descrLabelPosx = 35
    local descrLabel = display.newLabel(40, descrBgSize.height - 13, 
        {fontSize = 22, color = '#ffedc1', ap = display.LEFT_TOP, w = descrBgSize.width - descrLabelPosx * 2})
	descrBg:addChild(descrLabel)

    local ornamentsInfoView = CreateOrnamentsInfoView(size)
    view:addChild(ornamentsInfoView.view)

    local confirmBtn = display.newButton(display.width -74 - display.SAFE_L, 80, {n = RES_DICT.CONFIRM_BUTTON})
    view:addChild(confirmBtn, 10)
    confirmBtn:setVisible(false)
    local confirmLabel = display.newLabel(confirmBtn:getContentSize().width / 2, confirmBtn:getContentSize().height / 2, fontWithColor(14, {text = __('确定')}))
    confirmBtn:addChild(confirmLabel, 1)

    local lightSpine = sp.SkeletonAnimation:create(
        RES_DICT.LIGHT_SPINE.json,
        RES_DICT.LIGHT_SPINE.atlas,
    1)
    lightSpine:setPosition(cc.p(display.cx, display.cy))
    view:addChild(lightSpine, 15)

    local goodsGetTipSize = cc.size(297, 106)
    local goodsGetTipBg = display.newNSprite(RES_DICT.DRAW_CARD_BG_TEXT_TIPS, display.SAFE_R - 10, size.height - 40, {ap = display.RIGHT_TOP, scale9 = true, size = goodsGetTipSize})
    view:addChild(goodsGetTipBg)

    local goodsGetTipLabel = display.newLabel(20, goodsGetTipSize.height - 15, {ap = display.LEFT_TOP, fontSize = 20, color = '#faf0db', text = '', w = 260})
    goodsGetTipBg:addChild(goodsGetTipLabel)

    return {
        view              = view,
        avatarName        = avatarName,
        avatarTypeName    = avatarTypeName,
        descrBg           = descrBg,
        descrLabel        = descrLabel,
        confirmBtn        = confirmBtn,
        lightSpine        = lightSpine,
        goodsGetTipBg     = goodsGetTipBg,
        ornamentsInfoView = ornamentsInfoView,
        goodsGetTipLabel  = goodsGetTipLabel,
    }
end

CreateOrnamentsInfoView = function (size)
    local view = display.newLayer()

    local ornamentsInfoBgSize = cc.size(1624, 1002)
    local ornamentsInfoBg = display.newNSprite(RES_DICT.SUMMON_SKIN_BG_TITLE_EFFECT, size.width / 2, size.height / 2, {ap = display.CENTER})
    view:addChild(ornamentsInfoBg)

    local ornamentsTitleLabel = display.newLabel(ornamentsInfoBgSize.width / 2 + 304, ornamentsInfoBgSize.height / 2 + 142, {ap = display.LEFT_CENTER, text = __('饰品效果'), fontSize = 22, color = '#ffedc1', reqW = 330})
    ornamentsInfoBg:addChild(ornamentsTitleLabel)

    local ornamentsDescrLabel = display.newLabel(ornamentsTitleLabel:getPositionX(), ornamentsInfoBgSize.height / 2 + 120, fontWithColor(16, {ap = display.LEFT_TOP, w = 350}))
    ornamentsInfoBg:addChild(ornamentsDescrLabel)
    
    return {
        view                = view,
        ornamentsTitleLabel = ornamentsTitleLabel,
        ornamentsDescrLabel = ornamentsDescrLabel,
    }

end

function CapsuleSkinSettlementAvatarCell:GetViewData()
    return self.viewData
end

return CapsuleSkinSettlementAvatarCell
