--[[
cutin 场景
@params args table {
	mainSkinId int 主立绘皮肤id
	otherHeadPaths table 其他头像id
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

	local spineFg = SpineCache(SpineCacheName.BATTLE):createWithName('cutin_2')
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
	if self.args.otherHeadPaths then
		for i,v in ipairs(self.args.otherHeadPaths) do
			local bgSpine = SpineCache(SpineCacheName.BATTLE):createWithName('connect_head_1')
			bgSpine:setPosition(display.center)
			sceneClipNode:addChild(bgSpine, 5)
			table.insert(self.spineNodes, bgSpine)
			-- bgSpine:setAnimation(0, 'animation', true)

			local headClipNode = cc.ClippingNode:create()
			headClipNode:setPosition(cc.p(0, 12))
			bgSpine:addChild(headClipNode)

			local headScale = 1.1
			local head = display.newNSprite(_res(v), 0, 0)
			headClipNode:addChild(head)
			head:setScale(headScale)
			local stencilNode = cc.DrawNode:create()
			stencilNode:drawSolidCircle(cc.p(0, 0), head:getContentSize().width * 0.5 * headScale - 5, 0, 50, 1, 1, cc.c4f(0,0,0,1))
			stencilNode:setPosition(cc.p(0, 0))
			headClipNode:setStencil(stencilNode)
			headClipNode:setAlphaThreshold(1)
			headClipNode:setInverted(false)

			local fgSpine = SpineCache(SpineCacheName.BATTLE):createWithName('connect_head_2')
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
		disappearAccelerate = 0
	}

	self.ciAnimationConf.disappearAccelerate = display.height /
		(self.ciAnimationConf.disappearTime *
			self.ciAnimationConf.disappearTime *
			self.ciAnimationConf.disappearTime *
			self.ciAnimationConf.disappearTime)

	self.canDisappear = false
	self.mainDrawNode:setPositionX(self.mainDrawNode:getPositionX() - self.ciAnimationConf.moveX)

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
	PlayBattleEffects(AUDIOS.BATTLE.ty_battle_baoqi.id)
	self.spineFg:setAnimation(0, 'animation', false)
	self:startMainDrawNodeAnimation()
end
--[[
@override
游戏结束
--]]
function CutinScene:over()
	self:setVisible(false)

	self.spineFg:clearTracks()
	self.spineFg:unregisterSpineEventHandler(sp.EventType.ANIMATION_EVENT)
	
	-- if self.touchListener_ then
	-- 	self:getEventDispatcher():removeEventListener(self.touchListener_)
	-- 	self.touchListener_ = nil
	-- end
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

	if self.canDisappear then
		if self.stencilLayer:getContentSize().height <= 0 then
			self.canDisappear = false
			self:over()
			return
		end
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

		-- 插值闭合
		-- self.stencilLayer:setContentSize(cc.size(display.width, utils.lerp(display.height, 0, self.ciAnimationConf.costedTime / self.ciAnimationConf.disappearTime)))
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
		local pos = cc.p(display.width * 1.5 + 100 * (i - 1), display.height * (1 - 0.3 * i))
		v:setPosition(pos)
		local actionSeq = cc.Sequence:create(
			cc.DelayTime:create(delayTime),
			cc.EaseOut:create(cc.MoveBy:create(self.ciAnimationConf.moveTime / self.ciAnimationConf.framePerSecond, cc.p(-display.width * 0.85, 0)), 15)
			)
		delayTime = delayTime + BMediator:GetRandomManager():GetRandomIntByRange(1, 2) * 0.05
		v:runAction(actionSeq)
		table.insert(self.actionNodes, v)

		v:setAnimation(0, 'animation', true)
		v:getChildByTag(3):setAnimation(0, 'animation', true)
	end
end
function CutinScene:startDisappear()
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

return CutinScene
