local PromotersView = class('PromotersView', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.PromotersView'
	node:enableNodeEvents()
	return node
end)

local RES_DIR = {
    
    PROMOTERS_INFO_BG = _res('ui/common/common_bg_7.png'),
    PROMOTERS_INFO_TITLE = _res('ui/common/common_title_6.png'),
    -- 
    
    PROMOTERS_BG = _res('ui/common/common_bg_3.png'),
    PROMOTERS_TITLE = _res('ui/common/common_bg_title_2.png'),
    PROMOTERS_AGENT_CODE_BG = _res('ui/promoters/agent_bg_code.png'),
    PROMOTERS_AGENT_DETAIL_BG = _res('ui/promoters/agent_bg_detail.png'),
    PROMOTERS_AGENT_INGO_BG = _res('ui/promoters/agent_bg_info.png'),
    PROMOTERS_AGENT_QR_CODE = _res('ui/promoters/qr_code.png'),
    PROMOTERS_AGENT_QR_CODE_HEAD_ARROW = _res('ui/promoters/rob_record_ico_arrow.png'),
    PROMOTERS_AGENT_BTN_SAVA_QR_CODE = _res('ui/promoters/agent_btn_save_to_photo.png'),
    PROMOTERS_AGENT_TAB_BG =  _res("ui/common/common_btn_sidebar_common.png"),
    PROMOTERS_AGENT_TAB_S_BG =  _res("ui/common/common_btn_sidebar_selected.png"),
    

    PROMOTERS_TEXT_BG =  _res('ui/common/commcon_bg_text.png'),
    TIP_ICON  = _res('ui/common/common_btn_tips.png'),
    PROMOTERS_AGENT_INGO_NUM_BG = _res('ui/home/market/market_buy_bg_info.png'),
    PROMOTERS_AGENT_INGO_RESEARCH_BG = _res('ui/home/market/market_main_bg_research.png'),
    PROMOTERS_AGENT_INGO_ARROW = _res('ui/home/task/main/rank_ico_arrow.png'),

    BTN_ORANGE = _res('ui/common/common_btn_orange.png'),


    LINE         =  _res('ui/tower/team/tower_ico_line3.png'),

    FRIEND_HEAD_BG    = _res('ui/author/create_roles_head_down_default.png'),
    FRIEND_HEAD_FRAME = _res('ui/author/create_roles_head_up_default.png'),

}

local TAB_TEXT = {
   {tag = PROMOTERS_VIEW_TAG.AGENT, text = __('推广员')},
--    {tag = PROMOTERS_VIEW_TAG.REDEEMCODE, text = __('兑换码')},
}

local BTN_TAG = {
    PROMOTERS_INFO           = 1000,         -- 推广员信息
    SKIN_COUPON_REPLACEMENT  = 1001,         -- 幻晶石补领
    SAVE_IMAGE               = 1002,         -- 保存图片
    COPY_LINK                = 1003,         -- 复制图片
    PRE_ARROW                = 1004,         -- 上张头像按钮
    NEXT_ARROW               = 1005,         -- 下张头像图片
    REDEEM_CODE              = 1006,         -- 兑换码
    REPLACEMENT_COUPON       = 1007,         -- 补领兑换券
}

local CreatePromotersView_ = nil
local CreateRedeemCodeView_ = nil
local CreateInfoView_ = nil
local CreateExplainView_ = nil

local createTitle = nil
local createInputBox = nil

function PromotersView:ctor( ... )
    self.args = unpack({...})
    self:InitialUI()
end

