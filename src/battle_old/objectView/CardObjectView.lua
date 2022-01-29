--[[
基础战斗物体view
@params t table {
	spineId int 动画spineId
}
--]]
local BaseObjectView = __Require('battle.objectView.BaseObjectView')
local CardObjectView = class('CardObjectView', BaseObjectView)

------------ import ------------
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
local ExpressionNode = require('common.ExpressionNode')
local CardSpine = require('Frame.gui.CardSpine')
------------ import ------------

------------ define ------------
local TargetShadowSpineSize = cc.size(245, 245)
------------ define ------------

---------------------------------------------------
-- init view begin --
---------------------------------------------------
--[[
@override
初始化数值
--]]
function CardObjectView:initValue()
	BaseObjectView.initValue(self)

	------------ 判断一次怪物阴影 ------------
	local cardConfig = CardUtils.GetCardConfig(self:getVCardId())
	if nil ~= cardConfig and ConfigMonsterFormType.COMMODE == checkint(cardConfig.formType) then
		self:setForceHideAvatarShadow(true)
	end
	------------ 判断一次怪物阴影 ------------
end
--[[
@override
初始化视图
--]]
function CardObjectView:initView()
	BaseObjectView.initView(self)
end
--[[
@override
创建spine avatar
--]]
function CardObjectView:InitSpineAvatarNode()
	-- 处理骨骼动画名字
	local spineName = self:getSpineNameBySpineId(self:getVSpineId(), self:getVCardId())
	local spineTowards = 1

	local avatar = CardSpine.new({
		skinId = self:getVSkinId(),
		scale = BMediator:GetSpineAvatarScaleByCardId(self:getVCardId()),
		spineName = spineName,
		cacheName = SpineCacheName.BATTLE,
		oriAnimationInfo = BattleUtils.GetAvatarSpineDataStructBySpineId(
			self:getVSpineId(),
			BMediator:GetSpineAvatarScaleByCardId(self:getVCardId())
		),
		downloadOverCallback = handler(self, self.FixUIState)
	})
	-- local avatar = SpineCache(SpineCacheName.BATTLE):createWithName(spineName)

	-- 进行缩放
	avatar:setScale(self:getAvatarScale())
	avatar:update(0)

	-- 初始化静态边界框框
	self.staticViewBox = avatar:getBorderBox(sp.CustomName.VIEW_BOX)
	self.staticCollisionBox = avatar:getBorderBox(sp.CustomName.COLLISION_BOX)

	-- 初始化朝向 全部朝向右
	avatar:setScaleX(spineTowards * math.abs(avatar:getScaleX()))

	avatar:setPosition(cc.p(0, 0))
	self:addChild(avatar, 5)

	self.avatar = avatar
end
--[[
@override
初始化ui
--]]
function CardObjectView:InitUI()
	-- 处理大小
	local bgSize = cc.size(0, 0)
	self:setContentSize(bgSize)
	self:setAnchorPoint(cc.p(0.5, 0))
	-- self:setBackgroundColor(cc.c4b(255, 0, 0, 255))

	-- 角色阴影
	local avatarShadow = display.newNSprite(_res('ui/battle/battle_role_shadow.png'), bgSize.width * 0.5, 0)
	self:addChild(avatarShadow, 1)
	avatarShadow:setScale(0.5 * (self:getAvatarStaticViewBox().width / avatarShadow:getContentSize().width))
	avatarShadow:setVisible(not self:getForceHideAvatarShadow())

	-- hp bar
	local hpBarPath = 'ui/battle/battle_blood_bg_2.png'
	if self:getVEnemy() then
		hpBarPath = 'ui/battle/battle_blood_bg_2_red.png'
	end
	local hpBar = CProgressBar:create(_res(hpBarPath))
    hpBar:setBackgroundImage(_res('ui/battle/battle_blood_bg_4.png'))
    hpBar:setDirection(eProgressBarDirectionLeftToRight)
    hpBar:setPosition(cc.p(bgSize.width * 0.5, self:getAvatarStaticViewBox().height + 15))
    self:addChild(hpBar, 10)
    local hpBarCover = display.newImageView(_res('ui/battle/battle_blood_bg_1.png'), utils.getLocalCenter(hpBar).x, utils.getLocalCenter(hpBar).y)
    hpBar:addChild(hpBarCover)

    -- energy bar
	local energyBar = CProgressBar:create(_res('ui/battle/battle_blood_bg_5.png'))
    energyBar:setDirection(eProgressBarDirectionLeftToRight)
    energyBar:setPosition(cc.p(hpBar:getPositionX(), hpBar:getPositionY()))
    self:addChild(energyBar, 11)

	self.viewData.hpBar = hpBar
	self.viewData.energyBar = energyBar
	self.viewData.avatarShadow = avatarShadow
	self.viewData.clearTargetMark = nil
	self.viewData.clearTargetShadow = nil
