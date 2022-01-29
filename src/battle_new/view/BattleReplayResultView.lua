--[[
新战斗失败结算界面
@params table {
	viewType ConfigBattleResultType 结算界面类型
	cleanCondition table 需要展示的三星特殊条件
	showMessage bool 是否显示给对手的留言
	canRepeatChallenge bool 是否可以重打
	teamData table 阵容信息
	trophyData table 战斗奖励信息
}
--]]
local BattleSuccessView = __Require('battle.view.BattleSuccessView')
local BattleReplayResultView = class('BattleReplayResultView', BattleSuccessView)


local RES_DICT = {
    BG_MASK    = _res('ui/common/common_bg_mask_2.png'),
    WHITE_BTN  = _res('ui/common/common_btn_white_default.png'),
    ORANGE_BTN = _res('ui/common/common_btn_orange.png'),
    MARRY_SPN  = _spn('effects/marry/fly'),
}


--[[
constructor
--]]
function BattleReplayResultView:ctor( ... )
    local args = unpack({...})
    self.enemyTeamData = args.enemyTeamData
    self.battleResult  = args.battleResult
    
	BattleSuccessView.ctor(self, ...)
end


function BattleReplayResultView:InitUI()
    local commonLayer = self:InitCommonLayer()
	table.insert(self.layers, commonLayer)

	self:RegistBtnClickHandler()
end


