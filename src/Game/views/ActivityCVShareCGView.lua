--[[
CV分享活动CGview
--]]
local ActivityCVShareCGView = class('ActivityCVShareCGView', function ()
    local node = CLayout:create(display.size)
    node:setAnchorPoint(cc.p(0, 0))
    node.name = 'home.ActivityCVShareCGView'
    node:enableNodeEvents()
    return node
end)
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")

function ActivityCVShareCGView:ctor( ... )
    self.args = unpack({...})
    self.cvDatas = checktable(self.args.cvDatas)
    self.shareRewards = checktable(self.args.shareRewards[1])
    self:InitUI()
    self:RegisterSignal()
end
--[[
init ui
--]]
function ActivityCVShareCGView:InitUI()
    local function CreateView()
        local view = display.newLayer(0,0,{size = display.size, ap = cc.p(0.5,0.5)})
        local cg = display.newImageView(_res(string.format('ui/home/activity/cvShare/cg/share_cg_%s.jpg', self.cvDatas.cvId)), display.cx, display.cy)
        view:addChild(cg, 1)
        local backBtn = display.newButton(30 + display.SAFE_L, display.height - 18, {n = _res('ui/common/common_btn_back.png'), ap = cc.p(0, 1)})
        view:addChild(backBtn, 10)
        -- 分享按钮
        local shareLayout = CLayout:create(cc.size(250, 180))
        shareLayout:setPosition(cc.p(display.width - display.SAFE_L - 180, 0))
        shareLayout:setAnchorPoint(cc.p(0.5, 0))
        view:addChild(shareLayout, 5)
        local shareBg = display.newImageView(_res('ui/home/activity/cvShare/share_bg_button.png'), 125, 90)
        shareLayout:addChild(shareBg, 1)
        local shareTipsLabel = display.newLabel(shareLayout:getContentSize().width/2, 134, fontWithColor(18, {w = 260 , ap = display.CENTER_BOTTOM , hAlign = display.TAC,  text = __('（分享后聆听飨灵专属故事）')}))
        shareLayout:addChild(shareTipsLabel, 10)
        local shareBtn = display.newButton(shareLayout:getContentSize().width/2, 92, {n = _res('ui/common/common_btn_blue_default.png')})
        shareLayout:addChild(shareBtn, 10)
        display.commonLabelParams(shareBtn, fontWithColor(14, {text = __('分享')}))
        local rewardLabel = display.newRichLabel(shareLayout:getContentSize().width/2, 50, {r = true, c = {
            {text = string.fmt(__('奖励_num_'), {['_num_'] = tostring(self.shareRewards.num)}), color = '#ffffff', fontSize = 22},
            {img = CommonUtils.GetGoodsIconPathById(self.shareRewards.goodsId), scale = 0.2}
        }})
        shareLayout:addChild(rewardLabel, 10)
        -- 分享图片
        local shareImg
        if isElexSdk() then
            shareImg = display.newImageView(_res(string.format('ui/home/activity/cvShare/cg/share_cg_%s.png', self.cvDatas.cvId)), display.cx, display.cy)
            shareImg:setVisible(false)
            view:addChild(shareImg, -1)
            local shareImgSize = shareImg:getContentSize()
            local shareImgQrCode = display.newImageView(_res(string.format('ui/home/activity/cvShare/shareCg/activity_share_cg_%s_1.png', self.cvDatas.cvId)), shareImgSize.width/2, shareImgSize.height/2)
            shareImg:addChild(shareImgQrCode)
        else
            shareImg = display.newImageView(_res(string.format('ui/home/activity/cvShare/shareCg/activity_share_cg_%s.png', self.cvDatas.cvId)), display.cx, display.cy)
            shareImg:setVisible(false)
            view:addChild(shareImg, -1)
        end
        return {
            view             = view,
            backBtn          = backBtn,
            shareLayout      = shareLayout,
            shareBtn         = shareBtn,
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
function ActivityCVShareCGView:EnterAction()
    local viewData_ = self.viewData_
    viewData_.view:setOpacity(0)
     viewData_.view:runAction(
        cc.FadeIn:create(0.3)
    )
end
--[[
隐藏分享界面
--]]
function ActivityCVShareCGView:HideShareView()
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
function ActivityCVShareCGView:RegisterSignal()

    ------------ 分享返回按钮 ------------
    AppFacade.GetInstance():RegistObserver('SHARE_BUTTON_BACK_EVENT', mvc.Observer.new(function (_, signal)
        self:HideShareView()
    end, self))
    ------------ 分享返回按钮 ------------

end
--[[
销毁信号
--]]
function ActivityCVShareCGView:UnRegistSignal()
    AppFacade.GetInstance():UnRegistObserver('SHARE_BUTTON_BACK_EVENT', self)
end
function ActivityCVShareCGView:onCleanup()
    -- 注销信号
    self:UnRegistSignal()
end
return ActivityCVShareCGView