end
---------------------------------------------------
-- init view end --
---------------------------------------------------

---------------------------------------------------
-- view controller begin --
---------------------------------------------------
--[[
@override
add buff
@params iconType BuffIconType 图标类型
@params value number 数值
--]]
function CardObjectView:addBuff(iconType, value)
	local iconPath = string.format('arts/battlebuffs/buff_icon_%d', checkint(iconType))
	local buffTag = checkint(iconType)

	if not BattleUtils.IsTable(value) and nil ~= tonumber(value) and value < 0 then
		iconPath = iconPath .. '_2'
		buffTag = ENEMY_TAG + buffTag
	end

	iconPath = iconPath .. '.png'

	local buffIcon = display.newNSprite(_res(iconPath), 0, 0)
    display.commonUIParams(buffIcon,
    	{ap = cc.p(0.5, 0)})
    buffIcon:setScale(0.25)
    self.viewData.hpBar:getParent():addChild(buffIcon, self.viewData.hpBar:getLocalZOrder())
    buffIcon:setTag(buffTag)

    table.insert(self.buffIcons, buffIcon)
    self:refreshBuffIcons()
end
--[[
@override
remove buff
@params iconType BuffIconType 图标类型
@params value number 数值
--]]
function CardObjectView:removeBuff(iconType, value)
	local buffTag = checkint(iconType)

	if not BattleUtils.IsTable(value) and nil ~= tonumber(value) and value < 0 then
		buffTag = ENEMY_TAG + buffTag
	end

	local buffIcon = nil
	for i = table.nums(self.buffIcons), 1, -1 do
		buffIcon = self.buffIcons[i]
		if buffTag == buffIcon:getTag() then
			table.remove(self.buffIcons, i)
			buffIcon:removeFromParent()
			break
		end
	end
	self:refreshBuffIcons()
end
--[[
@override
刷新buff坐标
--]]
function CardObjectView:refreshBuffIcons()
	local y = self.viewData.hpBar:getContentSize().height + 5
	local spaceW = 5
	display.setNodesToNodeOnCenter(self.viewData.hpBar, self.buffIcons, {y = y, spaceW = spaceW})
end
--[[
@override
显示被击特效
@params params table {
	hurtEffectId int 被击特效id
	hurtEffectPos cc.p 被击特效单位坐标
	hurtEffectZOrder int 被击特效层级
}
--]]
function CardObjectView:showHurtEffect(params)
	if nil == params.hurtEffectId or 0 == params.hurtEffectId then return end
	local effectName = 'hurt_' .. params.hurtEffectId
	local effectSpine = SpineCache(SpineCacheName.BATTLE):createWithName(effectName)
	if effectSpine then
		self.hurtEffects[tostring(ID(effectSpine))] = effectSpine

		effectSpine:update(0)
		effectSpine:setPosition(self:convertUnitPosToRealPos(params.hurtEffectPos))
		self:getAvatar():addChild(effectSpine, params.hurtEffectZOrder >= 0 and params.hurtEffectZOrder + 20 or -1)

		-- 翻转爆点方向
		effectSpine:setScaleX(-1 * effectSpine:getScaleX())
		-- 修正缩放
		effectSpine:setScaleX(effectSpine:getScaleX() * self:getSpineAvatarScale2Card())
		effectSpine:setScaleY(effectSpine:getScaleY() * self:getSpineAvatarScale2Card())

		effectSpine:setAnimation(0, sp.AnimationName.idle, false)
		effectSpine:registerSpineEventHandler(function (event)
			if sp.AnimationName.idle == event.animation then
				effectSpine:setVisible(false)
				effectSpine:performWithDelay(
					function ()
						self.hurtEffects[tostring(ID(effectSpine))] = nil
						effectSpine:clearTracks()
						effectSpine:unregisterSpineEventHandler(sp.EventType.ANIMATION_END)
						effectSpine:removeFromParent()
					end,
					(1 * cc.Director:getInstance():getAnimationInterval())
				)
			end
		end, sp.EventType.ANIMATION_END)
	end
