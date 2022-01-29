--[[
 * author : kaishiqi
 * descpt : 工会派对 - ROLL点界面
]]
local UnionPartyRollRewardsView = class('UnionPartyRollRewardsView', function()
    return display.newLayer(0, 0, {name = 'Game.views.union.UnionPartyRollRewardsView'})
end)

local RES_DICT = {
    BG_FRAME          = 'ui/union/roll/guild_party_roll_bg.png',
    TITLE_IMG         = 'ui/union/roll/party_roll_title.png',
    PROGRESS_BAR_D    = 'ui/union/roll/party_roll_bar_bg.png',
    PROGRESS_BAR_S    = 'ui/union/roll/party_roll_bar.png',
    REWARDS_FRAME     = 'ui/union/roll/party_roll_reward_bg.png',
    REWARDS_TITLE     = 'ui/union/roll/party_roll_reward_title.png',
    BTN_CANCEL        = 'ui/common/common_btn_white_default.png',
    BTN_CONFIRM       = 'ui/common/common_btn_orange.png',
    MEMBER_TITLE      = 'ui/union/roll/party_roll_people_title.png',
    MEMBER_FRAME      = 'ui/union/roll/party_roll_bg_people.png',
    MEMBER_CELL_BLACK = 'ui/union/roll/party_roll_bg_people_frame_black.png',
    MEMBER_CELL_BG_S  = 'ui/union/roll/party_roll_bg_people_frame_me.png',
    MEMBER_CELL_BG_N  = 'ui/union/roll/party_roll_bg_people_frame.png',
}

local CreateView       = nil
local CreateMemberCell = nil

local RANK_COLOR_MAP = {
    ['1'] = '#FF591F',
    ['2'] = '#FF8E1F',
    ['3'] = '#FFC350',
    ['4'] = '#E9FF90',
}


function UnionPartyRollRewardsView:ctor(args)
    -- create view
    self.viewData_ = CreateView()
    self:addChild(self.viewData_.view)

    -- update views
    self:updateRollStatus(false)
    self:hideRewardsView(true)
end


