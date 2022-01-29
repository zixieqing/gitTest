--[[
 * author : kaishiqi
 * descpt : 打牌游戏 - 卡包奖励弹窗
]]
local TTGamePackageRewardsPopup = class('TripleTriadGamePackageRewardsPopup', function()
    return display.newLayer(0, 0, {name = 'TripleTriadGamePackageRewardsPopup'})
end)

local RES_DICT = {
    CLOSE_BAR          = _res('ui/common/common_bg_close.png'),
    REWARDS_LIGHT      = _res('ui/common/common_reward_light.png'),
    REWARDS_WORDS      = _res('ui/common/common_words_congratulations.png'),
    CHANGE_ARROW       = _res('ui/home/capsuleNew/common/summon_ico_arrow_change.png'),
    CHANGE_GOODS_BG    = _res('ui/home/capsuleNew/common/summon_skin_bg_goods_change.png'),
    OPEN_PACKAGE_SPINE = _spn('ui/ttgame/shop/cardgame_pack'),
    SP_REWARDS_SPINE   = _spn('effects/capsule/capsule'),
}

local CreateView  = nil
local CreateGoods = nil
local GOODS_SIZE  = cc.size(230, 260)


function TTGamePackageRewardsPopup:ctor(args)
    self:setAnchorPoint(display.CENTER)

    -- init vars
    self.animateRewards_ = self:preprocessRewardsData_(args.rewards)
    self.isComposeMode_  = args.composeMode == true
    self.closeCallback_  = args.closeCB
    self.isControllable_ = true

    -- create view
    self.viewData_ = CreateView()
    self:addChild(self.viewData_.view)

    -- add listener
    display.commonUIParams(self:getViewData().closeLayer, {cb = handler(self, self.onClickCloseLayerHandler_)})

    -- update view
    self.goodsEndPos_ = {}
    self.goodsVDList_ = {}
    local GOODS_COUNT = #self.animateRewards_
    local GOODS_COLS  = 5
    local GOODS_ROWS  = math.ceil(GOODS_COUNT / GOODS_COLS)
    local CENTER_POS  = self:getViewData().rewardsCenterPos
    local GOODS_POS_Y = CENTER_POS.y + (GOODS_ROWS/2 - 0.5) * GOODS_SIZE.height
    local GOODS_POS_X = CENTER_POS.x
    for goodsIndex, rewardData in ipairs(self.animateRewards_) do
        local colNum  = (goodsIndex - 1) % GOODS_COLS + 1
        local rowNum  = math.ceil(goodsIndex / GOODS_COLS)
        local colMax  = math.min(GOODS_COUNT - (rowNum-1) * GOODS_COLS, GOODS_COLS)
        local offsetX = GOODS_POS_X - (colMax-1) * GOODS_SIZE.width/2
        local goodsVD = CreateGoods(GOODS_SIZE)
        goodsVD.view:setPositionX(offsetX + (colNum-1) * GOODS_SIZE.width)
        goodsVD.view:setPositionY(GOODS_POS_Y - (rowNum-1) * GOODS_SIZE.height)
        self:getViewData().rewardsLayer:addChild(goodsVD.view)
        table.insert(self.goodsEndPos_, cc.p(goodsVD.view:getPosition()))
        table.insert(self.goodsVDList_, goodsVD)

        goodsVD.hasTurn = checkint(rewardData.turnGoodsId) > 0
        goodsVD.cardNode:setCardId(rewardData.cardId)
        goodsVD.changeArrow:setVisible(goodsVD.hasTurn)
        goodsVD.exchangeLayer:setVisible(goodsVD.hasTurn)
        if goodsVD.hasTurn then
            local goodIconPath = CommonUtils.GetGoodsIconPathById(rewardData.turnGoodsId)
            goodsVD.changeIconLayer:addChild(display.newImageView(goodIconPath))
            goodsVD.changeNumLabel:setString(tostring(rewardData.turnGoodsNum))
        end
    end

    self:getViewData().rewardsLightEndPos = cc.p(self:getViewData().rewardsLight:getPositionX(), GOODS_POS_Y + GOODS_SIZE.height/2 - 50)
    self:getViewData().rewardsWordsEndPos = cc.p(self:getViewData().rewardsWords:getPositionX(), self:getViewData().rewardsLightEndPos.y + 80)
    self:getViewData().rewardsLight:setPosition(self:getViewData().rewardsLightEndPos)
    self:getViewData().rewardsWords:setPosition(self:getViewData().rewardsWordsEndPos)

    self:show()
