--[[
常驻累充view
--]]
local CumulativeRechargeView = class('CumulativeRechargeView', function ()
    local node = CLayout:create(display.size)
    node.name = 'home.CumulativeRechargeView'
    node:enableNodeEvents()
    return node
end)

function CumulativeRechargeView:ctor( ... )
    self.args = unpack({...})
    self:InitUI()
end
--[[
init ui
--]]
function CumulativeRechargeView:InitUI()
    local function CreateView()
        local bgSize = cc.size(1100, 602)
        local view = display.newLayer(display.cx, display.cy, {size = bgSize, ap = cc.p(0.5, 0.5)})
        local bg = display.newImageView(_res('ui/home/recharge/recharge_bg.png'), bgSize.width/2, bgSize.height/2)
        view:addChild(bg, 1)
        local mask = CColorView:create(cc.c4b(0, 0, 0, 0))
        mask:setPosition(cc.p(bgSize.width/2, bgSize.height/2))
        mask:setAnchorPoint(cc.p(0.5, 0.5))
        mask:setTouchEnabled(true)
        mask:setContentSize(bgSize)
        view:addChild(mask, -1)
        -- 进度条
        local progressLayoutSize = cc.size(860, 100)
        local progressLayout = CLayout:create(progressLayoutSize)
        progressLayout:setAnchorPoint(cc.p(0.5, 1))
        progressLayout:setPosition(cc.p(bgSize.width/2, bgSize.height - 8))
        view:addChild(progressLayout, 5)
        local progressTips = display.newRichLabel(30, 72, { ap = cc.p(0, 0.5)})
        progressLayout:addChild(progressTips, 3)
        local progressTipsBtn = display.newButton(0, 72, {ap = cc.p(0, 0.5), n = _res('ui/common/common_btn_tips.png')})
        progressLayout:addChild(progressTipsBtn, 5)
        local progressLabel = display.newLabel(360, progressLayoutSize.height/2 - 8, {text = '', fontSize = 20, color = '#ffffff'})
        progressLayout:addChild(progressLabel, 3)
        local progressBar = CProgressBar:create(_res('ui/home/recharge/recharge_bar_1.png'))
        progressBar:setBackgroundImage(_res('ui/home/recharge/recharge_bar_2.png'))
        progressBar:setDirection(eProgressBarDirectionLeftToRight)
        progressBar:setAnchorPoint(cc.p(0.5, 0.5))
        progressBar:setPosition(cc.p(360, progressLayoutSize.height/2 - 8))
        progressLayout:addChild(progressBar, 1)
        local rechargeBtn = display.newButton(progressLayoutSize.width - 85, progressLayoutSize.height/2, {n = _res('ui/common/common_btn_green.png')})
        progressLayout:addChild(rechargeBtn, 1)
        display.commonLabelParams(rechargeBtn, fontWithColor(14, {text = __('去充值')}))
        local lastRichLabel = display.newRichLabel(300, 10, { ap = cc.p(0.5, 0.5)})
        progressLayout:addChild(lastRichLabel, 1)
        local rechargeTipsStr = '每充值1元=1积分'
        --if isElexSdk() or isKoreanSdk() or isEfunSdk() then
        --    rechargeTipsStr = __('充值金额对应积分内容请见活动详情')
        --end
        --local rechargeTips = display.newLabel(progressLayoutSize.width - 20, 0, fontWithColor(15, {text = rechargeTipsStr,w = 330, ap = cc.p(1, 1)}))
        --progressLayout:addChild(rechargeTips, 3)
        -- 切换按钮
        local leftSwitchBtn = display.newButton(85, bgSize.height/2, {n = _res('ui/home/recharge/recharge_btn_arrow.png'), tag = 101})
        leftSwitchBtn:setScaleX(-1)
        view:addChild(leftSwitchBtn, 5)
        local rightSwitchBtn = display.newButton(bgSize.width - 85, bgSize.height/2, {n = _res('ui/home/recharge/recharge_btn_arrow.png'), tag = 102})
        view:addChild(rightSwitchBtn, 5)
        -- 立绘
        local roleLayoutSize = cc.size(440, 480)
        local roleLayout = CLayout:create(roleLayoutSize)
        display.commonUIParams(roleLayout, {ap = cc.p(0, 0), po = cc.p(80, 12)})
        view:addChild(roleLayout, 1)
        local role = display.newImageView(_res('ui/home/recharge/recharge_npc.png'), - 60, -12, {ap = cc.p(0, 0)})
        roleLayout:addChild(role, 1)
        local title = display.newImageView(_res('ui/home/recharge/recharge_title.png'), 220, 130)
        roleLayout:addChild(title, 5) 
        local titleEffect = sp.SkeletonAnimation:create(
          'effects/activity/leichong_lizi.json',
          'effects/activity/leichong_lizi.atlas',
          0.7)
        titleEffect:setAnimation(0, 'idle', true)
        titleEffect:setPosition(cc.p(220, 130))
        roleLayout:addChild(titleEffect, 2)
        local cumulativeBg = display.newImageView(_res('ui/home/recharge/recharge_bg_accumulative_recharge.png'), roleLayoutSize.width/2 + 50, 28)
        roleLayout:addChild(cumulativeBg, 1)
        local cumulativeRichLabel = display.newRichLabel(cumulativeBg:getContentSize().width/2, cumulativeBg:getContentSize().height/2, {})
        cumulativeBg:addChild(cumulativeRichLabel, 1)
        -- 创建奖励列表
        local rewardLayout = require('Game.views.CumulativeRechargeRewardView').new()
        display.commonUIParams(rewardLayout, {ap = cc.p(1, 0), po = cc.p(bgSize.width - 80, 12)})
        view:addChild(rewardLayout, 3)
        local nextRewardLayout = require('Game.views.CumulativeRechargeRewardView').new()
        display.commonUIParams(nextRewardLayout, {ap = cc.p(1, 0), po = cc.p(bgSize.width - 80, 12)})
        view:addChild(nextRewardLayout, 3)
        nextRewardLayout:setVisible(false)
        local drawBtn = display.newButton(bgSize.width - 371, 50, {n = _res("ui/common/common_btn_orange.png"), d = _res("ui/common/activity_mifan_by_ico.png")})
        display.commonLabelParams(drawBtn, fontWithColor(14, {text = __('领取')}))
        view:addChild(drawBtn, 5)
        local drawLabel = display.newLabel(drawBtn:getContentSize().width/2, drawBtn:getContentSize().height/2, {text = __('已领取'), fontSize = 24, color = '#ffffff'})
        drawBtn:addChild(drawLabel, 1)
        return {
            view                = view, 
            rewardLayout        = rewardLayout,
            nextRewardLayout    = nextRewardLayout,
            drawBtn             = drawBtn,
            drawLabel           = drawLabel,
            progressBar         = progressBar,
            progressTips        = progressTips,
            progressTipsBtn     = progressTipsBtn,
            progressLabel       = progressLabel,
            lastRichLabel       = lastRichLabel,
            rechargeBtn         = rechargeBtn,
            leftSwitchBtn       = leftSwitchBtn,
            rightSwitchBtn      = rightSwitchBtn,
            cumulativeBg        = cumulativeBg ,
            cumulativeRichLabel = cumulativeRichLabel,
            role                = role,

        }
    end 
    -- eaterLayer
    local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 255*0.6))
    eaterLayer:setCascadeOpacityEnabled(true)
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    self:addChild(eaterLayer, -1)
    eaterLayer:setOnClickScriptHandler(function()
        PlayAudioByClickClose()
        AppFacade.GetInstance():UnRegsitMediator("CumulativeRechargeMediator")
    end)
    xTry(function ( )
        self.viewData_ = CreateView( )
        self:addChild(self.viewData_.view, 1)
    end, __G__TRACKBACK__)
end
return CumulativeRechargeView