end
--[[
@override
显示附加在人物身上的持续特效
@params v bool 是否可见
@params	bid string buff id
@params params table {
	attachEffectId int 特效id
	attachEffectPos cc.p 特效位置坐标
	attachEffectZOrder int 特效层级
}
--]]
function CardObjectView:showAttachEffect(v, bid, params)
	if nil == params.attachEffectId then return end
	
	local effectId = params.attachEffectId

	if nil == effectId or 0 == effectId then return end

	local effectSpine = self.attachEffects[tostring(effectId)]
	if nil == effectSpine then
		if v then
			local effectName = 'hurt_' .. params.attachEffectId
			effectSpine = SpineCache(SpineCacheName.BATTLE):createWithName(effectName)
			if nil == effectSpine then return end
			effectSpine:update(0)
			effectSpine:setPosition(self:convertUnitPosToRealPos(params.attachEffectPos))
			self:getAvatar():addChild(effectSpine, params.attachEffectZOrder >= 0 and params.attachEffectZOrder + 20 or -1)
			effectSpine:setVisible(false)
			self.attachEffects[tostring(effectId)] = effectSpine

			-- 修正缩放
			effectSpine:setScaleX(effectSpine:getScaleX() * self:getSpineAvatarScale2Card())
			effectSpine:setScaleY(effectSpine:getScaleY() * self:getSpineAvatarScale2Card())
		else
			return
		end
	end
	if v and not effectSpine:isVisible() then
		effectSpine:setVisible(true)
		effectSpine:setToSetupPose()
		effectSpine:setAnimation(0, sp.AnimationName.idle, true)
	else
		effectSpine:setVisible(false)
		effectSpine:clearTrack(0)
	end
end
--[[
@override
根据effect id移除附加特效
@params effectId int 特效id
--]]
function CardObjectView:RemoveAttachEffectByEffectId(effectId)
	local effectSpine = self.attachEffects[tostring(effectId)]
	if nil ~= effectSpine then
		effectSpine:setVisible(false)
		effectSpine:clearTrack(0)
		effectSpine:removeFromParent()
		self.attachEffects[tostring(effectId)] = nil
	end
end
--[[
@override
显示免疫提示
@params immuneType ImmuneType 免疫类型
--]]
function CardObjectView:showImmune(immuneType)
	local pos = self:convertUnitPosToRealPos(cc.p(0.5, 1))
	local remindLabel = display.newLabel(pos.x, pos.y,
		{text = __('免疫'), fontSize = 40, color = fontWithColor('BC').color, ttf = true, font = TTF_GAME_FONT})
	remindLabel:enableOutline(cc.c4b(0, 0, 0, 255), 1)
	self:addChild(remindLabel, 21)
	local actionSeq = cc.Sequence:create(
		cc.Spawn:create(
			cc.MoveBy:create(0.75, cc.p(0, 35)),
			cc.FadeTo:create(0.75, 0)
		),
		cc.RemoveSelf:create()
	)
	remindLabel:runAction(actionSeq)
