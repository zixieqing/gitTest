--[[
 * author : kaishiqi
 * descpt : 主界面 - 主题功能
]]
local socket = require('socket')


-------------------------------------------------
-- 中秋节（冒出弹跳毛球）
HOME_THEME_STYLE_MAP.MID_AUTUMN.EXTRA_PANEL_THEME_FUNC = function(ownerNode)
    -- balloon button
    local balloonBtn = display.newLayer(835, 655, {color = cc.r4b(0), size = cc.size(128, 100), enable = true})
    ownerNode:addChild(balloonBtn)

    -- effect define
    local createThemeBalloon = function(sender, isBirthMode)
        local senderSize = sender:getContentSize()
        local senderPos  = cc.p(sender:getPosition())
        local balloonImg = display.newImageView(_res('theme/midAutumn/theme_balloon.png'))
        local container  = sender:getParent()
        container:addChild(balloonImg)
        
        -- init status
        local RANGE_W  = 350
        local startPos = cc.p(senderPos.x + senderSize.width/2, senderPos.y + senderSize.height/2)
        local endPoint = cc.p(startPos.x + math.random(-RANGE_W, RANGE_W), -balloonImg:getContentSize().height)
        balloonImg:setScale(0)
        balloonImg:setOpacity(0)
        balloonImg:setPosition(startPos)
    
        -- run action
        local showTime   = 0.2
        local hideTime   = 0.4
        local DURATION   = 0.5 + math.random(1)
        local jumpAction = cc.Spawn:create(
            cc.CallFunc:create(function()
                if not isBirthMode then
                    if app.audioMgr:IsOpenAudio() then
                        AudioEngine.playEffect('theme/midAutumn/ui_home_zhongqiu_ballon.mp3')
                    end
                end
            end),
            cc.BezierTo:create(DURATION, {
                cc.p(startPos.x, display.height + 150 + math.random(150)), -- start con pos
                cc.p(endPoint.x, display.height + 100 + math.random(100)), -- end con pos
                endPoint,  -- end pos
            }),
            cc.Sequence:create(
                cc.Spawn:create(
                    cc.FadeIn:create(showTime),
                    cc.ScaleTo:create(showTime, 1)
                ),
                cc.DelayTime:create(DURATION - showTime - hideTime),
                cc.FadeOut:create(hideTime)
            )
        )
    
        if isBirthMode then
            local shakeActList = {}
            local shakeRangeW  = 8
            for i = 1, 20 do
                table.insert(shakeActList, cc.MoveTo:create(0.02, cc.p(startPos.x + math.random(-shakeRangeW, shakeRangeW), startPos.y)))
            end
            balloonImg:setAnchorPoint(display.CENTER_BOTTOM)
            balloonImg:runAction(cc.Sequence:create(
                cc.Spawn:create(
                    cc.Sequence:create(shakeActList),
                    cc.ScaleTo:create(0.4, 1),
                    cc.FadeIn:create(0.4)
                ),
                cc.DelayTime:create(1),
                jumpAction
            ))
        else
            balloonImg:runAction(jumpAction)
        end
    end
    
    -- click balloon button
    display.commonUIParams(balloonBtn, {cb = function(sender)
        local ostime   = socket.gettime()
        local lastTime = balloonBtn.clickThemeBalloonLastTime_ or 0
        if ostime - lastTime > 0.2 then
            createThemeBalloon(sender)
            balloonBtn.clickThemeBalloonLastTime_ = ostime
        end
    end})

    -- auto balloon action
    local autoCreateThemeBalloon = function()
        local ostime   = socket.gettime()
        local lastTime = balloonBtn.clickThemeBalloonLastTime_ or 0
        if CommonUtils.ModulePanelIsOpen() and ostime - lastTime > 1.5 then
            createThemeBalloon(balloonBtn, true)
        end
    end
    balloonBtn:runAction(cc.RepeatForever:create(cc.Sequence:create(
        cc.DelayTime:create(3),
        cc.CallFunc:create(autoCreateThemeBalloon),
        cc.DelayTime:create(6),
        cc.CallFunc:create(autoCreateThemeBalloon),
        cc.DelayTime:create(5),
        cc.CallFunc:create(autoCreateThemeBalloon)
    )))
end


