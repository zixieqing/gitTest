--[[
 * author : kaishiqi
 * descpt : 工会战 - 主界面场景
]]
local CommonBattleButton = require('common.CommonBattleButton')
local UnionWarsStateNode = require('Game.views.unionWars.UnionWarsHomeStateNode')
local UnionWarsMapLayer  = require('Game.views.unionWars.UnionWarsMapLayer')
local UnionWarsHomeScene = class('UnionWarsHomeScene', require('Frame.GameScene'))

local RES_DICT = {
    -- top
    TOP_BAR_BG     = _res('ui/union/wars/home/gvg_titile_bg_me.png'),
    BTN_BACK       = _res('ui/common/common_btn_back.png'),
    BTN_TIPS       = _res('ui/common/common_btn_tips.png'),
    UNION_NAME_BAR = _res('ui/union/wars/home/gvg_guild_name_bg_black.png'),
    CHEST_IMAGE    = _res(string.fmt('arts/goods/goods_icon_%1.png', 191005)),
    -- func
    ICON_NAME_BAR  = _res('ui/union/lobby/guild_icon_name_bg.png'),
    BTN_UNION      = _res('ui/union/wars/home/gvg_btn_back.png'),
    BTN_APPLY      = _res('ui/union/wars/home/gvg_btn_check.png'),
    BTN_DEFEND     = _res('ui/union/wars/home/gvg_btn_enroll.png'),
    BTN_REPORT     = _res('ui/union/wars/home/gvg_btn_warreport.png'),
    FUNC_INFO_BAR  = _res('ui/union/wars/home/gvg_function_bg_btn.png'),
    -- enemy
    ENEMY_INFO_BAR = _res('ui/union/wars/home/gvg_attack_state_bg.png'),
    ENEMY_TIME_BAR = _res('ui/union/wars/home/gvg_attack_state_time_bg.png'),
    -- map
    BTN_SHOP        = _res('ui/union/wars/home/gvg_icon_shop.png'),
    SITE_INFO_BAR   = _res('ui/union/wars/home/gvg_defense_number_bg.png'),
    -- other
    MAP_CAMP_SWITCH  = _spn('ui/union/wars/home/management'),  -- idle, play
    ENEMY_MATCHED    = _spn('ui/union/wars/home/gvg_matching'),  -- idle, play
    UNION_ICON_FRAME = _res('ui/union/guild_head_frame_default.png'),
}

local CreateView      = nil
local CreateUILayer   = nil
local CreateFuncBtn   = nil
local CreateMatchView = nil


function UnionWarsHomeScene:ctor()
    self.super.ctor(self, 'Game.views.unionWars.UnionWarsHomeScene')

    -- create views
    self.viewData_ = CreateView()
    self:AddGameLayer(self.viewData_.view)
    
    self.warsMapLayer_ = UnionWarsMapLayer.new()
    self:AddGameLayer(self.warsMapLayer_)

    self.uiViewData_ = CreateUILayer()
    self:AddUILayer(self.uiViewData_.view)

    self.matchViewData_ = CreateMatchView()
    self:AddUILayer(self.matchViewData_.view)
    self:hideMatchView()

    -- init views
    self:getUIViewData().topLayer:setPosition(cc.p(0, 150))
    self:getUIViewData().funcLayer:setPosition(cc.p(0, -150))
    self:getUIViewData().enemyLayer:setPosition(cc.p(0, -150))
    self:getUIViewData().mapLeftLayer:setPosition(cc.p(-200 - display.SAFE_L, 0))
    self:getUIViewData().mapRightLayer:setPosition(cc.p(200 + display.SAFE_L, 0))
end


CreateView = function()
    local view = display.newLayer()
    local size = view:getContentSize()

    return {
        view = view,
    }
end


