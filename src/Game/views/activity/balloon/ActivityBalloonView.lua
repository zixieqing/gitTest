--[[
打气球活动view
--]]
local ActivityBalloonView = class('ActivityBalloonView', function ()
    local node = CLayout:create(display.size)
    node.name = 'home.view.activity.balllon.ActivityBalloonView'
    node:enableNodeEvents()
    return node
end)

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")

function ActivityBalloonView:ctor( ... )
    self.args = unpack({...})
    self:InitUI()
end
--[[
init ui
--]]
function ActivityBalloonView:InitUI()
    local function CreateView()
        local view = CLayout:create(display.size)
        local bg = display.newImageView(_res('ui/home/activity/balloon/activity_61_bg.png'), display.cx, display.cy)
        view:addChild(bg, 1)
        -- 标题板
        local tabNameLabel = display.newButton(display.SAFE_L + 130, display.height, {n = _res('ui/common/common_title_new.png'),enable = true,ap = cc.p(0, 1)})
        display.commonLabelParams(tabNameLabel, {ttf = true, font = TTF_GAME_FONT, text = '', fontSize = 30, color = '473227',offset = cc.p(0,-8)})
        view:addChild(tabNameLabel, 10)
        -- 人物立绘
        local roleImg = AssetsUtils.GetCardDrawNode('200021', display.SAFE_L + 330, display.cy - 170)
        view:addChild(roleImg, 3)
        -- 兑换
        local exchangeLayoutSize = cc.size(460, 140)
        local exchangeLayout = CLayout:create(exchangeLayoutSize)
        exchangeLayout:setPosition(cc.p(display.SAFE_L + 300, 195))
        view:addChild(exchangeLayout, 5)
        local exchangeBtnBg = display.newImageView(_res('ui/home/activity/balloon/activity_bg_reward.png'), exchangeLayoutSize.width/2, exchangeLayoutSize.height/2)
        exchangeLayout:addChild(exchangeBtnBg, 3)
        local exchangeDescr = display.newLabel(exchangeLayoutSize.width/2, exchangeLayoutSize.height - 26, fontWithColor(18, {hAlign = display.TAC , w = 420 , text = __('戳破气球获得道具兑换奖励')}))
        exchangeLayout:addChild(exchangeDescr, 5)
        local exchangeBtn = display.newButton(exchangeLayoutSize.width/2, 50, { n = _res('ui/common/common_btn_orange_big.png')})
        exchangeLayout:addChild(exchangeBtn, 5)
        display.commonLabelParams(exchangeBtn, {text = __('兑换奖励'), w = 160 ,hAlign = display.TAC ,  fontSize = 26, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#5b3c25'})
        -- 气球靶盘
        local targetLayoutSize = cc.size(740, 802)
        local targetLayout = CLayout:create(targetLayoutSize)
        targetLayout:setPosition(display.width - 400 - display.SAFE_L, display.cy - 102)
        view:addChild(targetLayout, 5)
        local targetLayoutBg = display.newImageView(_res('ui/home/activity/balloon/activity_bg_qiqiu.png'), targetLayoutSize.width/2, targetLayoutSize.height/2)
        targetLayout:addChild(targetLayoutBg, 1)
        -- 气球
        local balloonImgs = {}
        local balloonSpines = {}
        local centerBalloonImg = display.newImageView(_res('ui/home/activity/balloon/activity_icon_qiqiu_0.png'), targetLayoutSize.width/2 + 5, 524)
        targetLayout:addChild(centerBalloonImg, 5)
        centerBalloonImg:setOpacity(255*0.2)
        centerBalloonImg:setVisible(false)
        table.insert(balloonImgs, centerBalloonImg)
        local centerBalloonSpine = sp.SkeletonAnimation:create(
          'effects/activity/qiqiu.json',
          'effects/activity/qiqiu.atlas',
          1)
        centerBalloonSpine:update(0)
        centerBalloonSpine:setToSetupPose()
        centerBalloonSpine:setAnimation(0, 'idle', true)
        centerBalloonSpine:setPosition(targetLayoutSize.width/2 + 5, 524)
        targetLayout:addChild(centerBalloonSpine, 7)
        centerBalloonSpine:setVisible(false)
        table.insert(balloonSpines, centerBalloonSpine)
        for i = 1, 8 do
            local centerPos = cc.p(372, 528)
            local angle = 45
            local radius = 155
            local radian = math.rad((i-1)*angle)
            local pos = cc.p(centerPos.x + radius*math.sin(radian), centerPos.y + radius*math.cos(radian))
            -- 气球img
            local balloonImg = display.newImageView(_res(string.format('ui/home/activity/balloon/activity_icon_qiqiu_%d.png', i)), pos.x, pos.y)
            targetLayout:addChild(balloonImg, 5)
            balloonImg:setOpacity(255*0.2)
            balloonImg:setVisible(false)
            table.insert(balloonImgs, balloonImg)
            -- 气球spine
            local ballonSpine = sp.SkeletonAnimation:create(
              'effects/activity/qiqiu.json',
              'effects/activity/qiqiu.atlas',
              0.8)
            ballonSpine:update(0)
            ballonSpine:setToSetupPose()
            ballonSpine:setAnimation(0, 'idle', true)
            ballonSpine:setPosition(pos)
            ballonSpine:setRotation((i-1)*angle)
            targetLayout:addChild(ballonSpine, 7)
            ballonSpine:setVisible(false)
            table.insert(balloonSpines, ballonSpine)
        end
        -- 戳一个
        local drawOneBtn = display.newButton(116, 285, {n = _res('ui/home/activity/balloon/activity_btn_qiqiu_1.png')})
        targetLayout:addChild(drawOneBtn, 5)
        local drwaOneLabel = display.newLabel(drawOneBtn:getContentSize().width/2, drawOneBtn:getContentSize().height - 32, {text = __('戳一个'), fontSize = 26, color = '#ffffff', ttf = true, font = TTF_GAME_FONT, outline = '#5b3c25'})
        drawOneBtn:addChild(drwaOneLabel, 3)
        local oneConsumeRichLabel = display.newRichLabel(drawOneBtn:getContentSize().width/2, 35)
        drawOneBtn:addChild(oneConsumeRichLabel, 5)
        -- 戳全部
        local drawAllBtn = display.newButton(targetLayoutSize.width - 124, 285, {n = _res('ui/home/activity/balloon/activity_btn_qiqiu_2.png')})
        targetLayout:addChild(drawAllBtn, 5)
        local drwaAllLabel = display.newLabel(drawAllBtn:getContentSize().width/2, drawAllBtn:getContentSize().height - 32, {text = __('戳全部'), fontSize = 26, color = '#ffffff', ttf = true, font = TTF_GAME_FONT, outline = '#5b3c25'})
        drawAllBtn:addChild(drwaAllLabel, 3)     
        local allConsumeRichLabel = display.newRichLabel(drawAllBtn:getContentSize().width/2, 35)
        drawAllBtn:addChild(allConsumeRichLabel, 5)
        -- 拥有数量
        local hasRichLabel = display.newRichLabel(targetLayoutSize.width/2 - 33, 264)
        targetLayout:addChild(hasRichLabel, 5)
        -- 获取按钮
        local getBtn = display.newButton(targetLayoutSize.width/2 + 99, 257, {n = _res('ui/home/activity/balloon/activity_btn_qiqiu_add.png')})
        targetLayout:addChild(getBtn, 5)
        return {
            view                = view,
            tabNameLabel        = tabNameLabel,
            tabNameLabelPos     = cc.p(tabNameLabel:getPosition()),
            drawOneBtn          = drawOneBtn,
            oneConsumeRichLabel = oneConsumeRichLabel,
            drawAllBtn          = drawAllBtn,
            allConsumeRichLabel = allConsumeRichLabel,
            exchangeBtn         = exchangeBtn,
            getBtn              = getBtn,
            hasRichLabel        = hasRichLabel,
            balloonImgs         = balloonImgs,
            balloonSpines       = balloonSpines,

        }

    end
    -- eaterLayer
    local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 255*0.6))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    self:addChild(eaterLayer, -1)
    xTry(function ( )
        self.viewData = CreateView( )
        self:addChild(self.viewData.view)
        self.viewData.view:setPosition(display.center)
    end, __G__TRACKBACK__)
    -- 弹出标题板
    self.viewData.tabNameLabel:setPositionY(display.height + 100)
    local action = cc.EaseBounceOut:create(cc.MoveTo:create(1, self.viewData.tabNameLabelPos))
    self.viewData.tabNameLabel:runAction( action )
end
return ActivityBalloonView