--[[
cutin 场景
@params args table {
	mainSkinId int 主立绘皮肤id
	otherHeadSkinId list 其他头像id的皮肤id
	callback function 游戏结束后的回调
}
--]]
local BaseMiniGameScene = __Require('battle.miniGame.BaseMiniGameScene')
local CutinScene = class('CutinScene', BaseMiniGameScene)
--[[
@override
--]]
function CutinScene:initView()
	BaseMiniGameScene.initView(self)
	self.eaterLayer:setOpacity(255 * 0)

	---------- 初始化总的裁剪节点 ----------

	local sceneClipNode = cc.ClippingNode:create()
	sceneClipNode:setPosition(cc.p(0, 0))
	self:addChild(sceneClipNode)

	local stencilLayer = display.newLayer(utils.getLocalCenter(self).x, utils.getLocalCenter(self).y,
		{size = display.size, ap = cc.p(0.5, 0.5), color = '#000000'})
	sceneClipNode:setAlphaThreshold(1)
	sceneClipNode:setInverted(false)
	sceneClipNode:setStencil(stencilLayer)
	self.stencilLayer = stencilLayer

	---------- 初始化spine过场动画 ----------

	local spineFg = SpineCache(SpineCacheName.BATTLE):createWithName(sp.AniCacheName.CARD_CI_FG)
	spineFg:setPosition(utils.getLocalCenter(self))
	sceneClipNode:addChild(spineFg, 10)
	self.spineFg = spineFg
	table.insert(self.spineNodes, spineFg)
	-- spineFg:setColor(cc.c3b(0, 255, 0))
	-- self:addChild(spineFg, 5)

	-- 绑定spine自定义回调
	self.spineFg:registerSpineEventHandler(handler(self, self.spineEventCustomHandler), sp.EventType.ANIMATION_EVENT)

	---------- 初始化spine动画垫字那一层 ----------

	local labelBottom = display.newLayer(display.width * 0.5, display.height * 0.5 - 220, {size = cc.size(display.width, 565), color = '#000000', ap = cc.p(0.5, 0.5)})
	sceneClipNode:addChild(labelBottom, 4)
	labelBottom:setOpacity(0)
	self.labelBottom = labelBottom

	---------- 初始化立绘 ----------

	local ttt = require('common.CardSkinDrawNode').new({skinId = self.args.mainSkinId, coordinateType = COORDINATE_TYPE_CAPSULE})
	-- self:addChild(ttt, 3)
	sceneClipNode:addChild(ttt, 6)
	self.mainDrawNode = ttt:GetAvatar()
	-- self.mainDrawNode:setVisible(false)

	---------- 初始化连携角色头像 ----------

	local connectHeadNodes = {}
	if self.args.otherHeadSkinId then
		for i, headSkinId_ in ipairs(self.args.otherHeadSkinId) do
			local headPath = CardUtils.GetCardHeadPathBySkinId(headSkinId_)

			local bgSpine = SpineCache(SpineCacheName.BATTLE):createWithName(sp.AniCacheName.CARD_CI_CONNECT_HEAD_BG)
			bgSpine:setPosition(display.center)
			sceneClipNode:addChild(bgSpine, 5)
			table.insert(self.spineNodes, bgSpine)
			-- bgSpine:setAnimation(0, 'animation', true)

			local headClipNode = cc.ClippingNode:create()
			headClipNode:setPosition(cc.p(0, 12))
			bgSpine:addChild(headClipNode)

			local headScale = 1.1
			local head = display.newNSprite(_res(headPath), 0, 0)
			headClipNode:addChild(head)
			head:setScale(headScale)
			local stencilNode = cc.DrawNode:create()
			stencilNode:drawSolidCircle(cc.p(0, 0), head:getContentSize().width * 0.5 * headScale - 5, 0, 50, 1, 1, cc.c4f(0,0,0,1))
			stencilNode:setPosition(cc.p(0, 0))
			headClipNode:setStencil(stencilNode)
			headClipNode:setAlphaThreshold(1)
			headClipNode:setInverted(false)

			local fgSpine = SpineCache(SpineCacheName.BATTLE):createWithName(sp.AniCacheName.CARD_CI_CONNECT_HEAD_FG)
			-- fgSpine:setAnimation(0, 'animation', true)
			bgSpine:addChild(fgSpine)
			fgSpine:setTag(3)
			table.insert(connectHeadNodes, bgSpine)
			table.insert(self.spineNodes, fgSpine)
		end
		self.connectHeadNodes = connectHeadNodes
	end

	---------- 初始化ci动画配置 ----------

	self.ciAnimationConf = {
		delay = 6.5,
		-- moveTime = 1.5 + 45 + 20 + 12,
		moveTime = 0 + 45 + 20 + 12,
		moveX = 275 + 1002,
		framePerSecond = 30,
		disappearTime = 12 / 30,
		costedTime = 0,
		headMoveX = display.width * 0.85,
		disappearAccelerate = 0,
		frameBegan = self.args.startFrame,
		frameEnded = self.args.startFrame + self.args.durationFrame,
		frameIndex = self.args.startFrame,
		frameEnter = self.args.startFrame,
	}

	self.ciAnimationConf.disappearAccelerate = display.height /
		(self.ciAnimationConf.disappearTime *
			self.ciAnimationConf.disappearTime *
			self.ciAnimationConf.disappearTime *
			self.ciAnimationConf.disappearTime)

	self.canDisappear = false

	if self.args.isEnemy then
		self.ciAnimationConf.moveX = -display.width - self.ciAnimationConf.moveX
		self.ciAnimationConf.headMoveX = -self.ciAnimationConf.headMoveX
		self.mainDrawNode:setPositionX(self.mainDrawNode:getPositionX() + display.cx)
		self.mainDrawNode:setPositionX(self.mainDrawNode:getPositionX() - self.ciAnimationConf.moveX)

		for index, spine in ipairs(self.spineNodes) do
			spine:setScaleX(-spine:getScaleX())
		end
	else
		self.mainDrawNode:setPositionX(self.mainDrawNode:getPositionX() - self.ciAnimationConf.moveX)
	end

	for i, headNode in ipairs(self.connectHeadNodes) do
		local posX = 0
		if self.args.isEnemy then
			posX = display.width * 0.28 + self.ciAnimationConf.headMoveX + 100 * (i - 1)
		else
			posX = display.width * 0.66 + self.ciAnimationConf.headMoveX + 100 * (i - 1)
		end
		local posY = display.height * (1 - 0.3 * i)
		headNode:setPosition(cc.p(posX, posY))
		headNode:setVisible(false)
	end

