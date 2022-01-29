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
local BattleFailView = class('BattleFailView', BattleSuccessView)

------------ import ------------
local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
local cardMgr = AppFacade.GetInstance('AppFacade'):GetManager("CardManager")
------------ import ------------

--[[
constructor
--]]
function BattleFailView:ctor( ... )
	BattleSuccessView.ctor(self, ...)
end
---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
@override
初始化公有层 公有层只包含立绘和结果
--]]
function BattleFailView:InitCommonLayer()
	local layerSize = cc.size(display.SAFE_RECT.width, display.SAFE_RECT.height)

	local animationConf = {
		bgMaskFadeInTime = 8,
		drawAppearDelayTime = 30,
		drawAppearTime = 20,
		drawMoveY = 43,
		hideMoveTime = 15,
		hideMoveY = 85,
		hintAppearDelayTime = 40,
		hintAppearTime = 15
	}

	-- 遮罩
	local bgMask = display.newImageView(_res('ui/common/common_bg_mask_2.png'), utils.getLocalCenter(self).x, utils.getLocalCenter(self).y,
		{enable = true, animate = false, scale9 = true, size = display.size,
	cb = function (sender)
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
	end})
	self:addChild(bgMask)

	-- 通用层节点
	local commonLayer = display.newLayer(display.SAFE_L + layerSize.width * 0.5, layerSize.height * 0.5,
		{size = layerSize, ap = cc.p(0.5, 0.5)})
	self:addChild(commonLayer, 1)

	-- 大spine节点
	local mainSpineNode = nil
	if BattleConfigUtils:UseElexLocalize() then
		mainSpineNode = sp.SkeletonAnimation:create(
			_res('battle/effect/battle_result.json'),
			_res('battle/effect/battle_result.atlas'),
			1
		)
	else
		mainSpineNode = sp.SkeletonAnimation:create(
			'battle/effect/battle_result.json',
			'battle/effect/battle_result.atlas',
			1
		)
	end
	mainSpineNode:update(0)
	mainSpineNode:setPosition(cc.p(layerSize.width * 0.5, layerSize.height * 0.5))
	commonLayer:addChild(mainSpineNode, 1)

	-- 立绘
	local leaderData = self.teamData[1]
	local drawNode = require('common.CardSkinDrawNode').new({
		skinId = checkint(leaderData.skinId),
		coordinateType = COORDINATE_TYPE_CAPSULE
	})
	self:addChild(drawNode, 2)
	if cardMgr.GetFavorabilityMax(leaderData.favorLevel) then
		local designSize = cc.size(1334, 750)
        local winSize = display.size
		local deltaHeight = (winSize.height - designSize.height) * 0.5
		
		local particleSpine = sp.SkeletonAnimation:create(
              'effects/marry/fly.json',
              'effects/marry/fly.atlas',
              1)
        -- particleSpine:setTimeScale(2.0 / 3.0)
        particleSpine:setPosition(cc.p(display.SAFE_L + 300,deltaHeight))
        self:addChild(particleSpine, 2)
        particleSpine:setAnimation(0, 'idle2', true)
        particleSpine:update(0)
        particleSpine:setToSetupPose()
		particleSpine:setVisible(false)
		
		self.particleSpine = particleSpine
	end

	------------ 失败小人 ------------
	local strongInfo = {
		{iconPath = 'ui/battle/label_btn_upper.png', descr = __('飨灵升级')},
		{iconPath = 'ui/battle/label_btn_break.png', descr = __('飨灵升星')},
		{iconPath = 'ui/battle/label_btn_stronger.png', descr = __('技能升级')}
	}

	local hintBg = display.newImageView(_res('ui/battle/battleresult/result_bg_black.png'), 0, 0)
	local hintBgX = math.min(layerSize.width * 0.5 + 375, layerSize.width - hintBg:getContentSize().width * 0.5 - 10)
	display.commonUIParams(hintBg, {po = cc.p(
		hintBgX,
		layerSize.height * 0.5 - 175
	)})
	commonLayer:addChild(hintBg)
	hintBg:setCascadeOpacityEnabled(true)

	local hintBgSize = hintBg:getContentSize()

	local hintLabel = display.newLabel(hintBgSize.width * 0.5, hintBgSize.height - 5, fontWithColor('9', {ap = cc.p(0.5, 1), text = __('通过以下方式提升自己')}))
	hintBg:addChild(hintLabel)

	local nodes = {}
	for i,v in ipairs(strongInfo) do
		local avatar = display.newImageView(_res(v.iconPath), 0, 0)
		hintBg:addChild(avatar)

		local avatarLabel = display.newLabel(0, 0, fontWithColor('19', {text = v.descr}))
		display.commonUIParams(avatarLabel, {ap = cc.p(0.5, 1), po = cc.p(
			utils.getLocalCenter(avatar).x,
			5
		)})
		avatar:addChild(avatarLabel)

		table.insert(nodes, avatar)
	end
	display.setNodesToNodeOnCenter(hintBg, nodes, {spaceW = 30, y = utils.getLocalCenter(hintBg).y + 15})
	------------ 失败小人 ------------

	-- 添加底部信息
	local commonBottomLayer = self:AddCommonBottomLayer(commonLayer)

	------------ 初始化动画状态 ------------
	bgMask:setOpacity(0)
	mainSpineNode:setVisible(false)
	drawNode:setVisible(false)
	drawNode:setOpacity(0)
	drawNode:setPositionY(drawNode:getPositionY() - animationConf.drawMoveY)
	if self.particleSpine then
		self.particleSpine:setOpacity(0)
	end

	hintBg:setVisible(false)
	hintBg:setOpacity(0)
	------------ 初始化动画状态 ------------

	local ShowSelf = function ()
		local costFrame = 0

		------------ 显示遮罩渐变动画 ------------
		local bgMaskActionSeq = cc.Sequence:create(
			cc.FadeTo:create(animationConf.bgMaskFadeInTime / self.fps, 255))
		bgMask:runAction(bgMaskActionSeq)
		------------ 显示遮罩渐变动画 ------------

		------------ 显示主spine动画 ------------
		local mainSpineNodeActionSeq = cc.Sequence:create(
			cc.DelayTime:create(animationConf.bgMaskFadeInTime / self.fps),
			cc.Show:create(),
			cc.CallFunc:create(function ()
				mainSpineNode:setAnimation(0, 'play_fail', false)
				mainSpineNode:addAnimation(0, 'idle2', true)
				-- 播放失败音效
				PlayAudioClip(AUDIOS.UI.ui_war_lose.id)
			end)
		)
		mainSpineNode:runAction(mainSpineNodeActionSeq)
		------------ 显示主spine动画 ------------

		------------ 显示立绘 ------------
		local drawNodeActionSeq = cc.Sequence:create(
			cc.DelayTime:create((animationConf.bgMaskFadeInTime + animationConf.drawAppearDelayTime) / self.fps),
			cc.Show:create(),
			cc.EaseOut:create(cc.Spawn:create(
				cc.FadeTo:create(animationConf.drawAppearTime / self.fps, 255),
				cc.MoveBy:create(animationConf.drawAppearTime / self.fps, cc.p(0, animationConf.drawMoveY))), 2),
			cc.CallFunc:create(function ()
				if self.particleSpine then
					self.particleSpine:runAction(cc.Sequence:create(
						cc.Show:create(),
						cc.FadeIn:create(0.5)))
				end
			end)
			)
		drawNode:runAction(drawNodeActionSeq)
		------------ 显示立绘 ------------

		------------ 失败小人 ------------
		local failHintActionSeq = cc.Sequence:create(
			cc.DelayTime:create((animationConf.bgMaskFadeInTime + animationConf.hintAppearDelayTime) / self.fps),
			cc.Show:create(),
			cc.FadeTo:create(animationConf.hintAppearTime / self.fps, 255))
		hintBg:runAction(failHintActionSeq)
		------------ 失败小人 ------------

		costFrame = animationConf.bgMaskFadeInTime + animationConf.hintAppearDelayTime + animationConf.hintAppearTime

		------------ 底部的动画 ------------
		if commonBottomLayer and commonBottomLayer.ShowSelf then
			commonBottomLayer.ShowSelf(costFrame)
		end
		------------ 底部的动画 ------------
	end

	local HideSelf = function ()
		-- commonLayer:setVisible(false)
		-- 屏蔽触摸
		self.canTouch = false

		-- 隐藏common层
		local commonLayerActionSeq = cc.Sequence:create(
			cc.EaseIn:create(
				cc.Spawn:create(
					cc.MoveBy:create(animationConf.hideMoveTime / self.fps, cc.p(0, animationConf.hideMoveY)),
					cc.FadeTo:create(animationConf.hideMoveTime / self.fps, 0)),
				2
			),
			cc.Hide:create())
		commonLayer:runAction(commonLayerActionSeq)

		------------ 底部的动画 ------------
		if commonBottomLayer and commonBottomLayer.ShowSelf then
			commonBottomLayer.HideSelf()
		end
		------------ 底部的动画 ------------
	end

	local layer = {ShowSelf = ShowSelf, HideSelf = HideSelf}
	return layer
end
---------------------------------------------------
-- init end --
---------------------------------------------------

return BattleFailView
