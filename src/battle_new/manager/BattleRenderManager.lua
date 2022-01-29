--[[
战斗渲染管理器
@params _ table {
	battleConstructor BattleConstructor 战斗构造器
}
--]]
---@type BaseBattleManager
local BaseBattleManager = __Require('battle.manager.BaseBattleManager')
---@class BattleRenderManager:BaseBattleManager
local BattleRenderManager = class('BattleRenderManager', BaseBattleManager)

------------ import ------------
------------ import ------------

------------ define ------------
local BUY_REVIVAL_LAYER_TAG = 2301
local FORCE_QUIT_LAYER_TAG = 2311
local PAUSE_SCENE_TAG = 1001
local WAVE_TRANSITION_SCENE_TAG = 1201

local GAME_RESULT_LAYER_TAG = 2321
local SKADA_LAYER_TAG = 2322

-- 战斗bgm定义
-- @see Game.init AUDIOS
local BattleBgmDefault = {
	SHEET_NAME = AUDIOS.BGM.name,
	CUE_NAME   = AUDIOS.BGM.Food_Battle.id
}
------------ define ------------

--[[
construtor
--]]
function BattleRenderManager:ctor( ... )
	BaseBattleManager.ctor(self, ...)
end

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化整个的逻辑
--]]
function BattleRenderManager:Init()
	BaseBattleManager.Init(self)

	-- 初始化数据
	self:InitValue()
end
--[[
初始化数据
--]]
function BattleRenderManager:InitValue()
	-- 物体渲染层数据
	self.objectViews = {}
	-- qte物体渲染层数据
	self.qteAttachViews = {}
	-- 主角模型渲染层数据
	self.playerViews = {}

	-- 战斗场景是否可以触摸
	self.battleTouchEnable = false

	-- 连携技按钮
	self.connectButtons = {}
	self.connectButtonsIndex = {}

	-- 暂停游戏的场景
	self.ciScenes = {pause = {}, normal = {}} -- 缓存ci场景 暂停的时候会判断ci场景是否暂停了obj 如果有恢复的时候不会恢复obj
	-- 暂停的coco2dx actions
	self.pauseActions = {pauseScene = {}, normalScene = {}, battle = {}}

	------------ 顶部语音气泡节点 ------------
	self.friendDialougeNodes = {}
	self.enemyDialougeNodes = {}

	self.friendDialougeY = 0
	self.enemyDialougeY = 0
	self.dialougeTagCounter = 0
	------------ 顶部语音气泡节点 ------------

	------------ 状态锁 ------------
	self.quitLock = false
	self.restartLock = false
	------------ 状态锁 ------------
end
--[[
进入战斗
--]]
function BattleRenderManager:EnterBattle()
	-- 初始化驱动
	self:InitBattleDrivers()
end
--[[
初始化战斗驱动器
--]]
function BattleRenderManager:InitBattleDrivers()
	------------ 资源加载驱动器 ------------
	local resLoadDriverClassName = 'battle.battleDriver.BattleResLoadDriver'

	if self:IsTagMatchBattle() then

		resLoadDriverClassName = 'battle.battleDriver.TagMatchResLoadDriver'

	end

	local resLoadDriver = __Require(resLoadDriverClassName).new({owner = self})
	self:SetBattleDriver(BattleDriverType.RES_LOADER, resLoadDriver)
	------------ 资源加载驱动器 ------------
end
--[[
初始化引导驱动 -> 引导驱动依赖一些渲染层的实例 在场景创建完毕后初始化
--]]
function BattleRenderManager:InitGuideDriver()
	------------ 引导驱动器 ------------
	local guideDriver = __Require('battle.battleDriver.RenderGuideDriver').new({owner = self})
	self:SetBattleDriver(BattleDriverType.GUIDE_DRIVER, guideDriver)
	------------ 引导驱动器 ------------
end
--[[
初始化按钮回调
--]]
function BattleRenderManager:InitButtonClickHandler()
	local battleScene = self:GetBattleScene()
	if nil ~= battleScene.viewData and nil ~= battleScene.viewData.actionButtons then
		for _, button in ipairs(battleScene.viewData.actionButtons) do
			display.commonUIParams(button, {cb = handler(self, self.ButtonsClickHandler), animate = false})
		end
	end

	------------ 录屏回调 ------------
	if BattleConfigUtils.IsScreenRecordEnable() then
		local screenRecordBtn = self:GetBattleScene().viewData.screenRecordBtn
		if nil ~= screenRecordBtn then
			display.commonUIParams(screenRecordBtn, {
				cb = handler(self, self.ScreenRecordClickHandler)
			})
		end
	end
	------------ 录屏回调 ------------
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- control begin --
---------------------------------------------------
--[[
开始加载资源
--]]
function BattleRenderManager:StartLoadResources()
	-- 加载音频资源
	self:LoadSoundResources()

	-- 加载图片资源
	self:LoadRenderResources(1)
end
--[[
加载音效资源
--]]
function BattleRenderManager:LoadSoundResources()
	self:GetBattleDriver(BattleDriverType.RES_LOADER):LoadSoundResources()
end
--[[
加载图片资源
@params wave int 加载的资源波数
--]]
function BattleRenderManager:LoadRenderResources(wave)
	self:GetBattleDriver(BattleDriverType.RES_LOADER):OnLogicEnter(wave)
end
--[[
资源加载结束
--]]
function BattleRenderManager:LoadResourcesOver()
	-- 初始化战斗场景按钮回调
	self:InitButtonClickHandler()

	-- 刷新一些界面信息
	self:RefreshTimeLabel(self:GetBattleConstructData().time)

	-- debug格子
	-- self:DebugCells()
end
--[[
逻辑层初始化完毕 再初始化一些东西
--]]
function BattleRenderManager:LogicInitOver()
	-- 初始化引导驱动
	self:InitGuideDriver()

	-- 初始化一些功能模块ui
	self:InitBattleModule()

	-- debug格子
	-- self:DebugCells()
end
---------------------------------------------------
-- control end --
---------------------------------------------------

---------------------------------------------------
-- main update begin --
---------------------------------------------------
--[[
渲染层主循环
--]]
function BattleRenderManager:MainUpdate(dt)
	for _, pauseCIScene in pairs(self.ciScenes.pause) do
		pauseCIScene:update(dt)
	end
	for _,normalCIScene in pairs(self.ciScenes.normal) do
		normalCIScene:update(dt)
	end
end
---------------------------------------------------
-- main update end --
---------------------------------------------------

---------------------------------------------------
-- view control begin --
---------------------------------------------------
--[[
显示提示 进入下波
@params wave int 波数
@params hasElite bool 含有精英
@params hasBoss bool 含有boss
@params callback function 动画结束以后的回调函数
--]]
function BattleRenderManager:ShowEnterNextWave(wave, hasElite, hasBoss)
	self:ShowNextWaveRemind(wave, function ()
		-- 设置触摸可用
		self:SetBattleTouchEnable(true)

		-- 开启一些渲染层的倒计时
		self:StartRenderCountdown()

		if not self:IsCalculator() then
			--###---------- 刷新逻辑层 ----------###--
			-- 回传消息开始下一波
			self:AddPlayerOperate(
				'G_BattleLogicMgr',
				'RenderStartNextWaveHandler'
			)
			--###---------- 刷新逻辑层 ----------###--
		end
	end)

	self:ShowBossAppear(hasElite, hasBoss)
end
--[[
显示下一波提示
@params wave int 波数
@params callback function 动画结束以后的回调函数
--]]
function BattleRenderManager:ShowNextWaveRemind(wave, callback)
	local battleScene = self:GetBattleScene()
	local uiLayer = battleScene.viewData.uiLayer

	local roundBg = display.newImageView(_res('ui/battle/battle_bg_black.png'), -display.width * 0.5, display.height * 0.5, {scale9 = true, size = cc.size(display.width, 144)})
	uiLayer:addChild(roundBg, BATTLE_E_ZORDER.UI_EFFECT)

	local plate = display.newNSprite(_res('ui/battle/battle_bg_switch.png'), display.width * 0.5, display.height * 0.5)
	uiLayer:addChild(plate, BATTLE_E_ZORDER.UI_EFFECT)
	plate:setScale(0)

	local knifeDeltaP = cc.p(50, -50)
	local knife = display.newNSprite(_res('ui/battle/battle_ico_switch_1.png'), display.width * 0.5 - knifeDeltaP.x, display.height * 0.5 - knifeDeltaP.y)
	uiLayer:addChild(knife, BATTLE_E_ZORDER.UI_EFFECT)
	knife:setOpacity(0)

	local forkDeltaP = cc.p(-50, -50)
	local fork = display.newNSprite(_res('ui/battle/battle_ico_switch_2.png'), display.width * 0.5 - forkDeltaP.x, display.height * 0.5 - forkDeltaP.y)
	uiLayer:addChild(fork, BATTLE_E_ZORDER.UI_EFFECT)
	fork:setOpacity(0)

	local labelBg = display.newNSprite(_res('ui/battle/battle_bg_switch_word.png'), 0, 0)
	display.commonUIParams(labelBg, {ap = cc.p(0, 0.5), po = cc.p(display.width * 0.5 - labelBg:getContentSize().width * 0.5, display.height * 0.5)})
	uiLayer:addChild(labelBg, BATTLE_E_ZORDER.UI_EFFECT)
	labelBg:setScaleX(0)

	local waveStr = ''
	if 1 == wave then
		waveStr = __('战斗开始')
	else
		waveStr = string.format(__('第%s回合'), CommonUtils.GetChineseNumber(checkint(wave)))
	end

	local waveLabel = display.newLabel(display.width * 0.5, display.height * 0.5,
		{text = waveStr, fontSize = 32, color = '#ffffff', ttf = true, font = TTF_GAME_FONT, outline = '#2e1e14'})
	uiLayer:addChild(waveLabel, BATTLE_E_ZORDER.UI_EFFECT)
	waveLabel:setOpacity(0)

	local bgActionSeq = cc.Sequence:create(
		cc.MoveBy:create(0.15, cc.p(display.width, 0)),
		cc.DelayTime:create(1.15),
		cc.FadeTo:create(0.2, 0),
		cc.RemoveSelf:create())
	roundBg:runAction(bgActionSeq)

	local plateActionSeq = cc.Sequence:create(
		cc.DelayTime:create(0.15),
		cc.ScaleTo:create(0.1, 1),
		cc.DelayTime:create(1.05),
		cc.FadeTo:create(0.2, 0),
		cc.RemoveSelf:create())
	plate:runAction(plateActionSeq)

	local knifeActionSeq = cc.Sequence:create(
		cc.DelayTime:create(0.2),
		cc.Spawn:create(
			cc.MoveBy:create(0.1, knifeDeltaP),
			cc.FadeTo:create(0.1, 255)),
		cc.DelayTime:create(1),
		cc.FadeTo:create(0.2, 0),
		cc.RemoveSelf:create())
	knife:runAction(knifeActionSeq)

	local forkActionSeq = cc.Sequence:create(
		cc.DelayTime:create(0.25),
		cc.Spawn:create(
			cc.MoveBy:create(0.1, forkDeltaP),
			cc.FadeTo:create(0.1, 255)),
		cc.DelayTime:create(0.95),
		cc.FadeTo:create(0.2, 0),
		cc.RemoveSelf:create())
	fork:runAction(forkActionSeq)

	local labelBgActionSeq = cc.Sequence:create(
		cc.DelayTime:create(0.35),
		cc.EaseSineOut:create(cc.ScaleTo:create(0.15, 1, 1)),
		cc.DelayTime:create(0.8),
		cc.FadeTo:create(0.2, 0),
		cc.RemoveSelf:create())
	labelBg:runAction(labelBgActionSeq)

	local labelActionSeq = cc.Sequence:create(
		cc.DelayTime:create(0.35),
		cc.FadeTo:create(0.2, 255),
		cc.DelayTime:create(0.75),
		cc.FadeTo:create(0.2, 0),
		cc.CallFunc:create(function ()
			if callback then
				callback()
			end
		end),
		cc.RemoveSelf:create())
	waveLabel:runAction(labelActionSeq)
end
--[[
显示boss来袭
@params hasElite bool 含有精英
@params hasBoss bool 含有boss
--]]
function BattleRenderManager:ShowBossAppear(hasElite, hasBoss)
	if not hasBoss then return end

	local battleScene = self:GetBattleScene()

	local waringBg = display.newNSprite(_res('ui/battle/battle_bg_warning.png'), display.width * 0.5, display.height * 0.5)
	local waringBgSize = waringBg:getContentSize()

	waringBg:setScaleX(display.width / waringBgSize.width)
	waringBg:setScaleY(display.height / waringBgSize.height)

	battleScene.viewData.uiLayer:addChild(waringBg)

	waringBg:setOpacity(0)
	local waringActionSeq = cc.Sequence:create(
		cc.Repeat:create(cc.Sequence:create(
			cc.FadeTo:create(0.5, 255),
			cc.DelayTime:create(0.25),
			cc.FadeTo:create(0.5, 0)
		), 3),
		cc.RemoveSelf:create()
	)
	waringBg:runAction(waringActionSeq)
end
--[[
显示特效层
@params show bool 显示特效层
--]]
function BattleRenderManager:ShowBattleEffectLayer(show)
	self:GetBattleScene().viewData.effectLayer:setVisible(show)
end
--[[
开始一些本地的倒计时 刷新一些倒计时界面
--]]
function BattleRenderManager:StartRenderCountdown()
	self:GetBattleScene():StartAliveCountdown()
end
--[[
刷新战斗bgm
@parmas teamMembers list
]]
function BattleRenderManager:RefreshBattleBgm(teamMembers)
	local defaultBgmData = self:GetDefaultBattleBGMInfo()
	local bgmData = {
		name = defaultBgmData.SHEET_NAME,
		id   = defaultBgmData.CUE_NAME,
	}
	for memberIndex, memberObj in ipairs(teamMembers or {}) do
		local cardId   = memberObj:GetObjectConfigId()
		local skinId   = memberObj:GetObjectSkinId()
		local skinConf = CardUtils.GetCardSkinConfig(skinId)
		if string.len(checkstr(skinConf.bgm)) > 0 then
			local datas  = string.split2(skinConf.bgm, ',')
			bgmData.name = datas[1]
			bgmData.id   = datas[2]
			break
		end
	end
	self:GetBattleScene():PlayBattleBgm(bgmData.name, bgmData.id)
end
--[[
获取默认的战斗bgm信息
@return map {
	sheetName = string, cueName = string
}
--]]
function BattleRenderManager:GetDefaultBattleBGMInfo()
	return BattleBgmDefault
end
---------------------------------------------------
-- view control end --
---------------------------------------------------

---------------------------------------------------
-- object view begin --
---------------------------------------------------
--[[
根据物体信息创建一个物体的view
@params viewModelTag int 展示层的tag
@params objInfo ObjectConstructorStruct 物体构造信息
@params visible bool 是否将物体设置不可见
--]]
function BattleRenderManager:CreateAObjectView(viewModelTag, objInfo, visible)
	local cardId = objInfo.cardId
	local cardConfig = CardUtils.GetCardConfig(cardId)

	------------ 处理渲染模型类型 ------------
	local viewClassName = 'battle.objectView.cardObject.BaseObjectView'

	if CardUtils.IsMonsterCard(cardId) then

		local monsterType = checkint(cardConfig.type)

		if ConfigMonsterType.BOSS == monsterType then
			viewClassName = 'battle.objectView.cardObject.BossView'
		else
			viewClassName = 'battle.objectView.cardObject.MonsterView'
		end

	else

		viewClassName = 'battle.objectView.cardObject.CardObjectView'

	end
	------------ 处理渲染模型类型 ------------

	local viewInfo = ObjectViewConstructStruct.New(
		cardId,
		objInfo.skinId,
		objInfo.avatarScale,
		self:GetSpineAvatarScale2CardByCardId(cardId),
		objInfo.isEnemy
	)

	local view = __Require(viewClassName).new({
		tag = viewModelTag,
		viewInfo = viewInfo
	})
	self:AddAObjectView(viewModelTag, view)

	-- 将物体加到场景中
	self:GetBattleRoot():addChild(view)

	if nil ~= visible then
		view:SetObjectVisible(visible)
	end
