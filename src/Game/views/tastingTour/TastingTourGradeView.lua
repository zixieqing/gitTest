--[[
 * descpt : 品鉴之旅 评分 界面
]]
local VIEW_SIZE = display.size
local TastingTourGradeView = class('TastingTourGradeView', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.tastingTour.TastingTourGradeView'
	node:enableNodeEvents()
	return node
end)

local CreateView           = nil
local CreateScoreDetail_   = nil

local getDetailByIndex     = nil

local RES_DIR = {
    BG                 = _res("ui/tastingTour/grade/fishtravel_grade_bg_board.png"),
    AWARD_3STAR_BG     = _res("ui/tastingTour/grade/fishtravel_grade_label_award_3star.png"),
    TOTAL_LABEL_BG     = _res("ui/tastingTour/grade/fishtravel_grade_label_tatol.png"),
    BG_DETAILS         = _res("ui/tastingTour/grade/fishtravel_grade_bg_details.png"),
    SCORE_DETAILS_BG   = _res("ui/tastingTour/grade/fishtravel_grade_label_text.png"),
    BG_HINTS           = _res("ui/tastingTour/grade/fishtravel_grade_bg_hints.png"),
    BTN_RULE           = _res('ui/common/common_btn_tips.png'),
    CHEAT_TIPS         = _res('ui/common/tower_btn_quit.png'),
    BTN_WHITE          = _res('ui/common/common_btn_white_default.png'),
    BTN_ORANGE         = _res('ui/common/common_btn_orange.png'),
    GRADE_PASSED       = _res("ui/tastingTour/grade/fishtravel_grade_label_passed.png"),
    GRADE_UNPASSED     = _res("ui/tastingTour/grade/fishtravel_grade_label_text_unpassed.png"),

}

local BUTTON_TAG = {
    hint    = 100, -- 作弊
    rule    = 101, -- 规则
    comment = 102, -- 评论
    next    = 103, -- 继续
}

local tastingTourMgr = AppFacade.GetInstance():GetManager("TastingTourManager")

function TastingTourGradeView:ctor( ... )
    
    self.args = unpack({...})
    self:initialUI()
end

function TastingTourGradeView:initialUI()
    xTry(function ( )
        self.viewData_ = CreateView()
        self:addChild(self.viewData_.view)
        -- self:showUiAction()
	end, __G__TRACKBACK__)
end


function TastingTourGradeView:refreshUi(data)
    local viewData = self:getViewData()
    local totalScoreNum = viewData.totalScoreNum
    totalScoreNum:setString(data.score)
    
    local questId = data.questId
    local questConf = tastingTourMgr:GetQuestConfigDataByQuestId(questId)
    local diamondCount = viewData.diamondCount
    display.commonLabelParams(diamondCount, {text = tostring(questConf.moneyCost)})
    local diamondIcon = viewData.diamondIcon
    display.commonUIParams(diamondIcon, {po = cc.p(diamondCount:getPositionX() + display.getLabelContentSize(diamondCount).width, diamondIcon:getPositionY())})

    self:showUiAction(data, cb)
    
end

function TastingTourGradeView:updateScoreDetail(scoreDetail, index, gradeAttr, isSatisfyStar)
    
    local labelColor = nil
    local score = checkint(gradeAttr[index])
    if index == 4 then
        local isSatisfy  = score >= 0
        labelColor = isSatisfy and '#ffead7' or '#fa583c'

        local detailLabel = scoreDetail:getChildByName('detailLabel')

        local img = nil
        local text = nil
        if isSatisfyStar then
            img = RES_DIR.GRADE_PASSED
            text = __('通过')
        else
            img = RES_DIR.GRADE_UNPASSED
            text = __('未通过')
        end
        scoreDetail:setTexture(img)
        display.commonLabelParams(detailLabel, {text = text})
    else
        local scoreLabel = scoreDetail:getChildByName('scoreLabel')
        display.commonLabelParams(scoreLabel, {text = score})
        scoreLabel:setVisible(false)
    end
end

