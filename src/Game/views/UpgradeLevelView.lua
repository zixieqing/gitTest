--[[
 * author : kaishiqi
 * descpt : 玩家升级 视图
]]
local UpgradeLevelView = class('UpgradeLevelView', function()
    return display.newLayer(0, 0, {name = 'Game.views.UpgradeLevelView'})
end)

local RES_DICT = {
    UPGRADE_SUNSHINE = 'ui/home/levelupgrade/level_up_ico_sunshine.png',
    UPGRADE_ARROW    = 'ui/home/kitchen/cooking_level_up_ico_arrow.png',
    REWARD_TITLE     = 'ui/home/levelupgrade/level_up_bg_title.png',
    LEVEL_UP_TEXT    = 'ui/home/levelupgrade/level_up_ico_text.png',
    BTN_CONFIRM_N    = 'ui/common/common_btn_orange_l.png',
    UNLOCK_SUNSHINE  = 'ui/common/common_reward_light.png',
    UNLOCK_NAME_BAR  = 'ui/home/levelupgrade/level_up_bg_title_unlock.png',
    UNLOCK_TITLE     = 'ui/home/levelupgrade/level_up_text_unlock.png',
}

local CreateView = nil


function UpgradeLevelView:ctor(args)
    self.viewData_ = CreateView()
    self.viewData_.view:setName('view')
    self:addChild(self.viewData_.view)

    local upgradeFrameSpine = self.viewData_.upgradeFrameSpine
    upgradeFrameSpine:registerSpineEventHandler(handler(self, self.onUppgradeFrameSpineCompleteHandler_), sp.EventType.ANIMATION_COMPLETE)
end


