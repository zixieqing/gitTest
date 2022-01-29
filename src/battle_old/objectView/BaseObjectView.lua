--[[
基础战斗物体view
@params t table {
	tag int obj tag 此tag与战斗物体逻辑层tag对应
	viewInfo ObjectViewConstructStruct 展示层信息
}
--]]
local BaseObjectView = class('BaseObjectView', function ()
	local node = CLayout:create()
	node.name = 'battle.obiectView.BaseObjectView'
	node:enableNodeEvents()
	return node
end)

------------ import ------------
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
local ExpressionNode = require('common.ExpressionNode')
------------ import ------------

--[[
constructor
--]]
function BaseObjectView:ctor( ... )
	local args = unpack({...})
	self.idInfo = {
		tag = args.tag
	}
	self.viewInfo = args.viewInfo
	self.staticViewBox = nil
	self.staticCollisionBox = nil

	self.viewData = {}
	self.avatar = nil

	-- buff图标
	self.buffIcons = {}
	-- 附加效果
	self.attachEffects = {}
	-- 爆点效果
	self.hurtEffects = {}

	self:initValue()
	self:initSpineId()
	self:initView()
end
---------------------------------------------------
-- init view begin --
---------------------------------------------------
--[[
初始化数值
--]]
function BaseObjectView:initValue()
	self.forceHideAvatarShadow = false
end
--[[
初始化视图
--]]
function BaseObjectView:initView()
	-- 创建spine avatar
	self:InitSpineAvatarNode()
	-- 创建其他的ui
	self:InitUI()
end
--[[
创建spine avatar
--]]
function BaseObjectView:InitSpineAvatarNode()

end
--[[
创建ui
--]]
function BaseObjectView:InitUI()

end
--[[
初始化spine id
--]]
function BaseObjectView:initSpineId()
	self.spineId = nil

	if nil ~= self:getVSkinId() then
		local skinConfig = CardUtils.GetCardSkinConfig(self:getVSkinId())
		if nil ~= skinConfig then
			self.spineId = tostring(skinConfig.spineId)
		end
	end
end
---------------------------------------------------
-- init view end --
---------------------------------------------------

---------------------------------------------------
-- view controller begin --
---------------------------------------------------
--[[
add buff
@params iconType BuffIconType 图标类型
@params value number 数值
--]]
function BaseObjectView:addBuff(iconType, value)

end
--[[
remove buff
@params iconType BuffIconType 图标类型
@params value number 数值
--]]
function BaseObjectView:removeBuff(iconType, value)

end
--[[
刷新buff坐标
--]]
function BaseObjectView:refreshBuffIcons()

end
--[[
显示被打断时的效果
@params weakPointId ConfigWeakPointId 弱点效果id
--]]
function BaseObjectView:showChantBreakEffect(weakPointId)
	local remindLabelActionSeq = nil
	local remindLabelPath = nil
	local fps = 30

	if ConfigWeakPointId.BREAK == weakPointId then

		self:showExpression(ExpressionType.EMBRARASSED)
		remindLabelPath = 'ui/battle/expression_word_3.png'

		local deltaP1 = cc.p(0, 30)
		local deltaP2 = cc.p(0, 80)

		remindLabelActionSeq = cc.Sequence:create(
			cc.Spawn:create(
				cc.FadeTo:create(6 / fps, 255),
				cc.ScaleTo:create(6 / fps, 1)
			),
			cc.MoveBy:create(24 / fps, deltaP1),
			cc.Spawn:create(
				cc.MoveBy:create(7 / fps, deltaP2),
				cc.FadeTo:create(7 / fps, 0)
			),
			cc.RemoveSelf:create()
		)

	elseif ConfigWeakPointId.HALF_EFFECT == weakPointId then

		self:showExpression(ExpressionType.SWEAT)
		remindLabelPath = 'ui/battle/expression_word_2.png'

		local deltaP1 = cc.p(0, 20)
		local deltaP2 = cc.p(0, 40)
		local deltaP3 = cc.p(0, -60)

		remindLabelActionSeq = cc.Sequence:create(
			cc.Spawn:create(
				cc.ScaleTo:create(5 / fps, 1),
				cc.FadeTo:create(5 / fps, 255)
			),
			cc.MoveBy:create(19 / fps, deltaP1),
			cc.MoveBy:create(5 / fps, deltaP2),
			cc.Spawn:create(
				cc.FadeTo:create(8 / fps, 0),
				cc.ScaleTo:create(8 / fps, 0),
				cc.MoveBy:create(8 / fps, deltaP3)
			),
			cc.RemoveSelf:create()
		)

	elseif ConfigWeakPointId.NONE == weakPointId then
		self:showExpression(ExpressionType.PLEASED)
		remindLabelPath = 'ui/battle/expression_word_1.png'

		local deltaP1 = cc.p(0, -10)
		local deltaP2 = cc.p(0, -50)

		remindLabelActionSeq = cc.Sequence:create(
			cc.Spawn:create(
				cc.FadeTo:create(6 / fps, 255),
				cc.ScaleTo:create(6 / fps, 1),
				cc.RotateBy:create(6 / fps, 10)
			),
			cc.MoveBy:create(18 / fps, deltaP1),
			cc.Spawn:create(
				cc.MoveBy:create(12 / fps, deltaP2),
				cc.FadeTo:create(12 / fps, 0)
			),
			cc.RemoveSelf:create()
		)

	end

	if nil ~= remindLabelPath then
		local viewBox = self:getAvatarStaticViewBox()
		local remindLabel = display.newNSprite(_res(remindLabelPath), viewBox.width * 0.25, viewBox.height * 0.75)
		self:addChild(remindLabel, 20)
		remindLabel:setTag(358)

		remindLabel:setScale(2)
		remindLabel:setOpacity(0)

		if nil ~= remindLabelActionSeq then
			remindLabel:runAction(remindLabelActionSeq)
		end
	end