function PromotersView:InitialUI()
    local function CreateView()
        local touchView = display.newLayer(0, 0, {color = cc.c4b(0, 0, 0, 130), enable = true, size = display.size, ap = display.LEFT_BOTTOM, cb = handler(self, self.CloseHandler)})
        self:addChild(touchView)

        local bg = display.newImageView(RES_DIR.PROMOTERS_BG, 0, 0, {ap = display.CENTER})
        local bgSize = bg:getContentSize()
        local view = display.newLayer(0, 0, {size = cc.size(bgSize.width + 228, bgSize.height), ap = display.CENTER})
        
        local touchBgView = display.newLayer(display.width / 2 - bgSize.width/2, display.height / 2 - bgSize.height / 2, {color = cc.c4b(0, 0, 0, 0), enable = true, size = cc.size(bgSize.width, bgSize.height), ap = display.LEFT_BOTTOM})
        view:setPosition(display.center)
        display.commonUIParams(bg, {po = cc.p(utils.getLocalCenter(view))})
        self:addChild(touchBgView)
        view:addChild(bg)
        self:addChild(view)
        
        local titleBg = display.newImageView(RES_DIR.PROMOTERS_TITLE, bgSize.width / 2, bgSize.height * 0.995, {ap = display.CENTER_TOP})
        bg:addChild(titleBg)
        
        local titleLabel = display.newLabel(0, 0, fontWithColor(3, {text = __('我是推广员'), ap = display.CENTER}))
        display.commonUIParams(titleLabel, {po =  utils.getLocalCenter(titleBg)})
        titleBg:addChild(titleLabel)
        
        local tabs = {}
        local tabSize = nil
        for i,v in ipairs(TAB_TEXT) do
            local tab = display.newButton(0, 0, {n = RES_DIR.PROMOTERS_AGENT_TAB_BG, ap = display.LEFT_TOP})
            if tabSize == nil then
                tabSize = tab:getContentSize()
                -- dump(tabSize, 'tabSizetabSize')
            end
            display.commonLabelParams(tab, fontWithColor(6, {text = v.text, offset = cc.p(-5, 12)}))
            local po = cc.p(bgSize.width + 93, bgSize.height * 0.88 - tabSize.height * (i - 1))
            display.commonUIParams(tab, {po = po})
            view:addChild(display.newLayer(po.x, po.y, {color = cc.c4b(0, 0, 0, 0), enable = true, size = tabSize, ap = display.LEFT_TOP}))
            view:addChild(tab)

            -- local tab = display.newCheckBox(0,0, { n = RES_DIR.PROMOTERS_AGENT_TAB_BG, s = RES_DIR.PROMOTERS_AGENT_TAB_S_BG, ap = display.LEFT_TOP})
            -- -- dump(tab:getContentSize(), 'tabSizetabSizetabSizetabSizetabSize')
            -- display.commonUIParams(tab, {cb = function (sender)
            --     dump(sender)
            --     print('SSSSSSSSSSSSSSSSS')
            -- end})
            -- if tabSize == nil then
            --     tabSize = tab:getContentSize()
            --     -- dump(tabSize, 'tabSizetabSize')
            -- end
            -- local lb = display.newLabel(tabSize.width / 2, tabSize.height / 2 + 10, fontWithColor(6, {text = v}))
            -- tab:addChild(lb)
            -- local po = cc.p(bgSize.width + 93, bgSize.height * 0.88 - tabSize.height * (i - 1))
            -- display.commonUIParams(tab, {po = po})
            -- view:addChild(display.newLayer(po.x, po.y, {color = cc.c4b(0, 0, 0, 0), enable = true, size = tabSize, ap = display.LEFT_TOP}))
            -- view:addChild(tab)
            
            tabs[tostring(v.tag)] = tab
        end

        -- local promotersViewData = CreatePromotersView_(bgSize)
        -- view:addChild(promotersViewData.view)
        
        -- local redeemCodeViewData = CreateRedeemCodeView_(bgSize)
        -- view:addChild(redeemCodeViewData.view)
        -- local infoViewData = CreateInfoView_()
        -- self:addChild(infoViewData.view)

        return {
            view = view,
            tabs = tabs,

            bgSize = bgSize,
        }
    end

    xTry(function ( )
        self.viewData_ = CreateView( )

        self.explainViewData_ = CreateExplainView_()

        display.commonUIParams(self.explainViewData_.layer, {po = cc.p(display.cx - self.viewData_.bgSize.width / 2 + 10, display.cy + self.viewData_.bgSize.height / 2 - 40)})
        self:addChild(self.explainViewData_.layer)
	end, __G__TRACKBACK__)
end