end
--[[
@override
暂停
--]]
function CardObjectView:pauseView()
	BaseObjectView.pauseView(self)
	---------- 爆点 ----------
	for k,v in pairs(self.hurtEffects) do
		v:setTimeScale(0)
	end
	---------- 爆点 ----------

	---------- 附加效果 ----------
	for k,v in pairs(self.attachEffects) do
		if v:isVisible() then
			v:setTimeScale(0)
		end
	end
	---------- 附加效果 ----------

	---------- 目标mark ----------
	if nil ~= self.viewData.clearTargetShadow then
		if self.viewData.clearTargetShadow:isVisible() then
			self.viewData.clearTargetShadow:setTimeScale(0)
		end
	end
	---------- 目标mark ----------
end
--[[
@override
继续
--]]
function CardObjectView:resumeView()
	BaseObjectView.resumeView(self)
	---------- 爆点 ----------
	for k,v in pairs(self.hurtEffects) do
		v:setTimeScale(1)
	end
	---------- 爆点 ----------

	---------- 附加效果 ----------
	for k,v in pairs(self.attachEffects) do
		if v:isVisible() then
			v:setTimeScale(1)
		end
	end
	---------- 附加效果 ----------

	---------- 目标mark ----------
	if nil ~= self.viewData.clearTargetShadow then
		if self.viewData.clearTargetShadow:isVisible() then
			self.viewData.clearTargetShadow:setTimeScale(1)
		end
	end
	---------- 目标mark ----------
end
--[[
显示过关目标相关信息
@params stageCompleteType ConfigStageCompleteType 过关类型
@params show bool 是否显示
--]]
function CardObjectView:ShowStageClearTargetMark(stageCompleteType, show)
	if ConfigStageCompleteType.SLAY_ENEMY == stageCompleteType then
		self:ShowSlayStageClearTarget(show)
	elseif ConfigStageCompleteType.HEAL_FRIEND == stageCompleteType then
		self:ShowHealStageClearTarget(show)
	end
end
--[[
显示杀戮模式相关信息
@params show bool 是否显示
--]]
function CardObjectView:ShowSlayStageClearTarget(show)
	if nil == self.viewData.clearTargetMark then
		local clearTargetMark = display.newImageView(_res('ui/battle/battletarget/battle_target_ico_atk.png'), 0, 0)
		display.commonUIParams(clearTargetMark, {po = cc.p(
			self.viewData.hpBar:getPositionX() - self.viewData.hpBar:getContentSize().width * 0.5 - clearTargetMark:getContentSize().width * 0.5 + 10,
			self.viewData.hpBar:getPositionY()
		)})
		self.viewData.hpBar:getParent():addChild(clearTargetMark, self.viewData.hpBar:getLocalZOrder() + 10)
		clearTargetMark:setScale(0.6)

		self.viewData.clearTargetMark = clearTargetMark
	else
		self.viewData.clearTargetMark:setTexture(_res('ui/battle/battletarget/battle_target_ico_atk.png'))
	end

	if nil == self.viewData.clearTargetShadow then
		local clearTargetShadow = SpineCache(SpineCacheName.BATTLE):createWithName('wavetarget')
		clearTargetShadow:update(0)
		clearTargetShadow:setPosition(cc.p(0, 0))
		self:addChild(clearTargetShadow)
		clearTargetShadow:setScale(
			(self:getAvatarStaticViewBox().width / TargetShadowSpineSize.width * 0.5) * 2
		)

		self.viewData.clearTargetShadow = clearTargetShadow
	end

	if show then
		self.viewData.clearTargetMark:setVisible(true)
		self.viewData.clearTargetShadow:setVisible(true)
		self.viewData.clearTargetShadow:setToSetupPose()
		self.viewData.clearTargetShadow:setAnimation(0, sp.AnimationName.slaytarget, true)
	else
		self.viewData.clearTargetMark:setVisible(false)
		self.viewData.clearTargetShadow:setVisible(false)
		self.viewData.clearTargetShadow:clearTracks()
	end
