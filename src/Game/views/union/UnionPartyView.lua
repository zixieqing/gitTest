--[[
 * author : kaishiqi
 * descpt : 工会派对视图
]]
local UnionConfigParser = require('Game.Datas.Parser.UnionConfigParser')
local UnionPartyView    = class('UnionPartyView', function()
    return display.newLayer(0, 0, {name = 'Game.views.union.UnionPartyView'})
end)

local RES_DICT = {
    PROGRESS_BAR_D  = 'ui/union/party/party/guild_hunt_bg_blood.png',
    PROGRESS_BAR_S  = 'ui/union/party/party/guild_hunt_bg_loading_blood.png',
    TOP_INFO_FRAME  = 'ui/union/party/party/guild_party_bg_title_progress.png',
    TOP_ICON_FOOD_S = 'ui/union/party/party/guild_party_ico_eat_food_active.png',
    TOP_ICON_FOOD_N = 'ui/union/party/party/guild_party_ico_eat_food_default.png',
    TOP_ICON_BOSS_S = 'ui/union/party/party/guild_party_ico_master_active.png',
    TOP_ICON_BOSS_N = 'ui/union/party/party/guild_party_ico_master.png',
    LEFT_INFO_FRAME = 'ui/union/party/party/guild_party_bg_eat_food_stat.png',
    LEFT_TIME_FRAME = 'ui/union/party/party/guild_party_bg_eat_food_time.png',
    -------------------------------------------------
    SWITCH_DOOR = 'avatar/ui/restaurant_anime_door.png',
    ROUND_FRAME = 'ui/union/party/party/battle_bg_switch.png',
    ROUND_IMG_1 = 'ui/union/party/party/battle_ico_switch_1.png',
    ROUND_IMG_2 = 'ui/union/party/party/battle_ico_switch_2.png',
    ROUND_TITLE = 'ui/union/party/party/battle_bg_switch_word.png',
}

local CreateView      = nil
local CreateRoundView = nil


function UnionPartyView:ctor(args)
    -- create view
    self.viewData_ = CreateView()
    self:addChild(self.viewData_.view)
end