CreateFuncBtn = function(x, y, img, name)
    local funcBtn = display.newButton(checkint(x), checkint(y), {n = tostring(img)})
    local btnSize = funcBtn:getContentSize()
    local nameBar = display.newButton(btnSize.width/2, btnSize.height/2 - 45, {n = RES_DICT.ICON_NAME_BAR, enable = false})
    display.commonLabelParams(nameBar, fontWithColor(19, {fontSize = 22, text = checkstr(name), paddingW = 15}))
    funcBtn:addChild(nameBar)
    return funcBtn, nameBar
end


CreateUILayer = function()
    local view = display.newLayer()
    local size = view:getContentSize()

    -------------------------------------------------
    -- top info
    local topLayer = display.newLayer()
    view:add(topLayer)

    topLayer:addChild(display.newImageView(RES_DICT.TOP_BAR_BG, size.width/2, size.height, {ap = display.CENTER_TOP}))

    -- back button
    local backBtn = display.newButton(display.SAFE_L + 75, size.height - 45, {n = RES_DICT.BTN_BACK})
    topLayer:addChild(backBtn)


    -- union infoBar
    local unionInfoBar  = display.newButton(backBtn:getPositionX() + 65, backBtn:getPositionY(), {n = RES_DICT.UNION_NAME_BAR, ap = display.LEFT_CENTER})
    local unionInfoSize = unionInfoBar:getContentSize()
    topLayer:addChild(unionInfoBar)

    -- unionIcon layer
    local unionIconLayer = display.newLayer(40, unionInfoSize.height/2 - 1)
    unionIconLayer:setScale(0.55)
    unionInfoBar:addChild(unionIconLayer)
    
    -- unionName label
    local unionNameLabel = display.newLabel(unionIconLayer:getPositionX() + 65, unionInfoSize.height/2, fontWithColor(3, {fontSize = 26, ap = display.LEFT_CENTER}))
    unionInfoBar:addChild(unionNameLabel)

    -- uninWars tips
    unionInfoBar:addChild(display.newImageView(RES_DICT.BTN_TIPS, unionInfoSize.width - 50, unionInfoSize.height/2))

    
    -- rewards button
    local rewardsBtn = display.newButton(size.width/2 - 15, unionInfoBar:getPositionY(), {n = RES_DICT.CHEST_IMAGE})
    display.commonLabelParams(rewardsBtn, fontWithColor(20, {fontSize = 32, text = __('奖励预览'), offset = cc.p(0,-50)}))
    rewardsBtn:setScale(0.58)
    topLayer:addChild(rewardsBtn)

    -- state node
    local stateNode = UnionWarsStateNode.new({x = display.SAFE_R - 3, y = size.height - 3, ap = display.RIGHT_TOP})
    topLayer:addChild(stateNode)


    -------------------------------------------------
    -- func info
    local funcLayer = display.newLayer()
    view:add(funcLayer)

    funcLayer:addChild(display.newImageView(RES_DICT.FUNC_INFO_BAR, 0, 20, {ap = display.LEFT_BOTTOM}))

    -- report button
    local reportBtn = CreateFuncBtn(display.SAFE_L + 90, 90, RES_DICT.BTN_REPORT, __('竞赛记录'))
    funcLayer:addChild(reportBtn)

    -- apply button
    local applyBtn = CreateFuncBtn(reportBtn:getPositionX() + 140, reportBtn:getPositionY(), RES_DICT.BTN_APPLY, __('报名成员'))
    funcLayer:addChild(applyBtn)

    -- defend button
    local defendBtn = CreateFuncBtn(applyBtn:getPositionX() + 140, reportBtn:getPositionY(), RES_DICT.BTN_DEFEND, __('防御编队'))
    funcLayer:addChild(defendBtn)

    -- union button
    local unionBtn = CreateFuncBtn(applyBtn:getPositionX(), applyBtn:getPositionY(), RES_DICT.BTN_UNION, __('返回工会'))
    funcLayer:addChild(unionBtn)


    -------------------------------------------------
    -- enemy info
    local enemyLayer = display.newLayer()
    view:add(enemyLayer)

    -- battle button
    local battleBtn = CommonBattleButton.new()
    battleBtn:setPosition(cc.p(display.SAFE_R - 75, 75))
    -- battleBtn:setEnabled(false)
    battleBtn:setScale(0.75)
    enemyLayer:addChild(battleBtn, 1)
    
    enemyLayer:addChild(display.newImageView(RES_DICT.ENEMY_INFO_BAR, battleBtn:getPositionX(), battleBtn:getPositionY(), {ap = display.RIGHT_CENTER}))

    -- battle time image
    local battleTimeImg = display.newImageView(RES_DICT.ENEMY_TIME_BAR, battleBtn:getPositionX() - 230, battleBtn:getPositionY() - 40)
    enemyLayer:addChild(battleTimeImg)

    -- battle time label
    local battleTimeLabel = display.newLabel(battleTimeImg:getPositionX(), battleTimeImg:getPositionY(), fontWithColor(10, {ap = display.LEFT_CENTER}))
    enemyLayer:addChild(battleTimeLabel)

    -- battle state label
    local battleStateLabel = display.newLabel(battleTimeImg:getPositionX(), battleTimeImg:getPositionY(), fontWithColor(16, {ap = display.LEFT_CENTER, text = __('进攻开始')}))
    enemyLayer:addChild(battleStateLabel)

    -- enemy name label
    local enemyNameLabel = display.newLabel(battleTimeImg:getPositionX(), battleBtn:getPositionY() - 6, fontWithColor(19, {fontSize = 22, color = '#FFB24D'}))
    enemyLayer:addChild(enemyNameLabel)
    enemyLayer:addChild(display.newLabel(battleTimeImg:getPositionX(), battleBtn:getPositionY() + 22, fontWithColor(18, {fontSize = 20, text = __('本场对手')})))

    
    -------------------------------------------------
    -- map info
    local mapLayer = display.newLayer()
    view:add(mapLayer)

    local mapLeftLayer = display.newLayer()
    mapLayer:addChild(mapLeftLayer)

    local mapRightLayer = display.newLayer()
    mapLayer:addChild(mapRightLayer)

    -- shop button
    local shopBtn = CreateFuncBtn(display.SAFE_R - 75, size.height - 160, RES_DICT.BTN_SHOP, __('竞赛商店'))
    mapRightLayer:addChild(shopBtn)
    
    -- siteInfo layer
    local siteInfoLayer = display.newLayer()
    mapLeftLayer:addChild(siteInfoLayer)
    
    local siteInfoSize = cc.size(240 + display.SAFE_L, 78)
    local siteInfoImg  = display.newImageView(RES_DICT.SITE_INFO_BAR, 0, size.height - 140, {ap = display.LEFT_CENTER, scale9 = true, size = siteInfoSize})
    siteInfoLayer:addChild(siteInfoImg)
    
    -- site num label
    local siteNumLabel = display.newLabel(display.SAFE_L/2 + siteInfoSize.width/2 - 30, siteInfoImg:getPositionY() - 7, fontWithColor(14, {fontSize = 22, color = '#FFCE49'}))
    siteInfoLayer:addChild(siteNumLabel)
    siteInfoLayer:addChild(display.newLabel(siteNumLabel:getPositionX(), siteInfoImg:getPositionY() + 17, fontWithColor(2, {fontSize = 20, color = '#FFFFFF', text = __('剩余据点')})))
    

    return {
        view             = view,
        topLayer         = topLayer,
        backBtn          = backBtn,
        unionInfoBar     = unionInfoBar,
        unionIconLayer   = unionIconLayer,
        unionNameLabel   = unionNameLabel,
        rewardsBtn       = rewardsBtn,
        stateNode        = stateNode,
        funcLayer        = funcLayer,
        reportBtn        = reportBtn,
        applyBtn         = applyBtn,
        defendBtn        = defendBtn,
        unionBtn         = unionBtn,
        enemyLayer       = enemyLayer,
        battleBtn        = battleBtn,
        battleTimeImg    = battleTimeImg,
        battleTimeLabel  = battleTimeLabel,
        battleStateLabel = battleStateLabel,
        battleTimeGapX   = 10,
        enemyNameLabel   = enemyNameLabel,
        mapLayer         = mapLayer,
        mapLeftLayer     = mapLeftLayer,
        mapRightLayer    = mapRightLayer,
        shopBtn          = shopBtn,
        siteInfoLayer    = siteInfoLayer,
        siteNumLabel     = siteNumLabel,
    }