end
--[[
@override
开始游戏
--]]
function CutinScene:start()
	if self.args.startCB then
		xTry(function()
			self.args.startCB()
		end, __G__TRACKBACK__)
	end
	-- 播放ci音效
	if G_BattleRenderMgr then
		G_BattleRenderMgr:PlayBattleSoundEffect(AUDIOS.BATTLE.ty_battle_baoqi.id)
	end
	self.spineFg:setAnimation(0, 'animation', false)
	self:startMainDrawNodeAnimation()
end
--[[
@override
游戏结束
--]]
function CutinScene:over()
	if self.isOver_ == true then return end
	self.isOver_ = true
	self:setVisible(false)

	self.spineFg:clearTracks()
	self.spineFg:unregisterSpineEventHandler(sp.EventType.ANIMATION_EVENT)

	if self.args.overCB then
		xTry(function()
			self.args.overCB(self.result)
		end, __G__TRACKBACK__)
	end
	
	self:die()
end
--[[
@override
update
--]]
function CutinScene:update(dt)
	if self.isPause then return end
	if self.isOver_ then return end

	if G_BattleLogicMgr then
		self.ciAnimationConf.frameIndex = G_BattleLogicMgr:GetBData():GetLogicFrameIndex()
	else
		self.ciAnimationConf.frameIndex = self.ciAnimationConf.frameIndex + 1
	end

	if self.canDisappear then
		local currentIndex = math.max(self.ciAnimationConf.frameIndex - self.ciAnimationConf.frameEnter, 0)
		local targetIndex  = math.max(self.ciAnimationConf.frameEnded - self.ciAnimationConf.frameEnter, currentIndex)
		self.ciAnimationConf.costedTime = targetIndex > 0 and (currentIndex / targetIndex) or 1

		self.stencilLayer:setContentSize(cc.size(display.width, math.max(display.height - display.height * (
			self.ciAnimationConf.costedTime *
			self.ciAnimationConf.costedTime *
			self.ciAnimationConf.costedTime *
			self.ciAnimationConf.costedTime
		), 0)))

		if self.stencilLayer:getContentSize().height <= 0 then
			self.canDisappear = false
			self:over()
			return
		end
		--[[
		self.ciAnimationConf.costedTime = self.ciAnimationConf.costedTime + dt

		-- 四次加速闭合
		self.stencilLayer:setContentSize(cc.size(
			display.width,
			math.max(display.height -
				self.ciAnimationConf.disappearAccelerate *
				self.ciAnimationConf.costedTime *
				self.ciAnimationConf.costedTime *
				self.ciAnimationConf.costedTime *
				self.ciAnimationConf.costedTime, 0)))
		]]

		-- 插值闭合
		-- self.stencilLayer:setContentSize(cc.size(display.width, utils.lerp(display.height, 0, self.ciAnimationConf.costedTime / self.ciAnimationConf.disappearTime)))
	end

	if self.ciAnimationConf.frameIndex >= self.ciAnimationConf.frameEnded then
		self.canDisappear = false
		self:over()
	end