CreatePromotersView_ = function (bgSize)
    local view = display.newLayer(114, 0, {size = bgSize, ap = display.LEFT_BOTTOM})
    local actionButtons = {}

    local agentInfoBg = display.newImageView(RES_DIR.PROMOTERS_AGENT_INGO_BG, 0, 0, {ap = display.LEFT_BOTTOM})
    local agentInfoBgSize = agentInfoBg:getContentSize()
    local agentInfoLayer = display.newLayer(bgSize.width / 2, bgSize.height * 0.92, {size = agentInfoBgSize, ap = display.CENTER_TOP})
    agentInfoLayer:addChild(agentInfoBg)
    view:addChild(agentInfoLayer)
    
    local agentDetailBg = display.newButton(agentInfoBgSize.width / 2, agentInfoBgSize.height, { ap = display.CENTER_TOP, n = RES_DIR.PROMOTERS_AGENT_DETAIL_BG})
    agentInfoLayer:addChild(agentDetailBg)
    actionButtons[tostring(BTN_TAG.PROMOTERS_INFO)] = agentDetailBg
    
    local arrowIcon = display.newImageView(RES_DIR.PROMOTERS_AGENT_QR_CODE_HEAD_ARROW, agentInfoBgSize.width * 0.06, agentInfoBgSize.height * 0.89, {ap = display.LEFT_CENTER})
    arrowIcon:setScale(0.5)
    arrowIcon:setRotation(180)
    agentInfoLayer:addChild(arrowIcon)

    local tipIcon = display.newButton(agentInfoBgSize.width * 0.1, agentInfoBgSize.height * 0.89, {n = RES_DIR.TIP_ICON, ap = display.CENTER})
    agentInfoLayer:addChild(tipIcon)
    
    local infoTipLabel = display.newLabel(agentInfoBgSize.width * 0.15, tipIcon:getPositionY(), fontWithColor(18, {text = __('外观劵获取方式 (点击查看）'), ap = display.LEFT_CENTER}))
    agentInfoLayer:addChild(infoTipLabel)

    
    local function createObtainNum(parent, str, posy)
        local obtainLabel = display.newLabel(agentInfoBgSize.width * 0.04, posy, fontWithColor(6, {text = str, ap = display.LEFT_CENTER}))
        local obtainLabelSize = display.getLabelContentSize(obtainLabel)
        parent:addChild(obtainLabel)
        
        local obtainNumBgSize = cc.size(220, 38)
        local obtainNumBg = display.newImageView(RES_DIR.PROMOTERS_AGENT_INGO_NUM_BG, agentInfoBgSize.width * 0.23, obtainLabel:getPositionY(), {size = obtainNumBgSize, scale9 = true, ap = display.LEFT_CENTER})
        parent:addChild(obtainNumBg)

        local numLabel = display.newRichLabel(obtainNumBgSize.width * 0.04, obtainNumBgSize.height * 0.5, {ap = display.LEFT_CENTER})
        -- local numLabel = display.newLabel(obtainNumBgSize.width * 0.04, obtainNumBgSize.height * 0.5, fontWithColor(6, {text = '0', ap = display.LEFT_CENTER}))
        obtainNumBg:addChild(numLabel)
        return numLabel
    end

    local todayObtainLabel = createObtainNum(agentInfoLayer, __('今日获得:'), agentInfoBgSize.height * 0.6)

    local todayObtainTipLabel = display.newLabel(agentInfoBgSize.width * 0.98, agentInfoBgSize.height * 0.6, fontWithColor(10, {text = __('(仅计算分享获得)'), ap = display.RIGHT_CENTER}))
    agentInfoLayer:addChild(todayObtainTipLabel)

    -- _res('arts/goods/goods_icon_goods_icon_890006.png')

    local totalObtainLabel = createObtainNum(agentInfoLayer, __('累计获得:'), agentInfoBgSize.height * 0.3)

    local replacementBtn = display.newButton(agentInfoBgSize.width * 0.83, agentInfoBgSize.height * 0.3, {ap = display.CENTER, n = RES_DIR.BTN_ORANGE})
    display.commonLabelParams(replacementBtn, fontWithColor(14, {fontSize = 22, text = __('补领皮肤券')}))
    agentInfoLayer:addChild(replacementBtn)
    actionButtons[tostring(BTN_TAG.SKIN_COUPON_REPLACEMENT)] = replacementBtn

    local line = display.newImageView(RES_DIR.LINE, bgSize.width / 2, 393, {ap = display.CENTER_BOTTOM})
    view:addChild(line)

    view:addChild(display.newLabel(bgSize.width * 0.5, bgSize.height * 0.58, fontWithColor(5, {text = __('我的专属二维码'), ap = display.CENTER})))

    -- local qrCode = display.newImageView(RES_DIR.PROMOTERS_AGENT_QR_CODE, bgSize.width / 2, 150, {ap = display.CENTER_BOTTOM})
    -- view:addChild(qrCode)
    local qrCodeLayerSize = cc.size(200, 200)
    local qrCodeLayer = display.newLayer(bgSize.width / 2, 150, {size = qrCodeLayerSize, ap = display.CENTER_BOTTOM}) 
    view:addChild(qrCodeLayer)

    local qrCode = lrequire('root.WebSprite').new({url = '', hpath = RES_DIR.PROMOTERS_AGENT_QR_CODE, tsize = qrCodeLayerSize})
    qrCode:setVisible(false)
    qrCode:setAnchorPoint(display.CENTER)
    qrCode:setPosition(utils.getLocalCenter(qrCodeLayer))
    qrCodeLayer:addChild(qrCode)
    
    local friendHeaderNode = require('root.CCHeaderNode').new({bg = _res(RES_DIR.FRIEND_HEAD_BG)})
    friendHeaderNode:setAnchorPoint(display.CENTER)
    friendHeaderNode:setPosition(utils.getLocalCenter(qrCodeLayer))
    friendHeaderNode:setScale(0.25)
    friendHeaderNode:addChild(display.newImageView(_res(RES_DIR.FRIEND_HEAD_FRAME), 0, 0, {ap = display.LEFT_BOTTOM}))
    qrCodeLayer:addChild(friendHeaderNode)

    local saveImgBtn = display.newButton(bgSize.width * 0.5, 140, {ap = display.CENTER_TOP, n = RES_DIR.PROMOTERS_AGENT_BTN_SAVA_QR_CODE})
    display.commonLabelParams(saveImgBtn, fontWithColor('14', {text = __('存储至相册')}))
    view:addChild(saveImgBtn)
    actionButtons[tostring(BTN_TAG.SAVE_IMAGE)] = saveImgBtn

    local preHeadArrow = display.newButton(bgSize.width * 0.19, 239, {ap = display.CENTER, n = RES_DIR.PROMOTERS_AGENT_QR_CODE_HEAD_ARROW})
    preHeadArrow:setRotation(180)
    view:addChild(preHeadArrow)
    actionButtons[tostring(BTN_TAG.PRE_ARROW)] = preHeadArrow

    local nextHeadArrow = display.newButton(bgSize.width * 0.81, 239, {ap = display.CENTER, n = RES_DIR.PROMOTERS_AGENT_QR_CODE_HEAD_ARROW})
    view:addChild(nextHeadArrow)
    actionButtons[tostring(BTN_TAG.NEXT_ARROW)] = nextHeadArrow

    local linkTipLabel = display.newLabel(bgSize.width * 0.07, 66, fontWithColor(6, {ap = display.LEFT_BOTTOM, text = __('我的专属邀请链接')}))
    view:addChild(linkTipLabel)

    local linkBg = display.newImageView(RES_DIR.PROMOTERS_AGENT_INGO_RESEARCH_BG, bgSize.width * 0.07, 40, {ap = display.LEFT_CENTER})
    local linkBgSize = linkBg:getContentSize()
    view:addChild(linkBg)
    
    local linkLabel = display.newLabel(2, linkBgSize.height / 2, fontWithColor(4, {ap = display.LEFT_CENTER, text = ''}))
    linkBg:addChild(linkLabel)

    local copyLink = display.newButton(bgSize.width - 30, 40, {ap = display.RIGHT_CENTER, n = _res('ui/home/teamformation/choosehero/team_btn_selection_unused.png')})
    display.commonLabelParams(copyLink, fontWithColor('14', {text = __('复制链接')}))
    view:addChild(copyLink)
    actionButtons[tostring(BTN_TAG.COPY_LINK)] = copyLink

    return {
        view = view,
        -- agentDetailBg = agentDetailBg,
        todayObtainLabel = todayObtainLabel,
        totalObtainLabel = totalObtainLabel,
        -- replacementBtn = replacementBtn,
        qrCodeLayer = qrCodeLayer,
        qrCode = qrCode,
        friendHeaderNode = friendHeaderNode,
        -- preHeadArrow = preHeadArrow,
        -- nextHeadArrow = nextHeadArrow,
        -- saveImgBtn = saveImgBtn,
        -- copyLink = copyLink,
        linkLabel = linkLabel,
        actionButtons = actionButtons,

        bgSize = bgSize,
    }