end


CreateMatchView = function()
    local view = display.newLayer()
    local size = view:getContentSize()

    -- block layer
    local blockLayer = display.newLayer(0,0, {color = cc.c4b(0,0,0,150), enable = true})
    view:addChild(blockLayer)

    -- add spine cache
    local effectSpinePath = RES_DICT.ENEMY_MATCHED.path
    if not SpineCache(SpineCacheName.UNION):hasSpineCacheData(effectSpinePath) then
        SpineCache(SpineCacheName.UNION):addCacheData(effectSpinePath, effectSpinePath, 1)
    end

    -- create effect spine
    local effectSpine = SpineCache(SpineCacheName.UNION):createWithName(effectSpinePath)
    effectSpine:setPosition(cc.p(size.width/2, size.height/2))
    view:addChild(effectSpine)

    -------------------------------------------------
    -- mine info layer
    local mineInfoPos   = cc.p(size.width/2 - 200, size.height/2)
    local mineInfoLayer = display.newLayer(mineInfoPos.x, mineInfoPos.y)
    view:addChild(mineInfoLayer)

    -- mine unionIcon frame
    local mineUnionIconFrame = display.newImageView(RES_DICT.UNION_ICON_FRAME, 0, 28, {scale = 0.77})
    mineInfoLayer:addChild(mineUnionIconFrame)

    -- mine unionIcon layer
    local mineUnionIconLayer = display.newLayer(mineUnionIconFrame:getPositionX(), mineUnionIconFrame:getPositionY())
    mineUnionIconLayer:setScale(0.75)
    mineInfoLayer:addChild(mineUnionIconLayer)
    
    -- mine unionName label
    local mineUnionNameLabel = display.newLabel(0, -50, fontWithColor(14, {fontSize = 26, color = '#FFF3e3'}))
    mineInfoLayer:addChild(mineUnionNameLabel)

    -------------------------------------------------
    -- enemy info layer
    local enemyInfoPos   = cc.p(size.width/2 + 200, size.height/2)
    local enemyInfoLayer = display.newLayer(enemyInfoPos.x, enemyInfoPos.y)
    view:addChild(enemyInfoLayer)

    -- enemy unionIcon frame
    local enemyUnionIconFrame = display.newImageView(RES_DICT.UNION_ICON_FRAME, 0, mineUnionIconLayer:getPositionY(), {scale = 0.77})
    enemyInfoLayer:addChild(enemyUnionIconFrame)

    -- enemy unionIcon layer
    local enemyUnionIconLayer = display.newLayer(enemyUnionIconFrame:getPositionX(), enemyUnionIconFrame:getPositionY())
    enemyUnionIconLayer:setScale(0.75)
    enemyInfoLayer:addChild(enemyUnionIconLayer)
    
    -- enemy unionName label
    local enemyUnionNameLabel = display.newLabel(0, mineUnionNameLabel:getPositionY(), fontWithColor(14, {fontSize = 26, color = '#FFF3e3'}))
    enemyInfoLayer:addChild(enemyUnionNameLabel)

    -------------------------------------------------
    -- matching label
    local matchingLabel = display.newLabel(enemyInfoPos.x, enemyInfoPos.y + 20, fontWithColor(2, {color = '#FFFFFFF', text = __('匹配对手中…')}))
    view:addChild(matchingLabel)

    -- animation define
    local SHOW_ANIMATION_NAME = 'idle'
    local HIDE_ANIMATION_NAME = 'play'
    local INFO_ACTION_TIME    = 0.3
    local MATHED_DELAY_TIME   = 1
    local animationData = {
        isMatchingRun      = false,
        isMatchingShow     = false,
        isMatchedRun       = false,
        isMatchedShow      = false,
        matchingFinishCB   = nil,
    }

    local showMatchingFunc = function()
        animationData.isMatchingRun  = true
        animationData.isMatchingShow = false
        matchingLabel:setOpacity(0)
        mineInfoLayer:setOpacity(0)
        enemyInfoLayer:setOpacity(0)
        effectSpine:setAnimation(0, SHOW_ANIMATION_NAME, false)
    end

    local showMatchedFunc = function()
        animationData.isMatchedRun  = true
        animationData.isMatchedShow = false
        view:runAction(cc.Sequence:create(
            cc.Spawn:create(
                cc.TargetedAction:create(matchingLabel, cc.FadeOut:create(INFO_ACTION_TIME)),
                cc.TargetedAction:create(enemyInfoLayer, cc.FadeIn:create(INFO_ACTION_TIME))
            ),
            cc.DelayTime:create(MATHED_DELAY_TIME),
            cc.CallFunc:create(function()
                effectSpine:setAnimation(0, HIDE_ANIMATION_NAME, false)
            end),
            cc.Spawn:create(
                cc.TargetedAction:create(mineInfoLayer, cc.FadeOut:create(INFO_ACTION_TIME)),
                cc.TargetedAction:create(enemyInfoLayer, cc.FadeOut:create(INFO_ACTION_TIME))
            )
        ))
    end

    local resetAnimationFunc = function()
        view:setVisible(false)
        view:stopAllActions()
        animationData.matchingFinishCB = nil
        animationData.isMatchingRun    = false
        animationData.isMatchingShow   = false
        animationData.isMatchedRun     = false
        animationData.isMatchedShow    = false
    end

    effectSpine:registerSpineEventHandler(function(event)
        if event.animation == SHOW_ANIMATION_NAME then
            view:runAction(cc.Sequence:create(
                cc.Spawn:create(
                    cc.TargetedAction:create(matchingLabel, cc.FadeIn:create(INFO_ACTION_TIME)),
                    cc.TargetedAction:create(mineInfoLayer, cc.FadeIn:create(INFO_ACTION_TIME))
                ),
                cc.CallFunc:create(function()
                    animationData.isMatchingShow = true
                    if animationData.matchingFinishCB then animationData.matchingFinishCB() end
                end)
            ))

        elseif event.animation == HIDE_ANIMATION_NAME then
            resetAnimationFunc()
        end
    end, sp.EventType.ANIMATION_COMPLETE)

    return {
        view                = view,
        blockLayer          = blockLayer,
        mineInfoLayer       = mineInfoLayer,
        mineUnionIconLayer  = mineUnionIconLayer,
        mineUnionNameLabel  = mineUnionNameLabel,
        enemyInfoLayer      = enemyInfoLayer,
        enemyUnionIconLayer = enemyUnionIconLayer,
        enemyUnionNameLabel = enemyUnionNameLabel,
        matchingLabel       = matchingLabel,
        animationData       = animationData,
        showMatchingFunc    = showMatchingFunc,
        showMatchedFunc     = showMatchedFunc,
        resetAnimationFunc  = resetAnimationFunc,
    }