CreateView = function ()
    local view = display.newLayer()
    local size = view:getContentSize()
    
    local actionButtons = {}
    
    local shallowLayer = display.newLayer(0, 0, {color = cc.c4b(0, 0, 0, 0), enable = false})
    view:addChild(shallowLayer)

    local bgLayer = display.newLayer(display.SAFE_R + 60, display.cy - 86, {ap = display.RIGHT_CENTER, bg = RES_DIR.BG})
    local bgSize = bgLayer:getContentSize()
    view:addChild(bgLayer)
    
    -- star layer
    local starLayerSize = cc.size(450, 100)
    local starLayer = display.newLayer(bgSize.width / 2, bgSize.height - 126, {ap = display.CENTER, size = starLayerSize})
    bgLayer:addChild(starLayer)

    local spineAnimation = sp.SkeletonAnimation:create(
            'effects/tastingTour/pingfen.json',
            'effects/tastingTour/pingfen.atlas',
        1
    )
    spineAnimation:update(0)
    -- spineAnimation:addAnimation(0, 'mogu2', false)
    spineAnimation:setPosition(cc.p(starLayerSize.width / 2, 0))
    starLayer:addChild(spineAnimation)
    local spineAnimationEffect = sp.SkeletonAnimation:create(
            'effects/tastingTour/pingfen_effect.json',
            'effects/tastingTour/pingfen_effect.atlas',
            1
    )
    spineAnimationEffect:update(0)
    -- spineAnimation:addAnimation(0, 'mogu2', false)
    spineAnimationEffect:setPosition(cc.p(starLayerSize.width / 2, 0))
    starLayer:addChild(spineAnimationEffect)

    
    -- totalScore
    local totalScoreBg = display.newImageView(RES_DIR.TOTAL_LABEL_BG, bgSize.width / 2, bgSize.height - 218, {ap = display.CENTER})
    local totalScoreBgSize = totalScoreBg:getContentSize()
    bgLayer:addChild(totalScoreBg)
    
    local totalScoreLabel = display.newLabel(20, totalScoreBgSize.height / 2, {ap = display.LEFT_CENTER, fontSize = 32, color = '#ffebcc', text = __('总分')})
    totalScoreBg:addChild(totalScoreLabel)

    -- local totalScoreNum = display.newLabel(totalScoreBgSize.width - 20, totalScoreBgSize.height / 2, {ap = display.RIGHT_CENTER, fontSize = 32, color = '#FFC541', text = 100})
    -- totalScoreBg:addChild(totalScoreNum)
    local totalScoreNum = cc.Label:createWithBMFont('font/team_ico_fight_figure_2.fnt', '')--
    totalScoreNum:setAnchorPoint(display.RIGHT_CENTER)
    totalScoreNum:setHorizontalAlignment(display.TAR)
    totalScoreNum:setPosition(cc.p(totalScoreBgSize.width - 20, totalScoreBgSize.height / 2))
    totalScoreBg:addChild(totalScoreNum)

    local detailsBg = display.newImageView(RES_DIR.BG_DETAILS, bgSize.width / 2, bgSize.height - 263, {ap = display.CENTER_TOP})
    local detailsBgSize = detailsBg:getContentSize()
    bgLayer:addChild(detailsBg)

    local scoreDetails = {}
    local scoreDetailSize = nil
    for i = 1, 4 do
        local scoreDetail = CreateScoreDetail_(i)
        if scoreDetailSize == nil then scoreDetailSize = scoreDetail:getContentSize() end
        display.commonUIParams(scoreDetail, {po = cc.p(detailsBgSize.width / 2, detailsBgSize.height - 32 - (i - 1) * (scoreDetailSize.height + 3)), ap = display.CENTER_TOP})
        detailsBg:addChild(scoreDetail)
        table.insert(scoreDetails, scoreDetail)
    end

    -- 查看提示
    local hintLayerSize = cc.size(420, 61)
    local hintLayer = display.newLayer(bgSize.width / 2, detailsBg:getPositionY() - detailsBgSize.height - 7, {size = hintLayerSize, ap = display.CENTER_TOP})
    bgLayer:addChild(hintLayer)
    hintLayer:setVisible(false)

    local hintsBtn = display.newButton(hintLayerSize.width / 2, hintLayerSize.height / 2, {ap = display.CENTER, n = RES_DIR.BG_HINTS})
    local hintsBtnSize = hintsBtn:getContentSize()
    actionButtons[tostring(BUTTON_TAG.hint)] = hintsBtn
    hintLayer:addChild(hintsBtn)
    
    local hintAnimation = sp.SkeletonAnimation:create(
            'effects/tastingTour/hint.json',
            'effects/tastingTour/hint.atlas',
            1
    )
    hintAnimation:update(0)
    hintAnimation:addAnimation(0, 'idle', true)
    hintAnimation:setPosition(cc.p(67, hintsBtnSize.height / 2))
    hintsBtn:addChild(hintAnimation)

    local cheatTipsBgSize = cc.size(208, 47)
    local cheatTipsBg = display.newImageView(RES_DIR.CHEAT_TIPS, 110, hintsBtnSize.height / 2, {ap = display.LEFT_CENTER, scale9 = true, size = cheatTipsBgSize})
    hintsBtn:addChild(cheatTipsBg)

    local cheatTipsBgLayer = display.newLayer(110, hintsBtnSize.height / 2, {ap = display.LEFT_CENTER, size = cheatTipsBgSize})
    hintsBtn:addChild(cheatTipsBgLayer)
    cheatTipsBgLayer:setVisible(false)

    local cheatTipLabel = display.newLabel(18, cheatTipsBgSize.height / 2, {ap = display.LEFT_CENTER, fontSize = 20, color = '#ffffff', text = __('查看提示')})
    local cheatTipLabelSize = display.getLabelContentSize(cheatTipLabel)
    cheatTipsBgLayer:addChild(cheatTipLabel)
    
    local diamondCount = display.newLabel(cheatTipLabel:getPositionX() + cheatTipLabelSize.width, cheatTipsBgSize.height / 2, fontWithColor(14, {text = 100, ap = display.LEFT_CENTER}))
    local diamondCountSize = display.getLabelContentSize(diamondCount)
    cheatTipsBgLayer:addChild(diamondCount)

    local diamondIcon = display.newImageView(CommonUtils.GetGoodsIconPathById(DIAMOND_ID), diamondCount:getPositionX() + diamondCountSize.width, diamondCountSize.height / 2 + 8, {ap = display.LEFT_CENTER})
    diamondIcon:setScale(0.2)
    cheatTipsBgLayer:addChild(diamondIcon)

    local lookCheatTipLabel = display.newLabel(cheatTipsBgSize.width / 2, cheatTipsBgSize.height / 2, {ap = display.CENTER, fontSize = 20, color = '#ffffff', text = __('查看提示')})
    cheatTipsBg:addChild(lookCheatTipLabel)

    -- rule
    local ruleBtn = display.newButton(hintsBtn:getPositionX() + hintsBtnSize.width / 2 + 10, hintsBtnSize.height / 2, {n = RES_DIR.BTN_RULE})
    actionButtons[tostring(BUTTON_TAG.rule)] = ruleBtn
    hintLayer:addChild(ruleBtn)

    -- button layer 
    local btnLayerSize = cc.size(400, 65)
    local btnLayer = display.newLayer(bgSize.width / 2, bgSize.height - 655, {ap = display.CENTER, size = btnLayerSize})
    bgLayer:addChild(btnLayer)
    btnLayer:setVisible(false)

    local commentBtn = display.newButton(0, btnLayerSize.height / 2, {n = RES_DIR.BTN_WHITE, ap = display.LEFT_CENTER})
    display.commonLabelParams(commentBtn, fontWithColor('14', {text = __('评论')}))
    actionButtons[tostring(BUTTON_TAG.comment)] = commentBtn
    btnLayer:addChild(commentBtn)

    local nextBtn = display.newButton(btnLayerSize.width, commentBtn:getPositionY(), {n = RES_DIR.BTN_ORANGE, ap = display.RIGHT_CENTER})
    display.commonLabelParams(nextBtn, fontWithColor('14', {text = __('继续')}))
    actionButtons[tostring(BUTTON_TAG.next)] = nextBtn
    btnLayer:addChild(nextBtn)

    return {
        view                 = view,
        shallowLayer         = shallowLayer,
        totalScoreNum        = totalScoreNum,
        scoreDetails         = scoreDetails,
        spineAnimation       = spineAnimation,
        spineAnimationEffect = spineAnimationEffect,
        hintLayer            = hintLayer,
        cheatTipsBgLayer     = cheatTipsBgLayer,
        diamondCount         = diamondCount,
        diamondIcon          = diamondIcon,
        lookCheatTipLabel    = lookCheatTipLabel,
        btnLayer             = btnLayer,
        actionButtons        = actionButtons,
    }