end

CreateRedeemCodeView_ = function (bgSize)
    local view = display.newLayer(114, 0, {size = bgSize, ap = display.LEFT_BOTTOM})

    local bg = display.newImageView(RES_DIR.PROMOTERS_AGENT_CODE_BG, 0, 0, {ap = display.LEFT_BOTTOM})
    local size = bg:getContentSize()
    local bgLayer = display.newLayer(bgSize.width / 2, bgSize.height * 0.88, {size = size, ap = display.CENTER_TOP})
    bgLayer:addChild(bg)
    view:addChild(bgLayer)
    
    local agentCodeTipLb = display.newLabel(size.width / 2, size.height * 0.5, {color = '#ba5c5c', fontSize = 28, text = __('输入兑换码，领取礼品奖励'), ap = display.CENTER_BOTTOM})
    bgLayer:addChild(agentCodeTipLb)

    -- local obtainNumBg = display.newImageView(RES_DIR.PROMOTERS_AGENT_INGO_NUM_BG, size.width / 2, obtainLabel:getPositionY(), {size = cc.size(375, 51), scale9 = true, ap = display.CENTER_TOP})
    -- bgLayer:addChild(obtainNumBg)
    local editBoxSize = cc.size(375, 51)
    local editBox = ccui.EditBox:create(editBoxSize, RES_DIR.PROMOTERS_AGENT_INGO_NUM_BG)
    editBox:setFontSize(fontWithColor('M2PX').fontSize)
    editBox:setFontColor(ccc3FromInt('#5b3c25'))
    editBox:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
    editBox:setPlaceHolder(__('请输入兑换码'))
    editBox:setPlaceholderFontSize(fontWithColor('M1PX').fontSize)
    editBox:setPlaceholderFontColor(ccc3FromInt('#8c8c8c'))
    editBox:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)
    -- editBox:registerScriptEditBoxHandler(function (eventType, sender)
    --     -- 开始输入 并且  提示处于显示状态 则 隐藏 提示
    --     if eventType == 'began' and nameTip:isVisible() then
    --         nameTip:runAction(cc.Sequence:create({
    --             cc.FadeOut:create(0.2),
    --             cc.CallFunc:create(function()
    --                 nameTip:setOpacity(255)
    --                 nameTip:setVisible(false)
    --             end),
    --         }))
    --     end
    -- end)
    display.commonUIParams(editBox, {po = cc.p(size.width / 2, size.height * 0.48), ap = display.CENTER_TOP})
    bgLayer:addChild(editBox)

    local btn = display.newButton(size.width / 2, size.height * 0.15 , {ap = display.CENTER, n = RES_DIR.BTN_ORANGE})
    btn:setTag(BTN_TAG.REDEEM_CODE)
    display.commonLabelParams(btn, fontWithColor(14, {text = __('确定')}))
    bgLayer:addChild(btn)

    return {
        view = view,
        editBox = editBox,
        btn = btn,
    }
