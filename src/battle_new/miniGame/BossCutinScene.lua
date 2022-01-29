--[[
cutin 场景
@params args table {
	mainSkinId int 主立绘皮肤id
	callback function 游戏结束后的回调
}
--]]
local BaseMiniGameScene = __Require('battle.miniGame.BaseMiniGameScene')
local BossCutinScene = class('BossCutinScene', BaseMiniGameScene)
--[[
@override
--]]
function BossCutinScene:init()
	self:initView()
end
--[[
@override
--]]
function BossCutinScene:initView()
	BaseMiniGameScene.initView(self)
	self.eaterLayer:setOpacity(255 * 0)

	---------- 初始化总的裁剪节点 ----------

	local sceneClipNode = cc.ClippingNode:create()
	sceneClipNode:setPosition(cc.p(0, 0))
	self:addChild(sceneClipNode)

	local stencilLayer = SpineCache(SpineCacheName.BATTLE):createWithName(sp.AniCacheName.BOSS_CI_MASK)
	stencilLayer:setPosition(utils.getLocalCenter(self))
	sceneClipNode:setAlphaThreshold(0.1)
	sceneClipNode:setInverted(true)
	sceneClipNode:setStencil(stencilLayer)
	self.stencilLayer = stencilLayer
	table.insert(self.spineNodes, stencilLayer)

	-- 在遮罩spine动画播完后结束ci场景
	self.stencilLayer:registerSpineEventHandler(handler(self, self.maskAnimationEndHandler), sp.EventType.ANIMATION_END)

	---------- 初始化boss ci背景 ----------

	local bg = display.newImageView(_res('arts/monster_bg.jpg'), display.cx, display.cy, {isFull = true})
	sceneClipNode:addChild(bg, 1)
	self.bg = bg

	-- 全面屏适配 放大一次spine遮罩
	stencilLayer:setScale(bg:getScale())

	---------- 初始化spine过场动画 ----------

	local spineBg = SpineCache(SpineCacheName.BATTLE):createWithName(sp.AniCacheName.BOSS_CI_BG)
	spineBg:setPosition(utils.getLocalCenter(self))
	sceneClipNode:addChild(spineBg, 5)
	self.spineBg = spineBg
	table.insert(self.spineNodes, spineBg)
	-- spineBg:setColor(cc.c3b(0, 255, 0))

	local spineFg = SpineCache(SpineCacheName.BATTLE):createWithName(sp.AniCacheName.BOSS_CI_FG)
	spineFg:setPosition(utils.getLocalCenter(self))
	sceneClipNode:addChild(spineFg, 10)
	self.spineFg = spineFg
	table.insert(self.spineNodes, spineFg)
	-- spineFg:setColor(cc.c3b(0, 255, 0))

	---------- 初始化立绘 ----------

	local ttt = require('common.CardSkinDrawNode').new({skinId = self.args.mainSkinId, coordinateType = COORDINATE_TYPE_CAPSULE})
	sceneClipNode:addChild(ttt, 6)
	self.mainDrawNode = ttt:GetAvatar()

	---------- 初始化ci动画配置 ----------

	self.ciAnimationConf = {
		bgFadeInTime = 0.3,
		drawNodeFadeInTime = 0,
		drawNodeMoveTime = SpineCache(SpineCacheName.BATTLE):getAnimationsDataByName(sp.AniCacheName.BOSS_CI_BG).animation.duration,
		drawNodeMoveY = 200,
		drawAppearDelayTime = 1.05,

	}

	self.bg:setOpacity(0)
	-- self.mainDrawNode:setOpacity(0)
	self.mainDrawNode:setVisible(false)
	self.mainDrawNode:setPositionX(self.mainDrawNode:getPositionX() + display.width * 0.1)
	self.mainDrawNode:setPositionY(self.mainDrawNode:getPositionY() - self.ciAnimationConf.drawNodeMoveY)