-------------------------------------------------
-- 万圣节（连点爆破幽灵）
HOME_THEME_STYLE_MAP.HALLOWEEN.EXTRA_PANEL_THEME_FUNC = function(ownerNode)
    -- ghost button
    local ghostBtn = display.newLayer(515, 185, {color = cc.r4b(0), size = cc.size(128, 120), enable = true})
    ownerNode:addChild(ghostBtn)

    -- ghost spine
    local ghostPath  = app.petMgr.GetPetEggSpinePathByPetEggId(240018)
    local ghostSpine = sp.SkeletonAnimation:create(string.format('%s.json', ghostPath), string.format('%s.atlas', ghostPath), 1)
    ghostSpine:setPosition(cc.p(ghostBtn:getContentSize().width/2, 0))
    ghostSpine:setAnimation(0, 'idle', true)
    ghostBtn:addChild(ghostSpine)

    -- effect define
    local BASE_SCALE = 1      -- 基础缩放
    local MOST_SCALE = 2      -- 最大缩放
    local CHANGE_GAP = 0.12   -- 放大间隔
    local DECAY_RATE = 0.008  -- 衰变比率
    local CALL_TIME  = 0.3    -- 响应时间
    local createGhostEffect = function(isBig)
        local awakeFailSpine = sp.SkeletonAnimation:create('effects/pet/pet_awake_fail.json', 'effects/pet/pet_awake_fail.atlas', 1)
        awakeFailSpine:setPositionX(ghostBtn:getPositionX() + ghostBtn:getContentSize().width/2)
        awakeFailSpine:setPositionY(ghostBtn:getPositionY() + ghostBtn:getContentSize().height + 20)
        awakeFailSpine:setAnchorPoint(cc.p(0.5, 2.2))
        ownerNode:addChild(awakeFailSpine)
        awakeFailSpine:registerSpineEventHandler(function(event)
            awakeFailSpine:runAction(cc.RemoveSelf:create())
        end, sp.EventType.ANIMATION_COMPLETE)

        if isBig then
            awakeFailSpine:setAnimation(0, 'play2', false)
        else
            awakeFailSpine:setAnimation(0, 'play1', false)
            awakeFailSpine:setRotation(math.random(-30, 60))
            awakeFailSpine:setPositionX(awakeFailSpine:getPositionX() + awakeFailSpine:getRotation()*1.6)
        end
    end

    -- update ghost spine
    local updateGhostSpine = function()
        if not ghostSpine.isCooldown_ then
            ghostSpine.isActivated_  = true
            ghostSpine.activateTime_ = socket.gettime()
            ghostSpine:setScale(ghostSpine:getScale() + CHANGE_GAP)

            if ghostSpine:getScale() >= MOST_SCALE then
                ghostSpine.isCooldown_ = true
            end
        end
    end

    -- ghost button schedule
    ghostBtn:scheduleUpdateWithPriorityLua(function(dt)
        if ghostSpine.isActivated_ and ghostSpine.activateTime_ then
            if socket.gettime() - ghostSpine.activateTime_ > CALL_TIME then
                createGhostEffect(ghostSpine.isCooldown_)
                ghostSpine.isActivated_ = false
            end
        end

        if ghostSpine:getScale() > BASE_SCALE then
            ghostSpine:setScale(math.max(BASE_SCALE, ghostSpine:getScale() - DECAY_RATE))

            if ghostSpine:getScale() == BASE_SCALE and ghostSpine.isCooldown_ then
                ghostSpine.isCooldown_ = false
            end
        end
    end, 0)

    -- click ghost button
    display.commonUIParams(ghostBtn, {cb = function(sender)
        local ostime   = socket.gettime()
        local lastTime = ghostBtn.clickThemeBalloonLastTime_ or 0
        if ostime - lastTime > 0.12 then
            updateGhostSpine()
            ghostBtn.clickThemeBalloonLastTime_ = ostime
        end
    end, animate = false})
end


-------------------------------------------------
-- 周年庆2018（彩虹拖尾流星）
HOME_THEME_STYLE_MAP.ANNIVERSARY.EXTRA_PANEL_THEME_FUNC = function(ownerNode)
    -- bear button
    local bearButton = display.newLayer(530, 170, {color = cc.r4b(0), size = cc.size(105, 150), enable = true})
    bearButton:addChild(display.newImageView(_res('theme/anniversary/theme_bear.png'), 0, 0, {ap = display.LEFT_BOTTOM}))
    ownerNode:addChild(bearButton)

    -- drop star
    local DROP_DEGREES = 30
    local NEAR_DEGREES = 90 - DROP_DEGREES
    local DROP_RADIANS = DROP_DEGREES * math.pi / 180
    local NEAR_RADIANS = NEAR_DEGREES * math.pi / 180
    local DROP_SPEED   = 1 / 400 -- 1 sec. move xxx px
    local STREAK_TIME  = 0.8
    local createBearStarEffect = function()
        local targetX = math.random(display.SAFE_L + 200, display.SAFE_R - 200)
        local targetY = math.random(display.SAFE_B + 200, display.SAFE_T - 200)
        local originX = -100
        local originY = targetY + (targetX - originX) * math.tan(DROP_RADIANS)
        if targetX > display.cx then
            originY = display.height + 100
            originX = targetX - (originY - targetY) * math.tan(NEAR_RADIANS)
        end
        local starDis = (targetX - originX) / math.cos(DROP_RADIANS)

        -- streeak node
        local streakNode = cc.MotionStreak:create(STREAK_TIME, 2, 24, cc.c3b(255,255,255), _res('theme/anniversary/star_rainbow.png'))
        streakNode:setPosition(cc.p(originX, originY))
        ownerNode:addChild(streakNode)
        
        -- star node
        local starNode = display.newImageView(_res('theme/anniversary/theme_star.png'), originX, originY, {scale = 0.6})
        ownerNode:addChild(starNode)

        -- star action
        local dropTime  = starDis * DROP_SPEED
        local originPos = cc.p(originX, originY)
        local targetPos = cc.p(targetX, targetY)
        starNode:runAction(cc.Sequence:create(
            cc.Spawn:create(
                cc.TargetedAction:create(starNode, cc.MoveTo:create(dropTime, targetPos)),
                cc.TargetedAction:create(starNode, cc.RotateBy:create(dropTime, dropTime * 270)),
                cc.TargetedAction:create(streakNode, cc.MoveTo:create(dropTime, targetPos))
            ),
            cc.CallFunc:create(function()
                starNode:setVisible(false)

                local boomParticle = cc.ParticleSystemQuad:create('theme/anniversary/star_boom.plist')
                boomParticle:setAutoRemoveOnFinish(true)
                boomParticle:setPosition(targetPos)
                ownerNode:addChild(boomParticle)
            end),
            cc.DelayTime:create(STREAK_TIME - 0.2),
            cc.TargetedAction:create(streakNode, cc.RemoveSelf:create()),
            cc.RemoveSelf:create()
        ))
    end

    -- click bear button
    display.commonUIParams(bearButton, {cb = function(sender)
        local ostime   = socket.gettime()
        local lastTime = bearButton.clickThemeBalloonLastTime_ or 0
        if ostime - lastTime > 0.12 then
            createBearStarEffect()
            bearButton.clickThemeBalloonLastTime_ = ostime
        end
    end, animate = false})

    -------------------------------------------------
    -- balloon layer
    local balloonLayer = display.newLayer()
    balloonLayer.lastCreateTime_ = 0
    ownerNode:addChild(balloonLayer)

    -- create balloon
    local BALLOON_KINDS   = 4
    local CREATE_INTERVAL = 1.5
    local createBalloonNode = function()
        local balloonKind = math.random(BALLOON_KINDS)
        local balloonPosX = math.random(display.SAFE_L + 30, display.SAFE_R - 130)
        local balloonPath = string.fmt('theme/anniversary/main_balloon_%1.png', string.format('%02d', balloonKind))
        local balloonNode = display.newImageView(_res(balloonPath), balloonPosX, -250, {ap = display.CENTER_BOTTOM})
        balloonLayer:addChild(balloonNode)

        balloonNode.speedY = 2
        balloonNode.speedX = math.random() * math.random(-1, 1)
        balloonNode:setScale(0.8 + math.random() * 0.6)
        balloonNode:scheduleUpdateWithPriorityLua(function(dt)
            balloonNode:setPosition(cc.p(
                balloonNode:getPositionX() + balloonNode.speedX,
                balloonNode:getPositionY() + balloonNode.speedY
            ))
            if balloonNode:getPositionY() > display.height then
                balloonNode:runAction(cc.RemoveSelf:create())
            end
        end, 0)
    end

    -- auto balloon schedule
    balloonLayer:scheduleUpdateWithPriorityLua(function(dt)
        if socket.gettime() - balloonLayer.lastCreateTime_ > CREATE_INTERVAL then
            createBalloonNode()
            balloonLayer.lastCreateTime_ = socket.gettime()
        end
    end, 0)
