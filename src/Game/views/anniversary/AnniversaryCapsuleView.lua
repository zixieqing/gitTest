--[[
游乐园（夏活）扭蛋view
--]]
---@class AnniversaryCapsuleView
local AnniversaryCapsuleView = class('AnniversaryCapsuleView', function ()
    local node = CLayout:create(display.size)
    node.name = 'home.AnniversaryCapsuleView'
    node:enableNodeEvents()
    return node
end)
-- local GameScene = require('Frame.GameScene')
-- local AnniversaryCapsuleView = class('AnniversaryCapsuleView', GameScene)
local uiMgr = app.uiMgr
local GoodPurchaseNode = require('common.GoodPurchaseNode')

local RES_DICT = {
    DIALOGUE_BG_2                   = app.anniversaryMgr:GetResPath('arts/stage/ui/dialogue_bg_2.png'),
    DIALOGUE_HORN                   = app.anniversaryMgr:GetResPath('arts/stage/ui/dialogue_horn.png'),
    COMMON_BTN_BACK                 = app.anniversaryMgr:GetResPath('ui/common/common_btn_back.png'),
    COMMON_BTN_ORANGE               = app.anniversaryMgr:GetResPath('ui/common/common_btn_orange.png'),
    COMMON_BTN_TIPS                 = app.anniversaryMgr:GetResPath('ui/common/common_btn_tips.png'),
    COMMON_TITLE                    = app.anniversaryMgr:GetResPath('ui/common/common_title_new.png'),
    -- MAIN_BG_BANNER_UP               = app.anniversaryMgr:GetResPath('ui/home/exploration/main_bg_banner_up.png'),
    RAID_ROOM_ICO_READY             = app.anniversaryMgr:GetResPath('ui/common/raid_room_ico_ready.png'),
    MAIN_BG_MONEY                   = app.anniversaryMgr:GetResPath('ui/home/nmain/main_bg_money.png'),
    ANNI_DRAW_BG                    = app.anniversaryMgr:GetResPath('ui/anniversary/capsule/anni_draw_bg.jpg'),
    ANNI_DRAW_BG_BELOW              = app.anniversaryMgr:GetResPath('ui/anniversary/capsule/anni_draw_bg_below.png'),
    ANNI_DRAW_BG_EXTRA              = app.anniversaryMgr:GetResPath('ui/anniversary/capsule/anni_draw_bg_extra.png'),
    ANNI_DRAW_BG_EXTRA_LIGHT        = app.anniversaryMgr:GetResPath('ui/anniversary/capsule/anni_draw_bg_extra_light.png'),
    ANNI_DRAW_BG_PLATE              = app.anniversaryMgr:GetResPath('ui/anniversary/capsule/anni_draw_bg_plate.png'),
    ANNI_DRAW_BTN_NINE              = app.anniversaryMgr:GetResPath('ui/anniversary/capsule/anni_draw_btn_nine.png'),
    ANNI_DRAW_BTN_ONE               = app.anniversaryMgr:GetResPath('ui/anniversary/capsule/anni_draw_btn_one.png'),
    ANNI_DRAW_EGG_EXTRA_BAR_GREY    = app.anniversaryMgr:GetResPath('ui/anniversary/capsule/anni_draw_egg_extra_bar_grey.png'),
    ANNI_DRAW_EXTRA_BAR_ACTIVE      = app.anniversaryMgr:GetResPath('ui/anniversary/capsule/anni_draw_extra_bar_active.png'),
    ANNI_DRAW_LABEL_NUM             = app.anniversaryMgr:GetResPath('ui/anniversary/capsule/anni_draw_label_num.png'),
    ANNI_DRAW_BG_SHADOW             = app.anniversaryMgr:GetResPath('ui/anniversary/capsule/anni_draw_bg_shadow.png'),
    ANNI_DRAW_BG_TEXT               = app.anniversaryMgr:GetResPath('ui/anniversary/capsule/anni_draw_bg_text.png'),
    ANNI_DRAW_LABEL_EXTRA           = app.anniversaryMgr:GetResPath('ui/anniversary/capsule/anni_draw_label_extra.png'),
    ANNI_ICO_POINT                  = app.anniversaryMgr:GetResPath('ui/anniversary/rewardPreview/anni_ico_point.png'),

    CAPSULE_SPINE                   = app.anniversaryMgr:GetSpinePath('effects/capsule/capsule'),
    RING_SPINE                      = app.anniversaryMgr:GetSpinePath('ui/anniversary/capsule/spine/anni_draw_circle'),
    ANNI_DRAW_CUTIN                 = app.anniversaryMgr:GetSpinePath('ui/anniversary/capsule/spine/anni_draw_cutin'),
    ANNI_DRAW_CAN                   = app.anniversaryMgr:GetSpinePath('ui/anniversary/capsule/spine/anni_draw_can')
    
}