CreateView = function()
    local view = display.newLayer()
    local size = view:getContentSize()

    -------------------------------------------------
    -- top layer
    local topLayer = display.newLayer()
    view:addChild(topLayer)

    local topInfoPos = cc.p(display.SAFE_L + 400, display.height)
    topLayer:addChild(display.newImageView(_res(RES_DICT.TOP_INFO_FRAME), topInfoPos.x, topInfoPos.y, {ap = display.CENTER_TOP}))

    local partyNameLabel = display.newLabel(topInfoPos.x, topInfoPos.y - 38, fontWithColor(19))
    topLayer:addChild(partyNameLabel)

    local roundProgressPos = cc.p(topInfoPos.x - 80, topInfoPos.y - 90)
    local roundProgressBar = CProgressBar:create(_res(RES_DICT.PROGRESS_BAR_S))
    roundProgressBar:setBackgroundImage(_res(RES_DICT.PROGRESS_BAR_D))
    roundProgressBar:setDirection(eProgressBarDirectionLeftToRight)
    roundProgressBar:setAnchorPoint(display.LEFT_CENTER)
    roundProgressBar:setPosition(roundProgressPos)
    roundProgressBar:setMaxValue(100)
    roundProgressBar:setValue(0)
    topLayer:addChild(roundProgressBar)

    local roundProgressBarW  = roundProgressBar:getContentSize().width
    local prevFoodNormalImg  = display.newImageView(_res(RES_DICT.TOP_ICON_FOOD_N), roundProgressPos.x + roundProgressBarW*0, roundProgressPos.y)
    local prevFoodSelectImg  = display.newImageView(_res(RES_DICT.TOP_ICON_FOOD_S), roundProgressPos.x + roundProgressBarW*0, roundProgressPos.y)
    local lastFoodNormalImg  = display.newImageView(_res(RES_DICT.TOP_ICON_FOOD_N), roundProgressPos.x + roundProgressBarW*1, roundProgressPos.y)
    local lastFoodSelectImg  = display.newImageView(_res(RES_DICT.TOP_ICON_FOOD_S), roundProgressPos.x + roundProgressBarW*1, roundProgressPos.y)
    local boosQuestNormalImg = display.newImageView(_res(RES_DICT.TOP_ICON_BOSS_N), roundProgressPos.x + roundProgressBarW/2, roundProgressPos.y)
    local boosQuestSelectImg = display.newImageView(_res(RES_DICT.TOP_ICON_BOSS_S), roundProgressPos.x + roundProgressBarW/2, roundProgressPos.y)
    topLayer:addChild(prevFoodNormalImg)
    topLayer:addChild(prevFoodSelectImg)
    topLayer:addChild(lastFoodNormalImg)
    topLayer:addChild(lastFoodSelectImg)
    topLayer:addChild(boosQuestNormalImg)
    topLayer:addChild(boosQuestSelectImg)

    local currentRoundLabel = display.newLabel(topInfoPos.x - 180, roundProgressPos.y + 14, {fontSize = 24, color = '#EFD8D8'})
    local totalRoundLabel = display.newLabel(currentRoundLabel:getPositionX(), roundProgressPos.y - 14, {fontSize = 22, color = '#B79990'})
    display.commonLabelParams(totalRoundLabel, {text = string.fmt(__('（共_num_回合）'), {_num_ = 3})})
    topLayer:addChild(currentRoundLabel)
    topLayer:addChild(totalRoundLabel)

    -------------------------------------------------
    -- left layer
    local leftLayer = display.newLayer()
    view:addChild(leftLayer)

    local leftInfoPos = cc.p(display.SAFE_L + 100, display.cy + 120)
    leftLayer:addChild(display.newImageView(_res(RES_DICT.LEFT_TIME_FRAME), leftInfoPos.x, leftInfoPos.y - 170, {ap = display.CENTER_TOP}))
    leftLayer:addChild(display.newImageView(_res(RES_DICT.LEFT_INFO_FRAME), leftInfoPos.x, leftInfoPos.y, {ap = display.CENTER_TOP}))

    local scoreInfoBrand = display.newLabel(leftInfoPos.x, leftInfoPos.y - 20, {fontSize = 22, color = '#ECEAE3', text = __('本回合成绩')})
    local foodScoreLabel = display.newLabel(leftInfoPos.x, scoreInfoBrand:getPositionY() - 50, fontWithColor(19, {fontSize = 34}))
    local goldScoreLabel = display.newLabel(leftInfoPos.x, foodScoreLabel:getPositionY() - 65, fontWithColor(19, {fontSize = 34}))
    local endedTimeBrand = display.newLabel(leftInfoPos.x, goldScoreLabel:getPositionY() - 55, {fontSize = 22, color = '#DF8352', text = __('美食分享倒计时')})
    local countdownLabel = display.newLabel(leftInfoPos.x, endedTimeBrand:getPositionY() - 25, fontWithColor(14))
    leftLayer:addChild(scoreInfoBrand)
    leftLayer:addChild(foodScoreLabel)
    leftLayer:addChild(goldScoreLabel)
    leftLayer:addChild(endedTimeBrand)
    leftLayer:addChild(countdownLabel)
    
    local goldIconPath  = CommonUtils.GetGoodsIconPathById(UNION_POINT_ID)
    local foodScoreIcon = display.newImageView(_res(RES_DICT.TOP_ICON_FOOD_N), foodScoreLabel:getPositionX(), foodScoreLabel:getPositionY())
    local goldScoreIcon = display.newImageView(_res(goldIconPath), goldScoreLabel:getPositionX(), goldScoreLabel:getPositionY(), {scale = 0.32, enable = true})
    leftLayer:addChild(foodScoreIcon)
    leftLayer:addChild(goldScoreIcon)

    display.commonUIParams(goldScoreIcon, {cb = function(sender)
        app.uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = UNION_POINT_ID, type = 1})
    end, animate = false})

    return {
        view               = view,
        topLayer           = topLayer,
        topLayerShowPos    = cc.p(topLayer:getPosition()),
        topLayerHidePos    = cc.p(topLayer:getPositionX(), topLayer:getPositionY() + 150),
        partyNameLabel     = partyNameLabel,
        roundProgressBar   = roundProgressBar,
        prevFoodNormalImg  = prevFoodNormalImg,
        prevFoodSelectImg  = prevFoodSelectImg,
        lastFoodNormalImg  = lastFoodNormalImg,
        lastFoodSelectImg  = lastFoodSelectImg,
        boosQuestNormalImg = boosQuestNormalImg,
        boosQuestSelectImg = boosQuestSelectImg,
        currentRoundLabel  = currentRoundLabel,
        leftLayer          = leftLayer,
        leftLayerShowPos   = cc.p(leftLayer:getPosition()),
        leftLayerHidePos   = cc.p(leftLayer:getPositionX() - display.SAFE_L - 200, leftLayer:getPositionY()),
        foodScoreLabel     = foodScoreLabel,
        goldScoreLabel     = goldScoreLabel,
        foodScoreLabelPos  = cc.p(foodScoreLabel:getPosition()),
        goldScoreLabelPos  = cc.p(goldScoreLabel:getPosition()),
        countdownLabel     = countdownLabel,
        foodScoreIcon      = foodScoreIcon,
        goldScoreIcon      = goldScoreIcon,
        scoreIconSize      = cc.size(60, 60),
    }
