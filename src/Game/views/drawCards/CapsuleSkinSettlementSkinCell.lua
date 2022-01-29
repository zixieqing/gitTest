--[[
皮肤卡池展示页面皮肤cell
--]]
local VIEW_SIZE = display.size
local CapsuleSkinSettlementSkinCell = class('CapsuleSkinSettlementSkinCell', function ()
    local node = CLayout:create(VIEW_SIZE)
    node.name = 'Game.views.drawCards.CapsuleSkinSettlementSkinCell'
    node:enableNodeEvents()
    return node
end)


local RES_DICT = {
    DRAW_CARD_ICO_NEW                = _res('ui/home/capsule/draw_card_ico_new.png'),
    
    DRAW_CARD_BG_TEXT                = _res('ui/home/capsule/draw_card_bg_text.png'),
    SUMMON_SKIN_BG_ROLE_DETAIL       = _res('ui/home/capsuleNew/skinCapsule/summon_skin_bg_role_detail.png'),
    CONFIRM_BUTTON                   = _res("ui/common/common_btn_orange.png"),
    LIGHT_SPINE                      = _spn('ui/home/capsuleNew/common/effect/yinbi'),
    DRAW_CARD_BG_TEXT_TIPS           = _res('ui/home/capsule/draw_card_bg_text_tips.png'),
}

local uiMgr   = app.uiMgr
local cardMgr = app.cardMgr
local CreateView             = nil


function CapsuleSkinSettlementSkinCell:ctor( ... )
    local args = unpack({...}) or {}
    self.reward = args.reward or {}
    self.cb = args.cb
    self.showAnimation = args.showAnimation or false
    self:InitUI()
    self:RefreshUI(self.reward)
    self:ShowEnterAnimation(self.showAnimation)
end

function CapsuleSkinSettlementSkinCell:InitUI()
    xTry(function ( )
		self.viewData = CreateView(VIEW_SIZE)
        self:addChild(self.viewData.view)
        self.viewData.confirmBtn:setOnClickScriptHandler(handler(self, self.ConfirmButtonCallback))
        self.viewData.shareBtn:setOnClickScriptHandler(handler(self, self.ShareButtonCallback))
        self:InitView()
	end, __G__TRACKBACK__)
end

function CapsuleSkinSettlementSkinCell:InitView()
    local viewData   = self:GetViewData()
end

function CapsuleSkinSettlementSkinCell:RefreshUI(args)
    local skinId = checkint(args.goodsId)
    if skinId < 0 then return end
    local skinConf = CardUtils.GetCardSkinConfig(skinId)
    if skinConf == nil then
        print('>>> error <<< -> can not find skin config')
        return
    end
    
    local viewData = self:GetViewData()
    self:UpdateNewImgShowState(viewData, args)

    self:UpdateSkinName(viewData, skinConf)
    
    local confId = skinConf.cardId
    self:UpdateCardCareer(viewData, confId)

    self:UpdateRoleName(viewData, confId)

    self:UpdateCardDrawNode(viewData, skinId)

    self:UpdateSkinDescr(viewData, skinConf)

    self:UpdateGoodsGetTipLabel(viewData, args)
end

function CapsuleSkinSettlementSkinCell:UpdateNewImgShowState(viewData, reward)
    viewData.newImg:setVisible(not(reward.turnGoodsId and true or false))
end

function CapsuleSkinSettlementSkinCell:UpdateSkinName(viewData, skinConf)
    display.commonLabelParams(viewData.skinName, {text = tostring(skinConf.name)})
end

function CapsuleSkinSettlementSkinCell:UpdateCardCareer(viewData, confId)
    local careerIconBg = viewData.careerIconBg
    careerIconBg:setTexture(CardUtils.GetCardCareerIconFramePathByCardId(confId))

    local careerIcon = viewData.careerIcon
    careerIcon:setTexture(CardUtils.GetCardCareerIconPathByCardId(confId))
end

function CapsuleSkinSettlementSkinCell:UpdateRoleName(viewData, confId)
    local cardConf = CardUtils.GetCardConfig(confId) or {}
    display.commonLabelParams(viewData.roleName, {text = tostring(cardConf.name)})
    display.commonLabelParams(viewData.cvRoleName, {text = CommonUtils.GetCurrentCvAuthorByCardId(confId)})
