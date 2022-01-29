--[[
连线游戏
--]]
local BaseMiniGameScene = __Require('battle.miniGame.BaseMiniGameScene')
local LineConnectGame = class('LineConnectGame', BaseMiniGameScene)
local scheduler = require('cocos.framework.scheduler')

--[[
@override
初始化界面
--]]
function LineConnectGame:initView()

	BaseMiniGameScene.initView(self)

	self.gameStart = false
	self.touchPointPrev = nil
	self.activeTouchItems = {}

	local bgSize = self:getContentSize()

	---------- 初始化总的裁剪节点 ----------

	local sceneClipNode = cc.ClippingNode:create()
	sceneClipNode:setPosition(cc.p(0, 0))
	self:addChild(sceneClipNode)
	self.sceneClipNode = sceneClipNode

	local stencilLayer = display.newLayer(utils.getLocalCenter(self).x, utils.getLocalCenter(self).y,
		{size = display.size, ap = cc.p(0.5, 0.5), color = '#000000'})
	sceneClipNode:setAlphaThreshold(1)
	sceneClipNode:setInverted(false)
	sceneClipNode:setStencil(stencilLayer)
	self.stencilLayer = stencilLayer

	---------- 倒计时 ----------
	
	local timeBar = CProgressBar:create(_res('battle/ui/battle_game_ico_time_loading.png'))
    timeBar:setBackgroundImage(_res('battle/ui/battle_game_bg_time.png'))
    timeBar:setDirection(eProgressBarDirectionLeftToRight)
    timeBar:setAnchorPoint(cc.p(0.5, 0.5))
    timeBar:setPosition(cc.p(bgSize.width * 0.5, display.height - 35))
    self:addChild(timeBar, 10)
    self.timeBar = timeBar
    timeBar:setVisible(false)

    timeBar:setMaxValue(self.time * 1000)
	timeBar:setValue(self.time * 1000)

	local timeLabel = display.newLabel(-10, utils.getLocalCenter(timeBar).y,
		{text = __('剩余时间'), fontSize = fontWithColor('SPX').fontSize, color = fontWithColor('BC').color, ap = cc.p(1, 0.5)})
	timeBar:addChild(timeLabel)

	local leftTimeLabel = display.newRichLabel(timeBar:getContentSize().width + 10, utils.getLocalCenter(timeBar).y,
		{ap = cc.p(0, 0.5), c = {
			{text = tostring(math.floor(self.time)), fontSize = fontWithColor('M2PX').fontSize, color = fontWithColor('BC').color},
			{text = '.', fontSize = fontWithColor('SPX').fontSize, color = fontWithColor('BC').color},
			{text = tostring(math.floor((self.time - math.floor(self.time)) * 10)), fontSize = fontWithColor('SPX').fontSize, color = fontWithColor('BC').color},
			{text = 's', fontSize = fontWithColor('SPX').fontSize, color = fontWithColor('BC').color},
		}
	})
	leftTimeLabel:reloadData()
	timeBar:addChild(leftTimeLabel)
	self.leftTimeLabel = leftTimeLabel

	---------- 提示框 ----------

	local scale = 0.6
	local hintFrame = display.newNSprite(_res('ui/story/dialogue_bg_happy.png'), 0, 0)
	hintFrame:setScale(scale)
	local hintLabel = display.newLabel(utils.getLocalCenter(hintFrame).x, utils.getLocalCenter(hintFrame).y,
		{text = __('连接所有头像'), fontSize = 40, color = '#6c6c6c'})
	hintFrame:addChild(hintLabel)
	self:addChild(hintFrame, 10)
	display.commonUIParams(hintFrame, {po = cc.p(display.width + 25 - hintFrame:getContentSize().width * 0.5 * scale, display.height + 25 - hintFrame:getContentSize().height * 0.5 * scale)})
	self.hintFrame = hintFrame
	hintFrame:setVisible(false)

	---------- 初始化立绘 ----------
	local ttt = require('common.CardSkinDrawNode').new({cardId = self.args.drawInfo.drawId})
	self.sceneClipNode:addChild(ttt, 6)
	self.mainDrawNode = ttt:GetAvatar()


	---------- 初始化头像touch item ----------

	-- 主触发角色
	local id = 1
	local mainCharacterTouchNode = self:createATouchItem(self.args.mainDrawName)
	self:addChild(mainCharacterTouchNode, 5)
	local mainTouchItem = {id = id, node = mainCharacterTouchNode, active = false, size = mainCharacterTouchNode:getContentSize()}
	self:addTouchItem(mainTouchItem)
	self.mainCharacterTouchNode = mainCharacterTouchNode

	-- 其他角色
	for i,v in ipairs(self.args.otherDrawName) do
		local touchNode = self:createATouchItem(v)
		self:addChild(touchNode, 5)
		touchNode:setPosition(cc.p(400, 400))
		local touchItem = {id = id + i, node = touchNode, active = false, size = touchNode:getContentSize()}
		self:addTouchItem(touchItem)
	end

	self:initTouchItem()

	---------- 初始化drawNode ----------

	local drawNode = cc.DrawNode:create()
	self:addChild(drawNode, 9)
	drawNode:setPosition(cc.p(0, 0))
	self.drawNode = drawNode

	---------- 初始化动画状态 ----------

	self.animationConf = {
		fadeInTime = 0.4,
		rightTime = 0.5,
		rightX = 1002,
		leftTime = 0.3,
		leftX = -75,
	}

	self.mainDrawNode:setPositionX(self.mainDrawNode:getPositionX() - 275 - 1002)
	self.eaterLayer:setOpacity(0)
	for i = 1, table.nums(self.touchItems) do
		self.touchItems[tostring(i)].node:setScale(0)
		self.touchItems[tostring(i)].node:setOpacity(0)
	end

