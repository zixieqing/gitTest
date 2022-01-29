--[[
 * author : liuzhipeng
 * descpt : 活动 皮肤嘉年华 抽奖活动View
--]]
local ActivitySkinCarnivalLotteryView = class('ActivitySkinCarnivalLotteryView', function ()
    local node = CLayout:create(display.size)
    node.name = 'Game.views.activity.skinCarnival.ActivitySkinCarnivalLotteryView'
    node:enableNodeEvents()
    return node
end)
local CapsuleCommonPrizeNode = require("Game.views.drawCards.CapsuleCommonPrizeNode")
local RES_DICT = {
    BG_ORNAMENT_L          = _res('ui/home/activity/skinCarnival/story_common_bg_diaoshi_1.png'),
    BG_ORNAMENT_R          = _res('ui/home/activity/skinCarnival/story_common_bg_diaoshi_2.png'),
    BG                     = _res('ui/home/activity/skinCarnival/story_cap_bg.png'),
    TITLE_BG               = _res('ui/home/activity/skinCarnival/story_common_bg_head.png'),
    TIPS_ICON              = _res('ui/common/common_btn_tips.png'),
    SWITCH_BTN             = _res('ui/home/activity/skinCarnival/story_common_btn_q.png'),
    SWITCH_BTN_L2D         = _res('ui/home/activity/skinCarnival/story_common_btn_L2D.png'),
    STORY_BTN              = _res('ui/home/activity/skinCarnival/story_common_btn_story.png'),
    STORY_BTN_LOCK_MASK    = _res('ui/home/activity/skinCarnival/story_common_btn_story_lock.png'),
    STORY_BTN_LOCK         = _res('ui/common/common_ico_lock.png'),
    BUY_BTN                = _res('ui/home/activity/skinCarnival/story_cap_btn_buy.png'),
    SKIN_NAME_BG           = _res('ui/home/activity/skinCarnival/story_cap_bg_name.png'),
    SKIN_NAME_LINE         = _res('ui/home/activity/skinCarnival/story_cap_line_name.png'),
    PREVIEW_BTN            = _res('ui/home/capsule/draw_choice_btn.png'),
    CURRENCY_BG            = _res('ui/home/activity/skinCarnival/story_swan_bg_prop.png'),
    CURRENCY_ADD_BTN       = _res('ui/common/common_btn_add.png'),
    COMMON_BTN_WHITE       = _res('ui/common/common_btn_white_default.png'),
    COMMON_BTN_ORANGE      = _res('ui/common/common_btn_orange.png'), 
    REWARD_PROGRESS_BG     = _res('ui/home/activity/skinCarnival/story_swan_line_bg.png'),
    REWARD_PROGRESS_BAR    = _res('ui/home/activity/skinCarnival/story_swan_line_zhong.png'),
    REWARD_PROGRESS_TOP    = _res('ui/home/activity/skinCarnival/story_swan_line_top.png'),
    DRAW_BTN_PRIZE_BG      = _res('ui/home/activity/skinCarnival/story_swan_bg_goods.png'),
    SKIN_GET_BG            = _res('ui/home/activity/skinCarnival/story_swan_bg_get.png'),    
    BUY_BTN_LINE           = _res('ui/home/activity/skinCarnival/story_common_line_buy.png'),
    REMIND_ICON            = _res('ui/common/common_hint_circle_red_ico.png'),
    COMPLETION_TITLE_BG    = _res('ui/home/activity/skinCarnival/story_swan_bg_get_2.png'),
}
function ActivitySkinCarnivalLotteryView:ctor( ... )
    local args = unpack({...})
    self.theme = checkint(args.group)
    self:InitUI()