end
--[[
显示表情
@params expressionType ExpressionType 表情类型
--]]
function BaseObjectView:showExpression(expressionType)
	local expressionNode = ExpressionNode.new({nodeType = expressionType})
	self:addChild(expressionNode, 20)
	local viewBox = self:getAvatarStaticViewBox()
	expressionNode:setPosition(cc.p(viewBox.width * 0.55, viewBox.height * 0.85))
	expressionNode:setTag(357)

	local fps = 30
	local oriScale = 0.75
	local deltaP1 = cc.p(30, 30)
	local deltaP2 = cc.p(10, 10)
	local deltaP3 = cc.p(20, 20)
	expressionNode:setScale(0)
	expressionNode:setOpacity(0)

	local actionSeq = cc.Sequence:create(
		cc.Spawn:create(
			cc.ScaleTo:create(10 / fps, oriScale),
			cc.MoveBy:create(10 / fps, deltaP1),
			cc.FadeTo:create(10 / fps, 255)
		),
		cc.MoveBy:create(28 / fps, deltaP2),
		cc.Spawn:create(
			cc.ScaleTo:create(8 / fps, oriScale * 1.1),
			cc.MoveBy:create(8 / fps, deltaP3),
			cc.FadeTo:create(8 / fps, 0)
		),
		cc.RemoveSelf:create()
	)
	expressionNode:runAction(actionSeq)
end
--[[
显示被击特效
@params params table {
	hurtEffectId int 被击特效id
	hurtEffectPos cc.p 被击特效单位坐标
	hurtEffectZOrder int 被击特效层级
}
--]]
function BaseObjectView:showHurtEffect(params)

end
--[[
显示附加在人物身上的持续特效
@params v bool 是否可见
@params	bid string buff id
@params params table {
	attachEffectId int 特效id
	attachEffectPos cc.p 特效位置坐标
	attachEffectZOrder int 特效层级
}
--]]
function BaseObjectView:showAttachEffect(v, bid, params)

end
--[[
根据effect id移除附加特效
@params effectId int 特效id
--]]
function BaseObjectView:RemoveAttachEffectByEffectId(effectId)

end
--[[
显示免疫提示
@params immuneType ImmuneType 免疫类型
--]]
function BaseObjectView:showImmune(immuneType)