end
--[[
创建按钮
--]]
function LineConnectGame:createATouchItem(drawName)
	local node = display.newNSprite(_res('ui/battle/battle_game1_bg_role.png'), 0, 0)

	local staticCover = display.newNSprite(_res('battle/ui/battle_game1_ico_normal'), utils.getLocalCenter(node).x, utils.getLocalCenter(node).y)
	staticCover:setTag(3)
	node:addChild(staticCover, 5)

	local dynamicCover = SpineCache(SpineCacheName.BATTLE):createWithName('head_active')
	dynamicCover:setTag(5)
	dynamicCover:update(0)
	dynamicCover:setPosition(utils.getLocalCenter(node))
	node:addChild(dynamicCover, 5)
	dynamicCover:setVisible(false)

	local headPath = AssetsUtils.GetCardHeadPath(drawName)
	if utils.isExistent(headPath) then
		-- 裁头像
		local headClipNode = cc.ClippingNode:create()
		headClipNode:setPosition(utils.getLocalCenter(node))
		node:addChild(headClipNode, 3)

		local stencilNode = display.newNSprite(_res('ui/battle/battle_game1_bg_role.png'), 0, 0)
		stencilNode:setScale(0.95)
		headClipNode:setAlphaThreshold(0.1)
		headClipNode:setStencil(stencilNode)

		local headNode = display.newImageView(headPath, 0, 0)
		headNode:setScale(0.6)
		headClipNode:addChild(headNode)
	end

	return node
end
--[[
初始化头像位置 移动方向
--]]
function LineConnectGame:initTouchItem()
	-- 初始化位置
	local moveArea = {
		left = display.width * 0.4 + self.mainCharacterTouchNode:getContentSize().width * 0.5,
		right = display.width - 150 - self.mainCharacterTouchNode:getContentSize().width * 0.5,
		bottom = 80 + self.mainCharacterTouchNode:getContentSize().height * 0.5,
		top = display.height - 200 - self.mainCharacterTouchNode:getContentSize().height * 0.5,
		width = 0,
		height = 0,
		rect = nil
	}
	moveArea.width = moveArea.right - moveArea.left
	moveArea.height = moveArea.top - moveArea.bottom
	moveArea.rect = cc.rect(moveArea.left, moveArea.bottom, moveArea.width, moveArea.height)

	self.moveArea = moveArea

	local x = {1, 2, 3, 0}
	local y = {1, 2, 3, 0}

	local randomX = 0
	local randomY = 0
	
	for k,v in pairs(self.touchItems) do
		-- 初始化位置
		randomX = math.random(1, table.nums(x))
		randomY = math.random(1, table.nums(y))
		v.node:setPosition(cc.p(
			moveArea.width * 0.33 * x[randomX] + moveArea.left,
			moveArea.height * 0.33 * y[randomY] + moveArea.bottom))

		-- 初始化方向
		v.towards = cc.p(
			math.random(BMediator:GetBConf().cellSize.width * 5, BMediator:GetBConf().cellSize.width * 10) * 0.01 * ((-1) ^ x[randomX]),
			math.random(BMediator:GetBConf().cellSize.width * 5, BMediator:GetBConf().cellSize.width * 10) * 0.01 * ((-1) ^ y[randomY]))

		table.remove(x, randomX)
		table.remove(y, randomY)
	end