local BUTTON_TAG = {
    BACK             = 100,
    RULE             = 101,
    NINE_DRAW        = 102,
    ONT_DRAW         = 103,
    EXTRA_REWARD_TIP = 104,
    REWARD_PREVIEW   = 105,
    DRAW_TIP_SHOW    = 106,
    DRAW_TIP_HIDE    = 107,
}

local UI_STATE = {
    BELOW_SHOW    = 1,
    BELOW_HIDE    = 2,
    DIALOG_SHOW   = 3,
    DIALOG_HIDE   = 4,
}

local DRAW_TYPE = {
    ONE  = 1,
    NINE = 2
}

local ONE_DRAW_STAGE_TYPE = {
    STOP    = 0,
    RUN_1   = 1,
    WAIT    = 2,
    RUN_2   = 3,
    END     = 4,
}

local CreateView       = nil
local CreateCapsuleBtn = nil
local CreateAvatarDialogueLayer = nil

function AnniversaryCapsuleView:ctor( ... )
    self.args = unpack({...}) or {}
    self:initUI()
end
--[[
init ui
--]]
function AnniversaryCapsuleView:initUI()
    xTry(function ( )
        self.viewData = CreateView( )
        self:addChild(self.viewData.view)
    end, __G__TRACKBACK__)
end

--==============================--
--desc: 更新累计套圈奖励按钮显示状态
--params superRewardTimes  int 最大累计次数
--@return
--==============================--
function AnniversaryCapsuleView:updateExtraRewardTipState(superRewardTimes)
    local viewData              = self:getViewData()
    local homeData              = app.anniversaryMgr:GetHomeData()
    local supperRewardsHasDrawn = checkint(homeData.supperRewardsHasDrawn) > 0
    local mysteriousCircleNum   = checkint(homeData.mysteriousCircleNum)

    superRewardTimes = checkint(superRewardTimes)

    local extraRewardTipLightBg = viewData.extraRewardTipLightBg
    extraRewardTipLightBg:setVisible(not supperRewardsHasDrawn and (mysteriousCircleNum > superRewardTimes))

    local rightImg              = viewData.rightImg
    rightImg:setVisible(supperRewardsHasDrawn)

    local extraRewardTipLabel   = viewData.extraRewardTipLabel
    local text = ''
    -- logInfo.add(5, tostring(supperRewardsHasDrawn))
    if supperRewardsHasDrawn then
        text = app.anniversaryMgr:GetPoText(__('已领取'))
    elseif mysteriousCircleNum > superRewardTimes then
        text = app.anniversaryMgr:GetPoText(__('点击领取'))
    else
        text = app.anniversaryMgr:GetPoText(__('累计套圈奖励'))
    end
    display.commonLabelParams(extraRewardTipLabel, {text = text, reqW = 178})

    local progressBar           = viewData.progressBar
    progressBar:setMaxValue(superRewardTimes)
    -- 大于
    if superRewardTimes < mysteriousCircleNum then
        progressBar:setValue(superRewardTimes)
        display.commonLabelParams(progressBar:getLabel(), {text = string.format( "%s/%s", mysteriousCircleNum, superRewardTimes)})
    else
        progressBar:setValue(mysteriousCircleNum)
    end
    
end

--==============================--
--desc: 更新套圈消耗数量标签
--params capsuleBtn  userdata 抽卡按钮
--       consumeNum  int      消耗数量
--@return
--==============================--
function AnniversaryCapsuleView:updateConsumeNumLabel(capsuleBtn, consumeNum)
    local consumeNumLabel = capsuleBtn:getChildByName('consumeNumLabel')
    if consumeNumLabel then
        display.commonLabelParams(consumeNumLabel, {text = consumeNum})
    end
end

--更新顶部货币数量
function AnniversaryCapsuleView:UpdateCountUI()
    local viewData  = self:getViewData()
    local moneyNods = viewData.moneyNods
	if moneyNods then
		for id, v in pairs(moneyNods) do
			v:updataUi(checkint(id)) --刷新每一个货币数量
		end
	end
end

