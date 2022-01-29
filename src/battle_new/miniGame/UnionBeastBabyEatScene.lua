--[[
战斗结束神兽吃能量场景
@params table {
	beastId int 神兽id
	energyLevel 能量等级
	deltaEnergy 变化的能量
	callback 结束后的回调
}
--]]
local BaseMiniGameScene = __Require('battle.miniGame.BaseMiniGameScene')
local UnionBeastBabyEatScene = class('UnionBeastBabyEatScene', BaseMiniGameScene)

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

--[[
@override
constructor
--]]
function UnionBeastBabyEatScene:ctor( ... )
	BaseMiniGameScene.ctor(self, ...)

	cc.Director:getInstance():getScheduler():setTimeScale(1)

	local args = unpack({...})

	self.beastId = args.beastId
	self.energyLevel = args.energyLevel
	self.deltaEnergy = args.deltaEnergy
	self.callback = args.callback

	self.energyNode = nil
	self.spineNode = nil

	-- self:setBackgroundColor(cc.c4b(255, 128, 128, 100))

	-- print('here check fuck params<<<<<<<<<<<<', self.beastId, self.energyLevel, self.deltaEnergy, self.callback)
end
--[[
@override
--]]
function UnionBeastBabyEatScene:initView()
	BaseMiniGameScene.initView(self)

	self.eaterLayer:setVisible(false)
	self.actionLayer = nil

	local actionLayer = CColorView:create(cc.c4b(0, 0, 0, 0))
	-- actionLayer:setTouchEnabled(true)
	actionLayer:setContentSize(display.size)
	actionLayer:setPosition(utils.getLocalCenter(self))
	self:addChild(actionLayer, 10)
	self.actionLayer = actionLayer
end
--[[
@override
开始游戏
--]]
function UnionBeastBabyEatScene:start()
	BaseMiniGameScene.start(self)
	local actionSeq = cc.Sequence:create(
		cc.FadeTo:create(1, 255),
		cc.CallFunc:create(function ()
			self:clearAll()
			self:createAct()
		end),
		cc.FadeTo:create(1, 0),
		cc.CallFunc:create(function ()
			self:OnActEnter()
		end))
	self.actionLayer:runAction(actionSeq)
end
--[[
@override
游戏结束
--]]
function UnionBeastBabyEatScene:over()
	-- BaseMiniGameScene.over(self)
end
--[[
@override
update
--]]
function UnionBeastBabyEatScene:update(dt)
	
end
--[[
创建表演内容
--]]
function UnionBeastBabyEatScene:createAct()
	local battleRootLayer = G_BattleRenderMgr:GetBattleRoot()
	local actLayer = display.newLayer(0, 0, {size = battleRootLayer:getContentSize()})
	display.commonUIParams(actLayer, {ap = battleRootLayer:getAnchorPoint(), po = cc.p(
		battleRootLayer:getPositionX(),
		battleRootLayer:getPositionY()
	)})
	-- actLayer:setBackgroundColor(cc.c4b(128, 255, 255, 100))
	battleRootLayer:getParent():addChild(actLayer, battleRootLayer:getLocalZOrder())
	self.actLayer = actLayer

	local cellR, cellC = 3, 23
	local eposinbattleroot = G_BattleLogicMgr:GetCellPosByRC(cellR, cellC)

	-- 创建一个能量
	local energyNode = display.newNSprite(_res(CommonUtils.GetGoodsIconPathById(UNION_BEAST_ENERGY_ID)), 0, 0)
	display.commonUIParams(energyNode, {po = cc.p(
		eposinbattleroot.cx,
		eposinbattleroot.cy
	)})
	actLayer:addChild(energyNode)

	self.energyNode = energyNode

	-- 创建一个神兽幼崽spine
	local beastConfig = app.cardMgr.GetBeastConfig(self.beastId)
	local beastBabyId = checkint(beastConfig.petId)
	local beastBabyFormConfig = app.cardMgr.GetBeastBabyFormConfig(beastBabyId, self.energyLevel, 1)
	if nil ~= beastBabyFormConfig then
		local skinId = checkint(beastBabyFormConfig.skinId)
		local fixedScale = checknumber(beastBabyFormConfig.scale)
		local spinePath = CardUtils.GetCardSpinePathBySkinId(skinId)
		local spineNode = sp.SkeletonAnimation:create(
			spinePath .. '.json',
			spinePath .. '.atlas',
			0.5 * fixedScale
		)
		spineNode:update(0)
		local viewBox = spineNode:getBorderBox(sp.CustomName.VIEW_BOX)
		if nil == viewBox then
			viewBox = cc.rect(0, 0, 0, 0)
		end
		spineNode:setPosition(cc.p(
			-viewBox.width,
			eposinbattleroot.cy - (viewBox.y + viewBox.height * 0.5)
		))
		actLayer:addChild(spineNode)

		self.spineNode = spineNode
	end
