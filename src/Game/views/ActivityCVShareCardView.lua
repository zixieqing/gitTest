--[[
CV分享活动卡牌view
--]]
local ActivityCVShareCardView = class('ActivityCVShareCardView', function ()
    local node = CLayout:create(display.size)
    node:setAnchorPoint(cc.p(0, 0))
    node.name = 'home.ActivityCVShareCardView'
    node:enableNodeEvents()
    return node
end)
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")

function ActivityCVShareCardView:ctor( ... )
    self.args = unpack({...})
    self.cvDatas = checktable(self.args.cvDatas)
    self.shareRewards = checktable(self.args.shareRewards[1])
    self:InitUI()
    self:RegisterSignal()
end
--[[
init ui
--]]
function ActivityCVShareCardView:InitUI()
    local cardDatas = CommonUtils.GetConfig('cards', 'card', self.cvDatas.cvCardId)
    local function CreateView()
        local view = display.newLayer(0,0,{size = display.size, ap = cc.p(0.5,0.5)})
        local cardImg = display.newImageView(_res(string.format('ui/home/activity/cvShare/cardImg/activity_%s', self.cvDatas.cvShareCard)), display.cx, display.cy)
        view:addChild(cardImg, 1)
        local bg = display.newImageView(_res('ui/home/activity/cvShare/activity_cv_share_bg.png'), display.cx, display.cy)
        view:addChild(bg, 1)
        local backBtn = display.newButton(30 + display.SAFE_L, display.height - 18, {n = _res('ui/common/common_btn_back.png'), ap = cc.p(0, 1)})
        view:addChild(backBtn, 10)
        -- 分享按钮
        local shareLayout = CLayout:create(cc.size(250, 180))
        shareLayout:setPosition(cc.p(200 + display.SAFE_L, 0))
        shareLayout:setAnchorPoint(cc.p(0.5, 0))
        view:addChild(shareLayout, 5)
        local shareTipsLabel = display.newLabel(shareLayout:getContentSize().width/2, 144, fontWithColor(18, {w = 360 , ap = display.CENTER_BOTTOM ,hAlign= display.TAC , text = __('（分享后聆听飨灵专属故事）')}))
        shareLayout:addChild(shareTipsLabel, 10)
        local shareBtn = display.newButton(shareLayout:getContentSize().width/2, 92, {n = _res('ui/common/common_btn_blue_default.png')})
        shareLayout:addChild(shareBtn, 10)
        display.commonLabelParams(shareBtn, fontWithColor(14, {text = __('分享')}))
        local rewardLabel = display.newRichLabel(shareLayout:getContentSize().width/2, 40, {r = true, c = {
            {text = string.fmt(__('奖励_num_'), {['_num_'] = tostring(self.shareRewards.num)}), color = '#ffffff', fontSize = 22},
            {img = CommonUtils.GetGoodsIconPathById(self.shareRewards.goodsId), scale = 0.2}
        }})
        shareLayout:addChild(rewardLabel, 10)
        -- 稀有度
        local rareIcon = display.newImageView(CardUtils.GetCardQualityTextPathByCardId(self.cvDatas.cvCardId), display.width - 188 - display.SAFE_L, display.height - 100, {ap = cc.p(0.5, 0.5)})
        view:addChild(rareIcon, 2)
        -- 卡牌名称背景
        local nameBg = display.newImageView(_res('ui/common/share_bg_name_card.png'), display.width - 188 - display.SAFE_L, display.height - 167, {ap = cc.p(0.5, 0.5)})
        view:addChild(nameBg, 2)

        local imgNew = display.newImageView(_res('ui/home/capsule/draw_card_ico_new.png'), 10, nameBg:getContentSize().height * 0.5, {ap = cc.p(0.5, 0.5)})
        nameBg:addChild(imgNew, 2)
        local textNew = display.newLabel(imgNew:getContentSize().width/2 - 6, imgNew:getContentSize().height/2 - 3, fontWithColor(19, {text = __('新')}))
        imgNew:addChild(textNew)
        -- 卡牌名称
        local nameLabel = display.newLabel(display.width - 188 - display.SAFE_L, display.height - 167, fontWithColor(19,{text = cardDatas.name}))
        view:addChild(nameLabel, 5)
        -- cv名称
        local cv = '???'
        if cardDatas.cv ~= '' then
            cv = CommonUtils.GetCurrentCvAuthorByCardId(self.cvDatas.cvCardId)
        end
        local cvLabel = display.newLabel(display.width - 188 - display.SAFE_L, display.height - 216, {text = cv , fontSize = 22, color = '#fca702', ap = cc.p(0.5, 0.5)})
        view:addChild(cvLabel, 3)
        -- 描述
        local descrBg = display.newImageView(_res('ui/home/activity/cvShare/activity_cv_card_words.png'), display.cx, 94)
        descrBg:setCascadeOpacityEnabled(true)
        view:addChild(descrBg, 5)
        local descr = CommonUtils.GetConfigNoParser('activity', 'cvDialogue', self.cvDatas.cvCardId)
        local descrLabel = display.newLabel(14, descrBg:getContentSize().height - 15, {text = descr.dialogue, fontSize = 22, color = 'ffffff', ap = cc.p(0, 1), w = 702, maxL = 4})
        descrLabel:setCascadeOpacityEnabled(true)
        descrBg:addChild(descrLabel)
        -- 分享图片
        local shareImg = display.newImageView(_res(string.format('ui/home/activity/cvShare/shareImg/activity_share_%s.png', self.cvDatas.cvShareCard)), display.cx, display.cy)
        shareImg:setVisible(false)
        view:addChild(shareImg, -1)
        return {
            view             = view,
            backBtn          = backBtn,
            shareLayout      = shareLayout,
            shareBtn         = shareBtn,
            imgNew           = imgNew,
            shareImg         = shareImg,
            rewardLabel      = rewardLabel
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
        self:addChild(self.viewData_.view)
        self.viewData_.view:setPosition(display.center)
        if checkint(self.cvDatas.collected) == 1 then
            self.viewData_.imgNew:setVisible(false)
        end
        if checkint(self.cvDatas.shared) == 1 then
            self.viewData_.rewardLabel:setVisible(false)
        end
        self.viewData_.backBtn:setOnClickScriptHandler(function(sender)
            PlayAudioByClickClose()
            self:runAction(cc.RemoveSelf:create())
        end)
        self.viewData_.shareBtn:setOnClickScriptHandler(function(sender)
            PlayAudioByClickNormal()
        --     -- 添加分享通用框架
            self.viewData_.shareImg:setVisible(true)
            local node = require('common.ShareNode').new({visitNode = self.viewData_.shareImg, name = "cv_share.jpg"})
            node:setName('ShareNode')
            display.commonUIParams(node, {po = utils.getLocalCenter(self)})
            self:addChild(node, 999)
        end)
        self:EnterAction()
    end, __G__TRACKBACK__)
