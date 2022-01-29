--[[
基础战斗物体view
@params t table {
	spineId int 动画spineId
}
--]]
local BaseObjectView = __Require('battle.objectView.cardObject.BaseObjectView')
local CardObjectView = class('CardObjectView', BaseObjectView)

------------ import ------------
local ExpressionNode = require('common.ExpressionNode')
local CardSpine = require('Frame.gui.CardSpine')
------------ import ------------

------------ define ------------
local TargetShadowSpineSize = cc.size(245, 245)

-- 物体view中zorder
local ObjectViewZOrder = {
	QTEAttachViewZOrder = 20 			-- qte物体zorder
}

-- buff icon缩放
local BUFF_ICON_SCALE = 0.25
------------ define ------------

---------------------------------------------------
-- init view begin --
---------------------------------------------------
--[[
@override
初始化数值
--]]
function CardObjectView:InitValue()
	BaseObjectView.InitValue(self)

	------------ 判断一次怪物阴影 ------------
	local cardConfig = CardUtils.GetCardConfig(self:GetVCardId())
	if nil ~= cardConfig and ConfigMonsterFormType.COMMODE == checkint(cardConfig.formType) then
		self:SetForceHideAvatarShadow(true)
	end
	------------ 判断一次怪物阴影 ------------
end
--[[
@override
初始化视图
--]]
function CardObjectView:InitView()
	BaseObjectView.InitView(self)
end
--[[
@override
创建spine avatar
--]]
function CardObjectView:InitSpineAvatarNode()
	-- 处理骨骼动画名字
	local spineName = self:GetSpineNameBySpineId(self:GetVSpineId(), self:GetVCardId())
	local spineTowards = 1

	local avatar = CardSpine.new({
		skinId = self:GetVSkinId(),
		scale = G_BattleRenderMgr:GetSpineAvatarScaleByCardId(self:GetVCardId()),
		animationCacheName = spineName,
		cache = SpineCacheName.BATTLE,
		oriAnimationInfo = BattleUtils.GetAvatarSpineDataStructBySpineId(
			self:GetVSpineId(),
			G_BattleRenderMgr:GetSpineAvatarScaleByCardId(self:GetVCardId())
		),
		downloadOverCallback = handler(self, self.FixUIState)
	})
	-- local avatar = SpineCache(SpineCacheName.BATTLE):createWithName(spineName)

	-- 进行缩放
	avatar:setScale(self:GetAvatarScale())
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
	avatarShadow:setScale(0.5 * (self:GetAvatarStaticViewBox().width / avatarShadow:getContentSize().width))
	avatarShadow:setVisible(not self:GetForceHideAvatarShadow())

	-- hp bar
	local hpBarPath = 'ui/battle/battle_blood_bg_2.png'
	if self:GetVEnemy() then
		hpBarPath = 'ui/battle/battle_blood_bg_2_red.png'
	end
	local hpBar = CProgressBar:create(_res(hpBarPath))
    hpBar:setBackgroundImage(_res('ui/battle/battle_blood_bg_4.png'))
    hpBar:setDirection(eProgressBarDirectionLeftToRight)
    hpBar:setPosition(cc.p(bgSize.width * 0.5, self:GetAvatarStaticViewBox().height + 15))
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
-- view control begin --
---------------------------------------------------
--[[
@override
添加一个attach object view
@params view BaseAttachObjectView
--]]
function CardObjectView:AddAAttachView(view)
	self:addChild(view, ObjectViewZOrder.QTEAttachViewZOrder)
end
--[[
@override
刷新一次ui大小 位置
--]]
function CardObjectView:FixUIState()
	local avatar = self:GetAvatar()

	------------ 刷新根据spine avatar确定的变量 ------------
	self.staticViewBox = avatar:getBorderBox(sp.CustomName.VIEW_BOX)
	self.staticCollisionBox = avatar:getBorderBox(sp.CustomName.COLLISION_BOX)
	------------ 刷新根据spine avatar确定的变量 ------------

	------------ 刷新脚底阴影的大小 ------------
	self.viewData.avatarShadow:setScale(0.5 * (self:GetAvatarStaticViewBox().width / self.viewData.avatarShadow:getContentSize().width))
	------------ 刷新脚底阴影的大小 ------------

	------------ 刷新血条和能量条位置 ------------
	local hpBarPosY = self:GetAvatarStaticViewBox().height + 15
	self.viewData.hpBar:setPositionY(hpBarPosY)
	self.viewData.energyBar:setPositionY(hpBarPosY)
	------------ 刷新血条和能量条位置 ------------

	------------ 刷新buff icon 位置 ------------
	self:RefreshBuffIcons()
	------------ 刷新buff icon 位置 ------------