end
--[[
开始表演
--]]
function UnionBeastBabyEatScene:OnActEnter()
	if self.energyNode and self.spineNode then
		self.spineNode:setToSetupPose()
		self.spineNode:setAnimation(0, sp.AnimationName.run, true)

		local viewBox = self.spineNode:getBorderBox(sp.CustomName.VIEW_BOX)
		if nil == viewBox then
			viewBox = cc.rect(0, 0, 0, 0)
		end
		local animationsData = self.spineNode:getAnimationsData()

		local targetPos = cc.p(
			self.energyNode:getPositionX() - self.energyNode:getContentSize().width * 0.35 * self.energyNode:getScale() - (viewBox.x + viewBox.width),
			self.spineNode:getPositionY()
		)

		local speed = G_BattleLogicMgr:GetCellSize().width * 3
		local moveTime = targetPos.x / speed

		local totalTime = moveTime + 
			animationsData['eat'].duration + 
			animationsData[sp.AnimationName.win].duration + 
			animationsData[sp.AnimationName.win].duration + 
			animationsData[sp.AnimationName.win].duration + 
			1

		local spineNodeActionSeq = cc.Sequence:create(
			cc.MoveTo:create(moveTime, targetPos),
			cc.CallFunc:create(function ()
				-- 开始吃
				self.spineNode:setToSetupPose()
				self.spineNode:setAnimation(0, 'eat', false)
				self.spineNode:addAnimation(0, sp.AnimationName.win, false)
				self.spineNode:addAnimation(0, sp.AnimationName.win, false)
				self.spineNode:addAnimation(0, sp.AnimationName.win, false)
				self.spineNode:addAnimation(0, sp.AnimationName.idle, true)

				-- 获得能量的spine
				local upgradeSpine = sp.SkeletonAnimation:create(
					'effects/pet/shengxing.json',
					'effects/pet/shengxing.atlas',
					1
				)
				upgradeSpine:setPosition(cc.p(
					self.spineNode:getPositionX(),
					self.spineNode:getPositionY()
				))
				self.actLayer:addChild(upgradeSpine, 10)
				upgradeSpine:setToSetupPose()
				upgradeSpine:setAnimation(0, 'play1', false)

				-- 说一句话
				local beastConfig = app.cardMgr.GetBeastConfig(self.beastId)
				local beastBabyId = checkint(beastConfig.petId)
				local voiceConfig = app.cardMgr.GetUnionBeastBabyVoiceConfigByVoiceType(beastBabyId, UnionPetVoiceType.AFTER_ENERGY)
				app.uiMgr:ShowDialogueBubble({
					targetNode = self.spineNode,
					descr = tostring(voiceConfig.descr),
					parentNode = self.actLayer,
					zorder = 999,
					alwaysOnCenter = true,
					alwaysOnTop = true,
					ignoreOutside = true
				})

				-- 能量动画
				local eatTime = animationsData['eat'].duration
				local energyNodeActionSeq = cc.Sequence:create(
					cc.Spawn:create(
						ShakeAction:create(eatTime, 10, 5),
						cc.FadeTo:create(eatTime, 0)
					),
					cc.Hide:create()
				)
				self.energyNode:runAction(energyNodeActionSeq)

				-- 飘字
				local energyLabel = display.newLabel(0, 0, fontWithColor('20', {text = '+' .. tostring(self.deltaEnergy)}))
				display.commonUIParams(energyLabel, {po = cc.p(
					self.energyNode:getPositionX(),
					self.energyNode:getPositionY() + self.energyNode:getContentSize().height * 0.5 * self.energyNode:getScaleY()
				)})
				self.actLayer:addChild(energyLabel, 10)
				energyLabel:setVisible(false)

				local labelActionSeq = cc.Sequence:create(
					cc.Show:create(),
					cc.Spawn:create(
						cc.MoveBy:create(0.5, cc.p(0, 50)),
						cc.FadeTo:create(0.5, 255 * 0.5)
					),
					cc.Hide:create()
				)
				energyLabel:runAction(labelActionSeq)
			end)
		)
		self.spineNode:runAction(spineNodeActionSeq)

		local actLayerActionSeq = cc.Sequence:create(
			cc.DelayTime:create(totalTime),
			cc.CallFunc:create(function ()
				self:OnActExit()
			end)
		)
		self.actLayer:runAction(actLayerActionSeq)

		-- 音效
		local soundActionSeq = cc.Sequence:create(
			-- 跑音效
			cc.CallFunc:create(function ()
				local beastConfig = app.cardMgr.GetBeastConfig(self.beastId)
				local beastBabyId = checkint(beastConfig.petId)
				local beastBabyFormConfig = app.cardMgr.GetBeastBabyFormConfig(beastBabyId, self.energyLevel, 1)
				if nil ~= beastBabyFormConfig then					
					local skinId = checkint(beastBabyFormConfig.skinId)
					local skinConfig = CardUtils.GetCardSkinConfig(skinId)
					local spineId = checkint(skinConfig.spineId)
					local effectId = AUDIOS.UI.ui_shoutuanzi_run.id
					if 300064 == spineId then
						effectId = AUDIOS.UI.ui_shouyao_run.id
					end
					PlayAudioClip(effectId)
				end
			end),
			cc.DelayTime:create(moveTime),
			-- 吃音效
			cc.CallFunc:create(function ()
				PlayAudioClip(AUDIOS.UI.ui_shoutuanzi_energy.id)
			end),
			cc.DelayTime:create(animationsData['eat'].duration + 0.1),
			-- 翻滚音效
			cc.CallFunc:create(function ()
				PlayAudioClip(AUDIOS.UI.ui_shoutuanzi_win.id)
			end),
			cc.DelayTime:create(animationsData[sp.AnimationName.win].duration),
			-- 翻滚音效
			cc.CallFunc:create(function ()
				PlayAudioClip(AUDIOS.UI.ui_shoutuanzi_win.id)
			end),
			cc.DelayTime:create(animationsData[sp.AnimationName.win].duration),
			-- 翻滚音效
			cc.CallFunc:create(function ()
				PlayAudioClip(AUDIOS.UI.ui_shoutuanzi_win.id)
			end)
		)
		self:runAction(soundActionSeq)

	else
		self:OnActBreak()
	end
end
--[[
表演被打断
--]]
function UnionBeastBabyEatScene:OnActBreak()
	self:OnActExit()
end
--[[
表演结束
--]]
function UnionBeastBabyEatScene:OnActExit()
	if nil ~= self.callback then
		self.callback()
	end
end
--[[
清场
--]]
function UnionBeastBabyEatScene:clearAll()
	-- 所有物体强制隐藏
	G_BattleRenderMgr:ForceShowAllObjectView(false)

	-- 隐藏所有ui
	G_BattleRenderMgr:GetBattleScene():ShowUILayer(false)
end

return UnionBeastBabyEatScene