CreateView = function()
    local view = display.newLayer()
    local size = view:getContentSize()

    -- block bg
    local blockBg = display.newLayer(0, 0, {color = cc.c4b(0,0,0,100), enable = true})
    view:addChild(blockBg)

    -- content layer
    local contentLayer = display.newLayer(size.width/2, size.height/2, {bg = _res(RES_DICT.BG_FRAME), ap = display.CENTER})
    local contentSize  = contentLayer:getContentSize()
    view:addChild(contentLayer)

    -------------------------------------------------
    -- left content
    local leftContentX = contentSize.width/2 - 172
    local label = display.newLabel(leftContentX, contentSize.height - 60 , fontWithColor(14, {text = __('幸运派对小飨饼') , color = "#ff7b20" , outline = "#631a1a" , outlineSize = 3 }))
    contentLayer:addChild(label)

    -- terminal progressBar
    local terminalProgressPos = cc.p(leftContentX, contentSize.height - 150)
    local terminalProgressBar = CProgressBar:create(_res(RES_DICT.PROGRESS_BAR_S))
    terminalProgressBar:setBackgroundImage(_res(RES_DICT.PROGRESS_BAR_D))
    terminalProgressBar:setDirection(eProgressBarDirectionLeftToRight)
    terminalProgressBar:setPosition(terminalProgressPos)
    terminalProgressBar:setAnchorPoint(display.CENTER)
    terminalProgressBar:setMaxValue(100)
    terminalProgressBar:setValue(0)
    contentLayer:addChild(terminalProgressBar)

    -- terminal label
    local terminalTimePoint = cc.p(terminalProgressPos.x - terminalProgressBar:getContentSize().width/2, terminalProgressPos.y + 30)
    local terminalTimeLabel = display.newLabel(terminalTimePoint.x, terminalTimePoint.y, fontWithColor(1, {fontSize = 22, color = '#7E2B1A', ap = display.LEFT_CENTER}))
    contentLayer:addChild(terminalTimeLabel)

    -- rewards frame
    local rewardsFrameSize  = cc.size(600, 230)
    local rewardsFramePoint = cc.p(leftContentX, 230)
    contentLayer:addChild(display.newImageView(_res(RES_DICT.REWARDS_FRAME), rewardsFramePoint.x, rewardsFramePoint.y, {scale9 = true, size = rewardsFrameSize}))

    -- rewards titleBar
    local rewardsTitleBar = display.newButton(rewardsFramePoint.x, rewardsFramePoint.y + rewardsFrameSize.height/2 - 25, {n = _res(RES_DICT.REWARDS_TITLE), enable = false})
    display.commonLabelParams(rewardsTitleBar, fontWithColor(16, {text = __('奖励预览')}))
    contentLayer:addChild(rewardsTitleBar)

    -- rewards iconList
    local rewardsDefines = {
        {color = RANK_COLOR_MAP['4']},
        {color = RANK_COLOR_MAP['3']},
        {color = RANK_COLOR_MAP['2']},
        {color = RANK_COLOR_MAP['1']},
    }
    local rewardsIconList = {}
    local rewardsIconPos  = cc.p(rewardsFramePoint.x + rewardsFrameSize.width/2 - 5, rewardsFramePoint.y - rewardsFrameSize.height/2 + 5)
    for i, rewardsDefine in ipairs(rewardsDefines) do
        local rewardsIconIndex = #rewardsDefines - i + 1
        local rewardsFramePath = string.format('ui/union/roll/party_roll_reward_no%d.png', rewardsIconIndex)
        local rewardsIconFrame = display.newImageView(_res(rewardsFramePath), rewardsIconPos.x, rewardsIconPos.y, {ap = display.RIGHT_BOTTOM})
        local rewardsFrameSize = rewardsIconFrame:getContentSize()
        contentLayer:addChild(rewardsIconFrame)

        local rewardsNumText  = string.fmt(__('第_num_名'), {_num_ = rewardsIconIndex})
        local rewardsNumPoint = cc.p(rewardsIconPos.x - rewardsFrameSize.width/2, rewardsIconPos.y + rewardsFrameSize.height - 25)
        local rewardsNumLabel = display.newLabel(rewardsNumPoint.x, rewardsNumPoint.y, fontWithColor(14, {fontSize = 26, color = rewardsDefine.color, text = rewardsNumText}))
        contentLayer:addChild(rewardsNumLabel)
        
        local rewardsIconLayer = display.newLayer(rewardsNumPoint.x, rewardsIconPos.y + 12, {ap = display.CENTER_BOTTOM})
        rewardsIconLayer:setScale(1 - (rewardsIconIndex - 1) / 10)
        contentLayer:addChild(rewardsIconLayer)
        
        rewardsIconList[rewardsIconIndex] = rewardsIconLayer
        rewardsIconPos.x = rewardsIconPos.x - rewardsFrameSize.width + 6
    end

    -- giveUp button
    local giveUpBtn = display.newButton(leftContentX - 120, 65, {n = _res(RES_DICT.BTN_CANCEL)})
    display.commonLabelParams(giveUpBtn, fontWithColor(14, {text = __('放 弃')}))
    contentLayer:addChild(giveUpBtn)

    -- toRoll button
    local toRollButton = display.newButton(leftContentX + 120, giveUpBtn:getPositionY(), {n = _res(RES_DICT.BTN_CONFIRM)})
    display.commonLabelParams(toRollButton, fontWithColor(14, {text = __('试试运气')}))
    contentLayer:addChild(toRollButton)

    -- waitResult tips
    local waitResultTips = display.newLabel(leftContentX, giveUpBtn:getPositionY(), fontWithColor(16, {text = __('请等待统计其余成员结果')}))
    contentLayer:addChild(waitResultTips)
    

    -------------------------------------------------
    -- right content
    local rightContentX = contentSize.width/2 + 308

    -- member frame
    local memberFrameSize = cc.size(336, 456)
    local memberFramePos  = cc.p(rightContentX, contentSize.height/2)
    contentLayer:addChild(display.newImageView(_res(RES_DICT.MEMBER_FRAME), memberFramePos.x, memberFramePos.y, {scale9 = true, size = memberFrameSize}))
    
    -- memberTittle bar
    local memberTitleBar = display.newButton(memberFramePos.x, contentSize.height - 35, {n = _res(RES_DICT.MEMBER_TITLE), enable = false})
    display.commonLabelParams(memberTitleBar, fontWithColor(14, {text = __('派对成员')}))
    contentLayer:addChild(memberTitleBar)

    -- member gridView
    local memberGridSize = cc.size(memberFrameSize.width - 4, memberFrameSize.height - 4)
    local memberGridView = CGridView:create(memberGridSize)
    memberGridView:setSizeOfCell(cc.size(memberGridSize.width, 52))
    memberGridView:setAnchorPoint(display.CENTER)
    memberGridView:setPosition(memberFramePos)
    memberGridView:setColumns(1)
    contentLayer:addChild(memberGridView)
    
    -- memberStatus rLabel
    local memberStatusRLabel = display.newRichLabel(memberFramePos.x, 30)
    contentLayer:addChild(memberStatusRLabel)

    return {
        view                = view,
        contentLayer        = contentLayer,
        terminalProgressBar = terminalProgressBar,
        terminalTimeLabel   = terminalTimeLabel,
        rewardsIconList     = rewardsIconList,
        waitResultTips      = waitResultTips,
        giveUpBtn           = giveUpBtn,
        toRollButton        = toRollButton,
        memberGridView      = memberGridView,
        memberStatusRLabel  = memberStatusRLabel,
    }