end


-------------------------------------------------
-- get / set

function UnionWarsHomeScene:getViewData()
    return self.viewData_
end


function UnionWarsHomeScene:getUIViewData()
    return self.uiViewData_
end


function UnionWarsHomeScene:getMatchViewData()
    return self.matchViewData_
end


function UnionWarsHomeScene:getMapLayer()
    return self.warsMapLayer_
end


function UnionWarsHomeScene:getMapViewData()
    return self:getMapLayer():getViewData()
end


-------------------------------------------------
-- public

function UnionWarsHomeScene:createSwitchCampMapEffect(closeCB)
    local view = display.newLayer(0, 0, {color = cc.r4b(0), enable = true})
    self:AddDialog(view)
    
    -- add spine cache
    local effectSpinePath = RES_DICT.MAP_CAMP_SWITCH.path
    if not SpineCache(SpineCacheName.UNION):hasSpineCacheData(effectSpinePath) then
        SpineCache(SpineCacheName.UNION):addCacheData(effectSpinePath, effectSpinePath, 1)
    end

    -- create effect spine
    local effectSpine = SpineCache(SpineCacheName.UNION):createWithName(effectSpinePath)
    effectSpine:setPosition(display.center)
    view:addChild(effectSpine)

    -- play spine 
    local CLOSE_ANIMATION_NAME = 'idle'
    local OPEN_ANIMATION_NAME  = 'play'
    effectSpine:registerSpineEventHandler(function(event)
        if event.animation == CLOSE_ANIMATION_NAME then
            if closeCB then closeCB() end
            effectSpine:setAnimation(0, OPEN_ANIMATION_NAME, false)

        elseif event.animation == OPEN_ANIMATION_NAME then
            view:runAction(cc.RemoveSelf:create())
        end
    end, sp.EventType.ANIMATION_COMPLETE)
    effectSpine:setAnimation(0, CLOSE_ANIMATION_NAME, false)