end
--[[
显示对话气泡
@params dialogueFrameType int 对话框气泡类型
@params content string 对话内容
@params actionDelay number action延迟
@params disappearCallback function 对话框开始消失时的回调函数
--]]
function BaseObjectView:showDialogue(dialogueFrameType, content, actionDelay, disappearCallback)
	local DIALOG_BG = nil

	if BattleConfigUtils:UseElexLocalize() or BattleConfigUtils:UseJapanLocalize() then
		DIALOG_BG = {
			['1'] = {id = 1, name = 'dialogue_bg_1', offset = cc.p(43, 21), size = cc.size(766, 138)},
			['2'] = {id = 2, name = 'dialogue_bg_2', offset = cc.p(87, 36), size = cc.size(650, 144)},
			['3'] = {id = 3, name = 'dialogue_bg_3', offset = cc.p(119, 61), size = cc.size(588,174)},
			['4'] = {id = 4, name = 'dialogue_bg_4', offset = cc.p(69, 74), size = cc.size(530, 140)},
			['5'] = {id = 5, name = 'dialogue_bg_5', offset = cc.p(71, 66), size = cc.size(660,142)},
			['6'] = {id = 6, name = 'dialogue_bg_6', offset = cc.p(68, 45), size = cc.size(662, 140)}
		}
	else
		DIALOG_BG = {
			['1'] = {id = 1, name = 'dialogue_bg_1', offset = cc.p(30, 26), size = cc.size(780, 132)},
			['2'] = {id = 2, name = 'dialogue_bg_2', offset = cc.p(44, 56), size = cc.size(472, 102)},
			['3'] = {id = 3, name = 'dialogue_bg_3', offset = cc.p(57, 53), size = cc.size(436, 128)},
			['4'] = {id = 4, name = 'dialogue_bg_4', offset = cc.p(59, 84), size = cc.size(322, 102)},
			['5'] = {id = 5, name = 'dialogue_bg_5', offset = cc.p(44, 50), size = cc.size(444, 98)},
			['6'] = {id = 6, name = 'dialogue_bg_6', offset = cc.p(68, 46), size = cc.size(498, 126)}
		}
	end

	------------ 创建对话内容 ------------
	-- 对话框初始位置
	local viewBox = self:getAvatarStaticViewBox()
	local dialogueConfig = DIALOG_BG[tostring(dialogueFrameType)]
	local dialogueFrame = display.newImageView(string.format('arts/stage/ui/%s.png', dialogueConfig.name), 0, 0)
	local dialogueSize = dialogueFrame:getContentSize()
	local contentLabel = display.newLabel(dialogueConfig.offset.x, dialogueSize.height - dialogueConfig.offset.y,
		{fontSize = 22, color = '6c6c6c', text = content, ap = cc.p(0, 1), hAlign = display.TAL,
		w = dialogueConfig.size.width, h = dialogueConfig.size.height}
	)
	dialogueFrame:addChild(contentLabel, 3)

	BMediator:GetBattleRoot():addChild(dialogueFrame, BATTLE_E_ZORDER.DIALOGUE)

	local dialogueOriginalPos = cc.p(self:getPositionX(), self:getPositionY() + viewBox.height * 0.5)
	display.commonUIParams(dialogueFrame, {po = dialogueOriginalPos})

	local finalScale = 1.25
	local dialoguePos = cc.p(0, self:getPositionY() + viewBox.height * 0.65)
	local battleRootSize = BMediator:GetBattleRoot():getContentSize()
	if battleRootSize.width * 0.5 < self:getPositionX() then
		-- 人物在战斗场景右半场
		dialoguePos.x = math.max(
			(battleRootSize.width - display.width) * 0.5 + dialogueSize.width * 0.5 * finalScale,
			self:getPositionX() - dialogueSize.width * 0.5 * finalScale - viewBox.width * 0.1
		)
	else
		-- 人物在战斗场景左半场
		dialoguePos.x = math.min(
			(battleRootSize.width + display.width) * 0.5 - dialogueSize.width * 0.5 * finalScale,
			self:getPositionX() + dialogueSize.width * 0.5 * finalScale + viewBox.width * 0.1
		)
	end
	------------ 创建对话内容 ------------

	------------ 对话内容动画 ------------
	-- 初始化对话框动画状态
	dialogueFrame:setOpacity(0)
	contentLabel:setVisible(false)

	local duration = string.utf8len(content) * 0.05
	local dialogueActionSeq = cc.Sequence:create(
		cc.Spawn:create(
			cc.MoveTo:create(0.2, dialoguePos),
			cc.FadeTo:create(0.2, 255)
		),
		cc.CallFunc:create(function ()
			-- 开始打字
			local writer = TypewriterAction:create(duration)
			local typeActionSeq = cc.Sequence:create(
				writer
			)
			contentLabel:runAction(typeActionSeq)
		end),
		cc.ScaleTo:create(duration + 1, 1.03),
		cc.CallFunc:create(function ()
			if nil ~= disappearCallback then
				disappearCallback()
			end
		end),
		cc.Spawn:create(
			cc.ScaleTo:create(0.1, finalScale),
			cc.FadeTo:create(0.1, 0)
		),
		cc.RemoveSelf:create()
	)

	dialogueFrame:runAction(dialogueActionSeq)
	------------ 对话内容动画 ------------