end


CreateMemberCell = function(size)
    local view = CGridViewCell:new()
    view:setContentSize(size)

    local cellLayer = display.newLayer()
    view:addChild(cellLayer)

    local normalBg = display.newImageView(_res(RES_DICT.MEMBER_CELL_BG_N), size.width/2, size.height/2)
    local selectBg = display.newImageView(_res(RES_DICT.MEMBER_CELL_BG_S), size.width/2, size.height/2)
    cellLayer:addChild(normalBg)
    cellLayer:addChild(selectBg)

    local nameLabel = display.newLabel(10, size.height/2, fontWithColor(16, {fontSize = 24, ap = display.LEFT_CENTER}))
    cellLayer:addChild(nameLabel)

    local scoreLabel = display.newLabel(size.width - 10, size.height/2, fontWithColor(20, {fontSize = 24, ap = display.RIGHT_CENTER}))
    cellLayer:addChild(scoreLabel)

    local giveUpLabel = display.newLabel(scoreLabel:getPositionX(), size.height/2, fontWithColor(14, {fontSize = 22, color = '#7e6454', ap = display.RIGHT_CENTER, text = __('放弃')}))
    cellLayer:addChild(giveUpLabel)

    local blackFg = display.newImageView(_res(RES_DICT.MEMBER_CELL_BLACK), size.width/2, size.height/2)
    cellLayer:addChild(blackFg)

    return {
        view        = view,
        cellLayer   = cellLayer,
        normalBg    = normalBg,
        selectBg    = selectBg,
        blackFg     = blackFg,
        nameLabel   = nameLabel,
        scoreLabel  = scoreLabel,
        giveUpLabel = giveUpLabel,
    }
end


function UnionPartyRollRewardsView:getViewData()
    return self.viewData_
end


function UnionPartyRollRewardsView:showRewardsView(isFast)
    self:getViewData().contentLayer:stopAllActions()
    if isFast then
        self:getViewData().contentLayer:setScale(1)
    else
        self:getViewData().contentLayer:runAction(cc.ScaleTo:create(0.2, 1))
    end
end
function UnionPartyRollRewardsView:hideRewardsView(isFast)
    self:getViewData().contentLayer:stopAllActions()
    if isFast then
        self:getViewData().contentLayer:setScale(0)
    else
        self:getViewData().contentLayer:runAction(cc.ScaleTo:create(0.2, 0))
    end
end


function UnionPartyRollRewardsView:getRankIndexColor(index)
    return RANK_COLOR_MAP[tostring(index)] or '#FFFFFF'
end


function UnionPartyRollRewardsView:updateRollStatus(isRolled)
    local isRolled = isRolled == true
    self:getViewData().giveUpBtn:setVisible(not isRolled)
    self:getViewData().toRollButton:setVisible(not isRolled)
    self:getViewData().waitResultTips:setVisible(isRolled)
