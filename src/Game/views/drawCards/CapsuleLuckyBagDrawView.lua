--[[
福袋抽卡领奖view
--]]
local CapsuleLuckyBagDrawView = class('CapsuleLuckyBagDrawView', function ()
    local node = CLayout:create(display.size)
    node.name = 'home.CapsuleLuckyBagDrawView'
    node:enableNodeEvents()
    return node
end)
local RES_DICT = {
    TITLE_TEXT      = _res('ui/common/common_words_congratulations.png'),
    TITLE_LIGHT     = _res('ui/common/common_reward_light.png'),
    BOTTOM_BG       = _res('ui/home/capsuleNew/luckyBag/summon_luck_bag_bg_card.png'),
    BG_MASK         = _res('ui/home/capsuleNew/luckyBag/summon_luck_bag_bg_mask.png'),
    BG              = _res('ui/home/capsule/draw_card_bg_new.jpg'),
    CARD_BG         = _res('ui/home/capsuleNew/luckyBag/summon_luck_bag_bg_card_below.png'),
    CARD_SELECT_BG  = _res('ui/home/capsuleNew/luckyBag/summon_luck_bag_bg_card_slected.png'),
    CARD_REPLACE_BG = _res('ui/home/capsuleNew/luckyBag/summon_luck_bag_bg_replace.png'),
    SKIP_BTN        = _res('arts/stage/ui/opera_btn_skip.png'),
    REFRESH_BTN     = _res('ui/home/commonShop/shop_btn_refresh.png'),
    COMMON_BTN      = _res('ui/common/common_btn_orange.png'),
    EFFACT_SPINE    = _spn('ui/home/capsuleNew/luckyBag/effect/fudai_chouka'),

}
local GOODS_ACTION_DATA = {
    {delaTime = 16/30, pos = cc.p(display.cx - 558, 90.5), time = 20/30, bgTag = 1},
    {delaTime = 18/30, pos = cc.p(display.cx - 310, 90.5), time = 20/30, bgTag = 3},
    {delaTime = 20/30, pos = cc.p(display.cx - 62 , 90.5), time = 20/30, bgTag = 5},
    {delaTime = 19/30, pos = cc.p(display.cx + 186, 90.5), time = 20/30, bgTag = 7},
    {delaTime = 17/30, pos = cc.p(display.cx + 434, 90.5), time = 20/30, bgTag = 9},
    {delaTime = 22/30, pos = cc.p(display.cx - 434, 90.5), time = 15/30, bgTag = 2},
    {delaTime = 24/30, pos = cc.p(display.cx - 186, 90.5), time = 15/30, bgTag = 4},
    {delaTime = 25/30, pos = cc.p(display.cx + 62 , 90.5), time = 15/30, bgTag = 6},
    {delaTime = 23/30, pos = cc.p(display.cx + 310, 90.5), time = 15/30, bgTag = 8},
    {delaTime = 21/30, pos = cc.p(display.cx + 558, 90.5), time = 15/30, bgTag = 10},
}
function CapsuleLuckyBagDrawView:ctor( ... )
    self.goodsNodeList = {}
    self:InitUI()