end
--[[
设置物体不可见
@params viewModelTag int 展示层tag
@params visible bool 是否可见
--]]
function BattleRenderManager:SetObjectViewVisible(viewModelTag, visible)
	local view = self:GetAObjectView(viewModelTag)
	if nil ~= view then
		view:SetObjectVisible(visible)
	end
end
--[[
根据物体信息创建一个召唤物的view
@params viewModelTag int 展示层tag
@params tag int 逻辑层的tag
@params objInfo ObjectConstructorStruct 物体构造信息
--]]
function BattleRenderManager:CreateABeckonObjectView(viewModelTag, tag, objInfo)
	local cardId = objInfo.cardId
	local viewClassName = 'battle.objectView.cardObject.BeckonView'

	local viewInfo = ObjectViewConstructStruct.New(
		cardId,
		objInfo.skinId,
		objInfo.avatarScale,
		self:GetSpineAvatarScale2CardByCardId(cardId),
		objInfo.isEnemy
	)

	local view = __Require(viewClassName).new({
		tag = viewModelTag,
		viewInfo = viewInfo,
		logicTag = tag
	})

	self:AddAObjectView(viewModelTag, view)

	-- 将物体加到场景中
	self:GetBattleRoot():addChild(view)
end
--[[
刷新object view
@params tag int 展示层的tag
@params renderTransformData ObjectRenderRefreshTranformStruct 刷新渲染层的数据
@params renderStateData ObjectRenderRefreshStateStruct 刷新渲染层状态的数据
--]]
function BattleRenderManager:RefreshObjectView(tag, renderTransformData, renderStateData)
	self:RefreshObjectViewTransform(tag, renderTransformData)
	self:RefreshObjectViewHPState(tag, renderStateData)
end
--[[
刷新object view 的transform状态
@params tag int 展示层的tag
@params renderTransformData ObjectRenderRefreshTranformStruct 刷新渲染层的数据
--]]
function BattleRenderManager:RefreshObjectViewTransform(tag, renderTransformData)
	local view = self:GetAObjectView(tag)

	if nil ~= view then
		-- 坐标
		self:SetObjectViewPositionByView(view, renderTransformData.x, renderTransformData.y)

		-- 朝向
		self:SetObjectViewTowardsByView(view, renderTransformData.towards)

		-- zorder
		self:SetObjectViewZOrderByView(view, renderTransformData.zorder)
	end
end
--[[
设置view的坐标
@params tag int 展示层的tag
@params x
@parmas y
--]]
function BattleRenderManager:SetObjectViewPosition(tag, x, y)
	local view = self:GetAObjectView(tag)
	if nil ~= view then
		self:SetObjectViewPositionByView(view, x, y)
	end
end
--[[
设置view的坐标
@params view cc.node
@params x
@parmas y
--]]
function BattleRenderManager:SetObjectViewPositionByView(view, x, y)
	view:setPositionX(x)
	view:setPositionY(y)
end
--[[
设置view的朝向
@params tag int 展示层的tag
@params towards BattleObjTowards 朝向
--]]
function BattleRenderManager:SetObjectViewTowards(tag, towards)
	local view = self:GetAObjectView(tag)
	if nil ~= view then
		self:SetObjectViewTowardsByView(view, towards)
	end
end
--[[
设置view的朝向
@params view cc.node
@params towards BattleObjTowards 朝向
--]]
function BattleRenderManager:SetObjectViewTowardsByView(view, towards)
	local sign = 1

	if BattleObjTowards.FORWARD == towards then
		sign = 1
	elseif BattleObjTowards.NEGATIVE == towards then
		sign = -1
	end

	local avatar = nil
	if view and view.GetAvatar then
		avatar = view:GetAvatar()
	end

	if nil ~= avatar then
		avatar:setScaleX(
			math.abs(avatar:getScaleX()) * sign
		)
	end
end
--[[
设置view的zorder
@params tag int 展示层的tag
@params zorder int cocos2dx zorder
--]]
function BattleRenderManager:SetObjectViewZOrder(tag, zorder)
	local view = self:GetAObjectView(tag)
	if nil ~= view then
		self:SetObjectViewZOrderByView(view, zorder)
	end
end
--[[
设置view的zorder
@params view cc.node
@params zorder int cocos2dx zorder
--]]
function BattleRenderManager:SetObjectViewZOrderByView(view, zorder)
	view:setLocalZOrder(zorder)
end
--[[
设置view的rotate
@params tag int 展示层的tag
@params rotate number 角度
--]]
function BattleRenderManager:SetObjectViewRotate(tag, rotate)
	local view = self:GetAObjectView(tag)
	if nil ~= view and view.GetAvatar then
		view:GetAvatar():setRotation(rotate)
	end
end
--[[
刷新object view的血量能量
@params tag int 展示层的tag
@params renderStateData ObjectRenderRefreshStateStruct 刷新渲染层状态的数据
--]]
function BattleRenderManager:RefreshObjectViewHPState(tag, renderStateData)
	local view = self:GetAObjectView(tag)

	if nil ~= view then
		-- 刷新血条
		self:SetObjectViewHpPercentByView(view, renderStateData.hpPercent)

		-- 刷新能量条
		self:SetObjectViewEnergyPercentByView(view, renderStateData.energyPercent)
	end
end
--[[
刷新物体血量
@params tag int 展示层的tag
@params hpPercent number 血量百分比
--]]
function BattleRenderManager:SetObjectViewHpPercent(tag, hpPercent)
	local view = self:GetAObjectView(tag)
	if nil ~= view then
		self:SetObjectViewHpPercentByView(view, hpPercent)
	end
end
--[[
刷新物体血量
@params view cc.node
@params hpPercent number 血量百分比
--]]
function BattleRenderManager:SetObjectViewHpPercentByView(view, hpPercent)
	if view and view.UpdateHpBar then
		view:UpdateHpBar(hpPercent)
	end
end
--[[
刷新物体能量条
@params tag int 展示层的tag
@params energyPercent number 血量百分比
--]]
function BattleRenderManager:SetObjectViewEnergyPercent(tag, energyPercent)
	local view = self:GetAObjectView(tag)
	if nil ~= view then
		self:SetObjectViewEnergyPercentByView(view, energyPercent)
	end
end
--[[
刷新物体能量条
@params view cc.node
@params energyPercent number 血量百分比
--]]
function BattleRenderManager:SetObjectViewEnergyPercentByView(view, energyPercent)
	if view and view.UpdateEnergyBar then
		view:UpdateEnergyBar(energyPercent)
	end
end
--[[
让view做动画
@params tag int 展示层的tag
@params setToSetupPose bool 是否恢复第一帧
@params timeScale int 动画速度缩放
@params setAnimationName string set的动画名字
@params setAnimationLoop bool set的动画是否循环
@params addAnimationName string add的动画名字
@params addAnimationLoop bool add的动画是否循环
--]]
function BattleRenderManager:ObjectViewDoAnimation(tag, setToSetupPose, timeScale, setAnimationName, setAnimationLoop, addAnimationName, addAnimationLoop)
	local view = self:GetAObjectView(tag)
	if nil ~= view then
		self:SetObejectViewAnimation(view, setToSetupPose, timeScale, setAnimationName, setAnimationLoop, addAnimationName, addAnimationLoop)
	end
end
function BattleRenderManager:SetObejectViewAnimation(view, setToSetupPose, timeScale, setAnimationName, setAnimationLoop, addAnimationName, addAnimationLoop)
	local avatar = view.GetAvatar and view:GetAvatar() or nil

	if avatar and true == setToSetupPose then
		avatar:setToSetupPose()
	end

	if avatar and nil ~= setAnimationName then
		avatar:setAnimation(0, setAnimationName, setAnimationLoop)
	end

	if avatar and nil ~= addAnimationName then
		avatar:addAnimation(0, addAnimationName, addAnimationLoop)
	end

	if avatar and nil ~= timeScale then
		avatar:setTimeScale(timeScale)
	end
end
--[[
清除view的动画
@params viewModelTag int 展示层tag
--]]
function BattleRenderManager:ClearObjectViewAnimations(viewModelTag)
	local view = self:GetAObjectView(tag)
	if nil ~= view and view.GetAvatar then
		local avatar = view:GetAvatar()
		if nil ~= avatar then
			avatar:clearTracks()
		end
	end
end
--[[
缩放view动画速度
@params tag int 展示层的tag
@params timeScale number
--]]
function BattleRenderManager:ObjectViewSetAnimationTimeScale(tag, timeScale)
	local view = self:GetAObjectView(tag)
	if nil ~= view and view.GetAvatar then
		local avatar = view:GetAvatar()
		if nil ~= avatar then
			avatar:setTimeScale(timeScale)
		end
	end
end
--[[
显示物体免疫文字
@params tag int 展示层的tag
--]]
function BattleRenderManager:ShowObjectViewImmune(tag)
	local view = self:GetAObjectView(tag)
	if nil ~= view then
		view:ShowImmune()
	end
end
--[[
显示打断提示
@params tag int 展示层的tag
@params weakEffectId ConfigWeakPointId 弱点效果id
--]]
function BattleRenderManager:ShowObjectWeakHint(tag, weakEffectId)
	local view = self:GetAObjectView(tag)

	if nil ~= view and view.ShowChantBreakEffect then
		view:ShowChantBreakEffect(weakEffectId)
	end
end
--[[
设置物体颜色
@params tag int 展示层的tag
@params color cc.c3b 颜色
--]]
function BattleRenderManager:SetObjectViewColor(tag, color)
	local view = self:GetAObjectView(tag)
	if view and view.SetObjectViewColor then
		view:SetObjectViewColor(color)
	end
end
--[[
添加一个buff icon
@params tag int 展示层的tag
@params iconType BuffIconType 图标类型
@params value number 数值
--]]
function BattleRenderManager:ObjectViewAddABuffIcon(tag, iconType, value)
	local view = self:GetAObjectView(tag)
	if nil ~= view and view.AddBuff then
		view:AddBuff(iconType, value)
	end
end
--[[
移除一个buff icon
@params tag int 展示层的tag
@params iconType BuffIconType 图标类型
@params value number 数值
--]]
function BattleRenderManager:ObjectViewRemoveABuffIcon(tag, iconType, value)
	local view = self:GetAObjectView(tag)
	if nil ~= view and view.RemoveBuff then
		view:RemoveBuff(iconType, value)
	end
end
--[[
显示被击爆点特效
@params tag int 展示层的tag
@params effectData HurtEffectStruct 被击特效数据
--]]
function BattleRenderManager:ObjectViewShowHurtEffect(tag, effectData)
	local view = self:GetAObjectView(tag)
	if nil ~= view and view.ShowHurtEffect then
		view:ShowHurtEffect(effectData)
		self:PlayBattleSoundEffect(effectData.effectSoundEffectId)
	end
end
--[[
显示附加效果特效
@params tag int 展示层的tag
@params visible bool 是否可见
@params	buffId string buff id
@params effectData AttachEffectStruct 被击特效数据
--]]
function BattleRenderManager:ObjectViewShowAttachEffect(tag, visible, buffId, effectData)
	local view = self:GetAObjectView(tag)
	if nil ~= view and view.ShowAttachEffect then
		view:ShowAttachEffect(visible, buffId, effectData)
	end
end
--[[
物体开始死亡
@params tag int 展示层的tag
--]]
function BattleRenderManager:ObjectViewDieBegin(tag)
	local view = self:GetAObjectView(tag)
	if nil ~= view and view.DieBegin then
		view:DieBegin()
	end
end
--[[
杀死渲染层
@params tag int 展示层的tag
--]]
function BattleRenderManager:KillObjectView(tag)
	local view = self:GetAObjectView(tag)
	if nil ~= view and view.DieEnd then
		view:DieEnd()
	end
end
--[[
根据effect id强制移除一次obj上hold的动画
@params effectId string effect id
--]]
function BattleRenderManager:ForceRemoveAttachEffectByEffectId(effectId)
	for _, view in pairs(self.objectViews) do
		if nil ~= view and view.RemoveAttachEffectByEffectId then
			view:RemoveAttachEffectByEffectId(effectId)
		end
	end
end
--[[
显示object的目标mark
@params viewModelTag int 展示层的tag
@params stageCompleteType ConfigStageCompleteType 过关类型
@params show bool 是否显示 
--]]
function BattleRenderManager:ObjectViewShowTargetMark(viewModelTag, stageCompleteType, show)
	local view = self:GetAObjectView(viewModelTag)
	if nil ~= view and view.ShowStageClearTargetMark then
		view:ShowStageClearTargetMark(stageCompleteType, show)
	end
end
--[[
隐藏object所有的目标mark
@params viewModelTag int 展示层的tag
--]]
function BattleRenderManager:ObjectViewHideAllTargetMark(viewModelTag)
	local view = self:GetAObjectView(viewModelTag)
	if nil ~= view and view.HideAllStageClearTargetMark then
		view:HideAllStageClearTargetMark()
	end
end
--[[
复活object view
@params viewModelTag int 展示层的tag
--]]
function BattleRenderManager:ObjectViewRevive(viewModelTag)
	local view = self:GetAObjectView(viewModelTag)
	if nil ~= view and view.Revive then
		view:Revive()
	end
end
---------------------------------------------------
-- object view end --
---------------------------------------------------

---------------------------------------------------
-- bullet view begin --
---------------------------------------------------
--[[
根据物体信息创建一个子弹的view
@params tag int 展示层的tag
@params bulletInfo ObjectSendBulletData 子弹物体构造信息
--]]
function BattleRenderManager:CreateABulletObjectView(tag, bulletInfo)
	
	if ConfigEffectBulletType.BASE ~= bulletInfo.otype then

		local className = self:GetBulletObjectViewClassName(bulletInfo.otype)
		local parentNode, zorder, fixedLocation = self:GetfixedBulletParentAndZOrder(bulletInfo)

		local viewInfo = BulletViewConstructorStruct.New(
			bulletInfo.otype,
			bulletInfo.causeType,
			bulletInfo.spineId,
			bulletInfo.bulletScale,
			bulletInfo.towards
		)

		local view = __Require(className).new({
			tag = tag,
			viewInfo = viewInfo
		})

		self:AddAObjectView(tag, view)

		-- 将物体加到场景中
		if nil ~= zorder then
			parentNode:addChild(view, zorder)
		else
			parentNode:addChild(view)
		end

		if nil ~= fixedLocation then
			view:setPosition(fixedLocation)
		end

	else

		-- base子弹类型不创建渲染层模型
		
	end
end
--[[
根据子弹类型获取子弹类的class name
@params bulletType ConfigEffectBulletType 子弹类型
@return _ string 子弹的 class name
--]]
function BattleRenderManager:GetBulletObjectViewClassName(bulletType)
	local config = {
		-- 纯spine特效类型 只播一遍动画 由动画事件发起效果
		[ConfigEffectBulletType.SPINE_EFFECT] 				= 'battle.objectView.bulletObject.BaseSpineBulletView',
		-- 纯spine特效类型 循环播动画 效果结束后隐藏特效
		[ConfigEffectBulletType.SPINE_PERSISTANCE] 			= 'battle.objectView.bulletObject.SpinePersistenceBulletView',
		-- 直线投掷物 循环播动画 碰撞后消失
		[ConfigEffectBulletType.SPINE_UFO_STRAIGHT] 		= 'battle.objectView.bulletObject.SpineUFOBulletView',
		-- 抛物线投掷物 循环播动画 碰撞后消失
		[ConfigEffectBulletType.SPINE_UFO_CURVE] 			= 'battle.objectView.bulletObject.SpineUFOBulletView',
		-- 激光投掷物 只播一遍动画 播完后消失 由动画事件发起效果
		[ConfigEffectBulletType.SPINE_LASER] 				= 'battle.objectView.bulletObject.SpineLaserBulletView',
		-- 回旋镖投掷物 循环播动画 回旋后小时 由碰撞发起效果
		[ConfigEffectBulletType.SPINE_WINDSTICK] 			= 'battle.objectView.bulletObject.SpineWindStickBulletView'
	}

	return config[bulletType]