end
--[[
暂停
--]]
function BaseObjectView:pauseView()

end
--[[
继续
--]]
function BaseObjectView:resumeView()
	
end
--[[
刷新血条
@params percent 血量百分比
--]]
function BaseObjectView:updateHpBar(percent)
	
end
--[[
进入下一波
@params nextWave int 下一波
--]]
function BaseObjectView:enterNextWave(nextWave)
	
end
--[[
显示怪物阴影
@params show bool 是否显示
--]]
function BaseObjectView:showAvatarShadow(show)

end
---------------------------------------------------
-- view controller end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
获取展示层tag
--]]
function BaseObjectView:getVTag()
	return self.idInfo.tag
end
--[[
获取卡牌id
--]]
function BaseObjectView:getVCardId()
	return self.viewInfo.cardId
end
--[[
获取spineid
--]]
function BaseObjectView:getVSpineId()
	return self.spineId
end
--[[
获取皮肤id
--]]
function BaseObjectView:getVSkinId()
	return self.viewInfo.skinId
end
--[[
获取卡牌avatar缩放比
--]]
function BaseObjectView:getAvatarScale()
	return self.viewInfo.avatarScale
end
--[[
获取avatar相对于卡牌的缩放比
--]]
function BaseObjectView:getSpineAvatarScale2Card()
	return self.viewInfo.avatarScale2Card
end
--[[
获取敌友性
@return _ bool 敌友性
--]]
function BaseObjectView:getVEnemy()
	return self.viewInfo.isEnemy
end
--[[
获取核心人物层
--]]
function BaseObjectView:getAvatar()
	return self.avatar
end
--[[
获取缓存后的spine名称
@params spineId int 传入的spineId 当本地没有对应的spine文件时 做相对处理
@return spineName string 处理过的缓存的spine动画名 
--]]
function BaseObjectView:getSpineNameBySpineId(spineId, cardId)
	-- new spine --
	-- 不再做容错 交给CardSpine判断
	return tostring(spineId)
	-- new spine --


	--[[ old spine --
	local spineJsonPath = string.format('cards/spine/avatar/%s.json', tostring(spineId))

	if not utils.isExistent(_res(spineJsonPath)) then

		-- 如果不存在该spine 使用该卡牌的默认皮肤对应的spine
		local defaultSkinId = CardUtils.GetCardSkinId(cardId)
		local defaultSkinConfig = CardUtils.GetCardSkinConfig(defaultSkinId)

		if nil ~= defaultSkinConfig then
			spineId = tostring(defaultSkinConfig.spineId)
			spineJsonPath = string.format('cards/spine/avatar/%s.json', spineId)

			if not utils.isExistent(_res(spineJsonPath)) then
				-- 默认皮肤对应的spine不存在
				if CardUtils.IsMonsterCard(cardId) then
					local cardConf = CardUtils.GetCardConfig(cardId)
					-- 普通小怪默认
					spineId = 300001
					if MONSTER_ELITE == checkint(cardConf.type) then
						-- 精英默认
						spineId = 300005
					elseif MONSTER_BOSS == checkint(cardConf.type) then
						-- boss 默认
						spineId = 300006
					end
				else
					-- 卡牌默认
					spineId = 200001
				end
			end
			print('here cannot find card spine in battle >>>>>>>>>>', spineId, cardId)
			-- 加载一次
			SpineCache(SpineCacheName.BATTLE):addCacheData('cards/spine/avatar/' .. spineId, spineId, 0.25)
		end

	end

	return tostring(spineId)
	-- old spine ]]--
end
--[[
获取卡牌spine修正后的边界框信息
@params borderBox string 边界框名字
@return box cc.rect 边界框信息
--]]
function BaseObjectView:getAvatarBorderBox(borderBox)
	return cc.rect(0, 0, 0, 0)
end
--[[
获取卡牌spine静态碰撞框信息
@return box cc.rect 边界框信息
--]]
function BaseObjectView:getAvatarStaticCollisionBox()
	return self.staticCollisionBox