end


function UnionWarsHomeScene:isShowingMatchView()
    return self:getMatchViewData().view:isVisible() == true
end
function UnionWarsHomeScene:showMatchView(mineUnionData, enemyUnionData)
    local mineUnionInfoData  = mineUnionData
    local enemyUnionInfoData = enemyUnionData

    self:getMatchViewData().view:setVisible(true)
    self:getMatchViewData().blockLayer:setVisible(enemyUnionInfoData ~= nli)

    -- update mine union info
    if mineUnionInfoData then
        display.commonLabelParams(self:getMatchViewData().mineUnionNameLabel, {text = checkstr(mineUnionInfoData.unionName)})
        self:getMatchViewData().mineUnionIconLayer:removeAllChildren()

        if checkint(mineUnionInfoData.unionAvatar) > 0 then
            local avatarImg = display.newImageView(_res(CommonUtils.GetGoodsIconPathById(mineUnionInfoData.unionAvatar)))
            self:getMatchViewData().mineUnionIconLayer:addChild(avatarImg)
        end
    end

    -- update enemy union info
    if enemyUnionInfoData then
        display.commonLabelParams(self:getMatchViewData().enemyUnionNameLabel, {text = checkstr(enemyUnionInfoData.unionName)})
        self:getMatchViewData().enemyUnionIconLayer:removeAllChildren()

        if checkint(enemyUnionInfoData.unionAvatar) > 0 then
            local avatarImg = display.newImageView(_res(CommonUtils.GetGoodsIconPathById(enemyUnionInfoData.unionAvatar)))
            self:getMatchViewData().enemyUnionIconLayer:addChild(avatarImg)
        end
    end

    -- run showMatch animation
    local animationData = self:getMatchViewData().animationData
    if enemyUnionInfoData then
        if animationData.isMatchingShow then
            if not animationData.isMatchedRun and not animationData.isMatchedShow then
                self:getMatchViewData():showMatchedFunc()
            end

        elseif animationData.isMatchingRun then
            animationData.matchingFinishCB = function()
                self:getMatchViewData():showMatchedFunc()
                animationData.matchingFinishCB = nil
            end
        else
            if not animationData.isMatchingRun_ and not animationData.isMatchingShow then
                self:getMatchViewData():showMatchingFunc()
                animationData.matchingFinishCB = function()
                    self:getMatchViewData():showMatchedFunc()
                    animationData.matchingFinishCB = nil
                end
            end
        end
    else
        if not animationData.isMatchingRun and not animationData.isMatchingShow then
            self:getMatchViewData():showMatchingFunc()
        end
    end