end
function ActivityCVShareCardView:EnterAction()
    local viewData_ = self.viewData_
    viewData_.view:setOpacity(0)
     viewData_.view:runAction(
        cc.FadeIn:create(0.3)
    )
end
--[[
隐藏分享界面
--]]
function ActivityCVShareCardView:HideShareView()
    -- 显示一些全局ui
    AppFacade.GetInstance():DispatchObservers('RAID_SHOW_CHAT_PANEL', {show = true})
    -- 移除分享界面
    if nil ~= self:getChildByName('ShareNode') then
        self:getChildByName('ShareNode'):setVisible(false)
        self:getChildByName('ShareNode'):runAction(cc.RemoveSelf:create())
    end
end
--[[
注册信号
--]]
function ActivityCVShareCardView:RegisterSignal()

    ------------ 分享返回按钮 ------------
    AppFacade.GetInstance():RegistObserver('SHARE_BUTTON_BACK_EVENT', mvc.Observer.new(function (_, signal)
        self:HideShareView()
    end, self))
    ------------ 分享返回按钮 ------------

end
--[[
销毁信号
--]]
function ActivityCVShareCardView:UnRegistSignal()
    AppFacade.GetInstance():UnRegistObserver('SHARE_BUTTON_BACK_EVENT', self)
end
function ActivityCVShareCardView:onCleanup()
    -- 注销信号
    self:UnRegistSignal()
end
return ActivityCVShareCardView