end
--[[
@override
开始动画但不是开始游戏
--]]
function LineConnectGame:start()
	BaseMiniGameScene.start(self)
	self:startEnterGameAnimation()
end
---------------------------------------------------
-- animation begin --
---------------------------------------------------
--[[
开场动画
--]]
function LineConnectGame:startEnterGameAnimation()

	-- 遮罩动画
	local eaterLayerActionSeq = cc.Sequence:create(
		cc.EaseIn:create(cc.FadeTo:create(self.animationConf.fadeInTime, 178), 5),
		cc.CallFunc:create(function ()
			-- 显示倒计时
			self.timeBar:setVisible(true)
		end))
	self.eaterLayer:runAction(eaterLayerActionSeq)

	-- 立绘动画
	local mainDrawNodeActionSeq = cc.Sequence:create(
		cc.DelayTime:create(self.animationConf.fadeInTime * 0.5),
		cc.EaseOut:create(cc.MoveBy:create(self.animationConf.rightTime, cc.p(self.animationConf.rightX, 0)), 50),
		cc.MoveBy:create(self.animationConf.leftTime, cc.p(self.animationConf.leftX, 0)),
		cc.CallFunc:create(function ()
			-- touch item 出现动画
			self:showTouchItems()
		end))
	self.mainDrawNode:runAction(mainDrawNodeActionSeq)

	-- 提示框动画
	local hintScale = self.hintFrame:getScale()
	local deltaP = cc.p(-40, -80)
	local rotate = -20
	self.hintFrame:setPosition(cc.p(self.hintFrame:getPositionX() - deltaP.x, self.hintFrame:getPositionY() - deltaP.y))
	self.hintFrame:setRotation(-rotate)
	local hintFrameActionSeq = cc.Sequence:create(
		cc.DelayTime:create(self.animationConf.fadeInTime),
		cc.Show:create(),
		cc.Spawn:create(
			cc.MoveBy:create(0.4, deltaP),
			cc.RotateBy:create(0.4, rotate)),
		cc.CallFunc:create(function ()
			local seq = cc.RepeatForever:create(cc.Sequence:create(
			cc.ScaleTo:create(0.2, 0.95 * hintScale),
			cc.ScaleTo:create(0.2, 1 * hintScale)))
			self.hintFrame:runAction(seq)
		end))
	self.hintFrame:runAction(hintFrameActionSeq)
end
--[[
显示touch item
--]]
function LineConnectGame:showTouchItems()
	local delayTime = 0.15
	for i = 1, table.nums(self.touchItems) do
		local actions = {
			cc.DelayTime:create(delayTime * (i - 1)),
			cc.Spawn:create(
				cc.ScaleTo:create(0.15, 1.2),
				cc.FadeTo:create(0.15, 255)
			),
			cc.ScaleTo:create(0.1, 0.9),
			cc.ScaleTo:create(0.1, 1)
		}
		if table.nums(self.touchItems) == i then
			table.insert(actions, cc.CallFunc:create(function ()
				self:miniGameStart()
			end))
		end
		local tiActionSeq = cc.Sequence:create(actions)
		self.touchItems[tostring(i)].node:runAction(tiActionSeq)
	end