end

CreateScoreDetail_ = function (index)
    local scoreDetailBg = display.newImageView()
    
    local detailLabel = nil
    if index ~= 4 then
        scoreDetailBg:setTexture(RES_DIR.SCORE_DETAILS_BG)
        local scoreDetailBgSize = scoreDetailBg:getContentSize()

        detailLabel = display.newLabel(28, scoreDetailBgSize.height / 2, {ap = display.LEFT_CENTER, fontSize = 20, color = '#ffead7', text = getDetailByIndex(index)})

        local scoreLabel = display.newLabel(scoreDetailBgSize.width - 50, scoreDetailBgSize.height / 2, {ap = display.CENTER, fontSize = 28, color = '#ffebcc', text = '+11'})
        scoreLabel:setName('scoreLabel')
        scoreDetailBg:addChild(scoreLabel)
    else
        scoreDetailBg:setTexture(RES_DIR.GRADE_PASSED)
        local scoreDetailBgSize = scoreDetailBg:getContentSize()
        
        detailLabel = display.newLabel(scoreDetailBgSize.width / 2, scoreDetailBgSize.height / 2, {ap = display.CENTER, fontSize = 36, font = TTF_GAME_FONT, ttf = true, color = '#ffffff', text = __('未通过')})
    end
    detailLabel:setName('detailLabel')
    scoreDetailBg:addChild(detailLabel)

    return scoreDetailBg