end
--[[
init ui
--]]
function ActivitySkinCarnivalLotteryView:InitUI()
    local function CreateView()
        -- 背景
        local bg = display.newImageView(RES_DICT.BG, 0, 0)
        local size = bg:getContentSize()
        -- view
        local view = CLayout:create(size)
        bg:setPosition(size.width / 2, size.height / 2)
        view:addChild(bg, 1)
        -- mask
        local mask = CColorView:create(cc.c4b(0, 0, 0, 0))
        mask:setTouchEnabled(true)
        mask:setContentSize(size)
        mask:setPosition(cc.p(size.width / 2, size.height / 2))
        view:addChild(mask, -1)
        -- 标题
        local titleBtn = display.newButton(-10, size.height - 20, {n = RES_DICT.TITLE_BG, ap = display.LEFT_TOP})
        view:addChild(titleBtn, 5)
        local titleLabel = display.newLabel(titleBtn:getContentSize().width / 2 - 20, titleBtn:getContentSize().height / 2, {text = '', fontSize = 24, color = '#ffffff', ttf = true, font = TTF_GAME_FONT, outlineSize = 1, outline = '#622A37'})
        titleBtn:addChild(titleLabel, 1)
        local tipsIcon = display.newImageView(RES_DICT.TIPS_ICON, titleBtn:getContentSize().width - 50, titleBtn:getContentSize().height / 2)
        titleBtn:addChild(tipsIcon, 3)
        -- spine切换按钮
        local switchBtn = display.newButton(60, size.height - 155, {n = RES_DICT.SWITCH_BTN})
        view:addChild(switchBtn, 5)
        -- 剧情按钮
        local storyBtn = display.newButton(60, size.height - 255, {n = RES_DICT.STORY_BTN})
        storyBtn:setVisible(false)
        view:addChild(storyBtn, 5)
        local storyBtnLockMask = display.newImageView(RES_DICT.STORY_BTN_LOCK_MASK, storyBtn:getContentSize().width / 2, storyBtn:getContentSize().height / 2)
        storyBtn:addChild(storyBtnLockMask, 1)
        local storyBtnLock = display.newImageView(RES_DICT.STORY_BTN_LOCK, storyBtnLockMask:getContentSize().width / 2, storyBtnLockMask:getContentSize().height / 2)
        storyBtnLockMask:addChild(storyBtnLock, 1)
        -- 原价购买按钮
        local buyBtn = display.newButton(-10, 35, {n = RES_DICT.BUY_BTN, ap = display.LEFT_BOTTOM})
        buyBtn:setVisible(false)
        view:addChild(buyBtn, 5) 
        local buyBtnLabel = display.newLabel(buyBtn:getContentSize().width / 2, buyBtn:getContentSize().height / 2 + 15, {text = __('原价购买'), fontSize = 22, color = '#784821', ttf = true, font = TTF_GAME_FONT})
        buyBtn:addChild(buyBtnLabel, 1)
        local buyBtnLine = display.newImageView(RES_DICT.BUY_BTN_LINE, buyBtn:getContentSize().width / 2, buyBtn:getContentSize().height / 2)
        buyBtn:addChild(buyBtnLine, 1)
        local buyBtnConsumeRichLabel = display.newRichLabel(buyBtn:getContentSize().width / 2, buyBtn:getContentSize().height / 2 - 15)
        buyBtn:addChild(buyBtnConsumeRichLabel, 1)
        -- 皮肤(不用cardskinDrawNode了，改为切好的图片)
        -- local cardSkinDrawNode = require( "common.CardSkinDrawNode" ).new({confId = CardUtils.DEFAULT_CARD_ID, coordinateType = COORDINATE_TYPE_CAPSULE})
        -- cardSkinDrawNode:setScale(0.7)
        -- cardSkinDrawNode:setPosition(0, 150)
        -- cardSkinDrawNode:setVisible(false)
        -- view:addChild(cardSkinDrawNode, 3)
        local cardSkinDrawNode = display.newImageView('empty', 0, 45, {ap = display.LEFT_BOTTOM})
        view:addChild(cardSkinDrawNode, 3)
        -- 皮肤名称
        local skinNameBg = display.newImageView(RES_DICT.SKIN_NAME_BG, 290, 180)
        skinNameBg:setCascadeOpacityEnabled(true)
        view:addChild(skinNameBg, 5)
        local skinNameLine = display.newImageView(RES_DICT.SKIN_NAME_LINE, skinNameBg:getContentSize().width / 2, skinNameBg:getContentSize().height / 2)
        skinNameBg:addChild(skinNameLine, 1)
        local skinDescrLabel = display.newLabel(skinNameBg:getContentSize().width / 2, skinNameBg:getContentSize().height - 30, {text = '', fontSize = 22, color = '#FFB85D', ttf = true, font = TTF_GAME_FONT, outline = '#56120D', outlineSize = 1})
        skinNameBg:addChild(skinDescrLabel, 1)
        local skinNameLabel = display.newLabel(skinNameBg:getContentSize().width / 2, 30, {text = '', fontSize = 22, color = '#FFEF82', ttf = true, font = TTF_GAME_FONT, outline = '#56120D', outlineSize = 1})
        skinNameBg:addChild(skinNameLabel, 1)

        -- lotteryLayout -- 
        local lotteryLayoutSize = cc.size(650, size.height)
        local lotteryLayout = CLayout:create(lotteryLayoutSize)
        display.commonUIParams(lotteryLayout, {ap = display.RIGHT_CENTER, po = cc.p(size.width - 38, size.height / 2 + 16)})
        view:addChild(lotteryLayout, 3)
        -- 抽卡背景
        local lotteryBg = display.newImageView('empty', lotteryLayoutSize.width + 42, lotteryLayoutSize.height / 2 - 15, {ap = display.RIGHT_CENTER})
        lotteryLayout:addChild(lotteryBg, 1)
        local lotteryTitle = display.newLabel(60, lotteryLayoutSize.height - 115, {text = __('水晶召唤'), fontSize = 24, color = '#61291E', ttf = true, font = TTF_GAME_FONT, ap = display.LEFT_CENTER})
        lotteryLayout:addChild(lotteryTitle, 5)
        -- 抽卡spine
        local lotterySpine = sp.SkeletonAnimation:create(
            string.format('ui/home/activity/skinCarnival/spine/%s/story_swan.json', THEME_SPINE_PATH[tostring(self.theme)]),
            string.format('ui/home/activity/skinCarnival/spine/%s/story_swan.atlas', THEME_SPINE_PATH[tostring(self.theme)]),
            1)
        lotterySpine:setAnimation(0, 'idle', true)
        lotterySpine:setPosition(cc.p(335, 175))
        lotteryLayout:addChild(lotterySpine, 1)
        -- 抽卡特效
        local drawOneEffect = sp.SkeletonAnimation:create(
            string.format('ui/home/activity/skinCarnival/spine/%s/story_swan_effect.json', THEME_SPINE_PATH[tostring(self.theme)]),
            string.format('ui/home/activity/skinCarnival/spine/%s/story_swan_effect.atlas', THEME_SPINE_PATH[tostring(self.theme)]),
            1)
        drawOneEffect:setPosition(cc.p(335, 175))
        drawOneEffect:setVisible(false)
        lotteryLayout:addChild(drawOneEffect, 1)
        if self.theme == SKIN_CASRNIVAL_THEME.FAIRY_TALE then
            -- 粒子效果
            local particle = cc.ParticleSystemQuad:create('ui/home/activity/skinCarnival/spine/fairyTale/story_swan_img_snow.plist')
            particle:setAutoRemoveOnFinish(true)
            particle:setPosition(cc.p(lotteryLayoutSize.width * 0.5, lotteryLayoutSize.height - 170))
            lotteryLayout:addChild(particle, 5)
        end
        -- 奖池预览
        local previewBtn = display.newButton(lotteryLayoutSize.width - 15, lotteryLayoutSize.height - 90, {n = RES_DICT.PREVIEW_BTN, ap = display.RIGHT_TOP})
        previewBtn:setScale(0.6)
        lotteryLayout:addChild(previewBtn, 5)
        display.commonLabelParams(previewBtn, {text = __('奖池一览'), fontSize = 34, color = '#ffffff', ap = display.RIGHT_CENTER, offset = cc.p(160, 0)})
        -- 货币
        local currencyBg = display.newImageView(RES_DICT.CURRENCY_BG, lotteryLayoutSize.width - 100, lotteryLayoutSize.height - 160)
        lotteryLayout:addChild(currencyBg, 1)
        local currencyLabel = display.newLabel(lotteryLayoutSize.width - 60, lotteryLayoutSize.height - 160, {text = '', color = '#ffffff', fontSize = 22, ap = display.RIGHT_CENTER, ttf = true, font = TTF_GAME_FONT})
        lotteryLayout:addChild(currencyLabel, 3)
        local currencyAddBtn = display.newButton(lotteryLayoutSize.width - 35, lotteryLayoutSize.height - 160, {n = RES_DICT.CURRENCY_ADD_BTN})
        lotteryLayout:addChild(currencyAddBtn, 5)
        local currencyIcon = display.newButton(lotteryLayoutSize.width - 165, lotteryLayoutSize.height - 160, {n = CommonUtils.GetGoodsIconPathById(GOLD_ID)})
        currencyIcon:setVisible(false)
        currencyIcon:setScale(0.25)
        lotteryLayout:addChild(currencyIcon, 5)
        -- 召唤按钮
        local btnLayoutSize = cc.size(lotteryLayoutSize.width, 100)
        local btnLayout = CLayout:create(btnLayoutSize)
        -- btnLayout:setVisible(false)
        btnLayout:setPosition(cc.p(lotteryLayoutSize.width / 2, 230))
        lotteryLayout:addChild(btnLayout, 5)
        local drawOneBtn = display.newButton(210, 65, {size = cc.size(160,65),scale9 = true,n = RES_DICT.COMMON_BTN_WHITE})
        display.commonLabelParams(drawOneBtn, fontWithColor(14, {text = __("召唤1次")}))
        btnLayout:addChild(drawOneBtn, 5)
        local drawOneRemindIcon = display.newImageView(RES_DICT.REMIND_ICON, drawOneBtn:getContentSize().width - 3, drawOneBtn:getContentSize().height - 3)
        drawOneBtn:addChild(drawOneRemindIcon, 5)
        local drawOnePrizeBg = display.newImageView(RES_DICT.DRAW_BTN_PRIZE_BG, 210, 20)
        btnLayout:addChild(drawOnePrizeBg, 3)
        local drawOnePrize = display.newLabel(210, 20, {text = '', color = '#61291E', fontSize = 20, ap = display.RIGHT_CENTER, ttf = true, font = TTF_GAME_FONT})
        btnLayout:addChild(drawOnePrize, 5)
        local drawOneGoodsIcon = display.newImageView(CommonUtils.GetGoodsIconPathById(GOLD_ID), 230, 20)
        drawOneGoodsIcon:setScale(0.18)
        btnLayout:addChild(drawOneGoodsIcon, 5)
        local drawTenBtn = display.newButton(btnLayoutSize.width - 180, 65, {size = cc.size(160,65),scale9 = true, n = RES_DICT.COMMON_BTN_ORANGE})
        display.commonLabelParams(drawTenBtn, fontWithColor(14, {text = __("召唤10次")}))
        btnLayout:addChild(drawTenBtn, 5)
        local drawTenRemindIcon = display.newImageView(RES_DICT.REMIND_ICON, drawTenBtn:getContentSize().width - 3, drawTenBtn:getContentSize().height - 3)
        drawTenBtn:addChild(drawTenRemindIcon, 5)
        local drawTenPrizeBg = display.newImageView(RES_DICT.DRAW_BTN_PRIZE_BG, btnLayoutSize.width - 180, 20)
        btnLayout:addChild(drawTenPrizeBg, 3)
        local drawTenPrize = display.newLabel(btnLayoutSize.width - 180, 20, {text = '', color = '#61291E', fontSize = 20, ap = display.RIGHT_CENTER, ttf = true, font = TTF_GAME_FONT})
        btnLayout:addChild(drawTenPrize, 5)
        local drawTenGoodsIcon = display.newImageView(CommonUtils.GetGoodsIconPathById(GOLD_ID), btnLayoutSize.width - 160, 20)
        drawTenGoodsIcon:setScale(0.18)
        btnLayout:addChild(drawTenGoodsIcon, 5)
        -- 已获得提示
        -- local skinGetBg = display.newImageView(RES_DICT.SKIN_GET_BG, lotteryLayoutSize.width / 2, 225)
        -- skinGetBg:setVisible(false)
        -- lotteryLayout:addChild(skinGetBg, 5)
        -- local skinGetTextLabel = display.newLabel(skinGetBg:getContentSize().width / 2, skinGetBg:getContentSize().height / 2, {text = __('召唤已结束'), fontSize = 24, color = '#61291E', ttf = true, font = TTF_GAME_FONT})
        -- skinGetBg:addChild(skinGetTextLabel, 1)
        -- lotteryLayout --

        -- rewardLayout --
        local rewardLayoutSize = lotteryLayoutSize
        local rewardLayout = CLayout:create(rewardLayoutSize)
        rewardLayout:setPosition(cc.p(rewardLayoutSize.width / 2, rewardLayoutSize.height / 2))
        rewardLayout:setVisible(false)
        lotteryLayout:addChild(rewardLayout, 5)
        -- 累计奖励
        local rewardDescrLabel = display.newLabel(lotteryLayoutSize.width / 2-40, 130, {text = '', color = '#61291E', fontSize = 19, w = 440, hAlign = cc.TEXT_ALIGNMENT_CENTER})
        rewardLayout:addChild(rewardDescrLabel, 5)
        local rewardProgressBar = CProgressBar:create(RES_DICT.REWARD_PROGRESS_BAR)
        rewardProgressBar:setBackgroundImage(RES_DICT.REWARD_PROGRESS_BG)
        rewardProgressBar:setDirection(eProgressBarDirectionLeftToRight)
        rewardProgressBar:setPosition(rewardLayoutSize.width / 2 - 10, 75)
        rewardLayout:addChild(rewardProgressBar, 3)
        local rewardPorgressTop = display.newImageView(RES_DICT.REWARD_PROGRESS_TOP, rewardLayoutSize.width / 2 - 10, 75)
        rewardLayout:addChild(rewardPorgressTop, 4)
        local rewardProgressBarLabel = display.newLabel(rewardLayoutSize.width / 2 - 10, 75, {text = '', fontSize = 20, color = '#ffffff'})
        rewardLayout:addChild(rewardProgressBarLabel, 5)
        local rewardGoodsNode = require('common.GoodNode').new({
			id = GOLD_ID,
			callBack = function () end
        })
        display.commonUIParams(rewardGoodsNode, {po = cc.p(rewardLayoutSize.width - 85, 110)})
        rewardGoodsNode:setScale(0.9)
        rewardGoodsNode:setVisible(false)
        rewardLayout:addChild(rewardGoodsNode, 5)
        local rewardRemindIcon = display.newImageView(RES_DICT.REMIND_ICON, rewardGoodsNode:getContentSize().width - 3, rewardGoodsNode:getContentSize().height - 3)
        rewardRemindIcon:setVisible(false)
        rewardGoodsNode:addChild(rewardRemindIcon, 100)
        -- rewardLayout --

        -- completionLayout --
        local completionLayoutSize = lotteryLayoutSize
        local completionLayout = CLayout:create(completionLayoutSize)
        completionLayout:setPosition(cc.p(completionLayoutSize.width / 2, completionLayoutSize.height / 2))
        completionLayout:setVisible(false)
        lotteryLayout:addChild(completionLayout, 5)
        -- 标题
        local completionTitleBg = display.newImageView(RES_DICT.COMPLETION_TITLE_BG, completionLayoutSize.width / 2 + 5, 110)
        completionLayout:addChild(completionTitleBg, 1)
        local completionTitleLabel = display.newLabel(completionTitleBg:getContentSize().width / 2, completionTitleBg:getContentSize().height / 2, {text = __('外观已获得'), color = '#E1BEA1', fontSize = 22})
        completionTitleBg:addChild(completionTitleLabel, 1)
        -- completionLayout -- 
        return {
            view                   = view,
            titleLabel             = titleLabel,
            titleBtn               = titleBtn,
            switchBtn              = switchBtn,
            storyBtn               = storyBtn,
            storyBtnLockMask       = storyBtnLockMask,
            buyBtn                 = buyBtn,
            buyBtnConsumeRichLabel = buyBtnConsumeRichLabel,
            cardSkinDrawNode       = cardSkinDrawNode,
            skinDescrLabel         = skinDescrLabel,
            skinNameLabel          = skinNameLabel,
            skinNameBg             = skinNameBg,
            previewBtn             = previewBtn,
            currencyLabel          = currencyLabel,
            currencyAddBtn         = currencyAddBtn,
            currencyIcon           = currencyIcon,
            drawOneBtn             = drawOneBtn,
            drawOnePrize           = drawOnePrize,
            drawOneGoodsIcon       = drawOneGoodsIcon,
            drawTenBtn             = drawTenBtn,
            drawTenPrize           = drawTenPrize,
            drawTenGoodsIcon       = drawTenGoodsIcon,
            rewardProgressBar      = rewardProgressBar,
            rewardProgressBarLabel = rewardProgressBarLabel,
            rewardGoodsNode        = rewardGoodsNode,
            -- skinGetBg              = skinGetBg,     
            btnLayout              = btnLayout,  
            drawOneEffect          = drawOneEffect,
            lotteryBg              = lotteryBg,  
            rewardDescrLabel       = rewardDescrLabel,
            rewardLayout           = rewardLayout,
            completionLayout       = completionLayout,
            -- remindIcon
            rewardRemindIcon       = rewardRemindIcon,
            drawOneRemindIcon      = drawOneRemindIcon,
            drawTenRemindIcon      = drawTenRemindIcon,
        }
    end
    -- eaterLayer
    local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 255 * 0.6))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    self:addChild(eaterLayer, -1)
    self.eaterLayer = eaterLayer
    if self.theme == SKIN_CASRNIVAL_THEME.FAIRY_TALE then
        -- 装饰品
        local bgOrnamentL = display.newImageView(RES_DICT.BG_ORNAMENT_L, display.cx - 700, display.cy + 700, {ap = display.CENTER_TOP})
        self:addChild(bgOrnamentL, -1)
        self.bgOrnamentL = bgOrnamentL
        local bgOrnamentR = display.newImageView(RES_DICT.BG_ORNAMENT_R, display.cx + 640, display.cy + 700, {ap = display.CENTER_TOP})
        self:addChild(bgOrnamentR, -1)
        self.bgOrnamentR = bgOrnamentR
    end
    xTry(function ( )
        self.viewData = CreateView( )
        self:addChild(self.viewData.view)
        self.viewData.view:setPosition(display.center)
        self.viewData.view:setOpacity(0)
    end, __G__TRACKBACK__)