end
--[[
显示ci
--]]
function LineConnectGame:showCutin()

	---------- 初始化spine过场动画 ----------

	local spineBg = SpineCache(SpineCacheName.BATTLE):createWithName('cutin_1')
	spineBg:setPosition(utils.getLocalCenter(self))
	self.sceneClipNode:addChild(spineBg, 5)
	self.spineBg = spineBg
	-- self.spineBg:setVisible(false)
	-- spineBg:setColor(cc.c3b(0, 255, 0))
	-- self:addChild(spineBg, 1)

	-- 绑定spine自定义回调
	self.spineBg:registerSpineEventHandler(handler(self, self.spineEventCustomHandler), sp.EventType.ANIMATION_EVENT)

	local spineFg = SpineCache(SpineCacheName.BATTLE):createWithName('cutin_2')
	spineFg:setPosition(utils.getLocalCenter(self))
	self.sceneClipNode:addChild(spineFg, 10)
	self.spineFg = spineFg
	-- self.spineFg:setVisible(false)
	-- spineFg:setColor(cc.c3b(0, 255, 0))
	-- self:addChild(spineFg, 5)

	---------- 初始化spine动画垫字那一层 ----------

	local labelBottom = display.newLayer(display.width * 0.5, display.height * 0.5 - 220, {size = cc.size(display.width, 565), color = '#000000', ap = cc.p(0.5, 0.5)})
	self.sceneClipNode:addChild(labelBottom, 4)
	labelBottom:setOpacity(0)
	self.labelBottom = labelBottom

	self.spineBg:setAnimation(0, 'animation', false)
	self.spineFg:setAnimation(0, 'animation', false)

	---------- 初始化连携角色头像 ----------

	local connectHeadNodes = {}
	for i,v in ipairs(self.args.otherDrawName) do
		local bgSpine = SpineCache(SpineCacheName.BATTLE):createWithName('connect_head_1')
		bgSpine:setPosition(display.center)
		self.sceneClipNode:addChild(bgSpine, 5)
		bgSpine:setAnimation(0, 'animation', true)

		local headClipNode = cc.ClippingNode:create()
		headClipNode:setPosition(cc.p(0, 12))
		bgSpine:addChild(headClipNode)

		local headScale = 1.1
		local head = display.newImageView(AssetsUtils.GetCardHeadPath(v), 0, 0)
		headClipNode:addChild(head)
		head:setScale(headScale)
		local stencilNode = cc.DrawNode:create()
		stencilNode:drawSolidCircle(cc.p(0, 0), head:getContentSize().width * 0.5 * headScale - 5, 0, 50, 1, 1, cc.c4f(0,0,0,1))
		stencilNode:setPosition(cc.p(0, 0))
		headClipNode:setStencil(stencilNode)
		headClipNode:setAlphaThreshold(1)
		headClipNode:setInverted(false)

		local fgSpine = SpineCache(SpineCacheName.BATTLE):createWithName('connect_head_2')
		fgSpine:setAnimation(0, 'animation', true)
		bgSpine:addChild(fgSpine)
		table.insert(connectHeadNodes, bgSpine)
	end

	---------- 初始化ci动画配置 ----------

	self.ciAnimationConf = {
		delay = 5,
		framePerSecond = 30,
		moveTime = 45 + 20 + 12,
		moveX = 275 - self.animationConf.leftX,
		costedTime = 0,
		disappearAccelerate = 0,
		disappearTime = 12 / 30,
	}
	self.ciAnimationConf.disappearAccelerate = display.height /
		(self.ciAnimationConf.disappearTime *
			self.ciAnimationConf.disappearTime *
			self.ciAnimationConf.disappearTime *
			self.ciAnimationConf.disappearTime)

	self.canDisappear = false

	-- 垫字层动画
	local labelBottomActionSeq = cc.Sequence:create(
		cc.DelayTime:create(2 / self.ciAnimationConf.framePerSecond),
		cc.FadeTo:create(23 / self.ciAnimationConf.framePerSecond, 128))
	self.labelBottom:runAction(labelBottomActionSeq)

	-- 立绘动画
	local mainDrawNodeActionSeq = cc.Sequence:create(
		cc.DelayTime:create(self.ciAnimationConf.delay / self.ciAnimationConf.framePerSecond),
		cc.EaseOut:create(cc.MoveBy:create(self.ciAnimationConf.moveTime / self.ciAnimationConf.framePerSecond, cc.p(self.ciAnimationConf.moveX, 0)), 5))
	self.mainDrawNode:runAction(mainDrawNodeActionSeq)

	-- 连携头像动画
	local delayTime = self.ciAnimationConf.delay / self.ciAnimationConf.framePerSecond
	for i,v in ipairs(connectHeadNodes) do
		local pos = cc.p(display.width * 1.5 + 100 * (i - 1), display.height * (1 - 0.3 * i))
		v:setPosition(pos)
		local actionSeq = cc.Sequence:create(
			cc.DelayTime:create(delayTime),
			cc.EaseOut:create(cc.MoveBy:create(self.ciAnimationConf.moveTime / self.ciAnimationConf.framePerSecond, cc.p(-display.width * 0.85, 0)), 15)
			)
		delayTime = delayTime + math.random(1, 2) * 0.1
		v:runAction(actionSeq)
	end