end


-------------------------------------------------
-- 周年庆2019（冒出扑克牌）
HOME_THEME_STYLE_MAP.ANNIVERSARY_2019.EXTRA_PANEL_THEME_FUNC = function(ownerNode)
    local snowPltPath   = 'theme/anniversary2019/xiaoxue.plist'
    local snowPltNode   = cc.ParticleSystemQuad:create(snowPltPath)
    local ownerNodeSize = ownerNode:getContentSize()
    snowPltNode:setPosition(cc.p(ownerNodeSize.width/2, ownerNodeSize.height))
    ownerNode:addChild(snowPltNode)

    -- rabbit spine
    local rabbitSpnPos  = cc.p(630, ownerNodeSize.height)
    local rabbitSpnPath = _spn('theme/anniversary2019/tuzi')
    local rabbitSpnNode = sp.SkeletonAnimation:create(rabbitSpnPath.json, rabbitSpnPath.atlas, 1.0)
    rabbitSpnNode:setPosition(cc.p(rabbitSpnPos.x, rabbitSpnPos.y))
    rabbitSpnNode:setAnimation(0, 'idle', true)
    ownerNode:addChild(rabbitSpnNode)

    -- rabbit button
    local rabbitSize = cc.size(120, 150)
    local rabbitBtn  = display.newLayer(rabbitSpnPos.x - rabbitSize.width/2 + 20, rabbitSpnPos.y - 320, {color = cc.r4b(0), size = rabbitSize, enable = true})
    ownerNode:addChild(rabbitBtn)


    -- effect define
    local createThemePokerCard = function(sender)
        local senderSize = sender:getContentSize()
        local senderPos  = cc.p(sender:getPosition())
        local pokerPath  = string.fmt('theme/anniversary2019/card%1.png', math.random(1,4))
        local pokerImg   = display.newImageView(_res(pokerPath))
        local container  = sender:getParent()
        container:addChild(pokerImg)
        
        -- init status
        local RANGE_W  = 450
        local RANGE_H  = 350
        local startPos = cc.p(senderPos.x + senderSize.width/2, senderPos.y + senderSize.height/2)
        local endPoint = cc.p(startPos.x + math.random(-RANGE_W, RANGE_W), -pokerImg:getContentSize().height)
        pokerImg:setScale(0)
        pokerImg:setOpacity(0)
        pokerImg:setPosition(startPos)
    
        -- run action
        local showTime   = 0.1
        local hideTime   = 0.1
        local DURATION   = showTime + hideTime + math.random(1)
        local jumpAction = cc.Spawn:create(
            cc.BezierTo:create(DURATION, {
                cc.p(startPos.x, startPos.y + RANGE_H + math.random(150)), -- start con pos
                cc.p(endPoint.x, startPos.y + RANGE_H + math.random(300)), -- end con pos
                endPoint,  -- end pos
            }),
            cc.RotateBy:create(DURATION, math.random(360*2, 360*6) * (math.random(100)>50 and 1 or -1)),
            cc.Sequence:create(
                cc.Spawn:create(
                    cc.FadeIn:create(showTime),
                    cc.ScaleTo:create(showTime, 1)
                ),
                cc.DelayTime:create(DURATION - showTime - hideTime),
                cc.FadeOut:create(hideTime),
                cc.RemoveSelf:create()
            )
        )
        pokerImg:runAction(jumpAction)
    end

    -- magicHat button
    local magicHatBtn = display.newLayer(530, 180, {color = cc.r4b(0), size = cc.size(115, 105), enable = true})
    ownerNode:addChild(magicHatBtn)

    local chestLightParticle = cc.ParticleSystemQuad:create('ui/tower/path/particle/chest_light.plist')
    chestLightParticle:setPosition(cc.p(utils.getLocalCenter(magicHatBtn).x, 0))
    magicHatBtn:addChild(chestLightParticle)

    -- click magicHat button
    magicHatBtn:setOnClickScriptHandler(function(sender)
        createThemePokerCard(sender)
    end)
end


-------------------------------------------------
-- 周年庆2020（发光spine + 一本书spine）
HOME_THEME_STYLE_MAP.ANNIVERSARY_2020.EXTRA_PANEL_THEME_FUNC = function(ownerNode)
    local ownerNodeSize = ownerNode:getContentSize()

    -- book spine
    local bookSpine = ui.spine({path = _spn('theme/anniversary2020/book'), init = 'idle'})
    bookSpine:setPosition(575-35, 225)
    ownerNode:add(bookSpine)

    -- snow spine
    local snowSpine = ui.spine({path = _spn('theme/anniversary2020/snow'), init = 'idle'})
    snowSpine:setPosition(ownerNodeSize.width * 0.6, ownerNodeSize.height/2)
    ownerNode:add(snowSpine)