end


CreateRoundView = function()
    local view  = display.newLayer()

    local blockLayer = display.newLayer(0, 0, {color = cc.c4b(0,0,0,0), enable = true})
    view:addChild(blockLayer)
    view:setVisible(false)
    
    local roundDoorL = display.newImageView(_res(RES_DICT.SWITCH_DOOR), display.cx, display.cy, {ap = display.RIGHT_CENTER})
    local roundDoorR = display.newImageView(_res(RES_DICT.SWITCH_DOOR), display.cx, display.cy, {ap = display.LEFT_CENTER})
    view:addChild(roundDoorL)
    view:addChild(roundDoorR)

    local roundLayer = display.newLayer()
    view:addChild(roundLayer)

    local roundFrame    = display.newImageView(_res(RES_DICT.ROUND_FRAME), display.cx, display.cy)
    local roundImage1   = display.newImageView(_res(RES_DICT.ROUND_IMG_1), display.cx, display.cy)
    local roundImage2   = display.newImageView(_res(RES_DICT.ROUND_IMG_2), display.cx, display.cy)
    local roundTitleBar = display.newButton(display.cx, display.cy, {n = _res(RES_DICT.ROUND_TITLE), enable = false})
    display.commonLabelParams(roundTitleBar, fontWithColor(20, {fontSize = 40}))
    roundLayer:addChild(roundFrame)
    roundLayer:addChild(roundImage1)
    roundLayer:addChild(roundImage2)
    roundLayer:addChild(roundTitleBar)

    -- init status
    roundDoorL:setPositionX(0)
    roundDoorR:setPositionX(display.width)
    roundLayer:setPositionY(display.height)
    blockLayer:setVisible(true)
    return {
        view              = view,
        blockLayer        = blockLayer,
        roundDoorL        = roundDoorL,
        roundDoorR        = roundDoorR,
        roundLayer        = roundLayer,
        roundTitleBar     = roundTitleBar,
        roundDoorLShowPos = cc.p(display.cx,    roundDoorL:getPositionY()),
        roundDoorLHidePos = cc.p(0,             roundDoorL:getPositionY()),
        roundDoorRShowPos = cc.p(display.cx,    roundDoorR:getPositionY()),
        roundDoorRHidePos = cc.p(display.width, roundDoorR:getPositionY()),
        roundLayerShowPos = cc.p(0, 0),
        roundLayerHidePos = cc.p(0, display.width),
    }
end


function UnionPartyView:getViewData()
    return self.viewData_
end