CreateView = function ()
    local view = display.newLayer()
    local size = view:getContentSize()

    view:addChild(display.newLayer(0,0,{color = cc.c4b(0,0,0,0), enable = true}))
    view:addChild(display.newNSprite(RES_DICT.ANNI_DRAW_BG, size.width / 2, size.height / 2, {ap = display.CENTER}))

    local actionBtns = {}
    -- back btn
    local backBtn = display.newButton(display.SAFE_L + 57, display.height - 55,
    {
        ap = display.CENTER,
        n = RES_DICT.COMMON_BTN_BACK,
        enable = true,
    })
    view:addChild(backBtn)
    actionBtns[tostring(BUTTON_TAG.BACK)] = backBtn

    local titleBtn = display.newButton(display.SAFE_L + 130, display.height, {n = RES_DICT.COMMON_TITLE, enable = true, ap = display.LEFT_TOP})
    display.commonLabelParams(titleBtn, {ttf = true, font = TTF_GAME_FONT, text = app.anniversaryMgr:GetPoText(__('神秘套圈')), reqW= 190 ,  fontSize = 30, color = '#473227',offset = cc.p(-15,-8)})
    view:addChild(titleBtn)
    actionBtns[tostring(BUTTON_TAG.RULE)] = titleBtn

    local tipsImg = display.newNSprite(RES_DICT.COMMON_BTN_TIPS, 250, 30,
    {
        ap = display.CENTER,
    })
    titleBtn:addChild(tipsImg)

    -- 重写顶部状态条 -- 
    local topLayoutSize = cc.size(display.width, 80)
    local moneyNode = CLayout:create(topLayoutSize)
    moneyNode:setName('TOP_LAYOUT')
    display.commonUIParams(moneyNode, {ap = display.CENTER_TOP, po = cc.p(display.cx, display.height)})
    view:addChild(moneyNode,100)

    -- top icon
    local imageImage = display.newImageView(RES_DICT.MAIN_BG_MONEY,0,0,{enable = false,
        scale9 = true, size = cc.size(680 + (display.width - display.SAFE_R), 54)})
    display.commonUIParams(imageImage,{ap = display.RIGHT_TOP, po = cc.p(display.width, 80)})
    moneyNode:addChild(imageImage)
    local moneyNods = {}
    local iconData = {app.anniversaryMgr:GetRingGameID(), GOLD_ID, DIAMOND_ID}
    for i,v in ipairs(iconData) do
        local isShowHpTips = (v == HP_ID) and 1 or -1
        local purchaseNode = GoodPurchaseNode.new({id = v, isShowHpTips = isShowHpTips})
        display.commonUIParams(purchaseNode,
        {ap = cc.p(1, 0.5), po = cc.p(topLayoutSize.width - 30 - display.SAFE_L - (( #iconData - i) * (purchaseNode:getContentSize().width + 16)), imageImage:getPositionY()- 26)})
        moneyNode:addChild(purchaseNode, 5)
        purchaseNode:setName('purchaseNode' .. i)
        purchaseNode.viewData.touchBg:setTag(checkint(v))
        moneyNods[tostring(v)] = purchaseNode
    end
    -- 重写顶部状态条 -- 

    ------------------- content ui start -------------------
    local contentUILayer = display.newLayer(size.width / 2, size.height / 2, {ap = display.CENTER, size = cc.size(1624, 1002)})
    view:addChild(contentUILayer)

    local potPositionConf = {
        cc.p(582, 373), cc.p(802, 373), cc.p(1064, 373),
        cc.p(537, 518), cc.p(820, 518), cc.p(1124, 518),
        cc.p(486, 702), cc.p(838, 702), cc.p(1184, 702),
    }
    local potCellSize = cc.size(105, 164)
    local potCells = {}
    local _r = math.random
    local potCellSpineScale = 0.5
    for i, pos in ipairs(potPositionConf) do
        local color = cc.c4b(0,0,0,0)
        local potCell = display.newLayer(pos.x, 1002 - pos.y - 40, {size = potCellSize, ap = display.CENTER_BOTTOM, enable = true, color = color})
        contentUILayer:addChild(potCell)

        -- ANNI_DRAW_CAN
        print(RES_DICT.ANNI_DRAW_CAN.json)
        print(RES_DICT.ANNI_DRAW_CAN.atlas)
        local potSpine = sp.SkeletonAnimation:create(
            RES_DICT.ANNI_DRAW_CAN.json,
            RES_DICT.ANNI_DRAW_CAN.atlas,
        1)
        potSpine:update(0)
        potSpine:setToSetupPose()
        potSpine:setAnimation(0, 'anni_draw_can_idle', false)
        
        potSpine:setPosition(cc.p(potCellSize.width/2, 40))
        potSpine:setScale(potCellSpineScale)
        potSpine:setName('potSpine')
        potCell:addChild(potSpine)

        table.insert(potCells, potCell)

        if i / 3 == 1 then
            potCellSpineScale = 0.53
        elseif i / 3 == 2 then
            potCellSpineScale = 0.65
        end
    end

    ------------------- content ui end -------------------

    ------------------- below UI start -------------------
    local belowLayerSize = cc.size(display.SAFE_RECT.width, 237)
    local belowLayer = display.newLayer(size.width / 2, 0,
    {
        ap = display.CENTER_BOTTOM,
        size = belowLayerSize,
    })
    view:addChild(belowLayer)
    -- belowLayer:setVisible(false)

    local belowBg = display.newNSprite(RES_DICT.ANNI_DRAW_BG_BELOW, belowLayerSize.width / 2, 0,
    {
        ap = display.CENTER_BOTTOM,
    })
    belowLayer:addChild(belowBg)

    local capsuleBtnConf = {
        [tostring(BUTTON_TAG.NINE_DRAW)] = {po = cc.p(0, 0), ap = display.LEFT_BOTTOM, btnSize = cc.size(245, 240), 
            drawBtnImg = RES_DICT.ANNI_DRAW_BTN_NINE, drawBtnImgPo = cc.p(119, 146), name = app.anniversaryMgr:GetPoText(__('套9次')), consumeNum = 9},
        [tostring(BUTTON_TAG.ONT_DRAW)] = {po = cc.p(belowLayerSize.width, 0), ap = display.RIGHT_BOTTOM, btnSize = cc.size(245, 160), 
            drawBtnImg = RES_DICT.ANNI_DRAW_BTN_ONE, drawBtnImgPo = cc.p(123, 110), name = app.anniversaryMgr:GetPoText(__('套1次')), consumeNum = 1},
    }

    for tag, conf in pairs(capsuleBtnConf) do
        local capsuleBtn = CreateCapsuleBtn(conf)
        belowLayer:addChild(capsuleBtn)
        actionBtns[tostring(tag)] = capsuleBtn
    end

    -- extra reward tip light bg
    local extraRewardTipLightBg = display.newNSprite(RES_DICT.ANNI_DRAW_BG_EXTRA_LIGHT, belowLayerSize.width / 2 - 150, 92,
    {
        ap = display.CENTER,
    })
    belowLayer:addChild(extraRewardTipLightBg)
    extraRewardTipLightBg:setVisible(false)
    
    local extraRewardTipBtn = display.newButton(belowLayerSize.width / 2 - 150, 91,
    {
        ap = display.CENTER,
        n = RES_DICT.ANNI_DRAW_BG_EXTRA,
        enable = true,
    })
    belowLayer:addChild(extraRewardTipBtn)
    actionBtns[tostring(BUTTON_TAG.EXTRA_REWARD_TIP)] = extraRewardTipBtn
    require('common.RemindIcon').addRemindIcon({parent = extraRewardTipBtn, tag = RemindTag.ANNIVERSARY_EXTRA_REWARD_TIP, po = cc.p(extraRewardTipBtn:getContentSize().width - 28, extraRewardTipBtn:getContentSize().height - 78)})

    local extraRewardTipLabel = display.newButton(362, 68, 
        {n = RES_DICT.ANNI_DRAW_LABEL_EXTRA, ap = display.RIGHT_CENTER, scale9 = true, enable = false})
    display.commonLabelParams(extraRewardTipLabel, fontWithColor(20,  {
        text =  app.anniversaryMgr:GetPoText(__('累计套圈奖励')),
        hAlign = display.TAR,
        ap = display.RIGHT_CENTER,
        fontSize = 22,
        color = '#ffffff',
        outline = '#a54441',
        offset = cc.p(94, 0),
    }))
    extraRewardTipBtn:addChild(extraRewardTipLabel)

    local progressBar = CProgressBar:create(RES_DICT.ANNI_DRAW_EXTRA_BAR_ACTIVE)
    progressBar:setBackgroundImage(RES_DICT.ANNI_DRAW_EGG_EXTRA_BAR_GREY)
    progressBar:setAnchorPoint(display.CENTER)
    progressBar:setMaxValue(100)
    progressBar:setValue(100)
    progressBar:setDirection(eProgressBarDirectionLeftToRight)
    progressBar:setPosition(cc.p(251, 32))
    progressBar:setShowValueLabel(true)
    display.commonLabelParams(progressBar:getLabel(),fontWithColor(18))
    extraRewardTipBtn:addChild(progressBar)

    local rightImg = display.newImageView(RES_DICT.RAID_ROOM_ICO_READY, 150, 48)
    extraRewardTipBtn:addChild(rightImg)
    rightImg:setVisible(false)

    local rewardPreviewBtn = display.newButton(belowLayerSize.width / 2 + 190, 52,
    {
        ap = display.CENTER,
        n = RES_DICT.COMMON_BTN_ORANGE,
        scale9 = true, size = cc.size(250, 62),
        enable = true,
    })
    display.commonLabelParams(rewardPreviewBtn, fontWithColor(14, {text = app.anniversaryMgr:GetPoText(__('奖励一览')), color = '#ffffff'}))
    belowLayer:addChild(rewardPreviewBtn)

    actionBtns[tostring(BUTTON_TAG.REWARD_PREVIEW)] = rewardPreviewBtn

    ------------------- below UI end -------------------

    local avatarDialogueLayerViewData = CreateAvatarDialogueLayer()
    view:addChild(avatarDialogueLayerViewData.avatarDialogueLayer)

    local aniLayer = display.newLayer(size.width/2, size.height/2, {ap = display.CENTER})
    view:addChild(aniLayer)

    local ringSpine = sp.SkeletonAnimation:create(
        RES_DICT.RING_SPINE.json,
        RES_DICT.RING_SPINE.atlas,
    1)
    ringSpine:update(0)
    ringSpine:setToSetupPose()
    -- ringSpine:setAnimation(0, 'anni_draw_circle_play9', false)
    -- ringSpine:setAnimation(0, 'play3', false)
    ringSpine:setPosition(cc.p(size.width / 2, size.height / 2))
    -- ringSpine:setScale(0.85)
    aniLayer:addChild(ringSpine)
    ringSpine:setVisible(false)

    local cutinSpine = sp.SkeletonAnimation:create(
        RES_DICT.ANNI_DRAW_CUTIN.json,
        RES_DICT.ANNI_DRAW_CUTIN.atlas,
    1)
    cutinSpine:update(0)
    cutinSpine:setToSetupPose()
    -- cutinSpine:setAnimation(0, 'anni_draw_cutin', true)
    cutinSpine:setPosition(cc.p(size.width / 2, size.height / 2))
    aniLayer:addChild(cutinSpine)
    cutinSpine:setVisible(false)

    local aniTouchView = display.newLayer(0, 0, {color = cc.c4b(_r(255), _r(255), _r(255), _r(255)), enable = true})
    view:addChild(aniTouchView, 10000)
    aniTouchView:setVisible(false)

    local viewData = {
        view                  = view,
        potCells              = potCells,
        belowLayer            = belowLayer,
        actionBtns            = actionBtns,
        moneyNods             = moneyNods,
        extraRewardTipLightBg = extraRewardTipLightBg,
        extraRewardTipLabel   = extraRewardTipLabel,
        progressBar           = progressBar,
        rightImg              = rightImg,

        ringSpine            = ringSpine,
        cutinSpine           = cutinSpine,

        aniTouchView          = aniTouchView,
        -- avatarDialogueLayer            = avatarDialogueLayer,
        -- qAvatar               = qAvatar,
    }

    table.merge(viewData, avatarDialogueLayerViewData)

    return viewData

end

CreateCapsuleBtn = function (conf)
    local po = conf.po
    local capsuleBtn = display.newLayer(conf.po.x, conf.po.y,
    {
        ap = conf.ap,
        color = cc.c4b(0,0,0,0),
        enable = true,
        size = conf.btnSize,
    })

    -- plate img
    local plateImg = display.newNSprite(RES_DICT.ANNI_DRAW_BG_PLATE, 117, 80,
    {
        ap = display.CENTER,
    })
    capsuleBtn:addChild(plateImg)

    capsuleBtn:addChild(display.newNSprite(conf.drawBtnImg, conf.drawBtnImgPo.x, conf.drawBtnImgPo.y, {ap = display.CENTER}))

    local drawTipBtn = display.newButton(120, 60, {n = RES_DICT.ANNI_DRAW_BG_SHADOW})
    display.commonLabelParams(drawTipBtn, fontWithColor(20, {
        text = conf.name,
        ap = display.CENTER,
        fontSize = 24,
        color = '#ffffff',
        outline = '#591f1f'
    }))
    capsuleBtn:addChild(drawTipBtn)

    local labelNumImg = display.newNSprite(RES_DICT.ANNI_DRAW_LABEL_NUM, 121, 23,
    {
        ap = display.CENTER,
    })
    capsuleBtn:addChild(labelNumImg)

    local consumeNumLabel = display.newLabel(133, 22,
    {
        ap = display.RIGHT_CENTER,
        fontSize = 24,
        color = '#ffffff',
        outline = '#591f1f'
    })
    consumeNumLabel:setName('consumeNumLabel')
    capsuleBtn:addChild(consumeNumLabel)

    local consumeCurrencyIcon = display.newNSprite(CommonUtils.GetGoodsIconPathById(app.anniversaryMgr:GetRingGameID()), 132, 25,
    {
        ap = display.LEFT_CENTER,
    })
    consumeCurrencyIcon:setScale(0.25)
    capsuleBtn:addChild(consumeCurrencyIcon)

    return capsuleBtn
end

CreateAvatarDialogueLayer = function ()
    local avatarDialogueLayer = display.newLayer()
    local spineId = 200129
    local changeSkinTable = app.anniversaryMgr.changeSkinTable
    if changeSkinTable then
        spineId = changeSkinTable.capsuleDrawNode
    end
    local qAvatar = AssetsUtils.GetCardSpineNode({confId = spineId, scale = 0.7})
    qAvatar:setName('qAvatar')
    qAvatar:update(0)
    qAvatar:setToSetupPose()
    qAvatar:setPosition(cc.p(display.SAFE_L + 100, 20))
    avatarDialogueLayer:addChild(qAvatar)
    -- qAvatar:setAnimation(0, 'attack', true)
    qAvatar:setVisible(false)

    -- dialogue 
    local dialogueSize = cc.size(592, 180)
    local dialogue = display.newButton(display.SAFE_L + 90, display.cy + 110, 
        {ap = display.LEFT_CENTER, n = RES_DICT.DIALOGUE_BG_2, scale9 = true, size = dialogueSize})
    dialogue:setCascadeOpacityEnabled(true)
    display.commonLabelParams(dialogue, {text = app.anniversaryMgr:GetDialogText().ferruleText, fontSize = 22, color = '#5b3c25', w = 400})
    
    local horn = display.newImageView(app.anniversaryMgr:GetResPath(RES_DICT.DIALOGUE_HORN), 143, -4)
    horn:setRotation(3)
	dialogue:addChild(horn)
    
    avatarDialogueLayer:addChild(dialogue)

    local drawTip = display.newButton(display.cx, 100, {n = RES_DICT.ANNI_DRAW_BG_TEXT, scale9 = true, enable = false})
    display.commonLabelParams(drawTip, fontWithColor(isEfunSdk() and 3 or 7, {w = 506, paddingH = 20, fontSize = 24, text = app.anniversaryMgr:GetDialogText().tipsText}))
    drawTip:setCascadeOpacityEnabled(true)
    avatarDialogueLayer:addChild(drawTip)

    dialogue:setVisible(false)
    drawTip:setVisible(false)

    return {
        avatarDialogueLayer = avatarDialogueLayer,
        qAvatar             = qAvatar,
        dialogue            = dialogue,
        drawTip             = drawTip,
    }
end

--==============================--
--desc: 创建 Cot 动画
--@return
--==============================--
function AnniversaryCapsuleView:CreateCotAnimation()
    -- 添加特效
    local cotAnimation = sp.SkeletonAnimation:create(
        RES_DICT.CAPSULE_SPINE.json,
        RES_DICT.CAPSULE_SPINE.atlas,
        1)
    cotAnimation:update(0)
    cotAnimation:setToSetupPose()
    cotAnimation:setAnimation(0, 'chouka_qian', false)
    cotAnimation:setPosition(display.center)
    -- 结束后移除
    cotAnimation:registerSpineEventHandler(function (event)
        cotAnimation:runAction(cc.RemoveSelf:create())
    end, sp.EventType.ANIMATION_END)
    sceneWorld:addChild(cotAnimation, GameSceneTag.Dialog_GameSceneTag)
end

--==============================--
--desc: 单抽动画
--params stageType int 单抽阶段类型
--       cb        function 回调
--@return
--==============================--
function AnniversaryCapsuleView:drawOneAni(stageType, cb)
    self:stopAllActions()

    local viewData   = self:getViewData()
    local avatarDialogueLayer = viewData.avatarDialogueLayer
    local belowLayer = viewData.belowLayer
    local qAvatar    = viewData.qAvatar
    local dialogue   = viewData.dialogue
    local drawTip    = viewData.drawTip
    local ringSpine = viewData.ringSpine

    if stageType == ONE_DRAW_STAGE_TYPE.RUN_1 then
        qAvatar:setVisible(false)
        qAvatar:setPositionX(display.SAFE_L - 300)
        dialogue:setOpacity(0)
        drawTip:setOpacity(0)
        self:runAction(cc.Sequence:create({
            cc.Spawn:create({
                cc.TargetedAction:create(belowLayer, cc.Spawn:create({
                    cc.FadeOut:create(0.3),
                    cc.MoveTo:create(0.3, cc.p(display.cx, -belowLayer:getContentSize().height - 20))
                })),
                cc.TargetedAction:create(qAvatar, cc.Sequence:create({
                    cc.Show:create(),
                    cc.CallFunc:create(function ()
                        qAvatar:update(0)
                        qAvatar:setToSetupPose()
                        qAvatar:setAnimation(0, 'run', true)
                    end),
                    cc.MoveTo:create(0.6, cc.p(display.SAFE_L + 100, 20)),
                    cc.CallFunc:create(function ()
                        qAvatar:update(0)
                        qAvatar:setToSetupPose()
                        qAvatar:setAnimation(0, 'idle', true)
                        
                    end),
                })),
            }),
            cc.TargetedAction:create(drawTip, cc.Sequence:create({
                cc.Show:create(),
                cc.FadeIn:create(0.5)
            })),
            cc.CallFunc:create(function ()
                if cb then
                    cb()
                end
            end),
            cc.DelayTime:create(5),
            cc.TargetedAction:create(dialogue, cc.Sequence:create({
                cc.Show:create(),
                cc.FadeIn:create(0.5),
                cc.DelayTime:create(3),
                cc.FadeOut:create(0.5),
                cc.Hide:create()
                -- cc.Show:create(),
            })),
            -- cc.TargetedAction:create(avatarDialogueLayer, cc.Spawn:create({
                
            --     cc.TargetedAction:create(drawTip, cc.FadeIn:create(0.5)),
            -- })),
        }))
    elseif stageType == ONE_DRAW_STAGE_TYPE.RUN_2 then
        
        local scene      = uiMgr:GetCurrentScene()
        scene:AddViewForNoTouch()
        -- 设置上一阶段的动画结束状态
        qAvatar:setPosition(cc.p(display.SAFE_L + 100, 20))
        belowLayer:setPosition(cc.p(display.cx, -belowLayer:getContentSize().height - 20))
        
        self:runAction(cc.Sequence:create({
            cc.TargetedAction:create(avatarDialogueLayer, cc.Spawn:create({
                cc.TargetedAction:create(dialogue, cc.FadeOut:create(0.5)),
                cc.TargetedAction:create(drawTip, cc.FadeOut:create(0.5)),
            })),
            cc.CallFunc:create(function ()
                self:setSpineAni(qAvatar, 'attack', false)
            end)
        }))

    end
end

--==============================--
--desc: 九连抽动画
--params cb function 回调
--@return
--==============================--
function AnniversaryCapsuleView:drawNineAni(cb)
    local scene      = uiMgr:GetCurrentScene()
    scene:AddViewForNoTouch()

    local viewData   = self:getViewData()
    local avatarDialogueLayer = viewData.avatarDialogueLayer
    local belowLayer = viewData.belowLayer
    local qAvatar    = viewData.qAvatar
    local dialogue   = viewData.dialogue
    local drawTip    = viewData.drawTip
    local ringSpine = viewData.ringSpine

    qAvatar:setVisible(false)
    qAvatar:setPositionX(display.SAFE_L - 300)
    self:runAction(cc.Sequence:create({
        cc.Spawn:create({
            cc.TargetedAction:create(belowLayer, cc.Spawn:create({
                cc.FadeOut:create(0.3),
                cc.MoveTo:create(0.3, cc.p(display.cx, -belowLayer:getContentSize().height - 20))
            })),
            cc.TargetedAction:create(qAvatar, cc.Sequence:create({
                cc.Show:create(),
                cc.CallFunc:create(function ()
                    qAvatar:update(0)
                    qAvatar:setToSetupPose()
                   qAvatar:setAnimation(0, 'run', true)
                end),
                cc.MoveTo:create(0.6, cc.p(display.SAFE_L + 100, 20)),
                cc.CallFunc:create(function ()
                    local cutinSpine = viewData.cutinSpine
                    cutinSpine:setVisible(true)
                    cutinSpine:setAnimation(0, 'anni_draw_cutin', false)
                    
                end),
            })),
        }),
    }))
end

--==============================--
--desc: 根据下标显示 ring  动画
--params index int 下标
--@return
--==============================--
function AnniversaryCapsuleView:showRingAniByIndex(index)
    local viewData = self:getViewData()
    local ringSpine = viewData.ringSpine
    ringSpine:setVisible(false)

    local potCells = viewData.potCells
    local potSpine  = self:getPotSpineByIndex(potCells, index)
    if potSpine then
        -- potSpine:update(0)
        -- potSpine:setToSetupPose()
        potSpine:setAnimation(0, 'anni_draw_can_play', false)
    end
end

--==============================--
--desc: 根据下标显示 ring trick 动画
--params index int 下标
--@return
--==============================--
function AnniversaryCapsuleView:showRingTrickAniByIndex(index)
    local viewData = self:getViewData()
    local potCells = viewData.potCells
    local potSpine  = self:getPotSpineByIndex(potCells, index)
    if potSpine then
        potSpine:addAnimation(0, 'anni_draw_can_trick', false)
    end
end

--==============================--
--desc: 显示打开罐子动画
--params index  int 下标
--       isRate bool 是否稀有
--@return
--==============================--
function AnniversaryCapsuleView:showOpenPotAniByIndex(index, isRate)
    local viewData = self:getViewData()
    local ringSpine = viewData.ringSpine
    ringSpine:setVisible(false)

    local potCells = viewData.potCells
    local potCell  = potCells[index]
    local potSpine  = self:getPotSpineByIndex(potCells, index)
    if potSpine then
        -- logInfo.add(5, 'showOpenPotAniByIndex = ' .. index )
        -- potSpine:setToSetupPose()
        if checkint(isRate) == 1 then
            potSpine:addAnimation(0, 'anni_draw_can_open2', false)
        else
            potSpine:addAnimation(0, 'anni_draw_can_open1', false)
        end
        -- potSpine:addAnimation(0, 'anni_draw_can_idle', false)
    end
end

--==============================--
--desc: 重置UI初始状态
--params cb  function 回调
--@return
--==============================--
function AnniversaryCapsuleView:resetUIInitStae(cb)
    self:stopAllActions()

    local viewData   = self:getViewData()
    local avatarDialogueLayer = viewData.avatarDialogueLayer
    local belowLayer = viewData.belowLayer
    local qAvatar    = viewData.qAvatar
    local dialogue   = viewData.dialogue
    local drawTip    = viewData.drawTip
    local ringSpine = viewData.ringSpine

    if belowLayer:getPositionY() ~= 0 then
        self:setSpineAni(qAvatar, 'idle', true)
        qAvatar:setPosition(cc.p(display.SAFE_L + 100, 20))
        qAvatar:setVisible(false)

        local potCells = viewData.potCells
        for i = 1, 9 do
            local potSpine = self:getPotSpineByIndex(potCells, i)
            if potSpine then
                potSpine:setToSetupPose()
                potSpine:setAnimation(0, 'anni_draw_can_idle', false)
            end
        end

        self:runAction(cc.Sequence:create({
            cc.TargetedAction:create(avatarDialogueLayer, cc.Spawn:create({
                cc.TargetedAction:create(dialogue, cc.FadeOut:create(0.5)),
                cc.TargetedAction:create(drawTip, cc.FadeOut:create(0.5)),
            })),
            cc.TargetedAction:create(belowLayer, cc.Spawn:create(
                cc.FadeIn:create(0.3),
                cc.MoveTo:create(0.3, cc.p(display.cx, 0))
            )),
            cc.CallFunc:create(function ()
                self:setSpineAni(ringSpine, 'idle', true)
                if cb then
                    cb ()
                end
            end)
        }))
    end
end

--==============================--
--desc: 设置spine 动画
--params spine    userdata spine
--params aniName  string 动画名称
--params isLoop   bool   是否循环
--@return
--==============================--
function AnniversaryCapsuleView:setSpineAni(spine, aniName, isLoop)
    if spine == nil then return end
    -- spine:update(0)
    spine:setToSetupPose()
    spine:setAnimation(0, aniName, isLoop)
end

--==============================--
--desc: 动画全部结束回调
--@return
--==============================--
function AnniversaryCapsuleView:endAniCb()
    local scene = uiMgr:GetCurrentScene()
    scene:RemoveViewForNoTouch()
end

--==============================--
--desc: 根据罐子spine index 获取spine
--params potCells    table 罐子 cells
--params index       int   罐子下标
--@return
--==============================--
function AnniversaryCapsuleView:getPotSpineByIndex(potCells, index)
    local potCell  = potCells[index]
    if potCell then
        return potCell:getChildByName('potSpine')
    end
end

function AnniversaryCapsuleView:getViewData()
    return self.viewData
end

return AnniversaryCapsuleView