function BattleReplayResultView:InitCommonLayer()
    local layerSize = cc.size(display.SAFE_RECT.width, display.SAFE_RECT.height)

    local designSize  = cc.size(1334, 750)
    local winSize     = display.size
    local deltaHeight = (winSize.height - designSize.height) * 0.5
    local animationConf = {
        drawNodeScale       = 0.7,
        drawNodeOffX        = 60,
        drawNodeOffY        = 100,
        marrySpineOffX      = 300,
        marrySpineOffY      = deltaHeight,
        resultOffY          = 100,
        resultFontSize      = 60,
        drawMoveY           = 43,
        hideMoveTime        = 15,
        hideMoveY           = 85,
        bgMaskFadeInTime    = 8,
        drawAppearDelayTime = 30,
        drawAppearTime      = 20,
    }


    -- 遮罩
    local bgMask = ui.image({img = RES_DICT.BG_MASK, p = display.center, enable = true, scale9 = true, size = display.size})
    ui.bindClick(bgMask, function(sender)
        if self.canTouch then
            self:ShowNextLayer()
        end
    end, false)
    self:add(bgMask)

    local attackMast = ui.layer({size = cc.size(display.width/2, display.height), enable = true, color = cc.r4b(0)})
    ui.bindClick(attackMast, function(sender)
        if self.canTouch then
            for i,v in ipairs(self.teamData) do
                local cardId = checkint(v.cardId)
                if cardId > 0 then
                    CommonUtils.PlayCardSoundByCardId(cardId, SoundType.TYPE_BATTLE_FAIL, SoundChannel.BATTLE_RESULT)
                    break
                end
            end
            self:ShowNextLayer()
        end
    end, false)
    self:addChild(attackMast)

    local defendMast = ui.layer({size = cc.size(display.width/2, display.height), enable = true, color = cc.r4b(0)})
    ui.bindClick(defendMast, function(sender)
        if self.canTouch then
            for i,v in ipairs(self.enemyTeamData) do
                local cardId = checkint(v.cardId)
                if cardId > 0 then
                    CommonUtils.PlayCardSoundByCardId(cardId, SoundType.TYPE_BATTLE_FAIL, SoundChannel.BATTLE_RESULT)
                    break
                end
            end
            self:ShowNextLayer()
        end
    end, false)
    defendMast:setPositionX(display.cx)
    self:addChild(defendMast)


    -------------------------------------------------
    -- 进攻方立绘
	local attackLeaderData = checktable(self.teamData[1])
    local attackDrawNode   = ui.cardDrawNode({skinId = checkint(attackLeaderData.skinId), coordinateType = COORDINATE_TYPE_CAPSULE})
    attackDrawNode.shopPos = cc.p(display.SAFE_L + animationConf.drawNodeOffX, display.cy - 320 + animationConf.drawNodeOffY)
    attackDrawNode.hidePos = cc.p(attackDrawNode.shopPos.x, attackDrawNode.shopPos.y - animationConf.drawMoveY)
    attackDrawNode:setScale(animationConf.drawNodeScale)
	self:addChild(attackDrawNode)
    
    local atkMarrySpine = nil
	if app.cardMgr.GetFavorabilityMax(attackLeaderData.favorLevel) then
        atkMarrySpine = ui.spine({path = RES_DICT.MARRY_SPN, init = 'idle2'})
        atkMarrySpine:setPosition(cc.p(display.SAFE_L + animationConf.marrySpineOffX, animationConf.marrySpineOffY))
        self:addChild(atkMarrySpine)
    end
    
    -- 防守方立绘
	local defendLeaderData = checktable(self.enemyTeamData[1])
    local defendDrawNode   = ui.cardDrawNode({skinId = checkint(defendLeaderData.skinId), coordinateType = COORDINATE_TYPE_CAPSULE})
    defendDrawNode.shopPos = cc.p(display.SAFE_R - animationConf.drawNodeOffX, display.cy - 320 + animationConf.drawNodeOffY)
    defendDrawNode.hidePos = cc.p(defendDrawNode.shopPos.x, defendDrawNode.shopPos.y - animationConf.drawMoveY)
    defendDrawNode:setScale(-animationConf.drawNodeScale, animationConf.drawNodeScale)
	self:addChild(defendDrawNode)
    
    local defMarrySpine = nil
    if app.cardMgr.GetFavorabilityMax(defendLeaderData.favorLevel) then
        defMarrySpine = ui.spine({path = RES_DICT.MARRY_SPN, init = 'idle2'})
        defMarrySpine:setPosition(cc.p(display.SAFE_R - animationConf.marrySpineOffX, animationConf.marrySpineOffY))
        self:addChild(defMarrySpine)
    end

    if self.battleResult == BattleResult.BR_SUCCESS then
        defendDrawNode:setFilterName(filter.TYPES.GRAY)
    elseif self.battleResult == BattleResult.BR_FAIL then
        attackDrawNode:setFilterName(filter.TYPES.GRAY)
    end


    -------------------------------------------------
    -- 进攻方结果
    local attackResultLayer   = ui.layer()
    attackResultLayer.shopPos = cc.p(display.width * 0.25, display.height - animationConf.resultOffY)
    attackResultLayer.hidePos = cc.p(attackResultLayer.shopPos.x, attackResultLayer.shopPos.y + animationConf.drawMoveY)
    self:addChild(attackResultLayer)

    if self.battleResult == BattleResult.BR_SUCCESS then
        local overText  = __('进攻方胜利')
        local textGroup = attackResultLayer:addList({
            ui.label({fnt = FONT.D1, fontSize = animationConf.resultFontSize, color = '#F58829', text = overText, ml = 3, mt = 3}),
            ui.label({fnt = FONT.D20, fontSize = animationConf.resultFontSize, color = '#FFD879', outline = '#B13B16', text = overText}),
        })
        ui.flowLayout(PointZero, textGroup, {type = ui.flowC, ap = ui.cc})
    elseif self.battleResult == BattleResult.BR_FAIL then
        local overText  = __('进攻方失败')
        local textGroup = attackResultLayer:addList({
            ui.label({fnt = FONT.D1, fontSize = animationConf.resultFontSize, color = '#91888D', text = overText, ml = 3, mt = 3}),
            ui.label({fnt = FONT.D20, fontSize = animationConf.resultFontSize, color = '#A7A5A3', outline = '#656464', text = overText}),
        })
        ui.flowLayout(PointZero, textGroup, {type = ui.flowC, ap = ui.cc})
    end

    -- 防守方结果
    local defendResultLayer = ui.layer()
    defendResultLayer.shopPos = cc.p(display.width * 0.75, display.height - animationConf.resultOffY)
    defendResultLayer.hidePos = cc.p(defendResultLayer.shopPos.x, defendResultLayer.shopPos.y + animationConf.drawMoveY)
    self:addChild(defendResultLayer)

    if self.battleResult == BattleResult.BR_SUCCESS then
        local overText  = __('防守方失败')
        local textGroup = defendResultLayer:addList({
            ui.label({fnt = FONT.D1, fontSize = animationConf.resultFontSize, color = '#91888D', text = overText, ml = 3, mt = 3}),
            ui.label({fnt = FONT.D20, fontSize = animationConf.resultFontSize, color = '#A7A5A3', outline = '#656464', text = overText}),
        })
        ui.flowLayout(PointZero, textGroup, {type = ui.flowC, ap = ui.cc})
    elseif self.battleResult == BattleResult.BR_FAIL then
        local overText  = __('防守方胜利')
        local textGroup = defendResultLayer:addList({
            ui.label({fnt = FONT.D1, fontSize = animationConf.resultFontSize, color = '#F58829', text = overText, ml = 3, mt = 3}),
            ui.label({fnt = FONT.D20, fontSize = animationConf.resultFontSize, color = '#FFD879', outline = '#B13B16', text = overText}),
        })
        ui.flowLayout(PointZero, textGroup, {type = ui.flowC, ap = ui.cc})
    end
    

    -------------------------------------------------
    -- 通用层节点
    local commonLayer = ui.layer()
    self:addChild(commonLayer)

    -- 添加底部信息
    local commonBottomLayer = self:AddCommonBottomLayer(commonLayer)
    

    ------------ 初始化动画状态 ------------
    bgMask:setOpacity(0)
    attackDrawNode:setVisible(false)
	attackDrawNode:setOpacity(0)
    attackDrawNode:setPosition(attackDrawNode.hidePos)
    defendDrawNode:setVisible(false)
	defendDrawNode:setOpacity(0)
    defendDrawNode:setPosition(defendDrawNode.hidePos)
    attackResultLayer:setVisible(false)
    attackResultLayer:setOpacity(0)
    attackResultLayer:setPosition(attackResultLayer.hidePos)
    defendResultLayer:setVisible(false)
    defendResultLayer:setOpacity(0)
    defendResultLayer:setPosition(defendResultLayer.hidePos)
    if atkMarrySpine then
        atkMarrySpine:setOpacity(0)
        atkMarrySpine:setVisible(false)
    end
    if defMarrySpine then
        defMarrySpine:setOpacity(0)
        defMarrySpine:setVisible(false)
    end
    

    ------------ 定义动画逻辑 ------------
    local ShowSelf = function ()
		local costFrame = 0

		------------ 显示遮罩渐变动画 ------------
        costFrame = costFrame + animationConf.bgMaskFadeInTime
		local bgMaskActionSeq = cc.Sequence:create(
            cc.FadeTo:create(costFrame / self.fps, 255)
        )
        bgMask:runAction(bgMaskActionSeq)
		------------ 显示遮罩渐变动画 ------------

        ------------ 显示立绘 ------------
        costFrame = costFrame + animationConf.drawAppearDelayTime
		local drawNodeActionSeq = cc.Sequence:create(
			cc.DelayTime:create(costFrame / self.fps),
			cc.Show:create(),
			cc.EaseOut:create(cc.Spawn:create(
				cc.FadeTo:create(animationConf.drawAppearTime / self.fps, 255),
                cc.MoveBy:create(animationConf.drawAppearTime / self.fps, cc.p(0, animationConf.drawMoveY))
            ), 2),
            cc.CallFunc:create(function()
                local marrySpienAct = cc.Sequence:create(
                    cc.Show:create(),
                    cc.FadeIn:create(0.5)
                )
				if atkMarrySpine then
					atkMarrySpine:runAction(marrySpienAct:clone())
				end
				if defMarrySpine then
					defMarrySpine:runAction(marrySpienAct:clone())
				end
			end)
		)
		attackDrawNode:runAction(drawNodeActionSeq)
		defendDrawNode:runAction(drawNodeActionSeq:clone())  -- 测试发现 CallFunc 不会被克隆，所以这里不会再次执行，不用担心执行两次。
        ------------ 显示立绘 ------------

        ------------ 显示结果动画 ------------
        local resultActionSeq = cc.Sequence:create(
			cc.DelayTime:create(costFrame / self.fps),
			cc.Show:create(),
			cc.EaseOut:create(cc.Spawn:create(
				cc.FadeTo:create(animationConf.drawAppearTime / self.fps, 255),
                cc.MoveBy:create(animationConf.drawAppearTime / self.fps, cc.p(0, -animationConf.drawMoveY))
            ), 2),
            cc.CallFunc:create(function()
                PlayAudioClip(AUDIOS.UI.ui_war_assess.id)
			end)
		)
        attackResultLayer:runAction(resultActionSeq)
        defendResultLayer:runAction(resultActionSeq:clone())
        ------------ 显示结果动画 ------------
        
		------------ 底部的动画 ------------
		if commonBottomLayer and commonBottomLayer.ShowSelf then
			commonBottomLayer.ShowSelf(costFrame)
		end
		------------ 底部的动画 ------------
	end

	local HideSelf = function ()
		-- 屏蔽触摸
		self.canTouch = false

		-- 隐藏common层
		local commonLayerActionSeq = cc.Sequence:create(
			cc.EaseIn:create(
				cc.Spawn:create(
					cc.MoveBy:create(animationConf.hideMoveTime / self.fps, cc.p(0, animationConf.hideMoveY)),
                    cc.FadeTo:create(animationConf.hideMoveTime / self.fps, 0)
                ),
            2),
            cc.Hide:create()
        )
        commonLayer:runAction(commonLayerActionSeq:clone())

		------------ 底部的动画 ------------
		if commonBottomLayer and commonBottomLayer.ShowSelf then
			commonBottomLayer.HideSelf()
		end
		------------ 底部的动画 ------------
    end
    
	return {ShowSelf = ShowSelf, HideSelf = HideSelf}