end

getDetailByIndex = function (index)
    local text = ''
    if index == 1 then
        text = __('食物得分')
    elseif index == 2 then
        text = __('餐厅美观度')
    elseif index == 3 then
        text = __('评委心情')
    elseif index == 4 then
        text = __('是否符合题目要求')
    end
    return text
end

function TastingTourGradeView:showUiAction(data, cb)
    local anis         = {}
    local viewData     = self:getViewData()
    local gradeAttr    = data.gradeAttr or {}
    
    -- 1.创建多有 条目 动画
    local starNum              = checkint(data.starNum)
    local isSatisfyStar        = starNum >= 3
    local scoreDetails         = viewData.scoreDetails
    local scoreDetailAnis      = self:createAllScoreDetail(isSatisfyStar, gradeAttr)

    -- 2.创建 所有 蘑菇动画
    local isSatisfy4           = gradeAttr and checkint(gradeAttr[4]) > 0
    local mushroomAnis         = self:createAllMushroomAni(starNum, isSatisfy4)

    -- 3.创建 其他动画
    local secretStatus = checkint(data.secretStatus)
    local rewards = data.rewards
    local otherAni = self:createOtherAni(secretStatus, isSatisfyStar, rewards)

    -- 4.合并动画列表
    for i, ani in ipairs(scoreDetailAnis) do
        table.insert(anis, ani)
    end

    for i, ani in ipairs(mushroomAnis) do
        table.insert(anis, ani)
    end

    for i, ani in ipairs(otherAni) do
        table.insert(anis, ani)
    end

    -- 5.执行动画
    local action = cc.Spawn:create(
        unpack(anis)
    )
    self:runAction(action)
end

function TastingTourGradeView:createAllScoreDetail(isSatisfyStar, gradeAttr)
    local viewData     = self:getViewData()
    local scoreDetails = viewData.scoreDetails
    -- 所有条目的 延迟时间
    local scoreDetailDelayTimes = {
        0,
        25 / 30,
        50 / 30,
        95 / 30,
    }

    local scoreDetailAction = function (index, posX, delayTime, moveTime)
        moveTime = moveTime or 8 / 30
        -- local scoreDetail = scoreDetails[index]
        local ac = cc.Sequence:create(
            cc.DelayTime:create(delayTime), cc.Spawn:create(
                cc.FadeTo:create(moveTime, 255),
                cc.MoveTo:create(moveTime, cc.p(posX, scoreDetails[index]:getPositionY()))
            ), cc.CallFunc:create(function ()
                if index ~= 4 then
                    local scoreLabel = scoreDetails[index]:getChildByName('scoreLabel')
                    scoreLabel:setVisible(true)
                end
            end)
        )
        return ac
    end


    local scoreDetailAnis = {}
    for i, scoreDetail in ipairs(scoreDetails) do
        local posx = scoreDetail:getPositionX()
        scoreDetail:setOpacity(0)
        scoreDetail:setPositionX(posx * 4)
        
        self:updateScoreDetail(scoreDetail, i, gradeAttr, isSatisfyStar)

        local scoreDetailAni = scoreDetailAction(i, posx, scoreDetailDelayTimes[i], nil)
        local targetAni = self:setTargetedAni(scoreDetail, scoreDetailAni)
        table.insert(scoreDetailAnis, targetAni)
    end

    return scoreDetailAnis
end