end
--[[
获取修正后的子弹父节点和zorder
@params bulletInfo ObjectSendBulletData 子弹物体构造信息
@return parentNode, zorder, fixedLocation cc.node, number, cc.p 父节点, zorder, 最终坐标
--]]
function BattleRenderManager:GetfixedBulletParentAndZOrder(bulletInfo)
	local parentNode, zorder, fixedLocation = nil, nil, nil

	if G_BattleLogicMgr:IsBulletAdd2ObjectView(bulletInfo) then

		--///mark
		local targetView = self:GetAObjectView(bulletInfo.targetViewModelTag)
		if nil ~= targetView then

			-- 修正父节点
			parentNode = targetView

			-- 修正zorder 加到物体身上 只存在顶部和底部
			zorder = bulletInfo.bulletZOrder < 0 and -1 or BATTLE_E_ZORDER.BULLET

			-- /***********************************************************************************************************************************\
			--  * 修正子弹的位置
			--  * 该类型逻辑层不关心特效的位置 在渲染层修正			
			-- \***********************************************************************************************************************************/
			local fixedPosInView = targetView.ConvertUnitPosToRealPos and targetView:ConvertUnitPosToRealPos(bulletInfo.fixedPos) or cc.p(0,0)
			fixedLocation = fixedPosInView

		end

	elseif ConfigEffectCauseType.SCREEN == bulletInfo.causeType then

		-- 全屏 加在战斗root上
		parentNode = self:GetBattleRoot()

	else

		-- 默认 battle root
		parentNode = self:GetBattleRoot()

	end

	return parentNode, zorder, fixedLocation
end
--[[
唤醒一个子弹渲染层模型
@params tag int 展示层的tag
--]]
function BattleRenderManager:AwakeABulletObjectView(tag)
	local view = self:GetAObjectView(tag)

	if nil ~= view then
		view:Awake()
	end
end
--[[
销毁一个子弹渲染层模型
@params tag int 展示层的tag
--]]
function BattleRenderManager:DestroyABulletObjectView(tag)
	local view = self:GetAObjectView(tag)

	if nil ~= view then
		if view.Die then view:Die() end

		-- 从缓存中移除
		self:RemoveAObjectView(tag)
	end
end
--[[
设置激光的部位
@params tag int view model tag
@params part sp.LaserAnimationName
--]]
function BattleRenderManager:SetLaserPart(tag, part)
	local view = self:GetAObjectView(tag)

	if nil ~= view then
		view:SetLaserPart(part)
	end
end
--[[
修正激光的长度
@params tag int view model tag
@params length number 激光束的长度
--]]
function BattleRenderManager:FixLaserBodyLength(tag, length)
	local view = self:GetAObjectView(tag)

	if nil ~= view and nil ~= view.FixLaserBodyLength then
		view:FixLaserBodyLength(length)
	end
end
---------------------------------------------------
-- bullet view end --
---------------------------------------------------

---------------------------------------------------
-- qte object view begin --
---------------------------------------------------
--[[
创建一个qte view
@params ownerTag int 拥有者tag
@params ownerViewModelTag int 展示层的模型
@params tag int qte obj tag
@params skillId int 对应的技能id
@params qteAttachObjectType QTEAttachObjectType qte层类型
--]]
function BattleRenderManager:CreateAAttachObjectView(ownerTag, ownerViewModelTag, tag, skillId, qteAttachObjectType)
	local viewClassName = 'battle.objectView.cardObject.BaseAttachObjectView'

	local view = __Require(viewClassName).new({
		ownerTag = ownerTag,
		tag = tag,
		skillId = skillId,
		qteAttachObjectType = qteAttachObjectType
	})
	self:AddAAttachObjectView(tag, view)

	local ownerView = self:GetAObjectView(ownerViewModelTag)
	if nil ~= ownerView then
		ownerView:AddAAttachView(view)
	end
end
--[[
刷新qte view 的状态
@params tag int qte obj tag
@params touchPace int 点击阶段
--]]
function BattleRenderManager:RefreshAAttachObjectViewState(tag, touchPace)
	local view = self:GetAAttachObjectView(tag)
	if nil ~= view then
		view:RefreshQTEViewByTouchPace(touchPace)
	end
end
--[[
销毁一个qte view
@params tag int qte obj tag
--]]
function BattleRenderManager:DestroyAAttachObjectView(tag)
	local view = self:GetAAttachObjectView(tag)
	if nil ~= view then
		view:Destroy()
	end

	-- 从内存中直接移除
	self:RemoveAAttachObjectView(tag)
end
---------------------------------------------------
-- qte object view end --
---------------------------------------------------

---------------------------------------------------
-- connect button begin --
---------------------------------------------------
--[[
根据阵容初始化一次连携技
@parmas teamMembers list
--]]
function BattleRenderManager:InitConnectButton(teamMembers)
	local obj = nil

	local x = 1
	local scale = 1

	-- 移除无效的连携技按钮
	local t = {}
	for otag_, btns in pairs(self.connectButtons) do
		local otag = checkint(otag_)
		for skillId, btn in pairs(btns) do
			obj = G_BattleLogicMgr:IsObjAliveByTag(otag)
			if nil == obj then

				-- 移除按钮
				btn:RemoveSelf()

				if nil ~= self.connectButtons[tostring(otag)] then
					self.connectButtons[tostring(otag)][tostring(skillId)] = nil
				end

			else

				table.insert(t, btn)

			end
		end
	end

	-- 排序
	table.sort(t, function (a, b)
		return a:getPositionX() > b:getPositionX()
	end)

	for i,v in ipairs(t) do
		local btnSize = cc.size(v:getContentSize().width * scale, v:getContentSize().height * scale)
		v:setPositionX(display.SAFE_R - 20 - (btnSize.width * 0.5) - (btnSize.width + 25) * (x - 1))

		local index = #self.connectButtonsIndex + 1
		self.connectButtonsIndex[index] = connectButton

		x = x + 1
	end

	-- 创建有效的连携技按钮
	for i = #teamMembers, 1, -1 do
		obj = teamMembers[i]
		tag = obj:GetOTag()
		local skinId = obj:GetObjectSkinId()

		local connectSkills = obj.castDriver:GetConnectSkills()
		if nil ~= connectSkills then
			for skillIndex, skillId in ipairs(connectSkills) do
				if nil == self:GetConnectButton(tag, skillId) then
					local connectButton = __Require('battle.view.ConnectButton').new({
						objTag = tag,
						cardHeadPath = CardUtils.GetCardHeadPathBySkinId(skinId),
						debugTxt = obj:GetObjectName(),
						skillId = checkint(skillId),
						callback = handler(self, self.ConnectSkillButtonClickHandler)
					})

					connectButton:setTag(skillIndex)

					local btnSize = cc.size(connectButton:getContentSize().width * scale, connectButton:getContentSize().height * scale)
					display.commonUIParams(connectButton, {
						po = cc.p(display.SAFE_R - 20 - (btnSize.width * 0.5) - (btnSize.width + 25) * (x - 1), 20 + btnSize.height * 0.5)})
					self:GetBattleScene().viewData.uiLayer:addChild(connectButton)

					-- 连携技按钮加入缓存
					if nil == self.connectButtons[tostring(tag)] then
						self.connectButtons[tostring(tag)] = {}
					end
					self.connectButtons[tostring(tag)][tostring(skillId)] = connectButton

					local index = #self.connectButtonsIndex + 1
					self.connectButtonsIndex[index] = connectButton

					x = x + 1
				end
			end
		end
	end
end
--[[
根据tag获取所有物体的连携技按钮
@params tag int obj tag
--]]
function BattleRenderManager:GetConnectButtonsByTag(tag)
	return self.connectButtons[tostring(tag)]
end
--[[
获取物体关联的连携技按钮
@params tag int obj tag
@params skillId int 技能id
--]]
function BattleRenderManager:GetConnectButton(tag, skillId)
	if nil ~= self.connectButtons[tostring(tag)] then
		return self.connectButtons[tostring(tag)][tostring(skillId)]
	end
	return nil
end
--[[
根据右向左的序号获取连携技按钮
@params index int 序号
@return _ ConnectButton 连携技按钮对象
--]]
function BattleRenderManager:GetConnectButtonByIndex(index)
	return self.connectButtonsIndex[index]
end
--[[
根据物体tag刷新连携技按钮的全状态
@params tag int obj tag
@params energyPercent number 能量百分比
@params canAct bool 是否可以行动
@params state OState 状态
@params inAbnormalState bool 是否处于无法释放连携技的状态
--]]
function BattleRenderManager:RefreshObjectConnectButtons(tag, energyPercent, canAct, state, inAbnormalState)
	local btns = self:GetConnectButtonsByTag(tag)

	if nil ~= btns then
		for skillId_, btn in pairs(btns) do
			btn:RefreshButton(energyPercent, canAct, state, inAbnormalState)
		end
	end
end
--[[
根据能量刷新物体连携技状态
@params tag int obj tag
@params energyPercent number 能量
--]]
function BattleRenderManager:RefreshObjectConnectButtonsByEnergy(tag, energyPercent)
	local btns = self:GetConnectButtonsByTag(tag)

	if nil ~= btns then
		for skillId_, btn in pairs(btns) do
			btn:RefreshButtonByEnergy(energyPercent)
		end
	end
end
--[[
根据状态刷新物体连携技状态
@params tag int obj tag
@params canAct bool 是否可以行动
@params state OState 状态
@params inAbnormalState bool 是否处于无法释放连携技的状态
--]]
function BattleRenderManager:RefreshObjectConnectButtonsByState(tag, canAct, state, inAbnormalState)
	local btns = self:GetConnectButtonsByTag(tag)

	if nil ~= btns then
		for skillId_, btn in pairs(btns) do
			btn:RefreshButtonByState(canAct, state, inAbnormalState)
		end
	end
end
--[[
点亮熄灭连携技按钮
@params tag int obj tag
@params skillId int 连携技id
@params enable bool 是否可用
--]]
function BattleRenderManager:EnableConnectSkillButton(tag, skillId, enable)
	local connectButton = self:GetConnectButton(tag, skillId)
	if nil ~= connectButton then

		connectButton:SetCanUse(enable)

		if false == enable then
			connectButton:DisableConnectButton()
		end

	end
end
---------------------------------------------------
-- connect button end --
---------------------------------------------------

---------------------------------------------------
-- scene view begin --
---------------------------------------------------
--[[
显示伤害数字
@params damageData ObjectDamageStruct 伤害信息
@params battleRootPos cc.p
@params towards bool 朝向 是否向右
@params inHighlight bool 是否高亮显示
--]]
function BattleRenderManager:ShowDamageNumber(damageData, battleRootPos, towards, inHighlight)
	if not self:HasBattleRoot() then return end
	
	-- 伤害数字 分三种 暴击 治疗 普通
	local colorPath = 'white'
	local fontSize = 50
	local actionSeq = nil
	local fps = 30
	local parentNode = self:GetBattleRoot()
	local pos = battleRootPos
	local sign = towards and -1 or 1

	local zorder = BATTLE_E_ZORDER.DAMAGE_NUMBER
	if true == inHighlight then
		zorder = zorder + G_BattleLogicMgr:GetFixedHighlightZOrder()
	end

	if nil ~= damageData.healerTag then

		if true == damageData.isCritical then
			fontSize = 80
		end

		-- 治疗数值
		colorPath = 'green'

		-- 为治疗错开一定的横坐标
		pos.x = pos.x + math.random(-35, 35)

		local deltaP1 = cc.p(0, 50 + math.random(40))
		local actionP1 = cc.pAdd(pos, deltaP1)
		local actionP2 = cc.pAdd(actionP1, cc.p(0, deltaP1.y * 0.5))

		actionSeq = cc.Sequence:create(
			cc.EaseSineIn:create(
				cc.Spawn:create(
					cc.ScaleTo:create(9 / fps, 1),
					cc.MoveTo:create(9 / fps, actionP1))
			),
			cc.Spawn:create(
				cc.Sequence:create(
					cc.MoveTo:create(19 / fps, actionP2),
					cc.MoveTo:create(11 / fps, pos)),
				cc.Sequence:create(
					cc.DelayTime:create(13 / fps),
					cc.ScaleTo:create(17 / fps, 0)),
				cc.Sequence:create(
					cc.DelayTime:create(19 / fps),
					cc.FadeTo:create(11 / fps, 0))
			),
			cc.RemoveSelf:create()
		)

	elseif true == damageData.isCritical then

		-- 暴击数值
		colorPath = 'orange'
		fontSize = 70
		local deltaP1 = cc.p(60 + math.random(40), 60 + math.random(40))
		local actionP1 = cc.p(pos.x + sign * deltaP1.x, pos.y + deltaP1.y)
		local actionP2 = cc.p(pos.x + sign * deltaP1.x * 2, pos.y + deltaP1.y * 0.25)
		local bezierConf2 = {
			actionP1,
			cc.p(actionP1.x + sign * deltaP1.x * 0.5, actionP1.y + deltaP1.y * 0.25),
			actionP2
		}

		actionSeq = cc.Sequence:create(
			cc.EaseSineOut:create(cc.Spawn:create(
				cc.ScaleTo:create(6 / fps, 1),
				cc.MoveTo:create(6 / fps, actionP1))
			),
			cc.Spawn:create(
				cc.BezierTo:create(33 / fps, bezierConf2),
				cc.Sequence:create(
					cc.DelayTime:create(22 / fps),
					cc.Spawn:create(
						cc.ScaleTo:create(11 / fps, 0),
						cc.FadeTo:create(11 / fps, 0)
					)
				)
			),
			cc.RemoveSelf:create()
		)

	else

		-- 普通伤害数值
		local deltaP1 = cc.p(15 + math.random(30), 15 + math.random(30))
		local actionP1 = cc.p(pos.x + sign * deltaP1.x, pos.y + deltaP1.y)
		local actionP2 = cc.p(pos.x + sign * deltaP1.x * 2, pos.y)
		local bezierConf2 = {
			actionP1,
			cc.p(actionP1.x + sign * deltaP1.x, actionP1.y + deltaP1.y),
			actionP2
		}

		actionSeq = cc.Sequence:create(
			cc.Spawn:create(
				cc.ScaleTo:create(5 / fps, 1),
				cc.MoveTo:create(5 / fps, actionP1)),
			-- cc.EaseOut:create(cc.Spawn:create(
			-- 	cc.ScaleTo:create(5 / fps, 1),
			-- 	cc.MoveTo:create(5 / fps, actionP1)),
			-- 	1
			-- ),
			cc.Spawn:create(
				cc.BezierTo:create(34 / fps, bezierConf2),
				cc.Sequence:create(
					cc.DelayTime:create(22 / fps),
					cc.Spawn:create(
						cc.ScaleTo:create(12 / fps, 0),
						cc.FadeTo:create(12 / fps, 0)
					)
				)
			),
			cc.RemoveSelf:create()
		)

	end

	local damageLabel = CLabelBMFont:create(
		string.format('%d', math.ceil(damageData:GetDamageValue())),
		string.format('font/battle_font_%s.fnt', colorPath))
	damageLabel:setBMFontSize(fontSize)
	damageLabel:setAnchorPoint(cc.p(0.5, 0.5))
	damageLabel:setPosition(pos)
	parentNode:addChild(damageLabel, zorder)

	-- 初始化动画状态
	damageLabel:setScale(0)
	if actionSeq then
		damageLabel:runAction(actionSeq)
	end

end
--[[
添加一个花钻购买的buff图标
@params skillId int 技能id
--]]
function BattleRenderManager:AddASpecialSkillIcon(skillId)
	self:GetBattleScene():AddAGlobalEffect(skillId)
end
---------------------------------------------------
-- scene view end --
---------------------------------------------------