end
function UnionWarsHomeScene:hideMatchView()
    self:getMatchViewData().resetAnimationFunc()
end


function UnionWarsHomeScene:showUI(endCB)
    local showTime = 0.3
    self:runAction(cc.Sequence:create(
        cc.Spawn:create(
            cc.TargetedAction:create(self:getUIViewData().topLayer, cc.MoveTo:create(showTime, PointZero)),
            cc.TargetedAction:create(self:getUIViewData().funcLayer, cc.MoveTo:create(showTime, PointZero)),
            cc.TargetedAction:create(self:getUIViewData().enemyLayer, cc.MoveTo:create(showTime, PointZero)),
            cc.TargetedAction:create(self:getUIViewData().mapLeftLayer, cc.MoveTo:create(showTime, PointZero)),
            cc.TargetedAction:create(self:getUIViewData().mapRightLayer, cc.MoveTo:create(showTime, PointZero))
        ),
        cc.CallFunc:create(function()
            if endCB then endCB() end
        end)
    ))
end


function UnionWarsHomeScene:updateAppliedState(isApplied)
    self.isApplied_ = isApplied == true
    self:updateViewState_()
end


function UnionWarsHomeScene:updateWatchCampState(isWatchEnemy)
    self.isWatchEnemy_ = isWatchEnemy == true
    self:getMapLayer():updateMapBgCampState(self.isWatchEnemy_)
    self:updateViewState_()