end
---------------------------------------------------
-- ci animation controller begin --
---------------------------------------------------
function CutinScene:startMainDrawNodeAnimation()
	-- 垫字层动画
	local labelBottomActionSeq = cc.Sequence:create(
		cc.DelayTime:create(2 / self.ciAnimationConf.framePerSecond),
		cc.FadeTo:create(23 / self.ciAnimationConf.framePerSecond, 128))
	self.labelBottom:runAction(labelBottomActionSeq)
	table.insert(self.actionNodes, self.labelBottom)

	-- 遮罩动画
	local eaterLayerActionSeq = cc.Sequence:create(
		cc.EaseIn:create(cc.FadeTo:create(self.ciAnimationConf.delay / self.ciAnimationConf.framePerSecond, 178), 5))
	self.eaterLayer:runAction(eaterLayerActionSeq)
	table.insert(self.actionNodes, self.eaterLayer)

	-- 立绘动画
	local mainDrawNodeActionSeq = cc.Sequence:create(
		cc.DelayTime:create(self.ciAnimationConf.delay / self.ciAnimationConf.framePerSecond),
		cc.EaseOut:create(cc.MoveBy:create(self.ciAnimationConf.moveTime / self.ciAnimationConf.framePerSecond, cc.p(self.ciAnimationConf.moveX, 0)), 20)
	)
	self.mainDrawNode:runAction(mainDrawNodeActionSeq)
	table.insert(self.actionNodes, self.mainDrawNode)

	-- 连携头像动画
	local delayTime = self.ciAnimationConf.delay / self.ciAnimationConf.framePerSecond
	for i,v in ipairs(self.connectHeadNodes) do
		local actionSeq = cc.Sequence:create(
			cc.Show:create(),
			cc.DelayTime:create(delayTime),
			cc.EaseOut:create(cc.MoveBy:create(self.ciAnimationConf.moveTime / self.ciAnimationConf.framePerSecond, cc.p(-self.ciAnimationConf.headMoveX, 0)), 15)
		)
		delayTime = delayTime + (math.random(1) + 1) * 0.05
		v:runAction(actionSeq)
		table.insert(self.actionNodes, v)

		v:setAnimation(0, 'animation', true)
		v:getChildByTag(3):setAnimation(0, 'animation', true)
	end
end
function CutinScene:startDisappear()
	self.ciAnimationConf.frameEnter = self.ciAnimationConf.frameIndex
	self.canDisappear = true
end
---------------------------------------------------
-- ci animation end --
---------------------------------------------------

--[[
spine自定义回调
--]]
function CutinScene:spineEventCustomHandler(event)
	if not event then return end
	if not event.eventData then return end
	if 'disappear' == event.eventData.name then
		self:startDisappear()
	end
end

---------------------------------------------------
-- handler logic begin --
---------------------------------------------------
--[[
cocos2dx event handler
--]]
function CutinScene:onEnter()
	-- ci场景不再自启动 由逻辑层调渲染层启动
end
function CutinScene:onExit()
	
end
function CutinScene:onCleanup()
	-- print('remove self -> ' .. ID(self))
end
---------------------------------------------------
-- handler logic end --
---------------------------------------------------

return CutinScene
