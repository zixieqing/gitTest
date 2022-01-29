--[[
boss弱点场景
@params args table {
	o obj 展示弱点的单位
	weakPoints table 展示的弱点bone name {
		id int 序号id 不是配表中的弱点id
		effectId int 配表中的效果id
		effectValue number 弱点效果数值
	}
	time number 施法时间
	skillId int 技能 id
}
--]]
local BaseMiniGameScene = __Require('battle.miniGame.BaseMiniGameScene')
local BossWeakScene = class('BossWeakScene', BaseMiniGameScene)

------------ import ------------
local scheduler = require('cocos.framework.scheduler')
------------ import ------------
--[[
@override
--]]
function BossWeakScene:init()
	self.o = self.args.o
	self.time = self.args.time
	self.weekPointBombTime = 0 -- 弱点会做一个爆炸动画 回传的施法事件实际上要减去这个施法时间
	self.skillId = self.args.skillId
	self.result = nil

	self.gameStart = false

	self:initView()
	self:initTouch()
	self:initWeakLayer()

	self.eaterLayer:setVisible(false)
end
---------------------------------------------------
-- init logic begin --
---------------------------------------------------
--[[
初始化weaklayer
--]]
function BossWeakScene:initWeakLayer()

	local bgSize = display.size

	---------- 倒计时 ----------

	---------- 提示框 ----------

	local scale = 0.6
	local hintFrame = display.newNSprite(_res('arts/stage/ui/dialogue_bg_2.png'), 0, 0)
	hintFrame:setScale(scale)
	local hintLabel = display.newLabel(utils.getLocalCenter(hintFrame).x, utils.getLocalCenter(hintFrame).y,
		{text = __('见证欧皇的时刻。随机点一个弱点，有机会直接打断BOSS的大招哦！'), fontSize = 36, color = '#6c6c6c', w = 400})
	hintFrame:addChild(hintLabel)
	self:addChild(hintFrame, 15)
	display.commonUIParams(hintFrame, {po = cc.p(display.width + 25 - hintFrame:getContentSize().width * 0.5 * scale, 100)})
	self.hintFrame = hintFrame

	---------- boss弱点 ----------

	for i, v in ipairs(self.args.weakPoints) do
		local touchLayer = display.newLayer(0, 0, {size = cc.size(100, 100), ap = cc.p(0.5, 0.5)})
		-- touchLayer:setBackgroundColor(cc.c4b(255, 0, 0, 255))
		local bossWeakSpine = SpineCache(SpineCacheName.BATTLE):createWithName('boss_weak')
		bossWeakSpine:update(0)
		touchLayer:addChild(bossWeakSpine)
		bossWeakSpine:setPosition(utils.getLocalCenter(touchLayer))
		self:addChild(touchLayer, 20)
		table.insert(self.spineNodes, bossWeakSpine)

		local bone = string.format('weak_point_%d', checkint(v.id))
		local effectId = v.effectId or false

		-- 倒计时文字
		-- local timerLabel = CLabelBMFont:create(tostring(math.ceil(self.time)), 'font/small/common_text_num.fnt')
		-- timerLabel:setBMFontSize(48)
		-- timerLabel:setAnchorPoint(cc.p(0.5, 0.5))
		-- timerLabel:setPosition(cc.p(utils.getLocalCenter(touchLayer).x - 2, utils.getLocalCenter(touchLayer).y - 7))
		-- touchLayer:addChild(timerLabel, 5)
		-- timerLabel:setTag(math.ceil(self.time) + 1)
		-- timerLabel:setVisible(false)
		local timerLabel = display.newLabel(0, 0,
			{text = tostring(math.ceil(self.time)), fontSize = 80, color = '#ffffff', ttf = true, font = TTF_GAME_FONT})
		display.commonUIParams(timerLabel, {po = utils.getLocalCenter(touchLayer)})
		timerLabel:setTag(math.ceil(self.time) + 1)
		touchLayer:addChild(timerLabel, 5)
		timerLabel:setVisible(false)

		local disappearTimerLabel = display.newLabel(0, 0,
			{text = tostring(math.ceil(self.time)), fontSize = 80, color = '#ffffff', ttf = true, font = TTF_GAME_FONT})
		display.commonUIParams(disappearTimerLabel, {po = utils.getLocalCenter(touchLayer)})
		disappearTimerLabel:setTag(math.ceil(self.time) + 1)
		touchLayer:addChild(disappearTimerLabel, 6)
		disappearTimerLabel:setVisible(false)

		table.insert(self.actionNodes, timerLabel)
		table.insert(self.actionNodes, disappearTimerLabel)

		local touchItem = {
			id = v.id, -- 弱点序号
			bone = bone,
			effectId = effectId,
			node = touchLayer,
			spineNode = bossWeakSpine,
			timerLabel = timerLabel,
			disappearTimerLabel = disappearTimerLabel
		}
		self:addTouchItem(touchItem)
	end

	---------- 初始化动画状态 ----------

	hintFrame:setVisible(false)