end
--[[
init ui
--]]
function CapsuleLuckyBagDrawView:InitUI()
    local function CreateView()
        local size = display.size
        local view = CLayout:create(size)
        local bg = display.newImageView(RES_DICT.BG, size.width / 2, size.height / 2)
        view:addChild(bg, -1)
        local maskLayer = display.newLayer(size.width / 2, size.height / 2, {ap = display.CENTER, size = size, color = cc.c4b(0, 0, 0, 255 * 0.6) ,enable = true})
        view:addChild(maskLayer, -1)
        local bgLayer = display.newLayer(size.width / 2, size.height / 2, {size = size, ap = display.CENTER})
        view:addChild(bgLayer, 1)
        local swallView = display.newLayer(size.width / 2, size.height / 2,{ ap = display.CENTER , size = cc.size(900 ,300),  color = cc.c4b(0,0,0,0) ,enable = true})
        bgLayer:addChild(swallView, -1)
        local rewardSpine = CommonUtils.GetRrawRewardsSpineAnimation()
        rewardSpine:setToSetupPose()
        rewardSpine:setAnimation(0, 'play', false)
        rewardSpine:setPosition(display.center)
        bgLayer:addChild(rewardSpine, 2)

        local rewardImage = display.newImageView(RES_DICT.TITLE_TEXT, size.width / 2,  display.height+94.6-110)
        bgLayer:addChild(rewardImage, 3)
        local lightCircle = display.newImageView(RES_DICT.TITLE_LIGHT, size.width / 2, display.cy+300-15-110)
        lightCircle:setVisible(false)
        bgLayer:addChild(lightCircle, 1)

        local bottomBg = display.newImageView(RES_DICT.BOTTOM_BG, 0, 0)
        local bottomLayerSize = bottomBg:getContentSize()
        local bottomLayer = display.newLayer(size.width / 2, - 140, {size = bottomLayerSize, ap = cc.p(0.5, 0)})
        view:addChild(bottomLayer, 4)
        bottomBg:setPosition(cc.p(bottomLayer:getContentSize().width / 2, bottomLayer:getContentSize().height / 2))
        bottomLayer:addChild(bottomBg, 1)
        local bottomLabel = display.newLabel(bottomLayerSize.width / 2, bottomLayerSize.height - 30, {text = __('更多的换卡机会'), fontSize = 24, color = '#fff7e7'})
        bottomLayer:addChild(bottomLabel, 1)
        local cardBgLayoutSize = cc.size(1240, 106)
        local cardBgLayout = CLayout:create(cardBgLayoutSize)
        cardBgLayout:setPosition(cc.p(bottomLayerSize.width / 2, bottomLayerSize.height / 2))
        bottomLayer:addChild(cardBgLayout, 2)
        cardBgLayout:setVisible(false)
        local cardSelectBgList = {}
        for i = 1, 10 do
            local cardBg = display.newImageView(RES_DICT.CARD_BG, i * (cardBgLayoutSize.width / 10) - 62.5, 44, {ap = cc.p(0.5, 0.5)})
            cardBg:setScale(0.88)
            cardBgLayout:addChild(cardBg, 1)
            local selectBg = display.newImageView(RES_DICT.CARD_SELECT_BG, i * (cardBgLayoutSize.width / 10) - 62.5, 44)
            selectBg:setVisible(false)
            cardBgLayout:addChild(selectBg, 2)
            table.insert(cardSelectBgList, selectBg)
        end

        local replaceLayer = display.newLayer(size.width / 2, size.height / 2, {size = size, ap = display.CENTER})
        view:addChild(replaceLayer, 3)
        replaceLayer:setVisible(false)
        local taskListSize = cc.size(690, 560)
        local gridView = CTableView:create(taskListSize)
        gridView:setSizeOfCell(cc.size(230, 560))
        gridView:setAutoRelocate(true)
        gridView:setDirection(eScrollViewDirectionHorizontal)
        replaceLayer:addChild(gridView, 2)
        gridView:setAnchorPoint(display.CENTER)
        gridView:setDragable(false)
        gridView:setPosition(cc.p(size.width / 2 - 14, size.height / 2 + 60))

        local bgMask = display.newImageView(RES_DICT.BG_MASK, size.width / 2, display.cy - 40, {ap = cc.p(0.5, 1)})
        replaceLayer:addChild(bgMask, 5)

        local rewardLayer = display.newLayer(size.width / 2, size.height / 2, {size = size, ap = display.CENTER})
        view:addChild(rewardLayer, 10)
        
        local buttonLayer = display.newLayer(size.width / 2, size.height / 2, {size = size, ap = display.CENTER})
        buttonLayer:setVisible(false)
        view:addChild(buttonLayer, 7)
        local skipBtn = display.newButton(size.width - display.SAFE_L, size.height - 55, {n = RES_DICT.SKIP_BTN, ap = cc.p(1, 0.5)})
        skipBtn:setScale(1)
        buttonLayer:addChild(skipBtn, 1)
        local skipLabel = display.newLabel(skipBtn:getContentSize().width - 25, skipBtn:getContentSize().height / 2, {text = __('跳过'), fontSize = 24, color = '#ffffff', ap = display.RIGHT_CENTER ,  font = TTF_GAME_FONT, ttf = true, outline = '#4e2e1e', outlineSize = 2})
        skipBtn:addChild(skipLabel, 1)
        local refreshBtn = display.newButton(size.width - display.SAFE_L - 45, 250, {n = RES_DICT.REFRESH_BTN})
        buttonLayer:addChild(refreshBtn, 1)
        local refreshLabel = display.newLabel(size.width - display.SAFE_L - 78, 260, {text = __('刷新次数'), fontSize = 22, color = '#d19b81', ap = cc.p(1, 0.5)})
        buttonLayer:addChild(refreshLabel, 1)
        local refreshTimesLabel = display.newLabel(size.width - display.SAFE_L - 78, 234, {text = '', fontSize = 22, color = '#ffffff', ap = cc.p(1, 0.5)})
        buttonLayer:addChild(refreshTimesLabel, 1)

        local replaceBgList = {}
        local replaceBtnList = {}
        local replaceEffectList = {}
        for i = 1, 3 do
            local bg = display.newImageView(RES_DICT.CARD_REPLACE_BG, size.width / 2 - 460 + (i * 230), size.height / 2 + 55)
            replaceLayer:addChild(bg, 1)
            table.insert(replaceBgList, bg)
            local replaceBtn = display.newButton(size.width / 2 - 460 + (i * 230), size.height / 2 - 140, {n = RES_DICT.COMMON_BTN})
            replaceBtn:setTag(i)
            replaceBtn:setVisible(false)
            buttonLayer:addChild(replaceBtn, 1)
            display.commonLabelParams(replaceBtn ,fontWithColor('14', {text = __('替换')}))
            table.insert(replaceBtnList, replaceBtn)
            local effectSpn = sp.SkeletonAnimation:create(RES_DICT.EFFACT_SPINE.json, RES_DICT.EFFACT_SPINE.atlas, 1)
            effectSpn:setPosition(cc.p(size.width / 2 - 460 + (i * 230), size.height / 2 + 80))
            replaceLayer:addChild(effectSpn, 10)
            effectSpn:setVisible(false)
            effectSpn:registerSpineEventHandler(
                function (event)
                    if event.animation == 'idle2' then
                        effectSpn:setVisible(false)
                    end
                end,
                sp.EventType.ANIMATION_END
            )
            table.insert(replaceEffectList, effectSpn)
        end
        return {
            view             = view,
            size             = size,
            rewardImage      = rewardImage,
            lightCircle      = lightCircle, 
            bottomLayer      = bottomLayer,
            cardBgLayout     = cardBgLayout,
            replaceLayer     = replaceLayer,
            gridView         = gridView,
            rewardLayer      = rewardLayer,
            maskLayer        = maskLayer,
            bgLayer          = bgLayer,
            buttonLayer      = buttonLayer,
            bgMask           = bgMask,
            skipBtn          = skipBtn,
            refreshBtn       = refreshBtn,
            cardSelectBgList = cardSelectBgList,
            replaceBgList    = replaceBgList,
            replaceBtnList   = replaceBtnList,
            replaceEffectList = replaceEffectList,
            refreshTimesLabel = refreshTimesLabel,

        }
    end
    xTry(function ( )
        local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 0))
        eaterLayer:setContentSize(display.size)
        eaterLayer:setTouchEnabled(true)
        eaterLayer:setPosition(utils.getLocalCenter(self))
        self.eaterLayer = eaterLayer
        self:addChild(eaterLayer, -1)
        self.viewData = CreateView( )
        self:addChild(self.viewData.view)
        self.viewData.view:setPosition(display.center)
    end, __G__TRACKBACK__)