end


function BattleReplayResultView:AddCommonBottomLayer(parentNode)
    self.backBtn     = ui.button({n = RES_DICT.ORANGE_BTN, scale9 = true}):updateLabel({fnt = FONT.D14, text = __('退出'), paddingW = 30})
    self.atkSkadaBtn = ui.button({n = RES_DICT.WHITE_BTN, scale9 = true}):updateLabel({fnt = FONT.D14, text = __('进攻伤害'), paddingW = 30})
    self.defSkadaBtn = ui.button({n = RES_DICT.WHITE_BTN, scale9 = true}):updateLabel({fnt = FONT.D14, text = __('防守伤害'), paddingW = 30})
    parentNode:addList(self.atkSkadaBtn):alignTo(nil, ui.cb, {offsetX = -display.width * 0.25, offsetY = 50})
    parentNode:addList(self.defSkadaBtn):alignTo(nil, ui.cb, {offsetX = display.width * 0.25, offsetY = 50})
    parentNode:addList(self.backBtn):alignTo(nil, ui.cb, {offsetX = 0, offsetY = 50})


    ------------ 初始化动画状态 ------------
    self.backBtn:setVisible(false)
    self.backBtn:setOpacity(0)
    self.atkSkadaBtn:setVisible(false)
    self.atkSkadaBtn:setOpacity(0)
    self.defSkadaBtn:setVisible(false)
    self.defSkadaBtn:setOpacity(0)


    ------------ 定义动画逻辑 ------------
    local ShowSelf = function(delayFrame)
        local btnActionSeq = cc.Sequence:create(
            cc.DelayTime:create(delayFrame / self.fps),
            cc.Show:create(),
            cc.FadeTo:create(0.5, 255),
            cc.CallFunc:create(function ()
                ------------ 动画完成 可以点击 ------------
                self.canTouch = true
                ------------ 动画完成 可以点击 ------------
            end)
        )
        self.backBtn:runAction(btnActionSeq)

        if GAME_MODULE_OPEN.BATTLE_SKADA then
            self.atkSkadaBtn:runAction(btnActionSeq:clone())
            self.defSkadaBtn:runAction(btnActionSeq:clone())
        end
    end

    local HideSelf = function(delayFrame)
    end

    return {ShowSelf = ShowSelf, HideSelf = HideSelf}
end


function BattleReplayResultView:UpdateLocalData()
end


function BattleReplayResultView:RegistBtnClickHandler()
	if nil ~= self.backBtn then
		display.commonUIParams(self.backBtn, {cb = handler(self, self.BackClickCallback)})
	end

	if nil ~= self.atkSkadaBtn then
		display.commonUIParams(self.atkSkadaBtn, {cb = handler(self, self.AtkSkadaClickHandler)})
	end

	if nil ~= self.defSkadaBtn then
		display.commonUIParams(self.defSkadaBtn, {cb = handler(self, self.DefSkadaClickHandler)})
	end
end


function BattleReplayResultView:AtkSkadaClickHandler(sender)
	if G_BattleMgr:GetBattleInvalid() then return end
	PlayAudioByClickNormal()
	G_BattleMgr:ShowSkada(false)
end

function BattleReplayResultView:DefSkadaClickHandler(sender)
	if G_BattleMgr:GetBattleInvalid() then return end
	PlayAudioByClickNormal()
	G_BattleMgr:ShowSkada(true)
end


return BattleReplayResultView