end
--[[
进入动画
@params pos pos 动画起始坐标
--]]
function ActivitySkinCarnivalLotteryView:EnterAction( pos )
    local viewData = self:GetViewData()
    viewData.view:setPosition(pos)
    viewData.view:setScale(0)
    local spawnAct = {
        cc.FadeIn:create(0.2),
        cc.MoveTo:create(0.2, display.center),
        cc.ScaleTo:create(0.2, 1)
    }
    if self.theme == SKIN_CASRNIVAL_THEME.FAIRY_TALE then
        table.insert(spawnAct, cc.TargetedAction:create(self.bgOrnamentL, cc.EaseBackOut:create(cc.MoveBy:create(0.2, cc.p(0, - 200)))))
        table.insert(spawnAct, cc.TargetedAction:create(self.bgOrnamentR, cc.EaseBackOut:create(cc.MoveBy:create(0.2, cc.p(0, - 200)))))
    end
    viewData.view:runAction(
        cc.Sequence:create(
            cc.Spawn:create(spawnAct),
            cc.CallFunc:create(function()
                app.uiMgr:GetCurrentScene():RemoveViewForNoTouch()
            end)
        )
    )
end
--[[
返回动画
--]]
function ActivitySkinCarnivalLotteryView:BackAction( pos )
    local viewData = self:GetViewData()
    -- 屏蔽所有点击事件
    app.uiMgr:GetCurrentScene():AddViewForNoTouch()
    local spawnAct = {
        cc.FadeOut:create(0.2),
        cc.MoveTo:create(0.2, pos),
        cc.ScaleTo:create(0.2, 0)
    }
    if self.theme == SKIN_CASRNIVAL_THEME.FAIRY_TALE then
        table.insert(spawnAct, cc.TargetedAction:create(self.bgOrnamentL, cc.EaseBackIn:create(cc.MoveBy:create(0.2, cc.p(0, 200)))))
        table.insert(spawnAct, cc.TargetedAction:create(self.bgOrnamentR, cc.EaseBackIn:create(cc.MoveBy:create(0.2, cc.p(0, 200)))))
    end
    viewData.view:runAction(
        cc.Sequence:create(
            cc.Spawn:create(spawnAct),
            cc.CallFunc:create(function()
                app:DispatchObservers(ACTIVITY_SKIN_CARNIVAL_BACK_HOME)
                app:UnRegsitMediator('activity.skinCarnival.ActivitySkinCarnivalLotteryMediator')
            end)
        )
    )