end
--[[
显示治疗目标信息
@params show bool 是否显示
--]]
function CardObjectView:ShowHealStageClearTarget(show)
	if nil == self.viewData.clearTargetMark then
		local clearTargetMark = display.newImageView(_res('ui/battle/battletarget/battle_target_ico_heal.png'), 0, 0)
		display.commonUIParams(clearTargetMark, {po = cc.p(
			self.viewData.hpBar:getPositionX() - self.viewData.hpBar:getContentSize().width * 0.5 - clearTargetMark:getContentSize().width * 0.5 + 10,
			self.viewData.hpBar:getPositionY()
		)})
		self.viewData.hpBar:getParent():addChild(clearTargetMark, self.viewData.hpBar:getLocalZOrder() + 10)
		clearTargetMark:setScale(0.6)

		self.viewData.clearTargetMark = clearTargetMark
		
	else
		self.viewData.clearTargetMark:setTexture(_res('ui/battle/battletarget/battle_target_ico_heal.png'))
	end

	if nil == self.viewData.clearTargetShadow then
		local clearTargetShadow = SpineCache(SpineCacheName.BATTLE):createWithName('wavetarget')
		clearTargetShadow:update(0)
		clearTargetShadow:setPosition(cc.p(0, 0))
		self:addChild(clearTargetShadow)
		clearTargetShadow:setScale(
			(self:getAvatarStaticViewBox().width / TargetShadowSpineSize.width * 0.5) * 2
		)

		self.viewData.clearTargetShadow = clearTargetShadow
	end

	if show then
		self.viewData.clearTargetMark:setVisible(true)
		self.viewData.clearTargetShadow:setVisible(true)
		self.viewData.clearTargetShadow:setToSetupPose()
		self.viewData.clearTargetShadow:setAnimation(0, sp.AnimationName.healtarget, true)
	else
		self.viewData.clearTargetMark:setVisible(false)
		self.viewData.clearTargetShadow:setVisible(false)
		self.viewData.clearTargetShadow:clearTracks()
	end
end
--[[
隐藏所有目标mark
--]]
function CardObjectView:HideAllStageClearTargetMark()
	if nil ~= self.viewData.clearTargetMark then
		self.viewData.clearTargetMark:setVisible(false)
		self.viewData.clearTargetShadow:setVisible(false)
		self.viewData.clearTargetShadow:clearTracks()
	end
end
--[[
@override
显示周身ui
@params show bool 是否显示
--]]
function CardObjectView:ShowAllObjectUI(show)
	self.viewData.hpBar:setVisible(show)
	self.viewData.energyBar:setVisible(show)
	self:showAvatarShadow(show)

	for i,v in ipairs(self.buffIcons) do
		v:setVisible(show)
	end

	-- 目标mark
	if not show then
		if nil ~= self.viewData.clearTargetMark then
			self.viewData.clearTargetMark:setVisible(false)
		end

		if nil ~= self.viewData.clearTargetShadow then
			self.viewData.clearTargetShadow:setVisible(false)
			self.viewData.clearTargetShadow:clearTracks()
		end
	end
end
--[[
刷新血条
@params percent 血量百分比
--]]
function CardObjectView:updateHpBar(percent)
	local maxValue = HP_BAR_MAX_VALUE
	local value = math.ceil(maxValue * percent)
	self.viewData.hpBar:setMaxValue(maxValue)
	self.viewData.hpBar:setValue(value)
end
--[[
@override
进入下一波
@params nextWave int 下一波
--]]
function CardObjectView:enterNextWave(nextWave)
	
end
--[[
显示怪物阴影
@params show bool 是否显示
--]]
function CardObjectView:showAvatarShadow(show)
	if self:getForceHideAvatarShadow() then

	else
		self.viewData.avatarShadow:setVisible(show)
	end