end

function CapsuleSkinSettlementSkinCell:UpdateCardDrawNode(viewData, skinId)
    local cardDrawNode = viewData.cardDrawNode
    local l2dDrawNode  = viewData.l2dDrawNode

    if CardUtils.IsShowCardLive2d(skinId) then
        if l2dDrawNode == nil then
            l2dDrawNode = require('common.CardSkinL2dNode').new({
                notRefresh = true,
                clickCB    = function() end,
            })
            l2dDrawNode:setScale(1.2)
            l2dDrawNode:setAnchorPoint(cc.p(0.21, 0.5))
            l2dDrawNode:setPosition(cc.p(VIEW_SIZE.width * 0.47, VIEW_SIZE.height / 2))
            viewData.view:addChild(l2dDrawNode)
        end

        local skinParams = {skinId = skinId}--, bgMode = true}
        l2dDrawNode:refreshL2dNode(skinParams)

        if cardDrawNode then
            cardDrawNode:setVisible(false)
        end

    else
        local skinParams = {skinId = skinId, coordinateType = COORDINATE_TYPE_CAPSULE}
        if cardDrawNode == nil then
            cardDrawNode = require('common.CardSkinDrawNode').new(skinParams)
            cardDrawNode:setScale(1.2)
            cardDrawNode:setAnchorPoint(cc.p(0.21, 0.5))
            cardDrawNode:setPosition(cc.p(VIEW_SIZE.width * 0.47, VIEW_SIZE.height / 2))
            cardDrawNode:setCascadeColorEnabled(true)
            viewData.view:addChild(cardDrawNode)
    
            viewData.cardDrawNode = cardDrawNode
        else
            cardDrawNode:setVisible(true)
            cardDrawNode:RefreshAvatar(skinParams)
        end

        if l2dDrawNode then
            l2dDrawNode:cleanL2dNode()
        end
    end
end

function CapsuleSkinSettlementSkinCell:UpdateSkinDescr(viewData, skinConf)
    local descrBg    = viewData.descrBg
    local descrLabel = viewData.descrLabel
    display.commonLabelParams(descrLabel, {text = tostring(skinConf.descr)})
