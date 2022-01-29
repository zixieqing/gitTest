--[[
 * author : kaishiqi
 * descpt : 打牌游戏 - 结算奖励弹窗
]]
local TTGameResultRewardsPopup = class('TripleTriadGameResultRewardsPopup', function()
    return display.newLayer(0, 0, {name = 'TripleTriadGameResultRewardsPopup'})
end)

local RES_DICT = {
    REWARD_TITLE      = _res('ui/battle/battleresult/common_words_flop.png'),
    CLOSE_BTN_N       = _res('ui/common/common_btn_orange.png'),
    GOODS_FRAME_BACK  = _res('ui/battle/battleresult/team_fight_flop_btn_default.png'),
    GOODS_FRAME_LIGHT = _res('ui/battle/battleresult/team_fight_flop_btn_light.png'),
    GOODS_FRAME_FRONT = _res('ui/battle/battleresult/team_fight_flop_btn_select.png'),
}

local CreateView  = nil
local CreateGoods = nil
local GOODS_SIZE  = cc.size(280, 320)


function TTGameResultRewardsPopup:ctor(args)
    self:setAnchorPoint(display.CENTER)

    -- init vars
    self.resultRewards_  = self:preprocessRewardsData_(args.totalRewards, args.rewardIndex)
    self.closeCallback_  = args.closeCB
    self.isControllable_ = true
    self.selectGoodsIdx_ = 0

    -- create view
    self.viewData_ = CreateView()
    self:addChild(self.viewData_.view)

    -- add listener
    display.commonUIParams(self:getViewData().closeBtn, {cb = handler(self, self.onClickCloseButtonHandler_)})

    -- update view
    self.goodsVDList_ = {}
    local offsetX = display.cx - (#self.resultRewards_-1)/2 * GOODS_SIZE.width
    for index = 1, #self.resultRewards_ do
        local goodsVD = CreateGoods(GOODS_SIZE)
        goodsVD.view:setPositionX(offsetX + (index-1) * GOODS_SIZE.width)
        goodsVD.view:setPositionY(display.cy)
        goodsVD.view:setTag(index)
        goodsVD.showPos = cc.p(goodsVD.view:getPosition())
        goodsVD.hidePos = cc.p(display.cx, -display.cy)
        goodsVD.hotspot:setTag(index)
        self:getViewData().rewardsLayer:addChild(goodsVD.view)
        table.insert(self.goodsVDList_, goodsVD)

        display.commonUIParams(goodsVD.hotspot, {cb = handler(self, self.onClickGoodsCellHandler_)})
    end

    self:getViewData().closeBtn:setVisible(false)
    self:show()
end


CreateView = function()
    local view = display.newLayer()
    local size = view:getContentSize()
    
    -- block layer
    view:addChild(display.newLayer(0, 0, {size = size, color = cc.c4b(0,0,0,150), enable = true}))

    -- reward title
    local rewardTitle = display.newImageView(RES_DICT.REWARD_TITLE, size.width/2, size.height/2 + 250)
    view:addChild(rewardTitle)
    
    -- rewards layer
    local rewardsLayer = display.newLayer()
    view:addChild(rewardsLayer)

    -- close bar
    local closeBtn = display.newButton(size.width/2, size.height/2 - 250, {n = RES_DICT.CLOSE_BTN_N})
    display.commonLabelParams(closeBtn, fontWithColor(14, {text = __('返回')}))
    view:addChild(closeBtn)

    return {
        view            = view,
        closeBtn        = closeBtn,
        rewardTitle     = rewardTitle,
        rewardTitleSPos = cc.p(rewardTitle:getPositionX(), rewardTitle:getPositionY()),
        rewardTitleHPos = cc.p(rewardTitle:getPositionX(), rewardTitle:getPositionY() + display.cy),
        rewardsLayer    = rewardsLayer,
    }
end


CreateGoods = function(size)
    local view = display.newLayer(0, 0, {size = size, color1 = cc.r4b(0), ap = display.CENTER})
    view:setContentSize(size)

    local frameBackImg  = display.newImageView(RES_DICT.GOODS_FRAME_BACK, size.width/2, size.height/2)
    local frameLightImg = display.newImageView(RES_DICT.GOODS_FRAME_LIGHT, size.width/2, size.height/2)
    local frameFrontImg = display.newImageView(RES_DICT.GOODS_FRAME_FRONT, size.width/2, size.height/2)
    view:addChild(frameBackImg)
    view:addChild(frameLightImg)
    view:addChild(frameFrontImg)
    frameLightImg:setVisible(false)
    frameFrontImg:setVisible(false)

    local goodsImgLayer = display.newLayer(size.width/2, size.height/2)
    view:addChild(goodsImgLayer)
    goodsImgLayer:setVisible(false)

    local hotspot = display.newLayer(0, 0, {size = size, color = cc.r4b(0), enable = true})
    view:addChild(hotspot)
    
    return {
        view          = view,
        hotspot       = hotspot,
        frameBackImg  = frameBackImg,
        frameLightImg = frameLightImg,
        frameFrontImg = frameFrontImg,
        goodsImgLayer = goodsImgLayer,
    }
end


-------------------------------------------------
-- get / ser

function TTGameResultRewardsPopup:getViewData()
    return self.viewData_
end


-------------------------------------------------
-- public

function TTGameResultRewardsPopup:close()
    if self.closeCallback_ then
        self.closeCallback_()
    end
    self:runAction(cc.RemoveSelf:create())
end


function TTGameResultRewardsPopup:show()
    -- init views
    self:getViewData().rewardTitle:setPosition(self:getViewData().rewardTitleHPos)

    local goodsActList = {
        cc.TargetedAction:create(self:getViewData().rewardTitle, cc.EaseBackOut:create(cc.MoveTo:create(0.2, self:getViewData().rewardTitleSPos)))
    }
    for index, goodsVD in ipairs(self.goodsVDList_) do
        goodsVD.view:setPosition(goodsVD.hidePos)
        table.insert(goodsActList, cc.TargetedAction:create(goodsVD.view, cc.EaseQuarticActionOut:create(cc.BezierTo:create(0.4, {
            cc.p(goodsVD.hidePos.x, goodsVD.showPos.y), -- start con pos
            cc.p(goodsVD.hidePos.x, goodsVD.showPos.y), -- end con pos
            goodsVD.showPos,  -- end pos
        }))))
    end

    -- run action
    self.isControllable_ = false
    self:runAction(cc.Sequence:create(
        cc.Spawn:create(goodsActList),
        cc.CallFunc:create(function()
            self.isControllable_ = true
        end)
    ))
end


-------------------------------------------------
-- private

function TTGameResultRewardsPopup:preprocessRewardsData_(totalRewards, rewardIndex)
    local animateRewards  = {}
    local totalRewardsNum = #checktable(totalRewards)
    for index, rewardData in ipairs(totalRewards or {}) do
        table.insert(animateRewards, {
            goodsId      = checkint(rewardData.goodsId),
            num          = checkint(rewardData.num),
            turnGoodsId  = rewardData.turnGoodsId,
            turnGoodsNum = rewardData.turnGoodsNum,
            isReward     = index == checkint(rewardIndex),
        })
    end
    for i = 1, 10 do
        local removeReward = table.remove(animateRewards, math.random(totalRewardsNum))
        table.insert(animateRewards, removeReward)
    end
    return animateRewards
end


function TTGameResultRewardsPopup:toFlipRewardGoods_(goodsIndex, finishCB)
    local goodsVD = self.goodsVDList_[goodsIndex]
    if goodsVD then
        goodsVD.view:stopAllActions()
        goodsVD.goodsImgLayer:setScaleX(0)
        goodsVD.frameFrontImg:setScaleX(0)
        goodsVD.goodsImgLayer:setVisible(true)
        goodsVD.frameFrontImg:setVisible(true)

        goodsVD.view:runAction(cc.Sequence:create(
            cc.Spawn:create(
                cc.TargetedAction:create(goodsVD.frameBackImg, cc.EaseQuarticActionIn:create(cc.ScaleTo:create(0.2, 0, 1))),
                cc.TargetedAction:create(goodsVD.frameLightImg, cc.EaseQuarticActionIn:create(cc.ScaleTo:create(0.2, 0, 1)))
            ),
            cc.Spawn:create(
                cc.TargetedAction:create(goodsVD.goodsImgLayer, cc.EaseQuarticActionOut:create(cc.ScaleTo:create(0.2, 1, 1))),
                cc.TargetedAction:create(goodsVD.frameFrontImg, cc.EaseQuarticActionOut:create(cc.ScaleTo:create(0.2, 1, 1))),
                cc.TargetedAction:create(goodsVD.frameLightImg, cc.EaseQuarticActionOut:create(cc.ScaleTo:create(0.2, 1, 1)))
            ),
            cc.CallFunc:create(function()
                if finishCB then finishCB() end
            end)
        ))
    end
end


-------------------------------------------------
-- handler

function TTGameResultRewardsPopup:onClickCloseButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    self:close()
end


function TTGameResultRewardsPopup:onClickGoodsCellHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end
    if self.selectGoodsIdx_ > 0 then return end

    local selectIndex    = checkint(sender:getTag())
    self.selectGoodsIdx_ = selectIndex
    
    -- switch rewards
    for goodsIndex, rewardData in ipairs(self.resultRewards_) do
        if rewardData.isReward then
            local aGoodsData = self.resultRewards_[selectIndex]
            local bGoodsData = self.resultRewards_[goodsIndex]
            self.resultRewards_[selectIndex] = bGoodsData
            self.resultRewards_[goodsIndex]  = aGoodsData
            break
        end
    end

    -- add goodsIcon
    for index, goodsVD in ipairs(self.goodsVDList_) do
        local rewardData = self.resultRewards_[index]
        local goodsType  = CommonUtils.GetGoodTypeById(checkint(rewardData.goodsId))
        local goodsNode  = nil 
        
        if GoodsType.TYPE_TTGAME_CARD == goodsType then
			local cardNode = TTGameUtils.GetBattleCardNode({cardId = rewardData.goodsId, zoomModel = 'l'})
			cardNode:setAnchorPoint(display.LEFT_BOTTOM)
			goodsNode = display.newButton(0, 0, {n = _res('ui/common/story_tranparent_bg.png'), scale9 = true, size = cardNode:getContentSize()})
			goodsNode:setCascadeOpacityEnabled(true)
			goodsNode:addChild(cardNode)
		else
			goodsNode = require('common.GoodNode').new({id = rewardData.goodsId, amount = rewardData.num, showAmount = true})
        end
        
        goodsVD.goodsImgLayer:addChild(goodsNode)
        goodsVD.frameLightImg:setVisible(index == self.selectGoodsIdx_)
    end

    -- showRewardsCB
    local closeRewardsCallback = function()
        for index, goodsVD in ipairs(self.goodsVDList_) do
            if index ~= self.selectGoodsIdx_ then
                self:toFlipRewardGoods_(index, function()
                    self:getViewData().closeBtn:setVisible(true)
                end)
            end
        end
    end

    -- showRewards
    self:toFlipRewardGoods_(self.selectGoodsIdx_, function()
        local rewardData = self.resultRewards_[self.selectGoodsIdx_]
        local goodsType  = CommonUtils.GetGoodTypeById(checkint(rewardData.goodsId))

        if goodsType == GoodsType.TYPE_TTGAME_CARD then
            app.uiMgr:AddDialog('Game.views.ttGame.TripleTriadGamePackageRewardsPopup', {composeMode = true, 
                rewards = { {turnGoodsId = rewardData.goodsId, num = 1} }, 
                closeCB = closeRewardsCallback
            })

        elseif goodsType == GoodsType.TYPE_TTGAME_PACK then
            app.uiMgr:AddDialog('Game.views.ttGame.TripleTriadGamePackageRewardsPopup', {
                rewards = {rewardData},
                closeCB = closeRewardsCallback
            })

        else
            app.uiMgr:AddDialog('common.RewardPopup', {rewards = {rewardData}, closeCallback = closeRewardsCallback})
        end
    end)
end


return TTGameResultRewardsPopup