function TastingTourGradeView:createAllMushroomAni(starNum, isSatisfy4)
    local mushroomAnis = {}
    local viewData             = self:getViewData()
    local spineAnimation       = viewData.spineAnimation
    local spineAnimationEffect = viewData.spineAnimationEffect
    -- 蘑菇动画延迟时间
    local mushroomDelayTimes = {
        10 / 30,
        30 / 30,
        60 / 30,
        85 / 30
    }

    local addSpineAnimation = function (delayTime, aniName)
        local ac = cc.Sequence:create(
            cc.DelayTime:create(delayTime), cc.CallFunc:create(
                function ()
                    spineAnimation:addAnimation(0, aniName, false)
                    local x, y = string.find(aniName , "qie")
                    if  x   then
                        spineAnimationEffect:addAnimation(0, aniName, true)
                    else
                        spineAnimationEffect:addAnimation(0, aniName, false)
                    end
                end
            )
        )
        return ac
    end

    local maxCount = starNum + 1
    for i = 1, maxCount do
        -- 1 星 和 2星
        if i == 3 and starNum == 2 then break end

        local ani = nil
        local aniName = ''
        if i == maxCount and starNum == 3 then
            aniName = isSatisfy4 and 'mogu4_1' or 'mogu4_2'
        else
            aniName = 'mogu' .. i
        end
        
        ani = self:setTargetedAni(spineAnimation, addSpineAnimation(mushroomDelayTimes[i], aniName))
        table.insert(mushroomAnis, ani)
    end

    -- 切蘑菇 动画
    local cutAction = self:setTargetedAni(spineAnimation, addSpineAnimation(105 / 30, 'qie' .. checkint(starNum)))
    table.insert(mushroomAnis, cutAction)
    return mushroomAnis
end

function TastingTourGradeView:createOtherAni(secretStatus, isSatisfyStar, rewards)
    local otherAnis = {}
    local viewData             = self:getViewData()

    local totalScoreNum        = viewData.totalScoreNum
    local posx = totalScoreNum:getPositionX()
    totalScoreNum:setOpacity(0)
    totalScoreNum:setPositionX(posx * 4)

    local totalScoreNumAni = self:setTargetedAni(totalScoreNum, cc.Sequence:create(
            cc.DelayTime:create(75 / 30), cc.Spawn:create(
                cc.FadeTo:create(8 / 30, 255),
                cc.MoveTo:create(8 / 30, cc.p(posx, totalScoreNum:getPositionY()))
            )
        )
    )

    table.insert(otherAnis, totalScoreNumAni)

    local hintLayer  = viewData.hintLayer
    local hintAni = cc.Sequence:create(
        cc.DelayTime:create(145/30), cc.CallFunc:create(
            function ()
                local isSecret = secretStatus > 0
                local cheatTipsBgLayer  = viewData.cheatTipsBgLayer
                local lookCheatTipLabel = viewData.lookCheatTipLabel
                cheatTipsBgLayer:setVisible(not isSecret)
                lookCheatTipLabel:setVisible(isSecret)
                hintLayer:setVisible(not isSatisfyStar)
            end
        )
    )
    
    table.insert(otherAnis, hintAni)

    local btnLayer = viewData.btnLayer
    local btnLayerAni = cc.Sequence:create(
        cc.DelayTime:create(150/30), cc.CallFunc:create(
            function ()
                local closeFun = function ()
                    btnLayer:setVisible(true)
                end
                if isSatisfyStar then
                    AppFacade.GetInstance():GetManager("UIManager"):AddDialog('common.RewardPopup', {rewards = rewards, closeCallback = closeFun, addBackpack = false})
                else
                    closeFun()
                end
            end
        )
    )
    table.insert(otherAnis, btnLayerAni)

    return otherAnis
end


function TastingTourGradeView:setTargetedAni(node, ani)
    return cc.TargetedAction:create(node, ani)
end

-- function TastingTourGradeView:updateAllScoreDetail(scoreDetails, gradeAttr)
--     local scoreDetailRealPosXs = {}
--     for i, scoreDetail in ipairs(scoreDetails) do
--         local posx = scoreDetail:getPositionX()
--         table.insert(scoreDetailRealPosXs, posx)
--         scoreDetail:setOpacity(0)
--         scoreDetail:setPositionX(posx * 4)

--         self:updateScoreDetail(scoreDetail, i, checkint(gradeAttr[i]))
--     end
--     return scoreDetailRealPosXs
-- end

--[[
    更新买过小抄本后的界面显示
--]]
function TastingTourGradeView:UpdateAlreadyBuySercet()
    local viewData_  = self.viewData_
    viewData_.cheatTipsBgLayer:setVisible(false)
    viewData_.lookCheatTipLabel:setVisible(true)

end
function TastingTourGradeView:getViewData()
	return self.viewData_
end

return TastingTourGradeView