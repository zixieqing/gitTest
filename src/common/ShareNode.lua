--[[
--共享分享层的页面的逻辑
--@param visitNode 分享需要截图的节点
--]]
local ShareNode = class('ShareNode', function()
    local node = CLayout:create(display.size)
    node.name = 'ShareNode'
    return node
end)

require('root.AppSDK')

local t = {
    {icon = _res('share/share_btn_share_facebook'), type = SHARE_TYPE.FACEBOOK},
    {icon = _res('share/share_btn_share_line'), type = SHARE_TYPE.LINE},
    {icon = _res('share/share_btn_share_whatsapp'), type = SHARE_TYPE.WHATSAPP},
}
if isKoreanSdk() then
    t = {
        {icon = _res('share/share_btn_share_facebook'), type = SHARE_TYPE.FACEBOOK},
    }
elseif isJapanSdk() then
    t = {
        {icon = _res('share/share_btn_share_twitter'), type = SHARE_TYPE.TWITTER},
    }
elseif  isNewUSSdk() then
    t = {
        {icon = _res('share/share_btn_share_facebook'), type = SHARE_TYPE.FACEBOOK},
    }
end

function ShareNode:ctor( ... )
    local args = unpack({...})
    local targetNode = args.visitNode --
    local cardId = args.cardId
    local imageName = args.name or 'eater_share.jpg'

    local function CreateView()
        local size = cc.size(display.width, 112)
        local view = CLayout:create(display.size)
        local touchView = CColorView:create(cc.c4b(100,100,100,0))
        touchView:setTouchEnabled(true)
        touchView:setContentSize(display.size)
        display.commonUIParams(touchView, {ap = display.CENTER_BOTTOM, po = cc.p(display.cx, 0)})
        view:addChild(touchView, -1)
        local bottomView = CLayout:create(size)
        display.commonUIParams(bottomView, {ap = display.CENTER_TOP, po = cc.p(display.cx, -size.height)})
        view:addChild(bottomView)
        local cview = display.newLayer(0,0,{bg = _res('share/share_bg_down'), scale9 = true, size = size})
        bottomView:addChild(cview)
        local buttons = {}
        local len = #t
        for i,val in pairs(t) do
            local btn = display.newButton(size.width - ((len - i) * 72 + (len - i + 1) * 30) - display.SAFE_L, size.height * 0.5 - 4,{
                n = val.icon, ap = display.RIGHT_CENTER
            })
            btn:setUserTag(i)
            cview:addChild(btn, 2)
            table.insert(buttons, btn)
        end

        local gameMgr = AppFacade.GetInstance():GetManager('GameManager')
        local headerNode = require('root.CCHeaderNode').new({bg = _res('ui/home/infor/setup_head_bg_2.png'),pre = gameMgr:GetUserInfo().avatarFrame})
        display.commonUIParams(headerNode,{po = cc.p(15 + display.SAFE_L, size.height * 0.5 - 4), ap = display.LEFT_CENTER})
        headerNode:setScale(0.62)
        bottomView:addChild(headerNode,2)

        local gameMgr = AppFacade.GetInstance():GetManager('GameManager')
        local playerNameLabel = display.newLabel(118 + display.SAFE_L, 82,fontWithColor(14,{ ap = display.LEFT_TOP, text = gameMgr:GetUserInfo().playerName, ttf = false}))
        bottomView:addChild(playerNameLabel,2)
        local levelLabel = display.newLabel(118 + display.SAFE_L, 50,fontWithColor(14,{ ap = display.LEFT_TOP, fontSize = 22, text = string.fmt(__('等级:%1'),gameMgr:GetUserInfo().level)}))
        bottomView:addChild(levelLabel,2)

        local qrPath = _res('share/qrcode')
        local qrCodeImage = display.newImageView(qrPath, size.width - 10 - display.SAFE_L,8, {ap = display.RIGHT_BOTTOM, scale = 0.5})
        bottomView:addChild(qrCodeImage,2)
        qrCodeImage:setOpacity(0)
        -- if not CommonUtils.GetIsOpenPhone() then
        qrCodeImage:setVisible(false)
        -- end
        -- local textImage = display.newImageView(_res('share/share_ico_text'),size.width - 160 - display.SAFE_L, 66, {ap = display.RIGHT_TOP})
        -- bottomView:addChild(textImage,2)
        -- textImage:setOpacity(0)

        local logoImage = display.newImageView(_res('share/share_ico_logo'), display.width - 160 - display.SAFE_L, display.height - 80)
        view:addChild(logoImage, 10)
        logoImage:setOpacity(0)

        return {
            view            = view,
            touchView       = touchView,
            bottomView      = bottomView,
            cview           = cview,
            buttons         = buttons,
            playerNameLabel = playerNameLabel,
            levelLabel      = levelLabel,
            qrCodeImage     = qrCodeImage,
            -- textImage       = textImage,
            logoImage       = logoImage,
        }
    end

    local viewData = CreateView()
    display.commonUIParams(viewData.view, {ap = display.CENTER_BOTTOM, po = cc.p(display.cx, 0)})
    self:addChild(viewData.view, 10)
    self.viewData = viewData

    local backBtn = display.newButton(0, 0, {n = _res("ui/common/common_btn_back")})
    display.commonUIParams(backBtn, {po = cc.p(display.SAFE_L + backBtn:getContentSize().width * 0.5 + 30, display.height - 18 - backBtn:getContentSize().height * 0.5)})
    backBtn:setName('btn_backButton')
    sceneWorld:addChild(backBtn, 2000)
    backBtn:setOnClickScriptHandler(function(sender)
        PlayAudioByClickNormal()
        viewData.touchView:setTouchEnabled(false)
        backBtn:runAction(cc.RemoveSelf:create())
        AppFacade.GetInstance():DispatchObservers('SHARE_BUTTON_BACK_EVENT')
    end)
    backBtn:setOpacity(0)

    for name,val in pairs(viewData.buttons) do
        val:setOnClickScriptHandler(function(sender)
            PlayAudioByClickNormal()
            sender:setEnabled(false)
            local shareType = sender:getUserTag()
            if Platform.id >= 4000 and Platform.id <= 4999 then
                shareType = t[sender:getUserTag()].type
            end
            -- local actions = {}
            -- table.insert(actions, cc.TargetedAction:create(viewData.cview,cc.MoveTo:create(0.24,cc.p(0,-112))))
            -- table.insert(actions, cc.TargetedAction:create(viewData.textImage, cc.FadeIn:create(0.24)))
            -- cc.TargetedAction:create(viewData.textImage, cc.FadeIn:create(0.24))),
            self:runAction(cc.Sequence:create(cc.Spawn:create(cc.TargetedAction:create(viewData.cview,cc.MoveTo:create(0.24,cc.p(0,-112))),
            cc.TargetedAction:create(viewData.qrCodeImage, cc.FadeIn:create(0.24))),
            cc.CallFunc:create(function()
                if targetNode.ShareAction then
                    targetNode:ShareAction(false)
                end
                AppFacade.GetInstance():DispatchObservers('SHARE_VIEW_WILL_SHOW_EVENT')
                cc.utils:captureNode(function(isOk, path)
                    if device.platform == 'ios' or device.platform == 'android' then
                        if isJapanSdk() then
                            if cardId then
                                --如果存在卡牌id表示是cv分享的逻辑取分享的文字
                                local shareData = CommonUtils.GetConfigNoParser("activity", "cvDialogue", cardId)
                                if shareData and shareData.shareText then
                                    require('root.AppSDK').GetInstance():InvokeShare(shareType,{image = path, linkUrl = 'https://app.adjust.com/36bexu?campaign=ingame_twszqy_tw_2_banner_002',
                                        description = string.fmt(shareData.shareText, {_text_ = shareData.url}),type = CONTENT_TYPE.C2DXContentTypeImage})
                                end
                            else
                                require('root.AppSDK').GetInstance():InvokeShare(shareType,{image = path, linkUrl = 'https://app.adjust.com/36bexu?campaign=ingame_twszqy_tw_2_banner_002', description = '一緒に「フードファンタジー」の世界を冒険しましょう！  #フードファンタジー',type = CONTENT_TYPE.C2DXContentTypeImage})
                            end
                        elseif isChinaSdk() then
                            local text  = args.descr or '#食之契约#豪华奖励免费领！完成任务即可免费领取UR武夷大红袍！全新联动版本11月26日等你开启！更有三周年庆典将于12月盛大开幕！快来领取超强限定飨灵！'  --
                            local title = args.title or '#食之契约#豪华奖励免费领！完成任务即可免费领取UR武夷大红袍！全新联动版本11月26日等你开启！更有三周年庆典将于12月盛大开幕！快来领取超强限定飨灵！'  --
                            local myurl = args.myurl
                            require('root.AppSDK').GetInstance():InvokeShare(shareType,{image = path, title = title, text = text , myurl = myurl, type = CONTENT_TYPE.C2DXContentTypeImage})
                        elseif isKoreanSdk() then
                            require('root.AppSDK').GetInstance():InvokeShare(shareType,{image = path, linkUrl = 'https://app.adjust.com/36bexu?campaign=ingame_twszqy_tw_2_banner_002', description = '초강력 식신 등장, 신규 던전과 신규 이벤트 오픈!#테이스티 사가# 어서 빨리 오셔서 신규 이벤트를 완성하여 무료 보상을 획득하세요! ',type = CONTENT_TYPE.C2DXContentTypeImage})
                        elseif isEfunSdk() then
                            require('root.AppSDK').GetInstance():InvokeShare(shareType,{image = path, linkUrl = 'https://app.adjust.com/36bexu?campaign=ingame_twszqy_tw_2_banner_002', description = '《食之契約》是款二次元超幻想美食冒險手機遊戲！各類美食幻化的食靈角色！遊戲更有豐崎愛生、佐倉綾音、澤城美雪等一線豪華聲優，為你帶來視覺、聽覺、味覺的終極饗宴！',type = CONTENT_TYPE.C2DXContentTypeImage})
                        else
                            require('root.AppSDK').GetInstance():InvokeShare(shareType,{image = path, title = title, text = text , myurl = myurl, type = CONTENT_TYPE.C2DXContentTypeImage})
                        end
                    else
                        AppFacade.GetInstance():DispatchObservers('SHARE_REQUEST_RESPONSE')
                    end
                end, imageName, targetNode, 1.0)
            end)))
        end)
    end
    viewData.view:runAction(cc.Sequence:create(cc.CallFunc:create(function()
        AppFacade.GetInstance():DispatchObservers('SHARE_VIEW_WILL_SHOW_EVENT')
        end),
            cc.Spawn:create(cc.TargetedAction:create(viewData.bottomView,cc.MoveTo:create(0.3,cc.p(display.cx, 112))),
    cc.TargetedAction:create(backBtn, cc.FadeIn:create(0.3)),
    cc.TargetedAction:create(viewData.logoImage, cc.FadeIn:create(0.3)))))
end

return ShareNode