end


-------------------------------------------------
-- 圣诞节2018（下雪spine）
HOME_THEME_STYLE_MAP.CHRISTMAS.EXTRA_PANEL_THEME_FUNC = function(ownerNode)
    local snowPltPath   = 'theme/christmas/christmas_snow.plist'
    local snowPltNode   = cc.ParticleSystemQuad:create(snowPltPath)
    local ownerNodeSize = ownerNode:getContentSize()
    snowPltNode:setPosition(cc.p(ownerNodeSize.width/2, ownerNodeSize.height))
    ownerNode:addChild(snowPltNode)
end


-------------------------------------------------
-- 圣诞节2019
HOME_THEME_STYLE_MAP.CHRISTMAS_2019.EXTRA_PANEL_THEME_FUNC = HOME_THEME_STYLE_MAP.CHRISTMAS.EXTRA_PANEL_THEME_FUNC


-------------------------------------------------
-- 春节2019（播放娃娃掉硬币spine）
HOME_THEME_STYLE_MAP.CHINESE_2019.EXTRA_PANEL_THEME_FUNC = function(ownerNode)
    -- snow particle
    local snowPltPath   = 'theme/chinese2019/christmas_snow.plist'
    local snowPltNode   = cc.ParticleSystemQuad:create(snowPltPath)
    local ownerNodeSize = ownerNode:getContentSize()
    snowPltNode:setPosition(cc.p(ownerNodeSize.width/2, ownerNodeSize.height))
    ownerNode:addChild(snowPltNode)

    -- wawa spine
    local wawaPath  = _spn('theme/chinese2019/chunjiewawa')
    local wawaSpine = sp.SkeletonAnimation:create(wawaPath.json, wawaPath.atlas, 1)
    wawaSpine:setAnimation(0, 'idle', true)
    wawaSpine:setPosition(580, 170)
    ownerNode:addChild(wawaSpine)
    wawaSpine:registerSpineEventHandler(function(event)
        if event.animation == 'play' then
            PlayAudioClip(AUDIOS.UI.ui_cat_end.id)
        elseif event.animation == 'play2' then
            PlayAudioClip(AUDIOS.UI.ui_skin_result.id)
        end
    end, sp.EventType.ANIMATION_COMPLETE)

    local playWawaAnimationFunc = function(animationName)
        wawaSpine:setAnimation(0, animationName, false)
        wawaSpine:addAnimation(0, 'idle', true)
    end

    -- goldWa button
    local goldWaButton = display.newLayer(520, 615, {color = cc.r4b(0), size = cc.size(110, 130), enable = true})
    ownerNode:addChild(goldWaButton)

    -- goldPig button
    local goldPigButton = display.newLayer(510, 165, {color = cc.r4b(0), size = cc.size(140, 130), enable = true})
    ownerNode:addChild(goldPigButton)

    -- click goldWa button
    display.commonUIParams(goldWaButton, {cb = function(sender)
        local ostime   = socket.gettime()
        local lastTime = wawaSpine.clickThemeBalloonLastTime_ or 0
        if ostime - lastTime > 0.6 then
            playWawaAnimationFunc('play')
            wawaSpine.clickThemeBalloonLastTime_ = ostime
        end
    end, animate = false})

    -- click goldPig button
    display.commonUIParams(goldPigButton, {cb = function(sender)
        local ostime   = socket.gettime()
        local lastTime = wawaSpine.clickThemeBalloonLastTime_ or 0
        if ostime - lastTime > 0.6 then
            playWawaAnimationFunc('play2')
            wawaSpine.clickThemeBalloonLastTime_ = ostime
        end
    end, animate = false})
end


-------------------------------------------------
-- 春节2020（满屏随机冒金币）
HOME_THEME_STYLE_MAP.CHINESE_2020.EXTRA_PANEL_THEME_FUNC = function(ownerNode)
    -- snow particle
    local snowPltPath   = 'theme/chinese2020/huaban.plist'
    local snowPltNode   = cc.ParticleSystemQuad:create(snowPltPath)
    local ownerNodeSize = ownerNode:getContentSize()
    snowPltNode:setPosition(cc.p(ownerNodeSize.width/3, ownerNodeSize.height))
    ownerNode:addChild(snowPltNode)
    
    -- mouse spine
    local mousePath  = _spn('theme/chinese2020/2020mouse')
    local mouseSpine = sp.SkeletonAnimation:create(mousePath.json, mousePath.atlas, 1)
    mouseSpine:setAnimation(0, 'idle', true)
    mouseSpine:setPosition(580, 170)
    ownerNode:addChild(mouseSpine)

    -- mouse button
    local mouseButton = display.newLayer(515, 170, {color = cc.r4b(0), size = cc.size(130, 170), enable = true})
    ownerNode:addChild(mouseButton)

    -- click goldWa button
    local GOLD_FLIP_TIME = 0.1
    local GOLD_JUMP_TIME = GOLD_FLIP_TIME * 4
    mouseButton:setOnClickScriptHandler(function(sender)
        local iconPath = CommonUtils.GetGoodsIconPathById(GOLD_ID)
        local goldView = display.newImageView(_res(iconPath), 0, 0)
        local scaleNum = math.random(3,5) / 10
        goldView:setPositionX(math.random(100, ownerNodeSize.width - 200))
        goldView:setPositionY(math.random(100, ownerNodeSize.height - 200))
        goldView:setScale(scaleNum)
        ownerNode:addChild(goldView)
        goldView:setScaleX(0)

        goldView:runAction(cc.Spawn:create(
            cc.JumpBy:create(GOLD_JUMP_TIME, cc.p(0,0), 100, 1),
            cc.Sequence:create(
                cc.ScaleTo:create(GOLD_FLIP_TIME, scaleNum, scaleNum),
                cc.ScaleTo:create(GOLD_FLIP_TIME, 0, scaleNum),
                cc.ScaleTo:create(GOLD_FLIP_TIME, scaleNum, scaleNum),
                cc.ScaleTo:create(GOLD_FLIP_TIME, 0, scaleNum),
                cc.RemoveSelf:create()
            )
        ))
    end)
