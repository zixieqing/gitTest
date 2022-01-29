--[[
 * author : kaishiqi
 * descpt : 工会派对 - ROLL结果界面
]]
local UnionPartyRollResultView = class('UnionPartyRollResultView', function()
    return display.newLayer(0, 0, {name = 'Game.views.union.UnionPartyRollResultView', enableEvent = true})
end)

local RES_DICT = {
    REWARDS_LIGHT = 'ui/common/common_reward_light.png',
    REWARDS_TITLE = 'ui/union/roll/party_roll_reward_words.png',
}

local CreateView      = nil
local CreateGoodsCell = nil

local RANK_COLOR_MAP = {
    ['1'] = '#FF591F',
    ['2'] = '#FF8E1F',
    ['3'] = '#FFC350',
    ['4'] = '#E9FF90',
}


function UnionPartyRollResultView:ctor(args)
    local ctorArgs        = checktable(args)
    local resultMap       = ctorArgs.rollResult or {}
    local resultStepId    = ctorArgs.resultStepId or {}
    local unionManager    = AppFacade.GetInstance():GetManager('UnionManager')
    local resultStepInfo  = unionManager:getPartyStepInfo(resultStepId) or {}
    self.resultEndedTime_ = checkint(resultStepInfo.endedTime)

    -- create view
    self.viewData_ = CreateView()
    self:addChild(self.viewData_.view)

    -- init goods
    local goodsSize  = cc.size(175, 220)
    local goodsCount = table.nums(resultMap)
    local goodsBaseX = display.cx - goodsSize.width * (goodsCount / 2 - 0.5)
    local goodsCells = {}
    for i = 1, goodsCount do
        -- create goodsCell
        local resultData = resultMap[tostring(i)] or {}
        local goodsCell  = CreateGoodsCell(goodsSize)
        goodsCell.view:setPosition(goodsBaseX + goodsSize.width * (i-1), display.cy)
        self.viewData_.rewardsLayer:addChild(goodsCell.view)
        goodsCells[i] = goodsCell

        -- update goodsCell
        local numText = string.fmt(__('第_num_名'), {_num_ = i})
        display.commonLabelParams(goodsCell.numLabel, {color = RANK_COLOR_MAP[i] or '#FFFFFF', text = numText})
        display.commonLabelParams(goodsCell.nameLabel, {text = tostring(resultData.playerName)})
        goodsCell.view:setOpacity(0)
        goodsCell.view:setScale(0)

        local goodsData = checktable(resultData.rewards)[1] or {}
        local goodsNode = require('common.GoodNode').new({id = checkint(goodsData.goodsId), amount = checkint(goodsData.num), showAmount = true, callBack = function(sender)
            local uiManager = AppFacade.GetInstance():GetManager('UIManager')
            uiManager:ShowInformationTipsBoard({targetNode = sender, iconId = checkint(goodsData.goodsId), type = 1}) -- 1 is props
        end})
        goodsNode:setPosition(utils.getLocalCenter(goodsCell.goodsLayer))
        goodsNode:setAnchorPoint(display.CENTER)
        goodsCell.goodsLayer:addChild(goodsNode)
    end

    -- init views
    self.viewData_.lightImg:setOpacity(0)
    self.viewData_.titleImg:setOpacity(0)
    self.viewData_.titleImg:setPosition(self.viewData_.titleHidePos)
    self.viewData_.rewardsSpine:setAnimation(0, 'play', false)
    self.viewData_.view:runAction(cc.Sequence:create({
        cc.DelayTime:create(1),
        cc.Spawn:create({
            cc.TargetedAction:create(self.viewData_.lightImg, cc.FadeIn:create(1.2)),
            cc.TargetedAction:create(self.viewData_.titleImg, cc.FadeIn:create(0.2)),
            cc.TargetedAction:create(self.viewData_.titleImg, cc.EaseElasticOut:create(cc.MoveTo:create(1.2, self.viewData_.titleShowPos))),
            cc.CallFunc:create(function()
                for i, goodsCell in ipairs(goodsCells) do
                    goodsCell.view:runAction(cc.Sequence:create({
                        cc.DelayTime:create(0.1 + 0.1*i),
                        cc.Spawn:create({
                            cc.FadeIn:create(0.4),
                            cc.ScaleTo:create(0.4, 1),
                            cc.JumpBy:create(0.4, cc.p(0,0), 160, 1)
                        })
                    }))
                end
            end)
        }),
        cc.CallFunc:create(function()
            self.viewData_.lightImg:runAction(cc.RepeatForever:create(cc.Spawn:create(
                cc.Sequence:create(
                    cc.FadeTo:create(1, 100),
                    cc.FadeTo:create(1, 255)
                ),
                cc.RotateBy:create(2, 45)
            )))

            self:updateResultLeftTime_()
            self:startResultCountdownUpdate_()
        end)
    }))