CreateView = function()
    local view = display.newLayer()
    local size = view:getContentSize()

    -- block layer
    local blockLayer = display.newLayer(0, 0, {color = cc.c4b(0,0,0,150), enable = true})
    view:addChild(blockLayer)


    -------------------------------------------------
    -- upgrade frame layer
    local upgradeFrameSize  = cc.size(size.width/2, size.height)
    local upgradeFrameLayer = display.newLayer(size.width/2, size.height/2, {ap = display.CENTER, size = upgradeFrameSize})
    view:addChild(upgradeFrameLayer)

    -- upgrade sunshine image
    local upgradeSunshineImg = display.newImageView(_res(RES_DICT.UPGRADE_SUNSHINE), upgradeFrameSize.width/2, upgradeFrameSize.height/2, {scale = 0.3})
    upgradeFrameLayer:addChild(upgradeSunshineImg)
    upgradeSunshineImg:runAction(cc.Sequence:create(
        cc.Spawn:create(
            cc.ScaleTo:create(0.5, 1),
            cc.RotateTo:create(0.5, 450)
        ),
        cc.CallFunc:create(function()
            upgradeSunshineImg:stopAllActions()
            upgradeSunshineImg:runAction(cc.RepeatForever:create(cc.Spawn:create(
                cc.Sequence:create(
                    cc.FadeTo:create(2.5, 100),
                    cc.FadeTo:create(2.5, 255)
                ),
                cc.RotateBy:create(5, 135)
            )))
        end)
    ))

    -- upgrade frame spine
    local upgradeFramePath  = 'effects/upgradeLevel/skeleton'
    local upgradeFrameSpine = sp.SkeletonAnimation:create(upgradeFramePath .. '.json', upgradeFramePath .. '.atlas', 1)
    upgradeFrameSpine:setPosition(upgradeFrameSize.width/2, upgradeFrameSize.height/2)
    upgradeFrameLayer:addChild(upgradeFrameSpine)

    -- levelUp text image
    local levelUpTextImage = display.newImageView(_res(RES_DICT.LEVEL_UP_TEXT), upgradeFrameSize.width/2 + 15, upgradeFrameSize.height/2 + 310)
    upgradeFrameLayer:addChild(levelUpTextImage)
    
    -- player level label
    local playerLevelLabel = cc.Label:createWithBMFont('font/levelup.fnt', '')
    playerLevelLabel:setPosition(cc.p(upgradeFrameSize.width/2, upgradeFrameSize.height/2 + 180))
    playerLevelLabel:setAnchorPoint(display.CENTER)
    upgradeFrameLayer:addChild(playerLevelLabel)


    -- upgrade info layer
    local upgradeInfoSize  = cc.size(320, 220)
    local upgradeInfoLayer = display.newLayer(upgradeFrameSize.width/2, upgradeFrameSize.height/2 - 30, {ap = display.CENTER, size = upgradeInfoSize})
    upgradeFrameLayer:addChild(upgradeInfoLayer)

    -- upgrade reward bar
    local upgradeRewardBar = display.newButton(upgradeInfoSize.width/2, upgradeInfoSize.height/2, {n = _res(RES_DICT.REWARD_TITLE), enable = false})
    display.commonLabelParams(upgradeRewardBar, {color = '#95663d', fontSize = 22, text = __('奖励')})
    upgradeInfoLayer:addChild(upgradeRewardBar)
    
    -- upgrade reward layer
    local upgradeRewardSize  = cc.size(upgradeInfoSize.width, 90)
    local upgradeRewardLayer = display.newLayer(upgradeRewardBar:getPositionX(), upgradeRewardBar:getPositionY() - 15, {ap = display.CENTER_TOP, size = upgradeRewardSize})
    upgradeInfoLayer:addChild(upgradeRewardLayer)

    -- upgrade info detail
    local upgradeInfoDefines = {
        {title = __('体力上限')},
        {title = __('角色等级')},
    }
    local oldNumInfoLabels = {}
    local newNumInfoLabels = {}
    local defineInfoLayers = {}
    for i, define in ipairs(upgradeInfoDefines) do
        local infoLayer = display.newLayer()
        upgradeInfoLayer:addChild(infoLayer)
        table.insert(defineInfoLayers, infoLayer)

        local infoBasePos = cc.p(upgradeRewardBar:getPositionX(), upgradeRewardBar:getPositionY() + 50 + (i-1) * 30)
        local titleBrand  = display.newLabel(infoBasePos.x - 10, infoBasePos.y, fontWithColor(8, {ap = display.RIGHT_CENTER, text = tostring(define.title)}))
        infoLayer:addChild(titleBrand)
        
        local NUM_LABEL_W = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '00'):getContentSize().width
        local infoOffsetX = infoBasePos.x + NUM_LABEL_W/2

        local oldNumLabel = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '--')
        oldNumLabel:setPosition(infoOffsetX, infoBasePos.y)
        oldNumLabel:setAnchorPoint(display.CENTER)
        infoLayer:addChild(oldNumLabel)
        table.insert(oldNumInfoLabels, oldNumLabel)
        
        local ARROW_COUNT  = 3
        local ARROW_ICON_W = 12
        local ARROW_AREA_W = ARROW_ICON_W * ARROW_COUNT + 20
        infoOffsetX        = infoOffsetX + NUM_LABEL_W/2 + ARROW_AREA_W/2
        for j = 1, ARROW_COUNT do
            local arrowOffX = (ARROW_COUNT/2 - 0.5) * ARROW_ICON_W
            local arrowIcon = display.newImageView(_res(RES_DICT.UPGRADE_ARROW), infoOffsetX - arrowOffX + (j-1)*ARROW_ICON_W, infoBasePos.y)
            infoLayer:addChild(arrowIcon)
            arrowIcon:setOpacity(0)
            arrowIcon:runAction(cc.RepeatForever:create(cc.Sequence:create({
                cc.DelayTime:create((j-1) * 0.4),
                cc.FadeIn:create(0.8),
                cc.FadeOut:create(0.8),
                cc.DelayTime:create((ARROW_COUNT - j) * 0.4),
            })))
        end

        infoOffsetX = infoOffsetX + ARROW_AREA_W/2 + NUM_LABEL_W/2
        local newNumLabel = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '--')
        newNumLabel:setPosition(infoOffsetX, infoBasePos.y)
        newNumLabel:setAnchorPoint(display.CENTER)
        infoLayer:addChild(newNumLabel)
        table.insert(newNumInfoLabels, newNumLabel)
    end


    -------------------------------------------------
    -- unlock frame layer
    local unlockFrameSize  = cc.size(size.width/2, size.height)
    local unlockFrameLayer = display.newLayer(size.width/5*4, size.height/2, {ap = display.CENTER, size = unlockFrameSize})
    view:addChild(unlockFrameLayer)
    unlockFrameLayer:setVisible(false)
    unlockFrameLayer:setName('rightLayout')

    -- goto home button
    local gotoHomeBtn = display.newButton(unlockFrameSize.width/2, unlockFrameSize.height/2 - 255, {n = _res(RES_DICT.BTN_CONFIRM_N)})
    display.commonLabelParams(gotoHomeBtn, fontWithColor(14, {text = __('返回主界面')}))
    unlockFrameLayer:addChild(gotoHomeBtn)
    gotoHomeBtn:setName('goToButton')
    
    -- unlock info layer
    local unlockInfoSize  = cc.size(320, 220)
    local unlockInfoLayer = display.newLayer(unlockFrameSize.width/2, unlockFrameSize.height/2, {ap = display.CENTER, size = unlockInfoSize})
    unlockFrameLayer:addChild(unlockInfoLayer)

    -- unlock sunshine image
    local unlockSunshineImg = display.newImageView(_res(RES_DICT.UNLOCK_SUNSHINE), unlockInfoSize.width/2, unlockInfoSize.height/2)
    unlockInfoLayer:addChild(unlockSunshineImg)
    unlockSunshineImg:runAction(cc.RepeatForever:create(cc.RotateBy:create(1, 30)))

    -- unlock function imageLayer
    local unlockFuncImgLayer = display.newLayer(unlockInfoSize.width/2, unlockInfoSize.height/2)
    unlockInfoLayer:addChild(unlockFuncImgLayer)

    -- unlock function titleImage
    local unlockFuncTitleImg = display.newImageView(_res(RES_DICT.UNLOCK_TITLE), unlockInfoSize.width/2, unlockInfoSize.height/2 + 120)
    unlockInfoLayer:addChild(unlockFuncTitleImg)
    
    -- unlock function nameBar
    local unlockFuncNameBar = display.newButton(unlockInfoSize.width/2, unlockInfoSize.height/2 - 90, {n = _res(RES_DICT.UNLOCK_NAME_BAR), enable = false})
    display.commonLabelParams(unlockFuncNameBar, fontWithColor(14, {offset = cc.p(0,10)}))
    unlockInfoLayer:addChild(unlockFuncNameBar)


    return {
        view                  = view,
        blockLayer            = blockLayer,
        upgradeFrameLayer     = upgradeFrameLayer,
        upgradeFrameCenterPos = cc.p(upgradeFrameLayer:getPositionX(), upgradeFrameLayer:getPositionY()),
        upgradeFrameLeftPos   = cc.p(size.width/3, upgradeFrameLayer:getPositionY()),
        upgradeFrameSpine     = upgradeFrameSpine,
        levelUpTextImage      = levelUpTextImage,
        levelUpTextShowPos    = cc.p(levelUpTextImage:getPositionX(), levelUpTextImage:getPositionY()),
        levelUpTextHidePos    = cc.p(levelUpTextImage:getPositionX(), levelUpTextImage:getPositionY() - 400),
        playerLevelLabel      = playerLevelLabel,
        upgradeInfoLayer      = upgradeInfoLayer,
        upgradeRewardLayer    = upgradeRewardLayer,
        healthInfoLayer       = defineInfoLayers[1],
        oldHealthLabel        = oldNumInfoLabels[1],
        newHealthLabel        = newNumInfoLabels[1],
        levelInfoLayer        = defineInfoLayers[2],
        oldLevelLabel         = oldNumInfoLabels[2],
        newLevelLabel         = newNumInfoLabels[2],
        unlockFrameLayer      = unlockFrameLayer,
        unlockFrameCenterPos  = cc.p(size.width/2, unlockFrameLayer:getPositionY()),
        unlockFrameRightPos   = cc.p(unlockFrameLayer:getPositionX(), unlockFrameLayer:getPositionY()),
        unlockInfoLayer       = unlockInfoLayer,
        unlockFuncNameBar     = unlockFuncNameBar,
        unlockFuncImgLayer    = unlockFuncImgLayer,
        gotoHomeBtn           = gotoHomeBtn,
    }