end
---------------------------------------------------
-- animation end --
---------------------------------------------------

---------------------------------------------------
-- touch logic begin --
---------------------------------------------------
function LineConnectGame:onTouchBegan_(touch, event)
	if self.gameStart then
		self.touchPointPrev = touch:getLocation()
		self.holdingItem = self:touchCheck(touch)
		-- 第一次触摸屏幕 判断一次是否触摸到
		if nil ~= self.touchItems[self.holdingItem] and not self.touchItems[self.holdingItem].active then
			self:touchedItemHandler(self.holdingItem)
		end
	end
	return true
end
function LineConnectGame:onTouchMoved_(touch, event)
	if self.gameStart then
		-- 移动时 判断是否触摸到 这里做一些分隔
		self.holdingItem = self:touchCheck(touch)
		if nil ~= self.touchItems[self.holdingItem] and not self.touchItems[self.holdingItem].active then
			self:touchedItemHandler(self.holdingItem)
		end
		-- 绘图
		if self.touchPointPrev then
			self.drawNode:drawLine(self.touchPointPrev, touch:getLocation(), cc.c4b(1, 0, 0, 1))
		end
		self.touchPointPrev = touch:getLocation()
	end
end
function LineConnectGame:onTouchEnded_(touch, event)
	if self.gameStart then
		-- 结束时清空连接线和激活状态
		self.drawNode:clear()
		self:inactiveAll()
		self.touchPointPrev = nil
	end
end
--[[
熄灭按钮
@params touchItem table 触摸物体
--]]
function LineConnectGame:inactiveTouchItem(touchItem)
	if not touchItem.active then return end
	touchItem.active = false
	touchItem.node:getChildByTag(3):setVisible(true)
	touchItem.node:getChildByTag(5):setVisible(false)
	touchItem.node:getChildByTag(5):clearTracks()
end
--[[
点亮按钮
@params touchItem table 触摸物体
--]]
function LineConnectGame:activeTouchItem(touchItem)
	if touchItem.active then return end
	touchItem.active = true
	touchItem.node:getChildByTag(3):setVisible(false)
	touchItem.node:getChildByTag(5):setVisible(true)
	touchItem.node:getChildByTag(5):setAnimation(0, 'animation', true)
end
--[[
熄灭所有
--]]
function LineConnectGame:inactiveAll()
	-- 触摸结束时直接熄灭所有touchitem
	for k,v in pairs(self.touchItems) do
		self:inactiveTouchItem(v)
	end
	-- 触摸结束时直接熄灭所有touchitem
	for k,v in pairs(self.activeTouchItems) do
		self:inactiveTouchItem(v)
		self.touchItems[k] = v
	end
	self.activeTouchItems = {}
end
--[[
触摸到了item 做出对应的处理
@params id int touch item id
--]]
function LineConnectGame:touchedItemHandler(id)
	self:activeTouchItem(self.touchItems[id])
	self.activeTouchItems[id] = self.touchItems[id]
	self.touchItems[id] = nil
end
---------------------------------------------------
-- touch logic end --
---------------------------------------------------

---------------------------------------------------
-- update logic begin --
---------------------------------------------------
--[[
@override
update
--]]
function LineConnectGame:update(dt)
	if self.isPause then return end

	if self.gameStart then
		self.time = self.time - dt

		-- 刷新倒计时
		self:refreshTimerLabel(self.time)

		if true == self:checkGameSuccess() then
			self:miniGameSuccess()
			return
		end

		if self.time <= 0 then
			self.result = false
			self:miniGameFail()
			return
		end

		self:updateTouchItemsPos()
	elseif self.canDisappear then
		-- ci 闭合动画
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
	end