end
--[[
获取卡牌spine静态碰撞框信息
@return box cc.rect 边界框信息
--]]
function BaseObjectView:getAvatarStaticViewBox()
	return self.staticViewBox
end
--[[
根据单位坐标点获取人物对应坐标
@params up cc.p 单位坐标
--]]
function BaseObjectView:convertUnitPosToRealPos(up)
	if not up then return cc.p(0, 0) end
	-- local viewBox = self:getAvatarStaticViewBox()
	local viewBox = self:getAvatarStaticCollisionBox()
	return cc.p(viewBox.x + viewBox.width * up.x, viewBox.y + viewBox.height * up.y)
end
--[[
获取逻辑层对象指针
--]]
function BaseObjectView:getLogicObject()
	return BMediator:IsObjAliveByTag(self:getVTag())
end
--[[
获取是否强制隐藏物体阴影
--]]
function BaseObjectView:getForceHideAvatarShadow()
	return self.forceHideAvatarShadow
end
function BaseObjectView:setForceHideAvatarShadow(force)
	self.forceHideAvatarShadow = force
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

---------------------------------------------------
-- action logic begin --
---------------------------------------------------
--[[
索敌行为
@params aTargetTag int 攻击对象tag
--]]
function BaseObjectView:doSeekAttackTarget(aTargetTag)

end
--[[
移动
@params dt number delta time
@params aTargetTag int 攻击对象tag
--]]
function BaseObjectView:doMove(dt, aTargetTag)
	
end
--[[
杀死该单位 隐藏血条能量条阴影
--]]
function BaseObjectView:killSelf()
	for i,v in ipairs(self.buffIcons) do
		v:setVisible(false)
	end
	for k,v in pairs(self.hurtEffects) do
		v:setVisible(false)
	end
	for k,v in pairs(self.attachEffects) do
		v:setVisible(false)
	end
end
--[[
view死亡
--]]
function BaseObjectView:dieEnd()
	self:setVisible(false)
	for k,v in pairs(self.attachEffects) do
		v:clearTracks()
	end
end
--[[
销毁view
--]]
function BaseObjectView:destroy()
	self:setVisible(false)
	self:runAction(cc.RemoveSelf:create())
end
--[[
复活
--]]
function BaseObjectView:revive()
	for i,v in ipairs(self.buffIcons) do
		v:setVisible(true)
	end
	for k,v in pairs(self.attachEffects) do
		v:setVisible(false)
		v:setToSetupPose()
		v:clearTracks()
	end
	self:setVisible(true)
end
--[[
变身出现
@params delayTime number 延迟
@params fadeTime number 消失时间
@params callback function 回调
--]]
function BaseObjectView:deformAppear(delayTime, fadeTime, callback)
	local actionSeqTable = {
		cc.DelayTime:create(delayTime),
		cc.Show:create(),
		cc.FadeTo:create(fadeTime, 255),
		cc.DelayTime:create(1)
	}

	if nil ~= callback then
		table.insert(actionSeqTable, cc.CallFunc:create(callback))
	end

	local actionSeq = cc.Sequence:create(actionSeqTable)
	self:runAction(actionSeq)
end
--[[
变身消失
@params fadeTime number 消失时间
@params callback function 回调
--]]
function BaseObjectView:deformDisappear(fadeTime, callback)
	local actionSeqTable = {
		cc.FadeTo:create(fadeTime, 0)
	}

	if nil ~= callback then
		table.insert(actionSeqTable, cc.CallFunc:create(callback))
	end

	local actionSeq = cc.Sequence:create(actionSeqTable)
	self:runAction(actionSeq)
end
--[[
开始逃跑
--]]
function BaseObjectView:escape()
	
end
--[[
逃跑消失
--]]
function BaseObjectView:escapeDisappear()
	self:setVisible(false)
end
--[[
逃跑后出现
--]]
function BaseObjectView:escapeDisappear()
	self:setVisible(true)
end
--[[
强制隐藏
--]]
function BaseObjectView:forceHide()
	self:setVisible(false)
end
--[[
强制显示
--]]
function BaseObjectView:forceShow()
	self:setVisible(true)
end
--[[
显示周身ui
@params show bool 是否显示
--]]
function BaseObjectView:ShowAllObjectUI(show)
	
end
---------------------------------------------------
-- action logic end --
---------------------------------------------------

return BaseObjectView