---------------------------------------------------
-- wave info begin --
---------------------------------------------------
--[[
刷新时间
@params leftTime int 剩余秒数
--]]
function BattleRenderManager:RefreshTimeLabel(leftTime, a, b)
	local m = math.floor(leftTime / 60)
	local s = math.floor(leftTime - m * 60)
	if self:GetBattleScene().viewData and self:GetBattleScene().viewData.battleTimeLabel then
		self:GetBattleScene().viewData.battleTimeLabel:setString(string.format('%d:%02d', m, s))
	end
end
--[[
刷新波数
@params currentWave int 当前波数
@params totalWave int 总波数
--]]
function BattleRenderManager:RefreshWaveInfo(currentWave, totalWave)
	local waveLabel = self:GetBattleScene().viewData.waveLabel
	local waveIcon = self:GetBattleScene().viewData.waveIcon

	-- 刷新波数文字
	waveLabel:setString(string.format('%d/%d', currentWave, totalWave))

	-- 刷新波数icon
	display.commonUIParams(waveIcon, {po = cc.p(
		waveLabel:getPositionX() - waveLabel:getContentSize().width,
		waveLabel:getPositionY() + 4
	)})
end
--[[
根据过关条件数据刷新过关条件展示
@params stageCompleteInfo StageCompleteSturct 过关配置信息
--]]
function BattleRenderManager:RefreshWaveClearInfo(stageCompleteInfo)
	local waveClearDescr = self:GetStageCompleteDescrByInfo(stageCompleteInfo)
	self:GetBattleScene():RefreshBattleClearTargetDescr(waveClearDescr)

	if ConfigStageCompleteType.ALIVE == stageCompleteInfo.completeType then
		self:GetBattleScene():InitAliveStageClear(stageCompleteInfo.aliveTime)
	else

	end
	-- 隐藏一些不需要的ui
	self:GetBattleScene():HideStageClearByStageCompleteType(stageCompleteInfo.completeType)
end
--[[
根据过关配置信息获取过关描述
@params stageCompleteInfo StageCompleteSturct 过关配置信息
@return str string 过关描述
--]]
function BattleRenderManager:GetStageCompleteDescrByInfo(stageCompleteInfo)
	local passType = stageCompleteInfo.completeType
	local passConfig = CommonUtils.GetConfig('quest', 'passType', tostring(passType))

	if nil ~= passConfig then
		return tostring(passConfig.descr)
	else
		return '未能找到过关条件描述配置'
	end
end
--[[
刷新当前车轮战两侧标记
@params friendTeamIndex int 友军队伍idx
@params enemyTeamIndex int 敌军队伍idx
--]]
function BattleRenderManager:RefreshTagMatchTeamStatus(friendTeamIndex, enemyTeamIndex)
	if self:IsTagMatchBattle() then
		self:GetBattleScene():RefreshTagMatchTeamStatus(friendTeamIndex, enemyTeamIndex)
	end
end
--[[
刷新存活模式的倒计时
@params countdown number 倒计时
--]]
function BattleRenderManager:RefreshAliveCountdown(countdown)
	self:GetBattleScene():RefreshAliveCountdown(countdown)
end
---------------------------------------------------
-- wave info end --
---------------------------------------------------

---------------------------------------------------
-- add layer begin --
---------------------------------------------------
--[[
换波场景
@params needReloadResources bool 是否需要重新加载资源
@params nextWave int 下一波的波数
@params friendTeamIndex int 友军队伍序号
@params enemyTeamIndex int 敌军队伍序号
@params isFriendWin ValueConstants 是否是友军胜利
@params aliveTargetsInfo list<{objectSkinId = nil}> 存活的obj信息
@params deadTargetsInfo list<{objectSkinId = nil}> 死亡的obj信息
--]]
function BattleRenderManager:ShowWaveTransition(needReloadResources, nextWave, friendTeamIndex, enemyTeamIndex, isFriendWin, aliveTargetsInfo, deadTargetsInfo)
	-- 屏蔽触摸
	self:SetBattleTouchEnable(false)

	local changeBegin = function ()
		-- 刷一次资源
		if true == needReloadResources then
			self:GetBattleDriver(BattleDriverType.RES_LOADER):OnLogicEnter(
				nextWave, friendTeamIndex, enemyTeamIndex, isFriendWin,
				aliveTargetsInfo, deadTargetsInfo
			)
		end

		--###---------- 刷新逻辑层 ----------###--
		-- 回传逻辑层 切波黑屏完毕 准备刷新场景
		self:AddPlayerOperate(
			'G_BattleLogicMgr',
			'RenderWaveTransitionStartHandler'
		)
		--###---------- 刷新逻辑层 ----------###--
	end

	local changeEnd = function ()
		--###---------- 刷新逻辑层 ----------###--
		-- 回传逻辑层 切波黑屏完毕 准备刷新场景
		self:AddPlayerOperate(
			'G_BattleLogicMgr',
			'RenderWaveTransitionOverHandler'
		)
		--###---------- 刷新逻辑层 ----------###--
	end

	local scene = __Require('battle.miniGame.WaveTransitionScene').new({
		callbacks = {
			changeBegin = changeBegin,
			changeEnd = changeEnd
		}
	})
	scene:setTag(WAVE_TRANSITION_SCENE_TAG)
	self:GetBattleScene():addChild(scene, BATTLE_E_ZORDER.CI)
	return scene
end
--[[
继续切波场景
--]]
function BattleRenderManager:ContinueWaveTransition()
	local scene = self:GetBattleScene():getChildByTag(WAVE_TRANSITION_SCENE_TAG)
	if nil ~= scene then
		scene:ContinueWaveTransition()
	end
end
--[[
显示连携技场景
@params tag int obj tag
@params sceneTag int 场景tag
@params cardId int 卡牌id
@params skinId int 皮肤id
@params otherHeadSkinId list 其他卡牌头像路径
@params skillId int 技能id
@params isEnemy bool 是否是敌人
@params startFrame int 起始帧
@params durationFrame int 帧时长
--]]
function BattleRenderManager:ShowConnectSkillCIScene(tag, sceneTag, cardId, skinId, otherHeadSkinId, skillId, isEnemy, startFrame, durationFrame)
	-- 屏蔽触摸
	self:SetBattleTouchEnable(false)

	local params = {
		ownerTag        = tag,
		tag             = sceneTag,
		mainSkinId      = skinId,
		otherHeadSkinId = otherHeadSkinId,
		isEnemy         = isEnemy,
		startFrame      = startFrame,
		durationFrame   = durationFrame,
		startCB         = function()
			-- 卡牌连携技 出现语音
			self:PlayCardSound(cardId, SoundType.TYPE_SKILL2)
		end,
		overCB = function ()
			if not self:IsCalculator() then
				--###---------- 刷新逻辑层 ----------###--
				-- 恢复游戏逻辑
				self:AddPlayerOperate(
					'G_BattleLogicMgr',
					'ConnectCISceneExit',
					tag, skillId, sceneTag
				)
				--###---------- 刷新逻辑层 ----------###--
			end

			-- 恢复触摸
			self:SetBattleTouchEnable(true)

			print('over connect skill ci', tag, skinId, skillId, sceneTag, G_BattleLogicMgr:GetBData():GetLogicFrameIndex())
			print('=======================================>>>>>>>>\n\n')
		end,
		dieCB = function ()
			self:SetCISceneBySceneTag(sceneTag, true, nil)
		end
	}

	local scene = __Require('battle.miniGame.CutinScene').new(params)
	self:GetBattleScene():addChild(scene, BATTLE_E_ZORDER.CI)
	self:SetCISceneBySceneTag(sceneTag, true, scene)

	--###---------- 刷新逻辑层 ----------###--
	-- 暂停正常逻辑
	self:AddPlayerOperate(
		'G_BattleLogicMgr',
		'ConnectCISceneEnter',
		tag, skillId, sceneTag
	)
	--###---------- 刷新逻辑层 ----------###--
	print('\n\n=======================================>>>>>>>>')
	print('start connect skill ci', tag, skinId, skillId, sceneTag, G_BattleLogicMgr:GetBData():GetLogicFrameIndex())
end
--[[
显示弱点场景
@params tag int obj tag
@params sceneTag int 场景tag
@params skillId int 技能id
@params weakPoints table 弱点信息
@params time number chant time
--]]
function BattleRenderManager:ShowWeakSkillScene(tag, viewModelTag, sceneTag, skillId, weakPoints, time)
	local params = {
		ownerTag = tag,
		ownerViewModelTag = viewModelTag,
		tag = sceneTag,
		skillId = skillId,
		weakPoints = weakPoints,
		time = time,
		touchWeakPointCB = handler(self, self.WeakSkillPointClickHandler),
		overCB = function (result)
			--###---------- 刷新逻辑层 ----------###--
			-- 恢复游戏逻辑
			self:AddPlayerOperate(
				'G_BattleLogicMgr',
				'RenderWeakChantOverHandler',
				tag, skillId, result
			)
			--###---------- 刷新逻辑层 ----------###--
		end,
		dieCB = function (result)
			self:SetCISceneBySceneTag(sceneTag, false, nil)
		end
	}

	local scene = __Require('battle.miniGame.BossWeakScene').new(params)
	self:GetBattleScene():addChild(scene, BATTLE_E_ZORDER.CI)
	self:SetCISceneBySceneTag(sceneTag, false, scene)
end
--[[
让指定的弱点场景中指定的弱点节点被戳爆
@params sceneTag int 弱点场景tag
@params touchedPointId int 点击的弱点
--]]
function BattleRenderManager:WeakPointBomb(sceneTag, touchedPointId)
	local scene = self:GetCISceneBySceneTag(sceneTag, false)
	if nil ~= scene then
		scene:WeakPointBomb(touchedPointId)
	end
end
--[[
显示boss ci场景
@params tag int obj tag
@params sceneTag int 场景tag
@params skillId int 施法的技能id
@params mainSkinId int boss皮肤
--]]
function BattleRenderManager:ShowBossCIScene(tag, sceneTag, skillId, mainSkinId)
	-- 屏蔽触摸
	self:SetBattleTouchEnable(false)

	local params = {
		ownerTag = tag,
		tag = sceneTag,
		mainSkinId = mainSkinId,
		startCB = function ()

		end,
		overCB = function ()
			--###---------- 刷新逻辑层 ----------###--
			-- 恢复游戏逻辑
			self:AddPlayerOperate(
				'G_BattleLogicMgr',
				'BossCISceneExit',
				tag, skillId, sceneTag
			)
			--###---------- 刷新逻辑层 ----------###--

			-- 恢复触摸
			self:SetBattleTouchEnable(true)
		end,
		dieCB = function ()
			self:SetCISceneBySceneTag(sceneTag, true, nil)
		end
	}

	local scene = __Require('battle.miniGame.BossCutinScene').new(params)
	self:GetBattleScene():addChild(scene, BATTLE_E_ZORDER.CI)
	self:SetCISceneBySceneTag(sceneTag, true, scene)

	--###---------- 刷新逻辑层 ----------###--
	-- 暂停正常逻辑
	self:AddPlayerOperate(
		'G_BattleLogicMgr',
		'BossCISceneEnter',
		tag, skillId, sceneTag
	)
	--###---------- 刷新逻辑层 ----------###--
end
--[[
根据obj tag移除当前对应的scene
@params tag int obj tag
--]]
function BattleRenderManager:KillObjectCISceneByTag(tag)
	for sceneTag_, scene in pairs(self.ciScenes.normal) do
		if tag == scene:GetOwnerTag() then
			scene:die()
		end
	end

	for sceneTag_, scene in pairs(self.ciScenes.pause) do
		if tag == scene:GetOwnerTag() then
			scene:die()
		end
	end
end
---------------------------------------------------
-- add layer end --
---------------------------------------------------

---------------------------------------------------
-- pause game begin --
---------------------------------------------------
--[[
显示暂停场景
--]]
function BattleRenderManager:PauseGame()
	-- 屏蔽触摸
	self:SetBattleTouchEnable(false)

	-- 暂停渲染层逻辑
	self:PauseRenderElements()

	-- 显示暂停界面
	local scene = __Require('battle.miniGame.PauseScene').new()
	self:GetBattleScene():addChild(scene, BATTLE_E_ZORDER.PAUSE)
	scene:setTag(PAUSE_SCENE_TAG)

	-- 初始化按钮回调
	if nil ~= scene.viewData and nil ~= scene.viewData.actionButtons then
		for _, button in ipairs(scene.viewData.actionButtons) do
			display.commonUIParams(button, {cb = handler(self, self.ButtonsClickHandler)})
		end
	end
end
--[[
移除暂停场景
--]]
function BattleRenderManager:ResumeGame()
	-- 屏蔽触摸
	self:SetBattleTouchEnable(true)

	-- 恢复渲染层逻辑
	self:ResumeRenderElements()

	-- 移除暂停界面
	local scene = self:GetBattleScene():getChildByTag(PAUSE_SCENE_TAG)
	if nil ~= scene then
		scene:setVisible(false)
		scene:die()
	end
end
--[[
暂停渲染层的逻辑
--]]
function BattleRenderManager:PauseRenderElements()
	self:PauseBattleScene()
	self:PauseCIScene()
	self:PauseNormalScene()
	self:PauseOther()
end
--[[
恢复渲染层的逻辑
--]]
function BattleRenderManager:ResumeRenderElements()
	self:ResumeBattleScene()
	self:ResumeCIScene()
	self:ResumeNormalScene()
	self:ResumeOther()
end
--[[
暂停战斗场景
--]]
function BattleRenderManager:PauseBattleScene()
	-- 暂停战斗场景
	self:GetBattleScene():PauseScene()
end
--[[
恢复战斗场景
--]]
function BattleRenderManager:ResumeBattleScene()
	-- 恢复战斗场景
	self:GetBattleScene():ResumeScene()
end
--[[
暂停ci场景
--]]
function BattleRenderManager:PauseCIScene()
	-- 暂停ci场景
	for _, node in pairs(self.ciScenes.pause) do
		node:pauseObj()
		cc.Director:getInstance():getActionManager():pauseTarget(node)
		table.insert(self.pauseActions.pauseScene, node)
	end
end
--[[
恢复ci场景
--]]
function BattleRenderManager:ResumeCIScene()
	for _, node in pairs(self.ciScenes.pause) do
		node:resumeObj()
		cc.Director:getInstance():getActionManager():resumeTarget(node)
	end
	self.pauseActions.pauseScene = {}
end
--[[
暂停普通场景
--]]
function BattleRenderManager:PauseNormalScene()
	for _, node in pairs(self.ciScenes.normal) do
		node:pauseObj()
		cc.Director:getInstance():getActionManager():pauseTarget(node)
		table.insert(self.pauseActions.normalScene, node)
	end
end
--[[
恢复普通场景
--]]
function BattleRenderManager:ResumeNormalScene()
	for _, node in pairs(self.ciScenes.normal) do
		node:resumeObj()
		cc.Director:getInstance():getActionManager():pauseTarget(node)
	end
	self.pauseActions.normalScene = {}
end
--[[
暂停其他战斗场景元素
--]]
function BattleRenderManager:PauseOther()
	------------ 暂停所有cocos2dx action ------------
	table.insert(self.pauseActions.battle, cc.Director:getInstance():getActionManager():pauseAllRunningActions())
	------------ 暂停所有cocos2dx action ------------

	-- 恢复cocos场景的action
	cc.Director:getInstance():getActionManager():resumeTarget(cc.CSceneManager:getInstance():getRunningScene())
end
--[[
恢复其他战斗场景元素
--]]
function BattleRenderManager:ResumeOther()
	for i,v in ipairs(self.pauseActions.battle) do
		cc.Director:getInstance():getActionManager():resumeTargets(v)
	end
	self.pauseActions.battle = {}
end
--[[
使一个obj view完全暂停
@params tag int 展示层的tag
@params timeScale number 动画速度缩放
--]]
function BattleRenderManager:PauseAObjectView(tag, timeScale)
	-- 设置avatar的timeScale
	self:ObjectViewSetAnimationTimeScale(tag, timeScale)

	local view = self:GetAObjectView(tag)
	if nil ~= view then
		view:PauseView()
	end