end
--[[
@override
设置引导中高亮
--]]
function CardObjectView:SetObjectHighlightInGuide(highlight)
	local fixedZOrder = highlight and G_BattleRenderMgr:GetFixedHighlightZOrder() or -1 * G_BattleRenderMgr:GetFixedHighlightZOrder()
	self:setLocalZOrder(self:getLocalZOrder() + fixedZOrder)
end
---------------------------------------------------
-- view control end --
---------------------------------------------------

---------------------------------------------------
-- object ui control begin --
---------------------------------------------------
--[[
@override
显示周身ui
@params show bool 是否显示
--]]
function CardObjectView:ShowAllObjectUI(show)
	-- 血条 能量条
	self:ShowHpBar(show)
	self:ShowEnergyBar(show)
	-- 脚下阴影
	self:ShowAvatarShadow(show)

	-- buff相关显示
	self:ShowAllBuffIcons(show)
	self:ShowAllHurtEffects(show)
	self:ShowAllAttachEffects(show)

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
@override
显示怪物阴影
@params show bool 是否显示
--]]
function CardObjectView:ShowAvatarShadow(show)
	if self:GetForceHideAvatarShadow() then
		-- 外部强制操作卡牌阴影时不处理
	else
		self.viewData.avatarShadow:setVisible(show)
	end
end
--[[
@override
显示血条
@params show bool 是否显示
--]]
function CardObjectView:ShowHpBar(show)
	-- 血条
	self.viewData.hpBar:setVisible(show)
end
--[[
@override
显示能量条
@params show bool 是否显示
--]]
function CardObjectView:ShowEnergyBar(show)
	-- 能量条
	self.viewData.energyBar:setVisible(show)
end
---------------------------------------------------
-- object ui control end --
---------------------------------------------------

---------------------------------------------------
-- hp energy control begin --
---------------------------------------------------
--[[
@override
刷新血条
@params percent 血量百分比
--]]
function CardObjectView:UpdateHpBar(percent)
	local maxValue = HP_BAR_MAX_VALUE
	local value = math.ceil(maxValue * percent)
	self.viewData.hpBar:setMaxValue(maxValue)
	self.viewData.hpBar:setValue(value)
end
--[[
@override
刷新能量条
@params percent 能量百分比
--]]
function CardObjectView:UpdateEnergyBar(percent)
	local maxValue = HP_BAR_MAX_VALUE
	local value = math.ceil(maxValue * percent)
	self.viewData.energyBar:setMaxValue(maxValue)
	self.viewData.energyBar:setValue(value)
end
---------------------------------------------------
-- hp energy control end --
---------------------------------------------------

---------------------------------------------------
-- pause control begin --
---------------------------------------------------
--[[
@override
暂停
--]]
function CardObjectView:PauseView()
	BaseObjectView.PauseView(self)
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
function CardObjectView:ResumeView()
	BaseObjectView.ResumeView(self)
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
---------------------------------------------------
-- pause control end --
---------------------------------------------------

---------------------------------------------------
-- buff control begin --
---------------------------------------------------
--[[
@override
add buff
@params iconType BuffIconType 图标类型
@params value number 数值
--]]
function CardObjectView:AddBuff(iconType, value)
	local iconPath = self:GetBuffIconPath(iconType, value)
	local buffTag = self:GetBuffIconTag(iconType, value)

    local buffIcon = display.newNSprite(_res(iconPath), 0, 0)
    display.commonUIParams(buffIcon, {ap = cc.p(0.5, 0)})
    buffIcon:setScale(BUFF_ICON_SCALE)
    self.viewData.hpBar:getParent():addChild(buffIcon, self.viewData.hpBar:getLocalZOrder())
    buffIcon:setTag(buffTag)

    table.insert(self.buffIcons, buffIcon)
    self:RefreshBuffIcons()