end


function UpgradeLevelView:getViewData()
    return self.viewData_
end


function UpgradeLevelView:updateLevelInfo(oldLevel, newLevel)
    local viewData = self:getViewData()
    display.commonLabelParams(viewData.oldLevelLabel, {text = tostring(oldLevel)})
    display.commonLabelParams(viewData.newLevelLabel, {text = tostring(newLevel)})
    display.commonLabelParams(viewData.playerLevelLabel, {text = tostring(newLevel)})
    viewData.levelInfoLayer:setVisible(checkint(newLevel) > checkint(oldLevel))
end


function UpgradeLevelView:updateHealthInfo(oldHP, newHP)
    local viewData = self:getViewData()
    display.commonLabelParams(viewData.oldHealthLabel, {text = tostring(oldHP)})
    display.commonLabelParams(viewData.newHealthLabel, {text = tostring(newHP)})
    viewData.healthInfoLayer:setVisible(checkint(newHP) > checkint(oldHP))
end


function UpgradeLevelView:updateRewardsInfo(rewardList)
    local viewData = self:getViewData()
    viewData.upgradeRewardLayer:removeAllChildren()

    local GOODS_GAP  = 90
    local layerSize  = viewData.upgradeRewardLayer:getContentSize()
    local nodeBsePos = cc.p(layerSize.width/2 - (table.nums(rewardList or {})/2 -0.5) * GOODS_GAP, layerSize.height/2)
    for i, rewardData in ipairs(rewardList or {}) do
        local goodsNode = require('common.GoodNode').new({id = rewardData.goodsId, amount = rewardData.num, showAmount = true})
        goodsNode:setPosition(nodeBsePos.x + (i-1) * GOODS_GAP, nodeBsePos.y)
        goodsNode:setScale(0.7)
        viewData.upgradeRewardLayer:addChild(goodsNode)

        display.commonUIParams(goodsNode, {cb = function(sender)
            local uiManager = AppFacade.GetInstance():GetManager('UIManager')
            uiManager:ShowInformationTipsBoard({targetNode = sender, iconId = rewardData.goodsId, type = 1})
        end, animate = false})

        goodsNode:setOpacity(0)
        goodsNode:setPositionY(goodsNode:getPositionY() - 100)
        goodsNode:runAction(cc.Sequence:create(
            cc.DelayTime:create(0.15 * i),
            cc.Spawn:create(
                cc.JumpBy:create(0.3, cc.p(0, 100), 75, 1),
                cc.FadeIn:create(0.3)
            )
        ))
    end