end
--[[
刷新标题
@params title string 标题
--]]
function ActivitySkinCarnivalLotteryView:RefreshTitle( title )
    local viewData = self:GetViewData()
    viewData.titleLabel:setString(tostring(title))
end
--[[
刷新皮肤购买消耗
@params consume map {
    goodsId int 道具id
    num     int 数量
}
--]]
function ActivitySkinCarnivalLotteryView:RefreshBuyBtnConsumeRichlabel( consume )
    local viewData = self:GetViewData()
    display.reloadRichLabel(viewData.buyBtnConsumeRichLabel, {c = {
        {text = consume.num, fontSize = 22, color = '#FFEF82', ttf = true, font = TTF_GAME_FONT, outline = '#56120D', outlineSize = 2},
        {img = CommonUtils.GetGoodsIconPathById(consume.goodsId), scale = 0.18},
    }})
    CommonUtils.AddRichLabelTraceEffect(viewData.buyBtnConsumeRichLabel, '#56120D', 2, {1})
end
--[[
刷新奖励描述
@params targetNum int 目标数量
@params skinId int 皮肤id
--]]
function ActivitySkinCarnivalLotteryView:RefreshRewardDescrLabel( targetNum, skinId )
    local viewData = self:GetViewData()
    local skinConfig = CardUtils.GetCardSkinConfig(skinId)
    local cardConfig = CardUtils.GetCardConfig(skinConfig.cardId)
    viewData.rewardDescrLabel:setString(string.fmt(__('水晶召唤累计_num1_次可获得_name1_外观-_name2_'), {['_num1_'] = targetNum, ['_name1_'] = cardConfig.name, ['_name2_'] = skinConfig.name}))