function UnionPartyView:showPartyView(isFast, endCB)
    local showTime   = 0.2
    local viewData   = self:getViewData()
    local finishFunc = function()
        viewData.topLayer:setPosition(viewData.topLayerShowPos)
        viewData.leftLayer:setPosition(viewData.leftLayerShowPos)
        if endCB then endCB() end
    end

    self:stopAllActions()
    viewData.topLayer:setPosition(viewData.topLayerHidePos)
    viewData.leftLayer:setPosition(viewData.leftLayerHidePos)

    if isFast then
        finishFunc()
    else
        self:runAction(cc.Sequence:create({
            cc.Spawn:create({
                cc.TargetedAction:create(viewData.topLayer, cc.MoveTo:create(showTime, viewData.topLayerShowPos)),
                cc.TargetedAction:create(viewData.leftLayer, cc.MoveTo:create(showTime, viewData.leftLayerShowPos))
            }),
            cc.CallFunc:create(finishFunc)
        }))
    end
end
function UnionPartyView:hidePartyView(isFast, endCB)
    local hideTime = 0.2
    local viewData = self:getViewData()
    local finishFunc = function()
        viewData.topLayer:setPosition(viewData.topLayerHidePos)
        viewData.leftLayer:setPosition(viewData.leftLayerHidePos)
        if endCB then endCB() end
    end

    self:stopAllActions()
    viewData.topLayer:setPosition(viewData.topLayerShowPos)
    viewData.leftLayer:setPosition(viewData.leftLayerShowPos)

    if isFast then
        finishFunc()
    else
        self:runAction(cc.Sequence:create({
            cc.Spawn:create({
                cc.TargetedAction:create(viewData.topLayer, cc.MoveTo:create(hideTime, viewData.topLayerHidePos)),
                cc.TargetedAction:create(viewData.leftLayer, cc.MoveTo:create(hideTime, viewData.leftLayerHidePos))
            }),
            cc.CallFunc:create(finishFunc)
        }))
    end
end


function UnionPartyView:updatePartyName(partyLevel)
    local partySizeConfs = CommonUtils.GetConfigAllMess(UnionConfigParser.TYPE.PARTY_SIZE, 'union') or {}
    local partyLevelName = tostring(checktable(partySizeConfs[tostring(partyLevel)]).name)
    display.commonLabelParams(self:getViewData().partyNameLabel, {text = partyLevelName})
end


function UnionPartyView:updateRoundNum(roundNum)
    local currentRoundLabel = self:getViewData().currentRoundLabel
    display.commonLabelParams(currentRoundLabel, {text = string.fmt(__('第_num_回合'), {_num_ = checkint(roundNum)})})
end


function UnionPartyView:updateRoundProgress(progress)
    local viewData = self:getViewData()
    if viewData then
        local progressNum     = math.max(0, math.min(checkint(progress), viewData.roundProgressBar:getMaxValue()))
        local progressOver0   = progressNum >= 0 and progressNum < 50
        local progressOver50  = progressNum >= 50 and progressNum < 100
        local progressOver100 = progressNum >= 100
        viewData.roundProgressBar:setValue(progressNum)
        viewData.prevFoodNormalImg:setVisible(progressOver0 == false)
        viewData.prevFoodSelectImg:setVisible(progressOver0 == true)
        viewData.boosQuestNormalImg:setVisible(progressOver50 == false)
        viewData.boosQuestSelectImg:setVisible(progressOver50 == true)
        viewData.lastFoodNormalImg:setVisible(progressOver100 == false)
        viewData.lastFoodSelectImg:setVisible(progressOver100 == true)
    end
end


function UnionPartyView:updateFoodScore(score)
    local viewData = self:getViewData()
    display.commonLabelParams(viewData.foodScoreLabel, {text = tostring(score)})

    local scoreIconHalfW = viewData.scoreIconSize.width / 2
    local scoreLabelSize = display.getLabelContentSize(viewData.foodScoreLabel)
    viewData.foodScoreLabel:setPositionX(viewData.foodScoreLabelPos.x - scoreIconHalfW)
    viewData.foodScoreIcon:setPositionX(viewData.foodScoreLabelPos.x + scoreLabelSize.width/2)
end