end
--[[
刷新一次ui大小 位置
--]]
function CardObjectView:FixUIState()
	local avatar = self.avatar

	------------ 刷新根据spine avatar确定的变量 ------------
	self.staticViewBox = avatar:getBorderBox(sp.CustomName.VIEW_BOX)
	self.staticCollisionBox = avatar:getBorderBox(sp.CustomName.COLLISION_BOX)
	------------ 刷新根据spine avatar确定的变量 ------------

	------------ 刷新脚底阴影的大小 ------------
	self.viewData.avatarShadow:setScale(0.5 * (self:getAvatarStaticViewBox().width / self.viewData.avatarShadow:getContentSize().width))
	------------ 刷新脚底阴影的大小 ------------

	------------ 刷新血条和能量条位置 ------------
	local hpBarPosY = self:getAvatarStaticViewBox().height + 15
	self.viewData.hpBar:setPositionY(hpBarPosY)
	self.viewData.energyBar:setPositionY(hpBarPosY)
	------------ 刷新血条和能量条位置 ------------

	------------ 刷新buff icon 位置 ------------
	self:refreshBuffIcons()
	------------ 刷新buff icon 位置 ------------
end
---------------------------------------------------
-- view controller end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
@override
获取卡牌spine修正后的边界框信息
@params borderBox string 边界框名字
@return box cc.rect 边界框信息
--]]
function CardObjectView:getAvatarBorderBox(borderBox)
	local box = self:getAvatar():getBorderBox(borderBox)
	if nil == box then return nil end
	-- 根据外部缩放修正边界框大小
	box.x = box.x * self:getAvatarScale()
	box.y = box.y * self:getAvatarScale()
	box.width = box.width * self:getAvatarScale()
	box.height = box.height * self:getAvatarScale()
	-- 根据朝向修正边界框数据
	local towards = self:getAvatar():getScaleX()
	if 0 > towards then
		-- 反向
		box.x = -(box.x + box.width)
	end
	return box
end
--[[
@override
获取卡牌spine静态碰撞框信息
@return box cc.rect 边界框信息
--]]
function CardObjectView:getAvatarStaticCollisionBox()
	if nil == self.staticCollisionBox then return nil end
	local box = cc.rect(
		self.staticCollisionBox.x,
		self.staticCollisionBox.y,
		self.staticCollisionBox.width,
		self.staticCollisionBox.height
	)
	-- 根据外部缩放修正边界框大小
	box.x = box.x * self:getAvatarScale()
	box.y = box.y * self:getAvatarScale()
	box.width = box.width * self:getAvatarScale()
	box.height = box.height * self:getAvatarScale()
	-- 根据朝向修正边界框数据
	local towards = self:getAvatar():getScaleX()
	if 0 > towards then
		-- 反向
		box.x = -(box.x + box.width)
	end
	return box
end
--[[
@override
获取卡牌spine静态碰撞框信息
@return box cc.rect 边界框信息
--]]
function CardObjectView:getAvatarStaticViewBox()
	if nil == self.staticViewBox then return nil end
	local box = cc.rect(
		self.staticViewBox.x,
		self.staticViewBox.y,
		self.staticViewBox.width,
		self.staticViewBox.height
	)
	-- 根据外部缩放修正边界框大小
	box.x = box.x * self:getAvatarScale()
	box.y = box.y * self:getAvatarScale()
	box.width = box.width * self:getAvatarScale()
	box.height = box.height * self:getAvatarScale()
	-- 根据朝向修正边界框数据
	local towards = self:getAvatar():getScaleX()
	if 0 > towards then
		-- 反向
		box.x = -(box.x + box.width)
	end
	return box
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

---------------------------------------------------
-- action logic begin --
---------------------------------------------------
--[[
@override
杀死该单位 隐藏血条能量条阴影
--]]
function CardObjectView:killSelf()
	BaseObjectView.killSelf(self)
	
	-- 隐藏周身ui
	self:ShowAllObjectUI(false)
end
--[[
@override
view死亡
--]]
function CardObjectView:dieEnd()
	BaseObjectView.dieEnd(self)
end
--[[
@override
销毁view
--]]
function CardObjectView:destroy()
	BaseObjectView.destroy(self)
end
--[[
@override
复活
--]]
function CardObjectView:revive()
	BaseObjectView.revive(self)
	
	-- 显示周身ui
	self:ShowAllObjectUI(true)
end
---------------------------------------------------
-- action logic end --
---------------------------------------------------


return CardObjectView