end
--[[
刷新皮肤节点
@params skinId int 皮肤id
@params effect string 皮肤spine特效
--]]
function ActivitySkinCarnivalLotteryView:RefreshSkinDrawNode( skinId, effect )
    local viewData = self:GetViewData()
    -- viewData.cardSkinDrawNode:RefreshAvatar({skinId = skinId})
    -- viewData.cardSkinDrawNode:setVisible(true)
    viewData.cardSkinDrawNode:setTexture(__(string.format('ui/home/activity/skinCarnival/skinImg/story_skin_%d.png', checkint(skinId))))
    if CardUtils.IsShowCardLive2d(skinId) then
        viewData.switchBtn:setNormalImage(RES_DICT.SWITCH_BTN_L2D)
        viewData.switchBtn:setSelectedImage(RES_DICT.SWITCH_BTN_L2D)
    else
        viewData.switchBtn:setNormalImage(RES_DICT.SWITCH_BTN)
        viewData.switchBtn:setSelectedImage(RES_DICT.SWITCH_BTN)
    end
    local skinConfig = CardUtils.GetCardSkinConfig(skinId)
    local cardConfig = CardUtils.GetCardConfig(skinConfig.cardId)
    viewData.skinDescrLabel:setString(string.fmt(__('_name_外观'), {['_name_'] = cardConfig.name}))
    viewData.skinNameLabel:setString(skinConfig.name)
    -- 判断是否需要添加皮肤特效spine
    if effect and effect ~= '' then
        if viewData.view:getChildByName('skinEffect') then
            viewData.view:getChildByName('skinEffect'):runAction(cc.RemoveSelf:create())
        end
        local skinEffectSpine = sp.SkeletonAnimation:create(
            string.format('ui/home/activity/skinCarnival/spineEffect/%s.json', effect),
            string.format('ui/home/activity/skinCarnival/spineEffect/%s.atlas', effect),
        1)
        skinEffectSpine:setAnimation(0, 'play', true)
        skinEffectSpine:setName('skinEffect')
        skinEffectSpine:setPosition(cc.p(280, 320))
        viewData.view:addChild(skinEffectSpine, 3)
    end
    -- 刷新列表背景
    local bgSkinId = skinId
    if not utils.isExistent(__(string.format('ui/home/activity/skinCarnival/listBg/story_list_bg_%d.png', checkint(bgSkinId)))) then
        bgSkinId = 250244
    end
    viewData.lotteryBg:setTexture(__(string.format('ui/home/activity/skinCarnival/listBg/story_list_bg_%d.png', checkint(bgSkinId))))