end


-------------------------------------------------
-- 春节2021
HOME_THEME_STYLE_MAP.CHINESE_2021.EXTRA_PANEL_THEME_FUNC = function(ownerNode)

    -------------------------------------------------
    -- balloon layer
    local balloonLayer = ui.layer()
    balloonLayer.lastCreateTime_ = 0
    ownerNode:addChild(balloonLayer)

    -- create balloon
    local BALLOON_KINDS   = 4
    local CREATE_INTERVAL = 1.5
    local createBalloonNode = function()
        local balloonKind = math.random(BALLOON_KINDS)
        local balloonPosX = math.random(display.SAFE_L + 30, display.SAFE_R - 130)
        local balloonPath = string.fmt('theme/chinese2021/main_balloon_%1.png', string.format('%02d', balloonKind))
        local balloonNode = ui.image({img = _res(balloonPath), p = cc.p(balloonPosX, -250), ap = ui.cb})
        balloonLayer:addChild(balloonNode)

        balloonNode.speedY = 2
        balloonNode.speedX = math.random() * math.random(-1, 1)
        balloonNode:setScale(0.8 + math.random() * 0.6)
        balloonNode:scheduleUpdateWithPriorityLua(function(dt)
            balloonNode:setPosition(cc.p(
                balloonNode:getPositionX() + balloonNode.speedX,
                balloonNode:getPositionY() + balloonNode.speedY
            ))
            if balloonNode:getPositionY() > display.height then
                balloonNode:runAction(cc.RemoveSelf:create())
            end
        end, 0)
    end

    -- auto balloon schedule
    balloonLayer:scheduleUpdateWithPriorityLua(function(dt)
        if socket.gettime() - balloonLayer.lastCreateTime_ > CREATE_INTERVAL then
            createBalloonNode()
            balloonLayer.lastCreateTime_ = socket.gettime()
        end
    end, 0)


    -------------------------------------------------
    -- cow button
    local cowSize    = cc.size(140, 200)
    local cowInitPos = cc.p(580, 660)
    local cowButton  = ui.layer({color = cc.r4b(0), size = cowSize, p = cowInitPos, ap = ui.cc})
    ownerNode:add(cowButton)
    
    -- cow spine
    local cowSpine = ui.spine({path = _spn('theme/chinese2021/cow'), init = 'idle'})
    cowButton:addList(cowSpine):alignTo(nil, ui.cc, {offsetY = -50})

    local comboCount = 0
    local escapeDist = 500
    local escapeTime = 0.6
    local cowEscapeFunc = function(inputAngle)
        comboCount = comboCount + 1
        if comboCount > 2 then
            app.uiMgr:ShowInformationTips(string.fmt(__('连击数：_num_'), {_num_ = comboCount}))
        end
        local currentPos  = cc.p(cowButton:getPosition())
        local outputAngle = inputAngle + 180
        local orientation = math.random(100) > 50 and 1 or -1
        local controlPos1 = inCirclePos(currentPos, escapeDist, escapeDist, outputAngle + 45 * orientation)
        local controlPos2 = inCirclePos(currentPos, escapeDist, escapeDist, outputAngle - 45 * orientation)
        cowButton:stopAllActions()
        cowButton:runAction(cc.Spawn:create(
            cc.Sequence:create(
                cc.RotateTo:create(escapeTime/2, orientation * 180),
                cc.RotateTo:create(escapeTime/2, orientation * 360),
                cc.CallFunc:create(function()
                    comboCount = 0
                end)
            ),
            cc.BezierTo:create(escapeTime, {
                controlPos1, -- start con pos
                controlPos2, -- end con pos
                cowInitPos,  -- end pos
            })
        ))
    end

    local touchEventListener = cc.EventListenerTouchOneByOne:create()
    touchEventListener:registerScriptHandler(function(touch, event)
        local mousePoint = touch:getLocation()
        local worldPoint = cowButton:convertToWorldSpace(PointZero)
        local regionRect = cc.rect(checkint(worldPoint.x), checkint(worldPoint.y), cowSize.width, cowSize.height)
        cowButton.isHit_ = cc.rectContainsPoint(regionRect, mousePoint)
        return true
    end, cc.Handler.EVENT_TOUCH_BEGAN)
    touchEventListener:registerScriptHandler(function(touch, event)
    end, cc.Handler.EVENT_TOUCH_MOVED)
    touchEventListener:registerScriptHandler(function(touch, event)
        if cowButton.isHit_ then
            local mousePoint = touch:getLocation()
            local worldPoint = cowButton:convertToWorldSpace(PointZero)
            local regionRect = cc.rect(checkint(worldPoint.x), checkint(worldPoint.y), cowSize.width, cowSize.height)
            local isEndedHit = cc.rectContainsPoint(regionRect, mousePoint)
            local cowCenterP = cc.p(worldPoint.x + cowSize.width/2, worldPoint.y + cowSize.height/2)
            if isEndedHit then
                local radian = math.atan2(mousePoint.y - cowCenterP.y, mousePoint.x - cowCenterP.x)
                local angle  = 90 - radian * (180 / math.pi)
                cowEscapeFunc(angle)
            end
        end
    end, cc.Handler.EVENT_TOUCH_ENDED)
    cc.Director:getInstance():getEventDispatcher():addEventListenerWithSceneGraphPriority(touchEventListener, cowButton)