end


CreateView = function()
    local view = display.newLayer()
    local size = view:getContentSize()
    
    -- block layer
    view:addChild(display.newLayer(0, 0, {size = size, color = cc.c4b(0,0,0,150), enable = true}))
    
    -- spRewards spine
    local spRewardsSpine = TTGameUtils.CreateSpine(RES_DICT.SP_REWARDS_SPINE)
    spRewardsSpine:setPosition(display.center)
    view:addChild(spRewardsSpine)
    spRewardsSpine:setVisible(false)

    -- openPackage spine
    local rewardsCenterPos = cc.p(display.cx, display.cy - 40)
    local openPackageSpine = TTGameUtils.CreateSpine(RES_DICT.OPEN_PACKAGE_SPINE)
    openPackageSpine:setPosition(rewardsCenterPos)
    view:addChild(openPackageSpine)


    -------------------------------------------------
    -- rewards layer
    local rewardsLayer = display.newLayer()
    view:addChild(rewardsLayer)

    local rewardsLight = display.newImageView(RES_DICT.REWARDS_LIGHT, rewardsCenterPos.x, rewardsCenterPos.y - 50)
    rewardsLayer:addChild(rewardsLight)

    local rewardsWords = display.newImageView(RES_DICT.REWARDS_WORDS, rewardsLight:getPositionX(), rewardsLight:getPositionY() + 80)
    rewardsLayer:addChild(rewardsWords)


    -------------------------------------------------
    -- close laer
    local closeLayer = display.newLayer(0, 0, {size = size, color = cc.c4b(0,0,0,0), enable = true})
    view:addChild(closeLayer)

    -- close bar
    local closeBar = display.newButton(size.width/2, 50, {n = RES_DICT.CLOSE_BAR, enable = false})
    display.commonLabelParams(closeBar, fontWithColor(9, {text = __('点击空白处关闭')}))
    closeLayer:addChild(closeBar)

    closeBar:runAction(cc.RepeatForever:create(cc.Sequence:create(
        cc.FadeTo:create(1, 55),
        cc.FadeTo:create(1, 255)
    )))

    return {
        view             = view,
        closeLayer       = closeLayer,
        rewardsLayer     = rewardsLayer,
        rewardsLight     = rewardsLight,
        rewardsWords     = rewardsWords,
        openPackageSpine = openPackageSpine,
        rewardsCenterPos = rewardsCenterPos,
        spRewardsSpine   = spRewardsSpine,
    }
end


CreateGoods = function(size)
    local view = display.newLayer(0, 0, {size = size, color1 = cc.r4b(50), ap = display.CENTER})
    view:setContentSize(size)

    local cardNode = TTGameUtils.GetBattleCardNode()
    cardNode:setPositionX(size.width/2)
    cardNode:setPositionY(size.height/2)
    view:addChild(cardNode)
    

    local exchangeLayer = display.newLayer()
    view:addChild(exchangeLayer)
    
    local changeGoodsBg = display.newImageView(RES_DICT.CHANGE_GOODS_BG, size.width - 30, 65)
    exchangeLayer:addChild(changeGoodsBg)
    
    local changeIconLayer = display.newLayer(changeGoodsBg:getPositionX(), changeGoodsBg:getPositionY())
    changeIconLayer:setScale(0.25)
    exchangeLayer:addChild(changeIconLayer)
    
    local changeIntro = display.newLabel(0, 0, fontWithColor(20, {fontSize = 24, outline = '#633131', text = __('转换')}))
    changeIntro:setPositionY(changeGoodsBg:getPositionY() + 35)
    changeIntro:setPositionX(changeGoodsBg:getPositionX())
    exchangeLayer:addChild(changeIntro)
    
    local changeNumLabel = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '---')
    changeNumLabel:setPositionY(changeGoodsBg:getPositionY() - 48)
    changeNumLabel:setPositionX(changeGoodsBg:getPositionX())
    changeNumLabel:setBMFontSize(30)
    exchangeLayer:addChild(changeNumLabel)

    
    local changeArrow = display.newImageView(RES_DICT.CHANGE_ARROW, size.width/2-15, 0, {ap = display.LEFT_BOTTOM, scale = 1})
    view:addChild(changeArrow)
    
    return {
        view            = view,
        cardNode        = cardNode,
        changeArrow     = changeArrow,
        exchangeLayer   = exchangeLayer,
        changeNumLabel  = changeNumLabel,
        changeIconLayer = changeIconLayer,
    }
end