end
--[[
@override
开始游戏
--]]
function BossCutinScene:start()
	if self.args.startCB then
		xTry(function()
			self.args.startCB()
		end,__G__TRACKBACK__)
	end
	G_BattleRenderMgr:PlayBattleSoundEffect(AUDIOS.BATTLE.ty_battle_baoqi.id)
	self:startMainDrawNodeAnimation()
end
--[[
@override
游戏结束
--]]
function BossCutinScene:over()
	self:setVisible(false)

	self.spineBg:clearTracks()
	self.spineFg:clearTracks()
	self.stencilLayer:clearTracks()
	self.stencilLayer:unregisterSpineEventHandler(sp.EventType.ANIMATION_END)
	
	-- if self.touchListener_ then
	-- 	self:getEventDispatcher():removeEventListener(self.touchListener_)
	-- 	self.touchListener_ = nil
	-- end
	if self.args.overCB then
		xTry(function()
			self.args.overCB(self.result)
		end,__G__TRACKBACK__)
	end
	self:die()
end
--[[
@override
update
--]]
function BossCutinScene:update(dt)
	if self.isPause then return end
end
---------------------------------------------------
-- ci animation controller begin --
---------------------------------------------------
function BossCutinScene:startMainDrawNodeAnimation()
	local disappearDelayTime = SpineCache(SpineCacheName.BATTLE):getAnimationsDataByName(sp.AniCacheName.BOSS_CI_BG).animation.duration -
		SpineCache(SpineCacheName.BATTLE):getAnimationsDataByName(sp.AniCacheName.BOSS_CI_MASK).animation.duration
	-- 背景渐变
	local bgActionSeq = cc.Sequence:create(
		cc.EaseIn:create(cc.FadeTo:create(self.ciAnimationConf.bgFadeInTime, 255), 5),
		cc.CallFunc:create(function ()
			self.spineBg:setAnimation(0, 'animation', false)
			self.spineFg:setAnimation(0, 'animation', false)
		end),
		cc.DelayTime:create(disappearDelayTime),
		cc.CallFunc:create(function ()
			-- 消失动画
			self.stencilLayer:setAnimation(0, 'animation', false)
		end))
	self.bg:runAction(bgActionSeq)
	table.insert(self.actionNodes, self.bg)

	-- 立绘动画
	local mainDrawNodeActionSeq = cc.Sequence:create(
		cc.DelayTime:create(self.ciAnimationConf.drawAppearDelayTime),
		cc.Show:create(),
		cc.EaseOut:create(cc.MoveBy:create(self.ciAnimationConf.drawNodeMoveTime, cc.p(0, self.ciAnimationConf.drawNodeMoveY)), 20)
		-- cc.Spawn:create(
		-- 	cc.FadeTo:create(self.ciAnimationConf.drawNodeFadeInTime, 255),
		-- 	cc.EaseOut:create(cc.MoveBy:create(self.ciAnimationConf.drawNodeMoveTime, cc.p(0, self.ciAnimationConf.drawNodeMoveY)), 20)
		-- )
	)
	self.mainDrawNode:runAction(mainDrawNodeActionSeq)
	table.insert(self.actionNodes, self.mainDrawNode)
end
---------------------------------------------------
-- ci animation end --
---------------------------------------------------
--[[
spine动画结束回调
--]]
function BossCutinScene:maskAnimationEndHandler(event)
	if not event then return end
	self:performWithDelay(
		function ()
			self:over()
		end,
		(1 * cc.Director:getInstance():getAnimationInterval())
	)
end

---------------------------------------------------
-- handler logic begin --
---------------------------------------------------
--[[
cocos2dx event handler
--]]
function BossCutinScene:onEnter()
	-- ci场景不再自启动 由逻辑层调渲染层启动
end
function BossCutinScene:onExit()
	
end
function BossCutinScene:onCleanup()
	-- print('remove self -> ' .. ID(self))
end
---------------------------------------------------
-- handler logic end --
---------------------------------------------------

return BossCutinScene