end


-------------------------------------------------
-- 清明2019（满屏掉左右滑荡的雨伞怪）
HOME_THEME_STYLE_MAP.TOMB_SWEEPING_2019.EXTRA_PANEL_THEME_FUNC = function(ownerNode)
    local rainPltPath   = 'theme/tombSweeping2019/rain.plist'
    local rainPltNode   = cc.ParticleSystemQuad:create(rainPltPath)
    local ownerNodeSize = ownerNode:getContentSize()
    rainPltNode:setPosition(cc.p(ownerNodeSize.width/2, ownerNodeSize.height))
    ownerNode:addChild(rainPltNode)

    -- sunny doll button
    local sunyDollBtn = display.newImageView(_res('theme/tombSweeping2019/sunny_doll.png'), 560, 930, {ap = display.CENTER_TOP, enable = true})
    ownerNode:addChild(sunyDollBtn)

    -- umbrella sprite
    local createUmbrellaSprite = function()
        local scaleRange = math.random(-1, 1) * 0.05
        local spineSize = cc.size(100, 80 * (1+scaleRange))
        local spineNode = AssetsUtils.GetCardSpineNode({confId = 300055, scale = 0.25+scaleRange})
        spineNode:setScaleX(-spineNode:getScaleX())
        spineNode:setAnimation(0, 'idle', true)
        ownerNode:addChild(spineNode)

        -- status init
        local STAY_ANGLE = 30
        local RANGE_SIZE = cc.size(200, 80)
        local OFF_HEIGHT = (ownerNodeSize.height - display.height) / 2
        spineNode:setPositionX(math.random(RANGE_SIZE.width, display.width))
        spineNode:setPositionY(OFF_HEIGHT + display.height)
        spineNode:setRotation(-STAY_ANGLE)
        
        -- swing update
        local SWING_TIME = 1.5
        local STAY_TIME  = 0.2
        spineNode:runAction(cc.RepeatForever:create(cc.Sequence:create(
            cc.Spawn:create(
                cc.BezierBy:create(SWING_TIME, {
                    cc.p(-RANGE_SIZE.width * 0.3, -RANGE_SIZE.height),  -- start con pos
                    cc.p(-RANGE_SIZE.width * 0.7, -RANGE_SIZE.height),  -- end con pos
                    cc.p(-RANGE_SIZE.width, 0),  -- end pos
                }),
                cc.RotateTo:create(SWING_TIME, STAY_ANGLE)
            ),
            cc.DelayTime:create(STAY_TIME),
            cc.Spawn:create(
                cc.BezierBy:create(SWING_TIME, {
                    cc.p(RANGE_SIZE.width * 0.3, -RANGE_SIZE.height),  -- start con pos
                    cc.p(RANGE_SIZE.width * 0.7, -RANGE_SIZE.height),  -- end con pos
                    cc.p(RANGE_SIZE.width, 0),  -- end pos
                }),
                cc.RotateTo:create(SWING_TIME, -STAY_ANGLE)
            ),
            cc.DelayTime:create(STAY_TIME)
        )))

        -- fall update
        local FALL_SPEED   = -3
        local LIMIT_BOTTOM = OFF_HEIGHT - RANGE_SIZE.height * 1.5
        spineNode:scheduleUpdateWithPriorityLua(function(dt)
            local spinePosY = spineNode:getPositionY()
            if spinePosY > LIMIT_BOTTOM then
                spineNode:setPositionY(spinePosY + FALL_SPEED)
            else
                spineNode:stopAllActions()
                spineNode:runAction(cc.RemoveSelf:create())
            end
        end, 0)
    end

    -- click sunyDoll button
    display.commonUIParams(sunyDollBtn, {cb = function(sender)
        local ostime   = socket.gettime()
        local lastTime = sunyDollBtn.clickLastTime_ or 0
        if ostime - lastTime > 0.7 then
            createUmbrellaSprite()
            sunyDollBtn.clickLastTime_ = ostime
        end
    end, animate = false})
end