end
--[[
开始领奖动画
@params rewards         list 奖励
@patams maxReplaceTimes int  最大替换卡牌刷新次数
--]]
function CapsuleLuckyBagDrawView:StartDrawAction( rewards, maxReplaceTimes )
    local viewData = self.viewData
    local rewardPoint_one = cc.p(display.cx ,  display.cy+300-35.5-110)
    local rewardPoint_Two = cc.p(display.cx ,  display.cy+300+24-110)
    local rewardPoint_Three = cc.p(display.cx ,  display.cy+300-15-110)
    local rewardPoint_Four = cc.p(display.cx ,  display.cy+300-15-110)
    app.uiMgr:GetCurrentScene():AddViewForNoTouch()
    viewData.rewardImage:setOpacity(0)
    viewData.rewardImage:runAction(
        cc.Sequence:create( 
            cc.DelayTime:create(0.3) ,
            cc.Spawn:create(cc.FadeIn:create(0.2),cc.MoveTo:create(0.2,rewardPoint_one)),
            cc.JumpTo:create(0.1,rewardPoint_Two, 10, 1),
            cc.MoveTo:create(0.1,rewardPoint_Three),
            cc.MoveTo:create(0.1,rewardPoint_Four),
            cc.DelayTime:create(0.3),
            cc.CallFunc:create(function ()
                app.uiMgr:GetCurrentScene():RemoveViewForNoTouch()
            end)
        )
    )
    viewData.lightCircle:setOpacity(0)
    viewData.lightCircle:runAction(
        cc.Sequence:create( 
            cc.DelayTime:create(0.3) ,
            cc.Show:create(),
            cc.FadeIn:create(0.25),
            cc.CallFunc:create(function ()
                PlayAudioClip(AUDIOS.UI.ui_mission.id)
                viewData.lightCircle:stopAllActions()
                viewData.lightCircle:runAction(cc.RepeatForever:create(cc.Spawn:create(cc.Sequence:create(cc.FadeTo:create(2.25,100),cc.FadeTo:create(2.25,255)), cc.RotateBy:create(4.5,180))))
            end)
        )
    )
    self:AddRewardGoods(rewards)
