local OptionRoleView = class('OptionRoleView', function ()
	local node = CLayout:create(cc.size(display.width * 0.5, display.height))
	node.name = 'Game.views.counterpart.OptionRoleView'
	node:enableNodeEvents()
	return node
end)


local cardMgr = AppFacade.GetInstance():GetManager("CardManager")

function OptionRoleView:ctor( ... )
	local t = unpack({...}) or {}
    local point = t.point
    local roleCoordinateConfig = t.config
    local roleId = t.roleId
    local faceId = 1
    local roleName = ""
    local iscard = false
    self.viewData = nil
    self.isInAction = true  --是否是正常的
    local flip = (checkint(roleCoordinateConfig.flip) == 1)
    if string.match(roleId, '^%d+') then
        --数字表示是卡牌
        iscard = true
        -- 突破后的立绘不存在 使用默认立绘
        roleId = checkint(roleId)
        roleName = tostring(CardUtils.GetCardConfig(roleId).name)
    else
        iscard = false
        --角色人物
        local rInfo = gameMgr:GetRoleInfo(roleId)
        if rInfo then
            roleName = rInfo.roleName
        end
    end
    local cardView = CommonUtils.GetRoleNodeById(roleId,checkint(faceId), flip)
    -- cardView:setBackgroundColor(cc.c4b(100,100,100,100))
    local lwidth = display.width * 0.5
    -- self:setBackgroundColor(cc.c4b(100,100,100,100))
    display.commonUIParams(cardView, {ap = display.CENTER_TOP, po = cc.p(lwidth * 0.5, display.height - 40)})
    cardView:setTag(888)
    self:addChild(cardView)
    cardView:setVisible(false)
    cardView:setOpacity(0)
    if iscard then
        CommonUtils.FixAvatarLocation(cardView, roleId)
        if roleCoordinateConfig.offset and table.nums(checktable(roleCoordinateConfig.offset)) > 0 then
            local posInfo = roleCoordinateConfig.offset
            local offsetX, offsetY = posInfo.x, posInfo.y
            local x,y = cardView:getPosition()
            cardView:setPosition(cc.p(x + checkint(offsetX), y + checkint(offsetY)))
        end
    else
        --是否有配置的坐标的逻辑
        local rInfo = gameMgr:GetRoleInfo(roleId)
        if checkint(rInfo.takeaway.x) ~= 0 and checkint(rInfo.takeaway.y) ~= 0 then
            -- local offset = (display.height - 1002)
            display.commonUIParams(cardView, {ap = display.CENTER, po = cc.p(lwidth * 0.5, display.height  - checkint(rInfo.takeaway.y))})
        end
    end
    if roleCoordinateConfig.scale and string.match(roleCoordinateConfig.scale, '^%d+') then
        cardView:setScale(checkint(roleCoordinateConfig.scale)/100)
    end

    local progressBg = display.newImageView(_res('ui/home/activity/activityQuest/activity_maps_bar__l_3'))
    progressBg:setPosition(cc.p( lwidth * 0.5, 44))
    self:addChild(progressBg,10)
    progressBg:setVisible(false)

    local operaProgressBar = CProgressBar:create(_res('ui/home/activity/activityQuest/activity_maps_bar_blue_l_2'))
    operaProgressBar:setBackgroundImage(_res('ui/home/activity/activityQuest/activity_maps_bar_l_1'))
    operaProgressBar:setDirection(eProgressBarDirectionLeftToRight)
    operaProgressBar:setMaxValue(math.max(1, checkint(t.maxPoint)))
    operaProgressBar:setValue(math.min(checkint(t.curPoint) + point, operaProgressBar:getMaxValue()))
    operaProgressBar:setPosition(utils.getLocalCenter(progressBg))
    progressBg:addChild(operaProgressBar, 5)
    operaProgressBar:setShowValueLabel(true)
    display.commonLabelParams(operaProgressBar:getLabel(), fontWithColor(14, {text = tostring(checkint(t.curPoint) + point), fontSize = 30}))
    if point >= 50 then
        operaProgressBar:setProgressImage(_res('ui/home/activity/activityQuest/activity_maps_bar_red_l_2'))
    end

    local scoreLabel = display.newLabel(lwidth * 0.5 - 60, 100, fontWithColor(2, {fontSize = 50,text = __('情谊'), color = 'fff4c2', outline = 'a44500', outlineSize = 2}))
    self:addChild(scoreLabel,10)
    scoreLabel:setLocalZOrder(200)
    scoreLabel:setVisible(false)
    scoreLabel:setOpacity(0)
    local x,y = scoreLabel:getPosition()
    local scoreNumLabel = display.newLabel(x + scoreLabel:getContentSize().width * 0.5 + 50, 100, fontWithColor(2, {fontSize = 60,text = string.fmt("+__num__",{__num__ = point}), color = 'fff4c2', outline = 'a44500', outlineSize = 2}))
    self:addChild(scoreNumLabel,10)
    scoreNumLabel:setLocalZOrder(200)
    scoreNumLabel:setVisible(false)
    scoreNumLabel:setOpacity(0)

    self.viewData = {
        cardView = cardView,
        progressBg = progressBg,
        operaProgressBar = operaProgressBar,
        scoreLabel = scoreLabel,
        scoreNumLabel = scoreNumLabel,
    }
end

function OptionRoleView:onEnter()
    local animationConf = {
        bgMaskFadeInTime = 8,
        drawAppearDelayTime = 30,
        drawAppearTime = 20,
        drawMoveY = 43,
        showStarLayerDelayTime = 36
    }
	local fps = 30
    local drawNodeActionSeq = cc.Sequence:create(
        cc.DelayTime:create(animationConf.drawAppearDelayTime / fps),
        cc.Show:create(),
        cc.EaseOut:create(cc.Spawn:create(
                cc.FadeTo:create(animationConf.drawAppearTime / fps, 255),
        cc.MoveBy:create(animationConf.drawAppearTime / fps, cc.p(0, animationConf.drawMoveY))), 2))

    local numActionSeq = cc.Sequence:create(
        cc.DelayTime:create(0.2),
        cc.Show:create(),
        cc.EaseOut:create(cc.FadeTo:create(animationConf.drawAppearTime / fps, 255), 0.15))

    local actions = cc.Sequence:create(
            cc.TargetedAction:create(self.viewData.cardView, drawNodeActionSeq),
            cc.TargetedAction:create(self.viewData.progressBg,numActionSeq),
            cc.TargetedAction:create(self.viewData.scoreLabel, numActionSeq),
            cc.TargetedAction:create(self.viewData.scoreNumLabel, numActionSeq),
            cc.CallFunc:create(function()
                self.isInAction = false
            end)
        )
    self:runAction(actions)
end

return OptionRoleView