end
--[[
恢复一个obj view
@params tag int 展示层的tag
@params timeScale number 动画速度缩放
--]]
function BattleRenderManager:ResumeAObjectView(tag, timeScale)
	-- 设置avatar的timeScale
	self:ObjectViewSetAnimationTimeScale(tag, timeScale)

	local view = self:GetAObjectView(tag)
	if nil ~= view then
		view:ResumeView()
	end
end
--[[
ci 场景开始自己并暂停其他一切action
@params sceneTag int 场景tag
--]]
function BattleRenderManager:PauseCISceneStart(sceneTag)
	-- 暂停掉其他动画
	self:PauseOther()

	if nil ~= sceneTag then
		local scene = self:GetCISceneBySceneTag(sceneTag, true)
		if nil ~= scene then
			scene:start()
		end
	end
end
--[[
ci 场景结束并恢复其他action
@params sceneTag int 场景tag
--]]
function BattleRenderManager:PauseCISceneOver(sceneTag)
	-- 恢复掉其他动画
	self:ResumeOther()
end
---------------------------------------------------
-- pause game end --
---------------------------------------------------

---------------------------------------------------
-- battle module begin --
---------------------------------------------------
--[[
初始化战斗模块相关的界面
--]]
function BattleRenderManager:InitBattleModule()
	-- 初始化一些额外的ui信息
	self:InitBattleUIInfo()
	-- 初始化功能模块的显示和隐藏
	self:InitFunctionModule()
end
--[[
初始化一些额外的ui
--]]
function BattleRenderManager:InitBattleUIInfo()
	------------ 车轮战ui ------------
	if self:IsTagMatchBattle() then
		self:GetBattleScene():InitTagMatchView(
			self:GetBattleMembers(false),
			self:GetBattleMembers(true)
		)
	end
	------------ 车轮战ui ------------
end
--[[
初始化功能模块的显示和隐藏
--]]
function BattleRenderManager:InitFunctionModule()
	local initByGuide = self:InitFunctionModuleByGuide()
	if initByGuide then return end

	local questBattleType = self:GetQuestBattleType()
	if self:IsCardVSCard() then

		-- 隐藏主角技 波数
		self:GetBattleScene():ShowBattleFunctionModule(ConfigBattleFunctionModuleType.PLAYER_SKILL, false)
		self:GetBattleScene():ShowBattleFunctionModule(ConfigBattleFunctionModuleType.WAVE, false)

		-- 回放模式 隐藏连携技
		if self:IsReplay() then
			self:GetBattleScene():ShowBattleFunctionModule(ConfigBattleFunctionModuleType.CONNECT_SKILL, false)
		end

	elseif QuestBattleType.PERFORMANCE == questBattleType then

		-- 隐藏所有模块
		self:GetBattleScene():HideAllBattleFunctionModule()

	elseif QuestBattleType.RAID == questBattleType then

		-- 隐藏所有功能模块
		self:GetBattleScene():ShowBattleFunctionModule(ConfigBattleFunctionModuleType.WAVE, false)
		self:GetBattleScene():ShowBattleFunctionModule(ConfigBattleFunctionModuleType.PLAYER_SKILL, false)
		self:GetBattleScene():ShowBattleFunctionModule(ConfigBattleFunctionModuleType.ACCELERATE_GAME, false)
		self:GetBattleScene():ShowBattleFunctionModule(ConfigBattleFunctionModuleType.PAUSE_GAME, false)

	elseif self:IsShareBoss() then

		-- 世界boss模式隐藏主角技和过关目标
		self:GetBattleScene():ShowBattleFunctionModule(ConfigBattleFunctionModuleType.PLAYER_SKILL, false)
		self:GetBattleScene():ShowBattleFunctionModule(ConfigBattleFunctionModuleType.STAGE_CLEAR_TARGET, false)

	end

	-- 根据配表信息隐藏功能模块信息
	local hideBattleFunctionModule = self:GetBattleConstructData().hideBattleFunctionModule
	if nil ~= hideBattleFunctionModule then
		for _, moduleType in ipairs(hideBattleFunctionModule) do
			self:GetBattleScene():ShowBattleFunctionModule(checkint(moduleType), false)
		end
	end
end
--[[
是否是由引导的逻辑初始化模块
@return _ bool 是否是由引导的逻辑初始化
--]]
function BattleRenderManager:InitFunctionModuleByGuide()
	local guideConfig = self:GetBattleGuideConfigByStageId()
	if nil == guideConfig then return false end

	for _, moduleType in ipairs(guideConfig.hiddenFunction) do
		self:GetBattleScene():ShowBattleFunctionModule(checkint(moduleType), false)
	end

	return true
end
---------------------------------------------------
-- battle module end --
---------------------------------------------------

---------------------------------------------------
-- player object view begin --
---------------------------------------------------
--[[
创建一个主角的渲染层模型
@params viewModelTag int 展示层tag
@params activeSkill list 技能列表
@params tag int obj tag
--]]
function BattleRenderManager:CreateAPlayerObjectView(viewModelTag, activeSkill, tag)
	local viewInfo = {tag = viewModelTag, logicTag = tag}
	-- 初始化友方主角的主角技模块
	local friendPlayerObjectView = __Require('battle.objectView.cardObject.PlayerObjectView').new(viewInfo)
	self:AddAPlayerObjectView(viewModelTag, friendPlayerObjectView)

	-- 初始化一次技能信息
	self:InitPlayerObjectSkills(viewModelTag, activeSkill)
end
--[[
根据技能信息初始化主角渲染
@params viewModelTag int 展示层tag
@params activeSkill list 技能
--]]
function BattleRenderManager:InitPlayerObjectSkills(viewModelTag, activeSkill)
	local playerView = self:GetAPlayerObjectView(viewModelTag)

	if nil ~= playerView then
		local skillId = nil
		for skillIndex, skillInfo in ipairs(activeSkill) do
			skillId = checkint(skillInfo.skillId)
			playerView:AddAPlayerSkillIcon(skillIndex, skillId, handler(self, self.PlayerSkillHandler))
		end
	end
end
--[[
添加一个主角物体渲染
@params viewModelTag int 展示层tag
@params view PlayerObjectView
--]]
function BattleRenderManager:AddAPlayerObjectView(viewModelTag, view)
	self.playerViews[tostring(viewModelTag)] = view
end
--[[
移除一个主角物体渲染
@params viewModelTag int 展示层tag
--]]
function BattleRenderManager:RemoveAPlayerObjectView(viewModelTag)
	self.playerViews[tostring(viewModelTag)] = nil
end
--[[
获取一个主角物体渲染
@params viewModelTag int 展示层tag
--]]
function BattleRenderManager:GetAPlayerObjectView(viewModelTag)
	return self.playerViews[tostring(viewModelTag)]
end
--[[
显示主角技模块
@params show bool 是否显示
--]]
function BattleRenderManager:ShowPlayerObjectView(show)
	for _, view in pairs(self.playerViews) do
		view:SetVisible(show)
	end
end
--[[
显示连携技模块
@params show bool 是否显示
--]]
function BattleRenderManager:ShowConnectObjectView(show)
	for tag, skillButtons in pairs(self.connectButtons) do
		for skillId, connectButton in pairs(skillButtons) do
			connectButton:setVisible(show)
		end
	end
end
--[[
刷新一个主角技按钮的cd百分比
@params viewModelTag int 展示层tag
@params skillId int 技能id
@params cdPercent number 冷却时间百分比
--]]
function BattleRenderManager:RefreshPlayerSkillCDPercent(viewModelTag, skillId, cdPercent)
	local view = self:GetAPlayerObjectView(viewModelTag)
	if nil ~= view then
		view:RefreshPlayerSkillByCDPercent(skillId, cdPercent)
	end
end
--[[
刷新一个主角技按钮的施法状态
@params viewModelTag int 展示层tag
@params skillId int 技能id
@params canCast bool 是否可以释放
--]]
function BattleRenderManager:RefreshPlayerSkillState(viewModelTag, skillId, canCast)
	local view = self:GetAPlayerObjectView(viewModelTag)
	if nil ~= view then
		view:RefreshPlayerSkillByState(skillId, canCast)
	end
end
--[[
刷新主角技能量条
@params viewModelTag int 展示层tag
@params energyPercent number
--]]
function BattleRenderManager:SetPlayerObjectViewEnergyPercent(viewModelTag, energyPercent)
	local view = self:GetAPlayerObjectView(viewModelTag)
	if nil ~= view then
		view:UpdateEnergyBar(energyPercent)
	end
end
--[[
显示释放主角技遮罩
--]]
function BattleRenderManager:ShowCastPlayerSkillCover()
	local waringBg = display.newNSprite(_res('ui/battle/battle_bg_warning.png'), display.width * 0.5, display.height * 0.5)
	waringBg:setColor(cc.c3b(0, 0, 0))
	local waringBgSize = waringBg:getContentSize()
	waringBg:setScaleX(display.width / waringBgSize.width)
	waringBg:setScaleY(display.height / waringBgSize.height)
	self:GetBattleScene().viewData.uiLayer:addChild(waringBg)
	waringBg:setOpacity(0)
	local waringActionSeq = cc.Sequence:create(
		cc.FadeTo:create(0.5, 255),
		cc.DelayTime:create(2.5),
		cc.FadeTo:create(0.5, 0),
		cc.RemoveSelf:create()
	)
	waringBg:runAction(waringActionSeq)
end
---------------------------------------------------
-- player object view end --
---------------------------------------------------

---------------------------------------------------
-- battle performance begin --
---------------------------------------------------
--[[
抖屏幕
@params callback function 动作结束后的回调函数
@return duration number 执行动作的时间长短
--]]
function BattleRenderManager:ShakeWorld(callback)
	self:GetBattleScene():ShakeWorld(callback)
end
--[[
阶段转换 ConfigPhaseType.TALK_DEFORM 喊话变身
@params deformSourceViewModelTag int 变身源的展示层tag
@params deformSourceTag int 变身源的tag
@params deformTargetViewModelTag int 变身目标的展示层tag
@params deformTargetTag int 变身目标的tag
@params dialogueFrameType int 对话框气泡类型
@params content string 对话内容
--]]
function BattleRenderManager:PhaseChangeSpeakAndDeform(deformSourceViewModelTag, deformSourceTag, deformTargetViewModelTag, deformTargetTag, dialogueFrameType, content)
	self:ShakeWorld(function ()
		local view = self:GetAObjectView(deformSourceViewModelTag)
		if nil ~= view then
			view:StartSpeakAndDeform(dialogueFrameType, content, deformTargetViewModelTag, function ()
				--###---------- 玩家手操记录 ----------###--
				self:AddPlayerOperate(
					'G_BattleLogicMgr',
					'RenderPhaseChangeSpeakAndDeformOverHandler',
					deformTargetTag
				)
				--###---------- 玩家手操记录 ----------###--
			end)
		end
	end)
end
--[[
阶段转换 ConfigPhaseType.TALK_ESCAPE 喊话逃跑 p1 喊话
@params viewModelTag int 逃跑物体展示层tag
@params tag int 逃跑物体的逻辑层tag
@params dialogueFrameType int 对话框气泡类型
@params content string 对话内容
--]]
function BattleRenderManager:PhaseChangeSpeakAndEscape(viewModelTag, tag, dialogueFrameType, content)
	local view = self:GetAObjectView(viewModelTag)
	if nil ~= view then
		view:StartSpeakBeforeEscape(dialogueFrameType, content, function ()
			--###---------- 玩家手操记录 ----------###--
			self:AddPlayerOperate(
				'G_BattleLogicMgr',
				'RenderPhaseChangeSpeakOverStartEscapeHandler',
				tag
			)
			--###---------- 玩家手操记录 ----------###--
		end)
	end
end
--[[
阶段转换 ConfigPhaseType.TALK_ESCAPE 喊话逃跑 p2 逃跑
@params viewModelTag int 逃跑物体展示层tag
@params tag int 逃跑物体的逻辑层tag
@params targetPos cc.p 目标点坐标
@params walkSpeed number 行走速度
--]]
function BattleRenderManager:PhaseChangeEscape(viewModelTag, tag, targetPos, walkSpeed)
	local view = self:GetAObjectView(viewModelTag)
	if nil ~= view then
		view:StartEscape(targetPos, walkSpeed, function ()
			--###---------- 玩家手操记录 ----------###--
			self:AddPlayerOperate(
				'G_BattleLogicMgr',
				'RenderPhaseChangeEscapeOverHandler',
				tag
			)
			--###---------- 玩家手操记录 ----------###--
		end)
	end
end
--[[
阶段转换 ConfigPhaseType.TALK_ESCAPE 喊话逃跑 p3 逃跑结束 消失
@params viewModelTag int 逃跑物体展示层tag
--]]
function BattleRenderManager:PhaseChangeEscapeOverAndDisappear(viewModelTag)
	local view = self:GetAObjectView(viewModelTag)
	if nil ~= view then
		view:OverEscape()
	end
end
--[[
阶段转换 ConfigPhaseType.TALK_ESCAPE 喊话逃跑 p4 逃跑后重返战场
@params viewModelTag int 逃跑物体展示层tag
--]]
function BattleRenderManager:PhaseChangeEscapeBack(viewModelTag)
	local view = self:GetAObjectView(viewModelTag)
	if nil ~= view then
		view:EscapeBack()
	end
end
--[[
阶段转换 ConfigPhaseType.DEFORM_CUSTOMIZE 定制化变身
@params deformSourceViewModelTag int 变身源的展示层tag
@params deformSourceTag int 变身源的tag
@params deformSourceActionName string 变身源的动作名称
@params delayTime number 登场的延迟时间
@params deformTargetViewModelTag int 变身目标的展示层tag
@params deformTargetTag int 变身目标的tag
@params deformTargetActionName string 变身源的动作名称
--]]
function BattleRenderManager:PhaseChangeDeformCustomize(deformSourceViewModelTag, deformSourceTag, deformSourceActionName, delayTime, deformTargetViewModelTag, deformTargetTag, deformTargetActionName)
	local deformSourceView = self:GetAObjectView(deformSourceViewModelTag)
	if nil ~= deformSourceView then

		deformSourceView:DeformCustomizeDisappear(deformSourceActionName, delayTime, nil)

		-- 计算动画时间
		local deformSourceActionData = deformSourceView:GetSpineAnimationDataByAnimationName(deformSourceActionName)
		if nil ~= deformSourceActionData then
			delayTime = delayTime + deformSourceActionData.duration
		end

	end

	local deformTargetView = self:GetAObjectView(deformTargetViewModelTag)
	if nil ~= deformTargetView then

		deformTargetView:DeformCustomizeAppear(deformSourceActionName, delayTime, function ()

			--###---------- 玩家手操记录 ----------###--
			self:AddPlayerOperate(
				'G_BattleLogicMgr',
				'RenderPhaseChangeDeformCustomizeOverHandler',
				deformSourceTag, deformTargetTag
			)
			--###---------- 玩家手操记录 ----------###--

		end)

	end
end
--[[
阶段转换 ConfigPhaseType.PLOT 暂停游戏 主线剧情
@params plotId int 剧情id
@params path string 对白配表路径
@params guide bool 是否是引导
--]]
function BattleRenderManager:PhaseChangeShowPlotStage(plotId, path, guide)
	local currentRenderTimeScale = G_BattleMgr:GetRenderTimeScale()
	------------ 强制一倍速 ------------
	G_BattleMgr:SetRenderTimeScale(1)
	------------ 强制一倍速 ------------

	local plotStage = require('Frame.Opera.OperaStage').new({
		id = plotId,
		path = path,
		guide = guide,
		cb = function ()
			------------ 处理游戏暂停 ------------
			self:ResumeBattleButtonClickHandler(nil)
			------------ 处理游戏暂停 ------------

			------------ 恢复游戏加速 ------------
			G_BattleMgr:SetRenderTimeScale(currentRenderTimeScale)
			------------ 恢复游戏加速 ------------
		end
	})
	plotStage:setPosition(display.center)
	sceneWorld:addChild(plotStage, GameSceneTag.Dialog_GameSceneTag)