function UnionPartyView:updateGoldScore(score)
    local viewData = self:getViewData()
    display.commonLabelParams(viewData.goldScoreLabel, {text = tostring(score)})

    local scoreIconHalfW = viewData.scoreIconSize.width / 2
    local scoreLabelSize = display.getLabelContentSize(viewData.goldScoreLabel)
    viewData.goldScoreLabel:setPositionX(viewData.goldScoreLabelPos.x - scoreIconHalfW)
    viewData.goldScoreIcon:setPositionX(viewData.goldScoreLabelPos.x + scoreLabelSize.width/2)
end


function UnionPartyView:updateCountdown(seconds)
    local viewData = self:getViewData()
    local timeData = string.formattedTime(checkint(seconds))
    local timeText = string.format('%02d:%02d', timeData.m, timeData.s)
    display.commonLabelParams(viewData.countdownLabel, {text = timeText})
end


-------------------------------------------------
-- party level frame
function UnionPartyView:createPartyLevelFrameView(partyLevel)
    local partyFramePath = string.format('ui/union/party/prepare/guild_party_bg_grade_%d.png', checkint(partyLevel))
    local levelFrameView = display.newButton(display.cx, display.cy, {n = _res(partyFramePath), enable = false})
    local partySizeConfs = CommonUtils.GetConfigAllMess(UnionConfigParser.TYPE.PARTY_SIZE, 'union') or {}
    local partyLevelName = tostring(checktable(partySizeConfs[tostring(partyLevel)]).name)
    display.commonLabelParams(levelFrameView, fontWithColor(20, {fontSize = 70, text = partyLevelName}))
    return levelFrameView
end
function UnionPartyView:showPartyLevelFrameAction(levelFrameView, closeCB)
    if not levelFrameView then return end
    local stepTime1 = 0.2
    local stepTime2 = 0.2
    local stepTime3 = 0.8
    local stepTime4 = 0.4
    local frameSize = levelFrameView:getContentSize()
    levelFrameView:setScale(0)
    levelFrameView:setOpacity(0)
    levelFrameView:setRotation(-45)
    levelFrameView:runAction(cc.Sequence:create({
        cc.Spawn:create({
            cc.FadeIn:create(stepTime1),
            cc.ScaleTo:create(stepTime1, 1.5),
            cc.RotateTo:create(stepTime1, 30)
        }),
        cc.Spawn:create({
            cc.ScaleTo:create(stepTime2, 1),
            cc.RotateTo:create(stepTime2, 0)
        }),
        cc.DelayTime:create(stepTime3),
        cc.CallFunc:create(function()
            if closeCB then closeCB() end
        end),
        cc.Spawn:create({
            cc.RotateTo:create(0.1, -15),
            cc.MoveTo:create(stepTime4, cc.p(display.cx, -frameSize.height))
        }),
        cc.RemoveSelf:create()
    }))
end


-------------------------------------------------
-- party boss spine
function UnionPartyView:createPartyBoss(partyQuestId)
    local partyQuestConf = CommonUtils.GetConfigNoParser('union', UnionConfigParser.TYPE.PARTY_QUEST, partyQuestId) or {}
    local partyBossId    = checkint(partyQuestConf.stageMonsterDescr)

    -- boss spine
    local partyBossSpine = AssetsUtils.GetCardSpineNode({confId = partyBossId, cacheName = SpineCacheName.UNION, spineName = partyBossId})
    partyBossSpine:setPosition(cc.p(display.cx, display.cy - 120))
    partyBossSpine:setAnimation(0, 'idle', true)
    return partyBossSpine