end
--[[
@override
remove buff
@params iconType BuffIconType 图标类型
@params value number 数值
--]]
function CardObjectView:RemoveBuff(iconType, value)
	local buffTag = self:GetBuffIconTag(iconType, value)
	local buffIcon = nil

	for i = #self.buffIcons, 1, -1 do
		buffIcon = self.buffIcons[i]
		if buffTag == buffIcon:getTag() then
			table.remove(self.buffIcons, i)
			buffIcon:removeFromParent()
			break
		end
	end
	self:RefreshBuffIcons()
end
--[[
@override
刷新buff坐标
--]]
function CardObjectView:RefreshBuffIcons()
	local y = self.viewData.hpBar:getContentSize().height + 5
	local spaceW = 5
	display.setNodesToNodeOnCenter(self.viewData.hpBar, self.buffIcons, {y = y, spaceW = spaceW})
end
--[[
@override
显示被击特效
@params effectData HurtEffectStruct 被击特效数据
--]]
function CardObjectView:ShowHurtEffect(effectData)
	if nil == effectData then return end

	local effectId = effectData.effectId

	if nil == effectId or '' == effectId or '0' == tostring(effectId) then return end

	local effectCacheName = BattleUtils.GetHurtAniNameById(effectId)
	local effectSpine = SpineCache(SpineCacheName.BATTLE):createWithName(effectCacheName)

	if effectSpine then

		self.hurtEffects[tostring(ID(effectSpine))] = effectSpine

		effectSpine:update(0)
		effectSpine:setPosition(self:ConvertUnitPosToRealPos(effectData.effectPos))
		self:GetAvatar():addChild(effectSpine, effectData.effectZOrder >= 0 and effectData.effectZOrder + 20 or -1)

		-- 翻转爆点方向
		effectSpine:setScaleX(-1 * effectSpine:getScaleX())

		-- 修正缩放
		effectSpine:setScaleX(effectSpine:getScaleX() * self:GetSpineAvatarScale2Card())
		effectSpine:setScaleY(effectSpine:getScaleY() * self:GetSpineAvatarScale2Card())

		-- 被击爆点只播放一次
		effectSpine:setAnimation(0, sp.AnimationName.idle, false)

		effectSpine:registerSpineEventHandler(
			function (event)
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
			end,
			sp.EventType.ANIMATION_END
		)

	end
end
--[[
@override
显示附加在人物身上的持续特效
@params visible bool 是否可见
@params	buffId string buff id
@params effectData AttachEffectStruct 被击特效数据
--]]
function CardObjectView:ShowAttachEffect(visible, buffId, effectData)
	if nil == effectData then return end
	
	local effectId = effectData.effectId

	if nil == effectId or '' == effectId or '0' == tostring(effectId) then return end

	local effectSpine = self.attachEffects[tostring(effectId)]
	if nil == effectSpine then

		if visible then

			local effectCacheName = BattleUtils.GetHurtAniNameById(effectId)
			effectSpine = SpineCache(SpineCacheName.BATTLE):createWithName(effectCacheName)

			if effectSpine then

				self.attachEffects[tostring(effectId)] = effectSpine

				effectSpine:update(0)
				effectSpine:setPosition(self:ConvertUnitPosToRealPos(effectData.effectPos))
				self:GetAvatar():addChild(effectSpine, effectData.effectZOrder >= 0 and effectData.effectZOrder + 20 or -1)
				effectSpine:setVisible(false)

				-- 修正缩放
				effectSpine:setScaleX(effectSpine:getScaleX() * self:GetSpineAvatarScale2Card())
				effectSpine:setScaleY(effectSpine:getScaleY() * self:GetSpineAvatarScale2Card())

			end

		else
			return
		end

	end

	if visible and not effectSpine:isVisible() then
		effectSpine:setVisible(true)
		effectSpine:setToSetupPose()
		effectSpine:setAnimation(0, sp.AnimationName.idle, true)
	else
		effectSpine:setVisible(false)
		effectSpine:clearTrack(0)
	end