end

CreateInfoView_ = function ()
    local view = display.newLayer(0, 0, {size = display.size, ap = display.LEFT_BOTTOM})
    local touchView = display.newLayer(0, 0, {color = cc.c4b(0, 0, 0, 130), enable = true, size = display.size, ap = display.LEFT_BOTTOM})
    view:addChild(touchView)

    local bg = display.newImageView(RES_DIR.PROMOTERS_INFO_BG, 0, 0, {ap = display.CENTER})
    local bgSize = bg:getContentSize()
    local bgLayer = display.newLayer(0, 0, {size = bgSize, ap = display.CENTER})
    display.commonUIParams(bgLayer, {po = cc.p(utils.getLocalCenter(view))})
    display.commonUIParams(bg, {po = cc.p(utils.getLocalCenter(bgLayer))})
    bgLayer:addChild(bg)
    bgLayer:addChild(display.newLayer(0, 0, {color = cc.c4b(0, 0, 0, 0), enable = true, size = bgSize, ap = display.LEFT_BOTTOM}))
    view:addChild(bgLayer)

    createTitle(bgLayer, RES_DIR.PROMOTERS_TITLE, __('信息'), cc.p(bgSize.width / 2, bgSize.height * 0.995))
    createTitle(bgLayer, RES_DIR.PROMOTERS_INFO_TITLE, __('请填写被邀请人信息'), cc.p(bgSize.width / 2, bgSize.height * 0.9))

    local UUIDEditBox = createInputBox(bgLayer, __('UID:'), __('请输入UID'), cc.p(bgSize.width * 0.4, bgSize.height * 0.75), 10)
    local phoneEditBox = createInputBox(bgLayer, __('绑定的手机号:'), __('请输入手机号'), cc.p(bgSize.width * 0.4, bgSize.height * 0.65), 11)

    local textBgSize = cc.size(22*22 + 3, 159)
    local textBg = display.newImageView(RES_DIR.PROMOTERS_TEXT_BG, bgSize.width / 2, bgSize.height / 2, {size = textBgSize, scale9 = true, ap = display.CENTER_TOP})
    bgLayer:addChild(textBg)
 
    local text = __('通过邀请获得外观券的初衷是为了让我们的世界更加美好，所以只有介绍真实的朋友进入游戏才能获得奖励，其他情况都是为非正当手段，将接受正义的裁决，一经发现立即封禁账号.')
    local descLabel = display.newLabel(textBgSize.width / 2, textBgSize.height / 2, {text = text, fontSize = 22, color = '#ba5c5c', w = textBgSize.width-22, ap = display.CENTER})
    textBg:addChild(descLabel)

    local btn = display.newButton(bgSize.width / 2, bgSize.height * 0.1 , {ap = display.CENTER, n = RES_DIR.BTN_ORANGE})
    btn:setTag(BTN_TAG.REPLACEMENT_COUPON)
    display.commonLabelParams(btn, fontWithColor(14, {text = __('补领外观券')}))
    bgLayer:addChild(btn)

    return {
        view = view,
        touchView = touchView,
        UUIDEditBox = UUIDEditBox,
        phoneEditBox = phoneEditBox,
        btn = btn,
    }