-------------------------------------------------
-- get / ser

function TTGamePackageRewardsPopup:getViewData()
    return self.viewData_
end


-------------------------------------------------
-- public

function TTGamePackageRewardsPopup:close()
    if self.closeCallback_ then
        self.closeCallback_()
    end
    self:runAction(cc.RemoveSelf:create())
end


function TTGamePackageRewardsPopup:show()
    -- init views
    local rewardsWordsInitPos = cc.p(self:getViewData().rewardsWordsEndPos.x, display.height + self:getViewData().rewardsWords:getContentSize().height)
    self:getViewData().rewardsWords:setPosition(rewardsWordsInitPos)
    self:getViewData().rewardsLight:setScale(0)
    self:getViewData().closeLayer:setVisible(false)

    local isSingleReward = #self.animateRewards_ <= 1
    local cardActionList = {}
    for index, goodsVD in ipairs(self.goodsVDList_) do
        if isSingleReward then
            goodsVD.cardNode:setScaleX(0)
        else
            goodsVD.view:setPosition(self:getViewData().rewardsCenterPos)
            goodsVD.cardNode:setScale(0)
            goodsVD.cardNode:setRotation(-180)
            goodsVD.cardNode:toCardBackStatus()
        end
        goodsVD.changeArrow:setScaleX(0)
        goodsVD.changeArrow:setOpacity(0)
        goodsVD.exchangeLayer:setScale(0)
        goodsVD.exchangeLayer:setOpacity(0)
    end

    -- run acttion
    local CARD_FLIP_TIME  = 0.4
    local hasSpRewards    = false
    local showRewardsFunc = function()
        if not isSingleReward then
            table.insert(cardActionList, cc.TargetedAction:create(self:getViewData().openPackageSpine, cc.FadeOut:create(1)))
        end

        for index, goodsVD in ipairs(self.goodsVDList_) do
            local isSpRewards = TTGameUtils.IsSpCard(goodsVD.cardNode:getCardId()) -- sp

            if isSingleReward then
                -- flip
                table.insert(cardActionList, cc.TargetedAction:create(goodsVD.cardNode, cc.EaseCubicActionOut:create(cc.ScaleTo:create(CARD_FLIP_TIME, 1))))

                if isSpRewards then
                    table.insert(cardActionList, cc.CallFunc:create(function()
                        self:getViewData().spRewardsSpine:setVisible(true)
                        self:getViewData().spRewardsSpine:setAnimation(0, 'chouka_qian', false)
                    end))
                end

                -- turn
                if goodsVD.hasTurn then
                    table.insert(cardActionList, cc.TargetedAction:create(goodsVD.changeArrow, cc.Sequence:create(
                        cc.DelayTime:create(0.4),
                        cc.Spawn:create(
                            cc.FadeIn:create(0.3),
                            cc.ScaleTo:create(0.2, 1)
                        )
                    )))
                    table.insert(cardActionList, cc.TargetedAction:create(goodsVD.exchangeLayer, cc.Sequence:create(
                        cc.DelayTime:create(0.6),
                        cc.Spawn:create(
                            cc.FadeIn:create(0.3),
                            cc.EaseBackOut:create(cc.ScaleTo:create(0.4, 1))
                        )
                    )))
                end

            else
                -- show
                table.insert(cardActionList, cc.TargetedAction:create(goodsVD.view, cc.Sequence:create(
                    cc.DelayTime:create((index-1) * 0.05),
                    cc.EaseCubicActionOut:create(cc.MoveTo:create(0.4, self.goodsEndPos_[index]))
                )))

                -- flip
                table.insert(cardActionList, cc.TargetedAction:create(goodsVD.cardNode, cc.Sequence:create(
                    cc.DelayTime:create((index-1) * 0.05),
                    cc.Spawn:create(
                        cc.EaseCubicActionOut:create(cc.RotateTo:create(0.3, 0)),
                        cc.EaseCubicActionOut:create(cc.ScaleTo:create(0.3, 1))
                    ),
                    cc.EaseCubicActionIn:create(cc.ScaleTo:create(CARD_FLIP_TIME, 0, 1)),
                    cc.CallFunc:create(function()
                        goodsVD.cardNode:toCardFrontStatus()
                    end),
                    cc.EaseCubicActionOut:create(cc.ScaleTo:create(CARD_FLIP_TIME, 1))
                )))

                if isSpRewards and not hasSpRewards then
                    table.insert(cardActionList, cc.Sequence:create(
                        cc.DelayTime:create(CARD_FLIP_TIME * 2 + (#self.goodsVDList_-1)*0.05 + 0.3),
                        cc.CallFunc:create(function()
                            self:getViewData().spRewardsSpine:setVisible(true)
                            self:getViewData().spRewardsSpine:setAnimation(0, 'chouka_qian', false)
                        end)
                    ))
                    hasSpRewards = true
                end

                -- turn
                if goodsVD.hasTurn then
                    local CARD_ACT_TIME = CARD_FLIP_TIME * 2 + 0.3
                    table.insert(cardActionList, cc.TargetedAction:create(goodsVD.changeArrow, cc.Sequence:create(
                        cc.DelayTime:create(0.4 + CARD_ACT_TIME),
                        cc.Spawn:create(
                            cc.FadeIn:create(0.3),
                            cc.ScaleTo:create(0.2, 1)
                        )
                    )))
                    table.insert(cardActionList, cc.TargetedAction:create(goodsVD.exchangeLayer, cc.Sequence:create(
                        cc.DelayTime:create(0.6 + CARD_ACT_TIME),
                        cc.Spawn:create(
                            cc.FadeIn:create(0.3),
                            cc.EaseBackOut:create(cc.ScaleTo:create(0.4, 1))
                        )
                    )))
                end
            end
        end

        self:runAction(cc.Sequence:create(
            #cardActionList > 0 and cc.Spawn:create(cardActionList) or nil,
            cc.Spawn:create(
                cc.TargetedAction:create(self:getViewData().rewardsWords, cc.EaseBounceOut:create(cc.MoveTo:create(0.5, self:getViewData().rewardsWordsEndPos))),
                cc.TargetedAction:create(self:getViewData().rewardsLight, cc.EaseBackOut:create(cc.ScaleTo:create(0.5, 1))),
                cc.TargetedAction:create(self:getViewData().rewardsLight, cc.RotateBy:create(0.5, 45))
            ),
            cc.CallFunc:create(function()
                self:getViewData().rewardsLight:runAction(cc.RepeatForever:create(cc.RotateBy:create(0.5, 45)))
                for index, goodsVD in ipairs(self.goodsVDList_) do
                    if TTGameUtils.IsSpCard(goodsVD.cardNode:getCardId()) then  -- sp
                        goodsVD.view:runAction(cc.RepeatForever:create(cc.Sequence:create(
                            cc.MoveBy:create(1, cc.p(0,8)),
                            cc.MoveBy:create(1, cc.p(0,-8))
                        )))
                    end
                end
            end),
            cc.CallFunc:create(function()
                self:getViewData().closeLayer:setVisible(true)
            end)
        ))
    end

    if self.isComposeMode_ then
        self:getViewData().openPackageSpine:setVisible(false)
        showRewardsFunc()
    else
        self:getViewData().openPackageSpine:registerSpineEventHandler(function(event)
            self:getViewData().openPackageSpine:unregisterSpineEventHandler(sp.EventType.ANIMATION_COMPLETE)
            showRewardsFunc()
        end, sp.EventType.ANIMATION_COMPLETE)
        self:getViewData().openPackageSpine:setAnimation(0, isSingleReward and 'play1' or 'play10', false)
    end
end


-------------------------------------------------
-- private

function TTGamePackageRewardsPopup:preprocessRewardsData_(packageRewards)
    local animateRewards = {}
    for rewardIndex, rewardData in ipairs(checktable(packageRewards)) do
        local battleCardId = checkint(rewardData.turnGoodsId)
        local cardConfInfo = TTGameUtils.GetConfAt(TTGAME_DEFINE.CONF_TYPE.CARD_DEFINE, battleCardId)
        if app.ttGameMgr:hasBattleCardId(battleCardId) then
            -- turn goods
            local turnGoodsInfo = checktable(cardConfInfo.exchange)[1] or {}
            table.insert(animateRewards, {cardId = battleCardId, turnGoodsId = turnGoodsInfo.goodsId, turnGoodsNum = turnGoodsInfo.num})
            -- add backpack
            CommonUtils.DrawRewards({{goodsId = turnGoodsInfo.goodsId, num = turnGoodsInfo.num}})
        else
            -- add card
            app.ttGameMgr:addBattleCardId(battleCardId)
            table.insert(animateRewards, {cardId = battleCardId})
        end
    end
    return animateRewards
end


-------------------------------------------------
-- handler

function TTGamePackageRewardsPopup:onClickCloseLayerHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    self:close()
end


return TTGamePackageRewardsPopup