end
--[[
@override
初始化触摸
--]]
function BossWeakScene:initTouch()
    self.touchListener_ = cc.EventListenerTouchOneByOne:create()
    self.touchListener_:setSwallowTouches(false)
    self.touchListener_:registerScriptHandler(handler(self, self.onTouchBegan_), cc.Handler.EVENT_TOUCH_BEGAN)
    self.touchListener_:registerScriptHandler(handler(self, self.onTouchMoved_), cc.Handler.EVENT_TOUCH_MOVED)
    self.touchListener_:registerScriptHandler(handler(self, self.onTouchEnded_), cc.Handler.EVENT_TOUCH_ENDED)
    self.touchListener_:registerScriptHandler(handler(self, self.onTouchCanceled_), cc.Handler.EVENT_TOUCH_CANCELLED)
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(self.touchListener_, self)
end
---------------------------------------------------
-- init logic end --
---------------------------------------------------

---------------------------------------------------
-- touch logic begin --
---------------------------------------------------
--[[
@override
游戏进行时才响应触摸
--]]
function BossWeakScene:onTouchBegan_(touch, event)
	if BMediator:IsBattleTouchEnable() and self:isVisible() and self.gameStart then
		self:touchedItemHandler(self:touchCheck(touch))
		return true
	else
		return false
	end
end
--[[
@override
触摸到了item 做出对应的处理
@params id int touch item id
--]]
function BossWeakScene:touchedItemHandler(id)
	if (not id) then return end
	if self.gameStart then
		self.gameStart = false

		for k,v in pairs(self.touchItems) do
			-- 隐藏其他弱点
			if checkint(k) ~= checkint(id) then
				v.node:setVisible(false)
				v.spineNode:setTimeScale(0)
				v.spineNode:clearTracks()
			end

			-- 停止倒计时动画
			v.timerLabel:stopAllActions()
			v.timerLabel:setVisible(false)

			v.disappearTimerLabel:stopAllActions()
			v.disappearTimerLabel:setVisible(false)
		end

		-- 处理触摸结果
		local touchItem = self.touchItems[tostring(id)]
		self.result = touchItem.id
		self.weekPointBombTime = 0

		-- 随机一个特效
		local bombEffectId = math.ceil(math.random(2000) * 0.001)
		local bombEffectActionName = string.format('bomb%d', bombEffectId)
		touchItem.spineNode:setToSetupPose()
		touchItem.spineNode:setAnimation(0, bombEffectActionName, false)

		self.weekPointBombTime = SpineCache(SpineCacheName.BATTLE):getAnimationsDataByName('boss_weak')[bombEffectActionName].duration

		local actionSeq = cc.Sequence:create(
			cc.DelayTime:create(self.weekPointBombTime),
			cc.FadeTo:create(0.1, 0),
			cc.CallFunc:create(function ()
				self:over()
			end))
		self:runAction(actionSeq)
	end
end
---------------------------------------------------
-- touch logic end --
---------------------------------------------------

---------------------------------------------------
-- miniGame logic begin --
---------------------------------------------------
--[[
@override
开始游戏
--]]
function BossWeakScene:start()
	BaseMiniGameScene.start(self)
	self:updateWeakLocation()
	self:startEnterGameAnimation()