end
function CapsuleSkinSettlementSkinCell:UpdateGoodsGetTipLabel(viewData, reward)
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
CreateView = function(size)
    local view = display.newLayer()
    
    local roleDetailBgSize = cc.size(435, 228)
    local roleDetailBg = display.newNSprite(RES_DICT.SUMMON_SKIN_BG_ROLE_DETAIL, display.SAFE_L - 60, display.cy + 50, {ap = display.LEFT_CENTER})
    view:addChild(roleDetailBg, 1)
    roleDetailBg:setCascadeOpacityEnabled(true)
    roleDetailBg:addChild(display.newLabel(73, roleDetailBgSize.height - 46, {text = __('皮肤'), fontSize = 22, color = '#bdaa93', ap = display.LEFT_CENTER}))

    local newImg = display.newNSprite(RES_DICT.DRAW_CARD_ICO_NEW, 120, roleDetailBgSize.height - 40, {ap = display.CENTER_BOTTOM})
	roleDetailBg:addChild(newImg)

    local skinName = display.newLabel(73, roleDetailBgSize.height - 58, {fontSize = 46, color = '#fffec7', outline = '#372018', outlineSize = 3, ap = display.LEFT_TOP, w = 305})
    roleDetailBg:addChild(skinName)

    local careerIconBg = display.newNSprite('', 100, 34, {ap = display.CENTER})
    careerIconBg:setScale(1.6)
    roleDetailBg:addChild(careerIconBg)

    local careerIcon = display.newNSprite('', careerIconBg:getPositionX(), careerIconBg:getPositionY(), {ap = display.CENTER})
    careerIcon:setScale(1.1)
    roleDetailBg:addChild(careerIcon)

    local roleName = display.newLabel(130, 36, {fontSize = 30, reqW = 260, color = '#ffdf89', ap = display.LEFT_BOTTOM})
    roleDetailBg:addChild(roleName)

    local cvRoleName = display.newLabel(130, 34, {fontSize = 24, reqW = 260, color = '#c2b55e', ap = display.LEFT_TOP})
    roleDetailBg:addChild(cvRoleName)
    local shareLayout = CLayout:create(cc.size(144, 120))
	shareLayout:setPosition(cc.p(74 + display.SAFE_L, 80))
	view:addChild(shareLayout, 10)
    local shareBtn = require('common.CommonShareButton').new({})
    display.commonUIParams(shareBtn, {po = cc.p(72, 65)})
    shareLayout:addChild(shareBtn, 10)
    -- shareLayout:setVisible(false)
    
    -- 卡牌描述
	local descrBg = display.newImageView(RES_DICT.DRAW_CARD_BG_TEXT, size.width / 2, 10, {ap = display.CENTER_BOTTOM})
	descrBg:setCascadeOpacityEnabled(true)
	view:addChild(descrBg,2)

    local descrLabel = display.newLabel(50, 135, {fontSize = 22, color = '#ffffff', ap = display.LEFT_TOP, w = 570})
	descrBg:addChild(descrLabel)
    descrLabel:setCascadeOpacityEnabled(true)

    local confirmBtn = display.newButton(display.width -74 - display.SAFE_L, 80, {n = RES_DICT.CONFIRM_BUTTON})
    view:addChild(confirmBtn, 10)
    confirmBtn:setVisible(true)
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
        newImg            = newImg,
        careerIconBg      = careerIconBg,
        careerIcon        = careerIcon,
        skinName          = skinName,
        roleName          = roleName,
        cvRoleName        = cvRoleName,
        shareLayout       = shareLayout,
        shareBtn          = shareBtn,
        descrBg           = descrBg,
        descrLabel        = descrLabel,
        cardDrawNode      = nil,
        confirmBtn        = confirmBtn,
        roleDetailBg      = roleDetailBg,
        lightSpine        = lightSpine,
        goodsGetTipBg     = goodsGetTipBg,
        goodsGetTipLabel  = goodsGetTipLabel,
    }
end

function CapsuleSkinSettlementSkinCell:GetViewData()
    return self.viewData
end

function CapsuleSkinSettlementSkinCell:ConfirmButtonCallback( sender )
    if self.cb then
        self.cb()
    end
    self:runAction(cc.RemoveSelf:create())
end

function CapsuleSkinSettlementSkinCell:ShareButtonCallback( sender )
    local layerTag = 7218
	local getCardSkinView = require('common.CommonCardGoodsShareView').new({
        goodsId = self.reward.goodsId,
		confirmCallback = function (sender)
			-- 确认按钮 关闭此界面
			local layer = uiMgr:GetCurrentScene():GetDialogByTag(layerTag)
			if nil ~= layer then
				layer:setVisible(false)
				layer:runAction(cc.RemoveSelf:create())
			end
		end
	})
	display.commonUIParams(getCardSkinView, {ap = cc.p(0.5, 0.5), po = display.center})
	uiMgr:GetCurrentScene():AddDialog(getCardSkinView)
	getCardSkinView:setTag(layerTag)
end

function CapsuleSkinSettlementSkinCell:ShowEnterAnimation( showAnimation )
    local viewData = self:GetViewData()
    if showAnimation then
        viewData.roleDetailBg:setOpacity(0)
        viewData.confirmBtn:setOpacity(0)
        viewData.descrBg:setOpacity(0)
        viewData.shareLayout:setOpacity(0)
        viewData.goodsGetTipBg:setOpacity(0)
        viewData.lightSpine:setAnimation(0, 'play2', false)
        self:runAction(
            cc.Sequence:create(
                cc.DelayTime:create(0.1),
                cc.Spawn:create(
                    cc.TargetedAction:create( -- 皮肤详情
                        viewData.roleDetailBg, 
                        cc.FadeIn:create(0.8)
                    ),
                    cc.TargetedAction:create( -- 皮肤描述
                        viewData.descrBg, 
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
                    ),
                    cc.TargetedAction:create( -- 分享按钮
                        viewData.shareLayout, 
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

return CapsuleSkinSettlementSkinCell