end

CreateExplainView_ = function ()
    
    local descrLabel = display.newLabel(23, 0, 
        fontWithColor(8, {text = __('分享你的专属二维码，邀请链接，可以获得外观券，具体规则：\n\n1.其他人每次点击，你获得1个外观券，每日最多5个，每周20个封顶。\n\n2.邀请新玩家通过你的链接下载并将角色提升至20级，你获得10个外观券，无上限。\n3.注意：通过点击链接方式，会受到IP限制，每个IP一天只能生效1次。'),
    ap = display.LEFT_TOP, hAlign = display.TAL, w = 335 - 20}))

    local size = cc.size(355, 100 + display.getLabelContentSize(descrLabel).height)

    local layer = display.newLayer(0, 0, {ap = display.RIGHT_TOP, size = size})

    local boardBg = display.newImageView(_res('ui/common/common_bg_tips_common.png'), 0, 0,
    {ap = cc.p(0, 0), animate = false, enable = true, scale9 = true, size = size})		
    layer:addChild(boardBg)

    local boardArrow = display.newNSprite(_res('ui/common/common_bg_tips_horn.png'), size.width, size.height - 20, {ap = display.LEFT_TOP})
    boardArrow:setRotation(90)
    display.commonUIParams(boardArrow,{po = cc.p(size.width + 10, size.height - 20)})
    boardBg:addChild(boardArrow)

    -- common_title_3
    createTitle(layer, _res('ui/common/common_title_3.png'), __('玩法说明'), cc.p(size.width / 2, size.height - 10), 5)

    descrLabel:setPositionY(size.height - 50)
    boardBg:addChild(descrLabel)

    
    -- 10, size.height - 50
    -- dump(display.getLabelContentSize(descrLabel))

    -- local layer1 = display.newLayer(10, size.height - 50, {color = cc.c3b(100,100,100), ap = display.LEFT_TOP, size = display.getLabelContentSize(descrLabel)})
    -- layer:addChild(layer1)
    -- local titleBg = display.newImageView( _res('ui/common/common_title_3.png'),size.width / 2, size.height - 10, {ap = display.CENTER_TOP})
    -- layer:addChild(titleBg)

    -- local titleLabel = display.newLabel(0, 0, fontWithColor(4, {text = __('玩法说明'), ap = display.CENTER}))
    -- display.commonUIParams(titleLabel, {po =  utils.getLocalCenter(titleBg)})
    -- titleBg:addChild(titleLabel)
    return {
        layer = layer,
    }