end
--[[
喊话
@params viewModelTag int 展示层tag
@params dialogueFrameType int 对话框气泡类型
@params content string 对话内容
@params callback function 喊话后的回调函数
--]]
function BattleRenderManager:ObjectViewSpeak(viewModelTag, dialogueFrameType, content, callback)
	local view = self:GetAObjectView(viewModelTag)
	if nil ~= view then
		view:ShowDialogue(dialogueFrameType, content, nil, callback)
	end
end
--[[
镜头效果 ConfigCameraActionType.SHAKE_ZOOM 抖动+变焦
@params tag int 触发镜头特效的物体tag
@params cameraActionTag int 镜头特效tag
@params scale number 场景最终缩放
--]]
function BattleRenderManager:CameraActionShakeAndZoom(tag, cameraActionTag, scale)
	local staticShakeTime = 1
	local scaleTime = 1.75

	local battleScene = self:GetBattleScene()

	------------ 设置一些节点大小 ------------
	local scaledSize = cc.size(
		battleScene:getContentSize().width * battleScene:getScaleX() * scale,
		battleScene:getContentSize().height * battleScene:getScaleY() * scale
	)
	local convertScaleX, convertScaleY = display.width / scaledSize.width, display.height / scaledSize.height

	-- 高亮底层
	local targetNode = battleScene.viewData.effectLayer
	local fixedSize = cc.size(
		targetNode:getContentSize().width * convertScaleX,
		targetNode:getContentSize().height * convertScaleY
	)
	targetNode:setContentSize(fixedSize)
	------------ 设置一些节点大小 ------------

	------------ 前景抖动动画 ------------
	local fgShakeAction = cc.Sequence:create(
		ShakeAction:create(staticShakeTime + scaleTime, 20, 10)
	)
	battleScene.viewData.fgLayer:runAction(fgShakeAction)
	------------ 前景抖动动画 ------------

	------------ 后景抖动动画 ------------
	local bgShakeAction = cc.Sequence:create(
		ShakeAction:create(staticShakeTime + scaleTime, 10, 5)
	)
	battleScene.viewData.bgLayer:runAction(bgShakeAction)
	------------ 后景抖动动画 ------------

	------------ 地图层抖动动画 ------------
	local battleLayerShakeAction = cc.Sequence:create(
		ShakeAction:create(staticShakeTime + scaleTime, 15, 7)
	)
	battleScene.viewData.battleLayer:runAction(battleLayerShakeAction)
	------------ 地图层抖动动画 ------------

	------------ 场景动画 ------------
	local sceneActionSeq = cc.Sequence:create(
		cc.DelayTime:create(staticShakeTime),
		cc.EaseIn:create(cc.ScaleTo:create(scaleTime, scale), 3),
		cc.CallFunc:create(function ()
			-- action结束 回传命令
			--###---------- 玩家手操记录 ----------###--
			self:AddPlayerOperate(
				'G_BattleLogicMgr',
				'RenderCameraActionShakeAndZoomOverHandler',
				tag, cameraActionTag
			)
			--###---------- 玩家手操记录 ----------###--
		end)
	)
	battleScene.viewData.fieldLayer:runAction(sceneActionSeq)
	------------ 场景动画 ------------
end
--[[
强制隐藏所有的object view
@params show bool 是否显示
--]]
function BattleRenderManager:ForceShowAllObjectView(show)
	for _, view in pairs(self.objectViews) do
		view:SetObjectVisible(show)
	end
end
--[[
展示一段表演
@params callback function 表演结束的回调
@params r BattleResult 战斗结果
@params responseData table 服务器返回信息
--]]
function BattleRenderManager:ShowActAfterGameOver(callback, r, responseData)
	-- 判断类型
	if QuestBattleType.UNION_BEAST == self:GetQuestBattleType() then
		-- 创建神兽吃能量场景
		local beastId = self:GetUnionBeastId()
		local babyEnergyLevel = checkint(responseData.energyLevel)
		local deltaEnergy = checkint(responseData.energy)
		if 0 < babyEnergyLevel and 0 ~= beastId then
			local scene = __Require('battle.miniGame.UnionBeastBabyEatScene').new({
				beastId = beastId,
				energyLevel = babyEnergyLevel,
				deltaEnergy = deltaEnergy,
				callback = callback
			})
			self:GetBattleScene():addChild(scene, BATTLE_E_ZORDER.CI)
		else
			callback()
		end
	end
end
--[[
播放一段卡牌语音
@params voiceData table 语音信息 {
	id int 语音id
	cardId int 卡牌id
	isEnemy bool 是否是敌人的语音
	text string 语音文字
	time number 语音时间
}
--]]
function BattleRenderManager:PlayeVoice(voiceData)
	local voicesConfig = CardUtils.GetVoiceLinesConfigByCardId(voiceData.cardId)
	local voiceConfig = nil

	if nil ~= voicesConfig then
		for i,v in ipairs(voicesConfig) do
			if voiceData.voiceId == checkint(v.groupId) then
				voiceConfig = v
				break
			end
		end
	end

	if nil ~= voiceConfig then
		local cueSheet = tostring(voiceConfig.roleId)
		local cueName = voiceConfig.voiceId
		local acbFile = string.format('sounds/%s.acb', cueSheet)
		if utils.isExistent(acbFile) then
			app.audioMgr:AddCueSheet(cueSheet, acbFile)
			app.audioMgr:PlayAudioClip(cueSheet, cueName)
		end
	end

	self:ShowVoiceDialouge(voiceData.cardId, voiceData.text, voiceData.isEnemy, voiceData.time)