end
--[[
添加奖励道具
--]]
function CapsuleLuckyBagDrawView:AddRewardGoods( rewards )
    if not rewards then return end
    local rewardLayer = self.viewData.rewardLayer
    local size = self.viewData.size 
    self.goodsNodeList = {}
    for i, v in ipairs(rewards) do
        local goodsNode = self:CreateGoods(rewards[i],0.05*i+ 0.4, i)
        if i <= 5 then
            goodsNode:setPosition(cc.p(size.width / 2 + ((i - 3) * 105), size.height / 2 - 100))
        else
            goodsNode:setPosition(cc.p(size.width / 2 + ((i - 5 - 3) * 105), size.height / 2 - 210))
        end
        table.insert(self.goodsNodeList, goodsNode)
        rewardLayer:addChild(goodsNode)
    end
end
--[[
创建道具
@params data      map 道具数据
@params delayTime int 动画延时
@params tag       int 序号
--]]
function CapsuleLuckyBagDrawView:CreateGoods( data, delayTime, tag )
    local goodsNode = self:CreateGoodsNode({goodsId = data.goodsId, goodsNum = data.num, showAmount = true})
    goodsNode:setTag(checkint(tag))
	goodsNode:setScale(0.8)
	goodsNode:setOpacity(0)
	local seqTable = {}
	local fadeIn = cc.FadeIn:create(0.25) 
	local jumpBy = cc.JumpBy:create(0.25,cc.p(0,150),60,1)
	local spawn = cc.Spawn:create(jumpBy,fadeIn)
	seqTable[#seqTable+1] = cc.DelayTime:create(delayTime)
	seqTable[#seqTable+1] = spawn
	local seqAction = cc.Sequence:create(seqTable)
	goodsNode:runAction(seqAction)
	return goodsNode 
end
--[[
创建道具node
@params {
	goodsId    int  道具id
	goodsNum   int  道具数量
	showAmount bool 显示数量
}
--]]
function CapsuleLuckyBagDrawView:CreateGoodsNode( params )
    local goodsId = checkint(params.goodsId)
	local goodsNum = checkint(params.goodsNum)
	local showAmount = params.showAmount == nil and true or params.showAmount
    local goodsNode = require('common.GoodNode').new({id = goodsId, amount = goodsNum, showAmount = showAmount})
    display.commonUIParams(goodsNode, {animate = false, cb = function (sender)
        local tag = sender:getTag()
        AppFacade.GetInstance():DispatchObservers(CAPSULE_LUCKY_BAG_CARD_CLICK, {tag = tag})
	end})
	return goodsNode
end
--[[
更新刷新次数
--]]
function CapsuleLuckyBagDrawView:UpdateRefreshTimes( leftReplaceTimes, maxReplaceTimes )
    local viewData = self:GetViewData()
    local refreshTimesLabel = viewData.refreshTimesLabel
    refreshTimesLabel:setString(string.format('%d/%d', checkint(leftReplaceTimes), checkint(maxReplaceTimes)))
end
--[[
显示更换界面
--]]
function CapsuleLuckyBagDrawView:ShowReplaceViewAction()
    local viewData = self.viewData
    app.uiMgr:GetCurrentScene():AddViewForNoTouch()
    -- maskLayerAction
    viewData.maskLayer:runAction(
        cc.FadeOut:create(0.3)
    )
    -- bottomLayerAction
    viewData.cardBgLayout:setOpacity(0)
    viewData.bottomLayer:runAction(
        cc.Spawn:create(
            cc.MoveTo:create(0.8, cc.p(viewData.bottomLayer:getPositionX(), 0)),
            cc.TargetedAction:create(viewData.cardBgLayout, cc.Sequence:create(
                cc.DelayTime:create(0.2),
                cc.Show:create(),
                cc.FadeIn:create(0.6)
            ))
        )
    )
    -- bgLayerAction
    viewData.bgLayer:runAction(
        cc.Sequence:create(
            cc.DelayTime:create(0.3),
            cc.FadeOut:create(0.7),
            cc.Hide:create()
        )
    )
    -- rewardLayerAction
    for i, v in ipairs(self.goodsNodeList) do
        local data = GOODS_ACTION_DATA[i]
        v:runAction(
            cc.Sequence:create(
                cc.DelayTime:create(data.delaTime),
                cc.MoveTo:create(data.time, data.pos)
            )
        )
    end
    -- buttonLayerAction
    viewData.buttonLayer:setOpacity(0)
    viewData.buttonLayer:runAction(
        cc.Sequence:create(
            cc.Show:create(),
            cc.DelayTime:create(1.4),
            cc.CallFunc:create(function ()
                AppFacade.GetInstance():DispatchObservers(CAPSULE_LUCKY_BAG_SWITCH_END)
            end),
            cc.DelayTime:create(1),
            cc.FadeIn:create(0.3),
            cc.CallFunc:create(function ()
                app.uiMgr:GetCurrentScene():RemoveViewForNoTouch()
            end)
        )
    )
end
--[[
更新选卡页面
--]]
function CapsuleLuckyBagDrawView:UpdateSelectCardView( replaceData )
    -- 清除缓存
    display.removeUnusedSpriteFrames()
    local gridView = self:GetViewData().gridView
    self:GetViewData().replaceLayer:setVisible(true)
    gridView:setCountOfCell(#checktable(replaceData))
    gridView:reloadData()
    self:SwitchCardViewAction(replaceData)
end
--[[
选卡页面切换动画
--]]
function CapsuleLuckyBagDrawView:SwitchCardViewAction( replaceData )
    local viewData = self:GetViewData()
    for i = 1, 3 do
        local replaceBtn = viewData.replaceBtnList[i]
        local replaceBg = viewData.replaceBgList[i]
        replaceBtn:stopAllActions()
        replaceBg:stopAllActions()
        replaceBtn:setOpacity(0)
        replaceBtn:setVisible(false)
        replaceBtn:setEnabled(false)
        replaceBg:setOpacity(0)
        if #replaceData > 0 then
            replaceBtn:runAction(
                cc.Sequence:create(
                    cc.DelayTime:create(0.5),
                    cc.DelayTime:create(0.1 * (i - 1)),
                    cc.Show:create(),
                    cc.FadeIn:create(0.4),
                    cc.DelayTime:create(0.1 * (3 - i)),
                    cc.CallFunc:create(function()
                        replaceBtn:setEnabled(true)
                    end)
                )
            )
        end
        replaceBg:runAction(
            cc.Sequence:create(
                cc.DelayTime:create(0.1 * i),
                cc.FadeIn:create(0.4)
            )
        )

    end        
end
--[[
更新Cell
--]]
function CapsuleLuckyBagDrawView:UpdateCell(cell, cardId)
    local viewData = cell.viewData
    local imgHero  = viewData.imgHero
    imgHero:setTexture(CardUtils.GetCardDrawPathByCardId(cardId))

    local locationInfo = CommonUtils.GetConfig('cards', 'coordinate', cardId)
    if nil == locationInfo or not locationInfo[COORDINATE_TYPE_TEAM] then
        print('\n**************\n', '立绘坐标信息未找到', cardId, '\n**************\n')
        locationInfo = {x = 0, y = 0, scale = 50, rotate = 0}
    else
        locationInfo = locationInfo[COORDINATE_TYPE_TEAM]
    end
    imgHero:setScale(locationInfo.scale/100)
    imgHero:setRotation((locationInfo.rotate))
    imgHero:setPosition(cc.p(locationInfo.x,(-1)*(locationInfo.y-540)))

    viewData.heroBg:setTexture(CardUtils.GetCardTeamBgPathByCardId(cardId))
    --更新技能相关的图标
    viewData.skillFrame:setTexture(CardUtils.GetCardCareerIconFramePathByCardId(cardId))
    viewData.skillIcon:setTexture(CardUtils.GetCardCareerIconPathByCardId(cardId))
    viewData.qualityIcon:setTexture(CardUtils.GetCardQualityIconPathByCardId(cardId))
    viewData.entryHeadNode:RefreshUI({confId = cardId})

    local node = cell:getChildByName("LIST_CELL_FLAG")
    
    if node then node:removeFromParent() end
    
end
--[[
道具选中动作
@params replaceData list 替换卡牌数据
@params index       int  索引
--]]
function CapsuleLuckyBagDrawView:SelectGoodsNodeAction( replaceData, index )
    local goodsNode = self.goodsNodeList[index]
    local actionData = GOODS_ACTION_DATA[index]
    local bgTag = actionData.bgTag
    local selectBg = self:GetViewData().cardSelectBgList[bgTag]
    goodsNode:stopAllActions()
    selectBg:stopAllActions()
    goodsNode:runAction(
        cc.EaseBackOut:create(cc.ScaleTo:create(0.2, 1.2))
    )
    selectBg:setOpacity(0)
    selectBg:setVisible(true)
    selectBg:runAction(cc.FadeIn:create(0.2))
end
--[[
道具取消选中动作
@params index       int  索引
--]]
function CapsuleLuckyBagDrawView:UnselectGoodsNodeAction( index )
    local goodsNode = self.goodsNodeList[index]
    local actionData = GOODS_ACTION_DATA[index]
    local bgTag = actionData.bgTag
    local selectBg = self:GetViewData().cardSelectBgList[bgTag]
    goodsNode:stopAllActions()
    selectBg:stopAllActions()
    goodsNode:runAction(
        cc.ScaleTo:create(0.2, 0.8)
    )
    selectBg:runAction(
        cc.Sequence:create(
            cc.FadeOut:create(0.1),
            cc.Hide:create()
        )
    )
end
--[[
替换卡牌动画
@params replaceCardId int 替换的卡牌id
@params positionId    int 道具位置id
@params cardIndex     int 替换的卡牌索引
--]]
function CapsuleLuckyBagDrawView:ReplaceCardAction( replaceCardId, positionId, cardIndex )
    local viewData = self:GetViewData()
    local actionData = GOODS_ACTION_DATA[positionId]
    local size = viewData.rewardLayer:getContentSize()
    local newGoodsNode = self:CreateGoodsNode({goodsId = replaceCardId, goodsNum = 1, showAmount = true})
    newGoodsNode:setTag(checkint(positionId))
    newGoodsNode:setPosition(cc.p(size.width / 2 - 460 + (cardIndex * 230), size.height / 2 + 80))
    viewData.rewardLayer:addChild(newGoodsNode)
    newGoodsNode:setScale(1.2)
    newGoodsNode:setVisible(false)
    newGoodsNode:setOpacity(0)
    local gridViewCell = viewData.gridView:cellAtIndex(cardIndex - 1)
    
    self.goodsNodeList[positionId]:removeFromParent()
    self.goodsNodeList[positionId] = newGoodsNode
    
    app.uiMgr:GetCurrentScene():AddViewForNoTouch()
    self:AddGoodsReplaceEffact(actionData.pos)
    
    newGoodsNode:runAction(
        cc.Sequence:create(
            cc.DelayTime:create(0.5),
            cc.CallFunc:create(function()
                self:ShowCardReplaceEffect(cardIndex)
            end),
            cc.TargetedAction:create(gridViewCell.viewData.eventNode, cc.FadeOut:create(0.3)),
            cc.DelayTime:create(0.6),
            cc.Show:create(),
            cc.FadeIn:create(0.3),
            cc.DelayTime:create(0.3),
            cc.MoveTo:create(0.5, actionData.pos),
            cc.CallFunc:create(function()
                AppFacade.GetInstance():DispatchObservers(CAPSULE_LUCKY_BAG_REPLACE_END)
                app.uiMgr:GetCurrentScene():RemoveViewForNoTouch()
            end)
        )
    )
end
--[[
添加替换特效
@pos pos 坐标
--]]
function CapsuleLuckyBagDrawView:AddGoodsReplaceEffact( pos )
    local viewData = self:GetViewData()
    local effectSpn = sp.SkeletonAnimation:create(RES_DICT.EFFACT_SPINE.json, RES_DICT.EFFACT_SPINE.atlas, 1)
    effectSpn:setPosition(pos)
    viewData.rewardLayer:addChild(effectSpn, 10)
    effectSpn:setAnimation(0, 'idle1', false)
    effectSpn:registerSpineEventHandler(
        function (event)
            if event.animation == 'idle1' or event.animation == 'idle2' then
                effectSpn:setVisible(false)
                effectSpn:performWithDelay(
                    function ()
                        effectSpn:clearTracks()
                        effectSpn:unregisterSpineEventHandler(sp.EventType.ANIMATION_END)
                        effectSpn:removeFromParent()
                    end,
                    (1 * cc.Director:getInstance():getAnimationInterval())
                )
            end
        end,
        sp.EventType.ANIMATION_END
    )
end
--[[
显示卡牌替换特效
@params index int 索引
--]]
function CapsuleLuckyBagDrawView:ShowCardReplaceEffect( index )
    local viewData = self:GetViewData()
    local effectSpn = viewData.replaceEffectList[index]
    effectSpn:setVisible(true)
    effectSpn:update(0)
    effectSpn:setToSetupPose()
    effectSpn:setAnimation(0, 'idle2', false)
end
--[[
获取viewData
--]]
function CapsuleLuckyBagDrawView:GetViewData()
    return self.viewData
end
--[[
返回
--]]
function CapsuleLuckyBagDrawView:BackAction()
    PlayAudioByClickClose()
    if self.cb then
        self.cb()
    end
end
function CapsuleLuckyBagDrawView:onCleanup()
	display.removeUnusedSpriteFrames()
end
return CapsuleLuckyBagDrawView