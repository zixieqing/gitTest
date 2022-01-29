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
local scheduler = require('cocos.framework.scheduler')
--[[
@override
--]]
function BossWeakScene:init()

	self.o = self.args.o
	self.time = self.args.time
	self.weekPointBombTime = 0 -- 弱点会做一个爆炸动画 回传的施法事件实际上要减去这个施法时间
	self.skillId = self.args.skillId

	--------------------------------------
	-- ui

	--------------------------------------
	-- ui

	self.result = nil

	--------------------------------------
	-- ui

	self.gameStart = false

	self:initView()
	self:initTouch()
	self:initWeakLayer()

	-- self.eaterLayer:setVisible(false)
end
--[[
初始化weaklayer
--]]
function BossWeakScene:initWeakLayer()

	local bgSize = display.size

	---------- 倒计时 ----------

	-- timeBar:setMaxValue(self.time * 1000)
	-- timeBar:setValue(self.time * 1000)
 	local timeBar = SpineCache(SpineCacheName.BATTLE):createWithName('boss_chant_progressBar')
 	timeBar:update(0)
 	timeBar:setPosition(cc.p(bgSize.width * 0.5, display.height - 75))
    self:addChild(timeBar, 15)
    timeBar:setVisible(false)
    self.timeBar = timeBar
    table.insert(self.spineNodes, timeBar)

    local spineAnimationTime = 
    	SpineCache(SpineCacheName.BATTLE):getAnimationsDataByName('boss_chant_progressBar')[sp.AnimationName.idle].duration
    timeBar:setTimeScale(spineAnimationTime / self.time)

	local timeLabel = display.newLabel(-10, utils.getLocalCenter(timeBar).y + 40,{text = __('剩余时间'),
		ap = cc.p(1, 0.5),color = 'ffffff',fontSize = fontWithColor('SPX').fontSize
	})
	timeBar:addChild(timeLabel)

	local leftTimeLabel = display.newRichLabel(timeBar:getContentSize().width + 10, utils.getLocalCenter(timeBar).y + 40,
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
	local hintFrame = display.newNSprite(_res('arts/stage/ui/dialogue_bg_2.png'), 0, 0)
	hintFrame:setScale(scale)
	local hintLabel = display.newLabel(utils.getLocalCenter(hintFrame).x, utils.getLocalCenter(hintFrame).y,
		{text = __('见证欧皇的时刻。随机点一个弱点，有机会直接打断BOSS的大招哦！'), fontSize = 40, color = '#6c6c6c', w = 400})
	hintFrame:addChild(hintLabel)
	self:addChild(hintFrame, 15)
	display.commonUIParams(hintFrame, {po = cc.p(display.width + 25 - hintFrame:getContentSize().width * 0.5 * scale, 80)})
	self.hintFrame = hintFrame
	hintFrame:setVisible(false)

	---------- boss弱点 ----------

	for i, v in ipairs(self.args.weakPoints) do
		local touchLayer = display.newLayer(0, 0, {size = cc.size(100, 100), ap = cc.p(0.5, 0.5)})
		local bossWeakSpine = SpineCache(SpineCacheName.BATTLE):createWithName('boss_weak')
		bossWeakSpine:update(0)
		touchLayer:addChild(bossWeakSpine)
		bossWeakSpine:setPosition(utils.getLocalCenter(touchLayer))
		self:addChild(touchLayer, 20)
		table.insert(self.spineNodes, bossWeakSpine)

		local bone = string.format('weak_point_%d', checkint(v.id))
		local effectId = v.effectId or false

		local touchItem = {id = v.id, bone = bone, effectId = effectId, node = touchLayer, spineNode = bossWeakSpine}
		self:addTouchItem(touchItem)
	end

	-- local clipLayer = cc.ClippingNode:create()
	-- clipLayer:setContentSize(display.size)
	-- clipLayer:setAnchorPoint(cc.p(0, 0))
	-- clipLayer:setPosition(cc.p(0, 0))
	-- self:addChild(clipLayer, 10)

	-- local cover = CColorView:create(cc.c4b(0, 0, 0, 255 * 0.6))
	-- cover:setTouchEnabled(true)
	-- cover:setContentSize(display.size)
	-- cover:setPosition(utils.getLocalCenter(clipLayer))
	-- clipLayer:addChild(cover, 1)
	-- -- self.eaterLayer = eaterLayer

	-- local stencilLayer = display.newLayer(0, 0, {size = display.size})
	-- self.stencilLayer = stencilLayer
	-- for i,v in ipairs(self.args.weakPoints) do
	-- 	local bone = string.format('weak_point_%d', checkint(v.id))
	-- 	local effect = v.effect or false
	-- 	local stencil = display.newImageView(_res('battle/ui/battle_btn_weakness_3.png'), 0, 0)
	-- 	stencilLayer:addChild(stencil)
	-- 	local aimNode = display.newImageView(_res('battle/ui/battle_btn_weakness_2.png'), 0, 0)
	-- 	self:addChild(aimNode, 99)
	-- 	local aimShine = display.newImageView(_res('battle/ui/battle_btn_weakness_light.png'), utils.getLocalCenter(aimNode).x, utils.getLocalCenter(aimNode).y)
	-- 	aimNode:addChild(aimShine, -1)
	-- 	local aimIcon = display.newImageView(_res('battle/ui/battle_btn_weakness_1.png'), utils.getLocalCenter(aimNode).x, utils.getLocalCenter(aimNode).y)
	-- 	aimNode:addChild(aimIcon)
	-- 	aimIcon:setScale(1.1)
	-- 	aimIcon:runAction(cc.RepeatForever:create(cc.Sequence:create(
	-- 			cc.ScaleTo:create(0.4, 0.75),
	-- 			cc.ScaleTo:create(0.4, 1.1)
	-- 			)))
	-- 	local touchItem = {id = v.id, bone = bone, effect = effect, stencil = stencil, node = aimNode}
	-- 	self:addTouchItem(touchItem)
	-- end
	-- clipLayer:setInverted(true)
	-- clipLayer:setAlphaThreshold(0.01)
	-- clipLayer:setStencil(stencilLayer)

	---------- 初始化动画状态 ----------

	self.animationConf = {
		fadeInTime = 0.2,
	}
	self.eaterLayer:setOpacity(0)
	self.timeBar:setVisible(false)
end
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

		local touchItem = self.touchItems[tostring(id)]
		-- 这里回传触摸到的弱点序号 结果由外部随机 而不是传结果
		self.result = touchItem.id
		-- 停止时间进度条动画
		self.timeBar:clearTracks()

		self.weekPointBombTime = 0

		if 101 == checkint(touchItem.effectId) then
			touchItem.spineNode:setToSetupPose()
			touchItem.spineNode:setAnimation(0, 'bomb2', false)
			self.weekPointBombTime = SpineCache(SpineCacheName.BATTLE):getAnimationsDataByName('boss_weak')['bomb2'].duration
		elseif 102 == checkint(touchItem.effectId) then
			touchItem.spineNode:setToSetupPose()
			touchItem.spineNode:setAnimation(0, 'bomb1', false)
			self.weekPointBombTime = SpineCache(SpineCacheName.BATTLE):getAnimationsDataByName('boss_weak')['bomb2'].duration
		end

		local actionSeq = cc.Sequence:create(
			cc.DelayTime:create(self.weekPointBombTime),
			cc.FadeTo:create(0.1, 0),
			cc.CallFunc:create(function ()
				self:over()
			end))
		self.eaterLayer:runAction(actionSeq)

		-- 隐藏其他弱点
		for k,v in pairs(self.touchItems) do
			if checkint(k) ~= checkint(id) then
				v.node:setVisible(false)
			end
		end
		
	end
	-- self:over()
end
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

	if self.touchListener_ then
		self:getEventDispatcher():removeEventListener(self.touchListener_)
		self.touchListener_ = nil
	end
	if self.args.overCB then
		xTry(function()
			self.args.overCB({result = self.result, leftTime = math.max(0, self.time - self.weekPointBombTime), skillId = self.skillId})
		end,__G__TRACKBACK__)
	end
	BMediator:SetTimeScale(BMediator:GetTimeScale())
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
		-- display.commonUIParams(v.stencil, {po = v.stencil:getParent():convertToNodeSpace(weakPoint)})
	end
end
--[[
刷新倒计时
--]]
function BossWeakScene:refreshTimerLabel(time)
	display.reloadRichLabel(self.leftTimeLabel, {c = {
		{text = tostring(math.floor(time)), fontSize = fontWithColor('M2PX').fontSize, color = fontWithColor('BC').color},
		{text = '.', fontSize = fontWithColor('SPX').fontSize, color = fontWithColor('BC').color},
		{text = tostring(math.floor((time - math.floor(time)) * 10)), fontSize = fontWithColor('SPX').fontSize, color = fontWithColor('BC').color},
		{text = 's', fontSize = fontWithColor('SPX').fontSize, color = fontWithColor('BC').color},
	}})
	-- self.timeBar:setValue(time * 1000)
end
--[[
开场动画
--]]
function BossWeakScene:startEnterGameAnimation()
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

	-- 遮罩动画
	local eaterLayerActionSeq = cc.Sequence:create(
		cc.EaseIn:create(cc.FadeTo:create(self.animationConf.fadeInTime, 178), 5),
		cc.CallFunc:create(function ()
			-- 显示倒计时
			self.gameStart = true
			self.timeBar:setVisible(true)
		 	self.timeBar:setAnimation(0, sp.AnimationName.idle, false)
		end))
	self.eaterLayer:runAction(eaterLayerActionSeq)

	-- 弱点动画 随机延迟
	for k,v in pairs(self.touchItems) do
		local randomDelay = math.random(5) * 0.1
		local actionSeq = cc.Sequence:create(
			cc.DelayTime:create(randomDelay + self.animationConf.fadeInTime),
			cc.CallFunc:create(function ()
				v.spineNode:setAnimation(0, 'enter', false)
				v.spineNode:addAnimation(0, 'idle', true)
			end))
		v.node:runAction(actionSeq)
	end
end

return BossWeakScene