end
--[[
刷新按钮状态
@params hasSkin bool 是否拥有皮肤
@params canDraw bool 任务奖励是否可领取
@params skinId  int  皮肤Id
--]]
function ActivitySkinCarnivalLotteryView:RefreshBtnState( hasSkin, canDraw, skinId )
    local viewData = self:GetViewData()
    viewData.storyBtn:setVisible(true)
    if hasSkin then
        viewData.storyBtnLockMask:setVisible(false)
        viewData.buyBtn:setVisible(false)
        -- viewData.skinGetBg:setVisible(true)
        -- viewData.btnLayout:setVisible(false)
        viewData.rewardLayout:setVisible(false)
        viewData.completionLayout:setVisible(true)
        return 
    end
    viewData.storyBtnLockMask:setVisible(true)
    viewData.buyBtn:setVisible(true)
    -- viewData.skinGetBg:setVisible(false)
    -- viewData.btnLayout:setVisible(true)
    viewData.rewardLayout:setVisible(true)
    viewData.completionLayout:setVisible(false)
    if canDraw then
        viewData.rewardGoodsNode:RefreshSelf({goodsId = skinId, highlight = 1})
    else
        viewData.rewardGoodsNode:RefreshSelf({goodsId = skinId})
    end
end
--[[
展示卡牌皮肤
--]]
function ActivitySkinCarnivalLotteryView:ShowCardSkin()
    local viewData = self:GetViewData()
    viewData.cardSkinDrawNode:setVisible(true)