end


---@see UNION_WARS_STEPS
function UnionWarsHomeScene:updateWarsStepState(unionWarsStep)
    self.warsStepId_ = checkint(unionWarsStep)
    self:updateViewState_()
end


function UnionWarsHomeScene:updateTitleInfo(titleData)
    local titleInfoData = checktable(titleData)
    display.commonLabelParams(self:getUIViewData().unionNameLabel, {text = checkstr(titleInfoData.unionName)})
    self:getUIViewData().unionIconLayer:removeAllChildren()

    if checkint(titleInfoData.unionAvatar) > 0 then
        local avatarImg = display.newImageView(_res(CommonUtils.GetGoodsIconPathById(titleInfoData.unionAvatar)))
        self:getUIViewData().unionIconLayer:addChild(avatarImg)
    end
end


function UnionWarsHomeScene:updateEnemyInfo(enemyData)
    local enemyInfoData = checktable(enemyData)
    display.commonLabelParams(self:getUIViewData().enemyNameLabel, {text = checkstr(enemyInfoData.enemyName)})
end


function UnionWarsHomeScene:isVisibleEnemyLayer()
    return self:getUIViewData().enemyLayer:isVisible() == true
end
function UnionWarsHomeScene:updateBattleTime(time)
    local timeStr = checkint(time) > 0 and CommonUtils.getTimeFormatByType(time, 3) or '--:--:--'
    display.commonLabelParams(self:getUIViewData().battleTimeLabel, {text = timeStr})
    
    local TIME_INFO_GAP_X = self:getUIViewData().battleTimeGapX
    local infoContainerW  = self:getUIViewData().battleTimeImg:getContentSize().width
    local stateLabelSize  = display.getLabelContentSize(self:getUIViewData().battleStateLabel)
    local timeLabelSize   = display.getLabelContentSize(self:getUIViewData().battleTimeLabel)
    local infoLabelWidth  = stateLabelSize.width + timeLabelSize.width + TIME_INFO_GAP_X
    local infoLabelInitX  = self:getUIViewData().battleTimeImg:getPositionX() - infoContainerW/2
    local infoLabelOffX   = infoLabelInitX + (infoContainerW - infoLabelWidth) / 2
    self:getUIViewData().battleStateLabel:setPositionX(infoLabelOffX)
    self:getUIViewData().battleTimeLabel:setPositionX(infoLabelOffX + stateLabelSize.width + TIME_INFO_GAP_X)
end