-------------------------------------------------
-- 夏日祭2019（连点高跳鸭子）
HOME_THEME_STYLE_MAP.SUMMER_FESTIVAL_2019.EXTRA_PANEL_THEME_FUNC = function(ownerNode)
    -- duck button
    local duckButton = display.newLayer(515, 180, {color = cc.r4b(0), size = cc.size(125, 105), enable = true})
    ownerNode:addChild(duckButton)

    -- duck image
    local duckImage = display.newImageView(_res('theme/summerFestival2019/duck.png'), duckButton:getContentSize().width/2, 0, {ap = display.CENTER_BOTTOM})
    duckButton:addChild(duckImage)

    -- effect define
    local ORIGINAL_POS    = cc.p(duckButton:getPositionX() + duckButton:getContentSize().width/2, duckButton:getPositionY())
    local LEFT_DIST_MAX   = ORIGINAL_POS.x - display.SAFE_L - 150
    local RIGHT_DIST_MAX  = display.SAFE_R - ORIGINAL_POS.x - 50
    local HIGHT_DIST_MAX  = display.height * 0.8
    local FIRST_JET_SPEED = 0.006
    local createFeatherEffect = function()
        local featherPath = string.fmt('theme/summerFestival2019/feather%1.png', math.random(1,5))
        local featherNode = display.newImageView(_res(featherPath))
        ownerNode:addChild(featherNode)
        
        local isLeftDirec = math.random(100) < 50
        local distWidth   = math.random(100, isLeftDirec and LEFT_DIST_MAX or RIGHT_DIST_MAX)
        local distHeight  = math.random(100, HIGHT_DIST_MAX)
        local startPoint  = ORIGINAL_POS
        local endedPoint  = cc.p(startPoint.x + distWidth * (isLeftDirec and -1 or 1), startPoint.y + distHeight)
        local distLength  = math.sqrt(distWidth*2 + distHeight*2)
        local initJetTime = FIRST_JET_SPEED * distLength
        
        -- action: first jet
        featherNode:setPosition(startPoint)
        featherNode:setScaleX(isLeftDirec and -1 or 1)
        featherNode:setRotation(math.random(360))
        featherNode:runAction(cc.Sequence:create(
            cc.Spawn:create(
                cc.EaseCubicActionOut:create(cc.MoveTo:create(initJetTime, endedPoint)),
                cc.RotateBy:create(initJetTime, (isLeftDirec and 1 or -1) * 180)
            ),
            cc.CallFunc:create(function()
                featherNode.isFalling = true

                -- action: repeat swing
                local SWING_TIME = 1.5
                local STAY_TIME  = 0.2
                local STAY_ANGLE = 30
                local RANGE_SIZE = cc.size(200, 80)
                featherNode:runAction(cc.RepeatForever:create(cc.Sequence:create(
                    cc.Spawn:create(
                        cc.BezierBy:create(SWING_TIME, {
                            cc.p(-RANGE_SIZE.width * 0.3, -RANGE_SIZE.height),  -- start con pos
                            cc.p(-RANGE_SIZE.width * 0.7, -RANGE_SIZE.height),  -- end con pos
                            cc.p(-RANGE_SIZE.width, 0),  -- end pos
                        }),
                        cc.RotateTo:create(SWING_TIME, STAY_ANGLE)
                    ),
                    cc.DelayTime:create(STAY_TIME),
                    cc.Spawn:create(
                        cc.BezierBy:create(SWING_TIME, {
                            cc.p(RANGE_SIZE.width * 0.3, -RANGE_SIZE.height),  -- start con pos
                            cc.p(RANGE_SIZE.width * 0.7, -RANGE_SIZE.height),  -- end con pos
                            cc.p(RANGE_SIZE.width, 0),  -- end pos
                        }),
                        cc.RotateTo:create(SWING_TIME, -STAY_ANGLE)
                    ),
                    cc.DelayTime:create(STAY_TIME)
                )))

                -- fall update
                local FALL_SPEED    = -2
                local ownerNodeSize = ownerNode:getContentSize()
                local OFF_HEIGHT    = (ownerNodeSize.height - display.height) / 2
                local LIMIT_BOTTOM  = OFF_HEIGHT - RANGE_SIZE.height * 1.5
                featherNode:scheduleUpdateWithPriorityLua(function(dt)
                    local spinePosY = featherNode:getPositionY()
                    if spinePosY > LIMIT_BOTTOM then
                        featherNode:setPositionY(spinePosY + FALL_SPEED)
                    else
                        featherNode:stopAllActions()
                        featherNode:runAction(cc.RemoveSelf:create())
                    end
                end, 0)
            end)
        ))
    end


    local JUMP_HIGHT = 80  -- 跳跃高度
    local DROP_SPEED = 15  -- 掉落速度
    local SUPER_JUMP = display.height * 0.8
    
    -- duck button schedule
    duckButton:scheduleUpdateWithPriorityLua(function(dt)
        if duckImage.vt then
            duckImage.vt = duckImage.vt - DROP_SPEED
            duckImage:setPositionY(duckImage:getPositionY() + duckImage.vt)

            if checkint(duckImage:getPositionY()) <= 0 then
                duckImage:setPositionY(0)
                duckImage.vt = nil
                
                local isSuperJump = checkint(duckImage.yy) >= SUPER_JUMP
                for i = 1, isSuperJump and 12 or 1 do
                    createFeatherEffect()
                end
            end
        end
    end, 0)

    -- click duck button
    display.commonUIParams(duckButton, {cb = function(sender)
        local ostime   = socket.gettime()
        local lastTime = duckButton.clickThemeBalloonLastTime_ or 0
        if ostime - lastTime > 0.12 then
            duckImage.vt = JUMP_HIGHT
            duckImage.yy = duckImage:getPositionY()
            duckButton.clickThemeBalloonLastTime_ = ostime
        end
    end})
end