end
function UnionPartyView:runPartyBossShowingAction(partyBossSpine, endCB)
    if not partyBossSpine and partyBossSpine:getParent() then return end
    local bossShowPos = cc.p(display.cx, display.cy - 120)
    local bossHidePos = cc.p(display.cx, display.cy * 3)

    partyBossSpine:stopAllActions()
    partyBossSpine:setPosition(bossHidePos)
    partyBossSpine:setScaleX(0.8)
    partyBossSpine:setScaleY(1.2)

    partyBossSpine:runAction(cc.Sequence:create({
        cc.MoveTo:create(0.3, bossShowPos),
        cc.CallFunc:create(function()
            -- shake scene
            sceneWorld:runAction(ShakeAction:create(0.3, 10, 5))

            -- add spine cache
            local smokePath  = 'ui/union/lobby/yan'
            if not SpineCache(SpineCacheName.UNION):hasSpineCacheData(smokePath) then
                SpineCache(SpineCacheName.UNION):addCacheData(smokePath, smokePath, 1)
            end

            -- smoke spine
            local smokeSpine = SpineCache(SpineCacheName.UNION):createWithName(smokePath)
            smokeSpine:setPosition(bossShowPos)
            smokeSpine:setAnimation(0, 'go', false)
            smokeSpine:registerSpineEventHandler(function(event)
                smokeSpine:runAction(cc.RemoveSelf:create())
            end, sp.EventType.ANIMATION_COMPLETE)
            partyBossSpine:getParent():addChild(smokeSpine)
        end),
        cc.ScaleTo:create(0.1, 1.2, 0.8),
        cc.ScaleTo:create(0.1, 1),
        cc.CallFunc:create(function()
            if endCB then endCB() end
        end)
    }))
end


-------------------------------------------------
-- party round view
function UnionPartyView:createRoundView()
    return CreateRoundView()
end
function UnionPartyView:getRoundSwitchTimeDefine()
    local actTimeDefine = {
        SHOW_DOOR_TIME  = 0.2,
        SHOW_ROUND_TIME = 0.4,
        SHOW_DELAY_TIME = 2,
        HIDE_ALL_TIME   = 0.3,
    }
    local actTotalTime = 0
    for k, v in pairs(actTimeDefine) do
        actTotalTime = actTotalTime + v
    end
    actTimeDefine.SWITCH_TOTAL_TIME = actTotalTime
    return actTimeDefine
end
function UnionPartyView:runRoundSwitchAction(roundViewData, roundNum)
    if not roundViewData then return end
    -- init status
    roundViewData.view:stopAllActions()
    roundViewData.blockLayer:setVisible(true)
    roundViewData.roundDoorL:setPosition(roundViewData.roundDoorLHidePos)
    roundViewData.roundDoorR:setPosition(roundViewData.roundDoorRHidePos)
    roundViewData.roundLayer:setPosition(roundViewData.roundLayerHidePos)
    display.commonLabelParams(roundViewData.roundTitleBar, {text = string.fmt(__('第_num_回合'), {_num_ = checkint(roundNum)})})

    -- run switch action
    local switchTimeDefine = self:getRoundSwitchTimeDefine()
    roundViewData.view:runAction(cc.Sequence:create({
        cc.Spawn:create({
            cc.TargetedAction:create(roundViewData.roundDoorL, cc.MoveTo:create(switchTimeDefine.SHOW_DOOR_TIME, roundViewData.roundDoorLShowPos)),
            cc.TargetedAction:create(roundViewData.roundDoorR, cc.MoveTo:create(switchTimeDefine.SHOW_DOOR_TIME, roundViewData.roundDoorRShowPos))
        }),
        cc.TargetedAction:create(roundViewData.roundLayer, cc.MoveTo:create(switchTimeDefine.SHOW_ROUND_TIME, roundViewData.roundLayerShowPos)),
        cc.DelayTime:create(switchTimeDefine.SHOW_DELAY_TIME),
        cc.Spawn:create({
            cc.TargetedAction:create(roundViewData.roundDoorL, cc.MoveTo:create(switchTimeDefine.HIDE_ALL_TIME, roundViewData.roundDoorLHidePos)),
            cc.TargetedAction:create(roundViewData.roundDoorR, cc.MoveTo:create(switchTimeDefine.HIDE_ALL_TIME, roundViewData.roundDoorRHidePos)),
            cc.TargetedAction:create(roundViewData.roundLayer, cc.MoveTo:create(switchTimeDefine.HIDE_ALL_TIME, cc.p(0, -display.height)))
        }),
        cc.TargetedAction:create(roundViewData.blockLayer, cc.Hide:create())
    }))
end


return UnionPartyView