end
--[[
显示顶部对话气泡
@params cardId int 卡牌id
@params text string 描述文字
@params isEnemy bool 敌友性
@params time number 语音时间
--]]
function BattleRenderManager:ShowVoiceDialouge(cardId, text, isEnemy, time)
	local layerSize = cc.size(325, 85)
	local layer = display.newLayer(0, 0, {size = layerSize, ap = cc.p(0.5, 0.5)})
	self:GetBattleScene():addChild(layer, 99999)

	self.dialougeTagCounter = self.dialougeTagCounter + 1
	layer:setTag(self.dialougeTagCounter)

	local bg = display.newImageView(_res('ui/common/common_bg_tips_common.png'), layerSize.width * 0.5, layerSize.height * 0.5,
		{scale9 = true, size = layerSize})
	layer:addChild(bg)

	-- 卡牌头像
	local cardHeadBg = display.newImageView(_res('ui/cards/head/kapai_frame_bg.png'), 0, 0)
	local cardHeadScale = (layerSize.height - 10) / cardHeadBg:getContentSize().height
	cardHeadBg:setScale(cardHeadScale)
	layer:addChild(cardHeadBg)

	local cardHeadCover = display.newImageView(_res('ui/cards/head/kapai_frame_orange.png'), 0, 0)
	cardHeadCover:setScale(cardHeadScale)
	layer:addChild(cardHeadCover, 10)

	local headIcon = display.newImageView(_res(CardUtils.GetCardHeadPathBySkinId(CardUtils.GetCardSkinId(cardId))), 0, 0)
	headIcon:setScale(cardHeadScale)
	layer:addChild(headIcon, 5)

	-- 翻译文字
	local descrLabel = display.newLabel(0, 0, fontWithColor('6', {text = text}))
	layer:addChild(descrLabel)

	local x = 0
	local y = 0

	local textW = 0
	local textH = 0
	local textAlign = display.TAC
	local textPos = cc.p(0, 0)
	local textAp = cc.p(0, 0)

	local dislougeMoveX = 0

	local cardHeadPos = cc.p(0, 0)

	local cacheNodes = nil

	if isEnemy then
		dislougeMoveX = -layerSize.width
		x = display.width - layerSize.width * 0.5 - dislougeMoveX
		y = display.height - layerSize.height * 0.5 - (layerSize.height) * self.enemyDialougeY

		cardHeadPos.x = layerSize.width - 5 - cardHeadBg:getContentSize().width * 0.5 * cardHeadScale
		cardHeadPos.y = layerSize.height * 0.5

		local headIconLeftBorderX = cardHeadPos.x - cardHeadBg:getContentSize().width * 0.5 * cardHeadScale
		textAp = cc.p(0, 1)
		textAlign = display.TAL
		textW = headIconLeftBorderX - 20
		textH = layerSize.height - 20
		textPos.x = headIconLeftBorderX * 0.5 - textW * 0.5
		textPos.y = layerSize.height * 0.5 + textH * 0.5

		self.enemyDialougeY = self.enemyDialougeY + 1

		cacheNodes = self.enemyDialougeNodes
	else
		dislougeMoveX = layerSize.width
		x = layerSize.width * 0.5 - dislougeMoveX
		y = display.height - layerSize.height * 0.5 - (layerSize.height) * self.friendDialougeY

		cardHeadPos.x = cardHeadBg:getContentSize().width * 0.5 * cardHeadScale + 5
		cardHeadPos.y = layerSize.height * 0.5

		local headIconRightBorderX = cardHeadPos.x + cardHeadBg:getContentSize().width * 0.5 * cardHeadScale
		textAp = cc.p(0, 1)
		textAlign = display.TAL
		textW = layerSize.width - headIconRightBorderX - 20
		textH = layerSize.height - 20
		textPos.x = (layerSize.width - headIconRightBorderX) * 0.5 + headIconRightBorderX - textW * 0.5
		textPos.y = layerSize.height * 0.5 + textH * 0.5

		self.friendDialougeY = self.friendDialougeY + 1

		cacheNodes = self.friendDialougeNodes
	end

	display.commonUIParams(layer, {po = cc.p(x, y)})

	display.commonUIParams(cardHeadBg, {po = cardHeadPos})
	display.commonUIParams(cardHeadCover, {po = cardHeadPos})
	display.commonUIParams(headIcon, {po = cardHeadPos})

	display.commonLabelParams(descrLabel, {w = textW, h = textH, hAlign = textAlign})
	display.commonUIParams(descrLabel, {ap = textAp, po = textPos})

	-- 插入缓存
	table.insert(cacheNodes, 1, layer)

	local actionSeq = cc.Sequence:create(
		cc.EaseOut:create(cc.MoveBy:create(0.2, cc.p(dislougeMoveX, 0)), 5),
		cc.DelayTime:create(2),
		cc.FadeTo:create(0.5, 0),
		cc.Hide:create(),
		cc.CallFunc:create(function ()
			-- 将自己从缓存队列中移除 并将所有节点上移一位
			for i = #cacheNodes, 1, -1 do
				if layer:getTag() == cacheNodes[i]:getTag() then
					table.remove(cacheNodes, i)
					if isEnemy then
						self.enemyDialougeY = self.enemyDialougeY - 1
					else
						self.friendDialougeY = self.friendDialougeY - 1
					end
					break
				end
			end

			-- 将所有缓存node上移
			for i,v in ipairs(cacheNodes) do
				local y = display.height - layerSize.height * 0.5 - (layerSize.height) * (#cacheNodes - i)
				local moveActionSeq = cc.Sequence:create(
					cc.EaseIn:create(cc.MoveTo:create(0.2, cc.p(v:getPositionX(), y)), 5)
				)
				v:runAction(moveActionSeq)
			end
		end),
		cc.RemoveSelf:create()
	)
	layer:runAction(actionSeq)
end
--[[
开始物体变形
@params viewModelTag int 展示层模型tag
@params oriSkinId int 源皮肤id
@params oriActionName string 源皮肤变形的动作
@params targetSkinId int 目标皮肤id
@params targetActionName string 目标皮肤变形的衔接动作
--]]
function BattleRenderManager:StartObjectViewTransform(viewModelTag, oriSkinId, oriActionName, targetSkinId, targetActionName)
	local view = self:GetAObjectView(viewModelTag)
	if nil ~= view then
		view:StartViewTransform(oriSkinId, oriActionName, targetSkinId, targetActionName)
	end
end
--[[
物体进行变形替换
@params viewModelTag int 展示层模型tag
@params oriSkinId int 源皮肤id
@params oriActionName string 源皮肤变形的动作
@params targetSkinId int 目标皮肤id
@params targetActionName string 目标皮肤变形的衔接动作
--]]
function BattleRenderManager:DoObjectViewTransform(viewModelTag, oriSkinId, oriActionName, targetSkinId, targetActionName)
	local view = self:GetAObjectView(viewModelTag)
	if nil ~= view then
		view:DoViewTransform(oriSkinId, oriActionName, targetSkinId, targetActionName)
	end
end
---------------------------------------------------
-- battle performance end --
---------------------------------------------------

---------------------------------------------------
-- battle guide begin --
---------------------------------------------------
--[[
创建引导层
@params guideStepData BattleGuideStepStruct 战斗单步引导信息
--]]
function BattleRenderManager:CreateGuideView(guideStepData)
	self:GetBattleDriver(BattleDriverType.GUIDE_DRIVER):OnLogicEnter(guideStepData)
end
--[[
隐藏所有引导节点
--]]
function BattleRenderManager:HideAllGuideCover()
	self:GetBattleDriver(BattleDriverType.GUIDE_DRIVER):HideAllGuideCover()
end
---------------------------------------------------
-- battle guide end --
---------------------------------------------------

---------------------------------------------------
-- battle result begin --
---------------------------------------------------
--[[
显示战斗胜利界面
@params responseData table 服务器返回数据
--]]
function BattleRenderManager:ShowGameSuccess(responseData)
	if self:NeedShowActAfterGameOver() then
		-- 显示神兽吃能量的场景
		local function callback()
			self:CreateBattleSuccessView(responseData)	
		end
		self:ShowActAfterGameOver(callback, BattleResult.BR_SUCCESS, responseData)
	else
		self:CreateBattleSuccessView(responseData)
	end
end
--[[
创建战斗胜利界面
@params responseData table 服务器返回数据
--]]
function BattleRenderManager:CreateBattleSuccessView(responseData)
	local className = 'battle.view.BattleSuccessView'
	local p_ = {}

	-- 结算类型
	local viewType = self:GetBattleResultViewType()
	local questBattleType = self:GetQuestBattleType()

	if self:IsShareBoss() then

		className = 'battle.view.ShareBossSuccessView'

		p_ = {
			totalTime = responseData.requestData.passTime,
			totalDamage = responseData.requestData.totalDamage
		}

	elseif ConfigBattleResultType.POINT_HAS_RESULT == viewType or

		ConfigBattleResultType.POINT_NO_RESULT == viewType then

		className = 'battle.view.PointSettleView'

		p_ = {
			battleResult = BattleResult.BR_SUCCESS
		}

	elseif ConfigBattleResultType.NO_RESULT_DAMAGE_COUNT == viewType then

		className = 'battle.view.ShareBossSuccessView'

		p_ = {
			totalTime = responseData.requestData.passTime,
			totalDamage = checknumber(responseData.requestData.totalDamage)
		}

	elseif ConfigBattleResultType.ONLY_RESULT_AND_REWARDS == viewType then

		className = 'battle.view.CommonBattleResultView'

		p_ = {
			battleResult = BattleResult.BR_SUCCESS
		}

	elseif ConfigBattleResultType.REPLAY == viewType then
		
		className = 'battle.view.BattleReplayResultView'

		p_ = {
			enemyTeamData = self:GetBattleMembers(true, 1),
			battleResult  = BattleResult.BR_SUCCESS,
		}

	end

	-- 三星条件
	local cleanCondition = nil
	if self:CanRechallenge() then
		cleanCondition = self:GetBattleConstructData().cleanCondition
	end

	-- 是否显示留言
	local showMessage = QuestBattleType.ROBBERY == questBattleType

	local viewParams = {
		viewType = viewType,
		cleanCondition = cleanCondition,
		showMessage = showMessage,
		canRepeatChallenge = false,
		teamData = self:GetBattleMembers(false, 1),
		trophyData = responseData
	}

	for k,v in pairs(p_) do
		viewParams[k] = v
	end

	-- 创建战斗结算界面
	local layer = __Require(className).new(viewParams)
	display.commonUIParams(layer, {ap = cc.p(0, 0), po = cc.p(0, 0)})
	self:GetBattleScene():AddUILayer(layer)

	layer:setTag(GAME_RESULT_LAYER_TAG)
end
--[[
显示战斗失败
@params responseData table 服务器返回数据
--]]
function BattleRenderManager:ShowGameFail(responseData)
	if self:NeedShowActAfterGameOver() then
		-- 显示神兽吃能量的场景
		local function callback()
			self:CreateBattleFailView(responseData)	
		end
		self:ShowActAfterGameOver(callback, BattleResult.BR_FAIL, responseData)
	else
		self:CreateBattleFailView(responseData)
	end
end
--[[
创建战斗失败界面
@params responseData table 服务器返回数据
--]]
function BattleRenderManager:CreateBattleFailView(responseData)
	local className = 'battle.view.BattleFailView'
	local p_ = {}

	-- 结算类型
	local viewType = ConfigBattleResultType.NO_EXP
	local questBattleType = self:GetQuestBattleType()
	local configResultType = self:GetBattleResultViewType()

	if QuestBattleType.SEASON_EVENT == questBattleType or
		QuestBattleType.SAIMOE == questBattleType or
		QuestBattleType.UNION_PVC == questBattleType or
		ConfigBattleResultType.POINT_NO_RESULT == configResultType or
		ConfigBattleResultType.NO_RESULT_DAMAGE_COUNT == configResultType or
		ConfigBattleResultType.REPLAY == configResultType then

		viewType = configResultType

	end

	if self:IsShareBoss() then

		className = 'battle.view.ShareBossSuccessView'

		p_ = {
			totalTime = responseData.requestData.passTime,
			totalDamage = responseData.requestData.totalDamage
		}

	elseif ConfigBattleResultType.POINT_HAS_RESULT == viewType or
		ConfigBattleResultType.POINT_NO_RESULT == viewType then

		className = 'battle.view.PointSettleView'		

		p_ = {
			battleResult = BattleResult.BR_FAIL
		}

	elseif ConfigBattleResultType.NO_RESULT_DAMAGE_COUNT == viewType then

		className = 'battle.view.ShareBossSuccessView'

		p_ = {
			totalTime = responseData.requestData.passTime,
			totalDamage = checknumber(responseData.totalDamage)
		}

	elseif ConfigBattleResultType.ONLY_RESULT_AND_REWARDS == viewType then

		className = 'battle.view.CommonBattleResultView'

		p_ = {
			battleResult = BattleResult.BR_FAIL
		}

	elseif ConfigBattleResultType.REPLAY == viewType then
		
		className = 'battle.view.BattleReplayResultView'

		p_ = {
			enemyTeamData = self:GetBattleMembers(true, 1),
			battleResult  = BattleResult.BR_FAIL,
		}

	end

	local viewParams = {
		viewType = viewType,
		cleanCondition = nil,
		showMessage = false,
		canRepeatChallenge = false,
		teamData = self:GetBattleMembers(false, 1),
		trophyData = responseData
	}

	for k,v in pairs(p_) do
		viewParams[k] = v
	end

	local layer = __Require(className).new(viewParams)
	display.commonUIParams(layer, {ap = cc.p(0, 0), po = cc.p(0, 0)})
	self:GetBattleScene():AddUILayer(layer)

	layer:setTag(GAME_RESULT_LAYER_TAG)
end
--[[
退出战斗 处理一些东西
--]]
function BattleRenderManager:QuitBattle()
	-- 屏蔽触摸
	self:SetBattleTouchEnable(false)
	-- 清空所有展示层实例
	self:DestroyAllView()
	-- 清空场景
	self:DestroyScene()
	-- 清空缓存数据
	self:DestroyValue()
	-- 清空战斗驱动器
	self:DestroyBattleDrivers()

	------------ 停掉录像 ------------
	BattleUtils.StopScreenRecord()
	------------ 停掉录像 ------------
end
--[[
清空所有展示层实例
--]]
function BattleRenderManager:DestroyAllView()
	for _, view in pairs(self.objectViews) do
		if view.Destroy then view:Destroy() end
	end
	self.objectViews = {}

	for _, view in pairs(self.qteAttachViews) do
		if view.Destroy then view:Destroy() end
	end
	self.qteAttachViews = {}
end
--[[
清空场景
--]]
function BattleRenderManager:DestroyScene()
	
end
--[[
清空缓存数据
--]]
function BattleRenderManager:DestroyValue()
	-- 物体渲染层数据
	self.objectViews = {}
	-- qte物体渲染层数据
	self.qteAttachViews = {}
	-- 主角模型渲染层数据
	self.playerViews = {}
	-- 暂停游戏的场景
	self.ciScenes = {pause = {}, normal = {}} -- 缓存ci场景 暂停的时候会判断ci场景是否暂停了obj 如果有恢复的时候不会恢复obj
	-- 暂停的coco2dx actions
	self.pauseActions = {pauseScene = {}, normalScene = {}, battle = {}}

	-- 连携技按钮
	self.connectButtons = {}
	self.connectButtonsIndex = {}

	------------ 顶部语音气泡节点 ------------
	self.friendDialougeNodes = {}
	self.enemyDialougeNodes = {}

	self.friendDialougeY = 0
	self.enemyDialougeY = 0
	self.dialougeTagCounter = 0
	------------ 顶部语音气泡节点 ------------
end
--[[
清空战斗驱动器
--]]
function BattleRenderManager:DestroyBattleDrivers()
	-- 通用驱动器

	-- 引导驱动器
	self:DestroyGuideDriver()
end
--[[
清空引导驱动器
--]]
function BattleRenderManager:DestroyGuideDriver()
	if nil ~= self:GetBattleDriver(BattleDriverType.GUIDE_DRIVER) then
		self:GetBattleDriver(BattleDriverType.GUIDE_DRIVER):OnDestroy()
	end
end
--[[
是否需要显示表演场景
@params r BattleResult 战斗结果
@return _ bool 
--]]
function BattleRenderManager:NeedShowActAfterGameOver(r)
	if QuestBattleType.UNION_BEAST == self:GetQuestBattleType() then
		return true
	end
	return false
end
---------------------------------------------------
-- battle result end --
---------------------------------------------------

---------------------------------------------------
-- rescue begin --
---------------------------------------------------
--[[
显示买活界面
@params canBuyReviveFree bool 是否可以免费买活
--]]
function BattleRenderManager:ShowBuyRevivalScene(canBuyReviveFree)
	local scene = __Require('battle.view.BattleBuyRevivalView').new({
		stageId = self:GetCurStageId(),
		questBattleType = self:GetQuestBattleType(),
		buyRevivalTime = self:GetBuyRevivalTime(),
		buyRevivalTimeMax = self:GetMaxBuyRevivalTime(),
		canBuyReviveFree = canBuyReviveFree
	})
	scene:setTag(BUY_REVIVAL_LAYER_TAG)
	display.commonUIParams(scene, {ap = cc.p(0, 0), po = cc.p(0, 0)})
	self:GetBattleScene():AddUILayer(scene)

	for _, btn in pairs(scene.actionButtons) do
		display.commonUIParams(btn, {cb = handler(self, self.ButtonsClickHandler)})
	end
end
--[[
取消买活
--]]
function BattleRenderManager:CancelRescue()
	-- 移除买活界面
	self:GetBattleScene():RemoveUILayerByTag(BUY_REVIVAL_LAYER_TAG)

	--###---------- 刷新逻辑层 ----------###--
	-- 暂停正常逻辑
	self:AddPlayerOperate(
		'G_BattleLogicMgr',
		'RenderCancelRescueHandler'
	)
	--###---------- 刷新逻辑层 ----------###--
end
--[[
确定买活 全体复活
--]]
function BattleRenderManager:RescueAllFriend()
	local stageId = self:GetCurStageId()
	local questBattleType = self:GetQuestBattleType()
	local nextBuyRevivalTime = self:GetNextBuyRevivalTime()

	local costConsumeConfig = CommonUtils.GetBattleBuyReviveCostConfig(
		stageId,
		questBattleType,
		nextBuyRevivalTime
	)
	local costGoodsId = checkint(costConsumeConfig.consume)
	local costGoodsAmount = checkint(costConsumeConfig.consumeNum)

	local buyRevivalScene = self:GetBattleScene():GetUIByTag(BUY_REVIVAL_LAYER_TAG)
	local buyRevivalFree = false
	if nil ~= buyRevivalScene then
		buyRevivalFree = buyRevivalScene:CanBuyReviveFree()
	end

	-- 判断消耗是否满足条件	
	if true == buyRevivalFree then

		-- 免费买活 将消耗置空
		costGoodsAmount = 0

	else

		local goodsAmount = app.gameMgr:GetAmountByIdForce(costGoodsId)

		if (0 ~= costGoodsAmount) and (costGoodsAmount > goodsAmount) then
			if GAME_MODULE_OPEN.NEW_STORE and checkint(costGoodsId) == DIAMOND_ID then
				app.uiMgr:showDiamonTips(nil, true)
			else
				local goodsConfig = CommonUtils.GetConfig('goods', 'goods', costGoodsId)
				app.uiMgr:ShowInformationTips(string.format(__('%s不足'), goodsConfig.name))
			end
			return
		end

	end

	----- network command -----
	local function callback(responseData)
		-- 扣除消耗
		CommonUtils.DrawRewards({
			{goodsId = costGoodsId, num = -costGoodsAmount}
		})

		--###---------- 刷新逻辑层 ----------###--
		-- 暂停正常逻辑
		self:AddPlayerOperate(
			'G_BattleLogicMgr',
			'RescueAllFriend'
		)
		--###---------- 刷新逻辑层 ----------###--
	end
	local serverCommand = self:GetServerCommand()
	AppFacade.GetInstance():DispatchObservers('BATTLE_BUY_REVIVE_REQUEST', {
		requestCommand = serverCommand.buyCheatRequestCommand,
		responseSignal = serverCommand.buyCheatResponseSignal,
		requestData = serverCommand.buyCheatRequestData,
		callback = callback
	})
	----- network command -----
end
--[[
显示买活动画场景
@params viewModelTags list 展示层tag集合
--]]
function BattleRenderManager:StartRescueAllFriend(viewModelTags)
	-- 移除买活界面
	self:GetBattleScene():RemoveUILayerByTag(BUY_REVIVAL_LAYER_TAG)

	local renderTimeScale = G_BattleMgr:GetRenderTimeScale()

	local reviveBegin = function ()

		G_BattleMgr:SetRenderTimeScale(1)

		for _, viewModelTag in ipairs(viewModelTags) do
			local view = self:GetAObjectView(viewModelTag)
			if nil ~= view then

				-- 创建一个复活spine动画
				local reviveSpine = SpineCache(SpineCacheName.BATTLE):createWithName('hurt_18')
				reviveSpine:setPosition(cc.p(
					view:getPositionX(), view:getPositionY()
				))
				self:GetBattleRoot():addChild(reviveSpine, view:getLocalZOrder())
				reviveSpine:setAnimation(0, 'idle', false)

				reviveSpine:registerSpineEventHandler(
					function (event)
						if sp.CustomEvent.cause_effect == event.eventData.name then
							view:ReviveFromBuyRevive()
						end
					end,
					sp.EventType.ANIMATION_EVENT
				)

				reviveSpine:registerSpineEventHandler(
					function (event)
						-- 移除自己
						reviveSpine:runAction(cc.RemoveSelf:create())
					end,
					sp.EventType.ANIMATION_COMPLETE
				)

			end
		end

	end

	local reviveMiddle = function ()
		--###---------- 刷新逻辑层 ----------###--
		-- 暂停正常逻辑
		self:AddPlayerOperate(
			'G_BattleLogicMgr',
			'RescueAllFriendComplete'
		)
		--###---------- 刷新逻辑层 ----------###--
	end

	local reviveEnd = function ()
		G_BattleMgr:SetRenderTimeScale(renderTimeScale)

		self:SetBattleTouchEnable(true)

		--###---------- 刷新逻辑层 ----------###--
		-- 暂停正常逻辑
		self:AddPlayerOperate(
			'G_BattleLogicMgr',
			'RescueAllFriendOver'
		)
		--###---------- 刷新逻辑层 ----------###--
	end

	local scene = __Require('battle.miniGame.RescueAllFriendScene').new({
		callbacks = {
			reviveBegin = reviveBegin,
			reviveMiddle = reviveMiddle,
			reviveEnd = reviveEnd,
		}
	})
	self:GetBattleScene():addChild(scene, BATTLE_E_ZORDER.CI)
end
---------------------------------------------------
-- rescue end --
---------------------------------------------------

---------------------------------------------------
-- skada begin --
---------------------------------------------------
--[[
显示伤害统计
@params isEnemy bool 是否是敌人
--]]
function BattleRenderManager:ShowSkada(isEnemy)
	local skadaLayer = self:GetBattleScene():GetUIByTag(SKADA_LAYER_TAG)
	if nil ~= skadaLayer and skadaLayer.isEnemy == isEnemy then
		skadaLayer:setVisible(true)
	else
		if nil ~= skadaLayer then
			skadaLayer:removeFromParent()
		end
		local skadaDriver = G_BattleLogicMgr:GetBattleDriver(BattleDriverType.SKADA_DRIVER)
		skadaLayer = __Require('battle.view.SkadaView').new({
			teamsData = self:GetBattleMembers(isEnemy == true),
			skadaData = (isEnemy == true) and skadaDriver:GetEnemySkadaData() or skadaDriver:GetFriendSkadaData(),
			tagInfo   = (isEnemy == true) and skadaDriver:GetEnemyTagInfo() or skadaDriver:GetFriendTagInfo(),
		})
		display.commonUIParams(skadaLayer, {ap = cc.p(0.5, 0.5), po = display.center})
		self:GetBattleScene():AddUILayer(skadaLayer)
		skadaLayer:setTag(SKADA_LAYER_TAG)
		skadaLayer.isEnemy = isEnemy
	end
end
---------------------------------------------------
-- skada end --
---------------------------------------------------

---------------------------------------------------
-- spine begin --
---------------------------------------------------
--[[
获取内存中是否存在对应的spine资源
@params spineId int spine动画id
@params spineType SpineType spine动画的类型
@params wave int 波数
@return _ bool 该资源是否在内存中
--]]
function BattleRenderManager:SpineInCache(spineId, spineType, wave)
	return self:GetBattleDriver(BattleDriverType.RES_LOADER):HasLoadSpineByCacheName(
		BattleUtils.GetCacheAniNameById(spineId, spineType)
	)
end
--[[
根据卡牌id获取spine avatar相对于卡牌的缩放比
@params cardId int 卡牌id
@return scale number spine缩放
--]]
function BattleRenderManager:GetSpineAvatarScale2CardByCardId(cardId)
	return self:GetSpineAvatarScaleByCardId(cardId) / CARD_DEFAULT_SCALE
end
--[[
根据卡牌id获取spine缩放比
@params cardId int 卡牌id
@return scale number spine缩放
--]]
function BattleRenderManager:GetSpineAvatarScaleByCardId(cardId)
	local cardConfig = CardUtils.GetCardConfig(cardId)

	local spineId = cardId
	local scale = CARD_DEFAULT_SCALE

	if CardUtils.IsMonsterCard(cardId) then

		-- 判断卡牌初始缩放比
		local monsterType = checkint(cardConfig.type)
		if ConfigMonsterType.ELITE == monsterType then
			scale = ELITE_DEFAULT_SCALE
		elseif ConfigMonsterType.BOSS == monsterType then
			scale = BOSS_DEFAULT_SCALE
		end

		-- if true ~= cardMgr.IsMonster(avatarId) then
		-- 	-- 如果是怪物使用卡牌的情况 则加载时不做缩放
		-- 	scale = CARD_DEFAULT_SCALE
		-- end

	end

	return scale
end
---------------------------------------------------
-- spine end --
---------------------------------------------------

---------------------------------------------------
-- sound begin --
---------------------------------------------------
--[[
播放一次战斗音效
@params id string 音效id
--]]
function BattleRenderManager:PlayBattleSoundEffect(id)
	PlayBattleEffects(id)
end
--[[
播放卡牌语音
@params cardId int 卡牌id
@soundType SoundType 语音类型
--]]
function BattleRenderManager:PlayCardSound(cardId, soundType)
	CommonUtils.PlayCardSoundByCardId(cardId, soundType)
end
---------------------------------------------------
-- sound end --
---------------------------------------------------

---------------------------------------------------
-- touch begin --
---------------------------------------------------
--[[
设置触摸
@params enable bool 设置是否可触摸
--]]
function BattleRenderManager:SetBattleTouchEnable(enable)
	self.battleTouchEnable = enable
	if self:GetBattleScene() and self:GetBattleScene().viewData then
		self:GetBattleScene().viewData.eaterLayer:setVisible(not enable)
	end
end
--[[
全屏是否响应触摸
@return _ bool 是否响应触摸
--]]
function BattleRenderManager:IsBattleTouchEnable()
	return self.battleTouchEnable
end
---------------------------------------------------
-- touch end --
---------------------------------------------------

---------------------------------------------------
-- button handler begin --
---------------------------------------------------
--[[
战斗场景中ui按钮回调
1001 暂停游戏
1002 游戏加速
1003 退出战斗
1004 重新开始
1005 继续游戏
1008 放弃买活
1009 买活
--]]
function BattleRenderManager:ButtonsClickHandler(sender)
	-- 按钮音效
	PlayAudioByClickNormal()

	local tag = sender:getTag()
	if 1001 == tag then
		-- 暂停游戏
		self:PauseBattleButtonClickHandler(sender)
	elseif 1002 == tag then
		-- 游戏加速按钮
		self:AccelerateButtonClickHandler(sender)
	elseif 1003 == tag then
		-- 退出战斗
		self:QuitGameButtonClickHandler(sender)
	elseif 1004 == tag then
		-- 重新开始战斗
		self:RestartGameButtonClickHandler(sender)
	elseif 1005 == tag then
		-- 从暂停中恢复游戏
		self:ResumeBattleButtonClickHandler(sender)	
	elseif 1008 == tag then
		-- 放弃买活
		self:CancelRescue()
	elseif 1009 == tag then
		-- 买活
		self:RescueAllFriend()
	end
end
--[[
加速按钮回调
--]]
function BattleRenderManager:AccelerateButtonClickHandler(sender)
	if not self:IsBattleTouchEnable() then return end

	--###---------- 玩家手操记录 ----------###--
	self:AddPlayerOperate(
		'G_BattleLogicMgr',
		'RenderAccelerateHandler'
	)
	--###---------- 玩家手操记录 ----------###--

	------------ 刷新本地加速记录 ------------
	local gameTimeScale = 3 - G_BattleMgr:GetRenderTimeScale()
	app.gameMgr:UpdatePlayer({localBattleAccelerate = gameTimeScale})
	------------ 刷新本地加速记录 ------------
end
--[[
暂停按钮回调
--]]
function BattleRenderManager:PauseBattleButtonClickHandler(sender)
	if not self:IsBattleTouchEnable() then return end

	--###---------- 玩家手操记录 ----------###--
	self:AddPlayerOperate(
		'G_BattleLogicMgr',
		'RenderPauseBattleHandler'
	)
	--###---------- 玩家手操记录 ----------###--
end
--[[
继续游戏按钮回调
--]]
function BattleRenderManager:ResumeBattleButtonClickHandler(sender)
	--###---------- 玩家手操记录 ----------###--
	self:AddPlayerOperate(
		'G_BattleLogicMgr',
		'RenderResumeBattleHandler'
	)
	--###---------- 玩家手操记录 ----------###--
end
--[[
连携技按钮回调
@params tag int 释放连携技的目标tag
@params skillId int 技能id
--]]
function BattleRenderManager:ConnectSkillButtonClickHandler(tag, skillId)
	if not self:IsBattleTouchEnable() then return end

	-- 按钮音效
	PlayAudioByClickNormal()
	
	--###---------- 玩家手操记录 ----------###--
	self:AddPlayerOperate(
		'G_BattleLogicMgr',
		'RenderConnectSkillHandler',
		tag, skillId
	)
	--###---------- 玩家手操记录 ----------###--
end
--[[
弱点按钮回调
@params sceneTag int 弱点场景tag
@params touchedPointId int 点击的弱点
--]]
function BattleRenderManager:WeakSkillPointClickHandler(sceneTag, touchedPointId)
	--###---------- 玩家手操记录 ----------###--
	self:AddPlayerOperate(
		'G_BattleLogicMgr',
		'RenderWeakPointClickHandler',
		sceneTag, touchedPointId
	)
	--###---------- 玩家手操记录 ----------###--
end
--[[
强制缩放游戏速度倍率
@params timeScale number 时间缩放倍率
--]]
function BattleRenderManager:ForceSetTimeScaleHandler(timeScale)
	--###---------- 玩家手操记录 ----------###--
	self:AddPlayerOperate(
		'G_BattleLogicMgr',
		'RenderSetTempTimeScaleHandler',
		timeScale
	)
	--###---------- 玩家手操记录 ----------###--
end
--[[
强制恢复游戏速度倍率
--]]
function BattleRenderManager:ForceRecoverTimeScaleHandler()
	--###---------- 玩家手操记录 ----------###--
	self:AddPlayerOperate(
		'G_BattleLogicMgr',
		'RenderRecoverTempTimeScaleHandler'
	)
	--###---------- 玩家手操记录 ----------###--
end
--[[
主角技按钮回调
@params tag int obj tag
@params skillId int 技能id
--]]
function BattleRenderManager:PlayerSkillHandler(tag, skillId)
	--###---------- 玩家手操记录 ----------###--
	self:AddPlayerOperate(
		'G_BattleLogicMgr',
		'RenderPlayerSkillClickHandler',
		tag, skillId
	)
	--###---------- 玩家手操记录 ----------###--
end
--[[
退出游戏按钮回调
--]]
function BattleRenderManager:QuitGameButtonClickHandler(sender)
	if self:GetQuitLock() then return end

	if QuestBattleType.PVC == self:GetQuestBattleType() then
		local layer = require('common.CommonTip').new({
			text = __('确定要退出吗?'),
			descr = __('退出本场战斗会被认定为失败'),
			callback = function (sender)
				-- 屏蔽触摸
				self:SetBattleTouchEnable(false)
				-- 上锁 排除点击过快的情况
				self:SetQuitLock(true)

				--###---------- 玩家手操记录 ----------###--
				self:AddPlayerOperate(
					'G_BattleLogicMgr',
					'RenderQuitGameHandler'
				)
				--###---------- 玩家手操记录 ----------###--
			end
		})
		layer:setPosition(display.center)
		app.uiMgr:GetCurrentScene():AddDialog(layer)

		return
	end

	-- 屏蔽触摸
	self:SetBattleTouchEnable(false)
	-- 上锁 排除点击过快的情况
	self:SetQuitLock(true)

	--###---------- 玩家手操记录 ----------###--
	self:AddPlayerOperate(
		'G_BattleLogicMgr',
		'RenderQuitGameHandler'
	)
	--###---------- 玩家手操记录 ----------###--
end
--[[
重新开始战斗
--]]
function BattleRenderManager:RestartGameButtonClickHandler(sender)
	if not self:CanRestartGame() then
		app.uiMgr:ShowInformationTips(__('无法重新开始!!!'))
	else
		if self:GetRestartLock() then return end

		self:SetBattleTouchEnable(false)
		-- 上锁 排除点击过快的情况
		self:SetRestartLock(true)

		--###---------- 玩家手操记录 ----------###--
		self:AddPlayerOperate(
			'G_BattleLogicMgr',
			'RenderRestartGameHandler'
		)
		--###---------- 玩家手操记录 ----------###--
	end
end
--[[
录屏按钮回调
--]]
function BattleRenderManager:ScreenRecordClickHandler(sender)
	local start = BattleUtils.StartScreenRecord()
	if start then
		PlayAudioByClickNormal()

		-- 设置图标变红
		self:GetBattleScene().viewData.recordLabel:setTexture(_res('ui/battle/battle_btn_video_under.png'))
		self:GetBattleScene().viewData.recordMark:setTexture(_res('ui/battle/battle_ico_video_state.png'))
	end
end
---------------------------------------------------
-- button handler end --
---------------------------------------------------

---------------------------------------------------
-- player operate begin --
---------------------------------------------------
--[[
向逻辑层中添加一条玩家手操
@params managerName string 管理器名字
@params functionName string 方法名
@params ... 参数集
--]]
function BattleRenderManager:AddPlayerOperate(managerName, functionName, ...)
	local playerOperateStruct = LogicOperateStruct.New(
		managerName, functionName, ...
	)
	if G_BattleLogicMgr then
		G_BattleLogicMgr:GetBData():AddPlayerOperate(playerOperateStruct)
	end
end
---------------------------------------------------
-- player operate end --
---------------------------------------------------

---------------------------------------------------
-- game time scale begin --
---------------------------------------------------
--[[
设置游戏速度倍率
@params timeScale number 速度倍率
--]]
function BattleRenderManager:SetBattleTimeScale(timeScale)
	local btnImage = 'ui/battle/battle_btn_accelerate.png'
	local btnText = 'x' .. (checknumber(timeScale) < 1 and string.format('1/%d', 1/checknumber(timeScale)) or tostring(timeScale))
	if checknumber(timeScale) == 1 or checknumber(timeScale) == 2 then
		btnImage = string.format('ui/battle/battle_btn_accelerate_%d.png', checkint(timeScale))
		btnText = ''
	end
	if self:GetBattleScene() and self:GetBattleScene().viewData and self:GetBattleScene().viewData.accelerateButton then
		self:GetBattleScene().viewData.accelerateButton:getNormalImage():setTexture(_res(btnImage))
		self:GetBattleScene().viewData.accelerateButton:setText(btnText)
	end
	G_BattleMgr:SetRenderTimeScale(timeScale)
end
---------------------------------------------------
-- game time scale end --
---------------------------------------------------

---------------------------------------------------
-- app background begin --
---------------------------------------------------
--[[
退后台暂停的逻辑
--]]
function BattleRenderManager:AppEnterBackground()
	-- 判断一些界面是否存在 如果存在直接不处理
	if nil ~= self:GetBattleScene() or not self:IsBattleTouchEnable() then

		-- 存在以下界面 直接不走逻辑
		local ignoreLayerTags = {
			PAUSE_SCENE_TAG
		}

		if self:GetBattleScene() then
			for _,v in ipairs(ignoreLayerTags) do
				if nil ~= self:GetBattleScene():getChildByTag(v) then
					return
				end
			end
		end

		--###---------- 玩家手操记录 ----------###--
		self:AddPlayerOperate(
			'G_BattleLogicMgr',
			'AppEnterBackground'
		)
		--###---------- 玩家手操记录 ----------###--

	end
end
--[[
从后台返回前台的逻辑
--]]
function BattleRenderManager:AppEnterForeground()
	
end
--[[
显示强制退出的对话框
--]]
function BattleRenderManager:ShowForceQuitLayer()
	local layer = app.uiMgr:GetCurrentScene():GetDialogByTag(FORCE_QUIT_LAYER_TAG)

	if nil ~= layer then
		-- 存在弹窗 消去这个弹窗
		layer:runAction(cc.RemoveSelf:create())
		return
	end

	local gameResultLayer = self:GetBattleScene():GetUIByTag(GAME_RESULT_LAYER_TAG)
	if nil ~= gameResultLayer then
		-- 如果已经结束 退出游戏
		-- 屏蔽触摸
		self:SetBattleTouchEnable(false)
		G_BattleMgr:BackToPrevious()
		return
	end

	-- 不暂停游戏 直接跳遮挡
	layer = require('common.CommonTip').new({
		text = __('确定要退出吗?'),
		descr = __('退出本场战斗会被认定为失败'),
		callback = function (sender)
			-- 屏蔽触摸
			self:SetBattleTouchEnable(false)
			G_BattleMgr:BackToPrevious()
		end
	})
	layer:setTag(FORCE_QUIT_LAYER_TAG)
	layer:setPosition(display.center)
	app.uiMgr:GetCurrentScene():AddDialog(layer)

end
---------------------------------------------------
-- app background end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
获取主场景
--]]
function BattleRenderManager:GetBattleScene()
	return G_BattleMgr:GetViewComponent()