-------------------------------------------------
-- 夏日祭2020
HOME_THEME_STYLE_MAP.SUMMER_FESTIVAL_2020.EXTRA_PANEL_THEME_FUNC = function(ownerNode)
    local bubblePltPath = 'theme/summerFestival2020/bubble.plist'
    local bubblePltNode = cc.ParticleSystemQuad:create(bubblePltPath)
    local ownerNodeSize = ownerNode:getContentSize()
    bubblePltNode:setPosition(cc.p(ownerNodeSize.width/2, 300))
    ownerNode:addChild(bubblePltNode)

    -- cat button
    local catButton = display.newLayer(515, 180, {color = cc.r4b(0), size = cc.size(125, 105), enable = true})
    ownerNode:addChild(catButton)

    -- cat spine
    local catSpine = ui.spine({path = _spn('theme/summerFestival2020/2020summer'), init = 'idle'})
    catButton:addList(catSpine):alignTo(nil, ui.cb)

    -- effect define
    local SEAFOOD_ARRAY = {
        {id = 160009, scale = 0.8}, 
        {id = 160010, scale = 0.6}, 
        {id = 160064, scale = 0.6}, 
        {id = 340007, scale = 0.5}, 
        {id = 340018, scale = 0.6}
    }
    local SPINE_BEGIN_Y = ownerNode:getContentSize().height/2 - display.cy
    local createSeafoodFunc = function(sender)
        local seafoodDef = SEAFOOD_ARRAY[math.random(#SEAFOOD_ARRAY)]
        local seafoodImg = GoodsUtils.GetIconNodeById(seafoodDef.id, 0, 0, {scale = seafoodDef.scale + math.random(-10, 10)/100})
        local container  = sender:getParent()
        container:addChild(seafoodImg)

        -- init status
        local DIRECTION = math.random(100) > 50 and 1 or -1
        local RANGE_H  = display.SAFE_SIZE.height * 0.7
        local SAFE_GAP = 200
        local SAFE_W   = display.SAFE_SIZE.width - SAFE_GAP*2
        local startPos = cc.p(display.SAFE_L + SAFE_GAP + math.random(SAFE_W), SPINE_BEGIN_Y - seafoodImg:getContentSize().height)
        local endPoint = cc.p(startPos.x + math.random(100, 300) * DIRECTION, startPos.y)
        seafoodImg:setPosition(startPos)

        local seafoodSpine = ui.spine({path = _spn('effects/fishing/effect_1'), init = 'idle', cache = SpineCacheName.GLOBAL})
        seafoodSpine:setPosition(cc.p(startPos.x, SPINE_BEGIN_Y + math.random(80)))
        seafoodSpine:setScaleX(0)
        container:addChild(seafoodSpine)

        -- run action
        local DURATION   = math.random(1.5, 2.5)
        local jumpAction = cc.Sequence:create(
            cc.BezierTo:create(DURATION, {
                cc.p(startPos.x, startPos.y + RANGE_H + math.random(500)), -- start con pos
                cc.p(endPoint.x, endPoint.y + RANGE_H + math.random(500)), -- end con pos
                endPoint,  -- end pos
            }),
            cc.RemoveSelf:create()
        )
        seafoodImg:runAction(jumpAction)
        seafoodSpine:runAction(cc.Sequence:create(
            cc.EaseCubicActionOut:create(cc.ScaleTo:create(0.3, 1, 1)),
            cc.EaseCubicActionIn:create(cc.ScaleTo:create(0.3, 0, 1)),
            cc.RemoveSelf:create()
        ))
    end

    -- click magicHat button
    catButton:setOnClickScriptHandler(function(sender)
        local ostime   = socket.gettime()
        local lastTime = sender.clickThemeBalloonLastTime_ or 0
        if ostime - lastTime > 0.2 then
            createSeafoodFunc(sender)
            sender.clickThemeBalloonLastTime_ = ostime
        end
    end)
end


-------------------------------------------------
-- 日本周年庆2019（播烟花spine）
HOME_THEME_STYLE_MAP.JP_ANNIVERSARY_2019.EXTRA_PANEL_THEME_FUNC = function(ownerNode)
    -- fireworks button
    local fireworksSize = cc.size(125, 105)
    local fireworksPos  = cc.p(515, 180)
    local fireworksBtn  = display.newLayer(fireworksPos.x, fireworksPos.y, {color = cc.r4b(0), size = fireworksSize, enable = true})
    ownerNode:addChild(fireworksBtn)

    local fireworksSpnPath = _spn('theme/jpAnniversary2019/yanhua')
    local fireworksSpnNode = sp.SkeletonAnimation:create(fireworksSpnPath.json, fireworksSpnPath.atlas, 1.0)
    fireworksSpnNode:setPosition(cc.p(fireworksPos.x + fireworksSize.width - 40, fireworksPos.y + fireworksSize.height - 40))
    fireworksSpnNode:setAnimation(0, 'idle', false)
    ownerNode:addChild(fireworksSpnNode)

    -- click duck button
    display.commonUIParams(fireworksBtn, {cb = function(sender)
        local ostime   = socket.gettime()
        local lastTime = fireworksBtn.clickThemeBalloonLastTime_ or 0
        if ostime - lastTime > 0.2 then
            local isOpenFire = math.random(100) >= 75
            if isOpenFire then
                fireworksBtn.clickThemeBalloonLastTime_ = ostime + 2
                fireworksSpnNode:setAnimation(0, 'play', false)
            else
                fireworksBtn.clickThemeBalloonLastTime_ = ostime + 1
                fireworksSpnNode:setAnimation(0, 'idle', false)
            end
            fireworksSpnNode:setToSetupPose()
            fireworksSpnNode:update(0)
        end
    end})
end


-------------------------------------------------
-- 日本周年庆2020（枫叶spine + 猫咪spine）
HOME_THEME_STYLE_MAP.JP_ANNIVERSARY_2020.EXTRA_PANEL_THEME_FUNC = function(ownerNode)
    local ownerNodeSize = ownerNode:getContentSize()

    local catSpnSize = cc.size(125, 105)
    local catSpnPos  = cc.p(515, 180)
    local catSpnBtn  = ui.layer({p = catSpnPos, color = cc.r4b(0), size = catSpnSize, enable = true})
    ownerNode:addChild(catSpnBtn)
    
    local catSpnNode = ui.spine({path = _spn('theme/jpAnniversary2020/cat'), init = 'idle'})
    catSpnNode:setPosition(cc.p(catSpnPos.x + catSpnSize.width - 60, catSpnPos.y + catSpnSize.height - 70))
    ownerNode:addChild(catSpnNode)
    
    local leafSpnNode = ui.spine({path = _spn('theme/jpAnniversary2020/leaf'), init = 'idle'})
    leafSpnNode:setPosition(cc.p(ownerNodeSize.width/2, ownerNodeSize.height/2))
    ownerNode:addChild(leafSpnNode)
end


-------------------------------------------------
-- 国庆2019（播烟花spine）
HOME_THEME_STYLE_MAP.NATIONAL_DAY_2019.EXTRA_PANEL_THEME_FUNC = HOME_THEME_STYLE_MAP.JP_ANNIVERSARY_2019.EXTRA_PANEL_THEME_FUNC


-------------------------------------------------
-- 春日祭2020
HOME_THEME_STYLE_MAP.SPRINGTIME_2020.EXTRA_PANEL_THEME_FUNC = function(ownerNode)
    local ownerNodeSize = ownerNode:getContentSize()

    -- cat spine
    local catSpineNode = display.newPathSpine(_spn('theme/springtime2020/2020spring'))
    catSpineNode:setPosition(cc.p(1080, ownerNodeSize.height - 502))
    catSpineNode:setAnimation(0, 'idle', true)
    ownerNode:addChild(catSpineNode)
end