end

createTitle = function (parent, img, text, pos, fontColor)
    local titleBg = display.newImageView(img, pos.x, pos.y, {ap = display.CENTER_TOP})
    parent:addChild(titleBg)

    local titleLabel = display.newLabel(0, 0, fontWithColor(fontColor or 3, {text = text, ap = display.CENTER}))
    display.commonUIParams(titleLabel, {po =  utils.getLocalCenter(titleBg)})
    titleBg:addChild(titleLabel)
end

createInputBox = function (parent, text, placeHolderText, pos, maxLength)
    local label = display.newLabel(0, 0, {text = text, fontSize = 24, color = '#a19b85'})
    local labelSize = display.getLabelContentSize(label)
    local editBoxSize = cc.size(225, 41)
    local editBox = ccui.EditBox:create(editBoxSize, RES_DIR.PROMOTERS_AGENT_INGO_NUM_BG)
    editBox:setFontSize(fontWithColor('M2PX').fontSize)
    editBox:setFontColor(ccc3FromInt('#5b3c25'))
    editBox:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
    editBox:setPlaceHolder(placeHolderText)
    editBox:setPlaceholderFontSize(fontWithColor('M1PX').fontSize)
    editBox:setPlaceholderFontColor(ccc3FromInt('#8c8c8c'))
    editBox:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)
    editBox:setMaxLength(maxLength)

    display.commonUIParams(editBox, {po = cc.p(pos.x, pos.y), ap = display.LEFT_CENTER})
    display.commonUIParams(label, {po = cc.p(pos.x - 5, pos.y), ap = display.RIGHT_CENTER})

    parent:addChild(editBox)
    parent:addChild(label)

    return editBox
end

function PromotersView:CreatePromotersView(bgSize)
    return CreatePromotersView_(bgSize)
end

function PromotersView:CreateRedeemCodeView(bgSize)
    return CreateRedeemCodeView_(bgSize)
end

function PromotersView:CreateInfoView()
    return CreateInfoView_()
end

function PromotersView:CreateExplainView(size)
    return CreateExplainView_(size)
end

function PromotersView:GetViewData()
    return self.viewData_
end

function PromotersView:GetExplainViewData()
    return self.explainViewData_
end

function PromotersView:getArgs()
	return self.args
end

function PromotersView:CloseHandler()
	local args = self:getArgs()
	local mediatorName = args.mediatorName
	
	local mediator = AppFacade.GetInstance():RetrieveMediator(mediatorName)
    AppFacade.GetInstance():DispatchObservers(FRIEND_REFRESH_EDITBOX, {isEnabled = true})

	if mediator then
		AppFacade.GetInstance():UnRegsitMediator(mediatorName)
	end
	
end

return PromotersView