function UnionWarsHomeScene:updateStateNodeTime(time)
    self:getUIViewData().stateNode:setStateTime(time)
end


function UnionWarsHomeScene:updateSiteProgress(siteProgressData)
    local progressData = checktable(siteProgressData)
    local memberNum    = checkint(progressData.memberNum)
    local detroyNum    = checkint(progressData.detroyNum)
    local allTotalHP   = checkint(progressData.allTotalHP)
    local allMemberHP  = checkint(progressData.allMemberHP)
    display.commonLabelParams(self:getUIViewData().siteNumLabel, {text = string.fmt('%1 / %2', memberNum - detroyNum, memberNum)})
    self:getUIViewData().stateNode:setHpProgress(allMemberHP, allTotalHP)
end


-------------------------------------------------
-- private

function UnionWarsHomeScene:updateViewState_()
    local isApplied   = self.isApplied_ == true
    local isViewEnemy = self.isWatchEnemy_ == true
    local wardStepId  = checkint(self.warsStepId_)

    self:getUIViewData().stateNode:setShowHP(false)
    self:getUIViewData().funcLayer:setVisible(true)
    self:getUIViewData().defendBtn:setVisible(false)
    self:getUIViewData().unionBtn:setVisible(isViewEnemy)
    self:getUIViewData().applyBtn:setVisible(not isViewEnemy)
    
    -- 准备阶段（成员编防）
    if UNION_WARS_STEPS.READY == wardStepId then
        self:getUIViewData().stateNode:setStateTitle(__('成员报名'))
        self:getUIViewData().defendBtn:setVisible(not isViewEnemy)
        self:getUIViewData().enemyLayer:setVisible(false)
        self:getUIViewData().siteInfoLayer:setVisible(false)


    -- 报名阶段（会长报名）
    elseif UNION_WARS_STEPS.APPLY == wardStepId then
        self:getUIViewData().stateNode:setStateTitle(__('竞赛报名'))
        self:getUIViewData().enemyLayer:setVisible(false)
        self:getUIViewData().siteInfoLayer:setVisible(isApplied)


    -- 匹配阶段（公会匹配）    
    elseif UNION_WARS_STEPS.MATCH == wardStepId then
        self:getUIViewData().stateNode:setStateTitle(isApplied and __('匹配中') or __('待开放'))
        self:getUIViewData().enemyLayer:setVisible(false)
        self:getUIViewData().siteInfoLayer:setVisible(isApplied)
        self:getUIViewData().funcLayer:setVisible(isApplied)


    -- 战斗阶段（比赛时间）
    elseif UNION_WARS_STEPS.FIGHTING == wardStepId then
        self:getUIViewData().stateNode:setStateTitle(isApplied and __('竞赛中') or __('待开放'))
        self:getUIViewData().stateNode:setShowHP(isApplied, isViewEnemy)
        self:getUIViewData().enemyLayer:setVisible(not isViewEnemy and isApplied)
        self:getUIViewData().siteInfoLayer:setVisible(isApplied)
        self:getUIViewData().funcLayer:setVisible(isApplied)


    -- 休赛阶段（等待下场）
    elseif UNION_WARS_STEPS.BREAK == wardStepId then
        self:getUIViewData().stateNode:setStateTitle(isApplied and __('休赛中') or __('待开放'))
        self:getUIViewData().applyBtn:setVisible(false)
        self:getUIViewData().enemyLayer:setVisible(false)
        self:getUIViewData().siteInfoLayer:setVisible(false)
        self:getUIViewData().funcLayer:setVisible(isApplied)
        
        
    -- 未开放
    else
        self:getUIViewData().stateNode:setStateTitle(__('待开放'))
        self:getUIViewData().applyBtn:setVisible(false)
        self:getUIViewData().funcLayer:setVisible(false)
        self:getUIViewData().enemyLayer:setVisible(false)
        self:getUIViewData().siteInfoLayer:setVisible(false)
    end
end


return UnionWarsHomeScene