end


function UpgradeLevelView:updateUnlockFunctionInfo(moduleId)
    local moduleConfs = CommonUtils.GetConfigAllMess('module') or {}
    local moduleConf  = moduleConfs[tostring(moduleId)] or {}
    local viewData    = self:getViewData()
    display.commonLabelParams(viewData.unlockFuncNameBar, {text = tostring(moduleConf.name)})
    
    local funcIconPath = string.fmt('ui/home/levelupgrade/unlockmodule/%1.png', tostring(moduleConf.iconID))
    viewData.unlockFuncImgLayer:removeAllChildren()
    viewData.unlockFuncImgLayer:addChild(display.newImageView(_res(funcIconPath)))
end


function UpgradeLevelView:showUpgradeFrame(spineEndCB, actionEndCB)
    self.upgradeFrameSpinePlayEndCB_  = spineEndCB
    self.upgradeFrameShowActionEndCB_ = actionEndCB

    local viewData = self:getViewData()
    viewData.upgradeInfoLayer:setScaleY(0)
    viewData.playerLevelLabel:setOpacity(0)
    viewData.levelUpTextImage:setOpacity(0)
    viewData.levelUpTextImage:setPosition(viewData.levelUpTextHidePos)
    viewData.upgradeFrameSpine:setAnimation(0, 'play', false)