end
--[[
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
---------------------------------------------------
-- buff control end --
---------------------------------------------------

---------------------------------------------------
-- expression begin --
---------------------------------------------------
--[[
@override
显示免疫提示
@params immuneType ImmuneType 免疫类型
--]]
function CardObjectView:ShowImmune(immuneType)
	local pos = self:ConvertUnitPosToRealPos(cc.p(0.5, 1))
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
---------------------------------------------------
-- expression end --
---------------------------------------------------

---------------------------------------------------
-- tint begin --
---------------------------------------------------
--[[
@override
设置一次物体颜色
@params color cc.c3b
--]]
function CardObjectView:SetObjectViewColor(color)
	self:GetAvatar():setColor(color)
end
---------------------------------------------------
-- tint end --
---------------------------------------------------

---------------------------------------------------
-- view transform begin --
---------------------------------------------------
--[[
@override
物体开始变形
@params oriSkinId int 源皮肤id
@params oriActionName string 源皮肤变形的动作
@params targetSkinId int 目标皮肤id
@params targetActionName string 目标皮肤变形的衔接动作@
--]]
function CardObjectView:StartViewTransform(oriSkinId, oriActionName, targetSkinId, targetActionName)
	local avatar = self:GetAvatar()

	-- 先让源avatar做动作
	avatar:setToSetupPose()
	avatar:setAnimation(0, oriActionName, false)

	-- 创建目标avatar
	local targetSkinConfig = CardUtils.GetCardSkinConfig(targetSkinId)
	if nil ~= targetSkinConfig then

		local spineId = targetSkinConfig.spineId
		local targetSpineName = self:GetSpineNameBySpineId(spineId, self:GetVCardId())
		local targetAvatar = CardSpine.new({
			skinId = targetSkinId,
			scale = G_BattleRenderMgr:GetSpineAvatarScaleByCardId(self:GetVCardId()),
			animationCacheName = targetSpineName,
			cache = SpineCacheName.BATTLE,
			oriAnimationInfo = BattleUtils.GetAvatarSpineDataStructBySpineId(
				spineId,
				G_BattleRenderMgr:GetSpineAvatarScaleByCardId(self:GetVCardId())
			),
			downloadOverCallback = handler(self, self.FixUIState)
		})

		-- 进行缩放
		targetAvatar:setScale(self:GetAvatarScale())
		targetAvatar:setAnimation(0, targetActionName, false)
		targetAvatar:update(0)
		targetAvatar:clearTrack(0)

		targetAvatar:setPosition(cc.p(0, 0))
		self:addChild(targetAvatar, 5)

		targetAvatar:setVisible(false)

		self.viewTransformAvatar = targetAvatar
	end
end
--[[
@override
物体进行变形替换
@params oriSkinId int 源皮肤id
@params oriActionName string 源皮肤变形的动作
@params targetSkinId int 目标皮肤id
@params targetActionName string 目标皮肤变形的衔接动作
--]]
function CardObjectView:DoViewTransform(oriSkinId, oriActionName, targetSkinId, targetActionName)
	local preAvatar = self:GetAvatar()
	local preTowards = preAvatar:getScaleX() / math.abs(preAvatar:getScaleX())

	preAvatar:setVisible(false)
	preAvatar:clearTracks()

	-- 直接移除老的avatar
	preAvatar:runAction(cc.RemoveSelf:create())

	if nil ~= self.viewTransformAvatar then
		self.avatar = self.viewTransformAvatar
		local avatar = self:GetAvatar()

		-- 设置朝向
		avatar:setScaleX(preTowards)

		-- avatar:setToSetupPose()
		avatar:setAnimation(0, targetActionName, false)
		avatar:addAnimation(0, sp.AnimationName.idle, true)

		-- 设置可见
		avatar:setVisible(true)

		-- 动作完成后刷新一次ui状态
		local animationData = self:GetSpineAnimationDataByAnimationName(targetActionName)
		local actionTime = 0
		if nil ~= animationData then
			actionTime = checknumber(animationData.duration)
		end
		local actionSeq = cc.Sequence:create(
			cc.DelayTime:create(actionTime),
			cc.CallFunc:create(function ()
				self:FixUIState()
			end)
		)
		self:runAction(actionSeq)
	end
end
---------------------------------------------------
-- view transform end --
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
function CardObjectView:GetAvatarBorderBox(borderBox)
	local box = self:GetAvatar():getBorderBox(borderBox)
	if nil == box then return nil end
	-- 根据外部缩放修正边界框大小
	box.x = box.x * self:GetAvatarScale()
	box.y = box.y * self:GetAvatarScale()
	box.width = box.width * self:GetAvatarScale()
	box.height = box.height * self:GetAvatarScale()
	-- 根据朝向修正边界框数据
	local towards = self:GetAvatar():getScaleX()
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
function CardObjectView:GetAvatarStaticCollisionBox()
	if nil == self.staticCollisionBox then return nil end
	local box = cc.rect(
		self.staticCollisionBox.x,
		self.staticCollisionBox.y,
		self.staticCollisionBox.width,
		self.staticCollisionBox.height
	)
	-- 根据外部缩放修正边界框大小
	box.x = box.x * self:GetAvatarScale()
	box.y = box.y * self:GetAvatarScale()
	box.width = box.width * self:GetAvatarScale()
	box.height = box.height * self:GetAvatarScale()
	-- 根据朝向修正边界框数据
	local towards = self:GetAvatar():getScaleX()
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
function CardObjectView:GetAvatarStaticViewBox()
	if nil == self.staticViewBox then return nil end
	local box = cc.rect(
		self.staticViewBox.x,
		self.staticViewBox.y,
		self.staticViewBox.width,
		self.staticViewBox.height
	)
	-- 根据外部缩放修正边界框大小
	box.x = box.x * self:GetAvatarScale()
	box.y = box.y * self:GetAvatarScale()
	box.width = box.width * self:GetAvatarScale()
	box.height = box.height * self:GetAvatarScale()
	-- 根据朝向修正边界框数据
	local towards = self:GetAvatar():getScaleX()
	if 0 > towards then
		-- 反向
		box.x = -(box.x + box.width)
	end
	return box
end
--[[
根据骨骼名字获取骨骼的坐标信息
@params boneName string 骨骼名字
@return result {
	name,
	x, y, worldX, worldY,
	scaleX, scaleY, rotation
}
--]]
function CardObjectView:FindBoneInAvatar(boneName)
	return self:GetAvatar() and self:GetAvatar():findBone(boneName) or nil
end
--[[
根据骨骼名字获取骨骼的世界坐标
@params boneName string 骨骼名字
@return worldPos cc.p 世界坐标
--]]
function CardObjectView:FindBoneInAvatarByWorldPos(boneName)
	local boneData = self:FindBoneInAvatar(boneName)
	if nil ~= boneData then
		local worldPos = self:GetAvatar():convertToWorldSpace(cc.p(boneData.worldX, boneData.worldY))
		return worldPos
	else
		return nil
	end
end
---------------------------------------------------
-- get set end --
---------------------------------------------------










































































---------------------------------------------------
-- view controller begin --
---------------------------------------------------
--[[
@override
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
		local clearTargetShadow = SpineCache(SpineCacheName.BATTLE):createWithName(sp.AniCacheName.WAVE_TARGET_MARK)
		clearTargetShadow:update(0)
		clearTargetShadow:setPosition(cc.p(0, 0))
		self:addChild(clearTargetShadow)
		clearTargetShadow:setScale(
			(self:GetAvatarStaticViewBox().width / TargetShadowSpineSize.width * 0.5) * 2
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
@override
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
		local clearTargetShadow = SpineCache(SpineCacheName.BATTLE):createWithName(sp.AniCacheName.WAVE_TARGET_MARK)
		clearTargetShadow:update(0)
		clearTargetShadow:setPosition(cc.p(0, 0))
		self:addChild(clearTargetShadow)
		clearTargetShadow:setScale(
			(self:GetAvatarStaticViewBox().width / TargetShadowSpineSize.width * 0.5) * 2
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
@override
隐藏所有目标mark
--]]
function CardObjectView:HideAllStageClearTargetMark()
	if nil ~= self.viewData.clearTargetMark then
		self.viewData.clearTargetMark:setVisible(false)
	end

	if nil ~= self.viewData.clearTargetShadow then
		self.viewData.clearTargetShadow:setVisible(false)
		self.viewData.clearTargetShadow:clearTracks()
	end
end
---------------------------------------------------
-- view controller end --
---------------------------------------------------


return CardObjectView