end


CreateView = function()
    local view = display.newLayer()

    -- block bg
    local blockBg = display.newLayer(0, 0, {color = cc.c4b(0,0,0,0), enable = true})
    view:addChild(blockBg)

    -- light img
    local lightImg = display.newImageView(_res(RES_DICT.REWARDS_LIGHT), display.cx, display.cy + 130)
    view:addChild(lightImg)

    -- title img
    local titleImg = display.newImageView(_res(RES_DICT.REWARDS_TITLE), display.cx, lightImg:getPositionY() + 60)
    view:addChild(titleImg)

    -- add spine cache
    local rewardsSpinePath = 'effects/rewardgoods/skeleton'
    if not SpineCache(SpineCacheName.UNION):hasSpineCacheData(rewardsSpinePath) then
        SpineCache(SpineCacheName.UNION):addCacheData(rewardsSpinePath, rewardsSpinePath, 1)
    end

    -- create rewards spine
    local rewardsSpine = SpineCache(SpineCacheName.UNION):createWithName(rewardsSpinePath)
    rewardsSpine:setPosition(display.center)
    view:addChild(rewardsSpine)

    -- rewards layer
    local rewardsLayer = display.newLayer()
    view:addChild(rewardsLayer)

    -- time label
    local timeLabel = display.newLabel(display.cx, display.cy - 175, fontWithColor(14))
    view:addChild(timeLabel)

    return {
        view         = view,
        lightImg     = lightImg,
        titleImg     = titleImg,
        titleHidePos = cc.p(titleImg:getPositionX(), display.height + 100),
        titleShowPos = cc.p(titleImg:getPosition()),
        rewardsSpine = rewardsSpine,
        rewardsLayer = rewardsLayer,
        timeLabel    = timeLabel,
    }
end


CreateGoodsCell = function(size)
    local view = display.newLayer(0, 0, {size = size, ap = display.CENTER})

    local numLabel = display.newLabel(size.width/2, size.height - 20, fontWithColor(14, {fontSize = 26, color = '#FFFFFF'}))
    view:addChild(numLabel)

    local nameBrand = display.newLabel(size.width/2, 50, fontWithColor(14, {fontSize = 22, color = '#FFFFFF', text = __('获奖者')}))
    view:addChild(nameBrand)

    local nameLabel = display.newLabel(size.width/2, nameBrand:getPositionY() - 30, fontWithColor(5, {color = '#FFBF37'}))
    view:addChild(nameLabel)

    local goodsLayer = display.newLayer(size.width/2, size.height/2 + 15, {ap = display.CENTER})
    view:addChild(goodsLayer)

    return {
        view       = view,
        numLabel   = numLabel,
        nameLabel  = nameLabel,
        goodsLayer = goodsLayer,
    }
end


function UnionPartyRollResultView:getViewData()
    return self.viewData_
end


function UnionPartyRollResultView:onCleanup()
    self:stopResultCountdownUpdate_()
end


function UnionPartyRollResultView:startResultCountdownUpdate_()
    if self.resultCountdownUpdateHandler_ then return end
    self.resultCountdownUpdateHandler_ = scheduler.scheduleGlobal(function()
        self:updateResultLeftTime_()
    end, 1)
end
function UnionPartyRollResultView:stopResultCountdownUpdate_()
    if self.resultCountdownUpdateHandler_ then
        scheduler.unscheduleGlobal(self.resultCountdownUpdateHandler_)
        self.resultCountdownUpdateHandler_ = nil
    end
end
function UnionPartyRollResultView:updateResultLeftTime_()
    local resultTimeLeft = checkint(self.resultEndedTime_) - getServerTime()
    display.commonLabelParams(self:getViewData().timeLabel, {text = string.fmt(__('_num_秒后自动关闭'), {_num_ = resultTimeLeft})})
end


return UnionPartyRollResultView