end
function UpgradeLevelView:onUppgradeFrameSpineCompleteHandler_(event)
    local viewData = self:getViewData()

    if event.animation == 'play' then
        viewData.upgradeFrameSpine:setToSetupPose()
        viewData.upgradeFrameSpine:setAnimation(0, 'idle', true)

        if self.upgradeFrameSpinePlayEndCB_ then
            self.upgradeFrameSpinePlayEndCB_()
        end

        self:runAction(cc.Sequence:create(
            cc.Spawn:create(
                cc.TargetedAction:create(viewData.upgradeInfoLayer, cc.ScaleTo:create(0.2, 1)),
                cc.TargetedAction:create(viewData.playerLevelLabel, cc.FadeIn:create(0.2)),
                cc.TargetedAction:create(viewData.levelUpTextImage, cc.Spawn:create(
                    cc.FadeIn:create(0.3),
                    cc.JumpTo:create(0.3, viewData.levelUpTextShowPos, 100, 1)
                ))
            ),
            cc.DelayTime:create(0.2),
            cc.CallFunc:create(function()
                if self.upgradeFrameShowActionEndCB_ then
                    self.upgradeFrameShowActionEndCB_()
                end
            end)
        ))
    end
end


function UpgradeLevelView:showCloseFrame(endCB)
    local viewData = self:getViewData()
    viewData.unlockFrameLayer:setOpacity(0)
    viewData.unlockFrameLayer:setVisible(true)
    viewData.unlockInfoLayer:setVisible(false)
    self:runAction(cc.Sequence:create(
        cc.TargetedAction:create(viewData.unlockFrameLayer, cc.EaseQuadraticActionIn:create(cc.FadeIn:create(0.3))),
        cc.DelayTime:create(0.2),
        cc.CallFunc:create(function()
            if endCB then endCB() end
        end)
    ))
end


function UpgradeLevelView:showUnlockFrame(endCB)
    local viewData = self:getViewData()
    viewData.unlockFrameLayer:setOpacity(0)
    viewData.unlockFrameLayer:setVisible(true)
    viewData.unlockFrameLayer:setPosition(viewData.unlockFrameCenterPos)
    viewData.upgradeFrameLayer:setPosition(viewData.upgradeFrameCenterPos)
    self:runAction(cc.Sequence:create(
        cc.Spawn:create(
            cc.TargetedAction:create(viewData.unlockFrameLayer, cc.EaseQuadraticActionIn:create(cc.FadeIn:create(0.3))),
            cc.TargetedAction:create(viewData.unlockFrameLayer, cc.MoveTo:create(0.3, viewData.unlockFrameRightPos)),
            cc.TargetedAction:create(viewData.upgradeFrameLayer, cc.MoveTo:create(0.3, viewData.upgradeFrameLeftPos))
        ),
        cc.DelayTime:create(0.2),
        cc.CallFunc:create(function()
            if endCB then endCB() end
        end)
    ))
end


return UpgradeLevelView