end


function UnionPartyRollRewardsView:updateRewardsIcon(index, goodsId, goodsNum)
    local rewardsIconLayer = self:getViewData().rewardsIconList[checkint(index)]
    if rewardsIconLayer then
        rewardsIconLayer:removeAllChildren()

        local goodsNode = require('common.GoodNode').new({id = checkint(goodsId), amount = checkint(goodsNum), showAmount = true, callBack = function(sender)
            local uiManager = AppFacade.GetInstance():GetManager('UIManager')
            uiManager:ShowInformationTipsBoard({targetNode = sender, iconId = checkint(goodsId), type = 1}) -- 1 is props
        end})
        goodsNode:setPosition(cc.p(rewardsIconLayer:getContentSize().width/2, 0))
        goodsNode:setAnchorPoint(display.CENTER_BOTTOM)
        rewardsIconLayer:addChild(goodsNode)
    end
end


function UnionPartyRollRewardsView:updateLeftMemberNum(num)
    local memberTextList = string.split2(string.fmt(__('剩余|_num_人|未选择...'), {_num_ = checkint(num)}), '|')
    display.reloadRichLabel(self:getViewData().memberStatusRLabel, {c = {
        fontWithColor(16, {text = memberTextList[1]}),
        fontWithColor(10, {text = memberTextList[2]}),
        fontWithColor(16, {text = memberTextList[3]})
    }})
end


function UnionPartyRollRewardsView:updateTimeProgress(leftTime, totalTime)
    local terminalProgressBar = self:getViewData().terminalProgressBar
    local leftTimeProgressMax = terminalProgressBar:getMaxValue()
    local leftTimeProgressNum = math.max(0, math.min(checkint(leftTime) / checkint(totalTime) * 100, leftTimeProgressMax))
    terminalProgressBar:setValue(leftTimeProgressNum)

    local leftTimeText = string.fmt(__('剩余时间：_num_秒'), {_num_ = checkint(leftTime)})
    display.commonLabelParams(self:getViewData().terminalTimeLabel, {text = leftTimeText})
end


function UnionPartyRollRewardsView:createMemberCell(size)
    return CreateMemberCell(size)
end


function UnionPartyRollRewardsView:showRollAnimation(resultNum, endedCB)
    local rollLayer = display.newLayer(0, 0, {color = cc.c4b(0,0,0,150), enable = true})
    
    -- add spine cache
    local rollSpinePath = 'ui/union/roll/lodian'
    if not SpineCache(SpineCacheName.UNION):hasSpineCacheData(rollSpinePath) then
        SpineCache(SpineCacheName.UNION):addCacheData(rollSpinePath, rollSpinePath, 1)
    end

    -- create roll spine
    local rollSpine = SpineCache(SpineCacheName.UNION):createWithName(rollSpinePath)
    rollSpine:setAnimation(0, 'play', false)
    rollSpine:setPosition(display.center)
    rollLayer:addChild(rollSpine)

    -- roll point label
    local rollSpineSize  = rollSpine:getContentSize()
    local rollPointLabel = display.newLabel(0, 0, fontWithColor(14, {fontSize = 46 , color = '#ffb136', text = tostring(resultNum)}))
    rollPointLabel:setPosition(rollSpineSize.width/2, rollSpineSize.height/2)
    rollPointLabel:setOpacity(0)
    rollPointLabel:runAction(cc.Sequence:create{
        cc.DelayTime:create(1.6),
        cc.FadeIn:create(1)
    })
    rollSpine:addChild(rollPointLabel)

    -- spine complete listen
    rollSpine:registerSpineEventHandler(function(event)
        if event.animation == 'play' then
            local actTime = 0.2
            rollLayer:runAction(cc.Sequence:create({
                cc.TargetedAction:create(rollPointLabel, cc.FadeOut:create(actTime)),
                cc.TargetedAction:create(rollSpine, cc.FadeOut:create(actTime)),
                cc.CallFunc:create(function()
                    if endedCB then endedCB() end
                end),
                cc.RemoveSelf:create()
            }))
        end
    end, sp.EventType.ANIMATION_COMPLETE)

    return rollLayer
end


return UnionPartyRollRewardsView