end
--[[
是否存在主战场节点
--]]
function BattleRenderManager:HasBattleRoot()
	return self:GetBattleScene() and not tolua.isnull(self:GetBattleScene()) and
			self:GetBattleScene().viewData and self:GetBattleScene().viewData.battleLayer
end
--[[
获取主战场节点
--]]
function BattleRenderManager:GetBattleRoot()
	return self:GetBattleScene().viewData.battleLayer
end
--[[
添加一个物体渲染
@params tag int obj tag
@params view BaseObjectView
--]]
function BattleRenderManager:AddAObjectView(tag, view)
	self.objectViews[tostring(tag)] = view
end
--[[
移除一个物体渲染
@params tag int obj tag
--]]
function BattleRenderManager:RemoveAObjectView(tag)
	self.objectViews[tostring(tag)] = nil
end
--[[
获取一个物体渲染
@params tag int 展示层的tag
--]]
function BattleRenderManager:GetAObjectView(tag)
	return self.objectViews[tostring(tag)]
end
--[[
添加一个qte物体渲染
@params tag int obj tag
@params view BaseAttachObjectView
--]]
function BattleRenderManager:AddAAttachObjectView(tag, view)
	self.qteAttachViews[tostring(tag)] = view
end
function BattleRenderManager:RemoveAAttachObjectView(tag)
	self.qteAttachViews[tostring(tag)] = nil
end
function BattleRenderManager:GetAAttachObjectView(tag)
	return self.qteAttachViews[tostring(tag)]
end
--[[
根据场景tag获取场景
@params sceneTag int 场景tag
@params isPauseScene bool 是否是带有暂停逻辑的场景
@return _ BaseMiniGameScene
--]]
function BattleRenderManager:GetCISceneBySceneTag(sceneTag, isPauseScene)
	if isPauseScene then
		return self.ciScenes.pause[tostring(sceneTag)]
	else
		return self.ciScenes.normal[tostring(sceneTag)]
	end
end
function BattleRenderManager:SetCISceneBySceneTag(sceneTag, isPauseScene, scene)
	if isPauseScene then
		self.ciScenes.pause[tostring(sceneTag)] = scene
	else
		self.ciScenes.normal[tostring(sceneTag)] = scene
	end
end
--[[
根据物体逻辑层tag获取hold的ci场景
@params tag int 逻辑层tag
@return _ BaseMiniGameScene ci场景
--]]
function BattleRenderManager:GetCISceneByOwnerTag(tag)
	for sceneTag_, scene in pairs(self.ciScenes.normal) do
		if tag == scene:GetOwnerTag() then
			return scene
		end
	end

	for sceneTag_, scene in pairs(self.ciScenes.pause) do
		if tag == scene:GetOwnerTag() then
			return scene
		end
	end
end
--[[
退出游戏的状态锁
--]]
function BattleRenderManager:GetQuitLock()
	return self.quitLock
end
function BattleRenderManager:SetQuitLock(lock)
	self.quitLock = lock
end
--[[
重开游戏的状态锁
--]]
function BattleRenderManager:GetRestartLock()
	return self.restartLock
end
function BattleRenderManager:SetRestartLock(lock)
	self.restartLock = lock
end
---------------------------------------------------
-- get set end --
---------------------------------------------------








---------------------------------------------------
-- debug begin --
---------------------------------------------------
--[[
debug 格子
--]]
function BattleRenderManager:DebugCells()
	for r = 1, G_BattleLogicMgr:GetBConf().ROW do
		for c = 1, G_BattleLogicMgr:GetBConf().COL do
			local cellInfo = G_BattleLogicMgr:GetCellPosByRC(r, c)
			local t = display.newImageView(_res('ui/common/common_hint_circle_red_ico.png'), cellInfo.cx, cellInfo.cy)
			self:GetBattleRoot():addChild(t)
			local posLabel = display.newLabel(t:getContentSize().width * 0.5, t:getContentSize().height + 10,
				{text = string.format('(%d,%d)', r, c), fontSize = 14, color = '#6c6c6c'})
			t:addChild(posLabel)
		end
	end
end
---------------------------------------------------
-- debug end --
---------------------------------------------------

return BattleRenderManager