end
--[[
刷新抽奖货币
@params goodsId int 抽奖消耗的道具id
@params cost    int 抽奖一次所需的道具数量
--]]
function ActivitySkinCarnivalLotteryView:RefreshLotteryCurrency( goodsId, cost )
    local viewData = self:GetViewData()
    local iconPath = CommonUtils.GetGoodsIconPathById(checkint(goodsId))
    viewData.currencyLabel:setString(app.gameMgr:GetAmountByIdForce(checkint(goodsId)))
    viewData.currencyIcon:setVisible(true)
    viewData.currencyIcon:setNormalImage(CommonUtils.GetGoodsIconPathById(checkint(goodsId)))
    viewData.currencyIcon:setSelectedImage(CommonUtils.GetGoodsIconPathById(checkint(goodsId)))
    viewData.drawOneGoodsIcon:setTexture(iconPath)
    viewData.drawOnePrize:setString(tostring(cost))
    viewData.drawTenGoodsIcon:setTexture(iconPath)
    viewData.drawTenPrize:setString(tostring(checkint(cost) * 10))
end
--[[
刷新奖励道具节点
@params skinId int 皮肤id
--]]
function ActivitySkinCarnivalLotteryView:RefreshRewardGoodsNode( skinId )
    local viewData = self:GetViewData()
    viewData.rewardGoodsNode:setVisible(true)
    viewData.rewardGoodsNode:RefreshSelf({goodsId = skinId})