end
--[[
@override
游戏结束
--]]
function BossWeakScene:over()
	self:setVisible(false)

	-- if self.touchListener_ then
	-- 	self:getEventDispatcher():removeEventListener(self.touchListener_)
	-- 	self.touchListener_ = nil
	-- end
	if self.args.overCB then
		xTry(function()
			self.args.overCB({result = self.result, leftTime = math.max(0, self.time - self.weekPointBombTime), skillId = self.skillId})
		end,__G__TRACKBACK__)
	end

	self:die()
end
--[[
update logic
--]]
function BossWeakScene:update(dt)
	self:updateWeakLocation()
	if self.isPause then return end

	if self.gameStart then
		self.time = math.max(self.time - dt, 0)
		-- 刷新倒计时
		self:refreshTimerLabel(self.time)

		if self.time <= 0 then
			self.result = false
			self:over()
		end

	end
	
end
--[[
update location
--]]
function BossWeakScene:updateWeakLocation()
	local weakPoint = nil
	local boneData = nil
	for k,v in pairs(self.touchItems) do
		boneData = self.o:findBoneInWorldSpace(v.bone)
		if nil ~= boneData then
			weakPoint = boneData.worldPosition
			display.commonUIParams(v.node, {po = v.node:getParent():convertToNodeSpace(weakPoint)})
		end
	end
end
--[[
刷新倒计时
--]]
function BossWeakScene:refreshTimerLabel(time)
	local fixedTime = math.ceil(time)
	local timerLabel = nil
	local disappearTimerLabel = nil
	for k,v in pairs(self.touchItems) do
		timerLabel = v.timerLabel
		disappearTimerLabel = v.disappearTimerLabel
		if fixedTime == timerLabel:getTag() then return end

		---------- 消失的倒计时动画 ----------
		local disappearActionSeq = cc.Sequence:create(
			cc.Show:create(),
			cc.Spawn:create(
				cc.ScaleTo:create(0.33, 2.5),
				cc.FadeTo:create(0.33, 0)
			),
			cc.Hide:create()
		)

		disappearTimerLabel:stopAllActions()
		disappearTimerLabel:setScale(1)
		disappearTimerLabel:setOpacity(255)
		disappearTimerLabel:setString(fixedTime)
		disappearTimerLabel:setTag(fixedTime)
		disappearTimerLabel:runAction(disappearActionSeq)
		---------- 消失的倒计时动画 ----------

		---------- 倒计时动画 ----------
		local timerActionSeq = cc.Sequence:create(
			cc.Show:create(),
			cc.ScaleTo:create(1, 0),
			cc.Hide:create())

		timerLabel:stopAllActions()
		timerLabel:setScale(1)
		timerLabel:setString(fixedTime)
		timerLabel:setTag(fixedTime)
		timerLabel:runAction(timerActionSeq)
		---------- 倒计时动画 ----------

	end
end
--[[
开场动画
--]]
function BossWeakScene:startEnterGameAnimation()
	-- 开始游戏逻辑
	self.gameStart = true

	for k,v in pairs(self.touchItems) do
		-- 显示弱点spine动画
		v.spineNode:addAnimation(0, 'idle', true)
	end

	-- 刷新倒计时
	self:refreshTimerLabel(self.time)

	-- -- 提示框动画
	-- local hintScale = self.hintFrame:getScale()
	-- local deltaP = cc.p(-40, -80)
	-- local rotate = -20
	-- self.hintFrame:setPosition(cc.p(self.hintFrame:getPositionX() - deltaP.x, self.hintFrame:getPositionY() - deltaP.y))
	-- self.hintFrame:setRotation(-rotate)
	-- local hintFrameActionSeq = cc.Sequence:create(
	-- 	cc.Show:create(),
	-- 	cc.Spawn:create(
	-- 		cc.MoveBy:create(0.4, deltaP),
	-- 		cc.RotateBy:create(0.4, rotate)),
	-- 	cc.CallFunc:create(function ()
	-- 		local seq = cc.RepeatForever:create(cc.Sequence:create(
	-- 		cc.ScaleTo:create(0.2, 0.95 * hintScale),
	-- 		cc.ScaleTo:create(0.2, 1 * hintScale)))
	-- 		self.hintFrame:runAction(seq)
	-- 	end))
	-- self.hintFrame:runAction(hintFrameActionSeq)
end
---------------------------------------------------
-- miniGame logic end --
---------------------------------------------------

return BossWeakScene