end
--[[
刷新倒计时
--]]
function LineConnectGame:refreshTimerLabel(time)
	display.reloadRichLabel(self.leftTimeLabel, {c = {
		{text = tostring(math.floor(time)), fontSize = fontWithColor('M2PX').fontSize, color = fontWithColor('BC').color},
		{text = '.', fontSize = fontWithColor('SPX').fontSize, color = fontWithColor('BC').color},
		{text = tostring(math.floor((time - math.floor(time)) * 10)), fontSize = fontWithColor('SPX').fontSize, color = fontWithColor('BC').color},
		{text = 's', fontSize = fontWithColor('SPX').fontSize, color = fontWithColor('BC').color},
	}})
	self.timeBar:setValue(time * 1000)
end
--[[
移动touchitem
--]]
function LineConnectGame:updateTouchItemsPos()
	local p = cc.p(0, 0)
	for k,v in pairs(self.touchItems) do
		p = cc.p(v.node:getPositionX() + v.towards.x, v.node:getPositionY() + v.towards.y)
		if cc.rectContainsPoint(self.moveArea.rect, p) then
			-- 速查
			v.node:setPosition(p)
		else
			if p.x > self.moveArea.right or p.x < self.moveArea.left then
				v.towards.x = v.towards.x * -1
			end
			if p.y > self.moveArea.top or p.y < self.moveArea.bottom then
				v.towards.y = v.towards.y * -1
			end
			p = cc.p(v.node:getPositionX() + v.towards.x, v.node:getPositionY() + v.towards.y)
			v.node:setPosition(p)
		end
	end
end
---------------------------------------------------
-- update logic end --
---------------------------------------------------
--[[
开始连线 开始倒计时
--]]
function LineConnectGame:miniGameStart()
	self.gameStart = true
end
--[[
游戏结束
--]]
function LineConnectGame:miniGameOver()
	self.gameStart = false
end
--[[
连线完成
--]]
function LineConnectGame:miniGameSuccess()
	self:miniGameOver()
	self.result = 1
	self:showRemind('success', function ()
		-- 将可见ui移出屏幕
		local moveActionSeq = cc.Sequence:create(
			cc.MoveBy:create(0.15, cc.p(display.width, 0)),
			cc.Hide:create(),
			cc.RemoveSelf:create())
		self.drawNode:runAction(moveActionSeq:clone())
		self.hintFrame:runAction(moveActionSeq:clone())
		for k,v in pairs(self.activeTouchItems) do
			v.node:runAction(moveActionSeq:clone())
		end

		local moveAndShowCI = cc.Sequence:create(
			cc.MoveBy:create(0.15, cc.p(display.width, 0)),
			cc.CallFunc:create(function ()
				self:showCutin()
			end),
			cc.Hide:create(),
			cc.RemoveSelf:create())
		self.timeBar:runAction(moveAndShowCI)
	end)
end
--[[
连线失败
--]]
function LineConnectGame:miniGameFail()
	self:miniGameOver()
	self.result = false
	self:showRemind('fail', function ()
		self:over()
	end)
end
--[[
检查游戏是否完成
--]]
function LineConnectGame:checkGameSuccess()
	if 0 == table.nums(self.touchItems) then
		return true
	else
		return false
	end
end
--[[
显示提示文字
@params text string 提示文字
@params callback function 回调函数
--]]
function LineConnectGame:showRemind(text, callback)
	local remindLabel = display.newLabel(display.width * 0.5, display.height * 0.5,
		{text = text, fontSize = 36, color = '#ffffff'})
	self:addChild(remindLabel, 11)

	remindLabel:setScale(0)

	local actionSeq = cc.Sequence:create(
		cc.ScaleTo:create(0.4, 1.2),
		cc.ScaleTo:create(0.3, 0.9),
		cc.ScaleTo:create(0.3, 1),
		cc.CallFunc:create(function ()
			if callback then
				callback()
			end
		end),
		cc.RemoveSelf:create())
	remindLabel:runAction(actionSeq)
end
--[[
spine自定义回调
--]]
function LineConnectGame:spineEventCustomHandler(event)
	if not event then return end
	if not event.eventData then return end
	if 'disappear' == event.eventData.name then
		self:startDisappear()
	end
end
function LineConnectGame:startDisappear()
	self.canDisappear = true
end

return LineConnectGame