end
--[[
刷新奖励进度条
@params lotteryNum int 抽奖次数
@params targetNum  int 目标次数
--]]
function ActivitySkinCarnivalLotteryView:RefreshRewardProgressBar( lotteryNum, targetNum )
    local viewData = self:GetViewData()
    viewData.rewardProgressBar:setMaxValue(checkint(targetNum))
    viewData.rewardProgressBar:setValue(checkint(lotteryNum))
    viewData.rewardProgressBarLabel:setString(string.format('%d/%d', math.min(lotteryNum, targetNum), targetNum))
end
--[[
显示抽一次特效
@params num int 抽奖次数
--]]
function ActivitySkinCarnivalLotteryView:ShowDrawOneEffect( num )
    app.uiMgr:GetCurrentScene():AddViewForNoTouch()
    local viewData = self:GetViewData()
    viewData.drawOneEffect:setVisible(true)
    viewData.drawOneEffect:update(0)
    viewData.drawOneEffect:setToSetupPose()
    if num == 1 then
        viewData.drawOneEffect:addAnimation(0, 'play_1', false)
    elseif num == 10 then
        viewData.drawOneEffect:addAnimation(0, 'play_10', false)
    end  
end
--[[
隐藏抽一次特效
--]]
function ActivitySkinCarnivalLotteryView:HideDrawOneEffect()
    app.uiMgr:GetCurrentScene():RemoveViewForNoTouch()
    local viewData = self:GetViewData()
    viewData.drawOneEffect:setVisible(false)
end
--[[
刷新抽奖按钮小红点
@params drawOneState bool 抽奖一次红点状态
@params drawTenState bool 抽奖十次红点状态
--]]
function ActivitySkinCarnivalLotteryView:RefreshDrawRemindIcon( drawOneState, drawTenState )
    local viewData = self:GetViewData()
    viewData.drawOneRemindIcon:setVisible(drawOneState)
    viewData.drawTenRemindIcon:setVisible(drawTenState)
end
--[[
刷新奖励小红点
@params state bool 
--]]
function ActivitySkinCarnivalLotteryView:RefreshRewardRemindIcon( state )
    local viewData = self:GetViewData()
    viewData.rewardRemindIcon:setVisible(state)
end
--[[
获取viewData
--]]
function ActivitySkinCarnivalLotteryView:GetViewData()
    return self.viewData
end
return ActivitySkinCarnivalLotteryView